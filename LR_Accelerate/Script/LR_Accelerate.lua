local AddonPath="Interface\\LR_Plugin\\LR_Accelerate"
local _L=LR.LoadLangPack(AddonPath)
local sformat, slen, sgsub, ssub,sfind = string.format, string.len, string.gsub, string.sub, string.find
local mfloor, mceil, mmin, mmax = math.floor, math.ceil, math.min, math.max
local tconcat, tinsert, tremove, tsort = table.concat, table.insert, table.remove, table.sort
--------------------------------------------------
LR_Accelerate = LR_Accelerate or {
	delta = 0,
	cd = 1.5,
	jump = 1,
	Lv90 = 54.782,
	Lv95 = 47.17425,
}

---95：95等级第一资料片：剑胆琴心
---951:95等级第二资料片：壮志凌云
---952:95等级第三资料片：百家争鸣
---953:95等级第四资料片：风骨霸刀
---954:95等级第五资料片：日月凌空
LR_Accelerate.UsrData = {
	bOn = false,
	version = 955,
}

local JIA_SU = {
	[90] = "Lv90",
	[95] = "Lv95",
	[951] = "Lv95",
	[952] = "Lv95",
	[953] = "Lv95",
	[954] = "Lv95",
	[955] = "Lv95",
}

LR_Accelerate.QiXueLv90 = {
	[1]={szName=_L["Acupoint:None(Default)"],delta=0},
	[2]={szName=_L["MengGe(WanHua)"],delta=50},
	[3]={szName=_L["ZhenShang(QiXiu)"],delta=50},
	[4]={szName=_L["DuShou(WuDu)"],delta=102},
	[5]={szName=_L["JuJingNingShen(TangMen)"],delta=205},
	[6]={szName=_L["YuePo(MingJiao)"],delta=52},
	[7]={szName=_L["TaiJiWuJi(ChunYang)"],delta=60},
	[8]={szName=_L["QinXin/NingJue(ChangGeMen)"],delta=51},
}

LR_Accelerate.QiXueLv95 = {
	[1]={szName=_L["Acupoint:None(Default)"],delta=0},
	[2]={szName=_L["MengGe(WanHua)"],delta=50},
	[3]={szName=_L["ZhenShang(QiXiu)"],delta=50},
	[4]={szName=_L["DuShou(WuDu)"],delta=102},
	[5]={szName=_L["JuJingNingShen(TangMen)"],delta=204},
	[6]={szName=_L["YuePo(MingJiao)"],delta=52},
	[7]={szName=_L["TaiJiWuJi(ChunYang)"],delta=60},
	[8]={szName=_L["QinXin/NingJue(ChangGeMen)"],delta=51},
	[9]={szName=_L["RuFeng(CangJian)"],delta=51},
	[10]={szName=_L["SuiBing(NaiXiu)"],delta=51},
	[11]={szName=_L["FaJing(MingJiaoT)"],delta=105},
}

LR_Accelerate.QiXueLv951 = {
	[1]={szName=_L["Acupoint:None(Default)"],delta=0},
	[2]={szName=_L["MengGe(WanHua)DPS"],delta=60},
	[3]={szName=_L["ZhenShang(QiXiu)"],delta=50},
	[4]={szName=_L["DuShou(WuDu)"],delta=102},
	[5]={szName=_L["JuJingNingShen(TangMen)"],delta=204},
	[6]={szName=_L["YuePo(MingJiao)"],delta=52},
	[7]={szName=_L["TaiJiWuJi(ChunYang)"],delta=60},
	[8]={szName=_L["QinXin/NingJue(ChangGeMen)"],delta=51},
	[9]={szName=_L["RuFeng(CangJian)"],delta=51},
	[10]={szName=_L["SuiBing(NaiXiu)"],delta=51},
	[11]={szName=_L["FaJing(MingJiaoT)"],delta=105},
	[12]={szName=_L["MengGe(WanHua)Nurse"],delta=50},
}

