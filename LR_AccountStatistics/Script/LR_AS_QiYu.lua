local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin\\@DATA\\LR_AccountStatistics"
local _L = LR.LoadLangPack(AddonPath)
local DB_name = "maindb.db"
local sformat, slen, sgsub, ssub, sfind = string.format, string.len, string.gsub, string.sub, string.find
local mfloor, mceil, mmin, mmax = math.floor, math.ceil, math.min, math.max
local tconcat, tinsert, tremove, tsort = table.concat, table.insert, table.remove, table.sort
--------------------------------------------------------------------
local MONITOR_TYPE = {
	WINDOW_DIALOG = 1,
	ITEM = 2,
	MULTI_ITEM = 3,
	MSG_NPC_NEARBY = 4,
	MSG_NPC_NEARBY_AND_WINDOW_DIALOG = 5,
}

local QIYU = {
	SHENG_FU_JU = 1,
	ZHUO_YAO_JI = 2,
	GUI_XIANG_LU = 3,
	FENG_LIN_JIU = 4,
	HONG_YI_GE = 5,
	HAI_TONG_SHU = 6,
	JING_KE_CI = 7,
	SHA_HAI_YAO = 8,
	SHI_GAN_DANG = 9,
	ZHI_ZUN_BAO = 10,
	PO_XIAO_MING = 11,
	ZHU_MA_QING = 12,
	QING_CAO_GE = 13,
	DIAN_NAN_XING = 14,
	ZHI_ZI_XIN = 15,
	GUAN_WAI_SHANG = 16,
	BEI_XING_BIAO = 17,
	DONG_HAI_KE = 18,
}

local QIYU_NAME = {
	[QIYU.SHENG_FU_JU] = _L["SHENG_FU_JU"],
	[QIYU.ZHUO_YAO_JI] = _L["ZHUO_YAO_JI"],
	[QIYU.GUI_XIANG_LU] = _L["GUI_XIANG_LU"],
	[QIYU.FENG_LIN_JIU] = _L["FENG_LIN_JIU"],
	[QIYU.HONG_YI_GE] = _L["HONG_YI_GE"],
	[QIYU.HAI_TONG_SHU] = _L["HAI_TONG_SHU"],
	[QIYU.JING_KE_CI] = _L["JING_KE_CI"],
	[QIYU.SHA_HAI_YAO] = _L["SHA_HAI_YAO"],
	[QIYU.SHI_GAN_DANG] = _L["SHI_GAN_DANG"],
	[QIYU.ZHI_ZUN_BAO] = _L["ZHI_ZUN_BAO"],
	[QIYU.PO_XIAO_MING] = _L["PO_XIAO_MING"],
	[QIYU.ZHU_MA_QING] = _L["ZHU_MA_QING"],
	[QIYU.QING_CAO_GE] = _L["QING_CAO_GE"],
	[QIYU.DIAN_NAN_XING] = _L["DIAN_NAN_XING"],
	[QIYU.ZHI_ZI_XIN] = _L["ZHI_ZI_XIN"],
	[QIYU.GUAN_WAI_SHANG] = _L["GUAN_WAI_SHANG"],
	[QIYU.BEI_XING_BIAO] = _L["BEI_XING_BIAO"],
	[QIYU.DONG_HAI_KE] = _L["DONG_HAI_KE"]
}

local QIYU_MNTP = {
	[QIYU.SHENG_FU_JU] = MONITOR_TYPE.WINDOW_DIALOG,
	[QIYU.ZHUO_YAO_JI] = MONITOR_TYPE.ITEM,
	[QIYU.GUI_XIANG_LU] = MONITOR_TYPE.ITEM,
	[QIYU.FENG_LIN_JIU] = MONITOR_TYPE.WINDOW_DIALOG,
	[QIYU.HONG_YI_GE] = MONITOR_TYPE.ITEM,
	[QIYU.HAI_TONG_SHU] = MONITOR_TYPE.ITEM,
	[QIYU.JING_KE_CI] = MONITOR_TYPE.MULTI_ITEM,
	[QIYU.SHA_HAI_YAO] = MONITOR_TYPE.ITEM,
	[QIYU.SHI_GAN_DANG] = MONITOR_TYPE.ITEM,
	[QIYU.ZHI_ZUN_BAO] = MONITOR_TYPE.MULTI_ITEM,
	[QIYU.PO_XIAO_MING] = MONITOR_TYPE.ITEM,
	[QIYU.ZHU_MA_QING] = MONITOR_TYPE.MSG_NPC_NEARBY,
	[QIYU.QING_CAO_GE] = MONITOR_TYPE.MSG_NPC_NEARBY,
	[QIYU.DIAN_NAN_XING] = MONITOR_TYPE.MSG_NPC_NEARBY_AND_WINDOW_DIALOG,
	[QIYU.ZHI_ZI_XIN] = MONITOR_TYPE.MSG_NPC_NEARBY,
	[QIYU.GUAN_WAI_SHANG] = MONITOR_TYPE.ITEM,
	[QIYU.BEI_XING_BIAO] = MONITOR_TYPE.WINDOW_DIALOG,
	[QIYU.DONG_HAI_KE] = MONITOR_TYPE.MSG_NPC_NEARBY,
}

