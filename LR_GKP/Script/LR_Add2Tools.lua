local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_GKP"
local SaveDataPath="Interface\\LR_Plugin@DATA\\LR_GKP"
local _L = LR.LoadLangPack(AddonPath)
local DB_Name = "LR_GKP.db"
local DB_Path = sformat("%s\\%s", SaveDataPath, DB_Name)
local VERSION = "20170717"
---------------------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("Normal") then
	table.insert (LR_TOOLS.tAddonClass,{"Normal",_L["Plugins"],"1"})
end
local LR_GKP_UI ={
	szName="LR_GKP_UI",
	szTitle=_L["LR GKP"] ,
	dwIcon = 2490,
	szClass = "Normal",
	tWidget = {
		{	name="LR_GKP_Button_01",type="Button",x=0,y=0,w=300,text=_L["Open LR_GKP Panel"],
			callback = function()
				LR_GKP_Panel:Open()
			end
		},
	}
}
LR_TOOLS:RegisterPanel(LR_GKP_UI)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
LR_TOOLS.menu=LR_TOOLS.menu or {}
LR_GKP_UI.menu = {
	szOption =_L["LR GKP"] ,
	fnAction = function()
		LR_GKP_Panel:Open()
	end,
	bCheck=true,
	bMCheck=false,
	rgb = {255, 255, 255},
	bChecked = function()
		local frame=Station.Lookup("Normal/LR_GKP_Panel")
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
		LR_TOOLS:OpenPanel(_L["LR GKP"])
	end,
	rgb = {255, 255, 255},
	fnAutoClose=true,
}
table.insert(LR_TOOLS.menu,LR_GKP_UI.menu)

-----------------------------
---¿ì½Ý¼ü
-----------------------------
LR.AddHotKey(_L["LR GKP"], function() LR_GKP_Panel:Open() end)
