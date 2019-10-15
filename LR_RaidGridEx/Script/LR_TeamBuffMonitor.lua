local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local VERSION = "20170921"
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_RaidGridEx"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_TeamGrid"
local _L = LR.LoadLangPack(AddonPath)
local _DefaultBuffMonitorData = {
	VERSION = VERSION,
	data = {},
}
----------------------------------------------------------------
--引用的变量都在这里设置
----------------------------------------------------------------
--地图缓存数据
_GMV.LR_Team_Map = {}	--用于存地图BUFF信息
_GMV.LR_Team_Map_Sorted = {}	--按年代排序地图信息

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
	local Box2 = handle:Lookup("Box")
	Box2:RegisterEvent(272)
	Box2.OnItemMouseEnter = function()
		local handle = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		local x, y = handle:GetAbsPos()
		local w, h = handle:GetSize()
		if LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 4 then
			w = w + 40
		end
		local nTime = math.floor(self.tBuff.nEndFrame - GetLogicFrameCount()) / 16 + 1
		OutputBuffTip(self.dwMemberID, self.tBuff.dwID, self.tBuff.nLevel, self.tBuff.nBuffStack, false, 0, {x, y, w, h})
	end
	Box2.OnItemMouseLeave = function()
		HideTip()
	end
	Box2.OnItemLButtonClick = function()
		local x = Box2:GetParent():GetParent():GetParent()
		x.OnItemLButtonClick()
	end

	local Handle_SFX = handle:Lookup("Handle_SFX")
	local nEffectsType = self.tBuff.nEffectsType or 0
	Handle_SFX:Clear()
	if nEffectsType > 0 then
		Handle_SFX:AppendItemFromIni(sformat("%s\\UI\\PSS.ini", AddonPath), sformat("Handle_SpecialBuff%d", nEffectsType), "Handle_SpecialBuff")
		Handle_SFX:Lookup("Handle_SpecialBuff"):Lookup(sformat("Handle_SpecialBuff%d_Fixed", nEffectsType)):SetName("Handle_SpecialBuff_Fixed")
		Handle_SFX:Lookup("Handle_SpecialBuff"):Lookup(sformat("SFX_SpecialBuff%d", nEffectsType)):SetName("SFX_SpecialBuff")
	end

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
		parentHandle:Lookup("Image_SpecialMe"):Hide()
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

	local style = self.tBuff.nEffectsType or 0
	if style > 0 then
		local w, h = handle:Lookup("Handle_SFX"):Lookup("Handle_SpecialBuff"):Lookup("Handle_SpecialBuff_Fixed"):GetSize()	--SFX原始大小
		local fSFXX, fSFXY = width / w, height / h
		handle:Lookup("Handle_SFX"):SetSize(width, height)
		handle:Lookup("Handle_SFX"):Lookup("Handle_SpecialBuff"):SetSize(width, height)
		handle:Lookup("Handle_SFX"):Lookup("Handle_SpecialBuff"):Lookup("SFX_SpecialBuff"):Get3DModel():SetScaling(fSFXX, fSFXY, fSFXX)
		handle:Lookup("Handle_SFX"):Lookup("Handle_SpecialBuff"):Lookup("SFX_SpecialBuff"):SetRelPos(width/2, height/2)
		handle:Lookup("Handle_SFX"):Lookup("Handle_SpecialBuff"):FormatAllItemPos()
		handle:Lookup("Handle_SFX"):FormatAllItemPos()
		handle:Lookup("Handle_SFX"):Show()
	end

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
	--Text_BuffStacks:SetSize(height, width)
	Text_BuffStacks:SetVAlign(0)
	Text_BuffStacks:SetHAlign(0)
	Text_LeftTime:SetFontScheme(15)
	--Text_LeftTime:SetSize(height, width)
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
	if nLeftFrame < 16 * 3 then
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
		box2:SetAlpha(LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffCDAniAlpha)
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
	Text_LeftTime:SetFontScheme(15)
	Text_LeftTime:SetAlpha(255)
	--Text_LeftTime:SetFontScale(UIConfig.handleBuff.fontscale or 0.9)
	local buffTextType = LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.buffTextType or 1
	LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.buffTextType = LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.buffTextType or 1
	if buffTextType == 1 then
		Text_LeftTime:SetHAlign(0)
		Text_LeftTime:SetVAlign(0)
	else
		Text_LeftTime:SetHAlign(2)
		Text_LeftTime:SetVAlign(2)
	end
	Text_LeftTime:SetFontColor(255, 255, 0)

	local w, h = box:GetSize()
	local ff = w * 1.0 / 26
	if LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bShowLeftTime then
		if nLeftFrame / 16 < 10 then
			if nLeftFrame / 16 <= 4 then
				Text_LeftTime:SetFontScheme(17)
			elseif nLeftFrame / 16 <= 7 then
				Text_LeftTime:SetFontScheme(16)
			else
				Text_LeftTime:SetFontScheme(15)
			end
			Text_LeftTime:SprintfText("%0.0f\"", mfloor(nLeftFrame / 16) )
			Text_LeftTime:SetFontScale(ff)
			Text_LeftTime:Show()
		else
			Text_LeftTime:Hide()
		end
	else
		Text_LeftTime:Hide()
	end

	local Text_BuffStacks = handle:Lookup("Text_BuffStacks")
	Text_BuffStacks:SetFontScheme(15)
	Text_BuffStacks:SetAlpha(255)
	--Text_BuffStacks:SetFontScale(UIConfig.handleBuff.fontscale or 0.9)
	if buffTextType == 1 then
		Text_BuffStacks:SetHAlign(2)
		Text_BuffStacks:SetVAlign(2)
	else
		Text_BuffStacks:SetHAlign(0)
		Text_BuffStacks:SetVAlign(0)
	end
	Text_BuffStacks:SetHAlign(2)
	Text_BuffStacks:SetVAlign(2)
	Text_BuffStacks:SetFontColor(255, 255, 0)

	if LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bShowStack then
		if self.tBuff.nStackNum and self.tBuff.nStackNum > 1 then
			Text_BuffStacks:SetText(self.tBuff.nStackNum)
			Text_BuffStacks:SetFontColor(255, 255, 255)
		else
			Text_BuffStacks:SetText("")
		end
		Text_BuffStacks:SetFontScale(ff)
		Text_BuffStacks:Show()
	else
		Text_BuffStacks:Hide()
	end

