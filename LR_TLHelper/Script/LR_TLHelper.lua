local sformat, slen, sgsub, ssub,sfind = string.format, string.len, string.gsub, string.sub, string.find
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
-----------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_TLHelper"
local _L = LR.LoadLangPack(AddonPath)
local UI={}
----------------------------------------------------
LR_TLHelper={
	bombImg={},
	bombTime={},
	LastTime=0,
	FrameLastTime=0,
	QJB={
		Box_Img="",
		Box_TypeText="",
		Box_TimeText="",
		Box_TargetText="",
		LastTime=0,
		Type=0,
		SelfID=0,
		TargetID=0,
		LastFightTime=0,
	},
	GuiFuEndFrame=0,
}

LR_TLHelper.UsrData={
	on=false,
	Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0,},
	Alpha= 80,
	Scale=1,
	HideQJB=true,
	showTargetLine=false,
	showMeLine=false,
	showSelf=false,
}

LR_TLHelper.Bombs={}
LR_TLHelper.SelectSelf=true

local CustomVersion = "20170111"
RegisterCustomData("LR_TLHelper.UsrData", CustomVersion)


function LR_TLHelper.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
	--this:RegisterEvent("LOADING_END")
	this:RegisterEvent("NPC_ENTER_SCENE")
	this:RegisterEvent("NPC_LEAVE_SCENE")

	this:RegisterEvent("DO_SKILL_CAST")
	this:RegisterEvent("SYS_MSG")

	this:SetAlpha(255*LR_TLHelper.UsrData.Alpha/100)

	LR_TLHelper.MainFrame=Station.Lookup("Normal/LR_TLHelper")
	LR_TLHelper.MainFrame:SetAlpha(0)

	LR_TLHelper.handle=LR_TLHelper.MainFrame:Lookup("","")
	LR_TLHelper.QJB.Box_Img=LR_TLHelper.handle:Lookup("Box_1")
	LR_TLHelper.QJB.Box_TypeText=LR_TLHelper.handle:Lookup("Text_1")

	LR_TLHelper.QJB.QJB_tar=LR_TLHelper.handle:Lookup("NPC_Name")
	LR_TLHelper.QJB.QJB_Distance2Self=LR_TLHelper.handle:Lookup("Distance_ToSelf")
	LR_TLHelper.QJB.QJB_Distance2tar=LR_TLHelper.handle:Lookup("Distance_ToTarget")
	LR_TLHelper.QJB.QJB_FightState=LR_TLHelper.handle:Lookup("QJB_FightState")


	LR_TLHelper.bombImg[1]=LR_TLHelper.handle:Lookup("Box_2")
	LR_TLHelper.bombImg[2]=LR_TLHelper.handle:Lookup("Box_3")
	LR_TLHelper.bombImg[3]=LR_TLHelper.handle:Lookup("Box_4")

	LR_TLHelper.bombTime[1]=LR_TLHelper.handle:Lookup("Text_2")
	LR_TLHelper.bombTime[2]=LR_TLHelper.handle:Lookup("Text_3")
	LR_TLHelper.bombTime[3]=LR_TLHelper.handle:Lookup("Text_4")

	LR_TLHelper.Shadow_Self=LR_TLHelper.handle:Lookup("Shadow_Self")
	LR_TLHelper.Shadow_ToME=LR_TLHelper.handle:Lookup("Shadow_ToME")
	LR_TLHelper.Shadow_ToTarget=LR_TLHelper.handle:Lookup("Shadow_ToTarget")

	LR_TLHelper.GuiFuBox=LR_TLHelper.handle:Lookup("Box_5")
	LR_TLHelper.GuiFuBoxTime=LR_TLHelper.handle:Lookup("Text_5")
	LR_TLHelper.GuiFuBoxStack=LR_TLHelper.handle:Lookup("Text_GuiFu")

	LR_TLHelper.QJB.QJB_tar:SetText("")
	LR_TLHelper.QJB.QJB_Distance2Self:SetText("")
	LR_TLHelper.QJB.QJB_Distance2tar:SetText("")
	LR_TLHelper.QJB.QJB_FightState:SetText("")
	LR_TLHelper.QJB.QJB_tar:SetFontScheme(16)
	LR_TLHelper.QJB.QJB_Distance2Self:SetFontScheme(16)
	LR_TLHelper.QJB.QJB_Distance2tar:SetFontScheme(16)
	LR_TLHelper.QJB.QJB_FightState:SetFontScheme(16)


	LR_TLHelper.QJB.Box_Img:SetObject(1)
	LR_TLHelper.QJB.Box_Img:SetObjectIcon(1904)
	LR_TLHelper.QJB.Box_TypeText:SetText(_L["None"])
	LR_TLHelper.QJB.Box_TypeText:SetFontScheme(16)

	LR_TLHelper.bombImg[1]:SetObject(1)
	LR_TLHelper.bombImg[2]:SetObject(1)
	LR_TLHelper.bombImg[3]:SetObject(1)

	LR_TLHelper.bombImg[1]:SetObjectIcon(83)
	LR_TLHelper.bombImg[2]:SetObjectIcon(83)
	LR_TLHelper.bombImg[3]:SetObjectIcon(83)

	LR_TLHelper.bombTime[1]:SetText("30")
	LR_TLHelper.bombTime[2]:SetText("30")
	LR_TLHelper.bombTime[3]:SetText("30")

	LR_TLHelper.GuiFuBox:SetObject(1)
	LR_TLHelper.GuiFuBox:SetObjectIcon(3193)
	LR_TLHelper.GuiFuBoxTime:SetText("0")
	LR_TLHelper.GuiFuBoxStack:SetText("20")

	LR_TLHelper.GuiFuBox:Hide()
	LR_TLHelper.GuiFuBoxTime:Hide()
	LR_TLHelper.GuiFuBoxStack:Hide()

	LR_TLHelper.Shadow_Self:Hide()
	LR_TLHelper.Shadow_ToME:Hide()
	LR_TLHelper.Shadow_ToTarget:Hide()

	LR_TLHelper.UpdateAnchor(this)
	LR_TLHelper.ScaleFont()
