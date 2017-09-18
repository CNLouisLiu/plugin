local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin\\@DATA\\LR_AccountStatistics\\UsrData"
local _L = LR.LoadLangPack(AddonPath)
local DB_name = "maindb.db"
local UsrDataVersion = "1.0"
local UserListVersion = "v1.0"
local UserInfoVersion = "v1.0"
--------------------------------------
LR_AccountStatistics  = {
	ON = true,
	del_data_id = {},
	GroupChose = {},
	SelfInfo = {},
	showDataNotInGroup = false,
}
LR_AccountStatistics.AllUsrList = {}
LR_AccountStatistics.AllUsrData = {}
LR_AccountStatistics.AllUsrGroup = {}
LR_AccountStatistics.GroupList = {}
LR_AccountStatistics.default = {
	UsrData = {
		Version = UsrDataVersion,
		OthersCanSee = false,
		nkey = "nMoney",
		nsort = "desc",
		AutoSave = true,
		OpenSave = true,
		CloseSave = true,
		FloatPanel = false,
		NotCalList = {},
	},
}
local _auto_save_lasttime = 0
local _auto_save_lasttime2 = 0

LR_AccountStatistics.UsrData = clone(LR_AccountStatistics.default.UsrData)
local CustomVersion = "20170111"
RegisterCustomData("LR_AccountStatistics.UsrData", CustomVersion)

function LR_AccountStatistics.AutoSave()
	if not LR_AccountStatistics.UsrData.AutoSave then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end

	local _check_time = GetTickCount()
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	-----保存当前登录账号所在分组的体力精力
	LR_AccountStatistics.UpdateMyGroupInfo(DB)
	----人物数据（金钱、帮贡等）
	LR_AccountStatistics.SaveSelfInfo(DB)
	------保存仓库
	LR_AccountStatistics_Bank.SaveData(DB)
	------保存背包
	LR_AccountStatistics_Bag.SaveData(DB)
	------保存装备、属性、装分
	LR_AccountStatistics_Equip.SaveData(DB)
	-----保存副本数据
	LR_AccountStatistics_FBList.SaveData(DB)
	-----保存阅读数据
	LR_AccountStatistics_BookRd.SaveData(DB)
	----日常数据
	LR_AccountStatistics_RiChang.SaveData(DB)
	--保存考试
	LR_AS_Exam.SaveData(DB)
	----记录成就
	LR_AccountStatistics_Achievement.SaveData(DB)

	DB:Execute("END TRANSACTION")
	DB:Release()

	-----副本
	ApplyMapSaveCopy()
	Log(sformat("[LR] AS Auto save cost %0.3f s", (GetTickCount() - _check_time) * 1.0 / 1000))
end

function LR_AccountStatistics.ON_FRAME_CREATE()
	local frame = arg0
	local szName = frame:GetName()
	if szName  ==  "ExitPanel" then
		frame:Lookup("Btn_Sure"):Enable(false)
		LR.DelayCall(1000, function()
			local frame = Station.Lookup("Topmost2/ExitPanel")
			if frame then
				frame:Lookup("Btn_Sure"):Enable(true)
			end
		end)
		Log("[LR_AccountStatistics]:Exit save")
		LR_AccountStatistics.AutoSave()
		LR_ACS_QiYu.SaveData()
		LR_Acc_Trade.MoveData2MainTable()
		FireEvent("LR_ACS_REFRESH_FP")
		frame:Lookup("Btn_Sure"):Enable(true)
	elseif szName  ==  "OptionPanel" then
		---每10秒最多触发一次
		local _time = GetCurrentTime()
		if _time - _auto_save_lasttime > 10 then
			local _check_time = GetTickCount()
			local path = sformat("%s\\%s", SaveDataPath, DB_name)
			local DB = SQLite3_Open(path)
			DB:Execute("BEGIN TRANSACTION")
			LR_AccountStatistics.LoadUserList(DB)
			LR_AccountStatistics.LoadAllUserInformation(DB)
			LR_AccountStatistics.LoadAllUserGroup(DB)
			DB:Execute("END TRANSACTION")
			DB:Release()
			Log(sformat("[LR] Sync user data cost %0.3f s", (GetTickCount() - _check_time) * 1.0 / 1000 ))
			-----------邮件提醒
			LR_AccountStatistics_Mail_Check.CheckAllMail()
			LR_Acc_Trade.OutPutMoneyChange()
			_auto_save_lasttime = _time
		end

		if _time - _auto_save_lasttime2 > 60 * 3 then
			LR_AccountStatistics.AutoSave()
			LR_ACS_QiYu.SaveData()
			_auto_save_lasttime2 = _time
		end

		FireEvent("LR_ACS_REFRESH_FP")
	elseif szName  ==  "BigBagPanel" then
		----在背包界面添加一个打开拉人物品统计的按钮
		LR.DelayCall(500, function()
			LR_AccountStatistics_Bag.HookBag()
		end)
	elseif szName == "MailPanel" then
		LR.DelayCall(200, function()
			LR_AccountStatistics_Bag.HookMailPanel()
		end)
	end
end

----检查UsrData版本，若不符合当前版本，则重置
function LR_AccountStatistics.CheckUsrDataVersion()
	if not (LR_AccountStatistics.UsrData and LR_AccountStatistics.UsrData.Version and LR_AccountStatistics.UsrData.Version  ==  UsrDataVersion) then
		LR_AccountStatistics.UsrData = clone(LR_AccountStatistics.default.UsrData)
	end
end

LR.RegisterEvent("ON_FRAME_CREATE", function() LR_AccountStatistics.ON_FRAME_CREATE()  end)

function LR_AccountStatistics.LoadUserList(DB)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local DB_SELECT = DB:Prepare("SELECT szKey, dwID, szName, dwForceID, loginArea, loginServer, realArea, realServer FROM player_info WHERE szKey IS NOT NULL")
	DB_SELECT:ClearBindings()
	local Data = DB_SELECT:GetAll() or {}
	local UserList = {}
	for k, v in pairs(Data) do
		UserList[v.szKey] = v
	end
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local key1 = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local key2 = sformat("%s_%s_%d", loginArea, loginServer, me.dwID)
	--下面两行顺序不能乱
	UserList[key2] = nil
	UserList[key1] = {szKey = key2, dwID = me.dwID, szName = me.szName, dwForceID = me.dwForceID, loginArea = loginArea, loginServer = loginServer, OthersCanSee = LR_AccountStatistics.UsrData.OthersCanSee, realArea = realArea, realServer = realServer, }
	LR_AccountStatistics.AllUsrList = clone(UserList)
end

function LR_AccountStatistics.GetUserInfo()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local UserInfo = {}
	UserInfo.szName = me.szName or ""
	UserInfo.dwID = me.dwID or 0
	UserInfo.nLevel = me.nLevel or 0
	UserInfo.dwForceID = me.dwForceID or 0
	local nMoney = me.GetMoney()
	UserInfo.nGold = nMoney.nGold
	UserInfo.nSilver = nMoney.nSilver
	UserInfo.nCopper = nMoney.nCopper
	UserInfo.nMoney = nMoney.nCopper + nMoney.nSilver * 100 + nMoney.nGold * 10000
	UserInfo.JianBen = LR.GetSelfJianBen() or 0	--监本
	UserInfo.BangGong = LR.GetSelfJiangGong() or 0
	UserInfo.XiaYi = LR.GetSelfXiaYi() or 0
	UserInfo.WeiWang = LR.GetSelfWeiWang() or 0
	UserInfo.ZhanJieJiFen = LR.GetSelfZhanJieJiFen() or 0
	UserInfo.ZhanJieDengJi = LR.GetSelfZhanJieDengJi() or 0
	UserInfo.MingJianBi = LR.GetSelfMingJianBi() or 0
	UserInfo.szTitle = me.szTitle or ""
	UserInfo.nCurrentStamina = me.nCurrentStamina or 0
	UserInfo.nMaxStamina = me.nMaxStamina or 0
	UserInfo.nCurrentThew = me.nCurrentThew or 0
	UserInfo.nMaxThew = me.nMaxThew or 0
	UserInfo.nCurrentTrainValue = me.nCurrentTrainValue or 0
	UserInfo.nCamp = me.nCamp or 0
	UserInfo.szTongName = LR.GetTongName(me.dwTongID) or ""
	UserInfo.remainJianBen = me.GetExamPrintRemainSpace() or 0
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	UserInfo.loginArea = loginArea or ""
	UserInfo.loginServer = loginServer or ""
	UserInfo.realServer = realServer or ""
	UserInfo.realArea = realArea or ""
	UserInfo.SaveTime = GetCurrentTime()
	LR_AccountStatistics.SelfInfo = clone(UserInfo)
	return UserInfo
