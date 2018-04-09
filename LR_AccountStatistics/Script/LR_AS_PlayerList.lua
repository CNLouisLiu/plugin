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
-------------------------------------------------------------
local _C = {}

function _C.GetSelfData()
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local data = {
		szKey = szKey,
		dwID = me.dwID,
		szName = me.szName,
		nLevel = me.nLevel,
		dwForceID = me.dwForceID,
		loginArea = loginArea,
		loginServer = loginServer,
		realArea = realArea,
		realServer = realServer,
	}
	return data
end

function _C.SaveData(DB)
	if not LR_AS_Base.UsrData.bRecord then
		return
	end
	local v = _C.GetSelfData()
	local DB_REPLACE = DB:Prepare("REPLACE INTO player_list ( szKey, dwID, szName, nLevel, dwForceID, loginArea, loginServer, realArea, realServer ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ? )")
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(unpack(g2d({ v.szKey, v.dwID, v.szName, v.nLevel, v.dwForceID, v.loginArea, v.loginServer, v.realArea, v.realServer })))
	DB_REPLACE:Execute()
end

function _C.LoadData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM player_list WHERE szKey IS NOT NULL ORDER BY nLevel DESC, dwForceID ASC, szName ASC")
	local data = d2g(DB_SELECT:GetAll())
	local AllUsrList = {}
	for k, v in pairs(data) do
		AllUsrList[v.szKey] = v
	end
	local myself = _C.GetSelfData()
	AllUsrList[myself.szKey] = clone(myself)
	LR_AS_Data.AllPlayerList = clone(AllUsrList)
end

--×¢²áÄ£¿é
LR_AS_Module.PlayerList = {}
LR_AS_Module.PlayerList.SaveData = _C.SaveData
LR_AS_Module.PlayerList.LoadData = _C.LoadData
LR_AS_Module.PlayerList.FIRST_LOADING_END = _C.LoadData




