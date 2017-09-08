local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin\\@DATA\\LR_AccountStatistics\\UsrData"
local _L = LR.LoadLangPack(AddonPath)
local DB_name = "maindb.db"
local sformat, slen, sgsub, ssub, sfind = string.format, string.len, string.gsub, string.sub, string.find
local mfloor, mceil, mmin, mmax = math.floor, math.ceil, math.min, math.max
local tconcat, tinsert, tremove, tsort = table.concat, table.insert, table.remove, table.sort
--[[
itemInfo.nGenre & item.nGenre
ITEM_GENRE.DESIGNATION	称号道具
ITEM_GENRE.TASK_ITEM	任务物品
ITEM_GENRE.EQUIPMENT	装备
ITEM_GENRE.POTION	药品
ITEM_GENRE.TASK_ITEM	任务物品
ITEM_GENRE.MATERIAL	材料
ITEM_GENRE.BOOK	书籍
ITEM_GENRE.DESIGNATION	称号道具
ITEM_GENRE.BOX	宝箱
ITEM_GENRE.BOX_KEY	宝箱钥匙
ITEM_TABLE_TYPE.OTHER	其他



itemInfo.nSub & item.nSub	装备类型 当 itemInfo.nGenre == ITEM_GENRE.EQUIPMENT 时
武器
EQUIPMENT_SUB.MELEE_WEAPON	近战武器
EQUIPMENT_SUB.RANGE_WEAPON	远程武器（暗器）
EQUIPMENT_SUB.ARROW	远程武器弹药
饰品
EQUIPMENT_SUB.AMULET
EQUIPMENT_SUB.RING
EQUIPMENT_SUB.PENDANT
包裹
EQUIPMENT_SUB.PACKAGE
--
EQUIPMENT_SUB.BULLET
--



ITEM_BIND.BIND_ON_TIME_LIMITATION	非限时绑定
ITEM_BIND.BIND_ON_EQUIPPED	装备后绑定
ITEM_BIND.BIND_ON_PICKED	拾取后绑定


itemInfo.nExistType  道具存在类型
ITEM_EXIST_TYPE.OFFLINE	下线限时道具
ITEM_EXIST_TYPE.ONLINE	上线限时道具
ITEM_EXIST_TYPE.ONLINEANDOFFLINE  &	ITEM_EXIST_TYPE.TIMESTAMP 		限时道具

]]


--------------------------------------------------------------------
--记录背包物品
-------------------------------------------------------------------
LR_AccountStatistics_Bag = LR_AccountStatistics_Bag or {}
LR_AccountStatistics_Bag.src = "%s\\UsrData\\%s\\%s\\%s\\Bag_%s.dat"
LR_AccountStatistics_Bag.UsrData = {
	On = true,
}
LR_AccountStatistics_Bag.ItemInBag =  {}
LR_AccountStatistics_Bag.UsrTable = {}
LR_AccountStatistics_Bag.bHooked = false
LR_AccountStatistics_Bag.bHookMailPanel = false
LR_AccountStatistics_Bag.Default = {
	Version = "20170119",
}
local CustomVersion = "20170111"
RegisterCustomData("LR_AccountStatistics_Bag.bHookMailPanel", CustomVersion)

