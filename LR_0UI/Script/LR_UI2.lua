local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
----------------------------------------------
-- base
----------------------------------------------
local x = {}
function x:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	self.__addon = true
	self.__listener = {self}
	return o
end

function x:__SetSelf(__self)
	self.__self = __self
	return self
end

function x:__SetParent(__parent)
	self.__parent = __parent
	return self
end

function x:GetParent()
	return self.__parent
end

function x:__SetType(__type)
	self.__type = __type
	return self
end

function x:GetType(__type)
	return self.__type
end

function x:__FireEvent(szEvent, ...)
	for k, v in pairs(self.__listener) do
		if v[szEvent] and type(v[szEvent]) == "function" then
			local res, err = pcall(v[szEvent], ...)
			if not res then
				LR.SysMsg( "ERROR:" .. err .."\n")
			end
		end
	end
end

----------------------------------------------
-- AppendWnd
----------------------------------------------
local ini_path = "Interface/LR_Plugin/LR_0UI/ini/%s.ini"
local NAME_INDEX = 1
local AppendWnd = function(__parent, __type, __name)
	if not __name then
		__name = string.format("LR_XUI_%d", NAME_INDEX)
		NAME_INDEX = NAME_INDEX + 1
	end
	if __parent.__addon then
		__parent = __parent:GetSelf()
	end
	local hwnd = Wnd.OpenWindow(string.format(ini_path, __type), __name):Lookup(__type)
	hwnd:ChangeRelation(__parent, true, true)
	hwnd:SetName(__name)
	Wnd.CloseWindow(__name)
	return hwnd
end

----------------------------------------------
-- WndWindow
----------------------------------------------
local WndWindow = x:new()
function WndWindow:Init(parent, name, data)
	assert(parent ~= nil, sformat("%s, parent can not be null.", name))
	data = data or {}
	local hwnd = AppendWnd(parent, "WndWindow", name)
	self.__this = hwnd
	self:__SetSelf(self.__this)
	self:__SetParent(parent)
	self:__SetType("WndWindow")
	self:SetSize(data.w or 100, data.h or 100)
	self:SetRelPos(data.x or 0, data.y or 0)
	self.data = {parent = parent, name = name, data = data}
	return self
end

function WndWindow:GetRelPos()
	return self.__this:GetRelPos()
end

function WndWindow:GetAbsPos()
	return self.__this:GetAbsPos()
end

function WndWindow:GetSize()
	return self.__this:GetSize()
end

function WndWindow:SetSize(...)
	self.__this:SetSize(...)
	return self
end

function WndWindow:IsVisible()
	return self.__this:IsVisible()
end

function WndWindow:IsDisable()
	return self.__this:IsDisable()
end

function WndWindow:SetRelPos(...)
	self.__this:SetRelPos(...)
	return self
end

function WndWindow:SetAbsPos(...)
	self.__this:SetAbsPos(...)
	return self
end

function WndWindow:SetCursorAbove()
	self.__this:SetCursorAbove()
	return self
end

function WndWindow:Enable(...)
	self.__this:Enable(...)
	return self
end

function WndWindow:Show(...)
	self.__this:Show(...)
	return self
end

function WndWindow:Hide(...)
	self.__this:Hide(...)
	return self
end

function WndWindow:ToggleVisible()
	self.__this:ToggleVisible()
	return self
end

function WndWindow:BringToTop()
	self.__this:BringToTop()
	return self
end

function WndWindow:Scale(...)
	self.__this:Scale(...)
	return self
end

function WndWindow:CreateItemHandle(...)
	self.__this:CreateItemHandle(...)
	return self
end

function WndWindow:ReleaseItemHandle()
	self.__this:ReleaseItemHandle()
	return self
end

function WndWindow:Lookup(...)
	self.__this:Lookup(...)
	return self
end

function WndWindow:GetName()
	self.__this:GetName()
	return self
end

function WndWindow:SetName(...)
	self.__this:SetName(...)
	return self
