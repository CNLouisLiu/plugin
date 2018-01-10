local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local DB_name = "maindb.db"
local _L  =  LR.LoadLangPack(AddonPath)
local CustomVersion = "20170111"
-----------------------------------------------------------
LR_AS_Base = LR_AS_Base or {}
LR_AS_Base.default = {
	UsrData = {
		OthersCanSee = false,
		nkey = "nMoney",
		nsort = "desc",
		AutoSave = true,
		OpenSave = true,
		CloseSave = true,
		FloatPanel = false,
		NotCalList = {},
	},
}

LR_AS_Base.UsrData = clone(LR_AS_Base.default.UsrData)
RegisterCustomData("LR_AS_Base.UsrData", CustomVersion)

---------------------------------
---AutoSave
---------------------------------
LR_AS_Base.AutoSaveList = {
	--{szKey = "", fnAction = function() ... end, order = x,}
}

function LR_AS_Base.Add2AutoSave(list)
	local list = list or {szKey = "none", fnAction = function() return false end, order = 9999}
	tinsert(LR_AS_Base.AutoSaveList, {szKey = list.szKey, fnAction = list.fnAction, order = list.order})
	tsort(LR_AS_Base.AutoSaveList, function(a, b) return a.order < b.order end)
end

function LR_AS_Base.AutoSave()
	--check
	if not LR_AS_Base.UsrData.AutoSave then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	--------------save
	local _check_time = GetTickCount()
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	for k, v in pairs(LR_AS_Base.AutoSaveList) do
		v.fnAction(DB)
	end
	---�������ľ���������Ϣ
	LR_AS_Group.UpdateMyGroupInfo(DB)
	----�������ݣ���Ǯ���ﹱ�ȣ�
	LR_AS_Info.SaveSelfInfo(DB)
	------����ֿ�
	LR_AccountStatistics_Bank.SaveData(DB)
	------���汳��
	LR_AccountStatistics_Bag.SaveData(DB)
	------����װ�������ԡ�װ��
	LR_AccountStatistics_Equip.SaveData(DB)
	-----���渱������
	LR_AccountStatistics_FBList.SaveData(DB)
	-----�����Ķ�����
	LR_AccountStatistics_BookRd.SaveData(DB)
	----�ճ�����
	LR_AccountStatistics_RiChang.SaveData(DB)
	--���濼��
	LR_AS_Exam.SaveData(DB)
	----��¼�ɾ�
	LR_AccountStatistics_Achievement.SaveData(DB)

	DB:Execute("END TRANSACTION")
	DB:Release()

	-----����
	ApplyMapSaveCopy()
	Log(sformat("[LR] AS Auto save cost %0.3f s", (GetTickCount() - _check_time) * 1.0 / 1000))
end

---------------------------------
---ResetData����һ�����������ݣ�
---------------------------------
local RESET_TYPE = {
	NONE = 0,
	EVERY_DAY = 1,
	MONDAY = 2,
	THURSDAY = 3,
}

LR_AS_Base.ResetDataList = {
	--{szKey = "", fnAction = function() ... end, order = x,},
}

function LR_AS_Base.Debug1()
	for k, v in pairs(LR_AS_Base.ResetDataList) do
		Output(v.szKey, v.nType)
	end
end


function LR_AS_Base.Add2ResetData(list)
	local list = list or {szKey = "none", fnAction = function() return false end, order = 9999, nType = RESET_TYPE.NONE}
	tinsert(LR_AS_Base.ResetDataList, {szKey = list.szKey, fnAction = list.fnAction, order = list.order, nType = list.nType})
	tsort(LR_AS_Base.ResetDataList, function(a, b) return a.order < b.order end)
end

function LR_AS_Base.ResetDataEveryDay(DB)
	for k, v in pairs(LR_AS_Base.ResetDataList) do
		if v.nType == RESET_TYPE.EVERY_DAY then
			v.fnAction(DB)
		end
	end
end

function LR_AS_Base.ResetDataMonday(DB)
	for k, v in pairs(LR_AS_Base.ResetDataList) do
		if v.nType == RESET_TYPE.MONDAY then
			v.fnAction(DB)
		end
	end
end

function LR_AS_Base.ResetDataThursday(DB)
	for k, v in pairs(LR_AS_Base.ResetDataList) do
		if v.nType == RESET_TYPE.THURSDAY then
			v.fnAction(DB)
		end
	end
end

