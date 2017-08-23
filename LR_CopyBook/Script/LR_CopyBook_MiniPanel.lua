local AddonPath="Interface\\LR_Plugin\\LR_CopyBook"
local _L = LR.LoadLangPack(AddonPath)
local sformat, slen, sgsub, ssub,sfind = string.format, string.len, string.gsub, string.sub, string.find
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil = math.floor, math.ceil
local tconcat, tinsert, tremove, tsort = table.concat, table.insert, table.remove, table.sort
-------------------------------------------------------------




-------------------------------------------------------------
-- 创建插件
LR_CopyBook_MiniPanel = CreateAddon("LR_CopyBook_MiniPanel")
LR_CopyBook_MiniPanel.UserData = {
	Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0},
}

local CustomVersion = "20170111v1"
RegisterCustomData("LR_CopyBook_MiniPanel.UserData", CustomVersion)

LR_CopyBook_MiniPanel:BindEvent("OnFrameDragEnd", "OnDragEnd")
LR_CopyBook_MiniPanel:BindEvent("OnFrameDestroy", "OnDestroy")
LR_CopyBook_MiniPanel:BindEvent("OnFrameKeyDown", "OnKeyDown")

-- 窗体创建回调
function LR_CopyBook_MiniPanel:OnCreate()
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("CUSTOM_DATA_LOADED")

	LR_CopyBook_MiniPanel.UpdateAnchor(this)
end

-- 事件回调
--/script ReloadUIAddon()
function LR_CopyBook_MiniPanel:OnEvents(event)
	if event == "CUSTOM_DATA_LOADED" then
		if arg0 == "Role" then
			LR_CopyBook_MiniPanel.UpdateAnchor(this)
		end
	elseif event == "UI_SCALED" then
		LR_CopyBook_MiniPanel.UpdateAnchor(this)
	end
end

function LR_CopyBook_MiniPanel.UpdateAnchor(frame)
	frame:SetPoint(LR_CopyBook_MiniPanel.UserData.Anchor.s, 0, 0, LR_CopyBook_MiniPanel.UserData.Anchor.r, LR_CopyBook_MiniPanel.UserData.Anchor.x, LR_CopyBook_MiniPanel.UserData.Anchor.y)
	frame:CorrectPos()
end
-- 窗体刷新回调
--~ LR_CopyBook_MiniPanel.OnUpdate = function()
--~ 	Output("OnUpdate")
--~ end

-- 窗体销毁回调
function LR_CopyBook_MiniPanel:OnDestroy()

end

-- 窗体拖动回调
function LR_CopyBook_MiniPanel:OnDragEnd()
	this:CorrectPos()
	LR_CopyBook_MiniPanel.UserData.Anchor = GetFrameAnchor(this)
end

-- 窗体按键响应回调
--~ LR_CopyBook_MiniPanel.OnKeyDown = function()
--~ 	Output("OnKeyDown")
--~ end