end

function LR_AccountStatistics.SaveSelfInfo(DB)
	-------保存自身的属性数据
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	LR_AccountStatistics.GetUserInfo()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	if LR_AccountStatistics.UsrData.OthersCanSee then
		local v = LR_AccountStatistics.SelfInfo
		local DB_REPLACE = DB:Prepare("REPLACE INTO player_info (szKey, dwID, szName, nLevel, dwForceID, nGold, nSilver, nCopper, JianBen, BangGong, XiaYi, WeiWang, ZhanJieJiFen, ZhanJieDengJi, MingJianBi, szTitle, nCurrentStamina, nMaxStamina, nCurrentThew, nMaxThew, nCurrentTrainValue, nCamp, szTongName, remainJianBen, loginArea, loginServer, realArea, realServer, SaveTime) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey, v.dwID, v.szName, v.nLevel, v.dwForceID, v.nGold, v.nSilver, v.nCopper, v.JianBen, v.BangGong, v.XiaYi, v.WeiWang, v.ZhanJieJiFen, v.ZhanJieDengJi, v.MingJianBi, v.szTitle, v.nCurrentStamina, v.nMaxStamina, v.nCurrentThew, v.nMaxThew, v.nCurrentTrainValue, v.nCamp, v.szTongName, v.remainJianBen, v.loginArea, v.loginServer, v.realArea, v.realServer, v.SaveTime)
		DB_REPLACE:Execute()
	else
		local DB_DELETE = DB:Prepare("DELETE FROM player_info WHERE szKey = ?")
		DB_DELETE:ClearBindings()
		DB_DELETE:BindAll(szKey)
		DB_DELETE:Execute()
	end
end

function LR_AccountStatistics.LoadAllUserInformation(DB)
	local GroupChose = LR_AccountStatistics.GroupChose or {}
	local DB_SELECT
	if next(GroupChose) ~= nil and not LR_AccountStatistics.showDataNotInGroup then
		local t = {}
		for k, v in pairs(GroupChose) do
			t[#t+1] = '?'
		end
		DB_SELECT = DB:Prepare(sformat("SELECT player_info.* FROM player_info INNER JOIN player_group ON player_info.szKey = player_group.szKey AND player_group.groupID IN ( %s ) WHERE player_info.szKey IS NOT NULL", tconcat(t, ", ")))
		DB_SELECT:ClearBindings()
		DB_SELECT:BindAll(unpack(GroupChose))
	else
		DB_SELECT = DB:Prepare("SELECT * FROM player_info WHERE szKey IS NOT NULL")
	end
	local Data = DB_SELECT:GetAll() or {}
	--local Data = DB:Execute("SELECT * FROM player_info WHERE szKey IS NOT NULL") or {}
	local AllUsrData = {}
	for k, v in pairs(Data) do
		AllUsrData[v.szKey] = v
		AllUsrData[v.szKey].nMoney = v.nCopper + v.nSilver *100 + v.nGold * 10000
	end
	LR_AccountStatistics.AllUsrData = clone(AllUsrData)
	--加入自己的数据
	LR_AccountStatistics.UpdateSelfInfoInAllData()
end

function LR_AccountStatistics.UpdateSelfInfoInAllData()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	LR_AccountStatistics.GetUserInfo()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local key = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	LR_AccountStatistics.AllUsrData[key] = LR_AccountStatistics.AllUsrData[key] or {}
	for k, v in pairs (LR_AccountStatistics.SelfInfo) do
		LR_AccountStatistics.AllUsrData[key][k] = v		--LR_AccountStatistics.SelfInfo中的数据列<从数据库导出的数据列，顾分项替换
	end
end

function LR_AccountStatistics.DelOneData (key, DB)
	local key = key
	local loginArea = key.loginArea
	local loginServer = key.loginServer
	local realArea = key.realArea or loginArea
	local realServer = key.realServer or loginServer
	local szName = key.szName
	local dwID = key.dwID

	------删除UserList内的数据
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	LR_AccountStatistics.AllUsrList[szKey] = nil

	-----删除成就数据
	DB:Execute(sformat("DELETE FROM achievement_data WHERE szKey = '%s'", szKey))

	-----删除背包数据
	DB:Execute(sformat("DELETE FROM bag_item_data WHERE belong = '%s'", szKey))

	-----删除仓库数据
	DB:Execute(sformat("DELETE FROM bank_item_data WHERE belong = '%s'", szKey))

	----删除阅读信息
	DB:Execute(sformat("DELETE FROM bookrd_data WHERE szKey = '%s'", szKey))

	----删除装备信息
	DB:Execute(sformat("DELETE FROM equipment_data WHERE szKey = '%s'", szKey))

	----删除考试数据
	DB:Execute(sformat("DELETE FROM exam_data WHERE szKey = '%s'", szKey))

	----删除副本数据
	DB:Execute(sformat("DELETE FROM fb_data WHERE szKey = '%s'", szKey))

	----删除邮件数据
	DB:Execute(sformat("DELETE FROM mail_data WHERE belong = '%s'", szKey))
	DB:Execute(sformat("DELETE FROM mail_item_data WHERE belong = '%s'", szKey))
	DB:Execute(sformat("DELETE FROM mail_receive_time WHERE szKey = '%s'", szKey))

	----删除人物所在分组
	DB:Execute(sformat("DELETE FROM player_group WHERE szKey = '%s'", szKey))

	-----删除角色信息数据
	DB:Execute(sformat("DELETE FROM player_info WHERE szKey = '%s' ", szKey))

	----删除角色奇遇数据
	DB:Execute(sformat("DELETE FROM qiyu_data WHERE szKey = '%s'", szKey))

	----删除日常数据
	DB:Execute(sformat("DELETE FROM richang_data WHERE szKey = '%s'", szKey))

	LR.SysMsg(_L["Delete successful!\n"])
end

function LR_AccountStatistics.WndButton (szName, x, y, szText, fnAction, aFrame, fnEnter, fnLeave)
	local fx = Wnd.OpenWindow("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics_WndButton.ini", "LR_AccountStatistics_WndButton")
	local item
	if fx then
		item = fx:Lookup("WndButton")
		if item then
			item:ChangeRelation(aFrame, true, true)
			item:SetName(szName)
			item:SetRelPos(x, y)
			item.OnLButtonClick = fnAction
			item:Lookup("", "Text_Default"):SetText(szText)
		end
	end
	Wnd.CloseWindow(fx)
	return item
end

function LR_AccountStatistics.ReFreshTitle()
	local page = Station.Lookup("Normal/LR_AccountStatistics/PageSet_Menu/Page_LR_AS_Record")
	local key_list = {"nLevel", "nMoney", "JianBen", "BangGong", "XiaYi", "WeiWang", "ZhanJieJiFen", "ZhanJieDengJi", "MingJianBi"}
	local title_list = {_L["Name"], _L["Money"], _L["Examprint"], _L["JiangGong"], _L["XiaYi"], _L["WeiWang"], _L["ZhanJieJiFen"], _L["ZhanJieLevel"], _L["MingJian"]}
	for k , v in ipairs(key_list) do
		if v then
			local txt = page:Lookup("", sformat("Text_Record_Break%d", k))
			txt:SetText(title_list[k])
			txt:RegisterEvent(786)
			txt:SetFontScheme(44)
			if LR_AccountStatistics.UsrData.nkey  ==  v then
				if LR_AccountStatistics.UsrData.nsort  ==  "asc" then
					txt:SetText(title_list[k] .. "↑")
					txt:SetFontScheme(99)
				elseif LR_AccountStatistics.UsrData.nsort  ==  "desc" then
					txt:SetText(title_list[k] .. "↓")
					txt:SetFontScheme(99)
				end
			end

			txt.OnItemLButtonClick = function()
				if LR_AccountStatistics.UsrData.nkey  ==  v then
					if LR_AccountStatistics.UsrData.nsort  ==  "asc" then
						LR_AccountStatistics.UsrData.nsort = "desc"
					else
						LR_AccountStatistics.UsrData.nsort = "asc"
					end
				end
				LR_AccountStatistics.UsrData.nkey = v
				LR_AccountStatistics.ReFreshTitle()
				LR_AccountStatistics.ListAS()
				LR_AccountStatistics_FBList.ListFB()
				LR_AccountStatistics_RiChang.ListRC()
				LR_ACS_QiYu.ListQY()
			end
			txt.OnItemMouseEnter = function()
				this:SetFontColor(255, 128, 0)
			end
			txt.OnItemMouseLeave = function()
				if LR_AccountStatistics.UsrData.nkey  ==  v then
					txt:SetFontScheme(99)
				else
					this:SetFontColor(255, 255, 255)
				end
			end
		end
	end
end


function LR_AccountStatistics.OnFrameCreate()
	-----账目本容器
	LR_AccountStatistics.LR_AS_Container = this:Lookup("PageSet_Menu/Page_LR_AS_Record/WndScroll_LR_AS_Record/WndContainer_Record_List")
	-----副本列表容器
	LR_AccountStatistics.LR_FBList_Container = this:Lookup("PageSet_Menu/Page_LR_FBList/WndScroll_LR_FBList_Record/Wnd_LR_FBList_Record_List")
	LR_AccountStatistics.LR_FBList_Title_handle = this:Lookup("PageSet_Menu"):Lookup("Page_LR_FBList"):Lookup("", "")
	-----日常统计容器
	LR_AccountStatistics.LR_RCList_Container = this:Lookup("PageSet_Menu/Page_LR_RCList/WndScroll_LR_RCList_Record/Wnd_LR_RCList_Record_List")
	LR_AccountStatistics.LR_RCList_Title_handle = this:Lookup("PageSet_Menu"):Lookup("Page_LR_RCList"):Lookup("", "")
	-----奇遇统计容器
	LR_AccountStatistics.LR_QYList_Container = this:Lookup("PageSet_Menu/Page_LR_QYList/WndScroll_LR_QYList_Record/Wnd_LR_QYList_Record_List")
	LR_AccountStatistics.LR_QYList_Title_handle = this:Lookup("PageSet_Menu"):Lookup("Page_LR_QYList"):Lookup("", "")

	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	----打开时刷新数据
	LR_AccountStatistics.LoadUserList(DB)
	LR_AccountStatistics.LoadAllUserInformation(DB)
	LR_AccountStatistics.LoadGroupListData(DB)
	LR_AccountStatistics.LoadAllUserGroup(DB)
	LR_AccountStatistics_FBList.GetFBList()
	LR_AS_Exam.LoadData(DB)
	LR_AccountStatistics_RiChang.LoadAllUsrData(DB)
	LR_AccountStatistics_RiChang.CheckAll()
	LR_AccountStatistics_FBList.LoadAllUsrData(DB)
	LR_ACS_QiYu.LoadAllUsrData(DB)		--奇遇数据


	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("CUSTOM_DATA_LOADED")

	this:Lookup("Btn_Close").OnLButtonClick =  function ()
		Wnd.CloseWindow("LR_AccountStatistics")
	end

	RegisterGlobalEsc("LR_AccountStatistics", function () return true end , function() Wnd.CloseWindow("LR_AccountStatistics") end)
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)

	----界面
	this:Lookup("", ""):Lookup("Text_Title"):SetText(_L["LR_AccountStatistics"])

	this:Lookup("PageSet_Menu/WndCheck_LR_AS_Record"):Lookup("", ""):Lookup("Text_LR_AS_Record"):SetText(_L["AccountStatistics"])
	this:Lookup("PageSet_Menu/Page_LR_AS_Record"):Lookup("", ""):Lookup("Text_LR_AS_RecordSettlement"):SetText(_L["Total:"])

	this:Lookup("PageSet_Menu/WndCheck_LR_FBList"):Lookup("", ""):Lookup("Text_LR_FBList_Record"):SetText(_L["FBStatistics"])
	LR_AccountStatistics.LR_FBList_Title_handle:Lookup("Text_FBList_Record_Break1"):SetText(_L["Name"])

	this:Lookup("PageSet_Menu/WndCheck_LR_RCList"):Lookup("", ""):Lookup("Text_LR_RCList_Record"):SetText(_L["RCStatistics"])
	LR_AccountStatistics.LR_RCList_Title_handle:Lookup("Text_RCList_Record_Break1"):SetText(_L["Name"])

	this:Lookup("PageSet_Menu/WndCheck_LR_QYList"):Lookup("", ""):Lookup("Text_LR_QYList_Record"):SetText(_L["QYStatistics"])
	LR_AccountStatistics.LR_QYList_Title_handle:Lookup("Text_QYList_Record_Break1"):SetText(_L["Name"])

	this:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)

	LR_AccountStatistics.ReFreshTitle()

	page = Station.Lookup("Normal/LR_AccountStatistics/PageSet_Menu/Page_LR_AS_Record")
	LR_AccountStatistics.WndButton("btn_5", 340, 555, _L["Show Group"], LR_AccountStatistics.ShowGroup, page)
	LR_AccountStatistics.WndButton("btn_4", 470, 555, _L["Reading Statistics"], LR_AccountStatistics.OpenBookRdPanel, page)
	LR_AccountStatistics.WndButton("btn_3", 600, 555, _L["Item Statistics"], LR_AccountStatistics.OpenItemPanel, page)
	LR_AccountStatistics.WndButton("btn_2", 730, 555, _L["Settings"], LR_AccountStatistics.SetOption, page)
	LR_AccountStatistics.WndButton("btn_1", 860, 555, _L["Save Data"], LR_AccountStatistics.SaveData, page)

	page = Station.Lookup("Normal/LR_AccountStatistics/PageSet_Menu/Page_LR_FBList")
	LR_AccountStatistics.WndButton("btn_5", 340, 555, _L["Show Group"], LR_AccountStatistics.ShowGroup, page)
	LR_AccountStatistics.WndButton("btn_4", 470, 555, _L["Reading Statistics"], LR_AccountStatistics.OpenBookRdPanel, page)
	LR_AccountStatistics.WndButton("btn_3", 600, 555, _L["FB Detail"], LR_AccountStatistics.OpenFBDetail_Panel, page)
	LR_AccountStatistics.WndButton("btn_2", 730, 555, _L["Settings"], LR_AccountStatistics.SetOption, page)

	page = Station.Lookup("Normal/LR_AccountStatistics/PageSet_Menu/Page_LR_RCList")
	LR_AccountStatistics.WndButton("btn_5", 340, 555, _L["Show Group"], LR_AccountStatistics.ShowGroup, page)
	LR_AccountStatistics.WndButton("btn_4", 470, 555, _L["Reading Statistics"], LR_AccountStatistics.OpenBookRdPanel, page)
	LR_AccountStatistics.WndButton("btn_3", 600, 555, _L["Quest Tools"], LR_AccountStatistics.OpenQuestTool_Panel, page)
	LR_AccountStatistics.WndButton("btn_2", 730, 555, _L["Settings"], LR_AccountStatistics.SetOption, page)
	LR_AccountStatistics.WndButton("btn_1", 860, 555, _L["7 YEAR"], LR_AccountStatistics.Open7Year, page)

	page = Station.Lookup("Normal/LR_AccountStatistics/PageSet_Menu/Page_LR_QYList")
	LR_AccountStatistics.WndButton("btn_5", 340, 555, _L["Show Group"], LR_AccountStatistics.ShowGroup, page)
	LR_AccountStatistics.WndButton("btn_4", 470, 555, _L["Reading Statistics"], LR_AccountStatistics.OpenBookRdPanel, page)
	LR_AccountStatistics.WndButton("btn_3", 600, 555, _L["QiYu Detail"], LR_AccountStatistics.OpenQYDetail_Panel, page)
	LR_AccountStatistics.WndButton("btn_2", 730, 555, _L["Settings"], LR_AccountStatistics.SetOption, page)
	local QiYu_About = LR_AccountStatistics.WndButton("btn_3", 860, 555, _L["QiYu About"], nil, page)
	QiYu_About.OnMouseEnter = function()
		local nX, nY = this:GetAbsPos()
		local nW, nH = this:GetSize()
		local szText = GetFormatText(_L["QiYu Tip"], 224)
		OutputTip(szText, 360 , {nX, nY, nW, nH})
	end
	QiYu_About.OnMouseLeave = function()
		HideTip()
	end

	-------打开面板时保存数据
	if LR_AccountStatistics.UsrData.AutoSave and LR_AccountStatistics.UsrData.OpenSave then
		LR_AccountStatistics.AutoSave()
	end

	-----------邮件提醒
	LR_AccountStatistics_Mail_Check.CheckAllMail()

	LR_AccountStatistics.ListAS()
	LR_AccountStatistics_FBList.ListFB()
	LR_AccountStatistics_RiChang.ListRC()
	LR_ACS_QiYu.ListQY()

	DB:Execute("END TRANSACTION")
	DB:Release()

	FireEvent("LR_ACS_REFRESH_FP")
	LR.AppendAbout(Addon, this)