--[[	box:SetOverText(1, "附")
	box:SetOverTextFontScheme(1, 15)
	box:SetOverTextPosition(1, ITEM_POSITION.LEFT_BOTTOM)]]

	if self.tBuff.bSpecialBuff then
		sha:SetColorRGB(0, 0, 0)
		local color = self.tBuff.col
		if next(self.tBuff.col) == nil then
			color = {127, 18, 127}
		end
		local parentHandle = self.parentHandle
		if self.tBuff.bShowMask then
			parentHandle:Lookup("Shadow_SpecialBuffBg"):SetColorRGB(unpack(color))
			parentHandle:Lookup("Shadow_SpecialBuffBg"):Show()
			parentHandle:Lookup("Shadow_SpecialBuffBg"):SetAlpha(LR_TeamGrid.UsrData.CommonSettings.nSpecialBuffAlpha or 120)
		end
		if self.tBuff.dwPlayerID == GetClientPlayer().dwID then
			parentHandle:Lookup("Image_SpecialMe"):Show()
		end
	end

	return self
end

----------------------------------------------------------------
----BOSS注视
----------------------------------------------------------------
_BossFocus = {}
BossFocusBuff =
	{
		Path = "\\UI\\Scheme\\Case\\BossFocusBuff.txt",
		Title =
		{
			{f = "i", t = "dwID"},
			{f = "i", t = "nBuffID"},
			{f = "i", t = "nBuffLevel"},
			{f = "i", t = "nBuffStack"},
		}
	}

local x3 = KG_Table.Load(BossFocusBuff.Path, BossFocusBuff.Title)
local RowCount = x3:GetRowCount()
for i = 1, RowCount, 1 do
	local x = x3:GetRow(i)
	_BossFocus[x.nBuffID] = {dwID = x.nBuffID, nLevel = x.nBuffLevel, nStackNum = x.nBuffStack}
end
--_BossFocus[208] = {dwID = 208, nLevel = 11, nStackNum = 1}	--扶摇
--_BossFocus[680] = {dwID = 680, nLevel = 29, nStackNum = 1}	--翔舞
--_BossFocus[103] = {dwID = 103, nLevel = 1, nStackNum = 1}	--打坐

