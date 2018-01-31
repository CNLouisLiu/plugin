local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local VERSION = "20170921"
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_RaidGridEx"
local SaveDataPath="Interface\\LR_Plugin@DATA\\LR_TeamGrid"
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
	o.parentHandle = BuffHandle:GetHandle()
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
	handle:Lookup("Text_LeftTime"):SetText("")
	handle:Lookup("Text_BuffStacks"):SetText("")
	return self
end

function _BuffBox:Remove()
	local parentHandle = self.parentHandle
	local dwID = self.dwID
	local handle = parentHandle:Lookup(sformat("Handle_BuffBox_%d", dwID))
	if handle then
		parentHandle:RemoveItem(handle)
	end
	if self.tBuff.bSpecialBuff then
		parentHandle:Lookup("Shadow_SpecialBuffBg"):Hide()
	end
	return self
end

function _BuffBox:GetBuffnIndex()
	return self.tBuff.nIndex
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
	if self.tBuff.bSpecialBuff then
		height = UIConfig.specialBuff["BuffBox"].height * fp
		width = UIConfig.specialBuff["BuffBox"].width * fp
	end
	local border = LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffShadow.nBorder or 0
	local handle = self.handle
	handle:Lookup("Box"):SetSize(width, height)
	handle:Lookup("Box2"):SetSize(width, height)
	handle:Lookup("Shadow_Color"):SetSize(width + border * 2, height + border * 2)
	handle:Lookup("Shadow_Color"):SetRelPos(-border, -border)
	handle:Lookup("Text_BuffStacks"):SetSize(width, height)
	handle:Lookup("Text_LeftTime"):SetSize(width, height)
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
	if self.tBuff.bSpecialBuff then
		top = UIConfig.specialBuff["BuffBox"].top * fy
		left = UIConfig.specialBuff["BuffBox"].left * fx
	end
	local handle = self.handle
	local parentHandle = self.parentHandle
	handle:SetRelPos(left, top)
	handle:FormatAllItemPos()
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
	local Text_LeftTime = handle:Lookup("Text_LeftTime")
	local UIConfig = LR_TeamGrid.UIConfig
	local nOrder = self.nOrder
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local fp = mmin(fx, fy)
	local height = UIConfig.handleBuffBox[nOrder].height
	local width = UIConfig.handleBuffBox[nOrder].width
	if self.tBuff.bSpecialBuff then
		height = UIConfig.specialBuff["BuffBox"].height * fp
		width = UIConfig.specialBuff["BuffBox"].width * fp
	end
	local n = mmin(height, width) * mmin(fx, fy)
	local fp = n / 16
	Text_BuffStacks:SetFontScheme(15)
	Text_BuffStacks:SetSize(height, width)
	Text_BuffStacks:SetVAlign(0)
	Text_BuffStacks:SetHAlign(0)
	Text_LeftTime:SetFontScheme(15)
	Text_LeftTime:SetSize(height, width)
	Text_LeftTime:SetVAlign(2)
	Text_LeftTime:SetHAlign(2)
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
	local UIConfig = LR_TeamGrid.UIConfig
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

	local Text_LeftTime = handle:Lookup("Text_LeftTime")
	Text_LeftTime:SetFontScheme(7)
	Text_LeftTime:SetAlpha(180)
	Text_LeftTime:SetFontScale(UIConfig.handleBuff.fontscale or 0.9)
	Text_LeftTime:SetHAlign(2)
	Text_LeftTime:SetVAlign(2)
	Text_LeftTime:SetFontColor(255, 255, 0)

	local w, h = box:GetSize()
	if LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bShowLeftTime then
		if nLeftFrame / 16 < 10 then
			Text_LeftTime:SprintfText("%0.0f", mfloor(nLeftFrame / 16) )
			Text_LeftTime:Show()
			if nLeftFrame / 16 <=3 then
				Text_LeftTime:SetFontColor(237, 168, 168)
			elseif nLeftFrame / 16 < 6 then
				Text_LeftTime:SetFontColor(255, 255, 128)
			else
				Text_LeftTime:SetFontColor(255, 255, 255)
			end
		else
			Text_LeftTime:Hide()
		end
	else
		Text_LeftTime:Hide()
	end

	local Text_BuffStacks = handle:Lookup("Text_BuffStacks")
	Text_BuffStacks:SetFontScheme(7)
	Text_BuffStacks:SetAlpha(180)
	Text_BuffStacks:SetFontScale(UIConfig.handleBuff.fontscale or 0.9)
	Text_BuffStacks:SetHAlign(0)
	Text_BuffStacks:SetVAlign(0)
	Text_BuffStacks:SetFontColor(255, 255, 0)
	if LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bShowStack then
		if self.tBuff.nStackNum and self.tBuff.nStackNum > 1 then
			Text_BuffStacks:SetText(self.tBuff.nStackNum)
			Text_BuffStacks:SetFontColor(255, 255, 255)
		else
			Text_BuffStacks:SetText("")
		end
		Text_BuffStacks:Show()
	else
		Text_BuffStacks:Hide()
	end

	if self.tBuff.bSpecialBuff then
		sha:SetColorRGB(0, 0, 0)
		local color = self.tBuff.col
		if next(self.tBuff.col) == nil then
			color = {127, 18, 127}
		end
		local parentHandle = self.parentHandle
		parentHandle:Lookup("Shadow_SpecialBuffBg"):SetColorRGB(unpack(color))
		parentHandle:Lookup("Shadow_SpecialBuffBg"):Show()
	end

	return self
end

----------------------------------------------------------------
----边角指示器buff
----------------------------------------------------------------
local _EDGEINDICATOR_BUFF_CACHE = {}
local _EDGEINDICATOR_BUFF_HANDLE_CACHE = {}
local _EDGEINDICATOR_BUFF_SHOW = {}

LR_TeamEdgeIndicator = {}
local EdgeIndicatorDefaultData = {
	["TopLeft"] = {
		style = 0,
		buff = {dwID = 0, szName = "", bOnlySelf = true,},
	},
	["TopRight"] = {
		style = 0,
		buff = {dwID = 0, szName = "", bOnlySelf = true,},
	},
	["BottomLeft"] = {
		style = 0,
		buff = {dwID = 0, szName = "", bOnlySelf = false,},
	},
	["BottomRight"] = {
		style = 0,
		buff = {dwID = 0, szName = "", bOnlySelf = false,},
	},
	["yellow"] = 0.5,
	["red"] = 3,
}
LR_TeamEdgeIndicator.UsrData = clone(EdgeIndicatorDefaultData)
RegisterCustomData("LR_TeamEdgeIndicator.UsrData", VERSION)

