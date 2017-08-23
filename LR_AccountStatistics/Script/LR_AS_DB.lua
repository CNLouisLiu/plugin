local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin\\@DATA\\LR_AccountStatistics\\UsrData"
local BackupPath = "Interface\\LR_Plugin\\@Backup\\LR_AccountStatistics\\"
local _L = LR.LoadLangPack(AddonPath)
local DB_name = "maindb.db"
---------------------------------------------------------------
LR_AS_DB = LR_AS_DB or {}

---------------------------------------------------------------
------数据库表项定义
---------------------------------------------------------------
---主数据库
local schema_table_info = {
	name = "table_info",
	version = "20170623",
	data = {
		{name = "table_name", sql = "table_name VARCHAR(60)"},
		{name = "version", sql = "version VARCHAR(20)"}
	},
	primary_key = {sql = "PRIMARY KEY ( table_name )"},
}

local schema_group_list = {
	name = "group_list",
	version = "20170625",
	data = {
		{name = "groupID", 	sql = "groupID INTEGER"},		--主键
		{name = "szName", sql = "szName VARCHAR(30) DEFAULT('DEFAULT GROUP')"},
		{name = "nCurrentStamina", 	sql = "nCurrentStamina INTEGER DEFAULT(0)"},
		{name = "nMaxStamina", 	sql = "nMaxStamina INTEGER DEFAULT(0)"},
		{name = "nCurrentThew", 	sql = "nCurrentThew INTEGER DEFAULT(0)"},
		{name = "nMaxThew", 	sql = "nMaxThew INTEGER DEFAULT(0)"},
		{name = "SaveTime", 	sql = "SaveTime INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( groupID )"},
}

local schema_player_info = {
	name = "player_info",
	version = "20170628",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "dwID", 	sql = "dwID INTEGER DEFAULT(0)"},
		{name = "szName", sql = "szName VARCHAR(20) DEFAULT('xx')"},
		{name = "nLevel", sql = "nLevel INTEGER DEFAULT(0)"},
		{name = "dwForceID", sql = "dwForceID INTEGER DEFAULT(0)"},
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
		{name = "szTitle", sql = "szTitle VARCHAR(20)"},
		{name = "nCurrentStamina", 	sql = "nCurrentStamina INTEGER DEFAULT(0)"},
		{name = "nMaxStamina", 	sql = "nMaxStamina INTEGER DEFAULT(0)"},
		{name = "nCurrentThew", 	sql = "nCurrentThew INTEGER DEFAULT(0)"},
		{name = "nMaxThew", 	sql = "nMaxThew INTEGER DEFAULT(0)"},
		{name = "nCurrentTrainValue", 	sql = "nCurrentTrainValue INTEGER DEFAULT(0)"},
		{name = "nCamp", 	sql = "nCamp INTEGER DEFAULT(0)"},
		{name = "szTongName", sql = "szTongName VARCHAR(20)"},
		{name = "remainJianBen", 	sql = "remainJianBen INTEGER DEFAULT(0)"},
		{name = "loginArea", sql = "loginArea VARCHAR(20)"},
		{name = "loginServer", sql = "loginServer VARCHAR(20)"},
		{name = "realArea", sql = "realArea VARCHAR(20)"},
		{name = "realServer", sql = "realServer VARCHAR(20)"},
		{name = "SaveTime", sql = "SaveTime INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_player_group = {
	name = "player_group",
	version = "20170628",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "groupID", sql = "groupID INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_exam_data = {
	name = "exam_data",
	version = "20170628",
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
	version = "20170628",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "DA", 	sql = "DA TEXT"},
		{name = "GONG", 	sql = "GONG TEXT"},
		{name = "CHA", 	sql = "CHA TEXT"},
		{name = "QIN", 	sql = "QIN TEXT"},
		{name = "JU", 	sql = "JU TEXT"},
		{name = "JING", 	sql = "JING TEXT"},
		{name = "MEI", 	sql = "MEI TEXT"},
		{name = "CAI", 	sql = "CAI TEXT"},
		{name = "XUN", 	sql = "XUN TEXT"},
		{name = "TU", 	sql = "TU TEXT"},
		{name = "MI", 	sql = "MI TEXT"},
		{name = "HUIGUANG", 	sql = "HUIGUANG TEXT"},
		{name = "HUASHAN", 	sql = "HUASHAN TEXT"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_richang_clear_time = {
	name = "richang_clear_time",
	version = "20170726",
	data = {
		{name = "szName", 	sql = "szName VARCHAR(60)"},		--主键
		{name = "nTime", 	sql = "nTime INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szName )"},
}

local schema_fb_data = {
	name = "fb_data",
	version = "20170628",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "fb_data", sql = "fb_data TEXT"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_qiyu_data = {
	name = "qiyu_data",
	version = "20170628",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "qiyu_data", sql = "qiyu_data TEXT"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_bookrd_data = {
	name = "bookrd_data",
	version = "20170629",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "bookrd_data", sql = "bookrd_data TEXT"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_bag_item_data = {
	name = "bag_item_data",
	version = "20170627",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "szName", 	sql = "szName VARCHAR(60)"},
		{name = "belong", 	sql = "belong VARCHAR(60)"},		--主键
		{name = "dwTabType", 	sql = "dwTabType INTEGER DEFAULT(0)"},
		{name = "dwIndex", 	sql = "dwIndex INTEGER DEFAULT(0)"},
		{name = "nUiId", 	sql = "nUiId INTEGER DEFAULT(0)"},
		{name = "nBookID", 	sql = "nBookID INTEGER DEFAULT(0)"},
		{name = "nGenre", 	sql = "nGenre INTEGER DEFAULT(0)"},
		{name = "nQuality", 	sql = "nQuality INTEGER DEFAULT(0)"},
		{name = "nStackNum", 	sql = "nStackNum INTEGER DEFAULT(0)"},
		{name = "bBind", 	sql = "bBind INTEGER DEFAULT(0)"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey, belong )"},
}

local schema_bank_item_data = {
	name = "bank_item_data",
	version = "20170627",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "szName", 	sql = "szName VARCHAR(60)"},
		{name = "belong", 	sql = "belong VARCHAR(60)"},		--主键
		{name = "dwTabType", 	sql = "dwTabType INTEGER DEFAULT(0)"},
		{name = "dwIndex", 	sql = "dwIndex INTEGER DEFAULT(0)"},
		{name = "nUiId", 	sql = "nUiId INTEGER DEFAULT(0)"},
		{name = "nBookID", 	sql = "nBookID INTEGER DEFAULT(0)"},
		{name = "nGenre", 	sql = "nGenre INTEGER DEFAULT(0)"},
		{name = "nQuality", 	sql = "nQuality INTEGER DEFAULT(0)"},
		{name = "nStackNum", 	sql = "nStackNum INTEGER DEFAULT(0)"},
		{name = "bBind", 	sql = "bBind INTEGER DEFAULT(0)"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey, belong )"},
}

local schema_mail_item_data = {
	name = "mail_item_data",
	version = "20170626",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "szName", 	sql = "szName VARCHAR(60)"},
		{name = "belong", 	sql = "belong VARCHAR(60)"},		--主键
		{name = "dwTabType", 	sql = "dwTabType INTEGER DEFAULT(0)"},
		{name = "dwIndex", 	sql = "dwIndex INTEGER DEFAULT(0)"},
		{name = "nUiId", 	sql = "nUiId INTEGER DEFAULT(0)"},
		{name = "nBookID", 	sql = "nBookID INTEGER DEFAULT(0)"},
		{name = "nGenre", 	sql = "nGenre INTEGER DEFAULT(0)"},
		{name = "nQuality", 	sql = "nQuality INTEGER DEFAULT(0)"},
		{name = "nStackNum", 	sql = "nStackNum INTEGER DEFAULT(0)"},
		{name = "bBind", 	sql = "bBind INTEGER DEFAULT(0)"},
		{name = "nBelongMailID",	sql = "nBelongMailID TEXT"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey, belong )"},
}

local schema_mail_data = {
	name = "mail_data",
	version = "20170618",
	data = {
		{name = "nMailID", 	sql = "nMailID INTEGER"},	--主键
		{name = "belong", 	sql = "belong VARCHAR(60)"},		--主键
		{name = "szSenderName", sql = "szSenderName VARCHAR(60)"},
		{name = "szTitle", 	sql = "szTitle TEXT"},
		{name = "szContent", 	sql = "szContent TEXT"},
		{name = "nType", 	sql = "nType INTEGER DEFAULT(0)"},
		{name = "nEndTime", 	sql = "nEndTime INTEGER DEFAULT(0)"},
		{name = "item_record", 	sql = "item_record TEXT"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( nMailID, belong )"},
}

local schema_mail_receive_time = {
	name = "mail_receive_time",
	version = "20170711",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "nTime", 	sql = "nTime INTEGER DEFAULT(0)"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_achievement_data = {
	name = "achievement_data",
	version = "20170619",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(80)"},		--主键
		{name = "achievement_data", 	sql = "achievement_data TEXT"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local schema_equipment_data = {
	name = "equipment_data",
	version = "20170622",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(80)"},		--主键
		{name = "nSuitIndex", 	sql = "nSuitIndex TEXT"},
		{name = "equipment_data", 	sql = "equipment_data TEXT"},
		{name = "score", 	sql = "score TEXT"},
		{name = "char_info", 	sql = "char_info TEXT"},
		{name = "char_infomore", 	sql = "char_infomore TEXT"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey, nSuitIndex )"},
}

--收支交易数据库
local schema_trade_data = {
	name = "trade_data",
	version = "20170618",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(80)"},		--主键
		{name = "nTime", 	sql = "nTime INTEGER DEFAULT(0)"},		--主键
		{name = "OrderTime", sql = "OrderTime INTEGER DEFAULT(0)"},
		{name = "nMoney", 	sql = "nMoney TEXT"},
		{name = "nItem_in", 	sql = "nItem_in TEXT"},
		{name = "nItem_out", 	sql = "nItem_out TEXT"},
		{name = "dwMapID", 	sql = "dwMapID INTEGER DEFAULT(0)"},
		{name = "nType", 	sql = "nType INTEGER DEFAULT(0)"},
		{name = "Distributor", 	sql = "Distributor TEXT"},
		{name = "Source", 	sql = "Source TEXT"},
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
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	if option == "player_info" then
		local path = sformat("%s\\UserList.dat",SaveDataPath)
		if IsFileExist(sformat("%s.jx3dat", path)) then
			local data = LoadLUAData(path) or {}
			if data.data then
				DB:Execute("BEGIN TRANSACTION")
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
				DB:Execute("END TRANSACTION")
			end
		end
	end

	DB:Release()
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

function LR_AS_DB.MainDBVacuum()
	local vacuum = function()
		local path = sformat("%s\\%s", SaveDataPath, DB_name)
		local DB = SQLite3_Open(path)
		DB:Execute("BEGIN TRANSACTION")
		local SQL = "DELETE FROM %s WHERE bDel = 1"
		local tables = {"bag_item_data", "bank_item_data", "bookrd_data", "exam_data", "fb_data", "mail_data", "mail_item_data", "mail_receive_time", "qiyu_data", "richang_data"}
		for k, v in pairs (tables) do
			local DB_DELETE = DB:Prepare(sformat(SQL, v))
			DB_DELETE:Execute()
		end
		DB:Execute("END TRANSACTION")
		DB:Execute("VACUUM")
		DB:Release()
		LR.SysMsg(sformat("%s\n", _L["VACUUM Success!"]))
		LR.GreenAlert(sformat("%s\n", _L["VACUUM Success!"]))
	end

	local msg = {
		szMessage = _L["Are you sure to vacuum main database ?"],
		szName = "vacuum database",
		fnAutoClose = function() return false end,
		{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() vacuum() end, },
		{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
	}
	MessageBox(msg)
end

function LR_AS_DB.MainDBBackup()
	local backup = function()
		local source = sformat("%s\\%s", SaveDataPath, DB_name)
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

function LR_AS_DB.IniMainDB()
	local tTableConfig = {
		schema_group_list,
		schema_player_info,
		schema_player_group,
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
	}
	LR.IniDB(SaveDataPath, DB_name, tTableConfig)
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
end

LR.RegisterEvent("LOGIN_GAME", function() LR_AS_DB.LOGIN_GAME() end)



