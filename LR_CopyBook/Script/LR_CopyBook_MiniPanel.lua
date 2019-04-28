local AddonPath="Interface\\LR_Plugin\\LR_CopyBook"
local _L = LR.LoadLangPack(AddonPath)
local sformat, slen, sgsub, ssub,sfind = string.format, string.len, string.gsub, string.sub, string.find
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil = math.floor, math.ceil
local tconcat, tinsert, tremove, tsort = table.concat, table.insert, table.remove, table.sort
-------------------------------------------------------------
-- 创建插件
LR_CopyBook_MiniPanel = _G2.CreateAddon("LR_CopyBook_MiniPanel")
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
	this:RegisterEvent("BAG_ITEM_UPDATE")
	this:RegisterEvent("OT_ACTION_PROGRESS_BREAK")
	this:RegisterEvent("DO_RECIPE_PREPARE_PROGRESS")

	LR_CopyBook_MiniPanel.UpdateAnchor(this)
end

-- 事件回调
--/script ReloadUIAddon()
function LR_CopyBook_MiniPanel:OnEvents(event)
	if event == "UI_SCALED" then
		LR_CopyBook_MiniPanel.UpdateAnchor(this)
	elseif event == "BAG_ITEM_UPDATE" then
		LR_CopyBook_MiniPanel.BAG_ITEM_UPDATE()
	elseif event == "OT_ACTION_PROGRESS_BREAK" then
		LR_CopyBook_MiniPanel.OT_ACTION_PROGRESS_BREAK()
	elseif event == "DO_RECIPE_PREPARE_PROGRESS" then
		LR_CopyBook_MiniPanel.DO_RECIPE_PREPARE_PROGRESS()
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

	local Btn_Option = LR.AppendUI("UIButton", frame, "Btn_Option", {w = 34, h = 34, x = 5, y = 8, ani = {"ui\\Image\\Button\\SystemButton_1.UITex", 1, 2, 3}})
	Btn_Option:SetAlpha(220)
	Btn_Option.OnClick = function()
		LR_TOOLS:OpenPanel(_L["LR Printing Machine"])
	end
	Btn_Option.OnRClick = function()
		LR_CopyBook.Gets()
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

	local edit = self:Append("Edit", frame, "Edit_Num", {x = 20, y = 85, w = 30})
	edit:SetText(LR_CopyBook.UsrData.nCopySuiteNum)
	edit.OnChange = function(value)
		local x = tonumber(value)
		if type(x) == "number" then
			if x > 100 then
				x = 100
				this:SetText(x)
			end
			LR_CopyBook.UsrData.nCopySuiteNum = x

			if LR_TOOLS:Fetch("edit_CopyBookNum") and LR_TOOLS:Fetch("edit_CopyBookNum"):GetText() ~= tostring(x) then
				LR_TOOLS:Fetch("edit_CopyBookNum"):SetText(x)
			end
			LR_CopyBook_MiniPanel:DrawNeed()
		end
	end

	local Btn_Max = self:Append("Button", frame, "Btn_Max", {x = 60, y = 85, w = 50, text = _L["Max"]})
	Btn_Max.OnClick = function()
		local nMax = LR_CopyBook.GetCanCopySuiteNum()
		edit:SetText(nMax)
		local edit2 = LR_TOOLS:Fetch("edit_CopyBookNum")
		if edit2 then
			edit2:SetText(nMax)
		end
	end

	---Need
	WndWindow_Need = self:Append("Window", frame, "WndWindow_Need", {w = 290, h = 30, x = 20, y = 85, })
	local Handle_Need = self:Append("Handle", WndWindow_Need, "Handle_Need", {w = 290, h = 30, x = 0, y = 0})
	Handle_Need:SetHandleStyle(3)

	---Begin/Stop button
	local Wnd_CopyBTN =	self:Append("Window", frame, "Wnd_CopyBTN", {w = 240, h = 40, x = 0, y = 0, })
	--创建一个按钮
	local button1 = self:Append("Button", Wnd_CopyBTN, "button1",{text = _L["Begin Printing"] ,x = 0,y = 0,w = 95,h = 36})
	--绑定按钮点击事件
	button1.OnClick = function()
		LR_CopyBook.StartCopy()
	end
	local button2 = self:Append("Button", Wnd_CopyBTN,"button2",{text = _L["Stop Printing!"],x = 110,y = 0,w = 95,h = 36})
	button2.OnClick = function()
		LR_CopyBook.StopCopy()
	end

	self:LoadSuitBooks()
	local WndWindow_Books = self:Fetch("WndWindow_Books")
	WndWindow_Books:Show()
	Handle_BookID.OnClick = function()
		local WndWindow_Books = self:Fetch("WndWindow_Books")
		WndWindow_Books:ToggleVisible()
		self:Resize()
	end

	self:Resize()

	LR.Animate(frame:GetSelf()):FadeIn():Pos({0, -20}):Scale(0.1)
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

	WndWindow_Books = self:Append("Window", frame,"WndWindow_Books",{w = 290, h = 90, x = 20, y = 115, })
	local Handle_Books = self:Append("Handle", WndWindow_Books,"Handle_Books",{w = 280, h = 30, x = 0, y = 0})
	Handle_Books:SetHandleStyle(3)

	local tCopyList = LR_CopyBook.UsrData.tCopyList or {}
	local i = 1
	for k, v in pairs(tCopyList) do
		local dwIndex = LR.Table_GetBookItemIndex(v.dwBookID, v.dwSegmentID)
		local iteminfo = GetItemInfo(5, dwIndex)

		local Handle_Book = self:Append("Handle", Handle_Books, sformat("Handle_Book_%d_%d", v.dwBookID, v.dwSegmentID), {w = 55, h = 55})
		local Box = self:Append("Box", Handle_Book, sformat("Box_%d_%d", v.dwBookID, v.dwSegmentID), {w = 50, h = 50})
		Box:SetObject(1)
		Box:SetObjectIcon(Table_GetItemIconID(iteminfo.nUiId))

		Box:SetOverText(1, LR.GetItemNumInBag(5, dwIndex, v.dwBookID, v.dwSegmentID))
		Box:SetOverTextFontScheme(1, 15)
		Box:SetOverTextPosition(1, ITEM_POSITION.RIGHT_BOTTOM)

		if iteminfo.nBindType == 3 then
			local ImageLock = LR.AppendUI("Image", Handle_Book, sformat("Image_Lock"), {x = 0, y = 0, w = 25, h = 25})
			ImageLock:SetImage("ui\\Image\\Button\\frendnpartybutton.UITex", 90)
		end

		Box:SetOverText(2, sformat("%d.", i))
		Box:SetOverTextFontScheme(2, 15)
		Box:SetOverTextPosition(2, ITEM_POSITION.LEFT_TOP)

		local ImageBCopy = self:Append("Image", Handle_Book, sformat("ImageBCopy_%d_%d", v.dwBookID, v.dwSegmentID), {x = 25, y = 0, w = 25, h = 25})
		if not me.IsBookMemorized(v.dwBookID, v.dwSegmentID) then
			ImageBCopy:FromUITex("ui/Image/GMPanel/gm2.UITex", 8)
			Box:EnableObject(false)
		elseif v.bCopy then
			ImageBCopy:FromUITex("ui/Image/GMPanel/gm2.UITex", 7)
			Box:EnableObject(true)
		else
			ImageBCopy:Hide()
			Box:EnableObject(true)
		end

		Box.OnEnter = function()
			if me.IsBookMemorized(v.dwBookID, v.dwSegmentID) then
				--Image_Hover:Show()
			end
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputBookTipByID(v.dwBookID, v.dwSegmentID, {x, y, w, h})
		end
		Box.OnLeave = function()
			HideTip()
		end
		Box.OnClick = function()
			if not GetClientPlayer().IsBookMemorized(v.dwBookID, v.dwSegmentID) then
				return
			end
			v.bCopy = not v.bCopy
			LR_CopyBook_MiniPanel:ChangeCheck(v.dwBookID, v.dwSegmentID)
		end

		i = i + 1
	end

	local WndWindow_Books = self:Fetch("WndWindow_Books")
	Handle_Books:FormatAllItemPos()
	Handle_Books:SetSizeByAllItemSize()
	local WndWindow_Books = self:Fetch("WndWindow_Books")
	local w, h = Handle_Books:GetSize()
	WndWindow_Books:SetSize(290, h)

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
	if next(LR_CopyBook.UsrData.tCopyList) ~= nil then
		szName = sformat(_L["SuitBook Name:%s"], LR_CopyBook.GetSuiteBookNameByID(LR_CopyBook.UsrData.tCopyList[1].dwBookID))
	end
	Text_SuitBook:SetText(szName)