function LR_CopyBook_MiniPanel:Init()
	--local frame = self:Append("Frame", "LR_CopyBook_MiniPanel", {title = _L["Mini Printing Machine"] , path = "interface\\LR_Plugin\\LR_CopyBook\\UI\\MiniUI.ini"})
	local frame = self:Append("Frame", "LR_CopyBook_MiniPanel", {path = "interface\\LR_Plugin\\LR_CopyBook\\UI\\MiniUI2.ini"})
	frame:Lookup("","Image_MainBg"):SetAlpha(220)

	local Btn_Option = CreateUIButton(frame, "Btn_Option", {w = 34, h = 34, x = 5, y = 8, ani = {"ui\\Image\\Button\\SystemButton_1.UITex", 1, 2, 3}})
	Btn_Option:SetAlpha(220)
	Btn_Option.OnClick = function()
		LR_TOOLS:OpenPanel(_L["LR Printing Machine"])
	end

	local Handle_BookID = self:Append("Handle", frame, "Handle_BookID", {w = 280, h = 40, x = 20, y = 40})
	local imgTab = self:Append("Image", Handle_BookID,"TabImg",{w = 280, h = 40, x = 0, y = 0})
    imgTab:SetImage("ui\\Image\\UICommon\\guildmainpanel2.UITex",16)
	imgTab:SetImageType(11)
	local Text_SuitBook = self:Append("Text", Handle_BookID,"Text_SuitBook",{w = 280, h = 40, x = 55, y = 2, text = "套书：十三棍僧救唐王"})
	Text_SuitBook:SetFontScheme(7)
	self:SetBookID()
	Handle_BookID.OnEnter = function()
		imgTab:SetImage("ui\\Image\\UICommon\\guildmainpanel2.UITex",17)
	end
	Handle_BookID.OnLeave = function()
		imgTab:SetImage("ui\\Image\\UICommon\\guildmainpanel2.UITex",16)
	end

	---Need
	WndWindow_Need = self:Append("Window", frame,"WndWindow_Need",{w = 290, h = 30, x = 20, y = 85, })
	local Handle_Need = self:Append("Handle", WndWindow_Need,"Handle_Need",{w = 290, h = 30, x = 0, y = 0})
	Handle_Need:SetHandleStyle(3)

	---Begin/Stop button
	local Wnd_CopyBTN =	self:Append("Window", frame, "Wnd_CopyBTN", {w = 240, h = 40, x = 0, y = 0, })
	--创建一个按钮
	local button1 = self:Append("Button", Wnd_CopyBTN, "button1",{text = _L["Begin Printing"] ,x = 0,y = 0,w = 95,h = 36})
	--绑定按钮点击事件
	button1.OnClick = function()
		if  LR_CopyBook.on then
			return
		end
		LR_CopyBook.on=true
		Wnd.OpenWindow("interface\\LR_Plugin\\LR_CopyBook\\UI\\EmptyUI.ini","LR_CopyBook")
		LR_CopyBook.RemainNum=LR_CopyBook.UsrData.CopyLimitNum
		if LR_CopyBook.OTAFlag==0 then
			LR_CopyBook.LastTime=GetLogicFrameCount()-4
		end
	end
	local button2 = self:Append("Button", Wnd_CopyBTN,"button2",{text = _L["Stop Printing!"],x = 110,y = 0,w = 95,h = 36})
	button2.OnClick = function()
		LR_CopyBook.StopCopy()
	end

	self:LoadSuitBooks()
	local WndWindow_Books = self:Fetch("WndWindow_Books")
	WndWindow_Books:Hide()
	Handle_BookID.OnClick = function()
		local WndWindow_Books = self:Fetch("WndWindow_Books")
		WndWindow_Books:ToggleVisible()
		self:Resize()
	end

	self:Resize()
end

-- 界面创建
function LR_CopyBook_MiniPanel:Open()
	local frame = self:Fetch("LR_CopyBook_MiniPanel")
	if frame then
		self:Destroy(frame)
	else
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
end

