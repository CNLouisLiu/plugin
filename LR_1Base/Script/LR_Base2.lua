local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_1Base"
local SaveDataPath="Interface\\LR_Plugin@DATA\\LR_1Base"
local _L = LR.LoadLangPack(AddonPath)
---------------------------------------------------------------
LR = LR or {}

--------------------------------------------------------------
----------物品格子
--------------------------------------------------------------
local ItemBox = {
	parent = nil,
	handle = nil,
	item_data = {},
	UI_data = {
		width = 48,
		height = 48,
		margin_x = 2,
		margin_y = 2,
		text_nStackNum_x = 20,
		text_nStackNum_y = 20,
	},
}
ItemBox.__index = ItemBox

function ItemBox:new(item)
	local o = {}
	setmetatable(o,self)
	if type(item) == "table" then
		for k, v in pairs(item) do
			self.item_data[k] = v
		end
	end
	o.UI_data = {
		width = 48,
		height = 48,
		margin_x = 2,
		margin_y = 2,
		text_nStackNum_x = 20,
		text_nStackNum_y = 20,
	}
	return o
end

function ItemBox:Create(parent,UI_data)
	if not parent then
		return self
	end
	if not self.item_data then
		return self
	end
	self.parent = parent
	if UI_data and type(UI_data) == "table" then
		for k, v in pairs (UI_data) do
			self.UI_data[k] = v
		end
	end
	--create
	local szName = sformat("Index%d_TabType%d", self.item_data.dwIndex, self.item_data.dwTabType)
	local Handle = LR.AppendUI("Handle", parent, szName, {w = self.UI_data.width + self.UI_data.margin_x, h = self.UI_data.height + self.UI_data.margin_y,})
	self.handle = Handle

	local Icon_Item = LR.AppendUI("Image", Handle, "Icon_Item", {w = self.UI_data.width , h = self.UI_data.height ,})
	local dwTabType, dwIndex = self.item_data.dwTabType, self.item_data.dwIndex
	local iteminfo,_ntype=GetItemInfo(dwTabType, dwIndex)
	local nQuality = self.item_data.nQuality
	if self.item_data.nUiId == 0 then
		Icon_Item:FromIconID(3530)
	else
		if iteminfo then
			local nUiId = iteminfo.nUiId
			local nIconID = Table_GetItemIconID(nUiId)
			Icon_Item:FromIconID(nIconID)
			nQuality = nQuality or iteminfo.nQuality
		end
	end
	if nQuality == 5 then
		local OrangeBox =  LR.AppendUI("Animate", Handle, "OrangeBox", {w = self.UI_data.width, h = self.UI_data.height,})
		OrangeBox:SetAnimate("ui\\Image\\Common\\Box.UITex",17)
	else
		local Box_Quality = LR.AppendUI("Image", Handle, "Box_Quality", {w = self.UI_data.width, h = self.UI_data.height,})
		if nQuality == 4 then
			Box_Quality:FromUITex("ui\\Image\\Common\\Box.UITex",42)
		elseif nQuality == 3 then
			Box_Quality:FromUITex("ui\\Image\\Common\\Box.UITex",43)
		elseif nQuality == 2 then
			Box_Quality:FromUITex("ui\\Image\\Common\\Box.UITex",13)
		else
			Box_Quality:FromUITex("ui\\Image\\Common\\Box.UITex",0)
		end
	end

	local Task_Icon = LR.AppendUI("Image", Handle, "Task_Icon", {w = self.UI_data.width, h = self.UI_data.height,})
	Task_Icon:FromUITex("ui\\Image\\Common\\Box.UITex",41)
	if self.item_data.nGenre and self.item_data.nGenre ==  ITEM_GENRE.TASK_ITEM then
		Task_Icon:Show()
	else
		Task_Icon:Hide()
	end

	local Text_nStackNum = LR.AppendUI("Text", Handle, "Text_nStackNum", {y = self.UI_data.text_nStackNum_y, w = self.UI_data.width - 4, text = ""})
	Text_nStackNum:SetFontScheme(15)
	Text_nStackNum:SetHAlign(2)
	if self.item_data.nUiId == 0 then
		Text_nStackNum:SetText("")
	else
		if self.item_data.nStackNum and self.item_data.nStackNum >1 then
			Text_nStackNum:SetText(self.item_data.nStackNum)
		end
	end

	local Bg_Hover = LR.AppendUI("Image", Handle, "Bg_Hover", {w = self.UI_data.width, h = self.UI_data.height,})
	Bg_Hover:FromUITex("ui\\Image\\Common\\Box.UITex",10)
	Bg_Hover:Hide()
	self.Bg_Hover = Bg_Hover

	Handle:GetHandle():RegisterEvent(4194303)
	Handle:GetHandle().OnItemLButtonClick = function()	--等效于 Handle:OnClick()

	end
	Handle.OnEnter = function()	--等效于Handle:GetHandle().OnItemMouseEnter()
		if iteminfo then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			if  iteminfo.nGenre and iteminfo.nGenre == ITEM_GENRE.BOOK then
				if item.nBookID then
					local dwBookID, dwSegmentID = GlobelRecipeID2BookID(item.nBookID)
					OutputBookTipByID(dwBookID, dwSegmentID, {x, y, w, h,})
				end
			else
				OutputItemTip(UI_OBJECT_ITEM_INFO, 1, dwTabType, dwIndex, {x, y, w, h,})
			end
		end
		Bg_Hover:Show()
	end
	Handle.OnLeave = function()
		HideTip()
		Bg_Hover:Hide()
	end
	return self
