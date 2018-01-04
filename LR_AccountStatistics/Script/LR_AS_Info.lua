local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local DB_name = "maindb.db"
local _L  =  LR.LoadLangPack(AddonPath)
local CustomVersion = "20170111"
---------------------------------------------------------------
LR_AS_Info = LR_AS_Info or {}
LR_AS_Info.SelfInfo = {}	--用于存放自己的基础数据
LR_AS_Info.AllUsrData = {}	--用于存放所有人物的基础数据
LR_AS_Info.AllUsrList = {}	--存放人物列表

function LR_AS_Info.GetUserInfo()
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
	LR_AS_Info.SelfInfo = clone(UserInfo)
	return UserInfo
end

function LR_AS_Info.SaveSelfInfo(DB)
	-------保存自身的属性数据
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	LR_AS_Info.GetUserInfo()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	if LR_AS_Base.UsrData.OthersCanSee then
		local v = LR_AS_Info.SelfInfo
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
--LR_AS_Base.Add2AutoSave({szKey = "SaveSelfInfo", fnAction = LR_AS_Info.SaveSelfInfo, order = 20})

function LR_AS_Info.UpdateSelfInfoInAllData()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	LR_AS_Info.GetUserInfo()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local key = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	LR_AS_Info.AllUsrData[key] = LR_AS_Info.AllUsrData[key] or {}
	for k, v in pairs (LR_AS_Info.SelfInfo) do
		LR_AS_Info.AllUsrData[key][k] = v		--LR_AS_Info.SelfInfo中的数据列<从数据库导出的数据列，顾分项替换
	end
end

function LR_AS_Info.LoadAllUserInformation(DB)
	local GroupChose = LR_AS_Info.GroupChose or {}
	local DB_SELECT
	if next(GroupChose) ~= nil and not LR_AS_Info.showDataNotInGroup then
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
	LR_AS_Info.AllUsrData = clone(AllUsrData)
	--加入自己的数据
	LR_AS_Info.UpdateSelfInfoInAllData()
end
--LR_AS_Base.Add2FirstLoadingEndList({szKey = "LoadAllUserInformation", fnAction = LR_AS_Info.LoadAllUserInformation, order = 30})

function LR_AS_Info.LoadUserList(DB)
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
	UserList[key1] = {szKey = key2, dwID = me.dwID, szName = me.szName, dwForceID = me.dwForceID, loginArea = loginArea, loginServer = loginServer, OthersCanSee = LR_AS_Base.UsrData.OthersCanSee, realArea = realArea, realServer = realServer, }
	LR_AS_Info.AllUsrList = clone(UserList)
end
-----------------------------------------
--界面显示数据
-----------------------------------------
LR_AS_Info.Container = nil	---显示人物基本数据的容器

---刷新标题
function LR_AS_Info.ReFreshTitle()
	local frame = Station.Lookup("Normal/LR_AccountStatistics")
	if not frame then
		return
	end
	local page = frame:Lookup("PageSet_Menu/Page_LR_AS_Record")
	local key_list = {"nLevel", "nMoney", "JianBen", "BangGong", "XiaYi", "WeiWang", "ZhanJieJiFen", "ZhanJieDengJi", "MingJianBi"}
	local title_list = {_L["Name"], _L["Money"], _L["Examprint"], _L["JiangGong"], _L["XiaYi"], _L["WeiWang"], _L["ZhanJieJiFen"], _L["ZhanJieLevel"], _L["MingJian"]}
	for k , v in ipairs(key_list) do
		if v then
			local txt = page:Lookup("", sformat("Text_Record_Break%d", k))
			txt:SetText(title_list[k])
			txt:RegisterEvent(786)
			txt:SetFontScheme(44)
			if LR_AS_Base.UsrData.nkey  ==  v then
				if LR_AS_Base.UsrData.nsort  ==  "asc" then
					txt:SetText(title_list[k] .. "↑")
					txt:SetFontScheme(99)
				elseif LR_AS_Base.UsrData.nsort  ==  "desc" then
					txt:SetText(title_list[k] .. "↓")
					txt:SetFontScheme(99)
				end
			end

			txt.OnItemLButtonClick = function()
				if LR_AS_Base.UsrData.nkey  ==  v then
					if LR_AS_Base.UsrData.nsort  ==  "asc" then
						LR_AS_Base.UsrData.nsort = "desc"
					else
						LR_AS_Base.UsrData.nsort = "asc"
					end
				end
				LR_AS_Base.UsrData.nkey = v
				LR_AS_Info.ReFreshTitle()
				LR_AS_Info.ListAS()
				LR_AccountStatistics_FBList.ListFB()
				LR_AccountStatistics_RiChang.ListRC()
				LR_ACS_QiYu.ListQY()
			end
			txt.OnItemMouseEnter = function()
				this:SetFontColor(255, 128, 0)
			end
			txt.OnItemMouseLeave = function()
				if LR_AS_Base.UsrData.nkey  ==  v then
					txt:SetFontScheme(99)
				else
					this:SetFontColor(255, 255, 255)
				end
			end
		end
	end
end

