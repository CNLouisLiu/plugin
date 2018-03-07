local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local _L = LR.LoadLangPack(AddonPath)
local DB_name = "maindb.db"
local sformat, slen, sgsub, ssub, sfind = string.format, string.len, string.gsub, string.sub, string.find
local mfloor, mceil, mmin, mmax = math.floor, math.ceil, math.min, math.max
local tconcat, tinsert, tremove, tsort = table.concat, table.insert, table.remove, table.sort
--------------------------------------------------------------------
--记录阅读情况
-------------------------------------------------------------------
LR_AccountStatistics_BookRd = LR_AccountStatistics_BookRd or {}
LR_AccountStatistics_BookRd.src = "%s\\UsrData\\%s\\%s\\%s\\BookRecord_%s.dat"
LR_AccountStatistics_BookRd.UsrData = {
	On = true,
}
LR_AccountStatistics_BookRd.RecordList = {}	----存放自身的阅读数据
LR_AccountStatistics_BookRd.AllUsrData = {}

LR_AccountStatistics_BookRd.bHookedReadPanel = false
LR_AccountStatistics_BookRd.bHookedBookExchangePanel = false

function LR_AccountStatistics_BookRd.HookReadPanel()
	local frame = Station.Lookup("Normal/CraftReadManagePanel")
	if frame then --背包界面添加一个按钮
		local Btn_Read = frame:Lookup("Btn_Read")
		if not Btn_Read then
			if true then
				local Btn_Read = LR.AppendUI("Button", frame, "Btn_Read", {w = 90, h = 28, x = 55, y = 0})
				Btn_Read:SetText(_L["LR Mail"])
				Btn_Read.OnClick = function()
					LR_BookRd_Panel:Open()
				end
				Btn_Read.OnEnter = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local szTip = {}
					szTip[#szTip+1] = GetFormatText(_L["LR Reading Statistics"], 163)
					szTip[#szTip+1] = GetFormatText(sformat("\n%s", _L["Click here to open [LR Reading Statistics] panel"]), 162)
					local szOutputTip = tconcat(szTip)
					OutputTip(szOutputTip, 400, {x, y, w, h})
				end
				Btn_Read.OnLeave = function()
					HideTip()
				end
			end
		end
	end
end

function LR_AccountStatistics_BookRd.HookBookExchangePanel()
	local frame = Station.Lookup("Normal/BookExchangePanel")
	if not LR_AccountStatistics_BookRd.bHookedBookExchangePanel and frame and frame:IsVisible() then --书籍兑换界面添加一个按钮
		local temp = Wnd.OpenWindow("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics_ReadButton.ini", "LR_AccountStatistics_ReadButton")
		if not frame:Lookup("Btn_Read") then
			local hBtnRead = temp:Lookup("Btn_Read")
			if hBtnRead then
				hBtnRead:ChangeRelation(frame, true, true)
				hBtnRead:SetRelPos(55, 0)
				hBtnRead.OnLButtonClick = function()
					LR_BookRd_Panel:Open()
				end
				hBtnRead.OnMouseEnter = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local szTip = {}
					szTip[#szTip+1] = GetFormatText(_L["LR Reading Statistics"], 163)
					szTip[#szTip+1] = GetFormatText(sformat("\n%s", _L["Click here to open [LR Reading Statistics] panel"]), 162)
					local szOutputTip = tconcat(szTip)
					OutputTip(szOutputTip, 400, {x, y, w, h})
				end
				hBtnRead.OnMouseLeave = function()
					HideTip()
				end
			end
		end
		Wnd.CloseWindow(temp)
		LR_AccountStatistics_BookRd.bHookedBookExchangePanel = false
	elseif not frame or not frame:IsVisible() then
		LR_AccountStatistics_BookRd.bHookedBookExchangePanel = false
	end
end

function LR_AccountStatistics_BookRd.SaveData(DB)
	local me =  GetClientPlayer()
	if not me then
		return
	end
	if IsRemotePlayer(me.dwID) then
		return
	end
	LR_AccountStatistics_BookRd.GetSelfBookRecord()
	local ServerInfo = {GetUserServer()}
	local realArea, realServer = ServerInfo[5], ServerInfo[6]
	local dwID = me.dwID
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	local RecordList = {}
	for dwBookID,  v in pairs (LR_AccountStatistics_BookRd.RecordList) do
		RecordList[tostring(dwBookID)] = {}
		for dwSegmentID, v2 in pairs (v) do
			RecordList[tostring(dwBookID)][tostring(dwSegmentID)] = true
		end
	end
	local DB_REPLACE = DB:Prepare("REPLACE INTO bookrd_data ( szKey, bookrd_data, bDel ) VALUES ( ?, ?, ? )")
	if LR_AS_Base.UsrData.OthersCanSee then
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey, LR.JsonEncode(RecordList), 0)
		DB_REPLACE:Execute()
	else
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(szKey, LR.JsonEncode({}), 1)
		DB_REPLACE:Execute()
	end
end
--LR_AS_Base.Add2AutoSave({szKey = "SaveBookRdData", fnAction = LR_AccountStatistics_BookRd.SaveData, order = 40})

function LR_AccountStatistics_BookRd.LoadAllUsrData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM bookrd_data WHERE bDel = 0 AND szKey IS NOT NULL")
	local Data = DB_SELECT:GetAll() or {}
	local AllUsrData = {}
	for k, v in pairs(Data) do
		AllUsrData[v.szKey] = {}
		local bookrd_data = {}
		for dwBookID, v2 in pairs(LR.JsonDecode(v.bookrd_data)) do
			bookrd_data[tonumber(dwBookID)] = {}
			for dwSegmentID, v3 in pairs(v2) do
				bookrd_data[tonumber(dwBookID)][tonumber(dwSegmentID)] = true
			end
		end
		AllUsrData[v.szKey] = clone (bookrd_data)
	end
	--讲自己的数据加入列表
	LR_AccountStatistics_BookRd.GetSelfBookRecord()
	local ServerInfo = {GetUserServer()}
	local realArea, realServer = ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, GetClientPlayer().dwID)
	AllUsrData[szKey] = clone(LR_AccountStatistics_BookRd.RecordList)
	LR_AccountStatistics_BookRd.AllUsrData = clone(AllUsrData)
	--Output(LR_AccountStatistics_BookRd.AllUsrData)
end

function LR_AccountStatistics_BookRd.GetSelfBookRecord()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local RecordList = {}
	local RowCount =  g_tTable.BookSegment:GetRowCount()
	local i = 2
	while i<= RowCount do
		local t = g_tTable.BookSegment:GetRow(i)
		local BookSuitID = t.dwBookID
		local num = t.dwBookNumber
		for k = 1, num, 1 do
			if me.IsBookMemorized(BookSuitID, k) then
				RecordList[BookSuitID] = RecordList[BookSuitID] or {}
				RecordList[BookSuitID][k]  = true
			end
		end
		i = i+t.dwBookNumber
	end
	LR_AccountStatistics_BookRd.RecordList = clone(RecordList)
end

------------------------------------------------------------------------------------
-----载入任务信息
------------------------------------------------------------------------------------
LR_AccountStatistics_BookRd.MissionData = {}
function LR_AccountStatistics_BookRd.LoadMissionData()
	local src = "Interface\\LR_Plugin\\LR_AccountStatistics\\Script\\AllMission.dat"
	LR_AccountStatistics_BookRd.MissionData = LoadLUAData(src) or {}
end

------------------------------------------------------------------------------------
-----载入碑铭信息
------------------------------------------------------------------------------------
LR_AccountStatistics_BookRd.BeiMingData = {}
function LR_AccountStatistics_BookRd.LoadBeiMingData()
	local src = "Interface\\LR_Plugin\\LR_AccountStatistics\\Script\\BeiMingData.dat"
	LR_AccountStatistics_BookRd.BeiMingData = LoadLUAData(src) or {}
end

------------------------------------------------------------------------------------
-----载入卖书籍的商店的信息
------------------------------------------------------------------------------------
LR_AccountStatistics_BookRd.BookShopData = {}
function LR_AccountStatistics_BookRd.LoadBookShopData()
	local src = "Interface\\LR_Plugin\\LR_AccountStatistics\\Script\\BookSelling.dat"
	LR_AccountStatistics_BookRd.BookShopData = LoadLUAData(src) or {}
end

------------------------------------------------------------------------------------
-----载入书籍掉落的信息
------------------------------------------------------------------------------------
LR_AccountStatistics_BookRd.BookLootData = {}
function LR_AccountStatistics_BookRd.LoadBookLootData()
	local src = "Interface\\LR_Plugin\\LR_AccountStatistics\\Script\\DoodadLoot.dat"
	LR_AccountStatistics_BookRd.BookLootData = LoadLUAData(src) or {}
end

function LR_AccountStatistics_BookRd.LOGIN_GAME()
	LR_AccountStatistics_BookRd.LoadMissionData()
	LR_AccountStatistics_BookRd.LoadBeiMingData()
	LR_AccountStatistics_BookRd.LoadBookShopData()
	LR_AccountStatistics_BookRd.LoadBookLootData()
	Log("LR bookrd_data loaded.\n")
end

LR.RegisterEvent("LOGIN_GAME", function() LR_AccountStatistics_BookRd.LOGIN_GAME() end)
------------------------------------------------------------------------------------
-----阅读小窗口
------------------------------------------------------------------------------------
LR_BookRd_Panel = CreateAddon("LR_BookRd_Panel")
LR_BookRd_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_BookRd_Panel.UserData = {
	Anchor = {s = "CENTER", r = "CENTER", x = 0, y = 0},
}

LR_BookRd_Panel.nPlayerName = ""
LR_BookRd_Panel.nrealServer = ""
LR_BookRd_Panel.searchText = ""
LR_BookRd_Panel.BookSuitID = 0
LR_BookRd_Panel.BookSuitNum = 0
LR_BookRd_Panel.BookSuitIDSelect = nil
LR_BookRd_Panel.BookNameSelect = nil
LR_BookRd_Panel.BookNameID = 0
LR_BookRd_Panel.BookRecord = {}
LR_BookRd_Panel.AllData = {}

local CustomVersion = "20170111"
RegisterCustomData("LR_BookRd_Panel.UserData", CustomVersion)

LR_BookRd_Panel:BindEvent("OnFrameDragEnd", "OnDragEnd")
LR_BookRd_Panel:BindEvent("OnFrameDestroy", "OnDestroy")
LR_BookRd_Panel:BindEvent("OnFrameKeyDown", "OnKeyDown")

--获取套书ID
--返回dwBookID：套书ID 以及 dwBookNumber:套书有几本
function LR_BookRd_Panel.GetSuitBookID(szName)
	local RowCount =  g_tTable.BookSegment:GetRowCount()
	local i = 1
	while i<= RowCount do
		local t = g_tTable.BookSegment:GetRow(i)
		if szName == t.szBookName then
			return t.dwBookID, t.dwBookNumber
		end
		i = i+t.dwBookNumber
	end
end

function LR_BookRd_Panel.GetBookName(dwBookID, dwSegmentID)
	local szBookName = ""
	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		szBookName = tBookSegment.szBookName
	end
	return szBookName
end

function LR_BookRd_Panel.GetSegmentName(dwBookID, dwSegmentID)
	local szSegmentName = ""
	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		szSegmentName = tBookSegment.szSegmentName
	end
	return szSegmentName
end

function LR_BookRd_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("CUSTOM_DATA_LOADED")
	LR_BookRd_Panel.UpdateAnchor(this)
	RegisterGlobalEsc("LR_BookRd_Panel", function () return true end , function() LR_BookRd_Panel:Open() end)
	local player =  GetClientPlayer()
	if not player then
		return
	end
	-------打开面板时保存数据
	if LR_AS_Base.UsrData.AutoSave and LR_AS_Base.UsrData.OpenSave then
		LR_AS_Base.AutoSave()
	end
	--加载阅读数据
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	LR_AccountStatistics_BookRd.LoadAllUsrData(DB)
	DB:Execute("END TRANSACTION")
	DB:Release()
end

function LR_BookRd_Panel:OnEvents(event)
	if event ==  "CUSTOM_DATA_LOADED" then
		if arg0 ==  "Role" then
			LR_BookRd_Panel.UpdateAnchor(this)
		end
	elseif event ==  "UI_SCALED" then
		LR_BookRd_Panel.UpdateAnchor(this)
	end
end

function LR_BookRd_Panel.UpdateAnchor(frame)
	frame:SetPoint(LR_BookRd_Panel.UserData.Anchor.s, 0, 0, LR_BookRd_Panel.UserData.Anchor.r, LR_BookRd_Panel.UserData.Anchor.x, LR_BookRd_Panel.UserData.Anchor.y)
	frame:CorrectPos()
end

function LR_BookRd_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_BookRd_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)

	LR_BookRd_Panel.nPlayerName = ""
	LR_BookRd_Panel.nrealServer = ""
	LR_BookRd_Panel.searchText = ""
	LR_BookRd_Panel.BookSuitID = 0
	LR_BookRd_Panel.BookSuitNum = 0
	LR_BookRd_Panel.BookSuitIDSelect = nil
	LR_BookRd_Panel.BookNameSelect = nil
	LR_BookRd_Panel.BookNameID = 0
	LR_BookRd_Panel.BookRecord = {}
	LR_BookRd_Panel.AllData = {}
end

function LR_BookRd_Panel:OnDragEnd()
	this:CorrectPos()
	LR_BookRd_Panel.UserData.Anchor = GetFrameAnchor(this)
end

function LR_BookRd_Panel:Init()
	local frame = self:Append("Frame", "LR_BookRd_Panel", {title = _L["LR Reading Statistics"], style = "NORMAL"})

	local imgTab = self:Append("Image", frame, "TabImg", {w = 768, h = 33, x = 0, y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)


	local hPageSet = self:Append("PageSet", frame, "PageSet", {x = 20, y = 120, w = 748, h = 360})
	--动态套书名称
	local hWinIconView = self:Append("Window", hPageSet, "WindowBookSuitBox", {x = 0, y = 0, w = 250, h = 360})
	local hScroll1 = self:Append("Scroll", hWinIconView, "ScrollBookSuitBox", {x = 0, y = 0, w = 250, h = 360})
	self:LoadBookSuitBox(hScroll1)
	hScroll1:UpdateList()

	--动态书籍名称
	local hWinIconView2 = self:Append("Window", hPageSet, "WindowBookNameBox", {x = 250, y = 0, w = 200, h = 180})
	local hScroll2 = self:Append("Scroll", hWinIconView2, "ScrollBookNameBox", {x = 0, y = 0, w = 200, h = 180})
	self:LoadBookNameBox(hScroll2)
	hScroll2:UpdateList()

	--动态人物名称
	local hWinIconView3 = self:Append("Window", hPageSet, "WindowUsrNameBox", {x = 450, y = 0, w = 200, h = 180})
	local hScroll3 = self:Append("Scroll", hWinIconView3, "ScrollUsrNameBox", {x = 0, y = 0, w = 200, h = 180})
	self:LoadUsrNameBox(hScroll3)
	hScroll3:UpdateList()

	--动态来源信息
	local hWinIconView4 = self:Append("Window", hPageSet, "WindowSourceBox", {x = 250, y = 210, w = 400, h = 150})
	local hScroll4 = self:Append("Scroll", hWinIconView4, "ScrollSourceBox", {x = 0, y = 0, w = 400, h = 150})
	self:GetSource(hScroll4)
	hScroll4:UpdateList()

	-------------初始界面物品
	-------------套书名称框
	local hHandle = self:Append("Handle", frame, "Handle", {x = 18, y = 90, w = 250, h = 390})

	local Image_Record_BG = self:Append("Image", hHandle, "Image_Record_BG", {x = 0, y = 0, w = 250, h = 390})
	Image_Record_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 50)
	Image_Record_BG:SetImageType(10)

	local Image_Record_BG1 = self:Append("Image", hHandle, "Image_Record_BG1", {x = 0, y = 30, w = 250, h = 360})
	Image_Record_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74)
	Image_Record_BG1:SetImageType(10)
	Image_Record_BG1:SetAlpha(110)

	local Image_Record_Line1_0 = self:Append("Image", hHandle, "Image_Record_Line1_0", {x = 3, y = 28, w = 250, h = 3})
	Image_Record_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 65)
	Image_Record_Line1_0:SetImageType(11)
	Image_Record_Line1_0:SetAlpha(115)

	local Image_Record_Break1 = self:Append("Image", hHandle, "Image_Record_Break1", {x = 50, y = 2, w = 3, h = 386})
	Image_Record_Break1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
	Image_Record_Break1:SetImageType(11)
	Image_Record_Break1:SetAlpha(160)

	local Text_break1 = self:Append("Text", hHandle, "Text_break1", {w = 50, h = 30, x  = 0, y = 2, text = _L["ID"], font = 18})
	Text_break1:SetHAlign(1)
	Text_break1:SetVAlign(1)

	local Text_break2 = self:Append("Text", hHandle, "Text_break1", {w = 200, h = 30, x  = 50, y = 2, text = _L["Suitbook Name"], font = 18})
	Text_break2:SetHAlign(1)
	Text_break2:SetVAlign(1)

	-------------书籍名称框
	local hHandle2 = self:Append("Handle", frame, "Handle2", {x = 270, y = 90, w = 200, h = 210})

	local Image_Record_BG2 = self:Append("Image", hHandle2, "Image_Record_BG2", {x = 0, y = 0, w = 200, h = 210})
	Image_Record_BG2:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 50)
	Image_Record_BG2:SetImageType(10)

	local Image_Record_BG3 = self:Append("Image", hHandle2, "Image_Record_BG3", {x = 0, y = 30, w = 200, h = 180})
	Image_Record_BG3:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74)
	Image_Record_BG3:SetImageType(10)
	Image_Record_BG3:SetAlpha(110)

	local Image_Record_Line2_0 = self:Append("Image", hHandle2, "Image_Record_Line2_0", {x = 3, y = 28, w = 200, h = 3})
	Image_Record_Line2_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 65)
	Image_Record_Line2_0:SetImageType(11)
	Image_Record_Line2_0:SetAlpha(115)

	local Text_break3 = self:Append("Text", hHandle2, "Text_break3", {w = 200, h = 30, x  = 0, y = 2, text = _L["Book Name"], font = 18})
	Text_break3:SetHAlign(1)
	Text_break3:SetVAlign(1)

	-------------人物名字框
	local hHandle3 = self:Append("Handle", frame, "Handle3", {x = 470, y = 90, w = 200, h = 210})

	local Image_Record_BG4 = self:Append("Image", hHandle3, "Image_Record_BG4", {x = 0, y = 0, w = 200, h = 210})
	Image_Record_BG4:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 50)
	Image_Record_BG4:SetImageType(10)

	local Image_Record_BG5 = self:Append("Image", hHandle3, "Image_Record_BG5", {x = 0, y = 30, w = 200, h = 180})
	Image_Record_BG5:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74)
	Image_Record_BG5:SetImageType(10)
	Image_Record_BG5:SetAlpha(110)

	local Image_Record_Line3_0 = self:Append("Image", hHandle3, "Image_Record_Line3_0", {x = 3, y = 28, w = 200, h = 3})
	Image_Record_Line3_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 65)
	Image_Record_Line3_0:SetImageType(11)
	Image_Record_Line3_0:SetAlpha(115)

	local Text_break4 = self:Append("Text", hHandle3, "Text_break4", {w = 200, h = 30, x  = 0, y = 2, text = _L["Readed Character"], font = 18})
	Text_break4:SetHAlign(1)
	Text_break4:SetVAlign(1)

	-----------来源
	local hHandle4 = self:Append("Handle", frame, "Handle4", {x = 270, y = 300, w = 400, h = 180})

	local Image_Record_BG6 = self:Append("Image", hHandle4, "Image_Record_BG6", {x = 0, y = 0, w = 400, h = 180})
	Image_Record_BG6:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 50)
	Image_Record_BG6:SetImageType(10)

	local Image_Record_BG7 = self:Append("Image", hHandle4, "Image_Record_BG7", {x = 0, y = 30, w = 400, h = 150})
	Image_Record_BG7:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74)
	Image_Record_BG7:SetImageType(10)
	Image_Record_BG7:SetAlpha(110)

	local Image_Record_Line4_0 = self:Append("Image", hHandle4, "Image_Record_Line4_0", {x = 3, y = 28, w = 400, h = 3})
	Image_Record_Line4_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 65)
	Image_Record_Line4_0:SetImageType(11)
	Image_Record_Line4_0:SetAlpha(115)

	local Text_break5 = self:Append("Text", hHandle4, "Text_break5", {w = 400, h = 30, x  = 0, y = 2, text = _L["Source"], font = 18})
	Text_break5:SetHAlign(1)
	Text_break5:SetVAlign(1)


	----------搜索
	local hTextSearch = self:Append("Text", frame, "TextSearch", {w = 20, h = 26, x = 20, y = 51, text = _L["Key words"], })
	local hEditBox = self:Append("Edit", frame, "searchText", {w = 200 , h = 26, x = 80, y = 51, text = ""})
	hEditBox:Enable(true)
	hEditBox.OnChange = function (value)
		LR_BookRd_Panel.searchText = sgsub(value, " ", "")

		LR_BookRd_Panel.BookSuitIDSelect = nil
		LR_BookRd_Panel.BookNameSelect = nil
		LR_BookRd_Panel.BookSuitID = 0
		LR_BookRd_Panel.BookNameID = 0
		LR_BookRd_Panel.BookSuitNum = 0


		--LR_AccountStatistics_Bag_Panel.LoadUserAllData()
		local cc = self:Fetch("ScrollBookSuitBox")
		if cc then
			self:ClearHandle(cc)
		end
		self:LoadBookSuitBox(cc)
		cc:UpdateList()

		--刷新已读人物名称
		local ScrollBookNameBox = self:Fetch("ScrollBookNameBox")
		if ScrollBookNameBox then
			self:ClearHandle(ScrollBookNameBox)
		end
		self:LoadUsrNameBox(ScrollBookNameBox)
		ScrollBookNameBox:UpdateList()
		--刷新已读人物名称
		local ScrollUsrNameBox = self:Fetch("ScrollUsrNameBox")
		if ScrollUsrNameBox then
			self:ClearHandle(ScrollUsrNameBox)
		end
		self:LoadUsrNameBox(ScrollUsrNameBox)
		ScrollUsrNameBox:UpdateList()
		----刷新来源
		local ScrollSourceBox = self:Fetch("ScrollSourceBox")
		if ScrollSourceBox then
			self:ClearHandle(ScrollSourceBox)
		end
		self:GetSource(ScrollSourceBox)
		ScrollSourceBox:UpdateList()
	end

	----------抄书插件
	local hButton = self:Append("Button", frame, "Button" , {w = 180, x = 50, y = 480, text = _L["Open [LR Printing Machine]"]})
	hButton:Enable(true)
	hButton.OnClick = function ()
		LR_TOOLS:OpenPanel(_L["LR Printing Machine"])
	end

	----------关于
	LR.AppendAbout(LR_BookRd_Panel, frame)
