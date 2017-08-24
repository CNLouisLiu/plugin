local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin\\@DATA\\LR_AccountStatistics\\UsrData"
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

local QIYU_NAME = {}	--名字
local QIYU_MNTP = {}	--监控类型
local QIYU_MAP = {}	--奇遇地图
local QIYU_NPC = {}	--奇遇NPC
local QIYU_ITEM = {} --监控物品
local QIYU_ITEM_NUM = {}	--奇遇监控物品数量
local QIYU_WINDOW_DIALOG = {}	--奇遇对话框
local QIYU_MSG_NPC_NEARBY = {}	--奇遇NPC近聊
local QIYU_WARNING_MSG = {}
local QIYU_ACHIEVEMENT = {}	--奇遇成就

--胜负局 1
QIYU_NAME[QIYU.SHENG_FU_JU] = _L["SHENG_FU_JU"]
QIYU_MNTP[QIYU.SHENG_FU_JU] = MONITOR_TYPE.MSG_NPC_NEARBY
QIYU_MAP[QIYU.SHENG_FU_JU] = 215
QIYU_NPC[QIYU.SHENG_FU_JU] = 48057
QIYU_MSG_NPC_NEARBY[QIYU.SHENG_FU_JU] = {
	{szText = _L["DIALOG_SHENG_FU_JU_01"], bFinish = true, }, 		--满次数
	{szText = _L["DIALOG_SHENG_FU_JU_02"], bFinish = false, },	--下了一次
}
QIYU_ACHIEVEMENT[QIYU.SHENG_FU_JU] = 5199

--捉妖记 2
QIYU_NAME[QIYU.ZHUO_YAO_JI] = _L["ZHUO_YAO_JI"]
QIYU_MNTP[QIYU.ZHUO_YAO_JI] = MONITOR_TYPE.ITEM
QIYU_MAP[QIYU.ZHUO_YAO_JI] = 16
QIYU_ITEM[QIYU.ZHUO_YAO_JI] = {
	{dwTabType = 5, dwIndex = 26009, },
}
QIYU_WARNING_MSG[QIYU.ZHUO_YAO_JI] = {
	{szText = _L["WARNING_ZHUO_YAO_JI_01"], bFinish = true, },
}
QIYU_ACHIEVEMENT[QIYU.ZHUO_YAO_JI] = 5197

--归乡路 3
QIYU_NAME[QIYU.GUI_XIANG_LU] = _L["GUI_XIANG_LU"]
QIYU_MNTP[QIYU.GUI_XIANG_LU] = MONITOR_TYPE.ITEM
QIYU_MAP[QIYU.GUI_XIANG_LU] = 49
QIYU_NPC[QIYU.GUI_XIANG_LU] = 48171
QIYU_ITEM[QIYU.GUI_XIANG_LU] = {
	{dwTabType = 5, dwIndex = 26027, },
}
QIYU_MSG_NPC_NEARBY[QIYU.GUI_XIANG_LU] = {
	{szText = _L["DIALOG_GUI_XIANG_LU_01"], bFinish = true, }, 		--满次数
}
QIYU_ACHIEVEMENT[QIYU.GUI_XIANG_LU] = 5200

--枫林酒 4
QIYU_NAME[QIYU.FENG_LIN_JIU] = _L["FENG_LIN_JIU"]
QIYU_MNTP[QIYU.FENG_LIN_JIU] = MONITOR_TYPE.WINDOW_DIALOG
QIYU_MAP[QIYU.FENG_LIN_JIU] = 12
QIYU_NPC[QIYU.FENG_LIN_JIU] = 42874
QIYU_WINDOW_DIALOG[QIYU.FENG_LIN_JIU] = {
	{szText = _L["WINDOW_FENG_LIN_JIU_01"], bFinish = false, }, 		--失败
}
QIYU_MSG_NPC_NEARBY[QIYU.FENG_LIN_JIU] = {
	{szText = _L["DIALOG_FENG_LIN_JIU_01"], bFinish = true, }, 		--满次数
}
QIYU_ACHIEVEMENT[QIYU.FENG_LIN_JIU] = 5194