----------------------------------------------------------------
----边角指示器buff
----------------------------------------------------------------
local _EDGEINDICATOR_BUFF_CACHE = {}
local _EDGEINDICATOR_BUFF_HANDLE_CACHE = {}
local _EDGEINDICATOR_BUFF_SHOW = {}
local EDGE_VERSION = "20180205"
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
	["VERSION"] = VERSION,
}
LR_TeamEdgeIndicator.UsrData = clone(EdgeIndicatorDefaultData)
RegisterCustomData("LR_TeamEdgeIndicator.UsrData", VERSION)

function LR_TeamEdgeIndicator.LoadDefaultData()
	if LR_TeamEdgeIndicator.UsrData.VERSION and LR_TeamEdgeIndicator.UsrData.VERSION == EDGE_VERSION then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwForceID = me.dwForceID
	local _, _, szLang = GetVersion()
	local path = sformat("%s\\DefaultData\\Edge_%s", AddonPath, szLang)
	local data = LoadLUAData(path) or {}
	if data[dwForceID] then
		LR_TeamEdgeIndicator.UsrData = clone(data[dwForceID])
		LR_TeamEdgeIndicator.UsrData.VERSION = EDGE_VERSION
	else
		LR_TeamEdgeIndicator.UsrData = clone(EdgeIndicatorDefaultData)
		LR_TeamEdgeIndicator.UsrData.VERSION = EDGE_VERSION
	end
end

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
					local buff = LR_TeamBuffSettingPanel.FormatMonitorBuff({})
					buff.dwID = LR_TeamEdgeIndicator.UsrData[v].buff.dwID
					buff.bEdgeIndicator = true
					buff.edge = v
					buff.bOnlySelf = LR_TeamEdgeIndicator.UsrData[v].buff.bOnlySelf
					MonitorList[sformat("%d", dwID)] = clone(buff)
				end
			else
				local buff = LR_TeamBuffSettingPanel.FormatMonitorBuff({})
				buff.szName = LR_TeamEdgeIndicator.UsrData[v].buff.szName
				buff.bEdgeIndicator = true
				buff.edge = v
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

function LR_TeamEdgeIndicator.FIRST_LOADING_END()
	LR_TeamEdgeIndicator.LoadDefaultData()
	LR_TeamEdgeIndicator.add2bufflist()
end
LR.RegisterEvent("FIRST_LOADING_END", function() LR_TeamEdgeIndicator.FIRST_LOADING_END() end)
--LR.RegisterEvent("LOADING_END", function() LR_TeamBuffSettingPanel.FormatDebuffNameList() end)
----------------------------------------------------------------
----Debuff设置
----------------------------------------------------------------
LR_TeamBuffSettingPanel = {}
LR_TeamBuffSettingPanel.BuffList = {}

function LR_TeamBuffSettingPanel.FormatMonitorBuff(buff)
	local tBuff = LR_TeamBuffTool.FormatBuff(buff)
	tBuff.bEdgeIndicator = false
	tBuff.edge = ""
	return tBuff
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
							tBuff[szKey] = LR_TeamBuffSettingPanel.FormatMonitorBuff(buff)
						else
							local szKey = sformat("%d", buff.dwID)
							tBuff[szKey] = LR_TeamBuffSettingPanel.FormatMonitorBuff(buff)
						end
					end
				end
			end
		end
	end

	local me = GetClientPlayer()
	local scene = me.GetScene()
	local dwMapID = scene.dwMapID
	local LR_Team_Map = _GMV.LR_Team_Map
	if scene.nType ==  MAP_TYPE.DUNGEON and not LR_TeamBuffTool_Panel.DisableDungeonData then
		local data = LR_Team_Map[LR.MapType[dwMapID].szOtherName] or {enable = true, dwMapID = {}, data = {}, level = 1}
		if data.enable then
			for k, buff in pairs(data.data) do
				if buff.enable then
					if buff.nMonitorLevel > 0 then
						local szKey = sformat("%d_L%d", buff.dwID, buff.nMonitorLevel)
						tBuff[szKey] = LR_TeamBuffSettingPanel.FormatMonitorBuff(buff)
					else
						local szKey = sformat("%d", buff.dwID)
						tBuff[szKey] = LR_TeamBuffSettingPanel.FormatMonitorBuff(buff)
					end
				end
			end
		end
	end

	LR_TeamBuffSettingPanel.BuffList = clone(tBuff)
	LR_TeamEdgeIndicator.add2bufflist()

	if LR_TeamBuffTool_Panel.bConnectSysRaidPanel then
		local _sysBuff = {}
		for dwID, v in pairs(LR_TeamBuffSettingPanel.BuffList) do
			tinsert(_sysBuff, v.dwID)
		end
		Raid_MonitorBuffs(_sysBuff)
	end