LR_Accelerate.QiXueLv952 = {
	[1]={szName=_L["Acupoint:None(Default)"],delta=0},
	[2]={szName=_L["MengGe(WanHua)"],delta=60},
	[3]={szName=_L["ZhenShang(QiXiu)"],delta=50},
	[4]={szName=_L["DuShou(WuDu)"],delta=102},
	[5]={szName=_L["JuJingNingShen(TangMen)"],delta=204},
	[6]={szName=_L["YuePo(MingJiao)"],delta=52},
	[7]={szName=_L["TaiJiWuJi(ChunYang)"],delta=60},
	[8]={szName=_L["QinXin/NingJue(ChangGeMen)"],delta=51},
	[9]={szName=_L["RuFeng(CangJian)"],delta=51},
	[10]={szName=_L["SuiBing(NaiXiu)"],delta=51},
	[11]={szName=_L["FaJing(MingJiaoT)"],delta=105},
}

LR_Accelerate.QiXueLv953 = {
	[1]={szName=_L["Acupoint:None(Default)"],delta=0},
	[2]={szName=_L["MengGe(WanHua)"],delta=60},
	[3]={szName=_L["ZhenShang(QiXiu)"],delta=50},
	[4]={szName=_L["DuShou(WuDu)"],delta=102},
	[5]={szName=_L["JuJingNingShen(TangMen)"],delta=204},
	[6]={szName=_L["YuePo(MingJiao)"],delta=52},
	[7]={szName=_L["TaiJiWuJi(ChunYang)"],delta=60},
	[8]={szName=_L["QinXin/NingJue(ChangGeMen)"],delta=51},
	[9]={szName=_L["RuFeng(CangJian)"],delta=51},
	[10]={szName=_L["SuiBing(NaiXiu)"],delta=51},
	[11]={szName=_L["FaJing(MingJiaoT)"],delta=105},
	--[12]={szName=_L["YiFeng(BaDao)"],delta=51},
}

LR_Accelerate.QiXueLv954 = {
	[1]={szName=_L["Acupoint:None(Default)"],delta=0},
	[2]={szName=_L["MengGe(WanHua)"],delta=60},
	[3]={szName=_L["ZhenShang(QiXiu)"],delta=50},
	[4]={szName=_L["DuShou(WuDu)"],delta=102},
	[5]={szName=_L["JuJingNingShen(TangMen)"],delta=204},
	[6]={szName=_L["YuePo(MingJiao)"],delta=52},
	[7]={szName=_L["TaiJiWuJi(ChunYang)"],delta=60},
	[8]={szName=_L["QinXin/NingJue(ChangGeMen)"],delta=51},
	[9]={szName=_L["RuFeng(CangJian)"],delta=51},
	[10]={szName=_L["SuiBing(NaiXiu)"],delta=51},
	[11]={szName=_L["FaJing(MingJiaoT)"],delta=105},
	--[12]={szName=_L["YiFeng(BaDao)"],delta=51},
}

LR_Accelerate.QiXueLv955 = {
	[1]={szName=_L["Acupoint:None(Default)"],delta=0},		--默认：无加速，GCD1.5s
	[2]={szName=_L["MengGe(WanHua)"],delta=60},	--梦歌（万花）
	[3]={szName=_L["ZhenShang(QiXiu)"],delta=50},	--枕上（七秀）
	[4]={szName=_L["DuShou(WuDu)"],delta=102},	--毒手（五毒）
	[5]={szName=_L["JuJingNingShen(TangMen)"],delta=204},	--聚精凝神（唐门）
	--[6]={szName=_L["YuePo(MingJiao)"],delta=52},	--月破（明教）
	[7]={szName=_L["TaiJiWuJi(ChunYang)"],delta=60},	--太极无极（纯阳）
	[8]={szName=_L["QinXin/NingJue(ChangGeMen)"],delta=51},	--沁心/凝绝（长歌门）
	[9]={szName=_L["RuFeng(CangJian)"],delta=82},	--如风（藏剑）
	[10]={szName=_L["SuiBing(NaiXiu)"],delta=51},		--碎冰（奶秀）
	--[11]={szName=_L["FaJing(MingJiaoT)"],delta=105},	--法境（明教T）
	--[12]={szName=_L["YiFeng(BaDao)"],delta=51},
}


