local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local LanguagePath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local db_name = "maindb.db"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20180403"
---------------------------------------------
LR_AS_Equip = {}
LR_AS_Equip.Default = {
	bShowButtonInCharacterPanel = true,
	bAutoSaveWhenChangeEquipment = true,
}
LR_AS_Equip.UsrData = clone(LR_AS_Equip.Default)
RegisterCustomData("LR_AS_Equip.UsrData", VERSION)
--------------------------------------------

-----统一一下设置：套装的序号从0开始，分别为0,1,2,3
local _Equip = {
	EQUIPs = {},
}
_Equip.SelfData = {}
_Equip.AllUsrData = {}

_Equip.tEquipPos = {
	{position = EQUIPMENT_INVENTORY.BANGLE, name = "BANGLE", frameid = 60, }, -- 护臂
	{position = EQUIPMENT_INVENTORY.CHEST, name = "CHEST", frameid = 62, }, -- 上衣
	{position = EQUIPMENT_INVENTORY.WAIST, name = "WAIST", frameid = 69, }, -- 腰带
	{position = EQUIPMENT_INVENTORY.HELM, name = "HELM", frameid = 63, }, -- 头部
	{position = EQUIPMENT_INVENTORY.PANTS, name = "PANTS", frameid = 65, }, -- 裤子
	{position = EQUIPMENT_INVENTORY.BOOTS, name = "BOOTS", frameid = 67, }, -- 鞋子
	{position = EQUIPMENT_INVENTORY.AMULET, name = "AMULET", frameid = 66, }, -- 项链
	{position = EQUIPMENT_INVENTORY.LEFT_RING, name = "LEFT_RING", frameid = 61, }, -- 左手戒指
	{position = EQUIPMENT_INVENTORY.RIGHT_RING, name = "RIGHT_RING", frameid = 61, }, -- 右手戒指
	{position = EQUIPMENT_INVENTORY.PENDANT, name = "PENDANT", frameid = 57, }, -- 腰缀
	{position = EQUIPMENT_INVENTORY.MELEE_WEAPON, name = "MELEE_WEAPON", frameid = 64, }, -- 普通近战武器
	{position = EQUIPMENT_INVENTORY.RANGE_WEAPON, name = "RANGE_WEAPON", frameid = 58, }, -- 远程武器
	{position = EQUIPMENT_INVENTORY.ARROW, name = "ARROW", frameid = 59, }, -- 暗器
	{position = EQUIPMENT_INVENTORY.BIG_SWORD, name = "BIG_SWORD", frameid = 77, }, -- 重剑
}

function _Equip.GetSuitIndex(nLogicIndex)
	local player = GetClientPlayer()
	if not player then
		return
	end
	local nSuitIndex = player.GetEquipIDArray(nLogicIndex)
	local dwBox
	if nLogicIndex == 0 then
		dwBox = INVENTORY_INDEX.EQUIP
	else
		dwBox = INVENTORY_INDEX[sformat("EQUIP_BACKUP%d", nLogicIndex)]
	end
	return nSuitIndex, dwBox
end

--获取所有部位的装备
function _Equip.GetAllEquipBox() -- update boxes
	local player = GetClientPlayer()
	if not player then
		return
	end
	if IsRemotePlayer(player.dwID) then
		return
	end
	_Equip.SelfData = _Equip.SelfData or {}
	local SelfData = _Equip.SelfData
	local EQUIPMENT_SUIT_COUNT = 4
	for i = 0, EQUIPMENT_SUIT_COUNT - 1 do		---这里的0~3不是我们看到的装备套装位置的0~3
		local nSuitIndex , dwBox = _Equip.GetSuitIndex(i)
		SelfData[tostring(nSuitIndex)] = SelfData[tostring(nSuitIndex)] or {}
		local Suits = {}
		for k = 1, #_Equip.tEquipPos, 1 do
			local nType = _Equip.tEquipPos[k].position
			local szName = _Equip.tEquipPos[k].name
			Suits[szName] = {}
			local item = GetPlayerItem(player, dwBox, nType)
			if item then
				local t_item = {}
				t_item.dwID = item.dwID
				t_item.szName = item.szName
				t_item.nGenre = item.nGenre
				t_item.dwTabType = item.dwTabType
				t_item.dwIndex = item.dwIndex
				t_item.nQuality = item.nQuality
				t_item.nStackNum = 1
				if item.bCanStack then
					t_item.nStackNum = item.nStackNum
				end
				t_item.nVersion = item.nVersion
				t_item.nUiId = item.nUiId
				Suits[szName] = clone(t_item)
			end
		end
		SelfData[tostring(nSuitIndex)].equipment_data = clone(Suits)
	end
end

