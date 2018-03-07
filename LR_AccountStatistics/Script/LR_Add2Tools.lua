local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics"
local _L = LR.LoadLangPack(AddonPath)
local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
-------------------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("LR_AS") then
	tinsert (LR_TOOLS.tAddonClass, {"LR_AS", _L["LR_AS"], "2"})
end

local RI_CHANG = LR_AccountStatistics_RiChang.RI_CHANG
local RI_CHANG_NAME = LR_AccountStatistics_RiChang.RI_CHANG_NAME

LR_AccountStatistics_FBList = LR_AccountStatistics_FBList or {}

function LR_AccountStatistics_FBList.CheckMapbShow(bCheckTable, bCheckMapID)
	for i = 1, #bCheckTable, 1 do
		if bCheckTable[i].dwMapID == bCheckMapID then
			return true
		end
	end
	return false
end

function LR_AccountStatistics_FBList.GetMapbShowID (bCheckTable, bCheckMapID)
	for i = 1, #bCheckTable, 1 do
		if bCheckTable[i].dwMapID == bCheckMapID then
			return i
		end
	end
	return 0
end

function LR_AccountStatistics_FBList.SortMapbShow ()
	local m = {}
	for i = 1, #LR_AccountStatistics_FBList.FB25R, 1 do
		if LR_AccountStatistics_FBList.CheckMapbShow(LR_AccountStatistics_FBList.UsrData.bShowMapID, LR_AccountStatistics_FBList.FB25R[i].dwMapID) then
			tinsert (m, {dwMapID = LR_AccountStatistics_FBList.FB25R[i].dwMapID})
		end
	end
	for i = 1, #LR_AccountStatistics_FBList.FB10R, 1 do
		if LR_AccountStatistics_FBList.CheckMapbShow(LR_AccountStatistics_FBList.UsrData.bShowMapID, LR_AccountStatistics_FBList.FB10R[i].dwMapID) then
			tinsert (m, {dwMapID = LR_AccountStatistics_FBList.FB10R[i].dwMapID})
		end
	end
	LR_AccountStatistics_FBList.UsrData.bShowMapID = clone (m)
end

local function _CheckRCData(szName)
	local RI_CHANG = RI_CHANG
	if LR_AccountStatistics_RiChang.UsrData.List[RI_CHANG[szName]] then
		return false
	end
	local n = 0
	for k, v in pairs(LR_AccountStatistics_RiChang.UsrData.List) do
		if v then
			n = n + 1
		end
		if n >= 8 then
			return true
		end
	end
	for k, v in pairs(LR_AccountStatistics_RiChang.CustomQuestList or {}) do
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

local function _CheckQiYuData(szName)
	local QiYu = LR_ACS_QiYu.QiYu
	local QiYuName = LR_ACS_QiYu.QiYuName
	local Data = LR_ACS_QiYu.UsrData.List
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

