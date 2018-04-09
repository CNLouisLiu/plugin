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

local UI = {
	szName = "LR_AccountStatistics",
	szTitle = _L["LR_AS_Global_Settings"],
	dwIcon = 244,
	szClass = "LR_AS",
	tWidget = {
		{name = "LR_Acc_UI_CheckBox1", type = "CheckBox", text = _L["Record the current user's data."], x = 0, y = 0, w = 200,
			default = function ()
 				return LR_AS_Base.UsrData.bRecord
			end,
			callback = function (enabled)
				LR_AS_Base.UsrData.bRecord = enabled
				if enabled then
					LR_AS_Base.SaveData()
				else
					local me = GetClientPlayer()
					local ServerInfo = {GetUserServer()}
					local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
					local player = {dwID = me.dwID, realArea = realArea, realServer = realServer}
					LR_AS_Base.DelPlayer(player)
					LR.SysMsg(_L["The relevant data has been deleted from the database.\n"])
				end
			end,
			Tip = function()
				local szTip = {}
				szTip[#szTip+1] = {szText = _L["Instructions:\n"], font = 17, r = 255, g = 127, b = 39, }
				szTip[#szTip+1] = {szText = _L["Instructions01\n"], font = 5, r = 255, g = 255, b = 255, }
				return szTip
			end,
		},{	name = "FAQ_AC_UI", type = "FAQ", x = 290, y = 5 ,
			Tip = function()
				local szTip = {}
				szTip[#szTip + 1] = {szText = _L["TIP1\n"],}
				szTip[#szTip + 1] = {szText = _L["TIP2\n"],}
				szTip[#szTip + 1] = {szText = _L["TIP3\n"],}
				szTip[#szTip + 1] = {szText = _L["TIP4\n"],}
				szTip[#szTip + 1] = {szText = _L["TIP5\n"],}
				szTip[#szTip + 1] = {szText = _L["TIP6\n"],}
				szTip[#szTip + 1] = {szText = _L["TIP7\n"],}
				szTip[#szTip + 1] = {szText = _L["TIP8\n"],}
				szTip[#szTip + 1] = {szText = _L["TIP9\n"],}
				return szTip
			end,
		},{name = "LR_Acc_UI_AutoSave", type = "CheckBox", text = _L["Auto save"], x = 0, y = 30, w = 200,
			enable = function()
				return LR_AS_Base.UsrData.bRecord
			end,
			default = function ()
 				return LR_AS_Base.UsrData.bAutoSave
			end,
			callback = function (enabled)
				LR_AS_Base.UsrData.bAutoSave = enabled
			end,
		},{name = "LR_Acc_UI_EscSave", type = "CheckBox", text = _L["Save when popup system menu.(ESC)"], x = 30, y = 60, w = 200,
			enable = function()
				return LR_AS_Base.UsrData.bRecord and LR_AS_Base.UsrData.bAutoSave
			end,
			default = function ()
 				return LR_AS_Base.UsrData.bEscSave
			end,
			callback = function (enabled)
				LR_AS_Base.UsrData.bEscSave = enabled
			end,
		},{name = "LR_Acc_UI_ExitSave", type = "CheckBox", text = _L["Save when the exit interface pops up."], x = 30, y = 90, w = 200,
			enable = function()
				return LR_AS_Base.UsrData.bRecord and LR_AS_Base.UsrData.bAutoSave
			end,
			default = function ()
 				return LR_AS_Base.UsrData.bExitSave
			end,
			callback = function (enabled)
				LR_AS_Base.UsrData.bExitSave = enabled
			end,
		},{name = "LR_Acc_UI_FP", type = "CheckBox", text = _L["Enable floating bar"], x = 0, y = 120, w = 200,
			enable = function()
				return true
			end,
			default = function ()
 				return LR_AS_Base.UsrData.FloatPanel
			end,
			callback = function (enabled)
				LR_AS_Base.UsrData.FloatPanel = enabled
				LR_AS_FP.OpenPanel()
			end,
		},{	name = "LR_AS_Base_Button_01", type = "Button", x = 0, y = 180, text = _L["Open [LR_AccountStatistics] panel"], w = 200, h = 40, font = 5,
			callback = function()
				LR_AS_Panel.OpenPanel()
			end,
		},{	name = "LR_AS_Base_Button_02", type = "Button", x = 0, y = 180, text = _L["Open [LR_AccountStatistics] panel"], w = 200, h = 40, font = 5,
			callback = function()
				LR_AS_Panel.OpenPanel()
			end,
		},{ name = "LR_Acc_UI_text4", type = "Text", x = 0, y = 250, w = 500, h = 28, text = _L["Warning 2"], font = 16, IsMultiLine = true,
		},{ name = "LR_Acc_UI_text3", type = "Text", x = 50, y = 320, w = 80, h = 28, text = _L["Warning used in Internet cafes"], font = 20,
		},
	}
}
LR_TOOLS:RegisterPanel(UI)

local UI2 = {
	szName = "LR_AS_DB_Settings",
	szTitle = _L["LR_AS_DB_Settings"],
	dwIcon = 244,
	szClass = "LR_AS",
	tWidget = {
		{	name = "LR_AS_DB_Button_01", type = "Button", x = 0, y = 0, text = _L["DB Vacuum"], w = 200, h = 40, font = 5,
			callback = function()
				LR_AS_DB.MainDBVacuum(true)
			end,
		},{	name = "FAQ_DB_Main", type = "FAQ", x = 200, y = 0 ,
			Tip = function()
				local szTip = {}
				szTip[#szTip + 1] = {szText = _L["Main DB Tip 1"],}
				szTip[#szTip + 1] = {szText = _L["Main DB Tip 2"],}
				szTip[#szTip + 1] = {szText = _L["Main DB Tip 3"],}
				return szTip
			end,
		},{	name = "LR_AS_DB_Button_02", type = "Button", x = 0, y = 30, text = _L["DB Backup"], w = 200, h = 40, font = 5,
			callback = function()
				local msg = {
					szMessage = _L["Are you sure to backup database ?"],
					szName = "backup database",
					fnAutoClose = function() return false end,
					{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() LR_AS_DB.backup() end, },
					{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
				}
				MessageBox(msg)
			end,
		},{	name = "LR_AS_DB_CheckBox_01", type = "CheckBox", text = _L["Auto backup data"], x = 0, y = 60, w = 200,
			default = function ()
 				return LR_AS_Base.UsrData.bAutoBackup
			end,
			callback = function (enabled)
				LR_AS_Base.UsrData.bAutoBackup = enabled
			end,
		},{	name = "LR_AS_DB_ComboBox_01", type = "ComboBox", x = 160, y = 60, w = 220, text = _L["Backup frequency"],
			enable = function()
				return LR_AS_Base.UsrData.bAutoBackup
			end,
			callback = function(m)
				local szOption = {_L["First launch every week"], _L["First launch every day"]}
				for k, v in pairs(szOption) do
					m[#m + 1] = {szOption = v, bCheck = true, bMCheck = true, bChecked = function() return LR_AS_Base.UsrData.nAutoBackupType == k end,
						fnAction = function()
							LR_AS_Base.UsrData.nAutoBackupType = k
						end
					}
				end
				PopupMenu(m)
			end,
		},
	},
}
LR_TOOLS:RegisterPanel(UI2)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
LR_TOOLS.menu = LR_TOOLS.menu or {}
LR_AS_MENU = {
	szOption = _L["LR_AccountStatistics"],
	--rgb = {255, 255, 255},
	fnAction = function()
		LR_AccountStatistics.OpenPanel()
	end,
	bCheck = true,
	bMCheck = false,
	rgb = {255, 255, 255},
	bChecked = function()
		local Frame = Station.Lookup("Normal/LR_AccountStatistics")
		if Frame then
			return true
		else
			return false
		end
	end,
	fnAutoClose = true,
	szIcon = "ui\\Image\\UICommon\\CommonPanel2.UITex",
	nFrame = 105,
	nMouseOverFrame = 106,
	szLayer = "ICON_RIGHT",
	fnAutoClose = true,
	fnClickIcon = function ()
		LR_TOOLS:OpenPanel(_L["LR_AS_Global_Settings"])
	end,
}

tinsert(LR_TOOLS.menu, LR_AS_MENU)




