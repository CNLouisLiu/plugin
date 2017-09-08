local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin\\@DATA\\LR_AccountStatistics\\UsrData"
local _L = LR.LoadLangPack(AddonPath)
local DB_name = "maindb.db"
local sformat, slen, sgsub, ssub, sfind = string.format, string.len, string.gsub, string.sub, string.find
local mfloor, mceil, mmin, mmax = math.floor, math.ceil, math.min, math.max
local tconcat, tinsert, tremove, tsort = table.concat, table.insert, table.remove, table.sort
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
}

LR_AccountStatistics_RiChang = LR_AccountStatistics_RiChang or {}
LR_AccountStatistics_RiChang.RI_CHANG = RI_CHANG
LR_AccountStatistics_RiChang.RI_CHANG_NAME = RI_CHANG_NAME

LR_AccountStatistics_RiChang.AllUsrData = {}
LR_AccountStatistics_RiChang.SelfData = {
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
}

LR_AccountStatistics_RiChang.Default = {
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
	},
	bUseCommonData = true,
	Version = "20170626",
}
LR_AccountStatistics_RiChang.UsrData = clone(LR_AccountStatistics_RiChang.Default)
LR_AccountStatistics_RiChang.CustomQuestList = {}
LR_AccountStatistics_RiChang.SelfCustomQuestStatus = {}
local CustomVersion = "20170111"
RegisterCustomData("LR_AccountStatistics_RiChang.UsrData", CustomVersion)

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
function LR_AccountStatistics_RiChang.ResetMenuList()
	local me = GetClientPlayer()
	if not me then
		return
	end
	LR_AccountStatistics_RiChang.UsrData = clone(LR_AccountStatistics_RiChang.Default)
	if LR_AccountStatistics_RiChang.UsrData.bUseCommonData then
		LR_AccountStatistics_RiChang.SaveCommomMenuList()
	end
end

function LR_AccountStatistics_RiChang.CheckCommomMenuList()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local  path = sformat("%s\\RiChangCommonData.dat.jx3dat", SaveDataPath)
	if not IsFileExist(path) then
		local CommomMenuList = LR_AccountStatistics_RiChang.Default
		local path = sformat("%s\\RiChangCommonData.dat", SaveDataPath)
		SaveLUAData (path, CommomMenuList)
	end
end

function LR_AccountStatistics_RiChang.SaveCommomMenuList()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_AccountStatistics_RiChang.UsrData.bUseCommonData then
		return
	end
	local CommomMenuList = LR_AccountStatistics_RiChang.UsrData
	local path = sformat("%s\\RiChangCommonData.dat", SaveDataPath)
	SaveLUAData (path, CommomMenuList)
end

function LR_AccountStatistics_RiChang.LoadCommomMenuList()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_AccountStatistics_RiChang.UsrData.bUseCommonData then
		return
	end
	LR_AccountStatistics_RiChang.CheckCommomMenuList()
	local path = sformat("%s\\RiChangCommonData.dat", SaveDataPath)
	local CommomMenuList = LoadLUAData  (path) or {}
	LR_AccountStatistics_RiChang.UsrData = clone(CommomMenuList)
end

----------------------------------------------------------------------------------------
----�Զ���������
----------------------------
function LR_AccountStatistics_RiChang.SaveCustomQuestList()
	local path = sformat("%s\\CustomQuestList.dat", SaveDataPath)
	local data = LR_AccountStatistics_RiChang.CustomQuestList or {}
	SaveLUAData(path, data)
end

function LR_AccountStatistics_RiChang.LoadCustomQuestList()
	local path = sformat("%s\\CustomQuestList.dat", SaveDataPath)
	local data = LoadLUAData(path) or {}
	LR_AccountStatistics_RiChang.CustomQuestList = clone(data)
	local quest_list = {}
	for k, v in pairs (data) do
		quest_list[tonumber(v.dwID)] = true
	end
	ADD2MONITED_QUEST_LIST(quest_list)
end

function LR_AccountStatistics_RiChang.GetCustomQuestStatus()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local CustomQuestList = LR_AccountStatistics_RiChang.CustomQuestList
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
	LR_AccountStatistics_RiChang.SelfCustomQuestStatus = clone(data)
end

-----------------------------------------------------------------------------------------
function LR_AccountStatistics_RiChang.LoadAllUsrData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM richang_data WHERE bDel = 0 AND szKey IS NOT NULL ")
	local Data = DB_SELECT:GetAll() or {}
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
	LR_AccountStatistics_RiChang.AllUsrData = clone(AllUsrData)
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	LR_AccountStatistics_RiChang.CheckAll()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	LR_AccountStatistics_RiChang.AllUsrData[szKey] = LR_AccountStatistics_RiChang.SelfData

	LR_AccountStatistics_RiChang.GetCustomQuestStatus()
	LR_AccountStatistics_RiChang.AllUsrData[szKey].CUSTOM_QUEST = clone(LR_AccountStatistics_RiChang.SelfCustomQuestStatus)
