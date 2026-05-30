PBM = PBM or {}

-- Timer helper (mirrors Multibot pattern): uses C_Timer if available, else OnUpdate fallback
local function PBM_TimerAfter(delay, callback)
    if C_Timer and C_Timer.After then
        return C_Timer.After(delay, callback)
    end
    local f = CreateFrame("Frame")
    f.elapsed = 0
    f:SetScript("OnUpdate", function(frame, dt)
        frame.elapsed = frame.elapsed + dt
        if frame.elapsed >= delay then
            frame:SetScript("OnUpdate", nil)
            if callback then pcall(callback) end
        end
    end)
end

-- Talent spec templates for the Set Talents menu
local ROGUE_TALENT_SPECS = {
    { label="Assassination |cffffcc00PvE|r", spec="as pve",       wowSpec="Assassination", icon="Interface\\Icons\\Ability_Rogue_Eviscerate" },
    { label="Combat |cffffcc00PvE|r",        spec="combat pve",   wowSpec="Combat",        icon="Interface\\Icons\\Ability_BackStab"         },
    { label="Subtlety |cffffcc00PvE|r",      spec="subtlety pve", wowSpec="Subtlety",      icon="Interface\\Icons\\Ability_Stealth"          },
    { label="Assassination |cffff4444PvP|r", spec="as pvp",       wowSpec="Assassination", icon="Interface\\Icons\\Ability_Rogue_Eviscerate" },
    { label="Combat |cffff4444PvP|r",        spec="combat pvp",   wowSpec="Combat",        icon="Interface\\Icons\\Ability_BackStab"         },
    { label="Subtlety |cffff4444PvP|r",      spec="subtlety pvp", wowSpec="Subtlety",      icon="Interface\\Icons\\Ability_Stealth"          },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Rogue class-specific overlay panel
-- ─────────────────────────────────────────────────────────────────────────────
local LichborneRogueMenu
local LichborneRogueCatcher

local ROGUE_LEFT_EXT = 5
local ROGUE_OVL_W = (PBM.GEAR_OFF + PBM.GEAR_SLOTS * PBM.COL_GEAR_W) - PBM.GS_OFF + ROGUE_LEFT_EXT
local ROGUE_OVL_H = PBM.MAX_ROWS * PBM.ROW_HEIGHT + 12

-- ─────────────────────────────────────────────────────────────────────────────
-- Rogue extended menu — icon button data (mirrors Multibot layout)
-- ─────────────────────────────────────────────────────────────────────────────
local EXT_ICON_SIZE = 26

local function HideAllRogue()
    PBM.HideCharSheet(LichborneRogueMenu, LichborneRogueCatcher)
end

function PBM.CloseRogueMenu()
    HideAllRogue()
end

function PBM.OpenRogueMenu(row)
    if not LichborneRogueMenu then
        LichborneRogueMenu, LichborneRogueCatcher = PBM.CreateCharSheet({
            menuName    = "LichborneRogueMenu",
            catcherName = "LichborneRogueCatcher",
            className   = "Rogue",
            classHex    = "FFF569",
            leftExt     = ROGUE_LEFT_EXT,
            overlayW    = ROGUE_OVL_W,
            overlayH    = ROGUE_OVL_H,
            talentSpecs = ROGUE_TALENT_SPECS,
            hideCallback = HideAllRogue,
        })

        -- ── Tree layout constants ────────────────────────────────────
        local SPEC_COL_W   = 82
        local SPEC_COL_GAP = 6
        local TREE_TOTAL_W = 3 * SPEC_COL_W + 2 * SPEC_COL_GAP
        local TREE_X       = math.floor((ROGUE_OVL_W - TREE_TOTAL_W) / 2)
        local TREE_TOP_Y   = -(PBM.ROW_HEIGHT + 68)
        local ICON_OFF     = math.floor((SPEC_COL_W - EXT_ICON_SIZE) / 2)

        local col1X = TREE_X
        local col2X = TREE_X + SPEC_COL_W + SPEC_COL_GAP
        local col3X = TREE_X + 2 * (SPEC_COL_W + SPEC_COL_GAP)

        local BTN_GAP    = 4
        local specBoxY   = TREE_TOP_Y - 16
        local specIconY  = specBoxY - 18 - 4

        -- Combat header (4 buttons wide, centered)
        local combatHdrW  = 4 * EXT_ICON_SIZE + 3 * BTN_GAP
        local combatHdrX  = TREE_X + math.floor((TREE_TOTAL_W - combatHdrW) / 2)
        local combatHdrY  = specIconY - EXT_ICON_SIZE - 15
        local combatIconY = combatHdrY - 18 - 4

        -- Assist header (3 buttons wide, centered)
        local assistHdrW  = 3 * EXT_ICON_SIZE + 2 * BTN_GAP
        local assistHdrX  = TREE_X + math.floor((TREE_TOTAL_W - assistHdrW) / 2)
        local assistHdrY  = combatIconY - EXT_ICON_SIZE - 15
        local assistIconY = assistHdrY - 18 - 4

        -- ── Backdrop template ────────────────────────────────────────
        local SPEC_BOX_BD = {
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        }

        -- ── Helpers ──────────────────────────────────────────────────
        local function MakeSpecBox(x, y, w, label, icon)
            local box = CreateFrame("Frame", nil, LichborneRogueMenu)
            box:SetSize(w, 18)
            box:SetPoint("TOPLEFT", LichborneRogueMenu, "TOPLEFT", x, y)
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
            local box = CreateFrame("Frame", nil, LichborneRogueMenu)
            box:SetSize(w, 18)
            box:SetPoint("TOPLEFT", LichborneRogueMenu, "TOPLEFT", x, y)
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
            local btn = CreateFrame("Button", nil, LichborneRogueMenu)
            btn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
            btn:SetPoint("TOPLEFT", LichborneRogueMenu, "TOPLEFT", bx, by)
            local tex = btn:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:SetTexture(icon)
            tex:SetDesaturated(true)
            btn.icon = tex
            btn.state = false
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetFrameLevel(LichborneRogueMenu:GetFrameLevel() + 20)
                GameTooltip:ClearLines()
                tipFn()
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            return btn
        end

        -- ── Row 1: Specs ─────────────────────────────────────────────
        MakeSpecBox(col1X, specBoxY, SPEC_COL_W, "Assassination", "Interface\\Icons\\Ability_Rogue_Eviscerate")
        MakeSpecBox(col2X, specBoxY, SPEC_COL_W, "Combat",        "Interface\\Icons\\Ability_BackStab")
        MakeSpecBox(col3X, specBoxY, SPEC_COL_W, "Subtlety",      "Interface\\Icons\\Ability_Stealth")

        local treeAsBtn = MakeTreeBtn(col1X + ICON_OFF, specIconY,
            "Interface\\Icons\\Ability_Rogue_Eviscerate", function()
            GameTooltip:SetText("|cffffcc00Assassination|r |cff999999- |r|cffFFF569melee|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Assassination DoT specialization|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Combat, Subtlety.|r", 1, 1, 1)
        end)
        LichborneRogueMenu.treeAsBtn = treeAsBtn

        local treeCombatBtn = MakeTreeBtn(col2X + ICON_OFF, specIconY,
            "Interface\\Icons\\Ability_BackStab", function()
            GameTooltip:SetText("|cffffcc00Combat|r |cff999999- |r|cffFFF569dps|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Combat sustained DPS|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Assassination, Subtlety.|r", 1, 1, 1)
        end)
        LichborneRogueMenu.treeCombatBtn = treeCombatBtn

        local treeSubtletyBtn = MakeTreeBtn(col3X + ICON_OFF, specIconY,
            "Interface\\Icons\\Ability_Stealth", function()
            GameTooltip:SetText("|cffffcc00Subtlety|r |cff999999- |r|cffFFF569melee|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Subtlety burst from Stealth|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Assassination, Combat.|r", 1, 1, 1)
        end)
        LichborneRogueMenu.treeSubtletyBtn = treeSubtletyBtn

        -- ── Combat header (4 buttons wide, centered) ─────────────────
        MakeWideBox(combatHdrX, combatHdrY, combatHdrW, "Combat")

        local treeDpsAoeBtn = MakeTreeBtn(assistHdrX + 60, assistIconY,
            "Interface\\Icons\\Spell_Shadow_RainOfFire", function()
            GameTooltip:SetText("|cffffcc00DPS AoE|r |cff999999- |r|cffFFF569aoe|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Cross-role AoE mode|r", 1, 1, 1)
            GameTooltip:AddLine("Switches to |cffffcc00AoE|r attacks on multiple targets.", 1, 1, 1)
        end)
        LichborneRogueMenu.treeDpsAoeBtn = treeDpsAoeBtn

        local treeStealthBtn = MakeTreeBtn(combatHdrX + 30, combatIconY,
            "Interface\\Icons\\Ability_Stealth", function()
            GameTooltip:SetText("|cffffcc00Stealth|r |cff999999- |r|cffFFF569stealth|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Activates Stealth mode|r", 1, 1, 1)
            GameTooltip:AddLine("Enters |cffffcc00Stealth|r between fights when possible.", 1, 1, 1)
        end)
        LichborneRogueMenu.treeStealthBtn = treeStealthBtn

        local treeStealthedBtn = MakeTreeBtn(combatHdrX + 60, combatIconY,
            "Interface\\Icons\\Ability_Sap", function()
            GameTooltip:SetText("|cffffcc00Stealthed|r |cff999999- |r|cffFFF569stealthed|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00In-combat stealth behavior|r", 1, 1, 1)
            GameTooltip:AddLine("Approaches targets in |cffffcc00Stealth|r.", 1, 1, 1)
            GameTooltip:AddLine("May pause DPS to re-stealth.", 1, 1, 1)
        end)
        LichborneRogueMenu.treeStealthedBtn = treeStealthedBtn

        local treeBoostBtn = MakeTreeBtn(combatHdrX + 90, combatIconY,
            "Interface\\Icons\\Ability_Mage_PotentSpirit", function()
            GameTooltip:SetText("|cffffcc00Boost|r |cff999999- |r|cffFFF569boost|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Offensive cooldown burst|r", 1, 1, 1)
            GameTooltip:AddLine("Works alongside all DPS modes.", 1, 1, 1)
        end)
        LichborneRogueMenu.treeBoostBtn = treeBoostBtn

        -- ── Assist header (3 buttons wide, centered) ──────────────────
        MakeWideBox(assistHdrX, assistHdrY, assistHdrW, "Assist")

        local treeTankAssistBtn = MakeTreeBtn(assistHdrX, assistIconY,
            "Interface\\Icons\\inv_shield_02", function()
            GameTooltip:SetText("|cffffcc00Tank Assist|r |cff999999- |r|cffff8000tank assist|r |cffffcc00CO|r")
            GameTooltip:AddLine("|cffffcc00Tank target focus|r", 1, 1, 1)
            GameTooltip:AddLine("Attacks the main tank's current target.", 1, 1, 1)
        end)
        LichborneRogueMenu.treeTankAssistBtn = treeTankAssistBtn

        local treeDpsAssistBtn = MakeTreeBtn(assistHdrX + 30, assistIconY,
            "Interface\\Icons\\Ability_Warrior_Challange", function()
            GameTooltip:SetText("|cffffcc00DPS Assist|r |cff999999- |r|cffff8000dps assist|r |cffffcc00CO|r")
            GameTooltip:AddLine("|cffffcc00Assists the main assist target|r", 1, 1, 1)
            GameTooltip:AddLine("Attacks the assist leader's target.", 1, 1, 1)
        end)
        LichborneRogueMenu.treeDpsAssistBtn = treeDpsAssistBtn

        local treeDpsBtn = MakeTreeBtn(combatHdrX, combatIconY,
            "Interface\\Icons\\inv_sword_27", function()
            GameTooltip:SetText("|cffffcc00Dps|r |cff999999- |r|cffFFF569dps|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Single-target DPS mode|r", 1, 1, 1)
            GameTooltip:AddLine("Uses the standard Combat rotation", 1, 1, 1)
            GameTooltip:AddLine("on the current target.", 1, 1, 1)
        end)
        LichborneRogueMenu.treeDpsBtn = treeDpsBtn

        -- ── Wire: toggle logic ────────────────────────────────────────────
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
                { cmd="melee", btn=treeAsBtn       },
                { cmd="dps",   btn=treeCombatBtn   },
                { cmd="melee", btn=treeSubtletyBtn },
            }
            for _, entry in ipairs(specList) do
                local btn = entry.btn
                local cmd = entry.cmd
                btn:SetScript("OnClick", function()
                    local bot = LichborneRogueMenu.botName or ""
                    LichborneRogueMenu._specUserSet = true
                    if btn.state then
                        PBM.SendToBot("co -" .. cmd .. ",?", bot); IconOff(btn)
                    else
                        PBM.SendToBot("co +" .. cmd .. ",?", bot); IconOn(btn)
                        for _, other in ipairs(specList) do
                            if other.btn ~= btn then IconOff(other.btn) end
                        end
                    end
                end)
            end

            -- TankAssist exclusive trio
            treeTankAssistBtn:SetScript("OnClick", function()
                local bot = LichborneRogueMenu.botName or ""
                LichborneRogueMenu._specUserSet = true
                if treeTankAssistBtn.state then
                    PBM.SendToBot("co -tank assist,?", bot); IconOff(treeTankAssistBtn)
                else
                    PBM.SendToBot("co +tank assist,?", bot); IconOn(treeTankAssistBtn)
                    IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            -- DpsAssist; also clears Stealthed
            treeDpsAssistBtn:SetScript("OnClick", function()
                local bot = LichborneRogueMenu.botName or ""
                LichborneRogueMenu._specUserSet = true
                if treeDpsAssistBtn.state then
                    PBM.SendToBot("co -dps assist,?", bot); IconOff(treeDpsAssistBtn)
                else
                    PBM.SendToBot("co +dps assist,?", bot); IconOn(treeDpsAssistBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAoeBtn); IconOff(treeStealthedBtn)
                end
            end)

            -- DpsAoe; also clears Stealthed
            treeDpsAoeBtn:SetScript("OnClick", function()
                local bot = LichborneRogueMenu.botName or ""
                LichborneRogueMenu._specUserSet = true
                if treeDpsAoeBtn.state then
                    PBM.SendToBot("co -aoe,?", bot); IconOff(treeDpsAoeBtn)
                else
                    PBM.SendToBot("co +aoe,?", bot); IconOn(treeDpsAoeBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeStealthedBtn)
                end
            end)

            -- Dps: clears Stealthed
            treeDpsBtn:SetScript("OnClick", function()
                local bot = LichborneRogueMenu.botName or ""
                LichborneRogueMenu._specUserSet = true
                if treeDpsBtn.state then
                    PBM.SendToBot("co -dps,?", bot); IconOff(treeDpsBtn)
                else
                    PBM.SendToBot("co +dps,?", bot); IconOn(treeDpsBtn)
                    IconOff(treeStealthedBtn)
                end
            end)

            -- Stealth (independent CO)
            treeStealthBtn:SetScript("OnClick", function()
                local bot = LichborneRogueMenu.botName or ""
                LichborneRogueMenu._specUserSet = true
                if treeStealthBtn.state then
                    PBM.SendToBot("co -stealth,?", bot); IconOff(treeStealthBtn)
                else
                    PBM.SendToBot("co +stealth,?", bot); IconOn(treeStealthBtn)
                end
            end)

            -- Stealthed: exclusive with Dps, DpsAoe, DpsAssist
            treeStealthedBtn:SetScript("OnClick", function()
                local bot = LichborneRogueMenu.botName or ""
                LichborneRogueMenu._specUserSet = true
                if treeStealthedBtn.state then
                    PBM.SendToBot("co -stealthed,?", bot); IconOff(treeStealthedBtn)
                else
                    PBM.SendToBot("co +stealthed,?", bot); IconOn(treeStealthedBtn)
                    IconOff(treeDpsBtn); IconOff(treeDpsAoeBtn); IconOff(treeDpsAssistBtn)
                end
            end)

            -- Boost (independent CO)
            treeBoostBtn:SetScript("OnClick", function()
                local bot = LichborneRogueMenu.botName or ""
                LichborneRogueMenu._specUserSet = true
                if treeBoostBtn.state then
                    PBM.SendToBot("co -boost,?", bot); IconOff(treeBoostBtn)
                else
                    PBM.SendToBot("co +boost,?", bot); IconOn(treeBoostBtn)
                end
            end)

            -- resetAllIcons: chain from base (food/loot/gather handled by base)
            local _baseReset = LichborneRogueMenu.resetSharedIcons
            LichborneRogueMenu.resetAllIcons = function()
                if _baseReset then _baseReset() end
                -- class-specific tree buttons only (food/loot/gather handled by base)
                IconOff(treeAsBtn); IconOff(treeCombatBtn); IconOff(treeSubtletyBtn)
                IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
                IconOff(treeDpsBtn); IconOff(treeStealthBtn); IconOff(treeStealthedBtn); IconOff(treeBoostBtn)
            end

            -- onStrategyUpdate
            local _baseSU = LichborneRogueMenu.onStrategyUpdate
            LichborneRogueMenu.onStrategyUpdate = function(stratType, activeSet)
                if _baseSU then _baseSU(stratType, activeSet) end
                if not LichborneRogueMenu._specUserSet then
                    if stratType == "co" then
                        -- Specs: full two-way
                        if activeSet["melee"] then IconOn(treeAsBtn)       else IconOff(treeAsBtn)       end
                        if activeSet["dps"]   then IconOn(treeCombatBtn)   else IconOff(treeCombatBtn)   end
                        if activeSet["melee"] then IconOn(treeSubtletyBtn) else IconOff(treeSubtletyBtn) end
                        -- Combat: full two-way
                        if activeSet["tank assist"] then IconOn(treeTankAssistBtn) else IconOff(treeTankAssistBtn) end
                        if activeSet["dps assist"]  then IconOn(treeDpsAssistBtn)  else IconOff(treeDpsAssistBtn)  end
                        if activeSet["aoe"]         then IconOn(treeDpsAoeBtn)     else IconOff(treeDpsAoeBtn)     end
                        if activeSet["dps"]         then IconOn(treeDpsBtn)        else IconOff(treeDpsBtn)        end
                        if activeSet["stealth"]     then IconOn(treeStealthBtn)    else IconOff(treeStealthBtn)    end
                        if activeSet["stealthed"]   then IconOn(treeStealthedBtn)  else IconOff(treeStealthedBtn)  end
                        if activeSet["boost"]       then IconOn(treeBoostBtn)      else IconOff(treeBoostBtn)      end
                    end
                end
            end
        end -- end toggle wire block
    end

    if LichborneRogueMenu:IsShown() and LichborneRogueMenu.sourceRow == row then
        HideAllRogue(); return
    end
    PBM.ShowCharSheet(LichborneRogueMenu, LichborneRogueCatcher, row, ROGUE_LEFT_EXT)
end
