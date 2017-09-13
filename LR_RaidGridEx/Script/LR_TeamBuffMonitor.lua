local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local VERSION = "20170913"
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_RaidGridEx"
local SaveDataPath="Interface\\LR_Plugin\\@DATA\\LR_TeamGrid"
local _L = LR.LoadLangPack(AddonPath)
local _DefaultBuffMonitorData={
	VERSION = VERSION,
	data={},
}
----------------------------------------------------------------
local _BuffBox = {
	dwMemberID = nil,
	handle = nil,
	dwID = nil,
	parentHandle = nil,
}
_BuffBox.__index = _BuffBox

function _BuffBox:new(dwID, BuffHandle, tBuff)
	local o={}
	setmetatable(o,self)
	o.dwID = dwID
	o.dwMemberID = dwMemberID
	o.tBuff = clone(tBuff)
	o.nOrder = 1
	o.parentHandle = BuffHandle
	o.nStartFrame = GetLogicFrameCount()
	return o
end

function _BuffBox:Create()
	local parentHandle = self.parentHandle
	local dwID = self.dwID
	local handle = parentHandle:Lookup(sformat("Handle_BuffBox_%d", dwID))
	if not handle then
		local szIniFile = sformat("%s\\UI\\%s\\BuffBox.ini", AddonPath, LR_TeamGrid.UsrData.UI_Choose)
		handle = parentHandle:AppendItemFromIni(szIniFile, "Handle_BuffBox", sformat("Handle_BuffBox_%d", dwID))
	end
	self.handle = handle
	return self
end

function _BuffBox:Remove()
	local parentHandle = self.parentHandle
	local dwID = self.dwID
	local handle = parentHandle:Lookup(sformat("Handle_BuffBox_%d", dwID))
	if handle then
		parentHandle:RemoveItem(handle)
	end
	return self
end

function _BuffBox:SetOrder(nOrder)
	self.nOrder = nOrder
	return self
end

function _BuffBox:SetStartFrame()
	self.nStartFrame = GetLogicFrameCount()
	return self
end

function _BuffBox:GetStartFrame()
	return self.nStartFrame
end

function _BuffBox:GetEndFrame()
	return self.tBuff.nEndFrame
end

function _BuffBox:SetSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local nOrder = self.nOrder
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local fp = mmin(fx, fy)
	local height = UIConfig.handleBuffBox[nOrder].height * fp
	local width = UIConfig.handleBuffBox[nOrder].width * fp
	local border = LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffShadow.nBorder or 0
	local handle = self.handle
	handle:Lookup("Box"):SetSize(width, height)
	handle:Lookup("Box2"):SetSize(width, height)
	handle:Lookup("Shadow_Color"):SetSize(width + border * 2, height + border * 2)
	handle:Lookup("Shadow_Color"):SetRelPos(-border, -border)
	handle:Lookup("Text_BuffStacks"):SetSize(width, height)
	handle:SetSize(width, height)
	handle:FormatAllItemPos()
	return self
end

function _BuffBox:SetRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local nOrder = self.nOrder
	local top = UIConfig.handleBuffBox[nOrder].top * fy
	local left = UIConfig.handleBuffBox[nOrder].left * fx
	local handle = self.handle
	local parentHandle = self.parentHandle
	handle:SetRelPos(left,top)
	parentHandle:FormatAllItemPos()
	return self
end

function _BuffBox:SetIcon()
	local handle = self.handle
	local box = handle:Lookup("Box")
	if self.tBuff.nIconID and self.tBuff.nIconID > 0 then
		self.nIcon = self.tBuff.nIconID
	else
		self.nIcon = Table_GetBuffIconID(self.tBuff.dwID, self.tBuff.nLevel)
	end
	box:SetObjectIcon(self.nIcon)
	return self
end

function _BuffBox:SetEndFrame(nEndFrame)
	self.tBuff.nEndFrame = nEndFrame
	return self
end

function _BuffBox:SetBuff(tBuff)
	self.tBuff = clone(tBuff)
	return self
end

function _BuffBox:Show()
	local handle = self.handle
	local box = handle:Lookup("Box")
	local box2 = handle:Lookup("Box2")
	local Text_BuffStacks = handle:Lookup("Text_BuffStacks")
	local UIConfig = LR_TeamGrid.UIConfig
	local nOrder = self.nOrder
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.handleBuffBox[nOrder].height
	local width = UIConfig.handleBuffBox[nOrder].width
	local n = mmin(height, width) * mmin(fx, fy)
	local fp = n / 16
	Text_BuffStacks:SetFontScheme(15)
	Text_BuffStacks:SetSize(height, width)
	Text_BuffStacks:SetVAlign(1)
	Text_BuffStacks:SetHAlign(1)
	if fp < 1 then
		Text_BuffStacks:SetFontScale(fp)
	end
	if self.tBuff.nStackNum and self.tBuff.nStackNum > 1 then
		Text_BuffStacks:SetText(self.tBuff.nStackNum)
	else
		Text_BuffStacks:SetText("")
	end
	box2:SetObject(1)
	box2:SetExtentImage("ui\\Image\\Common\\Box.UITex", 11)
	box2:SetAlpha(170)
	box2:Hide()
	box:SetObject(1)
	box:SetObjectIcon(self.nIcon)
	self.handle:Show()
	return self
