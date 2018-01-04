local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local DB_name = "maindb.db"
local _L  =  LR.LoadLangPack(AddonPath)
local sformat, slen, sgsub, ssub, sfind  =  string.format, string.len, string.gsub, string.sub, string.find
local mfloor, mceil  =  math.floor, math.ceil
local tconcat, tinsert, tremove, tsort  =  table.concat, table.insert, table.remove, table.sort
-------------------------------------------------------------
LR_AccountStatistics_Achievement = {}
LR_AccountStatistics_Achievement.SelfData = {}
LR_AccountStatistics_Achievement.AllUsrData = {}

LR_AccountStatistics_Achievement.fenlei = {
	[_L["MengHuiDaoXiang"]] = {5449, 5450, 5451, 5452, 5453, 5454, 5455, 5456, 5457, 5458, 5459, 5460, 5461, 5462, 5463, 5464, 5465, 5466, 5467, 5468, 5469, 5470, }, 	--梦回稻香
	[_L["MidAutumn"]] = {1434, 1435, 598, 599, 600, 596, 595, 601, 1060, 1061, 1062, 2629, 2650, 2651, 2652, 2653, 2654, 597, 2605, 2631, 2644, }, 	--中秋节
	[_L["ChineseNewYear"]] = {1571, 1576, 1243, 1245, 1252, 1246, 2899, 2900, 2901, 3391, 4037, 4490, 5274, 5275, 5276, 5277, 1248, 1254, 1244}, 	--春节
	[_L["NewYearsDay"]] = {2889, 2890, 2895, 2891, }, 	--元旦
	[_L["FlowerFestival"]] = {3416, 3417, 3418, 5327, }, 	--花朝节
	[_L["LanternFestival"]] = {4041, 4042, 4043, 4044, }, 	--元宵节
	[_L["ChingMingFestival"]] = {1736, 1737, 1738, 1739, 1740, 1727}, 	--清明节
	[_L["DragonBoatFestival"]] = {1381, 1390, 1391, 1392, 4581, 4582, 5344, 1369, 1376, 1386, 2465, }, 	--端午节
	[_L["ChineseValentineDay"]] = {1394, 1412, 2588, 2589, 2591, 2592, 2593, 2594, 2595, 4647, }, 	--七夕
	[_L["WinterSolstice"]] = {1539, 1199, 1200, 1201, 1202, 1203, 2887, 2888, 3389, 4035, 4486, 5228, 1516, 1171, 1180, 1186, }, 	--冬至节
	[_L["DoubleNinthFestival"]] = {4296, 4297, 4298, 4299}, 		--重阳节
}

--获取成就数据
function LR_AccountStatistics_Achievement.GetSelfData()
	local me = GetClientPlayer()
	if not me then
		return
	end

	for k, v in pairs(LR_AccountStatistics_Achievement.fenlei) do
		if type(v) == "table" then
			--Output(k)
			for i = 1, #v, 1 do
				LR_AccountStatistics_Achievement.SelfData[v[i]] = me.IsAchievementAcquired(v[i])
				--Output(v[i])
			end
		end
	end
end
--保存成就数据
function LR_AccountStatistics_Achievement.SaveData(DB)
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local SelfData = {}
	LR_AccountStatistics_Achievement.GetSelfData()
	for achievement_id, v in pairs (LR_AccountStatistics_Achievement.SelfData) do
		SelfData[tostring(achievement_id)] = v
	end
	local DB_REPLACE = DB:Prepare("REPLACE INTO achievement_data ( szKey, achievement_data, bDel ) VALUES ( ?, ?, ? )")
	DB_REPLACE:ClearBindings()
	if LR_AS_Base.UsrData.OthersCanSee then
		DB_REPLACE:BindAll(szKey, LR.JsonEncode(SelfData), 0)
	else
		DB_REPLACE:BindAll(szKey, LR.JsonEncode({}), 1)
	end
	DB_REPLACE:Execute()
end

