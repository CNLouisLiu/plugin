local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local VERSION = "20180131"
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_TeamHelper"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_TeamHelper"
local _L = LR.LoadLangPack(AddonPath)
---------------------------------------------------------------
local REQUEST_LIST = {
	--["华契"] = {szName = "华契", dwForceID = 1, nLevel = 95, nCamp = 2, nTime = GetTickCount(), nType = "INVITE"}
}	--存放组队申请列表
local _ui = {}
---------------------------------------------------------------
LR_TeamRequest = {}
LR_TeamRequest.UsrData = {
	bOn = false,
}
RegisterCustomData("LR_TeamRequest.UsrData", VERSION)

function LR_TeamRequest.CloseBox(data)
	if not LR_TeamRequest.UsrData.bOn then
		return
	end
	local frame
	if data.nType == "INVITE" then
		frame = Station.Lookup("Topmost/MB_IMTP_" .. data.szName)
	elseif data.nType == "APPLY" then
		frame = Station.Lookup("Topmost/MB_ATMP_" .. data.szName)
	end
	if not frame then
		return
	end

	if not REQUEST_LIST[data.szName] then
		REQUEST_LIST[data.szName] = clone(data)
	end
	LR.BgTalk(data.szName, "LR_TeamRequest", "ASK")

	frame.fnAutoClose = nil
	frame.fnCancelAction = nil
	frame.szCloseSound = nil
	Wnd.CloseWindow(frame)
	LR_TeamRequestPanel.OpenPanel()
end

function LR_TeamRequest.Request(szName, action)
	if REQUEST_LIST[szName] then
		local data = REQUEST_LIST[szName]
		local WndWindow = _ui[sformat("WndWindow_%s", data.szName)]
		_ui[sformat("WndWindow_%s", data.szName)] = nil
		_ui[sformat("Image_Hover_%s", data.szName)] = nil
		_ui[sformat("Btn_Refuse_%s", data.szName)] = nil
		_ui[sformat("Image_Kungfu_%s", data.szName)] = nil
		_ui[sformat("Image_GongZhan_%s", data.szName)] = nil
		WndWindow:Destroy()
		if data.nType == "INVITE" then
			GetClientTeam().RespondTeamInvite(data.szName, action)
		elseif data.nType == "APPLY" then
			GetClientTeam().RespondTeamApply(data.szName, action)
		end

		LR_TeamRequestPanel.ReSize()
		REQUEST_LIST[szName] = nil
	end
end

---------------------------------------------
---界面
---------------------------------------------
LR_TeamRequestPanel = {}
function LR_TeamRequestPanel.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")

	LR_TeamRequestPanel.UpdateAnchor(this)
end

function LR_TeamRequestPanel.OnFrameDestroy()
	_ui = {}
end

function LR_TeamRequestPanel.OnFrameBreathe()
	for k, v in pairs(REQUEST_LIST) do
		if GetTickCount() - v.nTime > 1000 * 60 * 2 then
			LR_TeamRequest.Request(v.szName, 0)
		else
			if _ui[sformat("Btn_Refuse_%s", v.szName)] then
				_ui[sformat("Btn_Refuse_%s", v.szName)]:SetText(sformat("%s(%d)", g_tStrings.STR_REFUSE, mfloor( 120 - (GetTickCount() - v.nTime) / 1000 )))
			end
		end
	end
end

function LR_TeamRequestPanel.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Close" then
		if _ui["WndContainer"]:GetAllContentCount() == 0 then
			LR_TeamRequestPanel.ClosePanel()
		else
			local fnAction = function()
				for k, v in pairs(REQUEST_LIST) do
					LR_TeamRequest.Request(k, 0)
					LR_TeamRequestPanel.ClosePanel()
				end
			end

			local msg = {
				szMessage = _L["Refuse all?"],
				szName = "Refuse all",
				fnAutoClose = function() return false end,
				{szOption = _L["Yes"], fnAction = function() fnAction() end, },
				{szOption = _L["Cancel"], fnAction = function()  end,},
			}
			MessageBox(msg)
		end
	end
end

function LR_TeamRequestPanel.OnEvent(szEvent)
	if szEvent == "UI_SCALED" then
		LR_TeamRequestPanel.UpdateAnchor(this)
	end
end

function LR_TeamRequestPanel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint("CENTER", 0, 0, "CENTER", 0, -240)
end

function LR_TeamRequestPanel.ini()
	local frame = LR.AppendUI("Frame", "LR_TeamRequestPanel", {title = _L["Team request"], path = sformat("%s\\UI\\LR_TeamRequestPanel.ini", AddonPath)})

	_ui = {}
	_ui["WndContainer"] = LR.AppendUI("WndContainer", frame, "WndContainer", {x = 0, y = 30, w = 470, h = 100})
	_ui["frame"] = frame

	LR_TeamRequestPanel.LoadQuest()
end

