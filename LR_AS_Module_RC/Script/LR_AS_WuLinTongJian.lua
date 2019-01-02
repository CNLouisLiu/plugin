local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AS_Module_RC"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local _L = LR.LoadLangPack(AddonPath)
local db_name = "maindb.db"
local VERSION = "20181225"
-------------------------------------------------------------
---武林通鉴任务id 2018.12.25更新
local WLTJ_ID = {
	t5R = {19199, 19243, 19244, 19245, 19246, 19247, 19248, 19250, 19251, 19252, 19253, 19254, 19255, 19256, 19257, 19258, 19259, 19260, 19261, 19262, 19263, 19264, 19265, 19266, 19267, 19268, 19269, 19270, 19271, 19272, 19273, 19274, 19616, 19617, 19618, 19619, 19620, 19621, 19622, 19623},
	t10R = {19219, 19220, 19276, 19277, 19278, 19279, 19280, 19281, 19282, 19283, 19284, 19285, 19286, 19287, 19288, 19289, 19290, 19291, 19292, 19293, 19294, 19295, 19296, 19297, 19298, 19299, 19300, 19661, 19662},
	tCommon = {19376, 19424, 19425, 19426, 19427, 19428, 19429, 19430, 19431, 19432, 19433, 19434, 19435, 19436},
}
--3个5人周常都完成，但是没交，其他5人周常显示不可接

local ID_CAN_DO = {}	--用于存放当前做任务
local SELF_DATA = {}
local ALL_USER_DATA = {}

local _C = {}
function _C.GetIDCanDo(SkipLoad)
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not SkipLoad then
		local path = sformat("%s\\WLTJ_ID.dat", SaveDataPath)
		local data = LoadLUAData(path) or {}
		if next(data) ~= nil then
			ID_CAN_DO = clone(data)
			return
		end
	end
	if me.nLevel < 100 then
		return
	end
	local _, _dwID = me.GetTarget()
	local ids = {}
	local key = {"tCommon", "t5R", "t10R",}
	for k, v in pairs(key) do
		for k2, dwQuestID in pairs(WLTJ_ID[v]) do
			local eCanAccept = me.CanAcceptQuest(dwQuestID, 14211)
			local tQuestStringInfo = LR.Table_GetQuestStringInfo(dwQuestID)
			if eCanAccept == 1 or eCanAccept == 7 or eCanAccept == 57 then	--1:可接任务	7：已经接受了任务	57：完成已达上限	2：不可接
				ids[v] = ids[v] or {}
				tinsert(ids[v], dwQuestID)
			end
		end
	end
	if SkipLoad then
		return ids
	else
		ID_CAN_DO = clone(ids)
	end
end

function _C.ClearWLTJdatMonday(DB)
	local path = sformat("%s\\WLTJ_ID.dat", SaveDataPath)
	local ids, ids_save = _C.GetIDCanDo(true), {}
	local group = {"t5R", "t10R", "tCommon",}
	local limit_num = {3, 3, 2}
	for k, GroupName in pairs(group) do
		ids[GroupName] = ids[GroupName] or {}
		for k2 = 1, limit_num[k] do
			if ids[GroupName][k2] then
				ids_save[GroupName] = ids_save[GroupName] or {}
				tinsert(ids_save[GroupName], ids[GroupName][k2])
			end
		end
	end
	SaveLUAData(path, ids_save)

	--数据库清空
	local DB_DELETE = DB:Prepare("DELETE FROM wltj_data")
	DB_DELETE:Execute()
end

function _C.LockWLTJdat()
	local data = clone(ID_CAN_DO)
	local path = sformat("%s\\WLTJ_ID.dat", SaveDataPath)
	SaveLUAData(path, data)

end

function _C.RefreshWLTJdat()
	_C.GetIDCanDo(true)
	--刷新UI

end

