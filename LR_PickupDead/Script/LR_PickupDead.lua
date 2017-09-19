local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_PickupDead"
local SaveDataPath = "Interface\\LR_Plugin\\@DATA\\LR_PickupDead"
local _L=LR.LoadLangPack(AddonPath)
---------------------------------------------------------------
local VERSION = "20170912"
---------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
----�Զ�ʰȡDoodad
-------------------------------------------------------------------------------------------------------------
-----SYNC_LOOT_LIST��DOODAD_ENTER_SCENE֮��
-----SYNC_LOOT_LIST:���п�ʰȡ��DOODAD���ֺ�ᴥ����������Ʒ���ᴥ��
-----��������ʹ��SYNC_LOOT_LIST
-----���裺
-----SYNC_LOOT_LIST��doodad����doodadList
-----breathe�򿪸�����DOODAD������OPEN_DOODAD(���˴򿪣��������Ѵ򿪶���������ֻ���Լ��򿪻ᴥ��)
-----����OPEN_DOODAD�󣬽���ʰȡ
-----��Щ��Ʒ�������˷������ٴ�DOODAD���ͻ�ֱ�ӷŽ�����������Roll���ڴ�֮��


local PICKUP_MIN_TIME = 3
local PICKUP_MAX_DISTANCE = 6
local ROLL_ITEM_CHOICE = {
	NEED = 2,
	GREED = 1,
	CANCEL = 0,
}

LR_PickupDead = {}
LR_PickupDead.doodadList = {}
LR_PickupDead.pickedUpList = {}
LR_PickupDead.rolledItemList = {}
LR_PickupDead.rollItemList = {}
LR_PickupDead.lastPickupTime = 0
LR_PickupDead.customData = {
	ignorList = {},
	pickList = {},
}
LR_PickupDead.UsrData = {
	pickUpLevel = 1,	--ʰȡ��ɫ������
	bOn = false,
	bPickupTaskItem = true,
	bPickupUnReadBook = true,
	bPickupOnlyOneBindBook = true,
	bPickupOnlyOneNotBindBook = true,
	bPickupItems = false,		---����������
	bnotPickupItems = false,		--����������
	bOnlyPickupItems = false,		---ֻʰȡ������
	bGiveUpItemsBTLON = true,  --Give up items beyond the limit of number �����������޵���Ʒ
}
RegisterCustomData("LR_PickupDead.UsrData", VERSION)

function LR_PickupDead.SaveCustomData()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local path = sformat("%s\\UsrData\\CustomData.dat", SaveDataPath)
	local data = clone(LR_PickupDead.customData)
	SaveLUAData (path,data)
end

function LR_PickupDead.LoadCustomData()
	local path = sformat("%s\\UsrData\\CustomData.dat", SaveDataPath)
	local data = LoadLUAData(path) or {ignorList = {},pickList = {},}
	LR_PickupDead.customData = clone(data)
end

------------------------------------------------------------------
function LR_PickupDead.CloseLootListPanel()
	local hL = Station.Lookup("Normal/LootList", "Handle_LootList")
	if hL then
		hL:Clear()
	end
end

--------------------------------------------------------------
---�¼�����
--------------------------------------------------------------
local CRAFT_SUCCESS = false

function LR_PickupDead.SYNC_LOOT_LIST()
	local dwDoodadID = arg0
	local doodad = GetDoodad(dwDoodadID)
	if doodad then
		LR_PickupDead.doodadList[dwDoodadID] = {dwID = dwDoodadID, nX = doodad.nX, nY = doodad.nY, nZ = doodad.nZ,}
	end
end

function LR_PickupDead.DOODAD_LEAVE_SCENE()
	local dwID = arg0
	LR_PickupDead.doodadList[dwID] = nil
	LR_PickupDead.pickedUpList[dwID] = nil
end

function LR_PickupDead.OPEN_DOODAD()
	local dwDoodadID = arg0
	local dwPlayerID = arg1
	local me = GetClientPlayer()
	if not me then
		return
	end
	if dwPlayerID ~=  me.dwID then
		return
	end

	LR_PickupDead.PickItem(dwDoodadID)
end