end

function WndWindow:GetPrev()
	self.__this:GetPrev()
	return self
end

function WndWindow:GetNext()
	self.__this:GetNext()
	return self
end

function WndWindow:GetParent()
	self.__this:GetParent()
	return self
end

function WndWindow:GetRoot()
	self.__this:GetRoot()
	return self
end

function WndWindow:GetFirstChild()
	self.__this:GetFirstChild()
	return self
end

function WndWindow:CorrectPos(...)
	self.__this:CorrectPos(...)
	return self
end

function WndWindow:SetSizeWithAllChild(bEnable)
	self.__this:SetSizeWithAllChild(bEnable)
	return self
end

function WndWindow:SetMousePenetrable(bEnable)
	self.__this:SetMousePenetrable(bEnable)
	return self
end

function WndWindow:SetAlpha(nAlpha)
	self.__this:SetAlpha(nAlpha)
	return self
end

function WndWindow:SetSelfAlpha(nAlpha)
	self.__this:SetSelfAlpha(nAlpha)
	return self
end

function WndWindow:GetAlpha()
	return self.__this:GetAlpha()
end

function WndWindow:GetType()
	return self.__this:GetType()
end

function WndWindow:ChangeRelation(...)
	self.__this:ChangeRelation(...)
	return self
end

function WndWindow:SetPoint(...)
	self.__this:SetPoint(...)
	return self
end

function WndWindow:Destroy()
	self.__this:Destroy()
	return self
end

function WndWindow:GetTreePath()
	return self.__this:GetTreePath()
end

function WndWindow:IsValid()
	return self.__this:IsValid()
end

----------------------------------------------
-- WndEdit
----------------------------------------------
local WndEdit = WndWindow:new()
function WndEdit:Init(parent, name, data)
	assert(parent ~= nil, sformat("%s, parent can not be null.", name))
	data = data or {}
	local hwnd = AppendWnd(parent, "WndEdit", name)
	self.__this = hwnd
	self.__edit = hwnd:Lookup("Edit_Default")
	self:__SetSelf(self.__this)
	self:__SetParent(parent)
	self:__SetType("WndEdit")
	self:SetSize(data.w or 100, data.h or 25)
	self:SetRelPos(data.x or 0, data.y or 0)
	self.data = {parent = parent, name = name, data = data}
	return self
end

function WndEdit:SetText(...)
	self.__edit:SetText(...)
	return self
end

function WndEdit:GetText()
	return self.__edit:GetText()
end

function WndEdit:GetTextLength()
	return self.__edit:GetTextLength()
end

function WndEdit:ClearText()
	self.__edit:ClearText()
	return self
end

function WndEdit:InsertObj(...)
	self.__edit:InsertObj(...)
	return self
end

function WndEdit:GetTextStruct()
	return self.__edit:GetTextStruct()
end

function WndEdit:SetType(...)
	self.__edit:SetType(...)
	return self
end

function WndEdit:SetLimit(...)
	self.__edit:SetLimit(...)
	return self
end

function WndEdit:GetLimit()
	return self.__edit:GetLimit()
end

function WndEdit:SetLimitMultiByte(...)
	self.__edit:SetLimitMultiByte(...)
	return self
end

function WndEdit:IsLimitMultiByte()
	return self.__edit:IsLimitMultiByte()
end

function WndEdit:SelectAll()
	self.__edit:SelectAll()
	return self
end

function WndEdit:CancelSelect()
	self.__edit:CancelSelect()
	return self
end

function WndEdit:SetFontScheme(...)
	self.__edit:SetFontScheme(...)
	return self
end

function WndEdit:GetFontScheme()
	return self.__edit:GetFontScheme()
end

function WndEdit:SetFontColor(...)
	self.__edit:SetFontColor(...)
	return self
end

function WndEdit:InsertText(...)
	self.__edit:InsertText(...)
	return self
end

function WndEdit:Backspace()
	self.__edit:Backspace()
	return self