end

function LR_CopyBook_MiniPanel:ChangeCheck(dwBookID, dwSegmentID)
	local frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
	if not frame then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end

	local tCopyList = LR_CopyBook.UsrData.tCopyList or {}
	local bCopy = LR_CopyBook.UsrData.tCopyList[dwSegmentID] and LR_CopyBook.UsrData.tCopyList[dwSegmentID].bCopy or false

	local ImageBCopy = self:Fetch(sformat("ImageBCopy_%d_%d", dwBookID, dwSegmentID))
	if not me.IsBookMemorized(dwBookID, dwSegmentID) then
		ImageBCopy:FromUITex("ui/Image/GMPanel/gm2.UITex", 8)
		ImageBCopy:Show()
	elseif LR_CopyBook.UsrData.tCopyList[dwSegmentID].bCopy then
		ImageBCopy:FromUITex("ui/Image/GMPanel/gm2.UITex", 7)
		ImageBCopy:Show()
	else
		ImageBCopy:Hide()
	end

	LR_CopyBook_MiniPanel:DrawNeed()
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
	local tCopyList = LR_CopyBook.UsrData.tCopyList or {}
	for k, v in pairs(tCopyList) do
		local Box = self:Fetch(sformat("Box_%d_%d", v.dwBookID, v.dwSegmentID))
		local dwIndex = LR.Table_GetBookItemIndex(v.dwBookID, v.dwSegmentID)
		local num = LR.GetItemNumInBag(5, dwIndex, v.dwBookID, v.dwSegmentID)
		if num >= 0 then
			Box:SetOverText(1, num)
		else
			Box:SetOverText(1, "")
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

	local Needs = LR_CopyBook.GetAllRecipeAgainstHasInBag()
	local Handle = self:Fetch("Handle_Need")
	self:ClearHandle(Handle)
	Handle:SetSize(280, 30)

	local hHandle1 = self:Append("Handle", Handle, "Handle_Text1", {w = 280, h = 30})
	local tText = self:Append("Text", hHandle1, "Text_Recipe_All", {w = 280, h = 30, x = 0, y = 0, text = _L["Recipe have"]})
	for k, v in pairs(Needs) do
		local _s, _e, dwTabType, dwIndex = sfind(k, "(.+)_(.+)")
		local iteminfo = GetItemInfo(dwTabType, dwIndex)
		if iteminfo then
			local nUiId = iteminfo.nUiId
			local nIconID = Table_GetItemIconID(nUiId)
			local hHandle = self:Append("Handle", Handle, sformat("Handle_%d_%d", dwTabType, dwIndex), {w = 50, h = 50,})
			local box = self:Append("Box", hHandle, sformat("Box_%d_%d", dwTabType, dwIndex), {h = 45, w = 45,})
			box:SetObject(1)
			box:SetObjectIcon(nIconID)
			box:SetOverText(1, v.have)
			box:SetOverTextFontScheme(1, 15)
			box:SetOverTextPosition(1, ITEM_POSITION.RIGHT_BOTTOM)
			box.OnEnter=function()
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				OutputItemTip(UI_OBJECT_ITEM_INFO, 1, dwTabType, dwIndex, {x, y, w, h,})
			end

			box.OnLeave=function()
				HideTip()
			end
		end
	end

	local hHandle2 = self:Append("Handle", Handle, "Handle_Text2", {w = 280, h = 30})
	local tText = self:Append("Text", hHandle2, "Text_Recipe_Need", {w = 280, h = 30, x = 0, y = 0, text = _L["Recipe need"]})

	local hHandle3 = self:Append("Handle", Handle, "Handle_Recipe_Need", {w = 280, h = 30})
	LR_CopyBook.DrawRecipeBoxes(hHandle3)

	Handle:FormatAllItemPos()
	Handle:SetSizeByAllItemSize()
	local w, h = Handle:GetSize()
	Handle:GetParent():SetSize(w, h)

	self:Resize()