function LR_AS_Base.ResetData()
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
	local day = weekday - 1
	if day < 0 then
		day = 0
	end
	---��һˢ��ʱ��
	local RefreshTimeMonday = CurrentTime - day * 86400 - hour * 60 * 60 - minute* 60 - second + 7 * 60 *60
	------------------ÿ�������ճ�����ʱ��
	local RefreshTimeEveryDay
	if hour < 7 then
		RefreshTimeEveryDay = CurrentTime -  (hour+24) * 60 * 60 - minute* 60 - second + 7 * 60 *60
	else
		RefreshTimeEveryDay = CurrentTime -  hour * 60 * 60 - minute* 60 - second + 7 * 60 *60
	end
	---����ˢ��ʱ��
	local RefreshTimeThursday = RefreshTimeMonday
	if (weekday > 4) or (weekday ==  4 and hour>= 7 ) then
		day = weekday - 4
		if day<0 then
			day = 0
		end
		RefreshTimeThursday = CurrentTime - day * 86400 - hour * 60 * 60 - minute* 60 - second + 7 * 60 *60
	end
	--------
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	------����ʱ��
	local RC_ResetTime = {
		ClearTimeEveryDay = 0,
		ClearTimeMonday = 0,
		ClearTimeThursday = 0,
	}
	local DB_SELECT = DB:Prepare("SELECT * FROM richang_clear_time WHERE szName IS NOT NULL")
	local Data = DB_SELECT:GetAll() or {}
	if Data and next(Data) ~= nil then
		for k, v in pairs(Data) do
			if RC_ResetTime[v.szName] then
				RC_ResetTime[v.szName] = v.nTime or 0
			end
		end
	end
	if RefreshTimeMonday > RC_ResetTime.ClearTimeMonday or RefreshTimeThursday > RC_ResetTime.ClearTimeThursday or RefreshTimeEveryDay > RC_ResetTime.ClearTimeEveryDay then
		if RefreshTimeMonday > RC_ResetTime.ClearTimeMonday then
			LR_AS_Base.ResetDataMonday(DB)
			LR_AS_Base.ResetDataThursday(DB)
			LR_AS_Base.ResetDataEveryDay(DB)
			----
			RC_ResetTime.ClearTimeMonday = CurrentTime
			RC_ResetTime.ClearTimeThursday = CurrentTime
			RC_ResetTime.ClearTimeEveryDay = CurrentTime
			----ÿ���Ż����ݿ�
			LR.DelayCall(2000, function()
				LR_AS_DB.MainDBVacuum(true)
			end)
		elseif RefreshTimeThursday > RC_ResetTime.ClearTimeThursday then
			LR_AS_Base.ResetDataThursday(DB)
			LR_AS_Base.ResetDataEveryDay(DB)
			--
			RC_ResetTime.ClearTimeThursday = CurrentTime
			RC_ResetTime.ClearTimeEveryDay = CurrentTime
		elseif RefreshTimeEveryDay > RC_ResetTime.ClearTimeEveryDay then
			LR_AS_Base.ResetDataEveryDay(DB)
			--
			RC_ResetTime.ClearTimeEveryDay = CurrentTime
		end
		--��¼����ʱ��
		local szName = {"ClearTimeEveryDay", "ClearTimeMonday", "ClearTimeThursday"}
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

---------------------------------
---FirstLoadingEnd	--��Ҫ������Ҫ���ݿ�Ĳ���
---------------------------------
LR_AS_Base.FirstLoadingEndList = {
	--{szKey = "", fnAction = function() ... end, order = x},
}

function LR_AS_Base.Add2FirstLoadingEndList(list)
	local list = list or {szKey = "none", fnAction = function() return false end, order = 9999}
	tinsert(LR_AS_Base.FirstLoadingEndList, {szKey = list.szKey, fnAction = list.fnAction, order = list.order, nType = list.nType})
	tsort(LR_AS_Base.FirstLoadingEndList, function(a, b) return a.order < b.order end)
end

function LR_AS_Base.FIRST_LOADING_END()
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	for k, v in pairs(LR_AS_Base.FirstLoadingEndList) do
		v.fnAction(DB)
	end
	LR_AS_Group.LoadGroupListData(DB)
	LR_AS_Group.LoadAllUserGroup(DB)
	LR_AS_Info.LoadUserList(DB)
	LR_AS_Info.LoadAllUserInformation(DB)

	--װ����ȡ��װ��
	LR_AccountStatistics_Equip.LoadSelfData(DB)
	----��ȡ��������
	LR_ACS_QiYu.LoadAllUsrData(DB)

	DB:Execute("END TRANSACTION")
	DB:Release()
	FireEvent("LR_ACS_REFRESH_FP")

	LR_AS_Base.ResetData()
	LR.DelayCall(15000, LR_AS_Base.AutoSave())
