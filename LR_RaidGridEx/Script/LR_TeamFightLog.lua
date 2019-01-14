local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local VERSION = "20180413"
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_RaidGridEx"
local SaveDataPath="Interface\\LR_Plugin@DATA\\LR_TeamGrid"
local _L = LR.LoadLangPack(AddonPath)
---------------------------------------------------------------
local LOG_TYPE = {
	DO_SKILL_CAST = 1,
	OT_STATE = 2,
	OT_STATE_FINISH = 3,
	MSG_NPC_NEARBY = 4,
	NPC_ENTER_SCENE = 5,
	MSG_NPC_SCENE = 6,
	MSG_NPC_YELL_TO = 7,
	MSG_NPC_WHISPER = 8,
}

local _C = {}
local FIGHT_LOG_CACHE = {}
local FIGHT_LOG_CACHE_LAST = {}
local FIGHT_LOG_CACHE_TEMP = {}
local NPC_CACHE = {}
local KEY = ""
local LOG_TIME = 0
local BEGIN_TIME = 0
local KEY_LIST = {}
local OTBAR_VISIABLE = false
local SKILL_CACHE = {}
local nMaxDistance = 45

function _C.SaveLog()
	if GetCurrentTime() - LOG_TIME >= 30 then
		local _date = TimeToDate(LOG_TIME)
		local me = GetClientPlayer()
		local scene = me.GetScene()
		local path = sformat("%s\\FIGHT_LOG\\%04d%02d%02d_%02d%02d%02d_%s_%s", SaveDataPath, _date["year"], _date["month"], _date["day"], _date["hour"], _date["minute"], _date["second"], me.szName, Table_GetMapName(scene.dwMapID) )
		local data = clone(FIGHT_LOG_CACHE[KEY])
		data.key = "FIGHT_LOG_SAVE"
		LR.SaveLUAData(path, data)
	end
end

function _C.LoadLog()
	local szFile = GetOpenFileName(sformat("%s", _L["Choose file"]), "Save data File(*.jx3dat)\0*.jx3dat\0All Files(*.*)\0*.*\0")
	if szFile == "" then
		return false
	end
	local data = LoadLUAData(szFile) or {}
	if data.key ~= "FIGHT_LOG_SAVE" then
		return false
	end
	data.key = nil
	FIGHT_LOG_CACHE_TEMP = clone(data)
	return true
end

function _C.BeginLog()
	local me = GetClientPlayer()
	if not me or not me.bFightState then
		return
	end
	KEY = sformat("KEY_%d", GetCurrentTime())
	LOG_TIME = GetCurrentTime()
	FIGHT_LOG_CACHE[KEY] = {}
	BEGIN_TIME = GetTickCount()
	tinsert(KEY_LIST, KEY)

	local frame = Station.Lookup("Normal/LR_FIGHT_LOG")
	if frame then
		LR_FIGHT_LOG.hScroll:ClearHandle()
		LR_FIGHT_LOG.hScroll:UpdateList()
	end
end

function _C.EndLog()
	if KEY ~= "" then
		_C.SaveLog()
	end
	KEY = ""
	LOG_TIME = 0
	BEGIN_TIME = 0
end

-------------------------------------------
function _C.GetSkillCache(szName)
	SKILL_CACHE[szName] = {}
	local num = g_tTable.Skill:GetRowCount()
	for i = 1, num, 1 do
		local t = g_tTable.Skill:GetRow(i)
		if t and t.szName == szName then
			tinsert(SKILL_CACHE[szName], {dwSkillID = t.dwSkillID, nLevel = mmax(1, t.dwLevel)})
		end
	end
end

