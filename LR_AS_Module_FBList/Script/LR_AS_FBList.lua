local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AS_Module_FBList"
local LanguagePath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local db_name = "maindb.db"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20181220"
-------------------------------------------------------------
--[[
因为获取副本信息是异步操作
上线马上获取一次副本信息，当副本进度变化时更新副本信息
副本信息的保存在异步获得副本信息后
]]
--独立cd的map
local INDEPENDENT_MAP = {
	[298] = true,
	[300] = true,
	[299] = true,
	[301] = true,
	[360] = true,
	[354] = true,
	[349] = true,
	[348] = true,
	[347] = true,
	[341] = true,
}

LR_AS_FBList = {}
local DefaultUsrData = {
	On = true,
	CommonSetting = true,
	bShowMapID = {
		{dwMapID = 361},
		{dwMapID = 354},
		{dwMapID = 350},
		{dwMapID = 348},
		{dwMapID = 347},
		{dwMapID = 341},
		--{dwMapID = 283},
	},
	VERSION = VERSION,
}
LR_AS_FBList.UsrData = clone( DefaultUsrData )
RegisterCustomData("LR_AS_FBList.UsrData", VERSION)

local _FBList = {}
_FBList.src = "%s\\%s\\%s\\%s\\FBList_%s.dat"
_FBList.SettingsSrc = "%s\\CommonSetting_FBList.dat"
_FBList.AllUsrData = {}
_FBList.SelfData = {}

_FBList.FB25R = {}
_FBList.FB10R = {}
_FBList.FB5R = {}