function LR_TeamRequestPanel.OpenPanel()
	local frame = Station.Lookup("Normal1/LR_TeamRequestPanel")
	if not frame then
		LR_TeamRequestPanel.ini()
		LR_TeamRequestPanel.LoadQuest()
	else
		LR_TeamRequestPanel.LoadQuest()
	end
end

function LR_TeamRequestPanel.ClosePanel()
	local frame = Station.Lookup("Normal1/LR_TeamRequestPanel")
	if frame then
		Wnd.CloseWindow(frame)
	end
end

function LR_TeamRequestPanel.ReSize()
	local frame = Station.Lookup("Normal1/LR_TeamRequestPanel")
	if not frame then
		return
	end

	if _ui["WndContainer"]:GetAllContentCount() == 0 then
		LR_TeamRequestPanel.ClosePanel()
	else
		_ui["WndContainer"]:SetSize(470, _ui["WndContainer"]:GetAllContentCount() * 40 + 2)
		_ui["WndContainer"]:FormatAllContentPos()
		_ui["frame"]:Lookup("",""):Lookup("Image_Bg"):SetSize(470, _ui["WndContainer"]:GetAllContentCount() * 40 + 32)
		_ui["frame"]:SetSize(470, _ui["WndContainer"]:GetAllContentCount() * 40 + 32)
	end
end

function LR_TeamRequestPanel.LoadQuest()
	for k, v in pairs(REQUEST_LIST) do
		LR_TeamRequestPanel.LoadOneQuest(v)
	end
end

