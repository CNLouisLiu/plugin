local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_BagHelper"
local SaveDataPath="Interface\\LR_Plugin\\@DATA\\LR_BagHelper"
local _L = LR.LoadLangPack(AddonPath)
--------------------------------------------------------------
local VERSION = "20170818"
---------------------------------------------------------------
LR_BagHelper = {}
LR_BagHelper.UsrData = {
	bShowBagBtn = false,
	bShowBankBtn = false,
	bShowGuildBankBtn = false,
}
RegisterCustomData("LR_BagHelper.UsrData", VERSION)
LR_BagHelper.bBagHooked = false
LR_BagHelper.bBankHooked = false

function LR_BagHelper.GetData(dwBox, dwX)
	local t = {}
	local me = GetClientPlayer()
	local item = me.GetItem(dwBox, dwX)
	if item then
		local dwTabType = item.dwTabType
		local dwIndex = item.dwIndex
		local szKey = sformat("%d_%d", dwTabType, dwIndex)
		t.szKey = szKey
		t.szName = item.szName
		t.dwTabType = item.dwTabType
		t.dwIndex = item.dwIndex
		t.nStackNum = 1
		if item.bCanStack then
			t.nStackNum = item.nStackNum
		end
		t.nMaxStackNum = item.nMaxStackNum
		t.bCanStack = item.bCanStack
		t.dwBox = dwBox
		t.dwX = dwX
		t.position = sformat("%d_%d", dwBox, dwX)
	end
	return t
end