function LR_AccountStatistics_Bag.HookBag()
	local frame = Station.Lookup("Normal/BigBagPanel")
	if frame then --背包界面添加一个按钮
		local LR_Btn_Bag = frame:Lookup("LR_Btn_Bag")
		if not LR_Btn_Bag then
			local LR_Btn_Bag = LR.AppendUI("UIButton", frame, "LR_Btn_Bag" , {x = 100 , y = 0 , w = 36 , h = 36, ani = {"ui\\Image\\button\\SystemButton_1.UITex", 35, 36, 37}, })
			LR_Btn_Bag:SetAlpha(200)
			LR_Btn_Bag.OnClick = function()
				LR_AccountStatistics_Bag_Panel:Open()
			end
			LR_Btn_Bag.OnEnter = function()
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				local szTip = {}
				szTip[#szTip+1] = GetFormatText(sformat("%s\n", _L["LR_Item_Statistics"]), 163)
				szTip[#szTip+1] = GetFormatText(_L["Click here to open [LR_Item_Statistics] panel."], 162)
				local text = tconcat(szTip)
				OutputTip(text, 400, {x, y, w, h})
			end
			LR_Btn_Bag.OnLeave = function()
				HideTip()
			end
		end
	end
end

local _BTN_Mail = nil
function LR_AccountStatistics_Bag.HookMailPanel()
	local frame = Station.Lookup("Normal/MailPanel")
	if frame then --背包界面添加一个按钮
		local BTN_Mail = frame:Lookup("LR_BTN_Mail")
		if not BTN_Mail then
			if LR_AccountStatistics_Bag.bHookMailPanel then
				local BTN_Mail = LR.AppendUI("Button", frame, "LR_BTN_Mail", {w = 90, h = 28, x = 200, y = 8})
				BTN_Mail:SetText(_L["LR Mail"])
				BTN_Mail.OnClick = function()
					LR_AccountStatistics_Bag_Panel:Open(nil, nil, nil, nil ,true)
				end
				BTN_Mail:Enable(false)
				_BTN_Mail = BTN_Mail
				LR.DelayCall(3000, function()
					frame = Station.Lookup("Normal/MailPanel")
					if frame then
						local BTN_Mail = frame:Lookup("LR_BTN_Mail")
						if BTN_Mail then
							_BTN_Mail:Enable(true)
						end
					end
				end)
			end
		else
			if not LR_AccountStatistics_Bag.bHookMailPanel then
				BTN_Mail:Destroy()
				_BTN_Mail = nil
			end
		end
	end
end

function LR_AccountStatistics_Bag.GetItemData(itm)
	local t = {}
	local t_item = {}
	t_item.dwTabType = itm.dwTabType
	t_item.dwIndex = itm.dwIndex
	t_item.nUiId = itm.nUiId
	t_item.nBookID = itm.nBookID
	t_item.nGenre = itm.nGenre
	t_item.nQuality = itm.nQuality
	t_item.nStackNum = 1
	if itm.bCanStack then
		t_item.nStackNum = itm.nStackNum
	end
	if itm.bBind then
		t_item.bBind = 1
	else
		t_item.bBind = 0
	end
	t_item.szName = LR.GetItemNameByItem(itm)
	local szKey = sformat("%d_%d", itm.dwTabType, itm.dwIndex)
	if itm.nGenre == ITEM_GENRE.BOOK then
		szKey = sformat("Book_%d", itm.nBookID)
	end
	if itm.bBind then
		szKey = sformat("%s_bBind", szKey)
	end
	t_item.szKey = szKey
	t_item.nSub = itm.nSub
	t_item.nDetail = itm.nDetail
	return t_item
end

function LR_AccountStatistics_Bag.GetItemByGrid ()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local ItemInBag = {}
	for i = 1, 6, 1 do
		for j = 0, me.GetBoxSize(i)-1, 1 do
			local itm = me.GetItem(i, j)
			if itm then
				local t_item = LR_AccountStatistics_Bag.GetItemData(itm)
				local szKey = t_item.szKey
				if ItemInBag[szKey] then
					ItemInBag[szKey].nStackNum = ItemInBag[szKey].nStackNum + t_item.nStackNum
				else
					ItemInBag[szKey] = t_item
				end
			end
		end
	end
	LR_AccountStatistics_Bag.ItemInBag = clone(ItemInBag)
end

function LR_AccountStatistics_Bag.SaveData(DB)
	LR_AccountStatistics_Bag.GetItemByGrid()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local belong = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	--先清数据
	local DB_SELECT = DB:Prepare("SELECT szKey FROM bag_item_data WHERE nStackNum > 0 AND bDel = 0 AND belong = ? AND szKey IS NOT NULL AND belong IS NOT NULL")
	DB_SELECT:ClearBindings()
	DB_SELECT:BindAll(belong)
	local result = DB_SELECT:GetAll() or {}
	if result and next(result) ~= nil then
		local DB_REPLACE = DB:Prepare("REPLACE INTO bag_item_data (szKey, belong, bDel) VALUES ( ?, ?, 1)")
		for k, v in pairs (result) do
			DB_REPLACE:ClearBindings()
			DB_REPLACE:BindAll(v.szKey, belong)
			DB_REPLACE:Execute()
		end
	end
	--添加数据
	if not LR_AccountStatistics.UsrData.OthersCanSee then
		return
	end
	local DB_REPLACE2 = DB:Prepare("REPLACE INTO bag_item_data (szKey, belong, szName, dwTabType, dwIndex, nUiId, nBookID, nGenre, nSub, nDetail, nQuality, nStackNum, bBind, bDel) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0 )")
	for szKey, v in pairs (LR_AccountStatistics_Bag.ItemInBag) do
		DB_REPLACE2:ClearBindings()
		DB_REPLACE2:BindAll(szKey, belong, v.szName, v.dwTabType, v.dwIndex, v.nUiId, v.nBookID, v.nGenre, v.nSub, v.nDetail, v.nQuality, v.nStackNum, v.bBind)
		DB_REPLACE2:Execute()
	end
end
------------------------------------------------------------------------------------------------------
---------记录仓库物品
------------------------------------------------------------------------------------------------------
LR_AccountStatistics_Bank = LR_AccountStatistics_Bank or {}
LR_AccountStatistics_Bank.src = "%s\\UsrData\\%s\\%s\\%s\\Bank_%s.dat"
LR_AccountStatistics_Bank.UsrData = {
	On = true,
}
LR_AccountStatistics_Bank.ItemInBank =  {}
LR_AccountStatistics_Bank.UsrTable = {}
LR_AccountStatistics_Bank.Default = {
	Version = "20170119",
}


function LR_AccountStatistics_Bank.GetItemByGrid ()
	LR_AccountStatistics_Bank.ItemInBank =  {}
	local me = GetClientPlayer()
	if not me then return end
	local ItemInBank = {}
	for i = 7, 12, 1 do
		for j = 0, me.GetBoxSize(i)-1, 1 do
			local itm = me.GetItem(i, j)
			if itm then
				local t_item = LR_AccountStatistics_Bag.GetItemData(itm)
				local szKey = t_item.szKey
				if ItemInBank[szKey] then
					ItemInBank[szKey].nStackNum = ItemInBank[szKey].nStackNum + t_item.nStackNum
				else
					ItemInBank[szKey] = t_item
				end
			end
		end
	end
	LR_AccountStatistics_Bank.ItemInBank = clone(ItemInBank)
end

function LR_AccountStatistics_Bank.SaveData(DB)
	LR_AccountStatistics_Bank.GetItemByGrid()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local belong = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	--先清数据
	local DB_SELECT = DB:Prepare("SELECT szKey FROM bank_item_data WHERE nStackNum > 0 AND bDel = 0 AND belong = ? AND szKey IS NOT NULL AND belong IS NOT NULL")
	DB_SELECT:ClearBindings()
	DB_SELECT:BindAll(belong)
	local result = DB_SELECT:GetAll() or {}
	if result and next(result) ~= nil then
		local DB_REPLACE = DB:Prepare("REPLACE INTO bank_item_data (szKey, belong, bDel) VALUES ( ?, ?, 1)")
		for k, v in pairs (result) do
			DB_REPLACE:ClearBindings()
			DB_REPLACE:BindAll(v.szKey, belong)
			DB_REPLACE:Execute()
		end
	end
	--添加数据
	if not LR_AccountStatistics.UsrData.OthersCanSee then
		return
	end
	local DB_REPLACE2 = DB:Prepare("REPLACE INTO bank_item_data (szKey, belong, szName, dwTabType, dwIndex, nUiId, nBookID, nGenre, nSub, nDetail, nQuality, nStackNum, bBind, bDel) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0 )")
	for szKey, v in pairs (LR_AccountStatistics_Bank.ItemInBank) do
		DB_REPLACE2:ClearBindings()
		DB_REPLACE2:BindAll(szKey, belong, v.szName, v.dwTabType, v.dwIndex, v.nUiId, v.nBookID, v.nGenre, v.nSub, v.nDetail, v.nQuality, v.nStackNum, v.bBind)
		DB_REPLACE2:Execute()
	end
end

------------------------------------------------------------------------------------------------------
----记录邮件附件
------------------------------------------------------------------------------------------------------
LR_AccountStatistics_Mail = LR_AccountStatistics_Mail or {}
LR_AccountStatistics_Mail.src = "%s\\UsrData\\%s\\%s\\%s\\Mail_%s.dat"
LR_AccountStatistics_Mail.Default = {
	On = true,
	atMaturity = true, 		----到期提醒
	atMaturityDay = 7, 		----到期提醒时间
	remind = true, 			----去收件提醒
	remindDay = 10, 		----收件时间提醒
	Version = "20170111",
}
LR_AccountStatistics_Mail.UsrData = clone(LR_AccountStatistics_Mail.Default)

local CustomVersion = "20170711"
RegisterCustomData("LR_AccountStatistics_Mail.UsrData", CustomVersion)

LR_AccountStatistics_Mail.ItemInMail = {}
LR_AccountStatistics_Mail.MailData = {}	--存放Mail信息（mail_id, belong, left_time, from, szTitle, szContent, bDel）
LR_AccountStatistics_Mail.UsrTable = {}
LR_AccountStatistics_Mail.Times = 0

------------------
---数据结构
------------------
--[[
ItemInMail = {
	item,
	MailDetail = {{num, nLeftTime, belong_mailID},
					   {num, nLeftTime, belong_mailID},
	}
}
]]
-----收件
LR_AccountStatistics_Mail.info = {}		----存储邮件，单独收件用
LR_AccountStatistics_Mail_Loot = {
	nLastLootTime = 0,		---上次收取的时间
	aLootQueue = {},			---待收件的列队
	tLootQueue = {},
}

local stopFun = function()
	LR_AccountStatistics_Mail_Loot.aLootQueue = {}
	LR_AccountStatistics_Mail_Loot.tLootQueue = {}
	LR.UnBreatheCall("LootingBreathe")
	----保存
	LR.DelayCall(150, function()
		LR_AccountStatistics_Mail.info = {}
		LR_AccountStatistics_Mail.ItemInMail = {}
		LR_AccountStatistics_Mail.MailData = {}
		LR_AccountStatistics_Mail.GetItemByMail()
		local path = sformat("%s\\%s", SaveDataPath, DB_name)
		local DB = SQLite3_Open(path)
		DB:Execute("BEGIN TRANSACTION")
		LR_AccountStatistics_Mail.SaveData(DB)
		DB:Execute("END TRANSACTION")
		DB:Release()
		local realArea = LR_AccountStatistics_Bag_Panel.realArea
		local realServer = LR_AccountStatistics_Bag_Panel.realServer
		local dwID = LR_AccountStatistics_Bag_Panel.dwID
		LR_AccountStatistics_Bag_Panel:ReloadItemBox(realArea, realServer, dwID)
	end)
end

local function LootingBreathe()
	local npc = GetNpc(LR_AccountStatistics_Mail_None.XinShiID)
	if not npc or LR.GetDistance(npc) > 5 then
		stopFun()
	end
	if GetTime() - LR_AccountStatistics_Mail_Loot.nLastLootTime <=  GetPingValue()*1.2 then -- 取附件得间隔一定时间，否则无法全部取出，需要加上延迟
		return
	elseif #LR_AccountStatistics_Mail_Loot.aLootQueue > 0 -- 确定收件队列不为空
	and #LR.GetPlayerBagFreeBoxList() > 0
	then
		local tLoot = LR_AccountStatistics_Mail_Loot.aLootQueue[1]
		local mail = GetMailClient().GetMailInfo(tLoot.nMailID)
		if mail then
			if tLoot.nIndex < 8 then
				mail.TakeItem(LR_AccountStatistics_Mail_None.XinShiID, tLoot.nIndex)
			else
				mail.TakeMoney(LR_AccountStatistics_Mail_None.XinShiID)
			end
			if not mail.bReadFlag then
				mail.Read()
			end
			-- 移除收取队列
			tremove(LR_AccountStatistics_Mail_Loot.aLootQueue, 1)
			LR_AccountStatistics_Mail_Loot.nLastLootTime = GetTime()
			LR_AccountStatistics_Mail_Loot.tLootQueue[sformat("%d_%d", tLoot.nMailID, tLoot.nIndex)] = nil
		end
	else -- 不符合条件时中断并清空收件队列
		stopFun()
	end
end

-- 取附件
-- LR_AccountStatistics_Mail_Loot.LootMailItem(107, 1)
-- LR_AccountStatistics_Mail_Loot.LootMailItem(107, "all")
-- LR_AccountStatistics_Mail_Loot.LootMailItem(107, "money")
function LR_AccountStatistics_Mail_Loot.LootMailItem(nMailID, nIndex)
	local MailClient = GetMailClient()
	local mail = MailClient.GetMailInfo(nMailID)
	if not mail then
		return
	end

	-- 物品加入收取队列
	if mail.bItemFlag then
		if nIndex ==  "all" then
			for i = 0, 7, 1 do
				local item = mail.GetItem(i)
				if item then
					local szKey = sformat("%d_%d", nMailID, i) -- 防止重复收取
					if not LR_AccountStatistics_Mail_Loot.tLootQueue[szKey] then
						LR_AccountStatistics_Mail_Loot.tLootQueue[szKey] = true
						tinsert(LR_AccountStatistics_Mail_Loot.aLootQueue, {nMailID = nMailID, nIndex = i})
					end
				end
			end
		elseif type(nIndex) ==  "number" then
			local item = mail.GetItem(nIndex)
			if item then
				local szKey = sformat("%d_%d", nMailID, nIndex)  -- 防止重复收取
				if not LR_AccountStatistics_Mail_Loot.tLootQueue[szKey] then
					LR_AccountStatistics_Mail_Loot.tLootQueue[szKey] = true
					tinsert(LR_AccountStatistics_Mail_Loot.aLootQueue, {nMailID = nMailID, nIndex = nIndex})
				end
			end
		end
	end
	-- 金钱加入收取队列
	if (nIndex ==  "money" or nIndex ==  "all")
	and not LR_AccountStatistics_Mail_Loot.tLootQueue[sformat("%d_8", nMailID)] then
		if mail.bMoneyFlag then
			LR_AccountStatistics_Mail_Loot.tLootQueue[sformat("%d_8", nMailID)] = true
			tinsert(LR_AccountStatistics_Mail_Loot.aLootQueue, {nMailID = nMailID, nIndex = 8})
		end
	end
	LR.BreatheCall("LootingBreathe", LootingBreathe)
end

----------
function LR_AccountStatistics_Mail.GetItemByMail ()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local Mail = GetMailClient()
	LR_AccountStatistics_Mail.info = {}
	local ItemInMail = {}
	local tMailList = Mail.GetMailList("all")
	for k, nMailID in pairs (tMailList) do
		local MailInfo =  Mail.GetMailInfo(nMailID)
		if MailInfo then
			MailInfo.RequestContent(LR_AccountStatistics_Mail_None.XinShiID)		----请求获取邮件信息
			local szSenderName = LR.Trim(MailInfo.szSenderName)
			local szTitle = LR.Trim(MailInfo.szTitle)
			local szContent = MailInfo.GetText()
			local nType = MailInfo.GetType()
			local nLeftTime = MailInfo.GetLeftTime()
			local nEndTime = GetCurrentTime() + nLeftTime
			---收取邮件单独添加
			LR_AccountStatistics_Mail.info[nMailID] = LR_AccountStatistics_Mail.info[nMailID] or {}
			LR_AccountStatistics_Mail.info[nMailID].szSenderName = szSenderName
			LR_AccountStatistics_Mail.info[nMailID].szTitle = szTitle
			LR_AccountStatistics_Mail.info[nMailID].nEndTime = nEndTime
			LR_AccountStatistics_Mail.info[nMailID].location = {}
			----
			local item_record = {}	---用于记录单个邮件中附件物品的总和
			----金钱记录
			if MailInfo.bMoneyFlag then
				local nMoney = MailInfo.nMoney
				if nMoney>0 then
					local t_item = {}
					local szKey = "Money_0_0"
					t_item.nUiId = 0
					t_item.bBind = true
					t_item.nStackNum = nMoney
					t_item.nQuality = 5
					t_item.szName = _L["Money"]
					t_item.nGenre = ITEM_GENRE.BOX
					t_item.dwTabType = 0
					t_item.dwIndex = 0
					t_item.nBookID = 0
					t_item.szKey = szKey
					-----
					if ItemInMail[szKey] then
						ItemInMail[szKey].nStackNum = ItemInMail[szKey].nStackNum + t_item.nStackNum
					else
						ItemInMail[szKey] = t_item
					end
					if item_record[szKey] then
						item_record[szKey] = item_record[szKey] + t_item.nStackNum
					else
						item_record[szKey] = t_item.nStackNum	--用于记录单个邮件中附件个数
					end
					ItemInMail[szKey].nBelongMailID = ItemInMail[szKey].nBelongMailID or {}
					ItemInMail[szKey].nBelongMailID[tostring(nMailID)] = true
					----收件用
					LR_AccountStatistics_Mail.info[nMailID].location[8] = t_item
				end
			end
			---物品记录
			if MailInfo.bItemFlag then
				---收取邮件单独添加
				LR_AccountStatistics_Mail.info[nMailID] = LR_AccountStatistics_Mail.info[nMailID] or {}
				LR_AccountStatistics_Mail.info[nMailID].szSenderName = szSenderName
				LR_AccountStatistics_Mail.info[nMailID].szTitle = szTitle
				LR_AccountStatistics_Mail.info[nMailID].nEndTime = nEndTime
				----
				for nIndex = 0, 7, 1 do
					local itm = MailInfo.GetItem(nIndex)
					if itm then
						local t_item = LR_AccountStatistics_Bag.GetItemData(itm)
						local szKey = t_item.szKey
						if ItemInMail[szKey] then
							ItemInMail[szKey].nStackNum = ItemInMail[szKey].nStackNum + t_item.nStackNum
						else
							ItemInMail[szKey] = t_item
						end
						if item_record[szKey] then
							item_record[szKey] = item_record[szKey] + t_item.nStackNum
						else
							item_record[szKey] = t_item.nStackNum	--用于记录单个邮件中附件个数
						end
						ItemInMail[szKey].nBelongMailID = ItemInMail[szKey].nBelongMailID or {}
						ItemInMail[szKey].nBelongMailID[tostring(nMailID)] = true
						----收件用
						LR_AccountStatistics_Mail.info[nMailID].location[nIndex] = t_item
					end
				end
			end
			if MailInfo.bMoneyFlag or MailInfo.bItemFlag then
				LR_AccountStatistics_Mail.MailData[nMailID] = LR_AccountStatistics_Mail.MailData[nMailID] or {}
				LR_AccountStatistics_Mail.MailData[nMailID].szSenderName = szSenderName
				LR_AccountStatistics_Mail.MailData[nMailID].szTitle = szTitle
				LR_AccountStatistics_Mail.MailData[nMailID].nEndTime = nEndTime
				LR_AccountStatistics_Mail.MailData[nMailID].szContent = szContent
				LR_AccountStatistics_Mail.MailData[nMailID].nType = nType
				LR_AccountStatistics_Mail.MailData[nMailID].item_record = item_record
			end
		end
	end
	LR_AccountStatistics_Mail.ItemInMail = clone(ItemInMail)
end

function LR_AccountStatistics_Mail.SaveData(DB)
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local belong = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	--先清数据
	--清mail_item_data表
	local DB_SELECT = DB:Prepare("SELECT szKey FROM mail_item_data WHERE nStackNum > 0 AND bDel = 0 AND belong = ? AND szKey IS NOT NULL AND belong IS NOT NULL")
	DB_SELECT:ClearBindings()
	DB_SELECT:BindAll(belong)
	local result = DB_SELECT:GetAll() or {}
	if result and next(result) ~= nil then
		local DB_REPLACE = DB:Prepare("REPLACE INTO mail_item_data (szKey, belong, bDel) VALUES ( ?, ?, 1)")
		for k, v in pairs (result) do
			DB_REPLACE:ClearBindings()
			DB_REPLACE:BindAll(v.szKey, belong)
			DB_REPLACE:Execute()
		end
	end
	--清mail_data表
	local DB_SELECT2 = DB:Prepare("SELECT nMailID FROM mail_data WHERE bDel = 0 AND belong = ? AND nMailID IS NOT NULL AND belong IS NOT NULL")
	DB_SELECT2:ClearBindings()
	DB_SELECT2:BindAll(belong)
	local result = DB_SELECT2:GetAll() or {}
	if result and next(result) ~= nil then
		local DB_REPLACE = DB:Prepare("REPLACE INTO mail_data (nMailID, belong, bDel) VALUES ( ?, ?, 1)")
		for k, v in pairs (result) do
			DB_REPLACE:ClearBindings()
			DB_REPLACE:BindAll(v.nMailID, belong)
			DB_REPLACE:Execute()
		end
	end
	--添加数据
	--添加物品
	local DB_REPLACE3 = DB:Prepare("REPLACE INTO mail_receive_time ( szKey, nTime, bDel ) VALUES ( ?, ?, 0 )")
	DB_REPLACE3:ClearBindings()
	DB_REPLACE3:BindAll(belong, GetCurrentTime())
	DB_REPLACE3:Execute()

	if not LR_AccountStatistics.UsrData.OthersCanSee then
		--return
	end
	local DB_REPLACE = DB:Prepare("REPLACE INTO mail_item_data (bDel, szKey, belong, szName, dwTabType, dwIndex, nUiId, nBookID, nGenre, nSub, nDetail, nQuality, nStackNum, bBind, nBelongMailID) VALUES ( 0, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )")
	--Output(LR_AccountStatistics_Mail.ItemInMail)
	for szKey, v in pairs (LR_AccountStatistics_Mail.ItemInMail) do
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey, belong, v.szName, v.dwTabType, v.dwIndex, v.nUiId, v.nBookID, v.nGenre, v.nSub, v.nDetail, v.nQuality, v.nStackNum, v.bBind, LR.JsonEncode(v.nBelongMailID))
		DB_REPLACE:Execute()
	end
	--添加邮件
	local DB_REPLACE2 = DB:Prepare("REPLACE INTO mail_data ( nMailID, belong, szSenderName, szTitle, szContent, nType, nEndTime, item_record, bDel ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, 0 )")
	for nMailID, v in pairs (LR_AccountStatistics_Mail.MailData) do
		DB_REPLACE2:ClearBindings()
		DB_REPLACE2:BindAll(nMailID, belong, v.szSenderName, v.szTitle, v.szContent, v.nType, v.nEndTime, LR.JsonEncode(v.item_record))
		DB_REPLACE2:Execute()
	end
end

--------------------------------------------------------------------------------------------------
LR_AccountStatistics_Mail_None = {}
LR_AccountStatistics_Mail_None.LastTime = 0
LR_AccountStatistics_Mail_None.Times = 0
LR_AccountStatistics_Mail_None.Times2 = 0
LR_AccountStatistics_Mail_None.XinShiID = 0
LR_AccountStatistics_Mail_None.MailPanel = 0

function LR_AccountStatistics_Mail_None.OnFrameCreate()
	LR_AccountStatistics_Mail_None.LastTime =  GetLogicFrameCount()
end

function LR_AccountStatistics_Mail_None.OnEvent(szEvent)

end

function LR_AccountStatistics_Mail_None.OnFrameBreathe()
	if GetLogicFrameCount() % 4 ~=  0 then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	if GetLogicFrameCount() - LR_AccountStatistics_Mail_None.LastTime > 16 and LR_AccountStatistics_Mail_None.Times <=  3 then
		LR_AccountStatistics_Mail.GetItemByMail()
		local me = GetClientPlayer()
		local ServerInfo = {GetUserServer()}
		local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
		local szName = me.szName
		local path = sformat(LR_AccountStatistics_Mail.src, SaveDataPath, realArea, realServer, szName, szName)
		if LR_AccountStatistics_Mail_None.Times ==  3 then
			local path = sformat("%s\\%s", SaveDataPath, DB_name)
			local DB = SQLite3_Open(path)
			DB:Execute("BEGIN TRANSACTION")
			LR_AccountStatistics_Mail.SaveData(DB)
			DB:Execute("END TRANSACTION")
			DB:Release()
			LR.SysMsg(_L["LR_Statistics has saved mail data.\n"])
			PlaySound(SOUND.UI_SOUND, g_sound.Gift)
		end
		LR_AccountStatistics_Mail_None.Times = LR_AccountStatistics_Mail_None.Times + 1
	end
	local frame = Station.Lookup("Normal/MailPanel")
	if frame then
		LR_AccountStatistics_Mail_None.MailPanel = 1
		LR_AccountStatistics_Mail_None.Times2 = 0
	else
		if LR_AccountStatistics_Mail_None.MailPanel ==  1 and LR_AccountStatistics_Mail_None.Times2 <=  3 then
			LR_AccountStatistics_Mail.GetItemByMail()
			local me = GetClientPlayer()
			local ServerInfo = {GetUserServer()}
			local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
			local szName = me.szName
			local path = sformat(LR_AccountStatistics_Mail.src, SaveDataPath, realArea, realServer, szName, szName)
			if LR_AccountStatistics_Mail_None.Times2 ==  3 then
				local path = sformat("%s\\%s", SaveDataPath, DB_name)
				local DB = SQLite3_Open(path)
				DB:Execute("BEGIN TRANSACTION")
				LR_AccountStatistics_Mail.SaveData(DB)
				DB:Execute("END TRANSACTION")
				DB:Release()
				PlaySound(SOUND.UI_SOUND, g_sound.Gift)
				LR_AccountStatistics_Mail_None.MailPanel = 0
			end
			LR_AccountStatistics_Mail_None.Times2 = LR_AccountStatistics_Mail_None.Times2 + 1
		end
	end
end

function LR_AccountStatistics_Mail_None.Open_Window()
	local dwIndex = arg0
	local text = LR.Trim(arg1)
	local dwTargetType = arg2
	local dwTargetID = arg3

	local _start, _end = sfind(text, _L["feige"])
	if _start and _end then
		LR_AccountStatistics_Mail_None.Times = 0
		LR_AccountStatistics_Mail_None.LastTime =  GetLogicFrameCount()
		LR_AccountStatistics_Mail_None.XinShiID =  dwTargetID
		Wnd.OpenWindow("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics_Mail_None.ini", "LR_AccountStatistics_Mail_None")
	else
		Wnd.CloseWindow("LR_AccountStatistics_Mail_None")
	end
end

LR.RegisterEvent("OPEN_WINDOW", function() LR_AccountStatistics_Mail_None.Open_Window() end)

-----------------------------------------------------------
-----帮会仓库
-----------------------------------------------------------
LR_GuildBank = {}
LR_GuildBank.Data = {}
local SORT_KEY = {
	ITEM_GENRE.EQUIPMENT,
	ITEM_GENRE.POTION,
	ITEM_GENRE.MATERIAL,
	ITEM_GENRE.BOOK,
	ITEM_GENRE.COLOR_DIAMOND,
	ITEM_GENRE.DIAMOND,
}

function LR_GuildBank.Sort(t)
	local tt = clone(t)
	tsort(tt, function(a, b)
		if a.nGenre == b.nGenre then
			if a.nGenre == ITEM_GENRE.BOOK then
				if a.nQuality == b.nQuality then
					if a.nBookID == b.nBookID then
						return a.dwX < b.dwX
					else
						return a.nBookID < b.nBookID
					end
				else
					return a.nQuality > b.nQuality
				end
			else
				if a.nSub == b.nSub then
					if a.nDetail == b.nDetail then
						if a.nQuality == b.nQuality then
							if a.nUiId == b.nUiId then
								if a.nStackNum == b.nStackNum then
									return a.dwX < b.dwX
								else
									return a.nStackNum > b.nStackNum
								end
							else
								return a.nUiId < b.nUiId
							end
						else
							return a.nQuality > b.nQuality
						end
					else
						return a.nDetail < b.nDetail
					end
				else
					return a.nSub < b.nSub
				end
			end
		else
			return a.nGenre < b.nGenre
		end
	end)
	return tt
end

function LR_GuildBank.LogicSortGuildBank()
	local Data = clone(LR_GuildBank.Data or {})
	local data_all = LR_GuildBank.Sort(Data)
	return data_all
end

function LR_GuildBank.PhysicSortGuildBank()
	local me = GetClientPlayer()
	LR_GuildBank.Data = clone(LR_GuildBank.GetGuildBankData())
	LR_GuildBank.Data = clone(LR_GuildBank.LogicSortGuildBank())

	local t, x = {}, {}
	for k, v in pairs(LR_GuildBank.Data) do
		if not x[v.szName] then
			t[#t+1] = v.szName
			x[v.szName] = true
		end
	end
	--Output(tconcat(t, ","))
	if not LR_GuildBank.ExchangeItem() then
		LR.DelayCall(125, function() LR_GuildBank.PhysicSortGuildBank() end)
	else
		local frame = Station.Lookup("Normal/GuildBankPanel")
		if frame then
			--LR_GuildBank.Btn:Enable(true)
		end
		LR.SysMsg(_L["Sort over.\n"])
	end
end

function LR_GuildBank.GetGuildData(dwBox, dwX)
	local data = {}
	local me = GetClientPlayer()
	local item = GetPlayerItem(me, dwBox, dwX)
	if item then
		data.szKey = sformat("%d_%d", item.dwTabType, item.dwIndex)
		data.nUiId = item.nUiId
		data.dwTabType = item.dwTabType
		data.dwIndex = item.dwIndex
		data.nStackNum = 1
		data.bCanStack = item.bCanStack
		if item.bCanStack then
			data.nStackNum = item.nStackNum
		end
		data.nMaxStackNum = item.nMaxStackNum
		data.nGenre = item.nGenre
		data.nBookID = 0
		if item.nGenre == ITEM_GENRE.BOOK then
			data.nBookID = item.nBookID
		end
		data.nSub = item.nSub
		data.nDetail = item.nDetail
		data.nQuality = item.nQuality
		data.szName = item.szName
		data.dwX = dwX
	end

	return data
end

function LR_GuildBank.GetGuildBankData()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local frame = Station.Lookup("Normal/GuildBankPanel")
	if not frame then
		return
	end
	local data = {}
	local dwBox = INVENTORY_GUILD_BANK
	local dwPageSize = INVENTORY_GUILD_PAGE_SIZE
	local nPage = frame.nPage
	LR_GuildBank.nPage = nPage
	local nStart = nPage * dwPageSize
	for dwX = nStart, nStart + dwPageSize - 1, 1 do
		local data2 = LR_GuildBank.GetGuildData(dwBox, dwX)
		if next(data2) ~= nil then
			data[#data + 1] = clone(data2)
		end
	end
	return data
end

function LR_GuildBank.ModifyData(data, k, dwX)
	local data2 = clone(data)
	for k, v in pairs(data2) do
		if v.dwX == k then
			data2[k].dwX = dwX
		end
	end
	return data2
end

function LR_GuildBank.ExchangeItem()
	local data2 = LR_GuildBank.Data
	local frame = Station.Lookup("Normal/GuildBankPanel")
	if not frame then
		return true
	end
	local nPage = frame.nPage
	local me = GetClientPlayer()
	if not me then
		return true
	end
	local dwBox = INVENTORY_GUILD_BANK
	local dwPageSize = INVENTORY_GUILD_PAGE_SIZE
	for k = 1, #data2 , 1 do
		local item = LR_GuildBank.GetGuildData(dwBox, dwPageSize * nPage + k - 1)
		local TargetItem = data2[k]
		local move_flag = true
		if item then
			if item.nGenre == ITEM_GENRE.BOOK then
				if TargetItem.nGenre == ITEM_GENRE.BOOK and TargetItem.nBookID == item.nBookID then
					move_flag = false
				end
			else
				if TargetItem.dwTabType == item.dwTabType and TargetItem.dwIndex == item.dwIndex and TargetItem.nStackNum == item.nStackNum then
					move_flag = false
				end
			end
		end
		if move_flag then
			--Output(TargetItem.dwX, "to", dwPageSize * nPage + k - 1, TargetItem.szName, item.szName)
			if OnExchangeItem(dwBox, TargetItem.dwX, dwBox, dwPageSize * nPage + k - 1) then
				return false
			else
				LR.SysMsg(_L["Move error.\n"])
				return true
			end
		end
	end
	return true
end

function LR_GuildBank.HookGuildBank()
	local frame = Station.Lookup("Normal/GuildBankPanel")
	if frame then --背包界面添加一个按钮
		local Btn_Refresh = frame:Lookup("Btn_Refresh")
		if Btn_Refresh then
			Btn_Refresh.OnRButtonUp = function()
				LR_GuildBank.PhysicSortGuildBank()
			end
		end
	end
end

function LR_GuildBank.ON_FRAME_CREATE()
	local frame = arg0
	local szName = frame:GetName()
	if szName == "GuildBankPanel" then
		LR.DelayCall(150, function() LR_GuildBank.HookGuildBank() end)
	end
end

LR.RegisterEvent("ON_FRAME_CREATE", function() LR_GuildBank.ON_FRAME_CREATE() end)
------------------------------------------------------------------------------------------------------
----界面
------------------------------------------------------------------------------------------------------
LR_AccountStatistics_Bag_Panel = CreateAddon("LR_AccountStatistics_Bag_Panel")
LR_AccountStatistics_Bag_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_AccountStatistics_Bag_Panel.UserData = {
	Anchor = {s = "CENTER", r = "CENTER", x = 0, y = 0},
}
LR_AccountStatistics_Bag_Panel.realArea = ""
LR_AccountStatistics_Bag_Panel.realServer = ""
LR_AccountStatistics_Bag_Panel.nPlayerName = ""
LR_AccountStatistics_Bag_Panel.dwID = 0
LR_AccountStatistics_Bag_Panel.ItemInBag = {}
LR_AccountStatistics_Bag_Panel.ItemInBank = {}
LR_AccountStatistics_Bag_Panel.ItemInMail = {}
LR_AccountStatistics_Bag_Panel.ItemInAll = {}
LR_AccountStatistics_Bag_Panel.MailData = {}
LR_AccountStatistics_Bag_Panel.AllUsrItemInBag = {}
LR_AccountStatistics_Bag_Panel.AllUsrItemInBank = {}
LR_AccountStatistics_Bag_Panel.AllUsrItemInMail = {}
LR_AccountStatistics_Bag_Panel.ItemBelong = {}
LR_AccountStatistics_Bag_Panel.bShowExpireMail = false	--只显示到期邮件

LR_AccountStatistics_Bag_Panel.Default = {
	{display = _L["TASK_ITEM"], f_arg1 = "nGenre", f_arg2 = ITEM_GENRE.TASK_ITEM, checked = true, },
	{display = _L["EQUIPMENT"], f_arg1 = "nGenre", f_arg2 = ITEM_GENRE.EQUIPMENT, checked = true, },
	{display = _L["POTION"], f_arg1 = "nGenre", f_arg2 = ITEM_GENRE.POTION, checked = true, },
	{display = _L["MATERIAL"], f_arg1 = "nGenre", f_arg2 = ITEM_GENRE.MATERIAL, checked = true, },
	{display = _L["BOOK"], f_arg1 = "nGenre", f_arg2 = ITEM_GENRE.BOOK, checked = true, },
	{display = _L["COLOR_DIAMOND"], f_arg1 = "nGenre", f_arg2 = ITEM_GENRE.COLOR_DIAMOND, checked = true, },
	{display = _L["DIAMOND"], f_arg1 = "nGenre", f_arg2 = ITEM_GENRE.DIAMOND, checked = true, },
	{display = _L["OTHER"], f_arg1 = "", f_arg2 = "", checked = true, },
	Version = "20170111",
}
LR_AccountStatistics_Bag_Panel.FilterCondition = clone(LR_AccountStatistics_Bag_Panel.Default)
LR_AccountStatistics_Bag_Panel.searchText = ""

local CustomVersion2 = "20170111"		--上面已经定义了一个CustomVersion
--RegisterCustomData("LR_AccountStatistics_Bag_Panel.UserData", CustomVersion2)
RegisterCustomData("LR_AccountStatistics_Bag_Panel.FilterCondition", CustomVersion2)

LR_AccountStatistics_Bag_Panel:BindEvent("OnFrameDragEnd", "OnDragEnd")
LR_AccountStatistics_Bag_Panel:BindEvent("OnFrameDestroy", "OnDestroy")
LR_AccountStatistics_Bag_Panel:BindEvent("OnFrameKeyDown", "OnKeyDown")

LR_AccountStatistics_Bag_Panel.CalBag = true
LR_AccountStatistics_Bag_Panel.CalBank = true
LR_AccountStatistics_Bag_Panel.CalMail = true
LR_AccountStatistics_Bag_Panel.oldUsrDataLIst = {}

function LR_AccountStatistics_Bag_Panel.LoadUserAllData()
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	---清空
	LR_AccountStatistics_Bag_Panel.ItemInBag = {}
	LR_AccountStatistics_Bag_Panel.ItemInBank = {}
	LR_AccountStatistics_Bag_Panel.ItemInMail = {}
	LR_AccountStatistics_Bag_Panel.ItemBelong = {}
	LR_AccountStatistics_Bag_Panel.MailData = {}
	--读取
	LR_AccountStatistics_Bag_Panel.LoadUserBagData(DB)
	LR_AccountStatistics_Bag_Panel.LoadUserBankData(DB)
	LR_AccountStatistics_Bag_Panel.LoadUserMailData(DB)
	DB:Execute("END TRANSACTION")
	DB:Release()
end

function LR_AccountStatistics_Bag_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("CUSTOM_DATA_LOADED")
	LR_AccountStatistics_Bag_Panel.UpdateAnchor(this)
	-------打开面板时保存数据
	if LR_AccountStatistics.UsrData.AutoSave and LR_AccountStatistics.UsrData.OpenSave then
		LR_AccountStatistics.AutoSave()
	end
	LR_AccountStatistics_Bag_Panel.ItemInBag = {}
	LR_AccountStatistics_Bag_Panel.ItemInBank = {}
	LR_AccountStatistics_Bag_Panel.ItemInMail = {}
	LR_AccountStatistics_Bag_Panel.ItemInAll = {}
	LR_AccountStatistics_Bag_Panel.MailData = {}
	LR_AccountStatistics_Bag_Panel.ItemBelong = {}
	LR_AccountStatistics_Bag_Panel.searchText = ""
	LR_AccountStatistics_Bag_Panel.LoadUserAllData()

	RegisterGlobalEsc("LR_AccountStatistics_Bag_Panel", function () return true end , function() LR_AccountStatistics_Bag_Panel:Open() end)
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	-----------邮件提醒
	LR_AccountStatistics_Mail_Check.CheckAllMail()
end

function LR_AccountStatistics_Bag_Panel:OnEvents(event)
	if event ==  "CUSTOM_DATA_LOADED" then
		if arg0 ==  "Role" then
			LR_AccountStatistics_Bag_Panel.UpdateAnchor(this)
		end
	elseif event ==  "UI_SCALED" then
		LR_AccountStatistics_Bag_Panel.UpdateAnchor(this)
	end
end

function LR_AccountStatistics_Bag_Panel.UpdateAnchor(frame)
	frame:SetPoint(LR_AccountStatistics_Bag_Panel.UserData.Anchor.s, 0, 0, LR_AccountStatistics_Bag_Panel.UserData.Anchor.r, LR_AccountStatistics_Bag_Panel.UserData.Anchor.x, LR_AccountStatistics_Bag_Panel.UserData.Anchor.y)
	frame:CorrectPos()
end

function LR_AccountStatistics_Bag_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_AccountStatistics_Bag_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_AccountStatistics_Bag_Panel:OnDragEnd()
	this:CorrectPos()
	LR_AccountStatistics_Bag_Panel.UserData.Anchor = GetFrameAnchor(this)
end

function LR_AccountStatistics_Bag_Panel:Init()
	local frame = self:Append("Frame", "LR_AccountStatistics_Bag_Panel", {title = _L["Item Statistics"], style = "NORMAL"})

	--------------角色选择
	local hComboBox = self:Append("ComboBox", frame, "ComboBox_name", {w = 140, x = 20, y = 51, text = GetClientPlayer().szName})
	hComboBox:Enable(true)

	local imgTab = self:Append("Image", frame, "TabImg", {w = 770, h = 33, x = 0, y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)

	local hPageSet = self:Append("PageSet", frame, "PageSet", {x = 0, y = 80, w = 768, h = 434})

	-------------初始界面物品
	local hWinIconView = self:Append("Window", hPageSet, "WindowItemView", {x = 0, y = 0, w = 758, h = 400})
	LR_AccountStatistics_Bag_Panel.LoadUserAllData()
	self:LoadItemBox(hWinIconView)

	local t_table = LR_AccountStatistics_Bag.UsrTable or {}
	hComboBox.OnClick = function (m)
		local TempTable_Cal, TempTable_NotCal = LR_AccountStatistics.SeparateUsrList()
		tsort(TempTable_Cal, function(a, b)
			if a.nLevel == b.nLevel then
				return a.dwForceID < b.dwForceID
			else
				return a.nLevel > b.nLevel
			end
		end)

		local all_option = {szOption = _L["(ALL CHARACTERS)"],
			fnAction = function()
				LR_AccountStatistics_Bag_Panel:ReloadItemBox("ALL", "ALL", -1)
				hComboBox:SetText(_L["(ALL CHARACTERS)"])
			end,}
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
						fnAction =  function ()
							local realArea = TempTable[i * 20 + k].realArea
							local realServer = TempTable[i * 20 + k].realServer
							local szName = TempTable[i * 20 + k].szName
							local dwID = TempTable[i * 20 + k].dwID
							LR_AccountStatistics_Bag_Panel:ReloadItemBox(realArea, realServer, dwID)
						end,
						szIcon =  szIcon,
						nFrame =  nFrame,
						szLayer =  "ICON_RIGHT",
						rgb =  {r, g, b},
					}
				end
			end
		end
		for i = 0, page_num - 1, 1 do
			page[i][#page[i] + 1] = {bDevide = true}
			if i ~= page_num - 1 then
				page[i][#page[i] + 1] = page[i+1]
				page[i][#page[i]].szOption = _L["Next 20 Records"]
			end
			page[i][#page[i] + 1] = all_option
		end

		m = page[0]

		local __x, __y = hComboBox:GetAbsPos()
		local __w, __h = hComboBox:GetSize()
		m.nMiniWidth = __w
		m.x = __x
		m.y = __y + __h
		PopupMenu(m)
	end

	----------搜索
	local hTextSearch = self:Append("Text", frame, "TextSearch", {w = 20, h = 26, x = 185, y = 51, text = _L["Search"], })
	local hEditBox = self:Append("Edit", frame, "searchText", {w = 100 , h = 26, x = 220, y = 51, text = ""})
	hEditBox:Enable(true)
	hEditBox.OnChange = function (value)
		LR_AccountStatistics_Bag_Panel.searchText = value

		--LR_AccountStatistics_Bag_Panel.LoadUserAllData()
		local cc = self:Fetch("WindowItemView")
		if cc then
			self:ClearHandle(cc)
		end
		--local hWinIconView = self:Append("Window", hPageSet, "WindowItemView", {x = 0, y = 30, w = 758, h = 400})
		--self:LoadItemBox(hWinIconView)
		self:LoadItemBox(cc)
	end

	local hComboBoxLocation = self:Append("ComboBox", frame, "ComboBox_Location", {w = 140, x = 340, y = 51, text  = _L["Choose position"]})
	hComboBoxLocation:Enable(true)

	hComboBoxLocation.OnClick = function (m)
		local szOption = {_L["Bag"], _L["Bank"], _L["Mail"]}
		local keys = {"CalBag", "CalBank", "CalMail"}
		for k, v in pairs(szOption) do
			m[#m+1] = {szOption = v, bCheck = true, bMCheck = false, bChecked = function() return LR_AccountStatistics_Bag_Panel[keys[k]] end,
			fnAction = function()
				LR_AccountStatistics_Bag_Panel[keys[k]] = not LR_AccountStatistics_Bag_Panel[keys[k]]
				local realArea = LR_AccountStatistics_Bag_Panel.realArea
				local realServer =LR_AccountStatistics_Bag_Panel.realServer
				local dwID = LR_AccountStatistics_Bag_Panel.dwID
				LR_AccountStatistics_Bag_Panel:ReloadItemBox(realArea, realServer, dwID)
			end, }
		end
		PopupMenu(m)
	end

	local hComboBoxFilter = self:Append("ComboBox", frame, "ComboBox_Filter", {w = 140, x = 500, y = 51, text  = _L["Choose type"]})
	hComboBoxFilter:Enable(true)

	hComboBoxFilter.OnClick = function (m)
		local t_table = LR_AccountStatistics_Bag_Panel.FilterCondition or {}
		for i = 1, #LR_AccountStatistics_Bag_Panel.FilterCondition, 1 do
			local temp_menu =  {
				szOption = LR_AccountStatistics_Bag_Panel.FilterCondition[i].display, bCheck = true, bChecked =  LR_AccountStatistics_Bag_Panel.FilterCondition[i].checked , fnAction = function ()
					LR_AccountStatistics_Bag_Panel.FilterCondition[i].checked = not LR_AccountStatistics_Bag_Panel.FilterCondition[i].checked

					local cc = self:Fetch("WindowItemView")
					if cc then
						self:ClearHandle(cc)
					end
					--local hWinIconView = self:Append("Window", hPageSet, "WindowItemView", {x = 0, y = 30, w = 758, h = 400})
					self:LoadItemBox(cc)
				end
			}
			tinsert (m, temp_menu)
		end
		PopupMenu(m)
	end

	local hTipBox = self:Append("Button", frame, "Tips", {w  = 60, x = 675, y = 52, text = "Tips"})
	hTipBox:Enable(true)
	hTipBox.OnEnter = function ()
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml  = GetFormatText(_L["1.Because of White list, you can only get attachment information after interactiving messenger.\n"], 136, 255, 128, 0)
		--szXml = szXml..GetFormatText("2.当阅读等级未到时，会显示未阅读而不能抄写\n", 136, 255, 128, 0)
		OutputTip(szXml, 350, {x, y, w, h})
	end
	hTipBox.OnLeave = function ()
		HideTip()
	end


	local hButtonRefresh = self:Append("Button", frame, "hButtonRefresh", {w  = 100, x = 30, y = 460, text = _L["Refresh"]})
	hButtonRefresh:Enable(true)
	hButtonRefresh.OnClick = function ()
		local frame = Station.Lookup("NORMAL/MailPanel")
		if frame then
			LR_AccountStatistics_Mail.info = {}
			LR_AccountStatistics_Mail.ItemInMail = {}
			LR_AccountStatistics_Mail.MailData = {}
			LR_AccountStatistics_Mail.GetItemByMail()
			local path = sformat("%s\\%s", SaveDataPath, DB_name)
			local DB = SQLite3_Open(path)
			DB:Execute("BEGIN TRANSACTION")
			LR_AccountStatistics_Mail.SaveData(DB)
			DB:Execute("END TRANSACTION")
			DB:Release()
		end

		local realArea = LR_AccountStatistics_Bag_Panel.realArea
		local realServer = LR_AccountStatistics_Bag_Panel.realServer
		local dwID = LR_AccountStatistics_Bag_Panel.dwID
		self:ReloadItemBox(realArea, realServer, dwID)
	end

	local hCheckBox = self:Append("CheckBox", frame, "enter_box", {w = 200, x = 150, y = 460 , text = _L["Only show mail which will expire"] })
	hCheckBox:Check(LR_AccountStatistics_Bag_Panel.bShowExpireMail)
	hCheckBox:Enable(true)
	hCheckBox.OnCheck = function(arg0)
		LR_AccountStatistics_Bag_Panel.bShowExpireMail = arg0
		local realArea = LR_AccountStatistics_Bag_Panel.realArea
		local realServer = LR_AccountStatistics_Bag_Panel.realServer
		local dwID = LR_AccountStatistics_Bag_Panel.dwID
		self:ReloadItemBox(realArea, realServer, dwID)
	end

	----------关于
	LR.AppendAbout(LR_AccountStatistics_Bag_Panel, frame)
end

function LR_AccountStatistics_Bag_Panel:Open(realArea, realServer, dwID, bShowExpireMail, bOnlyShowMail)
	if realArea then
		LR_AccountStatistics_Bag_Panel.realArea = realArea
		LR_AccountStatistics_Bag_Panel.realServer = realServer
		LR_AccountStatistics_Bag_Panel.dwID = dwID
		LR_AccountStatistics_Bag_Panel.bShowExpireMail = bShowExpireMail or false
	else
		local ServerInfo = {GetUserServer()}
		local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
		local me = GetClientPlayer()
		LR_AccountStatistics_Bag_Panel.realArea = realArea
		LR_AccountStatistics_Bag_Panel.realServer = realServer
		LR_AccountStatistics_Bag_Panel.dwID = me.dwID
		LR_AccountStatistics_Bag_Panel.bShowExpireMail = false
	end
	if bOnlyShowMail then
		LR_AccountStatistics_Bag_Panel.CalBag = false
		LR_AccountStatistics_Bag_Panel.CalBank = false
		LR_AccountStatistics_Bag_Panel.CalMail = true
	end
	local frame = self:Fetch("LR_AccountStatistics_Bag_Panel")
	if frame then
		self:Destroy(frame)
	else
		frame = self:Init()
	end
end

function LR_AccountStatistics_Bag_Panel:ReloadItemBox(realArea, realServer, dwID)
	LR_AccountStatistics_Bag_Panel.realArea = realArea
	LR_AccountStatistics_Bag_Panel.realServer = realServer
	LR_AccountStatistics_Bag_Panel.dwID = dwID
	LR_AccountStatistics_Bag_Panel.LoadUserAllData()
	local cc = self:Fetch("WindowItemView")
	if cc then
		self:ClearHandle(cc)
	end
	self:LoadItemBox(cc)
end
--[[
LR_AccountStatistics_Bag_Panel.ItemBelong = {
	[item_szkey] = {
		[belong] = {belongUsr_realServer, belongUsr, Mail_num, bag_num, Bank_num,
			MailDetail = {


			},
		},
		....
	}
	...
}
]]
function LR_AccountStatistics_Bag_Panel:OutputIconTip(item)
	local nMouseX, nMouseY = Cursor.GetPos()
	local r , g, b = GetItemFontColorByQuality (item.nQuality, false)
	local szTipInfo = {}
	if item.nUiId ==  0 then
		szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s  ", _L["Money"]) , 17, r, g, b) .. LR.FormatMoneyString(item.nStackNum) .. GetFormatText("\n", 17)
	else
		local szTip, itemInfo = GetItemInfoTip(1, item.dwTabType, item.dwIndex, nil, nil, item.nBookID)
		szTipInfo[#szTipInfo+1]  = szTip
	end
	szTipInfo[#szTipInfo+1] = GetFormatImage("ui\\image\\ChannelsPanel\\NewChannels.uitex", 166, 420, 27)
	szTipInfo[#szTipInfo+1] = GetFormatText("\n", 224)
	if LR_AccountStatistics_Bag_Panel.dwID ==  -1 then
		if item.nUiId ==  0 then
			szTipInfo[#szTipInfo+1] = GetFormatText(_L["Item belongs:(Mail)\n"], 16)
			local ItemBelong = LR_AccountStatistics_Bag_Panel.ItemBelong[item.szKey] or {}
			for szKey , v in pairs (ItemBelong) do
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("（%s_%s）%14s：   ", LR_AccountStatistics.AllUsrList[v.belongUsr].realArea, LR_AccountStatistics.AllUsrList[v.belongUsr].realServer, LR_AccountStatistics.AllUsrList[v.belongUsr].szName), 224)
				local mail_num =  (v.mail_num or 0)
				local string_money = LR.FormatMoneyString(mail_num)
				szTipInfo[#szTipInfo+1] = string_money .. GetFormatText("\n", 224)
			end
		else
			szTipInfo[#szTipInfo+1] = GetFormatText(_L["Item belongs:(Bag/Bank/Mail)\n"], 16)
			local ItemBelong = LR_AccountStatistics_Bag_Panel.ItemBelong[item.szKey] or {}
			for szKey , v in pairs (ItemBelong) do
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("（%s_%s）%14s：", LR_AccountStatistics.AllUsrList[v.belongUsr].realArea, LR_AccountStatistics.AllUsrList[v.belongUsr].realServer, LR_AccountStatistics.AllUsrList[v.belongUsr].szName), 224)
				local bag_num = (v.bag_num or 0)
				local bank_num =  (v.bank_num or 0)
				local mail_num =  (v.mail_num or 0)
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("\t%5d / %5d / %5d\n", bag_num, bank_num, mail_num), 224)
			end
		end
	else
		if item.nUiId ==  0 then
			szTipInfo[#szTipInfo+1] = GetFormatText(_L["Item belongs:(Mail)\n"], 16)
			local ItemBelong = LR_AccountStatistics_Bag_Panel.ItemBelong[item.szKey] or {}
			for szKey , v in pairs (ItemBelong) do
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("（%s_%s）%14s：   ", LR_AccountStatistics.AllUsrList[v.belongUsr].realArea, LR_AccountStatistics.AllUsrList[v.belongUsr].realServer, LR_AccountStatistics.AllUsrList[v.belongUsr].szName), 224)
				local mail_num =  (v.mail_num or 0)
				local string_money = LR.FormatMoneyString(mail_num)
				szTipInfo[#szTipInfo+1] = string_money .. GetFormatText("\n", 224)
			end
		else
			szTipInfo[#szTipInfo+1] = GetFormatText(_L["Item belongs:(Bag/Bank/Mail)\n"], 16)
			local ItemBelong = LR_AccountStatistics_Bag_Panel.ItemBelong[item.szKey] or {}
			for szKey , v in pairs (ItemBelong) do
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("（%s_%s）%14s：", LR_AccountStatistics.AllUsrList[v.belongUsr].realArea, LR_AccountStatistics.AllUsrList[v.belongUsr].realServer, LR_AccountStatistics.AllUsrList[v.belongUsr].szName), 224)
				local bag_num = (v.bag_num or 0)
				local bank_num =  (v.bank_num or 0)
				local mail_num =  (v.mail_num or 0)
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("\t%5d / %5d / %5d\n", bag_num, bank_num, mail_num), 224)
			end
		end
	end
	szTipInfo[#szTipInfo+1] = GetFormatImage("ui\\image\\ChannelsPanel\\NewChannels.uitex", 166, 420, 27)

	--if true then
	if (not LR_AccountStatistics_Bag_Panel.CalBag) and (not LR_AccountStatistics_Bag_Panel.CalBank) and LR_AccountStatistics_Bag_Panel.CalMail or LR_AccountStatistics_Bag_Panel.bShowExpireMail then
	--if (not LR_AccountStatistics_Bag_Panel.CalBag) and (not LR_AccountStatistics_Bag_Panel.CalBank) and LR_AccountStatistics_Bag_Panel.CalMail and LR_AccountStatistics_Bag_Panel.dwID ~=  -1
		--or (item.nUiId == 0 and LR_AccountStatistics_Bag_Panel.dwID ~= -1 )
	--then
		szTipInfo[#szTipInfo+1] = GetFormatText(_L["[from]->[to] (left time) (mail id)\t[number]\n"], 16)
		if LR_AccountStatistics_Bag_Panel.ItemInMail[item.szKey] and next(LR_AccountStatistics_Bag_Panel.ItemInMail[item.szKey].nBelongMailID or {}) ~= nil then
			local ItemBelong = LR_AccountStatistics_Bag_Panel.ItemBelong[item.szKey] or {}
			local MailData = LR_AccountStatistics_Bag_Panel.MailData or {}
			local nBelongMailID = {}
			for belong, v in pairs (ItemBelong) do
				for nMailID, v2 in pairs(v.nBelongMailID) do
					nBelongMailID[#nBelongMailID+1] = {nMailID = tonumber(nMailID), belong = belong, nEndTime = MailData[belong][tonumber(nMailID)].nEndTime}
				end
			end
			tsort(nBelongMailID,function(a, b)
				return a.nEndTime < b.nEndTime
			end)

			for k, v in pairs(nBelongMailID) do
				local nMailID = v.nMailID
				local szSenderName = MailData[v.belong][tonumber(nMailID)].szSenderName
				local nStackNum = MailData[v.belong][tonumber(nMailID)].item_record[item.szKey]
				local szTitle =  MailData[v.belong][tonumber(nMailID)].szTitle
				local nLeftTime = MailData[v.belong][tonumber(nMailID)].nEndTime - GetCurrentTime()
				local nLeftTime2 = nLeftTime
				local szTimeLeft = ""
				local tTimeLeft = {}
				local szLeftDay, szLeftHour, szLeftMinute, szLeftSecond = "", "", "", ""
				if nLeftTime >=  86400 then
					szLeftDay = FormatString(g_tStrings.STR_MAIL_LEFT_DAY, mfloor(nLeftTime / 86400))
					nLeftTime = nLeftTime % 86400
				end
				if nLeftTime >=  3600 then
					szLeftHour = FormatString(g_tStrings.STR_MAIL_LEFT_HOURE, mfloor(nLeftTime / 3600))
					nLeftTime = nLeftTime % 3600
				end
				if  nLeftTime >=  60 then
					szLeftMinute = FormatString(g_tStrings.STR_MAIL_LEFT_MINUTE, mfloor(nLeftTime / 60))
					nLeftTime = nLeftTime % 60
				end
				szLeftSecond = FormatString(g_tStrings.STR_MAIL_LEFT_SECOND, nLeftTime)
				if nLeftTime2 > 86400 then
					szTimeLeft = szLeftDay .. szLeftHour
				elseif nLeftTime2 > 3600 then
					szTimeLeft = szLeftHour .. szLeftMinute
				elseif nLeftTime2 > 0 then
					szTimeLeft = szLeftMinute .. szLeftSecond
				end
				if item.szKey == "Money_0_0" then
					if nLeftTime2 >= 0 then
						szTimeLeft = sformat(" %s->%s  %14s (%d)   ", szSenderName, LR_AccountStatistics.AllUsrList[v.belong].szName,  szTimeLeft, tonumber(nMailID))
					else
						szTimeLeft = sformat(_L[" %s->%s  overdue (%d)   "], szSenderName, LR_AccountStatistics.AllUsrList[v.belong].szName,  tonumber(nMailID))
					end
					if MailData[v.belong][tonumber(nMailID)].nEndTime - GetCurrentTime() < 60 * 60 * 24 * 7 then
						szTipInfo[#szTipInfo+1] = sformat("%s%s%s", GetFormatText(sformat("%s",  szTimeLeft), 101), LR.FormatMoneyString(nStackNum), GetFormatText(sformat("\n",  szTimeLeft), 101))
					else
						szTipInfo[#szTipInfo+1] = sformat("%s%s%s", GetFormatText(sformat("%s", szTimeLeft), 106), LR.FormatMoneyString(nStackNum), GetFormatText(sformat("\n",  szTimeLeft), 106))
					end
				else
					if nLeftTime2 >= 0 then
						szTimeLeft = sformat(" %s->%s  %s (%d) \t%d\n", szSenderName, LR_AccountStatistics.AllUsrList[v.belong].szName,  szTimeLeft, tonumber(nMailID), nStackNum)
					else
						szTimeLeft = sformat(_L[" %s->%s  overdue (%d) \t%d\n"], szSenderName, LR_AccountStatistics.AllUsrList[v.belong].szName,  tonumber(nMailID), nStackNum)
					end
					if MailData[v.belong][tonumber(nMailID)].nEndTime - GetCurrentTime() < 60 * 60 * 24 * 7 then
						szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s",  szTimeLeft), 101)
					else
						szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s", szTimeLeft), 106)
					end
				end
			end
		end
	end

	if IsCtrlKeyDown() then
		szTipInfo[#szTipInfo+1] = GetFormatText(sformat("\n\n%s:\n", _L["Debug"]), 102)
		szTipInfo[#szTipInfo+1] = GetFormatText(sformat("nUiId: %d\n", item.nUiId), 102)
		szTipInfo[#szTipInfo+1] = GetFormatText(sformat("dwTabType: %d\n", item.dwTabType), 102)
		szTipInfo[#szTipInfo+1] = GetFormatText(sformat("dwIndex: %d\n", item.dwIndex), 102)
		--szTipInfo = szTipInfo .. GetFormatText("\n\n调试信息:\n", 102)
		--szTipInfo = szTipInfo .. GetFormatText("nUiId: "..item.nUiId.."\n", 102)
		--szTipInfo = szTipInfo .. GetFormatText("nGenre: "..item.nGenre.."\n", 102)
		--szTipInfo = szTipInfo .. GetFormatText("nQuality: "..item.nQuality.."\n", 102)
		--szTipInfo = szTipInfo .. GetFormatText("nSub: "..item.nSub.."\n", 102)
		--szTipInfo = szTipInfo .. GetFormatText("nDetail: "..item.nDetail.."\n", 102)
	end

	if false and item.nGenre ==   ITEM_GENRE.EQUIPMENT then  --or  item.nGenre ==   ITEM_GENRE.COLOR_DIAMOND then
		if  IsAltKeyDown() then
			local szText = tconcat(szTipInfo)
			OutputTip(szText, 420, {nMouseX, nMouseY, 0, 0})
		else
			OutputItemTip(UI_OBJECT_ITEM_INFO, GLOBAL.CURRENT_ITEM_VERSION, item.dwTabType, item.dwIndex, {nMouseX, nMouseY, 0, 0})
		end
--[[		if  IsAltKeyDown() then
			OutputItemTip(UI_OBJECT_ITEM_INFO, GLOBAL.CURRENT_ITEM_VERSION, item.dwTabType, item.dwIndex, {nMouseX, nMouseY, 0, 0})
			--OutputItemTip(UI_OBJECT_ITEM_ONLY_ID, item.dwID, nil, nil, {nMouseX, nMouseY, 0, 0}, nil, "loot")
		else
			OutputTip(szTipInfo, 360, {nMouseX, nMouseY, 0, 0})
		end]]
	else
		local szText = tconcat(szTipInfo)
		OutputTip(szText, 420, {nMouseX, nMouseY, 0, 0})
	end
end

function LR_AccountStatistics_Bag_Panel:LoadOneItem2(parent, item_data)
	local box = LR.ItemBox:new(item_data)
	box:Create(parent, nil)

	local MouseEnter = function()
		self:OutputIconTip(item_data)
		box:Hover(true)
	end
	box:OnItemMouseEnter(MouseEnter)

	local OnClick = function()
		if IsCtrlKeyDown() then
			EditBox_AppendLinkItemInfo(1, item_data.dwTabType, item_data.dwIndex, item_data.nBookID)
			return
		end
		if not LR.bCanDebug2() then
			return
		end
		if (not LR_AccountStatistics_Bag_Panel.CalBag) and (not LR_AccountStatistics_Bag_Panel.CalBank) and LR_AccountStatistics_Bag_Panel.CalMail and LR_AccountStatistics_Bag_Panel.dwID ~= -1
			or (item_data.nUiId == 0 and LR_AccountStatistics_Bag_Panel.dwID ~= -1 )
		then
			if LR_AccountStatistics_Mail_None.XinShiID > 0 then
				LR_AccountStatistics_Mail.info = {}
				LR_AccountStatistics_Mail.ItemInMail = {}
				LR_AccountStatistics_Mail.MailData = {}
				LR_AccountStatistics_Mail.GetItemByMail()
				local path = sformat("%s\\%s", SaveDataPath, DB_name)
				local DB = SQLite3_Open(path)
				DB:Execute("BEGIN TRANSACTION")
				LR_AccountStatistics_Mail.SaveData(DB)
				DB:Execute("END TRANSACTION")
				DB:Release()

				if LR_AccountStatistics_Mail.ItemInMail[item_data.szKey] and next(LR_AccountStatistics_Mail.ItemInMail[item_data.szKey].nBelongMailID or {}) ~= nil then
					local ItemBelong = LR_AccountStatistics_Bag_Panel.ItemBelong[item_data.szKey] or {}
					local MailData = LR_AccountStatistics_Bag_Panel.MailData or {}
					local nBelongMailID = {}
					for belong, v in pairs (ItemBelong) do
						for nMailID, v2 in pairs(v.nBelongMailID) do
							nBelongMailID[#nBelongMailID+1] = {nMailID = tonumber(nMailID), belong = belong, nEndTime = MailData[belong][tonumber(nMailID)].nEndTime}
						end
					end
					tsort(nBelongMailID,function(a, b)
						return a.nEndTime < b.nEndTime
					end)

					local menu = {}
					for k, v in pairs(nBelongMailID) do
						local nMailID = v.nMailID
						for nIndex, v2 in pairs (LR_AccountStatistics_Mail.info[tonumber(nMailID)].location) do
							if v2.szKey == item_data.szKey then
								LR_AccountStatistics_Mail_Loot.LootMailItem(tonumber(nMailID), nIndex)
							end
						end
					end
				else
					LR.SysMsg(_L["Please refresh again.\n"])
				end
			else
				LR.SysMsg(_L["Please goto the messenger, and check out mail once.\n"])
			end
		end
	end
	box:OnItemLButtonClick(OnClick)

	local OnRClick = function()
		if not LR.bCanDebug2() then
			return
		end
		local frame = Station.Lookup("Normal/MailPanel")
		if not frame then
			return
		end
		if (not LR_AccountStatistics_Bag_Panel.CalBag) and (not LR_AccountStatistics_Bag_Panel.CalBank) and LR_AccountStatistics_Bag_Panel.CalMail and LR_AccountStatistics_Bag_Panel.dwID ~= -1
			or (item_data.nUiId == 0 and LR_AccountStatistics_Bag_Panel.dwID ~=  -1 )
		then
			if LR_AccountStatistics_Mail_None.XinShiID > 0 then
				LR_AccountStatistics_Mail.info = {}
				LR_AccountStatistics_Mail.ItemInMail = {}
				LR_AccountStatistics_Mail.MailData = {}
				LR_AccountStatistics_Mail.GetItemByMail()
				local path = sformat("%s\\%s", SaveDataPath, DB_name)
				local DB = SQLite3_Open(path)
				DB:Execute("BEGIN TRANSACTION")
				LR_AccountStatistics_Mail.SaveData(DB)
				DB:Execute("END TRANSACTION")
				DB:Release()

				if LR_AccountStatistics_Mail.ItemInMail[item_data.szKey] and next(LR_AccountStatistics_Mail.ItemInMail[item_data.szKey].nBelongMailID or {}) ~= nil then
					local ItemBelong = LR_AccountStatistics_Bag_Panel.ItemBelong[item_data.szKey] or {}
					local MailData = LR_AccountStatistics_Bag_Panel.MailData or {}
					local menu = {}
					local nBelongMailID = {}
					for belong, v in pairs (ItemBelong) do
						for nMailID, v2 in pairs(v.nBelongMailID) do
							nBelongMailID[#nBelongMailID+1] = {nMailID = tonumber(nMailID), belong = belong, nEndTime = MailData[belong][tonumber(nMailID)].nEndTime}
						end
					end
					tsort(nBelongMailID,function(a, b)
						return a.nEndTime < b.nEndTime
					end)

					for k, v in pairs(nBelongMailID) do
						local nMailID = v.nMailID
						local szSenderName = MailData[v.belong][tonumber(nMailID)].szSenderName
						local nStackNum = MailData[v.belong][tonumber(nMailID)].item_record[item_data.szKey]
						local szTitle =  MailData[v.belong][tonumber(nMailID)].szTitle
						local m = {
							szOption =  sformat(" %s『%s』%d (id:%d)", szSenderName, szTitle, nStackNum, tonumber(nMailID)),
							bCheck = false,
							bChecked = false,
							bMCheck = false,
							szIcon = "UI\\Image\\UICommon\\CommonPanel2.UITex",
							nFrame = 105,
							nMouseOverFrame = 106,
							szLayer = "ICON_LEFT",
							fnClickIcon = function()
								LR_AccountStatistics_Mail.info[tonumber(nMailID)] = LR_AccountStatistics_Mail.info[tonumber(nMailID)] or {}
								for nIndex, v4 in pairs (LR_AccountStatistics_Mail.info[tonumber(nMailID)].location or {}) do
									if v4.szKey == item_data.szKey then
										LR_AccountStatistics_Mail_Loot.LootMailItem(tonumber(nMailID), nIndex)
									end
								end
							end,
						}
						if MailData[v.belong][tonumber(nMailID)].nEndTime - GetCurrentTime() < 60 * 60 * 24 * 7 then
							m.szOption = sformat("(%s) %s", _L["to be expired"], m.szOption )
							m.rgb = {255, 201, 14}
						end
						--Output(LR_AccountStatistics_Mail.info[tonumber(nMailID)])
						for nIndex, v4 in pairs (LR_AccountStatistics_Mail.info[tonumber(nMailID)].location) do
							if v4.szKey == item_data.szKey then
								m[#m+1] = {
									szOption =  sformat("%s", v4.szName),
									fnAction = function()
										LR_AccountStatistics_Mail_Loot.LootMailItem(tonumber(nMailID), nIndex)
									end,
								}
							end
						end
						menu[#menu+1] = m
					end
					PopupMenu(menu)
				else
					LR.SysMsg(_L["Please refresh again.\n"])
				end
			else
				LR.SysMsg(_L["Please goto the messenger, and check out mail once.\n"])
			end
		end
	end
	box:OnItemRButtonClick(OnRClick)
end

function LR_AccountStatistics_Bag_Panel.CheckData(target_table, item)
	local t_table =  target_table
	local t_item =  item

	if not t_item then
		return
	end

	for i = 1, #t_table, 1 do
		if t_table[i].nGenre ==   ITEM_GENRE.BOOK then
			if t_table[i].nBookID ==  t_item.nBookID and t_table[i].bBind ==  t_item.bBind then
				return i
			end
		elseif t_table[i].nUiId == t_item.nUiId and t_table[i].bBind ==  t_item.bBind then
			return i
		end
	end
	return 0
end


-------------------载入数据
function LR_AccountStatistics_Bag_Panel.LoadUserBagData(DB)
	local realArea = LR_AccountStatistics_Bag_Panel.realArea
	local realServer = LR_AccountStatistics_Bag_Panel.realServer
	local dwID = LR_AccountStatistics_Bag_Panel.dwID
	if not LR_AccountStatistics_Bag_Panel.CalBag or LR_AccountStatistics_Bag_Panel.bShowExpireMail then
		--LR_AccountStatistics_Bag_Panel.AllUsrItemInBag[belong] = {}
		return
	end
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area2, Server2, realArea2, realServer2 = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	if dwID == 0 then
		dwID = me.dwID
		realArea = realArea2
		realServer = realServer2
	end
	local belong = sformat("%s_%s_%d", realArea, realServer, dwID)
	local ItemInBag = {}
	if dwID >= 0 then
		if dwID == me.dwID and realArea2 == realArea and realServer2 == realServer or dwID == 0 then
			ItemInBag = LR_AccountStatistics_Bag.ItemInBag
		else
			local DB_SELECT = DB:Prepare("SELECT bag_item_data.* FROM bag_item_data INNER JOIN player_info ON bag_item_data.belong = player_info.szKey WHERE bag_item_data.bDel = 0 AND bag_item_data.belong = ? AND bag_item_data.nStackNum > 0 AND bag_item_data.szKey IS NOT NULL AND bag_item_data.belong IS NOT NULL")
			DB_SELECT:ClearBindings()
			DB_SELECT:BindAll(belong)
			local Data = DB_SELECT:GetAll() or {}
			for k, v in pairs (Data) do
				ItemInBag[v.szKey] = v
			end
		end
		--所属信息
		for k, v in pairs (ItemInBag) do
			LR_AccountStatistics_Bag_Panel.ItemBelong[v.szKey] = LR_AccountStatistics_Bag_Panel.ItemBelong[v.szKey] or {}
			LR_AccountStatistics_Bag_Panel.ItemBelong[v.szKey][belong] = LR_AccountStatistics_Bag_Panel.ItemBelong[v.szKey][belong] or {}
			LR_AccountStatistics_Bag_Panel.ItemBelong[v.szKey][belong].belongUsr = belong
			LR_AccountStatistics_Bag_Panel.ItemBelong[v.szKey][belong].bag_num = v.nStackNum
		end
	elseif dwID == -1 then
		local DB_SELECT = DB:Prepare("SELECT belong, player_info.dwID, player_info.realArea, player_info.realServer FROM bag_item_data INNER JOIN player_info ON bag_item_data.belong = player_info.szKey WHERE bag_item_data.szKey IS NOT NULL AND bag_item_data.belong IS NOT NULL GROUP BY belong")
		local UserList = DB_SELECT:GetAll() or {}
		for k, v in pairs(UserList) do
			local temp = {}
			if v.dwID == me.dwID and realArea2 == v.realArea and realServer2 == v.realServer then
				temp = LR_AccountStatistics_Bag.ItemInBag
			else
				local DB_SELECT2 = DB:Prepare("SELECT bag_item_data.* FROM bag_item_data INNER JOIN player_info ON bag_item_data.belong = player_info.szKey WHERE bag_item_data.bDel = 0 AND bag_item_data.belong = ? AND bag_item_data.nStackNum > 0 AND bag_item_data.szKey IS NOT NULL AND bag_item_data.belong IS NOT NULL")
				DB_SELECT2:ClearBindings()
				DB_SELECT2:BindAll(v.belong)
				local Data = DB_SELECT2:GetAll() or {}
				--Output(Data)
				for k2, v2 in pairs (Data) do
					temp[v2.szKey] = v2
				end
			end

			for k3, v3 in pairs(temp) do
				if ItemInBag[v3.szKey] then
					ItemInBag[v3.szKey].nStackNum = ItemInBag[v3.szKey].nStackNum + v3.nStackNum
				else
					ItemInBag[v3.szKey] = clone(v3)
				end

				LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey] = LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey] or {}
				LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong] = LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong] or {}
				LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong].belongUsr = v.belong
				LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong].bag_num = v3.nStackNum
			end
		end
	end
	LR_AccountStatistics_Bag_Panel.ItemInBag = clone(ItemInBag)
end

function LR_AccountStatistics_Bag_Panel.LoadUserBankData(DB)
	local realArea = LR_AccountStatistics_Bag_Panel.realArea
	local realServer = LR_AccountStatistics_Bag_Panel.realServer
	local dwID = LR_AccountStatistics_Bag_Panel.dwID
	if not LR_AccountStatistics_Bag_Panel.CalBank or LR_AccountStatistics_Bag_Panel.bShowExpireMail then
		--LR_AccountStatistics_Bag_Panel.AllUsrItemInBag[belong] = {}
		return
	end
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area2, Server2, realArea2, realServer2 = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	if dwID == 0 then
		dwID = me.dwID
		realArea = realArea2
		realServer = realServer2
	end
	local belong = sformat("%s_%s_%d", realArea, realServer, dwID)
	local ItemInBank = {}
	if dwID >= 0 then
		if dwID == me.dwID and realArea2 == realArea and realServer2 == realServer or dwID == 0 then
			ItemInBank = LR_AccountStatistics_Bank.ItemInBank
		else
			local DB_SELECT = DB:Prepare("SELECT bank_item_data.* FROM bank_item_data INNER JOIN player_info ON bank_item_data.belong = player_info.szKey WHERE bank_item_data.bDel = 0 AND bank_item_data.belong = ? AND bank_item_data.nStackNum > 0 AND bank_item_data.szKey IS NOT NULL AND bank_item_data.belong IS NOT NULL")
			DB_SELECT:ClearBindings()
			DB_SELECT:BindAll(belong)
			local Data = DB_SELECT:GetAll() or {}
			for k, v in pairs (Data) do
				ItemInBank[v.szKey] = v
			end
		end
		--所属信息
		for k, v in pairs (ItemInBank) do
			LR_AccountStatistics_Bag_Panel.ItemBelong[v.szKey] = LR_AccountStatistics_Bag_Panel.ItemBelong[v.szKey] or {}
			LR_AccountStatistics_Bag_Panel.ItemBelong[v.szKey][belong] = LR_AccountStatistics_Bag_Panel.ItemBelong[v.szKey][belong] or {}
			LR_AccountStatistics_Bag_Panel.ItemBelong[v.szKey][belong].belongUsr = belong
			LR_AccountStatistics_Bag_Panel.ItemBelong[v.szKey][belong].bank_num = v.nStackNum
		end
	elseif dwID == -1 then
		local DB_SELECT = DB:Prepare("SELECT belong, player_info.dwID, player_info.realArea, player_info.realServer FROM bank_item_data INNER JOIN player_info ON bank_item_data.belong = player_info.szKey WHERE bank_item_data.szKey IS NOT NULL AND bank_item_data.belong IS NOT NULL GROUP BY belong")
		local UserList = DB_SELECT:GetAll() or {}
		for k, v in pairs(UserList) do
			local temp = {}
			if v.dwID == me.dwID and realArea2 == v.realArea and realServer2 == v.realServer then
				temp = LR_AccountStatistics_Bank.ItemInBank
			else
				local DB_SELECT2 = DB:Prepare("SELECT bank_item_data.* FROM bank_item_data INNER JOIN player_info ON bank_item_data.belong = player_info.szKey WHERE bank_item_data.bDel = 0 AND bank_item_data.belong = ? AND bank_item_data.nStackNum > 0 AND bank_item_data.szKey IS NOT NULL AND bank_item_data.belong IS NOT NULL")
				DB_SELECT2:ClearBindings()
				DB_SELECT2:BindAll(v.belong)
				local Data = DB_SELECT2:GetAll() or {}
				--Output(Data)
				for k2, v2 in pairs (Data) do
					temp[v2.szKey] = v2
				end
			end

			for k3, v3 in pairs(temp) do
				if ItemInBank[v3.szKey] then
					ItemInBank[v3.szKey].nStackNum = ItemInBank[v3.szKey].nStackNum + v3.nStackNum
				else
					ItemInBank[v3.szKey] = clone(v3)
				end

				LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey] = LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey] or {}
				LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong] = LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong] or {}
				LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong].belongUsr = v.belong
				LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong].bank_num = v3.nStackNum
			end
		end
	end
	LR_AccountStatistics_Bag_Panel.ItemInBank = clone(ItemInBank)
end


--[[
ItemInMail = {
	item,
	MailDetail = {{num, nLeftTime, belong_mailID},
					   {num, nLeftTime, belong_mailID},
	}
}
]]
function LR_AccountStatistics_Bag_Panel.LoadUserMailData(DB)
	local realArea = LR_AccountStatistics_Bag_Panel.realArea
	local realServer = LR_AccountStatistics_Bag_Panel.realServer
	local dwID = LR_AccountStatistics_Bag_Panel.dwID

	if not LR_AccountStatistics_Bag_Panel.CalMail then
		--LR_AccountStatistics_Bag_Panel.AllUsrItemInBag[belong] = {}
		return
	end
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area2, Server2, realArea2, realServer2 = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	if dwID == 0 then
		dwID = me.dwID
		realArea = realArea2
		realServer = realServer2
	end
	local belong = sformat("%s_%s_%d", realArea, realServer, dwID)
	local selfKey = sformat("%s_%s_%d", realArea2, realServer2, me.dwID)
	local ItemInMail = {}
	local MailData = {}
	local UserList = {}
	if dwID >= 0 then
		if dwID == me.dwID then
			UserList[belong] = {belong = belong, realArea = realArea2, realServer = realServer2, dwID = me.dwID}
		else
			UserList[belong] = {belong = belong, realArea = realArea, realServer = realServer, dwID = dwID}
		end
	else
		local SQL = "SELECT belong, player_info.dwID, player_info.realArea, player_info.realServer FROM mail_data INNER JOIN player_info ON mail_data.belong = player_info.szKey WHERE mail_data.bDel = 0 AND mail_data.nMailID IS NOT NULL AND mail_data.belong IS NOT NULL GROUP BY belong"
		if LR_AccountStatistics_Bag_Panel.bShowExpireMail then
			local nEndTime = GetCurrentTime() + 60 * 60 *24 * 7
			SQL = sformat("SELECT belong, player_info.dwID, player_info.realArea, player_info.realServer FROM mail_data INNER JOIN player_info ON mail_data.belong = player_info.szKey WHERE mail_data.bDel = 0 AND mail_data.nEndTime < %d AND mail_data.nMailID IS NOT NULL AND mail_data.belong IS NOT NULL GROUP BY belong", nEndTime)
		end
		local DB_SELECT = DB:Prepare(SQL)
		local UserList2 = DB_SELECT:GetAll() or {}
		for k, v in pairs(UserList2) do
			UserList[v.belong] = v
		end
		UserList[selfKey] = {belong = selfKey, realArea = realArea2, realServer = realServer2, dwID = me.dwID}		--增加自己
	end

	for belong, v in pairs(UserList) do
		local ItemInMail2 = {}
		local MailData2 = {}
		local t_num = {}
		local t_nMailID = {}
		if selfKey == v.belong and next(LR_AccountStatistics_Mail.ItemInMail) ~= nil then
			if LR_AccountStatistics_Bag_Panel.bShowExpireMail then
				local nEndTime = GetCurrentTime() + 60 * 60 *24 * 7
				for nMailID, v2 in pairs (LR_AccountStatistics_Mail.MailData) do
					if v2.nEndTime < nEndTime then
						MailData2[nMailID] = v2
						for szKey, num in pairs(v2.item_record) do
							ItemInMail2[szKey] = LR_AccountStatistics_Mail.ItemInMail[szKey]
						end
					end
				end
			else
				MailData2 = clone(LR_AccountStatistics_Mail.MailData)
				ItemInMail2 = clone(LR_AccountStatistics_Mail.ItemInMail)
			end
		else
			local SQL = "SELECT * FROM mail_data WHERE belong = ? AND bDel = 0 AND nMailID IS NOT NULL AND belong IS NOT NULL"
			if LR_AccountStatistics_Bag_Panel.bShowExpireMail then
				local nEndTime = GetCurrentTime() + 60 * 60 *24 * 7
				SQL = sformat("SELECT * FROM mail_data WHERE belong = ? AND bDel = 0 AND nEndTime < %d AND nMailID IS NOT NULL AND belong IS NOT NULL", nEndTime)
			end
			local DB_SELECT = DB:Prepare(SQL)
			DB_SELECT:ClearBindings()
			DB_SELECT:BindAll(belong)
			local Data = DB_SELECT:GetAll() or {}
			if next(Data) ~= nil then
				for k2, v2 in pairs(Data) do
					MailData2[v2.nMailID] = clone(v2)
					MailData2[v2.nMailID].item_record = LR.JsonDecode(v2.item_record)
				end
				--获取邮件中的物品信息
				local SQL2 = "SELECT * FROM mail_item_data WHERE belong = ? AND bDel = 0 AND szKey IS NOT NULL AND belong IS NOT NULL"
				if LR_AccountStatistics_Bag_Panel.bShowExpireMail then
					local t_szKey2 = {}
					for k3, v3 in pairs(MailData2) do
						for k2, v2 in pairs(v3.item_record) do
							t_szKey2[k2] = true
							t_num[k2] = ( t_num[k2] or 0 ) + v2
						end
					end
					local t_szKey = {}
					for k2, v2 in pairs(t_szKey2) do
						t_szKey[#t_szKey+1] = sformat("'%s'", k2)
					end
					SQL2 = sformat("SELECT * FROM mail_item_data WHERE belong = ? AND bDel = 0 AND szKey IN ( %s ) AND szKey IS NOT NULL AND belong IS NOT NULL", tconcat(t_szKey, ", "))
				end
				local DB_SELECT2 = DB:Prepare(SQL2)
				DB_SELECT2:ClearBindings()
				DB_SELECT2:BindAll(belong)
				local Data2 = DB_SELECT2:GetAll() or {}
				for k2, v2 in pairs (Data2) do
					ItemInMail2[v2.szKey] = v2
					ItemInMail2[v2.szKey].nBelongMailID = LR.JsonDecode(v2.nBelongMailID)
				end
			end
		end
		---
		for k3, v3 in pairs(MailData2) do
			for k2, v2 in pairs(v3.item_record) do
				t_nMailID[k2] = t_nMailID[k2] or {}
				t_nMailID[k2][k3] = true
			end
		end
		----
		for k3, v3 in pairs(ItemInMail2) do
			if ItemInMail[v3.szKey] then
				if LR_AccountStatistics_Bag_Panel.bShowExpireMail then
					ItemInMail[v3.szKey].nStackNum = ItemInMail[v3.szKey].nStackNum + t_num[v3.szKey]
				else
					ItemInMail[v3.szKey].nStackNum = ItemInMail[v3.szKey].nStackNum + v3.nStackNum
				end
			else
				ItemInMail[v3.szKey] = clone(v3)
				if LR_AccountStatistics_Bag_Panel.bShowExpireMail then
					ItemInMail[v3.szKey].nStackNum = t_num[v3.szKey] or 0
				end
			end

			LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey] = LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey] or {}
			LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong] = LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong] or {}
			LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong].belongUsr = v.belong
			LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong].mail_num = v3.nStackNum
			if LR_AccountStatistics_Bag_Panel.bShowExpireMail then
				LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong].mail_num = t_num[v3.szKey]
			end
			LR_AccountStatistics_Bag_Panel.ItemBelong[v3.szKey][v.belong].nBelongMailID = clone(t_nMailID[v3.szKey])
		end
		MailData[belong] = clone(MailData2)
	end

	LR_AccountStatistics_Bag_Panel.ItemInMail = clone(ItemInMail)
	LR_AccountStatistics_Bag_Panel.MailData = clone(MailData)
end

-------合并表格
function LR_AccountStatistics_Bag_Panel.MergeTable (_table1, _table2, _type)
	local t_table1 =  _table1 or {}
	local t_table2 =  _table2 or {}

	local result_table = {}
	result_table = clone (t_table1)
	if _type ==  "bag" then
		for szKey , v in pairs (t_table2) do
			if result_table[szKey] then
				result_table[szKey].nStackNum = result_table[szKey].nStackNum  + v.nStackNum
			else
				result_table[szKey] = v
			end
		end
	end

	if _type ==  "bank" then
		for szKey , v in pairs (t_table2) do
			if result_table[szKey] then
				result_table[szKey].nStackNum = result_table[szKey].nStackNum  + v.nStackNum
			else
				result_table[szKey] = v
			end
		end
	end

	if _type ==  "mail" then
		for szKey , v in pairs (t_table2) do
			if result_table[szKey] then
				result_table[szKey].nStackNum = result_table[szKey].nStackNum  + v.nStackNum
			else
				result_table[szKey] = v
			end
		end
	end

	return result_table
end

function LR_AccountStatistics_Bag_Panel.CheckDetail (_desc, _usr)
	local temp_table = _desc or {}
	for i = 1, #temp_table, 1 do
		if temp_table[i].belongUsr ==  _usr then
			return i
		end
	end
	return 0
end

function LR_AccountStatistics_Bag_Panel.FetchData2 (t_table)
	if LR_AccountStatistics_Bag_Panel.searchText ==  "" or  LR_AccountStatistics_Bag_Panel.searchText ==  nil then
		return t_table
	end

	for nUiId , v in pairs(t_table) do
		local szName = LR.GetItemNameByItem(v)
		local _start, _end = sfind(szName, LR_AccountStatistics_Bag_Panel.searchText)
		if not _start then
			t_table[nUiId] = nil
		end
	end

	return t_table
end

function LR_AccountStatistics_Bag_Panel.FetchData()
	local t_temp1 = {}
	local t1 = clone (LR_AccountStatistics_Bag_Panel.ItemInBag) or {}
	local t2 = clone (LR_AccountStatistics_Bag_Panel.ItemInBank) or {}
	local t3 = clone (LR_AccountStatistics_Bag_Panel.ItemInMail) or {}

	if LR_AccountStatistics_Bag_Panel.CalBag then
		t1 = LR_AccountStatistics_Bag_Panel.FetchData2 (t1)
		t_temp1 =  LR_AccountStatistics_Bag_Panel.MergeTable (t_temp1, t1, "bag")
	end
	if LR_AccountStatistics_Bag_Panel.CalBank then
		t2 = LR_AccountStatistics_Bag_Panel.FetchData2 (t2)
		t_temp1 =  LR_AccountStatistics_Bag_Panel.MergeTable (t_temp1, t2, "bank")
	end
	if LR_AccountStatistics_Bag_Panel.CalMail then
		t3 = LR_AccountStatistics_Bag_Panel.FetchData2 (t3)
		t_temp1 =  LR_AccountStatistics_Bag_Panel.MergeTable (t_temp1, t3, "mail")
	end

	return t_temp1
end

-----过滤条件（按种类过滤）
function LR_AccountStatistics_Bag_Panel.FilterData(t_table)
	local temp_table = t_table or {}
	local table1 = {}
	local FilterCondition = LR_AccountStatistics_Bag_Panel.FilterCondition or {}
	local FilterTable = {}

	---{display = _L["TASK_ITEM"], f_arg1 = "nGenre", f_arg2 = ITEM_GENRE.TASK_ITEM, checked = true, },
	for i = 1, #FilterCondition-1, 1 do
		FilterTable[FilterCondition[i].f_arg2] = {}
	end
	FilterTable["other"] = {}

	for nUiId, v in pairs (temp_table) do
		if FilterTable[v.nGenre] ~=  nil then
			FilterTable[v.nGenre][#FilterTable[v.nGenre]+1] = v
		else
			FilterTable["other"][#FilterTable["other"]+1] = v
		end
	end

	for i = 1, #FilterCondition-1, 1 do
		if FilterCondition[i].checked then
			local t1 = LR_AccountStatistics_Bag_Panel.SortData(FilterTable[FilterCondition[i].f_arg2])
			for k = 1, #t1, 1 do
				table1[#table1+1] = t1[k]
			end
		end
	end
	if FilterCondition[#FilterCondition].checked then
		local t1 = LR_AccountStatistics_Bag_Panel.SortData(FilterTable["other"])
			for k = 1, #t1, 1 do
				table1[#table1+1] = t1[k]
			end
	end

	return table1
end

----排序
function LR_AccountStatistics_Bag_Panel.SortData(t_table)
	local temp_table = (t_table) or {}
	local tt = {}
	tsort(temp_table, function(a, b)
		if a.nGenre == b.nGenre then
			if a.nSub == b.nSub then
				if a.nDetail == b.nDetail then
					if a.nQuality == b.nQuality then
						return a.nUiId < b.nUiId
					else
						return a.nQuality > b.nQuality
					end
				else
					return a.nDetail < b.nDetail
				end
			else
				return a.nSub < b.nSub
			end
		else
			return a.nGenre < b.nGenre
		end
	end)

	return temp_table
end

function LR_AccountStatistics_Bag_Panel:LoadItemBox(hWin)
	local realArea = LR_AccountStatistics_Bag_Panel.realArea
	local realServer = LR_AccountStatistics_Bag_Panel.realServer
	local dwID = LR_AccountStatistics_Bag_Panel.dwID
	local hComboBox = self:Fetch("ComboBox_name")
	if dwID == -1 then
		hComboBox:SetText(_L["(ALL CHARACTERS)"])
	elseif dwID == 0 then
		hComboBox:SetText(GetClientPlayer().szName)
	else
		hComboBox:SetText(LR_AccountStatistics.AllUsrList[sformat("%s_%s_%d", realArea, realServer, dwID)].szName)
	end

	local hIconViewContent = self:Append("Handle", hWin, "IconViewContent", {x = 33, y = 33, w = 700, h = 300})
	hIconViewContent:SetHandleStyle(3)

	local hBtnPrev = self:Append("Button", hWin, "BtnIconPrev", {x = 200, y = 350, text = _L["Prev"], enable = false})
	local hBtnNext = self:Append("Button", hWin, "BtnIconNext", {x = 410, y = 350, text = _L["Next"]})

	local t_table = {}

	--LR_AccountStatistics_Bag_Panel.LoadUserAllData()
	t_table = clone (LR_AccountStatistics_Bag_Panel.FetchData())
	t_table = clone (LR_AccountStatistics_Bag_Panel.FilterData(t_table))

	local n , nTol = 1, mceil( #t_table / 84)
	local hPage = self:Append("Text", hWin, "TextIconPage", {x = 340, y = 350, text = sformat("%d / %d", n, nTol)})

	for i = 1, 84 do
		local item_data = t_table[i]
		if t_table[i] then
			LR_AccountStatistics_Bag_Panel:LoadOneItem2(hIconViewContent, item_data)
		end
	end

	hBtnPrev.OnClick = function()
		n = mmax(1, n - 1)
		hPage:SprintfText("%d / %d", n, nTol)
		if n ==  1 then
			hBtnPrev:Enable(false)
		else
			hBtnPrev:Enable(true)
		end
		hIconViewContent:Clear()
		hBtnNext:Enable(true)
		for i = 1, 84 do
			k = (n - 1) * 84 + i
			local item_data = t_table[k]
			if item_data then
				LR_AccountStatistics_Bag_Panel:LoadOneItem2(hIconViewContent, item_data)
			end
		end
	end
	hBtnNext.OnClick = function()
		n = mmin(nTol, n + 1)
		hPage:SprintfText("%d / %d", n, nTol)
		if n ==  nTol then
			hBtnNext:Enable(false)
		else
			hBtnNext:Enable(true)
		end
		hIconViewContent:Clear()
		hBtnPrev:Enable(true)
		for i = 1, 84 do
			k = (n - 1) * 84 + i
			local item_data = t_table[k]
			if item_data then
				LR_AccountStatistics_Bag_Panel:LoadOneItem2(hIconViewContent, item_data)
			end
		end
	end
end

---------------------------------------------
------检查是否有到期邮件
---------------------------------------------
LR_AccountStatistics_Mail_Check = {}
function LR_AccountStatistics_Mail_Check.CheckAllMail()
	if not (LR_AccountStatistics_Mail.UsrData.atMaturity or LR_AccountStatistics_Mail.UsrData.remind) then
		return
	end
	local _check_time = GetTickCount()
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	if LR_AccountStatistics_Mail.UsrData.atMaturity then
		local DB_SELECT = DB:Prepare("SELECT COUNT(*) AS COUNT FROM mail_data INNER JOIN player_info ON mail_data.belong = player_info.szKey WHERE mail_data.bDel = 0 AND nEndTime < ? AND nEndTime > ? AND mail_data.nMailID IS NOT NULL AND mail_data.belong IS NOT NULL")
		local nEndTime = GetCurrentTime() + 60 * 60 * 24 * LR_AccountStatistics_Mail.UsrData.atMaturityDay
		DB_SELECT:ClearBindings()
		DB_SELECT:BindAll(nEndTime, GetCurrentTime())
		local Data = DB_SELECT:GetAll() or {}
		if next(Data) ~= nil and Data[1].COUNT > 0 then
			local msg = sformat("%s\n", _L["LR_Mail:Someone's mail is about to expire. Open [LR_Bag] to have a look."])
			LR.SysMsg(msg)
			--LR.RedAlert(msg)
			if false then
				local DB_SELECT2 = DB:Prepare("SELECT * FROM mail_data INNER JOIN player_info ON mail_data.belong = player_info.szKey WHERE mail_data.bDel = 0 AND nEndTime < ? AND nEndTime > ? AND mail_data.nMailID IS NOT NULL AND mail_data.belong IS NOT NULL")
				local nEndTime = GetCurrentTime() + 60 * 60 * 24 * LR_AccountStatistics_Mail.UsrData.atMaturityDay
				DB_SELECT2:ClearBindings()
				DB_SELECT2:BindAll(nEndTime, GetCurrentTime())
				local Data2 = DB_SELECT2:GetAll() or {}
				for k, v in pairs (Data2) do
					Output(v.szName)
				end
			end
		end
	end

	if LR_AccountStatistics_Mail.UsrData.remind then
		local DB_SELECT = DB:Prepare("SELECT * FROM mail_receive_time WHERE szKey = ? AND bDel = 0 AND szKey IS NOT NULL")
		local me = GetClientPlayer()
		local ServerInfo = {GetUserServer()}
		local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
		local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
		DB_SELECT:ClearBindings()
		DB_SELECT:BindAll(szKey)
		local Data = DB_SELECT:GetAll() or {}
		if next(Data) ~= nil and Data[1].nTime < GetCurrentTime() - 60 * 60 * 24 * LR_AccountStatistics_Mail.UsrData.remindDay then
			local msg = sformat(_L["LR_Mail:You have not received letters for at least %d days.\n"], LR_AccountStatistics_Mail.UsrData.remindDay)
			if Data[1] then
				local day = mfloor ((GetCurrentTime() - Data[1].nTime) / 60 / 60 / 24)
				msg = sformat(_L["LR_Mail:You have not received letters for %d days.\n"], day)
			end
			LR.SysMsg(msg)
			LR.RedAlert(msg)
		end
	end

	DB:Execute("END TRANSACTION")
	DB:Release()
	Log(sformat("[LR] Checking Mail expire cost %0.3f s", (GetTickCount() - _check_time) * 1.0 / 1000 ))
end

-----------------------------------------------------------------------
local _Hook = {}
if AH_MailBank and AH_MailBank.HookBagPanel then
	_Hook._HookBagPanel = AH_MailBank.HookBagPanel
	AH_MailBank.HookBagPanel = function()
		LR.DelayCall(400, function() _Hook._HookBagPanel() end)
	end
end

function LR_AccountStatistics_Bag.FIRST_LOADING_END()
	LR_AccountStatistics_Mail_Check.CheckAllMail()
end

LR.RegisterEvent("FIRST_LOADING_END", function() LR_AccountStatistics_Bag.FIRST_LOADING_END() end)