local QIYU_ITEM = {
	[QIYU.ZHUO_YAO_JI] = {item = {{dwTabType = 5, dwIndex = 26009, }, }, dwMapID = 0, },
	[QIYU.GUI_XIANG_LU] = {item = {{dwTabType = 5, dwIndex = 26027, }, }, dwMapID = 0, },
	[QIYU.HONG_YI_GE] = {item = {{dwTabType = 5, dwIndex = 25997, }, }, dwMapID = 0, },
	[QIYU.HAI_TONG_SHU] = {item = {{dwTabType = 5, dwIndex = 26026, }, }, dwMapID = 0, },
	[QIYU.JING_KE_CI] = {item = {{dwTabType = 5, dwIndex = 20016, }, }, dwMapID = 172, dwTemplateID = 51323, },
	[QIYU.SHA_HAI_YAO] = {item = {{dwTabType = 5, dwIndex = 26675, }, }, dwMapID = 0, },
	[QIYU.SHI_GAN_DANG] = {item = {{dwTabType = 5, dwIndex = 26714, }, }, dwMapID = 0, },
	[QIYU.ZHI_ZUN_BAO] = {item = {{dwTabType = 5, dwIndex = 11111, }, {dwTabType = 5, dwIndex = 17032, }, }, dwMapID = 105, dwTemplateID = 51963, },
	--[QIYU.ZHU_MA_QING] = {item = {{dwTabType = 5, dwIndex = 11048, }, {dwTabType = 5, dwIndex = 10247, }, }, dwMapID = 101, dwTemplateID = 51936, },
	[QIYU.PO_XIAO_MING] = {item = {{dwTabType = 5, dwIndex = 26777, }, }, dwMapID = 0, },
	[QIYU.GUAN_WAI_SHANG] = {item = {{dwTabType = 5, dwIndex = 28443, }, }, dwMapID = 0, },
}

local QIYU_WINDOW_DIALOG = {
	[QIYU.SHENG_FU_JU] = {dwMapID = 215, dwTemplateID = 48057, 			--1
		dialog = {
			{szText = _L["DIALOG_SHENG_FU_JU_01"], bFinish = false, }, 		--失败
		},
	},
	[QIYU.FENG_LIN_JIU] = {dwMapID = 12, dwTemplateID = 42874,
		dialog = {
			{szText = _L["DIALOG_FENG_LIN_JIU_01"], bFinish = false, }, 		--失败
		},
	},
	[QIYU.DIAN_NAN_XING] = {dwMapID = 102, dwTemplateID = 55289,
		dialog = {
			{szText = _L["DIALOG_DIAN_NAN_XING_02"], bFinish = true, }, 		--满次数
		},
	},
	[QIYU.BEI_XING_BIAO] = {dwMapID = 239, dwTemplateID = 56702,
		dialog = {
			{szText = _L["DIALOG_BEI_XING_BIAO_01"], bFinish = false, }, 		--满次数
		},
	},
}

local QIYU_MSG_NPC_NEARBY = {
	[QIYU.SHENG_FU_JU] = {dwMapID = 215, szName = _L["SHENG_FU_JU_NPCSZNAME"],
		dialog = {		--1
			{szText = _L["SHENG_FU_JU_02"], bFinish = true, }, 		--满次数
		},
	},
	[QIYU.FENG_LIN_JIU] = {dwMapID = 12, szName = _L["FENG_LIN_JIU_NPCSZNAME"],
		dialog = {		--4
			{szText = _L["DIALOG_FENG_LIN_JIU_02"], bFinish = true, }, 		--满次数
		},
	},
	[QIYU.HAI_TONG_SHU] = {dwMapID = 2, szName = _L["HAI_TONG_SHU_NPCSZNAME"],
		dialog = {		--6
			{szText = _L["DIALOG_HAI_TONG_SHU_02"], bFinish = true, }, 		--满次数
		},
	},
	[QIYU.SHI_GAN_DANG] = {dwMapID = 108, szName = _L["SHI_GAN_DANG_NPCSZNAME"],
		dialog = {		--9
			{szText = _L["DIALOG_SHI_GAN_DANG_02"], bFinish = true, }, 		--满次数
		},
	},
	[QIYU.ZHI_ZUN_BAO] = {dwMapID = 105, szName = _L["ZHI_ZUN_BAO_NPCSZNAME"],
		dialog = {		--9
			{szText = _L["DIALOG_ZHI_ZUN_BAO_02"], bFinish = true, }, 		--满次数
		},
	},
	[QIYU.ZHU_MA_QING] = {dwMapID = 101, szName = _L["ZHU_MA_QING_NPCSZNAME"],
		dialog = {		--12
			{szText = _L["DIALOG_ZHU_MA_QING_01"], bFinish = false, }, 		--失败
			{szText = _L["DIALOG_ZHU_MA_QING_02"], bFinish = true, }, 		--满次数
			{szText = _L["DIALOG_ZHU_MA_QING_03"], bFinish = true, }, 		--成功
		},
	},
	[QIYU.QING_CAO_GE] = {dwMapID = 216, szName = _L["QING_CAO_GE_NPCSZNAME"],
		dialog = {		--13
			{szText = _L["DIALOG_QING_CAO_GE_01"], bFinish = false, }, 		--失败
			{szText = _L["DIALOG_QING_CAO_GE_02"], bFinish = true, }, 		--满次数
			{szText = _L["DIALOG_QING_CAO_GE_03"], bFinish = true, }, 		--成功
		},
	},
	[QIYU.DIAN_NAN_XING] = {dwMapID = 102, szName = _L["DIAN_NAN_XING_NPCSZNAME"],
		dialog = {		--14
			{szText = _L["DIALOG_DIAN_NAN_XING_01"], bFinish = false, }, 		--失败
			--{szText = _L["DIALOG_DIAN_NAN_XING_02"], bFinish = true, }, 		--满次数
			{szText = _L["DIALOG_DIAN_NAN_XING_03"], bFinish = true, }, 		--成功
		},
	},
	[QIYU.ZHI_ZI_XIN] = {dwMapID = 159, szName = _L["ZHI_ZI_XIN_NPCSZNAME"],
		dialog = {		--15
			{szText = _L["DIALOG_ZHI_ZI_XIN_01"], bFinish = false, }, 		--失败
			{szText = _L["DIALOG_ZHI_ZI_XIN_02"], bFinish = true, }, 		--满次数
			{szText = _L["DIALOG_ZHI_ZI_XIN_03"], bFinish = true, }, 		--成功
		},
	},
	[QIYU.DONG_HAI_KE] = {dwMapID = 22, szName = _L["DONG_HAI_KE_NPCSZNAME"],
		dialog = {		--15
			{szText = _L["DIALOG_DONG_HAI_KE_01"], bFinish = false, }, 		--失败
		},
	},
}

