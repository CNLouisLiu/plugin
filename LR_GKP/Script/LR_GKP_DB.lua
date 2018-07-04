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
LR_GKP_DB = {}

--[[
账单名称：电信一区_红尘寻梦_2017_12_24_15_27_szPlayerName
]]
local schema_bill_data = {
	name = "bill_data",
	version = "20180620",
	data = {
		{name = "szName", 	sql = "szName VARCHAR(100)"},		--主键
		{name = "hash", 	sql = "hash VARCHAR(100)"},		--主键
		{name = "szArea", 	sql = "szArea VARCHAR(40)"},
		{name = "szServer", 	sql = "szServer VARCHAR(40)"},
		{name = "nCreateTime", sql = "nCreateTime INTEGER DEFAULT(0)"},
		{name = "szBossData", sql = "szBossData VARCHAR(9999)"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szName )"},
}

--[[
szKey：nTime_dwTabType_nIndex_dwItemID
]]
local schema_trade_data = {
	name = "trade_data",
	version = "20180621",
	data = {
		{name = "szKey", sql = "szKey VARCHAR(150)"},		--主键
		{name = "hash", 	sql = "hash VARCHAR(150)"},
		{name = "szName", 	sql = "szName VARCHAR(60)"},
		{name = "dwTabType", sql = "dwTabType INTEGER DEFAULT(0)"},
		{name = "dwIndex", sql = "dwIndex INTEGER DEFAULT(0)"},
		{name = "nBookID", sql = "nBookID INTEGER DEFAULT(0)"},
		{name = "nStackNum", sql = "nStackNum INTEGER DEFAULT(0)"},
		{name = "szArea", 	sql = "szArea VARCHAR(40)"},
		{name = "szServer", 	sql = "szServer VARCHAR(40)"},
		{name = "dwMapID", 	sql = "dwMapID INTEGER DEFAULT(0)"},
		{name = "nCopyIndex", 	sql = "nCopyIndex INTEGER DEFAULT(0)"},
		{name = "nGold", 	sql = "nGold INTEGER DEFAULT(0)"},
		{name = "nSilver", 	sql = "nSilver INTEGER DEFAULT(0)"},
		{name = "nCopper", 	sql = "nCopper INTEGER DEFAULT(0)"},
		{name = "szDistributorName", 	sql = "szDistributorName VARCHAR(40)"},
		{name = "dwDistributorID", 	sql = "dwDistributorID INTEGER DEFAULT(0)"},
		{name = "dwDistributorForceID", 	sql = "dwDistributorForceID INTEGER DEFAULT(0)"},
		{name = "szPurchaserName", 	sql = "szPurchaserName VARCHAR(40)"},
		{name = "dwPurchaserID", 	sql = "dwPurchaserID INTEGER DEFAULT(0)"},
		{name = "dwPurchaserForceID", 	sql = "dwPurchaserForceID INTEGER DEFAULT(0)"},
		{name = "nOperationType", 	sql = "nOperationType INTEGER DEFAULT(0)"},
		{name = "szSourceName", 	sql = "szSourceName VARCHAR(40)"},
		{name = "nCreateTime", sql = "nCreateTime INTEGER DEFAULT(0)"},
		{name = "nSaveTime", sql = "nSaveTime INTEGER DEFAULT(0)"},
		{name = "szBelongBill", 	sql = "szBelongBill VARCHAR(100)"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( hash )"},
}

local schema_cash_data = {
	name = "cash_data",
	version = "20171226",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(100)"},		--主键
		{name = "szName", 	sql = "szName VARCHAR(40)"},
		{name = "dwID", 	sql = "dwID INTEGER DEFAULT(0)"},
		{name = "dwForceID", 	sql = "dwForceID INTEGER DEFAULT(0)"},
		{name = "my_szName", 	sql = "my_szName VARCHAR(40)"},
		{name = "my_dwID", 	sql = "my_dwID INTEGER DEFAULT(0)"},
		{name = "my_dwForceID", 	sql = "my_dwForceID INTEGER DEFAULT(0)"},
		{name = "hash", 	sql = "hash VARCHAR(100)"},
		{name = "szArea", 	sql = "szArea VARCHAR(40)"},
		{name = "szServer", 	sql = "szServer VARCHAR(40)"},
		{name = "dwMapID", 	sql = "dwMapID INTEGER DEFAULT(0)"},
		{name = "nCopyIndex", 	sql = "nCopyIndex INTEGER DEFAULT(0)"},
		{name = "nGold", 	sql = "nGold INTEGER DEFAULT(0)"},
		{name = "nCreateTime", sql = "nCreateTime INTEGER DEFAULT(0)"},
		{name = "szBelongBill", 	sql = "szBelongBill VARCHAR(100)"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local function CREATE_DB()
	LR.IniDB(SaveDataPath, DB_Name, {schema_bill_data, schema_trade_data, schema_cash_data})
end
CREATE_DB()
