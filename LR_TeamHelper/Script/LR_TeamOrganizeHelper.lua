local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local VERSION = "20190625"
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_TeamHelper"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_TeamHelper"
local _L = LR.LoadLangPack(AddonPath)
---------------------------------------------------------------
local ROLETYPE_TEXT = {
	[1] = _L["ChengNan"],
	[2] = _L["ChengNv"],
	[5] = _L["ZhengTai"],
	[6] = _L["Loli"],
}
local FULL_LEVEL = 100
---------------------------------------------------------------
local REQUEST_LIST = {
	--["华契"] = {szName = "华契", dwForceID = 1, nLevel = 95, nCamp = 2, nTime = GetTickCount(), nType = "INVITE"}
}	--存放组队申请列表
local _ui = {}
---------------------------------------------------------------
LR_TeamRequest = {}
LR_TeamRequest.UsrData = {
	bOn = false,
	auto_action = {
		Auto_Refuse_Unfull_Level = false,	--拒绝未满级的(好友除外)
		Auto_Refuse_GZS = false,	--拒绝疑似工作室
		Auto_Allow_Friend = false,		--自动通过好友
		Auto_Allow_Same_Tong = false,	--自动通过同帮会
	},
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

	LR.DelayCall(100, function()
		local MY_PartyRequest = Station.Lookup("Normal2/MY_PartyRequest")
		if MY_PartyRequest then
			local msg = {
				szMessage = _L["Please close MY_PartyRequest"],
				szName = "Refuse all",
				fnAutoClose = function() return false end,
				{szOption = _L["Yes"], fnAction = function()  end, },
			}
			MessageBox(msg)
		end
	end)

	if not frame then
		return
	end

	if not REQUEST_LIST[data.szName] then
		REQUEST_LIST[data.szName] = clone(data)
		LR.Role_Code.LoadDB(data)
		local bHave, role = LR.Role_Code.CheckExist(data)
		if bHave then
			REQUEST_LIST[data.szName].szKey = role.szKey
			REQUEST_LIST[data.szName].role_code = role.role_code
		end
	end

	frame.fnAutoClose = nil
	frame.fnCancelAction = nil
	frame.szCloseSound = nil
	Wnd.CloseWindow(frame)

	if LR_TeamRequest.UsrData.auto_action.Auto_Allow_Friend then
		if LR.Friend.IsFriend(data.szName) then
			LR_TeamRequest.Request(data.szName, 1)
			return
		end
	end
	if LR_TeamRequest.UsrData.auto_action.Auto_Allow_Same_Tong then
		if LR.Tong.IsTongMember(data.szName) then
			LR_TeamRequest.Request(data.szName, 1)
			return
		end
	end
	if LR_TeamRequest.UsrData.auto_action.Auto_Refuse_Unfull_Level then
		if not LR.Friend.IsFriend(data.szName) and data.nLevel < FULL_LEVEL then
			LR_TeamRequest.Request(data.szName, 0)
			return
		end
	end

	LR_TeamRequestPanel.OpenPanel()
	LR.BgTalk(data.szName, "LR_TeamRequest", "ASK")
end

function LR_TeamRequest.Request(szName, action)
	if REQUEST_LIST[szName] then
		local data = clone(REQUEST_LIST[szName])
		local WndWindow = _ui[sformat("WndWindow_%s", data.szName)]
		if WndWindow then
			_ui[sformat("WndWindow_%s", data.szName)] = nil
			_ui[sformat("Image_Hover_%s", data.szName)] = nil
			_ui[sformat("Btn_Refuse_%s", data.szName)] = nil
			_ui[sformat("Image_Kungfu_%s", data.szName)] = nil
			_ui[sformat("Image_GongZhan_%s", data.szName)] = nil
			WndWindow:Destroy()
			LR_TeamRequestPanel.ReSize()
		end
		--
		if data.nType == "INVITE" then
			GetClientTeam().RespondTeamInvite(data.szName, action)
		elseif data.nType == "APPLY" then
			GetClientTeam().RespondTeamApply(data.szName, action)
		end
		--
		REQUEST_LIST[szName] = nil
	end
end

function LR_TeamRequest.OptionMenu(menu)
	local szKey = {"Auto_Refuse_Unfull_Level", "Auto_Allow_Friend", "Auto_Allow_Same_Tong"}
	local szText = {_L["Auto refuse unfull lever player"], _L["Auto allow friend to get in party"], _L["Auto allow tong member to get in party"]}
	for k, v in pairs(szKey) do
		menu[#menu + 1] = {szOption = szText[k], bCheck = true, bMCheck = false, bChecked = function() return LR_TeamRequest.UsrData.auto_action[v] end,
			fnAction = function()
				LR_TeamRequest.UsrData.auto_action[v] = not LR_TeamRequest.UsrData.auto_action[v]
			end
		}
	end
end

function LR_TeamRequest.GetSystemDB()
	OpenBrowser("https://m.weibo.cn/detail/4387419950208972")
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
				end
				LR_TeamRequestPanel.ClosePanel()
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
	elseif szName == "Btn_Setting" then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local menu = {}
		menu[#menu + 1] = {szOption = _L["Option"], fnAction = function() LR_TOOLS:OpenPanel(_L["LR TeamHelper"]) end}
		menu[#menu + 1] = {bDevide = true}
		LR_TeamRequest.OptionMenu(menu)
		menu[#menu + 1] = {bDevide = true}
		menu[#menu + 1] = {szOption = _L["Get black list data"], fnAction = function() LR_TeamRequest.GetSystemDB() end}

		PopupMenu(menu, {x, y, w, h})
	end
end

function LR_TeamRequestPanel.OnMouseEnter()
	local szName = this:GetName()
	if szName == "Btn_Setting" then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local tTip = {}
		tTip[#tTip + 1] = GetFormatText(sformat("%s\n", _L["Instructions:"]))
		--
		tTip[#tTip + 1] = GetFormatImage("UI/Image/GMPanel/gm2.uitex", 7, 24, 24)
		tTip[#tTip + 1] = GetFormatText(sformat("%s\n", _L["LR Plugin installed."]))
		--
		tTip[#tTip + 1] = GetFormatImage("UI/Image/GMPanel/gm2.uitex", 9, 24, 24)
		tTip[#tTip + 1] = GetFormatText(sformat("%s\n", _L["LR Plugin not installed."]))
		--
		tTip[#tTip + 1] = GetFormatImage("UI/Image/GMPanel/gm2.uitex", 6, 24, 24)
		tTip[#tTip + 1] = GetFormatText(sformat("%s\n", _L["Be in black list."]))

		OutputTip(tconcat(tTip), 320, {x, y, w, h})
	end
end

function LR_TeamRequestPanel.OnMouseLeave()
	local szName = this:GetName()
	if szName == "Btn_Setting" then
		HideTip()
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
	_ui["WndContainer"] = LR.AppendUI("WndContainer", frame, "WndContainer", {x = 0, y = 30, w = 550, h = 100})
	_ui["WinBlack"] = LR.AppendUI("Window", frame, "WinBlack", {x = 0, y = 30, w = 550, h = 100})
	_ui["WndBlackContainer"] = LR.AppendUI("WndContainer", _ui["WinBlack"], "WndBlackContainer", {x = 0, y = 30, w = 550, h = 100})
	--
	local image = LR.AppendUI("Image", _ui["WinBlack"], "Image_Text", {x = 0, y = 0, w = 100, h = 30})
	image:FromUITex("UI/image/Helper/help--bg.Uitex", 6)
	local Text = LR.AppendUI("Text", _ui["WinBlack"], "Text_Black", {x = 10, y = 0, w = 100, h = 30, text = _L["Black list"]})
	Text:SetFontScheme(235)

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

	if _ui["WndContainer"]:GetAllContentCount() == 0 and _ui["WndBlackContainer"]:GetAllContentCount() == 0 then
		LR_TeamRequestPanel.ClosePanel()
	else
		--
		local num1 = _ui["WndContainer"]:GetAllContentCount()
		local h1 = num1 * 50 + 2
		_ui["WndContainer"]:SetSize(600, h1)
		_ui["WndContainer"]:FormatAllContentPos()
		--
		local num2, h3 = _ui["WndBlackContainer"]:GetAllContentCount(), 0
		if num2 > 0 then
			local h2 = num2 * 50 + 2
			h3 = h2 + 30
			_ui["WinBlack"]:SetRelPos(0, 30 + h1)
			_ui["WinBlack"]:SetSize(600, h3)
			_ui["WndBlackContainer"]:SetSize(600, h2)
			_ui["WndBlackContainer"]:FormatAllContentPos()
			--
			local handle = frame:Lookup("WinBlack"):Lookup("","")
			handle:Show()
		else
			_ui["WndBlackContainer"]:SetSize(600, 0)
			_ui["WndBlackContainer"]:FormatAllContentPos()
			--
			_ui["WinBlack"]:SetRelPos(0, 30 + h1)
			_ui["WinBlack"]:SetSize(600, h3)

			local handle = frame:Lookup("WinBlack"):Lookup("","")
			handle:Hide()
		end

		_ui["frame"]:Lookup("",""):Lookup("Image_Bg"):SetSize(600, h1 + h3 + 32)
		_ui["frame"]:SetSize(600, h1 + h3 + 32)
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
		local WndWindow = LR.AppendUI("Window", _ui["WndContainer"], sformat("WndWindow_%s", data.szName), {w = 600, h = 50})
		--
		local Image_Bg = LR.AppendUI("Image", WndWindow, "Image_Bg", { x = 0, y = 0, w = 600, h = 50})
		Image_Bg:FromUITex("ui/Image/UICommon/CommonPanel.UITex", 48):SetImageType(10)
		--image
		local Image_Status = LR.AppendUI("Image", WndWindow, sformat("Image_Status_%s", data.szName), { x = 10, y = 10, w = 30, h = 30})
		Image_Status:FromUITex("UI/Image/GMPanel/gm2.uitex", 9)

		local Image_Kungfu = LR.AppendUI("Image", WndWindow, sformat("Image_Kungfu_%s", data.szName), { x = 45, y = 10, w = 30, h = 30})
		Image_Kungfu:FromUITex(GetForceImage(data.dwForceID))

		local Text_Name = LR.AppendUI("Text", WndWindow, "Text_Name", {x = 80, y = 5, w = 95, h = 40})
		Text_Name:SetVAlign(1):SetHAlign(0):SetFontScheme(2):SetText(sformat("%s (%d)", data.szName, data.nLevel)):SetFontColor(LR.GetMenPaiColor(data.dwForceID))

		local Image_GongZhan = LR.AppendUI("Image", WndWindow, sformat("Image_GongZhan_%s", data.szName), { x = 270, y = 10, w = 30, h = 30})
		Image_GongZhan:FromIconID(Table_GetBuffIconID(3219, 1)):Hide()

		local Image_Camp = LR.AppendUI("Image", WndWindow, "Image_Camp", { x = 310, y = 10, w = 30, h = 30})
		Image_Camp:FromUITex(LR.GetCampImage(data.nCamp))

		local Btn_View = LR.AppendUI("Button", WndWindow, sformat("Btn_View_%s", data.szName), {x = 350, y = 5, w = 80, h = 40, text = g_tStrings.STR_LOOKUP})
		Btn_View:Enable(false)
		local Btn_Apply = LR.AppendUI("Button", WndWindow, "Btn_Apply", {x = 435, y = 5, w = 70, h = 40, text = g_tStrings.STR_ACCEPT})
		local Btn_Refuse = LR.AppendUI("Button", WndWindow, sformat("Btn_Refuse_%s", data.szName), {x = 510, y = 5, w = 80, h = 40, text = sformat("%s(%d)", g_tStrings.STR_REFUSE, 120)})

		local Image_Hover = LR.AppendUI("Image", WndWindow, sformat("Image_Hover_%s", data.szName), { x = 0, y = 0, w = 600, h = 50})
		Image_Hover:FromUITex("ui/Image/Common/Box.UITex", 10):SetImageType(10):Hide()

		_ui[sformat("WndWindow_%s", data.szName)] = WndWindow
		_ui[sformat("Image_Hover_%s", data.szName)] = Image_Hover
		_ui[sformat("Btn_Refuse_%s", data.szName)] = Btn_Refuse
		_ui[sformat("Image_Kungfu_%s", data.szName)] = Image_Kungfu
		_ui[sformat("Image_GongZhan_%s", data.szName)] = Image_GongZhan
		_ui[sformat("Btn_View_%s", data.szName)] = Btn_View
		_ui[sformat("Image_Status_%s", data.szName)] = Image_Status

		Btn_View.OnEnter = function()
			if _ui[sformat("Image_Hover_%s", data.szName)] then
				_ui[sformat("Image_Hover_%s", data.szName)]:Show()
			end
		end
		Btn_View.OnLeave = function()
			if _ui[sformat("Image_Hover_%s", data.szName)] then
				_ui[sformat("Image_Hover_%s", data.szName)]:Hide()
			end
		end
		Btn_View.OnClick = function()
			if data.dwID then
				LR.GetEquipmentMenu(data.dwID)[1].fnAction()
			end
		end

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
			if IsCtrlKeyDown() then
				if REQUEST_LIST[data.szName] then
					LR_TeamRequest.Request(data.szName, 1)
				end
			else
				local v = REQUEST_LIST[data.szName] or {}
				local bInBlackList, nType, tList = LR_Black_List.IsTargetInBlackList(v)
				if bInBlackList then
					local msg = {
						szMessage = _L["In black list, plese hold ctrl to click."],
						szName = "black list",
						fnAutoClose = function() return false end,
						{szOption = g_tStrings.STR_HOTKEY_SURE,
							fnAction = function()

							end,
						},
					}
					MessageBox(msg)
				else
					if REQUEST_LIST[data.szName] then
						LR_TeamRequest.Request(data.szName, 1)
					end
				end
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
			local v = REQUEST_LIST[data.szName] or {}
			local tTips = {}
			if not v.dwID then
				tTips[#tTips + 1] = GetFormatText(_L["This player has not installed LR_Plugin, be careful.\n"], 24)
			end
			local bInBlackList, nType, tList = LR_Black_List.IsTargetInBlackList(v)
			if bInBlackList then
				local function _list(tip, tList)
					for k2, v2 in pairs(tList) do
						local info = LR_Black_List.GetInfo(v2)
						tip[#tip + 1] = GetFormatText("---------")
						local szPath, nFrame = GetForceImage(info.dwForceID)
						tip[#tip + 1] = GetFormatImage(szPath, nFrame, 24, 24)
						tip[#tip + 1] = GetFormatText(sformat(_L["%s\n"], info.szName), 28)
						tip[#tip + 1] = GetFormatText(sformat(_L["Server: %s_%s\n"], info.area, info.server), 28)
						tip[#tip + 1] = GetFormatText(sformat(_L["ID: %d\n"], info.dwID), 28)
						tip[#tip + 1] = GetFormatText(sformat(_L["Role type: %s\n"], ROLETYPE_TEXT[info.role_type]), 28)
						tip[#tip + 1] = GetFormatText(sformat(_L["Cheat_style: %s\n"], info.cheat_style), 28)
						tip[#tip + 1] = GetFormatText(sformat(_L["Details: %s\n"], info.remarks), 28)
						tip[#tip + 1] = GetFormatText(sformat(_L["Link: %s\n"], info.detail_link), 28)
						local _t1 = _L["Have not yet."]
						if info.role_code ~= "" then
							_t1 = info.role_code
						end
						tip[#tip + 1] = GetFormatText(sformat(_L["User code: %s\n"], _t1), 28)
						if info.role_code == "" and nType == 1 then
							tTips[#tTips + 1] = GetFormatText(_L["This player is lack of user_code, if you have the user_code of this player, please give it to me.\n"], 24)
							local bHave, role = LR.Role_Code.CheckExist(info)
							if bHave then
								tTips[#tTips + 1] = GetFormatText(_L["You have the code of this player, please give it to me. Right click to choose 'hand it up'"], 235)
							end
						end
					end
				end
				if nType == 1 then
					tTips[#tTips + 1] = GetFormatText(_L["This player is in system black list.\n"], 235)
					--
					_list(tTips, tList)
				elseif nType == 2 then
					local tName = {}
					for k2, v2 in pairs(tList) do
						tinsert(tName, v2.szName)
					end
					tTips[#tTips + 1] = GetFormatText(sformat(_L["This player has the same account with player %s .\n"], tconcat(tName, ",")), 235)
					--
					_list(tTips, tList)
				elseif nType == 3 then
					tTips[#tTips + 1] = GetFormatText(_L["This player is in custom black list.\n"], 235)
				end
			end
			if #tTips > 0 then
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				OutputTip(tconcat(tTips), 320, {x, y, w, h})
			end
		end
		WndWindow:GetSelf().OnMouseLeave = function()
			if _ui[sformat("Image_Hover_%s", data.szName)] then
				_ui[sformat("Image_Hover_%s", data.szName)]:Hide()
			end
			HideTip()
		end
		WndWindow:GetSelf().OnLButtonClick = function()
			if IsCtrlKeyDown() then
				LR.EditBox_AppendLinkPlayer(data.szName)
			end
		end
		WndWindow:GetSelf().OnRButtonClick = function()
			local menu = {}
			if data.dwID then
				local dwID = data.dwID
				InsertPlayerCommonMenu(menu, data.dwID, data.szName)
				menu[#menu + 1] = {bDevide = true,}
				menu[#menu + 1] = LR.GetEquipmentMenu(dwID)[1]
				menu[#menu + 1] = {szOption=_L["Check Attribute"], fnAction = function() LR.ViewCharInfoToPlayer(dwID) end,}
			else
				menu[#menu + 1] = {szOption = g_tStrings.STR_SAY_SECRET, fnAction = function() LR.SwitchChat(data.szName) end}
				menu[#menu + 1] = {szOption = g_tStrings.STR_MAKE_FRIEND, fnAction = function() GetClientPlayer().AddFellowship(data.szName) end}
			end
			local v = REQUEST_LIST[data.szName] or {}
			local bInBlackList, nType, tList = LR_Black_List.IsTargetInBlackList(v)
			if bInBlackList then
				local info = LR_Black_List.GetInfo(v)
				if info.role_code == "" and nType == 1 then
					local bHave, role = LR.Role_Code.CheckExist(info)
					if bHave then
						menu[#menu + 1] = {bDevide = true,}
						menu[#menu + 1] = {szOption=_L["Black List"], fnDisable = function() return true end,}
						menu[#menu + 1] = {szOption=_L["Hand it up"],
							fnAction = function()
								local v3 = clone(v)
								local ServerInfo = {GetUserServer()}
								local realArea, realServer = ServerInfo[5], ServerInfo[6]
								v3.role_code = role.role_code
								v3.area = realArea
								v3.server = realServer
								LR_Black_List.ReportP(v3)
							end,}
					end
				end
			end
			local fx, fy = Cursor.GetPos()
			PopupMenu(menu, {fx, fy, 0, 0})
		end

		if LR_Black_List.IsTargetInBlackList(data) then
			LR_TeamRequest.ChangeToBlackWindow(data)
		end
		LR_TeamRequestPanel.ReSize()
	end
end

function LR_TeamRequest.ChangeToBlackWindow(data)
	local frame = Station.Lookup("Normal1/LR_TeamRequestPanel")
	if not frame then
		return
	end
	if not _ui[sformat("WndWindow_%s", data.szName)] then
		return
	end
	local WndWindow = _ui[sformat("WndWindow_%s", data.szName)]
	local WndBlackContainer = _ui["WndBlackContainer"]
	WndWindow:ChangeRelation(WndBlackContainer, true, true)
	_ui[sformat("WndWindow_%s", data.szName)] = WndWindow

	--
	local bInBlackList, nType, tList = LR_Black_List.IsTargetInBlackList(REQUEST_LIST[data.szName])
	if bInBlackList then
		_ui[sformat("Image_Status_%s", data.szName)]:FromUITex("UI/Image/GMPanel/gm2.uitex", 6)
	end
	--
	LR_TeamRequestPanel.ReSize()
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
	if data[1] == "ANSWER" then
		local v = data[2]
		if REQUEST_LIST[v.szName] then
			REQUEST_LIST[v.szName].dwID = v.dwID
			REQUEST_LIST[v.szName].dwKungfuID = v.dwKungfuID
			REQUEST_LIST[v.szName].bGongZhan = v.bGongZhan
			REQUEST_LIST[v.szName].role_code = v.uc
			REQUEST_LIST[v.szName].role_type = v.rt

			if _ui[sformat("Image_Kungfu_%s", v.szName)] then
				_ui[sformat("Image_Kungfu_%s", v.szName)]:FromIconID(Table_GetSkillIconID(v.dwKungfuID, 1))
			end
			if _ui[sformat("Image_GongZhan_%s", v.szName)] then
				if v.bGongZhan then
					_ui[sformat("Image_GongZhan_%s", v.szName)]:Show()
				end
			end
			if _ui[sformat("Btn_View_%s", v.szName)] then
				_ui[sformat("Btn_View_%s", v.szName)]:Enable(true)
			end

			if _ui[sformat("Image_Status_%s", v.szName)] then
				_ui[sformat("Image_Status_%s", v.szName)]:FromUITex("UI/Image/GMPanel/gm2.uitex", 7)
			end

			--黑名单检测
			local ServerInfo = {GetUserServer()}
			local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
			local szKey = sformat("%s_%s_%d", realArea, realServer, v.dwID)
			REQUEST_LIST[v.szName].szKey = szKey
			--
			local bInBlackList, nType, tList = LR_Black_List.IsTargetInBlackList(REQUEST_LIST[v.szName])
			if bInBlackList then
				LR_TeamRequest.ChangeToBlackWindow(REQUEST_LIST[v.szName])
				--_ui[sformat("Image_Status_%s", v.szName)]:FromUITex("UI/Image/GMPanel/gm2.uitex", 6)
			end
		end
	end
end

LR.RegisterEvent("PARTY_INVITE_REQUEST", function() LR_TeamRequest.PARTY_INVITE_REQUEST() end)
LR.RegisterEvent("PARTY_APPLY_REQUEST", function() LR_TeamRequest.PARTY_APPLY_REQUEST() end)
LR.RegisterEvent("ON_BG_CHANNEL_MSG", function() LR_TeamRequest.ON_BG_CHANNEL_MSG() end)