function _FBList.GetFBData()
	local fenlei = {
		[25] = {},
		[10] = {},
		[5] = {},
	}
	for dwMapID, v in pairs (LR.MapType) do
		if fenlei[v.nMaxPlayerCount] then
			fenlei[v.nMaxPlayerCount][#fenlei[v.nMaxPlayerCount]+1] = {dwMapID = dwMapID, Level = v.Level}
		end
	end
	tsort(fenlei[25], function(a, b) return a.dwMapID > b.dwMapID end)
	tsort(fenlei[10], function(a, b) return a.dwMapID > b.dwMapID end)
	tsort(fenlei[5], function(a, b) return a.dwMapID > b.dwMapID end)
	_FBList.FB25R = clone(fenlei[25])
	_FBList.FB10R = clone(fenlei[10])
	_FBList.FB5R = clone(fenlei[5])
end
_FBList.GetFBData()

------------------------------------------------------------
function _FBList.LoadCommonSetting()
	if not LR_AS_FBList.UsrData.CommonSetting then
		return
	end
	local path = sformat("%s\\CommonSetting_FBList.dat", SaveDataPath)
	local data = LoadLUAData(path) or {}
	if data.VERSION and data.VERSION == VERSION then
		LR_AS_FBList.UsrData.bShowMapID = clone(data.bShowMapID or {})
	else
		LR_AS_FBList.UsrData.bShowMapID =  clone( DefaultUsrData.bShowMapID )
		_FBList.SaveCommonSetting()
	end
end

function _FBList.SaveCommonSetting()
	if not LR_AS_FBList.UsrData.CommonSetting then
		return
	end
	local data = {}
	data.VERSION = VERSION
	data.bShowMapID = LR_AS_FBList.UsrData.bShowMapID or {}
	local path = sformat("%s\\CommonSetting_FBList.dat", SaveDataPath)
	SaveLUAData(path, data)
end

------↓↓↓清除所有人的副本数据，包括10人本，25人本，5人本
function _FBList.ClearAllData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM fb_data WHERE bDel = 0 AND szKey IS NOT NULL")
	local Data = d2g(DB_SELECT:GetAll())
	local DB_REPLACE = DB:Prepare("REPLACE INTO fb_data ( szKey, fb_data, bDel ) VALUES ( ?, ?, 0 )")
	for k, v in pairs (Data) do
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(g2d(v.szKey), g2d(LR.JsonEncode({})))
		DB_REPLACE:Execute()
	end
end

------↓↓↓清除所有人物的10人本数据
function _FBList.ClearAllData10R(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM fb_data WHERE bDel = 0 AND szKey IS NOT NULL")
	local Data = d2g(DB_SELECT:GetAll())
	local DB_REPLACE = DB:Prepare("REPLACE INTO fb_data ( szKey, fb_data, bDel ) VALUES ( ?, ?, 0 )")
	for k, v in pairs (Data) do
		local FB_Record = LR.JsonDecode(v.fb_data) or {}
		---拷贝25人本的数据
		local t = {}
		local FB25R = _FBList.FB25R
		for j = 1, #FB25R, 1 do
			if FB_Record[tostring(FB25R[j].dwMapID)] ~= nil then
				t[tostring(FB25R[j].dwMapID)] = FB_Record[tostring(FB25R[j].dwMapID)]
			end
		end
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(g2d(v.szKey), g2d(LR.JsonEncode(t)))
		DB_REPLACE:Execute()
	end
end

------↓↓↓清除所有人物的5人副本数据
function _FBList.ClearAllData5R(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM fb_data WHERE bDel = 0 AND szKey IS NOT NULL")
	local Data = d2g(DB_SELECT:GetAll())
	local DB_REPLACE = DB:Prepare("REPLACE INTO fb_data ( szKey, fb_data, bDel ) VALUES ( ?, ?, 0 )")
	for k, v in pairs (Data) do
		local FB_Record = LR.JsonDecode(v.fb_data) or {}
		---拷贝25/10人本的数据
		local t = {}
		local FB25R = _FBList.FB25R
		local FB10R = _FBList.FB10R
		for j = 1, #FB25R, 1 do
			if FB_Record[tostring(FB25R[j].dwMapID)] ~= nil then
				t[tostring(FB25R[j].dwMapID)] = FB_Record[tostring(FB25R[j].dwMapID)]
			end
		end
		for j = 1, #FB10R, 1 do
			if FB_Record[tostring(FB10R[j].dwMapID)] ~= nil then
				t[tostring(FB10R[j].dwMapID)] = FB_Record[tostring(FB10R[j].dwMapID)]
			end
		end
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(unpack(g2d({v.szKey, LR.JsonEncode(t)})))
		DB_REPLACE:Execute()
	end
end

function _FBList.ResetDataMonday(DB)
	_FBList.ClearAllData(DB)
end

function _FBList.ResetDataEveryDay(DB)
	_FBList.ClearAllData5R(DB)
end

function _FBList.ResetDataFriday(DB)
	_FBList.ClearAllData10R(DB)
end


------↓↓↓获取副本CD（异步）
function _FBList.GetFBList()
	for dwMapID, v in pairs(INDEPENDENT_MAP) do
		ApplyDungeonRoleProgress(dwMapID, GetClientPlayer().dwID)
	end
	ApplyMapSaveCopy()
end

------↓↓↓保存自己的副本CD数据
function _FBList.SaveData2(DB)
	LR.DelayCall(100, function() _FBList.GetFBList() end)
	_FBList.SaveData(DB)
end

function _FBList.SaveData(DB)
	if not LR_AS_Base.UsrData.bRecord then
		return
	end
	local me = GetClientPlayer()
	if not me or IsRemotePlayer(me.dwID) then
		return
	end

	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local dwID = me.dwID
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)

	local FB_Record = {}
	for dwMapID, nCopyIndex in pairs (_FBList.SelfData) do
		FB_Record[tostring(dwMapID)] = nCopyIndex
	end
	local DB_REPLACE = DB:Prepare("REPLACE INTO fb_data ( szKey, fb_data, bDel ) VALUES ( ?, ?, 0 )")
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(unpack(g2d({szKey, LR.JsonEncode(FB_Record)})))
	DB_REPLACE:Execute()
end

function _FBList.LoadAllUsrData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM fb_data WHERE bDel = 0 AND szKey IS NOT NULL")
	local Data = d2g(DB_SELECT:GetAll())
	local AllUsrData = {}
	if Data and next(Data) ~= nil then
		for k, v in pairs (Data) do
			local fb_data = LR.JsonDecode(v.fb_data)
			local FB_Record = {}
			for dwMapID, nCopyIndex in pairs(fb_data) do
				FB_Record[tonumber(dwMapID)] = nCopyIndex
			end
			AllUsrData[v.szKey] = clone(FB_Record)
		end
	end
	_FBList.AllUsrData = clone(AllUsrData)

	--将自己的数据加入列表
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, GetClientPlayer().dwID)
	_FBList.AllUsrData[szKey] = clone(_FBList.SelfData)

	--将自己的数据加入列表
	LR.DelayCall(500, function() _FBList.GetFBList() end)
end

------↓↓↓对服务器获取副本CD事件的响应
--[[
event = "ON_APPLY_PLAYER_SAVED_COPY_RESPOND"
arg0 = {
	[dwMapID] = {[1] = dwFBID},
	[dwMapID] = {[1] = dwFBID},
	...
}
]]
function _FBList.ON_APPLY_PLAYER_SAVED_COPY_RESPOND()
	local FB_Record = arg0
	--添加独立CD
	for dwMapID, v in pairs(INDEPENDENT_MAP) do
		local flag = false
		local data = {}
		local tBossList = Table_GetCDProcessBoss and Table_GetCDProcessBoss(dwMapID) or {}
		for k2, v2 in pairs(tBossList) do
			if GetDungeonRoleProgress(dwMapID, GetClientPlayer().dwID, v2.dwProgressID) then
				data[tostring(v2.dwProgressID)] = true
				flag = true
			else
				data[tostring(v2.dwProgressID)] = false
			end
		end
		if false then
			data = {["1"] = true, ["2"] = true, ["3"] = false, ["4"] = true, ["5"] = false, }
			flag = true
		end
		if flag then
			FB_Record[dwMapID] = clone(data)
		end
	end

	---讲数据添加进数据库
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, GetClientPlayer().dwID)
	_FBList.SelfData = clone(FB_Record)
	_FBList.AllUsrData[szKey] = clone(FB_Record)

	--保存进数据库
	local path = sformat("%s\\%s", SaveDataPath, db_name)
	local DB = LR.OpenDB(path, "FB_LIST_APPLY_RESPOND_SAVE_DE4533D93EA9A55619841F731C02064C")
	_FBList.SaveData(DB)
	LR.CloseDB(DB)

	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if frame then
		_FBList.ListFB()
	end
