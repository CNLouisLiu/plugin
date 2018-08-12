local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local LanguagePath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local db_name = "maindb.db"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20180408"
-------------------------------------------------------------
local Module_List = {
	"PlayerList", "PlayerInfo", "Group", "ItemRecord", "EquipmentRecord", "BookRd", "AchievementRecord", "FBList", "RC", "QY",
}

LR_AS_Module = {
	--["PlayerList"] = {FIRST_LOADING_END = XX, SaveData = XX},
}

LR_AS_Base = LR_AS_Base or {}
LR_AS_Base.default = {
	UsrData = {
		bRecord = false,
		bAutoSave = true,
		bExitSave = true,
		bEscSave = true,
		bOpenFrameSave = true,
		bCloseFrameSave = true,
		nKey = "nLevel",
		nSort = "desc",
		FloatPanel = false,
		NotCalList = {},
		bAutoBackup = false,
		nAutoBackupType = 1,		--1：每周第一次上线，2：每天第一次上线
		nUpdateDel = 0,
	},
}
LR_AS_Base.UsrData = clone(LR_AS_Base.default.UsrData)
RegisterCustomData("LR_AS_Base.UsrData", VERSION)

LR_AS_Data = {}
LR_AS_Data.AllPlayerList = {}
LR_AS_Data.AllUsrFilteredList = {}
LR_AS_Data.AllUsrSortedList = {}
LR_AS_Data.AllPlayerInfo = {}
LR_AS_Data.AllGroupList = {}
LR_AS_Data.AllUsrGroup = {}
LR_AS_Data.ExamData = {}

---------------------------------
---LoadData
---------------------------------
function LR_AS_Base.LoadData()
	Log("[LR] AS load begin\n")
	local _begin_time = GetTickCount()
	local path = sformat("%s\\%s", SaveDataPath, db_name)
	local DB = LR.OpenDB(path, "AS_BASE_LOAD_DATA_05DC638DAB8A11477BDFF035C167AFC9")
	for k, v in pairs(Module_List) do
		if LR_AS_Module[v] and LR_AS_Module[v].LoadData then
			--Log(sformat("%s\n", v))
			LR_AS_Module[v].LoadData(DB)
		end
	end
	LR.CloseDB(DB)
	Log(sformat("[LR] AS load cost %0.3f s", (GetTickCount() - _begin_time) * 1.0 / 1000))
end

---------------------------------
---AutoSave
---------------------------------
function LR_AS_Base.SaveData()
	local me = GetClientPlayer()
	if not me or IsRemotePlayer(me.dwID) then
		return
	end
	--------------save
	local _begin_time = GetTickCount()
	local path = sformat("%s\\%s", SaveDataPath, db_name)
	local DB = LR.OpenDB(path, "AS_BASE_SAVE_DATA_0D9F801993115A3C7F3EA6267F0AAA9C")
	for k, v in pairs(Module_List) do
		if LR_AS_Module[v] and LR_AS_Module[v].SaveData then
			--Log(sformat("%s\n", v))
			LR_AS_Module[v].SaveData(DB)
		end
	end
	LR.CloseDB(DB)
	Log(sformat("[LR] AS save cost %0.3f s", (GetTickCount() - _begin_time) * 1.0 / 1000))
end

function LR_AS_Base.AutoSave()
	--check
	if not LR_AS_Base.UsrData.bAutoSave then
		return
	end
	LR_AS_Base.SaveData()
end

---------------------------------
---ResetData（周一/周五重置数据）
---------------------------------
function LR_AS_Base.ResetDataEveryDay(DB)
	for k, v in pairs(Module_List) do
		if LR_AS_Module[v] and LR_AS_Module[v].ResetDataEveryDay then
			LR_AS_Module[v].ResetDataEveryDay(DB)
		end
	end
end

function LR_AS_Base.ResetDataMonday(DB)
	for k, v in pairs(Module_List) do
		if LR_AS_Module[v] and LR_AS_Module[v].ResetDataMonday then
			LR_AS_Module[v].ResetDataMonday(DB)
		end
	end
end

function LR_AS_Base.ResetDataFriday(DB)
	for k, v in pairs(Module_List) do
		if LR_AS_Module[v] and LR_AS_Module[v].ResetDataFriday then
			LR_AS_Module[v].ResetDataFriday(DB)
		end
	end
end