end

function ItemBox:Hover(flag)
	if flag then
		self.Bg_Hover:Show()
	else
		self.Bg_Hover:Hide()
	end
	return self
end

function ItemBox:SetRelPos(...)
	self.handle:SetRelPos(...)
	return self
end

function ItemBox:OnItemLButtonClick(fnAction)
	if fnAction and type(fnAction) == "function" then
		self.handle:GetHandle().OnItemLButtonClick = fnAction
	end
	return self
end

function ItemBox:OnItemRButtonClick(fnAction)
	if fnAction and type(fnAction) == "function" then
		self.handle:GetHandle().OnItemRButtonClick = fnAction
	end
	return self
end

function ItemBox:OnItemMouseEnter(fnAction)
	if fnAction and type(fnAction) == "function" then
		self.handle:GetHandle().OnItemMouseEnter = fnAction
	end
	return self
end

function ItemBox:OnItemMouseLeave(fnAction)
	if fnAction and type(fnAction) == "function" then
		self.handle:GetHandle().OnItemMouseLeave = fnAction
	end
	return self
end
LR.ItemBox = ItemBox

--------------------------------------------------------------
----------Buff格子
--------------------------------------------------------------
local BuffBox = {
	parent = nil,
	handle = nil,
	buff_data = {},
	UI_data = {
		width = 78,
		height = 98,
		icon_size = 70,
		margin_x = 2,
		margin_y = 2,
		text_nStackNum_x = 0,
		text_nStackNum_y = 45,
		text_nStackNum_w = 68,
		text_szName_x = 0,
		text_szName_y = 72,
		text_level_x = 15,
		text_level_y = 5,
		text_level_w = 68,

	},
}
BuffBox.__index = BuffBox

function BuffBox:new(buff)
	local o = {}
	setmetatable(o,self)
	if type(buff) == "table" then
		for k, v in pairs(buff) do
			self.buff_data[k] = v
		end
	end
	return o
end