function LR_TeamEdgeIndicator.add2bufflist()
	local MonitorList = LR_TeamBuffSettingPanel.BuffList
	local szEdge = {"TopLeft", "TopRight", "BottomLeft", "BottomRight"}
	for k, v in pairs(szEdge) do
		if LR_TeamEdgeIndicator.UsrData[v].style == 1 then
			if LR_TeamEdgeIndicator.UsrData[v].buff.dwID and LR_TeamEdgeIndicator.UsrData[v].buff.dwID > 0 then
				local dwID = LR_TeamEdgeIndicator.UsrData[v].buff.dwID
				if MonitorList[sformat("%d", dwID)] then
					if not MonitorList[sformat("%d", dwID)].bSpecialBuff then
						MonitorList[sformat("%d", dwID)].bEdgeIndicator = true
						MonitorList[sformat("%d", dwID)].edge = v
						MonitorList[sformat("%d", dwID)].bOnlySelf = LR_TeamEdgeIndicator.UsrData[v].buff.bOnlySelf
					end
				else
					local buff = {dwID = nil, szName = nil, bOnlySelf = false, bEdgeIndicator = true, col = {}, nIconID = 0, nMonitorLevel = 0, edge = v, nMonitorStack = 0, bSpecialBuff = false,}
					buff.dwID = LR_TeamEdgeIndicator.UsrData[v].buff.dwID
					buff.bOnlySelf = LR_TeamEdgeIndicator.UsrData[v].buff.bOnlySelf
					MonitorList[sformat("%d", dwID)] = clone(buff)
				end
			else
				local buff = {dwID = nil, szName = nil, bOnlySelf = false, bEdgeIndicator = true, col = {}, nIconID = 0, nMonitorLevel = 0, edge = v, nMonitorStack = 0, bSpecialBuff = false,}
				buff.szName = LR_TeamEdgeIndicator.UsrData[v].buff.szName
				buff.bOnlySelf = LR_TeamEdgeIndicator.UsrData[v].buff.bOnlySelf
				MonitorList[buff.szName] = clone(buff)
			end
		end
	end
end

function LR_TeamEdgeIndicator.RefreshEdgeIndicator()
	for dwPlayerID, v in pairs(_EDGEINDICATOR_BUFF_HANDLE_CACHE) do
		for edge, v2 in pairs(v) do
			if next(v2) ~= nil then
				local nStartFrame = v2.nStartFrame
				local nEndFrame = v2.nEndFrame
				local nNowFrame = GetLogicFrameCount()
				if nNowFrame > nEndFrame then
					v2.hShadow:Hide()
					v2.hShadowBg:Hide()
					v2 = {}
				else
					if (nEndFrame - nNowFrame) < 3 * 16 then
						v2.hShadow:SetColorRGB(255, 0, 128)
					elseif (nEndFrame - nNowFrame) / (nEndFrame - nStartFrame) < 0.5 then
						v2.hShadow:SetColorRGB(255, 255, 0)
					else
						v2.hShadow:SetColorRGB(34, 177, 76)
					end
					v2.hShadow:Show()
					v2.hShadowBg:Show()
				end
			end
		end
	end
end

function LR_TeamEdgeIndicator.ClearEdgeIndicatorCache(dwID)
	if dwID then
		_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwID] = {}
	else
		_EDGEINDICATOR_BUFF_HANDLE_CACHE = {}
	end
end

function LR_TeamEdgeIndicator.ClearOneEdgeIndicatorCache(dwID)
	_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwID] = {}
end

LR.RegisterEvent("FIRST_LOADING_END", function() LR_TeamEdgeIndicator.add2bufflist() end)

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
LR_TeamBuffSettingPanel.TeamMember = {}  --存放队友数据

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

LR_TeamBuffSettingPanel.BuffList = {}