end

function LR_TLHelper.ScaleFont ()
	LR_TLHelper.MainFrame:Scale(LR_TLHelper.UsrData.Scale,LR_TLHelper.UsrData.Scale)

	LR_TLHelper.QJB.QJB_tar:SetFontScale(LR_TLHelper.UsrData.Scale)
	LR_TLHelper.QJB.QJB_Distance2Self:SetFontScale(LR_TLHelper.UsrData.Scale)
	LR_TLHelper.QJB.QJB_Distance2tar:SetFontScale(LR_TLHelper.UsrData.Scale)
	LR_TLHelper.QJB.QJB_FightState:SetFontScale(LR_TLHelper.UsrData.Scale)

	LR_TLHelper.QJB.Box_TypeText:SetFontScale(LR_TLHelper.UsrData.Scale)

	LR_TLHelper.bombTime[1]:SetFontScale(LR_TLHelper.UsrData.Scale)
	LR_TLHelper.bombTime[2]:SetFontScale(LR_TLHelper.UsrData.Scale)
	LR_TLHelper.bombTime[3]:SetFontScale(LR_TLHelper.UsrData.Scale)
end


function LR_TLHelper.OnEvent(event)
	if event == "LOADING_END" then
		LR_TLHelper.UpdateAnchor(this)
	elseif event == "UI_SCALED" then
		LR_TLHelper.UpdateAnchor(this)
	elseif event == "DO_SKILL_CAST" then
		LR_TLHelper.UpdateBombNum()
		LR_TLHelper.UpdateQJBState()
	elseif event == "NPC_ENTER_SCENE" then
		LR_TLHelper.NPC_ENTER_SCENE(arg0)
	elseif event == "NPC_LEAVE_SCENE" then
		LR_TLHelper.NPC_LEAVE_SCENE(arg0)
	elseif event == "SYS_MSG" then
		if arg0 == "UI_OME_SKILL_EFFECT_LOG" then
			LR_TLHelper.GetQJBTarget ()
		elseif arg0 == "UI_OME_DEATH_NOTIFY" then
			LR_TLHelper.ClearQJBTarget ()
		end
	end
end

function LR_TLHelper.OnFrameBreathe()
	if not LR_TLHelper.UsrData.on then
		Wnd.CloseWindow("LR_TLHelper")
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end

	if GetLogicFrameCount() - LR_TLHelper.FrameLastTime>8 then
		if LR.GetXinFa() == Table_GetSkillName(10225,1) then
			LR_TLHelper.MainFrame:SetAlpha(255*LR_TLHelper.UsrData.Alpha/100)
		else
			Wnd.CloseWindow("LR_TLHelper")
			return
		end
	else
		return
	end

	LR_TLHelper.UpdateBomb()
	LR_TLHelper.UpdateQJB()
	LR_TLHelper.UpdateGF()

	if IsCtrlKeyDown() and  (IsShiftKeyDown() or IsAltKeyDown()) then
		this:SetDragArea(0, 0, this:GetSize())
		this:SetMousePenetrable(false)
		this:SetAlpha(255)
	else
		this:SetDragArea(0, 0, 0, 0)
		this:SetMousePenetrable(true)
		this:SetAlpha(255*LR_TLHelper.UsrData.Alpha/100)
	end
end