LR_Accelerate.QiXue = {}

LR_Accelerate.YuShe = {
	{szName=_L["Default(1.5sGCD)"],cd=1.5,jump=1,QiXue=1},
	{szName=_L["MingJiaoDPS"],cd=1,jump=1,QiXue=1},
	--{szName=_L["MingJiaoT"],cd=1,jump=1,QiXue=1},
	{szName=_L["QiChun"],cd=1.5,delta=0,jump=1,QiXue=7},
	{szName=_L["BingXinDaiXian(XinZhuang)"],cd=2.4375,jump=3,QiXue=3},
	{szName=_L["BingXinDaiXian(Normal)"],cd=3,jump=3,QiXue=3},
	{szName=_L["NaiXiu(HuiXuePiaoYao)"],cd=3,jump=3,QiXue=1},
	--{szName=_L["NaiXiu(HuiXuePiaoYao)+SuiBing"],cd=3,jump=3,QiXue=10},
	{szName=_L["NaiXiu(HuiXuePiaoYao)+GuiZi"],cd=2.4375,jump=3,QiXue=1},
	--{szName=_L["NaiXiu(LingLongKongHou)"],cd=2.5,jump=5,QiXue=1},
	--{szName=_L["NaiXiu(LingLongKongHou)+SuiBing"],cd=2.5,jump=5,QiXue=10},
	{szName=_L["HuaJian(KuaiXue)"],cd=5,jump=5,QiXue=2},
	{szName=_L["HuaJian(KuaiXue-QingGe)"],cd=3.125,jump=5,QiXue=2},
	{szName=_L["HuaJian(YangMingZhi)"],cd=1.5,jump=1,QiXue=2},
	{szName=_L["NaiHuaChangZhen(QingLv)"],cd=2.75,jump=1,QiXue=1},
	{szName=_L["NaiHuaChangZhen(Normal)"],cd=3,jump=1,QiXue=1},
	{szName=_L["NaiHuaBiZhen"],cd=1.5,jump=1,QiXue=1},
	{szName=_L["NaiHuaTiZhen(JieZe)"],cd=1.75,jump=1,QiXue=1},
	{szName=_L["NaiHuaTiZhen(Normal)"],cd=2,jump=1,QiXue=1},
	--{szName=_L["NaiDuZuiWu(NaJing)"],cd=4.8125,jump=7,QiXue=1},	--【日月凌空】和谐
	{szName=_L["NaiDuZuiWu(NaJing)"],cd=4.875,jump=6,QiXue=1},
	{szName=_L["NaiDuZuiWu(Normal)"],cd=5,jump=5,QiXue=1},
	{szName=_L["NaiDuBingCan"],cd=1.5,jump=1,QiXue=1},
	{szName=_L["DuJingXieXin"],cd=1.5,jump=1,QiXue=1},
	{szName=_L["TianLuo(ShiJiDan1.75s)"],cd=1.75,jump=1,QiXue=1},
	{szName=_L["TianLuo(ShiJiDan1.5s)"],cd=1.5,jump=1,QiXue=1},
	{szName=_L["TangMen(BaoYuLiHuaZhen)"],cd=2.5,jump=5,QiXue=1},
	{szName=_L["JingYu(DuoPo)"],cd=1.5,jump=1,QiXue=1},
	{szName=_L["ChangGeMen-Zhi"],cd=3,jump=3,QiXue=1},
	{szName=_L["ChangGeMen-Zhi(ZhengCu)"],cd=3,jump=6,QiXue=1},
	{szName=_L["ChangGeMen-Gong"],cd=1.5,jump=1,QiXue=1},
	{szName=_L["ChangGeMen-Gong(GuangYa)"],cd=3,jump=1,QiXue=1},
	{szName=_L["NaiGe-Gong"],cd=1.5,jump=1,QiXue=8},
	{szName=_L["CangJian"],cd=1.5,jump=1,QiXue=9},
	--{szName=_L["BaDao"],cd=1.5,jump=1,QiXue=1},
	--{szName=_L["BaDao(YiFeng)"],cd=1.5,jump=1,QiXue=12},
}

