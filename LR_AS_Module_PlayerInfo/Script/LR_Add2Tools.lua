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
	szName = "LR_AS_PlayerInfo",
	szTitle = _L["AccountStatistics"],
	dwIcon = 8375,
	szClass = "LR_AS",
	tWidget = {
		{	name = "LR_AS_PlayerInfo_Button_01", type = "Button", x = 0, y = 0, text = _L["Open [LR_AccountStatistics] panel"], w = 220, h = 40,
			callback = function()
				LR_AS_Panel.OpenPanel()
			end,
		},

	},
}


LR_TOOLS:RegisterPanel(LR_AccountStatistics_UI)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------





