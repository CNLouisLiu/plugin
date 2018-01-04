local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_1Base"
local SaveDataPath="Interface\\LR_Plugin@DATA\\LR_1Base"
---------------------------------------------------------------
LR = LR or {
	tDelayCall={},
	tEvent={},
	tBreatheCall={},
}
LR.UsrData={
	Debug_enable=true,
	Debug_Level=1,
}
local CustomVersion = "20170111"
RegisterCustomData("LR.UsrData", CustomVersion)

---------------------------------------------------------------------------------
-- �����Դ���
-- (table) MY.LoadLangPack(void)
local SZLANG = ""
function LR.GetszLang()
	if SZLANG == "" then
		local _, _, szLang = GetVersion()
		SZLANG = szLang
	end
end
LR.GetszLang()

function LR.LoadLangPack(szLangFolder)
	local _, _, szLang = GetVersion()
	SZLANG = szLang
	local t0 = LoadLUAData(sformat("%s\\lang\\default", AddonPath)) or {}
--[[	local t1 = LoadLUAData(AddonPath.."\\lang\\" .. szLang) or {}
	for k, v in pairs(t1) do
		t0[k] = v
	end]]
	if type(szLangFolder)=="string" then
		--szLangFolder = sgsub(szLangFolder,"[/\\]+$","")
		local t2 = LoadLUAData(sformat("%s\\lang\\default", szLangFolder)) or {}
		for k, v in pairs(t2) do
			t0[k] = v
		end
		--local t3 = LoadLUAData(szLangFolder.."\\lang\\" .. "zhtw") or {}
		local t3 = LoadLUAData(sformat("%s\\lang\\%s",  szLangFolder, szLang)) or {}
		for k, v in pairs(t3) do
			t0[k] = v
		end
	end
	setmetatable(t0, {
		__index = function(t, k) return k end,
		__call = function(t, k, ...) return sformat(t[k], ...) end,
	})
	return t0
end
local _L = LR.LoadLangPack(AddonPath)
---------------------------------------------------------------------------------
------------------------------------
function LR.Trim(szText)
	if not szText or szText == "" then
		return ""
	end
	return (sgsub(szText, "^%s*(.-)%s*$", "%1"))
end

function LR.UrlEncode(szText)
	local str = szText:gsub("([^0-9a-zA-Z ])", function (c) return sformat("%%%02X", sbyte(c)) end)
	str = str:gsub(" ", "+")
	return str
end

function LR.UrlDecode(szText)
	return szText:gsub("+", " "):gsub("%%(%x%x)", function(h) return schar(tonumber(h, 16)) end)
end

function LR.AscIIEncode(szText)
	return szText:gsub('(.)', function(s) return sformat("%02x", s:byte()) end)
end

function LR.AscIIDecode(szText)
	return szText:gsub('(%x%x)', function(s) return schar(tonumber(s, 16)) end)
end

function LR.StrDB2Game(szText)
	local szText = szText
	if SZLANG == "zhcn" then
		szText = UTF8ToAnsi(szText)
	end
	return szText
end

function LR.StrGame2DB(szText)
	local szText = szText
	if SZLANG == "zhcn" then
		szText = AnsiToUTF8(szText)
	end
	return szText
end
-----------------------------------------------------------------------
LR.MapType = {}
function LR.LoadDragonMapData()
	local nCount = g_tTable.DungeonInfo:GetRowCount()
	--row 1 for default
	for i = 2, nCount, 1 do
		local tLine = g_tTable.DungeonInfo:GetRow(i)
		local dwMapID = tLine.dwMapID
		local _, _, nMaxPlayerCount = GetMapParams(dwMapID)
		local desc = ""
		local _s, _e, num_limit, tLevel = sfind(tLine.szLayer3Name, sformat("(%%d+)%s(.+)", _L["REN"]))
		if not _s then
			num_limit = 25
			desc = sformat("(%s)", wssub(LR.Trim(tLine.szLayer3Name), 1, 2))
		else
			desc = sformat("(%d%s)", num_limit, wssub(tLevel, 1, 1))
		end
		local _s2, _e2, szOtherName = sfind(tLine.szOtherName, _L["��(.+)"])
		if not _s2 then
			szOtherName = tLine.szOtherName
		end
		local szName = sformat("%s%s", szOtherName, desc)
		local szBossInfo = sgsub(tLine.szBossInfo, "(%s+)", ",")
		LR.MapType[dwMapID] = {szName = szName, dwMapID = dwMapID, nMaxPlayerCount = tonumber(num_limit), bossList = szBossInfo, Level = tLine.nDivideLevel, szVersionName = tLine.szVersionName, path = tLine.szDungeonImage2, nFrame = tLine.nDungeonFrame2 }
	end

	---�������ض���bossList
	local boss = {
		[206] = _L["BossZhuHu"],
		[199] = _L["BossZhuHu"],
		[212] = _L["BossZhuHu"],
		[192] = _L["BossZhuHu"],

		[171] = _L["BossZhanBaoJunXieKu"],
		[160] = _L["BossZhanBaoJunXieKu"],

		[72] = _L["BossDiHuaShengDian"],
		[70] = _L["BossDiHuaShengDian"],
		[69] = _L["BossDiHuaShengDian"],
		[68] = _L["BossDiHuaShengDian"],

		[271] = _L["BossDuanDaoTing"],
		[273] = _L["BossDuanDaoTing"],
		[263] = _L["BossDuanDaoTing"],
	}
	for k, v in pairs (boss) do
		if LR.MapType[k] then
			LR.MapType[k].bossList = v
		end
	end
end
LR.LoadDragonMapData()

--------------------------------------
function LR.Table_GetBookItemIndex(dwBookID, dwSegmentID)
	local dwBookItemIndex = 0

	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		dwBookItemIndex = tBookSegment.dwBookItemIndex
	end

	return dwBookItemIndex
end

function LR.GetBookReadStatusByName(szName)
	local RowCount = g_tTable.BookSegment:GetRowCount()
	local i = 2
	while i <= RowCount do
		local t = g_tTable.BookSegment:GetRow(i)
		if LR.Trim(szName) == LR.Trim(t.szSegmentName) then
			return GetClientPlayer().IsBookMemorized(t.dwBookID, t.dwSegmentID)
		end
		i = i + 1
	end
	return false
end

function LR.Table_GetSegmentName(dwBookID, dwSegmentID)
	local szSegmentName = ""

	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		szSegmentName = tBookSegment.szSegmentName
	end
	return szSegmentName
end

function LR.GetItemNameByItem(item)
	if item.nGenre == ITEM_GENRE.BOOK then
		local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
		return LR.Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	else
		return Table_GetItemName(item.nUiId)
	end
end

function LR.GetItemNameByItemInfo(itemInfo, nBookInfo)
	if itemInfo.nGenre == ITEM_GENRE.BOOK then
		if nBookInfo then
			local nBookID, nSegID = GlobelRecipeID2BookID(nBookInfo)
			return LR.Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
		else
			return Table_GetItemName(itemInfo.nUiId)
		end
	else
		return Table_GetItemName(itemInfo.nUiId)
	end
end

function LR.CheckUnLock()
	local state = Lock_State()
	return state == "NO_PASSWORD" or state == "PASSWORD_UNLOCK"
end

function LR.GetItemNumInBag(dwTabType, dwIndex, nBookID)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local num = 0
	for dBox = 1, 6, 1 do
		for dX = 0, me.GetBoxSize(dBox) - 1, 1 do
			local item = me.GetItem(dBox, dX)
			if item then
				if item.dwTabType == dwTabType and item.dwIndex == dwIndex then
					local nStackNum = 1
					if item.nGenre == ITEM_GENRE.BOOK then
						if item.nBookID ~= nBookID then
							nStackNum = 0
						end
					else
						if item.bCanStack then
							nStackNum = item.nStackNum
						end
					end
					num = num + nStackNum
				end
			end
		end
	end

	return num
end

function LR.GetItemNumInBank(dwTabType, dwIndex, nBookID)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local num = 0
	for dBox = 7, 12, 1 do
		for dX = 0, me.GetBoxSize(dBox) - 1, 1 do
			local item = me.GetItem(dBox, dX)
			if item then
				if item.dwTabType == dwTabType and item.dwIndex == dwIndex then
					local nStackNum = 1
					if item.nGenre == ITEM_GENRE.BOOK then
						if item.nBookID ~= nBookID then
							nStackNum = 0
						end
					else
						if item.bCanStack then
							nStackNum = item.nStackNum
						end
					end
					num = num + nStackNum
				end
			end
		end
	end

	return num
end

function LR.GetItemNumInBagAndBank(dwTabType, dwIndex, nBookID)
	local bagNum = LR.GetItemNumInBag(dwTabType, dwIndex, nBookID)
	local bankNum = LR.GetItemNumInBank(dwTabType, dwIndex, nBookID)
	return bagNum + bankNum
end

