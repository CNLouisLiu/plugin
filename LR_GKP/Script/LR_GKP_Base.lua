local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_GKP"
local SaveDataPath="Interface\\LR_Plugin@DATA\\LR_GKP"
local _L = LR.LoadLangPack(AddonPath)
local DB_Name = "LR_GKP.db"
local DB_Path = sformat("%s\\%s", SaveDataPath, DB_Name)
local VERSION = "20180104"
---------------------------------------------------------------
local OPERATION_TYPE = {
	ADD = 1,
	MODIFY = 2,
	DEL = 3,
	SYNC = 4,
}

local tEquipPos = {
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
---------------------------------------------------------------
local _GKP = {}
--------------------
LR_GKP_Base = {}
local DefaultData = {
	bOn = true,
	lastLoadBill = "",
}
LR_GKP_Base.UsrData = clone(DefaultData)
RegisterCustomData("LR_GKP_Base.UsrData", CustomVersion)
---------------------------------------------------------------
local MATERIAL = LoadLUAData(sformat("%s\\Script\\material", AddonPath)) or {}
local SMALL_IRON = {
	["5_6629"] = true,
	["5_10359"] = true,
	["5_19283"] = true,
	["5_25829"] = true,
}

function _GKP.IsMaterial(item)
	if not item or not item.dwTabType or not item.dwIndex then
		return false
	end
	local szKey = sformat("%d_%d", item.dwTabType, item.dwIndex)
	return MATERIAL[szKey] or false
end

function _GKP.IsSmallIron(item)
	if not item or not item.dwTabType or not item.dwIndex then
		return false
	end
	local szKey = sformat("%d_%d", item.dwTabType, item.dwIndex)
	return SMALL_IRON[szKey] or false
end

function _GKP.GroupItem(items)
	local Grouped_Items = {}
	Grouped_Items["Weapon"] = {}		--武器
	Grouped_Items["Armor"] = {}			--防具(散件)
	Grouped_Items["ExchangeItem"] = {}	--兑换牌
	Grouped_Items["Material"] = {}	--材料
	Grouped_Items["Other"] = {}	--其他
	for k, item in pairs(items) do
		if item.nGenre == ITEM_GENRE.EQUIPMENT then
			if item.nSub == 0 then		--近身武器
				Grouped_Items["Weapon"][#Grouped_Items["Weapon"] + 1] = clone(item)
			elseif item.nSub >= 1 and item.nSub <= 11 then
				Grouped_Items["Armor"][#Grouped_Items["Armor"] + 1] = clone(item)
			else
				Grouped_Items["Other"][#Grouped_Items["Other"] + 1] = clone(item)
			end
		elseif item.nGenre == ITEM_GENRE.MATERIAL and item.nSub == 6 then
			Grouped_Items["ExchangeItem"][#Grouped_Items["ExchangeItem"] + 1] = clone(item)
		elseif _GKP.IsMaterial(item) then
			Grouped_Items["Material"][#Grouped_Items["Material"] + 1] = clone(item)
		elseif _GKP.IsSmallIron(item) then
			Grouped_Items["Other"][#Grouped_Items["Other"] + 1] = clone(item)
		elseif item.nGenre == ITEM_GENRE.MATERIAL and item.nSub == 0 then	--秦风部分牌子
			local _s, _e, m, n = sfind(itemInfo.szName, _L["qinfeng(.+).(.+)"])
			if _s then
				Grouped_Items["ExchangeItem"][#Grouped_Items["ExchangeItem"] + 1] = clone(item)
			else
				Grouped_Items["Other"][#Grouped_Items["Other"] + 1] = clone(item)
			end
		else
			Grouped_Items["Other"][#Grouped_Items["Other"] + 1] = clone(item)
		end
	end
	return Grouped_Items
end

LR_GKP_Base.GKP_Bill = {}	--GKP记录的账单号信息
LR_GKP_Base.GKP_TradeList = {}	--GKP的记录内容
LR_GKP_Base.GKP_Person_Trade = {}	--个人消费总金额
LR_GKP_Base.GKP_Person_Debt = {}		--个人欠账
LR_GKP_Base.GKP_Person_Cash = {}		--个人交易金钱记录--数据库 + 缓存
LR_GKP_Base.GKP_Person_Cash_Temp = {}	--个人交易记录缓存
LR_GKP_Base.Last_Trade = {} --记录物品上一次的购买者
_GKP.Sale_Item_History = {}

LR_GKP_Base.SmallIronBoss = {dwID = 0, szName = "0", dwForceID = 0}
LR_GKP_Base.MaterialBoss = {dwID = 0, szName = "0", dwForceID = 0}
LR_GKP_Base.EquipmentBoss = {dwID = 0, szName = "0", dwForceID = 0}
LR_GKP_Base.MenPaiBoss = {}

_GKP.DoodadOriginalCount = {}
_GKP.DoodadCount = {}

_GKP.szSearchKey = "nCreateTime"
_GKP.szOrderKey = "DESC"

------------------------------------------------------------------
function _GKP.IsSpecialWeapon(item)
	local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
	if not itemInfo then
		return false
	end
	if not (itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and itemInfo.nSub == 0) then
		return false
	end
	local magicAttrib = GetItemMagicAttrib(itemInfo.GetMagicAttribIndexList())
	for k2, v2 in pairs(magicAttrib) do
		if v2.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
			return true
		elseif v2.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then
			return true
		end
	end
	local desc = Table_GetItemDesc(itemInfo.nUiId)
	if sfind(ssub(desc, 1, 50), _L["Use:"]) then
		return true
	end
	return false
end

function _GKP.InsertSetBossMenu(menu)
	local me = GetClientPlayer()
	if not me then
		return {}
	end
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
	--小铁老板设置
	menu[#menu + 1] = {
		szOption = _L["Set smalliron boss"],
	}
	local m = menu[#menu]
	for k, v in pairs(memberList) do
		local szIcon, nFrame = GetForceImage(v.dwForceID)
		m[#m + 1] = {
			szOption = v.szName,
			bCheck = true,
			bMCheck = true,
			bChecked = function() return LR_GKP_Base.SmallIronBoss.dwID == v.dwID end,
			rgb = { LR.GetMenPaiColor(v.dwForceID) },
			szIcon = szIcon,
			nFrame = nFrame,
			szLayer = "ICON_RIGHT",
			fnAction = function()
				LR_GKP_Base.SmallIronBoss = {dwID = v.dwID, szName = v.szName, dwForceID = v.dwForceID}
			end,
		}
	end
	--散件老板
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

	return menu
end

function _GKP.GetDistributorInfo()
	local me = GetClientPlayer()
	if not me or not (me.IsInParty() or me.IsInRaid()) then
		return {}
	end
	local team = GetClientTeam()
	local dwDistributorID = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
	local memberInfo = team.GetMemberInfo(dwDistributorID)
	memberInfo.dwID = dwDistributorID
	return memberInfo
end

function _GKP.IsDistributor()
	local me = GetClientPlayer()
	if not me or not (me.IsInParty() or me.IsInRaid()) then
		return false
	end
	local team = GetClientTeam()
	return (team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == me.dwID)
end

function _GKP.CheckIsDistributor(bOutMessage)
	if not _GKP.IsDistributor() then
		if bOutMessage then
			LR.SysMsg(_L["You must be in a team, and be distributor.\n"])
		end
		return false
	end
	return true
end

function _GKP.CheckBillExist()
	if next(LR_GKP_Base.GKP_Bill or {}) == nil then
		local msg = {
			szMessage = _L["You have no bill now. Create one or load One?"],
			szName = "create bill",
			fnAutoClose = function() return false end,
			{szOption = _L["New"], fnAction = function() LR_GKP_NewBill_Panel:Open() end, },
			{szOption = _L["Load"], fnAction = function() LR.DelayCall(500, function() PopupMenu(LR_GKP_Panel:CreateBillMenu()) end) end,},
		}
		MessageBox(msg)
		return false
	else
		return true
	end
end

------------------
--检测是否装备了某装备
function _GKP.GetSuitIndex(nLogicIndex)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local nSuitIndex = me.GetEquipIDArray(nLogicIndex)
	local dwBox
	if nLogicIndex == 0 then
		dwBox = INVENTORY_INDEX.EQUIP
	else
		dwBox = INVENTORY_INDEX[sformat("EQUIP_BACKUP%d", nLogicIndex)]
	end
	return nSuitIndex, dwBox
end

function _GKP.CheckIsEquipmentEquiped(szKey)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local EQUIPMENT_SUIT_COUNT = 4
	for i = 0, EQUIPMENT_SUIT_COUNT - 1 do
		local nSuitIndex , dwBox = _GKP.GetSuitIndex(i)
		for k = 1, #tEquipPos, 1 do
			local nType = tEquipPos[k].position
			local item = GetPlayerItem(me, dwBox, nType)
			if item then
				local key = sformat("%d_%d", item.dwTabType, item.dwIndex)
				if key == szKey then
					return true
				end
			end
		end
	end
	return false
end

--------------------
--物品数据
function _GKP.GetItemData(item)
	local data = {}
	data.dwID = item.dwID or 0
	data.dwTabType = item.dwTabType or 0
	data.dwIndex = item.dwIndex or 0
	data.nUiId = item.nUiId  or 0
	data.nBookID = item.nBookID or 0
	data.nGenre = item.nGenre or 0
	data.nQuality = item.nQuality or 0
	data.nStackNum = 1
	if item.bCanStack then
		data.nStackNum = item.nStackNum
	end
	data.szName = LR.GetItemNameByItem(item)
	local szKey = sformat("%d_%d", item.dwTabType, item.dwIndex)
	if item.nGenre == ITEM_GENRE.BOOK then
		szKey = sformat("Book_%d", item.nBookID)
	end
	data.szKey = szKey
	data.nSub = item.nSub
	data.nDetail = item.nDetail

	return data
end

function _GKP.GetItemInDoodad(dwDoodadID)
	local dwDoodadID = dwDoodadID
	local szName, tab = "", {}
	local me = GetClientPlayer()
	if not me then
		return szName, tab
	end
	----
	local doodad =  GetDoodad (dwDoodadID)
	if not doodad then
		return szName, tab
	end

	--拾取金钱
	local nMoney = doodad.GetLootMoney()
	if nMoney > 0 then
		LootMoney (doodad.dwID)
	end

	local history = {}
	szName = LR.Trim(sgsub(doodad.szName, " ", ""))
	if szName == "" then
		szName = Table_GetNpcTemplateName(doodad.dwTemplateID)
	end
	local num = doodad.GetItemListCount()
	local nLootLevel = 2
	if GetClientTeam() then
		nLootLevel = GetClientTeam().nRollQuality
	end
	for i = 0, num - 1, 1 do
		local item, bNeedRoll, bLeader, bGoldTeam = doodad.GetLootItem(i, me)
		if item then
			if bLeader then
				if item.nQuality >= nLootLevel then
					local data = _GKP.GetItemData(item)
					data.nBelongDoodadID = dwDoodadID
					data.szBelongDoodadName = szName
					data.szSourceName = szName
					data.nIndex = i

					tab[#tab + 1] = clone(data)
					local szKey = sformat("%d_%d", item.dwTabType, item.dwIndex)
					if not history[szKey] then
						history[szKey] = 0
					end
					history[szKey] = history[szKey] + 1
				end
			end
		end
	end

	if not _GKP.DoodadOriginalCount[dwDoodadID] then
		_GKP.DoodadOriginalCount[dwDoodadID] = clone(history)
	end
	_GKP.DoodadCount[dwDoodadID] = clone(history)

	return szName, tab
end

function _GKP.GetCount(dwDoodadID, item)
	local szKey = sformat("%d_%d", item.dwTabType, item.dwIndex)
	return _GKP.DoodadOriginalCount[dwDoodadID][szKey] or 0, _GKP.DoodadCount[dwDoodadID][szKey] or 0
end

function _GKP.ConvertItem2TradeData(item)
	local me = GetClientPlayer()
	local scene = me.GetScene()
	local distributorInfo = _GKP.GetDistributorInfo()
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local nTime = GetCurrentTime()
	local data = {}
	data.szKey = item.szKey or sformat("%d_%d_%d_%d", nTime, item.dwTabType or 0, item.dwIndex or 0, item.dwID or 0)
	data.hash = item.hash or tostring(GetStringCRC(data.szKey))
	data.szName = item.szName
	data.dwTabType = item.dwTabType
	data.dwIndex = item.dwIndex
	data.nBookID = item.nBookID
	data.nStackNum = item.nStackNum
	data.szArea = item.szArea or realArea
	data.szServer = item.szServer or realServer
	data.dwMapID = item.dwMapID or scene.dwMapID
	data.nCopyIndex = item.nCopyIndex or scene.nCopyIndex
	data.nGold = item.nGold or 0
	data.nSilver = item.nSilver or 0
	data.nCopper = item.nCopper or 0
	data.szDistributorName = item.szDistributorName or distributorInfo.szName
	data.dwDistributorID = item.dwDistributorID or distributorInfo.dwID
	data.dwDistributorForceID = item.dwDistributorForceID or distributorInfo.dwForceID
	data.szPurchaserName = item.szPurchaserName or ""
	data.dwPurchaserID = item.dwPurchaserID or 0
	data.dwPurchaserForceID = item.dwPurchaserForceID or ""
	data.nOperationType = item.nOperationType or 0
	data.szSourceName = item.szSourceName or ""
	data.nCreateTime = item.nCreateTime or GetCurrentTime()
	data.nSaveTime = item.nSaveTime or GetCurrentTime()
	data.szBelongBill = item.szBelongBill or LR_GKP_Base.GKP_Bill.szName
	data.nBelongDoodadID = item.nBelongDoodadID
	data.szBelongDoodadName = item.szBelongDoodadName
	data.dwID = item.dwID

	return data
end

-------------------------------------------------
-------分配相关
-------------------------------------------------
--不在线的玩家不能分配

function _GKP.GetTeamMemberList()
	local team = GetClientTeam()
	local memberList = team.GetTeamMemberList()
	local m = {}
	for k, v in pairs(memberList) do
		m[#m + 1] = team.GetMemberInfo(v)
		m[#m].bOnlineFlag = true
		m[#m].dwID = v
	end
	tsort(m, function(a, b)
		if a.dwForceID == b.dwForceID then
			return a.szName < b.szName
		else
			return a.dwForceID < b.dwForceID
		end
	end)
	return m
end

function _GKP.GetLooterList(dwDoodadID)
	local me = GetClientPlayer()
	if not me then
		return {}
	end
	if not (me.IsInParty() or me.IsInRaid() ) then
		return {}
	end
	local doodad = GetDoodad(dwDoodadID)
	if not doodad then
		return {}
	end
	local team = GetClientTeam()
	local aPartyMember = doodad.GetLooterList()
	if not aPartyMember then
		return {}
	end
	for k, v in ipairs(aPartyMember) do
		local player = team.GetMemberInfo(v.dwID)
		aPartyMember[k].dwForceID = player.dwForceID
		aPartyMember[k].dwMapID   = player.dwMapID
	end
	tsort(aPartyMember, function(a,b)
		if a.dwForceID == b.dwForceID then
			return a.szName < b.szName
		else
			return a.dwForceID < b.dwForceID
		end
	end)
	return aPartyMember
end

function _GKP.CheckPlayerCanLootItem(player, dwDoodadID)
	local dwDoodadID = dwDoodadID
	local looterList = _GKP.GetLooterList(dwDoodadID)
	for k, v in pairs(looterList) do
		if v.dwID == player.dwID then
			return v.bOnlineFlag
		end
	end
	return false
end

---检查待分配者即时状态是否符合分配的条件
function _GKP.CheckPlayerStatus(player, dwDoodadID)
	local me = GetClientPlayer()
	if not (me and (me.IsInParty() or me.IsInRaid())) then
		return false
	end
	if not player or next(player) == nil or not me.IsPlayerInMyParty(player.dwID) then
		LR.RedAlert(sformat(_L["%s is not in party.\n"], player.szName))
		LR.SysMsg(sformat(_L["%s is not in party.\n"], player.szName))
		return false
	end
	local team = GetClientTeam()
	local _player = team.GetMemberInfo(player.dwID)
	if not (_player and _player.bIsOnLine) then
		LR.RedAlert(sformat(_L["%s is not online.\n"], player.szName))
		LR.SysMsg(sformat(_L["%s is not online.\n"], player.szName))
		return false
	end
	local scene = me.GetScene()
	if not (_player.dwMapID == scene.dwMapID and _player.nMapCopyIndex == scene.nCopyIndex) then
		LR.RedAlert(sformat(_L["%s is not in the same map with you.\n"], _player.szName))
		LR.SysMsg(sformat(_L["%s is not in the same map with you.\n"], _player.szName))
		return false
	end
	if not _GKP.CheckPlayerCanLootItem(player, dwDoodadID) then
		LR.RedAlert(sformat(_L["%s has no right to pick up item.\n"], _player.szName))
		LR.SysMsg(sformat(_L["%s has no right to pick up item.\n"], _player.szName))
		return false
	end
	return true
end

function _GKP.DistributeItem(item, player)
	local me = GetClientPlayer()
	if not me or not _GKP.IsDistributor() then
		return false
	end
	local frame = LR_GKP_Distribute_Panel:Fetch("LR_GKP_Distribute_Panel")
	if frame then
		LR.SysMsg("Please close last panel.\n")
		return false
	end
	local doodad = GetDoodad(item.nBelongDoodadID)
	if not doodad then
		LR.SysMsg(_L["Error: Doodad is not exesit.\n"])
		return false
	end
	local _item = GetItem(item.dwID)
	if not _item then
		LR.SysMsg(_L["Error: Item is not exesit.\n"])
		return false
	end
	if not _GKP.CheckPlayerStatus(player, item.nBelongDoodadID) then
		return false
	end

	LR_GKP_Base.Last_Trade[sformat("%d_%d", item.dwTabType, item.dwIndex)] = clone(player)	--记住最后一次分配的人
	doodad.DistributeItem(item.dwID, player.dwID)
	return true
	--LR_GKP_Distribute_Panel:Open(item, player)
end

function _GKP.ShoutDistributeItemToRaid(item, player)
	local me = GetClientPlayer()
	local data = {}
	data[#data + 1] = {type = "name", name = me.szName}
	data[#data + 1] = {type = "text", text = _L["Jiang"]}
	if LR_GKP_Distribute_Panel.data.dwTabType == 0 then
		data[#data + 1] = {type = "text", text = sformat("[%s]", item.szName)}
	else
		if item.nGenre == ITEM_GENRE.BOOK then
			data[#data + 1] = {type = "book", tabtype = item.dwTabType, index = item.dwIndex, bookinfo = item.nBookID}
		else
			data[#data + 1] = {type = "iteminfo", tabtype = item.dwTabType, index = item.dwIndex}
		end
	end
	data[#data + 1] = {type = "text", text = sformat(_L["for %d Gold dis to"], item.nGold)}
	data[#data + 1] = {type = "name", name = player.szName}
	me.Talk(PLAYER_TALK_CHANNEL.RAID, "", data)
end

function _GKP.BatchDistributeItem(items)
	local success_distribute = {}
	for k, item in pairs(items) do
		local player = {dwID = item.dwPurchaserID, szName = item.szPurchaserName, dwForceID = dwPurchaserForceID}
		if _GKP.DistributeItem(item, player) then
			_GKP.ShoutDistributeItemToRaid(item, player)
			success_distribute[item.dwID] = true
		end
	end
	local DB = SQLite3_Open(DB_Path)
	--先记录一波
	DB:Execute("BEGIN TRANSACTION")
	for k, item in pairs(items) do
		if success_distribute[item.dwID] then
			_GKP.SaveSingleData(DB, item)
		end
	end
	DB:Execute("END TRANSACTION")
	DB:Release()
	--发布同步信息
	_GKP.GKP_BgTalk("SYNC_BEGIN", {})
	for k, item in pairs(items) do
		if success_distribute[item.dwID] then
			_GKP.GKP_BgTalk("SYNC", item)
		end
	end
	_GKP.GKP_BgTalk("SYNC_END", {})
end

function _GKP.OneKey2Self(dwDoodadID)
	if not _GKP.CheckIsDistributor(true) or not _GKP.CheckBillExist() or not dwDoodadID then
		return
	end
	local me = GetClientPlayer()
	local _, data = _GKP.GetItemInDoodad(dwDoodadID)
	local data2 = {}
	for k, item in pairs(data) do
		item.szPurchaserName = me.szName
		item.dwPurchaserForceID = me.dwForceID
		item.dwPurchaserID = me.dwID
		data2[#data2 + 1] = _GKP.ConvertItem2TradeData(item)
	end
	_GKP.BatchDistributeItem(data2)
end

--一键分材料老板
function _GKP.GetMaterialBossList(dwDoodadID, List)
	if not _GKP.CheckIsDistributor(true) or not _GKP.CheckBillExist() or not dwDoodadID or LR_GKP_Base.MaterialBoss.dwID == 0 then
		return
	end
	local Boss = LR_GKP_Base.MaterialBoss
	if not _GKP.CheckPlayerStatus(Boss, dwDoodadID) then
		return
	end
	local _, data = _GKP.GetItemInDoodad(dwDoodadID)
	for k, item in pairs(data) do
		if _GKP.IsMaterial(item) then
			item.szPurchaserName = Boss.szName
			item.dwPurchaserForceID = Boss.dwForceID
			item.dwPurchaserID = Boss.dwID
			List[#List + 1] = _GKP.ConvertItem2TradeData(item)
		end
	end
end

function _GKP.OneKey2MaterialBoss(dwDoodadID)
	local data2 = {}
	_GKP.GetMaterialBossList(dwDoodadID, data2)
	if #data2 == 0 then
		LR.SysMsg(_L["There is no eligible item.\n"])
		return
	end
	_GKP.BatchDistributeItem(data2)
end

--一键分配小铁老板
function _GKP.GetSmallIronBossList(dwDoodadID, List)
	if not _GKP.CheckIsDistributor(true) or not _GKP.CheckBillExist() or not dwDoodadID or LR_GKP_Base.SmallIronBoss.dwID == 0 then
		return
	end
	local Boss = LR_GKP_Base.SmallIronBoss
	if not _GKP.CheckPlayerStatus(Boss, dwDoodadID) then
		return
	end
	local _, data = _GKP.GetItemInDoodad(dwDoodadID)
	for k, item in pairs(data) do
		if _GKP.IsSmallIron(item) then
			item.szPurchaserName = Boss.szName
			item.dwPurchaserForceID = Boss.dwForceID
			item.dwPurchaserID = Boss.dwID
			List[#List + 1] = _GKP.ConvertItem2TradeData(item)
		end
	end
end

function _GKP.OneKey2SmallIronBoss(dwDoodadID)
	local data2 = {}
	_GKP.GetSmallIronBossList(dwDoodadID, data2)
	if #data2 == 0 then
		LR.SysMsg(_L["There is no eligible item.\n"])
		return
	end
	_GKP.BatchDistributeItem(data2)
end

--一键分配散件老板
function _GKP.GetEquipmentBossList(dwDoodadID, List)
	if not _GKP.CheckIsDistributor(true) or not _GKP.CheckBillExist() or not dwDoodadID or LR_GKP_Base.EquipmentBoss.dwID == 0 then
		return
	end
	local Boss = LR_GKP_Base.EquipmentBoss
	if not _GKP.CheckPlayerStatus(Boss, dwDoodadID) then
		return
	end
	local _, data = _GKP.GetItemInDoodad(dwDoodadID)
	local Grouped_Items = _GKP.GroupItem(data)
	local Armor = Grouped_Items["Armor"]
	for k, item in pairs(Armor) do
		item.szPurchaserName = Boss.szName
		item.dwPurchaserForceID = Boss.dwForceID
		item.dwPurchaserID = Boss.dwID
		List[#List + 1] = _GKP.ConvertItem2TradeData(item)
	end
end

function _GKP.OneKey2EquipmentBoss(dwDoodadID)
	local data2 = {}
	_GKP.GetEquipmentBossList(dwDoodadID, data2)
	if #data2 == 0 then
		LR.SysMsg(_L["There is no eligible item.\n"])
		return
	end
	_GKP.BatchDistributeItem(data2)
	--LR.SysMsg(_L["Onekey to equipment boss done!\n"])
end

--一键分门派老板
function _GKP.GetMenPaiBossList(dwDoodadID, List)
	if not _GKP.CheckIsDistributor(true) or not _GKP.CheckBillExist() or not dwDoodadID then
		return
	end
	local _, data = _GKP.GetItemInDoodad(dwDoodadID)
	local Grouped_Items = _GKP.GroupItem(data)
	local ExchangeItem = Grouped_Items["ExchangeItem"]
	local Weapon = Grouped_Items["Weapon"]

	local tBoss = LR_GKP_Base.MenPaiBoss
	for dwForceID, Boss in pairs(tBoss) do
		if Boss and next(Boss) ~= nil and Boss.dwID ~= 0 then
			local dwForceID = Boss.dwForceID
			local szForceTitle = g_tStrings.tForceTitle[dwForceID]
			--兑换牌
			for k, item in pairs(ExchangeItem) do
				local szName = LR.GetItemNameByItem(item)
				if sfind(szName, szForceTitle) then
					item.szPurchaserName = Boss.szName
					item.dwPurchaserForceID = Boss.dwForceID
					item.dwPurchaserID = Boss.dwID
					List[#List + 1] = _GKP.ConvertItem2TradeData(item)
				end
			end
			--普通武器
			for k, item in pairs(Weapon) do
				if not _GKP.IsSpecialWeapon(item) then
					local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
					if itemInfo and itemInfo.nRecommendID and g_tTable.EquipRecommend then
						local nRecommendID = itemInfo.nRecommendID
						--nRecommendID:18、22、28、29皆可出现短剑。nDetail = 2是短兵
						--如果有藏剑老板和纯阳老板，则短剑不分配，如果只有藏剑老板或者纯阳老板，则 18/22/28/29 的短兵全部分给老板
						if dwForceID == 4 or dwForceID == 8 then	--是藏剑老板或者纯阳老板
							if tBoss[4] and tBoss[8] then	--既有藏剑老板和纯阳老板，则气纯的剑肯定得分纯阳
								if dwForceID == 4 and nRecommendID == 19 then
									item.szPurchaserName = Boss.szName
									item.dwPurchaserForceID = Boss.dwForceID
									item.dwPurchaserID = Boss.dwID
									List[#List + 1] = _GKP.ConvertItem2TradeData(item)
								end
							else
								if (nRecommendID == 18 or nRecommendID == 22 or nRecommendID == 28 or nRecommendID == 29) and itemInfo.nDetail == 2 then
									item.szPurchaserName = Boss.szName
									item.dwPurchaserForceID = Boss.dwForceID
									item.dwPurchaserID = Boss.dwID
									List[#List + 1] = _GKP.ConvertItem2TradeData(item)
								end
							end
						else
							--根据描述分武器
							local t = g_tTable.EquipRecommend:Search(nRecommendID)
							if t and t.szDesc and t.szDesc ~= "" then
								if sfind(t.szDesc, szForceTitle) then
									item.szPurchaserName = Boss.szName
									item.dwPurchaserForceID = Boss.dwForceID
									item.dwPurchaserID = Boss.dwID
									List[#List + 1] = _GKP.ConvertItem2TradeData(item)
								end
							end
						end
					end
				end
			end
		end
	end
end

function _GKP.Onekey2MenPaiBoss(dwDoodadID)
	local data2 = {}
	_GKP.GetMenPaiBossList(dwDoodadID, data2)
	if #data2 == 0 then
		LR.SysMsg(_L["There is no eligible item.\n"])
		return
	end
	_GKP.BatchDistributeItem(data2)
end

----一键分所有老板
function _GKP.OneKey2AllBoss(dwDoodadID)
	local data2 = {}
	_GKP.GetMaterialBossList(dwDoodadID, data2)
	_GKP.GetSmallIronBossList(dwDoodadID, data2)
	_GKP.GetEquipmentBossList(dwDoodadID, data2)
	_GKP.GetMenPaiBossList(dwDoodadID, data2)
	if #data2 == 0 then
		LR.SysMsg(_L["There is no eligible item.\n"])
		return
	end
	_GKP.BatchDistributeItem(data2)
end

function _GKP.GetLastItemPrice(item)
	local szKey = sformat("%d_%d", item.dwTabType, item.dwIndex)
	if _GKP.Sale_Item_History[szKey] then
		return _GKP.Sale_Item_History[szKey].nGold, _GKP.Sale_Item_History[szKey]
	else
		return 0, nil
	end
end
--------------------------------------------------
---数据保存读取
--------------------------------------------------
function _GKP.LoadGKPList(szBillName)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local DB = SQLite3_Open(DB_Path)
	DB:Execute("BEGIN TRANSACTION")
	local szName = LR.StrGame2DB(szBillName)
	local DB_SELECT = DB:Prepare("SELECT * FROM bill_data WHERE szName = ? AND bDel = 0")
	DB_SELECT:ClearBindings()
	DB_SELECT:BindAll(szName)
	local result = DB_SELECT:GetAll() or {}
	if next(result) ~= nil then
		LR_GKP_Base.GKP_Bill = {
			szName = LR.StrDB2Game(result[1].szName),
			hash = result[1].hash,
			szArea = LR.StrDB2Game(result[1].szArea),
			szServer = LR.StrDB2Game(result[1].szServer),
			nCreateTime = result[1].nCreateTime,
		}
		LR_GKP_Base.GKP_TradeList = {}	--GKP的记录内容
		LR_GKP_Base.GKP_Person_Trade = {}	--个人消费总金额
		LR_GKP_Base.GKP_Person_Debt = {}		--个人欠账
		LR_GKP_Base.GKP_Person_Cash = {}		--个人交易金钱记录
		_GKP.Sale_Item_History = {}		--记录单个物品的价格
		local GKP_TradeList = LR_GKP_Base.GKP_TradeList
		local szSearchKey = _GKP.szSearchKey
		local szOrderKey = _GKP.szOrderKey
		local DB_SELECT2 = DB:Prepare(sformat("SELECT * FROM trade_data WHERE szBelongBill = ? ORDER BY %s %s", szSearchKey, szOrderKey))
		DB_SELECT2:ClearBindings()
		DB_SELECT2:BindAll(szName)
		local result2 = LR.StrDB2Game(DB_SELECT2:GetAll())
		for k, v in pairs(result2) do
			local trade_data = clone(v)
			trade_data.bDel = (v.bDel == 1)
			GKP_TradeList[#GKP_TradeList + 1] = clone(trade_data)

			if v.bDel == 0 then
				LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID] = LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID] or {nGold = 0}
				LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID].dwID = trade_data.dwPurchaserID
				LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID].szName = trade_data.szPurchaserName
				LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID].dwForceID = trade_data.dwPurchaserForceID
				LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID].nGold = LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID].nGold + trade_data.nGold

				local szKey = sformat("%d_%d", v.dwTabType, v.dwIndex)
				if _GKP.Sale_Item_History[szKey] then
					if _GKP.Sale_Item_History[szKey].nGold < v.nGold then
						_GKP.Sale_Item_History[szKey] = clone(trade_data)
					elseif _GKP.Sale_Item_History[szKey].nGold == v.nGold and v.nCreateTime > _GKP.Sale_Item_History[szKey].nCreateTime then
						_GKP.Sale_Item_History[szKey] = clone(trade_data)
					end
				else
					_GKP.Sale_Item_History[szKey] = clone(trade_data)
				end
			end
		end

		local DB_SELECT3 = DB:Prepare("SELECT * FROM cash_data WHERE szBelongBill = ? AND bDel = 0 ORDER BY nCreateTime DESC")
		DB_SELECT3:ClearBindings()
		DB_SELECT3:BindAll(szName)
		local result3 = DB_SELECT3:GetAll() or {}
		local GKP_Person_Cash = LR_GKP_Base.GKP_Person_Cash
		for k, v in pairs(result3) do
			GKP_Person_Cash[#GKP_Person_Cash + 1] = {
				szKey = LR.StrDB2Game(v.szKey),
				szName = LR.StrDB2Game(v.szName),
				dwID = v.dwID,
				dwForceID = v.dwForceID,
				my_szName = LR.StrDB2Game(v.my_szName),
				my_dwID = v.my_dwID,
				my_dwForceID = v.my_dwForceID,
				hash = v.hash,
				szArea = LR.StrDB2Game(v.szArea),
				szServer = LR.StrDB2Game(v.szServer),
				dwMapID = v.dwMapID,
				nCopyIndex = v.nCopyIndex,
				nGold = v.nGold,
				nCreateTime = v.nCreateTime,
				szBelongBill = LR.StrDB2Game(v.szBelongBill),
			}

			--先放入缓存
			LR_GKP_Base.GKP_Person_Cash_Temp[v.nCreateTime] = clone(GKP_Person_Cash[#GKP_Person_Cash])
		end

		for k, v in pairs(LR_GKP_Base.GKP_Person_Cash_Temp) do
			if not (v.szBelongBill and v.szBelongBill ~= LR_GKP_Base.GKP_Bill.szName) then
				LR_GKP_Base.GKP_Person_Debt[v.dwID] = LR_GKP_Base.GKP_Person_Debt[v.dwID] or {nGold = 0}
				LR_GKP_Base.GKP_Person_Debt[v.dwID].dwID = v.dwID
				LR_GKP_Base.GKP_Person_Debt[v.dwID].szName = v.szName
				LR_GKP_Base.GKP_Person_Debt[v.dwID].dwForceID = v.dwForceID
				if v.nGold > 0 then
					LR_GKP_Base.GKP_Person_Debt[v.dwID].nGold = LR_GKP_Base.GKP_Person_Debt[v.dwID].nGold + v.nGold
				end
			end
		end

		for k, v in pairs(LR_GKP_Base.GKP_Person_Trade) do
			LR_GKP_Base.GKP_Person_Debt[k] = LR_GKP_Base.GKP_Person_Debt[k] or {nGold = 0}
			LR_GKP_Base.GKP_Person_Debt[k].dwID = v.dwID
			LR_GKP_Base.GKP_Person_Debt[k].szName = v.szName
			LR_GKP_Base.GKP_Person_Debt[k].dwForceID = v.dwForceID
			LR_GKP_Base.GKP_Person_Debt[k].nGold = LR_GKP_Base.GKP_Person_Debt[k].nGold - v.nGold
		end
	else
		LR_GKP_Base.GKP_Bill = {}	--GKP记录的账单号信息
		LR_GKP_Base.GKP_TradeList = {}	--GKP的记录内容
		LR_GKP_Base.GKP_Person_Trade = {}	--个人消费总金额
		LR_GKP_Base.GKP_Person_Debt = {}		--个人欠账
		LR_GKP_Base.GKP_Person_Cash = {}		--个人交易金钱记录
		LR.SysMsg(_L["No such bill.\n"])
	end
	DB:Execute("END TRANSACTION")
	DB:Release()
end

--[[
data = {

}
]]
function _GKP.SaveSingleData(DB, data, bDel)
	--先保存账单信息
	local DB_SELECT = DB:Prepare("SELECT * FROM bill_data WHERE szName = ? AND bDel = 0")
	DB_SELECT:ClearBindings()
	DB_SELECT:BindAll(LR.StrGame2DB(data.szBelongBill))
	local result = DB_SELECT:GetAll() or {}
	if next(result) == nil then
		_GKP.CreateNewBill(DB, data.szBelongBill)
	else
		LR_GKP_Base.GKP_Bill = {
			szName = LR.StrDB2Game(result[1].szName),
			hash = result[1].hash,
			szArea = LR.StrDB2Game(result[1].szArea),
			szServer = LR.StrDB2Game(result[1].szServer),
			nCreateTime = result[1].nCreateTime,
		}
		LR_GKP_Panel:RefreshBillName()
	end
	--再保存交易信息
	local DB_REPLACE
	if not bDel then
		DB_REPLACE = DB:Prepare("REPLACE INTO trade_data ( szKey, hash, szName, dwTabType, dwIndex, nBookID, nStackNum, szArea, szServer, dwMapID, nCopyIndex, nGold, nSilver, nCopper, szDistributorName, dwDistributorID, dwDistributorForceID, szPurchaserName, dwPurchaserID, dwPurchaserForceID, nOperationType, szSourceName, nCreateTime, nSaveTime, szBelongBill, bDel ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0 )")
	else
		DB_REPLACE = DB:Prepare("REPLACE INTO trade_data ( szKey, hash, szName, dwTabType, dwIndex, nBookID, nStackNum, szArea, szServer, dwMapID, nCopyIndex, nGold, nSilver, nCopper, szDistributorName, dwDistributorID, dwDistributorForceID, szPurchaserName, dwPurchaserID, dwPurchaserForceID, nOperationType, szSourceName, nCreateTime, nSaveTime, szBelongBill, bDel ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1 )")
	end

	local v = clone(LR.StrGame2DB(data))
	v.nSaveTime = GetCurrentTime()

	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(v.szKey, v.hash, v.szName, v.dwTabType, v.dwIndex, v.nBookID, v.nStackNum, v.szArea, v.szServer, v.dwMapID, v.nCopyIndex, v.nGold, v.nSilver, v.nCopper, v.szDistributorName, v.dwDistributorID, v.dwDistributorForceID, v.szPurchaserName, v.dwPurchaserID, v.dwPurchaserForceID, v.nOperationType, v.szSourceName, v.nCreateTime, v.nSaveTime, v.szBelongBill)
	DB_REPLACE:Execute()

	--记录物品价格
	local szKey = sformat("%d_%d", data.dwTabType, data.dwIndex)
	if _GKP.Sale_Item_History[szKey] then
		if _GKP.Sale_Item_History[szKey].nGold < data.nGold then
			_GKP.Sale_Item_History[szKey] = clone(data)
		elseif _GKP.Sale_Item_History[szKey].nGold == data.nGold and _GKP.Sale_Item_History[szKey].nCreateTime < data.nCreateTime then
			_GKP.Sale_Item_History[szKey] = clone(data)
		end
	else
		_GKP.Sale_Item_History[szKey] = clone(data)
	end
end

function _GKP.DelSingleData(DB, data)
	_GKP.SaveSingleData(DB, data, true)
end

function _GKP.SaveCashRecord(DB, data)
	local me = GetClientPlayer()
	local scene = me.GetScene()
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local nTime = GetCurrentTime()
	local v = {}
	v.szKey = LR.StrGame2DB(sformat("%s_%s_%d_%d", realArea, realServer, data.nCreateTime, data.dwID))
	v.szName = LR.StrGame2DB(data.szName)
	v.dwID = data.dwID or 0
	v.dwForceID = data.dwForceID or 0
	v.my_szName = LR.StrGame2DB(me.szName)
	v.my_dwID = me.dwID
	v.my_dwForceID = me.dwForceID
	v.hash = tostring(GetStringCRC(v.szKey)) or ""
	v.szArea = LR.StrGame2DB(realArea)
	v.szServer = LR.StrGame2DB(realServer)
	v.dwMapID = scene.dwMapID
	v.nCopyIndex = scene.nCopyIndex
	v.nGold = data.nGold
	v.nCreateTime = data.nCreateTime
	v.szBelongBill = LR.StrGame2DB(LR_GKP_Base.GKP_Bill.szName)

	local DB_REPLACE = DB:Prepare("REPLACE INTO cash_data ( szKey, szName, dwID, dwForceID, my_szName, my_dwID, my_dwForceID, hash, szArea, szServer, dwMapID, nCopyIndex, nGold, nCreateTime, szBelongBill, bDel ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)")
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(v.szKey, v.szName, v.dwID, v.dwForceID, v.my_szName, v.my_dwID, v.my_dwForceID, v.hash, v.szArea, v.szServer, v.dwMapID, v.nCopyIndex, v.nGold, v.nCreateTime, v.szBelongBill)
	DB_REPLACE:Execute()
end

function _GKP.DelCashRecord(DB, data)
	local DB_REPLACE = DB:Prepare("REPLACE INTO cash_data (szKey, bDel) VALUES ( ?, 1)")
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(LR.StrGame2DB(data.szKey))
	DB_REPLACE:Execute()
end

function _GKP.CreateNewBill(DB, szBillName)
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local nTime = GetCurrentTime()
	LR_GKP_Base.GKP_Bill = {}
	LR_GKP_Base.GKP_TradeList = {}
	local bill_data = {
		szName = LR.StrGame2DB(szBillName),
		nCreateTime = nTime,
		hash = tostring(GetStringCRC(LR.StrGame2DB(szBillName))),
		szArea = LR.StrGame2DB(realArea),
		szServer = LR.StrGame2DB(realServer),
	}
	LR_GKP_Base.GKP_Bill = {
		szName = szBillName,
		nCreateTime = nTime,
		hash = bill_data.hash,
		szArea = realArea,
		szServer = realServer,
	}

	local DB_REPLACE = DB:Prepare("REPLACE INTO bill_data ( szName, hash, szArea, szServer, nCreateTime, bDel ) VALUES ( ?, ?, ?, ?, ?, 0 )")
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(bill_data.szName, bill_data.hash, bill_data.szArea, bill_data.szServer, bill_data.nCreateTime)
	DB_REPLACE:Execute()

	LR_GKP_Base.UsrData.lastLoadBill = szBillName
	LR_GKP_Panel:RefreshBillName()
end

function _GKP.GKP_BgTalk(nType, data)
	LR.BgTalk(PLAYER_TALK_CHANNEL.RAID, "LR_GKP", nType, data)
end

--[[
1、只有发布者是分配者才相应，队长都不行。
]]
local BG_DB = nil
function _GKP.ON_BG_CHANNEL_MSG()
	local szKey = arg0
	local nChannel = arg1
	local dwTalkerID = arg2
	local szTalkerName = arg3
	local data = arg4

	if not (szKey == "LR_GKP" or szKey == "MY_GKP") then
		return
	end

	local me = GetClientPlayer()
	if not me or not (me and (me.IsInParty() or me.IsInRaid())) then
		return
	end
	local team = GetClientTeam()
	if not team then
		return
	end
	local dwDistributorID = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
	if dwDistributorID ~= dwTalkerID then
		return
	end

	if szKey == "LR_GKP" then
		if data[1] == "SYNC_BEGIN" then
			if not BG_DB then
				BG_DB = SQLite3_Open(DB_Path)
				BG_DB:Execute("BEGIN TRANSACTION")
			end
		elseif data[1] == "SYNC" then
			if not BG_DB then
				BG_DB = SQLite3_Open(DB_Path)
				BG_DB:Execute("BEGIN TRANSACTION")
			end
			local trade_data = data[2]
			_GKP.SaveSingleData(BG_DB, trade_data)
		elseif data[1] == "SYNC_END" then
			if BG_DB then
				BG_DB:Execute("END TRANSACTION")
				BG_DB:Release()
				BG_DB = nil
				LR.DelayCall(500, function() LR_GKP_Panel:LoadGKPItemBox() end)
			end
		elseif data[1] == "DEL" then
			if not BG_DB then
				BG_DB = SQLite3_Open(DB_Path)
				BG_DB:Execute("BEGIN TRANSACTION")
			end
			local trade_data = data[2]
			_GKP.DelSingleData(DB, trade_data)
		elseif data[1] =="BEGIN_AUCTION" then
			FireEvent("LR_GKP_Loot_Sale", data[2].dwDoodadID, data[2].dwID, true)
		elseif data[1] == "CANCEL_AUCTION" then
			FireEvent("LR_GKP_Loot_Sale", data[2].dwDoodadID, data[2].dwID, false)
		end
	end

	if szKey == "MY_GKP" then
		local distributor = team.GetMemberInfo(dwDistributorID)
		local serverInfo = {GetUserServer()}
		local realArea, realServer = serverInfo[5], serverInfo[6]
		if next(LR_GKP_Base.GKP_Bill) == nil then
			if sfind(_GKP.UsrData.lastLoadBill or "", "MY_GKP") then

			else
				local szBillName = LR_GKP_NewBill_Panel:CreateMainName() .. "_MY_GKP"
				local DB = SQLite3_Open(DB_Path)
				DB:Execute("BEGIN TRANSACTION")
				_GKP.CreateNewBill(DB, szBillName)
				DB:Execute("END TRANSACTION")
				DB:Release()
			end
		end

		local trade_data = {
			szKey = sformat("%d_%d_%d_%d", data[2].nTime, data[2].dwTabType, data[2].dwIndex, GetTickCount()),
			hash = data[2].key,
			szName = data[2].szName,
			dwTabType = data[2].dwTabType,
			dwIndex = data[2].dwIndex,
			nBookID = 0,
			nStackNum = 1,
			szArea = realArea,
			szServer = realServer,
			dwMapID = distributor.dwMapID,
			nCopyIndex = distributor.nMapCopyIndex,
			nGold = data[2].nMoney,
			nSilver = 0,
			nCopper = 0,
			szDistributorName = distributor.szName,
			dwDistributorID = dwDistributorID,
			dwDistributorForceID = distributor.dwForceID,
			szPurchaserName = data[2].szPlayer,
			dwPurchaserForceID = data[2].dwForceID,
			dwPurchaserID = 0,
			nOperationType = 0,
			szSourceName = data[2].szNpcName,
			nCreateTime = data[2].nTime,
			nSaveTime = GetCurrentTime(),
			szBelongBill = _GKP.UsrData.lastLoadBill,
		}

		if data[1] == "add" or data[1] == "edit" then
			local DB = SQLite3_Open(DB_Path)
			DB:Execute("BEGIN TRANSACTION")
			_GKP.SaveSingleData(DB, trade_data)
			DB:Execute("END TRANSACTION")
			DB:Release()
			LR.DelayCall(500, function() LR_GKP_Panel:LoadGKPItemBox() end)
		elseif data[1] == "del" then
			local DB = SQLite3_Open(DB_Path)
			DB:Execute("BEGIN TRANSACTION")
			_GKP.SaveSingleData(DB, trade_data, true)
			DB:Execute("END TRANSACTION")
			DB:Release()
			LR.DelayCall(500, function() LR_GKP_Panel:LoadGKPItemBox() end)
		end
	end
end

function _GKP.GetMoneyCol(Money)
	local Money = tonumber(Money)
	if Money then
		if Money < 0 then
			return 0, 128, 255
		elseif Money < 1000 then
			return 255, 255, 255
		elseif Money < 10000 then
			return 255, 255, 164
		elseif Money < 100000 then
			return 255, 255, 0
		elseif Money < 1000000 then
			return 255, 192, 0
		elseif Money < 10000000 then
			return 255, 92, 0
		else
			return 255, 0, 0
		end
	else
		return 255, 255, 255
	end
end

LR.RegisterEvent("ON_BG_CHANNEL_MSG", function() _GKP.ON_BG_CHANNEL_MSG() end)

---------------------------------------------------------------------->
-- 金钱记录
----------------------------------------------------------------------<
_GKP.TradingTarget = {}
function _GKP.MoneyUpdate(nGold, nSilver, nCopper)
	if nGold > -20 and nGold < 20 then
		return
	end
	if not _GKP.TradingTarget then
		return
	end
	if not _GKP.TradingTarget.szName then
		return
	end
	local nTime = GetCurrentTime()
	local cash_data = {
		nGold = nGold,
		szName = _GKP.TradingTarget.szName or "System",
		dwID = _GKP.TradingTarget.dwID or 0,
		dwForceID = _GKP.TradingTarget.dwForceID,
		nTime = nTime,
		nCreateTime = nTime,
		dwMapID = GetClientPlayer().GetMapID()
	}
	LR_GKP_Base.GKP_Person_Cash_Temp[nTime] = clone(cash_data)
	if next(LR_GKP_Base.GKP_Bill) == nil then
		LR.DelayCall(500, function() LR_GKP_Panel:LoadTradeItemBox() end)
		return
	end
	DB = SQLite3_Open(DB_Path)
	DB:Execute("BEGIN TRANSACTION")
	_GKP.SaveCashRecord(DB, cash_data)
	DB:Execute("END TRANSACTION")
	DB:Release()
	if LR_GKP_Loot.DistributeCheck() then
		local text = {}
		if cash_data.nGold > 0 then
			text[#text + 1] = {type = "text", text = _L["Received"]}
		else
			text[#text + 1] = {type = "text", text = _L["Send"]}
		end
		text[#text + 1] = {type = "name", name = cash_data.szName}
		text[#text + 1] = {type = "text", text = sformat(_L["%d Gold"], mabs(cash_data.nGold))}
		GetClientPlayer().Talk(PLAYER_TALK_CHANNEL.RAID, "", text)
	end

	LR.DelayCall(500, function() LR_GKP_Panel:LoadTradeItemBox() end)
end

RegisterEvent("TRADING_OPEN_NOTIFY",function() -- 交易开始
	_GKP.TradingTarget = GetPlayer(arg0)
end)
RegisterEvent("TRADING_CLOSE",function() -- 交易结束
	_GKP.TradingTarget = {}
end)
RegisterEvent("MONEY_UPDATE",function() --金钱变动
	_GKP.MoneyUpdate(arg0, arg1, arg2)
end)

function _GKP.OutputTradeList()
	local GKP_Person_Trade = LR_GKP_Base.GKP_Person_Trade
	LR.Talk(PLAYER_TALK_CHANNEL.RAID, _L["====Consumption Statistics===="])
	local t = {}
	for k, v in pairs(GKP_Person_Trade) do
		t[#t + 1] = v
	end
	tsort(t, function(a, b) return a.nGold > b.nGold end)
	local total_money = 0
	for k, v in pairs(t) do
		if v.nGold ~= 0 then
			local data = {}
			data[#data + 1] = {type = "name", name = v.szName}
			data[#data + 1] = {type = "text", text = sformat(_L[":%d Gold"], v.nGold)}
			LR.Talk(PLAYER_TALK_CHANNEL.RAID, data)
			total_money = total_money + v.nGold
		end
	end
	LR.Talk(PLAYER_TALK_CHANNEL.RAID, sformat(_L["Total: %d Gold"], total_money))
	LR.Talk(PLAYER_TALK_CHANNEL.RAID, _L["=========END========="])
end

function _GKP.OutputDebtList()
	if not LR_GKP_Loot.DistributeCheck() then
		LR.SysMsg(_L["You must be in a team, and be distributor.\n"])
		return
	end

	local GKP_Person_Debt = LR_GKP_Base.GKP_Person_Debt
	LR.Talk(PLAYER_TALK_CHANNEL.RAID, _L["======Debt Statistics======"])
	local t = {}
	for k, v in pairs(GKP_Person_Debt) do
		t[#t + 1] = v
	end
	tsort(t, function(a, b) return a.nGold < b.nGold end)
	for k, v in pairs(t) do
		if v.nGold ~= 0 then
			local data = {}
			data[#data + 1] = {type = "name", name = v.szName}
			data[#data + 1] = {type = "text", text = sformat(_L[":%d Gold"], v.nGold)}
			LR.Talk(PLAYER_TALK_CHANNEL.RAID, data)
		end
	end

	local GKP_Person_Trade = LR_GKP_Base.GKP_Person_Trade
	local nMoney = 0
	for k, v in pairs(GKP_Person_Trade) do
		nMoney = nMoney + v.nGold
	end
	local data1 = {}
	data1[#data1 + 1] = {type = "text", text = sformat(_L["Total: %d Gold"], nMoney)}

	local nMoney2 = 0
	for k, v in pairs(LR_GKP_Base.GKP_Person_Cash_Temp) do
		if not (v.szBelongBill and v.szBelongBill ~= LR_GKP_Base.GKP_Bill.szName) then
			if v.nGold > 0 then
				nMoney2 = nMoney2 + v.nGold
			end
		end
	end
	local data2 = {}
	data2[#data2 + 1] = {type = "text", text = sformat(_L["Received money: %d Gold"], nMoney2)}

	local data3 = {}
	data3[#data3 + 1] = {type = "text", text = sformat(_L["Not received money: %d Gold"], nMoney - nMoney2)}

	LR.Talk(PLAYER_TALK_CHANNEL.RAID, "※※※※※※※※※※※")
	LR.Talk(PLAYER_TALK_CHANNEL.RAID, data3)
	LR.Talk(PLAYER_TALK_CHANNEL.RAID, data2)
	LR.Talk(PLAYER_TALK_CHANNEL.RAID, data1)
	LR.Talk(PLAYER_TALK_CHANNEL.RAID, _L["=========END========="])
end

function _GKP.SyncRecord()
	DB = SQLite3_Open(DB_Path)
	DB:Execute("BEGIN TRANSACTION")
	_GKP.GKP_BgTalk("SYNC_BEGIN", {})
	LR.SysMsg(_L["Sync begin\n"])
	for k, v in pairs(LR_GKP_Base.GKP_TradeList) do
		_GKP.GKP_BgTalk("SYNC", v)
	end
	_GKP.GKP_BgTalk("SYNC_END", {})
	LR.SysMsg(_L["Sync end\n"])
	DB:Execute("END TRANSACTION")
	DB:Release()
end

-----------------------------------------
---事件处理
-----------------------------------------
function _GKP.LOADING_END()
	local me = GetClientPlayer()
	local scene = me.GetScene()
	if scene.nType ==  MAP_TYPE.DUNGEON then
		local szDir, nType, nMaxPlayerCount, nLimitTimes, nCampType = GetMapParams(scene.dwMapID)
		if nMaxPlayerCount == 10 or nMaxPlayerCount == 25 then
			if me.IsInParty() or me.IsInRaid() then
				local team = GetClientTeam()
				if me.dwID == team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) then
					local msg = {
						szMessage = sformat(_L["[LR GKP]You entered a %d num limit dungeon and you are the distributor. \nCreate a new bill or load an exist one?"], nMaxPlayerCount),
						szName = "check bill",
						fnAutoClose = function() return false end,
						{szOption = _L["New"], fnAction = function() LR_GKP_NewBill_Panel:Open() end, },
						{szOption = _L["Load"], fnAction = function() LR.DelayCall(500, function() PopupMenu(LR_GKP_Panel:CreateBillMenu()) end) end,},
					}
					MessageBox(msg)
				end
			end
		end
	end
end

function _GKP.TEAM_AUTHORITY_CHANGED()	--团长改变、分配者改变、标记着改变
	local nAuthorityType = arg0
	local dwTeamID = arg1
	local dwOldAuthorityID = arg2
	local dwNewAuthorityID = arg3
	local me = GetClientPlayer()
	if not me then
		return
	end
	if nAuthorityType == TEAM_AUTHORITY_TYPE.DISTRIBUTE then
		if me.dwID == dwNewAuthorityID then
			local scene = me.GetScene()
			if scene.nType ==  MAP_TYPE.DUNGEON then
				local szDir, nType, nMaxPlayerCount, nLimitTimes, nCampType = GetMapParams(scene.dwMapID)
				if nMaxPlayerCount == 10 or nMaxPlayerCount == 25 then
					_GKP.CheckBillExist()
				end
			end
		end
	end
end

LR.RegisterEvent("LOADING_END", function() _GKP.LOADING_END() end)
LR.RegisterEvent("TEAM_AUTHORITY_CHANGED", function() _GKP.TEAM_AUTHORITY_CHANGED() end)

--------------------------------
local test_data = {
	{8, 21844,},
	{7, 37789,},
	{6, 16683,},
	{7, 37771,},
	{6, 16632,},
	{7, 37790,},
}

function LR_GKP_Base.Test2(n, dwDoodadID)
	local dwID = dwDoodadID
	if not dwID then
		dwID = 111
	end
	local items = {}
	local me = GetClientPlayer()
	local history = {}
	for i = 1, #test_data do
		local item = GetItemInfo(test_data[i][1], test_data[i][2])
		if item then
			local ss = {}
			ss.dwID = i
			ss.dwTabType = test_data[i][1]
			ss.dwIndex = test_data[i][2]
			ss.nStackNum = 1
			local key = {"nUiId", "nBookID", "nGenre", "nQuality", "szName", "nSub", "nDetail"}
			for k, v in pairs(key) do
				ss[v] = item[v]
			end

			local data = LR_GKP_Base.GetItemData(ss)
			items[#items + 1] = clone(data)

			local szKey = sformat("%d_%d", data.dwTabType, data.dwIndex)
			if not history[szKey] then
				history[szKey] = 0
			end
			history[szKey] = history[szKey] + 1
		end
	end

	Output(items)
	if not _GKP.DoodadOriginalCount[dwID] then
		_GKP.DoodadOriginalCount[dwID] = clone(history)
	end
	_GKP.DoodadCount[dwID] = clone(history)

	LR_GKP_Loot.Open(dwID, "测试对象", items)
end



function LR_GKP_Base.Test(n, dwDoodadID)
	local dwID = dwDoodadID
	if not dwID then
		dwID = 111
	end
	local items = {}
	local me = GetClientPlayer()
	local history = {}
	for i = 0, n - 1 do
		local item = me.GetItem(1, i)
		local data = LR_GKP_Base.GetItemData(item)
		items[#items + 1] = clone(data)

		local szKey = sformat("%d_%d", data.dwTabType, data.dwIndex)
		if not history[szKey] then
			history[szKey] = 0
		end
		history[szKey] = history[szKey] + 1
	end

	if not _GKP.DoodadOriginalCount[dwID] then
		_GKP.DoodadOriginalCount[dwID] = clone(history)
	end
	_GKP.DoodadCount[dwID] = clone(history)

	LR_GKP_Loot.Open(dwID, "测试对象", items)
end
------------------------------------
local Open_Shield_Function = {
	"GetItemInDoodad", "GetItemData", "GetDistributorInfo", "IsDistributor", "CheckIsDistributor", "CheckBillExist", "GetTeamMemberList", "GetLooterList",
	"CheckIsEquipmentEquiped", "IsSmallIron", "GroupItem", "GetCount", "GKP_BgTalk", "SaveSingleData", "DelSingleData",
	"GetLastItemPrice", "GetMoneyCol", "DistributeItem", "ShoutDistributeItemToRaid",
	"OutputTradeList", "OutputDebtList",
	"LoadGKPList", "CreateNewBill", "InsertSetBossMenu",
	"OneKey2Self", "OneKey2EquipmentBoss", "OneKey2MaterialBoss", "OneKey2SmallIronBoss", "Onekey2MenPaiBoss", "OneKey2AllBoss",
}
for k, v in pairs(Open_Shield_Function) do
	LR_GKP_Base[v] = _GKP[v]
end