--载入成就数据
function LR_AccountStatistics_Achievement.LoadAllUsrData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM achievement_data INNER JOIN player_info ON player_info.szKey = achievement_data.szKey WHERE achievement_data.bDel = 0 AND achievement_data.szKey IS NOT NULL")
	local Data = DB_SELECT:GetAll() or {}
	local AllUsrData = {}
	for k, v in pairs (Data) do
		local data = LR.JsonDecode(v.achievement_data)
		local data2 = {}
		for k2, v2 in pairs(data) do
			data2[tonumber(k2)] = v2
		end
		AllUsrData[v.szKey] = clone(data2)
	end
	---添加自己
	LR_AccountStatistics_Achievement.GetSelfData()
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	AllUsrData[szKey] = clone (LR_AccountStatistics_Achievement.SelfData)
	LR_AccountStatistics_Achievement.AllUsrData = clone(AllUsrData)
end

function LR_AccountStatistics_Achievement.LoadCustomFenlei()
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szName = me.szName
	local src = "%s\\Script\\AchievementSettings.dat"
	local path = sformat(src, AddonPath)
	local data = LoadLUAData(path) or {}
	for k, v in pairs(data) do
		if type(v)  ==  "table" then
			LR_AccountStatistics_Achievement.fenlei[k] = v
		end
	end
end

function LR_AccountStatistics_Achievement.NEW_ACHIEVEMENT()
	LR_AccountStatistics_Achievement.GetSelfData()
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	local szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	AllUsrData[szKey] = clone (LR_AccountStatistics_Achievement.SelfData)
	LR_AccountStatistics_Achievement.AllUsrData = clone(AllUsrData)

	LR_Acc_Achievement_Panel:ReloadItemBox()
end

function LR_AccountStatistics_Achievement.LOGIN_GAME()
	LR_AccountStatistics_Achievement.LoadCustomFenlei()
end

LR.RegisterEvent("NEW_ACHIEVEMENT", function() LR_AccountStatistics_Achievement.NEW_ACHIEVEMENT() end)
LR.RegisterEvent("LOGIN_GAME", function() LR_AccountStatistics_Achievement.LOGIN_GAME() end)
------------------------------
--界面
------------------------------
LR_Acc_Achievement_Panel  =  CreateAddon("LR_Acc_Achievement_Panel")
LR_Acc_Achievement_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_Acc_Achievement_Panel.Select = _L["MengHuiDaoXiang"]

LR_Acc_Achievement_Panel.UsrData  =  {
	Anchor  =  {s  =  "CENTER", r  =  "CENTER", x  =  0, y  =  0},
}

function LR_Acc_Achievement_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")

	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	LR_AccountStatistics_Achievement.LoadAllUsrData(DB)
	DB:Execute("END TRANSACTION")
	DB:Release()

	LR_Acc_Achievement_Panel.UpdateAnchor(this)
	RegisterGlobalEsc("LR_Acc_Achievement_Panel", function () return true end , function() LR_Acc_Achievement_Panel:Open() end)
end

function LR_Acc_Achievement_Panel:OnEvents(event)
	if event  ==  "UI_SCALED" then
		LR_Acc_Achievement_Panel.UpdateAnchor(this)
	end
end

function LR_Acc_Achievement_Panel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_Acc_Achievement_Panel.UsrData.Anchor.s, 0, 0, LR_Acc_Achievement_Panel.UsrData.Anchor.r, LR_Acc_Achievement_Panel.UsrData.Anchor.x, LR_Acc_Achievement_Panel.UsrData.Anchor.y)
end