-- 格式化Debuff表的数据, 成为直接可用的内容
function LR_TeamBuffSettingPanel.FormatDebuffNameList2()
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
			szContent = sgsub(szContent, "c", "C")
			szContent = sgsub(szContent, "s", "S")
			szContent = sgsub(szContent, "l", "L")
			szContent = sformat("%s;", szContent)
			local t={}
			for s in sgfind(szContent, "(.-);") do
				if s ~= "" then
					t[#t + 1] = s
				end
			end

			for i = 1, #t, 1 do
				local buff = {dwID = 0, szName = "", col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,}
				local text = t[i]

				local _s, _e, bSelf = sfind(text, "%[(.-)%]")
				if bSelf and bSelf == _L["self"] then
					buff.bOnlySelf = true
				end
				text = sgsub(text, "%[(.-)%]", "")

				local _s, _e, bSpecialBuff = sfind(text, "%(S(.-)%)")
				if bSpecialBuff then
					buff.bSpecialBuff = true
				end
				text = sgsub(text, "%(S(.-)%)", "")

				local _s, _e, nMonitorStack = sfind(text, "%(C(.-)%)")
				if nMonitorStack then
					local _s, _e, s = sfind(nMonitorStack, "(%d+)")
					buff.nMonitorStack = tonumber(s)
				end
				text = sgsub(text, "%(C(.-)%)", "")

				local _s, _e, nMonitorLevel = sfind(text, "%(L(.-)%)")
				if nMonitorLevel then
					local _s, _e, s = sfind(nMonitorLevel, "(%d+)")
					buff.nMonitorLevel = tonumber(s)
				end
				text = sgsub(text, "%(L(.-)%)", "")

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
				buff.bEdgeIndicator = false

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
	LR_TeamEdgeIndicator.add2bufflist()
end

function LR_TeamBuffSettingPanel.FormatDebuffNameList()
	local tBuff = {}
	for szGroupName, tGroupData in pairs(LR_TeamBuffTool.tBuffList) do
		if type(tGroupData) == "table" then
			if tGroupData.enable then
				for k, buff in pairs(tGroupData.data) do
					if buff.enable then
						if buff.nMonitorLevel > 0 then
							local szKey = sformat("%d_L%d", buff.dwID, buff.nMonitorLevel)
							tBuff[szKey] = clone(buff)
						else
							local szKey = sformat("%d", buff.dwID)
							tBuff[szKey] = clone(buff)
						end
					end
				end
			end
		end
	end
	LR_TeamBuffSettingPanel.BuffList = clone(tBuff)
	LR_TeamEdgeIndicator.add2bufflist()
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
---公共文件
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

local JH_DBM_BUFF_LIST = {}	---用于存放DBM过来的BUFF数据
----------------------------------------------------------------
----一般BUFF
----------------------------------------------------------------
local _NORMAL_BUFF_CACHE = {}	--用于存放所有普通BUFF缓存
local _NORMAL_BUFF_HANDLE_CACHE = {}	----用于存放监控普通BUFF的handleUI，缓存
local _NORMAL_BUFF_SHOW = {}		----用于存放显示中的成员的普通BUFF，缓存
----------------------------------------------------------------
----一般BUFF
----------------------------------------------------------------
local _SPECIAL_BUFF_CACHE = {}	--用于存放所有特殊BUFF缓存
local _SPECIAL_BUFF_HANDLE_CACHE = {}	----用于存放监控特殊BUFF的handleUI，缓存
local _SPECIAL_BUFF_SHOW = {}		----用于存放显示中的成员的特殊BUFF，缓存
----------------------------------------------------------------
----Debuff监控
----------------------------------------------------------------
LR_TeamBuffMonitor = {}
local BUFF_REFRESH_LIST = {}  	--用于存放UI_OME_BUFF_LOG刷新的buff缓存数据
local BUFF_NAME = {}

local checktime = 0
function LR_TeamBuffMonitor.GetBuffName(dwID, nLevel)
	if not BUFF_NAME[dwID] then
		BUFF_NAME[dwID] = LR.Trim(Table_GetBuffName(dwID, nLevel))
		if BUFF_NAME[dwID] == "" then
			BUFF_NAME[dwID] = sformat("#%d", dwID)
		end
	end
	return BUFF_NAME[dwID]
end

function LR_TeamBuffMonitor.SpecialBuffCheck2(MonitorBuff)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local player = GetPlayer(MonitorBuff.dwPlayerID)
	if not player then
		return
	end

	_SPECIAL_BUFF_CACHE[MonitorBuff.dwPlayerID] = _SPECIAL_BUFF_CACHE[MonitorBuff.dwPlayerID]  or {}
	_SPECIAL_BUFF_CACHE[MonitorBuff.dwPlayerID][MonitorBuff.dwID] = _SPECIAL_BUFF_CACHE[MonitorBuff.dwPlayerID][MonitorBuff.dwID] or {}
	local cache = _SPECIAL_BUFF_CACHE[MonitorBuff.dwPlayerID][MonitorBuff.dwID]

	local tBuffList = LR.GetBuffList(player)
	local _nIndex, _nEndFrame = 0, 0
	local bOnlySelf = MonitorBuff.bOnlySelf
	for k, v in pairs(tBuffList) do
		if v.dwID == MonitorBuff.dwID then
			if bOnlySelf then
				if v.dwSkillSrcID == me.dwID and (MonitorBuff.nMonitorLevel == 0 or v.nLevel == MonitorBuff.nLevel) then
					local buff = clone(v)
					buff.dwCaster = v.dwSkillSrcID
					buff.bOnlySelf = MonitorBuff.bOnlySelf or false
					buff.col = MonitorBuff.col or {}
					buff.nIconID = MonitorBuff.nIconID or 0
					buff.bSpecialBuff = MonitorBuff.bSpecialBuff or false
					buff.bEdgeIndicator = MonitorBuff.bEdgeIndicator or false
					buff.nMonitorLevel = MonitorBuff.nMonitorLevel or 0
					buff.nMonitorStack = MonitorBuff.nMonitorStack or 0
					cache[v.nIndex] = clone(buff)
					FireEvent("LR_SPECIAL_BUFF_ADD_FRESH", MonitorBuff.dwPlayerID, buff)
					return
				end
			else
				if MonitorBuff.nMonitorLevel == 0 or v.nLevel == MonitorBuff.nLevel then
					cache[v.nIndex] = clone(v)
					cache[v.nIndex].dwCaster = v.dwSkillSrcID
					if v.nEndFrame > _nEndFrame then
						_nIndex = v.nIndex
						_nEndFrame = v.nEndFrame
					end
				end
			end
		end
	end

	if _nIndex == 0 then
		FireEvent("LR_SPECIAL_BUFF_DELETE", MonitorBuff.dwPlayerID, MonitorBuff)
		return
	else
		local buff = cache[_nIndex]
		buff.bOnlySelf = MonitorBuff.bOnlySelf or false
		buff.bSpecialBuff = MonitorBuff.bSpecialBuff or false
		buff.col = MonitorBuff.col or {}
		buff.nIconID = MonitorBuff.nIconID or 0
		FireEvent("LR_SPECIAL_BUFF_ADD_FRESH", MonitorBuff.dwPlayerID, buff)
	end
end

function LR_TeamBuffMonitor.EdgeBuffCheck2(MonitorBuff)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local player = GetPlayer(MonitorBuff.dwPlayerID)
	if not player then
		return
	end

	_EDGEINDICATOR_BUFF_CACHE[dwPlayerID] = _EDGEINDICATOR_BUFF_CACHE[dwPlayerID] or {}
	_EDGEINDICATOR_BUFF_CACHE[dwPlayerID][dwID] = _EDGEINDICATOR_BUFF_CACHE[dwPlayerID][dwID] or {}
	local cache = _EDGEINDICATOR_BUFF_CACHE[dwPlayerID][dwID]

	local tBuffList = LR.GetBuffList(player)
	local _nIndex, _nEndFrame = 0, 0
	local bOnlySelf = MonitorBuff.bOnlySelf
	for k, v in pairs(tBuffList) do
		if v.dwID == MonitorBuff.dwID then
			if bOnlySelf then
				if v.dwSkillSrcID == me.dwID and (MonitorBuff.nMonitorLevel == 0 or v.nLevel == MonitorBuff.nLevel) then
					local buff = clone(v)
					buff.dwCaster = v.dwSkillSrcID
					buff.bOnlySelf = MonitorBuff.bOnlySelf or false
					buff.bEdgeIndicator = MonitorBuff.bEdgeIndicator
					buff.edge = MonitorBuff.edge
					buff.bSpecialBuff = MonitorBuff.bSpecialBuff or false
					buff.nStartFrame = GetLogicFrameCount()

					cache[v.nIndex] = clone(buff)
					FireEvent("LR_RAID_EDGE_ADD_FRESH", MonitorBuff.dwPlayerID, buff)
					return
				end
			else
				if MonitorBuff.nMonitorLevel == 0 or v.nLevel == MonitorBuff.nLevel then
					v.bEdgeIndicator = MonitorBuff.bEdgeIndicator
					v.edge = MonitorBuff.edge
					v.bSpecialBuff = MonitorBuff.bSpecialBuff or false
					cache[v.nIndex] = clone(v)
					cache[v.nIndex].dwCaster = v.dwSkillSrcID
					if v.nEndFrame > _nEndFrame then
						_nIndex = v.nIndex
						_nEndFrame = v.nEndFrame
					end
				end
			end
		end
	end

	if _nIndex == 0 then
		FireEvent("LR_RAID_EDGE_DELETE", MonitorBuff.dwPlayerID, MonitorBuff)
		return
	else
		local buff = cache[_nIndex]
		buff.bOnlySelf = MonitorBuff.bOnlySelf or false
		buff.bEdgeIndicator = MonitorBuff.bEdgeIndicator
		buff.edge = MonitorBuff.edge
		buff.bSpecialBuff = MonitorBuff.bSpecialBuff or false
		FireEvent("LR_RAID_EDGE_ADD_FRESH", MonitorBuff.dwPlayerID, buff)
	end
end

function LR_TeamBuffMonitor.NormalBuffCheck2(MonitorBuff)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local player = GetPlayer(MonitorBuff.dwPlayerID)
	if not player then
		return
	end

	_NORMAL_BUFF_CACHE[MonitorBuff.dwPlayerID] = _NORMAL_BUFF_CACHE[MonitorBuff.dwPlayerID]  or {}
	_NORMAL_BUFF_CACHE[MonitorBuff.dwPlayerID][MonitorBuff.dwID] = _NORMAL_BUFF_CACHE[MonitorBuff.dwPlayerID][MonitorBuff.dwID] or {}
	local cache = _NORMAL_BUFF_CACHE[MonitorBuff.dwPlayerID][MonitorBuff.dwID]

	local tBuffList = LR.GetBuffList(player)
	local _nIndex, _nEndFrame = 0, 0
	local bOnlySelf = MonitorBuff.bOnlySelf
	for k, v in pairs(tBuffList) do
		if v.dwID == MonitorBuff.dwID then
			if bOnlySelf then
				if v.dwSkillSrcID == me.dwID and (MonitorBuff.nMonitorLevel == 0 or v.nLevel == MonitorBuff.nLevel) then
					local buff = clone(v)
					buff.dwCaster = v.dwSkillSrcID
					buff.bOnlySelf = MonitorBuff.bOnlySelf or false
					buff.col = MonitorBuff.col or {}
					buff.nIconID = MonitorBuff.nIconID or 0
					cache[v.nIndex] = clone(buff)
					FireEvent("LR_RAID_BUFF_ADD_FRESH", MonitorBuff.dwPlayerID, buff)
					return
				end
			else
				if MonitorBuff.nMonitorLevel == 0 or v.nLevel == MonitorBuff.nLevel then
					cache[v.nIndex] = clone(v)
					cache[v.nIndex].dwCaster = v.dwSkillSrcID
					if v.nEndFrame > _nEndFrame then
						_nIndex = v.nIndex
						_nEndFrame = v.nEndFrame
					end
				end
			end
		end
	end

	if _nIndex == 0 then
		FireEvent("LR_RAID_BUFF_DELETE", MonitorBuff.dwPlayerID, MonitorBuff)
		return
	else
		local buff = cache[_nIndex]
		buff.bOnlySelf = MonitorBuff.bOnlySelf or false
		buff.bSpecialBuff = MonitorBuff.bSpecialBuff or false
		buff.col = MonitorBuff.col or {}
		buff.nIconID = MonitorBuff.nIconID or 0
		FireEvent("LR_RAID_BUFF_ADD_FRESH", MonitorBuff.dwPlayerID, buff)
	end
end

function LR_TeamBuffMonitor.ReCheck(dwPlayerID, dwID, szKey)
	BUFF_REFRESH_LIST[dwPlayerID] = BUFF_REFRESH_LIST[dwPlayerID] or {}
	BUFF_REFRESH_LIST[dwPlayerID][dwID] = BUFF_REFRESH_LIST[dwPlayerID][dwID] or {}
	local tBuff = BUFF_REFRESH_LIST[dwPlayerID][dwID]
	local n = 1
	while tBuff[n] do
		if tBuff[n].szKey == szKey then
			--Output("Fix", Table_GetBuffName(tBuff[n].dwID, tBuff[n].nLevel))
			if tBuff[n].bSpecialBuff then
				LR_TeamBuffMonitor.SpecialBuffCheck2(tBuff[n])
			elseif tBuff[n].bEdgeIndicator then
				LR_TeamBuffMonitor.EdgeBuffCheck2(tBuff[n])
			else
				LR_TeamBuffMonitor.NormalBuffCheck2(tBuff[n])
			end
			Log("LR_TEAM_BUFF_MONITOR_FIX\n")
			tremove(tBuff, n)
		end
		n = n +1
	end
end

function LR_TeamBuffMonitor.UI_OME_BUFF_LOG(dwTarget, bCanCancel, dwID, bAddOrDel, nLevel)
	local me = GetClientPlayer()

	if LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bOff then
		return
	end
	--去除不在buff监控中的
	local MonitorList = LR_TeamBuffSettingPanel.BuffList
	local szBuffName = LR_TeamBuffMonitor.GetBuffName(dwID, nLevel)

	local MonitorBuff = nil
	if MonitorList[szBuffName] then
		MonitorBuff = clone(MonitorList[szBuffName])
	elseif MonitorList[sformat("%d_L%d", dwID, nLevel)] then
		MonitorBuff = clone(MonitorList[sformat("%d_L%d", dwID, nLevel)])
	elseif MonitorList[sformat("%d", dwID)] then
		MonitorBuff = clone(MonitorList[sformat("%d", dwID)])
	end
	if not MonitorBuff then
		return
	end

--[[	if not MonitorList[dwID] then
		--local szBuffName = LR_TeamBuffMonitor.GetBuffName(dwID, nLevel)
		if not MonitorList[szBuffName] then
			return
		end
		if not Table_BuffIsVisible(dwID, nLevel) then
			return
		end
		MonitorList[dwID] = clone(MonitorList[szBuffName])
		MonitorList[szBuffName] = nil
	else
		if MonitorList[dwID] and MonitorList[szBuffName] then
			if MonitorList[szBuffName].bEdgeIndicator then
				MonitorList[dwID].bEdgeIndicator = MonitorList[szBuffName].bEdgeIndicator
				MonitorList[dwID].edge = MonitorList[szBuffName].edge
			end
			MonitorList[szBuffName] = nil
		end
	end]]
	--去除不在队伍里的
	if not (LR_TeamBuffSettingPanel.TeamMember[dwTarget] or me.IsPlayerInMyParty(dwTarget)) then
		return
	end
	LR_TeamBuffSettingPanel.TeamMember[dwTarget] = true
	--加入log列表
	local n = 1
	local szKey = sformat("%d_%d_%d", dwTarget, dwID, n)
	local nTime = GetTime()
	BUFF_REFRESH_LIST[dwTarget] = BUFF_REFRESH_LIST[dwTarget] or {}
	BUFF_REFRESH_LIST[dwTarget][dwID] = BUFF_REFRESH_LIST[dwTarget][dwID] or {}
	local tBuff = BUFF_REFRESH_LIST[dwTarget][dwID]
	while tBuff[n] do  --and (tBuff[n].dwPlayerID ~= dwTarget or (mabs(tBuff[n].nTime - nTime) > 100) ) do
		n = n + 1
		szKey = sformat("%d_%d_%d", dwTarget, dwID, n)
	end
	--Output("1", szKey, BUFF_REFRESH_LIST[szKey])

	local buff = {}
	buff.dwPlayerID = dwTarget
	buff.bDelete = (bAddOrDel == 0)
	buff.bCanCancel = bCanCancel
	buff.dwID = dwID
	buff.nLevel = nLevel
	buff.receivedFromLOG = true
	buff.DelayCallKey = sformat("%s_%d", szKey, nTime)
	buff.nTime = nTime
	buff.szKey = szKey

	buff.bOnlySelf = MonitorBuff.bOnlySelf or false
	buff.nMonitorLevel = MonitorBuff.nMonitorLevel or 0
	buff.col = MonitorBuff.col or {}
	buff.nIconID = MonitorBuff.nIconID or 0
	buff.bEdgeIndicator = MonitorBuff.bEdgeIndicator or false
	buff.edge = MonitorBuff.edge or ""
	buff.bSpecialBuff = MonitorBuff.bSpecialBuff or false
	tBuff.bShowUnderStack = MonitorBuff.bSpecialBuff or false

	if not tBuff[n] then
		tinsert(tBuff, buff)
		LR.DelayCall(150, function() LR_TeamBuffMonitor.ReCheck(dwTarget, dwID, szKey) end, buff.DelayCallKey)
	end
end

--[[
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
]]
function LR_TeamBuffMonitor.BUFF_UPDATE2()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bOff then
		return
	end

	local dwPlayerID, bDelete, nIndex, bCanCancel, dwID, nStackNum, nEndFrame, bInit, nLevel, dwCaster, IsValid, nLeftFrame = arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11
	--去除不在监控buff里的
	local MonitorList = LR_TeamBuffSettingPanel.BuffList
	local szBuffName = LR_TeamBuffMonitor.GetBuffName(dwID, nLevel)

	local MonitorBuff = nil
	if MonitorList[szBuffName] then
		MonitorBuff = clone(MonitorList[szBuffName])
	elseif MonitorList[sformat("%d_L%d", dwID, nLevel)] then
		MonitorBuff = clone(MonitorList[sformat("%d_L%d", dwID, nLevel)])
	elseif MonitorList[sformat("%d", dwID)] then
		MonitorBuff = clone(MonitorList[sformat("%d", dwID)])
	end
	if not MonitorBuff then
		return
	end

--[[	if not MonitorList[dwID] then
		--local szBuffName = LR_TeamBuffMonitor.GetBuffName(dwID, nLevel)
		if not MonitorList[szBuffName] then
			return
		end
		if not Table_BuffIsVisible(dwID, nLevel) then
			return
		end
		MonitorList[dwID] = clone(MonitorList[szBuffName])
		MonitorList[szBuffName] = nil
	else
		if MonitorList[dwID] and MonitorList[szBuffName] then
			if MonitorList[szBuffName].bEdgeIndicator then
				MonitorList[dwID].bEdgeIndicator = MonitorList[szBuffName].bEdgeIndicator
				MonitorList[dwID].edge = MonitorList[szBuffName].edge
			end
			if MonitorList[szBuffName].bSpecialBuff then
				MonitorList[dwID].bSpecialBuff = MonitorList[szBuffName].bSpecialBuff
			end
			MonitorList[szBuffName] = nil
		end
	end]]

	--去除buff刷新对象不在队里的
	if not (LR_TeamBuffSettingPanel.TeamMember[dwPlayerID] or me.IsPlayerInMyParty(dwPlayerID)) then
		return
	end
	LR_TeamBuffSettingPanel.TeamMember[dwPlayerID] = true

	--去除Log监控数据
	BUFF_REFRESH_LIST[dwPlayerID] = BUFF_REFRESH_LIST[dwPlayerID] or {}
	BUFF_REFRESH_LIST[dwPlayerID][dwID] = BUFF_REFRESH_LIST[dwPlayerID][dwID] or {}
	local tBuffFreshList = BUFF_REFRESH_LIST[dwPlayerID][dwID]
	if next(tBuffFreshList) ~= nil then
		LR.UnDelayCall(tBuffFreshList[1].DelayCallKey)
		tremove(tBuffFreshList, 1)
	end
	--Output("xx2", tBuffFreshList)
	--如果只监控自己而不是自己的返回
	if MonitorBuff.bOnlySelf and dwCaster ~= me.dwID then
		return
	end

	local tBuff = {
		dwPlayerID = dwPlayerID,
		bDelete = bDelete,
		nIndex = nIndex,
		bCanCancel = bCanCancel,
		dwID = dwID,
		nStackNum = nStackNum,
		nEndFrame = nEndFrame,
		bInit = bInit,
		nLevel = nLevel,
		dwCaster = dwCaster,
		IsValid = IsValid,
		nLeftFrame = nLeftFrame,
	}
	tBuff.bOnlySelf = MonitorBuff.bOnlySelf or false
	tBuff.col = MonitorBuff.col or {}
	tBuff.nIconID = MonitorBuff.nIconID or 0
	tBuff.nMonitorLevel = MonitorBuff.nMonitorLevel or 0
	tBuff.nMonitorStack = MonitorBuff.nMonitorStack or 0
	tBuff.bEdgeIndicator = MonitorBuff.bEdgeIndicator or false
	tBuff.edge = MonitorBuff.edge or ""
	tBuff.bSpecialBuff = MonitorBuff.bSpecialBuff or false
	tBuff.bShowUnderStack = MonitorBuff.bSpecialBuff or false

	if tBuff.bSpecialBuff and tBuff.bShowUnderStack and tBuff.nStackNum < tBuff.nMonitorStack then
		tBuff.bSpecialBuff = false
		tBuff.nMonitorStack = 0
	end

	if tBuff.bSpecialBuff then
		LR_TeamBuffMonitor.BUFF_UPDATE_SPECIALBUFF(tBuff)
		if tBuff.bShowUnderStack and tBuff.nStackNum == tBuff.nMonitorStack then
			LR_TeamBuffMonitor.BUFF_UPDATE_NORMALBUFF(tBuff)
		end
		return
	end

	if tBuff.bEdgeIndicator then
		LR_TeamBuffMonitor.BUFF_UPDATE_EDGEINDICATORBUFF(tBuff)
		return
	end

	LR_TeamBuffMonitor.BUFF_UPDATE_NORMALBUFF(tBuff)
	if MonitorBuff.bSpecialBuff then
		tBuff.bSpecialBuff = true
		tBuff.nMonitorStack = MonitorBuff.nMonitorStack or 0
		LR_TeamBuffMonitor.BUFF_UPDATE_SPECIALBUFF(tBuff)
	end
end

function LR_TeamBuffMonitor.BUFF_UPDATE_SPECIALBUFF(tBuff)
	local tBuff = tBuff
	local dwPlayerID = tBuff.dwPlayerID
	local dwID = tBuff.dwID
	local nIndex = tBuff.nIndex
	local bDelete = tBuff.bDelete
	tBuff.nStartFrame = GetLogicFrameCount()

	_SPECIAL_BUFF_HANDLE_CACHE[dwPlayerID] = _SPECIAL_BUFF_HANDLE_CACHE[dwPlayerID] or {}
	_SPECIAL_BUFF_HANDLE_CACHE[dwPlayerID] = _SPECIAL_BUFF_HANDLE_CACHE[dwPlayerID] or {}
	local hMemberBuff = _SPECIAL_BUFF_HANDLE_CACHE[dwPlayerID]
	local MemberBuff = _SPECIAL_BUFF_SHOW[dwPlayerID]

	_SPECIAL_BUFF_CACHE[dwPlayerID] = _SPECIAL_BUFF_CACHE[dwPlayerID]  or {}
	_SPECIAL_BUFF_CACHE[dwPlayerID][dwID] = _SPECIAL_BUFF_CACHE[dwPlayerID][dwID] or {}
	local cache = _SPECIAL_BUFF_CACHE[dwPlayerID][dwID]

	if tBuff.nMonitorStack > 0 then
		if tBuff.nStackNum < tBuff.nMonitorStack then
			bDelete = true
		end
	end

	if tBuff.nMonitorLevel > 0 then
		if tBuff.nLevel ~= tBuff.nMonitorLevel then
			bDelete = true
		end
	end

	if bDelete then
		cache[nIndex] = nil
	else
		cache[nIndex] = clone(tBuff)
	end

	local hBuff = hMemberBuff[dwID]
	if hBuff and hBuff:GetBuffnIndex() == nIndex and not bDelete then
		FireEvent("LR_SPECIAL_BUFF_ADD_FRESH", tBuff.dwPlayerID, tBuff)
		return
	end

	if tBuff.bOnlySelf then
		if bDelete then
			FireEvent("LR_SPECIAL_BUFF_DELETE", tBuff.dwPlayerID, tBuff)
			return
		else
			FireEvent("LR_SPECIAL_BUFF_ADD_FRESH", tBuff.dwPlayerID, tBuff)
			return
		end
	else
		local _nIndex, _nEndFrame = 0, 0
		for k, v in pairs(cache) do
			if v.nEndFrame >= _nEndFrame then
				_nIndex = v.nIndex
				_nEndFrame = v.nEndFrame
			end
		end
		if _nIndex == 0 then
			FireEvent("LR_SPECIAL_BUFF_DELETE", tBuff.dwPlayerID, tBuff)
			return
		else
			FireEvent("LR_SPECIAL_BUFF_ADD_FRESH", tBuff.dwPlayerID, cache[_nIndex])
			return
		end
	end
end

function LR_TeamBuffMonitor.BUFF_UPDATE_EDGEINDICATORBUFF(tBuff)
	local tBuff = tBuff
	local dwPlayerID = tBuff.dwPlayerID
	local dwID = tBuff.dwID
	local nIndex = tBuff.nIndex
	local bDelete = tBuff.bDelete
	tBuff.nStartFrame = GetLogicFrameCount()

	_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID] = _EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID] or {}
	_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID][tBuff.edge] = _EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID][tBuff.edge] or {}
	local hEdge = _EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID][tBuff.edge]

	_EDGEINDICATOR_BUFF_CACHE[dwPlayerID] = _EDGEINDICATOR_BUFF_CACHE[dwPlayerID] or {}
	_EDGEINDICATOR_BUFF_CACHE[dwPlayerID][dwID] = _EDGEINDICATOR_BUFF_CACHE[dwPlayerID][dwID] or {}
	local cache = _EDGEINDICATOR_BUFF_CACHE[dwPlayerID][dwID]
	if bDelete then
		cache[nIndex] = nil
	else
		cache[nIndex] = clone(tBuff)
	end

	if next(hEdge) == nil and not bDelete then
		FireEvent("LR_RAID_EDGE_ADD_FRESH", tBuff.dwPlayerID, tBuff)
		return
	end

	if tBuff.bOnlySelf then
		if bDelete then
			FireEvent("LR_RAID_EDGE_DELETE", tBuff.dwPlayerID, tBuff)
			return
		else
			FireEvent("LR_RAID_EDGE_ADD_FRESH", tBuff.dwPlayerID, tBuff)
			return
		end
	else
		local _nIndex, _nEndFrame = 0, 0
		for k, v in pairs(cache) do
			if v.nEndFrame >= _nEndFrame then
				_nIndex = v.nIndex
				_nEndFrame = v.nEndFrame
			end
		end
		if _nIndex == 0 then
			FireEvent("LR_RAID_EDGE_DELETE", tBuff.dwPlayerID, tBuff)
			return
		else
			FireEvent("LR_RAID_EDGE_ADD_FRESH", tBuff.dwPlayerID, cache[_nIndex])
			return
		end
	end
