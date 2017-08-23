local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin\\@DATA\\LR_AccountStatistics\\UsrData"
local _L = LR.LoadLangPack(AddonPath)
local DB_name = "maindb.db"
local sformat, slen, sgsub, ssub, sfind = string.format, string.len, string.gsub, string.sub, string.find
local mfloor, mceil, mmin, mmax = math.floor, math.ceil, math.min, math.max
local tconcat, tinsert, tremove, tsort = table.concat, table.insert, table.remove, table.sort
----------------------------------------------------------
LR_AccountStatistics_FBList =  LR_AccountStatistics_FBList or {}
LR_AccountStatistics_FBList.src = "%s\\%s\\%s\\%s\\FBList_%s.dat"
LR_AccountStatistics_FBList.SettingsSrc = "%s\\CommonSetting_FBList.dat"
LR_AccountStatistics_FBList.AllUsrData = {}
LR_AccountStatistics_FBList.SelfData = {}

LR_AccountStatistics_FBList.FB25R = {}
LR_AccountStatistics_FBList.FB10R = {}
LR_AccountStatistics_FBList.FB5R = {}

function LR_AccountStatistics_FBList.GetFBData()
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
	LR_AccountStatistics_FBList.FB25R = clone(fenlei[25])
	LR_AccountStatistics_FBList.FB10R = clone(fenlei[10])
	LR_AccountStatistics_FBList.FB5R = clone(fenlei[5])
end
LR_AccountStatistics_FBList.GetFBData()

local DefaultUsrData = {
	On = true,
	CommonSetting = true,
	bShowMapID = {
		{dwMapID = 270},
		{dwMapID = 271},
		{dwMapID = 273},
		{dwMapID = 249},
		{dwMapID = 248},
		{dwMapID = 263},
	},
	Version = "20170602v2",
}

LR_AccountStatistics_FBList.UsrData = clone( DefaultUsrData )
local CustomVersion = "20170602v2"
RegisterCustomData("LR_AccountStatistics_FBList.UsrData", CustomVersion)

function LR_AccountStatistics_FBList.CheckVersion()
	local UsrData = LR_AccountStatistics_FBList.UsrData
	local Version = UsrData.Version or "1.0"
	if Version ~=  DefaultUsrData.Version then
		LR_AccountStatistics_FBList.UsrData = clone ( DefaultUsrData )
	end

	local path = sformat(LR_AccountStatistics_FBList.SettingsSrc, SaveDataPath)
	local t =  LoadLUAData(path) or {}
	if not (t.Version and t.Version == DefaultUsrData.Version and t.nType and t.nType == "FBCommSet" )then
		local data = {}
		data.Version = DefaultUsrData.Version
		data.nType = "FBCommSet"
		data.data = DefaultUsrData.bShowMapID or {}
		local path = sformat(LR_AccountStatistics_FBList.SettingsSrc, SaveDataPath)
		SaveLUAData(path, data)
	end
end

function LR_AccountStatistics_FBList.LoadCommonSetting ()
	if not LR_AccountStatistics_FBList.UsrData.CommonSetting then
		return
	end
	local path = sformat(LR_AccountStatistics_FBList.SettingsSrc, SaveDataPath)
	local t =  LoadLUAData(path) or {}
	if t.Version and t.Version == DefaultUsrData.Version and t.nType and t.nType == "FBCommSet" then
		LR_AccountStatistics_FBList.UsrData.bShowMapID = t.data or {}
	else
		LR_AccountStatistics_FBList.UsrData.bShowMapID =  clone( DefaultUsrData.bShowMapID )
		LR_AccountStatistics_FBList.UsrData.Version = DefaultUsrData.Version
	end
end

function LR_AccountStatistics_FBList.SaveCommonSetting ()
	if LR_AccountStatistics_FBList.UsrData.CommonSetting then
		local data = {}
		data.Version = DefaultUsrData.Version
		data.nType = "FBCommSet"
		data.data = LR_AccountStatistics_FBList.UsrData.bShowMapID or {}
		local path = sformat(LR_AccountStatistics_FBList.SettingsSrc, SaveDataPath)
		SaveLUAData(path, data)
	end
end

-----重置副本数据
function LR_AccountStatistics_FBList.ClearData()
	----合并到RC里面 LR_AccountStatistics_RiChang.ResetData()
	if true then
		return
	end