local QIYU_ACHIEVEMENT = {
	[QIYU.SHENG_FU_JU] = 5199,
	[QIYU.ZHUO_YAO_JI] = 5197,
	[QIYU.GUI_XIANG_LU] = 5200,
	[QIYU.FENG_LIN_JIU] = 5194,
	[QIYU.HONG_YI_GE] = 5195,
	[QIYU.HAI_TONG_SHU] = 5196,
	[QIYU.JING_KE_CI] = 5328,
	[QIYU.SHA_HAI_YAO] = 5329,
	[QIYU.SHI_GAN_DANG] = 5339,
	[QIYU.ZHI_ZUN_BAO] = 5443,
	[QIYU.PO_XIAO_MING] = 5441,
	[QIYU.ZHU_MA_QING] = 5442,
	[QIYU.QING_CAO_GE] = 5658,
	[QIYU.DIAN_NAN_XING] = 5657,
	[QIYU.ZHI_ZI_XIN] = 5659,
	[QIYU.GUAN_WAI_SHANG] = 5812,
	[QIYU.BEI_XING_BIAO] = 5811,
	[QIYU.DONG_HAI_KE] = 5813,
}

local QIYU_ITEM_NUM = {}

--------------------------------------------------------------------
LR_ACS_QiYu = LR_ACS_QiYu or {}
LR_ACS_QiYu.SelfData = {}
LR_ACS_QiYu.default = {
	List = {
		[QIYU_NAME[QIYU.SHENG_FU_JU]] = true,
		[QIYU_NAME[QIYU.ZHUO_YAO_JI]] = true,
		[QIYU_NAME[QIYU.GUI_XIANG_LU]] = true,
		[QIYU_NAME[QIYU.FENG_LIN_JIU]] = true,
		[QIYU_NAME[QIYU.HONG_YI_GE]] = true,
		[QIYU_NAME[QIYU.HAI_TONG_SHU]] = true,
		[QIYU_NAME[QIYU.JING_KE_CI]] = true,
		[QIYU_NAME[QIYU.SHA_HAI_YAO]] = true,
		[QIYU_NAME[QIYU.SHI_GAN_DANG]] = true,
		[QIYU_NAME[QIYU.ZHI_ZUN_BAO]] = false,
		[QIYU_NAME[QIYU.PO_XIAO_MING]] = false,
		[QIYU_NAME[QIYU.ZHU_MA_QING]] = false,
	},
	bUseCommonData = true,
	Version = "20170111",
}
LR_ACS_QiYu.QiYu = clone(QIYU)
LR_ACS_QiYu.QiYuName = clone(QIYU_NAME)
LR_ACS_QiYu.UsrData = clone(LR_ACS_QiYu.default)

local CustomVersion = "20170111"
RegisterCustomData("LR_ACS_QiYu.UsrData", CustomVersion)

function LR_ACS_QiYu.ResetUsrData()
	LR_ACS_QiYu.UsrData = clone(LR_ACS_QiYu.default)
end

function LR_ACS_QiYu.CheckCommomUsrData()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local  path = sformat("%s\\UsrData\\QiYuCommonData.dat.jx3dat", SaveDataPath)
	if not IsFileExist(path) then
		local CommomMenuList = LR_ACS_QiYu.default
		local path = sformat("%s\\UsrData\\QiYuCommonData.dat", SaveDataPath)
		SaveLUAData (path, CommomMenuList)
	end
end

function LR_ACS_QiYu.SaveCommomUsrData()
	if not LR_ACS_QiYu.UsrData.bUseCommonData then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local path = sformat("%s\\UsrData\\QiYuCommonData.dat", SaveDataPath)
	local UsrData = LR_ACS_QiYu.UsrData
	SaveLUAData (path, UsrData)
end