--红衣歌 5
QIYU_NAME[QIYU.HONG_YI_GE] = _L["HONG_YI_GE"]
QIYU_MNTP[QIYU.HONG_YI_GE] = MONITOR_TYPE.ITEM
QIYU_MAP[QIYU.HONG_YI_GE] = 9
QIYU_NPC[QIYU.HONG_YI_GE] = 47992
QIYU_ITEM[QIYU.HONG_YI_GE] = {
	{dwTabType = 5, dwIndex = 25997, },
}
QIYU_MSG_NPC_NEARBY[QIYU.HONG_YI_GE] = {
	{szText = _L["DIALOG_HONG_YI_GE_01"], bFinish = true, }, 		--满次数
}
QIYU_ACHIEVEMENT[QIYU.HONG_YI_GE] = 5195

--孩童书 6
QIYU_NAME[QIYU.HAI_TONG_SHU] = _L["HAI_TONG_SHU"]
QIYU_MNTP[QIYU.HAI_TONG_SHU] = MONITOR_TYPE.ITEM
QIYU_MAP[QIYU.HAI_TONG_SHU] = 2
QIYU_NPC[QIYU.HAI_TONG_SHU] = 48105
QIYU_ITEM[QIYU.HAI_TONG_SHU] = {
	{dwTabType = 5, dwIndex = 26026, },
}
QIYU_MSG_NPC_NEARBY[QIYU.HAI_TONG_SHU] = {
	{szText = _L["DIALOG_HAI_TONG_SHU_01"], bFinish = true, }, 		--满次数
}
QIYU_ACHIEVEMENT[QIYU.HAI_TONG_SHU] = 5196

--荆轲刺 7
QIYU_NAME[QIYU.JING_KE_CI] = _L["JING_KE_CI"]
QIYU_MNTP[QIYU.JING_KE_CI] = MONITOR_TYPE.MULTI_ITEM
QIYU_MAP[QIYU.JING_KE_CI] = 172
QIYU_NPC[QIYU.JING_KE_CI] = 51323
QIYU_ITEM[QIYU.JING_KE_CI] = {
	{dwTabType = 5, dwIndex = 20016, },
}
QIYU_MSG_NPC_NEARBY[QIYU.JING_KE_CI] = {
	{szText = _L["DIALOG_JING_KE_CI_01"], bFinish = true, }, 		--满次数
}
QIYU_ACHIEVEMENT[QIYU.JING_KE_CI] = 5328

--沙海谣 8
QIYU_NAME[QIYU.SHA_HAI_YAO] = _L["SHA_HAI_YAO"]
QIYU_MNTP[QIYU.SHA_HAI_YAO] = MONITOR_TYPE.ITEM
QIYU_MAP[QIYU.SHA_HAI_YAO] = 23
QIYU_NPC[QIYU.SHA_HAI_YAO] = 51303
QIYU_ITEM[QIYU.SHA_HAI_YAO] = {
	{dwTabType = 5, dwIndex = 26675, },
}
QIYU_MSG_NPC_NEARBY[QIYU.SHA_HAI_YAO] = {
	{szText = _L["DIALOG_SHA_HAI_YAO_01"], bFinish = true, }, 		--满次数
}
QIYU_ACHIEVEMENT[QIYU.SHA_HAI_YAO] = 5329

--石敢当 9
QIYU_NAME[QIYU.SHI_GAN_DANG] = _L["SHI_GAN_DANG"]
QIYU_MNTP[QIYU.SHI_GAN_DANG] = MONITOR_TYPE.ITEM
QIYU_MAP[QIYU.SHI_GAN_DANG] = 108
QIYU_NPC[QIYU.SHI_GAN_DANG] = 11969
QIYU_ITEM[QIYU.SHI_GAN_DANG] = {
	{dwTabType = 5, dwIndex = 26714, },
}
QIYU_MSG_NPC_NEARBY[QIYU.SHI_GAN_DANG] = {
	{szText = _L["DIALOG_SHI_GAN_DANG_01"], bFinish = true, }, 		--满次数
}
QIYU_WARNING_MSG[QIYU.SHI_GAN_DANG] = {
	{szText = _L["WARNING_SHI_GAN_DANG_01"], bFinish = true, }, 		--满次数
}
QIYU_ACHIEVEMENT[QIYU.SHI_GAN_DANG] = 5339

