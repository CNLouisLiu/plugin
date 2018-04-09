local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local g2d, d2g = LR.StrGame2DB, LR.StrDB2Game
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AS_Module_PlayerInfo"
local LanguagePath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local db_name = "maindb.db"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20180403"
-------------------------------------------------------------
local _C = {}

function _C.GetSelfData()
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local loginArea, loginServer, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]

	local UserInfo = {}
	UserInfo.szKey = sformat("%s_%s_%d", realArea, realServer, me.dwID)
	local nMoney = me.GetMoney()
	UserInfo.nGold = nMoney.nGold
	UserInfo.nSilver = nMoney.nSilver
	UserInfo.nCopper = nMoney.nCopper
	UserInfo.nMoney = nMoney.nCopper + nMoney.nSilver * 100 + nMoney.nGold * 10000
	UserInfo.JianBen = LR.GetSelfJianBen() or 0	--监本
	UserInfo.BangGong = LR.GetSelfJiangGong() or 0
	UserInfo.XiaYi = LR.GetSelfXiaYi() or 0
	UserInfo.WeiWang = LR.GetSelfWeiWang() or 0
	UserInfo.ZhanJieJiFen = LR.GetSelfZhanJieJiFen() or 0
	UserInfo.ZhanJieDengJi = LR.GetSelfZhanJieDengJi() or 0
	UserInfo.MingJianBi = LR.GetSelfMingJianBi() or 0
	UserInfo.szTitle = me.szTitle or ""
	UserInfo.nCurrentStamina = me.nCurrentStamina or 0
	UserInfo.nMaxStamina = me.nMaxStamina or 0
	UserInfo.nCurrentThew = me.nCurrentThew or 0
	UserInfo.nMaxThew = me.nMaxThew or 0
	UserInfo.nCurrentTrainValue = me.nCurrentTrainValue or 0
	UserInfo.nCamp = me.nCamp or 0
	UserInfo.szTongName = LR.GetTongName(me.dwTongID) or ""
	UserInfo.remainJianBen = me.GetExamPrintRemainSpace() or 0
	UserInfo.SaveTime = GetCurrentTime()

	return UserInfo
end

function _C.SaveData(DB)
	if not LR_AS_Base.UsrData.bRecord then
		return
	end
	-------保存自身的属性数据
	local v = _C.GetSelfData()
	local DB_REPLACE = DB:Prepare("REPLACE INTO player_info (szKey, nGold, nSilver, nCopper, JianBen, BangGong, XiaYi, WeiWang, ZhanJieJiFen, ZhanJieDengJi, MingJianBi, szTitle, nCurrentStamina, nMaxStamina, nCurrentThew, nMaxThew, nCurrentTrainValue, nCamp, szTongName, remainJianBen, SaveTime) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )")
	DB_REPLACE:ClearBindings()
	DB_REPLACE:BindAll(unpack(g2d({v.szKey, v.nGold, v.nSilver, v.nCopper, v.JianBen, v.BangGong, v.XiaYi, v.WeiWang, v.ZhanJieJiFen, v.ZhanJieDengJi, v.MingJianBi, v.szTitle, v.nCurrentStamina, v.nMaxStamina, v.nCurrentThew, v.nMaxThew, v.nCurrentTrainValue, v.nCamp, v.szTongName, v.remainJianBen, v.SaveTime})))
	DB_REPLACE:Execute()
end

