local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_CopyBook"
local LanguagePath = "Interface\\LR_Plugin\\LR_CopyBook"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_CopyBook"
local _L = LR.LoadLangPack(LanguagePath)
local VERSION = "20180408"
-------------------------------------------------------------
local DefaultData = {
	szSuiteBookName = _L["Please Enter Suitbook Name"],
	tCopyList = {},
	nCopySuiteNum = 1,
	bKilledByFrame = false,
}
LR_CopyBook = {}
LR_CopyBook.UsrData = clone(DefaultData)
RegisterCustomData("LR_CopyBook.UsrData", VERSION)

-------------------------------------------------------------
local _C = {}
local MAX_STACK_NUM = {}
local SHOP_CACHE = {}
local SHOP_SELLING_ITEM_CACHE = {}
local MISSION_CACHE = {}	--存放任务获得的监本数量
local RECIPE_PREPARE_PROGRESS_CACHE = {}
-------------------------------------------------------------
----Hook
-------------------------------------------------------------
function _C.HookReadPanel()
	local frame = Station.Lookup("Normal/CraftReadManagePanel")
	if frame then --背包界面添加一个按钮
		local Btn_CopyBook = frame:Lookup("Btn_CopyBook")
		if not Btn_CopyBook then
			if true then
				local Btn_CopyBook = LR.AppendUI("Button", frame, "Btn_CopyBook", {w = 90, h = 22, x = 60, y = 477})
				Btn_CopyBook:SetText(_L["LR Copy Book"])
				Btn_CopyBook.OnClick = function()
					LR_TOOLS:OpenPanel(_L["LR Printing Machine"])
				end
				Btn_CopyBook.OnEnter = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local szTip = {}
					szTip[#szTip+1] = GetFormatText(sformat("%s\n", _L["LR Copy Book"]), 163)
					szTip[#szTip+1] = GetFormatText(_L["Click to Open LR Printing Machine Interface"], 162)
					OutputTip(tconcat(szTip), 400, {x, y, w, h})
				end
				Btn_CopyBook.OnLeave = function()
					HideTip()
				end
			end
		end
	end
end

function _C.HookBookExchangePanel()
	local frame = Station.Lookup("Normal/BookExchangePanel")
	if frame then --背包界面添加一个按钮
		local Btn_CopyBook = frame:Lookup("Btn_CopyBook")
		if not Btn_CopyBook then
			if true then
				local Btn_CopyBook = LR.AppendUI("Button", frame, "Btn_CopyBook", {w = 90, h = 22, x = 60, y = 477})
				Btn_CopyBook:SetText(_L["LR Copy Book"])
				Btn_CopyBook.OnClick = function()
					LR_TOOLS:OpenPanel(_L["LR Printing Machine"])
				end
				Btn_CopyBook.OnEnter = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local szTip = {}
					szTip[#szTip+1] = GetFormatText(sformat("%s\n", _L["LR Copy Book"]), 163)
					szTip[#szTip+1] = GetFormatText(_L["Click to Open LR Printing Machine Interface"], 162)
					OutputTip(tconcat(szTip), 400, {x, y, w, h})
				end
				Btn_CopyBook.OnLeave = function()
					HideTip()
				end
			end
		end
	end
end

function _C.ON_FRAME_CREATE()
	local frame=arg0
	local szName=frame:GetName()
	if szName == "CraftReadManagePanel" then
		---------阅读界面增加抄书按钮
		LR.DelayCall(500, function() _C.HookReadPanel() end)
	elseif szName == "BookExchangePanel" then
		---------书籍兑换界面增加抄书按钮
		LR.DelayCall(500, function() _C.HookBookExchangePanel() end)
	end
end
LR.RegisterEvent("ON_FRAME_CREATE",function() _C.ON_FRAME_CREATE() end)

----------------
function LR_CopyBook.OnFrameCreate()
	this:RegisterEvent("SYS_MSG")
	this:RegisterEvent("OT_ACTION_PROGRESS_BREAK")
	this:RegisterEvent("DO_RECIPE_PREPARE_PROGRESS")

end

function LR_CopyBook.OnEvent(event)
	if event == "SYS_MSG" then
		_C.SYS_MSG()
	elseif event == "OT_ACTION_PROGRESS_BREAK" then
		_C.OT_ACTION_PROGRESS_BREAK()
	elseif event == "DO_RECIPE_PREPARE_PROGRESS" then
		_C.DO_RECIPE_PREPARE_PROGRESS()
	end
end

function LR_CopyBook.OnFrameBreathe()

end
-------------------------------------------------------------
----dwBookID:dwSuiteBookID,dwSegmentID:dwSegmentID
-------------------------------------------------------------
function _C.GetSuiteBookIDByName(szName)
	--返回套书ID以及套书有几本
	local szName = szName or "--"
	local RowCount = g_tTable.BookSegment:GetRowCount()
	local i = 2
	while i <= RowCount do
		local tLine = g_tTable.BookSegment:GetRow(i)
		if tLine then
			if tLine.szBookName == szName then
				return tLine.dwBookID, tLine.dwBookNumber
			else
				i = i + tLine.dwBookNumber
			end
		else
			i = i + 1
		end
	end
	return 0, 0
end

function _C.GetSuiteBookNameByID(dwBookID)
	local dwBookID, dwSegmentID = dwBookID or 1, 1
	local tLine = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tLine then
		return tLine.szBookName
	end
	return ""
end

function _C.GetSegmentBookNameByID(dwBookID, dwSegmentID)
	local tLine = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tLine then
		return tLine.szSegmentName
	end
	return ""
end

function _C.GetBoosBySuiteBookName(szName)
	local dwBookID, dwSuiteBookNum = _C.GetSuiteBookIDByName(szName)
	if dwBookID == 0 then
		return {}
	end
	local tBooks = {}
	for dwSegmentID = 1, dwSuiteBookNum do
		local tLine = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
		if tLine then
			tBooks[#tBooks + 1] = {dwBookID = dwBookID, dwSegmentID = dwSegmentID, szSegmentName = tLine.szSegmentName, szBookName = tLine.szBookName}
		end
	end
	return tBooks
end

function _C.CheckSegmentBookCanBCopy(dwBookID, dwSegmentID)
	local me = GetClientPlayer()
	return me.IsBookMemorized(dwBookID, dwSegmentID)
end

function _C.InitCopyList()
	local szName = LR_CopyBook.UsrData.szSuiteBookName
	local tBooks = _C.GetBoosBySuiteBookName(szName)
	if next(tBooks) == nil then
		LR_CopyBook.UsrData.tCopyList = {}
		return
	end
	local tCopyList = {}
	for k, v in pairs(tBooks) do
		local bCopy = _C.CheckSegmentBookCanBCopy(v.dwBookID, v.dwSegmentID)
		tCopyList[#tCopyList + 1] = {dwBookID = v.dwBookID, dwSegmentID = v.dwSegmentID, bCopy = bCopy}
	end
	LR_CopyBook.UsrData.tCopyList = clone(tCopyList)
end

function _C.InitCopyListMenu(tMenu)
	local tCopyList = clone(LR_CopyBook.UsrData.tCopyList)
	for k, v in pairs(tCopyList) do
		local szName = _C.GetSegmentBookNameByID(v.dwBookID, v.dwSegmentID)
		if not _C.CheckSegmentBookCanBCopy(v.dwBookID, v.dwSegmentID) then
			szName = sformat("%s%s", szName, _L["(Never Read)"])
		end
		local dwIndex = LR.Table_GetBookItemIndex(v.dwBookID, v.dwSegmentID)
		local itemInfo = GetItemInfo(5, dwIndex)
		szName = sformat("[%d] %s", LR.GetItemNumInBag(5, dwIndex, v.dwBookID, v.dwSegmentID), szName)
		if itemInfo and itemInfo.nBindType == 3 then
			szName = sformat("%s%s", szName, _L["(Bind after printing)"])
		end
		tMenu[#tMenu + 1] = {szOption = szName, bCheck = true, bMCheck = false, bChecked = function() return v.bCopy and _C.CheckSegmentBookCanBCopy(v.dwBookID, v.dwSegmentID) end,
			fnAction = function()
				LR_CopyBook.UsrData.tCopyList[k].bCopy = not LR_CopyBook.UsrData.tCopyList[k].bCopy
				LR_CopyBook_MiniPanel:ChangeCheck(v.dwBookID, v.dwSegmentID)

				if LR_TOOLS:Fetch("LR_CopyBook_UI_Handle003") then
					LR_CopyBook.DrawRecipeBoxes(LR_TOOLS:Fetch("LR_CopyBook_UI_Handle003"))
				end
			end,
			fnDisable = function()
				return not _C.CheckSegmentBookCanBCopy(v.dwBookID, v.dwSegmentID)
			end
		}
	end
	return tMenu
end

function _C.GetSearchList(value)
	local szName = value or "--"
	local tList = {}
	local RowCount = g_tTable.BookSegment:GetRowCount()
	local i = 2
	while i <= RowCount do
		local tLine = g_tTable.BookSegment:GetRow(i)
		if tLine then
			if sfind(tLine.szBookName, szName) then
				tList[#tList + 1] = {szOption = tLine.szBookName,
					fnAction = function()
						LR_CopyBook.UsrData.szSuiteBookName = tLine.szBookName
						_C.InitCopyList()

						if LR_TOOLS:Fetch("LR_CopyBook_UI_edit1") then
							LR_TOOLS:Fetch("LR_CopyBook_UI_edit1"):SetText(tLine.szBookName)
						end

						if LR_TOOLS:Fetch("LR_CopyBook_UI_Handle003") then
							LR_CopyBook.DrawRecipeBoxes(LR_TOOLS:Fetch("LR_CopyBook_UI_Handle003"))
						end

						local frame = LR_CopyBook_MiniPanel:Fetch("LR_CopyBook_MiniPanel")
						if frame then
							LR_CopyBook_MiniPanel:SetBookID()
							LR_CopyBook_MiniPanel:LoadSuitBooks()
							LR_CopyBook_MiniPanel:DrawNeed()
						end
					end,
				}
			end
			i = i + tLine.dwBookNumber
		else
			i = i + 1
		end
	end
	return tList
end

function _C.GetOneSuiteRecipeNum(tCopyList, bForceCopy)
	--返回需要抄写的书，一套所需要的材料数量，以及每本书需要的材料数量
	local tCopyList = tCopyList or clone(LR_CopyBook.UsrData.tCopyList)
	local tSuitRecipeNum, tSegmentRecipeNum, nSuitTrewNeed, nSegmentTrewNeed = {}, {}, 0, {}
	for k, v in pairs(tCopyList) do
		if v.bCopy and _C.CheckSegmentBookCanBCopy(v.dwBookID, v.dwSegmentID) or bForceCopy then
			local recipe  = GetRecipe(12, v.dwBookID, v.dwSegmentID)
			--
			local szBookKey = sformat("%d_%d", v.dwBookID, v.dwSegmentID)		--书Key
			for nIndex = 1, 4, 1 do
				local nType = recipe[sformat("dwRequireItemType%d", nIndex)]
				local dwIndex = recipe[sformat("dwRequireItemIndex%d", nIndex)]
				local nNeed  = recipe[sformat("dwRequireItemCount%d", nIndex)]
				if nNeed > 0 then
					local szKey = sformat("%d_%d", nType, dwIndex)		--材料Key
					tSuitRecipeNum[szKey] = tSuitRecipeNum[szKey] or {dwTabType = nType, dwIndex = dwIndex, num = 0}
					tSuitRecipeNum[szKey].num = tSuitRecipeNum[szKey].num + nNeed

					tSegmentRecipeNum[szBookKey] = tSegmentRecipeNum[szBookKey] or {}
					tSegmentRecipeNum[szBookKey][szKey] = {dwTabType = nType, dwIndex = dwIndex, num = nNeed}
				end
			end
			--体力
			nSuitTrewNeed = nSuitTrewNeed + recipe.nVigor
			nSegmentTrewNeed[szBookKey] = recipe.nVigor
		end
	end
	return tSuitRecipeNum, tSegmentRecipeNum, nSuitTrewNeed, nSegmentTrewNeed
end

function _C.GetCanCopySuiteNum()
	local nSuiteBoxNeed = 0
	local tCopyList = clone(LR_CopyBook.UsrData.tCopyList)
	for k, v in pairs(tCopyList) do
		if v.bCopy and _C.CheckSegmentBookCanBCopy(v.dwBookID, v.dwSegmentID) then
			nSuiteBoxNeed = nSuiteBoxNeed + 1
		end
	end

	--nEmptyBagBoxNum:实际空出来的格子(通过系统获取)
	--nLogiEmptyBagBoxNum:随着边抄边交，实际空出的格子(如果原来的格子中有书籍n本，抄m次，若n - m >= 0, 说明书够，不用抄，不增加空出来的格子数量;否则逻辑上空出来的格子-1)
	--nLogiEmptyBagBoxNum:实际空出来的格子要能放得下材料
	--nRecipeBoxNeed:材料需要的格子数量
	local nEmptyBagBoxNum, nLogiEmptyBagBoxNum, nRecipeBoxNeed, nThewNeed = LR.GetBagEmptyBoxNum(), 0, 0, 0
	local nCopySuiteNum = 0
	local tBooksNumCache = {}
	for k, v in pairs(tCopyList) do
		local dwIndex = LR.Table_GetBookItemIndex(v.dwBookID, v.dwSegmentID)
		tBooksNumCache[sformat("%d_%d", v.dwBookID, v.dwSegmentID)] = LR.GetItemNumInBag(5, dwIndex, v.dwBookID, v.dwSegmentID)
	end

	repeat
		nCopySuiteNum = nCopySuiteNum + 1
		nLogiEmptyBagBoxNum = nEmptyBagBoxNum
		nRecipeBoxNeed = 0
		nThewNeed = 0
		for k, v in pairs(tCopyList) do
			if tBooksNumCache[sformat("%d_%d", v.dwBookID, v.dwSegmentID)] < nCopySuiteNum then
				nLogiEmptyBagBoxNum = nLogiEmptyBagBoxNum - 1 + tBooksNumCache[sformat("%d_%d", v.dwBookID, v.dwSegmentID)]
			end
		end

		local tAllRecipeNum, nTrewNeed = _C.GetAllRecipeNum(nCopySuiteNum)
		for szKey, v in pairs(tAllRecipeNum) do
			local nMaxStackNum = MAX_STACK_NUM[szKey] or 20
			nRecipeBoxNeed = nRecipeBoxNeed + mceil(v.num / nMaxStackNum)
		end
		local nTrew = GetClientPlayer().nVigor + GetClientPlayer().nCurrentStamina
	until nLogiEmptyBagBoxNum < nRecipeBoxNeed or nLogiEmptyBagBoxNum < 0 or nCopySuiteNum > 100 or nTrewNeed > nTrew

	return nCopySuiteNum - 1
end

function _C.GetAllRecipeNum(nCopySuiteNum)
	local nCopySuiteNum = nCopySuiteNum or LR_CopyBook.UsrData.nCopySuiteNum
	local tSuitRecipeNum, tSegmentRecipeNum, nSuitTrewNeed, nSegmentTrewNeed = _C.GetOneSuiteRecipeNum()

	--Output("sdfsff", tSuitRecipeNum, tSegmentRecipeNum)
	--先计算所有的材料需要的总量 - 包里已有数量
	local tAllRecipeNum = clone(tSuitRecipeNum)
	for szKey, v in pairs(tAllRecipeNum) do
		v.num = mmax(v.num * nCopySuiteNum - LR.GetItemNumInBag(v.dwTabType, v.dwIndex), 0)
	end
	--减去已有书籍所需要抄录的所需要的材料的数量
	local tCopyList = clone(LR_CopyBook.UsrData.tCopyList)
	for k, v in pairs(tCopyList) do
		if v.bCopy and _C.CheckSegmentBookCanBCopy(v.dwBookID, v.dwSegmentID) then
			local szBookKey = sformat("%d_%d", v.dwBookID, v.dwSegmentID)
			for k2, v2 in pairs(tSegmentRecipeNum[szBookKey]) do
				local szKey2 = sformat("%d_%d", v2.dwTabType, v2.dwIndex)
				local dwIndex = LR.Table_GetBookItemIndex(v.dwBookID, v.dwSegmentID)
				tAllRecipeNum[szKey2].num = mmax(tAllRecipeNum[szKey2].num - v2.num * mmin(nCopySuiteNum, LR.GetItemNumInBag(5, dwIndex, v.dwBookID, v.dwSegmentID, not LR.IsPhoneLock())), 0)
			end
		end
	end

	---计算体力
	local nTrewNeed = 0
	nTrewNeed = nSuitTrewNeed * nCopySuiteNum
	for k, v in pairs(tCopyList) do
		if v.bCopy and _C.CheckSegmentBookCanBCopy(v.dwBookID, v.dwSegmentID) then
			local szBookKey = sformat("%d_%d", v.dwBookID, v.dwSegmentID)
			--减去已有书籍需要的体力
			local dwIndex = LR.Table_GetBookItemIndex(v.dwBookID, v.dwSegmentID)
			nTrewNeed = nTrewNeed - nSegmentTrewNeed[szBookKey] * mmin(nCopySuiteNum, LR.GetItemNumInBag(5, dwIndex, v.dwBookID, v.dwSegmentID))
		end
	end

	return tAllRecipeNum, nTrewNeed
end

function _C.GetAllRecipeAgainstHasInBag()
	local nCopySuiteNum = nCopySuiteNum or LR_CopyBook.UsrData.nCopySuiteNum
	local tSuitRecipeNum, tSegmentRecipeNum = _C.GetOneSuiteRecipeNum()
	---
	local tAllRecipeNum = {}
	for szKey, v in pairs(tSuitRecipeNum) do
		tAllRecipeNum[szKey] = {need = 0, have = 0,}
		tAllRecipeNum[szKey].have = LR.GetItemNumInBag(v.dwTabType, v.dwIndex)
	end
	return tAllRecipeNum
end

function _C.CopyBook()
	local me = GetClientPlayer()
	if not (me and me.GetOTActionState() == 0 and me.nMoveState == MOVE_STATE.ON_STAND and (not me.bFightState)) then
		return
	end

	local tCopyList = clone(LR_CopyBook.UsrData.tCopyList)

	local tNum = {}
	for k, v in pairs(tCopyList) do
		if v.bCopy and _C.CheckSegmentBookCanBCopy(v.dwBookID, v.dwSegmentID) then
			local dwIndex = LR.Table_GetBookItemIndex(v.dwBookID, v.dwSegmentID)
			tinsert(tNum, LR.GetItemNumInBag(5, dwIndex, v.dwBookID, v.dwSegmentID))
		end
	end

	if #tNum == 0 then
		_C.StopCopy()
		return
	end

	local min_num = mmin(unpack(tNum))
	for k, v in pairs(tCopyList) do
		if v.bCopy and _C.CheckSegmentBookCanBCopy(v.dwBookID, v.dwSegmentID) then
			local dwIndex = LR.Table_GetBookItemIndex(v.dwBookID, v.dwSegmentID)
			if LR.GetItemNumInBag(5, dwIndex, v.dwBookID, v.dwSegmentID) == min_num then
				GetClientPlayer().CastProfessionSkill(12, v.dwBookID, v.dwSegmentID)
				return
			end
		end
	end
end

---------------------------
function _C.LoadCfg()
	local path = sformat("%s//Script//SuitBook", AddonPath)
	MISSION_CACHE = LoadLUAData(path) or {}

	local path2 = sformat("%s//Script//MaterialPrice", AddonPath)
	local data = LoadLUAData(path2)

	MAX_STACK_NUM = {}
	for szKey, v in pairs(data) do
		MAX_STACK_NUM[szKey] = v.nMaxStackNum
	end
end
---------------------------
function _C.StartCopy()
	local frame = Station.Lookup("Lowest/LR_CopyBook")
	if not frame then
		Wnd.OpenWindow("interface\\LR_Plugin\\LR_CopyBook\\UI\\EmptyUI.ini","LR_CopyBook")
	end
	_C.CopyBook()
end

function _C.StopCopy()
	local frame = Station.Lookup("Lowest/LR_CopyBook")
	if frame then
		Wnd.CloseWindow(frame)
	end
	GetClientPlayer().StopCurrentAction()
end

function _C.DrawRecipeBoxes(parent)
	local tAllRecipeNum, nThewNeed = _C.GetAllRecipeNum()
	parent:Clear()
	parent:SetHandleStyle(3)
	local w1, h1 = parent:GetSize()
	for szKey, v in pairs(tAllRecipeNum) do
		if v.num > 0 then
			local hHandle = LR.AppendUI("Handle", parent, sformat("Handle_%s", szKey), {w = 50, h = 50})
			local Box = LR.AppendUI("Box", hHandle, sformat("Handle_%s", szKey), {x = 0, y = 0, w = 45, h = 45})
			local itemInfo = GetItemInfo(v.dwTabType, v.dwIndex)
			Box:SetObject(1):SetObjectIcon(Table_GetItemIconID(itemInfo.nUiId))
			Box:SetOverText(1, v.num)
			Box:SetOverTextFontScheme(1, 15)
			Box:SetOverTextPosition(1, ITEM_POSITION.RIGHT_BOTTOM)
			Box.OnEnter = function()
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				OutputItemTip(UI_OBJECT_ITEM_INFO, 1, v.dwTabType, v.dwIndex, {x, y, w, h,})
			end
			Box.OnLeave = function()
				HideTip()
			end
		end
	end

	local Handle_Thew = LR.AppendUI("Handle", parent, "Handle_Thew", {w = w1, h = 30})
	local tCopyList = clone(LR_CopyBook.UsrData.tCopyList)
	local dwBookID = tCopyList[1] and tCopyList[1].dwBookID or 0
	local n = (MISSION_CACHE[sformat("BookID#%d", dwBookID)] or 0) * (LR_CopyBook.UsrData.nCopySuiteNum or 0)
	local flag = false
	if next(tCopyList) ~= nil then
		for k, v in pairs(tCopyList) do
			if v.bCopy and _C.CheckSegmentBookCanBCopy(v.dwBookID, v.dwSegmentID) then
				flag = true
			end
		end
	end
	if not flag then
		n = 0
	end
	local tText = LR.AppendUI("Text", Handle_Thew, "Text_Thew", {x = 0, y = 0, text = sformat(_L["Need thew: %d, get examprint: %d"], nThewNeed, n)})
	parent:FormatAllItemPos()
	local w, h = parent:GetAllItemSize()
	parent:SetSize(w1, h)
end

---------------------------
function _C.GetAllSellingItem(nShopID, nCount)
	SHOP_SELLING_ITEM_CACHE = {}
	for i = 0, nCount - 1, 1 do
		local dwItemID = GetShopItemID(nShopID, i)
		local item = GetItem(dwItemID)
		if item then
			local nMaxStackNum = item.nMaxStackNum
			local szKey = sformat("%d_%d", item.dwTabType, item.dwIndex)
			if item.nGenre == ITEM_GENRE.BOOK then
				local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
				szKey = sformat("%d_%d", nBookID, nSegID)
				nMaxStackNum = 1
			end
			SHOP_SELLING_ITEM_CACHE[szKey] = {nShopID = nShopID, nID = i, dwID = dwItemID}
			MAX_STACK_NUM[szKey] = nMaxStackNum
		end
	end
end

function _C.SHOP_OPENSHOP()
	local Shop = {
		nShopID = arg0,
		nShopType = arg1,
		nValidPageCount = arg2,
		bCanRepair = arg3,
		nNpcID = arg4,
	}
	SHOP_CACHE = clone(Shop)
	_C.GetAllSellingItem(Shop.nShopID, Shop.nValidPageCount)
end

function _C.Gets(nCopySuiteNum)
	local nCopySuiteNum = nCopySuiteNum or LR_CopyBook.UsrData.nCopySuiteNum
	--
	if next(SHOP_CACHE) == nil then
		return
	end
	local frame = Station.Lookup("Normal/ShopPanel")
	if not frame then
		return
	end

	local t = _C.GetAllRecipeNum(nCopySuiteNum)
	for szKey, v in pairs(t) do
		--Output(SHOP_CACHE.nNpcID, SHOP_CACHE.nShopID, SHOP_SELLING_ITEM_CACHE[szKey].nID, v.num)
		local nMaxStackNum = MAX_STACK_NUM[szKey] or 20
		local n, num = mfloor(v.num / nMaxStackNum), v.num % nMaxStackNum
		for i = 1, n, 1 do
			BuyItem(SHOP_CACHE.nNpcID, SHOP_CACHE.nShopID, SHOP_SELLING_ITEM_CACHE[szKey].nID, nMaxStackNum)
		end
		if num > 0 then
			BuyItem(SHOP_CACHE.nNpcID, SHOP_CACHE.nShopID, SHOP_SELLING_ITEM_CACHE[szKey].nID, num)
		end
	end
end

function _C.UpdateSuitNum()
	local dwBookID, dwSegmentID = RECIPE_PREPARE_PROGRESS_CACHE.dwBookID, RECIPE_PREPARE_PROGRESS_CACHE.dwSegmentID
	--
	local tCopyList = clone(LR_CopyBook.UsrData.tCopyList)
	local tNum = {}
	for k, v in pairs(tCopyList) do
		if v.bCopy and _C.CheckSegmentBookCanBCopy(v.dwBookID, v.dwSegmentID) then
			local dwIndex = LR.Table_GetBookItemIndex(v.dwBookID, v.dwSegmentID)
			tinsert(tNum, LR.GetItemNumInBag(5, dwIndex, v.dwBookID, v.dwSegmentID))
		end
	end
	if #tNum == 0 then
		return
	end
	local min_num = mmin(unpack(tNum))
	local dwIndex = LR.Table_GetBookItemIndex(dwBookID, dwSegmentID)
	if min_num == LR.GetItemNumInBag(5, dwIndex, dwBookID, dwSegmentID) then
		LR_CopyBook.UsrData.nCopySuiteNum = LR_CopyBook.UsrData.nCopySuiteNum - 1
		local nCopySuiteNum = LR_CopyBook.UsrData.nCopySuiteNum
		local edit = LR_TOOLS:Fetch("edit_CopyBookNum")
		if edit then
			edit:SetText(nCopySuiteNum)
		end
		--
		if LR_TOOLS:Fetch("edit_CopyBookNum") and LR_TOOLS:Fetch("edit_CopyBookNum"):GetText() ~= tostring(nCopySuiteNum) then
			LR_TOOLS:Fetch("edit_CopyBookNum"):SetText(nCopySuiteNum)
		end
		if LR_CopyBook_MiniPanel:Fetch("Edit_Num") and LR_CopyBook_MiniPanel:Fetch("Edit_Num"):GetText() ~= tostring(nCopySuiteNum) then
			LR_CopyBook_MiniPanel:Fetch("Edit_Num"):SetText(nCopySuiteNum)
		end
	end
end

---------------------------------------------------------------------
function _C.SYS_MSG()
	if arg0 == "UI_OME_CRAFT_RESPOND" then
		----------arg1=1,生成技能成功释放，抄书成功
		----------arg1=2,技能施展失败
		----------arg1=6,技能调息时间未到
		----------arg1=20,操作失败，正在进行其他操作
		----------arg1=21,当前状态无法完成这个操作
		if arg1 == 1 then
			if RECIPE_PREPARE_PROGRESS_CACHE.bOn then
				_C.UpdateSuitNum()
				LR_CopyBook_MiniPanel.SYS_MSG()
				RECIPE_PREPARE_PROGRESS_CACHE = {}
				if LR_CopyBook.UsrData.nCopySuiteNum > 0 then
					_C.CopyBook()
				else
					_C.StopCopy()
				end
			end
		elseif arg1 == 1 or arg1 == 2 or arg1 == 6 or arg1 == 20 or arg1 == 211 then
			_C.StopCopy()
			RECIPE_PREPARE_PROGRESS_CACHE = {}
		else
			_C.StopCopy()
			RECIPE_PREPARE_PROGRESS_CACHE = {}
		end
	end
end

function _C.OT_ACTION_PROGRESS_BREAK()
	local dwID = arg0
	local me = GetClientPlayer()
	if not me or me.dwID ~= dwID then
		return
	end
	RECIPE_PREPARE_PROGRESS_CACHE = {}
end

function _C.DO_RECIPE_PREPARE_PROGRESS()
	local nTotalFrame = arg0
	local CraftType = arg1
	local bookID = arg2
	if CraftType == 12 then
		local dwBookID, dwSegmentID = GlobelRecipeID2BookID(bookID)
		local nowFrame = GetLogicFrameCount()
		local nEndFrame = nowFrame + nTotalFrame
		RECIPE_PREPARE_PROGRESS_CACHE = {
			bOn = true,
			dwBookID = dwBookID,
			dwSegmentID = dwSegmentID,
			nEndFrame = nEndFrame,
		}
	end
end

function _C.LOGIN_GAME()
	_C.LoadCfg()
end

LR.RegisterEvent("SHOP_OPENSHOP",function() _C.SHOP_OPENSHOP() end)
LR.RegisterEvent("LOGIN_GAME",function() _C.LOGIN_GAME() end)
---------------------
LR_CopyBook.InitCopyListMenu = _C.InitCopyListMenu
LR_CopyBook.GetSearchList = _C.GetSearchList
LR_CopyBook.CopyBook = _C.CopyBook
LR_CopyBook.GetAllRecipeNum = _C.GetAllRecipeNum
LR_CopyBook.DrawRecipeBoxes = _C.DrawRecipeBoxes
LR_CopyBook.GetCanCopySuiteNum = _C.GetCanCopySuiteNum
LR_CopyBook.StartCopy = _C.StartCopy
LR_CopyBook.StopCopy = _C.StopCopy
LR_CopyBook.GetSuiteBookNameByID = _C.GetSuiteBookNameByID
LR_CopyBook.GetAllRecipeAgainstHasInBag = _C.GetAllRecipeAgainstHasInBag
LR_CopyBook.Gets = _C.Gets
LR_CopyBook.GetOneSuiteRecipeNum = _C.GetOneSuiteRecipeNum