function BuffBox:Create(parent, UI_data)
	if not parent then
		return self
	end
	if not self.buff_data then
		return self
	end
	self.parent = parent
	if UI_data and type(UI_data) == "table" then
		for k, v in pairs (UI_data) do
			self.UI_data[k] = v
		end
	end
	---create
	local szName = sformat("id_%d", self.buff_data.dwID)
	local Handle = LR.AppendUI("Handle", parent, szName, {w = self.UI_data.width + self.UI_data.margin_x, h = self.UI_data.height + self.UI_data.margin_y,})
	self.handle = Handle

	local Image_Bg = LR.AppendUI("Image", Handle, "Icon_Buff", {w = self.UI_data.width , h = self.UI_data.height,})
	Image_Bg:FromUITex("ui\\Image\\Common\\CommonPanel.UITex",63)
	Image_Bg:SetAlpha(100)

	local Icon_Buff = LR.AppendUI("Image", Handle, "Icon_Buff", {x = (self.UI_data.width - self.UI_data.icon_size) / 2, y = 4, w = self.UI_data.icon_size , h = self.UI_data.icon_size,})
	local dwID, nLevel = self.buff_data.dwID, self.buff_data.nLevel
	local nStackNum = self.buff_data.nStackNum
	local nEndFrame = self.buff_data.nEndFrame
	local nIconID = Table_GetBuffIconID(dwID, nLevel)
	if nIconID ~= -1 then
		Icon_Buff:FromIconID(nIconID)
	else
		if LR_BuffCapture and LR_BuffCapture.buffCustomDesc[self.buff_data.dwID] then
			Icon_Buff:FromIconID(4720)
		else
			Icon_Buff:FromIconID(1434)
		end
	end

	local Text_Level = LR.AppendUI("Text", Handle, "Text_Level", {x = self.UI_data.text_level_x, y = self.UI_data.text_level_y, w = self.UI_data.text_level_w, text = ""})
	Text_Level:SetFontScheme(15)
	Text_Level:SetHAlign(0)
	if nLevel > 1 then
		Text_Level:SprintfText("Lv.%d", nLevel)
	end

	local Text_StackNum = LR.AppendUI("Text", Handle, "Text_StackNum", {y = self.UI_data.text_nStackNum_y + 2, w = self.UI_data.text_nStackNum_w, text = ""})
	Text_StackNum:SetFontScheme(15)
	Text_StackNum:SetHAlign(2)
	if nStackNum > 1 then
		Text_StackNum:SprintfText("%d", nStackNum)
	end

	local Text_LeftTime = LR.AppendUI("Text", Handle, "Text_LestTime", {y = self.UI_data.text_nStackNum_y + 2, w = self.UI_data.text_nStackNum_w, text = ""})
	Text_LeftTime:SetFontScheme(15)
	Text_LeftTime:SetHAlign(0)
	local nowFrame = GetLogicFrameCount()
	if nEndFrame < nowFrame then
		Text_LeftTime:SetText("已过期")
	else
		local nLeftFrame = mfloor((nEndFrame - nowFrame) / 16)
		if mfloor(nLeftFrame / 16) < 60 then
			Text_LeftTime:SprintfText("%ds", mfloor(nLeftFrame))
		elseif mfloor(nLeftFrame / 16) < 60 * 60 then
			Text_LeftTime:SprintfText("%dm%ds", mfloor(nLeftFrame / 60), mfloor(nLeftFrame % 60))
		end
	end

	if nStackNum > 1 then
		Text_LeftTime:SprintfText("%d", nStackNum)
	end

	local Text_Name = LR.AppendUI("Text", Handle, "Text_Name", {y = self.UI_data.text_szName_y, w = self.UI_data.width, text = "xxxx"})
	Text_Name:SetFontScheme(15)
	Text_Name:SetHAlign(1)
	local szName = wssub(Table_GetBuffName(dwID, nLevel), 1, 5 )
	if szName == "" then
		if LR_BuffCapture and LR_BuffCapture.buffCustomDesc and LR_BuffCapture.buffCustomDesc[dwID] and LR_BuffCapture.buffCustomDesc[dwID].desc and LR_BuffCapture.buffCustomDesc[dwID].desc ~="" then
			Text_Name:SprintfText("%s", wssub(LR_BuffCapture.buffCustomDesc[dwID].desc, 1, 5 ))
		else
			Text_Name:SprintfText("#%d", dwID)
		end
	else
		Text_Name:SprintfText("%s", szName)
	end

	local Bg_Hover = LR.AppendUI("Image", Handle, "Bg_Hover", {w = self.UI_data.width, h = self.UI_data.height,})
	Bg_Hover:FromUITex("ui\\Image\\Common\\Box.UITex",10)
	Bg_Hover:Hide()
	self.Bg_Hover = Bg_Hover

	Handle:GetHandle():RegisterEvent(4194303)
	Handle:GetHandle().OnItemLButtonClick = function()	--等效于 Handle:OnClick()

	end

	Handle.OnEnter = function()
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		if Table_GetBuffDesc(dwID, nLevel) ~= "" then
			OutputBuffTip(nil, dwID, nLevel, nil, nil, nil, {x, y, w, h})
		end
		Bg_Hover:Show()
	end
	Handle.OnLeave = function()
		HideTip()
		Bg_Hover:Hide()
	end

	return self
