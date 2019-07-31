local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AS_Module_PlayerInfo"
local LanguagePath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local db_name = "maindb.db"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20180403a"
-------------------------------------------------------------
local LOGIN_TIME = 0

LR_AS_Base.PlayerInfoUI = {}
LR_AS_Base.PlayerInfoUI.TitleOrder = {
	"nMoney", "BangGong", "remainBangGong", "XiaYi", "remainXiaYi", "JianBen", "nVigor", "nVigorRemainSpace", "WeiWang", "remainWeiWang", "ZhanJieJiFen", "remainZhanJieJiFen", "ZhanJieDengJi", "MingJianBi", "LastLoginTime"
}
local DefaultShowData = {
	["szName"] = true,
	["nMoney"] = true,
	["BangGong"] = true,
	["remainBangGong"] = false,
	["XiaYi"] = true,
	["remainXiaYi"] = true,
	["JianBen"] = true,
	["nVigor"] = true,
	["nVigorRemainSpace"] = true,
	["WeiWang"] = true,
	["remainWeiWang"] = false,
	["ZhanJieDengJi"] = false,
	["remainZhanJieJiFen"] = false,
	["ZhanJieDengJi"] = false,
	["MingJianBi"] = false,
	["LastLoginTime"] = false,
}
LR_AS_Base.PlayerInfoUI.ShowData = clone(DefaultShowData)

LR_AS_Base.PlayerInfoUI.Width = {
	["szName"] = 150,
	["nMoney"] = 200,
	["BangGong"] = 95,
	["remainBangGong"] = 95,
	["XiaYi"] = 80,
	["remainXiaYi"] = 80,
	["JianBen"] = 100,
	["nVigor"] = 80,
	["nVigorRemainSpace"] = 80,
	["WeiWang"] = 80,
	["remainWeiWang"] = 80,
	["ZhanJieJiFen"] = 80,
	["remainZhanJieJiFen"] = 80,
	["ZhanJieDengJi"] = 80,
	["MingJianBi"] = 80,
	["LastLoginTime"] = 80,
}

local _C = {}
----------------------------------------------------
------配置读取保存
----------------------------------------------------
function _C.CfgSave()
	local path = sformat("%s\\%s", SaveDataPath, "PlayerInfoCfg.dat")
	local data = {VERSION = VERSION, data = clone(LR_AS_Base.PlayerInfoUI.ShowData)}
	LR.SaveLUAData(path, data, "")
end

function _C.CfgLoad()
	local path = sformat("%s\\%s", SaveDataPath, "PlayerInfoCfg.dat")
	local data = LoadLUAData(path) or {}
	if not data.VERSION or data.VERSION ~= VERSION then
		_C.CfgReset()
		return
	end
	LR_AS_Base.PlayerInfoUI.ShowData = clone(data.data)
end

function _C.CfgReset()
	local path = sformat("%s\\%s", SaveDataPath, "PlayerInfoCfg.dat")
	local data = {VERSION = VERSION, data = clone(DefaultShowData)}
	LR.SaveLUAData(path, data, "")
	LR_AS_Base.PlayerInfoUI.ShowData = clone(DefaultShowData)
end

function _C.LOGIN_GAME()
	_C.CfgLoad()
	LOGIN_TIME = GetCurrentTime()
end

LR.RegisterEvent("LOGIN_GAME", function() _C.LOGIN_GAME() end)
----------------------------------------------------
------数据获取保存
----------------------------------------------------
local DATA2BSAVE = {}

function _C.CheckTitleDisable(szName)
	if LR_AS_Base.PlayerInfoUI.ShowData[szName] then
		return false
	end
	local nTotalWidth = 0
	local TitleOrder = clone(LR_AS_Base.PlayerInfoUI.TitleOrder)
	tinsert(TitleOrder, 1, "szName")
	for k, v in pairs(TitleOrder) do
		if LR_AS_Base.PlayerInfoUI.ShowData[v] then
			nTotalWidth = nTotalWidth + LR_AS_Base.PlayerInfoUI.Width[v]
		end
	end
	if not LR_AS_Base.PlayerInfoUI.ShowData[szName] then
		nTotalWidth = nTotalWidth + LR_AS_Base.PlayerInfoUI.Width[szName]
	end
	return nTotalWidth >= 975
end