function LR_ACS_QiYu.LoadCommomUsrData()
	LR_ACS_QiYu.CheckCommomUsrData()
	if not LR_ACS_QiYu.UsrData.bUseCommonData then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local path = sformat("%s\\UsrData\\QiYuCommonData.dat", SaveDataPath)
	local UsrData = LoadLUAData (path)
	LR_ACS_QiYu.UsrData = clone(UsrData)
end

function LR_ACS_QiYu.SaveData()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	local ServerInfo = {GetUserServer()}
	local realArea, realServer = ServerInfo[5], ServerInfo[6]
	local dwID = me.dwID
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	local DB_REPLACE = DB:Prepare("REPLACE INTO qiyu_data ( szKey, qiyu_data, bDel ) VALUES ( ?, ?, ? )")
	if LR_AccountStatistics.UsrData.OthersCanSee then
		local SelfData = {}
		for k, v in pairs(LR_ACS_QiYu.SelfData) do
			SelfData[tostring(k)] = v
		end
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey, LR.JsonEncode(SelfData), 0)
		DB_REPLACE:Execute()
	else
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey, LR.JsonEncode({}), 1)
		DB_REPLACE:Execute()
	end
	DB:Execute("END TRANSACTION")
	DB:Release()
end

function LR_ACS_QiYu.LoadAllUsrData(DB)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local ServerInfo = {GetUserServer()}
	local realArea, realServer = ServerInfo[5], ServerInfo[6]
	local dwID = me.dwID
	local szSelfKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	local DB_SELECT = DB:Prepare("SELECT * FROM qiyu_data WHERE bDel = 0")
	local Data = DB_SELECT:GetAll() or {}
	local AllUsrData = {}
	for k, v in pairs (Data) do
		AllUsrData[v.szKey] = clone(v)
		local qiyu_data = {}
		for k, v in pairs (v.qiyu_data or {}) do
			qiyu_data[tonumber(k)] = v
		end
		AllUsrData[v.szKey].qiyu_data = clone(qiyu_data)
	end
	if next(LR_ACS_QiYu.SelfData) == nil then
		LR_ACS_QiYu.SelfData = AllUsrData[szSelfKey] or {}
	else
		AllUsrData[szSelfKey] = LR_ACS_QiYu.SelfData
	end
end

function LR_ACS_QiYu.ClearAllData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM qiyu_data WHERE bDel = 0")
	local Data = DB_SELECT:GetAll() or {}
	local DB_REPLACE = DB:Prepare("REPLACE INTO qiyu_data ( szKey, qiyu_data, bDel ) VALUES ( ?, ?, 0 )")
	if Data and next(Data) ~= nil then
		for k, v in pairs (Data) do
			DB_REPLACE:ClearBindings()
			DB_REPLACE:BindAll(v.szKey, LR.JsonEncode({}))
			DB_REPLACE:Execute()
		end
	end
end

local _tempTime = 0
function LR_ACS_QiYu.CheckItemNum(dwTabType, dwIndex)
	local now = GetLogicFrameCount()
	if now - _tempTime < 2 then
		LR.DelayCall(100, function() LR_ACS_QiYu.CheckItemNum(dwTabType, dwIndex) end)
		return
	end
	for k, v in pairs(QIYU) do
		if QIYU_MNTP[v] ==  MONITOR_TYPE.ITEM or QIYU_MNTP[v] ==  MONITOR_TYPE.MULTI_ITEM then
			local data = QIYU_ITEM[v]
			for k2, v2 in pairs (data.item) do
				if dwTabType == v2.dwTabType and dwIndex == v2.dwIndex then
					local num = LR_ACS_QiYu.GetSingleItemNum(dwTabType, dwIndex)
					local flag = true
					if QIYU_MNTP[v] ==  MONITOR_TYPE.MULTI_ITEM then
						local me = GetClientPlayer()
						local scene = me.GetScene()
						if scene.dwMapID ~=  data.dwMapID then
							flag = false
						end
						local nType, dwID = me.GetTarget()
						if nType ==  TARGET.NPC then
							local tar = LR.GetTarget(nType, dwID)
							if tar.dwTemplateID ~=  data.dwTemplateID then
								flag = false
							end
						else
							flag = false
						end
					end
					local key = sformat("%d_%d", dwTabType, dwIndex)
					if num<QIYU_ITEM_NUM[key] and flag then
						LR_ACS_QiYu.SelfData[v] = LR_ACS_QiYu.SelfData[v] or 0
						LR_ACS_QiYu.SelfData[v] = LR_ACS_QiYu.SelfData[v]+1
						LR_ACS_QiYu.SaveData()
						LR_ACS_QiYu.ListQY()
					end
					QIYU_ITEM_NUM[key] = num
				end
			end
		end
	end
end

function LR_ACS_QiYu.GetSingleItemNum(dwTabType, dwIndex)
	local me = GetClientPlayer()
	local num = me.GetItemAmountInAllPackages(dwTabType, dwIndex)
	return num
end

