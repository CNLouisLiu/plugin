local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_GKP"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_GKP\\"
local _L = LR.LoadLangPack(AddonPath)
local DB_Name = "LR_GKP.db"
local DB_Path = sformat("%s\\%s", SaveDataPath, DB_Name)
local VERSION = "20170717"
----------------------------------------------------------------
------主界面
----------------------------------------------------------------
LR_GKP_Panel = CreateAddon("LR_GKP_Panel")
LR_GKP_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_GKP_Panel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER", x = 0, y = 0},
}

function LR_GKP_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")

	LR_GKP_Panel.UpdateAnchor(this)
	RegisterGlobalEsc("LR_GKP_Panel", function () return true end , function() LR_GKP_Panel:Open() end)
end

function LR_GKP_Panel:OnEvents(event)
	if event ==  "UI_SCALED" then
		LR_GKP_Panel.UpdateAnchor(this)
	end
end

function LR_GKP_Panel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_GKP_Panel.UsrData.Anchor.s, 0, 0, LR_GKP_Panel.UsrData.Anchor.r, LR_GKP_Panel.UsrData.Anchor.x, LR_GKP_Panel.UsrData.Anchor.y)
end

function LR_GKP_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_GKP_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_GKP_Panel:OnDragEnd()
	this:CorrectPos()
	LR_GKP_Panel.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_GKP_Panel:Init()
	local frame = self:Append("Frame", "LR_GKP_Panel", {title = _L["LR_GKP_RECORD"], style = "LARGER"})
	local imgTab = self:Append("Image", frame, "TabImg", {w = 962, h = 33, x = 0, y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)

	local Page_Break1 = self:Append("Image", frame, "Page_Break1", {x = 40, y = 50, w = 3, h = 30})
	Page_Break1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
	Page_Break1:SetImageType(11)
	Page_Break1:SetAlpha(255)

	local Page_Break2 = self:Append("Image", frame, "Page_Break2", {x = 240, y = 50, w = 3, h = 30})
	Page_Break2:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
	Page_Break2:SetImageType(11)
	Page_Break2:SetAlpha(255)

	local Text_BillName = self:Append("Text", frame, "Text_BillName" , {w = 200, h = 30, x  = 260, y = 50, text = "", font = 2})
	self:RefreshBillName()

	local hPageSet = self:Append("PageSet", frame, "PageSet", {x = 0, y = 50, w = 962, h = 540})

	local Btn_GKP_List = self:Append("UICheckBox", hPageSet, "Btn_GKP_List", {x = 40, y = 0, w = 100, h = 30, text = _L["GKP List"], group = "LR_GKP"})
	local Window_GKP_List = self:Append("Window", hPageSet, "Window_GKP_List", {x = 0, y = 30, w = 962, h = 510})
	hPageSet:AddPage(Window_GKP_List:GetSelf(), Btn_GKP_List:GetSelf())
	Btn_GKP_List.OnCheck = function(bCheck)
		if bCheck then
			hPageSet:ActivePage(0)
		end
	end

	local Btn_Trade_List = self:Append("UICheckBox", hPageSet, "Btn_Trade_List", {x = 140, y = 0, w = 100, h = 30, text = _L["Trade List"], group = "LR_GKP"})
	local Window_Trade_List = self:Append("Window", hPageSet, "Window_Trade_List", {x = 0, y = 30, w = 962, h = 510})
	hPageSet:AddPage(Window_Trade_List:GetSelf(), Btn_Trade_List:GetSelf())
	Btn_Trade_List.OnCheck = function(bCheck)
		if bCheck then
			hPageSet:ActivePage(1)
		end
	end

	local Scroll_GKP_List = self:Append("Scroll", Window_GKP_List, "Scroll_GKP_List", {x = 20, y = 40, w = 934, h = 420})
	local Scroll_Trade_List = self:Append("Scroll", Window_Trade_List, "Scroll_Trade_List", {x = 20, y = 40, w = 934, h = 450})

	-------------初始Window_GKP_List界面物品
	local Handle_GKP_List = self:Append("Handle", Window_GKP_List, "Handle_GKP_List", {x = 18, y = 10, w = 920, h = 450})

	local Image_GKP_List_BG = self:Append("Image", Handle_GKP_List, "Image_GKP_List_BG", {x = 0, y = 0, w = 920, h = 450})
	Image_GKP_List_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 50)
	Image_GKP_List_BG:SetImageType(10)

	local Image_GKP_List_BG1 = self:Append("Image", Handle_GKP_List, "Image_GKP_List_BG1", {x = 0, y = 30, w = 920, h = 420})
	Image_GKP_List_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74)
	Image_GKP_List_BG1:SetImageType(10)
	Image_GKP_List_BG1:SetAlpha(110)

	local Image_GKP_List_Line1_0 = self:Append("Image", Handle_GKP_List, "Image_GKP_List_Line1_0", {x = 3, y = 28, w = 920, h = 3})
	Image_GKP_List_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 65)
	Image_GKP_List_Line1_0:SetImageType(11)
	Image_GKP_List_Line1_0:SetAlpha(115)

	---垂直线条
	local szText = {"#", _L["szItemName"], _L["Purchaser"], _L["Money"], _L["Source"], _L["Time"]}
	local nWidth = {80, 150, 160, 140, 140, 245}
	local _key = {"#", "szName", "szPurchaserName", "nGold", "szSourceName", "nCreateTime"}
	local n = 0
	for k, v in pairs(szText) do
		local Text_GKP_List_Break = self:Append("Text", Handle_GKP_List, "Text_GKP_List_Break_" .. k, {w = nWidth[k], h = 30, x  = n, y = 2, text = v, font = 2})
		Text_GKP_List_Break:SetHAlign(1)
		Text_GKP_List_Break:SetVAlign(1)
		Text_GKP_List_Break:GetSelf():RegisterEvent(277)
		Text_GKP_List_Break:GetSelf().OnItemLButtonClick = function()
			if v == "#" then
				return
			end
			if LR_GKP_Base.szSearchKey == _key[k] then
				if LR_GKP_Base.szOrderKey == "DESC" then
					LR_GKP_Base.szOrderKey = "ASC"
				else
					LR_GKP_Base.szOrderKey = "DESC"
				end
			else
				LR_GKP_Base.szSearchKey = _key[k]
			end
			if next(LR_GKP_Base.GKP_Bill) ~= nil then
				--LR_GKP_Base.LoadGKPList(LR_GKP_Base.GKP_Bill.szName)
				LR_GKP_Panel:RefreshBillName()
				LR_GKP_Panel:LoadGKPItemBox()
			end
			LR_GKP_Panel:DrawTitle()
		end
		n = n + nWidth[k]
		local Image_GKP_List_Break = self:Append("Image", Handle_GKP_List, "Image_GKP_List_Break_" .. k, {x = n, y = 2, w = 3, h = 442})
		Image_GKP_List_Break:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
		Image_GKP_List_Break:SetImageType(11)
		Image_GKP_List_Break:SetAlpha(255)
	end
	LR_GKP_Panel:DrawTitle()

	----合计金钱
	local hHandle_money_all = self:Append("Handle", Window_GKP_List, "Handle_money_all", {x = 20, y = 460, w = 300, h = 30})
	hHandle_money_all:SetHandleStyle(3)
	hHandle_money_all:SetMinRowHeight(30)
	self:ShowMoneyAll(0)

	self:LoadGKPItemBox()
	self:LoadTradeItemBox()
	-------------初始Trade_List界面物品
	local Handle_Trade_List = self:Append("Handle", Window_Trade_List, "Handle_Trade_List", {x = 18, y = 10, w = 920, h = 480})

	local Image_Trade_List_BG = self:Append("Image", Handle_Trade_List, "Image_Trade_List_BG", {x = 0, y = 0, w = 920, h = 480})
	Image_Trade_List_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 50)
	Image_Trade_List_BG:SetImageType(10)

	local Image_Trade_List_BG1 = self:Append("Image", Handle_Trade_List, "Image_Trade_List_BG1", {x = 0, y = 30, w = 920, h = 450})
	Image_Trade_List_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74)
	Image_Trade_List_BG1:SetImageType(10)
	Image_Trade_List_BG1:SetAlpha(110)

	local Image_Trade_List_Line1_0 = self:Append("Image", Handle_Trade_List, "Image_Trade_List_Line1_0", {x = 3, y = 28, w = 920, h = 3})
	Image_Trade_List_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 65)
	Image_Trade_List_Line1_0:SetImageType(11)
	Image_Trade_List_Line1_0:SetAlpha(115)

	---垂直线条
	local szText2 = {"#", _L["Trade Target"], _L["Money"], _L["Time"], _L["szBelongBill"]}
	local nWidth2 = {80, 140, 200, 250, 245}
	local _key2 = {"#", "szName", "nGold", "nCreateTime"}
	local n2 = 0
	for k, v in pairs(szText2) do
		local Text_Trade_List_Break = self:Append("Text", Handle_Trade_List, "Text_Trade_List_Break_" .. k, {w = nWidth2[k], h = 30, x  = n2, y = 2, text = v, font = 2})
		Text_Trade_List_Break:SetHAlign(1)
		Text_Trade_List_Break:SetVAlign(1)
		Text_Trade_List_Break:GetSelf():RegisterEvent(277)
		Text_Trade_List_Break:GetSelf().OnItemLButtonClick = function()