function LR_CopyBook_MiniPanel:LoadSuitBooks()
	local frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
	if not frame then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end

	local WndWindow_Books = self:Fetch("WndWindow_Books")
	if WndWindow_Books then
		self:Destroy(WndWindow_Books)
	end

	WndWindow_Books = self:Append("Window", frame,"WndWindow_Books",{w = 290, h = 90, x = 20, y = 85, })
	local Handle_Books = self:Append("Handle", WndWindow_Books,"Handle_Books",{w = 250, h = 30, x = 40, y = 0})
	Handle_Books:SetHandleStyle(3)

	local bookList = LR_CopyBook.UsrData.bookList or {}
	for k, v in pairs(bookList) do
		local dwIndex = LR.Table_GetBookItemIndex(v.dwBookID, v.dwSegmentID)
		local iteminfo = GetItemInfo(5, dwIndex)

		local Handle_Book = self:Append("Handle", Handle_Books, sformat("Handle_Book_%d_%d", v.dwBookID, v.dwSegmentID), {w = 240, h = 40, x = 0, y = 0})
		local Image_Bg = self:Append("Image", Handle_Book, sformat("Image_Bg_%d_%d", v.dwBookID, v.dwSegmentID),{w = 230, h = 40, x = 0, y = 0})
		Image_Bg:SetImage("ui\\Image\\UICommon\\battlefiled.UITex",1)
		Image_Bg:SetAlpha(160)

		local Image_Hover = self:Append("Image", Handle_Book, sformat("Image_Hover_%d_%d", v.dwBookID, v.dwSegmentID),{w = 230, h = 40, x = 0, y = 0})
		Image_Hover:SetImage("ui\\Image\\UICommon\\battlefiled.UITex", 2)
		Image_Hover:Hide()

		local Image_Progress_Bar = self:Append("Image", Handle_Book, sformat("Progress_Bar_%d_%d", v.dwBookID, v.dwSegmentID),{w = 220, h = 32, x = 4, y = 4})
		Image_Progress_Bar:SetImage("ui\\Image\\Common\\Money.UITex", 211)
		Image_Progress_Bar:SetAlpha(180)
		Image_Progress_Bar:SetImageType(1)
		Image_Progress_Bar:Hide()


		local Image_Icon = self:Append("Image", Handle_Book, sformat("Image_Icon_%d_%d", v.dwBookID, v.dwSegmentID),{w = 30, h = 30, x = 8, y = 5})
		Image_Icon:FromIconID(Table_GetItemIconID(iteminfo.nUiId))
		Image_Bg:SetAlpha(160)

		local Text_Num = self:Append("Text", Handle_Book, sformat("Text_Num_%d_%d", v.dwBookID, v.dwSegmentID), {w = 30, h = 30, x = 8, y = 10})
		Text_Num:SetText("999")
		Text_Num:SetFontScheme(2)
		Text_Num:SetFontScale(0.8)
		Text_Num:SetHAlign(2)

		local Text_BookName = self:Append("Text", Handle_Book, sformat("TextName_Book_%d_%d", v.dwBookID, v.dwSegmentID), {w = 190, h = 40, x = 46, y = 0})
		Text_BookName:SetText(LR.Table_GetSegmentName(v.dwBookID, v.dwSegmentID))

		local Image_Lock = self:Append("Image", Handle_Book, sformat("Image_Lock_%d_%d", v.dwBookID, v.dwSegmentID),{w = 20, h = 25, x = 200, y = 6})
		Image_Lock:SetImage("ui\\Image\\Button\\frendnpartybutton.UITex", 89)
		Image_Lock:Hide()
		if iteminfo.nBindType == 3 then
			Image_Lock:Show()
		end

		if me.IsBookMemorized(v.dwBookID, v.dwSegmentID) then
			Handle_Book:SetAlpha(255)
			if not v.bCopy then
				Image_Bg:SetImage("ui\\Image\\UICommon\\battlefiled.UITex",3)
				Handle_Book:SetAlpha(140)
			end
		else
			Handle_Book:SetAlpha(70)
			Image_Bg:SetImage("ui\\Image\\UICommon\\battlefiled.UITex", 4)
		end

		Handle_Book.OnEnter = function()
			if me.IsBookMemorized(v.dwBookID, v.dwSegmentID) then
				Image_Hover:Show()
			end
			local info = GetBookTipByItemInfo(iteminfo, v.dwBookID, v.dwSegmentID, true)
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputTip(info, 400, { x, y, w, h })
		end

		Handle_Book.OnLeave = function()
			Image_Hover:Hide()
			HideTip()
		end
	end

	local WndWindow_Books = self:Fetch("WndWindow_Books")
	for k, v in pairs(bookList) do
		local checkbox = self:Append("CheckBox", WndWindow_Books, sformat("CheckBox_%d_%d", v.dwBookID, v.dwSegmentID),{w = 30, h = 30, x = 12, y = (k - 1) * 40 +7})
		checkbox:Enable(me.IsBookMemorized(v.dwBookID, v.dwSegmentID))
		checkbox:Check(v.bCopy and me.IsBookMemorized(v.dwBookID, v.dwSegmentID))
		checkbox.OnCheck = function(arg0)
			LR_CopyBook.UsrData.bookList[k].bCopy = arg0
			LR_CopyBook_MiniPanel:ChangeCheck(v.dwBookID, v.dwSegmentID, true)
			LR_CopyBook.CountNeeds()
			LR_CopyBook_MiniPanel:DrawNeed()
		end
	end

	Handle_Books:FormatAllItemPos()
	Handle_Books:SetSizeByAllItemSize()
	local WndWindow_Books = self:Fetch("WndWindow_Books")
	local w, h = Handle_Books:GetSize()
	WndWindow_Books:SetSize(290, h)

	LR_CopyBook.CountNeeds()
	LR_CopyBook_MiniPanel:DrawNeed()
	self:Resize()
	LR_CopyBook_MiniPanel:SetBookID()
	LR_CopyBook_MiniPanel:RefreshBookNum()
end

