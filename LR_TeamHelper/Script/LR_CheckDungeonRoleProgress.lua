local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_TeamHelper"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_TeamHelper"
local _L = LR.LoadLangPack(AddonPath)
---------------------------------------------------------------
--¶ÀÁ¢cdµÄmap
local INDEPENDENT_MAP = {
	[298] = true,
	[300] = true,
	[299] = true,
	[301] = true,
	[360] = true,
	[354] = true,
	[349] = true,
	[348] = true,
	[347] = true,
	[341] = true,
}

local UI = {}
LR_CDRP = {
	Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0,},
}


function LR_CDRP.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("PARTY_ADD_MEMBER")
	this:RegisterEvent("PARTY_DELETE_MEMBER")
	this:RegisterEvent("TEAM_CHANGE_MEMBER_GROUP")
	this:RegisterEvent("PARTY_DISBAND")
	LR_CDRP.dwMapID = 298
	LR_CDRP.dwProgressID = 0

	ApplyDungeonRoleProgress(298, GetClientPlayer().dwID)
	Table_GetCDProcessBoss(298)
end

function LR_CDRP.OnEvent(szEvent)
	if szEvent == "UI_SCALED" then
		LR_CDRP.UpdateAnchor(this)
	elseif szEvent == "PARTY_ADD_MEMBER" then
		LR_CDRP.Load()
		LR_CDRP.AutoSize()
	elseif szEvent == "PARTY_DELETE_MEMBER" then
		LR_CDRP.Load()
		LR_CDRP.AutoSize()
	elseif szEvent == "TEAM_CHANGE_MEMBER_GROUP" then
		LR_CDRP.Load()
		LR_CDRP.AutoSize()
	elseif szEvent == "PARTY_DISBAND" then
		LR_CDRP.Load()
		LR_CDRP.AutoSize()
	end
end

function LR_CDRP.OnFrameBreathe()
	if GetLogicFrameCount() % 15	 == 0 then
		LR_CDRP.Load()
		LR_CDRP.AutoSize()
	end
end

function LR_CDRP.OnFrameDestroy()
	UI = {}
end

function LR_CDRP.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Close" then
		Wnd.CloseWindow("LR_CDRP")
	elseif szName == "Btn_Option" then
		LR_CDRP.PopOption()
	end
end