--至尊宝 10
QIYU_NAME[QIYU.ZHI_ZUN_BAO] = _L["ZHI_ZUN_BAO"]
QIYU_MNTP[QIYU.ZHI_ZUN_BAO] = MONITOR_TYPE.MULTI_ITEM
QIYU_MAP[QIYU.ZHI_ZUN_BAO] = 105
QIYU_NPC[QIYU.ZHI_ZUN_BAO] = 51963
--[[
QIYU_ITEM[QIYU.ZHI_ZUN_BAO] = {
	{dwTabType = 5, dwIndex = 11111, },
	{dwTabType = 5, dwIndex = 17032, },
}]]
QIYU_MSG_NPC_NEARBY[QIYU.ZHI_ZUN_BAO] = {
	{szText = _L["DIALOG_ZHI_ZUN_BAO_01"], bFinish = true, }, 		--满次数
	{szText = _L["DIALOG_ZHI_ZUN_BAO_02"], bFinish = false, }, 		--满次数
}
QIYU_ACHIEVEMENT[QIYU.ZHI_ZUN_BAO] = 5443

--破晓鸣 11
QIYU_NAME[QIYU.PO_XIAO_MING] = _L["PO_XIAO_MING"]
QIYU_MNTP[QIYU.PO_XIAO_MING] = MONITOR_TYPE.ITEM
QIYU_MAP[QIYU.PO_XIAO_MING] = 10
QIYU_NPC[QIYU.PO_XIAO_MING] = 2350
--[[
QIYU_ITEM[QIYU.PO_XIAO_MING] = {
	{dwTabType = 5, dwIndex = 26777, },
}]]
QIYU_MSG_NPC_NEARBY[QIYU.PO_XIAO_MING] = {
	{szText = _L["DIALOG_PO_XIAO_MING_01"], bFinish = false, }, 		--做了一次
	{szText = _L["DIALOG_PO_XIAO_MING_02"], bFinish = true, }, 		--满次数
}
QIYU_ACHIEVEMENT[QIYU.PO_XIAO_MING] = 5441

--竹马情 12
QIYU_NAME[QIYU.ZHU_MA_QING] = _L["ZHU_MA_QING"]
QIYU_MNTP[QIYU.ZHU_MA_QING] = MONITOR_TYPE.MSG_NPC_NEARBY
QIYU_MAP[QIYU.ZHU_MA_QING] = 101
QIYU_NPC[QIYU.ZHU_MA_QING] = 51936
QIYU_MSG_NPC_NEARBY[QIYU.ZHU_MA_QING] = {
	{szText = _L["DIALOG_ZHU_MA_QING_01"], bFinish = false, }, 		--失败
	{szText = _L["DIALOG_ZHU_MA_QING_02"], bFinish = true, }, 		--满次数
	{szText = _L["DIALOG_ZHU_MA_QING_03"], bFinish = true, }, 		--成功
}
QIYU_ACHIEVEMENT[QIYU.ZHU_MA_QING] = 5442

--青草歌 13
QIYU_NAME[QIYU.QING_CAO_GE] = _L["QING_CAO_GE"]
QIYU_MNTP[QIYU.QING_CAO_GE] = MONITOR_TYPE.MSG_NPC_NEARBY
QIYU_MAP[QIYU.QING_CAO_GE] = 216
QIYU_NPC[QIYU.QING_CAO_GE] = 55282
QIYU_MSG_NPC_NEARBY[QIYU.QING_CAO_GE] = {
	{szText = _L["DIALOG_QING_CAO_GE_01"], bFinish = false, }, 		--失败
	{szText = _L["DIALOG_QING_CAO_GE_02"], bFinish = true, }, 		--满次数
	{szText = _L["DIALOG_QING_CAO_GE_03"], bFinish = true, }, 		--成功
}
QIYU_ACHIEVEMENT[QIYU.QING_CAO_GE] = 5658

--滇南行 14
QIYU_NAME[QIYU.DIAN_NAN_XING] = _L["DIAN_NAN_XING"]
QIYU_MNTP[QIYU.DIAN_NAN_XING] = MONITOR_TYPE.MSG_NPC_NEARBY_AND_WINDOW_DIALOG
QIYU_MAP[QIYU.DIAN_NAN_XING] = 102
QIYU_NPC[QIYU.DIAN_NAN_XING] = 55289
QIYU_WINDOW_DIALOG[QIYU.DIAN_NAN_XING] = {
	{szText = _L["WINDOW_DIAN_NAN_XING_01"], bFinish = true, }, 		--满次数
}
QIYU_MSG_NPC_NEARBY[QIYU.DIAN_NAN_XING] = {
	{szText = _L["DIALOG_DIAN_NAN_XING_01"], bFinish = false, }, 		--失败
	{szText = _L["DIALOG_DIAN_NAN_XING_02"], bFinish = true, }, 		--成功
}
QIYU_ACHIEVEMENT[QIYU.DIAN_NAN_XING] = 5657