end

function _BuffBox:Hide()
	self.handle:Hide()
	return self
end

function _BuffBox:Draw()
	local now = GetLogicFrameCount()
	local nEndFrame = self.tBuff.nEndFrame
	local nStartFrame = self.nStartFrame
	local nLeftFrame = nEndFrame - now
	local nTotalFrame = nEndFrame - nStartFrame
	if nLeftFrame < 0 then
		nLeftFrame = 0
	end
	local fp = nLeftFrame / nTotalFrame
	local handle = self.handle
	local box = handle:Lookup("Box")
	local box2 = handle:Lookup("Box2")
	local sha = handle:Lookup("Shadow_Color")
	if nLeftFrame < 16*3 then
		box:SetObjectStaring(true)
	else
		box:SetObjectStaring(false)
	end
	if nLeftFrame < 8 then
		box:SetObjectSparking(true)
	else
		box:SetObjectSparking(false)
	end
	if fp > 0.1 and fp < 0.99 and LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bShowDebuffCDAni then
		box2:SetObjectCoolDown(true)
		box2:SetCoolDownPercentage(fp)
		box2:Show()
	else
		box2:SetObjectCoolDown(false)
		box2:Hide()
	end
	sha:Hide()
	if LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffShadow.bShow then
		if self.tBuff.col and type(self.tBuff.col) == "table" and next(self.tBuff.col) ~= nil then
			sha:SetColorRGB(unpack(self.tBuff.col))
			sha:SetAlpha(LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffShadow.alpha)
			sha:Show()
		end
	end

	local Text_BuffStacks = handle:Lookup("Text_BuffStacks")
	Text_BuffStacks:SetFontScheme(7)
	Text_BuffStacks:SetAlpha(180)
	Text_BuffStacks:SetFontScale(0.9)
	Text_BuffStacks:SetHAlign(2)
	Text_BuffStacks:SetVAlign(2)
	Text_BuffStacks:SetFontColor(255, 255, 0)
	local w, h = box:GetSize()
	Text_BuffStacks:SetSize(w, h)
	if LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.buffTextType == 2 then
		if nLeftFrame / 16 < 9 then
			Text_BuffStacks:SprintfText("%0.0f", mfloor(nLeftFrame / 16) )
			Text_BuffStacks:Show()
			if nLeftFrame / 16 <=3 then
				Text_BuffStacks:SetFontColor(237, 168, 168)
			elseif nLeftFrame / 16 < 6 then
				Text_BuffStacks:SetFontColor(255, 255, 128)
			else
				Text_BuffStacks:SetFontColor(255, 255, 255)
			end
		else
			Text_BuffStacks:Hide()
		end
	elseif LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.buffTextType == 1 then
		if self.tBuff.nStackNum and self.tBuff.nStackNum > 1 then
			Text_BuffStacks:SetText(self.tBuff.nStackNum)
			Text_BuffStacks:SetFontColor(255, 255, 255)
		else
			Text_BuffStacks:SetText("")
		end
	elseif LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.buffTextType == 3 then
		Text_BuffStacks:Hide()
	end
--[[	if GetLogicFrameCount()%16 == 0 then
		Output(self.tBuff)
	end]]
--[[	if Table_GetBuffName(self.tBuff.dwID, self.tBuff.nLevel) == "极乐" and GetLogicFrameCount()%16 == 0 then
		Output(self.nStartFrame,self.tBuff,fp)
	end]]

	return self
end

----------------------------------------------------------------
----Debuff设置
----------------------------------------------------------------
LR_TeamBuffSettingPanel = {}
LR_TeamBuffSettingPanel.frameSelf = nil
LR_TeamBuffSettingPanel.handleList = nil
LR_TeamBuffSettingPanel.handleListSelected = nil

-- 存档的BUFF/DEBUFF列表内容, 主表是个 Array
-- 子表格式为 {szName = "组名", szDesc = "我是描述，我是TIP。", szContent = "普渡八音(红),火里栽莲,王手截脉(蓝)", bEnable = true}
LR_TeamBuffSettingPanel.tDebuffListContent = {}
local JH_DBM_BUFF_LIST = {}	---用于存放DBM过来的BUFF数据

local nEnableIcon = 6933
local nDisableIcon = 6942
local szIniFile = sformat("%s\\UI\\LR_TeamBuffSettingPanel.ini", AddonPath)

LR_TeamBuffSettingPanel.tColorCover = {
	[_L["red"]] = {255, 0, 0},
	[_L["green"]] = {0, 255, 0},
	[_L["blue"]] = {0, 0, 255},
	[_L["yellow"]] = {255, 255, 0},
	[_L["purple"]] = {255, 0, 255},
	[_L["grass"]] = {0, 255, 255},
	[_L["orange"]] = {255, 128, 0},
	[_L["black"]] = {0, 0, 0},
	[_L["white"]] = {255, 255, 255},
}

