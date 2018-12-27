local AddonPath="Interface\\LR_Plugin\\LR_CopyBook"
local _L = LR.LoadLangPack(AddonPath)
local sformat, slen, sgsub, ssub,sfind = string.format, string.len, string.gsub, string.sub, string.find
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil = math.floor, math.ceil
local tconcat, tinsert, tremove, tsort = table.concat, table.insert, table.remove, table.sort
------------------------------------
LR_CopyBook= {
	on=false,
	OTAFlag=0,
	LastTime=0,
}
LR_CopyBook.Needs={}
LR_CopyBook.Default ={
	szName=_L["Please Enter Suitbook Name"],
	KillOTA=false,
	CopyLimitNum=1,
	NeedText="",
	bookList = {},
}
LR_CopyBook.UsrData = clone(LR_CopyBook.Default)

local CustomVersion = "20170523v1"
RegisterCustomData("LR_CopyBook.UsrData", CustomVersion)
LR_CopyBook.TempName=LR_CopyBook.UsrData.szName
LR_CopyBook.RemainNum=0
LR_CopyBook.bHookedReadPanel=false
LR_CopyBook.bHookedBookExchangePanel=false

function LR_CopyBook.HookReadPanel()
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

function LR_CopyBook.HookBookExchangePanel()
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

function LR_CopyBook.ON_FRAME_CREATE()
	local frame=arg0
	local szName=frame:GetName()
	if szName == "CraftReadManagePanel" then
		---------阅读界面增加抄书按钮
		LR.DelayCall(500, function() LR_CopyBook.HookReadPanel() end)
	elseif szName == "BookExchangePanel" then
		---------书籍兑换界面增加抄书按钮
		LR.DelayCall(500, function() LR_CopyBook.HookBookExchangePanel() end)
	end
end

LR.RegisterEvent("ON_FRAME_CREATE",function() LR_CopyBook.ON_FRAME_CREATE()  end)

--获取套书ID
--返回dwBookID：套书ID 以及 dwBookNumber:套书有几本
function LR_CopyBook.GetSuitBookID (szName)
	local RowCount= g_tTable.BookSegment:GetRowCount()
	local i=2
	while i<=RowCount do
		local t=g_tTable.BookSegment:GetRow(i)
		if LR.Trim(szName)==LR.Trim(t.szBookName) then
			return t.dwBookID, t.dwBookNumber
		end
		i=i+t.dwBookNumber
	end
	return nil,nil
end

function LR_CopyBook.GetBookName(dwBookID, dwSegmentID)
	local szBookName = ""
	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		szBookName = tBookSegment.szBookName
	end
	return szBookName
end

function LR_CopyBook.GetSegmentName(dwBookID, dwSegmentID)
	local szSegmentName = ""
	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		szSegmentName = tBookSegment.szSegmentName
	end
	return szSegmentName
end


function LR_CopyBook.GetBookNum(dwBookID, dwSegmentID)
	local me = GetClientPlayer()
	local num = 0
	for _, dwBox in pairs(BAG_PACKAGE) do
		local size = me.GetBoxSize(dwBox)
		for dwX = 0, size - 1, 1 do
			local item = me.GetItem(dwBox, dwX)
			if item then
				if LR.GetItemNameByItem(item) == LR_CopyBook.GetSegmentName(dwBookID, dwSegmentID) then
					num = me.GetItemAmount(item.dwTabType, item.dwIndex, dwBookID, dwSegmentID)
				end
			end
		end
	end

	return num
end