------------------------------------------------------------------
------UI
------------------------------------------------------------------
function LR.AppendUI(__type, parent, szName, data)
	local __h = nil
	if __type == "Frame" then
		__h = _G.CreateFrame(parent, szName, data)
	elseif __type == "Window" then
		__h = _G.CreateWindow(parent, szName, data)
	elseif __type == "WndContainer" then
		__h = _G.CreateWndContainer(parent, szName, data)
	elseif __type == "PageSet" then
		__h = _G.CreatePageSet(parent, szName, data)
	elseif __type == "Button" then
		__h = _G.CreateButton(parent, szName, data)
	elseif __type == "Edit" then
		__h = _G.CreateEdit(parent, szName, data)
	elseif __type == "CheckBox" then
		__h = _G.CreateCheckBox(parent, szName, data)
	elseif __type == "ComboBox" then
		__h = _G.CreateComboBox(parent, szName, data)
	elseif __type == "RadioBox" then
		__h = _G.CreateRadioBox(parent, szName, data)
	elseif __type == "CSlider" then
		__h = _G.CreateCSlider(parent, szName, data)
	elseif __type == "ColorBox" then
		__h = _G.CreateColorBox(parent, szName, data)
	elseif __type == "Scroll" then
		__h = _G.CreateScroll(parent, szName, data)
	elseif __type == "UIButton" then
		__h = _G.CreateUIButton(parent, szName, data)
	elseif __type == "Handle" then
		__h = _G.CreateHandle(parent, szName, data)
	elseif __type == "Text" then
		__h = _G.CreateText(parent, szName, data)
	elseif __type == "Image" then
		__h = _G.CreateImage(parent, szName, data)
	elseif __type == "Animate" then
		__h = _G.CreateAnimate(parent, szName, data)
	elseif __type == "Shadow" then
		__h = _G.CreateShadow(parent, szName, data)
	elseif __type == "Box" then
		__h = _G.CreateBox(parent, szName, data)
	elseif __type == "TreeLeaf" then
		__h = _G.CreateTreeLeaf(parent, szName, data)
	end

	return __h
end

-----------------------------------------------------------------
------�������Ի�ȡ
------------------------------------------------------------------
---����
function LR.GetSelfXiaYi()
	local player=GetClientPlayer()
	if not player then
		return 0
	end
	return player.nJustice
end

---�ﹱ
function LR.GetSelfJiangGong()
	local player=GetClientPlayer()
	if not player then
		return 0
	end
	return player.nContribution
end


----�౾
function LR.GetSelfJianBen()
	local player=GetClientPlayer()
	if not player then
		return 0
	end
	return player.nExamPrint
end

---����
function LR.GetSelfWeiWang()
	local player=GetClientPlayer()
	if not player then
		return 0
	end
	return player.nCurrentPrestige
end

----ս�׻���
function LR.GetSelfZhanJieJiFen()
	local player=GetClientPlayer()
	if not player then
		return 0
	end
	return player.nTitlePoint
end

----ս�׵ȼ�
function LR.GetSelfZhanJieDengJi()
	local player=GetClientPlayer()
	if not player then
		return 0
	end
	return player.nTitle
end

----������
function LR.GetSelfMingJianBi()
	local player=GetClientPlayer()
	if not player then
		return 0
	end
	return player.nArenaAward
end

---------------------------------------------------
--��ȡ�ķ�����
---------------------------------------------------
--[[10002 ϴ�辭 10003 �׽ 10014 ��ϼ�� 10015 ̫�齣�� 10021 ������ 10026 ��Ѫս�� 10028 �뾭�׵� 10062 ������ 10080 �����ľ� 10081 ���ľ� 10144 ��ˮ�� 10145 ɽ�ӽ���]]
function LR.GetXinFa(dwSkillID)
	local me=GetClientPlayer()
	if not me then
		return
	end
	if dwSkillID then
		return Table_GetSkillName(dwSkillID,1)
	else
		local kungfu=me.GetKungfuMount()
		local dwSkillID=kungfu.dwSkillID
		return Table_GetSkillName(dwSkillID,1)
	end
end

-------------------------------------------------
--���������
-------------------------------------------------
function LR.OpenInternetExplorer(szAddr, bDisableSound)
	if Login then
		local _,_,_,szVersionEx = GetVersion()
		if szVersionEx == "snda" then
			if Login.m_StateLeaveFunction == Login.LeavePassword then
				Login.ShowSdoaWindows(false)
			end
		end
	end

	local nIndex = nil
	local nLast = nil
	for i = 1, 10, 1 do
		if not LR.IsInternetExplorerOpened(i) then
			nIndex = i
			break
		elseif not nLast then
			nLast = i
		end
	end
	if not nIndex then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.MSG_OPEN_TOO_MANY)
		return nil
	end
	local x, y = LR.IE_GetNewIEFramePos()
	local frame = Wnd.OpenWindow("InternetExplorer", sformat("IE%d", nIndex))
	frame.bIE = true
	frame.nIndex = nIndex

	frame:BringToTop()
	if nLast then
		frame:SetAbsPos(x, y)
		frame:CorrectPos()
		frame.x = x
		frame.y = y
	else
		frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		frame.x, frame.y = frame:GetAbsPos()
	end
	local webPage = frame:Lookup("WebPage_Page")
	if szAddr then
		webPage:Navigate(szAddr)
	end
	Station.SetFocusWindow(webPage)
	if not bDisableSound then
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
	return webPage
end

function LR.IsInternetExplorerOpened(nIndex)
	local frame = Station.Lookup(sformat("Topmost/IE%d", nIndex))
	if frame and frame:IsVisible() then
		return true
	end
	return false
end

function LR.IE_GetNewIEFramePos()
	local nLastTime = 0
	local nLastIndex = nil
	for i = 1, 10, 1 do
		local frame = Station.Lookup(sformat("Topmost/IE%d", i))
		if frame and frame:IsVisible() then
			if frame.nOpenTime > nLastTime then
				nLastTime = frame.nOpenTime
				nLastIndex = i
			end
		end
	end
	if nLastIndex then
		local frame = Station.Lookup(sformat("Topmost/IE%d", nLastIndex))
		x, y = frame:GetAbsPos()
		local wC, hC = Station.GetClientSize()
		if x + 890 <= wC and y + 630 <= hC then
			return x + 30, y + 30
		end
	end
	return 40, 40
end

--------------------------------------------------------
---��Ǯ����
--------------------------------------------------------
function LR.MoneyToGoldSilverAndCopper (nMoney)
	local nGoldBrick,nGold, nSilver, nCopper = 0, 0, 0, 0
	if nMoney >= 0 then
		nGoldBrick = mfloor(nMoney / 100000000)
		nGold = mfloor((nMoney- nGoldBrick*100000000 ) / 10000)
		nSilver = mfloor((nMoney-nGoldBrick*100000000 - nGold*10000)/100)
		nCopper = mfloor((nMoney - nGoldBrick*100000000 - nGold*10000-nSilver*100)/1)
		return nGoldBrick,nGold, nSilver, nCopper
	else
		nMoney = - nMoney
		nGoldBrick = mfloor(nMoney / 100000000)
		nGold = mfloor((nMoney- nGoldBrick*100000000 ) / 10000)
		nSilver = mfloor((nMoney-nGoldBrick*100000000 - nGold*10000)/100)
		nCopper = mfloor((nMoney - nGoldBrick*100000000 - nGold*10000-nSilver*100)/1)
		return -nGoldBrick, -nGold, -nSilver, -nCopper
	end
end

function LR.FormatMoneyString(nMoney, bSelfFont, plusFont, minusFont)
	local font = 5
	if bSelfFont then
		if nMoney >= 0 then
			font = plusFont or 5
		else
			font = minusFont or 71
		end
	end
	local nGoldBrick, nGold, nSilver, nCopper = LR.MoneyToGoldSilverAndCopper(mabs(nMoney))
	local string_nGoldBrick = sformat("%s%s", GetFormatText(nGoldBrick, font), GetFormatImage("ui\\Image\\Common\\Money.UITex", 27, 24, 24))
	local string_nGold = sformat("%s%s", GetFormatText(nGold, font), GetFormatImage("ui\\Image\\Common\\Money.UITex", 0, 24, 24))
	local string_nSilver = sformat("%s%s", GetFormatText(nSilver, font), GetFormatImage("ui\\Image\\Common\\Money.UITex", 2, 24, 24))
	local string_nCopper = sformat("%s%s", GetFormatText(nCopper, font), GetFormatImage("ui\\Image\\Common\\Money.UITex", 1, 20, 20))
	local output_string = ""
	if nGoldBrick >0  then
		output_string = sformat("%s%s%s%s", string_nGoldBrick, string_nGold, string_nSilver, string_nCopper)
	elseif nGold>0 then
		output_string = sformat("%s%s%s", string_nGold, string_nSilver, string_nCopper)
	elseif nSilver>0 then
		output_string = sformat("%s%s", string_nSilver, string_nCopper)
	elseif nCopper >0 then
		output_string = sformat("%s", string_nCopper)
	end
	if nMoney < 0 then
		output_string = sformat("- %s", output_string)
	end
	return output_string