function _C.GetSelfData()
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]

	local UserInfo = {}
	UserInfo.szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local nMoney = me.GetMoney()
	UserInfo.nGold = nMoney.nGold
	UserInfo.nSilver = nMoney.nSilver
	UserInfo.nCopper = nMoney.nCopper
	UserInfo.nMoney = nMoney.nCopper + nMoney.nSilver * 100 + nMoney.nGold * 10000
	UserInfo.JianBen, UserInfo.remainJianBen = LR.GetSelfJianBen()	--监本
	UserInfo.BangGong, UserInfo.remainBangGong = LR.GetSelfJiangGong()	--帮贡
	UserInfo.XiaYi, UserInfo.remainXiaYi = LR.GetSelfXiaYi()	--狭义
	UserInfo.WeiWang, UserInfo.remainWeiWang = LR.GetSelfWeiWang()	--威望
	UserInfo.ZhanJieJiFen, UserInfo.remainZhanJieJiFen = LR.GetSelfZhanJieJiFen()	--战阶积分
	UserInfo.ZhanJieDengJi = LR.GetSelfZhanJieDengJi()	--战阶等级
	UserInfo.MingJianBi, UserInfo.remainMingJianBi = LR.GetSelfMingJianBi()	--名剑币
	UserInfo.szTitle = me.szTitle or ""	--称号
	UserInfo.nCurrentTrainValue = me.nCurrentTrainValue or 0	--修为
	UserInfo.nCamp = me.nCamp or 0		--阵营
	UserInfo.szTongName = LR.GetTongName(me.dwTongID) or ""	--帮会名称
	UserInfo.SaveTime = GetCurrentTime()
	UserInfo.LastLoginTime = LOGIN_TIME
	UserInfo.LastLogoutTime = GetCurrentTime()

	--100级新版精力
	UserInfo.nVigor = me.nVigor
	UserInfo.nMaxVigor = me.GetMaxVigor()
	UserInfo.nVigorRemainSpace = me.GetVigorRemainSpace()

	return UserInfo
end

function _C.PrepareData()
	DATA2BSAVE = _C.GetSelfData()
end

function _C.SaveData(DB, TestData)
	-------保存自身的属性数据
	local v = TestData or clone(DATA2BSAVE) or {}
	local DB_REPLACE = DB:Prepare("REPLACE INTO player_info (szKey, nGold, nSilver, nCopper, JianBen, remainJianBen, BangGong, remainBangGong, XiaYi, remainXiaYi, WeiWang, remainWeiWang, ZhanJieJiFen, remainZhanJieJiFen, ZhanJieDengJi, MingJianBi, remainMingJianBi, szTitle, nCurrentTrainValue, nCamp, szTongName, nVigor, nMaxVigor, nVigorRemainSpace, SaveTime, LastLoginTime, LastLogoutTime) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )")
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(unpack(g2d({v.szKey, v.nGold, v.nSilver, v.nCopper, v.JianBen, v.remainJianBen, v.BangGong, v.remainBangGong, v.XiaYi, v.remainXiaYi, v.WeiWang, v.remainWeiWang, v.ZhanJieJiFen, v.remainZhanJieJiFen, v.ZhanJieDengJi, v.MingJianBi, v.remainMingJianBi, v.szTitle, v.nCurrentTrainValue, v.nCamp, v.szTongName, v.nVigor, v.nMaxVigor, v.nVigorRemainSpace, v.SaveTime, LOGIN_TIME, GetCurrentTime()})))
	DB_REPLACE:Execute()
end

function _C.LoadData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM player_info WHERE szKey IS NOT NULL ORDER BY nGold DESC, nSilver DESC, nCopper DESC")
	local data = d2g(DB_SELECT:GetAll())
	local AllUsrInfo = {}
	for k, v in pairs(data) do
		AllUsrInfo[v.szKey] = v
		AllUsrInfo[v.szKey].nMoney = v.nGold * 10000 + v.nSilver * 100 + v.nCopper
	end
	local myself = _C.GetSelfData()
	AllUsrInfo[myself.szKey] = clone(myself)
	LR_AS_Data.AllPlayerInfo = clone(AllUsrInfo)
end