function LR_CDRP.PopOption()
	local menu = {}
	for dwMapID, v in pairs(INDEPENDENT_MAP) do
		menu[#menu + 1] = {szOption = Table_GetMapName(dwMapID),
			fnAction = function()
				LR_CDRP.dwMapID = dwMapID
				LR_CDRP.Load()
				LR_CDRP.AutoSize()
			end,
		}
		local m = menu[#menu]
		m[#m + 1] = {szOption = _L["Global"],
			fnAction = function()
				LR_CDRP.dwMapID = dwMapID
				LR_CDRP.dwProgressID = 0
				LR_CDRP.Load()
				LR_CDRP.AutoSize()
			end,}
		local tBossList = Table_GetCDProcessBoss(dwMapID)
		tsort(tBossList, function(a, b)
			return a["dwProgressID"] < b["dwProgressID"]
		end)
		for k, v in pairs(tBossList) do
			m[#m + 1] = {szOption = sformat("%d.%s", v.dwProgressID, v.szName),
				fnAction = function()
					LR_CDRP.dwMapID = dwMapID
					LR_CDRP.dwProgressID = v.dwProgressID
					LR_CDRP.Load()
					LR_CDRP.AutoSize()
				end,
			}
		end
	end
	PopupMenu(menu)
end

function LR_CDRP.UpdateAnchor(frame)
	frame:SetPoint(LR_CDRP.Anchor.s, 0, 0, LR_CDRP.Anchor.r, LR_CDRP.Anchor.x, LR_CDRP.Anchor.y)
	frame:CorrectPos()
end

function LR_CDRP.SetTitle()
	local frame = Station.Lookup("Normal/LR_CDRP")
	if not frame then
		return
	end
	local WndTitle = frame:Lookup("Wnd_Title")
	local TextTitle = WndTitle:Lookup("",""):Lookup("Text_Title")
	local dwMapID = LR_CDRP.dwMapID
	local dwProgressID = LR_CDRP.dwProgressID
	local sz = ""
	if dwProgressID == 0 then
		sz = _L["Global"]
	else
		sz = Table_GetBoss(dwMapID, dwProgressID).szName
	end
	TextTitle:SetText(sformat("%s(%s)", sz, Table_GetMapName(dwMapID)))
	local w, h = TextTitle:GetTextExtent()
	TextTitle:SetSize(w, 30)
end

function LR_CDRP.Ini()
	UI = {}
	local frame = LR.AppendUI("Frame", "LR_CDRP", {path = sformat("%s\\UI\\LR_CheckDungeonRoleProgress.ini", AddonPath)})

	local WndBody = LR.AppendUI("Window", frame, "WndBody", {x = 0, y = 30, w = 120, h = 75})
	local HandleBody = LR.AppendUI("Handle", WndBody, "HandleBody", {x = 0, y = 0, w = 120, h = 75})
	HandleBody:SetHandleStyle(3)
	UI["Frame"] = frame
	UI["WndBody"] = WndBody
	UI["HandleBody"] = HandleBody

	LR_CDRP.Load()
	LR_CDRP.AutoSize()
	LR_CDRP.UpdateAnchor(frame)
end

function LR_CDRP.OpenFrame()
	local frame = Station.Lookup("Normal/LR_CDRP")
	if frame then
		UI = {}
		Wnd.CloseWindow(frame)
	else
		LR_CDRP.Ini()
	end
end

function LR_CDRP.Load()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local frame = Station.Lookup("Normal/LR_CDRP")
	if not frame then
		return
	end

	local HandleBody = UI["HandleBody"]
	local team = GetClientTeam()

	HandleBody:ClearHandle()
	local dwMapID = LR_CDRP.dwMapID
	HandleBody:SetSize(600, 600)
	if not (me.IsInParty() or me.IsInRaid()) then
		local data = {
			dwID = me.dwID,
			szName = me.szName,
			dwForceID = me.dwForceID,
		}
		local kungfu = me.GetKungfuMount()
		if kungfu then
			local dwSkillID = kungfu.dwSkillID
			data.dwMountKungfuID = dwSkillID
		else
			data.dwMountKungfuID = 0
		end
		local HandleTeam = LR.AppendUI("Handle", HandleBody, "HandleTeam", {w = 120, h = 600})
		HandleTeam:SetHandleStyle(3)
		local dwMapID = LR_CDRP.dwMapID
		ApplyDungeonRoleProgress(dwMapID, data.dwID)
		LR_CDRP.LoadOne(HandleTeam, data)
		HandleTeam:FormatAllItemPos()
		HandleTeam:SetSizeByAllItemSize()
		HandleBody:SetSizeByAllItemSize()
		LR_CDRP.SetTitle()
		return
	end

	for i = 0, 4 do
		local GroupInfo = team.GetGroupInfo(i)
		if GroupInfo and next(GroupInfo) ~= nil then
			if next(GroupInfo.MemberList or {}) ~= nil then
				local HandleTeam = LR.AppendUI("Handle", HandleBody, sformat("HandleTeam%d", i), {w = 120, h = 600})
				HandleTeam:SetHandleStyle(3)
				for k, dwMemberID in pairs(GroupInfo.MemberList) do
					local memberInfo = team.GetMemberInfo(dwMemberID)
					memberInfo.dwID = dwMemberID
					local dwMapID = LR_CDRP.dwMapID
					ApplyDungeonRoleProgress(dwMapID, dwMemberID)
					LR_CDRP.LoadOne(HandleTeam, memberInfo)
				end
				HandleTeam:FormatAllItemPos()
				HandleTeam:SetSizeByAllItemSize()
			end
		end
	end
	HandleBody:FormatAllItemPos()
	HandleBody:SetSizeByAllItemSize()

	LR_CDRP.SetTitle()
end

function LR_CDRP.LoadOne(parent, data)
	local dwMapID = LR_CDRP.dwMapID
	ApplyDungeonRoleProgress(dwMapID, data.dwID)
	local HandleRole = LR.AppendUI("Handle", parent, sformat("HandleRole%d", data.dwID), {w = 120, h = 60, eventid = 304})

	local Shadow = LR.AppendUI("Shadow", HandleRole, sformat("Shadow%d", data.dwID), {x = 0, y = 0, w = 120, h = 60})
	Shadow:Hide()
	local ImageBg = LR.AppendUI("Image", HandleRole, sformat("ImageBg%d", data.dwID), {x = 0, y = 0, w = 120, h = 60})
	ImageBg:FromUITex("ui/image/UICommon/YiRong15.uitex", 18):SetImageType(10)
	local HandleName = LR.AppendUI("Handle", HandleRole, sformat("HandleName%d", data.dwID), {x = 0, y = 0, w = 120, h = 30, eventid = 0})
	local ImageKungfu = LR.AppendUI("Image", HandleName, sformat("ImageKungfu%d", data.dwID), {x = 0, y = 0, w = 30, h = 30})
	ImageKungfu:FromIconID(Table_GetSkillIconID(data.dwMountKungfuID, 1))
	local TextName = LR.AppendUI("Text", HandleName, sformat("TextName%d", data.dwID), {x = 30, y = 0, w = 90, h = 30, text = wssub(data.szName, 1, 7)})
	local r, g, b = LR.GetMenPaiColor(data.dwForceID)
	TextName:SetVAlign(1):SetHAlign(0)
	local w, h = TextName:GetTextExtent()
	TextName:SetSize(w, 30)
	HandleName:FormatAllItemPos():SetSize(w + 30, 30):SetRelPos((90 - w - 10)/2, 4)
	local HandleProgress = LR.AppendUI("Handle", HandleRole, sformat("HandleProgress%d", data.dwID), {x = 0, y = 30, w = 120, h = 30, eventid = 0})
	local HandleProgress2 = LR.AppendUI("Handle", HandleProgress, sformat("HandleProgress2%d", data.dwID), {x = 0, y = 0, w = 120, h = 30, eventid = 0})
	HandleProgress2:SetHandleStyle(3)
	if LR_CDRP.dwProgressID == 0 then
		local tBossList = Table_GetCDProcessBoss and Table_GetCDProcessBoss(dwMapID) or {}
		tsort(tBossList, function(a, b)
			return a["dwProgressID"] < b["dwProgressID"]
		end)
		for k2, v2 in pairs(tBossList) do
			LR_CDRP.LoadText(HandleProgress2, data, v2, 1)
		end
	else
		local v2 = Table_GetBoss(dwMapID, LR_CDRP.dwProgressID)
		LR_CDRP.LoadText(HandleProgress2, data, v2, 2)
		if GetDungeonRoleProgress(dwMapID, data.dwID, LR_CDRP.dwProgressID) then
			Shadow:SetColorRGB(255, 0, 0):SetAlpha(255):Show()
		end
	end
	HandleProgress2:FormatAllItemPos():SetSizeByAllItemSize()
	local w2, h2 = HandleProgress2:GetSize()
	HandleProgress2:SetRelPos((120 - w2)/2, (30 - h2)/2 )
	HandleProgress:FormatAllItemPos()

	HandleRole.OnClick = function()
		if IsCtrlKeyDown() then
			LR.EditBox_AppendLinkPlayer(data.szName)
		end
	end
	HandleRole.OnRClick = function()
		--Output(data.szName, data.dwID, dwMapID, GetDungeonRoleProgress(dwMapID, data.dwID, 1))
	end

end

function LR_CDRP.LoadText(parent, player, data, showtype)
	local TextProgress
	local dwMapID = LR_CDRP.dwMapID
	if GetDungeonRoleProgress(dwMapID, player.dwID, data.dwProgressID) then
		if showtype == 1 then
			TextProgress = LR.AppendUI("Text", parent, sformat("T_%d_%d_%d", player.dwID, dwMapID, data.dwProgressID), {x = 30, y = 0, w = 90, h = 30, text = _L["<SYMBOL_DONE>"]})
			TextProgress:SetFontScheme(2):SetFontColor(255, 255, 255)
		else
			TextProgress = LR.AppendUI("Text", parent, sformat("T_%d_%d_%d", player.dwID, dwMapID, data.dwProgressID), {x = 30, y = 0, w = 90, h = 30, text = _L["Killed"]})
			TextProgress:SetFontScheme(2):SetFontColor(255, 0, 0)
		end
	else
		if showtype == 1 then
			TextProgress = LR.AppendUI("Text", parent, sformat("T_%d_%d_%d", player.dwID, dwMapID, data.dwProgressID), {x = 30, y = 0, w = 90, h = 30, text = _L["<SYMBOL_NOT>"]})
			TextProgress:SetFontScheme(2):SetFontColor(255, 255, 255)
		else
			TextProgress = LR.AppendUI("Text", parent, sformat("T_%d_%d_%d", player.dwID, dwMapID, data.dwProgressID), {x = 30, y = 0, w = 90, h = 30, text = _L["Waiting for kill"]})
			TextProgress:SetFontScheme(2):SetFontColor(255, 255, 255)
		end
	end
	TextProgress:SetVAlign(1):SetHAlign(1):RegisterEvent(256)
	TextProgress:GetSelf().OnItemMouseEnter = function()
		local x, y = parent:GetParent():GetParent():GetAbsPos()
		local szXml = {}
		local status, r, g, b = _L["Killed"], 255, 0, 0
		ApplyDungeonRoleProgress(dwMapID, player.dwID)
		if not GetDungeonRoleProgress(dwMapID, player.dwID, data.dwProgressID) then
			status, r, g, b = _L["Waiting for kill"], 34, 177, 76
		end
		local szPath, nFrame = GetForceImage(player.dwForceID)
		local r2, g2, b2 = LR.GetMenPaiColor(player.dwForceID)
		szXml[#szXml + 1] = GetFormatImage(szPath, nFrame, 24, 24)
		szXml[#szXml + 1] = GetFormatText(sformat("%s\n", player.szName), nil, r2, g2, b2)
		szXml[#szXml + 1] = GetFormatText(sformat("%d.%s\n", data.dwProgressID, data.szName))
		szXml[#szXml + 1] = GetFormatText(status, nil, r, g, b)
		OutputTip(tconcat(szXml), 420, {x, y, 120, 75})
	end
	TextProgress:GetSelf().OnItemMouseLeave = function()
		HideTip()
	end
end

function LR_CDRP.AutoSize()
	local Frame = UI["Frame"]
	local WndBody = UI["WndBody"]
	local HandleBody = UI["HandleBody"]
	local w, h = HandleBody:GetSize()
	WndBody:SetSize(w, h)

	local WndTitle = Frame:Lookup("Wnd_Title")
	local Handle_Title = WndTitle:Lookup("","")
	local Text_Title = Handle_Title:Lookup("Text_Title")
	local w1, h1 = Text_Title:GetSize()
	local w3 = mmax(60 + w1, w)
	WndTitle:SetSize(w3, 30)
	Frame:SetSize(w3, h + 30)
	Handle_Title:SetSize(w3, 30)
	local Image_TitleBg = Handle_Title:Lookup("Image_TitleBg")
	Image_TitleBg:SetSize(w3, 30)

	Frame:SetDragArea(0, 0, w3, 30)
	local Btn_Close = WndTitle:Lookup("Btn_Close")
	Btn_Close:SetRelPos(w3 - 30, 3)
end