function LR_ACS_QiYu.FIRST_LOADING_END()
	LR_ACS_QiYu.LoadAllUsrData(DB)
	LR_ACS_QiYu.LoadCommomUsrData()

	for k, v in pairs(QIYU) do
		if QIYU_MNTP[v] ==  MONITOR_TYPE.ITEM or QIYU_MNTP[v] ==  MONITOR_TYPE.MULTI_ITEM then
			local data = QIYU_ITEM[v]
			for k2, v2 in pairs(data.item) do
				local dwTabType = v2.dwTabType
				local dwIndex = v2.dwIndex
				local num = LR_ACS_QiYu.GetSingleItemNum(dwTabType, dwIndex)
				local key = sformat("%d_%d", dwTabType, dwIndex)
				QIYU_ITEM_NUM[key] = num
			end
		end
	end
end

function LR_ACS_QiYu.DESTROY_ITEM()
	local dwBoxIndex = arg0
	local dwX = arg1
	local nVersion = arg2
	local dwTabType = arg3
	local dwIndex = arg4

	_tempTime = GetLogicFrameCount()
	LR_ACS_QiYu.CheckItemNum(dwTabType, dwIndex)
end

function LR_ACS_QiYu.BAG_ITEM_UPDATE()
	local dwBoxIndex = arg0
	local dwX = arg1

	local me = GetClientPlayer()
	local item = me.GetItem(dwBoxIndex, dwX)

	if item then
		local dwTabType = item.dwTabType
		local dwIndex = item.dwIndex
		_tempTime = GetLogicFrameCount()
		LR_ACS_QiYu.CheckItemNum(dwTabType, dwIndex)
	end
end

function LR_ACS_QiYu.OPEN_WINDOW()
	local dwIndex = arg0
	local szText = LR.Trim(arg1)
	local dwTargetType = arg2
	local dwTargetID = arg3

	if dwTargetType ~=  TARGET.NPC then
		return
	end
	local npc = GetNpc(dwTargetID)
	if not npc then
		return
	end
	local dwTemplateID = npc.dwTemplateID
	local scene = npc.GetScene()
	local dwMapID = scene.dwMapID

	for k, v in pairs(QIYU) do
		if QIYU_MNTP[v] ==  MONITOR_TYPE.WINDOW_DIALOG or  QIYU_MNTP[v] ==  MONITOR_TYPE.MSG_NPC_NEARBY_AND_WINDOW_DIALOG then
			local data = QIYU_WINDOW_DIALOG[v]
			if dwMapID ==  data.dwMapID and dwTemplateID ==  data.dwTemplateID then
				local bFound = false
				local bFinish = false
				for k2, v2 in pairs(data.dialog) do
					local _start, _end = sfind(szText, v2.szText)
					if _start then
						bFound = true
						if v2.bFinish then
							bFinish = true
						end
					end
				end
				if bFound then
					LR_ACS_QiYu.SelfData[v] = LR_ACS_QiYu.SelfData[v] or 0
					LR_ACS_QiYu.SelfData[v] = LR_ACS_QiYu.SelfData[v]+1
					if bFinish then
						LR_ACS_QiYu.SelfData[v] = 4
					end
					LR_ACS_QiYu.SaveData()
					LR_ACS_QiYu.ListQY()
				end
			end
		end
	end
end

function LR_ACS_QiYu.MSG_NPC_NEARBY(szMsg)
	local szMsg = szMsg or ""
	local me = GetClientPlayer()
	if not me then
		return
	end
	local scene = me.GetScene()
	local dwMapID = scene.dwMapID
	for k, v in pairs(QIYU) do
		if QIYU_MNTP[v] ==  MONITOR_TYPE.MSG_NPC_NEARBY  or  QIYU_MNTP[v] ==  MONITOR_TYPE.MSG_NPC_NEARBY_AND_WINDOW_DIALOG or QIYU_MSG_NPC_NEARBY[v] then
			local data = QIYU_MSG_NPC_NEARBY[v]
			if dwMapID == data.dwMapID then
				local bFound = false
				local bFinish = false
				for k2, v2 in pairs(data.dialog) do
					local _start, _end = sfind(szMsg, v2.szText)
					local _start2, _end2 = sfind(szMsg, data.szName)
					if _start and _start2 then
						bFound = true
						if v2.bFinish then
							bFinish = true
						end
					end
				end
				if bFound then
					LR_ACS_QiYu.SelfData[v] = LR_ACS_QiYu.SelfData[v] or 0
					LR_ACS_QiYu.SelfData[v] = LR_ACS_QiYu.SelfData[v]+1
					if bFinish then
						LR_ACS_QiYu.SelfData[v] = 4
					end
					LR_ACS_QiYu.SaveData()
					LR_ACS_QiYu.ListQY()
				end
			end
		end
	end
end

RegisterMsgMonitor(LR_ACS_QiYu.MSG_NPC_NEARBY, {"MSG_NPC_NEARBY"})
LR.RegisterEvent("OPEN_WINDOW", function() LR_ACS_QiYu.OPEN_WINDOW() end)
LR.RegisterEvent("DESTROY_ITEM", function() LR_ACS_QiYu.DESTROY_ITEM() end)
LR.RegisterEvent("BAG_ITEM_UPDATE", function() LR_ACS_QiYu.BAG_ITEM_UPDATE() end)
LR.RegisterEvent("FIRST_LOADING_END", function() LR_ACS_QiYu.FIRST_LOADING_END() end)