end


---------------------------------------------------
local COPYING_CACHE = {}
local ProgressBar
function LR_CopyBook_MiniPanel.BreatheCall(dwBookID, dwSegmentID, nEndFrame, nTotalFrame)
	local frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
	if not frame then
		return
	end

	local BOX = LR_CopyBook_MiniPanel:Fetch(sformat("Box_%d_%d", dwBookID, dwSegmentID))
	if BOX then
		if GetLogicFrameCount() > nEndFrame then
			BOX:SetObjectSelected(false)
			BOX:SetCoolDownPercentage(0)
			BOX:SetObjectCoolDown(false)
			COPYING_CACHE = {}
			LR.UnBreatheCall("CopyBook_OT")
		else
			local fp = (nEndFrame - GetLogicFrameCount()) / nTotalFrame * 1.0
			BOX:SetObjectCoolDown(true)
			BOX:SetCoolDownPercentage(fp)
		end
	else
		COPYING_CACHE = {}
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
		local nEndFrame = nowFrame + nTotalFrame
		local BOX = LR_CopyBook_MiniPanel:Fetch(sformat("Box_%d_%d", dwBookID, dwSegmentID))
		if BOX then
			BOX:SetObjectSelected(true)
		end
		COPYING_CACHE = {dwBookID = dwBookID, dwSegmentID = dwSegmentID}
		LR.BreatheCall("CopyBook_OT", function() LR_CopyBook_MiniPanel.BreatheCall(dwBookID, dwSegmentID, nEndFrame, nTotalFrame) end)
	end
end

function LR_CopyBook_MiniPanel.OT_ACTION_PROGRESS_BREAK()
	local frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
	if not frame then
		return
	end
	local dwID = arg0
	local me = GetClientPlayer()
	if not me then
		return
	end
	if dwID ~= me.dwID then
		return
	end
	local dwBookID, dwSegmentID = COPYING_CACHE.dwBookID or 0, COPYING_CACHE.dwSegmentID or 0
	local Bar = ProgressBar
	local BOX = LR_CopyBook_MiniPanel:Fetch(sformat("Box_%d_%d", dwBookID, dwSegmentID))
	if BOX then
		BOX:SetObjectSelected(false)
		BOX:SetCoolDownPercentage(0)
		BOX:SetObjectCoolDown(false)
		COPYING_CACHE = {}
		LR.UnBreatheCall("CopyBook_OT")
	end
	COPYING_CACHE = {}
end

function LR_CopyBook_MiniPanel.SYS_MSG()
	local Bar = ProgressBar
	if Bar then
		LR.UnBreatheCall("CopyBook_OT")
		LR.BreatheCall("CopyBook_OT_Fade", function() LR_CopyBook_MiniPanel.FadeOut(Bar) end)
	end
	ProgressBar = nil
end