end

function WndEdit:SetMultiLine(...)
	self.__edit:SetMultiLine(...)
	return self
end

function WndEdit:IsMultiLine()
	return self.__edit:IsMultiLine()
end

function WndEdit:SetFontSpacing(...)
	self.__edit:SetFontSpacing(...)
	return self
end

function WndEdit:SetRowSpacing(...)
	self.__edit:SetRowSpacing(...)
	return self
end

function WndEdit:SetFocusBgColor(...)
	self.__edit:SetFocusBgColor(...)
	return self
end

function WndEdit:SetSelectBgColor(...)
	self.__edit:SetSelectBgColor(...)
	return self
end

function WndEdit:SetSelectFontScheme(...)
	self.__edit:SetSelectFontScheme(...)
	return self
end

function WndEdit:SetCurSel(...)
	self.__edit:SetCurSel(...)
	return self
end

----------------------------------------------
-- WndButton
----------------------------------------------
local WndButton = WndWindow:new()
function WndButton:Init(parent, name, data)
	assert(parent ~= nil, sformat("%s, parent can not be null.", name))
	data = data or {}
	local hwnd = AppendWnd(parent, "WndButton", name)
	self.__this = hwnd
	self.__text = hwnd:Lookup("", "Text_Default")
	self:SetText(data.text or "")
	self:__SetSelf(self.__this)
	self:__SetParent(parent)
	self:__SetType("WndButton")
	self:Enable((data.enable == nil or data.enable) and true or false)
	self:SetSize(data.w or 91, data.h)
	self:SetRelPos(data.x or 0, data.y or 0)
	self.data = {parent = parent, name = name, data = data}

	--Bind Button Events
	self.__this.OnLButtonClick = function()
		self:__FireEvent("OnLButtonClick")
	end
	self.__this.OnMouseEnter = function()
		self:__FireEvent("OnMouseEnter")
	end
	self.__this.OnMouseLeave = function()
		self:__FireEvent("OnMouseLeave")
	end
	return self
end

function WndButton:IsEnabled()
	return self.__this:IsEnabled()
end

function WndButton:Enable(bEnable)
	if bEnable then
		self.__this:Enable(true)
		self.__text:SetFontColor(255, 255, 255)
	else
		self.__text:SetFontColor(180, 180, 180)
		self.__this:Enable(false)
	end
	return self
end

function WndButton:SetAnimateGroupNormal(nGroup)
	self.__this:SetAnimateGroupNormal(nGroup)
	return self
end

function WndButton:SetAnimateGroupMouseOver(nGroup)
	self.__this:SetAnimateGroupMouseOver(nGroup)
	return self
end

function WndButton:SetAnimateGroupMouseDown(nGroup)
	self.__this:SetAnimateGroupMouseDown(nGroup)
	return self
end

function WndButton:SetAnimateGroupDisable(nGroup)
	self.__this:SetAnimateGroupDisable(nGroup)
	return self
end

function WndButton:RegisterLButtonDrag()
	self.__this:SetAnimateGroupDisable()
	return self
end

function WndButton:UnregisterLButtonDrag()
	self.__this:UnregisterLButtonDrag()
	return self
end

function WndButton:IsLButtonDragable(bDrageble)
	self.__this:IsLButtonDragable(bDrageble)
	return self
end

function WndButton:RegisterRButtonDrag()
	self.__this:RegisterRButtonDrag()
	return self
end

function WndButton:UnregisterRButtonDrag()
	self.__this:UnregisterRButtonDrag()
	return self
end

function WndButton:IsRButtonDragable(bDrageble)
	self.__this:IsRButtonDragable(bDrageble)
	return self
end

--
function WndButton:SetText(...)
	self.__text:SetText(...)
	return self
end

function WndButton:GetText()
	return self.__text:GetText()
end

function WndButton:SetFontScheme(...)
	self.__text:SetFontScheme(...)
	return self
end