end

function LR_AccountStatistics_RiChang.SaveData(DB)
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	LR_AccountStatistics_RiChang.CheckAll()
	if LR_AccountStatistics.UsrData.OthersCanSee then
		local name, wen, value = {}, {}, {}
		for k, v in pairs(RI_CHANG) do
			name[#name+1] = k
			wen[#wen+1] = "?"
			value[#value+1] = LR.JsonEncode(LR_AccountStatistics_RiChang.SelfData[v])
		end
		---�����Զ�����������
		LR_AccountStatistics_RiChang.GetCustomQuestStatus()
		name[#name+1] = "CUSTOM_QUEST"
		wen[#wen+1] = "?"
		value[#value+1] = LR.JsonEncode(LR_AccountStatistics_RiChang.SelfCustomQuestStatus or {})

		local DB_REPLACE = DB:Prepare(sformat("REPLACE INTO richang_data ( bDel, szKey, %s ) VALUES ( ?, %s, ? )", tconcat(name, ", "), tconcat(wen, ", ")))
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(0, szKey, unpack(value))
		DB_REPLACE:Execute()
	else
		local DB_REPLACE = DB:Prepare("REPLACE INTO richang_data (szKey, bDel) VALUES ( ?, 1)")
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey)
		DB_REPLACE:Execute()
	end
end

----------------------------------------------------------------------------
---------�����ճ����
LR_AccountStatistics_RiChang.List = {
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
	[12] = {szName = _L["HUASHAN"], nType = "ONCE", order = RI_CHANG.HUASHAN, }
}

----��ս��������
LR_AccountStatistics_RiChang.Dazhan = {
	----[����id] = true,
	[14765] = true, 		--14765 ��ս��Ӣ��΢ɽ��Ժ��
	[14766] = true, 		--14766 ��ս��Ӣ�������֣�
	[14767] = true, 		--14767 ��ս��Ӣ�������Ժ��
	[14768] = true, 		--14768 ��ս��Ӣ����ɽʥȪ��
	[14769] = true, 		--14769 ��ս��Ӣ������ˮ鿣�
}
ADD2MONITED_QUEST_LIST(LR_AccountStatistics_RiChang.Dazhan)

-----����ս״̬
function LR_AccountStatistics_RiChang.CheckDazhan()
	local me = GetClientPlayer()
	if not me then
		return
	end

	local Dazhan = LR_AccountStatistics_RiChang.Dazhan
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
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.DA] = {eQuestPhase = eQuestPhase, need = need, have = have, }
	else
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.DA] = {eQuestPhase = eQuestPhase, need = 3, have = 0, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:869 �ؾ���������
	local eCanAccept = me.CanAcceptQuest(14765, 869)		------�á���ս��Ӣ��΢ɽ��Ժ�������Դ�ս�Ƿ���cd ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.DA].finished = true
	else
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.DA].finished = false
	end
end

-------��鹫���¼�
--local dwQuestID = 14831
local GONG_QUEST = {
	[14831] = true,
}
ADD2MONITED_QUEST_LIST(GONG_QUEST)
function LR_AccountStatistics_RiChang.CheckGongShiJian()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[������Զ��������] ����ID��14831
	local dwQuestID = 14831
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.GONG] = {eQuestPhase = eQuestPhase, need = 100, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local need = quest_state[1].need
		local have = quest_state[1].have
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.GONG] = {eQuestPhase = eQuestPhase, need = need, have = have, }
	elseif eQuestPhase ==  3 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.GONG] = {eQuestPhase = eQuestPhase, need = 100, have = 100, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:869 �ؾ���������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 869)		------���Թ����ճ��Ƿ���cd ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.GONG].finished = true
	else
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.GONG].finished = false
	end

end

-------�����
local CHA_QUEST = {
	[14246] = true,
}
ADD2MONITED_QUEST_LIST(CHA_QUEST)
function LR_AccountStatistics_RiChang.CheckChaGuan()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[���������в�] ����ID��14246
	local dwQuestID = 14246
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.CHA] = {eQuestPhase = eQuestPhase, need = 10, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local need = quest_state[1].need
		local have = quest_state[1].have
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.CHA] = {eQuestPhase = eQuestPhase, need = need, have = have, }
	elseif eQuestPhase ==  3 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.CHA] = {eQuestPhase = eQuestPhase, need = 10, have = 10, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:45009 �����
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 45009)		------���Բ���Ƿ���cd ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.CHA].finished = true
	else
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.CHA].finished = false
	end
end

