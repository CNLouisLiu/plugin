local sformat, slen, sgsub, ssub,sfind = string.format, string.len, string.gsub, string.sub, string.find
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil = math.floor, math.ceil
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
-------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_BagHelper"
local _L = LR.LoadLangPack(AddonPath)
--------------------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("SmallHelpers") then
	tinsert (LR_TOOLS.tAddonClass,{"SmallHelpers",_L["Helpers"],"3"})
end

local LR_BagHelper_UI ={
	szName="LR_BagHelper_UI",
	szTitle=_L["LR BagHelper"],
	dwIcon = 1265,
	szClass = "SmallHelpers",
	tWidget = {
		{name = "LR_BagHelper_CheckBox01", type = "CheckBox", text = _L["Show stack button on bag panel"], x = 0, y = 0, w = 150,
			default = function ()
				return LR_BagHelper.UsrData.bShowBagBtn
			end,
			callback = function (enabled)
				LR_BagHelper.UsrData.bShowBagBtn = enabled
				LR_BagHelper.HookBag()
				LR_AccountStatistics_Bag.HookBag()
			end,
		},{name = "LR_BagHelper_CheckBox02", type = "CheckBox", text = _L["Show stack button on bank panel"], x = 0, y = 40, w = 150,
			default = function ()
				return LR_BagHelper.UsrData.bShowBankBtn
			end,
			callback = function (enabled)
				LR_BagHelper.UsrData.bShowBankBtn = enabled
				LR_BagHelper.HookBank()
			end,
		},{name = "LR_BagHelper_CheckBox03", type = "CheckBox", text = _L["Show sort button on GuildBank panel"], x = 0, y = 80, w = 150,
			default = function ()
				return LR_BagHelper.UsrData.bShowGuildBankBtn
			end,
			callback = function (enabled)
				LR_BagHelper.UsrData.bShowGuildBankBtn = enabled
				LR_GuildBank.HookGuildBank()
			end,
		},
	}
}
LR_TOOLS:RegisterPanel(LR_BagHelper_UI)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
LR_TOOLS.menu=LR_TOOLS.menu or {}
LR_BagHelper_UI.menu = {
	szOption =_L["LR BagHelper"],
	fnAction = function()
		LR_CopyBook_MiniPanel:Open()
	end,
	bCheck=true,
	bMCheck=false,
	rgb = {255, 255, 255},
	bChecked = function()
		local Frame = Station.Lookup("Normal/LR_TOOLS")
		if Frame then
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
		LR_TOOLS:OpenPanel(_L["LR BagHelper"])
	end,
	rgb = {255, 255, 255},
	fnAutoClose=true,
	{szOption = _L["Show stack button on bag panel"], bCheck = true, bMCheck = false, bChecked = function() return LR_BagHelper.UsrData.bShowBagBtn end, fnAction = function() LR_BagHelper.UsrData.bShowBagBtn = not LR_BagHelper.UsrData.bShowBagBtn; LR_BagHelper.HookBag() end},
	{szOption = _L["Show stack button on bank panel"], bCheck = true, bMCheck = false, bChecked = function() return LR_BagHelper.UsrData.bShowBankBtn end, fnAction = function() LR_BagHelper.UsrData.bShowBankBtn = not LR_BagHelper.UsrData.bShowBankBtn; LR_BagHelper.HookBank() end},
	{szOption = _L["Show sort button on GuildBank panel"], bCheck = true, bMCheck = false, bChecked = function() return LR_BagHelper.UsrData.bShowGuildBankBtn end, fnAction = function() LR_BagHelper.UsrData.bShowGuildBankBtn = not LR_BagHelper.UsrData.bShowGuildBankBtn; LR_GuildBank.HookGuildBank() end},
}
tinsert(LR_TOOLS.menu,LR_BagHelper_UI.menu)

-----------------------------
---¿ì½Ý¼ü
-----------------------------
LR.AddHotKey(_L["LR BagHelper"], 	function() LR_TOOLS:OpenPanel(_L["LR BagHelper"]) end)