-------------------------------------------
function _C.FIGHT_HINT()
	if not LR_FIGHT_LOG.UserData.bOn then
		return
	end
	local bFight = arg0
	if bFight then
		_C.BeginLog()
	else
		--Output(KEY_LIST, KEY_LIST[#KEY_LIST], FIGHT_LOG_CACHE[KEY_LIST[#KEY_LIST]])
		FIGHT_LOG_CACHE_LAST = clone(FIGHT_LOG_CACHE)
		_C.EndLog()
	end
end

function _C.DO_SKILL_CAST()
	if not LR_FIGHT_LOG.UserData.bOn then
		return
	end
	local dwCaster = arg0
	local dwSkillID = arg1
	local nLevel = arg2
	if IsPlayer(dwCaster) and dwCaster ~= 0 or KEY == "" then
		return
	end
	if not Table_IsSkillShow(dwSkillID, nLevel) then
		return
	end
	local szName, data = LR_TeamTools.DeathRecord.GetName(TARGET.NPC, dwCaster)
	local dwTemplateID, blood_fp = 0, 1
	if data then
		if data.bPet then
			return
		end
		if data.obj then
			if LR.GetDistance(data.obj) > nMaxDistance then
				return
			end
			blood_fp = data.obj.nCurrentLife * 1.0 / data.obj.nMaxLife
		else
			if LR.GetDistance(data) > nMaxDistance then
				return
			end
		end
		dwTemplateID = data.dwTemplateID
	end
	local tab = {dwSkillID = dwSkillID, nLevel = nLevel, nType = LOG_TYPE.DO_SKILL_CAST, caster = {szName = szName, dwTemplateID = dwTemplateID, blood_fp = blood_fp}, nTime = GetTickCount() - BEGIN_TIME }
	tinsert(FIGHT_LOG_CACHE[KEY], tab)
	LR_FIGHT_LOG.AppendLog(tab, true)
end

function _C.CheckOTState()
	if not LR_FIGHT_LOG.UserData.bOn then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local _nType, _dwID = me.GetTarget()
	if not (_nType == TARGET.NPC or _nType == TARGET.PLAYER) then
		return
	end
	local path, szOTname, dwTemplateID, data, blood_fp = "", "", 0, nil, 1
	if _nType == TARGET.NPC then
		path = "Normal/Target"
		szOTname, data = LR_TeamTools.DeathRecord.GetName(TARGET.NPC, _dwID)
		if data then
			if data.bPet then
				return
			end
			if data.obj then
				if LR.GetDistance(data.obj) > nMaxDistance then
					return
				end
				blood_fp = data.obj.nCurrentLife * 1.0 / data.obj.nMaxLife
			else
				if LR.GetDistance(data) > nMaxDistance then
					return
				end
			end
			dwTemplateID = data.dwTemplateID
		end
	else
		local player = GetPlayer(_dwID)
		if player then
			_nType, _dwID = player.GetTarget()
			if _nType == TARGET.NPC then
				path = "Normal/TargetTarget"
				szOTname, data = LR_TeamTools.DeathRecord.GetName(TARGET.NPC, _dwID)
				if data then
					if data.bPet then
						return
					end
					if data.obj then
						if LR.GetDistance(data.obj) > nMaxDistance then
							return
						end
						blood_fp = data.obj.nCurrentLife * 1.0 / data.obj.nMaxLife
					else
						if LR.GetDistance(data) > nMaxDistance then
							return
						end
					end
					dwTemplateID = data.obj.dwTemplateID
				end
			else
				return
			end
		end
	end
	local frame = Station.Lookup(path)
	if not frame then
		return
	end
	local Handle_Target = frame:Lookup("","")
	local Handle_Bar = Handle_Target:Lookup("Handle_Bar")
	if not Handle_Bar:IsVisible() then
		if OTBAR_VISIABLE then
			local tab = {nType = LOG_TYPE.OT_STATE_FINISH, caster = {szName = szOTname, dwTemplateID = dwTemplateID, blood_fp = blood_fp}, nTime = GetTickCount() - BEGIN_TIME }
			tinsert(FIGHT_LOG_CACHE[KEY], tab)
			OTBAR_VISIABLE = false
			LR_FIGHT_LOG.AppendLog(tab, true)
		end
		return
	end
	if not OTBAR_VISIABLE then
		local Image_Progress = Handle_Bar:Lookup("Image_Progress") or Handle_Bar:Lookup("Image_BarProgress")
		local Image_FlashF = Handle_Bar:Lookup("Image_FlashF")
		local Image_FlashS = Handle_Bar:Lookup("Image_FlashS")
		local Text_Name = Handle_Bar:Lookup("Text_Name")
		local szSkillName = Text_Name:GetText()
		local tab = {szSkillName = szSkillName, nType = LOG_TYPE.OT_STATE, caster = {szName = szOTname, dwTemplateID = dwTemplateID}, nTime = GetTickCount() - BEGIN_TIME }
		tinsert(FIGHT_LOG_CACHE[KEY], tab)
		OTBAR_VISIABLE = true
		LR_FIGHT_LOG.AppendLog(tab, true)
	end
end

function _C.NPC_TALK()
	local dwNpcID = arg0
	local szContent = arg1
	local nChannel = arg2
	local szMsg = nil
	local hNpc = GetNpc(dwNpcID)
	local szName = Table_GetNpcTemplateName(hNpc.dwTemplateID)
    if nChannel == PLAYER_TALK_CHANNEL.WHISPER then
    	szChannel = "MSG_NPC_WHISPER"
    	szMsg = "["..szName.."]"..g_tStrings.STR_TALK_HEAD_WHISPER..szText.."\n"
    elseif nChannel == PLAYER_TALK_CHANNEL.NEARBY then
    	szChannel = "MSG_NPC_NEARBY"
    	szMsg = "["..szName.."]"..g_tStrings.STR_TALK_HEAD_SAY..szText.."\n"
    elseif nChannel == PLAYER_TALK_CHANNEL.SENCE then
    	szChannel = "MSG_NPC_YELL"
    	szMsg = "["..szName.."]"..g_tStrings.STR_TALK_HEAD_SAY2..szText.."\n"
    else
    	szChannel = "MSG_NPC_NEARBY"
    	szMsg = "["..szName.."]"..g_tStrings.STR_TALK_HEAD_SAY..szText.."\n"
    end
	Output("NPC_TALK", szMsg)

end


function _C.PLAYER_SAY()
	if not LR_FIGHT_LOG.UserData.bOn then
		return
	end
	local szContent = arg0
	local dwID = arg1
	local nChannel = arg2
	if IsPlayer(dwID) and dwID ~= 0 or KEY == "" then
		return
	end

	if nChannel == PLAYER_TALK_CHANNEL.NPC_NEARBY or nChannel == PLAYER_TALK_CHANNEL.NPC_SENCE or nChannel == PLAYER_TALK_CHANNEL.MSG_NPC_YELL then
		local szName, data = LR_TeamTools.DeathRecord.GetName(TARGET.NPC, dwID)
		local dwTemplateID, blood_fp = 0, 1
		if data then
			if data.bPet then
				return
			end
			if data.obj then
				if LR.GetDistance(data.obj) > nMaxDistance then
					return
				end
				blood_fp = data.obj.nCurrentLife * 1.0 / data.obj.nMaxLife
			else
				if LR.GetDistance(data) > nMaxDistance then
					return
				end
			end
			dwTemplateID = data.dwTemplateID
		end
		local text = GetPureText(szContent)
		local tab = {nType = LOG_TYPE.MSG_NPC_NEARBY, szText = text, OriginalText = szContent, caster = {szName = szName, dwTemplateID = dwTemplateID, blood_fp = blood_fp}, nTime = GetTickCount() - BEGIN_TIME}
		if nChannel == PLAYER_TALK_CHANNEL.NPC_NEARBY then
			tab.nType = LOG_TYPE.MSG_NPC_NEARBY
		elseif nChannel == PLAYER_TALK_CHANNEL.NPC_SENCE then
			tab.nType = LOG_TYPE.MSG_NPC_SCENE
		elseif nChannel == PLAYER_TALK_CHANNEL.NPC_SAY_TO then
			tab.nType = LOG_TYPE.MSG_NPC_WHISPER
		elseif nChannel == PLAYER_TALK_CHANNEL.NPC_YELL_TO then
			tab.nType = LOG_TYPE.MSG_NPC_YELL_TO
		end
		tinsert(FIGHT_LOG_CACHE[KEY], tab)
		LR_FIGHT_LOG.AppendLog(tab, true)
	end
end

function _C.NPC_ENTER_SCENE2(data)
	if not LR_FIGHT_LOG.UserData.bOn or KEY == "" then
		return
	end
	local szName, data2 = LR_TeamTools.DeathRecord.GetName(TARGET.NPC, dwID)
	local dwTemplateID, blood_fp = 0, 1
	if data2 then
		dwTemplateID = data2.dwTemplateID
		if data2.obj then
			blood_fp = data2.obj.nCurrentLife * 1.0 / data2.obj.nMaxLife
		end
	end
	Output("dsd", data)
	local tab = {nType = LOG_TYPE.NPC_ENTER_SCENE, npc = {szName = szName, dwTemplateID = dwTemplateID, blood_fp = blood_fp}, nTime = data.nTime - BEGIN_TIME}
	tinsert(FIGHT_LOG_CACHE[KEY], tab)
	LR_FIGHT_LOG.AppendLog(tab, true)
end

function _C.NPC_ENTER_SCENE()
	if not LR_FIGHT_LOG.UserData.bOn then
		return
	end
	local dwID = arg0
	local nTime = GetTickCount()
	LR.DelayCall(100, function() _C.NPC_ENTER_SCENE2({dwID = dwID, nTime = nTime}) end)
end

function _C.MsgMonitor(szMsg, nFont, bRich, r, g, b, szChannel)
	--------
end

function _C.BreatheCall()
	_C.CheckOTState()
end

LR.BreatheCall("FIGHT_HINT_LOG_BREATHE", function() _C.BreatheCall() end)
RegisterMsgMonitor(_C.MsgMonitor, {"MSG_NPC_NEARBY", "MSG_NPC_YELL", "MSG_NPC_PARTY", "MSG_NPC_WHISPER"})
LR.RegisterEvent("FIGHT_HINT", function() _C.FIGHT_HINT() end)
LR.RegisterEvent("DO_SKILL_CAST", function() _C.DO_SKILL_CAST() end)
LR.RegisterEvent("PLAYER_SAY", function() _C.PLAYER_SAY() end)
LR.RegisterEvent("NPC_TALK", function() _C.NPC_TALK() end)
LR.RegisterEvent("NPC_ENTER_SCENE", function() _C.NPC_ENTER_SCENE() end)

----------------
LR_FIGHT_LOG = {}
LR_FIGHT_LOG.UserData = {
	bOn = false,
}
LR_FIGHT_LOG.Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0}
LR_FIGHT_LOG.bShowHistory = false

function LR_FIGHT_LOG.OnEvent(event)
	if event == "UI_SCALED" then
		LR_FIGHT_LOG.UpdateAnchor(this)
	end
end

function LR_FIGHT_LOG.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_FIGHT_LOG.Anchor.s, 0, 0, LR_FIGHT_LOG.Anchor.r, LR_FIGHT_LOG.Anchor.x, LR_FIGHT_LOG.Anchor.y)
end

