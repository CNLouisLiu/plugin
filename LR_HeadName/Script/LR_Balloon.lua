local sformat, slen, sgsub, ssub,sfind = string.format, string.len, string.gsub, string.sub, string.find
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil = math.floor, math.ceil
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
local AddonPath="Interface\\LR_Plugin\\LR_HeadName"
local SaveDataPath="Interface\\LR_Plugin@DATA\\LR_HeadName"
local _L = LR.LoadLangPack(AddonPath)
-----------------------------------------------
local sziniFile="Interface\\LR_Plugin\\LR_HeadName\\UI\\LR_Balloon.ini"
local SeeTime=10000

LR_Balloon = LR_Balloon or {
	DialogList={},
	Handle_Total=nil,
	LR_HeadName_Frame=nil,
}

LR_Balloon.UsrData={
	bShowPlayerMsg=true,
	bShowNpcMsg=true,
	bBlock=true,
	NumLimit=50,
}
local CustomVersion = "20170110"
RegisterCustomData("LR_Balloon.UsrData", CustomVersion)
-----------------------------------------
local _Balloon={
	handle=nil,
	dwID=nil,
	xScreen=-4999,
	yScreen=-4999,
	szContent="",
	nStartTime=0,
	nEndTime=0,
	szName="",
	xOffset=0,
	yOffset=0,
	alpha=0,
}
_Balloon.__index = _Balloon

function _Balloon:new(obj)
	local o={}
	setmetatable(o,self)
	o.dwID=obj.dwID
	o.self=obj
	o.nType=obj.nType
	o.szContent=obj.szContent
	o.nStartTime = GetTime()
	o.nEndTime = GetTime()+SeeTime
	return o
end

function _Balloon:Create()
	local Handle_Total=LR_Balloon.Handle_Total
	local dwID = self.dwID
	local Handle_Balloon=Handle_Total:Lookup(sformat("Handle_Balloon_%d", dwID))
	local sziniFile = "Interface\\LR_Plugin\\LR_HeadName\\UI\\LR_BalloonItem.ini"
	if not Handle_Balloon then
		Handle_Balloon=Handle_Total:AppendItemFromIni(sziniFile, "Handle_Balloon", sformat("Handle_Balloon_%d", dwID))
	end
	Handle_Balloon:RegisterEvent(277)
	Handle_Balloon.OnItemMouseEnter = function()
		if IsPlayer(dwID) and dwID ~= GetClientPlayer().dwID then
			if Handle_Balloon then
				local Image_Hover = Handle_Balloon:Lookup("Image_Hover")
				if Image_Hover then
					Image_Hover:Show()
				end
			end
		end
	end

	Handle_Balloon.OnItemMouseLeave = function()
		if IsPlayer(dwID) and dwID ~= GetClientPlayer().dwID then
			if LR_Balloon.DialogList[dwID] then
				if Handle_Balloon then
					local Image_Hover = Handle_Balloon:Lookup("Image_Hover")
					if Image_Hover then
						Image_Hover:Hide()
					end
				end
			end
		end
	end

	Handle_Balloon.OnItemLButtonClick = function()
		if IsPlayer(dwID) and dwID ~= GetClientPlayer().dwID then
			self:Remove()
			LR_Balloon.DialogList[dwID] = nil
			local player=GetPlayer(dwID)
			if player then
				LR_Balloon.LoadBlock()
				LR_Balloon.BlockList.RoleList[dwID] = {dwID=dwID,szName=LR.Trim(player.szName)}
				LR_Balloon.SaveBlock()
			end
			local msg=_L["LR_Balloon:Shield balloons from [%s].\n"]
			msg=sformat(msg,LR.Trim(player.szName))
			LR.SysMsg(msg)
			if IsShiftKeyDown () then
				LR_Balloon_Panel:Open()
			end
		end
	end
	self.handle=Handle_Balloon
	--Output("2",self.dwID)
	return self
end

function _Balloon:Remove()
	local Handle_Total=LR_Balloon.Handle_Total
	local dwID = self.dwID
	local Handle_Balloon=Handle_Total:Lookup(sformat("Handle_Balloon_%d", dwID))
	if Handle_Balloon then
		Handle_Total:RemoveItem(Handle_Balloon)
	end
	self.handle=nil
	return self
