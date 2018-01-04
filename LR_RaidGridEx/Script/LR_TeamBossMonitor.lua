local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_RaidGridEx"
local SaveDataPath="Interface\\LR_Plugin@DATA\\LR_TeamGrid"
local _L = LR.LoadLangPack(AddonPath)
--------------------------------------------------------------
local ACTION_STATE =
{
	NONE = 1,
	PREPARE = 2,
	DONE = 3,
	BREAK = 4,
	FADE = 5,
}
---------------------------------------------------------------
LR_TeamBossMonitor ={}
local _BossList = {
	--[165905]={dwID=165905,OldTarget=0,isBoss=true,},
}
local _OTMonitorList = {
	--[165905]={nType=TARGET.PLAYER,nActionState=ACTION_STATE.NONE,},
}
local _OTBarHandle ={}
---------------------------------------------------------------
local _BossOTBar={
	handle=nil,
	dwID=nil,
	nLevel=0,
	nActionState=0,
	szSkillName="",
	dwSkillID=0,
	szCasterName="",
	dwCasterID=0,
}
_BossOTBar.__index = _BossOTBar

function _BossOTBar:new(dwID)
	local o={}
	setmetatable(o,self)
	o.dwID = dwID
	o.parentHandle = LR_TeamGrid.Handle_BossOTBar
	return o
end

function _BossOTBar:Create()
	local parentHandle = self.parentHandle
	local dwID = self.dwID
	local Handle_ProgressBar=parentHandle:Lookup(sformat("Boss_OTBar_%d", dwID))
	if not Handle_ProgressBar then
		local szIniFile = sformat("%s\\UI\\%s\\BossOTBar.ini", AddonPath, LR_TeamGrid.UsrData.UI_Choose)
		Handle_ProgressBar=parentHandle:AppendItemFromIni(szIniFile, "Handle_Bar", sformat("Boss_OTBar_%d", dwID))
	end
	self.handle=Handle_ProgressBar
	return self
end

function _BossOTBar:Remove()
	local parentHandle = self.parentHandle
	local dwID = self.dwID
	local Handle_ProgressBar=parentHandle:Lookup(sformat("Boss_OTBar_%d", dwID))
	if Handle_ProgressBar then
		parentHandle:RemoveItem(Handle_ProgressBar)
	end
	return self
end

function _BossOTBar:GetHandle()
	return self.handle
end

function _BossOTBar:GetCasterName()
	return self.szCasterName
end

function _BossOTBar:SetCasterName(szName)
	self.szCasterName = LR.Trim(szName) or ""
	return self
end

function _BossOTBar:GetSkillName()
	return self.szSkillName
end

function _BossOTBar:SetSkillName(szName)
	self.szSkillName= LR.Trim(szName) or ""
	return self
end

function _BossOTBar:SetText(szName)
	local szName = szName or self.szSkillName
	local handle = self.handle
	local Text_BarName=handle:Lookup("Text_BarName")
	if Text_BarName then
		Text_BarName:SetText(szName)
	end
	return self
end

function _BossOTBar:SetCasterName(szName)
	local szName = szName or ""
	local handle = self.handle
	local Text_BarName=handle:Lookup("Text_CasterName")
	if Text_BarName then
		Text_BarName:SetText(szName)
	end
	return self
end

function _BossOTBar:SetPercentage(fP)
	local handle=self.handle
	local image=handle:Lookup("Image_Progress")
	if image then
		image:SetPercentage(fP)
		image:Show()
	end
	handle:Lookup("Image_FlashS"):Hide()
	handle:Lookup("Image_FlashF"):Hide()
	return self
end

function _BossOTBar:OTSucess()
	local handle=self.handle
	handle:Lookup("Image_Progress"):Hide()
	handle:Lookup("Image_FlashS"):Show()
	handle:Lookup("Image_FlashF"):Hide()
	return self
end

function _BossOTBar:OTFail()
	local handle=self.handle
	handle:Lookup("Image_Progress"):Hide()
	handle:Lookup("Image_FlashS"):Hide()
	handle:Lookup("Image_FlashF"):Show()
	return self
end

function _BossOTBar:GetAlpha()
	local handle=self.handle
	return handle:GetAlpha()
end

function _BossOTBar:SetAlpha(alpha)
	local handle=self.handle
	handle:SetAlpha(alpha)
	return self
end

---------------------------------------------------------------
function LR_TeamBossMonitor.isBoss(npc)
	if not npc then
		return false
	end
	if GetNpcIntensity(npc) < 3 then
		return false
	end
	local me=GetClientPlayer()
	if not me then
		return false
	end
	local scene=me.GetScene()
	if not scene then
		return false
	end
	local dwMapID=scene.dwMapID
	if not LR.MapType[dwMapID] then
		return false
	end
	local bossList=LR.MapType[dwMapID].bossList
	local szName=LR_TeamBossMonitor.SplitBossName(bossList)
	for k,v in pairs (szName) do
		if v==npc.szName or v==Table_GetNpcTemplateName(npc.dwTemplateID) then
			return true
		end
	end
	return false