LR_TeamBuffSettingPanel.BuffList={}
-- 格式化Debuff表的数据, 成为直接可用的内容
function LR_TeamBuffSettingPanel.FormatDebuffNameList()
	local tSplitTextTable = {}
	for nIndex, tInfo in pairs(LR_TeamBuffSettingPanel.tDebuffListContent) do
		local szContent = tInfo.szContent
		if tInfo.bEnable and szContent and type(szContent) == "string" and szContent ~= "" then
			szContent = sgsub(szContent, "%s", "")
			szContent = sgsub(szContent, " ", "")
			szContent = sgsub(szContent, "；", ";")
			szContent = sgsub(szContent, "，", ",")
			szContent = sgsub(szContent, "（", "(")
			szContent = sgsub(szContent, "）", ")")
			szContent = sformat("%s;", szContent)
			local t={}
			for s in sgfind(szContent, "(.-);") do
				if s ~= "" then
					t[#t + 1] = s
				end
			end

			for i = 1, #t, 1 do
				local buff = {dwID = 0, szName = "", col = {}, bOnlySelf = false, nIconID = 0, nLevel = 0,}
				local text = t[i]

				local _s, _e, bSelf = sfind(text, "%[(.-)%]")
				if bSelf and bSelf == _L["self"] then
					buff.bOnlySelf = true
				end
				text = sgsub(text, "%[(.-)%]", "")

				local _s, _e, _color = sfind(text,"%((.-)%)")
				if _color then
					local _s, _e, r, g, b = sfind(text, "(%d+),(%d+),(%d+)")
					if _s then
						buff.col = {r, g, b}
					else
						buff.col = LR_TeamBuffSettingPanel.tColorCover[_color] or {}
					end
				end
				text = sgsub(text, "%((.-)%)", "")

				local _s, _e, _nIconID = sfind(text, "#(%d+)")
				if _s then
					buff.nIconID = tonumber(_nIconID)
				end
				text = sgsub(text, "#(%d+)", "")

				if type(tonumber(text)) == "number" then
					buff.dwID = tonumber(text)
					if not tSplitTextTable[buff.szName] then
						tSplitTextTable[buff.dwID] = buff
					end
				else
					buff.szName = text
					if not tSplitTextTable[buff.szName] then
						tSplitTextTable[buff.szName] = buff
					end
				end
			end
		end
	end

	LR_TeamBuffSettingPanel.BuffList = clone(tSplitTextTable)
end

function LR_TeamBuffSettingPanel.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
	LR_TeamBuffSettingPanel.OnEvent("UI_SCALED")
	LR_TeamBuffSettingPanel.frameSelf = nil
	LR_TeamBuffSettingPanel.handleList = nil
	LR_TeamBuffSettingPanel.handleListSelected = nil
	LR_TeamBuffSettingPanel.LoadCommonData()
	LR_TeamBuffSettingPanel.frameSelf = this
	LR_TeamBuffSettingPanel.handleList = this:Lookup("", "Handle_List")
	LR_TeamBuffSettingPanel.UpdateList()
end

function LR_TeamBuffSettingPanel.OnFrameDestroy()
	LR_TeamBuffSettingPanel.frameSelf = nil
	LR_TeamBuffSettingPanel.handleList = nil
	LR_TeamBuffSettingPanel.handleListSelected = nil
end

function LR_TeamBuffSettingPanel.OnFrameBreathe()
	------
end

function LR_TeamBuffSettingPanel.OnEvent(event)
	if event == "UI_SCALED" then
		this:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
	end
end

function LR_TeamBuffSettingPanel.UpdateList()
	local handleList = LR_TeamBuffSettingPanel.handleList
	if handleList then
		handleList:Clear()
	end
	for nIndex, tContent in pairs(LR_TeamBuffSettingPanel.tDebuffListContent) do
		LR_TeamBuffSettingPanel.NewListDebuffGroup(nIndex)
	end
end

function LR_TeamBuffSettingPanel.NewListDebuffGroup(nIndex, bSelectNewHandle)
	local tInfo = LR_TeamBuffSettingPanel.tDebuffListContent[(nIndex or -1)]
	if not tInfo then
		nIndex = #LR_TeamBuffSettingPanel.tDebuffListContent + 1
		tInfo = {szName = sformat("%s[%d]", _L["NewGroup"], nIndex), szDesc = "", szContent = "", bEnable = true}
		tinsert(LR_TeamBuffSettingPanel.tDebuffListContent, tInfo)
	end

	local handleList = LR_TeamBuffSettingPanel.handleList
	if not handleList then
		return
	end
	local handleDebuffGroup = handleList:AppendItemFromIni(szIniFile, "HI")
	handleDebuffGroup:Lookup("Name"):SetText(tInfo.szName)
	handleDebuffGroup.nIndex = nIndex

	local box = handleDebuffGroup:Lookup("Box_Skill")
	local nIconID = nDisableIcon
	if tInfo.bEnable then
		nIconID = nEnableIcon
	end

	box:Show()
	box:SetObject(1,0)
	box:ClearObjectIcon()
	box:SetObjectIcon(nIconID)
	box.nIndex = nIndex

	if bSelectNewHandle then
		LR_TeamBuffSettingPanel.SelectListHandle(handleDebuffGroup)
	end
	LR_TeamBuffSettingPanel.UpdateScrollInfo()
	return handleDebuffGroup
end

function LR_TeamBuffSettingPanel.DelListDebuffGroup(handle)
	local nIndex = handle.nIndex
	local tInfo = LR_TeamBuffSettingPanel.tDebuffListContent[nIndex]
	if tInfo then
		tremove(LR_TeamBuffSettingPanel.tDebuffListContent, nIndex)
		LR_TeamBuffSettingPanel.UpdateList()
		LR_TeamBuffSettingPanel.UpdateScrollInfo()
		LR_TeamBuffSettingPanel.handleListSelected = nil
	end
end

function LR_TeamBuffSettingPanel.UpdateScrollInfo()
	local handleList = LR_TeamBuffSettingPanel.handleList
	handleList:FormatAllItemPos()
	local w, h = handleList:GetSize()
	local wAll, hAll = handleList:GetAllItemSize()

	local nStep = mceil((hAll - h) / 10)
	local scroll = handleList:GetRoot():Lookup("Scroll_List")
	if nStep > 0 then
		scroll:Show()
		scroll:GetParent():Lookup("Btn_Up"):Show()
		scroll:GetParent():Lookup("Btn_Down"):Show()
	else
		scroll:Hide()
		scroll:GetParent():Lookup("Btn_Up"):Hide()
		scroll:GetParent():Lookup("Btn_Down"):Hide()
	end
	scroll:SetStepCount(nStep)
end

-------------------------------------------------------------------------------------------------------------
function LR_TeamBuffSettingPanel.OnItemMouseEnter()
	local szName = this:GetName()
	if szName:match("HI") then
		local imageCover = this:Lookup("Sel")
		if imageCover then
			imageCover:Show()
		end
	elseif szName:match("Box_Skill") then
		this:SetObjectMouseOver(true)
		local tInfo = LR_TeamBuffSettingPanel.tDebuffListContent[this.nIndex]
		if tInfo then
			local szTip = tInfo.szDesc or ""
			local nMouseX, nMouseY = Cursor.GetPos()
			local szEnableTip = {}
			if tInfo.bEnable then
				szEnableTip[#szEnableTip+1] = sformat("<Text>text=%s\n font=105 </text>", EncodeComponentsString(_L["This monitoring module is working now.(Smile Icon)"]))
			else
				szEnableTip[#szEnableTip+1] = sformat("<Text>text=%s\n font=102 </text>", EncodeComponentsString(_L["This monitoring module has been closed.(Crying Icon)"]))
			end
			szEnableTip[#szEnableTip+1] = sformat("<Text>text=%s font=100 </text>", EncodeComponentsString(szTip))
			OutputTip(tconcat(szEnableTip), 1000, {nMouseX, nMouseY, 0, 0})
		end
	end
end

function LR_TeamBuffSettingPanel.OnItemMouseLeave()
	local szName = this:GetName()
	if szName:match("HI") then
		local imageCover = this:Lookup("Sel")
		local nSelectedIndex = -1
		if LR_TeamBuffSettingPanel.handleListSelected and LR_TeamBuffSettingPanel.handleListSelected.nIndex then
			nSelectedIndex = LR_TeamBuffSettingPanel.handleListSelected.nIndex
		end
		if imageCover and this.nIndex ~= nSelectedIndex then
			imageCover:Hide()
		end
	elseif szName:match("Box_Skill") then
		this:SetObjectMouseOver(false)
		HideTip()
	end
end

-------------------------------------------------------------------------------------------------------------

function LR_TeamBuffSettingPanel.OnItemLButtonClick()
	local szName = this:GetName()
	if szName:match("Box_Skill") then
		local nIndex = this.nIndex
		local tInfo = LR_TeamBuffSettingPanel.tDebuffListContent[nIndex]
		if tInfo then
			local box = this
			local nIconID = nDisableIcon
			if tInfo.bEnable then
				tInfo.bEnable = false
			else
				tInfo.bEnable = true
				nIconID = nEnableIcon
			end
			box:SetObjectIcon(nIconID)
			LR_TeamBuffSettingPanel.FormatDebuffNameList()
			--LR_TeamBuffSettingPanel.OnItemMouseEnter()
		end
	elseif szName:match("HI") then
		LR_TeamBuffSettingPanel.SelectListHandle(this)
	end
end

function LR_TeamBuffSettingPanel.SelectListHandle(handle)
	if LR_TeamBuffSettingPanel.handleListSelected then
		local imageLastSelectedImage = LR_TeamBuffSettingPanel.handleListSelected:Lookup("Sel")
		if imageLastSelectedImage then
			imageLastSelectedImage:Hide()
		end
	end
	LR_TeamBuffSettingPanel.handleListSelected = handle

	local imageCover = handle:Lookup("Sel")
	if imageCover then
		imageCover:Show()
	end

	local tInfo = LR_TeamBuffSettingPanel.tDebuffListContent[handle.nIndex]
	if tInfo then
		LR_TeamBuffSettingPanel.frameSelf:Lookup("Edit_Name"):SetText(tInfo.szName or "")
		LR_TeamBuffSettingPanel.frameSelf:Lookup("Edit_Desc"):SetText(tInfo.szDesc or "")
		LR_TeamBuffSettingPanel.frameSelf:Lookup("Edit_Content"):SetText(tInfo.szContent or "")
	else
		LR_TeamBuffSettingPanel.frameSelf:Lookup("Edit_Name"):SetText("")
		LR_TeamBuffSettingPanel.frameSelf:Lookup("Edit_Desc"):SetText("")
		LR_TeamBuffSettingPanel.frameSelf:Lookup("Edit_Content"):SetText("")
	end
end

-------------------------------------------------------------------------------------------------------------

function LR_TeamBuffSettingPanel.OnEditChanged()
	local szName = this:GetName()
	local handleSelected = LR_TeamBuffSettingPanel.handleListSelected
	if handleSelected then
		local nIndex = LR_TeamBuffSettingPanel.handleListSelected.nIndex
		local tInfo = LR_TeamBuffSettingPanel.tDebuffListContent[nIndex]
		if tInfo then
			if szName:match("Edit_Name") then
				tInfo.szName = this:GetText()
				handleSelected:Lookup("Name"):SetText(tInfo.szName)
			elseif szName:match("Edit_Desc") then
				tInfo.szDesc = this:GetText()
			elseif szName:match("Edit_Content") then
				tInfo.szContent = this:GetText()
			end
		end

		LR_TeamBuffSettingPanel.FormatDebuffNameList()
	end
end

function LR_TeamBuffSettingPanel.OnScrollBarPosChanged()
	local nCurrentValue = this:GetScrollPos()
	local szName = this:GetName()
	if szName == "Scroll_List" then
		local nCurrentValue = this:GetScrollPos()
		local frame = this:GetParent()
		if nCurrentValue == 0 then
			frame:Lookup("Btn_Up"):Enable(false)
		else
			frame:Lookup("Btn_Up"):Enable(true)
		end
		if nCurrentValue == this:GetStepCount() then
			frame:Lookup("Btn_Down"):Enable(false)
		else
			frame:Lookup("Btn_Down"):Enable(true)
		end

	    local handle = frame:Lookup("", "Handle_List")
	    handle:SetItemStartRelPos(0, - nCurrentValue * 10)
    end
end

function LR_TeamBuffSettingPanel.OnLButtonHold()
    local szName = this:GetName()
	if szName == "Btn_Up" then
		this:GetParent():Lookup("Scroll_List"):ScrollPrev(1)
	elseif szName == "Btn_Down" then
		this:GetParent():Lookup("Scroll_List"):ScrollNext(1)
    end
end

function LR_TeamBuffSettingPanel.OnItemMouseWheel()
	local nDistance = Station.GetMessageWheelDelta()
	this:GetParent():Lookup("Scroll_List"):ScrollNext(nDistance)
	return 1
end

function LR_TeamBuffSettingPanel.OnLButtonDown()
	LR_TeamBuffSettingPanel.OnLButtonHold()
end

-------------------------------------------------------------------------------------------------------------

function LR_TeamBuffSettingPanel.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Cancel" then
		LR_TeamBuffSettingPanel.ClosePanel()
		LR_TeamBuffSettingPanel.FormatDebuffNameList()
	elseif szName == "Btn_New" then
		LR_TeamBuffSettingPanel.NewListDebuffGroup(nil, true)
		PlaySound(SOUND.UI_SOUND,g_sound.Button)
	elseif szName == "Btn_Close" then
		LR_TeamBuffSettingPanel.ClosePanel()
		LR_TeamBuffSettingPanel.FormatDebuffNameList()
	elseif szName == "Btn_Delete" then
		if not LR_TeamBuffSettingPanel.handleListSelected then
			return
		end
		local DelHandle = function()
			local handleSelected = LR_TeamBuffSettingPanel.handleListSelected
			if not handleSelected then
				return
			end
			local nIndex = LR_TeamBuffSettingPanel.handleListSelected.nIndex
			local tInfo = LR_TeamBuffSettingPanel.tDebuffListContent[nIndex]
			if not tInfo then
				return
			end
			LR_TeamBuffSettingPanel.DelListDebuffGroup(handleSelected)
		end
		if IsShiftKeyDown() then
			DelHandle()
		else
			local msg = {
				szMessage = _L["Are you sure to delete?(press SHIFT to skip)"],
				szName = "del_debufflist_sure",
				fnAutoClose = function() return false end,
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() DelHandle() end, },
				{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
			}
			MessageBox(msg)
		end
		LR_TeamBuffSettingPanel.FormatDebuffNameList()
	end
end

function LR_TeamBuffSettingPanel.OpenPanel()
	local frame = Station.Lookup("Topmost/LR_TeamBuffSettingPanel")
	if not frame then
		frame = Wnd.OpenWindow(szIniFile, "LR_TeamBuffSettingPanel")
	end
	frame:Show()
end

function LR_TeamBuffSettingPanel.ClosePanel()
	local frame = Station.Lookup("Topmost/LR_TeamBuffSettingPanel")
	if frame then
		Wnd.CloseWindow(frame)
	end
	LR_TeamBuffSettingPanel.SaveCommonData()
end

-- ---------------------------------------------------------------
-- 配置文件处理
-- ---------------------------------------------------------------
function LR_TeamBuffSettingPanel.SaveSettings()
	local Recall = function(szText)
		if not szText or szText == "" then
			return
		end
		LR_TeamBuffSettingPanel.OutputSettingsFile(szText)
	end
	GetUserInput(_L["Enter Save File Name"], Recall, nil, function() end, nil, GetClientPlayer().szName, 31)
end

function LR_TeamBuffSettingPanel.OutputSettingsFile(szName)
	local player = GetClientPlayer()
	if not player then
		return
	end
	local szName = szName or player.szName
	local szMsg = LR_TeamBuffSettingPanel.tDebuffListContent
	local path = sformat("%s\\UsrData\\Data_%s.dat", SaveDataPath, szName)
	SaveLUAData(path,szMsg)
	LR.SysMsg(_L["Export Successful!"])
end

function LR_TeamBuffSettingPanel.LoadSettings()
	local Recall = function(szText)
		if not szText or szText == "" then
			return
		end
		LR_TeamBuffSettingPanel.LoadSettingsFile(szText)
	end
	GetUserInput(_L["Enter Load File Name"], Recall, nil, function() end, nil, GetClientPlayer().szName, 31)
end

function LR_TeamBuffSettingPanel.LoadSettingsFile(szText)
	local player = GetClientPlayer()
	if not player then
		return
	end
	local szName = szText or player.szName
	local szMsg = LR_TeamBuffSettingPanel.tDebuffListContent
	local path = sformat("%s\\UsrData\\Data_%s.dat", SaveDataPath, szName)
	if IsFileExist(sformat("%s.jx3dat", path)) then
		local t = LoadLUAData(path) or {}
		LR.SysMsg(_L["Import Successful!"])
		LR_TeamBuffSettingPanel.tDebuffListContent = t
		LR_TeamBuffSettingPanel.UpdateList()
	else
		LR.SysMsg(_L["No such file.\n"])
	end
end


----------------------------------------------------------------------------------
function LR_TeamBuffSettingPanel.SaveCommonData()
	local path = sformat("%s\\UsrData\\CommonBuffMonitorData.dat", SaveDataPath)
	local data = {}
	data.VERSION =VERSION
	data.data = clone(LR_TeamBuffSettingPanel.tDebuffListContent)
	SaveLUAData(path,data)
end

function LR_TeamBuffSettingPanel.LoadCommonData()
	local path = sformat("%s\\UsrData\\CommonBuffMonitorData.dat", SaveDataPath)
	local data = LoadLUAData(path) or {}
	if data.VERSION and data.VERSION == VERSION then
		LR_TeamBuffSettingPanel.tDebuffListContent = clone(data.data)
		LR_TeamBuffSettingPanel.FormatDebuffNameList()
	else
		local path2 = sformat("%s\\Script\\DefaultBuffMonitorData.dat", AddonPath)
		data2 = LoadLUAData(path2) or {}
		LR_TeamBuffSettingPanel.tDebuffListContent = clone(data2.data)
		LR_TeamBuffSettingPanel.FormatDebuffNameList()
		LR_TeamBuffSettingPanel.SaveCommonData()
	end
end

function LR_TeamBuffSettingPanel.LoadDefaultData()
	local path = sformat("%s\\Script\\DefaultBuffMonitorData.dat", AddonPath)
	local data = LoadLUAData(path) or {}
	LR_TeamBuffSettingPanel.tDebuffListContent = clone(data.data)
	LR_TeamBuffSettingPanel.SaveCommonData()
	LR_TeamBuffSettingPanel.FormatDebuffNameList()
end

function LR_TeamBuffSettingPanel.LOGIN_GAME()
	LR_TeamBuffSettingPanel.LoadCommonData()
	Log("[LR_TeamBuffSettingPanel] : LoadCommonBuffMonitorData")
end

LR.RegisterEvent("LOGIN_GAME",function() LR_TeamBuffSettingPanel.LOGIN_GAME() end)

----------------------------------------------------------------
----Debuff监控
----------------------------------------------------------------
LR_TeamBuffMonitor = {}
local _MemberBuff = {}		----用于存放成员的监控buff，缓存
local _hMemberBuff = {}	----用于存放监控buff的handleUI，缓存

function LR_TeamBuffMonitor.Check(MonitorBuff, nType)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local player = GetPlayer(MonitorBuff.dwPlayerID)
	if not player then
		return
	end
	local tBuffList = LR.GetBuffList(player)
	local buff, nEndFrame = {}, 0
	local bOnlySelf = MonitorBuff.bOnlySelf
	for k, v in pairs(tBuffList) do
		if v.dwID == MonitorBuff.dwID then
			if bOnlySelf then
				if v.dwSkillSrcID == me.dwID and v.nEndFrame > nEndFrame and (MonitorBuff.nLevel == 0 or v.nLevel == MonitorBuff.nLevel) then
					buff = clone(v)
					nEndFrame = v.nEndFrame
				end
			else
				if v.nEndFrame >nEndFrame and (MonitorBuff.nLevel == 0 or v.nLevel == MonitorBuff.nLevel) then
					buff = clone(v)
					nEndFrame = v.nEndFrame
				end
			end
		end
	end
	local hMemberBuff = _hMemberBuff[MonitorBuff.dwPlayerID] or {}
	if next(buff) == nil then
		if hMemberBuff[MonitorBuff.dwID] then
			hMemberBuff[MonitorBuff.dwID]:Remove()
			hMemberBuff[MonitorBuff.dwID]=nil
			MemberBuff = _MemberBuff[MonitorBuff.dwPlayerID] or {}
			for k, v in pairs (MemberBuff) do
				if v.dwID == MonitorBuff.dwID then
					MemberBuff[k] = {}
					--LR_TeamBuffMonitor.SortBuff(tBuff.dwPlayerID)
					return
				end
			end
		end
		return
	else
		buff.bOnlySelf = MonitorBuff.bOnlySelf
		buff.col = MonitorBuff.col
		buff.nIconID = MonitorBuff.nIconID
		buff.source = nType
		FireEvent("LR_RAID_BUFF_REC", MonitorBuff.dwPlayerID, buff)
		if nType == "JH_DBM" then
			JH_DBM_BUFF_LIST[buff.dwID] = clone(buff)
		end
	end
end

function LR_TeamBuffMonitor.SYS_MSG()
	if arg0 == "UI_OME_BUFF_LOG" then	--xx获得/失去xxbuff
		local dwTarget, bCanCancel, dwID, bAddOrDel, nLevel = arg1, arg2, arg3, arg4, arg5
		LR_TeamBuffMonitor.UI_OME_BUFF_LOG(dwTarget, bCanCancel, dwID, bAddOrDel, nLevel)
	end
end

function LR_TeamBuffMonitor.UI_OME_BUFF_LOG(dwTarget, bCanCancel, dwID, bAddOrDel, nLevel)
	if LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bOff then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local tBuff = {
		dwPlayerID = dwTarget,
		bDelete = not bAddOrDel,
		bCanCancel = bCanCancel,
		dwID = dwID,
		nLevel = nLevel,
	}
	if not IsPlayer(tBuff.dwPlayerID) then
		return
	end
	if not (tBuff.dwPlayerID == me.dwID or me.IsPlayerInMyParty(tBuff.dwPlayerID)) then
		return
	end
	local MonitorList = clone(LR_TeamBuffSettingPanel.BuffList) or {}
	local szBuffName = Table_GetBuffName(tBuff.dwID, tBuff.nLevel)
	if not (MonitorList[szBuffName] or MonitorList[tBuff.dwID] or JH_DBM_BUFF_LIST[tBuff.dwID] ) then
		return
	end
	if MonitorList[szBuffName] then
		if not Table_BuffIsVisible(tBuff.dwID, tBuff.nLevel) then
			return
		end
	end
	local MonitorBuff = MonitorList[szBuffName] or MonitorList[tBuff.dwID] or JH_DBM_BUFF_LIST[tBuff.dwID]
	MonitorBuff.szName = szBuffName
	MonitorBuff.dwID = tBuff.dwID
	MonitorBuff.dwPlayerID = tBuff.dwPlayerID

	LR_TeamBuffMonitor.Check(MonitorBuff, "LR_Team")
end

function LR_TeamBuffMonitor.BUFF_UPDATE()
	if LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bOff then
		return
	end
	local tBuff={
		dwPlayerID = arg0,
		bDelete  = arg1,
		nIndex = arg2,
		bCanCancel = arg3,
		dwID = arg4,
		nStackNum = arg5,
		nEndFrame = arg6,
		bInit = arg7,
		nLevel = arg8,
		dwSkillSrcID = arg9,
		isValid= arg10,
		nLeftFrame = arg11,
	}
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not IsPlayer(tBuff.dwPlayerID) then
		return
	end
	if not (tBuff.dwPlayerID == me.dwID or me.IsPlayerInMyParty(tBuff.dwPlayerID)) then
		return
	end
	local MonitorList = clone(LR_TeamBuffSettingPanel.BuffList) or {}
	local szBuffName = Table_GetBuffName(tBuff.dwID, tBuff.nLevel)
	if not (MonitorList[szBuffName] or MonitorList[dwID] or JH_DBM_BUFF_LIST[tBuff.dwID] ) then
		return
	end
	if MonitorList[szBuffName] then
		if not Table_BuffIsVisible(tBuff.dwID, tBuff.nLevel) then
			return
		end
	end
	local MonitorBuff = MonitorList[szBuffName] or MonitorList[dwID] or JH_DBM_BUFF_LIST[tBuff.dwID]
	MonitorBuff.szName = szBuffName
	MonitorBuff.dwID = tBuff.dwID
	MonitorBuff.dwPlayerID = tBuff.dwPlayerID

	LR_TeamBuffMonitor.Check(MonitorBuff, "LR_Team")
end

--arg0 = dwMemberID
--arg1 = {
	--dwID,
	--nLevel,
	--nLevelEx,
	--col,		颜色
	--nIcon,
	--bOnlySelf,
	--nStackNum
--}
function LR_TeamBuffMonitor.JH_RAID_REC_BUFF()
	if LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bOff then
		return
	end
	local tBuff={
		dwPlayerID = arg0,
		dwID = arg1.dwID or 0,
		bOnlySelf = arg1.bOnlySelf or false,
		nLevel = arg1.nLevel or 0,
		nLevelEx = arg1.nLevelEx,
		nIconID = arg1.nIcon or 0,
		col = arg1.col or {},
		nStackNum = arg1.nStackNum,
	}

	local me = GetClientPlayer()
	if not me then
		return
	end
	if not IsPlayer(tBuff.dwPlayerID) then
		return
	end
	if not (tBuff.dwPlayerID == me.dwID or me.IsPlayerInMyParty(tBuff.dwPlayerID)) then
		return
	end
	local MonitorBuff = tBuff

	LR_TeamBuffMonitor.Check(MonitorBuff, "JH_DBM")
end

function LR_TeamBuffMonitor.LR_RAID_BUFF_REC()
	local dwPlayerID = arg0
	local tBuff = arg1

	local MemberBuff = clone(_MemberBuff[dwPlayerID] or {})
	local BuffList = {}
	BuffList[1] = clone(tBuff)
	local bFound = false
	for i = 1, 4, 1 do
		MemberBuff[i] = MemberBuff[i] or {}
		if next(MemberBuff[i]) ~= nil and not bFound then
			if MemberBuff[i].dwID == tBuff.dwID then
				MemberBuff[i] = {}
				n = i
				bFound = true
			end
		end
	end

	local n = 2
	for i = 1, 4, 1 do
		MemberBuff[i] = MemberBuff[i] or {}
		if next(MemberBuff[i]) ~= nil then
			BuffList[n] = clone(MemberBuff[i])
			n = n + 1
		elseif i >= n then
			BuffList[n] = clone(MemberBuff[i])
			n = n + 1
		end
	end
	local buffMonitorNum = LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.buffMonitorNum
	for i = buffMonitorNum + 1, #BuffList, 1 do
		BuffList[i]=nil
	end

	_MemberBuff[dwPlayerID] = clone(BuffList)
	LR_TeamBuffMonitor.RedrawBuffBox(dwPlayerID)
end

function LR_TeamBuffMonitor.RefreshBuff()
	for dwMemberID , v in pairs(_hMemberBuff) do
		if next(v) ~= nil then
			for dwID , v2 in pairs(v) do
				if v2:GetEndFrame() < GetLogicFrameCount() then
					v2:Remove()
					v[dwID] = nil
					for k3, v3 in pairs (_MemberBuff[dwMemberID]) do
						if v3.dwID == dwID then
							_MemberBuff[dwMemberID][k3] = {}
						end
					end
					--LR_TeamBuffMonitor.SortBuff(dwMemberID)
				else
					v2:Draw()
				end
			end
		end
	end
end

function LR_TeamBuffMonitor.RedrawBuffBox(dwPlayerID)
	local newTable = {}
	MemberBuff = _MemberBuff[dwPlayerID] or {}
	for k, v in pairs (MemberBuff) do
		if next(v) ~= nil then
			newTable[v.dwID] = clone(v)
			newTable[v.dwID].nOrder = k
		end
	end
	local BuffHandle = LR_TeamGrid.GetRoleGridBuffHandle(dwPlayerID)
	_hMemberBuff[dwPlayerID] = _hMemberBuff[dwPlayerID] or {}
	local hMemberBuff = _hMemberBuff[dwPlayerID] or {}

	if BuffHandle then
		for dwID, v in pairs(hMemberBuff) do
			local v2 = newTable[dwID]
			if v2 then
				v:SetOrder(v2.nOrder):SetSize():SetRelPos()
				if v2.nEndFrame ~= v:GetEndFrame() then
					v:SetStartFrame()
				end
				v:SetBuff(v2):SetIcon():Show()
			else
				v:Remove()
				hMemberBuff[dwID] = nil
			end
		end
		for dwID, v in pairs(newTable) do
			local v2 = hMemberBuff[dwID]
			if not v2 then
				local h = _BuffBox:new(v.dwID, BuffHandle, v):Create()
				h:SetBuff(v):SetOrder(v.nOrder):SetStartFrame():SetEndFrame(v.nEndFrame):SetIcon():SetSize():SetRelPos():Show()
				hMemberBuff[dwID] = h
			end
		end
		BuffHandle:FormatAllItemPos()
	end
end

function LR_TeamBuffMonitor.ClearAllCache()
	local MemberBuff = clone(_MemberBuff)
	_hMemberBuff={}
	_MemberBuff={}
	for dwID, v in pairs(MemberBuff) do
		local BuffHandle = LR_TeamGrid.GetRoleGridBuffHandle(dwID)
		if BuffHandle then
			BuffHandle:Clear()
		end
	end
end

function LR_TeamBuffMonitor.ClearOneCache(dwID)
	_hMemberBuff[dwID]=nil
	_MemberBuff[dwID]=nil
	local BuffHandle = LR_TeamGrid.GetRoleGridBuffHandle(dwID)
	if BuffHandle then
		BuffHandle:Clear()
	end
end

function LR_TeamBuffMonitor.ClearhMemberBuff()
	_hMemberBuff={}
end

function LR_TeamBuffMonitor.SortBuff(dwPlayerID)
	local MemberBuff = _MemberBuff[dwPlayerID] or {}
	local BuffList = {}
	for i=1,4 do
		if MemberBuff[i] then
			BuffList[#BuffList+1] = clone(MemberBuff[i])
		end
	end
	local buffMonitorNum = LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.buffMonitorNum
	for i=buffMonitorNum+1,#BuffList do
		BuffList[i]=nil
	end
	local hMemberBuff = _hMemberBuff[dwPlayerID] or {}
	local BuffHandle = LR_TeamGrid.GetRoleGridBuffHandle(dwPlayerID)
	if BuffHandle then
		for k, v in pairs(BuffList) do
			local h = hMemberBuff[v.dwID]
			if h then
				h:SetOrder(k):SetRelPos()
			end
		end
		BuffHandle:FormatAllItemPos()
	end
end

LR.RegisterEvent("LR_RAID_BUFF_REC", function() LR_TeamBuffMonitor.LR_RAID_BUFF_REC() end)
