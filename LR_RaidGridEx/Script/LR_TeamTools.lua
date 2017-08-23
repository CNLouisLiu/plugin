local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_RaidGridEx"
local SaveDataPath="Interface\\LR_Plugin\\@DATA\\LR_TeamGrid"
local _L = LR.LoadLangPack(AddonPath)
------------------------------------
LR_TeamTools={}

-----------------------------------------------------------
---DPS显示（需铭伊插件支持）
-----------------------------------------------------------
LR_TeamTools.DPS = {
	Record={},
	FightUIID=0,
}

function LR_TeamTools.DPS.FIGHT_HINT()
	if MY_Recount == nil or MY_Recount=={} then
		--LR.SysMsg("需安装【茗伊插件集】-【伤害统计】\n")
		return
	end
	local DPS_ALL=MY_Recount.Data.Get()
	if not DPS_ALL then
		return
	end
	local DPS_Last = DPS_ALL[1]
	if not DPS_Last then
		return
	end
	if FightUIID==DPS_Last["UUID"] then
		return
	else
		FightUIID = DPS_Last["UUID"]
	end
	local nTimeBegin= DPS_Last["nTimeBegin"]
	local nTimeDuring = DPS_Last["nTimeDuring"]
	local szBossName = DPS_Last["szBossName"]
	local Damage=DPS_Last["Damage"]
	for k,v in pairs (Damage) do
		local dwID=k
		local nTotalEffect = v["nTotalEffect"]
		if LR_TeamTools.DPS.Record[k] == nil then
			LR_TeamTools.DPS.Record[k]={{FightUIID=FightUIID,nTimeBegin=nTimeBegin,nTimeDuring=nTimeDuring,szBossName=szBossName,DPS={nTotalEffect=nTotalEffect},}}
		else
			local t={{FightUIID=FightUIID,nTimeBegin=nTimeBegin,nTimeDuring=nTimeDuring,szBossName=szBossName,DPS={nTotalEffect=nTotalEffect},}}
			for i=1,#LR_TeamTools.DPS.Record[k] do
				tinsert(t,LR_TeamTools.DPS.Record[k][i])
			end
			LR_TeamTools.DPS.Record[k]=t
			--tinsert (LR_TeamTools.DPS.Record[k],{FightUIID=FightUIID,nTimeBegin=nTimeBegin,nTimeDuring=nTimeDuring,szBossName=szBossName,DPS={nTotalEffect=nTotalEffect,},})
		end
	end
	local Heal=DPS_Last["Heal"]
	for k,v in pairs (Heal) do
		local dwID=k
		local nTotalEffect = v["nTotalEffect"]
		if LR_TeamTools.DPS.Record[k] == nil then
			LR_TeamTools.DPS.Record[k]={{FightUIID=FightUIID,nTimeBegin=nTimeBegin,nTimeDuring=nTimeDuring,szBossName=szBossName,HPS={nTotalEffect=nTotalEffect,},}}
		elseif LR_TeamTools.DPS.Record[k][1]["FightUIID"] ~= FightUIID then
			local t={{FightUIID=FightUIID,nTimeBegin=nTimeBegin,nTimeDuring=nTimeDuring,szBossName=szBossName,HPS={nTotalEffect=nTotalEffect},}}
			for i=1,#LR_TeamTools.DPS.Record[k] do
				tinsert(t,LR_TeamTools.DPS.Record[k][i])
			end
			LR_TeamTools.DPS.Record[k]=t
			--tinsert (LR_TeamTools.DPS.Record[k],{FightUIID=FightUIID,nTimeBegin=nTimeBegin,nTimeDuring=nTimeDuring,szBossName=szBossName,HPS={nTotalEffect=nTotalEffect,},})
		else
			LR_TeamTools.DPS.Record[k][1]["HPS"]={nTotalEffect=nTotalEffect,}
		end
	end
end

