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
local VERSION = "20190113"
-------------------------------------------------------------
LR_AS_DB = LR_AS_DB or {}
LR_AS_DEBUG = false
---------------------------------------------------------------
------数据库表项定义
---------------------------------------------------------------
---主数据库
local schema_group_list = {
	name = "group_list",
	version = VERSION,
	data = {
		{name = "groupID", 	sql = "groupID INTEGER"},		--主键
		{name = "szName", sql = "szName VARCHAR(30) DEFAULT('DEFAULT GROUP')"},
		{name = "SaveTime", 	sql = "SaveTime INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( groupID )"},
}

local schema_player_group = {
	name = "player_group",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "groupID", sql = "groupID INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_player_list = {
	name = "player_list",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "dwID", 	sql = "dwID INTEGER DEFAULT(0)"},
		{name = "szName", sql = "szName VARCHAR(20) DEFAULT('user_name')"},
		{name = "nLevel", sql = "nLevel INTEGER DEFAULT(0)"},
		{name = "dwForceID", sql = "dwForceID INTEGER DEFAULT(0)"},
		{name = "loginArea", sql = "loginArea VARCHAR(20) DEFAULT('')"},
		{name = "loginServer", sql = "loginServer VARCHAR(20) DEFAULT('')"},
		{name = "realArea", sql = "realArea VARCHAR(20) DEFAULT('')"},
		{name = "realServer", sql = "realServer VARCHAR(20) DEFAULT('')"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_player_info = {
	name = "player_info",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "nGold", 	sql = "nGold INTEGER DEFAULT(0)"},
		{name = "nSilver", 	sql = "nSilver INTEGER DEFAULT(0)"},
		{name = "nCopper", 	sql = "nCopper INTEGER DEFAULT(0)"},
		{name = "JianBen", 	sql = "JianBen INTEGER DEFAULT(0)"},
		{name = "BangGong", 	sql = "BangGong INTEGER DEFAULT(0)"},
		{name = "XiaYi", 	sql = "XiaYi INTEGER DEFAULT(0)"},
		{name = "WeiWang", 	sql = "WeiWang INTEGER DEFAULT(0)"},
		{name = "ZhanJieJiFen", 	sql = "ZhanJieJiFen INTEGER DEFAULT(0)"},
		{name = "ZhanJieDengJi", 	sql = "ZhanJieDengJi INTEGER DEFAULT(0)"},
		{name = "MingJianBi", 	sql = "MingJianBi INTEGER DEFAULT(0)"},
		{name = "szTitle", sql = "szTitle VARCHAR(20) DEFAULT('')"},
		{name = "nCurrentTrainValue", 	sql = "nCurrentTrainValue INTEGER DEFAULT(0)"},
		{name = "nCamp", 	sql = "nCamp INTEGER DEFAULT(0)"},
		{name = "szTongName", sql = "szTongName VARCHAR(20) DEFAULT('')"},
		{name = "remainJianBen", 	sql = "remainJianBen INTEGER DEFAULT(0)"},
		{name = "nVigor", 	sql = "nVigor INTEGER DEFAULT(0)"},			--100级新版精力
		{name = "nMaxVigor", 	sql = "nMaxVigor INTEGER DEFAULT(10000)"},			--100级新版精力
		{name = "nVigorRemainSpace", 	sql = "nVigorRemainSpace INTEGER DEFAULT(3000)"},			--100级新版精力
		{name = "SaveTime", sql = "SaveTime INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_exam_data = {
	name = "exam_data",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "ShengShi", 	sql = "ShengShi INTEGER DEFAULT(0)"},
		{name = "HuiShi", 	sql = "HuiShi INTEGER DEFAULT(0)"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_richang_data = {
	name = "richang_data",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "DA", 	sql = "DA TEXT DEFAULT('{}')" },
		{name = "GONG", 	sql = "GONG TEXT DEFAULT('{}')"},
		{name = "CHA", 	sql = "CHA TEXT DEFAULT('{}')"},
		{name = "QIN", 	sql = "QIN TEXT DEFAULT('{}')"},
		{name = "JU", 	sql = "JU TEXT DEFAULT('{}')"},
		{name = "JING", 	sql = "JING TEXT DEFAULT('{}')"},
		{name = "MEI", 	sql = "MEI TEXT DEFAULT('{}')"},
		{name = "CAI", 	sql = "CAI TEXT DEFAULT('{}')"},
		{name = "XUN", 	sql = "XUN TEXT DEFAULT('{}')"},
		{name = "TU", 	sql = "TU TEXT DEFAULT('{}')"},
		{name = "MI", 	sql = "MI TEXT DEFAULT('{}')"},
		{name = "ZHENYINGRICHANG", 	sql = "ZHENYINGRICHANG TEXT DEFAULT('{}')"},
		{name = "HUIGUANG", 	sql = "HUIGUANG TEXT DEFAULT('{}')"},
		{name = "HUASHAN", 	sql = "HUASHAN TEXT DEFAULT('{}')"},
		{name = "LONGMENJUEJING", 	sql = "LONGMENJUEJING TEXT DEFAULT('{}')"},
		{name = "LUOYANGSHENBING", 	sql = "LUOYANGSHENBING TEXT DEFAULT('{}')"},
		{name = "CUSTOM_QUEST", 	sql = "CUSTOM_QUEST TEXT DEFAULT('[]')"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_richang_clear_time = {
	name = "richang_clear_time",
	version = VERSION,
	data = {
		{name = "szName", 	sql = "szName VARCHAR(60)"},		--主键
		{name = "nTime", 	sql = "nTime INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szName )"},
}

local schema_fb_data = {
	name = "fb_data",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "fb_data", sql = "fb_data TEXT DEFAULT('[]')"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_qiyu_data = {
	name = "qiyu_data",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "qiyu_data", sql = "qiyu_data TEXT DEFAULT('[]')"},
		{name = "qiyu_achievement", sql = "qiyu_achievement TEXT DEFAULT('[]')"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_bookrd_data = {
	name = "bookrd_data",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "bookrd_data", sql = "bookrd_data TEXT DEFAULT('[]')"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_bag_item_data = {
	name = "bag_item_data",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "szName", 	sql = "szName VARCHAR(60) DEFAULT('[]')"},
		{name = "belong", 	sql = "belong VARCHAR(60)"},		--主键
		{name = "dwTabType", 	sql = "dwTabType INTEGER DEFAULT(0)"},
		{name = "dwIndex", 	sql = "dwIndex INTEGER DEFAULT(0)"},
		{name = "nUiId", 	sql = "nUiId INTEGER DEFAULT(0)"},
		{name = "nBookID", 	sql = "nBookID INTEGER DEFAULT(0)"},
		{name = "nGenre", 	sql = "nGenre INTEGER DEFAULT(0)"},
		{name = "nSub", 	sql = "nSub INTEGER DEFAULT(0)"},
		{name = "nDetail", 	sql = "nDetail INTEGER DEFAULT(0)"},
		{name = "nQuality", 	sql = "nQuality INTEGER DEFAULT(0)"},
		{name = "nStackNum", 	sql = "nStackNum INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey, belong )"},
}

local schema_bank_item_data = {
	name = "bank_item_data",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "szName", 	sql = "szName VARCHAR(60) DEFAULT('[]')"},
		{name = "belong", 	sql = "belong VARCHAR(60)"},		--主键
		{name = "dwTabType", 	sql = "dwTabType INTEGER DEFAULT(0)"},
		{name = "dwIndex", 	sql = "dwIndex INTEGER DEFAULT(0)"},
		{name = "nUiId", 	sql = "nUiId INTEGER DEFAULT(0)"},
		{name = "nBookID", 	sql = "nBookID INTEGER DEFAULT(0)"},
		{name = "nGenre", 	sql = "nGenre INTEGER DEFAULT(0)"},
		{name = "nSub", 	sql = "nSub INTEGER DEFAULT(0)"},
		{name = "nDetail", 	sql = "nDetail INTEGER DEFAULT(0)"},
		{name = "nQuality", 	sql = "nQuality INTEGER DEFAULT(0)"},
		{name = "nStackNum", 	sql = "nStackNum INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey, belong )"},
}

local schema_mail_item_data = {
	name = "mail_item_data",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "szName", 	sql = "szName VARCHAR(60)"},
		{name = "belong", 	sql = "belong VARCHAR(60)"},		--主键
		{name = "dwTabType", 	sql = "dwTabType INTEGER DEFAULT(0)"},
		{name = "dwIndex", 	sql = "dwIndex INTEGER DEFAULT(0)"},
		{name = "nUiId", 	sql = "nUiId INTEGER DEFAULT(0)"},
		{name = "nBookID", 	sql = "nBookID INTEGER DEFAULT(0)"},
		{name = "nGenre", 	sql = "nGenre INTEGER DEFAULT(0)"},
		{name = "nSub", 	sql = "nSub INTEGER DEFAULT(0)"},
		{name = "nDetail", 	sql = "nDetail INTEGER DEFAULT(0)"},
		{name = "nQuality", 	sql = "nQuality INTEGER DEFAULT(0)"},
		{name = "nStackNum", 	sql = "nStackNum INTEGER DEFAULT(0)"},
		{name = "nBelongMailID",	sql = "nBelongMailID TEXT"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey, belong )"},
}

local schema_mail_data = {
	name = "mail_data",
	version = VERSION,
	data = {
		{name = "nMailID", 	sql = "nMailID INTEGER"},	--主键
		{name = "belong", 	sql = "belong VARCHAR(60)"},		--主键
		{name = "szSenderName", sql = "szSenderName VARCHAR(60)"},
		{name = "szTitle", 	sql = "szTitle TEXT"},
		{name = "szContent", 	sql = "szContent TEXT"},
		{name = "nType", 	sql = "nType INTEGER DEFAULT(0)"},
		{name = "nEndTime", 	sql = "nEndTime INTEGER DEFAULT(0)"},
		{name = "item_record", 	sql = "item_record TEXT DEFAULT('[]')"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( nMailID, belong )"},
}

local schema_mail_receive_time = {
	name = "mail_receive_time",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "nTime", 	sql = "nTime INTEGER DEFAULT(0)"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_achievement_data = {
	name = "achievement_data",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(80)"},		--主键
		{name = "achievement_data", 	sql = "achievement_data TEXT DEFAULT('[]')"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_equipment_data = {
	name = "equipment_data",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(80)"},		--主键
		{name = "nSuitIndex", 	sql = "nSuitIndex TEXT"},
		{name = "equipment_data", 	sql = "equipment_data TEXT DEFAULT('[]')"},
		{name = "score", 	sql = "score TEXT DEFAULT('[]')"},
		{name = "char_infomoreV2", 	sql = "char_infomoreV2 TEXT DEFAULT('[]')"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey, nSuitIndex )"},
}

local schema_wltj_data = {
	name = "wltj_data",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(80)"},		--主键
		{name = "tCommon", 	sql = "tCommon TEXT DEFAULT('[]')"},
		{name = "t5R", 	sql = "t5R TEXT DEFAULT('[]')"},
		{name = "t10R", 	sql = "t10R TEXT DEFAULT('[]')"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

--收支交易数据库
local schema_trade_data = {
	name = "trade_data",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(80)"},		--主键
		{name = "nTime", 	sql = "nTime INTEGER DEFAULT(0)"},		--主键
		{name = "OrderTime", sql = "OrderTime INTEGER DEFAULT(0)"},
		{name = "nMoney", 	sql = "nMoney TEXT DEFAULT('[]')"},
		{name = "nItem_in", 	sql = "nItem_in TEXT DEFAULT('[]')"},
		{name = "nItem_out", 	sql = "nItem_out TEXT DEFAULT('[]')"},
		{name = "dwMapID", 	sql = "dwMapID INTEGER DEFAULT(0)"},
		{name = "nType", 	sql = "nType INTEGER DEFAULT(0)"},
		{name = "Distributor", 	sql = "Distributor TEXT DEFAULT('[]')"},
		{name = "Source", 	sql = "Source TEXT DEFAULT('[]')"},
		{name = "tDate", 	sql = "tDate TEXT"},
		{name = "nDate", 	sql = "nDate TEXT"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}
local schema_trade_data_temp = clone(schema_trade_data)
schema_trade_data_temp.name = "trade_data_temp"
-----------------------------------------------------
function LR_AS_DB.Convert_Old_Version(option)
	local path = sformat("%s\\%s", SaveDataPath, db_name)
	local DB = LR.OpenDB(path, "AS_DB_CONVERT_OLD_VERSION_E2CD230AE8816652267E6E1D6E8A52E2")
	if option == "player_info" then
		local path = sformat("%s\\UserList.dat",SaveDataPath)
		if IsFileExist(sformat("%s.jx3dat", path)) then
			local data = LoadLUAData(path) or {}
			if data.data then
				local DB_W  = DB:Prepare("REPLACE INTO player_info (szKey, dwID, szName, nLevel, dwForceID, nGold, nSilver, nCopper, JianBen, BangGong, XiaYi, WeiWang, ZhanJieJiFen, ZhanJieDengJi, MingJianBi, szTitle, nCurrentStamina, nMaxStamina, nCurrentThew, nMaxThew, nCurrentTrainValue, nCamp, szTongName, remainJianBen, loginArea, loginServer, realArea, realServer, SaveTime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
				for k, v in pairs(data.data) do
					local src = "%s\\%s\\%s\\%s\\Information_%s.dat"
					local path2 = sformat(src, SaveDataPath, v.realArea, v.realServer, v.szName, v.szName)
					local data2 = LoadLUAData(path2) or {}
					if data2.data then
						local v2 = data2.data
						local szKey = (sformat("%s_%s_%d", v2.realArea, v2.realServer, v2.dwID))
						DB_W:ClearBindings()
						--Output(szKey, v2.dwID, (v2.szName), v2.nLevel, v2.dwForceID, v2.nMoney, v2.JianBen, v2.BangGong, v2.XiaYi, v2.WeiWang, v2.ZhanJieJiFen, v2.ZhanJieDengJi, v2.MingJianBi, v2.szTitle, v2.nCurrentStamina, v2.nMaxStamina, v2.nCurrentThew, v2.nMaxThew, v2.nCurrentTrainValue, v2.nCamp, v2.dwTongID, v2.szTongName, v2.remainJianBen, v2.Area, v2.Server, v2.realArea, v2.realServer, v2.groupID)
						DB_W:BindAll(szKey, v2.dwID, (v2.szName), v2.nLevel, v2.dwForceID, mfloor(v2.nMoney / 10000), mfloor((v2.nMoney % 10000) / 100), mfloor(v2.nMoney % 100),  v2.JianBen, v2.BangGong, v2.XiaYi, v2.WeiWang, v2.ZhanJieJiFen, v2.ZhanJieDengJi, v2.MingJianBi, v2.szTitle, v2.nCurrentStamina, v2.nMaxStamina, v2.nCurrentThew, v2.nMaxThew, v2.nCurrentTrainValue, v2.nCamp, v2.szTongName, v2.remainJianBen, v2.Area, v2.Server, v2.realArea, v2.realServer, v2.SaveTime)
						DB_W:Execute()
					end
				end
			end
		end
	end

	LR.CloseDB(DB)
end

function LR_AS_DB.ImportPlayerListOld()
	local ImportPlayerListOld = function()
		LR_AS_DB.Convert_Old_Version("player_info")
	end

	local msg = {
		szMessage = _L["Are you sure to import playerlist ?"],
		szName = "import playerlist",
		fnAutoClose = function() return false end,
		{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() ImportPlayerListOld() end, },
		{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
	}
	MessageBox(msg)
end

function LR_AS_DB.MainDBVacuum(skip)
	local vacuum = function()
		local path = sformat("%s\\%s", SaveDataPath, db_name)
		local DB = LR.OpenDB(path, "AS_DB_VACUUM_9B768A082DF71DDAC8B1FC8EFCDB4E57")
		local SQL = "DELETE FROM %s WHERE bDel = 1"
		local tables = {"bookrd_data", "exam_data", "fb_data", "mail_data", "mail_item_data", "mail_receive_time", "qiyu_data", "richang_data"}
		for k, v in pairs (tables) do
			local DB_DELETE = DB:Prepare(sformat(SQL, v))
			DB_DELETE:Execute()
		end

		local SQL2 = "DELETE FROM %s WHERE %s IS NULL"
		local TABLE2 = {"player_info", "bag_item_data", "bank_item_data", "bookrd_data", "exam_data", "fb_data", "mail_data", "mail_item_data", "mail_receive_time", "qiyu_data", "richang_data", "richang_clear_time", "achievement_data", "equipment_data", "group_list", "player_group"}
		local KEY2 = {"szKey", "szKey", "szKey", "szKey", "szKey", "szKey", "nMailID", "szKey", "szKey", "szKey", "szKey", "szName", "szKey", "szKey", "groupID", "szKey"}
		for k, v in pairs(TABLE2) do
			local DB_DELETE = DB:Prepare(sformat(SQL2, v, KEY2[k]))
			DB_DELETE:Execute()
		end

		DB:Execute("END TRANSACTION")
		DB:Execute("VACUUM")
		DB:Execute("BEGIN TRANSACTION")
		LR.CloseDB(DB)
		LR.SysMsg(sformat("%s\n", _L["VACUUM Success!"]))
		--LR.GreenAlert(sformat("%s\n", _L["VACUUM Success!"]))
	end

	if skip then
		vacuum()
	else
		local msg = {
			szMessage = _L["Are you sure to vacuum main database ?"],
			szName = "vacuum database",
			fnAutoClose = function() return false end,
			{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() vacuum() end, },
			{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
		}
		MessageBox(msg)
	end
end

function LR_AS_DB.MainDBBackup()
	local backup = function()
		local source = sformat("%s\\%s", SaveDataPath, db_name)
		local nTime = GetCurrentTime()
		local _date = TimeToDate(nTime)
		local _year = _date.year
		local _month = _date.month
		local _day = _date.day
		local target = sformat("%s\\5", SaveDataPath)
		---------
	end

	local msg = {
		szMessage = _L["Are you sure to backup main database ?"],
		szName = "vacuum database",
		fnAutoClose = function() return false end,
		{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() backup() end, },
		{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
	}
	MessageBox(msg)
end

------------------------------------------
--初始化数据库
------------------------------------------
function LR_AS_DB.MoveTradeDB(DB)
	local column = {}
	for k, v in pairs (schema_trade_data.data) do
		column[#column+1] = v.name
	end
	DB:Execute(sformat("REPLACE INTO trade_data ( %s ) SELECT %s FROM trade_data_temp", tconcat(column, ", "), tconcat(column, ", ")))
end

function LR_AS_DB.IniTradeDB()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local path = sformat("%s\\TradeData\\%s\\%s\\%s", SaveDataPath, realArea, realServer, GetUserRoleName())
	local tTableConfig = {
		schema_trade_data,
		schema_trade_data_temp,
	}
	LR.IniDB(path, "TradeDB.db", tTableConfig)
end

local tTableConfig = {
	schema_group_list,
	schema_player_group,
	schema_player_list,
	schema_player_info,
	schema_exam_data,
	schema_richang_data,
	schema_richang_clear_time,
	schema_fb_data,
	schema_bag_item_data,
	schema_bank_item_data,
	schema_mail_item_data,
	schema_mail_data,
	schema_qiyu_data,
	schema_bookrd_data,
	schema_mail_receive_time,
	schema_achievement_data,
	schema_equipment_data,
	schema_wltj_data,
}

function LR_AS_DB.IniMainDB()
	local tTableConfig = tTableConfig
	LR.IniDB(SaveDataPath, db_name, tTableConfig)
end

function LR_AS_DB.backup()
	local begin_time = GetTickCount()

	local tTableConfig = tTableConfig
	--新建备份数据库
	local nTime = GetCurrentTime()
	local _date = TimeToDate(nTime)

	local name = sformat("backup_%04d%02d%02d_%02dh%02dm%02ds.db", _date.year, _date.month, _date.day, _date.hour, _date.minute, _date.second)
	local path = sformat("%s\\backup", SaveDataPath)
	LR.IniDB(sformat("%s\\backup", SaveDataPath), name, tTableConfig)

	for table_config_k, table_config_v in pairs(tTableConfig) do
		local path = sformat("%s\\%s", SaveDataPath, db_name)
		local DB = LR.OpenDB(path, "AS_DB_BACKUP_OPEN_MAIN_B1743D7DDD8D1FDD03E4B14B1E2B5D4D")

		local table_name = table_config_v.name
		--获取全部数据
		local DB_SELECT = DB:Prepare(sformat("SELECT * FROM %s", table_name))
		local data = DB_SELECT:GetAll()

		--打开备份数据库
		local path2 = sformat("%s\\backup\\%s", SaveDataPath, name)
		local DB2 = LR.OpenDB(path2, "AS_DB_BACKUP_OPEN_BACKUP2670572C80E55B4CAAAB65E06B5F2D09")

		--导入
		for k, v in pairs(data) do
			local key = {}
			local wen = {}
			local values = {}

			for k2, key_data in pairs(table_config_v.data) do
				if v[key_data.name] then
					key[#key + 1] = key_data.name
					wen[#wen + 1] = "?"
					values[#values + 1] = v[key_data.name]
				end
			end

			local keys = tconcat(key, ", ")
			local wens = tconcat(wen, ", ")

			local sql = sformat("REPLACE INTO %s ( %s ) VALUES ( %s )", table_name, keys, wens)
			--Output(sql)
			local DB_REPLACE = DB2:Prepare(sql)
			if DB_REPLACE then
				DB_REPLACE:ClearBindings()
				DB_REPLACE:BindAll(unpack(values))
				DB_REPLACE:Execute()
			else
				Output(sql)
			end
		end

		LR.CloseDB(DB2, "2670572C80E55B4CAAAB65E06B5F2D09")
		LR.CloseDB(DB)
	end
	local end_time = GetTickCount()
	Log(sformat("backup cost %ss\n", tostring((end_time - begin_time) /1000.0)))
	LR.SysMsg(sformat(_L["backup path: %s\\\n"], path))
	LR.SysMsg(sformat(_L["backup dataname: %s\n"], name))
	LR.SysMsg(sformat(_L["backup cost %ss\n"], tostring((end_time - begin_time) /1000.0)))
end

----------------------------------------------
------------奇遇历史事件
----------------------------------------------
local schema_qyhistory_list = {
	name = "qiyu_history",
	version = VERSION,
	data = {
		{name = "szName", sql = "szName VARCHAR(30) DEFAULT('playername')"},
		{name = "szQYName", sql = "szQYName VARCHAR(30) DEFAULT('qyname')"},
		{name = "realArea", sql = "realArea VARCHAR(30) DEFAULT('daqu')"},
		{name = "realServer", sql = "realServer VARCHAR(30) DEFAULT('fuwuqi')"},
		{name = "nMethod", sql = "nMethod INTEGER DEFAULT(0)"},
		{name = "bFinished", sql = "bFinished INTEGER DEFAULT(0)"},
		{name = "nTime", 	sql = "nTime INTEGER DEFAULT(0)"},
		{name = "hash", sql = "hash VARCHAR(40) DEFAULT('')"},
	},
	primary_key = {sql = "PRIMARY KEY ( szName, szQYName, realArea, realServer )"},
}

local schema_pethistory_list = {
	name = "pet_history",
	version = VERSION,
	data = {
		{name = "szName", sql = "szName VARCHAR(30) DEFAULT('playername')"},
		{name = "szPetName", sql = "szPetName VARCHAR(30) DEFAULT('qyname')"},
		{name = "realArea", sql = "realArea VARCHAR(30) DEFAULT('daqu')"},
		{name = "realServer", sql = "realServer VARCHAR(30) DEFAULT('fuwuqi')"},
		{name = "nTime", 	sql = "nTime INTEGER DEFAULT(0)"},
		{name = "hash", sql = "hash VARCHAR(40) DEFAULT('')"},
	},
	primary_key = {sql = "PRIMARY KEY ( szName, szPetName, realArea, realServer )"},
}

function LR_AS_DB.IniQYHistoryDB()
	local tTableConfig = {schema_qyhistory_list, schema_pethistory_list}
	local path = SaveDataPath
	local db_name = "qiyu_history.db"
	LR.IniDB(SaveDataPath, db_name, tTableConfig)
end

----------------------------------------------
------------事件处理
----------------------------------------------
----登录顺序
----CUSTOM_DATA_LOADED	可以获得玩家名字（通过GetUserRoleName），不能获得GetClientPlayer的信息
----LOGIN_GAME	可以获得玩家名字（通过GetUserRoleName），不能获得GetClientPlayer的信息
----SYNC_ROLE_DATA_END（可以获得角色信息）
----FIRST_LOADING_END
----LOADING_END
--过图触发顺序
----SYNC_ROLE_DATA_END（可以获得角色信息）
----LOADING_END
function LR_AS_DB.LOGIN_GAME()
	LR_AS_DB.IniMainDB()
	LR_AS_DB.IniTradeDB()
	LR_AS_DB.IniQYHistoryDB()
end

LR.RegisterEvent("LOGIN_GAME", function() LR_AS_DB.LOGIN_GAME() end)