function LR_Acc_Achievement_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_Acc_Achievement_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_Acc_Achievement_Panel:Init()
	local frame  =  self:Append("Frame", "LR_Acc_Achievement_Panel", {title  =  _L["LR_Achievement Panel"], style  =  "LARGER"})

	local imgTab  =  self:Append("Image", frame, "TabImg", {w  =  962, h  =  33, x  =  0, y  =  50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)

	----选择成就
	local hComboBoxShow  =  self:Append("ComboBox", frame, "hComboBoxShow", {w  =  250, x  =  20, y  =  51, text  =  LR_Acc_Achievement_Panel.Select or "" })
	hComboBoxShow:Enable(true)
	hComboBoxShow.OnClick  =  function(m)
		local fenlei = LR_AccountStatistics_Achievement.fenlei or {}
		for k, v in pairs (fenlei) do
			local menu = {szOption = k, bCheck = true, bMCheck = true, bChecked = function() return LR_Acc_Achievement_Panel.Select  ==  k end,
			fnAction = function()
				hComboBoxShow:SetText(k)
				LR_Acc_Achievement_Panel.Select  =  k
				self:ReloadItemBox()
			end, }

			m[#m+1] = menu
		end
		PopupMenu(m)
	end

	local refreshButton  =  self:Append("Button", frame, "refreshButton", {w  =  80, x  =  300, y  =  52, text  =  _L["Refresh"] })
	refreshButton:Enable(true)
	refreshButton.OnClick  =  function()
		self:ReloadItemBox()
	end

	local me = GetClientPlayer()
	if me then
		local handle_role = self:Append("Handle", frame, "Handle_role", {x  =  670, y  =  50, w  =  300, h  =  30})
		handle_role:SetHandleStyle(3)
		handle_role:SetMinRowHeight(30)
		local szPath, nFrame = GetForceImage(me.dwForceID)
		local image_role = self:Append("Image", handle_role, "Image_Role", { w  =  30, h  =  30 , image = szPath , frame =  nFrame })
		local Text_role = self:Append("Text", handle_role, "Text_Role", { w  =  200, h  =  30 , font = 17})
		Text_role:SetText(me.szName)
		Text_role:SetVAlign(1)
		Text_role:SetHAlign(1)
		local r, g, b = LR.GetMenPaiColor(me.dwForceID)
		Text_role:SetFontColor(r, g, b)
		handle_role:FormatAllItemPos()
		local w, h = handle_role:GetAllItemSize()
		handle_role:SetSize(w, 30)
		handle_role:SetRelPos(920-w, 50)
	end

	local hPageSet  =  self:Append("PageSet", frame, "PageSet", {x  =  20, y  =  120, w  =  935, h  =  450})
	local hWinIconView  =  self:Append("Window", hPageSet, "WindowItemView", {x  =  0, y  =  0, w  =  935, h  =  450})
	local hScroll  =  self:Append("Scroll", hWinIconView, "Scroll", {x  =  0, y  =  0, w  =  935, h  =  450})
	self:LoadItemBox(hScroll)
	hScroll:UpdateList()

	-------------初始界面物品
	local hHandle  =  self:Append("Handle", frame, "Handle", {x  =  18, y  =  90, w  =  920, h  =  450})

	local Image_Record_BG  =  self:Append("Image", hHandle, "Image_Record_BG", {x  =  0, y  =  0, w  =  920, h  =  480})
	Image_Record_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 50)
	Image_Record_BG:SetImageType(10)

	local Image_Record_BG1  =  self:Append("Image", hHandle, "Image_Record_BG1", {x  =  0, y  =  30, w  =  920, h  =  480})
	Image_Record_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74)
	Image_Record_BG1:SetImageType(10)
	Image_Record_BG1:SetAlpha(110)

	local Image_Record_Line1_0  =  self:Append("Image", hHandle, "Image_Record_Line1_0", {x  =  3, y  =  28, w  =  920, h  =  3})
	Image_Record_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 65)
	Image_Record_Line1_0:SetImageType(11)
	Image_Record_Line1_0:SetAlpha(115)


	local Text_break1  =  self:Append("Text", hHandle, "Text_break1", {w  =  150, h  =  30, x  = 0, y  =  2, text  =  _L["Name"], font  =  _font})
	Text_break1:SetHAlign(1)
	Text_break1:SetVAlign(1)

	local Image_Record_Break1  =  self:Append("Image", hHandle, "Image_Record_Break1", {x  =  150, y  =  2, w  =  3, h  =  472})
	Image_Record_Break1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
	Image_Record_Break1:SetImageType(11)
	Image_Record_Break1:SetAlpha(160)

	local tHead_Handle = self:Append("Handle", hHandle, "tHead_Handle", {x  =  150, y  =  0, w  =  770, h  =  30})
	LR_Acc_Achievement_Panel:Load_tHead()

	----------关于
	LR.AppendAbout(LR_Acc_Achievement_Panel, frame)
