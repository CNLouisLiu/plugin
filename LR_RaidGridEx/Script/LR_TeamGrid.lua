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
local _KungfuText={
	[0] = {text =_L["xia"], rgb = {LR.GetMenPaiColor(0)}},
	[10002] = {text = _L["xi"], rgb = {LR.GetMenPaiColor(1)}},
	[10003] = {text = _L["yi"], rgb = {LR.GetMenPaiColor(1)}},
	[10021] = {text = _L["hua"], rgb = {LR.GetMenPaiColor(2)}},
	[10028] = {text = _L["li"], rgb = {LR.GetMenPaiColor(2)}},
	[10026] = {text = _L["ao"], rgb = {LR.GetMenPaiColor(3)}},
	[10062] = {text = _L["tie"], rgb = {LR.GetMenPaiColor(3)}},
	[10014] = {text = _L["qi"], rgb = {LR.GetMenPaiColor(4)}},
	[10015] = {text = _L["jian"], rgb = {LR.GetMenPaiColor(4)}},
	[10080] = {text = _L["yun"], rgb = {LR.GetMenPaiColor(5)}},
	[10081] = {text = _L["bing"], rgb = {LR.GetMenPaiColor(5)}},
	[10175] = {text = _L["du"], rgb = {LR.GetMenPaiColor(6)}},
	[10176] = {text = _L["bu"], rgb = {LR.GetMenPaiColor(6)}},
	[10224] = {text = _L["yu"], rgb = {LR.GetMenPaiColor(7)}},
	[10225] = {text = _L["gui"], rgb = {LR.GetMenPaiColor(7)}},
	[10144] = {text = _L["wen"], rgb = {LR.GetMenPaiColor(8)}},
	[10145] = {text = _L["shan"], rgb = {LR.GetMenPaiColor(8)}},
	[10268] = {text = _L["gai"], rgb = {LR.GetMenPaiColor(9)}},
	[10242] = {text = _L["ying"], rgb = {LR.GetMenPaiColor(10)}},
	[10243] = {text = _L["liu"], rgb = {LR.GetMenPaiColor(10)}},
	[10389] = {text = _L["gu"], rgb = {LR.GetMenPaiColor(21)}},
	[10390] = {text = _L["fen"], rgb = {LR.GetMenPaiColor(21)}},
	[10447] = {text = _L["mo"], rgb = {LR.GetMenPaiColor(22)}},
	[10448] = {text = _L["zhi"], rgb = {LR.GetMenPaiColor(22)}},
	[10464] = {text = _L["ba"], rgb = {LR.GetMenPaiColor(23)}},
	[10533] = {text = _L["peng"], rgb = {LR.GetMenPaiColor(24)}},
}
local TEAM_VOTE={
	DELETE_MEMBER=0,
	DISTRIBUTE_MONEY=1,
}
local VOTE_RESPONSE={
	AGREE = 1,
	DISAGREE = 0,
}
----------拍团请求
local _Gold_Confirm={
	all=0,
	agree=0,
	stopTime=0,
	nType=nil,
}
----标记图片
local tMarkerImageList = {66, 67, 73, 74, 75, 76, 77, 78, 81, 82}
---------------------------------------------------------------
local DefaultCommonSettings = {
	bOn = false,
	nGridType = 2,		---1：5列模式，2:3+2模式
	bLockLocation = false,
	bDisableTeamNum = false,
	bLockGroup = false,
	scale={fx=1, fy=1,},
	Anchor = {x = 40, y = 250,},
	bShowSystemGridPanel = false,	--是否显示系统面板
	bShowOnlyInRaidMode = false,	--是否只在团队模式下显示
	bShowSystemTeamPanel = false,	--是否显示系统小队面板
	bShowDistributeWarn = true,	--显示分配有问题的对话
	bInCureMode = true,	--是否治疗模式
	cureMode = 1,		--治疗模式方式1：划过自动选，2：按技能时选
	autoPercentInCure = true,	--切治疗时自动换成百分比
	--血量设置
	bShortBlood = true,	--是否精简血量显示
	nDecimalPoint = 2,	--小数点后X位	0：1位；1:1位；2:2位
	lifeTextType = 1,	--1：剩余数值；2：损耗血量；3：不显示血量
	bShowBloodInPercent = false,	--是否显示百分比
	bloodTextScale = 1,	--血量缩放设置
	--血量蓝量危险设置
	bShowLifeDanger = true,
	bShowManaDanger = true,
	nLifeDanger = 0.3,
	nManaDanger = 0.3,
	--血条颜色设置
	bShowDistanceText = false,
	backGroundColorType = 4,	--血条着色设置。1：固定颜色；2：按门派着色；3:按阵营着色；4：按距离着色；5：按血量着色
	backGroundFixedColor = {155, 155, 155},
	--distanceColorType = 1,	--1:按距离着色；2:透明度着色；3：不区分距离
	backGroundAlphaType = 1,	--血量透明度着色。1：固定透明度；2：按距离透明度；3：按血量透明度
	backGroundFixedAlpha = 255,
	bgColorFillType = 2,	--1：不渲染、纯色;2：中间有条阴影；3：默认方式
	TitleButton = {
		ShowLootModeBtn = true,
		ShowLootLevelBtn = true,
		ShowWorldMarkBtn = true,
		ShowGoldTeamBtn = true,
		ShowTeamNoticeBtn = true,
		ShowVoiceBtn = true,
		ShowMiniBtn = true,
	},

	distanceLevel = {
		[1] = 8,
		[2] = 20,
		[3] = 24,
	},
	distanceColor = {
		[1] = {104, 198, 83},
		[2] = {104, 198, 83},
		[3] = {181, 172, 0},
		[4] = {206, 70, 70},
		[5] = {155, 155, 155},
	},
	distanceAlpha = {
		[1] = 255,
		[2] = 255,
		[3] = 200,
		[4] = 120,
		[5] = 60,
	},
	bloodLevelSet = {	---血量百分百设置
		[1] = 0.75,
		[2] = 0.4,
		[3] = 0,
	},
	bloodLevelColor = {	--不同血量颜色
		[1] = {104, 198, 83},		--绿
		[2] = {181, 172, 0},		--橙
		[3] = {206, 70, 70},		--红
	},
	bloodLevelAlpha = {		--不同血量透明度
		[1] = 255,
		[2] = 204,
		[3] = 102,
	},

	--Tip设置
	bShowNewTip = true,
	disableTipWhenFight = false,	--战斗时不显示tip
	--名字设置
	szFontScheme = 7, --字体设置
	szFontColor = 1,	--1:根据门派着色；2：根据阵营着色；3：不着色
	nNameNumLimit = 5,	--名字个数限制
	nameTextScale = 1,	---名字缩放设置
	nameFontSpacing = 0,		--字间距
	--心法显示
	kungFuShowType = 2,	--1：心法图标；2：心法文字；3：阵营图标；4：阵营文字
	kungFuTextScale = 1,	--心法文字缩放比例
	--鼠标操作
	mouseAction = {
		LButtonDBClick = 0,		--0:什么都不做，1：跟随
		LButtonDBClickAlt = 0,	--0：什么都不做，1：交易
		LButtonDBClickShfit = 0,	--0：什么都不做
		LButtonDBClickCtrl = 0,		--0：什么都不做
		MouseEnterAlt = 1,	--什么都不做 1：显示dps
		MouseEnterShift = 1,	--什么都不做，1：显示重伤记录
	},
	--技能盒子
	bShowSkillBox = true,
	skillBoxPos = 3,	---1：上， 2：下，3：左，4：右。
	--Boss读条
	bShowBossOT = true,
	bShowBossOTOnlyInCure = false,
	--Boss目标
	bShowBossTarget = true,
	bShowSmallBossTarget = true,
	--Boss点名
	bShowBossFocus = true,
	nBossFocusAlpha = 120,
	--醒目BUFF
	nSpecialBuffAlpha = 120,
	--Debuff监控
	debuffMonitor = {
		bOff = false,	---关闭debuff监控
		buffMonitorNum = 4,	---buff监控数量
		bShowDebuffCDAni = true,		--buffCD 阴影
		debuffCDAniAlpha = 180,		--buffCD阴影透明度
		buffTextType = 1,		--1:显示buff层数;2:显示buff剩余时间
		bShowStack = true,
		bShowLeftTime = true,
		debuffShadow = {
			bShow = true,		--显示debuff颜色
			nBorder = 2,		--debuff颜色边框宽度
			alpha = 255,		--边框透明度
		},
		nBuffShowType = 1, 		--1:传统模式，2：BUFF自动缩进，新BUFF插入第一个，3：BUFF自动缩进，新BUFF自动放入末尾
	},
}
local DefaultData = {
	UI_Choose = "Classic",
	VERSION = VERSION,
	CommonSettings = clone(DefaultCommonSettings),
}
---------------------------------------------------------------
LR_TeamGrid = LR_TeamGrid or {
	bOn = false,
	Anchor = clone(DefaultCommonSettings.Anchor),
	frameSelf = nil,		--主界面frame
	UsrData = clone(DefaultData),
	UIConfig = nil,
	UIList = {},
	target = nil,		-----玩家当前的目标
	cureTarget = nil,		---玩家治疗时，点击面板确定的目标
	cureLock = false,		---治疗时的锁，当鼠标移动进格子，会锁住，不会选中cureTarget
	hoverHandle = nil,	---悬停时的handle
}
local CustomVersion = "20180111"
RegisterCustomData("LR_TeamGrid.bOn", CustomVersion)
RegisterCustomData("LR_TeamGrid.Anchor", CustomVersion)

local _tRoleGrids = {}	--存放_RoleGrid数据，队友
local _tExtendGrids = {}	--存放_RoleGrid数据，拖拽时临时增加的格子
local _Members = {}	--存放人物数据，包括进队以及离队的，缓存
local _tPartyMark = {}	--存放标记
local bDraged = false
local _JCG = {}	--用于存放切了剑的长歌
local _tBossFocusList = {}
--存放npc,player缓存
LR_TeamGrid.NPC_Cache = {}
LR_TeamGrid.Player_Cache = {}
---------------------------------------------------------------
LR_TeamGrid_Panel = {}

---------------------------------------------------------------
local _RoleGrid={
	handle = nil,
	dwID = nil,
	parentHandle = nil,
}
_RoleGrid.__index = _RoleGrid

function _RoleGrid:new(dwID)
	local o={}
	setmetatable(o,self)
	o.dwID = dwID
	o.nCol = 0
	o.nRealCol = 0
	o.nRow = 0
	o.szName = ""
	o.nameColor = {255, 255, 255}
	o.UI = clone({})
	o.parentHandle = LR_TeamGrid.Handle_Roles
	return o
end

function _RoleGrid:AppendRoleGrid()
	local parentHandle = self.parentHandle
	local dwID = self.dwID
	local RoleGridConfig = LoadLUAData(sformat("%s\\UI\\%s\\Role", AddonPath, LR_TeamGrid.UsrData.UI_Choose)) or {}
	self.UI = {}
	for i = 1, #RoleGridConfig do
		v = RoleGridConfig[i]
		local Parent
		if not v.Parent then
			Parent = parentHandle
		else
			Parent = self.UI[v.Parent]
		end
		if v.nType == "Handle" then
			self.UI[v.name] = LR.AppendUI("Handle", Parent, v.name, {w = v.w, h = v.h, x = v.x, y = v.y, eventid = 0})
		elseif v.nType == "Image" then
			self.UI[v.name] = LR.AppendUI("Image", Parent, v.name, {w = v.w, h = v.h, x = v.x, y = v.y, eventid = 0})
			self.UI[v.name]:FromUITex(v.Image, v.Frame)
		elseif v.nType == "Text" then
			self.UI[v.name] = LR.AppendUI("Text", Parent, v.name, {w = v.w, h = v.h, x = v.x, y = v.y, text = v.Text, eventid = 0})
		elseif v.nType == "Shadow" then
			self.UI[v.name] = LR.AppendUI("Shadow", Parent, v.name, {w = v.w, h = v.h, x = v.x, y = v.y, eventid = 0})
		elseif v.nType == "Animate" then
			self.UI[v.name] = LR.AppendUI("Animate", Parent, v.name, {w = v.w, h = v.h, x = v.x, y = v.y, eventid = 0})
			self.UI[v.name]:SetAnimate(v.Image, v.Group, v.LoopCount)
		elseif v.nType == "PSS" then
			self.UI[v.name] = Parent:AppendItemFromIni(v.path, v.section, v.name)
		end
		if v.LockShowAndHide and v.LockShowAndHide == 1 then self.UI[v.name]:Hide() end
		if v.Alpha then self.UI[v.name]:SetAlpha(v.Alpha) end
		if v.ImageType and v.nType == "Image" then self.UI[v.name]:SetImageType(v.ImageType) end
		if v.PosType then self.UI[v.name]:SetPosType(v.PosType) end
	end

	self.UI["Handle_RoleDummy"]:SetName(sformat("Handle_RoleGrid_%d", dwID))
	self.UI[sformat("Handle_RoleGrid_%d", dwID)] = self.UI["Handle_RoleDummy"]
	return self.UI[sformat("Handle_RoleGrid_%d", dwID)]
end

