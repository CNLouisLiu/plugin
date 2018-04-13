local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_RaidGridEx"
local SaveDataPath="Interface\\LR_Plugin@DATA\\LR_TeamGrid"
local _L = LR.LoadLangPack(AddonPath)
------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("Normal") then
	tinsert (LR_TOOLS.tAddonClass,{"Normal",_L["plugins"],"2"})
end

local LR_TeamGrid_UI ={
	szName="LR_TeamGrid",
	szTitle=_L["LR_TeamGrid"],
	dwIcon = 6270,
	szClass = "Normal",
	tWidget = {
		{	name="LR_TeamGrid_UI_ch01",type="CheckBox",text=_L["Enalbe LR_RaidGridEx"],x=0,y=0,w=200,
			default = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function (enabled)
				LR_TeamGrid.bOn = enabled
				LR_TeamGrid.SwitchPanel()
				LR_TeamGrid.SaveCommonData()
			end
		},{	name="LR_TeamGrid_UI_te01",type="Text",x=5,y=25,w=40,h=28,text="©»",font=22,
		},{	name="LR_TeamGrid_UI_SysRaidPan",type="CheckBox",text=_L["Enable System Grid Panel"],x=25,y=25,w=200,
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			default = function ()
				return LR_TeamGrid.UsrData.CommonSettings.bShowSystemGridPanel
			end,
			callback = function (enabled)
				LR_TeamGrid.UsrData.CommonSettings.bShowSystemGridPanel = enabled
				LR_TeamGrid.SwitchSystemRaidPanel()
				LR_TeamGrid.SaveCommonData()
			end
		},{	name="LR_TeamGrid_UI_te02",type="CheckBox",text=_L["Enable When in Team"],x = 200, y = 0,w = 200,
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			default = function ()
				return not LR_TeamGrid.UsrData.CommonSettings.bShowOnlyInRaidMode
			end,
			callback = function (enabled)
				LR_TeamGrid.UsrData.CommonSettings.bShowOnlyInRaidMode = not enabled
				LR_TeamGrid.SwitchPanel()
				LR_TeamGrid.SaveCommonData()
			end
		},{	name="LR_TeamGrid_UI_te03", type = "Text", x = 205, y = 25, w = 40, h = 28, text = "©»", font = 22,
		},{	name="LR_TeamGrid_UI_SysTeamPan", type = "CheckBox", text = _L["Enable System Team Panel"], x = 225, y = 25, w = 200,
			enable = function ()
				return LR_TeamGrid.bOn and not LR_TeamGrid.UsrData.CommonSettings.bShowOnlyInRaidMode
			end,
			default = function ()
				return LR_TeamGrid.UsrData.CommonSettings.bShowSystemTeamPanel
			end,
			callback = function (enabled)
				LR_TeamGrid.UsrData.CommonSettings.bShowSystemTeamPanel = enabled
				LR_TeamGrid.SwitchSystemTeamPanel()
				LR_TeamGrid.SaveCommonData()
			end
		},{	name="LR_TeamGrid_UI_GridType", type = "ComboBox", text = _L["Choose GridType"],x = 360, y = 0, w = 140,
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function (m)
				local szOption = {_L["1Row(5Col)"], _L["2Row(3Col+2Col)"]}
				for k, v in pairs(szOption) do
					m[#m + 1] = {szOption = v, bCheck = true, bMCheck = true, bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.nGridType == k end,
						fnAction = function()
							LR_TeamGrid.UsrData.CommonSettings.nGridType = k
							LR_TeamGrid.SaveCommonData()
							LR_TeamGrid.ReDrawAllMembers(true)
						end,
					}
				end
				PopupMenu(m)
			end,
		},{	name="LR_TeamGrid_UI_ChooseUI",type="ComboBox",text=_L["Choose UI"],x=0,y=60,w=180,
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function (m)
				LR_TeamGrid.LoadUIList()
				for k, v in pairs (LR_TeamGrid.UIList) do
					m[#m+1] = {szOption = v.cnName, bCheck = true, bMCheck = true, bChecked = function() return LR_TeamGrid.UsrData.UI_Choose == v.szName end,
						fnAction = function()
							LR_TeamBuffMonitor.ClearAllCache()
							LR_TeamGrid.ClosePanel()
							LR_TeamGrid.UsrData.UI_Choose = v.szName
							LR_TeamGrid.SaveCommonData()
							LR_TeamGrid.LoadUIConfig()
							LR_TeamGrid.SwitchPanel()
						end,
					}
				end
				PopupMenu(m)
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["UI choose Instructions:\n"], font = 17, r = 255, g = 127, b = 39,}
				tTips[#tTips+1] = {szText = _L["UI choose Instructions01\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["UI choose Instructions02\n"], font = 5, r = 255, g = 255, b = 255,}
				return tTips
			end,
		},{name="LR_TeamGrid_UI_Rehelp",type="Button",x=190,y=60,text=_L["TeamGrid UI Help"],w=280,
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function()
				OpenBrowser("http://t.cn/RXityvX")
			end,
		},{	name="LR_TeamGrid_UI_NameSet",type="ComboBox",x=0,y=90,w=180,text=_L["Team member name settings"],
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function(m)
				local menu={}
				local menu2=LR_TeamMenu.NameStyleMenu()
				for k,v in pairs (menu2) do
					menu[#menu+1]=v
				end

				menu[#menu+1]={bDevide = true}
				menu2=LR_TeamMenu.NameColoredMenu()
				for k,v in pairs (menu2) do
					menu[#menu+1]=v
				end

				menu[#menu+1]={bDevide = true}
				menu2=LR_TeamMenu.NameLimitMenu()
				menu[#menu+1]=menu2

				menu[#menu+1]={bDevide = true}
				menu[#menu+1]={szOption = _L["Set Font Spacing"]}
				menu2 = menu[#menu]
				for i = -5, 5, 1 do
					menu2[#menu2+1] = {	szOption=sformat(" %3d", i), bCheck = true, bMCheck = true,
						bChecked = function() return LR_TeamGrid.UsrData.CommonSettings.nameFontSpacing == i end,
						fnAction = function()
							LR_TeamGrid.UsrData.CommonSettings.nameFontSpacing = i
							LR_TeamGrid.ReDrawAllMembers()
							LR_TeamGrid.SaveCommonData()
						end,
					}
				end

				for k,v in pairs(menu) do
					m[#m+1]=v
				end
				PopupMenu(m)
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["Team member name Instructions:\n"], font = 17, r = 255, g = 127, b = 39,}
				tTips[#tTips+1] = {szText = _L["Team member name Instructions01\n"], font = 5, r = 255, g = 255, b = 255,}
				return tTips
			end,
		},{	name="LR_TeamGrid_UI_te05",type="Text",x=190,y=92,w=40,h=28,text=_L["Scale1"],font=5,
		},{	name="LR_TeamGrid_UI_NameScale",type="CSlider",min=0.5,max=2,x=290,y=90,w=210,step=15,unit="",
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			default = function ()
				return LR_TeamGrid.UsrData.CommonSettings.nameTextScale
			end,
			callback = function (value)
				LR_TeamGrid.UsrData.CommonSettings.nameTextScale = value
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end
		},{	name="LR_TeamGrid_UI_Kungfu",type="ComboBox",x=0,y=120,w=180,text=_L["Kungfu Display"],
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function(m)
				local menu=LR_TeamMenu.KungfuDisplayMenu()
				for k, v in pairs(menu) do
					m[k]=v
				end
				PopupMenu(m)
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["Kungfu Instructions:\n"], font = 17, r = 255, g = 127, b = 39,}
				tTips[#tTips+1] = {szText = _L["Kungfu Instructions01\n"], font = 5, r = 255, g = 255, b = 255,}
				return tTips
			end,
		},{	name="LR_TeamGrid_UI_te04",type="Text",x=190,y=122,w=40,h=28,text=_L["Scale2"],font=5,
		},{	name="LR_TeamGrid_UI_KungfuScale",type="CSlider",min=0.5,max=2,x=290,y=120,w=210,step=15,unit="",
			enable = function ()
				return (LR_TeamGrid.bOn and LR_TeamGrid.UsrData.CommonSettings.kungFuShowType == 2)
			end,
			default = function ()
				return LR_TeamGrid.UsrData.CommonSettings.kungFuTextScale
			end,
			callback = function (value)
				LR_TeamGrid.UsrData.CommonSettings.kungFuTextScale = value
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end
		},{	name="LR_TeamGrid_UI_BloodSet",type="ComboBox",x=0,y=150,w=180,text=_L["Blood display settings"],
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function(m)
				local menu = LR_TeamMenu.BloodDisplayMenu()
				for i=1,#menu,1 do
					tinsert(m,menu[i])
				end
				PopupMenu(m)
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["Blood Instructions:\n"], font = 17, r = 255, g = 127, b = 39,}
				tTips[#tTips+1] = {szText = _L["Blood Instructions01\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["Blood Instructions02\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["Blood Instructions03\n"], font = 5, r = 255, g = 255, b = 255,}
				return tTips
			end,
		},{	name="LR_TeamGrid_UI_te06",type="Text",x=190,y=152,w=40,h=28,text=_L["Scale3"],font=5,
		},{	name="LR_TeamGrid_UI_BloodScale",type="CSlider",min=0.5,max=2,x=290,y=150,w=210,step=15,unit="",
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			default = function ()
				return LR_TeamGrid.UsrData.CommonSettings.bloodTextScale
			end,
			callback = function (value)
				LR_TeamGrid.UsrData.CommonSettings.bloodTextScale = value
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end
		},{	name="LR_TeamGrid_UI_DebuffSet",type="ComboBox",x=0,y=180,w=180,text=_L["BuffMonitor Settings"],
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function(m)
				local menu = LR_TeamMenu.BuffMonitorMenu()
				for k,v in pairs(menu) do
					m[#m+1]=v
				end
				PopupMenu(m)
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["BuffMonitor Instructions:\n"], font = 17, r = 255, g = 127, b = 39,}
				tTips[#tTips+1] = {szText = _L["BuffMonitor Instructions01\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["BuffMonitor Instructions02\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["BuffMonitor Instructions03\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["BuffMonitor Instructions04\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["BuffMonitor Instructions05\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["BuffMonitor Instructions06\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["BuffMonitor Instructions07\n"], font = 5, r = 255, g = 255, b = 255,}
				return tTips
			end,
		},{	name="LR_TeamGrid_UI_fxsc_1",type="Text",x=190,y=182,w=40,h=28,text=_L["fx Scale"],font=5,
		},{	name="LR_TeamGrid_UI_fxsc_2",type="CSlider",min=0.5,max=2,x=290,y=180,w=210,step=15,unit="",
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			default = function ()
				return LR_TeamGrid.UsrData.CommonSettings.scale.fx
			end,
			callback = function (value)
				LR_TeamGrid.UsrData.CommonSettings.scale.fx = value
				LR_TeamGrid.ReDrawAllMembers(true)
				LR_TeamGrid.SaveCommonData()
			end
		},{	name="LR_TeamGrid_UI_fysc_1",type="Text",x=190,y=212,w=40,h=28,text=_L["fy Scale"],font=5,
		},{	name="LR_TeamGrid_UI_fysc_2",type="CSlider",min=0.5,max=2,x=290,y=210,w=210,step=15,unit="",
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			default = function ()
				return LR_TeamGrid.UsrData.CommonSettings.scale.fy
			end,
			callback = function (value)
				LR_TeamGrid.UsrData.CommonSettings.scale.fy = value
				LR_TeamGrid.ReDrawAllMembers(true)
				LR_TeamGrid.SaveCommonData()
			end
		},{	name="LR_TeamGrid_UI_BackColSet",type="ComboBox",x=0,y=210,w=180,text=_L["BloodBar color/alpha settings"],
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function(m)
				local menu= LR_TeamMenu.BloodBarSetMenu()
				for k,v in pairs(menu) do
					m[#m+1]=v
				end
				PopupMenu(m)
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["Distance Instructions:\n"], font = 17, r = 255, g = 127, b = 39,}
				tTips[#tTips+1] = {szText = _L["Distance Instructions01\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["Distance Instructions02\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["Distance Instructions03\n"], font = 5, r = 255, g = 255, b = 255,}
				return tTips
			end,
		},{	name="LR_TeamGrid_UI_MouseAction",type="ComboBox",x=0,y=240,w=180,text=_L["Mouse operation instructions and settings"],
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function(m)
				local menu = LR_TeamMenu.MouseActionMenu()
				for k, v in pairs(menu) do
					m[#m+1]=v
				end
				PopupMenu(m)
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["Mouse Instructions:\n"], font = 17, r = 255, g = 127, b = 39,}
				tTips[#tTips+1] = {szText = _L["Mouse Instructions01\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["Mouse Instructions02\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["Mouse Instructions03\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["Mouse Instructions04\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["Mouse Instructions05\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["Mouse Instructions06\n"], font = 5, r = 255, g = 255, b = 255,}
				return tTips
			end,
		},{	name="LR_TeamGrid_UI_SysMemberTip",type="CheckBox",text=_L["Enable new type of tip"], x=190,y=240,w=200,
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			default = function ()
				return LR_TeamGrid.UsrData.CommonSettings.bShowNewTip
			end,
			callback = function (enabled)
				LR_TeamGrid.UsrData.CommonSettings.bShowNewTip = enabled
				LR_TeamGrid.SaveCommonData()
			end
		},{	name="LR_TeamGrid_UI_DisableTipFight",type="CheckBox",text=_L["Disable tip when fight"], x=330,y=240,w=200,
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			default = function ()
				return LR_TeamGrid.UsrData.CommonSettings.disableTipWhenFight
			end,
			callback = function (enabled)
				LR_TeamGrid.UsrData.CommonSettings.disableTipWhenFight = enabled
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end
		},{	name="LR_TeamGrid_UI_CureSet",type="ComboBox",x=0,y=270,w=180,text=_L["Correlation with cure"],
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function(m)
				local menu=LR_TeamMenu.CureModeMenu()
				for k, v in pairs(menu) do
					m[k]=v
				end
				PopupMenu(m)
			end,
			Tip = function()
				local tTips = {}
				tTips[#tTips+1] = {szText = _L["Cure Instructions:\n"], font = 17, r = 255, g = 127, b = 39,}
				tTips[#tTips+1] = {szText = _L["Cure Instructions01\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["Cure Instructions02\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["Cure Instructions03\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["Cure Instructions04\n"], font = 5, r = 255, g = 255, b = 255,}
				tTips[#tTips+1] = {szText = _L["Cure Instructions05\n"], font = 5, r = 255, g = 255, b = 255,}
				return tTips
			end,
		},{	name="LR_TeamGrid_UI_EnableTeamNum",type="CheckBox",text=_L["Enable group num display"], x=190,y=270,w=200,
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			default = function ()
				return not LR_TeamGrid.UsrData.CommonSettings.bDisableTeamNum
			end,
			callback = function (enabled)
				LR_TeamGrid.UsrData.CommonSettings.bDisableTeamNum = not enabled
				LR_TeamGrid.ReDrawAllMembers()
				LR_TeamGrid.SaveCommonData()
			end
		},{	name="LR_TeamGrid_UI_DistributeWarn",type="CheckBox",text=_L["Enable distribute warn"], x=350,y=270,w=200,
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			default = function ()
				return LR_TeamGrid.UsrData.CommonSettings.bShowDistributeWarn
			end,
			callback = function (enabled)
				LR_TeamGrid.UsrData.CommonSettings.bShowDistributeWarn = enabled
				LR_TeamGrid.SaveCommonData()
			end
		},{	name = "LR_TeamGrid_UI_EdgeIndicator", type = "Button", x = 0, y = 340, text = _L["Open EdgeIndicator"], w = 120,
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function()
				LR_EdgeIndicator_Panel.OpenFrame()
			end
		},{	name = "LR_TeamGrid_UI_Buff_tools", type = "Button", x = 140, y = 340, text = _L["Open Buff Tools"], w = 120,
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function()
				LR_TeamBuffTool_Panel:Open()
			end
		},{	name = "LR_TeamGrid_UI_co13", type="ComboBox", text = _L["Control Panel Set"], x = 270, y = 340, w = 160,
			default = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function(m)
				local szOption = {"ShowLootModeBtn", "ShowLootLevelBtn", "ShowWorldMarkBtn", "ShowGoldTeamBtn", "ShowTeamNoticeBtn", "ShowVoiceBtn", "ShowMiniBtn"}

				for k, v in pairs(szOption) do
					m[#m + 1] = { szOption = _L[v], bCheck = true, bMCheck = false,
						bChecked = function()
							return LR_TeamGrid.UsrData.CommonSettings.TitleButton[v]
						end,
						fnAction = function()
							LR_TeamGrid.UsrData.CommonSettings.TitleButton[v] = not LR_TeamGrid.UsrData.CommonSettings.TitleButton[v]
							LR_TeamGrid.SaveCommonData()
							LR_TeamGrid.ListButtons()
						end,
					}
				end
				PopupMenu(m)
			end,
		},{	name="LR_TeamGrid_UI_Reset",type="Button",x = 450, y = 340, text = _L["Reset settings"],
			enable = function ()
				return LR_TeamGrid.bOn
			end,
			callback = function()
				LR_TeamGrid.ResetCommonData()
				LR_TeamGrid.LoadUIConfig()
				LR_TeamGrid.SwitchPanel()
				LR_TeamGrid.ReDrawAllMembers(true)
				LR_TeamGrid.SaveCommonData()
				LR_TOOLS:OpenPanel(_L["LR_TeamGrid"])
			end
		},{	name="LR_TeamGrid_UI_Help",type="Text",x=0,y=310,w=40,h=28,text=_L["TeamGrid UI Help2"],font=61,
		}
	}
}
LR_TOOLS:RegisterPanel(LR_TeamGrid_UI)

-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
LR_TOOLS.menu=LR_TOOLS.menu or {}
LR_TeamGrid_UI.menu = {
	szOption =_L["LR_TeamGrid"],
	--rgb = {255, 255, 255},
	fnAction = function()
		LR_TeamGrid.bOn = not LR_TeamGrid.bOn
		LR_TeamGrid.SwitchPanel()
		LR_TeamGrid.SaveCommonData()
	end,
	bCheck=true,
	bMCheck=false,
	rgb = {255, 255, 255},
	bChecked = function()
		return LR_TeamGrid.bOn
	end,
	fnAutoClose=true,
	szIcon = "ui\\Image\\UICommon\\CommonPanel2.UITex",
	nFrame =105,
	nMouseOverFrame = 106,
	szLayer = "ICON_RIGHT",
	fnAutoClose=true,
	fnClickIcon = function ()
		LR_TOOLS:OpenPanel(_L["LR_TeamGrid"])
	end,
}
LR_TeamGrid_UI.secondmenu1 = {
	szOption=_L["Enable When in Team"],
	bCheck=true,
	bMCheck=false,
	bChecked= function ()
		return not LR_TeamGrid.UsrData.CommonSettings.bShowOnlyInRaidMode
	end,
	fnAction = function ()
		LR_TeamGrid.UsrData.CommonSettings.bShowOnlyInRaidMode = not LR_TeamGrid.UsrData.CommonSettings.bShowOnlyInRaidMode
		LR_TeamGrid.SwitchPanel()
		LR_TeamGrid.SaveCommonData()
	end,
	fnDisable= function ()
		return not LR_TeamGrid.bOn
	end,
}
LR_TeamGrid_UI.secondmenu2 = {
	szOption=_L["Enable System Team Panel"],
	bCheck=true,
	bMCheck=false,
	bChecked= function ()
		return LR_TeamGrid.UsrData.CommonSettings.bShowSystemTeamPanel
	end,
	fnAction = function ()
		LR_TeamGrid.UsrData.CommonSettings.bShowSystemTeamPanel = not LR_TeamGrid.UsrData.CommonSettings.bShowSystemTeamPanel
		LR_TeamGrid.SwitchSystemTeamPanel()
		LR_TeamGrid.SaveCommonData()
	end,
	fnDisable= function ()
		return not LR_TeamGrid.bOn
	end,
}
LR_TeamGrid_UI.secondmenu3 = {
	szOption=_L["Enable System Grid Panel"],
	bCheck=true,
	bMCheck=false,
	bChecked= function ()
		return LR_TeamGrid.UsrData.CommonSettings.bShowSystemGridPanel
	end,
	fnAction = function ()
		LR_TeamGrid.UsrData.CommonSettings.bShowSystemGridPanel = not LR_TeamGrid.UsrData.CommonSettings.bShowSystemGridPanel
		LR_TeamGrid.SwitchSystemRaidPanel()
		LR_TeamGrid.SaveCommonData()
	end,
	fnDisable= function ()
		return not LR_TeamGrid.bOn
	end,
}
tinsert(LR_TeamGrid_UI.menu,LR_TeamGrid_UI.secondmenu1)
tinsert(LR_TeamGrid_UI.menu,LR_TeamGrid_UI.secondmenu2)
tinsert(LR_TeamGrid_UI.menu,LR_TeamGrid_UI.secondmenu3)
tinsert(LR_TOOLS.menu,LR_TeamGrid_UI.menu)