----------------------------------------------------
function LR_ACS_QiYu.ListQY()
	local frame = Station.Lookup("Normal/LR_AccountStatistics")
	if not frame then
		return
	end
	local title_handle = LR_AccountStatistics.LR_QYList_Title_handle
	local n = 1
	for k, v in pairs (QIYU) do
		if n<10 then
			if LR_ACS_QiYu.UsrData.List[QIYU_NAME[v]] then
				local text = title_handle:Lookup(sformat("Text_QY%d_Break", n))
				text:SetText(QIYU_NAME[v])
				text:RegisterEvent(277)
				text.OnItemLButtonClick = function ()
					local nX, nY = text:GetAbsPos()
					local nW, nH = text:GetSize()
					OutputAchievementTip(QIYU_ACHIEVEMENT[v], {nX, nY, 0, -135})
				end
				text.OnItemMouseEnter = function ()
					text:SetFontColor(255, 128, 0)
				end
				text.OnItemMouseLeave = function ()
					text:SetFontColor(255, 255, 255)
				end
				n = n+1
			end
		end
	end
	for i = n, 9, 1 do
		local text = title_handle:Lookup(sformat("Text_QY%d_Break", i))
		text:SetText("")
	end

	local TempTable_Cal, TempTable_NotCal = LR_AccountStatistics.SeparateUsrList()

	LR_AccountStatistics.LR_QYList_Container:Clear()
	num = LR_ACS_QiYu.ShowItem(TempTable_Cal, 255, 1, 0)
	num = LR_ACS_QiYu.ShowItem(TempTable_NotCal, 60, 1, num)
	LR_AccountStatistics.LR_QYList_Container:FormatAllContentPos()
end

function LR_ACS_QiYu.ShowItem(t_Table, Alpha, bCal, _num)
	local num = _num
	local TempTable = clone(t_Table)

	local me = GetClientPlayer()
	if not me then
		return
	end

	for i = 1, #TempTable, 1 do
		num = num+1
		local wnd = LR_AccountStatistics.LR_QYList_Container:AppendContentFromIni("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics_QYList_Item.ini", "QYList_WndWindow", num)
		local items = wnd:Lookup("", "")
		if num % 2 ==  0 then
			items:Lookup("Image_Line"):Hide()
		else
			items:Lookup("Image_Line"):SetAlpha(225)
		end

		wnd:SetAlpha(Alpha)

		local item_MenPai = items:Lookup("Image_NameIcon")
		local item_Name = items:Lookup("Text_Name")
		local item_Select = items:Lookup("Image_Select")
		item_Select:SetAlpha(125)
		item_Select:Hide()

		item_MenPai:FromUITex(GetForceImage(TempTable[i].dwForceID))
		local name = TempTable[i].szName
		if slen(name) >12 then
			local _start, _end  = sfind (name, "@")
			if _start and _end then
				name = sformat("%s...", ssub(name, 1, 9))
			else
				name = sformat("%s...", ssub(name, 1, 10))
			end
		end
		item_Name:SprintfText("%s（%d）", name, TempTable[i].nLevel)
		local r, g, b = LR.GetMenPaiColor(TempTable[i].dwForceID)
		item_Name:SetFontColor(r, g, b)
		--  Output(LR.GetMenPaiColor(TempTable[i].MenPai))

		local realArea = TempTable[i].realArea
		local realServer = TempTable[i].realServer
		local szName = TempTable[i].szName
		local player  = GetClientPlayer()
		local QY_Record

		local src = "%s\\UsrData\\%s\\%s\\%s\\QiYu_%s.dat"
		if TempTable[i].dwID ==  me.dwID then
			QY_Record = clone(LR_ACS_QiYu.SelfData)
		else
			local path = sformat(src, SaveDataPath, realArea, realServer, szName, szName)
			QY_Record2 = LoadLUAData(path) or {data = {}, }
			QY_Record = clone(QY_Record2.data)
		end

		------输出日常
		local n = 1
		local List = LR_ACS_QiYu.List
		for k, v in pairs(QIYU) do
			if n<10 then
				if LR_ACS_QiYu.UsrData.List[QIYU_NAME[v]] then
					local Text_QY = items:Lookup(sformat("Text_QY%d", n))
					local times = QY_Record[v] or 0
					if times>= 3 then
						Text_QY:SetText(_L["Done"])
						Text_QY:SetFontScheme(47)
					elseif times>0 then
						Text_QY:SetText(times)
						Text_QY:SetFontScheme(31)
					else
						Text_QY:SetText("")
					end
					n = n+1
				end
			end
		end

		for i = n, 9, 1 do
			local Text_QY = items:Lookup(sformat("Text_QY%d", i))
			Text_QY:SetText("")
		end

		--------------------输出tips
		items:RegisterEvent(786)
		items.OnItemMouseEnter = function ()
			item_Select:Show()
			local nMouseX, nMouseY =  Cursor.GetPos()
			local szTipInfo = {}
			local szPath, nFrame = GetForceImage(TempTable[i].dwForceID)
			szTipInfo[#szTipInfo+1] = GetFormatImage(szPath, nFrame, 26, 26)
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s（%d）\n", TempTable[i].szName, TempTable[i].nLevel), 62, r, g, b)
			szTipInfo[#szTipInfo+1] = GetFormatText(" ============== \t   \n", 62)
			for k, v in pairs(QIYU) do
				local times = QY_Record[v] or 0
				local text = ""
				local font = 17
				if times>= 3 then
					text = _L["Done"]
					font = 47
				elseif times>0 then
					text = times
					font = 31
				else
					text = times
					font = 17
				end
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s：", QIYU_NAME[v]), 224)
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", text), font)
			end
			local szOutputTip = tconcat(szTipInfo)
			OutputTip(szOutputTip, 200, {nMouseX, nMouseY, 0, 0})
		end
		items.OnItemMouseLeave = function()
			item_Select:Hide()
			HideTip()
		end
		items.OnItemLButtonClick = function()
			local realArea = TempTable[i].realArea
			local realServer = TempTable[i].realServer
			local szName = TempTable[i].szName
			LR_ACS_QiYu_Panel:Open(realArea, realServer, szName)
		end
	end
	return num
end

----------------------------------------------------
----小窗口
----------------------------------------------------
LR_ACS_QiYu_Panel = CreateAddon("LR_ACS_QiYu_Panel")
LR_ACS_QiYu_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_ACS_QiYu_Panel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0},
}