function LR_TLHelper.OnFrameDragEnd()
	this:CorrectPos()
	LR_TLHelper.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_TLHelper.UpdateAnchor(frame)
	frame:SetPoint(LR_TLHelper.UsrData.Anchor.s, 0, 0, LR_TLHelper.UsrData.Anchor.r, LR_TLHelper.UsrData.Anchor.x, LR_TLHelper.UsrData.Anchor.y)
	frame:CorrectPos()
end

function LR_TLHelper.UpdateQJBState()
	if arg0 ~= GetClientPlayer().dwID then
		return
	end
	if Table_GetSkillName(arg1,arg2) == _L["QianJiBian"] then
		LR_TLHelper.QJB.Box_Img:SetObjectIcon(3191)
		LR_TLHelper.QJB.Box_TypeText:SetText( _L["QianJiBian"])
		LR_TLHelper.QJB.Type=1
		LR_TLHelper.QJB.LastTime=GetLogicFrameCount()
	end
	if Table_GetSkillName(arg1,arg2) == _L["LianNuXingTai"] then
		LR_TLHelper.QJB.Box_Img:SetObjectIcon(3291)
		LR_TLHelper.QJB.Box_TypeText:SetText(_L["LianNuXingTai"])
		LR_TLHelper.QJB.Type=2
		LR_TLHelper.QJB.LastTime=GetLogicFrameCount()
	end
	if Table_GetSkillName(arg1,arg2) == _L["ZhongNuXingTai"] then
		LR_TLHelper.QJB.Box_Img:SetObjectIcon(3290)
		LR_TLHelper.QJB.Box_TypeText:SetText(_L["ZhongNuXingTai"])
		LR_TLHelper.QJB.Type=3
		LR_TLHelper.QJB.LastTime=GetLogicFrameCount()
	end
	if Table_GetSkillName(arg1,arg2) == _L["DuShaXingTai"] then
		LR_TLHelper.QJB.Box_Img:SetObjectIcon(3288)
		LR_TLHelper.QJB.Box_TypeText:SetText(_L["DuShaXingTai"])
		LR_TLHelper.QJB.Type=4
		LR_TLHelper.QJB.LastTime=GetLogicFrameCount()
	end
end

function LR_TLHelper.NPC_ENTER_SCENE(dwID)
	local npc =  GetNpc(dwID)
	if not npc then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end

	local szName=LR_TLHelper.GetQJBNameByTemplateID(npc.dwTemplateID)
	if npc.dwEmployer == me.dwID then
		if szName == _L["QianJiBian"] or szName == _L["DuSha"] or szName ==  _L["ZhongNu"] or szName== _L["LianNu"] then
			LR_TLHelper.QJB.SelfID= npc.dwID

			if LR_TLHelper.UsrData.showMeLine then
				local r,g,b,a=128,255,128,140
				LR_TLHelper.Shadow_ToME:SetTriangleFan(GEOMETRY_TYPE.LINE, 2)
				LR_TLHelper.Shadow_ToME:ClearTriangleFanPoint()
				LR_TLHelper.Shadow_ToME:AppendCharacterID(LR_TLHelper.QJB.SelfID, false, r, g, b, a)
				LR_TLHelper.Shadow_ToME:AppendCharacterID(me.dwID, false, r, g, b, a)
				LR_TLHelper.Shadow_ToME:Show()
			end

			if LR_TLHelper.UsrData.showSelf then
				UI.DrawShape(npc,LR_TLHelper.Shadow_Self,360,0.45,{255,201,14},TARGET.NPC,140)
			end
		end
	end
end

function LR_TLHelper.NPC_LEAVE_SCENE(dwID)
	local me = GetClientPlayer()
	if not me then
		return
	end

	if LR_TLHelper.QJB.SelfID == dwID then
		LR_TLHelper.QJB.SelfID= 0
		LR_TLHelper.Shadow_ToME:Hide()
		LR_TLHelper.Shadow_ToTarget:Hide()
		LR_TLHelper.Shadow_Self:Hide()
	end
end


function LR_TLHelper.GetQJBRadiusByTemplateID (dwTemplateID)
	----------------------
	--每尺=64个单位
	----------------------
	if dwTemplateID == 15959 then	-- 飞星
		return 2240
	elseif dwTemplateID == 15994 then	-- 天绝地灭
		return 384
	elseif dwTemplateID == 16174 then	-- 机关底坐
		return 0
	elseif dwTemplateID == 16000 then	-- 暗藏杀机
		return 384
	elseif dwTemplateID == 16177 then	-- 毒刹
		return 640
	elseif dwTemplateID == 16176 then	-- 重弩
		return 1600
	elseif dwTemplateID == 16175 then	-- 连弩
		return 1600
	end
	return 0
end