end

function LR_BookRd_Panel:Open()
	local frame = self:Fetch("LR_BookRd_Panel")
	if frame then
		self:Destroy(frame)
	else
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

function LR_BookRd_Panel:LoadBookSuitBox(hWin)
	local player =  GetClientPlayer()
	if not player then
		return
	end

	local m = 1
	local RowCount =  g_tTable.BookSegment:GetRowCount()
	local i = 2
	while i<= RowCount do
		local t = g_tTable.BookSegment:GetRow(i)
		local BookSuitID = t.dwBookID
		local num = t.dwBookNumber
		local BookSuitName = t.szBookName
		local bShow = false
		local _start, _end = sfind(BookSuitName, LR_BookRd_Panel.searchText)
		for k = 1, num do
			local name = LR_BookRd_Panel.GetSegmentName(BookSuitID, k)
			local _start, _end = sfind(name, LR_BookRd_Panel.searchText)
			if _start then
				bShow = true
			end
		end
		if _start or bShow then
			--背景条
			local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 246, h = 30})
			--hIconViewContent:RegisterEvent(524596)

			local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 0, y = 0, w = 246, h = 30})
			Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
			Image_Line:SetImageType(10)
			Image_Line:SetAlpha(200)
			if m%2 == 0 then
				Image_Line:SetAlpha(35)
			end
			--悬停框
			local Image_Hover = self:Append("Image", hIconViewContent, sformat("Image_Hover_%d", m), {x = 2, y = 0, w = 246, h = 30})
			Image_Hover:FromUITex("ui\\Image\\Common\\TempBox.UITex", 5)
			Image_Hover:SetImageType(10)
			Image_Hover:SetAlpha(200)
			Image_Hover:Hide()
			--选择框
			local Image_Select = self:Append("Image", hIconViewContent, sformat("Image_Select_%d", m), {x = 2, y = 0, w = 246, h = 30})
			Image_Select:FromUITex("ui\\Image\\Common\\TempBox.UITex", 6)
			Image_Select:SetImageType(10)
			Image_Select:SetAlpha(200)
			Image_Select:Hide()

			--序号
			local Text_break1 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_1", m), {w = 50, h = 30, x  = 0, y = 2, text = m , font = 18})
			Text_break1:SetHAlign(1)
			Text_break1:SetVAlign(1)
			--套书名称
			local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 200, h = 30, x  = 60, y = 2, text = BookSuitName , font = 18})
			Text_break2:SetHAlign(0)
			Text_break2:SetVAlign(1)

			--鼠标操作
			hIconViewContent.OnClick = function()
				LR_BookRd_Panel.BookSuitID = BookSuitID
				LR_BookRd_Panel.BookNameID = 0
				LR_BookRd_Panel.BookSuitNum = num
				LR_BookRd_Panel.BookNameSelect = nil

				--刷新已读人物名称
				local ScrollUsrNameBox = self:Fetch("ScrollUsrNameBox")
				if ScrollUsrNameBox then
					self:ClearHandle(ScrollUsrNameBox)
				end
				self:LoadUsrNameBox(ScrollUsrNameBox)
				ScrollUsrNameBox:UpdateList()
				----刷新来源
				local ScrollSourceBox = self:Fetch("ScrollSourceBox")
				if ScrollSourceBox then
					self:ClearHandle(ScrollSourceBox)
				end
				self:GetSource(ScrollSourceBox)
				ScrollSourceBox:UpdateList()

				if LR_BookRd_Panel.BookSuitIDSelect ~= nil then
					LR_BookRd_Panel.BookSuitIDSelect:Hide()
				end
				LR_BookRd_Panel.BookSuitIDSelect = Image_Select
				Image_Select:Show()
				local ScrollBookNameBox = self:Fetch("ScrollBookNameBox")
				if ScrollBookNameBox then
					self:ClearHandle(ScrollBookNameBox)
				end
				self:LoadBookNameBox(ScrollBookNameBox)
				ScrollBookNameBox:UpdateList()
			end
			hIconViewContent.OnEnter = function()
				--Output(t)
				Image_Hover:Show()
			end
			hIconViewContent.OnLeave = function()
				Image_Hover:Hide()
			end
			m = m+1
		end
		i = i+t.dwBookNumber
	end