function LR_FIGHT_LOG.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")

	LR_FIGHT_LOG.UpdateAnchor(this)
end

function LR_FIGHT_LOG.Initial()
	local frame = LR.AppendUI("Frame", "LR_FIGHT_LOG", {title = _L["LR_FIGHT_LOG"] , style = "LARGER2"})
	LR_FIGHT_LOG.frame = frame

	local imgTab = LR.AppendUI("Image", frame,"TabImg",{w = 1075, h = 33, x = 65,y = 60})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex",46)
	imgTab:SetImageType(11)
	imgTab:SetAlpha(180)

	local hPageSet = LR.AppendUI("PageSet", frame, "PageSet", {x = 65, y = 60, w = 1075, h = 650})
	local hWinIconView = LR.AppendUI("Window", hPageSet, "WindowItemView", {x = 20, y = 40, w = 1035, h = 610})
	local hScroll = LR.AppendUI("Scroll", hWinIconView,"Scroll", {x = 0, y = 30, w = 1035, h = 510})
	LR_FIGHT_LOG.hScroll = hScroll

	local hComboBox = LR.AppendUI("ComboBox", frame, "ComboBox_List", {w = 160, x = 85, y = 61, text = _L["Option"]})
	hComboBox:Enable(true)
	hComboBox.OnClick = function(m)
		m[#m + 1] = {szOption = _L["Begin log"], bCheck = true, bMCheck = false, bChecked = function() return LR_FIGHT_LOG.UserData.bOn end,
			fnAction = function()
				LR_FIGHT_LOG.UserData.bOn = not LR_FIGHT_LOG.UserData.bOn
				if LR_FIGHT_LOG.UserData.bOn then
					_C.BeginLog()
				else
					_C.EndLog()
				end
			end,
		}
		m[#m + 1] = {bDevide = true}
		m[#m + 1] = {szOption = _L["Load current data"], bCheck = true, bMCheck = true, bChecked = function() return not LR_FIGHT_LOG.bShowHistory end,
			fnAction = function()
				LR_FIGHT_LOG.bShowHistory = false
				LR_FIGHT_LOG.ListLog()
				Wnd.CloseWindow(GetPopupMenu())
			end,
		}
		m[#m + 1] = {szOption = _L["Load history"], bCheck = true, bMCheck = true, bChecked = function() return LR_FIGHT_LOG.bShowHistory end,
			fnAction = function()
				if _C.LoadLog() then
					LR_FIGHT_LOG.bShowHistory = true
					LR_FIGHT_LOG.ListLog()
					Wnd.CloseWindow(GetPopupMenu())
				end
			end,
		}
		PopupMenu(m)
	end

	-------
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

	local Text_Title_RoleName = LR.AppendUI("Text", hWinIconView, "Text_Title_RoleName", {x = 0, y = 0, w = 150, h = 30, text = _L["time"]})
	Text_Title_RoleName:SetVAlign(1):SetHAlign(1):SetFontScheme(2):RegisterEvent(304)
	local Image_Break_RoleName = LR.AppendUI("Image", hWinIconView, "Image_Break_RoleName", {x = 150, y = 0, w = 3, h = 540})
	Image_Break_RoleName:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48):SetImageType(12):SetAlpha(180)

	LR.AppendAbout(LR_WLTJ, frame)
