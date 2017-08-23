local AddonPath = "Interface\\LR_Plugin\\LR_1Base"
local _L = LR.LoadLangPack(AddonPath)
local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
-----
LR_TOOLS = CreateAddon("LR_TOOLS")
LR_TOOLS:BindEvent("OnFrameDestroy", "OnDestroy")

LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {
	{"About", _L["About"], "99"},
}

function LR_TOOLS.Check_tAddonClass (szTitle)
	for i = 1, #LR_TOOLS.tAddonClass, 1 do
		if LR_TOOLS.tAddonClass[i][1] ==  szTitle then
			return true
		end
	end
	return false
end

LR_TOOLS.tAddonModules = {}
LR_TOOLS.hLastBtn = nil
LR_TOOLS.hLastWin = nil
LR_TOOLS.SelectBoxName = _L["About"]
LR_TOOLS.Box = nil
LR_TOOLS.Addons = {}

LR_TOOLS.bShowBox = false	---是否显示右下角按钮
LR_TOOLS.NeverShowTongS = false		--是否不再显示帮会按钮
LR_TOOLS.DisableEffect = true	---是否不再显示效果

local CustomVersion = "20170111"
RegisterCustomData("LR_TOOLS.bShowBox", CustomVersion)
RegisterCustomData("LR_TOOLS.NeverShowTongS", CustomVersion)
RegisterCustomData("LR_TOOLS.DisableEffect", "20170426")

function LR_TOOLS:OnCreate()
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("ScaleEnd")
	self:UpdateAnchor(this)

	RegisterGlobalEsc("LR_TOOLS", function () return true end , function() LR_TOOLS:OpenPanel() end)
end

function LR_TOOLS:UpdateAnchor(frame)
	frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
end

function LR_TOOLS:OnEvents(event)
	if event ==  "UI_SCALED" then
		self:UpdateAnchor(this)
	elseif event ==  "ScaleEnd" then
		LR_TOOLS:Init2()

	end
end