end

function LR_BookRd_Panel:LoadBookNameBox(hWin)
	local player =  GetClientPlayer()
	if not player then
		return
	end
	local m = 1
	if LR_BookRd_Panel.BookSuitID ==  0  then
		return
	end
	for i = 1, LR_BookRd_Panel.BookSuitNum, 1 do
		local BookName = LR_BookRd_Panel.GetSegmentName(LR_BookRd_Panel.BookSuitID, i)
		--背景条
		local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 196, h = 30})
		local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 0, y = 0, w = 196, h = 30})
		Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
		Image_Line:SetImageType(10)
		Image_Line:SetAlpha(200)
		if m%2 == 0 then
			Image_Line:SetAlpha(35)
		end

		--悬停框
		local Image_Hover = self:Append("Image", hIconViewContent, sformat("Image_Hover_%d", m), {x = 0, y = 0, w = 198, h = 30})
		Image_Hover:FromUITex("ui\\Image\\Common\\TempBox.UITex", 5)
		Image_Hover:SetImageType(10)
		Image_Hover:SetAlpha(200)
		Image_Hover:Hide()
		--选择框
		local Image_Select = self:Append("Image", hIconViewContent, sformat("Image_Select_%d", m), {x = 2, y = 0, w = 198, h = 30})
		Image_Select:FromUITex("ui\\Image\\Common\\TempBox.UITex", 6)
		Image_Select:SetImageType(10)
		Image_Select:SetAlpha(200)
		Image_Select:Hide()

		--套书名称
		local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 200, h = 30, x  = 15, y = 2, text = BookName , font = 18})
		Text_break2:SetHAlign(0)
		Text_break2:SetVAlign(1)
		if player.IsBookMemorized(LR_BookRd_Panel.BookSuitID, i) then

		else
			Text_break2:SetFontColor(192, 192, 192)
		end

		--鼠标操作
		hIconViewContent.OnClick = function()
			if LR_BookRd_Panel.BookNameSelect ~= nil then
				LR_BookRd_Panel.BookNameSelect:Hide()
			end
			LR_BookRd_Panel.BookNameSelect = Image_Select
			Image_Select:Show()
			LR_BookRd_Panel.BookNameID = i
			--刷新已读人物名称
			local ScrollUsrNameBox = self:Fetch("ScrollUsrNameBox")
			if ScrollUsrNameBox then
				self:ClearHandle(ScrollUsrNameBox)
			end
			self:LoadUsrNameBox(ScrollUsrNameBox)
			ScrollUsrNameBox:UpdateList()
			----刷新来源
			local ScrollSourceBox = self:Fetch("ScrollSourceBox")
			if ScrollSourceBox then
				self:ClearHandle(ScrollSourceBox)
			end
			self:GetSource(ScrollSourceBox)
			ScrollSourceBox:UpdateList()

		end
		hIconViewContent.OnEnter = function()
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local info = ""

			local nTabtype = 5
			local nIndex = LR.Table_GetBookItemIndex(LR_BookRd_Panel.BookSuitID, i)
			local itemInfo = GetItemInfo(nTabtype, nIndex)
			--Output(itemInfo)

			info = GetBookTipByItemInfo(itemInfo, LR_BookRd_Panel.BookSuitID, i, true)
			OutputTip(info, 400, { x, y, w, h })
			Image_Hover:Show()
		end
		hIconViewContent.OnLeave = function()
			HideTip()
			Image_Hover:Hide()
		end

		m = m+1
	end
