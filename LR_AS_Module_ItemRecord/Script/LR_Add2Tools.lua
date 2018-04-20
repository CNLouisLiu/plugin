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
	szTitle = _L["Item Statistics"],
	dwIcon = 246,
	szClass = "LR_AS",
	tWidget = {
		{name = "ItemRecord_CheckBox_01", type = "CheckBox", text = _L["Display button on BigBagPanel."], x = 0, y = 0, w = 200,
			default = function ()
 				return LR_AS_ItemRecord.UsrData.bShowButtonInBagPanel
			end,
			callback = function (enabled)
				LR_AS_ItemRecord.UsrData.bShowButtonInBagPanel = enabled
				LR_AS_ItemRecord.HookBag()
			end,
		},{name = "ItemRecord_CheckBox_02", type = "CheckBox", text = _L["Display button on MailPanel."], x = 0, y = 30, w = 200,
			default = function ()
 				return LR_AS_ItemRecord.UsrData.bShowButtonInMailPanel
			end,
			callback = function (enabled)
				LR_AS_ItemRecord.UsrData.bShowButtonInMailPanel = enabled
				LR_AS_ItemRecord.HookMailPanel()
			end,
		},{	name = "LR_Acc_UI_mailRemind", type = "ComboBox", x = 0, y = 60, w = 220, text = _L["Mail remind settings"],
			callback = function(m)
				local menu1 = {szOption = _L["Enable Remind"], bCheck = true, bMCheck = false, bChecked = function() return LR_AS_Mail.UsrData.remind end, fnAction = function() LR_AS_Mail.UsrData.remind = not LR_AS_Mail.UsrData.remind end, }
				local menu2 = {szOption = _L["Enable at Maturity"], bCheck = true, bMCheck = false, bChecked = function() return LR_AS_Mail.UsrData.atMaturity end, fnAction = function() LR_AS_Mail.UsrData.atMaturity = not LR_AS_Mail.UsrData.atMaturity end, }
				for i = 5, 30, 5 do
					tinsert(menu1, {szOption = sformat("%d%s", i, _L["day"]), bCheck = true, bMCheck = true, bChecked = function() return LR_AS_Mail.UsrData.remindDay == i end, fnAction = function() LR_AS_Mail.UsrData.remindDay = i end, fnDisable = function() return not LR_AS_Mail.UsrData.remind end})
				end
				for i = 1, 10, 1 do
					tinsert(menu2, {szOption = sformat("%d%s", i, _L["day"]), bCheck = true, bMCheck = true, bChecked = function() return LR_AS_Mail.UsrData.atMaturityDay == i end, fnAction = function() LR_AS_Mail.UsrData.atMaturityDay = i end, fnDisable = function() return not LR_AS_Mail.UsrData.atMaturity end})
				end
				tinsert(m, menu1)
				tinsert(m, menu2)
				PopupMenu(m)
			end,
		},{	name = "ItemRecord_Button_01", type = "Button", x = 240, y = 60, text = _L["View mails overdue."], w = 200, h = 40, font = 16,
			callback = function()
				LR_AS_ItemRecord_Panel:Open("ALL", "ALL", -1, true)
			end,
		},{	name = "ItemRecord_Button_02", type = "Button", x = 0, y = 120, text = _L["Open [LR_Item_Statistics] panel"], w = 220, h = 40,
			callback = function()
				LR_AS_ItemRecord_Panel:Open()
			end,
		},
	}
}

LR_TOOLS:RegisterPanel(LR_AccountStatistics_UI)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
tinsert(LR_AS_MENU, {
	szOption = _L["Open [LR_Item_Statistics] panel"],
	fnAction = function()
		LR_AS_ItemRecord_Panel:Open()
	end,
})

-----------------------------
---¿ì½Ý¼ü
-----------------------------
LR.AddHotKey(_L["Open [LR_Item_Statistics] panel"], function() LR_AS_ItemRecord_Panel:Open() end)
