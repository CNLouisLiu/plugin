local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath="Interface\\LR_Plugin\\LR_EquipSearch"
local SaveDataPath="Interface\\LR_Plugin@DATA\\LR_EquipSearch"
local _L = LR.LoadLangPack(AddonPath)
local DB_Name = "EquipDB.db"
local DB_Path = sformat("%s\\%s", SaveDataPath, DB_Name)
local VERSION = "20170717"
---------------------------------------------------------------
local schema_table_info = {
	name = "table_info",
	version = "20170622",
	data = {
		{name = "table_name", sql = "table_name VARCHAR(60) PRIMARY KEY"},
		{name = "version", sql = "version VARCHAR(20)"}
	},
}
local schema_equipdb_data = {
	name = "equip_data",
	version = "20170628",
	data = {
		{name = "szKey", 	sql = "szKey VARCHAR(60)"},		--主键
		{name = "dwTabType", sql = "dwTabType INTEGER DEFAULT(0)"},
		{name = "dwIndex", sql = "dwIndex INTEGER DEFAULT(0)"},
		{name = "nLevel", sql = "nLevel INTEGER DEFAULT(0)"},
		{name = "nAucType", sql = "nAucType INTEGER DEFAULT(0)"},
		{name = "szName", sql = "szName TEXT"},
		{name = "nSchoolID", sql = "nSchoolID INTEGER DEFAULT(0)"},
		{name = "nSetID", sql = "nSetID INTEGER DEFAULT(0)"},
		{name = "szMagicKind", sql = "szMagicKind TEXT"},
		{name = "szMagicType", sql = "szMagicType TEXT"},
		{name = "szSourceType", sql = "szSourceType TEXT"},
		{name = "szPvePvp", sql = "szPvePvp TEXT"},
		{name = "szSourceForce", sql = "szSourceForce TEXT"},
		{name = "szSourceDesc", sql = "szSourceDesc TEXT"},
		{name = "szBelongMapID", sql = "szBelongMapID TEXT"},
		{name = "szPrestigeRequire", sql = "szPrestigeRequire TEXT"},
		{name = "nRecommendID", sql = "nRecommendID INTEGER DEFAULT(0)"},
		{name = "nGenre", sql = "nGenre INTEGER DEFAULT(0)"},
		{name = "nSub", sql = "nSub INTEGER DEFAULT(0)"},
		{name = "nDetail", sql = "nDetail INTEGER DEFAULT(0)"},
		{name = "nQuality", sql = "nQuality INTEGER DEFAULT(0)"},
		{name = "nBindType", sql = "nBindType INTEGER DEFAULT(0)"},
		{name = "szAttribute", sql = "szAttribute TEXT"},
		{name = "nRequireLevel", sql = "nRequireLevel INTEGER DEFAULT(0)"},
		{name = "bDel", 	sql = "bDel INTEGER DEFAULT(0)"},
	},
	primary_key = {sql = "PRIMARY KEY ( szKey )"},
}

local function CREATE_DB()
	LR.IniDB(SaveDataPath, DB_Name, {schema_equipdb_data,})
end
CREATE_DB()
---------------------------------------------------------------
local LR_ATTRIBUTE = {
	--DPS
	PO_FANG = 1,
	HUI_XIN = 2,
	HUI_XIAO = 3,
	WU_SHUANG = 4,
	JIA_SU = 5,
	MING_ZHONG = 6,
	--T
	WAI_FANG = 7,
	NEI_FANG = 8,
	YU_JIN = 9,
	ZHAO_JIA = 10,
	SHAN_BI = 11,
	--PVP
	HUA_JIN = 12,
}

local LR_ATTRIBUTE_TEXT = {
	[LR_ATTRIBUTE.PO_FANG] = _L["PO_FANG"],
	[LR_ATTRIBUTE.HUI_XIN] = _L["HUI_XIN"],
	[LR_ATTRIBUTE.HUI_XIAO] = _L["HUI_XIAO"],
	[LR_ATTRIBUTE.WU_SHUANG] = _L["WU_SHUANG"],
	[LR_ATTRIBUTE.JIA_SU] = _L["JIA_SU"],
	[LR_ATTRIBUTE.MING_ZHONG] = _L["MING_ZHONG"],
	[LR_ATTRIBUTE.WAI_FANG] = _L["WAI_FANG"],
	[LR_ATTRIBUTE.NEI_FANG] = _L["NEI_FANG"],
	[LR_ATTRIBUTE.YU_JIN] = _L["YU_JIN"],
	[LR_ATTRIBUTE.ZHAO_JIA] = _L["ZHAO_JIA"],
	[LR_ATTRIBUTE.SHAN_BI] = _L["SHAN_BI"],
	[LR_ATTRIBUTE.HUA_JIN] = _L["HUA_JIN"],
}

local LR_ATTRIBUTE_nID = {}

local LR_QUALITY = {
	NONE = -1,
	PO_BAI = 0,
	PU_TONG = 1,
	JING_QIAO = 2,
	ZHUO_YUE = 3,
	ZHEN_QI = 4,
	XI_SHI = 5,
}

local LR_QUALITY_TEXT = {
	[LR_QUALITY.NONE] = _L["ANY_QUALITY"],
	[LR_QUALITY.PO_BAI] = _L["PO_BAI"],
	[LR_QUALITY.PU_TONG] = _L["PU_TONG"],
	[LR_QUALITY.JING_QIAO] = _L["JING_QIAO"],
	[LR_QUALITY.ZHUO_YUE] = _L["ZHUO_YUE"],
	[LR_QUALITY.ZHEN_QI] = _L["ZHEN_QI"],
	[LR_QUALITY.XI_SHI] = _L["XI_SHI"],
}

local LR_RECOMMEND_TEXT = {}
local function GET_LR_RECOMMEND_TEXT()
	local nCount = g_tTable.EquipRecommend:GetRowCount()
	for i = 2, nCount, 1 do
		local tLine = g_tTable.EquipRecommend:GetRow(i)
		LR_RECOMMEND_TEXT[tLine.dwID] = tLine.szDesc
	end
end
GET_LR_RECOMMEND_TEXT()