function LR_AS_Base.ResetData()
	local CurrentTime =  GetCurrentTime()
	local _date = TimeToDate(CurrentTime)
	local weekday = _date["weekday"]
	local hour = _date["hour"]
	local minute = _date["minute"]
	local second = _date["second"]
	-----------星期一大刷新（周常、日常数据）
	if weekday ==  0 then
		weekday = 7
	end
	if weekday ==  1 and hour < 7 then
		return
	end
	local day = weekday - 1
	if day < 0 then
		day = 0
	end
	---周一刷新时间
	local RefreshTimeMonday = CurrentTime - day * 86400 - hour * 60 * 60 - minute* 60 - second + 7 * 60 *60
	------------------每日重置日常任务时间
	local RefreshTimeEveryDay
	if hour < 7 then
		RefreshTimeEveryDay = CurrentTime -  (hour+24) * 60 * 60 - minute* 60 - second + 7 * 60 *60
	else
		RefreshTimeEveryDay = CurrentTime -  hour * 60 * 60 - minute* 60 - second + 7 * 60 *60
	end
	---周五刷新时间
	local RefreshTimeFriday = RefreshTimeMonday
	if (weekday > 5) or (weekday ==  5 and hour>= 7 ) then
		day = weekday - 5
		if day<0 then
			day = 0
		end
		RefreshTimeFriday = CurrentTime - day * 86400 - hour * 60 * 60 - minute* 60 - second + 7 * 60 *60
	end
	--------
	local path = sformat("%s\\%s", SaveDataPath, db_name)
	local DB = LR.OpenDB(path, "AS_BASE_RESET_DATA_D7F73ADF2CB70A9AACFB048D8F7C6833")
	------载入时间
	local RC_ResetTime = {
		ClearTimeEveryDay = 0,
		ClearTimeMonday = 0,
		ClearTimeFriday = 0,
	}
	local DB_SELECT = DB:Prepare("SELECT * FROM richang_clear_time WHERE szName IS NOT NULL")
	local Data = DB_SELECT:GetAll()
	for k, v in pairs(Data) do
		if RC_ResetTime[v.szName] then
			RC_ResetTime[v.szName] = v.nTime or 0
		end
	end

	if RefreshTimeMonday > RC_ResetTime.ClearTimeMonday or RefreshTimeFriday > RC_ResetTime.ClearTimeFriday or RefreshTimeEveryDay > RC_ResetTime.ClearTimeEveryDay then
		if RefreshTimeMonday > RC_ResetTime.ClearTimeMonday then
			LR_AS_Base.ResetDataMonday(DB)
			LR_AS_Base.ResetDataFriday(DB)
			LR_AS_Base.ResetDataEveryDay(DB)
			----
			RC_ResetTime.ClearTimeMonday = CurrentTime
			RC_ResetTime.ClearTimeFriday = CurrentTime
			RC_ResetTime.ClearTimeEveryDay = CurrentTime
			----每周优化数据库
			LR.DelayCall(1000, function()
				LR_AS_DB.MainDBVacuum(true)
				if LR_AS_Base.UsrData.bAutoBackup and LR_AS_Base.UsrData.nAutoBackupType == 1 then
					LR.SysMsg(_L["[LR]Auto backup data\n"])
					LR_AS_DB.backup()
				end
			end)
		elseif RefreshTimeFriday > RC_ResetTime.ClearTimeFriday then
			LR_AS_Base.ResetDataFriday(DB)
			LR_AS_Base.ResetDataEveryDay(DB)

			--
			RC_ResetTime.ClearTimeFriday = CurrentTime
			RC_ResetTime.ClearTimeEveryDay = CurrentTime
		elseif RefreshTimeEveryDay > RC_ResetTime.ClearTimeEveryDay then
			LR_AS_Base.ResetDataEveryDay(DB)
			--
			RC_ResetTime.ClearTimeEveryDay = CurrentTime
			LR.DelayCall(1000, function()
				if LR_AS_Base.UsrData.bAutoBackup and LR_AS_Base.UsrData.nAutoBackupType == 2 then
					LR.SysMsg(_L["[LR]Auto backup data\n"])
					LR_AS_DB.backup()
				end
			end)
		end
		--记录保存时间
		local szName = {"ClearTimeEveryDay", "ClearTimeMonday", "ClearTimeFriday"}
		local DB_REPLACE2 = DB:Prepare("REPLACE INTO richang_clear_time (szName, nTime) VALUES ( ?, ? )")
		for k, v in pairs (szName) do
			DB_REPLACE2:ClearBindings()
			DB_REPLACE2:BindAll(v, RC_ResetTime[v])
			DB_REPLACE2:Execute()
		end
	end

	LR.CloseDB(DB)
end