function LR_TeamRequestPanel.LoadOneQuest(data)
	local frame = Station.Lookup("Normal1/LR_TeamRequestPanel")
	if not frame then
		return
	end
	if not _ui[sformat("WndWindow_%s", data.szName)] then
		local WndWindow = LR.AppendUI("Window", _ui["WndContainer"], sformat("WndWindow_%s", data.szName), {w = 470, h = 40})

		local Image_Bg = LR.AppendUI("Image", WndWindow, "Image_Bg", { x = 0, y = 0, w = 470, h = 40})
		Image_Bg:FromUITex("ui/Image/UICommon/CommonPanel.UITex", 48):SetImageType(10)

		local Image_Kungfu = LR.AppendUI("Image", WndWindow, sformat("Image_Kungfu_%s", data.szName), { x = 10, y = 5, w = 30, h = 30})
		Image_Kungfu:FromUITex(GetForceImage(data.dwForceID))

		local Text_Name = LR.AppendUI("Text", WndWindow, "Text_Name", {x = 45, y = 5, w = 100, h = 30})
		Text_Name:SetVAlign(1):SetHAlign(0):SetFontScheme(2):SetText(sformat("%s (%d)", data.szName, data.nLevel)):SetFontColor(LR.GetMenPaiColor(data.dwForceID))

		local Image_GongZhan = LR.AppendUI("Image", WndWindow, sformat("Image_GongZhan_%s", data.szName), { x = 225, y = 5, w = 30, h = 30})
		Image_GongZhan:FromIconID(Table_GetBuffIconID(3219, 1)):Hide()

		local Image_Camp = LR.AppendUI("Image", WndWindow, "Image_Camp", { x = 265, y = 5, w = 30, h = 30})
		Image_Camp:FromUITex(LR.GetCampImage(data.nCamp))

		local Btn_Apply = LR.AppendUI("Button", WndWindow, "Btn_Apply", {x = 305, y = 5, w = 70, h = 30, text = g_tStrings.STR_ACCEPT})

		local Btn_Refuse = LR.AppendUI("Button", WndWindow, sformat("Btn_Refuse_%s", data.szName), {x = 385, y = 5, w = 70, h = 30, text = sformat("%s(%d)", g_tStrings.STR_REFUSE, 120)})

		local Image_Hover = LR.AppendUI("Image", WndWindow, sformat("Image_Hover_%s", data.szName), { x = 0, y = 0, w = 470, h = 40})
		Image_Hover:FromUITex("ui/Image/Common/Box.UITex", 10):SetImageType(10):Hide()

		_ui[sformat("WndWindow_%s", data.szName)] = WndWindow
		_ui[sformat("Image_Hover_%s", data.szName)] = Image_Hover
		_ui[sformat("Btn_Refuse_%s", data.szName)] = Btn_Refuse
		_ui[sformat("Image_Kungfu_%s", data.szName)] = Image_Kungfu
		_ui[sformat("Image_GongZhan_%s", data.szName)] = Image_GongZhan

		Btn_Apply.OnEnter = function()
			if _ui[sformat("Image_Hover_%s", data.szName)] then
				_ui[sformat("Image_Hover_%s", data.szName)]:Show()
			end
		end
		Btn_Apply.OnLeave = function()
			if _ui[sformat("Image_Hover_%s", data.szName)] then
				_ui[sformat("Image_Hover_%s", data.szName)]:Hide()
			end
		end
		Btn_Apply.OnClick = function()
			if REQUEST_LIST[data.szName] then
				LR_TeamRequest.Request(data.szName, 1)
			end
		end

		Btn_Refuse.OnEnter = function()
			if _ui[sformat("Image_Hover_%s", data.szName)] then
				_ui[sformat("Image_Hover_%s", data.szName)]:Show()
			end
		end
		Btn_Refuse.OnLeave = function()
			if _ui[sformat("Image_Hover_%s", data.szName)] then
				_ui[sformat("Image_Hover_%s", data.szName)]:Hide()
			end
		end
		Btn_Refuse.OnClick = function()
			if REQUEST_LIST[data.szName] then
				LR_TeamRequest.Request(data.szName, 0)
			end
		end

		WndWindow:GetSelf().OnMouseEnter = function()
			if _ui[sformat("Image_Hover_%s", data.szName)] then
				_ui[sformat("Image_Hover_%s", data.szName)]:Show()
			end
		end
		WndWindow:GetSelf().OnMouseLeave = function()
			if _ui[sformat("Image_Hover_%s", data.szName)] then
				_ui[sformat("Image_Hover_%s", data.szName)]:Hide()
			end
		end
		WndWindow:GetSelf().OnLButtonClick = function()
			if IsCtrlKeyDown() then
				EditBox_AppendLinkPlayer(data.szName)
			end
		end
		WndWindow:GetSelf().OnRButtonClick = function()
			if data.dwID then
				local menu = {}
				local dwID = data.dwID
				InsertPlayerCommonMenu(menu, data.dwID, data.szName)
				menu[#menu+1]={bDevide = true,}
				menu[#menu+1]=LR.GetEquipmentMenu(dwID)[1]
				menu[#menu+1]={szOption=_L["Check Attribute"],fnAction=function() LR.ViewCharInfoToPlayer(dwID) end,}

				local fx, fy = Cursor.GetPos()
				PopupMenu(menu, {fx, fy, 0, 0})
			end
		end

		LR_TeamRequestPanel.ReSize()
	end
end

-------------------------------------------
---事件处理
-------------------------------------------
function LR_TeamRequest.PARTY_INVITE_REQUEST()	-----别人邀请你组进他的队伍
	local szName = arg0
	local nCamp = arg1
	local dwForceID = arg2
	local nLevel = arg3

	local data = {szName = szName, nCamp = nCamp, dwForceID = dwForceID, nLevel = nLevel, nTime = GetTickCount(), nType = "INVITE"}
	LR_TeamRequest.CloseBox(data)
end

function LR_TeamRequest.PARTY_APPLY_REQUEST()
	local szName = arg0
	local nCamp = arg1
	local dwForceID = arg2
	local nLevel = arg3

	local data = {szName = szName, nCamp = nCamp, dwForceID = dwForceID, nLevel = nLevel, nTime = GetTickCount(), nType = "APPLY"}
	LR_TeamRequest.CloseBox(data)
end

function LR_TeamRequest.ON_BG_CHANNEL_MSG()
	local szKey = arg0
	local nChannel = arg1
	local dwTalkerID = arg2
	local szTalkerName = arg3
	local data = arg4

	if szKey ~= "LR_TeamRequest" then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	--[[
	if data[1] == "ASK" then
		local t = {szName = me.szName, dwID = me.dwID, dwKungfuID = UI_GetPlayerMountKungfuID(), bGongZhan = LR.HasBuff(LR.GetBuffList(me), 3219)}
		LR.BgTalk(szTalkerName, "LR_TeamRequest", "ANSWER", t)
	else ]]
	if data[1] == "ANSWER" then
		local v = data[2]
		if REQUEST_LIST[v.szName] then
			REQUEST_LIST[v.szName].dwID = v.dwID
			REQUEST_LIST[v.szName].dwKungfuID = v.dwKungfuID
			REQUEST_LIST[v.szName].bGongZhan = v.bGongZhan

			if _ui[sformat("Image_Kungfu_%s", v.szName)] then
				_ui[sformat("Image_Kungfu_%s", v.szName)]:FromIconID(Table_GetSkillIconID(v.dwKungfuID, 1))
			end
			if _ui[sformat("Image_GongZhan_%s", v.szName)] then
				if v.bGongZhan then
					_ui[sformat("Image_GongZhan_%s", v.szName)]:Show()
				end
			end
		end
	end
end

LR.RegisterEvent("PARTY_INVITE_REQUEST", function() LR_TeamRequest.PARTY_INVITE_REQUEST() end)
LR.RegisterEvent("PARTY_APPLY_REQUEST", function() LR_TeamRequest.PARTY_APPLY_REQUEST() end)
LR.RegisterEvent("ON_BG_CHANNEL_MSG", function() LR_TeamRequest.ON_BG_CHANNEL_MSG() end)