--任务记录
function _C.GetData()
	local me = GetClientPlayer()
	local CurrentTime =  GetCurrentTime()
	local _date = TimeToDate(CurrentTime)
	if me.nLevel < 100 then
		return
	end
	local IDs = clone(WLTJ_ID)
	local key = {"t5R", "t10R", "tCommon",}
	local data = {}
	for k, v in pairs(key) do
		data[v] = data[v] or {}
		for k2, dwQuestID in pairs(IDs[v]) do
			local eCanAccept = me.CanAcceptQuest(dwQuestID, 14211)
			if eCanAccept == 57 then
				data[v][tostring(dwQuestID)] = {eCanAccept = eCanAccept}
			elseif eCanAccept == 1 then
				data[v][tostring(dwQuestID)] = nil	--不用记录
			elseif eCanAccept == 7 then
				data[v][tostring(dwQuestID)] = {}
				data[v][tostring(dwQuestID)].eCanAccept = eCanAccept
				----3: 表示已完成任务0: 表示任务不存在1: 表示任务正在进行中，2: 表示任务已完成但还没有交-1: 表示任务id非法
				local nQuestPhase = me.GetQuestPhase(dwQuestID)
				data[v][tostring(dwQuestID)].nQuestPhase = nQuestPhase
				if nQuestPhase ==  1 then
					local tTraceInfo = me.GetQuestTraceInfo(dwQuestID)
					data[v][tostring(dwQuestID)].kill_npc = clone(tTraceInfo.kill_npc or {})
					data[v][tostring(dwQuestID)].quest_state = clone(tTraceInfo.quest_state or {})
					data[v][tostring(dwQuestID)].need_item = clone(tTraceInfo.need_item or {})
				end
			end
		end
	end
	SELF_DATA = clone(data)
end

function _C.LockIDList()
	local path = sformat("%s\\WLTJ_ID.dat", SaveDataPath)
	local data = clone(ID_CAN_DO) or {}
	SaveLUAData(path, data)

	LR.SysMsg(_L["Lock!\n"])
end



function _C.SaveData(DB)
	if not LR_AS_Base.UsrData.bRecord then
		return
	end
	local me = GetClientPlayer()
	if not me or IsRemotePlayer(me.dwID) then
		return
	end
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)

	Log("[LR] WLTJ savedata begin\n")
	_C.GetData()

	local tCommon = SELF_DATA.tCommon
	local t5R = SELF_DATA.t5R
	local t10R = SELF_DATA.t10R
	local DB_REPLACE = DB:Prepare("REPLACE INTO wltj_data ( szKey, tCommon, t5R, t10R ) VALUES ( ?, ?, ?, ? )")
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(unpack(g2d({szKey, LR.JsonEncode(tCommon), LR.JsonEncode(t5R), LR.JsonEncode(t10R)})))
	DB_REPLACE:Execute()
end

function _C.LoadAllUsrData()
	Log("[LR] WLTJ load begin\n")
	local _begin_time = GetTickCount()
	local path = sformat("%s\\%s", SaveDataPath, db_name)
	local DB = LR.OpenDB(path, "WLTJ_LOAD_DATA_05DADF3216579FSDF62SDERGK67AFC9")

	local DB_SELECT = DB:Prepare("SELECT * FROM wltj_data WHERE szKey IS NOT NULL")
	local Data = d2g(DB_SELECT:GetAll())
	LR.CloseDB(DB)
	Log(sformat("[LR] WLTJ load cost %0.3f s", (GetTickCount() - _begin_time) * 1.0 / 1000))

	local all_data = {}
	for k, v in pairs(Data) do
		all_data[v.szKey] = {}
		all_data[v.szKey].szKey = v.szKey
		all_data[v.szKey].eCanAccept = v.eCanAccept
		all_data[v.szKey].nQuestPhase = v.nQuestPhase
		all_data[v.szKey].tCommon = LR.JsonDecode(v.tCommon)
		all_data[v.szKey].t5R = LR.JsonDecode(v.t5R)
		all_data[v.szKey].t10R = LR.JsonDecode(v.t10R)
	end
	ALL_USER_DATA = clone(all_data)
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local me = GetClientPlayer()
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	_C.GetData()
	ALL_USER_DATA[szKey] = clone(SELF_DATA)
end

--UI
LR_WLTJ = {}
LR_WLTJ.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0},
}

function LR_WLTJ.OnEvent(event)
	if event == "UI_SCALED" then
		LR_WLTJ.UpdateAnchor(this)
	end
end

function LR_WLTJ.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_WLTJ.UsrData.Anchor.s, 0, 0, LR_WLTJ.UsrData.Anchor.r, LR_WLTJ.UsrData.Anchor.x, LR_WLTJ.UsrData.Anchor.y)
end

function LR_WLTJ.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")

	LR_WLTJ.UpdateAnchor(this)

	LR_WLTJ.frame = nil
	_C.GetIDCanDo()
	_C.GetData()
end


