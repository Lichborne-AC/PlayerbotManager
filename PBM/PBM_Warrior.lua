PBM = PBM or {}

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

local WARRIOR_TALENT_SPECS = {
    { label="Arms |cffffcc00PvE|r",       spec="arms pve", wowSpec="Arms",               icon="Interface\\Icons\\Ability_Warrior_Sunder"          },
    { label="Fury |cffffcc00PvE|r",       spec="fury pve", wowSpec="Fury",               icon="Interface\\Icons\\Ability_Warrior_InnerRage"       },
    { label="Protection |cffffcc00PvE|r", spec="prot pve", wowSpec="Protection Warrior", icon="Interface\\Icons\\Ability_Warrior_DefensiveStance" },
    { label="Arms |cffff4444PvP|r",       spec="arms pvp", wowSpec="Arms",               icon="Interface\\Icons\\Ability_Warrior_Sunder"          },
    { label="Fury |cffff4444PvP|r",       spec="fury pvp", wowSpec="Fury",               icon="Interface\\Icons\\Ability_Warrior_InnerRage"       },
    { label="Protection |cffff4444PvP|r", spec="prot pvp", wowSpec="Protection Warrior", icon="Interface\\Icons\\Ability_Warrior_DefensiveStance" },
}

local LichborneWarriorMenu
local LichborneWarriorCatcher

local WARRIOR_LEFT_EXT = 5
local WARRIOR_OVL_W = (PBM.GEAR_OFF + PBM.GEAR_SLOTS * PBM.COL_GEAR_W) - PBM.GS_OFF + WARRIOR_LEFT_EXT
local WARRIOR_OVL_H = PBM.MAX_ROWS * PBM.ROW_HEIGHT + 12

local EXT_ICON_SIZE = 26

local function HideAllWarrior()
    PBM.HideCharSheet(LichborneWarriorMenu, LichborneWarriorCatcher)
end

function PBM.CloseWarriorMenu()
    HideAllWarrior()
end

