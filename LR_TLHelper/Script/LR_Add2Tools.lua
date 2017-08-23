local sformat, slen, sgsub, ssub,sfind = string.format, string.len, string.gsub, string.sub, string.find
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_TLHelper"
local _L = LR.LoadLangPack(AddonPath)
----------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("Normal") then
	tinsert (LR_TOOLS.tAddonClass,{"Normal",_L["Plugins"],"1"})
end

local LR_TLHelper_UI ={
	szName="LR_TLHelper_UI",
	szTitle=_L["TL Helper"],
	dwIcon = 3289,
	szClass = "Normal",
	tWidget = {
		{
			name="LR_TLHelper_UIcheck_box",type="CheckBox",text=_L["Enable TL Helper"],x=0,y=0,w=200,
			enable = function ()
				if LR.GetXinFa() == Table_GetSkillName(10225,1) then	---xinfa=="天罗诡道"
					return true
				else
					return false
				end
			end,
			default = function ()
				return LR_TLHelper.UsrData.on
			end,
			callback = function (enabled)
				LR_TLHelper.UsrData.on=enabled
				if LR_TLHelper.UsrData.on==true then
					Wnd.OpenWindow("Interface\\LR_Plugin\\LR_TLHelper\\UI\\LR_TLHelper.ini", "LR_TLHelper")
					LR_TLHelper.FrameLastTime=GetLogicFrameCount()
					--LR_TLHelper.ScaleFont ()
				else
					Wnd.CloseWindow("LR_TLHelper")
				end
			end
		},{
			name="LR_TLHelper_UItext1",type="Text",x=0,y=40,w=80,h=28,text=_L["Set Alpha"],font=5,
		},{
			name="LR_TLHelper_UI_Alpha",type="CSlider",min=50,max=100,x=0,y=60,w=200,step=50,unit="%",
			enable = function ()
				if LR_TLHelper.UsrData.on and LR.GetXinFa() == Table_GetSkillName(10225,1) then
					return true
				else
					return false
				end
			end,
			default = function ()
				return LR_TLHelper.UsrData.Alpha
			end,
			callback = function (value)
				LR_TLHelper.UsrData.Alpha=value
				--LR_TLHelper.QJB.Box_Img:SetAlpha(255*LR_TLHelper.UsrData.Alpha/100)
				LR_TLHelper.MainFrame:SetAlpha(255*LR_TLHelper.UsrData.Alpha/100)
			end
		},{
			name="LR_TLHelper_UItext2",type="Text",x=0,y=100,w=80,h=28,text=_L["Set Scale"],font=5,
		},{
			name="LR_TLHelper_UI_Scale",type="CSlider",min=50,max=150,x=0,y=120,w=200,step=100,unit="%",
			enable = function ()
				if LR_TLHelper.UsrData.on and LR.GetXinFa() == Table_GetSkillName(10225,1) then
					return true
				else
					return false
				end
			end,
			default = function ()
				return LR_TLHelper.UsrData.Scale*100
			end,
			callback = function (value)
				LR_TLHelper.MainFrame:Scale(1/LR_TLHelper.UsrData.Scale*value/100,1/LR_TLHelper.UsrData.Scale*value/100)
				--Output(value)
				LR_TLHelper.QJB.Box_TypeText:SetFontScale(value/100)
				LR_TLHelper.bombTime[1]:SetFontScale(value/100)
				LR_TLHelper.bombTime[2]:SetFontScale(value/100)
				LR_TLHelper.bombTime[3]:SetFontScale(value/100)
				LR_TLHelper.QJB.QJB_Distance2tar:SetFontScale(value/100)
				LR_TLHelper.QJB.QJB_FightState:SetFontScale(value/100)
				LR_TLHelper.QJB.QJB_tar:SetFontScale(value/100)
				LR_TLHelper.QJB.QJB_Distance2Self:SetFontScale(value/100)
				LR_TLHelper.UsrData.Scale=value/100
			end
		},{
			name="LR_TLHelper_UIcheck_box3",type="CheckBox",text=_L["Auto Hide"],x=0,y=160,w=200,
			enable = function ()
				if LR.GetXinFa() == Table_GetSkillName(10225,1) and LR_TLHelper.UsrData.on then
					return true
				else
					return false
				end
			end,
			default = function ()
				return LR_TLHelper.UsrData.HideQJB
			end,
			callback = function (enabled)
				LR_TLHelper.UsrData.HideQJB = enabled
			end
		},{
			name="LR_TLHelper_UIcheck_box4",type="CheckBox",text=_L["Show TargetLine"],x=0,y=190,w=200,
			enable = function ()
				if LR.GetXinFa() == Table_GetSkillName(10225,1) and LR_TLHelper.UsrData.on then
					return true
				else
					return false
				end
			end,
			default = function ()
				return LR_TLHelper.UsrData.showTargetLine
			end,
			callback = function (enabled)
				LR_TLHelper.UsrData.showTargetLine = enabled
			end
		},
		{
			name="LR_TLHelper_UIcheck_box5",type="CheckBox",text=_L["Show MeLine"],x=0,y=220,w=200,
			enable = function ()
				if LR.GetXinFa() == Table_GetSkillName(10225,1) and LR_TLHelper.UsrData.on then
					return true
				else
					return false
				end
			end,
			default = function ()
				return LR_TLHelper.UsrData.showMeLine
			end,
			callback = function (enabled)
				LR_TLHelper.UsrData.showMeLine = enabled
			end
		},
		{
			name="LR_TLHelper_UIcheck_box6",type="CheckBox",text=_L["Show Self"],x=0,y=250,w=200,
			enable = function ()
				if LR.GetXinFa() == Table_GetSkillName(10225,1) and LR_TLHelper.UsrData.on then
					return true
				else
					return false
				end
			end,
			default = function ()
				return LR_TLHelper.UsrData.showSelf
			end,
			callback = function (enabled)
				LR_TLHelper.UsrData.showSelf = enabled
			end
		},{
			name="LR_TLHelper_UItips1",type="TipBox",x=0,y=290,w=60,h=28,text="Tips",
			callback= function ()
				local x, y=this:GetAbsPos()
				local w, h = this:GetSize()
				local szXml = {}
				szXml[#szXml+1] = GetFormatText(_L["1.Only be used in TianLuo\n"],136,255,128,0)
				szXml[#szXml+1] = GetFormatText(_L["2.Press Alt+Ctrl Move.\n"],136,255,128,0)
				OutputTip(tconcat(szXml),350,{x,y,w,h})
			end
		},{
			name="LR_TLHelper_UImove1",type="Text",x=100,y=290,w=80,h=28,text=_L["Press Alt+Ctrl Move"],font=23,
		},
	}
}
LR_TOOLS:RegisterPanel(LR_TLHelper_UI)
-----------------------------------
----注册头像、扳手菜单
-----------------------------------
LR_TOOLS.menu=LR_TOOLS.menu or {}
LR_TLHelper_UI.menu = {
	szOption =_L["TL Helper"],
	--rgb = {255, 255, 255},
	fnAction = function()
		LR_TOOLS:OpenPanel(_L["TL Helper"])
	end,
	--bCheck=true,
	--bMCheck=true,
	rgb = {255, 255, 255},
	bChecked = function()
		local Frame = Station.Lookup("Normal/LR_TOOLS")
		if Frame then
			return true
		else
			return false
		end
	end,
	fnAutoClose=false,
}
tinsert(LR_TOOLS.menu,LR_TLHelper_UI.menu)