function LR_TLHelper.GetQJBNameByTemplateID (dwTemplateID)
	if dwTemplateID == 15959 then	-- 飞星
		return _L["FeiXing"]
	elseif dwTemplateID == 15994 then	-- 天绝地灭
		return _L["TianJueDiMie"]
	elseif dwTemplateID == 16174 then	-- 机关底坐
		return _L["QianJiBian"]
	elseif dwTemplateID == 16000 then	-- 暗藏杀机
		return _L["AnCangShaJi"]
	elseif dwTemplateID == 16177 then	-- 毒刹
		return _L["DuSha"]
	elseif dwTemplateID == 16176 then	-- 重弩
		return _L["ZhongNu"]
	elseif dwTemplateID == 16175 then	-- 连弩
		return _L["LianNu"]
	end
	return _L["Other"]
end


function LR_TLHelper.UpdateBombNum()
	if arg0 ~= GetClientPlayer().dwID then
		return
	end
	if Table_GetSkillName(arg1,arg2) == _L["AnCangShaJi"] then
	    local count = #LR_TLHelper.Bombs
		if count < 3 then
		    tinsert(LR_TLHelper.Bombs,GetLogicFrameCount())
		elseif count == 3 then
		    tremove(LR_TLHelper.Bombs,1)
		    tinsert(LR_TLHelper.Bombs,GetLogicFrameCount())
		end
	end
	if Table_GetSkillName(arg1,arg2) == _L["TuQiongBiXian"] then
		LR_TLHelper.Bombs = {}
	end
	--Output(LR_TLHelper.Bombs)
end

function LR_TLHelper.UpdateBomb()
	local num=#LR_TLHelper.Bombs
	if num>0 then
		if 60*16 - 1 -(GetLogicFrameCount()-LR_TLHelper.Bombs[1]) <0 then
			tremove(LR_TLHelper.Bombs,1)
		end
	end
	num=#LR_TLHelper.Bombs
	for i=1,num do
		LR_TLHelper.bombImg[i]:Show()
		LR_TLHelper.bombTime[i]:Show()
		LR_TLHelper.bombTime[i]:SprintfText("%0.0f", 60 - 0.01 - (GetLogicFrameCount()-LR_TLHelper.Bombs[i])/16)
		LR_TLHelper.bombImg[i]:SetObjectCoolDown(true)
		LR_TLHelper.bombImg[i]:SetCoolDownPercentage((60 - 0.01 - (GetLogicFrameCount()-LR_TLHelper.Bombs[i])/16)/60)
		if 60*16 - 1 -(GetLogicFrameCount() - LR_TLHelper.Bombs[i]) < 5*16 then
			LR_TLHelper.bombImg[i]:SetObjectStaring(true)
		else
			LR_TLHelper.bombImg[i]:SetObjectStaring(false)
		end
	end
	for i=1,3-num do
		LR_TLHelper.bombImg[4-i]:SetObjectCoolDown(false)
		LR_TLHelper.bombImg[4-i]:Hide()
		LR_TLHelper.bombTime[4-i]:Hide()
	end
end

function LR_TLHelper.ClearSeen ()
	LR_TLHelper.QJB.Box_Img:SetObjectIcon(1904)
	LR_TLHelper.QJB.Box_TypeText:SetText(_L["None"])
	LR_TLHelper.QJB.Box_Img:SetObjectCoolDown(false)
	LR_TLHelper.QJB.Box_Img:SetObjectStaring(false)
	LR_TLHelper.QJB.Type=0
	LR_TLHelper.QJB.QJB_Distance2Self:SetText("")
	LR_TLHelper.QJB.QJB_Distance2tar:SetText("")
	LR_TLHelper.QJB.QJB_tar:SetText("")
	LR_TLHelper.QJB.QJB_FightState:SetText("")
end

function LR_TLHelper.ShowQJBDistance2Self ()
	local player =  GetClientPlayer()
	if LR_TLHelper.QJB.SelfID==0 then
		return
	end
	if (GetLogicFrameCount()-LR_TLHelper.QJB.LastTime) >= 16 then
		local tDistance_ToSelf= GetCharacterDistance(LR_TLHelper.QJB.SelfID,player.dwID)/64
		if tDistance_ToSelf>=0 then
			LR_TLHelper.QJB.QJB_Distance2Self:SprintfText("%0.1f", tDistance_ToSelf)
		else
			LR_TLHelper.QJB.QJB_Distance2Self:SetText("--")
		end
	else
		LR_TLHelper.QJB.QJB_Distance2Self:SetText("")
	end
end