function PBM.OpenWarriorMenu(row)
    if not LichborneWarriorMenu then
        LichborneWarriorMenu, LichborneWarriorCatcher = PBM.CreateCharSheet({
            menuName     = "LichborneWarriorMenu",
            catcherName  = "LichborneWarriorCatcher",
            className    = "Warrior",
            classHex     = "C79C6E",
            leftExt      = WARRIOR_LEFT_EXT,
            overlayW     = WARRIOR_OVL_W,
            overlayH     = WARRIOR_OVL_H,
            talentSpecs  = WARRIOR_TALENT_SPECS,
            hideCallback = HideAllWarrior,
        })

        -- ── Strategy tree layout ─────────────────────────────────────
        local TREE_TOTAL_W = 258
        local TREE_X       = math.floor((WARRIOR_OVL_W - TREE_TOTAL_W) / 2)
        local TREE_TOP_Y   = -(PBM.ROW_HEIGHT + 68)

        local specBoxY  = TREE_TOP_Y - 16
        local specIconY = specBoxY - 18 - 3

        local SPEC_BOX_BD = {
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        }

        local function MakeWideBox(x, y, w, label, icon)
            local box = CreateFrame("Frame", nil, LichborneWarriorMenu)
            box:SetSize(w, 18)
            box:SetPoint("TOPLEFT", LichborneWarriorMenu, "TOPLEFT", x, y)
            box:SetBackdrop(SPEC_BOX_BD)
            box:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
            box:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
            if icon then
                local ic = box:CreateTexture(nil, "ARTWORK")
                ic:SetSize(14, 14)
                ic:SetPoint("LEFT", box, "LEFT", 2, 0)
                ic:SetTexture(icon)
            end
            local lbl = box:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            lbl:SetTextColor(0.78, 0.61, 0.23, 1)
            lbl:SetText(label)
            if icon then
                lbl:SetPoint("LEFT", box, "LEFT", 18, 0)
                lbl:SetPoint("RIGHT", box, "RIGHT", -2, 0)
            else
                lbl:SetAllPoints()
            end
            lbl:SetJustifyH("CENTER")
            return box
        end

        local function MakeTreeBtn(bx, by, icon, tipFn)
            local btn = CreateFrame("Button", nil, LichborneWarriorMenu)
            btn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
            btn:SetPoint("TOPLEFT", LichborneWarriorMenu, "TOPLEFT", bx, by)
            local tex = btn:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:SetTexture(icon)
            tex:SetDesaturated(true)
            btn.icon = tex
            btn.state = false
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetFrameLevel(LichborneWarriorMenu:GetFrameLevel() + 20)
                GameTooltip:ClearLines()
                tipFn()
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            return btn
        end

        local ROW_GAP  = 45
        local BOX_H    = 18

        -- ── 3 Spec columns: Arms | Fury | Protection ──────────────────
        local COL_W     = 60
        local COL_GAP   = 8
        local SPEC_W    = 3 * COL_W + 2 * COL_GAP
        local col1X     = math.floor(WARRIOR_OVL_W / 2) - math.floor(SPEC_W / 2)
        local col2X     = col1X + COL_W + COL_GAP
        local col3X     = col2X + COL_W + COL_GAP
        local CENTER_X  = col1X + math.floor(SPEC_W / 2)
        local singleOff = math.floor((COL_W - EXT_ICON_SIZE) / 2)

        MakeWideBox(col1X, specBoxY, COL_W, PBM_L["Arms"],       "Interface\\Icons\\Ability_Warrior_Sunder")
        MakeWideBox(col2X, specBoxY, COL_W, PBM_L["Fury"],       "Interface\\Icons\\Ability_Warrior_InnerRage")
        MakeWideBox(col3X, specBoxY, COL_W, PBM_L["Protection"], "Interface\\Icons\\Ability_Warrior_DefensiveStance")

        local treeArmsBtn = MakeTreeBtn(col1X + singleOff, specIconY,
            "Interface\\Icons\\Ability_Warrior_Sunder",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["Arms"] .. "|r |cff999999- |r|cffC79C6Earms|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["Arms DPS"] .. "|r", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444" .. PBM_L["Mutually exclusive with Fury, Protection."] .. "|r", 1, 1, 1)
            end)
        LichborneWarriorMenu.treeArmsBtn = treeArmsBtn

        local treeFuryBtn = MakeTreeBtn(col2X + singleOff, specIconY,
            "Interface\\Icons\\Ability_Warrior_InnerRage",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["Fury"] .. "|r |cff999999- |r|cffC79C6Efury|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["Fury DPS"] .. "|r", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444" .. PBM_L["Mutually exclusive with Arms, Protection."] .. "|r", 1, 1, 1)
            end)
        LichborneWarriorMenu.treeFuryBtn = treeFuryBtn

        local treeTankBtn = MakeTreeBtn(col3X + singleOff, specIconY,
            "Interface\\Icons\\Ability_Warrior_DefensiveStance",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["Protection"] .. "|r |cff999999- |r|cffC79C6Etank|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["Protection tank"] .. "|r", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444" .. PBM_L["Mutually exclusive with Arms, Fury."] .. "|r", 1, 1, 1)
            end)
        LichborneWarriorMenu.treeTankBtn = treeTankBtn

        -- Row 2 — AoE
        local aoeBoxY  = specBoxY - BOX_H - ROW_GAP
        local aoeIconY = aoeBoxY  - BOX_H - 3
        local aoeBoxW  = 60
        MakeWideBox(CENTER_X - math.floor(aoeBoxW / 2), aoeBoxY, aoeBoxW, PBM_L["AoE"])

        local treeDpsAoeBtn = MakeTreeBtn(CENTER_X - 13, aoeIconY,
            "Interface\\Icons\\Spell_Frost_IceStorm",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["DPS AoE"] .. "|r |cff999999- |r|cffC79C6Eaoe|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["Cross-role AoE mode"] .. "|r", 1, 1, 1)
            end)
        LichborneWarriorMenu.treeDpsAoeBtn = treeDpsAoeBtn

        -- Row 3 — Assist (Tank Assist | DPS Assist side by side)
        local assistBoxY  = aoeBoxY  - BOX_H - ROW_GAP
        local assistIconY = assistBoxY - BOX_H - 3
        local assistBoxW  = 84
        MakeWideBox(CENTER_X - math.floor(assistBoxW / 2), assistBoxY, assistBoxW, PBM_L["Assist"])

        local treeTankAssistBtn = MakeTreeBtn(CENTER_X - 28, assistIconY,
            "Interface\\Icons\\inv_shield_02",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["Tank Assist"] .. "|r |cff999999- |r|cffff8000tank assist|r |cffffcc00CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["Tank target focus"] .. "|r", 1, 1, 1)
                GameTooltip:AddLine(PBM_L["Bot attacks the tank's current target."], 1, 1, 1)
            end)
        LichborneWarriorMenu.treeTankAssistBtn = treeTankAssistBtn

        local treeDpsAssistBtn = MakeTreeBtn(CENTER_X + 2, assistIconY,
            "Interface\\Icons\\Ability_Warrior_Challange",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["DPS Assist"] .. "|r |cff999999- |r|cffff8000dps assist|r |cffffcc00CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["DPS target focus"] .. "|r", 1, 1, 1)
                GameTooltip:AddLine(PBM_L["Bot attacks the group DPS focus target."], 1, 1, 1)
            end)
        LichborneWarriorMenu.treeDpsAssistBtn = treeDpsAssistBtn

        -- ── Wire ────────────────────────────────────────────────────────
        do
            local function IconOn(btn)
                btn.state = true
                if btn.icon then btn.icon:SetDesaturated(false) end
            end
            local function IconOff(btn)
                btn.state = false
                if btn.icon then btn.icon:SetDesaturated(true) end
            end

            -- Arms (exclusive with Fury, Protection)
            treeArmsBtn:SetScript("OnClick", function()
                local bot = LichborneWarriorMenu.botName or ""
                LichborneWarriorMenu._specUserSet = true
                if treeArmsBtn.state then
                    PBM.SendToBot("co -arms,?", bot); IconOff(treeArmsBtn)
                else
                    PBM.SendToBot("co +arms,?", bot); IconOn(treeArmsBtn)
                    IconOff(treeFuryBtn); IconOff(treeTankBtn)
                end
            end)

            -- Fury (exclusive with Arms, Protection)
            treeFuryBtn:SetScript("OnClick", function()
                local bot = LichborneWarriorMenu.botName or ""
                LichborneWarriorMenu._specUserSet = true
                if treeFuryBtn.state then
                    PBM.SendToBot("co -fury,?", bot); IconOff(treeFuryBtn)
                else
                    PBM.SendToBot("co +fury,?", bot); IconOn(treeFuryBtn)
                    IconOff(treeArmsBtn); IconOff(treeTankBtn)
                end
            end)

            -- Protection (exclusive with Arms, Fury, and all assist/aoe modes)
            treeTankBtn:SetScript("OnClick", function()
                local bot = LichborneWarriorMenu.botName or ""
                LichborneWarriorMenu._specUserSet = true
                if treeTankBtn.state then
                    PBM.SendToBot("co -tank,?", bot); IconOff(treeTankBtn)
                else
                    PBM.SendToBot("co +tank,?", bot); IconOn(treeTankBtn)
                    IconOff(treeArmsBtn); IconOff(treeFuryBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            -- TankAssist / DpsAssist / DpsAoe exclusive trio
            treeTankAssistBtn:SetScript("OnClick", function()
                local bot = LichborneWarriorMenu.botName or ""
                LichborneWarriorMenu._specUserSet = true
                if treeTankAssistBtn.state then
                    PBM.SendToBot("co -tank assist,?", bot); IconOff(treeTankAssistBtn)
                else
                    PBM.SendToBot("co +tank assist,?", bot); IconOn(treeTankAssistBtn)
                    IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            treeDpsAssistBtn:SetScript("OnClick", function()
                local bot = LichborneWarriorMenu.botName or ""
                LichborneWarriorMenu._specUserSet = true
                if treeDpsAssistBtn.state then
                    PBM.SendToBot("co -dps assist,?", bot); IconOff(treeDpsAssistBtn)
                else
                    PBM.SendToBot("co +dps assist,?", bot); IconOn(treeDpsAssistBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            treeDpsAoeBtn:SetScript("OnClick", function()
                local bot = LichborneWarriorMenu.botName or ""
                LichborneWarriorMenu._specUserSet = true
                if treeDpsAoeBtn.state then
                    PBM.SendToBot("co -aoe,?", bot); IconOff(treeDpsAoeBtn)
                else
                    PBM.SendToBot("co +aoe,?", bot); IconOn(treeDpsAoeBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn)
                end
            end)

            local _baseReset = LichborneWarriorMenu.resetSharedIcons
            LichborneWarriorMenu.resetAllIcons = function()
                if _baseReset then _baseReset() end
                IconOff(treeArmsBtn); IconOff(treeFuryBtn); IconOff(treeTankBtn)
                IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
            end

            local _baseSU = LichborneWarriorMenu.onStrategyUpdate
            LichborneWarriorMenu.onStrategyUpdate = function(stratType, activeSet)
                if _baseSU then _baseSU(stratType, activeSet) end
                if not LichborneWarriorMenu._specUserSet then
                    if stratType == "co" then
                        if activeSet["arms"]        then IconOn(treeArmsBtn)        else IconOff(treeArmsBtn)        end
                        if activeSet["fury"]        then IconOn(treeFuryBtn)        else IconOff(treeFuryBtn)        end
                        if activeSet["tank"]        then IconOn(treeTankBtn)        else IconOff(treeTankBtn)        end
                        if activeSet["tank assist"] then IconOn(treeTankAssistBtn)  else IconOff(treeTankAssistBtn)  end
                        if activeSet["dps assist"]  then IconOn(treeDpsAssistBtn)   else IconOff(treeDpsAssistBtn)   end
                        if activeSet["aoe"]         then IconOn(treeDpsAoeBtn)      else IconOff(treeDpsAoeBtn)      end
                    end
                end
            end
        end
    end

    if LichborneWarriorMenu:IsShown() and LichborneWarriorMenu.sourceRow == row then
        HideAllWarrior(); return
    end
    PBM.ShowCharSheet(LichborneWarriorMenu, LichborneWarriorCatcher, row, WARRIOR_LEFT_EXT)
end