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