end

function LR_TeamBuffMonitor.BUFF_UPDATE_NORMALBUFF(tBuff)
	local dwPlayerID = tBuff.dwPlayerID
	local dwID = tBuff.dwID
	local bDelete = tBuff.bDelete
	local nIndex = tBuff.nIndex

	_NORMAL_BUFF_HANDLE_CACHE[dwPlayerID] = _NORMAL_BUFF_HANDLE_CACHE[dwPlayerID] or {}
	local _NormalBuffHandle = _NORMAL_BUFF_HANDLE_CACHE[dwPlayerID]

	_NORMAL_BUFF_CACHE[dwPlayerID] = _NORMAL_BUFF_CACHE[dwPlayerID]  or {}
	_NORMAL_BUFF_CACHE[dwPlayerID][dwID] = _NORMAL_BUFF_CACHE[dwPlayerID][dwID] or {}
	local cache = _NORMAL_BUFF_CACHE[dwPlayerID][dwID]

	if tBuff.nMonitorStack > 0 then
		if tBuff.nStackNum < tBuff.nMonitorStack then
			bDelete = true
		end
	end

	if tBuff.nMonitorLevel > 0 then
		if tBuff.nLevel ~= tBuff.nMonitorLevel then
			bDelete = true
		end
	end

	if tBuff.bSpecialBuff then
		bDelete = true
	end

	if bDelete then
		_NORMAL_BUFF_CACHE[dwPlayerID][dwID][nIndex] = nil
	else
		_NORMAL_BUFF_CACHE[dwPlayerID][dwID][nIndex] = clone(tBuff)
	end

	local hBuff = _NormalBuffHandle[dwID]
	if hBuff and hBuff:GetBuffnIndex() == nIndex and not bDelete then
		FireEvent("LR_RAID_BUFF_ADD_FRESH", tBuff.dwPlayerID, tBuff)
		return
	end

	if tBuff.bOnlySelf then
		if bDelete then
			FireEvent("LR_RAID_BUFF_DELETE", tBuff.dwPlayerID, tBuff)
			return
		else
			FireEvent("LR_RAID_BUFF_ADD_FRESH", tBuff.dwPlayerID, tBuff)
			return
		end
	else
		local _nIndex, _nEndFrame = 0, 0
		for k, v in pairs(cache) do
			if v.nEndFrame >= _nEndFrame then
				_nIndex = v.nIndex
				_nEndFrame = v.nEndFrame
			end
		end
		if _nIndex == 0 then
			FireEvent("LR_RAID_BUFF_DELETE", tBuff.dwPlayerID, tBuff)
			return
		else
			FireEvent("LR_RAID_BUFF_ADD_FRESH", tBuff.dwPlayerID, cache[_nIndex])
			return
		end
	end
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
	LR_TeamBuffSettingPanel.BuffList[arg1.dwID] = LR_TeamBuffSettingPanel.BuffList[arg1.dwID] or {}
	LR_TeamBuffSettingPanel.BuffList[arg1.dwID].nLevel = arg1.nLevelEx or 0
	LR_TeamBuffSettingPanel.BuffList[arg1.dwID].nMonitorLevel = arg1.nLevel or LR_TeamBuffSettingPanel.BuffList[arg1.dwID].nLevel or 0
	LR_TeamBuffSettingPanel.BuffList[arg1.dwID].bOnlySelf = arg1.bOnlySelf or LR_TeamBuffSettingPanel.BuffList[arg1.dwID].bOnlySelf or false
	LR_TeamBuffSettingPanel.BuffList[arg1.dwID].nIconID = arg1.nIcon or LR_TeamBuffSettingPanel.BuffList[arg1.dwID].nIconID or 0
	LR_TeamBuffSettingPanel.BuffList[arg1.dwID].nStackNum = arg1.nStackNum or LR_TeamBuffSettingPanel.BuffList[arg1.dwID].nStackNum or 0
	LR_TeamBuffSettingPanel.BuffList[arg1.dwID].col = arg1.col or LR_TeamBuffSettingPanel.BuffList[arg1.dwID].col or {}
