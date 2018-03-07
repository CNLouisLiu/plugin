local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
-------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_NianShou"
local _L = LR.LoadLangPack(AddonPath)
--------------------------------------------------

LR_NianShou=LR_NianShou or {
	nScore=0,
	bOn=false,
	bPickorRollWhenOff = false,
	bDebug = false,
	doodadID = 0,
	tDoodadList={},
	tNPCList={},
	tRollList={},
	tPickedList={},
	tSelfOpenDoodad = {},
}

function LR_NianShou.LoadDefault()
	local _, _, szLang = GetVersion()
	local path = sformat("%s\\Script\\Default.%s", AddonPath, szLang)
	local data = LoadLUAData(path) or {}
	if LR_PickupDead then
		LR_PickupDead.customData.ignorList = {}
		local ignorList = {}
		for k, v in pairs(data) do
			ignorList[#ignorList + 1] = {szName = k, bnotPickup = v}
		end
		tsort(ignorList, function(a, b) return a.szName < b.szName end)
		LR_PickupDead.customData.ignorList = clone(ignorList)
	end
	return data
end

LR_NianShou.Default = {
	nUseXiaoJinChui = 320,	--用小金锤的分数
	nUseZJ = 1280,		-- 开始吃醉生、寄优谷的分数
	bPauseNoZJ = true,	-- 缺少醉生、寄优时停砸
	nPausePoint = 327680,	-- 停砸分数线
	nUseJX = 80,				-- 自动用掉锦囊、香囊
	bNonZS = false,	-- 不使用醉生
	bUseGold = false,	-- 没银锤时使用金锤
	bUseTaoguan = true,	-- 必要时自动使用背包的陶罐
	loot_notinlist=true,	---不在列表的也拾取
	tFilterItem =LR_NianShou.LoadDefault() ,
}

LR_NianShou.UsrData = clone(LR_NianShou.Default)

local CustomDataVersion = "20170131"
RegisterCustomData("LR_NianShou.UsrData", CustomDataVersion)

local ROLL_ITEM_CHOICE={
	NEED=2,
	GREED=1,
	CANCEL=0,
}

function LR_NianShou.OnFrameCreate()
	-------------
end

function LR_NianShou.OnEvent(event)
	-------------
end

function LR_NianShou.OnFrameBreathe()
	LR_NianShou.frame_CloseMessageBox()
	if GetLogicFrameCount() % 4 ~= 0 then
		return
	end
	if not LR_NianShou.bOn then
		return
	end

	local me =  GetClientPlayer()
	if not me then
		return
	end
	local bufflist=LR.GetBuffList(me)

	-------------使用醉生、寄忧谷
	if LR_NianShou.nScore < LR_NianShou.UsrData.nUseZJ then
		-----------使用香囊、锦囊
		if LR_NianShou.nScore < LR_NianShou.UsrData.nUseJX then
			--------什么都不做，用锤子砸
		else
			if LR.HasBuff (bufflist, _L["XingYunJinNang"]) and LR.HasBuff (bufflist, _L["XingYunXiangNang"]) then
				---------什么都不做，用锤子砸
			elseif not LR.HasBuff (bufflist, _L["XingYunJinNang"]) then
				LR_NianShou.UseBagItem (_L["XingYunJinNang"],true)
				return
			elseif not LR.HasBuff (bufflist, _L["XingYunXiangNang"]) then
				LR_NianShou.UseBagItem(_L["XingYunXiangNang"],true)
				return
			end
		end
	else
		if LR.HasBuff (bufflist,_L["JiYouGu"]) and LR.HasBuff (bufflist,_L["ZuiSheng"]) then

		elseif not LR.HasBuff (bufflist,_L["JiYouGu"]) then
			LR_NianShou.UseBagItem (_L["JiYouGu"],true)
			return
		elseif not LR.HasBuff (bufflist,_L["ZuiSheng"]) and not LR_NianShou.UsrData.bNonZS then
			LR_NianShou.UseBagItem (_L["ZuiSheng"],true)
			return
		end
	end

	local _type,_dwID=me.GetTarget()
	if _type==TARGET.NPC then
		local npc=GetNpc(_dwID)
		if npc and (LR.Trim(npc.szName) == _L["NianShouTaoGuan"] or  LR.Trim(Table_GetNpcTemplateName(npc.dwTemplateID)) == _L["NianShouTaoGuan"])  then
			if LR_NianShou.nScore >= LR_NianShou.UsrData.nUseXiaoJinChui then
				LR_NianShou.UseBagItem (_L["XiaoJinChui"],true)
			else
				LR_NianShou.UseBagItem (_L["XiaoYinChui"],true)
			end
		end
	end
	LR_NianShou.UseBagItem(_L["HuoShuYinHua"])
	LR_NianShou.UseBagItem(_L["BianPao"])
	LR_NianShou.UseBagItem(_L["YanHuoBang"])
	LR_NianShou.UseBagItem(_L["LongFengChengXiang"])
	LR_NianShou.UseBagItem(_L["ChuanTianHou"])
end

function LR_NianShou.UseBagItem(szName,bStop)
	if not LR_NianShou.bOn then
		return
	end
	local player = GetClientPlayer()
	if not player then
		return
	end
	for i = 1, 6 do
		for j = 0, player.GetBoxSize(i) - 1 do
			local item = GetPlayerItem(player, i, j)
			if item and LR.Trim(item.szName) == szName then
				local bCool, nLeft, nTotal, bBroken =  player.GetItemCDProgress( i,j)
				if nLeft==0 and nTotal==0 then
					--LR.SysMsg( "正在使用"..str ..".\n")
					OnUseItem(i,j)
				end
				return
			end
		end
	end

	if bStop then
		LR.SysMsg(sformat(_L["Lack of %s, stop\n"], szName))
		LR_NianShou.Open(sformat(_L["Lack of %s, stop\n"], szName))
		PlaySound(SOUND.UI_SOUND, AddonPath .. "\\Script\\stop.mp3")
	end
end

-----------------------------------------
---开启关闭年兽陶罐
-----------------------------------------
function LR_NianShou.Open(message)
	local frame=Station.Lookup("Lowest/LR_NianShou")
	if frame then
		Wnd.CloseWindow(frame)
		LR_NianShou.bOn = false

		local szText = {}
		szText[#szText+1] = GetFormatText(_L["Stop taoguan\n"], 2, 255, 255, 255)
		szText[#szText+1] = GetFormatText(sformat(_L["Score: %d\n"], LR_NianShou.nScore), 162, 255, 0, 0)
		--szText[#szText+1] = sformat("<Text>text=%s font=2 r=255 g=255 b=255</text>", EncodeComponentsString(_L["Stop taoguan\n"]))
		--szText[#szText+1] = sformat("<Text>text=%s font=162 r=255 g=0 b=0</text>", EncodeComponentsString(sformat(_L["Score: %d"], LR_NianShou.nScore)) .. "\n")
		if message then
			szText[#szText+1] = GetFormatText(message, 2)
		end
		local msg =
		{
			szMessage = tconcat(szText),
			bRichText = true,
			szName = "LoadDefaultSettings",
			{szOption = g_tStrings.STR_HOTKEY_SURE,
				fnAction = function()
					if LR_NianShou.nScore >= LR_NianShou.UsrData.nPausePoint then
						LR_NianShou.nScore = 0
					end
				end
			},
			{szOption = g_tStrings.STR_HOTKEY_CANCEL},
		}
		MessageBox(msg)
		LR.SysMsg(_L["Stop LR_NianShou"])
	else
		Wnd.OpenWindow(AddonPath.."\\UI\\LR_NianShouTaoGuanNone.ini", "LR_NianShou")
		LR_NianShou.bOn = true
		LR_NianShou.LastTime = GetLogicFrameCount()
		LR.SysMsg(_L["Start LR_NianShou"])
	end
end

-----------------------------------------
---获取分数
-----------------------------------------
function LR_NianShou.GetScore(szMsg)
	if not LR_NianShou.bOn then
		return
	end
	local _, _, score = string.find(szMsg, _L["Now total score:(%d+)"])
	if score then
		LR_NianShou.nScore = tonumber(score)
		if LR_NianShou.nScore >= LR_NianShou.UsrData.nPausePoint then
			LR.SysMsg(_L["Stop line, stop\n"])
			LR_NianShou.Open(_L["Stop line, stop\n"])
			PlaySound(SOUND.UI_SOUND, AddonPath.."\\Script\\stop.mp3")
		end
	end
end
RegisterMsgMonitor(LR_NianShou.GetScore, {"MSG_SYS"})

-----------------------------------------
---关闭拾取确认框
-----------------------------------------
function LR_NianShou.frame_CloseMessageBox(szName)
	local frame = Station.Lookup("Topmost/MB_PlayerMessageBoxCommon")
	if frame then
		local btn = frame:Lookup("Wnd_All/Btn_Option1")
		if btn and btn:IsEnabled() then
			btn.fnAction(1)
			CloseMessageBox("PlayerMessageBoxCommon")
		end
	end
end
