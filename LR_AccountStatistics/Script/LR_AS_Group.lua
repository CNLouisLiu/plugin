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
--------------------------------------------------------------
LR_AS_Group = {}
LR_AS_Group.GroupChose = {}	--存放选择显示的Group
LR_AS_Group.GroupList = {}	--存放Group列表
LR_AS_Group.AllUsrGroup = {}	--存放人员的Group信息
LR_AS_Group.ShowDataNotInGroup = false --显示不在分组中的人物

local _Group = {}
--------------------------------------------
----分组
--------------------------------------------
function _Group.LoadGroupListData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM group_list WHERE groupID IS NOT NULL")
	DB_SELECT:ClearBindings()
	local Data = d2g(DB_SELECT:GetAll())
	local Group = {}
	for k, v in pairs(Data) do
		Group[v.groupID] = v
	end
	LR_AS_Group.GroupList = clone(Group)
end

--读取所有人员的分组信息
function _Group.LoadAllUserGroup(DB)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local DB_SELECT = DB:Prepare("SELECT player_group.*, group_list.szName FROM player_group INNER JOIN group_list ON group_list.groupID = player_group.groupID WHERE player_group.szKey IS NOT NULL")
	local Data = d2g(DB_SELECT:GetAll())
	local AllUsrGroup = {}
	for k, v in pairs(Data) do
		AllUsrGroup[v.szKey] = v
	end
	LR_AS_Group.AllUsrGroup = clone(AllUsrGroup)
end

---更新我所在分组的精力、体力信息
function _Group.UpdateMyGroupInfo(DB)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local DB_SELECT = DB:Prepare("SELECT group_list.* FROM group_list INNER JOIN player_group ON player_group.groupID = group_list.groupID WHERE player_group.szKey = ? AND player_group.groupID > 0 AND player_group.szKey IS NOT NULL")
	DB_SELECT:ClearBindings()
	DB_SELECT:BindAll(g2d(szKey))
	local result = d2g(DB_SELECT:GetAll())
	if result and next(result) ~= nil then
		local v = result[1]
		v.nMaxStamina = me.nMaxStamina or 0
		v.nCurrentStamina = me.nCurrentStamina or 0
		v.nMaxThew = me.nMaxThew or 0
		v.nCurrentThew = me.nCurrentThew or 0
		v.SaveTime = GetCurrentTime()
		local DB_REPLACE = DB:Prepare("REPLACE INTO group_list ( groupID, szName, nCurrentStamina, nMaxStamina, nCurrentThew, nMaxThew, SaveTime ) VALUES ( ?, ?, ?, ?, ?, ?, ? )")
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(unpack(g2d({v.groupID, v.szName, v.nCurrentStamina, v.nMaxStamina, v.nCurrentThew, v.nMaxThew, v.SaveTime})))
		DB_REPLACE:Execute()
	end
end

function _Group.SaveData(DB)
	_Group.UpdateMyGroupInfo(DB)
end

function _Group.LoadData(DB)
	_Group.LoadGroupListData(DB)
	_Group.LoadAllUserGroup(DB)
end

------------------------------------------------
--判定某个分组里是否有某个人
function _Group.ifGroupHasUser(key, groupID)
	if LR_AS_Group.AllUsrGroup[key] and LR_AS_Group.AllUsrGroup[key].groupID == groupID then
		return true
	else
		return false
	end
end

--根据组名获取组id
function _Group.GetGroupIDbyGroupName(szGroupName)
	local Group = LR_AS_Group.GroupList
	for k, v in pairs (Group) do
		if v.szName == szGroupName then
			return k
		end
	end
	return 0
end

--修改某个人员的组别
function _Group.ChangeUserGroup(szKey, groupID, DB)
	if groupID > 0 then
		local DB_REPLACE = DB:Prepare("REPLACE INTO player_group (szKey, groupID) VALUES ( ?, ? )")
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(g2d(szKey), g2d(groupID))
		DB_REPLACE:Execute()
	else
		local DB_DELETE = DB:Prepare("DELETE FROM player_group WHERE szKey = ?")
		DB_DELETE:ClearBindings()
		DB_DELETE:BindAll(g2d(szKey))
		DB_DELETE:Execute()
	end
	_Group.LoadAllUserGroup(DB)
end

--增加分组
function _Group.AddGroup(szGroupName, DB)
	local GroupID = _Group.GetGroupIDbyGroupName(szGroupName)
	if GroupID == 0 then
		local DB_INSERT = DB:Prepare("INSERT INTO group_list (szName) VALUES ( ? )")
		DB_INSERT:ClearBindings()
		DB_INSERT:BindAll(g2d(szGroupName))
		DB_INSERT:Execute()
		_Group.LoadGroupListData(DB)
	else
		LR.SysMsg(_L["Already have the same name group.\n"])
	end
end