end

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
----声音缓存
----------------------------------------------------------------
local _SOUND_CACHE = {}
local SOUND_TYPE = {
	g_sound.OpenAuction,
	g_sound.CloseAuction,
	g_sound.FinishAchievement,
	g_sound.PickupRing,
	g_sound.PickupWater,
}

----------------------------------------------------------------
----地图缓存数据
----------------------------------------------------------------
local map_initial = function()
	local fenlei = {
		[25] = {},
		[10] = {},
		[5] = {},
	}
	for dwMapID, v in pairs (LR.MapType) do
		if fenlei[v.nMaxPlayerCount] then
			fenlei[v.nMaxPlayerCount][#fenlei[v.nMaxPlayerCount]+1] = {dwMapID = dwMapID, Level = v.Level, szName = v.szName, szVersionName = v.szVersionName, szOtherName = v.szOtherName}
		end
	end
	tsort(fenlei[25], function(a, b) return a.dwMapID > b.dwMapID end)
	tsort(fenlei[10], function(a, b) return a.dwMapID > b.dwMapID end)
	tsort(fenlei[5], function(a, b) return a.dwMapID > b.dwMapID end)

	--以["三才阵"]这种类型分类
	local data = {}
	for k, v in pairs(fenlei[25]) do
		data[v.szOtherName] = data[v.szOtherName] or {enable = true, dwMapID = {}, data = {}, level = 1}
		tinsert(data[v.szOtherName].dwMapID, v.dwMapID)
	end
	for k, v in pairs(fenlei[10]) do
		data[v.szOtherName] = data[v.szOtherName] or {enable = true, dwMapID = {}, data = {}, level = 1}
		tinsert(data[v.szOtherName].dwMapID, v.dwMapID)
	end
	for k, v in pairs(fenlei[5]) do
		data[v.szOtherName] = data[v.szOtherName] or {enable = true, dwMapID = {}, data = {}, level = 2}
		tinsert(data[v.szOtherName].dwMapID, v.dwMapID)
	end

	--按时代进行分类
	--获取分类中最大的dwMap数字
	for k, v in pairs(data) do
		v.nMaxdwMapID = mmax(unpack(v.dwMapID))
	end

	local list, szVersionName = {}, {}
	for k, v in pairs(data) do
		if not szVersionName[LR.MapType[v.nMaxdwMapID].szVersionName] then
			tinsert(list, {szVersionName = LR.MapType[v.nMaxdwMapID].szVersionName, nMaxdwMapID = 0, data = {}})
			szVersionName[LR.MapType[v.nMaxdwMapID].szVersionName] = #list
		end

		tinsert(list[szVersionName[LR.MapType[v.nMaxdwMapID].szVersionName]].data, {nMaxdwMapID = v.nMaxdwMapID, szOtherName = LR.MapType[v.nMaxdwMapID].szOtherName, level = v.level, dwMapID = clone(v.dwMapID), enable = v.enable, data = clone(v.data)})
		list[szVersionName[LR.MapType[v.nMaxdwMapID].szVersionName]].nMaxdwMapID = mmax(list[szVersionName[LR.MapType[v.nMaxdwMapID].szVersionName]].nMaxdwMapID, v.nMaxdwMapID)
	end
	tsort(list, function(a, b) return a.nMaxdwMapID > b.nMaxdwMapID end)
	for k, v in pairs(list) do
		tsort(v.data, function(a, b)
			if a.level == b.level then
				return a.nMaxdwMapID > b.nMaxdwMapID
			else
				return a.level < b.level
			end
		end)
	end
	for k, v in pairs(list) do
		for k2, v2 in pairs(v.data) do
			tsort(v2.dwMapID, function(a, b) return a > b end)
		end
	end

	_GMV.LR_Team_Map = clone(data)
	_GMV.LR_Team_Map_Sorted = clone(list)
end
map_initial()

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

	local buff = clone(MonitorBuff)
	buff.dwPlayerID = dwTarget
	buff.bDelete = (bAddOrDel == 0)
	buff.bCanCancel = bCanCancel
	buff.dwID = dwID
	buff.nLevel = nLevel
	buff.receivedFromLOG = true
	buff.DelayCallKey = sformat("%s_%d", szKey, nTime)
	buff.nTime = nTime
	buff.szKey = szKey

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

	local dwPlayerID, bDelete, nIndex, bCanCancel, dwID, nStackNum, nEndFrame, bInit, nLevel, dwCaster, IsValid, nLeftFrame = arg0, arg1, arg2, arg3, arg4, arg5 or 1, arg6, arg7, arg8 or 0, arg9, arg10, arg11
	--去除不在监控buff里的
	if dwID == 0 then
		return
	end

	local MonitorList = LR_TeamBuffSettingPanel.BuffList
	local szBuffName = LR_TeamBuffMonitor.GetBuffName(dwID, nLevel)

	if _BossFocus[dwID] and LR_TeamGrid.UsrData.CommonSettings.bShowBossFocus then
		if _BossFocus[dwID].nLevel == nLevel then
			if bDelete then
				FireEvent("ON_BOSS_FOCUS", dwPlayerID, false)
			else
				if nStackNum >= _BossFocus[dwID].nStackNum then
					FireEvent("ON_BOSS_FOCUS", dwPlayerID, true)
				else
					FireEvent("ON_BOSS_FOCUS", dwPlayerID, false)
				end
			end
		else
			FireEvent("ON_BOSS_FOCUS", dwPlayerID, false)
		end
	end

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
	--如果只监控来源是自己的BUFF而BUFF不是来源于自己的返回
	if MonitorBuff.bOnlySelf and dwCaster ~= me.dwID then
		return
	end

	--如果只监控作用于自己的BUFF，而BUFF不是自己的则返回
	if MonitorBuff.bOnlyMonitorSelf and dwPlayerID ~= me.dwID then
		return
	end

	local tBuff = clone(MonitorBuff)
	tBuff.dwPlayerID = dwPlayerID
	tBuff.bDelete = bDelete
	tBuff.nIndex = nIndex
	tBuff.bCanCancel = bCanCancel
	tBuff.dwID = dwID
	tBuff.nStackNum = nStackNum
	tBuff.nEndFrame = nEndFrame
	tBuff.bInit = bInit
	tBuff.nLevel = nLevel
	tBuff.dwCaster = dwCaster
	tBuff.IsValid = IsValid
	tBuff.nLeftFrame = nLeftFrame

	local nSoundType = tBuff.nSoundType or 0
	if nSoundType > 0 then
		if dwPlayerID == me.dwID then
			local bSoundFlag = true
			if tBuff.nMonitorStack > 0 then
				if tBuff.nStackNum < tBuff.nMonitorStack then
					bSoundFlag = false
				end
			end
			if bSoundFlag then
				_SOUND_CACHE[dwPlayerID] = _SOUND_CACHE[dwPlayerID] or {}
				_SOUND_CACHE[dwPlayerID][dwID] = _SOUND_CACHE[dwPlayerID][dwID] or {}
				for nIndex, v in pairs(_SOUND_CACHE[dwPlayerID][dwID]) do
					if v.nEndFrame < GetLogicFrameCount() then
						_SOUND_CACHE[dwPlayerID][dwID][nIndex] = nil
					end
				end
				if next(_SOUND_CACHE[dwPlayerID][dwID]) == nil and not bDelete and SOUND_TYPE[nSoundType] then
					PlaySound(SOUND.UI_SOUND, SOUND_TYPE[nSoundType])
				end
				if bDelete then
					_SOUND_CACHE[dwPlayerID][dwID][nIndex] = nil
				else
					_SOUND_CACHE[dwPlayerID][dwID][nIndex] = {nEndFrame = nEndFrame}
				end
			end
		else
			_SOUND_CACHE[dwPlayerID] = _SOUND_CACHE[dwPlayerID] or {}
			_SOUND_CACHE[dwPlayerID][dwID] = nil
		end
	end

	--如果是醒目BUFF且即使没到监控层数也显示且监控层数没到醒目层数
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
		if tBuff.bScene then
			FireEvent("LR_BUFF_TRAN", "Add", tBuff.dwPlayerID, tBuff)
		end
		return
	end

	if tBuff.bOnlySelf then
		if bDelete then
			FireEvent("LR_RAID_BUFF_DELETE", tBuff.dwPlayerID, tBuff)
			if tBuff.bScene then
				FireEvent("LR_BUFF_TRAN", "Del", tBuff.dwPlayerID, tBuff)
			end
			return
		else
			FireEvent("LR_RAID_BUFF_ADD_FRESH", tBuff.dwPlayerID, tBuff)
			if tBuff.bScene then
				FireEvent("LR_BUFF_TRAN", "Add", tBuff.dwPlayerID, tBuff)
			end
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
			if tBuff.bScene then
				FireEvent("LR_BUFF_TRAN", "Del", tBuff.dwPlayerID, tBuff)
			end
			return
		else
			FireEvent("LR_RAID_BUFF_ADD_FRESH", tBuff.dwPlayerID, cache[_nIndex])
			if tBuff.bScene then
				FireEvent("LR_BUFF_TRAN", "Add", tBuff.dwPlayerID, tBuff)
			end
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
		if hEdge.hShadow then
			hEdge.hShadow:Hide()
		end

		if hEdge.hShadowBg then
			hEdge.hShadowBg:Hide()
		end

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
		end
	end

	local nBuffShowType = LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.nBuffShowType or 1
	local BuffList = {}
	if nBuffShowType == 1 then
		BuffList = clone(MemberBuff)
	elseif nBuffShowType == 2 or nBuffShowType == 3 then
		local n = 1
		for i = 1, 4, 1 do
			MemberBuff[i] = MemberBuff[i] or {}
			if next(MemberBuff[i]) ~= nil then
				BuffList[n] = clone(MemberBuff[i])
				n = n + 1
			end
		end
	end

	_NORMAL_BUFF_SHOW[dwPlayerID] = clone(BuffList)
	LR_TeamBuffMonitor.RedrawBuffBox(dwPlayerID)
end

function LR_TeamBuffMonitor.LR_RAID_BUFF_ADD_FRESH()
	local dwPlayerID = arg0
	local tBuff = arg1

	local MemberBuff = clone(_NORMAL_BUFF_SHOW[dwPlayerID] or {})
	local nBuffShowType = LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.nBuffShowType or 1

	local BuffList = {}
	if nBuffShowType == 1 then
		BuffList[1] = clone(tBuff)
		local bFound = false
		for i = 1, 4, 1 do
			MemberBuff[i] = MemberBuff[i] or {}
			if next(MemberBuff[i]) ~= nil and not bFound then
				if MemberBuff[i].dwID == tBuff.dwID then
					MemberBuff[i] = {}
					--n = i
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
	elseif nBuffShowType == 2 then
		BuffList[1] = clone(tBuff)
		local n = 2
		for i = 1, 4, 1 do
			MemberBuff[i] = MemberBuff[i] or {}
			if next(MemberBuff[i]) ~= nil and MemberBuff[i].dwID ~= tBuff.dwID then
				BuffList[n] = clone(MemberBuff[i])
				n = n + 1
			end
		end
	elseif nBuffShowType == 3 then
		local n = 1
		for i = 1, 4, 1 do
			MemberBuff[i] = MemberBuff[i] or {}
			if next(MemberBuff[i]) ~= nil and MemberBuff[i].dwID ~= tBuff.dwID then
				BuffList[n] = clone(MemberBuff[i])
				n = n + 1
			end
		end
		BuffList[n] = clone(tBuff)
		for i = 1, #BuffList - 4 do
			tremove(BuffList, 1)
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
	local MemberBuff = _NORMAL_BUFF_SHOW[dwPlayerID]
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
	for i = 1, 4 do
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

function LR_TeamBuffMonitor.OutputBossFocusBuff()
	Output(_BossFocus)
end

