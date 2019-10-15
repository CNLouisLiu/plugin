local sformat, slen, sgsub, ssub, sfind, sgfind, smatch, sgmatch = string.format, string.len, string.gsub, string.sub, string.find, string.gfind, string.match, string.gmatch
local wslen, wssub, wsreplace, wssplit, wslower = wstring.len, wstring.sub, wstring.replace, wstring.split, wstring.lower
local mfloor, mceil, mabs, mpi, mcos, msin, mmax, mmin = math.floor, math.ceil, math.abs, math.pi, math.cos, math.sin, math.max, math.min
local tconcat, tinsert, tremove, tsort, tgetn = table.concat, table.insert, table.remove, table.sort, table.getn
---------------------------------------------------------------
-------------------------------------------------------------
local AddonPath = "Interface\\LR_Plugin\\LR_NianShou"
local _L = LR.LoadLangPack(AddonPath)
--------------------------------------------------
LR_TOOLS.tAddonClass = LR_TOOLS.tAddonClass or {}
if not LR_TOOLS.Check_tAddonClass("SmallHelpers") then
    tinsert(LR_TOOLS.tAddonClass, { "SmallHelpers", _L["Helpers"], "3" })
end
---------------------------------------------------
local LR_NianShou_UI_score = {
    [1]  = 20,
    [2]  = 40,
    [3]  = 80,
    [4]  = 160,
    [5]  = 320,
    [6]  = 640,
    [7]  = 1280,
    [8]  = 2560,
    [9]  = 5120,
    [10] = 10240,
    [11] = 20480,
    [12] = 40960,
    [13] = 81920,
    [14] = 163840,
    [15] = 327680,
    [16] = 655360,
}