function WndButton:SetSize(__w, __h)
	self.__this:SetSize(__w, __h or 26)
	self.__this:Lookup("", ""):SetSize(__w, __h or 26)
	self.__text:SetSize(__w, __h or 26)
	return self
end


----------------------------------------------
-- WndUIButton
----------------------------------------------
local WndUIButton = WndWindow:new()
function WndUIButton:Init(parent, name, data)
	assert(parent ~= nil, "parent can not be null.")
	data = data or {}
	local hwnd = AppendWnd(parent, "WndUIButton", name)
	self.__image = hwnd:Lookup("", "Image_Default")
	self.__text = hwnd:Lookup("", "Text_Default")
	self.__text:SetText(data.text or "")
	self.__this = hwnd
	self:__SetSelf(self.__this)
	self:__SetParent(parent)
	self:__SetType("WndUIButton")
	self.__animate = data.ani
	self:SetSize(data.w or 40, data.h or 40)
	self:Enable((data.enable == nil or data.enable) and true or false)
	self:SetRelPos(data.x or 0, data.y or 0)
	self:_UpdateNormal()

	--Bind Button Events
	self.__this.OnMouseEnter = function()
		if self:IsEnabled() then
			self:_UpdateOver()
		end
		self:__FireEvent("OnMouseEnter")
	end
	self.__this.OnMouseLeave = function()
		if self:IsEnabled() then
			self:_UpdateNormal()
		end
		self:__FireEvent("OnMouseLeave")
	end
	self.__this.OnLButtonClick = function()
		self:__FireEvent("OnLButtonClick")
	end
	self.__this.OnLButtonDown = function()
		if self:IsEnabled() then
			self:_UpdateDown()
		end
	end
	self.__this.OnLButtonUp = function()
		if self:IsEnabled() then
			self:_UpdateOver()
		end
	end
	self.__this.OnRButtonDown = function()
		if self:IsEnabled() then
			self:_UpdateDown()
		end
	end
	self.__this.OnRButtonUp = function()
		if self:IsEnabled() then
			self:_UpdateOver()
		end
	end
	self.__this.OnRButtonClick = function()
		self:__FireEvent("OnRButtonClick")
	end
end

function WndUIButton:SetFontColor(...)
	self.__text:SetFontColor(...)
	return self
end

function WndUIButton:Enable(__enable)
	if __enable then
		self.__text:SetFontColor(255, 255, 255)
		self.__this:Enable(true)
		self:_UpdateNormal()
	else
		self.__text:SetFontColor(180, 180, 180)
		self.__this:Enable(false)
		self:_UpdateDisable()
	end
	return self
end

function WndUIButton:_UpdateNormal()
	self.__image:FromUITex(self.__animate[1], self.__animate[2])
end

function WndUIButton:_UpdateOver()
	self.__image:FromUITex(self.__animate[1], self.__animate[3])
end

function WndUIButton:_UpdateDown()
	self.__image:FromUITex(self.__animate[1], self.__animate[4])
end

function WndUIButton:_UpdateDisable()
	self.__image:FromUITex(self.__animate[1], self.__animate[5])
end

function WndUIButton:IsEnabled()
	return self.__this:IsEnabled()
end

function WndUIButton:SetText(...)
	self.__text:SetText(...)
	return self
end

function WndUIButton:GetText()
	return self.__text:GetText()
end

function WndUIButton:SetSize(__w, __h)
	self.__this:SetSize(__w, __h)
	self.__this:Lookup("", ""):SetSize(__w, __h)
	self.__image:SetSize(__w, __h)
	self.__text:SetSize(__w, __h)
	return self
end

