local AddonPath="Interface\\LR_Plugin\\LR_CopyBook"
local _L = LR.LoadLangPack(AddonPath)
local sformat, slen, sgsub, ssub,sfind = string.format, string.len, string.gsub, string.sub, string.find
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil = math.floor, math.ceil
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
-------------------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass ("Normal") then
	tinsert (LR_TOOLS.tAddonClass,{"Normal",_L["Plugins"],"1"})
end

local LR_CopyBook_UI ={
	szName="LR_CopyBook_UI",
	szTitle=_L["LR Printing Machine"],
	dwIcon = 3731,
	szClass = "Normal",
	tWidget = {
		{
			name="LR_CopyBook_UI_te01",type="Text",x=0,y=0,w=80,h=28,text=_L["Suitbook Name"],font=99,
		},{
			name="LR_CopyBook_UI_an9",type="Button",x=120,y=0,text=_L["Source of books/Book Records"]  ,w=200,
			callback = function()
				if LR_BookRd_Panel then
					LR_BookRd_Panel:Open()
				else
					LR.SysMsg(sformat("%s\n", _L["Please install [LR_AccountStatistics Plugin]"]))
				end
			end
		},{
			name="LR_CopyBook_UI_edit1",type="Edit",x=0,y=30,w=200,
			default= function()
				LR_CopyBook.TempName=LR_CopyBook.UsrData.szName
				return LR_CopyBook.UsrData.szName
			end,
			callback = function(value)
				if IsPopupMenuOpened() then
					Wnd.CloseWindow(GetPopupMenu())
				end
				local szName
				szName=sgsub(value," ","")
				LR_CopyBook.TempName=szName
				local menu={}
				local RowCount= g_tTable.BookSegment:GetRowCount()
				local i=2
				local editbox=this
				while i<=RowCount do
					local t=g_tTable.BookSegment:GetRow(i)
					local _start,_end=sfind(t.szBookName,szName)
					if _start then
						if #menu <=15 then
							tinsert(menu,{
								szOption=t.szBookName,
								fnAction = function()
									editbox:SetText(t.szBookName)
									if LR_CopyBook.GetSuitBookID (LR_CopyBook.TempName) then
										LR_CopyBook.UsrData.szName=LR_CopyBook.TempName
										LR_CopyBook.CreateBookTable()
										LR_CopyBook.CountNeeds()
										LR_CopyBook_MiniPanel:LoadSuitBooks()
									else
										LR.SysMsg(sformat("%s %s\n", LR_CopyBook.TempName, _L["No this Suitbook"]))
									end
								end,
							})
						end
					end
					i=i+t.dwBookNumber
				end
				local menu1 = {{
					szOption = _L["LR Printing Machine"],
					fnAction = function()
						LR_CopyBook_MiniPanel:Open()
					end,
					bCheck=true,
					bMCheck=false,
					rgb = {255, 255, 255},
					bChecked = function()
						local Frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
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
						LR_TOOLS:OpenPanel(_L["LR Printing Machine"])
					end,
					rgb = {255, 255, 255},
					fnAutoClose=true,
				}}
				local nX, nY = this:GetAbsPos()
				local nW, nH = this:GetSize()
				menu.nMiniWidth = 200
				menu.x = nX
				menu.y = nY + nH
				menu.bShowKillFocus = true
				menu.bDisableSound = true
				PopupMenu(menu)
			end,
		},{
			name="LR_CopyBook_UI_an1",type="Button",x=210,y=30,text=_L["OK"],
			callback = function()
				local player=GetClientPlayer()
-- 				if LR_CopyBook.TempName==LR_CopyBook.UsrData.szName then
-- 					LR_CopyBook.CountNeeds()
-- 					return
-- 				else
					if LR_CopyBook.GetSuitBookID (LR_CopyBook.TempName) then
						LR_CopyBook.UsrData.szName=LR_CopyBook.TempName
						LR_CopyBook.CreateBookTable()
						LR_CopyBook.CountNeeds()
						LR_CopyBook_MiniPanel:LoadSuitBooks()
					else
						LR.SysMsg(sformat("%s %s\n", LR_CopyBook.TempName, _L["No this Suitbook"]))
					end
				--end

			end
		},{
			name="LR_CopyBook_UI_ComboBox1",type="ComboBox",x=0,y=70,w=300,text=_L["Choose book(s) which to print"],
			callback = function(m)
				local me = GetClientPlayer()
				if not me then
					return
				end
				local bookList = LR_CopyBook.UsrData.bookList or {}
				for k, v in pairs (bookList) do
					local name = {}
					local szName = LR.Table_GetSegmentName(v.dwBookID, v.dwSegmentID)
					name[#name+1] = sformat("%d. %s", k, szName)
					local num = LR_CopyBook.GetBookNum(v.dwBookID, k)
					name[#name+1] = sformat("[%d]", num)
					local dwIndex = LR.Table_GetBookItemIndex(v.dwBookID, v.dwSegmentID)
					local itemInfo = GetItemInfo(5, dwIndex)
					if me.IsBookMemorized(v.dwBookID, k) then
						if itemInfo.nBindType == 3 then
							name[#name+1] = _L["(Bind after printing)"]
						end
						m[#m+1] = {szOption=tconcat(name), bCheck=true, bChecked = function() return LR_CopyBook.UsrData.bookList[k].bCopy end,
						fnAction=function()
							LR_CopyBook.UsrData.bookList[k].bCopy = not LR_CopyBook.UsrData.bookList[k].bCopy
							LR_CopyBook_MiniPanel:ChangeCheck(v.dwBookID, v.dwSegmentID)
							LR_CopyBook.CountNeeds()
						end }
					else
						name[#name+1] = _L["(Never Read)"]
						if itemInfo.nBindType == 3 then
							name[#name+1] = _L["(Bind after printing)"]
						end
						m[#m+1] = {szOption=tconcat(name), bCheck=false, bChecked=false, nFont=108}
					end
				end
				PopupMenu(m)
			end,
		},{
			name="LR_CopyBook_UI_te02",type="Text",x=0,y=105,w=80,h=28,text=_L["Continuous print"],font=5,
		},{
			name="LR_CopyBook_UI_CopyBookNeeds",type="Text",x=330,y=70,w=200,h=100,IsRichText=true,AutoSize=true,IsMultiLine=true,text=LR_CopyBook.UsrData.NeedText,font=27,
		},{
			name="CopyBookLimitNum",type="CSlider",min=1,max=500,x=0,y=125,w=270,step=499,unit=_L["unit"],
			enable = function ()
				return true
			end,
			default = function ()
				return LR_CopyBook.UsrData.CopyLimitNum
			end,
			callback = function (value)
				LR_CopyBook.UsrData.CopyLimitNum=value
				LR_CopyBook.CountNeeds()
				LR_CopyBook_MiniPanel:DrawNeed()
				--LR_TOOLS:Fetch("edit_CopyBookNum"):SetText(value)
			end
		},{
			name="edit_CopyBookNum",type="Edit",x=95,y=103,w=90,
			default= function()
				return _L["Enter num"]
			end,
			callback = function(value)
				local x = tonumber(value)
				if type(x)== "number" then
					if x>500 then
						x = 500
						this:SetText("500")
					end
					LR_CopyBook.UsrData.CopyLimitNum = x
					LR_TOOLS:Fetch("CopyBookLimitNum"):UpdateScrollPos(x)
					LR_CopyBook.CountNeeds()
				end
			end
		},{
			name="LR_CopyBook_UI_an3",type="Button",x=110,y=160,text=_L["Begin Printing"],
			callback = function()
				if  LR_CopyBook.on then
					return
				end
				LR_CopyBook.on=true
				Wnd.OpenWindow("interface\\LR_Plugin\\LR_CopyBook\\UI\\EmptyUI.ini","LR_CopyBook")
				LR_CopyBook.RemainNum=LR_CopyBook.UsrData.CopyLimitNum
				if LR_CopyBook.OTAFlag==0 then
					LR_CopyBook.LastTime=GetLogicFrameCount()-4
				end
			end
		},{
			name="LR_CopyBook_UI_an4",type="Button",x=210,y=160,text=_L["Stop Printing!"],
			callback = function()
				LR_CopyBook.StopCopy()
			end
		},{
			name="LR_CopyBook_UI_an5",type="Button",x=150,y=200,text=_L["Open mini panel"] , w=140,h=30,font=177,
			callback = function()
				LR_CopyBook_MiniPanel:Open()
			end
		},{
			name="LR_CopyBook_UI_check_box",type="CheckBox",text=_L["Stop Printing immediately when close Setting Panel or Mini Panel or press ESC."],x=0,y=240,w=200,
			default = function ()
				return LR_CopyBook.UsrData.KillOTA
			end,
			callback = function (enabled)
				LR_CopyBook.UsrData.KillOTA=enabled
			end
		},{
			name="LR_CopyBook_UI_tips1",type="TipBox",x=0,y=280,w=150,h=28,text=_L["Tips & FAQ"],
			callback= function ()
				local x, y=this:GetAbsPos()
				local w, h = this:GetSize()
				local szXml = {}
				szXml[#szXml+1] = GetFormatText(_L["1.Suggest to copy [ShiSanGunSenJiuTangWang]\n"],136,255,128,0)
				szXml[#szXml+1] = GetFormatText(_L["2.The book which will bind after printing can not trade to others.\n"],136,255,128,0)
				OutputTip(tconcat(szXml),420,{x,y,w,h})
			end
		},
	}
}
LR_TOOLS:RegisterPanel(LR_CopyBook_UI)
-----------------------------------
----×¢²áÍ·Ïñ¡¢°âÊÖ²Ëµ¥
-----------------------------------
LR_TOOLS.menu=LR_TOOLS.menu or {}
LR_CopyBook_UI.menu = {
	szOption =_L["LR Printing Machine"],
	fnAction = function()
		LR_CopyBook_MiniPanel:Open()
	end,
	bCheck=true,
	bMCheck=false,
	rgb = {255, 255, 255},
	bChecked = function()
		local Frame = Station.Lookup("Normal/LR_CopyBook_MiniPanel")
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
		LR_TOOLS:OpenPanel(_L["LR Printing Machine"])
	end,
	rgb = {255, 255, 255},
	fnAutoClose=true,
}
tinsert(LR_TOOLS.menu,LR_CopyBook_UI.menu)

-----------------------------
---¿ì½Ý¼ü
-----------------------------
LR.AddHotKey(_L["Mini Printing Machine"], 	function() LR_CopyBook_MiniPanel:Open() end)