end


function _FBList.FIRST_LOADING_END()
	_FBList.LoadCommonSetting()
	_FBList.GetFBList()
end

function _FBList.ResetData()
	local SettingsSrc2 = sformat("%s\\CommonSetting_FBList.dat", SaveDataPath)
	local bShowMapID = clone( DefaultUsrData.bShowMapID )
	SaveLUAData( SettingsSrc2, bShowMapID )
	LR_AS_FBList.UsrData = clone( DefaultUsrData )
end

LR.RegisterEvent("ON_APPLY_PLAYER_SAVED_COPY_RESPOND", function() _FBList.ON_APPLY_PLAYER_SAVED_COPY_RESPOND() end)
LR.RegisterEvent("FIRST_LOADING_END", function() _FBList.FIRST_LOADING_END() end)
-------------------------------------------------------------------
function _FBList.GetFBNameByID(dwMapID)
	for i = 1, #_FBList.FB25R, 1 do
		if _FBList.FB25R[i].dwMapID ==  dwMapID then
			return LR.MapType[dwMapID].szName
		end
	end
	for i = 1, #_FBList.FB10R, 1 do
		if _FBList.FB10R[i].dwMapID ==  dwMapID then
			return LR.MapType[dwMapID].szName
		end
	end
	return "未知地图"
end

function _FBList.GetFBIDByMapID(fb_data, dwMapID)
	local fb_data = fb_data or {}
	if next(fb_data) == nil then
		return nil
	end
	if fb_data[dwMapID] then
		return fb_data[dwMapID][1]
	else
		return nil
	end
end

------------------------------------------------------
----主界面显示副本数据
------------------------------------------------------
_FBList.Container = nil

function _FBList.AddPage()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end

	local PageSet_Menu = frame:Lookup("PageSet_Menu")
	local Btn = PageSet_Menu:Lookup("WndCheck_FBList")
	--PageSet_Menu:Lookup("Page_FBList"):Destroy()

	local page = Wnd.OpenWindow(sformat("%s\\UI\\Page.ini", AddonPath), "temp"):Lookup("Page_FBList")
	page:ChangeRelation(PageSet_Menu, true, true)
	page:SetName("Page_FBList")
	Wnd.CloseWindow("temp")
	PageSet_Menu:AddPage(page, Btn)

	Btn:Enable(true)
	Btn:Lookup("",""):Lookup("Text_FBList"):SetFontColor(255, 255, 255)
	_FBList.ReFreshTitle()
	_FBList.ListFB()
	_FBList.AddPageButton()
end

function _FBList.ReFreshTitle()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end
	local title_handle = frame:Lookup("PageSet_Menu"):Lookup("Page_FBList"):Lookup("", "")
	for i = 1, #LR_AS_FBList.UsrData.bShowMapID, 1 do
		local text = title_handle:Lookup(sformat("Text_FB%d_Break", i))
		text:SetText(_FBList.GetFBNameByID(LR_AS_FBList.UsrData.bShowMapID[i].dwMapID))
	end
	for i = #LR_AS_FBList.UsrData.bShowMapID+1, 6, 1 do
		local text = title_handle:Lookup(sformat("Text_FB%d_Break", i))
		text:SetText("")
	end
end

function _FBList.ListFB()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end
	local TempTable_Cal, TempTable_NotCal = LR_AS_Base.SeparateUsrList()
	_FBList.Container = frame:Lookup("PageSet_Menu/Page_FBList/WndScroll_FBList/Wnd_FBList")
	_FBList.Container:Clear()
	num = _FBList.ShowItem (TempTable_Cal, 255, 1, 0)
	num = _FBList.ShowItem (TempTable_NotCal, 60, 1, num)
	_FBList.Container:FormatAllContentPos()
end