end

function LR_TeamBuffMonitor.LR_SPECIAL_BUFF_DELETE()
	local dwPlayerID = arg0
	local tBuff = arg1

	_SPECIAL_BUFF_HANDLE_CACHE[dwPlayerID] = _SPECIAL_BUFF_HANDLE_CACHE[dwPlayerID] or {}
	_SPECIAL_BUFF_SHOW[dwPlayerID] = _SPECIAL_BUFF_SHOW[dwPlayerID] or {}
	local specialBuffHandle = _SPECIAL_BUFF_HANDLE_CACHE[dwPlayerID]
	local specialBuffShow = _SPECIAL_BUFF_SHOW[dwPlayerID]

	if specialBuffHandle[tBuff.dwID] then
		specialBuffHandle[tBuff.dwID]:Remove()
		specialBuffHandle[tBuff.dwID] = nil
	end

	for k, v in pairs (specialBuffShow) do
		if v.dwID == tBuff.dwID then
			tremove(specialBuffShow, k)
		end
	end
end

function LR_TeamBuffMonitor.LR_SPECIAL_BUFF_ADD_FRESH()
	local dwPlayerID = arg0
	local tBuff = arg1

	_SPECIAL_BUFF_SHOW[dwPlayerID] = _SPECIAL_BUFF_SHOW[dwPlayerID] or {}
	local specialBuffShow = _SPECIAL_BUFF_SHOW[dwPlayerID]
	for k, v in pairs(specialBuffShow) do
		if v.dwID == tBuff.dwID then
			tremove(specialBuffShow, k)
		end
	end
	tinsert(specialBuffShow, tBuff)
	LR_TeamBuffMonitor.RedrawSpecialBuffBox(dwPlayerID)
