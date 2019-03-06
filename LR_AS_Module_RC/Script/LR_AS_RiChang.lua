local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AS_Module_RC"
local LanguagePath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local db_name = "maindb.db"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20180809"
-------------------------------------------------------------
local RI_CHANG = {
	DA = 1, 	--��ս
	GONG = 2, 	--�����ճ�
	CHA = 3, 	--���
	QIN = 4, 	--���޲��
	JU = 5, 	--�ݵ�ó��
	JING = 6, 	--��������
	MEI = 7, 	--ÿ����ʤ
	CAI = 8, 	--���ɲ�
	XUN = 9, 	--Ѱ����
	TU = 10, 	--����ͼ
	MI = 11, 	--�ٱ���/����
	HUIGUANG = 12, 	--�ع�(7����)
	HUASHAN = 13, 	--����(7����)
	LONGMENJUEJING = 14,	--�Լ�
	LUOYANGSHENBING = 15,	--�������
	ZHENYINGRICHANG = 16,	--��Ӫ�ճ�
}

local RI_CHANG_NAME = {
	[RI_CHANG.DA] = _L["DA"], 	--��ս
	[RI_CHANG.GONG] = _L["GONG"], 	--�����ճ�
	[RI_CHANG.CHA] = _L["CHA"], 	--���
	[RI_CHANG.QIN] = _L["QIN"], 	--���޲��
	[RI_CHANG.JU] = _L["JU"], 	--�ݵ�ó��
	[RI_CHANG.JING] = _L["JING"], 	--��������
	[RI_CHANG.MEI] = _L["MEI"], 	--ÿ����ʤ
	[RI_CHANG.CAI] = _L["CAI"], 	--���ɲ�
	[RI_CHANG.XUN] = _L["XUN"], 	--Ѱ����
	[RI_CHANG.TU] = _L["TU"], 	--����ͼ
	[RI_CHANG.MI] = _L["MI"], 	--�ٱ���/����
	[RI_CHANG.HUIGUANG] = _L["HUIGUANG"], 	--�ع�(7����)
	[RI_CHANG.HUASHAN] = _L["HUASHAN"], 	--����(7����)
	[RI_CHANG.LONGMENJUEJING] = _L["LONGMENJUEJING"], 	--�Լ�
	[RI_CHANG.LUOYANGSHENBING] = _L["LUOYANGSHENBING"], 	--�������
	[RI_CHANG.ZHENYINGRICHANG] = _L["ZHENYINGRICHANG"], 	--��Ӫ�ճ�
}

local RESET_TYPE = {
	NONE = 0,
	EVERY_DAY = 1,
	MONDAY = 2,
	THURSDAY = 3,
}

LR_AS_RC = {}
LR_AS_RC.Default = {
	List = {
		[RI_CHANG.DA] = true,
		[RI_CHANG.GONG] = true,
		[RI_CHANG.CHA] = true,
		[RI_CHANG.QIN] = true,
		[RI_CHANG.JU] = true,
		[RI_CHANG.JING] = true,
		[RI_CHANG.CAI] = false,
		[RI_CHANG.XUN] = true,
		[RI_CHANG.TU] = true,
		[RI_CHANG.MI] = false,
		[RI_CHANG.HUIGUANG] = false,
		[RI_CHANG.HUASHAN] = false,
		[RI_CHANG.LONGMENJUEJING] = false,
		[RI_CHANG.LUOYANGSHENBING] = false,
		[RI_CHANG.ZHENYINGRICHANG] = false,
	},
	bUseCommonData = true,
	InstantSaving = false,
	Version = VERSION,
}
LR_AS_RC.UsrData = clone(LR_AS_RC.Default)
RegisterCustomData("LR_AS_RC.UsrData", VERSION)

LR_AS_RC.CustomQuestList = {}

local _RC = {}
_RC.RI_CHANG = RI_CHANG
_RC.RI_CHANG_NAME = RI_CHANG_NAME

_RC.AllUsrData = {}
_RC.SelfData = {
	[RI_CHANG.DA] = {eQuestPhase = 0, need = 100, have = 0, finished = false,	},
	[RI_CHANG.GONG] = {eQuestPhase = 0, need = 100, have = 0, finished = false,	},
	[RI_CHANG.CHA] = {eQuestPhase = 0, need = 10, have = 0, finished = false,	},
	[RI_CHANG.QIN] = {eQuestPhase = 0, need = 3, have = 0, finished = false,	},
	[RI_CHANG.JU] = {eQuestPhase = 0, need = 3000, have = 0, finished = false,	},
	[RI_CHANG.JING] = {eQuestPhase = 0, need = 1000, have = 0, finished = false,	},
	[RI_CHANG.MEI] = {eQuestPhase = 0, need = 3, have = 0, finished = false,	},
	[RI_CHANG.CAI] = {eQuestPhase = 0, need = 7, have = 0, finished = false,	},
	[RI_CHANG.XUN] = {eQuestPhase = 0, need = 5, have = 0, finished = false,	},
	[RI_CHANG.TU] = {eQuestPhase = 0, need = 2, have = 0, finished = false,	},
	[RI_CHANG.MI] = {eQuestPhase = 0, need = 2, have = 0, finished = false,	},
	[RI_CHANG.HUIGUANG] = {eQuestPhase = 0, need = 1, have = 0, finished = false,	},
	[RI_CHANG.HUASHAN] = {eQuestPhase = 0, need = 100, have = 0, finished = false,	},
	[RI_CHANG.LONGMENJUEJING] = {eQuestPhase = 0, need = 2, have = 0, finished = false,	},
	[RI_CHANG.LUOYANGSHENBING] = {eQuestPhase = 0, need = 1000, have = 0, finished = false,	},
	[RI_CHANG.ZHENYINGRICHANG] = {eQuestPhase = 0, need = 1000, have = 0, finished = false,	},
}

_RC.SelfCustomQuestStatus = {}

-------------------------------
local MONITED_QUEST_LIST = {}		----��������б��е����񲻻ᴥ������
local ADD2MONITED_QUEST_LIST = function(tList)
	for k, v in pairs (tList or {}) do
		MONITED_QUEST_LIST[k] = true
	end
end

------------------------------
----������ʾ���ճ��б�
----�����б�����
function _RC.ResetMenuList()
	local me = GetClientPlayer()
	if not me then
		return
	end
	LR_AS_RC.UsrData = clone(LR_AS_RC.Default)
	if LR_AS_RC.UsrData.bUseCommonData then
		_RC.SaveCommomMenuList()
	end
end

function _RC.CheckCommomMenuList()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local  path = sformat("%s\\RiChangCommonData.dat.jx3dat", SaveDataPath)
	if not IsFileExist(path) then
		local CommomMenuList = LR_AS_RC.Default
		local path = sformat("%s\\RiChangCommonData.dat", SaveDataPath)
		SaveLUAData (path, CommomMenuList)
	end
end

function _RC.SaveCommomMenuList()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_AS_RC.UsrData.bUseCommonData then
		return
	end
	local CommomMenuList = LR_AS_RC.UsrData
	local path = sformat("%s\\RiChangCommonData.dat", SaveDataPath)
	SaveLUAData (path, CommomMenuList)
end

function _RC.LoadCommomMenuList()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_AS_RC.UsrData.bUseCommonData then
		return
	end
	_RC.CheckCommomMenuList()
	local path = sformat("%s\\RiChangCommonData.dat", SaveDataPath)
	local CommomMenuList = LoadLUAData  (path) or {}
	LR_AS_RC.UsrData = clone(CommomMenuList)
end

----------------------------------------------------------------------------------------
----�Զ���������
----------------------------
function _RC.SaveCustomQuestList()
	local path = sformat("%s\\CustomQuestList.dat", SaveDataPath)
	local data = LR_AS_RC.CustomQuestList or {}
	SaveLUAData(path, data)
end

function _RC.LoadCustomQuestList()
	local path = sformat("%s\\CustomQuestList.dat", SaveDataPath)
	local data = LoadLUAData(path) or {}
	LR_AS_RC.CustomQuestList = clone(data)
	local quest_list = {}
	for k, v in pairs (data) do
		quest_list[tonumber(v.dwID)] = true
	end
	ADD2MONITED_QUEST_LIST(quest_list)
end

function _RC.GetCustomQuestStatus()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local CustomQuestList = LR_AS_RC.CustomQuestList
	local data = {}
	for k, v in pairs (CustomQuestList) do
		local dwID = v.dwID
		local dwTemplateID = v.dwTemplateID or 0
		data[tostring(dwID)] = {nQuestPhase = 0, need = 0, have = 0, full = false,}

		local nQuestPhase = me.GetQuestPhase(dwID)	--3: ��ʾ���������0: ��ʾ���񲻴���1: ��ʾ�������ڽ����У�2: ��ʾ��������ɵ���û�н�-1: ��ʾ����id�Ƿ�
		if nQuestPhase > 0 then
			data[tostring(dwID)].nQuestPhase = nQuestPhase
		end

		local QuestTraceInfo = me.GetQuestTraceInfo(dwID)
		if QuestTraceInfo then
			local quest_state = QuestTraceInfo.quest_state or {}
			local kill_npc = QuestTraceInfo.kill_npc or {}
			local need_item = QuestTraceInfo.need_item or {}
			local need = 0
			local have = 0
			for k , v in pairs (kill_npc) do
				need = need + v.need or 0
				have = have + v.have or 0
			end
			for k , v in pairs (quest_state) do
				need = need + v.need or 0
				have = have + v.have or 0
			end
			for k , v in pairs (need_item) do
				need = need + v.need or 0
				have = have + v.have or 0
			end
			data[tostring(dwID)].need = need
			data[tostring(dwID)].have = have
		end

		if dwTemplateID > 0 then
			local eCanAccept = me.CanAcceptQuest(dwID, dwTemplateID)		------�á���ս��Ӣ��΢ɽ��Ժ�������Դ�ս�Ƿ���cd ������57��������ɶ��Ѵ�����
			if eCanAccept ==  57 then
				data[tostring(dwID)].full = true
			else
				data[tostring(dwID)].full = false
			end
		end
	end
	_RC.SelfCustomQuestStatus = clone(data)
