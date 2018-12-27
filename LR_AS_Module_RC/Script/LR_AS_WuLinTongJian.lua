local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AS_Module_RC"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local _L = LR.LoadLangPack(AddonPath)
local VERSION = "20181225"
-------------------------------------------------------------
---武林通鉴任务id 2018.12.25更新
local WLTJ_ID = {
	t5R = {19199, 19243, 19244, 19245, 19246, 19247, 19248, 19250, 19251, 19252, 19253, 19254, 19255, 19256, 19257, 19258, 19259, 19260, 19261, 19262, 19263, 19264, 19265, 19266, 19267, 19268, 19269, 19270, 19271, 19272, 19273, 19274, 19616, 19617, 19618, 19619, 19620, 19621, 19622, 19623},
	t10R = {19219, 19220, 19276, 19277, 19278, 19279, 19280, 19281, 19282, 19283, 19284, 19285, 19286, 19287, 19288, 19289, 19290, 19291, 19292, 19293, 19294, 19295, 19296, 19297, 19298, 19299, 19300, 19661, 19662},
	tCommon = {19376, 19424, 19425, 19426, 19427, 19428, 19429, 19430, 19431, 19432, 19433, 19434, 19435, 19436},
}

local ID_CAN_DO = {}	--用于存放当前做任务

local _C = {}
function _C.GetIDCanDo(SkipLoad)
	local me = GetClientPlayer()
	if not me then
		return
	end
	if SkipLoad then
		local path = sformat("%s\\WLTJ_ID.dat", SaveDataPath)
		local data = LoadLUAData(path) or {}
		if next(data) ~= nil then
			ID_CAN_DO = clone(data)
			return
		end
	end
	if me.nLevel < 100 then
		return
	end
	local _, _dwID = me.GetTarget()
	local key = {"tCommon", "t5R", "t10R",}
	for k, v in pairs(key) do
		for k2, dwQuestID in pairs(WLTJ_ID[v]) do
			local eCanAccept = me.CanAcceptQuest(dwQuestID, 14211)
			local tQuestStringInfo = LR.Table_GetQuestStringInfo(dwQuestID)
			if dwQuestID == 19260 then
				Output(dwQuestID, tQuestStringInfo.szName, eCanAccept, g_tStrings.tQuestResultString[eCanAccept])
			end
			if eCanAccept == 1 or eCanAccept == 7 or eCanAccept == 57 then	--1:可接任务	7：已经接受了任务	57：完成已达上限	2：不可接
				ID_CAN_DO[v] = ID_CAN_DO[v] or {}
				tinsert(ID_CAN_DO[v], dwQuestID)
			end
		end
	end
end

function _C.ClearWLTJdatMonday()
	local path = sformat("%s\\WLTJ_ID.dat", SaveDataPath)
	SaveLUAData(path, {})
end

function _C.LockWLTJdat()
	local data = clone(ID_CAN_DO)
	local path = sformat("%s\\WLTJ_ID.dat", SaveDataPath)
	SaveLUAData(path, data)
end

function _C.RefreshWLTJdat()
	_C.GetIDCanDo(true)
	--刷新UI

end

--任务记录
function _C.GetData()
	local me = GetClientPlayer()
	local CurrentTime =  GetCurrentTime()
	local _date = TimeToDate(CurrentTime)
	Output(_date)
	if me.nLevel < 100 then
		return
	end
	if next(ID_CAN_DO) == nil then
		_C.GetIDCanDo()
	end
	local key = {"tCommon", "t5R", "t10R",}
	for k, v in pairs(key) do
		for k2, dwQuestID in pairs(ID_CAN_DO[v]) do
			local tTraceInfo = me.GetQuestTraceInfo(dwQuestID)
			local tQuestStringInfo = LR.Table_GetQuestStringInfo(dwQuestID)
			Output(tQuestStringInfo.szName, tTraceInfo)
		end
	end
end




LR_WLTJ = {}
LR_WLTJ.GetData = _C.GetData
LR_WLTJ.GetIDCanDo = _C.GetIDCanDo
