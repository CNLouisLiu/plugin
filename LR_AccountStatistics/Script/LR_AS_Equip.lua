local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin\\@DATA\\LR_AccountStatistics\\UsrData"
local DB_name = "maindb.db"
local _L = LR.LoadLangPack(AddonPath)
local sformat, slen, sgsub, ssub, sfind = string.format, string.len, string.gsub, string.sub, string.find
local mfloor, mceil, mmin, mmax = math.floor, math.ceil, math.min, math.max
local tconcat, tinsert, tremove, tsort = table.concat, table.insert, table.remove, table.sort
----------------------------------------------------------
-----ͳһһ�����ã���װ����Ŵ�0��ʼ���ֱ�Ϊ0,1,2,3
-----


LR_AccountStatistics_Equip = LR_AccountStatistics_Equip or {
	EQUIPs = {},
}
LR_AccountStatistics_Equip.SelfData = {}
LR_AccountStatistics_Equip.AllUsrData = {}



LR_AccountStatistics_Equip.tEquipPos = {
	{position = EQUIPMENT_INVENTORY.BANGLE, name = "BANGLE", frameid = 60, }, -- ����
	{position = EQUIPMENT_INVENTORY.CHEST, name = "CHEST", frameid = 62, }, -- ����
	{position = EQUIPMENT_INVENTORY.WAIST, name = "WAIST", frameid = 69, }, -- ����
	{position = EQUIPMENT_INVENTORY.HELM, name = "HELM", frameid = 63, }, -- ͷ��
	{position = EQUIPMENT_INVENTORY.PANTS, name = "PANTS", frameid = 65, }, -- ����
	{position = EQUIPMENT_INVENTORY.BOOTS, name = "BOOTS", frameid = 67, }, -- Ь��
	{position = EQUIPMENT_INVENTORY.AMULET, name = "AMULET", frameid = 66, }, -- ����
	{position = EQUIPMENT_INVENTORY.LEFT_RING, name = "LEFT_RING", frameid = 61, }, -- ���ֽ�ָ
	{position = EQUIPMENT_INVENTORY.RIGHT_RING, name = "RIGHT_RING", frameid = 61, }, -- ���ֽ�ָ
	{position = EQUIPMENT_INVENTORY.PENDANT, name = "PENDANT", frameid = 57, }, -- ��׺
	{position = EQUIPMENT_INVENTORY.MELEE_WEAPON, name = "MELEE_WEAPON", frameid = 64, }, -- ��ͨ��ս����
	{position = EQUIPMENT_INVENTORY.RANGE_WEAPON, name = "RANGE_WEAPON", frameid = 58, }, -- Զ������
	{position = EQUIPMENT_INVENTORY.ARROW, name = "ARROW", frameid = 59, }, -- ����
	{position = EQUIPMENT_INVENTORY.BIG_SWORD, name = "BIG_SWORD", frameid = 77, }, -- �ؽ�
}

function LR_AccountStatistics_Equip.GetSuitIndex (nLogicIndex)
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

function LR_AccountStatistics_Equip.GetAllEquipBox() -- update boxes
	local player = GetClientPlayer()
	if not player then
		return
	end
	if IsRemotePlayer(player.dwID) then
		return
	end
	LR_AccountStatistics_Equip.SelfData = LR_AccountStatistics_Equip.SelfData or {}
	local SelfData = LR_AccountStatistics_Equip.SelfData
	local EQUIPMENT_SUIT_COUNT = 4
	for i = 0, EQUIPMENT_SUIT_COUNT - 1 do
		local nSuitIndex , dwBox = LR_AccountStatistics_Equip.GetSuitIndex (i)
		SelfData[tostring(nSuitIndex)] = SelfData[tostring(nSuitIndex)] or {}
		local Suits = {}
		for k = 1, #LR_AccountStatistics_Equip.tEquipPos, 1 do
			local nType = LR_AccountStatistics_Equip.tEquipPos[k].position
			local szName = LR_AccountStatistics_Equip.tEquipPos[k].name
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

