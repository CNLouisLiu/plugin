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
local VERSION = "20170717"
---------------------------------------------------------------
local OPERATION_TYPE = {
	ADD = 1,
	MODIFY = 2,
	DEL = 3,
	SYNC = 4,
}


---------------------------------------------------------------
LR_GKP_Base = {}
local DefaultData = {
	bOn = true,
}
LR_GKP_Base.UsrData = clone(DefaultData)
RegisterCustomData("LR_GKP_Base.UsrData", CustomVersion)

LR_GKP_Base.GKP_Bill = {}	--GKP记录的账单号信息
LR_GKP_Base.GKP_TradeList = {}	--GKP的记录内容
LR_GKP_Base.GKP_Person_Trade = {}	--个人消费总金额
LR_GKP_Base.GKP_Person_Debt = {}		--个人欠账
LR_GKP_Base.GKP_Person_Cash = {}		--个人交易金钱记录--数据库 + 缓存
LR_GKP_Base.GKP_Person_Cash_Temp = {}	--个人交易记录缓存

LR_GKP_Base.szSearchKey = "nCreateTime"
LR_GKP_Base.szOrderKey = "DESC"


function LR_GKP_Base.LoadGKPList(szBillName)
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
		local GKP_TradeList = LR_GKP_Base.GKP_TradeList
		local szSearchKey = LR_GKP_Base.szSearchKey
		local szOrderKey = LR_GKP_Base.szOrderKey
		local DB_SELECT2 = DB:Prepare(sformat("SELECT * FROM trade_data WHERE szBelongBill = ? ORDER BY %s %s", szSearchKey, szOrderKey))
		DB_SELECT2:ClearBindings()
		DB_SELECT2:BindAll(szName)
		local result2 = DB_SELECT2:GetAll() or {}
		for k, v in pairs(result2) do
			local trade_data = {}
			trade_data.szKey = v.szKey
			trade_data.hash = v.hash
			trade_data.szName = LR.StrDB2Game(v.szName)
			trade_data.dwTabType = v.dwTabType
			trade_data.dwIndex = v.dwIndex
			trade_data.nBookID = v.nBookID
			trade_data.nStackNum = v.nStackNum
			trade_data.szArea = LR.StrDB2Game(v.szArea)
			trade_data.szServer = LR.StrDB2Game(v.szServer)
			trade_data.dwMapID = v.dwMapID
			trade_data.nCopyIndex = v.nCopyIndex
			trade_data.nGold = v.nGold
			trade_data.nSilver = v.nSilver
			trade_data.nCopper = v.nCopper
			trade_data.szDistributorName = LR.StrDB2Game(v.szDistributorName)
			trade_data.dwDistributorID = v.dwDistributorID
			trade_data.dwDistributorForceID = v.dwDistributorForceID
			trade_data.szPurchaserName = LR.StrDB2Game(v.szPurchaserName)
			trade_data.dwPurchaserID = v.dwPurchaserID
			trade_data.dwPurchaserForceID = v.dwPurchaserForceID
			trade_data.nOperationType = v.nOperationType
			trade_data.szSourceName = LR.StrDB2Game(v.szSourceName)
			trade_data.nCreateTime = v.nCreateTime
			trade_data.nSaveTime = v.nSaveTime
			trade_data.szBelongBill = LR.StrDB2Game(v.szBelongBill)
			trade_data.bDel = (v.bDel == 1)
			GKP_TradeList[#GKP_TradeList + 1] = clone(trade_data)

			if v.bDel == 0 then
				LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID] = LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID] or {nGold = 0}
				LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID].dwID = trade_data.dwPurchaserID
				LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID].szName = trade_data.szPurchaserName
				LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID].dwForceID = trade_data.dwPurchaserForceID
				LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID].nGold = LR_GKP_Base.GKP_Person_Trade[v.dwPurchaserID].nGold + trade_data.nGold
			end
		end

		local DB_SELECT3 = DB:Prepare("SELECT * FROM cash_data WHERE szBelongBill = ? AND bDel = 0 AND my_dwID = ? ORDER BY nCreateTime DESC")
		DB_SELECT3:ClearBindings()
		DB_SELECT3:BindAll(szName, me.dwID)
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
function LR_GKP_Base.SaveSingleData(DB, data, bDel)
	--先保存账单信息
	local DB_SELECT = DB:Prepare("SELECT * FROM bill_data WHERE szName = ? AND bDel = 0")
	DB_SELECT:ClearBindings()
	DB_SELECT:BindAll(LR.StrGame2DB(data.szBelongBill))
	local result = DB_SELECT:GetAll() or {}
	if next(result) == nil then
		LR_GKP_Base.CreateNewBill(DB, data.szBelongBill)
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

	local v = {}
	v.szKey = data.szKey
	v.hash = data.hash
	v.szName = LR.StrGame2DB(data.szName)
	v.dwTabType = data.dwTabType
	v.dwIndex = data.dwIndex
	v.nBookID = data.nBookID
	v.nStackNum = data.nStackNum
	v.szArea = LR.StrGame2DB(data.szArea)
	v.szServer = LR.StrGame2DB(data.szServer)
	v.dwMapID = data.dwMapID
	v.nCopyIndex = data.nCopyIndex
	v.nGold = data.nGold
	v.nSilver = data.nSilver
	v.nCopper = data.nCopper
	v.szDistributorName = LR.StrGame2DB(data.szDistributorName)
	v.dwDistributorID = data.dwDistributorID
	v.dwDistributorForceID = data.dwDistributorForceID
	v.szPurchaserName = LR.StrGame2DB(data.szPurchaserName)
	v.dwPurchaserID = data.dwPurchaserID
	v.dwPurchaserForceID = data.dwPurchaserForceID
	v.nOperationType = data.nOperationType
	v.szSourceName = LR.StrGame2DB(data.szSourceName)
	v.nCreateTime = data.nCreateTime
	v.nSaveTime = GetCurrentTime()
	v.szBelongBill = LR.StrGame2DB(data.szBelongBill)

	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(v.szKey, v.hash, v.szName, v.dwTabType, v.dwIndex, v.nBookID, v.nStackNum, v.szArea, v.szServer, v.dwMapID, v.nCopyIndex, v.nGold, v.nSilver, v.nCopper, v.szDistributorName, v.dwDistributorID, v.dwDistributorForceID, v.szPurchaserName, v.dwPurchaserID, v.dwPurchaserForceID, v.nOperationType, v.szSourceName, v.nCreateTime, v.nSaveTime, v.szBelongBill)
	DB_REPLACE:Execute()
