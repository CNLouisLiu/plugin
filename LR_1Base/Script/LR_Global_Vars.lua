local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin, mtan = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min, math.tan
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_1Base"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_1Base"
---------------------------------------------------------------
-----2019��5�£�����°汾�趨ȫ�ֱ���ֻ������һ�Σ���ȫ�ֱ���ֻ��=1�Σ��ܶ����������ݵķ�����Ҫ���½����޸�
---------------------------------------------------------------
-----���в����ȫ�ֱ���������������
---------------------------------------------------------------
BAG_PACKAGE = {
	INVENTORY_INDEX.PACKAGE,	--1
	INVENTORY_INDEX.PACKAGE1,	--2
	INVENTORY_INDEX.PACKAGE2,	--3
	INVENTORY_INDEX.PACKAGE3,	--4
	INVENTORY_INDEX.PACKAGE4,	--5
	INVENTORY_INDEX.PACKAGE_MIBAO,	--6
}
BANK_PACKAGE = {
	INVENTORY_INDEX.BANK,
	INVENTORY_INDEX.BANK_PACKAGE1,
	INVENTORY_INDEX.BANK_PACKAGE2,
	INVENTORY_INDEX.BANK_PACKAGE3,
	INVENTORY_INDEX.BANK_PACKAGE4,
	INVENTORY_INDEX.BANK_PACKAGE5,
}

ALL_KUNGFU_COLLECT = {
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 21, 22, 23, 24, 0,
}

---------------------------------------------------------------
-----��Ҫ��������ݵı�������������������������ȫ�ֱ���ǰ��_GMV
---------------------------------------------------------------
_GMV = {}	--short for Global_Memory_Vars
--�Ŷ����
--_GMV.LR_Team_Map = {}
--_GMV.LR_Team_Map_Sorted = {}