---------------------------------
---FirstLoadingEnd	--主要用于需要数据库的操作
---------------------------------
function LR_AS_Base.FIRST_LOADING_END()
	local _begin_time = GetTickCount()
	local path = sformat("%s\\%s", SaveDataPath, db_name)
	local DB = LR.OpenDB(path, "AS_BASE_FIRST_LOADING_END_AA481F7DB2E1EC1CBD53005AF1A11D3F")
	for k, v in pairs(Module_List) do
		if LR_AS_Module[v] and LR_AS_Module[v].FIRST_LOADING_END then
			LR_AS_Module[v].FIRST_LOADING_END(DB)
		end
	end
	LR.CloseDB(DB)
	Log(sformat("[LR] AS FIRST_LOADING_END load data cost %0.3f s", (GetTickCount() - _begin_time) * 1.0 / 1000))
	--FireEvent("LR_ACS_REFRESH_FP")

	if not LR_AS_Base.UsrData.bRecord and LR_AS_Base.UsrData.nUpdateDel ~= VERSION then
		local me = GetClientPlayer()
		local ServerInfo = {GetUserServer()}
		local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
		local player = {dwID = me.dwID, realArea = realArea, realServer = realServer}
		LR_AS_Base.DelPlayer(player)
		LR_AS_Base.UsrData.nUpdateDel = VERSION
	end

	LR_AS_Base.ResetData()
	LR.DelayCall(6000, function() LR_AS_Base.AutoSave() end)
end

LR.RegisterEvent("FIRST_LOADING_END", function() LR_AS_Base.FIRST_LOADING_END() end)

---------------------------------
---用于在部分界面打开时的操作
---------------------------------
local _auto_save_lasttime	= 0	--打开OptionPanel的操作时间记录，至少10s检查邮件
local _auto_save_lasttime2 = 0	--至少间隔3分钟保存一次记录

function LR_AS_Base.ON_FRAME_CREATE()
	local frame = arg0
	local szName = frame:GetName()
	if szName  ==  "ExitPanel" then
		if LR_AS_Base.UsrData.bAutoSave and  LR_AS_Base.UsrData.bExitSave then
			frame:Lookup("Btn_Sure"):Enable(false)
			LR.DelayCall(1000, function()
				local frame = Station.Lookup("Topmost2/ExitPanel")
				if frame then
					frame:Lookup("Btn_Sure"):Enable(true)
				end
			end)
			Log("[LR_AccountStatistics]:Exit save")
			LR_AS_Base.AutoSave()
			if LR_AS_Trade then
				LR_AS_Trade.SaveTempData(true)
				LR_AS_Trade.MoveData2MainTable()
			end
			frame:Lookup("Btn_Sure"):Enable(true)
		end

	elseif szName  ==  "OptionPanel" then
		if LR_AS_Base.UsrData.bAutoSave and  LR_AS_Base.UsrData.bEscSave then
			local _now = GetTickCount()
			if _now - _auto_save_lasttime2 > 3 * 60 * 1000 then
				_auto_save_lasttime2 = _now
				Log("[LR_AccountStatistics]:Esc save")
				LR_AS_Base.AutoSave()
			end
		end
		FireEvent("LR_ACS_REFRESH_FP")
	end
end
LR.RegisterEvent("ON_FRAME_CREATE", function() LR_AS_Base.ON_FRAME_CREATE()  end)
---------------------------------
---在界面上添加按钮
---------------------------------
function LR_AS_Base.AddButton(parent, szName, szText, x, y, w, h, fnAction, fnEnter, fnLeave)
	local Button = LR.AppendUI("Button", parent, szName, {text = szText, x = x, y = y, w = w, h = h})
	Button.OnEnter = fnEnter
	Button.OnLeave = fnLeave
	Button.OnClick = fnAction

	return Button
end