----------------------------------------------
-- WndCheckBox
----------------------------------------------
local WndCheckBox = WndWindow:new()
function WndCheckBox:Init(parent, name, data)
	assert(parent ~= nil, "parent can not be null.")
	data = data or {}
	local hwnd = _AppendWnd(parent, "WndCheckBox", name)
	self.__text = hwnd:Lookup("", "Text_Default")
	self.__this = hwnd
	self.__CheckBox = hwnd--:Lookup("WndCheckBox1")
	self.__h = hwnd:Lookup("", "")
	self:__SetSelf(self.__this)
	self:__SetParent(__parent)
	self:__SetType("WndCheckBox")
	self:Check(data.check or false)
	self:Enable((data.enable == nil or data.enable) and true or false)
	self.__text:SetText(data.text or "")
	--local _w=math.max((__data.w or 150),self.__text:GetTextExtent())
	self:SetSize(self.__text:GetTextExtent())
	self:SetRelPos(data.x or 0, data.y or 0)

	--Bind CheckBox Events
	self.__CheckBox.OnCheckBoxCheck = function()
		self:__FireEvent("OnCheck", true)
	end
	self.__CheckBox.OnCheckBoxUncheck = function()
		self:__FireEvent("OnCheck", false)
	end
	self.__CheckBox.OnMouseEnter = function()
		self:__FireEvent("OnMouseEnter")
	end
	self.__CheckBox.OnMouseLeave = function()
		self:__FireEvent("OnMouseLeave")
	end
	self.__text:SetVAlign(0)
end

function WndCheckBox:IsCheckBoxActive()
	return self.__CheckBox:IsCheckBoxActive()
end

function WndCheckBox:Enable(__enable)
	if __enable then
		self.__text:SetFontColor(255, 255, 255)
		self.__CheckBox:Enable(true)
	else
		self.__text:SetFontColor(180, 180, 180)
		self.__CheckBox:Enable(false)
	end
	return self
end

function WndCheckBox:IsChecked()
	return self.__CheckBox:IsCheckBoxChecked()
end

function WndCheckBox:Check(...)
	self.__CheckBox:Check(...)
	return self
end

function WndCheckBox:ToggleCheck(...)
	self.__CheckBox:ToggleCheck(...)
	return self
end

function WndCheckBox:SetAnimation(...)
	self.__CheckBox:SetAnimation(...)
	return self
end

--
function WndCheckBox:SetSize(__w)
	--self.__this:SetSize (__w+28 , 30)
	local _, h = self.__text:GetSize()
	local w = self.__text:GetTextExtent()
	self.__text:SetSize(w, h)
	self.__h:SetSize(w + 30, h)
	self.__h:FormatAllItemPos()
	return self
end

function WndCheckBox:SetText(...)
	self.__text:SetText(...)
	return self
end

function WndCheckBox:GetText()
	return self.__text:GetText()
end

function WndCheckBox:SetFontColor(...)
	self.__text:SetFontColor(...)
	return self
end

function WndCheckBox:GetFontColor()
	return self.__text:GetFontColor()
end

function WndCheckBox:SetFontScheme(...)
	self.__text:SetFontScheme(...)
	return self
end

function WndCheckBox:GetFontScheme()
	return self.__text:GetFontScheme()
end

----------------------------------------------
-- WndNewScrollBar
----------------------------------------------
local WndNewScrollBar = WndWindow:new()
function WndNewScrollBar:Init(parent, name, data)
	assert(parent ~= nil, "parent can not be null.")
	data = data or {}
	local hwnd = _AppendWnd(parent, "WndNewScrollBar", name)
	self.__this = hwnd
	self:__SetSelf(self.__this)
	self:__SetParent(__parent)
	self:__SetType("WndNewScrollBar")
	self:Enable((data.enable == nil or data.enable) and true or false)

	return self
end

function WndNewScrollBar:SetScrollPos(nPos)
	self.__this:SetScrollPos(nPos)
	return self
end

function WndNewScrollBar:GetScrollPos()
	return self.__this:GetScrollPos()
end

function WndNewScrollBar:SetStepCount(nStepCount)
	self.__this:SetStepCount(nStepCount)
	return self
end

function WndNewScrollBar:GetStepCount()
	return self.__this:GetStepCount()
end

