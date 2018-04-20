local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AS_Module_CashFlowRecord"
local LanguagePath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local db_name = "maindb.db"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20180403"
---------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("LR_AS") then
	tinsert (LR_TOOLS.tAddonClass, {"LR_AS", _L["LR_AS"], "2"})
end

local UI = {
	szName = "LR_AS_Trade",
	szTitle = _L["LR_TRADE_RECORD"],
	dwIcon = 9529,
	szClass = "LR_AS",
	tWidget = {
		{	name = "LR_AS_Trade_CheckBox_01", type = "CheckBox", text = _L["Show money change when esc"], x = 0, y = 0, w = 200,
			default = function ()
 				return LR_AS_Trade.UsrData.ShowMoneyChangeLog
			end,
			callback = function (enabled)
				LR_AS_Trade.UsrData.ShowMoneyChangeLog = enabled
			end,
		},{	name = "LR_AS_Trade_Button_01", type = "Button", x = 0, y = 60, text = _L["LR_TRADE_RECORD"], w = 150, h = 40,
			callback = function()
				LR_Acc_Trade_Panel:Open()
			end,
		},
	}
}

LR_TOOLS:RegisterPanel(UI)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
tinsert(LR_AS_MENU, {
	szOption = _L["Open [LR_Trade_Record] panel"],
	fnAction = function()
		LR_Acc_Trade_Panel:Open()
	end,
})

-----------------------------
---¿ì½Ý¼ü
-----------------------------
LR.AddHotKey(_L["Open [LR_Trade_Record] panel"], function() LR_Acc_Trade_Panel:Open() end)