function _FBList.ShowItem(t_Table, Alpha, bCal, _num)
	local num = _num
	local PlayerList = clone(t_Table)

	local me  = GetClientPlayer()
	if not me then
		return
	end

	for k, v in pairs(PlayerList) do
		num = num+1
		local wnd = _FBList.Container:AppendContentFromIni(sformat("%s\\UI\\item.ini", AddonPath), "FBList_WndWindow", sformat("%s_%s_%s", v.realArea, v.realServer, v.szName))
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

		--名字
		item_MenPai:FromUITex(GetForceImage(v.dwForceID))
		local name = v.szName
		if wslen(name) > 6 then
			name = sformat("%s...", wssub(name, 1, 5))
		end
		item_Name:SprintfText(_L["%s(%d)"], name, v.nLevel)
		local r, g, b = LR.GetMenPaiColor(v.dwForceID)
		item_Name:SetFontColor(r, g, b)

		local realArea = v.realArea
		local realServer = v.realServer
		local realArea = v.realArea
		local realServer = v.realServer
		local szName = v.szName
		local dwID = v.dwID
		local FB_Record = {}

		local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
		FB_Record = _FBList.AllUsrData[szKey] or {}

		for i = 1, #LR_AS_FBList.UsrData.bShowMapID, 1 do
			local Text_FB = handle:Lookup(sformat("Text_FB%d", i))
			local dwMapID = LR_AS_FBList.UsrData.bShowMapID[i].dwMapID
			if INDEPENDENT_MAP[dwMapID] then
				local data = {}
				if FB_Record[dwMapID] then
					local tBossList = Table_GetCDProcessBoss and Table_GetCDProcessBoss(dwMapID) or {}
					if false then
						tBossList = {{dwProgressID = 1}, {dwProgressID = 2}, {dwProgressID = 3}, {dwProgressID = 4}, {dwProgressID = 5}, }
						Output(FB_Record[dwMapID])
					end
					tsort(tBossList, function(a, b) return a.dwProgressID < b.dwProgressID end)
					local szText = ""
					for k2, v2 in pairs(tBossList) do
						if FB_Record[dwMapID][tostring(v2.dwProgressID)] then
							szText = sformat("%s%s", szText, _L["<SYMBOL_DONE>"])
						else
							szText = sformat("%s%s", szText, _L["<SYMBOL_NOT>"])
						end
					end
					Text_FB:SetText(szText)
					Text_FB:SetFontScheme(2)
				else
					Text_FB:SetText("--")
					Text_FB:SetFontScheme(80)
				end
			else
				local FB_ID = _FBList.GetFBIDByMapID(FB_Record, dwMapID)
				if FB_ID ==  nil then
					Text_FB:SetText("--")
					Text_FB:SetFontScheme(80)
				else
					Text_FB:SprintfText("ID: %d", FB_ID)
					Text_FB:SetFontScheme(41)
				end
			end
		end

		for i = #LR_AS_FBList.UsrData.bShowMapID+1, 6, 1 do
			local Text_FB = handle:Lookup(sformat("Text_FB%d", i))
			Text_FB:SetText("")
			Text_FB:SetFontScheme(41)
		end

		local item_button = wnd:Lookup("Btn_FBSetting")
		item_button.OnLButtonClick =  function ()
			local frame = Station.Lookup("Normal/LR_AS_FB_Detail_Panel")
			local realArea = v.realArea
			local realServer = v.realServer
			local dwID = v.dwID
			if not frame then
				LR_AS_FB_Detail_Panel:Open(realArea, realServer, dwID)
			else
				LR_AS_FB_Detail_Panel:ReloadItemBox(realArea, realServer, dwID)
			end
		end

		--------------------输出tips
		handle:RegisterEvent(304)
		handle.OnItemMouseEnter = function ()
			item_Select:Show()
			_FBList.ShowTip(v)
		end
		handle.OnItemMouseLeave = function()
			item_Select:Hide()
			HideTip()
		end
		handle.OnItemLButtonClick = function()
			local frame = Station.Lookup("Normal/LR_AS_FB_Detail_Panel")
			local realArea = v.realArea
			local realServer = v.realServer
			local dwID = v.dwID
			if not frame then
				LR_AS_FB_Detail_Panel:Open(realArea, realServer, dwID)
			else
				LR_AS_FB_Detail_Panel:ReloadItemBox(realArea, realServer, dwID)
			end
		end
		handle.OnItemRButtonClick = function()
			local menu = LR_AS_Panel.RClickMenu(realArea, realServer, dwID)
			PopupMenu(menu)
		end
	end
	return num
end

--添加底部按钮
function _FBList.AddPageButton()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end
	local page = frame:Lookup("PageSet_Menu/Page_FBList")
	LR_AS_Base.AddButton(page, "btn_5", _L["Show Group"], 340, 555, 110, 36, function() LR_AS_Group.PopupUIMenu() end)
	if LR_AS_Module["BookRd"] then
		LR_AS_Base.AddButton(page, "btn_4", _L["Reading Statistics"], 470, 555, 110, 36, function() LR_BookRd_Panel:Open() end)
	end
	LR_AS_Base.AddButton(page, "btn_3", _L["FB Detail"], 600, 555, 110, 36, function() LR_AS_FB_Detail_Panel:Open() end)
	LR_AS_Base.AddButton(page, "btn_2", _L["Settings"], 730, 555, 110, 36, function() LR_AS_Base.SetOption() end)
end

function _FBList.RefreshPage()
	_FBList.ReFreshTitle()
	_FBList.ListFB()
end