---------���޲������
LR_AccountStatistics_RiChang.QinXiu = {
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
}
ADD2MONITED_QUEST_LIST(LR_AccountStatistics_RiChang.QinXiu)
-----������޲��
function LR_AccountStatistics_RiChang.CheckQinXiu()
	local me = GetClientPlayer()
	if not me then
		return
	end

	local QinXiu = LR_AccountStatistics_RiChang.QinXiu
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
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.QIN] = {eQuestPhase = eQuestPhase, need = 3, have = 0, }
		elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
			local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
			local quest_state = QuestTraceInfo.quest_state
			local need = quest_state[1].need
			local have = quest_state[1].have
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.QIN] = {eQuestPhase = eQuestPhase, need = need, have = have, }
		elseif eQuestPhase ==  3 then
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.QIN] = {eQuestPhase = eQuestPhase, need = 3, have = 3, }
		end
		if eCanAccept ==  57 then
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.QIN].finished = true
		else
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.QIN].finished = false
		end
	else
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.QIN] = {eQuestPhase = 0, need = 3, have = 0, finished = false, }
	end
end

-----���ݵ�ó��
local MAOYI_QUEST = {
	[11864] = true,
	[11991] = true,
}
ADD2MONITED_QUEST_LIST(MAOYI_QUEST)
function LR_AccountStatistics_RiChang.CheckMaoYi()
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
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.JU] = {eQuestPhase = eQuestPhase, need = "3K", have = 0, }
		elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
			local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
			local quest_state = QuestTraceInfo.need_item
			local need = quest_state[1].need
			local have = quest_state[1].have
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.JU] = {eQuestPhase = eQuestPhase, need = "3K", have = have, }
		elseif eQuestPhase ==  3 then
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.JU] = {eQuestPhase = eQuestPhase, need = "3K", have = 3000, }
		end
		if eCanAccept ==  57 then
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.JU].finished = true
		else
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.JU].finished = false
		end
	else
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.JU] = {eQuestPhase = 0, need = "3K", have = 0, finished = false, }
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
function LR_AccountStatistics_RiChang.CheckJingKuang()
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
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.JING] = {eQuestPhase = eQuestPhase, need = "1K", have = 0, }
		elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
			local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
			local quest_state = QuestTraceInfo.quest_state
			local need = quest_state[1].need
			local have = quest_state[1].have
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.JING] = {eQuestPhase = eQuestPhase, need = "1K", have = have, }
		elseif eQuestPhase ==  3 then
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.JING] = {eQuestPhase = eQuestPhase, need = "1K", have = 1000, }
		end

		------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:46968 Ī�ƣ������ˣ�	;	46969 Ī��(���˹�)	��
		local eCanAccept = me.CanAcceptQuest(dwQuestID, dwTemplateID)		------���Ծ��������Ƿ���cd ������57��������ɶ��Ѵ�����
		if eCanAccept ==  57 then
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.JING].finished = true
		else
			LR_AccountStatistics_RiChang.SelfData[RI_CHANG.JING].finished = false
		end
	else
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.JING] = {eQuestPhase = 0, need = "1K", have = 0, finished = false, }
	end
end


-----�����ɲ�
local CAIXIANCAO_QUEST = {
	[8332] = true,
}
ADD2MONITED_QUEST_LIST(CAIXIANCAO_QUEST)
function LR_AccountStatistics_RiChang.CheckCaiCao()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[�����������ɲ�] ����ID��8332
	local dwQuestID = 8332
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.CAI] = {eQuestPhase = eQuestPhase, need = 7, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local have = 0
		for k, v in pairs(quest_state) do
			if v.have == 1 then
				have = have+1
			end
		end
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.CAI] = {eQuestPhase = eQuestPhase, need = 7, have = have, }
	elseif eQuestPhase ==  3 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.CAI] = {eQuestPhase = eQuestPhase, need = 7, have = 7, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:16747 ���������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 16747)		------���Բ��ɲ��Ƿ���cd ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.CAI].finished = true
	else
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.CAI].finished = false
	end
end

-----���Ѱ����
local XUNLONGMAI_QUEST = {
	[13600] = true,
}
ADD2MONITED_QUEST_LIST(XUNLONGMAI_QUEST)
function LR_AccountStatistics_RiChang.CheckLongMai()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[Ѱ�����������] ����ID��13600
	local dwQuestID = 13600
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.XUN] = {eQuestPhase = eQuestPhase, need = 5, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local need = quest_state[1].need
		local have = quest_state[1].have
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.XUN] = {eQuestPhase = eQuestPhase, need = 5, have = have, }
	elseif eQuestPhase ==  3 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.XUN] = {eQuestPhase = eQuestPhase, need = 5, have = 5, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:16747 ���������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 16747)		------���Բ��ɲ��Ƿ���cd ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.XUN].finished = true
	else
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.XUN].finished = false
	end
end

