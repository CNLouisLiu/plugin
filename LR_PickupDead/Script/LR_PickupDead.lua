local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_ShopHelper"
local SaveDataPath = "Interface\\LR_Plugin\\@DATA\\LR_ShopHelper"
local _L=LR.LoadLangPack(AddonPath)
---------------------------------------------------------------
local VERSION = "20170818b"
---------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
----自动拾取Doodad
-------------------------------------------------------------------------------------------------------------
-----SYNC_LOOT_LIST在DOODAD_ENTER_SCENE之后
-----SYNC_LOOT_LIST:在有可拾取的DOODAD出现后会触发，任务物品不会触发
-----所以优先使用SYNC_LOOT_LIST
-----步骤：
-----SYNC_LOOT_LIST将doodad加入doodadList
-----breathe打开附近的DOODAD，触发OPEN_DOODAD(别人打开，包括队友打开都不触发，只有自己打开会触发)
-----触发OPEN_DOODAD后，进行拾取
-----有些物品被所有人放弃后再打开DOODAD，就会直接放进包里，所以最好Roll点在打开之后


local PICKUP_MIN_TIME = 3
local PICKUP_MAX_DISTANCE = 4
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
	pickUpLevel = 1,
	bOn = false,
	bPickupTaskItem = true,
	bPickupUnReadBook = false,
	bPickupItems = false,
	bnotPickupItems = false,
	bOnlyPickupItems = false,
}
RegisterCustomData("LR_PickupDead.UsrData", VERSION)


function LR_PickupDead.SaveCustomData()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local path = AddonPath.."\\UsrData\\CustomData.dat"
	local data = clone(LR_PickupDead.customData)
	SaveLUAData (path,data)
end

function LR_PickupDead.LoadCustomData()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local path = AddonPath.."\\UsrData\\CustomData.dat"
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
---事件操作
--------------------------------------------------------------
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

	if LR_PickupDead.pickedUpList[dwDoodadID] then
		LR_PickupDead.doodadList[dwDoodadID] = nil
		return
	end

	local doodad =  GetDoodad (dwDoodadID)
	if not doodad then
		return
	end

	----清空LIst
	LR_PickupDead.doodadList[dwDoodadID] = nil
	LR_PickupDead.pickedUpList[dwDoodadID] = true

	--拾取金钱
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
				if item.nGenre ==  ITEM_GENRE.TASK_ITEM then		---如果是任务物品，则直接拾取
					if LR_PickupDead.UsrData.bPickupTaskItem then
						LootItem(dwDoodadID, item.dwID)
					end
				elseif LR_PickupDead.UsrData.bPickupUnReadBook and item.nGenre == ITEM_GENRE.BOOK then
					local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
					if not me.IsBookMemorized(nBookID, nSegID) then
						LootItem(dwDoodadID, item.dwID)
					end
				else
					local pickFlag = false
					--白名单
					for k, v in pairs(LR_PickupDead.customData.pickList or {}) do
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
					--不在白名单中的
					if not LR_PickupDead.UsrData.bOnlyPickupItems then
						if item.nQuality >=  LR_PickupDead.UsrData.pickUpLevel then
							pickFlag = true
						end
					end
					--黑名单
					for k, v in pairs(LR_PickupDead.customData.ignorList or {}) do
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

					if pickFlag then
						LootItem(dwDoodadID, item.dwID)
					end
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
						if GetLogicFrameCount() - LR_PickupDead.lastPickupTime >=  PICKUP_MIN_TIME  and me.nMoveState == MOVE_STATE.ON_STAND then
							LR_PickupDead.lastPickupTime = GetLogicFrameCount()
							InteractDoodad(doodad.dwID)
							return
						end
					else
						LR_PickupDead.doodadList[dwID] = nil
					end
				end
			end
		end
	end
end

function LR_PickupDead.LOGIN_GAME()
	LR_PickupDead.LoadCustomData()
end


LR.BreatheCall("LR_PickupDead", function() LR_PickupDead.BreatheCall() end, 250)
LR.RegisterEvent("SYNC_LOOT_LIST",function() LR_PickupDead.SYNC_LOOT_LIST() end)
LR.RegisterEvent("DOODAD_LEAVE_SCENE",function() LR_PickupDead.DOODAD_LEAVE_SCENE() end)
LR.RegisterEvent("OPEN_DOODAD",function() LR_PickupDead.OPEN_DOODAD() end)
LR.RegisterEvent("LOGIN_GAME",function() LR_PickupDead.LOGIN_GAME() end)