-------------------------------------------------------------------------
----------��ȡװ��
--------------------------------------------------------------------------
local charinfo_frame_flag = 0	--0��ԭ��Ϊ�ر�״̬ 1��ԭ��Ϊ��״̬ (����) 2��ԭ��Ϊ��״̬���ɼ���
local charinfomore_frame_flag = 0	--ͬ��
function LR_AccountStatistics_Equip.GetEquipScore()
	local player = GetClientPlayer()
	if not player then
		return
	end
	----�򿪽���
	local charinfo_frame = Station.Lookup("Normal/CharInfo")
	if not charinfo_frame then
		charinfo_frame_flag = 0
		Wnd.OpenWindow("CharInfo"):Hide()
		local CharacterPanel_frame = Station.Lookup("Normal/CharacterPanel")
		CharacterPanel_frame:SetSize(610, 535)
	elseif not charinfo_frame:IsVisible() then
		charinfo_frame_flag = 1
	else
		charinfo_frame_flag = 2
	end

	local charinfomore_frame = Station.Lookup("Normal/CharInfoMore")
	if not charinfomore_frame then
		charinfomore_frame_flag = 0
		Wnd.OpenWindow("CharInfoMore"):SetRelPos(-500, -500)
		local CharacterPanel_frame = Station.Lookup("Normal/CharacterPanel")
		CharacterPanel_frame:SetSize(840, 535)
	elseif not charinfomore_frame:IsVisible() then
		charinfomore_frame_flag = 1
	else
		charinfomore_frame_flag = 2
	end

	LR.DelayCall(500,function()
		local nIndex = player.GetEquipIDArray(0)
		local TotalEquipScore = player.GetTotalEquipScore()	--�ܷ�
		local BaseEquipScore = player.GetBaseEquipScore()	--��������
		local StrengthEquipScore = player.GetStrengthEquipScore()	--ǿ������
		local MountsEquipScore = player.GetMountsEquipScore()	--��Ƕ����

		---��ȡ����
		local charinfo_frame = Station.Lookup("Normal/CharInfo")
		local PVEscore, PVPscore
		local data2 = {}
		if charinfo_frame then
			local charinfo_handle = charinfo_frame:Lookup("","")
			PVEscore = charinfo_handle:Lookup("Text_PVEValue"):GetText()
			PVPscore = charinfo_handle:Lookup("Text_PVPValue"):GetText()
			local handle = charinfo_frame:Lookup("WndScroll_Property", "")
			for i = 0, handle:GetVisibleItemCount() -1 do
				local h = handle:Lookup(i)
				data2[#data2+1] = {
					szTip = h.szTip,
					label = h:Lookup("Text_ClassInfoLabel"):GetText(),
					value = h:Lookup("Text_ClassInfoValue"):GetText(),
				}
			end
		else
			--Output("ss")
		end

		--��ȡ��������
		local charinfomore_frame = Station.Lookup("Normal/CharInfoMore")
		local data3 = {}
		if charinfomore_frame then
			local handle3 = charinfomore_frame:Lookup("WndScroll_Property", "")
			for i = 0, handle3:GetVisibleItemCount() -1 do
				local h = handle3:Lookup(i)
				if h:GetName() == "Handle_Text" then
					data3[#data3+1] = {
						bText = true,
						value = h:Lookup("Text_GroupName"):GetText(),
					}
				elseif h:GetName() == "Handle_Divide" then
					data3[#data3+1] = { bDivide = true,}
				else
					if h:Lookup("Text_ClassInfoValue"):GetText() ~= "9999" then
						data3[#data3+1] = {
							label = h:Lookup("Text_ClassInfoLabel"):GetText(),
							value = h:Lookup("Text_ClassInfoValue"):GetText(),
						}
					end
				end
			end
			if charinfomore_frame_flag == 0 then
				Wnd.CloseWindow("CharInfoMore")
				local CharacterPanel_frame = Station.Lookup("Normal/CharacterPanel")
				CharacterPanel_frame:SetSize(610, 535)
			elseif charinfomore_frame_flag == 1 then
				charinfomore_frame:Hide()
			end
		else
			--Output("xx")
		end

		local score = {}
		score.TotalEquipScore = TotalEquipScore
		score.BaseEquipScore = BaseEquipScore
		score.StrengthEquipScore = StrengthEquipScore
		score.MountsEquipScore = MountsEquipScore
		score.PVEscore = PVEscore
		score.PVPscore = PVPscore

		local char_info = clone(data2)
		local char_infomore = clone(data3)

		LR_AccountStatistics_Equip.SelfData[tostring(nIndex)] = LR_AccountStatistics_Equip.SelfData[tostring(nIndex)] or {}
		LR_AccountStatistics_Equip.SelfData[tostring(nIndex)].score = clone(score)
		LR_AccountStatistics_Equip.SelfData[tostring(nIndex)].char_info = clone(char_info)
		LR_AccountStatistics_Equip.SelfData[tostring(nIndex)].char_infomore = clone(char_infomore)

		LR_AccountStatistics_Equip.SaveData(DB)
	end)
end

function LR_AccountStatistics_Equip.SaveData(DB)
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local SelfData = LR_AccountStatistics_Equip.SelfData
	local DB_REPLACE = DB:Prepare("REPLACE INTO equipment_data ( szKey, nSuitIndex, equipment_data, score, char_info, char_infomore, bDel ) VALUES ( ?, ?, ?, ?, ?, ?, 0 )")
	local DB_REPLACE2 = DB:Prepare("REPLACE INTO equipment_data ( szKey, nSuitIndex, bDel ) VALUES ( ?, ?, 1 )")
	for nSuitIndex, v in pairs (SelfData) do
		if true then
		--if LR_AccountStatistics.UsrData.OthersCanSee then
			DB_REPLACE:ClearBindings()
			DB_REPLACE:BindAll(szKey, nSuitIndex, LR.JsonEncode(v.equipment_data), LR.JsonEncode(v.score), LR.JsonEncode(v.char_info), LR.JsonEncode(v.char_infomore))
			DB_REPLACE:Execute()
		else
			DB_REPLACE2:ClearBindings()
			DB_REPLACE2:BindAll(szKey, nSuitIndex)
			DB_REPLACE2:Execute()
		end
	end
end

function LR_AccountStatistics_Equip.LoadData(DB, realArea, realServer, dwID)
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	local DB_SELECT = DB:Prepare("SELECT * FROM equipment_data WHERE szKey = ? AND bDel = 0")
	DB_SELECT:ClearBindings()
	DB_SELECT:BindAll(szKey)
	local Data = DB_SELECT:GetAll() or {}
	local t = {}
	for k, v in pairs(Data) do
		t[v.nSuitIndex] = {}
		t[v.nSuitIndex].equipment_data = LR.JsonDecode(v.equipment_data)
		t[v.nSuitIndex].score = LR.JsonDecode(v.score)
		t[v.nSuitIndex].char_info = LR.JsonDecode(v.char_info)
		t[v.nSuitIndex].char_infomore = LR.JsonDecode(v.char_infomore)
	end
	LR_AccountStatistics_Equip.AllUsrData[szKey] = clone(t)
	return t
end

function LR_AccountStatistics_Equip.LoadSelfData(DB)
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	LR_AccountStatistics_Equip.SelfData = clone(LR_AccountStatistics_Equip.LoadData(DB, realArea, realServer, me.dwID))
	LR_AccountStatistics_Equip.GetAllEquipBox()
	LR_AccountStatistics_Equip.AllUsrData[szKey] = clone(LR_AccountStatistics_Equip.SelfData)
end


-------------------------------------------------------------------------
----------װ������
--------------------------------------------------------------------------
LR_AS_Equip_Panel = CreateAddon("LR_AS_Equip_Panel")
LR_AS_Equip_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_AS_Equip_Panel.UserData = {
	Anchor = {s = "TOP", r = "TOP",  x = 10, y = 150},
}

LR_AS_Equip_Panel.BOX_Position = {
	{name = "BANGLE", x = 324, y = 70, h = 45, w = 45, cn_name = _L["BANGLE"], frameid = 60, }, 	-- ����
	{name = "BOOTS", x = 324, y = 170, h = 45, w = 45, cn_name = _L["BOOTS"], frameid = 67, }, -- Ь��
	{name = "HELM", x = 12, y = 70, h = 45, w = 45, cn_name = _L["HELM"], frameid = 63, }, -- ͷ��
	{name = "CHEST", x = 12, y = 180, h = 45, w = 45, cn_name = _L["CHEST"], frameid = 62, }, -- ����
	{name = "WAIST", x = 12, y = 338, h = 45, w = 45, cn_name = _L["WAIST"], frameid = 69, }, -- ����
	{name = "PANTS", x = 324, y = 120, h = 45, w = 45, cn_name = _L["PANTS"], frameid = 65, }, -- ����
	{name = "AMULET", x = 324, y = 222, h = 45, w = 45, cn_name = _L["AMULET"], frameid = 66, }, -- ����
	{name = "PENDANT", x = 324, y = 275, h = 45, w = 45, cn_name = _L["PENDANT"], frameid = 57, }, -- ��׺
	{name = "LEFT_RING", x = 324, y = 325, h = 45, w = 45, cn_name = _L["LEFT_RING"], frameid = 61, }, -- ���ֽ�ָ
	{name = "RIGHT_RING", x = 324, y = 375, h = 45, w = 45, cn_name = _L["RIGHT_RING"], frameid = 61, }, -- ���ֽ�ָ
	{name = "RANGE_WEAPON", x = 185, y = 442, h = 45, w = 45, cn_name = _L["RANGE_WEAPON"], frameid = 58, }, -- Զ������
	{name = "MELEE_WEAPON", x = 133, y = 442, h = 45, w = 45, cn_name = _L["MELEE_WEAPON"], frameid = 64, }, -- ��ͨ��ս����
	{name = "BIG_SWORD", x = 80, y = 442, h = 45, w = 45, cn_name = _L["BIG_SWORD"], frameid = 77, }, -- �ؽ�
	{name = "ARROW", x = 237, y = 452, h = 30, w = 30, cn_name = _L["ARROW"], frameid = 59, }, -- ����
}

LR_AS_Equip_Panel.playerName = nil
LR_AS_Equip_Panel.playerRealServer = nil
LR_AS_Equip_Panel.playerRealArea = nil
LR_AS_Equip_Panel.PlayerMenPai = nil
LR_AS_Equip_Panel.playerID = nil


local CustomVersion = "20170111"
--RegisterCustomData("LR_BookRd_Panel.UserData", CustomVersion)

function LR_AS_Equip_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")

	LR_AS_Equip_Panel.UpdateAnchor(this)
	-------�����ʱ��������

	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	--LR_AccountStatistics_Equip.LoadSelfData(DB)
	LR_AccountStatistics_Equip.GetAllEquipBox()
	LR_AccountStatistics_Equip.SaveData(DB)
	DB:Execute("END TRANSACTION")
	DB:Release()

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

	--------------����ѡ��
	local hComboBox = self:Append("ComboBox", frame, "hComboBox", {w = 160, x = 105, y = 45, text = LR_AS_Equip_Panel.playerName})
	hComboBox:Enable(true)
	hComboBox.OnClick = function (m)
		local TempTable_Cal, TempTable_NotCal = LR_AccountStatistics.SeparateUsrList()
		tsort(TempTable_Cal, function(a, b)
			if a.nLevel == b.nLevel then
				return a.dwForceID < b.dwForceID
			else
				return a.nLevel > b.nLevel
			end
		end)

		local TempTable = {}
		for i = 1, #TempTable_Cal, 1 do
			TempTable[#TempTable+1] = TempTable_Cal[i]
		end
		for i = 1, #TempTable_NotCal, 1 do
			TempTable[#TempTable+1] = TempTable_NotCal[i]
		end

		local page_num = mceil(#TempTable / 20)
		local page = {}
		for i = 0, page_num - 1, 1 do
			page[i] = {}
			for k = 1, 20, 1 do
				if TempTable[i * 20 + k] ~= nil then
					local szIcon, nFrame = GetForceImage(TempTable[i * 20 + k].dwForceID)
					local r, g, b = LR.GetMenPaiColor(TempTable[i * 20 + k].dwForceID)
					page[i][#page[i]+1] = {szOption = sformat("(%d)%s", TempTable[i * 20 + k].nLevel, TempTable[i * 20 + k].szName), bCheck = false, bChecked = false,
						fnAction = function ()
							hComboBox:SetText(TempTable[i * 20 + k].szName)
							LR_AS_Equip_Panel.playerRealArea = TempTable[i * 20 + k].realArea
							LR_AS_Equip_Panel.playerName = TempTable[i * 20 + k].szName
							LR_AS_Equip_Panel.playerID = TempTable[i * 20 + k].dwID
							LR_AS_Equip_Panel.playerRealServer = TempTable[i * 20 + k].realServer
							LR_AS_Equip_Panel.PlayerMenPai = TempTable[i * 20 + k].dwForceID
							LR_AS_Equip_Panel:LoadEquipSuit(0)
						end,
						szIcon = szIcon,
						nFrame = nFrame,
						szLayer = "ICON_RIGHT",
						rgb = {r, g, b},
					}
				end
			end
		end
		for i = 0, page_num - 1, 1 do
			if i ~= page_num - 1 then
				page[i][#page[i] + 1] = {bDevide = true}
				page[i][#page[i] + 1] = page[i+1]
				page[i][#page[i]].szOption = _L["Next 20 Records"]
			end
		end

		m = page[0]
		local __x, __y = hComboBox:GetAbsPos()
		local __w, __h = hComboBox:GetSize()
		m.nMiniWidth = __w
		m.x = __x
		m.y = __y + __h
		PopupMenu(m)
	end

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
	---����
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

	local Image_Devide1 = LR.AppendUI("Image", WndWindow_Charinfo:Lookup("",""), "Image_Devide1", {w = 212, h = 68, x = 11, y = 126})
	Image_Devide1:FromUITex("ui\\image\\minimap\\mapmark.uitex", 50)
	Image_Devide1:SetImageType(10)

	local Image_Devide2 = LR.AppendUI("Image", WndWindow_Charinfo:Lookup("",""), "Image_Devide2", {w = 212, h = 303, x = 11, y = 197})
	Image_Devide2:FromUITex("ui\\image\\minimap\\mapmark.uitex", 50)
	Image_Devide2:SetImageType(10)

	local Text_Equipmentscore = LR.AppendUI("Text", WndWindow_Charinfo:Lookup("",""), "Text_Equipmentscore", {w = 62, h = 20, x = 106, y = 58, text = _L["Equipmentscore"]})
	local Text_score = LR.AppendUI("Text", WndWindow_Charinfo:Lookup("",""), "Text_score", {w = 100, h = 30, x = 106, y = 81, text = ""})
	Text_score:SetFontScheme(200)

	local Text_PVELabel = LR.AppendUI("Text", WndWindow_Charinfo:Lookup("",""), "Text_PVELabel", {w = 125, h = 25, x = 26, y = 137, text = _L["PVEscore"]})
	local Text_PVEValue = LR.AppendUI("Text", WndWindow_Charinfo:Lookup("",""), "Text_PVEValue", {w = 80, h = 25, x = 130, y = 137, text = ""})
	Text_PVELabel:SetHAlign(0)
	Text_PVEValue:SetHAlign(2)

	local Text_PVPLabel = LR.AppendUI("Text", WndWindow_Charinfo:Lookup("",""), "Text_PVPLabel", {w = 125, h = 25, x = 26, y = 161, text = _L["PVPscore"]})
	local Text_PVPValue = LR.AppendUI("Text", WndWindow_Charinfo:Lookup("",""), "Text_PVPValue", {w = 80, h = 25, x = 130, y = 161, text = ""})
	Text_PVPLabel:SetHAlign(0)
	Text_PVPValue:SetHAlign(2)

	local Text_Property = LR.AppendUI("Text", WndWindow_Charinfo:Lookup("",""), "Text_Property", {w = 125, h = 25, x = 26, y = 209, text = _L["Property"]})
	local Image_Property = LR.AppendUI("Image", WndWindow_Charinfo:Lookup("",""), "Image_Property", {w = 200, h = 5, x = 26, y = 235})
	Image_Property:FromUITex("ui\\Image\\uicommon\\commonpanel.UITex", 45)

	local hScroll = LR.AppendUI("Scroll", WndWindow_Charinfo, "Scroll", {x = 23, y = 246, w = 200, h = 260})
	LR_AS_Equip_Panel.Scroll = hScroll

	--��ϸ����
	local charinfo_handle2 = Wnd.OpenWindow("interface\\LR_Plugin\\LR_AccountStatistics\\UI\\WndFrameThin.ini", "charinfo_frame"):Lookup("Wnd_Window")
	charinfo_handle2:ChangeRelation(frame:GetSelf(), true, true)
	charinfo_handle2:SetName("WndWindow_Charmoreinfo")
	Wnd.CloseWindow("charinfo_frame")
	local WndWindow_Charinfo2 = frame:Lookup("WndWindow_Charmoreinfo")
	WndWindow_Charinfo2:SetRelPos(w + w2 -10, 0)
	WndWindow_Charinfo2:Lookup("","Text_Title"):SetText(_L["charmoreinfo"])
	local hScroll2 = self:Append("Scroll", WndWindow_Charinfo2, "Scroll2", {x = 10, y = 40, w = 220, h = 450})
	LR_AS_Equip_Panel.Scroll2 = hScroll2
	frame:SetSize(w + w2 * 2, h2)
	self:LoadEquipSuit(0)

	----------����
	LR.AppendAbout(LR_AS_Equip_Panel, frame)
end

function LR_AS_Equip_Panel:Open(szplayerName, szplayerRealArea, szplayerRealServer, szPlayerMenPai, dwID)
	local frame = self:Fetch("LR_AS_Equip_Panel")
	if frame and frame:IsVisible() then
		frame:Destroy()
	else
		LR_AS_Equip_Panel.playerName = szplayerName
		LR_AS_Equip_Panel.playerRealServer = szplayerRealServer
		LR_AS_Equip_Panel.PlayerMenPai = szPlayerMenPai
		LR_AS_Equip_Panel.playerRealArea = szplayerRealArea
		LR_AS_Equip_Panel.playerID = dwID
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
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

function LR_AS_Equip_Panel:LoadCharscore(nIndex)
	local player = GetClientPlayer()
	if not player then
		return
	end
	local nIndex = nIndex or 0
	local realArea = LR_AS_Equip_Panel.playerRealArea
	local realServer = LR_AS_Equip_Panel.playerRealServer
	local szName = LR_AS_Equip_Panel.playerName
	local dwID = LR_AS_Equip_Panel.playerID
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area2, Server2, realArea2, realServer2 = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local data
	if not realArea or realArea2 == realArea and realServer2 == realServer and me.dwID == dwID then
		data = clone(LR_AccountStatistics_Equip.SelfData)
	else
		data = clone(LR_AccountStatistics_Equip.AllUsrData[szKey])
	end
	local data2 = data[tostring(nIndex)] or {}
	local score = data2.score or {}

	local frame = Station.Lookup("Normal/LR_AS_Equip_Panel")
	local WndWindow_Charinfo = frame:Lookup("WndWindow_Charinfo")
	local hCharinfo = WndWindow_Charinfo:Lookup("","")
	local Text_PVEValue = hCharinfo:Lookup("Text_PVEValue")
	local Text_PVPValue = hCharinfo:Lookup("Text_PVPValue")
	local Text_Equipmentscore = hCharinfo:Lookup("Text_score")

	local hScroll = LR_AS_Equip_Panel.Scroll
	hScroll:ClearHandle()

	local hScroll2 = LR_AS_Equip_Panel.Scroll2
	hScroll2:ClearHandle()

	if next(score) ~= nil then
		Text_PVEValue:SetText(score.PVEscore or "")
		Text_PVPValue:SetText(score.PVPscore or "")
		Text_Equipmentscore:SetText(score.TotalEquipScore or "")

		local char_info = data2.char_info or {}
		for k, v in pairs(char_info or {}) do
			local handle = LR.AppendUI("Handle", hScroll, sformat("handle_%d", k), {w = 200, h = 25})
			local Text_Label = LR.AppendUI("Text", handle, sformat("Text_Label_%d", k), {x = 0, y = 0, w = 125, h = 25, text = v.label})
			local Text_Value = LR.AppendUI("Text", handle, sformat("Text_Value_%d", k), {x = 100 , y = 0, w = 80, h = 25, text = v.value})
			Text_Label:SetHAlign(0)
			Text_Value:SetHAlign(2)
			handle.OnEnter = function()
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				OutputTip(v.szTip, 720, {x, y, w, h})
			end

			handle.OnLeave = function()
				HideTip()
			end
		end

		local char_infomore = data2.char_infomore
		for k, v in pairs(char_infomore or {}) do
			if v.bDivide then
				local handle = LR.AppendUI("Handle", hScroll2, sformat("Handle2_%d", k), {w = 220, h = 8})
				local Image_Divide = LR.AppendUI("Image", handle, sformat("Image2_Divide_%d", k), {x = 0, y = 0, w = 220, h = 8})
				Image_Divide:FromUITex("ui\\Image\\uicommon\\commonpanel.UITex", 45)
			elseif v.bText then
				local handle = LR.AppendUI("Handle", hScroll2, sformat("Handle2_%d", k), {w = 220, h = 20})
				local Text = LR.AppendUI("Text", handle, sformat("Text2_%d", k), {x = 0, y = 0, w = 220, h = 20, text = v.value})
				Text:SetFontScheme(27)
			else
				local handle = LR.AppendUI("Handle", hScroll2, sformat("Handle2_%d", k), {w = 220, h = 25})
				local Text_Label = LR.AppendUI("Text", handle, sformat("Text2_Label_%d", k), {x = 0, y = 0, w = 125, h = 25, text = v.label})
				local Text_Value = LR.AppendUI("Text", handle, sformat("Text2_Value_%d", k), {x = 120 , y = 0, w = 80, h = 25, text = v.value})
			end
		end
	else
		Text_PVEValue:SetText("--")
		Text_PVPValue:SetText("--")
		Text_Equipmentscore:SetText("--")

		local handle = LR.AppendUI("Handle", hScroll, "Handle2_nodata", {w = 220, h = 20})
		local Text = LR.AppendUI("Text", handle, "Text2_nodata", {x = 0, y = 0, w = 220, h = 20, text = _L["No data"]})

		local handle2 = LR.AppendUI("Handle", hScroll2, "Handle3_nodata", {w = 220, h = 20})
		local Text = LR.AppendUI("Text", handle2, "Text3_nodata", {x = 0, y = 0, w = 220, h = 20, text = _L["No data"]})
	end
	hScroll:UpdateList()
	hScroll2:UpdateList()
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

	local realArea = LR_AS_Equip_Panel.playerRealArea
	local realServer = LR_AS_Equip_Panel.playerRealServer
	local szName = LR_AS_Equip_Panel.playerName
	local dwID = LR_AS_Equip_Panel.playerID

	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area2, Server2, realArea2, realServer2 = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local data
	if not realArea or realArea2 == realArea and realServer2 == realServer and me.dwID == dwID then
		data = clone(LR_AccountStatistics_Equip.SelfData)
		LR_AccountStatistics_Equip.AllUsrData[sformat("%s_%s_%d", realArea, realServer, dwID)] = clone(data)
	else
		local path = sformat("%s\\%s", SaveDataPath, DB_name)
		local DB = SQLite3_Open(path)
		DB:Execute("BEGIN TRANSACTION")
		data = LR_AccountStatistics_Equip.LoadData(DB, realArea, realServer, dwID)
		DB:Execute("END TRANSACTION")
		DB:Release()
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
			if LR_AS_Equip_Panel.PlayerMenPai ~= 8 and  szName == "BIG_SWORD" then
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
							if player.szName ~= szplayerName then
								OutputItemTip(UI_OBJECT_ITEM_INFO, GLOBAL.CURRENT_ITEM_VERSION, item.dwTabType, item.dwIndex, {nMouseX, nMouseY, 0, 0})
							else
								OutputItemTip(UI_OBJECT_ITEM_ONLY_ID, item.dwID, nil, nil, {nMouseX, nMouseY, 0, 0}, nil, "loot")
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
						tText[#tText+1] = sformat("%s��%s\n", partName, item.szName)
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
-----hack
------------------------------------------------------------------
function LR_AccountStatistics_Equip.OpenPanel()
	local player = GetClientPlayer()
	if not player then
		return
	end
	local szName = player.szName
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local dwMenpai = player.dwForceID
	LR_AS_Equip_Panel:Open(szName, realArea, realServer, dwMenpai, player.dwID)
end

function LR_AccountStatistics_Equip.Hack()
	local frame = Station.Lookup("Normal/CharacterPanel")
	local Btn_LR_Equipment = frame:Lookup("Btn_LR_Equipment")
	if Btn_LR_Equipment then
		Btn_LR_Equipment:Destroy()
	end
	LR_AccountStatistics.WndButton("Btn_LR_Equipment", 40, 8, _L["LR Equipment Statistics"], LR_AccountStatistics_Equip.OpenPanel, frame)
end

-----�л���װEQUIP_CHANGE
function LR_AccountStatistics_Equip.EQUIP_CHANGE()
	LR_AccountStatistics_Equip.bLock = true	--��ֹ�����л�װ��ʱ����������EQUIP_ITEM_UPDATE�¼�
	LR_AccountStatistics_Equip.GetEquipScore()
	LR.DelayCall(500, function() LR_AccountStatistics_Equip.bLock = false end)
end

---����װ��
function LR_AccountStatistics_Equip.EQUIP_ITEM_UPDATE()
	LR.DelayCall(100, function()
		if not LR_AccountStatistics_Equip.bLock then
			LR_AccountStatistics_Equip.GetEquipScore()
		end
	end)
end

function LR_AccountStatistics_Equip.FIRST_LOADING_END()
	LR_AccountStatistics_Equip.Hack()
	LR.DelayCall(1000,function()
		local charinfo_frame = Station.Lookup("Normal/CharInfo")
		if charinfo_frame then
			Wnd.CloseWindow("CharInfo")
		end
		local CharInfoMore_frame = Station.Lookup("Normal/CharInfoMore")
		if CharInfoMore_frame then
			Wnd.CloseWindow("CharInfoMore")
		end
		local CharacterPanel_frame = Station.Lookup("Normal/CharacterPanel")
		CharacterPanel_frame:SetSize(380, 535)
	end)
end

LR.RegisterEvent("FIRST_LOADING_END", function() LR_AccountStatistics_Equip.FIRST_LOADING_END() end)
LR.RegisterEvent("EQUIP_CHANGE",function() LR_AccountStatistics_Equip.EQUIP_CHANGE() end)
LR.RegisterEvent("EQUIP_ITEM_UPDATE",function() LR_AccountStatistics_Equip.EQUIP_ITEM_UPDATE() end)