------------------------------------------
--界面
------------------------------------------
LR_Accelerate_Panel = CreateAddon("LR_Accelerate_Panel")
LR_Accelerate_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_Accelerate_Panel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0},
}


function LR_Accelerate_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("CUSTOM_DATA_LOADED")

	LR_Accelerate_Panel.UpdateAnchor(this)
	RegisterGlobalEsc("LR_Accelerate_Panel",function () return true end ,function() LR_Accelerate_Panel:Open() end)
	--[[
	if LR_Accelerate.UsrData.version == 95 then
		LR_Accelerate.QiXue=clone(LR_Accelerate.QiXueLv95)
	elseif LR_Accelerate.UsrData.version == 90 then
		LR_Accelerate.QiXue=clone(LR_Accelerate.QiXueLv90)
	elseif LR_Accelerate.UsrData.version == 951 then
		LR_Accelerate.QiXue=clone(LR_Accelerate.QiXueLv951)
	elseif LR_Accelerate.UsrData.version == 952 then
		LR_Accelerate.QiXue=clone(LR_Accelerate.QiXueLv952)
	elseif LR_Accelerate.UsrData.version == 953 then
		LR_Accelerate.QiXue=clone(LR_Accelerate.QiXueLv953)
	elseif LR_Accelerate.UsrData.version == 954 then
		LR_Accelerate.QiXue=clone(LR_Accelerate.QiXueLv954)
	end
	]]
	LR_Accelerate.QiXue = clone(LR_Accelerate[sformat("QiXueLv%d", LR_Accelerate.UsrData.version)])

	LR_Accelerate.delta=0
	LR_Accelerate.cd=1.5
	LR_Accelerate.jump=1
end

function LR_Accelerate_Panel:OnEvents(event)
	if event == "CUSTOM_DATA_LOADED" then
		if arg0 == "Role" then
			LR_Accelerate_Panel.UpdateAnchor(this)
		end
	elseif event == "UI_SCALED" then
		LR_Accelerate_Panel.UpdateAnchor(this)
	end
end

function LR_Accelerate_Panel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_Accelerate_Panel.UsrData.Anchor.s, 0, 0, LR_Accelerate_Panel.UsrData.Anchor.r, LR_Accelerate_Panel.UsrData.Anchor.x, LR_Accelerate_Panel.UsrData.Anchor.y)
end

function LR_Accelerate_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_Accelerate_Panel")
	PlaySound(SOUND.UI_SOUND,g_sound.CloseFrame)
end

