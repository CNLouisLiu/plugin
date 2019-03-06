local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AS_Module_CashFlowRecord"
local LanguagePath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local db_name = "maindb.db"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20180403"
---------------------------------------------
local _log_time = 0		--防刷屏设置
local _log_flag = 0		--防刷屏设置
local _save_time = 0
local _save_flag = false
-------------------------------------------------------------
LR_AS_Trade = LR_AS_Trade or {
	Trade_LIst = {},
	Login_Time = 0,
	Login_Money = 0,
	index = {},
	Shop = {},
	Temp_Record = nil,
	Tradeing_Flag = 0,
	Tradeing_TarID = 0,
	Tradeing_Bag = {},
	LootItem_dwID = 0,
	Mail_Flag = false,
	Mail_TarID = 0,
}
LR_AS_Trade.UsrData = {
	ShowMoneyChangeLog = true,
}
RegisterCustomData("LR_AS_Trade.UsrData", VERSION)

local _Event_Trace = {}
local _Doodad_item = {}
local _font = 41
local _Doodad_Cache = {}
local _Bag_item = {}
local _Auction = {}
local _This_Login = {}		--index
local _Today = {}		--index
local _History = {}			--index
local _This_Week = {}		--index
local _This_Month = {}	--index
local _Last_Seven_Days = {}		--index
local _GoldTeam = {bOn = false, nTime = 0, }
local _2bSave = {}
local _Item_In_Mail_old = {nMoney = 0, items = {}, }
local _Item_In_Mail_new = {nMoney = 0, items = {}, }
local _Item_In_Mail_change = {nMoney = 0, items = {}, }
local _Item_In_MailPay_old = {nPayMoney = 0, items = {}, }
local _Item_In_MailPay_new = {nPayMoney = 0, items = {}, }
local _Item_In_MailPay_change = {nPayMoney = 0, items = {}, }
local _Item_In_Bag_old = {nMoney = 0, items = {}, }
local _Item_In_Bag_new = {nMoney = 0, items = {}, }
local _Item_In_Bag_change = {nMoney = 0, items = {}, }
----------------------------------------
-----Debug
----------------------------------------
local Dbug = {
	Debug_enable = false,
}