end

------↓↓↓清除所有人的每周可获得监本数量
function LR_AccountStatistics_FBList.ClearAllReaminJianBen(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM player_info")
	local Data = DB_SELECT:GetAll() or {}
	local DB_REPLACE = DB:Prepare("REPLACE INTO player_info (szKey, dwID, szName, nLevel, dwForceID, nGold, nSilver, nCopper, JianBen, BangGong, XiaYi, WeiWang, ZhanJieJiFen, ZhanJieDengJi, MingJianBi, szTitle, nCurrentStamina, nMaxStamina, nCurrentThew, nMaxThew, nCurrentTrainValue, nCamp, szTongName, remainJianBen, loginArea, loginServer, realArea, realServer, SaveTime) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1000, ?, ?, ?, ?, ?)")
	for k, v in pairs (Data) do
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(v.szKey, v.dwID, v.szName, v.nLevel, v.dwForceID, v.nGold, v.nSilver, v.nCopper, v.JianBen, v.BangGong, v.XiaYi, v.WeiWang, v.ZhanJieJiFen, v.ZhanJieDengJi, v.MingJianBi, v.szTitle, v.nCurrentStamina, v.nMaxStamina, v.nCurrentThew, v.nMaxThew, v.nCurrentTrainValue, v.nCamp, v.szTongName, v.loginArea, v.loginServer, v.realArea, v.realServer, v.SaveTime)
		DB_REPLACE:Execute()
	end
end

------↓↓↓清除所有人的副本数据，包括10人本，25人本，5人本
function LR_AccountStatistics_FBList.ClearAllData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM fb_data WHERE bDel = 0")
	local Data = DB_SELECT:GetAll() or {}
	local DB_REPLACE = DB:Prepare("REPLACE INTO fb_data ( szKey, fb_data, bDel ) VALUES ( ?, ?, 0 )")
	for k, v in pairs (Data) do
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(v.szKey, LR.JsonEncode({}))
		DB_REPLACE:Execute()
	end
end

------↓↓↓清除所有人物的10人本数据
function LR_AccountStatistics_FBList.ClearAllData10R(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM fb_data WHERE bDel = 0")
	local Data = DB_SELECT:GetAll() or {}
	local DB_REPLACE = DB:Prepare("REPLACE INTO fb_data ( szKey, fb_data, bDel ) VALUES ( ?, ?, 0 )")
	for k, v in pairs (Data) do
		local FB_Record = LR.JsonDecode(v.fb_data) or {}
		---拷贝25人本的数据
		local t = {}
		local FB25R = LR_AccountStatistics_FBList.FB25R
		for j = 1, #FB25R, 1 do
			if FB_Record[tostring(FB25R[j].dwMapID)] ~=  nil then
				t[tostring(FB25R[j].dwMapID)] = FB_Record[tostring(FB25R[j].dwMapID)]
			end
		end
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(v.szKey, LR.JsonEncode(t))
		DB_REPLACE:Execute()
	end
end

------↓↓↓清除所有人物的5人副本数据
function LR_AccountStatistics_FBList.ClearAllData5R(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM fb_data WHERE bDel = 0")
	local Data = DB_SELECT:GetAll() or {}
	local DB_REPLACE = DB:Prepare("REPLACE INTO fb_data ( szKey, fb_data, bDel ) VALUES ( ?, ?, 0 )")
	for k, v in pairs (Data) do
		local FB_Record = LR.JsonDecode(v.fb_data) or {}
		---拷贝25/10人本的数据
		local t = {}
		local FB25R = LR_AccountStatistics_FBList.FB25R
		local FB10R = LR_AccountStatistics_FBList.FB10R
		for j = 1, #FB25R, 1 do
			if FB_Record[tostring(FB25R[j].dwMapID)] ~=  nil then
				t[tostring(FB25R[j].dwMapID)] = FB_Record[tostring(FB25R[j].dwMapID)]
			end
		end
		for j = 1, #FB10R, 1 do
			if FB_Record[tostring(FB25R[j].dwMapID)] ~=  nil then
				t[tostring(FB10R[j].dwMapID)] = FB_Record[tostring(FB10R[j].dwMapID)]
			end
		end
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(v.szKey, LR.JsonEncode(t))
		DB_REPLACE:Execute()
	end
end

------↓↓↓获取副本CD（异步）
function LR_AccountStatistics_FBList.GetFBList()
	--Output("GetFBList")
	ApplyMapSaveCopy()
end

------↓↓↓保存自己的副本CD数据
function LR_AccountStatistics_FBList.SaveData(DB)
	local me = GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	local serverInfo = {GetUserServer()}
	local realArea, realServer = serverInfo[5], serverInfo[6]
	local dwID = me.dwID
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	if LR_AccountStatistics.UsrData.OthersCanSee then
		if next(LR_AccountStatistics_FBList.SelfData) ~=  nil then
			local FB_Record = {}
			for dwMapID, nCopyIndex in pairs (LR_AccountStatistics_FBList.SelfData) do
				FB_Record[tostring(dwMapID)] = nCopyIndex
			end
			local DB_REPLACE = DB:Prepare("REPLACE INTO fb_data ( szKey, fb_data, bDel ) VALUES ( ?, ?, 0 )")
			DB_REPLACE:ClearBindings()
			DB_REPLACE:BindAll(szKey, LR.JsonEncode(FB_Record))
			DB_REPLACE:Execute()
		end
	else
		local DB_REPLACE = DB:Prepare("REPLACE INTO fb_data ( szKey, bDel ) VALUES ( ?, 1 )")
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey)
		DB_REPLACE:Execute()
	end
end

function LR_AccountStatistics_FBList.LoadAllUsrData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM fb_data WHERE bDel = 0")
	local Data = DB_SELECT:GetAll()
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
	LR_AccountStatistics_FBList.AllUsrData = clone(AllUsrData)

	--将自己的数据加入列表
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, GetClientPlayer().dwID)
	LR_AccountStatistics_FBList.AllUsrData[szKey] = clone(LR_AccountStatistics_FBList.SelfData)
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
function LR_AccountStatistics_FBList.ON_APPLY_PLAYER_SAVED_COPY_RESPOND()
	local FB_Record = arg0 or {}
	if next(FB_Record) ==  nil then
		return
	end
	LR_AccountStatistics_FBList.SelfData = clone(FB_Record)
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	LR_AccountStatistics_FBList.SaveData(DB)
	DB:Execute("END TRANSACTION")
	DB:Release()
	local frame = Station.Lookup("Normal/LR_AccountStatistics")
	if frame then
		LR_AccountStatistics_FBList.ListFB()
	end
end


function LR_AccountStatistics_FBList.FIRST_LOADING_END()
	LR_AccountStatistics_FBList.CheckVersion()
	----------检查是否有副本cd配置文件
	--------以下
	local SettingsSrc1 = sformat("%s\\CommonSetting_FBList.dat.jx3dat", SaveDataPath)
	local SettingsSrc2 = sformat("%s\\CommonSetting_FBList.dat", SaveDataPath)
	local bShowMapID = clone( DefaultUsrData.bShowMapID )
	if IsFileExist(SettingsSrc1) then

	else
		SaveLUAData(SettingsSrc2, bShowMapID)
	end
	--------以上
	if not (LR_AccountStatistics_FBList.UsrData and LR_AccountStatistics_FBList.UsrData.Version and LR_AccountStatistics_FBList.UsrData.Version ==  DefaultUsrData.Version ) then
		LR_AccountStatistics_FBList.ResetData()
	end
	LR_AccountStatistics_FBList.LoadCommonSetting()
end

function LR_AccountStatistics_FBList.ResetData()
	local SettingsSrc2 = sformat("%s\\CommonSetting_FBList.dat", SaveDataPath)
	local bShowMapID = clone( DefaultUsrData.bShowMapID )
	SaveLUAData( SettingsSrc2, bShowMapID )
	LR_AccountStatistics_FBList.UsrData = clone( DefaultUsrData )
end


LR.RegisterEvent("ON_APPLY_PLAYER_SAVED_COPY_RESPOND", function() LR_AccountStatistics_FBList.ON_APPLY_PLAYER_SAVED_COPY_RESPOND() end)
LR.RegisterEvent("FIRST_LOADING_END", function() LR_AccountStatistics_FBList.FIRST_LOADING_END() end)

-------------------------------------------------------------------
function LR_AccountStatistics_FBList.GetFBNameByID(dwMapID)
	for i = 1, #LR_AccountStatistics_FBList.FB25R, 1 do
		if LR_AccountStatistics_FBList.FB25R[i].dwMapID ==  dwMapID then
			return LR.MapType[dwMapID].szName
		end
	end
	for i = 1, #LR_AccountStatistics_FBList.FB10R, 1 do
		if LR_AccountStatistics_FBList.FB10R[i].dwMapID ==  dwMapID then
			return LR.MapType[dwMapID].szName
		end
	end
	return "未知地图"
end

function LR_AccountStatistics_FBList.GetFBIDByMapID(fb_data, dwMapID)
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

function LR_AccountStatistics_FBList.ListFB()
	local frame = Station.Lookup("Normal/LR_AccountStatistics")
	if not frame then
		return
	end
	local title_handle = LR_AccountStatistics.LR_FBList_Title_handle
	for i = 1, #LR_AccountStatistics_FBList.UsrData.bShowMapID, 1 do
		local text = title_handle:Lookup(sformat("Text_FB%d_Break", i))
		text:SetText(LR_AccountStatistics_FBList.GetFBNameByID(LR_AccountStatistics_FBList.UsrData.bShowMapID[i].dwMapID))
	end

	for i = #LR_AccountStatistics_FBList.UsrData.bShowMapID+1, 6, 1 do
		local text = title_handle:Lookup(sformat("Text_FB%d_Break", i))
		text:SetText("")
	end

	local TempTable_Cal, TempTable_NotCal = LR_AccountStatistics.SeparateUsrList()

	LR_AccountStatistics.LR_FBList_Container:Clear()
	num = LR_AccountStatistics_FBList.ShowItem (TempTable_Cal, 255, 1, 0)
	num = LR_AccountStatistics_FBList.ShowItem (TempTable_NotCal, 60, 1, num)
	LR_AccountStatistics.LR_FBList_Container:FormatAllContentPos()
end

function LR_AccountStatistics.OpenFBDetail_Panel ()
	LR_Acc_FB_Detail_Panel:Open()
end

function LR_AccountStatistics_FBList.ShowItem (t_Table, Alpha, bCal, _num)
	local num = _num
	local TempTable = clone(t_Table)

	local player  = GetClientPlayer()
	if not player then
		return
	end

	for i = 1, #TempTable, 1 do
		num = num+1
		local wnd = LR_AccountStatistics.LR_FBList_Container:AppendContentFromIni("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics_FBList_Item.ini", "FBList_WndWindow", num)
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
		item_Name:SprintfText("%s（%d）", name, TempTable[i].nLevel)
		local r, g, b = LR.GetMenPaiColor(TempTable[i].dwForceID)
		item_Name:SetFontColor(r, g, b)
		--  Output(LR.GetMenPaiColor(TempTable[i].MenPai))

		local realArea = TempTable[i].realArea
		local realServer = TempTable[i].realServer
		local realArea = TempTable[i].realArea
		local realServer = TempTable[i].realServer
		local szName = TempTable[i].szName
		local dwID = TempTable[i].dwID
		local FB_Record = {}

		local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
		FB_Record = LR_AccountStatistics_FBList.AllUsrData[szKey] or {}

		for i = 1, #LR_AccountStatistics_FBList.UsrData.bShowMapID, 1 do
			local Text_FB = items:Lookup(sformat("Text_FB%d", i))
			local FB_ID = LR_AccountStatistics_FBList.GetFBIDByMapID(FB_Record, LR_AccountStatistics_FBList.UsrData.bShowMapID[i].dwMapID)
			if FB_ID ==  nil then
				Text_FB:SetText("--")
				Text_FB:SetFontScheme(80)
			else
				Text_FB:SprintfText("ID: %d", FB_ID)
				Text_FB:SetFontScheme(41)
			end
		end

		for i = #LR_AccountStatistics_FBList.UsrData.bShowMapID+1, 6, 1 do
			local Text_FB = items:Lookup(sformat("Text_FB%d", i))
			Text_FB:SetText("")
			Text_FB:SetFontScheme(41)
		end

		local item_button = wnd:Lookup("Btn_FBSetting")
		item_button.OnLButtonClick =  function ()
			local frame = Station.Lookup("Normal/LR_Acc_FB_Detail_Panel")
			local realArea = TempTable[i].realArea
			local realServer = TempTable[i].realServer
			local dwID = TempTable[i].dwID
			if not frame then
				LR_Acc_FB_Detail_Panel:Open(realArea, realServer, dwID)
			else
				LR_Acc_FB_Detail_Panel:ReloadItemBox(realArea, realServer, dwID)
			end
		end

		--------------------输出tips
		items:RegisterEvent(786)
		items.OnItemMouseEnter = function ()
			item_Select:Show()
			local nMouseX, nMouseY =  Cursor.GetPos()
			local szTipInfo = {}
			local szPath, nFrame = GetForceImage(TempTable[i].dwForceID)
			szTipInfo[#szTipInfo+1] = GetFormatImage(szPath, nFrame, 26, 26)
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s（%d）\n", TempTable[i].szName, TempTable[i].nLevel), 62, r, g, b)
			--szTipInfo[#szTipInfo+1] = GetFormatText(" ================================ \n", 17)
			szTipInfo[#szTipInfo+1] = GetFormatImage("ui\\image\\ChannelsPanel\\NewChannels.uitex", 166, 330, 27)
			szTipInfo[#szTipInfo+1] = GetFormatText("\n", 41)
			for dwMapID, v in pairs (FB_Record) do
				local str = sformat("\tID：%6d \n", v[1])
				szTipInfo[#szTipInfo+1] = GetFormatText(Table_GetMapName(dwMapID), 224)
				szTipInfo[#szTipInfo+1] = GetFormatText(str, 27)
			end
			--szTipInfo = szTipInfo .. GetFormatText("〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓\n", 41)
			szTipInfo[#szTipInfo+1] = GetFormatText("\t \n", 41)
			local szOutputTip = tconcat(szTipInfo)
			OutputTip(szOutputTip, 330, {nMouseX, nMouseY, 0, 0})
		end
		items.OnItemMouseLeave = function()
			item_Select:Hide()
			HideTip()
		end
		items.OnItemLButtonClick = function()
			local frame = Station.Lookup("Normal/LR_Acc_FB_Detail_Panel")
			local realArea = TempTable[i].realArea
			local realServer = TempTable[i].realServer
			local dwID = TempTable[i].dwID
			if not frame then
				LR_Acc_FB_Detail_Panel:Open(realArea, realServer, dwID)
			else
				LR_Acc_FB_Detail_Panel:ReloadItemBox(realArea, realServer, dwID)
			end
		end
	end
	return num
end

------------------------------------------------------------------------------------
-----明细小窗口
------------------------------------------------------------------------------------
LR_Acc_FB_Detail_Panel = CreateAddon("LR_Acc_FB_Detail_Panel")
LR_Acc_FB_Detail_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_Acc_FB_Detail_Panel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER", x = 0, y = 0},
}

LR_Acc_FB_Detail_Panel.szPlayerName = nil
LR_Acc_FB_Detail_Panel.realServer = nil
LR_Acc_FB_Detail_Panel.realArea = nil

local CustomVersion = "20170111"
RegisterCustomData("LR_Acc_FB_Detail_Panel.UsrData", CustomVersion)

LR_Acc_FB_Detail_Panel:BindEvent("OnFrameDragEnd", "OnDragEnd")
LR_Acc_FB_Detail_Panel:BindEvent("OnFrameDestroy", "OnDestroy")
LR_Acc_FB_Detail_Panel:BindEvent("OnFrameKeyDown", "OnKeyDown")


function LR_Acc_FB_Detail_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")
	--this:RegisterEvent("CUSTOM_DATA_LOADED")
	LR_Acc_FB_Detail_Panel.UpdateAnchor(this)

	-------打开面板时保存数据
	if LR_AccountStatistics.UsrData.AutoSave and LR_AccountStatistics.UsrData.OpenSave then
		LR_AccountStatistics.AutoSave()
	end

	RegisterGlobalEsc("LR_Acc_FB_Detail_Panel", function () return true end , function() LR_Acc_FB_Detail_Panel:Open() end)
end

function LR_Acc_FB_Detail_Panel:OnEvents(event)
	if event ==  "UI_SCALED" then
		LR_Acc_FB_Detail_Panel.UpdateAnchor(this)
	end
end

function LR_Acc_FB_Detail_Panel.UpdateAnchor(frame)
	frame:SetPoint(LR_Acc_FB_Detail_Panel.UsrData.Anchor.s, 0, 0, LR_Acc_FB_Detail_Panel.UsrData.Anchor.r, LR_Acc_FB_Detail_Panel.UsrData.Anchor.x, LR_Acc_FB_Detail_Panel.UsrData.Anchor.y)
	frame:CorrectPos()
end

function LR_Acc_FB_Detail_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_Acc_FB_Detail_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_Acc_FB_Detail_Panel:OnDragEnd()
	this:CorrectPos()
	LR_Acc_FB_Detail_Panel.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_Acc_FB_Detail_Panel:Init()
	local frame = self:Append("Frame", "LR_Acc_FB_Detail_Panel", {title = _L["LR FB Details"], style = "SMALL"})

	local imgTab = self:Append("Image", frame, "TabImg", {w = 381, h = 33, x = 0, y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)

	--------------人物选择
	local hComboBox = self:Append("ComboBox", frame, "hComboBox", {w = 160, x = 20, y = 51, text = ""})
	hComboBox:Enable(true)

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


	hComboBox.OnClick = function (m)
		local TempTable_Cal, TempTable_NotCal = LR_AccountStatistics.SeparateUsrList()
		tsort(TempTable_Cal, function(a, b)
			if a.nLevel ==  b.nLevel then
				return a.dwForceID < b.dwForceID
			else
				return a.nLevel > b.nLevel
			end
		end)

		local TempTable = {}
		for i = 1, #TempTable_Cal, 1 do
			TempTable[#TempTable+1] = TempTable_Cal[i]
		end
		for i = 1, #TempTable_NotCal, 1 do
			TempTable[#TempTable+1] = TempTable_NotCal[i]
		end

		local page_num = mceil(#TempTable / 20)
		local page = {}
		for i = 0, page_num - 1, 1 do
			page[i] = {}
			for k = 1, 20, 1 do
				if TempTable[i * 20 + k] ~=  nil then
					local szIcon, nFrame = GetForceImage(TempTable[i * 20 + k].dwForceID)
					local r, g, b = LR.GetMenPaiColor(TempTable[i * 20 + k].dwForceID)
					page[i][#page[i]+1] = {szOption = sformat("(%d)%s", TempTable[i * 20 + k].nLevel, TempTable[i * 20 + k].szName), bCheck = false, bChecked = false,
						fnAction =  function ()
							local realArea = TempTable[i * 20 + k].realArea
							local realServer = TempTable[i * 20 + k].realServer
							local dwID = TempTable[i * 20 + k].dwID
							LR_Acc_FB_Detail_Panel:ReloadItemBox(realArea, realServer, dwID)
						end,
						szIcon =  szIcon,
						nFrame =  nFrame,
						szLayer =  "ICON_RIGHT",
						rgb =  {r, g, b},
					}
				end
			end
		end
		for i = 0, page_num - 1, 1 do
			if i ~=  page_num - 1 then
				page[i][#page[i] + 1] = {bDevide = true}
				page[i][#page[i] + 1] = page[i+1]
				page[i][#page[i]].szOption = _L["Next 20 Records"]
			end
		end

		m = page[0]

		local __x, __y = hComboBox:GetAbsPos()
		local __w, __h = hComboBox:GetSize()
		m.nMiniWidth = __w
		m.x = __x
		m.y = __y + __h
		PopupMenu(m)
	end
	----------关于
	LR.AppendAbout(LR_Acc_FB_Detail_Panel, frame)
end

function LR_Acc_FB_Detail_Panel:Open(realArea, realServer, dwID)
	local frame = self:Fetch("LR_Acc_FB_Detail_Panel")
	if frame then
		self:Destroy(frame)
	else
		if realArea then
			LR_Acc_FB_Detail_Panel.realArea = realArea
			LR_Acc_FB_Detail_Panel.realServer = realServer
			LR_Acc_FB_Detail_Panel.dwID = dwID
		else
			local serverInfo = {GetUserServer()}
			local realArea, realServer = serverInfo[5], serverInfo[6]
			local szName = GetClientPlayer().szName
			LR_Acc_FB_Detail_Panel.realArea = realArea
			LR_Acc_FB_Detail_Panel.realServer = realServer
			LR_Acc_FB_Detail_Panel.dwID = GetClientPlayer().dwID
		end
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

function LR_Acc_FB_Detail_Panel:LoadItemBox(hWin)
	local hComboBox = self:Fetch("hComboBox")
	local FB_25R = LR_AccountStatistics_FBList.FB25R
	local FB_10R = LR_AccountStatistics_FBList.FB10R
	local realServer = LR_Acc_FB_Detail_Panel.realServer
	local realArea = LR_Acc_FB_Detail_Panel.realArea
	local dwID = LR_Acc_FB_Detail_Panel.dwID
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	local FB_Record = LR_AccountStatistics_FBList.AllUsrData[szKey] or {}

	local szName = ""
	if LR_AccountStatistics.AllUsrList[szKey] then
		szName = LR_AccountStatistics.AllUsrList[szKey].szName
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
		m = m+1

		local Text_break1 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_1", m), {w = 160, h = 30, x  = 36, y = 2, text = LR.MapType[FB_25R[i].dwMapID].szName , font = 18})
		Text_break1:SetHAlign(0)
		Text_break1:SetVAlign(1)

		local FB_ID = LR_AccountStatistics_FBList.GetFBIDByMapID(FB_Record, FB_25R[i].dwMapID)
		local Text_ID =  ""
		if FB_ID ~=  nil then
			Text_ID = sformat("ID: %d", FB_ID)
		else
			Text_ID = "--"
		end
		local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 140, h = 30, x  = 200, y = 2, text = Text_ID, font = 18})
		Text_break2:SetHAlign(1)
		Text_break2:SetVAlign(1)
	end

	local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 340, h = 30})
	local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 3, y = 0, w = 334, h = 30})
	Image_Line:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 49)
	Image_Line:SetImageType(10)
	Image_Line:SetAlpha(180)

	local Text_break1 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_1", m), {w = 160, h = 30, x  = 36, y = 3, text  = _L["10FB"] , font = 18})
	Text_break1:SetHAlign(0)
	Text_break1:SetVAlign(1)

	m = m+1
	for i = 1, #FB_10R do
		local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 340, h = 30})
		local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 0, y = 0, w = 340, h = 30})
		Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
		Image_Line:SetImageType(10)
		Image_Line:SetAlpha(200)

		if m % 2 ==  1 then
			Image_Line:Hide()
		end
		m = m+1

		local Text_break1 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_1", m), {w = 160, h = 30, x  = 36, y = 2, text = LR.MapType[FB_10R[i].dwMapID].szName  , font = 18})
		Text_break1:SetHAlign(0)
		Text_break1:SetVAlign(1)

		local FB_ID = LR_AccountStatistics_FBList.GetFBIDByMapID(FB_Record, FB_10R[i].dwMapID)
		local Text_ID =  ""
		if FB_ID ~=  nil then
			Text_ID = sformat("ID: %d", FB_ID)
		else
			Text_ID = "--"
		end

		local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 140, h = 30, x  = 200, y = 2, text = Text_ID, font = 18})
		Text_break2:SetHAlign(1)
		Text_break2:SetVAlign(1)
	end
end

function LR_Acc_FB_Detail_Panel:ReloadItemBox(realArea, realServer, dwID)
	LR_Acc_FB_Detail_Panel.dwID = dwID
	LR_Acc_FB_Detail_Panel.realServer = realServer
	LR_Acc_FB_Detail_Panel.realArea = realArea
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
LR_FB_Tips = {
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
	LR.DelayCall(500, function() LR_AccountStatistics_FBList.GetFBList() end)
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
	if not scene then
		return
	end
	if scene.nType ~=  MAP_TYPE.DUNGEON then
		return
	end
	local dwMapID = scene.dwMapID
	local nCopyIndex = scene.nCopyIndex
	local szName = Table_GetMapName(dwMapID)
	local MSG = {}
	local FB_ID = LR_AccountStatistics_FBList.GetFBIDByMapID(LR_AccountStatistics_FBList.SelfData, dwMapID)
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
	LR.DelayCall(150, function() LR_AccountStatistics_FBList.GetFBList() end)
end

LR.RegisterEvent("LOADING_END", function() LR_FB_Tips.LOADING_END() end)
LR.RegisterEvent("ON_MAP_COPY_PROGRESS_UPDATE", function() LR_FB_Tips.ON_MAP_COPY_PROGRESS_UPDATE() end)
LR.RegisterEvent("ON_APPLY_PLAYER_SAVED_COPY_RESPOND", function() LR_FB_Tips.ON_APPLY_PLAYER_SAVED_COPY_RESPOND() end)