local EQUIPMENT_NOW_CACHE = {}
local EQUIPMENT_SUIT_NOW_CACHE = 0
function _Equip.GetEquiping()
	local me = GetClientPlayer()
	EQUIPMENT_NOW_CACHE = {}
	local Suits = {}
	for k = 1, #_Equip.tEquipPos, 1 do
		local nType = _Equip.tEquipPos[k].position
		local szName = _Equip.tEquipPos[k].name
		Suits[szName] = {}
		local item = GetPlayerItem(me, INVENTORY_INDEX.EQUIP, nType)
		if item then
			local t_item = {}
			t_item.dwID = item.dwID
			t_item.szName = item.szName
			t_item.nGenre = item.nGenre
			t_item.dwTabType = item.dwTabType
			t_item.dwIndex = item.dwIndex
			t_item.nQuality = item.nQuality
			t_item.nStackNum = 1
			if item.bCanStack then
				t_item.nStackNum = item.nStackNum
			end
			t_item.nVersion = item.nVersion
			t_item.nUiId = item.nUiId
			Suits[szName] = clone(t_item)
			EQUIPMENT_NOW_CACHE[nType] = item.dwID
		else
			EQUIPMENT_NOW_CACHE[nType] = 0
		end
	end
	return Suits
end

-------------------------------------------------------------------------
----------获取装分
--------------------------------------------------------------------------
function _Equip.GetEquipScore()
	local me = GetClientPlayer()
	if not me then
		return
	end

	local nIndex = me.GetEquipIDArray(0)
	local TotalEquipScore = me.GetTotalEquipScore()	--总分
	local BaseEquipScore = me.GetBaseEquipScore()	--基础分数
	local StrengthEquipScore = me.GetStrengthEquipScore()	--强化分数
	local MountsEquipScore = me.GetMountsEquipScore()	--镶嵌分数

	local score = {}
	score.TotalEquipScore = TotalEquipScore
	score.BaseEquipScore = BaseEquipScore
	score.StrengthEquipScore = StrengthEquipScore
	score.MountsEquipScore = MountsEquipScore

	local tFenLei, tContent, tTip = CharInfoMore_GetShowValue()
	local char_infomore = {}
	local k, flag = 0, true
	for i = 1, #tContent, 1 do
		if i > tFenLei[k + 1][2] then
			flag = true
			k = k +1
		end
		if flag then
			char_infomore[#char_infomore + 1] = {bText = true, value = tFenLei[k + 1][1],}
			char_infomore[#char_infomore + 1] = {bDevide = true,}
			flag = false
		end
		char_infomore[#char_infomore + 1] = {}
		char_infomore[#char_infomore].label = tContent[i][1]
		char_infomore[#char_infomore].value = tContent[i][2]
		char_infomore[#char_infomore].tip = tTip[tContent[i][3]]
	end

	_Equip.SelfData[tostring(nIndex)] = _Equip.SelfData[tostring(nIndex)] or {}
	_Equip.SelfData[tostring(nIndex)].score = clone(score)
	_Equip.SelfData[tostring(nIndex)].char_infomore = clone(char_infomore)
end

local DATA2BSAVE = {}
function _Equip.PrepareData()
	DATA2BSAVE = {}
	_Equip.GetAllEquipBox()
	_Equip.GetEquipScore()
	DATA2BSAVE = clone(_Equip.SelfData)
end

function _Equip.SaveData(DB)
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local data = DATA2BSAVE
	local DB_REPLACE = DB:Prepare("REPLACE INTO equipment_data ( szKey, nSuitIndex, equipment_data, score, char_infomoreV2, bDel ) VALUES ( ?, ?, ?, ?, ?, 0 )")
	local DB_REPLACE2 = DB:Prepare("REPLACE INTO equipment_data ( szKey, nSuitIndex, bDel ) VALUES ( ?, ?, 1 )")
	for nSuitIndex, v in pairs (data) do
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(unpack(g2d({szKey, nSuitIndex, LR.JsonEncode(v.equipment_data), LR.JsonEncode(v.score), LR.JsonEncode(v.char_infomore)})))
		DB_REPLACE:Execute()
	end
end

function _Equip.LoadData(DB, realArea, realServer, dwID)
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	local DB_SELECT = DB:Prepare("SELECT * FROM equipment_data WHERE szKey = ? AND bDel = 0 AND nSuitIndex IS NOT NULL")
	DB_SELECT:ClearBindings()
	DB_SELECT:BindAll(g2d(szKey))
	local Data = d2g(DB_SELECT:GetAll())
	local t = {}
	for k, v in pairs(Data) do
		t[v.nSuitIndex] = {}
		t[v.nSuitIndex].equipment_data = LR.JsonDecode(v.equipment_data)
		t[v.nSuitIndex].score = LR.JsonDecode(v.score)
		t[v.nSuitIndex].char_infomore = LR.JsonDecode(v.char_infomoreV2)
	end
	_Equip.AllUsrData[szKey] = clone(t)
	return t
end

function _Equip.LoadSelfData(DB)
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	_Equip.SelfData = clone(_Equip.LoadData(DB, realArea, realServer, me.dwID))
end

-------------------------------------------------------------------------
----------装备界面
--------------------------------------------------------------------------
LR_AS_Equip_Panel = _G2.CreateAddon("LR_AS_Equip_Panel")
LR_AS_Equip_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_AS_Equip_Panel.UserData = {
	Anchor = {s = "TOP", r = "TOP",  x = 10, y = 150},
}

LR_AS_Equip_Panel.BOX_Position = {
	{name = "BANGLE", x = 324, y = 70, h = 45, w = 45, cn_name = _L["BANGLE"], frameid = 60, }, 	-- 护臂
	{name = "BOOTS", x = 324, y = 170, h = 45, w = 45, cn_name = _L["BOOTS"], frameid = 67, }, -- 鞋子
	{name = "HELM", x = 12, y = 70, h = 45, w = 45, cn_name = _L["HELM"], frameid = 63, }, -- 头部
	{name = "CHEST", x = 12, y = 180, h = 45, w = 45, cn_name = _L["CHEST"], frameid = 62, }, -- 上衣
	{name = "WAIST", x = 12, y = 338, h = 45, w = 45, cn_name = _L["WAIST"], frameid = 69, }, -- 腰带
	{name = "PANTS", x = 324, y = 120, h = 45, w = 45, cn_name = _L["PANTS"], frameid = 65, }, -- 裤子
	{name = "AMULET", x = 324, y = 222, h = 45, w = 45, cn_name = _L["AMULET"], frameid = 66, }, -- 项链
	{name = "PENDANT", x = 324, y = 275, h = 45, w = 45, cn_name = _L["PENDANT"], frameid = 57, }, -- 腰缀
	{name = "LEFT_RING", x = 324, y = 325, h = 45, w = 45, cn_name = _L["LEFT_RING"], frameid = 61, }, -- 左手戒指
	{name = "RIGHT_RING", x = 324, y = 375, h = 45, w = 45, cn_name = _L["RIGHT_RING"], frameid = 61, }, -- 右手戒指
	{name = "RANGE_WEAPON", x = 185, y = 442, h = 45, w = 45, cn_name = _L["RANGE_WEAPON"], frameid = 58, }, -- 远程武器
	{name = "MELEE_WEAPON", x = 133, y = 442, h = 45, w = 45, cn_name = _L["MELEE_WEAPON"], frameid = 64, }, -- 普通近战武器
	{name = "BIG_SWORD", x = 80, y = 442, h = 45, w = 45, cn_name = _L["BIG_SWORD"], frameid = 77, }, -- 重剑
	{name = "ARROW", x = 237, y = 452, h = 30, w = 30, cn_name = _L["ARROW"], frameid = 59, }, -- 暗器
}

LR_AS_Equip_Panel.szName = nil
LR_AS_Equip_Panel.realServer = nil
LR_AS_Equip_Panel.realArea = nil
LR_AS_Equip_Panel.dwForceID = nil
LR_AS_Equip_Panel.dwID = nil


local CustomVersion = "20170111"
--RegisterCustomData("LR_BookRd_Panel.UserData", CustomVersion)

function LR_AS_Equip_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")

	LR_AS_Equip_Panel.UpdateAnchor(this)
	-------打开面板时保存数据
	_Equip.GetAllEquipBox()
	_Equip.GetEquipScore()
	local path = sformat("%s\\%s", SaveDataPath, db_name)
	local DB = LR.OpenDB(path, "AS_EQUIP_PANEL_CREATE_SAVE_6691DCA694DA04E2128D3D5ECE615B95")
	_Equip.SaveData(DB)
	LR.CloseDB(DB)

	RegisterGlobalEsc("LR_AS_Equip_Panel", function () return true end , function() LR_AS_Equip_Panel:Open() end)
end

function LR_AS_Equip_Panel:OnEvents(event)
	if event == "UI_SCALED" then
		LR_AS_Equip_Panel.UpdateAnchor(this)
	end
end

function LR_AS_Equip_Panel.UpdateAnchor(frame)
	frame:SetPoint(LR_AS_Equip_Panel.UserData.Anchor.x, LR_AS_Equip_Panel.UserData.Anchor.y)
	frame:CorrectPos()
end

function LR_AS_Equip_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_AS_Equip_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_AS_Equip_Panel:OnDragEnd()
	this:CorrectPos()
	--LR_AS_Equip_Panel.UserData.Anchor = GetFrameAnchor(this)
end

function LR_AS_Equip_Panel:Init()
	local frame = self:Append("Frame", "LR_AS_Equip_Panel", {title = _L["LR Equipment Statistics"], style = "SMALL"})
	local w, h = frame:GetSize()

	local Image_Icon = LR.AppendUI("Image", frame, "Image_Icon", {x = 5, y = 0, w = 36, h = 36})
	Image_Icon:FromUITex("ui\\Image\\Button\\SystemButton.UITex", 35)
	Image_Icon:SetAlpha(180)

	--------------人物选择
	local hComboBox = self:Append("ComboBox", frame, "hComboBox", {w = 160, x = 105, y = 45, text = LR_AS_Equip_Panel.szName})
	hComboBox:Enable(true)
	local fnAction = function(data)
		hComboBox:SetText(data.szName)
		local realArea = data.realArea
		local realServer = data.realServer
		local szName = data.szName
		local dwID = data.dwID
		local dwForceID = data.dwForceID
		LR_AS_Equip_Panel:ReLoadEquipSuit(szName, realArea, realServer, dwForceID, dwID)
		local TextServer = LR_AS_Equip_Panel:Fetch("TextServer")
		if TextServer then
			TextServer:SetText(sformat("%s@%s", realArea, realServer))
		end
	end
	hComboBox.OnClick = function (m)
		LR_AS_Base.PopupPlayerMenu(hComboBox, fnAction)
	end

	local TextServer = self:Append("Text", frame, "TextServer", {w = 160, h = 30, x = 105, y = 65})
	TextServer:SetVAlign(1):SetHAlign(1):SetText(sformat("%s@%s", LR_AS_Equip_Panel.realArea, LR_AS_Equip_Panel.realServer))

	local hIconViewContent = self:Append("Handle", frame, "IconViewContent", {x = 0, y = 12, w = 700, h = 300})
	local icon = self:Append("Image", hIconViewContent, "Icon_blank", {x = 0, y = 0, w = 45, h = 45, })
	icon:Hide()

	local hButton1 = self:Append("Button", frame, "Button1" , {w = 30, x = 280, y = 35, text = "1"})
	hButton1:Enable(true)
	hButton1.OnClick = function ()
		self:LoadEquipSuit(0)
	end
	local hButton2 = self:Append("Button", frame, "Button2" , {w = 30, x = 315, y = 35, text = "2"})
	hButton2:Enable(true)
	hButton2.OnClick = function ()
		self:LoadEquipSuit(1)
	end
	local hButton3 = self:Append("Button", frame, "Button3" , {w = 30, x = 280, y = 55, text = "3"})
	hButton3:Enable(true)
	hButton3.OnClick = function ()
		self:LoadEquipSuit(2)
	end
	local hButton4 = self:Append("Button", frame, "Button4" , {w = 30, x = 315, y = 55, text = "4"})
	hButton4:Enable(true)
	hButton4.OnClick = function ()
		self:LoadEquipSuit(3)
	end

	for i = 1, #LR_AS_Equip_Panel.BOX_Position do
		local szName = LR_AS_Equip_Panel.BOX_Position[i].name
		local px = LR_AS_Equip_Panel.BOX_Position[i].x
		local py = LR_AS_Equip_Panel.BOX_Position[i].y
		local ph = LR_AS_Equip_Panel.BOX_Position[i].h
		local pw = LR_AS_Equip_Panel.BOX_Position[i].w
		local frameid = LR_AS_Equip_Panel.BOX_Position[i].frameid

		local box = self:Append("Image", hIconViewContent, sformat("Box_%s", szName), {x = px-1, y = py-1, w = pw+2, h = ph+2, eventid = 277 })
		box:FromUITex("ui\\Image\\LootPanel\\LootPanel.UITex", frameid)
		box:SetAlpha(140)
		box.OnEnter = function()
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local szXml = GetFormatText(LR_AS_Equip_Panel.BOX_Position[i].cn_name, 0, 255, 128, 0)
			OutputTip(szXml, 350, {x, y, w, h})
		end
		box.OnLeave = function()
			HideTip()
		end

		local icon = self:Append("Image", hIconViewContent, sformat("Icon_%s", szName), {x = px, y = py, w = pw, h = ph, eventid = 277})
		--icon:FromUITex("ui\\Image\\Common\\Box.UITex", 11)
		icon:Hide()

		local Border = self:Append("Image", hIconViewContent, sformat("Border_%s", szName), {x = px, y = py, w = pw, h = ph, })
		Border:Hide()

		local OrangeBox = self:Append("Animate", hIconViewContent, sformat("OrangeBox_%s", szName), {x = px, y = py, w = pw, h = ph, })
		OrangeBox:SetAnimate("ui\\Image\\Common\\Box.UITex", 17)
		OrangeBox:Hide()
	end

	local Text_Equip = self:Append("Text", hIconViewContent, "Text_Equip", {x = 100, y = 75, w = 260, h = 33, text  = "", font  = 64})
	Text_Equip:SetMultiLine(true)
	Text_Equip:AutoSize()
	Text_Equip:SetRichText(true)
	Text_Equip:SetVAlign(0)
	Text_Equip:SetHAlign(0)


	local TipButton = self:Append("Button", frame, "TipButton" , {w = 80, x = 10, y = 45, text = _L["Desc"]})
	TipButton:Enable(true)
	TipButton.OnEnter = function ()
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local Tip = {
			_L["You can only see original attribute of others"],
		}
		for i = 1, #Tip, 1 do
			Tip[i] = GetFormatText(Tip[i] , 0, 255, 128, 0)
		end
		local szXml = tconcat(Tip)
		OutputTip(szXml, 350, {x, y, w, h})
	end
	TipButton.OnLeave = function()
		HideTip()
	end

	local tt = self:Append("Text", frame, "tt", {x = 10, y = 420, w = 180, h = 33, text  = _L["You can only see original attribute of others"], font  = 169})

	----------关于
	LR.AppendAbout(LR_AS_Equip_Panel, frame)

	---属性
	local charinfo_handle = Wnd.OpenWindow("interface\\LR_Plugin\\LR_AccountStatistics\\UI\\WndFrameThin.ini", "charinfo_frame"):Lookup("Wnd_Window")
	charinfo_handle:ChangeRelation(frame:GetSelf(), true, true)
	charinfo_handle:SetName("WndWindow_Charinfo")
	Wnd.CloseWindow("charinfo_frame")

	local WndWindow_Charinfo = frame:Lookup("WndWindow_Charinfo")
	WndWindow_Charinfo:SetRelPos(w - 5, 0)
	local w2, h2 = WndWindow_Charinfo:GetSize()
	frame:SetSize(w + w2, h2)
	WndWindow_Charinfo:Lookup("","Text_Title"):SetText(_L["charinfo"])
	local Image_Equipment = LR.AppendUI("Image", WndWindow_Charinfo:Lookup("",""), "Image_Equipment", {w = 106, h = 103, x = 3, y = 30})
	Image_Equipment:FromUITex("ui\\image\\uicommon\\commonpanel7.uitex", 23)

	local Image_Devide2 = LR.AppendUI("Image", WndWindow_Charinfo:Lookup("",""), "Image_Devide2", {w = 212, h = 371, x = 11, y = 126})
	Image_Devide2:FromUITex("ui\\image\\minimap\\mapmark.uitex", 50)
	Image_Devide2:SetImageType(10)

	local Text_Equipmentscore = LR.AppendUI("Text", WndWindow_Charinfo:Lookup("",""), "Text_Equipmentscore", {w = 62, h = 20, x = 106, y = 58, text = _L["Equipmentscore"]})
	local Text_score = LR.AppendUI("Text", WndWindow_Charinfo:Lookup("",""), "Text_score", {w = 100, h = 30, x = 106, y = 81, text = ""})
	Text_score:SetFontScheme(200)

	local hScroll = LR.AppendUI("Scroll", WndWindow_Charinfo, "Scroll", {x = 23, y = 135, w = 200, h = 360})
	LR_AS_Equip_Panel.Scroll = hScroll

	local realArea = LR_AS_Equip_Panel.realArea
	local realServer = LR_AS_Equip_Panel.realServer
	local szName = LR_AS_Equip_Panel.szName
	local dwID = LR_AS_Equip_Panel.dwID
	if szName == GetClientPlayer().szName and dwID == GetClientPlayer().dwID then
		LR_AS_Equip_Panel:LoadEquipSuit(GetClientPlayer().GetEquipIDArray(0))
	else
		LR_AS_Equip_Panel:LoadEquipSuit(0)
	end
end

function LR_AS_Equip_Panel:Open(szName, realArea, realServer, dwForceID, dwID)
	local frame = self:Fetch("LR_AS_Equip_Panel")
	if szName then
		if frame then
			LR_AS_Equip_Panel:ReLoadEquipSuit(szName, realArea, realServer, dwForceID, dwID)
		else
			LR_AS_Equip_Panel.realArea = realArea
			LR_AS_Equip_Panel.realServer = realServer
			LR_AS_Equip_Panel.szName = szName
			LR_AS_Equip_Panel.dwID = dwID
			LR_AS_Equip_Panel.dwForceID = dwForceID
			frame = self:Init()
		end
	else
		if frame then
			self:Destroy(frame)
		else
			local me = GetClientPlayer()
			local ServerInfo = {GetUserServer()}
			local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
			LR_AS_Equip_Panel.szName = me.szName
			LR_AS_Equip_Panel.realServer = realServer
			LR_AS_Equip_Panel.dwForceID = me.dwForceID
			LR_AS_Equip_Panel.realArea = realArea
			LR_AS_Equip_Panel.dwID = me.dwID
			frame = self:Init()
		end
	end
end

function LR_AS_Equip_Panel:ReLoadEquipSuit(szName, realArea, realServer, dwForceID, dwID)
	local frame = self:Fetch("LR_AS_Equip_Panel")
	if frame then
		LR_AS_Equip_Panel.realArea = realArea
		LR_AS_Equip_Panel.realServer = realServer
		LR_AS_Equip_Panel.szName = szName
		LR_AS_Equip_Panel.dwID = dwID
		LR_AS_Equip_Panel.dwForceID = dwForceID
		LR_AS_Equip_Panel:LoadEquipSuit(0)
	end
end

function LR_AS_Equip_Panel.OnItemLinkDown(item, ui)
	ui.nVersion = item.nVersion
	ui.dwTabType = item.dwTabType
	ui.dwIndex = item.dwIndex
	ui.dwID = item.dwID
	if item.nGenre == ITEM_GENRE.BOOK then
		ui.nBookRecipeID = BookID2GlobelRecipeID(GlobelRecipeID2BookID(item.nBookID))
		ui:SetName("booklink")
	else
		ui:SetName("itemlink")
	end
	return OnItemLinkDown(ui)
end

function LR_AS_Equip_Panel:Output()
	--Output("22")
end


function LR_AS_Equip_Panel:LoadCharscore(nIndex)
	local player = GetClientPlayer()
	if not player then
		return
	end
	local nIndex = nIndex or 0
	local realArea = LR_AS_Equip_Panel.realArea
	local realServer = LR_AS_Equip_Panel.realServer
	local szName = LR_AS_Equip_Panel.szName
	local dwID = LR_AS_Equip_Panel.dwID
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area2, Server2, realArea2, realServer2 = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local data
	if not realArea or realArea2 == realArea and realServer2 == realServer and me.dwID == dwID then
		data = clone(_Equip.SelfData)
	else
		data = clone(_Equip.AllUsrData[szKey])
	end
	local data2 = data[tostring(nIndex)] or {}
	local score = data2.score or {}

	local frame = Station.Lookup("Normal/LR_AS_Equip_Panel")
	local WndWindow_Charinfo = frame:Lookup("WndWindow_Charinfo")
	local hCharinfo = WndWindow_Charinfo:Lookup("","")
	local Text_Equipmentscore = hCharinfo:Lookup("Text_score")

	Text_Equipmentscore:SetText(score.TotalEquipScore or "")

	local hScroll = LR_AS_Equip_Panel.Scroll
	hScroll:ClearHandle()
	local char_infomore = data2.char_infomore or {}

	if next(char_infomore) ~= nil then
		for k, v in pairs(char_infomore or {}) do
			if v.bDevide then
--[[				local handle = LR.AppendUI("Handle", hScroll, sformat("Handle2_%d", k), {w = 210, h = 8})
				local Image_Divide = LR.AppendUI("Image", handle, sformat("Image2_Divide_%d", k), {x = 0, y = 0, w = 210, h = 8})
				Image_Divide:FromUITex("ui\\Image\\uicommon\\commonpanel.UITex", 45)]]
			elseif v.bText then
				local handle = LR.AppendUI("Handle", hScroll, sformat("Handle2_%d", k), {w = 210, h = 30})
				local Image_Divide = LR.AppendUI("Image", handle, sformat("Image2_Divide_%d", k), {x = 0, y = 0, w = 190, h = 30})
				Image_Divide:SetAlpha(180)
				Image_Divide:FromUITex("ui\\Image\\uicommon\\commonpanel2.UITex", 14)
				local Text = LR.AppendUI("Text", handle, sformat("Text2_%d", k), {x = 5, y = 0, w = 210, h = 30, text = v.value})
				Text:SetVAlign(1)
				Text:SetFontScheme(27)
--[[
				local handle = LR.AppendUI("Handle", hScroll, sformat("Handle2_%d", k), {w = 210, h = 20})
				local Text = LR.AppendUI("Text", handle, sformat("Text2_%d", k), {x = 0, y = 0, w = 210, h = 20, text = v.value})
				Text:SetFontScheme(27)]]
			else
				local handle = LR.AppendUI("Handle", hScroll, sformat("Handle2_%d", k), {w = 210, h = 25})
				local Text_Label = LR.AppendUI("Text", handle, sformat("Text2_Label_%d", k), {x = 0, y = 0, w = 125, h = 25, text = v.label})
				local Text_Value = LR.AppendUI("Text", handle, sformat("Text2_Value_%d", k), {x = 120 , y = 0, w = 80, h = 25, text = v.value})
				handle.OnEnter = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					OutputTip(v.tip, 720, {x, y, w, h})
				end

				handle.OnLeave = function()
					HideTip()
				end
			end
		end
	else
		Text_Equipmentscore:SetText("--")
		local handle = LR.AppendUI("Handle", hScroll, "Handle2_nodata", {w = 220, h = 20})
		local Text = LR.AppendUI("Text", handle, "Text2_nodata", {x = 0, y = 0, w = 220, h = 20, text = _L["No data"]})
	end

	hScroll:UpdateList()
end


function LR_AS_Equip_Panel:LoadEquipSuit(nIndex)
	local nIndex = nIndex
	for i = 1, 4 do
		local bButton = LR_AS_Equip_Panel:Fetch(sformat("Button%d", i))
		if nIndex == (i - 1) then
			bButton:SetFontScheme(17)
		else
			bButton:SetFontScheme(18)
		end
	end
	local player = GetClientPlayer()
	if not player then
		return
	end

	local realArea = LR_AS_Equip_Panel.realArea
	local realServer = LR_AS_Equip_Panel.realServer
	local szName = LR_AS_Equip_Panel.szName
	local dwID = LR_AS_Equip_Panel.dwID

	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area2, Server2, realArea2, realServer2 = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local data
	if not realArea or realArea2 == realArea and realServer2 == realServer and me.dwID == dwID then
		data = clone(_Equip.SelfData)
		_Equip.AllUsrData[sformat("%s_%s_%d", realArea, realServer, dwID)] = clone(data)
	else
		local path = sformat("%s\\%s", SaveDataPath, db_name)
		local DB = LR.OpenDB(path, "EQUIP_PANEL_LOAD_DATA_C62538E1E3693CC1B81363C0C7A826F3")
		data = _Equip.LoadData(DB, realArea, realServer, dwID)
		LR.CloseDB(DB)
	end

	local data2 = data[tostring(nIndex)] or {}
	local EQUIPs = data2.equipment_data or {}
	if next(EQUIPs)~= nil then
		local tText = {}
		local _text = LR_AS_Equip_Panel:Fetch("Text_Equip")
		for i = 1, #LR_AS_Equip_Panel.BOX_Position, 1 do
			local szName = LR_AS_Equip_Panel.BOX_Position[i].name
			local partName = LR_AS_Equip_Panel.BOX_Position[i].cn_name
			local box = LR_AS_Equip_Panel:Fetch(sformat("Box_%s", szName))
			local Icon = LR_AS_Equip_Panel:Fetch(sformat("Icon_%s", szName))
			local Border = LR_AS_Equip_Panel:Fetch(sformat("Border_%s", szName))
			local OrangeBox = LR_AS_Equip_Panel:Fetch(sformat("OrangeBox_%s", szName))
			if LR_AS_Equip_Panel.dwForceID ~= 8 and  szName == "BIG_SWORD" then
				box:Hide()
				Icon:Hide()
				Border:Hide()
				OrangeBox:Hide()
			else
				box:Show()
			end

			if Icon and Border then
				if next(EQUIPs[szName]) ~= nil then
					local item = EQUIPs[szName]
					if item.dwID ~= nil then
						local IconID = Table_GetItemIconID(item.nUiId)
						Icon:FromIconID(IconID)
						Icon:Show()
						Icon.OnEnter = function()
							local nMouseX, nMouseY = Cursor.GetPos()
							local itm = GetItem(item.dwID)
							if not itm then
								OutputItemTip(UI_OBJECT_ITEM_INFO, GLOBAL.CURRENT_ITEM_VERSION, item.dwTabType, item.dwIndex, {nMouseX, nMouseY, 0, 0})
							else
								OutputItemTip(UI_OBJECT_ITEM_ONLY_ID, item.dwID, nil, nil, {nMouseX, nMouseY, 0, 0})
							end
						end
						Icon.OnLeave = function()
							HideTip()
						end
						Icon.OnClick = function()
							LR_AS_Equip_Panel.OnItemLinkDown(item, this)
						end

						if item.nQuality == 5 then
							Border:FromUITex("ui\\Image\\Common\\Box.UITex", 44)
							Border:Show()
							OrangeBox:Show()
						elseif item.nQuality == 4 then
							Border:FromUITex("ui\\Image\\Common\\Box.UITex", 42)
							Border:Show()
							OrangeBox:Hide()
						elseif item.nQuality == 3 then
							Border:FromUITex("ui\\Image\\Common\\Box.UITex", 43)
							Border:Show()
							OrangeBox:Hide()
						else
							Border:Hide()
							OrangeBox:Hide()
						end
						tText[#tText+1] = sformat("%s：%s\n", partName, item.szName)
					else
						Icon:Hide()
						Border:Hide()
						OrangeBox:Hide()
					end
				else
					Icon:Hide()
					Border:Hide()
					OrangeBox:Hide()
				end
			end
			_text:SetText(tconcat(tText))
		end
	else
		for i = 1, #LR_AS_Equip_Panel.BOX_Position, 1 do
			local szName = LR_AS_Equip_Panel.BOX_Position[i].name
			local Icon = LR_AS_Equip_Panel:Fetch(sformat("Icon_%s", szName))
			local Border = LR_AS_Equip_Panel:Fetch(sformat("Border_%s", szName))
			local OrangeBox = LR_AS_Equip_Panel:Fetch(sformat("OrangeBox_%s", szName))
			local _text = LR_AS_Equip_Panel:Fetch("Text_Equip")
			if Icon then
				Icon:Hide()
				Border:Hide()
				OrangeBox:Hide()
				_text:SetText("")
			end
		end
	end
	self:LoadCharscore(nIndex)
end


------------------------------------------------------------------
-----Hook
------------------------------------------------------------------
function _Equip.OpenPanel()
	local me = GetClientPlayer()
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local dwForceID = me.dwForceID
	local dwID = me.dwID
	local szName = me.szName
	LR_AS_Equip_Panel:Open(szName, realArea, realServer, dwForceID, dwID)
end

function _Equip.Hook()
	local frame = Station.Lookup("Normal/CharacterPanel")
	if frame then --背包界面添加一个按钮
		local Btn_Equipment = frame:Lookup("LR_Btn_Equipment")
		if Btn_Equipment then
			Btn_Equipment:Destroy()
		end
		if LR_AS_Equip.UsrData.bShowButtonInCharacterPanel then
			local Btn_Equipment = LR.AppendUI("UIButton", frame, "LR_Btn_Equipment", {x = 45 , y = 0 , w = 36 , h = 36, ani = {"ui\\Image\\Button\\SystemButton.UITex", 35, 36, 37, 38}})
			Btn_Equipment:SetAlpha(180)
			Btn_Equipment.OnClick = function()
				_Equip.OpenPanel()
			end
			Btn_Equipment.OnEnter = function()
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				local szTip = {}
				szTip[#szTip+1] = GetFormatText(sformat("%s\n", _L["LR Equipment Statistics"]), 163)
				szTip[#szTip+1] = GetFormatText(_L["Click to open LR Equipment Statistics Panel"], 162)
				OutputTip(tconcat(szTip), 400, {x, y, w, h})
			end
			Btn_Equipment.OnLeave = function()
				HideTip()
			end
		end

		--用于切换装备时屏蔽EQUIP_ITEM_UPDATE事件的响应
		local Page_Battle = frame:Lookup("PageSet_Main"):Lookup("Page_Battle")
		if Page_Battle then
			for i = 1, 4, 1 do
				local CheckBox_PageNum = Page_Battle:Lookup(sformat("CheckBox_PageNum%d", i))
				if CheckBox_PageNum then
					CheckBox_PageNum.OnLButtonClick = function()
						if EQUIPMENT_SUIT_NOW_CACHE ~= i - 1 then
							_Equip.bLock = true
						end
					end
				end
			end
		end
	end
end

-----切换套装EQUIP_CHANGE
function _Equip.EQUIP_CHANGE()
	local me = GetClientPlayer()
	if me.bFightState then
		return
	end
	--获取装备、装分、属性
	--LR.DelayCall(100, function()
		LR.Log("[LR] EQUIP_CHANGE, get score...")
		_Equip.GetEquipScore()
		--保存
		if LR_AS_Equip.UsrData.bAutoSaveWhenChangeEquipment then
			local t = GetTickCount()
			LR.Log("[LR] EQUIP_CHANGE, auto save data begin...")
			_Equip.PrepareData()
			local path = sformat("%s\\%s", SaveDataPath, db_name)
			local DB = LR.OpenDB(path, "EQUIP_CHANGE_SAVE_DATA_BB77392CC5A9D92DF1011413EE07D945")
			_Equip.SaveData(DB)
			LR.CloseDB(DB)
			LR.Log(sformat("[LR] EQUIP_CHANGE, auto save data end..., cost %d ms", GetTickCount() - t))
		end
	--end)
	EQUIPMENT_SUIT_NOW_CACHE = GetClientPlayer().GetEquipIDArray(0)
	_Equip.bLock = false
end

---更换装备
--[[
arg0:	INVENTORY_INDEX.EQUIP	类型
arg1:	EQUIPMENT_INVENTORY.MELEE_WEAPON 更换的部位
--
local nBoxIndex = arg0
local nItemIndex = arg1
]]
function _Equip.EQUIP_ITEM_UPDATE()
	if _Equip.bLock then
		return
	end
	local me = GetClientPlayer()
	if me.bFightState then
		return
	end
	LR.Log("[LR] EQUIP_ITEM_UPDATE begin")
	local t = GetTickCount()
	local dwBox, dwX = arg0, arg1
	local item = GetPlayerItem(me, dwBox, dwX)
	if item then
		if EQUIPMENT_NOW_CACHE[dwX] ~= item.dwID then
			LR.Log(sformat("[LR] Equiped item, %d_%d, [%s], get score", item.dwTabType, item.dwIndex, item.szName))
			_Equip.GetEquipScore()
		end
	end
	LR.Log(sformat("[LR] EQUIP_ITEM_UPDATE end, cost %d ms", GetTickCount() - t))
end

function _Equip.FIRST_LOADING_END(DB)
	_Equip.LoadSelfData(DB)
	_Equip.GetAllEquipBox()
	_Equip.GetEquipScore()
end

function _Equip.FIRST_LOADING_END2()
	--和_Equip.FIRST_LOADING_END区分，_Equip.FIRST_LOADING_END用于通用数据处理
	if LR_AS_Equip.UsrData.bShowButtonInCharacterPanel then
		_Equip.Hook()
	end

	EQUIPMENT_SUIT_NOW_CACHE = GetClientPlayer().GetEquipIDArray(0)
end

function _Equip.ON_FRAME_CREATE()
	local frame = arg0
	local szName = frame:GetName()
	if szName  ==  "CharacterPanel" then
		_Equip.Hook()
	end
end

LR.RegisterEvent("FIRST_LOADING_END", function() _Equip.FIRST_LOADING_END2() end)
LR.RegisterEvent("EQUIP_CHANGE", function() _Equip.EQUIP_CHANGE() end)
LR.RegisterEvent("EQUIP_ITEM_UPDATE", function() _Equip.EQUIP_ITEM_UPDATE() end)		--去除，装备耐久，受缴械等都会触发，不可控，会卡的
LR.RegisterEvent("ON_FRAME_CREATE", function() _Equip.ON_FRAME_CREATE() end)
--注册模块
LR_AS_Module.EquipmentRecord = {}
LR_AS_Module.EquipmentRecord.PrepareData = _Equip.PrepareData
LR_AS_Module.EquipmentRecord.SaveData = _Equip.SaveData
LR_AS_Module.EquipmentRecord.FIRST_LOADING_END = _Equip.FIRST_LOADING_END

LR_AS_Equip.Hook = _Equip.Hook

----------
--[[
装备统计模块
因为只能获得当前装备的装分和属性，所以
登录时先从数据库载入装备信息，并获取一波当前的1-4套装备信息以及装分信息。此后装分信息只在切套装或者换装备时更新，不再读取数据库
切套装或者换装备时更新装备的装分信息(物品信息可以不更新)
在自动保存时，先刷所有的1-4套的装备信息，以及当前套装的装分信息，然后保存

根据测试，EQUIP_ITEM_UPDATE事件在EQUIP_CHANGE事件之前发生
]]

