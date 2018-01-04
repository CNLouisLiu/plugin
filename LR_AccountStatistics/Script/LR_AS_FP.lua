local AddonPath="Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath="Interface\\LR_Plugin@DATA\\LR_AccountStatistics"
local _L = LR.LoadLangPack(AddonPath)
local sformat, slen, sgsub, ssub,sfind = string.format, string.len, string.gsub, string.sub, string.find
local mfloor, mceil, mmin, mmax = math.floor, math.ceil, math.min, math.max
local tconcat, tinsert, tremove, tsort = table.concat, table.insert, table.remove, table.sort
----------------------------------------------------------
local DefaultData={
	Version="1.0",
	Anchor = {x = 500, y = 20},
}

LR_AccountStatistics_FP={
	on=true,
	last_time=0,
}
LR_AccountStatistics_FP.UsrData = clone(DefaultData)

-----------------------------------------------------------------
function LR_AccountStatistics_FP.SaveCommonData()
	local path = sformat("%s\\UsrData\\FloatPanelData.dat", SaveDataPath)
	local data = {}
	data.Version = DefaultData.Version
	data.Anchor = clone(LR_AccountStatistics_FP.UsrData.Anchor)
	SaveLUAData(path, data)
end

function LR_AccountStatistics_FP.LoadCommonData()
	local path =sformat("%s\\UsrData\\FloatPanelData.dat", SaveDataPath)
	local data = LoadLUAData(path) or {}
	if data.Version and data.Version == DefaultData.Version then
		LR_AccountStatistics_FP.UsrData = clone(data)
	else
		LR_AccountStatistics_FP.UsrData = clone(DefaultData)
		LR_AccountStatistics_FP.SaveCommonData()
	end
end
----------------------------------------------------------------


function LR_AccountStatistics_FP.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")

	this:Lookup("Btn_MainBtn").OnLButtonClick= function ()
		LR_AccountStatistics.OpenPanel()
	end
	this:Lookup("Btn_MainBtn").OnRButtonClick= function ()
		LR_Acc_Trade_Panel:Open()
	end
	this:Lookup("Btn_MainBtn").OnMouseEnter= function ()
		local me = GetClientPlayer()
		local x, y=this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml =GetFormatText(_L["Left click to open [LR_AccountStatistics]\nRight click to open[LR Trade Record]."],18)
		OutputTip(szXml,350,{x,y,w,h})
	end
	this:Lookup("Btn_MainBtn").OnMouseLeave= function ()
		HideTip()
	end
	LR_AccountStatistics_FP.ShowMoney(0)
	LR_AccountStatistics_FP.UpdateAnchor()
	LR_AccountStatistics_FP.Refresh()
end

function LR_AccountStatistics_FP.OnFrameDragEnd()
	this:CorrectPos()
	local x, y = this:GetRelPos()
	LR_AccountStatistics_FP.UsrData.Anchor = {x = x, y = y}
	LR_AccountStatistics_FP.SaveCommonData()
end

function LR_AccountStatistics_FP.UpdateAnchor()
	local frame = Station.Lookup("Normal/LR_AccountStatistics_FP")
	local x, y = LR_AccountStatistics_FP.UsrData.Anchor.x, LR_AccountStatistics_FP.UsrData.Anchor.y
	local nW, nH = Station.GetClientSize(true)
	if x < 0 then x = 0 end
	if x > nW - 100 then x = nW - 100 end
	if y < 0 then y = 0 end
	if y > nH - 20 then y = nH - 20 end
	if frame then
		this:SetRelPos(x, y)
		this:CorrectPos()
	end
end

function LR_AccountStatistics_FP.OnEvent(event)
	if event == "CUSTOM_DATA_LOADED" then
		if arg0 == "Role" then
			LR_AccountStatistics_FP.UpdateAnchor(this)
		end
	elseif event == "UI_SCALED" then
		LR_AccountStatistics_FP.UpdateAnchor(this)
	end
end

function LR_AccountStatistics_FP.OnFrameBreathe()
	----нч
end

function LR_AccountStatistics_FP.Refresh()
	local AllMoney=0
	local TempTable_Cal,TempTable_NotCal = LR_AS_Base.SeparateUsrList()
	for i=1,#TempTable_Cal,1 do
		AllMoney=AllMoney+TempTable_Cal[i].nMoney
	end
	LR_AccountStatistics_FP.ShowMoney(AllMoney)
end