local LR_EQUIP_TYPE = {}
local function GET_LR_EQUIP_TYPE()
	local DB = LR.OpenDB(DB_Path, "EF5E2BBBC4A5DC7920A72284FA058170")
	local DB_SELECT = DB:Prepare("SELECT nSub, nDetail FROM equip_data GROUP BY nSub, nDetail")
	local data = DB_SELECT:GetAll() or {}
	LR.CloseDB(DB)
	LR_EQUIP_TYPE = {}
	for k, v in pairs (data) do
		local nSub = v.nSub
		local nDetail = v.nDetail
		local szSub = g_tStrings.tEquipTypeNameTable[nSub]
		if nSub == EQUIPMENT_SUB.MELEE_WEAPON then
			local szDetail = GetWeapenType(nDetail)
			local SQL = {sformat("nSub = %d", nSub), sformat("nDetail = %d", nDetail)}
			LR_EQUIP_TYPE[szSub] = LR_EQUIP_TYPE[szSub] or {}
			LR_EQUIP_TYPE[szSub][szDetail] = tconcat(SQL, " AND ")
		elseif nSub == EQUIPMENT_SUB.RANGE_WEAPON then
			local szDetail = GetWeapenType(nDetail)
			local SQL = {sformat("nSub = %d", nSub), sformat("nDetail = %d", nDetail)}
			LR_EQUIP_TYPE[szSub] = LR_EQUIP_TYPE[szSub] or {}
			LR_EQUIP_TYPE[szSub][szDetail] = tconcat(SQL, " AND ")
		elseif nSub == EQUIPMENT_SUB.ARROW then
			local szDetail = GetWeapenType(nDetail)
			local SQL = {sformat("nSub = %d", nSub), sformat("nDetail = %d", nDetail)}
			LR_EQUIP_TYPE[szSub] = LR_EQUIP_TYPE[szSub] or {}
			LR_EQUIP_TYPE[szSub][szDetail] = tconcat(SQL, " AND ")
		elseif nSub >=2 and nSub <= 10 then
			LR_EQUIP_TYPE[_L["FANG_JU"]] = LR_EQUIP_TYPE[_L["FANG_JU"]] or {}
			LR_EQUIP_TYPE[_L["FANG_JU"]][szSub] = sformat("nSub = %d", nSub)
		elseif nSub == 11 or nSub == 14 or nSub == 17 or nSub == 20 or nSub == 21 or nSub == 22 then
			--11：腰部挂件，14：背部挂件，17：面部挂件，20：左肩饰，21：右肩饰，22：披风
			LR_EQUIP_TYPE[_L["ZHUANG_SHI"]] = LR_EQUIP_TYPE[_L["ZHUANG_SHI"]] or {}
			LR_EQUIP_TYPE[_L["ZHUANG_SHI"]][szSub] = sformat("nSub = %d", nSub)
		else
			LR_EQUIP_TYPE[_L["QI_TA"]] = LR_EQUIP_TYPE[_L["QI_TA"]] or {}
			LR_EQUIP_TYPE[_L["QI_TA"]][szSub] = sformat("nSub = %d", nSub)
			if nSub == 15 then
				LR_EQUIP_TYPE[_L["QI_TA"]][szSub] = sformat("nSub = %d AND nRequireLevel > 0", nSub)
			end
		end
	end
end
-------------------------------------------------------------
LR_EquipSearch = LR_EquipSearch or {}
LR_EquipSearch.RESULT = {}
LR_EquipSearch.UsrData = {
	VERSION = "20170606",
}
function LR_EquipSearch.SaveVer()
	SaveLUAData(sformat("%s\\ver.dat", SaveDataPath), LR_EquipSearch.UsrData)
end

function LR_EquipSearch.LoadVer()
	LR_EquipSearch.UsrData = LoadLUAData(sformat("%s\\ver.dat", SaveDataPath)) or {VERSION = "20170606",}
end
LR_EquipSearch.LoadVer()

function LR_EquipSearch.CheckDB()
	local bInI = false
	if LR_EquipSearch.UsrData.VERSION ~= VERSION then
		bInI = true
	elseif not IsFileExist(DB_Path) then
		bInI = true
	else
		local DB = LR.OpenDB(DB_Path, "04BEC480CB21E0CA7B530DB30C148EEF")
		local DB_SELECT = DB:Prepare("SELECT * FROM sqlite_master WHERE type = 'table' AND name ='equip_data'")
		local Data = DB_SELECT:GetAll() or {}
		if next(Data) == nil then
			bInI = true
		else
			local DB_SELECT2 = DB:Prepare("SELECT COUNT(*) AS COUNT FROM equip_data")
			local Data2 = DB_SELECT2:GetAll() or {}
			if Data2[1].COUNT < 100 then
				bInI = true
			end
			local nCount = g_tTable.EquipDB:GetRowCount()
			if nCount - Data2[1].COUNT > 3 then
				bInI = true
			end
		end
		LR.CloseDB(DB)
	end
	if bInI then
		local msg = {
			szMessage = _L["Need to initialize the plug-in and start?"],
			szName = "initial",
			fnAutoClose = function() return false end,
			{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() LR_EquipSearch.IniDB() end, },
			{szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function() LR_EquipSearch_Panel:Close() end, },
		}
		MessageBox(msg)
	end
end

function LR_EquipSearch.IniDB()
	CPath.DelFile(DB_Path)
	CREATE_DB()
	LR_EquipSearch.ExportDB()
	local msg = {
		szMessage = _L["Initialize plug-in successfully"],
		szName = "success",
		fnAutoClose = function() return false end,
		{szOption = g_tStrings.STR_HOTKEY_SURE,  },
	}
	MessageBox(msg)
	LR_EquipSearch.UsrData.VERSION = VERSION
	LR_EquipSearch.SaveVer()
	GET_LR_EQUIP_TYPE()
end

