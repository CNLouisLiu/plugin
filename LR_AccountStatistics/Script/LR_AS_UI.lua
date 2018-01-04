local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch, slower = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch, string.lower
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_AccountStatistics"
local SaveDataPath = "Interface\\LR_Plugin@DATA\\LR_AccountStatistics\\UsrData"
local DB_name = "maindb.db"
local _L  =  LR.LoadLangPack(AddonPath)
local CustomVersion = "20170111"
---------------------------------------------------------------
LR_AccountStatistics = LR_AccountStatistics or {}



function LR_AccountStatistics.OnFrameCreate()
	-----账目本容器
	LR_AccountStatistics.LR_AS_Container = this:Lookup("PageSet_Menu/Page_LR_AS_Record/WndScroll_LR_AS_Record/WndContainer_Record_List")
	-----副本列表容器
	LR_AccountStatistics.LR_FBList_Container = this:Lookup("PageSet_Menu/Page_LR_FBList/WndScroll_LR_FBList_Record/Wnd_LR_FBList_Record_List")
	LR_AccountStatistics.LR_FBList_Title_handle = this:Lookup("PageSet_Menu"):Lookup("Page_LR_FBList"):Lookup("", "")
	-----日常统计容器
	LR_AccountStatistics.LR_RCList_Container = this:Lookup("PageSet_Menu/Page_LR_RCList/WndScroll_LR_RCList_Record/Wnd_LR_RCList_Record_List")
	LR_AccountStatistics.LR_RCList_Title_handle = this:Lookup("PageSet_Menu"):Lookup("Page_LR_RCList"):Lookup("", "")
	-----奇遇统计容器
	LR_AccountStatistics.LR_QYList_Container = this:Lookup("PageSet_Menu/Page_LR_QYList/WndScroll_LR_QYList_Record/Wnd_LR_QYList_Record_List")
	LR_AccountStatistics.LR_QYList_Title_handle = this:Lookup("PageSet_Menu"):Lookup("Page_LR_QYList"):Lookup("", "")

	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	----打开时刷新数据
	LR_AS_Group.LoadGroupListData(DB)
	LR_AS_Group.LoadAllUserGroup(DB)
	LR_AS_Info.LoadUserList(DB)
	LR_AS_Info.LoadAllUserInformation(DB)
	LR_AccountStatistics_FBList.GetFBList()
	LR_AS_Exam.LoadData(DB)
	LR_AccountStatistics_RiChang.LoadAllUsrData(DB)
	LR_AccountStatistics_RiChang.CheckAll()
	LR_AccountStatistics_FBList.LoadAllUsrData(DB)
	LR_ACS_QiYu.LoadAllUsrData(DB)		--奇遇数据


	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("CUSTOM_DATA_LOADED")

	this:Lookup("Btn_Close").OnLButtonClick =  function ()
		Wnd.CloseWindow("LR_AccountStatistics")
	end

	RegisterGlobalEsc("LR_AccountStatistics", function () return true end , function() Wnd.CloseWindow("LR_AccountStatistics") end)
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)

	----界面
	this:Lookup("", ""):Lookup("Text_Title"):SetText(_L["LR_AccountStatistics"])

	this:Lookup("PageSet_Menu/WndCheck_LR_AS_Record"):Lookup("", ""):Lookup("Text_LR_AS_Record"):SetText(_L["AccountStatistics"])
	this:Lookup("PageSet_Menu/Page_LR_AS_Record"):Lookup("", ""):Lookup("Text_LR_AS_RecordSettlement"):SetText(_L["Total:"])

	this:Lookup("PageSet_Menu/WndCheck_LR_FBList"):Lookup("", ""):Lookup("Text_LR_FBList_Record"):SetText(_L["FBStatistics"])
	LR_AccountStatistics.LR_FBList_Title_handle:Lookup("Text_FBList_Record_Break1"):SetText(_L["Name"])

	this:Lookup("PageSet_Menu/WndCheck_LR_RCList"):Lookup("", ""):Lookup("Text_LR_RCList_Record"):SetText(_L["RCStatistics"])
	LR_AccountStatistics.LR_RCList_Title_handle:Lookup("Text_RCList_Record_Break1"):SetText(_L["Name"])

	this:Lookup("PageSet_Menu/WndCheck_LR_QYList"):Lookup("", ""):Lookup("Text_LR_QYList_Record"):SetText(_L["QYStatistics"])
	LR_AccountStatistics.LR_QYList_Title_handle:Lookup("Text_QYList_Record_Break1"):SetText(_L["Name"])

	this:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)

	LR_AS_Info.ReFreshTitle()
	LR_AS_Info.ListAS()
	LR_AS_Info.AddPageButton()

	LR_AccountStatistics_FBList.ReFreshTitle()
	LR_AccountStatistics_FBList.ListFB()
	LR_AccountStatistics_FBList.AddPageButton()

	LR_AccountStatistics_RiChang.ReFreshTitle()
	LR_AccountStatistics_RiChang.ListRC()
	LR_AccountStatistics_RiChang.AddPageButton()

	LR_ACS_QiYu.ReFreshTitle()
	LR_ACS_QiYu.ListQY()
	LR_ACS_QiYu.AddPageButton()

	-------打开面板时保存数据
	if LR_AS_Base.UsrData.AutoSave then
		LR_AS_Base.AutoSave()
	end

	-----------邮件提醒
	LR_AccountStatistics_Mail_Check.CheckAllMail()

	LR_AccountStatistics_FBList.ListFB()
	LR_AccountStatistics_RiChang.ListRC()
	LR_ACS_QiYu.ListQY()

	DB:Execute("END TRANSACTION")
	DB:Release()

	FireEvent("LR_ACS_REFRESH_FP")
	LR.AppendAbout(Addon, this)