end

function LR_TeamBuffMonitor.ClearSpecialBuffCache(dwID)
	if dwID then
		_SPECIAL_BUFF_HANDLE_CACHE[dwID] = {}
	else
		_SPECIAL_BUFF_HANDLE_CACHE = {}
	end
end

function LR_TeamBuffMonitor.RefreshSpecialBuff()
	for dwMemberID , v in pairs(_SPECIAL_BUFF_HANDLE_CACHE) do
		if next(v) ~= nil then
			for dwID , v2 in pairs(v) do
				if v2:GetEndFrame() < GetLogicFrameCount() then
					v2:Remove()
					v[dwID] = nil
					for k3, v3 in pairs (_SPECIAL_BUFF_HANDLE_CACHE[dwMemberID]) do
						if v3.dwID == dwID then
							tremove(_SPECIAL_BUFF_HANDLE_CACHE[dwMemberID], k3)
						end
					end
				else
					v2:Draw()
				end
			end
		end
	end
end

function LR_TeamBuffMonitor.RedrawSpecialBuffBox(dwPlayerID)
	_NORMAL_BUFF_SHOW[dwPlayerID] = _NORMAL_BUFF_SHOW[dwPlayerID] or {}
	local specialBuffShow = _SPECIAL_BUFF_SHOW[dwPlayerID]

	_SPECIAL_BUFF_HANDLE_CACHE[dwPlayerID] = _SPECIAL_BUFF_HANDLE_CACHE[dwPlayerID] or {}
	local specialBuffHandle = _SPECIAL_BUFF_HANDLE_CACHE[dwPlayerID]

	for dwID, v in pairs(specialBuffHandle) do
		if dwID ~= specialBuffShow[#specialBuffShow].dwID then
			specialBuffHandle[dwID]:Remove()
			specialBuffHandle[dwID] = nil
		end
	end

	local BuffHandle = LR_TeamGrid.GetRoleGridSpecialBuffHandle(dwPlayerID)
	if not (specialBuffShow and #specialBuffShow > 0) then
		return
	end
	local buffLastShow = specialBuffShow[#specialBuffShow]

	if BuffHandle then
		if not specialBuffHandle[buffLastShow.dwID] then
			local h = _BuffBox:new(buffLastShow.dwID, BuffHandle, buffLastShow):Create()
			specialBuffHandle[buffLastShow.dwID] = h
		end
		specialBuffHandle[buffLastShow.dwID]:SetOrder(1):SetSize():SetRelPos():SetBuff(buffLastShow)
		specialBuffHandle[buffLastShow.dwID]:SetStartFrame():SetEndFrame(buffLastShow.nEndFrame):SetIcon():Show()
		BuffHandle:FormatAllItemPos()
	end
end

function LR_TeamBuffMonitor.LR_RAID_EDGE_DELETE()
	local dwPlayerID = arg0
	local tBuff = arg1

	_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID] = _EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID] or {}
	_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID][tBuff.edge] = _EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID][tBuff.edge] or {}
	local hEdge = _EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID][tBuff.edge]

	_EDGEINDICATOR_BUFF_CACHE[dwPlayerID] = _EDGEINDICATOR_BUFF_CACHE[dwPlayerID] or {}
	_EDGEINDICATOR_BUFF_CACHE[dwPlayerID][tBuff.dwID] = _EDGEINDICATOR_BUFF_CACHE[dwPlayerID][tBuff.dwID] or {}
	local cache = _EDGEINDICATOR_BUFF_CACHE[dwPlayerID][tBuff.dwID]

	if next(cache) ~= nil then
		hEdge.hShadow:Hide()
		hEdge.hShadowBg:Hide()

		_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID][tBuff.edge] = {}
		_EDGEINDICATOR_BUFF_SHOW[dwPlayerID][tBuff.edge] = {}
		_EDGEINDICATOR_BUFF_CACHE[dwPlayerID][tBuff.dwID] = {}
	end
