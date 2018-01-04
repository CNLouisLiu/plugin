local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local DB_name = "maindb.db"
local _L  =  LR.LoadLangPack(AddonPath)
-----------------------------------------------------------
LR_AS_Group = LR_AS_Group or {}
LR_AS_Group.GroupList = {}	--���Group�б�
LR_AS_Group.AllUsrGroup = {}	--�����Ա��Group��Ϣ
LR_AS_Group.GroupChose = {}	--���ѡ����ʾ��Group
--------------------------------------------
----����
--------------------------------------------
function LR_AS_Group.LoadGroupListData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM group_list WHERE groupID IS NOT NULL")
	DB_SELECT:ClearBindings()
	local Data = DB_SELECT:GetAll() or {}
	local Group = {}
	for k, v in pairs(Data) do
		Group[v.groupID] = v
	end
	LR_AS_Group.GroupList = clone(Group)
end
--LR_AS_Base.Add2FirstLoadingEndList({szKey = "LoadGroupListData", fnAction = LR_AS_Group.LoadGroupListData, order = 10})

--��ȡ������Ա�ķ�����Ϣ
function LR_AS_Group.LoadAllUserGroup(DB)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local DB_SELECT = DB:Prepare("SELECT player_group.*, group_list.szName FROM player_group INNER JOIN group_list ON group_list.groupID = player_group.groupID WHERE player_group.szKey IS NOT NULL")
	local Data = DB_SELECT:GetAll()
	local AllUsrGroup = {}
	for k, v in pairs(Data) do
		AllUsrGroup[v.szKey] = v
	end
	LR_AS_Group.AllUsrGroup = clone(AllUsrGroup)
end
--LR_AS_Base.Add2FirstLoadingEndList({szKey = "LoadAllUserGroup", fnAction = LR_AS_Group.LoadAllUserGroup, order = 20})

---���������ڷ���ľ�����������Ϣ
function LR_AS_Group.UpdateMyGroupInfo(DB)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local DB_SELECT = DB:Prepare("SELECT group_list.* FROM group_list INNER JOIN player_group ON player_group.groupID = group_list.groupID WHERE player_group.szKey = ? AND player_group.groupID > 0 AND player_group.szKey IS NOT NULL")
	DB_SELECT:ClearBindings()
	DB_SELECT:BindAll(szKey)
	local result = DB_SELECT:GetAll() or {}
	if result and next(result) ~= nil then
		local v = result[1]
		v.nMaxStamina = me.nMaxStamina or 0
		v.nCurrentStamina = me.nCurrentStamina or 0
		v.nMaxThew = me.nMaxThew or 0
		v.nCurrentThew = me.nCurrentThew or 0
		v.SaveTime = GetCurrentTime()
		local DB_REPLACE = DB:Prepare("REPLACE INTO group_list ( groupID, szName, nCurrentStamina, nMaxStamina, nCurrentThew, nMaxThew, SaveTime ) VALUES ( ?, ?, ?, ?, ?, ?, ? )")
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(v.groupID, v.szName, v.nCurrentStamina, v.nMaxStamina, v.nCurrentThew, v.nMaxThew, v.SaveTime)
		DB_REPLACE:Execute()
	end
end
--��ӵ��Զ������б�
--LR_AS_Base.Add2AutoSave({szKey = "UpdateMyGroupInfo", fnAction = LR_AS_Group.UpdateMyGroupInfo, order = 10})

--�ж�ĳ���������Ƿ���ĳ����
function LR_AS_Group.ifGroupHasUser(key, groupID)
	if LR_AS_Group.AllUsrGroup[key] and LR_AS_Group.AllUsrGroup[key].groupID == groupID then
		return true
	else
		return false
	end
end

--����������ȡ��id
function LR_AS_Group.GetGroupIDbyGroupName(szGroupName)
	local Group = LR_AS_Group.GroupList
	for k, v in pairs (Group) do
		if v.szName == szGroupName then
			return k
		end
	end
	return 0
end

--�޸�ĳ����Ա�����
function LR_AS_Group.ChangeUserGroup(szKey, groupID, DB)
	if groupID > 0 then
		local DB_REPLACE = DB:Prepare("REPLACE INTO player_group (szKey, groupID) VALUES ( ?, ? )")
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey, groupID)
		DB_REPLACE:Execute()
	else
		local DB_DELETE = DB:Prepare("DELETE FROM player_group WHERE szKey = ?")
		DB_DELETE:ClearBindings()
		DB_DELETE:BindAll(szKey)
		DB_DELETE:Execute()
	end
	LR_AS_Group.LoadAllUserGroup(DB)
end

--���ӷ���
function LR_AS_Group.AddGroup(szGroupName, DB)
	local GroupID = LR_AS_Group.GetGroupIDbyGroupName(szGroupName)
	if GroupID == 0 then
		local DB_INSERT = DB:Prepare("INSERT INTO group_list (szName) VALUES ( ? )")
		DB_INSERT:ClearBindings()
		DB_INSERT:BindAll(szGroupName)
		DB_INSERT:Execute()
		LR_AS_Group.LoadGroupListData(DB)
	else
		LR.SysMsg(_L["Already have the same name group.\n"])
	end
end

--ɾ������
function LR_AS_Group.DelGroup(groupID, DB)
	local DB_DELETE = DB:Prepare("DELETE FROM group_list WHERE groupID = ?")
	DB_DELETE:ClearBindings()
	DB_DELETE:BindAll(groupID)
	DB_DELETE:Execute()
	local DB_DELETE2 = DB:Prepare("DELETE FROM player_group WHERE groupID = ?")
	DB_DELETE2:ClearBindings()
	DB_DELETE2:BindAll(groupID)
	DB_DELETE2:Execute()
	LR_AS_Group.LoadGroupListData(DB)