end

function _Balloon:GetHandle()
	return self.handle
end

function _Balloon:GetPos()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local tab=self
	local dwID=self.dwID

	PostThreadCall(function(tab, xScreen, yScreen)
		local xScreen = xScreen or 0
		local yScreen = yScreen or 0

		xScreen ,yScreen = Station.AdjustToOriginalPos(xScreen, yScreen)
		tab.xScreen = xScreen
		tab.yScreen = yScreen

		tab:SetPos()
	end, tab , "Scene_GetCharacterTopScreenPos", dwID)
	return self
end

function _Balloon:SetPos()
	local xScreen=self.xScreen
	local yScreen=self.yScreen
	local handle=self.handle
	local nTopOffset = LR_HeadName.UsrData.nBallonTopOffset or 0

	xScreen = xScreen - self.xOffset
	yScreen = yScreen - self.yOffset + nTopOffset

	handle:SetAbsPos(xScreen,yScreen)
	return self
end

function _Balloon:SetContent(szContent)
	self.szContent=szContent or ""
	return self
end

function _Balloon:DrawContent()
	local handle=self.handle
	local Handle_Content=handle:Lookup("Handle_Content")
	local szContent=self.szContent
	Handle_Content:Clear()
	Handle_Content:SetSize(300,200)
	Handle_Content:AppendItemFromString(szContent)
	Handle_Content:FormatAllItemPos()
	Handle_Content:SetSizeByAllItemSize()

	local w ,h =Handle_Content:GetAllItemSize()
	w, h = w + 20, h + 20
	handle:SetSize(w,h)
	local image = handle:Lookup("Image_Bg1")
	image:SetSize(w, h)
	if not LR_HeadName.UsrData.nBallonType or LR_HeadName.UsrData.nBallonType  == 3 then
		image:FromUITex("ui\\Image\\TeachingPanel\\TeachingPanel4.UITex", 11)
	elseif LR_HeadName.UsrData.nBallonType  == 2 then
		image:FromUITex("ui\\Image\\LootPanel\\LootPanel.UITex", 80)
	elseif LR_HeadName.UsrData.nBallonType  == 1 then
		image:FromUITex("ui\\Image\\UICommon\\CommonPanel.UITex", 21)
	elseif LR_HeadName.UsrData.nBallonType  == 4 then
		image:FromUITex("ui\\Image\\UICommon\\RaidTotal.UITex", 17)
	elseif LR_HeadName.UsrData.nBallonType  == 5 then
		image:FromUITex("ui\\Image\\UICommon\\RaidTotal.UITex", 15)
	end

	local imagehover = handle:Lookup("Image_Hover")
	imagehover:SetSize(w, h)
	imagehover:Hide()
	local image2 = handle:Lookup("Image_Bg2")
	local szName=self.szName
	local len=slen(szName)

	if w > (len*16 + 8) then
		image2:SetRelPos( ( w * 0.5 + len*7-10), h - 4)
	else
		image2:SetRelPos(w * 0.8 - 16, h - 4)
	end
	handle:FormatAllItemPos()

	-----设置偏移量
	local cxLR_Balloon, cyLR_Balloon = handle:GetSize()
	local nTopOffset = LR_HeadName.UsrData.nBallonTopOffset or 0
	local dwID = self.dwID
	if LR_HeadName._Role[dwID] then
		if LR_HeadName._Role[dwID]:GetHandle() then
			nTopOffset = LR_HeadName._Role[dwID]:GetHandle():GetnTopOffset()
		end
	end
	self.xOffset = cxLR_Balloon * 0.5
	self.yOffset = cyLR_Balloon + 30 + nTopOffset

	return self
end

function _Balloon:SetStartTime()
	self.nStartTime = GetTime()
	return self
end

function _Balloon:GetStartTime()
	return self.nStartTime
end

function _Balloon:SetEndTime()
	self.nEndTime = self.nStartTime + SeeTime
	return self
end

