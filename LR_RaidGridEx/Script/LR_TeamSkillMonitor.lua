local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_RaidGridEx"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_TeamGrid"
local _L = LR.LoadLangPack(AddonPath)
------------------------------------------------------
LR_TeamSkillMonitor = {
	SkillMonitorData = {},
}
local _hSkillBox = {}	---存放skillbox的handle
------------------------------------------------------
-----技能监控
------------------------------------------------------
LR_TeamSkillMonitor.SKILL_LIST = {
	[10080] = {		----奶秀
		{dwID = 569, enable = true, }, 	---王母
		{dwID = 555, enable = true, }, 		---风袖
		--{dwID = 548, enable = true, }, 		---龙池乐
		{dwID = 557, enable = true, }, 		---天地低昂
		{dwID = 551, enable = true, }, 		---战复
		{dwID = 574, enable = false, }, 		---蝶弄足
		{dwID = 552, enable = false, }, 		---邻里曲
		{dwID = 550, enable = false, }, 		---鹊踏枝
		{dwID = 568, enable = true, }, 		---繁音急节
		{dwID = 18221, enable = false, }, 		---余寒映日
		{dwID = 9002, enable = true, }, 		---扶摇
		{dwID = 9003, enable = true, }, 		---聂云
	},
	[10028] = {		----离经易道
		{dwID = 132, enable = true, }, 		---春泥
		{dwID = 140, enable = true, }, 		---彼针
		{dwID = 2663, enable = true, }, 		---听风吹雪
		{dwID = 136, enable = true, }, 		---水月无间
		{dwID = 143, enable = false, }, 		---大针
		{dwID = 141, enable = true, }, 		---毫针
		{dwID = 14963, enable = false, }, 		---大招
		{dwID = 131, enable = true, }, 		---碧水
		{dwID = 228, enable = true, }, 		---太阴指
		{dwID = 9002, enable = true, }, 		---扶摇
		{dwID = 9003, enable = true, }, 		---聂云
	},
	[10176] = {		----补天
		{dwID = 2231, enable = true, }, 		---蛊惑
		{dwID = 2957, enable = true, }, 		---圣手
		{dwID = 15132, enable = true, }, 		---蕨菜
		{dwID = 2234, enable = true, }, 		---鼎
		{dwID = 2235, enable = true, }, 		---千蝶
		{dwID = 2230, enable = true, }, 		---女娲
		{dwID = 2226, enable = true, }, 		---献祭
		{dwID = 2228, enable = true, }, 		---化蝶
		{dwID = 18584, enable = true, }, 		---灵蛊
		{dwID = 9002, enable = true, }, 		---扶摇
		{dwID = 9003, enable = true, }, 		---聂云
	},
	[10448] = {		-----相知
		{dwID = 14082, enable = true, }, 		---影子
		{dwID = 14075, enable = true, }, 		---平伤害盾
		{dwID = 14076, enable = true, }, 		---浮空
		{dwID = 14084, enable = true, }, 		---战复
		{dwID = 15068, enable = false, }, 		---偷buff
		{dwID = 9002, enable = true, }, 		---扶摇
		{dwID = 9003, enable = true, }, 		---聂云
	},
}


local DefaultSkillMonitorList = {
	[10080] = {		----奶秀
		{dwID = 569, enable = true, }, 	---王母
		{dwID = 555, enable = true, }, 		---风袖
		--{dwID = 548, enable = true, }, 		---龙池乐
		{dwID = 557, enable = true, }, 		---天地低昂
		{dwID = 551, enable = true, }, 		---战复
		{dwID = 9002, enable = true, }, 		---扶摇
		{dwID = 9003, enable = true, }, 		---聂云
	},
	[10028] = {		----离经易道
		{dwID = 132, enable = true, }, 		---春泥
		{dwID = 140, enable = true, }, 		---彼针
		{dwID = 2663, enable = true, }, 		---听风吹雪
		{dwID = 131, enable = true, }, 		---碧水
		{dwID = 9002, enable = true, }, 		---扶摇
		{dwID = 9003, enable = true, }, 		---聂云
	},
	[10176] = {		----补天
		{dwID = 2231, enable = true, }, 		---蛊惑
		{dwID = 2957, enable = true, }, 		---圣手
		{dwID = 15132, enable = true, }, 		---蕨菜
		{dwID = 2234, enable = true, }, 		---鼎
		{dwID = 2235, enable = true, }, 		---千蝶
		{dwID = 2230, enable = true, }, 		---女娲
		{dwID = 2226, enable = true, }, 		---献祭
		{dwID = 9002, enable = true, }, 		---扶摇
		{dwID = 9003, enable = true, }, 		---聂云
	},
	[10448] = {		-----相知
		{dwID = 14082, enable = true, }, 		---影子
		{dwID = 14075, enable = true, }, 		---平伤害盾
		{dwID = 14076, enable = true, }, 		---浮空
		{dwID = 14084, enable = true, }, 		---战复
		{dwID = 9002, enable = true, }, 		---扶摇
		{dwID = 9003, enable = true, }, 		---聂云
	},
}

