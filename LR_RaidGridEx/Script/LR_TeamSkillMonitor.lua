local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_RaidGridEx"
local SaveDataPath="Interface\\LR_Plugin\\@DATA\\LR_TeamGrid"
local _L = LR.LoadLangPack(AddonPath)
------------------------------------------------------
LR_TeamSkillMonitor = {
	SkillMonitorData = {},
}
local _hSkillBox={}	---´æ·ÅskillboxµÄhandle
------------------------------------------------------
-----¼¼ÄÜ¼à¿Ø
------------------------------------------------------
LR_TeamSkillMonitor.SKILL_LIST={
	[10080]={		----ÄÌÐã
		{dwID=569,enable=true,},	---ÍõÄ¸
		{dwID=555,enable=true,},		---·çÐä
		{dwID=548,enable=true,},		---Áú³ØÀÖ
		{dwID=557,enable=true,},		---ÌìµØµÍ°º
		{dwID=551,enable=true,},		---Õ½¸´
		{dwID=574,enable=false,},		---µûÅª×ã
		{dwID=552,enable=false,},		---ÁÚÀïÇú
		{dwID=550,enable=false,},		---ÈµÌ¤Ö¦
		{dwID=568,enable=true,},		---·±Òô¼±½Ú
		{dwID=9002,enable=true,},		---·öÒ¡
		{dwID=9003,enable=true,},		---ÄôÔÆ
	},
	[10028]={		----Àë¾­Ò×µÀ
		{dwID=132,enable=true,},		---´ºÄà
		{dwID=140,enable=true,},		---±ËÕë
		{dwID=2663,enable=true,},		---Ìý·ç´µÑ©
		{dwID=136,enable=true,},		---Ë®ÔÂÎÞ¼ä
		{dwID=143,enable=false,},		---´óÕë
		{dwID=141,enable=true,},		---ºÁÕë
		{dwID=14963,enable=false,},		---´óÕÐ
		{dwID=131,enable=true,},		---±ÌË®
		{dwID=228,enable=true,},		---Ì«ÒõÖ¸
		{dwID=9002,enable=true,},		---·öÒ¡
		{dwID=9003,enable=true,},		---ÄôÔÆ
	},
	[10176]={		----²¹Ìì
		{dwID=2231,enable=true,},		---¹Æ»ó
		{dwID=2957,enable=true,},		---Ê¥ÊÖ
		{dwID=15132,enable=true,},		---´óÕÐ
		{dwID=2234,enable=true,},		---¶¦
		{dwID=2235,enable=true,},		---Ç§µû
		{dwID=2230,enable=true,},		---Å®æ´
		{dwID=2226,enable=true,},		---Ï×¼À
		{dwID=9002,enable=true,},		---·öÒ¡
		{dwID=9003,enable=true,},		---ÄôÔÆ
	},
	[10448]={		-----ÏàÖª
		{dwID=14082,enable=true,},		---Ó°×Ó
		{dwID=14075,enable=true,},		---Æ½ÉËº¦¶Ü
		{dwID=14076,enable=true,},		---¸¡¿Õ
		{dwID=14084,enable=true,},		---Õ½¸´
		{dwID=15068,enable=false,},		---Íµbuff
		{dwID=9002,enable=true,},		---·öÒ¡
		{dwID=9003,enable=true,},		---ÄôÔÆ
	},
}


local DefaultSkillMonitorList={
	[10080]={		----ÄÌÐã
		{dwID=569,enable=true,},	---ÍõÄ¸
		{dwID=555,enable=true,},		---·çÐä
		{dwID=548,enable=true,},		---Áú³ØÀÖ
		{dwID=557,enable=true,},		---ÌìµØµÍ°º
		{dwID=551,enable=true,},		---Õ½¸´
		{dwID=9002,enable=true,},		---·öÒ¡
		{dwID=9003,enable=true,},		---ÄôÔÆ
	},
	[10028]={		----Àë¾­Ò×µÀ
		{dwID=132,enable=true,},		---´ºÄà
		{dwID=140,enable=true,},		---±ËÕë
		{dwID=2663,enable=true,},		---Ìý·ç´µÑ©
		{dwID=131,enable=true,},		---±ÌË®
		{dwID=9002,enable=true,},		---·öÒ¡
		{dwID=9003,enable=true,},		---ÄôÔÆ
	},
	[10176]={		----²¹Ìì
		{dwID=2231,enable=true,},		---¹Æ»ó
		{dwID=2957,enable=true,},		---Ê¥ÊÖ
		{dwID=15132,enable=true,},		---´óÕÐ
		{dwID=2234,enable=true,},		---¶¦
		{dwID=2235,enable=true,},		---Ç§µû
		{dwID=2230,enable=true,},		---Å®æ´
		{dwID=2226,enable=true,},		---Ï×¼À
		{dwID=9002,enable=true,},		---·öÒ¡
		{dwID=9003,enable=true,},		---ÄôÔÆ
	},
	[10448]={		-----ÏàÖª
		{dwID=14082,enable=true,},		---Ó°×Ó
		{dwID=14075,enable=true,},		---Æ½ÉËº¦¶Ü
		{dwID=14076,enable=true,},		---¸¡¿Õ
		{dwID=14084,enable=true,},		---Õ½¸´
		{dwID=9002,enable=true,},		---·öÒ¡
		{dwID=9003,enable=true,},		---ÄôÔÆ
	},
}