function _C.RepairDB(DB)
	--导入数据
	_C.LoadData(DB)
	local all_data = {}
	local AllPlayerList = clone(LR_AS_Data.AllPlayerList)
	local value1 = function(value, default)
		return value and value ~= "" and value or default
	end
	for szKey, v2 in pairs(AllPlayerList) do
		local data = {}
		local v = LR_AS_Data.AllPlayerInfo[szKey] or {}
		data.szKey = szKey
		data.nGold = value1(v.nGold, 0)
		data.nSilver = value1(v.nSilver, 0)
		data.nCopper = value1(v.nCopper, 0)
		data.nMoney = data.nCopper + data.nSilver * 100 + data.nGold * 10000
		data.JianBen, data.remainJianBen = value1(v.JianBen, 0), value1(v.remainJianBen, 1500)	--监本
		data.BangGong, data.remainBangGong = value1(v.BangGong, 0), value1(v.remainBangGong, 170000)		--帮贡
		data.XiaYi, data.remainXiaYi = value1(v.XiaYi, 0), value1(v.remainXiaYi, 9000)	--狭义
		data.WeiWang, data.remainWeiWang = value1(v.WeiWang, 0), value1(v.remainWeiWang, 180000)	--威望
		data.ZhanJieJiFen, data.remainZhanJieJiFen = value1(v.ZhanJieJiFen, 0), value1(v.remainZhanJieJiFen, 0)	--战阶积分
		data.ZhanJieDengJi = value1(v.ZhanJieDengJi, 0)	--战阶等级
		data.MingJianBi, data.remainMingJianBi = value1(v.MingJianBi, 0), value1(v.remainMingJianBi, 0)	--名剑币
		data.szTitle = value1(v.szTitle, "")	--称号
		data.nCurrentTrainValue = value1(v.nCurrentTrainValue, 0)	--修为
		data.nCamp = value1(v.nCamp, 0)	--阵营
		data.szTongName = value1(v.szTongName, "")	--帮会名称
		data.SaveTime = GetCurrentTime()
		data.LastLoginTime = value1(v.LastLoginTime, 0)
		data.LastLogoutTime = value1(v.LastLogoutTime, 0)

		--100级新版精力
		data.nVigor = value1(v.nVigor, 0)
		data.nMaxVigor = value1(v.nMaxVigor, 0)
		data.nVigorRemainSpace = value1(v.nVigorRemainSpace, 0)
		all_data[szKey] = clone(data)
	end
	--先清除数据库
	local DB_DELETE = DB:Prepare("DELETE FROM player_info")
	DB_DELETE:Execute()
	--保存数据
	local DB_REPLACE = DB:Prepare("REPLACE INTO player_info (szKey, nGold, nSilver, nCopper, JianBen, remainJianBen, BangGong, remainBangGong, XiaYi, remainXiaYi, WeiWang, remainWeiWang, ZhanJieJiFen, remainZhanJieJiFen, ZhanJieDengJi, MingJianBi, remainMingJianBi, szTitle, nCurrentTrainValue, nCamp, szTongName, nVigor, nMaxVigor, nVigorRemainSpace, SaveTime, LastLoginTime, LastLogoutTime) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )")
	for k, v in pairs(all_data) do
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(unpack(g2d({v.szKey, v.nGold, v.nSilver, v.nCopper, v.JianBen, v.remainJianBen, v.BangGong, v.remainBangGong, v.XiaYi, v.remainXiaYi, v.WeiWang, v.remainWeiWang, v.ZhanJieJiFen, v.remainZhanJieJiFen, v.ZhanJieDengJi, v.MingJianBi, v.remainMingJianBi, v.szTitle, v.nCurrentTrainValue, v.nCamp, v.szTongName, v.nVigor, v.nMaxVigor, v.nVigorRemainSpace, v.SaveTime, v.LastLoginTime, v.LastLogoutTime})))
		DB_REPLACE:Execute()
	end
end

