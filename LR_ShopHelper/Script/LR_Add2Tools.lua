local sformat, slen, sgsub, ssub,sfind = string.format, string.len, string.gsub, string.sub, string.find
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil = math.floor, math.ceil
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
-------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_ShopHelper"
local _L = LR.LoadLangPack(AddonPath)
--------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("SmallHelpers") then
	tinsert (LR_TOOLS.tAddonClass,{"SmallHelpers",_L["Helpers"],"3"})
end
-----------------------------------------
local LR_ShopHelper_UI  = {
	szName = "LR_ShopHelper_UI",
	szTitle = _L["LR ShopHelper"] ,
	dwIcon = 8850,
	szClass = "SmallHelpers",
	tWidget = {
		{name = "LR_ShopHelper_CheckBox01", type = "CheckBox", text = _L["Enable auto sell"], x = 0, y = 0, w = 150,
			default = function ()
				return LR_AutoSell.UsrData.bOn
			end,
			callback = function (enabled)
				LR_AutoSell.UsrData.bOn = enabled
			end,
		},{name = "LR_ShopHelper_CheckBox04", type = "CheckBox", text = _L["Auto sell grey item"], x = 20, y = 30, w = 150,
			enable = function()
				return LR_AutoSell.UsrData.bOn
			end,
			default = function()
				return LR_AutoSell.UsrData.bAutoSellGreyItem
			end,
			callback = function (enabled)
				LR_AutoSell.UsrData.bAutoSellGreyItem = enabled
			end,
		},{	name = "LR_ShopHelper_ComboBox1", type = "ComboBox", x = 20, y = 60, w = 220, text = _L["Sell Item List"],
			enable = function()
				return LR_AutoSell.UsrData.bOn
			end,
			callback = function(m)
				LR_AutoSell.LoadCustomData()
				m[#m + 1] = {szOption = _L["Enable sell items in list"], bCheck = true, bMCheck = false, bChecked = function() return LR_AutoSell.UsrData.bAutoSellItemInList end,
					fnAction = function()
						LR_AutoSell.UsrData.bAutoSellItemInList = not LR_AutoSell.UsrData.bAutoSellItemInList
					end,
				}
				m[#m + 1] = {bDevide = true}
				local CustomData = LR_AutoSell.CustomData or {}
				for k, v in pairs (CustomData.AutoSellItem or {}) do
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
					m[#m + 1] = {szOption = szName, bCheck = true, bMCheck = false, bChecked = function() return v.bSell end,
						fnAction = function()
							v.bSell = not v.bSell
							LR_AutoSell.SaveCustomData()
						end,
						fnDisable = function()
							return not LR_AutoSell.UsrData.bAutoSellItemInList
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
								{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() tremove(LR_AutoSell.CustomData.AutoSellItem, k); LR_AutoSell.SaveCustomData() end, },
								{szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function() end, },
							}
							MessageBox(msg)
						end,
					}
				end
				m[#m + 1] = {bDevide = true}
				m[#m + 1] = {szOption = _L["Add Item"],
					fnAction = function()
						GetUserInput(_L["Add Item"], function(szText)
							local szText =  LR.Trim(szText)
							szText = sgsub(szText, "£¬", ",")
							szText = sgsub(szText, " ", "")
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
								data.bSell = true
								LR_AutoSell.CustomData = LR_AutoSell.CustomData or {}
								tinsert(LR_AutoSell.CustomData.AutoSellItem, data)
								LR_AutoSell.SaveCustomData()
							end
						end)
					end,
					fnDisable = function()
						return not LR_AutoSell.UsrData.bAutoSellItemInList
					end,
				}
				PopupMenu(m)
			end
		},{	name = "LR_ShopHelper_ComboBox2", type = "ComboBox", x = 250, y = 60, w = 220, text = _L["Black List"],
			enable = function()
				return LR_AutoSell.UsrData.bOn
			end,
			callback = function(m)
				LR_AutoSell.LoadCustomData()
				m[#m + 1] = {szOption = _L["Enable black list"], bCheck = true, bMCheck = false, bChecked = function() return LR_AutoSell.UsrData.enableBlackList end,
					fnAction = function()
						LR_AutoSell.UsrData.enableBlackList = not LR_AutoSell.UsrData.enableBlackList
					end,
				}
				m[#m + 1] = {bDevide = true}
				local CustomData = LR_AutoSell.CustomData or {}
				for k, v in pairs (CustomData.BlackList or {}) do
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
					m[#m + 1] = {szOption = szName, bCheck = true, bMCheck = false, bChecked = function() return v.bNotSell end,
						fnAction = function()
							v.bNotSell = not v.bNotSell
							LR_AutoSell.SaveCustomData()
						end,
						fnDisable = function()
							return not LR_AutoSell.UsrData.enableBlackList
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
								{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() tremove(LR_AutoSell.CustomData.BlackList, k); LR_AutoSell.SaveCustomData() end, },
								{szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function() end, },
							}
							MessageBox(msg)
						end,
					}
				end
				m[#m + 1] = {bDevide = true}
				m[#m + 1] = {szOption = _L["Add Item"],
					fnAction = function()
						GetUserInput(_L["Add Item"], function(szText)
							local szText =  LR.Trim(szText)
							szText = sgsub(szText, "£¬", ",")
							szText = sgsub(szText, " ", "")
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
								data.bNotSell = true
								LR_AutoSell.CustomData = LR_AutoSell.CustomData or {}
								tinsert(LR_AutoSell.CustomData.BlackList, data)
								LR_AutoSell.SaveCustomData()
							end
						end)
					end,
					fnDisable = function()
						return not LR_AutoSell.UsrData.enableBlackList
					end,
				}
				PopupMenu(m)
			end
		},{	name = "LR_ShopHelper_Button01", type = "Button", x = 20, y = 90, text = _L["Reset list"], w = 120, h = 40,
			enable = function()
				return LR_AutoSell.UsrData.bOn
			end,
			callback = function()
				local msg = {
					szMessage = _L["Are you sure to reset item list?"],
					szName = "reset",
					fnAutoClose = function() return false end,
					{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() LR_AutoSell.ResetCustomData() end, },
					{szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function() end, },
				}
				MessageBox(msg)
			end,
		},
		--[[
		{name = "LR_ShopHelper_CheckBox02", type = "CheckBox", text = _L["Enable auto repare"], x = 0, y = 140, w = 150,
			default = function ()
				return LR_AutoRepare.UsrData.bOn
			end,
			callback = function (enabled)
				LR_AutoRepare.UsrData.bOn = enabled
			end,
		},
		]]
		{	name = "LR_ShopHelper_Text2", type = "Scroll_Text", x = 0, y = 140, w = 540, h = 360,
			Text = {
				{szText = _L["TIP2"], font = 61},
				{szText = _L["TIP"], font = 61 },
			},
		},
	}
}
LR_TOOLS:RegisterPanel(LR_ShopHelper_UI)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
LR_TOOLS.menu = LR_TOOLS.menu or {}
LR_ShopHelper_UI.menu = {
	szOption  = _L["LR ShopHelper"] ,
	fnAction = function()
		LR_TOOLS:OpenPanel(_L["LR ShopHelper"])
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
		LR_TOOLS:OpenPanel(_L["LR ShopHelper"])
	end,
	rgb = {255, 255, 255},
	fnAutoClose = true,
	{szOption = _L["Enable auto sell"], bCheck = true, bMCheck = false, bChecked = function() return LR_AutoSell.UsrData.bOn end, fnAction = function() LR_AutoSell.UsrData.bOn = not LR_AutoSell.UsrData.bOn end},
	{szOption = _L["Enable auto repare"], bCheck = true, bMCheck = false, bChecked = function() return LR_AutoRepare.UsrData.bOn end, fnAction = function() LR_AutoRepare.UsrData.bOn = not LR_AutoRepare.UsrData.bOn end},
	--{szOption = _L["Enable buy more"], bCheck = true, bMCheck = false, bChecked = function() return LR_BuyMore.UsrData.bOn end, fnAction = function() LR_BuyMore.UsrData.bOn = not LR_BuyMore.UsrData.bOn end},
}
table.insert(LR_TOOLS.menu, LR_ShopHelper_UI.menu)

-----------------------------
---¿ì½Ý¼ü
-----------------------------
LR.AddHotKey(_L["LR ShopHelper"], function() LR_TOOLS:OpenPanel(_L["LR ShopHelper"]) end)