-----�������ͼ
local MEIRENTU_QUEST = {
	[7669] = true,
}
ADD2MONITED_QUEST_LIST(MEIRENTU_QUEST)
function LR_AccountStatistics_RiChang.CheckMeiRenTu()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[����ͼ] ����ID��7669
	local dwQuestID = 7669
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.TU] = {eQuestPhase = eQuestPhase, need = 2, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local have = 0
		for k, v in pairs(quest_state) do
			if v.have == 1 then
				have = have+1
			end
		end
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.TU] = {eQuestPhase = eQuestPhase, need = 2, have = have, }
	elseif eQuestPhase ==  3 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.TU] = {eQuestPhase = eQuestPhase, need = 2, have = 2, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:16747 ���������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 16747)		------���Բ��ɲ��Ƿ���cd ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.TU].finished = true
	else
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.TU].finished = false
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
function LR_AccountStatistics_RiChang.CheckHeiMi()
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

	LR_AccountStatistics_RiChang.SelfData[RI_CHANG.MI] = {eQuestPhase = 0, need = num_all, have = num_finish, }
	if num_accecp > 0 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.MI].eQuestPhase = 1
	end
	if num_all ==  num_finish and num_all ~= 0 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.MI] = {eQuestPhase = 0, need = 0, have = 0, }
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.MI].finished = true
	else
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.MI].finished = false
	end
end

-----��鵾������2016
local HUIGUANG_QUEST = {
	[15594] = true,
}
ADD2MONITED_QUEST_LIST(HUIGUANG_QUEST)
function LR_AccountStatistics_RiChang.CheckHUIGUANG()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[�ع�˷Ӱ] ����ID��15594
	local dwQuestID = 15594
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.HUIGUANG] = {eQuestPhase = eQuestPhase, need = 0, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
--[[		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local quest_state = QuestTraceInfo.quest_state
		local need = quest_state[1].need
		local have = quest_state[1].have]]
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.HUIGUANG] = {eQuestPhase = eQuestPhase, need = 1, have = 1, }
	elseif eQuestPhase ==  3 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.HUIGUANG] = {eQuestPhase = eQuestPhase, need = 0, have = 0, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:52417 ���������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 52417)		------���Իع�˷Ӱ ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.HUIGUANG].finished = true
	else
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.HUIGUANG].finished = false
	end
end

---�����ȹ�
local CHENXIANGSHANGU_QUEST = {
	[15770] = true,
}
ADD2MONITED_QUEST_LIST(CHENXIANGSHANGU_QUEST)
function LR_AccountStatistics_RiChang.CheckHuaShan()
	local me = GetClientPlayer()
	if not me then
		return
	end

	-----[�����ȹ�] ����ID��15770
	local dwQuestID = 15770
	local eQuestPhase = me.GetQuestPhase(dwQuestID)
	if eQuestPhase ==  0 or eQuestPhase ==  -1 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.HUASHAN] = {eQuestPhase = eQuestPhase, need = 100, have = 0, }
	elseif eQuestPhase ==  1 or eQuestPhase ==  2 then
		local QuestTraceInfo = me.GetQuestTraceInfo(dwQuestID)
		local need_item = QuestTraceInfo.need_item
		local need = need_item[1].need
		local have = need_item[1].have
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.HUASHAN] = {eQuestPhase = eQuestPhase, need = 100, have = have, }
	elseif eQuestPhase ==  3 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.HUASHAN] = {eQuestPhase = eQuestPhase, need = 100, have = 100, }
	end

	------CanAcceptQuest(dwQuestID, dwTemplateID) dwTemplateID:15770 ���������
	local eCanAccept = me.CanAcceptQuest(dwQuestID, 52417)		------���Իع�˷Ӱ ������57��������ɶ��Ѵ�����
	if eCanAccept ==  57 then
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.HUASHAN].finished = true
	else
		LR_AccountStatistics_RiChang.SelfData[RI_CHANG.HUASHAN].finished = false
	end
end

------------------------------------------------
---����
------------------------------------------------
LR_AS_Exam = LR_AS_Exam or {}
LR_AS_Exam.AllUsrData = {}
LR_AS_Exam.SelfData = {
	["ShengShi"] = 0,
	["HuiShi"] = 0,
}

function LR_AS_Exam.LoadData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM exam_data WHERE bDel = 0 AND szKey IS NOT NULL")
	local Data = DB_SELECT:GetAll() or {}
	local AllUsrData = {}
	if Data and next(Data) ~=  nil then
		for k, v in pairs(Data) do
			AllUsrData[v.szKey] = v
		end
	end
	LR_AS_Exam.AllUsrData = clone(AllUsrData)
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	LR_AS_Exam.CheckExam()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	LR_AS_Exam.AllUsrData[szKey] = clone(LR_AS_Exam.SelfData)
end

function LR_AS_Exam.SaveData(DB)
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	LR_AS_Exam.CheckExam()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local v = LR_AS_Exam.SelfData or {}
	local DB_REPLACE = DB:Prepare("REPLACE INTO exam_data ( szKey, ShengShi, HuiShi, bDel ) VALUES ( ?, ?, ?, ? )")
	if LR_AccountStatistics.UsrData.OthersCanSee then
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey, v.ShengShi, v.HuiShi, 0)
		DB_REPLACE:Execute()
	else
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey, 0, 0, 1)
		DB_REPLACE:Execute()
	end