--每周重置可以获得的监本、精力数量
function _C.ClearAllReaminJianBenAndJingLi(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM player_info WHERE szKey IS NOT NULL")
	local Data = d2g(DB_SELECT:GetAll())
	local DB_REPLACE = DB:Prepare("REPLACE INTO player_info (szKey, nGold, nSilver, nCopper, JianBen, remainJianBen, BangGong, remainBangGong, XiaYi, remainXiaYi, WeiWang, remainWeiWang, ZhanJieJiFen, remainZhanJieJiFen, ZhanJieDengJi, MingJianBi, remainMingJianBi, szTitle, nCurrentTrainValue, nCamp, szTongName, nVigor, nMaxVigor, nVigorRemainSpace, SaveTime, LastLoginTime, LastLogoutTime) VALUES ( ?, ?, ?, ?, ?, 1500, ?, 200000, ?, 9000, ?, 200000, ?, ?, ?, ?, 2400, ?, ?, ?, ?, ?, ?, 3000, ?, ?, ? )")
	for k, v in pairs (Data) do
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(unpack(g2d({v.szKey, v.nGold, v.nSilver, v.nCopper, v.JianBen, v.BangGong, v.XiaYi, v.WeiWang, v.ZhanJieJiFen, v.remainZhanJieJiFen, v.ZhanJieDengJi, v.MingJianBi, v.szTitle, v.nCurrentTrainValue, v.nCamp, v.szTongName, v.nVigor, v.nMaxVigor, GetCurrentTime(), v.LastLoginTime, v.LastLogoutTime})))
		DB_REPLACE:Execute()
	end
end

function _C.ResetDataMonday(DB)
	_C.ClearAllReaminJianBenAndJingLi(DB)
end

----------------------------------------------------
------主界面显示奇遇信息
----------------------------------------------------
function _C.AddPage()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end

	local PageSet_Menu = frame:Lookup("PageSet_Menu")
	local Btn = PageSet_Menu:Lookup("WndCheck_PlayerInfo")

	local page = Wnd.OpenWindow(sformat("%s\\UI\\page.ini", AddonPath), "temp"):Lookup("Page_PlayerInfo")
	page:ChangeRelation(PageSet_Menu, true, true)
	page:SetName("Page_PlayerInfo")
	Wnd.CloseWindow("temp")
	PageSet_Menu:AddPage(page, Btn)

	Btn:Enable(true)
	Btn:Lookup("",""):Lookup("Text_PlayerInfo"):SetFontColor(255, 255, 255)

	_C.Container = LR.AppendUI("Scroll", page, "WndScroll_PlayInfo", {x = 20, y = 50, w = 980, h = 480})
	_C.ReFreshTitle()
	_C.ListAS()

	_C.AddPageButton()
end

---刷新标题
function _C.ReFreshTitle()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end
	local Handle_Title = frame:Lookup("PageSet_Menu"):Lookup("Page_PlayerInfo"):Lookup("",""):Lookup("Handle_Title")
	local TitleOrder = clone(LR_AS_Base.PlayerInfoUI.TitleOrder)
	tinsert(TitleOrder, 1, "szName")
	Handle_Title:Clear()
	local nX, n = 0, 1
	for k, v in pairs(TitleOrder) do
		if LR_AS_Base.PlayerInfoUI.ShowData[v] then
			if n > 1 then
				local image_break = LR.AppendUI("Image", Handle_Title, sformat("ImageBreak_%d", n - 1), {x = nX, y = 0, w = 3, h = 506,})
				image_break:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
			end

			local text_title = LR.AppendUI("Text", Handle_Title, sformat("Text_Title_%s", v), {x = nX, y = 0, w = LR_AS_Base.PlayerInfoUI.Width[v], h = 30, text = _L[v]})
			text_title:SetVAlign(1):SetHAlign(1):SetFontScheme(44):RegisterEvent(786)
			if LR_AS_Base.UsrData.nKey == v or LR_AS_Base.UsrData.nKey == "nLevel" and v == "szName" then
				if LR_AS_Base.UsrData.nSort  ==  "asc" then
					text_title:SetText(sformat("%s%s", _L[v], _L["JianTouShang"]))
					text_title:SetFontScheme(99)
				elseif LR_AS_Base.UsrData.nSort  ==  "desc" then
					text_title:SetText(sformat("%s%s", _L[v], _L["JianTouXia"]))
					text_title:SetFontScheme(99)
				end
			end

			text_title.OnClick = function()
				if LR_AS_Base.UsrData.nKey == v or LR_AS_Base.UsrData.nKey == "nLevel" and v == "szName"  then
					if LR_AS_Base.UsrData.nSort  ==  "asc" then
						LR_AS_Base.UsrData.nSort = "desc"
					else
						LR_AS_Base.UsrData.nSort = "asc"
					end
				end
				if v == "szName" then
					LR_AS_Base.UsrData.nKey = "nLevel"
				else
					LR_AS_Base.UsrData.nKey = v
				end
				_C.ReFreshTitle()
				_C.ListAS()
				--LR_AccountStatistics_FBList.ListFB()
				--LR_AccountStatistics_RiChang.ListRC()
				--LR_ACS_QiYu.ListQY()
			end
			text_title.OnEnter = function()
				this:SetFontColor(255, 128, 0)
			end
			text_title.OnLeave = function()
				if LR_AS_Base.UsrData.nKey == v then
					text_title:SetFontScheme(99)
				else
					text_title:SetFontColor(255, 255, 255)
				end
			end

			nX = nX + LR_AS_Base.PlayerInfoUI.Width[v]
			n = n + 1
		end
	end
	if nX < 955 then
		local image_break = LR.AppendUI("Image", Handle_Title, sformat("ImageBreak_%d", n - 1), {x = nX, y = 0, w = 3, h = 506,})
		image_break:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
	end
end

--刷新列表
function _C.ListAS()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end

	_C.Container:ClearHandle()
	local TempTable_Cal, TempTable_NotCal = LR_AS_Base.SeparateUsrList()
	local AllMoney = 0
	local num = 0
	num, AllMoney = _C.ShowItem(TempTable_Cal, 255, true, 0, 0)
	num, AllMoney = _C.ShowItem(TempTable_NotCal, 60, false, num, AllMoney)
	_C.Container:UpdateList()
	local page = Station.Lookup("Normal/LR_AS_Panel/PageSet_Menu/Page_PlayerInfo")
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

function _C.ShowItem(t_Table, Alpha, bCal, _num, _money)
	local num = _num
	local AllMoney = _money
	local PlayerList = clone(t_Table)
	local me = GetClientPlayer()
	for k, v in pairs(PlayerList) do
		num = num + 1
		local Handle_Role = LR.AppendUI("HoverHandle", _C.Container, sformat("%s_%s_%s", v.realArea, v.realServer, v.szName), {w = 954, h = 30})

		local szKey = sformat("%s_%s_%d", v.realArea, v.realServer, v.dwID)
		local PlayerInfo = LR_AS_Data.AllPlayerInfo[szKey] or {}
		local szPath, nFrame = GetForceImage(v.dwForceID)

		local TitleOrder = clone(LR_AS_Base.PlayerInfoUI.TitleOrder)
		tinsert(TitleOrder, 1, "szName")
		local nX, n = 0, 1
		for k2, v2 in pairs(TitleOrder) do
			if LR_AS_Base.PlayerInfoUI.ShowData[v2] then
				if v2 == "szName" then
					local Image_MenPai = LR.AppendUI("Image", Handle_Role, "Image_MenPai", {x = nX, y = 0, w = 30, h = 30})
					Image_MenPai:FromUITex(GetForceImage(v.dwForceID))

					local Text_Name = LR.AppendUI("Text", Handle_Role, "Text_Name", {x = nX + 30, y = 0, w = LR_AS_Base.PlayerInfoUI.Width["szName"] - 30, h = 30})
					Text_Name:SetHAlign(0):SetVAlign(1):SetFontScheme(2)
					local name = v.szName
					if wslen(name) > 6 then
						name = sformat("%s...", wssub(name, 1, 5))
					end
					Text_Name:SprintfText(_L["%s(%d)"], name, v.nLevel)
					local r, g, b = LR.GetMenPaiColor(v.dwForceID)
					Text_Name:SetFontColor(r, g, b)
				elseif v2 == "nMoney" then
					local Handle_Money = Handle_Role:AppendItemFromIni(sformat("%s\\UI\\HandleMoney.ini", AddonPath), "Handle_Record", "Handle_Money")
					Handle_Money:SetRelPos(nX, 0)
					local nGoldBrick, nGold, nSilver, nCopper = LR.MoneyToGoldSilverAndCopper(PlayerInfo.nMoney or 0)
					Handle_Money:Lookup("Text_GoldBrick"):SetText(nGoldBrick)
					Handle_Money:Lookup("Text_Gold"):SetText(nGold)
					Handle_Money:Lookup("Text_Silver"):SetText(nSilver)
					Handle_Money:Lookup("Text_Copper"):SetText(nCopper)
				else
					local Text = LR.AppendUI("Text", Handle_Role, sformat("Text_%s", v2), {x = nX, y = 0, w = LR_AS_Base.PlayerInfoUI.Width[v2], h = 30})
					Text:SetVAlign(1):SetHAlign(1):SetFontScheme(2):SetText(PlayerInfo[v2])
					if v2 == "JianBen" then
						local nJianBen = tostring(PlayerInfo.JianBen or "--")
						local examData = LR_AS_Data.ExamData[szKey] or {["ShengShi"] = 0, ["HuiShi"] = 0, }
						if examData["HuiShi"] == 1 then
							Text:SprintfText(_L["H%sH"], nJianBen)
						elseif examData["ShengShi"] == 1 then
							Text:SprintfText(_L["S%sS"], nJianBen)
						else
							Text:SetText(nJianBen)
						end
						local remainJianBen = PlayerInfo.remainJianBen or 1500
						if remainJianBen < 100 then
							Text:SetFontScheme(207)
							Text:SetFontColor(255, 0, 128)
						elseif remainJianBen < 300 then
							Text:SetFontScheme(207)
							Text:SetFontColor(215, 215, 0)
						end
					elseif v2 == "LastLoginTime" then
						local delta = GetCurrentTime() - PlayerInfo.LastLoginTime
						if delta < 60 * 60 then
							Text:SetText(sformat(_L["%d minute ago"], mfloor(delta / 60)))
						elseif delta < 60 * 60 * 48 then
							Text:SetText(sformat(_L["%d hour ago"], mfloor(delta / 60 / 60)))
						elseif delta < 60 * 60 * 24 * 365 * 3 then
							Text:SetText(sformat(_L["%d days ago"], mfloor(delta / 60 / 60 / 24)))
						else
							Text:SetText(_L["3 Years ago"])
						end
					end
				end

				nX = nX + LR_AS_Base.PlayerInfoUI.Width[v2]
				n = n + 1
			end
		end
		Handle_Role:FormatAllItemPos()

		Handle_Role.OnEnter = function ()
			_C.ShowTip(v)
		end
		Handle_Role.OnLeave = function()
			HideTip()
		end
		Handle_Role.OnClick = function()
			if LR_AS_Module["ItemRecord"] then
				LR_AS_ItemRecord_Panel:Open(v.realArea, v.realServer, v.dwID)
			end
		end
		Handle_Role.OnRClick = function()
			local item_button_menu = LR_AS_Panel.RClickMenu(v.realArea, v.realServer, v.dwID)
			PopupMenu(item_button_menu)
		end

		if bCal then
			AllMoney = AllMoney + (PlayerInfo.nMoney or 0)
		end

		Handle_Role:SetAlpha(Alpha or 255)
	end
	return num, AllMoney
end

function _C.GetMoneyTipText(nGold)
	local szUitex = "ui/image/common/money.UITex"
	local r, g, b = 255, 255, 255
	local nGoldBrick, nGold, nSilver, nCopper = LR.MoneyToGoldSilverAndCopper(nGold or 0)
	if nGold >= 0 then
		return GetFormatText(nGoldBrick, 41, r, g, b) .. GetFormatImage(szUitex, 27) .. GetFormatText(nGold, 41, r, g, b) .. GetFormatImage(szUitex, 0) .. GetFormatText(nSilver, 41, r, g, b) .. GetFormatImage(szUitex, 2).. GetFormatText(nCopper, 41, r, g, b) .. GetFormatImage(szUitex, 1)
	else
		nGold = nGold * -1
		return GetFormatText("-" .. math.floor(nGold / 10000), 41, r, g, b) .. GetFormatImage(szUitex, 27) .. GetFormatText(math.floor(nGold % 10000), 41, r, g, b) .. GetFormatImage(szUitex, 0)
	end
end

function _C.ShowTip(v)
	local nMouseX, nMouseY =  Cursor.GetPos()
	local szTipInfo = {}
	local szPath, nFrame = GetForceImage(v.dwForceID)
	local szKey = sformat("%s_%s_%d", v.realArea, v.realServer, v.dwID)
	local PlayerInfo = LR_AS_Data.AllPlayerInfo[szKey] or {}
	local All_Stamina = LR_AS_Data.All_Stamina
	local r, g, b = LR.GetMenPaiColor(v.dwForceID)
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	if v.dwID == me.dwID and v.realArea == realArea and v.realServer == realServer then
		local myself = _C.GetSelfData()
		if LR_AS_Module.RC then
			LR_AS_Module.RC.CheckExam()
		end
		PlayerInfo = clone(myself)
	end

	szTipInfo[#szTipInfo+1] = GetFormatImage(szPath, nFrame, 26, 26)
	szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s(%d)\n", v.szName, v.nLevel), 62, r, g, b)
	szTipInfo[#szTipInfo+1] = GetFormatImage("ui\\image\\ChannelsPanel\\NewChannels.uitex", 166, 365, 27)
	szTipInfo[#szTipInfo+1] = GetFormatText("\n", 224)
	szTipInfo[#szTipInfo+1] = GetFormatText(_L["Login Server:"], 224)
	szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s[%s]\n", v.loginServer or "--", v.loginArea or "--"), 18)
	szTipInfo[#szTipInfo+1] = GetFormatText(_L["Tong:"], 224)
	szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", PlayerInfo.szTongName or "--"), 18)
	szTipInfo[#szTipInfo+1] = GetFormatText(_L["Title:"], 224)
	szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", PlayerInfo.szTitle or "--"), 18)
	if PlayerInfo.nCamp ~=  nil then
		szTipInfo[#szTipInfo+1] = GetFormatText(_L["Camp:"], 224)
		if v.nCamp  ==  0 then
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", g_tStrings.STR_CAMP_TITLE[PlayerInfo.nCamp]), 27)
		elseif v.nCamp  ==  1 then
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", g_tStrings.STR_CAMP_TITLE[PlayerInfo.nCamp]), 206)
		elseif v.nCamp  ==  2 then
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n",g_tStrings.STR_CAMP_TITLE[PlayerInfo.nCamp]), 102)
		else
			szTipInfo[#szTipInfo+1] = GetFormatText("\n")
		end
	end
	--local nGoldBrick, nGold, nSilver, nCopper = LR.MoneyToGoldSilverAndCopper(PlayerInfo.nMoney or 0)
	--szTipInfo[#szTipInfo+1] = GetFormatText(_L["Money:"], 224) ..  GetFormatText(sformat("%d %s %d %s %d %s\n", nGold, _L["Gold"], nSilver, _L["Silver"], nCopper, _L["Copper"]), 41)
	szTipInfo[#szTipInfo+1] = GetFormatText(_L["Money:"], 224) .. _C.GetMoneyTipText(PlayerInfo.nMoney) .. GetFormatText("\n")
	szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s/%s", _L["BangGong:"], _L["remainBangGong:"]), 224) .. GetFormatText(sformat("%d / %d\n", PlayerInfo.BangGong, PlayerInfo.remainBangGong), 41)
	szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s/%s", _L["XiaYi:"], _L["remainXiaYi:"]), 224) ..  GetFormatText(sformat("%d / %d\n", PlayerInfo.XiaYi, PlayerInfo.remainXiaYi), 41)
	szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s/%s", _L["WeiWang:"], _L["remainWeiWang:"]), 224) ..  GetFormatText(sformat("%d / %d\n", PlayerInfo.WeiWang, PlayerInfo.remainWeiWang), 41)
	szTipInfo[#szTipInfo+1] = GetFormatText(_L["ZhanJieJiFen:"], 224) ..  GetFormatText(PlayerInfo.ZhanJieJiFen.."\n", 41)
	szTipInfo[#szTipInfo+1] = GetFormatText(_L["remainZhanJieJiFen:"], 224) ..  GetFormatText(PlayerInfo.remainZhanJieJiFen.."\n", 41)
	szTipInfo[#szTipInfo+1] = GetFormatText(_L["ZhanJieDengJi:"], 224) ..  GetFormatText(PlayerInfo.ZhanJieDengJi.."\n", 41)
	szTipInfo[#szTipInfo+1] = GetFormatText(_L["MingJianBi:"], 224) ..  GetFormatText(PlayerInfo.MingJianBi.."\n", 41)

	szTipInfo[#szTipInfo+1] = GetFormatText(_L["TrainValue:"], 224)
	szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", PlayerInfo.nCurrentTrainValue or "--"), 18)

	szTipInfo[#szTipInfo+1] = GetFormatText(_L["JingLi:"], 224) ..  GetFormatText(PlayerInfo.nVigor.."\n", 41)
	szTipInfo[#szTipInfo+1] = GetFormatText(_L["JingLi remain:"], 224) ..  GetFormatText(PlayerInfo.nVigorRemainSpace.."\n", 41)
	local AccountStamina = 0
	if v.hash01 then
		AccountStamina = All_Stamina[v.hash01][sformat("%s_%s", v.realArea, v.realServer)].nCurrentStamina or 0
	end
	szTipInfo[#szTipInfo+1] = GetFormatText(_L["Account Stamina:"], 224) ..  GetFormatText(AccountStamina, 41)
	if v.hash01 then
		local nCurrentStamina = AccountStamina
		local nMaxStamina = All_Stamina[v.hash01][sformat("%s_%s", v.realArea, v.realServer)].nMaxStamina
		local SaveTime = All_Stamina[v.hash01][sformat("%s_%s", v.realArea, v.realServer)].SaveTime
		if nCurrentStamina + (GetCurrentTime() - SaveTime) / 1000 / 3 * 9 > nMaxStamina then
			szTipInfo[#szTipInfo+1] = GetFormatText(_L["Full\n"], 22)
		else
			szTipInfo[#szTipInfo+1] = GetFormatText("\n", 41)
		end
	else
		szTipInfo[#szTipInfo+1] = GetFormatText("\n", 41)
	end

	szTipInfo[#szTipInfo+1] = GetFormatText(_L["JianBen:"], 224) ..  GetFormatText(PlayerInfo.JianBen.."\n", 41)
	if PlayerInfo.remainJianBen then
		szTipInfo[#szTipInfo+1] = GetFormatText(_L["JianBen this week remain:"], 224)
		szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", PlayerInfo.remainJianBen), 18)
	end

	local examData = LR_AS_Data.ExamData[szKey] or {["ShengShi"] = 0, ["HuiShi"] = 0, }
	if examData["HuiShi"] == 1 or examData["ShengShi"] == 1 then
		if examData["HuiShi"] == 1 then
			szTipInfo[#szTipInfo+1] = GetFormatText(_L["Finished HuiShi exam(6-7)\n"], 224)
		end
		if examData["ShengShi"] == 1 then
			szTipInfo[#szTipInfo+1] = GetFormatText(_L["Finished ShengShi exam(1-7)\n"], 224)
		end
	else
		szTipInfo[#szTipInfo+1] = GetFormatText(_L["Haven't had any exam yet\n"], 224)
	end

	if LR_AS_Group.AllUsrGroup[szKey] and LR_AS_Group.AllUsrGroup[szKey].groupID and LR_AS_Group.AllUsrGroup[szKey].groupID > 0 then
		szTipInfo[#szTipInfo+1] = GetFormatText(_L["Group name:"], 224)
		szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", LR_AS_Group.AllUsrGroup[szKey].szName), 18)
	end

	if IsCtrlKeyDown() then
		szTipInfo[#szTipInfo+1] = GetFormatText(sformat("dwID：%d\n", v.dwID), 71)
	end

	local text = tconcat(szTipInfo)
	OutputTip(text, 360, {nMouseX, nMouseY, 0, 0})
end

--添加底部按钮
function _C.AddPageButton()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end
	local page = frame:Lookup("PageSet_Menu/Page_PlayerInfo")
	LR_AS_Base.AddButton(page, "btn_5", _L["Show Group"], 340, 555, 110, 36, function() LR_AS_Group.PopupUIMenu() end)
	if LR_AS_Module["BookRd"] then
		LR_AS_Base.AddButton(page, "btn_4", _L["Reading Statistics"], 470, 555, 110, 36, function() LR_BookRd_Panel:Open() end)
	end
	if LR_AS_Module["ItemRecord"] then
		LR_AS_Base.AddButton(page, "btn_3", _L["Item Statistics"], 600, 555, 110, 36, function() LR_AS_ItemRecord_Panel:Open() end)
	end
	LR_AS_Base.AddButton(page, "btn_2", _L["Settings"], 730, 555, 110, 36, function() LR_TOOLS:OpenPanel(_L["AccountStatistics"]) end)
	LR_AS_Base.AddButton(page, "btn_1", _L["Save Data"], 860, 555, 110, 36, function() LR_AS_Base.SaveData() end)
end

function _C.RefreshPage()
	_C.ReFreshTitle()
	_C.ListAS()
end

------------------
function _C.FIRST_LOADING_END(DB)
	_C.LoadData(DB)
end

---------------------------------
---压力测试
---------------------------------
local StressTest = {}
StressTest.Num = 50
function StressTest.IniDB(DB)
	local value1 = function(value, default)
		return value and value ~= "" and value or default
	end

	for i = 1, StressTest.Num, 1 do
		local realArea = sformat(_L["Area%d"], i % 3)
		local realServer = sformat(_L["Server%d"], i % 4)
		local dwID = 1000000 + i
		local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)

		local data, v = {}, {}
		data.szKey = szKey
		data.nGold = value1(v.nGold, i)
		data.nSilver = value1(v.nSilver, i)
		data.nCopper = value1(v.nCopper, i)
		data.nMoney = data.nCopper + data.nSilver * 100 + data.nGold * 10000
		data.JianBen, data.remainJianBen = value1(v.JianBen, i), value1(v.remainJianBen, 1500)	--监本
		data.BangGong, data.remainBangGong = value1(v.BangGong, i), value1(v.remainBangGong, 170000)		--帮贡
		data.XiaYi, data.remainXiaYi = value1(v.XiaYi, i), value1(v.remainXiaYi, 9000)	--狭义
		data.WeiWang, data.remainWeiWang = value1(v.WeiWang, i), value1(v.remainWeiWang, 180000)	--威望
		data.ZhanJieJiFen, data.remainZhanJieJiFen = value1(v.ZhanJieJiFen, i), value1(v.remainZhanJieJiFen, 0)	--战阶积分
		data.ZhanJieDengJi = value1(v.ZhanJieDengJi, 0)	--战阶等级
		data.MingJianBi, data.remainMingJianBi = value1(v.MingJianBi, i), value1(v.remainMingJianBi, 0)	--名剑币
		data.szTitle = value1(v.szTitle, "")	--称号
		data.nCurrentTrainValue = value1(v.nCurrentTrainValue, i)	--修为
		data.nCamp = value1(v.nCamp, 0)	--阵营
		data.szTongName = value1(v.szTongName, "")	--帮会名称
		data.SaveTime = GetCurrentTime()
		data.LastLoginTime = value1(v.LastLoginTime, 0)
		data.LastLogoutTime = value1(v.LastLogoutTime, 0)

		--100级新版精力
		data.nVigor = value1(v.nVigor, i)
		data.nMaxVigor = value1(v.nMaxVigor, 1500)
		data.nVigorRemainSpace = value1(v.nVigorRemainSpace, 0)

		_C.SaveData(DB, data)
	end
end

---------------------------------
---注册模块
---------------------------------
LR_AS_Module.PlayerInfo = {}
LR_AS_Module.PlayerInfo.PrepareData = _C.PrepareData
LR_AS_Module.PlayerInfo.SaveData = _C.SaveData
LR_AS_Module.PlayerInfo.LoadData = _C.LoadData
LR_AS_Module.PlayerInfo.ResetDataMonday = _C.ResetDataMonday
LR_AS_Module.PlayerInfo.AddPage = _C.AddPage
LR_AS_Module.PlayerInfo.RefreshPage = _C.RefreshPage
LR_AS_Module.PlayerInfo.FIRST_LOADING_END = _C.FIRST_LOADING_END
LR_AS_Module.PlayerInfo.ShowTip = _C.ShowTip
LR_AS_Module.PlayerInfo.CheckTitleDisable = _C.CheckTitleDisable
LR_AS_Module.PlayerInfo.CfgSave = _C.CfgSave
LR_AS_Module.PlayerInfo.CfgReset = _C.CfgReset
LR_AS_Module.PlayerInfo.RepairDB = _C.RepairDB
-----
LR_AS_Module.PlayerInfo.StressTest = StressTest
