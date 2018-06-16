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
---------------------------------------------------------------
---ini配置文件多重窗口
---------------------------------------------------------------
local _UI = {}

LR_GKP_Loot_Base = class()
function LR_GKP_Loot_Base.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("TEAM_AUTHORITY_CHANGED")
	this:Lookup("Btn_Close").OnLButtonClick = function()
		local _, _, dwDoodadID = sfind(this:GetRoot():GetName(), "LR_GKP_Loot_(%d+)")
		dwDoodadID = tonumber(dwDoodadID)
		_UI[dwDoodadID] = nil
		Wnd.CloseWindow(this:GetParent())
	end

	LR_GKP_Loot.UpdateAnchor(this)
end

function LR_GKP_Loot_Base.OnEvent(szEvent)
	if szEvent == "UI_SCALED" then
		LR_GKP_Loot.UpdateAnchor(this)
	elseif szEvent == "TEAM_AUTHORITY_CHANGED" then
		LR_GKP_Loot.TEAM_AUTHORITY_CHANGED()
	end
end

function LR_GKP_Loot_Base.OnFrameDragEnd()
	this:CorrectPos()
	local x, y = this:GetRelPos()
	LR_GKP_Loot.UsrData.Anchor = {x = x, y = y}
end

function LR_GKP_Loot_Base.OnFrameDestroy()

end

function LR_GKP_Loot_Base.OnMouseEnter()
	local szName = this:GetName()
	local _, _, dwDoodadID = sfind(this:GetRoot():GetName(), "LR_GKP_Loot_(%d+)")
	dwDoodadID = tonumber(dwDoodadID)
	if sfind(szName, "Window_(%d+)_(%d+)") then
		local _s, _e, dwTabType, dwIndex = sfind(szName, "Window_(%d+)_(%d+)")
		if _UI[dwDoodadID][sformat("Window_Hover_%s_%s", dwTabType, dwIndex)] then
			local w, h = _UI[dwDoodadID][sformat("Window_Hover_%s_%s", dwTabType, dwIndex)]:GetSize()
			if h > 70 then
				_UI[dwDoodadID][sformat("Window_Hover_%s_%s", dwTabType, dwIndex)]:Show()
			end
		end
	end
end

function LR_GKP_Loot_Base.OnMouseLeave()
	local szName = this:GetName()
	local _, _, dwDoodadID = sfind(this:GetRoot():GetName(), "LR_GKP_Loot_(%d+)")
	dwDoodadID = tonumber(dwDoodadID)
	if sfind(szName, "Window_(%d+)_(%d+)") then
		local _s, _e, dwTabType, dwIndex = sfind(szName, "Window_(%d+)_(%d+)")
		if _UI[dwDoodadID][sformat("Window_Hover_%s_%s", dwTabType, dwIndex)] then
			local w, h = _UI[dwDoodadID][sformat("Window_Hover_%s_%s", dwTabType, dwIndex)]:GetSize()
			if h > 70 then
				_UI[dwDoodadID][sformat("Window_Hover_%s_%s", dwTabType, dwIndex)]:Hide()
			end
		end
	end
end

---------------------------------------------------------------
---拾取面板
---------------------------------------------------------------
LR_GKP_Loot = CreateAddon("LR_GKP_Loot")
LR_GKP_Loot.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER",  x = 500, y = 500},
}
local CustomVersion = "20180102"
RegisterCustomData("LR_GKP_Loot.UsrData", CustomVersion)

local ANIMATE_SALE = {}

function LR_GKP_Loot.UpdateAnchor(frame)
	frame:SetRelPos(LR_GKP_Loot.UsrData.Anchor.x, LR_GKP_Loot.UsrData.Anchor.y)
	frame:CorrectPos()
end