--稚子心 15
QIYU_NAME[QIYU.ZHI_ZI_XIN] = _L["ZHI_ZI_XIN"]
QIYU_MNTP[QIYU.ZHI_ZI_XIN] = MONITOR_TYPE.MSG_NPC_NEARBY
QIYU_MAP[QIYU.ZHI_ZI_XIN] = 159
QIYU_NPC[QIYU.ZHI_ZI_XIN] = 54677
QIYU_MSG_NPC_NEARBY[QIYU.ZHI_ZI_XIN] = {
	{szText = _L["DIALOG_ZHI_ZI_XIN_01"], bFinish = false, }, 		--失败
	{szText = _L["DIALOG_ZHI_ZI_XIN_02"], bFinish = true, }, 		--满次数
	{szText = _L["DIALOG_ZHI_ZI_XIN_03"], bFinish = true, }, 		--成功
}
QIYU_ACHIEVEMENT[QIYU.ZHI_ZI_XIN] = 5659

--关外商 16
QIYU_NAME[QIYU.GUAN_WAI_SHANG] = _L["GUAN_WAI_SHANG"]
QIYU_MNTP[QIYU.GUAN_WAI_SHANG] = MONITOR_TYPE.ITEM
QIYU_MAP[QIYU.GUAN_WAI_SHANG] = 193
QIYU_NPC[QIYU.GUAN_WAI_SHANG] = 56476
QIYU_ITEM[QIYU.GUAN_WAI_SHANG] = {
	{dwTabType = 5, dwIndex = 28443, },
}
QIYU_WINDOW_DIALOG[QIYU.GUAN_WAI_SHANG] = {
	{szText = _L["WINDOW_GUAN_WAI_SHANG_01"], bFinish = true, }, 		--满次数
	{szText = _L["WINDOW_GUAN_WAI_SHANG_02"], bFinish = true, }, 		--满次数
}
QIYU_ACHIEVEMENT[QIYU.GUAN_WAI_SHANG] = 5812

--北行镖 17
QIYU_NAME[QIYU.BEI_XING_BIAO] = _L["BEI_XING_BIAO"]
QIYU_MNTP[QIYU.BEI_XING_BIAO] = MONITOR_TYPE.WINDOW_DIALOG
QIYU_MAP[QIYU.BEI_XING_BIAO] = 239
QIYU_NPC[QIYU.BEI_XING_BIAO] = 56702
QIYU_WINDOW_DIALOG[QIYU.BEI_XING_BIAO] = {
	{szText = _L["DIALOG_BEI_XING_BIAO_01"], bFinish = false, }, 		--吃了一次
}
QIYU_ACHIEVEMENT[QIYU.BEI_XING_BIAO] = 5811

--东海客 18
QIYU_NAME[QIYU.DONG_HAI_KE] = _L["DONG_HAI_KE"]
QIYU_MNTP[QIYU.DONG_HAI_KE] = MONITOR_TYPE.MSG_NPC_NEARBY
QIYU_MAP[QIYU.DONG_HAI_KE] = 22
QIYU_NPC[QIYU.DONG_HAI_KE] = 56477
QIYU_WINDOW_DIALOG[QIYU.DONG_HAI_KE] = {
	{szText = _L["WINDOW_DONG_HAI_KE_01"], bFinish = true, }, 		--满次数
}
QIYU_MSG_NPC_NEARBY[QIYU.DONG_HAI_KE] = {
	{szText = _L["DIALOG_DONG_HAI_KE_01"], bFinish = false, }, 		--失败
}
QIYU_ACHIEVEMENT[QIYU.DONG_HAI_KE] = 5813


--------------------------------------------------------------------
LR_ACS_QiYu = LR_ACS_QiYu or {}
LR_ACS_QiYu.SelfData = {}
LR_ACS_QiYu.SelfAchievementData = {}
LR_ACS_QiYu.AllUsrData = {}
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

function LR_ACS_QiYu.GetSelfQiYuAchievementData()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local data = {}
	for k, v in pairs(QIYU) do
		local dwID = QIYU_ACHIEVEMENT[v]
		local bFinished = me.IsAchievementAcquired(dwID)
		if bFinished then
			data[tostring(dwID)] = true
		end
	end
	LR_ACS_QiYu.SelfAchievementData = clone(data)
