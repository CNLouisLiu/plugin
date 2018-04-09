local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AS_Module_QY"
local LanguagePath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics"
local db_name = "maindb.db"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20180403"
--------------------------------------
local function _CheckQiYuData(szName)
	local QiYu = LR_AS_QY.QiYu
	local QiYuName = LR_AS_QY.QiYuName
	local Data = LR_AS_QY.UsrData.List
	if Data[szName] then
		return false
	else
		local n = 0
		for k, v in pairs(QiYu) do
			local szName = QiYuName[v]
			if Data[szName] then
				n = n+1
			end
		end
		if n<9 then
			return false
		else
			return true
		end
	end
end
-------------------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("LR_AS") then
	tinsert (LR_TOOLS.tAddonClass, {"LR_AS", _L["LR_AS"], "2"})
end

local UI = {
	szName = "QYStatistics",
	szTitle = _L["QYStatistics"],
	dwIcon = 289,
	szClass = "LR_AS",
	tWidget = {
		{	name = "LR_Acc_UI_QiYuBox1", type = "ComboBox", x = 0, y = 0, w = 220, text = _L["QiYu show in panel"],
			callback = function(m)
				local QiYu = LR_AS_QY.QiYu
				local QiYuName = LR_AS_QY.QiYuName
				for k, v in pairs(QiYu) do
					m[#m+1] = {szOption = QiYuName[v], bCheck = true, bMCheck = false, bChecked = function() return LR_AS_QY.UsrData.List[QiYuName[v]] end,
						fnAction = function()
							LR_AS_QY.UsrData.List[QiYuName[v]] = not LR_AS_QY.UsrData.List[QiYuName[v]]
							LR_AS_QY.SaveCommomUsrData()
							LR_AS_Panel.RefreshUI()
						end,
						fnDisable = function()
							return _CheckQiYuData(QiYuName[v])
						end,
					}
				end
				PopupMenu(m)
			end,
			Tip = function()
				local szTip = {}
				szTip[#szTip + 1] = {szText = sformat(_L["Choose %d at most"], 9),}
				return szTip
			end,
		},{	name = "LR_Acc_UI_QiYuComx", type = "CheckBox", text = _L["Use common QiYu settings"], x = 240, y = 0, w = 200,
			default = function ()
 				return LR_AS_QY.UsrData.bUseCommonData
			end,
			callback = function (enabled)
				LR_AS_QY.UsrData.bUseCommonData = enabled
				if LR_AS_QY.UsrData.bUseCommonData then
					LR_AS_QY.LoadCommomUsrData()
					LR_AS_Panel.RefreshUI()
				end
			end,
		},{	name = "FAQ_AS_QY", type = "FAQ", x = 410, y = 5 ,
			Tip = function()
				local szTip = {}
				szTip[#szTip + 1] = {szText = sformat(_L["Choose %d at most"], 9),}
				return szTip
			end,
		},
	},
}


LR_TOOLS:RegisterPanel(UI)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------