function LR_GKP_Loot:Init(dwDoodadID, szDoodadName, items)
	--local frame = self:Append("Frame", "LR_GKP_Loot", {title = _L["Mini Printing Machine"] , path = "interface\\LR_Plugin\\LR_CopyBook\\UI\\MiniUI.ini"})
	local frame = Wnd.OpenWindow(sformat("%s\\UI\\GKP_Loot.ini", AddonPath), "LR_GKP_Loot_" .. dwDoodadID)
	frame:Lookup("Wnd_Title"):Lookup("",""):Lookup("Text_DoodadName"):SetText(szDoodadName)

	local Btn_Shout = LR.AppendUI("UIButton", frame, "Btn_Shout" , {x = 8 , y = 4 , w = 26 , h = 26, ani = {"ui\\Image\\UICommon\\YiRong15.UITex", 15, 16, 17}, })
	Btn_Shout.OnClick = function()
		local szDoodadName, items = LR_GKP_Base.GetItemInDoodad(dwDoodadID)
		if #items > 0 then
			local data = {}
			for k, v in pairs(items) do
				if items.nGenre == ITEM_GENRE.BOOK then
					data[#data + 1] = {type = "book", tabtype = v.dwTabType, index = v.dwIndex, bookinfo = v.nBookID}
				else
					data[#data + 1] = {type = "iteminfo", tabtype = v.dwTabType, index = v.dwIndex}
				end
			end
			LR.Talk(PLAYER_TALK_CHANNEL.RAID, data)
		end
	end
	Btn_Shout.OnEnter = function()
		local x, y =  this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = {}
		szXml[#szXml + 1] = GetFormatText(_L["Shout everything to raid channel."])
		OutputTip(tconcat(szXml), 350, {x, y, 0, 0})
	end
	Btn_Shout.OnLeave = function()
		HideTip()
	end

	local Btn_OneKey = LR.AppendUI("UIButton", frame, "Btn_OneKey" , {x = 35 , y = 4 , w = 26 , h = 26, ani = {"ui\\Image\\UICommon\\YiRong15.UITex", 12, 13, 14}, })
	Btn_OneKey.OnClick = function()
		if not LR_GKP_Base.CheckIsDistributor(true) then
			return
		end
		if not LR_GKP_Base.CheckBillExist() then
			return
		end

		local msg = {
			szMessage = _L["Are you sure to pick up all into your own bag?"],
			szName = "one key",
			fnAutoClose = function() return false end,
			{szOption = _L["Yes"], fnAction = function() LR_GKP_Base.OneKey2Self(dwDoodadID) end, },
			{szOption = _L["No"], fnAction = function()  end,},
		}
		MessageBox(msg)
	end
	Btn_OneKey.OnEnter = function()
		local x, y =  this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = {}
		szXml[#szXml + 1] = GetFormatText(_L["Pick up everything into my own bag."])
		OutputTip(tconcat(szXml), 350, {x, y, 0, 0})
	end
	Btn_OneKey.OnLeave = function()
		HideTip()
	end

	local Btn_OneKeyBoss = LR.AppendUI("UIButton", frame, "Btn_OneKeyBoss" , {x = 172 , y = 4 , w = 26 , h = 26, ani = {"ui\\Image\\UICommon\\YiRong15.UITex", 19, 20, 21}, })
	Btn_OneKeyBoss.OnClick = function()
		if not LR_GKP_Base.CheckIsDistributor(true) then
			return
		end
		if not LR_GKP_Base.CheckBillExist() then
			return
		end
		local menu = {}
		menu[#menu + 1] = {
			szOption = _L["OneKey to material boss"],
			fnAction = function()
				if LR_GKP_Base.MaterialBoss.dwID == 0 then
					LR.SysMsg(_L["Please set material boss first.\n"])
					return
				else
					local msg = {
						szMessage = _L["Are you sure to pick up material into bag of material boss?"],
						szName = "one key",
						fnAutoClose = function() return false end,
						{szOption = _L["Yes"], fnAction = function() LR_GKP_Base.OneKey2MaterialBoss(dwDoodadID) end, },
						{szOption = _L["No"], fnAction = function()  end,},
					}
					MessageBox(msg)
				end
			end,
		}
		menu[#menu + 1] = {
			szOption = _L["OneKey to smalliron boss"],
			fnAction = function()
				if LR_GKP_Base.MaterialBoss.dwID == 0 then
					LR.SysMsg(_L["Please set smalliron boss first.\n"])
					return
				else
					local msg = {
						szMessage = _L["Are you sure to pick up smalliron into bag of smalliron boss?"],
						szName = "one key",
						fnAutoClose = function() return false end,
						{szOption = _L["Yes"], fnAction = function() LR_GKP_Base.OneKey2SmallIronBoss(dwDoodadID) end, },
						{szOption = _L["No"], fnAction = function()  end,},
					}
					MessageBox(msg)
				end
			end,
		}
		menu[#menu + 1] = {
			szOption = _L["OneKey to equipment boss"],
			fnAction = function()
				if LR_GKP_Base.EquipmentBoss.dwID == 0 then
					LR.SysMsg(_L["Please set equipment boss first.\n"])
					return
				else
					local msg = {
						szMessage = _L["Are you sure to pick up equipment into bag of equipment boss?"],
						szName = "one key",
						fnAutoClose = function() return false end,
						{szOption = _L["Yes"], fnAction = function() LR_GKP_Base.OneKey2EquipmentBoss(dwDoodadID) end, },
						{szOption = _L["No"], fnAction = function()  end,},
					}
					MessageBox(msg)
				end
			end,
		}
		menu[#menu + 1] = {bDevide = true}
		LR_GKP_Base.InsertSetBossMenu(menu)

		PopupMenu(menu)
	end
	Btn_OneKeyBoss.OnRClick = function()
		local msg = {
			szMessage = _L["Are you sure to pick up items into the bag of all boss?"],
			szName = "one key",
			fnAutoClose = function() return false end,
			{szOption = _L["Yes"], fnAction = function() LR_GKP_Base.OneKey2AllBoss(dwDoodadID) end, },
			{szOption = _L["No"], fnAction = function()  end,},
		}
		MessageBox(msg)
	end
	Btn_OneKeyBoss.OnEnter = function()
		local x, y =  this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = {}
		szXml[#szXml + 1] = GetFormatText(_L["Pick up everything into the bag of  the boss."])
		OutputTip(tconcat(szXml), 350, {x, y, 0, 0})
	end
	Btn_OneKeyBoss.OnLeave = function()
		HideTip()
	end

	LR_GKP_Loot:LoadItemBox(dwDoodadID, items)
	LR.AppendAbout(LR_GKP_Loot, frame:Lookup("Wnd_Button"))

	if next(ANIMATE_SALE) ~= nil then
		FireEvent("LR_GKP_Loot_Sale", ANIMATE_SALE.dwDoodadID, ANIMATE_SALE.dwID, true)
	end
	return frame
end

function LR_GKP_Loot:LoadItemBox(dwDoodadID, items)
	local frame = Station.Lookup(sformat("Normal/LR_GKP_Loot_%d", dwDoodadID))
	if not frame then
		return
	end

	local WndContainer_LootList = frame:Lookup("Wnd_Body"):Lookup("WndContainer_LootList")
	_UI[dwDoodadID] = {}
	WndContainer_LootList:Clear()
	local data = LR_GKP_Base.GroupItem(items)

	local key = {"Armor", "Weapon", "ExchangeItem", "Material", "Other"}
	for k, v in pairs(key) do
		if next(data[v]) ~= nil then
			LR_GKP_Loot:LoadGroupWindow(WndContainer_LootList, data[v], dwDoodadID, v)
		end
	end

	WndContainer_LootList:SetSize(230, 2000)
	WndContainer_LootList:FormatAllContentPos()
	local w, h = WndContainer_LootList:GetAllContentSize()
	WndContainer_LootList:SetSize(230, h)
	LR_GKP_Loot.Resize(dwDoodadID)

	local hL = Station.Lookup("Normal/LootList")
	if hL then
		hL:SetAbsPos(4096, 4096)
	end
end

function LR_GKP_Loot:LoadGroupWindow(parent, items, dwDoodadID, key)
	local Window_Group = LR.AppendUI("Window", parent, sformat("Window_%s", key), {w = 230, h = 40})
	local Handle_Group = LR.AppendUI("Handle", Window_Group, sformat("Handle_%s", key), {x = 0, y = 0, w = 230, h = 33})
	local WndContainer_Group = LR.AppendUI("WndContainer", Window_Group, sformat("WndContainer_%s", key), {x = 5, y = 30, w = 220, h = 1000})

	local imgTab = LR.AppendUI("Image", Handle_Group, "TabImg", {w = 230, h = 30, x = 0, y = 0})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)

	local imgTitle = LR.AppendUI("Image", Handle_Group, "imgTitle", {w = 180, h = 26, x = 25, y = 2})
    imgTitle:SetImage("ui\\Image\\QuestPanel\\QuestPanelPart.UITex", 11)
	imgTitle:SetImageType(11)

	local TextTitle = LR.AppendUI("Text", Handle_Group, "TextTitle", {w = 180, h = 26, x = 25, y = 2})
	TextTitle:SetText(_L[key]):SetHAlign(1):SetVAlign(1):SetFontScheme(2)

	for k, item in pairs(items) do
		LR_GKP_Loot:LoadOneItem(WndContainer_Group, item, dwDoodadID)
	end

	WndContainer_Group:SetSize(220, 2000)
	WndContainer_Group:FormatAllContentPos()
	local w, h = WndContainer_Group:GetAllContentSize()
	WndContainer_Group:SetSize(220, h + 10)
	Window_Group:SetSize(230, h + 32 + 10)

end

function LR_GKP_Loot:LoadOneItem(parent, item, dwDoodadID)
	local v = item
	if not _UI[dwDoodadID][sformat("Window_%d_%d", v.dwTabType, v.dwIndex)] then
		local Window_Item_Group = LR.AppendUI("Window", parent, sformat("Window_%d_%d", v.dwTabType, v.dwIndex), {w= 220, h = 30})
		local Handle_Content = LR.AppendUI("Handle", Window_Item_Group, sformat("Handle_Content_%d_%d", v.dwTabType, v.dwIndex), {x = 0, y = 0, w = 220, h = 30})
		Handle_Content:Hide()

		local BG1 = LR.AppendUI("Image", Window_Item_Group, sformat("Image_BG_%d_%d", v.dwTabType, v.dwIndex), {x = 0, y = 0, w = 220, h = 30})
		BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 50):SetImageType(10)

		local Text_BG = LR.AppendUI("Image", Window_Item_Group, sformat("Text_BG_%d_%d", v.dwTabType, v.dwIndex), {x = 0, y = 8, w = 100, h = 24})
		Text_BG:FromUITex("ui\\Image\\Common\\CoverShadow.UITex", 4):SetImageType(10):Hide()

		local Text_Item = LR.AppendUI("Text", Window_Item_Group, sformat("Text_%d_%d", v.dwTabType, v.dwIndex), {x = 0, y = 8, w = 100, h = 24})
		local org, now = LR_GKP_Base.GetCount(dwDoodadID, item)
		Text_Item:SetText(sformat("%d开(剩%d)", org, now)):SetHAlign(1):SetVAlign(2):Hide()

		local BG_Hover = LR.AppendUI("Image", Window_Item_Group, sformat("Window_Hover_%d_%d", v.dwTabType, v.dwIndex), {x = 0, y = 0, w = 220, h = 30})
		BG_Hover:FromUITex("ui\\Image\\Common\\Box.UITex", 4):SetImageType(10):Hide()

		local WndContainer_Item = LR.AppendUI("WndContainer", Window_Item_Group, sformat("WndContainer_%d_%d", v.dwTabType, v.dwIndex), {x = 5, y = 5, w = 210, h = 30})
		_UI[dwDoodadID][sformat("Window_%d_%d", v.dwTabType, v.dwIndex)] = Window_Item_Group
		_UI[dwDoodadID][sformat("Handle_Content_%d_%d", v.dwTabType, v.dwIndex)] = Handle_Content
		_UI[dwDoodadID][sformat("Image_BG_%d_%d", v.dwTabType, v.dwIndex)] = BG1
		_UI[dwDoodadID][sformat("Window_Hover_%d_%d", v.dwTabType, v.dwIndex)] = BG_Hover
		_UI[dwDoodadID][sformat("WndContainer_%d_%d", v.dwTabType, v.dwIndex)] = WndContainer_Item
		_UI[dwDoodadID][sformat("Text_BG_%d_%d", v.dwTabType, v.dwIndex)] = Text_BG
		_UI[dwDoodadID][sformat("Text_%d_%d", v.dwTabType, v.dwIndex)] = Text_Item
	else
		_UI[dwDoodadID][sformat("Handle_Content_%d_%d", v.dwTabType, v.dwIndex)]:Show()
		_UI[dwDoodadID][sformat("WndContainer_%d_%d", v.dwTabType, v.dwIndex)]:SetRelPos(5, 35)
		_UI[dwDoodadID][sformat("Text_BG_%d_%d", v.dwTabType, v.dwIndex)]:Show()
		_UI[dwDoodadID][sformat("Text_%d_%d", v.dwTabType, v.dwIndex)]:Show()
	end

	local Window_Item_Group = _UI[dwDoodadID][sformat("Window_%d_%d", v.dwTabType, v.dwIndex)]
	local WndContainer_Item = _UI[dwDoodadID][sformat("WndContainer_%d_%d", v.dwTabType, v.dwIndex)]
	local BG1 = _UI[dwDoodadID][sformat("Image_BG_%d_%d", v.dwTabType, v.dwIndex)]
	local BG_Hover = _UI[dwDoodadID][sformat("Window_Hover_%d_%d", v.dwTabType, v.dwIndex)]

	local Window_Item = LR.AppendUI("Window", WndContainer_Item, sformat("Window_%d", v.dwID), {w= 210, h = 56})
	local Handle_Item = LR.AppendUI("Handle", Window_Item, "Handle_Item_" .. v.dwID, {w = 210, h = 56})
	local Image_Background = LR.AppendUI("Image", Handle_Item, "Image_Background".. v.dwID, {w = 210, h = 56, x = 0, y = 0})
	Image_Background:FromUITex("ui\\Image\\UICommon\\CommonPanel.UITex", 48):SetImageType(10):SetAlpha(200)

	local box = LR.AppendUI("Box", Handle_Item, "Box_Item_" .. v.dwID, {w = 44, h = 44})
	box:SetRelPos(8, 6)
	UpdateBoxObject(box:GetSelf(), UI_OBJECT_ITEM_ONLY_ID, v.dwID)
	--box:SetOverText(1, v.nStackNum)
	--box:SetOverTextFontScheme(1, 15)
	--box:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
	--UpdateBoxObject(box:GetSelf(), UI_OBJECT_ITEM_INFO, 1, v.dwTabType, v.dwIndex)
	local Text_Item_Name = LR.AppendUI("Text", Handle_Item, "Text_Item_Name_" .. v.dwID, {w = 140, h = 48, x = 65, y = 4, eventid = 0, font = 15})
	Text_Item_Name:SetHAlign(0)
	Text_Item_Name:SetVAlign(1)
	Text_Item_Name:SetText(v.szName)
	Text_Item_Name:SetFontColor(GetItemFontColorByQuality(v.nQuality))
	if v.nGenre == ITEM_GENRE.MATERIAL then
		for k2, v2 in pairs(g_tStrings.tForceTitle) do
			if sfind(v.szName, v2) then
				Text_Item_Name:SetFontColor(LR.GetMenPaiColor(k2))
			end
		end
	end

	local Text_Desc = LR.AppendUI("Text", Handle_Item, "Text_Desc_" .. v.dwID, {w = 210, h = 56, x = 0, y = 0, eventid = 0, font = 8, text = ""})
	Text_Desc:SetHAlign(2)
	Text_Desc:SetVAlign(2)
	if v.nGenre == ITEM_GENRE.BOOK then
		local nBookID, nSegID = GlobelRecipeID2BookID(v.nBookID)
		if GetClientPlayer().IsBookMemorized(nBookID, nSegID) then
			Text_Desc:SetText(_L["Read"])
			Text_Desc:Show()
		end
	elseif v.nGenre == ITEM_GENRE.EQUIPMENT then
		local num = LR.GetItemNumInBagAndBank(v.dwTabType, v.dwIndex, v.nBookID)
		if num > 0 then
			Text_Desc:SetText(_L["Have"])
			Text_Desc:Show()
		end
		if LR_GKP_Base.CheckIsEquipmentEquiped(sformat("%d_%d", v.dwTabType, v.dwIndex)) then
			Text_Desc:SetText(_L["Equiped"])
			Text_Desc:Show()
		end
	elseif LR_GKP_Base.IsSmallIron(v) then
		local num = LR.GetItemNumInBagAndBank(v.dwTabType, v.dwIndex, v.nBookID)
		if num > 0 then
			Text_Desc:SetText(sformat(_L["Have %d"], num))
			Text_Desc:Show()
		end
	end

	--右上角
	local tipHandle = LR.AppendUI("Handle", Handle_Item, "tipHandle_Item_" .. v.dwID, {x = 0, y = 5, w = 210, h = 26})
	tipHandle:SetHandleStyle(3)

	if true then
		local itemInfo = GetItemInfo(v.dwTabType, v.dwIndex)
		if itemInfo and itemInfo.nRecommendID and g_tTable.EquipRecommend then
			local nRecommendID = itemInfo.nRecommendID
			local t = g_tTable.EquipRecommend:Search(nRecommendID)
			if t and t.szDesc and t.szDesc ~= "" then
				local szForceTitle = g_tStrings.tForceTitle[GetClientPlayer().dwForceID]
				if sfind(t.szDesc, szForceTitle) then
					local fitHandle = LR.AppendUI("Handle", tipHandle, "fitHandle_Item_" .. v.dwID, {w = 26, h = 26})
					local imageFit = LR.AppendUI("Image", fitHandle, "imageFit_Item_" .. v.dwID, {x = 0, y = 0, w = 26, h = 26, eventid = 373})
					imageFit:FromUITex("ui\\Image\\GmPanel\\Gm2.UITex", 7):SetImageType(10):SetAlpha(180)
					_UI[dwDoodadID]["imageFit_Item_".. v.dwID] = imageFit
					imageFit.OnEnter = function()
						if _UI[dwDoodadID]["imageFit_Item_".. v.dwID] then
							_UI[dwDoodadID]["imageFit_Item_".. v.dwID]:SetAlpha(255)
						end

						local x, y = this:GetAbsPos()
						local szXml = {}
						szXml[#szXml + 1] = GetFormatText(_L["This item suits you."], 224)

						OutputTip(tconcat(szXml), 350, {x, y, 0, 0})
					end
					imageFit.OnLeave = function()
						if _UI[dwDoodadID]["imageFit_Item_".. v.dwID] then
							_UI[dwDoodadID]["imageFit_Item_".. v.dwID]:SetAlpha(180)
						end
						HideTip()
					end
				end
			end
		end
	end

	if LR_GKP_Base.IsDistributor() then
		local saleHandle = LR.AppendUI("Handle", tipHandle, "saleHandle_Item_" .. v.dwID, {w = 26, h = 26})
		local imageSale = LR.AppendUI("Image", saleHandle, "imageSale_Item_" .. v.dwID, {x = 0, y = 0, w = 26, h = 26, eventid = 373})
		imageSale:FromUITex("ui\\Image\\UICommon\\GoldTeam.UITex", 6):SetImageType(10):SetAlpha(200)
		_UI[dwDoodadID]["imageSale_Item_".. v.dwID] = imageSale
		imageSale.OnEnter = function()
			if _UI[dwDoodadID]["imageSale_Item_".. v.dwID] then
				_UI[dwDoodadID]["imageSale_Item_".. v.dwID]:FromUITex("ui\\Image\\UICommon\\GoldTeam.UITex", 7)
			end
			local last_price, data = LR_GKP_Base.GetLastItemPrice(v)

			local x, y = imageSale:GetAbsPos()
			local szXml = {}
			szXml[#szXml + 1] = GetFormatText(_L["Starting price:"], 224)
			szXml[#szXml + 1] = GetFormatText(sformat("%d\n", last_price))
			if data and last_price > 0 then
				szXml[#szXml + 1] = GetFormatText(_L["Last buyer:"], 224)
				local szPath, nFrame = GetForceImage(data.dwForceID)
				szXml[#szXml + 1] = GetFormatImage(szPath, nFrame, 24, 24)
				szXml[#szXml + 1] = GetFormatText(sformat("%s\n", data.szPurchaserName))
			end
			szXml[#szXml + 1] = GetFormatText(_L["Left click to launch the auction.\n"], 132)
			szXml[#szXml + 1] = GetFormatText(_L["Right click to cancel the auction.\n"], 132)
			OutputTip(tconcat(szXml), 350, {x, y, 0, 0})
		end
		imageSale.OnLeave = function()
			if _UI[dwDoodadID]["imageSale_Item_".. v.dwID] then
				_UI[dwDoodadID]["imageSale_Item_".. v.dwID]:FromUITex("ui\\Image\\UICommon\\GoldTeam.UITex", 6)
			end
			HideTip()
		end
		imageSale.OnClick = function()
			FireEvent("LR_GKP_Loot_Sale",dwDoodadID, v.dwID, true)
			LR_GKP_Base.GKP_BgTalk("BEGIN_AUCTION", {dwDoodadID = dwDoodadID, dwID = v.dwID})
		end
		imageSale.OnRClick = function()
			FireEvent("LR_GKP_Loot_Sale",dwDoodadID, v.dwID, false)
			LR_GKP_Base.GKP_BgTalk("CANCEL_AUCTION", {dwDoodadID = dwDoodadID, dwID = v.dwID})
		end
	else
		local last_price, data = LR_GKP_Base.GetLastItemPrice(v)
		if last_price > 0 and data then
			local warningHandle = LR.AppendUI("Handle", tipHandle, "warningHandle_Item_" .. v.dwID, {w = 22, h = 22})
			local imageWarning = LR.AppendUI("Image", warningHandle, "imageWarning_Item_" .. v.dwID, {x = 0, y = 0, w = 22, h = 22, eventid = 373})
			imageWarning:FromUITex("ui\\Image\\GmPanel\\Gm2.UITex", 9):SetImageType(10):SetAlpha(180)
			_UI[dwDoodadID]["imageWarning_Item_".. v.dwID] = imageWarning
			imageSale.OnEnter = function()
				if _UI[dwDoodadID]["imageWarning_Item_".. v.dwID] then
					_UI[dwDoodadID]["imageWarning_Item_".. v.dwID]:SetAlpha(255)
				end
				local last_price, data = LR_GKP_Base.GetLastItemPrice(v)
				local x, y = imageSale:GetAbsPos()
				local szXml = {}
				szXml[#szXml + 1] = GetFormatText(_L["Starting price:"], 224)
				szXml[#szXml + 1] = GetFormatText(sformat("%d\n", last_price))
				if data and last_price > 0 then
					szXml[#szXml + 1] = GetFormatText(_L["Last buyer:"], 224)
					local szPath, nFrame = GetForceImage(data.dwForceID)
					szXml[#szXml + 1] = GetFormatImage(szPath, nFrame, 24, 24)
					szXml[#szXml + 1] = GetFormatText(sformat("%s\n", data.szPurchaserName))
				end
				OutputTip(tconcat(szXml), 350, {x, y, 0, 0})
			end
			imageSale.OnLeave = function()
				if _UI[dwDoodadID]["imageSale_Item_".. v.dwID] then
					_UI[dwDoodadID]["imageSale_Item_".. v.dwID]:SetAlpha(180)
				end
				HideTip()
			end
		end
	end

	tipHandle:FormatAllItemPos():SetSizeByAllItemSize()
	local w1, h1 = tipHandle:GetSize()
	tipHandle:SetRelPos(210 - w1 - 5, 5)
	Handle_Item:FormatAllItemPos()

	--在拍卖中
	if true then
		local Image_SaleSelected = LR.AppendUI("Animate", Handle_Item, "Image_SaleSelected_".. v.dwID, {w = 54, h = 54, x = 3, y = 1})
		Image_SaleSelected:SetAnimate("ui\\Image\\UiCommon\\FEPanel3.UITex", 1, -1):SetAlpha(200):Hide()
		_UI[dwDoodadID]["Image_SaleSelected_".. v.dwID] = Image_SaleSelected
	end

	--悬停
	local Image_Hover = LR.AppendUI("Image", Handle_Item, "Image_Hover_".. v.dwID, {w = 210, h = 56, x = 0, y = 0})
	Image_Hover:FromUITex("ui\\Image\\Common\\Box.UITex", 9):SetImageType(10):SetAlpha(200):Hide()
	_UI[dwDoodadID]["Image_Hover".. v.dwID] = Image_Hover

	local OnEnter =function()
		local Image_Hover = _UI[dwDoodadID]["Image_Hover".. v.dwID]
		if Image_Hover then
			Image_Hover:Show()
		end
		local BG_Hover = _UI[dwDoodadID][sformat("Window_Hover_%d_%d", v.dwTabType, v.dwIndex)]
		if BG_Hover then
			local w, h = BG_Hover:GetSize()
			if h > 70 then
				BG_Hover:Show()
			end
		end

		local iteminfo = GetItemInfo(v.dwTabType, v.dwIndex)
		if iteminfo then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			if  iteminfo.nGenre and iteminfo.nGenre == ITEM_GENRE.BOOK then
				if v.nBookID then
					local dwBookID, dwSegmentID = GlobelRecipeID2BookID(v.nBookID)
					OutputBookTipByID(dwBookID, dwSegmentID, {x, y, w, h,})
				end
			else
				OutputItemTip(UI_OBJECT_ITEM_ONLY_ID, v.dwID, nil, nil, {x, y, w, h,})
			end
		end
	end

	local OnLeave = function()
		local Image_Hover = _UI[dwDoodadID]["Image_Hover".. v.dwID]
		if Image_Hover then
			Image_Hover:Hide()
		end
		local BG_Hover = _UI[dwDoodadID][sformat("Window_Hover_%d_%d", v.dwTabType, v.dwIndex)]
		if BG_Hover then
			BG_Hover:Hide()
		end

		HideTip()
	end

	local OnClick = function()
		if IsCtrlKeyDown() then
			LR.EditBox_AppendLinkItem(v)
			return
		end
		if IsAltKeyDown() then
			Addon_ExteriorViewByItemInfo(v.dwTabType, v.dwIndex)
			return
		end
		if not LR_GKP_Base.CheckIsDistributor() then
			return
		end
		if not LR_GKP_Base.CheckBillExist() then
			return
		end

		PopupMenu(LR_GKP_Loot.GetLootMenu(v))
	end

	Handle_Item.OnEnter = function()
		pcall(OnEnter)
	end

	Handle_Item.OnLeave = function()
		pcall(OnLeave)
	end

	Handle_Item.OnClick = function()
		pcall(OnClick)
	end

	------------
	WndContainer_Item:SetSize(210, 1000)
	WndContainer_Item:FormatAllContentPos()
	local w1, h1 = WndContainer_Item:GetAllContentSize()
	WndContainer_Item:SetSize(210, h1)
	Window_Item_Group:SetSize(220, h1 + 10)
	BG1:SetSize(220, h1 + 10)
	BG_Hover:SetSize(220, h1 + 10)


	if _UI[dwDoodadID][sformat("Handle_Content_%d_%d", v.dwTabType, v.dwIndex)]:IsVisible() then
		Window_Item_Group:SetSize(220, h1 + 30 + 10)
		BG1:SetSize(220, h1 + 40)
		BG_Hover:SetSize(220, h1 + 40)
	end

end

function LR_GKP_Loot.OnSale(dwDoodadID, dwItemID, bSale)
	if next(ANIMATE_SALE) ~= nil then
		if _UI[ANIMATE_SALE.dwDoodadID] then
			local Animate = _UI[ANIMATE_SALE.dwDoodadID]["Image_SaleSelected_".. ANIMATE_SALE.dwID]
			if Animate then
				Animate:Hide()
			end
		end
		ANIMATE_SALE = {}
	end
	_UI[dwDoodadID] = _UI[dwDoodadID] or {}
	local Animate = _UI[dwDoodadID]["Image_SaleSelected_".. dwItemID]
	if Animate then
		if bSale then
			Animate:Show()
		else
			Animate:Hide()
		end
	end
	ANIMATE_SALE = {dwDoodadID = dwDoodadID, dwID = dwItemID}
end

function LR_GKP_Loot.TEAM_AUTHORITY_CHANGED()
	local nAuthorityType = arg0
	local dwTeamID = arg1
	local dwOldAuthorityID = arg2
	local dwNewAuthorityID = arg3
	if nAuthorityType == TEAM_AUTHORITY_TYPE.DISTRIBUTE then
		local me = GetClientPlayer()
		if dwOldAuthorityID ~= dwNewAuthorityID and (dwOldAuthorityID == me.dwID or dwNewAuthorityID == me.dwID) then
			local _, _, dwDoodadID = sfind(this:GetRoot():GetName(), "LR_GKP_Loot_(%d+)")
			dwDoodadID = tonumber(dwDoodadID)
			local szDoodadName, items = LR_GKP_Base.GetItemInDoodad(dwDoodadID)
			if #items > 0 then
				LR_GKP_Loot.Open(dwDoodadID, szDoodadName, items)
			end
		end
	end
end

function LR_GKP_Loot.Resize(dwDoodadID)
	local frame = Station.Lookup(sformat("Normal/LR_GKP_Loot_%d", dwDoodadID))
	if not frame then
		return
	end
	local WndContainer_LootList = frame:Lookup("Wnd_Body"):Lookup("WndContainer_LootList")
	local w, h = WndContainer_LootList:GetSize()
	WndContainer_LootList:GetParent():SetSize(230, h)
	local Image_BackMiddle = frame:Lookup("Wnd_Title"):Lookup("", "Image_BackMiddle")
	Image_BackMiddle:SetSize(230, h)
	local Image_BackBottom = frame:Lookup("Wnd_Title"):Lookup("", "Image_BackBottom")
	Image_BackBottom:SetRelPos(0, h + 50)
	Image_BackBottom:GetParent():FormatAllItemPos()

	frame:Lookup("Wnd_Button"):SetRelPos(0, 50 + h)
	frame:SetSize(230, 50 + h + 29)
end

-- 界面创建
function LR_GKP_Loot.Open(dwDoodadID, szDoodadName, items)
	local frame = Station.Lookup(sformat("Normal/LR_GKP_Loot_%d", dwDoodadID))
	if frame then
		LR_GKP_Loot:LoadItemBox(dwDoodadID, items)
	else
		frame = LR_GKP_Loot:Init(dwDoodadID, szDoodadName, items)
		LR.Animate(frame):FadeIn(100):Pos({-20, -20})
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
end

function LR_GKP_Loot.Close(dwDoodadID)
	local frame = Station.Lookup(sformat("Normal/LR_GKP_Loot_%d", dwDoodadID))
	if frame then
		Wnd.CloseWindow(frame)
	end
end

function LR_GKP_Loot.ReLoadItemBox(dwDoodadID, items)
	local frame = Station.Lookup(sformat("Normal/LR_GKP_Loot_%d", dwDoodadID))
	if frame then
		LR_GKP_Loot:LoadItemBox(dwDoodadID, items)
	end
end

----------------------------------------------------------------
------分配界面
----------------------------------------------------------------
LR_GKP_Distribute_Panel = CreateAddon("LR_GKP_Distribute_Panel")
LR_GKP_Distribute_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_GKP_Distribute_Panel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER", x = 0, y = 0},
}
LR_GKP_Distribute_Panel.data = {}

function LR_GKP_Distribute_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")

	LR_GKP_Distribute_Panel.UpdateAnchor(this)
	RegisterGlobalEsc("LR_GKP_Panel", function () return true end , function() LR_GKP_Distribute_Panel:Close() end)
end

function LR_GKP_Distribute_Panel:OnEvents(event)
	if event ==  "UI_SCALED" then
		LR_GKP_Distribute_Panel.UpdateAnchor(this)
	end
end

function LR_GKP_Distribute_Panel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_GKP_Distribute_Panel.UsrData.Anchor.s, 0, 0, LR_GKP_Distribute_Panel.UsrData.Anchor.r, LR_GKP_Distribute_Panel.UsrData.Anchor.x, LR_GKP_Distribute_Panel.UsrData.Anchor.y)
end

function LR_GKP_Distribute_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_GKP_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_GKP_Distribute_Panel:OnDragEnd()
	this:CorrectPos()
	LR_GKP_Distribute_Panel.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_GKP_Distribute_Panel:Init(item, player, bModify)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local nTime = GetCurrentTime()
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local scene = me.GetScene()
	local distributorInfo = LR_GKP_Base.GetDistributorInfo()
	if not bModify then
		LR_GKP_Distribute_Panel.data = {
			szKey = sformat("%d_%d_%d_%d", nTime, item.dwTabType or 0, item.dwIndex or 0, item.dwID or 0),
			hash = tostring(GetStringCRC(LR.StrGame2DB(sformat("%d_%d_%d_%d", nTime, item.dwTabType or 0, item.dwIndex or 0, item.dwID or 0)))),
			szName = item.szName or "some one",
			dwTabType = item.dwTabType or 0,
			dwIndex = item.dwIndex or 0,
			nBookID = item.nBookID or 0,
			nStackNum = item.nStackNum or 1,
			nGenre = item.nGenre,
			szArea = realArea,
			szServer = realServer,
			dwMapID = scene.dwMapID,
			nCopyIndex = scene.nCopyIndex,
			nGold = 0,
			nSilver = 0,
			nCopper = 0,
			szDistributorName = distributorInfo.szName,
			dwDistributorForceID = distributorInfo.dwForceID,
			dwDistributorID = distributorInfo.dwID,
			szPurchaserName = player.szName or "",
			dwPurchaserForceID = player.dwForceID or 0,
			dwPurchaserID = player.dwID or 0,
			nOperationType = 0,
			szSourceName = item.szBelongDoodadName or _L["Distribute  manual"],
			nCreateTime = nTime,
			nSaveTime = nTime,
			szBelongBill = LR_GKP_Base.GKP_Bill.szName,
			nBossType = 4,
		}
	else
		LR_GKP_Distribute_Panel.data = item
		LR_GKP_Distribute_Panel.data.nSaveTime = nTime
		LR_GKP_Distribute_Panel.data.szBelongBill = LR_GKP_Base.GKP_Bill.szName
	end
	if LR.Trim(LR_GKP_Distribute_Panel.data.szSourceName) == "" then
		LR_GKP_Distribute_Panel.data.szSourceName = _L["unknown"]
	end

	local frame = self:Append("Frame", "LR_GKP_Distribute_Panel", {title = _L["Distribute Item"], path = sformat("%s\\UI\\Small2.ini", AddonPath)})

	---购买者
	local Text_Purchaser = self:Append("Text", frame, "Text_Purchaser", {x = 20, y = 50, w = 40, h = 30, text = _L["To:"]})
	local ComboBox_Purchaser = self:Append("ComboBox", frame, "ComboBox_Purchaser", {w = 100, x = 90, y = 50, text = _L["Please choose"] })
	ComboBox_Purchaser:Enable(true)
	ComboBox_Purchaser.OnClick = function (m)
		local mm = self:GetLootMenu(item)
		for k, v in pairs(mm) do
			m[#m + 1] = v
		end
		PopupMenu(m)
	end
	if player then
		ComboBox_Purchaser:SetText(player.szName)
	end
	if bModify then
		ComboBox_Purchaser:SetText(item.szPurchaserName)
	end

	local Text_ItemName = self:Append("Text", frame, "Text_ItemName", {x = 20, y = 85, w = 40, h = 30, text = _L["Item Name:"]})
	local Edit_ItemName = self:Append("Edit", frame, "Edit_ItemName", {x = 90, y = 85, h = 25, w = 120, text = ""})
	Edit_ItemName:SetText(item.szName or "")
	if item.bManual then
		Edit_ItemName:Enable(true)
	else
		Edit_ItemName:Enable(false)
	end
	local fn3 = function()
		local szText = {_L["Treasure Box"], _L["Penalty"], _L["Boss"], _L["Other"]}
		local menu = {}
		local x, y = Edit_ItemName:GetAbsPos()
		local w, h = Edit_ItemName:GetSize()
		menu.nMiniWidth = w
		menu.x = x
		menu.y = y + h
		menu.bShowKillFocus = true
		menu.bDisableSound = true
		for k, v in pairs(szText) do
			menu[#menu + 1] = {
				szOption = v,
				fnAction = function()
					local nTime = GetCurrentTime()
					Edit_ItemName:SetText(v)
					LR_GKP_Distribute_Panel.data.szKey = sformat("%d_0_0_0", nTime)
					LR_GKP_Distribute_Panel.data.hash = tostring(GetStringCRC(LR.StrGame2DB(sformat("%d_0_0_0", nTime))))
					LR_GKP_Distribute_Panel.data.dwTabType = 0
					LR_GKP_Distribute_Panel.data.dwIndex = 0
					LR_GKP_Distribute_Panel.data.szName = v
				end,
			}
		end
		PopupMenu(menu)
	end
	Edit_ItemName.OnChange = function(arg0)
		local szName = sgsub(arg0, " ", "")
		if szName == "" then
			szName = _L["Other"]
		end
		LR_GKP_Distribute_Panel.data.szName = szName
	end
	Edit_ItemName.OnSetFocus = function()
		fn3()
	end
	Edit_ItemName.OnKillFocus = function()
		LR.DelayCall(350, function()
			if IsPopupMenuOpened() then
				Wnd.CloseWindow(GetPopupMenu())
			end
		end)
	end

	local Text_Source = self:Append("Text", frame, "Text_Source", {x = 20, y = 120, w = 40, h = 30, text = _L["Source:"]})
	local Edit_Source = self:Append("Edit", frame, "Edit_Source", {x = 90, y = 120, h = 25, w = 120, text = _L["Distribute  manual"]})
	Edit_Source:Enable(false)
	if not item.bManual then
		Edit_Source:SetText(item.szSourceName or "")
	end

	local Text_Money = self:Append("Text", frame, "Text_Money", {x = 20, y = 155, w = 40, h = 30, text = _L["Money:"]})
	local Edit_Money = self:Append("Edit", frame, "Edit_Money", {x = 90, y = 155, h = 25, w = 120, text = "0"})
	Edit_Money:SetText(LR_GKP_Distribute_Panel.data.nGold or "0")
	local fn4 = function(money2)
		local money
		if money2 then
			money = sgsub(money2, "%a", "")
			if money == "" then
				money = "0"
			end
		else
			money = LR_GKP_Distribute_Panel.data.nGold or 0
		end
		money = tonumber(money)
		LR_GKP_Distribute_Panel.data.nGold = money
		local t = {10 * money, 100 * money, 1000 * money, 10000 * money, 100000 * money}
		local menu = {}
		local nX, nY = this:GetAbsPos()
		local nW, nH = this:GetSize()
		menu.x = nX
		menu.y = nY + nH
		menu.nMinWidth = nW
		menu.bShowKillFocus = true
		menu.bDisableSound = true
		for k, v in pairs(t) do
			if v <= 800000 and v >= 100 then
				menu[#menu + 1] = {
					bRichText = true,
					szOption = LR_GKP_Loot.GetMoneyTipText(v),
					fnAction = function()
						Edit_Money:SetText(v)
						LR_GKP_Distribute_Panel.data.nGold = v
					end,
				}
			end
		end
		menu[#menu + 1] = {bDevide = true}
		menu[#menu + 1] = {
			bRichText = true,
			szOption = LR_GKP_Loot.GetMoneyTipText(money),
			fnAction = function()
				Edit_Money:SetText(money)
				LR_GKP_Distribute_Panel.data.nGold = money
			end,
		}
		PopupMenu(menu)
	end

	Edit_Money.OnChange = function(arg0)
		fn4(arg0)
	end
	Edit_Money.OnSetFocus = function()
		fn4()
	end
	Edit_Money.OnKillFocus = function()
		LR.DelayCall(350, function()
			if IsPopupMenuOpened() then
				Wnd.CloseWindow(GetPopupMenu())
			end
		end)
	end

	---设置老板
	local CheckBox_Boss = LR.AppendUI("CheckBox", frame, "CheckBox_Boss", {x = 20, y = 240, w = 30, h = 30, text = _L["Set as boss"]})
	CheckBox_Boss.OnEnter = function()
		local x, y = this:GetAbsPos()
		local szXml = {}
		szXml[#szXml + 1] = GetFormatText(_L["If you want to set the boss, please press the 'OK' button after setting the boss type"], 2)
		OutputTip(tconcat(szXml), 300, {x, y, 0, 0})
	end
	CheckBox_Boss.OnLeave =function()
		HideTip()
	end
	CheckBox_Boss.OnCheck = function(arg0)
		local ComboBox_Boss = self:Fetch("ComboBox_Boss")
		if ComboBox_Boss then
			ComboBox_Boss:Enable(arg0)
		end
	end

	local ComboBox_Boss = self:Append("ComboBox", frame, "ComboBox_Boss", {x = 120, y = 240, w = 120, h = 30, text = sformat("%s%s", g_tStrings.tForceTitle[LR_GKP_Distribute_Panel.data.dwPurchaserForceID], _L["Boss"])})
	ComboBox_Boss:Enable(false)
	ComboBox_Boss.OnClick = function(m)
		local dwForceID = LR_GKP_Distribute_Panel.data.dwPurchaserForceID
		local szOption = {_L["Equipment boss"], _L["Material boss"], _L["Smalliron boss"], sformat("%s%s", g_tStrings.tForceTitle[dwForceID], _L["Boss"])}
		for k, v in pairs(szOption) do
			m[#m + 1] = {szOption = v,
				fnAction = function()
					if k == 4 then
						ComboBox_Boss:SetText(sformat("%s%s", g_tStrings.tForceTitle[dwForceID], _L["Boss"]))
					else
						ComboBox_Boss:SetText(v)
					end
					LR_GKP_Distribute_Panel.data.nBossType = k
				end,
			}
		end
		PopupMenu(m)
	end

	local Btn_OK = self:Append("Button", frame, "Btn_OK", {text = _L["OK"] , x = 85, y = 200, w = 80, h = 36})
	Btn_OK.OnClick = function()
		if next(LR_GKP_Base.GKP_Bill or {}) == nil then
			LR_GKP_Panel:CheckBill()
		else
			--先保存一波
			local DB = SQLite3_Open(DB_Path)
			DB:Execute("BEGIN TRANSACTION")
			LR_GKP_Base.SaveSingleData(DB, LR_GKP_Distribute_Panel.data)
			DB:Execute("END TRANSACTION")
			DB:Release()
			--
			LR_GKP_Base.GKP_BgTalk("SYNC_BEGIN", {})
			LR_GKP_Base.GKP_BgTalk("SYNC", LR_GKP_Distribute_Panel.data)
			LR_GKP_Base.GKP_BgTalk("SYNC_END", {})

			local p = {
				szName = LR_GKP_Distribute_Panel.data.szPurchaserName,
				dwID = LR_GKP_Distribute_Panel.data.dwPurchaserID,
				dwForceID = LR_GKP_Distribute_Panel.data.dwPurchaserForceID,
			}
			LR_GKP_Base.ShoutDistributeItemToRaid(LR_GKP_Distribute_Panel.data, p)

			if CheckBox_Boss:IsChecked() then
				local nBossType = LR_GKP_Distribute_Panel.data.nBossType
				local data = LR_GKP_Distribute_Panel.data
				if nBossType == 1 then
					LR_GKP_Base.EquipmentBoss = {dwID = data.dwPurchaserID, szName = data.szPurchaserName, dwForceID = data.dwPurchaserForceID}
				elseif nBossType == 2 then
					LR_GKP_Base.MaterialBoss = {dwID = data.dwPurchaserID, szName = data.szPurchaserName, dwForceID = data.dwPurchaserForceID}
				elseif nBossType == 3 then
					LR_GKP_Base.SmallIronBoss = {dwID = data.dwPurchaserID, szName = data.szPurchaserName, dwForceID = data.dwPurchaserForceID}
				elseif nBossType == 4 then
					LR_GKP_Base.MenPaiBoss[data.dwPurchaserForceID] = {dwID = data.dwPurchaserID, szName = data.szPurchaserName, dwForceID = data.dwPurchaserForceID}
				end
			end

			self:Close()
		end
	end

	local Btn_Close = frame:Lookup("Btn_Close")
	Btn_Close.OnLButtonClick = function()
		if item.bManual then
			self:Close()
		else
			if next(LR_GKP_Base.GKP_Bill or {}) == nil then
				LR_GKP_Panel:CheckBill()
			else
				--先保存一波
				local DB = SQLite3_Open(DB_Path)
				DB:Execute("BEGIN TRANSACTION")
				LR_GKP_Base.SaveSingleData(DB, LR_GKP_Distribute_Panel.data)
				DB:Execute("END TRANSACTION")
				DB:Release()
				--
				LR_GKP_Base.GKP_BgTalk("SYNC_BEGIN", {})
				LR_GKP_Base.GKP_BgTalk("SYNC", LR_GKP_Distribute_Panel.data)
				LR_GKP_Base.GKP_BgTalk("SYNC_END", {})

				local p = {
					szName = LR_GKP_Distribute_Panel.data.szPurchaserName,
					dwID = LR_GKP_Distribute_Panel.data.dwPurchaserID,
					dwForceID = LR_GKP_Distribute_Panel.data.dwPurchaserForceID,
				}
				LR_GKP_Base.ShoutDistributeItemToRaid(LR_GKP_Distribute_Panel.data, p)

				self:Close()
			end
		end
	end

	----------关于
	LR.AppendAbout(LR_GKP_Panel, frame)
end

function LR_GKP_Distribute_Panel:Close()
	local frame = self:Fetch("LR_GKP_Distribute_Panel")
	if frame then
		self:Destroy(frame)
	end
end


function LR_GKP_Distribute_Panel:Open(item, player, bModify)
	local frame = self:Fetch("LR_GKP_Distribute_Panel")
	if frame then
		LR.SysMsg(_L["Please close last panel.\n"])
	else
		local me = GetClientPlayer()
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
				{szOption = _L["Load"], fnAction = function() LR.DelayCall(500, function() PopupMenu(LR_GKP_Panel:CreateBillMenu()) end) end,},
			}
			MessageBox(msg)
		else
			frame = self:Init(item or {}, player or {}, bModify)
			PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
		end
	end
end

function LR_GKP_Distribute_Panel:GetLootMenu(item)
	local menu = {}
	local looterList
	local doodad
	if item and item.nBelongDoodadID then
		doodad = GetDoodad(item.nBelongDoodadID)
	end
	if not item or item.bManual or not doodad or not item.nBelongDoodadID then
		looterList = LR_GKP_Base.GetTeamMemberList()
	else
		looterList = LR_GKP_Base.GetLooterList(item.nBelongDoodadID)
	end
	if LR_GKP_Base.Last_Trade[sformat("%d_%d", item.dwTabType, item.dwIndex)] then
		tinsert(looterList, 1, "")
		tinsert(looterList, 1, LR_GKP_Base.Last_Trade[sformat("%d_%d", item.dwTabType, item.dwIndex)])
		tinsert(looterList, 1, _L["Last distribute"])
	end
	for k, v in pairs (looterList) do
		if type(v) == "table" then
			local szIcon, nFrame = GetForceImage(v.dwForceID)
			menu[#menu + 1] = {
				szOption = v.szName,
				bDisable = not v.bOnlineFlag,
				rgb = { LR.GetMenPaiColor(v.dwForceID) },
				szIcon = szIcon,
				nFrame = nFrame,
				szLayer = "ICON_RIGHT",
				fnAction = function()
					local ComboBox_Purchaser = self:Fetch("ComboBox_Purchaser")
					if ComboBox_Purchaser then
						ComboBox_Purchaser:SetText(v.szName)
					end
					local ComboBox_Boss = self:Fetch("ComboBox_Boss")
					if ComboBox_Boss then
						ComboBox_Boss:SetText(sformat("%s%s", g_tStrings.tForceTitle[v.dwForceID], _L["Boss"]))
					end

					LR_GKP_Distribute_Panel.data.szPurchaserName = v.szName
					LR_GKP_Distribute_Panel.data.dwPurchaserForceID = v.dwForceID
					LR_GKP_Distribute_Panel.data.dwPurchaserID = v.dwID
				end,
			}
		else
			if v == "" then
				menu[#menu + 1] = {bDevide = true}
			else
				menu[#menu + 1] = {szOption = v, bDisable = true}
			end
		end
	end
	return menu
end


------------------------------------------
function LR_GKP_Loot.GetMoneyTipText(nGold)
	local szUitex = "ui/image/common/money.UITex"
	local r, g, b = LR_GKP_Base.GetMoneyCol(nGold)
	if nGold >= 0 then
		return GetFormatText(math.floor(nGold / 10000), 41, r, g, b) .. GetFormatImage(szUitex, 27) .. GetFormatText(math.floor(nGold % 10000), 41, r, g, b) .. GetFormatImage(szUitex, 0)
	else
		nGold = nGold * -1
		return GetFormatText("-" .. math.floor(nGold / 10000), 41, r, g, b) .. GetFormatImage(szUitex, 27) .. GetFormatText(math.floor(nGold % 10000), 41, r, g, b) .. GetFormatImage(szUitex, 0)
	end
end

function LR_GKP_Loot.DistributeCheck(dwDoodadID)
	local me = GetClientPlayer()
	if not me then
		return false
	end
	local team = GetClientTeam()
	if not team then
		return false
	end
	if dwDoodadID then
		local doodad = GetDoodad(dwDoodadID)
		if not doodad then
			return false
		end
		local dwBelongTeamID = doodad.GetBelongTeamID()
		if dwBelongTeamID ~= team.dwTeamID then
			--OutputMessage("MSG_ANNOUNCE_RED",g_tStrings.ERROR_LOOT_DISTRIBUTE)
			return false
		end
	end
	local dwDistributorID = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
	if dwDistributorID ~= me.dwID then
		--OutputMessage("MSG_ANNOUNCE_RED",g_tStrings.ERROR_LOOT_DISTRIBUTE)
		return false
	end
	return true
end

function LR_GKP_Loot.GetLootMenu(item)
	local menu = {}
	menu.nMiniWidth = 120
	if not LR_GKP_Loot.DistributeCheck(item.nBelongDoodadID) then
		return {}
	end
	menu[#menu + 1] = {szOption = item.szName, bDisable = true,}
	menu[#menu + 1] = {bDevide = true}
	local looterList = LR_GKP_Base.GetLooterList(item.nBelongDoodadID)
	if LR_GKP_Base.Last_Trade[sformat("%d_%d", item.dwTabType, item.dwIndex)] then
		tinsert(looterList, 1, "")
		tinsert(looterList, 1, LR_GKP_Base.Last_Trade[sformat("%d_%d", item.dwTabType, item.dwIndex)])
		tinsert(looterList, 1, _L["Last distribute"])
	end

	for k, v in pairs (looterList) do
		if type(v) ~= "table" then
			if v == "" then
				menu[#menu + 1] = {bDevide = true}
			else
				menu[#menu + 1] = {szOption = v, bDisable = true}
			end
		else
			local szIcon, nFrame = GetForceImage(v.dwForceID)
			menu[#menu + 1] = {
				szOption = v.szName,
				bDisable = not v.bOnlineFlag,
				rgb = { LR.GetMenPaiColor(v.dwForceID) },
				szIcon = szIcon,
				nFrame = nFrame,
				szLayer = "ICON_RIGHT",
				fnAction = function()
					if next(LR_GKP_Base.GKP_Bill or {}) == nil then
						LR_GKP_Panel:CheckBill()
					else
						local Distribute_Frame = Station.Lookup("Normal/LR_GKP_Distribute_Panel")
						if Distribute_Frame then
							LR.SysMsg(_L["You should distribute other item first.\n"])
							return
						end
						local doodad = GetDoodad(item.nBelongDoodadID)
						if doodad then
							local item2 = doodad.GetLootItem(item.nIndex, GetClientPlayer())
							if item2 and item2.dwID == item.dwID then
								if item2.nQuality >= 3 then
									local msg =
									{
										szMessage = FormatLinkString(
											g_tStrings.PARTY_DISTRIBUTE_ITEM_SURE,
											"font=162",
											GetFormatText("["..GetItemNameByItem(item2).."]", "166"..GetItemFontColorByQuality(item2.nQuality, true)),
											GetFormatText("["..v.szName.."]", 162)
											),
										szName = "Distribute_Item_Sure" .. item2.dwID,
										bRichText = true,
										{szOption = g_tStrings.STR_HOTKEY_SURE,
											fnAction = function()
												local doodad = GetDoodad(item.nBelongDoodadID)
												if doodad then
													if LR_GKP_Base.DistributeItem(item, v) then
														LR_GKP_Distribute_Panel:Open(item, v)
													end
												end
											end
										},
										{szOption = g_tStrings.STR_HOTKEY_CANCEL},
									}
									MessageBox(msg)
								else
									if LR_GKP_Base.DistributeItem(item, v) then
										LR_GKP_Distribute_Panel:Open(item, v)
									end
								end
							else
								LR.SysMsg("Item error, please pick again.\n")
							end
						else
							LR.SysMsg("Doodad error, please check.\n")
						end
					end
				end,
			}
		end
	end
	return menu
end

function LR_GKP_Loot.DistributeItem(player, item)
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_GKP_Loot.DistributeCheck(item.nBelongDoodadID) then
		return
	end
	local doodad = GetDoodad(item.nBelongDoodadID)
	if not doodad then
		return
	end
	local itm = GetItem(item.dwID)
	if not itm then
		return
	end
	local team = GetClientTeam()
	local player2 = team.GetMemberInfo(player.dwID)
	if not player2 or (player2 and not player2.bIsOnLine) then -- 不在线
		LR.RedAlert(_L["1.No Pick up Object, may due to Network off - line"])
		return
	end
	if player2.dwMapID ~= me.GetMapID() then -- 不在同一地图
		LR.RedAlert(_L["2.No Pick up Object, Please confirm that in the Dungeon."])
		return
	end
	if not LR_GKP_Loot.CheckLooterListCanLoot(player.dwID, item.nBelongDoodadID) then -- 给不了
		LR.RedAlert(_L["3.No Pick up Object, may due to Network off - line"])
		return
	end
	doodad.DistributeItem(item.dwID, player.dwID)
	LR_GKP_Distribute_Panel:Open(item, player)
end

function LR_GKP_Loot.CheckLooterListCanLoot(dwPlayerID, dwDoodadID)
	local looterList = LR_GKP_Base.GetLooterList(dwDoodadID)
	for k, v in pairs(looterList) do
		if v.dwID == dwPlayerID then
			return v.bOnlineFlag
		end
	end
	return false
end

---------------------------------
function LR_GKP_Loot.OPEN_DOODAD()
	local dwDoodadID = arg0
	local dwPlayerID = arg1

	local me = GetClientPlayer()
	if not me then
		return
	end
	if dwPlayerID ~=  me.dwID then
		return
	end

	local szDoodadName, items = LR_GKP_Base.GetItemInDoodad(dwDoodadID)
	if #items > 0 then
		LR_GKP_Loot.Open(dwDoodadID, szDoodadName, items)
		_SYNCED_LOOT_NUM[dwDoodadID] = #items
		_SYNCED_LOOT_LIST[dwDoodadID] = true
	end
end

local _SYNCED_LOOT_LIST = {}		--假如没拾取过，则，第一次自动弹出
local _SYNCED_LOOT_NUM = {}
function LR_GKP_Loot.SYNC_LOOT_LIST()
	local dwDoodadID = arg0
	local frame = Station.Lookup(sformat("Normal/LR_GKP_Loot_%d", dwDoodadID))
	if frame  then
		local szDoodadName, items = LR_GKP_Base.GetItemInDoodad(dwDoodadID)
		if #items > 0 then
			if not (_SYNCED_LOOT_NUM[dwDoodadID] and #items == _SYNCED_LOOT_NUM[dwDoodadID]) then
				LR_GKP_Loot.Open(dwDoodadID, szDoodadName, items)
				_SYNCED_LOOT_NUM[dwDoodadID] = #items
			end
		else
			LR_GKP_Loot.Close(dwDoodadID)
		end
		_SYNCED_LOOT_LIST[dwDoodadID] = true
	end
end

function LR_GKP_Loot.DOODAD_LEAVE_SCENE()
	local dwDoodadID = arg0
	LR_GKP_Loot.Close(dwDoodadID)
end

LR.RegisterEvent("OPEN_DOODAD", function() LR_GKP_Loot.OPEN_DOODAD() end)
LR.RegisterEvent("SYNC_LOOT_LIST", function() LR_GKP_Loot.SYNC_LOOT_LIST() end)
LR.RegisterEvent("DOODAD_LEAVE_SCENE", function() LR_GKP_Loot.DOODAD_LEAVE_SCENE() end)
LR.RegisterEvent("LR_GKP_Loot_Sale", function() LR_GKP_Loot.OnSale(arg0, arg1, arg2) end)