end

LR.RegisterEvent("FIRST_LOADING_END", function() LR_AS_Base.FIRST_LOADING_END() end)

---------------------------------
---�����ڲ��ֽ����ʱ�Ĳ���
---------------------------------
local _auto_save_lasttime	= 0	--��OptionPanel�Ĳ���ʱ���¼������10s����ʼ�
local _auto_save_lasttime2 = 0	--���ټ��3���ӱ���һ�μ�¼

function LR_AS_Base.ON_FRAME_CREATE()
	local frame = arg0
	local szName = frame:GetName()
	if szName  ==  "ExitPanel" then
		frame:Lookup("Btn_Sure"):Enable(false)
		LR.DelayCall(1000, function()
			local frame = Station.Lookup("Topmost2/ExitPanel")
			if frame then
				frame:Lookup("Btn_Sure"):Enable(true)
			end
		end)
		Log("[LR_AccountStatistics]:Exit save")
		LR_AS_Base.AutoSave()
		LR_ACS_QiYu.SaveData()
		LR_Acc_Trade.MoveData2MainTable()
		FireEvent("LR_ACS_REFRESH_FP")
		frame:Lookup("Btn_Sure"):Enable(true)
	elseif szName  ==  "OptionPanel" then
		---ÿ10����ഥ��һ��
		local _time = GetCurrentTime()
		if _time - _auto_save_lasttime > 10 then
			local _check_time = GetTickCount()
			local path = sformat("%s\\%s", SaveDataPath, DB_name)
			local DB = SQLite3_Open(path)
			DB:Execute("BEGIN TRANSACTION")
			LR_AS_Group.LoadAllUserGroup(DB)
			LR_AS_Info.LoadUserList(DB)
			LR_AS_Info.LoadAllUserInformation(DB)
			DB:Execute("END TRANSACTION")
			DB:Release()
			Log(sformat("[LR] Sync user data cost %0.3f s", (GetTickCount() - _check_time) * 1.0 / 1000 ))
			-----------�ʼ�����
			LR_AccountStatistics_Mail_Check.CheckAllMail()
			LR_Acc_Trade.OutPutMoneyChange()
			_auto_save_lasttime = _time
		end

		if _time - _auto_save_lasttime2 > 60 * 3 then
			LR_AS_Base.AutoSave()
			LR_ACS_QiYu.SaveData()
			_auto_save_lasttime2 = _time
		end

		FireEvent("LR_ACS_REFRESH_FP")
	elseif szName  ==  "BigBagPanel" then
		----�ڱ����������һ��������Ʒͳ�Ƶİ�ť
		LR.DelayCall(500, function()
			LR_AccountStatistics_Bag.HookBag()
		end)
	elseif szName == "MailPanel" then
		LR_Acc_Trade.OpenMailPanel()
		-----
		LR.DelayCall(200, function()
			LR_AccountStatistics_Bag.HookMailPanel()
		end)
	elseif szName == "GuildBankPanel" then
		LR.DelayCall(150, function() LR_GuildBank.HookGuildBank() end)
	elseif szName ==  "AuctionPanel" then
		LR_Acc_Trade.GetItemInBag()
	elseif szName ==  "CharacterPanel" then
		LR_AccountStatistics_Equip.Hack()
	end
end
LR.RegisterEvent("ON_FRAME_CREATE", function() LR_AS_Base.ON_FRAME_CREATE()  end)

---------------------------------
---�ڽ�������Ӱ�ť
---------------------------------
function LR_AS_Base.AddButton(parent, szName, szText, x, y, w, h, fnAction, fnEnter, fnLeave)
	local Button = LR.AppendUI("Button", parent, szName, {text = szText, x = x, y = y, w = w, h = h})
	Button.OnEnter = fnEnter
	Button.OnLeave = fnLeave
	Button.OnClick = fnAction

	return Button
end