end

function LR_AccountStatistics.OnFrameDestroy ()
	UnRegisterGlobalEsc("LR_AccountStatistics")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_AccountStatistics.OnEvent(event)
	----
end

function LR_AccountStatistics.OpenPanel(flag)
	local frame = Station.Lookup("Normal/LR_AccountStatistics")
	if frame and not flag then
		Wnd.CloseWindow(frame)
	else
		Wnd.OpenWindow("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics.ini", "LR_AccountStatistics")
	end
end

function LR_AccountStatistics.OnFrameBreathe()
	if GetLogicFrameCount() % (16*5) ~=  0 then
		return
	end
	local player = GetClientPlayer()
	if not player then
		return
	end
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	LR_AccountStatistics.GetUserInfo()	--获取自身数据
	LR_AccountStatistics.LoadGroupListData(DB)	--分组数据
	LR_AccountStatistics.LoadAllUserGroup(DB)	--人物分组
	LR_AccountStatistics.LoadAllUserInformation(DB)		--人物数据
	LR_AS_Exam.LoadData(DB)	--考试数据
	LR_AccountStatistics_RiChang.LoadAllUsrData(DB)	--日常数据
	LR_AccountStatistics_FBList.LoadAllUsrData(DB)	--副本数据
	LR_ACS_QiYu.LoadAllUsrData(DB)		--奇遇数据
	---展示
	LR_AccountStatistics.ListAS()
	LR_AccountStatistics_FBList.ListFB()
	LR_AccountStatistics_RiChang.ListRC()
	LR_ACS_QiYu.ListQY()
	DB:Execute("END TRANSACTION")
	DB:Release()