-----------------------------------------
--连弩攻击一次，依次释放 3361、3405、3363技能
--重弩攻击依次，依次释放 3362、3409、3365技能
----------------------------------------
function LR_TLHelper.GetQJBTarget ()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_TLHelper.UsrData.on then
		return
	end
	if LR.GetXinFa() ~= Table_GetSkillName(10225,1) then
		return
	end
	if LR_TLHelper.QJB.SelfID == 0 then
		return
	end

	if arg1 ==  LR_TLHelper.QJB.SelfID then
		if arg5 == 3361 or arg5 == 3362 then
			LR_TLHelper.QJB.TargetID = arg2
			LR_TLHelper.QJB.LastFightTime = GetLogicFrameCount()
		end
	else
		--LR_TLHelper.QJB.TargetID=0
	end
end

function LR_TLHelper.ClearQJBTarget ()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if arg1 == LR_TLHelper.QJB.TargetID then
		LR_TLHelper.QJB.TargetID = 0
	end
end

function LR_TLHelper.ShowQJBTarget()
	local me=  GetClientPlayer()
	if not me then
		return
	end

	local QJB_TargetID = LR_TLHelper.QJB.TargetID
	local me_Target_Type,me_Target_dwID = me.GetTarget()

	if QJB_TargetID == 0 or QJB_TargetID == LR_TLHelper.QJB.SelfID or  QJB_TargetID == nil then
		LR_TLHelper.QJB.QJB_Distance2tar:SetText("")
		LR_TLHelper.QJB.QJB_tar:SetText("")
		LR_TLHelper.QJB.QJB_FightState:SetText("")
		LR_TLHelper.Shadow_ToTarget:Hide()
		return
	end
	local QJB_Target,QJB_Target_Type
    if IsPlayer(QJB_TargetID) then
        QJB_Target = GetPlayer(QJB_TargetID)
		QJB_Target_Type = TARGET.PLAYER
    else
        QJB_Target = GetNpc(QJB_TargetID)
		QJB_Target_Type = TARGET.NPC
    end
	if not QJB_Target then
		LR_TLHelper.Shadow_ToTarget:Hide()
		return
	end
	local QJB_2_QJBTarget_Distance= GetCharacterDistance(LR_TLHelper.QJB.SelfID,QJB_TargetID)/64
	if QJB_2_QJBTarget_Distance>=0 then
		LR_TLHelper.QJB.QJB_Distance2tar:SprintfText("%0.1f", QJB_2_QJBTarget_Distance)
	else
		LR_TLHelper.QJB.QJB_Distance2tar:SetText("--")
	end
	local szName=LR.Trim(QJB_Target.szName)
	if QJB_Target_Type == TARGET.NPC then
		if szName=="" then
			szName=Table_GetNpcTemplateName(QJB_Target.dwTemplateID)
		end
	end

	LR_TLHelper.QJB.QJB_tar:SetText(szName)

	if LR_TLHelper.UsrData.showTargetLine then
		local r,g,b,a=153,217,234,140
		LR_TLHelper.Shadow_ToTarget:SetTriangleFan(GEOMETRY_TYPE.LINE, 2)
		LR_TLHelper.Shadow_ToTarget:ClearTriangleFanPoint()
		LR_TLHelper.Shadow_ToTarget:AppendCharacterID(LR_TLHelper.QJB.SelfID, true, r, g, b, a, -110)
		LR_TLHelper.Shadow_ToTarget:AppendCharacterID(QJB_TargetID, true, r, g, b, a)
		LR_TLHelper.Shadow_ToTarget:Show()
	end

	local QJB=GetNpc(LR_TLHelper.QJB.SelfID)
	if not QJB then
		LR_TLHelper.QJB.QJB_FightState:SetText("")
		return
	end

	local text=""
	if QJB_TargetID ~= me_Target_dwID then
		text=_L["Not the same target"]
	end
	if GetLogicFrameCount() - LR_TLHelper.QJB.LastFightTime < 36 then
		LR_TLHelper.QJB.QJB_FightState:SprintfText("%s%s", _L["Attacking"], text)
	else
		LR_TLHelper.QJB.QJB_FightState:SetText(text)
	end
end

function LR_TLHelper.UpdateGF()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local nowFrame=GetLogicFrameCount()
	if LR_TLHelper.GuiFuEndFrame>nowFrame then
		LR_TLHelper.GuiFuBoxTime:SetText(mceil((LR_TLHelper.GuiFuEndFrame-nowFrame)/16))
	end
end