function LR_CopyBook_MiniPanel:Resize()
	local frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
	if not frame then
		return
	end

	local Img_Devide = frame:Lookup("","Image_Devide")
	local Wnd_CopyBTN = self:Fetch("Wnd_CopyBTN")
	local WndWindow_Books = self:Fetch("WndWindow_Books")
	local WndWindow_Need = self:Fetch("WndWindow_Need")
	local left, top = WndWindow_Books:GetRelPos()
	local width, height = WndWindow_Books:GetSize()
	local width2, height2 = WndWindow_Need:GetSize()

	local Img_bg = frame:Lookup("","Image_MainBg")
	if WndWindow_Books:IsVisible() then
		Img_Devide:SetRelPos(20, top + height - 10)
		Img_Devide:GetParent():FormatAllItemPos()
		WndWindow_Need:SetRelPos(20, top + height + 25)
		Wnd_CopyBTN:SetRelPos(60, top + height + height2 + 30)
		Img_bg:SetSize(320, top + height + height2 + 85)
		Img_bg:GetParent():SetSize(320, top + height + height2 + 85)
		frame:SetSize(320, top + height + height2 + 85)
		frame:SetDragArea(0, 0, 320, top + height + height2 + 85)
	else
		Img_Devide:SetRelPos(20, top - 10)
		Img_Devide:GetParent():FormatAllItemPos()
		WndWindow_Need:SetRelPos(20, top + 25)
		Wnd_CopyBTN:SetRelPos(60, top + height2 + 30)
		Img_bg:SetSize(320, top + height2 + 85)
		Img_bg:GetParent():SetSize(320, top + height2 + 85)
		frame:SetSize(320, top + height2 + 85)
		frame:SetDragArea(0, 0, 320, top + height2 + 85)
	end
end

function LR_CopyBook_MiniPanel:SetBookID()
	local frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
	if not frame then
		return
	end
	local Text_SuitBook = self:Fetch("Text_SuitBook")
	local szName = _L["No book set, please set"]
	if next(LR_CopyBook.UsrData.bookList) ~= nil then
		szName = sformat(_L["SuitBook Name:%s"], LR_CopyBook.GetBookName(LR_CopyBook.UsrData.bookList[1].dwBookID, 1))
	end
	Text_SuitBook:SetText(szName)
end

function LR_CopyBook_MiniPanel:ChangeCheck(dwBookID, dwSegmentID, flag)
	local frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
	if not frame then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end

	local bookList = LR_CopyBook.UsrData.bookList or {}
	local bCopy = LR_CopyBook.UsrData.bookList[dwSegmentID] and LR_CopyBook.UsrData.bookList[dwSegmentID].bCopy
	if not flag then
		local check_box = self:Fetch(sformat("CheckBox_%d_%d", dwBookID, dwSegmentID))
		check_box:Check(bCopy and me.IsBookMemorized(dwBookID, dwSegmentID))
	end

	local handle = self:Fetch(sformat("Handle_Book_%d_%d", dwBookID, dwSegmentID))
	local bg = self:Fetch(sformat("Image_Bg_%d_%d", dwBookID, dwSegmentID))
	if bCopy and me.IsBookMemorized(dwBookID, dwSegmentID) then
		bg:SetImage("ui\\Image\\UICommon\\battlefiled.UITex",1)
		handle:SetAlpha(255)
	elseif not bCopy then
		bg:SetImage("ui\\Image\\UICommon\\battlefiled.UITex",3)
		handle:SetAlpha(140)
	else
		bg:SetImage("ui\\Image\\UICommon\\battlefiled.UITex",4)
		handle:SetAlpha(70)
	end
end

function LR_CopyBook_MiniPanel:RefreshBookNum()
	local frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
	if not frame then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local bookList = LR_CopyBook.UsrData.bookList or {}
	for k, v in pairs(bookList) do
		local Text_Num = self:Fetch(sformat("Text_Num_%d_%d", v.dwBookID, v.dwSegmentID))
		local num = LR_CopyBook.GetBookNum(v.dwBookID, v.dwSegmentID)
		if num >= 0 then
			Text_Num:SetText(num)
		else
			Text_Num:SetText("")
		end
	end
end

function LR_CopyBook_MiniPanel:DrawNeed()
	local frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
	if not frame then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local Needs = LR_CopyBook.Needs or {}
	local Handle = self:Fetch("Handle_Need")
	self:ClearHandle(Handle)
	Handle:SetSize(280, 30)

	for k, v in pairs(Needs) do
		local iteminfo = GetItemInfo(v.nType, v.dwIndex)
		if iteminfo then
			local nUiId = iteminfo.nUiId
			local need = v.need
			local num = me.GetItemAmount(v.nType, v.dwIndex)
			local nIconID = Table_GetItemIconID(nUiId)
			local box = self:Append("Box", Handle, sformat("Box_%d", v.dwIndex), {h=30,w=30,})
			box:SetObject(1)
			box:SetObjectIcon(nIconID)

			box.OnEnter=function()
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				OutputItemTip(UI_OBJECT_ITEM_INFO, 1, v.nType, v.dwIndex, {x, y, w, h,})
			end

			box.OnLeave=function()
				HideTip()
			end

			local Text = self:Append("Text", Handle, sformat("Text_Need_%d", v.dwIndex), {w=30, h=30})
			Text:SetText(sformat("x %d ( %d )    ", num, need))
		end
	end
	Handle:FormatAllItemPos()
	Handle:SetSizeByAllItemSize()
	local w, h = Handle:GetSize()
	Handle:GetParent():SetSize(w, h)

	self:Resize()