--刷新列表
function LR_AS_Info.ListAS()
	local frame = Station.Lookup("Normal/LR_AccountStatistics")
	if not frame then
		return
	end
	LR_AS_Info.Container = frame:Lookup("PageSet_Menu/Page_LR_AS_Record/WndScroll_LR_AS_Record/WndContainer_Record_List")
	LR_AS_Info.Container:Clear()
	local TempTable_Cal, TempTable_NotCal = LR_AS_Base.SeparateUsrList()
	local AllMoney = 0
	local num = 0
	num, AllMoney = LR_AS_Info.ShowItem (TempTable_Cal, 255, true, 0, 0)
	num, AllMoney = LR_AS_Info.ShowItem (TempTable_NotCal, 60, false, num, AllMoney)
	LR_AS_Info.Container:FormatAllContentPos()
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

function LR_AS_Info.ShowItem (t_Table, Alpha, bCal, _num, _money)
	local num = _num
	local AllMoney = _money
	local TempTable = clone(t_Table)
	for i = 1, #TempTable, 1 do
		num = num+1
		local wnd = LR_AS_Info.Container:AppendContentFromIni("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics_item.ini", "WndWindow", num)
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
				local NotCalList = LR_AS_Base.UsrData.NotCalList or {}
				if NotCalList[key] then
					NotCalList[key] = nil
				else
					NotCalList[key] = true
				end
				LR_AS_Info.ListAS()
				LR_AccountStatistics_FBList.ListFB()
				LR_AccountStatistics_RiChang.ListRC()
				LR_ACS_QiYu.ListQY()
			end,
			bChecked = function ()
				local NotCalList = LR_AS_Base.UsrData.NotCalList or {}
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
		for groupID, groupV in pairs(LR_AS_Group.GroupList) do
			local szGroupName = groupV.szName
			tinsert (item_button_menu2, {
				szOption = szGroupName,
				bCheck = true, bMCheck = true, bChecked = function() return LR_AS_Group.ifGroupHasUser(key, groupID) end,
				fnAction = function(UserData)
					local path = sformat("%s\\%s", SaveDataPath, DB_name)
					local DB = SQLite3_Open(path)
					DB:Execute("BEGIN TRANSACTION")
					LR_AS_Group.ChangeUserGroup(key, groupID, DB)
					LR_AS_Group.UpdateMyGroupInfo(DB)
					LR_AS_Info.ListAS()
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
				LR_AS_Group.ChangeUserGroup(key, 0, DB)
				LR_AS_Group.UpdateMyGroupInfo(DB)
				LR_AS_Info.ListAS()
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
						LR_AS_Group.AddGroup(szText, DB)
						LR_AS_Info.ListAS()
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
				local sure_delete = function()
					local key = {dwID = TempTable[i].dwID, loginArea = TempTable[i].loginArea, loginServer = TempTable[i].loginServer, szName = TempTable[i].szName, realArea = TempTable[i].realArea, realServer = TempTable[i].realServer}
					if next(key)~= nil then
						local path = sformat("%s\\%s", SaveDataPath, DB_name)
						local DB = SQLite3_Open(path)
						DB:Execute("BEGIN TRANSACTION")
						LR_AS_Base.DelOneData(key, DB)
						LR_AS_Group.LoadAllUserGroup(DB)
						LR_AS_Info.LoadUserList(DB)
						LR_AS_Info.LoadAllUserInformation(DB)
						DB:Execute("END TRANSACTION")
						DB:Release()

						LR_AS_Info.ListAS()
						LR_AccountStatistics_FBList.ListFB()
						LR_AccountStatistics_RiChang.ListRC()
						LR_ACS_QiYu.ListQY()
					else
						return
					end
				end

				local msg = {
					szMessage = sformat("%s %s?", _L["Sure to delete"], TempTable[i].szName),
					szName = "delete",
					fnAutoClose = function() return false end,
					{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() sure_delete() end, },
					{szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function()  end, },
				}
				MessageBox(msg)
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
				local GroupList = LR_AS_Group.GroupList

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
				if LR_AS_Group.AllUsrGroup[key] and LR_AS_Group.AllUsrGroup[key].groupID > 0 then
					local groupID = LR_AS_Group.AllUsrGroup[key].groupID
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

			if LR_AS_Group.AllUsrGroup[key] and LR_AS_Group.AllUsrGroup[key].groupID and LR_AS_Group.AllUsrGroup[key].groupID > 0 then
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["Group name:"], 224)
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", LR_AS_Group.AllUsrGroup[key].szName), 18)
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

--添加底部按钮
function LR_AS_Info.AddPageButton()
	local frame = Station.Lookup("Normal/LR_AccountStatistics")
	if not frame then
		return
	end
	local page = frame:Lookup("PageSet_Menu/Page_LR_AS_Record")
	LR_AS_Base.AddButton(page, "btn_5", _L["Show Group"], 340, 555, 110, 36, function() LR_AS_Group.ShowGroup() end)
	LR_AS_Base.AddButton(page, "btn_4", _L["Reading Statistics"], 470, 555, 110, 36, function() LR_BookRd_Panel:Open() end)
	LR_AS_Base.AddButton(page, "btn_3", _L["Item Statistics"], 600, 555, 110, 36, function() LR_AccountStatistics_Bag_Panel:Open() end)
	LR_AS_Base.AddButton(page, "btn_2", _L["Settings"], 730, 555, 110, 36, function() LR_AccountStatistics.SetOption() end)
	LR_AS_Base.AddButton(page, "btn_1", _L["Save Data"], 860, 555, 110, 36, function() LR_AS_Base.AutoSave() end)
end
