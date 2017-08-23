local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_1Base"
local SaveDataPath="Interface\\LR_Plugin\\@DATA\\LR_1Base"
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