end

function LR_ACS_QiYu.SaveData()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	LR_ACS_QiYu.GetSelfQiYuAchievementData()
	local ServerInfo = {GetUserServer()}
	local realArea, realServer = ServerInfo[5], ServerInfo[6]
	local dwID = me.dwID
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	local DB_REPLACE = DB:Prepare("REPLACE INTO qiyu_data ( szKey, qiyu_data, qiyu_achievement, bDel ) VALUES ( ?, ?, ?, ? )")
	if LR_AccountStatistics.UsrData.OthersCanSee then
		local SelfData = {}
		for k, v in pairs(LR_ACS_QiYu.SelfData) do
			SelfData[tostring(k)] = v
		end
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey, LR.JsonEncode(SelfData), LR.JsonEncode(LR_ACS_QiYu.SelfAchievementData or {}), 0)
		DB_REPLACE:Execute()
	else
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey, LR.JsonEncode({}), LR.JsonEncode({}), 1)
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
		for k, v in pairs (LR.JsonDecode(v.qiyu_data) or {}) do
			qiyu_data[tonumber(k)] = v
		end
		AllUsrData[v.szKey].qiyu_data = clone(qiyu_data)
		local achievement_data = {}
		for k, v in pairs (LR.JsonDecode(v.qiyu_achievement) or {}) do
			achievement_data[k] = v
		end
		AllUsrData[v.szKey].qiyu_achievement = clone(achievement_data)
	end
	if next(LR_ACS_QiYu.SelfData) == nil then
		AllUsrData[szSelfKey] = AllUsrData[szSelfKey] or {}
		LR_ACS_QiYu.SelfData = AllUsrData[szSelfKey].qiyu_data or {}
	else
		AllUsrData[szSelfKey] = {}
		AllUsrData[szSelfKey].qiyu_data = clone(LR_ACS_QiYu.SelfData)
	end
	LR_ACS_QiYu.GetSelfQiYuAchievementData()
	AllUsrData[szSelfKey].qiyu_achievement = clone(LR_ACS_QiYu.SelfAchievementData)
	LR_ACS_QiYu.AllUsrData = clone(AllUsrData)
end

function LR_ACS_QiYu.ClearAllData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM qiyu_data WHERE bDel = 0")
	local Data = DB_SELECT:GetAll() or {}
	local DB_REPLACE = DB:Prepare("REPLACE INTO qiyu_data ( szKey, qiyu_data, qiyu_achievement, bDel ) VALUES ( ?, ?, ?, 0 )")
	if Data and next(Data) ~= nil then
		for k, v in pairs (Data) do
			DB_REPLACE:ClearBindings()
			DB_REPLACE:BindAll(v.szKey, LR.JsonEncode({}), v.qiyu_achievement)
			DB_REPLACE:Execute()
		end
	end
	LR_ACS_QiYu.SelfData = {}
end

local _tempTime = 0
function LR_ACS_QiYu.CheckItemNum(dwTabType, dwIndex)
	local now = GetLogicFrameCount()
	if now - _tempTime < 2 then
		LR.DelayCall(100, function() LR_ACS_QiYu.CheckItemNum(dwTabType, dwIndex) end)
		return
	end
	for k, v in pairs(QIYU) do
		if QIYU_ITEM[v] then
			local data = QIYU_ITEM[v] or {}
			for k2, v2 in pairs (data) do
				if dwTabType == v2.dwTabType and dwIndex == v2.dwIndex then
					local num = LR_ACS_QiYu.GetSingleItemNum(dwTabType, dwIndex)
					local flag = true
					if QIYU_MNTP[v] ==  MONITOR_TYPE.MULTI_ITEM then
						local me = GetClientPlayer()
						local scene = me.GetScene()
						if scene.dwMapID ~=  QIYU_MAP[v] then
							flag = false
						end
						local nType, dwID = me.GetTarget()
						if nType ==  TARGET.NPC then
							local tar = LR.GetTarget(nType, dwID)
							if tar.dwTemplateID ~=  QIYU_NPC[v] then
								flag = false
							end
						else
							flag = false
						end
					end
					local key = sformat("%d_%d", dwTabType, dwIndex)
					if num < QIYU_ITEM_NUM[key] and flag then
						LR_ACS_QiYu.SelfData[v] = LR_ACS_QiYu.SelfData[v] or 0
						LR_ACS_QiYu.SelfData[v] = LR_ACS_QiYu.SelfData[v] + 1
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
	LR_ACS_QiYu.LoadCommomUsrData()

	for k, v in pairs(QIYU) do
		if QIYU_ITEM[v] then
			local data = QIYU_ITEM[v] or {}
			for k2, v2 in pairs(data) do
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
		if QIYU_WINDOW_DIALOG[v] then
			local data = QIYU_WINDOW_DIALOG[v] or {}
			if dwMapID ==  QIYU_MAP[v] and dwTemplateID ==  QIYU_NPC[v] then
				local bFound = false
				local bFinish = false
				for k2, v2 in pairs(data) do
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
		if QIYU_MSG_NPC_NEARBY[v] then
			local data = QIYU_MSG_NPC_NEARBY[v]
			if dwMapID == QIYU_MAP[v] then
				local bFound = false
				local bFinish = false
				local szNpcName = LR.Trim(Table_GetNpcTemplateName(QIYU_NPC[v]))
				for k2, v2 in pairs(data) do
					local _start, _end = sfind(szMsg, v2.szText)
					local _start2, _end2 = sfind(szMsg, szNpcName)
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