function Dbug._Debug_Event(nCount)
	if not Dbug.Debug_enable then
		return
	end
	LR.SysMsg("---------\n")
	local nCount = nCount
	if #_Event_Trace < nCount then
		nCount = #_Event_Trace
	end
	for i = (#_Event_Trace) - nCount + 1, #_Event_Trace, 1 do
		LR.SysMsg(sformat("%s\n", _Event_Trace[i].szName))
	end
	LR.SysMsg("---------\n")
end

function Dbug.Debug(szText , szHeader , nLevel )
	if Dbug.Debug_enable then
		LR.Debug(szText , szHeader , nLevel)
	end
end

----------------------------------------------------------------
------类
----------------------------------------------------------------
local TRADE = {
	NONE = 0, 			---无
	TRADE = 1, 			---与玩家交易
	SHOP = 2, 			---NPC商店交易
	REPAIR = 3, 		---修理
	QUEST = 4, 		---任务获得
	GKP = 5, 			---GKP记录
	SHOP_BUY = 6, 	---商店购买
	SHOP_SELL = 7, 	---商店卖出
	DROP = 8, 			---丢弃
	RETURN = 9, 		---回购
	H_RETURN = 10, 	---高级回购
	LOOT = 11, 		---拾取
	LOOT_MONEY = 12, 	---拾取金钱
	AUCTION_SELL = 13, 	---交易行寄售
	AUCTION_BUY = 14, 	---交易行购买
	SHOP_RETURN = 15, 	---退货
	AUCTION_SUCCESS = 16, 	---寄卖成功
	GOLDTEAM = 17, 	--拍团交易
	MAIL_GET = 18, 		--邮件获得
	MAIL_SEND = 19, 		--邮件发送
	MAIL_PAY = 20, 		--付费取件
	GOLDTEAM_ADDMONEY = 21, 		--拍团添加工资
	FAN_PAI_JIANG_LI = 22,	--连续签到翻牌奖励
}

local TRADE_TEXT = {
	[TRADE.NONE] = _L["NONE"],
	[TRADE.TRADE] = _L["TRADE"],
	[TRADE.SHOP] = _L["SHOP"],
	[TRADE.REPAIR] = _L["REPAIR"],
	[TRADE.QUEST] = _L["QUEST"],
	[TRADE.GKP] = _L["GKP"],
	[TRADE.SHOP_BUY] = _L["SHOP_BUY"],
	[TRADE.SHOP_SELL] = _L["SHOP_SELL"],
	[TRADE.DROP] = _L["DROP"],
	[TRADE.RETURN] = _L["RETURN"],
	[TRADE.H_RETURN] = _L["H_RETURN"],
	[TRADE.LOOT] = _L["LOOT"],
	[TRADE.LOOT_MONEY] = _L["LOOT_MONEY"],
	[TRADE.AUCTION_SELL] = _L["AUCTION_SELL"],
	[TRADE.AUCTION_BUY] = _L["AUCTION_BUY"],
	[TRADE.SHOP_RETURN] = _L["SHOP_RETURN"],
	[TRADE.AUCTION_SUCCESS] = _L["AUCTION_SUCCESS"],
	[TRADE.GOLDTEAM] = _L["GOLDTEAM"],
	[TRADE.MAIL_GET] = _L["MAIL_GET"],
	[TRADE.MAIL_SEND] = _L["MAIL_SEND"],
	[TRADE.MAIL_PAY] = _L["MAIL_PAY"],
	[TRADE.GOLDTEAM_ADDMONEY] = _L["GOLDTEAM_ADDMONEY"],
	[TRADE.FAN_PAI_JIANG_LI] = _L["FAN_PAI_JIANG_LI"]
}

local DOODAD_TYPETEXT = {
	[DOODAD_KIND.CORPSE] = _L["D_CORPSE"],
	[DOODAD_KIND.QUEST] = _L["D_QUEST"],
	[DOODAD_KIND.TREASURE] = _L["D_TREASURE"],
}

local _WEEKDAY  = {
	[1] = _L["MON"],
	[2] = _L["TUE"],
	[3] = _L["WED"],
	[4] = _L["THU"],
	[5] = _L["FRI"],
	[6] = _L["SAT"],
	[0] = _L["SUN"],
}

local OP1 = {
	THIS_LOGIN = 1,
	TODAY = 2,
	LAST_SEVEN_DAYS = 3,
	THIS_WEEK = 4,
	THIS_MONTH = 5,
	HISTORY = 6,
}

local TEXT_OP1 = {
	[OP1.THIS_LOGIN] = _L["THIS_LOGIN"],
	[OP1.TODAY] = _L["TODAY"],
	[OP1.LAST_SEVEN_DAYS] = _L["LAST_SEVEN_DAYS"],
	[OP1.THIS_WEEK] = _L["THIS_WEEK"],
	[OP1.THIS_MONTH] = _L["THIS_MONTH"],
	[OP1.HISTORY] = _L["HISTORY"],
}

local bLoaded = {
	[OP1.THIS_LOGIN] = false,
	[OP1.TODAY] = false,
	[OP1.LAST_SEVEN_DAYS] = false,
	[OP1.THIS_WEEK] = false,
	[OP1.THIS_MONTH] = false,
	[OP1.HISTORY] = false,
}


local _Trade = {
	nTime = 0,
	OrderTime = 0,
	nMoney = 0,
	nItem_in = {},
	nItem_out = {},
	dwMapID = 0,
	nType = TRADE.NONE,
	Distributor = {
		nType = TARGET.NO_TARGET,
		dwID = 0,
		szName = "",
		szTitle = "",
		nCamp = nil,
		dwForceID = nil,
	},
	Source = {
		nType = TARGET.NO_TARGET,
		dwID = 0,
		szName = "",
		szTitle = "",
		nCamp = nil,
		dwForceID = nil,
	},
}
_Trade.__index = _Trade

function _Trade:new()
	local o = {
		nTime = 0,
		OrderTime = 0,
		nMoney = 0,
		nItem_in = {},
		nItem_out = {},
		dwMapID = 0,
		nType = TRADE.NONE,
		Distributor = {
			nType = TARGET.NO_TARGET,
			dwID = 0,
			szName = "",
			szTitle = "",
			nCamp = nil,
			dwForceID = nil,
		},
		Source = {
			nType = TARGET.NO_TARGET,
			dwID = 0,
			szName = "",
			szTitle = "",
			nCamp = nil,
			dwForceID = nil,
		},
	}
	setmetatable(o, self)
	return o
end

function _Trade:SetTime(nTime)
	if nTime then
		self.nTime = nTime
	else
		self.nTime = GetCurrentTime()
	end
	return self
end

function _Trade:GetTime()
	return self.nTime
end

function _Trade:SetOrderTime(nTime)
	if nTime then
		self.OrderTime = nTime
	else
		self.OrderTime = GetTime()
	end
	return self
end

function _Trade:GetOrderTime()
	return self.OrderTime
end

function _Trade:SetDistributorType(nType)
	self.Distributor.nType = nType
	return self
end

function _Trade:GetDistributorType()
	return self.Distributor.nType
end

function _Trade:SetDistributorID(dwID)
	self.Distributor.dwID = dwID
	return self
end

function _Trade:GetDistributorID()
	return self.Distributor.dwID
end

function _Trade:SetDistributorName(szName)
	self.Distributor.szName = szName or ""
	return self
end

function _Trade:GetDistributorName()
	return self.Distributor.szName
end

function _Trade:SetDistributorTitle(szTitle)
	self.Distributor.szTitle = szTitle or ""
	return self
end

function _Trade:GetDistributorTitle()
	return self.Distributor.szTitle
end

function _Trade:SetDistributorCamp(nCamp)
	self.Distributor.nCamp = nCamp
	return self
end

function _Trade:GetDistributorCamp()
	return self.Distributor.nCamp
end

function _Trade:SetDistributorForceID(dwForceID)
	self.Distributor.dwForceID = dwForceID
	return self
end

function _Trade:GetDistributorForce()
	return self.Distributor.dwForceID
end


function _Trade:SetDistributor(Distributor)
	self:SetDistributorType(Distributor.nType):SetDistributorID(Distributor.dwID):SetDistributorName(Distributor.szName):SetDistributorTitle(Distributor.szTitle)
	self:SetDistributorCamp(Distributor.nCamp):SetDistributorForceID(Distributor.dwForceID)
	return self
end

function _Trade:GetDistributor()
	return self.Distributor
end

function _Trade:SetSourceType(nType)
	self.Source.nType = nType
	return self
end

function _Trade:GetSourceType()
	return self.Source.nType
end

function _Trade:SetSourceID(dwID)
	self.Source.dwID = dwID
	return self
end

function _Trade:GetSourceID()
	return self.Source.dwID
end

function _Trade:SetSourceName(szName)
	self.Source.szName = szName or ""
	return self
end

function _Trade:GetSourceName()
	return self.Source.szName
end

function _Trade:SetSourceTitle(szTitle)
	self.Source.szTitle = szTitle
	return self
end

function _Trade:GetSourceTitle()
	return self.Source.szTitle
end

function _Trade:SetSourceCamp(nCamp)
	self.Source.nCamp = nCamp
	return self
end

function _Trade:GetSourceCamp()
	return self.Source.nCamp
end

function _Trade:SetSourceForceID(dwForceID)
	self.Source.dwForceID = dwForceID
	return self
end

function _Trade:GetSourceForceID()
	return self.Source.dwForceID
end

function _Trade:SetSource(Source)
	self:SetSourceType(Source.nType):SetSourceID(Source.dwID):SetSourceName(Source.szName):SetSourceTitle(Source.szTitle)
	self:SetSourceCamp(Source.nCamp):SetSourceForceID(Source.dwForceID)
	return self
end

function _Trade:GetSource()
	return self.Source
end

function _Trade:SetMapID(dwMapID)
	if dwMapID then
		self.dwMapID = dwMapID
	else
		local me = GetClientPlayer()
		if me then
			self.dwMapID = me.GetMapID()
		else
			self.dwMapID = 0
		end
	end
	return self
end

function _Trade:GetMapID()
	return self.dwMapID
end

function _Trade:SetMoney(nMoney)
	self.nMoney = self.nMoney+nMoney
	return self
end

function _Trade:AddMoney(nMoney)
	self.nMoney = self.nMoney+nMoney
	return self
end

function _Trade:GetMoney()
	return self.nMoney
end

function _Trade:SetItem_in(nItem)
	local nItem = nItem or {}
	self.nItem_in = clone(nItem)
	return self
end

function _Trade:AddItem_in(nItem)
	if type(nItem) ~=  "table" then
		return self
	end
	if next(nItem) ==  nil then
		return self
	end

	for n = 1, #nItem, 1 do
		local bAdd = true
		local t_nItem = self.nItem_in
		for i = 1, #t_nItem, 1 do
			if t_nItem[i].nVersion ==  nItem[n].nVersion and t_nItem[i].dwTabType ==  nItem[n].dwTabType and t_nItem[i].dwIndex ==  nItem[n].dwIndex and t_nItem[i].nBookID ==  nItem[n].nBookID then
				t_nItem[i].nStackNum = t_nItem[i].nStackNum + nItem[n].nStackNum
				bAdd = false
				return self
			end
		end
		if bAdd then
			t_nItem[#t_nItem+1] = {nVersion = nItem[n].nVersion, dwTabType = nItem[n].dwTabType, dwIndex = nItem[n].dwIndex, nStackNum = nItem[n].nStackNum, nBookID = nItem[n].nBookID, szName = nItem[n].szName}
		end
	end
	return self
end

function _Trade:GetItem_in()
	return self.nItem_in
end

function _Trade:SetItem_out(nItem)
	self.nItem_out = clone(nItem)
	return self
end

function _Trade:AddItem_out(nItem)
	if type(nItem) ~=  "table" then
		return self
	end
	if next(nItem) ==  nil then
		return self
	end

	for n = 1, #nItem, 1 do
		local bAdd = true
		local t_nItem = self.nItem_out
		for i = 1, #t_nItem, 1 do
			if t_nItem[i].nVersion ==  nItem[n].nVersion and t_nItem[i].dwTabType ==  nItem[n].dwTabType and t_nItem[i].dwIndex ==  nItem[n].dwIndex and t_nItem[i].nBookID ==  nItem[n].nBookID then
				t_nItem[i].nStackNum = t_nItem[i].nStackNum + nItem[n].nStackNum
				bAdd = false
			end
		end
		if bAdd then
			t_nItem[#t_nItem+1] = {nVersion = nItem[n].nVersion, dwTabType = nItem[n].dwTabType, dwIndex = nItem[n].dwIndex, nStackNum = nItem[n].nStackNum, nBookID = nItem[n].nBookID, szName = nItem[n].szName}
		end
	end
	return self
end

function _Trade:GetItem_out()
	return self.nItem_out
end

function _Trade:SetType(nType)
	self.nType = nType
	return self
end

function _Trade:GetType()
	return self.nType
end

function _Trade:SetDate(nTime)
	local tDate = {}
	if nTime then
		if type (nTime) ==  "number" then
			tDate = TimeToDate(nTime)
		elseif type (nTime) ==  "table" then
			tDate = clone(nTime)
		end
	else
		tDate = TimeToDate(self.nTime)
	end
	self.tDate = tDate
	return self
end

function _Trade:GetDate()
	return self.tDate
end

function _Trade:GetData()
	local data = {}
	data.nTime = self.nTime
	data.OrderTime = self.OrderTime
	data.nMoney = self.nMoney
	data.nItem_in = self.nItem_in
	data.nItem_out = self.nItem_out
	data.dwMapID = self.dwMapID
	data.nType = self.nType
	data.Distributor = self.Distributor
	data.Source = self.Source
	data.tDate = self.tDate
	return data
end

----------------------------------------------------------------
------保存
----------------------------------------------------------------
local _SaveTempDataTime = 0
function LR_AS_Trade.SaveTempData(bSaveImmediately)
	local _time = GetCurrentTime()
	----每5分钟缓存一次
	if _time - _SaveTempDataTime < 60 * 5 and not bSaveImmediately then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local szName = me.szName
	local path = sformat("%s\\TradeData\\%s\\%s\\%s\\TradeDB.db", SaveDataPath, realArea, realServer, szName)
	local DB = LR.OpenDB(path, "AS_TRADE_SAVE_TEMP_DATA_86B9CAF777543A467C77821DEF5D91AA")
	LR_AS_Trade.SaveTempData2(DB)
	LR.CloseDB(DB)
	_SaveTempDataTime = GetCurrentTime()
end

function LR_AS_Trade.SaveTempData2(DB)
	local data = clone(_2bSave)
	_2bSave = {}
	local DB_REPLACE = DB:Prepare("REPLACE INTO trade_data_temp ( szKey, nTime, OrderTime, nMoney, nItem_in, nItem_out, dwMapID, nType, Distributor, Source, tDate, nDate, bDel ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0 )")
	for k, v in pairs (data) do
		for k2, v2 in pairs (v) do
			local szKey = sformat("%d_%d", v2.nTime, v2.OrderTime)
			local _date = v2.tDate
			local year = _date.year
			local month = _date.month
			local day = _date.day
			local nDate = sformat("%04d-%02d-%02d", year, month, day)
			local nGoldBrick, nGold, nSilver, nCopper = LR.MoneyToGoldSilverAndCopper(v2.nMoney)
			local nMoney = {nGoldBrick = nGoldBrick, nGold = nGold, nSilver = nSilver, nCopper = nCopper}
			DB_REPLACE:ClearBindings()
			--Output(szKey, v2.nTime, v2.OrderTime, LR.JsonEncode(nMoney), LR.JsonEncode(v2.nItem_in or {}), LR.JsonEncode(v2.nItem_out or {}), v2.dwMapID, v2.nType, LR.JsonEncode(v2.Distributor or {}), LR.JsonEncode(v2.Source or {}), LR.JsonEncode(v2.tDate or {}), nDate, 0)
			DB_REPLACE:BindAll(unpack(g2d({szKey, v2.nTime, v2.OrderTime, LR.JsonEncode(nMoney), LR.JsonEncode(v2.nItem_in or {}), LR.JsonEncode(v2.nItem_out or {}), v2.dwMapID, v2.nType, LR.JsonEncode(v2.Distributor or {}), LR.JsonEncode(v2.Source or {}), LR.JsonEncode(v2.tDate or {}), nDate})))
			DB_REPLACE:Execute()
		end
	end
end

function LR_AS_Trade.MoveData2MainTable()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local szName = me.szName
	local path = sformat("%s\\TradeData\\%s\\%s\\%s\\TradeDB.db", SaveDataPath, realArea, realServer, szName)
	local DB = LR.OpenDB(path, "AS_TRADE_MOVE_TEMP_DATA_9C945166DC2179E258864DC4AD28C34A")
	LR_AS_Trade.SaveTempData2(DB)
	LR_AS_DB.MoveTradeDB(DB)
	DB:Execute("DROP TABLE trade_data_temp")
	LR.CloseDB(DB)
	LR_AS_DB.IniTradeDB()
end

function LR_AS_Trade.VacuumData()
	local vacuum = function()
		local me = GetClientPlayer()
		if not me then
			return
		end
		if IsRemotePlayer(me.dwID) then
			return
		end
		local serverInfo = {GetUserServer()}
		local realArea, realServer = serverInfo[5], serverInfo[6]
		local szName = me.szName
		local path = sformat("%s\\TradeData\\%s\\%s\\%s\\TradeDB.db", SaveDataPath, realArea, realServer, szName)
		local DB = LR.OpenDB(DB, "AS_TRADE_VACUUM_DATA_116F822102736954564DE4B8DAC08F46")
		local DB_DELETE = DB:Prepare("DELETE FROM trade_data WHERE bDel = 1")
		DB_DELETE:Execute()
		DB:Execute("END TRANSACTION")
		DB:Execute("VACUUM")
		DB:Execute("BEGIN TRANSACTION")
		LR.CloseDB(DB)
		LR.SysMsg(sformat("%s\n", _L["VACUUM Success!"]))
		LR.GreenAlert(sformat("%s\n", _L["VACUUM Success!"]))
	end

	local msg = {
		szMessage = _L["Are you sure to vacuum tradedata ?"],
		szName = "vacuum tradedata",
		fnAutoClose = function() return false end,
		{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() vacuum() end, },
		{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
	}
	MessageBox(msg)
end

function LR_AS_Trade.LoadData(nType, nPage)
	local nPage = nPage or 0
	local me = GetClientPlayer()
	if not me then
		return
	end
	local data = {}
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local szName = me.szName
	local path = sformat("%s\\TradeData\\%s\\%s\\%s\\TradeDB.db", SaveDataPath, realArea, realServer, szName)
	local DB = LR.OpenDB(path, "AS_TRADE_LOAD_DATA_D29E9166CAA75E3F535F3674BF091D81")
	local SQL, SQL2, SQL3 = "", "", ""
	if not nType or nType == OP1.TODAY then
		SQL = "SELECT * FROM trade_data WHERE bDel = 0 AND nDate = date('now', 'localtime') AND szKey IS NOT NULL ORDER BY nTime, OrderTime LIMIT 100 OFFSET ?"
		SQL3 = "SELECT * FROM trade_data WHERE bDel = 0 AND nDate = date('now', 'localtime') AND szKey IS NOT NULL ORDER BY nTime, OrderTime"
		SQL2 = "SELECT COUNT(*) AS COUNT FROM trade_data WHERE bDel = 0 AND nDate = date('now', 'localtime') AND szKey IS NOT NULL"
	elseif nType == OP1.LAST_SEVEN_DAYS then
		SQL = "SELECT * FROM trade_data WHERE bDel = 0 AND nDate > date('now', 'localtime', '-7 day') AND szKey IS NOT NULL ORDER BY nTime, OrderTime LIMIT 100 OFFSET ?"
		SQL3 = "SELECT * FROM trade_data WHERE bDel = 0 AND nDate > date('now', 'localtime', '-7 day') AND szKey IS NOT NULL ORDER BY nTime, OrderTime"
		SQL2 = "SELECT COUNT(*) AS COUNT FROM trade_data WHERE bDel = 0 AND nDate > date('now', 'localtime', '-7 day') AND szKey IS NOT NULL"
	elseif nType == OP1.THIS_MONTH then
		SQL = "SELECT * FROM trade_data WHERE bDel = 0 AND nDate >= date('now', 'localtime', 'start of month') AND szKey IS NOT NULL ORDER BY nTime, OrderTime LIMIT 100 OFFSET ?"
		SQL3 = "SELECT * FROM trade_data WHERE bDel = 0 AND nDate >= date('now', 'localtime', 'start of month') AND szKey IS NOT NULL ORDER BY nTime, OrderTime"
		SQL2 = "SELECT COUNT(*) AS COUNT FROM trade_data WHERE bDel = 0 AND nDate >= date('now', 'localtime', 'start of month') AND szKey IS NOT NULL"
	elseif nType == OP1.HISTORY then
		local start_time = sformat("%04d-%02d-%02d", LR_Acc_Trade_ChooseDate_Panel.start_year, LR_Acc_Trade_ChooseDate_Panel.start_month, LR_Acc_Trade_ChooseDate_Panel.start_day )
		local end_time = sformat("%04d-%02d-%02d", LR_Acc_Trade_ChooseDate_Panel.end_year, LR_Acc_Trade_ChooseDate_Panel.end_month, LR_Acc_Trade_ChooseDate_Panel.end_day )
		if start_time > end_time then
			local t = start_time
			start_time = end_time
			end_time = t
		end
		SQL = sformat("SELECT * FROM trade_data WHERE bDel = 0 AND nDate BETWEEN '%s' AND '%s' AND szKey IS NOT NULL ORDER BY nTime, OrderTime LIMIT 100 OFFSET ?", start_time, end_time)
		SQL3 = sformat("SELECT * FROM trade_data WHERE bDel = 0 AND nDate BETWEEN '%s' AND '%s' AND szKey IS NOT NULL ORDER BY nTime, OrderTime", start_time, end_time)
		SQL2 = sformat("SELECT COUNT(*) AS COUNT FROM trade_data WHERE bDel = 0 AND szKey IS NOT NULL AND nDate BETWEEN '%s' AND '%s'", start_time, end_time)
	elseif nType == OP1.THIS_WEEK then
		local _now = GetCurrentTime()
		local _date = TimeToDate(_now)
		local weekday = _date.weekday
		if weekday ==0 then
			weekday = 7
		end
		SQL = sformat("SELECT * FROM trade_data WHERE bDel = 0 AND nDate > date('now', 'localtime', '-%d day') AND szKey IS NOT NULL ORDER BY nTime, OrderTime LIMIT 100 OFFSET ?", weekday)
		SQL3 = sformat("SELECT * FROM trade_data WHERE bDel = 0 AND nDate > date('now', 'localtime', '-%d day') AND szKey IS NOT NULL ORDER BY nTime, OrderTime", weekday)
		SQL2 = sformat("SELECT COUNT(*) AS COUNT FROM trade_data WHERE bDel = 0 AND szKey IS NOT NULL AND nDate > date('now', 'localtime', '-%d day')", weekday)
	end
	local DB_SELECT2 = DB:Prepare(SQL2)
	local data2 = d2g(DB_SELECT2:GetAll())
	nPage = mmax(nPage, 1)
	LR_Acc_Trade_Panel.nCount = data2[1].COUNT
	LR_Acc_Trade_Panel.nTotalPage = mfloor((LR_Acc_Trade_Panel.nCount - 1)/100) + 1
	LR_Acc_Trade_Panel.nLastPage = LR_Acc_Trade_Panel.nTotalPage
	LR_Acc_Trade_Panel.nPage = mmin(nPage, LR_Acc_Trade_Panel.nTotalPage)
	LR_Acc_Trade_Panel.nPrePage = mmax((LR_Acc_Trade_Panel.nPage - 1), 1)
	LR_Acc_Trade_Panel.nNextPage = mmin((LR_Acc_Trade_Panel.nPage + 1), LR_Acc_Trade_Panel.nTotalPage)
	local DB_SELECT, data
	if LR_Acc_Trade_Panel.notByPage then
		DB_SELECT = DB:Prepare(SQL3)
		data = d2g(DB_SELECT:GetAll())
	else
		DB_SELECT = DB:Prepare(SQL)
		DB_SELECT:ClearBindings()
		DB_SELECT:BindAll((nPage - 1) * 100)
		data = d2g(DB_SELECT:GetAll())
	end
	LR.CloseDB(DB)

	local Trade_LIst = LR_AS_Trade.Trade_LIst
	local index = LR_AS_Trade.index
	_History = {}
	_Today = {}
	_This_Week = {}
	_This_Month = {}
	_Last_Seven_Days = {}

	for k, v in pairs(data) do
		--加入记录 Trade_LIst为所有的记录内容
		local nTime = v.nTime
		local OrderTime = v.OrderTime
		local key1 = sformat("%d_%d", nTime, OrderTime)
		local nMoney2 = LR.JsonDecode(v.nMoney)
		local nMoney = nMoney2.nCopper + nMoney2.nSilver * 100 + nMoney2.nGold * 10000 + nMoney2. nGoldBrick * 100000000

		Trade_LIst[key1] = _Trade:new()
		Trade_LIst[key1]:SetMapID(v.dwMapID):SetMoney(nMoney):SetTime(nTime):SetOrderTime(OrderTime):SetType(v.nType)
		Trade_LIst[key1]:SetDistributor(LR.JsonDecode(v.Distributor)):SetSource(LR.JsonDecode(v.Source)):AddItem_in(LR.JsonDecode(v.nItem_in)):AddItem_out(LR.JsonDecode(v.nItem_out))
		Trade_LIst[key1]:SetDate(LR.JsonDecode(v.tDate))

		if not nType or nType == OP1.TODAY then
			_Today[#_Today+1] = {nTime = nTime, OrderTime = OrderTime, }
		elseif nType == OP1.THIS_WEEK then
			_This_Week[#_This_Week+1] = {nTime = nTime, OrderTime = OrderTime, }
		elseif nType == OP1.THIS_MONTH then
			_This_Month[#_This_Month+1] = {nTime = nTime, OrderTime = OrderTime, }
		elseif nType == OP1.LAST_SEVEN_DAYS then
			_Last_Seven_Days[#_Last_Seven_Days+1] = {nTime = nTime, OrderTime = OrderTime, }
		elseif nType == OP1.HISTORY then
			_History[#_History+1] = {nTime = nTime, OrderTime = OrderTime, }
		end
	end

end

function LR_AS_Trade.Convert2_1d1(data)
	local me = GetClientPlayer()
	if not me then
		return {}
	end
	local data = data
	local t = {}
	for i = 1, #data, 1 do
		if type(data[i]) == "table" then
			t[#t+1] = data[i]
			local _date = TimeToDate(data[i].nTime)
			t[#t].tDate = _date
		end
	end
	t.szName = me.szName
	t.nType = "LR_Trade_List"
	t.Version = "1.1"
	return t
end

function LR_AS_Trade.ImportOldData()
	local me = GetClientPlayer()
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local szName = me.szName
	if LR_AS_Trade.ImportOldData2(realArea, realServer, szName) then
		LR.SysMsg(sformat("%s\n", _L["Import success"]))
		LR.GreenAlert(sformat("%s\n", _L["Import success"]))
	end
end


function LR_AS_Trade.ImportOldData2(realArea, realServer, szName)
	local me = GetClientPlayer()
	if IsRemotePlayer(me.dwID) then
		LR.SysMsg(sformat("%s\n", _L["Can not import data in current status."]))
		LR.RedAlert(sformat("%s\n", _L["Can not import data in current status."]))
		return false
	end
	local src = "%s\\%s\\%s\\%s\\Trade\\Data_%s\\Record_%s_%s.dat"
	local path = sformat("%s\\TradeData\\%s\\%s\\%s\\TradeDB.db", SaveDataPath, realArea, realServer, szName)
	LR_AS_DB.IniTradeDB(realArea, realServer, szName)
	local DB = LR.OpenDB(path, "AS_TRADE_IMPORT_DATA2_4F5345F8597C42EA9D982B07CC26910D")
	local DB_REPLACE = DB:Prepare("REPLACE INTO trade_data ( szKey, nTime, OrderTime, nMoney, nItem_in, nItem_out, dwMapID, nType, Distributor, Source, tDate, nDate, bDel ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0 )")
	for month = 3, 4, 1 do
		local src2 = "%s\\%s\\%s\\%s\\Trade\\Record_%s_%s.dat"
		local path = sformat(src2, SaveDataPath, realArea, realServer, szName, sformat("%04d_%02d", 2016, month), szName)
		local data = LoadLUAData(path) or {}
		for k, v in pairs (data) do
			if type(v) == "table" then
				local szKey = sformat("%d_%d", v.nTime, v.OrderTime)
				local tDate = TimeToDate(v.nTime)
				local _date = tDate
				local year = _date.year
				local month = _date.month
				local day = _date.day
				local nDate = sformat("%04d-%02d-%02d", year, month, day)
				local nGoldBrick, nGold, nSilver, nCopper = LR.MoneyToGoldSilverAndCopper(v.nMoney)
				local nMoney = {nGoldBrick = nGoldBrick, nGold = nGold, nSilver = nSilver, nCopper = nCopper}
				DB_REPLACE:ClearBindings()
				--Output(szKey, v2.nTime, v2.OrderTime, LR.JsonEncode(nMoney), LR.JsonEncode(v2.nItem_in or {}), LR.JsonEncode(v2.nItem_out or {}), v2.dwMapID, v2.nType, LR.JsonEncode(v2.Distributor or {}), LR.JsonEncode(v2.Source or {}), LR.JsonEncode(v2.tDate or {}), nDate, 0)
				DB_REPLACE:BindAll(unpack(g2d({szKey, v.nTime, v.OrderTime, LR.JsonEncode(nMoney), LR.JsonEncode(v.nItem_in or {}), LR.JsonEncode(v.nItem_out or {}), v.dwMapID, v.nType, LR.JsonEncode(v.Distributor or {}), LR.JsonEncode(v.Source or {}), LR.JsonEncode(tDate), nDate})))
				DB_REPLACE:Execute()
			end
		end
	end
	for year = 2016, 2017, 1 do
		for month = 1, 12, 1 do
			for day = 1, 31, 1 do
				local path = sformat(src, SaveDataPath, realArea, realServer, szName, sformat("%04d_%02d", year, month), sformat("%04d_%02d_%02d", year, month, day), szName)
				local data = LoadLUAData(path) or {}
				for k, v in pairs (data) do
					if type(v) == "table" then
						local szKey = sformat("%d_%d", v.nTime, v.OrderTime)
						local _date = v.tDate
						local year = _date.year
						local month = _date.month
						local day = _date.day
						local nDate = sformat("%04d-%02d-%02d", year, month, day)
						local nGoldBrick, nGold, nSilver, nCopper = LR.MoneyToGoldSilverAndCopper(v.nMoney)
						local nMoney = {nGoldBrick = nGoldBrick, nGold = nGold, nSilver = nSilver, nCopper = nCopper}
						DB_REPLACE:ClearBindings()
						--Output(szKey, v2.nTime, v2.OrderTime, LR.JsonEncode(nMoney), LR.JsonEncode(v2.nItem_in or {}), LR.JsonEncode(v2.nItem_out or {}), v2.dwMapID, v2.nType, LR.JsonEncode(v2.Distributor or {}), LR.JsonEncode(v2.Source or {}), LR.JsonEncode(v2.tDate or {}), nDate, 0)
						DB_REPLACE:BindAll(unpack(g2d({szKey, v.nTime, v.OrderTime, LR.JsonEncode(nMoney), LR.JsonEncode(v.nItem_in or {}), LR.JsonEncode(v.nItem_out or {}), v.dwMapID, v.nType, LR.JsonEncode(v.Distributor or {}), LR.JsonEncode(v.Source or {}), LR.JsonEncode(v.tDate or {}), nDate})))
						DB_REPLACE:Execute()
					end
				end
			end
		end
	end
	LR.CloseDB(DB)
	return true
end

function LR_AS_Trade.BatchImportOldData()
	local batch_import = function ()
		local t = GetTickCount()
		local AllUsrList = clone(LR_AS_Info.AllUsrList)
		for szKey, v in pairs (AllUsrList) do
			local realArea = v.realArea
			local realServer = v.realServer
			local szName = v.szName
			LR_AS_Trade.ImportOldData2(realArea, realServer, szName)
		end
		local cost = ( GetTickCount() - t ) * 1.0 / 1000
		LR.SysMsg(sformat(_L["Cost %0.3f s.\n"], cost))
		LR.GreenAlert(sformat(_L["Cost %0.3f s.\n"], cost))
	end

	local msg = {
		szMessage = _L["Are you sure to patch import data (database version) ?"],
		szName = "patch import old version",
		fnAutoClose = function() return false end,
		{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() batch_import() end, },
		{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
	}
	MessageBox(msg)
end


function LR_AS_Trade.ImportNewVersionData()
	local me = GetClientPlayer()
	if IsRemotePlayer(me.dwID) then
		LR.SysMsg(sformat("%s\n", _L["Can not import data in current status."]))
		LR.RedAlert(sformat("%s\n", _L["Can not import data in current status."]))
		return
	end
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local filepath = sformat(_L["file locate at 'Interface/LR_Plugin@Data/LR_AccountStatistics/UsrData/TradeData/[Area]/[Server]/[PlayerName]'"])
	local step_3 = function(szFile)
		local path = szFile
		local DB = LR.OpenDB(path, "AS_TRADE_LOAD_OLD_VERSION_DATA_984684081279407503BCA422E48BA1AC")
		DB_SELECT = DB:Prepare("SELECT * FROM trade_data WHERE bDel = 0 AND szKey IS NOT NULL")
		local Data = d2g(DB_SELECT:GetAll())
		LR.CloseDB(DB)

		local me = GetClientPlayer()
		local serverInfo = {GetUserServer()}
		local realArea, realServer = serverInfo[5], serverInfo[6]
		local szName = me.szName
		local path2 = sformat("%s\\TradeData\\%s\\%s\\%s\\TradeDB.db", SaveDataPath, realArea, realServer, szName)
		local DB2 = LR.OpenDB(path2, "AS_TRADE_IMPORT_NEW_VERSION_DATA_1ED0C5B68C340B819AC6A77F3DAB91EA")
		local DB_REPLACE = DB2:Prepare("REPLACE INTO trade_data ( szKey, nTime, OrderTime, nMoney, nItem_in, nItem_out, dwMapID, nType, Distributor, Source, tDate, nDate, bDel ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0 )")
		for k, v in pairs (Data) do
			DB_REPLACE:ClearBindings()
			DB_REPLACE:BindAll(unpack(g2d({v.szKey, v.nTime, v.OrderTime, v.nMoney, v.nItem_in, v.nItem_out, v.dwMapID, v.nType, v.Distributor, v.Source, v.tDate, v.nDate})))
			DB_REPLACE:Execute()
		end
		LR.CloseDB(DB2)
		LR.SysMsg(sformat("%s\n", _L["Import success"]))
		LR.GreenAlert(sformat("%s\n", _L["Import success"]))
	end

	local step_2 = function()
		local szFile = GetOpenFileName(sformat("%s ( %s )", _L["Choose file"], filepath), "Trade data File(*.db)\0*.db\0All Files(*.*)\0*.*\0")
		if szFile == "" then
			return
		else
			local _s1, _e1, _area, _server, _szName = sfind(slower(szFile), "interface\\lr_plugin@data\\lr_accountstatistics\\usrdata\\tradedata\\(.-)\\(.-)\\(.-)\\")
			if not _s1 then
				LR.SysMsg(sformat("%s\n", _L["File path wrong."]))
				LR.RedAlert(sformat("%s\n", _L["File path wrong."]))
				return
			end
			local _s, _e = sfind(slower(szFile), "tradedb.db")
			if not _s then
				LR.SysMsg(sformat("%s\n", _L["File name wrong."]))
				LR.RedAlert(sformat("%s\n", _L["File name wrong."]))
				return
			end
		end
		local DB = LR.OpenDB(szFile, "AS_TRADE_CHECK_OLD_VERSION_DATA_E7F21CAEA685ED25B933D5F8A2592E10")
		local DB_SELECT = DB:Prepare("SELECT * FROM sqlite_master WHERE type = 'table' AND name ='trade_data'")
		if not DB_SELECT then
			LR.SysMsg(sformat("%s\n", _L["File open error."]))
			LR.RedAlert(sformat("%s\n", _L["File open error."]))
			LR.CloseDB(DB)
			return
		end
		local data = d2g(DB_SELECT:GetAll())
		LR.CloseDB(DB)
		if next(data) == nil then
			LR.SysMsg(sformat("%s\n", _L["File open error."]))
			LR.RedAlert(sformat("%s\n", _L["File open error."]))
		else
			local _s1, _e1, _area, _server, _szName = sfind(slower(szFile), "interface\\lr_plugin@data\\lr_accountstatistics\\usrdata\\tradedata\\(.-)\\(.-)\\(.-)\\tradedb.db")
			local msg = {
				szMessage = sformat(_L["File correct, sure to import?\nArea: %s , Server: %s , Name: %s"], _area, _server, _szName),
				szName = "file correct",
				fnAutoClose = function() return false end,
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() step_3(szFile) end, },
				{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
			}
			MessageBox(msg)
		end
	end

	local step_1 = function()
		local msg = {
			szMessage = filepath,
			szName = "file path",
			fnAutoClose = function() return false end,
			{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() step_2() end, },
			{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
		}
		MessageBox(msg)
	end

	local msg = {
		szMessage = _L["Are you sure to import new version data (database version) ?"],
		szName = "import new version",
		fnAutoClose = function() return false end,
		{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() step_1() end, },
		{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
	}
	MessageBox(msg)
end

----------------------------------------------------------------
------事件处理
----------------------------------------------------------------
function LR_AS_Trade.GetTargetInfo()
	local info = {
		szName = "",
		szTitle = "",
		dwID = 0,
		nType = TARGET.NO_TARGET,
	}
	local me = GetClientPlayer()
	if not me then
		return info
	end
	local _type, _dwID = me.GetTarget()
	local target
	if _type == TARGET.NPC then
		target = GetNpc(_dwID)
		info.szTitle = target.szTitle
	elseif _type == TARGET.PLAYER then
		target = GetPlayer(_dwID)
		info.szTitle = target.szTitle
	elseif _type == TARGET.NO_TARGET then
		return info
	elseif _type == TARGET.DOODAD then
		target = GetDoodad(_dwID)
	end
	info.szName = LR.Trim(target.szName)
	info.dwID = target.dwID
	info.nType = _type

	return info
end

function LR_AS_Trade.OpenShop()
	local Shop = LR_AS_Trade.Shop
	Shop.dwShopID = arg0
	Shop.nShopType = arg1
	Shop.dwValidPage = arg2
	Shop.bCanRepair = arg3
	Shop.dwNpcID = arg4
end

function LR_AS_Trade.BAG_ITEM_UPDATE()
	local dwBoxIndex = arg0
	local dwX = arg1
	if LR_AS_Trade.Mail_Flag then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local item = me.GetItem(dwBoxIndex, dwX)
	if item then
		Dbug.Debug("BAG_ITEM_UPDATE_HAVE")
		local _Event = {}
		_Event.szName = "BAG_ITEM_UPDATE_HAVE"
		_Event.Obj = _Trade:new()
		_Event.Obj:SetTime():SetOrderTime():SetMapID()

		local nStackNum = 1
		if item.bCanStack then
			nStackNum = item.nStackNum
		end
		local nBookID = 0
		if item.nGenre ==  ITEM_GENRE.BOOK then
			nBookID = item.nBookID
		end

		_Event.Obj:AddItem_in({{nVersion = item.nVersion, dwTabType = item.dwTabType, dwIndex = item.dwIndex, nStackNum = nStackNum, nBookID = nBookID}})
		_Event_Trace[#_Event_Trace+1] = _Event
	else
		Dbug.Debug("BAG_ITEM_UPDATE_NONE")
		local _Event = {}
		_Event.szName = "BAG_ITEM_UPDATE_NONE"

		_Event_Trace[#_Event_Trace+1] = _Event
	end

	local AuctionPanel = Station.Lookup("Normal/AuctionPanel")
	if AuctionPanel then
		if _Event_Trace[#_Event_Trace].szName ==  "BAG_ITEM_UPDATE_HAVE" then
			LR_AS_Trade.GetItemInBag()
		end
		_Event_Trace[#_Event_Trace].dwBoxIndex = dwBoxIndex
		_Event_Trace[#_Event_Trace].dwX = dwX
	end

	if _Event_Trace[#_Event_Trace].szName ==  "BAG_ITEM_UPDATE_HAVE" then
		if #_Event_Trace>= 2 then
			if  _Event_Trace[#_Event_Trace-1].szName ==  "SOLD_ITEM_UPDATE_NONE" or _Event_Trace[#_Event_Trace-1].szName ==  "TIME_LIMIT_SOLD_ITEM_UPDATE_NONE" then
				local Obj_item_in = _Event_Trace[#_Event_Trace].Obj
				local Temp_Record = _Trade:new()
				Temp_Record:SetTime():SetOrderTime():SetMapID()
				Temp_Record:AddItem_in(Obj_item_in:GetItem_in())
				if _Event_Trace[#_Event_Trace-1].szName ==  "SOLD_ITEM_UPDATE_NONE" then
					Temp_Record:SetType(TRADE.RETURN)
				elseif _Event_Trace[#_Event_Trace-1].szName ==  "TIME_LIMIT_SOLD_ITEM_UPDATE_NONE" then
					Temp_Record:SetType(TRADE.H_RETURN)
				end

				local Shop = LR_AS_Trade.Shop
				local dwNpcID = Shop.dwNpcID
				local npc = GetNpc(dwNpcID)
				if npc then
					local szName = LR.Trim(npc.szName)
					if szName ==  "" then
						szName = LR.Trim(Table_GetNpcTemplateName(npc.dwTemplateID))
					end
					local Source = {dwID = dwID, szName = szName, szTitle = LR.Trim(npc.szTitle), nType = TARGET.NPC, nCamp = nil, dwForceID = nil, }
					Temp_Record:SetSource(Source)
				end

				LR_AS_Trade.AddRecord(Temp_Record)
				if Temp_Record:GetType() ==  TRADE.RETURN then
					_Event_Trace[#_Event_Trace+1] = {szName = "SOLD_ITEM_UPDATE_NONE"}
				elseif Temp_Record:GetType() ==  TRADE.H_RETURN then
					_Event_Trace[#_Event_Trace+1] = {szName = "TIME_LIMIT_SOLD_ITEM_UPDATE_NONE"}
				end
				_Event_Trace[#_Event_Trace+1] = {szName = "BAG_ITEM_UPDATE_HAVE"}
			end
		end
	end
end

function LR_AS_Trade.SOLD_ITEM_UPDATE()
	local dwBoxIndex = arg0
	local dwX = arg1
	local me = GetClientPlayer()
	if not me then
		return
	end

	local item = me.GetItem(dwBoxIndex, dwX)

	if item then
		Dbug.Debug("SOLD_ITEM_UPDATE_HAVE")
		local _Event = {}
		_Event.szName = "SOLD_ITEM_UPDATE_HAVE"
		_Event.Obj = _Trade:new()
		_Event.Obj:SetTime():SetOrderTime():SetMapID()

		local nStackNum = 1
		if item.bCanStack then
			nStackNum = item.nStackNum
		end
		local nBookID = 0
		if item.nGenre ==  ITEM_GENRE.BOOK then
			nBookID = item.nBookID
		end

		_Event.Obj:AddItem_out({{nVersion = item.nVersion, dwTabType = item.dwTabType, dwIndex = item.dwIndex, nStackNum = nStackNum, nBookID = nBookID}})
		_Event_Trace[#_Event_Trace+1] = _Event
	else
		Dbug.Debug("SOLD_ITEM_UPDATE_NONE")
		local _Event = {}
		_Event.szName = "SOLD_ITEM_UPDATE_NONE"

		_Event_Trace[#_Event_Trace+1] = _Event
	end
end

function LR_AS_Trade.TIME_LIMIT_SOLD_ITEM_UPDATE()
	local dwBoxIndex = arg0
	local dwX = arg1
	local me = GetClientPlayer()
	if not me then
		return
	end

	local item = me.GetItem(dwBoxIndex, dwX)

	if item then
		Dbug.Debug("TIME_LIMIT_SOLD_ITEM_UPDATE_HAVE")
		local _Event = {}
		_Event.szName = "TIME_LIMIT_SOLD_ITEM_UPDATE_HAVE"
		_Event.Obj = _Trade:new()
		_Event.Obj:SetTime():SetOrderTime():SetMapID()

		local nStackNum = 1
		if item.bCanStack then
			nStackNum = item.nStackNum
		end
		local nBookID = 0
		if item.nGenre ==  ITEM_GENRE.BOOK then
			nBookID = item.nBookID
		end

		_Event.Obj:AddItem_out({{nVersion = item.nVersion, dwTabType = item.dwTabType, dwIndex = item.dwIndex, nStackNum = nStackNum, nBookID = nBookID}})
		_Event_Trace[#_Event_Trace+1] = _Event
	else
		Dbug.Debug("TIME_LIMIT_SOLD_ITEM_UPDATE_NONE")
		local _Event = {}
		_Event.szName = "TIME_LIMIT_SOLD_ITEM_UPDATE_NONE"

		_Event_Trace[#_Event_Trace+1] = _Event
	end
end

function LR_AS_Trade.DESTROY_ITEM()
	local dwBoxIndex = arg0
	local dwX = arg1
	local nVersion = arg2
	local dwTabType = arg3
	local dwIndex = arg4

	local iteminfo = GetItemInfo(dwTabType, dwIndex)
	local nTime = GetCurrentTime()
	local OrderTime = GetTime()

	local me = GetClientPlayer()
	if not me then
		return
	end

	if iteminfo then
		Dbug.Debug("DESTROY_ITEM")
		if dwBoxIndex<= 6 then
			local _Event = {}
			_Event.szName = "DESTROY_ITEM"
			_Event.Obj = _Trade:new()
			_Event.Obj:SetTime():SetOrderTime():SetMapID()

			local key = sformat("%d_%d", dwBoxIndex, dwX)
			if LR_AS_Trade.Tradeing_Bag[key] then
				local _item = LR_AS_Trade.Tradeing_Bag[key]
				_Event.Obj:AddItem_out({{nVersion = _item.nVersion, dwTabType = _item.dwTabType, dwIndex = _item.dwIndex, nStackNum = _item.nStackNum, nBookID = _item.nBookID}})
			end

			_Event_Trace[#_Event_Trace+1] = _Event
		end
	end
end

function LR_AS_Trade.MONEY_UPDATE()
	if LR_AS_Trade.Mail_Flag then
		return
	end
	local nGold = arg0
	local nSilver = arg1
	local nCopper = arg2
	local bShowMsg = arg3
	local dwTargetID = arg4
	local nTime = GetCurrentTime()
	local OrderTime = GetTime()
	local nMoney = {
		nGold = nGold,
		nSilver = nSilver,
		nCopper = nCopper,
	}
	local nMoney2 = nMoney.nGold*10000+nMoney.nSilver*100+nMoney.nCopper

	Dbug.Debug("MONEY_UPDATE")
	local _Event = {}
	_Event.szName = "MONEY_UPDATE"
	_Event.Obj = _Trade:new()
	_Event.Obj:SetTime():SetOrderTime():SetMapID()
	_Event.Obj:AddMoney(nMoney2)

	_Event_Trace[#_Event_Trace+1] = _Event

	if _Event_Trace[#_Event_Trace].szName ==  "MONEY_UPDATE" then
		if #_Event_Trace>= 3 then
			if _Event_Trace[#_Event_Trace-1].szName ==  "BAG_ITEM_UPDATE_HAVE"
			and (_Event_Trace[#_Event_Trace-2].szName ==  "SOLD_ITEM_UPDATE_NONE"
			or _Event_Trace[#_Event_Trace-2].szName ==  "TIME_LIMIT_SOLD_ITEM_UPDATE_NONE")
			then
				local Obj_money = _Event_Trace[#_Event_Trace].Obj
				local Temp_Record = _Trade:new()
				Temp_Record:SetTime():SetOrderTime():SetMapID()
				Temp_Record:AddMoney(Obj_money:GetMoney())
				if _Event_Trace[#_Event_Trace-2].szName ==  "SOLD_ITEM_UPDATE_NONE" then
					Temp_Record:SetType(TRADE.RETURN)
				elseif _Event_Trace[#_Event_Trace-2].szName ==  "TIME_LIMIT_SOLD_ITEM_UPDATE_NONE" then
					Temp_Record:SetType(TRADE.H_RETURN)
				end

				local Shop = LR_AS_Trade.Shop
				local dwNpcID = Shop.dwNpcID
				local npc = GetNpc(dwNpcID)
				if npc then
					local szName = LR.Trim(npc.szName)
					if szName ==  "" then
						szName = LR.Trim(Table_GetNpcTemplateName(npc.dwTemplateID))
					end
					local Source = {dwID = dwID, szName = szName, szTitle = LR.Trim(npc.szTitle), nType = TARGET.NPC, nCamp = nil, dwForceID = nil, }
					Temp_Record:SetSource(Source)
				end

				LR_AS_Trade.AddRecord(Temp_Record)
			end
		elseif #_Event_Trace>= 2 then
			if nMoney2 > 0 then
				if _Event_Trace[#_Event_Trace-1].szName ==  "OPEN_DOODAD" then
					if GetTime() - _Event_Trace[#_Event_Trace-1].Obj:GetOrderTime() < 30000 then
						local Obj_money = _Event_Trace[#_Event_Trace].Obj
						local Temp_Record = _Trade:new()
						Temp_Record:SetTime():SetOrderTime():SetMapID()
						Temp_Record:AddMoney(Obj_money:GetMoney())
						Temp_Record:SetType(TRADE.LOOT_MONEY)

						if _Doodad_item["money"] then
							local _items = _Doodad_item["money"]
							local doodad = _items[#_items].doodad
							if doodad then
								local Source = {dwID = doodad.dwID, szName = LR.Trim(doodad.szName), szTitle = doodad.nKind, nType = TARGET.DOODAD, nCamp = nil, dwForceID = nil, }
								Temp_Record:SetSource(Source)
								_items[#_items] = nil
							end
						end

						LR_AS_Trade.AddRecord(Temp_Record)
					end
				end
			end
		end
		if nMoney2 >0 and _GoldTeam.bOn then
			LR.DelayCall(100, function() LR_AS_Trade.CheckGoldTeam(_Event.Obj) end)
		end
	end
end

function LR_AS_Trade.TRADING_OPEN_NOTIFY()
	local dwID = arg0
	LR_AS_Trade.Tradeing_TarID = dwID

	Dbug.Debug("TRADING_OPEN_NOTIFY")
	local _Event = {}
	_Event.szName = "TRADING_OPEN_NOTIFY"

	_Event_Trace[#_Event_Trace+1] = _Event
end

function LR_AS_Trade.TRADING_UPDATE_ITEM()
	local dwCharacterID = arg0
	local dwBoxIndex = arg1
	local dX = arg2
	local dwGridIndex = arg3

	local me = GetClientPlayer()
	if not me then
		return
	end

	if dwCharacterID ~=  me.dwID then
		return
	end

	local item = me.GetItem(dwBoxIndex, dX)
	if item then
		local nStackNum = 1
		if item.bCanStack then
			nStackNum = item.nStackNum
		end
		local nBookID = 0
		if item.nGenre ==  ITEM_GENRE.BOOK then
			nBookID = item.nBookID
		end
		LR_AS_Trade.Tradeing_Bag[sformat("%d_%d", dwBoxIndex, dX)] = {nVersion = item.nVersion, dwTabType = item.dwTabType, dwIndex = item.dwIndex, nStackNum = nStackNum, nBookID = nBookID}
	end
end

function LR_AS_Trade.TRADING_UPDATE_CONFIRM()
	Dbug.Debug("TRADING_UPDATE_CONFIRM")
	local _Event = {}
	_Event.szName = "TRADING_UPDATE_CONFIRM"
	_Event_Trace[#_Event_Trace+1] = _Event

	LR_AS_Trade.Tradeing_Flag = LR_AS_Trade.Tradeing_Flag+1
end

function LR_AS_Trade.TRADING_CLOSE()
	Dbug.Debug("TRADING_CLOSE")
	local _Event = {}
	_Event.szName = "TRADING_CLOSE"
	_Event_Trace[#_Event_Trace+1] = _Event
end

function LR_AS_Trade.SYS_MSG()
	if not (arg0 == "UI_OME_SHOP_RESPOND" or arg0 == "UI_OME_TRADING_RESPOND" or arg0 == "UI_OME_LOOT_RESPOND") then
		return
	end
	if arg0 == "UI_OME_SHOP_RESPOND" then
		Dbug.Debug(arg1)
		Dbug.Debug(g_tStrings.g_ShopStrings[arg1])
		if arg1 == 1 then	----商店出售物品
			Dbug.Debug("UI_OME_SHOP_RESPOND_1")
			local _Event = {}
			_Event.szName = "UI_OME_SHOP_RESPOND_1"
			_Event_Trace[#_Event_Trace+1] = _Event
		elseif arg1 == 2 then	----商店购买物品
			Dbug.Debug("UI_OME_SHOP_RESPOND_2")
			local _Event = {}
			_Event.szName = "UI_OME_SHOP_RESPOND_2"
			_Event_Trace[#_Event_Trace+1] = _Event
		elseif arg1 == 3 then		-----修理物品成功	arg1 = 4:帮会资金修理成功
			Dbug.Debug("UI_OME_SHOP_RESPOND_3")
			local _Event = {}
			_Event.szName = "UI_OME_SHOP_RESPOND_3"
			_Event_Trace[#_Event_Trace+1] = _Event
		elseif arg1 == 5 then		-----退货成功
			Dbug.Debug("UI_OME_SHOP_RESPOND_5")
			local _Event = {}
			_Event.szName = "UI_OME_SHOP_RESPOND_5"
			_Event_Trace[#_Event_Trace+1] = _Event
		end
	elseif arg0 == "UI_OME_TRADING_RESPOND" then
		Dbug.Debug(arg1)
		Dbug.Debug(g_tStrings.tTradingResultString[arg1])
		if arg1 == 1 then	--交易成功
			Dbug.Debug("UI_OME_TRADING_RESPOND_1")
			local _Event = {}
			_Event.szName = "UI_OME_TRADING_RESPOND_1"
			_Event_Trace[#_Event_Trace+1] = _Event
		end
	elseif arg0 == "UI_OME_LOOT_RESPOND" then
		Dbug.Debug(arg1)
		Dbug.Debug(g_tStrings.tLootResult[arg1])
	end

	if arg0 == "UI_OME_SHOP_RESPOND" or arg0 == "UI_OME_TRADING_RESPOND" or arg0 == "UI_OME_LOOT_RESPOND" then
		if _Event_Trace[#_Event_Trace].szName ==  "UI_OME_SHOP_RESPOND_1" then	----出售物品成功
			local bAdd = false
			local Obj_item_out = nil
			local Obj_money = nil
			if #_Event_Trace>= 4 then
				if _Event_Trace[#_Event_Trace-1].szName ==  "MONEY_UPDATE"
				and ( _Event_Trace[#_Event_Trace-2].szName ==  "TIME_LIMIT_SOLD_ITEM_UPDATE_HAVE" or _Event_Trace[#_Event_Trace-2].szName ==  "SOLD_ITEM_UPDATE_HAVE" )
				and _Event_Trace[#_Event_Trace-3].szName ==  "BAG_ITEM_UPDATE_NONE"
				then		------出售成功
					bAdd = true
					Obj_item_out =  _Event_Trace[#_Event_Trace-2].Obj
					Obj_money = _Event_Trace[#_Event_Trace-1].Obj
				end
			end
			if #_Event_Trace>= 3 then
				if ( _Event_Trace[#_Event_Trace-1].szName ==  "TIME_LIMIT_SOLD_ITEM_UPDATE_HAVE" or _Event_Trace[#_Event_Trace-1].szName ==  "SOLD_ITEM_UPDATE_HAVE" )
				and _Event_Trace[#_Event_Trace-2].szName ==  "BAG_ITEM_UPDATE_NONE"
				then		------出售成功
					bAdd = true
					Obj_item_out =  _Event_Trace[#_Event_Trace-1].Obj
				end
			end
			if bAdd then
				local Temp_Record = _Trade:new()
				Temp_Record:SetTime():SetOrderTime():SetMapID()
				if Obj_money then
					Temp_Record:AddMoney(Obj_money:GetMoney())
				end
				Temp_Record:AddItem_out(Obj_item_out:GetItem_out())
				Temp_Record:SetType(TRADE.SHOP_SELL)

				local Shop = LR_AS_Trade.Shop
				local dwNpcID = Shop.dwNpcID
				local npc = GetNpc(dwNpcID)
				if npc then
					local szName = LR.Trim(npc.szName)
					if szName ==  "" then
						szName = LR.Trim(Table_GetNpcTemplateName(npc.dwTemplateID))
					end
					local Source = {dwID = dwID, szName = szName, szTitle = LR.Trim(npc.szTitle), nType = TARGET.NPC, nCamp = nil, dwForceID = nil, }
					Temp_Record:SetSource(Source)
				end

				LR_AS_Trade.AddRecord(Temp_Record)
			end
		elseif _Event_Trace[#_Event_Trace].szName == "UI_OME_SHOP_RESPOND_2" then	--购买物品成功
			local bAdd = false
			local Obj_item_in = nil
			local Obj_money = nil
			if #_Event_Trace>= 6 and not bAdd then
				if _Event_Trace[#_Event_Trace-1].szName ==  "LOOT_ITEM"
				and _Event_Trace[#_Event_Trace-2].szName ==  "BAG_ITEM_UPDATE_HAVE"
				and _Event_Trace[#_Event_Trace-3].szName ==  "BAG_ITEM_UPDATE_NONE"
				and _Event_Trace[#_Event_Trace-4].szName ==  "DESTROY_ITEM"
				and _Event_Trace[#_Event_Trace-5].szName ==  "MONEY_UPDATE"
				and GetTime() - _Event_Trace[#_Event_Trace-5].Obj:GetOrderTime() <500
				then
					bAdd = true
					Obj_item_in =  _Event_Trace[#_Event_Trace-1].Obj
					Obj_money = _Event_Trace[#_Event_Trace-5].Obj
				end
			end
			if #_Event_Trace>= 4 and not bAdd then
				if _Event_Trace[#_Event_Trace-1].szName ==  "LOOT_ITEM"
				and _Event_Trace[#_Event_Trace-2].szName ==  "BAG_ITEM_UPDATE_HAVE"
				and  _Event_Trace[#_Event_Trace-3].szName ==  "MONEY_UPDATE"
				and GetTime() - _Event_Trace[#_Event_Trace-3].Obj:GetOrderTime() <500
				then		------购买物品成功
					bAdd = true
					Obj_item_in =  _Event_Trace[#_Event_Trace-1].Obj
					Obj_money = _Event_Trace[#_Event_Trace-3].Obj
				end
			end
			if #_Event_Trace>= 3 and not bAdd then
				if _Event_Trace[#_Event_Trace-1].szName ==  "LOOT_ITEM"
				and _Event_Trace[#_Event_Trace-2].szName ==  "BAG_ITEM_UPDATE_HAVE"
				and GetTime() - _Event_Trace[#_Event_Trace-2].Obj:GetOrderTime() <500
				then		------购买物品成功
					bAdd = true
					Obj_item_in =  _Event_Trace[#_Event_Trace-1].Obj
				end
			end
			if bAdd then
				local Temp_Record = _Trade:new()
				Temp_Record:SetTime():SetOrderTime():SetMapID()
				if Obj_money then
					Temp_Record:AddMoney(Obj_money:GetMoney())
				end
				Temp_Record:AddItem_in(Obj_item_in:GetItem_in())
				Temp_Record:SetType(TRADE.SHOP_BUY)
				local Shop = LR_AS_Trade.Shop
				local dwNpcID = Shop.dwNpcID
				local npc = GetNpc(dwNpcID)
				if npc then
					local szName = LR.Trim(npc.szName)
					if szName ==  "" then
						szName = LR.Trim(Table_GetNpcTemplateName(npc.dwTemplateID))
					end
					local Source = {dwID = dwID, szName = szName, szTitle = LR.Trim(npc.szTitle), nType = TARGET.NPC, nCamp = nil, dwForceID = nil, }
					Temp_Record:SetSource(Source)
				end
				LR_AS_Trade.AddRecord(Temp_Record)
			end
		elseif _Event_Trace[#_Event_Trace].szName == "UI_OME_SHOP_RESPOND_3" then	-----修理成功
			if #_Event_Trace>= 2 then
				if _Event_Trace[#_Event_Trace-1].szName ==  "MONEY_UPDATE" then
					local Obj_money = _Event_Trace[#_Event_Trace-1].Obj
					local Temp_Record = _Trade:new()
					Temp_Record:SetTime():SetOrderTime():SetMapID()
					Temp_Record:AddMoney(Obj_money:GetMoney())
					Temp_Record:SetType(TRADE.REPAIR)
					local Shop = LR_AS_Trade.Shop
					local dwNpcID = Shop.dwNpcID
					local npc = GetNpc(dwNpcID)
					if npc then
						local szName = LR.Trim(npc.szName)
						if szName ==  "" then
							szName = LR.Trim(Table_GetNpcTemplateName(npc.dwTemplateID))
						end
						local Source = {dwID = dwID, szName = szName, szTitle = LR.Trim(npc.szTitle), nType = TARGET.NPC, nCamp = nil, dwForceID = nil, }
						Temp_Record:SetSource(Source)
					end
					LR_AS_Trade.AddRecord(Temp_Record)
				end
			end
		elseif _Event_Trace[#_Event_Trace].szName == "UI_OME_SHOP_RESPOND_5" then	----退货成功
			Dbug._Debug_Event(6)
			local Obj_item_in = nil
			local Obj_money  = nil
			local bAdd = false
			if #_Event_Trace>= 6 and not bAdd then
				if _Event_Trace[#_Event_Trace-1].szName ==  "MONEY_UPDATE"
				and _Event_Trace[#_Event_Trace-2].szName ==  "LOOT_ITEM"
				and _Event_Trace[#_Event_Trace-3].szName ==  "BAG_ITEM_UPDATE_HAVE"
				and _Event_Trace[#_Event_Trace-4].szName ==  "BAG_ITEM_UPDATE_NONE"
				and _Event_Trace[#_Event_Trace-5].szName ==  "DESTROY_ITEM"
				and GetTime() - _Event_Trace[#_Event_Trace-5].Obj:GetOrderTime() < 500
				then
					Obj_item_in = _Event_Trace[#_Event_Trace-2].Obj
					Obj_money = _Event_Trace[#_Event_Trace-1].Obj
					bAdd = true
				end
			end
			if #_Event_Trace>= 4 and not bAdd then
				if _Event_Trace[#_Event_Trace-1].szName ==  "MONEY_UPDATE"
				and _Event_Trace[#_Event_Trace-2].szName ==  "BAG_ITEM_UPDATE_NONE"
				and _Event_Trace[#_Event_Trace-3].szName ==  "DESTROY_ITEM"
				and GetTime() - _Event_Trace[#_Event_Trace-3].Obj:GetOrderTime() < 500
				then
					Obj_money = _Event_Trace[#_Event_Trace-1].Obj
					bAdd = true
				end
			end
			if bAdd then
				local Temp_Record = _Trade:new()
				Temp_Record:SetTime():SetOrderTime():SetMapID()
				Temp_Record:AddMoney(Obj_money:GetMoney())
				if Obj_item_in then
					Temp_Record:AddItem_in(Obj_item_in:GetItem_in())
				end
				Temp_Record:SetType(TRADE.SHOP_RETURN)
				local Shop = LR_AS_Trade.Shop
				local dwNpcID = Shop.dwNpcID
				local npc = GetNpc(dwNpcID)
				if npc then
					local szName = LR.Trim(npc.szName)
					if szName ==  "" then
						szName = LR.Trim(Table_GetNpcTemplateName(npc.dwTemplateID))
					end
					local Source = {dwID = dwID, szName = szName, szTitle = LR.Trim(npc.szTitle), nType = TARGET.NPC, nCamp = nil, dwForceID = nil, }
					Temp_Record:SetSource(Source)
				end
				LR_AS_Trade.AddRecord(Temp_Record)
			end
		elseif _Event_Trace[#_Event_Trace].szName == "UI_OME_TRADING_RESPOND_1" then	----交易成功
			local Temp_Record = _Trade:new()
			Temp_Record:SetTime():SetOrderTime():SetMapID()
			local i = 0

			while (_Event_Trace[#_Event_Trace-i].szName~= "TRADING_UPDATE_CONFIRM" )
			do
				if _Event_Trace[#_Event_Trace-i].szName == "BAG_ITEM_UPDATE_HAVE" then
					local Obj_item_in = _Event_Trace[#_Event_Trace-i].Obj
					Temp_Record:AddItem_in(Obj_item_in:GetItem_in())
				elseif _Event_Trace[#_Event_Trace-i].szName == "MONEY_UPDATE" then
					local Obj_money = _Event_Trace[#_Event_Trace-i].Obj
					Temp_Record:AddMoney(Obj_money:GetMoney())
				elseif _Event_Trace[#_Event_Trace-i].szName == "DESTROY_ITEM" then
					local Obj_item_out = _Event_Trace[#_Event_Trace-i].Obj
					Temp_Record:AddItem_out(Obj_item_out:GetItem_out())
				end
				i = i+1
			end
			Temp_Record:SetType(TRADE.TRADE)

			local player = GetPlayer(LR_AS_Trade.Tradeing_TarID)
			if player then
				local Source = {dwID = player.dwID, szName = LR.Trim(player.szName), szTitle = LR.Trim(player.szTitle), nType = TARGET.PLAYER, nCamp = player.nCamp, dwForceID = player.dwForceID, }
				Temp_Record:SetSource(Source)
			end

			LR_AS_Trade.AddRecord(Temp_Record)

			LR_AS_Trade.Tradeing_Flag = 0
		end
	end
end

function LR_AS_Trade.LOOT_ITEM()
	local dwPlayerID = arg0
	local dwItemID = arg1
	local dwCount = arg2

	if LR_AS_Trade.Mail_Flag then
		return
	end

	local me = GetClientPlayer()
	if not me then
		return
	end
	if dwPlayerID~= me.dwID then
		return
	end
	local item = GetItem(dwItemID)
	if not item then
		return
	end

	Dbug.Debug("LOOT_ITEM")
	local _Event = {}
	_Event.szName = "LOOT_ITEM"
	_Event.Obj = _Trade:new()
	_Event.Obj:SetTime():SetOrderTime():SetMapID()

	local nStackNum = 1
	if item.bCanStack then
		nStackNum = item.nStackNum
	end
	local nBookID = 0
	if item.nGenre ==  ITEM_GENRE.BOOK then
		nBookID = item.nBookID
	end

	_Event.Obj:AddItem_in({{nVersion = item.nVersion, dwTabType = item.dwTabType, dwIndex = item.dwIndex, nStackNum = dwCount, nBookID = nBookID}})
	_Event_Trace[#_Event_Trace+1] = _Event

	if _Event_Trace[#_Event_Trace].szName == "LOOT_ITEM" then
		if LR_AS_Trade.Tradeing_Flag ==  2 then
			return
		end
		local frame = Station.Lookup("Normal/ShopPanel")
		if not frame then
			if #_Event_Trace>= 2 then
				if _Event_Trace[#_Event_Trace-1].szName == "BAG_ITEM_UPDATE_HAVE" then
					local Obj_item_in = _Event_Trace[#_Event_Trace].Obj
					local Temp_Record = _Trade:new()
					Temp_Record:SetTime():SetOrderTime():SetMapID()
					Temp_Record:AddItem_in(Obj_item_in:GetItem_in())
					Temp_Record:SetType(TRADE.LOOT)

					if _Doodad_item[LR.Trim(item.szName)] then
						local _items = _Doodad_item[LR.Trim(item.szName)]
						local doodad = _items[#_items].doodad
						if doodad then
							local Source = {dwID = doodad.dwID, szName = LR.Trim(doodad.szName), szTitle = doodad.nKind, nType = TARGET.DOODAD, nCamp = nil, dwForceID = nil, }
							Temp_Record:SetSource(Source)
							_items[#_items] = nil
						end
					end
					LR_AS_Trade.AddRecord(Temp_Record)
				end
			end
		end
	end
end

function LR_AS_Trade.OPEN_DOODAD()
	local dwDoodadID = arg0
	local dwPlayerID = arg1

	local me = GetClientPlayer()
	if not me then
		return
	end
	local doodad =  GetDoodad (dwDoodadID)
	if not _Doodad_Cache[dwDoodadID] then
		local doodad =  GetDoodad (dwDoodadID)
		if doodad then
			local nMoney = doodad.GetLootMoney()
			if nMoney>0 then
				_Doodad_item["money"] = _Doodad_item["money"] or {}
				local _items = _Doodad_item[money]
				_items[#_items+1] = {dwID = dwID, doodad = {dwID = dwDoodadID, szName = LR.Trim(doodad.szName), nKind = doodad.nKind}}
			end

			local num = doodad.GetItemListCount()
			for i = num-1, 0, -1 do
				local item, bRoll, bDist = doodad.GetLootItem(i, me)
				if item then
					local szName = LR.Trim(item.szName)
					_Doodad_item[szName] = _Doodad_item[szName] or {}
					local _items = _Doodad_item[szName]
					local bAdd = true
					for i = #_items, 1, -1 do
						if _items[i].doodad.dwID ==  dwDoodadID then
							bAdd = false
						end
					end
					if bAdd then
						_items[#_items+1] = {dwID = dwID, doodad = {dwID = dwDoodadID, szName = LR.Trim(doodad.szName), nKind = doodad.nKind}}
					end
				end
			end
			_Doodad_Cache[dwDoodadID] = {dwID = doodad.dwID, szName = LR.Trim(doodad.szName), nKind = doodad.nKind}
		end
	end

	Dbug.Debug("OPEN_DOODAD")
	local _Event = {}
	_Event.szName = "OPEN_DOODAD"
	_Event.Obj = _Trade:new()
	_Event.Obj:SetTime():SetOrderTime():SetMapID()
	if  _Doodad_Cache[dwDoodadID] then
		local doodad = _Doodad_Cache[dwDoodadID]
		local Source = {dwID = doodad.dwID, szName = doodad.szName, szTitle = doodad.szTitle, nType = TARGET.DOODAD, nCamp = nil, dwForceID = nil, }
		_Event.Obj:SetSource(Source)
	end
	_Event_Trace[#_Event_Trace+1] = _Event
end

function LR_AS_Trade.SYNC_LOOT_LIST()
	local dwDoodadID = arg0
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not _Doodad_Cache[dwDoodadID] then
		local doodad =  GetDoodad (dwDoodadID)
		if doodad then
			--[[
			local nMoney = doodad.GetLootMoney()
			if nMoney>0 then
				_Doodad_item["money"] = _Doodad_item["money"] or {}
				local _items = _Doodad_item[money]
				_items[#_items+1] = {dwID = dwID, doodad = {dwID = dwDoodadID, szName = LR.Trim(doodad.szName), nKind = doodad.nKind}}
			end

			local num = doodad.GetItemListCount()
			for i = num-1, 0, -1 do
				local item, bRoll, bDist = doodad.GetLootItem(i, me)
				if item then
					local szName = LR.Trim(item.szName)
					_Doodad_item[szName] = _Doodad_item[szName] or {}
					local _items = _Doodad_item[szName]
					local bAdd = true
					for i = #_items, 1, -1 do
						if _items[i].doodad.dwID ==  dwDoodadID then
							bAdd = false
						end
					end
					if bAdd then
						_items[#_items+1] = {dwID = dwID, doodad = {dwID = dwDoodadID, szName = LR.Trim(doodad.szName), nKind = doodad.nKind}}
					end
				end
			end
			]]
			_Doodad_Cache[dwDoodadID] = {dwID = doodad.dwID, szName = LR.Trim(doodad.szName), nKind = doodad.nKind}
		end
	end

	Dbug.Debug("SYNC_LOOT_LIST")
	local _Event = {}
	_Event.szName = "SYNC_LOOT_LIST"
	_Event.Obj = _Trade:new()
	_Event.Obj:SetTime():SetOrderTime():SetMapID()
	if  _Doodad_Cache[dwDoodadID] then
		local doodad = _Doodad_Cache[dwDoodadID]
		local Source = {dwID = doodad.dwID, szName = doodad.szName, szTitle = doodad.nKind, nType = TARGET.DOODAD, nCamp = nil, dwForceID = nil, }
		_Event.Obj:SetSource(Source)
	end
	_Event_Trace[#_Event_Trace+1] = _Event

	if _Event_Trace[#_Event_Trace].szName == "SYNC_LOOT_LIST" then
		if #_Event_Trace >= 2 then
			if _Event_Trace[#_Event_Trace-1].szName == "MONEY_UPDATE" and GetTime() - _Event_Trace[#_Event_Trace-1].Obj:GetOrderTime() <500 then
				local Obj_money = _Event_Trace[#_Event_Trace-1].Obj
				local Obj_Souce = _Event_Trace[#_Event_Trace].Obj
				local Temp_Record = _Trade:new()
				Temp_Record:SetTime(Obj_money:GetTime()):SetOrderTime(Obj_money:GetOrderTime()):SetMapID()
				Temp_Record:AddMoney(Obj_money:GetMoney())
				Temp_Record:SetSource(Obj_Souce:GetSource())
				Temp_Record:SetType(TRADE.LOOT_MONEY)
				LR_AS_Trade.AddRecord(Temp_Record)
			end
		end
	end
end

function LR_AS_Trade.ON_BG_CHANNEL_MSG()
	local szKey = arg0
	local nChannel = arg1
	local dwTalkerID = arg2
	local szTalkerName = arg3
	local data = arg4

	local me = GetClientPlayer()
	if not me then
		return
	end
	if szKey~= "GKP" then
		return
	end
	if data[1] ==  "add" then
		if data[2].szPlayer ~=  LR.Trim(me.szName) then
			return
		end
		local dwIndex = data[2].dwIndex
		local dwTabType = data[2].dwTabType
		local nVersion = data[2].nVersion
		local nMoney = data[2].nMoney*10000
		local szNpcName = data[2].szNpcName ---doodad名称
		local szName = data[2].szName

		local Temp_Record = _Trade:new()
		Temp_Record:SetTime():SetOrderTime():SetMapID()
		Temp_Record:AddMoney(nMoney)
		---物品
		Temp_Record:AddItem_in({{nVersion = nVersion, dwTabType = dwTabType, dwIndex = dwIndex, nStackNum = 1, nBookID = 0, szName = szName}})
		---来源
		local Source = {dwID = 0, szName = szNpcName, szTitle = "", nType = TARGET.NO_TARGET, nCamp = nil, dwForceID = nil, }
		Temp_Record:SetSource(Source)
		local team = GetClientTeam()
		if team then
			local member = team.GetMemberInfo(dwTalkerID)
			if member then
				local Distributor = {szName = member.szName, dwID = member.dwID, nType = TARGET.PLAYER, szTitle = "", nCamp = member.nCamp, dwForceID = member.dwForceID}
				Temp_Record:SetDistributor(Distributor)
			end
		end
		Temp_Record:SetType(TRADE.GKP)
		LR_AS_Trade.AddRecord(Temp_Record)
	end
end

function LR_AS_Trade.AUCTION_MESSAGE_NOTIFY()
	local code = arg0
	local szName = LR.Trim(arg1)
	local nGold = arg2
	local nSilver = arg3
	local nCopper = arg4
	local nMoney = nGold*10000+nSilver*100+nCopper

	Dbug.Debug("AUCTION_MESSAGE_NOTIFY")
	local _Event = {}
	_Event.szName = "AUCTION_MESSAGE_NOTIFY"
	_Event.Obj = _Trade:new()
	_Event.Obj:SetTime():SetOrderTime():SetMapID()
	_Event.Obj:AddMoney(nMoney)
	local nItem = {nVersion = 0, dwTabType = 0, dwIndex = 0, nStackNum = 1, nBookID = 0, szName = szName}
	_Event.Obj:AddItem_out({nItem})
	_Event_Trace[#_Event_Trace+1] = _Event

	Dbug._Debug_Event(6)
	if code == 0 then	---交易行购买成功
		local Obj_item_in = _Event_Trace[#_Event_Trace].Obj
		local Obj_money = _Event_Trace[#_Event_Trace-1].Obj
		local Temp_Record = _Trade:new()
		Temp_Record:SetTime():SetOrderTime():SetMapID()
		Temp_Record:AddMoney(Obj_money:GetMoney())
		Temp_Record:AddItem_in(Obj_item_in:GetItem_out())
		Temp_Record:SetType(TRADE.AUCTION_BUY)
		LR_AS_Trade.AddRecord(Temp_Record)
	elseif code == 3 then	----寄卖成功
		local Obj_item_out = _Event_Trace[#_Event_Trace].Obj
		local Obj_money = _Event_Trace[#_Event_Trace].Obj
		local Temp_Record = _Trade:new()
		Temp_Record:SetTime():SetOrderTime():SetMapID()
		Temp_Record:AddMoney(Obj_money:GetMoney())
		Temp_Record:AddItem_out(Obj_item_out:GetItem_out())
		Temp_Record:SetType(TRADE.AUCTION_SUCCESS)
		LR_AS_Trade.AddRecord(Temp_Record)
	end
end

function LR_AS_Trade.AUCTION_SELL_RESPOND()
	if arg0 ==  1 then
		Dbug.Debug("AUCTION_SELL_RESPOND_SUCCEED")
		local _Event = {}
		_Event.szName = "AUCTION_SELL_RESPOND_SUCCEED"
		_Event_Trace[#_Event_Trace+1] = _Event
	end

	if _Event_Trace[#_Event_Trace].szName ==  "AUCTION_SELL_RESPOND_SUCCEED" then
		Dbug._Debug_Event(6)
		if #_Event_Trace >=  4 then
			if _Event_Trace[#_Event_Trace-1].szName ==  "BAG_ITEM_UPDATE_NONE"
			and  _Event_Trace[#_Event_Trace-2].szName ==  "DESTROY_ITEM"
			and  _Event_Trace[#_Event_Trace-3].szName ==  "MONEY_UPDATE"
			then
				local Obj_money = _Event_Trace[#_Event_Trace-3].Obj
				local Temp_Record = _Trade:new()
				Temp_Record:SetTime():SetOrderTime():SetMapID()
				Temp_Record:AddMoney(Obj_money:GetMoney())
				local dwBoxIndex = _Event_Trace[#_Event_Trace-1].dwBoxIndex
				local dwX = _Event_Trace[#_Event_Trace-1].dwX
				local nitem = _Bag_item[sformat("%d_%d", dwBoxIndex, dwX)]
				Temp_Record:AddItem_out({nitem})
				Temp_Record:SetType(TRADE.AUCTION_SELL)
				local Source = _Auction
				Temp_Record:SetSource(Source)
				LR_AS_Trade.AddRecord(Temp_Record)
			end
		end
	end
end

function LR_AS_Trade.TEAM_VOTE_REQUEST()
	if arg0 == 1 then
		_GoldTeam.bOn = true
		_GoldTeam.nTime = GetTime()
	end
end

function LR_AS_Trade.TEAM_VOTE_MSG(szMsg)
	local _s, _e = sfind(szMsg, _L["Begin TeamGold"])
	if _s then
		_GoldTeam.bOn = true
		_GoldTeam.nTime = GetTime()
	end
	local _s, _e , nMoney =  sfind(szMsg, _L["Add TeamGold"])
	if nMoney then
		local Temp_Record = _Trade:new()
		Temp_Record:SetTime():SetOrderTime():SetMapID()
		Temp_Record:AddMoney(nMoney*10000*(-1))
		Temp_Record:SetType(TRADE.GOLDTEAM_ADDMONEY)
		LR_AS_Trade.AddRecord(Temp_Record)
	end
end

function LR_AS_Trade.FAN_PAI_JIANG_LI(szMsg)
	local _s, _e = sfind(szMsg, _L["FAN_PAI_JIANG_LI_STRING"])
	if _s then

	end
end

function LR_AS_Trade.QUEST_FINISHED()
	local dwQuestID = arg0
	local QuestInfo = LR.Table_GetQuestStringInfo(dwQuestID)
	local szQuestName = LR.Trim(QuestInfo.szName)

	Dbug.Debug("QUEST_FINISHED")
	local _Event = {}
	_Event.szName = "QUEST_FINISHED"
	_Event.Obj = _Trade:new()
	_Event.Obj:SetTime():SetOrderTime():SetMapID()
	----用获取物品一栏存储任务信息
	_Event.Obj:AddItem_in({{nVersion = 0, dwTabType = 0, dwIndex = 0, nStackNum = 1, nBookID = dwQuestID, szName = szQuestName}})
	_Event_Trace[#_Event_Trace+1] = _Event

	if _Event_Trace[#_Event_Trace].szName == "QUEST_FINISHED" then
		if #_Event_Trace>= 2 then
			if _Event_Trace[#_Event_Trace-1].szName ==  "MONEY_UPDATE" and GetTime() - _Event_Trace[#_Event_Trace-1].Obj:GetOrderTime() < 500 then
				local Temp_Record = _Trade:new()
				local Obj_money = _Event_Trace[#_Event_Trace-1].Obj
				local Obj_item_in = _Event_Trace[#_Event_Trace].Obj
				Temp_Record:SetTime():SetOrderTime():SetMapID()
				Temp_Record:AddMoney(Obj_money:GetMoney())
				Temp_Record:AddItem_in(Obj_item_in:GetItem_in())
				Temp_Record:SetType(TRADE.QUEST)
				LR_AS_Trade.AddRecord(Temp_Record)
			end
		end
	end
end

function LR_AS_Trade.CheckGoldTeam(Temp_Record)
	local nTime = GetTime()
	if not _GoldTeam.bOn then
		return
	end
	if nTime-_GoldTeam.nTime >= 35000 then
		_GoldTeam.bOn = false
		_GoldTeam.nTime = 0
		return
	end
	local handle = Station.Lookup("Topmost2/Announce", "")
	if  handle then
		local text = handle:Lookup(4)
		local t = LR.Trim(text:GetText())
		if t == _L["MSG_1"] then
			local Temp_Record = Temp_Record
			Temp_Record:SetType(TRADE.GOLDTEAM)
			LR_AS_Trade.AddRecord(Temp_Record)
			_GoldTeam.bOn = false
			_GoldTeam.nTime = 0
		end
	end
end

function LR_AS_Trade.Mail_GetItemInMail()
	local me = GetClientPlayer()
	local Mail = GetMailClient()
	local npcID = LR_AS_Trade.Mail_TarID
	if npcID == 0 then
		return
	end

	local data = {
		nMoney = 0,
		items = {},
	}
	local data2 = {
		nPayMoney = 0,
		items = {},
	}
	local MailList = Mail.GetMailList("all")

	for i, dwMailID in pairs(MailList) do
		if dwMailID then
			local MailInfo =  Mail.GetMailInfo(dwMailID)
			local content = MailInfo.RequestContent(npcID)

			if MailInfo.bMoneyFlag then
				local nMoney = MailInfo.nMoney
				if nMoney>0 then
					data.nMoney = data.nMoney + nMoney
				end
			end

			if MailInfo.bPayFlag then
				local nMoney = MailInfo.nAllItemPrice
				if nMoney>0 then
					data2.nPayMoney = data2.nPayMoney + nMoney
				end
			end

			if MailInfo.bItemFlag then
				for j = 0, 7, 1 do
					local item = MailInfo.GetItem(j)
					if item then
						local t_item = {}
						t_item.nVersion = item.nVersion
						t_item.dwTabType = item.dwTabType
						t_item.dwIndex = item.dwIndex
						t_item.nStackNum = 1
						if item.bCanStack then
							t_item.nStackNum = item.nStackNum
						end
						t_item.nBookID = 0
						if item.nGenre == ITEM_GENRE.BOOK then
							t_item.nBookID = item.nBookID
						end
						local key = sformat("%d", item.nUiId)
						if item.bBind then
							key = sformat("%s_bBind", key)
						end
						local items = data.items
						if MailInfo.bPayFlag then
							items = data2.items
						end
						items[key] = items[key] or {}
						if next(items[key]) == nil then
							items[key] = clone(t_item)
						else
							items[key].nStackNum = items[key].nStackNum + t_item.nStackNum
						end
					end
				end
			end
		end
	end
	return data, data2
end

function LR_AS_Trade.Mail_GetItemInBag()
	local me = GetClientPlayer()
	local data = {
		nMoney = 0,
		items = {},
	}
	local Money = me.GetMoney()
	data.nMoney = Money.nCopper+Money.nSilver*100+Money.nGold*10000

	for _, dwBox in pairs(BAG_PACKAGE) do
		local size = me.GetBoxSize(dwBox)
		for dwX = 0, size - 1 do
			local item = me.GetItem(dwBox, dwX)
			if item then
				local t_item = {}
				t_item.nVersion = item.nVersion
				t_item.dwTabType = item.dwTabType
				t_item.dwIndex = item.dwIndex
				t_item.nStackNum = 1
				if item.bCanStack then
					t_item.nStackNum = item.nStackNum
				end
				t_item.nBookID = 0
				if item.nGenre == ITEM_GENRE.BOOK then
					t_item.nBookID = item.nBookID
				end
				local key = sformat("%d", item.nUiId)
				if item.bBind then
					key = sformat("%s_bBind", key)
				end
				local items = data.items
				items[key] = items[key] or {}
				if next(items[key]) == nil then
					items[key] = clone(t_item)
				else
					items[key].nStackNum = items[key].nStackNum + t_item.nStackNum
				end
			end
		end
	end

	return data
end

function LR_AS_Trade.Mail_GetChangeInMail()
	local data = {
		nMoney = 0,
		items = {},
	}
	local data2 = {
		nPayMoney = 0,
		items = {},
	}

	--收件
	data.nMoney = _Item_In_Mail_old.nMoney - _Item_In_Mail_new.nMoney
	for k, v in pairs(_Item_In_Mail_old.items) do
		if _Item_In_Mail_new.items[k] then
			if _Item_In_Mail_old.items[k].nStackNum ~=  _Item_In_Mail_new.items[k].nStackNum then
				local items = data.items
				items[#items+1] = clone(_Item_In_Mail_old.items[k])
				items[#items].nStackNum = _Item_In_Mail_old.items[k].nStackNum -  _Item_In_Mail_new.items[k].nStackNum
			end
		else
			local items = data.items
			items[#items+1] = clone(_Item_In_Mail_old.items[k])
		end
	end

	--付费
	data2.nPayMoney = _Item_In_MailPay_old.nPayMoney - _Item_In_MailPay_new.nPayMoney
	for k, v in pairs(_Item_In_MailPay_old.items) do
		if _Item_In_MailPay_new.items[k] then
			if _Item_In_MailPay_old.items[k].nStackNum ~=  _Item_In_MailPay_new.items[k].nStackNum then
				local items = data2.items
				items[#items+1] = clone(_Item_In_MailPay_old.items[k])
				items[#items].nStackNum = _Item_In_MailPay_old.items[k].nStackNum -  _Item_In_MailPay_new.items[k].nStackNum
			end
		else
			local items = data2.items
			items[#items+1] = clone(_Item_In_MailPay_old.items[k])
		end
	end

	return data, data2
end

function LR_AS_Trade.Mail_GetChangeInBag()
	local data = {
		nMoney = 0,
		items = {},
	}
	-----先将收取的信件合并至old
	local data2 = clone(_Item_In_Bag_old)
	data2.nMoney = data2.nMoney+_Item_In_Mail_change.nMoney-_Item_In_MailPay_change.nPayMoney

	for k, v in pairs(_Item_In_Bag_change.items) do
		if data2.items[k] then
			data2.items[k].nStackNum = data2.items[k].nStackNum + _Item_In_Bag_change.items[k].nStackNum
		else
			data2.items[k] = clone(_Item_In_Bag_change.items[k])
		end
	end

	data.nMoney = data2.nMoney - _Item_In_Bag_new.nMoney
	for k, v in pairs(data2.items) do
		if _Item_In_Bag_new.items[k] then
			if data2.items[k].nStackNum - _Item_In_Bag_new.items[k].nStackNum > 0 then
				local items = data.items
				items[#items+1] = clone(data2.items[k])
				items[#items].nStackNum = data2.items[k].nStackNum -  _Item_In_Bag_new.items[k].nStackNum
			end
		else
			local items = data.items
			items[#items+1] = clone(data2.items[k])
		end
	end

	return data
end

function LR_AS_Trade.isMailPanelOpen()
	local frame = Station.Lookup("Normal/MailPanel")
	if frame then
		LR.DelayCall(1000, function() LR_AS_Trade.isMailPanelOpen() end)
		return
	else
		_Item_In_Mail_new, _Item_In_MailPay_new = LR_AS_Trade.Mail_GetItemInMail()
		_Item_In_Mail_change, _Item_In_MailPay_change = LR_AS_Trade.Mail_GetChangeInMail()

		_Item_In_Bag_new = LR_AS_Trade.Mail_GetItemInBag()
		_Item_In_Bag_change = LR_AS_Trade.Mail_GetChangeInBag()

		----收件
		if _Item_In_Mail_change.nMoney~= 0 or next(_Item_In_Mail_change.items)~= nil then
			local Temp_Record = _Trade:new()
			Temp_Record:SetTime():SetOrderTime():SetMapID()
			Temp_Record:AddMoney(_Item_In_Mail_change.nMoney)
			Temp_Record:AddItem_in(_Item_In_Mail_change.items)
			Temp_Record:SetType(TRADE.MAIL_GET)
			LR_AS_Trade.AddRecord(Temp_Record)
		end

		--付费
		if _Item_In_MailPay_change.nPayMoney ~= 0 or next(_Item_In_MailPay_change.items)~= nil then
			local Temp_Record2 = _Trade:new()
			Temp_Record2:SetTime():SetOrderTime(GetTime()+1):SetMapID()
			Temp_Record2:AddMoney(- (_Item_In_MailPay_change.nPayMoney))
			Temp_Record2:AddItem_in(_Item_In_MailPay_change.items)
			Temp_Record2:SetType(TRADE.MAIL_PAY)
			LR_AS_Trade.AddRecord(Temp_Record2)
		end

		--发件
		if _Item_In_Bag_change.nMoney ~= 0 or next(_Item_In_Bag_change.items)~= nil then
			local Temp_Record3 = _Trade:new()
			Temp_Record3:SetTime():SetOrderTime(GetTime()+2):SetMapID()
			Temp_Record3:AddMoney(- (_Item_In_Bag_change.nMoney))
			Temp_Record3:AddItem_out(_Item_In_Bag_change.items)
			Temp_Record3:SetType(TRADE.MAIL_SEND)
			LR_AS_Trade.AddRecord(Temp_Record3)
		end

		_Item_In_Mail_old = {nMoney = 0, items = {}, }
		_Item_In_Mail_new = {nMoney = 0, items = {}, }
		_Item_In_Mail_change = {nMoney = 0, items = {}, }
		_Item_In_MailPay_old = {nPayMoney = 0, items = {}, }
		_Item_In_MailPay_new = {nPayMoney = 0, items = {}, }
		_Item_In_MailPay_change = {nPayMoney = 0, items = {}, }
		_Item_In_Bag_old = {nMoney = 0, items = {}, }
		_Item_In_Bag_new = {nMoney = 0, items = {}, }
		_Item_In_Bag_change = {nMoney = 0, items = {}, }

		LR_AS_Trade.Mail_Flag = false

		LR_AS_Trade.SaveTempData()
	end
end

function LR_AS_Trade.OpenMailPanel()
	LR_AS_Trade.Mail_Flag = true
	LR.DelayCall(800, function()
		_Item_In_Mail_old, _Item_In_MailPay_old = LR_AS_Trade.Mail_GetItemInMail()
		_Item_In_Bag_old = LR_AS_Trade.Mail_GetItemInBag()
	end)
	LR.DelayCall(1000, function() LR_AS_Trade.isMailPanelOpen() end)
end

function LR_AS_Trade.AddRecord(Temp_Record)
	local Temp_Record = Temp_Record
	local Trade_LIst = LR_AS_Trade.Trade_LIst
	local index = LR_AS_Trade.index
	local bAdd = true

	if next(_This_Login) ~=  nil then
		local LastIndex = index[#index]
		local nTime = LastIndex.nTime
		local OrderTime = LastIndex.OrderTime
		local key = sformat("%d_%d", nTime, OrderTime)
		local LastRecord = Trade_LIst[key]
		if Temp_Record:GetType() ==  TRADE.SHOP_BUY or Temp_Record:GetType() ==  TRADE.SHOP_SELL or Temp_Record:GetType() ==  TRADE.RETURN or Temp_Record:GetType() ==  TRADE.H_RETURN then
			if LastRecord:GetType() ==  Temp_Record:GetType() and Temp_Record:GetOrderTime() - LastRecord:GetOrderTime() < 60000 then
				if next(LastRecord:GetSource())~= nil and next(Temp_Record:GetSource())~= nil then
					if LastRecord:GetSource().dwID ==  Temp_Record:GetSource().dwID then
						bAdd = false
					end
				end
			end
		end

		if Temp_Record:GetType() ==  TRADE.REPAIR then
			if LastRecord:GetType() ==  Temp_Record:GetType() and Temp_Record:GetOrderTime() - LastRecord:GetOrderTime() < 1000 then
				if next(LastRecord:GetSource())~= nil and next(Temp_Record:GetSource())~= nil then
					if LastRecord:GetSource().dwID ==  Temp_Record:GetSource().dwID then
						bAdd = false
					end
				end
			end
		end

		if Temp_Record:GetType() ==  TRADE.LOOT then
			if (LastRecord:GetType() ==  Temp_Record:GetType() or LastRecord:GetType() == TRADE.LOOT_MONEY)  and Temp_Record:GetOrderTime() - LastRecord:GetOrderTime() < 60000 then
				if LastRecord:GetType() ==  TRADE.LOOT then
					if next(LastRecord:GetSource())~= nil and next(Temp_Record:GetSource())~= nil then
						if LastRecord:GetSource().szName ==  Temp_Record:GetSource().szName then
							bAdd = false
						end
					end
				elseif LastRecord:GetType() ==  TRADE.LOOT_MONEY then
					bAdd = false
				end
			end
		end

		if Temp_Record:GetType() ==  TRADE.LOOT_MONEY then
			if (LastRecord:GetType() ==  TRADE.LOOT_MONEY or LastRecord:GetType() ==  TRADE.LOOT)  and Temp_Record:GetOrderTime() - LastRecord:GetOrderTime() < 60000 then
				bAdd = false
			end
		end
	end

	if bAdd then
		local nTime = Temp_Record:GetTime()
		local OrderTime = Temp_Record:GetOrderTime()
		local _date = TimeToDate(nTime)
		local year = _date.year
		local month = _date.month
		local day = _date.day
		Temp_Record:SetDate(_date)
		local key = sformat("%d_%d", nTime, OrderTime)
		Trade_LIst[key] = Temp_Record
		index[#index+1] = {nTime = nTime, OrderTime = OrderTime, }
		_This_Login[#_This_Login+1] = {nTime = nTime, OrderTime = OrderTime, }

		local key2 = sformat("%d_%d_%d", year, month, day)
		_Today[key2] = _Today[key2] or {}
		_Today[key2][#_Today[key2]+1] = {nTime = nTime, OrderTime = OrderTime, }

		_2bSave[key2] = _2bSave[key2] or {}
		local _day = _2bSave[key2]
		_day[#_day+1] = Temp_Record:GetData()
	else
		local LastIndex = index[#index]
		local nTime = LastIndex.nTime
		local OrderTime = LastIndex.OrderTime
		local _date = TimeToDate(nTime)
		local year = _date.year
		local month = _date.month
		local day = _date.day
		local key = sformat("%d_%d", nTime, OrderTime)
		local LastRecord = Trade_LIst[key]
		LastRecord:AddMoney(Temp_Record:GetMoney()):AddItem_in(Temp_Record:GetItem_in()):AddItem_out(Temp_Record:GetItem_out())
		if Temp_Record:GetType() == TRADE.LOOT and LastRecord:GetType() == TRADE.LOOT_MONEY then
			LastRecord:SetSource(Temp_Record:GetSource())
			LastRecord:SetType(TRADE.LOOT)
		end
		local key2 = sformat("%d_%d_%d", year, month, day)
		_2bSave[key2] = _2bSave[key2] or {}
		local _day = _2bSave[key2]
		_day[#_day] = LastRecord:GetData()
	end
	_Event_Trace = {}
	_Bag_item = {}
	LR_Acc_Trade_Panel:Refresh()
	--LR_AS_Trade.SaveTempData()
end

function LR_AS_Trade.FIRST_LOADING_END()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local nMoney = me.GetMoney()
	LR_AS_Trade.Login_Money = nMoney.nCopper+nMoney.nSilver*100+nMoney.nGold*10000
end

-------------金钱变动提醒
function LR_AS_Trade.OutPutMoneyChange()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local nMoney = me.GetMoney()
	local money = nMoney.nCopper+nMoney.nSilver*100+nMoney.nGold*10000
	local delta_money = money - LR_AS_Trade.Login_Money
	local text_money = LR_AS_Trade.FormatMoney(delta_money)

	local t_text = {}
	t_text[#t_text+1] = _L["LR:This login, you got money:"]
	if delta_money < 0 then
		t_text[#t_text+1] = " - "
	end
	t_text[#t_text+1] = text_money
	t_text[#t_text+1] = sformat(_L["(Do not show again in %d seconds)"], 10)
	if _log_flag == 1 then
		t_text[#t_text+1] = _L["(8s)"]
		_log_flag = 0
	end
	t_text[#t_text+1] = "\n"

	local text = tconcat(t_text)
	LR.SysMsg(text)
end

function LR_AS_Trade.OPEN_WINDOW()
	local dwIndex = arg0
	local szText = LR.Trim(arg1)
	local dwTargetType = arg2
	local dwTargetID = arg3

	if dwTargetType ==  TARGET.NPC then
		local npc = GetNpc(dwTargetID)
		if LR.Trim(npc.szTitle) ==  _L["TRADER"] then
			_Auction = {dwID = npc.dwID, szName = LR.Trim(npc.szName), szTitle = LR.Trim(npc.szTitle), nType = TARGET.NPC}
		elseif sfind(szText, _L["feige"]) then
			LR_AS_Trade.Mail_TarID = dwTargetID
		end
	end
end

function LR_AS_Trade.FormatMoney(nMoney)
	local nMoney = nMoney
	local t = {}
	if type(nMoney) ==  "table" then
		if nMoney.nGold <0 then
			nMoney.nGold = 0 - nMoney.nGold
		end

		if nMoney.nGold >0 then
			if nMoney.nGold >= 10000 then
				t[#t+1] = sformat(_L["%dGoldBrick"], nMoney.nGold / 10000)
				if nMoney.nGold%10000 >0 then
					t[#t+1] = sformat(_L["%dGold"], nMoney.nGold % 10000)
				end
			elseif nMoney.nGold>0 then
				t[#t+1] = sformat(_L["%dGold"], nMoney.nGold)
			end
		end
		if nMoney.nSilver > 0 then
			t[#t+1] = sformat(_L["%dSilver"], nMoney.nSilver)
		end
		if nMoney.nCopper > 0 then
			t[#t+1] = sformat(_L["%dCopper"], nMoney.nCopper)
		end
	elseif type(nMoney) ==  "number" then
		if nMoney < 0 then
			nMoney = 0 - nMoney
		end

		if nMoney>= 100000000 then
			t[#t+1] = sformat(_L["%dGoldBrick"], nMoney / 100000000)
			nMoney = nMoney % 100000000
		end
		if nMoney >= 10000 then
			t[#t+1] = sformat(_L["%dGold"], nMoney / 10000)
			nMoney = nMoney % 10000
		end
		if nMoney >= 100 then
			t[#t+1] = sformat(_L["%dSilver"], nMoney / 100)
			nMoney = nMoney % 100
		end
		if nMoney >0 then
			t[#t+1] = sformat(_L["%dCopper"], nMoney / 1)
			nMoney = nMoney % 1
		end

		if #t == 0 then
			t[#t+1] = sformat(_L["%dGold"], 0)
		end
	end
	local szText = tconcat(t)

	return szText
end

function LR_AS_Trade.GetItemInBag()
	local me = GetClientPlayer()
	if not me then
		return
	end

	_Bag_item = {}
	for _, dwBox in pairs(BAG_PACKAGE) do
		local size = me.GetBoxSize(dwBox)
		for dwX = 0, size - 1, 1 do
			local item = me.GetItem(i, n)
			if item then
				local nStackNum = 1
				if item.bCanStack then
					nStackNum = item.nStackNum
				end
				local nBookID = 0
				if item.nGenre ==  ITEM_GENRE.BOOK then
					nBookID = item.nBookID
				end
				_Bag_item[sformat("%d_%d", i, n)] = {nVersion = item.nVersion, dwTabType = item.dwTabType, dwIndex = item.dwIndex, nStackNum = nStackNum, nBookID = nBookID}
			end
		end
	end
end

LR.RegisterEvent("SYS_MSG", function() LR_AS_Trade.SYS_MSG() end)
LR.RegisterEvent("SHOP_OPENSHOP", function() LR_AS_Trade.OpenShop() end)
LR.RegisterEvent("MONEY_UPDATE", function() LR_AS_Trade.MONEY_UPDATE() end)

LR.RegisterEvent("FIRST_LOADING_END", function() LR_AS_Trade.FIRST_LOADING_END() end)
--LR.RegisterEvent("ON_FRAME_CREATE", function() LR_AS_Trade.ON_FRAME_CREATE() end)
LR.RegisterEvent("OPEN_WINDOW", function() LR_AS_Trade.OPEN_WINDOW() end)

LR.RegisterEvent("BAG_ITEM_UPDATE", function() LR_AS_Trade.BAG_ITEM_UPDATE() end)
LR.RegisterEvent("SOLD_ITEM_UPDATE", function() LR_AS_Trade.SOLD_ITEM_UPDATE() end)
LR.RegisterEvent("TIME_LIMIT_SOLD_ITEM_UPDATE", function() LR_AS_Trade.TIME_LIMIT_SOLD_ITEM_UPDATE() end)

LR.RegisterEvent("TRADING_OPEN_NOTIFY", function() LR_AS_Trade.TRADING_OPEN_NOTIFY() end)
LR.RegisterEvent("TRADING_UPDATE_CONFIRM", function() LR_AS_Trade.TRADING_UPDATE_CONFIRM() end)
LR.RegisterEvent("TRADING_CLOSE", function() LR_AS_Trade.TRADING_CLOSE() end)
LR.RegisterEvent("TRADING_UPDATE_ITEM", function() LR_AS_Trade.TRADING_UPDATE_ITEM() end)

LR.RegisterEvent("DESTROY_ITEM", function() LR_AS_Trade.DESTROY_ITEM() end)

LR.RegisterEvent("LOOT_ITEM", function() LR_AS_Trade.LOOT_ITEM() end)

LR.RegisterEvent("OPEN_DOODAD", function() LR_AS_Trade.OPEN_DOODAD() end)
LR.RegisterEvent("SYNC_LOOT_LIST", function() LR.DelayCall(70, LR_AS_Trade.SYNC_LOOT_LIST()) end)

LR.RegisterEvent("ON_BG_CHANNEL_MSG", function() LR_AS_Trade.ON_BG_CHANNEL_MSG() end)

LR.RegisterEvent("AUCTION_SELL_RESPOND", function() LR_AS_Trade.AUCTION_SELL_RESPOND() end)
LR.RegisterEvent("AUCTION_MESSAGE_NOTIFY", function() LR_AS_Trade.AUCTION_MESSAGE_NOTIFY() end)

LR.RegisterEvent("TEAM_VOTE_REQUEST", function() LR_AS_Trade.TEAM_VOTE_REQUEST() end)
RegisterMsgMonitor(LR_AS_Trade.TEAM_VOTE_MSG, {"MSG_SYS"})

LR.RegisterEvent("QUEST_FINISHED", function() LR_AS_Trade.QUEST_FINISHED() end)

----------------------------------------------------------------
------界面
----------------------------------------------------------------
LR_Acc_Trade_Panel = _G2.CreateAddon("LR_Acc_Trade_Panel")
LR_Acc_Trade_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_Acc_Trade_Panel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER", x = 0, y = 0},
}

LR_Acc_Trade_Panel.nPage = 1
LR_Acc_Trade_Panel.nPrePage = 1
LR_Acc_Trade_Panel.nNextPage = 1
LR_Acc_Trade_Panel.nFirstPage = 1
LR_Acc_Trade_Panel.nLastPage = 1
LR_Acc_Trade_Panel.nTotalPage = 1
LR_Acc_Trade_Panel.nCount = 0
LR_Acc_Trade_Panel.notByPage =	false

LR_Acc_Trade_Panel.Show_Type = OP1.THIS_LOGIN

function LR_Acc_Trade_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")

	LR_Acc_Trade_Panel.UpdateAnchor(this)
	RegisterGlobalEsc("LR_Acc_Trade_Panel", function () return true end , function() LR_Acc_Trade_Panel:Open() end)
	LR_Acc_Trade_Panel.Show_Type = OP1.THIS_LOGIN
	LR_AS_Trade.SaveTempData(true)
	LR_AS_Trade.MoveData2MainTable()
end

function LR_Acc_Trade_Panel:OnEvents(event)
	if event ==  "UI_SCALED" then
		LR_Acc_Trade_Panel.UpdateAnchor(this)
	end
end

function LR_Acc_Trade_Panel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_Acc_Trade_Panel.UsrData.Anchor.s, 0, 0, LR_Acc_Trade_Panel.UsrData.Anchor.r, LR_Acc_Trade_Panel.UsrData.Anchor.x, LR_Acc_Trade_Panel.UsrData.Anchor.y)
end

function LR_Acc_Trade_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_Acc_Trade_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_Acc_Trade_Panel:OnDragEnd()
	this:CorrectPos()
	LR_Acc_Trade_Panel.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_Acc_Trade_Panel:Init()
	local frame = self:Append("Frame", "LR_Acc_Trade_Panel", {title = _L["LR_TRADE_RECORD"], style = "LARGER"})
	local imgTab = self:Append("Image", frame, "TabImg", {w = 962, h = 33, x = 0, y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)

	local me = GetClientPlayer()
	if me then
		local handle_role = self:Append("Handle", frame, "Handle_role", {x = 670, y = 50, w = 300, h = 30})
		handle_role:SetHandleStyle(3)
		handle_role:SetMinRowHeight(30)
		local szPath, nFrame = GetForceImage(me.dwForceID)
		local image_role = self:Append("Image", handle_role, "Image_Role", { w = 30, h = 30 , image = szPath , frame =  nFrame })
		local Text_role = self:Append("Text", handle_role, "Text_Role", { w = 200, h = 30 , font = 17})
		Text_role:SetText(me.szName)
		Text_role:SetVAlign(1)
		Text_role:SetHAlign(1)
		local r, g, b = LR.GetMenPaiColor(me.dwForceID)
		Text_role:SetFontColor(r, g, b)
		handle_role:FormatAllItemPos()
		local w, h = handle_role:GetAllItemSize()
		handle_role:SetSize(w, 30)
		handle_role:SetRelPos(920-w, 50)
	end


	local hComboBoxShow = self:Append("ComboBox", frame, "hComboBoxShow", {w = 160, x = 20, y = 51, text = TEXT_OP1[LR_Acc_Trade_Panel.Show_Type]})
	hComboBoxShow:Enable(true)
	hComboBoxShow.OnClick = function(m)
		local szOption = {"THIS_LOGIN", "TODAY", "THIS_WEEK", "LAST_SEVEN_DAYS", "THIS_MONTH", "HISTORY"}
		for k, v in pairs (szOption) do
			m[#m+1] = {szOption = TEXT_OP1[OP1[v]], bCheck = true, bMCheck = true, bChecked = function() return LR_Acc_Trade_Panel.Show_Type == OP1[v] end,
			fnAction = function()
				if OP1[v] == OP1.HISTORY then
					LR_Acc_Trade_ChooseDate_Panel:Open()
				else
					LR_Acc_Trade_Panel.Show_Type = OP1[v]
					if OP1[v] == OP1.LAST_SEVEN_DAYS then
						LR_AS_Trade.LoadData(OP1.LAST_SEVEN_DAYS)
					elseif OP1[v] == OP1.THIS_WEEK then
						LR_AS_Trade.LoadData(OP1.THIS_WEEK)
					elseif OP1[v] == OP1.THIS_MONTH then
						LR_AS_Trade.LoadData(OP1.THIS_MONTH)
					elseif OP1[v] == OP1.TODAY then
						LR_AS_Trade.LoadData(OP1.TODAY)
					end
					LR_Acc_Trade_Panel:Refresh()
				end
			end, }
		end

		m[#m+1] = {bDevide = true}
		m[#m+1] = {szOption = _L["Import data"]}
		local t = m[#m]
		t[#t+1] = {szOption = _L["Import old version data (not database version)"],
			fnAction = function()
				local msg = {
					szMessage = _L["Are you sure to import old version data (not database version) ?"],
					szName = "import old version",
					fnAutoClose = function() return false end,
					{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() LR_AS_Trade.ImportOldData() end, },
					{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
				}
				MessageBox(msg)
			end
		}
		t[#t+1] = {szOption = _L["Import new version data (database version)"],
			fnAction = function()
				LR_AS_Trade.ImportNewVersionData()
			end
		}
		PopupMenu(m)
	end

	local BTN_SAVE = self:Append("Button", frame, "BTN_SAVE", {text = _L["SAVE"] , x = 200, y = 51, w = 95, h = 30})
	BTN_SAVE.OnClick = function()
		LR_AS_Trade.MoveData2MainTable()
	end

	local hFAQ_Back = self:Append("Image", frame, "FAQ_back" , {x = 305 , y = 53 , w = 24 , h = 24, })
	hFAQ_Back:FromUITex("ui\\Image\\Common\\MainPanel_1.UITex", 3)
	hFAQ_Back:SetAlpha(150)
	local hFAQ = self:Append("UIButton", frame, "B_FAQ" , {x = 307 , y = 55 , w = 20 , h = 20, ani = {"ui\\Image\\UICommon\\CommonPanel2.UITex", 48, 50, 54}, })
	hFAQ.OnEnter = function()
		local x, y = hFAQ:GetAbsPos()
		local w, h = hFAQ:GetSize()
		local szXml = {}
		szXml[#szXml + 1] = GetFormatText(sformat("1. %s", _L["TRADE_FAQ_1"]), 7)
		szXml[#szXml + 1] = GetFormatText(sformat("2. %s", _L["TRADE_FAQ_2"]), 7)
		szXml[#szXml + 1] = GetFormatText(sformat("3. %s", _L["TRADE_FAQ_3"]), 7)
		szXml[#szXml + 1] = GetFormatText(sformat("4. %s", _L["TRADE_FAQ_4"]), 7)
		szXml[#szXml + 1] = GetFormatText(sformat("5. %s", _L["TRADE_FAQ_5"]), 7)

		OutputTip(tconcat(szXml), 420, {x, y, w, h})
	end
	hFAQ.OnLeave = function()
		HideTip(true)
	end

	----合计金钱
	local hHandle_money_all = self:Append("Handle", frame, "Handle_money_all", {x = 670, y = 550, w = 300, h = 30})
	hHandle_money_all:SetHandleStyle(3)
	hHandle_money_all:SetMinRowHeight(30)
	self:ShowMoneyAll(0)

	local Wnd_PageBTN =	self:Append("Window", frame, "Wnd_PageBTN", {w = 750, h = 80, x = 20, y = 550, })
	--创建一个按钮
	local BTN_FIRST = self:Append("Button", Wnd_PageBTN, "BTN_FIRST", {text = _L["FIRST"] , x = 0, y = 0, w = 95, h = 36})
	--绑定按钮点击事件
	BTN_FIRST.OnClick = function()
		LR_AS_Trade.LoadData(LR_Acc_Trade_Panel.Show_Type, LR_Acc_Trade_Panel.nFirstPage)
		LR_Acc_Trade_Panel:Refresh()
	end
	local BTN_PRE = self:Append("Button", Wnd_PageBTN, "BTN_PRE", {text = _L["PRE"] , x = 100, y = 0, w = 95, h = 36})
	--绑定按钮点击事件
	BTN_PRE.OnClick = function()
		LR_AS_Trade.LoadData(LR_Acc_Trade_Panel.Show_Type, LR_Acc_Trade_Panel.nPrePage)
		LR_Acc_Trade_Panel:Refresh()
	end
	local BTN_NEXT = self:Append("Button", Wnd_PageBTN, "BTN_NEXT", {text = _L["NEXT"] , x = 200, y = 0, w = 95, h = 36})
	--绑定按钮点击事件
	BTN_NEXT.OnClick = function()
		LR_AS_Trade.LoadData(LR_Acc_Trade_Panel.Show_Type, LR_Acc_Trade_Panel.nNextPage)
		LR_Acc_Trade_Panel:Refresh()
	end
	local BTN_LAST = self:Append("Button", Wnd_PageBTN, "BTN_LAST", {text = _L["LAST"] , x = 300, y = 0, w = 95, h = 36})
	--绑定按钮点击事件
	BTN_LAST.OnClick = function()
		LR_AS_Trade.LoadData(LR_Acc_Trade_Panel.Show_Type, LR_Acc_Trade_Panel.nLastPage)
		LR_Acc_Trade_Panel:Refresh()
	end
	local EDIT_PAGE = self:Append("Edit", Wnd_PageBTN, "EDIT_PAGE", {w = 60, h = 24, x = 400, y = 6, text = "0", font = 22})
	local BTN_OK = self:Append("Button", Wnd_PageBTN, "BTN_OK", {text = _L["Yes"] , x = 465, y = 0, w = 95, h = 36})
	--绑定按钮点击事件
	BTN_OK.OnClick = function()
		local nPage = tonumber(EDIT_PAGE:GetText())
		if type(nPage) ~= "number" then
			return
		end
		LR_AS_Trade.LoadData(LR_Acc_Trade_Panel.Show_Type, nPage)
		LR_Acc_Trade_Panel:Refresh()
	end
	local TEXT_PAGE = self:Append("Text", Wnd_PageBTN, "TEXT_PAGE", {w = 400, h = 24, x = 5, y = 40, text = "", font = 2})
	local CheckBox_PAGE = self:Append("CheckBox", Wnd_PageBTN, "CheckBox_PAGE", {w = 50, x = 400, y = 40, text = _L["Do not show by page"]})
	CheckBox_PAGE:Enable(true)
	CheckBox_PAGE:Check(LR_Acc_Trade_Panel.notByPage)
	CheckBox_PAGE.OnCheck = function (arg0)
		LR_Acc_Trade_Panel.notByPage = arg0
		if LR_Acc_Trade_Panel.Show_Type ~= OP1.THIS_LOGIN then
			LR_AS_Trade.LoadData(LR_Acc_Trade_Panel.Show_Type, LR_Acc_Trade_Panel.nPage)
			LR_Acc_Trade_Panel:Refresh()
		end
	end
	CheckBox_PAGE.OnEnter = function()
		local x, y =  CheckBox_PAGE:GetAbsPos()
		local w, h = CheckBox_PAGE:GetSize()
		local szXml = {}
		szXml[#szXml+1] = GetFormatText(_L["Page tip 1"], 136, 255, 128, 0)
		OutputTip(tconcat(szXml), 350, {x, y, 0, 0})
	end
	CheckBox_PAGE.OnLeave = function()
		HideTip()
	end

	local hPageSet = self:Append("PageSet", frame, "PageSet", {x = 20, y = 120, w = 934, h = 420})
	local hWinIconView = self:Append("Window", hPageSet, "WindowItemView", {x = 0, y = 0, w = 934, h = 420})
	local hScroll = self:Append("Scroll", hWinIconView, "Scroll", {x = 0, y = 0, w = 934, h = 420})
	self:LoadItemBox(hScroll)
	hScroll:UpdateList()

	-------------初始界面物品
	local hHandle = self:Append("Handle", frame, "Handle", {x = 18, y = 90, w = 920, h = 450})

	local Image_Record_BG = self:Append("Image", hHandle, "Image_Record_BG", {x = 0, y = 0, w = 920, h = 450})
	Image_Record_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 50)
	Image_Record_BG:SetImageType(10)

	local Image_Record_BG1 = self:Append("Image", hHandle, "Image_Record_BG1", {x = 0, y = 30, w = 920, h = 420})
	Image_Record_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74)
	Image_Record_BG1:SetImageType(10)
	Image_Record_BG1:SetAlpha(110)

	local Image_Record_Line1_0 = self:Append("Image", hHandle, "Image_Record_Line1_0", {x = 3, y = 28, w = 920, h = 3})
	Image_Record_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 65)
	Image_Record_Line1_0:SetImageType(11)
	Image_Record_Line1_0:SetAlpha(115)

	local Text_break1 = self:Append("Text", hHandle, "Text_break1", {w = 120, h = 30, x  = 0, y = 2, text = _L["Time"], font = _font})
	Text_break1:SetHAlign(1)
	Text_break1:SetVAlign(1)

	local Image_Record_Break1 = self:Append("Image", hHandle, "Image_Record_Break1", {x = 120, y = 2, w = 3, h = 442})
	Image_Record_Break1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
	Image_Record_Break1:SetImageType(11)
	Image_Record_Break1:SetAlpha(160)

	local Text_break2 = self:Append("Text", hHandle, "Text_break2", {w = 80, h = 30, x  = 120, y = 2, text = _L["Location"], font = _font})
	Text_break2:SetHAlign(1)
	Text_break2:SetVAlign(1)

	local Image_Record_Break2 = self:Append("Image", hHandle, "Image_Record_Break2", {x = 200, y = 2, w = 3, h = 442})
	Image_Record_Break2:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
	Image_Record_Break2:SetImageType(11)
	Image_Record_Break2:SetAlpha(160)

	local Text_break3 = self:Append("Text", hHandle, "Text_break3", {w = 80, h = 30, x  = 200, y = 2, text = _L["Type"], font = _font})
	Text_break3:SetHAlign(1)
	Text_break3:SetVAlign(1)

	local Image_Record_Break3 = self:Append("Image", hHandle, "Image_Record_Break3", {x = 280, y = 2, w = 3, h = 442})
	Image_Record_Break3:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
	Image_Record_Break3:SetImageType(11)
	Image_Record_Break3:SetAlpha(160)

	local Text_break4 = self:Append("Text", hHandle, "Text_break4", {w = 120, h = 30, x  = 280, y = 2, text = _L["Source/Object"], font = _font})
	Text_break4:SetHAlign(1)
	Text_break4:SetVAlign(1)

	local Image_Record_Break4 = self:Append("Image", hHandle, "Image_Record_Break4", {x = 400, y = 2, w = 3, h = 442})
	Image_Record_Break4:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
	Image_Record_Break4:SetImageType(11)
	Image_Record_Break4:SetAlpha(160)

	local Text_break5 = self:Append("Text", hHandle, "Text_break5", {w = 300, h = 30, x  = 400, y = 2, text = _L["Content"], font = _font})
	Text_break5:SetHAlign(1)
	Text_break5:SetVAlign(1)

	local Image_Record_Break5 = self:Append("Image", hHandle, "Image_Record_Break5", {x = 700, y = 2, w = 3, h = 442})
	Image_Record_Break5:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
	Image_Record_Break5:SetImageType(11)
	Image_Record_Break5:SetAlpha(160)

	local Text_break6 = self:Append("Text", hHandle, "Text_break6", {w = 210, h = 30, x  = 700, y = 2, text = _L["MONEY"], font = _font})
	Text_break6:SetHAlign(1)
	Text_break6:SetVAlign(1)

	----------关于
	LR.AppendAbout(LR_Acc_Trade_Panel, frame)
end

function LR_Acc_Trade_Panel:Open()
	local frame = self:Fetch("LR_Acc_Trade_Panel")
	if frame then
		self:Destroy(frame)
	else
		--LR_AS_Trade.LoadData(nil, true)
		frame = self:Init()

		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

function LR_Acc_Trade_Panel:LoadItemBox(hWin)
	local index  = {}
	local Trade_LIst = LR_AS_Trade.Trade_LIst
	local nMoneyall = 0
	local old_year, old_month, old_day = 0, 0, 0

	local hComboBoxShow = self:Fetch("hComboBoxShow")
	hComboBoxShow:SetText(TEXT_OP1[LR_Acc_Trade_Panel.Show_Type])
	if LR_Acc_Trade_Panel.Show_Type ==  OP1.THIS_LOGIN then
		index = _This_Login or {}
	elseif LR_Acc_Trade_Panel.Show_Type ==  OP1.TODAY then
		index = _Today or {}
	elseif LR_Acc_Trade_Panel.Show_Type ==  OP1.THIS_MONTH then
		index = _This_Month or {}
	elseif LR_Acc_Trade_Panel.Show_Type ==  OP1.THIS_WEEK then
		index = _This_Week or {}
	elseif LR_Acc_Trade_Panel.Show_Type ==  OP1.LAST_SEVEN_DAYS then
		index = _Last_Seven_Days or {}
	elseif LR_Acc_Trade_Panel.Show_Type ==  OP1.HISTORY then
		index = _History or {}
	end
	local nPage = LR_Acc_Trade_Panel.nPage
	local nStart, nEnd, nStep = 1, #index, 1
	if LR_Acc_Trade_Panel.Show_Type == OP1.THIS_LOGIN then
		nStart, nEnd, nStep = #index, 1, -1
	end
	for i = nStart, nEnd, nStep do
		local nTime = index[i].nTime
		local OrderTime = index[i].OrderTime
		local key = sformat("%d_%d", nTime, OrderTime)
		local Trade_Record = Trade_LIst[key]

		local nType = Trade_Record:GetType()
		local flag = true
		if nType == TRADE.QUEST then
			local t_item
			t_item = Trade_Record:GetItem_in()
			local dwQuestID = t_item[1].nBookID
			local szQuestName = LR.GetQuestName(dwQuestID)
			if sfind(szQuestName, _L["QYJSMD"]) then
				flag = false
			end
		end
		if flag then
			local data = TimeToDate(nTime)
			local year = data["year"]
			local month = data["month"]
			local day = data["day"]
			local weekday = data["weekday"]
			if year ~= old_year or month ~= old_month or day ~= old_day then
				local handle_day = self:Append("Handle", hWin, sformat("Handle_Day_%d_%d_%d", year, month, day), {x = 0, y = 0, w = 900, h = 30})
				local t = self:Append("Image", handle_day, sformat("Image_Day_Line2_%d_%d_%d", year, month, day), {x = 4, y = 0, w = 915, h = 30 , image = "ui\\Image\\Minimap\\MapMark.UITex" , frame = 49 })
				t:SetImageType(10)
				t:SetAlpha(150)
				local Image_day_line = self:Append("Image", handle_day, sformat("Image_Day_Line_%d_%d_%d", year, month, day), {x = 0, y = 0, w = 900, h = 30})
				Image_day_line:FromUITex("ui\\Image\\Common\\TextShadow.UITex", 5)
				Image_day_line:SetImageType(10)
				Image_day_line:SetAlpha(250)
				local text = self:Append("Text", handle_day, sformat("Text_Time_%d_1", i), { h = 30, x  = 15, w = 200 , y = 2, text = sformat("%d-%d-%d  %s", year, month, day, _WEEKDAY[weekday]), font = _font})
				text:SetVAlign(1)
				--text:SetHAlign(1)
				old_year, old_month, old_day = year, month, day
			end

			local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", i), {x = 0, y = 0, w = 900, h = 30})
			--hIconViewContent:SetHandleStyle(3)

			local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line1_%d", i), {x = 0, y = 0, w = 900, h = 30})
			Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
			Image_Line:SetImageType(10)
			Image_Line:SetAlpha(200)
			if i%2 == 0 then
				Image_Line:SetAlpha(35)
			end

			local Image_Line2 = self:Append("Image", hIconViewContent, sformat("Image_Line2_%d", i), {x = 0, y = 0, w = 900, h = 30})
			if Trade_Record:GetType() ==  TRADE.GKP then
				Image_Line2:FromUITex("ui\\Image\\Common\\Money.UITex", 228)
			elseif Trade_Record:GetType() ==  TRADE.TRADE or Trade_Record:GetType() ==  TRADE.AUCTION_BUY or Trade_Record:GetType() ==  TRADE.AUCTION_SELL then
				Image_Line2:FromUITex("ui\\Image\\Common\\Money.UITex", 213)
			elseif Trade_Record:GetType() ==  TRADE.SHOP_BUY then
				Image_Line2:FromUITex("ui\\Image\\Common\\Money.UITex", 214)
			elseif Trade_Record:GetType() ==  TRADE.SHOP_SELL then
				Image_Line2:FromUITex("ui\\Image\\Common\\Money.UITex", 215)
			elseif Trade_Record:GetType() ==  TRADE.LOOT or Trade_Record:GetType() ==  TRADE.LOOT_MONEY or Trade_Record:GetType() ==  TRADE.GOLDTEAM then
				Image_Line2:FromUITex("ui\\Image\\Common\\Money.UITex", 212)
			elseif Trade_Record:GetType() ==  TRADE.RETURN or Trade_Record:GetType() ==  TRADE.H_RETURN or Trade_Record:GetType() ==  TRADE.SHOP_RETURN then
				Image_Line2:FromUITex("ui\\Image\\Common\\Money.UITex", 211)
			elseif Trade_Record:GetType() ==  TRADE.MAIL_GET or Trade_Record:GetType() ==  TRADE.MAIL_PAY or Trade_Record:GetType() ==  TRADE.MAIL_SEND then
				Image_Line2:FromUITex("ui\\Image\\Common\\Money.UITex", 219)
			end
			Image_Line2:SetImageType(10)
			Image_Line2:SetAlpha(65)

			--悬停框
			local Image_Hover = self:Append("Image", hIconViewContent, sformat("Image_Hover_%d", i), {x = 2, y = 0, w = 910, h = 30})
			Image_Hover:FromUITex("ui\\Image\\Common\\TempBox.UITex", 5)
			Image_Hover:SetImageType(10)
			Image_Hover:SetAlpha(200)
			Image_Hover:Hide()
			--选择框
			local Image_Select = self:Append("Image", hIconViewContent, sformat("Image_Select_%d", i), {x = 2, y = 0, w = 910, h = 30})
			Image_Select:FromUITex("ui\\Image\\Common\\TempBox.UITex", 6)
			Image_Select:SetImageType(10)
			Image_Select:SetAlpha(200)
			Image_Select:Hide()

			-----显示日期
			local hour = data["hour"]
			local minute = data["minute"]
			local second = data["second"]

			local Text_Time = self:Append("Text", hIconViewContent, sformat("Text_Time_%d_1", i), {w = 120, h = 30, x  = 0, y = 2, text = "" , font = _font})
			Text_Time:SetHAlign(1)
			Text_Time:SetVAlign(1)
			Text_Time:SetText(sformat("%0.2d:%0.2d:%0.2d", hour, minute, second))

			----显示地点
			local dwMapID = Trade_Record:GetMapID()
			local szMapName = LR.Trim(Table_GetMapName(dwMapID))

			local Text_Location = self:Append("Text", hIconViewContent, sformat("Text_Location_%d_1", i), {w = 80, h = 30, x  = 120, y = 2, text = "" , font = _font})
			Text_Location:SetHAlign(1)
			Text_Location:SetVAlign(1)
			Text_Location:SetText(szMapName)

			local s1 = Text_Location:GetTextPosExtent(76)
			local s2 = Text_Location:GetTextLen()
			local s3 = ssub(szMapName, -8)
			if s2>4 then
				Text_Location:RegisterEvent(272)
				Text_Location:SetText(s3)
				Text_Location.OnEnter = function()
					Image_Hover:Show()
					local x, y = Text_Location:GetAbsPos()
					local w, h = Text_Location:GetSize()
					local szXml  = GetFormatText(szMapName, 18)
					OutputTip(szXml, 350, {x, y, w, h})
				end
				Text_Location.OnLeave = function()
					Image_Hover:Hide()
					HideTip()
				end
			end

			----显示类型
			local nType = Trade_Record:GetType()

			local Text_Type = self:Append("Text", hIconViewContent, sformat("Text_Type_%d_1", i), {w = 80, h = 30, x  = 200, y = 2, text = "" , font = _font})
			Text_Type:SetHAlign(1)
			Text_Type:SetVAlign(1)
			Text_Type:SetText(TRADE_TEXT[nType])

			----显示来源
			local Text_Source = self:Append("Text", hIconViewContent, sformat("Text_Source_%d_1", i), {w = 120, h = 30, x  = 280, y = 2, text = "" , font = _font})
			Text_Source:SetHAlign(1)
			Text_Source:SetVAlign(1)

			local Source = Trade_Record:GetSource()
			if Source.nType == TARGET.NPC then
				Text_Source:RegisterEvent(272)
				Text_Source:SetText(Source.szName)
				Text_Source.OnEnter = function()
					Image_Hover:Show()
					local x, y = Text_Source:GetAbsPos()
					local w, h = Text_Source:GetSize()
					local szXml = {}
					szXml[#szXml+1] = GetFormatText(sformat("%s\n", Source.szName), 18)
					if Source.szTitle then
						local szTitle = Source.szTitle or ""
						szXml[#szXml+1] = GetFormatText(sformat("[%s]\n", szTitle), 18)
					end
					szXml[#szXml+1] = GetFormatText(sformat("%s\n", szMapName), 18)
					OutputTip(tconcat(szXml), 350, {x, y, w, h})
				end
				Text_Source.OnLeave = function()
					Image_Hover:Hide()
					HideTip()
				end
			elseif Source.nType == TARGET.DOODAD then
				Text_Source:RegisterEvent(272)
				Text_Source:SetText(Source.szName)
				Text_Source.OnEnter = function()
					Image_Hover:Show()
					local x, y = Text_Source:GetAbsPos()
					local w, h = Text_Source:GetSize()
					local szXml = {}
					szXml[#szXml+1] = GetFormatText(sformat("%s\n", Source.szName), 18)
					szXml[#szXml+1] = GetFormatText("<DOODAD>\n", 18)
					if Source.szTitle then
						local szTitle = Source.szTitle
						if type(Source.szTitle) ==  "number" then
							szTitle = DOODAD_TYPETEXT[Source.szTitle] or ""
						end
						szXml[#szXml+1] = GetFormatText(sformat("[%s]\n", szTitle), 18)
					end
					szXml[#szXml+1] = GetFormatText(sformat("%s\n", szMapName), 18)
					OutputTip(tconcat(szXml), 350, {x, y, w, h})
				end
				Text_Source.OnLeave = function()
					Image_Hover:Hide()
					HideTip()
				end
			elseif Source.nType == TARGET.PLAYER then
				Text_Source:RegisterEvent(272)
				Text_Source:SetText(Source.szName)
				local dwForceID = Source.dwForceID or 0
				local r, g, b = LR.GetMenPaiColor(dwForceID)
				Text_Source:SetFontColor(r, g, b)
				Text_Source.OnEnter = function()
					Image_Hover:Show()
					local x, y = Text_Source:GetAbsPos()
					local w, h = Text_Source:GetSize()
					local dwForceID = Source.dwForceID or 0
					local szPath, nFrame = GetForceImage(dwForceID)
					local r, g, b = LR.GetMenPaiColor(dwForceID)
					local szXml = {}
					szXml[#szXml+1] = GetFormatImage(szPath, nFrame, 26, 26)
					szXml[#szXml+1] = GetFormatText(sformat("%s\n", Source.szName), 18, r, g, b)
					szXml[#szXml+1] = GetFormatText(sformat("%s\n", _L["<PLAYER>"]), 18)
					OutputTip(tconcat(szXml), 350, {x, y, w, h})
				end
				Text_Source.OnLeave = function()
					Image_Hover:Hide()
					HideTip()
				end
				Text_Source.OnClick = function()
					local menu = {}
					local dwID = Source.dwID
					local szName = Source.szName
					if IsCtrlKeyDown() then
						LR.EditBox_AppendLinkPlayer(szName)
					else
						InsertPlayerCommonMenu(menu, dwID, szName)
						if menu then
							local invite = menu[1].fnAction
							invite()
						end
					end
				end
			elseif Source.nType ==  TARGET.NO_TARGET and Trade_Record:GetType() ==  TRADE.GKP then
				Text_Source:RegisterEvent(272)
				Text_Source:SetText(Source.szName)
				Text_Source.OnEnter = function()
					Image_Hover:Show()
					local x, y = Text_Source:GetAbsPos()
					local w, h = Text_Source:GetSize()
					local szXml = {}
					szXml[#szXml+1] = GetFormatText(sformat("%s\n", Source.szName), 18)
					szXml[#szXml+1] = GetFormatText(sformat("%s\n", _L["<GKP>"]), 18)
					szXml[#szXml+1] = GetFormatText(sformat("%s\n", szMapName), 18)
					OutputTip(tconcat(szXml), 350, {x, y, w, h})
				end
				Text_Source.OnLeave = function()
					Image_Hover:Hide()
					HideTip()
				end
			end

			----显示内容
			local handle_content = self:Append("Handle", hIconViewContent, sformat("Handle_Content_%d_1", i), {x = 400, y = 2, w = 300, h = 28})
			handle_content:SetHandleStyle(3)
			handle_content:SetMinRowHeight(30)

			if nType == TRADE.SHOP_BUY or nType == TRADE.SHOP_SELL or nType ==  TRADE.RETURN or nType ==  TRADE.H_RETURN or nType ==  TRADE.LOOT or nType ==  TRADE.SHOP_RETURN
			or nType == TRADE.MAIL_GET or nType == TRADE.MAIL_PAY or nType == TRADE.MAIL_SEND
			then
				local t_item =  {}
				if nType == TRADE.SHOP_BUY or nType ==  TRADE.RETURN or nType ==  TRADE.H_RETURN or nType ==  TRADE.LOOT or nType ==  TRADE.SHOP_RETURN
				or nType == TRADE.MAIL_GET or nType == TRADE.MAIL_PAY
				then
					t_item = Trade_Record:GetItem_in() or {}
				elseif nType == TRADE.SHOP_SELL or nType == TRADE.MAIL_SEND then
					t_item = Trade_Record:GetItem_out() or {}
				end
				if next(t_item)~= nil then
					if nType ==  TRADE.SHOP_RETURN then
						self:Append("Text", handle_content, sformat("Text_content_%d_re", i), {h = 30, text = _L["Get:"] , font = _font})
					elseif nType ==  TRADE.MAIL_GET then
						self:Append("Text", handle_content, sformat("Text_content_%d_mailget", i), {h = 30, text = _L["Get Attachment:"] , font = _font})
					elseif nType ==  TRADE.MAIL_PAY then
						self:Append("Text", handle_content, sformat("Text_content_%d_mailpay", i), {h = 30, text = _L["Pay for Attachment:"] , font = _font})
					elseif nType ==  TRADE.MAIL_SEND then
						self:Append("Text", handle_content, sformat("Text_content_%d_mailsend", i), {h = 30, text = _L["Mail Items:"] , font = _font})
					end
				end
				for k = 1, #t_item, 1 do
					self:AddBoxItem(t_item[k], handle_content, sformat("%d_%d_%d", OrderTime, i, k), Image_Hover)
				end
			elseif nType == TRADE.TRADE then
				local t_item
				t_item = Trade_Record:GetItem_in()
				if next(t_item) ~=  nil then
					self:Append("Text", handle_content, sformat("Text_content_%d_1", i), {h = 30, text = _L["Get:"] , font = _font})
					for k = 1, #t_item, 1 do
						self:AddBoxItem(t_item[k], handle_content, sformat("%d_in_%d_%d", OrderTime, i, k), Image_Hover)
					end
					self:Append("Text", handle_content, sformat("Text_content_%d_3", i), {h = 30, text = "  \n" , font = _font})
				end
				t_item = Trade_Record:GetItem_out()
				if next(t_item) ~=  nil then
					self:Append("Text", handle_content, sformat("Text_content_%d_2", i), {h = 30, text = _L["Give:"] , font = _font})
					for k = 1, #t_item, 1 do
						self:AddBoxItem(t_item[k], handle_content, sformat("%d_out_%d_%d", OrderTime, i, k), Image_Hover)
					end
				end
			elseif nType == TRADE.AUCTION_SELL then
				local t_item
				t_item = Trade_Record:GetItem_out()
				if next(t_item) ~=  nil then
					self:Append("Text", handle_content, sformat("Text_content_%d_1", i), {h = 30, text = _L["Consignment:"] , font = _font})
					for k = 1, #t_item, 1 do
						self:AddBoxItem(t_item[k], handle_content, sformat("%d_in_%d_%d", OrderTime, i, k), Image_Hover)
					end
				end
			elseif nType == TRADE.AUCTION_BUY then
				local t_item
				t_item = Trade_Record:GetItem_in()
				if next(t_item) ~=  nil then
					self:Append("Text", handle_content, sformat("Text_content_%d_1", i), {h = 30, text = _L["You successfully bought"] , font = _font})
					for k = 1, #t_item, 1 do
						local szName = t_item[k].szName or ""
						self:Append("Text", handle_content, sformat("Text_content_%d_1", i), {h = 30, text = sformat("[%s] ", szName), font = 27})
					end
					self:Append("Text", handle_content, sformat("Text_content_%d_1", i), {h = 30, text = "！" , font = _font})
				end
			elseif nType == TRADE.AUCTION_SUCCESS then
				local t_item
				t_item = Trade_Record:GetItem_out()
				if next(t_item) ~=  nil then
					self:Append("Text", handle_content, sformat("Text_content_%d_1", i), {h = 30, text = _L["You consignment thing "] , font = _font})
					for k = 1, #t_item, 1 do
						local szName = t_item[k].szName or ""
						self:Append("Text", handle_content, sformat("Text_content_%d_1", i), {h = 30, text = sformat("[%s] ", szName) , font = 27})
					end
					self:Append("Text", handle_content, sformat("Text_content_%d_1", i), {h = 30, text = _L["sold out successful."] , font = _font})
				end
			elseif nType == TRADE.GKP then
				local t_item
				t_item = Trade_Record:GetItem_in()
				if next(t_item) ~=  nil then
					local Distributor = Trade_Record:GetDistributor()
					if Distributor.nType ==  TARGET.PLAYER then
						local text = self:Append("Text", handle_content, sformat("Text_content_%d_4", i), {h = 30, text = "" , font = _font})
						text:RegisterEvent(272)
						text:SprintfText("[%s] ", Distributor.szName)
						local dwForceID =  Distributor.dwForceID
						local r, g, b = LR.GetMenPaiColor(dwForceID)
						text:SetFontColor(r, g, b)

						text.OnEnter = function()
							Image_Hover:Show()
							local x, y = text:GetAbsPos()
							local w, h = text:GetSize()
							local dwForceID = Distributor.dwForceID or 0
							local szPath, nFrame = GetForceImage(dwForceID)
							local r, g, b = LR.GetMenPaiColor(dwForceID)
							local szXml = {}
							szXml[#szXml+1] = GetFormatImage(szPath, nFrame, 26, 26)
							szXml[#szXml+1] = GetFormatText(sformat("%s\n", Distributor.szName), 18, r, g, b)
							szXml[#szXml+1] = GetFormatText(sformat("%s\n", _L["<PLAYER>"]), 18)
							OutputTip(tconcat(szXml), 350, {x, y, w, h})
						end
						text.OnLeave = function()
							Image_Hover:Hide()
							HideTip()
						end

						text.OnClick = function()
							local menu = {}
							local dwID = Distributor.dwID
							local szName = Distributor.szName
							if IsCtrlKeyDown() then
								LR.EditBox_AppendLinkPlayer(szName)
							else
								InsertPlayerCommonMenu(menu, dwID, szName)
								if menu then
									local invite = menu[1].fnAction
									invite()
								end
							end
						end
					end
					self:Append("Text", handle_content, sformat("Text_content_%d_1", i), {h = 30, text = _L["Record "] , font = _font})
					for k = 1, #t_item, 1 do
						self:AddBoxItem(t_item[k], handle_content, sformat("%d_in_%d_%d", OrderTime, i, k), Image_Hover)
					end
					self:Append("Text", handle_content, sformat("Text_content_%d_2", i), {h = 30, text = _L["as"] , font = _font})
					local nMoney = Trade_Record:GetMoney() / 10000
					self:Append("Text", handle_content, sformat("Text_content_%d_3", i), {h = 30, text = nMoney , font = _font})
					local img = self:Append("Image", handle_content, sformat("Img_content_%d_4", i), {w = 24, h = 24})
					img:FromUITex("ui\\Image\\Common\\Money.UITex", 0)
					img:Show()
				end
			elseif nType == TRADE.QUEST then
				local t_item
				t_item = Trade_Record:GetItem_in()
				if next(t_item) ~=  nil then
					self:Append("Text", handle_content, sformat("Text_content_%d_QUEST_1", i), {h = 30, text = _L["Finish quest "] , font = _font})
					for k = 1, #t_item, 1 do
						local dwQuestID = t_item[k].nBookID
						local szQuestName = LR.GetQuestName(dwQuestID)
						local text = self:Append("Text", handle_content, sformat("Text_QUEST_%d_1", i), {h = 30, text = sformat("[%s] ", szQuestName), font = 27})
						text:RegisterEvent(272)
						text.OnEnter = function()
							Image_Hover:Show()
							local x, y = text:GetAbsPos()
							local w, h = text:GetSize()
							OutputQuestTip(dwQuestID, {x, y, w, h, }, false)
						end
						text.OnLeave = function()
							Image_Hover:Hide()
							HideTip()
						end
					end
				end
			end
			handle_content:FormatAllItemPos()
			local w, h = handle_content:GetAllItemSize()
			local w2, h2 = hIconViewContent:GetSize()
			if h>30 then
				local x = mceil(h/30)
				hIconViewContent:SetSize(w2, x*30)
				Image_Line:SetSize(w2, x*30)
				Image_Hover:SetSize(910, x*30)
				Image_Line2:SetSize(w2, x*30)
			end


			-----显示金额
			local MoneyContentHandle = self:Append("Handle", hIconViewContent, sformat("MoneyContentHandle_%d", i), {x = 700, y = 0, w = 200, h = 30})
			--MoneyContentHandle:SetHandleStyle(1)
			MoneyContentHandle:SetMinRowHeight(30)

			local Text_GoldBrick = self:Append("Text", MoneyContentHandle, sformat("Text_GoldBrick_%d", i), {w = 24, h = 30, x = 0 , text = "88" , font = _font})
			Text_GoldBrick:SetVAlign(1)
			Text_GoldBrick:SetHAlign(2)
			local Img_GoldBrick = self:Append("Animate", MoneyContentHandle, sformat("Img_GoldBrick_%d", i), {w = 24, h = 24, x = 24, })
			Img_GoldBrick:SetAnimate("ui\\Image\\Common\\Money.UITex", 41)
			Img_GoldBrick:Show()
			local Text_Gold = self:Append("Text", MoneyContentHandle, sformat("Text_Gold_%d", i), {w = 40, h = 30, x = 48 , text = "8888" , font = _font})
			Text_Gold:SetVAlign(1)
			Text_Gold:SetHAlign(2)
			local Img_Gold = self:Append("Image", MoneyContentHandle, sformat("Img_Gold_%d", i) , {w = 24, h = 24, x = 88 , })
			Img_Gold:FromUITex("ui\\Image\\Common\\Money.UITex", 0)
			Img_Gold:Show()
			local Text_Silver = self:Append("Text", MoneyContentHandle, sformat("Text_Gold_%d", i), {w = 24, h = 30, x = 112 , text = "88" , font = _font})
			Text_Silver:SetVAlign(1)
			Text_Silver:SetHAlign(2)
			local Img_Silver = self:Append("Image", MoneyContentHandle, sformat("Img_Gold_%d", i), {w = 24, h = 24, x = 136 , })
			Img_Silver:FromUITex("ui\\Image\\Common\\Money.UITex", 2)
			Img_Silver:Show()
			local Text_Copper = self:Append("Text", MoneyContentHandle, sformat("Text_Gold_%d", i), {w = 24, h = 30, x = 160 , text = "88" , font = _font})
			Text_Copper:SetVAlign(1)
			Text_Copper:SetHAlign(2)
			local Img_Copper	 = self:Append("Image", MoneyContentHandle, sformat("Img_Gold_%d", i), {w = 24, x = 184 , h = 24, })
			Img_Copper:FromUITex("ui\\Image\\Common\\Money.UITex", 1)
			Img_Copper:Show()

			local nMoney = Trade_Record:GetMoney()
			if Trade_Record:GetType() == TRADE.GKP then
				nMoney = 0
			end

			if not (Trade_Record:GetType() == TRADE.GKP or Trade_Record:GetType() == TRADE.AUCTION_SUCCESS) then
				nMoneyall = nMoneyall+nMoney
			end

			local minus = 1
			if nMoney < 0 then
				minus = -1
				nMoney = 0 - nMoney
			end

			local nGoldBrick, nGold, nSilver, nCopper =  LR.MoneyToGoldSilverAndCopper (nMoney)
			Text_GoldBrick:SetText(nGoldBrick)
			Text_Gold:SetText(nGold)
			Text_Silver:SetText(nSilver)
			Text_Copper:SetText(nCopper)

			if minus == -1 then
				Text_GoldBrick:SetFontColor(237, 28, 36)
				Text_Gold:SetFontColor(237, 28, 36)
				Text_Silver:SetFontColor(237, 28, 36)
				Text_Copper:SetFontColor(237, 28, 36)

				if nMoney >= 100000000 then
					Text_GoldBrick:SprintfText("- %d", nGoldBrick)
				elseif nMoney >= 10000 then
					Text_Gold:SprintfText("- %d", nGold)
				elseif nMoney >= 100 then
					Text_Silver:SprintfText("- %d", nSilver)
				else
					Text_Copper:SprintfText("- %d", nCopper)
				end
			end

			if nMoney >=  100000000 then
				-----
			elseif nMoney >=  10000 then
				Text_GoldBrick:Hide()
				Img_GoldBrick:Hide()
			elseif nMoney >=  100 then
				Text_GoldBrick:Hide()
				Img_GoldBrick:Hide()
				Text_Gold:Hide()
				Img_Gold:Hide()
			else
				Text_GoldBrick:Hide()
				Img_GoldBrick:Hide()
				Text_Gold:Hide()
				Img_Gold:Hide()
				Text_Silver:Hide()
				Img_Silver:Hide()
			end

			MoneyContentHandle:FormatAllItemPos()

			-----------鼠标操作
			hIconViewContent.OnEnter = function()
				Image_Hover:Show()
			end
			hIconViewContent.OnLeave = function()
				Image_Hover:Hide()
			end

			handle_content.OnEnter = function()
				Image_Hover:Show()
			end
			handle_content.OnLeave = function()
				Image_Hover:Hide()
			end

			MoneyContentHandle.OnEnter = function()
				Image_Hover:Show()
			end
			MoneyContentHandle.OnLeave = function()
				Image_Hover:Hide()
			end
		end
	end

	self:ShowMoneyAll(nMoneyall)

	LR_Acc_Trade_Panel:RefreshBTN_PAGE()
end

function LR_Acc_Trade_Panel:AddBoxItem(item, hwin, header_name, Image_Hover)
	local item = item
	local dwTabType = item.dwTabType
	local nVersion = item.nVersion
	local dwIndex = item.dwIndex
	local nStackNum = item.nStackNum or 0
	if dwTabType ==  0 and nVersion == 0 and dwIndex == 0 then	----GKP单独分配显示
		local nIconID = 582
		local box = self:Append("Box", hwin, sformat("Box_%s", header_name), {h = 26, w = 26, })
		box:SetObject(1)
		box:SetObjectIcon(nIconID)

		box.OnEnter = function()
			Image_Hover:Show()
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local szXml  = GetFormatText(item.szName, 0, 255, 128, 0)
			OutputTip(szXml, 350, {x, y, w, h})
		end

		box.OnLeave = function()
			Image_Hover:Hide()
			HideTip()
		end
		return
	end
	local iteminfo, _ntype = GetItemInfo(dwTabType, dwIndex)
	if iteminfo then
		local nUiId = iteminfo.nUiId
		local nIconID = Table_GetItemIconID(nUiId)
		local box = self:Append("Box", hwin, sformat("Box_%s", header_name), {h = 26, w = 26, })
		box:SetObject(1)
		box:SetObjectIcon(nIconID)

		if nStackNum>1 then
			self:Append("Text", hwin, sformat("Text_Num_%s", header_name), {h = 30, text = sformat("x %d ", nStackNum), font = _font})
		end

		box.OnEnter = function()
			Image_Hover:Show()
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			if iteminfo.nGenre == ITEM_GENRE.BOOK then
				if item.nBookID then
					local dwBookID, dwSegmentID = GlobelRecipeID2BookID(item.nBookID)
					OutputBookTipByID(dwBookID, dwSegmentID, {x, y, w, h, })
				end
			else
				OutputItemTip(UI_OBJECT_ITEM_INFO, nVersion, dwTabType, dwIndex, {x, y, w, h, })
			end
		end

		box.OnLeave = function()
			Image_Hover:Hide()
			HideTip()
		end
	end
end

function LR_Acc_Trade_Panel:ShowMoneyAll(nMoney)
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
	local nGoldBrick, nGold, nSilver, nCopper =  LR.MoneyToGoldSilverAndCopper (nMoney2)
	local Text_GoldBrick, Text_Gold, Text_Silver, Text_Copper = nil, nil, nil, nil
	if nMoney2 >=  100000000 then
		Text_GoldBrick = self:Append("Text", hHandle, "Text_GoldBrick_all" , {h = 30, text = nGoldBrick , font = _font})
		self:Append("Animate", hHandle, "Img_GoldBrick_all" , {w = 24, h = 24, image = "ui\\Image\\Common\\Money.UITex" , group = 41 })
		Text_Gold = self:Append("Text", hHandle, "Text_Gold_all" , {h = 30, text = nGold , font = _font})
		self:Append("Image", hHandle, "Img_Gold_all" , {w = 24, h = 24, image = "ui\\Image\\Common\\Money.UITex" , frame = 0  })
		Text_Silver = self:Append("Text", hHandle, "Text_Silver_all" , {h = 30, text = nSilver , font = _font})
		self:Append("Image", hHandle, "Img_Silver_all" , {w = 24, h = 24, image = "ui\\Image\\Common\\Money.UITex" , frame = 2  })
		Text_Copper = self:Append("Text", hHandle, "Text_Copper_all" , {h = 30, text = nCopper , font = _font})
		self:Append("Image", hHandle, "Img_Copper_all" , {w = 24, h = 24, image = "ui\\Image\\Common\\Money.UITex" , frame = 1  })
	elseif nMoney2>= 10000 then
		Text_Gold = self:Append("Text", hHandle, "Text_Gold_all" , {h = 30, text = nGold , font = _font})
		self:Append("Image", hHandle, "Img_Gold_all" , {w = 24, h = 24, image = "ui\\Image\\Common\\Money.UITex" , frame = 0  })
		Text_Silver = self:Append("Text", hHandle, "Text_Silver_all" , {h = 30, text = nSilver , font = _font})
		self:Append("Image", hHandle, "Img_Silver_all" , {w = 24, h = 24, image = "ui\\Image\\Common\\Money.UITex" , frame = 2  })
		Text_Copper = self:Append("Text", hHandle, "Text_Copper_all" , {h = 30, text = nCopper , font = _font})
		self:Append("Image", hHandle, "Img_Copper_all" , {w = 24, h = 24, image = "ui\\Image\\Common\\Money.UITex" , frame = 1  })
	elseif nMoney2>= 100 then
		Text_Silver = self:Append("Text", hHandle, "Text_Silver_all" , {h = 30, text = nSilver , font = _font})
		self:Append("Image", hHandle, "Img_Silver_all" , {w = 24, h = 24, image = "ui\\Image\\Common\\Money.UITex" , frame = 2  })
		Text_Copper = self:Append("Text", hHandle, "Text_Copper_all" , {h = 30, text = nCopper , font = _font})
		self:Append("Image", hHandle, "Img_Copper_all" , {w = 24, h = 24, image = "ui\\Image\\Common\\Money.UITex" , frame = 1  })
	else
		Text_Copper = self:Append("Text", hHandle, "Text_Copper_all" , {h = 30, text = nCopper , font = _font})
		self:Append("Image", hHandle, "Img_Copper_all" , {w = 24, h = 24, image = "ui\\Image\\Common\\Money.UITex" , frame = 1  })
	end
	if nMoney<0 then
		if Text_GoldBrick then Text_GoldBrick:SetFontColor(237, 28, 36) end
		if Text_Gold then Text_Gold:SetFontColor(237, 28, 36) end
		if Text_Silver then Text_Silver:SetFontColor(237, 28, 36) end
		if Text_Copper then Text_Copper:SetFontColor(237, 28, 36) end

		if nMoney2 >=  100000000 then Text_GoldBrick:SprintfText("- %s", Text_GoldBrick:GetText())
		elseif nMoney2 >=  10000 then Text_Gold:SprintfText("- %s", Text_Gold:GetText())
		elseif nMoney2 >=  100 then Text_Silver:SprintfText("- %s", Text_Silver:GetText())
		else Text_Copper:SprintfText("- %s", Text_Copper:GetText())
		end
	end
	hHandle:FormatAllItemPos()
end

function LR_Acc_Trade_Panel:Refresh()
	local frame = Station.Lookup("Normal/LR_Acc_Trade_Panel")
	if frame then
		local cc = self:Fetch("Scroll")
		if cc then
			self:ClearHandle(cc)
		end
		self:LoadItemBox(cc)
		cc:UpdateList()
	end
end

function LR_Acc_Trade_Panel:RefreshBTN_PAGE()
	local frame = Station.Lookup("Normal/LR_Acc_Trade_Panel")
	if not frame then
		return
	end
	local BTN_FIRST = self:Fetch("BTN_FIRST"):Enable(false)
	local BTN_PRE = self:Fetch("BTN_PRE"):Enable(false)
	local BTN_NEXT = self:Fetch("BTN_NEXT"):Enable(false)
	local BTN_LAST = self:Fetch("BTN_LAST"):Enable(false)
	local BTN_OK = self:Fetch("BTN_OK"):Enable(false)
	local TEXT_PAGE = self:Fetch("TEXT_PAGE"):SetText("")
	local EDIT_PAGE = self:Fetch("EDIT_PAGE"):SetText("0")

	if LR_Acc_Trade_Panel.Show_Type == OP1.THIS_LOGIN or LR_Acc_Trade_Panel.notByPage then
		return
	end
	if LR_Acc_Trade_Panel.nTotalPage > 1 then
		BTN_OK:Enable(true)
	end
	if LR_Acc_Trade_Panel.nTotalPage > 1 and LR_Acc_Trade_Panel.nPage > 1 then
		BTN_FIRST:Enable(true)
		BTN_PRE:Enable(true)
	end
	if LR_Acc_Trade_Panel.nTotalPage > 1 and LR_Acc_Trade_Panel.nPage < LR_Acc_Trade_Panel.nTotalPage then
		BTN_NEXT:Enable(true)
		BTN_LAST:Enable(true)
	end
	local szText = sformat(_L["Total %d record(s), total %d page(s)"], LR_Acc_Trade_Panel.nCount, LR_Acc_Trade_Panel.nTotalPage)
	TEXT_PAGE:SetText(szText)
	EDIT_PAGE:SetText(LR_Acc_Trade_Panel.nPage)
end
-------------------------------------------------------------
-- 创建插件
LR_Acc_Trade_ChooseDate_Panel = _G2.CreateAddon("LR_Acc_Trade_ChooseDate_Panel")
LR_Acc_Trade_ChooseDate_Panel.UserData = {
	Anchor = {s = "CENTER", r = "CENTER", x = 0, y = 0},
}

LR_Acc_Trade_ChooseDate_Panel:BindEvent("OnFrameDragEnd", "OnDragEnd")
LR_Acc_Trade_ChooseDate_Panel:BindEvent("OnFrameDestroy", "OnDestroy")
LR_Acc_Trade_ChooseDate_Panel:BindEvent("OnFrameKeyDown", "OnKeyDown")

local _now = GetCurrentTime()
local _date = TimeToDate(_now)
local now_year = _date.year
local now_month = _date.month
local now_day = _date.day
LR_Acc_Trade_ChooseDate_Panel.start_year = now_year
LR_Acc_Trade_ChooseDate_Panel.start_month = now_month
LR_Acc_Trade_ChooseDate_Panel.start_day = now_day
LR_Acc_Trade_ChooseDate_Panel.end_year = now_year
LR_Acc_Trade_ChooseDate_Panel.end_month = now_month
LR_Acc_Trade_ChooseDate_Panel.end_day = now_day

-- 窗体创建回调
function LR_Acc_Trade_ChooseDate_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")

	LR_Acc_Trade_ChooseDate_Panel.UpdateAnchor(this)
end

-- 事件回调
--/script ReloadUIAddon()
function LR_Acc_Trade_ChooseDate_Panel:OnEvents(event)
	if event == "UI_SCALED" then
		LR_Acc_Trade_ChooseDate_Panel.UpdateAnchor(this)
	end
end

function LR_Acc_Trade_ChooseDate_Panel.UpdateAnchor(frame)
	frame:SetPoint(LR_Acc_Trade_ChooseDate_Panel.UserData.Anchor.s, 0, 0, LR_Acc_Trade_ChooseDate_Panel.UserData.Anchor.r, LR_Acc_Trade_ChooseDate_Panel.UserData.Anchor.x, LR_Acc_Trade_ChooseDate_Panel.UserData.Anchor.y)
	frame:CorrectPos()
end
-- 窗体刷新回调
--~ LR_Acc_Trade_ChooseDate_Panel.OnUpdate = function()
--~ 	Output("OnUpdate")
--~ end

-- 窗体销毁回调
function LR_Acc_Trade_ChooseDate_Panel:OnDestroy()
	--
end

-- 窗体拖动回调
function LR_Acc_Trade_ChooseDate_Panel:OnDragEnd()
	--
end

function LR_Acc_Trade_ChooseDate_Panel:Init()
	local frame = self:Append("Frame", "LR_Acc_Trade_ChooseDate_Panel", {path = "interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AS_TradeChooseDate_Panel.ini"})
	frame:Lookup("", "Image_MainBg"):SetAlpha(220)

	local _now = GetCurrentTime()
	local _date = TimeToDate(_now)
	local _year = _date.year
	local _month = _date.month
	local _day = _date.day
	local hStartYear = self:Append("ComboBox", frame, "hStartYear", {w = 80, x = 20, y = 80, text = LR_Acc_Trade_ChooseDate_Panel.start_year })
	hStartYear:Enable(true)
	hStartYear.OnClick = function (m)
		for i = 2016, _year, 1 do
			m[#m+1] = {szOption = i, bMCheck = true, bCheck = true, bChecked = function() return LR_Acc_Trade_ChooseDate_Panel.start_year == i end,
				fnAction = function()
					LR_Acc_Trade_ChooseDate_Panel.start_year = i
					hStartYear:SetText(i)
				end
			}
		end
		PopupMenu(m)
	end

	local hStartMonth = self:Append("ComboBox", frame, "hStartMonth", {w = 40, x = 140, y = 80, text = LR_Acc_Trade_ChooseDate_Panel.start_month })
	hStartMonth:Enable(true)
	hStartMonth.OnClick = function (m)
		for i = 1, 12, 1 do
			m[#m+1] = {szOption = i, bMCheck = true, bCheck = true, bChecked = function() return LR_Acc_Trade_ChooseDate_Panel.start_month == i end,
				fnAction = function()
					LR_Acc_Trade_ChooseDate_Panel.start_month = i
					hStartMonth:SetText(i)
				end
			}
		end
		PopupMenu(m)
	end

	local hStartDay = self:Append("ComboBox", frame, "hStartDay", {w = 40, x = 220, y = 80, text = LR_Acc_Trade_ChooseDate_Panel.start_day })
	hStartDay:Enable(true)
	hStartDay.OnClick = function (m)
		for i = 1, 31, 1 do
			m[#m+1] = {szOption = i, bMCheck = true, bCheck = true, bChecked = function() return LR_Acc_Trade_ChooseDate_Panel.start_day == i end,
				fnAction = function()
					LR_Acc_Trade_ChooseDate_Panel.start_day = i
					hStartDay:SetText(i)
				end
			}
		end
		PopupMenu(m)
	end

	local hEndYear = self:Append("ComboBox", frame, "hEndYear", {w = 80, x = 20, y = 150, text = LR_Acc_Trade_ChooseDate_Panel.end_year })
	hEndYear:Enable(true)
	hEndYear.OnClick = function (m)
		for i = 2016, _year, 1 do
			m[#m+1] = {szOption = i, bMCheck = true, bCheck = true, bChecked = function() return LR_Acc_Trade_ChooseDate_Panel.end_year == i end,
				fnAction = function()
					LR_Acc_Trade_ChooseDate_Panel.end_year = i
					hEndYear:SetText(i)
				end
			}
		end
		PopupMenu(m)
	end
	local hEndMonth = self:Append("ComboBox", frame, "hEndMonth", {w = 40, x = 140, y = 150, text = LR_Acc_Trade_ChooseDate_Panel.end_month })
	hEndMonth:Enable(true)
	hEndMonth.OnClick = function (m)
		for i = 1, 12, 1 do
			m[#m+1] = {szOption = i, bMCheck = true, bCheck = true, bChecked = function() return LR_Acc_Trade_ChooseDate_Panel.end_month == i end,
				fnAction = function()
					LR_Acc_Trade_ChooseDate_Panel.end_month = i
					hEndMonth:SetText(i)
				end
			}
		end
		PopupMenu(m)
	end
	local hEndDay = self:Append("ComboBox", frame, "hEndDay", {w = 40, x = 220, y = 150, text = LR_Acc_Trade_ChooseDate_Panel.end_day })
	hEndDay:Enable(true)
	hEndDay.OnClick = function (m)
		for i = 1, 31, 1 do
			m[#m+1] = {szOption = i, bMCheck = true, bCheck = true, bChecked = function() return LR_Acc_Trade_ChooseDate_Panel.end_day == i end,
				fnAction = function()
					LR_Acc_Trade_ChooseDate_Panel.end_day = i
					hEndDay:SetText(i)
				end
			}
		end
		PopupMenu(m)
	end

	local tStartYear = self:Append("Text", frame, "tStartYear", {w = 5, h = 30, x = 110, y = 78, text = _L["Year"], font = 22})
	local tStartMonth = self:Append("Text", frame, "tStartMonth", {w = 5, h = 30, x = 190, y = 78, text = _L["Month"], font = 22})
	local tStartDay = self:Append("Text", frame, "tStartDay", {w = 5, h = 30, x = 270, y = 78, text = _L["Day"], font = 22})
	local tEndYear = self:Append("Text", frame, "tEndYear", {w = 5, h = 30, x = 110, y = 148, text = _L["Year"], font = 22})
	local tEndMonth = self:Append("Text", frame, "tEndMonth", {w = 5, h = 30, x = 190, y = 148, text = _L["Month"], font = 22})
	local tEndDay = self:Append("Text", frame, "tEndDay", {w = 5, h = 30, x = 270, y = 148, text = _L["Day"], font = 22})
	local tStartTime = self:Append("Text", frame, "tStartYear", {w = 5, h = 30, x = 20, y = 45, text = _L["Start Time"], font = 22})
	local tEndTime = self:Append("Text", frame, "tStartYear", {w = 5, h = 30, x = 20, y = 115, text = _L["End Time"], font = 22})

	---Begin/Stop button
	local Wnd_CopyBTN =	self:Append("Window", frame, "Wnd_CopyBTN", {w = 240, h = 40, x = 60, y = 200, })
	--创建一个按钮
	local button1 = self:Append("Button", Wnd_CopyBTN, "button1", {text = _L["Yes"] , x = 0, y = 0, w = 95, h = 36})
	--绑定按钮点击事件
	button1.OnClick = function()
		local Scroll = LR_Acc_Trade_Panel:Fetch("Scroll")
		if Scroll then
			LR_Acc_Trade_Panel.Show_Type = OP1.HISTORY
			LR_AS_Trade.LoadData(OP1.HISTORY)
			LR_Acc_Trade_Panel:ClearHandle(Scroll)
			LR_Acc_Trade_Panel:LoadItemBox(Scroll)
			Scroll:UpdateList()
		end
	end
	local button2 = self:Append("Button", Wnd_CopyBTN, "button2", {text = _L["Cancle"], x = 110, y = 0, w = 95, h = 36})
	button2.OnClick = function()
		LR_Acc_Trade_ChooseDate_Panel:Open()
	end

	LR.AppendAbout(LR_Acc_Trade_ChooseDate_Panel, frame)
end

-- 界面创建
function LR_Acc_Trade_ChooseDate_Panel:Open()
	local frame = self:Fetch("LR_Acc_Trade_ChooseDate_Panel")
	if frame then
		self:Destroy(frame)
	else
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end


----------------------------------------------
local _Hook = {}
AH_MailBank = AH_MailBank or {}
AH_MailBank.HookMailPanel = AH_MailBank.HookMailPanel or function() end
_Hook.HookMailPanel = AH_MailBank.HookMailPanel
AH_MailBank.HookMailPanel = function()
	LR.DelayCall(200, function()
		_Hook.HookMailPanel()
	end)
end

local _option_time = 0
function LR_AS_Trade.ON_FRAME_CREATE()
	local frame = arg0
	local szName = frame:GetName()

	if szName == "MailPanel" then
		LR_Acc_Trade.OpenMailPanel()
	elseif szName ==  "AuctionPanel" then
		LR_Acc_Trade.GetItemInBag()
	elseif szName == "OptionPanel" then
		if LR_AS_Trade.UsrData.ShowMoneyChangeLog then
			if GetTickCount() - _option_time > 10 * 1000 then
				_option_time = GetTickCount()
				LR_AS_Trade.OutPutMoneyChange()
			end
		end
	end
end

LR.RegisterEvent("ON_FRAME_CREATE", function() LR_AS_Trade.ON_FRAME_CREATE() end)