function WndNewScrollBar:SetPageStepCount(nStepCount)
	self.__this:SetPageStepCount(nStepCount)
	return self
end

function WndNewScrollBar:GetPageStepCount()
	return self.__this:GetPageStepCount()
end

function WndNewScrollBar:ScrollPrev(nStepCount)
	self.__this:ScrollPrev(nStepCount)
	return self
end

function WndNewScrollBar:ScrollNext(nStepCount)
	self.__this:ScrollNext(nStepCount)
	return self
end

function WndNewScrollBar:ScrollPagePrev()
	self.__this:ScrollPagePrev()
	return self
end

function WndNewScrollBar:ScrollPageNext()
	self.__this:ScrollPageNext()
	return self
end

function WndNewScrollBar:ScrollHome()
	self.__this:ScrollHome()
	return self
end

function WndNewScrollBar:ScrollEnd()
	self.__this:ScrollEnd()
	return self
end

function WndNewScrollBar:SetDragStep(nDragStep)
	self.__this:SetDragStep(nDragStep)
	return self
end

----------------------------------------------
-- WndNewScrollBar
----------------------------------------------
local WndScroll = WndWindow:new()
function WndScroll:Init(parent, name, data)
	assert(parent ~= nil, "parent can not be null.")
	data = data or {}
	local hwnd = AppendWnd(parent, "WndScroll", name)
	self.__this = hwnd
	self:__SetSelf(self.__this)
	self:__SetParent(__parent)
	self:__SetType("WndScroll")
	self.__up = self.__this:Lookup("Btn_Up")
	self.__down = self.__this:Lookup("Btn_Down")
	self.__scroll = self.__this:Lookup("Scroll_List")
	self.__handle = self.__this:Lookup("", "")

	self:SetSize(data.w or 500, data.h or 345)
	self:SetRelPos(data.x or 0, data.y or 0)

	self.__up.OnLButtonHold = function()
		self.__scroll:ScrollPrev(1)
	end
	self.__up.OnLButtonDown = function()
		self.__scroll:ScrollPrev(1)
	end
	self.__down.OnLButtonHold = function()
		self.__scroll:ScrollNext(1)
	end
	self.__down.OnLButtonDown = function()
		self.__scroll:ScrollNext(1)
	end
	self.__handle.OnItemMouseWheel = function()
		local __dist = Station.GetMessageWheelDelta()
		self.__scroll:ScrollNext(__dist)
		return true
	end
	self.__scroll.OnScrollBarPosChanged = function()
		local __value = this:GetScrollPos()
		if __value == 0 then
			self.__up:Enable(false)
		else
			self.__up:Enable(true)
		end
		if __value == this:GetStepCount() then
			self.__down:Enable(false)
		else
			self.__down:Enable(true)
		end
		self.__handle:SetItemStartRelPos(0, -__value * 10)
	end
end

function WndScroll:SetScrollVerStepSzie(nStepCount)
	self.__scroll:SetScrollVerStepSzie(nStepCount)
	return self
end

function WndScroll:SetScrollHorStepSzie(nStepCount)
	self.__scroll:SetScrollHorStepSzie(nStepCount)
	return self
end

--
function WndScroll:GetHandle()
	return self.__handle
end

function WndScroll:AppendItemFromIni(...)
	local __item = self.__handle:AppendItemFromIni(...)
	return __item
end

function WndScroll:AddItem(__name)
	local __item = ScrollItems.new(self:GetHandle(), "Handle_Item", "Item_" .. __name)
	__item:Show()
	local __cover = __item:GetSelf():Lookup("Image_Cover")
	__item.OnEnter = function()
		__cover:Show()
	end
	__item.OnLeave = function()
		__cover:Hide()
	end
	return __item
end

function WndScroll:RemoveItem(...)
	self.__handle:RemoveItem(...)
	return self
end

function WndScroll:SetHandleStyle(...)
	self.__handle:SetHandleStyle(...)
	return self
end

