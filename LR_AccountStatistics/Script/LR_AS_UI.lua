local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local LanguagePath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local db_name = "maindb.db"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20180403"
-------------------------------------------------------------
LR_AS_Panel = {}
LR_AS_Panel.Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0}

function LR_AS_Panel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_AS_Panel.Anchor.s, 0, 0, LR_AS_Panel.Anchor.r, LR_AS_Panel.Anchor.x, LR_AS_Panel.Anchor.y)
end

function LR_AS_Panel.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
	LR_AS_Panel.UpdateAnchor(this)

	this:Lookup("Btn_Close").OnLButtonClick =  function ()
		Wnd.CloseWindow("LR_AS_Panel")
	end

	RegisterGlobalEsc("LR_AS_Panel", function () return true end , function() Wnd.CloseWindow("LR_AS_Panel") end)
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)

	LR_AS_Base.LoadData()
	----界面
	this:Lookup("", ""):Lookup("Text_Title"):SetText(_L["LR_AccountStatistics"])
	local keys = {"PlayerInfo", "FBList", "RC", "QY"}
	local values = {_L["AccountStatistics"], _L["FBStatistics"], _L["RCStatistics"], _L["QYStatistics"]}
	for k, v in pairs (keys) do
		local text = this:Lookup("PageSet_Menu"):Lookup(sformat("WndCheck_%s", v)):Lookup("",""):Lookup(sformat("Text_%s", v))
		text:SetText(values[k])
		text:SetFontColor(128, 128, 128)
		local btn = this:Lookup("PageSet_Menu"):Lookup(sformat("WndCheck_%s", v))
		btn:Enable(false)
	end

	local flag = false
	for k, v in pairs(keys) do
		if LR_AS_Module[v] and LR_AS_Module[v].AddPage then
			LR_AS_Module[v].AddPage()
			flag = true
		end
	end
	if flag then
		this:Lookup("PageSet_Menu"):ActivePage(0)
	end

	LR.AppendAbout(Addon, this)
	FireEvent("LR_ACS_REFRESH_FP")
end