--删除分组
function _Group.DelGroup(groupID, DB)
	local DB_DELETE = DB:Prepare("DELETE FROM group_list WHERE groupID = ?")
	DB_DELETE:ClearBindings()
	DB_DELETE:BindAll(g2d(groupID))
	DB_DELETE:Execute()
	local DB_DELETE2 = DB:Prepare("DELETE FROM player_group WHERE groupID = ?")
	DB_DELETE2:ClearBindings()
	DB_DELETE2:BindAll(g2d(groupID))
	DB_DELETE2:Execute()
end

--重命名分组
function _Group.RenameGroup(groupID, szNewGroupName, DB)
	local ID = _Group.GetGroupIDbyGroupName(szNewGroupName)
	if ID == 0 then
		local DB_UPDATE = DB:Prepare("UPDATE group_list SET szName = ? WHERE groupID = ?")
		DB_UPDATE:ClearBindings()
		DB_UPDATE:BindAll(g2d(szNewGroupName), g2d(groupID))
		DB_UPDATE:Execute()
		_Group.LoadGroupListData(DB)
	else
		LR.SysMsg(_L["Already have the same name group.\n"])
	end
end

--------------------------------------------
--界面部分弹出Group菜单
--------------------------------------------
function _Group.PopupUIMenu()
	local menu = {}
	local GroupList = LR_AS_Group.GroupList
	for groupID, v in pairs(GroupList) do
		local szGroupName = v.szName
		tinsert(menu, {szOption = szGroupName, bCheck = true, bMCheck = false, bChecked = function() return _Group.CheckShowGroup(groupID) end,
			fnAction = function()
				_Group.AddShowGroup(groupID)
				--读取
				LR_AS_Base.LoadData()
				--舒心UI
				LR_AS_Panel.RefreshUI()
				FireEvent("LR_ACS_REFRESH_FP")
			end,
			{szOption = _L["Delete Group"],
				fnAction = function()
					--保存
					local path = sformat("%s\\%s", SaveDataPath, db_name)
					local DB = SQLite3_Open(path)
					DB:Execute("BEGIN TRANSACTION")
					_Group.DelGroup(groupID, DB)
					DB:Execute("END TRANSACTION")
					DB:Release()
					--从查看的分组列表里删除
					_Group.AddShowGroup(groupID, "DEL")
					--读取
					LR_AS_Base.LoadData()
					--刷新UI
					LR_AS_Panel.RefreshUI()
				end
			},
			{szOption = _L["Rename Group"],
				fnAction = function()
					GetUserInput(_L["Group Name"], function(szText)
						local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
						if szText ~=  "" then
							--保存
							local path = sformat("%s\\%s", SaveDataPath, db_name)
							local DB = SQLite3_Open(path)
							DB:Execute("BEGIN TRANSACTION")
							_Group.RenameGroup(groupID, szText, DB)
							DB:Execute("END TRANSACTION")
							DB:Release()
							--刷新UI
							LR_AS_Panel.RefreshUI()
						end
					end)
				end
			},
		})
	end
	tinsert(menu, {bDevide = true,})
	tinsert(menu, {szOption = _L["Show data not in choose group. (translucence)"], bCheck = true, bMCheck = false, bChecked = function() return LR_AS_Group.ShowDataNotInGroup end,
		fnAction = function()
			LR_AS_Group.ShowDataNotInGroup = not LR_AS_Group.ShowDataNotInGroup
			--读取信息
			LR_AS_Base.LoadData()
			--刷新UI
			LR_AS_Panel.RefreshUI()
		end,
	})
	tinsert(menu, {szOption = _L["Add Group"],
		fnAction = function()
			GetUserInput(_L["Group Name"], function(szText)
				local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
				if szText ~=  "" then
					--保存分组
					local path = sformat("%s\\%s", SaveDataPath, db_name)
					local DB = SQLite3_Open(path)
					DB:Execute("BEGIN TRANSACTION")
					_Group.AddGroup(szText, DB)
					DB:Execute("END TRANSACTION")
					DB:Release()
					--刷新
					LR_AS_Panel.RefreshUI()
				end
			end)
		end,
	})
	PopupMenu(menu)
end

function _Group.AddShowGroup(groupID, flag)
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

function _Group.CheckShowGroup(groupID)
	local GroupChose = LR_AS_Group.GroupChose
	for i = 1, #GroupChose, 1 do
		if GroupChose[i] == groupID then
			return true
		end
	end
	return false
end

----------------------------------------------
---其他开放
----------------------------------------------
LR_AS_Group.PopupUIMenu = _Group.PopupUIMenu
LR_AS_Group.ifGroupHasUser = _Group.ifGroupHasUser
LR_AS_Group.ChangeUserGroup = _Group.ChangeUserGroup
LR_AS_Group.SaveData = _Group.SaveData

--注册模块
LR_AS_Module.Group = {}
LR_AS_Module.Group.SaveData = _Group.SaveData
LR_AS_Module.Group.LoadData = _Group.LoadData