function WndScroll:ClearHandle()
	self.__handle:Clear()
	return self
end

function WndScroll:GetItemCount()
	return self.__handle:GetItemCount()
end

function WndScroll:ScrollPagePrev()
	self.__scroll:ScrollPagePrev()
	return self
end

function WndScroll:ScrollPageNext()
	self.__scroll:ScrollPageNext()
	return self
end

function WndScroll:ScrollHome()
	self.__scroll:ScrollHome()
	return self
end

function WndScroll:ScrollEnd()
	self.__scroll:ScrollEnd()
	return self
end

function WndScroll:UpdateList()
	self.__handle:FormatAllItemPos()
	local __w, __h = self.__handle:GetSize()
	local __wAll, __hAll = self.__handle:GetAllItemSize()
	local __count = math.ceil((__hAll - __h) / 10)

	self.__scroll:SetStepCount(__count)
	if __count > 0 then
		self.__scroll:Show()
		self.__up:Show()
		self.__down:Show()
	else
		self.__scroll:Hide()
		self.__up:Hide()
		self.__down:Hide()
	end
end

function WndScroll:SetSize(__w, __h)
	self.__this:SetSize(__w, __h)
	self.__handle:SetSize(__w, __h)
	self.__scroll:SetSize(15, __h - 40)
	self.__scroll:SetRelPos(__w - 17, 20)
	self.__up:SetRelPos(__w - 20, 3)
	self.__down:SetRelPos(__w - 20, __h - 20)
	return self
end

----------------------------------------------
-- WndContainerScroll
----------------------------------------------
local WndContainerScroll = WndWindow:new()
function WndContainerScroll:Init(parent, name, data)
	assert(parent ~= nil, "parent can not be null.")
	data = data or {}
	local hwnd = AppendWnd(parent, "WndContainerScroll", name)
	local hWndScroll = hwnd:Lookup("WndScroll")
	local WndContainer = hWndScroll:Lookup("_WndContainer")
	local Scroll_List = hwnd:Lookup("New_ScrollBar")
	self.__this = hwnd
	self.__WndContainer = _WndContainer
	self.__hwnd = hwnd
	self.__hWndScroll = hWndScroll
	self.__up = hWndScroll:Lookup("Btn_Up")
	self.__down = hWndScroll:Lookup("Btn_Down")
	self.__scroll = hWndScroll:Lookup("New_ScrollBar")
	self.__handle = hWndScroll:Lookup("", "")
	self:__SetSelf(self.__this)
	self:__SetParent(parent)
	self:__SetType("WndContainerScroll")

	self:SetSize(data.w or 500, data.h or 345)
	self:SetRelPos(data.x or 0, data.y or 0)
end

function WndContainerScroll:GetSelf()
	return self.__WndContainer
end

function WndContainerScroll:SetSize(__w, __h)
	self.__this:SetSize(__w, __h)
	self.__hwnd:SetSize(__w, __h)
	self.__hWndScroll:SetSize(__w, __h)
	self.__handle:SetSize(__w, __h)
	self.__scroll:SetSize(15, __h - 40)
	self.__WndContainer:SetSize(__w, __h)
	self.__scroll:SetRelPos(__w - 17, 20)
	self.__up:SetRelPos(__w - 20, 3)
	self.__down:SetRelPos(__w - 20, __h - 20)
	return self
end

function WndContainerScroll:GetHandle()
	return self.__this
end

function WndContainerScroll:Clear()
	self.__WndContainer:Clear()
	return self.__WndContainer
end

function WndContainerScroll:ClearHandle()
	self.__WndContainer:Clear()
	return self.__WndContainer
end

function WndContainerScroll:GetAllContentCount()
	return self.__WndContainer:GetAllContentCount()
end

function WndContainerScroll:GetAllContentSize()
	return self.__WndContainer:GetAllContentSize()
end

function WndContainerScroll:FormatAllContentPos()
	self.__WndContainer:FormatAllContentPos()
end