end

function LR_GKP_Base.DelSingleData(DB, data)
	LR_GKP_Base.SaveSingleData(DB, data, true)
end

function LR_GKP_Base.SaveCashRecord(DB, data)
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

function LR_GKP_Base.DelCashRecord(DB, data)
	local DB_REPLACE = DB:Prepare("REPLACE INTO cash_data (szKey, bDel) VALUES ( ?, 1)")
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(LR.StrGame2DB(data.szKey))
	DB_REPLACE:Execute()
end

function LR_GKP_Base.CreateNewBill(DB, szBillName)
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local nTime = GetCurrentTime()
	LR_GKP_Base.GKP_Bill = {}
	LR_GKP_Base.GKP_TradeList = {}
	local bill_data =  {
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

	LR_GKP_Panel:RefreshBillName()
end

function LR_GKP_Base.GKP_BgTalk(nType, data)
	LR.BgTalk(PLAYER_TALK_CHANNEL.RAID, "LR_GKP", nType, data)
end

--[[
1、只有发布者是分配者才相应，队长都不行。
]]
local BG_DB = nil
function LR_GKP_Base.ON_BG_CHANNEL_MSG()
	local szKey = arg0
	local nChannel = arg1
	local dwTalkerID = arg2
	local szTalkerName = arg3
	local data = arg4

	if not (szKey == "LR_GKP" or szKey == "MY_GKP") then
		return
	end

	local me = GetClientPlayer()
	if not me or  not (me and (me.IsInParty() or me.IsInRaid())) then
		return
	end
	local team = GetClientTeam()
	if not team then
		return
	end
	local dwDistributerID = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
	if dwDistributerID ~= dwTalkerID then
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
			LR_GKP_Base.SaveSingleData(BG_DB, trade_data)
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
			LR_GKP_Base.DelSingleData(DB, trade_data)
		end
	end

end

function LR_GKP_Base.GetMoneyCol(Money)
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

LR.RegisterEvent("ON_BG_CHANNEL_MSG", function() LR_GKP_Base.ON_BG_CHANNEL_MSG() end)

---------------------------------------------------------------------->
-- 金钱记录
----------------------------------------------------------------------<
LR_GKP_Base.TradingTarget = {}

function LR_GKP_Base.MoneyUpdate(nGold, nSilver, nCopper)
	if nGold > -20 and nGold < 20 then
		return
	end
	if not LR_GKP_Base.TradingTarget then
		return
	end
	if not LR_GKP_Base.TradingTarget.szName then
		return
	end
	local nTime = GetCurrentTime()
	local cash_data = {
		nGold     = nGold,
		szName  = LR_GKP_Base.TradingTarget.szName or "System",
		dwID = LR_GKP_Base.TradingTarget.dwID or 0,
		dwForceID = LR_GKP_Base.TradingTarget.dwForceID,
		nTime     = nTime,
		nCreateTime = nTime,
		dwMapID   = GetClientPlayer().GetMapID()
	}
	LR_GKP_Base.GKP_Person_Cash_Temp[nTime] = clone(cash_data)
	if next(LR_GKP_Base.GKP_Bill) == nil then
		LR.DelayCall(500, function() LR_GKP_Panel:LoadTradeItemBox() end)
		return
	end
	DB = SQLite3_Open(DB_Path)
	DB:Execute("BEGIN TRANSACTION")
	LR_GKP_Base.SaveCashRecord(DB, cash_data)
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
	LR_GKP_Base.TradingTarget = GetPlayer(arg0)
end)
RegisterEvent("TRADING_CLOSE",function() -- 交易结束
	LR_GKP_Base.TradingTarget = {}
end)
RegisterEvent("MONEY_UPDATE",function() --金钱变动
	LR_GKP_Base.MoneyUpdate(arg0, arg1, arg2)
end)

function LR_GKP_Base.OutputTradeList()
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

function LR_GKP_Base.OutputDebtList()
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
	LR.Talk(PLAYER_TALK_CHANNEL.RAID, data1)

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
	LR.Talk(PLAYER_TALK_CHANNEL.RAID, data2)

	local data3 = {}
	data3[#data3 + 1] = {type = "text", text = sformat(_L["Not received money: %d Gold"], nMoney - nMoney2)}
	LR.Talk(PLAYER_TALK_CHANNEL.RAID, data3)

	LR.Talk(PLAYER_TALK_CHANNEL.RAID, _L["=========END========="])
end

function LR_GKP_Base.SyncRecord()
	DB = SQLite3_Open(DB_Path)
	DB:Execute("BEGIN TRANSACTION")
	LR_GKP_Base.GKP_BgTalk("SYNC_BEGIN", {})
	LR.SysMsg(_L["Sync begin\n"])
	for k, v in pairs(LR_GKP_Base.GKP_TradeList) do
		LR_GKP_Base.GKP_BgTalk("SYNC", v)
	end
	LR_GKP_Base.GKP_BgTalk("SYNC_END", {})
	LR.SysMsg(_L["Sync end\n"])
	DB:Execute("END TRANSACTION")
	DB:Release()
end
