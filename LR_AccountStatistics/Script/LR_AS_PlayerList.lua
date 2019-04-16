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
local DATA2BSAVE = {}

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

function _C.PrepareData()
	DATA2BSAVE = _C.GetSelfData()
end

function _C.SaveData(DB)
	local v = clone(DATA2BSAVE) or {}
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

function _C.RepairDB(DB)
	--导入数据
	_C.LoadData(DB)
	local AllPlayerList = clone(LR_AS_Data.AllPlayerList)
	--修复 szKey 为""的数据
	if AllPlayerList[""] then
		if AllPlayerList[""].dwID and AllPlayerList[""].dwID ~= 0 and AllPlayerList[""].realArea and LR.Trim(AllPlayerList[""].realArea) ~= "" and AllPlayerList[""].realServer and AllPlayerList[""].realServer ~= "" then
			local szKey = sformat("%s_%s_%d", AllPlayerList[""].realArea, AllPlayerList[""].realServer, AllPlayerList[""].dwID)
			AllPlayerList[szKey] = clone(AllPlayerList[""])
			AllPlayerList[""] = nil
		end
	end
	--修复NULL数据，用默认替代，如果szKey 不规范，则根据realarea/realServer/dwID修复，若realarea/realServer/dwID其中有不规范(空或者"")的，放弃这条数据
	--
	local all_data = {}
	local check01 = function(value)
		if not value or LR.Trim(value) == "" then
			return false
		else
			return true
		end
	end
	local value1 = function(value, default)
		return value and value ~= "" and value or default
	end
	for szKey, v in pairs(AllPlayerList) do
		local flag = true
		local key = szKey
		local _s, _e, area, server, id = sfind(szKey, "(.+)_(.+)_(%d+)")
		if not _s then
			if not (check01(v.realArea) and check01(v.realServer) and check01(v.dwID)) then
				flag = false
			else
				key = sformat("%s_%s_%d", v.realArea, v.realServer, v.dwID)
			end
		end
		if flag then
			local data = {}
			data.szKey = key
			data.dwID = value1(v.dwID, 0)
			data.szName = value1(v.szName, sformat("PLAYER#%d", data.dwID))
			data.nLevel = value1(v.nLevel, 1)
			data.dwForceID = value1(v.dwForceID, 0)
			data.loginArea = value1(v.loginArea, area)
			data.loginServer = value1(v.loginServer, server)
			data.realArea = value1(v.realArea, area)
			data.realServer = value1(v.realServer, server)
			all_data[key] = clone(data)
		end
	end

	--先清除数据库
	local DB_DELETE = DB:Prepare("DELETE FROM player_list")
	DB_DELETE:Execute()
	--插入数据
	local DB_REPLACE = DB:Prepare("REPLACE INTO player_list ( szKey, dwID, szName, nLevel, dwForceID, loginArea, loginServer, realArea, realServer ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ? )")
	for k, v in pairs(all_data) do
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(unpack(g2d({ v.szKey, v.dwID, v.szName, v.nLevel, v.dwForceID, v.loginArea, v.loginServer, v.realArea, v.realServer })))
		DB_REPLACE:Execute()
	end
	LR_AS_Data.AllPlayerList = clone(all_data)
end

--注册模块
LR_AS_Module.PlayerList = {}
LR_AS_Module.PlayerList.PrepareData = _C.PrepareData
LR_AS_Module.PlayerList.SaveData = _C.SaveData
LR_AS_Module.PlayerList.LoadData = _C.LoadData
LR_AS_Module.PlayerList.FIRST_LOADING_END = _C.LoadData
LR_AS_Module.PlayerList.RepairDB = _C.RepairDB