function LR_WLTJ.Initial()
	local frame = LR.AppendUI("Frame", "LR_WLTJ", {title = _L["LR_WLTJ"] , style = "LARGER2"})

	local imgTab = LR.AppendUI("Image", frame,"TabImg",{w = 1075, h = 33, x = 65,y = 60})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex",46)
	imgTab:SetImageType(11)
	imgTab:SetAlpha(180)

	local hPageSet = LR.AppendUI("PageSet", frame, "PageSet", {x = 65, y = 60, w = 1075, h = 650})
	local hWinIconView = LR.AppendUI("Window", hPageSet, "WindowItemView", {x = 20, y = 40, w = 1035, h = 610})
	local hScroll = LR.AppendUI("Scroll", hWinIconView,"Scroll", {x = 0, y = 30, w = 1035, h = 510})
	LR_WLTJ.hScroll = hScroll
	--self:LoadItemBox(hScroll)
	--hScroll:UpdateList()
	local hComboBox = LR.AppendUI("ComboBox", frame, "ComboBox_List", {w = 160, x = 100, y = 61, text = _L["Quest list"]})
	hComboBox:Enable(true)
	local tab_check = {}
	for k, v in pairs(ID_CAN_DO) do
		for k2, dwQuestID in pairs(v) do
			tab_check[dwQuestID] = true
		end
	end
	hComboBox.OnClick = function(m)
		local ids = _C.GetIDCanDo(true)
		local tab = {}
		for k, v in pairs(ids) do
			for k2, dwQuestID in pairs(v) do
				tinsert(tab, dwQuestID)
			end
		end
		for k, dwQuestID in pairs(tab) do
			local QuestInfo = LR.Table_GetQuestStringInfo(dwQuestID)
			m[#m + 1] = {szOption = QuestInfo.szName, bCheck = true, bMCheck = false,
				bChecked = function()
					return tab_check[dwQuestID]
				end,
				fnAction = function()
					tab_check[dwQuestID] = not tab_check[dwQuestID]
					ID_CAN_DO = {}
					for GroupName, v in pairs(ids) do
						for k2, dwQuestID in pairs(v) do
							if tab_check[dwQuestID] then
								ID_CAN_DO[GroupName] = ID_CAN_DO[GroupName] or {}
								tinsert(ID_CAN_DO[GroupName], dwQuestID)
							end
						end
					end
					LR_WLTJ.SetTitle()
					LR_WLTJ.List()
				end,
				}
		end
		PopupMenu(m)
	end
	hComboBox.OnEnter = function()
		local x, y = this:GetAbsPos()
		local tip = {}
		tip[#tip + 1] = GetFormatText(_L["ComboBox Tip01"], 32)
		OutputTip(tconcat(tip), 320, {x, y, 0, 0})
	end
	hComboBox.OnLeave = function()
		HideTip()
	end

	local BtnLock = LR.AppendUI("Button", frame, "BtnLock", {x = 270, y = 60, w = 100, h = 30, text = _L["Lock"]})
	BtnLock.OnClick = function()
		_C.LockIDList()
	end
	BtnLock.OnEnter = function()
		local x, y = this:GetAbsPos()
		local path = sformat("%s\\WLTJ_ID.dat", SaveDataPath)
		local ids = LoadLUAData(path) or {}
		local tab = {}
		for GroupName, v in pairs(ids) do
			for k, dwQuestID in pairs(v) do
				tinsert(tab, dwQuestID)
			end
		end
		local tip = {}
		if next(tab) == nil then
			tip[#tip + 1] = GetFormatText(_L["No list lock now"], 32)
		else
			tip[#tip + 1] = GetFormatText(_L["The locked-list now is :\n"], 2)
			for k, dwQuestID in pairs(tab) do
				local QuestInfo = LR.Table_GetQuestStringInfo(dwQuestID)
				tip[#tip + 1] = GetFormatText(sformat("%s\n", QuestInfo.szName), 32)
			end
		end

		OutputTip(tconcat(tip), 320, {x, y, 0, 0})
	end
	BtnLock.OnLeave = function()
		HideTip()
	end
	--local hHandle = LR.AppendUI("Handle", frame, "Handle", {x = 18, y = 150, w = 340, h = 330})

	local Image_Record_BG = LR.AppendUI("Image", hWinIconView, "Image_Record_BG", {x = 0, y = 0, w = 1035, h = 540})
	Image_Record_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",50)
	Image_Record_BG:SetImageType(10)

	local Image_Record_BG0 = LR.AppendUI("Image", hWinIconView,"Image_Record_BG0",{w = 1035, h = 30, x = 0,y = 0})
    Image_Record_BG0:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	Image_Record_BG0:SetImageType(11)
	Image_Record_BG0:SetAlpha(110)

	local Image_Record_BG1 = LR.AppendUI("Image", hWinIconView, "Image_Record_BG1", {x = 0, y = 30, w = 1035, h = 510})
	Image_Record_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74)
	Image_Record_BG1:SetImageType(10)
	Image_Record_BG1:SetAlpha(50)

	local Image_Record_Line1_0 = LR.AppendUI("Image", hWinIconView, "Image_Record_Line1_0", {x = 3, y = 28, w = 1032, h = 3})
	Image_Record_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",65)
	Image_Record_Line1_0:SetImageType(11)
	Image_Record_Line1_0:SetAlpha(180)

	local Text_Title_RoleName = LR.AppendUI("Text", hWinIconView, "Text_Title_RoleName", {x = 0, y = 0, w = 150, h = 30, text = _L["name"]})
	Text_Title_RoleName:SetVAlign(1):SetHAlign(1):SetFontScheme(2):RegisterEvent(304)
	local Image_Break_RoleName = LR.AppendUI("Image", hWinIconView, "Image_Break_RoleName", {x = 150, y = 0, w = 3, h = 540})
	Image_Break_RoleName:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48):SetImageType(12):SetAlpha(180)

	local Handle_Title_WLGJ = LR.AppendUI("Handle", hWinIconView, "Handle_Title_WLGJ", {x = 150, y = 0, w = 882, h = 30})
	LR_WLTJ.Handle_Title_WLGJ = Handle_Title_WLGJ

	LR_WLTJ.SetTitle()
	LR_WLTJ.List()

	LR.AppendAbout(LR_WLTJ, frame)
end

function LR_WLTJ.SetTitle()
	local IDs = clone(ID_CAN_DO) or {}
	local group = {"t5R", "t10R", "tCommon",}
	local limit_num = {3, 3, 2}
	local title_num = 0
	for k, GroupName in pairs(group) do
		IDs[GroupName] = IDs[GroupName] or {}
		for k2 = 1, limit_num[k] do
			if IDs[GroupName][k2] then
				title_num = title_num + 1
			end
		end
	end

	local Handle_Title_WLGJ = LR_WLTJ.Handle_Title_WLGJ
	Handle_Title_WLGJ:ClearHandle()
	local Per_Width = mfloor(885.0 / title_num)
	local Image_Break = {}
	for i = 1, title_num - 1, 1 do
		Image_Break[i] = LR.AppendUI("Image", Handle_Title_WLGJ, sformat("Image_Break_%d", i), {x = i * Per_Width, y = 0, w = 3, h = 540})
		Image_Break[i]:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
		Image_Break[i]:SetImageType(12)
		Image_Break[i]:SetAlpha(180)
	end

	local Text_Title_WLTJ = {}
	for i = 1, title_num, 1 do
		Text_Title_WLTJ[i] = LR.AppendUI("Text", Handle_Title_WLGJ, sformat("Text_Title_WLTJ_%d", i), {x = (i - 1) * Per_Width, y = 0, w = Per_Width, h = 30, text = ""})
		Text_Title_WLTJ[i]:SetVAlign(1):SetHAlign(1):SetFontScheme(2):RegisterEvent(304)
	end

	local i = 1
	for k, GroupName in pairs(group) do
		for k2 = 1, limit_num[k] do
			if IDs[GroupName][k2] then
				local dwQuestID = IDs[GroupName][k2]
				if dwQuestID then
					local QuestInfo = LR.Table_GetQuestStringInfo(dwQuestID)
					Text_Title_WLTJ[i]:SetText(wssub(QuestInfo.szName, mmax(1, wslen(QuestInfo.szName) - mfloor(Per_Width / 24.0)), wslen(QuestInfo.szName)))
					Text_Title_WLTJ[i].OnEnter = function()
						local nMouseX, nMouseY = this:GetAbsPos()
						local tText = {}
						tText[#tText + 1] = GetFormatText(QuestInfo.szName)
						OutputTip(tconcat(tText), 250, {nMouseX, nMouseY, 0, 0})
					end
					Text_Title_WLTJ[i].OnLeave = function()
						HideTip()
					end
					i = i + 1
				end
			end
		end
	end
end

function LR_WLTJ.List()
	local frame = Station.Lookup("Normal/LR_WLTJ")
	if not frame then
		return
	end
	LR_WLTJ.hScroll:ClearHandle()
	_C.LoadAllUsrData()
	local TempTable_Cal, TempTable_NotCal = LR_AS_Base.SeparateUsrList()
	LR_WLTJ.Count = 1
	for k, v in pairs(TempTable_Cal) do
		LR_WLTJ.ShowOneData(v)
	end
	for k, v in pairs(TempTable_NotCal) do
		LR_WLTJ.ShowOneData(v)
	end
	LR_WLTJ.hScroll:UpdateList()
end

function LR_WLTJ.ShowOneData(data)
	local IDs = clone(ID_CAN_DO) or {}
	local group = {"t5R", "t10R", "tCommon",}
	local limit_num = {3, 3, 2}
	local title_num = 0
	for k, GroupName in pairs(group) do
		IDs[GroupName] = IDs[GroupName] or {}
		for k2 = 1, limit_num[k] do
			if IDs[GroupName][k2] then
				title_num = title_num + 1
			end
		end
	end
	local hScroll = LR_WLTJ.hScroll
	local hRole = LR.AppendUI("Handle", hScroll, sformat("hRole_%s", data.szKey), {x = 0, y = 0, w = 1035, h = 30})
	local Image_BG = LR.AppendUI("Image", hRole, sformat("Image_BG_%s", data.szKey), {x = 0, y = 0, w = 1035, h = 30})
	Image_BG:FromUITex("ui\\Image\\UICommon\\LoginCommon.UITex", 64)
	if LR_WLTJ.Count % 2 == 0 then
		Image_BG:SetAlpha(255)
	else
		Image_BG:SetAlpha(80)
	end
	local Image_Hover = LR.AppendUI("Image", hRole, sformat("Image_Hover_%s", data.szKey), {x = 0, y = 0, w = 1035, h = 30})
	Image_Hover:FromUITex("ui\\Image\\Common\\TempBox.UITex", 5):SetImageType(2):SetAlpha(180):Hide()

	local Image_Force = LR.AppendUI("Image", hRole, sformat("Image_Force_%s", data.szKey), {x = 3, y = 0, w = 30, h = 30})
	local path, frame = GetForceImage(data.dwForceID or 0)
	Image_Force:FromUITex(path, frame)

	local r, g, b = LR.GetMenPaiColor(data.dwForceID)
	local Text_RoleName = LR.AppendUI("Text", hRole, sformat("Text_RoleName_%d", data.dwID), {x = 30, y = 0, w = 150 - 30, h = 30, text = wssub(data.szName, 1, mceil(150 / 24.0))})
	Text_RoleName:SetVAlign(1):SetHAlign(0):SetFontScheme(2):SetText(sformat("%s(%d)", wssub(data.szName, 1, mceil(150 / 24.0)), data.nLevel)):SetFontColor(r, g, b)

	--开始列表
	ALL_USER_DATA[data.szKey] = ALL_USER_DATA[data.szKey] or {}
	local Per_Width = mfloor(885.0 / title_num)
	local i = 1
	for k, GroupName in pairs(group) do
		ALL_USER_DATA[data.szKey][GroupName] = ALL_USER_DATA[data.szKey][GroupName] or {}
		for k2 = 1, limit_num[k] do
			if IDs[GroupName][k2] then
				local dwQuestID = IDs[GroupName][k2]
				local v = ALL_USER_DATA[data.szKey][GroupName][tostring(dwQuestID)] or {}
				local hText = LR.AppendUI("Text", hRole, sformat("Text_WLTJ_%s_%d", data.szKey, dwQuestID), {x = 150 + (i - 1) * Per_Width, y = 0, w = Per_Width, h = 30, text = "--"})
				hText:SetVAlign(1):SetHAlign(1):SetFontScheme(47)
				if next(v) ~= nil then
					local text = "--"
					if v.eCanAccept == 1 then
						text = _L["--"]
					elseif v.eCanAccept == 7 then
						----3: 表示已完成任务0: 表示任务不存在1: 表示任务正在进行中，2: 表示任务已完成但还没有交-1: 表示任务id非法
						if v.nQuestPhase == 1 then
							text = _L["Doing"]
							hText:SetFontScheme(16)
						elseif v.nQuestPhase == 2 then
							text = _L["Not submit"]
							hText:SetFontScheme(17)
						end
					elseif v.eCanAccept == 57 then
						text = _L["Complete"]
						hText:SetFontScheme(47)
					end
					hText:SetText(text)
				end
				i = i + 1
			end
		end
	end

	hRole.OnEnter = function()
		Image_Hover:Show()
	end
	hRole.OnLeave = function()
		Image_Hover:Hide()
	end
	LR_WLTJ.Count = LR_WLTJ.Count + 1
end



function LR_WLTJ.OpenFrame()
	local frame = Station.Lookup("Normal/LR_WLTJ")
	if frame then
		Wnd.CloseWindow(frame)
	else
		LR_WLTJ.Initial()
	end
end





LR_WLTJ.GetData = _C.GetData
LR_WLTJ.GetIDCanDo = _C.GetIDCanDo
LR_WLTJ.SaveData = _C.SaveData
LR_WLTJ.ClearWLTJdatMonday = _C.ClearWLTJdatMonday