function LR_EquipSearch.ExportDB()
	local tTime = GetTickCount()
	local DB = LR.OpenDB(DB_Path, "59E83193256DDE21DB9FE60DEDACA299")
	local DB_REPLACE = DB:Prepare("REPLACE INTO equip_data ( szKey, dwTabType, dwIndex, nLevel, nAucType, szName, nSchoolID, nSetID, szMagicKind, szMagicType, szSourceType, szPvePvp, szSourceForce, szSourceDesc, szBelongMapID, szPrestigeRequire, nRecommendID, nGenre, nSub, nDetail, nQuality, nBindType, szAttribute, nRequireLevel, bDel ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0 )")

	local nCount = g_tTable.EquipDB:GetRowCount()
	for i = 2, nCount, 1 do
		local v = g_tTable.EquipDB:GetRow(i)
		if v and next(v) ~= nil then
			local itemInfo = GetItemInfo(v.dwTabType, v.nItemID)
			local nRecommendID = itemInfo.nRecommendID
			local nGenre = itemInfo.nGenre
			local nSub = itemInfo.nSub
			local nDetail = itemInfo.nDetail
			local nQuality = itemInfo.nQuality
			local nBindType = itemInfo.nBindType
			local szKey = sformat("%d_%d", v.dwTabType, v.nItemID)

			local magicAttrib = GetItemMagicAttrib(itemInfo.GetMagicAttribIndexList())
			local tAttribute = {}
			for k2, v2 in pairs(magicAttrib) do
				local szText = ""
				if LR_ATTRIBUTE_nID[v2.nID] == nil then
					if v2.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
						--
					elseif v2.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then
						--
					else
						FormatAttributeValue(v2)
						szText = FormatString(Table_GetMagicAttributeInfo(v2.nID, false), v2.Param0, v2.Param1, v2.Param2, v2.Param3) or ""
					end
					for k3, v3 in pairs (LR_ATTRIBUTE) do
						--Output(itemInfo.szName, szText, v3)
						if sfind(szText, LR_ATTRIBUTE_TEXT[v3]) then
							LR_ATTRIBUTE_nID[v2.nID] = v3
						end
					end
					if LR_ATTRIBUTE_nID[v2.nID] == nil then
						LR_ATTRIBUTE_nID[v2.nID] = 0
					end
				end
				if LR_ATTRIBUTE_nID[v2.nID] > 0 then
					tAttribute[#tAttribute + 1] = sformat("A%d,", LR_ATTRIBUTE_nID[v2.nID])
				end
			end
			szAttribute = tconcat(tAttribute, "")

			local nRequireLevel = 0
			if v.dwTabType ~= ITEM_TABLE_TYPE.OTHER then
				local requireAttrib = itemInfo.GetRequireAttrib() or {}
				for k, v in pairs(requireAttrib) do
					if v.nID == 5 then
						nRequireLevel = v.nValue
					end
				end
			end

			DB_REPLACE:ClearBindings()
			--DB_REPLACE:BindAll(szKey, v.dwTabType, v.nItemID, v.nLevel, v.nAucType, AnsiToUTF8(v.szName), v.nSchoolID, v.nSetID, AnsiToUTF8(v.szMagicKind), AnsiToUTF8(v.szMagicType), AnsiToUTF8(v.szSourceType), v.szPvePvp, AnsiToUTF8(v.szSourceForce), AnsiToUTF8(v.szSourceDesc), v.szBelongMapID, v.szPrestigeRequire)
			DB_REPLACE:BindAll(szKey, v.dwTabType, v.nItemID, v.nLevel, v.nAucType, AnsiToUTF8(v.szName), v.nSchoolID, v.nSetID, (v.szMagicKind), (v.szMagicType), AnsiToUTF8(v.szSourceType), v.szPvePvp, AnsiToUTF8(v.szSourceForce), AnsiToUTF8(v.szSourceDesc), v.szBelongMapID, v.szPrestigeRequire, nRecommendID, nGenre, nSub, nDetail, nQuality, nBindType, szAttribute, nRequireLevel)
			DB_REPLACE:Execute()
		end
	end

	LR.CloseDB(DB)
	LR.SysMsg(sformat(_L["Cost %0.3f s\n"], (GetTickCount() - tTime) * 1.0 / 1000))
end

function LR_EquipSearch.SEARCH(nPage)
	local nPage = nPage or 0
	local SQL = "FROM equip_data"
	local tCondition = {}
	local szCondition = ""
	local EquipName = LR_EquipSearch_Panel:Fetch("Edit_EquipName"):GetText()
	if LR.Trim(EquipName) ~= "" then
		LR_EquipSearch_Panel.EquipName = EquipName
		tCondition[#tCondition + 1] = sformat("szName like '%%%s%%'", AnsiToUTF8(EquipName))
	end
	if LR_EquipSearch_Panel.Quality > -1 then
		tCondition[#tCondition + 1] = sformat("nQuality = %d", LR_EquipSearch_Panel.Quality)
	end
	if LR_EquipSearch_Panel.Recommend > 1 then
		tCondition[#tCondition + 1] = sformat("nRecommendID = %d", LR_EquipSearch_Panel.Recommend)
	end
	local RequireLevel_Low = LR_EquipSearch_Panel:Fetch("Edit_EquipRequireLevel_Low"):GetText()
	if type(tonumber(LR.Trim(RequireLevel_Low))) == "number" then
		LR_EquipSearch_Panel.RequireLevel_Low = RequireLevel_Low
		tCondition[#tCondition + 1] = sformat("nRequireLevel >= %d", RequireLevel_Low)
	end
	local RequireLevel_High = LR_EquipSearch_Panel:Fetch("Edit_EquipRequireLevel_High"):GetText()
	if type(tonumber(LR.Trim(RequireLevel_High))) == "number" then
		LR_EquipSearch_Panel.RequireLevel_High = RequireLevel_High
		tCondition[#tCondition + 1] = sformat("nRequireLevel <= %d", RequireLevel_High)
	end
	local EquipLevel_Low = LR_EquipSearch_Panel:Fetch("Edit_EquipLevel_Low"):GetText()
	if type(tonumber(LR.Trim(EquipLevel_Low))) == "number" then
		LR_EquipSearch_Panel.RequireLevel_Low = EquipLevel_Low
		tCondition[#tCondition + 1] = sformat("nLevel >= %d", EquipLevel_Low)
	end
	local EquipLevel_High = LR_EquipSearch_Panel:Fetch("Edit_EquipLevel_High"):GetText()
	if type(tonumber(LR.Trim(EquipLevel_High))) == "number" then
		LR_EquipSearch_Panel.EquipLevel_High = EquipLevel_High
		tCondition[#tCondition + 1] = sformat("nLevel <= %d", EquipLevel_High)
	end
	if LR_EquipSearch_Panel.EquipType ~= "" then
		tCondition[#tCondition + 1] = LR_EquipSearch_Panel.EquipType
	end
	if next(LR_EquipSearch_Panel.EquipAttribut) ~= nil then
		local tAttribute = {}
		for k, v in pairs (LR_EquipSearch_Panel.EquipAttribut) do
			if v then
				tAttribute[#tAttribute+1] = sformat("szAttribute LIKE '%%%s%%'", sformat("A%d,", k))
			end
		end
		local szAttribute = tconcat(tAttribute, " AND ")
		if szAttribute ~= "" then
			tCondition[#tCondition + 1] = szAttribute
		end
	end
	if next(LR_EquipSearch_Panel.EquipAttributNot) ~= nil then
		local tAttribute = {}
		for k, v in pairs (LR_EquipSearch_Panel.EquipAttributNot) do
			if v then
				tAttribute[#tAttribute+1] = sformat("szAttribute not LIKE '%%%s%%'", sformat("A%d,", k))
			end
		end
		local szAttribute = tconcat(tAttribute, " AND ")
		if szAttribute ~= "" then
			tCondition[#tCondition + 1] = szAttribute
		end
	end

	szCondition = tconcat(tCondition, " AND ")
	if szCondition ~="" then
		SQL = sformat("%s WHERE %s", SQL, szCondition)
	end
	SQL = sformat("%s ORDER BY nLevel %s, nQuality DESC, nSub ASC, nDetail ASC, szName ASC", SQL, LR_EquipSearch_Panel.Order)

	local DB = LR.OpenDB(DB_Path, "8A518302E1BD70EAFB506626852A0867")
	local SQL2 = sformat("SELECT COUNT( * ) AS COUNT %s", SQL)
	--Output("SQL2", SQL2)
	local DB_SELECT2 = DB:Prepare(SQL2)
	local data2 = DB_SELECT2:GetAll() or {}
	nPage = mmax(nPage, 1)
	LR_EquipSearch_Panel.nCount = data2[1].COUNT
	LR_EquipSearch_Panel.nTotalPage = mfloor((LR_EquipSearch_Panel.nCount - 1)/20) + 1
	LR_EquipSearch_Panel.nLastPage = LR_EquipSearch_Panel.nTotalPage
	LR_EquipSearch_Panel.nPage = mmin(nPage, LR_EquipSearch_Panel.nTotalPage)
	LR_EquipSearch_Panel.nPrePage = mmax((LR_EquipSearch_Panel.nPage - 1), 1)
	LR_EquipSearch_Panel.nNextPage = mmin((LR_EquipSearch_Panel.nPage + 1), LR_EquipSearch_Panel.nTotalPage)


	SQL = sformat("SELECT * %s LIMIT 20 OFFSET %d", SQL, (nPage - 1) * 20)
	--Output("SQL", SQL)
	local DB_SELECT = DB:Prepare(SQL)
	local Data = DB_SELECT:GetAll() or {}

	LR.CloseDB(DB)

	LR_EquipSearch.RESULT = clone(Data)
end
----------------------------------------------------------------
------界面
----------------------------------------------------------------
LR_EquipSearch_Panel = CreateAddon("LR_EquipSearch_Panel")
LR_EquipSearch_Panel:BindEvent("OnFrameDestroy", "OnDestroy")

LR_EquipSearch_Panel.UsrData = {
	Anchor = {s = "CENTER", r = "CENTER", x = 0, y = 0},
}

LR_EquipSearch_Panel.EquipName = ""
LR_EquipSearch_Panel.Quality = -1
LR_EquipSearch_Panel.Recommend = 1
LR_EquipSearch_Panel.RequireLevel_Low = ""
LR_EquipSearch_Panel.RequireLevel_High = ""
LR_EquipSearch_Panel.EquipLevel_Low = ""
LR_EquipSearch_Panel.EquipLevel_High = ""
LR_EquipSearch_Panel.Order = "ASC"
LR_EquipSearch_Panel.EquipType = ""
LR_EquipSearch_Panel.EquipAttribut = {}
LR_EquipSearch_Panel.EquipAttributNot = {}
LR_EquipSearch_Panel.nPage = 1
LR_EquipSearch_Panel.nPrePage = 1
LR_EquipSearch_Panel.nNextPage = 1
LR_EquipSearch_Panel.nFirstPage = 1
LR_EquipSearch_Panel.nLastPage = 1
LR_EquipSearch_Panel.nTotalPage = 1
LR_EquipSearch_Panel.nCount = 0
LR_EquipSearch_Panel.hClicked = nil

function LR_EquipSearch_Panel:OnCreate()
	this:RegisterEvent("UI_SCALED")

	LR_EquipSearch_Panel.UpdateAnchor(this)
	RegisterGlobalEsc("LR_EquipSearch_Panel", function () return true end , function() LR_EquipSearch_Panel:Open() end)

	LR_EquipSearch_Panel.EquipName = ""
	LR_EquipSearch_Panel.Quality = -1
	LR_EquipSearch_Panel.Recommend = 1
	LR_EquipSearch_Panel.RequireLevel_Low = ""
	LR_EquipSearch_Panel.RequireLevel_High = ""
	LR_EquipSearch_Panel.EquipLevel_Low = ""
	LR_EquipSearch_Panel.EquipLevel_High = ""
	LR_EquipSearch_Panel.Order = "ASC"
	LR_EquipSearch_Panel.EquipType = ""
	LR_EquipSearch_Panel.EquipAttribut = {}
	LR_EquipSearch_Panel.EquipAttributNot ={}

	LR_EquipSearch_Panel.nPage = 1
	LR_EquipSearch_Panel.nPrePage = 1
	LR_EquipSearch_Panel.nNextPage = 1
	LR_EquipSearch_Panel.nFirstPage = 1
	LR_EquipSearch_Panel.nLastPage = 1
	LR_EquipSearch_Panel.nTotalPage = 1
	LR_EquipSearch_Panel.nCount = 0

	LR_EquipSearch.RESULT = {}
	LR_EquipSearch.CheckDB()
	GET_LR_EQUIP_TYPE()
end

function LR_EquipSearch_Panel:OnEvents(event)
	if event ==  "UI_SCALED" then
		LR_EquipSearch_Panel.UpdateAnchor(this)
	end
end

function LR_EquipSearch_Panel.UpdateAnchor(frame)
	frame:CorrectPos()
	frame:SetPoint(LR_EquipSearch_Panel.UsrData.Anchor.s, 0, 0, LR_EquipSearch_Panel.UsrData.Anchor.r, LR_EquipSearch_Panel.UsrData.Anchor.x, LR_EquipSearch_Panel.UsrData.Anchor.y)
end

function LR_EquipSearch_Panel:OnDestroy()
	UnRegisterGlobalEsc("LR_EquipSearch_Panel")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_EquipSearch_Panel:OnDragEnd()
	this:CorrectPos()
	LR_EquipSearch_Panel.UsrData.Anchor = GetFrameAnchor(this)
end

function LR_EquipSearch_Panel:Init()
	local frame = self:Append("Frame", "LR_EquipSearch_Panel", {title = _L["LR_EQUIP_SEARCH"], style = "LARGER"})
	local imgTab = self:Append("Image", frame, "TabImg", {w = 962, h = 33, x = 0, y = 50})
    imgTab:SetImage("ui\\Image\\UICommon\\ActivePopularize2.UITex", 46)
	imgTab:SetImageType(11)
	local hComboBoxMenu = self:Append("ComboBox", frame, "hComboBoxMenu", {w = 160, x = 20, y = 51, text = _L["Equip Search"]})
	hComboBoxMenu.OnClick = function(m)
		m[#m+1] = {szOption = _L["Reinitialize plug-in manually"],
			fnAction = function()
				local msg = {
					szMessage = _L["Are you sure to reinitial plug-in?"],
					szName = "initial",
					fnAutoClose = function() return false end,
					{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() LR_EquipSearch.IniDB() end, },
					{szOption = g_tStrings.STR_HOTKEY_CANCEL,},
				}
				MessageBox(msg)
			end,
		}
		m[#m+1] = {szOption = _L["Exit"],
			fnAction = function()
				LR_EquipSearch_Panel:Close()
			end,
		}
		PopupMenu(m)
	end

	local Text_EquipName = self:Append("Text", frame, "Text_EquipName", {w = 160, h = 24, x = 20, y = 90, text = _L["Equip Name"] })
	local Edit_EquipName = self:Append("Edit", frame, "Edit_EquipName", {w = 160, h = 24, x = 20, y = 110, text = LR_EquipSearch_Panel.EquipName })

	local Text_EquipRequireLevel = self:Append("Text", frame, "Text_EquipRequireLevel", {w = 160, h = 24, x = 20, y = 140, text = _L["Equip Require Level"] })
	local Edit_EquipRequireLevel_low = self:Append("Edit", frame, "Edit_EquipRequireLevel_Low", {w = 40, h = 24, x = 20, y = 160, text = LR_EquipSearch_Panel.RequireLevel_Low})
	local Text_EquipRequireLevel_Divide = self:Append("Text", frame, "Text_EquipRequireLevel_Divide", {w = 160, h = 24, x = 66, y = 160, text = "—" })
	local Edit_EquipRequireLevel_high = self:Append("Edit", frame, "Edit_EquipRequireLevel_High", {w = 40, h = 24, x = 80, y = 160, text = LR_EquipSearch_Panel.RequireLevel_High})

	local Text_EquipLevel = self:Append("Text", frame, "Text_EquipLevel", {w = 160, h = 24, x = 20, y = 190, text = _L["Equip Level"] })
	local Edit_EquipLevel_low = self:Append("Edit", frame, "Edit_EquipLevel_Low", {w = 40, h = 24, x = 20, y = 210, text = LR_EquipSearch_Panel.EquipLevel_Low })
	local Text_EquipLevel_Divide = self:Append("Text", frame, "Text_EquipLevel_Divide", {w = 160, h = 24, x = 66, y = 210, text = "—" })
	local Edit_EquipLevel_high = self:Append("Edit", frame, "Edit_EquipLevel_High", {w = 40, h = 24, x = 80, y = 210, text = LR_EquipSearch_Panel.EquipLevel_High })

	local Text_EquipnQuality = self:Append("Text", frame, "Text_EquipnQuality", {w = 160, h = 24, x = 20, y = 240, text = _L["Equip Quality"] })
	local ComboBox_EquipnQuality = self:Append("ComboBox", frame, "ComboBox_EquipnQuality", {w = 160, x = 20, y = 260, text = LR_QUALITY_TEXT[LR_EquipSearch_Panel.Quality] })
	ComboBox_EquipnQuality:Enable(true)
	ComboBox_EquipnQuality.OnClick = function (m)
		for k = -1, 5, 1 do
			local rgb = {255, 255, 255}
			if k > -1 then
				rgb = {GetItemFontColorByQuality(k, false)}
			end
			m[#m + 1] = {szOption = LR_QUALITY_TEXT[k],
				fnAction = function()
					LR_EquipSearch_Panel.Quality = k
					ComboBox_EquipnQuality:SetText(LR_QUALITY_TEXT[k])
				end,
				rgb = rgb,
			}
		end
		PopupMenu(m)
	end

	local Text_RecommendKungfu = self:Append("Text", frame, "Text_RecommendKungfu", {w = 160, h = 24, x = 20, y = 290, text = _L["Equip Recommend Kungfu"] })
	local ComboBox_RecommendKungfu = self:Append("ComboBox", frame, "ComboBox_RecommendKungfu", {w = 160, x = 20, y = 310, text = LR_RECOMMEND_TEXT[LR_EquipSearch_Panel.Recommend] })
	ComboBox_RecommendKungfu:Enable(true)
	ComboBox_RecommendKungfu.OnClick = function (m)
		for k, v in pairs (LR_RECOMMEND_TEXT) do
			m[#m + 1] = {szOption = v,
				fnAction = function()
					LR_EquipSearch_Panel.Recommend = k
					ComboBox_RecommendKungfu:SetText(v)
				end
			}
		end
		PopupMenu(m)
	end

	local Text_Attribute = self:Append("Text", frame, "Text_Attribute", {w = 160, h = 24, x = 20, y = 340, text = _L["Equip Attribute"] })
	local ComboBox_Attribute = self:Append("ComboBox", frame, "ComboBox_Attribute", {w = 160, x = 20, y = 360, text = _L["Any Attribute"] })
	ComboBox_Attribute.tip = ""
	local SetComboBox_AttributeText = function()
		local tText = {}
		for k, v in pairs(LR_EquipSearch_Panel.EquipAttribut) do
			if v then
				tText[#tText+1] = LR_ATTRIBUTE_TEXT[k]
			end
		end
		local szText1 = tconcat(tText,",")
		tText = {}
		for k, v in pairs(LR_EquipSearch_Panel.EquipAttributNot) do
			if v then
				tText[#tText+1] = LR_ATTRIBUTE_TEXT[k]
			end
		end
		local szText2 = tconcat(tText,",")
		local szText = ""
		if szText2 ~= "" then
			szText = sformat("%s %s %s", szText1, _L["NOT CONTAIN"], szText2)
		else
			szText = szText1
		end
		if szText == "" then
			ComboBox_Attribute:SetText(_L["Any Attribute"])
		else
			ComboBox_Attribute:SetText(szText)
		end
		return szText
	end
	ComboBox_Attribute:Enable(true)
	ComboBox_Attribute.OnClick = function (m)
		m[#m+1] = { szOption = _L["Any Attribute"],
			fnAction = function()
				LR_EquipSearch_Panel.EquipAttribut = {}
				ComboBox_Attribute:SetText(_L["Any Attribute"])
			end,
		}
		m[#m+1] = {bDevide = true,}
		m[#m+1] = {szOption = _L["CONTAIN"] , fnDisable = function() return true end}
		for v = 1, 12, 1 do
			m[#m+1] = { szOption = LR_ATTRIBUTE_TEXT[v], bCheck = true, bMCheck = false, bChecked = function() return LR_EquipSearch_Panel.EquipAttribut[v] end,
				fnAction = function()
					LR_EquipSearch_Panel.EquipAttribut[v] = not LR_EquipSearch_Panel.EquipAttribut[v]
					if not LR_EquipSearch_Panel.EquipAttribut[v] then
						LR_EquipSearch_Panel.EquipAttribut[v] = nil
					end
					ComboBox_Attribute.tip = SetComboBox_AttributeText()
				end,
			}
		end
		m[#m+1] = {bDevide = true,}
		m[#m+1] = {szOption = _L["NOT CONTAIN"] , fnDisable = function() return true end}
		local x = {LR_ATTRIBUTE.NEI_FANG, LR_ATTRIBUTE.SHAN_BI, LR_ATTRIBUTE.ZHAO_JIA, LR_ATTRIBUTE.HUI_XIN, LR_ATTRIBUTE.JIA_SU, LR_ATTRIBUTE.HUA_JIN}
		for k, v in pairs (x) do
			m[#m+1] = { szOption = LR_ATTRIBUTE_TEXT[v], bCheck = true, bMCheck = false, bChecked = function() return LR_EquipSearch_Panel.EquipAttributNot[v] end,
				fnAction = function()
					LR_EquipSearch_Panel.EquipAttributNot[v] = not LR_EquipSearch_Panel.EquipAttributNot[v]
					if not LR_EquipSearch_Panel.EquipAttributNot[v] then
						LR_EquipSearch_Panel.EquipAttributNot[v] = nil
					end
					ComboBox_Attribute.tip = SetComboBox_AttributeText()
				end,
			}
		end
		PopupMenu(m)
	end
	ComboBox_Attribute.OnEnter = function()
		local x, y =  ComboBox_Attribute:GetAbsPos()
		local w, h = ComboBox_Attribute:GetSize()
		local szTip = {}
		szTip[#szTip+1] = GetFormatText(_L["Multiple conditions can be checked"], 7 )
		if ComboBox_Attribute.tip ~= "" then
			szTip[#szTip+1] = GetFormatText(sformat("%s：%s",_L["Conditions"], ComboBox_Attribute.tip), 7 )
		end
		OutputTip(tconcat(szTip), 350, {x, y, 0, 0})
	end
	ComboBox_Attribute.OnLeave = function()
		HideTip()
	end


	local Text_EquipPart = self:Append("Text", frame, "Text_EquipPart", {w = 160, h = 24, x = 20, y = 390, text = _L["Equip Part"] })
	local ComboBox_EquipPart = self:Append("ComboBox", frame, "ComboBox_EquipPart", {w = 160, x = 20, y = 410, text = _L["Any Type"] })
	ComboBox_EquipPart:Enable(true)
	ComboBox_EquipPart.OnClick = function (m)
		m[#m+1] = {szOption = _L["Any Type"], fnAction =
			function()
				LR_EquipSearch_Panel.EquipType = ""
				ComboBox_EquipPart:SetText(_L["Any Type"])
			end,
		}
		m[#m+1] = {bDevide = true,}
		for k, v in pairs(LR_EQUIP_TYPE) do
			m[#m+1] = {szOption = k}
			local t = m[#m]
			for k2, v2 in pairs(v) do
				t[#t+1] = {szOption = k2,
					fnAction = function()
						LR_EquipSearch_Panel.EquipType = v2
						ComboBox_EquipPart:SetText(k2)
					end
				}
			end
		end
		PopupMenu(m)
	end


	local hPageSet = self:Append("PageSet", frame, "PageSet01", {x = 220, y = 120, w = 700, h = 350})
	local hWinIconView = self:Append("Window", hPageSet, "WindowItemView", {x = 4, y = 0, w = 700, h = 350})
	local hScroll = self:Append("Scroll", hWinIconView, "Scroll", {x = 0, y = 0, w = 700, h = 350})

	local hPageSet2 = self:Append("PageSet", frame, "PageSet01", {x = 347, y = 470, w = 580, h = 70})
	local hWinIconView2 = self:Append("Window", hPageSet2, "WindowItemView2", {x = 0, y = 0, w = 580, h = 70})
	local hHandle_Source = self:Append("Scroll", hWinIconView2, "hHandle_Source", {x = 0, y = 0, w = 580, h = 70})
	hHandle_Source:UpdateList()
	--local hHandle_Source = self:Append("Handle", hHandle, "hHandle_Source", {x = 130, y = 377, w = 560, h = 70,})
	-------------初始界面物品
	local hHandle = self:Append("Handle", frame, "Handle", {x = 218, y = 90, w = 700, h = 380})

	local Image_Record_BG = self:Append("Image", hHandle, "Image_Record_BG", {x = 0, y = 0, w = 700, h = 380})
	Image_Record_BG:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 50)
	Image_Record_BG:SetImageType(10)

	local Image_Record_BG1 = self:Append("Image", hHandle, "Image_Record_BG1", {x = 0, y = 30, w = 700, h = 350})
	Image_Record_BG1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 74)
	Image_Record_BG1:SetImageType(10)
	Image_Record_BG1:SetAlpha(110)

	local Image_Record_BG2 = self:Append("Image", hHandle, "Image_Record_BG2", {x = 0, y = 375, w = 700, h = 75})
	Image_Record_BG2:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 50)
	Image_Record_BG2:SetImageType(10)
	Image_Record_BG2:SetAlpha(110)

	local Image_Record_Break1 = self:Append("Image", hHandle, "Image_Record_Break1", {x = 120, y = 377, w = 4, h = 70})
	Image_Record_Break1:FromUITex("ui\\Image\\Minimap\\MapMark.UITex", 48)
	Image_Record_Break1:SetImageType(11)
	Image_Record_Break1:SetAlpha(220)

	local Text_Result = self:Append("Text", hHandle, "Text_Result", {x = 10, y = 2, w = 80, h = 30, text = _L["Search Result"]})
	local Text_Source = self:Append("Text", hHandle, "Text_Result", {x = 0, y = 377, w = 120, h = 70, text = _L["Equip Source"]})
	Text_Source:SetHAlign(1)
	Text_Source:SetVAlign(1)

	local ComboBox_Sort = self:Append("ComboBox", frame, "ComboBox_Sort", {w = 100, x = 310, y = 94, text = _L[LR_EquipSearch_Panel.Order] })
	ComboBox_Sort:Enable(true)
	ComboBox_Sort.OnClick = function (m)
		local szOption = {"ASC", "DESC"}
		local szText = {_L["ASC"], _L["DESC"]}
		for k, v in pairs (szOption) do
			m[#m+1] = {szOption = szText[k], bCheck = true, bMCheck = true, bChecked = function() return LR_EquipSearch_Panel.Order == v end,
				fnAction = function()
					LR_EquipSearch_Panel.Order = v
					if LR_EquipSearch_Panel.nCount > 0 then
						LR_EquipSearch.SEARCH()
						LR_EquipSearch_Panel:ReloadItemBox()
					end
					ComboBox_Sort:SetText(_L[LR_EquipSearch_Panel.Order])
				end,
			}
		end
		PopupMenu(m)
	end

	local Wnd_SearchBTN =	self:Append("Window", frame, "Wnd_SearchBTN", {w = 200, h = 80, x = 20, y = 470, })
	local BTN_SEARCH = self:Append("Button", Wnd_SearchBTN, "BTN_SEARCH", {text = _L["SEARCH"] , x = 0, y = 0, w = 70, h = 36})
	BTN_SEARCH.OnClick = function()
		LR_EquipSearch.SEARCH()
		LR_EquipSearch_Panel:ReloadItemBox()
	end
	local BTN_RESET = self:Append("Button", Wnd_SearchBTN, "BTN_RESET", {text = _L["RESET"] , x = 100, y = 0, w = 70, h = 36})
	BTN_RESET.OnClick = function()
		LR_EquipSearch_Panel.EquipName = ""
		LR_EquipSearch_Panel.Quality = -1
		LR_EquipSearch_Panel.Recommend = 1
		LR_EquipSearch_Panel.RequireLevel_Low = ""
		LR_EquipSearch_Panel.RequireLevel_High = ""
		LR_EquipSearch_Panel.EquipLevel_Low = ""
		LR_EquipSearch_Panel.EquipLevel_High = ""
		LR_EquipSearch_Panel.Order = "ASC"
		LR_EquipSearch_Panel.EquipType = ""
		LR_EquipSearch_Panel.EquipAttribut = {}

		Edit_EquipName:SetText(LR_EquipSearch_Panel.EquipName)
		Edit_EquipRequireLevel_low:SetText(LR_EquipSearch_Panel.RequireLevel_Low)
		Edit_EquipRequireLevel_high:SetText(LR_EquipSearch_Panel.RequireLevel_High)
		Edit_EquipLevel_low:SetText(LR_EquipSearch_Panel.EquipLevel_Low)
		Edit_EquipLevel_high:SetText(LR_EquipSearch_Panel.EquipLevel_High)
		ComboBox_EquipnQuality:SetText(LR_QUALITY_TEXT[LR_EquipSearch_Panel.Quality])
		ComboBox_RecommendKungfu:SetText(LR_RECOMMEND_TEXT[LR_EquipSearch_Panel.Recommend])
		ComboBox_Attribute:SetText(_L["Any Attribute"])
		ComboBox_EquipPart:SetText(_L["Any Type"])

		ComboBox_Attribute.tip = ""
	end

	local Wnd_PageBTN =	self:Append("Window", frame, "Wnd_PageBTN", {w = 750, h = 80, x = 220, y = 550, })
	--创建一个按钮
	local BTN_FIRST = self:Append("Button", Wnd_PageBTN, "BTN_FIRST", {text = _L["FIRST"] , x = 0, y = 0, w = 95, h = 36})
	BTN_FIRST.OnClick = function()
		LR_EquipSearch.SEARCH(LR_EquipSearch_Panel.nFirstPage)
		LR_EquipSearch_Panel:ReloadItemBox()
	end
	local BTN_PRE = self:Append("Button", Wnd_PageBTN, "BTN_PRE", {text = _L["PRE"] , x = 100, y = 0, w = 95, h = 36})
	BTN_PRE.OnClick = function()
		LR_EquipSearch.SEARCH(LR_EquipSearch_Panel.nPrePage)
		LR_EquipSearch_Panel:ReloadItemBox()
	end
	local BTN_NEXT = self:Append("Button", Wnd_PageBTN, "BTN_NEXT", {text = _L["NEXT"] , x = 200, y = 0, w = 95, h = 36})
	BTN_NEXT.OnClick = function()
		LR_EquipSearch.SEARCH(LR_EquipSearch_Panel.nNextPage)
		LR_EquipSearch_Panel:ReloadItemBox()
	end
	local BTN_LAST = self:Append("Button", Wnd_PageBTN, "BTN_LAST", {text = _L["LAST"] , x = 300, y = 0, w = 95, h = 36})
	BTN_LAST.OnClick = function()
		LR_EquipSearch.SEARCH(LR_EquipSearch_Panel.nLastPage)
		LR_EquipSearch_Panel:ReloadItemBox()
	end
	local EDIT_PAGE = self:Append("Edit", Wnd_PageBTN, "EDIT_PAGE", {w = 60, h = 24, x = 400, y = 6, text = "0", font = 22})
	local BTN_OK = self:Append("Button", Wnd_PageBTN, "BTN_OK", {text = _L["Yes"] , x = 465, y = 0, w = 95, h = 36})
	BTN_OK.OnClick = function()
		local nPage = tonumber(EDIT_PAGE:GetText())
		if type(nPage) ~= "number" then
			return
		end
		LR_EquipSearch.SEARCH(nPage)
		LR_EquipSearch_Panel:ReloadItemBox()
	end
	local TEXT_PAGE = self:Append("Text", Wnd_PageBTN, "TEXT_PAGE", {w = 400, h = 24, x = 5, y = 40, text = "", font = 2})

	---显示数据
	self:LoadItemBox(hScroll)
	hScroll:UpdateList()

	----------关于
	LR.AppendAbout(LR_EquipSearch_Panel, frame)
end

function LR_EquipSearch_Panel:Open()
	local frame = self:Fetch("LR_EquipSearch_Panel")
	if frame then
		self:Destroy(frame)
	else
		frame = self:Init()
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

function LR_EquipSearch_Panel:Close()
	local frame = self:Fetch("LR_EquipSearch_Panel")
	if frame then
		self:Destroy(frame)
	end
end

function LR_EquipSearch_Panel:LoadItemBox(hWin)
	local data = LR_EquipSearch.RESULT or {}
	LR_EquipSearch_Panel.hClicked = nil
	for k, v in pairs (data) do
		local dwTabType = v.dwTabType
		local dwIndex = v.dwIndex
		local itemInfo = GetItemInfo(dwTabType, dwIndex)
		if itemInfo then
			local handle = LR.AppendUI("Handle", hWin, sformat("Handle_Box", k), {w = 170, h = 70})
			local Image_Bg = LR.AppendUI("Image", handle, "Image_BG", {x = 0, y = 0, w = 165, h = 65})
			Image_Bg:FromUITex("ui\\Image\\Common\\CommonPanel.UITex",63)
			Image_Bg:SetAlpha(100)

			local Icon_Item = LR.AppendUI("Image", handle, "Icon_Item", {w = 50 , h = 50, x = 7, y = 7,})
			local nUiId = itemInfo.nUiId
			local nIconID = Table_GetItemIconID(nUiId)
			Icon_Item:FromIconID(nIconID)

			local nQuality =  itemInfo.nQuality
			if nQuality == 5 then
				local OrangeBox =  LR.AppendUI("Animate", handle, "OrangeBox", {w = 50 , h = 50, x = 7, y = 7,})
				OrangeBox:SetAnimate("ui\\Image\\Common\\Box.UITex",17)
			else
				local Box_Quality = LR.AppendUI("Image", handle, "Box_Quality", {w = 50 , h = 50, x = 7, y = 7,})
				if nQuality == 4 then
					Box_Quality:FromUITex("ui\\Image\\Common\\Box.UITex",42)
				elseif nQuality == 3 then
					Box_Quality:FromUITex("ui\\Image\\Common\\Box.UITex",43)
				elseif nQuality == 2 then
					Box_Quality:FromUITex("ui\\Image\\Common\\Box.UITex",13)
				else
					Box_Quality:FromUITex("ui\\Image\\Common\\Box.UITex",0)
				end
			end

			local Text_Name = LR.AppendUI("Text", handle, "Text_Name", {w = 100 , h = 20, x = 65, y = 2, text = itemInfo.szName})
			Text_Name:SetFontColor(GetItemFontColorByQuality(itemInfo.nQuality, false))

			local szPart = g_tStrings.tEquipTypeNameTable[itemInfo.nSub]
			if itemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON or	itemInfo.nSub == EQUIPMENT_SUB.RANGE_WEAPON or itemInfo.nSub == EQUIPMENT_SUB.ARROW then
				szPart = sformat("%s", GetWeapenType(itemInfo.nDetail))
			elseif itemInfo.nSub == EQUIPMENT_SUB.AMULET or itemInfo.nSub == EQUIPMENT_SUB.RING or itemInfo.nSub == EQUIPMENT_SUB.PENDANT then
				--饰品
			elseif itemInfo.nSub == EQUIPMENT_SUB.PACKAGE then
				--包裹
			elseif itemInfo.nSub == EQUIPMENT_SUB.BULLET then
				szPart = sformat("%s(%s)", szPart, g_tStrings.tBulletDetail[itemInfo.nDetail] or g_tStrings.UNKNOWN_WEAPON)
			else
				--防具
			end
			local Text_Part = LR.AppendUI("Text", handle, "Text_Part", {w = 100 , h = 20, x = 65, y = 22, text = szPart})
			local szEq_Level = sformat(_L["%dP"], v.nLevel)
			if v.nRequireLevel > 0 then
				szEq_Level = sformat("%s，%s", szEq_Level, sformat(_L["%dL"], v.nRequireLevel))
			end
			local Text_Level = LR.AppendUI("Text", handle, "Text_Level", {w = 100 , h = 20, x = 65, y = 42, text = szEq_Level})

			local Bg_Hover = LR.AppendUI("Image", handle, "Bg_Hover", {w = 165, h = 65,})
			Bg_Hover:SetImageType(10)
			Bg_Hover:FromUITex("ui\\Image\\Common\\Box.UITex",9)
			Bg_Hover:Hide()
			self.Bg_Hover = Bg_Hover

			local Bg_Select = LR.AppendUI("Image", handle, "Bg_Select", {w = 165, h = 65,})
			Bg_Select:SetImageType(10)
			Bg_Select:FromUITex("ui\\Image\\Common\\Box.UITex",10)
			Bg_Select:Hide()

			handle:GetHandle():RegisterEvent(4194303)
			handle:GetHandle().OnItemLButtonClick = function()	--等效于 Handle:OnClick()
				if IsCtrlKeyDown() then
					EditBox_AppendLinkItemInfo(1, dwTabType, dwIndex, 0)
				elseif IsAltKeyDown() then
					Addon_ExteriorViewByItemInfo(dwTabType, dwIndex)
				else
					if LR_EquipSearch_Panel.hClicked then
						LR_EquipSearch_Panel.hClicked:Hide()
					end
					LR_EquipSearch_Panel:OutputSouce(v)
					Bg_Select:Show()
					LR_EquipSearch_Panel.hClicked = Bg_Select
					--Output("nSub = " .. itemInfo.nSub, "nDetail = " .. itemInfo.nDetail)
					--Output(UTF8ToAnsi(v.szSourceType), UTF8ToAnsi(v.szSourceForce), UTF8ToAnsi(v.szSourceDesc), UTF8ToAnsi(v.szBelongMapID), UTF8ToAnsi(v.szPrestigeRequire))
				end
			end
			handle.OnEnter = function()	--等效于Handle:GetHandle().OnItemMouseEnter()
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				if  itemInfo.nGenre and itemInfo.nGenre == ITEM_GENRE.BOOK then
					if itemInfo.nBookID then
						local dwBookID, dwSegmentID = GlobelRecipeID2BookID(itemInfo.nBookID)
						OutputBookTipByID(dwBookID, dwSegmentID, {x, y, w, h,})
					end
				else
					if IsCtrlKeyDown() and IsAltKeyDown() then
						local tText = {}
						tText[#tText + 1] = GetFormatText(sformat("dwTabType:%d\n", dwTabType))
						tText[#tText + 1] = GetFormatText(sformat("dwIndex:%d\n", dwIndex))
						tText[#tText + 1] = GetFormatText(sformat("nSub:%d (%s)\n", v.nSub, g_tStrings.tEquipTypeNameTable[v.nSub]))
						tText[#tText + 1] = GetFormatText(sformat("nDetail:%d (%s)\n", v.nDetail, GetWeapenType(v.nDetail)))
						tText[#tText + 1] = GetFormatText(sformat("nUiId:%d\n", itemInfo.nUiId))
						tText[#tText + 1] = GetFormatText(sformat("nQuality:%d\n", v.nQuality))
						tText[#tText + 1] = GetFormatText(sformat("nRequireLevel:%d\n", v.nRequireLevel))
						tText[#tText + 1] = GetFormatText(sformat("nLevel:%d\n", v.nLevel))

						OutputTip(tconcat(tText), 300, {x, y, w, h})
					else
						OutputItemTip(UI_OBJECT_ITEM_INFO, 1, dwTabType, dwIndex, {x, y, w, h,})
					end
				end
				Bg_Hover:Show()
			end
			handle.OnLeave = function()
				HideTip()
				Bg_Hover:Hide()
			end
		end
	end

	LR_EquipSearch_Panel:RefreshBTN_PAGE()
end

function LR_EquipSearch_Panel:ReloadItemBox()
	local cc = self:Fetch("Scroll")
	if cc then
		self:ClearHandle(cc)
	end
	self:LoadItemBox(cc)
end

function LR_EquipSearch_Panel:RefreshBTN_PAGE()
	local frame = Station.Lookup("Normal/LR_EquipSearch_Panel")
	if not frame then
		return
	end
	local BTN_FIRST = self:Fetch("BTN_FIRST"):Enable(false)
	local BTN_PRE = self:Fetch("BTN_PRE"):Enable(false)
	local BTN_NEXT = self:Fetch("BTN_NEXT"):Enable(false)
	local BTN_LAST = self:Fetch("BTN_LAST"):Enable(false)
	local BTN_OK = self:Fetch("BTN_OK"):Enable(false)
	local TEXT_PAGE = self:Fetch("TEXT_PAGE"):SetText("")
	local EDIT_PAGE = self:Fetch("EDIT_PAGE"):SetText("0")

	if LR_EquipSearch_Panel.nTotalPage > 1 then
		BTN_OK:Enable(true)
	end
	if LR_EquipSearch_Panel.nTotalPage > 1 and LR_EquipSearch_Panel.nPage > 1 then
		BTN_FIRST:Enable(true)
		BTN_PRE:Enable(true)
	end
	if LR_EquipSearch_Panel.nTotalPage > 1 and LR_EquipSearch_Panel.nPage < LR_EquipSearch_Panel.nTotalPage then
		BTN_NEXT:Enable(true)
		BTN_LAST:Enable(true)
	end
	local szText = sformat(_L["Total %d record(s), total %d page(s)"], LR_EquipSearch_Panel.nCount, LR_EquipSearch_Panel.nTotalPage)
	TEXT_PAGE:SetText(szText)
	EDIT_PAGE:SetText(LR_EquipSearch_Panel.nPage)
end

function LR_EquipSearch_Panel:OutputSouce(DATA)
	local hHandle_Source = self:Fetch("hHandle_Source")
	self:ClearHandle(hHandle_Source)
	local szBelongMapID = DATA.szBelongMapID
	local szSourceType = UTF8ToAnsi(DATA.szSourceType)
	local szSourceForce = UTF8ToAnsi(DATA.szSourceForce)
	local szSourceDesc = UTF8ToAnsi(DATA.szSourceDesc)

	local tSourceType = {}
	for s in string.gfind(szSourceType .. ",", "(.-),") do
		if s ~= "" then
			tSourceType[#tSourceType+1] = s
		end
	end

	local tSourceDesc = {}
	for s in string.gfind(szSourceDesc, "{(.-)}") do
		tSourceDesc[#tSourceDesc+1] = s
	end

	local tBelongMapID = {}
	for s in string.gfind(szBelongMapID .. ",", "(%d+),") do
		tBelongMapID[#tBelongMapID+1] = s
	end

	local data = {}
	for k, v in pairs (tSourceType) do
		if v == _L["FU_BEN"] then
			local tSourceDesc2 = {}
			for s in string.gfind(tSourceDesc[k], "%[(.-)%]") do
				tSourceDesc2[#tSourceDesc2+1] = s
			end
			data[v] = {}
			for k2 ,v2 in pairs (tSourceDesc2) do
				tinsert(data[v], {dwMapID = tonumber(tBelongMapID[k2]), boss = v2})
			end
		else
			local tSourceDesc2 = {}
			for s in string.gfind(tSourceDesc[k] .. ",", "(.-),") do
				tSourceDesc2[#tSourceDesc2+1] = s
			end
			data[v] = {}
			for k2 ,v2 in pairs (tSourceDesc2) do
				if v == _L["SHENG_WANG"] and szSourceForce ~= "" then
					tinsert(data[v], {value = v2, szSourceForce = szSourceForce})
				else
					tinsert(data[v], {value = v2 })
				end
			end
		end
	end

	for k, v in pairs (data) do
		for k2, v2 in pairs (v) do
			local hHandle = LR.AppendUI("Handle", hHandle_Source, "Handle", {w = 560, h = 30,})
			local bg = LR.AppendUI("Image", hHandle, "bg_image", {x = 0, y = 0, w = 0, h = 0})
			bg:FromUITex("UI/Image/Common/Money.Uitex", 211)
			bg:SetAlpha(200)
			bg:Hide()
			local hHandle2 = LR.AppendUI("Handle", hHandle, "Handle", {w = 560, h = 30,})
			hHandle2:SetHandleStyle(3)
			if k == _L["FU_BEN"] then
				local dwMapID = v2.dwMapID
				local szMapName = Table_GetMapName(dwMapID)
				LR.AppendUI("Text", hHandle2, "type", {text = sformat("◆%s ", k)})
				LR.AppendUI("Text", hHandle2, "name", {text = sformat("[%s]：", szMapName)})
				LR.AppendUI("Text", hHandle2, "boss", {text = sformat("%s  ", v2.boss)})
			elseif k == _L["SHENG_WANG"] then
				LR.AppendUI("Text", hHandle2, "type", {text = sformat("◆%s%s%s：", v2.szSourceForce or "", k, _L["SHANG_REN"])})
				LR.AppendUI("Text", hHandle2, "value", {text = sformat("%s [%s] ", v2.value, DATA.szPrestigeRequire)})
			elseif k == _L["SHANG_DIAN"] then
				LR.AppendUI("Text", hHandle2, "type", {text = sformat("◆%s：", k)})
				LR.AppendUI("Text", hHandle2, "value", {text = sformat("%s%s  ", v2.value, _L["SHANG_REN"])})
			else
				LR.AppendUI("Text", hHandle2, "type", {text = sformat("◆%s：", k)})
				LR.AppendUI("Text", hHandle2, "value", {text = sformat("%s  ", v2.value)})
			end
			hHandle2:FormatAllItemPos()
			hHandle2:SetSizeByAllItemSize()
			hHandle:SetSizeByAllItemSize()
			local w, h = hHandle:GetAllItemSize()
			bg:SetSize(w, h)

			hHandle2:RegisterEvent(786)
			hHandle2.OnEnter = function()
				bg:Show()
			end
			hHandle2.OnLeave = function()
				bg:Hide()
			end
		end
	end
	hHandle_Source:UpdateList()
end