end

--����������
function LR_AS_Group.RenameGroup(groupID, szNewGroupName, DB)
	local ID = LR_AS_Group.GetGroupIDbyGroupName(szNewGroupName)
	if ID == 0 then
		local DB_UPDATE = DB:Prepare("UPDATE group_list SET szName = ? WHERE groupID = ?")
		DB_UPDATE:ClearBindings()
		DB_UPDATE:BindAll(szNewGroupName, groupID)
		DB_UPDATE:Execute()
		LR_AS_Group.LoadGroupListData(DB)
	else
		LR.SysMsg(_L["Already have the same name group.\n"])
	end
end

--------------------------------------------
--���沿�ֵ���Group�˵�
--------------------------------------------
function LR_AS_Group.ShowGroup()
	local menu = {}
	local GroupList = LR_AS_Group.GroupList
	for groupID, v in pairs(GroupList) do
		local szGroupName = v.szName
		tinsert(menu, {szOption = szGroupName, bCheck = true, bMCheck = false, bChecked = function() return LR_AS_Group.CheckShowGroup(groupID) end,
			fnAction = function()
				local path = sformat("%s\\%s", SaveDataPath, DB_name)
				local DB = SQLite3_Open(path)
				DB:Execute("BEGIN TRANSACTION")
				LR_AS_Group.AddShowGroup(groupID)
				LR_AS_Info.LoadAllUserInformation(DB)
				LR_AS_Info.ListAS()
				LR_AccountStatistics_FBList.ListFB()
				LR_AccountStatistics_RiChang.ListRC()
				LR_ACS_QiYu.ListQY()
				LR_Acc_Achievement_Panel:ReloadItemBox()
				DB:Execute("END TRANSACTION")
				DB:Release()
				FireEvent("LR_ACS_REFRESH_FP")
			end,
			{szOption = _L["Delete Group"],
				fnAction = function()
					local path = sformat("%s\\%s", SaveDataPath, DB_name)
					local DB = SQLite3_Open(path)
					DB:Execute("BEGIN TRANSACTION")
					LR_AS_Group.DelGroup(groupID, DB)
					LR_AS_Group.AddShowGroup(groupID, "DEL")
					LR_AS_Info.LoadAllUserInformation(DB)
					LR_AS_Info.ListAS()
					LR_AccountStatistics_FBList.ListFB()
					LR_AccountStatistics_RiChang.ListRC()
					LR_ACS_QiYu.ListQY()
					DB:Execute("END TRANSACTION")
					DB:Release()
				end
			},
			{szOption = _L["Rename Group"],
				fnAction = function()
					GetUserInput(_L["Group Name"], function(szText)
						local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
						if szText ~=  "" then
							local path = sformat("%s\\%s", SaveDataPath, DB_name)
							local DB = SQLite3_Open(path)
							DB:Execute("BEGIN TRANSACTION")
							LR_AS_Group.RenameGroup(groupID, szText, DB)
							LR_AS_Info.ListAS()
							LR_AccountStatistics_FBList.ListFB()
							LR_AccountStatistics_RiChang.ListRC()
							LR_ACS_QiYu.ListQY()
							DB:Execute("END TRANSACTION")
							DB:Release()
						end
					end)
				end
			},
		})
	end
	tinsert(menu, {bDevide = true,})
	tinsert(menu, {szOption = _L["Show data not in choose group. (translucence)"], bCheck = true, bMCheck = false, bChecked = function() return LR_AS_Group.showDataNotInGroup end,
		fnAction = function()
			LR_AS_Group.showDataNotInGroup = not LR_AS_Group.showDataNotInGroup
			local path = sformat("%s\\%s", SaveDataPath, DB_name)
			local DB = SQLite3_Open(path)
			DB:Execute("BEGIN TRANSACTION")
			LR_AS_Info.LoadAllUserInformation(DB)
			LR_AS_Info.ListAS()
			LR_AccountStatistics_FBList.ListFB()
			LR_AccountStatistics_RiChang.ListRC()
			LR_ACS_QiYu.ListQY()
			DB:Execute("END TRANSACTION")
			DB:Release()
		end,
	})
	tinsert(menu, {szOption = _L["Add Group"],
		fnAction = function()
			GetUserInput(_L["Group Name"], function(szText)
				local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
				if szText ~=  "" then
					local path = sformat("%s\\%s", SaveDataPath, DB_name)
					local DB = SQLite3_Open(path)
					DB:Execute("BEGIN TRANSACTION")
					LR_AS_Group.AddGroup(szText, DB)
					LR_AS_Info.ListAS()
					LR_AccountStatistics_FBList.ListFB()
					LR_AccountStatistics_RiChang.ListRC()
					LR_ACS_QiYu.ListQY()
					DB:Execute("END TRANSACTION")
					DB:Release()
				end
			end)
		end,
	})
	PopupMenu(menu)
end

function LR_AS_Group.AddShowGroup(groupID, flag)
	local GroupChose = LR_AS_Group.GroupChose or {}
	local bExist = false
	for i = #GroupChose, 1, -1 do
		if GroupChose[i] == groupID then
			tremove(LR_AS_Group.GroupChose, i)
			bExist = true
		end
	end
	if not bExist and not flag then
		tinsert(LR_AS_Group.GroupChose, groupID)
	end
end

function LR_AS_Group.CheckShowGroup(groupID)
	local GroupChose = LR_AS_Group.GroupChose
	for i = 1, #GroupChose, 1 do
		if GroupChose[i] == groupID then
			return true
		end
	end
	return false
end