end

function LR_Acc_Achievement_Panel:Open()
	local frame  =  self:Fetch("LR_Acc_Achievement_Panel")
	if frame then
		self:Destroy(frame)
	else
		frame  =  self:Init()
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

function LR_Acc_Achievement_Panel:LoadItemBox(hWin)
	local TempTable_Cal, TempTable_NotCal = LR_AS_Base.SeparateUsrList()

	local m
	m = self:LoadItem(hWin, TempTable_Cal, 1)
	--self:LoadItem(hWin, TempTable_NotCal, m)
end

function LR_Acc_Achievement_Panel:LoadItem(hWin, t_table, m)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local n = 1
	for i = 1, #t_table, 1 do
		if t_table[i].nLevel >= 20 then
			local hIconViewContent  =  self:Append("Handle", hWin, sformat("IconViewContent%d", i+m), {x  =  0, y  =  0, w  =  920, h  =  30})
			local Image_Line  =  self:Append("Image", hIconViewContent, sformat("Image_Line%d", i+m), {x  =  0, y  =  0, w  =  920, h  =  30})
			Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex", 75)
			Image_Line:SetImageType(10)
			Image_Line:SetAlpha(200)

			if (m+n) % 2  ==  1 then
				Image_Line:Hide()
			end

			--悬停框
			local Image_Hover  =  self:Append("Image", hIconViewContent, sformat("Image_Hover", i+m), {x  =  2, y  =  0, w  =  910, h  =  30})
			Image_Hover:FromUITex("ui\\Image\\Common\\TempBox.UITex", 5)
			Image_Hover:SetImageType(10)
			Image_Hover:SetAlpha(200)
			Image_Hover:Hide()

			----显示内容
			local handle_content  =  self:Append("Handle", hIconViewContent, sformat("handle_content_%d_1", i+m), {x  =  0, y  =  2, w  =  150, h  =  28})
			handle_content:SetHandleStyle(3)
			handle_content:SetMinRowHeight(30)

			local szPath, nFrame  =  GetForceImage(t_table[i].dwForceID)
			local Img_Force = self:Append("Image", handle_content, sformat("Img_Force_%d", i+m), {w  =  30, h  =  30, x = 0 , })
			Img_Force:FromUITex(szPath, nFrame)
			Img_Force:Show()

			local r, g, b = LR.GetMenPaiColor(t_table[i].dwForceID)
			local szName  =  sformat("%s(%d)", t_table[i].szName, t_table[i].nLevel)
			local Text_Name = self:Append("Text", handle_content, sformat("Img_Force_%d", i+m), {w  =  24, h  =  30, x = 0 , text  =  szName , font  =  41})
			Text_Name:SetFontColor(r, g, b)

			handle_content:FormatAllItemPos()

			local realArea = t_table[i].realArea
			local realServer = t_table[i].realServer
			local szName = t_table[i].szName
			local dwID = t_table[i].dwID
			local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
			local data = LR_AccountStatistics_Achievement.AllUsrData[szKey] or {}

			local Select = LR_Acc_Achievement_Panel.Select or _L["MengHuiDaoXiang"]
			if LR_AccountStatistics_Achievement.fenlei[Select] and type(LR_AccountStatistics_Achievement.fenlei[Select]) == "table" then
				local selectData = LR_AccountStatistics_Achievement.fenlei[Select]
				for ix = 1, #selectData, 1 do
					local text_finish = self:Append("Text", hIconViewContent, sformat("Text_Finish_%d_%s", i+m, selectData[ix]), {w  =  35, h  =  30, x = 150+(ix-1)*35 , text  =  "   " , font  =  22})
					if data[selectData[ix]] then
						text_finish:SetText("√")
						text_finish:SetVAlign(1)
						text_finish:SetHAlign(1)
						text_finish:SetFontColor(34, 177, 46)
					end

					text_finish:RegisterEvent(277)
					text_finish.OnClick = function ()
						local nX, nY = text_finish:GetAbsPos()
						local nW, nH = text_finish:GetSize()
						OutputAchievementTip(selectData[ix], {nX, nY, 0, -135})
					end
					text_finish.OnEnter = function ()
						text_finish:SetFontColor(255, 128, 0)
						Image_Hover:Show()
					end
					text_finish.OnLeave = function ()
						text_finish:SetFontColor(34, 177, 46)
						Image_Hover:Hide()
					end
				end
			end

			-----------鼠标操作
			hIconViewContent.OnEnter  =  function()
				Image_Hover:Show()
			end
			hIconViewContent.OnLeave  =  function()
				Image_Hover:Hide()
			end

			handle_content.OnEnter  =  function()
				Image_Hover:Show()
			end
			handle_content.OnLeave  =  function()
				Image_Hover:Hide()
			end
			n = n+1
		end
	end
	return (m + n)