local DefaultSkillMonitorData={
	Version = "20161204",
	data = clone(DefaultSkillMonitorList),
}

-----------------------------------------------
----×ÔÉí¼¼ÄÜCD¼à¿Ø
------------------------------------------------
local _SkillBox={
	handle=nil,
	dwID=nil,
	nLevel=0,
	nEndFrame=0,
	nTotalFrame=0,
	nTime=0,
	nOrder=1,
}
_SkillBox.__index = _SkillBox

function _SkillBox:new(dwID)
	local o={}
	setmetatable(o,self)
	o.dwID = dwID
	o.parentHandle = LR_TeamGrid.Handle_Skill_Box
	return o
end

function _SkillBox:Create()
	local parentHandle = self.parentHandle
	local dwID = self.dwID
	local Handle_Skill_Box = parentHandle:Lookup(sformat("Handle_Skill_Box_%d", dwID))
	if not Handle_Skill_Box then
		local szIniFile = sformat("%s\\UI\\%s\\SkillBox.ini", AddonPath, LR_TeamGrid.UsrData.UI_Choose)
		Handle_Skill_Box=parentHandle:AppendItemFromIni(szIniFile, "Handle_Skill_Box", sformat("Handle_Skill_Box_%d", dwID))
	end
	self.handle=Handle_Skill_Box
	self:SetSkillLevel()
	self:SetEndFrameTime()
	self:SetSkillIcon()
	self:SetTimeText()

	Handle_Skill_Box:RegisterEvent(4194303)
	Handle_Skill_Box.OnItemMouseEnter = function()
		local szName=LR.Trim(Table_GetSkillName(dwID,1))
		local nX,nY=this:GetAbsPos()
		local nW,nH=this:GetSize()
		local szText = {}
		szText[#szText+1] = GetFormatText(sformat("%s\n", szName), 224)
		szText[#szText+1] = GetFormatText(sformat("dwID:%d\n", dwID), 224)
		--OutputTip(tconcat(szText), 360, {nX, nY, nW, nH})
		OutputSkillTip(dwID, GetClientPlayer().GetSkillLevel(dwID), {nX, nY, nW, nH})
	end
	Handle_Skill_Box.OnItemMouseLeave = function()
		HideTip()
	end
	return self
end

function _SkillBox:SetRelPos()
	local handle = self.handle
	local nOrder =self.nOrder
	if LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 3 or LR_TeamGrid.UsrData.CommonSettings.skillBoxPos == 4 then
		handle:SetRelPos(0, (nOrder - 1) * 41)
	else
		handle:SetRelPos((nOrder - 1) * 41, 0)
	end
end

function _SkillBox:SetOrder(nOrder)
	self.nOrder = nOrder
	return self
end

function _SkillBox:SetTimeText()
	local Text_Skill_Remain_Time=self.handle:Lookup("Text_Skill_Remain_Time")
	local nTotalFrame=self.nTotalFrame
	local nEndFrame=self.nEndFrame
	local nowFrame=GetLogicFrameCount()
	local nLeftFrame=nEndFrame-nowFrame
	if nLeftFrame >0 then
		local ntime=mfloor(nLeftFrame / 16)
		Text_Skill_Remain_Time:SetText(ntime)
	else
		Text_Skill_Remain_Time:SetText("")
	end
	return self
end

function _SkillBox:SetSkillIcon()
	local dwID=self.dwID
	local nLevel=self.nLevel
	local nIcon=Table_GetSkillIconID(dwID,nLevel)
	local Box_Skill=self.handle:Lookup("Box_Skill")
	Box_Skill:SetObject(UI_OBJECT_NOT_NEED_KNOWN, 0)
	Box_Skill:SetObjectIcon(nIcon)
end

function _SkillBox:SetSkillID(dwID)
	self.dwID=dwID
	return self
end

function _SkillBox:GetTimeLeft()
	local text="4"
	local Text_Skill_Remain_Time=self.handle:Lookup("Text_Skill_Remain_Time")
	Text_Skill_Remain_Time:SetText(text)

	return self
end

function _SkillBox:GetSkillLevel()
	return self.nLevel
end

function _SkillBox:SetSkillLevel(nLevel)
	if nLevel then
		self.nLevel=nLevel
	else
		local me = GetClientPlayer()
		local dwID=self.dwID
		if me then
			self.nLevel=me.GetSkillLevel(dwID)
		else
			self.nLevel=0
		end
	end
	return self
end

function _SkillBox:SetEndFrameTime()
	local dwID=self.dwID
	local nLevel=self.nLevel
	local me = GetClientPlayer()
	if me then
		local isCDing,nLeftFrame,nTotalFrame,nNum,_=me.GetSkillCDProgress(dwID,nLevel)
		local nowFrame=GetLogicFrameCount()
		self.nEndFrame=nowFrame+nLeftFrame
		self.nTotalFrame=nTotalFrame
	else
		self.nEndFrame=0
		self.nTotalFrame=0
	end
end

function _SkillBox:SetCoolDownPercentage()
	local nEndFrame=self.nEndFrame
	local nowFrame=GetLogicFrameCount()
	local nTotalFrame=self.nTotalFrame
	local nLeftFrame=nEndFrame-nowFrame
	local Box_Skill=self.handle:Lookup("Box_Skill")
	if self.nLevel > 0 then
		if nLeftFrame > 0 and nTotalFrame > 0 then
			Box_Skill:SetObjectCoolDown(true)
			Box_Skill:SetCoolDownPercentage(1-nLeftFrame/nTotalFrame)
			if nLeftFrame <5 then
				Box_Skill:SetObjectSparking(true)
			end
		else
			Box_Skill:SetObjectCoolDown(false)
			Box_Skill:SetCoolDownPercentage(1)
		end
	else
		Box_Skill:SetObjectCoolDown(true)
		Box_Skill:SetCoolDownPercentage(0)
	end
	return self
end

function _SkillBox:GetnTime()
	return self.nTime
end

function _SkillBox:SetnTime(nTime)
	self.nTime = nTime
	return self
end

-----------------------------------------------------------------
function LR_TeamSkillMonitor.SaveCommonData()
	local path = sformat("%s\\UsrData\\CommonSkillMonitor.dat", SaveDataPath)
	local data = LR_TeamSkillMonitor.SkillMonitorData or {}
	SaveLUAData(path, data)
end

function LR_TeamSkillMonitor.CheckCommonData()
	local path = sformat("%s\\UsrData\\CommonSkillMonitor.dat", SaveDataPath)
	local data = LoadLUAData(path) or {}
	if data.Version and data.Version == DefaultSkillMonitorData.Version then
		return
	end
	LR_TeamSkillMonitor.SkillMonitorData = clone(DefaultSkillMonitorData)
	LR_TeamSkillMonitor.SaveCommonData()
end

function LR_TeamSkillMonitor.LoadCommonData()
	LR_TeamSkillMonitor.CheckCommonData()
	local path = sformat("%s\\UsrData\\CommonSkillMonitor.dat", SaveDataPath)
	local data = LoadLUAData(path) or {}
	LR_TeamSkillMonitor.SkillMonitorData = clone(data)
end

function LR_TeamSkillMonitor.ResetCommonData()
	local path = sformat("%s\\UsrData\\CommonSkillMonitor.dat", SaveDataPath)
	local data = clone(DefaultSkillMonitorData)
	SaveLUAData(path, data)
	LR_TeamSkillMonitor.SkillMonitorData = clone(data)
end

------------------------------------------------------------------
function LR_TeamSkillMonitor.ShowSkillPanel()
	local frame=Station.Lookup("Normal/LR_TeamGrid")
	if not frame then
		return
	end
	LR_TeamGrid.Handle_Skill_Box:Clear()
	LR_TeamGrid.Handle_Skill_Box:GetParent():SetRelPos(-40, 30)
	_hSkillBox = {}
	if not LR_TeamGrid.UsrData.CommonSettings.bShowSkillBox then
		LR_TeamGrid.UpdateRoleBodySize()
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local kungfu=me.GetKungfuMount()
	local dwSkillID=kungfu.dwSkillID
	if dwSkillID==10028 or dwSkillID==10080 or dwSkillID==10176 or dwSkillID==10448  then
		local data=LR_TeamSkillMonitor.SkillMonitorData.data[dwSkillID] or {}
		local n=1
		for i=1,#data,1 do
			if data[i].enable then
				local dwID = data[i].dwID
				local szName=LR.Trim(Table_GetSkillName(dwID,1))
				local h = _SkillBox:new(dwID)
				h:Create():SetOrder(n):SetRelPos()
				_hSkillBox[szName] = h
				n=n+1
			end
		end
		LR_TeamGrid.Handle_Skill_Box:FormatAllItemPos()
		LR_TeamGrid.Handle_Skill_Box:SetSizeByAllItemSize()
		local width, height = LR_TeamGrid.Handle_Skill_Box:GetSize()
		LR_TeamGrid.Handle_Skill_Box:GetParent():SetSize(width, height)
		LR_TeamGrid.ReDrawAllMembers()
	end
	LR_TeamGrid.UpdateRoleBodySize()
end

function LR_TeamSkillMonitor.RefreshAllSkillBox()
	-----×ÔÉí¼¼ÄÜCD¼à¿Ø
	if LR_TeamGrid.UsrData.CommonSettings.bShowSkillBox then
		for szName,v in pairs (_hSkillBox) do
			if _hSkillBox[szName] then
				_hSkillBox[szName]:SetTimeText()
				_hSkillBox[szName]:SetCoolDownPercentage()
			end
		end
	end
end

function LR_TeamSkillMonitor.GetSkillMonitorOrder(dwForceID,dwID)
	for i=1,#LR_TeamSkillMonitor.SkillMonitorData.data[dwForceID],1 do
		if LR_TeamSkillMonitor.SkillMonitorData.data[dwForceID][i].dwID == dwID then
			return i
		end
	end
	return 0
end

----------------------------------------------------------------------

function LR_TeamSkillMonitor.LOGIN_GAME()
	LR_TeamSkillMonitor.LoadCommonData()
	Log("[LR] : Loaded LR_TeamSkillMonitor.CommonData")
end

function LR_TeamSkillMonitor.SKILL_MOUNT_KUNG_FU()
	LR.DelayCall(250,function()
		LR_TeamSkillMonitor.ShowSkillPanel()
	end)
end

function LR_TeamSkillMonitor.SKILL_UPDATE()
	local dwID=arg0
	local nLevel=arg1
	local szName=LR.Trim(Table_GetSkillName(dwID,nLevel))
	if _hSkillBox[szName] then
		_hSkillBox[szName]:SetSkillID(dwID)
		_hSkillBox[szName]:SetSkillLevel(nLevel)
	end
	LR.DelayCall(250,function() LR_TeamSkillMonitor.ReFreshAllSkillLevel() end)
end

function LR_TeamSkillMonitor.DO_SKILL_CAST()
	local dwCaster=arg0
	local dwSkillID=arg1
	local dwLevel=arg2
	local me = GetClientPlayer()
	if not me then
		return
	end
	if dwCaster == me.dwID then
		local szName=LR.Trim(Table_GetSkillName(dwSkillID,dwLevel))
		if _hSkillBox[szName] then
			if szName==_L["MiXian"] and dwSkillID ~=15132 then
				return
			end
			local nTime=GetTime()
			if nTime - _hSkillBox[szName]:GetnTime() > 500 then
				_hSkillBox[szName]:SetnTime(nTime):SetSkillID(dwSkillID):SetSkillLevel(dwLevel):SetEndFrameTime()
			end
		end
	end
end

function LR_TeamSkillMonitor.ReFreshAllSkillLevel()
	local me = GetClientPlayer()
	if not me then
		return
	end
	for szName,v in pairs (_hSkillBox) do
		if _hSkillBox[szName] then
			_hSkillBox[szName]:SetSkillLevel()
		end
	end
end

LR.RegisterEvent("LOGIN_GAME",function() LR_TeamSkillMonitor.LOGIN_GAME() end)