function LR_AccountStatistics_FP.ShowMoney(nMoney)
	local frame = Station.Lookup("Normal/LR_AccountStatistics_FP")
	if not frame then
		return
	end
	local Handle_Total = frame:Lookup("","")
	local Handle_Money = Handle_Total:Lookup("Handle_Money")
	local Animate_Hover = Handle_Total:Lookup("Image_Hover")
	Animate_Hover:SetSize(0, 0)
	Animate_Hover:SetRelPos(0, 0)
	Handle_Money:SetHandleStyle(3)
	Handle_Money:Clear()
	Handle_Money:SetSize(500, 18)
	local AllMoney = nMoney
	local nGoldBrick,nGold,nSilver,nCopper =  LR.MoneyToGoldSilverAndCopper (AllMoney)
	local Text_GoldBrick,Text_Gold,Text_Silver,Text_Copper=nil,nil,nil,nil
	local _font = 207
	if AllMoney >= 100000000 then
		Text_GoldBrick=LR.AppendUI("Text", Handle_Money, "Text_GoldBrick_all" , {h = 30, text = nGoldBrick , font = _font})
		local Img_GoldBrick_all = LR.AppendUI("Animate", Handle_Money, "Img_GoldBrick_all" , {w = 24, h = 24, image="ui\\Image\\Common\\Money.UITex" , group=41 })
		Img_GoldBrick_all:SetLoopCount(-1)
		Text_Gold=LR.AppendUI("Text", Handle_Money, "Text_Gold_all" , {h = 30, text = nGold , font = _font})
		LR.AppendUI("Image", Handle_Money, "Img_Gold_all" , {w = 24, h = 24, image="ui\\Image\\Common\\Money.UITex" , frame=0  })
		Text_Silver=LR.AppendUI("Text", Handle_Money, "Text_Silver_all" , {h = 30, text = nSilver , font = _font})
		LR.AppendUI("Image", Handle_Money, "Img_Silver_all" , {w = 24, h = 24, image="ui\\Image\\Common\\Money.UITex" , frame=2  })
		Text_Copper=LR.AppendUI("Text", Handle_Money, "Text_Copper_all" , {h = 30, text = nCopper , font = _font})
		LR.AppendUI("Image", Handle_Money, "Img_Copper_all" , {w = 24, h = 24, image="ui\\Image\\Common\\Money.UITex" , frame=1  })
	elseif AllMoney>=10000 then
		Text_Gold=LR.AppendUI("Text", Handle_Money, "Text_Gold_all" , {h = 30, text = nGold , font = _font})
		LR.AppendUI("Image", Handle_Money, "Img_Gold_all" , {w = 24, h = 24, image="ui\\Image\\Common\\Money.UITex" , frame=0  })
		Text_Silver=LR.AppendUI("Text", Handle_Money, "Text_Silver_all" , {h = 30, text = nSilver , font = _font})
		LR.AppendUI("Image", Handle_Money, "Img_Silver_all" , {w = 24, h = 24, image="ui\\Image\\Common\\Money.UITex" , frame=2  })
		Text_Copper=LR.AppendUI("Text", Handle_Money, "Text_Copper_all" , {h = 30, text = nCopper , font = _font})
		LR.AppendUI("Image", Handle_Money, "Img_Copper_all" , {w = 24, h = 24, image="ui\\Image\\Common\\Money.UITex" , frame=1  })
	elseif AllMoney>=100 then
		Text_Silver=LR.AppendUI("Text", Handle_Money, "Text_Silver_all" , {h = 30, text = nSilver , font = _font})
		LR.AppendUI("Image", Handle_Money, "Img_Silver_all" , {w = 24, h = 24, image="ui\\Image\\Common\\Money.UITex" , frame=2  })
		Text_Copper=LR.AppendUI("Text", Handle_Money, "Text_Copper_all" , {h = 30, text = nCopper , font = _font})
		LR.AppendUI("Image", Handle_Money, "Img_Copper_all" , {w = 24, h = 24, image="ui\\Image\\Common\\Money.UITex" , frame=1  })
	else
		Text_Copper=LR.AppendUI("Text", Handle_Money, "Text_Copper_all" , {h = 30, text = nCopper , font = _font})
		LR.AppendUI("Image", Handle_Money, "Img_Copper_all" , {w = 24, h = 24, image="ui\\Image\\Common\\Money.UITex" , frame=1  })
	end

	Handle_Money:FormatAllItemPos()
	local w1, h1 = Handle_Money:GetAllItemSize()
	Handle_Money:SetSize(w1, h1)
	Handle_Money:SetRelPos(55, (30 - h1) / 2)

	Handle_Total:FormatAllItemPos()
	local w2, h2 = Handle_Total:GetAllItemSize()
	Animate_Hover:SetSize(w2, h2)
	Handle_Total:SetSize(w2, h2)
	frame:Lookup("",""):Lookup("Image_BG"):SetSize(w2, h2)
	frame:SetSize(w2, h2)
	frame:SetDragArea(0, 0, w2, h2)

	Handle_Money:RegisterEvent(786)
	Handle_Money.OnItemMouseEnter = function()
		Animate_Hover:Show()
	end
	Handle_Money.OnItemMouseLeave = function()
		Animate_Hover:Hide()
	end
end
------------------------------------------------------
function LR_AccountStatistics_FP.OpenPanel()
	if LR_AS_Base.UsrData.FloatPanel then
		local frame = Station.Lookup("Normal/LR_AccountStatistics_FP")
		if not frame then
			local path = sformat("%s\\UI\\LR_AccountStatistics_FP.ini", AddonPath)
			Wnd.OpenWindow(path, "LR_AccountStatistics_FP")
		end
	end
end

function LR_AccountStatistics_FP.ClosePanel()
	local frame = Station.Lookup("Normal/LR_AccountStatistics_FP")
	if frame then
		Wnd.CloseWindow(frame)
	end
end
-----------------------------------------------------
function LR_AccountStatistics_FP.LOGIN_GAME()
	LR_AccountStatistics_FP.LoadCommonData()
end

function LR_AccountStatistics_FP.FIRST_LOADING_END()
	LR_AccountStatistics_FP.OpenPanel()
end

function LR_AccountStatistics_FP.MONEY_UPDATE()
	LR_AS_Info.GetUserInfo()
	LR_AccountStatistics_FP.Refresh()
end

LR.RegisterEvent("LOGIN_GAME", function() LR_AccountStatistics_FP.LOGIN_GAME() end)
LR.RegisterEvent("FIRST_LOADING_END", function() LR_AccountStatistics_FP.FIRST_LOADING_END() end)
LR.RegisterEvent("LR_ACS_REFRESH_FP", function() LR_AccountStatistics_FP.Refresh() end)
LR.RegisterEvent("MONEY_UPDATE", function() LR_AccountStatistics_FP.MONEY_UPDATE() end)