end
--------------------------------------------------------
---��ɫ��
--------------------------------------------------------
local DefaltColor= {
	Version="1.1",
	Color={
		KungFuColor={
			[0]  = {255, 255, 255},		----����
			[1]  = {255, 178, 95},			----����
			[2]  = {196, 152, 255},		----��
			[3]  = {255, 111, 83},			----���
			[4]  = {22, 216, 216},		----����
			[5]  = {255, 129, 176},		----����
			[6]  = {55, 147, 255},			----�嶾
			[7]  = {121, 183, 54},			----����
			[8]  = {214, 249, 93},			----�ؽ�
			[9]  = {205,133,63},			----ؤ��
			[10] = {240, 70, 96},			----����
			[21] = {180, 60, 0},		--����
			[22] = {100, 250, 180},	--������
			[23] = {106 , 108, 189},			----�Ե�
		},
		CampColor={
			[0] = {128, 255, 128},	--����
			[1] = {64, 64, 255},	--����
			[2] = {255, 64, 64},	--����
		},
		RelationColor={
			["Enemy"] = {},	--�ж�
			["Ally"] = {},	--�Ѻ�
			["Neutrality"] = {},	--����
			["Party"] = {},	--�Ŷ�
			["Self"] = {},	--�Լ�
		},
	},
}
LR.MenPaiColor = clone(DefaltColor.Color.KungFuColor)
LR.CampColor = clone(DefaltColor.Color.CampColor)
LR.RelationColor = clone(DefaltColor.Color.RelationColor)

function LR.GetMenPaiByKungfuID(dwKungfuID)
	if not dwKungfuID then  ----����
		return 0
	elseif dwKungfuID==10002 or dwKungfuID==10002 then	----����
		return 1
	elseif dwKungfuID==10021 or dwKungfuID==10028 then	----��
		return 2
	elseif dwKungfuID==10026 or dwKungfuID==10062 then	----���
		return 3
	elseif dwKungfuID==10014 or dwKungfuID==10015 then	----����
		return 4
	elseif dwKungfuID==10080 or dwKungfuID==10081 then	----����
		return 5
	elseif dwKungfuID==10175 or dwKungfuID==10176 then	----�嶾
		return 6
	elseif dwKungfuID==10224 or dwKungfuID==10225 then	----����
		return 7
	elseif dwKungfuID==10144 or dwKungfuID==10144 then	----�ؽ�
		return 8
	elseif dwKungfuID==10268 then	----ؤ��
		return 9
	elseif dwKungfuID==10242 or dwKungfuID==10243 then	----����
		return 10
	elseif dwKungfuID==10389 or dwKungfuID==10390 then	----����
		return 21
	elseif dwKungfuID==10447 or dwKungfuID==10448 then	----������
		return 22
	elseif dwKungfuID==10464  then	----�Ե�
		return 23
	else
		return 0
	end
end

function LR.GetMenPaiColor(dwForceID)
	local color = LR.MenPaiColor[dwForceID] or {255, 255, 255}
	return unpack(color)
end

function LR.ResetMenPaiColor()
	LR.MenPaiColor = clone(DefaltColor.Color.KungFuColor)
	LR.SaveMenPaiColor()
end

function LR.LoadMenPaiColor()
	local path=sformat("%s\\MenPaiColor.dat",SaveDataPath)
	local data=LoadLUAData(path) or {}
	if data.Version and data.Version == DefaltColor.Version then
		LR.MenPaiColor = clone(data.Color.KungFuColor)
	else
		LR.ResetMenPaiColor()
	end
end

function LR.SaveMenPaiColor()
	local path=sformat("%s\\Color.dat",SaveDataPath)
	local data={}
	data.Version = DefaltColor.Version
	data.Color={}
	data.Color.KungFuColor = clone (LR.MenPaiColor)
	data.Color.CampColor = clone (LR.CampColor)
	data.Color.RelationColor = clone(LR.RelationColor)
	SaveLUAData(path,data)
end
--------------------------------------------------------
---bufflist
--------------------------------------------------------
function LR.GetBuffList(obj)
	local aBuffTable = {}
	if not obj or obj==nil then
		return {}
	end
	if obj.dwID==nil then
		return {}
	end
	local nCount = obj.GetBuffCount()
	for i=1,nCount,1 do
		local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid , bIsStackable , nLeftFrame = obj.GetBuff(i - 1)
		if dwID then
			tinsert(aBuffTable,{dwID = dwID, nLevel = nLevel, bCanCancel = bCanCancel, nEndFrame = nEndFrame, nIndex = nIndex, nStackNum = nStackNum, dwSkillSrcID = dwSkillSrcID, bValid = bValid , bIsStackable= bIsStackable, nLeftFrame = nLeftFrame})
		end
	end
	return aBuffTable
end

function LR.HasBuff (tBuffList,dwBuffID_szName)
	for i=1,#tBuffList,1 do
		if tBuffList[i].dwID == dwBuffID_szName or Table_GetBuffName( tBuffList[i].dwID, tBuffList[i].nLevel) == dwBuffID_szName  then
			return true
		end
	end
	return false
end

function LR.GetBuffOrderinBuffList(tBuffList,dwBuffID_szName)
	for i=1,#tBuffList,1 do
		if tBuffList[i].dwID == dwBuffID_szName or Table_GetBuffName( tBuffList[i].dwID, tBuffList[i].nLevel) == dwBuffID_szName  then
			return i
		end
	end
	return 0
end

function LR.GetBuffByID(obj, dwID)
	local buffList = LR.GetBuffList(obj)
	for k, v in pairs (buffList) do
		if v.dwID == dwID then
			return v
		end
	end
	return nil
end


-- ׷��С��ͼ���
-- (void) LR.UpdateMiniFlag(number dwType, KObject tar, number nF1[, number nF2])
-- dwType	-- ���ͣ�8 - ������5 - Doodad��7 - ���� NPC��2 - ��ʾ�㣬1 - ���ѣ�4 - ���� NPC
-- tar			-- Ŀ����� KPlayer��KNpc��KDoodad
-- nF1			-- ͼ��֡��
-- nF2			-- ��ͷ֡�Σ�Ĭ�� 48 ����
function LR.UpdateMiniFlag(dwType, tar, nF1, nF2)
	local nX, nZ = Scene_PlaneGameWorldPosToScene(tar.nX, tar.nY)
	local m = Station.Lookup("Normal/Minimap/Wnd_Minimap/Minimap_Map")
	if m then
		m:UpdataArrowPoint(dwType, tar.dwID, nF1, nF2 or 48, nX, nZ, 16)
	end
end


----------------------------------------
--�������
----------------------------------------
-- (KObject) LR.GetTarget()														-- ȡ�õ�ǰĿ���������
-- (KObject) LR.GetTarget([number dwType, ]number dwID)	-- ���� dwType ���ͺ� dwID ȡ�ò�������
function LR.GetTarget (dwType, dwID)
	if not dwType then
		local me = GetClientPlayer()
		if me then
			dwType, dwID = me.GetTarget()
		else
			dwType, dwID = TARGET.NO_TARGET, 0
		end
	elseif not dwID then
		dwID, dwType = dwType, TARGET.NPC
		if IsPlayer(dwID) then
			dwType = TARGET.PLAYER
		end
	end
	if dwID <= 0 or dwType == TARGET.NO_TARGET then
		return nil, TARGET.NO_TARGET
	elseif dwType == TARGET.PLAYER then
		return GetPlayer(dwID), TARGET.PLAYER
	elseif dwType == TARGET.DOODAD then
		return GetDoodad(dwID), TARGET.DOODAD
	else
		return GetNpc(dwID), TARGET.NPC
	end
end

function LR.GetCharacter(dwID)
	if IsPlayer(dwID) then
		return GetPlayer(dwID)
	else
		return GetNpc(dwID)
	end
end

-- ����Ŀ��������ľ���
-- (number) LR.GetDistance(KObject tar)
-- (number) LR.GetDistance(number nX, number nY[, number nZ])
-- tar		-- ���� nX��nY��nZ �����Ե� table �� KPlayer��KNpc��KDoodad
-- nX		-- ��������ϵ�µ�Ŀ��� X ֵ
-- nY		-- ��������ϵ�µ�Ŀ��� Y ֵ
-- nZ		-- *��ѡ* ��������ϵ�µ�Ŀ��� Z ֵ
function LR.GetDistance(nX, nY, nZ)
	local NX,XY,NZ
	local me = GetClientPlayer()
	if not nX then
		return 0
	elseif not me then
		return 0
	elseif not nY and not nZ then
		local tar = nX
		NX, NY, NZ = tar.nX, tar.nY, tar.nZ
	elseif not nZ then
		return mfloor(((me.nX - nX) ^ 2 + (me.nY - nY) ^ 2) ^ 0.5)/64
	end
	return mfloor(((me.nX - NX) ^ 2 + (me.nY - NY) ^ 2 + (me.nZ/8 - NZ/8) ^ 2) ^ 0.5)/64
end

---------------------------------------------
---������Ϣ
---------------------------------------------
--------����ϵͳ��Ϣ
function LR.SysMsg (szText, nType, bRich, nFont, tColor)
	local nType = nType or "MSG_SYS"
	OutputMessage(nType,szText, bRich, nFont, tColor)
end

