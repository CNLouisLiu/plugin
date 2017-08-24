local sformat, slen, sgsub, ssub,sfind = string.format, string.len, string.gsub, string.sub, string.find
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil = math.floor, math.ceil
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
-------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_PickupDead"
local _L = LR.LoadLangPack(AddonPath)
--------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("SmallHelpers") then
	tinsert (LR_TOOLS.tAddonClass,{"SmallHelpers",_L["Helpers"],"3"})
end
-----------------------------------------
local LR_PickupDead_UI  = {
	szName = "LR_PickupDead_UI",
	szTitle = _L["LR PickupDead"] ,
	dwIcon = 7181,
	szClass = "SmallHelpers",
	tWidget = {
		{name = "LR_PickupDead_CheckBox01", type = "CheckBox", text = _L["Enable pickup dead"], x = 0, y = 0, w = 150,
			default = function ()
				return LR_PickupDead.UsrData.bOn
			end,
			callback = function (enabled)
				LR_PickupDead.UsrData.bOn = enabled
			end,
		},{	name = "LR_PickupDead_ComboBox1", type = "ComboBox", x = 0, y = 30, w = 220, text = _L["Quality Settings"],
			enable = function()
				return LR_PickupDead.UsrData.bOn
			end,
			callback = function(m)
				local szOption = {_L["Any Quality"], _L["Quality 0"], _L["Quality 1"], _L["Quality 2"], _L["Quality 3"], }
				local RGB = {{GetItemFontColorByQuality(0)}, {GetItemFontColorByQuality(1)}, {GetItemFontColorByQuality(2)}, {GetItemFontColorByQuality(3)}, {GetItemFontColorByQuality(4)}, }
				for k, v in pairs (szOption) do
					m[#m + 1] = {szOption = v, bCheck = true, bMCheck = true, bChecked = function() return LR_PickupDead.UsrData.pickUpLevel == k - 1 end,
						fnAction = function()
							LR_PickupDead.UsrData.pickUpLevel = k - 1
						end,
						rgb = RGB[k],
					}
				end
				PopupMenu(m)
			end
		},{	name = "LR_PickupDead_ComboBox2", type = "ComboBox", x = 0, y = 60, w = 220, text = _L["Item Filter Settings"],
			enable = function()
				return LR_PickupDead.UsrData.bOn
			end,
			callback = function(m)
				--拾取任务物品
				m[#m + 1] = {szOption = _L["Pickup task item"], bCheck = true, bMCheck = false, bChecked = function() return LR_PickupDead.UsrData.bPickupTaskItem end,
					fnAction = function()
						LR_PickupDead.UsrData.bPickupTaskItem = not LR_PickupDead.UsrData.bPickupTaskItem
					end,
				}
				m[#m + 1] = {szOption = _L["Pickup unread book"], bCheck = true, bMCheck = false, bChecked = function() return LR_PickupDead.UsrData.bPickupUnReadBook end,
					fnAction = function()
						LR_PickupDead.UsrData.bPickupUnReadBook = not LR_PickupDead.UsrData.bPickupUnReadBook
					end,
				}
				--拾取白名单
				m[#m + 1] = {bDevide = true}
				m[#m + 1] = {szOption = _L["Pickup White List"], bCheck = true, bMCheck = false, bChecked = function() return LR_PickupDead.UsrData.bPickupItems end,
					fnAction = function()
						LR_PickupDead.UsrData.bPickupItems = not LR_PickupDead.UsrData.bPickupItems
					end
				}
				local itemMenu = m[#m]
				for k, v in pairs (LR_PickupDead.customData.pickList or {}) do
					local szName = ""
					if v.szName then
						szName = v.szName
					elseif v.dwTabType then
						local itemInfo = GetItemInfo(v.dwTabType, v.dwIndex)
						if itemInfo then
							szName = itemInfo.szName
						else
							szName = _L["Error, no this item"]
						end
					else
						szName = GetItemNameByUIID(v.nUiId)
					end
					itemMenu[#itemMenu + 1] = {szOption = szName, bCheck = true, bMCheck = false, bChecked = function() return v.bPickup end,
						fnAction = function()
							v.bPickup = not v.bPickup
							LR_PickupDead.SaveCustomData()
						end,
						fnDisable = function()
							return not LR_PickupDead.UsrData.bPickupItems
						end,
						fnAutoClose = true,
						szIcon = "ui\\Image\\UICommon\\CommonPanel4.UITex",
						nFrame  = 72,
						nMouseOverFrame = 72,
						szLayer = "ICON_RIGHT",
						fnAutoClose = true,
						fnClickIcon = function ()
							local msg = {
								szMessage = sformat("%s %s?", _L["Sure to delete"], szName),
								szName = "delete",
								fnAutoClose = function() return false end,
								{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() tremove(LR_PickupDead.customData.pickList, k); LR_PickupDead.SaveCustomData() end, },
								{szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function() end, },
							}
							MessageBox(msg)
						end,
					}
				end
				itemMenu[#itemMenu + 1] = {bDevide = true}
				itemMenu[#itemMenu + 1] = {szOption = _L["Add Item"],
					fnAction = function()
						GetUserInput(_L["Add Item"], function(szText)
							local szText =  LR.Trim(szText)
							if szText ~= "" then
								local data
								if type(tonumber(szText)) == "number" then
									data = {nUiId = tonumber(szText)}
								elseif sfind(szText, "(%d+),(%d+)") then
									local _, _, dwTabType, dwIndex = sfind(szText, "(%d+),(%d+)")
									data = {dwTabType = dwTabType, dwIndex = dwIndex}
								else
									data = {szName = szText}
								end
								data.bPickup = true
								LR_PickupDead.customData.pickList = LR_PickupDead.customData.pickList or {}
								tinsert(LR_PickupDead.customData.pickList, data)
								LR_PickupDead.SaveCustomData()
							end
						end)
					end,
					fnDisable = function()
						return not LR_PickupDead.UsrData.bPickupItems
					end,
				}
				itemMenu[#itemMenu + 1] = {bDevide = true}
				itemMenu[#itemMenu + 1] = {szOption = _L["Only pickup item in white list which is checked"], bCheck = true, bMCheck = false, bChecked = function() return LR_PickupDead.UsrData.bOnlyPickupItems end,
					fnAction = function()
						LR_PickupDead.UsrData.bOnlyPickupItems = not LR_PickupDead.UsrData.bOnlyPickupItems
					end,
					fnDisable = function()
						return not LR_PickupDead.UsrData.bPickupItems
					end,
				}
				--拾取黑名单
				m[#m + 1] = {bDevide = true}
				m[#m + 1] = {szOption = _L["Pickup Black List"], bCheck = true, bMCheck = false, bChecked = function() return LR_PickupDead.UsrData.bnotPickupItems end,
					fnAction = function()
						LR_PickupDead.UsrData.bnotPickupItems = not LR_PickupDead.UsrData.bnotPickupItems
					end
				}
				local itemMenu = m[#m]
				for k, v in pairs (LR_PickupDead.customData.ignorList or {}) do
					local szName = ""
					if v.szName then
						szName = v.szName
					elseif v.dwTabType then
						local itemInfo = GetItemInfo(v.dwTabType, v.dwIndex)
						if itemInfo then
							szName = itemInfo.szName
						else
							szName = _L["Error, no this item"]
						end
					else
						szName = GetItemNameByUIID(v.nUiId)
					end
					itemMenu[#itemMenu + 1] = {szOption = szName, bCheck = true, bMCheck = false, bChecked = function() return v.bnotPickup end,
						fnAction = function()
							v.bnotPickup = not v.bnotPickup
							LR_PickupDead.SaveCustomData()
						end,
						fnDisable = function()
							return not LR_PickupDead.UsrData.bnotPickupItems
						end,
						fnAutoClose = true,
						szIcon = "ui\\Image\\UICommon\\CommonPanel4.UITex",
						nFrame  = 72,
						nMouseOverFrame = 72,
						szLayer = "ICON_RIGHT",
						fnAutoClose = true,
						fnClickIcon = function ()
							local msg = {
								szMessage = sformat("%s %s?", _L["Sure to delete"], szName),
								szName = "delete",
								fnAutoClose = function() return false end,
								{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() tremove(LR_PickupDead.customData.ignorList, k); LR_PickupDead.SaveCustomData() end, },
								{szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function() end, },
							}
							MessageBox(msg)
						end,
					}
				end
				itemMenu[#itemMenu + 1] = {bDevide = true}
				itemMenu[#itemMenu + 1] = {szOption = _L["Add Item"],
					fnAction = function()
						GetUserInput(_L["Add Item"], function(szText)
							local szText =  LR.Trim(szText)
							if szText ~= "" then
								local data
								if type(tonumber(szText)) == "number" then
									data = {nUiId = tonumber(szText)}
								elseif sfind(szText, "(%d+),(%d+)") then
									local _, _, dwTabType, dwIndex = sfind(szText, "(%d+),(%d+)")
									data = {dwTabType = dwTabType, dwIndex = dwIndex}
								else
									data = {szName = szText}
								end
								data.bnotPickup = true
								LR_PickupDead.customData.ignorList = LR_PickupDead.customData.ignorList or {}
								tinsert(LR_PickupDead.customData.ignorList, data)
								LR_PickupDead.SaveCustomData()
							end
						end)
					end,
					fnDisable = function()
						return not LR_PickupDead.UsrData.bnotPickupItems
					end,
				}

				m[#m + 1] = {bDevide = true}
				m[#m + 1] = {szOption = _L["Refresh black/white list"],
					fnAction = function()
						local msg = {
							szMessage = _L["Are you sure to refresh black/white list?"],
							szName = "reset",
							fnAutoClose = function() return false end,
							{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() LR_PickupDead.LoadCustomData() end, },
							{szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function() end, },
						}
						MessageBox(msg)
					end,}

				PopupMenu(m)
			end
		},
	}
}
LR_TOOLS:RegisterPanel(LR_PickupDead_UI)
-----------------------------------
----注册头像、扳手菜单
-----------------------------------
LR_TOOLS.menu = LR_TOOLS.menu or {}
LR_PickupDead_UI.menu = {
	szOption  = _L["LR PickupDead"] ,
	fnAction = function()
		LR_TOOLS:OpenPanel(_L["LR PickupDead"])
	end,
	bCheck = true,
	bMCheck = false,
	rgb = {255, 255, 255},
	bChecked = function()
		local frame = Station.Lookup("Normal/LR_TOOLS")
		if frame then
			return true
		else
			return false
		end
	end,
	fnAutoClose = true,
	szIcon = "ui\\Image\\UICommon\\CommonPanel2.UITex",
	nFrame  = 105,
	nMouseOverFrame = 106,
	szLayer = "ICON_RIGHT",
	fnAutoClose = true,
	fnClickIcon = function ()
		LR_TOOLS:OpenPanel(_L["LR PickupDead"])
	end,
	rgb = {255, 255, 255},
	fnAutoClose = true,
}
tinsert(LR_TOOLS.menu, LR_PickupDead_UI.menu)

-----------------------------
---快捷键
-----------------------------
LR.AddHotKey(_L["LR PickupDead"], function() LR_TOOLS:OpenPanel(_L["LR PickupDead"]) end)