function _C.LoadData(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM player_info WHERE szKey IS NOT NULL ORDER BY nGold DESC, nSilver DESC, nCopper DESC")
	local data = d2g(DB_SELECT:GetAll())
	local AllUsrInfo = {}
	for k, v in pairs(data) do
		AllUsrInfo[v.szKey] = v
		AllUsrInfo[v.szKey].nMoney = v.nGold * 10000 + v.nSilver * 100 + v.nCopper
	end
	local myself = _C.GetSelfData()
	AllUsrInfo[myself.szKey] = clone(myself)
	LR_AS_Data.AllPlayerInfo = clone(AllUsrInfo)
end

function _C.ClearAllReaminJianBen(DB)
	local DB_SELECT = DB:Prepare("SELECT * FROM player_info WHERE szKey IS NOT NULL")
	local Data = d2g(DB_SELECT:GetAll())
	local DB_REPLACE = DB:Prepare("REPLACE INTO player_info (szKey, nGold, nSilver, nCopper, JianBen, BangGong, XiaYi, WeiWang, ZhanJieJiFen, ZhanJieDengJi, MingJianBi, szTitle, nCurrentStamina, nMaxStamina, nCurrentThew, nMaxThew, nCurrentTrainValue, nCamp, szTongName, remainJianBen, SaveTime) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1500,  ?)")
	for k, v in pairs (Data) do
		DB_REPLACE:ClearBindings()
		DB_REPLACE:BindAll(unpack(g2d({v.szKey, v.nGold, v.nSilver, v.nCopper, v.JianBen, v.BangGong, v.XiaYi, v.WeiWang, v.ZhanJieJiFen, v.ZhanJieDengJi, v.MingJianBi, v.szTitle, v.nCurrentStamina, v.nMaxStamina, v.nCurrentThew, v.nMaxThew, v.nCurrentTrainValue, v.nCamp, v.szTongName, GetCurrentTime()})))
		DB_REPLACE:Execute()
	end
end

function _C.ResetDataMonday(DB)
	_C.ClearAllReaminJianBen(DB)
end

----------------------------------------------------
------主界面显示奇遇信息
----------------------------------------------------
function _C.AddPage()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end

	local PageSet_Menu = frame:Lookup("PageSet_Menu")
	local Btn = PageSet_Menu:Lookup("WndCheck_PlayerInfo")

	local page = Wnd.OpenWindow(sformat("%s\\UI\\page.ini", AddonPath), "temp"):Lookup("Page_PlayerInfo")
	page:ChangeRelation(PageSet_Menu, true, true)
	page:SetName("Page_PlayerInfo")
	Wnd.CloseWindow("temp")
	PageSet_Menu:AddPage(page, Btn)

	Btn:Enable(true)
	Btn:Lookup("",""):Lookup("Text_PlayerInfo"):SetFontColor(255, 255, 255)
	_C.ReFreshTitle()
	_C.ListAS()

	_C.AddPageButton()
end

---刷新标题
function _C.ReFreshTitle()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end
	local page = frame:Lookup("PageSet_Menu"):Lookup("Page_PlayerInfo"):Lookup("","")
	local key_list = {"nLevel", "nMoney", "JianBen", "BangGong", "XiaYi", "WeiWang", "ZhanJieJiFen", "ZhanJieDengJi", "MingJianBi"}
	local title_list = {_L["Name"], _L["Money"], _L["Examprint"], _L["JiangGong"], _L["XiaYi"], _L["WeiWang"], _L["ZhanJieJiFen"], _L["ZhanJieLevel"], _L["MingJian"]}
	for k , v in ipairs(key_list) do
		if v then
			local txt = page:Lookup(sformat("Text_Record_Break%d", k))
			txt:SetText(title_list[k])
			txt:RegisterEvent(786)
			txt:SetFontScheme(44)
			if LR_AS_Base.UsrData.nKey  ==  v then
				if LR_AS_Base.UsrData.nSort  ==  "asc" then
					txt:SetText(title_list[k] .. "↑")
					txt:SetFontScheme(99)
				elseif LR_AS_Base.UsrData.nSort  ==  "desc" then
					txt:SetText(title_list[k] .. "↓")
					txt:SetFontScheme(99)
				end
			end

			txt.OnItemLButtonClick = function()
				if LR_AS_Base.UsrData.nKey  ==  v then
					if LR_AS_Base.UsrData.nSort  ==  "asc" then
						LR_AS_Base.UsrData.nSort = "desc"
					else
						LR_AS_Base.UsrData.nSort = "asc"
					end
				end
				LR_AS_Base.UsrData.nKey = v
				_C.ReFreshTitle()
				_C.ListAS()
				--LR_AccountStatistics_FBList.ListFB()
				--LR_AccountStatistics_RiChang.ListRC()
				--LR_ACS_QiYu.ListQY()
			end
			txt.OnItemMouseEnter = function()
				this:SetFontColor(255, 128, 0)
			end
			txt.OnItemMouseLeave = function()
				if LR_AS_Base.UsrData.nKey  ==  v then
					txt:SetFontScheme(99)
				else
					this:SetFontColor(255, 255, 255)
				end
			end
		end
	end
end

--刷新列表
function _C.ListAS()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end
	_C.Container = frame:Lookup("PageSet_Menu/Page_PlayerInfo/WndScroll_PlayerInfo/WndContainer_PlayerInfo")
	_C.Container:Clear()
	local TempTable_Cal, TempTable_NotCal = LR_AS_Base.SeparateUsrList()
	local AllMoney = 0
	local num = 0
	num, AllMoney = _C.ShowItem(TempTable_Cal, 255, true, 0, 0)
	num, AllMoney = _C.ShowItem(TempTable_NotCal, 60, false, num, AllMoney)
	_C.Container:FormatAllContentPos()
	local page = Station.Lookup("Normal/LR_AS_Panel/PageSet_Menu/Page_PlayerInfo")
	local Text_GoldBrick = page:Lookup("", "Text_GoldBrick")
	local Text_Gold = page:Lookup("", "Text_Gold")
	local Text_Silver = page:Lookup("", "Text_Silver")
	local Text_Copper = page:Lookup("", "Text_Copper")
	local nGoldBrick, nGold, nSilver, nCopper = LR.MoneyToGoldSilverAndCopper(AllMoney)

	Text_GoldBrick:SetText(nGoldBrick)
	Text_Gold:SetText(nGold)
	Text_Silver:SetText(nSilver)
	Text_Copper:SetText(nCopper)
end

function _C.ShowItem(t_Table, Alpha, bCal, _num, _money)
	local num = _num
	local AllMoney = _money
	local PlayerList = clone(t_Table)
	local me = GetClientPlayer()
	for k, v in pairs(PlayerList) do
		num = num+1
		local wnd = _C.Container:AppendContentFromIni(sformat("%s\\UI\\item.ini", AddonPath), "WndWindow", sformat("%s_%s_%s", v.realArea, v.realServer, v.szName))
		local items = wnd:Lookup("", "")
		if num % 2  ==  0 then
			items:Lookup("Image_Line"):Hide()
		else
			items:Lookup("Image_Line"):SetAlpha(225)
		end

		wnd:SetAlpha(Alpha)

		local item_MenPai = items:Lookup("Image_NameIcon")
		local item_Name = items:Lookup("Text_Name")
		local item_GoldBrick = items:Lookup("Text_GoldBrick")
		local item_Gold = items:Lookup("Text_Gold")
		local item_Silver = items:Lookup("Text_Silver")
		local item_Copper = items:Lookup("Text_Copper")
		local item_JianBen = items:Lookup("Text_JianBen")
		local item_BangGong = items:Lookup("Text_BangGong")
		local item_XiaYi = items:Lookup("Text_XiaYi")
		local item_WeiWang = items:Lookup("Text_WeiWang")
		local item_ZhanJieJiFen = items:Lookup("Text_ZhanJieJiFen")
		local item_ZhanJieDengJi = items:Lookup("Text_ZhanJieDengJi")
		local item_MingJianBi = items:Lookup("Text_MingJianBi")
		local item_Select = items:Lookup("Image_Select")
		item_Select:SetAlpha(125)
		item_Select:Hide()

		local szKey = sformat("%s_%s_%d", v.realArea, v.realServer, v.dwID)
		local PlayerInfo = LR_AS_Data.AllPlayerInfo[szKey] or {}
		local szPath, nFrame = GetForceImage(v.dwForceID)

		local item_button_menu = LR_AS_Panel.RClickMenu(v.realArea, v.realServer, v.dwID)
		local item_button = wnd:Lookup("Btn_Setting")
		item_button.OnLButtonClick =  function ()
			  PopupMenu(item_button_menu)
		end

		--名字
		item_MenPai:FromUITex(GetForceImage(v.dwForceID))
		local name = v.szName
		if wslen(name) > 6 then
			name = sformat("%s...", wssub(name, 1, 5))
		end
		item_Name:SprintfText(_L["%s(%d)"], name, v.nLevel)
		local r, g, b = LR.GetMenPaiColor(v.dwForceID)
		item_Name:SetFontColor(r, g, b)

		--金钱
		local nGoldBrick, nGold, nSilver, nCopper = LR.MoneyToGoldSilverAndCopper(PlayerInfo.nMoney or 0)
		item_GoldBrick:SetText(nGoldBrick)
		item_Gold:SetText(nGold)
		item_Silver:SetText(nSilver)
		item_Copper:SetText(nCopper)

		--监本
		local nJianBen = tostring(PlayerInfo.JianBen or "--")
		local examData = LR_AS_Data.ExamData[szKey] or {["ShengShi"] = 0, ["HuiShi"] = 0, }
		if examData["HuiShi"] == 1 then
			item_JianBen:SprintfText("▲%s▲", nJianBen)
		elseif examData["ShengShi"] == 1 then
			item_JianBen:SprintfText("△%s△", nJianBen)
		else
			item_JianBen:SetText(nJianBen)
		end

		--
		item_BangGong:SetText(PlayerInfo.BangGong or "--")
		item_XiaYi:SetText(PlayerInfo.XiaYi or "--")
		item_WeiWang:SetText(PlayerInfo.WeiWang or "--")
		item_ZhanJieJiFen:SetText(PlayerInfo.ZhanJieJiFen or "--")
		item_ZhanJieDengJi:SetText(PlayerInfo.ZhanJieDengJi or "--")
		item_MingJianBi:SetText(PlayerInfo.MingJianBi or "--")

		local remainJianBen = PlayerInfo.remainJianBen or 1500
		if remainJianBen < 100 then
			item_JianBen:SetFontScheme(207)
			item_JianBen:SetFontColor(255, 0, 128)
		elseif remainJianBen < 300 then
			item_JianBen:SetFontScheme(207)
			item_JianBen:SetFontColor(215, 215, 0)
		end

		--------------------输出tips
		items:RegisterEvent(818)
		items.OnItemMouseEnter = function ()
			item_Select:Show()
			local nMouseX, nMouseY =  Cursor.GetPos()
			local szTipInfo = {}
			local szPath, nFrame = GetForceImage(v.dwForceID)
			szTipInfo[#szTipInfo+1] = GetFormatImage(szPath, nFrame, 26, 26)
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s(%d)\n", v.szName, v.nLevel), 62, r, g, b)
			szTipInfo[#szTipInfo+1] = GetFormatImage("ui\\image\\ChannelsPanel\\NewChannels.uitex", 166, 365, 27)
			szTipInfo[#szTipInfo+1] = GetFormatText("\n", 224)
			--szTipInfo[#szTipInfo+1] = GetFormatText(" ================================ \n", 17)
--[[			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("金钱：", 224) ..  GetFormatText(sformat("%d 金 %d 银 %d 铜\n", nGold, nSilver, nCopper), 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("监本：", 224) ..  GetFormatText(v.JianBen.."\n", 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("江湖贡献值：", 224) ..  GetFormatText(v.BangGong.."\n", 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("侠义值：", 224) ..  GetFormatText(v.XiaYi.."\n", 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("威望值：", 224) ..  GetFormatText(v.WeiWang.."\n", 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("战阶积分：", 224) ..  GetFormatText(v.ZhanJieJiFen.."\n", 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("战阶等级：", 224) ..  GetFormatText(v.ZhanJieDengJi.."\n", 41)
			szTipInfo[#szTipInfo+1] = szTipInfo .. GetFormatText("名剑币：", 224) ..  GetFormatText(v.MingJianBi.."\n", 41)]]
			szTipInfo[#szTipInfo+1] = GetFormatText(_L["Login Server:"], 224)
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s[%s]\n", v.loginServer or "--", v.loginArea or "--"), 18)
			szTipInfo[#szTipInfo+1] = GetFormatText(_L["Tong:"], 224)
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", PlayerInfo.szTongName or "--"), 18)
			szTipInfo[#szTipInfo+1] = GetFormatText(_L["Title:"], 224)
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", PlayerInfo.szTitle or "--"), 18)

			if PlayerInfo.nCamp ~=  nil then
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["Camp:"], 224)
				if v.nCamp  ==  0 then
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", g_tStrings.STR_CAMP_TITLE[PlayerInfo.nCamp]), 27)
				elseif v.nCamp  ==  1 then
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", g_tStrings.STR_CAMP_TITLE[PlayerInfo.nCamp]), 206)
				elseif v.nCamp  ==  2 then
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n",g_tStrings.STR_CAMP_TITLE[PlayerInfo.nCamp]), 102)
				end
			end

			szTipInfo[#szTipInfo+1] = GetFormatText(_L["TrainValue:"], 224)
			szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", PlayerInfo.nCurrentTrainValue or "--"), 18)

			if PlayerInfo.nCurrentStamina ~=  nil then
				local nMaxStamina, nMaxThew, nCurrentStamina, nCurrentThew, SaveTime = 0, 0, 0, 0, 0
				local delta_time, delta_Stamina, delta_Thew, now_Stamina, now_Thew
				local GroupList = LR_AS_Group.GroupList

				nMaxStamina = PlayerInfo.nMaxStamina or 0
				nMaxThew = PlayerInfo.nMaxThew or 0
				nCurrentStamina = PlayerInfo.nCurrentStamina or 0
				nCurrentThew = PlayerInfo.nCurrentThew or 0
				SaveTime = PlayerInfo.SaveTime or 0

				-----如果在分组里，刷新成分组里的数据
				local loginArea = v.loginArea
				local loginServer = v.loginServer
				local realArea = v.realArea or loginArea
				local realServer = v.realServer or loginServer
				local dwID = v.dwID
				local szName = v.szName
				local szKey = sformat("%s_%s_%d", realArea, realServer, dwID)
				if LR_AS_Group.AllUsrGroup[szKey] and LR_AS_Group.AllUsrGroup[szKey].groupID > 0 then
					local groupID = LR_AS_Group.AllUsrGroup[szKey].groupID
					nMaxStamina = GroupList[groupID].nMaxStamina or 0
					nMaxThew = GroupList[groupID].nMaxThew or 0
					nCurrentStamina = GroupList[groupID].nCurrentStamina or 0
					nCurrentThew = GroupList[groupID].nCurrentThew or 0
					SaveTime = GroupList[groupID].SaveTime or 0
				end

				delta_time = (GetCurrentTime() - SaveTime) / 60 / 6
				delta_Stamina = mfloor(nMaxStamina * 0.00078 * delta_time )
				delta_Thew =  mfloor(nMaxThew  * 0.00078 * delta_time)
				now_Stamina = nCurrentStamina + delta_Stamina
				now_Thew = nCurrentThew + delta_Thew
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["Stamina:"], 224)
				if now_Stamina>= nMaxStamina then
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%d%s", nMaxStamina, _L[" (FULL)"]), 71)
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat(" = %d + Δ%d\n", nCurrentStamina, nMaxStamina - nCurrentStamina), 18)
				else
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%d = %d + Δ%d\n", now_Stamina, nCurrentStamina, delta_Stamina), 18)
				end
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["Thew:"], 224)
				if now_Thew>= nMaxThew then
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%d%s", nMaxThew, _L[" (FULL)"]), 71)
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat(" = %d + Δ%d\n", nCurrentThew, nMaxThew - nCurrentThew), 18)
				else
					szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%d = %d +Δ%d\n", now_Thew, nCurrentThew, delta_Thew), 18)
				end
			else
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["Stamina:"], 224)
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", v.nCurrentStamina or ""), 18)
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["Thew:"], 224)
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", v.nCurrentThew or ""), 18)
			end
			if v.remainJianBen then
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["JianBen this week remain:"], 224)
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", v.remainJianBen), 18)
			end

			if LR_AS_Group.AllUsrGroup[szKey] and LR_AS_Group.AllUsrGroup[szKey].groupID and LR_AS_Group.AllUsrGroup[szKey].groupID > 0 then
				szTipInfo[#szTipInfo+1] = GetFormatText(_L["Group name:"], 224)
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("%s\n", LR_AS_Group.AllUsrGroup[szKey].szName), 18)
			end

			if IsCtrlKeyDown() then
				szTipInfo[#szTipInfo+1] = GetFormatText(sformat("dwID：%d\n", v.dwID), 71)
			end

			local text = tconcat(szTipInfo)
			OutputTip(text, 360, {nMouseX, nMouseY, 0, 0})
		end
		items.OnItemMouseLeave = function()
			item_Select:Hide()
			HideTip()
		end
		items.OnItemLButtonClick = function()
			if LR_AS_Module["ItemRecord"] then
				LR_AS_ItemRecord_Panel:Open(v.realArea, v.realServer, v.dwID)
			end
		end
		items.OnItemRButtonClick = function()
			PopupMenu(item_button_menu)
		end
		if bCal then
			AllMoney = AllMoney + (PlayerInfo.nMoney or 0)
		end
	end
	return num, AllMoney
end

--添加底部按钮
function _C.AddPageButton()
	local frame = Station.Lookup("Normal/LR_AS_Panel")
	if not frame then
		return
	end
	local page = frame:Lookup("PageSet_Menu/Page_PlayerInfo")
	LR_AS_Base.AddButton(page, "btn_5", _L["Show Group"], 340, 555, 110, 36, function() LR_AS_Group.PopupUIMenu() end)
	if LR_AS_Module["BookRd"] then
		LR_AS_Base.AddButton(page, "btn_4", _L["Reading Statistics"], 470, 555, 110, 36, function() LR_BookRd_Panel:Open() end)
	end
	if LR_AS_Module["ItemRecord"] then
		LR_AS_Base.AddButton(page, "btn_3", _L["Item Statistics"], 600, 555, 110, 36, function() LR_AS_ItemRecord_Panel:Open() end)
	end
	LR_AS_Base.AddButton(page, "btn_2", _L["Settings"], 730, 555, 110, 36, function() LR_AS_Base.SetOption() end)
	LR_AS_Base.AddButton(page, "btn_1", _L["Save Data"], 860, 555, 110, 36, function() LR_AS_Base.SaveData() end)
end

function _C.RefreshPage()
	_C.ReFreshTitle()
	_C.ListAS()
end

--注册模块
LR_AS_Module.PlayerInfo = {}
LR_AS_Module.PlayerInfo.SaveData = _C.SaveData
LR_AS_Module.PlayerInfo.LoadData = _C.LoadData
LR_AS_Module.PlayerInfo.ResetDataMonday = _C.ResetDataMonday
LR_AS_Module.PlayerInfo.AddPage = _C.AddPage
LR_AS_Module.PlayerInfo.RefreshPage = _C.RefreshPage
LR_AS_Module.PlayerInfo.FIRST_LOADING_END = _C.LoadData