function _FBList.ShowTip(v)
	local nMouseX, nMouseY =  Cursor.GetPos()
	local szTipInfo = {}
	local szPath, nFrame = GetForceImage(v.dwForceID)
	local szKey = sformat("%s_%s_%d", v.realArea, v.realServer, v.dwID)
	local FB_Record = _FBList.AllUsrData[szKey] or {}
	local r, g, b = LR.GetMenPaiColor(v.dwForceID)
	szTipInfo[#szTipInfo+1] = GetFormatImage(szPath, nFrame, 26, 26)
	szTipInfo[#szTipInfo+1] = GetFormatText(sformat(_L["%s(%d)"], v.szName, v.nLevel), 62, r, g, b)
	szTipInfo[#szTipInfo+1] = GetFormatText(sformat("\n%s@%s\n", v.realArea, v.realServer))
	szTipInfo[#szTipInfo+1] = GetFormatImage("ui\\image\\ChannelsPanel\\NewChannels.uitex", 166, 330, 27)
	szTipInfo[#szTipInfo+1] = GetFormatText("\n", 41)
	for dwMapID, v in pairs (FB_Record) do
		szTipInfo[#szTipInfo+1] = GetFormatText(Table_GetMapName(dwMapID), 224)
		local str = ""
		if INDEPENDENT_MAP[dwMapID] then
			local tBossList = Table_GetCDProcessBoss and Table_GetCDProcessBoss(dwMapID) or {}
			if false then
				tBossList = {{dwProgressID = 1}, {dwProgressID = 2}, {dwProgressID = 3}, {dwProgressID = 4}, {dwProgressID = 5}, }
			end
			tsort(tBossList, function(a, b) return a.dwProgressID < b.dwProgressID end)
			local szText = ""
			for k2, v2 in pairs(tBossList) do
				if FB_Record[dwMapID][tostring(v2.dwProgressID)] then
					szText = sformat("%s%s", szText, _L["<SYMBOL_DONE>"])
				else
					szText = sformat("%s%s", szText, _L["<SYMBOL_NOT>"])
				end
			end
			str = sformat(_L["\tKill status：%s \n"], szText)
		else
			str = sformat(_L["\tID:%6d \n"], v[1] or -1)
		end
		szTipInfo[#szTipInfo+1] = GetFormatText(str, 27)
	end
	--szTipInfo = szTipInfo .. GetFormatText("〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓\n", 41)
	szTipInfo[#szTipInfo+1] = GetFormatText("\t \n", 41)
	local szOutputTip = tconcat(szTipInfo)
	OutputTip(szOutputTip, 330, {nMouseX, nMouseY, 0, 0})
end

------------------------------------------------------------------------------------
-----明细小窗口
------------------------------------------------------------------------------------
LR_AS_FB_Detail_Panel = CreateAddon("LR_AS_FB_Detail_Panel")
LR_AS_FB_Detail_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_AS_FB_Detail_Panel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER", x = 0, y = 0},
}

LR_AS_FB_Detail_Panel.szPlayerName = nil
LR_AS_FB_Detail_Panel.realServer = nil
LR_AS_FB_Detail_Panel.realArea = nil

local CustomVersion = "20170111"
RegisterCustomData("LR_AS_FB_Detail_Panel.UsrData", CustomVersion)

LR_AS_FB_Detail_Panel:BindEvent("OnFrameDragEnd", "OnDragEnd")
LR_AS_FB_Detail_Panel:BindEvent("OnFrameDestroy", "OnDestroy")
LR_AS_FB_Detail_Panel:BindEvent("OnFrameKeyDown", "OnKeyDown")


function LR_AS_FB_Detail_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")
	--this:RegisterEvent("CUSTOM_DATA_LOADED")
	LR_AS_FB_Detail_Panel.UpdateAnchor(this)

	-------打开面板时保存数据
	if LR_AS_Base.UsrData.AutoSave and LR_AS_Base.UsrData.OpenSave then
		LR_AS_Base.AutoSave()
	end

	RegisterGlobalEsc("LR_AS_FB_Detail_Panel", function () return true end , function() LR_AS_FB_Detail_Panel:Open() end)
end

function LR_AS_FB_Detail_Panel:OnEvents(event)
	if event ==  "UI_SCALED" then
		LR_AS_FB_Detail_Panel.UpdateAnchor(this)
	end
end

function LR_AS_FB_Detail_Panel.UpdateAnchor(frame)
	frame:SetPoint(LR_AS_FB_Detail_Panel.UsrData.Anchor.s, 0, 0, LR_AS_FB_Detail_Panel.UsrData.Anchor.r, LR_AS_FB_Detail_Panel.UsrData.Anchor.x, LR_AS_FB_Detail_Panel.UsrData.Anchor.y)
	frame:CorrectPos()
end

function LR_AS_FB_Detail_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_AS_FB_Detail_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_AS_FB_Detail_Panel:OnDragEnd()
	this:CorrectPos()
	LR_AS_FB_Detail_Panel.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_AS_FB_Detail_Panel:Init()
	local frame = self:Append("Frame", "LR_AS_FB_Detail_Panel", {title = _L["LR FB Details"], style = "SMALL"})

	local imgTab = self:Append("Image", frame, "TabImg", {w = 381, h = 33, x = 0, y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)

	local realArea = LR_AS_FB_Detail_Panel.realArea
	local realServer = LR_AS_FB_Detail_Panel.realServer

	--------------人物选择
	local hComboBox = self:Append("ComboBox", frame, "hComboBox", {w = 160, x = 20, y = 51, text = ""})
	hComboBox:Enable(true)

	local Text_Server = self:Append("Text", frame, "Text_Server", {w = 100, h = 30, x = 195, y = 50, text = ""})
	Text_Server:SetVAlign(1):SetHAlign(0):SetText(sformat("%s@%s", realArea, realServer))

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

	local Text_break1 = self:Append("Text", hHandle, "Text_break1", {w = 200, h = 30, x  = 0, y = 2, text = _L["FB Name"], font = 18})
	Text_break1:SetHAlign(1)
	Text_break1:SetVAlign(1)

	local Text_break2 = self:Append("Text", hHandle, "Text_break1", {w = 140, h = 30, x  = 200, y = 2, text = _L["FB ID"], font = 18})
	Text_break2:SetHAlign(1)
	Text_break2:SetVAlign(1)

	local fnAction = function(data)
		local realArea = data.realArea
		local realServer = data.realServer
		local dwID = data.dwID
		LR_AS_FB_Detail_Panel:ReloadItemBox(realArea, realServer, dwID)
		local Text_Server = LR_AS_FB_Detail_Panel:Fetch("Text_Server")
		if Text_Server then
			Text_Server:SetText(sformat("%s@%s", realArea, realServer))
		end
	end
	hComboBox.OnClick = function (m)
		LR_AS_Base.PopupPlayerMenu(hComboBox, fnAction)
	end
	----------关于
	LR.AppendAbout(LR_AS_FB_Detail_Panel, frame)
end

function LR_AS_FB_Detail_Panel:Open(realArea, realServer, dwID)
	local frame = self:Fetch("LR_AS_FB_Detail_Panel")
	if realArea then
		if frame then
			LR_AS_FB_Detail_Panel:ReloadItemBox(realArea, realServer, dwID)
		else
			LR_AS_FB_Detail_Panel.realArea = realArea
			LR_AS_FB_Detail_Panel.realServer = realServer
			LR_AS_FB_Detail_Panel.dwID = dwID
			frame = self:Init()
		end
	else
		if frame then
			self:Destroy(frame)
		else
			local serverInfo = {GetUserServer()}
			local realArea, realServer = serverInfo[5], serverInfo[6]
			LR_AS_FB_Detail_Panel.realArea = realArea
			LR_AS_FB_Detail_Panel.realServer = realServer
			LR_AS_FB_Detail_Panel.dwID = GetClientPlayer().dwID
			frame = self:Init()
		end
	end
end

function LR_AS_FB_Detail_Panel:LoadItemBox(hWin)
	local hComboBox = self:Fetch("hComboBox")
	local FB_25R = _FBList.FB25R
	local FB_10R = _FBList.FB10R
	local realServer = LR_AS_FB_Detail_Panel.realServer
	local realArea = LR_AS_FB_Detail_Panel.realArea
	local dwID = LR_AS_FB_Detail_Panel.dwID
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	local FB_Record = _FBList.AllUsrData[szKey] or {}

	local szName = ""
	if LR_AS_Data.AllPlayerList[szKey] then
		szName = LR_AS_Data.AllPlayerList[szKey].szName
	end
	hComboBox:SetText(szName)

	local m = 1
	local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 340, h = 30})
	local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 3, y = 0, w = 334, h = 30})
	Image_Line:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 49)
	Image_Line:SetImageType(10)
	Image_Line:SetAlpha(180)

	local Text_break1 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_1", m), {w = 160, h = 30, x  = 36, y = 3, text  = _L["25FB"] , font = 18})
	Text_break1:SetHAlign(0)
	Text_break1:SetVAlign(1)

	m = 2
	for i = 1, #FB_25R do
		local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 340, h = 30})
		local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 0, y = 0, w = 340, h = 30})
		Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
		Image_Line:SetImageType(10)
		Image_Line:SetAlpha(200)

		if m % 2 ==  1 then
			Image_Line:Hide()
		end
		m = m + 1

		local Text_break1 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_1", m), {w = 160, h = 30, x  = 36, y = 2, text = LR.MapType[FB_25R[i].dwMapID].szName , font = 18})
		Text_break1:SetHAlign(0)
		Text_break1:SetVAlign(1)

		local Text_FB = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 140, h = 30, x  = 200, y = 2, text = "", font = 18})
		Text_FB:SetHAlign(1)
		Text_FB:SetVAlign(1)

		local dwMapID = FB_25R[i].dwMapID
		if INDEPENDENT_MAP[dwMapID] then
			local data = {}
			if FB_Record[dwMapID] then
				local tBossList = Table_GetCDProcessBoss and Table_GetCDProcessBoss(dwMapID) or {}
				if false then
					tBossList = {{dwProgressID = 1}, {dwProgressID = 2}, {dwProgressID = 3}, {dwProgressID = 4}, {dwProgressID = 5}, }
					Output(FB_Record[dwMapID])
				end
				tsort(tBossList, function(a, b) return a.dwProgressID < b.dwProgressID end)
				local szText = ""
				for k2, v2 in pairs(tBossList) do
					if FB_Record[dwMapID][tostring(v2.dwProgressID)] then
						szText = sformat("%s%s", szText, _L["<SYMBOL_DONE>"])
					else
						szText = sformat("%s%s", szText, _L["<SYMBOL_NOT>"])
					end
				end
				Text_FB:SetText(szText)
				Text_FB:SetFontScheme(2)
			else
				Text_FB:SetText("--")
				Text_FB:SetFontScheme(80)
			end
		else
			local FB_ID = _FBList.GetFBIDByMapID(FB_Record, dwMapID)
			local Text_ID =  ""
			if FB_ID ~=  nil then
				Text_ID = sformat("ID: %d", FB_ID)
			else
				Text_ID = "--"
			end
			Text_FB:SetText(Text_ID)
		end
	end

	local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 340, h = 30})
	local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 3, y = 0, w = 334, h = 30})
	Image_Line:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 49)
	Image_Line:SetImageType(10)
	Image_Line:SetAlpha(180)

	local Text_break1 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_1", m), {w = 160, h = 30, x  = 36, y = 3, text  = _L["10FB"] , font = 18})
	Text_break1:SetHAlign(0)
	Text_break1:SetVAlign(1)

	m = m + 1
	for i = 1, #FB_10R do
		local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 340, h = 30})
		local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 0, y = 0, w = 340, h = 30})
		Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
		Image_Line:SetImageType(10)
		Image_Line:SetAlpha(200)

		if m % 2 ==  1 then
			Image_Line:Hide()
		end
		m = m + 1

		local Text_break1 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_1", m), {w = 160, h = 30, x  = 36, y = 2, text = LR.MapType[FB_10R[i].dwMapID].szName  , font = 18})
		Text_break1:SetHAlign(0)
		Text_break1:SetVAlign(1)

		local Text_FB = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 140, h = 30, x  = 200, y = 2, text = Text_ID, font = 18})
		Text_FB:SetHAlign(1)
		Text_FB:SetVAlign(1)

		local dwMapID = FB_10R[i].dwMapID
		if INDEPENDENT_MAP[dwMapID] then
			local data = {}
			if FB_Record[dwMapID] then
				local tBossList = Table_GetCDProcessBoss and Table_GetCDProcessBoss(dwMapID) or {}
				if false then
					tBossList = {{dwProgressID = 1}, {dwProgressID = 2}, {dwProgressID = 3}, {dwProgressID = 4}, {dwProgressID = 5}, }
					Output(FB_Record[dwMapID])
				end
				tsort(tBossList, function(a, b) return a.dwProgressID < b.dwProgressID end)
				local szText = ""
				for k2, v2 in pairs(tBossList) do
					if FB_Record[dwMapID][tostring(v2.dwProgressID)] then
						szText = sformat("%s%s", szText, _L["<SYMBOL_DONE>"])
					else
						szText = sformat("%s%s", szText, _L["<SYMBOL_NOT>"])
					end
				end
				Text_FB:SetText(szText)
				Text_FB:SetFontScheme(2)
			else
				Text_FB:SetText("--")
				Text_FB:SetFontScheme(80)
			end
		else
			local FB_ID = _FBList.GetFBIDByMapID(FB_Record, dwMapID)
			local Text_ID =  ""
			if FB_ID ~=  nil then
				Text_ID = sformat("ID: %d", FB_ID)
			else
				Text_ID = "--"
			end
			Text_FB:SetText(Text_ID)
		end
	end
