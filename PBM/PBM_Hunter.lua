PBM = PBM or {}

-- Talent spec templates for the Set Talents menu
local HUNTER_TALENT_SPECS = {
    { label="Beast Mastery |cffffcc00PvE|r", spec="bm pve",   wowSpec="Beast Mastery", icon="Interface\\Icons\\Ability_Hunter_BeastTaming"  },
    { label="Marksmanship |cffffcc00PvE|r",  spec="mm pve",   wowSpec="Marksmanship",  icon="Interface\\Icons\\Ability_Marksmanship"        },
    { label="Survival |cffffcc00PvE|r",      spec="surv pve", wowSpec="Survival",      icon="Interface\\Icons\\Ability_Hunter_SwiftStrike"  },
    { label="Beast Mastery |cffff4444PvP|r", spec="bm pvp",   wowSpec="Beast Mastery", icon="Interface\\Icons\\Ability_Hunter_BeastTaming"  },
    { label="Marksmanship |cffff4444PvP|r",  spec="mm pvp",   wowSpec="Marksmanship",  icon="Interface\\Icons\\Ability_Marksmanship"        },
    { label="Survival |cffff4444PvP|r",      spec="surv pvp", wowSpec="Survival",      icon="Interface\\Icons\\Ability_Hunter_SwiftStrike"  },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Hunter class-specific overlay panel
-- ─────────────────────────────────────────────────────────────────────────────
local LichborneHunterMenu
local LichborneHunterCatcher

local HUNTER_LEFT_EXT = 5
local HUNTER_OVL_W = (PBM.GEAR_OFF + PBM.GEAR_SLOTS * PBM.COL_GEAR_W) - PBM.GS_OFF + HUNTER_LEFT_EXT
local HUNTER_OVL_H = PBM.MAX_ROWS * PBM.ROW_HEIGHT + 12

local EXT_ICON_SIZE = 26

local function HideAllHunter()
    PBM.HideCharSheet(LichborneHunterMenu, LichborneHunterCatcher)
end

function PBM.CloseHunterMenu()
    HideAllHunter()
end

function PBM.OpenHunterMenu(row)
    if not LichborneHunterMenu then
        LichborneHunterMenu, LichborneHunterCatcher = PBM.CreateCharSheet({
            menuName    = "LichborneHunterMenu",
            catcherName = "LichborneHunterCatcher",
            className   = "Hunter",
            classHex    = "ABD473",
            leftExt     = HUNTER_LEFT_EXT,
            overlayW    = HUNTER_OVL_W,
            overlayH    = HUNTER_OVL_H,
            talentSpecs = HUNTER_TALENT_SPECS,
            hideCallback = HideAllHunter,
        })

        -- ── Tree layout constants ────────────────────────────────────
        local HDR_H        = PBM.ROW_HEIGHT
        local SPEC_COL_W   = 82
        local SPEC_COL_GAP = 6
        local TREE_TOTAL_W = 3 * SPEC_COL_W + 2 * SPEC_COL_GAP
        local TREE_X       = math.floor((HUNTER_OVL_W - TREE_TOTAL_W) / 2)
        local TREE_TOP_Y   = -(HDR_H + 68)
        local ICON_OFF     = math.floor((SPEC_COL_W - EXT_ICON_SIZE) / 2)

        local col1X = TREE_X
        local col2X = TREE_X + SPEC_COL_W + SPEC_COL_GAP
        local col3X = TREE_X + 2 * (SPEC_COL_W + SPEC_COL_GAP)

        local specBoxY  = TREE_TOP_Y - 16
        local specIconY = specBoxY - 18 - 4     -- 4px header→icon gap

        -- Combat header: 2 buttons wide (Trap Weave only — dps/dps debuff removed)
        local BTN_GAP      = 4
        local combatBtnW   = 2 * EXT_ICON_SIZE + BTN_GAP
        local combatHdrX   = col2X + math.floor((SPEC_COL_W - combatBtnW) / 2)
        local trapX        = combatHdrX + math.floor((combatBtnW - EXT_ICON_SIZE) / 2)
        local combatHdrY   = specIconY - EXT_ICON_SIZE - 15
        local combatIconY  = combatHdrY - 18 - 4
        -- Assist header: 3 buttons wide, centred independently under Marksmanship
        local assistBtnW   = 3 * EXT_ICON_SIZE + 2 * BTN_GAP
        local assistHdrX   = col2X + math.floor((SPEC_COL_W - assistBtnW) / 2)
        local assistHdrY   = combatIconY - EXT_ICON_SIZE - 15
        local assistIconY  = assistHdrY - 18 - 4

        -- Aspects: CO/NC columns sit to the right of Survival (Paladin-style)
        -- "Aspects" master header at spec row, CO/NC sub-headers below it
        local aspectColTotalW = EXT_ICON_SIZE + BTN_GAP + EXT_ICON_SIZE
        local coX          = col3X + SPEC_COL_W + SPEC_COL_GAP
        local ncX          = coX + EXT_ICON_SIZE + BTN_GAP
        local aspectsHdrY  = specBoxY                         -- same row as spec headers
        local coNcHdrY     = aspectsHdrY - 18 - 3            -- CO / NC sub-headers
        local aspectIcon1Y = coNcHdrY - 18 - 4               -- first aspect button
        local aspectIcon2Y = aspectIcon1Y - EXT_ICON_SIZE - 3
        local aspectIcon3Y = aspectIcon2Y - EXT_ICON_SIZE - 3

        -- ── Backdrop template ────────────────────────────────────────
        local SPEC_BOX_BD = {
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        }

        -- ── Helpers ──────────────────────────────────────────────────
        local function MakeSpecBox(x, y, w, label, icon)
            local box = CreateFrame("Frame", nil, LichborneHunterMenu)
            box:SetSize(w, 18)
            box:SetPoint("TOPLEFT", LichborneHunterMenu, "TOPLEFT", x, y)
            box:SetBackdrop(SPEC_BOX_BD)
            box:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
            box:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
            if icon then
                local ic = box:CreateTexture(nil, "ARTWORK")
                ic:SetSize(14, 14)
                ic:SetPoint("LEFT", box, "LEFT", 2, 0)
                ic:SetTexture(icon)
            end
            local fs = box:CreateFontString(nil, "OVERLAY")
            fs:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
            fs:SetTextColor(0.78, 0.61, 0.23, 1)
            if icon then
                fs:SetPoint("LEFT", box, "LEFT", 18, 0)
                fs:SetPoint("RIGHT", box, "RIGHT", -2, 0)
            else
                fs:SetAllPoints()
            end
            fs:SetJustifyH("CENTER")
            fs:SetText(label)
            return box
        end

        local function MakeWideBox(x, y, w, label)
            local box = CreateFrame("Frame", nil, LichborneHunterMenu)
            box:SetSize(w, 18)
            box:SetPoint("TOPLEFT", LichborneHunterMenu, "TOPLEFT", x, y)
            box:SetBackdrop(SPEC_BOX_BD)
            box:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
            box:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
            local fs = box:CreateFontString(nil, "OVERLAY")
            fs:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            fs:SetTextColor(0.78, 0.61, 0.23, 1)
            fs:SetAllPoints()
            fs:SetJustifyH("CENTER")
            fs:SetText(label)
            return box
        end

        local function MakeTreeBtn(bx, by, icon, tipFn)
            local btn = CreateFrame("Button", nil, LichborneHunterMenu)
            btn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
            btn:SetPoint("TOPLEFT", LichborneHunterMenu, "TOPLEFT", bx, by)
            local tex = btn:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:SetTexture(icon)
            tex:SetDesaturated(true)
            btn.icon = tex
            btn.state = false
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetFrameLevel(LichborneHunterMenu:GetFrameLevel() + 20)
                GameTooltip:ClearLines()
                tipFn()
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            return btn
        end

        -- ── Row 1: Specs ─────────────────────────────────────────────
        MakeSpecBox(col1X, specBoxY, SPEC_COL_W, "Beast Mastery", "Interface\\Icons\\Ability_Hunter_BeastTaming")
        MakeSpecBox(col2X, specBoxY, SPEC_COL_W, "Marksmanship",  "Interface\\Icons\\Ability_Marksmanship")
        MakeSpecBox(col3X, specBoxY, SPEC_COL_W, "Survival",      "Interface\\Icons\\Ability_Hunter_SwiftStrike")

        local treeBmBtn = MakeTreeBtn(col1X + ICON_OFF, specIconY,
            "Interface\\Icons\\Ability_Hunter_BeastTaming", function()
            GameTooltip:SetText("|cffffcc00Beast Mastery|r |cff999999- |r|cffABD473bm|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Beast Mastery specialization|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Marksmanship, Survival.|r", 1, 1, 1)
        end)
        LichborneHunterMenu.treeBmBtn = treeBmBtn

        local treeMmBtn = MakeTreeBtn(col2X + ICON_OFF, specIconY,
            "Interface\\Icons\\Ability_Marksmanship", function()
            GameTooltip:SetText("|cffffcc00Marksmanship|r |cff999999- |r|cffABD473mm|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Marksmanship specialization|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Beast Mastery, Survival.|r", 1, 1, 1)
        end)
        LichborneHunterMenu.treeMmBtn = treeMmBtn

        local treeSurvBtn = MakeTreeBtn(col3X + ICON_OFF, specIconY,
            "Interface\\Icons\\Ability_Hunter_SwiftStrike", function()
            GameTooltip:SetText("|cffffcc00Survival|r |cff999999- |r|cffABD473surv|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Survival specialization|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Beast Mastery, Marksmanship.|r", 1, 1, 1)
        end)
        LichborneHunterMenu.treeSurvBtn = treeSurvBtn

        -- ── Combat header (2-button wide, Trap Weave centred) ────────
        MakeWideBox(combatHdrX, combatHdrY, combatBtnW, "Combat")

        local treeTrapWeaveBtn = MakeTreeBtn(trapX, combatIconY,
            "Interface\\Icons\\ability_ensnare", function()
            GameTooltip:SetText("|cffffcc00Trap Weave|r |cff999999- |r|cffABD473trap weave|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Melee trap rotation|r", 1, 1, 1)
        end)
        LichborneHunterMenu.treeTrapWeaveBtn = treeTrapWeaveBtn

        -- ── Assist header (3-button wide, centred under Marksmanship) ─
        MakeWideBox(assistHdrX, assistHdrY, assistBtnW, "Assist")

        local treeTankAssistBtn = MakeTreeBtn(assistHdrX, assistIconY,
            "Interface\\Icons\\inv_shield_02", function()
            GameTooltip:SetText("|cffffcc00Tank Assist|r |cff999999- |r|cffff8000tank assist|r |cffffcc00CO|r")
            GameTooltip:AddLine("|cffffcc00Tank target focus|r", 1, 1, 1)
        end)
        LichborneHunterMenu.treeTankAssistBtn = treeTankAssistBtn

        local treeDpsAssistBtn = MakeTreeBtn(assistHdrX + 30, assistIconY,
            "Interface\\Icons\\Ability_Warrior_Challange", function()
            GameTooltip:SetText("|cffffcc00DPS Assist|r |cff999999- |r|cffff8000dps assist|r |cffffcc00CO|r")
            GameTooltip:AddLine("|cffffcc00Assists the main assist target|r", 1, 1, 1)
            GameTooltip:AddLine("Attacks the assist leader's target.", 1, 1, 1)
        end)
        LichborneHunterMenu.treeDpsAssistBtn = treeDpsAssistBtn

        local treeDpsAoeBtn = MakeTreeBtn(assistHdrX + 60, assistIconY,
            "Interface\\Icons\\Spell_Shadow_RainOfFire", function()
            GameTooltip:SetText("|cffffcc00DPS AoE|r |cff999999- |r|cffABD473aoe|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Cross-role AoE mode|r", 1, 1, 1)
        end)
        LichborneHunterMenu.treeDpsAoeBtn = treeDpsAoeBtn

        -- ── Aspects: master header + CO/NC sub-headers ──────────────
        MakeWideBox(coX, aspectsHdrY, aspectColTotalW, "Aspects")
        MakeSpecBox(coX, coNcHdrY, EXT_ICON_SIZE, "CO")

        local treeCADragonhawkBtn = MakeTreeBtn(coX, aspectIcon1Y,
            "Interface\\Icons\\Ability_Hunter_Pet_DragonHawk", function()
            GameTooltip:SetText("|cffffcc00Dragonhawk|r |cff999999- |r|cffffff00bdps|r |cffff8000CO|r")
            GameTooltip:AddLine("|cffffcc00Aspect of the Dragonhawk|r", 1, 1, 1)
            GameTooltip:AddLine("Increases ranged |cffFF9900attack power|r", 1, 1, 1)
            GameTooltip:AddLine("and |cffFF9900dodge rating.|r", 1, 1, 1)
        end)
        LichborneHunterMenu.treeCADragonhawkBtn = treeCADragonhawkBtn

        local treeCAPackBtn = MakeTreeBtn(coX, aspectIcon2Y,
            "Interface\\Icons\\Ability_Mount_WhiteTiger", function()
            GameTooltip:SetText("|cffffcc00Pack|r |cff999999- |r|cffffff00bspeed|r |cffff8000CO|r")
            GameTooltip:AddLine("|cffffcc00Aspect of the Pack|r", 1, 1, 1)
            GameTooltip:AddLine("Increases group |cffFF9900movement speed|r", 1, 1, 1)
            GameTooltip:AddLine("while in combat.", 1, 1, 1)
        end)
        LichborneHunterMenu.treeCAPackBtn = treeCAPackBtn

        local treeCAWildBtn = MakeTreeBtn(coX, aspectIcon3Y,
            "Interface\\Icons\\Spell_Nature_ProtectionformNature", function()
            GameTooltip:SetText("|cffffcc00Wild|r |cff999999- |r|cffffff00rnature|r |cffff8000CO|r")
            GameTooltip:AddLine("|cffffcc00Aspect of the Wild|r", 1, 1, 1)
            GameTooltip:AddLine("Increases group |cff1EFF00Nature resistance|r", 1, 1, 1)
            GameTooltip:AddLine("while in combat.", 1, 1, 1)
        end)
        LichborneHunterMenu.treeCAWildBtn = treeCAWildBtn

        -- ── NC aspect column ─────────────────────────────────────────
        MakeSpecBox(ncX, coNcHdrY, EXT_ICON_SIZE, "NC")

        local treeNCADragonhawkBtn = MakeTreeBtn(ncX, aspectIcon1Y,
            "Interface\\Icons\\Ability_Hunter_Pet_DragonHawk", function()
            GameTooltip:SetText("|cffffcc00Dragonhawk|r |cff999999- |r|cffffff00bdps|r |cffff8000NC|r")
            GameTooltip:AddLine("|cffffcc00Aspect of the Dragonhawk|r", 1, 1, 1)
            GameTooltip:AddLine("Default out-of-combat aspect.", 1, 1, 1)
            GameTooltip:AddLine("Maintains ranged |cffFF9900attack power|r", 1, 1, 1)
            GameTooltip:AddLine("and |cffFF9900dodge rating.|r", 1, 1, 1)
        end)
        LichborneHunterMenu.treeNCADragonhawkBtn = treeNCADragonhawkBtn

        local treeNCACheetahBtn = MakeTreeBtn(ncX, aspectIcon2Y,
            "Interface\\Icons\\Ability_Mount_WhiteTiger", function()
            GameTooltip:SetText("|cffffcc00Cheetah|r |cff999999- |r|cffffff00bspeed|r |cffff8000NC|r")
            GameTooltip:AddLine("|cffffcc00Aspect of the Cheetah|r", 1, 1, 1)
            GameTooltip:AddLine("Increases |cffFF9900movement speed|r when", 1, 1, 1)
            GameTooltip:AddLine("not in combat.", 1, 1, 1)
        end)
        LichborneHunterMenu.treeNCACheetahBtn = treeNCACheetahBtn

        local treeNCAWildBtn = MakeTreeBtn(ncX, aspectIcon3Y,
            "Interface\\Icons\\Spell_Nature_ProtectionformNature", function()
            GameTooltip:SetText("|cffffcc00Wild|r |cff999999- |r|cffffff00rnature|r |cffff8000NC|r")
            GameTooltip:AddLine("|cffffcc00Aspect of the Wild|r", 1, 1, 1)
            GameTooltip:AddLine("Provides group |cff1EFF00Nature resistance|r", 1, 1, 1)
            GameTooltip:AddLine("between encounters.", 1, 1, 1)
        end)
        LichborneHunterMenu.treeNCAWildBtn = treeNCAWildBtn

        -- ── Wire: toggle logic ────────────────────────────────────────
        do
            local function IconOn(btn)
                btn.state = true
                if btn.icon then btn.icon:SetDesaturated(false) end
            end
            local function IconOff(btn)
                btn.state = false
                if btn.icon then btn.icon:SetDesaturated(true) end
            end

            -- Spec radio (mutually exclusive CO)
            local specList = {
                { cmd="bm",   btn=treeBmBtn   },
                { cmd="mm",   btn=treeMmBtn   },
                { cmd="surv", btn=treeSurvBtn },
            }
            for _, entry in ipairs(specList) do
                local btn = entry.btn
                local cmd = entry.cmd
                btn:SetScript("OnClick", function()
                    local bot = LichborneHunterMenu.botName or ""
                    LichborneHunterMenu._specUserSet = true
                    if btn.state then
                        PBM.SendToBot("co -" .. cmd .. ",?", bot); IconOff(btn)
                    else
                        PBM.SendToBot("co +" .. cmd .. ",?", bot); IconOn(btn)
                        for _, other in ipairs(specList) do
                            if other.cmd ~= cmd then IconOff(other.btn) end
                        end
                    end
                end)
            end

            -- DpsAssist ↔ TankAssist ↔ DpsAoe exclusive trio
            treeDpsAssistBtn:SetScript("OnClick", function()
                local bot = LichborneHunterMenu.botName or ""
                LichborneHunterMenu._specUserSet = true
                if treeDpsAssistBtn.state then
                    PBM.SendToBot("co -dps assist,?", bot); IconOff(treeDpsAssistBtn)
                else
                    PBM.SendToBot("co +dps assist,?", bot); IconOn(treeDpsAssistBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            -- DpsAoe ↔ TankAssist ↔ DpsAssist exclusive trio
            treeDpsAoeBtn:SetScript("OnClick", function()
                local bot = LichborneHunterMenu.botName or ""
                LichborneHunterMenu._specUserSet = true
                if treeDpsAoeBtn.state then
                    PBM.SendToBot("co -aoe,?", bot); IconOff(treeDpsAoeBtn)
                else
                    PBM.SendToBot("co +aoe,?", bot); IconOn(treeDpsAoeBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn)
                end
            end)

            -- TrapWeave (independent CO)
            treeTrapWeaveBtn:SetScript("OnClick", function()
                local bot = LichborneHunterMenu.botName or ""
                LichborneHunterMenu._specUserSet = true
                if treeTrapWeaveBtn.state then
                    PBM.SendToBot("co -trap weave,?", bot); IconOff(treeTrapWeaveBtn)
                else
                    PBM.SendToBot("co +trap weave,?", bot); IconOn(treeTrapWeaveBtn)
                end
            end)

            -- TankAssist ↔ DpsAssist ↔ DpsAoe exclusive trio
            treeTankAssistBtn:SetScript("OnClick", function()
                local bot = LichborneHunterMenu.botName or ""
                LichborneHunterMenu._specUserSet = true
                if treeTankAssistBtn.state then
                    PBM.SendToBot("co -tank assist,?", bot); IconOff(treeTankAssistBtn)
                else
                    PBM.SendToBot("co +tank assist,?", bot); IconOn(treeTankAssistBtn)
                    IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            -- Combat Aspect radio (CO, one-way sync)
            local combatAspectList = {
                { cmd="bdps",    btn=treeCADragonhawkBtn },
                { cmd="bspeed",  btn=treeCAPackBtn       },
                { cmd="rnature", btn=treeCAWildBtn       },
            }
            for _, entry in ipairs(combatAspectList) do
                local btn = entry.btn
                local cmd = entry.cmd
                btn:SetScript("OnClick", function()
                    local bot = LichborneHunterMenu.botName or ""
                    LichborneHunterMenu._specUserSet = true
                    if btn.state then
                        PBM.SendToBot("co -" .. cmd .. ",?", bot); IconOff(btn)
                    else
                        PBM.SendToBot("co +" .. cmd .. ",?", bot); IconOn(btn)
                        for _, other in ipairs(combatAspectList) do
                            if other.cmd ~= cmd then IconOff(other.btn) end
                        end
                    end
                end)
            end

            -- Non-Combat Aspect radio (NC, one-way sync)
            local ncAspectList = {
                { cmd="bdps",    btn=treeNCADragonhawkBtn },
                { cmd="bspeed",  btn=treeNCACheetahBtn    },
                { cmd="rnature", btn=treeNCAWildBtn       },
            }
            for _, entry in ipairs(ncAspectList) do
                local btn = entry.btn
                local cmd = entry.cmd
                btn:SetScript("OnClick", function()
                    local bot = LichborneHunterMenu.botName or ""
                    LichborneHunterMenu._specUserSet = true
                    if btn.state then
                        PBM.SendToBot("nc -" .. cmd .. ",?", bot); IconOff(btn)
                    else
                        PBM.SendToBot("nc +" .. cmd .. ",?", bot); IconOn(btn)
                        for _, other in ipairs(ncAspectList) do
                            if other.cmd ~= cmd then IconOff(other.btn) end
                        end
                    end
                end)
            end

            -- Extend resetSharedIcons with all class-specific buttons
            local _baseReset = LichborneHunterMenu.resetSharedIcons
            LichborneHunterMenu.resetAllIcons = function()
                if _baseReset then _baseReset() end
                for _, e in ipairs(specList)         do IconOff(e.btn) end
                IconOff(treeDpsAssistBtn)
                IconOff(treeDpsAoeBtn); IconOff(treeTrapWeaveBtn)
                IconOff(treeTankAssistBtn)
                for _, e in ipairs(combatAspectList) do IconOff(e.btn) end
                for _, e in ipairs(ncAspectList)     do IconOff(e.btn) end
            end

            -- Extend onStrategyUpdate (base handles food/loot/gather NC)
            local _baseSU = LichborneHunterMenu.onStrategyUpdate
            LichborneHunterMenu.onStrategyUpdate = function(stratType, activeSet)
                if _baseSU then _baseSU(stratType, activeSet) end
                if not LichborneHunterMenu._specUserSet then
                    if stratType == "co" then
                        if activeSet["bm"]          then IconOn(treeBmBtn)          else IconOff(treeBmBtn)          end
                        if activeSet["mm"]          then IconOn(treeMmBtn)          else IconOff(treeMmBtn)          end
                        if activeSet["surv"]        then IconOn(treeSurvBtn)        else IconOff(treeSurvBtn)        end
                        if activeSet["dps assist"]  then IconOn(treeDpsAssistBtn)   else IconOff(treeDpsAssistBtn)   end
                        if activeSet["aoe"]         then IconOn(treeDpsAoeBtn)      else IconOff(treeDpsAoeBtn)      end
                        if activeSet["trap weave"]  then IconOn(treeTrapWeaveBtn)   else IconOff(treeTrapWeaveBtn)   end
                        if activeSet["tank assist"] then IconOn(treeTankAssistBtn)  else IconOff(treeTankAssistBtn)  end
                        -- Combat Aspects: one-way (only snap ON)
                        for _, e in ipairs(combatAspectList) do
                            if activeSet[e.cmd] then IconOn(e.btn) end
                        end
                    elseif stratType == "nc" then
                        -- NC Aspects: one-way
                        for _, e in ipairs(ncAspectList) do
                            if activeSet[e.cmd] then IconOn(e.btn) end
                        end
                    end
                end
            end
        end -- end wire block
    end -- end lazy init

    if LichborneHunterMenu:IsShown() and LichborneHunterMenu.sourceRow == row then
        HideAllHunter()
        return
    end

    PBM.ShowCharSheet(LichborneHunterMenu, LichborneHunterCatcher, row, HUNTER_LEFT_EXT)
end