function LR_TLHelper.UpdateQJB()
	local player=GetClientPlayer()

	if GetLogicFrameCount() - LR_TLHelper.QJB.LastTime > 8 then
		local frame=Station.Lookup("Normal/PuppetActionBar")
		if not frame then
			LR_TLHelper.ClearSeen ()
		end
	end
	----千机变
	if LR_TLHelper.QJB.Type==1 then
		if 120*16 - 1 -(GetLogicFrameCount() - LR_TLHelper.QJB.LastTime) <0 then
			LR_TLHelper.ClearSeen ()
		else
			LR_TLHelper.QJB.Box_TypeText:SprintfText("%s.%0.0f", _L["QianJiBian"], 120 - 0.01 - (GetLogicFrameCount()-LR_TLHelper.QJB.LastTime)/16)
			LR_TLHelper.QJB.Box_Img:SetObjectCoolDown(true)
			LR_TLHelper.QJB.Box_Img:SetCoolDownPercentage((120 - 0.01 - (GetLogicFrameCount()-LR_TLHelper.QJB.LastTime)/16)/120)
			LR_TLHelper.ShowQJBDistance2Self ()
			--LR_TLHelper.QJB.Box_Img:SetObjectSparking(true)
			if 120*16 - 1 -(GetLogicFrameCount() - LR_TLHelper.QJB.LastTime) <10*16 then
				LR_TLHelper.QJB.Box_Img:SetObjectStaring(true)
			else
				LR_TLHelper.QJB.Box_Img:SetObjectStaring(false)
			end
		end
	end
	------连弩
	if LR_TLHelper.QJB.Type==2 then
		if 120*16 - 1 -(GetLogicFrameCount() - LR_TLHelper.QJB.LastTime) <0 then
			LR_TLHelper.ClearSeen ()
		else
			LR_TLHelper.QJB.Box_TypeText:SprintfText("%s.%0.0f", _L["LianNuXingTai"], 120 - 0.01 - (GetLogicFrameCount()-LR_TLHelper.QJB.LastTime)/16)
			LR_TLHelper.QJB.Box_Img:SetObjectCoolDown(true)
			LR_TLHelper.QJB.Box_Img:SetCoolDownPercentage((120 - 0.01 - (GetLogicFrameCount()-LR_TLHelper.QJB.LastTime)/16)/120)
			LR_TLHelper.ShowQJBDistance2Self ()
			LR_TLHelper.ShowQJBTarget()
			--LR_TLHelper.QJB.Box_Img:SetObjectSparking(true)
			if 120*16 - 1 -(GetLogicFrameCount() - LR_TLHelper.QJB.LastTime) <10*16 then
				LR_TLHelper.QJB.Box_Img:SetObjectStaring(true)
			else
				LR_TLHelper.QJB.Box_Img:SetObjectStaring(false)
			end
		end
	end
	-------重弩
	if LR_TLHelper.QJB.Type==3 then
		if 120*16 - 1 -(GetLogicFrameCount() - LR_TLHelper.QJB.LastTime) <0 then
			LR_TLHelper.ClearSeen ()
		else
			LR_TLHelper.QJB.Box_TypeText:SprintfText("%s.%0.0f", _L["ZhongNuXingTai"], 120 - 0.01 - (GetLogicFrameCount()-LR_TLHelper.QJB.LastTime)/16)
			LR_TLHelper.QJB.Box_Img:SetObjectCoolDown(true)
			LR_TLHelper.QJB.Box_Img:SetCoolDownPercentage((120 - 0.01 - (GetLogicFrameCount()-LR_TLHelper.QJB.LastTime)/16)/120)
			LR_TLHelper.ShowQJBDistance2Self ()
			LR_TLHelper.ShowQJBTarget()
			--LR_TLHelper.QJB.Box_Img:SetObjectSparking(true)
			if 120*16 - 1 -(GetLogicFrameCount() - LR_TLHelper.QJB.LastTime) <10*16 then
				LR_TLHelper.QJB.Box_Img:SetObjectStaring(true)
			else
				LR_TLHelper.QJB.Box_Img:SetObjectStaring(false)
			end
		end
	end
	--------毒刹
	if LR_TLHelper.QJB.Type==4 then
		if 11*16 - 1 -(GetLogicFrameCount() - LR_TLHelper.QJB.LastTime) <0 then
			LR_TLHelper.ClearSeen ()
		elseif 11*16 - 1 -(GetLogicFrameCount() - LR_TLHelper.QJB.LastTime) < 8*16 then
			LR_TLHelper.QJB.Box_TypeText:SprintfText("%s.%0.0f", _L["DuShaXingTai"], 11 - 0.01 - (GetLogicFrameCount()-LR_TLHelper.QJB.LastTime)/16)
			LR_TLHelper.QJB.Box_Img:SetObjectCoolDown(true)
			LR_TLHelper.QJB.Box_Img:SetCoolDownPercentage((11 - 0.01 - (GetLogicFrameCount()-LR_TLHelper.QJB.LastTime)/16)/8)
			LR_TLHelper.ShowQJBDistance2Self ()
			--LR_TLHelper.QJB.Box_Img:SetObjectSparking(true)
		else
			LR_TLHelper.QJB.Box_Img:SetObjectCoolDown(false)
		end
	end
	--------无东西
	if LR_TLHelper.QJB.Type==0 then
		LR_TLHelper.ClearSeen ()
		if LR_TLHelper.UsrData.HideQJB == true then
			LR_TLHelper.QJB.Box_Img:Hide()
			LR_TLHelper.QJB.Box_TypeText:Hide()
			LR_TLHelper.QJB.Box_Img:Hide()
			LR_TLHelper.QJB.Box_Img:Hide()
		else
			LR_TLHelper.QJB.Box_Img:Show()
			LR_TLHelper.QJB.Box_TypeText:Show()
			LR_TLHelper.QJB.Box_Img:Show()
			LR_TLHelper.QJB.Box_Img:Show()
		end
	else
		LR_TLHelper.QJB.Box_Img:Show()
		LR_TLHelper.QJB.Box_TypeText:Show()
		LR_TLHelper.QJB.Box_Img:Show()
		LR_TLHelper.QJB.Box_Img:Show()
	end
	  --Output(LR_TLHelper.QJB.Type)