function LR_TeamTools.DPS.OutputDPSRecord (dwID,rc)
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
	if LR_TeamTools.DPS.Record[dwID] == nil then
		szTip[#szTip+1] = sformat("%s\n", _L["No Record"])
	else
		for i=1,#LR_TeamTools.DPS.Record[dwID] do
			local date = TimeToDate(LR_TeamTools.DPS.Record[dwID][i]["nTimeBegin"])
			local weekday =  sformat("%02d",date["weekday"])
			local hour = sformat("%02d",date["hour"])
			local minute = sformat("%02d",date["minute"])
			local second = sformat("%02d",date["second"])
			local szBossName = LR_TeamTools.DPS.Record[dwID][i]["szBossName"]
			local DPS , HPS = 0,0
			local t_text= ""
			if LR_TeamTools.DPS.Record[dwID][i]["DPS"]~=nil and LR_TeamTools.DPS.Record[dwID][i]["HPS"] ~=nil then
				DPS= sformat("%6d %4s",LR_TeamTools.DPS.Record[dwID][i]["DPS"]["nTotalEffect"] / LR_TeamTools.DPS.Record[dwID][i]["nTimeDuring"],"DPS")
				HPS= sformat("%6d %4s",LR_TeamTools.DPS.Record[dwID][i]["HPS"]["nTotalEffect"] / LR_TeamTools.DPS.Record[dwID][i]["nTimeDuring"],"HPS")
				t_text = sformat("%s / %s", DPS, HPS)
			elseif LR_TeamTools.DPS.Record[dwID][i]["HPS"]~=nil then
				HPS= sformat("%6d %4s",LR_TeamTools.DPS.Record[dwID][i]["HPS"]["nTotalEffect"] / LR_TeamTools.DPS.Record[dwID][i]["nTimeDuring"],"HPS")
				t_text = HPS
			else
				DPS= sformat("%6d %4s",LR_TeamTools.DPS.Record[dwID][i]["DPS"]["nTotalEffect"] / LR_TeamTools.DPS.Record[dwID][i]["nTimeDuring"],"DPS")
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
function LR_TeamTools.DeathRecord.OnSkillEffectLog (dwCaster, dwTarget, bReact, nEffectType, dwID, dwLevel, bCriticalStrike, nCount, tResult)
	local Caster,target,szSkillName
	if nCount <= 2 then
		return
	end
	if IsPlayer(dwCaster) then
		Caster = GetPlayer(dwCaster)
	else
		Caster = GetNpc(dwCaster)
	end
	if not Caster then
		return
	end
	if IsPlayer(dwTarget) then
		target = GetPlayer(dwTarget)
	else
		return
	end
	if not target then
		return
	end
	if nEffectType == SKILL_EFFECT_TYPE.SKILL then
		szSkillName = Table_GetSkillName(dwID, dwLevel);
	elseif nEffectType == SKILL_EFFECT_TYPE.BUFF then
		szSkillName = Table_GetBuffName(dwID, dwLevel);
	end
	if not szSkillName then
		return
	end
	local me = GetClientPlayer()
	local team = GetClientTeam()
	if IsPlayer(dwTarget) then
		if me.IsPlayerInMyParty(dwTarget) or dwTarget == me.dwID then
			LR_TeamTools.DeathRecord.tDamage[dwTarget] = LR_TeamTools.DeathRecord.tDamage[dwTarget] or {}
			local szDamage = ""
			local nValue = tResult[SKILL_RESULT_TYPE.PHYSICS_DAMAGE]
			if nValue and nValue > 0 then
				if szDamage ~= "" then
					szDamage = sformat("%s%s", szDamage, g_tStrings.STR_COMMA)
				end
				szDamage = sformat("%s%s", szDamage, FormatString(g_tStrings.SKILL_DAMAGE, nValue, g_tStrings.STR_SKILL_PHYSICS_DAMAGE))
			end
			local nValue = tResult[SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE]
			if nValue and nValue > 0 then
				if szDamage ~= "" then
					szDamage = sformat("%s%s", szDamage, g_tStrings.STR_COMMA)
				end
				szDamage = sformat("%s%s", szDamage ,FormatString(g_tStrings.SKILL_DAMAGE, nValue, g_tStrings.STR_SKILL_SOLAR_MAGIC_DAMAGE))
			end
			local nValue = tResult[SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE]
			if nValue and nValue > 0 then
				if szDamage ~= "" then
					szDamage = sformat("%s%s", szDamage, g_tStrings.STR_COMMA)
				end
				szDamage = sformat("%s%s", szDamage, FormatString(g_tStrings.SKILL_DAMAGE, nValue, g_tStrings.STR_SKILL_NEUTRAL_MAGIC_DAMAGE))
			end
			local nValue = tResult[SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE]
			if nValue and nValue > 0 then
				if szDamage ~= "" then
					szDamage = sformat("%s%s", szDamage, g_tStrings.STR_COMMA)
				end
				szDamage = sformat("%s%s", szDamage, FormatString(g_tStrings.SKILL_DAMAGE, nValue, g_tStrings.STR_SKILL_LUNAR_MAGIC_DAMAGE))
			end
			local nValue = tResult[SKILL_RESULT_TYPE.POISON_DAMAGE]
			if nValue and nValue > 0 then
				if szDamage ~= "" then
					szDamage = sformat("%s%s", szDamage, g_tStrings.STR_COMMA)
				end
				szDamage = sformat("%s%s", szDamage, FormatString(g_tStrings.SKILL_DAMAGE, nValue, g_tStrings.STR_SKILL_POISON_DAMAGE))
			end
			if szDamage ~= "" then
				tinsert(LR_TeamTools.DeathRecord.tDamage[dwTarget],{
					szCaster = LR.GetTemplateName(Caster),
					szTarget = LR.GetTemplateName(target),
					szSkillName = szSkillName,
					szValue = szDamage,
					time = GetCurrentTime(),
				})
			end
		end
	end
	if IsPlayer(dwCaster) and (me.IsPlayerInMyParty(dwCaster) or dwCaster == me.dwID) then
		if not LR_TeamTools.DeathRecord.tDamage[dwCaster] then
			LR_TeamTools.DeathRecord.tDamage[dwCaster] = {}
		end
		local szDamage = ""
		local nValue = tResult[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE]
		if nValue and nValue > 0 then
			if szDamage ~= "" then
				szDamage = sformat("%s%s", szDamage, g_tStrings.STR_COMMA)
			end
			szDamage = sformat("%s%d%s", szDamage, nValue, _L["Points harm"])
		end
		if szDamage ~= "" then
			tinsert(LR_TeamTools.DeathRecord.tDamage[dwCaster],{
				szCaster = LR.GetTemplateName(target),
				szTarget = LR.GetTemplateName(Caster),
				szSkillName = sformat("%s(%s)", _L["Bounce"], szSkillName),
				szValue = szDamage,
			})
		end
	end
end

function LR_TeamTools.DeathRecord.OnCommonHealthLog (dwTarget, nDeltaLife)
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
	if me.IsPlayerInMyParty(dwTarget) or dwTarget == me.dwID then
		if not LR_TeamTools.DeathRecord.tDamage[dwTarget] then
			LR_TeamTools.DeathRecord.tDamage[dwTarget] = {}
		end
		tinsert(LR_TeamTools.DeathRecord.tDamage[dwTarget],{
			szCaster =_L["Extraterrestrials"],
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

function LR_TeamTools.DeathRecord.OnDeath (dwTarget, dwCaster)
	local szCasterName = ""
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsPlayer(dwTarget) then
		target=GetPlayer(dwTarget)
	else
		return
	end

	if IsPlayer(dwCaster) then
		Caster = GetPlayer(dwCaster)
		if Caster then
			szCasterName = LR.Trim(Caster.szName)
		else
			szBossName = sformat(_L["Player id: %d"], dwCaster)
		end
	else
		Caster = GetNpc(dwCaster)
		if Caster then
			szCasterName = LR.Trim(Caster.szName)
			if szCasterName == "" then
				szCasterName = LR.Trim(Table_GetNpcTemplateName(Caster.dwTemplateID))
			end
			if szCasterName == "" then
				szCasterName = _L["Extraterrestrials"]
			end
		else
			szCasterName = _L["Extraterrestrials"]
		end
	end

	if me.IsPlayerInMyParty(dwTarget) or dwTarget == me.dwID then
		LR_TeamTools.DeathRecord.tDeath[dwTarget] = LR_TeamTools.DeathRecord.tDeath[dwTarget] or {}
		local tDeath = LR_TeamTools.DeathRecord.tDeath[dwTarget]
		local deathData = {}
		deathData.szCaster = szCasterName
		deathData.time = GetCurrentTime()
		deathData.last10Damage = {}
		local tDamage = LR_TeamTools.DeathRecord.tDamage[dwTarget] or {}
		for i=#tDamage, mmax(1, #tDamage - 10), -1 do
			deathData.last10Damage[#deathData.last10Damage+1] = clone(tDamage[i])
		end
		tinsert(LR_TeamTools.DeathRecord.tDeath[dwTarget], deathData)
		if #LR_TeamTools.DeathRecord.tDeath[dwTarget] > 6 then
			tremove(LR_TeamTools.DeathRecord.tDeath[dwTarget],1)
		end
		LR_TeamTools.DeathRecord.tDamage[dwTarget] = nil
	end
end

RegisterEvent("SYS_MSG",function()
	if arg0 == "UI_OME_DEATH_NOTIFY" then -- 死亡记录
		--arg1:死亡的人的id
		--arg2:杀死他的人的id
		--Output("UI_OME_DEATH_NOTIFY",arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7)
		LR_TeamTools.DeathRecord.OnDeath(arg1, arg2)
	elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" then -- 技能记录
		LR_TeamTools.DeathRecord.OnSkillEffectLog(arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9)
	elseif arg0 == "UI_OME_COMMON_HEALTH_LOG" then
		--LR_TeamTools.DeathRecord.OnCommonHealthLog(arg1,arg2)
	end
end)

function LR_TeamTools.DeathRecord.OutputDeathRecord(dwID,rc)
	local hTeam = GetClientTeam()
	local v = hTeam.GetMemberInfo(dwID)
	if not v then
		return
	end
	local szIcon,nFrame = GetForceImage(v.dwForceID)
	local r,g,b =  LR.GetMenPaiColor(v.dwForceID)
	local szXml = {}
	szXml[#szXml+1] = GetFormatImage(szIcon,nFrame,26,26)
	szXml[#szXml+1] = GetFormatText(sformat("%s:\n", v.szName),136,r,g,b)
	szXml[#szXml+1] = GetFormatText(sformat("%s\n", _L["--Dead Record--"]),136,255,255,255)
	if not LR_TeamTools.DeathRecord.tDeath[dwID] or #LR_TeamTools.DeathRecord.tDeath[dwID] == 0 then
		szXml[#szXml+1] = GetFormatText(sformat("%s\n", _L["No Record"]),136,255,255,0)
	else
		for i = #LR_TeamTools.DeathRecord.tDeath[dwID] , 1 , -1 do
			local a = LR_TeamTools.DeathRecord.tDeath[dwID][i]
			szXml[#szXml+1] = GetFormatText(sformat("%s ", FormatTime("%Y-%m-%d %H:%M:%S", a.time)),136,255,255,0)
			szXml[#szXml+1] = GetFormatText(sformat("%s killed %s\n", a.szCaster, v.szName ),136,255,128,0)
			for k2, v2 in pairs(a.last10Damage) do
				szXml[#szXml+1] = GetFormatText("-> ",136,255,128,0)
				szXml[#szXml+1] = GetFormatText(sformat("%s ", FormatTime("%Y-%m-%d %H:%M:%S", v2.time)),136,255,255,0)
				szXml[#szXml+1] = GetFormatText(v2.szCaster,136,255,128,0)
				szXml[#szXml+1] = GetFormatText(" <",136,255,255,0)
				szXml[#szXml+1] = GetFormatText(v2.szSkillName,136,255,128,0)
				szXml[#szXml+1] = GetFormatText("> ",136,255,255,0)
				szXml[#szXml+1] = GetFormatText(_L["Cause"],136,255,255,0)
				szXml[#szXml+1] = GetFormatText(sformat("%s\n", v2.szValue),136,255,128,0)
			end
			szXml[#szXml+1] = GetFormatText("\n",136,255,128,0)
		end
	end
	OutputTip(tconcat(szXml),600,rc)
end

--------------------------------------------------------------------------------------------------------------------
-----------重伤记录
--------------------------------------------------------------------------------------------------------------------
LR_TeamTools.Menpai={
	Count={}
}
function LR_TeamTools.Menpai.CheckMenpai ()
	local player =  GetClientPlayer()
	if not player then return end
	local team= GetClientTeam()
	if not team then return end
	local team_ids=team.GetTeamMemberList()

	LR_TeamTools.Menpai.Count[0]=0 	--大侠
	LR_TeamTools.Menpai.Count[1]=0	--少林
	LR_TeamTools.Menpai.Count[2]=0	--万花
	LR_TeamTools.Menpai.Count[3]=0	--天策
	LR_TeamTools.Menpai.Count[4]=0	--纯阳
	LR_TeamTools.Menpai.Count[5]=0	--七秀
	LR_TeamTools.Menpai.Count[6]=0	--五毒
	LR_TeamTools.Menpai.Count[7]=0	--唐门
	LR_TeamTools.Menpai.Count[8]=0	--藏剑
	LR_TeamTools.Menpai.Count[9]=0	--丐帮
	LR_TeamTools.Menpai.Count[10]=0	--明教
	LR_TeamTools.Menpai.Count[21]=0	--苍云
	LR_TeamTools.Menpai.Count[22]=0	--长歌门
	LR_TeamTools.Menpai.Count[23]=0	--霸刀

	for i=1,#team_ids,1 do
		local memberinfo= team.GetMemberInfo(team_ids[i])
		if memberinfo then
			LR_TeamTools.Menpai.Count[memberinfo.dwForceID] = LR_TeamTools.Menpai.Count[memberinfo.dwForceID]+1
		end
	end
end

function LR_TeamTools.Menpai.OutputData()
	LR_TeamTools.Menpai.CheckMenpai ()
	local szText={}
	szText[#szText+1]={szText=_L["LR_MenPai Count:\n"]}
	szText[#szText+1]={szText="----------"}
	local dwForceID={1,2,3,4,5,6,7,8,9,10,21,22,23,0}
	local szForceName={_L["ShaoLin"],_L["WanHua"],_L["TianCe"],_L["ChunYang"],_L["QiXiu"],_L["WuDu"],_L["TangMen"],_L["CangJian"],_L["GaiBang"],_L["MingJiao"],_L["CangYun"],_L["ChangGeMen"],_L["BaDao"],_L["DaXia"],}
	for k, v in pairs(dwForceID) do
		szText[#szText+1]={szText=sformat("【%s】：%d\n", szForceName[k], LR_TeamTools.Menpai.Count[v])}
	end
	szText[#szText+1]={szText="----------"}
	for k, v in pairs(szText) do
		LR.Talk(PLAYER_TALK_CHANNEL.RAID, v.szText)
	end
end

--------------------------------------------------------------------------------------------------------------------
-----------分配提醒
--------------------------------------------------------------------------------------------------------------------
LR_TeamTools.DistributeAttention={}

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
	if scene.nType == MAP_TYPE.DUNGEON then
		if me.IsInParty() or me.IsInRaid() then
			local team = GetClientTeam()
			if me.IsInRaid() then
				if team.nLootMode ~= 2 then
					LR_TeamGrid.SetTitleText(sformat(_L["Warning: You are in [%s] loot mode"], szLootMode[team.nLootMode]))
					LR.DelayCall(12000,function() LR_TeamGrid.SetTitleText("") end)
				end
			else
				if team.nLootMode ~= 3 then
					LR_TeamGrid.SetTitleText(sformat(_L["Warning: You are in [%s] loot mode"], szLootMode[team.nLootMode]))
					LR.DelayCall(12000,function() LR_TeamGrid.SetTitleText("") end)
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------------------
-----------Hack系统团队面板
--------------------------------------------------------------------------------------------------------------------
LR_TeamTools.HackSystemTeamPanel={}


function LR_TeamTools.HackSystemTeamPanel.ON_FRAME_CREATE()
	local frame = arg0
	if frame:GetName() == "RaidPanel_Main" then
		--Output("sdf")
		LR.DelayCall(500,function()
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
				Output("ererer")
			end
		end)

	end
end

LR.RegisterEvent("ON_FRAME_CREATE", function() LR_TeamTools.HackSystemTeamPanel.ON_FRAME_CREATE() end)