function LR_CopyBook.CreateBookTable()
	local temp_book_id, temp_book_num=LR_CopyBook.GetSuitBookID(LR_CopyBook.UsrData.szName)
	local player = GetClientPlayer()
	local temp_name,temp_readed,temp_num,temp_isCopy

	LR_CopyBook.UsrData.bookList = {}
	local bookList = LR_CopyBook.UsrData.bookList
	if temp_book_id then
		for i = 1, temp_book_num do
			bookList[#bookList+1] = {dwBookID = temp_book_id, dwSegmentID = i, bCopy = true,}
		end
	end
end

function LR_CopyBook.StopCopy ()
	if LR_CopyBook.on == true then
		LR.SysMsg(sformat("%s\n", _L["Stop Printing!"]))
	end
	LR_CopyBook.on=false
	Wnd.CloseWindow("LR_CopyBook")
	if LR_CopyBook.UsrData.KillOTA==true then
		local player=GetClientPlayer()
		player.StopCurrentAction()
	end
end


function LR_CopyBook.OnFrameCreate()
	this:RegisterEvent("SYS_MSG")
	this:RegisterEvent("CUSTOM_DATA_LOADED")
end

function LR_CopyBook.OnEvent(event)
	if event == "SYS_MSG" then
		if arg0=="UI_OME_CRAFT_RESPOND" then
			if not LR_CopyBook.on then
				return
			end
			----------arg1=1,成功抄录
			----------arg1=2,技能施展失败
			----------arg1=6,技能调息时间未到
			----------arg1=20,操作失败，正在进行其他操作
			----------arg1=21,当前状态无法完成这个操作

			if arg1 ~=1 and arg1~=20 and arg1~=2  and arg1~=6  and arg1~=21  then
				local handle = Station.Lookup("Topmost2/Announce", "")
				if not handle then
					return
				end
				local text = handle:Lookup(4)
				if text then
					LR.SysMsg(sformat("%s\n", sgsub(text:GetText(),"\n","")))
				end
				LR_CopyBook.StopCopy()
				return
			end
			if arg1 == 1 then
				LR_CopyBook.OTAFlag=0
				LR_CopyBook.RemainNum = LR_CopyBook.RemainNum - 1
				LR.SysMsg(sformat("%s\n", sformat(_L["Remain %d book(s)."], LR_CopyBook.RemainNum)))
				LR_CopyBook.CountNeeds()
				LR_CopyBook_MiniPanel:DrawNeed()
				if LR_CopyBook.RemainNum<=0 then
					LR_CopyBook.StopCopy ()
				end
			elseif arg1 == 0 then
				LR_CopyBook.OTAFlag=1
			end
			LR_CopyBook.LastTime=GetLogicFrameCount()+GetPingValue()/62.5 - 7
		end
	end
	if event == "CUSTOM_DATA_LOADED" then
		if next(LR_CopyBook.UsrData.bookList) == nil then
			LR_CopyBook.CreateBookTable()
		end
		LR_CopyBook.an1=LR_CopyBook.UsrData.szName
	end
end

function LR_CopyBook.GetNeeds(dwBookID,choose_id)
	local player=GetClientPlayer()
	local recipe  = GetRecipe(12, dwBookID, choose_id)
	local szTool = {}
	szTool[#szTool+1] = _L["Need:"]
	for nIndex = 1, 4, 1 do
		local nType  = recipe[sformat("dwRequireItemType%d", nIndex)]
		local nID	 = recipe[sformat("dwRequireItemIndex%d", nIndex)]
		local nNeed  = recipe[sformat("dwRequireItemCount%d", nIndex)]
		if nNeed > 0 then
			local ItemRequire = GetItemInfo(nType, nID)
			local szItemName = LR.GetItemNameByItemInfo(ItemRequire)
			local nCount = player.GetItemAmount(nType, nID)
			szTool[#szTool+1] = sformat(" %s[ %d / %d ] ", szItemName, nNeed, nCount)
		end
	end
	szTool[#szTool+1] = "\n"
	LR.SysMsg(tconcat(szTool))
end

function LR_CopyBook.CountNeeds()
	LR_CopyBook.Needs = {}
	local me = GetClientPlayer()
	if not me then
		return
	end

	local LR_TOOLS_Panel = Station.Lookup("Normal/LR_TOOLS")
	local LR_CopyBook_MiniUI_frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
	if not (LR_CopyBook.on or LR_TOOLS_Panel or LR_CopyBook_MiniUI_frame) then
		return
	end

	local bookList = LR_CopyBook.UsrData.bookList or {}
	if next(bookList) == nil then
		return
	end

	local szName = LR_CopyBook.GetBookName(bookList[1].dwBookID, 1)
	local dwBookID , dwBookNumber = LR_CopyBook.GetSuitBookID(szName)

	if dwBookNumber == nil then
		return
	end

	local t_SingleBookNeed = {}
	for k, v in pairs(bookList) do
		if v.bCopy and me.IsBookMemorized(v.dwBookID, v.dwSegmentID) then
			local temp = {}
			temp.szName = LR_CopyBook.GetSegmentName(v.dwBookID, v.dwSegmentID)
			temp.dwBookID = v.dwBookID
			temp.dwSegmentID = v.dwSegmentID
			temp.num = LR_CopyBook.GetBookNum(v.dwBookID, v.dwSegmentID)
			local needs = {}
			local recipe  = GetRecipe(12, v.dwBookID, v.dwSegmentID)
			for nIndex = 1, 4, 1 do
				local nType = recipe[sformat("dwRequireItemType%d", nIndex)]
				local dwIndex = recipe[sformat("dwRequireItemIndex%d", nIndex)]
				local nNeed  = recipe[sformat("dwRequireItemCount%d", nIndex)]
				if nNeed > 0 then
					local iteminfo = GetItemInfo(nType, dwIndex)
					local szItemName = LR.GetItemNameByItemInfo(iteminfo)
					needs[#needs+1] = {szName = szItemName, nNeed = nNeed, nType = nType, dwIndex = dwIndex}
				end
			end
			temp.needs = clone(needs)
			t_SingleBookNeed[#t_SingleBookNeed+1] = clone(temp)
		end
	end

	local t_Needs = {}
	local i = 0
	if LR_CopyBook.on then
		i = LR_CopyBook.RemainNum
	else
		i = LR_CopyBook.UsrData.CopyLimitNum
	end
	if next(t_SingleBookNeed) ~= nil then
		while i > 0 do
			for k, v in pairs(t_SingleBookNeed) do
				if i > 0 then
					if v.num > 0 then
						v.num = v.num - 1
					else
						for k2, v2 in pairs (v.needs) do
							if v2.nNeed > 0 then
								t_Needs[v2.dwIndex] = t_Needs[v2.dwIndex] or {need = 0}
								t_Needs[v2.dwIndex].need = t_Needs[v2.dwIndex].need + v2.nNeed
								t_Needs[v2.dwIndex].dwIndex = v2.dwIndex
								t_Needs[v2.dwIndex].nType = v2.nType
								t_Needs[v2.dwIndex].szName = v2.szName
							end
						end
						i = i - 1
					end
				end
			end
		end
	end

	local t_Needs2 = {}
	for k, v in pairs(t_Needs) do
		t_Needs2[#t_Needs2+1] = v
	end

	tsort(t_Needs2,function(a,b)
		return a.dwIndex < b.dwIndex
	end)

	LR_CopyBook.Needs = clone(t_Needs2)

	if #t_Needs2 == 0 then
		local CopyBookNeeds=LR_TOOLS:Fetch("LR_CopyBook_UI_CopyBookNeeds")
		if CopyBookNeeds then
			CopyBookNeeds:SetText("")
		end
		return
	end

	local text = {}
	text[#text+1] = sformat("%s\n", _L["Need:"])
	for k,v in pairs(t_Needs2) do
		text[#text+1] = sformat("%s：%d（%d）\n", v.szName, v.need, me.GetItemAmount(v.nType, v.dwIndex))
	end
	local CopyBookNeeds=LR_TOOLS:Fetch("LR_CopyBook_UI_CopyBookNeeds")
	local frame=Station.Lookup("Normal/LR_TOOLS")
	if CopyBookNeeds and frame then
		CopyBookNeeds:SetText(tconcat(text))
	end
	LR_CopyBook.UsrData.NeedText=tconcat(text)
end

function LR_CopyBook.OnFrameBreathe()
	if not LR_CopyBook.on then
		return
	end
	if Hotkey.IsKeyDown(0x1B) and IsCtrlKeyDown() then
		LR_CopyBook.StopCopy()
		return
	end

	if GetLogicFrameCount() % 3 ~= 0 then
		return
	end
	local player=GetClientPlayer()
	local LR_UI_frame=Station.Lookup("Normal/LR_TOOLS")
	local LR_CopyBook_MiniUI_frame=Station.Lookup("Normal/LR_CopyBook_MiniPanel")
	if not (LR_UI_frame or LR_CopyBook_MiniUI_frame) then
		LR_CopyBook.StopCopy()
		return
	end
	if player.GetOTActionState() ~= 0 then
		LR_CopyBook.OTAFlag=1
		LR_CopyBook.LastTime=GetLogicFrameCount()+GetPingValue()/62.5
		return
	else
		LR_CopyBook.OTAFlag=0
	end
	if LR_CopyBook.OTAFlag==1 then
		return
	end
	if LR_CopyBook.OTAFlag==0 and GetLogicFrameCount() - LR_CopyBook.LastTime < 12 then
		return
	end
	local dwBookID,dwBookNumber=LR_CopyBook.GetSuitBookID (LR_CopyBook.UsrData.szName)
	if not dwBookID then
		return
	end
	local choose_id = 0
	local min_num = 999

	for i = dwBookNumber, 1, -1 do
		if LR_CopyBook.UsrData.bookList[i].bCopy and player.IsBookMemorized(dwBookID,i) then
			local num=LR_CopyBook.GetBookNum(dwBookID, i)
			if num <= min_num then
				min_num = num
				choose_id = i
			end
		end
	end
	if choose_id == 0 then
		LR_CopyBook.on=false
		return
	end

	if player and player.GetOTActionState() == 0 and player.nMoveState == MOVE_STATE.ON_STAND and (not player.bFightState) then
		LR.SysMsg(_L["Begin printing 【%s】\n"],LR_CopyBook.GetSegmentName(dwBookID,choose_id))
		LR_CopyBook.GetNeeds(dwBookID,choose_id)
		player.CastProfessionSkill(12, dwBookID, choose_id)
		LR_CopyBook.LastTime=GetLogicFrameCount()+GetPingValue()/62.5
	end
end

function LR_CopyBook.ON_BAG_ITEM_UPDATE ()

end

RegisterEvent("BAG_ITEM_UPDATE",LR_CopyBook.ON_BAG_ITEM_UPDATE)