function LR_AS_Panel.OnFrameDestroy ()
	UnRegisterGlobalEsc("LR_AS_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_AS_Panel.OnEvent(event)
	if event == "UI_SCALED" then
		LR_AS_Panel.UpdateAnchor(this)
	end
end

function LR_AS_Panel.OpenPanel(flag)
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if frame and not flag then
		Wnd.CloseWindow(frame)
	else
		Wnd.OpenWindow("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AS_Panel.ini", "LR_AS_Panel")
	end
end

function LR_AS_Panel.OnFrameBreathe()
	if GetLogicFrameCount() % (16*5) ~=  0 then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	LR_AS_Base.LoadData()
	LR_AS_Panel.RefreshUI()
end

function LR_AS_Panel.RefreshUI()
	local keys = {"PlayerInfo", "FBList", "RC", "QY"}
	for k, v in pairs (keys) do
		if LR_AS_Module[v] and LR_AS_Module[v].RefreshPage then
			LR_AS_Module[v].RefreshPage()
		end
	end
	FireEvent("LR_ACS_REFRESH_FP")
end

function LR_AS_Panel.CheckTable(t_Table, dwID)
	local TempTable = t_Table
	local CheckID =  dwID
	for k, v in pairs (TempTable) do
		if v.ID  ==  CheckID then
			return k
		end
	end
	return 0
end

---------------------------------
---打开设置界面
---------------------------------
function LR_AS_Panel.SetOption()
	LR_TOOLS:OpenPanel(_L["LR_AS_Global_Settings"])
	local frame = Station.Lookup("Normal/LR_TOOLS")
	if frame then
		frame:BringToTop()
	end
end

-------------------------------
---弹出菜单
-------------------------------
function LR_AS_Panel.RClickMenu(realArea, realServer, dwID)
	if not realArea then
		return {}
	end
	local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
	local player = LR_AS_Data.AllPlayerList[szKey] or {}
	if next(player) == nil then
		return {}
	end
	local menu = {}
	local szPath, nFrame = GetForceImage(player.dwForceID)
	tinsert(menu, {
		szOption = player.szName,
		szLayer = "ICON_RIGHT",
		rgb = {LR.GetMenPaiColor(player.dwForceID)},
		szIcon = szPath,
		nFrame = nFrame,
	})

	if LR_AS_Module["PlayerInfo"] then
		tinsert(menu, { bDevide = true })
		tinsert(menu, {
			szOption = _L["Add this money"],
			bCheck = true,
			bMCheck = false,
			rgb = {255, 255, 255},
			fnAction = function ()
				local NotCalList = LR_AS_Base.UsrData.NotCalList or {}
				if NotCalList[szKey] then
					NotCalList[szKey] = nil
				else
					NotCalList[szKey] = true
				end
				--刷新
				LR_AS_Panel.RefreshUI()
			end,
			bChecked = function ()
				local NotCalList = LR_AS_Base.UsrData.NotCalList or {}
				if NotCalList[szKey] then
					return false
				else
					return true
				end
			end,
		})
	end

	tinsert(menu, { bDevide = true })
	if LR_AS_Module["ItemRecord"] then
		tinsert(menu, {
			szOption = _L["Show item statistics"],
			fnAction = function ()
				LR_AS_ItemRecord_Panel:Open(player.realArea, player.realServer, player.dwID)
			end,
		})
	end

	if LR_AS_Module["FBList"] then
		tinsert(menu, {
			szOption = _L["Show FB Details"],
			fnAction = function ()
				LR_AS_FB_Detail_Panel:Open(player.realArea, player.realServer, player.dwID)
			end,
		})
	end

	if LR_AS_Module["EquipmentRecord"] then
		tinsert(menu, {
			szOption = _L["Show Equipment"],
			fnAction = function ()
				LR_AS_Equip_Panel:Open(player.szName, player.realArea, player.realServer, player.dwForceID, player.dwID)
			end,
		})
	end

	---------------
	tinsert(menu, { bDevide = true })
	local menu2 = {
		szOption = _L["Group Settings"],
		fnDisable = function ()
			return false
		end,
		}
	for groupID, groupV in pairs(LR_AS_Group.GroupList) do
		local szGroupName = groupV.szName
		tinsert (menu2, {
			szOption = szGroupName,
			bCheck = true, bMCheck = true, bChecked = function() return LR_AS_Group.ifGroupHasUser(szKey, groupID) end,
			fnAction = function(UserData)
				--保存
				local path = sformat("%s\\%s", SaveDataPath, db_name)
				local DB = LR.OpenDB(path, "B6931908B2648C2F5FEABFE8816E8257")
				LR_AS_Group.ChangeUserGroup(szKey, groupID, DB)
				LR_AS_Group.SaveData(DB)
				LR.CloseDB(DB)
				--刷新UI
				LR_AS_Panel.RefreshUI()
			end,
		})
	end
	tinsert(menu2, {bDevide = true})
	tinsert(menu2, {szOption = _L["Group Cancel"],
		fnAction = function()
			local path = sformat("%s\\%s", SaveDataPath, db_name)
			local DB = LR.OpenDB(path, "85E7B24C8750AB7082E646858D6FF2D5")
			LR_AS_Group.ChangeUserGroup(szKey, 0, DB)
			LR_AS_Group.SaveData(DB)
			LR.CloseDB(DB)
			--刷新UI
			LR_AS_Panel.RefreshUI()
		end,
	})
	tinsert(menu2, {szOption = _L["Add Group"],
		fnAction = function()
			GetUserInput(_L["Group Name"], function(szText)
				local szText =  string.gsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
				if szText ~=  "" then
					local path = sformat("%s\\%s", SaveDataPath, db_name)
					local DB = LR.OpenDB(path, "935E09BF233EC8E405ABB1ED0F639562")
					LR_AS_Group.AddGroup(szText, DB)
					LR_AS_Module.Group.LoadData(DB)
					LR.CloseDB(DB)
					--刷新UI
					LR_AS_Panel.RefreshUI()
				end
			end)
		end,
	})
	tinsert(menu, menu2)
	if player.dwID ~=  GetClientPlayer().dwID then
		tinsert(menu, {	szOption =  _L["Make Friend"],
			fnAction = function()
				GetClientPlayer().AddFellowship(player.szName)
			end}
		)
	end
	tinsert(menu, { bDevide = true })
	tinsert(menu, {
		szOption = _L["Delete Data"],
		fnAction = function ()
			local sure_delete = function()
				local szKey = {dwID = player.dwID, loginArea = player.loginArea, loginServer = player.loginServer, szName = player.szName, realArea = player.realArea, realServer = player.realServer}
				if next(szKey)~= nil then
					local path = sformat("%s\\%s", SaveDataPath, db_name)
					local DB = LR.OpenDB(path, "810899476BEBD046B845B6F522B0E64F")
					LR_AS_Base.DelPlayer(szKey, DB)
					LR.CloseDB(DB)
					--读取
					LR_AS_Base.LoadData()
					--刷新UI
					LR_AS_Panel.RefreshUI()
				else
					return
				end
			end

			local msg = {
				szMessage = sformat("%s %s?", _L["Sure to delete"], player.szName),
				szName = "delete",
				fnAutoClose = function() return false end,
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() sure_delete() end, },
				{szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function()  end, },
			}
			MessageBox(msg)
		end,
		fnDisable = function()
			local me = GetClientPlayer()
			local ServerInfo = {GetUserServer()}
			local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
			if me.szName == player.szName and realArea == player.realArea and realServer == player.realServer then
				return true
			end
			return false
		end,
	})
	return menu
end