end

function LR_BookRd_Panel:LoadUsrNameBox(hWin)
	local player =  GetClientPlayer()
	if not player then
		return
	end
	if LR_BookRd_Panel.BookSuitID ==  0 or LR_BookRd_Panel.BookNameID ==  0 then
		return
	end

	local m = 1
	for szKey, v in pairs(LR_AccountStatistics_BookRd.AllUsrData) do
		if v[LR_BookRd_Panel.BookSuitID] and next(v[LR_BookRd_Panel.BookSuitID]) ~= nil then
			if v[LR_BookRd_Panel.BookSuitID][LR_BookRd_Panel.BookNameID] then
				--背景条
				local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 196, h = 30})
				local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 0, y = 0, w = 196, h = 30})
				Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
				Image_Line:SetImageType(10)
				Image_Line:SetAlpha(200)

				local User = LR_AS_Info.AllUsrData[szKey]
				if User then
					local r, g, b = LR.GetMenPaiColor(User.dwForceID)
					local Image_MenPai = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 15, y = 0, w = 30, h = 30})
					Image_MenPai:FromUITex(GetForceImage(User.dwForceID))
					--人物名称
					local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 150, h = 30, x  = 50, y = 2, text = User.szName , font = 18})
					Text_break2:SetHAlign(0)
					Text_break2:SetVAlign(1)
					Text_break2:SetFontColor(r, g, b)
				end
			end
		end
		m = m+1
	end