function LR_TOOLS.Init2()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local self = LR_TOOLS
	local frame = self:Fetch("LR_TOOLS")
	-- Tab BgImage
	local imgTab = self:Append("Image", frame, "TabImg", {w = 770, h = 33, x = 0, y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)

	local imgSplit = self:Append("Image", frame, "SplitImg", {w = 5, h = 400, x = 188, y = 100})
	imgSplit:SetImage("ui\\Image\\UICommon\\CommonPanel.UITex", 43)

	-- PageSet
	local hPageSet = self:Append("PageSet", frame, "PageSet01"  , {x = 0, y = 50, w = 768, h = 434})
	tsort (self.tAddonClass, function(a, b)
		return a[3] < b[3]
	end)

	local hCheckBox = self:Append("CheckBox", hPageSet, "enter_box", {w = 200, x = 560, y = 2 , text = _L["Enable Bottom-Right Button"] })
	hCheckBox:Check(LR_TOOLS.bShowBox)
	hCheckBox:Enable(true)
	hCheckBox.OnCheck = function(arg0)
		LR_TOOLS.bShowBox = arg0
		hCheckBox:Check(arg0)
		if arg0 then
			LR_TOOLS.Box:Show()
		else
			LR_TOOLS.Box:Hide()
		end
	end

	local Effect = self:Append("CheckBox", frame, "Effect", {w = 200, x = 20, y = 20 , text = _L["Enable Effect"] })
	Effect:Check(not LR_TOOLS.DisableEffect)
	Effect:Enable(true)
	Effect.OnCheck = function(arg0)
		LR_TOOLS.DisableEffect = not arg0
	end

	local Window_Welcome = self:Append("Window", hPageSet, "Window_Welcome" , {w = 530, h = 380, x = 210, y = 50})
	local img_Welcome = self:Append("Image", Window_Welcome, "img_Welcome" , {x = 0, y = 0, w = 520, h = 240, image = "interface\\LR_Plugin\\LR_0UI\\ini\\Welcome.UITex", frame = 0})
	self:Append("Image", Window_Welcome, "img_Welcome" , {x = 0, y = 0, w = 150, h = 150, image = "interface\\LR_Plugin\\LR_0UI\\ini\\Welcome.UITex", frame = 1})
	local text_Welcome = self:Append("Text", Window_Welcome, "text_Welcome" , {w = 760, x = 0, y = 245, h = 60, text  = sformat(_L["Welcome %s to use LR Plugins"], me.szName)  , font  = 236})
	Window_Welcome:Show()
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	if realArea ==  "电信六区" and realServer == "红尘寻梦" then
		local text_tone = self:Append("Text", Window_Welcome, "text_Welcome2" , {w = 515, x = 0, y = 225, h = 20, text  = "电六 大一统\n中恶休闲养老帮会【么么哒萌萌哒】收人\n15神行、帮修、骑马跑商已开\n欢迎各类人士加入", font  = 230})
		text_tone:SetVAlign(2)
		text_tone:SetHAlign(2)
		text_tone:SetMultiLine(true)
		text_tone:Show()
	end

	-----tAddonClass是头顶的页（例如：插件|工具|增强包|关于）
	-----是一个pageset属性
	for i = 1, #self.tAddonClass do
		-- Nav
		local hBtn = self:Append("UICheckBox", hPageSet, sformat("t_TabClass_%s", self.tAddonClass[i][1]), {x = 20 + 80 * ( i- 1), y = 0, w = 80, h = 30, text = self.tAddonClass[i][2], group = "AddonClass"})
		if i ==  1 then
			hBtn:Check(true)
		end

		local hWin = self:Append("Window", hPageSet, sformat("t_Window_%s", self.tAddonClass[i][1]), {x = 0, y = 30, w = 768, h = 400})
		hPageSet:AddPage(hWin:GetSelf(), hBtn:GetSelf())
		hBtn.OnCheck = function(bCheck)
			if bCheck then
				hPageSet:ActivePage(i-1)
			end
 		end

		-- Addon List
		local hScroll = self:Append("Scroll", hWin, sformat("t_Scroll_%s", self.tAddonClass[i][1]), {x = 20, y = 20, w = 180, h = 380})
		local tAddonList = self:GetAddonList(self.tAddonClass[i][1])
		for j = 1, #tAddonList, 1 do
			--Addon Box
			local hBox = self:Append("Handle", hScroll, sformat("tAddonList_hBox_%d_%d", i, j), {w = 160, h = 50, postype = 8})
			self:Append("Image", hBox, sformat("imgBg_%d_%d", i, j), {w = 155, h = 50, image = "ui\\image\\uicommon\\rankingpanel.UITex", frame = 10})

			local imgHover = self:Append("Image", hBox, sformat("tAddonList_imgHover_%d_%d", i, j), {w = 160, h = 50, image = "ui\\image\\uicommon\\rankingpanel.UITex", frame = 11, lockshowhide = 1})
			hBox.imgSel = self:Append("Image", hBox, sformat("tAddonList_imgSel_%d_%d", i, j), {w = 160, h = 50, image = "ui\\image\\uicommon\\rankingpanel.UITex", frame = 11, lockshowhide = 1})

			self:Append("Image", hBox, sformat("tAddonList_imgIcon_%d_%d", i, j), {w = 40, h = 40, x = 5, y = 5}):SetImage(tAddonList[j].dwIcon)
			self:Append("Text", hBox, sformat("tAddonList_txt_%d_%d", i, j), {w = 100, h = 50, x = 55, y = 0, text = tAddonList[j].szTitle})

			local szName = ssub(sformat("tD_Win_%s", tAddonList[j].szName), 1, 30)
			hBox.hWin = hWin
			hBox.tWidget = tAddonList[j].tWidget
			hBox.szName = szName
			hBox.winSel = self:Append("Window", hWin, szName, {w = 530, h = 380, x = 210, y = 20})
			self:AppendAddonInfo(hBox.winSel, tAddonList[j].tWidget)
			hBox.winSel:Hide()

			if LR_TOOLS.SelectBoxName ==   tAddonList[j].szTitle then
				self:Selected(hBox, i, j)
				hPageSet:ActivePage(i-1)
				Window_Welcome:Hide()
				PlaySound(SOUND.UI_SOUND, g_sound.Button)
			end
			hBox.OnEnter = function()
				hBox.bOver = true
				self:UpdateBgStatus(hBox)
			end
			hBox.OnLeave = function()
				hBox.bOver = false
				self:UpdateBgStatus(hBox)
			end
			hBox.OnClick = function()
				self:Selected(hBox, i, #tAddonList)
				Window_Welcome:Hide()
				PlaySound(SOUND.UI_SOUND, g_sound.Button)
			end

			local addon = {hBox = hBox, i = i, j = j, szTitle = tAddonList[j].szTitle, all = #tAddonList}
			LR_TOOLS.Addons[tAddonList[j].szTitle] = addon
		end
		hScroll:UpdateList()
	end

	------插入关于
	LR.AppendAbout(LR_TOOLS, frame)
end

function LR_TOOLS:Init()
	LR_TOOLS.Addons = {}
	local frame = self:Append("Frame", "LR_TOOLS", {title = _L["JX3 LR Plugin"] , style = "NORMAL"})
	frame.ScaleEnd = LR_TOOLS.Init2
end

function LR_TOOLS:Selected(hBox, nS, nTotal)
	for i = 1, nTotal do
		local hI = self:Fetch(sformat("tAddonList_hBox_%d_%d", nS, i))
		if hI.bSel then
			hI.bSel = false
			hI.imgSel:Hide()
			if hI.winSel then
				hI.winSel:Hide()
			end
		end
	end
	hBox.bSel = true
	hBox.winSel:SetAlpha(0)
	hBox.winSel:Show()
	self:UpdateBgStatus(hBox)
	if not LR_TOOLS.DisableEffect then
		local fx, fy = hBox.winSel:GetRelPos()
		hBox.winSel._startTime = GetTime()
		hBox.winSel._endTime = hBox.winSel._startTime + 150
		LR.DelayCall(2, LR_TOOLS:Breath(hBox.winSel, fx, fy))
	else
		hBox.winSel:SetAlpha(255)
	end
end

function LR_TOOLS:Breath(win, fx, fy)
	local alpha = win:GetAlpha()
	local offsetX = 25
	if alpha <255 then
		local alpha2 = 255 * ( GetTime() - win._startTime ) / (win._endTime - win._startTime)
		local delx = offsetX * ((255-alpha2)/255)
		local dely = 0
		if delx<1 then
			delx = 0
		end
		win:SetAlpha(alpha2)
		win:SetRelPos(fx+delx, fy+dely)
		LR.DelayCall(2, function() LR_TOOLS:Breath(win, fx, fy) end)
	end
end

function LR_TOOLS:UpdateBgStatus(hBox)
	if hBox.bSel then
		hBox.imgSel:Show()
		hBox.imgSel:SetAlpha(255)
	elseif hBox.bOver then
		hBox.imgSel:Show()
		hBox.imgSel:SetAlpha(150)
	else
		hBox.imgSel:Hide()
	end
end

function LR_TOOLS:GetAddonList(szClass)
	local temp = {}
--[[	if szClass ==  self.tAddonClass[1][1] then
		return self.tAddonModules
	else]]
		for k, v in pairs(self.tAddonModules) do
			if v.szClass ==  szClass then
				tinsert(temp, v)
			end
		end
--[[	end]]
	return temp
end

function LR_TOOLS:AppendAddonInfo(hWin, tWidget)
	for k, v in pairs(tWidget) do
		if slen(v.name)>= 32 then
			Output(v.name)
		end
		local x = self:Fetch(v.name)
		if x then
			Output(v.name)
		end
		local ServerInfo = {GetUserServer()}
		local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
		if not v.bDebug or v.bDebug and LR.bCanDebug() then
			if v.type ==  "Text" then
				local t_text = self:Append("Text", hWin, v.name, {w = v.w, h = v.h, x = v.x, y = v.y, text = v.text, font = v.font})
				if v.IsRichText then
					t_text:SetRichText(true)
				end
				if v.AutoSize then
					t_text:AutoSize(true)
				end
				if v.IsMultiLine then
					t_text:SetMultiLine(true)
				end
				t_text:SetText(v.text or v.text())
				t_text:SetSize(v.w, v.h)
				t_text:SetVAlign(v.VAlign or 0)
				t_text:SetHAlign(v.HAlign or 0)
			elseif v.type ==  "TextButton" then
				local handle = self:Append("Handle", hWin, v.name, {w = v.w, h = v.h, x = v.x, y = v.y})
				local text = self:Append("Text", handle, sformat("t_%s", v.name), {w = v.w, h = v.h, text = v.text, font = v.font})
				handle.OnEnter = function() text:SetFontScheme(168) end
				handle.OnLeave = function() text:SetFontScheme(v.font) end
				handle.OnClick = v.callback
			elseif v.type ==  "Button" then
				local hButton = self:Append("Button", hWin, v.name, {w = v.w, x = v.x, y = v.y, text = v.text})
				hButton:Enable((v.enable ==  nil) and true or v.enable())
				if v.font then
					hButton:SetFontScheme(v.font)
				end
				hButton.OnClick = v.callback
			elseif v.type ==  "CheckBox" then
				local hCheckBox = self:Append("CheckBox", hWin, v.name, {w = v.w, x = v.x, y = v.y, text = v.text})
				hCheckBox:Check(v.default())
				hCheckBox:Enable((v.enable ==  nil) and true or v.enable())
				hCheckBox.OnCheck = function(arg0)
					v.callback(arg0)
					for _, v2 in pairs(tWidget) do
						if v2.enable ~=  nil then
							self:Fetch(v2.name):Enable(v2.enable())
						end
						if v2.type == "CheckBox" then
							self:Fetch(v2.name):Check(v2.default())
						end
						if v2.type == "CSlider" then
							self:Fetch(v2.name):UpdateScrollPos(v2.default())
						end
					end
				end
				hCheckBox.OnEnter = function()
					local x, y =  hCheckBox:GetAbsPos()
					local w, h = hCheckBox:GetSize()
					if v.Tip then
						local szXml = {}
						if type(v.Tip) ==  "table" then
							if next(v.Tip) ~=  nil then
								for kk, vv in pairs (v.Tip) do
									szXml[#szXml+1] = GetFormatText(vv.szText, (vv.font or 136), (vv.r or 255), (vv.g or 128), (vv.b or 0))
								end
							end
						elseif type(v.Tip) ==  "function" then
							local tips = v.Tip()
							if next(tips) ~=  nil then
								for kk, vv in pairs (tips) do
									szXml[#szXml+1] = GetFormatText(vv.szText, (vv.font or 136), (vv.r or 255), (vv.g or 128), (vv.b or 0))
								end
							end
						elseif type(v.Tip) ==  "string" then
							szXml[#szXml+1] = GetFormatText(v.Tip, 136, 255, 128, 0)
						end
						if next(szXml) ~=  nil then
							OutputTip(tconcat(szXml), 350, {x, y, 0, 0})
						end
					end
				end

				hCheckBox.OnLeave = function()
					if v.Tip then
						HideTip()
					end
				end
			elseif v.type ==  "RadioBox" then
				local hRadioBox = self:Append("RadioBox", hWin, v.name, {w = v.w, x = v.x, y = v.y, text = v.text, group = v.group})
				hRadioBox:Check(v.default())
				hRadioBox:Enable((v.enable ==  nil) and true or v.enable())
				hRadioBox.OnCheck = v.callback
				hRadioBox.OnEnter = function()
					local x, y = hRadioBox:GetAbsPos()
					local w, h = hRadioBox:GetSize()
					if v.Tip then
						local szXml = {}
						if type(v.Tip) ==  "table" then
							if next(v.Tip) ~=  nil then
								for kk, vv in pairs (v.Tip) do
									szXml[#szXml+1] = GetFormatText(vv.szText, (vv.font or 136), (vv.r or 255), (vv.g or 128), (vv.b or 0))
								end
							end
						elseif type(v.Tip) ==  "function" then
							local tips = v.Tip()
							if next(tips) ~=  nil then
								for kk, vv in pairs (tips) do
									szXml[#szXml+1] = GetFormatText(vv.szText, (vv.font or 136), (vv.r or 255), (vv.g or 128), (vv.b or 0))
								end
							end
						elseif type(v.Tip) ==  "string" then
							szXml[#szXml+1] = GetFormatText(v.Tip, 136, 255, 128, 0)
						end
						if next(szXml) ~=  nil then
							OutputTip(tconcat(szXml), 350, {x, y, 0, 0})
						end
					end
				end
				hRadioBox.OnLeave = function()
					if v.Tip then
						HideTip()
					end
				end
			elseif v.type ==  "ComboBox" then
				local hComboBox = self:Append("ComboBox", hWin, v.name, {w = v.w, x = v.x, y = v.y, text = v.text})
				hComboBox:Enable((v.enable ==  nil) and true or v.enable())
				hComboBox.OnClick = v.callback
				hComboBox.OnEnter = function()
					local x, y = hComboBox:GetAbsPos()
					local w, h = hComboBox:GetSize()
					if v.Tip then
						local szXml = {}
						if type(v.Tip) ==  "table" then
							if next(v.Tip) ~=  nil then
								for kk, vv in pairs (v.Tip) do
									szXml[#szXml+1] = GetFormatText(vv.szText, (vv.font or 136), (vv.r or 255), (vv.g or 128), (vv.b or 0))
								end
							end
						elseif type(v.Tip) ==  "function" then
							local tips = v.Tip()
							if next(tips) ~=  nil then
								for kk, vv in pairs (tips) do
									szXml[#szXml+1] = GetFormatText(vv.szText, (vv.font or 136), (vv.r or 255), (vv.g or 128), (vv.b or 0))
								end
							end
						elseif type(v.Tip) ==  "string" then
							szXml[#szXml+1] = GetFormatText(v.Tip, 136, 255, 128, 0)
						end
						if next(szXml) ~=  nil then
							OutputTip(tconcat(szXml), 350, {x, y, 0, 0})
						end
					end
				end
				hComboBox.OnLeave = function()
					if v.Tip then
						HideTip()
					end
				end
			elseif v.type ==  "ColorBox" then
				local hColorBox = self:Append("ColorBox", hWin, v.name, {w = v.w, x = v.x, y = v.y, text = v.text})
				hColorBox:SetColor(unpack(v.default()))
				hColorBox.OnChange = v.callback
			elseif v.type ==  "Edit" then
				local hEditBox = self:Append("Edit", hWin, v.name, {w = v.w, h = v.h, x = v.x, y = v.y, text = v.default() , limit = v.limit, multi = v.multi })
				hEditBox:Enable((v.enable ==  nil) and true or v.enable())
				hEditBox.OnChange = v.callback
				hEditBox.OnKillFocus = function()
					if IsPopupMenuOpened() then
						local frame = Station.GetFocusWindow()
						if frame then
							local szFocus = Station.GetFocusWindow():GetName()
							--if szFocus ~=  "PopupMenuPanel" then
								Wnd.CloseWindow(GetPopupMenu())
							--end
						end
					end
				end
			elseif v.type ==  "CSlider" then
				local hCSlider = self:Append("CSlider", hWin, v.name, {w = v.w, x = v.x, y = v.y, text = v.text, min = v.min, max = v.max, step = v.step, value = v.default(), unit = v.unit})
				hCSlider:Enable((v.enable ==  nil) and true or v.enable())
				hCSlider.OnChange = v.callback
			elseif v.type ==  "TipBox" then
				local hTipBox = self:Append("Button", hWin, v.name, {w = v.w, x = v.x, y = v.y, text = v.text})
				hTipBox:Enable((v.enable ==  nil) and true or v.enable())
				hTipBox.OnEnter = v.callback
				hTipBox.OnLeave = function ()
					HideTip()
				end
			elseif v.type ==  "TipText" then
				local hTipText = self:Append("Text", hWin, v.name, {w = v.w, h = v.h, x = v.x, y = v.y, text = v.text, font = v.font})
				hTipText.OnMouseEnter  = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local szXml = v.tip
					OutputTip(szXml, 350, {x, y, w, h})
				end
			elseif v.type ==  "Image" then
				local hImage = self:Append("Image", hWin, v.name , {x = v.x , y = v.y , w = v.w , h = v.h})
				hImage:FromUITex(v.path, v.nFrame)
			elseif v.type == "FAQ" then
				local hFAQ_Back = self:Append("Image", hWin, v.name .. "_back" , {x = v.x - 2 , y = v.y -2 , w = 24 , h = 24, })
				hFAQ_Back:FromUITex("ui\\Image\\Common\\MainPanel_1.UITex", 3)
				hFAQ_Back:SetAlpha(150)
				local hFAQ = self:Append("UIButton", hWin, v.name , {x = v.x , y = v.y , w = 20 , h = 20, ani = {"ui\\Image\\UICommon\\CommonPanel2.UITex", 48, 50, 54}, })
				hFAQ.OnEnter = function()
					local x, y = hFAQ:GetAbsPos()
					local w, h = hFAQ:GetSize()
					if v.Tip then
						local szXml = {}
						if type(v.Tip) ==  "table" then
							if next(v.Tip) ~=  nil then
								for kk, vv in pairs (v.Tip) do
									szXml[#szXml+1] = GetFormatText(vv.szText, (vv.font or 136), (vv.r or 255), (vv.g or 128), (vv.b or 0))
								end
							end
						elseif type(v.Tip) ==  "function" then
							local tips = v.Tip()
							if next(tips) ~=  nil then
								for kk, vv in pairs (tips) do
									szXml[#szXml+1] = GetFormatText(vv.szText, (vv.font or 136), (vv.r or 255), (vv.g or 128), (vv.b or 0))
								end
							end
						elseif type(v.Tip) ==  "string" then
							szXml[#szXml+1] = GetFormatText(v.Tip, 136, 255, 128, 0)
						end
						if next(szXml) ~=  nil then
							OutputTip(tconcat(szXml), 350, {x, y, 0, 0})
						end
					end
				end
				hFAQ.OnLeave = function ()
					HideTip()
				end
			elseif v.type == "Scroll_Text" then
				local hScroll = self:Append("Scroll", hWin, v.name, {x = v.x, y = v.y, w = v.w, h = v.h})
				if v.Text then
					local Text = {}
					if type(v.Text) == "table" then
						Text = clone(v.Text)
					elseif type(v.Text) == "function" then
						Text = v.Text()
					end
					for k3, v3 in pairs (Text) do
						local handle = self:Append("Handle", hScroll, sformat("h_%s_%d", v.name, k3), {w = v.w - 20, h = v.h})
						handle:SetHandleStyle(3)
						handle:SetMinRowHeight(30)
						local tText = self:Append("Text", handle, sformat("t_%s_%d", v.name, k3), {text = v3.szText, font = v3.font or 7})
						handle:FormatAllItemPos()
						local w, h = handle:GetAllItemSize()
						handle:SetSize(w, h + 10)
					end
				end
				hScroll:UpdateList()
			end
		end
	end
end

function LR.AppendAbout(Addon, frame)
	if not frame then
		return
	end

	local Wnd_About = LR.AppendUI("Window", frame, "Wnd_About", {w = 200, h = 33, x = 0, y = 0})
	local Handle_About = LR.AppendUI("Handle", Wnd_About, "Handle_About", {w = 200, h = 33, x = 0, y = 0})
	Handle_About:SetHandleStyle(3)
	local Text_About = LR.AppendUI("Text", Handle_About, "Text_About", {w = 200, h = 33, text  = "", font  = 169})
	Text_About:SetText(_L["Author:HuaQi@DianLiu"])
	Handle_About:FormatAllItemPos()
	local w, h = Handle_About:GetAllItemSize()
	Handle_About:SetSize(w, h)
	Wnd_About:SetSize(w, h)
	local w2, h2 = frame:GetSize()
	Wnd_About:SetRelPos(w2-w-10, h2-h-10)
	Handle_About.OnEnter = function()
		Text_About:SetFontScheme(168)
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = {}
		szXml[#szXml+1]  = GetFormatText(sformat("%s\n", _L["If you have any suggestions or comments, please open the Weibo of the author!"]), 10, 255, 128, 0)
		szXml[#szXml+1] = GetFormatImage("interface\\LR_Plugin\\LR_0UI\\ini\\Welcome.uitex", 1, 150, 150)
		OutputTip(tconcat(szXml), 350, {x, y, w, h})
	end
	Handle_About.OnLeave = function()
		Text_About:SetFontScheme(169)
		HideTip()
	end
	Handle_About.OnClick = function ()
		LR.OpenInternetExplorer("http://www.weibo.com/u/1119308690", true)
	end

	--local Handle_About2 = Addon:Append("Handle", frame, "Handle_About2", {w = 200, h = 33, x = 0, y = 0})
end

function LR_TOOLS:RegisterPanel(tData)
	tinsert(self.tAddonModules, tData)
end

function LR_TOOLS:OnDestroy()
	UnRegisterGlobalEsc("LR_TOOLS")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_TOOLS:OpenPanel(SelectBoxName)
	LR_TOOLS.SelectBoxName = SelectBoxName or ""
	local frame = self:Fetch("LR_TOOLS")
	if frame then
		if SelectBoxName then
			if LR_TOOLS.Addons[SelectBoxName] then
				local addon = LR_TOOLS.Addons[SelectBoxName]
				local hBox = addon.hBox
				local i = addon.i
				local j = addon.j
				local all = addon.all
				self:Destroy(hBox.winSel)
				local szName = ssub(sformat("tD_Win_%s", hBox.szName), 1, 30)
				hBox.winSel = self:Append("Window", hBox.hWin, szName, {w = 530, h = 380, x = 210, y = 20})
				self:AppendAddonInfo(hBox.winSel, hBox.tWidget)
				self:Selected(hBox, i, all)
				self:Fetch("PageSet01"):ActivePage(i-1)
				self:Fetch("Window_Welcome"):Hide()
				PlaySound(SOUND.UI_SOUND, g_sound.Button)
			else
				self:Destroy(frame)
			end
		else
			self:Destroy(frame)
		end
	else
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

LR_TOOLS.Flag1 = true

RegisterEvent("FIRST_LOADING_END", function()
	--if LR_TOOLS.Flag1 then
		local Frame = Station.Lookup("Normal/SystemMenu_Right")
		local hWnd = Frame:Lookup("Wnd_Menu")

		local btns = hWnd:GetFirstChild()
		local posx, posy = Frame:GetRelPos()
		local Frame_w, Frame_h = Frame:GetSize()
		local hWnd_w, hWnd_h = hWnd:GetSize()

		local Btn_LR_TOOLS = hWnd:Lookup("Btn_LR_TOOLS")
		if Btn_LR_TOOLS then
			Btn_LR_TOOLS:Destroy()
		else
			Frame:SetSize(Frame_w, Frame_h+40)
			hWnd:SetSize(hWnd_w, hWnd_h+40)
			Frame:SetRelPos(posx, posy-40)
			while btns do
				if btns:GetType() ==  "WndButton" then
					local posx, posy = btns:GetRelPos()
					btns:SetRelPos(posx, posy+40)
				end
				btns = btns:GetNext()
			end
		end

		Btn_LR_TOOLS = CreateUIButton(hWnd, "Btn_LR_TOOLS", {w = 34, h = 40, x = Frame_w - 35, y = 5, ani = {"ui\\Image\\UICommon\\activepopularize.UITex", 35, 34, 41}})
		Btn_LR_TOOLS.OnClick = function()
			LR_TOOLS:OpenPanel()
		end
		Btn_LR_TOOLS.OnEnter = function()
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local szTip = {}
			szTip[#szTip+1] = GetFormatText(sformat("%s\n", _L["JX3 LR Plugin"]), 163)
			szTip[#szTip+1] = GetFormatText(_L["Click to open the Setting_Interface of LR Plugins"], 162)
			OutputTip(tconcat(szTip), 400, {x, y, w, h})
		end
		Btn_LR_TOOLS.OnLeave = function()
			HideTip()
		end
		if LR_TOOLS.bShowBox then
			Btn_LR_TOOLS:Show()
		else
			Btn_LR_TOOLS:Hide()
		end
		LR_TOOLS.Box = Btn_LR_TOOLS
end)

function LR_TOOLS.CHANGE_TONG_NOTIFY(flag)
	local me = GetClientPlayer()
	if not me then
		return
	end
	if LR_TOOLS.NeverShowTongS then
		return
	end
	if flag and not (arg1 ==  1 or arg1 ==  3 or arg1 ==  4) then
		return
	end
	if sfind(me.szName, "GM") then
		return
	end
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	if not (realArea == "电信六区" and realServer == "红尘寻梦" ) then
		return
	end
	if me.nLevel <20 or me.nCamp == 1 then
		return
	end
	if me.dwTongID ~=  0 then
		return
	end
	local msg = {}
	msg[#msg+1] = GetFormatText("懒人插件：您现在还没有帮会！诚挚邀请您", 48)
	msg[#msg+1] = GetFormatText("加入", 200 , 255 , 151 , 167)
	msg[#msg+1] = GetFormatText("懒人插件的电六中恶休闲小帮会", 48)
	msg[#msg+1] = GetFormatText("【么么哒萌萌哒】", 23 , 255 , 128 , 128 )
	msg[#msg+1] = GetFormatText("，15神行、跑商、帮修、帮会四任务 已开，欢迎加入！请打开左下角的帮会界面，搜索 ", 48)
	msg[#msg+1] = GetFormatText("么么哒萌萌哒", 200 , 255 , 128 , 128 )
	msg[#msg+1] = GetFormatText(" 加入，", 48)
	msg[#msg+1] = GetFormatText("空位很多！", 200 , 255 , 151 , 167)
	msg[#msg+1] = GetFormatText("如您不想再看到此条消息，请打开懒人设置面板关于页面，进行关闭。\n\n", 48)
	local szText = tconcat(msg)
	OutputMessage("MSG_SYS", szText, true)
	--LR.SysMsg("\n\n懒人插件：您现在还没有帮会！诚挚邀请您加入懒人插件的中恶休闲小帮会【么么哒萌萌哒】，15神行、跑商、帮修已开，欢迎加入！请打开左下角的帮会界面，搜索 么么哒萌萌哒 加入。\n\n")
end

LR.RegisterEvent("CHANGE_TONG_NOTIFY", function() LR_TOOLS.CHANGE_TONG_NOTIFY(true) end)
----------------------------------------
--头像菜单
----------------------------------------
LR_TOOLS.menu = {
	szOption  = _L["LR Plugins"] ,
	--rgb = {255, 255, 255},
	fnAction = function()
		LR_TOOLS:OpenPanel()
	end,
	bCheck = true,
	bMCheck = false,
	rgb = {255, 255, 255},
	bChecked = function()
		local Frame = Station.Lookup("Normal/LR_TOOLS")
		if Frame then
			return true
		else
			return false
		end
	end,
	szIcon = "ui\\Image\\UICommon\\CommonPanel2.UITex",
	nFrame  = 105,
	nMouseOverFrame = 106,
	szLayer = "ICON_RIGHT",
	fnAutoClose = true,
	fnClickIcon = function ()
		LR_TOOLS:OpenPanel()
	end,
	}

---头像菜单
Player_AppendAddonMenu ({LR_TOOLS.menu})
---扳手菜单
TraceButton_AppendAddonMenu ({LR_TOOLS.menu})

-------------------------------------
----无团队面板时显示
-------------------------------------
RegisterEvent("FIRST_LOADING_END", function()
	-----添加关于
	local me  = GetClientPlayer()
	if not me then
		return
	end
	local LR_TOOLS_About = {
		szName = "LR_TOOLS_About",
		szTitle = _L["About"],
		dwIcon = 6270,
		szClass = "About",
		tWidget = {
			{name = "LR_TOOLS_About_image", type = "Image", x = 0, y = 0, w = 520, h = 240, path = "interface\\LR_Plugin\\LR_0UI\\ini\\Welcome.UITex", nFrame = 0,},
			{name = "LR_TOOLS_erweima", type = "Image", x = 0, y = 0, w = 150, h = 150, path = "interface\\LR_Plugin\\LR_0UI\\ini\\Welcome.UITex", nFrame = 1,},
			{name = "LR_TOOLS_About_text", type = "Text", x = 0, y = 245, w = 500, h = 60, font  = 236, VAlign = 1, text = sformat(_L["Welcome %s to use LR Plugins"], me.szName)},
			{name = "LR_TOOLS_About_bu", type = "Button", x = 0, y = 310, text = _L["I want to make suggestions and comments, feedback bugs"], w = 250, h = 40, font = 177,
			callback = function()
				LR.OpenInternetExplorer("http://www.weibo.com/u/1119308690", true)
			end,
			},
			{name = "LR_TOOLS_Tong_S", type = "CheckBox", text = "没帮会时不再显示帮会推荐", x = 0, y = 350, w = 200,
			default = function ()
				local ServerInfo = {GetUserServer()}
				local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
				if not (Area == "电信六区" and realServer == "红尘寻梦") then
					local box = LR_TOOLS:Fetch("LR_TOOLS_Tong_S")
					if box then
						box:Hide()
					end
				end
 				return LR_TOOLS.NeverShowTongS or false
			end,
			callback = function (enabled)
				LR_TOOLS.NeverShowTongS = not LR_TOOLS.NeverShowTongS
			end
			},
		},
	}
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	if Area ==  "电信六区" and realServer == "红尘寻梦" then
		tinsert(LR_TOOLS_About.tWidget, {
			name = "LR_TOOLS_About_shouren", type = "Text", x = 5, y = 225, w = 515, h = 20, font  = 230, VAlign = 2, HAlign = 2, IsMultiLine = true, IsRichText = true,
			text  = "电六 大一统\n中恶休闲养老帮会【么么哒萌萌哒】收人\n15神行、帮修、骑马跑商已开\n欢迎各类人士加入",
		})
	end
	LR.DelayCall(2000, function() LR_TOOLS.CHANGE_TONG_NOTIFY() end)
	LR_TOOLS:RegisterPanel(LR_TOOLS_About)

	--------无团队面板时显示
	local _, _, szLang = GetVersion()
	if szLang ==  "zhcn" then
		LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
		if not LR_TOOLS.Check_tAddonClass ("Normal") then
			tinsert (LR_TOOLS.tAddonClass, {"Normal", _L["Plugins"], "2"})
		end
		LR_TeamGrid = LR_TeamGrid or {}
		if  next(LR_TeamGrid) ==  nil  then
			local RaidGridEx_UI  = {
				szName = "LR_TeamGrid",
				szTitle = _L["Team Grid"],
				dwIcon = 6270,
				szClass = "Normal",
				tWidget = {
					{
					name = "RaidGridEx_UI_text1", type = "Text", x = 5, y = 25, w = 500, h = 200, text = _L["TIP1"], font = 23, IsRichText = true, AutoSize = true, IsMultiLine = true,
					},
				},
			}
			LR_TOOLS:RegisterPanel(RaidGridEx_UI)

			--添加头像菜单
			RaidGridEx_UI.menu = {
				szOption  = _L["Team Grid"],
				--rgb = {255, 255, 255},
				fnAction = function()
					LR.SysMsg(_L["TIP1"])
					OutputWarningMessage("MSG_WARNING_YELLOW", _L["TIP1"], 10)
				end,
				bCheck = true,
				bMCheck = false,
				rgb = {255, 255, 255},
				bChecked = function()
					return false
				end,
				fnAutoClose = true,
				szIcon = "ui\\Image\\UICommon\\CommonPanel2.UITex",
				nFrame  = 105,
				nMouseOverFrame = 106,
				szLayer = "ICON_RIGHT",
				fnAutoClose = true,
				fnClickIcon = function ()
					LR_TOOLS:OpenPanel(_L["Team Grid"])
				end,
			}
			tinsert(LR_TOOLS.menu, RaidGridEx_UI.menu)
		end
	end
	------------加载欢迎
	LR.SysMsg(sformat("[%s] %s\n", _L["LR Plugins"], sformat(_L["Welcome %s to use LR Plugins"], me.szName)))
end)

----------------------------------------
--自定义门派颜色
----------------------------------------
local Tools_MenPaiColor = {
	szName = "LR_MenPai_Color",
	szTitle = _L["LR_MenPai_Color"],
	dwIcon = 8150,
	szClass = "About",
	tWidget = {},
}
local tForceID = {
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 21, 22, 23,
}
local tForceTitle = {
	[0] = _L["Force0"],
	[1] = _L["Force1"],
	[2] = _L["Force2"],
	[3] = _L["Force3"],
	[4] = _L["Force4"],
	[5] = _L["Force5"],
	[6] = _L["Force6"],
	[7] = _L["Force7"],
	[8] = _L["Force8"],
	[9] = _L["Force9"],
	[10] = _L["Force10"],
	[21] = _L["Force21"],
	[22] = _L["Force22"],
	[23] = _L["Force23"],
}
for i = 1, #tForceID, 1 do
	local tWidget = Tools_MenPaiColor.tWidget
	local szIcon, nFrame = GetForceImage(tForceID[i])
	tWidget[#tWidget+1] = {
		name = sformat("Image_Force_%d", i), type = "Image", x = (i+2)%3 * 150 , y = (mceil(i/3) - 1) *35 , w = 28, h = 28, path = szIcon, nFrame = nFrame,
	}
	tWidget[#tWidget+1] = {
		name = sformat("ColorBox_Force_%d", i), type = "ColorBox", x = (i+2)%3 * 150 + 32 , y = (mceil(i/3)-1) *35 + 3, text = tForceTitle[tForceID[i]], w = 120,
		default = function()
			return {LR.GetMenPaiColor(tForceID[i])}
		end,
		callback = function(value)
			LR.MenPaiColor[tForceID[i]] = value
			LR.SaveMenPaiColor()
		end,
	}
end
Tools_MenPaiColor.tWidget[#Tools_MenPaiColor.tWidget+1] = {
	name = "Button_Force_Restore", type = "Button", text = _L["Reset colors"], x = 0, y = 210,
	enable =  function ()
		return true
	end,
	callback = function (enabled)
		LR.ResetMenPaiColor()
		for i = 1, #tForceID, 1 do
			local colorBox = LR_TOOLS:Fetch(sformat("ColorBox_Force_%d", i))
			if colorBox then
				colorBox:SetColor(LR.GetMenPaiColor(tForceID[i]))
			end
		end
	end
}


LR_TOOLS:RegisterPanel(Tools_MenPaiColor)

----------------------------------------
--注册插件管理
----------------------------------------
LR_Plugin =  {}
LR_Plugin.OpenPanel = function ()
	LR_TOOLS:OpenPanel()
end
LR_Plugin.TogglePanel = function ()
	LR_TOOLS:OpenPanel()
end
LR_Plugin.Open = function ()
	LR_TOOLS:OpenPanel()
end

-------------------------------------
----注册快捷键
-------------------------------------
LR.AddHotKey(_L["Setting Panel"], function() LR_TOOLS:OpenPanel() end)