function LR.Debug(szText , szHeader , nLevel )
	if not (LR.UsrData and LR.UsrData.Debug_enable) then
		return
	end
	local szText=szText or ""
	local nLevel = nLevel or 1
	local szHeader = szHeader or "-LR-> "
	if not (nLevel >= LR.UsrData.Debug_Level) then
		return
	end
	if type(szText) == "string" then
		LR.SysMsg(sformat("%s%s\n", szHeader, szText))
	elseif type(szText) == "number" then
		LR.SysMsg(sformat("%s%s\n", szHeader, tostring(szText)))
	elseif type(szText) == "table" then
		LR.SysMsg(sformat("%s{\n", szHeader))
		if next(szText)~=nil then
			for k,v in pairs(szText) do
				LR.SysMsg(sformat("%s\[%d\]=", szHeader, k))
				if type(v) == "string" or type(v)=="number" then
					LR.Debug(v , "" , nLevel)
				elseif type(v) == "table" then
					LR.Debug(v , szHeader.."    " , nLevel)
				end
			end
		end
		LR.SysMsg(sformat("%s}\n", szHeader))
	end
end

function LR.bCanDebug()
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	if realArea == "����һ��" and realServer == "�쳾Ѱ��" and IsShiftKeyDown() and IsAltKeyDown() then
		return true
	else
		return false
	end
end

function LR.bCanDebug2()
	local me = GetClientPlayer()
	local ServerInfo = {GetUserServer()}
	local Area, Server, realArea, realServer = ServerInfo[3], ServerInfo[4], ServerInfo[5], ServerInfo[6]
	if realArea == "����һ��" and realServer == "�쳾Ѱ��" and LR.GetTongName(me.dwTongID) == "ôô��������" then
		return true
	else
		return false
	end
end

---------------------------------------------
---����ϵͳ����
---------------------------------------------
function LR.RedAlert(...)
	OutputWarningMessage("MSG_WARNING_RED", ...)
end

function LR.YellowAlert(...)
	OutputWarningMessage("MSG_WARNING_YELLOW", ...)
end

function LR.GreenAlert(...)
	OutputWarningMessage("MSG_WARNING_GREEN", ...)
end

---------------------------------------------
---����Ƶ������
---------------------------------------------
local TALK_BAN = false

