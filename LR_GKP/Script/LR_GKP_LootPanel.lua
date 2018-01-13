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
LR_GKP_Loot_Base = class()
function LR_GKP_Loot_Base.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")

	this:Lookup("Btn_Close").OnLButtonClick = function()
		Wnd.CloseWindow(this:GetParent())
	end

	LR_GKP_Loot.UpdateAnchor(this)
end

function LR_GKP_Loot_Base.OnEvent(szEvent)
	if szEvent == "UI_SCALED" then
		LR_GKP_Loot.UpdateAnchor(this)
	end
end

function LR_GKP_Loot_Base.OnFrameDragEnd()
	this:CorrectPos()
	local x, y = this:GetRelPos()
	LR_GKP_Loot.UsrData.Anchor = {x = x, y = y}
end

function LR_GKP_Loot_Base.OnFrameDestroy()

end

---------------------------------------------------------------
---拾取面板
---------------------------------------------------------------
LR_GKP_Loot = CreateAddon("LR_GKP_Loot")
LR_GKP_Loot.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER",  x = 500, y = 500},
}
local _UI = {}

local CustomVersion = "20180102"
RegisterCustomData("LR_GKP_Loot.UsrData", CustomVersion)

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
		local memberList = LR_GKP_Base.GetTeamMemberList()
		--材料老板设置
		menu[#menu + 1] = {
			szOption = _L["Set material boss"],
		}
		local m = menu[#menu]
		for k, v in pairs(memberList) do
			local szIcon, nFrame = GetForceImage(v.dwForceID)
			m[#m + 1] = {
				szOption = v.szName,
				bCheck = true,
				bMCheck = true,
				bChecked = function() return LR_GKP_Base.MaterialBoss.dwID == v.dwID end,
				rgb = { LR.GetMenPaiColor(v.dwForceID) },
				szIcon = szIcon,
				nFrame = nFrame,
				szLayer = "ICON_RIGHT",
				fnAction = function()
					LR_GKP_Base.MaterialBoss = {dwID = v.dwID, szName = v.szName, dwForceID = v.dwForceID}
				end,
			}
		end
		menu[#menu + 1] = {
			szOption = _L["Set equipment boss"],
		}
		local m2 = menu[#menu]
		for k, v in pairs(memberList) do
			local szIcon, nFrame = GetForceImage(v.dwForceID)
			m2[#m2 + 1] = {
				szOption = v.szName,
				bCheck = true,
				bMCheck = true,
				bChecked = function() return LR_GKP_Base.EquipmentBoss.dwID == v.dwID end,
				rgb = { LR.GetMenPaiColor(v.dwForceID) },
				szIcon = szIcon,
				nFrame = nFrame,
				szLayer = "ICON_RIGHT",
				fnAction = function()
					LR_GKP_Base.EquipmentBoss = {dwID = v.dwID, szName = v.szName, dwForceID = v.dwForceID}
				end,
			}
		end

		PopupMenu(menu)
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
	frame:Lookup("Wnd_Button"):Lookup("Wnd_About"):SetRelPos(95, 8)

	return frame
end

function LR_GKP_Loot:LoadItemBox(dwDoodadID, items)
	local frame = Station.Lookup(sformat("Normal/LR_GKP_Loot_%d", dwDoodadID))
	if not frame then
		return
	end
	local Handle_LootList = frame:Lookup("Wnd_Body"):Lookup("","")
	Handle_LootList:SetHandleStyle(3)
	_UI[dwDoodadID] = {}
	Handle_LootList:Clear()

	for k, v in pairs(items) do
		local Handle_Item = LR.AppendUI("Handle", Handle_LootList, "Handle_Item_".. k, {w = 215, h = 56})
		local Image_Background = LR.AppendUI("Image", Handle_Item, "Image_Background".. k, {w = 215, h = 56, x = 0, y = 0})
		--Image_Background:FromUITex("ui\\Image\\UICommon\\CommonPanel.UITex", 45)	--可以试试15
		Image_Background:FromUITex("ui\\Image\\UICommon\\rankingpanel.UITex", 16)
		Image_Background:SetAlpha(200)

		_UI[dwDoodadID]["Image_Hover".. v.dwID] = self:Append("Image", Handle_Item, "Image_Hover".. v.dwID, {w = 215, h = 56, x = 0, y = 0})
		_UI[dwDoodadID]["Image_Hover".. v.dwID]:FromUITex("ui\\Image\\UICommon\\rankingpanel.UITex", 17)
		_UI[dwDoodadID]["Image_Hover".. v.dwID]:SetAlpha(200)
		_UI[dwDoodadID]["Image_Hover".. v.dwID]:Hide()

		local box = LR.ItemBox:new(v)
		box:Create(Handle_Item, {width = 48, height = 48})
		box:SetRelPos(5, 4)

		--[[
		local Box_Item_Icon = LR.AppendUI("Box", Handle_Item, "Box_Item_Icon_".. k, {w = 48, h = 48, x = 5, y = 4, eventid = 0})
		Box_Item_Icon:SetObject(1)
		Box_Item_Icon:SetObjectIcon(Table_GetItemIconID(v.nUiId))
		]]

		local Text_Item_Name = LR.AppendUI("Text", Handle_Item, "Text_Item_Name_".. k, {w = 140, h = 48, x = 65, y = 4, eventid = 0, font = 15})
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

		--local Image_Item = LR.AppendUI("Image", Handle_Item, "Image_Item_".. k, {w = 56, h = 56, x = 5, y = 0})
		--Image_Item:FromUITex("ui\\Image\\Common\\Box.UITex",41)
		local OnEnter =function()
			local Image_Hover = _UI[dwDoodadID]["Image_Hover".. v.dwID]
			if Image_Hover then
				Image_Hover:Show()
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
			HideTip()
		end

		local OnClick = function()
			if IsCtrlKeyDown() then
				EditBox_AppendLinkItemInfo(1, v.dwTabType, v.dwIndex, v.nBookID)
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

		box:OnItemMouseEnter(function()
			pcall(OnEnter)
		end)
		box:OnItemMouseLeave(function()
			pcall(OnLeave)
		end)
		box:OnItemLButtonClick(function()
			pcall(OnClick)
		end)

		Handle_Item.OnEnter = function()
			pcall(OnEnter)
		end

		Handle_Item.OnLeave = function()
			pcall(OnLeave)
		end

		Handle_Item.OnClick = function()
			pcall(OnClick)
		end

	end
	Handle_LootList:FormatAllItemPos()
	LR_GKP_Loot.Resize(dwDoodadID)

	local hL = Station.Lookup("Normal/LootList")
	if hL then
		hL:SetAbsPos(4096, 4096)
	end
end

function LR_GKP_Loot.Resize(dwDoodadID)
	local frame = Station.Lookup(sformat("Normal/LR_GKP_Loot_%d", dwDoodadID))
	if not frame then
		return
	end
	local Handle_LootList = frame:Lookup("Wnd_Body"):Lookup("","")
	local w, h = Handle_LootList:GetAllItemSize()
	Handle_LootList:SetSize(w, h)
	Handle_LootList:GetParent():SetSize(230, h)
	local Image_BackMiddle = frame:Lookup("Wnd_Title"):Lookup("", "Image_BackMiddle")
	Image_BackMiddle:SetSize(230, h)
	local Image_BackBottom = frame:Lookup("Wnd_Title"):Lookup("", "Image_BackBottom")
	Image_BackBottom:SetRelPos(0, h + 50)
	Image_BackBottom:GetParent():FormatAllItemPos()

	Handle_LootList:FormatAllItemPos()

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
	RegisterGlobalEsc("LR_GKP_Panel", function () return true end , function() LR_GKP_Distribute_Panel:Open() end)
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
		LR.DelayCall(100, function()
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
		LR.DelayCall(100, function()
			if IsPopupMenuOpened() then
				Wnd.CloseWindow(GetPopupMenu())
			end
		end)
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

			local data = {}
			data[#data + 1] = {type = "name", name = LR_GKP_Distribute_Panel.data.szDistributorName}
			data[#data + 1] = {type = "text", text = _L["Jiang"]}
			if LR_GKP_Distribute_Panel.data.dwTabType == 0 then
				data[#data + 1] = {type = "text", text = sformat("[%s]", LR_GKP_Distribute_Panel.data.szName)}
			else
				if LR_GKP_Distribute_Panel.data.nGenre == ITEM_GENRE.BOOK then
					data[#data + 1] = {type = "book", tabtype = LR_GKP_Distribute_Panel.data.dwTabType, index = LR_GKP_Distribute_Panel.data.dwIndex, bookinfo = LR_GKP_Distribute_Panel.data.nBookID}
				else
					data[#data + 1] = {type = "iteminfo", tabtype = LR_GKP_Distribute_Panel.data.dwTabType, index = LR_GKP_Distribute_Panel.data.dwIndex}
				end
			end
			data[#data + 1] = {type = "text", text = sformat(_L["for %d Gold dis to"], LR_GKP_Distribute_Panel.data.nGold)}
			data[#data + 1] = {type = "name", name = LR_GKP_Distribute_Panel.data.szPurchaserName}
			GetClientPlayer().Talk(PLAYER_TALK_CHANNEL.RAID, "", data)
			self:Open()
		end
	end

	local Btn_Close = frame:Lookup("Btn_Close")
	Btn_Close.OnLButtonClick = function()
		if item.bManual then
			self:Open()
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

				local data = {}
				data[#data + 1] = {type = "name", name = LR_GKP_Distribute_Panel.data.szDistributorName}
				data[#data + 1] = {type = "text", text = _L["Jiang"]}
				if LR_GKP_Distribute_Panel.data.dwTabType == 0 then
					data[#data + 1] = {type = "text", text = sformat("[%s]", LR_GKP_Distribute_Panel.data.szName)}
				else
					if LR_GKP_Distribute_Panel.data.nGenre == ITEM_GENRE.BOOK then
						data[#data + 1] = {type = "book", tabtype = LR_GKP_Distribute_Panel.data.dwTabType, index = LR_GKP_Distribute_Panel.data.dwIndex, bookinfo = LR_GKP_Distribute_Panel.data.nBookID}
					else
						data[#data + 1] = {type = "iteminfo", tabtype = LR_GKP_Distribute_Panel.data.dwTabType, index = LR_GKP_Distribute_Panel.data.dwIndex}
					end
				end
				data[#data + 1] = {type = "text", text = sformat(_L["for %d Gold dis to"], LR_GKP_Distribute_Panel.data.nGold)}
				data[#data + 1] = {type = "name", name = LR_GKP_Distribute_Panel.data.szPurchaserName}
				GetClientPlayer().Talk(PLAYER_TALK_CHANNEL.RAID, "", data)

				self:Open()
			end
		end
	end

	----------关于
	LR.AppendAbout(LR_GKP_Panel, frame)
end

function LR_GKP_Distribute_Panel:Open(item, player, bModify)
	local frame = self:Fetch("LR_GKP_Distribute_Panel")
	if frame then
		self:Destroy(frame)
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
	for k, v in pairs (looterList) do
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
				LR_GKP_Distribute_Panel.data.szPurchaserName = v.szName
				LR_GKP_Distribute_Panel.data.dwPurchaserForceID = v.dwForceID
				LR_GKP_Distribute_Panel.data.dwPurchaserID = v.dwID
			end,
		}
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
	for k, v in pairs (looterList) do
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
												--LR_GKP_Loot.DistributeItem(v, item)
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
								--LR_GKP_Loot.DistributeItem(v, item)
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
	end
end

local _SYNCED_LOOT_LIST = {}		--假如没拾取过，则，第一次自动弹出
local _SYNCED_LOOT_NUM = {}
function LR_GKP_Loot.SYNC_LOOT_LIST()
	local dwDoodadID = arg0
	local frame = Station.Lookup(sformat("Normal/LR_GKP_Loot_%d", dwDoodadID))
	if frame or not _SYNCED_LOOT_LIST[dwDoodadID] then
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

function LR_GKP_Loot.Test(n)
	local items = {}
	local me = GetClientPlayer()
	for i = 1, n do
		local item = me.GetItem(2, i)
			local data = LR_GKP_Base.GetItemData(item)
			items[#items + 1] = clone(data)
	end

	LR_GKP_Loot.Open(111, "sdf", items)
end


LR.RegisterEvent("OPEN_DOODAD", function() LR_GKP_Loot.OPEN_DOODAD() end)
LR.RegisterEvent("SYNC_LOOT_LIST", function() LR_GKP_Loot.SYNC_LOOT_LIST() end)
LR.RegisterEvent("DOODAD_LEAVE_SCENE", function() LR_GKP_Loot.DOODAD_LEAVE_SCENE() end)