---------------------------------
---删除数据
---------------------------------
function LR_AS_Base.DelPlayer(player)
	local realArea = player.realArea
	local realServer = player.realServer
	local dwID = player.dwID
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)

	local path = sformat("%s\\%s", SaveDataPath, db_name)
	local DB = LR.OpenDB(path, "DEL_PLAYER_264015779F0459A1088BA2AEAF2F1E51")

	------删除用户列表数据
	LR_AS_Data.AllPlayerList[szKey] = nil
	DB:Execute(sformat("DELETE FROM player_list WHERE szKey = '%s'", g2d(szKey)))

	----删除人物所在分组
	DB:Execute(sformat("DELETE FROM player_group WHERE szKey = '%s'", g2d(szKey)))

	-----删除角色信息数据
	DB:Execute(sformat("DELETE FROM player_info WHERE szKey = '%s' ", g2d(szKey)))

	-----删除背包数据
	DB:Execute(sformat("DELETE FROM bag_item_data WHERE belong = '%s'", g2d(szKey)))

	-----删除仓库数据
	DB:Execute(sformat("DELETE FROM bank_item_data WHERE belong = '%s'", g2d(szKey)))

	----删除邮件数据
	if true then
		local me = GetClientPlayer()
		local ServerInfo = {GetUserServer()}
		local loginArea2, loginServer2, realArea2, realServer2 = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
		local szKey2 = sformat("%s_%s_%d", realArea2, realServer2, me.dwID)
		if szKey2 ~= szKey then
			DB:Execute(sformat("DELETE FROM mail_data WHERE belong = '%s'", g2d(szKey)))
			DB:Execute(sformat("DELETE FROM mail_item_data WHERE belong = '%s'", g2d(szKey)))
			DB:Execute(sformat("DELETE FROM mail_receive_time WHERE szKey = '%s'", g2d(szKey)))
		end
	end

	-----删除成就数据
	DB:Execute(sformat("DELETE FROM achievement_data WHERE szKey = '%s'", g2d(szKey)))

	----删除阅读信息
	DB:Execute(sformat("DELETE FROM bookrd_data WHERE szKey = '%s'", g2d(szKey)))

	----删除装备信息
	DB:Execute(sformat("DELETE FROM equipment_data WHERE szKey = '%s'", g2d(szKey)))

	----删除考试数据
	DB:Execute(sformat("DELETE FROM exam_data WHERE szKey = '%s'", g2d(szKey)))

	----删除副本数据
	DB:Execute(sformat("DELETE FROM fb_data WHERE szKey = '%s'", g2d(szKey)))

	----删除角色奇遇数据
	DB:Execute(sformat("DELETE FROM qiyu_data WHERE szKey = '%s'", g2d(szKey)))

	----删除日常数据
	DB:Execute(sformat("DELETE FROM richang_data WHERE szKey = '%s'", g2d(szKey)))


	--重建用户列表
	LR_AS_Module.PlayerList.LoadData(DB)

	LR.CloseDB(DB)
end