local LR_AccountStatistics_UI = {
	szName = "LR_AccountStatistics",
	szTitle = _L["LR_AS_Global_Settings"],
	dwIcon = 244,
	szClass = "LR_AS",
	tWidget = {
		{name = "LR_Acc_UI_CheckBox1", type = "CheckBox", text = _L["Allow others to see this character's record"], x = 0, y = 0, w = 200,
			default = function ()
 				return LR_AS_Base.UsrData.OthersCanSee
			end,
			callback = function (enabled)
				LR_AS_Base.UsrData.OthersCanSee = enabled
				local frame = Station.Lookup("Normal/LR_AccountStatistics")
				if frame then
					LR_AS_Info.ReFreshTitle()
					LR_AS_Info.ListAS()

					LR_AccountStatistics_FBList.ReFreshTitle()
					LR_AccountStatistics_FBList.ListFB()

					LR_AccountStatistics_RiChang.ReFreshTitle()
					LR_AccountStatistics_RiChang.ListRC()

					LR_ACS_QiYu.ReFreshTitle()
					LR_ACS_QiYu.ListQY()
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
				return LR_AS_Base.UsrData.OthersCanSee
			end,
			default = function ()
 				return LR_AS_Base.UsrData.AutoSave
			end,
			callback = function (enabled)
				LR_AS_Base.UsrData.AutoSave = enabled
			end,
			Tip = function()
				local szXml = {}
				szXml[#szXml + 1] = {szText = _L["When will auto save:\n"],}
				szXml[#szXml + 1] = {szText = _L["1.Login in\n"],}
				szXml[#szXml + 1] = {szText = _L["2.Open LR AccountStatistics panel\n"],}
				szXml[#szXml + 1] = {szText = _L["3.Quit game"],}
				return szXml
			end,
		},{name="LR_Acc_UI_FP",type="CheckBox",text=_L["Enable floating bar"],x = 100 , y = 30, w = 200,
			default = function ()
 				return LR_AS_Base.UsrData.FloatPanel
			end,
			callback = function (enabled)
				LR_AS_Base.UsrData.FloatPanel=enabled
				if LR_AS_Base.UsrData.FloatPanel then
					Wnd.OpenWindow("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics_FP.ini", "LR_AccountStatistics_FP")
				else
					Wnd.CloseWindow("LR_AccountStatistics_FP")
				end
			end,
			Tip = function()
				local szTip = {}
				szTip[#szTip+1] = {szText = _L["Floating bar Instructions:\n"], font = 17, r = 255, g = 127, b = 39,}
				szTip[#szTip+1] = {szText = _L["Floating bar Instructions01\n"], font = 5, r = 255, g = 255, b = 255,}
				szTip[#szTip+1] = {szText = _L["Floating bar Instructions02\n"], font = 5, r = 255, g = 255, b = 255,}
				szTip[#szTip+1] = {szText = _L["Floating bar Instructions03\n"], font = 5, r = 255, g = 255, b = 255,}
				return szTip
			end,
		},
		{name="LR_Acc_UI_CheckBox003",type="CheckBox",text=_L["Show button on mail panel"],x = 220 , y = 30, w = 200,
			default = function ()
 				return LR_AccountStatistics_Bag.bHookMailPanel
			end,
			callback = function (enabled)
				LR_AccountStatistics_Bag.bHookMailPanel = enabled
				LR_AccountStatistics_Bag.HookMailPanel()
			end,
		},
		{	name = "LR_Acc_UI_an4", type = "Button", x = 0, y = 70, text = _L["Open [LR_AccountStatistics] panel"], w = 200, h = 40,
			callback = function()
				LR_AccountStatistics.OpenPanel(true)
			end,
		},{	name = "LR_Acc_UI_an6", type = "Button", x = 0, y = 110, text = _L["View mails overdue."], w = 200, h = 40, font = 16,
			callback = function()
				LR_AccountStatistics_Bag_Panel:Open("ALL", "ALL", -1, true)
			end,
		},{	name = "LR_Acc_UI_an7", type = "Button", x = 0, y = 150, text = _L["View trade record."], w = 200, h = 40,
			callback = function()
				LR_Acc_Trade_Panel:Open()
			end,
		},{	name = "LR_Acc_UI_an5", type = "Button", x = 0, y = 200, text = _L["Reset settings"], w = 150, h = 40,
			callback = function()
				LR_AS_Base.UsrData = clone(LR_AS_Base.default.UsrData)
				LR_AccountStatistics_FBList.ResetData()
				LR_AccountStatistics_RiChang.ResetMenuList()
				LR_TOOLS:OpenPanel(_L["LR_AccountStatistics"])
			end,
		},{ name = "LR_Acc_UI_text4", type = "Text", x = 0, y = 250, w = 500, h = 28, text = _L["Warning 2"], font = 16, IsMultiLine = true,
		},{ name = "LR_Acc_UI_text3", type = "Text", x = 50, y = 320, w = 80, h = 28, text = _L["Warning used in Internet cafes"], font = 20,
		},
	}
}

local LR_AS_Normal_Settings = {
	szName = "LR_AS_Normal_Settings",
	szTitle = _L["LR_AS_Normal_Settings"],
	dwIcon = 299,
	szClass = "LR_AS",
	tWidget = {
		{	name = "TXT_LR_AS_FB", type = "Text", x = 0, y = 0, w = 80, h = 30, text = _L["FB Settings"], font = 31
		},{	name = "FAQ_AS_FB", type = "FAQ", x = 110, y = 0 ,
			Tip = function()
				local szTip = {}
				szTip[#szTip + 1] = {szText = sformat(_L["Choose %d at most"], 6),}
				return szTip
			end,
		},{	name = "LR_Acc_UI_ComboBox1", type = "ComboBox", x = 0, y = 25, w = 220, text = _L["FB show in panel"],
			callback = function(m)
				local szOption = {_L["25FB"], _L["10FB"], _L["5FB"]}
				local FBList = {LR_AccountStatistics_FBList.FB25R, LR_AccountStatistics_FBList.FB10R, LR_AccountStatistics_FBList.FB5R}
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
								return LR_AccountStatistics_FBList.CheckMapbShow(LR_AccountStatistics_FBList.UsrData.bShowMapID, v2.dwMapID)
							end,
							fnDisable = function ()
								if LR_AccountStatistics_FBList.CheckMapbShow(LR_AccountStatistics_FBList.UsrData.bShowMapID, v2.dwMapID) then
									return false
								end
								if #LR_AccountStatistics_FBList.UsrData.bShowMapID >= 6 then
									return true
								end
							end,
							fnAction = function ()
								if LR_AccountStatistics_FBList.CheckMapbShow(LR_AccountStatistics_FBList.UsrData.bShowMapID, v2.dwMapID) then
									local Map_ID = LR_AccountStatistics_FBList.GetMapbShowID (LR_AccountStatistics_FBList.UsrData.bShowMapID, v2.dwMapID)
									tremove (LR_AccountStatistics_FBList.UsrData.bShowMapID, Map_ID)
									LR_AccountStatistics_FBList.SaveCommonSetting ()
								else
									tinsert (LR_AccountStatistics_FBList.UsrData.bShowMapID, {dwMapID = v2.dwMapID})
									LR_AccountStatistics_FBList.SortMapbShow ()
									LR_AccountStatistics_FBList.SaveCommonSetting ()
								end
								LR_AccountStatistics_FBList.ReFreshTitle()
								LR_AccountStatistics_FBList.ListFB()
							end,
							fnMouseEnter = function()
								local szTip = {}
								szTip[#szTip+1] = GetFormatText(sformat("%s\n", Table_GetMapName(v2.dwMapID)), 8)
								szTip[#szTip+1] = GetFormatText(sformat("%s\n", _L["Boss List"]), 2)
								local bossList = LR.MapType[v2.dwMapID].bossList
								local boss = string.split(bossList, ",")
								for k, v in pairs (boss) do
									szTip[#szTip+1] = GetFormatText(sformat("%d）%s\n", k, v), 2)
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
		},{name = "LR_Acc_UI_FBCom", type = "CheckBox", text = _L["Use common FB settings"], x = 220, y = 25, w = 200,
			default = function ()
 				return LR_AccountStatistics_FBList.UsrData.CommonSetting
			end,
			callback = function (enabled)
				LR_AccountStatistics_FBList.UsrData.CommonSetting = enabled
				if LR_AccountStatistics_FBList.UsrData.CommonSetting then
					LR_AccountStatistics_FBList.LoadCommonSetting ()
					LR_AccountStatistics_FBList.ReFreshTitle()
					LR_AccountStatistics_FBList.ListFB()
				end
			end,
		},{	name = "TXT_LR_AS_RC", type = "Text", x = 0, y = 70, w = 80, h = 30, text = _L["RC Settings"], font = 31
		},{	name = "FAQ_AS_RC", type = "FAQ", x = 110, y = 70 ,
			Tip = function()
				local szTip = {}
				szTip[#szTip + 1] = {szText = sformat(_L["Choose %d at most"], 8),}
				return szTip
			end,
		},{	name = "LR_Acc_UI_RCBox1", type = "ComboBox", x = 0, y = 95, w = 220, text = _L["RC show in panel"],
			callback = function(m)
				LR_AccountStatistics_RiChang.LoadCustomQuestList()
				local szOption = {_L["PVE"],  _L["PVP"], _L["PVX"]}
				local List = {{"DA", "GONG"}, {"JU", "JING", "LONGMENJUEJING", "LUOYANGSHENBING"}, {"CHA", "QIN", "CAI", "TU", "XUN", "MI", "HUIGUANG", "HUASHAN"}}
				for k, v in pairs (szOption) do
					m[#m+1] = {szOption = v}
					local t = m[#m]
					for k2, v2 in pairs (List[k]) do
						t[#t+1] = {
							szOption = RI_CHANG_NAME[RI_CHANG[v2]], bCheck = true, bMCheck = false, bChecked = function() return LR_AccountStatistics_RiChang.UsrData.List[RI_CHANG[v2]] end,
							fnAction = function()
								LR_AccountStatistics_RiChang.UsrData.List[RI_CHANG[v2]] = not LR_AccountStatistics_RiChang.UsrData.List[RI_CHANG[v2]]
								LR_AccountStatistics_RiChang.SaveCommomMenuList()
								LR_AccountStatistics_RiChang.ReFreshTitle()
								LR_AccountStatistics_RiChang.ListRC()
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
				for k, v in pairs (LR_AccountStatistics_RiChang.CustomQuestList or {}) do
					customMenu[#customMenu + 1] = {szOption = v.szName, bCheck = true, bMCheck = false, bChecked = function() return v.bShow end,
						fnAction = function()
							v.bShow = not v.bShow
							LR_AccountStatistics_RiChang.SaveCustomQuestList()
							LR_AccountStatistics_RiChang.ReFreshTitle()
							LR_AccountStatistics_RiChang.ListRC()
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
										tremove(LR_AccountStatistics_RiChang.CustomQuestList, k)
										LR_AccountStatistics_RiChang.SaveCustomQuestList()
										LR_AccountStatistics_RiChang.ReFreshTitle()
										LR_AccountStatistics_RiChang.ListRC()
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
								{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() tinsert(LR_AccountStatistics_RiChang.CustomQuestList, data); LR_AccountStatistics_RiChang.SaveCustomQuestList() end, },
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
		},{name = "LR_Acc_UI_RCComx", type = "CheckBox", text = _L["Use common RC settings"], x = 220, y = 95, w = 200,
			default = function ()
 				return LR_AccountStatistics_RiChang.UsrData.bUseCommonData
			end,
			callback = function (enabled)
				LR_AccountStatistics_RiChang.UsrData.bUseCommonData = enabled
				if LR_AccountStatistics_RiChang.UsrData.bUseCommonData then
					LR_AccountStatistics_RiChang.LoadCommomMenuList()
					LR_AccountStatistics_RiChang.ReFreshTitle()
					LR_AccountStatistics_RiChang.ListRC()
				end
			end,
		},{	name = "TXT_LR_AS_QY", type = "Text", x = 0, y = 140, w = 80, h = 30, text = _L["QiYu Settings"], font = 31
		},{	name = "FAQ_AS_QY", type = "FAQ", x = 110, y = 140 ,
			Tip = function()
				local szTip = {}
				szTip[#szTip + 1] = {szText = sformat(_L["Choose %d at most"], 9),}
				return szTip
			end,
		},{	name = "LR_Acc_UI_QiYuBox1", type = "ComboBox", x = 0, y = 165, w = 220, text = _L["QiYu show in panel"],
			callback = function(m)
				local QiYu = LR_ACS_QiYu.QiYu
				local QiYuName = LR_ACS_QiYu.QiYuName
				for k, v in pairs(QiYu) do
					m[#m+1] = {szOption = QiYuName[v], bCheck = true, bMCheck = false, bChecked = function() return LR_ACS_QiYu.UsrData.List[QiYuName[v]] end,
						fnAction = function()
							LR_ACS_QiYu.UsrData.List[QiYuName[v]] = not LR_ACS_QiYu.UsrData.List[QiYuName[v]]
							LR_ACS_QiYu.SaveCommomUsrData()
							LR_ACS_QiYu.ReFreshTitle()
							LR_ACS_QiYu.ListQY()
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
		},{	name = "LR_Acc_UI_QiYuComx", type = "CheckBox", text = _L["Use common QiYu settings"], x = 220, y = 165, w = 200,
			default = function ()
 				return LR_ACS_QiYu.UsrData.bUseCommonData
			end,
			callback = function (enabled)
				LR_ACS_QiYu.UsrData.bUseCommonData = enabled
				if LR_ACS_QiYu.UsrData.bUseCommonData then
					LR_ACS_QiYu.LoadCommomUsrData()
					LR_ACS_QiYu.ReFreshTitle()
					LR_ACS_QiYu.ListQY()
				end
			end,
		},{	name = "TXT_LR_AS_Mail", type = "Text", x = 0, y = 210, w = 80, h = 30, text = _L["Mail Settings"], font = 31
		},{	name = "LR_Acc_UI_mailRemind", type = "ComboBox", x = 0, y = 235, w = 220, text = _L["Mail remind settings"],
			callback = function(m)
				local menu1 = {szOption = _L["Enable Remind"], bCheck = true, bMCheck = false, bChecked = function() return LR_AccountStatistics_Mail.UsrData.remind end, fnAction = function() LR_AccountStatistics_Mail.UsrData.remind = not LR_AccountStatistics_Mail.UsrData.remind end, }
				local menu2 = {szOption = _L["Enable at Maturity"], bCheck = true, bMCheck = false, bChecked = function() return LR_AccountStatistics_Mail.UsrData.atMaturity end, fnAction = function() LR_AccountStatistics_Mail.UsrData.atMaturity = not LR_AccountStatistics_Mail.UsrData.atMaturity end, }
				for i = 5, 30, 5 do
					tinsert(menu1, {szOption = sformat("%d%s", i, _L["day"]), bCheck = true, bMCheck = true, bChecked = function() return LR_AccountStatistics_Mail.UsrData.remindDay == i end, fnAction = function() LR_AccountStatistics_Mail.UsrData.remindDay = i end, fnDisable = function() return not LR_AccountStatistics_Mail.UsrData.remind end})
				end
				for i = 1, 10, 1 do
					tinsert(menu2, {szOption = sformat("%d%s", i, _L["day"]), bCheck = true, bMCheck = true, bChecked = function() return LR_AccountStatistics_Mail.UsrData.atMaturityDay == i end, fnAction = function() LR_AccountStatistics_Mail.UsrData.atMaturityDay = i end, fnDisable = function() return not LR_AccountStatistics_Mail.UsrData.atMaturity end})
				end
				tinsert(m, menu1)
				tinsert(m, menu2)
				PopupMenu(m)
			end,
		},
	},
}

local LR_AS_DB_Settings = {
	szName = "LR_AS_DB_Settings",
	szTitle = _L["LR_AS_DB_Settings"],
	dwIcon = 6633,
	szClass = "LR_AS",
	tWidget = {
		{	name = "TXT_LR_DB_Main", type = "Text", x = 0, y = 0, w = 80, h = 30, text = _L["Main DB Settings"], font = 31
		},{	name = "FAQ_DB_Main", type = "FAQ", x = 75, y = 0 ,
			Tip = function()
				local szTip = {}
				szTip[#szTip + 1] = {szText = _L["Main DB Tip 1"],}
				szTip[#szTip + 1] = {szText = _L["Main DB Tip 2"],}
				szTip[#szTip + 1] = {szText = _L["Main DB Tip 3"],}
				return szTip
			end,
		},{	name = "LR_Acc_DB_Vacuum", type = "Button", x = 0, y = 25, text = _L["DB Vacuum"], w = 100, h = 40,
			callback = function()
				LR_AS_DB.MainDBVacuum()
			end,
		},{	name = "LR_Acc_DB_backup", type = "Button", x = 120, y = 25, text = _L["DB Backup"], w = 100, h = 40,
			callback = function()
				local msg = {
					szMessage = _L["Please backup manually."],
					szName = "vacuum database",
					fnAutoClose = function() return false end,
					{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()  end, },
					{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
				}
				MessageBox(msg)
			end,
		},{	name = "LR_Acc_DB_Im_player", type = "Button", x = 240, y = 25, text = _L["DB Import playerlist"], w = 140, h = 40,
			callback = function()
				LR_AS_DB.ImportPlayerListOld()
			end,
		},{	name = "TXT_LR_DB_TRADE", type = "Text", x = 0, y = 70, w = 80, h = 30, text = _L["TRADE DB Settings"], font = 31
		},{	name = "FAQ_DB_TRADE", type = "FAQ", x = 120, y = 70 ,
			Tip = function()
				local szTip = {}
				szTip[#szTip + 1] = {szText = _L["Trade DB Tip 1"],}
				szTip[#szTip + 1] = {szText = _L["Trade DB Tip 2"],}
				szTip[#szTip + 1] = {szText = _L["Trade DB Tip 3"],}
				return szTip
			end,
		},{	name = "LR_Acc_TRADE_DB_Vacuum", type = "Button", x = 0, y = 95, text = _L["DB Vacuum"], w = 100, h = 40,
			callback = function()
				LR_Acc_Trade.VacuumData()
			end,
		},{	name = "LR_Acc_TRADE_DB_backup", type = "Button", x = 120, y = 95, text = _L["DB Backup"], w = 100, h = 40,
			callback = function()
				local msg = {
					szMessage = _L["Please backup manually."],
					szName = "vacuum database",
					fnAutoClose = function() return false end,
					{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()  end, },
					{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
				}
				MessageBox(msg)
			end,
		},{	name = "LR_Acc_TRADE_DB_BI", type = "Button", x = 240, y = 95, text = _L["TRADE DB Batch Import"], w = 140, h = 40,
			callback = function()
				LR_Acc_Trade.BatchImportOldData()
			end,
		},
	},
}

local LR_AS_Desc= {
	szName = "LR_AS_Desc",
	szTitle = _L["LR_AS_Desc"],
	dwIcon = 310,
	szClass = "LR_AS",
	tWidget = {
		{	name = "LR_AS_Desc_Scroll", type = "Scroll_Text", x = 0, y = 0, w = 540, h = 360,
			Text = {
				{szText = _L["TIP1\n"], font = 5 },
				{szText = _L["TIP2\n"], font = 5 },
				{szText = _L["TIP3\n"], font = 5 },
				{szText = _L["TIP4\n"], font = 5 },
				{szText = _L["TIP5\n"], font = 5 },
				{szText = _L["TIP6\n"], font = 5 },
				{szText = _L["TIP7\n"], font = 5 },
				{szText = _L["TIP8\n"], font = 5 },
				{szText = _L["TIP9\n"], font = 5 },
				{szText = sformat("10.%s", _L["DB_TIP_1"]), font = 5 },
				{szText = sformat("11.%s", _L["DB_TIP_2"]), font = 5 },
				{szText = sformat("12.%s", _L["TRADE_FAQ_1"]), font = 5 },
				{szText = sformat("13.%s", _L["TRADE_FAQ_2"]), font = 5 },
				{szText = sformat("14.%s", _L["TRADE_FAQ_3"]), font = 5 },
				{szText = sformat("15.%s", _L["TRADE_FAQ_4"]), font = 5 },
				{szText = sformat("16.%s", _L["TRADE_FAQ_5"]), font = 5 },
				{szText = sformat("17.%s", _L["Warning 2"]), font = 5 },
			},
		},
	},
}


LR_TOOLS:RegisterPanel(LR_AccountStatistics_UI)
LR_TOOLS:RegisterPanel(LR_AS_Normal_Settings)
LR_TOOLS:RegisterPanel(LR_AS_DB_Settings)
LR_TOOLS:RegisterPanel(LR_AS_Desc)
-----------------------------------
----注册头像、扳手菜单
-----------------------------------
LR_TOOLS.menu = LR_TOOLS.menu or {}
LR_AccountStatistics_UI.menu = {
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
	{
	szOption = _L["Enable floating bar"],
	bCheck = true,
	bMCheck = false,
	bChecked = function ()
		return LR_AS_Base.UsrData.FloatPanel
	end,
	fnAction = function ()
		LR_AS_Base.UsrData.FloatPanel = not LR_AS_Base.UsrData.FloatPanel
		if LR_AS_Base.UsrData.FloatPanel then
			Wnd.OpenWindow("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics_FP.ini", "LR_AccountStatistics_FP")
		else
			Wnd.CloseWindow("LR_AccountStatistics_FP")
		end
	end
	}, {
		szOption = _L["Allow others to see this character's record"],
		bCheck = true,
		bMCheck = false,
		bChecked = function ()
			return LR_AS_Base.UsrData.OthersCanSee
		end,
		fnAction = function ()
			LR_AS_Base.UsrData.OthersCanSee = not LR_AS_Base.UsrData.OthersCanSee
		end
	}, {bDevide = true}, {
		szOption = _L["Open [LR_AccountStatistics] panel"],
		fnAction = function ()
			Wnd.ToggleWindow("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics.ini", "LR_AccountStatistics")
		end
	}, {
		szOption = _L["Open [LR_Item_Statistics] panel"],
		fnAction = function ()
			local frame = Station.Lookup("Normal/LR_AccountStatistics_Bag_Panel")
			if not frame then
				LR_AccountStatistics_Bag_Panel:Open()
			else
				local ServerInfo = {GetUserServer()}
				local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
				local szName = GetClientPlayer().szName
				LR_AccountStatistics_Bag_Panel:ReloadItemBox(realArea, realServer, szName)
			end
		end
	}, {szOption = _L["Open [LR_FB_Detail] panel"],
		fnAction = function ()
			local frame = Station.Lookup("Normal/LR_Acc_FB_Detail_Panel")
			if not frame then
				LR_Acc_FB_Detail_Panel:Open()
			else
				local ServerInfo = {GetUserServer()}
				local realArea, realServer = ServerInfo[5], ServerInfo[6]
				local szName = GetClientPlayer().szName
				LR_Acc_FB_Detail_Panel:ReloadItemBox(realArea, realServer, szName)
			end
		end
	}, {	szOption = _L["Open [LR_Reading_Record] panel"],
		fnAction = function ()
			LR_BookRd_Panel:Open()
		end
	}, {	szOption = _L["Open [LR_Trade_Record] panel"],
		fnAction = function ()
			LR_Acc_Trade_Panel:Open()
		end
	}, {szOption = _L["Open [LR_QiYu_Detail] panel"],
		fnAction = function ()
			local frame = Station.Lookup("Normal/LR_ACS_QiYu_Panel")
			if not frame then
				LR_ACS_QiYu_Panel:Open()
			else
				local ServerInfo = {GetUserServer()}
				local realArea, realServer = ServerInfo[5], ServerInfo[6]
				local szName = GetClientPlayer().szName
				LR_Acc_FB_Detail_Panel:ReloadItemBox(realArea, realServer, szName)
			end
		end
	}, {szOption = _L["Open [LR_Achievement] panel"],
		fnAction = function ()
			LR_Acc_Achievement_Panel:Open()
		end
	},
}
--tinsert(LR_AccountStatistics_UI.menu, LR_AccountStatistics_UI.secondmenu1)
--tinsert(LR_AccountStatistics_UI.menu, LR_AccountStatistics_UI.secondmenu2)

tinsert(LR_TOOLS.menu, LR_AccountStatistics_UI.menu)

-----------------------------
---快捷键
-----------------------------
LR.AddHotKey(_L["LR_AccountStatistics"], 	function() LR_AccountStatistics.OpenPanel() end)
LR.AddHotKey(_L["LR_Item_Statistics"], 		function() LR_AccountStatistics_Bag_Panel:Open() end)
LR.AddHotKey(_L["LR FB Details"], 				function() LR_Acc_FB_Detail_Panel:Open() end)
LR.AddHotKey(_L["Reading Statistics"], 		function() LR_BookRd_Panel:Open() end)
LR.AddHotKey(_L["LR Equipment Statistics"], function() LR_AS_Equip_Panel:Open() end)
LR.AddHotKey(_L["LR_TRADE_RECORD"], 		function() LR_Acc_Trade_Panel:Open() end)
LR.AddHotKey(_L["LR QiYu Details"], 			function() LR_ACS_QiYu_Panel:Open() end)



