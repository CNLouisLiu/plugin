local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_RaidGridEx"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_TeamGrid"
local _L = LR.LoadLangPack(AddonPath)
---------------------------------------------------------------
LR_TeamMenu = {}

function LR_TeamMenu.CureModeMenu()
	local menu =  {}
	local menu2 =  {}
	local szOption = {}
	menu[#menu+1] = {szOption = _L["Correlation with boss"],fnDisable = function() return true end,}
	menu[#menu+1] = {bDevide = true,}
	menu[#menu+1] = {szOption = _L["Show boss target"],bMCheck = false, bCheck = true, bChecked = LR_TeamGrid.UsrData.CommonSettings.bShowBossTarget,
		fnDisable = function()
			return false
		end,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.bShowBossTarget = not LR_TeamGrid.UsrData.CommonSettings.bShowBossTarget
			LR_TeamGrid.SaveCommonData()
		end,}
	menu[#menu+1] = {szOption = _L["Show elite monster target"],bMCheck = false,bCheck = true,bChecked = LR_TeamGrid.UsrData.CommonSettings.bShowSmallBossTarget ,
		fnDisable = function()
			return false
		end,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.bShowSmallBossTarget = not LR_TeamGrid.UsrData.CommonSettings.bShowSmallBossTarget
			LR_TeamGrid.SaveCommonData()
		end,}
	menu[#menu+1] = {bDevide = true,}
	menu[#menu+1] = {szOption = _L["Show boss OTBar"],bMCheck = false,bCheck = true,bChecked = LR_TeamGrid.UsrData.CommonSettings.bShowBossOT ,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.bShowBossOT = not LR_TeamGrid.UsrData.CommonSettings.bShowBossOT
			LR_TeamGrid.SaveCommonData()
		end,}
	menu[#menu+1] = {szOption = _L["Enable only in cure kungfu"],bMCheck = false,bCheck = true,bChecked =  LR_TeamGrid.UsrData.CommonSettings.bShowBossOTOnlyInCure ,
		fnDisable = function()
			return not LR_TeamGrid.UsrData.CommonSettings.bShowBossOT
		end,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.bShowBossOTOnlyInCure = not LR_TeamGrid.UsrData.CommonSettings.bShowBossOTOnlyInCure
			LR_TeamGrid.SaveCommonData()
		end,}
	menu[#menu+1] = {bDevide = true}
	menu[#menu+1] = {szOption = _L["Enable boss focus"], bCheck = true, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.bShowBossFocus end,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.bShowBossFocus = not LR_TeamGrid.UsrData.CommonSettings.bShowBossFocus
			LR_TeamGrid.SaveCommonData()
		end,}
	menu[#menu+1] = {szOption = sformat(_L["Set boss focus alpha %d"], LR_TeamGrid.UsrData.CommonSettings.nBossFocusAlpha or 120),
		fnAction = function()
			local fx, fy = this:GetAbsPos()
			GetUserInputNumber(LR_TeamGrid.UsrData.CommonSettings.nBossFocusAlpha or 120, 255, {fx, fy, 0, 0},
				function(value)
					LR_TeamGrid.UsrData.CommonSettings.nBossFocusAlpha = tonumber(value)
					LR_TeamGrid.SaveCommonData()
				end, nil, nil)
		end,}
	menu[#menu+1] = {bDevide = true}
	menu[#menu+1] = {szOption = _L["The following functions will be auto enabled in cure kungfu"],fnDisable = function() return true end,}
	menu[#menu+1] = {bDevide = true}
	menu[#menu+1] = {szOption =  _L["Quick select team member(without click)."],bMCheck = false,bCheck = true,bChecked =  LR_TeamGrid.UsrData.CommonSettings.bInCureMode ,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.bInCureMode = not LR_TeamGrid.UsrData.CommonSettings.bInCureMode
			LR_TeamGrid.SaveCommonData()
		end,
		fnMouseEnter = function()
			local szTip = {}
			szTip[#szTip+1] = GetFormatText(_L["Cure Auto Select Tip"], 224)
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputTip(tconcat(szTip), 300, {x, y, 0, 0})
		end,}
	---选人方式
	szOption = {_L["Cure Select Mode 1."], _L["Cure Select Mode 2."]}
	--szOption = {_L["Cure Select Mode 1."], } --暂时屏蔽选人方式2
	for k, v in pairs(szOption) do
		menu[#menu+1] = {szOption = v,bMCheck = true, bCheck = true, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.cureMode == k end,
			fnDisable =  function() return not LR_TeamGrid.UsrData.CommonSettings.bInCureMode end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.cureMode = k
				LR_TeamGrid.SaveCommonData()
			end,
			fnMouseEnter = function()
				if k == 2 then
					local szTip = {}
					szTip[#szTip+1] = GetFormatText(_L["Cure Select Mode 2 Tip1"], 224)
					szTip[#szTip+1] = GetFormatText(_L["Cure Select Mode 2 Tip2"], 224)
					szTip[#szTip+1] = "<image>w = 24 h = 24 path = \"fromiconid\" frame = 6933</image>"
					szTip[#szTip+1] = GetFormatText(sformat("\n%s", _L["Cure Select Mode 2 Tip3"]), 224)
					szTip[#szTip+1] = "<image>w = 24 h = 24 path = \"fromiconid\" frame = 6942</image>"
					szTip[#szTip+1] = GetFormatText(sformat("\n%s", _L["Cure Select Mode 2 Tip4"]), 224)
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					OutputTip(tconcat(szTip), 300, {x, y, 0, 0})
				end
			end,}
	end

	menu[#menu+1] = {bDevide = true}
	menu[#menu+1] = {szOption = _L["Show skill cd self"],	bMCheck = false,	bCheck = true,bChecked =  LR_TeamGrid.UsrData.CommonSettings.bShowSkillBox ,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.bShowSkillBox = not LR_TeamGrid.UsrData.CommonSettings.bShowSkillBox
			LR_TeamSkillMonitor.ShowSkillPanel()
			LR_TeamGrid.SaveCommonData()
		end,}
		menu[#menu][#menu[#menu]+1] = {szOption = _L["Check order is the sort order"],bCheck = false,fnDisable = function() return true end,}
		menu[#menu][#menu[#menu]+1] = {bDevide = true}
		menu2 = {}
		for dwID,v in pairs(LR_TeamSkillMonitor.SKILL_LIST) do
			local menu2 = {szOption = LR.Trim(Table_GetSkillName(dwID,1)),bCheck = false,fnDisable = function() return not LR_TeamGrid.UsrData.CommonSettings.bShowSkillBox end,}
			for i = 1,#v,1 do
				tinsert(menu2,{szOption = LR.Trim(Table_GetSkillName(v[i].dwID,1)),bCheck = true,bMCheck = false,
					bChecked = function()
						local SkillMonitorList = LR_TeamSkillMonitor.SkillMonitorData.data[dwID] or {}
						for kk,vv in pairs (SkillMonitorList) do
							if vv.dwID == v[i].dwID then
								return true
							end
						end
						return false
					end,
					fnAction = function()
						local ID = LR_TeamSkillMonitor.GetSkillMonitorOrder(dwID,v[i].dwID)
						if ID == 0 then
							LR_TeamSkillMonitor.SkillMonitorData.data[dwID][#LR_TeamSkillMonitor.SkillMonitorData.data[dwID]+1] = {dwID = v[i].dwID,enable = true}
						else
							tremove(LR_TeamSkillMonitor.SkillMonitorData.data[dwID],ID)
						end
						LR_TeamSkillMonitor.ShowSkillPanel()
						LR_TeamSkillMonitor.SaveCommonData()
					end,})
			end
			tinsert(menu2,{bDevide = true})
			tinsert(menu2,{szOption = _L["Uncheck All"],bMCheck = false,fnAutoClose = function() return true end,
				fnAction = function()
					LR_TeamSkillMonitor.SkillMonitorData.data[dwID] = {}
					LR_TeamSkillMonitor.ShowSkillPanel()
					LR_TeamSkillMonitor.SaveCommonData()
				end,
			})
			tinsert(menu[#menu],menu2)
		end
	local t = {_L["Up"], _L["Down"], _L["Left"], _L["Right"]}
	menu[#menu+1] = {szOption = _L["The position where the skill will be shown"],fnDisable = function() return not LR_TeamGrid.UsrData.CommonSettings.bShowSkillBox end,}
		for k, v in pairs (t) do
			menu[#menu][#menu[#menu]+1] = {szOption = v,bMCheck = true,bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == k end,
				fnAction = function()
					LR_TeamGrid.UsrData.CommonSettings.skillBoxPos = k
					LR_TeamSkillMonitor.ShowSkillPanel()
					LR_TeamGrid.UpdateRoleBodySize()
					LR_TeamGrid.SaveCommonData()
				end,}
		end
	menu[#menu+1] = {bDevide = true,}
	menu[#menu+1] = {szOption =  _L["Blood automatically converted to percentage display"] ,bMCheck =  false,bCheck = true,bChecked = LR_TeamGrid.UsrData.CommonSettings.autoPercentInCure,
		fnDisable = function() return false end,
		fnAction = function ()
			LR_TeamGrid.UsrData.CommonSettings.autoPercentInCure = not LR_TeamGrid.UsrData.CommonSettings.autoPercentInCure
			LR_TeamGrid.ReDrawAllMembers()
			LR_TeamGrid.SaveCommonData()
		end,}
	return menu
end

function LR_TeamMenu.KungfuDisplayMenu()
	local menu = {}
	local szText = { _L["Show Kungfu icon"], _L["Show Kungfu name"], _L["Show Camp icon"], _L["Show Camp name"]}
	for k, v in pairs(szText) do
		menu[#menu+1] = {szOption = v,bMCheck = true,bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.kungFuShowType == k end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.kungFuShowType = k
				if LR_TOOLS:Fetch("LR_TeamGrid_UI_KungfuScale") then
					LR_TOOLS:Fetch("LR_TeamGrid_UI_KungfuScale"):Enable(k == 2 or k == 4)
				end
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end
	return menu
end

function LR_TeamMenu.NameStyleMenu()
	local menu = {}
	local szText = {_L["Style1"], _L["Style2"], _L["Style3"]}
	local value = {15, 7, 23}
	for k, v in pairs(szText) do
		menu[#menu+1] = {szOption = v,bMCheck = true,bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.szFontScheme == value[k] end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.szFontScheme = value[k]
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end
	return menu
end

function LR_TeamMenu.NameColoredMenu()
	local menu = {}
	local szOption = {_L["Colored by school"], _L["Colored by camp"], _L["No Color"]}
	for k,v in pairs(szOption) do
		menu[#menu+1] = {szOption = v ,bMCheck = true,bChecked = LR_TeamGrid.UsrData.CommonSettings.szFontColor == k,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.szFontColor = k
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end
	menu[#menu+1] = {bDevide = true}
	menu[#menu+1] = {szOption = _L["Auto change color in common quest"], bCheck = true, bMCheck = true,
		bChecked = function()
			return not LR_TeamGrid.UsrData.CommonSettings.bNotAutoChangeColorWhenInWorldCommonQuest
		end,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.bNotAutoChangeColorWhenInWorldCommonQuest = not LR_TeamGrid.UsrData.CommonSettings.bNotAutoChangeColorWhenInWorldCommonQuest
			LR_TeamGrid.ReDrawAllMembers()
			LR_TeamGrid.SaveCommonData()
		end,
		fnMouseEnter = function()
			local tip = {}
			tip[#tip + 1] = GetFormatText(_L["Name text tip01"], 32)
			local x, y = this:GetAbsPos()
			OutputTip(tconcat(tip), 320, {x, y, 0, 0})
		end,
		fnMouseLeave = function()
			HideTip()
		end,
	}
	return menu
end

function LR_TeamMenu.NameLimitMenu()
	local menu = {szOption = _L["Name number limit"]}
	for i = 3,6,1 do
		menu[#menu+1] = {szOption = sformat(_L["%d characters"],i),bMCheck = true,	bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.nNameNumLimit == i end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.nNameNumLimit = i
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end
	return menu
end

function LR_TeamMenu.LifeTextTypeMenu()
	local menu = {}
	local szText = {_L["Display left blood"], _L["Show damaged blood"], _L["No blood display"]}
	for k, v in pairs(szText) do
		menu[#menu+1] = {szOption = v, bMCheck = true, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.lifeTextType == k end,
			fnAction = function(UserData,bCheck)
				LR_TeamGrid.UsrData.CommonSettings.lifeTextType = k
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end
	return menu
end

function LR_TeamMenu.LifePercentSetMenu()
	local menu = {}
	local szText = {_L["Show blood number"], _L["Show blood percent"]}
	local value = {false, true}
	for k, v in pairs(szText) do
		menu[#menu+1] = {szOption = v, bCheck = true, bMCheck = true, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.bShowBloodInPercent == value[k] end,
			fnDisable = function()
				return LR_TeamGrid.UsrData.CommonSettings.lifeTextType == 3
			end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.bShowBloodInPercent = value[k]
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end
	return menu
end

function LR_TeamMenu.ShortBloodMenu()
	local menu = {}
	menu[#menu+1] = {szOption = _L["Short blood"],bCheck = true,bMCheck = false,bChecked = LR_TeamGrid.UsrData.CommonSettings.bShortBlood,
		fnDisable = function()
			return LR_TeamGrid.UsrData.CommonSettings.lifeTextType == 3
		end,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.bShortBlood = not LR_TeamGrid.UsrData.CommonSettings.bShortBlood
			LR_TeamGrid.ReDrawAllMembers()
			LR_TeamGrid.SaveCommonData()
		end,
	}
	local menu2 = menu[#menu]
	for i = 0,2,1 do
		menu2[#menu2+1] = {szOption = sformat(_L["%d digits after the decimal point"],i),bCheck = true , bMCheck = true ,bChecked =  function() return LR_TeamGrid.UsrData.CommonSettings.nDecimalPoint == i end,
			fnDisable = function()
				return LR_TeamGrid.UsrData.CommonSettings.lifeTextType == 3 or not LR_TeamGrid.UsrData.CommonSettings.bShortBlood
			end,
			fnAction = function ()
				LR_TeamGrid.UsrData.CommonSettings.nDecimalPoint = i
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end
	return menu
end

function LR_TeamMenu.BackGroundColorSetMenu()
	local menu = {}
	local szText = {_L["Colored by distance"], _L["Colored by kungfu"], _L["No Color"]}
	for k , v in pairs (szText) do
		menu[#menu+1] = {szOption = v, bCheck = true, bMCheck = true, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.bShowBloodInPercent == value[k] end,
			fnDisable = function()
				return LR_TeamGrid.UsrData.CommonSettings.lifeTextType == 3
			end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.bShowBloodInPercent = value[k]
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end
	return menu
end

function LR_TeamMenu.BloodBarSetMenu()
	local menu = {}
	local menu2 = {}
	local m = {}
	local distanceLevel = LR_TeamGrid.UsrData.CommonSettings.distanceLevel
	local distanceAlpha = LR_TeamGrid.UsrData.CommonSettings.distanceAlpha
	local backGroundColorType = LR_TeamGrid.UsrData.CommonSettings.backGroundColorType
	local bloodLevelSet = LR_TeamGrid.UsrData.CommonSettings.bloodLevelSet
	local bloodLevelAlpha = LR_TeamGrid.UsrData.CommonSettings.bloodLevelAlpha

	local szText = {_L["BloodBar Color Set"], _L["BloodBar Alpha Set"],}
	for k, v in pairs(szText) do
		menu[#menu+1] = {szOption = v, 	}
	end

	menu[#menu+1] = {bDevide = true}
	menu[#menu+1] = {szOption = _L["Distance level set"]}
	local key2 = {"nDis1","nDis2","nDis3"}
	for k,v in pairs (key2) do
		local menu2 = {szOption = _L[v]}
		for i = 2,35,1 do
			if k == 1 and i<24 or k == 2 and i<25  and i>5 or k == 3 and i<= 35 and i> 15 then
			menu2[#menu2+1] = {szOption = sformat(_L["%s meter"],LR.GetFullSizeNumber(i)),bMCheck = true,bCheck = true,bChecked =  distanceLevel[k] == i ,
				fnDisable = function()
					return not LR_TeamMenu.IsDistanceDisable(k,i)
				end,
				fnAction = function()
					distanceLevel[k] = i
					LR_TeamGrid.ReDrawAllMembers()
					LR_TeamGrid.SaveCommonData()
				end,
			}
			end
		end
		menu[#menu][#menu[#menu]+1] = menu2
	end

	menu[#menu+1] = {szOption = _L["Blood level set"]}
	key2 = {_L["Blood level 1"], _L["Blood level 2"],}
	for k,v in pairs (key2) do
		local menu2 = {szOption = v}
		menu2[#menu2+1] = {szOption = sformat(_L["%d%%, Click to change"], bloodLevelSet[k] * 100) ,
			fnAction = function()
				GetUserInputNumber(bloodLevelSet[k] *100 , 100, nil,
					function(value)
						LR_TeamGrid.UsrData.CommonSettings.bloodLevelSet[k] = value / 100
						LR_TeamGrid.ReDrawAllMembers()
						LR_TeamGrid.SaveCommonData()
					end, nil, nil)
			end
		}
		menu[#menu][#menu[#menu]+1] = menu2
	end

	menu[#menu+1] = {bDevide = true,}
	menu[#menu+1] = {szOption = _L["Show distance text"], bCheck = true, bMCheck = false, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.bShowDistanceText end,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.bShowDistanceText = not LR_TeamGrid.UsrData.CommonSettings.bShowDistanceText
			LR_TeamGrid.ReDrawAllMembers()
			LR_TeamGrid.SaveCommonData()
		end
	}

	menu[#menu+1] = {bDevide = true,}
	menu[#menu+1] = {szOption = _L["BG Color Fill Method"]}
	menu2 = menu[#menu]
	for i = 1, 5 do
		menu2[#menu2+1] = {szOption = sformat(_L["Method %d"], i), bCheck = true, bMCheck = true, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.bgColorFillType == i end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.bgColorFillType = i
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end

	--血条着色设置。1：固定颜色；2：按门派着色；3:按阵营着色；4：按距离着色；5：按血量着色
	szText = {_L["Fixed Color"], _L["Colored by kungfu"], _L["Colored by Camp"], _L["Colored by distance"], _L["Colored by blood volume"]}
	for k, v in pairs(szText) do
		local m = menu[1]
		m[#m+1] = {szOption = v, bCheck = true, bMCheck = true, bChecked = function() return backGroundColorType == k end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.backGroundColorType = k
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end

	m = menu[1][1]
	m[#m+1] = { szOption = _L["Click to change color"],
		rgb = LR_TeamGrid.UsrData.CommonSettings.backGroundFixedColor,
		fnAutoClose = true,
		fnAction = function()
			local fnChangeColor = function(r, g, b)
				LR_TeamGrid.UsrData.CommonSettings.backGroundFixedColor = {r, g, b}
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end
			LR.OpenColorTablePanel(fnChangeColor, LR_TeamGrid.UsrData.CommonSettings.backGroundFixedColor)
		end,
		fnDisable = function() return LR_TeamGrid.UsrData.CommonSettings.backGroundColorType ~=  1 end,}

	m = menu[1][4]
	szText = {
		sformat(_L["Color:%s - %s meter"], LR.GetFullSizeNumber(0), LR.GetFullSizeNumber(distanceLevel[1])),
		sformat(_L["Color:%s - %s meter"], LR.GetFullSizeNumber(distanceLevel[1]), LR.GetFullSizeNumber(distanceLevel[2])),
		sformat(_L["Color:%s - %s meter"], LR.GetFullSizeNumber(distanceLevel[2]), LR.GetFullSizeNumber(distanceLevel[3])),
		sformat(_L["Color:%s meters - Sync Range"], LR.GetFullSizeNumber(distanceLevel[3])),
		_L["Color:Out of Sync Range"],
	}
	for k, v in pairs(szText) do
		m[#m+1] = {	szOption = v, fnDisable = function() return LR_TeamGrid.UsrData.CommonSettings.backGroundColorType ~=  4 end,
			{	szOption = _L["Click to change color"],  bMCheck = false,
				rgb = LR_TeamGrid.UsrData.CommonSettings.distanceColor[k],
				fnAutoClose = true,
				fnAction = function()
					local fnChangeColor = function(r, g, b)
						LR_TeamGrid.UsrData.CommonSettings.distanceColor[k] = {r, g, b}
						LR_TeamGrid.ReDrawAllMembers()
						LR_TeamGrid.SaveCommonData()
					end
					LR.OpenColorTablePanel(fnChangeColor, LR_TeamGrid.UsrData.CommonSettings.distanceColor[k])
				end,
				szIcon = "ui\\Image\\Button\\CommonButton_1.UITex",
				nFrame  = 69,
				nMouseOverFrame = 70,
				szLayer = "ICON_RIGHT",
				fnClickIcon = function ()
					local fnChangeColor = function(r, g, b)
						LR_TeamGrid.UsrData.CommonSettings.distanceColor[k] = {r, g, b}
						LR_TeamGrid.ReDrawAllMembers()
						LR_TeamGrid.SaveCommonData()
					end
					LR.OpenColorTablePanel(fnChangeColor, LR_TeamGrid.UsrData.CommonSettings.distanceColor[k])
				end,
			},
		}
	end
	m[#m+1] = {bDevide = true}
	m[#m+1] = {szOption = _L["Reset color settings"], fnDisable = function() return LR_TeamGrid.UsrData.CommonSettings.backGroundColorType ~=  4 end ,
		fnAction = function()
			LR_TeamGrid.ResetColorSettings()
			LR_TeamGrid.ReDrawAllMembers()
			LR_TeamGrid.SaveCommonData()
		end,
	}

	m = menu[1][5]
	menu2 = {}
	szText = {
		sformat(_L["Level 1:(above %d%%)"], bloodLevelSet[1] * 100),
		sformat(_L["Level 2:(%d%% ~ %d%%)"], bloodLevelSet[1] * 100, bloodLevelSet[2] * 100),
		sformat(_L["Level 3:(under %d%%)"], bloodLevelSet[2] * 100)
	}
	for k, v in pairs(szText) do
		m[#m+1] = {szOption =  v, fnDisable = function() return LR_TeamGrid.UsrData.CommonSettings.backGroundColorType ~=  5 end,
			{	szOption = _L["Click to change color"],
				rgb = LR_TeamGrid.UsrData.CommonSettings.bloodLevelColor[k],
				fnAutoClose = true,
				fnAction = function()
					local fnChangeColor = function(r, g, b)
						LR_TeamGrid.UsrData.CommonSettings.bloodLevelColor[k] = {r, g, b}
						LR_TeamGrid.ReDrawAllMembers()
						LR_TeamGrid.SaveCommonData()
					end
					LR.OpenColorTablePanel(fnChangeColor, LR_TeamGrid.UsrData.CommonSettings.bloodLevelColor[k])
				end,
				fnDisable = function() return LR_TeamGrid.UsrData.CommonSettings.backGroundColorType ~=  5 end,
			}
		}
	end

	--血量透明度着色。1：固定透明度；2：按距离透明度；3：按血量透明度
	szText = {_L["Fixed alpha"], _L["Alpha by distance"], _L["Alpha by blood volume"]}
	m = menu[2]
	for k, v in pairs(szText) do
		m[#m+1] = {szOption = v, bCheck = true, bMCheck = true, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.backGroundAlphaType == k end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.backGroundAlphaType = k
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end

	m = menu[2][1]
	m[#m+1] = {szOption = sformat(_L["%d Alpha , Click to change alpha"], LR_TeamGrid.UsrData.CommonSettings.backGroundFixedAlpha),
		fnDisable = function() return LR_TeamGrid.UsrData.CommonSettings.backGroundAlphaType ~=  1 end,
		fnAction = function()
			GetUserInputNumber(LR_TeamGrid.UsrData.CommonSettings.backGroundFixedAlpha, 255, nil,
				function(value)
					LR_TeamGrid.UsrData.CommonSettings.backGroundFixedAlpha = value
				end, nil, nil)
		end,
	}

	m = menu[2][2]
	szText = {
		sformat(_L["Alpha:%s - %s meter"], LR.GetFullSizeNumber(0), LR.GetFullSizeNumber(distanceLevel[1])),
		sformat(_L["Alpha:%s - %s meter"], LR.GetFullSizeNumber(distanceLevel[1]), LR.GetFullSizeNumber(distanceLevel[2])),
		sformat(_L["Alpha:%s - %s meter"], LR.GetFullSizeNumber(distanceLevel[2]), LR.GetFullSizeNumber(distanceLevel[3])),
		sformat(_L["Alpha:%s v - Sync Range"], LR.GetFullSizeNumber(distanceLevel[3])),
		_L["Alpha:Out of Sync Range"]
	}
	for k, v in pairs (szText) do
		m[#m+1] = {	szOption = v, fnDisable = function() return LR_TeamGrid.UsrData.CommonSettings.backGroundAlphaType ~=  2 end,
			{	szOption = sformat(_L["%d Alpha , Click to change alpha"], distanceAlpha[k]),
				fnAutoClose = true,
				fnAction = function()
					GetUserInputNumber(distanceAlpha[k], 255, nil, function(value) distanceAlpha[k] = value end, nil, nil)
				end,
			}
		}
	end
	m[#m+1] = {bDevide = true}
	m[#m+1] = {szOption = _L["Reset alpha settings"], fnDisable = function() return LR_TeamGrid.UsrData.CommonSettings.backGroundAlphaType ~=  2 end,
		fnAction = function()
			LR_TeamGrid.ResetColorSettings()
			LR_TeamGrid.ReDrawAllMembers()
			LR_TeamGrid.SaveCommonData()
		end,
	}

	m = menu[2][3]
	szText = {
		sformat(_L["Level 1:(above %d%%)"], bloodLevelSet[1] * 100),
		sformat(_L["Level 2:(%d%% ~ %d%%)"], bloodLevelSet[1] * 100, bloodLevelSet[2] * 100),
		sformat(_L["Level 3:(under %d%%)"], bloodLevelSet[2] * 100),
	}
	for k, v in pairs(szText) do
		m[#m+1] = {szOption = v, fnDisable = function() return LR_TeamGrid.UsrData.CommonSettings.backGroundAlphaType ~=  3 end,
			{	szOption = sformat(_L["%d Alpha , Click to change alpha"], bloodLevelAlpha[k]),
				fnAutoClose = true,
				fnAction = function()
					GetUserInputNumber(distanceAlpha[k], 255, nil, function(value) bloodLevelAlpha[k] = value end, nil, nil)
				end,
			},
		}
	end

	return menu
end

function LR_TeamMenu.BuffMonitorMenu()
	local menu = {}
	local menu2
	menu[#menu+1] = {szOption = _L["Enable monitor debuffs"], bCheck = true, bMCheck = false, bChecked = function() return not LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bOff end,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bOff = not LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bOff
			LR_TeamGrid.SaveCommonData()
			if LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bOff then
				LR_TeamBuffMonitor.ClearAllNormalBuffCache()
			end
		end,
	}
	menu[#menu+1] = {bDevide = true}
	menu[#menu+1] = {szOption = _L["BuffMonitor num"], fnDisable = function() return LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bOff end,}
	menu2 = menu[#menu]
	for i = 1, 4, 1 do
		menu2[#menu2+1] = {szOption = sformat(_L["%d buff(s)"], i), bMCheck = true, bCheck = true,
			bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.buffMonitorNum == i end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.buffMonitorNum = i
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end

	menu[#menu+1] = {szOption = _L["BuffCD Settings"], fnDisable = function() return LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bOff end,}
	menu2 = menu[#menu]
	menu2[#menu2+1] = {szOption = _L["Show buffcd animation"], bCheck = true, bMCheck = false,
		bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bShowDebuffCDAni end,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bShowDebuffCDAni = not LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bShowDebuffCDAni
			LR_TeamGrid.SaveCommonData()
		end,
	}
	menu2[#menu2+1] = {szOption = _L["buffcd animation alpha"],
		fnDisable = function() return not LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bShowDebuffCDAni end,
		{szOption = sformat(_L["%d Alpha , Click to change alpha"], LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffCDAniAlpha),
			fnAction = function()
				GetUserInputNumber(LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffCDAniAlpha, 255, nil,
					function(value)
						LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffCDAniAlpha = value
						LR_TeamGrid.SaveCommonData()
					end, nil, nil)
			end,
		},
	}

	menu[#menu+1] = {szOption = _L["Debuff shadow settings"], fnDisable = function() return LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.bOff end,}
	menu2 = menu[#menu]
	menu2[#menu2+1] = {szOption = _L["Show buff shadow"],bCheck = true, bMCheck = false,
		bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffShadow.bShow end,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffShadow.bShow = not LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffShadow.bShow
			LR_TeamGrid.SaveCommonData()
		end,
	}
	local szOption = {"nBorder", "alpha"}
	local szText = {_L["Debuff shadow border"], _L["Debuff shadow alpha"]}
	local szText2 = {_L["%d Pixs, Click to change border width"], _L["%d Alpha , Click to change alpha"]}
	local nMax = {7, 255}
	for k, v in pairs(szOption) do
		menu2[#menu2+1] = {szOption = szText[k],
			fnDisable = function() return not LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffShadow.bShow end,
			{szOption = sformat(szText2[k], LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffShadow[v]),
				fnAction = function()
					GetUserInputNumber(LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffShadow[v], nMax[k], nil,
						function(value)
							LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.debuffShadow[v] = value
						end, nil, nil)
				end,
			}
		}
	end
	menu[#menu+1] = {szOption = sformat(_L["Set special buff bg alpha:%d"], LR_TeamGrid.UsrData.CommonSettings.nSpecialBuffAlpha or 120),
		fnAction = function()
			local fx, fy = this:GetAbsPos()
			GetUserInputNumber(LR_TeamGrid.UsrData.CommonSettings.nSpecialBuffAlpha or 120, 255, {fx, fy, 0, 0},
				function(value)
					LR_TeamGrid.UsrData.CommonSettings.nSpecialBuffAlpha = tonumber(value)
					LR_TeamGrid.SaveCommonData()
				end, nil, nil)
		end,
	}
	menu[#menu+1] = {bDevide = true,}
	szText = {_L["Show buff stack"], _L["Show buff remain time"]}
	local key = {"bShowStack", "bShowLeftTime"}
	for k, v in pairs(szText) do
		menu[#menu+1] = {szOption = v, bCheck = true, bMCheck = false, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.debuffMonitor[key[k]] end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.debuffMonitor[key[k]] = not LR_TeamGrid.UsrData.CommonSettings.debuffMonitor[key[k]]
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end
	menu[#menu+1] = {szOption = _L["Text position set"]}
	local mm = menu[#menu]
	local tText = {_L["Stack:RightBottom, Lefttime:LeftTop"], _L["Stack:LeftTop, Lefttime:RightBottom"]}
	for k, v in pairs(tText) do
		mm[#mm + 1] = {szOption = v, bCheck = true, bMCheck = true, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.buffTextType == k end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.buffTextType = k
				LR_TeamGrid.SaveCommonData()
			end,
		}
	end

	menu[#menu+1] = {szOption = _L["Buff arrange set"]}
	local mm = menu[#menu]
	local tText = {_L["Old style"], _L["New style 1"], _L["New style 2"]}
	local tTip = {_L["Old style tip"], _L["New style 1 tip"], _L["New style 2 tip"]}
	for k, v in pairs(tText) do
		mm[#mm + 1] = {szOption = v, bCheck = true, bMCheck = true, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.nBuffShowType == k end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.debuffMonitor.nBuffShowType = k
				LR_TeamGrid.SaveCommonData()
			end,
			fnMouseEnter = function()
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				local szXml = {}
				szXml[#szXml + 1] = GetFormatText(tTip[k])
				OutputTip(tconcat(szXml), 320, {x, y, w, h})
			end,
		}
	end

	menu[#menu+1] = {bDevide = true,}
	--menu[#menu+1] = {szOption = _L["Load default file"],fnAction = function() LR_TeamBuffSettingPanel.LoadDefaultData() end,}
	menu[#menu+1] = {szOption = _L["Open Buff Set Panel"],fnAction = function() LR_TeamBuffTool_Panel:Open() end,}
	return menu
end

function LR_TeamMenu.MenpaiCountMenu()
	local menu = {}
	local dwForceID = ALL_KUNGFU_COLLECT
	--local szForceName = {_L["ShaoLin"],_L["WanHua"],_L["TianCe"],_L["ChunYang"],_L["QiXiu"],_L["WuDu"],_L["TangMen"],_L["CangJian"],_L["GaiBang"],_L["MingJiao"],_L["CangYun"],_L["ChangGeMen"],_L["BaDao"],_L["DaXia"],}
	LR_TeamTools.Menpai.CheckMenpai()
	for k,v in pairs (dwForceID) do
		local szPath, nFrame = GetForceImage(v)
		if g_tStrings.tForceTitle[v] then
			menu[#menu+1] = {szOption = sformat(_L["[%s]:%2d people"], g_tStrings.tForceTitle[v] or "", LR_TeamTools.Menpai.Count[v] or 0), rgb = LR.MenPaiColor[v], szIcon = szPath, nFrame = nFrame, szLayer = "ICON_LEFT",}
		end
	end
	menu[#menu+1] = {bDevide = true}
	menu[#menu+1] = {szOption = _L["Publish to raid"],fnAction = function() LR_TeamTools.Menpai.OutputData() end,}
	return menu
end

function LR_TeamMenu.BloodDisplayMenu()
	local menu = {}
	local menu2 = LR_TeamMenu.LifeTextTypeMenu()
	for k, v in pairs(menu2) do
		menu[#menu+1] = v
	end

	menu[#menu+1] = {bDevide = true}
	menu2 = LR_TeamMenu.LifePercentSetMenu()
	for k, v in pairs(menu2) do
		menu[#menu+1] = v
	end

	menu[#menu+1] = {bDevide = true}
	menu[#menu+1] = {szOption =  _L["Blood automatically converted to percentage display in cure kungfu."] ,bMCheck =  false,bCheck = true, bChecked = function () return LR_TeamGrid.UsrData.CommonSettings.autoPercentInCure end,
		fnAction = function ()
			LR_TeamGrid.UsrData.CommonSettings.autoPercentInCure = not LR_TeamGrid.UsrData.CommonSettings.autoPercentInCure
			LR_TeamGrid.ReDrawAllMembers()
			LR_TeamGrid.SaveCommonData()
		end,}

	menu[#menu+1] = {bDevide = true}
	menu2 = LR_TeamMenu.ShortBloodMenu()
	for k, v in pairs (menu2) do
		menu[#menu+1] = v
	end

	menu[#menu+1] = {bDevide = true}
	menu[#menu+1] = {szOption = _L["Life/Mana danger set"], fnDisable = function() return true end, }
	local szText = {_L["Show Life Danger"], _L["Show Mana Danger"]}
	local szText2 = {_L["Life Danger Line:%d%%, Click to change"], _L["Mana Danger Line:%d%%, Click to change"]}
	local key = {"bShowLifeDanger", "bShowManaDanger"}
	local key2 = {"nLifeDanger", "nManaDanger"}
	for k, v in pairs(szText) do
		menu[#menu+1] = {szOption = v, bCheck = true, bMCheck = false, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings[key[k]] end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings[key[k]] = not LR_TeamGrid.UsrData.CommonSettings[key[k]]
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end,
			{szOption = sformat(szText2[k], LR_TeamGrid.UsrData.CommonSettings[key2[k]] * 100 ), fnDisable = function() return not LR_TeamGrid.UsrData.CommonSettings[key[k]] end,
				fnAction = function()
					GetUserInputNumber(LR_TeamGrid.UsrData.CommonSettings[key2[k]] *100 , 100, nil,
						function(value)
							LR_TeamGrid.UsrData.CommonSettings[key2[k]] = value/100
							LR_TeamGrid.ReDrawAllMembers()
							LR_TeamGrid.SaveCommonData()
						end, nil, nil)
				end
			},
		}
	end
	return menu
end

function LR_TeamMenu.QuickSetMenu()
	local menu = {}
	local menu2
	local menu3
	---名字颜色
	menu[#menu+1] = {szOption = _L["Color of name"],}
	menu3 = menu[#menu]
	menu2 = LR_TeamMenu.NameStyleMenu()
	for k,v in pairs (menu2) do
		menu3[#menu3+1] = v
	end

	menu3[#menu3+1] = {bDevide = true}
	menu2 = LR_TeamMenu.NameColoredMenu()
	for k,v in pairs (menu2) do
		menu3[#menu3+1] = v
	end

	menu3[#menu3+1] = {bDevide = true}
	menu2 = LR_TeamMenu.NameLimitMenu()
	menu3[#menu3+1] = menu2

	--心法显示
	menu[#menu+1] = {szOption = _L["Kungfu display"],}
	menu3 = menu[#menu]
	menu2 = LR_TeamMenu.KungfuDisplayMenu()
	for k,v in pairs (menu2) do
		menu3[#menu3+1] = v
	end

	--血量显示
	menu[#menu+1] = {szOption = _L["Blood display"],}
	menu3 = menu[#menu]
	menu2 = LR_TeamMenu.BloodDisplayMenu()
	for k,v in pairs (menu2) do
		menu3[#menu3+1] = v
	end
	return menu
end

function LR_TeamMenu.MouseActionMenu()
	local m  = {}
	m[#m+1] = {szOption = _L["The following instructions for mouse"],fnDisable = function() return true end,}
	m[#m+1] = {szOption = _L["Hover"],
		{szOption = _L["*Show Target Tip"]},
		{bDevide = true,},
		{szOption = _L["Enable quick choose when in cure kungfu"],fnDisable = function() return true end,},
		{szOption = _L["*Auto select target"],},}
	--m[#m+1] = {szOption = _L["Alt+Hover"],{szOption = _L["*Show target DPS/HPS"]},}
	--m[#m+1] = {szOption = _L["Shift+Hover"],{szOption = _L["*Show dead record/debug"]},}
	m[#m+1] = {szOption = _L["Left Click"],{szOption = _L["*Select this target"]},}
	m[#m+1] = {szOption = _L["Right Click"],{szOption = _L["*Popup menu"]},}
	m[#m+1] = {szOption = _L["Drag"],{szOption = _L["*Change member group"]},}
	m[#m+1] = {bDevide = true,}
	m[#m+1] = {szOption = _L["The following are optional"],fnDisable = function() return true end,}
	m[#m+1] = {szOption = _L["Left Double Click"],
		{szOption = _L["*No operation"],bCheck = true,bMCheck = true,bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.mouseAction.LButtonDBClick == 0 end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.mouseAction.LButtonDBClick = 0
				LR_TeamGrid.SaveCommonData()
			end,},
		{szOption = _L["Follow"],bCheck = true,bMCheck = true,bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.mouseAction.LButtonDBClick == 1 end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.mouseAction.LButtonDBClick = 1
				LR_TeamGrid.SaveCommonData()
			end,},
	}
	m[#m+1] = {szOption = _L["Alt+Left Double Click"],
		{szOption = _L["*No operation"],bCheck = true,bMCheck = true,bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.mouseAction.LButtonDBClickAlt == 0 end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.mouseAction.LButtonDBClickAlt = 0 ;
				LR_TeamGrid.SaveCommonData()
			end,},
		{szOption = _L["Trade"],bCheck = true,bMCheck = true,bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.mouseAction.LButtonDBClickAlt == 1 end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.mouseAction.LButtonDBClickAlt = 1 ;
				LR_TeamGrid.SaveCommonData()
			end,},
	}
	m[#m+1] = {szOption = _L["Alt+Mouse Hover"],
		{szOption = _L["*No operation"],bCheck = true,bMCheck = true,bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.mouseAction.MouseEnterAlt == 0 end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.mouseAction.MouseEnterAlt = 0 ;
				LR_TeamGrid.SaveCommonData()
			end,},
		{szOption = _L["*Show target DPS/HPS"],bCheck = true,bMCheck = true,bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.mouseAction.MouseEnterAlt == 1 end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.mouseAction.MouseEnterAlt = 1 ;
				LR_TeamGrid.SaveCommonData()
			end,},
	}
	m[#m+1] = {szOption = _L["Shift+Mouse Hover"],
		{szOption = _L["*No operation"],bCheck = true,bMCheck = true,bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.mouseAction.MouseEnterShift == 0 end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.mouseAction.MouseEnterShift = 0 ;
				LR_TeamGrid.SaveCommonData()
			end,},
		{szOption = _L["*Show dead record/debug"],bCheck = true,bMCheck = true,bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.mouseAction.MouseEnterShift == 1 end,
			fnAction = function()
				LR_TeamGrid.UsrData.CommonSettings.mouseAction.MouseEnterShift = 1 ;
				LR_TeamGrid.SaveCommonData()
			end,},
	}
	return m
end

function LR_TeamMenu.IsDistanceDisable(nLevel,nDis)
	local distanceLevel = LR_TeamGrid.UsrData.CommonSettings.distanceLevel
	if nLevel == 1 then
		if nDis <=  distanceLevel[2] then
			return true
		end
	elseif nLevel == 2 then
		if nDis >=  distanceLevel[1] and nDis <=  distanceLevel[3] then
			return true
		end
	elseif nLevel == 3 then
		if nDis <=  50 and nDis > distanceLevel[2] then
			return true
		end
	end
	return false
end

function LR_TeamMenu.PopOptions()
	local tOptions = {}
	local menu
	tOptions[#tOptions+1] = {szOption = _L["Config Debuff monitor settings"], fnAction = function() LR_TeamBuffTool_Panel:Open() end}
	tOptions[#tOptions+1] =  {szOption = _L["Clear Panel"], fnAction = function()
		LR_TeamBuffMonitor.ClearAllNormalBuffCache()
		LR_TeamBuffMonitor.ClearAllCache()
		LR_TeamGrid.ReDrawAllMembers(true)
	end}
	tOptions[#tOptions+1] = {szOption = _L["Check role progress"],
		fnAction = function()
			if LR_CDRP then
				LR_CDRP.OpenFrame()
			else
				LR.SysMsg(_L["Please install lr cdrp\n"])
			end
		end,
	}
	if LR_TeamGrid.IsLeader(GetClientPlayer().dwID) then
		--团确
		tOptions[#tOptions+1] = {bDevide = true}
		tOptions[#tOptions+1] = {szOption = _L["Position confirmation"]}
		menu = tOptions[#tOptions]
		menu[#menu+1] = {szOption = _L["Start position confirmation"], bCheck = false, bChecked = false,
			fnAction = function()
				local tMsg  =
				{
					szMessage = g_tStrings.STR_RAID_MSG_START_READY_CONFIRM,
					szName = "StartReadyConfirm",
					{szOption = g_tStrings.STR_HOTKEY_SURE,
						fnAction = function()
							LR_TeamGrid.StartReadyConfirmCheck()
							Send_RaidReadyConfirm()
						end,},
					{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
				}
				MessageBox(tMsg)
			end,
			fnDisable = function()
				return not LR_TeamGrid.IsLeader(GetClientPlayer().dwID)
			end,
		}
		menu[#menu+1] = {szOption = _L["Reset position confirmation"], bCheck = false, bChecked = false,
			fnAction = function()
				GetPopupMenu():Hide()
				LR_TeamGrid.ClearReadyConfirm()
			end,
			fnDisable = function()
				return not LR_TeamGrid.IsLeader(GetClientPlayer().dwID)
			end,
		}
		--世界标记
		tOptions[#tOptions+1] = {bDevide = true}
		tOptions[#tOptions+1] = {szOption = _L["Open world sign panel"], bCheck = false, bChecked = false,
			fnDisable  = function()
				return not LR_TeamGrid.IsLeader(GetClientPlayer().dwID)
			end,
			fnAction = function()
				Wnd.ToggleWindow("WorldMark")
			end,
		}
		--分配
		tOptions[#tOptions+1] = {bDevide = true}
		InsertDistributeMenu(tOptions, not LR_TeamGrid.IsLeader(GetClientPlayer().dwID))
	end
	--治疗模式
	tOptions[#tOptions+1] = {szOption = _L["Correlation with cure"],}
	menu = LR_TeamMenu.CureModeMenu()
	for k,v in pairs(menu) do
		tOptions[#tOptions][#tOptions[#tOptions]+1] = v
	end
	--团队人数统计
	tOptions[#tOptions+1] = {szOption = _L["Count of school members"],}
	menu = LR_TeamMenu.MenpaiCountMenu()
	for k,v in pairs(menu) do
		tOptions[#tOptions][#tOptions[#tOptions]+1] = v
	end
	--锁定位置
	tOptions[#tOptions+1] = {bDevide = true}
	tOptions[#tOptions+1] = {szOption = _L["Lock Position"], bCheck = true, bMCheck = false, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.bLockLocation end,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.bLockLocation = not LR_TeamGrid.UsrData.CommonSettings.bLockLocation
			local frame = Station.Lookup("Normal/LR_TeamGrid")
			if frame then
				if LR_TeamGrid.UsrData.CommonSettings.bLockLocation  then
					frame:EnableDrag(false)
				else
					frame:EnableDrag(true)
				end
			end
			LR_TeamGrid.SaveCommonData()
		end,
	}
	--锁定分组
	tOptions[#tOptions+1] = {szOption = _L["Lock Group"], bCheck = true, bMCheck = false, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.bLockGroup end,
		fnAction = function()
			LR_TeamGrid.UsrData.CommonSettings.bLockGroup = not LR_TeamGrid.UsrData.CommonSettings.bLockGroup
			LR_TeamGrid.SaveCommonData()
		end,
	}
	--快速设置
	tOptions[#tOptions+1] = {bDevide = true,}
	tOptions[#tOptions+1] = {szOption = _L["Quick Set"],}
	menu = LR_TeamMenu.QuickSetMenu()
	for k,v in pairs(menu) do
		tOptions[#tOptions][#tOptions[#tOptions]+1] = v
	end
	tOptions[#tOptions+1] = {szOption = _L["Interface scale"]}
	local tscale = tOptions[#tOptions]
	local tscaleOption = {_L["fx Scale"], _L["fy Scale"]}
	local key = {"fx", "fy"}
	for k, v in pairs(tscaleOption) do
		tscale[#tscale+1] = {szOption = v}
		local menu = tscale[#tscale]
		for i = 0.5, 2, 0.1 do
			menu[#menu+1] = {szOption = i, bCheck = true, bMCheck = true, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.scale[key[k]] == i end,
				fnAction = function()
					LR_TeamGrid.UsrData.CommonSettings.scale[key[k]] = i
					LR_TeamGrid.ReDrawAllMembers(true)
					LR_TeamGrid.SaveCommonData()
				end,
			}
		end
	end

	--更多设置
	tOptions[#tOptions+1] = {szOption = _L["More settings"],bCheck = false, bChecked = false,
		fnAction = function()
			LR_TOOLS:OpenPanel(_L["Team Grid"])
		end
	}

	local player = GetClientPlayer()
	if not player then
		return
	end
	local scene = player.GetScene()
	if not scene then
		return
	end
	local SceneInfo = {}
	SceneInfo.dwID = scene.dwID
	SceneInfo.nType = scene.nType
	SceneInfo.szName = scene.szName
	SceneInfo.dwMapID = scene.dwMapID
	SceneInfo.nCopyIndex = scene.nCopyIndex
	if SceneInfo.nType == MAP_TYPE.DUNGEON then
		tinsert(tOptions,{bDevide = true})
		tinsert(tOptions,{szOption = SceneInfo.szName ,rgb = {192,192,192},bCheck = false,fnAutoClose = function() return false end,})
		if LR_AccountStatistics_FBList and LR_AccountStatistics_FBList.SelfFBList then
			if LR_AccountStatistics_FBList.SelfFBList.tCopyID[SceneInfo.dwMapID] and LR_AccountStatistics_FBList.SelfFBList.tCopyID[SceneInfo.dwMapID][1] then
				tinsert(tOptions,{szOption = sformat("CD：%d", LR_AccountStatistics_FBList.SelfFBList.tCopyID[SceneInfo.dwMapID][1]), rgb = {192,192,192},bCheck = false,})
			else
				tinsert(tOptions,{szOption = sformat("ID：%d", SceneInfo.nCopyIndex), rgb = {192,192,192},bCheck = false,fnAutoClose = function() return false end,})
				tinsert(tOptions,{szOption = _L["CD:None"],rgb = {192,192,192},bCheck = false,})
			end
		else
			tinsert(tOptions,{szOption = sformat("ID：%d", SceneInfo.nCopyIndex) ,rgb = {192,192,192},bCheck = false,fnAutoClose = function() return false end,})
			tinsert(tOptions,{szOption = _L["CD:(Require LR_AccountStatistics)"], rgb = {192,192,192},bCheck = false,fnAutoClose = function() return false end,})
		end
		if LR.BlackFBList and LR.BlackFBList[SceneInfo.dwMapID] and LR.BlackFBList[SceneInfo.dwMapID][SceneInfo.nCopyIndex] then
			local szName = LR.BlackFBList[SceneInfo.dwMapID][SceneInfo.nCopyIndex].szName
			tinsert(tOptions,{szOption = sformat(_L["Black:%s"],szName), rgb = {192,192,192},bCheck = false,fnAutoClose = function() return false end,})
		end
	else
		tinsert(tOptions,{bDevide = true})
		tinsert(tOptions,{szOption = SceneInfo.szName,rgb = {192,192,192},bCheck = false,fnAutoClose = function() return false end,})
	end

	PopupMenu(tOptions)
end