end


---------------------------------------------------
local ProgressBar
function LR_CopyBook_MiniPanel.BreatheCall(dwBookID, dwSegmentID, nEndFrame, nTotalFrame)
	local frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
	if not frame then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local Bar = LR_CopyBook_MiniPanel:Fetch(sformat("Progress_Bar_%d_%d", dwBookID, dwSegmentID))
	if Bar then
		Bar:SetImage("ui\\Image\\Common\\Money.UITex", 211)
		Bar:SetAlpha(180)
		ProgressBar = Bar
		local nowFrame = GetLogicFrameCount()
		if nowFrame <= nEndFrame then
			local fP = 1- (nEndFrame - nowFrame) / nTotalFrame
			Bar:SetPercentage(fP)
			Bar:Show()
		else
			LR.UnBreatheCall("CopyBook_OT")
			Bar:SetImage("ui\\Image\\Common\\Money.UITex", 217)
			Bar:SetAlpha(255)
			LR.BreatheCall("CopyBook_OT_Fade", function() LR_CopyBook_MiniPanel.FadeOut(Bar) end)
			ProgressBar = nil
		end
	else
		ProgressBar = nil
		LR.UnBreatheCall("CopyBook_OT")
	end
end

function LR_CopyBook_MiniPanel.FadeOut(Bar)
	if Bar then
		local Alpha = Bar:GetAlpha()
		Alpha = Alpha - 30
		if Alpha < 0 then
			Bar:Hide()
			LR.UnBreatheCall("CopyBook_OT_Fade")

		else
			Bar:SetAlpha(Alpha)
		end
	else
		LR.UnBreatheCall("CopyBook_OT_Fade")
	end
end
-----------------------------------------------------
function LR_CopyBook_MiniPanel.BAG_ITEM_UPDATE()
	LR_CopyBook.CountNeeds()
	LR_CopyBook_MiniPanel:DrawNeed()
	LR_CopyBook_MiniPanel:RefreshBookNum()
end

function LR_CopyBook_MiniPanel.DO_RECIPE_PREPARE_PROGRESS()
	local nTotalFrame = arg0
	local CraftType = arg1
	local bookID = arg2
	if CraftType == 12 then
		local dwBookID, dwSegmentID = GlobelRecipeID2BookID(bookID)
		local nowFrame = GetLogicFrameCount()
		local nEndFrame = nowFrame +nTotalFrame
		LR.UnBreatheCall("CopyBook_OT_Fade")
		LR.BreatheCall("CopyBook_OT",function() LR_CopyBook_MiniPanel.BreatheCall(dwBookID, dwSegmentID, nEndFrame, nTotalFrame) end)
	end
end

function LR_CopyBook_MiniPanel.OT_ACTION_PROGRESS_BREAK()
	local dwID = arg0
	local me = GetClientPlayer()
	if not me then
		return
	end
	if dwID ~= me.dwID then
		return
	end
	local Bar = ProgressBar
	if Bar then
		Bar:SetImage("ui\\Image\\Common\\Money.UITex", 215)
		LR.UnBreatheCall("CopyBook_OT")
		LR.BreatheCall("CopyBook_OT_Fade", function() LR_CopyBook_MiniPanel.FadeOut(Bar) end)
	end
	ProgressBar = nil
end

LR.RegisterEvent("OT_ACTION_PROGRESS_BREAK", function() LR_CopyBook_MiniPanel.OT_ACTION_PROGRESS_BREAK() end)
LR.RegisterEvent("DO_RECIPE_PREPARE_PROGRESS", function() LR_CopyBook_MiniPanel.DO_RECIPE_PREPARE_PROGRESS() end)
LR.RegisterEvent("BAG_ITEM_UPDATE",function() LR_CopyBook_MiniPanel.BAG_ITEM_UPDATE() end)