--[[			if v == "#" then
				return
			end
			if LR_GKP_Base.szSearchKey == _key[k] then
				if LR_GKP_Base.szOrderKey == "DESC" then
					LR_GKP_Base.szOrderKey = "ASC"
				else
					LR_GKP_Base.szOrderKey = "DESC"
				end
			else
				LR_GKP_Base.szSearchKey = _key[k]
			end
			if next(LR_GKP_Base.GKP_Bill) ~= nil then
				LR_GKP_Base.LoadGKPList(LR_GKP_Base.GKP_Bill.szName)
				LR_GKP_Panel:RefreshBillName()
				LR_GKP_Panel:LoadGKPItemBox()
			end
			LR_GKP_Panel:DrawTitle()]]
		end
		n2 = n2 + nWidth2[k]
		local Image_Trade_List_Break = self:Append("Image", Handle_Trade_List, "Image_Trade_List_Break_" .. k, {x = n2, y = 2, w = 3, h = 472})
		Image_Trade_List_Break:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
		Image_Trade_List_Break:SetImageType(11)
		Image_Trade_List_Break:SetAlpha(255)
	end

	local ComboBox_Option = self:Append("ComboBox", frame, "ComboBox_Option", {w = 110, x = 800, y = 52, text = _L["Bill Options"] })
	ComboBox_Option:Enable(true)
	ComboBox_Option.OnClick = function (m)
		m[#m + 1] = {
			szOption = _L["Create a bill"],
			fnAction = function()
				LR_GKP_NewBill_Panel:Open()
			end,
			fnDisable = function()
				return not LR_GKP_Loot.DistributeCheck()
			end
		}
		m[#m + 1] = {
			szOption = _L["Change to another bill"],
		}
		local m3 = LR_GKP_Panel:CreateBillMenu()
		local mm = m[#m]
		for k, v in pairs (m3) do
			mm[#mm + 1] = v
		end
		PopupMenu(m)
	end

	local UIButton_FAQ = self:Append("UIButton", frame, "FAQ" , {x = 914 , y = 52 , w = 26 , h = 26, ani = {"ui\\Image\\UICommon\\CommonPanel2.UITex", 48, 50, 54, 55}, })
	UIButton_FAQ.OnEnter = function()
		local x, y = UIButton_FAQ:GetAbsPos()
		local w, h = UIButton_FAQ:GetSize()
		local szXml = {}
		szXml[#szXml+1] = GetFormatText(_L["GKP_TIP01"], 136, 255, 128, 0)
		szXml[#szXml+1] = GetFormatText(_L["GKP_TIP02"], 136, 255, 128, 0)
		szXml[#szXml+1] = GetFormatText(_L["GKP_TIP03"], 136, 255, 128, 0)
		szXml[#szXml+1] = GetFormatText(_L["GKP_TIP04"], 136, 255, 128, 0)

		OutputTip(tconcat(szXml), 600, {x, y, 0, 0})
	end
	UIButton_FAQ.OnLeave = function()
		HideTip()
	end


	local Btn_AddRecord = self:Append("Button", frame, "Btn_AddRecord", {text = _L["Add record"] , x = 20, y = 570, w = 90, h = 36})
	Btn_AddRecord.OnClick = function()
		if not LR_GKP_Loot.DistributeCheck() then
			LR.SysMsg(_L["You must be in a team, and be distributor.\n"])
			return
		else
			LR_GKP_Distribute_Panel:Open({szName = _L["Treasure Box"], szKey = sformat("ManualAdd_%d_%d", GetCurrentTime(), GetTickCount()), dwIndex = 0, dwTabType = 0, bManual = true}, GetClientPlayer())
		end
	end

	local Btn_TradeRecord = self:Append("Button", frame, "Btn_TradeRecord", {text = _L["Trade record"] , x = 130, y = 570, w = 120, h = 36})
	Btn_TradeRecord.OnClick = function()
		LR_GKP_Base.OutputTradeList()
	end

	local Btn_DebtRecord = self:Append("Button", frame, "Btn_DebtRecord", {text = _L["Debt record"] , x = 270, y = 570, w = 120, h = 36})
	Btn_DebtRecord.OnClick = function()
		LR_GKP_Base.OutputDebtList()
	end

	local Btn_SyncRecord = self:Append("Button", frame, "Btn_DebtRecord", {text = _L["Sync record"] , x = 410, y = 570, w = 160, h = 36})
	Btn_SyncRecord.OnClick = function()
		if not LR_GKP_Loot.DistributeCheck() then
			LR.SysMsg(_L["You must be in a team, and be distributor.\n"])
			return
		else
			local msg = {
				szMessage = _L["Are you sure to sync record to others?"],
				szName = "sync bill",
				fnAutoClose = function() return false end,
				{szOption = _L["Yes"], fnAction = function() LR_GKP_Base.SyncRecord(); LR_GKP_Base.SyncBoss() end, },
				{szOption = _L["No"], fnAction = function()  end,},
			}
			MessageBox(msg)
		end
	end

	local Btn_SetPrice = self:Append("Button", frame, "Btn_SetPrice", {text = _L["Set price"], x = 740, y = 570, w = 90, h = 36})
	Btn_SetPrice.OnClick = function()
		local menu = {}
		local x, y = Btn_SetPrice:GetAbsPos()
		menu.minwidth = 90
		menu.x, menu.y = x, y + 36
		LR_GKP_Base.InsertSetPriceMenu(menu)
		PopupMenu(menu)
	end

	local Btn_SetBoss = self:Append("Button", frame, "Btn_SetBoss", {text = _L["Set boss"] , x = 840, y = 570, w = 90, h = 36})
	Btn_SetBoss.OnClick = function()
		local menu = {}
		local x, y = Btn_SetBoss:GetAbsPos()
		menu.minwidth = 90
		menu.x, menu.y = x, y + 36
		LR_GKP_Base.InsertSetBossMenu(menu)
		PopupMenu(menu)
	end

	----------关于
	LR.AppendAbout(LR_GKP_Panel, frame)
end

function LR_GKP_Panel:DrawTitle()
	local frame = self:Fetch("LR_GKP_Panel")
	if not frame then
		return
	end
	local szText = {"#", _L["szItemName"], _L["Purchaser"], _L["Money"], _L["Source"], _L["Time"]}
	local _key = {"#", "szName", "szPurchaserName", "nGold", "szSourceName", "nCreateTime"}
	for k, v in pairs(szText) do
		local h = self:Fetch("Text_GKP_List_Break_" .. k)
		if LR_GKP_Base.szSearchKey == _key[k] then
			if LR_GKP_Base.szOrderKey == "DESC" then
				h:SetText(v .. "↓")
			else
				h:SetText(v .. "↑")
			end
			h:SetFontScheme(8)
		else
			h:SetText(v)
			h:SetFontScheme(7)
		end
	end
end

function LR_GKP_Panel:Open()
	local frame = self:Fetch("LR_GKP_Panel")
	if frame then
		self:Destroy(frame)
	else
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

function LR_GKP_Panel:CheckBill()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not (me.IsInParty() or me.IsInRaid()) then
		return
	end
	local team = GetClientTeam()
	if me.dwID ~= team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) then
		return
	end
	if next(LR_GKP_Base.GKP_Bill or {}) == nil then
		local msg = {
			szMessage = _L["You have no bill now. Create one or load One?"],
			szName = "create bill",
			fnAutoClose = function() return false end,
			{szOption = _L["New"], fnAction = function() LR_GKP_NewBill_Panel:Open() end, },
			{szOption = _L["Load"], fnAction = function() LR.DelayCall(100, function() PopupMenu(LR_GKP_Panel:CreateBillMenu()) end) end,},
		}
		MessageBox(msg)
	end
end

function LR_GKP_Panel:CreateBillMenu()
	local DB = SQLite3_Open(DB_Path)
	DB:Execute("BEGIN TRANSACTION")
	local DB_SELECT = DB:Prepare("SELECT * FROM bill_data WHERE szName IS NOT NULL ORDER BY nCreateTime DESC LIMIT 20 OFFSET 0")
	local result = DB_SELECT:GetAll() or {}
	local mm = {}
	for k, v in pairs (result) do
		mm[#mm + 1] = {
			szOption = LR.StrDB2Game(v.szName),
			fnAction = function()
				LR_GKP_Base.LoadBill(LR.StrDB2Game(v.szName))
			end
		}
	end
	DB:Execute("END TRANSACTION")
	DB:Release()

	return mm
end

function LR_GKP_Panel:RefreshBillName()
	local Text_BillName = self:Fetch("Text_BillName")
	if Text_BillName then
		if next(LR_GKP_Base.GKP_Bill or {}) ~= nil then
			Text_BillName:SetText(LR_GKP_Base.GKP_Bill.szName)
		else
			Text_BillName:SetText("")
		end
	end
end

function LR_GKP_Panel:ShowMoneyAll(nMoney)
	local hHandle = self:Fetch("Handle_money_all")
	if not hHandle then
		return
	end
	self:ClearHandle(hHandle)
	self:Append("Text", hHandle, "Text_MoneyAll", {h = 30, text = _L["Total:"] , font = _font})
	local nMoney = nMoney
	local nMoney2 = 0
	if nMoney>= 0 then
		nMoney2 = nMoney
	else
		nMoney2 = -nMoney
	end
	hHandle:AppendItemFromString(LR_GKP_Loot.GetMoneyTipText(nMoney))
	hHandle:FormatAllItemPos()
end

function LR_GKP_Panel:LoadGKPItemBox()
	local frame = Station.Lookup("Normal/LR_GKP_Panel")
	if not frame then
		return
	end
	local Scroll_GKP_List = self:Fetch("Scroll_GKP_List")
	if not Scroll_GKP_List then
		return
	end
	self:ClearHandle(Scroll_GKP_List)
	if next(LR_GKP_Base.GKP_Bill) == nil then
		return
	end
	LR_GKP_Base.LoadGKPList(LR_GKP_Base.GKP_Bill.szName)

	local nMoney = 0
	for k, v in pairs(LR_GKP_Base.GKP_TradeList) do
		local handleTradeList = LR.AppendUI("Handle", Scroll_GKP_List, "handleTradeList" .. k, {w = 920, h = 30})

		local Image_Line = LR.AppendUI("Image", handleTradeList, sformat("Image_Line1_%d", k), {x = 0, y = 0, w = 920, h = 30, eventid = 0})
		Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
		Image_Line:SetImageType(10)
		Image_Line:SetAlpha(220)
		if k % 2 == 0 then
			Image_Line:SetAlpha(140)
		end

		--悬停框
		local Image_Hover = self:Append("Image", handleTradeList, sformat("Image_Hover_%d", k), {x = 2, y = 0, w = 920, h = 30, eventid = 0})
		Image_Hover:FromUITex("ui\\Image\\Common\\TempBox.UITex", 5)
		Image_Hover:SetImageType(10)
		Image_Hover:SetAlpha(200)
		Image_Hover:Hide()

		local nWidth = {80, 150, 160, 140, 140, 245}
		local nn = 0
		local Text_Order = LR.AppendUI("Text", handleTradeList, "Text_Order" .. k, {h = 30, text = k , w = nWidth[1], eventid = 0})
		Text_Order:SetHAlign(1)
		Text_Order:SetVAlign(1)
		nn = nn + nWidth[1]

		--显示物品
		local dwTabType, dwIndex = v.dwTabType, v.dwIndex
		local itemInfo = GetItemInfo(dwTabType, dwIndex)
		local Handle_Item = LR.AppendUI("Handle", handleTradeList, "Handle_Item" .. k, {x = nn, h = 30, w = nWidth[2], eventid = 0})
		Handle_Item:SetHandleStyle(3)

		if v.dwTabType ~= 0 then
			local box = LR.AppendUI("Box", Handle_Item, sformat("Box_Item_%d_%d", v.dwTabType, v.dwIndex), {w = 30, h = 30})
			UpdateBoxObject(box:GetSelf(), UI_OBJECT_ITEM_INFO, 1, v.dwTabType, v.dwIndex)
			if v.nStackNum > 1 then
				box:SetOverText(1, v.nStackNum)
				box:SetOverTextFontScheme(1, 15)
				box:SetOverTextPosition(1, ITEM_POSITION.RIGHT_BOTTOM)
			end
--[[			local box = LR.ItemBox:new(v)
			box:Create(Handle_Item, {width = 30, height = 30})
			box:OnItemMouseEnter(function() Image_Hover:Show()	end)
			box:OnItemMouseLeave(function() Image_Hover:Hide() end)]]
		else
			local box = LR.AppendUI("Image", Handle_Item, "Image_Item_Icon" .. k, {h = 30, w = 30, eventid = 0})
			box:FromIconID(582)
		end

		local Text_Item = LR.AppendUI("Text", Handle_Item, "Text_Item" .. k, {h = 30, w = 40, text = v.szName, eventid = 0})
		Text_Item:SetHAlign(1)
		Text_Item:SetVAlign(0)
		if itemInfo then
			Text_Item:SetFontColor(GetItemFontColorByQuality(itemInfo.nQuality))
		end
		Handle_Item:FormatAllItemPos()
		local w_ItemName, h_ItemName = Text_Item:GetTextExtent()
		Text_Item:SetSize(w_ItemName, 30):SetVAlign(1):SetHAlign(1)
		nn = nn + nWidth[2]

		--显示购买者
		local Handle_Purchaser = LR.AppendUI("Handle", handleTradeList, "Handle_Purchaser" .. k, {x = nn, h = 30, w = nWidth[3], eventid = 0})
		Handle_Purchaser:SetHandleStyle(3)
		local Image_PurchaserForce = LR.AppendUI("Image", Handle_Purchaser, "Image_PurchaserForce" .. k, {h = 30, w = 30, eventid = 0})
		Image_PurchaserForce:FromUITex(GetForceImage(v.dwPurchaserForceID))
		local Text_PurchaserName = LR.AppendUI("Text", Handle_Purchaser, "Text_PurchaserName" .. k, {h = 30, text = v.szPurchaserName, eventid = 0})
		Handle_Purchaser:FormatAllItemPos()
		local w_PurchaserName, h_PurchaserName = Text_PurchaserName:GetTextExtent()
		Text_PurchaserName:SetSize(w_PurchaserName, 30):SetVAlign(1):SetHAlign(1)

		nn = nn + nWidth[3]

		--显示金钱
		local Handle_Money2 = LR.AppendUI("Handle", handleTradeList, "Handle_Money2_" .. k, {x = nn, h = 30, w = nWidth[4], eventid = 0})
		local Handle_Money = LR.AppendUI("Handle", Handle_Money2, "Handle_Money" .. k, {x = 0, h = 30, w = nWidth[4], eventid = 0})
		Handle_Money:SetHandleStyle(3)
		Handle_Money:AppendItemFromString(LR_GKP_Loot.GetMoneyTipText(v.nGold))
		Handle_Money:FormatAllItemPos()
		local w_money, h_money = Handle_Money:GetAllItemSize()
		Handle_Money:SetSize(w_money, h_money):SetRelPos(0, (30 - h_money) / 2)
		Handle_Money2:FormatAllItemPos()
		nn = nn + nWidth[4]
		if not v.bDel then
			nMoney = nMoney + v.nGold
		end

		--显示来源
		local Text_Source = LR.AppendUI("Text", handleTradeList, "Text_Source_" .. k, {x = nn, h = 30, w = nWidth[5], eventid = 0})
		Text_Source:SetText(v.szSourceName)
		Text_Source:SetHAlign(1)
		Text_Source:SetVAlign(1)
		nn = nn + nWidth[5]

		--显示时间
		local Text_Time = LR.AppendUI("Text", handleTradeList, "Text_Time_" .. k, {x = nn, h = 30, w = nWidth[6], eventid = 0})
		local _date = TimeToDate(v.nCreateTime)
		Text_Time:SetText(sformat(_L["%04dy%02dm%02dd %02d:%02d:%02d"], _date.year, _date.month, _date.day, _date.hour, _date.minute, _date.second))
		Text_Time:SetHAlign(1)
		Text_Time:SetVAlign(1)

		local pm = function()
			if not LR_GKP_Loot.DistributeCheck() then
				return
			end
			local menu = {}
			menu[#menu + 1] = {
				szOption = _L["Modify"],
				fnAction = function()
					if not LR_GKP_Loot.DistributeCheck() then
						return
					end
					LR_GKP_Distribute_Panel:Open(v, nil, true)
				end,
			}
			menu[#menu + 1] = {
				szOption = _L["Delete"],
				fnAction = function()
					if not LR_GKP_Loot.DistributeCheck() then
						return
					end
					if next(LR_GKP_Base.GKP_Bill or {}) == nil then
						LR_GKP_Panel:CheckBill()
					else
						--先保存一波
						local DB = SQLite3_Open(DB_Path)
						DB:Execute("BEGIN TRANSACTION")
						LR_GKP_Base.DelSingleData(DB, v)
						DB:Execute("END TRANSACTION")
						DB:Release()
						--
						LR_GKP_Panel:LoadGKPItemBox()
						LR_GKP_Base.GKP_BgTalk("SYNC_BEGIN", {})
						LR_GKP_Base.GKP_BgTalk("DEL", v)
						LR_GKP_Base.GKP_BgTalk("SYNC_END", {})
					end
				end,
			}
			PopupMenu(menu)
		end

		handleTradeList.OnEnter = function()
			local Image_Hover = self:Fetch(sformat("Image_Hover_%d", k))
			if Image_Hover then
				Image_Hover:Show()
			end
		end
		handleTradeList.OnLeave = function()
			local Image_Hover = self:Fetch(sformat("Image_Hover_%d", k))
			if Image_Hover then
				Image_Hover:Hide()
			end
		end
		handleTradeList.OnClick = function()
			pm()
		end

		Handle_Item.OnEnter = function()
			local Image_Hover = self:Fetch(sformat("Image_Hover_%d", k))
			if Image_Hover then
				Image_Hover:Show()
			end
			if itemInfo then
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				if  itemInfo.nGenre and itemInfo.nGenre == ITEM_GENRE.BOOK then
					if v.nBookID then
						local dwBookID, dwSegmentID = GlobelRecipeID2BookID(v.nBookID)
						OutputBookTipByID(dwBookID, dwSegmentID, {x, y, w, h,})
					end
				else
					OutputItemTip(UI_OBJECT_ITEM_INFO, 1, dwTabType, dwIndex, {x, y, w, h,})
				end
			end
		end
		Handle_Item.OnLeave = function()
			local Image_Hover = self:Fetch(sformat("Image_Hover_%d", k))
			if Image_Hover then
				Image_Hover:Hide()
			end
			HideTip()
		end
		Handle_Item.OnClick = function()
			pm()
		end

		Handle_Purchaser.OnEnter = function()
			local Image_Hover = self:Fetch(sformat("Image_Hover_%d", k))
			if Image_Hover then
				Image_Hover:Show()
			end
		end
		Handle_Purchaser.OnLeave = function()
			local Image_Hover = self:Fetch(sformat("Image_Hover_%d", k))
			if Image_Hover then
				Image_Hover:Hide()
			end
		end
		Handle_Purchaser.OnClick = function()
			pm()
		end

		Handle_Money.OnEnter = function()
			local Image_Hover = self:Fetch(sformat("Image_Hover_%d", k))
			if Image_Hover then
				Image_Hover:Show()
			end
		end
		Handle_Money.OnLeave = function()
			local Image_Hover = self:Fetch(sformat("Image_Hover_%d", k))
			if Image_Hover then
				Image_Hover:Hide()
			end
		end
		Handle_Money.OnClick = function()
			pm()
		end

		if v.bDel then
			handleTradeList:SetAlpha(80)
		end
	end
	Scroll_GKP_List:UpdateList()
	LR_GKP_Panel:ShowMoneyAll(nMoney)
end

function LR_GKP_Panel:LoadTradeItemBox()
	local frame = Station.Lookup("Normal/LR_GKP_Panel")
	if not frame then
		return
	end
	local Scroll_Trade_List = self:Fetch("Scroll_Trade_List")
	if not Scroll_Trade_List then
		return
	end
	Scroll_Trade_List:ClearHandle()
	if next(LR_GKP_Base.GKP_Bill) ~= nil then
		LR_GKP_Base.LoadGKPList(LR_GKP_Base.GKP_Bill.szName)
	end

	local GKP_Person_Cash_Temp = {}
	for k, v in pairs(LR_GKP_Base.GKP_Person_Cash_Temp) do
		GKP_Person_Cash_Temp[#GKP_Person_Cash_Temp + 1] = v
	end
	tsort(GKP_Person_Cash_Temp, function(a, b) return a.nCreateTime > b.nCreateTime end)

	local n = 1
	for k, v in pairs(GKP_Person_Cash_Temp) do
		if not (v.szBelongBill and v.szBelongBill ~= LR_GKP_Base.GKP_Bill.szName) then
			local handleTradeList = LR.AppendUI("Handle", Scroll_Trade_List, "handleTradeList" .. k, {w = 920, h = 30})

			local Image_Line = LR.AppendUI("Image", handleTradeList, sformat("Image_Line1_%d", k), {x = 0, y = 0, w = 920, h = 30})
			Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
			Image_Line:SetImageType(10)
			Image_Line:SetAlpha(220)
			if k % 2 == 0 then
				Image_Line:SetAlpha(140)
			end

			--悬停框
			local Image_Hover = LR.AppendUI("Image", handleTradeList, sformat("Image_Hover_%d", k), {x = 2, y = 0, w = 920, h = 30})
			Image_Hover:FromUITex("ui\\Image\\Common\\TempBox.UITex", 5)
			Image_Hover:SetImageType(10)
			Image_Hover:SetAlpha(200)
			Image_Hover:Hide()

			local nWidth = {80, 140, 200, 250}
			local nn = 0
			local Text_Order = LR.AppendUI("Text", handleTradeList, "Text_Order" .. k, {h = 30, text = n , w = nWidth[1]})
			Text_Order:SetHAlign(1)
			Text_Order:SetVAlign(1)
			nn = nn + nWidth[1]

			--显示交易对象
			local Handle_Purchaser = LR.AppendUI("Handle", handleTradeList, "Handle_Purchaser" .. k, {x = nn, h = 30, w = nWidth[2]})
			Handle_Purchaser:SetHandleStyle(3)
			local Image_PurchaserForce = LR.AppendUI("Image", Handle_Purchaser, "Image_PurchaserForce" .. k, {h = 30, w = 30, eventid = 0})
			Image_PurchaserForce:FromUITex(GetForceImage(v.dwForceID))
			local Text_PurchaserName = LR.AppendUI("Text", Handle_Purchaser, "Text_PurchaserName" .. k, {h = 30, text = v.szName})
			Handle_Purchaser:FormatAllItemPos()
			nn = nn + nWidth[2]

			--显示金钱
			local Handle_Money2 = LR.AppendUI("Handle", handleTradeList, "Handle_Money2_" .. k, {x = nn, h = 30, w = nWidth[3]})
			local Handle_Money = LR.AppendUI("Handle", Handle_Money2, "Handle_Money_" .. k, {h = 30, w = nWidth[3]})
			Handle_Money:SetHandleStyle(3)
			Handle_Money:AppendItemFromString(LR_GKP_Loot.GetMoneyTipText(v.nGold))
			Handle_Money:FormatAllItemPos()
			local w_money, h_money = Handle_Money:GetAllItemSize()
			Handle_Money:SetSize(w_money, h_money):SetRelPos(0, (30 - h_money) / 2)
			Handle_Money2:FormatAllItemPos()
			nn = nn + nWidth[3]

			--显示时间
			local Text_Time = LR.AppendUI("Text", handleTradeList, "Text_Time_" .. k, {x = nn, h = 30, w = nWidth[4]})
			local _date = TimeToDate(v.nCreateTime)
			Text_Time:SetText(sformat(_L["%04dy%02dm%02dd %02d:%02d:%02d"], _date.year, _date.month, _date.day, _date.hour, _date.minute, _date.second))
			Text_Time:SetHAlign(1)
			Text_Time:SetVAlign(1)
			nn = nn + nWidth[4]

			local Text_Belong = LR.AppendUI("Text", handleTradeList, "Text_Belong" .. k, {x = nn, h = 30, w = nWidth[5]})
			if v.szBelongBill and v.szBelongBill == LR_GKP_Base.GKP_Bill.szName then
				Text_Belong:SetText("")
			else
				Text_Belong:SetText(_L["this login, in any bill"])
			end

			n = n +1
		end
	end
	Scroll_Trade_List:UpdateList()
end

----------------------------------------------------------------
------新建Bill界面
----------------------------------------------------------------
LR_GKP_NewBill_Panel = CreateAddon("LR_GKP_NewBill_Panel")
LR_GKP_NewBill_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_GKP_NewBill_Panel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER", x = 0, y = 0},
}

function LR_GKP_NewBill_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")

	LR_GKP_NewBill_Panel.UpdateAnchor(this)
	RegisterGlobalEsc("LR_GKP_NewBill_Panel", function () return true end , function() LR_GKP_NewBill_Panel:Open() end)
end

function LR_GKP_NewBill_Panel:OnEvents(event)
	if event ==  "UI_SCALED" then
		LR_GKP_NewBill_Panel.UpdateAnchor(this)
	end
end

function LR_GKP_NewBill_Panel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_GKP_NewBill_Panel.UsrData.Anchor.s, 0, 0, LR_GKP_NewBill_Panel.UsrData.Anchor.r, LR_GKP_NewBill_Panel.UsrData.Anchor.x, LR_GKP_NewBill_Panel.UsrData.Anchor.y)
end

function LR_GKP_NewBill_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_GKP_NewBill_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_GKP_NewBill_Panel:OnDragEnd()
	this:CorrectPos()
	LR_GKP_NewBill_Panel.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_GKP_NewBill_Panel:Init()
	local frame = self:Append("Frame", "LR_GKP_NewBill_Panel", {title = _L["New Bill"], path = sformat("%s\\UI\\Small.ini", AddonPath)})
	local Handle_Total = frame:Lookup("","")

	local Text_Main = self:Append("Text", Handle_Total, "Text_Main", {80, h = 30, x  = 10, y = 30, text = _L["Main_Name"], font = 2})
	local Edit_Main = self:Append("Edit", frame, "Edit_Main", {x = 10, y = 55, h = 20, w = 160, text = self:CreateMainName()})
	Edit_Main:Enable(false)

	local Text_Sub = self:Append("Text", Handle_Total, "Text_Sub", {80, h = 30, x  = 10, y = 80, text = _L["Sub_Name"], font = 2})
	local Edit_Sub = self:Append("Edit", frame, "Edit_Sub", {x = 10, y = 105, h = 20, w = 160, text = Table_GetMapName(GetClientPlayer().GetScene().dwMapID)})
	local pop = function()
		local menu = LR_GKP_NewBill_Panel:GetDungeonList()
		local nX, nY = Edit_Sub:GetAbsPos()
		local nW, nH = Edit_Sub:GetSize()
		menu.x = nX
		menu.y = nY + nH
		menu.nMinWidth = nW
		menu.bShowKillFocus = true
		menu.bDisableSound = true
		PopupMenu(menu)
	end

	Edit_Sub.OnChange = function()

	end
	Edit_Sub.OnSetFocus = function()
		pop()
	end
	Edit_Sub.OnKillFocus = function()
		LR.DelayCall(100, function()
			if IsPopupMenuOpened() then
				Wnd.CloseWindow(GetPopupMenu())
			end
		end)
	end

	local Btn_OK = self:Append("Button", frame, "Btn_OK", {text = _L["New"] , x = 15, y = 140, w = 70, h = 36})
	Btn_OK.OnClick = function()
		local text_main = LR.Trim(self:Fetch("Edit_Main"):GetText())
		local text_sub = sgsub(self:Fetch("Edit_Sub"):GetText(), " ", "")
		if text_sub == "" then
			text_sub = _L["Some Dungeon"]
		end
		local text = sformat("%s_%s", text_main, text_sub)

		local DB = SQLite3_Open(DB_Path)
		DB:Execute("BEGIN TRANSACTION")
		LR_GKP_Base.CreateNewBill(DB, text)
		DB:Execute("END TRANSACTION")
		DB:Release()
		LR.DelayCall(500, function()
			LR_GKP_Panel:LoadGKPItemBox()
			LR_GKP_Panel:LoadTradeItemBox()
		end)
		self:Open()
	end

	local Btn_Cancel = self:Append("Button", frame, "Btn_Cancel", {text = _L["Cancel"] , x = 105, y = 140, w = 70, h = 36})
	Btn_Cancel.OnClick = function()
		self:Open()
	end
	----------关于
	LR.AppendAbout(LR_GKP_Panel, frame)
end

function LR_GKP_NewBill_Panel:CreateMainName()
	local nTime = GetCurrentTime()
	local _date = TimeToDate(nTime)
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local szText = sformat(_L["%s_%s_%04dy%02dm%02dd_%02d:%02d:%02d"], realArea, realServer, _date.year, _date.month, _date.day, _date.hour, _date.minute, _date.second)
	return szText
end

function LR_GKP_NewBill_Panel:GetDungeonList()
	local nCount = g_tTable.DungeonInfo:GetRowCount()
	local m = {}
	local n = 0
	for i = nCount, 1, -1 do
		local tLine = g_tTable.DungeonInfo:GetRow(i)
		local dwMapID = tLine.dwMapID
		local _, _, nMaxPlayerCount = GetMapParams(dwMapID)
		local desc = ""
		local _s, _e, num_limit, tLevel = sfind(tLine.szLayer3Name, sformat("(%%d+)%s(.+)", _L["REN"]))
		if not _s then
			num_limit = 25
			desc = sformat("(%s)", wssub(LR.Trim(tLine.szLayer3Name), 1, 2))
		else
			desc = sformat("(%d%s)", num_limit, wssub(tLevel, 1, 1))
		end
		local _s2, _e2, szOtherName = sfind(tLine.szOtherName, _L["·(.+)"])
		if not _s2 then
			szOtherName = tLine.szOtherName
		end
		local szName = sformat("%s%s", szOtherName, desc)
		if not m[szName] then
			m[szName] = true
			n = n +1
		end
		if n == 10 then
			break
		end
	end
	local mm = {}
	for k, v in pairs(m) do
		mm[#mm + 1] = {
			szOption = k,
			fnAction = function()
				Edit_Sub = self:Fetch("Edit_Sub")
				if Edit_Sub then
					Edit_Sub:SetText(k)
				end
			end,
		}
	end
	return mm
end

function LR_GKP_NewBill_Panel:Open()
	local frame = self:Fetch("LR_GKP_NewBill_Panel")
	if frame then
		self:Destroy(frame)
	else
		--LR_Acc_Trade.LoadData(nil, true)
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

------------------------------------------------------
---新建门派老板
------------------------------------------------------
LR_GKP_NewMenPaiBoss_Panel = CreateAddon("LR_GKP_NewMenPaiBoss_Panel")
LR_GKP_NewMenPaiBoss_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_GKP_NewMenPaiBoss_Panel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER", x = 0, y = 0},
}
LR_GKP_NewMenPaiBoss_Panel.data = {}

function LR_GKP_NewMenPaiBoss_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")

	LR_GKP_NewMenPaiBoss_Panel.UpdateAnchor(this)
	RegisterGlobalEsc("LR_GKP_NewMenPaiBoss_Panel", function () return true end , function() LR_GKP_NewMenPaiBoss_Panel:Open() end)
	LR_GKP_NewMenPaiBoss_Panel.data = {}
end

function LR_GKP_NewMenPaiBoss_Panel:OnEvents(event)
	if event ==  "UI_SCALED" then
		LR_GKP_NewMenPaiBoss_Panel.UpdateAnchor(this)
	end
end

function LR_GKP_NewMenPaiBoss_Panel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_GKP_NewMenPaiBoss_Panel.UsrData.Anchor.s, 0, 0, LR_GKP_NewMenPaiBoss_Panel.UsrData.Anchor.r, LR_GKP_NewMenPaiBoss_Panel.UsrData.Anchor.x, LR_GKP_NewMenPaiBoss_Panel.UsrData.Anchor.y)
end

function LR_GKP_NewMenPaiBoss_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_GKP_NewMenPaiBoss_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_GKP_NewMenPaiBoss_Panel:OnDragEnd()
	this:CorrectPos()
	LR_GKP_NewMenPaiBoss_Panel.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_GKP_NewMenPaiBoss_Panel:Init()
	local frame = self:Append("Frame", "LR_GKP_NewMenPaiBoss_Panel", {title = _L["New MenPai Boss"], path = sformat("%s\\UI\\Small.ini", AddonPath)})
	local Image = self:Append("Image", frame, "Image", {x = 150, y = 60 , w = 30, h = 30})
	local ComboBox = self:Append("ComboBox", frame, "ComboBox", {x = 30, y = 60, w = 120, h = 30, })
	ComboBox:SetRichText(true):SetText(_L["Please Choose"])
	ComboBox.OnClick = function(m)
		local MemberList = LR_GKP_Base.GetTeamMemberList()
		for k, v in pairs(MemberList) do
			local dwMemberID = v.dwID
			local szName = v.szName
			local szPath, nFrame = GetForceImage(v.dwForceID)
			local r, g, b = LR.GetMenPaiColor(v.dwForceID)
			m[#m + 1] = {	bRichText = true, szOption = GetFormatImage(szPath, nFrame, 24, 24) .. GetFormatText(szName, nil, r, g, b),
				rgb = rgb,
				fnAction = function()
					ComboBox:SetText(szName):SetFontColor(r, g, b)
					Image:FromUITex(szPath, nFrame)
					LR_GKP_NewMenPaiBoss_Panel.data = clone(v)
				end
			}
		end
		PopupMenu(m)
	end

	local Btn_OK = self:Append("Button", frame, "Btn_OK", {text = _L["Add"] , x = 60, y = 110, w = 70, h = 36})
	Btn_OK.OnClick = function()
		if next(LR_GKP_NewMenPaiBoss_Panel.data) ~= nil then
			local v = LR_GKP_NewMenPaiBoss_Panel.data
			LR_GKP_Base.MenPaiBoss[v.dwForceID] = {dwID = v.dwID, szName = v.szName, dwForceID = v.dwForceID}
			LR_GKP_Base.SaveBill()
			--喊话
			local r, g, b = LR.GetMenPaiColor(v.dwForceID)
			local msg = {}
			msg[#msg + 1] = GetFormatText(_L["Successfully set"], 48)
			msg[#msg + 1] = GetFormatText(g_tStrings.tForceTitle[v.dwForceID], 48, r, g, b)
			msg[#msg + 1] = GetFormatText(_L["boss"], 48)
			msg[#msg + 1] = GetFormatText(sformat("[%s]", v.szName), 48, r, g, b)
			msg[#msg + 1] = GetFormatText("\n")
			OutputMessage("MSG_SYS", tconcat(msg), true)
		end
	end

	----------关于
	LR.AppendAbout(nil, frame)
end

function LR_GKP_NewMenPaiBoss_Panel:Open()
	local frame = self:Fetch("LR_GKP_NewMenPaiBoss_Panel")
	if frame then
		self:Destroy(frame)
	else
		--LR_Acc_Trade.LoadData(nil, true)
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