end

function BuffBox:OnItemLButtonClick(fnAction)
	if fnAction and type(fnAction) == "function" then
		self.handle:GetHandle().OnItemLButtonClick = fnAction
	end
	return self
end

function BuffBox:OnItemRButtonClick(fnAction)
	if fnAction and type(fnAction) == "function" then
		self.handle:GetHandle().OnItemRButtonClick = fnAction
	end
	return self
end

function BuffBox:OnItemMouseEnter(fnAction)
	if fnAction and type(fnAction) == "function" then
		self.handle:GetHandle().OnItemMouseEnter = fnAction
	end
	return self
end

function BuffBox:OnItemMouseLeave(fnAction)
	if fnAction and type(fnAction) == "function" then
		self.handle:GetHandle().OnItemMouseLeave = fnAction
	end
	return self
end
LR.BuffBox = BuffBox

--------------------------------------------------------------
----------数据库
--------------------------------------------------------------
local schema_table_info = {
	name = "table_info",
	version = "20170622",
	data = {
		{name = "table_name", sql = "table_name VARCHAR(60) PRIMARY KEY"},
		{name = "version", sql = "version VARCHAR(20)"}
	},
}

local SQLITE3 = {}
function SQLITE3.UpdateTable(DB, table_config)
	---创建表格
	local sql = "CREATE TABLE IF NOT EXISTS %s ( %s )"
	local table_name = table_config.name
	local version = table_config.version
	local sq = {}
	for k, v in pairs(table_config.data) do
		sq[#sq + 1] = v.sql
	end
	if table_config.primary_key then
		sq[#sq + 1] = table_config.primary_key.sql
	end
	sql = sformat(sql, table_name, tconcat(sq, ", "))
	DB:Execute(sql)

	----添加列
	local sql2 = sformat("SELECT * FROM table_info WHERE table_name = '%s' AND version = '%s'", table_name, version)
	local result = DB:Execute(sql2) or {}
	if not result or next(result) == nil then
		local column = {}
		for k, v in pairs (table_config.data) do
			local sql3 = sformat("SELECT * FROM sqlite_master WHERE type = 'table' AND name ='%s' AND sql like '%% %s %%'", table_name, v.name)
			local result2 = DB:Execute(sql3)
			if result2 and next(result2) ~= nil then
				column[#column+1] = v.name
			end
		end
		DB:Execute(sformat("ALTER TABLE %s RENAME TO _%s_temp", table_name, table_name))
		DB:Execute(sql)
		DB:Execute(sformat("REPLACE INTO %s ( %s ) SELECT %s FROM _%s_temp", table_name, tconcat(column, ", "), tconcat(column, ", "), table_name))
		DB:Execute(sformat("REPLACE INTO table_info ( table_name, version ) VALUES ( '%s', '%s' )", table_name, version))
		DB:Execute(sformat("DROP TABLE _%s_temp", table_name))
	end
end

function SQLITE3.IniDB(db_path, db_name, tTable_Config)
	CPath.MakeDir(db_path)
	----
	local path = sformat("%s\\%s", db_path, db_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	SQLITE3.UpdateTable(DB, schema_table_info)
	for k, v in pairs (tTable_Config) do
		SQLITE3.UpdateTable(DB, v)
	end
	DB:Execute("END TRANSACTION")
	DB:Release()
end

LR.IniDB = SQLITE3.IniDB

----------------------------------------------------------------
----调色板
----------------------------------------------------------------
function LR.hsv2rgb(h, s, v)
	s = s / 100
	v = v / 100
	local r, g, b = 0, 0, 0
	local h = h / 60
	local i = mfloor(h)
	local f = h - i
	local p = v * (1 - s)
	local q = v * (1 - s * f)
	local t = v * (1 - s * (1 - f))
	if i == 0 or i == 6 then
		r, g, b = v, t, p
	elseif i == 1 then
		r, g, b = q, v, p
	elseif i == 2 then
		r, g, b = p, v, t
	elseif i == 3 then
		r, g, b = p, q, v
	elseif i == 4 then
		r, g, b = t, p, v
	elseif i == 5 then
		r, g, b = v, p, q
	end
	return mfloor(r * 255), mfloor(g * 255), mfloor(b * 255)
end

function LR.rgb2hsv(r, g, b)
	local r=r/255
	local g=g/255
	local b=b/255
	local MAX,MIN
	if r>g then
		MAX=mmax(r,b)
		MIN=mmin(g,b)
	else
		MAX=mmax(g,b)
		MIN=mmin(r,b)
	end
	local v=MAX
	local delta=MAX-MIN

	if MAX == 0 then
		s=0
	else
		s=delta / MAX
	end

	if MAX==MIN then
		h=0
	else
		if r == MAX and g >= b then
			h = 60 * ( g - b ) / delta + 0
		elseif r == MAX and g < b then
			h = 60 * ( g - b ) / delta + 360
		elseif g == MAX then
			h = 60 * ( b - r ) / delta + 120
		elseif b == MAX then
			h = 60 * ( r - g ) / delta + 240
		end
	end

	h = mfloor( h + 0.5 )
	if h > 359 then
		h = h - 360
	elseif h < 0 then
		h = h +360
	end

	return h, mfloor(s*100 + 0.5), mfloor(v*100 + 0.5)
end

ColorPanel = CreateAddon("ColorPanel")
ColorPanel:BindEvent("OnFrameDragEnd", "OnDragEnd")
ColorPanel:BindEvent("OnFrameDestroy", "OnDestroy")

ColorPanel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0},
}
ColorPanel.AutoClose = false

function ColorPanel:OnCreate()
	this:RegisterEvent("UI_SCALED")

	local fx, fy=Cursor.GetPos()
	ColorPanel.UpdateAnchor(this)
	--this:SetPoint(fx+10,fy+10)
end

function ColorPanel:OnEvents(event)
	if event == "UI_SCALED" then
		ColorPanel.UpdateAnchor(this)
	end
end

function ColorPanel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(ColorPanel.UsrData.Anchor.s, 0, 0, ColorPanel.UsrData.Anchor.r, ColorPanel.UsrData.Anchor.x, ColorPanel.UsrData.Anchor.y)
end

function ColorPanel:OnDestroy()
	PlaySound(SOUND.UI_SOUND,g_sound.CloseFrame)
end

function ColorPanel:OnDragEnd()
	this:CorrectPos()
	ColorPanel.UsrData.Anchor = GetFrameAnchor(this)
end

local COLOR_HUE = 0
local COLOR_S = 0
local COLOR_V = 0
local tUI = {}

function ColorPanel:Init(fnAction,rgb)
	local o_r,o_g,o_b
	if rgb then
		o_r,o_g,o_b=unpack(rgb)
	else
		o_r,o_g,o_b=255,255,255
	end
	local o_h,o_s,o_v = LR.rgb2hsv(o_r,o_g,o_b)
	COLOR_HUE,COLOR_S,COLOR_V=o_h,o_s,o_v
	local frame = self:Append("Frame", "ColorPanel", {title = _L["LR Color Table"] , style = "SMALL" , disableEffect = true , })
	local AutoClose = LR.AppendUI("CheckBox", frame, "AutoClose", {x = 14, y = 14, text = _L["Auto close"]})
	AutoClose:Check(ColorPanel.AutoClose)
	AutoClose.OnCheck = function(arg0)
		ColorPanel.AutoClose = arg0
	end

	local hPageSet = self:Append("PageSet", frame, "PageSet", {x = 20, y = 40, w = 360, h = 500})
	local hWinIconView = self:Append("Window", hPageSet, "WindowItemView", {x = 0, y = 0, w = 360, h = 500})

	local hShadow = self:Append("Shadow", hWinIconView, "Select", { w = 25, h = 25, x = 20, y = 10 })
	hShadow:SetColorRGB(o_r,o_g,o_b)
	local tText_R = self:Append("Text", hWinIconView, "TEXT_R", { x = 50, y = 8, text = "R" })
	local eEdit_R = self:Append("Edit", hWinIconView, "EDIT_R", { x = 65, y = 10, w = 30, h = 25, limit = 3 })
	local tText_G = self:Append("Text", hWinIconView, "TEXT_G", { x = 115, y = 8, text = "G" })
	local eEdit_G = self:Append("Edit", hWinIconView, "EDIT_G", { x = 130, y = 10, w = 30, h = 25, limit = 3 })
	local tText_B = self:Append("Text", hWinIconView, "TEXT_B", { x = 180, y = 8, text = "B" })
	local eEdit_B = self:Append("Edit", hWinIconView, "EDIT_B", { x = 195, y = 10, w = 30, h = 25, limit = 3 })
	eEdit_R:SetText(o_r)
	eEdit_G:SetText(o_g)
	eEdit_B:SetText(o_b)

	local editchange=function()
		local r=tonumber(eEdit_R:GetText())
		local g=tonumber(eEdit_G:GetText())
		local b=tonumber(eEdit_B:GetText())

		if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
			return
		end

		if r > 255 then
			r=255
			eEdit_R:SetText(r)
		elseif r<0 then
			r=0
			eEdit_R:SetText(r)
		end

		if g > 255 then
			g=255
			eEdit_G:SetText(g)
		elseif g<0 then
			g=0
			eEdit_G:SetText(g)
		end

		if b > 255 then
			b=255
			eEdit_B:SetText(b)
		elseif b<0 then
			b=0
			eEdit_B:SetText(b)
		end

		local h,s,v=LR.rgb2hsv(r,g,b)
--[[		hCSlider_H:UpdateScrollPos(h)
		hCSlider_S:UpdateScrollPos(s)
		hCSlider_V:UpdateScrollPos(v)]]
		hShadow:SetColorRGB(r,g,b)
	end

	eEdit_R.OnChange = editchange
	eEdit_G.OnChange = editchange
	eEdit_B.OnChange = editchange


	local hButton_OK = self:Append("Button", hWinIconView, "BUTTON_OK", {w = 80, x = 250, y = 10, text = _L["OK"]})
	hButton_OK.OnClick = function()
		local r=eEdit_R:GetText() or 0
		local g=eEdit_G:GetText() or 0
		local b=eEdit_B:GetText() or 0
		if fnAction then
			fnAction(r,g,b)
		end
		if ColorPanel.AutoClose then
			self:Open()
		end
	end

	local hCSlider_H = self:Append("CSlider", hWinIconView, "CSlider_H", {w = 270, x = 16, y = 34, text = "", min = 0, max = 360, step = 360, value = 0, unit = "H"})
	local hCSlider_S = self:Append("CSlider", hWinIconView, "CSlider_S", {w = 270, x = 16, y = 390, text = "", min = 0, max = 100, step = 100, value = 0, unit = "%S"})
	local hCSlider_V = self:Append("CSlider", hWinIconView, "CSlider_V", {w = 270, x = 16, y = 410, text = "", min = 0, max = 100, step = 100, value = 0, unit = "%V"})
	hCSlider_H:UpdateScrollPos(o_h)
	hCSlider_S:UpdateScrollPos(o_s)
	hCSlider_V:UpdateScrollPos(o_v)
	for i = 0, 360, 2 do
		local Shadow=self:Append("Shadow", hWinIconView, sformat("Shadow_%d", i), { x = 20 + (0.74 * i), y = 60, h = 10, w = 2,  })
		Shadow:SetColorRGB(LR.hsv2rgb(i,100,100))
	end

	local handle = self:Append("Handle", hWinIconView, "Handle_color" ,{ w = 300, h = 300, x = 20, y = 80 })
	local function SetColor(bInit)
		local handle=self:Fetch("Handle_color")
		for v = 100, 0, -2 do
			tUI[v] = tUI[v] or {}
			for s = 0, 100, 2 do
				local x = s * 3
				local y = (100 - v) * 3
				local r, g, b = LR.hsv2rgb(COLOR_HUE, s, v)
				if not bInit then
					tUI[v][s]:SetColorRGB(r, g, b)
				else
					handle:AppendItemFromString("<shadow> w=6 h=6 EventID=272 </shadow>")
					local sha = self:Fetch("Handle_color"):Lookup(handle:GetItemCount() - 1)
					sha:SetRelPos(x, y)
					sha:SetColorRGB(r, g, b)
					tUI[v][s] = sha
					sha.v=v
					sha.s=s
					sha.OnItemMouseEnter = function()
						if IsCtrlKeyDown() then
							return
						end
						local r,g,b=LR.hsv2rgb(COLOR_HUE, s, v)
						eEdit_R:SetText(r)
						eEdit_G:SetText(g)
						eEdit_B:SetText(b)

						COLOR_S=s
						COLOR_V=v

						hCSlider_H:UpdateScrollPos(COLOR_HUE)
						hCSlider_S:UpdateScrollPos(s)
						hCSlider_V:UpdateScrollPos(v)
						hShadow:SetColorRGB(r,g,b)
					end
					sha.OnItemLButtonClick = function()
						local r=eEdit_R:GetText() or 0
						local g=eEdit_G:GetText() or 0
						local b=eEdit_B:GetText() or 0
						if fnAction then
							fnAction(r,g,b)
						end
						if ColorPanel.AutoClose then
							self:Open()
						end
					end
				end
			end
		end
		if bInit then
			handle:FormatAllItemPos()
		end
	end

	SetColor(true)

	hCSlider_H.OnChange = function(value)
		COLOR_HUE=value
		SetColor()
	end
	hCSlider_S.OnChange = function(value)
		COLOR_S=value
		local h,s,v=COLOR_HUE,COLOR_S,COLOR_V
		local r,g,b=LR.hsv2rgb(h,s,v)
		eEdit_R:SetText(r)
		eEdit_G:SetText(g)
		eEdit_B:SetText(b)
		hShadow:SetColorRGB(r,g,b)
	end
	hCSlider_V.OnChange = function(value)
		COLOR_V=value
		local h,s,v=COLOR_HUE,COLOR_S,COLOR_V
		local r,g,b=LR.hsv2rgb(h,s,v)
		eEdit_R:SetText(r)
		eEdit_G:SetText(g)
		eEdit_B:SetText(b)
		hShadow:SetColorRGB(r,g,b)
	end

	local hButton_Restore = self:Append("Button", hWinIconView, "BUTTON_RESTORE", {w = 80, x = 20, y = 436, text = _L["Restore"]})
	hButton_Restore.OnClick = function()
		eEdit_R:SetText(o_r)
		eEdit_G:SetText(o_g)
		eEdit_B:SetText(o_b)

		hCSlider_H:UpdateScrollPos(o_h)
		hCSlider_S:UpdateScrollPos(o_s)
		hCSlider_V:UpdateScrollPos(o_v)

		COLOR_HUE=o_h
		COLOR_S=o_s
		COLOR_V=o_v

		hShadow:SetColorRGB(o_r,o_g,o_b)
	end

	local hButton_TIP = self:Append("Button", frame, "BUTTON_RESTORE", {w = 50, x = 285, y = 14, text = _L["TIP"]})
	hButton_TIP.OnEnter = function()
		local x, y=this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml=_L["LR Color Tip"]
		szXml = GetFormatText(szXml,136,255,128,0)
		OutputTip(szXml,350,{x,y,w,h})
	end
	hButton_TIP.OnLeave = function()
		HideTip()
	end

	----------关于
	LR.AppendAbout(ColorPanel,frame)
end

function ColorPanel:Open(fnAction,rgb)
	local frame = self:Fetch("ColorPanel")
	if frame then
		self:Destroy(frame)
	else
		frame = self:Init(fnAction,rgb)
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
end

function LR.OpenColorTablePanel(fnAction,rgb)
	ColorPanel:Open(fnAction,rgb)
end


------字体面板
_FontPanel = CreateAddon("_FontPanel")
_FontPanel:BindEvent("OnFrameDragEnd", "OnDragEnd")
_FontPanel:BindEvent("OnFrameDestroy", "OnDestroy")

_FontPanel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0},
}
_FontPanel.AutoClose = false
_FontPanel.selected = 0
_FontPanel.hSelected = {}