function LR_ACS_QiYu.ON_WARNING_MESSAGE()
	local nMsgType = arg0
	local szMsg = arg1

	local me = GetClientPlayer()
	if not me then
		return
	end
	local scene = me.GetScene()
	local dwMapID = scene.dwMapID

	for k, v in pairs(QIYU) do
		if QIYU_WARNING_MSG[v] then
			local data = QIYU_WARNING_MSG[v] or {}
			if dwMapID == QIYU_MAP[v] then
				local bFound = false
				local bFinish = false
				for k2, v2 in pairs(data) do
					local _start, _end = sfind(szMsg, v2.szText)
					if _start then
						bFound = true
						if v2.bFinish then
							bFinish = true
						end
					end
				end
				if bFound then
					LR_ACS_QiYu.SelfData[v] = LR_ACS_QiYu.SelfData[v] or 0
					LR_ACS_QiYu.SelfData[v] = LR_ACS_QiYu.SelfData[v] + 1
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
LR.RegisterEvent("ON_WARNING_MESSAGE", function() LR_ACS_QiYu.ON_WARNING_MESSAGE() end)
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
		local dwID = TempTable[i].dwID
		local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
		LR_ACS_QiYu.AllUsrData[szKey] = LR_ACS_QiYu.AllUsrData[szKey] or {}
		local QY_Record = LR_ACS_QiYu.AllUsrData[szKey].qiyu_data or {}
		local QY_Achievement  = LR_ACS_QiYu.AllUsrData[szKey].qiyu_achievement or {}
		local ServerInfo2 = {GetUserServer()}
		local loginArea2, loginServer2, realArea2, realServer2 = ServerInfo2[3], ServerInfo2[4], ServerInfo2[5], ServerInfo2[6]

		if realArea2 == realArea and realServer2 == realServer and me.dwID == dwID then
			QY_Record = LR_ACS_QiYu.SelfData or {}
		end

		------输出日常
		local n = 1
		local List = LR_ACS_QiYu.List
		for k, v in pairs(QIYU) do
			if n<10 then
				if LR_ACS_QiYu.UsrData.List[QIYU_NAME[v]] then
					local Text_QY = items:Lookup(sformat("Text_QY%d", n))
					if QY_Achievement[tostring(QIYU_ACHIEVEMENT[v])] then
						Text_QY:SetText(_L["Done"])
						Text_QY:SetFontScheme(47)
					else
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
				if QY_Achievement[tostring(QIYU_ACHIEVEMENT[v])] then
					text = _L["Done"]
					font = 47
				else
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
			local dwID = TempTable[i].dwID
			LR_ACS_QiYu_Panel:Open(realArea, realServer, dwID)
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

	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	LR_ACS_QiYu.LoadAllUsrData(DB)
	DB:Execute("END TRANSACTION")
	DB:Release()

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
	local hComboBox = self:Append("ComboBox", frame, "hComboBox", {w = 160, x = 20, y = 51, text = ""})
	hComboBox:Enable(true)
	hComboBox.OnClick = function (m)
		local TempTable_Cal, TempTable_NotCal = LR_AccountStatistics.SeparateUsrList()
		tsort(TempTable_Cal, function(a, b)
			if a.nLevel ==  b.nLevel then
				return a.dwForceID < b.dwForceID
			else
				return a.nLevel > b.nLevel
			end
		end)

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
				if TempTable[i * 20 + k] ~=  nil then
					local szIcon, nFrame = GetForceImage(TempTable[i * 20 + k].dwForceID)
					local r, g, b = LR.GetMenPaiColor(TempTable[i * 20 + k].dwForceID)
					page[i][#page[i]+1] = {szOption = sformat("(%d)%s", TempTable[i * 20 + k].nLevel, TempTable[i * 20 + k].szName), bCheck = false, bChecked = false,
						fnAction =  function ()
							local realArea = TempTable[i * 20 + k].realArea
							local realServer = TempTable[i * 20 + k].realServer
							local dwID = TempTable[i * 20 + k].dwID
							LR_ACS_QiYu_Panel:ReloadItemBox(realArea, realServer, dwID)
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
			if i ~=  page_num - 1 then
				page[i][#page[i] + 1] = {bDevide = true}
				page[i][#page[i] + 1] = page[i+1]
				page[i][#page[i]].szOption = _L["Next 20 Records"]
			end
		end

		m = page[0]

		local __x, __y = hComboBox:GetAbsPos()
		local __w, __h = hComboBox:GetSize()
		m.nMiniWidth = __w
		m.x = __x
		m.y = __y + __h
		PopupMenu(m)
	end

	self:LoadItemBox(hScroll)
	hScroll:UpdateList()
end

function LR_ACS_QiYu_Panel:Open(realArea, realServer, dwID)
	local frame = self:Fetch("LR_ACS_QiYu_Panel")
	if frame then
		if realArea then
			LR_ACS_QiYu_Panel:ReloadItemBox(realArea, realServer, dwID)
		else
			self:Destroy(frame)
		end
	else
		if realArea then
			LR_ACS_QiYu_Panel.realArea = realArea
			LR_ACS_QiYu_Panel.realServer = realServer
			LR_ACS_QiYu_Panel.dwID = dwID
		else
			local serverInfo = {GetUserServer()}
			local realArea, realServer = serverInfo[5], serverInfo[6]
			local dwID = GetClientPlayer().dwID
			LR_ACS_QiYu_Panel.realArea = realArea
			LR_ACS_QiYu_Panel.realServer = realServer
			LR_ACS_QiYu_Panel.dwID = dwID
		end
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

function LR_ACS_QiYu_Panel:LoadItemBox(hWin)
	local realServer = LR_ACS_QiYu_Panel.realServer
	local realArea = LR_ACS_QiYu_Panel.realArea
	local dwID = LR_ACS_QiYu_Panel.dwID

	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)

	--设置ComboBox的名字
	local hComboBox = self:Fetch("hComboBox")
	hComboBox:SetText(LR_AccountStatistics.AllUsrList[szKey].szName)

	LR_ACS_QiYu.AllUsrData[szKey] = LR_ACS_QiYu.AllUsrData[szKey] or {}
	local QY_Record = LR_ACS_QiYu.AllUsrData[szKey].qiyu_data or {}
	local QY_Achievement = LR_ACS_QiYu.AllUsrData[szKey].qiyu_data or {}
	local ServerInfo2 = {GetUserServer()}
	local loginArea2, loginServer2, realArea2, realServer2 = ServerInfo2[3], ServerInfo2[4], ServerInfo2[5], ServerInfo2[6]
	local me = GetClientPlayer()
	if realArea2 == realArea and realServer2 == realServer and me.dwID == dwID then
		QY_Record = LR_ACS_QiYu.SelfData or {}
		QY_Achievement = LR_ACS_QiYu.SelfAchievementData or {}
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

		if QY_Achievement[tostring(QIYU_ACHIEVEMENT[v])] then
			times = _L["Done"]
		else
			local times = QY_Record[v] or 0
			if times >= 3 then
				times = _L["Done"]
			end
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

function LR_ACS_QiYu_Panel:ReloadItemBox(realArea, realServer, dwID)
	local hComboBox = self:Fetch("hComboBox")
	hComboBox:SetText(szName)
	LR_ACS_QiYu_Panel.dwID = dwID
	LR_ACS_QiYu_Panel.realServer = realServer
	LR_ACS_QiYu_Panel.realArea = realArea
	local cc = self:Fetch("Scroll")
	if cc then
		self:ClearHandle(cc)
	end
	self:LoadItemBox(cc)
	cc:UpdateList()
end