end

function LR_AccountStatistics.OnFrameDestroy ()
	UnRegisterGlobalEsc("LR_AccountStatistics")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function LR_AccountStatistics.OnEvent(event)
	----
end

function LR_AccountStatistics.OpenPanel(flag)
	local frame = Station.Lookup("Normal/LR_AccountStatistics")
	if frame and not flag then
		Wnd.CloseWindow(frame)
	else
		Wnd.OpenWindow("Interface\\LR_Plugin\\LR_AccountStatistics\\UI\\LR_AccountStatistics.ini", "LR_AccountStatistics")
	end
end

function LR_AccountStatistics.OnFrameBreathe()
	if GetLogicFrameCount() % (16*5) ~=  0 then
		return
	end
	local player = GetClientPlayer()
	if not player then
		return
	end
	local path = sformat("%s\\%s", SaveDataPath, DB_name)
	local DB = SQLite3_Open(path)
	DB:Execute("BEGIN TRANSACTION")
	LR_AS_Group.LoadGroupListData(DB)	--分组数据
	LR_AS_Group.LoadAllUserGroup(DB)	--人物分组
	LR_AS_Info.GetUserInfo()	--获取自身数据
	LR_AS_Info.LoadAllUserInformation(DB)		--人物数据
	LR_AS_Exam.LoadData(DB)	--考试数据
	LR_AccountStatistics_RiChang.LoadAllUsrData(DB)	--日常数据
	LR_AccountStatistics_FBList.LoadAllUsrData(DB)	--副本数据
	LR_ACS_QiYu.LoadAllUsrData(DB)		--奇遇数据
	---展示
	LR_AS_Info.ListAS()
	LR_AccountStatistics_FBList.ListFB()
	LR_AccountStatistics_RiChang.ListRC()
	LR_ACS_QiYu.ListQY()
	DB:Execute("END TRANSACTION")
	DB:Release()
end

function LR_AccountStatistics.CheckTable(t_Table, dwID)
	local TempTable = t_Table
	local CheckID =  dwID
	for k, v in pairs (TempTable) do
		if v.ID  ==  CheckID then
			return k
		end
	end
	return 0
end

---------------------------------
---打开设置界面
---------------------------------
function LR_AccountStatistics.SetOption()
	LR_TOOLS:OpenPanel(_L["LR_AS_Global_Settings"])
	local frame = Station.Lookup("Normal/LR_TOOLS")
	if frame then
		frame:BringToTop()
	end
end
