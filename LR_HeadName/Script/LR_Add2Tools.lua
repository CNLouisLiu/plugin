local sformat, slen, sgsub, ssub, sfind = string.format, string.len, string.gsub, string.sub, string.find
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil = math.floor, math.ceil
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local AddonPath = "Interface\\LR_Plugin\\LR_HeadName"
local _L = LR.LoadLangPack(AddonPath)
-----------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("Normal") then
	tinsert (LR_TOOLS.tAddonClass, {"Normal", _L["Plugin"], "1"})
end


local LR_HeadName_UI
LR_HeadName_UI = {
	szName = "LR_HeadName_UI",
	szTitle = _L["LR Headname"],
	dwIcon = 6631,
	szClass = "Normal",
	tWidget = {
		{name = "LR_Head_check_box", type = "CheckBox", text = _L["Enable Headname"], x = 0, y = 0, w = 150,
			default = function ()
				return LR_HeadName.bOn
			end,
			callback = function (enabled)
				LR_HeadName.bOn = enabled
				LR_HeadName.OpenFrame()
				if LR_HeadName.bOn then
					if LR_HeadName.UsrData.bShowQMode ==  1 or LR_HeadName.UsrData.bShowQMode ==  2 then
						LR_HeadName.GetAllMissionNeed()
						LR_HeadName.Tree()
						LR_HeadName.AddAllDoodad2AllList()
					end
					LR_HeadName.ReDrawAll()
				end
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["Instructions:\n"], font = 17, r = 255, g = 127, b = 39, }
				tTips[#tTips+1] = {szText = _L["Instructions01\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["Recommended to enable Balloon at the same time.\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["Instructions03\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["Instructions04\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["Instructions05\n"], font = 5, r = 255, g = 255, b = 255, }
				return tTips
			end,
		}, {	name = "LR_Head_FontSize", type = "ComboBox", x = 150, y = 0, w = 120, text = _L["FontSize"],
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function(m)
				local player = GetClientPlayer()
				if not player then
					return
				end
				local menu  = {
					{szOption = _L["Small"], bCheck = true, bMCheck = true, bChecked = function() return LR_HeadName.UsrData.font == 17 end,
						fnAction = function()
							LR_HeadName.UsrData.font = 17
							LR_HeadName.SaveCommonSettings()
							LR_HeadName.ReDrawAll()
						end,
					},
--[[					{szOption = _L["Big"], bCheck = true, bMCheck = true, bChecked = function() return LR_HeadName.UsrData.font == 23 end,
						fnAction = function()
							LR_HeadName.UsrData.font = 23
							LR_HeadName.SaveCommonSettings()
							LR_HeadName.ReDrawAll()
						end,
					},]]
				}
				menu[#menu+1] = {bDevide = true}
				menu[#menu+1] = {szOption = _L["Scale"],
					fnMouseEnter = function()
						local tTips = {}
						tTips[#tTips+1] = GetFormatText(_L["Scale Instructions\n"], 17, 255, 127, 39)
						tTips[#tTips+1] = GetFormatText(_L["Scale Instructions01\n"], 5, 255, 255, 255)
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						OutputTip(tconcat(tTips), 300, {x, y, 0, 0})
					end,
				}
				local menu2 = menu[#menu]
				for i = 0.5, 2.1, 0.1 do
					menu2[#menu2+1] = {szOption = LR.GetFullSizeNumber(i), bCheck = true, bMCheck = true, bChecked = function() return LR_HeadName.UsrData.nFontScale ==  i end,
						fnAction = function()
							LR_HeadName.UsrData.nFontScale = i
							LR_HeadName.SaveCommonSettings()
							LR_HeadName.ReDrawAll()
						end,
					}
				end
				for i = 1, #menu do
					tinsert(m, menu[i])
				end
				PopupMenu(m)
			end,
		}, {name = "LR_Head_Line_Spacing", type = "ComboBox", x = 300, y = 0, w = 100, text = _L["Line spacing"],
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function(m)
				for i = 10, 30, 1 do
					tinsert(m, {szOption = i, bCheck = true, bMCheck = true, bChecked = function() return LR_HeadName.UsrData.Height == i end,
						fnAction = function()
							LR_HeadName.UsrData.Height = i
							LR_HeadName.SaveCommonSettings()
							LR_HeadName.ReDrawAll()
						end,
					})
				end
				PopupMenu(m)
			end,
		}, {	name = "LR_Balloon_Ballon_Enable", type = "CheckBox", text = _L["Enable Balloon"], x = 0, y = 30, w = 150,
			enable =  function ()
				return LR_HeadName.bOn
			end,
			default = function ()
				return LR_HeadName.UsrData.bShowBalloon
			end,
			callback = function (enabled)
				LR_HeadName.UsrData.bShowBalloon = enabled
				if not LR_HeadName.UsrData.bShowBalloon then
					for k, v in pairs (LR_Balloon.DialogList) do
						v:Remove()
						LR_Balloon.DialogList[k] = nil
					end
				end
				LR_HeadName.SaveCommonSettings()
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["Balloon Instructions:\n"], font = 17, r = 255, g = 127, b = 39, }
				tTips[#tTips+1] = {szText = _L["Balloon Instructions01\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["Please close the system balloon manually\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["Balloon Instructions03\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["Balloon Instructions04\n"], font = 5, r = 255, g = 255, b = 255, }
				return tTips
			end,
		}, {name = "LR_Balloon_Balloon_Settings", type = "ComboBox", x = 150, y = 30, w = 120, text = _L["Balloon Settings"],
			enable =  function ()
				return LR_HeadName.bOn and LR_HeadName.UsrData.bShowBalloon
			end,
			callback = function(m)
				m[#m+1] = {szOption = _L["Show player balloon"], bCheck = true, bMCheck = false, bChecked = function() return LR_Balloon.UsrData.bShowPlayerMsg end, fnAction = function() LR_Balloon.UsrData.bShowPlayerMsg = not LR_Balloon.UsrData.bShowPlayerMsg end, }
				m[#m+1] = {szOption = _L["Show npc balloon"], bCheck = true, bMCheck = false, bChecked = function() return LR_Balloon.UsrData.bShowNpcMsg end, fnAction = function() LR_Balloon.UsrData.bShowNpcMsg = not LR_Balloon.UsrData.bShowNpcMsg end, }
				m[#m+1] = {bDevide = true, }
				m[#m+1] = {szOption = _L["Enable shield"], bCheck = true, bMCheck = false, bChecked = function() return LR_Balloon.UsrData.bBlock end,
					fnAction = function()
						LR_Balloon.UsrData.bBlock = not LR_Balloon.UsrData.bBlock
					end, }
				m[#m+1] = {
					szOption = _L["Set lifeper text offsetY"] .. sformat(": %d", LR_HeadName.UsrData.nBallonTopOffset or 0),
					fnAction = function()
						GetUserInputNumber(LR_HeadName.UsrData.nBallonTopOffset or 0, 1000, nil, function(arg0)
							LR_HeadName.UsrData.nBallonTopOffset = arg0,
							--LR_HeadName.ReDrawAll()
							LR_HeadName.SaveCommonSettings()
						end)
					end,
				}
				m[#m+1] = {bDevide = true}
				m[#m+1] = {szOption = _L["Balloon style"], bDisable = true}
				local szOption = {_L["System type"], _L["Style 1"], _L["Style 2"], _L["Style 3"], _L["Style 4"]}
				for k, v in pairs(szOption) do
					m[#m + 1] = {szOption = v, bCheck = true, bMCheck = true, bChecked = function() return LR_HeadName.UsrData.nBallonType == k end,
						fnAction = function()
							LR_HeadName.UsrData.nBallonType = k
							LR_HeadName.SaveCommonSettings()
						end,
					}
				end
				PopupMenu(m)
			end
		}, {
			name = "LR_Balloon_BlockSettings", type = "Button", text = _L["Shield Settings"], x = 300, y = 30, w = 150,
			enable =  function ()
				return LR_HeadName.bOn and LR_HeadName.UsrData.bShowBalloon
			end,
			callback = function (enabled)
				LR_Balloon_Panel:Open()
			end
		}, {	name = "LR_Balloon_QuestFlag_Enable", type = "CheckBox", text = _L["Enable Quest Flag"], x = 0, y = 60, w = 150,
			enable =  function ()
				return LR_HeadName.bOn
			end,
			default = function ()
				return LR_HeadName.UsrData.bShowQuestFlag
			end,
			callback = function (enabled)
				LR_HeadName.UsrData.bShowQuestFlag = enabled
				LR_HeadName.Tree()
				LR_HeadName.AddAllDoodad2AllList()
				LR_HeadName.ReDrawAll()
				LR_HeadName.ReDrawAll()
				LR_HeadName.SaveCommonSettings()
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["Quest Flag Instructions:\n"], font = 17, r = 255, g = 127, b = 39, }
				tTips[#tTips+1] = {szText = _L["Quest Flag Instructions01\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["Quest Flag Instructions02\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["DES"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["Quest Can Accept:"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["Quest Can Pay:"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["Quest Target:"], font = 5, r = 255, g = 255, b = 255, }
				return tTips
			end,
		}, {name = "LR_Head_CustomQmode", type = "ComboBox", x = 150, y = 60, w = 120, text = _L["Quest Flag Settings"],
			enable =  function ()
				return LR_HeadName.bOn and LR_HeadName.UsrData.bShowQuestFlag
			end,
			callback = function(m)
				local szOption = {_L["Ahead Name(Static)"], _L["Above Name(Dynamic)"]}
				for k, v in pairs (szOption) do
					m[#m+1] = {szOption = v, bCheck = true, bMCheck = true, bChecked = function() return LR_HeadName.UsrData.bShowQMode ==  k end,
						fnAction = function()
							LR_HeadName.UsrData.bShowQMode = k
							LR_HeadName.GetAllMissionNeed()
							LR_HeadName.Tree()
							LR_HeadName.AddAllDoodad2AllList()
							LR_HeadName.ReDrawAll()
							LR_HeadName.SaveCommonSettings()
						end, }
				end
				PopupMenu(m)
			end,
		}, {name = "LR_Head_bSeeLimit", type = "CheckBox", text = _L["Num Limit"], x = 0, y = 100, w = 150,
			default = function ()
				return LR_HeadName.UsrData.bSeeLimit
			end,
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function (enabled)
				LR_HeadName.UsrData.bSeeLimit = enabled
				LR_HeadName.SaveCommonSettings()
				LR_HeadName.ReDrawAll()
			end,
		}, {name = "LR_Head_SeeMax", type = "CSlider", min = 10, max = 1000, x = 150, y = 100, w = 200, step = 99, unit = _L["character"],
			enable =  function ()
				return (LR_HeadName.bOn and LR_HeadName.UsrData.bSeeLimit )
			end,
			default = function ()
				return LR_HeadName.UsrData.SeeMax
			end,
			callback = function (value)
				LR_HeadName.UsrData.SeeMax = value
				LR_HeadName.SaveCommonSettings()
			end
		}, {name = "LR_Head_bDisLimit", type = "CheckBox", text = _L["Distance Limit"], x = 0, y = 130, w = 150,
			default = function ()
				return LR_HeadName.UsrData.bDisLimit
			end,
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function (enabled)
				LR_HeadName.UsrData.bDisLimit = enabled
				LR_HeadName.SaveCommonSettings()
				LR_HeadName.ReDrawAll()
			end
		}, {	name = "LR_Head_distanceMax", type = "CSlider", min = 5, max = 150, x = 150, y = 130, w = 200, step = 29, unit = _L["meter"],
			enable =  function ()
				return (LR_HeadName.bOn and LR_HeadName.UsrData.bDisLimit )
			end,
			default = function ()
				return LR_HeadName.UsrData.distanceMax
			end,
			callback = function (value)
				LR_HeadName.UsrData.distanceMax = value
				LR_HeadName.SaveCommonSettings()
			end
		}, {name = "LR_Head_Seof", type = "Text", x = 0, y = 167, w = 80, h = 28, text = _L["Height"],
			enable = function()
				return LR_HeadName.bOn
			end,
		}, {
			name = "LR_Head_Seoffset", type = "CSlider", min = -100, max = 100, x = 80, y = 160, w = 200, step = 200, unit = "",
			enable =  function ()
				return LR_HeadName.bOn
			end,
			default = function ()
				return LR_HeadName.UsrData.nOffset
			end,
			callback = function (value)
				LR_HeadName.UsrData.nOffset = value
				LR_HeadName.ReDrawAll()
				LR_HeadName.SaveCommonSettings()
			end
		}, {name = "LR_Head_NPCHead", type = "ComboBox", x = 0, y = 210, w = 140, text = _L["NPC Head Settings"],
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function(m)
				local UsrData = LR_HeadName.UsrData
				local Main = {szOption = _L["Enable NPC Head"], bCheck = true, bMCheck = false, bChecked = function() return UsrData.NPC.bShow end,
					fnAction = function()
						UsrData.NPC.bShow = not UsrData.NPC.bShow
						LR_HeadName.SaveCommonSettings()
						LR_HeadName.ReDrawAll()
						if UsrData.NPC.bShow then
							LR_HeadName.HideSysHead()
						else
							LR_HeadName.ResumeSysHead()
						end
					end}
				local second = {szOption = _L["Always hide sys npc top when disable"], bCheck = true, bMCheck = false, bChecked = function() return UsrData.NPC.bAlwaysHideSysNpcTop end,
					fnAction = function()
						UsrData.NPC.bAlwaysHideSysNpcTop = not UsrData.NPC.bAlwaysHideSysNpcTop
						if UsrData.NPC.bAlwaysHideSysNpcTop then
							LR_HeadName.HideSysHead()
						else
							LR_HeadName.ResumeSysHead()
						end
						LR_HeadName.SaveCommonSettings()
					end}
				local menu = {}
				local szOption = {_L["Neutrality NPC"], _L["Ally NPC"], _L["Enemy NPC"]}
				local relation = {"Neutrality", "Ally", "Enemy"}
				local lv2Option = {_L["Show Name"], _L["Show Title"], _L["Show Level"], _L["Show Blood"], _L["Hide Blood when not in Fight"]}
				local lv2Key = {"Name", "Title", "Level", "LifeBar", "HideLifeBar"}
				for k, v in pairs(szOption) do
					menu[relation[k]] = {szOption = v, bCheck = true, bMCheck = false, bChecked = function() return UsrData.NPC[relation[k]].bShow end,
						fnDisable = function() return  not UsrData.NPC.bShow end,
						fnAction = function()
							UsrData.NPC[relation[k]].bShow = not UsrData.NPC[relation[k]].bShow
							LR_HeadName.SaveCommonSettings()
							LR_HeadName.ReDrawAll()
						end,
					}
					for k2, v2 in pairs(lv2Option) do
						if k2 ==  5 then
							if relation[k] == "Enemy" then
								menu[relation[k]][#menu[relation[k]]+1] = { szOption = _L["Show life per in name"], bCheck = true, bMCheck = false,
									bChecked = function()
										return UsrData.NPC[relation[k]].bShowLifePer
									end,
									fnAction = function()
										UsrData.NPC[relation[k]].bShowLifePer = not UsrData.NPC[relation[k]].bShowLifePer
										LR_HeadName.SaveCommonSettings()
										LR_HeadName.ReDrawAll()
									end,
								}
							end
							menu[relation[k]][#menu[relation[k]]+1] = {bDevide = true, }
						end
						menu[relation[k]][#menu[relation[k]]+1] = {szOption = v2, bCheck = true, bMCheck = false, bChecked = function() return UsrData.NPC[relation[k]][lv2Key[k2]] end,
							fnDisable = function() return not UsrData.NPC[relation[k]].bShow end,
							fnAction = function()
								UsrData.NPC[relation[k]][lv2Key[k2]] = not UsrData.NPC[relation[k]][lv2Key[k2]]
								LR_HeadName.SaveCommonSettings()
								LR_HeadName.ReDrawAll()
							end}
						if k2 ==  5 then
							menu[relation[k]][#menu[relation[k]]].fnDisable = function() return not (UsrData.NPC[relation[k]].bShow and UsrData.NPC[relation[k]].LifeBar)  end
						end
					end
				end

				tinsert(m, Main)
				tinsert(m, second)
				tinsert(m, {bDevide = true})
				tinsert(m, menu.Neutrality)
				tinsert(m, menu.Ally)
				tinsert(m, menu.Enemy)
				PopupMenu(m)
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["NPC Instructions:\n"], font = 17, r = 255, g = 127, b = 39, }
				tTips[#tTips+1] = {szText = _L["NPC Instructions01\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["NPC Instructions02\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["NPC Instructions03\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["NPC Instructions04\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["NPC Instructions05\n"], font = 5, r = 255, g = 255, b = 255, }
				return tTips
			end,
		}, {
			name = "LR_Head_playerHead", type = "ComboBox", x = 150, y = 210, w = 140, text = _L["PLAYER Head Settings"],
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function(m)
				local UsrData = LR_HeadName.UsrData
				local Main = {szOption = _L["Enable PLAYER Head"], bCheck = true, bMCheck = false, bChecked = function() return UsrData.Player.bShow end,
					fnAction = function()
						UsrData.Player.bShow = not UsrData.Player.bShow
						LR_HeadName.SaveCommonSettings()
						LR_HeadName.ReDrawAll()
						if UsrData.Player.bShow then
							LR_HeadName.HideSysHead()
						else
							LR_HeadName.ResumeSysHead()
						end
					end, }
				local second = {szOption = _L["Always hide sys player top when disable"], bCheck = true, bMCheck = false, bChecked = function() return UsrData.Player.bAlwaysHideSysPlayerTop end,
					fnAction = function()
						UsrData.Player.bAlwaysHideSysPlayerTop = not UsrData.Player.bAlwaysHideSysPlayerTop
						if UsrData.Player.bAlwaysHideSysPlayerTop then
							LR_HeadName.HideSysHead()
						else
							LR_HeadName.ResumeSysHead()
						end
						LR_HeadName.SaveCommonSettings()
					end}
				local menu = {}
				local szOption = {_L["Self"], _L["Neutrality Player"], _L["Ally Player"], _L["Enemy Player"], _L["In Group"]}
				local relation = {"Self", "Neutrality", "Ally", "Enemy", "Party"}
				local lv2Option = {_L["Show Name"], _L["Show Title"], _L["Show Tong"], _L["Show Level"], _L["Show Blood"], _L["Show Force"], _L["Show RoleType"], _L["Hide Blood when not in Fight"]}
				local lv2Key = {"Name", "Title", "Tong", "Level", "LifeBar", "ForceID", "RoleType", "HideLifeBar"}
				for k, v in pairs(szOption) do
					menu[relation[k]] = {szOption = v, bCheck = true, bMCheck = false, bChecked = function() return UsrData.Player[relation[k]].bShow end,
						fnDisable = function() return  not UsrData.Player.bShow end,
						fnAction = function()
							UsrData.Player[relation[k]].bShow = not UsrData.Player[relation[k]].bShow
							LR_HeadName.SaveCommonSettings()
							LR_HeadName.ReDrawAll()
						end,
					}
					for k2, v2 in pairs(lv2Option) do
						if k2 == 8 then
							if relation[k] == "Enemy" then
								menu[relation[k]][#menu[relation[k]]+1] = { szOption = _L["Show life per in name"], bCheck = true, bMCheck = false,
									bChecked = function()
										return UsrData.Player[relation[k]].bShowLifePer
									end,
									fnAction = function()
										UsrData.Player[relation[k]].bShowLifePer = not UsrData.Player[relation[k]].bShowLifePer
										LR_HeadName.SaveCommonSettings()
										LR_HeadName.ReDrawAll()
									end,
								}
							end
							menu[relation[k]][#menu[relation[k]]+1] = {bDevide = true, }
						end
						menu[relation[k]][#menu[relation[k]]+1] = {szOption = v2, bCheck = true, bMCheck = false, bChecked = function() return UsrData.Player[relation[k]][lv2Key[k2]] end,
							fnDisable = function() return not UsrData.Player[relation[k]].bShow end,
							fnAction = function()
								UsrData.Player[relation[k]][lv2Key[k2]] = not UsrData.Player[relation[k]][lv2Key[k2]]
								LR_HeadName.SaveCommonSettings()
								LR_HeadName.ReDrawAll()
							end}
						if k2 ==  8 then
							menu[relation[k]][#menu[relation[k]]].fnDisable = function() return not (UsrData.Player[relation[k]].bShow and UsrData.Player[relation[k]].LifeBar)  end
						end
					end
				end

				tinsert(m, Main)
				tinsert(m, second)
				tinsert(m, {bDevide = true})
				tinsert(m, menu.Self)
				tinsert(m, menu.Party)
				tinsert(m, menu.Neutrality)
				tinsert(m, menu.Ally)
				tinsert(m, menu.Enemy)
				PopupMenu(m)
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["PLAYER Instructions:\n"], font = 17, r = 255, g = 127, b = 39, }
				tTips[#tTips+1] = {szText = _L["PLAYER Instructions01\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["PLAYER Instructions02\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["PLAYER Instructions03\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["PLAYER Instructions04\n"], font = 5, r = 255, g = 255, b = 255, }
				return tTips
			end,
		}, {
			name = "LR_Head_ChangShadow", type = "ComboBox", x = 300, y = 210, w = 140, text = _L["ChangGeShadowSettings"],
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function(m)
				local UsrData = LR_HeadName.UsrData
				local Main = {szOption = _L["EnableChangGeShadow"], bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow.bShow end, fnAction = function() UsrData.ChangGeShadow.bShow = not UsrData.ChangGeShadow.bShow ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll() end}
				local Self = {szOption = _L["SelfShadow"], fnDisable = function() return not UsrData.ChangGeShadow.bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Self"].bShow end, fnAction = function() UsrData.ChangGeShadow["Self"].bShow = not UsrData.ChangGeShadow["Self"].bShow ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll() end,
					{szOption = _L["ShowShadow"], fnDisable = function() return not UsrData.ChangGeShadow["Self"].bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Self"].bShowShadow end, fnAction = function() UsrData.ChangGeShadow["Self"].bShowShadow = not UsrData.ChangGeShadow["Self"].bShowShadow ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll()  end},
					{szOption = _L["ShowTrueBody"], fnDisable = function() return not UsrData.ChangGeShadow["Self"].bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Self"].bShowBody end, fnAction = function() UsrData.ChangGeShadow["Self"].bShowBody = not UsrData.ChangGeShadow["Self"].bShowBody ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll() end},
				}
				local Neutrality = {szOption = _L["Neutrality Player"], fnDisable = function() return  not UsrData.ChangGeShadow.bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Neutrality"].bShow end, fnAction = function() UsrData.ChangGeShadow["Neutrality"].bShow = not UsrData.ChangGeShadow["Neutrality"].bShow ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll() end,
					{szOption = _L["ShowShadow"], fnDisable = function() return not UsrData.ChangGeShadow["Neutrality"].bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Neutrality"].bShowShadow end, fnAction = function() UsrData.ChangGeShadow["Neutrality"].bShowShadow = not UsrData.ChangGeShadow["Neutrality"].bShowShadow ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll()  end},
					{szOption = _L["ShowTrueBody"], fnDisable = function() return not UsrData.ChangGeShadow["Neutrality"].bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Neutrality"].bShowBody end, fnAction = function() UsrData.ChangGeShadow["Neutrality"].bShowBody = not UsrData.ChangGeShadow["Neutrality"].bShowBody ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll() end},
				}
				local Ally = {szOption = _L["Ally Player"], fnDisable = function() return  not UsrData.ChangGeShadow.bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Ally"].bShow end, fnAction = function() UsrData.ChangGeShadow["Ally"].bShow = not UsrData.ChangGeShadow["Ally"].bShow ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll() end,
					{szOption = _L["ShowShadow"], fnDisable = function() return not UsrData.ChangGeShadow["Ally"].bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Ally"].bShowShadow end, fnAction = function() UsrData.ChangGeShadow["Ally"].bShowShadow = not UsrData.ChangGeShadow["Ally"].bShowShadow ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll()  end},
					{szOption = _L["ShowTrueBody"], fnDisable = function() return not UsrData.ChangGeShadow["Ally"].bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Ally"].bShowBody end, fnAction = function() UsrData.ChangGeShadow["Ally"].bShowBody = not UsrData.ChangGeShadow["Ally"].bShowBody ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll() end},
				}
				local Enemy = {szOption = _L["Enemy Player"], fnDisable = function() return  not UsrData.ChangGeShadow.bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Enemy"].bShow end, fnAction = function() UsrData.ChangGeShadow["Enemy"].bShow = not UsrData.ChangGeShadow["Enemy"].bShow ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll() end,
					{szOption = _L["ShowShadow"], fnDisable = function() return not UsrData.ChangGeShadow["Enemy"].bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Enemy"].bShowShadow end, fnAction = function() UsrData.ChangGeShadow["Enemy"].bShowShadow = not UsrData.ChangGeShadow["Enemy"].bShowShadow ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll()  end},
					{szOption = _L["ShowTrueBody"], fnDisable = function() return not UsrData.ChangGeShadow["Enemy"].bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Enemy"].bShowBody end, fnAction = function() UsrData.ChangGeShadow["Enemy"].bShowBody = not UsrData.ChangGeShadow["Enemy"].bShowBody ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll() end},
				}
				local Party = {szOption = _L["In Group"], fnDisable = function() return  not UsrData.ChangGeShadow.bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Party"].bShow end, fnAction = function() UsrData.ChangGeShadow["Party"].bShow = not UsrData.ChangGeShadow["Party"].bShow ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll() end,
					{szOption = _L["ShowShadow"], fnDisable = function() return not UsrData.ChangGeShadow["Party"].bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Party"].bShowShadow end, fnAction = function() UsrData.ChangGeShadow["Party"].bShowShadow = not UsrData.ChangGeShadow["Party"].bShowShadow ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll()  end},
					{szOption = _L["ShowTrueBody"], fnDisable = function() return not UsrData.ChangGeShadow["Party"].bShow end, bCheck = true, bMCheck = false, bChecked = function() return UsrData.ChangGeShadow["Party"].bShowBody end, fnAction = function() UsrData.ChangGeShadow["Party"].bShowBody = not UsrData.ChangGeShadow["Party"].bShowBody ;LR_HeadName.SaveCommonSettings() ; LR_HeadName.ReDrawAll() end},
				}
				tinsert(m, Main)
				tinsert(m, {bDevide = true})
				tinsert(m, Self)
				tinsert(m, Party)
				tinsert(m, Neutrality)
				tinsert(m, Ally)
				--tinsert(m, Enemy)
				PopupMenu(m)
			end,
		}, {
			name = "LR_Head_HideInDUNGEON", type = "ComboBox", x = 0, y = 240, w = 140, text = _L["HideInDragon"],
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function(m)
				local data = LR_HeadName.UsrData.HideInDungeon
				local szOption = {_L["Enable auto hide in dragon"], _L["Hide Name"], _L["Hide Title"], _L["Hide Tong"], _L["Hide Level"], _L["Hide Blood"], _L["Hide Force"], _L["Hide RoleType"]}
				local key = {"bOn", "Name", "Title", "Tong", "Level", "LifeBar", "ForceID", "RoleType"}
				local menu = {}
				for k, v in pairs(szOption) do
					if k ==  2 then
						menu[#menu+1] = {bDevide = true, }
					end
					menu[#menu+1] = {szOption = v, bCheck = true, bMCheck = false, bChecked = function() return data[key[k]] end,
						fnAction = function()
							data[key[k]] = not data[key[k]]
							LR_HeadName.SaveCommonSettings()
							LR_HeadName.ReDrawAll()
						end, }
					if k>= 2 then
						menu[#menu].fnDisable = function() return not data.bOn end
					end
				end
				for i = 1, #menu, 1 do
					tinsert(m, menu[i])
				end
				PopupMenu(m)
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["Auto hide Instructions:\n"], font = 17, r = 255, g = 127, b = 39, }
				tTips[#tTips+1] = {szText = _L["Auto hide Instructions01\n"], font = 5, r = 255, g = 255, b = 255, }
				return tTips
			end,
		}, { name = "LR_Head_bShowTeamMark", type = "ComboBox", text = _L["Show Team Mark"], x = 150, y = 240, w = 140,
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function (m)
				m[#m+1] = {szOption = _L["Show Team Mark"], bCheck = true, bMCheck = false, bChecked = function() return LR_HeadName.UsrData.bShowTeamMark end,
					fnAction = function()
						LR_HeadName.UsrData.bShowTeamMark = not LR_HeadName.UsrData.bShowTeamMark
						LR_HeadName.SaveCommonSettings()
						LR_HeadName.ReDrawAll()
					end,
				}
				m[#m+1] = {szOption = _L["High Light Team Mark"], bCheck = true, bMCheck = false, bChecked = function() return LR_HeadName.UsrData.bHightLightTeamMark end,
					fnAction = function()
						LR_HeadName.UsrData.bHightLightTeamMark = not LR_HeadName.UsrData.bHightLightTeamMark
						LR_HeadName.SaveCommonSettings()
						LR_HeadName.ReDrawAll()
					end,
				}
				m[#m+1] = {bDevide = true, }
				local szText = {_L["Show Team Mark Text"], _L["Show Team Mark Image"]}
				for k, v in pairs (szText) do
					m[#m+1] = {szOption = v, bCheck = true, bMCheck = true, bChecked = function() return LR_HeadName.UsrData.nShowTeamMarkType ==  k end,
						fnDisable = function() return not LR_HeadName.UsrData.bShowTeamMark end,
						fnAction = function()
							LR_HeadName.UsrData.nShowTeamMarkType = k
							LR_HeadName.SaveCommonSettings()
							LR_HeadName.ReDrawAll()
						end,
					}
				end
				local mm = m[#m]
				mm[#mm + 1] = {
					szOption = _L["Set lifeper text offsetY"] .. sformat(": %d", LR_HeadName.UsrData.nMarkOffset or 0),
					fnAction = function()
						GetUserInputNumber(LR_HeadName.UsrData.nMarkOffset or 0, 1000, nil, function(arg0)
							LR_HeadName.UsrData.nMarkOffset = arg0,
							--LR_HeadName.ReDrawAll()
							LR_HeadName.SaveCommonSettings()
						end)
					end,
				}
				PopupMenu(m)
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["Teammark Instructions:\n"], font = 17, r = 255, g = 127, b = 39, }
				tTips[#tTips+1] = {szText = _L["Teammark Instructions01\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["Teammark Instructions02\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["Teammark Instructions03\n"], font = 5, r = 255, g = 255, b = 255, }
				return tTips
			end,
		}, {name = "LR_Head_Dis", type = "ComboBox", x = 300, w = 140, y = 240, text = _L["Distance/Face settings"],
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function(m)
				m[#m + 1] = {szOption = _L["Show target distance"], bCheck = true, bMCheck = false, bChecked = function() return LR_HeadName.UsrData.bShowTargetDis end,
					fnAction = function()
						LR_HeadName.UsrData.bShowTargetDis = not LR_HeadName.UsrData.bShowTargetDis
						LR_HeadName.ReDrawAll()
						LR_HeadName.SaveCommonSettings()
					end,
				}
				m[#m + 1] = {szOption = _L["Show fighting enemy distance"], bCheck = true, bMCheck = false, bChecked = function() return LR_HeadName.UsrData.bShowFightingEnemyDis end,
					fnAction = function()
						LR_HeadName.UsrData.bShowFightingEnemyDis = not LR_HeadName.UsrData.bShowFightingEnemyDis
						LR_HeadName.ReDrawAll()
						LR_HeadName.SaveCommonSettings()
					end,
				}
				m[#m + 1] = {bDevide = true}
				m[#m + 1] = {szOption = _L["Show target face"], bCheck = true, bMCheck = false, bChecked = function() return LR_HeadName.UsrData.bShowTargetFace end,
					fnAction = function()
						LR_HeadName.UsrData.bShowTargetFace = not LR_HeadName.UsrData.bShowTargetFace
						LR_HeadName.ReDrawAll()
						LR_HeadName.SaveCommonSettings()
					end,
				}
				PopupMenu(m)
			end,
		}, {name = "LR_Head_DoodadShow", type = "ComboBox", x = 0, y = 270, w = 140, text = _L["Show Doodad"],
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function(m)
				local DoodadKind = {
					--[DOODAD_KIND.INVALID], --"INVALID",
					[DOODAD_KIND.NORMAL] = true, --"普通物件"
					[DOODAD_KIND.CORPSE] = true, --"尸体"
					[DOODAD_KIND.QUEST] = true, --"任务物品"
					--[DOODAD_KIND.READ], --"写字台"
					--[DOODAD_KIND.DIALOG] = true, --"DIALOG"
					[DOODAD_KIND.ACCEPT_QUEST] = true, --"宴席"
					[DOODAD_KIND.TREASURE] = true, --"拾取物品"
					[DOODAD_KIND.ORNAMENT] = true, --"装饰"
					[DOODAD_KIND.CRAFT_TARGET] = true, --"碑铭"
					--[DOODAD_KIND.CLIENT_ONLY], --"CLIENT_ONLY"
					--[DOODAD_KIND.CHAIR], --"CHAIR"
					--[DOODAD_KIND.GUIDE], --"GUIDE"
					--[DOODAD_KIND.DOOR] = true, --"桌子"
					--[DOODAD_KIND.NPCDROP], --"NPCDROP"
				}
				for k, v in pairs (DoodadKind) do
					m[#m+1] = {szOption = LR_HeadName.DoodadKindDescribe[k], bCheck = true, bMCheck = false, bChecked = function() return LR_HeadName.DoodadKind[k] end,
						fnAction = function()
							LR_HeadName.DoodadKind[k] = not LR_HeadName.DoodadKind[k]
							LR_HeadName.AddAllDoodad2AllList()
							LR_HeadName.ReDrawAll()
							LR_HeadName.SaveCommonSettings()
						end,
					}
				end
				m[#m+1] = {bDevide = true}
				m[#m+1] = {szOption = _L["Show Doodad Type"], bCheck = true, bMCheck = false, bChecked = function() return LR_HeadName.UsrData.bShowDoodadKind end,
					fnAction = function()
						LR_HeadName.UsrData.bShowDoodadKind = not LR_HeadName.UsrData.bShowDoodadKind
						LR_HeadName.SaveCommonSettings()
						LR_HeadName.ReDrawAll()
					end,
				}
				m[#m+1] = {szOption = _L["Enhance guding show"], bCheck = true, bMCheck = false, bChecked = function() return LR_HeadName.UsrData.bEnhanceGuDing end,
					fnAction = function()
						LR_HeadName.UsrData.bEnhanceGuDing = not LR_HeadName.UsrData.bEnhanceGuDing
						LR_HeadName.SaveCommonSettings()
						LR_HeadName.ReDrawAll()
					end,
				}
				m[#m+1] = {szOption = _L["Show quest pickup doodad"], bCheck = true, bMCheck = false, bChecked = function() return LR_HeadName.UsrData.bShowQuestDoodad end,
					fnAction = function()
						LR_HeadName.UsrData.bShowQuestDoodad = not LR_HeadName.UsrData.bShowQuestDoodad
						LR_HeadName.SaveCommonSettings()
						if LR_HeadName.UsrData.bShowQuestDoodad then
							LR_HeadName.AddAllDoodad2AllList()
						end
						LR_HeadName.ReDrawAll()
					end,
				}
				PopupMenu(m)
			end
		}, {name = "LR_Head_Mineral", type = "ComboBox", x = 150, y = 270, w = 140, text = _L["Show Mineral"],
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function(m)
				local Mineral = LR_HeadName.Mineral
				for i = 1, #Mineral, 1 do
					m[#m+1] = {szOption = Mineral[i].szName, bCheck = true, bMCheck = false, bChecked = function() return Mineral[i].bShow end,
						fnAction = function()
							Mineral[i].bShow = not Mineral[i].bShow
							LR_HeadName.AddAllDoodad2AllList()
							LR_HeadName.ReDrawAll()
							LR_HeadName.SaveCommonSettings()
						end,
					}
				end
				m[#m+1] = {bDevide = true, }
				m[#m+1] = {szOption = _L["Mark in minimap"], bCheck = true, bMCheck = false, bChecked = function() return LR_HeadName.UsrData.bMiniMapMine end,
					fnAction = function()
						LR_HeadName.UsrData.bMiniMapMine = not LR_HeadName.UsrData.bMiniMapMine
						LR_HeadName.SaveCommonSettings()
					end,
				}
				m[#m+1] = {bDevide = true, }
				m[#m+1] = {szOption = _L["Reset settings"],
					fnAction = function()
						LR_HeadName_UI.ResetMineral()
						LR_HeadName.AddAllDoodad2AllList()
						LR_HeadName.ReDrawAll()
						LR_HeadName.SaveCommonSettings()
					end,
				}
				PopupMenu(m)
			end
		}, {name = "LR_Head_Agriculture", type = "ComboBox", x = 300, y = 270, w = 140, text = _L["Show Agriculture"],
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function(m)
				local Agriculture = LR_HeadName.Agriculture
				for i = 1, #Agriculture, 1 do
					m[#m+1] = {szOption = Agriculture[i].szName, bCheck = true, bMCheck = false, bChecked = function() return Agriculture[i].bShow end,
						fnAction = function()
							Agriculture[i].bShow = not Agriculture[i].bShow
							LR_HeadName.AddAllDoodad2AllList()
							LR_HeadName.ReDrawAll()
							LR_HeadName.SaveCommonSettings()
						end, }
				end
				m[#m+1] = {bDevide = true, }
				m[#m+1] = {szOption = _L["Mark in minimap"], bCheck = true, bMCheck = false, bChecked = function() return LR_HeadName.UsrData.bMiniMapAgriculture end,
					fnAction = function()
						LR_HeadName.UsrData.bMiniMapAgriculture = not LR_HeadName.UsrData.bMiniMapAgriculture
						LR_HeadName.SaveCommonSettings()
					end,
				}
				m[#m+1] = {bDevide = true, }
				m[#m+1] = {szOption = _L["Reset settings"],
					fnAction = function()
						LR_HeadName_UI.ResetAgriculture()
						LR_HeadName.AddAllDoodad2AllList()
						LR_HeadName.ReDrawAll()
						LR_HeadName.SaveCommonSettings()
					end,
				}
				PopupMenu(m)
			end
		}, {name = "LR_Head_CustomDoodad", type = "ComboBox", x = 0, y = 300, w = 140, text = _L["Custom object"],
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function(m)
				local CustomDoodad = LR_HeadName.CustomDoodad
				tinsert(m, {szOption = _L["ADD"],
				fnAction = function()
					GetUserInput(_L["Object Name"], function(szText)
						local szText =  sgsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
						if szText ~=  "" then
							CustomDoodad[szText] = true
							LR_HeadName.SaveCommonSettings()
						end
					end)
				end})
				tinsert(m, {bDevide = true})
				for k, v in pairs (CustomDoodad) do
					tinsert(m, {szOption = k, bCheck = true, bMCheck = false, bChecked = function() return CustomDoodad[k] end, fnAction = function() CustomDoodad[k]  = not CustomDoodad[k] ; LR_HeadName.SaveCommonSettings() ; LR_HeadName.AddAllDoodad2AllList() ;LR_HeadName.ReDrawAll()  end,
						{szOption = _L["Delete"], fnAction = function()
							CustomDoodad[k] = nil
							LR_HeadName.SaveCommonSettings()
						end, }
					})
				end
				PopupMenu(m)
			end
		}, {name = "LR_Head_CustomLifeBar", type = "ComboBox", x = 150, y = 300, w = 140, text = _L["LifeBar Style Settings"],
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function(m)
				local LifeBar = LR_HeadName.UsrData.LifeBar
				local border  = {szOption = _L["Show Blood Border"], bCheck = true, bMCheck = false, bChecked = function() return LifeBar.ShowBorder end,
					fnAction = function()
						LifeBar.ShowBorder  = not LifeBar.ShowBorder
						LR_HeadName.SaveCommonSettings()
						LR_HeadName.ReDrawAll()
					end, }
				local bordercolor = {szOption = _L["Border color"], fnDisable = function() return not LifeBar.ShowBorder end,
					{	szOption = _L["Click to change color"],
						rgb = LR_HeadName.UsrData.LifeBar.BorderColor,
						fnAutoClose = true,
						fnAction = function()
							local fnChangeColor = function(r, g, b)
								LR_HeadName.UsrData.LifeBar.BorderColor = {r, g, b}
								LR_HeadName.SaveCommonSettings()
								LR_HeadName.ReDrawAll()
							end
							LR.OpenColorTablePanel(fnChangeColor, LR_HeadName.UsrData.LifeBar.BorderColor)
						end,
						fnDisable = function() return not LifeBar.ShowBorder end,
					}
				}
				local height = {szOption = _L["Blood Height"], }
				for i = 5, 10, 1 do
					tinsert(height, {szOption = sformat(_L["%d pixel"], i-4), bCheck = true, bMCheck = true, bChecked = function() return LifeBar.Height == i end, fnAction = function() LifeBar.Height  = i ; LR_HeadName.SaveCommonSettings()  ;LR_HeadName.ReDrawAll()  end, })
				end
				local alpha = {szOption = _L["Alpha"], }
				for i = 5, 255, 25 do
					tinsert(alpha, {szOption = i , bCheck = true, bMCheck = true, bChecked = function() return LifeBar.Alpha == i end, fnAction = function() LifeBar.Alpha  = i ; LR_HeadName.SaveCommonSettings()  ;LR_HeadName.ReDrawAll()  end, })
				end
				local color = {szOption = _L["ColorMode"],
					{szOption = _L["Red"] , bCheck = true, bMCheck = true, bChecked = function() return LifeBar.ColorMode == 1 end, fnAction = function() LifeBar.ColorMode  = 1 ; LR_HeadName.SaveCommonSettings()  ;LR_HeadName.ReDrawAll()  end, },
					{szOption = _L["Follow Head Color"] , bCheck = true, bMCheck = true, bChecked = function() return LifeBar.ColorMode == 2 end, fnAction = function() LifeBar.ColorMode  = 2 ; LR_HeadName.SaveCommonSettings()  ; LR_HeadName.ReDrawAll() end, },
				}
				local offsetY = {szOption = _L["LifeBar offsetY"], }
				for i = 10, -10, -1 do
					tinsert(offsetY, {szOption = sformat("%d px", i), bCheck = true, bMCheck = true, bChecked = function() return LifeBar.nOffsetY == i end, fnAction = function() LifeBar.nOffsetY  = i ; LR_HeadName.SaveCommonSettings()  ;LR_HeadName.ReDrawAll()  end, })
				end
				local lenth = {szOption = _L["LifeBar lenth"], }
				for i = 32, 200, 4 do
					tinsert(lenth, {szOption = sformat("%d px", i) , bCheck = true, bMCheck = true, bChecked = function() return LifeBar.Lenth == i end, fnAction = function() LifeBar.Lenth  = i ; LR_HeadName.SaveCommonSettings()  ;LR_HeadName.ReDrawAll()  end, })
				end

				tinsert(m, border)
				tinsert(m, bordercolor)
				tinsert(m, height)
				tinsert(m, alpha)
				tinsert(m, color)
				tinsert(m, lenth)
				tinsert(m, offsetY)

				tinsert(m, {bDevide = true})
				tinsert(m, {szOption = _L["Show lifeper beside lifebar"], bCheck = true, bMCheck = false, bChecked = function() return LR_HeadName.UsrData.LifeBar.bShowLifePercentText end,
					fnAction = function()
						LR_HeadName.UsrData.LifeBar.bShowLifePercentText = not LR_HeadName.UsrData.LifeBar.bShowLifePercentText,
						LR_HeadName.ReDrawAll()
						LR_HeadName.SaveCommonSettings()
					end,
				})
				tinsert(m, {szOption = _L["Set lifeper text offsetX"] .. sformat(": %d", LR_HeadName.UsrData.LifeBar.nLifePercentTextOffsetX or 0) ,
					fnAction = function()
						GetUserInputNumber(LR_HeadName.UsrData.LifeBar.nLifePercentTextOffsetX or 0, 1000, nil, function(arg0)
							LR_HeadName.UsrData.LifeBar.nLifePercentTextOffsetX = arg0,
							LR_HeadName.ReDrawAll()
							LR_HeadName.SaveCommonSettings()
						end)
					end,
					fnDisable = function() return not LR_HeadName.UsrData.LifeBar.bShowLifePercentText end,
				})
				tinsert(m, {szOption = _L["Set lifeper text offsetY"] .. sformat(": %d", LR_HeadName.UsrData.LifeBar.nLifePercentTextOffsetY or 0) ,
					fnAction = function()
						GetUserInputNumber(LR_HeadName.UsrData.LifeBar.nLifePercentTextOffsetY or 0, 1000, nil, function(arg0)
							LR_HeadName.UsrData.LifeBar.nLifePercentTextOffsetY = arg0,
							LR_HeadName.ReDrawAll()
							LR_HeadName.SaveCommonSettings()
						end)
					end,
					fnDisable = function() return not LR_HeadName.UsrData.LifeBar.bShowLifePercentText end,
				})
				tinsert(m, {szOption = _L["Set lifeper text scale"] .. sformat(": %d%%", (LR_HeadName.UsrData.LifeBar.nLifePercentTextScale or 0) * 100) ,
					fnAction = function()
						GetUserInputNumber((LR_HeadName.UsrData.LifeBar.nLifePercentTextScale or 0) * 100, 1000, nil, function(arg0)
							LR_HeadName.UsrData.LifeBar.nLifePercentTextScale = arg0 * 1.0 / 100,
							LR_HeadName.ReDrawAll()
							LR_HeadName.SaveCommonSettings()
						end)
					end,
					fnDisable = function() return not LR_HeadName.UsrData.LifeBar.bShowLifePercentText end,
				})
				PopupMenu(m)
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["LifeBar Instructions:\n"], font = 17, r = 255, g = 127, b = 39, }
				tTips[#tTips+1] = {szText = _L["LifeBar Instructions01\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["LifeBar Instructions02\n"], font = 5, r = 255, g = 255, b = 255, }
				tTips[#tTips+1] = {szText = _L["LifeBar Instructions03\n"], font = 5, r = 255, g = 255, b = 255, }
				return tTips
			end,
		},
		--[[
		{name = "LR_Head_FontColor", type = "ComboBox", x = 300, y = 300, w = 140, text = _L["Font&Color"],
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function(m)
				m[#m + 1] = {szOption = _L["Set Font"],
					{szOption = sformat(_L["Now Font %d, click to change"], LR_HeadName.UsrData.font),
					fnAction = function()
						local function fun (font)
							LR_HeadName.UsrData.font = font
							LR_HeadName.SaveCommonSettings()
							LR_HeadName.ReDrawAll()
						end
						LR.OpenFontPanel(fun, LR_HeadName.UsrData.font)
					end},
				}
				m[#m + 1] = {bDevide = true}

				local szKey = {"Doodad", "Ally", "Enemy", "Neutrality", "Party", "Self"}
				m[#m + 1] = {szOption = _L["Set normal color"]}
				local menu1 = m[#m]
				for k, v in pairs(szKey) do
					menu1[#menu1 + 1] = {szOption = _L[v],
						fnAction = function()
							local function fun (r, g, b)
								LR_HeadName.Color[v] = {r, g, b}
								LR_HeadName.SaveCommonSettings()
								LR_HeadName.ReDrawAll()
							end
							LR.OpenColorTablePanel(fun, LR_HeadName.Color[v])
						end,
					}
				end

				m[#m + 1] = {szOption = _L["Set highlight color"]}
				local menu2 = m[#m]
				for k, v in pairs(szKey) do
					menu2[#menu2 + 1] = {szOption = _L[v],
						fnAction = function()
							local function fun (r, g, b)
								LR_HeadName.HighLightColor[v] = {r, g, b}
								LR_HeadName.SaveCommonSettings()
								LR_HeadName.ReDrawAll()
							end
							LR.OpenColorTablePanel(fun, LR_HeadName.HighLightColor[v])
						end,
					}
				end

				m[#m + 1] = {bDevide = true}
				m[#m + 1] = {szOption = _L["Reset font&color"],
					fnAction = function()
						local reset = function()
							LR_HeadName.ResetFontAndColor()
							LR_HeadName.SaveCommonSettings()
							LR_HeadName.ReDrawAll()
						end

						local msg = {
							szMessage = _L["Sure to reset font&color?"],
							szName = "reset",
							fnAutoClose = function() return false end,
							{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() reset() end, },
							{szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function() end, },
						}
						MessageBox(msg)
					end,
				}

				PopupMenu(m)
			end,
		},
		]]
		{name = "LR_Head_an2", type = "Button", x = 330, y = 330, text = _L["Reset settings"], w = 100,
			enable =  function ()
				return LR_HeadName.bOn
			end,
			callback = function()
				LR_HeadName.ResetSettings()
				LR_HeadName.SaveCommonSettings()
				if LR_HeadName.UsrData.bShowQMode ==  1 or LR_HeadName.UsrData.bShowQMode ==  2 then
					LR_HeadName.GetAllMissionNeed()
					LR_HeadName.Tree()
					LR_HeadName.AddAllDoodad2AllList()
				end
				LR_HeadName.ReDrawAll()
				LR_TOOLS:OpenPanel(_L["LR Headname"])
			end
		},
	}
}

function LR_HeadName_UI.ResetAgriculture()
	LR_HeadName.Agriculture = {
		{szName = _L["GanCao"], bShow = true, },
		{szName = _L["DaHuang"], bShow = true, },
		{szName = _L["ShaoYao"], bShow = false, },
		{szName = _L["LanCao"], bShow = false, },
		{szName = _L["XiangSiZi"], bShow = false, },
		{szName = _L["CheQianCao"], bShow = false, },
		{szName = _L["TianMingJing"], bShow = false, },
		{szName = _L["FangFeng"], bShow = false, },
		{szName = _L["WuWeiZi"], bShow = false, },
		{szName = _L["JinYinHua"], bShow = false, },
		{szName = _L["JinChuangXiaoCao"], bShow = false, },
		{szName = _L["GouQi"], bShow = false, },
		{szName = _L["QianLiXiang"], bShow = false, },
		{szName = _L["TianQi"], bShow = false, },
		{szName = _L["TianMa"], bShow = false, },
		{szName = _L["YuanZhi"], bShow = false, },
		{szName = _L["XianMao"], bShow = false, },
		{szName = _L["ChuanBei"], bShow = false, },
		{szName = _L["ChongCao"], bShow = false, },
		{szName = _L["MaiDong"], bShow = false, },
		{szName = _L["SuGuanHeDing"], bShow = false, },
		{szName = _L["BaiMaiGen"], bShow = false, },
		{szName = _L["HuangZhuCao"], bShow = false, },
		{szName = _L["TianXiangCao"], bShow = false, },
		{szName = _L["ZiHuaMuXu"], bShow = false, },
		{szName = _L["ShiLianHua"], bShow = false, },
		{szName = _L["BiAnHua"], bShow = false, },
		{szName = _L["BaiZhu"], bShow = true, },
		{szName = _L["ZiSu"], bShow = true, },
	}
end

function LR_HeadName_UI.ResetMineral()
	LR_HeadName.Mineral  = {
		{szName = _L["TongKuang"], bShow = true, },
		{szName = _L["XiKuang"], bShow = false, },
		{szName = _L["QianKuang"], bShow = false, },
		{szName = _L["XinKuang"], bShow = false, },
		{szName = _L["TieKuang"], bShow = false, },
		{szName = _L["YinKuang"], bShow = false, },
		{szName = _L["YinShaKuang"], bShow = false, },
		{szName = _L["ChiTie"], bShow = false, },
		{szName = _L["YueXi"], bShow = false, },
		{szName = _L["ZhenTieKuang"], bShow = false, },
		{szName = _L["YuTongKuang"], bShow = false, },
		{szName = _L["TianQingShiKuang"], bShow = true, },
		{szName = _L["YanYuShiKuang"], bShow = true, },
	}
end

LR_TOOLS:RegisterPanel(LR_HeadName_UI)

-----------------------------------
----注册头像、扳手菜单
-----------------------------------
LR_TOOLS.menu = LR_TOOLS.menu or {}
LR_HeadName_UI.menu = {
	szOption  = _L["LR Headname"],
	fnAction = function()
		LR_HeadName.bOn = not LR_HeadName.bOn
		LR_HeadName.OpenFrame()
		if LR_HeadName.bOn then
			LR_HeadName.ReDrawAll()
		end
	end,
	bCheck = true,
	bMCheck = false,
	rgb = {255, 255, 255},
	bChecked = function()
		return LR_HeadName.bOn
	end,
	fnAutoClose = true,
	szIcon = "ui\\Image\\UICommon\\CommonPanel2.UITex",
	nFrame  = 105,
	nMouseOverFrame = 106,
	szLayer = "ICON_RIGHT",
	fnAutoClose = true,
	fnClickIcon = function ()
		LR_TOOLS:OpenPanel(_L["LR Headname"])
	end,
	rgb = {255, 255, 255},
	fnAutoClose = true,
	{szOption = _L["Enable Headname"], bCheck = true, bMCheck = false, bChecked = function() return LR_HeadName.bOn end,
	fnAction = function()
		LR_HeadName.bOn = not LR_HeadName.bOn
		LR_HeadName.OpenFrame()
		if LR_HeadName.bOn then
			LR_HeadName.ReDrawAll()
		end
	end, },
	{bDevide = true},
	{szOption = _L["Enable Balloon"], bCheck = true, bMCheck = false, bChecked = function() return LR_Balloon.UsrData.bOn end,
		fnAction = function()
			LR_Balloon.UsrData.bOn = not LR_Balloon.UsrData.bOn
			if not LR_Balloon.UsrData.bOn then
				for k, v in pairs (LR_Balloon.DialogList) do
					v:Remove()
					LR_Balloon.DialogList[k] = nil
				end
			end
		end,
		fnDisable = function() return not LR_HeadName.bOn end, },
	{szOption = _L["Show player balloon"], bCheck = true, bMCheck = false, bChecked = function() return LR_Balloon.UsrData.bShowPlayerMsg end, fnAction = function() LR_Balloon.UsrData.bShowPlayerMsg = not LR_Balloon.UsrData.bShowPlayerMsg end, fnDisable = function() return not (LR_HeadName.bOn and LR_Balloon.UsrData.bOn) end, },
	{szOption = _L["Show npc balloon"], bCheck = true, bMCheck = false, bChecked = function() return LR_Balloon.UsrData.bShowNpcMsg end, fnAction = function() LR_Balloon.UsrData.bShowNpcMsg = not LR_Balloon.UsrData.bShowNpcMsg end, fnDisable = function() return not (LR_HeadName.bOn and LR_Balloon.UsrData.bOn)  end, },
	{szOption = _L["Enable shield"], bCheck = true, bMCheck = false, bChecked = function() return LR_Balloon.UsrData.bBlock end,
		fnAction = function()
			LR_Balloon.UsrData.bBlock = not LR_Balloon.UsrData.bBlock
		end,
		fnDisable = function() return not (LR_HeadName.bOn and LR_Balloon.UsrData.bOn)  end, },
	{szOption = _L["Balloon num limit"],
		fnAction = function()
			LR.SysMsg(sformat(_L["The balloon num limit is %d now.\n"], LR_Balloon.UsrData.NumLimit))
			local x, y = this:GetAbsPos()
			GetUserInputNumber(50, 100, {x, y, 0, 0}, function(szText)
				if tonumber(szText) > 0  then
					LR_Balloon.UsrData.NumLimit = tonumber(szText)
					LR.SysMsg(_L["Successful!Change.\n"])
				end
			end)
		end,
		fnDisable = function() return not (LR_HeadName.bOn and LR_Balloon.UsrData.bOn)  end,
	},
	{bDevide = true},
	{szOption = _L["Shield Settings"], fnAction = function() LR_Balloon_Panel:Open() end, },
}
tinsert(LR_TOOLS.menu, LR_HeadName_UI.menu)

-----------------------------
---快捷键
-----------------------------
LR.AddHotKey(_L["LR Headname"], function() LR_TOOLS:OpenPanel(_L["LR Headname"]) end)
LR.AddHotKey(_L["LR Headname onekey shield npc"], function() LR_HeadName.OneKeyShieldNpc() end)
LR.AddHotKey(_L["LR Headname onekey shield player"], function() LR_HeadName.OneKeyShieldPlayer() end)

