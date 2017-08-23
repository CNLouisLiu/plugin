local AddonPath="Interface\\LR_Plugin\\LR_Accelerate"
local _L=LR.LoadLangPack(AddonPath)
--------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("Normal") then
	table.insert (LR_TOOLS.tAddonClass,{"Normal",_L["Plugins"],"1"})
end
local LR_Accelerate_UI ={
	szName="LR_Accelerate_UI",
	szTitle=_L["LR Accelerate Table"] ,
	dwIcon = 532,
	szClass = "Normal",
	tWidget = {
		{
			name="LR_Accelerate_UI_Button",type="Button",x=0,y=0,w=300,text=_L["Open LR Accelerate Table"],
			callback = function()
				LR_Accelerate_Panel:Open()
			end
		},
	}
}
LR_TOOLS:RegisterPanel(LR_Accelerate_UI)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
LR_TOOLS.menu=LR_TOOLS.menu or {}
LR_Accelerate_UI.menu = {
	szOption =_L["LR Accelerate Table"] ,
	fnAction = function()
		LR_Accelerate_Panel:Open()
	end,
	bCheck=true,
	bMCheck=false,
	rgb = {255, 255, 255},
	bChecked = function()
		local frame=Station.Lookup("Normal/LR_Accelerate_Panel")
		if frame then
			return true
		else
			return false
		end
	end,
	fnAutoClose=true,
	szIcon = "ui\\Image\\UICommon\\CommonPanel2.UITex",
	nFrame =105,
	nMouseOverFrame = 106,
	szLayer = "ICON_RIGHT",
	fnAutoClose=true,
	fnClickIcon = function ()
		LR_TOOLS:OpenPanel(_L["LR Accelerate Table"])
	end,
	rgb = {255, 255, 255},
	fnAutoClose=true,
}
table.insert(LR_TOOLS.menu,LR_Accelerate_UI.menu)

-----------------------------
---¿ì½Ý¼ü
-----------------------------
LR.AddHotKey(_L["LR Accelerate Table"], function() LR_Accelerate_Panel:Open() end)