end

function LR_TeamBossMonitor.SplitBossName(szName)
	local names={}
	for s in sgfind(sformat("%s,", szName),"(.-),") do
		names[#names+1]=s
	end
	return names
end
-------------------------------
--BOSS¶ÁÌõ¼à¿Ø
-------------------------------
function LR_TeamBossMonitor.CheckOTState(dwID)
	local dwID = dwID
	if not _OTMonitorList[dwID] then
		return
	end
	local v = _OTMonitorList[dwID]
	local nType = v.nType
	local obj = nil
	if nType == TARGET.NPC then
		obj = GetNpc(dwID)
	elseif nType == TARGET.PLAYER then
		obj = GetPlayer(dwID)
	end
	if not obj then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not (IsEnemy(obj.dwID, me.dwID) and obj.bFightState) then
		--return
	end
	local bPrePare,dwSkillID,dwSkillLevel,fP = obj.GetSkillPrepareState()
	local OTBar = _OTBarHandle[dwID]

	if bPrePare and v.nActionState ~= ACTION_STATE.PREPARE then
		if not OTBar then
			local h = _BossOTBar:new(dwID)
			h:Create():SetAlpha(255):SetPercentage(0):SetSkillName(LR.Trim(Table_GetSkillName(dwSkillID, dwSkillLevel))):SetCasterName(LR.Trim(obj.szName)):SetText()
			_OTBarHandle[dwID] = h
		end
		OTBar = _OTBarHandle[dwID]
		v.nActionState = ACTION_STATE.PREPARE
		LR_TeamBossMonitor.ReLoadOTBarPosition()
	elseif not bPrePare and v.nActionState == ACTION_STATE.PREPARE then
		v.nActionState = ACTION_STATE.DONE
		if OTBar then
			OTBar:Remove()
			_OTBarHandle[dwID] = nil
			OTBar = nil
			LR_TeamBossMonitor.ReLoadOTBarPosition()
		end
	end

	if not OTBar then
		return
	end

	if v.nActionState == ACTION_STATE.PREPARE then
		OTBar:SetPercentage(fP)
	elseif v.nActionState == ACTION_STATE.DONE then
		OTBar:OTSucess()
		v.nActionState = ACTION_STATE.FADE
	elseif v.nActionState == ACTION_STATE.BREAK then
		OTBar:OTFail()
		v.nActionState = ACTION_STATE.FADE
	elseif v.nActionState == ACTION_STATE.FADE then
		local nAlpha = OTBar:GetAlpha()
		nAlpha = nAlpha - 10
		if nAlpha > 0 then
			OTBar:SetAlpha(nAlpha)
		else
			v.nActionState = ACTION_STATE.NONE
		end
	else
		OTBar:Remove()
		_OTBarHandle[dwID] = nil
		OTBar = nil
		LR_TeamBossMonitor.ReLoadOTBarPosition()
	end
end

function LR_TeamBossMonitor.ReLoadOTBarPosition()
	local Handle_BossOTBar=LR_TeamGrid.Handle_BossOTBar
	local num=Handle_BossOTBar:GetItemCount()
	local n=1
	for i=1,num,1 do
		local handle=Handle_BossOTBar:Lookup(i-1)
		if handle then
			handle:SetRelPos(0,-(i-1)*25)
		end
	end
	Handle_BossOTBar:FormatAllItemPos()
	local w, h = Handle_BossOTBar:GetAllItemSize()
	Handle_BossOTBar:SetSize(w, h)
	Handle_BossOTBar:GetParent():SetSize(w, h)
end

function LR_TeamBossMonitor.CheckAllOTState()
	--10028ÄÌ»¨ 10080ÄÌÐã 10176ÄÌ¶¾ 10448ÄÌÇÙ
	------Boss¶ÁÌõ¼à¿Ø
	if not GetClientPlayer() then
		return
	end
	if LR_TeamGrid.UsrData.CommonSettings.bShowBossOT then
		if LR_TeamGrid.UsrData.CommonSettings.bShowBossOTOnlyInCure then
			local kungfu=GetClientPlayer().GetKungfuMount()
			local dwSkillID=kungfu.dwSkillID
			if dwSkillID==10028 or dwSkillID==10080 or dwSkillID==10176 or dwSkillID==10448 then
				for dwID, v in pairs (_OTMonitorList) do
					LR_TeamBossMonitor.CheckOTState(dwID)
				end
			end
		else
			for dwID, v in pairs (_OTMonitorList) do
				LR_TeamBossMonitor.CheckOTState(dwID)
			end
		end
	end
end

-------------------------------
--BOSSÄ¿±êÏÔÊ¾
-------------------------------
function LR_TeamBossMonitor.DrawAllBossTarget()
	--10028ÄÌ»¨ 10080ÄÌÐã 10176ÄÌ¶¾ 10448ÄÌÇÙ
	------Boss¶ÁÌõ¼à¿Ø
	if not GetClientPlayer() then
		return
	end
	if LR_TeamGrid.UsrData.CommonSettings.bShowBossTarget or LR_TeamGrid.UsrData.CommonSettings.bShowSmallBossTarget then
		for dwID, v in pairs (_BossList) do
			LR_TeamBossMonitor.ShowBossTargetImage(dwID)
		end
	end
end


function LR_TeamBossMonitor.ShowBossTargetImage(dwID)
	if not (LR_TeamGrid.UsrData.CommonSettings.bShowBossTarget or LR_TeamGrid.UsrData.CommonSettings.bShowSmallBossTarget) then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local v=_BossList[dwID]
	if not v then
		return
	end
	local npc=GetNpc(dwID)
	if not npc then
		local handleRole = LR_TeamGrid.GetRoleHandle(v.OldTarget)
		if handleRole then
			handleRole:DrawBossTargetImage(false):DrawSmallBossTargetImage(false)
		end
		return
	end
	if IsEnemy(npc.dwID,me.dwID) and npc.bFightState then
		local eTargetType,dwTargetID=npc.GetTarget()
		if eTargetType==TARGET.PLAYER and dwTargetID > 0 and me.IsPlayerInMyParty(dwTargetID) then
			if v.OldTarget ~= dwTargetID and me.IsPlayerInMyParty(v.OldTarget) then
				local handleRole = LR_TeamGrid.GetRoleHandle(v.OldTarget)
				if handleRole then
					handleRole:DrawBossTargetImage(false):DrawSmallBossTargetImage(false)
				end
			end

			local handleRole = LR_TeamGrid.GetRoleHandle(dwTargetID)
			if handleRole then
				if LR_TeamGrid.UsrData.CommonSettings.bShowBossTarget and v.isBoss then
					handleRole:DrawBossTargetImage(true):DrawSmallBossTargetImage(true)
				else
					handleRole:DrawBossTargetImage(false):DrawSmallBossTargetImage(true)
				end
--[[				if RaidGridEx.ShowEliteTarget  and GetNpcIntensity(npc)==3 then
					handleRole:Lookup("Image_Target2"):Show()
				end]]
			end
			v.OldTarget=dwTargetID
		else
			if v.OldTarget>0 and me.IsPlayerInMyParty(v.OldTarget) then
				local handleRole = LR_TeamGrid.GetRoleHandle(v.OldTarget)
				if handleRole then
					handleRole:DrawBossTargetImage(false):DrawSmallBossTargetImage(false)
				end
				v.OldTarget=0
			end
		end
	else
		if v.OldTarget>0 and me.IsPlayerInMyParty(v.OldTarget) then
			local handleRole = LR_TeamGrid.GetRoleHandle(v.OldTarget)
			if handleRole then
				handleRole:DrawBossTargetImage(false):DrawSmallBossTargetImage(false)
			end
			v.OldTarget=0
		end
	end
end

-------------------------------------------------------------
function LR_TeamBossMonitor.NPC_ENTER_SCENE()
	local dwID=arg0
	local npc=GetNpc(dwID)
	if not npc then
		return
	end
	local scene=npc.GetScene()
	if not scene then
		return
	end
	if scene.nType ~= MAP_TYPE.DUNGEON then
		return
	end
	if LR.Trim(npc.szName)=="" then
		return
	end
	if LR_TeamBossMonitor.isBoss(npc) then
		_BossList[dwID] = {dwID = dwID, OldTarget = 0, isBoss=true,}
		_OTMonitorList[dwID] = {nType = TARGET.NPC, nActionState = ACTION_STATE.NONE,}
	else
		if GetNpcIntensity(npc) == 3 then
			_BossList[dwID] = {dwID = dwID, OldTarget = 0, isBoss = false,}
		elseif GetNpcIntensity(npc) == 4 then
			_BossList[dwID] = {dwID = dwID, OldTarget = 0, isBoss = false,}
			_OTMonitorList[dwID] = {nType = TARGET.NPC, nActionState = ACTION_STATE.NONE,}
		end
	end
end

function LR_TeamBossMonitor.NPC_LEAVE_SCENE()
	local dwID=arg0
	if _BossList[dwID] then
		local v = clone(_BossList[dwID])
		local handleRole = LR_TeamGrid.GetRoleHandle(v.OldTarget)
		if handleRole then
			LR.DelayCall(100, function()
				handleRole:DrawBossTargetImage(false):DrawSmallBossTargetImage(false)
			end)
		end
	end
	_BossList[dwID] = nil
	if _OTMonitorList[dwID] then
		local OTBar=_OTBarHandle[dwID]
		if OTBar then
			OTBar:Remove()
			_OTMonitorList[dwID] = nil
			LR_TeamBossMonitor.ReLoadOTBarPosition()
		end
		_OTMonitorList[dwID] = nil
	end
end

LR.RegisterEvent("NPC_ENTER_SCENE", function() LR_TeamBossMonitor.NPC_ENTER_SCENE() end)
LR.RegisterEvent("NPC_LEAVE_SCENE", function() LR_TeamBossMonitor.NPC_LEAVE_SCENE() end)