function LR_Accelerate_Panel:OnDragEnd()
	this:CorrectPos()
	LR_Accelerate_Panel.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_Accelerate_Panel:Init()
	local frame = self:Append("Frame", "LR_Accelerate_Panel", {title = _L["LR Accelerate Table"] , style = "SMALL"})

	local imgTab = self:Append("Image", frame,"TabImg",{w = 381,h = 33,x = 0,y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex",46)
	imgTab:SetImageType(11)

	local UIButton_FAQ = self:Append("UIButton", frame, "FAQ" , {x = 318 , y = 14 , w = 22 , h = 22, ani = {"ui\\Image\\UICommon\\CommonPanel2.UITex", 48, 50, 54, 55}, })
	UIButton_FAQ.OnEnter = function()
		local x, y = UIButton_FAQ:GetAbsPos()
		local w, h = UIButton_FAQ:GetSize()
		local szXml = {}
		szXml[#szXml+1] = GetFormatText(_L["TIP01"], 136, 255, 128, 0)

		OutputTip(tconcat(szXml), 600, {x, y, 0, 0})
	end
	UIButton_FAQ.OnLeave = function()
		HideTip()
	end


	local hPageSet = self:Append("PageSet", frame, "PageSet", {x = 20, y = 180, w = 360, h = 300})
	local hWinIconView = self:Append("Window", hPageSet, "WindowItemView", {x = 0, y = 0, w = 360, h = 300})
	local hScroll = self:Append("Scroll", hWinIconView,"Scroll", {x = 0, y = 0, w = 354, h = 300})
	self:LoadItemBox(hScroll)
	hScroll:UpdateList()

	-------------初始界面物品
	local hHandle = self:Append("Handle", frame, "Handle", {x = 18, y = 150, w = 340, h = 330})

	local Image_Record_BG = self:Append("Image", hHandle, "Image_Record_BG", {x = 0, y = 0, w = 340, h = 330})
	Image_Record_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",50)
	Image_Record_BG:SetImageType(10)

	local Image_Record_BG1 = self:Append("Image", hHandle, "Image_Record_BG1", {x = 0, y = 30, w = 340, h = 300})
	Image_Record_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",74)
	Image_Record_BG1:SetImageType(10)
	Image_Record_BG1:SetAlpha(110)

	local Image_Record_Line1_0 = self:Append("Image", hHandle, "Image_Record_Line1_0", {x = 3, y = 28, w = 340, h = 3})
	Image_Record_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",65)
	Image_Record_Line1_0:SetImageType(11)
	Image_Record_Line1_0:SetAlpha(115)

	local Image_Record_Break1 = self:Append("Image", hHandle, "Image_Record_Break1", {x = 60, y = 2, w = 3, h = 326})
	Image_Record_Break1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",48)
	Image_Record_Break1:SetImageType(11)
	Image_Record_Break1:SetAlpha(160)

	local Text_break1 = self:Append("Text", hHandle, "Text_break1", {w = 60, h = 30, x =0, y = 2, text = _L["Level"], font = 18})
	Text_break1:SetHAlign(1)
	Text_break1:SetVAlign(1)

	local Image_Record_Break2 = self:Append("Image", hHandle, "Image_Record_Break2", {x = 150, y = 2, w = 3, h = 326})
	Image_Record_Break2:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",48)
	Image_Record_Break2:SetImageType(11)
	Image_Record_Break2:SetAlpha(160)

	local Text_break2 = self:Append("Text", hHandle, "Text_break1", {w = 90, h = 30, x =60, y = 2, text = _L["Real Time"], font = 18})
	Text_break2:SetHAlign(1)
	Text_break2:SetVAlign(1)

	local Image_Record_Break3 = self:Append("Image", hHandle, "Image_Record_Break3", {x = 240, y = 2, w = 3, h = 326})
	Image_Record_Break3:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",48)
	Image_Record_Break3:SetImageType(11)
	Image_Record_Break3:SetAlpha(160)

	local Text_break3 = self:Append("Text", hHandle, "Text_break1", {w = 95, h = 30, x =150, y = 2, text = _L["Accelerate Rate"] , font = 18})
	Text_break3:SetHAlign(1)
	Text_break3:SetVAlign(1)

	local Text_break4 = self:Append("Text", hHandle, "Text_break1", {w = 95, h = 30, x =240, y = 2, text = _L["Accelerate Level"] , font = 18})
	Text_break4:SetHAlign(1)
	Text_break4:SetVAlign(1)


	----正读条时间/持续性技能间隔时间/引导读条每跳时间
	local text_cd = self:Append("Text", frame, "Text_cd", {w = 100, h = 30, x =20, y = 85, text = _L["Time/Interval"] , font = 15})
	text_cd:SetHAlign(0)

	local Editbox_cd = self:Append("Edit", frame, "Editbox_cd", {w = 100, h = 30, x = 100, y = 85, text = "1.5"})
	Editbox_cd:Enable(true)
	Editbox_cd.OnChange = function (value)
		LR_Accelerate.cd = tonumber (value)
		if type(LR_Accelerate.cd) ~="number" then
			return
		end
		if  LR_Accelerate.cd >20 then
			LR_Accelerate.cd=20
			Editbox_cd:SetText("20")
		end
		local cc=self:Fetch("Scroll")
		if cc then
			self:ClearHandle(cc)
		end
		self:LoadItemBox(hScroll)
		hScroll:UpdateList()
	end
	----跳数
	local text_jump = self:Append("Text", frame, "Text_jump", {w = 100, h = 30, x =20, y = 115, text = _L["Jumps"], font = 15})
	text_jump:SetHAlign(0)

	local Editbox_jump = self:Append("Edit", frame, "Editbox_jump", {w = 100, h = 30, x = 100, y = 115, text = "1"})
	Editbox_jump:Enable(true)
	Editbox_jump.OnChange = function (value)
		LR_Accelerate.jump = tonumber (value)

		local cc=self:Fetch("Scroll")
		if cc then
			self:ClearHandle(cc)
		end
		self:LoadItemBox(hScroll)
		hScroll:UpdateList()
	end


	--------------奇穴选择
	local hComboBox = self:Append("ComboBox", frame, "hComboBox", {w = 160, x = 20, y = 51, text = _L["Acupoint:None(Default)"]  })
	hComboBox:Enable(true)

	local t_table = LR_Accelerate.QiXue or {}
	hComboBox.OnClick = function (m)
			for i, v in pairs(t_table) do
			--for i = 1, #t_table, 1 do
				tinsert (m, {szOption = t_table[i].szName, bCheck = false, bChecked = false, fnAction = function ()
					hComboBox:SetText(t_table[i].szName)
					LR_Accelerate.delta = t_table[i].delta

					local cc = self:Fetch("Scroll")
					if cc then
						self:ClearHandle(cc)
					end
					self:LoadItemBox(hScroll)
					hScroll:UpdateList()
				end})
			end
			PopupMenu(m)
	end

	--------------预设选择
	local hComboBox_2 = self:Append("ComboBox", frame, "hComboBox_2", {w = 160, x = 200, y = 51, text = _L["Default(1.5sGCD)"] })
	hComboBox_2:Enable(true)

	local t_table_2 = LR_Accelerate.YuShe or {}
	hComboBox_2.OnClick = function (m)
			for i=1,#t_table_2,1 do
				tinsert (m,{szOption=t_table_2[i].szName,bCheck=false,bChecked=false,fnAction= function ()
					hComboBox:SetText(LR_Accelerate.QiXue[t_table_2[i].QiXue].szName)
					hComboBox_2:SetText(t_table_2[i].szName)
					Editbox_cd:SetText(t_table_2[i].cd)
					Editbox_jump:SetText(t_table_2[i].jump)

					LR_Accelerate.delta = LR_Accelerate.QiXue[t_table_2[i].QiXue].delta
					LR_Accelerate.cd = tonumber(t_table_2[i].cd)
					LR_Accelerate.jump = tonumber(t_table_2[i].jump)

					local cc=self:Fetch("Scroll")
					if cc then
						self:ClearHandle(cc)
					end
					self:LoadItemBox(hScroll)
					hScroll:UpdateList()
				end})
			end
			PopupMenu(m)
	end

	--------------版本选择
	local hComboBoxVersion = self:Append("ComboBox", frame, "hComboBoxVersion", {w = 160, x = 20, y = 480, text = _L[sformat("Lv%d Version", LR_Accelerate.UsrData.version)] })
	hComboBoxVersion:Enable(true)

	local t_table = LR_Accelerate.QiXue or {}
	hComboBoxVersion.OnClick = function (m)
		local menu = {}
		local nVersion = {955, 954, 953, 952, 951, 95, 90}
		for k, v in pairs(nVersion) do
			menu[k] = { szOption = _L[sformat("Lv%d Version", v)], bCheck = true, bMCheck = true,
				bChecked = function() return LR_Accelerate.UsrData.version == v end,
				fnAction = function()
					hComboBoxVersion:SetText(_L[sformat("Lv%d Version", v)])
					LR_Accelerate.UsrData.version = v
					LR_Accelerate.QiXue = clone(LR_Accelerate[sformat("QiXueLv%d", v)])

					LR_Accelerate.delta = 0
					LR_Accelerate.cd = 1.5
					LR_Accelerate.jump = 1

					hComboBox_2:SetText(_L["Default(1.5sGCD)"])
					hComboBox:SetText(_L["Acupoint:None(Default)"])
					Editbox_cd:SetText("1.5")
					Editbox_jump:SetText("1")

					local cc=self:Fetch("Scroll")
					if cc then
						self:ClearHandle(cc)
					end
					self:LoadItemBox(hScroll)
					hScroll:UpdateList()
					local cc=self:Fetch("Scroll")
					if cc then
						self:ClearHandle(cc)
					end
					self:LoadItemBox(hScroll)
					hScroll:UpdateList()
				end
			}
		end
		for i=1,#menu,1 do
			tinsert(m,menu[i])
		end
		PopupMenu(m)
	end

	----------关于
	LR.AppendAbout(LR_Accelerate_Panel, frame)
end

function LR_Accelerate_Panel:Open()
	local frame = self:Fetch("LR_Accelerate_Panel")
	if frame then
		self:Destroy(frame)
	else
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
end

function LR_Accelerate_Panel:LoadItemBox(hWin)
	if type(LR_Accelerate.cd) ~= "number" then
		return
	end
	if type(LR_Accelerate.jump) ~= "number" then
		return
	end
	if LR_Accelerate.jump == 0 then
		return
	end
	local Zhenshu_Yuan = LR_Accelerate.cd * 16 / LR_Accelerate.jump
	local Zhenshu_min = mfloor ((Zhenshu_Yuan)/1.25)
	local Dangshu = Zhenshu_Yuan - Zhenshu_min
	--Output(LR_Accelerate.cd,LR_Accelerate.jump,Zhenshu_Yuan,Zhenshu_min,Dangshu)

	for i = 0, Dangshu do
		local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", i), {x = 0, y = 0, w = 340, h = 30})
		local Jiasulvzhi = mceil (Zhenshu_Yuan / (Zhenshu_Yuan - i + 1) * 1024 - 1024 )
		if Zhenshu_Yuan / (Zhenshu_Yuan- i + 1) * 1024 - 1024 == Jiasulvzhi then
			Jiasulvzhi = Jiasulvzhi + 1
		end
		local jiasu = LR_Accelerate[JIA_SU[LR_Accelerate.UsrData.version]] or 0

		local YuZhi = mceil ((Jiasulvzhi - LR_Accelerate.delta )  * jiasu / 10.24)
		if YuZhi <= 0 then
			YuZhi = 0
		end

		local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", i), {x = 0, y = 0, w = 340, h = 30})
		Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex",75)
		Image_Line:SetImageType(10)
		Image_Line:SetAlpha(200)

		if i % 2 == 0 then
			Image_Line:Hide()
		end

		local Text_break1 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_1", i), {w = 60, h = 30, x =0, y = 2, text = i, font = 18})
		Text_break1:SetHAlign(1)
		Text_break1:SetVAlign(1)

		local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", i), {w = 90, h = 30, x =60, y = 2, text = sformat ("%0.2fs", (Zhenshu_Yuan - i) /16*LR_Accelerate.jump), font = 18})
		Text_break2:SetHAlign(1)
		Text_break2:SetVAlign(1)

		local Text_break3 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_3", i), {w = 90, h = 30, x =150, y = 2, text = sformat("%0.2f%%", YuZhi / jiasu ), font = 18})
		Text_break3:SetHAlign(1)
		Text_break3:SetVAlign(1)

		local Text_break4 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_4", i), {w = 90, h = 30, x =240, y = 2, text = YuZhi, font = 18})
		Text_break4:SetHAlign(1)
		Text_break4:SetVAlign(1)
	end
end



