local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AS_Module_RC"
local LanguagePath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local db_name = "maindb.db"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20180403"
-------------------------------------------------------------
local RI_CHANG = LR_AS_RC.RI_CHANG
local RI_CHANG_NAME = LR_AS_RC.RI_CHANG_NAME

local function _CheckRCData(szName)
	local RI_CHANG = RI_CHANG
	if LR_AS_RC.UsrData.List[RI_CHANG[szName]] then
		return false
	end
	local n = 0
	for k, v in pairs(LR_AS_RC.UsrData.List) do
		if v then
			n = n + 1
		end
		if n >= 8 then
			return true
		end
	end
	for k, v in pairs(LR_AS_RC.CustomQuestList or {}) do
		if v.szName == szName then
			return false
		end
		if v.bShow then
			n = n + 1
		end
		if n >=8 then
			return true
		end
	end
	return false
end


LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("LR_AS") then
	tinsert (LR_TOOLS.tAddonClass, {"LR_AS", _L["LR_AS"], "2"})
end

local UI = {
	szName = "RCStatistics",
	szTitle = _L["RCStatistics"],
	dwIcon = 8329,
	szClass = "LR_AS",
	tWidget = {
		{	name = "LR_Acc_UI_RCBox1", type = "ComboBox", x = 0, y = 0, w = 220, text = _L["RC show in panel"],
			callback = function(m)
				LR_AS_RC.LoadCustomQuestList()
				local szOption = {_L["PVE"],  _L["PVP"], _L["PVX"]}
				local List = {{"DA", "GONG"}, {"JU", "JING", "LONGMENJUEJING", "LUOYANGSHENBING"}, {"CHA", "QIN", "CAI", "TU", "XUN", "MI", "HUIGUANG", "HUASHAN"}}
				for k, v in pairs (szOption) do
					m[#m+1] = {szOption = v}
					local t = m[#m]
					for k2, v2 in pairs (List[k]) do
						t[#t+1] = {
							szOption = RI_CHANG_NAME[RI_CHANG[v2]], bCheck = true, bMCheck = false, bChecked = function() return LR_AS_RC.UsrData.List[RI_CHANG[v2]] end,
							fnAction = function()
								LR_AS_RC.UsrData.List[RI_CHANG[v2]] = not LR_AS_RC.UsrData.List[RI_CHANG[v2]]
								LR_AS_RC.SaveCommomMenuList()
								LR_AS_Panel.RefreshUI()
							end,
							fnDisable = function()
								return _CheckRCData(v2)
							end,
						}
					end
				end
				-------自定义任务
				m[#m + 1] = {bDevide = true}
				m[#m + 1] = {szOption = _L["Custom quest list"]}
				local customMenu = m[#m]
				for k, v in pairs (LR_AS_RC.CustomQuestList or {}) do
					customMenu[#customMenu + 1] = {szOption = v.szName, bCheck = true, bMCheck = false, bChecked = function() return v.bShow end,
						fnAction = function()
							v.bShow = not v.bShow
							LR_AS_RC.SaveCustomQuestList()
							LR_AS_Panel.RefreshUI()
						end,
						fnDisable = function()
							return _CheckRCData(v.szName)
						end,
						fnAutoClose = true,
						szIcon = "ui\\Image\\UICommon\\CommonPanel4.UITex",
						nFrame  = 72,
						nMouseOverFrame = 72,
						szLayer = "ICON_RIGHT",
						fnAutoClose = true,
						fnClickIcon = function ()
							local msg = {
								szMessage = sformat("%s %s?", _L["Sure to delete"], v.szName),
								szName = "delete",
								fnAutoClose = function() return false end,
								{szOption = g_tStrings.STR_HOTKEY_SURE,
									fnAction = function()
										tremove(LR_AS_RC.CustomQuestList, k)
										LR_AS_RC.SaveCustomQuestList()
										LR_AS_Panel.RefreshUI()
									end,
								},
								{szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function() end, },
							}
							MessageBox(msg)
						end,
					}
				end
				customMenu[#customMenu + 1] = {bDevide = true}
				customMenu[#customMenu + 1] = {szOption = _L["Add custom quest"],
					fnAction = function()
						local dwID, szName, refresh, dwTemplateID = 0, "", "NEVER", 0
						local step_4 = function(nType)
							refresh = nType
							local QuestInfo = LR.Table_GetQuestStringInfo(dwID)
							if not QuestInfo then
								LR.SysMsg(_L["Error, no this quest.\n"])
								return
							end
							local szQuestName = QuestInfo.szName
							local data = {dwID = dwID, szName = szName, refresh = refresh, bShow = false, dwTemplateID = dwTemplateID}
							local msg = {
								szMessage = sformat("%s\n%s:%s,%s:%s %s:%s (%s)", _L["Are you sure to add?"], _L["QuestName"], szQuestName, _L["NPC dwTemplateID"], dwTemplateID, _L["Show name"], szName, _L[refresh] ),
								szName = "add",
								fnAutoClose = function() return false end,
								{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() tinsert(LR_AS_RC.CustomQuestList, data); LR_AS_RC.SaveCustomQuestList() end, },
								{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
							}
							MessageBox(msg)
						end

						local step_3 = function()
							local msg = {
								szMessage = _L["Please choose quest refresh type."],
								szName = "quest refresh type",
								fnAutoClose = function() return false end,
								{szOption = _L["NEVER"], fnAction = function() step_4("NEVER") end, },
								{szOption = _L["WEEK"], fnAction = function() step_4("WEEK") end, },
								{szOption = _L["EVERYDAY"], fnAction = function() step_4("EVERYDAY") end, },
							}
							MessageBox(msg)
						end

						local step_2 = function()
							GetUserInput(_L["Input quest show name"], function(szText)
								local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
								if szText ~= "" then
									szName = szText
									step_3()
								else
									LR.SysMsg(_L["Quest name could not be null.\n"])
								end
							end)
						end

						local step_1_5 = function()
							GetUserInput(_L["Input quest npc dwTemplateID"], function(szText)
								local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
								if type(tonumber(szText)) == "number" then
									dwTemplateID = tonumber(szText)
									LR.DelayCall(250, function() step_2() end)
								else
									LR.SysMsg(_L["Quest npc dwTemplateID must be number.\n"])
								end
							end)
						end

						local step_1 = function()
							GetUserInput(_L["Input quest id"], function(szText)
								local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
								if type(tonumber(szText)) == "number" then
									dwID = tonumber(szText)
									LR.DelayCall(250, function() step_1_5() end)
								else
									LR.SysMsg(_L["Quest id must be number.\n"])
								end
							end)
						end
						step_1()
					end,}
				PopupMenu(m)
			end,
			Tip = function()
				local szTip = {}
				szTip[#szTip + 1] = {szText = sformat(_L["Choose %d at most"], 8),}
				return szTip
			end,
		},{name = "LR_Acc_UI_RCComx", type = "CheckBox", text = _L["Use common RC settings"], x = 220, y = 0, w = 200,
			default = function ()
 				return LR_AS_RC.UsrData.bUseCommonData
			end,
			callback = function (enabled)
				LR_AS_RC.UsrData.bUseCommonData = enabled
				if LR_AS_RC.UsrData.bUseCommonData then
					LR_AS_RC.LoadCommomMenuList()
					LR_AS_Panel.RefreshUI()
				end
			end,
		},{name = "LR_Acc_UI_RCComx02", type = "CheckBox", text = _L["Instant saving when quest update"], x = 0, y = 30, w = 200,
			default = function ()
 				return LR_AS_RC.UsrData.InstantSaving
			end,
			callback = function (enabled)
				LR_AS_RC.UsrData.InstantSaving = enabled
				if LR_AS_RC.UsrData.bUseCommonData then
					LR_AS_RC.LoadCommomMenuList()
					LR_AS_Panel.RefreshUI()
				end
			end,
		},
	},
}

LR_TOOLS:RegisterPanel(UI)
-----------------------------------
----注册头像、扳手菜单
-----------------------------------