function _RoleGrid:Create()
	self.parentHandle = LR_TeamGrid.Handle_Roles
	if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 then
		if self.nRealCol > 2 then
			self.parentHandle = LR_TeamGrid.Handle_RolesSub
		end
	end
	local parentHandle = self.parentHandle
	local dwID = self.dwID
	--local handle = parentHandle:Lookup(sformat("Handle_RoleGrid_%d", dwID))

	local handle = parentHandle:Lookup(sformat("Handle_RoleGrid_%d", dwID))
	if not handle then
		handle = self:AppendRoleGrid()
		--local szIniFile = sformat("%s\\UI\\%s\\Role.ini", AddonPath, LR_TeamGrid.UsrData.UI_Choose)
		--handle = parentHandle:AppendItemFromIni(szIniFile, "Handle_RoleDummy", sformat("Handle_RoleGrid_%d", dwID))
	end
	self.handle = handle
	handle:SetRelPos(0, 0)
	handle:Show()
	handle:RegisterEvent(4194303)
	--handle:RegisterEvent(4096)
	----------------------------------------------
	--鼠标进入
	----------------------------------------------
	handle:GetHandle().OnItemMouseEnter=function()
		handle:Lookup("Image_Hover"):Show()
		if bDraged then
			local dwID = dwID
			if dwID < 100 then
				dwID = 0
			end
			LR_TeamGrid.nDragChooseGridEnd = {nCol = self.nRealCol, nRow = self.nRow, dwID = dwID}
		else
			--local nX, nY = parentHandle:GetAbsPos()
			--local nW, nH = parentHandle:GetSize()
			local hHandle = this:GetParent():GetParent()
			local nX, nY = hHandle:GetAbsPos()
			local nW, nH = hHandle:GetSize()
			if LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 4 then
				nW = nW + 40
			end
			--local nX, nY = LR_TeamGrid.frameSelf:GetAbsPos()
			--local nW, nH = LR_TeamGrid.frameSelf:GetSize()
			if IsAltKeyDown() and LR_TeamGrid.UsrData.CommonSettings.mouseAction.MouseEnterAlt == 1 then
				if not MY_Recount then
					LR.SysMsg(sformat("%s\n", _L["Tips:Hold Alt when hover,will show HPS/DPS,MY DPS required."]))
					return
				end
				LR_TeamTools.DPS.FIGHT_HINT()
				LR_TeamTools.DPS.OutputDPSRecord (dwID, {nX, nY, nW, nH - 40})
			elseif IsShiftKeyDown() and LR_TeamGrid.UsrData.CommonSettings.mouseAction.MouseEnterShift == 1 then
				LR_TeamTools.DeathRecord.OutputDeathRecord (dwID,{nX, nY, nW, nH - 40})
			else
				LR_TeamGrid.cureLock = true
				LR_TeamGrid.hoverHandle = self
				if LR_TeamGrid.UsrData.CommonSettings.bInCureMode then -- and RaidGridEx.CureModeSelectMode and RaidGridEx.CureModeSelectMode == 1 then
					local me =  GetClientPlayer()
					if not me then
						return
					end
					if LR.IsNurse() then
						if LR_TeamGrid.UsrData.CommonSettings.cureMode == 1 then
							LR_TeamGrid.timeCache = GetLogicFrameCount()
							LR_TeamGrid.cureTargetInTeam = dwID
							if _JCG[dwID] then
								LR_TeamGrid.cureTargetInTeam = _JCG[dwID]
							end
							if LR_TeamGrid.IfTargetCanBSelect(dwID) then
								LR_TeamGrid.SetTarget(dwID)
							end
						end
					end
				end
				if not (LR_TeamGrid.UsrData.CommonSettings.disableTipWhenFight and GetClientPlayer().bFightState) then
					LR_TeamGrid.OutputTeamMemberTip(dwID, {nX , nY , nW, nH - 40})
				end
			end
		end
	end

	----------------------------------------------
	--鼠标离开
	----------------------------------------------
	handle:GetHandle().OnItemMouseLeave=function()
		if handle:Lookup("Image_Hover") then handle:Lookup("Image_Hover"):Hide() end
		HideTip()
	end

	----------------------------------------------
	--鼠标右击
	----------------------------------------------
	handle:GetHandle().OnItemRButtonClick = function()
		local team =  GetClientTeam()
		if not team then return end
		local dwID = dwID
		local menu = {}
		local me = GetClientPlayer()
		local info = team.GetMemberInfo(dwID)
		local szPath, nFrame = GetForceImage(info.dwForceID)
		menu[#menu+1]={szOption = info.szName, szLayer = "ICON_RIGHT", rgb = {LR.GetMenPaiColor(info.dwForceID)}, szIcon = szPath, nFrame = nFrame,}
		if  LR_TeamGrid.IsLeader(me.dwID) and me.IsInRaid() then
			menu[#menu+1]={bDevide = true,}
			LR_TeamGrid.InsertChangeGroupMenu(menu, dwID)
		end
		if dwID ~= me.dwID then
			menu[#menu+1]={bDevide = true,}
			InsertTeammateMenu(menu, dwID)
			menu[#menu+1]={bDevide = true,}
			if GVoiceBase_IsMemberForbid(dwID) then
				menu[#menu+1]={szOption=_L["Cancel shielded speech"], fnAction = function() GVoiceBase_ForbidMember(dwID, false) end,}
			else
				menu[#menu+1]={szOption=_L["Shielded speech"], fnAction = function() GVoiceBase_ForbidMember(dwID, true) end,}
			end
			menu[#menu+1]=LR.GetTradeMenu(dwID)[1]
			menu[#menu+1]=LR.GetEquipmentMenu(dwID)[1]
			menu[#menu+1]={szOption=_L["Check Attribute"],fnAction=function() LR.ViewCharInfoToPlayer(dwID) end,}
			menu[#menu+1]=LR.GetMoreInfoMenu(dwID)[1]
			menu[#menu+1]=LR.GetShiTuMenu(dwID)[1]
			menu[#menu+1]={bDevide = true,}
			menu[#menu+1]=LR.GetInviteJJCTeamMenu(dwID)[1]
			menu[#menu+1]=LR.GetRevengeMenu(dwID)[1]
			menu[#menu+1]=LR.GetWantedMenu(dwID)[1]
		else
			menu[#menu+1]={bDevide = true,}
			InsertPlayerMenu(menu ,dwID)
		end
		if #menu > 0 then
			PopupMenu(menu)
		end
	end

	----------------------------------------------
	--鼠标左击
	----------------------------------------------
	handle:GetHandle().OnItemLButtonClick = function()
		if LR.IsMapBlockAddon() and GetClientPlayer() and GetClientPlayer().nMoveState == MOVE_STATE.ON_DEATH then
			BattleField_MatchPlayer(dwID)
		elseif IsCtrlKeyDown() then
			LR.EditBox_AppendLinkPlayer(_Members[dwID].szName)
		else
			local dwID = dwID
			if _JCG[dwID] then
				dwID = _JCG[dwID]
			end

			if LR_TeamGrid.IfTargetCanBSelect(dwID) then
				LR_TeamGrid.SetTarget(dwID)
				LR_TeamGrid.HandClickTarget = dwID
				LR_TeamGrid.timeCache = GetLogicFrameCount()
				if LR_TeamGrid.UsrData.CommonSettings.bInCureMode then
					local dwKungfuID = UI_GetPlayerMountKungfuID()
					if dwKungfuID == 10028 or dwKungfuID == 10080 or dwKungfuID == 10176 or dwKungfuID == 10448 then
						LR_TeamGrid.cureTarget = dwID
					else
						LR_TeamGrid.cureTarget = nil
					end
				end
			end
		end
	end

	----------------------------------------------
	--鼠标左击双击
	----------------------------------------------
	handle:GetHandle().OnItemLButtonDBClick = function()
		if IsAltKeyDown() and LR_TeamGrid.UsrData.CommonSettings.mouseAction.LButtonDBClickAlt == 1 then
			local menu=LR.GetTradeMenu(dwID)
			if menu then
				local fnTrade=menu[1].fnAction
				fnTrade()
			end
		elseif IsShiftKeyDown() and LR_TeamGrid.UsrData.CommonSettings.mouseAction.LButtonDBClickShfit == 1 then
			---
		elseif IsCtrlKeyDown() and LR_TeamGrid.UsrData.CommonSettings.mouseAction.LButtonDBClickCtrl == 1 then
			---
		elseif LR_TeamGrid.UsrData.CommonSettings.mouseAction.LButtonDBClick == 1 then
			local menu=LR.GetFollowMenu(dwID)
			if menu then
				local fnFollow=menu[1].fnAction
				fnFollow()
			end
		end
	end

	----------------------------------------------
	--鼠标拖拽
	----------------------------------------------
	handle:GetHandle().OnItemLButtonDrag = function()
		local me = GetClientPlayer()
		if not me then
			return
		end
		if LR_TeamGrid.UsrData.CommonSettings.bLockGroup then
			return
		end
		if LR_TeamGrid.IsLeader(me.dwID) then
			if not bDraged then
				LR_TeamGrid.nDragChooseGridStart = {dwID = dwID}
			end
			bDraged = true
			LR_TeamGrid.UpdateTeamMember()
			LR_TeamGrid.DrawExtendGrid()
			LR_TeamGrid.OpenRaidDragPanel(dwID)
			HideTip()
		end
	end

	----------------------------------------------
	--鼠标拖拽结束
	----------------------------------------------
	handle:GetHandle().OnItemLButtonDragEnd = function()
		local me = GetClientPlayer()
		if not me then
			return
		end
		if LR_TeamGrid.UsrData.CommonSettings.bLockGroup then
			return
		end
		if LR_TeamGrid.IsLeader(me.dwID) then
			bDraged = false
			LR_TeamGrid.UpdateTeamMember()
			for k, v in pairs (_tExtendGrids) do
				if v then
					v:Remove()
					_tExtendGrids[k]=nil
				end
			end
			LR_TeamGrid.DrawAllMembers()
			local team = GetClientTeam()
			if team then
				if LR_TeamGrid.nDragChooseGridEnd then
					--Output(LR_TeamGrid.nDragChooseGridStart.dwID, LR_TeamGrid.nDragChooseGridEnd.nRealCol, LR_TeamGrid.nDragChooseGridEnd.dwID)
					team.ChangeMemberGroup(LR_TeamGrid.nDragChooseGridStart.dwID, LR_TeamGrid.nDragChooseGridEnd.nCol, LR_TeamGrid.nDragChooseGridEnd.dwID)
				end
			end
			LR_TeamGrid.nDragChooseGridEnd = nil
			LR_TeamGrid.nDragChooseGridStart = nil
			LR_TeamGrid.CloseRaidDragPanel(dwID)
		end
	end

	parentHandle:FormatAllItemPos()
	return self
end

function _RoleGrid:Remove()
	local parentHandle = self.parentHandle
	local dwID = self.dwID
	local handle = parentHandle:Lookup(sformat("Handle_RoleGrid_%d", dwID))
	if handle then
		parentHandle:RemoveItem(handle)
	end
	return self
end

function _RoleGrid:SetCol(nCol)
	self.nCol = nCol
	return self
end

function _RoleGrid:SetRealCol(nCol)
	self.nRealCol = nCol
	return self
end

function _RoleGrid:SetRow(nRow)
	self.nRow = nRow
	return self
end

function _RoleGrid:GetPlayerID()
	return self.dwID
end

function _RoleGrid:GetRelPos()
	local handle = self.handle
	return handle:GetRelPos()
end

function _RoleGrid:SetIndex(nIndex)
	self.handle:SetIndex(nIndex)
	return self
end

----设置角色格子大小
function _RoleGrid:SetRoleBodySize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.wholeRoleGrid.height * fy
	local width = UIConfig.wholeRoleGrid.width * fx
	local handle = self.handle
	handle:SetSize(width, height)
	handle:Lookup("Image_MonsterTarget"):SetSize(width+2, height+2)
	handle:Lookup("Image_MonsterTarget"):SetRelPos(-1, -1)
	handle:Lookup("Animate_Selected"):SetSize(width+2, height+2)
	handle:Lookup("Animate_Selected"):SetRelPos(-1, -1)
	handle:Lookup("Image_BG_Grid"):SetSize(width+2,height+2)
	handle:Lookup("Image_BG_Grid"):SetRelPos(-1, -1)
	handle:Lookup("Image_BG_EmptyGrid"):SetSize(width+2,height+2)
	handle:Lookup("Image_BG_EmptyGrid"):SetRelPos(-1, -1)
	handle:Lookup("Image_Hover"):SetSize(width+2,height+2)
	handle:Lookup("Image_Hover"):SetRelPos(-1, -1)
	--handle:Lookup("Image_BossFocus"):SetSize(width+2,height+2)
	--handle:Lookup("Image_BossFocus"):SetRelPos(-1, -1)

	local w, h = handle:Lookup("Handle_BossFocus"):Lookup("Handle_BossFocus_Fixed"):GetSize()	--SFX原始大小
	local fSFXX, fSFXY = width / w, height / h
	handle:Lookup("Handle_BossFocus"):Lookup("SFX_BossFocus"):Get3DModel():SetScaling(fSFXX, fSFXY, fSFXX)
	handle:Lookup("Handle_BossFocus"):Lookup("SFX_BossFocus"):SetRelPos(width/2, height/2)
	handle:Lookup("Handle_BossFocus"):FormatAllItemPos()

	handle:Lookup("Image_ReadyCheck"):SetSize(width, height)
	handle:Lookup("Image_ReadyCheck"):SetRelPos(0, 0)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:ShowSelectedImage(bShow)
	local handle = self.handle
	if bShow then
		handle:Lookup("Animate_Selected"):Show()
	else
		handle:Lookup("Animate_Selected"):Hide()
	end
end

function _RoleGrid:ShowEmptyGrid()
	local handle = self.handle
	handle:Lookup("Text_RoleName"):Hide()
	handle:Lookup("Text_Kungfu"):Hide()
	handle:Lookup("Text_LifeValue"):Hide()
	handle:Lookup("Image_LifeBG"):Hide()
	handle:Lookup("Image_Mana"):Hide()
	handle:Lookup("Image_ManaBG"):Hide()
	handle:Lookup("Image_BG_EmptyGrid"):Show()

	return self
end

function _RoleGrid:Scale()
	local handle = self.handle
	local CommonSettings = LR_TeamGrid.UsrData.CommonSettings
	local fx, fy = CommonSettings.scale.fx, CommonSettings.scale.fy
	--handle:Scale(fx, fy)
	return self
end

----设置角色格子位置
function _RoleGrid:SetRoleBodyRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local nCol = self.nCol
	local nRow = self.nRow
	local handle = self.handle
	local width = UIConfig.wholeRoleGrid.width
	local height = UIConfig.wholeRoleGrid.height
	local margin_x = UIConfig.wholeRoleGrid.margin_x
	local margin_y = UIConfig.wholeRoleGrid.margin_y
	local marginBody = UIConfig.marginBody
	local parentHandle = self.parentHandle
	local CommonSettings = LR_TeamGrid.UsrData.CommonSettings
	local fx, fy = CommonSettings.scale.fx, CommonSettings.scale.fy
	handle:SetRelPos(marginBody + nCol * (width + margin_x) * fx, marginBody + nRow * (height + margin_y) * fy)
	parentHandle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetRoleNameSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.roleName.height * fy
	local width = UIConfig.roleName.width * fx
	local handle = self.handle
	local parentHandle = self.parentHandle
	handle:Lookup("Text_RoleName"):SetSize(width, height)
	parentHandle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetRoleNameRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.roleName.top * fy
	local left = UIConfig.roleName.left * fx
	local handle = self.handle
	handle:Lookup("Text_RoleName"):SetRelPos(left, top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetRoleName(szName)
	self.szName = szName
	self:DrawRoleNameText()
	return self
end

function _RoleGrid:SetRoleNameColor(RGB)
	self.nameColor = RGB
	self:DrawRoleNameText()
	return self
end

function _RoleGrid:DrawRoleNameText()
	local dwID = self.dwID
	local handle = self.handle
	local szName = self.szName
	local r, g, b = 255, 255, 255
	local nNameNumLimit = LR_TeamGrid.UsrData.CommonSettings.nNameNumLimit
	local UIConfig = LR_TeamGrid.UIConfig
	local halign = UIConfig.roleName.halign
	local valign = UIConfig.roleName.valign
	if wslen(szName) > nNameNumLimit then
		szName = sformat("%s..", wssub(szName, 1, nNameNumLimit))
	end
	local MemberInfo = _Members[dwID]
	local dwMountKungfuID = MemberInfo.dwMountKungfuID
	local dwForceID = MemberInfo.dwForceID
	if LR_TeamGrid.UsrData.CommonSettings.szFontColor == 1 then
		if _KungfuText[dwMountKungfuID] then
			r, g, b = LR.GetMenPaiColor(dwForceID)
		end
	elseif LR_TeamGrid.UsrData.CommonSettings.szFontColor == 2 then
		r, g, b = unpack(LR.CampColor[MemberInfo.nCamp])
	end
	if MemberInfo.bDeathFlag or MemberInfo.nCurrentLife == 0 then
		--r, g, b = 255, 0, 0
	end
	if not MemberInfo.bIsOnLine then
		r, g, b = 96, 96, 96
	end
	handle:Lookup("Text_RoleName"):SetText(szName)
	handle:Lookup("Text_RoleName"):SetFontScheme(LR_TeamGrid.UsrData.CommonSettings.szFontScheme)
	handle:Lookup("Text_RoleName"):SetFontScale(LR_TeamGrid.UsrData.CommonSettings.nameTextScale)
	handle:Lookup("Text_RoleName"):SetFontSpacing(LR_TeamGrid.UsrData.CommonSettings.nameFontSpacing)
	handle:Lookup("Text_RoleName"):SetFontColor(r, g, b)
	handle:Lookup("Text_RoleName"):SetHAlign(halign)
	handle:Lookup("Text_RoleName"):SetVAlign(valign)
	handle:Lookup("Text_RoleName"):SetAlpha(255)
	return self
end

function _RoleGrid:SetLifeBarSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.lifeBar.height * fy
	local width = UIConfig.lifeBar.width * fx
	local handle = self.handle
	handle:Lookup("Image_LifeBG"):SetSize(width, height)
	handle:Lookup("Shadow_Life_Fade"):SetSize(width, height)
	handle:Lookup("Shadow_Life_Color"):SetSize(width, height)
	handle:Lookup("Image_Life_Danger"):SetSize(width, height)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetLifeBarRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.lifeBar.top * fy
	local left = UIConfig.lifeBar.left * fx
	local handle = self.handle
	handle:Lookup("Image_LifeBG"):SetRelPos(left,top)
	handle:Lookup("Shadow_Life_Fade"):SetRelPos(left,top)
	handle:Lookup("Shadow_Life_Color"):SetRelPos(left,top)
	handle:Lookup("Image_Life_Danger"):SetRelPos(left,top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:DrawLifeBar()
	local handle = self.handle
	local dwID = self.dwID
	local MemberInfo = _Members[dwID]
	local nCurrentLife = MemberInfo.nCurrentLife
	local nMaxLife = MemberInfo.nMaxLife
	local nLifePercentage = 1.0
	local r, g, b = unpack(LR_TeamGrid.UsrData.CommonSettings.distanceColor[5])
	local a = LR_TeamGrid.UsrData.CommonSettings.distanceAlpha[5]
	if _JCG[dwID] then
		local npc = GetNpc(_JCG[dwID])
		if npc then
			nCurrentLife = npc.nCurrentLife
			nMaxLife = npc.nMaxLife
		end
	end
	if nMaxLife > 0 then
		nLifePercentage = nCurrentLife / nMaxLife
	end

	local width, height = handle:Lookup("Image_LifeBG"):GetSize()
	local sha = handle:Lookup("Shadow_Life_Color")
	local lifeDanger = handle:Lookup("Image_Life_Danger")

	local _GetRGBA = function()
		local r, g, b, a
		local DistanceLevel = 5
		local BloodLevel = 1
		--距离
		if LR_TeamGrid.UsrData.CommonSettings.backGroundColorType == 4 or LR_TeamGrid.UsrData.CommonSettings.backGroundAlphaType == 2 then
			local player = GetPlayer(dwID)
			if _JCG[dwID] then
				player = GetNpc(_JCG[dwID])
			end

			if player then
				local distance = LR.GetDistance(player)
				if distance <= LR_TeamGrid.UsrData.CommonSettings.distanceLevel[1] then
					DistanceLevel = 1
				elseif distance <= LR_TeamGrid.UsrData.CommonSettings.distanceLevel[2] then
					DistanceLevel = 2
				elseif distance <= LR_TeamGrid.UsrData.CommonSettings.distanceLevel[3] then
					DistanceLevel = 3
				elseif distance <= 50 then
					DistanceLevel = 4
				else
					DistanceLevel = 5
				end
			else
				DistanceLevel = 5
			end
		end
		--透明度
		if LR_TeamGrid.UsrData.CommonSettings.backGroundColorType == 5 or LR_TeamGrid.UsrData.CommonSettings.backGroundAlphaType == 3 then
			if nLifePercentage >= LR_TeamGrid.UsrData.CommonSettings.bloodLevelSet[1] then
				BloodLevel = 1
			elseif nLifePercentage >= LR_TeamGrid.UsrData.CommonSettings.bloodLevelSet[2] then
				BloodLevel = 2
			elseif nLifePercentage >= LR_TeamGrid.UsrData.CommonSettings.bloodLevelSet[3] then
				BloodLevel = 3
			end
		end
		--血条着色设置。1：固定颜色；2：按门派着色；3:按阵营着色；4：按距离着色；5：按血量着色
		if LR_TeamGrid.UsrData.CommonSettings.backGroundColorType == 1 then 	--固定颜色
			r, g, b = unpack(LR_TeamGrid.UsrData.CommonSettings.backGroundFixedColor)
		elseif LR_TeamGrid.UsrData.CommonSettings.backGroundColorType == 2 then 	--按门派着色
			r, g, b = LR.GetMenPaiColor(MemberInfo.dwForceID)
		elseif LR_TeamGrid.UsrData.CommonSettings.backGroundColorType == 3 then 	--按阵营着色
			r, g, b = unpack(LR.CampColor[MemberInfo.nCamp])
		elseif LR_TeamGrid.UsrData.CommonSettings.backGroundColorType == 4 then 	--按距离着色
			r, g, b = unpack(LR_TeamGrid.UsrData.CommonSettings.distanceColor[DistanceLevel])
		elseif LR_TeamGrid.UsrData.CommonSettings.backGroundColorType == 5 then 	--按血量着色
			r, g, b = unpack(LR_TeamGrid.UsrData.CommonSettings.bloodLevelColor[BloodLevel])
		end

		--血量透明度着色。1：固定透明度；2：按距离透明度；3：按血量透明度
		if LR_TeamGrid.UsrData.CommonSettings.backGroundAlphaType == 1 then 	--固定颜色
			a = LR_TeamGrid.UsrData.CommonSettings.backGroundFixedAlpha
		elseif LR_TeamGrid.UsrData.CommonSettings.backGroundAlphaType == 2 then 	--按距离透明度
			a = LR_TeamGrid.UsrData.CommonSettings.distanceAlpha[DistanceLevel]
		elseif LR_TeamGrid.UsrData.CommonSettings.backGroundAlphaType == 3 then 	--按血量透明度
			a = LR_TeamGrid.UsrData.CommonSettings.bloodLevelAlpha[BloodLevel]
		end

		return r, g, b, a
	end

	if MemberInfo.bIsOnLine then
		r, g, b, a = _GetRGBA()

		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:ClearTriangleFanPoint()
		local x = width * nLifePercentage
		local y = height


		if LR_TeamGrid.UsrData.CommonSettings.bgColorFillType == 2 then
			local h, s, v = LR.rgb2hsv(r, g, b)
			local r1 ,g1, b1 = LR.hsv2rgb(h, s, mmax(10, v / 2))
			sha:AppendTriangleFanPoint(x, y/10*3, r1, g1, b1, a)
			sha:AppendTriangleFanPoint(x, y/10*2, r1, g1, b1, a)
			sha:AppendTriangleFanPoint(x, 0, r, g, b, a)
			sha:AppendTriangleFanPoint(0, 0 , r, g, b, a)
			sha:AppendTriangleFanPoint(0, y/10*2, r1, g1, b1, a)
			sha:AppendTriangleFanPoint(0, y/10*3, r1, g1, b1, a)
			sha:AppendTriangleFanPoint(0, y,  r, g, b, a)
			sha:AppendTriangleFanPoint(x, y , r, g, b, a)
		elseif LR_TeamGrid.UsrData.CommonSettings.bgColorFillType == 3 then
			local h, s, v = LR.rgb2hsv(r, g, b)
			local r1 ,g1, b1 = LR.hsv2rgb(h, s, mmax(10, v / 2))
			sha:AppendTriangleFanPoint(x, y/10*3, r, g, b, a)
			sha:AppendTriangleFanPoint(x, y/10*2, r, g, b, a)
			sha:AppendTriangleFanPoint(x, 0, r1, g1, b1, a)
			sha:AppendTriangleFanPoint(0, 0 , r1, g1, b1, a)
			sha:AppendTriangleFanPoint(0, y/10*2, r, g, b, a)
			sha:AppendTriangleFanPoint(0, y/10*3, r, g, b, a)
			sha:AppendTriangleFanPoint(0, y,  r1, g1, b1, a)
			sha:AppendTriangleFanPoint(x, y , r1, g1, b1, a)
		elseif LR_TeamGrid.UsrData.CommonSettings.bgColorFillType == 4 then
			local h, s, v = LR.rgb2hsv(r, g, b)
			local r1 ,g1, b1 = LR.hsv2rgb(h, s, mmax(10, v / 2))
			sha:AppendTriangleFanPoint(0, 0, r1, g1, b1, a)
			sha:AppendTriangleFanPoint(x, 0, r1, g1, b1, a)
			sha:AppendTriangleFanPoint(x, y / 4, r, g, b, a)
			sha:AppendTriangleFanPoint(x, y, r, g, b, a)
			sha:AppendTriangleFanPoint(0, y,  r, g, b, a)
			sha:AppendTriangleFanPoint(0, y / 4, r, g, b, a)
		elseif LR_TeamGrid.UsrData.CommonSettings.bgColorFillType == 5 then
			local h, s, v = LR.rgb2hsv(r, g, b)
			local r1 ,g1, b1 = LR.hsv2rgb(h, s, mmax(10, v / 5 * 3))
			local r2 ,g2, b2 = LR.hsv2rgb(h, s, mmin(255, v / 5 *3 + 125))
			sha:AppendTriangleFanPoint(x, y/10*3, r1, g1, b1, a)
			sha:AppendTriangleFanPoint(x, y/10*2, r1, g1, b1, a)
			sha:AppendTriangleFanPoint(x, 0, r2, g2, b2, a)
			sha:AppendTriangleFanPoint(0, 0 , r2, g2, b2, a)
			sha:AppendTriangleFanPoint(0, y/10*2, r1, g1, b1, a)
			sha:AppendTriangleFanPoint(0, y/10*3, r1, g1, b1, a)
			sha:AppendTriangleFanPoint(0, y,  r2, g2, b2, a)
			sha:AppendTriangleFanPoint(x, y , r2, g2, b2, a)
		else
			sha:AppendTriangleFanPoint(0, 0, r, g, b, a)
			sha:AppendTriangleFanPoint(x, 0, r, g, b, a)
			sha:AppendTriangleFanPoint(x, y, r, g, b, a)
			sha:AppendTriangleFanPoint(0, y, r, g, b, a)
		end

		sha:Show()

		if nLifePercentage < LR_TeamGrid.UsrData.CommonSettings.nLifeDanger and LR_TeamGrid.UsrData.CommonSettings.bShowLifeDanger
		and MemberInfo.bIsOnLine and not MemberInfo.bDeathFlag and MemberInfo.nCurrentLife ~= 0 then
			lifeDanger:SetAlpha(255)
			lifeDanger:Show()
		else
			lifeDanger:Hide()
		end
	else
		sha:Hide()
		lifeDanger:Hide()
	end
	return self
end

function _RoleGrid:SetManaBarSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.manaBar.height * fy
	local width = UIConfig.manaBar.width * fx
	local handle = self.handle
	handle:Lookup("Image_ManaBG"):SetSize(width, height)
	handle:Lookup("Image_Mana"):SetSize(width, height)
	handle:Lookup("Image_Mana_Danger"):SetSize(width, height)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetManaBarPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.manaBar.top * fy
	local left = UIConfig.manaBar.left * fx
	local handle = self.handle
	handle:Lookup("Image_ManaBG"):SetRelPos(left,top)
	handle:Lookup("Image_Mana"):SetRelPos(left,top)
	handle:Lookup("Image_Mana_Danger"):SetRelPos(left,top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:DrawManaBar()
	local handle = self.handle
	local dwID = self.dwID
	local MemberInfo = _Members[dwID]
	local nCurrentMana = MemberInfo.nCurrentMana
	local nMaxMana = MemberInfo.nMaxMana
	local nManaPercentage = 1.0
	if nMaxMana > 0 then
		nManaPercentage = nCurrentMana / nMaxMana
	end
	if MemberInfo.bIsOnLine then
		handle:Lookup("Image_Mana"):SetPercentage(nManaPercentage)
		handle:Lookup("Image_Mana"):Show()

		if nManaPercentage < LR_TeamGrid.UsrData.CommonSettings.nManaDanger and LR_TeamGrid.UsrData.CommonSettings.bShowManaDanger
		and MemberInfo.bIsOnLine and not MemberInfo.bDeathFlag and MemberInfo.nCurrentLife ~= 0 then
			handle:Lookup("Image_Mana_Danger"):SetAlpha(255)
			handle:Lookup("Image_Mana_Danger"):Show()
		else
			handle:Lookup("Image_Mana_Danger"):Hide()
		end
	else
		handle:Lookup("Image_Mana"):Hide()
		handle:Lookup("Image_Mana_Danger"):Hide()
	end
	return self
end

function _RoleGrid:SetKungfu(dwKungfuID)
	self.dwKungfuID = dwKungfuID
	return self
end

function _RoleGrid:SetKungfuTextSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.kungfuText.height * fy
	local width = UIConfig.kungfuText.width * fx
	local handle = self.handle
	handle:Lookup("Text_Kungfu"):SetSize(width, height)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetKungfuTextRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.kungfuText.top * fy
	local left = UIConfig.kungfuText.left * fx
	local handle = self.handle
	handle:Lookup("Text_Kungfu"):SetRelPos(left,top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetKungfuImageSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.kungfuImage.height
	local width = UIConfig.kungfuImage.width
	local handle = self.handle
	handle:Lookup("Image_Kungfu"):SetSize(width, height)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetKungfuImageRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.kungfuImage.top * fy
	local left = UIConfig.kungfuImage.left * fx
	local handle = self.handle
	handle:Lookup("Image_Kungfu"):SetRelPos(left,top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:DrawKungFu()
	local dwID = self.dwID
	local MemberInfo = _Members[dwID]
	local szText = "??"
	local r, g, b = 255, 255, 255
	local IconID = Table_GetSkillIconID(0, 1)
	if MemberInfo and LR.GetMenPaiColor(MemberInfo.dwForceID) then
		szText = _KungfuText[MemberInfo.dwMountKungfuID].text
		r, g, b = LR.GetMenPaiColor(MemberInfo.dwForceID)
		IconID = Table_GetSkillIconID(MemberInfo.dwMountKungfuID, 1)
	end
	local handle = self.handle
	if LR_TeamGrid.UsrData.CommonSettings.kungFuShowType == 1 then
		handle:Lookup("Image_Kungfu"):FromIconID(IconID)
		handle:Lookup("Image_Kungfu"):Show()
		handle:Lookup("Text_Kungfu"):Hide()
	elseif LR_TeamGrid.UsrData.CommonSettings.kungFuShowType == 2 then
		handle:Lookup("Text_Kungfu"):SetText(szText)
		handle:Lookup("Text_Kungfu"):SetFontScheme(LR_TeamGrid.UsrData.CommonSettings.szFontScheme)
		handle:Lookup("Text_Kungfu"):SetFontScale(LR_TeamGrid.UsrData.CommonSettings.kungFuTextScale)
		handle:Lookup("Text_Kungfu"):SetFontColor(r, g, b)
		handle:Lookup("Text_Kungfu"):Show()
		handle:Lookup("Image_Kungfu"):Hide()
	elseif LR_TeamGrid.UsrData.CommonSettings.kungFuShowType == 3 then	--显示阵营图标
		local frame = 0
		if MemberInfo.nCamp == CAMP.GOOD or MemberInfo.nCamp == CAMP.EVIL then
			if MemberInfo.nCamp == CAMP.GOOD then
				handle:Lookup("Image_Kungfu"):FromUITex("ui\\Image\\UICommon\\CommonPanel2.UITex", 7)
			else
				handle:Lookup("Image_Kungfu"):FromUITex("ui\\Image\\UICommon\\CommonPanel2.UITex", 5)
			end
			handle:Lookup("Image_Kungfu"):Show()
		else
			handle:Lookup("Image_Kungfu"):Hide()
		end
		handle:Lookup("Text_Kungfu"):Hide()
	elseif LR_TeamGrid.UsrData.CommonSettings.kungFuShowType == 4 then
		local szText = ""
		local r, g, b = unpack(LR.CampColor[MemberInfo.nCamp])
		if MemberInfo.nCamp == CAMP.GOOD then
			szText = _L["H"]
		elseif MemberInfo.nCamp == CAMP.EVIL then
			szText = _L["E"]
		end
		handle:Lookup("Text_Kungfu"):SetText(szText)
		handle:Lookup("Text_Kungfu"):SetFontScheme(LR_TeamGrid.UsrData.CommonSettings.szFontScheme)
		handle:Lookup("Text_Kungfu"):SetFontScale(LR_TeamGrid.UsrData.CommonSettings.kungFuTextScale)
		handle:Lookup("Text_Kungfu"):SetFontColor(r, g, b)
		handle:Lookup("Text_Kungfu"):Show()
		handle:Lookup("Image_Kungfu"):Hide()
	end
	return self
end

function _RoleGrid:SetGroupEyeSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.groupEyeImage.height
	local width = UIConfig.groupEyeImage.width
	local handle = self.handle
	handle:Lookup("Image_GroupEye"):SetSize(width, height)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetGroupEyeRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.groupEyeImage.top * fy
	local left = UIConfig.groupEyeImage.left * fx
	local handle = self.handle
	handle:Lookup("Image_GroupEye"):SetRelPos(left,top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:DrawGroupEye()
	local dwID = self.dwID
	local handle = self.handle
	if LR_TeamGrid.IsGroupEye(dwID) then
		handle:Lookup("Image_GroupEye"):Show()
	else
		handle:Lookup("Image_GroupEye"):Hide()
	end
	return self
end

function _RoleGrid:SetBossTargetImageSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.bossTargetImage.height
	local width = UIConfig.bossTargetImage.width
	local handle = self.handle
	handle:Lookup("Image_BossTarget"):SetSize(width, height)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetBossTargetImageRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.bossTargetImage.top * fy
	local left = UIConfig.bossTargetImage.left * fx
	local handle = self.handle
	handle:Lookup("Image_BossTarget"):SetRelPos(left,top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:DrawBossTargetImage(bShow)
	local handle = self.handle
	local Image_BossTarget = handle:Lookup("Image_BossTarget")
	if bShow then
		Image_BossTarget:Show()
	else
		Image_BossTarget:Hide()
	end
	return self
end

function _RoleGrid:DrawSmallBossTargetImage(bShow)
	local handle = self.handle
	local Image_MonsterTarget = handle:Lookup("Image_MonsterTarget")
	if bShow then
		Image_MonsterTarget:Show()
	else
		Image_MonsterTarget:Hide()
	end
	return self
end

function _RoleGrid:SetLeaderImageSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.leaderImage.height
	local width = UIConfig.leaderImage.width
	local handle = self.handle
	handle:Lookup("Image_Leader"):SetSize(width, height)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetLeaderImageRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.leaderImage.top * fy
	local left = UIConfig.leaderImage.left * fx
	local handle = self.handle
	handle:Lookup("Image_Leader"):SetRelPos(left,top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:DrawLeaderImage()
	local dwID = self.dwID
	local handle = self.handle
	if LR_TeamGrid.IsLeader(dwID) then
		handle:Lookup("Image_Leader"):Show()
	else
		handle:Lookup("Image_Leader"):Hide()
	end
	return self
end

function _RoleGrid:SetMarkerImageSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.markerImage.height
	local width = UIConfig.markerImage.width
	local handle = self.handle
	handle:Lookup("Image_Mark"):SetSize(width, height)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetMarkerImageRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.markerImage.top * fy
	local left = UIConfig.markerImage.left * fx
	local handle = self.handle
	handle:Lookup("Image_Mark"):SetRelPos(left,top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:DrawMarkerImage()
	local dwID = self.dwID
	local handle = self.handle
	if LR_TeamGrid.IsMarker(dwID) then
		handle:Lookup("Image_Mark"):Show()
	else
		handle:Lookup("Image_Mark"):Hide()
	end
	return self
end

function _RoleGrid:SetLooterImageSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.looterImage.height
	local width = UIConfig.looterImage.width
	local handle = self.handle
	handle:Lookup("Image_Looter"):SetSize(width, height)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetLooterImageRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.looterImage.top * fy
	local left = UIConfig.looterImage.left * fx
	local handle = self.handle
	handle:Lookup("Image_Looter"):SetRelPos(left,top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:DrawLootertImage()
	local dwID = self.dwID
	local handle = self.handle
	if LR_TeamGrid.IsLooter(dwID) then
		handle:Lookup("Image_Looter"):Show()
	else
		handle:Lookup("Image_Looter"):Hide()
	end
	return self
end

function _RoleGrid:SetWorldMarkImageSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.worldMarkImage.height
	local width = UIConfig.worldMarkImage.width
	local handle = self.handle
	handle:Lookup("Image_WorldMark"):SetSize(width, height)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetWorldMarkImageRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.worldMarkImage.top * fy
	local left = UIConfig.worldMarkImage.left * fx
	local handle = self.handle
	handle:Lookup("Image_WorldMark"):SetRelPos(left,top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:DrawWorldMarkImage()
	local dwID = self.dwID
	local handle = self.handle
	local nMarkImageIndex = _tPartyMark[dwID]
	if nMarkImageIndex and tMarkerImageList[nMarkImageIndex] then
		local imageMark = handle:Lookup("Image_WorldMark")
		if imageMark then
			imageMark:SetFrame(tMarkerImageList[nMarkImageIndex])
			imageMark:Show()
			imageMark:SetAlpha(255)
		end
	else
		local imageMark = handle:Lookup("Image_WorldMark")
		if imageMark then
			imageMark:Hide()
		end
	end
	return self
end

function _RoleGrid:SetLifeTextSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.lifeText.height * fy
	local width = UIConfig.lifeText.width * fx
	local handle = self.handle
	handle:Lookup("Text_LifeValue"):SetSize(width, height)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetLifeTextRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.lifeText.top * fy
	local left = UIConfig.lifeText.left * fx
	local handle = self.handle
	handle:Lookup("Text_LifeValue"):SetRelPos(left,top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:DrawLifeText()
	local me = GetClientPlayer()
	if not me then
		return self
	end
	local handle = self.handle
	local dwID = self.dwID
	local MemberInfo = _Members[dwID]
	local nCurrentLife = MemberInfo.nCurrentLife
	local nMaxLife = MemberInfo.nMaxLife
	local player = GetPlayer()
	if player then
		nCurrentLife = player.nCurrentLife
		nMaxLife = player.nMaxLife
	end
	if _JCG[dwID] then
		local npc = GetNpc(_JCG[dwID])
		if npc then
			nCurrentLife = npc.nCurrentLife
			nMaxLife = npc.nMaxLife
		end
	end
	local life = 0
	local textLife = ""
	local r, g, b = 255, 255, 255
	local UIConfig = LR_TeamGrid.UIConfig
	local halign = UIConfig.lifeText.halign
	local valign = UIConfig.lifeText.valign
	if not MemberInfo.bDeathFlag then
		handle.bDeathFlag = false	--用于消除BOSS_FOCUS
	end
	if (MemberInfo.bDeathFlag and nCurrentLife == 0) or not MemberInfo.bIsOnLine or nMaxLife == 0 then
		if not MemberInfo.bIsOnLine then
			nCurrentLife = _L["Offline"]
			r, g, b = 96, 96, 96
		elseif nMaxLife == 0 then
			nCurrentLife = "--"
			r, g, b = 255, 255, 255
		elseif MemberInfo.bDeathFlag then -- or nCurrentLife == 0 then
			nCurrentLife = _L["Dead"]
			r, g, b = 255, 0, 0
			--将队友死后BOSS_FOCUS消除的语句放这
			if not handle.bDeathFlag then
				FireEvent("ON_BOSS_FOCUS", dwID, false)
				handle.bDeathFlag = bDeathFlag
			end
		end

		handle:Lookup("Text_LifeValue"):SetText(nCurrentLife)
		handle:Lookup("Text_LifeValue"):SetFontScheme(15)
		handle:Lookup("Text_LifeValue"):SetFontScale(LR_TeamGrid.UsrData.CommonSettings.bloodTextScale)
		handle:Lookup("Text_LifeValue"):SetFontColor(r, g, b)
		handle:Lookup("Text_LifeValue"):SetHAlign(halign)
		handle:Lookup("Text_LifeValue"):SetVAlign(valign)
		handle:Lookup("Text_LifeValue"):Show()
		return self
	end

	if LR_TeamGrid.UsrData.CommonSettings.lifeTextType == 1 then
		life = nCurrentLife
	elseif LR_TeamGrid.UsrData.CommonSettings.lifeTextType == 2 then
		life = nMaxLife - nCurrentLife
	elseif LR_TeamGrid.UsrData.CommonSettings.lifeTextType == 3 then
		handle:Lookup("Text_LifeValue"):SetText("")
		handle:Lookup("Text_LifeValue"):Hide()
		return self
	end

	if LR.IsNurse() and LR_TeamGrid.UsrData.CommonSettings.autoPercentInCure or LR_TeamGrid.UsrData.CommonSettings.bShowBloodInPercent then
		if mfloor(life * 100 / nMaxLife) == 0 then
			textLife = "0"
		else
			textLife = sformat("%.0f%%", mfloor(life * 100 / nMaxLife))
		end
	elseif LR_TeamGrid.UsrData.CommonSettings.bShortBlood then
		if life >= 10000 then
			if LR_TeamGrid.UsrData.CommonSettings.nDecimalPoint == 0 then
				textLife = sformat("%.0fw", life /10000)
			elseif LR_TeamGrid.UsrData.CommonSettings.nDecimalPoint == 1 then
				textLife = sformat("%.1fw", life /10000)
			elseif LR_TeamGrid.UsrData.CommonSettings.nDecimalPoint == 2 then
				textLife = sformat("%.2fw", life /10000)
			end
		else
			textLife = sformat("%d", life)
		end
	else
		textLife = sformat("%d", life)
	end
	handle:Lookup("Text_LifeValue"):SetText(textLife)
	handle:Lookup("Text_LifeValue"):SetFontScheme(15)
	handle:Lookup("Text_LifeValue"):SetFontScale(LR_TeamGrid.UsrData.CommonSettings.bloodTextScale)
	handle:Lookup("Text_LifeValue"):SetFontColor(r, g, b)
	handle:Lookup("Text_LifeValue"):SetHAlign(halign)
	handle:Lookup("Text_LifeValue"):SetVAlign(valign)
	handle:Lookup("Text_LifeValue"):Show()
	return self
end

function _RoleGrid:SetHandleBuffSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.handleBuff.height * fy
	local width = UIConfig.handleBuff.width * fx
	local handle = self.handle
	handle:Lookup("Handle_Debuffs"):SetSize(width, height)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetHandleBuffRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.handleBuff.top * fy
	local left = UIConfig.handleBuff.left * fx
	local handle = self.handle
	handle:Lookup("Handle_Debuffs"):SetRelPos(left, top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetBuffBoxSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local handle = self.handle
	local handleBuff = handle:Lookup("Handle_Debuffs")
	for i =1, 4, 1 do
		local height = UIConfig.handleBuffBox[i].height * fy
		local width = UIConfig.handleBuffBox[i].width * fx
		handleBuff:Lookup(sformat("Box_%d", i)):SetSize(width, height)
	end
	handleBuff:FormatAllItemPos()
	return self
end

function _RoleGrid:SetBuffBoxRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local handle = self.handle
	local handleBuff = handle:Lookup("Handle_Debuffs")
	for i =1, 4, 1 do
		local top = UIConfig.handleBuffBox[i].top
		local left = UIConfig.handleBuffBox[i].left
		handleBuff:Lookup(sformat("Box_%d", i)):SetRelPos(left, top)
		--handleBuff:Lookup(sformat("Box_%d", i)):SetObject(1)
		--handleBuff:Lookup(sformat("Box_%d", i)):SetObjectIcon(119)
		--handleBuff:Lookup(sformat("Box_%d", i)):Show()
	end
	handleBuff:FormatAllItemPos()
	return self
end

function _RoleGrid:SetConfirmImageSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.confirmImage.height * fy
	local width = UIConfig.confirmImage.width * fx
	local handle = self.handle
	handle:Lookup("Image_Vote_Wait"):SetSize(width, height)
	handle:Lookup("Image_Vote_Yes"):SetSize(width, height)
	handle:Lookup("Image_Vote_No"):SetSize(width, height)
	handle:Lookup("Image_ReadyCheck_No"):SetSize(width, height)
	handle:Lookup("Image_Vote_Wait"):SetImageType(0)
	handle:Lookup("Image_Vote_Yes"):SetImageType(0)
	handle:Lookup("Image_Vote_No"):SetImageType(0)
	handle:Lookup("Image_ReadyCheck_No"):SetImageType(0)
	return self
end

function _RoleGrid:SetConfirmImageRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.confirmImage.top * fy
	local left = UIConfig.confirmImage.left * fx
	local handle = self.handle
	handle:Lookup("Image_Vote_Wait"):SetRelPos(left, top)
	handle:Lookup("Image_Vote_Yes"):SetRelPos(left, top)
	handle:Lookup("Image_Vote_No"):SetRelPos(left, top)
	handle:Lookup("Image_ReadyCheck_No"):SetRelPos(left, top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:ShowReadyConfirmImage()
	local handle = self.handle
	local dwID = self.dwID
	if LR_TeamGrid.IsLeader(dwID) then
		return
	end
	local Image_ReadyCheck = handle:Lookup("Image_ReadyCheck")
	if Image_ReadyCheck then
		Image_ReadyCheck:SetAlpha(160)
		Image_ReadyCheck:Show()
	end
	return self
end

function _RoleGrid:ResponseReadyConfirm(nReadyState)
	local handle = self.handle
	local dwID = self.dwID
	if not LR_TeamGrid.IsLeader(GetClientPlayer().dwID) then
		return
	end
	local Image_ReadyCheck = handle:Lookup("Image_ReadyCheck")
	local Image_ReadyCheck_No = handle:Lookup("Image_ReadyCheck_No")
	local Image_Vote_Wait = handle:Lookup("Image_Vote_Wait")
	if Image_ReadyCheck and Image_ReadyCheck_No then
		if nReadyState == 1 then
			Image_Vote_Wait:Hide()
			Image_ReadyCheck:Hide()
			Image_ReadyCheck_No:Hide()
		elseif nReadyState == 2 then
			Image_Vote_Wait:Hide()
			Image_ReadyCheck:Show()
			Image_ReadyCheck_No:Show()
		end
	end
	return self
end

function _RoleGrid:ClearReadyConfirm()
	local handle = self.handle
	local Image_ReadyCheck = handle:Lookup("Image_ReadyCheck")
	local Image_ReadyCheck_No = handle:Lookup("Image_ReadyCheck_No")
	local Image_Vote_Wait = handle:Lookup("Image_Vote_Wait")
	if Image_ReadyCheck and Image_ReadyCheck_No then
		Image_ReadyCheck:Hide()
		Image_ReadyCheck_No:Hide()
		Image_Vote_Wait:Hide()
	end
	return self
end

function _RoleGrid:ShowVoteImage()
	local handle = self.handle
	local dwID = self.dwID
	local Image_ReadyCheck = handle:Lookup("Image_ReadyCheck")
	local Image_Vote_Yes = handle:Lookup("Image_Vote_Yes")
	local Image_Vote_No = handle:Lookup("Image_Vote_No")
	local Image_Vote_Wait = handle:Lookup("Image_Vote_Wait")
	Image_ReadyCheck:SetAlpha(225)
	Image_ReadyCheck:Show()
	Image_Vote_Yes:Hide()
	Image_Vote_No:Hide()
	if _Members[dwID] and _Members[dwID].bIsOnLine and _Members[GetClientPlayer().dwID]
	and _Members[GetClientPlayer().dwID].nMapCopyIndex == _Members[dwID].nMapCopyIndex
	and _Members[GetClientPlayer().dwID].dwMapID == _Members[dwID].dwMapID then
		Image_Vote_Wait:Show()
	else
		Image_Vote_Wait:Hide()
		Image_ReadyCheck:SetAlpha(80)
	end
	return self
end

function _RoleGrid:ResponseVote(nRespondState)
	local handle = self.handle
	local Image_ReadyCheck = handle:Lookup("Image_ReadyCheck")
	local Image_Vote_Yes = handle:Lookup("Image_Vote_Yes")
	local Image_Vote_No = handle:Lookup("Image_Vote_No")
	local Image_Vote_Wait = handle:Lookup("Image_Vote_Wait")
	if nRespondState == VOTE_RESPONSE.AGREE then
		Image_ReadyCheck:Show()
		Image_Vote_Yes:Show()
		Image_Vote_No:Hide()
		Image_Vote_Wait:Hide()
	elseif nRespondState == VOTE_RESPONSE.DISAGREE then
		Image_ReadyCheck:Show()
		Image_Vote_Yes:Hide()
		Image_Vote_No:Show()
		Image_Vote_Wait:Hide()
	end
	return self
end

function _RoleGrid:ClearVoteImage()
	local handle = self.handle
	local Image_ReadyCheck = handle:Lookup("Image_ReadyCheck")
	local Image_Vote_Yes = handle:Lookup("Image_Vote_Yes")
	local Image_Vote_No = handle:Lookup("Image_Vote_No")
	local Image_Vote_Wait = handle:Lookup("Image_Vote_Wait")
	Image_ReadyCheck:Hide()
	Image_Vote_Yes:Hide()
	Image_Vote_No:Hide()
	Image_Vote_Wait:Hide()
	return self
end

function _RoleGrid:GetBuffHandle()
	--local handle = self.handle
	return self.UI["Handle_Debuffs"]
end

function _RoleGrid:GetSpecialBuffHandle()
	--local handle = self.handle
	return self.UI["Handle_SpecialBuff"]
end

function _RoleGrid:GetEdgeIndicatorShadow(...)
	return self.UI[...]
end

function _RoleGrid:SetDistanceTextSize()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig.distanceText.height * fy
	local width = UIConfig.distanceText.width * fx
	local handle = self.handle
	handle:Lookup("Text_Distance"):SetSize(width, height)
	return self
end

function _RoleGrid:SetDistanceTextRelPos()
	local UIConfig = LR_TeamGrid.UIConfig
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig.distanceText.top * fy
	local left = UIConfig.distanceText.left * fx
	local handle = self.handle
	handle:Lookup("Text_Distance"):SetRelPos(left, top)
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:DrawDistanceText()
	local me = GetClientPlayer()
	if not me then
		return self
	end
	local dwID = self.dwID
	local MemberInfo = _Members[dwID]
	local handle = self.handle
	local szText = ""
	if LR_TeamGrid.UsrData.CommonSettings.bShowDistanceText and dwID ~= me.dwID then
		if MemberInfo.bIsOnLine then
			local player = GetPlayer(dwID)
			if player then
				local distance = LR.GetDistance(player)
				if distance < 55 then
					szText = sformat("%.2f", distance)
				else
					szText = "--"
				end
			end
		end
		handle:Lookup("Text_Distance"):SetText(szText)
		handle:Lookup("Text_Distance"):SetHAlign(2)
		handle:Lookup("Text_Distance"):Show()
	else
		handle:Lookup("Text_Distance"):Hide()
	end
	return self
end

function _RoleGrid:SetEdgeIndicatoSize()
	local UIConfig = LR_TeamGrid.UIConfig.edgeIndicato
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local szKey = {"TopLeft", "TopRight", "BottomLeft", "BottomRight"}
	for k, v in pairs(szKey) do
		local height = UIConfig[v].height * fy
		local width = UIConfig[v].width * fx
		local handle = self.handle
		handle:Lookup(sformat("Shadow_Edge%s", v)):SetSize(width, height)
		handle:Lookup(sformat("Shadow_Edge%sBg", v)):SetSize(width + 4, height + 4)
	end
	return self
end

function _RoleGrid:SetEdgeIndicatoRelPos()
	local UIConfig = LR_TeamGrid.UIConfig.edgeIndicato
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local szKey = {"TopLeft", "TopRight", "BottomLeft", "BottomRight"}
	local handle = self.handle
	for k, v in pairs(szKey) do
		local top = UIConfig[v].top * fy
		local left = UIConfig[v].left * fx
		handle:Lookup(sformat("Shadow_Edge%s", v)):SetRelPos(left, top)
		handle:Lookup(sformat("Shadow_Edge%sBg", v)):SetRelPos(left - 2, top - 2)
		self:SetEdgeIndicatoColor(v, nil, nil)
	end
	handle:FormatAllItemPos()
	return self
end

function _RoleGrid:SetEdgeIndicatoColor(szKey, color, bShow)
	local handle = self.handle
	local shadow = handle:Lookup(sformat("Shadow_Edge%s", szKey))
	shadow:SetColorRGB(34, 177, 76)
	shadow:Hide()
	local shadowBg = handle:Lookup(sformat("Shadow_Edge%sBg", szKey))
	shadowBg:SetColorRGB(0, 0, 0)
	shadowBg:Hide()
	return self
end

function _RoleGrid:SetMicOpenSize()
	local UIConfig = LR_TeamGrid.UIConfig.micStatus
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig["MicOpen"].height * fy
	local width = UIConfig["MicOpen"].width * fx
	local handle = self.handle
	handle:Lookup("Animate_MicOpen"):SetSize(width, height)
	return self
end

function _RoleGrid:SetMicOpenRelPos()
	local UIConfig = LR_TeamGrid.UIConfig.micStatus
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig["MicOpen"].top * fy
	local left = UIConfig["MicOpen"].left * fx
	local handle = self.handle
	handle:Lookup("Animate_MicOpen"):SetRelPos(left, top)
	handle:FormatAllItemPos()
	return self
end

function  _RoleGrid:DrawMicOpen(bShow)
	local handle = self.handle
	local Animate_Mic = handle:Lookup("Animate_MicOpen")
	if bShow then
		Animate_Mic:Show()
	else
		Animate_Mic:Hide()
	end
	return self
end

function _RoleGrid:SetMicDisableSize()
	local UIConfig = LR_TeamGrid.UIConfig.micStatus
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local height = UIConfig["MicDisable"].height * fy
	local width = UIConfig["MicDisable"].width * fx
	local handle = self.handle
	handle:Lookup("Image_MicDisable"):SetSize(width, height)
	return self
end

function _RoleGrid:SetMicDisableRelPos()
	local UIConfig = LR_TeamGrid.UIConfig.micStatus
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local top = UIConfig["MicDisable"].top * fy
	local left = UIConfig["MicDisable"].left * fx
	local handle = self.handle
	handle:Lookup("Image_MicDisable"):SetRelPos(left, top)
	handle:FormatAllItemPos()
	return self
end

function  _RoleGrid:DrawMicDisable(bShow)
	local handle = self.handle
	local Image_MicDisable = handle:Lookup("Image_MicDisable")
	if bShow then
		Image_MicDisable:Show()
		self:DrawMicOpen(false)
	else
		Image_MicDisable:Hide()
	end
	return self
end

function _RoleGrid:SetSpecialBuffSize()
	local UIConfig = LR_TeamGrid.UIConfig.specialBuff
	local handle = self.handle
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local heightHandle = UIConfig["Handle"].height * fy
	local widthHandle = UIConfig["Handle"].width * fx
	handle:Lookup("Handle_SpecialBuff"):SetSize(widthHandle, heightHandle)
	local heightSpecialBuffBg = UIConfig["Bg"].height * fy
	local widthSpecialBuffBg = UIConfig["Bg"].width * fx
	handle:Lookup("Handle_SpecialBuff"):Lookup("Shadow_SpecialBuffBg"):SetSize(widthSpecialBuffBg, heightSpecialBuffBg)
	handle:Lookup("Handle_SpecialBuff"):Lookup("Image_SpecialMe"):SetSize(widthSpecialBuffBg, heightSpecialBuffBg)

	return self
end

function _RoleGrid:SetSpecialBuffRelPos()
	local UIConfig = LR_TeamGrid.UIConfig.specialBuff
	local fx, fy = LR_TeamGrid.UsrData.CommonSettings.scale.fx, LR_TeamGrid.UsrData.CommonSettings.scale.fy
	local handle = self.handle
	local topHandle = UIConfig["Handle"].top * fy
	local leftHandle = UIConfig["Handle"].left * fx
	handle:Lookup("Handle_SpecialBuff"):SetRelPos(leftHandle, topHandle)
	local topSpecialBuffBg = UIConfig["Bg"].top * fy
	local leftSpecialBuffBg = UIConfig["Bg"].left * fx
	handle:Lookup("Handle_SpecialBuff"):Lookup("Shadow_SpecialBuffBg"):SetRelPos(leftSpecialBuffBg, topSpecialBuffBg)
	handle:Lookup("Handle_SpecialBuff"):Lookup("Shadow_SpecialBuffBg"):Hide()
	handle:Lookup("Handle_SpecialBuff"):Lookup("Image_SpecialMe"):SetRelPos(leftSpecialBuffBg, topSpecialBuffBg)
	handle:Lookup("Handle_SpecialBuff"):Lookup("Image_SpecialMe"):Hide()
	handle:FormatAllItemPos()
	handle:Lookup("Handle_SpecialBuff"):FormatAllItemPos()
	return self
end

function _RoleGrid:BossFocus(bShow)
	local handle = self.handle
	local Handle_BossFocus = handle:Lookup("Handle_BossFocus")
	if Handle_BossFocus then
		Handle_BossFocus:SetAlpha(LR_TeamGrid.UsrData.CommonSettings.nBossFocusAlpha or 120)
		if bShow then
			Handle_BossFocus:Show()
		else
			Handle_BossFocus:Hide()
		end
	end
	return self
end

---------------------------------------------------------------
function LR_TeamGrid.OnFrameCreate()
	local frame = Station.Lookup("Normal/LR_TeamGrid")
	LR_TeamGrid.frameSelf = frame
	LR_TeamGrid.Handle_Title = frame:Lookup("Wnd_Title"):Lookup("","")
	LR_TeamGrid.Handle_Skill_Box = frame:Lookup("Wnd_Skill_Box"):Lookup("","")
	LR_TeamGrid.Handle_BossOTBar = frame:Lookup("Wnd_Boss_OTBar"):Lookup("","")
	LR_TeamGrid.Handle_Body = frame:Lookup("Wnd_Body"):Lookup("","")
	LR_TeamGrid.Handle_Roles = LR_TeamGrid.Handle_Body:Lookup("Handle_Roles")
	LR_TeamGrid.Handle_TeamNum = LR_TeamGrid.Handle_Body:Lookup("Handle_TeamNum")
	LR_TeamGrid.Handle_BodySub = frame:Lookup("Wnd_BodySub"):Lookup("","")
	LR_TeamGrid.Handle_RolesSub = LR_TeamGrid.Handle_BodySub:Lookup("Handle_RolesSub")
	LR_TeamGrid.Handle_TeamNumSub = LR_TeamGrid.Handle_BodySub:Lookup("Handle_TeamNumSub")
	LR_TeamGrid.bMiniPanel = false

	LR_TeamGrid.ListButtons()
	LR.DelayCall(2000, function()
		LR_TeamGrid.GVOICE_MIC_STATE_CHANGED()
		LR_TeamGrid.GVOICE_SPEAKER_STATE_CHANGED()
	end)

	if LR_TeamGrid.UsrData.CommonSettings.bLockLocation then
		frame:EnableDrag(false)
	else
		frame:EnableDrag(true)
	end

	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("PARTY_ADD_MEMBER")
	this:RegisterEvent("PARTY_DELETE_MEMBER")
	this:RegisterEvent("TEAM_CHANGE_MEMBER_GROUP")
	this:RegisterEvent("PARTY_UPDATE_MEMBER_LMR")		--血量刷新
	this:RegisterEvent("PARTY_UPDATE_MEMBER_INFO")		--切换心法、重伤、复活
	this:RegisterEvent("TEAM_AUTHORITY_CHANGED")		--团长改变、分配者改变、标记着改变
	this:RegisterEvent("PARTY_SET_FORMATION_LEADER")		--阵眼改变
	this:RegisterEvent("PARTY_LOOT_MODE_CHANGED")		--分配模式改变
	this:RegisterEvent("PARTY_ROLL_QUALITY_CHANGED")		--Roll等级改变
	this:RegisterEvent("PARTY_SET_MEMBER_ONLINE_FLAG")		--Roll等级改变
	this:RegisterEvent("PARTY_DISBAND")	--队伍解散
	--this:RegisterEvent("PARTY_LEVEL_UP_RAID")	--升级为团队模式
	this:RegisterEvent("PARTY_SET_MARK")
	this:RegisterEvent("RIAD_READY_CONFIRM_RECEIVE_ANSWER")	--团队就位确认响应
	this:RegisterEvent("TEAM_VOTE_REQUEST")	--踢人、是否同意发工资请求
	this:RegisterEvent("TEAM_VOTE_RESPOND")	--踢人、是否同意发工资响应
	-----
	this:RegisterEvent("BUFF_UPDATE")	--BUFF
	this:RegisterEvent("JH_RAID_REC_BUFF")		--dbm
	this:RegisterEvent("SYS_MSG")	--途径2监控BUFF
	this:RegisterEvent("LR_RAID_BUFF_ADD_FRESH")
	this:RegisterEvent("LR_RAID_BUFF_DELETE")
	this:RegisterEvent("LR_RAID_EDGE_ADD_FRESH")
	this:RegisterEvent("LR_RAID_EDGE_DELETE")
	this:RegisterEvent("LR_SPECIAL_BUFF_ADD_FRESH")
	this:RegisterEvent("LR_SPECIAL_BUFF_DELETE")

	---GVoice相关
	this:RegisterEvent("GVOICE_ON_JOIN_ROOM")
	this:RegisterEvent("GVOICE_MIC_STATE_CHANGED")
	this:RegisterEvent("GVOICE_BASE_ON_FORBID_MEMBER")
	this:RegisterEvent("GVOICE_SPEAKER_STATE_CHANGED")

	----自身技能监控
	this:RegisterEvent("SKILL_MOUNT_KUNG_FU")
	this:RegisterEvent("SKILL_UPDATE")
	this:RegisterEvent("DO_SKILL_CAST")

	this:RegisterEvent("FIGHT_HINT")
	this:RegisterEvent("MONEY_UPDATE")

	--46140这两个事件用于长歌切剑
	this:RegisterEvent("NPC_ENTER_SCENE")
	this:RegisterEvent("NPC_LEAVE_SCENE")

	--BOSS点名
	this:RegisterEvent("ON_BOSS_FOCUS")

	this:RegisterEvent("LOADING_END")	--载入完成
	this:RegisterEvent(12787)

	LR_TeamGrid.UpdateAnchor(frame)
	LR_TeamGrid.SetTitleText("")
	local team = GetClientTeam()
	if team then
		LR_TeamGrid.Handle_Roles:RegisterEvent(786)
		LR_TeamGrid.Handle_Roles.OnItemMouseLeave = function()
			if bDraged then
				LR_TeamGrid.nDragChooseGridEnd = nil
			end
		end

		LR_TeamGrid.DrawImageLoot(team.nLootMode)
		LR_TeamGrid.DrawImageLootLevel(team.nRollQuality)

		LR_TeamSkillMonitor.ShowSkillPanel()
	end
end

function LR_TeamGrid.OnEvent(szEvent)
	if szEvent == "UI_SCALED" then
		LR_TeamGrid.ReDrawAllMembers(true)
		--LR_TeamGrid.UpdateRoleBodySize()
		LR_TeamGrid.UpdateAnchor(this)
	elseif szEvent == "PARTY_ADD_MEMBER" then
		LR_TeamGrid.PARTY_ADD_MEMBER()
	elseif szEvent == "PARTY_DELETE_MEMBER" then
		LR_TeamGrid.PARTY_DELETE_MEMBER()
	elseif szEvent == "TEAM_CHANGE_MEMBER_GROUP" then
		LR_TeamGrid.TEAM_CHANGE_MEMBER_GROUP()
	elseif szEvent == "PARTY_UPDATE_MEMBER_LMR" then
		LR_TeamGrid.PARTY_UPDATE_MEMBER_LMR()
	elseif szEvent == "PARTY_UPDATE_MEMBER_INFO" then
		LR_TeamGrid.PARTY_UPDATE_MEMBER_INFO()
	elseif szEvent == "TEAM_AUTHORITY_CHANGED" then
		LR_TeamGrid.TEAM_AUTHORITY_CHANGED()
	elseif szEvent == "PARTY_SET_FORMATION_LEADER" then
		LR_TeamGrid.PARTY_SET_FORMATION_LEADER()
	elseif szEvent == "PARTY_LOOT_MODE_CHANGED" then
		LR_TeamGrid.PARTY_LOOT_MODE_CHANGED()
	elseif szEvent == "PARTY_ROLL_QUALITY_CHANGED" then
		LR_TeamGrid.PARTY_ROLL_QUALITY_CHANGED()
	elseif szEvent == "PARTY_SET_MEMBER_ONLINE_FLAG" then
		LR_TeamGrid.PARTY_SET_MEMBER_ONLINE_FLAG()
	elseif szEvent == "PARTY_DISBAND" then
		LR_TeamGrid.PARTY_DISBAND()
	--elseif szEvent == "PARTY_LEVEL_UP_RAID" then
		--LR_TeamGrid.PARTY_LEVEL_UP_RAID()
	elseif szEvent == "PARTY_SET_MARK" then
		LR_TeamGrid.PARTY_SET_MARK()
	elseif szEvent == "RIAD_READY_CONFIRM_RECEIVE_ANSWER" then
		LR_TeamGrid.RIAD_READY_CONFIRM_RECEIVE_ANSWER()
	elseif szEvent == "TEAM_VOTE_REQUEST" then
		LR_TeamGrid.TEAM_VOTE_REQUEST()
	elseif szEvent == "TEAM_VOTE_RESPOND" then
		LR_TeamGrid.TEAM_VOTE_RESPOND()
	elseif szEvent == "BUFF_UPDATE" then
		LR_TeamBuffMonitor.BUFF_UPDATE2()
	elseif szEvent == "LR_RAID_BUFF_ADD_FRESH" then
		LR_TeamBuffMonitor.LR_RAID_BUFF_ADD_FRESH()
	elseif szEvent == "LR_RAID_BUFF_DELETE" then
		LR_TeamBuffMonitor.LR_RAID_BUFF_DELETE()
	elseif szEvent == "LR_RAID_EDGE_ADD_FRESH" then
		LR_TeamBuffMonitor.LR_RAID_EDGE_ADD_FRESH()
	elseif szEvent == "LR_RAID_EDGE_DELETE" then
		LR_TeamBuffMonitor.LR_RAID_EDGE_DELETE()
	elseif szEvent == "LR_SPECIAL_BUFF_ADD_FRESH" then
		LR_TeamBuffMonitor.LR_SPECIAL_BUFF_ADD_FRESH()
	elseif szEvent == "LR_SPECIAL_BUFF_DELETE" then
		LR_TeamBuffMonitor.LR_SPECIAL_BUFF_DELETE()
	elseif szEvent == "SYS_MSG" then
		LR_TeamGrid.SYS_MSG()
	elseif szEvent == "SKILL_MOUNT_KUNG_FU" then
		LR_TeamSkillMonitor.SKILL_MOUNT_KUNG_FU()
	elseif szEvent == "SKILL_UPDATE" then
		LR_TeamSkillMonitor.SKILL_UPDATE()
	elseif szEvent == "DO_SKILL_CAST" then
		LR_TeamSkillMonitor.DO_SKILL_CAST()
	elseif szEvent == "FIGHT_HINT" then
		LR_TeamTools.DistributeAttention.FIGHT_HINT()
		LR_TeamGrid.FIGHT_HINT()
	elseif szEvent == "MONEY_UPDATE" then
		LR_TeamGrid.MONEY_UPDATE()
	elseif szEvent == "LOADING_END" then
		LR_TeamGrid.LOADING_END()
	elseif szEvent == "GVOICE_ON_JOIN_ROOM" then
		LR_TeamGrid.GVOICE_ON_JOIN_ROOM()
	elseif szEvent == "GVOICE_MIC_STATE_CHANGED" then
		LR_TeamGrid.GVOICE_MIC_STATE_CHANGED()
	elseif szEvent == "GVOICE_BASE_ON_FORBID_MEMBER" then
		LR_TeamGrid.GVOICE_BASE_ON_FORBID_MEMBER()
	elseif szEvent == "GVOICE_SPEAKER_STATE_CHANGED" then
		LR_TeamGrid.GVOICE_SPEAKER_STATE_CHANGED()
	elseif szEvent == "NPC_ENTER_SCENE" then
		LR_TeamGrid.NPC_ENTER_SCENE()
	elseif szEvent == "NPC_LEAVE_SCENE" then
		LR_TeamGrid.NPC_LEAVE_SCENE()
	elseif szEvent == "PLAYER_ENTER_SCENE" then
		LR_TeamGrid.PLAYER_ENTER_SCENE()
	elseif szEvent == "ON_BOSS_FOCUS" then
		LR_TeamGrid.ON_BOSS_FOCUS()
	end
end

function LR_TeamGrid.OnFrameDestroy()
	_tRoleGrids ={}
	_JCG = {}
	LR_TeamBuffMonitor.ClearAllNormalBuffCache()
	LR_TeamBuffMonitor.ClearAllCache()
end

function LR_TeamGrid.OnFrameBreathe()
	if LR_TeamGrid.UsrData.CommonSettings.backGroundColorType == 4 or LR_TeamGrid.UsrData.CommonSettings.backGroundAlphaType == 2 or LR_TeamGrid.UsrData.CommonSettings.bShowDistanceText then
		if GetLogicFrameCount() % 2 == 0 then
			for dwID , v in pairs(_tRoleGrids) do
				if LR_TeamGrid.UsrData.CommonSettings.backGroundColorType == 4 or LR_TeamGrid.UsrData.CommonSettings.backGroundAlphaType == 2 then
					v:DrawLifeBar()
				end
				if LR_TeamGrid.UsrData.CommonSettings.bShowDistanceText then
					v:DrawDistanceText()
				end
			end
		end
	end

	if GetLogicFrameCount() % 2 == 0 then
		for dwID , v in pairs(_tRoleGrids) do
			v:DrawLifeText()
		end
	end

	--刷新切剑长歌
	for dwID, v in pairs(_JCG) do
		local v = _tRoleGrids[dwID]
		if v then
			v:DrawLifeBar():DrawLifeText()
		end
	end

	--Boss点名
	for dwID, v in pairs(_tRoleGrids) do
		if v then
			if _tBossFocusList[dwID] then
				v:BossFocus(_tBossFocusList[dwID])
			else
				v:BossFocus(false)
			end
		end
	end

--[[	for dwID, bShow in pairs(_tBossFocusList) do
		local v =  _tRoleGrids[dwID]
		if v then
			v:BossFocus(bShow)
		end
	end]]

	if GetLogicFrameCount() % 2 == 0 then
		LR_TeamGrid.CheckPanelActive()
	end

	if not LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bOff then
		LR_TeamBuffMonitor.RefreshBuff()
	end
	LR_TeamBuffMonitor.RefreshSpecialBuff()
	--边角指示器
	LR_TeamEdgeIndicator.RefreshEdgeIndicator()
	--检查语音
	LR_TeamGrid.CheckAllMemberMicStatus()

	LR_TeamSkillMonitor.RefreshAllSkillBox()
	LR_TeamBossMonitor.CheckAllOTState()
	LR_TeamBossMonitor.DrawAllBossTarget()

	GVoiceBase_CheckMicState()
end

function LR_TeamGrid.OnFrameDragEnd()
	this:CorrectPos()
	local Anchor = LR_TeamGrid.Anchor
	Anchor.x, Anchor.y = this:GetRelPos()
end

function LR_TeamGrid.OnRButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Option" then
		local Wnd_Fold = LR_TeamGrid.frameSelf:Lookup("Wnd_Title"):Lookup("WndContainer_Title"):Lookup("Wnd_Fold")
		if Wnd_Fold then
			Wnd_Fold:Lookup("CheckBox_Fold"):Check(not LR_TeamGrid.bMiniPanel)
		else
			LR_TeamGrid.bMiniPanel = not LR_TeamGrid.bMiniPanel
			LR_TeamGrid.ReDrawAllMembers(true)
			LR_TeamSkillMonitor.ShowSkillPanel()
			LR_TeamGrid.UpdateRoleBodySize()
			LR_TeamGrid.ResizeTitle()
		end
	end
end

function LR_TeamGrid.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Option" then
		LR_TeamMenu.PopOptions()
	elseif szName == "Btn_LootMode" then
		local menu= {}
		InsertDistributeMenu(menu,not LR_TeamGrid.IsLooter(GetClientPlayer().dwID))
		if not LR_TeamGrid.IsLooter( GetClientPlayer().dwID) then
			tinsert(menu[1],{szOption=_L["You have not the distribute right,you can not change the distribute mode."],fnDisable = function() return true end})
		end
		PopupMenu(menu[1])
	elseif szName == "Btn_LootLevel" then
		local menu= {}
		InsertDistributeMenu(menu,not LR_TeamGrid.IsLooter( GetClientPlayer().dwID))
		if not LR_TeamGrid.IsLooter( GetClientPlayer().dwID) then
			tinsert(menu[2],{szOption=_L["You have not the distribute right,you can not change the distribute level."],fnDisable = function() return true end})
		end
		PopupMenu(menu[2])
	elseif szName == "Btn_WorldMark" then
		if LR_TeamGrid.IsLeader( GetClientPlayer().dwID) then
			Wnd.ToggleWindow("WorldMark")
		else
			LR.SysMsg(sformat("%s\n", _L["You are not the leader"]))
		end
	elseif szName == "Btn_Mic" then
		LR_TeamGrid.ChangeMicStatus()
		LR_TeamGrid.OnMouseEnter()
	elseif szName == "Btn_SpeakerAll" then
		LR_TeamGrid.ChangeSpeakerStatus()
		LR_TeamGrid.OnMouseEnter()
	elseif szName == "Btn_LR_GKP" then
		if LR_GKP_Base then
			LR_GKP_Panel:Open()
		end
	elseif szName == "Btn_TeamNotice" then
		if Table_IsZombieBattleFieldMap and Table_IsZombieBattleFieldMap(GetClientPlayer().GetMapID()) then
			LR.SysMsg(_L["This map can not use team notice\n"])
		else
			LR.OpenTeamNoticePanel()
		end
	end
end

function LR_TeamGrid.OnCheckBoxCheck()
	local szName = this:GetName()
	if szName == "CheckBox_Fold" then
		LR_TeamGrid.bMiniPanel = true
		LR_TeamGrid.ReDrawAllMembers(true)
		LR_TeamSkillMonitor.ShowSkillPanel()
		LR_TeamGrid.UpdateRoleBodySize()
		LR_TeamGrid.ResizeTitle()
	end
end

function LR_TeamGrid.OnCheckBoxUncheck()
	local szName = this:GetName()
	if szName == "CheckBox_Fold" then
		LR_TeamGrid.bMiniPanel = false
		LR_TeamGrid.ReDrawAllMembers(true)
		LR_TeamSkillMonitor.ShowSkillPanel()
		LR_TeamGrid.UpdateRoleBodySize()
		LR_TeamGrid.ResizeTitle()
	end
end

function LR_TeamGrid.OnMouseEnter()
	local szName = this:GetName()
	--Output("Enter", szName)
	if szName == "Btn_Option" then
		local nMouseX, nMouseY =  this:GetAbsPos()
		local szTipInfo={}
		szTipInfo[#szTipInfo+1] = GetFormatText(_L["Rclick to fold or expand panel"], 41,255,255,255)
		OutputTip(tconcat(szTipInfo), 330, {nMouseX, nMouseY, 0, 0})
	elseif szName == "Btn_LootMode" then
		this:SetAlpha(255)
		local nMouseX, nMouseY =  this:GetAbsPos()
		local szTipInfo={}
		local team=GetClientTeam()
		szTipInfo[#szTipInfo+1] = GetFormatText(_L["Distribute Mode Now:"],41)
		if team.nLootMode == 1 then
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Free Pick"]), 41,255,255,255)
		elseif team.nLootMode == 2 then
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Distributor"]), 41,0,255,0)
		elseif team.nLootMode == 3 then
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Team Pick"]), 41,0,128,255)
		elseif team.nLootMode == 4 then
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Gold Team"]), 41,255,128,0)
		end
		szTipInfo[#szTipInfo+1] = GetFormatText(_L["Click to change distribute mode"],30)
		OutputTip(tconcat(szTipInfo), 330, {nMouseX, nMouseY, 0, 0})
	elseif szName == "Btn_LootLevel" then
		this:SetAlpha(255)
		local nMouseX, nMouseY =  this:GetAbsPos()
		local szTipInfo={}
		local team=GetClientTeam()
		szTipInfo[#szTipInfo+1] = GetFormatText(_L["Distribute Level Now:"],41)
		if team.nRollQuality == 2 then
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Green"]), 41,0,255,0)
		elseif team.nRollQuality == 3 then
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Blue"]), 41,0,255,255)
		elseif team.nRollQuality == 4 then
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Purple"]),41,255,89,255)
		elseif team.nRollQuality == 5 then
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Orange"]),41,255,128,0)
		end
		szTipInfo[#szTipInfo+1] = GetFormatText(_L["Click to change distribute level"],30)
		OutputTip(tconcat(szTipInfo), 330, {nMouseX, nMouseY, 0, 0})
	elseif szName == "Btn_Mic" then
		local tText = {
			[MIC_STATE.NOT_AVIAL] = g_tStrings.GVOICE_MIC_UNAVIAL_STATE_TIP,
			[MIC_STATE.CLOSE_NOT_IN_ROOM] = g_tStrings.GVOICE_MIC_JOIN_STATE_TIP,
			[MIC_STATE.CLOSE_IN_ROOM] = g_tStrings.GVOICE_MIC_KEY_STATE_TIP,
			[MIC_STATE.KEY] = sformat(g_tStrings.GVOICE_MIC_FREE_STATE_TIP, GetKeyShow(Hotkey.Get("TOGGLE_GVOCIE_SAY"))),
			[MIC_STATE.FREE] = g_tStrings.GVOICE_MIC_CLOSE_STATE_TIP,
		}
		local fx, fy = this:GetAbsPos()
		local nW, nH = this:GetSize()
		OutputTip(GetFormatText(tText[GVoiceBase_GetMicState()], 0), 300, {fx, fy, nW, nH})
	elseif szName == "Btn_SpeakerAll" then
		local tText = {
			[SPEAKER_STATE.OPEN] = g_tStrings.GVOICE_SPEAKER_OPEN_TIP,
			[SPEAKER_STATE.CLOSE] = g_tStrings.GVOICE_SPEAKER_CLOSE_TIP,
		}
		local fx, fy = this:GetAbsPos()
		local nW, nH = this:GetSize()
		OutputTip(GetFormatText(tText[GVoiceBase_GetSpeakerState()], 0), 300, {fx, fy, nW, nH})
	elseif szName == "Wnd_Body" or szName == "Wnd_BodySub" then
		LR_TeamGrid.bInFrame = true
		if LR_TeamGrid.UsrData.CommonSettings.bInCureMode then
			local dwKungfuID = UI_GetPlayerMountKungfuID()
			if dwKungfuID == 10028 or dwKungfuID == 10080 or dwKungfuID == 10176 or dwKungfuID == 10448 then
				LR_TeamGrid.timeCache = GetLogicFrameCount()
			end
		end
	elseif szName == "Btn_LR_GKP" then
		local fx, fy = this:GetAbsPos()
		local nW, nH = this:GetSize()
		OutputTip(GetFormatText(_L["Open LR GKP"], 0), 300, {fx, fy, nW, nH})
	elseif szName == "Btn_TeamNotice" then
		local fx, fy = this:GetAbsPos()
		local nW, nH = this:GetSize()
		OutputTip(GetFormatText(_L["Open LR TeamNotice"], 0), 300, {fx, fy, nW, nH})
	end
	LR_TeamGrid.ResizeTitle()
end

function LR_TeamGrid.OnMouseLeave()
	local szName = this:GetName()
	--Output("Leave", szName)
	if szName == "Btn_Option" then
		HideTip()
	elseif szName == "Btn_LootMode" then
		this:SetAlpha(200)
		HideTip()
	elseif szName == "Btn_LootLevel" then
		this:SetAlpha(200)
		HideTip()
	elseif szName == "Btn_Mic" then
		HideTip()
	elseif szName == "Btn_SpeakerAll" then
		HideTip()
	elseif szName == "Wnd_Body" or szName == "Wnd_BodySub" then
		LR_TeamGrid.cureLock = false
		LR_TeamGrid.hoverHandle = nil
		LR_TeamGrid.bInFrame = false
		LR_TeamGrid.outTime = GetLogicFrameCount()
		if not LR_TeamGrid.cureLock and LR_TeamGrid.UsrData.CommonSettings.bInCureMode then
			local dwKungfuID = UI_GetPlayerMountKungfuID()
			if dwKungfuID == 10028 or dwKungfuID == 10080 or dwKungfuID == 10176 or dwKungfuID == 10448 then
				if LR_TeamGrid.IfTargetCanBSelect(LR_TeamGrid.cureTarget) then
					LR_TeamGrid.SetTarget(LR_TeamGrid.cureTarget)
				end
			end
		end
	elseif szName == "Btn_LR_GKP" then
		HideTip()
	elseif szName == "Btn_TeamNotice" then
		HideTip()
	end
	LR_TeamGrid.ResizeTitle()
end

function LR_TeamGrid.OnFrameKeyDown()
	--屏蔽功能
	if LR_TeamGrid.UsrData.CommonSettings.bInCureMode and LR_TeamGrid.UsrData.CommonSettings.cureMode == 2 then
		if IsNurse()
			if LR_TeamGrid.hoverHandle then
				local playerID = LR_TeamGrid.hoverHandle:GetPlayerID()
				if LR_TeamGrid.IfICanSelect() and LR_TeamGrid.IfTargetCanBSelect(playerID) then
					LR_TeamGrid.SetTarget(playerID)
				end
			end
		end
	end
end

function LR_TeamGrid.UpdateAnchor()
	local frame = Station.Lookup("Normal/LR_TeamGrid")
	if not frame then
		return
	end
	local Anchor = LR_TeamGrid.Anchor
	local nW, nH = Station.GetClientSize(true)
	if Anchor.x < 0 then Anchor.x = 0 end
	if Anchor.x > nW - 100 then Anchor.x = nW - 100 end
	if Anchor.y < 0 then Anchor.y = 0 end
	if Anchor.y > nH - 100 then Anchor.y = nH - 100 end
	frame:SetRelPos(Anchor.x, Anchor.y)
	frame:CorrectPos()
end


function LR_TeamGrid.UpdateRoleBodySize()
	local me = GetClientPlayer()
	if not me then
		return
	end

	if LR_TeamGrid.bMiniPanel then
		LR_TeamGrid.Handle_Body:Lookup("Image_BodyBg"):SetSize(0, 0)
		LR_TeamGrid.Handle_Body:SetSize(0, 0)
		LR_TeamGrid.frameSelf:Lookup("Wnd_Body"):SetSize(0, 0)

		LR_TeamGrid.Handle_TeamNumSub:Clear()
		LR_TeamGrid.Handle_TeamNumSub:SetSize(0, 0)
		LR_TeamGrid.Handle_BodySub:Lookup("Image_BodyBgSub"):SetSize(0, 0)
		LR_TeamGrid.Handle_BodySub:SetSize(0, 0)
		LR_TeamGrid.frameSelf:Lookup("Wnd_BodySub"):SetSize(0, 0)

		return
	end

	local UIConfig = LR_TeamGrid.UIConfig
	local marginBody = UIConfig.marginBody
	--主面板设置大小
	local width, height = 0, 0
	if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 and LR_TeamGrid.Handle_Roles:GetItemCount() == 0 then
		LR_TeamGrid.Handle_Body:Lookup("Image_BodyBg"):SetSize(0, 0)
		LR_TeamGrid.Handle_Body:SetSize(0, 0)
		LR_TeamGrid.frameSelf:Lookup("Wnd_Body"):SetSize(0, 0)
	else
		LR_TeamGrid.Handle_Body:Lookup("Image_BodyBg"):SetSize(0, 0)
		LR_TeamGrid.Handle_Body:FormatAllItemPos()
		LR_TeamGrid.Handle_Body:SetSizeByAllItemSize()
		width, height = LR_TeamGrid.Handle_Body:GetAllItemSize()
		LR_TeamGrid.Handle_Body:SetSize(width + marginBody, height + marginBody)
		LR_TeamGrid.Handle_Body:Lookup("Image_BodyBg"):SetSize(width + marginBody, height + marginBody)
		LR_TeamGrid.Handle_Body:Lookup("Image_BodyBg"):SetRelPos(0, 0)
		LR_TeamGrid.Handle_Body:FormatAllItemPos()
		width, height = LR_TeamGrid.Handle_Body:GetAllItemSize()
		LR_TeamGrid.frameSelf:Lookup("Wnd_Body"):SetSize(width, height)
	end
	--副面板设置大小
	local width2, height2 = 0, 0
	if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 then
		if LR_TeamGrid.Handle_RolesSub:GetItemCount() == 0 then
			LR_TeamGrid.Handle_TeamNumSub:Clear()
			LR_TeamGrid.Handle_TeamNumSub:SetSize(0, 0)
			LR_TeamGrid.Handle_BodySub:Lookup("Image_BodyBgSub"):SetSize(0, 0)
			LR_TeamGrid.Handle_BodySub:SetSize(0, 0)
			LR_TeamGrid.frameSelf:Lookup("Wnd_BodySub"):SetSize(0, 0)
		else
			LR_TeamGrid.Handle_BodySub:Lookup("Image_BodyBgSub"):SetSize(0, 0)
			LR_TeamGrid.Handle_BodySub:FormatAllItemPos()
			LR_TeamGrid.Handle_BodySub:SetSizeByAllItemSize()
			width2, height2 = LR_TeamGrid.Handle_BodySub:GetAllItemSize()
			LR_TeamGrid.Handle_BodySub:SetSize(width2 + marginBody, height2 + marginBody)
			LR_TeamGrid.Handle_BodySub:Lookup("Image_BodyBgSub"):SetSize(width2 + marginBody, height2 + marginBody)
			LR_TeamGrid.Handle_BodySub:Lookup("Image_BodyBgSub"):SetRelPos(0, 0)
			LR_TeamGrid.Handle_BodySub:FormatAllItemPos()
			width2, height2 = LR_TeamGrid.Handle_BodySub:GetAllItemSize()
			LR_TeamGrid.frameSelf:Lookup("Wnd_BodySub"):SetSize(width, height)
		end
	else
		LR_TeamGrid.Handle_BodySub:Lookup("Image_BodyBgSub"):SetSize(0, 0)
		LR_TeamGrid.Handle_BodySub:SetSize(0, 0)
		LR_TeamGrid.frameSelf:Lookup("Wnd_BodySub"):SetSize(0, 0)
	end

	if LR_TeamGrid.UsrData.CommonSettings.bShowSkillBox and LR.IsNurse() then
		if LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 1 then
			LR_TeamGrid.frameSelf:Lookup("Wnd_Body"):SetRelPos(0, 70)
			LR_TeamGrid.frameSelf:Lookup("Wnd_Skill_Box"):SetRelPos(0, 30)
			if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 then
				LR_TeamGrid.frameSelf:Lookup("Wnd_BodySub"):SetRelPos(0, 70 + height)
			else

			end
		elseif LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 2 then
			LR_TeamGrid.frameSelf:Lookup("Wnd_Body"):SetRelPos(0, 30)
			LR_TeamGrid.frameSelf:Lookup("Wnd_Skill_Box"):SetRelPos(0, 30 + height + height2)
			if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 then
				LR_TeamGrid.frameSelf:Lookup("Wnd_BodySub"):SetRelPos(0, 30 + height)
			else

			end
		elseif LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 3 then
			LR_TeamGrid.frameSelf:Lookup("Wnd_Body"):SetRelPos(40, 30)
			LR_TeamGrid.frameSelf:Lookup("Wnd_Skill_Box"):SetRelPos(0, 30)
			if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 then
				LR_TeamGrid.frameSelf:Lookup("Wnd_BodySub"):SetRelPos(40, 30 + height)
			else

			end
		elseif LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 4 then
			LR_TeamGrid.frameSelf:Lookup("Wnd_Body"):SetRelPos(0, 30)
			LR_TeamGrid.frameSelf:Lookup("Wnd_Skill_Box"):SetRelPos(mmax(width, width2), 30)
			if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 then
				LR_TeamGrid.frameSelf:Lookup("Wnd_BodySub"):SetRelPos(0, 30 + height)
			else

			end
		end
	else
		LR_TeamGrid.frameSelf:Lookup("Wnd_Body"):SetRelPos(0, 30)
		LR_TeamGrid.frameSelf:Lookup("Wnd_BodySub"):SetRelPos(0, 30 + height)
	end

	LR_TeamGrid.ResizeTitle()
	local titleWidth, titleHeight = LR_TeamGrid.frameSelf:Lookup("Wnd_Title"):GetSize()
	local skillBoxWidth, skillBoxHeight = LR_TeamGrid.Handle_Skill_Box:GetSize()
	if LR_TeamGrid.UsrData.CommonSettings.bShowSkillBox and (dwSkillID==10028 or dwSkillID==10080 or dwSkillID==10176 or dwSkillID==10448) then
		if LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 1 then
			LR_TeamGrid.frameSelf:SetSize(titleWidth, height + titleHeight + 40)
		elseif LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 2 then
			LR_TeamGrid.frameSelf:SetSize(titleWidth, height + titleHeight)
		elseif LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 3 then
			LR_TeamGrid.frameSelf:SetSize(titleWidth, mmax(height, skillBoxHeight) + titleHeight)
		elseif LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 4 then
			LR_TeamGrid.frameSelf:SetSize(titleWidth, mmax(height, skillBoxHeight) + titleHeight)
		end
	else
		LR_TeamGrid.frameSelf:SetSize(mmax(titleWidth, width), height + titleHeight)
	end
end

function LR_TeamGrid.OpenPanel()
	local frame = Station.Lookup("Normal/LR_TeamGrid")
	if not frame then
		local UIPath = sformat("%s\\UI\\%s\\UI.ini", AddonPath, LR_TeamGrid.UsrData.UI_Choose)
		if not (IsFileExist(UIPath)) then
			UIPath = sformat("%s\\UI\\Classic\\UI.ini", AddonPath)
			LR_TeamGrid.UsrData.UI_Choose = "Classic"
		end
		LR_TeamGrid.frame = Wnd.OpenWindow(UIPath, "LR_TeamGrid")
	end
	LR_TeamGrid.UpdateTeamMember()
	LR_TeamGrid.ReDrawAllMembers(true)
end

function LR_TeamGrid.ClosePanel()
	local frame = Station.Lookup("Normal/LR_TeamGrid")
	if frame then
		Wnd.CloseWindow(frame)
	end
end

function LR_TeamGrid.SwitchPanel()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if LR_TeamGrid.bOn then
--[[		if LR.IsMapBlockAddon() then
			LR_TeamGrid.ClosePanel()
		elseif me.IsInRaid() then]]
		if me.IsInRaid() then
			LR_TeamGrid.OpenPanel()
		elseif me.IsInParty() and not LR_TeamGrid.UsrData.CommonSettings.bShowOnlyInRaidMode then
			LR_TeamGrid.OpenPanel()
		else
			LR_TeamGrid.ClosePanel()
		end
	else
		LR_TeamGrid.ClosePanel()
	end
	LR.DelayCall(70, function()
		LR_TeamGrid.SwitchSystemRaidPanel()
		LR_TeamGrid.SwitchSystemTeamPanel()
	end)
end

----------------------------------------------------------------------------
function LR_TeamGrid.CheckPanelActive()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local Image_Frame_State = LR_TeamGrid.Handle_Title:Lookup("Image_Frame_State")
	if not Image_Frame_State then
		return
	end
	if LR_TeamGrid.UsrData.CommonSettings.bInCureMode and LR_TeamGrid.UsrData.CommonSettings.cureMode == 2 then
		if LR.IsNurse() then
			local hActiveFrame = Station.GetActiveFrame()
			if hActiveFrame and hActiveFrame:GetName() == "LR_TeamGrid" then
				Image_Frame_State:FromIconID(6933)
			else
				Image_Frame_State:FromIconID(6942)
			end
			Image_Frame_State:Show()
		else
			Image_Frame_State:Hide()
		end
	else
		Image_Frame_State:Hide()
	end
end

function LR_TeamGrid.OpenRaidDragPanel(dwMemberID)
	local hTeam = GetClientTeam()
	local tMemberInfo = hTeam.GetMemberInfo(dwMemberID)
	if not tMemberInfo then
		return
	end

	local hFrame = Wnd.OpenWindow("RaidDragPanel")
	if not hFrame then
		return
	end

	local nX, nY = Cursor.GetPos()
	hFrame:SetAbsPos(nX, nY)
	hFrame:StartMoving()

	hFrame.dwID = dwMemberID
	local hMember = hFrame:Lookup("", "")

	local szPath, nFrame = GetForceImage(tMemberInfo.dwForceID)
	hMember:Lookup("Image_Force"):FromUITex(szPath, nFrame)

	local hTextName = hMember:Lookup("Text_Name")
	--hTextName:SetText("sdf")
	hTextName:SetText(tMemberInfo.szName)

	local hImageLife = hMember:Lookup("Image_Health")
	local hImageMana = hMember:Lookup("Image_Mana")
	if tMemberInfo.bIsOnLine then
		if tMemberInfo.nMaxLife > 0 then
			hImageLife:SetPercentage(tMemberInfo.nCurrentLife / tMemberInfo.nMaxLife)
		end
		if tMemberInfo.nMaxMana > 0 and tMemberInfo.nMaxMana ~= 1 then
			hImageMana:SetPercentage(tMemberInfo.nCurrentMana / tMemberInfo.nMaxMana)
		end
	else
		hImageLife:SetPercentage(0)
		hImageMana:SetPercentage(0)
	end

	hMember:Show()
end

function LR_TeamGrid.CloseRaidDragPanel()
	local hFrame = Station.Lookup("Normal/RaidDragPanel")
	if hFrame then
		hFrame:EndMoving()
		Wnd.CloseWindow(hFrame)
	end
end


----------------------------------------------------------------------------
function LR_TeamGrid.ResetCommonData()
	local src = sformat("%s\\CommonSettings.dat", SaveDataPath)
	local data = clone(DefaultData)
	SaveLUAData(src, data)
	LR_TeamGrid.UsrData = clone(data)
	LR_TeamGrid.Anchor = clone(DefaultCommonSettings.Anchor)
	LR_TeamGrid.UpdateAnchor()
end

function LR_TeamGrid.ResetColorSettings()
	local src = sformat("%s\\CommonSettings.dat", SaveDataPath)
	local data = clone(LR_TeamGrid.UsrData)
	data.CommonSettings.distanceColor = clone(DefaultCommonSettings.distanceColor)
	SaveLUAData(src, data)
	LR_TeamGrid.UsrData = clone(data)
end

function LR_TeamGrid.CheckCommonData()
	local src = sformat("%s\\CommonSettings.dat", SaveDataPath)
	if IsFileExist(sformat("%s.jx3dat", src)) then
		local data = LoadLUAData(src) or {}
		if data.VERSION and data.VERSION == VERSION then
			LR_TeamGrid.UsrData = clone(data)
		else
			LR_TeamGrid.ResetCommonData()
		end
	else
		LR_TeamGrid.ResetCommonData()
	end
end

function LR_TeamGrid.LoadCommonData()
	LR_TeamGrid.CheckCommonData()
	local src = sformat("%s\\CommonSettings.dat", SaveDataPath)
	local data = LoadLUAData(src) or {}
	LR_TeamGrid.UsrData = clone(data)
end

function LR_TeamGrid.SaveCommonData()
	local src = sformat("%s\\CommonSettings.dat", SaveDataPath)
	local data = clone(LR_TeamGrid.UsrData)
	SaveLUAData(src, data)
end

function LR_TeamGrid.LoadUIList()
	local _, _, szLang = GetVersion()
	local src = sformat("%s\\UI\\UIList.%s", AddonPath, szLang)
	local data = LoadLUAData(src) or {}
	LR_TeamGrid.UIList = clone(data)
end

function LR_TeamGrid.LoadUIConfig()
	local src = sformat("%s\\UI\\%s\\config.dat", AddonPath, LR_TeamGrid.UsrData.UI_Choose)
	local data = LoadLUAData(src) or {}
	LR_TeamGrid.UIConfig = clone(data)
end
-----------------------------------------------------------------------
function LR_TeamGrid.UpdateSingleMemberInfo(dwID)
	local player =  GetClientPlayer()
	if not player then return end
	local team= GetClientTeam()
	if not team then return end
	local MemberInfo = team.GetMemberInfo(dwID)
	_Members[dwID] = clone (MemberInfo)
end

function LR_TeamGrid.UpdateTeamMember()
	local player =  GetClientPlayer()
	if not player then return end
	local team= GetClientTeam()
	if not team then return end
	local team_member = team.nGroupNum
	local tGroupMembers={}
	if player.IsInRaid() then
		for i=0,4,1 do
			tGroupMembers[i+1] = team.GetGroupInfo(i)
		end
	elseif player.IsInParty() then
		tGroupMembers[1] = team.GetGroupInfo(0)
		for i=2,4 do
			tGroupMembers[i] = {MemberList={}}
		end
	end
	LR_TeamGrid.tGroupMembers = clone(tGroupMembers)
	for nCol , v in pairs(tGroupMembers) do
		local MemberList = v.MemberList
		if next(MemberList) ~= nil then
			for nRow, dwID in pairs(MemberList) do
				LR_TeamGrid.UpdateSingleMemberInfo(dwID)
			end
		end
	end
end

function LR_TeamGrid.DrawAllMembers()
	if LR_TeamGrid.bMiniPanel then
		return
	end

	local tGroupMembers = LR_TeamGrid.tGroupMembers or {}
	local nCol = 0
	local count = 1
	local team = GetClientTeam()
	_tPartyMark = team.GetTeamMark() or {}
	for i = 1, 5, 1 do
		if tGroupMembers[i] then
			local MemberList = tGroupMembers[i].MemberList
			if next(MemberList) ~= nil then
				for nRow, dwID in pairs(MemberList) do
					if not _tRoleGrids[dwID] then
						local roleGrid=_RoleGrid:new(dwID)
						roleGrid:SetRealCol(i - 1):Create():SetRoleBodySize()
						roleGrid:SetRoleNameSize():SetRoleNameRelPos()
						roleGrid:SetLifeBarSize():SetLifeBarRelPos()
						roleGrid:SetManaBarSize():SetManaBarPos()
						roleGrid:SetKungfuTextSize():SetKungfuTextRelPos():SetKungfuImageSize():SetKungfuImageRelPos()
						roleGrid:SetGroupEyeSize():SetGroupEyeRelPos():DrawGroupEye()
						roleGrid:SetBossTargetImageSize():SetBossTargetImageRelPos()
						roleGrid:SetLeaderImageSize():SetLeaderImageRelPos():DrawLeaderImage()
						roleGrid:SetMarkerImageSize():SetMarkerImageRelPos():DrawMarkerImage()
						roleGrid:SetLooterImageSize():SetLooterImageRelPos():DrawLootertImage()
						roleGrid:SetDistanceTextSize():SetDistanceTextRelPos():DrawDistanceText()
						roleGrid:SetWorldMarkImageSize():SetWorldMarkImageRelPos()
						roleGrid:SetEdgeIndicatoSize():SetEdgeIndicatoRelPos()
						roleGrid:SetMicOpenSize():SetMicOpenRelPos():DrawMicOpen(false)
						roleGrid:SetMicDisableSize():SetMicDisableRelPos():DrawMicDisable(false)
						roleGrid:SetSpecialBuffSize():SetSpecialBuffRelPos()
						roleGrid:SetLifeTextSize():SetLifeTextRelPos()
						roleGrid:SetConfirmImageSize():SetConfirmImageRelPos()
						roleGrid:SetHandleBuffSize():SetHandleBuffRelPos()
						--roleGrid:SetBuffBoxSize():SetBuffBoxRelPos()

						roleGrid:Scale()
						_tRoleGrids[dwID] = roleGrid
					end
					_tRoleGrids[dwID]:SetRealCol(i - 1):SetCol(nCol):SetRow(nRow-1):SetRoleBodyRelPos():DrawWorldMarkImage()
					_tRoleGrids[dwID]:SetRoleName(_Members[dwID].szName):DrawKungFu()
					_tRoleGrids[dwID]:DrawLifeText():DrawLifeBar():DrawManaBar()
					_tRoleGrids[dwID]:DrawDistanceText()
					_tRoleGrids[dwID]:SetIndex(count)
					count = count + 1
				end
				nCol = nCol +1
			end
		end
		if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 and i == 3 then
			nCol = 0
		end
	end
	LR_TeamGrid.DrawTeamNum()

	LR_TeamGrid.Handle_Roles:FormatAllItemPos()
	LR_TeamGrid.Handle_Roles:SetSizeByAllItemSize()

	if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 then
		LR_TeamGrid.Handle_RolesSub:FormatAllItemPos()
		LR_TeamGrid.Handle_RolesSub:SetSizeByAllItemSize()
	end
	LR_TeamGrid.UpdateRoleBodySize()
end

function LR_TeamGrid.ReDrawAllMembers(bClear)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local frame = Station.Lookup("Normal/LR_TeamGrid")
	if not frame then
		return
	end
	if bClear then
		LR_TeamBuffMonitor.ClearhMemberNormalBuff()
		LR_TeamEdgeIndicator.ClearEdgeIndicatorCache()
		LR_TeamBuffMonitor.ClearSpecialBuffCache(dwID)

		_JCG = {}
		_tBossFocusList = {}

		LR_TeamGrid.Handle_Roles:Clear()
		LR_TeamGrid.Handle_RolesSub:Clear()
		LR_TeamGrid.Handle_TeamNum:Clear()
		LR_TeamGrid.Handle_TeamNumSub:Clear()
		_tRoleGrids={}
	end
	LR_TeamGrid.DrawAllMembers()
	if bClear then
		for dwPlayerID, v in pairs(_tRoleGrids) do
			LR_TeamBuffMonitor.RedrawBuffBox(dwPlayerID)
			LR_TeamBuffMonitor.RedrawEdgeIndicatorBUFF(dwPlayerID)
			LR_TeamBuffMonitor.RedrawSpecialBuffBox(dwPlayerID)
		end
	end
end

function LR_TeamGrid.DrawExtendGrid()
	local team = GetClientTeam()
	if not team then
		return
	end
	local nGroupNum = team.nGroupNum
	local tGroupMembers = LR_TeamGrid.tGroupMembers

	local nCol = 0
	for i = 0, nGroupNum - 1, 1 do
		local MemberList = tGroupMembers[i + 1].MemberList
		local nEmptyStart = #MemberList
		for nRow = 1, nEmptyStart, 1 do
			if _tRoleGrids[MemberList[nRow]] then
				_tRoleGrids[MemberList[nRow]]:SetCol(nCol):SetRow(nRow-1):SetRoleBodyRelPos()
			end
		end
		for nRow = nEmptyStart + 1, 5, 1 do
			local dwID = i * 10 + nRow
			if not _tExtendGrids[dwID] then
				local roleGrid=_RoleGrid:new(dwID)
				roleGrid:SetRealCol(i):Create():SetRoleBodySize()
				roleGrid:ShowEmptyGrid()
				roleGrid:Scale()
				_tExtendGrids[dwID] = roleGrid
			end
			_tExtendGrids[dwID]:SetRealCol(i):SetCol(nCol):SetRow(nRow-1):SetRoleBodyRelPos()
		end
		nCol = nCol + 1
		if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 and i == 2 then
			nCol = 0
		end
	end

	LR_TeamGrid.Handle_Roles:FormatAllItemPos()
	LR_TeamGrid.Handle_Roles:SetSizeByAllItemSize()
	LR_TeamGrid.DrawTeamNum()
	LR_TeamGrid.UpdateRoleBodySize()
end

function LR_TeamGrid.DrawTeamNum()
	local team = GetClientTeam()
	if not team then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local Handle_TeamNum = LR_TeamGrid.Handle_TeamNum
	local Handle_Body = LR_TeamGrid.Handle_Body
	local tGroupMembers = LR_TeamGrid.tGroupMembers or {}
	Handle_TeamNum:Clear()
	Handle_TeamNum:SetSize(0,0)
	Handle_TeamNum:SetRelPos(0,0)

	local Handle_TeamNumSub = LR_TeamGrid.Handle_TeamNumSub
	local Handle_BodySub = LR_TeamGrid.Handle_BodySub
	if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 then
		Handle_TeamNumSub:Clear()
		Handle_TeamNumSub:SetSize(0,0)
		Handle_TeamNumSub:SetRelPos(0,0)
	end

	if LR_TeamGrid.UsrData.CommonSettings.bDisableTeamNum then
		Handle_Body:FormatAllItemPos()
		return
	end

	if next(tGroupMembers) == nil then
		return
	end
	local nMaxCol = team.nGroupNum
	local szIniFile = sformat("%s\\UI\\%s\\UI.ini", AddonPath, LR_TeamGrid.UsrData.UI_Choose)
	local n = 0
	for nCol = 0, nMaxCol - 1, 1 do
		local hTextNum = nil
		local TeamNum = Handle_TeamNum
		if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 and nCol > 2 then
			TeamNum = Handle_TeamNumSub
		end

		if bDraged then
			hTextNum = TeamNum:AppendItemFromIni(szIniFile, "Text_Num", sformat("Text_Num_%d", nCol))
		elseif next(tGroupMembers[nCol +1].MemberList) ~= nil then
			hTextNum = TeamNum:AppendItemFromIni(szIniFile, "Text_Num", sformat("Text_Num_%d", nCol))
		end
		if hTextNum then
			local Text_Num = ""
			if nCol == 0 then
				if me.IsInRaid() then
					Text_Num = _L["ONE"]
				elseif	me.IsInParty() then
					Text_Num = _L["TEAM"]
				end
			elseif nCol == 1 then
				Text_Num = _L["TWO"]
			elseif nCol == 2 then
				Text_Num = _L["THREE"]
			elseif nCol == 3 then
				Text_Num = _L["FOUR"]
			elseif nCol == 4 then
				Text_Num = _L["FIVE"]
			end
			hTextNum:SetText(Text_Num)
			hTextNum:SetHAlign(1)
			if team.GetMemberGroupIndex(me.dwID) == nCol then
				hTextNum:SetFontScheme(207)
			else
				hTextNum:SetFontScheme(17)
			end
			local UIConfig = LR_TeamGrid.UIConfig
			local height = UIConfig.wholeRoleGrid.height
			local width = UIConfig.wholeRoleGrid.width
			local margin_x = UIConfig.wholeRoleGrid.margin_x
			local margin_y = UIConfig.wholeRoleGrid.margin_y
			local marginBody = UIConfig.marginBody
			local CommonSettings = LR_TeamGrid.UsrData.CommonSettings
			local fx, fy = CommonSettings.scale.fx, CommonSettings.scale.fy
			hTextNum:SetSize(width * fx, 18)
			hTextNum:SetVAlign(2)
			hTextNum:SetHAlign(1)
			hTextNum:SetRelPos(marginBody + n * (width + margin_x) * fx, 0)
			n = n + 1
		end

		if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 and nCol == 2 then
			n = 0
		end
	end
	Handle_TeamNum:FormatAllItemPos()
	Handle_TeamNum:SetSizeByAllItemSize()
	local width, height = LR_TeamGrid.Handle_Roles:GetAllItemSize()
	Handle_TeamNum:SetRelPos(0, height + LR_TeamGrid.UIConfig.wholeRoleGrid.margin_y)
	Handle_Body:FormatAllItemPos()

	Handle_TeamNumSub:FormatAllItemPos()
	Handle_TeamNumSub:SetSizeByAllItemSize()
	local width2, height2 = LR_TeamGrid.Handle_RolesSub:GetAllItemSize()
	Handle_TeamNumSub:SetRelPos(0, height2 + LR_TeamGrid.UIConfig.wholeRoleGrid.margin_y)
	Handle_BodySub:FormatAllItemPos()
end

function LR_TeamGrid.DrawImageLoot(nLootMode)
	local frame = LR_TeamGrid.frameSelf
	local WndContainer_Title = frame:Lookup("Wnd_Title"):Lookup("WndContainer_Title")
	local Btn_LootMode = WndContainer_Title:Lookup("Btn_LootMode")
	if Btn_LootMode then
		local Image_Loot = Btn_LootMode:Lookup("",""):Lookup("Image_LootMode")
		Image_Loot:Show()
		Image_Loot:SetAlpha(200)
		if nLootMode== 1 then	--自由拾取
			Image_Loot:FromUITex("ui\\Image\\TargetPanel\\Target.UITex",60)
		elseif nLootMode == 2 then	--分配者分配
			Image_Loot:FromUITex("ui\\Image\\UICommon\\CommonPanel2.UITex",92)
		elseif nLootMode == 3 then	--队伍拾取Roll点
			Image_Loot:FromUITex("ui\\Image\\UICommon\\LoginCommon.UITex",29)
		elseif nLootMode == 4 then	--拍卖分配
			Image_Loot:FromUITex("ui\\Image\\UICommon\\GoldTeam.UITex",7)
		end
	end
end

function LR_TeamGrid.DrawImageLootLevel(nRollQuality)
	local frame = LR_TeamGrid.frameSelf
	local WndContainer_Title = frame:Lookup("Wnd_Title"):Lookup("WndContainer_Title")
	local Btn_LootLevel = WndContainer_Title:Lookup("Btn_LootLevel")
	if Btn_LootLevel then
		local Image_Level = Btn_LootLevel:Lookup("",""):Lookup("Image_LootLevel")
		Image_Level:Show()
		Image_Level:SetAlpha(200)
		if nRollQuality == 2 then
			Image_Level:FromUITex("ui\\Image\\icon\\huodong_wabao_09.UITex",0)
		elseif nRollQuality == 3 then
			Image_Level:FromUITex("ui\\Image\\icon\\huodong_wabao_05.UITex",0)
		elseif nRollQuality == 4 then
			Image_Level:FromUITex("ui\\Image\\icon\\huodong_wabao_10.UITex",0)
		elseif nRollQuality == 5 then
			Image_Level:FromUITex("ui\\Image\\icon\\huodong_wabao_08.UITex",0)
		end
	end
end

function LR_TeamGrid.StartReadyConfirmCheck()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_TeamGrid.IsLeader(me.dwID) then
		return
	end
	if me.IsInParty() or me.IsInRaid() then
		for dwID , v in pairs (_tRoleGrids) do
			if v then
				v:ShowReadyConfirmImage()
			end
		end
	end
end

function LR_TeamGrid.ClearReadyConfirm()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if me.IsInParty() or me.IsInRaid() then
		for dwID , v in pairs (_tRoleGrids) do
			if v then
				v:ClearReadyConfirm()
			end
		end
	end
end

function LR_TeamGrid.ChangeMicStatus()
	GVoiceBase_SwitchMicState()
end

function LR_TeamGrid.ChangeSpeakerStatus()
	GVoiceBase_SwitchSpeakerState()
end

function LR_TeamGrid.ListButtons()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local hFrame = LR_TeamGrid.frameSelf
	local Wnd_Title = hFrame:Lookup("Wnd_Title")
	local WndContainer_Title = Wnd_Title:Lookup("WndContainer_Title")
	WndContainer_Title:Clear()
	WndContainer_Title:SetSize(1000, 30)

	local szIniFile = sformat("%s\\UI\\%s\\TitleButton.ini", AddonPath, LR_TeamGrid.UsrData.UI_Choose)
	WndContainer_Title:AppendContentFromIni(szIniFile, "Btn_Option", "Btn_Option")

	local team = GetClientTeam()
	if LR_TeamGrid.UsrData.CommonSettings.TitleButton.ShowLootModeBtn then
		WndContainer_Title:AppendContentFromIni(szIniFile, "Btn_LootMode", "Btn_LootMode")
		if team then
			LR_TeamGrid.DrawImageLoot(team.nLootMode)
		end
	end
	if LR_TeamGrid.UsrData.CommonSettings.TitleButton.ShowLootLevelBtn then
		WndContainer_Title:AppendContentFromIni(szIniFile, "Btn_LootLevel", "Btn_LootLevel")
		if team then
			LR_TeamGrid.DrawImageLootLevel(team.nRollQuality)
		end
	end
	if LR_TeamGrid.UsrData.CommonSettings.TitleButton.ShowWorldMarkBtn then
		WndContainer_Title:AppendContentFromIni(szIniFile, "Btn_WorldMark", "Btn_WorldMark")
	end
	if LR_TeamGrid.UsrData.CommonSettings.TitleButton.ShowGoldTeamBtn then
		WndContainer_Title:AppendContentFromIni(szIniFile, "Btn_LR_GKP", "Btn_LR_GKP")
	end
	if LR_TeamGrid.UsrData.CommonSettings.TitleButton.ShowTeamNoticeBtn then
		WndContainer_Title:AppendContentFromIni(szIniFile, "Btn_TeamNotice", "Btn_TeamNotice")
	end
	if LR_TeamGrid.UsrData.CommonSettings.TitleButton.ShowVoiceBtn then
		WndContainer_Title:AppendContentFromIni(szIniFile, "Wnd_Speaker", "Wnd_Speaker")
		WndContainer_Title:AppendContentFromIni(szIniFile, "Wnd_Mic", "Wnd_Mic")
		hFrame:Lookup("Wnd_Title"):Lookup("WndContainer_Title"):Lookup("Wnd_Mic"):Lookup("Btn_Mic"):Lookup("",""):Lookup("Handle_HotKey"):Lookup("Text_HotKey"):SetFontScale(0.9)
		hFrame:Lookup("Wnd_Title"):Lookup("WndContainer_Title"):Lookup("Wnd_Mic"):Lookup("Btn_Mic"):Lookup("",""):Lookup("Handle_Free_Mic"):Lookup("Text_Free"):SetFontScale(0.9)
	end
	WndContainer_Title:AppendContentFromIni(szIniFile, "Wnd_TitleText", "Wnd_TitleText")

	if LR_TeamGrid.UsrData.CommonSettings.TitleButton.ShowMiniBtn then
		WndContainer_Title:SetSize(1000, 30)
		WndContainer_Title:AppendContentFromIni(szIniFile, "Wnd_Fold", "Wnd_Fold")
		hFrame:Lookup("Wnd_Title"):Lookup("WndContainer_Title"):Lookup("Wnd_Fold"):Lookup("CheckBox_Fold"):Check(LR_TeamGrid.bMiniPanel)
	end

	LR_TeamGrid.SetTitleText("")
	---因为会改1大小，所以放后面
	if LR_TeamGrid.UsrData.CommonSettings.TitleButton.ShowVoiceBtn then
		LR_TeamGrid.GVOICE_MIC_STATE_CHANGED()
		LR_TeamGrid.GVOICE_SPEAKER_STATE_CHANGED()
	end

	WndContainer_Title:FormatAllContentPos()
	LR_TeamGrid.ResizeTitle()
end

function LR_TeamGrid.ResizeTitle()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local hFrame = LR_TeamGrid.frameSelf
	local Wnd_Title = hFrame:Lookup("Wnd_Title")
	local WndContainer_Title = Wnd_Title:Lookup("WndContainer_Title")
	WndContainer_Title:SetSize(1000, 30)
	WndContainer_Title:FormatAllContentPos()
	local w1, h1 = WndContainer_Title:GetAllContentSize()

	local Wnd_Body = hFrame:Lookup("Wnd_Body")
	local w2, h2 = Wnd_Body:GetSize()

	local w = mmax(w1 + 5, w2, 80)
	--考虑技能面板
	local Wnd_Skill_Box = hFrame:Lookup("Wnd_Skill_Box")
	local w3, h3 = Wnd_Skill_Box:GetSize()
	if LR_TeamGrid.UsrData.CommonSettings.bShowSkillBox and LR.IsNurse() then
		if LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 1 then  --上下
			w = mmax(w1 + 5, w2, w3)
		elseif LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 3 or LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 4 then
			w = mmax(w1 + 5, (w2 + w3))
		end
	end

	--Output("c", {Cursor.GetPos(true)}, "w", {Wnd_Title:GetAbsPos()})
	local cX, cY = Cursor.GetPos(true)
	local wX, wY = Wnd_Title:GetAbsPos()
	if cX >= wX and cX <= wX + w and cY >= wY and cY <= wY + 30 then
		if w == w1 + 5 then
			w = w + 30
		end
	end

	Wnd_Title:SetSize(w, 30)
	WndContainer_Title:SetSize(w, 30)
	--WndContainer_Title:SetRelPos(3, 2)
	Handle_Title = Wnd_Title:Lookup("","")
	Handle_Title:Lookup("Image_TitleBg"):SetSize(w, 30)
	Handle_Title:Lookup("Image_Title"):SetSize(w, 30)
	hFrame:SetDragArea(0, 0, w, 30)
end

function LR_TeamGrid.SetTitleText(szText)
	local hFrame = LR_TeamGrid.frameSelf
	local Wnd_Title = hFrame:Lookup("Wnd_Title")
	local WndContainer_Title = Wnd_Title:Lookup("WndContainer_Title")
	local Wnd_TitleText = WndContainer_Title:Lookup("Wnd_TitleText")
	if Wnd_TitleText then
		local Handle_TitleText = Wnd_TitleText:Lookup("","")
		local Text_TitleText = Handle_TitleText:Lookup("Text_TitleText")
		Text_TitleText:SetSize(1000,30)
		Text_TitleText:SetText(szText)

		local width, height = Text_TitleText:GetTextExtent()
		Text_TitleText:SetSize(width, 24)
		Handle_TitleText:SetSize(width, 24)
		Wnd_TitleText:SetSize(width, 24)

		LR_TeamGrid.ResizeTitle()
	end
end

function LR_TeamGrid.CheckAllMemberMicStatus()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local sayingInfo = GVoiceBase_GetSaying()
	for dwID, v in pairs(_tRoleGrids) do
		if dwID == GetClientPlayer().dwID then
			v:DrawMicOpen(false)
			local frame = LR_TeamGrid.frameSelf
			local Wnd_Mic = frame:Lookup("Wnd_Title"):Lookup("Wnd_Mic")
			if Wnd_Mic then
				local Btn_Mic = Wnd_Mic:Lookup("Btn_Mic")
				local Handle_Status_Mic = Btn_Mic:Lookup("","")
				local Animate_Input_Mic = Handle_Status_Mic:Lookup("Animate_Input_Mic")
				if GVoiceBase_IsMemberSaying(dwID, sayingInfo) then
					Animate_Input_Mic:Show()
				else
					Animate_Input_Mic:Hide()
				end
			end
		else
			if GVoiceBase_IsMemberForbid(dwID) then
				v:DrawMicDisable(true)
				v:DrawMicOpen(false)
			else
				v:DrawMicDisable(false)
				v:DrawMicOpen(GVoiceBase_IsMemberSaying(dwID, sayingInfo))
			end
		end
	end
end

-----------------------------------------------------------------------
function LR_TeamGrid.IfICanSelect()
	local me = GetClientPlayer()
	if not me then
		return false
	end
	local scene = me.GetScene()
	if scene.nType == MAP_TYPE.NORMAL_MAP or scene.nType == MAP_TYPE.BATTLE_FIELD then
		if me.nMoveState == MOVE_STATE.ON_JUMP or me.nMoveState == 26 or me.nMoveState == MOVE_STATE.ON_RUN then
			return false
		end
	end
	return true
end

function LR_TeamGrid.IfTargetCanBSelect(dwID)
	local me = GetClientPlayer()
	if not me then
		return false
	end
	if IsPlayer(dwID) then
		local player = GetPlayer(dwID)
		if not player then
			return false
		end
		if me.IsPlayerInMyParty(dwID) then
			local scene = me.GetScene()
			LR_TeamGrid.UpdateSingleMemberInfo(dwID)
			local Members = _Members[dwID]
			if Members and Members.dwMapID == scene.dwMapID and Members.nMapCopyIndex == scene.nCopyIndex and LR.GetDistance(player) <= 56 then
				return true
			else
				return false
			end
		else
			local distance = LR.GetDistance(player)
			if distance <= 56 then
				return true
			end
			return false
		end
	else
		local npc = GetNpc(dwID)
		if not npc then
			return false
		end
		local distance = LR.GetDistance(npc)
		if distance <= 56 then
			return true
		end
		return false
	end
end

-- 获取团长 ID
function LR_TeamGrid.GetLeader()
	local team = GetClientTeam()
	if not team then
		return
	end
	return team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
end

-- 判断玩家是否是团队队长
function LR_TeamGrid.IsLeader(dwMemberID)
	return dwMemberID == LR_TeamGrid.GetLeader()
end

-- 获取阵眼 ID
function LR_TeamGrid.GetGroupEye(nGroupIndex)
	local team = GetClientTeam()
	if not team then
		return
	end
	if GetClientPlayer().IsInParty() then
		local tGroupInfo = team.GetGroupInfo(nGroupIndex)
		if tGroupInfo and tGroupInfo.MemberList and #tGroupInfo.MemberList > 0 then
			return tGroupInfo.dwFormationLeader
		end
	end
end

-- 判断玩家是否是阵眼
function LR_TeamGrid.IsGroupEye(dwMemberID)
	local team = GetClientTeam()
	if not team then
		return
	end
	if GetClientPlayer().IsInParty() then
		for i = 0, mmin(4, team.nGroupNum - 1) do
			local tGroupInfo = team.GetGroupInfo(i)
			if tGroupInfo and tGroupInfo.MemberList and #tGroupInfo.MemberList > 0 and tGroupInfo.dwFormationLeader == dwMemberID then
				return true
			end
		end
	end
	return false
end

-- 获取拾取者 ID
function LR_TeamGrid.GetLooter()
	local team = GetClientTeam()
	if not team then
		return
	end
	return team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
end

-- 判断玩家是否拾取者
function LR_TeamGrid.IsLooter(dwMemberID)
	return dwMemberID == LR_TeamGrid.GetLooter()
end

-- 获取标记者 ID
function LR_TeamGrid.GetMarker()
	local team = GetClientTeam()
	if not team then
		return
	end
	return team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK)
end

-- 判断玩家是否标记者
function LR_TeamGrid.IsMarker(dwMemberID)
	return dwMemberID == LR_TeamGrid.GetMarker()
end

-- 获取拾取模式和品质
function LR_TeamGrid.GetLootModenQuality()
	local team = GetClientTeam()
	if not team then
		return
	end
	return team.nLootMode, team.nRollQuality
end

function LR_TeamGrid.CheckIsbOpenPanel()
	local me = GetClientPlayer()
	if not me then
		return false
	end
	if not LR_TeamGrid.bOn then
		return false
	end
	local scene = me.GetScene()

	if me.IsInParty() or me.IsInRaid() then
		return true
	end
	return false
end

function LR_TeamGrid.OutputTeamMemberTip(dwID, rc)
	if not LR_TeamGrid.UsrData.CommonSettings.bShowNewTip then
		HideTip()
		OutputTeamMemberTip(dwID,rc)
		return
	end
	local hTeam = GetClientTeam()
	local tMemberInfo = hTeam.GetMemberInfo(dwID)
	if not tMemberInfo then
		return
	end
	local r, g, b = LR.GetMenPaiColor(tMemberInfo.dwForceID)
	local szPath, nFrame = GetForceImage(tMemberInfo.dwForceID)
	local szTip = {}
	szTip[#szTip+1] = GetFormatImage(szPath, nFrame, 26, 26)
	szTip[#szTip+1] = GetFormatText(FormatString(g_tStrings.STR_NAME_PLAYER, tMemberInfo.szName), 80, r, g, b)
	if tMemberInfo.bIsOnLine then
		local p = GetPlayer(dwID)
		if p and p.dwTongID > 0 then
			local szName=LR.GetTongName(p.dwTongID)
			szTip[#szTip+1] = GetFormatText(_L["Tong:"],224)
			szTip[#szTip+1] = GetFormatText(sformat("%s\n", szName), 27)
		end
    	szTip[#szTip+1] = GetFormatText(_L["Level:"],224)
		szTip[#szTip+1] = GetFormatText(FormatString(g_tStrings.STR_PLAYER_H_WHAT_LEVEL, tMemberInfo.nLevel), 27)
		szTip[#szTip+1] = GetFormatText(_L["Kungfu:"],224)
		szTip[#szTip+1] = GetFormatText(sformat("%s\n", LR.GetXinFa(tMemberInfo.dwMountKungfuID)), 27)
		local szMapName = Table_GetMapName(tMemberInfo.dwMapID)
		if szMapName then
			szTip[#szTip+1] = GetFormatText(_L["Map:"],224)
			szTip[#szTip+1] = GetFormatText(sformat("%s\n", szMapName), 27)
		end
		local nCamp = tMemberInfo.nCamp
		szTip[#szTip+1] = GetFormatText(_L["Camp:"], 224)
		szTip[#szTip+1] = GetFormatText(sformat("%s\n", g_tStrings.STR_GUILD_CAMP_NAME[nCamp]), 27)
	else
		szTip[#szTip+1] = GetFormatText(sformat("%s\n", g_tStrings.STR_FRIEND_NOT_ON_LINE), 82, 128, 128, 128)
	end
	if not GetClientPlayer().IsPartyMemberInSameScene(dwID) then
		if tMemberInfo.dwMapID == hTeam.GetMemberInfo(GetClientPlayer().dwID).dwMapID then
			szTip[#szTip+1] = GetFormatText(sformat("%s\n", _L["This player is not in the same map with you."]), 102)
		end
	end
	if IsCtrlKeyDown() then
		szTip[#szTip+1] = GetFormatText(FormatString(g_tStrings.TIP_PLAYER_ID, dwID), 102)
	end
	OutputTip(tconcat(szTip), 345, rc)
end

function LR_TeamGrid.InsertChangeGroupMenu(tMenu, dwMemberID)
	local hTeam = GetClientTeam()
	local tSubMenu = { szOption = g_tStrings.STR_RAID_MENU_CHANG_GROUP }

	local nCurGroupID = hTeam.GetMemberGroupIndex(dwMemberID)
	for i = 0, hTeam.nGroupNum - 1 do
		if i ~= nCurGroupID then
			local tGroupInfo = hTeam.GetGroupInfo(i)
			if tGroupInfo and tGroupInfo.MemberList then
				local tSubSubMenu =
				{
					szOption = g_tStrings.STR_NUMBER[i + 1],
					--bDisable = (#tGroupInfo.MemberList >= 5),
					fnAction = function()
						hTeam.ChangeMemberGroup(dwMemberID, i,0)
					end,
					fnAutoClose = function() return true end,
				}
				tinsert(tSubMenu, tSubSubMenu)
			end
		end
	end

	if #tSubMenu > 0 then
		tinsert(tMenu, tSubMenu)
	end
end

function LR_TeamGrid.SetTarget(dwID)
	--不在同一个地图的不选，普通地图、战场，状态是跳跃时不选、距离超过56的不选
	local me = GetClientPlayer()
	if not me then
		return
	end
	local tarType, tarID = me.GetTarget()
	if tarType == TARGET.PLAYER or tarType == TARGET.NPC then
		if tarID == dwID then
			return true
		end
	end
	if IsPlayer(dwID) then
		local player = GetPlayer(dwID)
		if player then
			SetTarget(TARGET.PLAYER, dwID)
		end
	else
		local npc = GetNpc(dwID)
		if npc then
			SetTarget(TARGET.NPC, dwID)
		end
	end
end

function LR_TeamGrid.BreatheSetTarget()
	local me =  GetClientPlayer()
	if not me then
		return
	end
	if GetLogicFrameCount() - LR_TeamGrid.timeCache > 8 then
		return
	end
	if LR.IsNurse() then
		if LR_TeamGrid.UsrData.CommonSettings.bInCureMode then
			if not LR_TeamGrid.IfICanSelect() then
				return
			end
			if LR_TeamGrid.bInFrame then
				if LR_TeamGrid.IfTargetCanBSelect(LR_TeamGrid.cureTargetInTeam) then
					LR_TeamGrid.SetTarget(LR_TeamGrid.cureTargetInTeam)
				end
			else
				if LR_TeamGrid.IfTargetCanBSelect(LR_TeamGrid.cureTarget) then
					LR_TeamGrid.SetTarget(LR_TeamGrid.cureTarget)
				end
			end
		else
			LR_TeamGrid.SetTarget(LR_TeamGrid.HandClickTarget)
		end
	else
		LR_TeamGrid.SetTarget(LR_TeamGrid.HandClickTarget)
	end
end

function LR_TeamGrid.GetRoleGridBuffHandle(dwMemberID)
	if _tRoleGrids[dwMemberID] then
		return _tRoleGrids[dwMemberID]:GetBuffHandle()
	end
	return nil
end

function LR_TeamGrid.GetRoleGridSpecialBuffHandle(dwMemberID)
	if _tRoleGrids[dwMemberID] then
		return _tRoleGrids[dwMemberID]:GetSpecialBuffHandle()
	end
	return nil
end

function LR_TeamGrid.GetRoleHandle(dwMemberID)
	if _tRoleGrids[dwMemberID] then
		return _tRoleGrids[dwMemberID]
	end
	return nil
end

function LR_TeamGrid.SwitchSystemRaidPanel()
	local frame = Station.Lookup("Normal/RaidPanel_Main")
	local me = GetClientPlayer()
	if not me then
		return
	end
	local scene = me.GetScene()
	if not LR_TeamGrid.bOn then
		if me.IsInRaid() and not frame then
			OpenRaidPanel()
		end
		return
	end
	--Output("s", scene.dwMapID == 74, me.IsInRaid(), not frame)
	--吃鸡地图开启系统面板
--[[	if LR.IsMapBlockAddon() and me.IsInRaid() then
		OpenRaidPanel()
		return
	end]]

	if not LR_TeamGrid.UsrData.CommonSettings.bShowSystemGridPanel then
		if frame then
			Wnd.CloseWindow(frame)
		end
	elseif me.IsInRaid() and not frame then
		OpenRaidPanel()
	end
end

function LR_TeamGrid.SwitchSystemTeamPanel()
	local frame = Station.Lookup("Normal/Teammate")
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_TeamGrid.bOn then
		if me.IsInParty() and frame and not frame:IsVisible() then
			frame:Show()
		end
		return
	end

	--吃鸡地图开启系统面板
--[[	if LR.IsMapBlockAddon() and me.IsInParty() and not me.IsInRaid() and not frame:IsVisible() then
		frame:Show()
		return
	end]]

	if me.IsInRaid() then
		if frame then
			frame:Hide()
		end
		return
	end
	if me.IsInParty() then
		if LR_TeamGrid.UsrData.CommonSettings.bShowOnlyInRaidMode then
			if frame then
				frame:Show()
			end
		else
			if not LR_TeamGrid.UsrData.CommonSettings.bShowSystemTeamPanel then
				if frame then
					frame:Hide()
				end
			else
				if frame then
					frame:Show()
				end
			end
		end
	end
end

function LR_TeamGrid.ShowVoteImage()
	for dwID, v in pairs(_tRoleGrids) do
		v:ShowVoteImage()
	end
end

function LR_TeamGrid.ClearVoteImage()
	for dwID, v in pairs(_tRoleGrids) do
		v:ClearVoteImage()
	end
	_Gold_Confirm.agree = 0
	_Gold_Confirm.all = 0
	_Gold_Confirm.stopTime = 0
	_Gold_Confirm.nType = nil
	LR_TeamGrid.SetTitleText("")
end

function LR_TeamGrid.ShowVoteText(bFresh)
	local now = GetTime()
	if now > _Gold_Confirm.stopTime then
		return
	end
	local agree = _Gold_Confirm.agree
	local all = _Gold_Confirm.all
	local stopTime = _Gold_Confirm.stopTime
	local leftTime = mfloor((stopTime - now) / 1000)
	local per = 1
	if all > 0 then
		per = mfloor(agree * 100 / all)
	end
	local szText = ""
	if _Gold_Confirm.nType == TEAM_VOTE.DELETE_MEMBER then
		szText = sformat(_L["Waiting for deleting member....%ds %d %% (%d/%d)"], leftTime, per, agree, all)
	elseif _Gold_Confirm.nType == TEAM_VOTE.DISTRIBUTE_MONEY then
		szText = sformat(_L["Waiting for money....%ds %d %% (%d/%d)"], leftTime, per, agree, all)
	end
	LR_TeamGrid.SetTitleText(szText)
	if not bFresh then
		LR.DelayCall(100, function() LR_TeamGrid.ShowVoteText() end)
	end
end


-----------------------------------------------------------------------
function LR_TeamGrid.PARTY_ADD_MEMBER()
	local dwTeamID = arg0
	local dwMemberID = arg1
	local nGroupIndex =arg2
	LR.DelayCall(100,function()
		LR_TeamGrid.UpdateTeamMember()
		LR_TeamGrid.DrawAllMembers()
	end)
	LR_TeamBuffSettingPanel.TeamMember[dwMemberID] = true
end

function LR_TeamGrid.PARTY_DELETE_MEMBER()
	local dwTeamID = arg0
	local dwMemberID = arg1
	local szName = arg2
	local nGroupIndex = arg3

	if LR_TeamGrid.CheckIsbOpenPanel() then
		if _tRoleGrids[dwMemberID] then
			_tRoleGrids[dwMemberID]:Remove()
		end
		_tRoleGrids[dwMemberID]=nil
		LR_TeamGrid.UpdateTeamMember()
		LR_TeamGrid.DrawAllMembers()
	else
		LR_TeamGrid.ClosePanel()
	end
	LR_TeamBuffMonitor.ClearOneCache(dwMemberID)
	LR_TeamBuffSettingPanel.TeamMember[dwMemberID] = nil
end

function LR_TeamGrid.TEAM_CHANGE_MEMBER_GROUP()	--有人换队伍
	local dwMemberID = arg0 --被变更的成员ID
	local nSrcGroupIndex = arg1 --原小队编号
	local nDstGroupIndex = arg2  --目标小队ID
	local dwDstMemberID = arg3	--被交换者的ID

	if LR_TeamGrid.UsrData.CommonSettings.nGridType == 2 then
		if nSrcGroupIndex <=2 and nDstGroupIndex >2 or nSrcGroupIndex > 2 and nDstGroupIndex<= 2 then
			LR_TeamBuffMonitor.ClearhMemberNormalBuff(dwMemberID)
			LR_TeamEdgeIndicator.ClearEdgeIndicatorCache(dwMemberID)
			LR_TeamBuffMonitor.ClearSpecialBuffCache(dwMemberID)
			_tRoleGrids[dwMemberID]:Remove()
			_tRoleGrids[dwMemberID] = nil
			LR.DelayCall(100, function()
				LR_TeamBuffMonitor.RedrawBuffBox(dwMemberID)
				LR_TeamBuffMonitor.RedrawEdgeIndicatorBUFF(dwMemberID)
				LR_TeamBuffMonitor.RedrawSpecialBuffBox(dwMemberID)
			end)
			if dwDstMemberID > 0 then
				LR_TeamBuffMonitor.ClearhMemberNormalBuff(dwDstMemberID)
				LR_TeamEdgeIndicator.ClearEdgeIndicatorCache(dwDstMemberID)
				LR_TeamBuffMonitor.ClearSpecialBuffCache(dwDstMemberID)
				_tRoleGrids[dwDstMemberID]:Remove()
				_tRoleGrids[dwDstMemberID] = nil
				LR.DelayCall(100, function()
					LR_TeamBuffMonitor.RedrawBuffBox(dwDstMemberID)
					LR_TeamBuffMonitor.RedrawEdgeIndicatorBUFF(dwDstMemberID)
					LR_TeamBuffMonitor.RedrawSpecialBuffBox(dwDstMemberID)
				end)
			end
		end
	end

	LR_TeamGrid.UpdateTeamMember()
	LR_TeamGrid.DrawAllMembers()

	---换队时，阵眼交换有时并不会触发阵眼交换的事件。
	LR.DelayCall(150, function()
		for dwID, v in pairs (_tRoleGrids) do
			v:DrawGroupEye()
		end
	end)
end

function LR_TeamGrid.PARTY_UPDATE_MEMBER_LMR()	--刷新血量
	local dwTeamID = arg0
	local dwMemberID = arg1
	LR_TeamGrid.UpdateSingleMemberInfo(dwMemberID)
	if _tRoleGrids[dwMemberID] then
		_tRoleGrids[dwMemberID]:DrawRoleNameText():DrawLifeText():DrawLifeBar():DrawManaBar()
	end
end

function LR_TeamGrid.PARTY_UPDATE_MEMBER_INFO()		--切换心法\死亡\复活
	local dwTeamID = arg0
	local dwMemberID = arg1
	LR.DelayCall(70, function()
		LR_TeamGrid.UpdateSingleMemberInfo(dwMemberID)
		if _tRoleGrids[dwMemberID] then
			_tRoleGrids[dwMemberID]:DrawRoleNameText():DrawLifeText():DrawLifeBar():DrawManaBar():DrawKungFu()
		end
	end)
end

function LR_TeamGrid.TEAM_AUTHORITY_CHANGED()	--团长改变、分配者改变、标记着改变
	local nAuthorityType = arg0
	local dwTeamID = arg1
	local dwOldAuthorityID = arg2
	local dwNewAuthorityID = arg3
	if nAuthorityType == TEAM_AUTHORITY_TYPE.LEADER then
		if _tRoleGrids[dwOldAuthorityID] then
			_tRoleGrids[dwOldAuthorityID]:DrawLeaderImage()
		end
		if _tRoleGrids[dwNewAuthorityID] then
			_tRoleGrids[dwNewAuthorityID]:DrawLeaderImage()
		end
	elseif nAuthorityType == TEAM_AUTHORITY_TYPE.DISTRIBUTE then
		if _tRoleGrids[dwOldAuthorityID] then
			_tRoleGrids[dwOldAuthorityID]:DrawLootertImage()
		end
		if _tRoleGrids[dwNewAuthorityID] then
			_tRoleGrids[dwNewAuthorityID]:DrawLootertImage()
		end
	elseif nAuthorityType == TEAM_AUTHORITY_TYPE.MARK then
		if _tRoleGrids[dwOldAuthorityID] then
			_tRoleGrids[dwOldAuthorityID]:DrawMarkerImage()
		end
		if _tRoleGrids[dwNewAuthorityID] then
			_tRoleGrids[dwNewAuthorityID]:DrawMarkerImage()
		end
	end
end

function LR_TeamGrid.PARTY_SET_FORMATION_LEADER()  --阵眼改变
	LR.DelayCall(100,function()
		for dwID, v in pairs (_tRoleGrids) do
			v:DrawGroupEye()
		end
	end)
end

function LR_TeamGrid.PARTY_LOOT_MODE_CHANGED()	--分配模式改变
	local dwTeamID = arg0
	local nLootMode = arg1
	LR_TeamGrid.DrawImageLoot(nLootMode)
end

function LR_TeamGrid.PARTY_ROLL_QUALITY_CHANGED()	--roll等级改变
	local dwTeamID = arg0
	local nRollQuality = arg1
	LR_TeamGrid.DrawImageLootLevel(nRollQuality)
end

function LR_TeamGrid.PARTY_SET_MEMBER_ONLINE_FLAG()	--玩家上线下线
	local dwTeamID = arg0
	local dwMemberID = arg1
	local bOnlineFlag = arg2
	LR_TeamGrid.UpdateSingleMemberInfo(dwMemberID)
	if _tRoleGrids[dwMemberID] then
		_tRoleGrids[dwMemberID]:DrawRoleNameText():DrawLifeText():DrawLifeBar():DrawManaBar():DrawKungFu()
	end
	if bOnlineFlag == 0 then
		LR_TeamBuffMonitor.ClearOneCache(dwMemberID)
	end
end

function LR_TeamGrid.PARTY_DISBAND()
	LR_TeamGrid.SwitchPanel()
	LR_TeamBuffMonitor.ClearAllCache()
end

function LR_TeamGrid.PARTY_LEVEL_UP_RAID()
	LR.DelayCall(70, function()
		LR_TeamGrid.SwitchSystemRaidPanel()
		LR_TeamGrid.SwitchPanel()
	end)
end

function LR_TeamGrid.RIAD_READY_CONFIRM_RECEIVE_ANSWER()
	local dwMemberID = arg0
	local nReadyState = arg1
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_TeamGrid.IsLeader(me.dwID) then
		return
	end
	if me.IsInParty() or me.IsInRaid() then
		if _tRoleGrids[dwMemberID] then
			_tRoleGrids[dwMemberID]:ResponseReadyConfirm(nReadyState)
		end
	end
end

function LR_TeamGrid.TEAM_VOTE_REQUEST()
	-- arg0 0=T人 1=分工资
	local nRespondType = arg0
	local team = GetClientTeam()
	_Gold_Confirm.agree = 0
	_Gold_Confirm.all = team.GetTeamSize()
	_Gold_Confirm.stopTime = GetTime() + 30 * 1000
	_Gold_Confirm.nType = nRespondType
	for dwID ,v in pairs(_tRoleGrids) do
		v:ShowVoteImage()
	end
	LR.DelayCall(30.3*1000, function() LR_TeamGrid.ClearVoteImage() end)
	LR_TeamGrid.ShowVoteText()
end

function LR_TeamGrid.TEAM_VOTE_RESPOND()
	-- arg0 回应状态 arg1 dwID arg2 同意=1 反对=0
	local nRespondType = arg0
	local dwMemberID= arg1
	local nRespondState= arg2
	if _tRoleGrids[dwMemberID] then
		_tRoleGrids[dwMemberID]:ResponseVote(nRespondState)
	end
	if nRespondState == VOTE_RESPONSE.AGREE then
		_Gold_Confirm.agree = _Gold_Confirm.agree + 1
	end
	LR_TeamGrid.ShowVoteText(true)
end

-- 重新绘制队友标记图标
function LR_TeamGrid.PARTY_SET_MARK()
	local team = GetClientTeam()
	if team then
		_tPartyMark = team.GetTeamMark() or {}
		for dwID ,v in pairs(_tRoleGrids) do
			v:DrawWorldMarkImage()
		end
	end
end

function LR_TeamGrid.MONEY_UPDATE()
	LR.DelayCall(100, function()
		local handle = Station.Lookup("Topmost2/Announce", "")
		if  handle then
			local text = handle:Lookup(4)
			local t = LR.Trim(text:GetText())
			if t==_L["End GoldTeam"] then
				LR_TeamGrid.ClearVoteImage()
			end
		end
	end)
end

function LR_TeamGrid.SYS_MSG()
	if arg0 == "UI_OME_BUFF_LOG" then
		local dwTarget, bCanCancel, dwID, bAddOrDel, nLevel = arg1, arg2, arg3, arg4, arg5
		LR_TeamBuffMonitor.UI_OME_BUFF_LOG(arg1, arg2, arg3, arg4, arg5)
	elseif arg0 == "UI_OME_DEATH_NOTIFY" then -- 死亡记录
		--arg1:死亡的人的id
		--arg2:杀死他的人的id
		--Output("UI_OME_DEATH_NOTIFY",arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7)
		LR_TeamTools.DeathRecord.OnDeath(arg1, arg2)
	elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" then -- 技能记录
		LR_TeamTools.DeathRecord.OnSkillEffectLog(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	elseif arg0 == "UI_OME_COMMON_HEALTH_LOG" then
		--LR_TeamTools.DeathRecord.OnCommonHealthLog(arg1,arg2)
	end
end

function LR_TeamGrid.GVOICE_ON_JOIN_ROOM()


end

function LR_TeamGrid.GVOICE_MIC_STATE_CHANGED()
	local nMicState = GVoiceBase_GetMicState()
	local frame = LR_TeamGrid.frameSelf
	local WndContainer_Title = frame:Lookup("Wnd_Title"):Lookup("WndContainer_Title")
	local Wnd_Mic = WndContainer_Title:Lookup("Wnd_Mic")
	if not Wnd_Mic then
		return
	end
	local Btn_Mic = Wnd_Mic:Lookup("Btn_Mic")
	local Handle_Status_Mic = Btn_Mic:Lookup("","")
	local Image_Uninsert_Mic = Handle_Status_Mic:Lookup("Image_Uninsert_Mic")
	local Image_Close_Mic = Handle_Status_Mic:Lookup("Image_Close_Mic")
	local Handle_HotKey = Handle_Status_Mic:Lookup("Handle_HotKey")
	local Handle_Free_Mic = Handle_Status_Mic:Lookup("Handle_Free_Mic")
	if nMicState == MIC_STATE.NOT_AVIAL then
		Btn_Mic:Enable(false)
		Image_Uninsert_Mic:Hide()
		Image_Close_Mic:Hide()
		Handle_HotKey:Hide()
		Handle_Free_Mic:Hide()
		Wnd_Mic:SetSize(18, 24)
	elseif nMicState == MIC_STATE.CLOSE_NOT_IN_ROOM then
		Btn_Mic:Enable(true)
		Image_Uninsert_Mic:Hide()
		Image_Close_Mic:Show()
		Handle_HotKey:Hide()
		Handle_Free_Mic:Hide()
		Wnd_Mic:SetSize(30, 24)
	elseif nMicState == MIC_STATE.CLOSE_IN_ROOM then
		Btn_Mic:Enable(true)
		Image_Uninsert_Mic:Hide()
		Image_Close_Mic:Show()
		Handle_HotKey:Hide()
		Handle_Free_Mic:Hide()
		Wnd_Mic:SetSize(30, 24)
	elseif nMicState == MIC_STATE.KEY then
		Btn_Mic:Enable(true)
		Image_Uninsert_Mic:Hide()
		Image_Close_Mic:Hide()
		Handle_HotKey:Show()
		Handle_Free_Mic:Hide()
		Wnd_Mic:SetSize(50, 24)
	elseif nMicState == MIC_STATE.FREE then
		Btn_Mic:Enable(true)
		Image_Uninsert_Mic:Hide()
		Image_Close_Mic:Hide()
		Handle_HotKey:Hide()
		Handle_Free_Mic:Show()
		Wnd_Mic:SetSize(50, 24)
	end
	WndContainer_Title:FormatAllContentPos()
	LR_TeamGrid.ResizeTitle()
end

function LR_TeamGrid.GVOICE_BASE_ON_FORBID_MEMBER()
	local dwMemberID = arg0
	local bForbid = arg1
	_tRoleGrids[dwMemberID]:DrawMicDisable(bForbid)
end

function LR_TeamGrid.GVOICE_SPEAKER_STATE_CHANGED()
	local nSpeakerState = GVoiceBase_GetSpeakerState()
	local frame = LR_TeamGrid.frameSelf
	local Wnd_Speaker = frame:Lookup("Wnd_Title"):Lookup("WndContainer_Title"):Lookup("Wnd_Speaker")
	if not Wnd_Speaker then
		return
	end

	local Btn_SpeakerAll = Wnd_Speaker:Lookup("Btn_SpeakerAll")
	local Handle_Status_Speaker = Btn_SpeakerAll:Lookup("","")
	local Image_Close_Speaker = Handle_Status_Speaker:Lookup("Image_Close_Speaker")
	local Image_Normal = Handle_Status_Speaker:Lookup("Image_Normal")
	if nSpeakerState == SPEAKER_STATE.OPEN then
		Image_Close_Speaker:Hide()
		Image_Normal:Show()
	elseif nSpeakerState == SPEAKER_STATE.CLOSE then
		Image_Close_Speaker:Show()
		Image_Normal:Hide()
	end
end

function LR_TeamGrid.NPC_ENTER_SCENE()
	local dwID = arg0
	local npc = GetNpc(dwID)
	if npc then
		--长歌切剑
		if npc.dwTemplateID == 46140 then
			if GetClientPlayer().IsPlayerInMyParty(npc.dwEmployer) then
				_JCG[npc.dwEmployer] = dwID
			end
		end
	end
end

function LR_TeamGrid.NPC_LEAVE_SCENE()
	local dwID = arg0
	for k, v in pairs(_JCG) do
		if v == dwID then
			_JCG[k] = nil
		end
	end
end

function LR_TeamGrid.ON_BOSS_FOCUS()
	local dwPlayerID = arg0
	local bFlash = arg1
	_tBossFocusList[dwPlayerID] = bFlash
end


function LR_TeamGrid.FIGHT_HINT()
	local bFight = arg0
	local frame = Station.Lookup("Normal/LR_TeamGrid")
	local me = GetClientPlayer()
	if not frame or not me then
		return
	end
	local tBossFocusList = clone(_tBossFocusList)
	_tBossFocusList = {}
	for dwPlayerID, v in pairs(tBossFocusList) do
		FireEvent("ON_BOSS_FOCUS", dwPlayerID, false)
	end
end

-----------------------------------------------------------------------
-- 关于界面打开和刷新面板的时机
-- 1) 普通情况下 组队会触发[PARTY_UPDATE_BASE_INFO]打开+刷新
-- 2) 进入竞技场/战场的情况下 不会触发[PARTY_UPDATE_BASE_INFO]事件
--    需要利用外面注册的[LOADING_END]来打开+刷新
-- 3) 如果在竞技场/战场掉线重上的情况下 需要使用外面注册的[LOADING_END]来打开面板
--    然后在UI上注册的[LOADING_END]的来刷新界面，否则获取不到团队成员，只能获取到有几个队
--    UI的[LOADING_END]晚大约30m，然后就能获取到团队成员了??????
-- 4) 从竞技场/战场回到原服使用外面注册的[LOADING_END]来打开+刷新
-- 5) 普通掉线/过地图使用外面注册的[LOADING_END]打开+刷新，避免过地图时候团队变动没有收到事件的情况。
-- 6) 综上所述的各式各样的奇葩情况 可以做如下的调整
--    利用外面的注册的[LOADING_END]来打开
--    利用UI注册的[LOADING_END]来刷新
--    避免多次重复刷新面板浪费开销


function LR_TeamGrid.PARTY_UPDATE_BASE_INFO()
	LR_TeamBuffMonitor.ClearAllCache()
	if LR_TeamGrid.CheckIsbOpenPanel() then
		LR_TeamGrid.SwitchPanel()
	end
end

function LR_TeamGrid.LOADING_END()
	LR_TeamBuffMonitor.ClearAllCache()
	if LR_TeamGrid.CheckIsbOpenPanel() then
		LR_TeamGrid.SwitchPanel()
	else
		LR_TeamGrid.ClosePanel()
	end
	LR_TeamBuffSettingPanel.TeamMember = {}
end

function LR_TeamGrid.LOGIN_GAME()
	LR_TeamGrid.LoadCommonData()
	LR_TeamGrid.LoadUIList()
	LR_TeamGrid.LoadUIConfig()
	Log("[LR_TeamRrid] : Loaded config.")
end

function LR_TeamGrid.LR_TARGET_CHANGE()
	local eTargetType, dwTargetID = arg0, arg1
	local me = GetClientPlayer()
	if not me then
		return
	end

	if me.IsInParty() or me.IsInRaid() then
		--LR_TeamGrid.target 用来存放选中高亮的人物ID
		if LR_TeamGrid.target and me.IsPlayerInMyParty(LR_TeamGrid.target) then
			if _tRoleGrids[LR_TeamGrid.target] then
				_tRoleGrids[LR_TeamGrid.target]:ShowSelectedImage(false)
			end
		end
		--local eTargetType, dwTargetID = me.GetTarget()
		if eTargetType == TARGET.PLAYER then
			if me.IsPlayerInMyParty(dwTargetID) then
				if _tRoleGrids[dwTargetID] then
					_tRoleGrids[dwTargetID]:ShowSelectedImage(true)
					LR_TeamGrid.target = dwTargetID
				end
			else
				LR_TeamGrid.target = nil
			end
		else
			LR_TeamGrid.target = nil
		end
		--长歌切剑后
		if eTargetType == TARGET.NPC then
			for k, v in pairs(_JCG) do
				if v == dwTargetID then
					if me.IsPlayerInMyParty(k) then
						if _tRoleGrids[k] then
							_tRoleGrids[k]:ShowSelectedImage(true)
							LR_TeamGrid.target = k
						end
					else
						LR_TeamGrid.target = nil
					end
				end
			end
		end

		if eTargetType == TARGET.PLAYER or eTargetType == TARGET.NPC or eTargetType == TARGET.NO_TARGET then
			if LR_TeamGrid.UsrData.CommonSettings.bInCureMode and not LR_TeamGrid.bInFrame then
				local me =  GetClientPlayer()
				if not me then
					return
				end
				if eTargetType == TARGET.NO_TARGET then
					if me.nMoveState == MOVE_STATE.ON_JUMP or me.nMoveState == 26 or me.nMoveState == MOVE_STATE.ON_RUN then
						return
					end
				end

				if LR.IsNurse() then
					if eTargetType == TARGET.PLAYER then
						if not (me.IsPlayerInMyParty(dwTargetID) and GetLogicFrameCount() - LR_TeamGrid.outTime < 12) then
							LR_TeamGrid.cureTarget = dwTargetID
							--Output("cureTarget", LR_TeamGrid.cureTarget)
						end
					else
						LR_TeamGrid.cureTarget = dwTargetID
						--Output("cureTarget", LR_TeamGrid.cureTarget)
					end
				end
			end
		end
	end
end

LR.BreatheCall("LR_Team_BreatheSetTarget", function() LR_TeamGrid.BreatheSetTarget() end)
LR.RegisterEvent("PARTY_UPDATE_BASE_INFO", function() LR_TeamGrid.PARTY_UPDATE_BASE_INFO() end)
LR.RegisterEvent("PARTY_LEVEL_UP_RAID", function() LR_TeamGrid.PARTY_LEVEL_UP_RAID() end)
LR.RegisterEvent("LOADING_END", function() LR_TeamGrid.LOADING_END() end)
LR.RegisterEvent("LOGIN_GAME", function() LR_TeamGrid.LOGIN_GAME() end)
LR.RegisterEvent("LR_TARGET_CHANGE", function() LR_TeamGrid.LR_TARGET_CHANGE() end)
