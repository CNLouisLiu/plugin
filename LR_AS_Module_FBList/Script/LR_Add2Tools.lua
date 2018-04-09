local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AS_Module_FBList"
local LanguagePath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local db_name = "maindb.db"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20180403"
-------------------------------------------------------------
function _CheckMapbShow(bCheckTable, bCheckMapID)
	for i = 1, #bCheckTable, 1 do
		if bCheckTable[i].dwMapID == bCheckMapID then
			return true
		end
	end
	return false
end

function _GetMapbShowID (bCheckTable, bCheckMapID)
	for i = 1, #bCheckTable, 1 do
		if bCheckTable[i].dwMapID == bCheckMapID then
			return i
		end
	end
	return 0
end

function _SortMapbShow()
	local m = {}
	for i = 1, #LR_AS_FBList.FB25R, 1 do
		if _CheckMapbShow(LR_AS_FBList.UsrData.bShowMapID, LR_AS_FBList.FB25R[i].dwMapID) then
			tinsert (m, {dwMapID = LR_AS_FBList.FB25R[i].dwMapID})
		end
	end
	for i = 1, #LR_AS_FBList.FB10R, 1 do
		if _CheckMapbShow(LR_AS_FBList.UsrData.bShowMapID, LR_AS_FBList.FB10R[i].dwMapID) then
			tinsert (m, {dwMapID = LR_AS_FBList.FB10R[i].dwMapID})
		end
	end
	LR_AS_FBList.UsrData.bShowMapID = clone (m)
end

-----------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("LR_AS") then
	tinsert (LR_TOOLS.tAddonClass, {"LR_AS", _L["LR_AS"], "2"})
end

local LR_AccountStatistics_UI = {
	szName = "FBStatistics",
	szTitle = _L["FBStatistics"],
	dwIcon = 260,
	szClass = "LR_AS",
	tWidget = {
		{	name = "LR_AS_FB_ComboBox1", type = "ComboBox", x = 0, y = 0, w = 220, text = _L["FB show in panel"],
			callback = function(m)
				local szOption = {_L["25FB"], _L["10FB"], _L["5FB"]}
				local FBList = {LR_AS_FBList.FB25R, LR_AS_FBList.FB10R, LR_AS_FBList.FB5R}
				for k, v in pairs (szOption) do
					m[#m+1] = {szOption = v}
					local szVersionName = {}
					for k2, v2 in pairs (FBList[k]) do
						if not szVersionName[sformat("%s(%d)", LR.MapType[v2.dwMapID].szVersionName, LR.MapType[v2.dwMapID].Level)] then
							m[#m][#m[#m]+1] = {szOption = sformat("%s(%d)", LR.MapType[v2.dwMapID].szVersionName, LR.MapType[v2.dwMapID].Level)}
							szVersionName[sformat("%s(%d)", LR.MapType[v2.dwMapID].szVersionName, LR.MapType[v2.dwMapID].Level)] = m[#m][#m[#m]]
						end
						local t = szVersionName[sformat("%s(%d)", LR.MapType[v2.dwMapID].szVersionName, LR.MapType[v2.dwMapID].Level)]
						t[#t+1] = {szOption = LR.MapType[v2.dwMapID].szName,
							bCheck = true,
							bMCheck = false,
							bChecked = function ()
								return _CheckMapbShow(LR_AS_FBList.UsrData.bShowMapID, v2.dwMapID)
							end,
							fnDisable = function ()
								if _CheckMapbShow(LR_AS_FBList.UsrData.bShowMapID, v2.dwMapID) then
									return false
								end
								if #LR_AS_FBList.UsrData.bShowMapID >= 6 then
									return true
								end
							end,
							fnAction = function ()
								if _CheckMapbShow(LR_AS_FBList.UsrData.bShowMapID, v2.dwMapID) then
									local Map_ID = _GetMapbShowID(LR_AS_FBList.UsrData.bShowMapID, v2.dwMapID)
									tremove (LR_AS_FBList.UsrData.bShowMapID, Map_ID)
									LR_AS_FBList.SaveCommonSetting()
								else
									tinsert (LR_AS_FBList.UsrData.bShowMapID, {dwMapID = v2.dwMapID})
									_SortMapbShow()
									LR_AS_FBList.SaveCommonSetting()
								end
								LR_AS_Panel.RefreshUI()
							end,
							fnMouseEnter = function()
								local szTip = {}
								szTip[#szTip+1] = GetFormatText(sformat("%s\n", Table_GetMapName(v2.dwMapID)), 8)
								szTip[#szTip+1] = GetFormatText(sformat("%s\n", _L["Boss List"]), 2)
								local bossList = LR.MapType[v2.dwMapID].bossList
								local boss = string.split(bossList, ",")
								for k, v in pairs (boss) do
									szTip[#szTip+1] = GetFormatText(sformat("%d£©%s\n", k, v), 2)
								end
								szTip[#szTip+1] = GetFormatImage(LR.MapType[v2.dwMapID].path, LR.MapType[v2.dwMapID].nFrame, 150, 150)
								if IsCtrlKeyDown() then
									szTip[#szTip+1] = GetFormatText(sformat("\ndwMapID: %d\n", v2.dwMapID), 33)
								end

								local x, y = this:GetAbsPos()
								local w, h = this:GetSize()
								OutputTip(tconcat(szTip), 300, {x, y, 0, 0})
							end,
							fnMouseLeave = function()
								HideTip()
							end
						}
					end
				end
				PopupMenu(m)
			end,
			Tip = function()
				local szTip = {}
				szTip[#szTip + 1] = {szText = sformat(_L["Choose %d at most"], 6),}
				return szTip
			end,
		},{name = "LR_Acc_UI_FBCom", type = "CheckBox", text = _L["Use common FB settings"], x = 220, y = 0, w = 200,
			default = function ()
 				return LR_AS_FBList.UsrData.CommonSetting
			end,
			callback = function (enabled)
				LR_AS_FBList.UsrData.CommonSetting = enabled
				if LR_AS_FBList.UsrData.CommonSetting then
					LR_AS_Panel.RefreshUI()
				end
			end,
		},{	name = "LR_FBList_Button_01", type = "Button", x = 0, y = 60, text = _L["Show FB Details"], w = 150, h = 40,
			callback = function()
				LR_AS_FB_Detail_Panel:Open()
			end,
		},
	}
}

LR_TOOLS:RegisterPanel(LR_AccountStatistics_UI)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
tinsert(LR_AS_MENU, {
	szOption = _L["Open [LR_FB_Detail] panel"],
	fnAction = function()
		LR_AS_FB_Detail_Panel:Open()
	end,
})

