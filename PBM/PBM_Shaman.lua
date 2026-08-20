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
local SHAMAN_TALENT_SPECS = {
    { label=PBM_L["Elemental |cffffcc00PvE|r"],   spec="ele pve",   wowSpec="Elemental",           icon="Interface\\Icons\\Spell_Nature_Lightning"       },
    { label=PBM_L["Enhancement |cffffcc00PvE|r"], spec="enh pve",   wowSpec="Enhancement",         icon="Interface\\Icons\\Spell_Nature_LightningShield" },
    { label=PBM_L["Restoration |cffffcc00PvE|r"], spec="resto pve", wowSpec="Restoration Shaman",  icon="Interface\\Icons\\Spell_Nature_MagicImmunity"   },
    { label=PBM_L["Elemental |cffff4444PvP|r"],   spec="ele pvp",   wowSpec="Elemental",           icon="Interface\\Icons\\Spell_Nature_Lightning"       },
    { label=PBM_L["Enhancement |cffff4444PvP|r"], spec="enh pvp",   wowSpec="Enhancement",         icon="Interface\\Icons\\Spell_Nature_LightningShield" },
    { label=PBM_L["Restoration |cffff4444PvP|r"], spec="resto pvp", wowSpec="Restoration Shaman",  icon="Interface\\Icons\\Spell_Nature_MagicImmunity"   },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Shaman class-specific overlay panel
-- ─────────────────────────────────────────────────────────────────────────────
local LichborneShamanMenu
local LichborneShamanCatcher

local SHAMAN_LEFT_EXT = 5
local SHAMAN_OVL_W = (PBM.GEAR_OFF + PBM.GEAR_SLOTS * PBM.COL_GEAR_W) - PBM.GS_OFF + SHAMAN_LEFT_EXT
local SHAMAN_OVL_H = PBM.MAX_ROWS * PBM.ROW_HEIGHT + 12

local EXT_ICON_SIZE = 26

local function HideAllShaman()
    if LichborneShamanMenu and LichborneShamanMenu._closeMultibotSub then
        LichborneShamanMenu._closeMultibotSub()
    end
    PBM.HideCharSheet(LichborneShamanMenu, LichborneShamanCatcher)
end

function PBM.CloseShamanMenu()
    HideAllShaman()
end

function PBM.OpenShamanMenu(row)
    if not LichborneShamanMenu then
        LichborneShamanMenu, LichborneShamanCatcher = PBM.CreateCharSheet({
            menuName    = "LichborneShamanMenu",
            catcherName = "LichborneShamanCatcher",
            className   = "Shaman",
            classHex    = "0070DE",
            leftExt     = SHAMAN_LEFT_EXT,
            overlayW    = SHAMAN_OVL_W,
            overlayH    = SHAMAN_OVL_H,
            talentSpecs = SHAMAN_TALENT_SPECS,
            hideCallback = HideAllShaman,
        })

        -- ═══════════════════════════════════════════════════════════════
        -- Spec tree: Elemental / Enhancement / Restoration
        -- ═══════════════════════════════════════════════════════════════
        local SPEC_COL_W   = 82
        local SPEC_COL_GAP = 6
        local TREE_TOTAL_W = 3 * SPEC_COL_W + 2 * SPEC_COL_GAP   -- 258
        local TREE_X       = math.floor((SHAMAN_OVL_W - TREE_TOTAL_W) / 2)
        local TREE_TOP_Y   = -(PBM.ROW_HEIGHT + 68)

        -- Column left-edge X positions (relative to menu TOPLEFT)
        local col1X = TREE_X
        local col2X = TREE_X + SPEC_COL_W + SPEC_COL_GAP
        local col3X = TREE_X + 2 * (SPEC_COL_W + SPEC_COL_GAP)
        local ICON_OFF = math.floor((SPEC_COL_W - EXT_ICON_SIZE) / 2)  -- center icon in column (28)

        local SPEC_BOX_BD = {
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        }

        -- Shared helpers ------------------------------------------------
        local function MakeSpecBox(x, y, w, label, iconTex)
            local box = CreateFrame("Frame", nil, LichborneShamanMenu)
            box:SetSize(w, 18)
            box:SetPoint("TOPLEFT", LichborneShamanMenu, "TOPLEFT", x, y)
            box:SetBackdrop(SPEC_BOX_BD)
            box:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
            box:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
            if iconTex then
                local ico = box:CreateTexture(nil, "ARTWORK")
                ico:SetSize(14, 14)
                ico:SetPoint("LEFT", box, "LEFT", 2, 0)
                ico:SetTexture(iconTex)
            end
            local lbl = box:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
            lbl:SetTextColor(0.78, 0.61, 0.23, 1)
            lbl:SetText(label)
            lbl:SetPoint("LEFT",  box, "LEFT",  iconTex and 18 or 4, 0)
            lbl:SetPoint("RIGHT", box, "RIGHT", -2, 0)
            lbl:SetJustifyH("CENTER")
            return box
        end

        local function MakeWideBox(x, y, w, label)
            local box = CreateFrame("Frame", nil, LichborneShamanMenu)
            box:SetSize(w, 18)
            box:SetPoint("TOPLEFT", LichborneShamanMenu, "TOPLEFT", x, y)
            box:SetBackdrop(SPEC_BOX_BD)
            box:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
            box:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
            local lbl = box:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            lbl:SetTextColor(0.78, 0.61, 0.23, 1)
            lbl:SetText(label)
            lbl:SetAllPoints()
            lbl:SetJustifyH("CENTER")
            return box
        end

        local function MakeTreeBtn(bx, by, icon, tipFn)
            local btn = CreateFrame("Button", nil, LichborneShamanMenu)
            btn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
            btn:SetPoint("TOPLEFT", LichborneShamanMenu, "TOPLEFT", bx, by)
            local tex = btn:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:SetTexture(icon)
            btn.icon = tex
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            btn.state = false
            btn.icon:SetDesaturated(true)
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetFrameLevel(LichborneShamanMenu:GetFrameLevel() + 20)
                tipFn()
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            return btn
        end

        -- ── Compute Y rows ───────────────────────────────────────────
        -- Each "tier" = box(18) + gap(4) + icon(26) = 48px, plus inter-tier gap(15)
        local specBoxY   = TREE_TOP_Y - 16                   -- row 1 header
        local specIconY  = specBoxY - 18 - 4                 -- row 1 icons
        local subBoxY    = specIconY - 26 - 15               -- row 2 header
        local subIconY   = subBoxY - 18 - 4                  -- row 2 icons
        local assBoxY    = subIconY - 26 - 15                -- row 3 header
        local assIconY   = assBoxY - 18 - 4                  -- row 3 icons

        -- ── Row 1: Spec columns ─────────────────────────────────────
        MakeSpecBox(col1X, specBoxY, SPEC_COL_W, PBM_L["Elemental"],
            "Interface\\Icons\\Spell_Nature_Lightning")
        MakeSpecBox(col2X, specBoxY, SPEC_COL_W, PBM_L["Enhancement"],
            "Interface\\Icons\\Spell_Nature_LightningShield")
        MakeSpecBox(col3X, specBoxY, SPEC_COL_W, PBM_L["Restoration"],
            "Interface\\Icons\\Spell_Nature_MagicImmunity")

        local treeEleBtn = MakeTreeBtn(col1X + ICON_OFF, specIconY,
            "Interface\\Icons\\Spell_Nature_Lightning",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["Elemental"] .. "|r |cff999999- |r|cff0070DEelemental|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["Elemental caster DPS"] .. "|r", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444" .. PBM_L["Mutually exclusive with Enhancement, Restoration."] .. "|r", 1, 1, 1)
            end)
        LichborneShamanMenu.treeEleBtn = treeEleBtn

        local treeEnhBtn = MakeTreeBtn(col2X + ICON_OFF, specIconY,
            "Interface\\Icons\\Spell_Nature_LightningShield",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["Enhancement"] .. "|r |cff999999- |r|cff0070DEenhancement|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["Enhancement melee DPS"] .. "|r", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444" .. PBM_L["Mutually exclusive with Elemental, Restoration."] .. "|r", 1, 1, 1)
            end)
        LichborneShamanMenu.treeEnhBtn = treeEnhBtn

        local treeRestoBtn = MakeTreeBtn(col3X + ICON_OFF, specIconY,
            "Interface\\Icons\\Spell_Nature_MagicImmunity",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["Restoration"] .. "|r |cff999999- |r|cff0070DErestoration|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["Restoration healing specialization"] .. "|r", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444" .. PBM_L["Mutually exclusive with Elemental, Enhancement."] .. "|r", 1, 1, 1)
            end)
        LichborneShamanMenu.treeRestoBtn = treeRestoBtn

        -- ── Row 2: AoE | Healer DPS — centred pair ──────────────────────
        local pairW    = 2 * SPEC_COL_W + SPEC_COL_GAP                        -- 170
        local aoeHdrX  = TREE_X + math.floor((TREE_TOTAL_W - pairW) / 2)      -- TREE_X + 44
        local hdpsHdrX = aoeHdrX + SPEC_COL_W + SPEC_COL_GAP                  -- aoeHdrX + 88

        MakeWideBox(aoeHdrX,  subBoxY, SPEC_COL_W, PBM_L["AoE"])
        MakeWideBox(hdpsHdrX, subBoxY, SPEC_COL_W, PBM_L["Healer DPS"])

        local treeAoeBtn = MakeTreeBtn(aoeHdrX + math.floor((SPEC_COL_W - EXT_ICON_SIZE) / 2), subIconY,
            "Interface\\Icons\\Spell_Frost_IceStorm",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["AoE"] .. "|r |cff999999- |r|cff0070DEaoe|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["AoE rotation"] .. "|r", 1, 1, 1)
            end)
        LichborneShamanMenu.treeAoeBtn = treeAoeBtn

        -- Healer DPS — centred inside hdpsHdrX column
        local treeHealerDpsBtn = MakeTreeBtn(hdpsHdrX + math.floor((SPEC_COL_W - EXT_ICON_SIZE) / 2), subIconY,
            "Interface\\Icons\\INV_Alchemy_Elixir_02",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["Healer DPS"] .. "|r |cff999999- |r|cffffcc00healer dps|r |cffff8000CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["Healer that fills with DPS"] .. "|r", 1, 1, 1)
            end)
        LichborneShamanMenu.treeHealerDpsBtn = treeHealerDpsBtn

        -- ── Row 3: Assist ────────────────────────────────────────────
        local ASS_TOTAL_W = 3 * EXT_ICON_SIZE                                  -- 78px, no gaps
        local assHdrX     = TREE_X + math.floor((TREE_TOTAL_W - ASS_TOTAL_W) / 2)

        MakeWideBox(assHdrX, assBoxY, ASS_TOTAL_W, PBM_L["Assist"])

        local function assX(idx)
            return assHdrX + idx * EXT_ICON_SIZE
        end

        local treeTankAssistBtn = MakeTreeBtn(assX(0), assIconY,
            "Interface\\Icons\\inv_shield_02",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["Tank Assist"] .. "|r |cff999999- |r|cffff8000tank assist|r |cffffcc00CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["Tank target focus"] .. "|r", 1, 1, 1)
                GameTooltip:AddLine(PBM_L["Bot attacks whatever the main tank is targeting."], 1, 1, 1)
            end)
        LichborneShamanMenu.treeTankAssistBtn = treeTankAssistBtn

        local treeDpsAssistBtn = MakeTreeBtn(assX(1), assIconY,
            "Interface\\Icons\\Ability_Warrior_Challange",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["DPS Assist"] .. "|r |cff999999- |r|cffff8000dps assist|r |cffffcc00CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["Assists the main assist target"] .. "|r", 1, 1, 1)
                GameTooltip:AddLine(PBM_L["Bot attacks the group DPS focus target."], 1, 1, 1)
            end)
        LichborneShamanMenu.treeDpsAssistBtn = treeDpsAssistBtn

        local treeDpsAoeBtn = MakeTreeBtn(assX(2), assIconY,
            "Interface\\Icons\\Spell_Shadow_RainOfFire",
            function()
                GameTooltip:SetText("|cffffcc00" .. PBM_L["DPS AoE"] .. "|r |cff999999- |r|cff0070DEaoe|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00" .. PBM_L["Cross-role AoE mode"] .. "|r", 1, 1, 1)
                GameTooltip:AddLine(PBM_L["Switches to AoE rotation on multiple targets."], 1, 1, 1)
            end)
        LichborneShamanMenu.treeDpsAoeBtn = treeDpsAoeBtn

        -- ── Cure section (below PvP, Shaman-only) ────────────────────
        local CURE_HDR_W = EXT_ICON_SIZE + 8
        local cureSideHdrBox = CreateFrame("Frame", nil, LichborneShamanMenu)
        cureSideHdrBox:SetSize(CURE_HDR_W, 18)
        cureSideHdrBox:SetPoint("TOPLEFT", LichborneShamanMenu.treePvpBtn, "BOTTOMLEFT", -4, -8)
        cureSideHdrBox:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        cureSideHdrBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        cureSideHdrBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local cureSideHdrLabel = cureSideHdrBox:CreateFontString(nil, "OVERLAY")
        cureSideHdrLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        cureSideHdrLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        cureSideHdrLabel:SetAllPoints(); cureSideHdrLabel:SetJustifyH("CENTER")
        cureSideHdrLabel:SetText(PBM_L["Cure"])

        local treeCureBtn = CreateFrame("Button", nil, LichborneShamanMenu)
        treeCureBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeCureBtn:SetPoint("TOPLEFT", cureSideHdrBox, "BOTTOMLEFT",
            math.floor((CURE_HDR_W - EXT_ICON_SIZE) / 2), -1)
        local treeCureTex = treeCureBtn:CreateTexture(nil, "ARTWORK")
        treeCureTex:SetAllPoints()
        treeCureTex:SetTexture("Interface\\Icons\\ability_creature_poison_02")
        treeCureBtn.icon = treeCureTex
        treeCureBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeCureBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneShamanMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00" .. PBM_L["Cure"] .. "|r |cff999999- |r|cffd4af37cure|r |cffff8000CO|r")
            GameTooltip:AddLine("|cffffcc00" .. PBM_L["Cure debuffs on group members"] .. "|r", 1, 1, 1)
            GameTooltip:AddLine(PBM_L["Cleanses poison, disease, and curses."], 1, 1, 1)
            GameTooltip:Show()
        end)
        treeCureBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeCureBtn.state = false
        treeCureBtn.icon:SetDesaturated(true)
        LichborneShamanMenu.treeCureBtn = treeCureBtn

        -- ══════════════════════════════════════════════════════════════
        -- Wire Shaman toggle logic
        -- ══════════════════════════════════════════════════════════════
        do
            local function IconOn(btn)
                btn.state = true
                if btn.icon then btn.icon:SetDesaturated(false) end
            end
            local function IconOff(btn)
                btn.state = false
                if btn.icon then btn.icon:SetDesaturated(true) end
            end

            -- Initialise all desaturated (OFF)
            IconOff(treeEleBtn);       IconOff(treeEnhBtn);       IconOff(treeRestoBtn)
            IconOff(treeAoeBtn);  IconOff(treeHealerDpsBtn)
            IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
            IconOff(treeCureBtn)

            local _baseReset = LichborneShamanMenu.resetSharedIcons
            LichborneShamanMenu.resetAllIcons = function()
                if _baseReset then _baseReset() end
                -- class-specific tree buttons only (food/loot/gather handled by base)
                IconOff(treeEleBtn);       IconOff(treeEnhBtn);       IconOff(treeRestoBtn)
                IconOff(treeAoeBtn);  IconOff(treeHealerDpsBtn)
                IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
                IconOff(treeCureBtn)
            end

            -- ── Row 1: Spec (mutually exclusive) ──────────────────────

            treeEleBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeEleBtn.state then
                    PBM.SendToBot("co -ele,?", bot)
                    IconOff(treeEleBtn)
                else
                    PBM.SendToBot("co +ele,?", bot)
                    IconOn(treeEleBtn)
                    IconOff(treeEnhBtn); IconOff(treeRestoBtn)
                end
            end)

            treeEnhBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeEnhBtn.state then
                    PBM.SendToBot("co -enh,?", bot)
                    IconOff(treeEnhBtn)
                else
                    PBM.SendToBot("co +enh,?", bot)
                    IconOn(treeEnhBtn)
                    IconOff(treeEleBtn); IconOff(treeRestoBtn)
                end
            end)

            treeRestoBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeRestoBtn.state then
                    PBM.SendToBot("co -resto,?", bot)
                    IconOff(treeRestoBtn)
                else
                    PBM.SendToBot("co +resto,?", bot)
                    IconOn(treeRestoBtn)
                    IconOff(treeEleBtn); IconOff(treeEnhBtn)
                end
            end)

            -- ── Row 2: Sub-roles + Cure (independent) ─────────────────

            treeAoeBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeAoeBtn.state then
                    PBM.SendToBot("co -aoe,?", bot)
                    IconOff(treeAoeBtn)
                else
                    PBM.SendToBot("co +aoe,?", bot)
                    IconOn(treeAoeBtn)
                end
            end)

            treeHealerDpsBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeHealerDpsBtn.state then
                    PBM.SendToBot("co -healer dps,?", bot)
                    IconOff(treeHealerDpsBtn)
                else
                    PBM.SendToBot("co +healer dps,?", bot)
                    IconOn(treeHealerDpsBtn)
                end
            end)

            -- ── Row 3: Assist (mutually exclusive) ────────────────────

            treeTankAssistBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeTankAssistBtn.state then
                    PBM.SendToBot("co -tank assist,?", bot)
                    IconOff(treeTankAssistBtn)
                else
                    PBM.SendToBot("co +tank assist,?", bot)
                    IconOn(treeTankAssistBtn)
                    IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            treeDpsAssistBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeDpsAssistBtn.state then
                    PBM.SendToBot("co -dps assist,?", bot)
                    IconOff(treeDpsAssistBtn)
                else
                    PBM.SendToBot("co +dps assist,?", bot)
                    IconOn(treeDpsAssistBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            treeDpsAoeBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeDpsAoeBtn.state then
                    PBM.SendToBot("co -aoe,?", bot)
                    IconOff(treeDpsAoeBtn)
                else
                    PBM.SendToBot("co +aoe,?", bot)
                    IconOn(treeDpsAoeBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn)
                end
            end)

            -- ── Row 5: Cure (independent toggle) ─────────────────────
            treeCureBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeCureBtn.state then
                    PBM.SendToBot("co -cure,?", bot)
                    IconOff(treeCureBtn)
                else
                    PBM.SendToBot("co +cure,?", bot)
                    IconOn(treeCureBtn)
                end
            end)

            -- ── State restore from co?/nc? query ──────────────────────
            local _baseSU = LichborneShamanMenu.onStrategyUpdate
            LichborneShamanMenu.onStrategyUpdate = function(stratType, activeSet)
                if _baseSU then _baseSU(stratType, activeSet) end
                if not LichborneShamanMenu._specUserSet then
                    if stratType == "co" then
                        -- Spec (mutually exclusive) — only sync on initial load
                        if activeSet["ele"]   then IconOn(treeEleBtn)   else IconOff(treeEleBtn)   end
                        if activeSet["enh"]   then IconOn(treeEnhBtn)   else IconOff(treeEnhBtn)   end
                        if activeSet["resto"] then IconOn(treeRestoBtn) else IconOff(treeRestoBtn) end
                        -- Sub-roles
                        if activeSet["aoe"]         then IconOn(treeAoeBtn)        else IconOff(treeAoeBtn)       end
                        if activeSet["healer dps"]  then IconOn(treeHealerDpsBtn)  else IconOff(treeHealerDpsBtn) end
                        -- Assist + Cure
                        if activeSet["tank assist"] then IconOn(treeTankAssistBtn) else IconOff(treeTankAssistBtn) end
                        if activeSet["dps assist"]  then IconOn(treeDpsAssistBtn)  else IconOff(treeDpsAssistBtn)  end
                        if activeSet["aoe"]         then IconOn(treeDpsAoeBtn)     else IconOff(treeDpsAoeBtn)     end
                        if activeSet["cure"]        then IconOn(treeCureBtn)       else IconOff(treeCureBtn)       end
                    end
                end
            end
        end -- end toggle wire block
    end

    if LichborneShamanMenu:IsShown() and LichborneShamanMenu.sourceRow == row then
        HideAllShaman(); return
    end
    PBM.ShowCharSheet(LichborneShamanMenu, LichborneShamanCatcher, row, SHAMAN_LEFT_EXT)
end