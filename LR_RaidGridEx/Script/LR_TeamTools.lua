local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_RaidGridEx"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_TeamGrid"
local _L = LR.LoadLangPack(AddonPath)
------------------------------------
LR_TeamTools = {}

-----------------------------------------------------------
---DPS显示（需铭伊插件支持）
-----------------------------------------------------------
LR_TeamTools.DPS = {
	Record = {},
	FightUIID = 0,
}

function LR_TeamTools.DPS.FIGHT_HINT()
	if MY_Recount ==  nil or MY_Recount ==  {} then
		--LR.SysMsg("需安装【茗伊插件集】-【伤害统计】\n")
		return
	end
	local DPS_ALL = MY_Recount.Data.Get()
	if not DPS_ALL then
		return
	end
	local DPS_Last = DPS_ALL[1]
	if not DPS_Last then
		return
	end
	if FightUIID ==  DPS_Last["UUID"] then
		return
	else
		FightUIID = DPS_Last["UUID"]
	end
	local nTimeBegin = DPS_Last["nTimeBegin"]
	local nTimeDuring = DPS_Last["nTimeDuring"]
	local szBossName = DPS_Last["szBossName"]
	local Damage = DPS_Last["Damage"]
	--Output(Damage)
	for k, v in pairs (Damage) do
		local dwID = k
		if type(v) == "table" then
			local nTotalEffect = v["nTotalEffect"]
			if LR_TeamTools.DPS.Record[k] ==  nil then
				LR_TeamTools.DPS.Record[k] = {{FightUIID = FightUIID,nTimeBegin = nTimeBegin,nTimeDuring = nTimeDuring,szBossName = szBossName,DPS = {nTotalEffect = nTotalEffect},}}
			else
				local t = {{FightUIID = FightUIID,nTimeBegin = nTimeBegin,nTimeDuring = nTimeDuring,szBossName = szBossName,DPS = {nTotalEffect = nTotalEffect},}}
				for i = 1,#LR_TeamTools.DPS.Record[k] do
					tinsert(t,LR_TeamTools.DPS.Record[k][i])
				end
				LR_TeamTools.DPS.Record[k] = t
				--tinsert (LR_TeamTools.DPS.Record[k],{FightUIID = FightUIID,nTimeBegin = nTimeBegin,nTimeDuring = nTimeDuring,szBossName = szBossName,DPS = {nTotalEffect = nTotalEffect,},})
			end
		end
	end
	local Heal = DPS_Last["Heal"]
	for k,v in pairs (Heal) do
		if type(v) == "table" then
			local dwID = k
			local nTotalEffect = v["nTotalEffect"]
			if LR_TeamTools.DPS.Record[k] ==  nil then
				LR_TeamTools.DPS.Record[k] = {{FightUIID = FightUIID,nTimeBegin = nTimeBegin,nTimeDuring = nTimeDuring,szBossName = szBossName,HPS = {nTotalEffect = nTotalEffect,},}}
			elseif LR_TeamTools.DPS.Record[k][1]["FightUIID"] ~=  FightUIID then
				local t = {{FightUIID = FightUIID,nTimeBegin = nTimeBegin,nTimeDuring = nTimeDuring,szBossName = szBossName,HPS = {nTotalEffect = nTotalEffect},}}
				for i = 1,#LR_TeamTools.DPS.Record[k] do
					tinsert(t,LR_TeamTools.DPS.Record[k][i])
				end
				LR_TeamTools.DPS.Record[k] = t
				--tinsert (LR_TeamTools.DPS.Record[k],{FightUIID = FightUIID,nTimeBegin = nTimeBegin,nTimeDuring = nTimeDuring,szBossName = szBossName,HPS = {nTotalEffect = nTotalEffect,},})
			else
				LR_TeamTools.DPS.Record[k][1]["HPS"] = {nTotalEffect = nTotalEffect,}
			end
		end
	end
end

