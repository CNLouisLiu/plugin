local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_EquipSearch"
local SaveDataPath="Interface\\LR_Plugin\\@DATA\\LR_EquipSearch"
local _L = LR.LoadLangPack(AddonPath)
-----------------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("Normal") then
	table.insert (LR_TOOLS.tAddonClass,{"Normal",_L["Plugins"],"1"})
end
local LR_EquipSearch_UI ={
	szName="LR_EquipSearch_UI",
	szTitle=_L["LR_EQUIP_SEARCH"] ,
	dwIcon = 605,
	szClass = "Normal",
	tWidget = {
		{
			name="LR_EquipSearch_UI_Button",type="Button",x=0,y=0,w=300,text=_L["OPEN_LR_EQUIP_SEARCH"],
			callback = function()
				LR_EquipSearch_Panel:Open()
			end
		},
	}
}
LR_TOOLS:RegisterPanel(LR_EquipSearch_UI)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
LR_TOOLS.menu=LR_TOOLS.menu or {}
LR_EquipSearch_UI.menu = {
	szOption =_L["LR_EQUIP_SEARCH"] ,
	fnAction = function()
		LR_EquipSearch_Panel:Open()
	end,
	bCheck=true,
	bMCheck=false,
	rgb = {255, 255, 255},
	bChecked = function()
		local frame=Station.Lookup("Normal/LR_EquipSearch_Panel")
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
		LR_TOOLS:OpenPanel(_L["LR_EQUIP_SEARCH"])
	end,
	rgb = {255, 255, 255},
	fnAutoClose=true,
}
table.insert(LR_TOOLS.menu,LR_EquipSearch_UI.menu)

-----------------------------
---¿ì½Ý¼ü
-----------------------------
LR.AddHotKey(_L["LR_EQUIP_SEARCH"], 	function() LR_EquipSearch_Panel:Open() end)