function LR_PickupDead.PickItem(dwDoodadID)
	local dwDoodadID = dwDoodadID
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_PickupDead.UsrData.bOn then
		return
	end

	if LR_PickupDead.pickedUpList[dwDoodadID] and not CRAFT_SUCCESS then
		LR_PickupDead.doodadList[dwDoodadID] = nil
		return
	end
	CRAFT_SUCCESS = false

	local doodad =  GetDoodad (dwDoodadID)
	if not doodad then
		return
	end

	----���LIst
	LR_PickupDead.doodadList[dwDoodadID] = nil
	LR_PickupDead.pickedUpList[dwDoodadID] = true

	--ʰȡ��Ǯ
	local nMoney = doodad.GetLootMoney()
	if nMoney > 0 then
		LootMoney (doodad.dwID)
	end

	local num = doodad.GetItemListCount()
	for i = num - 1, 0, -1 do
		local item, bNeedRoll, bLeader ,bGoldTeam = doodad.GetLootItem(i, me)
		if item then
			if bNeedRoll then
				--Output("bNeedRoll")
			elseif bLeader then
				--Output("bLeader")
			else
				local pickFlag = false
				--[[���˹���(��˳��)��
				1���������еķ���
				2�����ֻʰȡ���������򲻹�Ʒ���Ĺ��ˣ��������Ʒ������
				3��������Ʒ�͹��˺���鼮����ֻʰȡ����������
				4�����ʰȡ�����Ʒ������������������򲻼�
				5��������Ʒ�ܺ������Ŀ���
				]]
				--������
				if LR_PickupDead.UsrData.bPickupItems then
					for k, v in pairs(LR_PickupDead.customData.pickList or {}) do
						if v.bPickup then
							if v.szName then
								if v.szName == LR.GetItemNameByItem(item) then
									pickFlag = true
								end
							elseif v.dwTabType then
								if v.dwTabType == item.dwTabType and v.dwIndex == item.dwIndex then
									pickFlag = true
								end
							elseif v.nUiId then
								if v.nUiId == item.nUiId then
									pickFlag = true
								end
							end
						end
					end
				end

				--���ڰ������е�
				if not (LR_PickupDead.UsrData.bPickupItems and LR_PickupDead.UsrData.bOnlyPickupItems) then
					if item.nQuality >=  LR_PickupDead.UsrData.pickUpLevel then
						pickFlag = true
					end
				end

				if item.nGenre == ITEM_GENRE.BOOK then
					if LR_PickupDead.UsrData.bPickupUnReadBook then	--ֻʰȡδ�Ķ������鼮
						local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
						if not me.IsBookMemorized(nBookID, nSegID) then
							pickFlag = true
						else
							pickFlag = false
						end
					end
					---ֻʰȡһ��
					if LR_PickupDead.UsrData.bPickupOnlyOneBindBook and item.bBind == true then
						if LR.GetItemNumInBag(item.dwTabType, item.dwIndex, item.nBookID) > 0 then
							pickFlag = false
						end
					end
					if LR_PickupDead.UsrData.bPickupOnlyOneNotBindBook and item.bBind == false then
						if LR.GetItemNumInBag(item.dwTabType, item.dwIndex, item.nBookID) > 0 then
							pickFlag = false
						end
					end
				end

				if item.nGenre ==  ITEM_GENRE.TASK_ITEM then		---�����������Ʒ����ֱ��ʰȡ
					if LR_PickupDead.UsrData.bPickupTaskItem then
						pickFlag = true
					end
				end

				if LR_PickupDead.UsrData.bGiveUpItemsBTLON then
					local nMaxExistAmount = item.nMaxExistAmount
					local nStackNum = 1
					if item.bCanStack then
						nStackNum = item.nStackNum
					end
					local numInBagAndBank = LR.GetItemNumInBagAndBank(item.dwTabType, item.dwIndex, item.nBookID)
					if nMaxExistAmount > 0 and nMaxExistAmount < numInBagAndBank + nStackNum then
						pickFlag = false
					end
				end

				--������
				if LR_PickupDead.UsrData.bnotPickupItems then
					for k, v in pairs(LR_PickupDead.customData.ignorList or {}) do
						if v.bnotPickup then
							if v.szName then
								if v.szName == LR.GetItemNameByItem(item) then
									pickFlag = false
								end
							elseif v.dwTabType then
								if v.dwTabType == item.dwTabType and v.dwIndex == item.dwIndex then
									pickFlag = false
								end
							elseif v.nUiId then
								if v.nUiId == item.nUiId then
									pickFlag = false
								end
							end
						end
					end
				end

				if pickFlag then
					LootItem(dwDoodadID, item.dwID)
				end
			end
		end
	end

	LR.DelayCall(250, function() LR_PickupDead.CloseLootListPanel() end)
end

function LR_PickupDead.BreatheCall()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not LR_PickupDead.UsrData.bOn then
		return
	end

	for dwID, v in pairs(LR_PickupDead.doodadList) do
		if not LR_PickupDead.pickedUpList[dwID] then
			local distance = LR.GetDistance(v)
			if distance <=  PICKUP_MAX_DISTANCE then
				local doodad = GetDoodad(dwID)
				if doodad then
					if doodad.CanLoot(me.dwID) then
						--Output(me.nMoveState == MOVE_STATE.ON_STAND)
						if GetLogicFrameCount() - LR_PickupDead.lastPickupTime >=  PICKUP_MIN_TIME  and me.nMoveState == MOVE_STATE.ON_STAND then
							LR_PickupDead.lastPickupTime = GetLogicFrameCount()
							OpenDoodad(me, doodad)
							--InteractDoodad(doodad.dwID)
							return
						end
					else
						LR_PickupDead.doodadList[dwID] = nil
					end
				end
			else
				--Output(distance)
			end
		end
	end
end

function LR_PickupDead.LOGIN_GAME()
	LR_PickupDead.LoadCustomData()
end

function LR_PickupDead.SYS_MSG()
	if arg0 == "UI_OME_CRAFT_RESPOND" then
		if arg1 == CRAFT_RESULT_CODE.SUCCESS then
			CRAFT_SUCCESS = true
		end
	end
end


LR.BreatheCall("LR_PickupDead", function() LR_PickupDead.BreatheCall() end, 250)
LR.RegisterEvent("SYNC_LOOT_LIST",function() LR_PickupDead.SYNC_LOOT_LIST() end)
LR.RegisterEvent("DOODAD_LEAVE_SCENE",function() LR_PickupDead.DOODAD_LEAVE_SCENE() end)
LR.RegisterEvent("OPEN_DOODAD",function() LR_PickupDead.OPEN_DOODAD() end)
LR.RegisterEvent("LOGIN_GAME",function() LR_PickupDead.LOGIN_GAME() end)
LR.RegisterEvent("SYS_MSG",function() LR_PickupDead.SYS_MSG() end)