end

function LR_AS_Exam.ResetData(DB)
	--�忼��
	local DB_SELECT = DB:Prepare("SELECT szKey FROM exam_data WHERE bDel = 0 AND szKey IS NOT NULL")
	local result = DB_SELECT:GetAll() or {}
	if result and next(result) ~=  nil then
		local DB_REPLACE = DB:Prepare("REPLACE INTO exam_data ( szKey, bDel ) VALUES ( ?, 0 )")
		for k, v in pairs(result) do
			DB_REPLACE:ClearBindings()
			DB_REPLACE:BindAll(v.szKey)
			DB_REPLACE:Execute()
		end
	end
end

function LR_AS_Exam.CheckExam()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local buffList = LR.GetBuffList(me)
	LR_AS_Exam.SelfData = {
		["ShengShi"] = 0,
		["HuiShi"] = 0,
	}
	if LR.HasBuff(buffList, 10936) then
		LR_AS_Exam.SelfData["ShengShi"] = 1
	end
	if LR.HasBuff(buffList, 4125) then
		LR_AS_Exam.SelfData["HuiShi"] = 1
	end
	LR_AS_Exam.AllUsrData[szKey] = clone(LR_AS_Exam.SelfData)
end

-------------------------------------------------
function LR_AccountStatistics_RiChang.ResetData()
	local CurrentTime =  GetCurrentTime()
	local _date = TimeToDate(CurrentTime)
	local weekday = _date["weekday"]
	local hour = _date["hour"]
	local minute = _date["minute"]
	local second = _date["second"]
	-----------����һ��ˢ�£��ܳ����ճ����ݣ�
	if weekday ==  0 then
		weekday = 7
	end
	if weekday ==  1 and hour < 7 then
		return
	end
	local day = weekday-1
	if day<0 then
		day = 0
	end
	local RefreshTimeMonday = CurrentTime - day * 86400 - hour * 60 * 60 - minute* 60 - second + 7 * 60 *60
	local RefreshTimeEveryDay		------------------ÿ�������ճ�����ʱ��
	if hour<7 then
		RefreshTimeEveryDay = CurrentTime -  (hour+24) * 60 * 60 - minute* 60 - second + 7 * 60 *60
	else
		RefreshTimeEveryDay = CurrentTime -  hour * 60 * 60 - minute* 60 - second + 7 * 60 *60
	end
	local RefreshTimeThursday = RefreshTimeMonday 	---����ˢ��ʱ��
	if (weekday > 4) or (weekday ==  4 and hour>= 7 ) then
		day = weekday - 4
		if day<0 then
			day = 0
		end
		RefreshTimeThursday = CurrentTime - day * 86400 - hour * 60 * 60 - minute* 60 - second + 7 * 60 *60
	end
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	------����ʱ��
	local DB_SELECT = DB:Prepare("SELECT * FROM richang_clear_time WHERE szName IS NOT NULL")
	local Data = DB_SELECT:GetAll() or {}
	local RC_ResetTime = {
		ClearTimeRC = 0,			--�ճ�
		ClearTimeZC = 0,			--�ܳ�
		ClearTime5R = 0,
		ClearTime10R = 0,
		ClearTime25R = 0,
 	}

	if Data and next(Data) ~= nil then
		for k, v in pairs(Data) do
			RC_ResetTime[v.szName] = v.nTime
		end
	end
	if RefreshTimeMonday > RC_ResetTime.ClearTimeZC or RefreshTimeEveryDay > RC_ResetTime.ClearTimeRC or RefreshTimeThursday > RC_ResetTime.ClearTime10R then
		LR_AccountStatistics_RiChang.LoadAllUsrData(DB)
		if RefreshTimeMonday > RC_ResetTime.ClearTimeZC then
			LR_AccountStatistics_RiChang.ClearZC(DB)
			LR_AccountStatistics_RiChang.ClearRC(DB)
			LR_AS_Exam.ResetData(DB)
			LR_AccountStatistics_FBList.ClearAllData(DB)	--�Դ�д��
			LR_AccountStatistics_FBList.ClearAllReaminJianBen(DB)		--�Դ�д��
			LR_ACS_QiYu.ClearAllData(DB)
			RC_ResetTime.ClearTimeZC = GetCurrentTime()
			RC_ResetTime.ClearTimeRC = GetCurrentTime()
			RC_ResetTime.ClearTime5R = GetCurrentTime()
			RC_ResetTime.ClearTime10R = GetCurrentTime()
			RC_ResetTime.ClearTime25R = GetCurrentTime()

			LR.DelayCall(2000, function()
				LR_AS_DB.MainDBVacuum(true)
			end)
		elseif RefreshTimeThursday > RC_ResetTime.ClearTime10R then
			LR_AccountStatistics_RiChang.ClearRC(DB)
			LR_AccountStatistics_FBList.ClearAllData10R(DB)	--�Դ�д��
			LR_AccountStatistics_FBList.ClearAllData5R(DB)		--�Դ�д��
			LR_ACS_QiYu.ClearAllData(DB)
			RC_ResetTime.ClearTime5R = GetCurrentTime()
			RC_ResetTime.ClearTimeRC = GetCurrentTime()
			RC_ResetTime.ClearTime10R = GetCurrentTime()
		else
			LR_AccountStatistics_RiChang.ClearRC(DB)
			LR_AccountStatistics_FBList.ClearAllData5R(DB)		--�Դ�д��
			LR_ACS_QiYu.ClearAllData(DB)
			RC_ResetTime.ClearTime5R = GetCurrentTime()
			RC_ResetTime.ClearTimeRC = GetCurrentTime()
		end
		---���������ԣ���������Ҫ����Loadһ��--����ͨ����Ϸapi�������
		LR_ACS_QiYu.LoadAllUsrData(DB)

		---����������д�����ݿ�
		local name, wen = {}, {}
		for k, v in pairs(RI_CHANG) do
			name[#name + 1] = k
			wen[#wen + 1] = "?"
		end
		name[#name + 1] = "CUSTOM_QUEST"
		wen[#wen + 1] = "?"
		local DB_REPLACE = DB:Prepare(sformat("REPLACE INTO richang_data ( bDel, szKey, %s ) VALUES ( ?, %s, ? )", tconcat(name, ", "), tconcat(wen, ", ")))
		for szKey, v in pairs (LR_AccountStatistics_RiChang.AllUsrData) do
			local value = {}
			for  k2, v2 in pairs(RI_CHANG) do
				value[#value+1] = LR.JsonEncode(v[v2])
			end
			value[#value + 1] = LR.JsonEncode(v.CUSTOM_QUEST)

			DB_REPLACE:ClearBindings()
			DB_REPLACE:BindAll(0, szKey, unpack(value))
			DB_REPLACE:Execute()
		end
		--��¼����ʱ��
		local szName = {"ClearTimeZC", "ClearTimeRC", "ClearTime5R", "ClearTime10R", "ClearTime25R"}
		local DB_REPLACE2 = DB:Prepare("REPLACE INTO richang_clear_time (szName, nTime) VALUES ( ?, ? )")
		for k, v in pairs (szName) do
			DB_REPLACE2:ClearBindings()
			DB_REPLACE2:BindAll(v, RC_ResetTime[v])
			DB_REPLACE2:Execute()
		end
	end
	DB:Execute("END TRANSACTION")
	DB:Release()
end

function LR_AccountStatistics_RiChang.ClearZC()
	local t_Table =  LR_AccountStatistics_RiChang.List
	for szKey, v in pairs(LR_AccountStatistics_RiChang.AllUsrData) do
		for k2, v2 in pairs(t_Table) do
			if v2.nType ==  "ZC" then		------���ڹ��˲����ճ�������
				if v[v2.order] then
					if v[v2.order].finished then
						LR_AccountStatistics_RiChang.AllUsrData[szKey][v2.order].finished = false
					end
				end
			end
		end

		local CUSTOM_QUEST = v.CUSTOM_QUEST or {}
		if next(CUSTOM_QUEST) ~= nil then
			for k2, v2 in pairs (LR_AccountStatistics_RiChang.CustomQuestList or {}) do
				if v2.refresh == "WEEK" or v.refresh == "EVERYDAY" then
					if CUSTOM_QUEST[tostring(v2.dwID)] then
						CUSTOM_QUEST[tostring(v2.dwID)] = nil
					end
				end
			end
		end
	end
end

------����ճ���¼
function LR_AccountStatistics_RiChang.ClearRC()
	local t_Table =  LR_AccountStatistics_RiChang.List
	for szKey, v in pairs(LR_AccountStatistics_RiChang.AllUsrData) do
		for k2, v2 in pairs(t_Table) do
			if v2.nType ==  "RC" then		------���ڹ��˲����ճ�������
				if v[v2.order] then
					if v[v2.order].finished then
						LR_AccountStatistics_RiChang.AllUsrData[szKey][v2.order].finished = false
					end
				end
			end
		end

		local CUSTOM_QUEST = v.CUSTOM_QUEST or {}
		for k2, v2 in pairs (LR_AccountStatistics_RiChang.CustomQuestList or {}) do
			if v2.refresh == "EVERYDAY" then
				if CUSTOM_QUEST[tostring(v2.dwID)] then
					CUSTOM_QUEST[tostring(v2.dwID)] = nil
				end
			end
		end
	end
end

---------------------------------
-----��¼��������״̬
function LR_AccountStatistics_RiChang.CheckAll()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	-------PVE
	----����ս
	LR_AccountStatistics_RiChang.CheckDazhan()
	----��鹫���¼�
	LR_AccountStatistics_RiChang.CheckGongShiJian()

	-------PVX
	----�����
	LR_AccountStatistics_RiChang.CheckChaGuan()
	----������޲��
	LR_AccountStatistics_RiChang.CheckQinXiu()
	----�����ɲ�
	LR_AccountStatistics_RiChang.CheckCaiCao()
	----Ѱ����
	LR_AccountStatistics_RiChang.CheckLongMai()
	----����ͼ
	LR_AccountStatistics_RiChang.CheckMeiRenTu()
	----�ٱ���/����
	LR_AccountStatistics_RiChang.CheckHeiMi()
	----2016�ع⵾���
	LR_AccountStatistics_RiChang.CheckHUIGUANG()
	----�����ȹ�
	LR_AccountStatistics_RiChang.CheckHuaShan()

	------PVP
	----���ݵ�ó��
	LR_AccountStatistics_RiChang.CheckMaoYi()
	----��龧������
	LR_AccountStatistics_RiChang.CheckJingKuang()

	----����
	LR_AS_Exam.CheckExam()

end

function LR_AccountStatistics_RiChang.ListRC()
	local frame = Station.Lookup("Normal/LR_AccountStatistics")
	if not frame then
		return
	end
	local title_handle = LR_AccountStatistics.LR_RCList_Title_handle
	local n = 1
	local List = LR_AccountStatistics_RiChang.List

	for i = 1, #List, 1 do
		if LR_AccountStatistics_RiChang.UsrData.List[List[i].order] and n<= 8 then
			local text = title_handle:Lookup(sformat("Text_RC%d_Break", n))
			text:SetText(List[i].szName)
			n = n+1
		end
	end

	for k, v in pairs (LR_AccountStatistics_RiChang.CustomQuestList) do
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

	local TempTable_Cal, TempTable_NotCal = LR_AccountStatistics.SeparateUsrList()

	LR_AccountStatistics.LR_RCList_Container:Clear()
	num = LR_AccountStatistics_RiChang.ShowItem (TempTable_Cal, 255, 1, 0)
	num = LR_AccountStatistics_RiChang.ShowItem (TempTable_NotCal, 60, 1, num)
	LR_AccountStatistics.LR_RCList_Container:FormatAllContentPos()
end


function LR_AccountStatistics_RiChang.ShowItem (t_Table, Alpha, bCal, _num)
	local num = _num
	local TempTable = clone(t_Table)

	local me = GetClientPlayer()
	if not me then
		return
	end

	for i = 1, #TempTable, 1 do
		num = num+1
		local wnd = LR_AccountStatistics.LR_RCList_Container:AppendContentFromIni("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics_RCList_Item.ini", "RCList_WndWindow", num)
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
		item_Name:SprintfText("%s��%d��", name, TempTable[i].nLevel)
		local r, g, b = LR.GetMenPaiColor(TempTable[i].dwForceID)
		item_Name:SetFontColor(r, g, b)
		--  Output(LR.GetMenPaiColor(TempTable[i].MenPai))

		local realArea = TempTable[i].realArea
		local realServer = TempTable[i].realServer
		local szName = TempTable[i].szName
		local player  = GetClientPlayer()
		local szKey = sformat("%s_%s_%d", realArea, realServer, TempTable[i].dwID)
		local RC_Record = LR_AccountStatistics_RiChang.AllUsrData[szKey] or {}

		------����ճ�
		local n = 1
		local List = LR_AccountStatistics_RiChang.List
		for i = 1, #List, 1 do
			if LR_AccountStatistics_RiChang.UsrData.List[List[i].order] and n<= 8 then
				local Text_FB = items:Lookup(sformat("Text_RC%d", n))
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
		local CustomQuestList = LR_AccountStatistics_RiChang.CustomQuestList or {}
		local CUSTOM_QUEST = RC_Record.CUSTOM_QUEST or {}
		for k, v in pairs(CustomQuestList) do
			if v.bShow and n <= 8 then
				local Text_FB = items:Lookup(sformat("Text_RC%d", n))
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
			local Text_FB = items:Lookup(sformat("Text_RC%d", j))
			Text_FB:SetText("")
			Text_FB:SetFontScheme(41)
		end

		--------------------���tips
		items:RegisterEvent(786)
		items.OnItemMouseEnter = function ()
			item_Select:Show()
			local nMouseX, nMouseY =  Cursor.GetPos()
			local szTipInfo = {}
			local szPath, nFrame = GetForceImage(TempTable[i].dwForceID)
			szTipInfo[#szTipInfo+1] = GetFormatImage(szPath, nFrame, 26, 26)
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s��%d��\n", TempTable[i].szName, TempTable[i].nLevel), 62, r, g, b)
			--szTipInfo[#szTipInfo+1] = GetFormatImage("ui\\image\\Common\\Money.uitex", 246, 260, 26)
			szTipInfo[#szTipInfo+1] = GetFormatImage("ui\\image\\ChannelsPanel\\NewChannels.uitex", 166, 260, 27)
			szTipInfo[#szTipInfo+1] = GetFormatText("\n", 62)
			local List = LR_AccountStatistics_RiChang.List
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
			local CustomQuestList = LR_AccountStatistics_RiChang.CustomQuestList or {}
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
		items.OnItemMouseLeave = function()
			item_Select:Hide()
			HideTip()
		end
		items.OnItemLButtonClick = function()

		end
	end
	return num
end


-----------------------------------------------------------------
LR_QuestTools = CreateAddon("LR_QuestTools")
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

	----------����
	LR.AppendAbout(LR_QuestTools, frame)

	local imgTab = self:Append("Image", frame, "TabImg", {w = 381, h = 33, x = 0, y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)

	local hPageSet = self:Append("PageSet", frame, "PageSet", {x = 20, y = 120, w = 360, h = 360})
	local hWinIconView = self:Append("Window", hPageSet, "WindowItemView", {x = 0, y = 0, w = 360, h = 360})
	local hScroll = self:Append("Scroll", hWinIconView, "Scroll", {x = 0, y = 0, w = 354, h = 360})
	self:LoadItemBox(hScroll)
	hScroll:UpdateList()

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

function LR_QuestTools:LoadItemBox(hWin)
	local me =  GetClientPlayer()
	if not me then
		return
	end

	local m = 1
	local Quest = {}
	for i = 0, 24, 1 do
		local dwQuestID = me.GetQuestID(i)
		if dwQuestID>0 then
			Quest[#Quest+1] = {dwQuestID = dwQuestID}
		end
	end

	tsort(Quest, function(a, b)
		if a.dwQuestID<b.dwQuestID then
			return true
		else
			return false
		end
	end)

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

		local dwQuestID = Quest[m].dwQuestID
		local QuestInfo = LR.Table_GetQuestStringInfo(dwQuestID)
		local szName = QuestInfo.szName

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
			--------
		end
	end
end


--------------------------------------
--------�¼�����
--------------------------------------
local _quest_save_time = 0
local function SAVE_QUEST(dwQuestID)
	if not MONITED_QUEST_LIST[dwQuestID] then
		return
	end
	local _time = GetCurrentTime()
	if _time - _quest_save_time < 60 * 1 then
		return
	end
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	LR_AccountStatistics_RiChang.SaveData(DB)
	DB:Execute("END TRANSACTION")
	DB:Release()
	Log("[LR] RI_CHANG_QUEST_EVENT_SAVE\n")
	_quest_save_time = GetCurrentTime()
end

function LR_AccountStatistics_RiChang.QUEST_ACCEPTED()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwQuestID = arg1
	SAVE_QUEST(dwQuestID)
end

function LR_AccountStatistics_RiChang.QUEST_DATA_UPDATE()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwQuestID = me.GetQuestID(arg0)
	SAVE_QUEST(dwQuestID)
end

function LR_AccountStatistics_RiChang.QUEST_FINISHED()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwQuestID = arg0
	SAVE_QUEST(dwQuestID)
end

function LR_AccountStatistics_RiChang.QUEST_FAILED()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwQuestID = me.GetQuestID(arg0)
	SAVE_QUEST(dwQuestID)
end

function LR_AccountStatistics_RiChang.QUEST_CANCELED()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwQuestID = arg0
	SAVE_QUEST(dwQuestID)
end

function LR_AccountStatistics_RiChang.FIRST_LOADING_END()
	if not (LR_AccountStatistics_RiChang.UsrData and LR_AccountStatistics_RiChang.UsrData.Version and LR_AccountStatistics_RiChang.UsrData.Version == LR_AccountStatistics_RiChang.Default.Version) then
		LR_AccountStatistics_RiChang.ResetMenuList()
	end
	LR_AccountStatistics_RiChang.LoadCustomQuestList()
	LR_AccountStatistics_RiChang.GetCustomQuestStatus()

	LR_AccountStatistics_RiChang.LoadCommomMenuList()
	LR.DelayCall(300, function()
		LR_AccountStatistics_RiChang.ResetData()
		LR_AccountStatistics_RiChang.CheckAll()
	end)
end

LR.RegisterEvent("QUEST_ACCEPTED", function() LR_AccountStatistics_RiChang.QUEST_ACCEPTED() end)
LR.RegisterEvent("QUEST_DATA_UPDATE", function() LR_AccountStatistics_RiChang.QUEST_DATA_UPDATE() end)
LR.RegisterEvent("QUEST_FINISHED", function() LR_AccountStatistics_RiChang.QUEST_FINISHED() end)
LR.RegisterEvent("QUEST_FAILED", function() LR_AccountStatistics_RiChang.QUEST_FAILED() end)
LR.RegisterEvent("QUEST_CANCELED", function() LR_AccountStatistics_RiChang.QUEST_CANCELED() end)

LR.RegisterEvent("FIRST_LOADING_END", function() LR_AccountStatistics_RiChang.FIRST_LOADING_END() end)
