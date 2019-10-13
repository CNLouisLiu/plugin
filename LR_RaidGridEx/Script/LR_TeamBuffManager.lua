local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local VERSION = "20190128"		--修改此项可重置为默认数据
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_RaidGridEx"
local SaveDataPath="Interface\\LR_Plugin@DATA\\LR_TeamGrid"
local _L = LR.LoadLangPack(AddonPath)

local _DEBUG = LR.DEBUG.Addon:New("BUFF_MANAGER")
----------------------------------------------------------------
--引用的变量都在这里设置
----------------------------------------------------------------
--地图缓存数据
local LR_Team_Map = _GMV.LR_Team_Map	--用于存地图BUFF信息
local LR_Team_Map_Sorted =  _GMV.LR_Team_Map_Sorted	--按年代排序地图信息
---------------------------------------------------------------
LR_BuffManager = {}
LR_BuffManager.CustomData = {{author = "unknown", title = "unknown", key = "unknown", file = "unknown"}, {bEncrypted = true, data = {}}}
--[[结构
data = {
	{szGroupName = "xx", enable = true, data = {
		{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
		{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
	},},
	{szGroupName = "xx", enable = true, data = {
		{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
		{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
	},},
}
]]
LR_BuffManager.DungeonData = {{author = "unknown", title = "unknown", key = "unknown", file = "unknown"}, {bEncrypted = true, data = {}}}
--[[
保存的文件结构
data = {
	{dwMapID = {xx, xx}, data = {
		{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
		{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
	},},
	{dwMapID = {xx, xx}, data = {
		{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
		{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
	},},
}
内存中的结构
data = {	相当于将文件结构中的key从序号转换为地图的名字
	[szMapName] = {
		{dwMapID = {xx, xx}, data = {
			{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
			{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
		},},
	},
	[szMapName] = {
		{dwMapID = {xx, xx}, data = {
			{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
			{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
		},},
	},
}
]]

local _Manager = {}
----------------------------------------------------------------
----数据保存载入默认数据
----------------------------------------------------------------
local DEFAULT_BUFF = {
	dwID = 0,
	enable = true,
	nLevel = 1,
	bOnlySelf = false,	--仅来源于我
	bOnlyMonitorSelf = false,	--仅监控我
	bOnlyInKungfu = {},	--限制心法
	bOnlyShowInTeamRights = {},	--限制团队成员显示，例如团长
	nMonitorLevel = 0,	--0：不区分等级
	nStackNum = 1,
	nMonitorStack = 0,	--0：不区分层数
	nIconID = 0,	--0：使用原来的ICON
	col = {},
	--醒目BUFF，醒目BUFF会有单独Handle放大，且只有醒目BUFF才有颜色模版，如果某些BUFF叠上X层后要重点显示，请用醒目BUFF，设置后开可以设置在X层下也显示
	bSpecialBuff = false,	--BUFF放大
	bShowMask = false,
	bShowUnderStack = false,
	--
	nEffectsType = 0,	--BUFF效果，普通BUFF也可以设置效果，也可以起到醒目的作用
	nSoundType = 0,	--声音报警
	bShowInTopHead = false,
}

local DEFAULT_AUTHOR = {
	author = "***",
	title = "***",
	key = "***",
	file = "***",
}

local DEFAULT_CUSTOM_DATA = {
	bEncrypted = true,
	data = {},
}

local DEFAULT_CUSTOM_GROUP = {
	szGroupName = "#GroupName",
	enable = true,
	data = {},
}

local DEFAULT_DUNGEON_DATA = {
	bEncrypted = true,
	data = {}
}

local DEFAULT_DUNGEON_GROUP = {
	dwMapID = {},
	data = {},
}

----------------------------------------------------------------
----表的简化以及补全
----------------------------------------------------------------
--[[
boolean类型变量，默认true的，当值为true时则不导出；如果默认值是false的，则当值为false时不导出
数值类型的变量，默认值为x的，当值为x时，不导出
字符串类型的变量，默认值为x的，当值为x时，不导出
表类型的，当表为空时不导出
]]
function _Manager.SimplifiedData(v, default) --简化表
	if type(v) == "boolean" or type(default) == "boolean" then
		if default then
			return v == false and v or v == true and nil
		else
			return v == true or nil
		end
	elseif type(v) == "table" or type(default) == "table" then
		if type(default) == "table" then
			if next(default) == nil then
				return next(v or {}) ~= nil and v or nil
			else
				local t = {}
				for k2, v2 in pairs(default) do
					t[k2] = _Manager.SimplifiedData(v[k2], v2)
				end
				return _Manager.SimplifiedData(t, {})
			end
		end
		return next(v or {}) ~= nil and v or nil
	elseif type(v) == "number" or type(default) == "number" then
		return v ~= default and v or nil
	elseif type(v) == "string" then
		return v ~= default and v or nil
	end
end

function _Manager.FullData(v, default)
	if type(v) == "boolean" or type(default) == "boolean" then
		if default then
			return v == nil or v
		else
			return v or v == nil and false
		end
	elseif type(v) == "table" or type(default) == "table" then
		if type(default) == "table" then
			if next(default) == nil then
				return v or {}
			else
				local temp = {}
				for k2, v2 in pairs(default) do
					temp[k2] = _Manager.FullData(v[k2], v2)
				end
				return temp
			end
		end
		--return next(v or {}) == nil and (default) or (v)
	elseif type(v) == "number" or type(default) == "number" then
		return v or default
	elseif type(v) == "string" then
		return v or default
	end
end

------------------------------
----本地数据的加载与保存
----如果是下载载数据保存，data不为空；如果只是本地数据保存，则data为空，data从内存中调取
----如果是下载数据保存，bEncrypted根据下载的文件进行设定；如果只是本地文件，则按内存来设定
------------------------------
function tt()
	_Manager.SaveData("CustomData", nil, nil)
end

function _Manager.SaveData(nType, author, data, bTest)
	local nType = nType == "DungeonData" and "DungeonData" or "CustomData"
	--local mem_data = data or (nType == "DungeonData" and clone(LR_BuffManager.DungeonData[2].data) or clone(LR_BuffManager.CustomData[2].data) )
	local mem_data = data or (nType == "DungeonData" and clone(LR_Team_Map) or clone(LR_TeamBuffTool.tBuffList) )
	local author = author or (nType == "DungeonData" and clone(LR_BuffManager.DungeonData[1]) or clone(LR_BuffManager.CustomData[1]) )

	local save_data = {}
	for szGroupName, tGroup in pairs(mem_data) do
		local temp = {}
		if nType == "DungeonData" then
			temp.dwMapID = _Manager.SimplifiedData(tGroup.dwMapID, {})
		else
			temp = _Manager.SimplifiedData({szGroupName = tGroup.szGroupName, enable = tGroup.enable}, DEFAULT_CUSTOM_GROUP)
		end
		--以下副本数据以及自定义数据通用
		temp.data = {}
		for k2, v2 in pairs(tGroup.data) do
			local simed = _Manager.SimplifiedData(v2, DEFAULT_BUFF)
			if simed and next(simed) ~= nil then
				tinsert(temp.data, simed)
			end
		end
		tinsert(save_data, temp)
	end

	save_data.nType = nType
	local save_file = {author, {bEncrypted = true, data = ""}}
	local path = nType == "DungeonData" and sformat("%s\\BUFF\\DungeonData", SaveDataPath) or sformat("%s\\BUFF\\CustomData", SaveDataPath)
	if bTest then
		save_file[2].data = clone(save_data)
		SaveLUAData(path .. "_Test", save_file, "\t", false)
	else
		save_file[2].data = LR.basexx.to_base64(EncryptAES(LR.JsonEncode(save_data), author.key))
		SaveLUAData(path, save_file, nil, false)
	end
end


function _Manager.LoadData(nType, file)
	local nType = nType == "DungeonData" and "DungeonData" or "CustomData"
	local path = file or nType == "DungeonData" and sformat("%s\\BUFF\\DungeonData", SaveDataPath) or sformat("%s\\BUFF\\CustomData", SaveDataPath)
	local data = LoadLUAData(path)
	local author = {author = data[1].author, title = data[1].title, key = data[1].key}
	local bEncrypted = data[2] and data[2].data and type(data[2].data) == "string" and true or false
	local data2 = data[2].data
	if bEncrypted then
		data2 = LR.JsonDecode(DecryptAES(LR.basexx.from_base64(data2), author.key))
	end
	if not data2 then
		Output("error file")
		return
	end
	local nTypeFile = data2.nType
	if not nTypeFile == nType then
		Output("wrong type")
		return
	end


	local data3 = {}
	data2.nType = nil
	for k, v in pairs(data2) do
		local temp = {}
		if nType == "DungeonData" then
			temp.dwMapID = _Manager.FullData(v.dwMapID, {})
		else
			temp.szGroupName = _Manager.FullData(v.szGroupName, "unknown")
			temp.enable = _Manager.FullData(v.enable, true)
		end
		--
		temp.data = {}
		for k2, v2 in pairs(v.data) do
			local temp4 = _Manager.FullData(v2, DEFAULT_BUFF)
			tinsert(temp.data, temp4)
		end
		if nType == "DungeonData" then
			local szName = "unknown"
			for k2, dwMapID in pairs(temp.dwMapID) do
				if LR.MapType[dwMapID] then
					szName = LR.MapType[dwMapID].szOtherName
				end
			end
			data3[szName]  = clone(temp)
		else
			tinsert(data3, temp)
		end
	end

	if nType == "DungeonData" then
		LR_BuffManager.DungeonData = {author, {bEncrypted = bEncrypted, data = clone(data3)}}
	else
		LR_BuffManager.CustomData = {author, {bEncrypted = bEncrypted, data = clone(data3)}}
	end
end

function _Manager.LoadAllData()
	_Manager.LoadData("DungeonData")
	_Manager.LoadData("CustomData")
end

function _Manager.FIRST_LOADING_END()
	_Manager.LoadAllData()
end

LR_BuffManager.SaveData = _Manager.SaveData
LR_BuffManager.SaveData = _Manager.LoadData
----------------------------------------------------------------
----网络数据的下载与保存
----------------------------------------------------------------




----------------------------------------------------------------
----BUFF数据的记录抓取
----------------------------------------------------------------
--[[
1.每次上线默认不抓取，减少系统负担
2.当抓取开启时，非战斗状态和战斗状态下都会记录BUFF，存储在Cache里，当ESC小退或者战斗结束时会保存为jx3dat文件，文件按照地图进行保存
3.当设定成
]]
----------------------------------------------------------------
local _Grab = {}
_Grab.bOn = false
_Grab.MapCache = {
--[[
注:非副本 mapid = "Map_id(name)"	副本 mapid = "map_szOtherName"
	[Mapid] = {
		[buffid_level] = {},
	}
]]
}
_Grab.TempCache = {}	--临时BUFF，开启记录后，buff就放这
local TEMP_MAX_NUM = 1000

_Grab.FightCache = {}
_Grab.FightCache4Search = {}
_Grab.szKey = ""
_Grab.Fight_Start_Time = 0
_Grab.Nearest_NPC = {szName = "#NoNPC", nIntensity = 0, dwTemplateID = 0, distance = 0}
------------------
----MapCache记录与保存
------------------
function _Grab.SaveMapData()
	local map_data = LR.GetMapData()
	local file_name = sformat("Map_%d(%s)", map_data.dwMapID, Table_GetMapName(map_data.dwMapID))
	local szKey = sformat("%s", Table_GetMapName(map_data.dwMapID))
	if map_data.nType == MAP_TYPE.DUNGEON then
		file_name = sformat("%s", map_data.data.szOtherName)
		szKey = sformat("%s", map_data.data.szOtherName)
	end
	SaveLUAData(sformat("%s\\BUFF\\MAP_BUFF_RECORD\\%s", SaveDataPath, file_name), _Grab.MapCache[szKey], "\t", false)
end

function _Grab.LoadMapData(dwMapID)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local map_data = LR.GetMapData(dwMapID)
	local file_name = sformat("Map_%d(%s)", map_data.dwMapID, Table_GetMapName(map_data.dwMapID))
	local szKey = sformat("%s", Table_GetMapName(map_data.dwMapID))
	if map_data.nType == MAP_TYPE.DUNGEON then
		file_name = sformat("%s", map_data.data.szOtherName)
		szKey = sformat("%s", map_data.data.szOtherName)
	end
	if not _Grab.MapCache[szKey] then		--如果存在就不读取了，因为内存里有了
		_Grab.MapCache[szKey] = LoadLUAData(sformat("%s\\BUFF\\MAP_BUFF_RECORD\\%s", SaveDataPath, file_name)) or {}
	end
end

------------------
----临时Cache记录与保存
------------------
function _Grab.LoadTempCache()
	local path = sformat("%s\\BUFF\\Temp_Buff_Cache", SaveDataPath)
	_Grab.TempCache = clone(LoadLUAData(path))
end

function _Grab.SaveTempCache()
	local path = sformat("%s\\BUFF\\Temp_Buff_Cache", SaveDataPath)
	local t = {}
	if #_Grab.TempCache > TEMP_MAX_NUM then
		for i = 1, TEMP_MAX_NUM do
			tinsert(t, _Grab.TempCache[i])
		end
	else
		t = _Grab.TempCache
	end
	SaveLUAData(path, _Grab.TempCache, "\t", false)
end

------------------
----临时Cache记录与保存
------------------
function _Grab.SaveFightCache()
	local nTime = GetCurrentTime()
	if nTime - _Grab.Fight_Start_Time < 30 then
		return
	end
	local me = GetClientPlayer()
	local _date = TimeToDate(nTime)
	local map_data = LR.GetMapData()
	local Nearest_NPC = _Grab.Nearest_NPC
	local path = sformat("%s\\BUFF\\BUFF_FIGHT_LOG\\%04d%02d%02d_%02d%02d%02d_%s_%s_%s(#%d)", SaveDataPath, _date["year"], _date["month"], _date["day"], _date["hour"], _date["minute"], _date["second"], me.szName, Table_GetMapName(map_data.dwMapID), Nearest_NPC.szName, Nearest_NPC.dwTemplateID )
	local data = clone(_Grab.FightCache)
	data.nType = "BUFF_FIGHT_CACHE"
	LR.SaveLUAData(path, data)
end

function _Grab.LoadFightCache()
	local szFile = GetOpenFileName(sformat("%s", _L["Choose file"]), "Save data File(*.jx3dat)\0*.jx3dat\0All Files(*.*)\0*.*\0")
	if szFile == "" then
		return false
	end
	local _s, _e, szFileName = sfind(szFile,"interface(.+)")
	local path = sformat("interface%s", szFileName)
	local data = LoadLUAData(path) or {}
	if data and data.key and data.key == "BUFF_FIGHT_CACHE" then
		data.key = nil
		_Grab.FightCache4Search = clone(data)
		return true
	else
		_Grab.FightCache4Search = {}
		return false
	end
end

----战斗BUFF的抓取相关
function _Grab.BeginFightLog()
	local me = GetClientPlayer()
	if not me or not me.bFightState then
		return
	end
	_Grab.szKey = sformat("KEY_%d", GetCurrentTime())
	_Grab.Fight_Start_Time = GetCurrentTime()
	_Grab.FightCache[KEY] = {}
	_Grab.Nearest_NPC = LR_TeamTools.DeathRecord.GetNearestNPC()
end

function LR_TeamBuffTool.EndLog()
	if _Grab.szKey ~= "" then
		_Grab.SaveFightCache()
		_Grab.FightCache4Search = clone(_Grab.FightCache[KEY])
	end
	_Grab.szKey = ""
	_Grab.Fight_Start_Time = 0
	_Grab.Nearest_NPC = {szName = "#NoNPC", nIntensity = 0, dwTemplateID = 0, distance = 0}
end

function _Grab.FIGHT_HINT()
	local bFight = arg0
	if not _Grab.bOn then
		return
	end

	if bFight then
		_Grab.BeginFightLog()
	else
		_Grab.EndFightLog()
	end
end


LR.RegisterEvent("FIGHT_HINT", function() _Grab.FIGHT_HINT() end)
----------------------------------------------------------------
----设置面板的UI
----------------------------------------------------------------
--地图缓存数据
local LR_Team_Map = _GMV.LR_Team_Map	--用于存地图BUFF信息
local LR_Team_Map_Sorted =  _GMV.LR_Team_Map_Sorted	--按年代排序地图信息
local _UI = {}
local _C = {}
--
LR_BuffManager_Panel = {}
LR_BuffManager_Panel.nShowType = "DungeonData"	--当前面板显示副本数据
LR_BuffManager_Panel.szGroupSelected = ""
LR_BuffManager_Panel.bShowDungeonMapData = false	---当显示为副本数据时，载入副本的BUFF数据，输出在result里面
LR_BuffManager_Panel.bShowOnlyFightLog = false		---当显示战斗数据时，将战斗的数据显示在result里面

--
LR_BuffManager_Panel.szSearchText = ""
LR_BuffManager_Panel.ResultPageNumTotal = 1
LR_BuffManager_Panel.ResultPageNumCurrent = 1
LR_BuffManager_Panel.ResultPerPageNum = 20
--



function LR_BuffManager_Panel.OnFrameCreate()

	_Manager.LoadAllData()
	LR_BuffManager_Panel.nShowType = "DungeonData"	--当前面板显示副本数据
	LR_BuffManager_Panel.szGroupSelected = ""
	_C.IniDungeonMap()
end

function LR_BuffManager_Panel.OnFrameDestroy()

end

function LR_BuffManager_Panel.OnFrameBreathe()

end

function LR_BuffManager_Panel.OnMouseEnter()
	local szName = this:GetName()
	if szName == "ScrollBuffListBox" then
		if LR_BuffManager_Panel.bDraged then
			LR_BuffManager_Panel.bAdd = true
		end
	end
end

function LR_BuffManager_Panel.OnMouseLeave()
	local szName = this:GetName()
	if szName == "ScrollBuffListBox" then
		LR_BuffManager_Panel.bAdd = false
	end
end

----------------------------------------------------------------
----设置面板的相关函数
----------------------------------------------------------------
function _C.UI(...)
	local h = LR.AppendUI(...)
	_UI[h:GetName()] = h
	return h
end

function _C.Init()
	local frame = _C.UI("Frame", "LR_BuffManager_Panel", {title = _L["LR BuffManager Panel"], style = "LARGER"})

	--
	local imgTab = LR.AppendUI("Image", frame,"TabImg",{w = 960,h = 33,x = 0,y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex",46):SetImageType(11)

	local PageSet = LR.AppendUI("PageSet", frame, "PageSet" , {w = 960, h = 380, x = 0, y = 50})
	--标签页
	local Text_CheckBox = {_L["Dungeon data"], _L["Custom data"]}
	local tchoose = {"DungeonData", "CustomData"}
	for k, v in pairs(Text_CheckBox) do
		local Check_Box = _C.UI("UICheckBox", PageSet, sformat("CheckBox_%s", tchoose[k]), {x = 20 + 150 * (k - 1), y = 1, w = 150, h = 30, text = v, group = "TypeChose"})
		Check_Box.OnCheck = function(bCheck)
			if bCheck then
				LR_BuffManager_Panel.nShowType = tchoose[k]
				_C.LoadGroupList()
			end
		end
		--
	end

	--分组列表
	local hHandle_Group = LR.AppendUI("Handle", frame, "hHandle_Group", {x = 18, y = 90, w = 200, h = 470})
	local Image_Group_BG = LR.AppendUI("Image", hHandle_Group, "Image_Group_BG", {x = 0, y = 0, w = 200, h = 470})
	Image_Group_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",50):SetImageType(10)
	local Image_Group_BG1 = LR.AppendUI("Image", hHandle_Group, "Image_Group_BG1", {x = 0, y = 30, w = 200, h = 440})
	Image_Group_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",74):SetImageType(10):SetAlpha(110)
	local Image_Group_Line1_0 = LR.AppendUI("Image", hHandle_Group, "Image_Group_Line1_0", {x = 3, y = 28, w = 200, h = 3})
	Image_Group_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",65):SetImageType(11):SetAlpha(115)
	local Text_Group_break2 = LR.AppendUI("Text", hHandle_Group, "Text_Group_break2", {w = 200, h = 30, x  = 0, y = 2, text = _L["Group name"], font = 18})
	Text_Group_break2:SetHAlign(1):SetVAlign(1)
	--
	local hScroll1 = _C.UI("Scroll", frame, "ScrollGroupBox", {x = 20, y = 120, w = 200, h = 430})

	--BUFF列表
	local hHandle_BuffList = LR.AppendUI("Handle", frame, "hHandle_BuffList", {x = 228, y = 90, w = 500, h = 470})
	local Image_BuffList_BG = LR.AppendUI("Image", hHandle_BuffList, "Image_Record_BG", {x = 0, y = 0, w = 500, h = 470})
	Image_BuffList_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",50):SetImageType(10)
	local Image_BuffList_BG1 = LR.AppendUI("Image", hHandle_BuffList, "Image_BuffList_BG1", {x = 0, y = 30, w = 500, h = 440})
	Image_BuffList_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",74):SetImageType(10):SetAlpha(110)
	local Image_BuffList_Line1_0 = LR.AppendUI("Image", hHandle_BuffList, "Image_BuffList_Line1_0", {x = 3, y = 28, w = 500, h = 3})
	Image_BuffList_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",65):SetImageType(11):SetAlpha(115)
	local Text_BuffList_break2 = LR.AppendUI("Text", hHandle_BuffList, "Text_BuffList_break2", {w = 500, h = 30, x  = 0, y = 2, text = _L["Buff list"], font = 18})
	Text_BuffList_break2:SetHAlign(1):SetVAlign(1)
	--
	local hScroll2 = _C.UI("Scroll", frame, "ScrollBuffListBox", {x = 230, y = 120, w = 500, h = 430})

	--搜索列表
	local hHandle_Search = LR.AppendUI("Handle", frame, "hHandle_Search", {x = 738, y = 90, w = 200, h = 470})
	local Image_Search_BG = LR.AppendUI("Image", hHandle_Search, "Image_Search_BG", {x = 0, y = 0, w = 200, h = 470})
	Image_Search_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",50):SetImageType(10)
	local Image_Search_BG1 = LR.AppendUI("Image", hHandle_Search, "Image_Search_BG1", {x = 0, y = 30, w = 200, h = 440})
	Image_Search_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74):SetImageType(10):SetAlpha(110)
	local Image_Search_Line1_0 = LR.AppendUI("Image", hHandle_Search, "Image_Search_Line1_0", {x = 3, y = 28, w = 200, h = 3})
	Image_Search_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",65):SetImageType(11):SetAlpha(115)
	local Text_Search_break2 = LR.AppendUI("Text", hHandle_Search, "Text_Search_break2", {w = 200, h = 30, x  = 0, y = 2, text = _L["Search+History"], font = 18})
	Text_Search_break2:SetHAlign(1):SetVAlign(1)
	--
	local hScroll3 = _C.UI("Scroll", frame, "ScrollSearchBuffBox", {x = 740, y = 150, w = 200, h = 400})

	--搜索框
	local hEditBox_Search = LR.AppendUI("Edit", frame, "hEditBox_Search", {w = 187 ,h = 30, x = 744, y = 120, text = ""})
	hEditBox_Search:Enable(true)
	hEditBox_Search.OnMouseEnter = function()
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml  = GetFormatText(_L["Enter name or id"], 0, 255, 128, 0)
		OutputTip(szXml, 350, {x, y, w, h})
	end
	hEditBox_Search.OnMouseLeave = function()
		HideTip()
	end
	hEditBox_Search.OnChange = function(value)
		local searchText = value or ""
		searchText = string.gsub(searchText," ","")
		searchText = LR.Trim(searchText)
		LR_BuffManager_Panel.szSearchText = searchText
		_C.LoadSearchResultBox()
	end

	_UI["CheckBox_DungeonData"]:Check(true)
end

function _C.OpenPanel()
	local frame = Station.Lookup("Normal/LR_BuffManager_Panel")
	if not frame then
		_C.Init()
	else
		Wnd.CloseWindow(frame)
	end
end

function _C.IniDungeonMap()
	for k, v in pairs(LR_Team_Map_Sorted) do
		v.fold = true
	end
end

----BUFF分组列表展示
function _C.ChangeGroupUIShow(nType, szGroupName)
	local frame = Station.Lookup("Normal/LR_BuffManager_Panel")
	if not frame then
		return
	end
	local ScrollGroupBox = _UI["ScrollGroupBox"]
	local szKey = ""
	if LR_BuffManager_Panel.nShowType == "DungeonData" then
		szKey = sformat("hSGroup_%s", szGroupName)
		local hGroupDungeon = ScrollGroupBox:Lookup(szKey)
		if hGroupDungeon then
			local Text_Group_Name = hGroupDungeon:Lookup(sformat("Text_Group_Name_%s", szGroupName))
			if Text_Group_Name then
				LR_BuffManager.DungeonData[2].data[szGroupName] = LR_BuffManager.DungeonData[2].data[szGroupName] or {data = {}}
				Text_Group_Name:SetText(sformat("%s ( %d )", szGroupName, #LR_BuffManager.DungeonData[2].data[szGroupName].data))
			end
		end
	else
		szKey = sformat("hCGroup_%s", szGroupName)
		local hGroupDungeon = ScrollGroupBox:Lookup(szKey)
		if hGroupDungeon then
			local Text_Group_Name = hGroupDungeon:Lookup("Text_Group_Name")
			if Text_Group_Name then
				local data = nil
				for k, v in pairs(LR_BuffManager.CustomData[2].data) do
					if v.szGroupName == szGroupName then
						data = clone(v.data)
						break
					end
				end
				Text_Group_Name:SetText(sformat("%s ( %d )", szGroupName, #data))
			end
		end
	end
end

function _C.LoadGroupList()
	local frame = Station.Lookup("Normal/LR_BuffManager_Panel")
	if not frame then
		return
	end
	local ScrollGroupBox = _UI["ScrollGroupBox"]
	ScrollGroupBox:ClearHandle()
	if LR_BuffManager_Panel.nShowType == "DungeonData" then
		for k, v in pairs(LR_Team_Map_Sorted) do
			local Handle_Version = LR.AppendUI("Handle", ScrollGroupBox, sformat("hBGroup_%s", v.szVersionName), {x = 0, y = 0, w = 196, h = 40, eventid = 524596})
			local Image_Version_BG = LR.AppendUI("Image", Handle_Version, sformat("Image_Version_BG_%s", v.szVersionName), {x = 3, y = 0, w = 193, h = 40})
			Image_Version_BG:FromUITex("UI/Image/UICommon/CommonPanel2.uitex", 12):SetImageType(0)
			local Text_Version = LR.AppendUI("Text", Handle_Version, sformat("Text_Version_%s", v.szVersionName), {w = 150, h = 40, x  = 15, y = 2, text = v.szVersionName, font = 18})
			if not v.fold then
				_C.LoadDungeonGroupBox(v.data)
			end
			Handle_Version.OnClick = function()
				v.fold = not v.fold
				_C.LoadGroupList()
			end
			Handle_Version.OnEnter = function()
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				local tip = {}
				--Output(v)
				for k2, v2 in pairs(v.data) do
					if v2.level == 1 then
						tip[#tip + 1] = GetFormatImage("ui/image/uitga/desertstorm.UITex", 8, 24, 24)
					else
						tip[#tip + 1] = GetFormatImage("ui/image/uitga/desertstorm.UITex", 1, 24, 24)
					end
					tip[#tip + 1] = GetFormatText(sformat("%s\n", v2.szOtherName))
				end
				OutputTip(tconcat(tip), 320, {x, y, w, h})
			end
			Handle_Version.OnLeave = function()
				HideTip()
			end
		end
	else
		for k, v in pairs(LR_BuffManager.CustomData[2].data) do
			local hGroupCustom = LR.AppendUI("HoverHandle", ScrollGroupBox, sformat("hCGroup_%s", v.szGroupName), {x = 0, y = 0, w = 196, h = 40, eventid = 524596})
			local Image_Line = LR.AppendUI("Image", hGroupCustom, "Image_Line_BG", {x = 0, y = 0, w = 196, h = 40})
			Image_Line:FromUITex("ui\\Image\\UICommon\\CommonPanel.UITex", 48):SetImageType(10):SetAlpha(200)
			if k % 2 == 0 then
				Image_Line:SetAlpha(35)
			end

			--选择框
			local Image_Select = _C.UI("Image", hGroupCustom, sformat("Image_CGroupSelect_%s", v.szGroupName), {x = 2, y = 0, w = 190, h = 40})
			Image_Select:FromUITex("ui\\Image\\Common\\TempBox.UITex",6):SetImageType(10):SetAlpha(200):Hide()
			if LR_BuffManager_Panel.szGroupSelected == Image_Select:GetName() and LR_BuffManager_Panel.nShowType == "CustomData" then
				local Image_Select = _UI[sformat("Image_CGroupSelect_%s", v.szGroupName)]
				if Image_Select then
					Image_Select:Show()
				end
			end

			--允许框
			local Image_Enable = _C.UI("Image", hGroupCustom, sformat("Image_GroupEnable_%s", v.szGroupName), {x = 5, y = 2, w = 36, h = 36, eventid = 272})
			Image_Enable:SetImageType(10)
			if v.enable then
				--Image_Enable:FromIconID(6933)
				Image_Enable:FromUITex("ui/Image/GMPanel/gm2.UITex", 7)
			else
				--Image_Enable:FromIconID(6942)
				Image_Enable:FromUITex("ui/Image/GMPanel/gm2.UITex", 6)
			end

			--分组名称
			local Text_break2 = LR.AppendUI("Text", hGroupCustom, "Text_CustomGroup", {w = 150, h = 40, x  = 50, y = 2, text = v.szGroupName, font = 18})
			Text_break2:SetHAlign(0):SetVAlign(1):SetText(sformat("%s ( %d )", v.szGroupName, #v.data))

			--鼠标操作
			hGroupCustom.OnClick = function()
				if LR_BuffManager_Panel.szGroupSelected ~= "" then
					local Image_Select = _UI[sformat("Image_CGroupSelect_%s", v.szGroupName)]
					if Image_Select and Image_Select:IsValid() then
						Image_Select:Hide()
					end
				end
				LR_BuffManager_Panel.szGroupSelected = v.szGroupName
				local Image_Select = _UI[sformat("Image_CGroupSelect_%s", v.szGroupName)]
				if Image_Select and Image_Select:IsValid() then
					Image_Select:Show()
				end

				------刷新BuffList
				_C.LoadBuffListBox()
			end

			hGroupCustom.OnRClick = function()
				local fx, fy = this:GetAbsPos()
				local nW, nH = this:GetSize()
				local m = {}
				m[#m + 1] = { szOption = _L["Delete"], fnAction = function() LR_TeamBuffTool_Panel:delGroup(v.szGroupName) end,}
				PopupMenu(m, {fx, fy, nW, nH})
			end

			hGroupCustom.OnEnter = function()
				local tTip = {}
				if v.enable then
					tTip[#tTip + 1] = GetFormatText(sformat(_L["Group [%s] is enabled.\n"], v.szGroupName), 2, 34, 177, 76)
				else
					tTip[#tTip + 1] = GetFormatText(sformat(_L["Group [%s] is disabled.\n"], v.szGroupName), 2, 255, 0, 128)
				end
				tTip[#tTip + 1] = GetFormatText(_L["LClick image to change status.\n"], 2)
				tTip[#tTip + 1] = GetFormatText(_L["RClick to delete group.\n"], 2)

				local fx, fy = this:GetAbsPos()
				local nW, nH = this:GetSize()
				OutputTip(tconcat(tTip), 320, {fx, fy, nW, nH})
			end

			hGroupCustom.OnLeave = function()
				HideTip()
			end

			--使能框
			Image_Enable.OnClick = function()
				v.enable = not v.enable
				local Image_GroupEnable = _UI[sformat("Image_GroupEnable_%s", v.szGroupName)]
				if Image_GroupEnable and Image_GroupEnable:IsValid() then
					if v.enable then
						--Image_Enable:FromIconID(6933)
						Image_Enable:FromUITex("ui/Image/GMPanel/gm2.UITex", 7)
						LR.SysMsg(sformat(_L["Enable monitor group: %s\n"], v.szGroupName))
					else
						Image_Enable:FromUITex("ui/Image/GMPanel/gm2.UITex", 6)
						--Image_Enable:FromIconID(6942)
						LR.SysMsg(sformat(_L["Disable monitor group: %s\n"], v.szGroupName))
					end
				end
				--LR_TeamBuffTool_Panel:modifyGroup(v.szGroupName, v)
			end
		end
	end
	ScrollGroupBox:UpdateList()
end

function _C.LoadDungeonGroupBox(data)
	local frame = Station.Lookup("Normal/LR_BuffManager_Panel")
	if not frame then
		return
	end
	local ScrollGroupBox = _UI["ScrollGroupBox"]
	for k, v in pairs(data) do
		local hGroupDungeon = LR.AppendUI("HoverHandle", ScrollGroupBox, sformat("hSGroup_%s", v.szOtherName), {x = 0, y = 0, w = 196, h = 40, eventid = 524596})
		local Image_Line = LR.AppendUI("Image", hGroupDungeon, sformat("Image_Line_%s", v.szOtherName), {x = 0, y = 0, w = 196, h = 40})
		Image_Line:FromUITex("ui\\Image\\UICommon\\CommonPanel.UITex", 48):SetImageType(10):SetAlpha(200)
		if k % 2 == 0 then
			Image_Line:SetAlpha(35)
		end

		--选择框
		local Image_Select = _C.UI("Image", hGroupDungeon, sformat("Image_GroupSelect_%s", v.szOtherName), {x = 2, y = 0, w = 190, h = 40})
		Image_Select:FromUITex("ui\\Image\\Common\\TempBox.UITex",6):SetImageType(10):SetAlpha(200):Hide()
		if LR_BuffManager_Panel.szGroupSelected == Image_Select:GetName() then
			local Image_Select = _UI[sformat("Image_GroupSelect_%s", v.szOtherName)]
			if Image_Select then
				Image_Select:Show()
			end
		end

		local Image_Group_Level = LR.AppendUI("Image", hGroupDungeon, sformat("Image_Group_Level_%s", v.szOtherName), {x = 5, y = 2, w = 36, h = 36})
		if v.level == 1 then
			Image_Group_Level:FromUITex("ui/image/uitga/desertstorm.UITex", 8):SetImageType(0):SetAlpha(200)
		else
			Image_Group_Level:FromUITex("ui/image/uitga/desertstorm.UITex", 1):SetImageType(0):SetAlpha(200)
		end
		local Text_Group_Name = LR.AppendUI("Text", hGroupDungeon, sformat("Text_Group_Name_%s", v.szOtherName), {w = 150, h = 40, x  = 50, y = 2, text = v.szOtherName, font = 18})
		--
		LR_BuffManager.DungeonData[2].data[v.szOtherName] = LR_BuffManager.DungeonData[2].data[v.szOtherName] or {data = {}}
		Text_Group_Name:SetText(sformat("%s ( %d )", v.szOtherName, #LR_BuffManager.DungeonData[2].data[v.szOtherName].data))
		hGroupDungeon.OnEnter = function()
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local tip = {}
			for k2, v2 in pairs(v.dwMapID) do
				if IsCtrlKeyDown() then
					tip[#tip + 1] = GetFormatText(sformat("%s#%d\n", Table_GetMapName(v2), v2))
				else
					tip[#tip + 1] = GetFormatText(sformat("%s\n", LR.MapType[v2].szName))
				end
			end
			OutputTip(tconcat(tip), 320, {x, y, w, h})

		end
		hGroupDungeon.OnLeave = function()
			HideTip()
		end
		hGroupDungeon.OnClick = function()
			if LR_BuffManager_Panel.szGroupSelected then
				local Image_Select = _UI[sformat("Image_GroupSelect_%s", LR_BuffManager_Panel.szGroupSelected)]
				if Image_Select then
					Image_Select:Hide()
				end
			end

			LR_BuffManager_Panel.szGroupSelected = v.szOtherName --sformat("Image_GroupSelect_%s", v.szOtherName)
			local Image_Select = _UI[sformat("Image_GroupSelect_%s", LR_BuffManager_Panel.szGroupSelected)]
			if Image_Select then
				Image_Select:Show()
			end

			if LR_TeamBuffTool_Panel.bMapData then
				--self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
				--self:LoadSearchResultBox()
			end
			------刷新BuffList
			_C.LoadBuffListBox()
		end
	end
end

--BUFF显示
function _C.LoadBuffListBox()
	local frame = Station.Lookup("Normal/LR_BuffManager_Panel")
	if not frame then
		return
	end
	local ScrollBuffListBox = _UI["ScrollBuffListBox"]
	ScrollBuffListBox:ClearHandle()
	if LR_BuffManager_Panel.nShowType == "DungeonData" then
		local buff_data = LR_BuffManager.DungeonData[2].data[LR_BuffManager_Panel.szGroupSelected].data
		for k, buff in pairs(buff_data) do
			_C.DrawOneBuffBox("DungeonData", LR_BuffManager_Panel.szGroupSelected, buff)
		end
	elseif LR_BuffManager_Panel.nShowType == "CustomData" then
		local buff_data = nil
		for k, v in pairs(LR_BuffManager.Custom[2].data) do


		end

		LR_BuffManager.DungeonData[2].data[LR_BuffManager_Panel.szGroupSelected].data





	end

	ScrollBuffListBox:UpdateList()
end

function _C.DrawOneBuffBox(nType, szGroupName, buff, bDel)
	local frame = Station.Lookup("Normal/LR_BuffManager_Panel")
	if not frame then
		return
	end
	local ScrollBuffListBox = _UI["ScrollBuffListBox"]
	local szKey = sformat("%s_%s_%d_%d", tostring(GetStringCRC(nType)), tostring(GetStringCRC(szGroupName)), buff.dwID, buff.nLevel)
	local hBuffList = _UI[sformat("hBuff_%s", szKey)]
	if bDel then
		if hBuffList and hBuffList:IsValid() then
			hBuffList:Destroy()
			ScrollBuffListBox:UpdateList()
			return
		end
	else
		if not hBuffList or not hBuffList:IsValid() then
			hBuffList = _C.UI("Handle", ScrollBuffListBox, sformat("hBuff_%s", szKey), {x = 0, y = 0, w = 160, h = 100, eventid = 304})
			hBuffList:SetIndex(0)
		end
	end
	--local hBuffList = self:Append("Handle", ScrollBuffListBox, sformat("hBuff_%s", szKey), {x = 0, y = 0, w = 160, h = 100, eventid = 304})
	if hBuffList then
		hBuffList:Clear()
		-----背景条
		local Image_Line = LR.AppendUI("Image", hBuffList, "Image_BuffListLine" .. szKey, {x = 0, y = 0, w = 160, h = 100})
		Image_Line:FromUITex("ui\\Image\\UICommon\\CommonPanel.UITex", 48):SetImageType(10):SetAlpha(200)

		local Shadow_Special = LR.AppendUI("Shadow", hBuffList, "Shadow_Special" .. szKey, {x = 5, y = 5, w = 150, h = 90})

		if buff.bSpecialBuff and next(buff.col) ~= nil and buff.bShowMask then
			Shadow_Special:SetColorRGB(unpack(buff.col))
			Shadow_Special:Show()
		else
			Shadow_Special:Hide()
		end
		--醒目
		local TextBuffSpecial = LR.AppendUI("Text", hBuffList, "TextBuffName".. szKey , {w = 40, h = 25, x  = 5, y = 25, text = _L["Special"], font = 15})
		TextBuffSpecial:SetHAlign(0):SetVAlign(1)
		if buff.bSpecialBuff then
			TextBuffSpecial:Show()
		else
			TextBuffSpecial:Hide()
		end

		--层
		local TextBuffStack = LR.AppendUI("Text", hBuffList, "TextBuffStack".. szKey, {w = 40, h = 25, x  = 5, y = 50, text = sformat(_L["Stack:%d"], buff.nMonitorStack), font = 15})
		TextBuffStack:SetHAlign(0):SetVAlign(1)
		if buff.nMonitorStack > 1 then
			TextBuffStack:Show()
		else
			TextBuffStack:Hide()
		end

		--选择框
		local Image_Select = LR.AppendUI("Image", hBuffList, sformat("Image_BuffListSelect_%s", szKey), {x = 2, y = 0, w = 160, h = 100})
		Image_Select:FromUITex("ui\\Image\\Common\\TempBox.UITex",6):SetImageType(10):SetAlpha(200):Hide()

		--Buff框
		local Image_BuffBox = LR.AppendUI("Image", hBuffList, "Image_BuffListBox" .. szKey, {x = 50, y = 8, w = 60, h = 60})
		Image_BuffBox:FromUITex("ui\\Image\\Common\\TempBox.UITex",34):SetImageType(10):SetAlpha(255):Show()

		--Buff框
		local Image_BuffIcon = LR.AppendUI("Image", hBuffList, "Image_BuffListIcon" .. szKey, {x = 50, y = 8, w = 60, h = 60})
		if buff.nIconID > 0 then
			Image_BuffIcon:FromIconID(buff.nIconID)
		else
			Image_BuffIcon:FromIconID(Table_GetBuffIconID(buff.dwID, buff.nLevel))
		end
		Image_BuffIcon:SetImageType(10):SetAlpha(255):Show()

		--特效Handle
		local Handle_Effect = LR.AppendUI("Handle", hBuffList, sformat("Handle_Effect_%s", szKey), {x = 50, y = 8, w = 60, h = 60, eventid = 0})
		local function Add_Effect()
			if Handle_Effect then
				local handle = Handle_Effect
				handle:Clear()
				local nEffectsType = buff.nEffectsType
				if nEffectsType > 0 then
					handle:AppendItemFromIni(sformat("%s\\UI\\PSS.ini", AddonPath), sformat("Handle_SpecialBuff%d", nEffectsType), "Handle_SpecialBuff")
					handle:Lookup("Handle_SpecialBuff"):Lookup(sformat("Handle_SpecialBuff%d_Fixed", nEffectsType)):SetName("Handle_SpecialBuff_Fixed")
					handle:Lookup("Handle_SpecialBuff"):Lookup(sformat("SFX_SpecialBuff%d", nEffectsType)):SetName("SFX_SpecialBuff")
					--设置大小
					local w, h = handle:Lookup("Handle_SpecialBuff"):Lookup("Handle_SpecialBuff_Fixed"):GetSize()	--SFX原始大小
					local width, height = 60, 60
					local fSFXX, fSFXY = width / w, height / h
					handle:SetSize(width, height)
					handle:Lookup("Handle_SpecialBuff"):SetSize(width, height)
					handle:Lookup("Handle_SpecialBuff"):Lookup("SFX_SpecialBuff"):Get3DModel():SetScaling(fSFXX, fSFXY, fSFXX)
					handle:Lookup("Handle_SpecialBuff"):Lookup("SFX_SpecialBuff"):SetRelPos(width / 2, height / 2)
					handle:Lookup("Handle_SpecialBuff"):FormatAllItemPos()
					handle:FormatAllItemPos()
					handle:Show()
				end
			end
		end
		Add_Effect()

		--BUFF名字
		local TextBuffName = LR.AppendUI("Text", hBuffList, "TextBuffName".. szKey .."_2", {w = 160, h = 30, x  = 0, y = 70, text = Table_GetBuffName(buff.dwID, buff.nLevel), font = 18})
		TextBuffName:SetHAlign(1):SetVAlign(1)

		--BUFF名字
		local TextBuffName = LR.AppendUI("Text", hBuffList, "TextBuffName".. szKey .."_2", {w = 40, h = 30, x  = 5, y = 0, text = _L["Self"], font = 15})
		TextBuffName:SetHAlign(0)
		TextBuffName:SetVAlign(1)
		if buff.bOnlySelf then
			TextBuffName:Show()
		else
			TextBuffName:Hide()
		end

		local Image_Disable = LR.AppendUI("Image", hBuffList, "Image_Disable" .. szKey, {x = 138, y = 4, w = 18, h = 18})
		Image_Disable:FromUITex("ui/image/uitga/voice.uitex", 32)

		if buff.enable then
			Image_Disable:Hide()
			Image_BuffIcon:SetAlpha(255)
		else
			Image_Disable:Show()
			Image_BuffIcon:SetAlpha(60)
		end

		--鼠标操作
		hBuffList.OnClick = function()
			LR_BuffConfig_Panel.OpenPanel(LR_BuffManager_Panel.nShowType, szGroupName, buff)
		end

		hBuffList.OnRClick = function()
			local fx, fy = this:GetAbsPos()
			local nW, nH = this:GetSize()
			local m = {}
			m[#m + 1] = {szOption = _L["Delete"], fnAction = function() _C.DelBuff(nType, szGroupName, buff) end,}

			PopupMenu(m, {fx, fy, nW, nH})
		end

		hBuffList.OnEnter = function()
			local fx, fy = this:GetAbsPos()
			local nW, nH = this:GetSize()
			LR.OutputBuffTip(buff.dwID, buff.nLevel, {fx, fy, nW, nH})
		end

		hBuffList.OnLeave = function()
			HideTip()
		end
	end
end

---BUFF搜索框/历史显示
function _C.GetResultList()
	local result = {}
	local szSearchText = LR_BuffManager_Panel.szSearchText
	local mem = {}
	for k, v in pairs(_Grab.TempCache) do
		local tLine = clone(v)
		tLine.nType = "mem"
		tinsert(mem, tLine)
	end

	if szSearchText ~= "" then
		local RowCount = g_tTable.Buff:GetRowCount()
		for i = 3, RowCount, 1 do
			local bAdd = false
			local tLine = g_tTable.Buff:GetRow(i)
			if type(tonumber(szSearchText)) == "number" then
				if tLine.dwBuffID == tonumber(szSearchText) then
					bAdd = true
				end
			else
				local _start, _end = string.find(tLine.szName, szSearchText)
				if _start then
					bAdd = true
				end
			end
			if bAdd then
				tinsert(result, {dwID = tLine.dwBuffID, nLevel = tLine.nLevel or 1, nType = "database"})
			end
		end

		if #result > 0 then
			tinsert(result, 1, {bDevide = true, nType = "database"})
			tinsert(result, {bDevide = true, nType = "mem"})
		end

		for k, v in pairs(_Grab.TempCache) do
			local bAdd = false
			if type(tonumber(szSearchText)) == "number" then
				if v.dwID == tonumber(szSearchText) then
					bAdd = true
				end
			else
				local _start, _end = string.find(Table_GetBuffName(v.dwID, v.nLevel), szSearchText)
				if _start then
					bAdd = true
				end
				if bAdd then
					tinsert(result, v)
				end
			end
		end
		return result
	end
	return mem
end

function _C.LoadSearchResultBox()
	local frame = Station.Lookup("Normal/LR_BuffManager_Panel")
	if not frame then
		return
	end
	local ScrollSearchBuffBox = _UI["ScrollSearchBuffBox"]
	ScrollSearchBuffBox:ClearHandle()
	local szSearchText = LR_BuffManager_Panel.szSearchText
	local data = _C.GetResultList()
	for i = 1 + (LR_BuffManager_Panel.ResultPageNumCurrent - 1) * 10, 1 + (LR_BuffManager_Panel.ResultPageNumCurrent - 1) * 10 + LR_BuffManager_Panel.ResultPerPageNum, 1 do
		if data[i] then
			_C.LoadOneSearchResultBox(data[i])
		end
	end
	ScrollSearchBuffBox:UpdateList()
end

function _C.LoadOneSearchResultBox(buff)
	local frame = Station.Lookup("Normal/LR_BuffManager_Panel")
	if not frame then
		return
	end
	local ScrollSearchBuffBox = _UI["ScrollSearchBuffBox"]
	if buff.bDevide then


	else
		local Handle_Buff = ScrollSearchBuffBox:AppendItemFromIni(sformat("%s\\UI\\Handle2.ini", AddonPath), "Handle_Buff", "Handle_Buff")
		local Image_BG = Handle_Buff:Lookup("Image_BG")
		local Text_Name = Handle_Buff:Lookup("Text_Name")
		local Image_Icon = Handle_Buff:Lookup("Image_Icon")
		local m = Handle_Buff:GetIndex()
		if m % 2 == 1 then
			Image_BG:SetAlpha(150)
		else
			Image_BG:SetAlpha(255)
		end
		Image_Icon:FromIconID(Table_GetBuffIconID(buff.dwID, buff.nLevel) or 13)
		Text_Name:SetText(sformat("%s(#%d)", Table_GetBuffName(buff.dwID, buff.nLevel), buff.dwID ))
		if buff.bDelete then
			Text_Name:SetFontScheme(17)
		elseif buff.bFresh then
			Text_Name:SetFontScheme(16)
		end

--[[		Handle_Buff.OnItemRButtonClick = function()
			if LR_TeamBuffTool_Panel.bMapData then
				if LR_TeamBuffTool_Panel.LoadType == "by dungeon" then
					if LR_TeamBuffTool_Panel.szChooseGroupName and LR_TeamBuffTool_Panel.szChooseGroupName ~= "" then
						local menu = {}
						menu[#menu + 1] = {szOption = _L["delete"], fnAction = function()
							local szKey = sformat("%d_%d", buff.dwID, buff.nLevel)
							BUFF_CACHE_MAP_TEMP[szKey] = nil
							local path = sformat("%s\\BUFF_CACHE\\%s.dat", SaveDataPath, LR_TeamBuffTool_Panel.szChooseGroupName)
							LR.SaveLUAData(path, BUFF_CACHE_MAP_TEMP)
							self:Destroy(hBuffSearch)
							hWin:UpdateList()
						end}
						PopupMenu(menu)
					end
				end
			else
				if LR_TeamBuffTool_Panel.bShowMapBuffCache then
					local menu = {}
					menu[#menu + 1] = {szOption = _L["delete"], fnAction = function()
						local szKey = sformat("%d_%d", buff.dwID, buff.nLevel)
						BUFF_CACHE_MAP[szKey] = nil
						LR_TeamBuffTool.SaveBuffCache(true)
						self:Destroy(hBuffSearch)
						hWin:UpdateList()
					end}
					PopupMenu(menu)
				end
			end
		end]]

		Handle_Buff.OnItemMouseEnter = function()
			local fx, fy = Handle_Buff:GetAbsPos()
			local nW, nH = Handle_Buff:GetSize()
			if IsCtrlKeyDown() then
				local tip = {}
				tip[#tip + 1] = LR.GetFormatImageByID(Table_GetBuffIconID(buff.dwID, buff.nLevel), 30, 30)
				tip[#tip + 1] = GetFormatText(sformat("%s\n", Table_GetBuffName(buff.dwID, buff.nLevel)))
				if buff.target_type == TARGET.NPC then
					tip[#tip + 1] = GetFormatText(_L["NPC self buff\n"], 8)
				end
				tip[#tip + 1] = GetFormatText(sformat(_L["ID: %d\n"], buff.dwID))
				tip[#tip + 1] = GetFormatText(sformat(_L["Level: %d\n"], buff.nLevel))
				tip[#tip + 1] = GetFormatText(sformat(_L["IconID: %d\n"], Table_GetBuffIconID(buff.dwID, buff.nLevel)))

				if buff.nType == "mem" then
					if mceil(buff.nTotalFrame  / 16.0) <= 120 then
						tip[#tip + 1] = GetFormatText(sformat(_L["Total time:%fs\n"], mceil(buff.nTotalFrame / 16.0)))
					end

					tip[#tip + 1] = GetFormatText(_L["From :\n"])
					for k6, v6 in pairs(buff.caster) do
						if v6.nType == TARGET.NPC then
							tip[#tip + 1] = GetFormatText(sformat("%s(#%d) %s\n", v6.szName, v6.dwTemplateID, Table_GetMapName(v6.dwMapID)))
						else
							tip[#tip + 1] = GetFormatText(sformat(_L["%s (Player) %s\n"], v6.szName, Table_GetMapName(v6.dwMapID)))
						end
					end
				end
				OutputTip(tconcat(tip), 600, {fx, fy, nW, nH})
			else
				LR.OutputBuffTip(buff.dwID, buff.nLevel or 1, {fx, fy, nW, nH})
			end
		end

		Handle_Buff.OnItemMouseLeave = function()
			HideTip()
		end

		Handle_Buff.OnItemLButtonDrag = function()
			LR_BuffManager_Panel.bDraged = true
			LR_BuffManager_Panel.bAddBuff = buff
			_C.OpenDragBuffPanel(buff)
		end

		Handle_Buff.OnItemLButtonDragEnd = function()
			_C.CloseDragBuffPanel()
			if LR_BuffManager_Panel.bAdd then
				local nType = LR_BuffManager_Panel.nShowType
				local szGroupName = LR_BuffManager_Panel.szGroupSelected
				Output(nType, szGroupName, buff)
				if szGroupName ~= "" then
					_C.AddBuff(nType, szGroupName, buff)

				end
			end
			LR_BuffManager_Panel.bDraged = false
			LR_BuffManager_Panel.bAddBuff = nil
		end

	end
end


----------------------
---拖动BUFF
----------------------
function _C.OpenDragBuffPanel(buff)
	local hFrame = Wnd.OpenWindow(sformat("%s\\UI\\BuffBox.ini", AddonPath), "LR_BuffBox")
	if not hFrame then
		return
	end

	local nX, nY = Cursor.GetPos()
	hFrame:SetAbsPos(nX + 5, nY + 5)
	hFrame:StartMoving()

	local hHandle = hFrame:Lookup("","")
	local Image_Buff = hHandle:Lookup("Image_Buff")
	Image_Buff:FromIconID(Table_GetBuffIconID(buff.dwID, buff.nLevel))
end

function _C.CloseDragBuffPanel()
	local hFrame = Station.Lookup("Normal/LR_BuffBox")
	if hFrame then
		hFrame:EndMoving()
		Wnd.CloseWindow(hFrame)
	end
end
----------------------
---添加删除BUFF
----------------------
function _C.IsGroupHasBuff(nType, szGroupName, BUFF)
	local nType = nType == "DungeonData" and "DungeonData" or "CustomData"
	local buff = BUFF
	if nType == "DungeonData" then
		LR_BuffManager.DungeonData[2].data = LR_BuffManager.DungeonData[2].data or {}
		LR_BuffManager.DungeonData[2].data[szGroupName] = LR_BuffManager.DungeonData[2].data[szGroupName] or {}
		for k, v in pairs(LR_BuffManager.DungeonData[2].data[szGroupName].data) do
			if v.dwID == buff.dwID and v.nLevel == buff.nLevel then
				return true, k
			end
		end
	elseif nType == "CustomData" then
		LR_BuffManager.CustomData[2].data = LR_BuffManager.CustomData[2].data or {}
		LR_BuffManager.CustomData[2].data[szGroupName] = LR_BuffManager.CustomData[2].data[szGroupName] or {}
		for k, v in pairs(LR_BuffManager.CustomData[2].data[szGroupName].data) do
			if v.dwID == buff.dwID and v.nLevel == buff.nLevel then
				return true, k
			end
		end
	end
	return false, nil
end

function _C.AddBuff(nType, szGroupName, BUFF)
	local nType = nType == "DungeonData" and "DungeonData" or "CustomData"
	if _C.IsGroupHasBuff(nType, szGroupName, BUFF) then
		local msg =
		{	szMessage = GetFormatText(sformat(_L["This group [%s] already has buff [%s]."], szGroupName, Table_GetBuffName(buff.dwID, buff.nLevel))),
			bRichText = true,
			szName = "AddBUFF",
			{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() end,},
		}
		MessageBox(msg)
	else
		local buff = _Manager.FullData(BUFF, DEFAULT_BUFF)
		if nType == "DungeonData" then
			tinsert(LR_BuffManager.DungeonData[2].data[szGroupName].data, buff)
			_Manager.SaveData("DungeonData")
		elseif nType == "CustomData" then
			tinsert(LR_BuffManager.CustomData[2].data[szGroupName].data, buff)
			_Manager.SaveData("CustomData")
		end
		_C.DrawOneBuffBox(nType, szGroupName, buff)
		_C.ChangeGroupUIShow(nType, szGroupName)
		LR.SysMsg("success\n")
	end
end

function _C.DelBuff(nType, szGroupName, BUFF)
	local nType = nType == "DungeonData" and "DungeonData" or "CustomData"
	local bHasBuff, key = _C.IsGroupHasBuff(nType, szGroupName, BUFF)
	if bHasBuff then
		if nType == "DungeonData" then
			tremove(LR_BuffManager.DungeonData[2].data[szGroupName].data, key)
			_Manager.SaveData("DungeonData")
		elseif nType == "CustomData" then
			tremove(LR_BuffManager.CustomData[2].data[szGroupName].data, key)
			_Manager.SaveData("CustomData")
		end
		_C.DrawOneBuffBox(nType, szGroupName, BUFF, true)
		_C.ChangeGroupUIShow(nType, szGroupName)
	else
		local msg =
		{	szMessage = GetFormatText(sformat(_L["This group [%s] has no buff [%s]."], szGroupName, Table_GetBuffName(buff.dwID, buff.nLevel))),
			bRichText = true,
			szName = "AddBUFF",
			{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() end,},
		}
		MessageBox(msg)
	end
end

function _C.ModifyBuff(nType, szGroupName, BUFF)
	local nType = nType == "DungeonData" and "DungeonData" or "CustomData"
	local bHasBuff, key = _C.IsGroupHasBuff(nType, szGroupName, BUFF)
	if bHasBuff then
		local buff = _Manager.FullData(BUFF, DEFAULT_BUFF)
		if nType == "DungeonData" then
			LR_BuffManager.DungeonData[2].data[szGroupName].data[key] = clone(buff)
			_Manager.SaveData("DungeonData")
		elseif nType == "CustomData" then
			LR_BuffManager.CustomData[2].data[szGroupName].data[key] = clone(buff)
			_Manager.SaveData("CustomData")
		end
		_C.DrawOneBuffBox(nType, szGroupName, buff)
	else
		_C.AddBuff(nType, szGroupName, BUFF)
	end
end





LR_BuffManager_Panel.OpenPanel = _C.OpenPanel

--[[
LR_BuffManager_Panel.OpenPanel()
]]



----------------------------------------------------------------
----BUFF设置面板
----------------------------------------------------------------
LR_BuffConfig_Base = class()
function LR_BuffConfig_Base.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")

	this:Lookup("Btn_Close").OnLButtonClick = function()
		Wnd.CloseWindow(this:GetParent())
	end

	LR_BuffConfig_Base.UpdateAnchor(this)
end

function LR_BuffConfig_Base.OnEvent(szEvent)
	if szEvent == "UI_SCALED" then
		LR_BuffConfig_Base.UpdateAnchor(this)
	end
end

function LR_BuffConfig_Base.OnFrameDragEnd()
	---
end

function LR_BuffConfig_Base.OnFrameDestroy()
	---
end

----------------------------------------------------------------
----BUFF设置面板
----------------------------------------------------------------
LR_BuffConfig_Panel = {}
local _UIC = {}
local _CC = {}


function _CC.Init(nType, szGroupName, BUFF)
	local buff = _Manager.FullData(szGroupName, BUFF)
	local szKey = sformat("%s_%d_%d", tostring(GetStringCRC(szGroupName)), buff.dwID, buff.nLevel)
	local frame = LR.AppendUI("Frame", sformat("LR_BuffConfig_%s", szKey), {title = sformat("%s.Lv%d (%s)", Table_GetBuffName(buff.dwID, buff.nLevel), buff.nLevel, szGroupName ) , style = "DialogPanel"})
	local Image_BG1 = LR.AppendUI("Image", frame, "Image_All_BG", {x = 55, y = 40, w = 530, h = 440})
	Image_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74):SetImageType(10):SetAlpha(120)

	_UIC[szKey] = {}
	local Image_Buff_Icon = LR.AppendUI("Image", frame, "Image_Buff_Icon", {w = 50, h = 50, x = 300, y = 50, eventid = 272})
	Image_Buff_Icon:FromIconID(Table_GetBuffIconID(buff.dwID, buff.nLevel))
	if buff.nIconID > 0 then
		Image_Buff_Icon:FromIconID(buff.nIconID)
	end
	Image_Buff_Icon.OnEnter = function()
		local fx, fy = this:GetAbsPos()
		local nW, nH = this:GetSize()
		LR.OutputBuffTip(buff.dwID, buff.nLevel, {fx, fy, nW, nH})
	end
	Image_Buff_Icon.OnLeave = function()
		HideTip()
	end
	Image_Buff_Icon.OnClick = function()
		GetUserInput(_L["Enter icon id"], function(szText)
			local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
			if szText ~=  "" then
				if type(tonumber(szText)) == "number" then
					buff.nIconID = tonumber(szText)
					if _UIC[szKey]["Image_Buff_Icon"] then
						if buff.nIconID > 0 then
							_UIC[szKey]["Image_Buff_Icon"]:FromIconID(buff.nIconID)
						else
							_UIC[szKey]["Image_Buff_Icon"]:FromIconID(Table_GetBuffIconID(buff.dwID, buff.nLevel))
						end
					end
					_C.ModifyBuff(nType, szGroupName, buff)
					_C.DrawOneBuffBox(nType, szGroupName, buff)
				end
			end
		end, nil, nil, nil, buff.nIconID > 0 and buff.nIconID)
	end
	_UIC[szKey]["Image_Buff_Icon"] = Image_Buff_Icon

	local function Add_Effect()
		if _UIC[szKey]["Handle_Effect"] then
			local handle = _UIC[szKey]["Handle_Effect"]
			handle:Clear()
			local nEffectsType = buff.nEffectsType
			if nEffectsType > 0 then
				handle:AppendItemFromIni(sformat("%s\\UI\\PSS.ini", AddonPath), sformat("Handle_SpecialBuff%d", nEffectsType), "Handle_SpecialBuff")
				handle:Lookup("Handle_SpecialBuff"):Lookup(sformat("Handle_SpecialBuff%d_Fixed", nEffectsType)):SetName("Handle_SpecialBuff_Fixed")
				handle:Lookup("Handle_SpecialBuff"):Lookup(sformat("SFX_SpecialBuff%d", nEffectsType)):SetName("SFX_SpecialBuff")
				--设置大小
				local w, h = handle:Lookup("Handle_SpecialBuff"):Lookup("Handle_SpecialBuff_Fixed"):GetSize()	--SFX原始大小
				local width, height = 50, 50
				local fSFXX, fSFXY = width / w, height / h
				handle:SetSize(width, height)
				handle:Lookup("Handle_SpecialBuff"):SetSize(width, height)
				handle:Lookup("Handle_SpecialBuff"):Lookup("SFX_SpecialBuff"):Get3DModel():SetScaling(fSFXX, fSFXY, fSFXX)
				handle:Lookup("Handle_SpecialBuff"):Lookup("SFX_SpecialBuff"):SetRelPos(width / 2, height / 2)
				handle:Lookup("Handle_SpecialBuff"):FormatAllItemPos()
				handle:FormatAllItemPos()
				handle:Show()
			end
		end
	end

	local Handle_Effect = LR.AppendUI("Handle", frame, "Handle_Effect", {w= 50, h = 50, x = 300, y = 50, eventid = 0})
	_UIC[szKey]["Handle_Effect"] = Handle_Effect
	Add_Effect()

	local CheckBox_Enable = LR.AppendUI("CheckBox", frame, "CheckBox_Enable", {x = 70, y = 50, text = _L["Enable"]})
	CheckBox_Enable:Enable(true)
	CheckBox_Enable:Check(buff.enable)
	CheckBox_Enable.OnCheck = function(arg0)
		buff.enable = arg0
		for k, v in pairs(_UIC[szKey]) do
			if v.Enable and k ~= "CheckBox_Enable" then
				v:Enable(arg0)
			end
		end

		_C.ModifyBuff(nType, szGroupName, buff)
		_C.DrawOneBuffBox(nType, szGroupName, buff)
	end
	_UIC[szKey]["CheckBox_Enable"] = CheckBox_Enable

	local ComboBox_Effect = LR.AppendUI("ComboBox", frame, "ComboBox_Effect", {x = 360, y = 76, w = 120, text = _L["Effect choose"]})
	ComboBox_Effect:Enable(true)
	ComboBox_Effect.OnClick = function(m)
		m[#m + 1] = {szOption = _L["No effect"], bCheck = true, bMCheck = true, bChecked = function() return buff.nEffectsType == 0 end,
			fnAction = function()
				buff.nEffectsType = 0
				_C.ModifyBuff(nType, szGroupName, buff)
				_C.DrawOneBuffBox(nType, szGroupName, buff)
				Add_Effect()
			end,
		}
		for i = 1, 8, 1 do
			m[#m + 1] = {szOption = sformat(_L["Effect type %d"], i), bCheck = true, bMCheck = true, bChecked = function() return buff.nEffectsType == i end,
				fnAction = function()
					buff.nEffectsType = i
					_C.ModifyBuff(nType, szGroupName, buff)
					_C.DrawOneBuffBox(nType, szGroupName, buff)
					Add_Effect()
				end,
			}
		end
		PopupMenu(m)
	end
	_UIC[szKey]["CheckBox_Enable"] = CheckBox_Enable

	local CheckBox_Not_By_Level = LR.AppendUI("CheckBox", frame, "CheckBox_Not_By_Level", {x = 100, y = 120, text = _L["Not by level"]})
	CheckBox_Not_By_Level:Enable(buff.enable)
	CheckBox_Not_By_Level:Check(buff.nMonitorLevel == 0)
	CheckBox_Not_By_Level.OnCheck = function(arg0)
		if arg0 then
			buff.nMonitorLevel = 0
		else
			buff.nMonitorLevel = buff.nLevel
		end
		_C.ModifyBuff(nType, szGroupName, buff)
		_C.DrawOneBuffBox(nType, szGroupName, buff)
	end
	_UIC[szKey]["CheckBox_Not_By_Level"] = CheckBox_Not_By_Level

	LR.AppendUI("Text", frame, "Text_By_Stacknum", {x = 250, y = 120, text = _L["By stacknum"]})
	local Edit_By_Stacknum = LR.AppendUI("Edit", frame, "Edit_By_Stacknum", {w = 40, h = 24, x = 330, y = 120, text = buff.nMonitorStack})
	Edit_By_Stacknum:Enable(buff.enable)
	Edit_By_Stacknum.OnChange = function(arg0)
		local szText = LR.Trim(arg0)
		if type(tonumber(szText)) == "number" then
			buff.nMonitorStack = tonumber(szText)
		end

		_C.ModifyBuff(nType, szGroupName, buff)
		_C.DrawOneBuffBox(nType, szGroupName, buff)
	end
	_UIC[szKey]["Edit_By_Stacknum"] = Edit_By_Stacknum

	--仅监控来自于我的BUFF
	local CheckBox_Only_From_Myself = LR.AppendUI("CheckBox", frame, "CheckBox_Only_From_Myself", {x = 100, y = 150, text = _L["Only from myself"]})
	CheckBox_Only_From_Myself:Enable(buff.enable)
	CheckBox_Only_From_Myself:Check(buff.bOnlySelf)
	CheckBox_Only_From_Myself.OnCheck = function(arg0)
		buff.bOnlySelf = arg0

		_C.ModifyBuff(nType, szGroupName, buff)
		_C.DrawOneBuffBox(nType, szGroupName, buff)
	end
	_UIC[szKey]["CheckBox_Only_From_Myself"] = CheckBox_Only_From_Myself

	--仅监控我的BUFF
	local CheckBox_Only_Monitor_Self = LR.AppendUI("CheckBox", frame, "CheckBox_Only_Monitor_Self", {x = 100, y = 180, text = _L["Only monitor self"]})
	CheckBox_Only_Monitor_Self:Enable(buff.enable)
	CheckBox_Only_Monitor_Self:Check(buff.bOnlyMonitorSelf)
	CheckBox_Only_Monitor_Self.OnCheck = function(arg0)
		buff.bOnlyMonitorSelf = arg0

		_C.ModifyBuff(nType, szGroupName, buff)
		_C.DrawOneBuffBox(nType, szGroupName, buff)
	end
	_UIC[szKey]["CheckBox_Only_Monitor_Self"] = CheckBox_Only_Monitor_Self

	local CheckBox_Striking_Display = LR.AppendUI("CheckBox", frame, "CheckBox_Striking_Display", {x = 100, y = 220, text = _L["Striking display"]})
	CheckBox_Striking_Display:Enable(buff.enable)
	CheckBox_Striking_Display:Check(buff.bSpecialBuff)
	CheckBox_Striking_Display.OnCheck = function(arg0)
		buff.bSpecialBuff = arg0
		local group = {"CheckBox_EnableMask", "CheckBox_UnderStack"}
		for k, v in pairs(group) do
			if _UIC[szKey][v] then
				_UIC[szKey][v]:Enable(arg0)
			end
		end

		_C.ModifyBuff(nType, szGroupName, buff)
		_C.DrawOneBuffBox(nType, szGroupName, buff)
	end
	_UIC[szKey]["CheckBox_Striking_Display"] = CheckBox_Striking_Display

	local CheckBox_EnableMask = LR.AppendUI("CheckBox", frame, "CheckBox_EnableMask", {x = 100, y = 250, text = _L["Enable color mask"]})
	CheckBox_EnableMask:Enable(buff.enable and buff.bSpecialBuff)
	CheckBox_EnableMask:Check(buff.bShowMask)
	CheckBox_EnableMask.OnCheck = function(arg0)
		buff.bShowMask = arg0

		_C.ModifyBuff(nType, szGroupName, buff)
		_C.DrawOneBuffBox(nType, szGroupName, buff)
	end
	_UIC[szKey]["CheckBox_EnableMask"] = CheckBox_EnableMask

	local Shadow_Striking_Display = LR.AppendUI("ColorBox", frame, "Shadow_Striking_Display", {x = 220, y = 255, w = 20, h = 20, eventid = 272})
	if next(buff.col) ~= nil then
		Shadow_Striking_Display:SetColor(unpack(buff.col))
	else
		Shadow_Striking_Display:SetColor(255, 255, 255)
	end
	Shadow_Striking_Display.OnChange = function(rgb)
		buff.col = rgb

		_C.ModifyBuff(nType, szGroupName, buff)
		_C.DrawOneBuffBox(nType, szGroupName, buff)
	end
	_UIC[szKey]["Shadow_Striking_Display"] = Shadow_Striking_Display

	local Btn_ClearColor = LR.AppendUI("Button", frame, "Btn_ClearColor", {x = 245, y = 250, text = _L["Clear color"], w = 100})
	Btn_ClearColor:Enable(buff.enable)
	Btn_ClearColor.OnClick = function(arg0)
		buff.col = {}
		if _UI[szKey]["Shadow_Striking_Display"] then
			if next(buff.col) ~= nil then
				_UIC[szKey]["Shadow_Striking_Display"]:SetColor(unpack(buff.col))
			else
				_UIC[szKey]["Shadow_Striking_Display"]:SetColor(255, 255, 255)
			end
		end

		_C.ModifyBuff(nType, szGroupName, buff)
		_C.DrawOneBuffBox(nType, szGroupName, buff)
	end

	local CheckBox_UnderStack = LR.AppendUI("CheckBox", frame, "CheckBox_UnderStack", {x = 100, y = 280, text = _L["Still show when under stacknum"]})
	CheckBox_UnderStack:Enable(buff.enable and buff.bSpecialBuff)
	CheckBox_UnderStack:Check(buff.bShowUnderStack)
	CheckBox_UnderStack.OnCheck = function(arg0)
		buff.bShowUnderStack = arg0

		_C.ModifyBuff(nType, szGroupName, buff)
		_C.DrawOneBuffBox(nType, szGroupName, buff)
	end
	_UIC[szKey]["CheckBox_UnderStack"] = CheckBox_UnderStack

	local ComboBox_Sound = LR.AppendUI("ComboBox", frame, "ComboBox_Sound", {x = 100, y = 320, w = 120, text = _L["Sound settings"]})
	ComboBox_Sound:Enable(buff.enable)
	ComboBox_Sound.OnClick = function(m)
		m[#m + 1] = {szOption = _L["No sound"], bCheck = true, bMCheck = true, bChecked = function() return buff.nSoundType == 0 end,
			fnAction = function()
				buff.nSoundType = 0
				_C.ModifyBuff(nType, szGroupName, buff)
				_C.DrawOneBuffBox(nType, szGroupName, buff)
				Add_Effect()
			end,
		}
		local SOUND_TYPE = {
			g_sound.OpenAuction,
			g_sound.CloseAuction,
			g_sound.FinishAchievement,
			g_sound.PickupRing,
			g_sound.PickupWater,
		}
		for nSoundType = 1, 5, 1 do
			m[#m + 1] = {szOption = sformat(_L["Sound type %d"], nSoundType), bCheck = true, bMCheck = true, bChecked = function() return buff.nSoundType == nSoundType end,
				fnAction = function()
					buff.nSoundType = nSoundType
					_C.ModifyBuff(nType, szGroupName, buff)
					_C.DrawOneBuffBox(nType, szGroupName, buff)
					Add_Effect()
					PlaySound(SOUND.UI_SOUND, SOUND_TYPE[nSoundType])
				end,
				szIcon = "ui\\Image\\uitga\\voice.UITex",
				nFrame =21,
				nMouseOverFrame = 22,
				szLayer = "ICON_RIGHT",
				fnClickIcon = function ()
					PlaySound(SOUND.UI_SOUND, SOUND_TYPE[nSoundType])
				end,
			}
		end
		PopupMenu(m)
	end
	ComboBox_Sound.OnEnter = function()
		local x, y = this:GetAbsPos()
		local szXml = {}
		szXml[#szXml + 1] = GetFormatText(_L["To make this function work normally, please turn off player sound because it may interrupt this sound."])
		OutputTip(tconcat(szXml), 320, {x, y, 0, 0})
	end
	ComboBox_Sound.OnLeave = function()
		HideTip()
	end
	_UIC[szKey]["ComboBox_Sound"] = ComboBox_Sound
end


function _CC.OpenPanel(nType, szGroupName, BUFF)
	local buff = _Manager.FullData(szGroupName, BUFF)
	local szKey = sformat("%s_%d_%d", tostring(GetStringCRC(szGroupName)), buff.dwID, buff.nLevel)
	local frame = Station.Lookup(sformat("Normal/LR_BuffConfig_%s", szKey))
	if not frame then
		_CC.Init(nType, szGroupName, BUFF)
	else
		Wnd.CloseWindow(frame)
	end
end


LR_BuffConfig_Panel.OpenPanel = _CC.OpenPanel





----------------------------------------------------------------
----时间处理
----------------------------------------------------------------
LR.RegisterEvent("FIRST_LOADING_END", function() _Manager.FIRST_LOADING_END() end)