end

function LR_AS_FB_Detail_Panel:ReloadItemBox(realArea, realServer, dwID)
	LR_AS_FB_Detail_Panel.dwID = dwID
	LR_AS_FB_Detail_Panel.realServer = realServer
	LR_AS_FB_Detail_Panel.realArea = realArea
	local cc = self:Fetch("Scroll")
	if cc then
		self:ClearHandle(cc)
	end
	self:LoadItemBox(cc)
	cc:UpdateList()
end

-----------------------------------------------------------------------------
---------进入副本小提示
-----------------------------------------------------------------------------
local LR_FB_Tips = {
	FirstCheck = false,
	SecondCheck = false,
	tCopyID = {},
}

function LR_FB_Tips.LOADING_END()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local scene = me.GetScene()
	if not scene then
		return
	end
	if scene.nType ~=  MAP_TYPE.DUNGEON then
		return
	end
	LR_FB_Tips.FirstCheck = false
	LR_FB_Tips.SecondCheck = false
	LR.DelayCall(500, function() _FBList.GetFBList() end)
	LR.DelayCall(3000, function() LR_FB_Tips.OutBlackCD() end)
end

function LR_FB_Tips.ON_APPLY_PLAYER_SAVED_COPY_RESPOND()
	local tCopyID = arg0 or {}
	LR_FB_Tips.tCopyID = clone(tCopyID)
	LR.DelayCall(750, function() LR_FB_Tips.CheckCD() end)