local LR_NianShou_UI = {
    szName  = "LR_NianShou_UI",
    szTitle = _L["LR NianShou"],
    dwIcon  = 1395,
    szClass = "SmallHelpers",
    tWidget = {
        { name     = "LR_NianShou_bu01", type = "Button", x = 0, y = 0, text = _L["Start NianShou"], w = 200,
          enable   = function()
              return true
          end,
          callback = function()
              LR_NianShou.Open()
          end
        }, {
            name     = "LR_NianShou_co01", type = "ComboBox", x = 0, y = 35, w = 300, text = _L["Score begin using gold hummer"],
            callback = function(m)
                local player = GetClientPlayer()
                for i = 1, 16 do
                    table.insert(m, { szOption = LR_NianShou_UI_score[i], bCheck = true, bMCheck = true, bChecked = function()
                        return LR_NianShou.UsrData.nUseXiaoJinChui == LR_NianShou_UI_score[i]
                    end, fnAction              = function()
                        LR_NianShou.UsrData.nUseXiaoJinChui = LR_NianShou_UI_score[i]
                    end, })
                end
                PopupMenu(m)
            end,
        }, {
            name     = "LR_NianShou_co02", type = "ComboBox", x = 0, y = 70, w = 300, text = _L["Score begin using perfume satchel"],
            callback = function(m)
                local player = GetClientPlayer()
                for i = 1, 16 do
                    table.insert(m, { szOption = LR_NianShou_UI_score[i], bCheck = true, bMCheck = true, bChecked = function()
                        return LR_NianShou.UsrData.nUseJX == LR_NianShou_UI_score[i]
                    end, fnAction              = function()
                        LR_NianShou.UsrData.nUseJX = LR_NianShou_UI_score[i]
                    end, })
                end
                PopupMenu(m)
            end,
        }, {
            name     = "LR_NianShou_co03", type = "ComboBox", x = 0, y = 105, w = 300, text = _L["Score begin using JiYouGu"],
            callback = function(m)
                local player = GetClientPlayer()
                for i = 1, 16 do
                    table.insert(m, { szOption = LR_NianShou_UI_score[i], bCheck = true, bMCheck = true, bChecked = function()
                        return LR_NianShou.UsrData.nUseZJ == LR_NianShou_UI_score[i]
                    end, fnAction              = function()
                        LR_NianShou.UsrData.nUseZJ = LR_NianShou_UI_score[i]
                    end, })
                end
                PopupMenu(m)
            end,
        }, {
            name     = "LR_NianShou_co04", type = "ComboBox", x = 0, y = 140, w = 300, text = _L["Stop score"],
            callback = function(m)
                local player = GetClientPlayer()
                for i = 1, 16 do
                    table.insert(m, { szOption = LR_NianShou_UI_score[i], bCheck = true, bMCheck = true, bChecked = function()
                        return LR_NianShou.UsrData.nPausePoint == LR_NianShou_UI_score[i]
                    end,
                                      fnAction = function()
                                          LR_NianShou.UsrData.nPausePoint = LR_NianShou_UI_score[i]
                                      end, })
                end
                PopupMenu(m)
            end,
        }, {
            name     = "LR_NianShou_bu04", type = "Button", x = 0, y = 175, w = 240, text = _L["Lost item list to pick"],
            callback = function()
                if LR_PickupDead then
                    LR_NianShou.LoadDefault()
                else
                    LR.SysMsg("Please install LR_PickupDead\n")
                end
            end
        }, {
            name     = "LR_NianShou_bu02", type = "Button", x = 0, y = 210, text = _L["Reset"],
            callback = function()
                LR_NianShou.nScore = 0
                LR_NianShou.bOn = false
                LR_NianShou.doodadID = 0
                LR_NianShou.Default.tFilterItem = LR_NianShou.LoadDefault()
                LR_NianShou.UsrData = clone(LR_NianShou.Default)
            end
        }, {
            name     = "LR_NianShou_bu03", type = "Button", x = 200, y = 210, text = _L["Only zuisheng"],
            callback = function()
                LR_NianShou.nScore = 0
                LR_NianShou.bOn = false
                LR_NianShou.doodadID = 0
                LR_NianShou.UsrData = {}
                LR_NianShou.UsrData = {
                    nUseXiaoJinChui = 327680, --用小金锤的分数
                    nUseZJ          = 327680, -- 开始吃醉生、寄优谷的分数
                    bPauseNoZJ      = true, -- 缺少醉生、寄优时停砸
                    nPausePoint     = 327680, -- 停砸分数线
                    nUseJX          = 327680, -- 自动用掉锦囊、香囊
                    bNonZS          = true, -- 不使用醉生
                    bUseGold        = false, -- 没银锤时使用金锤
                    bUseTaoguan     = true, -- 必要时自动使用背包的陶罐
                    loot_notinlist  = true,
                    tFilterItem     = LR_NianShou.LoadDefault(),
                }
            end
        }, { name     = "LR_NianShou_ch03", type = "CheckBox", text = _L["Do not use ZS"], x = 300, y = 0, w = 200,
             default  = function()
                 return LR_NianShou.UsrData.bNonZS
             end,
             callback = function(enabled)
                 LR_NianShou.UsrData.bNonZS = enabled
             end
        },
    }
}
LR_TOOLS:RegisterPanel(LR_NianShou_UI)
-----------------------------------
----注册头像、扳手菜单
-----------------------------------
LR_TOOLS.menu = LR_TOOLS.menu or {}
LR_NianShou_UI.menu = {
    szOption        = _L["LR NianShou"],
    --rgb = {255, 255, 255},
    fnAction        = function()
        LR_NianShou.bOn = not LR_NianShou.bOn
    end,
    bCheck          = true,
    bMCheck         = false,
    rgb             = { 255, 255, 255 },
    bChecked        = function()
        return LR_NianShou.bOn
    end,
    fnAutoClose     = true,
    szIcon          = "ui\\Image\\UICommon\\CommonPanel2.UITex",
    nFrame          = 105,
    nMouseOverFrame = 106,
    szLayer         = "ICON_RIGHT",
    fnAutoClose     = true,
    fnClickIcon     = function()
        LR_TOOLS:OpenPanel(_L["LR NianShou"])
    end,
}

table.insert(LR_TOOLS.menu, LR_NianShou_UI.menu)