function _FontPanel:OnCreate()
	this:RegisterEvent("UI_SCALED")

	_FontPanel.UpdateAnchor(this)
end

function _FontPanel:OnEvents(event)
	if event == "UI_SCALED" then
		_FontPanel.UpdateAnchor(this)
	end
end

function _FontPanel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(_FontPanel.UsrData.Anchor.s, 0, 0, _FontPanel.UsrData.Anchor.r, _FontPanel.UsrData.Anchor.x, _FontPanel.UsrData.Anchor.y)
end

function _FontPanel:OnDestroy()
	PlaySound(SOUND.UI_SOUND,g_sound.CloseFrame)
end

function _FontPanel:OnDragEnd()
	this:CorrectPos()
	ColorPanel.UsrData.Anchor = GetFrameAnchor(this)
end

local _FontSheild = {
	[9] = true,
	[11] = true,
	[12] = true,
	[13] = true,
	[14] = true,
	[26] = true,
	[29] = true,
	[42] = true,
	[80] = true,
	[82] = true,
	[83] = true,
	[180] = true,
	[182] = true,
	[183] = true,
	[211] = true,
}

function _FontPanel:Init(fnAction,rgb)
	local frame = self:Append("Frame", "_FontPanel", {title = _L["LR Font Table"] , style = "SMALL" , disableEffect = true , })
	local AutoClose = LR.AppendUI("CheckBox", frame, "AutoClose", {x = 14, y = 14, text = _L["Auto close"]})
	AutoClose:Check(_FontPanel.AutoClose)
	AutoClose.OnCheck = function(arg0)
		_FontPanel.AutoClose = arg0
	end

	local hPageSet = self:Append("PageSet", frame, "PageSet", {x = 20, y = 50, w = 340, h = 420})

	local hScroll = LR.AppendUI("Scroll", hPageSet, "Scroll", {x = 0, y = 0, w = 340, h = 420})

	_FontPanel.hSelected = {}
	for i = 1, 241, 1 do
		if not _FontSheild[i] then
			local handle = LR.AppendUI("Handle", hScroll, sformat("Handle_%d", i), {w = 85, h = 40})
			local hover = LR.AppendUI("Image", handle, sformat("Hover_%d", i), {w = 85, h = 40})
			hover:FromUITex("ui/image/common/box.uitex", 1)
			hover:Hide()
			hover:SetImageType(10)

			local selected = LR.AppendUI("Image", handle, sformat("Selected_%d", i), {w = 85, h = 40})
			selected:FromUITex("ui/image/common/box.uitex", 10)
			selected:Hide()
			if i == _FontPanel.selected then
				selected:Show()
			end
			_FontPanel.hSelected[i] = selected


			local text = LR.AppendUI("Text", handle, sformat("Text_%d", i), {w = 85, h = 40, text = sformat(_L["Font%d"], i)})
			text:SetHAlign(1)
			text:SetVAlign(1)
			text:SetFontScheme(i)
			--text:SetFontColor(255, 255, 255)

			handle.OnClick = function()
				if _FontPanel.hSelected[_FontPanel.selected] then
					_FontPanel.hSelected[_FontPanel.selected]:Hide()
				end
				_FontPanel.hSelected[i]:Show()
				_FontPanel.selected = i

				if fnAction then
					fnAction(i)
				end
				if _FontPanel.AutoClose then
					_FontPanel:Open()
				end
			end
			handle.OnEnter = function()
				hover:Show()
			end
			handle.OnLeave = function()
				hover:Hide()
			end
		end
	end

	hScroll:UpdateList()

	----------关于
	LR.AppendAbout(ColorPanel,frame)
end

function _FontPanel:Open(fnAction, font)
	local frame = self:Fetch("_FontPanel")
	if frame then
		self:Destroy(frame)
	else
		_FontPanel.selected = font or 0
		frame = self:Init(fnAction, font)
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
end

function LR.OpenFontPanel(fnAction, font)
	_FontPanel:Open(fnAction, font)
end