local DefaultSkillMonitorData = {
	Version = "20171231",
	data = clone(DefaultSkillMonitorList),
}

-----------------------------------------------
----自身技能CD监控
------------------------------------------------
local _SkillBox = {
	handle = nil,
	dwID = nil,
	nLevel = 0,
	nEndFrame = 0,
	nTotalFrame = 0,
	nTime = 0,
	nOrder = 1,
}
_SkillBox.__index = _SkillBox

function _SkillBox:new(dwID)
	local o = {}
	setmetatable(o, self)
	o.dwID = dwID
	o.parentHandle = LR_TeamGrid.Handle_Skill_Box
	return o
end

function _SkillBox:Create()
	local parentHandle = self.parentHandle
	local dwID = self.dwID
	local Handle_Skill_Box = parentHandle:Lookup(sformat("Handle_Skill_Box_%d", dwID))
	if not Handle_Skill_Box then
		local szIniFile = sformat("%s\\UI\\%s\\SkillBox.ini", AddonPath, LR_TeamGrid.UsrData.UI_Choose)
		Handle_Skill_Box = parentHandle:AppendItemFromIni(szIniFile, "Handle_Skill_Box", sformat("Handle_Skill_Box_%d", dwID))
--		local box = LR.AppendUI("Box", parentHandle, sformat("Box_%d", dwID), {w = 40, h = 40})
--		UpdateBoxObject(box:GetSelf(), 5, 9002, 11, GetClientPlayer().dwID)
-- 		UI_OBJECT = SetmetaReadonly({
-- 			NONE             = -1, -- 空Box
-- 			ITEM             = 0 , -- 身上有的物品。nUiId, dwBox, dwX, nItemVersion, nTabType, nIndex
-- 			SHOP_ITEM        = 1 , -- 商店里面出售的物品 nUiId, dwID, dwShopID, dwIndex
-- 			OTER_PLAYER_ITEM = 2 , -- 其他玩家身上的物品 nUiId, dwBox, dwX, dwPlayerID
-- 			ITEM_ONLY_ID     = 3 , -- 只有一个ID的物品。比如装备链接之类的。nUiId, dwID, nItemVersion, nTabType, nIndex
-- 			ITEM_INFO        = 4 , -- 类型物品 nUiId, nItemVersion, nTabType, nIndex, nCount(书nCount代表dwRecipeID)
-- 			SKILL            = 5 , -- 技能。dwSkillID, dwSkillLevel, dwOwnerID
-- 			CRAFT            = 6 , -- 技艺。dwProfessionID, dwBranchID, dwCraftID
-- 			SKILL_RECIPE     = 7 , -- 配方dwID, dwLevel
-- 			SYS_BTN          = 8 , -- 系统栏快捷方式dwID
-- 			MACRO            = 9 , -- 宏
-- 			MOUNT            = 10, -- 镶嵌
-- 			ENCHANT          = 11, -- 附魔
-- 			NOT_NEED_KNOWN   = 15, -- 不需要知道类型
-- 			PENDANT          = 16, -- 挂件
-- 			PET              = 17, -- 宠物
-- 			MEDAL            = 18, -- 宠物徽章
-- 			BUFF             = 19, -- BUFF
-- 			MONEY            = 20, -- 金钱
-- 			TRAIN            = 21, -- 修为
-- 			EMOTION_ACTION   = 22, -- 动作表情
-- 		})
	end
	self.handle = Handle_Skill_Box
	self:SetSkillLevel()
	self:SetEndFrameTime()
	self:SetSkillIcon()
	self:SetTimeText()

	Handle_Skill_Box:RegisterEvent(4194303)
	Handle_Skill_Box.OnItemMouseEnter = function()
		local szName = LR.Trim(Table_GetSkillName(dwID, 1))
		local nX, nY = this:GetAbsPos()
		local nW, nH = this:GetSize()
		local szText = {}
		szText[#szText+1] = GetFormatText(sformat("%s\n", szName), 224)
		szText[#szText+1] = GetFormatText(sformat("dwID:%d\n", dwID), 224)
		--OutputTip(tconcat(szText), 360, {nX, nY, nW, nH})
		OutputSkillTip(dwID, GetClientPlayer().GetSkillLevel(dwID), {nX, nY, nW, nH - 40})
	end
	Handle_Skill_Box.OnItemMouseLeave = function()
		HideTip()
	end
	return self
end

function _SkillBox:SetRelPos()
	local handle = self.handle
	local nOrder  = self.nOrder
	if LR_TeamGrid.UsrData.CommonSettings.skillBoxPos  ==  3 or LR_TeamGrid.UsrData.CommonSettings.skillBoxPos  ==  4 then
		handle:SetRelPos(0, (nOrder - 1) * 41)
	else
		handle:SetRelPos((nOrder - 1) * 41, 0)
	end
end

function _SkillBox:SetOrder(nOrder)
	self.nOrder = nOrder
	return self
end

function _SkillBox:SetTimeText()
	local Text_Skill_Remain_Time = self.handle:Lookup("Text_Skill_Remain_Time")
	local nTotalFrame = self.nTotalFrame
	local nEndFrame = self.nEndFrame
	local nowFrame = GetLogicFrameCount()
	local nLeftFrame = nEndFrame-nowFrame
	if nLeftFrame >0 then
		local ntime = mfloor(nLeftFrame / 16)
		Text_Skill_Remain_Time:SetText(ntime)
	else
		Text_Skill_Remain_Time:SetText("")
	end
	return self
end

function _SkillBox:SetSkillIcon()
	local dwID = self.dwID
	local nLevel = self.nLevel
	local nIcon = Table_GetSkillIconID(dwID, nLevel)
	local Box_Skill = self.handle:Lookup("Box_Skill")
	Box_Skill:SetObject(UI_OBJECT_NOT_NEED_KNOWN, 0)
	Box_Skill:SetObjectIcon(nIcon)
end

function _SkillBox:SetSkillID(dwID)
	self.dwID = dwID
	return self
end

function _SkillBox:GetTimeLeft()
	local text = "4"
	local Text_Skill_Remain_Time = self.handle:Lookup("Text_Skill_Remain_Time")
	Text_Skill_Remain_Time:SetText(text)

	return self
end

function _SkillBox:GetSkillLevel()
	return self.nLevel
end

function _SkillBox:SetSkillLevel(nLevel)
	if nLevel then
		self.nLevel = nLevel
	else
		local me = GetClientPlayer()
		local dwID = self.dwID
		if me then
			self.nLevel = me.GetSkillLevel(dwID)
		else
			self.nLevel = 0
		end
	end
	return self
end

function _SkillBox:SetEndFrameTime()
	local dwID = self.dwID
	local nLevel = self.nLevel
	local me = GetClientPlayer()
	if me then
		local isCDing, nLeftFrame, nTotalFrame, nNum, _ = me.GetSkillCDProgress(dwID, nLevel)
		local nowFrame = GetLogicFrameCount()
		self.nEndFrame = nowFrame + nLeftFrame
		self.nTotalFrame = nTotalFrame
	else
		self.nEndFrame = 0
		self.nTotalFrame = 0
	end
end

function _SkillBox:SetCoolDownPercentage()
	local nEndFrame = self.nEndFrame
	local nowFrame = GetLogicFrameCount()
	local nTotalFrame = self.nTotalFrame
	local nLeftFrame = nEndFrame-nowFrame
	local Box_Skill = self.handle:Lookup("Box_Skill")
	if self.nLevel > 0 then
		if nLeftFrame > 0 and nTotalFrame > 0 then
			Box_Skill:SetObjectCoolDown(true)
			Box_Skill:SetCoolDownPercentage(1-nLeftFrame/nTotalFrame)
			if nLeftFrame <5 then
				Box_Skill:SetObjectSparking(true)
			end
		else
			Box_Skill:SetObjectCoolDown(false)
			Box_Skill:SetCoolDownPercentage(1)
		end
	else
		Box_Skill:SetObjectCoolDown(true)
		Box_Skill:SetCoolDownPercentage(0)
	end
	return self
end

function _SkillBox:GetnTime()
	return self.nTime
end

function _SkillBox:SetnTime(nTime)
	self.nTime = nTime
	return self
end

-----------------------------------------------------------------
function LR_TeamSkillMonitor.SaveCommonData()
	local path = sformat("%s\\UsrData\\CommonSkillMonitor.dat", SaveDataPath)
	local data = LR_TeamSkillMonitor.SkillMonitorData or {}
	SaveLUAData(path, data)
end

function LR_TeamSkillMonitor.CheckCommonData()
	local path = sformat("%s\\UsrData\\CommonSkillMonitor.dat", SaveDataPath)
	local data = LoadLUAData(path) or {}
	if data.Version and data.Version  ==  DefaultSkillMonitorData.Version then
		return
	end
	LR_TeamSkillMonitor.SkillMonitorData = clone(DefaultSkillMonitorData)
	LR_TeamSkillMonitor.SaveCommonData()
end

function LR_TeamSkillMonitor.LoadCommonData()
	LR_TeamSkillMonitor.CheckCommonData()
	local path = sformat("%s\\UsrData\\CommonSkillMonitor.dat", SaveDataPath)
	local data = LoadLUAData(path) or {}
	LR_TeamSkillMonitor.SkillMonitorData = clone(data)
end

function LR_TeamSkillMonitor.ResetCommonData()
	local path = sformat("%s\\UsrData\\CommonSkillMonitor.dat", SaveDataPath)
	local data = clone(DefaultSkillMonitorData)
	SaveLUAData(path, data)
	LR_TeamSkillMonitor.SkillMonitorData = clone(data)
end

------------------------------------------------------------------
function LR_TeamSkillMonitor.ShowSkillPanel()
	local frame = Station.Lookup("Normal/LR_TeamGrid")
	if not frame then
		return
	end
	LR_TeamGrid.Handle_Skill_Box:Clear()
	LR_TeamGrid.Handle_Skill_Box:GetParent():SetRelPos(-40, 30)
	_hSkillBox = {}
	if LR_TeamGrid.bMiniPanel then
		return
	end
	if not LR_TeamGrid.UsrData.CommonSettings.bShowSkillBox then
		LR_TeamGrid.UpdateRoleBodySize()
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local kungfu = me.GetKungfuMount()
	local dwSkillID = kungfu.dwSkillID
	if dwSkillID == 10028 or dwSkillID == 10080 or dwSkillID == 10176 or dwSkillID == 10448  then
		local data = LR_TeamSkillMonitor.SkillMonitorData.data[dwSkillID] or {}
		local n = 1
		for i = 1, #data, 1 do
			if data[i].enable then
				local dwID = data[i].dwID
				local szName = LR.Trim(Table_GetSkillName(dwID, 1))
				local h = _SkillBox:new(dwID)
				h:Create():SetOrder(n):SetRelPos()
				_hSkillBox[szName] = h
				n = n+1
			end
		end
		LR_TeamGrid.Handle_Skill_Box:FormatAllItemPos()
		LR_TeamGrid.Handle_Skill_Box:SetSizeByAllItemSize()
		local width, height = LR_TeamGrid.Handle_Skill_Box:GetSize()
		LR_TeamGrid.Handle_Skill_Box:GetParent():SetSize(width, height)
		LR_TeamGrid.ReDrawAllMembers()
	end
	LR_TeamGrid.UpdateRoleBodySize()
end

function LR_TeamSkillMonitor.RefreshAllSkillBox()
	-----自身技能CD监控
	if LR_TeamGrid.UsrData.CommonSettings.bShowSkillBox then
		for szName, v in pairs (_hSkillBox) do
			if _hSkillBox[szName] then
				_hSkillBox[szName]:SetEndFrameTime()
				_hSkillBox[szName]:SetTimeText()
				_hSkillBox[szName]:SetCoolDownPercentage()
			end
		end
	end
end

function LR_TeamSkillMonitor.GetSkillMonitorOrder(dwForceID, dwID)
	for i = 1, #LR_TeamSkillMonitor.SkillMonitorData.data[dwForceID], 1 do
		if LR_TeamSkillMonitor.SkillMonitorData.data[dwForceID][i].dwID  ==  dwID then
			return i
		end
	end
	return 0
end

----------------------------------------------------------------------
function LR_TeamSkillMonitor.LOGIN_GAME()
	LR_TeamSkillMonitor.LoadCommonData()
	Log("[LR] : Loaded LR_TeamSkillMonitor.CommonData")
end

function LR_TeamSkillMonitor.SKILL_MOUNT_KUNG_FU()
	LR.DelayCall(250, function()
		LR_TeamSkillMonitor.ShowSkillPanel()
	end)
end

function LR_TeamSkillMonitor.SKILL_UPDATE()
	local dwID = arg0
	local nLevel = arg1
	local szName = LR.Trim(Table_GetSkillName(dwID, nLevel))
	if _hSkillBox[szName] then
		_hSkillBox[szName]:SetSkillID(dwID)
		_hSkillBox[szName]:SetSkillLevel(nLevel)
	end
	LR.DelayCall(250, function() LR_TeamSkillMonitor.ReFreshAllSkillLevel() end)
end

function LR_TeamSkillMonitor.DO_SKILL_CAST()
	local dwCaster = arg0
	local dwSkillID = arg1
	local dwLevel = arg2
	local me = GetClientPlayer()
	if not me then
		return
	end
	local kungfu = me.GetKungfuMount()
	local dwKungSkillID = kungfu.dwSkillID
	if not (dwKungSkillID == 10028 or dwKungSkillID == 10080 or dwKungSkillID == 10176 or dwKungSkillID == 10448)  then
		return
	end
--[[	local szName = LR.Trim(Table_GetSkillName(dwSkillID, dwLevel))
	if szName ~= "" then
		Output(dwCaster, szName, dwSkillID)
	end]]
	if dwCaster  ==  me.dwID then
		local szName = LR.Trim(Table_GetSkillName(dwSkillID, dwLevel))
		if _hSkillBox[szName] then
			if szName == _L["MiXian"] and dwSkillID ~= 15132 then
				return
			end
			local nTime = GetTime()
			if nTime - _hSkillBox[szName]:GetnTime() > 500 then
				--LR.DelayCall(100, function()
					_hSkillBox[szName]:SetnTime(nTime):SetSkillID(dwSkillID):SetSkillLevel(dwLevel):SetEndFrameTime()
				--end)
			end
		end
		--五毒
		--LR_TeamSkillMonitor.QiXueFreshCD(10176, 14866, dwSkillID, 2957, 2957)	--织心奇穴

	else
--[[		if not IsPlayer(dwCaster) then
			local npc = GetNpc(dwCaster)
			if npc and npc.dwEmployer == me.dwID then
				--奶毒
				LR_TeamSkillMonitor.QiXueFreshCD(10176, 18312, dwSkillID, 2474, 2226)	--蝎毒奇穴
				LR_TeamSkillMonitor.QiXueFreshCD(10176, 18312, dwSkillID, 2474, 2228)	--蝎毒奇穴
			end
		end]]
	end
end

function LR_TeamSkillMonitor.QiXueFreshCD(dwKungSkillID, dwQiXueSkillID, dwCastSkillID, dwTriggerSkillID, dwActionSkillID)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local kungfu = me.GetKungfuMount()
	local dwKungSkillID = kungfu.dwSkillID
	if not (dwKungSkillID == 10028 or dwKungSkillID == 10080 or dwKungSkillID == 10176 or dwKungSkillID == 10448)  then
		return
	end
	if dwKungSkillID == dwKungSkillID then	--奶毒
		if me.GetSkillLevel(dwQiXueSkillID) > 0 and LR.Trim(Table_GetSkillName(dwCastSkillID, 1)) == LR.Trim(Table_GetSkillName(dwTriggerSkillID, 1)) then
			if _hSkillBox[LR.Trim(Table_GetSkillName(dwActionSkillID, 1))] then
				LR.DelayCall(100, function()
					_hSkillBox[LR.Trim(Table_GetSkillName(dwActionSkillID, 1))]:SetEndFrameTime()
				end)
			end
		end
	end
end

function LR_TeamSkillMonitor.ReFreshAllSkillLevel()
	local me = GetClientPlayer()
	if not me then
		return
	end
	for szName, v in pairs (_hSkillBox) do
		if _hSkillBox[szName] then
			_hSkillBox[szName]:SetSkillLevel()
		end
	end
end

LR.RegisterEvent("LOGIN_GAME", function() LR_TeamSkillMonitor.LOGIN_GAME() end)