end

function LR_BookRd_Panel:GetSource(hWin)
	local player  = GetClientPlayer()
	if not player then
		return
	end
	if LR_BookRd_Panel.BookSuitID ==  0 or LR_BookRd_Panel.BookNameID ==  0 then
		return
	end
	m = 1
	local szBookName = LR_BookRd_Panel.GetSegmentName(LR_BookRd_Panel.BookSuitID, LR_BookRd_Panel.BookNameID)
	szBookName = LR.Trim(szBookName)

	------任务
	for i = 1, #LR_AccountStatistics_BookRd.MissionData, 1 do
		if LR_AccountStatistics_BookRd.MissionData[i].szBookName ==  szBookName then
			--背景条
			local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 396, h = 30})
			local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 0, y = 0, w = 396, h = 30})
			Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
			Image_Line:SetImageType(10)
			Image_Line:SetAlpha(200)

			--任务名称
			local szName = LR_AccountStatistics_BookRd.MissionData[i].szQuestName
			local szMapName = Table_GetMapName(LR_AccountStatistics_BookRd.MissionData[i].dwMapID)
			local szAcceptNpcName = LR_AccountStatistics_BookRd.MissionData[i].szAcceptNpcName
			local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 396, h = 30, x  = 15, y = 2, text  = sformat("%s%s（%s）%s", _L["[Quest]"], szName, szMapName, szAcceptNpcName), font = 31})
			Text_break2:SetHAlign(0)
			Text_break2:SetVAlign(1)

			m = m+1
		end
	end

	-----碑铭
	for i = 1, #LR_AccountStatistics_BookRd.BeiMingData, 1 do
		local data = LR_AccountStatistics_BookRd.BeiMingData[i]
		local _start, _end = sfind(data.szBeiMingName, szBookName)
		if _start then
			--背景条
			local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 396, h = 30})
			local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 0, y = 0, w = 396, h = 30})
			Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
			Image_Line:SetImageType(10)
			Image_Line:SetAlpha(200)
			--碑铭名称
			local szMapName = Table_GetMapName(data.dwMapID)
			local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 396, h = 30, x  = 15, y = 2, text  = sformat("%s%s（%s）", _L["[BEI]"], data.szBeiMingName, szMapName), font = 36})
			Text_break2:SetHAlign(0)
			Text_break2:SetVAlign(1)

			m = m+1
		end
	end


	------商店
	for i = 1, #LR_AccountStatistics_BookRd.BookShopData, 1 do
		for k = 1, #LR_AccountStatistics_BookRd.BookShopData[i].tSellItem, 1 do
			if LR.Trim(LR_AccountStatistics_BookRd.BookShopData[i].tSellItem[k].szItemName) ==  LR.Trim(szBookName) then
				--背景条
				local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 396, h = 30})
				local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 0, y = 0, w = 396, h = 30})
				Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
				Image_Line:SetImageType(10)
				Image_Line:SetAlpha(200)
				--商店名称
				local szMapName = Table_GetMapName(LR_AccountStatistics_BookRd.BookShopData[i].dwMapID)
				local szTitle = LR_AccountStatistics_BookRd.BookShopData[i].szNpcTitle
				local szNpcName = LR_AccountStatistics_BookRd.BookShopData[i].szNpcName
				local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 396, h = 30, x  = 15, y = 2, text = sformat("【%s】%s（%s）", szTitle, szNpcName, szMapName), font = 39})
				Text_break2:SetHAlign(0)
				Text_break2:SetVAlign(1)

				m = m+1
			end
		end
	end


	---杀怪掉落
	for i = 1, #LR_AccountStatistics_BookRd.BookLootData, 1 do
		if LR.Trim(LR_AccountStatistics_BookRd.BookLootData[i].szBookName) ==  LR.Trim(szBookName) then
			--背景条
			local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 396, h = 30})
			local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 0, y = 0, w = 396, h = 30})
			Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
			Image_Line:SetImageType(10)
			Image_Line:SetAlpha(200)
			--掉落名称
			local text = LR_AccountStatistics_BookRd.BookLootData[i].Loot
			local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 396, h = 30, x  = 15, y = 2, text = sformat("%s%s", _L["Drop"], text), font = 35})
			Text_break2:SetHAlign(0)
			Text_break2:SetVAlign(1)
			m = m+1
		end
	end

	----------什么都没有
	if m == 1 then
		--背景条
		local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", m), {x = 0, y = 0, w = 396, h = 30})
		local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", m), {x = 0, y = 0, w = 396, h = 30})
		Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
		Image_Line:SetImageType(10)
		Image_Line:SetAlpha(200)
		--任务名称
		local Text_break2 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_2", m), {w = 396, h = 30, x  = 15, y = 2, text = _L["Click to goto JX3 Official BBS."] , font = 39})
		Text_break2:SetHAlign(0)
		Text_break2:SetVAlign(1)

		hIconViewContent.OnClick = function()
			OpenBrowser("http://jx3.bbs.xoyo.com/forum.php?mod = viewthread&tid = 33236551")
		end
		--Output(LR.Trim(szBookName))
	end

end