end

-----------------------------------------------------------------------------------------
function _RC.LoadAllUsrData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM richang_data WHERE bDel = 0 AND szKey IS NOT NULL ")
	local Data = d2g(DB_SELECT:GetAll())
	local AllUsrData = {}
	if Data and next(Data) ~= nil then
		for k, v in pairs(Data) do
			local data2 = {}
			for k2, v2 in pairs(v) do
				if k2 ~="szKey" and k2 ~= "bDel" then
					if RI_CHANG[k2] then
						data2[RI_CHANG[k2]] = LR.JsonDecode(v2)
					else
						data2["CUSTOM_QUEST"] = LR.JsonDecode(v2)
					end
				end
			end
			AllUsrData[v.szKey] = data2
		end
	end
	_RC.AllUsrData = clone(AllUsrData)
	local me = GetClientPlayer()
	if not me or IsRemotePlayer(me.dwID) then
		return
	end
	_RC.CheckAll()		--�����������״̬
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	_RC.AllUsrData[szKey] = clone(_RC.SelfData)

	_RC.GetCustomQuestStatus()
	_RC.AllUsrData[szKey].CUSTOM_QUEST = clone(_RC.SelfCustomQuestStatus)
end

function _RC.SaveData(DB)
	if not LR_AS_Base.UsrData.bRecord then
		return
	end
	local me = GetClientPlayer()
	if not me or IsRemotePlayer(me.dwID) then
		return
	end
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	_RC.CheckAll()
	local name, wen, value = {}, {}, {}
	for k, v in pairs(RI_CHANG) do
		name[#name+1] = k
		wen[#wen+1] = "?"
		value[#value+1] = LR.JsonEncode(_RC.SelfData[v])
	end
	---�����Զ�����������
	_RC.GetCustomQuestStatus()
	name[#name+1] = "CUSTOM_QUEST"
	wen[#wen+1] = "?"
	value[#value+1] = LR.JsonEncode(_RC.SelfCustomQuestStatus or {})

	local DB_REPLACE = DB:Prepare(sformat("REPLACE INTO richang_data ( bDel, szKey, %s ) VALUES ( ?, %s, ? )", tconcat(name, ", "), tconcat(wen, ", ")))
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(unpack(g2d({0, szKey, unpack(value)})))
	DB_REPLACE:Execute()
end

----------------------------------------------------------------------------
---------�����ճ����
_RC.List = {
	[1] = {szName = _L["DA"], nType = "RC", order = RI_CHANG.DA, },
	[2] = {szName = _L["CHA"], nType = "RC", order = RI_CHANG.CHA, },
	[3] = {szName = _L["GONG"], nType = "RC", order = RI_CHANG.GONG, },
	[4] = {szName = _L["JU"], nType = "RC", order = RI_CHANG.JU, },
	[5] = {szName = _L["JING"], nType = "RC", order = RI_CHANG.JING, },
	[6] = {szName = _L["QIN"], nType = "RC", order = RI_CHANG.QIN, },
	[7] = {szName = _L["TU"], nType = "RC", order = RI_CHANG.TU, },
	[8] = {szName = _L["CAI"], nType = "RC", order = RI_CHANG.CAI, },
	[9] = {szName = _L["XUN"], nType = "RC", order = RI_CHANG.XUN, },
	[10] = {szName = _L["MI"], nType = "RC", order = RI_CHANG.MI, },
	[11] = {szName = _L["HUIGUANG"], nType = "RC", order = RI_CHANG.HUIGUANG, },
	[12] = {szName = _L["HUASHAN"], nType = "ONCE", order = RI_CHANG.HUASHAN, },
	[13] = {szName = _L["LONGMENJUEJING"], nType = "ZC", order = RI_CHANG.LONGMENJUEJING, },
	[14] = {szName = _L["LUOYANGSHENBING"], nType = "RC", order = RI_CHANG.LUOYANGSHENBING, },
	[14] = {szName = _L["ZHENYINGRICHANG"], nType = "RC", order = RI_CHANG.ZHENYINGRICHANG, },
}

----��ս��������
_RC.Dazhan = {
	----[����id] = true,
--[[95����
	[14765] = true, 		--14765 ��ս��Ӣ��΢ɽ��Ժ��
	[14766] = true, 		--14766 ��ս��Ӣ�������֣�
	[14767] = true, 		--14767 ��ս��Ӣ�������Ժ��
	[14768] = true, 		--14768 ��ս��Ӣ����ɽʥȪ��
	[14769] = true, 		--14769 ��ս��Ӣ������ˮ鿣�]]
--[[95���İ��
	[17816] = true,		--��������
	[17817] = true,		--�����
	[17818] = true,		--���ֺ���
	[17819] = true,		--Ϧ�ո�
	[17820] = true,		--�׵�ˮ��]]
--100����ս
	[19191] = true,	--�ű��
	[19192] = true,	--��������
	[19195] = true,	--������
	[19196] = true,	--������˿��
	[19197] = true,	--��Ԩ��

}
ADD2MONITED_QUEST_LIST(_RC.Dazhan)

-----����ս״̬
function _RC.CheckDazhan()
	local me = GetClientPlayer()
	if not me then
		return
	end

	local Dazhan = _RC.Dazhan
	local eQuestPhase = 0
	local dwQuestID = 0
	for k, v in pairs (Dazhan) do
		local _eQuestPhase = me.GetQuestPhase(k)	----- -1���Ƿ�	0�����񲻴���	1�����������	2��������ɵ�û��	3��������ɣ����񲻴��ڣ�û������
		if _eQuestPhase ~=  0 and _eQuestPhase ~=  -1 then
			eQuestPhase = _eQuestPhase
			dwQuestID = k
		end
	end
	if dwQuestID ~=  0 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local kill_npc = QuestTraceInfo.kill_npc
		local need = 0
		local have = 0
		for k , v in pairs (kill_npc) do
			if v.need ==  v.have then
				have = have+1
			end
			need = need+1
		end
		for k , v in pairs (quest_state) do
			if v.need ==  v.have then
				have = have+1
			end
			need = need+1
		end
		_RC.SelfData[RI_CHANG.DA] = {eQuestPhase = eQuestPhase, need = need, have = have, }
	else
		_RC.SelfData[RI_CHANG.DA] = {eQuestPhase = eQuestPhase, need = 3, have = 0, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:869 �ؾ���������
	local eCanAccept = me.CanAcceptQuest(19191, 869)		------�á���ս��Ӣ�۾ű絺�������Դ�ս�Ƿ���cd ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		_RC.SelfData[RI_CHANG.DA].finished = true
	else
		_RC.SelfData[RI_CHANG.DA].finished = false
	end
end


-------�����Ӫ�ճ�
local ZHENYINGRICHANG_QUEST = {
	--����
	[14894] = true,
	[18936] = true,
	[19201] = true,
	[19311] = true,
	[19720] = true,
	--����
	[14893] = true,
	[18904] = true,
	[19200] = true,
	[19310] = true,
	[19719] = true,
}
ADD2MONITED_QUEST_LIST(ZHENYINGRICHANG_QUEST)
function _RC.CheckZHENYINGRICHANG()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not (me.nCamp == 1 or me.nCamp == 2) then
		return
	end
	local dwTemplateID, dwQuestID = 0, 0
	local IDs = {}
	if me.nCamp == 1 then		--����
		dwTemplateID = 62002
		IDs = {14893, 18904, 19200, 19310, 19719}
	elseif me.nCamp == 2 then		--����
		dwTemplateID = 62039
		IDs = {14894, 18936, 19201, 19311, 19720}
	end

	for k, _dwQuestID in pairs(IDs) do
		local eCanAccept = me.CanAcceptQuest(_dwQuestID, dwTemplateID)
		if eCanAccept == 1 or eCanAccept == 7 or eCanAccept == 57 then
			dwQuestID = _dwQuestID
		end
	end
	if dwQuestID == 0 then
		return
	end
	_RC.SelfData[RI_CHANG.ZHENYINGRICHANG] = {eQuestPhase = 0, need = 1000, have = 0, finished = false,}
	local eCanAccept = me.CanAcceptQuest(dwQuestID, dwTemplateID)
	if eCanAccept == 57 then
		_RC.SelfData[RI_CHANG.ZHENYINGRICHANG].finished = true
		return
	end
	if eCanAccept == 7 then
		local eQuestPhase = me.GetQuestPhase(dwQuestID)
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state or {{need = 0, have = 0}}
		local need = quest_state[1].need
		local have = quest_state[1].have
		_RC.SelfData[RI_CHANG.ZHENYINGRICHANG].eQuestPhase = eQuestPhase
		_RC.SelfData[RI_CHANG.ZHENYINGRICHANG].need = need
		_RC.SelfData[RI_CHANG.ZHENYINGRICHANG].have = have
	end
end


-------��鹫���¼�
--local dwQuestID = 14831
local GONG_QUEST = {
	[14831] = true,
}
ADD2MONITED_QUEST_LIST(GONG_QUEST)
function _RC.CheckGongShiJian()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[������Զ��������] ����ID��14831
	local dwQuestID = 14831
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		_RC.SelfData[RI_CHANG.GONG] = {eQuestPhase = eQuestPhase, need = 100, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local need = quest_state[1].need
		local have = quest_state[1].have
		_RC.SelfData[RI_CHANG.GONG] = {eQuestPhase = eQuestPhase, need = need, have = have, }
	elseif eQuestPhase ==  3 then
		_RC.SelfData[RI_CHANG.GONG] = {eQuestPhase = eQuestPhase, need = 100, have = 100, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:869 �ؾ���������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 869)		------���Թ����ճ��Ƿ���cd ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		_RC.SelfData[RI_CHANG.GONG].finished = true
	else
		_RC.SelfData[RI_CHANG.GONG].finished = false
	end
end

-------�����
local CHA_QUEST = {
	--[14246] = true,	--95���������
	[19514] = true,	--100���������
}
ADD2MONITED_QUEST_LIST(CHA_QUEST)
function _RC.CheckChaGuan()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[���������в�] 95������ID��14246
	----[�׺��Ʒ��Ų���]	100������ID��19514
	local dwQuestID = 19514
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		_RC.SelfData[RI_CHANG.CHA] = {eQuestPhase = eQuestPhase, need = 10, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local need = quest_state[1].need
		local have = quest_state[1].have
		_RC.SelfData[RI_CHANG.CHA] = {eQuestPhase = eQuestPhase, need = need, have = have, }
	elseif eQuestPhase ==  3 then
		_RC.SelfData[RI_CHANG.CHA] = {eQuestPhase = eQuestPhase, need = 10, have = 10, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:45009 95�������		63734��100�������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 63734)		------���Բ���Ƿ���cd ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		_RC.SelfData[RI_CHANG.CHA].finished = true
	else
		_RC.SelfData[RI_CHANG.CHA].finished = false
	end
end

---------���޲������
_RC.QinXiu = {
	-----[dwQuestID] = ture,
	[8206] = true, 		-----���
	[8347] = true, 		-----����
	[8348] = true, 		-----��
	[8349] = true, 		-----����
	[8350] = true, 		-----����
	[8351] = true, 		-----�ؽ�
	[8352] = true, 		-----�嶾
	[8353] = true, 		-----����
	[8398] = true, 		-----����
	[8399] = true, 		-----��
	[8400] = true, 		-----����
	[8401] = true, 		-----����
	[8402] = true, 		-----�ؽ�
	[8403] = true, 		-----�嶾
	[8404] = true, 		-----����
	[9796] = true, 		-----����95��
	[9797] = true, 		-----����20~94��
	[11245] = true, 		-----ؤ��
	[11246] = true, 		-----ؤ��
	[12701] = true, 		-----����
	[12702] = true, 		-----����
	[11254] = true, 		-----�������
	[11255] = true, 		-----�������
	[14731] = true, 		-----����
	[14732] = true, 		-----����
	[16205] = true, 		-----�Ե�
	[16206] = true, 		-----�Ե�
	[19225] = true,		-----����
	[19226] = true,		-----����
}
ADD2MONITED_QUEST_LIST(_RC.QinXiu)
-----������޲��
function _RC.CheckQinXiu()
	local me = GetClientPlayer()
	if not me then
		return
	end

	local QinXiu = _RC.QinXiu
	local eQuestPhase = 0
	local dwQuestID = 0

	---------Ѱ�Ҹý�ɫӦ�ö�Ӧ��һ�����޲��
	for k, v in pairs (QinXiu) do
		local eCanAccept = me.CanAcceptQuest(k, 16747)
		if eCanAccept ==  57 or eCanAccept ==  1 or  eCanAccept ==  7 then
			dwQuestID = k
		end
	end

	if dwQuestID ~=  0 then
		local eQuestPhase = me.GetQuestPhase(dwQuestID)	----����״̬
		local eCanAccept = me.CanAcceptQuest(dwQuestID, 16747)		----����CD
		if eQuestPhase ==  0 or eQuestPhase ==  -1 then
			_RC.SelfData[RI_CHANG.QIN] = {eQuestPhase = eQuestPhase, need = 3, have = 0, }
		elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
			local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
			local quest_state = QuestTraceInfo.quest_state
			local need = quest_state[1].need
			local have = quest_state[1].have
			_RC.SelfData[RI_CHANG.QIN] = {eQuestPhase = eQuestPhase, need = need, have = have, }
		elseif eQuestPhase ==  3 then
			_RC.SelfData[RI_CHANG.QIN] = {eQuestPhase = eQuestPhase, need = 3, have = 3, }
		end
		if eCanAccept ==  57 then
			_RC.SelfData[RI_CHANG.QIN].finished = true
		else
			_RC.SelfData[RI_CHANG.QIN].finished = false
		end
	else
		_RC.SelfData[RI_CHANG.QIN] = {eQuestPhase = 0, need = 3, have = 0, finished = false, }
	end
end

-----���ݵ�ó��
local MAOYI_QUEST = {
	[11864] = true,
	[11991] = true,
}
ADD2MONITED_QUEST_LIST(MAOYI_QUEST)
function _RC.CheckMaoYi()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwQuestID = 0
	local dwTemplateID = 0
	if me.nCamp ==  1 then		-----������
		dwQuestID = 11864
		dwTemplateID = 36388
	elseif me.nCamp ==  2 then		----���˹�
		dwQuestID = 11991
		dwTemplateID = 36387
	end

	if dwQuestID ~=  0 then
		local eQuestPhase = me.GetQuestPhase(dwQuestID)	----����״̬
		local eCanAccept = me.CanAcceptQuest(dwQuestID, dwTemplateID)		----����CD
		if eQuestPhase ==  0 or eQuestPhase ==  -1 then
			_RC.SelfData[RI_CHANG.JU] = {eQuestPhase = eQuestPhase, need = "3K", have = 0, }
		elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
			local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
			local quest_state = QuestTraceInfo.need_item
			local need = quest_state[1].need
			local have = quest_state[1].have
			_RC.SelfData[RI_CHANG.JU] = {eQuestPhase = eQuestPhase, need = "3K", have = have, }
		elseif eQuestPhase ==  3 then
			_RC.SelfData[RI_CHANG.JU] = {eQuestPhase = eQuestPhase, need = "3K", have = 3000, }
		end
		if eCanAccept ==  57 then
			_RC.SelfData[RI_CHANG.JU].finished = true
		else
			_RC.SelfData[RI_CHANG.JU].finished = false
		end
	else
		_RC.SelfData[RI_CHANG.JU] = {eQuestPhase = 0, need = "3K", have = 0, finished = false, }
	end
end

-----��龧������
local JINGKUANG_QUEST = {
		[14727] = true, 	---��������ھ��������̡�
		[14728] = true, 	---���ˡ���ھ��������̡�
		[14729] = true, 	---��������ھ��������̡�
		[14730] = true, 	---���ˡ���ھ��������̡�
}
ADD2MONITED_QUEST_LIST(JINGKUANG_QUEST)
function _RC.CheckJingKuang()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[��ھ���������] ����ID�������ˣ�14727		���˹ȣ�14728
	local dwQuestID = 0
	local dwTemplateID = 0
	if me.nCamp ==  1 then		-----������
		dwTemplateID = 46968
	elseif me.nCamp ==  2 then		----���˹�
		dwTemplateID = 46969
	end

	local data = clone (JINGKUANG_QUEST)

	for k, v in pairs (data) do
		local eCanAccept = me.CanAcceptQuest(k, dwTemplateID)
		if eCanAccept ==  57 or eCanAccept ==  1 or  eCanAccept ==  7 then
			dwQuestID = k
		end
	end

	if dwQuestID ~=  0 then
		local eQuestPhase = me.GetQuestPhase(dwQuestID)
		if eQuestPhase ==  0 or eQuestPhase ==  -1 then
			_RC.SelfData[RI_CHANG.JING] = {eQuestPhase = eQuestPhase, need = "1K", have = 0, }
		elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
			local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
			local quest_state = QuestTraceInfo.quest_state
			local need = quest_state[1].need
			local have = quest_state[1].have
			_RC.SelfData[RI_CHANG.JING] = {eQuestPhase = eQuestPhase, need = "1K", have = have, }
		elseif eQuestPhase ==  3 then
			_RC.SelfData[RI_CHANG.JING] = {eQuestPhase = eQuestPhase, need = "1K", have = 1000, }
		end

		------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:46968 Ī�ƣ������ˣ�	;	46969 Ī��(���˹�)	��
		local eCanAccept = me.CanAcceptQuest(dwQuestID, dwTemplateID)		------���Ծ��������Ƿ���cd ������57��������ɶ��Ѵ�����
		if eCanAccept ==  57 then
			_RC.SelfData[RI_CHANG.JING].finished = true
		else
			_RC.SelfData[RI_CHANG.JING].finished = false
		end
	else
		_RC.SelfData[RI_CHANG.JING] = {eQuestPhase = 0, need = "1K", have = 0, finished = false, }
	end
end


-----�����ɲ�
local CAIXIANCAO_QUEST = {
	[8332] = true,
}
ADD2MONITED_QUEST_LIST(CAIXIANCAO_QUEST)
function _RC.CheckCaiCao()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[�����������ɲ�] ����ID��8332
	local dwQuestID = 8332
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		_RC.SelfData[RI_CHANG.CAI] = {eQuestPhase = eQuestPhase, need = 7, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local have = 0
		for k, v in pairs(quest_state) do
			if v.have == 1 then
				have = have+1
			end
		end
		_RC.SelfData[RI_CHANG.CAI] = {eQuestPhase = eQuestPhase, need = 7, have = have, }
	elseif eQuestPhase ==  3 then
		_RC.SelfData[RI_CHANG.CAI] = {eQuestPhase = eQuestPhase, need = 7, have = 7, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:16747 ���������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 16747)		------���Բ��ɲ��Ƿ���cd ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		_RC.SelfData[RI_CHANG.CAI].finished = true
	else
		_RC.SelfData[RI_CHANG.CAI].finished = false
	end
end

-----���Ѱ����
local XUNLONGMAI_QUEST = {
	[13600] = true,
}
ADD2MONITED_QUEST_LIST(XUNLONGMAI_QUEST)
function _RC.CheckLongMai()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[Ѱ�����������] ����ID��13600
	local dwQuestID = 13600
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		_RC.SelfData[RI_CHANG.XUN] = {eQuestPhase = eQuestPhase, need = 5, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local need = quest_state[1].need
		local have = quest_state[1].have
		_RC.SelfData[RI_CHANG.XUN] = {eQuestPhase = eQuestPhase, need = 5, have = have, }
	elseif eQuestPhase ==  3 then
		_RC.SelfData[RI_CHANG.XUN] = {eQuestPhase = eQuestPhase, need = 5, have = 5, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:16747 ���������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 16747)		------���Բ��ɲ��Ƿ���cd ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		_RC.SelfData[RI_CHANG.XUN].finished = true
	else
		_RC.SelfData[RI_CHANG.XUN].finished = false
	end
end

-----�������ͼ
local MEIRENTU_QUEST = {
	[7669] = true,
}
ADD2MONITED_QUEST_LIST(MEIRENTU_QUEST)
function _RC.CheckMeiRenTu()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[����ͼ] ����ID��7669
	local dwQuestID = 7669
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		_RC.SelfData[RI_CHANG.TU] = {eQuestPhase = eQuestPhase, need = 2, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local have = 0
		for k, v in pairs(quest_state) do
			if v.have == 1 then
				have = have+1
			end
		end
		_RC.SelfData[RI_CHANG.TU] = {eQuestPhase = eQuestPhase, need = 2, have = have, }
	elseif eQuestPhase ==  3 then
		_RC.SelfData[RI_CHANG.TU] = {eQuestPhase = eQuestPhase, need = 2, have = 2, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:16747 ���������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 16747)		------���Բ��ɲ��Ƿ���cd ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		_RC.SelfData[RI_CHANG.TU].finished = true
	else
		_RC.SelfData[RI_CHANG.TU].finished = false
	end
end

--------��ɽ���� dwTemplateID = 45660 ������
---dwQuestID:14603	[���е��¼�����]
---dwQuestID:14604	[��ϡ������ߵ�]
---dwQuestID:14605	[�޵������Է���]
---dwQuestID:14606	[��ϡ������ߵ�]
---dwQuestID:14607	[�ڸ��ɱ�ֵ���]
---dwQuestID:14608


-------�ٱ���*ī���� dwTemplateID = 45661 ��ƻ��
---dwQuestID:14609	[�������е��Ϲ�]
---dwQuestID:14610	[��ϡ������ߵ�]
---dwQuestID:14611	[��Ӯ�������ò�]
---dwQuestID:14612	[��ϡ������ߵ�]
---dwQuestID:14613	[�ٱ��ᾴ�ص���ɱ��]
local YINSHANHEISHI_QUEST = {
	[14603] = true,
	[14604] = true,
	[14605] = true,
	[14606] = true,
	[14607] = true,

	[14609] = true,
	[14610] = true,
	[14611] = true,
	[14612] = true,
	[14613] = true,
}
ADD2MONITED_QUEST_LIST(YINSHANHEISHI_QUEST)
-----������/�ٱ�������
function _RC.CheckHeiMi()
	local me = GetClientPlayer()
	if not me then
		return
	end

	local num_all = 0
	local num_finish = 0
	local num_accecp = 0

	local data_hei = {
		[14603] = true,
		[14604] = true,
		[14605] = true,
		[14606] = true,
		[14607] = true,
	}

	----�����ɽ��������
	local dwTemplateID = 45660
	for dwQuestID, v in pairs(data_hei) do
		local eCanAccept = me.CanAcceptQuest(dwQuestID, dwTemplateID)
		--Output(dwQuestID, eCanAccept)
		if eCanAccept ==  57 or eCanAccept ==  1 or  eCanAccept ==  7 then
			num_all = num_all+1
			if eCanAccept ==  57 then
				num_finish = num_finish +1
			end
			if eCanAccept ==  57 or eCanAccept ==  7 then
				num_accecp = num_accecp + 1
			end
		end
	end

	local data_mi = {
		[14609] = true,
		[14610] = true,
		[14611] = true,
		[14612] = true,
		[14613] = true,
	}

	----����ٱ�������
	dwTemplateID = 45661
	for dwQuestID, v in pairs(data_mi) do
		local eCanAccept = me.CanAcceptQuest(dwQuestID, dwTemplateID)
		if eCanAccept ==  57 or eCanAccept ==  1 or  eCanAccept ==  7 then
			num_all = num_all+1
			if eCanAccept ==  57 then
				num_finish = num_finish +1
			end
			if eCanAccept ==  57 or eCanAccept ==  7 then
				num_accecp = num_accecp + 1
			end
		end
	end

	_RC.SelfData[RI_CHANG.MI] = {eQuestPhase = 0, need = num_all, have = num_finish, }
	if num_accecp > 0 then
		_RC.SelfData[RI_CHANG.MI].eQuestPhase = 1
	end
	if num_all ==  num_finish and num_all ~= 0 then
		_RC.SelfData[RI_CHANG.MI] = {eQuestPhase = 0, need = 0, have = 0, }
		_RC.SelfData[RI_CHANG.MI].finished = true
	else
		_RC.SelfData[RI_CHANG.MI].finished = false
	end
end

-----��鵾������2016
local HUIGUANG_QUEST = {
	[15594] = true,
}
ADD2MONITED_QUEST_LIST(HUIGUANG_QUEST)
function _RC.CheckHUIGUANG()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[�ع�˷Ӱ] ����ID��15594
	local dwQuestID = 15594
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		_RC.SelfData[RI_CHANG.HUIGUANG] = {eQuestPhase = eQuestPhase, need = 0, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
--[[		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local need = quest_state[1].need
		local have = quest_state[1].have]]
		_RC.SelfData[RI_CHANG.HUIGUANG] = {eQuestPhase = eQuestPhase, need = 1, have = 1, }
	elseif eQuestPhase ==  3 then
		_RC.SelfData[RI_CHANG.HUIGUANG] = {eQuestPhase = eQuestPhase, need = 0, have = 0, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:52417 ���������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 52417)		------���Իع�˷Ӱ ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		_RC.SelfData[RI_CHANG.HUIGUANG].finished = true
	else
		_RC.SelfData[RI_CHANG.HUIGUANG].finished = false
	end
end

---�����ȹ�
local CHENXIANGSHANGU_QUEST = {
	[15770] = true,
}
ADD2MONITED_QUEST_LIST(CHENXIANGSHANGU_QUEST)
function _RC.CheckHuaShan()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[�����ȹ�] ����ID��15770
	local dwQuestID = 15770
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		_RC.SelfData[RI_CHANG.HUASHAN] = {eQuestPhase = eQuestPhase, need = 100, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local need_item = QuestTraceInfo.need_item
		local need = need_item[1].need
		local have = need_item[1].have
		_RC.SelfData[RI_CHANG.HUASHAN] = {eQuestPhase = eQuestPhase, need = 100, have = have, }
	elseif eQuestPhase ==  3 then
		_RC.SelfData[RI_CHANG.HUASHAN] = {eQuestPhase = eQuestPhase, need = 100, have = 100, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:15770 ���������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 52417)		------���Իع�˷Ӱ ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		_RC.SelfData[RI_CHANG.HUASHAN].finished = true
	else
		_RC.SelfData[RI_CHANG.HUASHAN].finished = false
	end
end

-----������ž���
local LONGMENJUEJING_QUEST = {
	[17895] = true,
}
ADD2MONITED_QUEST_LIST(LONGMENJUEJING_QUEST)
function _RC.CheckLongMenJueJing()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[Ѱ�����������] ����ID��13600
	local dwQuestID = 17895
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		_RC.SelfData[RI_CHANG.LONGMENJUEJING] = {eQuestPhase = eQuestPhase, need = 2, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local need = quest_state[1].need
		local have = quest_state[1].have
		_RC.SelfData[RI_CHANG.LONGMENJUEJING] = {eQuestPhase = eQuestPhase, need = 2, have = have, }
	elseif eQuestPhase ==  3 then
		_RC.SelfData[RI_CHANG.LONGMENJUEJING] = {eQuestPhase = eQuestPhase, need = 2, have = 2, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:16747 ���������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 59149)		------�������ž����Ƿ���cd ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		_RC.SelfData[RI_CHANG.LONGMENJUEJING].finished = true
	else
		_RC.SelfData[RI_CHANG.LONGMENJUEJING].finished = false
	end
end

-----����������
local LUOYANGSHENBING_QUEST = {
	[17507] = true,		--����
	[17508] = true,		--����
	[17509] = true,		--������
	[17510] = true,		--������
}
ADD2MONITED_QUEST_LIST(LUOYANGSHENBING_QUEST)
function _RC.CheckLuoYangShenBing()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwQuestID = 0
	local dwTemplateID = 0
	if me.nCamp ==  1 then		-----������
		dwQuestID = 17509
		dwTemplateID = 58135
		local eCanAccept = me.CanAcceptQuest(dwQuestID, dwTemplateID)
		if eCanAccept == 48 then
			dwQuestID = 17507
		end
	elseif me.nCamp ==  2 then		----���˹�
		dwQuestID = 17510
		dwTemplateID = 58136
		local eCanAccept = me.CanAcceptQuest(dwQuestID, dwTemplateID)
		if eCanAccept == 48 then
			dwQuestID = 17508
		end
	end

	if dwQuestID ~=  0 then
		local eQuestPhase = me.GetQuestPhase(dwQuestID)	----����״̬
		local eCanAccept = me.CanAcceptQuest(dwQuestID, dwTemplateID)		----����CD
		if eQuestPhase ==  0 or eQuestPhase ==  -1 then
			_RC.SelfData[RI_CHANG.LUOYANGSHENBING] = {eQuestPhase = eQuestPhase, need = "1K", have = 0, }
		elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
			local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
			local quest_state = QuestTraceInfo.quest_state
			local need = quest_state[1].need
			local have = quest_state[1].have
			_RC.SelfData[RI_CHANG.LUOYANGSHENBING] = {eQuestPhase = eQuestPhase, need = "1K", have = have, }
		elseif eQuestPhase ==  3 then
			_RC.SelfData[RI_CHANG.LUOYANGSHENBING] = {eQuestPhase = eQuestPhase, need = "1K", have = 1000, }
		end
		if eCanAccept ==  57 then
			_RC.SelfData[RI_CHANG.LUOYANGSHENBING].finished = true
		else
			_RC.SelfData[RI_CHANG.LUOYANGSHENBING].finished = false
		end
	else
		_RC.SelfData[RI_CHANG.LUOYANGSHENBING] = {eQuestPhase = 0, need = "1K", have = 0, finished = false, }
	end
end

------------------------------------------------
---����
------------------------------------------------
local _Exam = {}
_Exam.AllUsrData = {}
_Exam.SelfData = {
	["ShengShi"] = 0,
	["HuiShi"] = 0,
}

function _Exam.LoadData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM exam_data WHERE bDel = 0 AND szKey IS NOT NULL")
	local Data = d2g(DB_SELECT:GetAll())
	local AllUsrData = {}
	if Data and next(Data) ~=  nil then
		for k, v in pairs(Data) do
			AllUsrData[v.szKey] = v
		end
	end
	_Exam.AllUsrData = clone(AllUsrData)
	--�滻��¼������ļ�¼
	_Exam.CheckExam()
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	_Exam.AllUsrData[szKey] = clone(_Exam.SelfData)
	--���Ƶ�����
	LR_AS_Data.ExamData = clone(_Exam.AllUsrData)
end

function _Exam.SaveData(DB)
	if not LR_AS_Base.UsrData.bRecord then
		return
	end
	local me = GetClientPlayer()
	if not me or IsRemotePlayer(me.dwID) then
		return
	end
	_Exam.CheckExam()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local v = _Exam.SelfData or {}
	local DB_REPLACE = DB:Prepare("REPLACE INTO exam_data ( szKey, ShengShi, HuiShi, bDel ) VALUES ( ?, ?, ?, ? )")
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(unpack(g2d({szKey, v.ShengShi, v.HuiShi, 0})))
	DB_REPLACE:Execute()
end

function _Exam.ResetData(DB)
	--�忼��
	local DB_SELECT = DB:Prepare("SELECT szKey FROM exam_data WHERE bDel = 0 AND szKey IS NOT NULL")
	local result = d2g(DB_SELECT:GetAll())
	if result and next(result) ~=  nil then
		local DB_REPLACE = DB:Prepare("REPLACE INTO exam_data ( szKey, bDel ) VALUES ( ?, 0 )")
		for k, v in pairs(result) do
			DB_REPLACE:ClearBindings()
			DB_REPLACE:BindAll(g2d(v.szKey))
			DB_REPLACE:Execute()
		end
	end
end

function _Exam.CheckExam()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local buffList = LR.GetBuffList(me)
	_Exam.SelfData = {
		["ShengShi"] = 0,
		["HuiShi"] = 0,
	}
	if LR.HasBuff(buffList, 10936) then
		_Exam.SelfData["ShengShi"] = 1
	end
	if LR.HasBuff(buffList, 4125) then
		_Exam.SelfData["HuiShi"] = 1
	end
	if LR.GetItemNumInBagAndBank(5, 6261) > 0 then
		_Exam.SelfData["ShengShi"] = 1		---��������(ʡ��buff��ʱ����ʧ)
	end

	_Exam.AllUsrData[szKey] = clone(_Exam.SelfData)
	LR_AS_Data.ExamData[szKey] = clone(_Exam.SelfData)
end

-----------------------------------

function _RC.SaveClearData(DB)
	---����������д�����ݿ�
	local name, wen = {}, {}
	for k, v in pairs(RI_CHANG) do
		name[#name + 1] = k
		wen[#wen + 1] = "?"
	end
	name[#name + 1] = "CUSTOM_QUEST"
	wen[#wen + 1] = "?"
	local DB_REPLACE = DB:Prepare(sformat("REPLACE INTO richang_data ( bDel, szKey, %s ) VALUES ( ?, %s, ? )", tconcat(name, ", "), tconcat(wen, ", ")))
	for szKey, v in pairs (_RC.AllUsrData) do
		local value = {}
		for  k2, v2 in pairs(RI_CHANG) do
			value[#value+1] = LR.JsonEncode(v[v2])
		end
		value[#value + 1] = LR.JsonEncode(v.CUSTOM_QUEST)

		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(unpack(g2d({0, szKey, unpack(value)})))
		DB_REPLACE:Execute()
	end
end

function _RC.ClearZC(DB)
	_RC.LoadAllUsrData(DB)
	local t_Table =  _RC.List
	for szKey, v in pairs(_RC.AllUsrData) do
		for k2, v2 in pairs(t_Table) do
			if v2.nType ==  "ZC" then		------���ڹ��˲����ܳ�������
				if v[v2.order] then
					if v[v2.order].finished then
						_RC.AllUsrData[szKey][v2.order].finished = false
					end
				end
			end
		end

		local CUSTOM_QUEST = v.CUSTOM_QUEST or {}
		if next(CUSTOM_QUEST) ~= nil then
			for k2, v2 in pairs (LR_AS_RC.CustomQuestList or {}) do
				if v2.refresh == "WEEK" or v.refresh == "EVERYDAY" then
					if CUSTOM_QUEST[tostring(v2.dwID)] then
						CUSTOM_QUEST[tostring(v2.dwID)] = nil
					end
				end
			end
		end
	end
	_RC.SaveClearData(DB)
end

------����ճ���¼
function _RC.ClearRC(DB)
	_RC.LoadAllUsrData(DB)
	local t_Table =  _RC.List
	for szKey, v in pairs(_RC.AllUsrData) do
		for k2, v2 in pairs(t_Table) do
			if v2.nType ==  "RC" then		------���ڹ��˲����ճ�������
				if v[v2.order] then
					if v[v2.order].finished then
						_RC.AllUsrData[szKey][v2.order].finished = false
					end
				end
			end
		end

		local CUSTOM_QUEST = v.CUSTOM_QUEST or {}
		for k2, v2 in pairs (LR_AS_RC.CustomQuestList or {}) do
			if v2.refresh == "EVERYDAY" then
				if CUSTOM_QUEST[tostring(v2.dwID)] then
					CUSTOM_QUEST[tostring(v2.dwID)] = nil
				end
			end
		end
	end
	_RC.SaveClearData(DB)
end

function _RC.ResetDataMonday(DB)
	_RC.ClearZC(DB)
	_Exam.ResetData(DB)

	LR_WLTJ.ClearWLTJdatMonday(DB)
end

function _RC.ResetDataEveryDay(DB)
	_RC.ClearRC(DB)
end
---------------------------------
-----��¼��������״̬
function _RC.CheckAll()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	-------PVE
	----����ս
	_RC.CheckDazhan()
	----��鹫���¼�
	_RC.CheckGongShiJian()

	-------PVX
	----�����
	_RC.CheckChaGuan()
	----������޲��
	_RC.CheckQinXiu()
	----�����ɲ�
	_RC.CheckCaiCao()
	----Ѱ����
	_RC.CheckLongMai()
	----����ͼ
	_RC.CheckMeiRenTu()
	----�ٱ���/����
	_RC.CheckHeiMi()
	----2016�ع⵾���
	_RC.CheckHUIGUANG()
	----�����ȹ�
	_RC.CheckHuaShan()

	------PVP
	----���ݵ�ó��
	_RC.CheckMaoYi()
	----��龧������
	_RC.CheckJingKuang()
	----������ž���
	_RC.CheckLongMenJueJing()
	---����������
	_RC.CheckLuoYangShenBing()
	--�����Ӫ�ճ�
	_RC.CheckZHENYINGRICHANG()

	----����
	_Exam.CheckExam()
end

------------------------------------------------------
-----��������ʾ�ճ�
------------------------------------------------------
_RC.Container = nil
function _RC.AddPage()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end

	local PageSet_Menu = frame:Lookup("PageSet_Menu")
	local Btn = PageSet_Menu:Lookup("WndCheck_RC")

	local page = Wnd.OpenWindow(sformat("%s\\UI\\page.ini", AddonPath), "temp"):Lookup("Page_RC")
	page:ChangeRelation(PageSet_Menu, true, true)
	page:SetName("Page_RC")
	Wnd.CloseWindow("temp")
	PageSet_Menu:AddPage(page, Btn)

	Btn:Enable(true)
	Btn:Lookup("",""):Lookup("Text_RC"):SetFontColor(255, 255, 255)
	_RC.ReFreshTitle()
	_RC.ListRC()
	_RC.AddPageButton()
end

function _RC.ReFreshTitle()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end
	local title_handle = frame:Lookup("PageSet_Menu"):Lookup("Page_RC"):Lookup("", "")
	local n = 1
	local List = _RC.List
	--����Լ�������ճ�
	for i = 1, #List, 1 do
		if LR_AS_RC.UsrData.List[List[i].order] and n<= 8 then
			local text = title_handle:Lookup(sformat("Text_RC%d_Break", n))
			text:SetText(List[i].szName)
			n = n+1
		end
	end
	---����Լ����õ��ճ�
	for k, v in pairs (LR_AS_RC.CustomQuestList) do
		if v.bShow and n <= 8 then
			local text = title_handle:Lookup(sformat("Text_RC%d_Break", n))
			text:SetText(v.szName)
			n = n+1
		end
	end

	for j = n, 8, 1 do
		local text = title_handle:Lookup(sformat("Text_RC%d_Break", j))
		text:SetText("")
	end
end

function _RC.ListRC()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end
	local TempTable_Cal, TempTable_NotCal = LR_AS_Base.SeparateUsrList()

	_RC.Container = frame:Lookup("PageSet_Menu/Page_RC/WndScroll_RC/Wnd_RC")
	_RC.Container:Clear()
	num = _RC.ShowItem (TempTable_Cal, 255, 1, 0)
	num = _RC.ShowItem (TempTable_NotCal, 60, 1, num)
	_RC.Container:FormatAllContentPos()
end

function _RC.ShowItem(t_Table, Alpha, bCal, _num)
	local num = _num
	local PlayerList = clone(t_Table)

	local me = GetClientPlayer()
	if not me then
		return
	end

	for k, v in pairs(PlayerList) do
		num = num+1
		local wnd = _RC.Container:AppendContentFromIni(sformat("%s\\UI\\item.ini", AddonPath), "RCList_WndWindow", sformat("RC_%s_%s_%s", v.realArea, v.realServer, v.szName))
		local handle = wnd:Lookup("", "")
		if num % 2 ==  0 then
			handle:Lookup("Image_Line"):Hide()
		else
			handle:Lookup("Image_Line"):SetAlpha(225)
		end
		wnd:SetAlpha(Alpha)

		local item_MenPai = handle:Lookup("Image_NameIcon")
		local item_Name = handle:Lookup("Text_Name")
		local item_Select = handle:Lookup("Image_Select")
		item_Select:SetAlpha(125)
		item_Select:Hide()

		item_MenPai:FromUITex(GetForceImage(v.dwForceID))
		local name = v.szName
		if wslen(name) > 6 then
			name = sformat("%s...", wssub(name, 1, 5))
		end
		item_Name:SprintfText(_L["%s(%d)"], name, v.nLevel)
		local r, g, b = LR.GetMenPaiColor(v.dwForceID)
		item_Name:SetFontColor(r, g, b)
		--  Output(LR.GetMenPaiColor(v.MenPai))

		local realArea = v.realArea
		local realServer = v.realServer
		local szName = v.szName
		local player  = GetClientPlayer()
		local szKey = sformat("%s_%s_%d", realArea, realServer, v.dwID)
		local RC_Record = _RC.AllUsrData[szKey] or {}

		------����ճ�
		local n = 1
		local List = _RC.List
		for i = 1, #List, 1 do
			if LR_AS_RC.UsrData.List[List[i].order] and n<= 8 then
				local Text_FB = handle:Lookup(sformat("Text_RC%d", n))
				if RC_Record[List[i].order] then
					if RC_Record[List[i].order].finished then
						Text_FB:SetText(_L["Done"])
						Text_FB:SetFontScheme(47)
					elseif RC_Record[List[i].order].eQuestPhase ==  0 or RC_Record[List[i].order].eQuestPhase ==  -1 then
						Text_FB:SetText("--")
						Text_FB:SetFontScheme(80)
					elseif RC_Record[List[i].order].eQuestPhase ==  1 then
						if RC_Record[List[i].order].have == 0 and List[i].szName ~=  _L["MI"] then
							Text_FB:SetText(_L["Accepted"])
						else
							Text_FB:SprintfText("%s / %s", tostring(RC_Record[List[i].order].have or 0), tostring(RC_Record[List[i].order].need or 0))
						end
						Text_FB:SetFontScheme(31)
					elseif RC_Record[List[i].order].eQuestPhase ==  2 then
						Text_FB:SetText(_L["Finished but not pay"])
						Text_FB:SetFontScheme(17)
					elseif RC_Record[List[i].order].eQuestPhase ==  3 then			------�������û��
						Text_FB:SetText(_L["Done"])
						Text_FB:SetFontScheme(47)
					end
				else
					Text_FB:SetText("--")
					Text_FB:SetFontScheme(80)
				end
				n = n+1
			end
		end

		---�Զ�������
		local CustomQuestList = LR_AS_RC.CustomQuestList or {}
		local CUSTOM_QUEST = RC_Record.CUSTOM_QUEST or {}
		for k, v in pairs(CustomQuestList) do
			if v.bShow and n <= 8 then
				local Text_FB = handle:Lookup(sformat("Text_RC%d", n))
				if CUSTOM_QUEST[tostring(v.dwID)] then
					if CUSTOM_QUEST[tostring(v.dwID)].full then
						Text_FB:SetText(_L["Done"])
						Text_FB:SetFontScheme(47)
					elseif CUSTOM_QUEST[tostring(v.dwID)].nQuestPhase == 1 then
						if CUSTOM_QUEST[tostring(v.dwID)].have == 0 then
							Text_FB:SetText(_L["Accepted"])
							Text_FB:SetFontScheme(31)
						else
							Text_FB:SprintfText("%s / %s", tostring(CUSTOM_QUEST[tostring(v.dwID)].have or 0), tostring(CUSTOM_QUEST[tostring(v.dwID)].need or 0))
							Text_FB:SetFontScheme(31)
						end
					elseif CUSTOM_QUEST[tostring(v.dwID)].nQuestPhase == 2 then
						Text_FB:SetText(_L["Finished but not pay"])
						Text_FB:SetFontScheme(17)
					elseif CUSTOM_QUEST[tostring(v.dwID)].nQuestPhase == 3 then
						Text_FB:SetText(_L["Done"])
						Text_FB:SetFontScheme(47)
					else
						Text_FB:SetText("--")
						Text_FB:SetFontScheme(80)
					end
				else
					Text_FB:SetText("--")
					Text_FB:SetFontScheme(80)
				end
				n = n+1
			end
		end

		for j = n, 8, 1 do
			local Text_FB = handle:Lookup(sformat("Text_RC%d", j))
			Text_FB:SetText("")
			Text_FB:SetFontScheme(41)
		end

		--------------------���tips
		handle:RegisterEvent(304)
		handle.OnItemMouseEnter = function ()
			item_Select:Show()
			_RC.ShowTip(v)
		end
		handle.OnItemMouseLeave = function()
			item_Select:Hide()
			HideTip()
		end
		handle.OnItemLButtonClick = function()
			--
		end
		handle.OnItemRButtonClick = function()
			local menu = LR_AS_Panel.RClickMenu(v.realArea, v.realServer, v.dwID)
			PopupMenu(menu)
		end
	end
	return num
end

function _RC.ShowTip(v)
	local nMouseX, nMouseY =  Cursor.GetPos()
	local szTipInfo = {}
	local szPath, nFrame = GetForceImage(v.dwForceID)
	local szKey = sformat("%s_%s_%d", v.realArea, v.realServer, v.dwID)
	local RC_Record = _RC.AllUsrData[szKey] or {}
	local r, g, b = LR.GetMenPaiColor(v.dwForceID)

	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	if v.dwID == me.dwID and v.realArea == realArea and v.realServer == realServer then
		_RC.CheckAll()
		_Exam.CheckExam()
		RC_Record = clone(_RC.SelfData)
	end

	szTipInfo[#szTipInfo+1] = GetFormatImage(szPath, nFrame, 26, 26)
	szTipInfo[#szTipInfo+1] = GetFormatText(sformat(_L["%s(%d)"], v.szName, v.nLevel), 62, r, g, b)
	szTipInfo[#szTipInfo+1] = GetFormatText(sformat("\n%s@%s\n", v.realArea, v.realServer))
	szTipInfo[#szTipInfo+1] = GetFormatImage("ui\\image\\ChannelsPanel\\NewChannels.uitex", 166, 260, 27)
	szTipInfo[#szTipInfo+1] = GetFormatText("\n", 62)
	local List = _RC.List
	for i = 1, #List, 1 do
		if RC_Record[List[i].order] then
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s��\t", List[i].szName), 224)
			if RC_Record[List[i].order].finished then
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Done"]), 47)
			elseif RC_Record[List[i].order].eQuestPhase ==  0 or RC_Record[List[i].order].eQuestPhase ==  -1 then
				szTipInfo[#szTipInfo+1] = GetFormatText("------\n", 80)
			elseif RC_Record[List[i].order].eQuestPhase ==  1 then
				if RC_Record[List[i].order].have == 0 and List[i].szName ~=  _L["MI"] then
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Accepted"]), 31)
				else
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s / %s\n", tostring(RC_Record[List[i].order].have or 0), tostring(RC_Record[List[i].order].need or 0)), 31)
				end
			elseif RC_Record[List[i].order].eQuestPhase ==  2 then
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Finished but not pay"]), 17)
			elseif RC_Record[List[i].order].eQuestPhase ==  3 then			------�������û��
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Done"]), 47)
			end
		end
	end

	------�Զ�������
	local CustomQuestList = LR_AS_RC.CustomQuestList or {}
	local CUSTOM_QUEST = RC_Record.CUSTOM_QUEST or {}
	if next(CustomQuestList) ~= nil then
		szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Custom quest under"]), 47)
	end
	for k, v in pairs(CustomQuestList) do
		szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s��\t", v.szName), 224)
		if CUSTOM_QUEST[tostring(v.dwID)] then
			if CUSTOM_QUEST[tostring(v.dwID)].full then
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Done"]), 47)
			elseif CUSTOM_QUEST[tostring(v.dwID)].nQuestPhase == 1 then
				if CUSTOM_QUEST[tostring(v.dwID)].have == 0 then
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Accepted"]), 31)
				else
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s / %s\n", tostring(CUSTOM_QUEST[tostring(v.dwID)].have or 0), tostring(CUSTOM_QUEST[tostring(v.dwID)].need or 0)), 31)
				end
			elseif CUSTOM_QUEST[tostring(v.dwID)].nQuestPhase == 2 then
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Finished but not pay"]), 17)
			elseif CUSTOM_QUEST[tostring(v.dwID)].nQuestPhase == 3 then
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", _L["Done"]), 47)
			else
				szTipInfo[#szTipInfo+1] = GetFormatText("------\n", 80)
			end
		else
			szTipInfo[#szTipInfo+1] = GetFormatText("------\n", 80)
		end
	end

	OutputTip(tconcat(szTipInfo), 250, {nMouseX, nMouseY, 0, 0})
end


function _RC.AddPageButton()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end
	local page = frame:Lookup("PageSet_Menu/Page_RC")
	LR_AS_Base.AddButton(page, "btn_5", _L["Show Group"], 340, 555, 110, 36, function() LR_AS_Group.PopupUIMenu() end)
	if LR_AS_Module["BookRd"] then
		LR_AS_Base.AddButton(page, "btn_4", _L["Reading Statistics"], 470, 555, 110, 36, function() LR_BookRd_Panel:Open() end)
	end
	LR_AS_Base.AddButton(page, "btn_3", _L["Quest Tools"], 600, 555, 110, 36, function() LR_QuestTools:Open() end)
	LR_AS_Base.AddButton(page, "btn_2", _L["Settings"], 730, 555, 110, 36, function() LR_AS_Base.SetOption() end)
	--LR_AS_Base.AddButton(page, "btn_1", _L["7 YEAR"], 730, 555, 110, 36, function() LR_Acc_Achievement_Panel:Open() end)
end

function _RC.RefreshPage()
	_RC.ReFreshTitle()
	_RC.ListRC()
end


-----------------------------------------------------------------
LR_QuestTools = _G2.CreateAddon("LR_QuestTools")
LR_QuestTools:BindEvent("OnFrameDestroy", "OnDestroy")

LR_QuestTools.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER", x = 0, y = 0},
}

LR_QuestTools.realArea = ""
LR_QuestTools.realServer = ""
LR_QuestTools.szPlayerName = ""

function LR_QuestTools:OnCreate()
	this:RegisterEvent("UI_SCALED")
	LR_QuestTools.UpdateAnchor(this)

	RegisterGlobalEsc("LR_QuestTools", function () return true end , function() LR_QuestTools:Open() end)
end

function LR_QuestTools:OnEvents(event)
	if event ==  "UI_SCALED" then
		LR_QuestTools.UpdateAnchor(this)
	end
end

function LR_QuestTools.UpdateAnchor(frame)
	frame:SetPoint(LR_QuestTools.UsrData.Anchor.s, 0, 0, LR_QuestTools.UsrData.Anchor.r, LR_QuestTools.UsrData.Anchor.x, LR_QuestTools.UsrData.Anchor.y)
	frame:CorrectPos()
end

function LR_QuestTools:OnDestroy()
	UnRegisterGlobalEsc("LR_QuestTools")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_QuestTools:OnDragEnd()
	this:CorrectPos()
	LR_QuestTools.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_QuestTools:Init()
	local frame = self:Append("Frame", "LR_QuestTools", {title = _L["LR Quest Tool"], style = "SMALL"})

	local imgTab = self:Append("Image", frame, "TabImg", {w = 381, h = 33, x = 0, y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)

	local hPageSet = self:Append("PageSet", frame, "PageSet", {x = 20, y = 120, w = 360, h = 360})
	local hWinIconView = self:Append("Window", hPageSet, "WindowItemView", {x = 0, y = 0, w = 360, h = 360})

	local Btn_Fresh = self:Append("Button", frame, "Btn_Fresh", {x = 20, y = 51, text = _L["Refresh"]})
	Btn_Fresh.OnClick = function()
		self:LoadItemBox()
	end

	local hScroll = self:Append("Scroll", hWinIconView, "Scroll", {x = 0, y = 0, w = 354, h = 360})
	self:LoadItemBox()
	--hScroll:UpdateList()

	-------------��ʼ������Ʒ
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

	local Image_Record_Break1 = self:Append("Image", hHandle, "Image_Record_Break1", {x = 80, y = 2, w = 3, h = 386})
	Image_Record_Break1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
	Image_Record_Break1:SetImageType(11)
	Image_Record_Break1:SetAlpha(160)

	local Text_break1 = self:Append("Text", hHandle, "Text_break1", {w = 80, h = 30, x  = 0, y = 2, text = _L["Quest ID"], font = 18})
	Text_break1:SetHAlign(1)
	Text_break1:SetVAlign(1)

	local Text_break2 = self:Append("Text", hHandle, "Text_break1", {w = 260, h = 30, x  = 80, y = 2, text = _L["Quest Name"], font = 18})
	Text_break2:SetHAlign(1)
	Text_break2:SetVAlign(1)

	----------����
	LR.AppendAbout(LR_QuestTools, frame)
end

function LR_QuestTools:Open()
	local frame = self:Fetch("LR_QuestTools")
	if frame then
		self:Destroy(frame)
	else
		self:Init()
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

function LR_QuestTools:LoadItemBox()
	local me =  GetClientPlayer()
	if not me then
		return
	end
	local hWin = self:Fetch("Scroll")
	if not hWin then
		return
	end

	local m = 1
	local Quest = {}
	if IsCtrlKeyDown() then
		local _type, _dwID = me.GetTarget()
		if _type == TARGET.NPC then
			local npc = GetNpc(_dwID)
			if npc then
				local questids = npc.GetNpcQuest()
				for k, v in pairs(questids) do
					Quest[#Quest+1] = {dwQuestID = v, dwTemplateID = npc.dwTemplateID}
				end
			end
		end
	else
		for i = 0, 24, 1 do
			local dwQuestID = me.GetQuestID(i)
			if dwQuestID>0 then
				Quest[#Quest+1] = {dwQuestID = dwQuestID}
			end
		end
	end

	tsort(Quest, function(a, b)
		if a.dwQuestID<b.dwQuestID then
			return true
		else
			return false
		end
	end)
	hWin:ClearHandle()

	for m = 1, #Quest, 1 do
		local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 340, h = 30})
		local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 0, y = 0, w = 340, h = 30})
		Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
		Image_Line:SetImageType(10)
		Image_Line:SetAlpha(200)

		if m % 2 ==  1 then
			Image_Line:Hide()
		end

		--��ͣ��
		local Image_Hover = self:Append("Image", hIconViewContent, sformat("Image_Hover_%d", m), {x = 2, y = 0, w = 334, h = 30})
		Image_Hover:FromUITex("ui\\Image\\Common\\TempBox.UITex", 5)
		Image_Hover:SetImageType(10)
		Image_Hover:SetAlpha(200)
		Image_Hover:Hide()

		local TextPhase = {[0] = _L["Not exist"], [1] = _L["In progress"], [2] = _L["Complete but not hand it"], [3] = _L["Finished"], [-1] = _L["Invalid"]}
		local dwQuestID = Quest[m].dwQuestID
		local QuestInfo = LR.Table_GetQuestStringInfo(dwQuestID)
		local szName = sformat("%s(%s)", QuestInfo.szName, TextPhase[me.GetQuestPhase(dwQuestID)])
		if Quest[m].dwTemplateID then
			local eCanAccept = me.CanAcceptQuest(dwQuestID, Quest[m].dwTemplateID)
			szName = szName .. " C " .. eCanAccept
		end

		local Text_break1 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_1", m), {w = 80, h = 30, x  = 0, y = 2, text = dwQuestID , font = 18})
		Text_break1:SetHAlign(1)
		Text_break1:SetVAlign(1)

		local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 250, h = 30, x  = 90, y = 2, text = szName, font = 18})
		Text_break2:SetHAlign(1)
		Text_break2:SetVAlign(1)

		hIconViewContent.OnEnter = function()
			Image_Hover:Show()
			local nX, nY = this:GetAbsPos()
			local nW, nH = this:GetSize()
			OutputQuestTip(dwQuestID, {nX, nY, nW, nH})
		end

		hIconViewContent.OnLeave = function()
			Image_Hover:Hide()
			HideTip()
		end

		hIconViewContent.OnClick = function()
			local nX, nY = this:GetAbsPos()
			local nW, nH = this:GetSize()
			OutputQuestTip(dwQuestID, {nX, nY, nW, nH}, true)
			--------
			--local dwQuestID = 418
			Output("-----------------------------------")
			local tQuestStringInfo = LR.Table_GetQuestStringInfo(dwQuestID)
			Output(sformat("%s%s", _L["Quest name:"], tQuestStringInfo.szName))
			if IsCtrlKeyDown() then
				Output(tQuestStringInfo)
			end

			local questInfo = GetQuestInfo(dwQuestID)
			if questInfo then
				for i = 1, 300 do
					local tList = Table_GetQuestPoint(dwQuestID, "accept", 0, i)
					if tList then
						Output("ss", tList)
					end
				end
				if questInfo.dwStartDoodadTemplateID ~= 0 then

				elseif questInfo.dwStartNpcTemplateID ~= 0 then

				end
				local Hortation = questInfo.GetHortation()
				Output("Hortation", Hortation)
			end
			local tQuest = g_tTable.Quest:Search(dwQuestID)
			if tQuest then
				if IsCtrlKeyDown() then
					Output("Quest", tQuest)
				end
				for k, v in pairs (LR_HeadName.SpliteString(tQuest.szAccept)) do
					if v.nType == "D" or v.nType == "N" then
						Output(_L["Accept npc"], "nType:"..v.nType, "dwMapID:"..v.dwMapID..Table_GetMapName(v.dwMapID), "dwTemplateID:"..v.dwTemplateID, "szName:"..v.szName, Table_GetQuestPoint(dwQuestID, "accept", k - 1, v.dwMapID))
						local eCanAccept = me.CanAcceptQuest(dwQuestID, v.dwTemplateID)
						Output(_L["Do ..... Can accept?"], eCanAccept, v.dwTemplateID, g_tStrings.tQuestResultString[eCanAccept])
					end
				end
				for k, v in pairs (LR_HeadName.SpliteString(tQuest.szFinish)) do
					if v.nType == "D" or v.nType == "N" then
						Output(_L["Finish npc"], "nType:"..v.nType, "dwMapID:"..v.dwMapID..Table_GetMapName(v.dwMapID), "dwTemplateID:"..v.dwTemplateID, "szName:"..v.szName, Table_GetQuestPoint(dwQuestID, "finish", k - 1, v.dwMapID))
					end
				end
			else
				Output("g_tTable.Quest ����Ϣ")
			end

			local nQuestPhase = me.GetQuestPhase(dwQuestID)
			Output("nQuestPhase", nQuestPhase)

			if IsCtrlKeyDown() then
				local _nType, _dwID = me.GetTarget()
				if _nType == TARGET.NPC then
					local eCanAccept = me.CanAcceptQuest(dwQuestID, TARGET.NPC, _dwID)
					local npc = GetNpc(_dwID)
					Output(npc.szName, _L["Can accept?"], eCanAccept, g_tStrings.tQuestResultString[eCanAccept])
					local eCanFinish = me.CanFinishQuest(dwQuestID, TARGET.NPC, _dwID)
					Output(npc.szName, _L["Can Finish?"], eCanFinish, g_tStrings.tQuestResultString[eCanFinish])
				end

				--3: ��ʾ���������0: ��ʾ���񲻴���1: ��ʾ�������ڽ����У�2: ��ʾ��������ɵ���û�н�-1: ��ʾ����id�Ƿ�
				Output(sformat("%s%s", _L["quest status:"], TextPhase[me.GetQuestPhase(dwQuestID)]))

				local tTraceInfo = me.GetQuestTraceInfo(dwQuestID)
				Output("TraceInfo", tTraceInfo)
				local key = {"kill_npc", "need_item", "quest_state"}
				for k, v in pairs(key) do
					local data = tTraceInfo[v]
					Output(v, data)
					for k2, v2 in pairs(data) do
						Output(v2.i)
						Output(LR.Table_GetQuestPoint(dwQuestID, v, v2.i))
					end
				end
			end
		end
	end
	hWin:UpdateList()
end


--------------------------------------
--------�¼�����
--------------------------------------
local _quest_save_time = 0
local function SAVE_QUEST(dwQuestID)
	--�Ǽ�ʱ�����򷵻�
	if not LR_AS_RC.UsrData.InstantSaving then
		return
	end
	--���ڼ���е����񲻱���
	if not MONITED_QUEST_LIST[dwQuestID] then
		return
	end
	local _time = GetCurrentTime()
	if _time - _quest_save_time < 60 * 1 then
		return
	end
	local path = sformat("%s\\%s", SaveDataPath, db_name)
	local DB = LR.OpenDB(path, "RC_SAVE_QUEST_C4C149DED36AB08F230374D361E4103E")
	_RC.SaveData(DB)
	LR.CloseDB(DB)
	Log("[LR] RI_CHANG_QUEST_EVENT_SAVE\n")
	_quest_save_time = GetCurrentTime()
	LR_AS_Panel:RefreshUI()
end

function _RC.QUEST_ACCEPTED()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwQuestID = arg1
	SAVE_QUEST(dwQuestID)
end

function _RC.QUEST_DATA_UPDATE()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwQuestID = me.GetQuestID(arg0)
	SAVE_QUEST(dwQuestID)
end

function _RC.QUEST_FINISHED()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwQuestID = arg0
	SAVE_QUEST(dwQuestID)
end

function _RC.QUEST_FAILED()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwQuestID = me.GetQuestID(arg0)
	SAVE_QUEST(dwQuestID)
end

function _RC.QUEST_CANCELED()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwQuestID = arg0
	SAVE_QUEST(dwQuestID)
end

function _RC.FIRST_LOADING_END()
	if not (LR_AS_RC.UsrData and LR_AS_RC.UsrData.Version and LR_AS_RC.UsrData.Version == LR_AS_RC.Default.Version) then
		_RC.ResetMenuList()
	end
	_RC.LoadCustomQuestList()
	_RC.GetCustomQuestStatus()

	_RC.LoadCommomMenuList()
	LR.DelayCall(300, function()
		_RC.ResetData()
		_RC.CheckAll()
	end)
end

LR.RegisterEvent("QUEST_ACCEPTED", function() _RC.QUEST_ACCEPTED() end)
LR.RegisterEvent("QUEST_DATA_UPDATE", function() _RC.QUEST_DATA_UPDATE() end)
LR.RegisterEvent("QUEST_FINISHED", function() _RC.QUEST_FINISHED() end)
LR.RegisterEvent("QUEST_FAILED", function() _RC.QUEST_FAILED() end)
LR.RegisterEvent("QUEST_CANCELED", function() _RC.QUEST_CANCELED() end)
LR.RegisterEvent("FIRST_LOADING_END", function() _RC.FIRST_LOADING_END() end)

------------------------------------------
LR_AS_RC.LoadCustomQuestList = _RC.LoadCustomQuestList
LR_AS_RC.SaveCommomMenuList = _RC.SaveCommomMenuList
LR_AS_RC.SaveCustomQuestList = _RC.SaveCustomQuestList
LR_AS_RC.RI_CHANG = RI_CHANG
LR_AS_RC.RI_CHANG_NAME = RI_CHANG_NAME

------------------------------------------
function _RC.SaveData2(DB)
	_RC.SaveData(DB)
	_Exam.SaveData(DB)
	LR_WLTJ.SaveData(DB)
end

function _RC.LoadData2(DB)
	_RC.LoadAllUsrData(DB)
	_Exam.LoadData(DB)
end

--ע��ģ��
LR_AS_Module.RC = {}
LR_AS_Module.RC.SaveData = _RC.SaveData2
LR_AS_Module.RC.LoadData = _RC.LoadData2
LR_AS_Module.RC.ResetDataMonday = _RC.ResetDataMonday		--�������忼�Լ�¼
LR_AS_Module.RC.ResetDataEveryDay = _RC.ResetDataEveryDay
LR_AS_Module.RC.AddPage = _RC.AddPage
LR_AS_Module.RC.RefreshPage = _RC.RefreshPage
LR_AS_Module.RC.ShowTip = _RC.ShowTip
LR_AS_Module.RC.FIRST_LOADING_END = _RC.LoadData2
LR_AS_Module.RC.CheckExam = _Exam.CheckExam

