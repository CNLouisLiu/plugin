local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_ShopHelper"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_ShopHelper"
local _L=LR.LoadLangPack(AddonPath)
---------------------------------------------------------------
local VERSION = "20170912"
---------------------------------------------------------------
----------------------------------------------------------------------------------------
------װ������
----------------------------------------------------------------------------------------
LR_AutoRepare = {}
LR_AutoRepare.UsrData = {
	bOn = false,
}
RegisterCustomData("LR_AutoRepare.UsrData", VERSION)

function LR_AutoRepare.SHOP_OPENSHOP()
	local dwShopID = arg0	--�̵�ID
	local nShopType = arg1	--�̵�����
	local dwValidPage = arg2	---�̵����ж��ٶ���
	local bCanRepair = arg3	--�̵���û��������
	local dwNpcID = arg4		--���̵��NPC��ID

	local me = GetClientPlayer()	---��
	if not me then	--����Ҳ����ڣ��ͷ���
		return
	end
	if bCanRepair and LR_AutoRepare.UsrData.bOn then		---����̵������������Զ�����Ĺ��ܴ�
		local nMoney = GetRepairAllItemsPrice(dwNpcID, dwShopID)	--��ȡ������Ҫ��ȫ���ʽ�
		if nMoney>0 then	--���������ô���0
			RepairAllItems(dwNpcID, dwShopID)	--��������ȫ���Ķ���
		end
	end
end
LR.RegisterEvent("SHOP_OPENSHOP", function() LR_AutoRepare.SHOP_OPENSHOP() end)
----------------------------------------------------------------------------------------
------�Զ�����
----------------------------------------------------------------------------------------
LR_AutoSell = {}
LR_AutoSell.UsrData = {
	bOn = false,
	bAutoSellGreyItem = true,
	bAutoSellItemInList = true,
	enableBlackList = false,
}
RegisterCustomData("LR_AutoSell.UsrData", VERSION)
local DEFAULT_ITEM = {
	AutoSellItem = {
		{dwTabType = 5, dwIndex = 17369, bSell = true}, 			--��Ҷ��
		{dwTabType = 5, dwIndex = 2863, bSell = true}, 			--��Ҷ��
		{dwTabType = 5, dwIndex = 2864, bSell = true}, 			--����Ҷ��
		{dwTabType = 5, dwIndex = 11682, bSell = true}, 			--����
		{dwTabType = 5, dwIndex = 11683, bSell = true}, 			--���
		{dwTabType = 5, dwIndex = 11684, bSell = true}, 			--��ש
		{dwTabType = 5, dwIndex = 11685, bSell = true}, 			--��Ԫ��
		{dwTabType = 5, dwIndex = 17130, bSell = true}, 			--��Ҷ�ӡ�����֮��
		{dwTabType = 5, dwIndex = 21381, bSell = true}, 			--���Ĺ�ף�û�õģ�
		{dwTabType = 5, dwIndex = 11640, bSell = true}, 			--��ש
		{dwTabType = 5, dwIndex = 22974, bSell = true}, 			--����Ľ�����
		{dwTabType = 5, dwIndex = 2865, bSell = true}, 			--��Ƭ����Ҷ��
		{dwTabType = 5, dwIndex = 2868, bSell = true}, 			--��Ƭ��Ҷ��
	},
	BlackList = {},
}
LR_AutoSell.CustomData = clone(DEFAULT_ITEM)

function LR_AutoSell.SaveCustomData()
	local path = sformat("%s\\CustomData.dat", SaveDataPath)
	local data = LR_AutoSell.CustomData or {}
	SaveLUAData(path, data)
end

function LR_AutoSell.LoadCustomData()
	local path = sformat("%s\\CustomData.dat", SaveDataPath)
	if IsFileExist(sformat("%s.jx3dat", path)) then
		LR_AutoSell.CustomData = LoadLUAData(path) or {}
	else
		LR_AutoSell.CustomData = clone(DEFAULT_ITEM)
		LR_AutoSell.SaveCustomData()
	end
end

function LR_AutoSell.ResetCustomData()
	LR_AutoSell.CustomData = clone(DEFAULT_ITEM)
	LR_AutoSell.SaveCustomData()
end

LR_AutoSell.ShopData = {
	dwShopID = 0,
	bCanRepair = false,
	dwNpcID = 0,
}

function LR_AutoSell.SHOP_OPENSHOP()
	local dwShopID = arg0
	local nShopType = arg1
	local dwValidPage = arg2
	local bCanRepair = arg3
	local dwNpcID = arg4

	LR_AutoSell.ShopData.dwShopID = dwShopID
	LR_AutoSell.ShopData.bCanRepair = bCanRepair
	LR_AutoSell.ShopData.dwNpcID = dwNpcID

	local me = GetClientPlayer()
	if not me then
		return
	end

	if not LR_AutoSell.UsrData.bOn then
		return
	end

	for _, dwBox in pairs(BAG_PACKAGE) do
		for dwX = 0, me.GetBoxSize(dwBox) - 1, 1 do
			local item = me.GetItem(dwBox, dwX)
			if item then
				local bSell = false
				if LR_AutoSell.UsrData.bAutoSellGreyItem then
					if item.nGenre ~= ITEM_GENRE.TASK_ITEM then
						if item.nQuality ==  0 then
							bSell = true
						end
					end
				end
				if LR_AutoSell.UsrData.bAutoSellItemInList then
					local CustomData = LR_AutoSell.CustomData or {}
					for k, v in pairs(CustomData.AutoSellItem or {}) do
						if v.bSell then
							if v.szName then
								if v.szName == LR.GetItemNameByItem(item) then
									bSell = true
								end
							elseif v.dwTabType then
								if tonumber(v.dwTabType) == item.dwTabType and tonumber(v.dwIndex) ==  item.dwIndex then
									bSell = true
								end
							elseif v.nUiId then
								if tonumber(v.nUiId) == item.nUiId then
									bSell = true
								end
							end
						end
					end
				end
				if LR_AutoSell.UsrData.enableBlackList then
					local CustomData = LR_AutoSell.CustomData or {}
					for k, v in pairs(CustomData.BlackList or {}) do
						if v.bNotSell then
							if v.szName then
								if v.szName == LR.GetItemNameByItem(item) then
									bSell = false
								end
							elseif v.dwTabType then
								if tonumber(v.dwTabType) ==  item.dwTabType and tonumber(v.dwIndex) ==  item.dwIndex then
									bSell = false
								end
							elseif v.nUiId then
								if tonumber(v.nUiId) == item.nUiId then
									bSell = false
								end
							end
						end
					end
				end
				if bSell then
					if LR.CheckUnLock() then
						local nCount = 1
						if item.bCanStack then
							nCount = item.nStackNum
						end
						LR.SysMsg(sformat("%s [%s] x%d\n", _L["LR: Sell item:"], LR.GetItemNameByItem(item), nCount))
						SellItem(dwNpcID, dwShopID, dwBox, dwX, nCount)
					else
						LR.SysMsg(_L["LR:You are locked\n"])
						return
					end
				end
			end
		end
	end
end

function LR_AutoSell.LOGIN_GAME()
	LR_AutoSell.LoadCustomData()
end

LR.RegisterEvent("SHOP_OPENSHOP", function() LR_AutoSell.SHOP_OPENSHOP() end)
LR.RegisterEvent("LOGIN_GAME", function() LR_AutoSell.LOGIN_GAME() end)
------------------------------------




