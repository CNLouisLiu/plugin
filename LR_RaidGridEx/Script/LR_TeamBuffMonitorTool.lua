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
----------------------------------------------------------------
--引用的变量都在这里设置
----------------------------------------------------------------
--地图缓存数据
local LR_Team_Map = _GMV.LR_Team_Map	--用于存地图BUFF信息
local LR_Team_Map_Sorted =  _GMV.LR_Team_Map_Sorted	--按年代排序地图信息

---------------------------------------------------------------
LR_TeamBuffTool = {}
LR_TeamBuffTool.tBuffList = {
--[[
	VERSION = XXX,
	{szGroupName = "xx", enable = true, data = {
		{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
		{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
	},},
	{szGroupName = "xx", enable = true, data = {
		{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
		{dwID = 0, col = {}, bOnlySelf = false, nIconID = 0, nMonitorLevel = 0, nMonitorStack = 0, bSpecialBuff = false,},
	},},
]]
}
--------------------------------------------------------------------
local BUFF_CACHE = {}
local BUFF_CACHE_MAP = {}
local BUFF_CACHE_MAP_TEMP = {}
local BUFF_TOTAL_TIME = {}
local BUFF_INDEX_CACHE = {}

local BUFF_FIGHT_CACHE = {}
local NearestNPC = {szName = "#NoNPC", nIntensity = 0, dwTemplateID = 0, distance = 0}
local LOG_TIME = 0
local BEGIN_TIME = 0
local KEY = ""
local BUFF_FIGHT_LOAD = {}

function LR_TeamBuffTool.SaveBuffCache(skip_check)
	if not LR_TeamBuffTool_Panel.bOnCollect and not skip_check then
		return
	end
	local path = sformat("%s\\BUFF_CACHE\\buffcache.dat", SaveDataPath)
	local data = {} --clone(BUFF_CACHE)
	for i = 1, 1500, 1 do
		data[#data + 1] = clone(BUFF_CACHE[i])
	end
	for k, v in pairs(data) do
		for dwCaster, v2 in pairs(v.temp_caster or {}) do
			if v2.nType == TARGET.NPC then
				local _, obj = LR_TeamTools.DeathRecord.GetName(TARGET.NPC, tonumber(dwCaster))
				if obj then
					v.caster[sformat("%d_%d", obj.dwTemplateID, obj.dwMapID)] = clone(obj)
					v.temp_caster[k2] = nil
				end
			else
				local _, obj = LR_TeamTools.DeathRecord.GetName(TARGET.PLAYER, tonumber(dwCaster))
				if obj then
					v.caster[sformat("%d_%d", obj.dwID, obj.dwMapID)] = clone(obj)
					v.temp_caster[k2] = nil
				end
			end
		end
		v.temp_caster = {}
	end
	LR.SaveLUAData(path, data)

	local me = GetClientPlayer()
	local scene = me.GetScene()
	local dwMapID = scene.dwMapID
	local file_name = sformat("Map_%d(%s)", dwMapID, Table_GetMapName(dwMapID))
	if scene.nType == MAP_TYPE.DUNGEON then
		file_name = LR.MapType[dwMapID].szOtherName
	end
	local path2 = sformat("%s\\BUFF_CACHE\\%s.dat", SaveDataPath, file_name)
	local data2 = clone(BUFF_CACHE_MAP) or {}
	for szKey, v in pairs(data2) do
		for dwCaster, v2 in pairs(v.temp_caster or {}) do
			local _, obj = LR_TeamTools.DeathRecord.GetName(TARGET.NPC, tonumber(dwCaster))
			if obj then
				v.caster[sformat("%d_%d", obj.dwTemplateID, obj.dwMapID)] = clone(obj)
				v.temp_caster[dwCaster] = nil
			end
		end
		v.temp_caster = {}
	end
	BUFF_CACHE_MAP = clone(data2)
	LR.SaveLUAData(path2, data2)

	if LR_TeamBuffTool_Panel.bLogByFight and KEY ~= "" and GetCurrentTime() - LOG_TIME >= 30 then
		local _date = TimeToDate(LOG_TIME)
		local me = GetClientPlayer()
		local scene = me.GetScene()
		local path = sformat("%s\\BUFF_FIGHT_LOG\\%04d%02d%02d_%02d%02d%02d_%s_%s_%s(#%d)", SaveDataPath, _date["year"], _date["month"], _date["day"], _date["hour"], _date["minute"], _date["second"], me.szName, Table_GetMapName(scene.dwMapID), NearestNPC.szName, NearestNPC.dwTemplateID )
		local data = clone(BUFF_FIGHT_CACHE[KEY] or {})
		for k, v in pairs(data) do
			for dwCaster, v2 in pairs(v.temp_caster or {}) do
				if v2.nType == TARGET.NPC then
					local _, obj = LR_TeamTools.DeathRecord.GetName(TARGET.NPC, tonumber(dwCaster))
					if obj then
						v.caster[sformat("%d_%d", obj.dwTemplateID, obj.dwMapID)] = clone(obj)
						v.temp_caster[k2] = nil
					end
				else
					local _, obj = LR_TeamTools.DeathRecord.GetName(TARGET.PLAYER, tonumber(dwCaster))
					if obj then
						v.caster[sformat("%d_%d", obj.dwID, obj.dwMapID)] = clone(obj)
						v.temp_caster[k2] = nil
					end
				end
			end
			v.temp_caster = {}
		end
		data.key = "BUFF_FIGHT_LOG"
		LR.SaveLUAData(path, data)
	end
end

function LR_TeamBuffTool.LoadBuffFightLog()
	BUFF_FIGHT_LOAD = {}
	local szFile = GetOpenFileName(sformat("%s", _L["Choose file"]), "Save data File(*.jx3dat)\0*.jx3dat\0All Files(*.*)\0*.*\0")
	if szFile == "" then
		return false
	end
	local _s, _e, szFileName = sfind(szFile,"interface(.+)")
	local path = sformat("interface%s", szFileName)
	local data = LoadLUAData(path) or {}
	if data and data.key and data.key == "BUFF_FIGHT_LOG" then
		data.key = nil
		BUFF_FIGHT_LOAD = clone(data)
		return true
	else
		BUFF_FIGHT_LOAD = {}
		return false
	end
end


function LR_TeamBuffTool.LoadBuffCache()
	local path = sformat("%s\\BUFF_CACHE\\buffcache.dat", SaveDataPath)
	local data = LoadLUAData(path) or {}
	BUFF_CACHE = clone(data)
end

function LR_TeamBuffTool.LoadBuffCacheMap()
	local me = GetClientPlayer()
	local scene = me.GetScene()
	local dwMapID = scene.dwMapID
	local file_name = sformat("Map_%d(%s)", dwMapID, Table_GetMapName(dwMapID))
	if scene.nType == MAP_TYPE.DUNGEON then
		file_name = LR.MapType[dwMapID].szOtherName
	end
	local path2 = sformat("%s\\BUFF_CACHE\\%s.dat", SaveDataPath, file_name)
	local data2 = LoadLUAData(path2) or {}
	BUFF_CACHE_MAP = clone(data2)
end

function LR_TeamBuffTool.ClearBuffCache()
	BUFF_CACHE = {}
	LR_TeamBuffTool.SaveBuffCache(true)
end

--------------------------------------------------------------------
---公共BUFF配置文件
--------------------------------------------------------------------
local ORDER = {}
function LR_TeamBuffTool.GetORDER(num)
	if ORDER[num] then
		return LR_TeamBuffTool.GetORDER(num + 1)
	else
		ORDER[num] = true
		return num
	end
end

function LR_TeamBuffTool.FormatBuff(v2)
	local buff = {
		dwID = v2.dwID or 0,
		enable = v2.enable or false,
		nLevel = v2.nLevel or 1,
		bOnlySelf = v2.bOnlySelf or false,	--仅来源于我
		bOnlyMonitorSelf = v2.bOnlyMonitorSelf or false,	--仅监控我
		bOnlyInKungfu = v2.bOnlyInKungfu or {},	--限制心法
		bOnlyShowInTeamRights = v2.bOnlyShowInTeamRights or {},	--限制团队成员显示，例如团长
		nMonitorLevel = v2.nMonitorLevel or 0,	--0：不区分等级
		nStackNum = v2.nStackNum or 1,
		nMonitorStack = v2.nMonitorStack or 0,	--0：不区分层数
		nIconID = v2.nIconID or 0,	--0：使用原来的ICON
		col = v2.col or {},
		--醒目BUFF，醒目BUFF会有单独Handle放大，且只有醒目BUFF才有颜色模版，如果某些BUFF叠上X层后要重点显示，请用醒目BUFF，设置后开可以设置在X层下也显示
		bSpecialBuff = v2.bSpecialBuff or false,	--BUFF放大
		bShowMask = v2.bShowMask or false,
		bShowUnderStack = v2.bShowUnderStack or false,
		--
		nEffectsType = v2.nEffectsType or 0,	--BUFF效果，普通BUFF也可以设置效果，也可以起到醒目的作用
		nSoundType = v2.nSoundType or 0,	--声音报警
		bShowInTopHead = v2.bShowInTopHead or false,	--头顶显示
	}
	return buff
end

function LR_TeamBuffTool.FormatData(data)
	local tBuffList = {}
	local temp = {}
	for k, v in pairs(data) do
		if type(v) == "table" and v.szGroupName then
			v.order = v.order or k
			tinsert(temp, v)
		end
	end
	tsort(temp, function(a, b) return a.order < b.order end)
	--Output(temp)

	ORDER = {}
	for k, v in pairs(temp) do
		if type(v) == "table" and v.szGroupName then
			local tGroup = {enable = v.enable or false, szGroupName = v.szGroupName or sformat("default%d", k), data = {}, order = LR_TeamBuffTool.GetORDER(1)}
			for k2, v2 in pairs(v.data) do
				local buff = LR_TeamBuffTool.FormatBuff(v2)
				tinsert(tGroup.data, buff)
			end
			tinsert(tBuffList, tGroup)
		end
	end
	return tBuffList
end

function LR_TeamBuffTool.SaveData()
	local path = sformat("%s\\BuffMonitorData.dat", SaveDataPath)
	local data = {dungeon_data = {}, custom_data = {}, VERSION = VERSION}
	for k, v in pairs(LR_Team_Map) do
		if next(v.data) ~= nil then
			tinsert(data.dungeon_data, {dwMapID = clone(v.dwMapID), data = clone(v.data), enable = v.enable})
		end
	end
	data.custom_data = LR_TeamBuffTool.FormatData(LR_TeamBuffTool.tBuffList)
	LR.SaveLUAData(path, data, "")

	LR_TeamBuffSettingPanel.FormatDebuffNameList()
end

function LR_TeamBuffTool.LoadData()
	local path = sformat("%s\\BuffMonitorData.dat", SaveDataPath)
	local data = LoadLUAData(path) or {dungeon_data = {}, custom_data = {}, VERSION = "-"}
	if next(data) == nil or not data.VERSION or data.VERSION ~= VERSION then
		LR_TeamBuffTool.ResetData()
	else
		for k, v in pairs(data.dungeon_data) do
			local szName = ""
			for k2, dwMapID in pairs(v.dwMapID) do
				if LR.MapType[dwMapID] then
					szName = LR.MapType[dwMapID].szOtherName
				end
			end
			LR_Team_Map[szName] = LR_Team_Map[szName] or {enable = true, dwMapID = clone(v.dwMapID), data = {}, level = 3}
			LR_Team_Map[szName].data = clone(v.data)
		end

		LR_TeamBuffTool.tBuffList = LR_TeamBuffTool.FormatData(data.custom_data)
	end
	LR_TeamBuffSettingPanel.FormatDebuffNameList()
end

function LR_TeamBuffTool.ResetData()
	local _, _, szLang = GetVersion()
	local path = sformat("%s\\DefaultData\\%s", AddonPath, szLang)
	local data = LoadLUAData(path) or {dungeon_data = {}, custom_data = {}, VERSION = VERSION}

	for k, v in pairs(data.dungeon_data) do
		local szName = ""
		for k2, dwMapID in pairs(v.dwMapID) do
			if LR.MapType[dwMapID] then
				szName = LR.MapType[dwMapID].szOtherName
			end
		end
		LR_Team_Map[szName] = LR_Team_Map[szName] or {enable = true, dwMapID = clone(v.dwMapID), data = {}, level = 3}
		LR_Team_Map[szName].data = clone(v.data)
	end
	LR_TeamBuffTool.tBuffList = LR_TeamBuffTool.FormatData(data.custom_data)

	LR_TeamBuffTool.SaveData()
end

function LR_TeamBuffTool.LoadDefaultData()
	local msg =
	{	szMessage = GetFormatText(_L["Sure to load default data?"]),
		bRichText = true,
		szName = "Load default data",
		{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction =
			function()
				LR_TeamBuffTool.ResetData()
				LR_TeamBuffTool_Panel.szChooseGroupName = ""
				LR_TeamBuffTool_Panel:LoadGroupBox()
				LR_TeamBuffTool_Panel:LoadBuffListBox()
			end
		},
		{szOption = g_tStrings.STR_HOTKEY_CANCEL},
	}
	MessageBox(msg)
end

--------------------------------------------------------------------
---数据导入导出
--------------------------------------------------------------------
----LR_TeamBuffTool.tBuffList用于存放自定义数据
----LR_Team_Map用于存放副本数据

function LR_TeamBuffTool.Export()
	local fExport = function(szName)
		local path = sformat("%s\\Export\\%s", SaveDataPath, szName)
		local data = {dungeon_data = {}, custom_data = {}, nType = "DataExport"}
		for k, v in pairs(LR_Team_Map) do
			if next(v.data) ~= nil then
				tinsert(data.dungeon_data, {dwMapID = clone(v.dwMapID), data = clone(v.data)})
			end
		end
		data.custom_data = LR_TeamBuffTool.FormatData(LR_TeamBuffTool.tBuffList)
		LR.SaveLUAData(path, data)
		LR.SysMsg(sformat(_L["File location: %s.jx3dat\n"], path))
	end

	local fx, fy = this:GetAbsPos()
	local nW, nH = this:GetSize()
	GetUserInput(_L["Enter file name"], fExport, nil, nil, {fx, fy, nW, nH}, GetClientPlayer().szName)
end

function LR_TeamBuffTool.Import()
	local szFile = GetOpenFileName(sformat("%s", _L["Choose file"]), "Save data File(*.jx3dat)\0*.jx3dat\0All Files(*.*)\0*.*\0")
	if szFile == "" then
		return
	end
	local _s, _e, szFileName = sfind(szFile,"interface(.+)")
	local path = sformat("interface%s", szFileName)
	local data = LoadLUAData(path) or {dungeon_data = {}, custom_data = {},}
	if data.nType ~= "DataExport" then
		return
	end

	for k, v in pairs(data.dungeon_data) do
		local szName = ""
		for k2, dwMapID in pairs(v.dwMapID) do
			if LR.MapType[dwMapID] then
				szName = LR.MapType[dwMapID].szOtherName
			end
		end
		LR_Team_Map[szName] = LR_Team_Map[szName] or {enable = true, dwMapID = clone(v.dwMapID), data = {}, level = 3}
		LR_Team_Map[szName].data = clone(v.data)
	end
	LR_TeamBuffTool.tBuffList = LR_TeamBuffTool.FormatData(data.custom_data)
	LR_TeamBuffTool.SaveData()

	LR_TeamBuffTool_Panel.szChooseGroupName = ""
	LR_TeamBuffTool_Panel:LoadGroupBox()
	LR_TeamBuffTool_Panel:LoadBuffListBox()
end

function LR_TeamBuffTool.Clear()
	local msg =
	{	szMessage = GetFormatText(_L["Sure to clear data?"]),
		bRichText = true,
		szName = "ClearData",
		{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction =
			function()
				LR_TeamBuffTool.tBuffList = {}
				for k, v in pairs(LR_Team_Map) do
					v.data = {}
				end
				LR_TeamBuffTool.SaveData()
				LR_TeamBuffTool_Panel:LoadGroupBox()
				LR_TeamBuffTool_Panel.szChooseGroupName = ""
				LR_TeamBuffTool_Panel:LoadBuffListBox()
			end
		},
		{szOption = g_tStrings.STR_HOTKEY_CANCEL},
	}
	MessageBox(msg)
end

----------------------------------------------------------------------------------------------
---------buff设置面板
----------------------------------------------------------------------------------------------
LR_TeamBuffTool_Panel = _G2.CreateAddon("LR_TeamBuffTool_Panel")
LR_TeamBuffTool_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_TeamBuffTool_Panel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0},
}
LR_TeamBuffTool_Panel.bOnCollect = false
LR_TeamBuffTool_Panel.bCollectHideBuff = false
LR_TeamBuffTool_Panel.bCollectOnlyFromNpc = false
LR_TeamBuffTool_Panel.bConnectSysRaidPanel = true
LR_TeamBuffTool_Panel.bShowMapBuffCache = false
LR_TeamBuffTool_Panel.bMapData = false
RegisterCustomData("LR_TeamBuffTool_Panel.bConnectSysRaidPanel", VERSION)

LR_TeamBuffTool_Panel.szChoose = "SelfBuff"
LR_TeamBuffTool_Panel.szChooseGroupName = ""
LR_TeamBuffTool_Panel.szChooseGroup = nil
LR_TeamBuffTool_Panel.szChooseBuff = nil
LR_TeamBuffTool_Panel.szChooseResultBuff = nil
LR_TeamBuffTool_Panel.searchText = ""
LR_TeamBuffTool_Panel.szCasterName = ""

LR_TeamBuffTool_Panel.bDraged = false
LR_TeamBuffTool_Panel.bAdd = false
LR_TeamBuffTool_Panel.bAddBuff = nil

LR_TeamBuffTool_Panel.ShowBuffOnNPC = true
LR_TeamBuffTool_Panel.ShowBuffOnPlayer = true

LR_TeamBuffTool_Panel.bShowRefreshBuff = false
LR_TeamBuffTool_Panel.bShowBuffOnlyFromNPC = false

LR_TeamBuffTool_Panel.bShowHideBuff = false
LR_TeamBuffTool_Panel.bShowNormalBuff = true

LR_TeamBuffTool_Panel.bShowBUFFGood = true
LR_TeamBuffTool_Panel.bShowBUFFBad = true

LR_TeamBuffTool_Panel.bLogByFight = false
LR_TeamBuffTool_Panel.bShowLogByFight = false

LR_TeamBuffTool_Panel.DisableDungeonData = false
RegisterCustomData("LR_TeamBuffTool_Panel.DisableDungeonData", VERSION)


local BuffListBoxUI = {}
local ResultBoxHover_Cache = {}

function LR_TeamBuffTool_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("CUSTOM_DATA_LOADED")

	LR_TeamBuffTool_Panel.UpdateAnchor(this)
	RegisterGlobalEsc("LR_TeamBuffTool_Panel",function () return true end ,function() LR_TeamBuffTool_Panel:Open() end)

	LR_TeamBuffTool_Panel.szChoose = "SelfBuff"
	LR_TeamBuffTool_Panel.szChooseGroup = nil
	LR_TeamBuffTool_Panel.szChooseGroupName = ""
	LR_TeamBuffTool_Panel.searchText = ""
	LR_TeamBuffTool_Panel.szCasterName = ""

	LR_TeamBuffTool_Panel.LoadType = "by dungeon"

	LR_TeamBuffTool_Panel.bLogByFight = false
	LR_TeamBuffTool_Panel.bShowLogByFight = false

	LR_TeamBuffTool.LoadBuffCache()
	LR_TeamBuffTool.SaveBuffCache()

	for k, v in pairs(LR_Team_Map_Sorted) do
		v.fold = true	--true为合起来
	end

end

function LR_TeamBuffTool_Panel:OnEvents(event)
	if event ==  "CUSTOM_DATA_LOADED" then
		if arg0 ==  "Role" then
			LR_TeamBuffTool_Panel.UpdateAnchor(this)
		end
	elseif event ==  "UI_SCALED" then
		LR_TeamBuffTool_Panel.UpdateAnchor(this)
	end
end

function LR_TeamBuffTool_Panel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_TeamBuffTool_Panel.UsrData.Anchor.s, 0, 0, LR_TeamBuffTool_Panel.UsrData.Anchor.r, LR_TeamBuffTool_Panel.UsrData.Anchor.x, LR_TeamBuffTool_Panel.UsrData.Anchor.y)
end

function LR_TeamBuffTool_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_TeamBuffTool_Panel")
	PlaySound(SOUND.UI_SOUND,g_sound.CloseFrame)

	LR_TeamBuffTool.SaveBuffCache()
end

function LR_TeamBuffTool_Panel:OnDragEnd()
	this:CorrectPos()
	--LR_TeamBuffTool_Panel.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_TeamBuffTool_Panel.OnMouseEnter()
	local szName = this:GetName()
	if szName == "ScrollBuffListBox" then
		if LR_TeamBuffTool_Panel.bDraged then
			LR_TeamBuffTool_Panel.bAdd = true
		end
	end
end

function LR_TeamBuffTool_Panel.OnMouseLeave()
	local szName = this:GetName()
	if szName == "ScrollBuffListBox" then
		LR_TeamBuffTool_Panel.bAdd = false
	end
end

function LR_TeamBuffTool_Panel.CanBuffShow(v)
	if v.target_type == TARGET.NPC and not LR_TeamBuffTool_Panel.ShowBuffOnNPC then
		return false, 1
	end
	if v.target_type == TARGET.PLAYER and not LR_TeamBuffTool_Panel.ShowBuffOnPlayer then
		return false, 2
	end
	if v.bFresh and not LR_TeamBuffTool_Panel.bShowRefreshBuff then
		return false, 3
	end
	if LR_TeamBuffTool_Panel.bShowBuffOnlyFromNPC then
		local flag = false
		for k2, v2 in pairs(v.caster or {}) do
			if v2.nType == TARGET.NPC then
				flag = true
			end
		end
		if not flag then
			return false, 4
		end
	end
	if v.bCanCancel then
		if not LR_TeamBuffTool_Panel.bShowBUFFGood then
			return false, 5
		end
	else
		if not LR_TeamBuffTool_Panel.bShowBUFFBad then
			return false, 6
		end
	end
	if v.bHideBuff then
		if not LR_TeamBuffTool_Panel.bShowHideBuff then
			return false, 7
		end
	else
		if not LR_TeamBuffTool_Panel.bShowNormalBuff then
			return false, 8
		end
	end

	return true
end

function LR_TeamBuffTool_Panel:Init()
	local frame = self:Append("Frame", "LR_TeamBuffTool_Panel", {title = _L["LR Buff Tools"], style = "LARGER"})
	frame:SetAlpha(255)
	local frame1 = Station.Lookup("Normal/LR_TeamBuffTool_Panel"):Lookup("",""):Lookup("Text_Title")
	frame1:SetAlpha(255)

	local imgTab = self:Append("Image", frame,"TabImg",{w = 960,h = 33,x = 0,y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex",46)
	imgTab:SetImageType(11)

	local Btn_FAQ = self:Append("UIButton", frame, "Btn_FAQ" , {x = 900 , y = 15 , w = 20 , h = 20, ani = {"ui\\Image\\UICommon\\CommonPanel2.UITex", 48, 50, 54}, })
	Btn_FAQ.OnEnter = function()
		local tTip = {}
		tTip[#tTip + 1] = GetFormatText(_L["TeamBuffTool_Panel_Tip01\n"], 2)
		tTip[#tTip + 1] = GetFormatText(_L["TeamBuffTool_Panel_Tip02\n"], 2)

		local fx, fy = this:GetAbsPos()
		local nW, nH = this:GetSize()
		OutputTip(tconcat(tTip), 320, {fx, fy, nW, nH})
	end
	Btn_FAQ.OnLeave = function()
		HideTip()
	end

	local Text_CheckBox = {_L["Dungeon data"], _L["Custom data"]}
	local tchose = {"by dungeon", "by custom"}
	local Check_Box = {}
	for k, v in pairs(Text_CheckBox) do
		Check_Box[k] = self:Append("UICheckBox", frame, sformat("CheckBox_%d", k), {x = 20 + 150 * (k - 1), y = 51, w = 150, h = 30, text = v, group = "TypeChose"})
		Check_Box[k].OnCheck = function(bCheck)
			if bCheck then
				LR_TeamBuffTool_Panel.szChooseGroup = nil
				LR_TeamBuffTool_Panel.szChooseGroupName = ""
				LR_TeamBuffTool_Panel.LoadType = tchose[k]
				self:LoadGroupBox()
				self:LoadBuffListBox()
			end
		end
	end
	Check_Box[1]:Check(true)

	local ComboBox_Import = LR.AppendUI("ComboBox", frame, "ComboBox_Import", {w = 150, h = 30, x = 320, y = 51, text = _L["Import/Export data"]})
	ComboBox_Import.OnClick = function(m)
		m[#m + 1] = {szOption = _L["Export data"], fnAction = function() LR_TeamBuffTool.Export() end}
		m[#m + 1] = {szOption = _L["Import data"], fnAction = function() LR_TeamBuffTool.Import() end}
		m[#m + 1] = {bDevide = true}
		m[#m + 1] = {szOption = _L["Clear data"], fnAction = function() LR_TeamBuffTool.Clear() end}
		m[#m + 1] = {szOption = _L["Load default data"], fnAction = function() LR_TeamBuffTool.LoadDefaultData() end}
		m[#m + 1] = {bDevide = true}
		m[#m + 1] = {szOption = _L["Connect to system raid panel"], bCheck = true, bChecked = function() return LR_TeamBuffTool_Panel.bConnectSysRaidPanel end,
			fnAction = function()
				LR_TeamBuffTool_Panel.bConnectSysRaidPanel = not LR_TeamBuffTool_Panel.bConnectSysRaidPanel
				LR_TeamBuffSettingPanel.FormatDebuffNameList()
				if not LR_TeamBuffTool_Panel.bConnectSysRaidPanel then
					Raid_MonitorBuffs({})
				end
			end}
		PopupMenu(m)
	end

	local Btn_FAQ2 = self:Append("UIButton", frame, "Btn_FAQ2" , {x = 480 , y = 55 , w = 20 , h = 20, ani = {"ui\\Image\\UICommon\\CommonPanel2.UITex", 48, 50, 54}, })
	Btn_FAQ2.OnEnter = function()
		local tTip = {}
		tTip[#tTip + 1] = GetFormatText(_L["TeamBuffTool_Panel_Tip03\n"], 2)

		local fx, fy = this:GetAbsPos()
		local nW, nH = this:GetSize()
		OutputTip(tconcat(tTip), 320, {fx, fy, nW, nH})
	end
	Btn_FAQ2.OnLeave = function()
		HideTip()
	end

	local ComboBox_DisableDungeonData = LR.AppendUI("CheckBox", frame, "ComboBox_DisableDungeonData", {w = 150, h = 30, x = 20, y = 20, text = _L["Disable dungeon data"]})
	ComboBox_DisableDungeonData:Check(LR_TeamBuffTool_Panel.DisableDungeonData)
	ComboBox_DisableDungeonData.OnCheck = function(arg0)
		LR_TeamBuffTool_Panel.DisableDungeonData = arg0
		LR_TeamBuffSettingPanel.FormatDebuffNameList()
	end

	local CheckBox_EnableCollect = LR.AppendUI("CheckBox", frame, "ComboBox_Import", {w = 150, h = 30, x = 740, y = 51, text = _L["Begin buff collect"]})
	CheckBox_EnableCollect:Check(LR_TeamBuffTool_Panel.bOnCollect)
	CheckBox_EnableCollect.OnCheck = function(arg0)
		LR_TeamBuffTool_Panel.bOnCollect = arg0
		if LR_TeamBuffTool_Panel.bOnCollect then
			LR_TeamBuffTool.BeginLog()
		else
			LR_TeamBuffTool.EndLog()
		end
	end

	local CheckBox_Selected = LR.AppendUI("CheckBox", frame, "CheckBox_Selected", {w = 150, h = 30, x = 240, y = 92, text = _L["Show select group npc buff"]})
	CheckBox_Selected:Check(LR_TeamBuffTool_Panel.bMapData)
	CheckBox_Selected.OnCheck = function(arg0)
		LR_TeamBuffTool_Panel.bMapData = arg0
		self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
		self:LoadSearchResultBox()
	end

	local UIButton_Add = LR.AppendUI("UIButton", frame, "LR_Btn_Equipment", {x = 680 , y = 93 , w = 24 , h = 24, ani = {"ui\\Image\\UICommon\\exteriorbox2.UITex", 23, 24, 25}})
	UIButton_Add.OnClick = function(dwID)
		local x, y = this:GetAbsPos()
		local function _addbuff(arg0)
			if LR_TeamBuffTool_Panel.szChooseGroupName == "" then
				return--LR_Team_Buff_Setting_Panel:Open(szGroupName, buff)
			end
			local buff = {dwID = arg0, nLevel = 1}
			LR_TeamBuffTool_Panel.bAddBuff = buff
			buff = LR_TeamBuffTool_Panel:addBuff()
			LR_Team_Buff_Setting_Panel:Open(LR_TeamBuffTool_Panel.szChooseGroupName, buff)
		end
		GetUserInputNumber(0, 99999, {x, y, 0, 0}, _addbuff)
	end


	local Btn_HideBuff = self:Append("UIButton", frame, "Btn_HideBuff" , {x = 870 , y = 55 , w = 14 , h = 20, ani = {"ui\\Image\\UICommon\\CommonPanel2.UITex", 80, 81, 82, 83}, })
	Btn_HideBuff.OnClick = function()
		local menu = {}
		menu[#menu + 1] = {szOption = _L["Collect hide buff"], bCheck = true, bChecked = function() return LR_TeamBuffTool_Panel.bCollectHideBuff end,
			fnAction = function()
				LR_TeamBuffTool_Panel.bCollectHideBuff = not LR_TeamBuffTool_Panel.bCollectHideBuff
			end
		}
		menu[#menu + 1] = {szOption = _L["Only from npc"], bCheck = true, bChecked = function() return LR_TeamBuffTool_Panel.bCollectOnlyFromNpc end,
			fnAction = function()
				LR_TeamBuffTool_Panel.bCollectOnlyFromNpc = not LR_TeamBuffTool_Panel.bCollectOnlyFromNpc
			end,
		}

		menu[#menu + 1] = {bDevide = true}
		menu[#menu + 1] = {szOption = _L["Log by fight"], bCheck = true, bChecked = function() return LR_TeamBuffTool_Panel.bLogByFight end,
			fnAction = function()
				LR_TeamBuffTool_Panel.bLogByFight = not LR_TeamBuffTool_Panel.bLogByFight
				self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
				self:LoadSearchResultBox()
				Wnd.CloseWindow(GetPopupMenu())
			end,
		}
		menu[#menu + 1] = {szOption = _L["Load history"],
			fnAction = function()
				if LR_TeamBuffTool.LoadBuffFightLog() then
					LR_TeamBuffTool_Panel.bShowMapBuffCache = false
					LR_TeamBuffTool_Panel.bShowLogByFight = true
					self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
					self:LoadSearchResultBox()
					Wnd.CloseWindow(GetPopupMenu())
				end
			end,
		}

		menu[#menu + 1] = {bDevide = true}
		menu[#menu + 1] = {szOption = _L["Show map buff cache"], bCheck = true, bChecked = function() return LR_TeamBuffTool_Panel.bShowMapBuffCache end,
			fnAction = function()
				LR_TeamBuffTool_Panel.bShowMapBuffCache = not LR_TeamBuffTool_Panel.bShowMapBuffCache
				if LR_TeamBuffTool_Panel.bShowMapBuffCache then
					LR_TeamBuffTool_Panel.bShowLogByFight = false
				end
				self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
				self:LoadSearchResultBox()
				Wnd.CloseWindow(GetPopupMenu())
			end,
		}

		menu[#menu + 1] = {bDevide = true}
		local tKey = {"ShowBuffOnNPC", "ShowBuffOnPlayer"}
		for k, v in pairs(tKey) do
			menu[#menu + 1] = {szOption = _L[v], bCheck = true, bMCheck = false, bChecked = function() return LR_TeamBuffTool_Panel[v] end,
				fnAction = function()
					LR_TeamBuffTool_Panel[v] = not LR_TeamBuffTool_Panel[v]
					self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
					self:LoadSearchResultBox()
				end,
			}
		end

		menu[#menu + 1] = {bDevide = true}
		local tKey = {"bShowRefreshBuff", "bShowBuffOnlyFromNPC"}
		for k, v in pairs(tKey) do
			menu[#menu + 1] = {szOption = _L[v], bCheck = true, bMCheck = false, bChecked = function() return LR_TeamBuffTool_Panel[v] end,
				fnAction = function()
					LR_TeamBuffTool_Panel[v] = not LR_TeamBuffTool_Panel[v]
					self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
					self:LoadSearchResultBox()
				end,
			}
		end

		menu[#menu + 1] = {bDevide = true}
		local tKey = {"bShowNormalBuff", "bShowHideBuff"}
		for k, v in pairs(tKey) do
			menu[#menu + 1] = {szOption = _L[v], bCheck = true, bMCheck = false, bChecked = function() return LR_TeamBuffTool_Panel[v] end,
				fnAction = function()
					LR_TeamBuffTool_Panel[v] = not LR_TeamBuffTool_Panel[v]
					self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
					self:LoadSearchResultBox()
				end,
			}
		end

		menu[#menu + 1] = {bDevide = true}
		local tKey = {"bShowBUFFGood", "bShowBUFFBad"}
		for k, v in pairs(tKey) do
			menu[#menu + 1] = {szOption = _L[v], bCheck = true, bMCheck = false, bChecked = function() return LR_TeamBuffTool_Panel[v] end,
				fnAction = function()
					LR_TeamBuffTool_Panel[v] = not LR_TeamBuffTool_Panel[v]
					self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
					self:LoadSearchResultBox()
				end,
			}
		end

		menu[#menu + 1] = {bDevide = true}
		menu[#menu + 1] = {szOption = _L["Clear history"],
			fnAction = function()
				LR_TeamBuffTool.ClearBuffCache()
				self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
				self:LoadSearchResultBox()
			end,
		}
		local tCasterName = {}
		local tTemp = {}

		if LR_TeamBuffTool_Panel.bMapData and LR_TeamBuffTool_Panel.LoadType == "by dungeon" then
			for k, v in pairs(BUFF_CACHE_MAP_TEMP) do
				for k2, v2 in pairs(v.caster) do
					if not tTemp[v2.szName] then
						tinsert(tCasterName, {nType = v2.nType, nIntensity = v2.nIntensity or 1, szName = v2.szName, dwForceID = v2.dwForceID or 0})
						tTemp[v2.szName] = true
					end
				end
			end
		else
			if LR_TeamBuffTool_Panel.bShowLogByFight then
				for k, v in pairs(BUFF_FIGHT_LOAD) do
					for k2, v2 in pairs(v.caster) do
						if not tTemp[v2.szName] then
							tinsert(tCasterName, {nType = v2.nType, nIntensity = v2.nIntensity or 1, szName = v2.szName, dwForceID = v2.dwForceID or 0})
							tTemp[v2.szName] = true
						end
					end
				end
			elseif LR_TeamBuffTool_Panel.bShowMapBuffCache then
				for k, v in pairs(BUFF_CACHE_MAP) do
					for k2, v2 in pairs(v.caster) do
						if not tTemp[v2.szName] then
							tinsert(tCasterName, {nType = v2.nType, nIntensity = v2.nIntensity or 1, szName = v2.szName, dwForceID = v2.dwForceID or 0})
							tTemp[v2.szName] = true
						end
					end
				end
			else
				for k, v in pairs(BUFF_CACHE) do
					local szCasterName = v.szCasterName or "unknow"
						for k2, v2 in pairs(v.caster) do
						if not tTemp[v2.szName] then
							tinsert(tCasterName, {nType = v2.nType, nIntensity = v2.nIntensity or 1, szName = v2.szName, dwForceID = v2.dwForceID or 0})
							tTemp[v2.szName] = true
						end
					end
				end
			end
		end

		tsort(tCasterName, function(a, b)
			if a.nType == b.nType then
				if a.nIntensity == b.nIntensity then
					if a.dwForceID == b.dwForceID then
						return a.szName < b.szName
					else
						return a.dwForceID < b.dwForceID
					end
				else
					return a.nIntensity > b.nIntensity
				end
			else
				return a.nType < b.nType
			end
		end)

		if next(tCasterName) ~= nil then
			menu[#menu + 1] = {bDevide = true}
			for k, v in pairs(tCasterName) do
				menu[#menu + 1] = {	szOption = v.szName, bCheck = true, bMCheck = true, bChecked = function() return LR_TeamBuffTool_Panel.szCasterName == v end,
					fnAction = function()
						LR_TeamBuffTool_Panel.szCasterName = v.szName
						self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
						self:LoadSearchResultBox()
					end,
				}
				if v.nType == TARGET.PLAYER then
					menu[#menu].szIcon,	 menu[#menu].nFrame = GetForceImage(v.dwForceID)
					menu[#menu].rgb = {LR.GetMenPaiColor(v.dwForceID)}
					menu[#menu].szLayer = "ICON_RIGHT"
				elseif v.nType == TARGET.NPC then
					if v.nIntensity == 4 then
						menu[#menu].szIcon,	 menu[#menu].nFrame = "UI\\image\\Minimap\\Minimap.uitex", 7
						menu[#menu].rgb = {237, 28, 36}
						menu[#menu].szLayer = "ICON_RIGHT"
					elseif v.nIntensity == 3 then
						menu[#menu].szIcon,	 menu[#menu].nFrame = "UI\\image\\Minimap\\Minimap.uitex", 12
						menu[#menu].rgb = {238, 238, 0}
						menu[#menu].szLayer = "ICON_RIGHT"
					else
						menu[#menu].szIcon,	 menu[#menu].nFrame = "UI\\image\\Minimap\\Minimap.uitex", 251
						menu[#menu].szLayer = "ICON_RIGHT"
					end
				end
			end
			menu[#menu + 1] = {bDevide = true}
			menu[#menu + 1] = {szOption = _L["Clear choose"],
				fnAction = function()
					LR_TeamBuffTool_Panel.szCasterName = ""
					self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
					self:LoadSearchResultBox()
				end,
			}
		end

		local fx, fy = this:GetAbsPos()
		local nW, nH = this:GetSize()
		PopupMenu(menu, {fx, fy, nW, nH})
	end

	local hPageSet = self:Append("PageSet", frame, "PageSet", {x = 20, y = 120, w = 1000, h = 470})
	--动态分组列表
	local hWinIconView = self:Append("Window", hPageSet, "WindowGroupBox", {x = 0, y = 0, w = 220, h = 430})
	local hScroll1 = self:Append("Scroll", hWinIconView,"ScrollGroupBox", {x = 0, y = 0, w = 200, h = 430})
	self:LoadGroupBox()

	--动态Buff列表
	local hBuffListBox = self:Append("Window", hPageSet, "hBuffListBox", {x = 210, y = 0, w = 520, h = 430})
	local hScroll3 = self:Append("Scroll", hBuffListBox,"ScrollBuffListBox", {x = 10, y = 0, w = 500, h = 430})
	self:LoadBuffListBox()

	--动态搜索buff结果
	local hWinBuffSearch = self:Append("Window", hPageSet, "hWinBuffSearch", {x = 723, y = 30, w = 220, h = 400})
	local hScroll2 = self:Append("Scroll", hWinBuffSearch,"ScrollSearchBuffBox", {x = 0, y = 0, w = 200, h = 400})
	self:LoadSearchResultBox()

	-------------初始界面物品
	-------------分组
	local hHandle_Group = self:Append("Handle", frame, "hHandle_Group", {x = 18, y = 90, w = 200, h = 470})

	local Image_Group_BG = self:Append("Image", hHandle_Group, "Image_Group_BG", {x = 0, y = 0, w = 200, h = 470})
	Image_Group_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",50)
	Image_Group_BG:SetImageType(10)

	local Image_Group_BG1 = self:Append("Image", hHandle_Group, "Image_Group_BG1", {x = 0, y = 30, w = 200, h = 440})
	Image_Group_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",74)
	Image_Group_BG1:SetImageType(10)
	Image_Group_BG1:SetAlpha(110)

	local Image_Group_Line1_0 = self:Append("Image", hHandle_Group, "Image_Group_Line1_0", {x = 3, y = 28, w = 200, h = 3})
	Image_Group_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",65)
	Image_Group_Line1_0:SetImageType(11)
	Image_Group_Line1_0:SetAlpha(115)

	local Text_Group_break2 = self:Append("Text", hHandle_Group, "Text_Group_break2", {w = 200, h = 30, x  = 0, y = 2, text = _L["Group name"], font = 18})
	Text_Group_break2:SetHAlign(1)
	Text_Group_break2:SetVAlign(1)


	-------------Buff列表
	local hHandle_BuffList = self:Append("Handle", frame, "hHandle_BuffList", {x = 230, y = 90, w = 500, h = 470})

	local Image_BuffList_BG = self:Append("Image", hHandle_BuffList, "Image_Record_BG", {x = 0, y = 0, w = 500, h = 470})
	Image_BuffList_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",50)
	Image_BuffList_BG:SetImageType(10)

	local Image_BuffList_BG1 = self:Append("Image", hHandle_BuffList, "Image_BuffList_BG1", {x = 0, y = 30, w = 500, h = 440})
	Image_BuffList_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",74)
	Image_BuffList_BG1:SetImageType(10)
	Image_BuffList_BG1:SetAlpha(110)

	local Image_BuffList_Line1_0 = self:Append("Image", hHandle_BuffList, "Image_BuffList_Line1_0", {x = 3, y = 28, w = 500, h = 3})
	Image_BuffList_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",65)
	Image_BuffList_Line1_0:SetImageType(11)
	Image_BuffList_Line1_0:SetAlpha(115)

	local Text_BuffList_break2 = self:Append("Text", hHandle_BuffList, "Text_BuffList_break2", {w = 500, h = 30, x  = 0, y = 2, text = _L["Buff list"], font = 18})
	Text_BuffList_break2:SetHAlign(1)
	Text_BuffList_break2:SetVAlign(1)

	-------------搜索列表
	local hHandle_Search = self:Append("Handle", frame, "hHandle_Search", {x = 740, y = 90, w = 200, h = 470})

	local Image_Search_BG = self:Append("Image", hHandle_Search, "Image_Search_BG", {x = 0, y = 0, w = 200, h = 470})
	Image_Search_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",50)
	Image_Search_BG:SetImageType(10)

	local Image_Search_BG1 = self:Append("Image", hHandle_Search, "Image_Search_BG1", {x = 0, y = 30, w = 200, h = 440})
	Image_Search_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",74)
	Image_Search_BG1:SetImageType(10)
	Image_Search_BG1:SetAlpha(110)

	local Image_Search_Line1_0 = self:Append("Image", hHandle_Search, "Image_Search_Line1_0", {x = 3, y = 28, w = 200, h = 3})
	Image_Search_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",65)
	Image_Search_Line1_0:SetImageType(11)
	Image_Search_Line1_0:SetAlpha(115)

	local Text_Search_break2 = self:Append("Text", hHandle_Search, "Text_Search_break2", {w = 200, h = 30, x  = 0, y = 2, text = _L["Search+History"], font = 18})
	Text_Search_break2:SetHAlign(1)
	Text_Search_break2:SetVAlign(1)

	----------搜索
	local hEditBox_Search = self:Append("Edit", frame, "hEditBox_Search", {w = 187 ,h = 26, x = 744, y = 120, text = ""})
	hEditBox_Search:Enable(true)
	hEditBox_Search.OnMouseEnter = function()
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml  = GetFormatText(_L["Enter name or id"],0,255,128,0)
		OutputTip(szXml,350,{x,y,w,h})
	end
	hEditBox_Search.OnMouseLeave = function()
		HideTip()
	end
	hEditBox_Search.OnChange = function(value)
		local searchText = value or ""
		searchText = string.gsub(searchText," ","")
		searchText = LR.Trim(searchText)
		LR_TeamBuffTool_Panel.szSearchText = searchText

		self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
		self:LoadSearchResultBox()
	end
	self:LoadSearchResultBox()

	----------添加分组
	local hButton_add_Group = self:Append("Button", frame, "hButton_add_Group" , {w = 196, x = 17, y = 562, text = _L["Add group"]})
	hButton_add_Group:Enable(true)
	hButton_add_Group.OnClick = function()
		self:addGroup()
	end

	--打开log管理器
	local hButton_EdgeOpen = self:Append("Button", frame, "hButton_EdgeOpen" , {w = 150, x = 580, y = 562, text = _L["Open log"]})
	hButton_EdgeOpen:Enable(true)
	hButton_EdgeOpen.OnClick = function()
		LR_FIGHT_LOG.OpenFrame()
	end

	----------打开边角管理器
	local hButton_LogOpen = self:Append("Button", frame, "hButton_LogOpen" , {w = 196, x = 740, y = 562, text = _L["Open EdgeIndicator"]})
	hButton_LogOpen:Enable(true)
	hButton_LogOpen.OnClick = function()
		LR_EdgeIndicator_Panel.OpenFrame()
	end

	----------关于
	LR.AppendAbout(nil, frame)
end

function LR_TeamBuffTool_Panel:Open()
	local frame = self:Fetch("LR_TeamBuffTool_Panel")
	if frame then
		self:Destroy(frame)
	else
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
end

function LR_TeamBuffTool_Panel:checkGroup(szGroupName)
	for k, v in pairs(LR_TeamBuffTool.tBuffList) do
		if v.szGroupName == szGroupName then
			return true
		end
	end
	return false
end

function LR_TeamBuffTool_Panel:addGroup()
	local me = GetClientPlayer()
	if not me then
		return
	end
	GetUserInput(_L["Group name"], function(szText)
		local szText =  LR.Trim(string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1"))
		if szText ~=  "" then
			if LR_TeamBuffTool_Panel:checkGroup(szText) then
				LR.SysMsg(_L["Group existed.\n"])
			else
				tinsert(LR_TeamBuffTool.tBuffList, {szGroupName = szText, enable = true, data = {}, order = 9999})
			end
			------刷新Group
			self:LoadGroupBox()
			LR_TeamBuffTool:SaveData()
		end
	end)
end

function LR_TeamBuffTool_Panel:delGroup(szGroupName)
	local msg =
	{	szMessage = GetFormatText(sformat(_L["Sure to delete group: %s ?"], szGroupName)),
		bRichText = true,
		szName = "DelGroup",
		{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction =
			function()
				for k, v in pairs(LR_TeamBuffTool.tBuffList) do
					if type(v) == "table" then
						if v.szGroupName == szGroupName then
							tremove(LR_TeamBuffTool.tBuffList, k)
						end
					end
				end
				self:LoadGroupBox()
				LR_TeamBuffTool:SaveData()
			end
		},
		{szOption = g_tStrings.STR_HOTKEY_CANCEL},
	}
	MessageBox(msg)
end

function LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
	local data, k = LR_TeamBuffTool_Panel:GetGroupData(szGroupName)
	if LR_TeamBuffTool_Panel.LoadType == "by dungeon" then
		local data = LR_Team_Map[szGroupName]
		for key, v in pairs(data.data) do
			if v.dwID == buff.dwID and v.nLevel == buff.nLevel then
				LR_Team_Map[szGroupName].data[key] = clone(buff)
				LR_TeamBuffTool.SaveData()
			end
		end
	else
		if k > 0 then
			local data = LR_TeamBuffTool.tBuffList[k]
			for key, v in pairs(data.data) do
				if v.dwID == buff.dwID and v.nLevel == buff.nLevel then
					LR_TeamBuffTool.tBuffList[k][key] = clone(buff)
					LR_TeamBuffTool.SaveData()
				end
			end
		end
	end
end

function LR_TeamBuffTool_Panel:modifyGroup(szGroupName, GroupData)
	local data, k = LR_TeamBuffTool_Panel:GetGroupData(szGroupName)
	if k > 0 then
		local data = LR_TeamBuffTool.tBuffList[k]
		data.enable = GroupData.enable
		data.szGroupName = GroupData.szGroupName
		LR_TeamBuffTool.SaveData()
	end
end

function LR_TeamBuffTool_Panel:addBuff()
	if LR_TeamBuffTool_Panel.szChooseGroupName == "" then
		return
	end
	local data, k = LR_TeamBuffTool_Panel:GetGroupData(LR_TeamBuffTool_Panel.szChooseGroupName)
	local bAddBuff = LR_TeamBuffTool_Panel.bAddBuff
	if LR_TeamBuffTool_Panel.IsBuffInMonitor(bAddBuff, data) then
		LR.SysMsg(_L["Buff exisited.\n"])
		LR_TeamBuffTool.SaveData()
		self:LoadBuffListBox()
		return
	end
	bAddBuff.enable = true
	local buff = LR_TeamBuffTool.FormatBuff(bAddBuff)
	if LR_TeamBuffTool_Panel.LoadType == "by dungeon" then
		tinsert(LR_Team_Map[LR_TeamBuffTool_Panel.szChooseGroupName].data, buff)
	else
		tinsert(LR_TeamBuffTool.tBuffList[k].data, buff)
	end
	self:LoadBuffListBox()
	self:RefreshBuffNum(LR_TeamBuffTool_Panel.szChooseGroupName)
	LR_TeamBuffTool.SaveData()
	return buff
end

function LR_TeamBuffTool_Panel:delBuff(buff, szGroupName)
	local msg =
	{	szMessage = GetFormatText(sformat(_L["Sure delete buff: %s"], Table_GetBuffName(buff.dwID, buff.nLevel))),
		bRichText = true,
		szName = "LoadSettings",
		{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()
			local GroupData, k = LR_TeamBuffTool_Panel:GetGroupData(szGroupName)

			if LR_TeamBuffTool_Panel.LoadType == "by dungeon" then
				local data = LR_Team_Map[k] or {}
				for key, v in pairs(data.data) do
					if v.dwID == buff.dwID and v.nLevel == buff.nLevel then
						tremove(LR_Team_Map[k].data, key)
					end
				end
			else
				if k > 0 then
					local data = LR_TeamBuffTool.tBuffList[k]
					for key, v in pairs(data.data) do
						if v.dwID == buff.dwID and v.nLevel == buff.nLevel then
							tremove(LR_TeamBuffTool.tBuffList[k].data, key)

						end
					end
				end
			end
			self:LoadBuffListBox()
			self:RefreshBuffNum(szGroupName)
			LR_TeamBuffTool.SaveData()
		end,},
		{szOption = g_tStrings.STR_HOTKEY_CANCEL},
	}
	MessageBox(msg)
end


function LR_TeamBuffTool_Panel.IsBuffInMonitor(buff, data)
	for k,v in pairs (data.data) do
		if v.dwID == buff.dwID and v.nLevel == buff.nLevel then
			return true
		end
	end
	return false
end

function LR_TeamBuffTool_Panel:LoadGroupBox()
	local me =  GetClientPlayer()
	if not me then
		return
	end
	local ScrollGroupBox = self:Fetch("ScrollGroupBox")
	if not ScrollGroupBox then
		return
	end
	self:ClearHandle(ScrollGroupBox)

	if LR_TeamBuffTool_Panel.LoadType == "by dungeon" then
		for k, v in pairs(LR_Team_Map_Sorted) do
			local Handle_Version = self:Append("Handle", ScrollGroupBox, sformat("hGroup_%s", v.szVersionName), {x = 0, y = 0, w = 196, h = 40, eventid = 524596})
			local Image_Version_BG = self:Append("Image", Handle_Version, sformat("Image_Version_BG_%s", v.szVersionName), {x = 3, y = 0, w = 193, h = 40})
			Image_Version_BG:FromUITex("UI/Image/UICommon/CommonPanel2.uitex", 12):SetImageType(0)
			local Text_Version = self:Append("Text", Handle_Version, sformat("Text_Version_%s", v.szVersionName), {w = 150, h = 40, x  = 15, y = 2, text = v.szVersionName, font = 18})
			local m = 0
			if not v.fold then
				for k2, v2 in pairs(v.data) do
					self:LoadDungeonGroupBox(v2, m)
					m = m + 1
				end
			end
			Handle_Version.OnClick = function()
				v.fold = not v.fold
				self:LoadGroupBox()
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
		local m = 1
		local List = LR_TeamBuffTool.tBuffList or {}
		tsort(List, function(a, b) return a.order < b.order end)

		for k, v in pairs (List) do
			if type(v) == "table" then
				if m == 1 then
					LR_TeamBuffTool_Panel.szChooseGroupName = v.szGroupName
					local szKey = tostring(GetStringCRC(v.szGroupName))
					LR_TeamBuffTool_Panel.szChooseGroup = sformat("Image_GroupSelect_%s", szKey)
				end
				LR_TeamBuffTool_Panel:LoadOneGroupBox(v, m)
				m = m + 1
			end
		end
	end
	ScrollGroupBox:UpdateList()
end

function LR_TeamBuffTool_Panel:RefreshBuffNum(szName)
	if LR_TeamBuffTool_Panel.LoadType == "by dungeon" then
		local Text = self:Fetch(sformat("Text_Group_Name_%s", szName))
		if Text then
			Text:SetText(sformat("%s ( %d )", szName, #LR_Team_Map[szName].data))
		end
	else
		sformat("Text_CustomGroup_%s", szName)
		local Text = self:Fetch(sformat("Text_CustomGroup_%s", szName))
		if Text then
			local data, k = LR_TeamBuffTool_Panel:GetGroupData(szName)
			Text:SetText(sformat("%s ( %d )", szName, #data.data))
		end
	end
end


function LR_TeamBuffTool_Panel:LoadDungeonGroupBox(GroupData, m)
	local ScrollGroupBox = self:Fetch("ScrollGroupBox")
	if not ScrollGroupBox then
		return
	end
	local v = clone(GroupData)

	if true then
		local hGroupDungeon = self:Append("Handle", ScrollGroupBox, sformat("hGroup_%s", v.szOtherName), {x = 0, y = 0, w = 196, h = 40, eventid = 524596})
		local Image_Line = self:Append("Image", hGroupDungeon, sformat("Image_Line_%s", v.szOtherName), {x = 0, y = 0, w = 196, h = 40})
		Image_Line:FromUITex("ui\\Image\\UICommon\\CommonPanel.UITex", 48):SetImageType(10):SetAlpha(200)
		if m % 2 == 0 then
			Image_Line:SetAlpha(35)
		end

		--悬停框
		local Image_Hover = self:Append("Image", hGroupDungeon, sformat("Image_GroupHover_%s", v.szOtherName), {x = 0, y = 0, w = 190, h = 40})
		Image_Hover:FromUITex("ui\\Image\\Common\\TempBox.UITex",5)
		Image_Hover:SetImageType(10)
		Image_Hover:SetAlpha(200)
		Image_Hover:Hide()

		--选择框
		local Image_Select = self:Append("Image", hGroupDungeon, sformat("Image_GroupSelect_%s", v.szOtherName), {x = 2, y = 0, w = 190, h = 40})
		Image_Select:FromUITex("ui\\Image\\Common\\TempBox.UITex",6)
		Image_Select:SetImageType(10)
		Image_Select:SetAlpha(200)
		Image_Select:Hide()
		if LR_TeamBuffTool_Panel.szChooseGroup == sformat("Image_GroupSelect_%s", v.szOtherName) then
			local Image_Select = self:Fetch(sformat("Image_GroupSelect_%s", v.szOtherName))
			if Image_Select then
				Image_Select:Show()
			end
		end

		local Image_Group_Level = self:Append("Image", hGroupDungeon, sformat("Image_Group_Level_%s", v.szOtherName), {x = 5, y = 2, w = 36, h = 36})
		if v.level == 1 then
			Image_Group_Level:FromUITex("ui/image/uitga/desertstorm.UITex", 8):SetImageType(0):SetAlpha(200)
		else
			Image_Group_Level:FromUITex("ui/image/uitga/desertstorm.UITex", 1):SetImageType(0):SetAlpha(200)
		end
		local Text_Group_Name = self:Append("Text", hGroupDungeon, sformat("Text_Group_Name_%s", v.szOtherName), {w = 150, h = 40, x  = 50, y = 2, text = v.szOtherName, font = 18})
		Text_Group_Name:SetText(sformat("%s ( %d )", v.szOtherName, #LR_Team_Map[v.szOtherName].data))

		hGroupDungeon.OnEnter = function()
			local Image_Hover = self:Fetch(sformat("Image_GroupHover_%s", v.szOtherName))
			if Image_Hover then
				Image_Hover:Show()
			end
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
			local Image_Hover = self:Fetch(sformat("Image_GroupHover_%s", v.szOtherName))
			if Image_Hover then
				Image_Hover:Hide()
			end
			HideTip()
		end
		hGroupDungeon.OnClick = function()
			if LR_TeamBuffTool_Panel.szChooseGroup then
				local Image_Select = self:Fetch(LR_TeamBuffTool_Panel.szChooseGroup)
				if Image_Select then
					Image_Select:Hide()
				end
			end
			LR_TeamBuffTool_Panel.szChooseGroup = sformat("Image_GroupSelect_%s", v.szOtherName)
			LR_TeamBuffTool_Panel.szChooseGroupName = v.szOtherName
			local Image_Select = self:Fetch(LR_TeamBuffTool_Panel.szChooseGroup)
			if Image_Select then
				Image_Select:Show()
			end

			if LR_TeamBuffTool_Panel.bMapData then
				self:ClearHandle(self:Fetch("ScrollSearchBuffBox"))
				self:LoadSearchResultBox()
			end
			------刷新BuffList
			self:LoadBuffListBox()
		end
	end
end


function LR_TeamBuffTool_Panel:LoadOneGroupBox(GroupData, m)
	local ScrollGroupBox = self:Fetch("ScrollGroupBox")
	if not ScrollGroupBox then
		return
	end
	local v = clone(GroupData)
	local szKey = tostring(GetStringCRC(v.szGroupName))
	local hIconViewContent = self:Fetch(sformat("hGroup_%s", szKey))
	if hIconViewContent then
		self:ClearHandle(hIconViewContent)
	end

	if true then
		hIconViewContent = self:Append("Handle", ScrollGroupBox, sformat("hGroup_%s", szKey), {x = 0, y = 0, w = 196, h = 40, eventid = 524596})
		local Image_Line = self:Append("Image", hIconViewContent, "Image_Line"..m, {x = 0, y = 0, w = 196, h = 40})
		Image_Line:FromUITex("ui\\Image\\UICommon\\CommonPanel.UITex", 48)
		Image_Line:SetImageType(10)
		Image_Line:SetAlpha(200)
		if m%2 == 0 then
			Image_Line:SetAlpha(35)
		end

		--允许框
		local Image_Enable = self:Append("Image", hIconViewContent, sformat("Image_GroupEnable_%s", szKey), {x = 5, y = 2, w = 36, h = 36, eventid = 272})
		Image_Enable:SetImageType(10)
		if v.enable then
			--Image_Enable:FromIconID(6933)
			Image_Enable:FromUITex("ui/Image/GMPanel/gm2.UITex", 7)
		else
			--Image_Enable:FromIconID(6942)
			Image_Enable:FromUITex("ui/Image/GMPanel/gm2.UITex", 6)
		end
		Image_Enable.OnClick = function()
			v.enable = not v.enable
			local Image_GroupEnable = self:Fetch(sformat("Image_GroupEnable_%s", szKey))
			if Image_GroupEnable then
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
			LR_TeamBuffTool_Panel:modifyGroup(v.szGroupName, v)
		end

		--悬停框
		local Image_Hover = self:Append("Image", hIconViewContent, sformat("Image_GroupHover_%s", szKey), {x = 0, y = 0, w = 190, h = 40})
		Image_Hover:FromUITex("ui\\Image\\Common\\TempBox.UITex",5)
		Image_Hover:SetImageType(10)
		Image_Hover:SetAlpha(200)
		Image_Hover:Hide()

		--选择框
		local Image_Select = self:Append("Image", hIconViewContent, sformat("Image_GroupSelect_%s", szKey), {x = 2, y = 0, w = 190, h = 40})
		Image_Select:FromUITex("ui\\Image\\Common\\TempBox.UITex",6)
		Image_Select:SetImageType(10)
		Image_Select:SetAlpha(200)
		Image_Select:Hide()
		if LR_TeamBuffTool_Panel.szChooseGroupName == v.szGroupName then
			local Image_Select = self:Fetch(sformat("Image_GroupSelect_%s", szKey))
			if Image_Select then
				Image_Select:Show()
			end
		end

		--分组名称
		local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_CustomGroup_%s", v.szGroupName), {w = 150, h = 40, x  = 50, y = 2, text = v.szGroupName, font = 18})
		Text_break2:SetHAlign(0):SetVAlign(1):SetText(sformat("%s ( %d )", v.szGroupName, #v.data))

		--鼠标操作
		hIconViewContent.OnClick = function()
			if LR_TeamBuffTool_Panel.szChooseGroup then
				local Image_Select = self:Fetch(LR_TeamBuffTool_Panel.szChooseGroup)
				if Image_Select then
					Image_Select:Hide()
				end
			end
			LR_TeamBuffTool_Panel.szChooseGroup = sformat("Image_GroupSelect_%s", szKey)
			LR_TeamBuffTool_Panel.szChooseGroupName = v.szGroupName
			local Image_Select = self:Fetch(LR_TeamBuffTool_Panel.szChooseGroup)
			if Image_Select then
				Image_Select:Show()
			end

			------刷新BuffList
			self:LoadBuffListBox()
		end

		hIconViewContent.OnRClick = function()
			local fx, fy = this:GetAbsPos()
			local nW, nH = this:GetSize()
			local m = {}
			m[#m + 1] = { szOption = _L["Delete"], fnAction = function() LR_TeamBuffTool_Panel:delGroup(v.szGroupName) end,}
			PopupMenu(m, {fx, fy, nW, nH})
		end

		hIconViewContent.OnEnter = function()
			local Image_Hover = self:Fetch(sformat("Image_GroupHover_%s", szKey))
			if Image_Hover then
				Image_Hover:Show()
			end

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

		hIconViewContent.OnLeave = function()
			local Image_Hover = self:Fetch(sformat("Image_GroupHover_%s", szKey))
			if Image_Hover then
				Image_Hover:Hide()
			end
			HideTip()
		end

		Image_Enable.OnEnter = function()
			hIconViewContent.OnEnter()
		end

		Image_Enable.OnLeave = function()
			hIconViewContent.OnLeave()
		end
	end
	ScrollGroupBox:UpdateList()
end

local _ResulUI = {}
function LR_TeamBuffTool_Panel:LoadSearchResultBox()
	local me = GetClientPlayer()
	if not me then
		return
	end

	local m = 0
	local hWin = self:Fetch("ScrollSearchBuffBox")
	if not hWin then
		return
	end
	ResultBoxHover_Cache = {}
	hWin:ClearHandle()

	_ResulUI = {}
	local szSearchText = LR_TeamBuffTool_Panel.szSearchText or ""
	if szSearchText ==  "" then
		if LR_TeamBuffTool_Panel.bMapData and LR_TeamBuffTool_Panel.LoadType == "by dungeon" then
			if LR_TeamBuffTool_Panel.szChooseGroupName and LR_TeamBuffTool_Panel.szChooseGroupName ~= "" then
				local path = sformat("%s\\BUFF_CACHE\\%s.dat", SaveDataPath, LR_TeamBuffTool_Panel.szChooseGroupName)
				local data = LoadLUAData(path) or {}
				BUFF_CACHE_MAP_TEMP = clone(data)
				for k, v in pairs(data) do
					local flag = false
					for k2, v2 in pairs(v.caster) do
						if v2.szName == LR_TeamBuffTool_Panel.szCasterName then
							flag = true
						end
					end

					if LR_TeamBuffTool_Panel.szCasterName == "" or flag then
						if LR_TeamBuffTool_Panel:ResultBoxLoadOneBuff(false, v, m, "h") then
							m = m + 1
						end
					end
				end
				hWin:UpdateList()
			end
			return
		else
			if LR_TeamBuffTool_Panel.bShowLogByFight then
				for k, v in pairs(BUFF_FIGHT_LOAD) do
					local flag = false
					for k2, v2 in pairs(v.caster) do
						if v2.szName == LR_TeamBuffTool_Panel.szCasterName then
							flag = true
						end
					end

					if LR_TeamBuffTool_Panel.szCasterName == "" or flag then
						if LR_TeamBuffTool_Panel:ResultBoxLoadOneBuff(false, v, m, "h") then
							m = m + 1
						end
					end
				end
				hWin:UpdateList()
				return
			elseif LR_TeamBuffTool_Panel.bShowMapBuffCache then
				for k, v in pairs(BUFF_CACHE_MAP) do
					local flag = false
					for k2, v2 in pairs(v.caster) do
						if v2.szName == LR_TeamBuffTool_Panel.szCasterName then
							flag = true
						end
					end

					if LR_TeamBuffTool_Panel.szCasterName == "" or flag then
						if LR_TeamBuffTool_Panel:ResultBoxLoadOneBuff(false, v, m, "h") then
							m = m + 1
						end
					end
				end
				hWin:UpdateList()
				return
			else
				for i = 1, 1000, 1 do
					if BUFF_CACHE[i] then
						if LR_TeamBuffTool_Panel.szCasterName == "" or LR_TeamBuffTool_Panel.szCasterName == BUFF_CACHE[i].szCasterName then
							if LR_TeamBuffTool_Panel:ResultBoxLoadOneBuff(false, BUFF_CACHE[i], m, "h") then
								m = m + 1
							end
						end
					end
				end
				hWin:UpdateList()
				return
			end
		end
	end

	self:ClearHandle(hWin)
	for i = 1, 1000, 1 do
		if BUFF_CACHE[i] then
			if LR_TeamBuffTool_Panel.szCasterName == "" or LR_TeamBuffTool_Panel.szCasterName == BUFF_CACHE[i].szCasterName then
				if type(tonumber(szSearchText)) ==  "number" then
					if tonumber(szSearchText) == BUFF_CACHE[i].dwID then
						if LR_TeamBuffTool_Panel:ResultBoxLoadOneBuff(false, BUFF_CACHE[i], m, "h") then
							m = m + 1
						end
					end
				else
					local szName = Table_GetBuffName(BUFF_CACHE[i].dwID, BUFF_CACHE[i].nLevel)
					local _s, _e = sfind(szName, szSearchText)
					if _s then
						if LR_TeamBuffTool_Panel:ResultBoxLoadOneBuff(false, BUFF_CACHE[i], m, "h") then
							m = m + 1
						end
					end
				end
			end
		end
	end

	local _cache = {}
	LR_TeamBuffTool_Panel:ResultBoxBreakLine(hWin)
	local RowCount = g_tTable.Buff:GetRowCount()
	local i = 3
	while i <= RowCount do
		local t = g_tTable.Buff:GetRow(i)
		local szName = t.szName or ""
		local dwBuffID = t.dwBuffID
		local nLevel = t.nLevel
		local bShow = false
		if type(tonumber(szSearchText)) ==  "number" then
			if dwBuffID == tonumber(szSearchText) then
				bShow = true
			end
		else
			local _start,_end = string.find(szName,szSearchText)
			if _start and szName ~=  "" then
				bShow = true
			end
		end
		if _cache[dwBuffID] then
			bShow = false
		end
		local szKey = sformat("%s_%d_%d", "b", dwBuffID, nLevel or 1)
		if _ResulUI[szKey] then
			bShow = false
		end

		if bShow then
			local buff = {dwID = dwBuffID, nLevel = nLevel or 1}
			if LR_TeamBuffTool_Panel:ResultBoxLoadOneBuff(nil, buff, m, "b") then
				m = m + 1
			end
			_cache[dwBuffID] = true
		end
		i = i + 1
	end
	hWin:UpdateList()
end

function LR_TeamBuffTool_Panel:ResultBoxBreakLine(hWin)
	-----背景条
	local hBuffSearch = LR.AppendUI("Handle", hWin, "hBuffSearch_break", {x = 0, y = 0, w = 196, h = 30})
	local Image_Line = LR.AppendUI("Image", hBuffSearch, "Image_BuffLine_break", {x = 0, y = 0, w = 196, h = 30})
	Image_Line:FromUITex("ui\\Image\\UICommon\\CommonPanel2.UITex", 14)
	Image_Line:SetImageType(10)
	Image_Line:SetAlpha(200)
	local Text = LR.AppendUI("Text", hBuffSearch, "Text_BuffLine_break", {x = 5, y = 0, w = 186, h = 30})
	Text:SetText(_L["Database below"]):SetVAlign(1):SetHAlign(0)
end

function LR_TeamBuffTool_Panel:ResultBoxLoadOneBuff(bring2top, buff, m, head)
	local hWin = self:Fetch("ScrollSearchBuffBox")
	if not hWin then
		return false
	end

	if not LR_TeamBuffTool_Panel.CanBuffShow(buff) then
		return false
	end

	local szKey = sformat("%s_%d_%d_%d_%d", head, buff.dwID, buff.nLevel, GetTickCount(), Random(99999))
	local Handle_Buff = nil --self:Fetch(sformat("hBuffSearch_%s", szKey))

	if not Handle_Buff then
		-----背景条
		Handle_Buff = hWin:AppendItemFromIni(sformat("%s\\UI\\Handle2.ini", AddonPath), "Handle_Buff", "Handle_Buff")

		local Image_BG = Handle_Buff:Lookup("Image_BG")
		local Text_Name = Handle_Buff:Lookup("Text_Name")
		local Image_Icon = Handle_Buff:Lookup("Image_Icon")
		if m % 2 == 0 then
			Image_BG:SetAlpha(35)
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

		Handle_Buff.OnItemRButtonClick = function()
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
		end

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
				if mceil(buff.nTotalFrame  / 16.0) <= 120 then
					tip[#tip + 1] = GetFormatText(sformat(_L["Total time:%fs\n"], mceil(buff.nTotalFrame / 16.0)))
				end

				if LR_TeamBuffTool_Panel.bShowMapBuffCache then
					tip[#tip + 1] = GetFormatText(_L["From :\n"])
					for k6, v6 in pairs(buff.caster) do
						if v6.nType == TARGET.NPC then
							tip[#tip + 1] = GetFormatText(sformat("%s(#%d) %s\n", v6.szName, v6.dwTemplateID, Table_GetMapName(v6.dwMapID)))
						else
							tip[#tip + 1] = GetFormatText(sformat(_L["%s (Player) %s\n"], v6.szName, Table_GetMapName(v6.dwMapID)))
						end
					end
				else
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
			LR_TeamBuffTool_Panel.bDraged = true
			LR_TeamBuffTool_Panel.bAddBuff = buff
			LR_TeamBuffTool.OpenBuffBoxPanel(buff)
		end

		Handle_Buff.OnItemLButtonDragEnd = function()
			LR_TeamBuffTool.CloseBuffBoxPanel()
			if LR_TeamBuffTool_Panel.bAdd then
				if LR_TeamBuffTool_Panel.szChooseGroupName ~= "" then
					LR_TeamBuffTool_Panel:addBuff()
				end
			end
			LR_TeamBuffTool_Panel.bDraged = false
			LR_TeamBuffTool_Panel.bAddBuff = nil
		end
	end
	if bring2top then
		Handle_Buff:SetIndex(0)
		hWin:UpdateList()
		for kkk = hWin:GetItemCount(), 10, -1 do
			hWin:RemoveItem(kkk)
		end
	end
	hWin:UpdateList()
	return true
end

function LR_TeamBuffTool_Panel:GetGroupData(szChooseGroupName)
	if LR_TeamBuffTool_Panel.LoadType == "by dungeon" then
		return LR_Team_Map[szChooseGroupName] or {}, szChooseGroupName
	else
		for k, v in pairs(LR_TeamBuffTool.tBuffList) do
			if type(v) == "table" then
				if v.szGroupName == szChooseGroupName then
					return v, k
				end
			end
		end
	end
	return {}, 0
end

function LR_TeamBuffTool_Panel:LoadBuffListBox()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local ScrollBuffListBox = self:Fetch("ScrollBuffListBox")
	if not ScrollBuffListBox then
		return
	end
	self:ClearHandle(ScrollBuffListBox)
	if LR_TeamBuffTool_Panel.szChooseGroupName == "" then
		ScrollBuffListBox:UpdateList()
		return
	end
	local tBuffList = LR_TeamBuffTool_Panel:GetGroupData(LR_TeamBuffTool_Panel.szChooseGroupName)
	local szChooseGroupName = LR_TeamBuffTool_Panel.szChooseGroupName
	local t = tBuffList.data

	for k, v in pairs(t) do
		---BUFF框架
		LR_TeamBuffTool_Panel:DrawOneBuffBox(szChooseGroupName, v)
	end
	ScrollBuffListBox:UpdateList()
end

function LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
	local ScrollBuffListBox = self:Fetch("ScrollBuffListBox")
	if not ScrollBuffListBox then
		return
	end
	local szKey = sformat("%s_%d_%d", tostring(GetStringCRC(szGroupName)), buff.dwID, buff.nLevel)
	local hBuffList = self:Fetch(sformat("hBuff_%s", szKey))
	if not hBuffList then
		hBuffList = self:Append("Handle", ScrollBuffListBox, sformat("hBuff_%s", szKey), {x = 0, y = 0, w = 160, h = 100, eventid = 304})
		hBuffList:SetIndex(0)
	end
	--local hBuffList = self:Append("Handle", ScrollBuffListBox, sformat("hBuff_%s", szKey), {x = 0, y = 0, w = 160, h = 100, eventid = 304})
	if hBuffList then
		self:ClearHandle(hBuffList)
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


		--悬停框
		local Image_Hover = self:Append("Image", hBuffList, sformat("Image_BuffListHover_%s", szKey), {x = 0, y = 0, w = 160, h = 100})
		Image_Hover:FromUITex("ui\\Image\\Common\\TempBox.UITex",5):SetImageType(10):SetAlpha(200):Hide()

		--选择框
		local Image_Select = self:Append("Image", hBuffList, sformat("Image_BuffListSelect_%s", szKey), {x = 2, y = 0, w = 160, h = 100})
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
			LR_Team_Buff_Setting_Panel:Open(szGroupName, buff)
		end

		hBuffList.OnRClick = function()
			local fx, fy = this:GetAbsPos()
			local nW, nH = this:GetSize()
			local m = {}
			m[#m + 1] = {szOption = _L["Delete"], fnAction = function() LR_TeamBuffTool_Panel:delBuff(buff, szGroupName) end,}

			PopupMenu(m, {fx, fy, nW, nH})
		end

		hBuffList.OnEnter = function()
			local Image_Hover = self:Fetch(sformat("Image_BuffListHover_%s", szKey))
			if Image_Hover then
				Image_Hover:Show()
			end
			local fx, fy = this:GetAbsPos()
			local nW, nH = this:GetSize()
			LR.OutputBuffTip(buff.dwID, buff.nLevel, {fx, fy, nW, nH})
		end

		hBuffList.OnLeave = function()
			local Image_Hover = self:Fetch(sformat("Image_BuffListHover_%s", szKey))
			if Image_Hover then
				Image_Hover:Hide()
			end
			HideTip()
		end
	end
end

-----------------------------
function LR_TeamBuffTool.OpenBuffBoxPanel(buff)
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

function LR_TeamBuffTool.CloseBuffBoxPanel()
	local hFrame = Station.Lookup("Normal/LR_BuffBox")
	if hFrame then
		hFrame:EndMoving()
		Wnd.CloseWindow(hFrame)
	end
end

----------------------------------
local dwMapID_now = 0

local NPC_BUFF_CACHE = {}
function LR_TeamBuffTool.MonitorTargetNPC()
	if not LR_TeamBuffTool_Panel.bOnCollect then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local _type, _dwID = me.GetTarget()
	if _type ~= TARGET.NPC then
		return
	end
	local npc = GetNpc(_dwID)
	if not npc then
		return
	end
	NPC_BUFF_CACHE[_dwID] = NPC_BUFF_CACHE[_dwID] or {}
	local buff_list = LR.GetBuffList(npc)
	for k, v in pairs(buff_list) do
		if not NPC_BUFF_CACHE[_dwID][v.nIndex] then
			NPC_BUFF_CACHE[_dwID][v.nIndex] = clone(v)
			if (not LR_TeamBuffTool_Panel.bCollectHideBuff and not Table_BuffIsVisible(v.dwID, v.nLevel)) then
				--
			else
				if v.dwSkillSrcID == 0 or not IsPlayer(v.dwSkillSrcID) then
					local szKey = sformat("%d_%d", v.dwID, v.nLevel)
					BUFF_CACHE_MAP[szKey] = BUFF_CACHE_MAP[szKey] or {dwID = v.dwID, nLevel = v.nLevel, target_type = TARGET.NPC, caster = {}, temp_caster = {}, nMaxStackNum = 0, nTotalFrame = v.nEndFrame - GetLogicFrameCount()}
					BUFF_CACHE_MAP[szKey].nMaxStackNum = mmax(BUFF_CACHE_MAP[szKey].nMaxStackNum, v.nStackNum)
					if v.dwSkillSrcID == 0 then
						BUFF_CACHE_MAP[szKey].caster[sformat("%s_%d", "0", dwMapID_now)] = {szName = "NPC#0", dwTemplateID = 0, dwMapID = dwMapID_now, nType = TARGET.NPC}
					else
						local szCasterName, obj = LR_TeamTools.DeathRecord.GetName(TARGET.NPC, v.dwSkillSrcID)
						if obj then
							BUFF_CACHE_MAP[szKey].caster[sformat("%d_%d", obj.dwTemplateID, obj.dwMapID)] = clone(obj)
						else
							BUFF_CACHE_MAP[szKey].temp_caster = BUFF_CACHE_MAP[szKey].temp_caster or {}
							BUFF_CACHE_MAP[szKey].temp_caster[tostring(v.dwSkillSrcID)] = true
						end
					end
					LR_TeamBuffTool_Panel:ResultBoxLoadOneBuff(true, BUFF_CACHE_MAP[szKey], 1, "h")

					local szCasterName, obj, nType = "", nil, TARGET.NPC
					if IsPlayer(dwCaster) then
						szCasterName, obj = LR_TeamTools.DeathRecord.GetName(TARGET.PLAYER, dwCaster)
						nType = TARGET.PLAYER
					else
						szCasterName, obj = LR_TeamTools.DeathRecord.GetName(TARGET.NPC, dwCaster)
					end
					local data = {
						dwID = v.dwID,
						nLevel = v.nLevel,
						bCanCancel = v.bCanCancel,
						nStackNum = v.nStackNum,
						bDelete = false,
						bHideBuff = false,
						bFresh = false,
						caster = {},
						temp_caster = {},
						szCasterName = "",
						target_type = TARGET.NPC,
						nTotalFrame = v.nEndFrame - GetLogicFrameCount(),
					}
					if not Table_BuffIsVisible(v.dwID, v.nLevel) then
						data.bHideBuff = true
					end

					local dwCaster = v.dwSkillSrcID
					if not IsPlayer(dwCaster) then
						if obj then
							data.caster[sformat("d_%d", dwCaster, dwMapID_now)] = {szName = szCasterName, dwTemplateID = obj.dwTemplateID, nIntensity = obj.nIntensity, dwMapID = dwMapID_now, nType = TARGET.NPC}
						else
							data.temp_caster[tostring(dwCaster)] = {dwMapID = dwMapID_now, nType = TARGET.NPC, dwID = dwCaster}
						end
					else
						if obj then
							data.caster[sformat("%d_%d", dwCaster, dwMapID_now)] = {szName = szCasterName, dwMapID = dwMapID_now, dwID = dwCaster, dwForceID = obj.dwForceID, nType = TARGET.PLAYER}
						else
							data.temp_caster[tostring(dwCaster)] = {dwMapID = dwMapID_now, nType = TARGET.PLAYER, dwID = dwCaster}
						end
					end
					tinsert(BUFF_CACHE, data)
					if not LR_TeamBuffTool_Panel.bShowMapBuffCache then
						LR_TeamBuffTool_Panel:ResultBoxLoadOneBuff(true, data, 1, "h")
					end
					if KEY ~= "" then
						data.nTime = GetTickCount() - BEGIN_TIME
						tinsert(BUFF_FIGHT_CACHE[KEY], data)
					end
				end
			end
		end
	end

end
LR.BreatheCall("MonitorTargetNPC", function() LR_TeamBuffTool.MonitorTargetNPC() end)

--bInit 必定是dwID, dwCaster = 0, 官方原来的意思就是为true时，刷新dwPlayerID、或者触发某些frame的刷新
function LR_TeamBuffTool.BUFF_UPDATE()
	if not LR_TeamBuffTool_Panel.bOnCollect then
		return
	end

	local dwPlayerID, bDelete, nIndex, bCanCancel, dwID, nStackNum, nEndFrame, bInit, nLevel, dwCaster, IsValid = arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10

	if (not LR_TeamBuffTool_Panel.bCollectHideBuff and not Table_BuffIsVisible(dwID, nLevel)) or dwID == 0 then
		return
	end
	if IsPlayer(dwCaster) and LR_TeamBuffTool_Panel.bCollectOnlyFromNpc then
		return
	end

	local szCasterName, obj, nType = "", nil, TARGET.NPC
	if IsPlayer(dwCaster) then
		szCasterName, obj = LR_TeamTools.DeathRecord.GetName(TARGET.PLAYER, dwCaster)
		nType = TARGET.PLAYER
	else
		szCasterName, obj = LR_TeamTools.DeathRecord.GetName(TARGET.NPC, dwCaster)
	end

	local szKey = sformat("%d_%d", dwID, nLevel)
	local data = {
		dwID = dwID,
		nLevel = nLevel,
		bCanCancel = bCanCancel,
		nStackNum = nStackNum,
		bDelete = bDelete,
		bHideBuff = false,
		bFresh = true,
		caster = {},
		temp_caster = {},
		szCasterName = szCasterName,
		target_type = TARGET.PLAYER,
		nTotalFrame = nEndFrame - GetLogicFrameCount(),
	}
	BUFF_INDEX_CACHE[tostring(dwPlayerID)] = BUFF_INDEX_CACHE[tostring(dwPlayerID)] or {}
	if not BUFF_INDEX_CACHE[tostring(dwPlayerID)][tostring(nIndex)] then
		data.bFresh = false
		BUFF_INDEX_CACHE[tostring(dwPlayerID)][tostring(nIndex)] = true
	end
	if bDelete then
		data.bFresh = false
	end
	if not Table_BuffIsVisible(dwID, nLevel) then
		data.bHideBuff = true
	end


	if not IsPlayer(dwCaster) then
		if obj then
			data.caster[sformat("d_%d", dwCaster, dwMapID_now)] = {szName = szCasterName, dwTemplateID = obj.dwTemplateID, nIntensity = obj.nIntensity, dwMapID = dwMapID_now, nType = TARGET.NPC}
		else
			data.temp_caster[tostring(dwCaster)] = {dwMapID = dwMapID_now, nType = TARGET.NPC, dwID = dwCaster}
		end
	else
		if obj then
			data.caster[sformat("%d_%d", dwCaster, dwMapID_now)] = {szName = szCasterName, dwMapID = dwMapID_now, dwID = dwCaster, dwForceID = obj.dwForceID, nType = TARGET.PLAYER}
		else
			data.temp_caster[tostring(dwCaster)] = {dwMapID = dwMapID_now, nType = TARGET.PLAYER, dwID = dwCaster}
		end
	end
	tinsert(BUFF_CACHE, data)
	if not LR_TeamBuffTool_Panel.bShowMapBuffCache then
		LR_TeamBuffTool_Panel:ResultBoxLoadOneBuff(true, data, 1, "h")
	end
	if KEY ~= "" then
		data.nTime = GetTickCount() - BEGIN_TIME
		tinsert(BUFF_FIGHT_CACHE[KEY], data)
	end

	if not IsPlayer(dwCaster) or dwCaster == 0 then
		BUFF_CACHE_MAP[szKey] = BUFF_CACHE_MAP[szKey] or {dwID = dwID, bHideBuff = data.bHideBuff, nLevel = nLevel, bDelete = bDelete, bCanCancel = bCanCancel, target_type = TARGET.PLAYER, caster = {}, temp_caster = {}, nMaxStackNum = 0, nTotalFrame = nEndFrame - GetLogicFrameCount()}
		BUFF_CACHE_MAP[szKey].nMaxStackNum = mmax(BUFF_CACHE_MAP[szKey].nMaxStackNum, nStackNum)
		if dwCaster == 0 then
			BUFF_CACHE_MAP[szKey].caster[sformat("%d_%d", 0, dwMapID_now)] = {dwMapID = dwMapID_now, nType = TARGET.PLAYER, dwID = dwCaster, szName = "PLAYER#0"}
		else
			local szCasterName, obj = LR_TeamTools.DeathRecord.GetName(TARGET.NPC, dwCaster)
			if obj then
				BUFF_CACHE_MAP[szKey].caster[sformat("%d_%d", obj.dwTemplateID, obj.dwMapID)] = clone(obj)
			else
				BUFF_CACHE_MAP[szKey].temp_caster[tostring(dwCaster)] = true
			end
		end
		LR_TeamBuffTool_Panel:ResultBoxLoadOneBuff(true, BUFF_CACHE_MAP[szKey], 1, "h")
	end
end

function LR_TeamBuffTool.LOADING_END()
	local me = GetClientPlayer()
	local scene = me.GetScene()
	dwMapID_now = scene.dwMapID
	LR_TeamBuffTool.LoadData()
	LR_TeamBuffTool.LoadBuffCache()
	LR_TeamBuffTool.LoadBuffCacheMap()
end

function LR_TeamBuffTool.ON_FRAME_CREATE()
	local frame = arg0
	local szName = frame:GetName()
	if szName  ==  "ExitPanel" then
		LR_TeamBuffTool.SaveBuffCache()
	elseif szName  ==  "OptionPanel" then
		LR_TeamBuffTool.SaveBuffCache()
	end
end

function LR_TeamBuffTool.BeginLog()
	local me = GetClientPlayer()
	if not me or not me.bFightState then
		return
	end
	KEY = sformat("KEY_%d", GetCurrentTime())
	LOG_TIME = GetCurrentTime()
	BUFF_FIGHT_CACHE[KEY] = {}
	BEGIN_TIME = GetTickCount()
	NearestNPC = LR_TeamTools.DeathRecord.GetNearestNPC()
end

function LR_TeamBuffTool.EndLog()
	if KEY ~= "" then
		LR_TeamBuffTool.SaveBuffCache()
	end
	KEY = ""
	LOG_TIME = 0
	BEGIN_TIME = 0
	NearestNPC = {szName = "#NoNPC", nIntensity = 0, dwTemplateID = 0, distance = 0}
end

function LR_TeamBuffTool.FIGHT_HINT()
	local bFight = arg0
	if not LR_TeamBuffTool_Panel.bOnCollect then
		return
	end

	if bFight then
		LR_TeamBuffTool.BeginLog()
	else
		LR_TeamBuffTool.EndLog()
	end
end

LR.RegisterEvent("BUFF_UPDATE", function() LR_TeamBuffTool.BUFF_UPDATE() end)
LR.RegisterEvent("LOADING_END", function() LR_TeamBuffTool.LOADING_END() end)
LR.RegisterEvent("ON_FRAME_CREATE", function() LR_TeamBuffTool.ON_FRAME_CREATE() end)
LR.RegisterEvent("FIGHT_HINT", function() LR_TeamBuffTool.FIGHT_HINT() end)

---------------------------------------------------------------
---ini配置文件多重窗口 单BUFF设置
---------------------------------------------------------------
LR_Team_Buff_Base = class()
function LR_Team_Buff_Base.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")

	this:Lookup("Btn_Close").OnLButtonClick = function()
		Wnd.CloseWindow(this:GetParent())
	end

	LR_Team_Buff_Setting_Panel.UpdateAnchor(this)
end

function LR_Team_Buff_Base.OnEvent(szEvent)
	if szEvent == "UI_SCALED" then
		LR_GKP_Loot.UpdateAnchor(this)
	end
end

function LR_Team_Buff_Base.OnFrameDragEnd()

end

function LR_Team_Buff_Base.OnFrameDestroy()

end
---------------------------------------------------------------
---BUFF设置面板
---------------------------------------------------------------
LR_Team_Buff_Setting_Panel = _G2.CreateAddon("LR_Team_Buff_Setting_Panel")
LR_Team_Buff_Setting_Panel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0},
}
local _UI = {}

function LR_Team_Buff_Setting_Panel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_Team_Buff_Setting_Panel.UsrData.Anchor.s, 0, 0, LR_Team_Buff_Setting_Panel.UsrData.Anchor.r, LR_Team_Buff_Setting_Panel.UsrData.Anchor.x, LR_Team_Buff_Setting_Panel.UsrData.Anchor.y)
end

function LR_Team_Buff_Setting_Panel:ini(szGroupName, buff)
	local buff = buff
	local szKey = sformat("%s_%d_%d", tostring(GetStringCRC(szGroupName)), buff.dwID, buff.nLevel)
	local frame = LR.AppendUI("Frame", sformat("BuffSetting_%s", szKey), {path = sformat("%s\\UI\\LR_BuffSetting.ini", AddonPath)})
	--local frame = Wnd.OpenWindow(sformat("%s\\UI\\LR_BuffSetting.ini", AddonPath), sformat("BuffSetting_%s", szKey))
	frame:Lookup("",""):Lookup("Text_Title"):SetText(sformat("%s（%s）", Table_GetBuffName(buff.dwID, buff.nLevel), szGroupName))

	_UI[szKey] = {}
	local Image_Buff_Icon = LR.AppendUI("Image", frame, "Image_Buff_Icon", {w= 50, h = 50, x = 155, y = 35, eventid = 272})
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
					if _UI[szKey]["Image_Buff_Icon"] then
						if buff.nIconID > 0 then
							_UI[szKey]["Image_Buff_Icon"]:FromIconID(buff.nIconID)
						else
							_UI[szKey]["Image_Buff_Icon"]:FromIconID(Table_GetBuffIconID(buff.dwID, buff.nLevel))
						end
					end
					LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
					LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
				end
			end
		end, nil, nil, nil, buff.nIconID > 0 and buff.nIconID)

		LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
		LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
	end
	_UI[szKey]["Image_Buff_Icon"] = Image_Buff_Icon

	local function Add_Effect()
		if _UI[szKey]["Handle_Effect"] then
			local handle = _UI[szKey]["Handle_Effect"]
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

	local Handle_Effect = LR.AppendUI("Handle", frame, "Handle_Effect", {w= 50, h = 50, x = 155, y = 35, eventid = 0})
	_UI[szKey]["Handle_Effect"] = Handle_Effect
	Add_Effect()

	local CheckBox_Enable = LR.AppendUI("CheckBox", frame, "CheckBox_Enable", {x = 10, y = 35, text = _L["Enable"]})
	CheckBox_Enable:Enable(true)
	CheckBox_Enable:Check(buff.enable)
	CheckBox_Enable.OnCheck = function(arg0)
		buff.enable = arg0
		for k, v in pairs(_UI[szKey]) do
			if v.Enable and k ~= "CheckBox_Enable" then
				v:Enable(arg0)
			end
		end

		LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
		LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
	end
	_UI[szKey]["CheckBox_Enable"] = CheckBox_Enable

	local ComboBox_Effect = LR.AppendUI("ComboBox", frame, "ComboBox_Effect", {x = 220, y = 60, w = 120, text = _L["Effect choose"]})
	ComboBox_Effect:Enable(true)
	ComboBox_Effect.OnClick = function(m)
		m[#m + 1] = {szOption = _L["No effect"], bCheck = true, bMCheck = true, bChecked = function() return buff.nEffectsType == 0 end,
			fnAction = function()
				buff.nEffectsType = 0
				LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
				LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
				Add_Effect()
			end,
		}

		for nType = 1, 8, 1 do
			m[#m + 1] = {szOption = sformat(_L["Effect type %d"], nType), bCheck = true, bMCheck = true, bChecked = function() return buff.nEffectsType == nType end,
				fnAction = function()
					buff.nEffectsType = nType
					LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
					LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
					Add_Effect()
				end,
			}
		end

		PopupMenu(m)
	end
	_UI[szKey]["CheckBox_Enable"] = CheckBox_Enable

	local CheckBox_Not_By_Level = LR.AppendUI("CheckBox", frame, "CheckBox_Not_By_Level", {x = 40, y = 85, text = _L["Not by level"]})
	CheckBox_Not_By_Level:Enable(buff.enable)
	CheckBox_Not_By_Level:Check(buff.nMonitorLevel == 0)
	CheckBox_Not_By_Level.OnCheck = function(arg0)
		if arg0 then
			buff.nMonitorLevel = 0
		else
			buff.nMonitorLevel = buff.nLevel
		end

		LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
		LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
	end
	_UI[szKey]["CheckBox_Not_By_Level"] = CheckBox_Not_By_Level

	LR.AppendUI("Text", frame, "Text_By_Stacknum", {x = 155, y = 85, text = _L["By stacknum"]})
	local Edit_By_Stacknum = LR.AppendUI("Edit", frame, "Edit_By_Stacknum", {w = 40, h = 24, x = 225, y = 85, text = buff.nMonitorStack})
	Edit_By_Stacknum:Enable(buff.enable)
	Edit_By_Stacknum.OnChange = function(arg0)
		local szText = LR.Trim(arg0)
		if type(tonumber(szText)) == "number" then
			buff.nMonitorStack = tonumber(szText)
		end

		LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
		LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
	end
	_UI[szKey]["Edit_By_Stacknum"] = Edit_By_Stacknum

	--仅监控来自于我的BUFF
	local CheckBox_Only_From_Myself = LR.AppendUI("CheckBox", frame, "CheckBox_Only_From_Myself", {x = 40, y = 105, text = _L["Only from myself"]})
	CheckBox_Only_From_Myself:Enable(buff.enable)
	CheckBox_Only_From_Myself:Check(buff.bOnlySelf)
	CheckBox_Only_From_Myself.OnCheck = function(arg0)
		buff.bOnlySelf = arg0

		LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
		LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
	end
	_UI[szKey]["CheckBox_Only_From_Myself"] = CheckBox_Only_From_Myself

	--仅监控我的BUFF
	local CheckBox_Only_Monitor_Self = LR.AppendUI("CheckBox", frame, "CheckBox_Only_Monitor_Self", {x = 40, y = 125, text = _L["Only monitor self"]})
	CheckBox_Only_Monitor_Self:Enable(buff.enable)
	CheckBox_Only_Monitor_Self:Check(buff.bOnlyMonitorSelf)
	CheckBox_Only_Monitor_Self.OnCheck = function(arg0)
		buff.bOnlyMonitorSelf = arg0

		LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
		LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
	end
	_UI[szKey]["CheckBox_Only_Monitor_Self"] = CheckBox_Only_Monitor_Self

	local CheckBox_Striking_Display = LR.AppendUI("CheckBox", frame, "CheckBox_Striking_Display", {x = 40, y = 160, text = _L["Striking display"]})
	CheckBox_Striking_Display:Enable(buff.enable)
	CheckBox_Striking_Display:Check(buff.bSpecialBuff)
	CheckBox_Striking_Display.OnCheck = function(arg0)
		buff.bSpecialBuff = arg0
		local group = {"CheckBox_EnableMask", "CheckBox_UnderStack"}
		for k, v in pairs(group) do
			if _UI[szKey][v] and _UI[szKey][v].Enable then
				_UI[szKey][v]:Enable(arg0)
			end
		end

		LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
		LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
	end
	_UI[szKey]["CheckBox_Striking_Display"] = CheckBox_Striking_Display

	local CheckBox_EnableMask = LR.AppendUI("CheckBox", frame, "CheckBox_EnableMask", {x = 40, y = 180, text = _L["Enable color mask"]})
	CheckBox_EnableMask:Enable(buff.enable and buff.bSpecialBuff)
	CheckBox_EnableMask:Check(buff.bShowMask)
	CheckBox_EnableMask.OnCheck = function(arg0)
		buff.bShowMask = arg0

		LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
		LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
	end
	_UI[szKey]["CheckBox_EnableMask"] = CheckBox_EnableMask

	local Shadow_Striking_Display = LR.AppendUI("ColorBox", frame, "Shadow_Striking_Display", {x = 165, y = 180, w = 20, h = 20, eventid = 272})
	if next(buff.col) ~= nil then
		Shadow_Striking_Display:SetColor(unpack(buff.col))
	else
		Shadow_Striking_Display:SetColor(255, 255, 255)
	end
	Shadow_Striking_Display.OnChange = function(rgb)
		buff.col = rgb

		LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
		LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
	end
	_UI[szKey]["Shadow_Striking_Display"] = Shadow_Striking_Display

	local Btn_ClearColor = LR.AppendUI("Button", frame, "Btn_ClearColor", {x = 195, y = 180, text = _L["Clear color"], w = 100})
	Btn_ClearColor:Enable(buff.enable)
	Btn_ClearColor.OnClick = function(arg0)
		buff.col = {}
		if _UI[szKey]["Shadow_Striking_Display"] then
			if next(buff.col) ~= nil then
				_UI[szKey]["Shadow_Striking_Display"]:SetColor(unpack(buff.col))
			else
				_UI[szKey]["Shadow_Striking_Display"]:SetColor(255, 255, 255)
			end
		end

		LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
		LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
	end

	local CheckBox_UnderStack = LR.AppendUI("CheckBox", frame, "CheckBox_UnderStack", {x = 40, y = 200, text = _L["Still show when under stacknum"]})
	CheckBox_UnderStack:Enable(buff.enable and buff.bSpecialBuff)
	CheckBox_UnderStack:Check(buff.bShowUnderStack)
	CheckBox_UnderStack.OnCheck = function(arg0)
		buff.bShowUnderStack = arg0

		LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
		LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
	end
	_UI[szKey]["CheckBox_UnderStack"] = CheckBox_UnderStack

	local ComboBox_Effect = LR.AppendUI("ComboBox", frame, "ComboBox_Effect", {x = 220, y = 60, w = 120, text = _L["Effect choose"]})
	ComboBox_Effect:Enable(buff.enable)
	ComboBox_Effect.OnClick = function(m)
		m[#m + 1] = {szOption = _L["No effect"], bCheck = true, bMCheck = true, bChecked = function() return buff.nEffectsType == 0 end,
			fnAction = function()
				buff.nEffectsType = 0
				LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
				LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
				Add_Effect()
			end,
		}
		for nType = 1, 8, 1 do
			m[#m + 1] = {szOption = sformat(_L["Effect type %d"], nType), bCheck = true, bMCheck = true, bChecked = function() return buff.nEffectsType == nType end,
				fnAction = function()
					buff.nEffectsType = nType
					LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
					LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
					Add_Effect()
				end,
			}
		end
		PopupMenu(m)
	end
	_UI[szKey]["ComboBox_Effect"] = ComboBox_Effect

	local ComboBox_Sound = LR.AppendUI("ComboBox", frame, "ComboBox_Sound", {x = 40, y = 235, w = 120, text = _L["Sound settings"]})
	ComboBox_Sound:Enable(buff.enable)
	ComboBox_Sound.OnClick = function(m)
		m[#m + 1] = {szOption = _L["No sound"], bCheck = true, bMCheck = true, bChecked = function() return buff.nSoundType == 0 end,
			fnAction = function()
				buff.nSoundType = 0
				LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
				LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
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
					LR_TeamBuffTool_Panel:modifyBuff(szGroupName, buff)
					LR_TeamBuffTool_Panel:DrawOneBuffBox(szGroupName, buff)
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
	_UI[szKey]["ComboBox_Sound"] = ComboBox_Sound
end

function LR_Team_Buff_Setting_Panel:Open(szGroupName, buff)
	local szKey = sformat("%s_%d_%d", tostring(GetStringCRC(szGroupName)), buff.dwID, buff.nLevel)
	local frame = Station.Lookup(sformat("Normal/BuffSetting_%s", szKey))
	if frame then
		Wnd.CloseWindow(frame)
	else
		LR_Team_Buff_Setting_Panel:ini(szGroupName, buff)
	end
end