end

function LR_FIGHT_LOG.AppendNormalText(parent, data)
	local Text_NormalText = LR.AppendUI("Text", parent, "Text_NormalText", {h = 30, text = data.szText})
end

function LR_FIGHT_LOG.AppendNPC(parent, data)
	local v = clone(data)
	local hText_NPC = LR.AppendUI("Text", parent, "Text_NPC", {h = 30, text = sformat("[%s]", v.szName), event = 304})
	hText_NPC:RegisterEvent(304)
	hText_NPC.OnEnter = function()
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local tip = {}
		tip[#tip + 1] = GetFormatText(sformat("%s(NPC)\n", v.szName))
		tip[#tip + 1] = GetFormatText(sformat(_L["dwTemplateID:%d\n"], v.dwTemplateID or 0))
		tip[#tip + 1] = GetFormatText(sformat(_L["Blood :%d%%\n"], (v.blood_fp or 1) * 100))
		OutputTip(tconcat(tip), 320, {x, y, w, h})
	end
	hText_NPC.OnLeave = function()
		HideTip()
	end
end

function LR_FIGHT_LOG.AppendSkill(parent, data)
	local v = clone(data)
	local Text_Skill = LR.AppendUI("Text", parent, "Text_Skill", {h = 30, text = "", event = 304})
	if data.szSkillName then
		Text_Skill:SetText(sformat("[%s]", data.szSkillName))
	else
		Text_Skill:SetText(sformat("[%s]", Table_GetSkillName(v.dwSkillID, v.nLevel)))
	end
	Text_Skill:RegisterEvent(304)
	Text_Skill.OnEnter = function()
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		if data.szSkillName then
			local tip = {}
			tip[#tip + 1] = GetFormatText(sformat("%s\n", v.szSkillName))
			OutputTip(tconcat(tip), 320, {x, y, w, h})
		else
			OutputSkillTip(v.dwSkillID, v.nLevel, {x, y, w, h})
		end
	end
	Text_Skill.OnLeave = function()
		HideTip()
	end
	Text_Skill.OnClick = function()
		if data.szSkillName then
			local szName = LR.Trim(data.szSkillName)
			if szName ~= "" then
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				if not SKILL_CACHE[szName] then
					_C.GetSkillCache(szName)
				end
				local menu = {}
				for k2, v2 in pairs(SKILL_CACHE[szName]) do
					menu[#menu + 1] = {szOption = sformat("%s(id: %d , level: %d )", Table_GetSkillName(v2.dwSkillID, v2.nLevel), v2.dwSkillID, v2.nLevel),
						fnMouseEnter = function()
							local x, y = this:GetAbsPos()
							local w, h = this:GetSize()
							OutputSkillTip(v2.dwSkillID, 1, {x, y, w, h})
						end,
						fnMouseLeave = function()
							HideTip()
						end,
					}

				end
				PopupMenu(menu)
			end
		end
	end
end

function LR_FIGHT_LOG.ListLog()
	local frame = Station.Lookup("Normal/LR_FIGHT_LOG")
	if not frame then
		return
	end
	LR_FIGHT_LOG.hScroll:ClearHandle()
	if LR_FIGHT_LOG.bShowHistory then
		local data = FIGHT_LOG_CACHE_TEMP or {}
		for k, v in pairs(data) do
			LR_FIGHT_LOG.AppendLog(v)
		end
	else
		if KEY ~= "" then
			local data = clone(FIGHT_LOG_CACHE or {})
			for i = #data - 17, #data, 1 do
				LR_FIGHT_LOG.AppendLog(data[i], true)
			end
		else
			local data = clone(FIGHT_LOG_CACHE_LAST)
			for k, v in pairs(data) do
				LR_FIGHT_LOG.AppendLog(v)
			end
		end
	end

	LR_FIGHT_LOG.hScroll:UpdateList()
end

function LR_FIGHT_LOG.AppendLog(data, bring2top)
	local frame = Station.Lookup("Normal/LR_FIGHT_LOG")
	if not frame then
		return
	end
	local hScroll = LR_FIGHT_LOG.hScroll

	local hHandle_Log = LR.AppendUI("Handle", hScroll, "Handle_Log", {w = 1032, h = 30})
	local Image_BG = LR.AppendUI("Image", hHandle_Log, "Image_BG", {x = 0, y = 0, w = 1035, h = 30})
	Image_BG:FromUITex("ui\\Image\\UICommon\\LoginCommon.UITex", 64):SetAlpha(80)

	local hText_Time = LR.AppendUI("Text", hHandle_Log, "Text_Time", {w = 150, h = 30, x = 0, y = 0, text = sformat("%0.2f", (data.nTime or 0) / 1000.0)})
	hText_Time:SetVAlign(1):SetHAlign(1):SetFontScheme(2)
	local hHandle_Content = LR.AppendUI("Handle", hHandle_Log, "hHandle_Content", {w = 880, h = 30, x = 152, y = 2})
	hHandle_Content:SetHandleStyle(3)

	if data.nType == LOG_TYPE.DO_SKILL_CAST then
		local text = {}
		LR_FIGHT_LOG.AppendNPC(hHandle_Content, data.caster)
		LR_FIGHT_LOG.AppendNormalText(hHandle_Content, {szText = _L[" cast skill: "]})
		LR_FIGHT_LOG.AppendSkill (hHandle_Content, {szSkillName = data.szSkillName, dwSkillID = data.dwSkillID, nLevel = data.nLevel})
	elseif data.nType == LOG_TYPE.OT_STATE then
		LR_FIGHT_LOG.AppendNPC(hHandle_Content, data.caster)
		LR_FIGHT_LOG.AppendNormalText(hHandle_Content, {szText = _L[" cast ot skill: "]})
		LR_FIGHT_LOG.AppendSkill (hHandle_Content, {szSkillName = data.szSkillName, dwSkillID = data.dwSkillID, nLevel = data.nLevel})
		Image_BG:FromUITex("ui\\Image\\Common\\Money.UITex", 215):SetAlpha(180)
	elseif data.nType == LOG_TYPE.OT_STATE_FINISH then
		LR_FIGHT_LOG.AppendNPC(hHandle_Content, data.caster)
		LR_FIGHT_LOG.AppendNormalText(hHandle_Content, {szText = _L[" ends ot skill."]})
		Image_BG:FromUITex("ui\\Image\\Common\\Money.UITex", 215):SetAlpha(180)
	elseif data.nType == LOG_TYPE.MSG_NPC_NEARBY or data.nType == LOG_TYPE.MSG_NPC_SCENE then
		if data.nType == LOG_TYPE.MSG_NPC_SCENE then
			LR_FIGHT_LOG.AppendNormalText(hHandle_Content, {szText = _L["[MAP] "]})
		end
		LR_FIGHT_LOG.AppendNPC(hHandle_Content, data.caster)
		LR_FIGHT_LOG.AppendNormalText(hHandle_Content, {szText = _L[" say: "]})
		LR_FIGHT_LOG.AppendNormalText(hHandle_Content, {szText = data.szText})
		--Image_BG:FromUITex("ui\\Image\\Common\\Money.UITex", 215):SetAlpha(180)
	elseif data.nType == LOG_TYPE.NPC_ENTER_SCENE then
		LR_FIGHT_LOG.AppendNPC(hHandle_Content, data.npc)
		LR_FIGHT_LOG.AppendNormalText(hHandle_Content, {szText = _L[" enter the scene."]})
	end
	hHandle_Content:FormatAllItemPos()

	if bring2top then
		hHandle_Log:SetIndex(0)
		if hScroll:GetHandle():Lookup(1):Lookup("Image_BG"):GetAlpha() == 255 then
			Image_BG:SetAlpha(80)
		else
			Image_BG:SetAlpha(255)
		end
		for k = hScroll:GetItemCount(), 17, -1 do
			hScroll:RemoveItem(k)
		end
	else
		if hScroll:GetHandle():Lookup(hScroll:GetHandle():GetItemCount() - 1):Lookup("Image_BG"):GetAlpha() == 255 then
			Image_BG:SetAlpha(80)
		else
			Image_BG:SetAlpha(255)
		end
	end

	hScroll:UpdateList()
end

function LR_FIGHT_LOG.OpenFrame()
	local frame = Station.Lookup("Normal/LR_FIGHT_LOG")
	if frame then
		Wnd.CloseWindow(frame)
	else
		LR_FIGHT_LOG.Initial()
	end
end