end

function LR_TeamBuffMonitor.LR_RAID_EDGE_ADD_FRESH()
	local dwPlayerID = arg0
	local tBuff = arg1

	_EDGEINDICATOR_BUFF_SHOW[dwPlayerID] = _EDGEINDICATOR_BUFF_SHOW[dwPlayerID] or {}
	_EDGEINDICATOR_BUFF_SHOW[dwPlayerID][tBuff.edge] = _EDGEINDICATOR_BUFF_SHOW[dwPlayerID][tBuff.edge] or {}
	_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID] = _EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID] or {}
	_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID][tBuff.edge] = _EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID][tBuff.edge] or {}
	local hEdge = _EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID][tBuff.edge]

	_EDGEINDICATOR_BUFF_CACHE[dwPlayerID] = _EDGEINDICATOR_BUFF_CACHE[dwPlayerID] or {}
	_EDGEINDICATOR_BUFF_CACHE[dwPlayerID][tBuff.dwID] = _EDGEINDICATOR_BUFF_CACHE[dwPlayerID][tBuff.dwID] or {}
	local cache = _EDGEINDICATOR_BUFF_CACHE[dwPlayerID][tBuff.dwID]


	local RoleHandle = LR_TeamGrid.GetRoleHandle(dwPlayerID)
	if not RoleHandle then
		return
	end
	local hShadow = RoleHandle:GetEdgeIndicatorShadow(sformat("Shadow_Edge%s", tBuff.edge))
	local hShadowBg = RoleHandle:GetEdgeIndicatorShadow(sformat("Shadow_Edge%sBg", tBuff.edge))

	if hShadow then
		_EDGEINDICATOR_BUFF_SHOW[dwPlayerID][tBuff.edge] = clone(tBuff)
		_EDGEINDICATOR_BUFF_CACHE[dwPlayerID][tBuff.dwID] = clone(tBuff)
		_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID][tBuff.edge] = clone(tBuff)
		_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID][tBuff.edge].hShadow = hShadow
		_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwPlayerID][tBuff.edge].hShadowBg = hShadowBg
	end
