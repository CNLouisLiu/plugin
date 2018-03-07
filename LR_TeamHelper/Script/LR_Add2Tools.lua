local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
-------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_TeamHelper"
local _L = LR.LoadLangPack(AddonPath)
--------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("SmallHelpers") then
	tinsert (LR_TOOLS.tAddonClass,{"SmallHelpers",_L["Helpers"],"3"})
end
---------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}

local LR_TeamHelper_UI ={
	szName="LR_TeamHelper_UI",
	szTitle=_L["LR TeamHelper"],
	dwIcon = 6641,
	szClass = "SmallHelpers",
	tWidget = {
		{
			name="LR_TeamHelper_UI_check_box",type="CheckBox",text=_L["Enable LR TeamHelper"],x=0,y=0,w=200,
			default = function ()
				return LR_TeamRequest.UsrData.bOn
			end,
			callback = function (enabled)
				LR_TeamRequest.UsrData.bOn = enabled
			end
		},
	}
}
LR_TOOLS:RegisterPanel(LR_TeamHelper_UI)


-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
LR_TOOLS.menu=LR_TOOLS.menu or {}
LR_TeamHelper_UI.menu = {
	szOption =_L["LR TeamHelper"],
	fnAction = function()
		LR_TeamRequest.UsrData.bOn = not LR_TeamRequest.UsrData.bOn
	end,
	bCheck=true,
	bMCheck=false,
	rgb = {255, 255, 255},
	bChecked = function()
		return LR_TeamRequest.UsrData.bOn
	end,
	fnAutoClose=true,
	szIcon = "ui\\Image\\UICommon\\CommonPanel2.UITex",
	nFrame =105,
	nMouseOverFrame = 106,
	szLayer = "ICON_RIGHT",
	fnAutoClose=true,
	fnClickIcon = function ()
		LR_TOOLS:OpenPanel(_L["LR TeamHelper"])
	end,
	rgb = {255, 255, 255},
	fnAutoClose=true,
}
table.insert(LR_TOOLS.menu,LR_TeamHelper_UI.menu)