LR_ACS_QiYu_Panel.realArea = ""
LR_ACS_QiYu_Panel.realServer = ""
LR_ACS_QiYu_Panel.szPlayerName = ""

function LR_ACS_QiYu_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")
	LR_ACS_QiYu_Panel.UpdateAnchor(this)

	RegisterGlobalEsc("LR_ACS_QiYu_Panel", function () return true end , function() LR_ACS_QiYu_Panel:Open() end)
end

function LR_ACS_QiYu_Panel:OnEvents(event)
	if event ==  "UI_SCALED" then
		LR_ACS_QiYu_Panel.UpdateAnchor(this)
	end
end

function LR_ACS_QiYu_Panel.UpdateAnchor(frame)
	frame:SetPoint(LR_ACS_QiYu_Panel.UsrData.Anchor.s, 0, 0, LR_ACS_QiYu_Panel.UsrData.Anchor.r, LR_ACS_QiYu_Panel.UsrData.Anchor.x, LR_ACS_QiYu_Panel.UsrData.Anchor.y)
	frame:CorrectPos()
end

function LR_ACS_QiYu_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_ACS_QiYu_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_ACS_QiYu_Panel:OnDragEnd()
	this:CorrectPos()
	LR_ACS_QiYu_Panel.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_ACS_QiYu_Panel:Init()
	local frame = self:Append("Frame", "LR_ACS_QiYu_Panel", {title = _L["LR QiYu Details"], style = "SMALL"})

	----------关于
	LR.AppendAbout(LR_ACS_QiYu_Panel, frame)

	local imgTab = self:Append("Image", frame, "TabImg", {w = 381, h = 33, x = 0, y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)

	local hPageSet = self:Append("PageSet", frame, "PageSet", {x = 20, y = 120, w = 360, h = 360})
	local hWinIconView = self:Append("Window", hPageSet, "WindowItemView", {x = 0, y = 0, w = 360, h = 360})
	local hScroll = self:Append("Scroll", hWinIconView, "Scroll", {x = 0, y = 0, w = 354, h = 360})
	self:LoadItemBox(hScroll)
	hScroll:UpdateList()

	-------------初始界面物品
	local hHandle = self:Append("Handle", frame, "Handle", {x = 18, y = 90, w = 340, h = 390})

	local Image_Record_BG = self:Append("Image", hHandle, "Image_Record_BG", {x = 0, y = 0, w = 340, h = 390})
	Image_Record_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 50)
	Image_Record_BG:SetImageType(10)

	local Image_Record_BG1 = self:Append("Image", hHandle, "Image_Record_BG1", {x = 0, y = 30, w = 340, h = 390})
	Image_Record_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74)
	Image_Record_BG1:SetImageType(10)
	Image_Record_BG1:SetAlpha(110)

	local Image_Record_Line1_0 = self:Append("Image", hHandle, "Image_Record_Line1_0", {x = 3, y = 28, w = 340, h = 3})
	Image_Record_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 65)
	Image_Record_Line1_0:SetImageType(11)
	Image_Record_Line1_0:SetAlpha(115)

	local Image_Record_Break1 = self:Append("Image", hHandle, "Image_Record_Break1", {x = 200, y = 2, w = 3, h = 386})
	Image_Record_Break1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
	Image_Record_Break1:SetImageType(11)
	Image_Record_Break1:SetAlpha(160)

	local Text_break1 = self:Append("Text", hHandle, "Text_break1", {w = 200, h = 30, x  = 0, y = 2, text = _L["QiYu Name"], font = 18})
	Text_break1:SetHAlign(1)
	Text_break1:SetVAlign(1)

	local Text_break2 = self:Append("Text", hHandle, "Text_break1", {w = 140, h = 30, x  = 200, y = 2, text = _L["QiYu Times"], font = 18})
	Text_break2:SetHAlign(1)
	Text_break2:SetVAlign(1)

	--------------人物选择
	local hComboBox = self:Append("ComboBox", frame, "hComboBox", {w = 160, x = 20, y = 51, text = LR_ACS_QiYu_Panel.szPlayerName})
	hComboBox:Enable(true)
	hComboBox.OnClick = function (m)
		local TempTable_Cal, TempTable_NotCal = LR_AccountStatistics.SeparateUsrList()
		TempTable_NotCal[#TempTable_NotCal+1] = {realServer = "ALL", szName = _L["(ALL CHARACTERS)"], dwForceID = 0, realArea = "ALL"}
		local TempTable = {}
		for i = 1, #TempTable_Cal, 1 do
			TempTable[#TempTable+1] = TempTable_Cal[i]
		end
		for i = 1, #TempTable_NotCal, 1 do
			TempTable[#TempTable+1] = TempTable_NotCal[i]
		end

		for i = 1, #TempTable, 1 do
			local szIcon, nFrame = GetForceImage(TempTable[i].dwForceID)
			local r, g, b = LR.GetMenPaiColor(TempTable[i].dwForceID)
			m[#m+1] = {szOption = TempTable[i].szName, bCheck = false, bChecked = false,
				fnAction =  function ()
					local realArea = TempTable[i].realArea
					local realServer = TempTable[i].realServer
					local szName = TempTable[i].szName
					LR_ACS_QiYu_Panel:ReloadItemBox(realArea, realServer, szName)
				end,
				szIcon =  szIcon,
				nFrame =  nFrame,
				szLayer =  "ICON_RIGHT",
				rgb =  {r, g, b},
			}
		end

		PopupMenu(m)
	end
end

function LR_ACS_QiYu_Panel:Open(realArea, realServer, szPlayerName)
	local frame = self:Fetch("LR_ACS_QiYu_Panel")
	if frame then
		if realArea then
			LR_ACS_QiYu_Panel:ReloadItemBox(realArea, realServer, szPlayerName)
		else
			self:Destroy(frame)
		end
	else
		if realArea then
			LR_ACS_QiYu_Panel.realArea = realArea
			LR_ACS_QiYu_Panel.realServer = realServer
			LR_ACS_QiYu_Panel.szPlayerName = szPlayerName
		else
			local serverInfo = {GetUserServer()}
			local realArea, realServer = serverInfo[5], serverInfo[6]
			local szName = GetClientPlayer().szName
			LR_ACS_QiYu_Panel.realArea = realArea
			LR_ACS_QiYu_Panel.realServer = realServer
			LR_ACS_QiYu_Panel.szPlayerName = szName
		end
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

function LR_ACS_QiYu_Panel:LoadItemBox(hWin)
	local realServer = LR_ACS_QiYu_Panel.realServer
	local realArea = LR_ACS_QiYu_Panel.realArea
	local szName = LR_ACS_QiYu_Panel.szPlayerName

	local path = sformat("%s\\UsrData\\%s\\%s\\%s\\QiYu_%s.dat", SaveDataPath, realArea, realServer, szName, szName)
	local QiYu_Record = LoadLUAData(path) or {}

	local me =  GetClientPlayer()
	if not me then
		return
	end
	if me.szName ==  szName then
		QiYu_Record  = LR_ACS_QiYu.SelfData or {}
	else
		QiYu_Record = QiYu_Record.data or {}
	end

	local m = 1
	for k, v in pairs(QIYU) do
		local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 340, h = 30})
		local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 0, y = 0, w = 340, h = 30})
		Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
		Image_Line:SetImageType(10)
		Image_Line:SetAlpha(200)

		if m % 2 ==  1 then
			Image_Line:Hide()
		end

		--悬停框
		local Image_Hover = self:Append("Image", hIconViewContent, sformat("Image_Hover_%d", m), {x = 2, y = 0, w = 334, h = 30})
		Image_Hover:FromUITex("ui\\Image\\Common\\TempBox.UITex", 5)
		Image_Hover:SetImageType(10)
		Image_Hover:SetAlpha(200)
		Image_Hover:Hide()

		local Text_break1 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_1", m), {w = 160, h = 30, x  = 36, y = 2, text = QIYU_NAME[v] , font = 18})
		Text_break1:SetHAlign(0)
		Text_break1:SetVAlign(1)

		local times = QiYu_Record[v] or 0
		if times >= 3 then
			times = "已完成"
		end
		local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 140, h = 30, x  = 200, y = 2, text = times, font = 18})
		Text_break2:SetHAlign(1)
		Text_break2:SetVAlign(1)

		hIconViewContent.OnEnter = function()
			Image_Hover:Show()
		end

		hIconViewContent.OnLeave = function()
			Image_Hover:Hide()
		end

		hIconViewContent.OnClick = function()
			local frame = self:Fetch("LR_ACS_QiYu_Panel")
			local nX, nY = frame:GetRelPos()
			local nW, nH = frame:GetSize()
			OutputAchievementTip(QIYU_ACHIEVEMENT[v], {nX, nY, nW, 0})
		end

		m = m+1
	end
end

function LR_ACS_QiYu_Panel:ReloadItemBox(realArea, realServer, szName)
	local hComboBox = self:Fetch("hComboBox")
	hComboBox:SetText(szName)
	LR_ACS_QiYu_Panel.szPlayerName = szName
	LR_ACS_QiYu_Panel.realServer = realServer
	LR_ACS_QiYu_Panel.realArea = realArea
	local cc = self:Fetch("Scroll")
	if cc then
		self:ClearHandle(cc)
	end
	self:LoadItemBox(cc)
	cc:UpdateList()
end