function _Balloon:GetEndTime()
	return self.nEndTime
end

function _Balloon:GetType()
	return self.nType
end

function _Balloon:SetName(szName)
	self.szName=szName or ""
	return self
end

function _Balloon:SetAlpha(alpha)
	self.alpha=alpha
	self.handle:SetAlpha(alpha)
	return self
end

function _Balloon:GetAlpha()
	return self.handle:GetAlpha()
end

function _Balloon:Fade()
	local nTime=GetTime()
	local alpha=self.alpha
	if nTime-self.nStartTime < 3000 then
		alpha=alpha +10
		if alpha <255 then
			self:SetAlpha(alpha)
		end
	elseif self.nEndTime - nTime <1000 then
		alpha=alpha - 10
		if alpha > 0 then
			self:SetAlpha(alpha)
		end
	end
	return self
end

function _Balloon:Hide()
	self.handle:Hide()
	return self
end

function _Balloon:Show()
	self.handle:Show()
	return self
end

---------------------------------------------------
function LR_Balloon.OnFrameCreate()
	this:RegisterEvent("PLAYER_SAY")
	this:RegisterEvent("RENDER_FRAME_UPDATE")
	LR_Balloon.LR_HeadName_Frame=Station.Lookup("Lowest/LR_HeadName")
	--LR_Balloon.LR_HeadName_Frame=this
	local handle=LR_Balloon.LR_HeadName_Frame:Lookup("","")
	LR_Balloon.Handle_Total=handle:Lookup("Handle_Balloons")
	LR_Balloon.Handle_Total:Clear()
end

function LR_Balloon.OnEvent(szEvent)
	if szEvent == "PLAYER_SAY" then
		LR_Balloon.PLAYER_SAY()
	elseif szEvent == "RENDER_FRAME_UPDATE" then
		LR_Balloon.OnFrameBreathe()
	end
end