end

function  LR_Acc_Achievement_Panel:Load_tHead()
	local frame = Station.Lookup("Normal/LR_Acc_Achievement_Panel")
	if frame then
		local tHead_Handle = self:Fetch("tHead_Handle")
		if tHead_Handle then
			self:ClearHandle(tHead_Handle)
		end
		local Select = LR_Acc_Achievement_Panel.Select or _L["MengHuiDaoXiang"]
		if LR_AccountStatistics_Achievement.fenlei[Select] and type(LR_AccountStatistics_Achievement.fenlei[Select]) == "table" then
			local data = LR_AccountStatistics_Achievement.fenlei[Select]
			local Text_Ach = {}
			local Image_Ach = {}
			for i = 1, #data, 1 do
				Text_Ach[i]  =  self:Append("Text", tHead_Handle, sformat("Text_Ach_%d", i), {w  =  35, h  =  30, x  =  (i-1) * 35 , y  =  2, text  =  i , font  =  _font})
				Text_Ach[i]:SetHAlign(1)
				Text_Ach[i]:SetVAlign(1)

				Text_Ach[i]:RegisterEvent(277)
				Text_Ach[i].OnClick = function ()
					local nX, nY = Text_Ach[i]:GetAbsPos()
					local nW, nH = Text_Ach[i]:GetSize()
					OutputAchievementTip(data[i], {nX, nY, 0, -135})
				end
				Text_Ach[i].OnEnter = function ()
					Text_Ach[i]:SetFontColor(255, 128, 0)
				end
				Text_Ach[i].OnLeave = function ()
					Text_Ach[i]:SetFontColor(255, 255, 255)
				end

				if not (#data>= 22 and i  ==  #data) then
					Image_Ach[i]  =  self:Append("Image", tHead_Handle, sformat("Image_Ach_%d", i), {x  =  i * 35 , y  =  2, w  =  4, h  =  472})
					Image_Ach[i]:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
					Image_Ach[i]:SetImageType(11)
					Image_Ach[i]:SetAlpha(160)
				end
			end
		end
	end
end

function LR_Acc_Achievement_Panel:ReloadItemBox()
	local frame = Station.Lookup("Normal/LR_Acc_Achievement_Panel")
	if frame then
		LR_Acc_Achievement_Panel:Load_tHead()
		local cc = self:Fetch("Scroll")
		if cc then
			self:ClearHandle(cc)
		end
		self:LoadItemBox(cc)
		cc:UpdateList()
	end
end

