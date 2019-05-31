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
		hash01 = LR.GetAccountCode(),
		hash02 = LR.GetUserCode(),
		--
		nCurrentStamina = me.nCurrentStamina,
		nMaxStamina = me.nMaxStamina,
	}
	--将自己的数据放入全局变量表
	LR_AS_Data.AllPlayerList[szKey] = clone(data)
	LR_AS_Data.All_Stamina[data.hash01] = LR_AS_Data.All_Stamina[data.hash01] or {}
	LR_AS_Data.All_Stamina[data.hash01][sformat("%s_%s", realArea, realServer)] = {nCurrentStamina = data.nCurrentStamina, nMaxStamina = data.nMaxStamina, SaveTime = GetCurrentTime()}
	--返回数据
	return data
end

function _C.PrepareData()
	DATA2BSAVE = _C.GetSelfData()
end

function _C.SaveData(DB)
	local v = clone(DATA2BSAVE) or {}
	local DB_REPLACE = DB:Prepare("REPLACE INTO player_list ( szKey, dwID, szName, nLevel, dwForceID, loginArea, loginServer, realArea, realServer, hash01, hash02 ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )")
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(unpack(g2d({ v.szKey, v.dwID, v.szName, v.nLevel, v.dwForceID, v.loginArea, v.loginServer, v.realArea, v.realServer, v.hash01, v.hash02 })))
	DB_REPLACE:Execute()
	--
	local DB_REPLACE2 = DB:Prepare("REPLACE INTO schema_stamina_data ( hash01, hash02, nCurrentStamina, nMaxStamina, SaveTime ) VALUES ( ?, ?, ?, ?, ? )")
	DB_REPLACE2:ClearBindings()
	DB_REPLACE2:BindAll(unpack(g2d({ v.hash01, sformat("%s_%s", v.realArea, v.realServer), v.nCurrentStamina, v.nMaxStamina, GetCurrentTime() })))
	DB_REPLACE2:Execute()
end

function _C.LoadData(DB)
	--载入所有人物的列表
	local DB_SELECT = DB:Prepare("SELECT * FROM player_list WHERE szKey IS NOT NULL ORDER BY nLevel DESC, dwForceID ASC, szName ASC")
	local data = d2g(DB_SELECT:GetAll())
	local AllPlayerList = {}
	for k, v in pairs(data) do
		AllPlayerList[v.szKey] = v
	end
	LR_AS_Data.AllPlayerList = clone(AllPlayerList)
	--载入所有账号的精力体力信息
	local DB_SELECT2 = DB:Prepare("SELECT * FROM schema_stamina_data WHERE hash01 IS NOT NULL AND hash02 IS NOT NULL")
	local data2 = d2g(DB_SELECT2:GetAll())
	local All_Stamina = {}
	for k, v in pairs(data2) do
		All_Stamina[v.hash01] = All_Stamina[v.hash01] or {}
		All_Stamina[v.hash01][v.hash02] = {nCurrentStamina = v.nCurrentStamina, nMaxStamina = v.nMaxStamina, SaveTime = v.SaveTime}
	end
	LR_AS_Data.All_Stamina = clone(All_Stamina)
	--将当前账号的信息以及账号信息放入共享数据
	_C.GetSelfData()
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