end

---------------------------------------------
function LR_TLHelper.UpdateXinFa()
	if arg0 ~= GetClientPlayer().dwID then
		return
	end
	if arg1 == 13165 then
		if not LR_TLHelper.UsrData.on then
			return
		end
		Wnd.OpenWindow("Interface\\LR_Plugin\\LR_TLHelper\\UI\\LR_TLHelper.ini", "LR_TLHelper")
		LR_TLHelper.FrameLastTime=GetLogicFrameCount()
	end
end

function LR_TLHelper.OpenPanel()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_TLHelper.UsrData.on then
		return
	end
	if LR.GetXinFa() ~= Table_GetSkillName(10225,1) then
		return
	end
	Wnd.OpenWindow("Interface\\LR_Plugin\\LR_TLHelper\\UI\\LR_TLHelper.ini", "LR_TLHelper")
	LR_TLHelper.FrameLastTime=GetLogicFrameCount()
end

function LR_TLHelper.BUFF_UPDATE()
	local dwPlayerID=arg0
	local bDelete=arg1
	local nIndex=arg2
	local bCanCancel=arg3
	local dwBuffID=arg4
	local nCount=arg5
	local nEndFrame=arg6
	local bInit=arg7
	local nBuffLevel=arg8
	local dwSkillSrcID=arg9
	local isValid=arg10
	local nLeftFrame=arg11
	local me=GetClientPlayer()
	if not me then
		return
	end
	if dwPlayerID~=me.dwID then
		return
	end
	if dwBuffID~=3426 then
		return
	end
	if dwBuffID==3426 then
		LR_TLHelper.GuiFuEndFrame=nEndFrame
		if bDelete then
			LR_TLHelper.GuiFuBox:Hide()
			LR_TLHelper.GuiFuBoxStack:Hide()
			LR_TLHelper.GuiFuBoxTime:Hide()
			LR_TLHelper.GuiFuBoxStack:SetText("")
			LR_TLHelper.GuiFuBoxTime:SetText("")
			LR_TLHelper.GuiFuEndFrame=0
		else
			local nowFrame=GetLogicFrameCount()
			LR_TLHelper.GuiFuBoxStack:SprintfText("x %d", nCount)
			LR_TLHelper.GuiFuBoxTime:SetText(mceil((nEndFrame-nowFrame)/16))
			LR_TLHelper.GuiFuBox:Show()
			LR_TLHelper.GuiFuBoxStack:Show()
			LR_TLHelper.GuiFuBoxTime:Show()
		end
	end
end

LR.RegisterEvent("FIRST_LOADING_END",function() LR_TLHelper.OpenPanel() end)
LR.RegisterEvent("DO_SKILL_CAST",function() LR_TLHelper.UpdateXinFa() end)
LR.RegisterEvent("BUFF_UPDATE",function() LR_TLHelper.BUFF_UPDATE() end)

----------------------------------------
local _t_type=TARGET.NO_TARGET
local _t_dwID=0
local _flag=0
function LR_TLHelper.SelectSelf_Key()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if LR.GetXinFa() ~= Table_GetSkillName(10225,1) then
		SetTarget(TARGET.PLAYER,me.dwID)
		return
	end
	if _flag==0 then
		_t_type,_t_dwID=me.GetTarget()
	end
	SetTarget(TARGET.PLAYER,me.dwID)
	_flag=1
end

function LR_TLHelper.SelectSelf_SKILL_PREPARE()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if LR.GetXinFa() ~= Table_GetSkillName(10225,1) then
		return
	end
	if not LR_TLHelper.SelectSelf then
		return
	end
	if Table_GetSkillName(arg1,arg2) == _L["QianJiBian"] then
		if _flag==1 then
			SetTarget(_t_type,_t_dwID)
			_t_type=TARGET.NO_TARGET
			_t_dwID=0
			_flag=0
		end
	end