end

function LR_TeamBuffMonitor.RedrawEdgeIndicatorBUFF(dwID)
	local v = _EDGEINDICATOR_BUFF_SHOW[dwID] or {}
	local RoleHandle = LR_TeamGrid.GetRoleHandle(dwID)
	if RoleHandle then
		for edge, v2 in pairs(v) do
			if next(v2) ~= nil then
				local hShadow = RoleHandle:GetEdgeIndicatorShadow(sformat("Shadow_Edge%s", edge))
				local hShadowBg = RoleHandle:GetEdgeIndicatorShadow(sformat("Shadow_Edge%sBg", edge))
				if hShadow then
					_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwID] = _EDGEINDICATOR_BUFF_HANDLE_CACHE[dwID] or {}
					_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwID][edge] = clone(v2)
					_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwID][edge].hShadow = hShadow
					_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwID][edge].hShadowBg = hShadowBg
				end
			end
		end
	end
end

function LR_TeamBuffMonitor.LR_RAID_BUFF_DELETE()
	local dwPlayerID = arg0
	local tBuff = arg1

	_NORMAL_BUFF_HANDLE_CACHE[dwPlayerID] = _NORMAL_BUFF_HANDLE_CACHE[dwPlayerID] or {}
	_NORMAL_BUFF_SHOW[dwPlayerID] = _NORMAL_BUFF_SHOW[dwPlayerID] or {}
	local hMemberBuff = _NORMAL_BUFF_HANDLE_CACHE[dwPlayerID]
	local MemberBuff = _NORMAL_BUFF_SHOW[dwPlayerID]

	if hMemberBuff[tBuff.dwID] then
		hMemberBuff[tBuff.dwID]:Remove()
		hMemberBuff[tBuff.dwID] = nil
	end

	for k, v in pairs (MemberBuff) do
		if v.dwID == tBuff.dwID then
			MemberBuff[k] = {}
			--LR_TeamBuffMonitor.SortBuff(tBuff.dwPlayerID)
			return
		end
	end
end

function LR_TeamBuffMonitor.LR_RAID_BUFF_ADD_FRESH()
	local dwPlayerID = arg0
	local tBuff = arg1

	local MemberBuff = clone(_NORMAL_BUFF_SHOW[dwPlayerID] or {})
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
		BuffList[i] = nil
	end

	_NORMAL_BUFF_SHOW[dwPlayerID] = clone(BuffList)
	LR_TeamBuffMonitor.RedrawBuffBox(dwPlayerID)
end

function LR_TeamBuffMonitor.RefreshBuff()
	for dwMemberID , v in pairs(_NORMAL_BUFF_HANDLE_CACHE) do
		if next(v) ~= nil then
			for dwID , v2 in pairs(v) do
				if v2:GetEndFrame() < GetLogicFrameCount() then
					v2:Remove()
					v[dwID] = nil
					for k3, v3 in pairs (_NORMAL_BUFF_SHOW[dwMemberID]) do
						if v3.dwID == dwID then
							_NORMAL_BUFF_SHOW[dwMemberID][k3] = {}
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
	_NORMAL_BUFF_SHOW[dwPlayerID] = _NORMAL_BUFF_SHOW[dwPlayerID] or {}
	MemberBuff = _NORMAL_BUFF_SHOW[dwPlayerID]
	for k, v in pairs (MemberBuff) do
		if next(v) ~= nil then
			newTable[v.dwID] = clone(v)
			newTable[v.dwID].nOrder = k
		end
	end
	local BuffHandle = LR_TeamGrid.GetRoleGridBuffHandle(dwPlayerID)
	_NORMAL_BUFF_HANDLE_CACHE[dwPlayerID] = _NORMAL_BUFF_HANDLE_CACHE[dwPlayerID] or {}
	local hMemberBuff = _NORMAL_BUFF_HANDLE_CACHE[dwPlayerID] or {}
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
		BuffHandle:GetHandle():FormatAllItemPos()
	end
end

function LR_TeamBuffMonitor.ClearAllNormalBuffCache()
	local MemberBuff = clone(_NORMAL_BUFF_SHOW)
	_NORMAL_BUFF_HANDLE_CACHE = {}
	_NORMAL_BUFF_SHOW = {}
	_NORMAL_BUFF_CACHE = {}
	for dwID, v in pairs(MemberBuff) do
		local BuffHandle = LR_TeamGrid.GetRoleGridBuffHandle(dwID)
		if BuffHandle then
			BuffHandle:Clear()
		end
	end
end

function LR_TeamBuffMonitor.ClearOneCache(dwID)
	_NORMAL_BUFF_HANDLE_CACHE[dwID] = nil
	_NORMAL_BUFF_CACHE[dwID] = nil
	_NORMAL_BUFF_SHOW[dwID] = nil

	_EDGEINDICATOR_BUFF_HANDLE_CACHE[dwID] = nil
	_EDGEINDICATOR_BUFF_CACHE[dwID] = nil
	_EDGEINDICATOR_BUFF_SHOW[dwID] = nil

	_SPECIAL_BUFF_HANDLE_CACHE[dwID] = nil
	_SPECIAL_BUFF_CACHE[dwID] = nil
	_SPECIAL_BUFF_SHOW[dwID] = nil

	local BuffHandle = LR_TeamGrid.GetRoleGridBuffHandle(dwID)
	if BuffHandle then
		BuffHandle:Clear()
	end
end

function LR_TeamBuffMonitor.ClearAllCache()
	_NORMAL_BUFF_HANDLE_CACHE = {}
	_NORMAL_BUFF_CACHE = {}
	_NORMAL_BUFF_SHOW = {}

	_EDGEINDICATOR_BUFF_HANDLE_CACHE = {}
	_EDGEINDICATOR_BUFF_CACHE = {}
	_EDGEINDICATOR_BUFF_SHOW = {}

	_SPECIAL_BUFF_HANDLE_CACHE = {}
	_SPECIAL_BUFF_CACHE = {}
	_SPECIAL_BUFF_SHOW = {}
end

function LR_TeamBuffMonitor.ClearhMemberNormalBuff(dwID)
	if dwID then
		_NORMAL_BUFF_HANDLE_CACHE[dwID] = {}
	else
		_NORMAL_BUFF_HANDLE_CACHE = {}
	end
end

function LR_TeamBuffMonitor.SortBuff(dwPlayerID)
	_NORMAL_BUFF_SHOW[dwPlayerID] = _NORMAL_BUFF_SHOW[dwPlayerID] or {}
	local MemberBuff = _NORMAL_BUFF_SHOW[dwPlayerID]
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
	local hMemberBuff = _NORMAL_BUFF_HANDLE_CACHE[dwPlayerID] or {}
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

