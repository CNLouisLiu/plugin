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
local _TALK_FOCUS = {}
local _C = {}
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
		local szIniFile = sformat("%s\\UI\\BossOTBar.ini", AddonPath)
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
--NPC¶ÁÌõ¸´ÖÆ
-------------------------------
function LR_TeamBossMonitor.CheckOTState2()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local _nType, _dwID = me.GetTarget()
	local OTBar = _OTBarHandle[1]
	if not (_nType == TARGET.NPC or _nType == TARGET.PLAYER) then
		if OTBar then
			OTBar:Remove()
			_OTBarHandle[1] = nil
			OTBar = nil
			LR_TeamBossMonitor.ReLoadOTBarPosition()
		end
		return
	end
	local path = ""
	if _nType == TARGET.NPC then
		path = "Normal/Target"
	else
		local player = GetPlayer(_dwID)
		if player then
			_nType, _dwID = player.GetTarget()
			if _nType == TARGET.NPC then
				path = "Normal/TargetTarget"
			else
				if OTBar then
					OTBar:Remove()
					_OTBarHandle[1] = nil
					OTBar = nil
					LR_TeamBossMonitor.ReLoadOTBarPosition()
				end
				return
			end
		end
	end
	local frame = Station.Lookup(path)
	if not frame then
		return
	end
	local Handle_Target = frame:Lookup("","")
	local Handle_Bar = Handle_Target:Lookup("Handle_Bar")
	if not Handle_Bar:IsVisible() then
		if OTBar then
			OTBar:Remove()
			_OTBarHandle[1] = nil
			OTBar = nil
			LR_TeamBossMonitor.ReLoadOTBarPosition()
		end
		return
	end
	local Image_Progress = Handle_Bar:Lookup("Image_Progress") or Handle_Bar:Lookup("Image_BarProgress")
	local Image_FlashF = Handle_Bar:Lookup("Image_FlashF")
	local Image_FlashS = Handle_Bar:Lookup("Image_FlashS")
	local Text_Name = Handle_Bar:Lookup("Text_Name")
	local fp = Image_Progress:GetPercentage()
	if not OTBar then
		local h = _BossOTBar:new(1)
		h:Create():SetAlpha(255):SetPercentage(0):SetSkillName(Text_Name:GetText()):SetText():SetCasterName(Handle_Target:Lookup("Text_Target"):GetText())
		_OTBarHandle[1] = h
		OTBar = h
	end
	if Image_FlashF:IsVisible() then
		OTBar:OTFail()
	elseif Image_FlashS:IsVisible() then
		OTBar:OTSucess()
	else
		OTBar:SetPercentage(fp)
	end
	OTBar:SetAlpha(Handle_Bar:GetAlpha())
	LR_TeamBossMonitor.ReLoadOTBarPosition()
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
			if LR.IsNurse() then
				LR_TeamBossMonitor.CheckOTState2()
			end
		else
			LR_TeamBossMonitor.CheckOTState2()
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
function _C.LoadData()
	local _, _, szLang = GetVersion()
	local path = sformat("%s\\DefaultData\\TalkFocusMon_%s", AddonPath, szLang)
	local data = LoadLUAData(path) or {}
	for k, v in pairs(data) do
		v.szText = sgsub(v.szText, "$name", "(.+)")
	end
	_TALK_FOCUS = clone(data)
end

function _C.PLAYER_SAY()
	local szContent = arg0
	local dwID = arg1
	local nChannel = arg2
	if IsPlayer(dwID) and dwID ~= 0 then
		return
	end
	if not (nChannel == PLAYER_TALK_CHANNEL.NPC_NEARBY or nChannel == PLAYER_TALK_CHANNEL.NPC_SENCE or nChannel == PLAYER_TALK_CHANNEL.MSG_NPC_YELL) then
		return
	end
	local szText = GetPureText(szContent)
	local szName, data = LR_TeamTools.DeathRecord.GetName(TARGET.NPC, dwID)
	if not data or next(data) == nil then
		return
	end
	for k, v in pairs(_TALK_FOCUS) do
		if v.dwTemplateID == data.dwTemplateID then
			if v .nType == 1 then
				local _s, _e, name = sfind(szText, v.szText)
				if _s then
					FireEvent("LR_TEAM_TALK_FOCUS", true, name)
					LR.DelayCall(8000, function() FireEvent("LR_TEAM_TALK_FOCUS", false, name) end)
				end
			elseif v.nType == 2 then
				local _s, _e, name = sfind(szText, v.szText)
				if _s then
					local npc = GetNpc(dwID)
					local _type, _dwID = npc.GetTarget()
					if _type == TARGET.PLAYER then
						local player = GetPlayer(_dwID)
						if player then
							local name = player.szName
							FireEvent("LR_TEAM_TALK_FOCUS", true, name)
							LR.DelayCall(8000, function() FireEvent("LR_TEAM_TALK_FOCUS", false, name) end)
						end
					end
				end
			end
		end
	end
end

function _C.FIRST_LOADING_END()
	_C.LoadData()
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
	local dwID = arg0
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

LR_TeamBossMonitor.PLAYER_SAY = _C.PLAYER_SAY

LR.RegisterEvent("NPC_ENTER_SCENE", function() LR_TeamBossMonitor.NPC_ENTER_SCENE() end)
LR.RegisterEvent("NPC_LEAVE_SCENE", function() LR_TeamBossMonitor.NPC_LEAVE_SCENE() end)
LR.RegisterEvent("FIRST_LOADING_END", function() _C.FIRST_LOADING_END() end)