end

function LR_FB_Tips.CheckCD()
	local tCopyID = LR_FB_Tips.tCopyID
	--Output(LR_FB_Tips.FirstCheck, LR_FB_Tips.SecondCheck)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local scene = me.GetScene()
	if not scene or scene.nType ~=  MAP_TYPE.DUNGEON then
		return
	end
	local dwMapID = scene.dwMapID
	local nCopyIndex = scene.nCopyIndex
	local szName = Table_GetMapName(dwMapID)
	local MSG = {}
	local FB_ID = _FBList.GetFBIDByMapID(_FBList.SelfData, dwMapID)
	if not LR_FB_Tips.FirstCheck then
		MSG[#MSG+1] = sformat(_L["LR:You enter FB[%s], ID is %d, "], szName, nCopyIndex)
		if FB_ID ~= nil then
			MSG[#MSG+1] = _L["You have cd.\n"]
			LR_FB_Tips.SecondCheck = true
			PlaySound(SOUND.UI_SOUND, g_sound.NewMail)
		else
			MSG[#MSG+1] = _L["You have not cd.\n"]
			PlaySound(SOUND.UI_SOUND, g_sound.TEAM_MESSAGE)
		end
		local szText = tconcat(MSG)
		LR.SysMsg(szText)
		if LR_FB_Tips.SecondCheck then
			LR.RedAlert(szText, 10)
		else
			LR.GreenAlert(szText, 10)
		end
		LR_FB_Tips.FirstCheck = true
	else
		if not LR_FB_Tips.SecondCheck then
			if FB_ID ~= nil then
				MSG[#MSG+1] = sformat(_L["LR:You got FB CD:%d.\n"], FB_ID)
				local szText = tconcat(MSG)
				LR.SysMsg(szText)
				LR.RedAlert(szText, 10)
				PlaySound(SOUND.UI_SOUND, g_sound.FinishAchievement)
				LR_FB_Tips.SecondCheck = true
			end
		end
	end
end

function LR_FB_Tips.OutBlackCD()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local scene = me.GetScene()
	if scene.nType ~=  MAP_TYPE.DUNGEON then
		return
	end
	local dwMapID = scene.dwMapID
	local nCopyIndex = scene.nCopyIndex
	LR.BlackFBList[dwMapID] = LR.BlackFBList[dwMapID] or {}
	LR.BlackFBList[dwMapID][nCopyIndex] = LR.BlackFBList[dwMapID][nCopyIndex] or {}
	if next(LR.BlackFBList[dwMapID][nCopyIndex]) ~= nil then
		local szName = LR.BlackFBList[dwMapID][nCopyIndex].szName
		local nTime = LR.BlackFBList[dwMapID][nCopyIndex].nTime
		local _date = TimeToDate(nTime)
		local year = _date["year"]
		local month = _date["month"]
		local day = _date["day"]
		local hour = _date["hour"]
		local minute = _date["minute"]
		local second = _date["second"]

		local msg_time = sformat(_L["%d/%d/%d %0.2d:%0.2d:%0.2d"], year, month, day, hour, minute, second)
		local msg = sformat(_L["LR:Blacked by [%s], Time:%s.\n"], szName, msg_time)
		LR.SysMsg(msg)
	end
end

function LR_FB_Tips.ON_MAP_COPY_PROGRESS_UPDATE()
	LR.DelayCall(150, function() _FBList.GetFBList() end)
end

LR.RegisterEvent("LOADING_END", function() LR_FB_Tips.LOADING_END() end)
LR.RegisterEvent("ON_MAP_COPY_PROGRESS_UPDATE", function() LR_FB_Tips.ON_MAP_COPY_PROGRESS_UPDATE() end)
LR.RegisterEvent("ON_APPLY_PLAYER_SAVED_COPY_RESPOND", function() LR_FB_Tips.ON_APPLY_PLAYER_SAVED_COPY_RESPOND() end)

------------------------------------------
LR_AS_FBList.FB25R = _FBList.FB25R
LR_AS_FBList.FB10R = _FBList.FB10R
LR_AS_FBList.FB5R = _FBList.FB5R
LR_AS_FBList.SaveCommonSetting = _FBList.SaveCommonSetting
LR_AS_FBList.LoadCommonSetting = _FBList.LoadCommonSetting


------------------------------------------
--注册模块
LR_AS_Module.FBList = {}
LR_AS_Module.FBList.SaveData = _FBList.SaveData2
LR_AS_Module.FBList.LoadData = _FBList.LoadAllUsrData
LR_AS_Module.FBList.ResetDataMonday = _FBList.ResetDataMonday
LR_AS_Module.FBList.ResetDataEveryDay = _FBList.ResetDataEveryDay
LR_AS_Module.FBList.ResetDataFriday = _FBList.ResetDataFriday
LR_AS_Module.FBList.AddPage = _FBList.AddPage
LR_AS_Module.FBList.RefreshPage = _FBList.RefreshPage
LR_AS_Module.FBList.ShowTip = _FBList.ShowTip