LR.tTalkChannelHeader = {
	[PLAYER_TALK_CHANNEL.NEARBY] = "/s ",
	[PLAYER_TALK_CHANNEL.FRIENDS] = "/o ",
	[PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = "/a ",
	[PLAYER_TALK_CHANNEL.RAID] = "/t ",
	[PLAYER_TALK_CHANNEL.BATTLE_FIELD] = "/b ",
	[PLAYER_TALK_CHANNEL.TONG] = "/g ",
	[PLAYER_TALK_CHANNEL.SENCE] = "/y ",
	[PLAYER_TALK_CHANNEL.FORCE] = "/f ",
	[PLAYER_TALK_CHANNEL.CAMP] = "/c ",
	[PLAYER_TALK_CHANNEL.WORLD] = "/h ",
}

-- parse faceicon in talking message
function LR.ParseFaceIcon (t)
	if not LR.tFaceIcon then
		LR.tFaceIcon = {}
		for i = 1, g_tTable.FaceIcon:GetRowCount() do
			local tLine = g_tTable.FaceIcon:GetRow(i)
			LR.tFaceIcon[tLine.szCommand] = {bTrue=true,dwID=tLine.dwID}
		end
	end
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type ~= "text" then
			if v.type == "faceicon" then
				v.type = "text"
			end
			tinsert(t2, v)
		else
			local nOff, nLen = 1, slen(v.text)
			while nOff <= nLen do
				local szFace = nil
				local nPos = sfind(v.text, "#", nOff)
				if not nPos then
					nPos = nLen
				else
					for i = nPos + 6, nPos + 2, -2 do
						if i <= nLen then
							local szTest = ssub(v.text, nPos, i)
							if LR.tFaceIcon[szTest] then
								if LR.tFaceIcon[szTest].bTrue then
									szFace = szTest
									nPos = nPos - 1
									break
								end
							end
						end
					end
				end
				if nPos >= nOff then
					tinsert(t2, { type = "text", text = ssub(v.text, nOff, nPos) })
					nOff = nPos + 1
				end
				if szFace then
					tinsert(t2, { type = "emotion", text = szFace , id= LR.tFaceIcon[szFace].dwID })
					nOff = nOff + slen(szFace)
				end
			end
		end
	end
	return t2
end


-- �ж�ĳ��Ƶ���ܷ���
-- (bool) LR.CanTalk(number nChannel)
function LR.CanTalk(nChannel)
	for _, v in ipairs({"WHISPER", "TEAM", "RAID", "BATTLE_FIELD", "NEARBY", "TONG", "TONG_ALLIANCE" }) do
		if nChannel == PLAYER_TALK_CHANNEL[v] then
			return true
		end
	end
	return false
end

-- �л�����Ƶ��
-- (void) LR.SwitchChat(number nChannel)
function LR.SwitchChat(nChannel)
	local szHeader = LR.tTalkChannelHeader[nChannel]
	if szHeader then
		SwitchChatChannel(szHeader)
	elseif type(nChannel) == "string" then
		SwitchChatChannel(sformat("/w %s ", nChannel))
	end
end


-- ������������
-- (void) HM.Talk(string szTarget, string szText[, boolean bNoEmotion])
-- (void) HM.Talk([number nChannel, ] string szText[, boolean bNoEmotion])
-- szTarget			-- ���ĵ�Ŀ���ɫ��
-- szText				-- �������ݣ������Ϊ���� KPlayer.Talk �� table��
-- nChannel			-- *��ѡ* ����Ƶ����PLAYER_TALK_CHANNLE.*��Ĭ��Ϊ����
-- bNoEmotion	-- *��ѡ* ���������������еı���ͼƬ��Ĭ��Ϊ false
-- bSaveDeny	-- *��ѡ* �������������������ɷ��Ե�Ƶ�����ݣ�Ĭ��Ϊ false
-- �ر�ע�⣺nChannel, szText ���ߵĲ���˳����Ե�����ս��/�Ŷ�����Ƶ�������л�

--�°� LR.Talk()
function LR.Talk(nChannel, szText, szUUID, bNoEmotion, bSaveDeny, bNotLimit)
	if TALK_BAN then
		return
	end
	local szTarget, me = "", GetClientPlayer()
	-- channel
	if not nChannel then
		nChannel = PLAYER_TALK_CHANNEL.TONG_ALLIANCE
	elseif type(nChannel) == "string" then
		if not szText then
			szText = nChannel
			nChannel = PLAYER_TALK_CHANNEL.TONG_ALLIANCE
		elseif type(szText) == "number" then
			szText, nChannel = nChannel, szText
		else
			szTarget = nChannel
			nChannel = PLAYER_TALK_CHANNEL.WHISPER
		end
	elseif nChannel == PLAYER_TALK_CHANNEL.RAID and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
	elseif type(nChannel) == "table" then
		szText = nChannel
		nChannel = PLAYER_TALK_CHANNEL.TONG_ALLIANCE
	end
	if nChannel == PLAYER_TALK_CHANNEL.RAID and not me.IsInParty() then
		return
	end

	-- say bodyT
	local tSay = nil
	if type(szText) == "table" then
		tSay = szText
	else
		local tar = LR.GetTarget(me.GetTarget())
		szText = sgsub(szText, "%$zj", me.szName)
		if tar then
			szText = sgsub(szText, "%$mb", tar.szName)
		end
		if wslen(szText) > 150 and not bNotLimit then
			szText = wssub(szText, 1, 150)
		end
		tSay = {{ type = "text", text = sformat("%s\n", szText),}}
	end
	if not bNoEmotion then
		tSay = LR.ParseFaceIcon(tSay)
	end
	-- add addon msg header

	if  tSay[1] or  (tSay[1].type == "eventlink" and tSay[1].name == "BG_CHANNEL_MSG") then
		--or  not (tSay[1].type == "eventlink" and tSay[1].name == "BG_CHANNEL_MSG") -- bgmsg
 		--and not (tSay[1].name == "" and tSay[1].type == "eventlink") -- header already added
	else
		tinsert(tSay, 1, {
			type = "eventlink",
			name = "",
--[[			linkinfo = LR.JsonEncode({
				via = "LR",
				uuid = szUUID and tostring(szUUID),
			}),]]
		})
	end
	if bSaveDeny and not LR.CanTalk(nChannel) then
		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		edit:ClearText()
		for _, v in ipairs(tSay) do
			if v.type == "text" then
				edit:InsertText(v.text)
			else
				edit:InsertObj(v.text, v)
			end
		end
		-- change to this channel
		LR.SwitchChat(nChannel)
	else
		me.Talk(nChannel, szTarget, tSay)
	end
end

-- �޷�����ʱ���������������
-- �°� LR.Talk2()
function LR.Talk2(nChannel, szText, szUUID, bNoEmotion)
	LR.Talk(nChannel, szText, szUUID, bNoEmotion, true)
end


-- ������̨����ͨѶ
-- (void) LR.BgTalk(szTarget, ...)
-- (void) LR.BgTalk(nChannel, ...)
-- szTarget			-- ���ĵ�Ŀ���ɫ��
-- nChannel			-- *��ѡ* ����Ƶ����PLAYER_TALK_CHANNLE.*��Ĭ��Ϊ����
-- ...						-- ���ɸ��ַ���������ɣ���ԭ��������

-- �°� LR.BgTalk()
function LR.BgTalk(nChannel, szKey, ...)
	local tSay = { { type = "eventlink", name = "BG_CHANNEL_MSG", linkinfo = szKey } }
	local tArg = { ... }
	for _, v in ipairs(tArg) do
		if v == nil then
			break
		end
		tinsert(tSay, { type = "eventlink", name = "", linkinfo = var2str(v) })
	end
	LR.Talk(nChannel, tSay, nil, true)
end

-- ��ȡ��̨�������ݣ��� ON_BG_CHANNEL_MSG �¼���������ʹ�ò�������
-- (table) LR.BgHear([string szKey])
-- szKey			-- ͨѶ���ͣ�Ҳ���� HM.BgTalk �ĵ�һ���ݲ���������ƥ�������
-- arg0: dwTalkerID, arg1: nChannel, arg2: bEcho, arg3: szName
-- �°� LR.BgHear()
function LR.BgHear(szKey, bIgnore)
	local me = GetClientPlayer()
	local tSay = me.GetTalkData()
	if tSay and (arg0 ~= me.dwID or bIgnore) and #tSay > 1 and (tSay[1].name == "BG_CHANNEL_MSG") and tSay[1].type == "eventlink" then
		local tData, nOff = {}, 2
			if szKey then
				if szKey ~= tSay[1].linkinfo then
					return nil
				end
			end
--[[		if szKey then
			if tSay[nOff].linkinfo ~= szKey then
				return nil
			end
			nOff = nOff + 1
		end]]

		for i = nOff, #tSay do
			tinsert(tData, tSay[i].linkinfo)
		end

		return tData
	end
end

-- ��������ʼ��
LR.nMaxEmotionLen = 0
function LR.InitEmotion ()
	if not LR.tEmotion then
		local t = {}
		for i = 1, g_tTable.FaceIcon:GetRowCount() do
			local tLine = g_tTable.FaceIcon:GetRow(i)
			local t1 = {
				nFrame = tLine.nFrame,
				dwID   = tLine.dwID or (10000 + i),
				szCmd  = tLine.szCommand,
				szType = tLine.szType,
				szImageFile = tLine.szImageFile or 'ui/Image/UICommon/Talk_face.UITex'
			}
			t[t1.dwID] = t1
			t[t1.szCmd] = t1
			t[t1.szImageFile..','..t1.nFrame..','..t1.szType] = t1
			LR.nMaxEmotionLen = mmax(LR.nMaxEmotionLen, wslen(t1.szCmd))
		end
		LR.tEmotion = t
	end
end

-- ��ȡ��������б�
-- typedef emo table
-- (emo[]) MY.Chat.GetEmotion()                             -- �������б����б�
-- (emo)   MY.Chat.GetEmotion(szCommand)                    -- ����ָ��Cmd�ı���
-- (emo)   MY.Chat.GetEmotion(szImageFile, nFrame, szType)  -- ����ָ��ͼ��ı���
function LR.GetEmotion (arg0, arg1, arg2)
	LR.InitEmotion()
	local t
	if not arg0 then
		t = LR.tEmotion
	elseif not arg1 then
		t = LR.tEmotion[arg0]
	elseif arg2 then
		arg0 = sgsub(arg0, '\\\\', '\\')
		t = LR.tEmotion[arg0..','..arg1..','..arg2]
	end
	return clone(t)
end

function LR.FormatContent(szMsg)
	local t = {}
	for n, w in sgfind(szMsg, "<(%w+)>(.-)</%1>") do
		if w then
			tinsert(t, w)
		end
	end

	local t2 = {}
	for k, v in pairs(t) do
		if not sfind(v, "name=") then
			if sfind(v, "frame=") then
				local n = smatch(v, "frame=(%d+)")
				local p = smatch(v, 'path="(.-)"')
				local emo = LR.GetEmotion(p, n, 'image')
				if emo then
					tinsert(t2, {type = "emotion", text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID})
				end
			elseif sfind(v, "group=") then
				local n = smatch(v, "group=(%d+)")
				local p = smatch(v, 'path="(.-)"')
				local emo = LR.GetEmotion(p, n, 'animate')
				if emo then
					tinsert(t2, {type = "emotion", text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID})
				end
			else
				--��ͨ����
				local s = smatch(v, "\"(.*)\"")
				tinsert(t2, {type= "text", text = s, innerText = s})
			end
		else
			--��Ʒ����
			if sfind(v, "name=\"itemlink\"") then
				local name, userdata = smatch(v,"%[(.-)%].-userdata=(%d+)")
				tinsert(t2, {type = "item", text = "["..name.."]", innerText = name, item = userdata})
			--��Ʒ��Ϣ
			elseif sfind(v, "name=\"iteminfolink\"") then
				local name, version, tab, index = smatch(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\%s*this.dwTabType=(%d+)\\%s*this.dwIndex=(%d+)")
				tinsert(t2, {type = "iteminfo", text = "["..name.."]", innerText = name, version = version, tabtype = tab, index = index})
			--����
			elseif sfind(v, "name=\"namelink_%d+\"") then
				local name = smatch(v,"%[(.-)%]")
				tinsert(t2, {type = "name", text = "["..name.."]", innerText = "["..name.."]", name = name})
			--����
			elseif sfind(v, "name=\"questlink\"") then
				local name, userdata = smatch(v,"%[(.-)%].-userdata=(%d+)")
				tinsert(t2, {type = "quest", text = "["..name.."]", innerText = name, questid = userdata})
			--�����
			elseif sfind(v, "name=\"recipelink\"") then
				local name, craft, recipe = smatch(v,"%[(.-)%].-script=\"this.dwCraftID=(%d+)\\%s*this.dwRecipeID=(%d+)")
				tinsert(t2, {type = "recipe", text = "["..name.."]", innerText = name, craftid = craft, recipeid = recipe})
			--����
			elseif sfind(v, "name=\"skilllink\"") then
				local name, skillinfo = smatch(v,"%[(.-)%].-script=\"this.skillKey=%{(.-)%}")
				local skillKey = {}
				for w in sgfind(skillinfo, "(.-)%,") do
					local k, v  = smatch(w, "(.-)=(%w+)")
					skillKey[k] = v
				end
				skillKey.text = "["..name.."]"
				skillKey.innerText = "["..name.."]"
				tinsert(t2, skillKey)
			--�ƺ�
			elseif sfind(v, "name=\"designationlink\"") then
				local name, id, fix = smatch(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\%s*this.bPrefix=(.-)")
				tinsert(t2, {type = "designation", text = "["..name.."]", innerText = name, id = id, prefix = fix})
			--�����ؼ�
			elseif sfind(v, "name=\"skillrecipelink\"") then
				local name, id, level = smatch(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\%s*this.dwLevel=(%d+)")
				tinsert(t2, {type = "skillrecipe", text = "["..name.."]", innerText = name, id = id, level = level})
			--�鼮
			elseif sfind(v, "name=\"booklink\"") then
				local name, version, tab, index, id = smatch(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\%s*this.dwTabType=(%d+)\\%s*this.dwIndex=(%d+)\\%s*this.nBookRecipeID=(%d+)")
				tinsert(t2, {type = "book", text = "["..name.."]", innerText = name, version = version, tabtype = tab, index = index, bookinfo = id})
			--�ɾ�
			elseif sfind(v, "name=\"achievementlink\"") then
				local name, id = smatch(v,"%[(.-)%].-script=\"this.dwID=(%d+)")
				tinsert(t2, {type = "achievement", text = "["..name.."]", innerText = name, id = id})
			--ǿ��
			elseif sfind(v, "name=\"enchantlink\"") then
				local name, pro, craft, recipe = smatch(v,"%[(.-)%].-script=\"this.dwProID=(%d+)\\%s*this.dwCraftID=(%d+)\\%s*this.dwRecipeID=(%d+)")
				tinsert(t2, {type = "enchant", text = "["..name.."]", innerText = name, proid = pro, craftid = craft, recipeid = recipe})
			--�¼�
			elseif sfind(v, "name=\"eventlink\"") then
				local name, na, info = smatch(v,'text="(.-)".-script="this.szName=\\"(.-)\\"\\%s*this.szLinkInfo=\\"(.-)\\"')
				tinsert(t2, {type = "eventlink", text = name, innerText = name, name = na, linkinfo = info or ""})
			end
		end
	end
	return t2
end

-----------------------------------------------------------
function LR.GetTemplateName(tar, bEmployer)
	if not tar then
		return "δ֪����"
	end
	local szName = tar.szName
	if not tar.dwID or not IsPlayer(tar.dwID) then
		if szName == "" then
			szName = Table_GetNpcTemplateName(tar.dwTemplateID)
		end
		if tar.dwEmployer and tar.dwEmployer ~= 0 and szName == Table_GetNpcTemplateName(tar.dwTemplateID) and bEmployer then
			local emp = GetPlayer(tar.dwEmployer)
			if not emp then
				szName =  g_tStrings.STR_SOME_BODY .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
			else
				szName = emp.szName .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
			end
		end
		if LR.Trim(szName) == "" then
			szName = tostring(tar.dwTemplateID)
		end
	end
	return szName
end

function LR.GetTongName(dwTongID)
	if dwTongID and type(dwTongID) == "number" and dwTongID>0 then
		local Tong=GetTongClient()
		return LR.Trim(Tong.ApplyGetTongName(dwTongID))
	else
		return ""
	end
end
-------------------------------------------------------------------------------
----------------�������
-------------------------------------------------------------------------------

LR.tAllSceneQuest={}  ---------------�����������
--------LR.tAllSceneQuest[��ͼID][����ID]=
--[[	Quest =
	{
		Path = "\\UI\\Scheme\\Case\\quest.txt",
		Title =
		{
			{f = "i", t = "dwQuestID"},
			{f = "s", t = "szAccept"},
			{f = "s", t = "szFinish"},
			{f = "s", t = "szQuestState1"},
			{f = "s", t = "szQuestState2"},
			{f = "s", t = "szQuestState3"},
			{f = "s", t = "szQuestState4"},
			{f = "s", t = "szQuestState5"},
			{f = "s", t = "szQuestState6"},
			{f = "s", t = "szQuestState7"},
			{f = "s", t = "szQuestState8"},
			{f = "s", t = "szKillNpc1"},
			{f = "s", t = "szKillNpc2"},
			{f = "s", t = "szKillNpc3"},
			{f = "s", t = "szKillNpc4"},
			{f = "s", t = "szNeedItem1"},
			{f = "s", t = "szNeedItem2"},
			{f = "s", t = "szNeedItem3"},
			{f = "s", t = "szNeedItem4"},
		},
	},]]

function LR.Table_GetQuestPosInfo(dwQuestID, szType, nIndex)
	local tQuestPosInfo = g_tTable.Quest:Search(dwQuestID)
	if not tQuestPosInfo then
		return
	end
-- 	if tonumber(dwQuestID)==11201 then
-- 		Output(tQuestPosInfo)
-- 	end
	local szQuestPos = nil
	if szType == "accept" then
		szQuestPos = tQuestPosInfo.szAccept
	elseif szType == "finish" then
		szQuestPos = tQuestPosInfo.szFinish
	elseif szType == "quest_state" then
		szQuestPos = tQuestPosInfo["szQuestState" .. nIndex + 1]
	elseif szType == "kill_npc" then
		szQuestPos = tQuestPosInfo["szKillNpc" .. nIndex + 1]
	elseif szType == "need_item" then
		szQuestPos = tQuestPosInfo["szNeedItem" .. nIndex + 1]
	end

	if szQuestPos == "" then
		szQuestPos = nil
	end
-- 	if tonumber(dwQuestID)==11201 then
-- 		Output(szQuestPos)
-- 	end

	return szQuestPos
end

function LR.Table_GetQuestPoint(dwQuestID, szType, nIndex)
	local szPosInfo = LR.Table_GetQuestPosInfo(dwQuestID, szType, nIndex)
	if not szPosInfo then
		return
	end
	return LR.GetQuestPoint(szPosInfo)
end

function LR.ParseNumberList(szNumberList)	-- 23,544;234,345,342,334;
	local tNumberList = {}
	for szData in sgmatch(szNumberList, "([%d,]+);?") do
		local tNumber = {}
		for szNumber in sgmatch(szData, "(%d+),?") do
			tinsert(tNumber, tonumber(szNumber))
		end
		tinsert(tNumberList, tNumber)
	end
	return tNumberList
end

function LR.GetQuestPoint(szPointList)
	local tPointList = {}
	for szType, szData in sgmatch(szPointList, "<(%a) ([%d,;|]+)>") do
		local szFrame, szSource = smatch(szData, "([%d]+)|([%d,;]+)")
		local nFrame
		if szFrame and szFrame ~= "" and szSource and szSource ~= "" then
			szData = szSource
			nFrame = tonumber(szFrame)
		end
		if szType == "N" or szType == "D" then	-- npc
			local tData = LR.ParseNumberList(szData)
			for _, tInfo in ipairs(tData) do
				local dwMapID = tInfo[1]
				local dwObject = tInfo[2]
				local tQuestPos = nil
				if szType == "N" then
					tQuestPos = g_tTable.QuestNpc:Search(dwObject, dwMapID)
				else
					tQuestPos = g_tTable.QuestDoodad:Search(dwObject, dwMapID)
				end
				if tQuestPos and tQuestPos.szPositions ~= "" then
					if not tPointList[dwMapID] then
						tPointList[dwMapID] = {}
					end
					local tPosList = LR.ParseNumberList(tQuestPos.szPositions)
					for _, tPosition in ipairs(tPosList) do
						tinsert(tPointList[dwMapID], {tPosition[1], tPosition[2], szType, dwObject, nFrame})
					end
				end
			end
		elseif szType == "P" then	-- postion
			local tData = LR.ParseNumberList(szData)
			for _, tPosition in ipairs(tData) do
				local dwMapID = tPosition[1]
				if not tPointList[dwMapID] then
					tPointList[dwMapID] = {}
				end
				tinsert(tPointList[dwMapID], {tPosition[2], tPosition[3], szType, nil, nFrame})
			end
		else

		end
	end
	return tPointList
end

function LR.Table_GetQuestStringInfo(dwQuestID)
	local tQuestStringInfo = g_tTable.Quests:Search(dwQuestID)
	return tQuestStringInfo
end

function LR.IsQuestNameShield(szName)
	for _, szShield in ipairs(g_tStrings.tQuestShieldName) do
		if szName == szShield then
			return true
		end
	end
	return false
end

function LR.Table_GetAllSceneQuest(dwMapID)
	local tSceneQuest = {}
	if LR.tAllSceneQuest[dwMapID] then
		tSceneQuest = LR.tAllSceneQuest[dwMapID]
	end

	return tSceneQuest
end

function LR.Table_LoadSceneQuest()
	local nRow = g_tTable.Quest:GetRowCount()

	-- Row 1 for default Row
	for i = 2, nRow  do
		local tQuestPosInfo = g_tTable.Quest:GetRow(i)
		dwQuestID = tQuestPosInfo.dwQuestID
		local tQuestStringInfo = LR.Table_GetQuestStringInfo(dwQuestID)
		if tQuestStringInfo then
-- 			local tShield = g_tTable.ShieldQuest:Search(dwQuestID)
-- 			local bQuestNameShield = LR.IsQuestNameShield(tQuestStringInfo.szName)
-- 			if not bQuestNameShield and not tShield then
				local szPosInfo = tQuestPosInfo.szAccept
				for szType, szData in sgmatch(szPosInfo, "<(%a) ([%d,;|]+)>") do
					local szFrame, szSource = smatch(szData, "([%d]+)|([%d,;]+)")
					local nFrame
					if szFrame and szFrame ~= "" and szSource and szSource ~= "" then
						szData = szSource
						nFrame = tonumber(szFrame)
					end
					if szType == "N" or szType == "D" then	-- npc
						local tData = LR.ParseNumberList(szData)
						for _, tInfo in ipairs(tData) do
							local dwQuestMapID = tInfo[1]
							local dwObject = tInfo[2]
							if not LR.tAllSceneQuest[dwQuestMapID] then
								LR.tAllSceneQuest[dwQuestMapID] = {}
							end
							if not LR.tAllSceneQuest[dwQuestMapID][dwQuestID] then
								LR.tAllSceneQuest[dwQuestMapID][dwQuestID] = {}
							end
							tinsert(LR.tAllSceneQuest[dwQuestMapID][dwQuestID], {szType, dwObject})
						end
					end
				end
			--end
		end
	end
end

RegisterEvent("FIRST_LOADING_END",LR.Table_LoadSceneQuest)
---------------------------DOODAD
function LR.TABLE_GetDoodadTemplateName(dwTemplateID)
	if dwTemplateID==5402 then
		return "����ǹͷ"
	end
	local RowCount= g_tTable.DoodadTemplate:GetRowCount()
	local i=1
	while i<=RowCount do
		local t=g_tTable.DoodadTemplate:GetRow(i)
		if dwTemplateID==t.nID then
			return t.szName
		end
		i=i+1
	end
	return ""
end

-----------------------------------------------
---HotKey
-----------------------------------------------
local HotKeyList = {}
local HotKeyHistory = {}
local function DebugHotKey(szName)
	HotKeyHistory[#HotKeyHistory + 1] = szName
end

function LR.AddHotKey(szName, fnAction)
	HotKeyList[#HotKeyList + 1] = {szName = szName, fnAction = fnAction}
end

function LR.RegisterHotKey()
	for k, v in pairs (HotKeyList) do
		local szName = sformat("LR_Plugin_Hotkey_%d", k)
		if k == 1 then
			Hotkey.AddBinding(szName, v.szName, _L["LR Plugins"], v.fnAction, DebugHotKey(v.szName), false)
		else
			Hotkey.AddBinding(szName, v.szName, "", v.fnAction, DebugHotKey(v.szName), false)
		end
	end
	----Test
	if IsCtrlKeyDown() then
		local fnTest = {{fnAction = LR.GB_Long}, {fnAction = LR.CJ_TigerRun}}
		for k, v in pairs (fnTest) do
			Hotkey.AddBinding(sformat("LR_Plugin_Hotkey_%d", k + 100), sformat("%s%d", _L["TEST HOTKEY"], k), "", v.fnAction, DebugHotKey(sformat("%s%d", _L["TEST HOTKEY"], k)), false)
		end
	end
end


------------------------�¼���
-- handle event
function LR.EventHandler (szEvent)
	local tEvent = LR.tEvent[szEvent]
	if next(tEvent) ~= nil then
		for k,v in pairs (tEvent) do
			local res, err = pcall(v)
			if not res then
				--LR.Debug("EVENT#" .. szEvent .. "." .. k .." ERROR: " .. err)
			end
		end
	end
end
-- ע���¼�����ϵͳ���������ڿ���ָ��һ�� KEY ��ֹ��μ���
-- (void) LR.RegisterEvent(string szEvent, func fnAction[, string szKey])
-- szEvent		-- �¼������ں����һ���㲢����һ����ʶ�ַ������ڷ�ֹ�ظ���ȡ���󶨣��� LOADING_END.xxx
-- fnAction		-- �¼���������arg0 ~ arg9������ nil �൱��ȡ�����¼�
--�ر�ע�⣺�� fnAction Ϊ nil ���� szKey ҲΪ nil ʱ��ȡ������ͨ��������ע����¼�������
--ע��ʱ�ṹ��LR.RegisterEvent("event",function() ��Ҫִ�еĺ��� end)��һ��Ҫ��ôд
function LR.RegisterEvent (szEvent, fnAction)
	local szKey = nil
	local nPos = StringFindW(szEvent, ".")
	if nPos then
		szKey = ssub(szEvent, nPos + 1)
		szEvent = ssub(szEvent, 1, nPos - 1)
	end
	if not LR.tEvent[szEvent] then
		LR.tEvent[szEvent] = {}
		RegisterEvent(szEvent, function() LR.EventHandler(szEvent) end)
	end
	local tEvent = LR.tEvent[szEvent]
	if fnAction then
		if not szKey then
			tinsert(tEvent, fnAction)
		else
			tEvent[szKey] = fnAction
		end
	else
		if not szKey then
			LR.tEvent[szEvent] = nil
		else
			tEvent[szKey] = nil
		end
	end
end

-- ȡ���¼�������
-- (void) HM.UnRegisterEvent(string szEvent)
function LR.UnRegisterEvent (szEvent, fnAction)
	local szKey = nil
	local nPos = StringFindW(szEvent, ".")
	if nPos then
		szKey = ssub(szEvent, nPos + 1)
		szEvent = ssub(szEvent, 1, nPos - 1)
	end
	if not LR.tEvent[szEvent] then
		return
	end
	if fnAction then
		if not szKey then
			tremove(tEvent, fnAction)
		else
			tEvent[szKey] = nil
		end
	else
		if not szKey then
			tremove(LR.tEvent,szEvent)
		else
			tEvent[szKey] = nil
		end
	end
end

----------------------------------------------
function LR.GetPlayerBagFreeBoxList()
	local player = GetClientPlayer()
	local tBoxTable = {}
	for nIndex = 6, 1, -1 do
		local dwBox = INVENTORY_INDEX.PACKAGE + nIndex - 1
		local dwSize = player.GetBoxSize(dwBox)
		if dwSize > 0 then
			for dwX = dwSize, 1, -1 do
				local item = player.GetItem(dwBox, dwX - 1)
				if not item then
					local i, j = dwBox, dwX - 1
					tinsert(tBoxTable, {i, j})
				end
			end
		end
	end
	return tBoxTable
end

----------------------------------------------
-----���ֲ˵���ȡ
----------------------------------------------
function LR.GetShiTuMenu(dwID)
	local t={}
	local menu={}
	InsertTargetMenu(menu,dwID)
	for k,v in pairs (menu) do
		if v.szOption==g_tStrings.CHANNEL_MENTOR then
			t[1]=v
			return t
		end
	end
end

function LR.GetTradeMenu(dwID)
	local t={}
	local menu={}
	InsertTargetMenu(menu,dwID)
	for k,v in pairs (menu) do
		if v.szOption==g_tStrings.STR_MAKE_TRADDING then
			t[1]=v
			return t
		end
	end
end

function LR.GetMakeFriendMenu(dwID)
	local t={}
	local menu={}
	InsertTargetMenu(menu,dwID)
	for k,v in pairs (menu) do
		if v.szOption==g_tStrings.STR_MAKE_FRIEND then
			t[1]=v
			return t
		end
	end
	return nil
end

function LR.GetEquipmentMenu(dwID)
	local t={}
	local menu={}
	InsertTargetMenu(menu,dwID)
	for k,v in pairs (menu) do
		if v.szOption==g_tStrings.STR_LOOKUP then
			t[1]=v
			return t
		end
	end
end

function LR.GetMoreInfoMenu(dwID)
	local t={}
	local menu={}
	InsertTargetMenu(menu,dwID)
	for k,v in pairs (menu) do
		if v.szOption==g_tStrings.LOOKUP_INFO then
			t[1]=v
			return t
		end
	end
end

function LR.GetRevengeMenu(dwID)
	local t={}
	local menu={}
	InsertTargetMenu(menu,dwID)
	for k,v in pairs (menu) do
		if v.szOption==g_tStrings.STR_ADD_EMENY then
			t[1]=v
			return t
		end
	end
end

function LR.GetWantedMenu(dwID)
	local t={}
	local menu={}
	InsertTargetMenu(menu,dwID)
	for k,v in pairs (menu) do
		if v.szOption==g_tStrings.STR_ADD_SHANG then
			t[1]=v
			return t
		end
	end
end

function LR.GetInviteJJCTeamMenu(dwID)
	local t={}
	local menu={}
	InsertTargetMenu(menu,dwID)
	for k,v in pairs (menu) do
		if v.szOption==g_tStrings.STR_ARENA_INVITE_TARGET then
			t[1]=v
			return t
		end
	end
end

function LR.GetInviteToneMenu(dwID)
	local t={}
	local menu={}
	InsertTargetMenu(menu,dwID)
	for k,v in pairs (menu) do
		if v.szOption==g_tStrings.INVITE_ADD_GUILD then
			t[1]=v
			return t
		end
	end
end

function LR.GetFollowMenu(dwID)
	local t={}
	local menu={}
	InsertTargetMenu(menu,dwID)
	for k,v in pairs (menu) do
		if v.szOption==g_tStrings.STR_FOLLOW then
			t[1]=v
			return t
		end
	end
	return nil
end

---------------------------------------------
----DelayCall
---------------------------------------------
function LR.OnFrameCreate()

end

function LR.OnFrameBreathe()
	local nFrame = GetLogicFrameCount()
	for k, v in pairs(LR.tBreatheCall) do
		if v then
			if nFrame >= v.nNextFrame then
				v.nNextFrame = nFrame + v.nStep
				local res, err = pcall(v.fnAction)
				if not res then

				end
			end
		end
	end
end

function LR.OnFrameRender()
	local nTime = GetTime()
	for k, v in pairs (LR.tDelayCall) do
		if v then
			if v.nTime <= nTime then
				local res, err = pcall(v.fnAction)
				if not res then

				end
				if type(k) == "number" then
					tremove(LR.tDelayCall, k)
				else
					LR.tDelayCall[k] = nil
				end
			end
		end
	end
end

function LR.DelayCall(nDelayTime, fnAction, szKey)
	----nDelayTime �ӳ�ʱ�� ��λ������
	local _time = GetTime()
	local nTime = nDelayTime + _time
	if szKey then
		local szKey = tostring(szKey)
		LR.tDelayCall[szKey] = {nTime = nTime, fnAction = fnAction, szKey = szKey,}
	else
		tinsert(LR.tDelayCall, {nTime = nTime, fnAction = fnAction})
	end
end

function LR.UnDelayCall(szKey)
	LR.tDelayCall[szKey] = {nTime = GetTime() + 1, fnAction = function()  end, szKey = szKey,}
end


function LR.BreatheCall(szKey, fnAction, nTime)
	local key = tostring(szKey)
	if fnAction and type(fnAction) == "function" then
		local nFrame = 1
		if nTime and nTime > 0 then
			nFrame = mceil(nTime / 62.5)
		end
		LR.tBreatheCall[key] = {fnAction = fnAction, nNextFrame = GetLogicFrameCount() + 1, nStep = nFrame }
	else
		LR.tBreatheCall[key] = {fnAction = function() LR.tBreatheCall[key] = nil end, nNextFrame = GetLogicFrameCount() + 1, nStep = 1 }
	end
end

function LR.UnBreatheCall(szKey)
	LR.BreatheCall(szKey)
end
Wnd.OpenWindow("Interface\\LR_Plugin\\LR_1Base\\UI\\LR_1Base_None.ini", "LR")

------------------------------------------------------------------------------------
-------
------------------------------------------------------------------------------------
function LR.GetFullSizeNumber(szNum) -- ������ֵΪ�������,����Ϊ��������
	szNum = tostring(szNum)
	local tFullSizeNumber = {"��","��","��","��","��","��","��","��","��","��"}
	for i = 0, 9, 1 do
		while sfind(szNum, tostring(i)) do
			szNum = szNum:gsub(tostring(i), tFullSizeNumber[i+1])
		end
	end
	if #szNum == 2 then -- ���ֵΪȫ������,����Ϊ�������ȵĶ���
		szNum = sformat("��%s", szNum)
	end
	return szNum
end
------------------------------------------------------------------------------------
-------
------------------------------------------------------------------------------------
function LR.GB_Long()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local bufflist=LR.GetBuffList(me)
	for k,v in pairs(bufflist) do
		local dwID=v.dwID
		if dwID == 9920 then
			me.CancelBuff(v.nIndex)
			return
		end
	end
end

function LR.CJ_TigerRun()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local bufflist=LR.GetBuffList(me)
	for k,v in pairs(bufflist) do
		local dwID=v.dwID
		if dwID == 1686 then
			me.CancelBuff(v.nIndex)
			return
		end
	end
end

------------------------------------------------------------------------------------
LR.BlackFBList={}
LR.BlackACK=0
function LR.Black_LOADING_END()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local scene=me.GetScene()
	local dwMapID=scene.dwMapID
	local nCopyIndex=scene.nCopyIndex
	local nTime=GetCurrentTime()
	local szName=me.szName

	if scene.nType ~= MAP_TYPE.DUNGEON then
		return
	end

	LR.BlackFBList[dwMapID] = LR.BlackFBList[dwMapID] or {}
	LR.BlackFBList[dwMapID][nCopyIndex] = LR.BlackFBList[dwMapID][nCopyIndex] or {}
	if next(LR.BlackFBList[dwMapID][nCopyIndex]) == nil then
		local data={szName=szName,nTime=nTime}
		LR.BlackFBList[dwMapID][nCopyIndex]=clone(data)
		if me.IsInParty() or me.IsInRaid() then
			local msg={dwMapID=dwMapID,nCopyIndex=nCopyIndex,szName=szName,nTime=nTime}
			LR.BgTalk(PLAYER_TALK_CHANNEL.RAID,"LR_BlackFB","Send",msg)
		end
	else
		if LR.BlackFBList[dwMapID][nCopyIndex].nTime > nTime then
			local data={szName=szName,nTime=nTime}
			LR.BlackFBList[dwMapID][nCopyIndex]=clone(data)
			if me.IsInParty() then
				local msg={dwMapID=dwMapID,nCopyIndex=nCopyIndex,szName=szName,nTime=nTime}
				LR.BgTalk(PLAYER_TALK_CHANNEL.RAID,"LR_BlackFB","Send",msg)
			end
		end
	end
end

function LR.Black_FIRST_LOADING_END()
	local me=GetClientPlayer()
	if not me then
		return
	end
	if me.IsInParty() then
		if LR.BlackACK==0 then
			LR.BgTalk(PLAYER_TALK_CHANNEL.RAID,"LR_BlackFB","Get",msg)
			LR.DelayCall(5000, function() LR.Black_FIRST_LOADING_END() end)
		end
	end
end

function LR.Black_ON_BG_CHANNEL_MSG()
	local szKey=arg0
	local nChannel=arg1
	local dwTalkerID=arg2
	local szTalkerName=arg3
	local data=arg4
	if szKey~="LR_BlackFB" then
		return
	end

	local me = GetClientPlayer()
	if not me then
		return
	end

	if data[1]=="Send" then
		local dwMapID=data[2].dwMapID
		local nCopyIndex=data[2].nCopyIndex
		local szName=data[2].szName
		local nTime=data[2].nTime

		if LR.BlackFBList[dwMapID] and LR.BlackFBList[dwMapID][nCopyIndex] then
			if LR.BlackFBList[dwMapID][nCopyIndex].nTime>nTime then
				local data={szName=szName,nTime=nTime}
				LR.BlackFBList[dwMapID][nCopyIndex]=clone(data)
			elseif LR.BlackFBList[dwMapID][nCopyIndex].nTime<nTime then
				local szName=	LR.BlackFBList[dwMapID][nCopyIndex].szName
				local nTime=	LR.BlackFBList[dwMapID][nCopyIndex].nTime
				local msg={dwMapID=dwMapID,nCopyIndex=nCopyIndex,szName=szName,nTime=nTime}
				LR.BgTalk(PLAYER_TALK_CHANNEL.RAID,"LR_BlackFB","Send",msg)
			end
		else
			LR.BlackFBList[dwMapID]=LR.BlackFBList[dwMapID] or {}
			LR.BlackFBList[dwMapID][nCopyIndex]=LR.BlackFBList[dwMapID][nCopyIndex] or {}
			local data={szName=szName,nTime=nTime}
			LR.BlackFBList[dwMapID][nCopyIndex]=clone(data)
		end
	elseif data[1]=="Get" then
		if me.IsPartyLeader() then
			local msg={dwID=dwTalkerID}
			LR.BgTalk(PLAYER_TALK_CHANNEL.RAID,"LR_BlackFB","ACK",msg)
			for dwMapID , v in pairs(LR.BlackFBList) do
				for nCopyIndex , v2 in pairs(v) do
					local msg={dwMapID=dwMapID,nCopyIndex=nCopyIndex,szName=v2.szName,nTime=v2.nTime}
					LR.BgTalk(PLAYER_TALK_CHANNEL.RAID,"LR_BlackFB","Send",msg)
				end
			end
		end
	elseif data[1]=="ACK" then
		if data[2].dwID==me.dwID then
			LR.BlackACK=1
		end
	end
end

function LR.Black_PARTY_ADD_MEMBER()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if me.IsPartyLeader() then
		LR.DelayCall(1000, function()
			for dwMapID , v in pairs(LR.BlackFBList) do
				for nCopyIndex , v2 in pairs(v) do
					local msg={dwMapID=dwMapID,nCopyIndex=nCopyIndex,szName=v2.szName,nTime=v2.nTime}
					LR.BgTalk(PLAYER_TALK_CHANNEL.RAID,"LR_BlackFB","Send",msg)
				end
			end
		end)
	end
end

function LR.Black_BreatheCheck()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if GetLogicFrameCount() % 12 ~= 0 then
		return
	end
	if me.IsPartyLeader() then
		local teamClient=GetClientTeam()
		local memberList=teamClient.GetTeamMemberList()
		for k,dwMemberID in pairs (memberList) do
			local memberInfo=teamClient.GetMemberInfo(dwMemberID)
			if memberInfo then
				local dwMapID=memberInfo.dwMapID
				local nCopyIndex=memberInfo.nMapCopyIndex
				local szName=memberInfo.szName
				local tMapInfo={GetMapParams(dwMapID)}
				local nType=tMapInfo[2]
				local nTime=GetCurrentTime()
				if nType == MAP_TYPE.DUNGEON then
					LR.BlackFBList[dwMapID] = LR.BlackFBList[dwMapID] or {}
					LR.BlackFBList[dwMapID][nCopyIndex] = LR.BlackFBList[dwMapID][nCopyIndex] or {}
					if next(LR.BlackFBList[dwMapID][nCopyIndex]) == nil then
						local data={szName=szName,nTime=nTime}
						LR.BlackFBList[dwMapID][nCopyIndex]=clone(data)
						if me.IsPartyLeader() then
							local msg={dwMapID=dwMapID,nCopyIndex=nCopyIndex,szName=szName,nTime=nTime}
							LR.BgTalk(PLAYER_TALK_CHANNEL.RAID,"LR_BlackFB","Send",msg)
						end
					else
						if LR.BlackFBList[dwMapID][nCopyIndex].nTime > nTime then
							local data={szName=szName,nTime=nTime}
							LR.BlackFBList[dwMapID][nCopyIndex]=clone(data)
							if me.IsPartyLeader() then
								local msg={dwMapID=dwMapID,nCopyIndex=nCopyIndex,szName=szName,nTime=nTime}
								LR.BgTalk(PLAYER_TALK_CHANNEL.RAID,"LR_BlackFB","Send",msg)
							end
						end
					end
				end
			end
		end
	end
end

function LR.LOGIN_GAME()
	LR.RegisterHotKey()
end

function LR.SYS_MSG()
	if arg0 == "UI_OME_CHAT_RESPOND" then
		if arg1 == PLAYER_TALK_ERROR.BAN then
			TALK_BAN = true
		end
	end
end

LR.BreatheCall("Black_BreatheCheck",function() LR.Black_BreatheCheck() end)
LR.RegisterEvent("LOADING_END",function() LR.Black_LOADING_END() end)
LR.RegisterEvent("FIRST_LOADING_END",function()
	LR.Black_FIRST_LOADING_END()
	LR.LoadMenPaiColor()
end)
LR.RegisterEvent("ON_BG_CHANNEL_MSG",function() LR.Black_ON_BG_CHANNEL_MSG() end)
LR.RegisterEvent("PARTY_ADD_MEMBER",function() LR.Black_PARTY_ADD_MEMBER() end)
LR.RegisterEvent("LOGIN_GAME", function() LR.LOGIN_GAME() end)
LR.RegisterEvent("SYS_MSG", function() LR.SYS_MSG() end)