end

function LR_AccountStatistics.CheckTable(t_Table, dwID)
	local TempTable = t_Table
	local CheckID =  dwID
	for k, v in pairs (TempTable) do
		if v.ID  ==  CheckID then
			return k
		end
	end
	return 0
end

function LR_AccountStatistics.ShowItem (t_Table, Alpha, bCal, _num, _money)
	local num = _num
	local AllMoney = _money
	local TempTable = clone(t_Table)
	for i = 1, #TempTable, 1 do
		num = num+1
		local wnd = LR_AccountStatistics.LR_AS_Container:AppendContentFromIni("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics_item.ini", "WndWindow", num)
		local items = wnd:Lookup("", "")
		if num % 2  ==  0 then
			items:Lookup("Image_Line"):Hide()
		else
			items:Lookup("Image_Line"):SetAlpha(225)
		end

		wnd:SetAlpha(Alpha)

		local item_MenPai = items:Lookup("Image_NameIcon")
		local item_Name = items:Lookup("Text_Name")
		local item_GoldBrick = items:Lookup("Text_GoldBrick")
		local item_Gold = items:Lookup("Text_Gold")
		local item_Silver = items:Lookup("Text_Silver")
		local item_Copper = items:Lookup("Text_Copper")
		local item_JianBen = items:Lookup("Text_JianBen")
		local item_BangGong = items:Lookup("Text_BangGong")
		local item_XiaYi = items:Lookup("Text_XiaYi")
		local item_WeiWang = items:Lookup("Text_WeiWang")
		local item_ZhanJieJiFen = items:Lookup("Text_ZhanJieJiFen")
		local item_ZhanJieDengJi = items:Lookup("Text_ZhanJieDengJi")
		local item_MingJianBi = items:Lookup("Text_MingJianBi")
		local item_Select = items:Lookup("Image_Select")
		item_Select:SetAlpha(125)
		item_Select:Hide()

		local szPath, nFrame = GetForceImage(TempTable[i].dwForceID)
		local loginArea = TempTable[i].loginArea
		local loginServer = TempTable[i].loginServer
		local realArea = TempTable[i].realArea or loginArea
		local realServer = TempTable[i].realServer or loginServer
		local dwID = TempTable[i].dwID
		local szName = TempTable[i].szName
		local key = sformat("%s_%s_%d", realArea, realServer, dwID)

		local item_button_menu = {}
		tinsert(item_button_menu, {
			szOption = TempTable[i].szName,
			szLayer = "ICON_RIGHT",
			rgb = { LR.GetMenPaiColor(TempTable[i].dwForceID) },
			szIcon = szPath,
			nFrame = nFrame,
		})
		tinsert(item_button_menu, { bDevide = true })
		tinsert(item_button_menu, {
			szOption = _L["Add this money"],
			bCheck = true,
			bMCheck = false,
			rgb = {255, 255, 255},
			fnAction = function ()
				local NotCalList = LR_AccountStatistics.UsrData.NotCalList or {}
				if NotCalList[key] then
					NotCalList[key] = nil
				else
					NotCalList[key] = true
				end
				LR_AccountStatistics.ListAS()
				LR_AccountStatistics_FBList.ListFB()
				LR_AccountStatistics_RiChang.ListRC()
				LR_ACS_QiYu.ListQY()
			end,
			bChecked = function ()
				local NotCalList = LR_AccountStatistics.UsrData.NotCalList or {}
				if NotCalList[key] then
					return false
				else
					return true
				end
			end,
			})
		tinsert(item_button_menu, { bDevide = true })
		tinsert(item_button_menu, {
			szOption = _L["Show item statistics"],
			fnDisable = function ()
				if LR_AccountStatistics_Bag  ==  nil then
					return true
				else
					return false
				end
			end,
			fnAction = function ()
				local frame = Station.Lookup("Normal/LR_AccountStatistics_Bag_Panel")
				local realArea = TempTable[i].realArea
				local realServer = TempTable[i].realServer
				local dwID = TempTable[i].dwID
				if not frame then
					LR_AccountStatistics_Bag_Panel:Open(realArea, realServer, dwID)
				else
					LR_AccountStatistics_Bag_Panel:ReloadItemBox(realArea, realServer, dwID)
				end
			end,
			})
		tinsert(item_button_menu, {
			szOption = _L["Show FB Details"],
			fnDisable = function ()
				if LR_Acc_FB_Detail_Panel  ==  nil then
					return true
				else
					return false
				end
			end,
			fnAction = function ()
				local frame = Station.Lookup("Normal/LR_Acc_FB_Detail_Panel")
				local realArea = TempTable[i].realArea
				local realServer = TempTable[i].realServer
				local dwID = TempTable[i].dwID
				if not frame then
					LR_Acc_FB_Detail_Panel:Open(realArea, realServer, dwID)
				else
					LR_Acc_FB_Detail_Panel:ReloadItemBox(realArea, realServer, dwID)
				end
			end,
			})
		tinsert(item_button_menu, {
			szOption = _L["Show reading statistics"],
			fnDisable = function ()
				if LR_BookRd_Panel  ==  nil then
					return true
				else
					return false
				end
			end,
			fnAction = function ()
				local frame = Station.Lookup("Normal/LR_BookRd_Panel")
				if not frame then
					LR_BookRd_Panel:Open()
				end
			end,
			})
		tinsert(item_button_menu, {
			szOption = _L["Show Equipment"],
			fnDisable = function ()
				if LR_AS_Equip_Panel  ==  nil then
					return true
				else
					return false
				end
			end,
			fnAction = function ()
				local frame = Station.Lookup("Normal/LR_AS_Equip_Panel")
				if not frame then
					local realArea = TempTable[i].realArea
					local realServer = TempTable[i].realServer
					local szName = TempTable[i].szName
					local dwForceID = TempTable[i].dwForceID
					LR_AS_Equip_Panel:Open(szName, realArea, realServer, dwForceID, TempTable[i].dwID)
				else
					local realArea = TempTable[i].realArea
					local realServer = TempTable[i].realServer
					local szName = TempTable[i].szName
					local dwForceID = TempTable[i].dwForceID
					LR_AS_Equip_Panel:Open()
					LR_AS_Equip_Panel:Open(szName, realArea, realServer, dwForceID, TempTable[i].dwID)
				end
			end,
			})

		local item_button_menu2 = {
			szOption = _L["Group Settings"],
			fnDisable = function ()
				return false
			end,
			}
		for groupID, groupV in pairs(LR_AccountStatistics.GroupList) do
			local szGroupName = groupV.szName
			tinsert (item_button_menu2, {
				szOption = szGroupName,
				bCheck = true, bMCheck = true, bChecked = function() return LR_AccountStatistics.ifGroupHasUser(key, groupID) end,
				fnAction = function(UserData)
					local path = sformat("%s\\%s", SaveDataPath, DB_name)
					local DB = SQLite3_Open(path)
					DB:Execute("BEGIN TRANSACTION")
					LR_AccountStatistics.ChangeUserGroup(key, groupID, DB)
					LR_AccountStatistics.UpdateMyGroupInfo(DB)
					LR_AccountStatistics.ListAS()
					LR_AccountStatistics_FBList.ListFB()
					LR_AccountStatistics_RiChang.ListRC()
					LR_ACS_QiYu.ListQY()
					DB:Execute("END TRANSACTION")
					DB:Release()
				end,
			})
		end
		tinsert(item_button_menu2, {bDevide = true})
		tinsert(item_button_menu2, {szOption = _L["Group Cancel"],
			fnAction = function()
				local path = sformat("%s\\%s", SaveDataPath, DB_name)
				local DB = SQLite3_Open(path)
				DB:Execute("BEGIN TRANSACTION")
				LR_AccountStatistics.ChangeUserGroup(key, 0, DB)
				LR_AccountStatistics.UpdateMyGroupInfo(DB)
				LR_AccountStatistics.ListAS()
				LR_AccountStatistics_FBList.ListFB()
				LR_AccountStatistics_RiChang.ListRC()
				LR_ACS_QiYu.ListQY()
				DB:Execute("END TRANSACTION")
				DB:Release()
			end,
		})
		tinsert(item_button_menu2, {szOption = _L["Add Group"],
			fnAction = function()
				GetUserInput(_L["Group Name"], function(szText)
					local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
					if szText ~=  "" then
						local path = sformat("%s\\%s", SaveDataPath, DB_name)
						local DB = SQLite3_Open(path)
						DB:Execute("BEGIN TRANSACTION")
						LR_AccountStatistics.AddGroup(szText, DB)
						LR_AccountStatistics.ListAS()
						LR_AccountStatistics_FBList.ListFB()
						LR_AccountStatistics_RiChang.ListRC()
						LR_ACS_QiYu.ListQY()
						DB:Execute("END TRANSACTION")
						DB:Release()
					end
				end)
			end,
		})
		tinsert(item_button_menu, item_button_menu2)
		if TempTable[i].dwID ~=  GetClientPlayer().dwID then
			tinsert(item_button_menu, {	szOption =  _L["Make Friend"],
				fnAction = function()
					GetClientPlayer().AddFellowship(TempTable[i].szName)
				end}
			)
		end
		tinsert(item_button_menu, { bDevide = true })
		tinsert(item_button_menu, {
			szOption = _L["Delete Data"],
			fnAction = function ()
				LR_AccountStatistics.del_data_id = {dwID = TempTable[i].dwID, loginArea = TempTable[i].loginArea, loginServer = TempTable[i].loginServer, szName = TempTable[i].szName, realArea = TempTable[i].realArea, realServer = TempTable[i].realServer}
				LR_AccountStatistics_DelPanel:Open()
				LR_AccountStatistics.ListAS()
				LR_AccountStatistics_FBList.ListFB()
				LR_AccountStatistics_RiChang.ListRC()
				LR_ACS_QiYu.ListQY()
			end,
			fnDisable = function()
				local me = GetClientPlayer()
				local ServerInfo = {GetUserServer()}
				local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
				if me.szName == TempTable[i].szName and realArea == TempTable[i].realArea and realServer == TempTable[i].realServer then
					return true
				end
				return false
			end,
			})
		local item_button = wnd:Lookup("Btn_Setting")
		item_button.OnLButtonClick =  function ()
			  PopupMenu(item_button_menu)
		end

		item_MenPai:FromUITex(GetForceImage(TempTable[i].dwForceID))
		local name = szName
		if slen(name) >12 then
			local _start, _end  = sfind (name, "@")
			if _start and _end then
				name = sformat("%s...", ssub(name, 1, 9))
			else
				name = sformat("%s...", ssub(name, 1, 10))
			end
		end
		item_Name:SprintfText("%s(%d)", name, TempTable[i].nLevel)
		local r, g, b = LR.GetMenPaiColor(TempTable[i].dwForceID)
		item_Name:SetFontColor(r, g, b)
		local nGoldBrick, nGold, nSilver, nCopper = LR.MoneyToGoldSilverAndCopper(TempTable[i].nMoney)
		item_GoldBrick:SetText(nGoldBrick)
		item_Gold:SetText(nGold)
		item_Silver:SetText(nSilver)
		item_Copper:SetText(nCopper)
		local realArea = TempTable[i].realArea
		local realServer = TempTable[i].realServer
		local szName = TempTable[i].szName
		local szKey = sformat("%s_%s_%d", realArea, realServer, TempTable[i].dwID)
		local examData = LR_AS_Exam.AllUsrData[szKey] or {["ShengShi"] = 0, ["HuiShi"] = 0, }
		local me = GetClientPlayer()
		local ServerInfo2 = {GetUserServer()}
		if me and me.szName  ==  szName and ServerInfo2[5]  ==  realArea and ServerInfo2[6]  ==  realServer then
			examData = LR_AS_Exam.SelfData
		end
		if examData["HuiShi"] == 1 then
			item_JianBen:SprintfText("▲%d▲", TempTable[i].JianBen)
		elseif examData["ShengShi"] == 1 then
			item_JianBen:SprintfText("△%d△", TempTable[i].JianBen)
		else
			item_JianBen:SetText(TempTable[i].JianBen)
		end
		item_BangGong:SetText(TempTable[i].BangGong)
		item_XiaYi:SetText(TempTable[i].XiaYi)
		item_WeiWang:SetText(TempTable[i].WeiWang)
		item_ZhanJieJiFen:SetText(TempTable[i].ZhanJieJiFen)
		item_ZhanJieDengJi:SetText(TempTable[i].ZhanJieDengJi)
		item_MingJianBi:SetText(TempTable[i].MingJianBi)

		local remainJianBen = TempTable[i].remainJianBen or 1000
		if remainJianBen<100 then
			item_JianBen:SetFontScheme(207)
			item_JianBen:SetFontColor(255, 0, 128)
		elseif remainJianBen<300 then
			item_JianBen:SetFontScheme(207)
			item_JianBen:SetFontColor(215, 215, 0)
		end

		--------------------输出tips
		items:RegisterEvent(818)
		items.OnItemMouseEnter = function ()
			item_Select:Show()
			local nMouseX, nMouseY =  Cursor.GetPos()
			local szTipInfo = {}
			local szPath, nFrame = GetForceImage(TempTable[i].dwForceID)
			szTipInfo[#szTipInfo+1] = GetFormatImage(szPath, nFrame, 26, 26)
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s(%d)\n", TempTable[i].szName, TempTable[i].nLevel), 62, r, g, b)
			szTipInfo[#szTipInfo+1] = GetFormatImage("ui\\image\\ChannelsPanel\\NewChannels.uitex", 166, 365, 27)
			szTipInfo[#szTipInfo+1] = GetFormatText("\n", 224)
			--szTipInfo[#szTipInfo+1] = GetFormatText(" ================================ \n", 17)
--[[			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("金钱：", 224) ..  GetFormatText(sformat("%d 金 %d 银 %d 铜\n", nGold, nSilver, nCopper), 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("监本：", 224) ..  GetFormatText(TempTable[i].JianBen.."\n", 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("江湖贡献值：", 224) ..  GetFormatText(TempTable[i].BangGong.."\n", 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("侠义值：", 224) ..  GetFormatText(TempTable[i].XiaYi.."\n", 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("威望值：", 224) ..  GetFormatText(TempTable[i].WeiWang.."\n", 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("战阶积分：", 224) ..  GetFormatText(TempTable[i].ZhanJieJiFen.."\n", 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("战阶等级：", 224) ..  GetFormatText(TempTable[i].ZhanJieDengJi.."\n", 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("名剑币：", 224) ..  GetFormatText(TempTable[i].MingJianBi.."\n", 41)]]
			szTipInfo[#szTipInfo+1] = GetFormatText(_L["Login Server:"], 224)
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s[%s]\n", TempTable[i].loginServer, TempTable[i].loginArea), 18)
			szTipInfo[#szTipInfo+1] = GetFormatText(_L["Tong:"], 224)
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", TempTable[i].szTongName or ""), 18)
			szTipInfo[#szTipInfo+1] = GetFormatText(_L["Title:"], 224)
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", TempTable[i].szTitle or ""), 18)

			if TempTable[i].nCamp ~=  nil then
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["Camp:"], 224)
				if TempTable[i].nCamp  ==  0 then
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Z"]), 27)
				elseif TempTable[i].nCamp  ==  1 then
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["H"]), 206)
				elseif TempTable[i].nCamp  ==  2 then
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["E"]), 102)
				end
			end

			szTipInfo[#szTipInfo+1] = GetFormatText(_L["TrainValue:"], 224)
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", TempTable[i].nCurrentTrainValue or ""), 18)

			if TempTable[i].nCurrentStamina ~=  nil then
				local nMaxStamina, nMaxThew, nCurrentStamina, nCurrentThew, SaveTime = 0, 0, 0, 0, 0
				local delta_time, delta_Stamina, delta_Thew, now_Stamina, now_Thew
				local GroupList = LR_AccountStatistics.GroupList

				nMaxStamina = TempTable[i].nMaxStamina or 0
				nMaxThew = TempTable[i].nMaxThew or 0
				nCurrentStamina = TempTable[i].nCurrentStamina or 0
				nCurrentThew = TempTable[i].nCurrentThew or 0
				SaveTime = TempTable[i].SaveTime or 0

				-----如果在分组里，刷新成分组里的数据
				local loginArea = TempTable[i].loginArea
				local loginServer = TempTable[i].loginServer
				local realArea = TempTable[i].realArea or loginArea
				local realServer = TempTable[i].realServer or loginServer
				local dwID = TempTable[i].dwID
				local szName = TempTable[i].szName
				local key = sformat("%s_%s_%d", realArea, realServer, dwID)
				if LR_AccountStatistics.AllUsrGroup[key] and LR_AccountStatistics.AllUsrGroup[key].groupID > 0 then
					local groupID = LR_AccountStatistics.AllUsrGroup[key].groupID
					nMaxStamina = GroupList[groupID].nMaxStamina or 0
					nMaxThew = GroupList[groupID].nMaxThew or 0
					nCurrentStamina = GroupList[groupID].nCurrentStamina or 0
					nCurrentThew = GroupList[groupID].nCurrentThew or 0
					SaveTime = GroupList[groupID].SaveTime or 0
				end

				delta_time = (GetCurrentTime() - SaveTime) / 60 / 6
				delta_Stamina = mfloor(nMaxStamina * 0.00078 * delta_time )
				delta_Thew =  mfloor(nMaxThew  * 0.00078 * delta_time)
				now_Stamina = nCurrentStamina + delta_Stamina
				now_Thew = nCurrentThew + delta_Thew
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["Stamina:"], 224)
				if now_Stamina>= nMaxStamina then
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%d%s", nMaxStamina, _L[" (FULL)"]), 71)
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat(" = %d + Δ%d\n", nCurrentStamina, nMaxStamina - nCurrentStamina), 18)
				else
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%d = %d + Δ%d\n", now_Stamina, nCurrentStamina, delta_Stamina), 18)
				end
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["Thew:"], 224)
				if now_Thew>= nMaxThew then
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%d%s", nMaxThew, _L[" (FULL)"]), 71)
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat(" = %d + Δ%d\n", nCurrentThew, nMaxThew - nCurrentThew), 18)
				else
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%d = %d +Δ%d\n", now_Thew, nCurrentThew, delta_Thew), 18)
				end
			else
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["Stamina:"], 224)
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", TempTable[i].nCurrentStamina or ""), 18)
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["Thew:"], 224)
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", TempTable[i].nCurrentThew or ""), 18)
			end
			if TempTable[i].remainJianBen then
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["JianBen this week remain:"], 224)
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", TempTable[i].remainJianBen), 18)
			end

			if LR_AccountStatistics.AllUsrGroup[key] and LR_AccountStatistics.AllUsrGroup[key].groupID and LR_AccountStatistics.AllUsrGroup[key].groupID > 0 then
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["Group name:"], 224)
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", LR_AccountStatistics.AllUsrGroup[key].szName), 18)
			end

			if IsCtrlKeyDown() then
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("dwID：%d\n", TempTable[i].dwID), 71)
			end

			local text = tconcat(szTipInfo)
			OutputTip(text, 360, {nMouseX, nMouseY, 0, 0})
		end
		items.OnItemMouseLeave = function()
			item_Select:Hide()
			HideTip()
		end
		items.OnItemLButtonClick = function()
			local frame = Station.Lookup("Normal/LR_AccountStatistics_Bag_Panel")
			local realArea = TempTable[i].realArea
			local realServer = TempTable[i].realServer
			local dwID = TempTable[i].dwID
			if not frame then
				LR_AccountStatistics_Bag_Panel:Open(realArea, realServer, dwID)
			else
				LR_AccountStatistics_Bag_Panel:ReloadItemBox(realArea, realServer, dwID)
			end
		end
		items.OnItemRButtonClick = function()
			PopupMenu(item_button_menu)
		end
		if bCal then
			AllMoney = AllMoney+TempTable[i].nMoney
		end
	end
	return num, AllMoney
end

function LR_AccountStatistics.ListAS()
	LR_AccountStatistics.LR_AS_Container:Clear()
	local TempTable_Cal, TempTable_NotCal = LR_AccountStatistics.SeparateUsrList()
	local AllMoney = 0
	local num = 0
	num, AllMoney = LR_AccountStatistics.ShowItem (TempTable_Cal, 255, true, 0, 0)
	num, AllMoney = LR_AccountStatistics.ShowItem (TempTable_NotCal, 60, false, num, AllMoney)
	LR_AccountStatistics.LR_AS_Container:FormatAllContentPos()
	local page = Station.Lookup("Normal/LR_AccountStatistics/PageSet_Menu/Page_LR_AS_Record")
	local Text_GoldBrick = page:Lookup("", "Text_GoldBrick")
	local Text_Gold = page:Lookup("", "Text_Gold")
	local Text_Silver = page:Lookup("", "Text_Silver")
	local Text_Copper = page:Lookup("", "Text_Copper")
	local nGoldBrick, nGold, nSilver, nCopper = LR.MoneyToGoldSilverAndCopper(AllMoney)

	Text_GoldBrick:SetText(nGoldBrick)
	Text_Gold:SetText(nGold)
	Text_Silver:SetText(nSilver)
	Text_Copper:SetText(nCopper)
end

function LR_AccountStatistics.Sort(a, b, num, nsort)
	local key_order = {"dwID"}
	if nsort  ==  "asc" then
		if a[key_order[num]] and b[key_order[num]] then
			if a[key_order[num]]  ==  b[key_order[num]] then
				return	LR_AccountStatistics.Sort(a, b, num+1, nsort)
			else
				return a[key_order[num]] < b[key_order[num]]
			end
		else
			return LR_AccountStatistics.Sort(a, b, num+1, nsort)
		end
	else
		if a[key_order[num]] and b[key_order[num]] then
			if a[key_order[num]]  ==  b[key_order[num]] then
				return	LR_AccountStatistics.Sort(a, b, num+1, nsort)
			else
				return a[key_order[num]] > b[key_order[num]]
			end
		else
			return	LR_AccountStatistics.Sort(a, b, num+1, nsort)
		end
	end
end

function LR_AccountStatistics.SeparateUsrList()
	local nkey = LR_AccountStatistics.UsrData.nkey or "nMoney"
	local nsort = LR_AccountStatistics.UsrData.nsort or "desc"

	LR_AccountStatistics.UpdateSelfInfoInAllData()
	local AllUsrData = LR_AccountStatistics.AllUsrData or {}
	local TempTable = {}
	for k, v in pairs (AllUsrData) do
		TempTable[#TempTable+1] = clone(v)
	end

	tsort(TempTable, function(a, b)
			if a[nkey] and b[nkey] then
				if nsort  ==  "asc" then
					if a[nkey]  ==  b[nkey] then
						if  a["nLevel"]  ==  b["nLevel"] then
							if a["dwForceID"]  ==  b["dwForceID"] then
								if a["szName"]  ==  b["szName"] then
									return a["dwID"] < b["dwID"]
								else
									return a["szName"] < b["szName"]
								end
							else
								return a["dwForceID"] < b["dwForceID"]
							end
						else
							return a["nLevel"] > b["nLevel"]
						end
					else
						return a[nkey] < b[nkey]
					end
				else
					if a[nkey]  ==  b[nkey] then
						if  a["nLevel"]  ==  b["nLevel"] then
							if a["dwForceID"]  ==  b["dwForceID"] then
								if a["szName"]  ==  b["szName"] then
									return a["dwID"] > b["dwID"]
								else
									return a["szName"] > b["szName"]
								end
							else
								return a["dwForceID"] < b["dwForceID"]
							end
						else
							return a["nLevel"] < b["nLevel"]
						end
					else
						return a[nkey] > b[nkey]
					end
				end
			else
				return true
			end
		end)

	local TempTable_NotCal = {}
	local TempTable_Cal = {}

	for i = 1, #TempTable, 1 do
		local bShow = true
		local GroupChose = LR_AccountStatistics.GroupChose
		local realArea = TempTable[i].realArea
		local realServer = TempTable[i].realServer
		local dwID = TempTable[i].dwID
		local szName = TempTable[i].szName
		local key = sformat("%s_%s_%d", realArea, realServer, dwID)
		local NotCalList = LR_AccountStatistics.UsrData.NotCalList or {}
		if #GroupChose == 0 then
			if NotCalList[key] then
				bShow = false
			end
		else
			local isExist = false
			for j = 1, #GroupChose, 1 do
				if LR_AccountStatistics.ifGroupHasUser(key, GroupChose[j]) then
					isExist = true
				end
			end
			if not isExist then
				bShow = false
			end
		end
		if bShow then
			tinsert (TempTable_Cal, TempTable[i])
		else
			tinsert (TempTable_NotCal, TempTable[i])
		end
	end

	return TempTable_Cal, TempTable_NotCal
end

function LR_AccountStatistics.ShowGroup()
	local menu = {}
	local GroupList = LR_AccountStatistics.GroupList
	for groupID, v in pairs(GroupList) do
		local szGroupName = v.szName
		tinsert(menu, {szOption = szGroupName, bCheck = true, bMCheck = false, bChecked = function() return LR_AccountStatistics.CheckShowGroup(groupID) end,
			fnAction = function()
				local path = sformat("%s\\%s", SaveDataPath, DB_name)
				local DB = SQLite3_Open(path)
				DB:Execute("BEGIN TRANSACTION")
				LR_AccountStatistics.AddShowGroup(groupID)
				LR_AccountStatistics.LoadAllUserInformation(DB)
				LR_AccountStatistics.ListAS()
				LR_AccountStatistics_FBList.ListFB()
				LR_AccountStatistics_RiChang.ListRC()
				LR_ACS_QiYu.ListQY()
				LR_Acc_Achievement_Panel:ReloadItemBox()
				DB:Execute("END TRANSACTION")
				DB:Release()
				FireEvent("LR_ACS_REFRESH_FP")
			end,
			{szOption = _L["Delete Group"],
				fnAction = function()
					local path = sformat("%s\\%s", SaveDataPath, DB_name)
					local DB = SQLite3_Open(path)
					DB:Execute("BEGIN TRANSACTION")
					LR_AccountStatistics.DelGroup(groupID, DB)
					LR_AccountStatistics.AddShowGroup(groupID, "DEL")
					LR_AccountStatistics.LoadAllUserInformation(DB)
					LR_AccountStatistics.ListAS()
					LR_AccountStatistics_FBList.ListFB()
					LR_AccountStatistics_RiChang.ListRC()
					LR_ACS_QiYu.ListQY()
					DB:Execute("END TRANSACTION")
					DB:Release()
				end
			},
			{szOption = _L["Rename Group"],
				fnAction = function()
					GetUserInput(_L["Group Name"], function(szText)
						local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
						if szText ~=  "" then
							local path = sformat("%s\\%s", SaveDataPath, DB_name)
							local DB = SQLite3_Open(path)
							DB:Execute("BEGIN TRANSACTION")
							LR_AccountStatistics.RenameGroup(groupID, szText, DB)
							LR_AccountStatistics.ListAS()
							LR_AccountStatistics_FBList.ListFB()
							LR_AccountStatistics_RiChang.ListRC()
							LR_ACS_QiYu.ListQY()
							DB:Execute("END TRANSACTION")
							DB:Release()
						end
					end)
				end
			},
		})
	end
	tinsert(menu, {bDevide = true,})
	tinsert(menu, {szOption = _L["Show data not in choose group. (translucence)"], bCheck = true, bMCheck = false, bChecked = function() return LR_AccountStatistics.showDataNotInGroup end,
		fnAction = function()
			LR_AccountStatistics.showDataNotInGroup = not LR_AccountStatistics.showDataNotInGroup
			local path = sformat("%s\\%s", SaveDataPath, DB_name)
			local DB = SQLite3_Open(path)
			DB:Execute("BEGIN TRANSACTION")
			LR_AccountStatistics.LoadAllUserInformation(DB)
			LR_AccountStatistics.ListAS()
			LR_AccountStatistics_FBList.ListFB()
			LR_AccountStatistics_RiChang.ListRC()
			LR_ACS_QiYu.ListQY()
			DB:Execute("END TRANSACTION")
			DB:Release()
		end,
	})
	tinsert(menu, {szOption = _L["Add Group"],
		fnAction = function()
			GetUserInput(_L["Group Name"], function(szText)
				local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
				if szText ~=  "" then
					local path = sformat("%s\\%s", SaveDataPath, DB_name)
					local DB = SQLite3_Open(path)
					DB:Execute("BEGIN TRANSACTION")
					LR_AccountStatistics.AddGroup(szText, DB)
					LR_AccountStatistics.ListAS()
					LR_AccountStatistics_FBList.ListFB()
					LR_AccountStatistics_RiChang.ListRC()
					LR_ACS_QiYu.ListQY()
					DB:Execute("END TRANSACTION")
					DB:Release()
				end
			end)
		end,
	})
	PopupMenu(menu)
end

function LR_AccountStatistics.AddShowGroup(groupID, flag)
	local GroupChose = LR_AccountStatistics.GroupChose or {}
	local bExist = false
	for i = #GroupChose, 1, -1 do
		if GroupChose[i] == groupID then
			tremove(LR_AccountStatistics.GroupChose, i)
			bExist = true
		end
	end
	if not bExist and not flag then
		tinsert(LR_AccountStatistics.GroupChose, groupID)
	end
end

function LR_AccountStatistics.CheckShowGroup(groupID)
	local GroupChose = LR_AccountStatistics.GroupChose
	for i = 1, #GroupChose, 1 do
		if GroupChose[i] == groupID then
			return true
		end
	end
	return false
end

function LR_AccountStatistics.OpenItemPanel ()
	LR_AccountStatistics_Bag_Panel:Open()
end

function LR_AccountStatistics.OpenBookRdPanel()
	LR_BookRd_Panel:Open()
end

function LR_AccountStatistics.Open7Year()
	LR_Acc_Achievement_Panel:Open()
end

function LR_AccountStatistics.OpenQuestTool_Panel()
	LR_QuestTools:Open()
end

function LR_AccountStatistics.SetOption()
	local frame = Station.Lookup("Normal/LR_TOOLS")
	if not frame then
		LR_TOOLS:OpenPanel(_L["LR_AS_Global_Settings"])
	else
		LR_TOOLS:OpenPanel()
		LR_TOOLS:OpenPanel(_L["LR_AS_Global_Settings"])
	end
end

function LR_AccountStatistics.OpenQYDetail_Panel()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local ServerInfo = {GetUserServer()}
	local realArea, realServer = ServerInfo[5], ServerInfo[6]
	local szName = me.szName
	local dwID = me.dwID

	LR_ACS_QiYu_Panel:Open(realArea, realServer, dwID)
end

-----------------------------
---删除确认界面
-----------------------------
LR_AccountStatistics_DelPanel = {}
LR_AccountStatistics_DelPanel = CreateAddon("LR_AccountStatistics_DelPanel")
LR_AccountStatistics_DelPanel_Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0}

function LR_AccountStatistics_DelPanel.OnFrameCreate ()
	this:SetPoint(LR_AccountStatistics_DelPanel_Anchor.s, 0, 0, LR_AccountStatistics_DelPanel_Anchor.r, LR_AccountStatistics_DelPanel_Anchor.x, LR_AccountStatistics_DelPanel_Anchor.y)
	this:CorrectPos()

	RegisterGlobalEsc("LR_AccountStatistics_DelPanel", function () return true end , function() LR_AccountStatistics_DelPanel:Open() end)
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

function LR_AccountStatistics_DelPanel:Init()
	local frame = self:Append("Frame", "LR_AccountStatistics_DelPanel", {title = _L["Are you sure to delete?"], path = "interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics_Del.ini"})

	--创建一个按钮
	local button1 = LR_AccountStatistics_DelPanel:Append("Button", frame, "button1", {text = _L["Yes"], x = 15, y = 40, w = 95, h = 26})
	--绑定按钮点击事件
	button1.OnClick = function()
		local key = LR_AccountStatistics.del_data_id or {}
		if next(key)~= nil then
			local path = sformat("%s\\%s", SaveDataPath, DB_name)
			local DB = SQLite3_Open(path)
			DB:Execute("BEGIN TRANSACTION")
			LR_AccountStatistics.DelOneData(key, DB)
			LR_AccountStatistics.LoadUserList(DB)
			LR_AccountStatistics.LoadAllUserInformation(DB)
			LR_AccountStatistics.LoadAllUserGroup(DB)
			LR_AccountStatistics_DelPanel:Open()
			LR_AccountStatistics.ListAS()
			LR_AccountStatistics_FBList.ListFB()
			LR_AccountStatistics_RiChang.ListRC()
			LR_ACS_QiYu.ListQY()
			DB:Execute("END TRANSACTION")
			DB:Release()
		else
			return
		end
	end
	local button2 = LR_AccountStatistics_DelPanel:Append("Button", frame, "button2", {text = _L["Cancle"], x = 120, y = 40, w = 95, h = 26})
		button2.OnClick = function()
			LR_AccountStatistics.del_data_id = {}
			LR_AccountStatistics_DelPanel:Open()
		end
end

function LR_AccountStatistics_DelPanel.OnFrameDestroy ()
	UnRegisterGlobalEsc("LR_AccountStatistics_DelPanel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_AccountStatistics_DelPanel:Open()
	local frame = self:Fetch("LR_AccountStatistics_DelPanel")
	if frame then
		self:Destroy(frame)
	else
		frame = self:Init()
	end
end

--------------------------------------------
----分组
--------------------------------------------
function LR_AccountStatistics.LoadGroupListData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM group_list WHERE groupID IS NOT NULL")
	DB_SELECT:ClearBindings()
	local Data = DB_SELECT:GetAll() or {}
	local Group = {}
	for k, v in pairs(Data) do
		Group[v.groupID] = v
	end
	LR_AccountStatistics.GroupList = clone(Group)
end

function LR_AccountStatistics.UpdateMyGroupInfo(DB)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local DB_SELECT = DB:Prepare("SELECT group_list.* FROM group_list INNER JOIN player_group ON player_group.groupID = group_list.groupID WHERE player_group.szKey = ? AND player_group.groupID > 0 AND player_group.szKey IS NOT NULL")
	DB_SELECT:ClearBindings()
	DB_SELECT:BindAll(szKey)
	local result = DB_SELECT:GetAll() or {}
	if result and next(result) ~= nil then
		local v = result[1]
		v.nMaxStamina = me.nMaxStamina or 0
		v.nCurrentStamina = me.nCurrentStamina or 0
		v.nMaxThew = me.nMaxThew or 0
		v.nCurrentThew = me.nCurrentThew or 0
		v.SaveTime = GetCurrentTime()
		local DB_REPLACE = DB:Prepare("REPLACE INTO group_list ( groupID, szName, nCurrentStamina, nMaxStamina, nCurrentThew, nMaxThew, SaveTime ) VALUES ( ?, ?, ?, ?, ?, ?, ? )")
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(v.groupID, v.szName, v.nCurrentStamina, v.nMaxStamina, v.nCurrentThew, v.nMaxThew, v.SaveTime)
		DB_REPLACE:Execute()
	end
end

function LR_AccountStatistics.LoadAllUserGroup(DB)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local DB_SELECT = DB:Prepare("SELECT player_group.*, group_list.szName FROM player_group INNER JOIN group_list ON group_list.groupID = player_group.groupID WHERE player_group.szKey IS NOT NULL")
	local Data = DB_SELECT:GetAll()
	local AllUsrGroup = {}
	for k, v in pairs(Data) do
		AllUsrGroup[v.szKey] = v
	end
	LR_AccountStatistics.AllUsrGroup = clone(AllUsrGroup)
end


function LR_AccountStatistics.ifGroupHasUser(key, groupID)
	if LR_AccountStatistics.AllUsrGroup[key] and LR_AccountStatistics.AllUsrGroup[key].groupID == groupID then
		return true
	else
		return false
	end
end

function LR_AccountStatistics.GetGroupIDbyGropuName(szGroupName)
	local Group = LR_AccountStatistics.GroupList
	for k, v in pairs (Group) do
		if v.szName == szGroupName then
			return k
		end
	end
	return 0
end

function LR_AccountStatistics.ChangeUserGroup(szKey, groupID, DB)
	if groupID > 0 then
		local DB_REPLACE = DB:Prepare("REPLACE INTO player_group (szKey, groupID) VALUES ( ?, ? )")
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey, groupID)
		DB_REPLACE:Execute()
	else
		local DB_DELETE = DB:Prepare("DELETE FROM player_group WHERE szKey = ?")
		DB_DELETE:ClearBindings()
		DB_DELETE:BindAll(szKey)
		DB_DELETE:Execute()
	end
	LR_AccountStatistics.LoadAllUserGroup(DB)
end

function LR_AccountStatistics.AddGroup(szGroupName, DB)
	local GroupID = LR_AccountStatistics.GetGroupIDbyGropuName(szGroupName)
	if GroupID == 0 then
		local DB_INSERT = DB:Prepare("INSERT INTO group_list (szName) VALUES ( ? )")
		DB_INSERT:ClearBindings()
		DB_INSERT:BindAll(szGroupName)
		DB_INSERT:Execute()
		LR_AccountStatistics.LoadGroupListData(DB)
	else
		LR.SysMsg(_L["Already have the same name group.\n"])
	end
end

function LR_AccountStatistics.DelGroup(groupID, DB)
	local DB_DELETE = DB:Prepare("DELETE FROM group_list WHERE groupID = ?")
	DB_DELETE:ClearBindings()
	DB_DELETE:BindAll(groupID)
	DB_DELETE:Execute()
	local DB_DELETE2 = DB:Prepare("DELETE FROM player_group WHERE groupID = ?")
	DB_DELETE2:ClearBindings()
	DB_DELETE2:BindAll(groupID)
	DB_DELETE2:Execute()
	LR_AccountStatistics.LoadGroupListData(DB)
end

function LR_AccountStatistics.RenameGroup(groupID, szNewGroupName, DB)
	local ID = LR_AccountStatistics.GetGroupIDbyGropuName(szNewGroupName)
	if ID == 0 then
		local DB_UPDATE = DB:Prepare("UPDATE group_list SET szName = ? WHERE groupID = ?")
		DB_UPDATE:ClearBindings()
		DB_UPDATE:BindAll(szNewGroupName, groupID)
		DB_UPDATE:Execute()
		LR_AccountStatistics.LoadGroupListData(DB)
	else
		LR.SysMsg(_L["Already have the same name group.\n"])
	end
end

----------------------------------------------
function LR_AccountStatistics.FIRST_LOADING_END()
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	LR_AccountStatistics.CheckUsrDataVersion()
	LR_AccountStatistics.LoadUserList(DB)
	LR_AccountStatistics.LoadGroupListData(DB)
	LR_AccountStatistics.LoadAllUserInformation(DB)
	LR_AccountStatistics.LoadAllUserGroup(DB)
	--装备获取及装分
	LR_AccountStatistics_Equip.LoadSelfData(DB)
	----获取奇遇数据
	LR_ACS_QiYu.LoadAllUsrData(DB)

	DB:Execute("END TRANSACTION")
	DB:Release()
	FireEvent("LR_ACS_REFRESH_FP")
	LR.DelayCall(15000, LR_AccountStatistics.AutoSave())
end

LR.RegisterEvent("FIRST_LOADING_END", function() LR_AccountStatistics.FIRST_LOADING_END() end)