function LR_Balloon.Sort()
	local DialogList=LR_Balloon.DialogList
	local t={}
	for dwID, v in pairs (DialogList) do
		t[#t+1]={dwID=dwID,nIndex=v.yScreen}
	end
	tsort(t, function(a, b) return a.nIndex < b.nIndex end)
	for i=#t,1,-1 do
		local dwID=t[i].dwID
		local handle=DialogList[dwID]:GetHandle()
		if handle:GetIndex() ~= i-1 then
			handle:ExchangeIndex(i-1)
		end
	end
end

function LR_Balloon.OnFrameBreathe()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_HeadName.UsrData.bShowBalloon then
		return
	end

	if IsCtrlKeyDown() and (IsShiftKeyDown() or IsAltKeyDown()) then
		LR_Balloon.LR_HeadName_Frame:SetMousePenetrable(false)
	else
		LR_Balloon.LR_HeadName_Frame:SetMousePenetrable(true)
	end
	local DialogList=LR_Balloon.DialogList
	for dwID,v in pairs (DialogList) do
		local tar=LR.GetCharacter(dwID)
		if not tar then
			v:Remove()
			DialogList[dwID] = nil
		else
			if GetTime() - v:GetEndTime() > 0  then
				v:Remove()
				DialogList[dwID] = nil
			else
				if LR.GetDistance(tar) > 45 then
					v:Hide()
				else
					v:Fade()
					v:GetPos()
					v:Show()
				end
			end
		end
	end
	local num=LR_Balloon.Handle_Total:GetItemCount()
	if num < 35 then
		LR_Balloon.Sort()
	end
end

--LR_Balloon.OnFrameRender = LR_Balloon.OnFrameBreathe

function LR_Balloon.PLAYER_SAY()
	if not LR_HeadName.UsrData.bShowBalloon then
		return
	end
	local szContent=arg0
	local dwID=arg1
	local szName=LR.Trim(arg3)
	local obj={dwID=dwID,szContent=szContent,nType=TARGET.NPC,}
	local NumLimit = LR_Balloon.UsrData.NumLimit or 50
	local num=LR_Balloon.Handle_Total:GetItemCount()
	if num > NumLimit and dwID ~= GetClientPlayer().dwID then
		return
	end

	if IsPlayer(dwID) then
		obj.nType = TARGET.PLAYER
	end

	if not LR_Balloon.UsrData.bShowPlayerMsg and obj.nType == TARGET.PLAYER then
		return
	end
	if not LR_Balloon.UsrData.bShowNpcMsg and obj.nType == TARGET.NPC then
		return
	end

	if LR_Balloon.UsrData.bBlock and dwID ~= GetClientPlayer().dwID then
		if obj.nType == TARGET.PLAYER then
			local player = GetPlayer(dwID)
			if not player then
				return
			end
			if player.nLevel <= 20 then
				return
			end
		end
		if LR_Balloon.BlockList.RoleList[dwID] then
			return
		end
		if LR_Balloon.IsBlockedByKey(szContent) then
			return
		end
	end

	local DialogList=LR_Balloon.DialogList
	local tar=LR.GetCharacter(dwID)
	if not tar then
		if DialogList[dwID] then
			DialogList[dwID]:Remove()
			DialogList[dwID]=nil
		end
		return
	end

	if DialogList[dwID] then
		DialogList[dwID]:SetContent(szContent)
		DialogList[dwID]:SetAlpha(0):DrawContent():SetStartTime():SetEndTime()
	else
		DialogList[dwID]=_Balloon:new(obj)
		DialogList[dwID]:Create():SetAlpha(0):SetName(szName):SetPos():DrawContent():SetStartTime():SetEndTime()
	end
end

Wnd.OpenWindow(sziniFile, "LR_Balloon")

---------------------------------------------------------------------
---------屏蔽相关
---------------------------------------------------------------------
LR_Balloon.BlockList={
	KeyList={},
	RoleList={},
}

function LR_Balloon.SaveBlock()
	local path=sformat("%s\\UsrData\\BlockList.dat",SaveDataPath)
	local BlockList=LR_Balloon.BlockList
	SaveLUAData (path,BlockList)
end

function LR_Balloon.LoadBlock()
	LR_Balloon.CheckBlock()
	local path=sformat("%s\\UsrData\\BlockList.dat",SaveDataPath)
	local BlockList= LoadLUAData (path) or {}
	LR_Balloon.BlockList = clone (BlockList)
end

function LR_Balloon.CheckBlock()
	local path=sformat("%s\\UsrData\\BlockList.dat.jx3dat",SaveDataPath)
	if not  IsFileExist(path) then
		local path=sformat("%s\\UsrData\\BlockList.dat",SaveDataPath)
		local BlockList={
			KeyList={},
			RoleList={},
		}
		SaveLUAData (path,BlockList)
	end
end

function LR_Balloon.IsBlockedByKey(szContent)
	local szContent = szContent
	local keys=LR_Balloon.BlockList.KeyList or {}
	for k,v in pairs (keys) do
		local _start,_end=sfind(szContent,v)
		if _start then
			return true
		end
	end
	return false
end

LR.RegisterEvent("FIRST_LOADING_END",function() LR_Balloon.LoadBlock() end)

---------------------------------------------------------------------
---------屏蔽管理
---------------------------------------------------------------------
------------------------------------------
--界面
------------------------------------------
LR_Balloon_Panel = _G2.CreateAddon("LR_Balloon_Panel")
LR_Balloon_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_Balloon_Panel.nChose=1

LR_Balloon_Panel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0},
}


function LR_Balloon_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")

	LR_Balloon_Panel.UpdateAnchor(this)
	RegisterGlobalEsc("LR_Balloon_Panel",function () return true end ,function() LR_Balloon_Panel:Open() end)
	LR_Balloon_Panel.nChose = 1
end

function LR_Balloon_Panel:OnEvents(event)
	if event == "UI_SCALED" then
		LR_Balloon_Panel.UpdateAnchor(this)
	end
end

function LR_Balloon_Panel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_Balloon_Panel.UsrData.Anchor.s, 0, 0, LR_Balloon_Panel.UsrData.Anchor.r, LR_Balloon_Panel.UsrData.Anchor.x, LR_Balloon_Panel.UsrData.Anchor.y)
end

