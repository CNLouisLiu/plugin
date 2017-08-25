local sformat, slen, sgsub, ssub,sfind = string.format, string.len, string.gsub, string.sub, string.find
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil = math.floor, math.ceil
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
-------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_DiamondHelper"
local _L = LR.LoadLangPack(AddonPath)
--------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("SmallHelpers") then
	tinsert (LR_TOOLS.tAddonClass,{"SmallHelpers",_L["Helpers"],"3"})
end
-----------------------------------------
local LR_DiamondHelper_UI  = {
	szName = "LR_DiamondHelper_UI",
	szTitle = _L["LR DiamondHelper"] ,
	dwIcon = 2656,
	szClass = "SmallHelpers",
	tWidget = {
		{name = "LR_DiamondHelper_CheckBox01", type = "CheckBox", text = _L["Remember last recipe"], x = 0, y = 0, w = 150,
			default = function ()
				return LR_DiamondHelper.UsrData.bRememberLastRecipe
			end,
			callback = function (enabled)
				LR_DiamondHelper.UsrData.bRememberLastRecipe = enabled
			end,
		},{name = "LR_DiamondHelper_CheckBox02", type = "CheckBox", text = _L["Distinguish by bind"], x = 0, y = 30, w = 150,
			default = function ()
				return LR_DiamondHelper.UsrData.bDistinguishBind
			end,
			callback = function (enabled)
				LR_DiamondHelper.UsrData.bDistinguishBind = enabled
			end,
		},
	}
}
LR_TOOLS:RegisterPanel(LR_DiamondHelper_UI)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
LR_TOOLS.menu = LR_TOOLS.menu or {}
LR_DiamondHelper_UI.menu = {
	szOption  = _L["LR DiamondHelper"] ,
	fnAction = function()
		LR_TOOLS:OpenPanel(_L["LR DiamondHelper"])
	end,
	bCheck = true,
	bMCheck = false,
	rgb = {255, 255, 255},
	bChecked = function()
		local frame = Station.Lookup("Normal/LR_TOOLS")
		if frame then
			return true
		else
			return false
		end
	end,
	fnAutoClose = true,
	szIcon = "ui\\Image\\UICommon\\CommonPanel2.UITex",
	nFrame  = 105,
	nMouseOverFrame = 106,
	szLayer = "ICON_RIGHT",
	fnAutoClose = true,
	fnClickIcon = function ()
		LR_TOOLS:OpenPanel(_L["LR DiamondHelper"])
	end,
	rgb = {255, 255, 255},
	fnAutoClose = true,
}
tinsert(LR_TOOLS.menu, LR_DiamondHelper_UI.menu)

-----------------------------
---¿ì½Ý¼ü
-----------------------------
LR.AddHotKey(_L["LR DiamondHelper"], function() LR_TOOLS:OpenPanel(_L["LR DiamondHelper"]) end)
