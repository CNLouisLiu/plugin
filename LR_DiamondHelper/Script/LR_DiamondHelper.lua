local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_DiamondHelper"
local SaveDataPath="Interface\\LR_Plugin\\@DATA\\LR_DiamondHelper"
--------------------------------------------------------------
local VERSION = "20170912"
---------------------------------------------------------------
LR_DiamondHelper = {}
LR_DiamondHelper.recipe = {}
LR_DiamondHelper.UsrData = {
	bRememberLastRecipe = false,
	bDistinguishBind = true,
}
RegisterCustomData("LR_DiamondHelper.UsrData", VERSION)

function LR_DiamondHelper.MakeStone()
	--
end

function LR_DiamondHelper.GetData(dwBox, dwX)
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
		t.bBind = item.bBind
		t.dwBox = dwBox
		t.dwX = dwX
		t.position = sformat("%d_%d", dwBox, dwX)
	end
	return t
end

function LR_DiamondHelper.GetRecipe()
	local recipe = {}
	local frame = Station.Lookup("Normal/CastingPanel")
	if not frame then
		return recipe
	end
	local me = GetClientPlayer()
	if not me then
		return recipe
	end
	local Handle_MyStone = frame:Lookup("PageSet_All"):Lookup("Page_Refine"):Lookup("","")
	--底子
	local Box_Refine = Handle_MyStone:Lookup("Handle_BoxItem"):Lookup("Box_Refine")
	local base = {}
	local nUiId, dwBox, dwX, _, dwTabType, dwIndex = Box_Refine:GetObjectData()
	if nUiId == -1 then
		return recipe
	end
	local base = LR_DiamondHelper.GetData(dwBox, dwX)
	if next(base) == nil then
		return recipe
	end

	--材料
	local Handle_RefineExpend = Handle_MyStone:Lookup("Handle_RefineExpend")
	local material = {}
	for i = 1, 16, 1 do
		local Box_RefineExpend = Handle_RefineExpend:Lookup(sformat("Box_RefineExpend_%d", i))
		local nUiId, dwBox, dwX, _, dwTabType, dwIndex = Box_RefineExpend:GetObjectData()
		if nUiId ~= -1 then
			local data = LR_DiamondHelper.GetData(dwBox, dwX)
			if next(data) ~= nil then
				material[data.position] = clone(data)
			end
		end
	end

	if next(material) == nil then
		return recipe
	end
	recipe[base.position] = clone(base)
	for k, v in pairs(material) do
		recipe[k] = clone(v)
	end
	return recipe
end

function LR_DiamondHelper.Remove2BlankBox(dwBox, dwX)
	local me = GetClientPlayer()
	if not me then
		return false
	end
	for dBox = 1, 6, 1 do
		for dX = 0, me.GetBoxSize(dBox) - 1, 1 do
			if not LR_DiamondHelper.recipe[sformat("%d_%d", dBox, dX)] then
				local item = me.GetItem(dBox, dX)
				if not item then
					me.ExchangeItem(dwBox, dwX, dBox, dX)
					return true
				end
			end
		end
	end
	return false
end

function LR_DiamondHelper.GetBagCache()
	local me = GetClientPlayer()
	local cache = {}
	for dwBox = 6, 1, -1 do
		for dwX = me.GetBoxSize(dwBox) - 1, 0, -1 do
			local data = LR_DiamondHelper.GetData(dwBox, dwX)
			if next(data) ~= nil then
				cache[#cache + 1] = clone(data)
			end
		end
	end
	return cache
end


function LR_DiamondHelper.MoveItemToRecipePosition(v)
	local me = GetClientPlayer()
	if not me then
		return false
	end
	local bagCache = LR_DiamondHelper.bagCache
	--Output(bagCache)
	for k, cache in pairs(bagCache) do
		if cache.szName == v.szName and cache.nStackNum >= v.nStackNum and not LR_DiamondHelper.recipe[sformat("%d_%d", cache.dwBox, cache.dwX)] then
			--Output(cache.dwBox, cache.dwX, v.dwBox, v.dwX, v.nStackNum)
			if not LR_DiamondHelper.UsrData.bDistinguishBind or cache.bBind == v.bBind then
				me.ExchangeItem(cache.dwBox, cache.dwX, v.dwBox, v.dwX, v.nStackNum)
				LR_DiamondHelper.bagCache[k].nStackNum = LR_DiamondHelper.bagCache[k].nStackNum - v.nStackNum
				return true
			end
		end
	end
	return false
end

function LR_DiamondHelper.RestoreRecipePosition()
	local me = GetClientPlayer()
	if not me then
		return false
	end
	local recipe = LR_DiamondHelper.recipe or {}
	if next(recipe) == nil then
		return false
	end
	--合并
	LR_DiamondHelper.StackBag()
	LR.DelayCall(25, function()
		--先把原位置上的东西都搬走
		---Output("1")
		for k, v in pairs(recipe) do
			local dwBox = v.dwBox
			local dwX = v.dwX
			local item = me.GetItem(dwBox, dwX)
			if item then
				if not LR_DiamondHelper.Remove2BlankBox(dwBox, dwX) then
					return false
				end
			end
		end

		LR.DelayCall(25, function()
			---再把原位置放上配方上的东西

			--Output("2")
			LR_DiamondHelper.bagCache = LR_DiamondHelper.GetBagCache()
			for k, v in pairs(recipe) do
				local dwBox = v.dwBox
				local dwX = v.dwX
				if not LR_DiamondHelper.MoveItemToRecipePosition(v) then
					return false
				end
			end

			LR.DelayCall(25, function()
				--Output("3")
				LR_DiamondHelper.MakeStone()
			end)
		end)
	end)
	return true
end

function LR_DiamondHelper.StackBag()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local cache = {}
	for dwBox = 1, 6, 1 do
		for dwX = 0, me.GetBoxSize(dwBox) - 1, 1 do
			local data = LR_DiamondHelper.GetData(dwBox, dwX)
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

function LR_DiamondHelper.DIAMON_UPDATE()
	if not LR_DiamondHelper.UsrData.bRememberLastRecipe then
		return
	end
	local me = GetClientPlayer()
	LR.DelayCall(50, function()
		if LR_DiamondHelper.RestoreRecipePosition() then

		end
	end)
end

function LR_DiamondHelper.ON_FRAME_CREATE2()
		local frame = Station.Lookup("Topmost/MB_CastingPanelConfirm")
		if frame then
			local Btn_Option1 = frame:Lookup("Wnd_All/Btn_Option1")
			LR_DiamondHelper.MakeStone = Btn_Option1.fnAction
			LR_DiamondHelper.recipe = LR_DiamondHelper.GetRecipe()
			--Output(LR_DiamondHelper.recipe)
		end
end

function LR_DiamondHelper.ON_FRAME_CREATE()
	if not LR_DiamondHelper.UsrData.bRememberLastRecipe then
		return
	end
	local frame = arg0
	local szName = frame:GetName()
	if szName == "MB_CastingPanelConfirm" then
		LR.DelayCall(150, function() LR_DiamondHelper.ON_FRAME_CREATE2() end)
	end
end

LR.RegisterEvent("DIAMON_UPDATE", function() LR_DiamondHelper.DIAMON_UPDATE() end)
LR.RegisterEvent("ON_FRAME_CREATE", function() LR_DiamondHelper.ON_FRAME_CREATE()  end)