function LR_Balloon_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_Balloon_Panel")
	PlaySound(SOUND.UI_SOUND,g_sound.CloseFrame)
end

function LR_Balloon_Panel:OnDragEnd()
	this:CorrectPos()
	LR_Balloon_Panel.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_Balloon_Panel:Init()
	local frame = self:Append("Frame", "LR_Balloon_Panel", {title = _L["Shield Settings"], style = "SMALL"})

	----------关于
	LR.AppendAbout(LR_Balloon_Panel,frame)

	local imgTab = self:Append("Image", frame,"TabImg",{w = 381,h = 33,x = 0,y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex",46)
	imgTab:SetImageType(11)

	local hPageSet = self:Append("PageSet", frame, "PageSet", {x = 20, y = 120, w = 360, h = 330})
	local hWinIconView = self:Append("Window", hPageSet, "WindowItemView", {x = 0, y = 0, w = 360, h = 330})
	local hScroll = self:Append("Scroll", hWinIconView,"Scroll", {x = 0, y = 0, w = 354, h = 330})
	self:LoadItemBox(hScroll)
	hScroll:UpdateList()

	local hComboBoxChose = self:Append("ComboBox", frame, "hComboBoxChose", {w = 140, x = 20, y = 51, text = _L["Key Settings"]})
	hComboBoxChose:Enable(true)

	hComboBoxChose.OnClick = function (m)
		m[#m+1]={szOption=_L["Key Settings"],bCheck=true,bMCheck=true,bChecked=function() return LR_Balloon_Panel.nChose == 1 end,
			fnAction=function()
				LR_Balloon_Panel.nChose = 1
				hComboBoxChose:SetText(_L["Key Settings"])
				local cc=self:Fetch("Scroll")
				if cc then
					self:ClearHandle(cc)
				end
				self:LoadItemBox(cc)
				cc:UpdateList()
			end
		}
		m[#m+1]={szOption=_L["Role Shield Settings"],bCheck=true,bMCheck=true,bChecked=function() return LR_Balloon_Panel.nChose == 2 end,
			fnAction=function()
				LR_Balloon_Panel.nChose = 2
				hComboBoxChose:SetText(_L["Role Shield Settings"])
				local cc=self:Fetch("Scroll")
				if cc then
					self:ClearHandle(cc)
				end
				self:LoadItemBox(cc)
				cc:UpdateList()
			end
		}
		PopupMenu(m)
	end

	local hButton = self:Append("Button", frame, "AddKeyButtoon", {w = 120, x = 190, y = 51, text = _L["Add keys"]})
	hButton:Enable(true)
	hButton.OnClick = function()
		GetUserInput(_L["Add keys"], function(szText)
			local szText =  sgsub(szText, "^%s*%[?(.-)%]?%s*$", "%1")
			if szText ~= "" then
				LR_Balloon.LoadBlock()
				local keys=LR_Balloon.BlockList.KeyList
				local bAdd=true
				for k,v in pairs (keys) do
					if v==szText then
						bAdd=false
					end
				end
				if bAdd then
					keys[#keys+1] = szText
					LR_Balloon.SaveBlock()
					local cc=self:Fetch("Scroll")
					if cc then
						self:ClearHandle(cc)
					end
					self:LoadItemBox(cc)
					cc:UpdateList()
					LR.SysMsg(_L["Successful!Add key: %s .\n"])
				end
			end
		end)
	end

	local hButton2 = self:Append("Button", frame, "AddKeyButtoon2", {w = 140, x = 20, y = 460, text = _L["Quick shield des"]})
	hButton2.OnEnter = function()
		local x, y=this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml =GetFormatText(_L["Hold Ctrl+Alt,Click Balloon,shield this person.\nHold Shift+Alt,Click Balloon,shield this person and open shield panel.\n "],0,255,128,0)
		OutputTip(szXml,350,{x,y,120,40})
	end
	hButton2.OnLeave = function()
		HideTip()
	end

	-------------初始界面物品
	local hHandle = self:Append("Handle", frame, "Handle", {x = 18, y = 90, w = 340, h = 390})

	local Image_Record_BG = self:Append("Image", hHandle, "Image_Record_BG", {x = 0, y = 0, w = 340, h = 360})
	Image_Record_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",50)
	Image_Record_BG:SetImageType(10)

	local Image_Record_BG1 = self:Append("Image", hHandle, "Image_Record_BG1", {x = 0, y = 30, w = 340, h = 330})
	Image_Record_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",74)
	Image_Record_BG1:SetImageType(10)
	Image_Record_BG1:SetAlpha(110)

	local Image_Record_Line1_0 = self:Append("Image", hHandle, "Image_Record_Line1_0", {x = 3, y = 28, w = 340, h = 3})
	Image_Record_Line1_0:FromUITex("ui\\Image\\Minimap\\MapMark.UITex",65)
	Image_Record_Line1_0:SetImageType(11)
	Image_Record_Line1_0:SetAlpha(115)

	local Text_break1 = self:Append("Text", hHandle, "Text_break1", {w = 340, h = 30, x =0, y = 2, text = _L["Key/Role"], font = 18})
	Text_break1:SetHAlign(1)
	Text_break1:SetVAlign(1)
end

function LR_Balloon_Panel:Open()
	local frame = self:Fetch("LR_Balloon_Panel")
	if frame then
		self:Destroy(frame)
	else
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
end

function LR_Balloon_Panel:LoadItemBox(hWin)
	local List={}
	if LR_Balloon_Panel.nChose == 1 then
		List=LR_Balloon.BlockList.KeyList
	elseif LR_Balloon_Panel.nChose == 2 then
		List=LR_Balloon.BlockList.RoleList
	end

	local i=1
	for k,v in pairs (List) do
		local hIconViewContent = self:Append("Handle", hWin, sformat("IconViewContent_%d", i), {x = 0, y = 0, w = 340, h = 30})

		local Image_Line = self:Append("Image", hIconViewContent, sformat("Image_Line_%d", i), {x = 0, y = 0, w = 340, h = 30})
		Image_Line:FromUITex("ui\\Image\\button\\ShopButton.UITex",75)
		Image_Line:SetImageType(10)
		Image_Line:SetAlpha(200)

		if i % 2 == 0 then
			Image_Line:Hide()
		end

		--悬停框
		local Image_Hover = self:Append("Image", hIconViewContent, sformat("Image_Hover_%d", i), {x = 0, y = 0, w = 340, h = 30})
		Image_Hover:FromUITex("ui\\Image\\Common\\TempBox.UITex",5)
		Image_Hover:SetImageType(10)
		Image_Hover:SetAlpha(200)
		Image_Hover:Hide()
		--选择框
		local Image_Select = self:Append("Image", hIconViewContent, sformat("Image_Select_%d", i), {x = 2, y = 0, w = 336, h = 30})
		Image_Select:FromUITex("ui\\Image\\Common\\TempBox.UITex",6)
		Image_Select:SetImageType(10)
		Image_Select:SetAlpha(200)
		Image_Select:Hide()

		local szText=""
		if LR_Balloon_Panel.nChose == 1 then
			szText = v
		elseif LR_Balloon_Panel.nChose == 2 then
			szText = v.szName
		end

		local Text_break1 = self:Append("Text", hIconViewContent, sformat("Text_break_%d_1", i), {w = 300, h = 30, x =15, y = 2, text = szText, font = 18})
		Text_break1:SetHAlign(1)
		Text_break1:SetVAlign(1)

		-----------------------
		----鼠标事件
		-----------------------
		hIconViewContent.OnClick = function()
			local menu={
			{	szOption=_L["Delete"],
				fnAction=function()
					List[k]=nil
					LR_Balloon.SaveBlock()
					LR.SysMsg(_L["Successful!Delete key/role.\n"])
					local cc=self:Fetch("Scroll")
					if cc then
						self:ClearHandle(cc)
					end
					self:LoadItemBox(cc)
					cc:UpdateList()
				end
			},}
			PopupMenu(menu)
		end
		hIconViewContent.OnEnter = function()
			Image_Hover:Show()
		end
		hIconViewContent.OnLeave = function()
			Image_Hover:Hide()
		end

		i=i+1
	end
end



