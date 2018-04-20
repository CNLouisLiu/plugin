local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
-------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics"
local _L = LR.LoadLangPack(AddonPath)
-------------------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("LR_AS") then
	tinsert (LR_TOOLS.tAddonClass, {"LR_AS", _L["LR_AS"], "2"})
end

local LR_AccountStatistics_UI = {
	szName = "LR_AccountStatistics",
	szTitle = _L["LR_Equipment_Record"],
	dwIcon = 1050,
	szClass = "LR_AS",
	tWidget = {
		{name = "LR_Equip_Record_CheckBox_01", type = "CheckBox", text = _L["Display button on CharacterPanel."], x = 0, y = 0, w = 200,
			default = function ()
 				return LR_AS_Equip.UsrData.bShowButtonInCharacterPanel
			end,
			callback = function (enabled)
				LR_AS_Equip.UsrData.bShowButtonInCharacterPanel = enabled
				LR_AS_Equip.Hook()
			end,
		},{name = "LR_Equip_Record_CheckBox_02", type = "CheckBox", text = _L["Save data when change equipment."], x = 0, y = 30, w = 200,
			default = function ()
 				return LR_AS_Equip.UsrData.bAutoSaveWhenChangeEquipment
			end,
			callback = function (enabled)
				LR_AS_Equip.UsrData.bAutoSaveWhenChangeEquipment = enabled
			end,
		},{	name = "LR_Equip_Record_Button_01", type = "Button", x = 0, y = 60, text = _L["LR Equipment Statistics"], w = 150, h = 40,
			callback = function()
				LR_AS_Equip_Panel:Open()
			end,
		},
	}
}

LR_TOOLS:RegisterPanel(LR_AccountStatistics_UI)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
tinsert(LR_AS_MENU, {
	szOption = _L["Open [LR_Equipment_Record] panel"],
	fnAction = function()
		LR_AS_Equip_Panel:Open()
	end,
})

-----------------------------
---¿ì½Ý¼ü
-----------------------------
LR.AddHotKey(_L["Open [LR_Equipment_Record] panel"], function() LR_AS_Equip_Panel:Open() end)