---------------------------------
---ɾ������
---------------------------------
function LR_AS_Base.DelOneData (key, DB)
	local key = key
	local loginArea = key.loginArea
	local loginServer = key.loginServer
	local realArea = key.realArea or loginArea
	local realServer = key.realServer or loginServer
	local szName = key.szName
	local dwID = key.dwID

	------ɾ��UserList�ڵ�����
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	LR_AS_Info.AllUsrList[szKey] = nil

	-----ɾ���ɾ�����
	DB:Execute(sformat("DELETE FROM achievement_data WHERE szKey = '%s'", szKey))

	-----ɾ����������
	DB:Execute(sformat("DELETE FROM bag_item_data WHERE belong = '%s'", szKey))

	-----ɾ���ֿ�����
	DB:Execute(sformat("DELETE FROM bank_item_data WHERE belong = '%s'", szKey))

	----ɾ���Ķ���Ϣ
	DB:Execute(sformat("DELETE FROM bookrd_data WHERE szKey = '%s'", szKey))

	----ɾ��װ����Ϣ
	DB:Execute(sformat("DELETE FROM equipment_data WHERE szKey = '%s'", szKey))

	----ɾ����������
	DB:Execute(sformat("DELETE FROM exam_data WHERE szKey = '%s'", szKey))

	----ɾ����������
	DB:Execute(sformat("DELETE FROM fb_data WHERE szKey = '%s'", szKey))

	----ɾ���ʼ�����
	DB:Execute(sformat("DELETE FROM mail_data WHERE belong = '%s'", szKey))
	DB:Execute(sformat("DELETE FROM mail_item_data WHERE belong = '%s'", szKey))
	DB:Execute(sformat("DELETE FROM mail_receive_time WHERE szKey = '%s'", szKey))

	----ɾ���������ڷ���
	DB:Execute(sformat("DELETE FROM player_group WHERE szKey = '%s'", szKey))

	-----ɾ����ɫ��Ϣ����
	DB:Execute(sformat("DELETE FROM player_info WHERE szKey = '%s' ", szKey))

	----ɾ����ɫ��������
	DB:Execute(sformat("DELETE FROM qiyu_data WHERE szKey = '%s'", szKey))

	----ɾ���ճ�����
	DB:Execute(sformat("DELETE FROM richang_data WHERE szKey = '%s'", szKey))

	LR.SysMsg(_L["Delete successful!\n"])
end

---------------------------------
---��� ��ʾ�Ͳ���ʾ�� �����б�
---------------------------------
function LR_AS_Base.SeparateUsrList()
	local nkey = LR_AS_Base.UsrData.nkey or "nMoney"
	local nsort = LR_AS_Base.UsrData.nsort or "desc"

	LR_AS_Info.UpdateSelfInfoInAllData()
	local AllUsrData = LR_AS_Info.AllUsrData or {}
	local TempTable = {}
	for k, v in pairs (AllUsrData) do
		TempTable[#TempTable+1] = clone(v)
	end

	tsort(TempTable, function(a, b)
			if a[nkey] and b[nkey] then
				if nsort  ==  "asc" then
					if a[nkey]  ==  b[nkey] then
						if  a["nLevel"]  ==  b["nLevel"] then
							if a["dwForceID"]  ==  b["dwForceID"] then
								if a["szName"]  ==  b["szName"] then
									return a["dwID"] < b["dwID"]
								else
									return a["szName"] < b["szName"]
								end
							else
								return a["dwForceID"] < b["dwForceID"]
							end
						else
							return a["nLevel"] > b["nLevel"]
						end
					else
						return a[nkey] < b[nkey]
					end
				else
					if a[nkey]  ==  b[nkey] then
						if  a["nLevel"]  ==  b["nLevel"] then
							if a["dwForceID"]  ==  b["dwForceID"] then
								if a["szName"]  ==  b["szName"] then
									return a["dwID"] > b["dwID"]
								else
									return a["szName"] > b["szName"]
								end
							else
								return a["dwForceID"] < b["dwForceID"]
							end
						else
							return a["nLevel"] < b["nLevel"]
						end
					else
						return a[nkey] > b[nkey]
					end
				end
			else
				return true
			end
		end)

	local TempTable_NotCal = {}
	local TempTable_Cal = {}

	for i = 1, #TempTable, 1 do
		local bShow = true
		local GroupChose = LR_AS_Group.GroupChose
		local realArea = TempTable[i].realArea
		local realServer = TempTable[i].realServer
		local dwID = TempTable[i].dwID
		local szName = TempTable[i].szName
		local key = sformat("%s_%s_%d", realArea, realServer, dwID)
		local NotCalList = LR_AS_Base.UsrData.NotCalList or {}
		if #GroupChose == 0 then
			if NotCalList[key] then
				bShow = false
			end
		else
			local isExist = false
			for j = 1, #GroupChose, 1 do
				if LR_AS_Group.ifGroupHasUser(key, GroupChose[j]) then
					isExist = true
				end
			end
			if not isExist then
				bShow = false
			end
		end
		if bShow then
			tinsert (TempTable_Cal, TempTable[i])
		else
			tinsert (TempTable_NotCal, TempTable[i])
		end
	end

	return TempTable_Cal, TempTable_NotCal
end
