local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_TeamHelper"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_TeamHelper"
local _L = LR.LoadLangPack(AddonPath)
---------------------------------------------------------------
local VERSION = "20190528b"
---------------------------------------------------------------
local ROLETYPE_TEXT = {
	[1] = _L["ChengNan"],
	[2] = _L["ChengNv"],
	[5] = _L["ZhengTai"],
	[6] = _L["Loli"],
}
---------------------------------------------------------------
---目的功能
---建立黑名单数据库
---在组队助手中进行提示
---分为系统数据库和用户自定义数据库
---系统数据库进行数据加密，只有特定用户才能在游戏中修改
---用户数据库由用户进行定义，本地数据共享，不加密
---------------------------------------------------------------
local SYSTEM_USER = {
	["d01d6084524227dd8f53e0b8bd083e01"] = true,
	["a1dfe695c899cfbe0c1d38fed2ff6598"] = true,
}
--
local SYSTEM_DB_PATH = sformat("%s\\data", AddonPath)
local SYSTEM_DB_NAME = "system.db"
--
local CUSTOM_DB_PATH = sformat("%s\\data", SaveDataPath)
local CUSTOM_DB_NAME = "custom.db"
--
local BLACK_ACCOUNT_LIST = {}
local BLACK_SYSTEM_LIST = {}
local BLACK_CUSTOM_LIST = {}
-----
LR_Black_List = {}
LR_Black_List.UsrData = {
	bOn = true,
}
RegisterCustomData("LR_Black_List.UsrData", VERSION)
---------------------------------------------------------------
--数据库初始化
---------------------------------------------------------------
---系统数据库
local schema_system_db = {
	name = "system_db",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(100) DEFAULT('')"},  --主键
		{name = "dwID", 	sql = "dwID INTEGER DEFAULT(0)"},		--
		{name = "szName", 	sql = "szName VARCHAR(30) DEFAULT('')"},
		{name = "area", sql = "area VARCHAR(30) DEFAULT('')"},
		{name = "server", 	sql = "server VARCHAR(30) DEFAULT('')"},
		{name = "role_code", 	sql = "role_code VARCHAR(999) DEFAULT('')"},
		{name = "dwForceID", 	sql = "dwForceID INTEGER DEFAULT(0)"},
		{name = "role_type", 	sql = "role_type INTEGER DEFAULT(0)"},
		{name = "detail_link", 	sql = "detail_link VARCHAR(9999) DEFAULT('')"},
		{name = "remarks", 	sql = "remarks VARCHAR(9999) DEFAULT('')"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}
local function IniSystemDB()
	local tTableConfig = {
		schema_system_db,
	}
	LR.IniDB(SYSTEM_DB_PATH, SYSTEM_DB_NAME, tTableConfig)
end
IniSystemDB()

---用户数据库
local schema_custom_db = {
	name = "custom_db",
	version = VERSION,
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(30) DEFAULT('')"},  --主键
		{name = "szName", 	sql = "szName VARCHAR(30) DEFAULT('')"},
		{name = "dwID", 	sql = "dwID INTEGER DEFAULT(0)"},		--
		{name = "area", sql = "area VARCHAR(30) DEFAULT('')"},
		{name = "server", 	sql = "server VARCHAR(30) DEFAULT('')"},
		{name = "dwForceID", 	sql = "dwForceID INTEGER DEFAULT(0)"},
		{name = "role_type", 	sql = "role_type INTEGER DEFAULT(0)"},
		{name = "remarks", 	sql = "remarks VARCHAR(9999) DEFAULT('')"},
		{name = "save_time", 	sql = "save_time INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}
local function IniCustomDB()
	local tTableConfig = {
		schema_custom_db,
	}
	LR.IniDB(CUSTOM_DB_PATH, CUSTOM_DB_NAME, tTableConfig)
end
IniCustomDB()

----------------------------
local _C = {}

function _C.CheckRights()
	return SYSTEM_USER[LR.GetAccountCode()]
end

function _C.LoadSystemDB()
	local path = sformat("%s\\%s", SYSTEM_DB_PATH, SYSTEM_DB_NAME)
	local DB = LR.OpenDB(path, "LR_SYSTEM_BLACK_LIST_LOAD_2FA215493354EEA02AF872C15BA3104A")
	local DB_SELECT = DB:Prepare("SELECT * FROM system_db WHERE szKey IS NOT NULL")
	local data = DB_SELECT:GetAll()
	LR.CloseDB(DB)
	--
	local account_list = {}
	local system_list = {}
	for k, v in pairs(data) do
		local role_code = LR.DecodeUserCode(data.role_code)
		local _s, _e, account_code, szKey = sfind(role_code, "(.+)_(.+)")
		if _s then
			if szKey == v.szKey then
				account_list[account_code] = true
			end
		end
		system_list[v.szKey] = clone(v)
	end
	BLACK_ACCOUNT_LIST = clone(account_list)
	BLACK_SYSTEM_LIST = clone(system_list)
end

function _C.LoadCustomDB()
	local path = sformat("%s\\%s", CUSTOM_DB_PATH, CUSTOM_DB_NAME)
	local DB = LR.OpenDB(path, "LR_CUSTOM_BLACK_LIST_LOAD_26F42E8AE6DD1393A62ED09C3BA00F8C")
	local DB_SELECT = DB:Prepare("SELECT * FROM custom_db WHERE szKey IS NOT NULL ORDER BY save_time DESC")
	local data = DB_SELECT:GetAll()
	LR.CloseDB(DB)
	--
	local custom_list = {}
	for k, v in pairs(data) do
		custom_list[v.szKey] = clone(v)
	end
	BLACK_CUSTOM_LIST = clone(custom_list)
	return data
end

function _C.AddOneCustomData(data)
	local path = sformat("%s\\%s", CUSTOM_DB_PATH, CUSTOM_DB_NAME)
	local DB = LR.OpenDB(path, "LR_CUSTOM_BLACK_LIST_ADD_855A0202969751C8C507DF0F2B96BCBD")
	local DB_REPLACE = DB:Prepare("REPLACE INTO custom_db ( szKey, szName, dwID, area, server, dwForceID, role_type, remarks, save_time ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ? )")
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(data.szKey, data.szName, data.dwID, data.area, data.server, data.dwForceID, data.role_type, data.remarks, GetCurrentTime())
	DB_REPLACE:Execute()
	LR.CloseDB(DB)
	--
	BLACK_CUSTOM_LIST[data.szKey] = clone(data)
end

function _C.DelOneCustomData(szKey)
	local path = sformat("%s\\%s", CUSTOM_DB_PATH, CUSTOM_DB_NAME)
	local DB = LR.OpenDB(path, "LR_CUSTOM_BLACK_LIST_ADD_855A0202969751C8C507DF0F2B96BCBD")
	local DB_REPLACE = DB:Prepare("DELETE FROM custom_db WHERE szKey = ?")
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(szKey)
	DB_REPLACE:Execute()
	LR.CloseDB(DB)
end

function _C.IsTargetInCustomBlackList(szKey)
	if BLACK_CUSTOM_LIST[szKey] then
		return true
	else
		return false
	end
end

function _C.IsTargetInSystemBlackList(szKey)
	if BLACK_SYSTEM_LIST[szKey] then
		return true
	else
		return false
	end
end

function _C.IsTargetInAccountBlackList(data)
	local role_code = LR.DecodeUserCode(data.role_code)
	local _s, _e, account_code, szKey = sfind(role_code, "(.-)_(.+)")

	if _s then
		if szKey == data.szKey then
			if BLACK_ACCOUNT_LIST[account_code] then
				return true
			end
		end
	end
	return false
end

function _C.GetTargetInfo(dwID)
	local player = GetPlayer(dwID)
	if not player then
		return nil
	end
	local data = {}
	local ServerInfo = {GetUserServer()}
	local realArea, realServer = ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	data.szKey = szKey
	data.szName = player.szName
	data.dwID = dwID
	data.area = realArea
	data.server = realServer
	data.dwForceID = player.dwForceID
	data.role_type = player.nRoleType
	data.remarks = ""

	return data
end

function _C.Target_AppendAddonMenu(dwID)
	local data = _C.GetTargetInfo(dwID)
	if not data then
		return
	end

	_C.AddOneCustomData(data)
end

Target_AppendAddonMenu({function(dwID, dwType)
	if dwType == TARGET.PLAYER and dwID ~= UI_GetClientPlayerID() and not LR.IsMapBlockAddon() then
		return {{szOption = _L["Add to LR_Black_List"], fnAction = function() _C.Target_AppendAddonMenu(dwID) end,}}
	else
		return {}
	end
end })

------
function LR_Black_List.Test01()
	Output(BLACK_CUSTOM_LIST, BLACK_SYSTEM_LIST, BLACK_ACCOUNT_LIST)
end


-----
function _C.LOGIN_GAME()
	_C.LoadSystemDB()
	_C.LoadCustomDB()
end

LR.RegisterEvent("LOGIN_GAME", function() _C.LOGIN_GAME() end)
-----------------------------------------------
--UI
-----------------------------------------------
local LP = {}	--short for List_Panel
local UI = {}
--
local SP = {}	--short for System_Panel
local SUI = {}
-----------------------------------------------
LR_Black_List_Panel = {}
LR_Black_List_Panel.UsrData = {
	Anchor = {},
}

function LR_Black_List_Panel.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
	--
	LP.UpdateAnchor(this)
	--
	RegisterGlobalEsc("LR_Black_List_Panel", function () return true end , function() Wnd.CloseWindow("LR_Black_List_Panel") end)
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

function LR_Black_List_Panel.OnFrameDestroy()
	UnRegisterGlobalEsc("LR_Black_List_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_Black_List_Panel.OnFrameDragEnd()
	this:CorrectPos()
	local x, y = this:GetRelPos()
	LR_Black_List_Panel.UsrData.Anchor = {x = x, y = y}
end

function LR_Black_List_Panel.OnFrameBreathe()

end

function LR_Black_List_Panel.OnEvent(szEvent)
	if szEvent == "UI_SCALED" then

	end
end

function LP.UpdateAnchor(frame)
	frame:CorrectPos()
	local Anchor = LR_Black_List_Panel.UsrData.Anchor
	if not Anchor.x then
		frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
	else
		frame:SetAbsPos(Anchor.x, Anchor.y)
	end
end

function LP.InitPanel()
	local frame = LR.AppendUI("Frame", "LR_Black_List_Panel", {title = _L["LR_Black_List_Panel"], style = "NORMAL"})
	UI["LR_Black_List_Panel"] = frame
	--
	local imgTab = LR.AppendUI("Image", frame, "TabImg", {w = 770, h = 33, x = 0, y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)
	--
	local hPageSet = LR.AppendUI("PageSet", frame, "PageSet", {x = 0, y = 50, w = 770, h = 460})
	local szKey = {"Custom_List", "System_List"}
	local break_line = LR.AppendUI("Image", frame, "Break_Line_0", {x = 20, y = 50, w = 2, h = 33})
	for k, v in pairs(szKey) do
		local Btn = LR.AppendUI("UICheckBox", hPageSet, sformat("Btn_%s", v), {x = 20 + (k - 1) * 140, y = 0, w = 140, h = 30, text = _L[v], group = "BtnBlackList"})
		local Window = LR.AppendUI("Window", hPageSet, sformat("Window_%s", v), {x = 0, y = 30, w = 770, h = 430})
		hPageSet:AddPage(Window:GetSelf(), Btn:GetSelf())
		Btn.OnCheck = function(bCheck)
			if bCheck then
				hPageSet:ActivePage(k - 1)
			end
		end

		local hScroll = LR.AppendUI("Scroll", Window, sformat("Scroll_%s", v), {x = 20, y = 30, w = 730, h = 340})

		local Image_Record_BG = LR.AppendUI("Image", Window, sformat("Image_Record_BG_%s", v), {x = 20, y = 0, w = 730, h = 370})
		Image_Record_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",50)
		Image_Record_BG:SetImageType(10)

		local Image_Record_BG0 = LR.AppendUI("Image", Window, sformat("Image_Record_BG0_%s", v), {w = 730, h = 30, x = 20, y = 0})
		Image_Record_BG0:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
		Image_Record_BG0:SetImageType(11)
		Image_Record_BG0:SetAlpha(110)

		local Image_Record_BG1 = LR.AppendUI("Image", Window, sformat("Image_Record_BG1_%s", v), {x = 20, y = 30, w = 730, h = 340})
		Image_Record_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74)
		Image_Record_BG1:SetImageType(10)
		Image_Record_BG1:SetAlpha(50)

		local Handle_Title = LR.AppendUI("Handle", Window, sformat("Handle_Title_%s", v), {x = 20, y = 0, w = 730, h = 370})
		UI[sformat("Handle_Title_%s", v)] = Handle_Title
		UI[sformat("Scroll_%s", v)] = hScroll

		local Btn_Refresh = LR.AppendUI("Button", Window, sformat("Btn_Refresh_%s", v), {x = 20, y = 380, w = 120, h = 40, text = _L["Refresh"]})
		Btn_Refresh.OnClick = function()
			LP.Refresh(v)
		end

		if _C.CheckRights() and v == "System_List" then
			local Btn_Add = LR.AppendUI("Button", Window, sformat("Btn_Add_%s", v), {x = 150, y = 380, w = 120, h = 40, text = _L["Add"]})
			Btn_Add.OnClick = function()
				SP.OpenPanel()
			end
		end
	end
	--
	LP.SetCustomListTitle()
	LP.SetSystemListTitle()
	--
	LP.ShowCustomList()
	LP.ShowSystemList()
	--
	LR.AppendAbout(nil, frame)
end

function LP.SetCustomListTitle()
	local frame = Station.Lookup("Normal/LR_Black_List_Panel")
	if not frame then
		return
	end
	local Handle_Title = UI["Handle_Title_Custom_List"]
	Handle_Title:Clear()

	local szKey = {"szName", "area_server", "dwForceID", "role_type"}
	local width = {160, 120, 80, 80}

	local x = 0
	for k, v in pairs(szKey) do
		local Text = LR.AppendUI("Text", Handle_Title, sformat("CustomTitle_Text_%s", v), {x = x, y = 0, w = width[k], h = 30, text = _L[v]})
		Text:SetVAlign(1):SetHAlign(1)
		x = x + width[k]
		local ImageBreak = LR.AppendUI("Image", Handle_Title, sformat("CustomTitle_Image_Break_%s", v), {x = x, y = 0, w = 5, h = 370})
		ImageBreak:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
		ImageBreak:SetImageType(12)
		ImageBreak:SetAlpha(180)
	end
end

function LP.SetSystemListTitle()
	local frame = Station.Lookup("Normal/LR_Black_List_Panel")
	if not frame then
		return
	end
	local Handle_Title = UI["Handle_Title_System_List"]
	Handle_Title:Clear()

	local szKey = {"szName", "area_server", "dwForceID", "role_type", "remarks", "details"}
	local width = {160, 120, 80, 80, 200, 80}

	local x = 0
	for k, v in pairs(szKey) do
		local Text = LR.AppendUI("Text", Handle_Title, sformat("CustomTitle_Text_%s", v), {x = x, y = 0, w = width[k], h = 30, text = _L[v]})
		Text:SetVAlign(1):SetHAlign(1)
		x = x + width[k]
		local ImageBreak = LR.AppendUI("Image", Handle_Title, sformat("SystemTitle_Image_Break_%s", v), {x = x, y = 0, w = 3, h = 370})
		ImageBreak:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
		ImageBreak:SetImageType(12)
		ImageBreak:SetAlpha(180)
	end
end

function LP.ShowCustomList()
	local frame = Station.Lookup("Normal/LR_Black_List_Panel")
	if not frame then
		return
	end
	local hScroll = UI["Scroll_Custom_List"]
	hScroll:ClearHandle()
	--
	local szKey = {"szName", "area_server", "dwForceID", "role_type"}
	local width = {160, 120, 80, 80}
	--
	local data = _C.LoadCustomDB()
	for k, v in pairs(data) do
		local Handle_Hover_Role = LR.AppendUI("HoverHandle", hScroll, sformat("Handle_%s", v.szKey), {w = 730, h = 30})
		--
		local x = 0
		for k2, v2 in pairs(szKey) do
			if v2 == "szName" then
				local HandleName = LR.AppendUI("Handle", Handle_Hover_Role, sformat("Handle_%s", v2), {x = x, y = 0, w = width[k2], h = 30})
				local Image = LR.AppendUI("Image", HandleName, sformat("ImageForce_%s", v2), {x = x, y = 0, w = 30, h = 30})
				local Text = LR.AppendUI("Text", HandleName, sformat("TextName_%s", v2), {x = x + 30, y = 0, w = width[k2] - 30, h = 30})
				Text:SetVAlign(1):SetHAlign(0)
				Text:SetText(v.szName)
			elseif v2 == "area_server" then
				local Text = LR.AppendUI("Text", Handle_Hover_Role, sformat("Text_%s", v2), {x = x, y = 0, w = width[k2], h = 30})
				Text:SetVAlign(1):SetHAlign(1)
				Text:SetText(sformat("%s_%s", v.area, v.server))
			elseif v2 == "dwForceID" then
				local Text = LR.AppendUI("Text", Handle_Hover_Role, sformat("Text_%s", v2), {x = x, y = 0, w = width[k2], h = 30})
				Text:SetVAlign(1):SetHAlign(1)
				Text:SetText(g_tStrings.tForceTitle[v.dwForceID])
			elseif v2 == "role_type" then
				local Text = LR.AppendUI("Text", Handle_Hover_Role, sformat("Text_%s", v2), {x = x, y = 0, w = width[k2], h = 30})
				Text:SetVAlign(1):SetHAlign(1)
				Text:SetText(ROLETYPE_TEXT[tonumber(v.role_type)])
			end

			x = x + width[k2]
		end
		Handle_Hover_Role.OnRClick = function()
			local menu = {}
			menu[#menu + 1] = {szOption = _L["Delete"], fnAction = function() _C.DelOneCustomData(v.szKey) end,}
			PopupMenu(menu)
		end
	end
	hScroll:UpdateList()
end

function LP.ShowSystemList()
	local frame = Station.Lookup("Normal/LR_Black_List_Panel")
	if not frame then
		return
	end
	local hScroll = UI["Scroll_System_List"]
	hScroll:ClearHandle()

	local szKey = {"szName", "area_server", "server", "dwForceID", "role_type"}


	for k, v in pairs(BLACK_SYSTEM_LIST) do


	end

	hScroll:UpdateList()
end

function LP.Refresh(szName)
	if szName == "Custom_List" then
		LP.ShowCustomList()
	elseif szName == "System_List" then
		LP.ShowSystemList()
	end
end

function LP.OpenPanel()
	local frame = Station.Lookup("Normal/LR_Black_List_Panel")
	if not frame then
		UI = {}
		LP.InitPanel()
	else
		UI = {}
		Wnd.CloseWindow("LR_Black_List_Panel")
	end
end

--------
--系统名单
--------
LR_System_Black_List_Panel = {}
LR_System_Black_List_Panel.UsrData = {
	Anchor = {},
}

function LR_System_Black_List_Panel.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
	--
	SP.UpdateAnchor(this)
	--
	RegisterGlobalEsc("LR_System_Black_List_Panel", function () return true end , function() Wnd.CloseWindow("LR_System_Black_List_Panel") end)
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

function LR_System_Black_List_Panel.OnFrameDestroy()
	UnRegisterGlobalEsc("LR_System_Black_List_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_System_Black_List_Panel.OnFrameDragEnd()
	this:CorrectPos()
	local x, y = this:GetRelPos()
	LR_Black_List_Panel.UsrData.Anchor = {x = x, y = y}
end

function LR_System_Black_List_Panel.OnFrameBreathe()

end

function LR_System_Black_List_Panel.OnEvent(szEvent)
	if szEvent == "UI_SCALED" then

	end
end

function SP.UpdateAnchor(frame)
	frame:CorrectPos()
	local Anchor = LR_System_Black_List_Panel.UsrData.Anchor
	if not Anchor.x then
		frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
	else
		frame:SetAbsPos(Anchor.x, Anchor.y)
	end
end

function SP.InitPanel(data)
	local frame = LR.AppendUI("Frame", "LR_System_Black_List_Panel", {title = _L["LR_System_Black_List_Panel"], style = "SMALL"})
	SUI["LR_System_Black_List_Panel"] = frame
	--
	local vData = data or {}
	--
	local szKey = {"szName", "dwID", "area", "server", "role_code", "dwForceID", "role_type", "detail_link", "remarks"}
	local height = {30, 30, 30, 30, 30, 30, 30, 30, 120}

	local y = 50
	for k, v in pairs(szKey) do
		local Label = LR.AppendUI("Text", frame, sformat("Label_%s", v), {x = 20, y = y, w = 60, h = height[k], text = _L[v]})
		local Edit = LR.AppendUI("Edit", frame, sformat("Edit_%s", v), {x = 100, y = y, w = 220, h = height[k], text = vData[v] or ""})
		SUI[sformat("Edit_%s", v)] = Edit
		y = y + height[k] + 5
	end

	local function GetData()
		local d = {}
		for k, v in pairs(szKey) do
			d[v] = SUI[sformat("Edit_%s", v)]:GetText()
		end
		return d
	end


	local Btn_Add = LR.AppendUI("Button", frame, "Btn_Add", {x = 120, y = 450, w = 120, h = 40, text = _L["Add"]})
	Btn_Add.OnClick = function()
		local d = GetData()
	end
end

function SP.OpenPanel(data)
	local frame = Station.Lookup("Normal/LR_System_Black_List_Panel")
	if not frame then
		SUI = {}
		SP.InitPanel(data)
	else
		SUI = {}
		Wnd.CloseWindow("LR_System_Black_List_Panel")
	end
end

-----------------------------------------------
LR_Black_List.IsTargetInCustomBlackList = _C.IsTargetInCustomBlackList
LR_Black_List.IsTargetInSystemBlackList = _C.IsTargetInSystemBlackList
LR_Black_List.IsTargetInAccountBlackList = _C.IsTargetInAccountBlackList
LR_Black_List.OpenPanel = LP.OpenPanel