function LR_TeamTools.DPS.OutputDPSRecord(dwID,rc)
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
	szTip[#szTip+1] = GetFormatText(sformat("%s\n", _L["-----DPS（HPS）Record-----"]),17)
	if LR_TeamTools.DPS.Record[dwID] ==  nil then
		szTip[#szTip+1] = sformat("%s\n", _L["No Record"])
	else
		for i = 1,#LR_TeamTools.DPS.Record[dwID] do
			local date = TimeToDate(LR_TeamTools.DPS.Record[dwID][i]["nTimeBegin"])
			local weekday =  sformat("%02d",date["weekday"])
			local hour = sformat("%02d",date["hour"])
			local minute = sformat("%02d",date["minute"])
			local second = sformat("%02d",date["second"])
			local szBossName = LR_TeamTools.DPS.Record[dwID][i]["szBossName"]
			local DPS , HPS = 0,0
			local t_text =  ""
			if LR_TeamTools.DPS.Record[dwID][i]["DPS"]~= nil and LR_TeamTools.DPS.Record[dwID][i]["HPS"] ~= nil then
				DPS =  sformat("%6d %4s",LR_TeamTools.DPS.Record[dwID][i]["DPS"]["nTotalEffect"] / LR_TeamTools.DPS.Record[dwID][i]["nTimeDuring"],"DPS")
				HPS =  sformat("%6d %4s",LR_TeamTools.DPS.Record[dwID][i]["HPS"]["nTotalEffect"] / LR_TeamTools.DPS.Record[dwID][i]["nTimeDuring"],"HPS")
				t_text = sformat("%s / %s", DPS, HPS)
			elseif LR_TeamTools.DPS.Record[dwID][i]["HPS"]~= nil then
				HPS =  sformat("%6d %4s",LR_TeamTools.DPS.Record[dwID][i]["HPS"]["nTotalEffect"] / LR_TeamTools.DPS.Record[dwID][i]["nTimeDuring"],"HPS")
				t_text = HPS
			else
				DPS =  sformat("%6d %4s",LR_TeamTools.DPS.Record[dwID][i]["DPS"]["nTotalEffect"] / LR_TeamTools.DPS.Record[dwID][i]["nTimeDuring"],"DPS")
				t_text = DPS
			end
			szTip[#szTip+1] = GetFormatText(sformat("(%s:%s:%s)%s:%s\n", hour, minute, second, szBossName, t_text), 27)
		end
	end
	OutputTip(tconcat(szTip), 420, rc)
end


--------------------------------------------------------------------------------------------------------------------
-----------重伤记录
--------------------------------------------------------------------------------------------------------------------
LR_TeamTools.DeathRecord = {
	tDamage = {},
	tDeath = {}
}
local NPC_Cache = {}
local Player_Cache = {
	[0] = {szName = "PLAYER#0", dwMapID = 0, nType = TARGET.PLAYER, obj = nil}
}

function LR_TeamTools.DeathRecord.NPC_ENTER_SCENE()
	local dwID = arg0
	local npc = GetNpc(dwID)
	if not NPC_Cache[dwID] then
		if npc then
			local szName = LR.Trim(npc.szName)
			if szName ==  "" then
				szName = LR.Trim(Table_GetNpcTemplateName(npc.dwTemplateID))
			end
			if szName ==  "" then
				szName = sformat("NPC#%d", npc.dwTemplateID)
			end
			local scene = npc.GetScene()
			local bPet = false
			if npc.dwEmployer > 0 and IsPlayer(npc.dwEmployer) then
				bPet = true
			end
			local nIntensity = GetNpcIntensity(npc)
			NPC_Cache[npc.dwID] = {szName = szName, nIntensity = nIntensity, bPet = bPet, dwTemplateID = npc.dwTemplateID, dwMapID = scene.dwMapID, nType = TARGET.NPC, obj = npc, nX = npc.nX, nY = npc.nY, nZ = npc.nZ}
		end
	else
		if npc then
			NPC_Cache[dwID].obj = npc
		end
	end
end

function LR_TeamTools.DeathRecord.NPC_LEAVE_SCENE()
	local dwID = arg0
	if NPC_Cache[dwID] then
		NPC_Cache[dwID].obj = nil
	end
end

function LR_TeamTools.DeathRecord.PLAYER_ENTER_SCENE()
	local dwID = arg0
	local player = GetPlayer(dwID)
	if not Player_Cache[dwID] then
		if player then
			Player_Cache[dwID] = {szName = player.szName, nType = TARGET.PLAYER, obj = player, dwForceID = player.dwForceID}
		end
	else
		if player then
			Player_Cache[dwID].obj = player
		end
	end
end

function LR_TeamTools.DeathRecord.PLAYER_LEAVE_SCENE()
	local dwID = arg0
	if Player_Cache[dwID] then
		Player_Cache[dwID].obj = nil
	end
end

function LR_TeamTools.DeathRecord.GetNearestNPC()
	local npcs = {}
	local me = GetClientPlayer()
	if not me then
		return
	end
	for k, v in pairs(NPC_Cache) do
		if v.obj and not v.bPet and IsEnemy(k, me.dwID) then
			tinsert(npcs, {szName = v.szName, nIntensity = v.nIntensity, dwTemplateID = v.dwTemplateID, distance = LR.GetDistance(v.obj)})
		end
	end
	if next(npcs) == nil then
		return {szName = "#NoNPC", nIntensity = 0, dwTemplateID = 0, distance = 0}
	else
		tsort(npcs, function(a, b)
			if a.nIntensity == b.nIntensity then
				return a.distance < b.distance
			else
				return a.nIntensity > b.nIntensity
			end
		end)
		return npcs[1]
	end
end

function LR_TeamTools.DeathRecord.GetName(nType, dwID)
	local szKillerName = ""
	if nType ==  TARGET.NPC then
		if NPC_Cache[dwID] then
			szKillerName = NPC_Cache[dwID].szName
		else
			szKillerName = sformat("NPC?#%d", dwID)
		end
		return szKillerName, NPC_Cache[dwID]
	elseif nType ==  TARGET.PLAYER then
		if Player_Cache[dwID] then
			szKillerName = Player_Cache[dwID].szName
		else
			szKillerName = sformat("PLAYER?#%d", dwID)
		end
		return szKillerName, Player_Cache[dwID]
	end
	return szKillerName
end

function LR_TeamTools.DeathRecord.OnSkillEffectLog(dwCaster, dwTarget, bReact, nEffectType, dwID, dwLevel, bCriticalStrike, nCount, tResult)
	if nCount <=  2 then			--无效数据
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not IsPlayer(dwTarget) or not me.IsPlayerInMyParty(dwTarget) then
		return
	end
	----ss
	local nCasterType = TARGET.NPC
	--伤害源
	if IsPlayer(dwCaster) then
		nCasterType = TARGET.PLAYER
	end
	--技能名字
	local szSkillName = ""
	if nEffectType ==  SKILL_EFFECT_TYPE.SKILL then
		szSkillName = Table_GetSkillName(dwID, dwLevel)
	elseif nEffectType ==  SKILL_EFFECT_TYPE.BUFF then
		szSkillName = Table_GetBuffName(dwID, dwLevel)
	end
	if not szSkillName then
		return
	end
	----依次为外功、阳性、阴性、混元性、毒性
	local DAMAGE_TYPE = {"PHYSICS_DAMAGE", "SOLAR_MAGIC_DAMAGE", "LUNAR_MAGIC_DAMAGE", "NEUTRAL_MAGIC_DAMAGE", "POISON_DAMAGE"}
	local DAMAGE_STRING = {"STR_SKILL_PHYSICS_DAMAGE", "STR_SKILL_SOLAR_MAGIC_DAMAGE", "STR_SKILL_LUNAR_MAGIC_DAMAGE", "STR_SKILL_NEUTRAL_MAGIC_DAMAGE", "STR_SKILL_POISON_DAMAGE"}
	local szDamage = ""
	local nTotalDamage = 0
	for k, v in pairs(DAMAGE_TYPE) do
		local nValue = tResult[SKILL_RESULT_TYPE[v]]
		if nValue and nValue > 0 then
			if szDamage ~=  "" then
				szDamage = sformat("%s%s", szDamage, g_tStrings.STR_COMMA)
			end
			szDamage = sformat("%s%s", szDamage, FormatString(g_tStrings.SKILL_DAMAGE, nValue, g_tStrings[DAMAGE_STRING[k]]))
			nTotalDamage = nTotalDamage + nValue
		end
	end

	if szDamage ~=  "" then
		--Output(tResult, szDamage)
		local nEffectDamage = tResult[SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE] or 0
		local data = {}
		data.dwCasterID = dwCaster
		data.nCasterType = nCasterType
		data.dwTargetID = dwTarget
		data.szDamage = szDamage
		data.szSkillName = szSkillName
		data.nEffectDamage = nEffectDamage
		data.nTotalDamage = nTotalDamage
		data.bCriticalStrike = bCriticalStrike
		data.nTime = GetCurrentTime()
		LR_TeamTools.DeathRecord.tDamage[dwTarget] = LR_TeamTools.DeathRecord.tDamage[dwTarget] or {}
		tinsert(LR_TeamTools.DeathRecord.tDamage[dwTarget], data)
	end
end

function LR_TeamTools.DeathRecord.OnCommonHealthLog(dwTarget, nDeltaLife)
	local target
	if IsPlayer(dwTarget) then
		target = GetPlayer(dwTarget)
	else
		return
	end
	if not target then
		return
	end
	if nDeltaLife < 0 then
		nDeltaLife = -nDeltaLife
	end
	local me = GetClientPlayer()
	local team = GetClientTeam()
	if me.IsPlayerInMyParty(dwTarget) or dwTarget ==  me.dwID then
		if not LR_TeamTools.DeathRecord.tDamage[dwTarget] then
			LR_TeamTools.DeathRecord.tDamage[dwTarget] = {}
		end
		tinsert(LR_TeamTools.DeathRecord.tDamage[dwTarget],{
			szCaster  = _L["Extraterrestrials"],
			szTarget = LR.GetTemplateName(target),
			szSkillName = _L["Fly up"],
			szValue = sformat("%d%s", nDeltaLife, _L["point damage"])
		})
	end
end

--[[
	arg0:"UI_OME_DEATH_NOTIFY" arg1:dwCharacterID arg2: 为INT_MAX，2147483647 arg3:szKiller
	arg0:"UI_OME_SKILL_EFFECT_LOG" arg1:dwCaster arg2:dwTarget arg3:bReact arg4:nType  arg5:dwID  arg6:dwLevel  arg7:bCriticalStrike arg8:nResultCount
	arg0:"UI_OME_COMMON_HEALTH_LOG" arg1:dwCharacterID arg2:nDeltaLife]]

function LR_TeamTools.DeathRecord.OnDeath(dwTarget, dwCaster)
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not (IsPlayer(dwTarget) and me.IsPlayerInMyParty(dwTarget)) then
		return
	end

	LR_TeamTools.DeathRecord.tDeath[dwTarget] = LR_TeamTools.DeathRecord.tDeath[dwTarget] or {}
	local data = {}
	if IsPlayer(dwCaster) then
		data.nKillerType = TARGET.PLAYER
	else
		data.nKillerType = TARGET.NPC
	end
	data.dwID = dwCaster
	data.nTime = GetCurrentTime()
	data.last10Damage = {}
	local tDamage = LR_TeamTools.DeathRecord.tDamage[dwTarget] or {}
	for i = #tDamage, mmax(1, #tDamage - 10), -1 do
		data.last10Damage[#data.last10Damage + 1] = clone(tDamage[i])
	end
	tinsert(LR_TeamTools.DeathRecord.tDeath[dwTarget], data)
	if #LR_TeamTools.DeathRecord.tDeath[dwTarget] > 6 then
		tremove(LR_TeamTools.DeathRecord.tDeath[dwTarget],1)
	end
end

function LR_TeamTools.DeathRecord.OutputDeathRecord(dwID, rc)
	local hTeam = GetClientTeam()
	local v = hTeam.GetMemberInfo(dwID)
	if not v then
		return
	end
	local szIcon, nFrame = GetForceImage(v.dwForceID)
	local r, g, b =  LR.GetMenPaiColor(v.dwForceID)
	local szXml = {}
	szXml[#szXml+1] = GetFormatImage(szIcon, nFrame, 26, 26)
	szXml[#szXml+1] = GetFormatText(sformat("%s:\n", v.szName),136,r,g,b)
	szXml[#szXml+1] = GetFormatText(sformat("%s\n", _L["--Dead Record--"]), 136, 255, 255, 255)
	if not LR_TeamTools.DeathRecord.tDeath[dwID] or #LR_TeamTools.DeathRecord.tDeath[dwID] ==  0 then
		szXml[#szXml+1] = GetFormatText(sformat("%s\n", _L["No Record"]), 136, 255, 255, 0)
	else
		for i = #LR_TeamTools.DeathRecord.tDeath[dwID] , 1 , -1 do
			local a = LR_TeamTools.DeathRecord.tDeath[dwID][i]
			szXml[#szXml+1] = GetFormatText(sformat("%s ", FormatTime("%Y-%m-%d %H:%M:%S", a.nTime)), 136, 255, 255, 0)
			local szKillerName = LR_TeamTools.DeathRecord.GetName(a.nKillerType, a.dwID)
			szXml[#szXml+1] = GetFormatText(sformat(_L["%s killed %s\n"], szKillerName, v.szName ),136,255,128,0)
			for k2, v2 in pairs(a.last10Damage) do
				szXml[#szXml+1] = GetFormatText("-> ",136,255,128,0)
				szXml[#szXml+1] = GetFormatText(sformat("%s ", FormatTime("%Y-%m-%d %H:%M:%S", v2.nTime)), 136, 255, 255, 0)
				local szMsg = ""
				local szCasterName = LR_TeamTools.DeathRecord.GetName(v2.nCasterType, v2.dwCasterID)
				local szTargetName = LR_TeamTools.DeathRecord.GetName(TARGET.PLAYER, v2.dwTargetID)
				local szCriticalStrike = ""
				if v2.bCriticalStrike then
					szCriticalStrike = g_tStrings.STR_SKILL_CRITICALSTRIKE
				end
--[[				if v2.nTotalDamage ==  v2.nEffectDamage then
					szMsg = FormatString("<D0> 的 [<D1>] <D2> 对 [<D3>] 造成了 <D4>", szCasterName, v2.szSkillName, szCriticalStrike, szTargetName, v2.szDamage)
				else
					szMsg = FormatString(g_tStrings.SKILL_EFFECT_DAMAGE_LOG, szCasterName, v2.szSkillName, szCriticalStrike, szTargetName, v2.szDamage, v2.nEffectDamage)
				end]]
				--szXml[#szXml+1] = GetFormatText(szMsg, 136, 255, 128, 0)
				szXml[#szXml+1] = GetFormatText(szCasterName, 136, 255, 128, 0)
				szXml[#szXml+1] = GetFormatText(" <", 136, 255, 255, 0)
				szXml[#szXml+1] = GetFormatText(v2.szSkillName, 136, 255, 128, 0)
				szXml[#szXml+1] = GetFormatText("> ", 136, 255, 255, 0)
				szXml[#szXml+1] = GetFormatText(szCriticalStrike, 136, 255, 0, 0)
				szXml[#szXml+1] = GetFormatText(_L["Cause"], 136, 255, 255, 0)
				szXml[#szXml+1] = GetFormatText(v2.szDamage, 136, 255, 128, 0)
				if v2.nTotalDamage ~=  v2.nEffectDamage then
					szXml[#szXml+1] = GetFormatText(sformat(_L[", effect damage %d point"], v2.nEffectDamage), 136, 255, 128, 0)
				end
				szXml[#szXml+1] = GetFormatText(sformat("\n"), 136, 255, 128, 0)
			end
			szXml[#szXml+1] = GetFormatText("\n",136,255,128,0)
		end
	end
	OutputTip(tconcat(szXml), 800, rc)
end

LR.RegisterEvent("NPC_ENTER_SCENE", function() LR_TeamTools.DeathRecord.NPC_ENTER_SCENE() end)
LR.RegisterEvent("NPC_LEAVE_SCENE", function() LR_TeamTools.DeathRecord.NPC_LEAVE_SCENE() end)
LR.RegisterEvent("PLAYER_ENTER_SCENE", function() LR_TeamTools.DeathRecord.PLAYER_ENTER_SCENE() end)
LR.RegisterEvent("PLAYER_LEAVE_SCENE", function() LR_TeamTools.DeathRecord.PLAYER_LEAVE_SCENE() end)

--------------------------------------------------------------------------------------------------------------------
-----------门派人数
--------------------------------------------------------------------------------------------------------------------
LR_TeamTools.Menpai = {
	Count = {}
}
function LR_TeamTools.Menpai.CheckMenpai ()
	local player =  GetClientPlayer()
	if not player then return end
	local team = GetClientTeam()
	if not team then return end
	local team_ids = team.GetTeamMemberList()

	--0大侠，1少林，2万花，3天策，4纯阳，5七秀，6五毒，7唐门，8藏剑，9丐帮，10明教，21苍云，22长歌门，23霸刀，24蓬莱
	for k, v in pairs(ALL_KUNGFU_COLLECT) do
		LR_TeamTools.Menpai.Count[v] = 0
	end

	for i = 1, #team_ids, 1 do
		local memberinfo =  team.GetMemberInfo(team_ids[i])
		if memberinfo then
			LR_TeamTools.Menpai.Count[memberinfo.dwForceID] = (LR_TeamTools.Menpai.Count[memberinfo.dwForceID] or 0) + 1
		end
	end
end

function LR_TeamTools.Menpai.OutputData()
	LR_TeamTools.Menpai.CheckMenpai ()
	local szText = {}
	szText[#szText+1] = {szText = _L["LR_MenPai Count:\n"]}
	szText[#szText+1] = {szText = "----------"}
	local dwForceID = ALL_KUNGFU_COLLECT
	--g_tStrings.tForceTitle[dwForceID]
	--local szForceName = {_L["ShaoLin"],_L["WanHua"],_L["TianCe"],_L["ChunYang"],_L["QiXiu"],_L["WuDu"],_L["TangMen"],_L["CangJian"],_L["GaiBang"],_L["MingJiao"],_L["CangYun"],_L["ChangGeMen"],_L["BaDao"],_L["DaXia"],}
	for k, v in pairs(dwForceID) do
		if g_tStrings.tForceTitle[v] then
			szText[#szText+1] = {szText = sformat("【%s】：%d\n", g_tStrings.tForceTitle[v], LR_TeamTools.Menpai.Count[v] or 0)}
		end
	end
	szText[#szText+1] = {szText = "----------"}
	for k, v in pairs(szText) do
		LR.Talk(PLAYER_TALK_CHANNEL.RAID, v.szText)
	end
end

--------------------------------------------------------------------------------------------------------------------
-----------分配提醒
--------------------------------------------------------------------------------------------------------------------
LR_TeamTools.DistributeAttention = {}

function LR_TeamTools.DistributeAttention.FIGHT_HINT()
	local bFight = arg0
	local frame = Station.Lookup("Normal/LR_TeamGrid")
	local me = GetClientPlayer()
	if not bFight or not frame or not me then
		return
	end
	if not LR_TeamGrid.UsrData.CommonSettings.bShowDistributeWarn then
		return
	end
	local scene = me.GetScene()
	local szLootMode = {_L["Free Pick"], _L["Distributor"], _L["Team Pick"], _L["Gold Team"]}
	if scene.nType ==  MAP_TYPE.DUNGEON then
		if me.IsInParty() or me.IsInRaid() then
			local team = GetClientTeam()
			if me.IsInRaid() then
				if team.nLootMode ~=  2 then
					LR_TeamGrid.SetTitleText(sformat(_L["Warning: You are in [%s] loot mode"], szLootMode[team.nLootMode]))
					FireEvent("LR_TEAMGRID_FLASH_TITLE", true)
					--LR.SysMsg(sformat(_L["Warning: You are in [%s] loot mode"] .. "\n", szLootMode[team.nLootMode]))
					LR.DelayCall(12000, function() LR_TeamGrid.SetTitleText(""); FireEvent("LR_TEAMGRID_FLASH_TITLE", false) end)
				end
			else
				if team.nLootMode ~=  3 then
					LR_TeamGrid.SetTitleText(sformat(_L["Warning: You are in [%s] loot mode"], szLootMode[team.nLootMode]))
					FireEvent("LR_TEAMGRID_FLASH_TITLE", true)
					--LR.SysMsg(sformat(_L["Warning: You are in [%s] loot mode"] .. "\n", szLootMode[team.nLootMode]))
					LR.DelayCall(12000,function() LR_TeamGrid.SetTitleText(""); FireEvent("LR_TEAMGRID_FLASH_TITLE", false) end)
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------------------
-----------Hack系统团队面板
--------------------------------------------------------------------------------------------------------------------
--[[LR_TeamTools.HackSystemTeamPanel = {}
function LR_TeamTools.HackSystemTeamPanel.ON_FRAME_CREATE()
	local frame = arg0
	if frame:GetName() ==  "RaidPanel_Main" then
		--Output("sdf")
		LR.DelayCall(500, function()
			local Wnd_Tabs = frame:Lookup("Wnd_Tabs")
			--if Wnd_Tabs then Output("1") end
			local Wnd_Btn = Wnd_Tabs:Lookup("Wnd_Btn")
			--if Wnd_Btn then Output("2") end
			local LR_TeamGrid_Button = LR.AppendUI("Image", Wnd_Btn, "LR_TeamGrid", {x = 6, y = 270, w = 24, h = 24})
			LR_TeamGrid_Button:FromIconID(8)
			LR_TeamGrid_Button:Show()
			LR_TeamGrid_Button:SetAlpha(255)
			Wnd_Btn:SetSize(29, 300)
			Wnd_Tabs:SetSize(39, 300)
			LR_TeamGrid_Button:SetRelPos(6, 270)
			if LR_TeamGrid_Button then
				--Output("ererer")
			end
		end)
	end
end

LR.RegisterEvent("ON_FRAME_CREATE", function() LR_TeamTools.HackSystemTeamPanel.ON_FRAME_CREATE() end)]]


--------------------------------------------------------------------------------------------------------------------
----------边角指示器
--------------------------------------------------------------------------------------------------------------------
--LR_EdgeIndicator_Panel = {}
LR_EdgeIndicator_Panel = _G2.CreateAddon("LR_EdgeIndicator_Panel")
LR_EdgeIndicator_Panel.Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0}
function LR_EdgeIndicator_Panel.OnFrameCreate()
	this:Lookup("",""):Lookup("Text_Title"):SetText(_L["Edge Indicator"])
	this:RegisterEvent("UI_SCALED")

	LR_EdgeIndicator_Panel.UpdateAnchor(this)

	RegisterGlobalEsc("LR_EdgeIndicator_Panel", function () return true end , function() LR_EdgeIndicator_Panel.OpenFrame() end)
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

function LR_EdgeIndicator_Panel.OnFrameDestroy()
	UnRegisterGlobalEsc("LR_EdgeIndicator_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_EdgeIndicator_Panel.OnEvent(szEvent)
	if szEvent ==  "UI_SCALED" then
		LR_EdgeIndicator_Panel.UpdateAnchor(this)
	end
end

function LR_EdgeIndicator_Panel.UpdateAnchor(frame)
	frame:SetPoint(LR_EdgeIndicator_Panel.Anchor.s, 0, 0, LR_EdgeIndicator_Panel.Anchor.r, LR_EdgeIndicator_Panel.Anchor.x, LR_EdgeIndicator_Panel.Anchor.y)
	frame:CorrectPos()
end

function LR_EdgeIndicator_Panel.OnLButtonClick()
	local szName = this:GetName()
	if szName ==  "Btn_Close" then
		Wnd.CloseWindow("LR_EdgeIndicator_Panel")
	end
end

function LR_EdgeIndicator_Panel:Init()
	local frame = self:Append("Frame", "LR_EdgeIndicator_Panel", {path = sformat("%s/UI/LR_EdgeIndicatorPanel.ini", AddonPath)})

	local Handle_Total = frame:Lookup("","")
	local imgTab = LR.AppendUI("Image", Handle_Total, "TabImg", {w = 354,h = 33,x = 3, y = 40})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex",46)
	imgTab:SetImageType(11)

	local hPageSet = LR.AppendUI("PageSet", frame, "PageSet", {x = 0, y = 40, w = 360, h = 130})
	local szKey = {"TopLeft", "TopRight", "BottomLeft", "BottomRight"}
	for k, v in pairs(szKey) do
		local Btn = LR.AppendUI("UICheckBox", hPageSet, sformat("Btn_%s", v), {x = 20 + (k - 1) * 80, y = 0, w = 80, h = 30, text = _L[v], group = "EdgeIndicator"})
		local Window = self:Append("Window", hPageSet, sformat("Window_%s", v), {x = 0, y = 30, w = 360, h = 100})
		hPageSet:AddPage(Window:GetSelf(), Btn:GetSelf())
		Btn.OnCheck = function(bCheck)
			if bCheck then
				hPageSet:ActivePage(k - 1)
			end
		end
	end

	for k, v in pairs(szKey) do
		local Window = self:Fetch(sformat("Window_%s", v))
		local Text_Style = LR.AppendUI("Text", Window, "Text_Style", {x = 20, y = 10, text = _L["Style"]})
		Text_Style:SetFontScheme(8)

		local szStyleOption = {"ColorBlock", "Disable"}
		local vStyleOption = {1, 0}
		for k2, v2 in pairs(szStyleOption) do
			local RadioBox = self:Append("RadioBox", Window, sformat("RadioBox_%s_%s", v, k2), {w = 100, x = 65 + (k2 - 1) * 60, y = 10, text = _L[v2], group = sformat("Style_%s", v)})
			RadioBox:Check(LR_TeamEdgeIndicator.UsrData[v].style ==  vStyleOption[k2])
			RadioBox.OnCheck = function(arg0)
				if arg0 then
					LR_TeamEdgeIndicator.UsrData[v].style = vStyleOption[k2]
					self:Fetch(sformat("Edit_Buff_%s", v)):Enable(LR_TeamEdgeIndicator.UsrData[v].style ==  1)
					self:Fetch(sformat("CheckBox_%s", v)):Enable(LR_TeamEdgeIndicator.UsrData[v].style ==  1)
					LR_TeamBuffSettingPanel.FormatDebuffNameList()
				end
			end
		end

		local Text_Buff = LR.AppendUI("Text", Window, "Text_Buff", {x = 20, y = 40, text = _L["Buff"], font = 8})
		local Edit_Buff = self:Append("Edit", Window, sformat("Edit_Buff_%s", v), {w =  100, x = 65, y = 40, })
		Edit_Buff:Enable(LR_TeamEdgeIndicator.UsrData[v].style ==  1)
		if LR_TeamEdgeIndicator.UsrData[v].buff.dwID ~=  0 then
			Edit_Buff:SetText(LR_TeamEdgeIndicator.UsrData[v].buff.dwID)
		elseif LR_TeamEdgeIndicator.UsrData[v].buff.szName ~=  "" then
			Edit_Buff:SetText(LR_TeamEdgeIndicator.UsrData[v].buff.szName)
		else
			Edit_Buff:SetText("")
		end
		local Image_Buff = self:Append("Image", Window, sformat("Image_Buff_%s", v), {x = 170, y = 40, w = 25, h = 25,})
		Image_Buff:Hide()
		local Text_BuffName = self:Append("Text", Window, sformat("Text_BuffName_%s", v), {x = 195, y = 40, text = "", font = 0})
		if LR_TeamEdgeIndicator.UsrData[v].buff.dwID ~=  0 then
			local szBuffName = Table_GetBuffName(LR_TeamEdgeIndicator.UsrData[v].buff.dwID, 1)
			Text_BuffName:SetText(szBuffName)
			Image_Buff:FromIconID(Table_GetBuffIconID(LR_TeamEdgeIndicator.UsrData[v].buff.dwID, 1))
			Image_Buff:Show()
		end

		Edit_Buff.OnKillFocus = function()
			LR.DelayCall(100, function()
				if IsPopupMenuOpened() then
					Wnd.CloseWindow(GetPopupMenu())
				end
			end)
		end

		Edit_Buff.OnChange = function(arg0)
			local szText = sgsub(arg0, " ", "")
			if szText ==  "" then
				return
			end
			if type(tonumber(szText)) ==  "number" then
				local dwID = tonumber(szText)
				LR_TeamEdgeIndicator.UsrData[v].buff.szName = ""
				LR_TeamEdgeIndicator.UsrData[v].buff.dwID = dwID
				local szBuffName = Table_GetBuffName(dwID, 1)
				Text_BuffName:SetText(szBuffName)
				if Table_GetBuffIconID(dwID, 1) > 0 then
					Image_Buff:FromIconID(Table_GetBuffIconID(dwID, 1))
					Image_Buff:Show()
				else
					Image_Buff:Hide()
				end
			else
				LR_TeamEdgeIndicator.UsrData[v].buff.szName = szText
				LR_TeamEdgeIndicator.UsrData[v].buff.dwID = 0
				Text_BuffName:SetText("")
				Image_Buff:Hide()

				local m = {}
				m.bShowKillFocus = true
				m.bDisableSound = true
				local x, y = Edit_Buff:GetAbsPos()
				local w, h = Edit_Buff:GetSize()
				m.nMiniWidth = w
				m.x = x
				m.y = y + h
				local RowCount = g_tTable.Buff:GetRowCount()
				for i = 2, RowCount do
					local buff = g_tTable.Buff:GetRow(i)
					if buff.szName ==  szText then
						m[#m + 1] = {szOption = sformat("%s #%d", buff.szName, buff.dwBuffID),
							fnMouseEnter = function()
								local x, y = this:GetAbsPos()
								local w, h = this:GetSize()
								local szXml = {}
								szXml[#szXml+1] = GetFormatText(buff.szRemark, 0)
								OutputTip(tconcat(szXml), 350, {x, y, 0, 0})
							end,
							fnAction = function()
								LR_TeamEdgeIndicator.UsrData[v].buff.dwID = buff.dwBuffID
								LR_TeamEdgeIndicator.UsrData[v].buff.szName = buff.szName
								Edit_Buff:SetText(buff.dwBuffID)
								Text_BuffName:SetText(buff.szName)
							end
						}
					end
				end
				PopupMenu(m)
			end
			LR_TeamBuffSettingPanel.FormatDebuffNameList()
		end

		local szBuffOption = {"Only self"}
		local szBuffOptionKey = {"bSelf"}
		for k2, v2 in pairs(szBuffOption) do
			local CheckBox = self:Append("CheckBox", Window, sformat("CheckBox_%s", v), {w = 100, x = 65 + (k2 - 1) * 60, y = 70, text = _L[v2],})
			CheckBox:Enable(LR_TeamEdgeIndicator.UsrData[v].style ==  1)
			CheckBox:Check(LR_TeamEdgeIndicator.UsrData[v].buff.bOnlySelf)
			CheckBox.OnCheck = function(arg0)
				LR_TeamEdgeIndicator.UsrData[v].buff.bOnlySelf = arg0
				LR_TeamBuffSettingPanel.FormatDebuffNameList()
			end
		end
	end

	local img0 = LR.AppendUI("Image", frame, "img01", {w = 280 , h = 10, x = 40, y = 166})
	img0:FromUITex("ui/image/UICommon/commonpanel.uitex", 42)

	local shadow1 = LR.AppendUI("Shadow", frame, "Shadow1", {w = 18, h = 18, x = 20, y = 180})
	shadow1:SetColorRGB(255, 255, 0)
	local text1 = LR.AppendUI("Text", frame, "Text1", {x = 40, y = 178, text = _L["Left time short in"]})
	local comboBox1 = LR.AppendUI("ComboBox", frame, "combobox1", {w = 60, h = 20, x = 130, y = 180, text = sformat("%d%%", LR_TeamEdgeIndicator.UsrData.yellow * 100)})
	comboBox1.OnClick = function(m)
		for i = 10, 90, 10 do
			m[#m +1] = {
				szOption = sformat("%d%%", i), bCheck = true, bMCheck = true, bChecked = function() return LR_TeamEdgeIndicator.UsrData.yellow ==  i * 1.0 / 100 end,
				fnAction = function()
					comboBox1:SetText(sformat("%d%%", i))
					LR_TeamEdgeIndicator.UsrData.yellow = i * 1.0 /100
				end,
			}
		end
		PopupMenu(m)
	end

	local shadow3 = LR.AppendUI("Shadow", frame, "Shadow3", {w = 18, h = 18, x = 220, y = 180})
	shadow3:SetColorRGB(34, 177, 76)
	local text3 = LR.AppendUI("Text", frame, "Text1", {x = 240, y = 178, text = _L["Normal status"]})

	local shadow2 = LR.AppendUI("Shadow", frame, "Shadow2", {w = 18, h = 18, x = 20, y = 210})
	shadow2:SetColorRGB(255, 0, 128)
	local text2 = LR.AppendUI("Text", frame, "Text2", {x = 40, y = 208, text = _L["Left time short in"]})
	local comboBox2 = LR.AppendUI("ComboBox", frame, "combobox2", {w = 60, h = 20, x = 130, y = 210, text = sformat(_L["%ds"], LR_TeamEdgeIndicator.UsrData.red)})
	comboBox2.OnClick = function(m)
		for i = 1, 5, 1 do
			m[#m +1] = {
				szOption = sformat(_L["%ds"], i), bCheck = true, bMCheck = true, bChecked = function() return LR_TeamEdgeIndicator.UsrData.red ==  i end,
				fnAction = function()
					comboBox2:SetText(sformat(_L["%ds"], i))
					LR_TeamEdgeIndicator.UsrData.red = i
				end,
			}
		end
		PopupMenu(m)
	end

	----------关于
	LR.AppendAbout(nil, frame)
end


function LR_EdgeIndicator_Panel.OpenFrame()
	local frame = Station.Lookup("Normal/LR_EdgeIndicator_Panel")
	if not frame then
		--Wnd.OpenWindow(sformat("%s/UI/LR_EdgeIndicatorPanel.ini", AddonPath), "LR_EdgeIndicator_Panel")
		LR_EdgeIndicator_Panel:Init()
	else
		Wnd.CloseWindow("LR_EdgeIndicator_Panel")
	end
end