---------------------------------
---拆分 显示和不显示的 人物列表
---------------------------------
function LR_AS_Base.PutOutUsrList()
	local temp = {}
	for k, v in pairs(LR_AS_Data.AllPlayerList) do
		temp[#temp + 1] = clone(v)
	end

	tsort(temp,function(a, b)
		if a.nLevel == b.nLevel then
			if a.dwForceID == b.dwForceID then
				if a.realArea == b.realArea then
					if a.realServer == b.realServer then
						return a.szName < b.szName
					else
						return a.realServer < b.realServer
					end
				else
					return a.realArea < b.realArea
				end
			else
				return a.dwForceID < b.dwForceID
			end
		else
			return a.nLevel > b.nLevel
		end
	end)

	return temp
end

function LR_AS_Base.SeparateUsrList()
	local nKey = LR_AS_Base.UsrData.nKey or "nLevel"
	local nSort = LR_AS_Base.UsrData.nSort or "desc"

	if not LR_AS_Module["PlayerInfo"] then
		LR_AS_Base.UsrData.nKey = "nLevel"
		nKey = "nLevel"
	end

	local AllPlayerList = LR_AS_Data.AllPlayerList
	local TempTable = {}
	for k, v in pairs (AllPlayerList) do
		TempTable[#TempTable+1] = clone(v)
		if nKey ~= "nLevel" then
			TempTable[#TempTable][nKey] = LR_AS_Data.AllPlayerInfo[v.szKey][nKey]
		end
	end

	tsort(TempTable,function(a, b)
		if nSort == "desc" then
			if a[nKey] == b[nKey] then
				if a.nLevel == b.nLevel then
					if a.dwForceID == b.dwForceID then
						if a.szName == b.szName then
							return a.dwID < b.dwID
						else
							return a.szName < b.szName
						end
					else
						return a.dwForceID < b.dwForceID
					end
				else
					return a.nLevel > b.nLevel
				end
			else
				return a[nKey] > b[nKey]
			end
		else
			if a[nKey] == b[nKey] then
				if a.nLevel == b.nLevel then
					if a.dwForceID == b.dwForceID then
						if a.szName == b.szName then
							return a.dwID > b.dwID
						else
							return a.szName > b.szName
						end
					else
						return a.dwForceID > b.dwForceID
					end
				else
					return a.nLevel < b.nLevel
				end
			else
				return a[nKey] < b[nKey]
			end
		end
	end)


--[[	tsort(TempTable, function(a, b)
		if a[nKey] and b[nKey] then
			if nSort  ==  "asc" then
				if a[nKey]  ==  b[nKey] then
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
					return a[nKey] < b[nKey]
				end
			else
				if a[nKey]  ==  b[nKey] then
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
					return a[nKey] > b[nKey]
				end
			end
		else
			return true
		end
	end)]]

	local TempTable_NotCal = {}
	local TempTable_Cal = {}

	for i = 1, #TempTable, 1 do
		local realArea = TempTable[i].realArea
		local realServer = TempTable[i].realServer
		local dwID = TempTable[i].dwID
		local szName = TempTable[i].szName
		local key = sformat("%s_%s_%d", realArea, realServer, dwID)

		local NotCalList = LR_AS_Base.UsrData.NotCalList or {}
		local bCal = true
		if NotCalList[key] then
			bCal = false
		end

		local GroupChose = LR_AS_Group.GroupChose
		local isExist = true
		if next(GroupChose) ~= nil then
			isExist = false
			for k, v in pairs(GroupChose) do
				if LR_AS_Group.ifGroupHasUser(key, v) then
					isExist = true
				end
			end
		end

		if LR_AS_Group.ShowDataNotInGroup then
			if bCal and isExist then
				tinsert(TempTable_Cal, TempTable[i])
			else
				tinsert(TempTable_NotCal, TempTable[i])
			end
		else
			if isExist then
				if bCal then
					tinsert(TempTable_Cal, TempTable[i])
				else
					tinsert(TempTable_NotCal, TempTable[i])
				end
			end
		end
	end

	return TempTable_Cal, TempTable_NotCal
end

function LR_AS_Base.PopupPlayerMenu(hComboBox, fnAction, all_option)
	local TempTable_Cal, TempTable_NotCal = LR_AS_Base.PutOutUsrList(), {}
	local TempTable = {}
	for i = 1, #TempTable_Cal, 1 do
		TempTable[#TempTable+1] = TempTable_Cal[i]
	end
	for i = 1, #TempTable_NotCal, 1 do
		TempTable[#TempTable+1] = TempTable_NotCal[i]
	end

	local page_num = mceil(#TempTable / 20)
	local page = {}
	for i = 0, page_num - 1, 1 do
		page[i] = {}
		for k = 1, 20, 1 do
			if TempTable[i * 20 + k] ~= nil then
				local szPath, nFrame = GetForceImage(TempTable[i * 20 + k].dwForceID)
				local r, g, b = LR.GetMenPaiColor(TempTable[i * 20 + k].dwForceID)
				page[i][#page[i]+1] = {
					bRichText = false, bCheck = false, bChecked = false,
					szOption = sformat("(%d)%s", TempTable[i * 20 + k].nLevel, TempTable[i * 20 + k].szName),
					fnAction = function ()
						fnAction(TempTable[i * 20 + k])
					end,
					fnMouseEnter = function()
						local szPath, nFrame = GetForceImage(TempTable[i * 20 + k].dwForceID)
						local r, g, b = LR.GetMenPaiColor(TempTable[i * 20 + k].dwForceID)
						local x, y = this:GetAbsPos()
						local szXml = {}
						szXml[#szXml + 1] = GetFormatImage(szPath, nFrame, 30, 30)
						szXml[#szXml + 1] = GetFormatText(sformat("%s(%d)\n", TempTable[i * 20 + k].szName, TempTable[i * 20 + k].nLevel), nil, r, g, b)
						szXml[#szXml + 1] = GetFormatText(sformat("%s@%s", TempTable[i * 20 + k].realArea, TempTable[i * 20 + k].realServer))
						OutputTip(tconcat(szXml), 300, {x, y, 0, 0})
					end,
					szIcon = szPath,
					nFrame = nFrame,
					szLayer = "ICON_RIGHT",
					rgb = {r, g, b},
				}
			end
		end
	end
	for i = 0, page_num - 1, 1 do
		if i ~= page_num - 1 then
			page[i][#page[i] + 1] = {bDevide = true}
			page[i][#page[i] + 1] = page[i+1]
			page[i][#page[i]].szOption = _L["Next 20 Records"]
		end
		if all_option then
			page[i][#page[i] + 1] = all_option
		end
	end

	local m = page[0]
	local __x, __y = hComboBox:GetAbsPos()
	local __w, __h = hComboBox:GetSize()
	m.nMiniWidth = __w
	m.x = __x
	m.y = __y + __h
	PopupMenu(m)
end

---------------------------------
---打开设置界面
---------------------------------
function LR_AS_Base.SetOption()
	LR_TOOLS:OpenPanel(_L["LR_AS_Global_Settings"])
	local frame = Station.Lookup("Normal/LR_TOOLS")
	if frame then
		frame:BringToTop()
	end
end