function LR_BagHelper.StackBag()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local cache = {}
	for dwBox = 1, 6, 1 do
		for dwX = 0, me.GetBoxSize(dwBox) - 1, 1 do
			local data = LR_BagHelper.GetData(dwBox, dwX)
			if next(data) ~= nil then
				if data.bCanStack then
					for k, v in pairs(cache) do
						if v.szKey == data.szKey and v.nStackNum < v.nMaxStackNum then
							me.ExchangeItem(dwBox, dwX, v.dwBox, v.dwX, mmin(data.nStackNum, v.nMaxStackNum - v.nStackNum))
							local nStackNum = data.nStackNum
							data.nStackNum = data.nStackNum - mmin(data.nStackNum, v.nMaxStackNum - v.nStackNum)
							v.nStackNum = v.nStackNum + mmin(nStackNum, v.nMaxStackNum - v.nStackNum)
						end
					end
					if data.nStackNum  > 0 then
						cache[#cache + 1] = clone(data)
					end
				end
			end
		end
	end
end

function LR_BagHelper.StackBank()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local cache = {}
	for dwBox = 7, 12, 1 do
		for dwX = 0, me.GetBoxSize(dwBox) - 1, 1 do
			local data = LR_BagHelper.GetData(dwBox, dwX)
			if next(data) ~= nil then
				if data.bCanStack then
					for k, v in pairs(cache) do
						if v.szKey == data.szKey and v.nStackNum < v.nMaxStackNum then
							me.ExchangeItem(dwBox, dwX, v.dwBox, v.dwX, mmin(data.nStackNum, v.nMaxStackNum - v.nStackNum))
							local nStackNum = data.nStackNum
							data.nStackNum = data.nStackNum - mmin(data.nStackNum, v.nMaxStackNum - v.nStackNum)
							v.nStackNum = v.nStackNum + mmin(nStackNum, v.nMaxStackNum - v.nStackNum)
						end
					end
					if data.nStackNum  > 0 then
						cache[#cache + 1] = clone(data)
					end
				end
			end
		end
	end
end


-----------------------------------------------------------
LR_GuildBank = {}

LR_GuildBank.Data = {}

local SORT_KEY = {
	ITEM_GENRE.EQUIPMENT,
	ITEM_GENRE.POTION,
	ITEM_GENRE.MATERIAL,
	ITEM_GENRE.BOOK,
	ITEM_GENRE.COLOR_DIAMOND,
	ITEM_GENRE.DIAMOND,
}

function LR_GuildBank.Sort(t)
	local tt = clone(t)
	tsort(tt, function(a, b)
		if a.nGenre == ITEM_GENRE.BOOK then
			if a.nQuality == b.nQuality then
				if a.nBookID == b.nBookID then
					return a.dwX < b.dwX
				else
					return a.nBookID < b.nBookID
				end
			else
				return a.nQuality > b.nQuality
			end
		else
			if a.nSub == b.nSub then
				if a.nDetail == b.nDetail then
					if a.nQuality == b.nQuality then
						if a.nUiId == b.nUiId then
							if a.nStackNum == b.nStackNum then
								return a.dwX < b.dwX
							else
								return a.nStackNum > b.nStackNum
							end
						else
							return a.nUiId < b.nUiId
						end
					else
						return a.nQuality > b.nQuality
					end
				else
					return a.nDetail < b.nDetail
				end
			else
				return a.nSub < b.nSub
			end
		end
	end)
	return tt
end

function LR_GuildBank.LogicSortGuildBank()
	local Data = LR_GuildBank.Data or {}
	local FilterData = {}
	for k, v in pairs(SORT_KEY) do
		FilterData[v] = {}
	end
	FilterData["other"] = {}
	--分类
	for k, v in pairs(Data) do
		if FilterData[v.nGenre] then
			FilterData[v.nGenre][#FilterData[v.nGenre] + 1] = v
		else
			FilterData["other"][#FilterData["other"] + 1] = v
		end
	end
	--分类排序
	for k, v in pairs(SORT_KEY) do
		FilterData[v] = LR_GuildBank.Sort(FilterData[v])
	end
	FilterData["other"] = LR_GuildBank.Sort(FilterData["other"])
	--分类组合
	local data_all = {}
	for k, v in pairs(SORT_KEY) do
		for kk, vv in pairs(FilterData[v]) do
			data_all[#data_all + 1] = vv
		end
	end
	for k, v in pairs(FilterData["other"]) do
		data_all[#data_all + 1] = v
	end
	return data_all
end

function LR_GuildBank.PhysicSortGuildBank()
	local me = GetClientPlayer()
	LR_GuildBank.Data = clone(LR_GuildBank.GetGuildBankData())
	LR_GuildBank.Data = clone(LR_GuildBank.LogicSortGuildBank())

	local t, x = {}, {}
	for k, v in pairs(LR_GuildBank.Data) do
		if not x[v.szName] then
			t[#t+1] = v.szName
			x[v.szName] = true
		end
	end
	--Output(tconcat(t, ","))
	if not LR_GuildBank.ExchangeItem() then
		LR.DelayCall(250, function() LR_GuildBank.PhysicSortGuildBank() end)
	else
		local frame = Station.Lookup("Normal/GuildBankPanel")
		if frame then
			LR_GuildBank.Btn:Enable(true)
		end
		LR.SysMsg(_L["Sort over.\n"])
	end
end


function LR_GuildBank.GetGuildData(dwBox, dwX)
	local data = {}
	local me = GetClientPlayer()
	local item = GetPlayerItem(me, dwBox, dwX)
	if item then
		data.szKey = sformat("%d_%d", item.dwTabType, item.dwIndex)
		data.nUiId = item.nUiId
		data.dwTabType = item.dwTabType
		data.dwIndex = item.dwIndex
		data.nStackNum = 1
		data.bCanStack = item.bCanStack
		if item.bCanStack then
			data.nStackNum = item.nStackNum
		end
		data.nMaxStackNum = item.nMaxStackNum
		data.nGenre = item.nGenre
		data.nBookID = 0
		if item.nGenre == ITEM_GENRE.BOOK then
			data.nBookID = item.nBookID
		end
		data.nSub = item.nSub
		data.nDetail = item.nDetail
		data.nQuality = item.nQuality
		data.szName = item.szName
		data.dwX = dwX
	end

	return data
end

function LR_GuildBank.GetGuildBankData()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local frame = Station.Lookup("Normal/GuildBankPanel")
	if not frame then
		return
	end
	local data = {}
	local dwBox = INVENTORY_GUILD_BANK
	local dwPageSize = INVENTORY_GUILD_PAGE_SIZE
	local nPage = frame.nPage
	LR_GuildBank.nPage = nPage
	local nStart = nPage * dwPageSize
	for dwX = nStart, nStart + dwPageSize - 1, 1 do
		local data2 = LR_GuildBank.GetGuildData(dwBox, dwX)
		if next(data2) ~= nil then
			data[#data + 1] = clone(data2)
		end
	end
	return data
end

function LR_GuildBank.ModifyData(data, k, dwX)
	local data2 = clone(data)
	for k, v in pairs(data2) do
		if v.dwX == k then
			data2[k].dwX = dwX
		end
	end
	return data2
end

function LR_GuildBank.ExchangeItem()
	local data2 = LR_GuildBank.Data
	local frame = Station.Lookup("Normal/GuildBankPanel")
	if not frame then
		return true
	end
	local nPage = frame.nPage
	local me = GetClientPlayer()
	if not me then
		return true
	end
	local dwBox = INVENTORY_GUILD_BANK
	local dwPageSize = INVENTORY_GUILD_PAGE_SIZE
	for k = 1, #data2 , 1 do
		local item = LR_GuildBank.GetGuildData(dwBox, dwPageSize * nPage + k - 1)
		local TargetItem = data2[k]
		local move_flag = true
		if item then
			if item.nGenre == ITEM_GENRE.BOOK then
				if TargetItem.nGenre == ITEM_GENRE.BOOK and TargetItem.nBookID == item.nBookID then
					move_flag = false
				end
			else
				if TargetItem.dwTabType == item.dwTabType and TargetItem.dwIndex == item.dwIndex and TargetItem.nStackNum == item.nStackNum then
					move_flag = false
				end
			end
		end
		if move_flag then
			--Output(TargetItem.dwX, "to", dwPageSize * nPage + k - 1, TargetItem.szName, item.szName)
			OnExchangeItem(dwBox, TargetItem.dwX, dwBox, dwPageSize * nPage + k - 1)
			return false
		end
	end
	return true
end

------hook
function LR_BagHelper.HookBag()
	local frame = Station.Lookup("Normal/BigBagPanel")
	if frame then --背包界面添加一个按钮
		local Btn_Stack = frame:Lookup("LR_Stack")
		if not Btn_Stack then
			if LR_BagHelper.UsrData.bShowBagBtn then
				local Btn_Stack = LR.AppendUI("Button", frame, "LR_Stack", {w = 44, h = 26, x = 8, y = 402})
				Btn_Stack:SetText(_L["Stack"])
				Btn_Stack.OnClick = function()
					LR_BagHelper.StackBag()
				end
			end
		else
			if not LR_BagHelper.UsrData.bShowBagBtn then
				Btn_Stack:Destroy()
			end
		end
	end
end

function LR_BagHelper.HookBank()
	local frame = Station.Lookup("Normal/BigBankPanel")
	if frame then --背包界面添加一个按钮
		local Btn_Stack = frame:Lookup("LR_Stack")
		local Btn_CU = frame:Lookup("Btn_CU")
		if not Btn_Stack then
			if LR_BagHelper.UsrData.bShowBankBtn then
				local left, top = Btn_CU:GetRelPos()
				local Btn_Stack = LR.AppendUI("Button", frame, "LR_Stack", {w = 91, h = 26, x = left + 100, y = top - 1})
				Btn_Stack:SetText(_L["Stack"])
				Btn_Stack.OnClick = function()
					LR_BagHelper.StackBank()
				end
			end
		else
			if not LR_BagHelper.UsrData.bShowBankBtn then
				Btn_Stack:Destroy()
			end
		end
	end
end

function LR_GuildBank.HookGuildBank()
	local frame = Station.Lookup("Normal/GuildBankPanel")
	if frame then --背包界面添加一个按钮
		local Btn_Sort = frame:Lookup("LR_Sort")
		if not Btn_Sort then
			if LR_BagHelper.UsrData.bShowGuildBankBtn then
				local Btn_Sort = LR.AppendUI("Button", frame, "LR_Sort", {w = 127, h = 28, x = 470, y = 474})
				Btn_Sort:SetText(_L["Sort"])
				Btn_Sort.OnClick = function()
					Btn_Sort:Enable(false)
					LR_GuildBank.PhysicSortGuildBank()
				end
				LR_GuildBank.Btn = Btn_Sort
			end
		else
			if not LR_BagHelper.UsrData.bShowGuildBankBtn then
				Btn_Sort:Destroy()
			end
		end
	end
end

-------------------------------------------------------------------------
function LR_BagHelper.ON_FRAME_CREATE()
	local frame = arg0
	local szName = frame:GetName()
	if szName == "BigBagPanel" then
		LR.DelayCall(600, function() LR_BagHelper.HookBag() end)
	elseif szName == "BigBankPanel" then
		LR.DelayCall(150, function() LR_BagHelper.HookBank() end)
	elseif szName == "GuildBankPanel" then
		LR.DelayCall(150, function() LR_GuildBank.HookGuildBank() end)
	end
end

LR.RegisterEvent("ON_FRAME_CREATE", function() LR_BagHelper.ON_FRAME_CREATE() end)




