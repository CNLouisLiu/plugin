local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_CopyBook"
local LanguagePath = "Interface\\LR_Plugin\\LR_CopyBook"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_CopyBook"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20180408"
-------------------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("Normal") then
	tinsert (LR_TOOLS.tAddonClass,{"Normal",_L["Plugins"],"1"})
end

local LR_CopyBook_UI = {
	szName = "LR_CopyBook_UI",
	szTitle = _L["LR Printing Machine"],
	dwIcon = 3731,
	szClass = "Normal",
	tWidget = {
		{name = "LR_CopyBook_UI_te01", type = "Text", x = 0, y = 0, w = 70, h = 28, text = _L["Suitbook Name"], font = 99,},
		{name = "LR_CopyBook_UI_edit1", type = "Edit", x = 80, y = 0, w = 200,
			default = function()
				return LR_CopyBook.UsrData.szSuiteBookName
			end,
			callback = function(value)
				local menu = LR_CopyBook.GetSearchList(LR.Trim(value), this)
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				menu.minWidh = w
				menu.x = x
				menu.y = y + h
				menu.bShowKillFocus = true
				menu.bDisableSound = true
				PopupMenu(menu)
			end,
		},
		{name = "LR_CopyBook_UI_ComboBox1", type = "ComboBox", x = 0, y = 30, w = 300, text = _L["Choose book(s) which to print"],
			callback = function(m)
				LR_CopyBook.InitCopyListMenu(m)
				PopupMenu(m)
			end,
		},
		{name = "LR_CopyBook_UI_te02", type = "Text", x = 0, y = 60, w = 80, h = 28, text = _L["Continuous print"], font=5,},
		{name = "edit_CopyBookNum", type = "Edit", x = 95, y = 60, w = 40,
			default= function()
				return LR_CopyBook.UsrData.nCopySuiteNum
			end,
			callback = function(value)
				local x = tonumber(value)
				if type(x) == "number" then
					if x > 100 then
						x = 100
						this:SetText(x)
					end
					LR_CopyBook.UsrData.nCopySuiteNum = x

					--设置面板的套数
					if LR_CopyBook_MiniPanel:Fetch("Edit_Num") and LR_CopyBook_MiniPanel:Fetch("Edit_Num"):GetText() ~= tostring(x) then
						LR_CopyBook_MiniPanel:Fetch("Edit_Num"):SetText(x)
					end
					--设置面板的材料需要
					if LR_TOOLS:Fetch("LR_CopyBook_UI_Handle003") then
						LR_CopyBook.DrawRecipeBoxes(LR_TOOLS:Fetch("LR_CopyBook_UI_Handle003"))
					end
				end
			end,
		},
		{name = "LR_CopyBook_UI_an11", type = "Button", x = 150, y = 60, text = _L["Max"], w = 50, h = 30, font = 177,
			callback = function()
				local nMax = LR_CopyBook.GetCanCopySuiteNum()
				local edit = LR_TOOLS:Fetch("edit_CopyBookNum")
				if edit then
					edit:SetText(nMax)
				end
			end,
		},
		{name = "LR_CopyBook_UI_Handle003", type = "Handle", x = 0, y = 90, w = 200, h = 400, default = LR_CopyBook.DrawRecipeBoxes},
		{name = "LR_CopyBook_UI_an3", type = "Button", x = 110, y = 170, text = _L["Begin Printing"],
			callback = function()
				LR_CopyBook.StartCopy()
			end,
		},
		{name = "LR_CopyBook_UI_an4", type = "Button", x = 210, y = 170, text = _L["Stop Printing!"],
			callback = function()
				LR_CopyBook.StopCopy()
			end,
		},
		{name = "LR_CopyBook_UI_an5", type = "Button", x = 150, y = 200, text = _L["Open mini panel"], w = 140, h = 30, font = 177,
			callback = function()
				LR_CopyBook_MiniPanel:Open()
			end,
		},
		{name = "LR_CopyBook_UI_tips1", type = "TipBox", x = 0, y = 230, w = 150, h = 28, text = _L["Tips & FAQ"],
			callback = function ()
				local x, y=this:GetAbsPos()
				local w, h = this:GetSize()
				local szXml = {}
				szXml[#szXml+1] = GetFormatText(_L["1.Suggest to copy [ShiSanGunSenJiuTangWang]\n"],136,255,128,0)
				szXml[#szXml+1] = GetFormatText(_L["2.The book which will bind after printing can not trade to others.\n"],136,255,128,0)
				OutputTip(tconcat(szXml),420,{x,y,w,h})
			end,
		},
		{name = "LR_CopyBook_UI_an9", type = "Button", x = 0, y = 260, text = _L["Source of books/Book Records"], w = 200,
			callback = function()
				if LR_BookRd_Panel then
					LR_BookRd_Panel:Open()
				else
					LR.SysMsg(sformat("%s\n", _L["Please install [LR_AccountStatistics Plugin]"]))
				end
			end,
		},
	},
}
LR_TOOLS:RegisterPanel(LR_CopyBook_UI)
-----------------------------------
----注册头像、扳手菜单
-----------------------------------
LR_TOOLS.menu=LR_TOOLS.menu or {}
LR_CopyBook_UI.menu = {
	szOption =_L["LR Printing Machine"],
	fnAction = function()
		LR_CopyBook_MiniPanel:Open()
	end,
	bCheck=true,
	bMCheck=false,
	rgb = {255, 255, 255},
	bChecked = function()
		local Frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
		if Frame then
			return true
		else
			return false
		end
	end,
	fnAutoClose=true,
	szIcon = "ui\\Image\\UICommon\\CommonPanel2.UITex",
	nFrame =105,
	nMouseOverFrame = 106,
	szLayer = "ICON_RIGHT",
	fnAutoClose=true,
	fnClickIcon = function ()
		LR_TOOLS:OpenPanel(_L["LR Printing Machine"])
	end,
	rgb = {255, 255, 255},
	fnAutoClose=true,
}
tinsert(LR_TOOLS.menu,LR_CopyBook_UI.menu)

-----------------------------
---快捷键
-----------------------------
LR.AddHotKey(_L["Mini Printing Machine"], 	function() LR_CopyBook_MiniPanel:Open() end)