end

LR.RegisterEvent("DO_SKILL_PREPARE_PROGRESS",function() LR_TLHelper.SelectSelf_SKILL_PREPARE() end)
----------------------------------------------------------

function UI.WorldMarkDraw(Point, sha, col)
	local nRadius = 64
	local nFace = 128
	local dwRad1 = mpi
	local dwRad2 = 3 * mpi + mpi / 20
	local r, g, b = unpack(col)
	local nX ,nY, nZ = unpack(Point)
	sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
	sha:SetD3DPT(D3DPT.TRIANGLEFAN)
	sha:ClearTriangleFanPoint()
	sha:AppendTriangleFan3DPoint(nX ,nY, nZ, r, g, b, 100)
	sha:Show()
	local sX, sZ = Scene_PlaneGameWorldPosToScene(nX, nY)
	repeat
		local sX_, sZ_ = Scene_PlaneGameWorldPosToScene(nX + mcos(dwRad1) * nRadius, nY + msin(dwRad1) * nRadius)
		sha:AppendTriangleFan3DPoint(nX ,nY, nZ, r, g, b, 100, { sX_ - sX, 0, sZ_ - sZ })
		dwRad1 = dwRad1 + mpi / 16
	until dwRad1 > dwRad2
end

function UI.draw(xScreen, yScreen,zScreen)
	local shadow=LR_TLHelper.Shadow_Self
	if not shadow then
		return
	end
	local me=GetClientPlayer()
	if not me then
		return
	end
	local Point={xScreen, yScreen,zScreen}
	local sha=shadow
	local col={255,255,0}
	UI.WorldMarkDraw(Point, sha, col)

	if true then
		return
	end
	local ncLen=15
	shadow:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
	shadow:SetD3DPT(D3DPT.TRIANGLEFAN)
	shadow:ClearTriangleFanPoint()
	local r,g,b=255,255,0
	shadow:AppendTriangleFan3DPoint(xScreen, yScreen,zScreen, r,g,b,  255)
	local dwMaxRadius=mpi+mpi
	local dwStepRadius=dwMaxRadius/21--( nLength /16 )
	local dwCurRadius=0 - dwStepRadius
	repeat
		dwCurRadius = dwCurRadius + dwStepRadius
		if dwCurRadius>dwMaxRadius then
			dwCurRadius=dwMaxRadius
		end
		cX = xScreen + mceil(mcos(dwCurRadius) * ncLen)
		cY = yScreen + mceil(msin(dwCurRadius) * ncLen)

		local cX,cY=xCircles.GetScreenPoint(cX,cY,tar.obj.nZ)
		if cX and cY then
			shadow:AppendTriangleFan3DPoint(cX, cY, r,g,b,255)
		end

	until dwMaxRadius <= dwCurRadius
	shadow:Show()
end

function UI.DrawShape(tar, sha, nAngle, nRadius, col, dwType, __Alpha)
	local pi=mpi
	local nRadius = nRadius * 64
	local nFace = mceil(128 * nAngle / 360)
	local dwRad1 = pi * (tar.nFaceDirection - nFace) / 128
	if tar.nFaceDirection > (256 - nFace) then
		dwRad1 = dwRad1 - pi - pi
	end
	local dwRad2 = dwRad1 + (nAngle / 180 * pi)
	local nStep = 16
	if nAngle <= 45 then nStep = 180 end
	if nAngle == 360 then
		dwRad2 = dwRad2 + pi / 20
	end

	nAlpha=__Alpha
	local r, g, b = unpack(col)
	-- orgina point
	sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
	sha:SetD3DPT(D3DPT.TRIANGLEFAN)
	sha:ClearTriangleFanPoint()
	if dwType == TARGET.DOODAD then
		sha:AppendDoodadID(tar.dwID, r, g, b, nAlpha)
	else
		sha:AppendCharacterID(tar.dwID, false, r, g, b, nAlpha)
	end
	sha:Show()
	-- relative points
	local sX, sZ = Scene_PlaneGameWorldPosToScene(tar.nX, tar.nY)
	repeat
		local sX_, sZ_ = Scene_PlaneGameWorldPosToScene(tar.nX + mcos(dwRad1) * nRadius, tar.nY + msin(dwRad1) * nRadius)
		if dwType == TARGET.DOODAD then
			sha:AppendDoodadID(tar.dwID, r, g, b, nAlpha, { sX_ - sX, 0, sZ_ - sZ })
		else
			sha:AppendCharacterID(tar.dwID, false, r, g, b, nAlpha, { sX_ - sX, 0, sZ_ - sZ })
		end
		dwRad1 = dwRad1 + pi / nStep
	until dwRad1 > dwRad2
end
