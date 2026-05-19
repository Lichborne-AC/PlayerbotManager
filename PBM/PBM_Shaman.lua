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
    { label="Elemental |cffffcc00PvE|r",    spec="ele pve",   wowSpec="Elemental",           icon="Interface\\Icons\\Spell_Nature_Lightning"       },
    { label="Enhancement |cffffcc00PvE|r",  spec="enh pve",   wowSpec="Enhancement",         icon="Interface\\Icons\\Spell_Nature_LightningShield" },
    { label="Restoration |cffffcc00PvE|r",  spec="resto pve", wowSpec="Restoration Shaman",  icon="Interface\\Icons\\Spell_Nature_MagicImmunity"   },
    { label="Elemental |cffff4444PvP|r",    spec="ele pvp",   wowSpec="Elemental",           icon="Interface\\Icons\\Spell_Nature_Lightning"       },
    { label="Enhancement |cffff4444PvP|r",  spec="enh pvp",   wowSpec="Enhancement",         icon="Interface\\Icons\\Spell_Nature_LightningShield" },
    { label="Restoration |cffff4444PvP|r",  spec="resto pvp", wowSpec="Restoration Shaman",  icon="Interface\\Icons\\Spell_Nature_MagicImmunity"   },
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
        -- Each "tier" = box(18) + gap(4) + icon(26) = 48px, plus inter-tier gap(6)
        local specBoxY   = TREE_TOP_Y - 16                   -- row 1 header
        local specIconY  = specBoxY - 18 - 4                 -- row 1 icons
        local subBoxY    = specIconY - 26 - 6                -- row 2 header
        local subIconY   = subBoxY - 18 - 4                  -- row 2 icons
        local totBoxY    = subIconY - 26 - 6                 -- row 3 header
        local totLabelY  = totBoxY - 18 - 2                  -- CO/NC labels just below header
        local totIconY   = totBoxY - 18 - 12                 -- mana buttons (shifted down to clear labels)
        local totRow2Y   = totIconY - EXT_ICON_SIZE - 2      -- totems row 2: dps stacked under mana
        local assBoxY    = totRow2Y - EXT_ICON_SIZE - 6      -- row 4 header
        local assIconY   = assBoxY - 18 - 4                  -- row 4 icons

        -- ── Row 1: Spec columns ─────────────────────────────────────
        MakeSpecBox(col1X, specBoxY, SPEC_COL_W, "Elemental",
            "Interface\\Icons\\Spell_Nature_Lightning")
        MakeSpecBox(col2X, specBoxY, SPEC_COL_W, "Enhancement",
            "Interface\\Icons\\Spell_Nature_LightningShield")
        MakeSpecBox(col3X, specBoxY, SPEC_COL_W, "Restoration",
            "Interface\\Icons\\Spell_Nature_MagicImmunity")

        local treeEleBtn = MakeTreeBtn(col1X + ICON_OFF, specIconY,
            "Interface\\Icons\\Spell_Nature_Lightning",
            function()
                GameTooltip:SetText("|cffffcc00Elemental|r |cff999999- |r|cff0070DEelemental|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Elemental caster DPS|r", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DELightning Bolt, Chain Lightning, Lava Burst|r caster rotation.", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEFlame Shock|r maintains DoT; |cffffcc00Lava Surge|r proc enables instant |cff0070DELava Burst|r.", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEEarth Shock|r interrupt or execute. |cffffcc00AoE|r via |cff0070DEChain Lightning|r.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Mutually exclusive with Enhancement, Restoration.|r", 1, 1, 1)
            end)
        LichborneShamanMenu.treeEleBtn = treeEleBtn

        local treeEnhBtn = MakeTreeBtn(col2X + ICON_OFF, specIconY,
            "Interface\\Icons\\Spell_Nature_LightningShield",
            function()
                GameTooltip:SetText("|cffffcc00Enhancement|r |cff999999- |r|cff0070DEenhancement|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Enhancement melee DPS|r", 1, 1, 1)
                GameTooltip:AddLine("|cffffcc00Melee|r with |cff0070DEStormstrike, Lava Lash, Flametongue, Windfury.|r", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEStormstrike|r — Nature damage debuff on target.", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DELava Lash|r — OH attack scaled by |cff0070DEFlametongue|r.", 1, 1, 1)
                GameTooltip:AddLine("|cffffcc00Windfury|r proc grants extra melee swings.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Mutually exclusive with Elemental, Restoration.|r", 1, 1, 1)
            end)
        LichborneShamanMenu.treeEnhBtn = treeEnhBtn

        local treeRestoBtn = MakeTreeBtn(col3X + ICON_OFF, specIconY,
            "Interface\\Icons\\Spell_Nature_MagicImmunity",
            function()
                GameTooltip:SetText("|cffffcc00Restoration|r |cff999999- |r|cff0070DErestoration|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Restoration healing specialization|r", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEChain Heal, Riptide, Lesser Healing Wave, Healing Wave.|r", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DERiptide|r — instant |cffffcc00HoT|r, generates Tidal Waves.", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEChain Heal|r — Tidal Waves proc, 2+ injured.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Mutually exclusive with Elemental, Enhancement.|r", 1, 1, 1)
            end)
        LichborneShamanMenu.treeRestoBtn = treeRestoBtn

        -- ── Row 2: AoE | Healer DPS — centred pair ──────────────────────
        local pairW    = 2 * SPEC_COL_W + SPEC_COL_GAP                        -- 170
        local aoeHdrX  = TREE_X + math.floor((TREE_TOTAL_W - pairW) / 2)      -- TREE_X + 44
        local hdpsHdrX = aoeHdrX + SPEC_COL_W + SPEC_COL_GAP                  -- aoeHdrX + 88

        MakeWideBox(aoeHdrX,  subBoxY, SPEC_COL_W, "AoE")
        MakeWideBox(hdpsHdrX, subBoxY, SPEC_COL_W, "Healer DPS")

        -- Pack the two AoE buttons side-by-side, centred inside AoE header
        local AOE_PAIR_W = 2 * EXT_ICON_SIZE + 4
        local aoeLeft = aoeHdrX + math.floor((SPEC_COL_W - AOE_PAIR_W) / 2)

        local treeCasterAoeBtn = MakeTreeBtn(aoeLeft, subIconY,
            "Interface\\Icons\\Spell_Nature_LightningOverload",
            function()
                GameTooltip:SetText("|cffffcc00Caster AoE|r |cff999999- |r|cffff8000caster aoe|r |cffffcc00CO|r")
                GameTooltip:AddLine("|cffffcc00Caster AoE rotation|r", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEChain Lightning|r — bounces to 3 targets.", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEFire Nova|r — detonates on nearby targets.", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEThunderstorm|r — |cffffcc00AoE|r knockback and damage.", 1, 1, 1)
            end)
        LichborneShamanMenu.treeCasterAoeBtn = treeCasterAoeBtn

        local treeMeleeAoeBtn = MakeTreeBtn(aoeLeft + EXT_ICON_SIZE + 4, subIconY,
            "Interface\\Icons\\Ability_Warrior_Shockwave",
            function()
                GameTooltip:SetText("|cffffcc00Melee AoE|r |cff999999- |r|cffff8000melee aoe|r |cffffcc00CO|r")
                GameTooltip:AddLine("|cffffcc00Melee AoE rotation|r", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEFire Nova|r — detonates Flame Shock on targets.", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEMagma Totem|r — ground |cffffcc00AoE|r pulse.", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEChain Lightning|r — Maelstrom procs, 3 targets.", 1, 1, 1)
            end)
        LichborneShamanMenu.treeMeleeAoeBtn = treeMeleeAoeBtn

        -- Healer DPS — centred inside hdpsHdrX column
        local treeHealerDpsBtn = MakeTreeBtn(hdpsHdrX + math.floor((SPEC_COL_W - EXT_ICON_SIZE) / 2), subIconY,
            "Interface\\Icons\\INV_Alchemy_Elixir_02",
            function()
                GameTooltip:SetText("|cffffcc00Healer DPS|r |cff999999- |r|cffffcc00healer dps|r |cffff8000CO|r")
                GameTooltip:AddLine("|cffffcc00Healer that fills with DPS|r", 1, 1, 1)
                GameTooltip:AddLine("Casts |cff0070DELightning Bolt|r when no heals are needed.", 1, 1, 1)
                GameTooltip:AddLine("Maintains |cff0070DEEarth Shield|r and |cff0070DERiptide|r.", 1, 1, 1)
                GameTooltip:AddLine("Only attacks when all party HP is high.", 1, 1, 1)
            end)
        LichborneShamanMenu.treeHealerDpsBtn = treeHealerDpsBtn

        -- ── Row 3: Totems — [Totems btn] [CO: Mana/DPS stacked] [NC: Mana/DPS stacked] ─
        local TOT_LEFT_GAP = 10   -- gap between Totems btn and CO column
        local TOT_COL_GAP  = 4   -- gap between CO and NC columns
        local totNewW   = 3 * EXT_ICON_SIZE + TOT_LEFT_GAP + TOT_COL_GAP   -- 92px
        local totStartX = TREE_X + math.floor((TREE_TOTAL_W - totNewW) / 2)
        local totCoX    = totStartX + EXT_ICON_SIZE + TOT_LEFT_GAP
        local totNcX    = totCoX    + EXT_ICON_SIZE + TOT_COL_GAP

        MakeWideBox(totStartX, totBoxY, totNewW, "Totems")

        -- "CO" mini-label above CO column
        local coLabel = LichborneShamanMenu:CreateFontString(nil, "OVERLAY")
        coLabel:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        coLabel:SetTextColor(1, 0.82, 0)
        coLabel:SetText("CO")
        coLabel:SetPoint("TOPLEFT", LichborneShamanMenu, "TOPLEFT", totCoX, totLabelY)
        coLabel:SetWidth(EXT_ICON_SIZE)
        coLabel:SetJustifyH("CENTER")

        -- "NC" mini-label above NC column
        local ncLabel = LichborneShamanMenu:CreateFontString(nil, "OVERLAY")
        ncLabel:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        ncLabel:SetTextColor(0.6, 0.8, 1.0)
        ncLabel:SetText("NC")
        ncLabel:SetPoint("TOPLEFT", LichborneShamanMenu, "TOPLEFT", totNcX, totLabelY)
        ncLabel:SetWidth(EXT_ICON_SIZE)
        ncLabel:SetJustifyH("CENTER")

        -- Totems full-set (co +totems)
        local treeTotemsBtn = MakeTreeBtn(totStartX, totIconY,
            "Interface\\Icons\\INV_Relics_TotemOfRebirth",
            function()
                GameTooltip:SetText("|cffffcc00Totems|r |cff999999- |r|cffffff00totems|r |cffff8000CO|r")
                GameTooltip:AddLine("|cffffcc00Places situational totems|r", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEEle:|r Stoneskin, Wrath, Mana Spring, Wrath of Air.", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEEnh:|r Strength of Earth, Magma, Healing Stream, Windfury.", 1, 1, 1)
                GameTooltip:AddLine("|cff0070DEResto:|r Stoneskin, Flametongue, Mana Spring, Wrath of Air.", 1, 1, 1)
            end)
        LichborneShamanMenu.treeTotemsBtn = treeTotemsBtn

        -- CO: Mana Spring Totem (co +bmana) — radio with CombatDps
        local treeCombatManaBtn = MakeTreeBtn(totCoX, totIconY,
            "Interface\\Icons\\Spell_Nature_ManaRegenTotem",
            function()
                GameTooltip:SetText("|cffffcc00Mana Totem|r |cff999999- |r|cffffff00bmana|r |cffff8000CO|r")
                GameTooltip:AddLine("|cffffcc00Mana Spring Totem in combat|r", 1, 1, 1)
                GameTooltip:AddLine("Drops |cff0070DEMana Spring Totem|r on combat start.", 1, 1, 1)
                GameTooltip:AddLine("Provides passive mana regen for the group.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one totem set active at a time.|r", 1, 1, 1)
            end)
        LichborneShamanMenu.treeCombatManaBtn = treeCombatManaBtn

        -- CO: Windfury Totem (co +bdps) — radio with CombatMana
        local treeCombatDpsBtn = MakeTreeBtn(totCoX, totRow2Y,
            "Interface\\Icons\\Spell_Nature_Windfury",
            function()
                GameTooltip:SetText("|cffffcc00DPS Totem|r |cff999999- |r|cffffff00bdps|r |cffff8000CO|r")
                GameTooltip:AddLine("|cffffcc00Windfury Totem in combat|r", 1, 1, 1)
                GameTooltip:AddLine("Drops |cff0070DEWindfury Totem|r on combat start.", 1, 1, 1)
                GameTooltip:AddLine("Grants extra melee attacks to the group.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one totem set active at a time.|r", 1, 1, 1)
            end)
        LichborneShamanMenu.treeCombatDpsBtn = treeCombatDpsBtn

        -- NC: Mana Spring Totem (nc +bmana) — radio with NcDps
        local treeNcManaBtn = MakeTreeBtn(totNcX, totIconY,
            "Interface\\Icons\\Spell_Nature_ManaRegenTotem",
            function()
                GameTooltip:SetText("|cffffcc00Mana Totem|r |cff999999- |r|cffffff00bmana|r |cffff8000NC|r")
                GameTooltip:AddLine("|cffffcc00Mana Spring Totem out of combat|r", 1, 1, 1)
                GameTooltip:AddLine("Drops |cff0070DEMana Spring Totem|r between fights.", 1, 1, 1)
                GameTooltip:AddLine("Passive mana regen for the group at rest.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one totem set active at a time.|r", 1, 1, 1)
            end)
        LichborneShamanMenu.treeNcManaBtn = treeNcManaBtn

        -- NC: Windfury Totem (nc +bdps) — radio with NcMana
        local treeNcDpsBtn = MakeTreeBtn(totNcX, totRow2Y,
            "Interface\\Icons\\Spell_Nature_Windfury",
            function()
                GameTooltip:SetText("|cffffcc00DPS Totem|r |cff999999- |r|cffffff00bdps|r |cffff8000NC|r")
                GameTooltip:AddLine("|cffffcc00Windfury Totem out of combat|r", 1, 1, 1)
                GameTooltip:AddLine("Drops |cff0070DEWindfury Totem|r between fights.", 1, 1, 1)
                GameTooltip:AddLine("Melee haste for the group at rest.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one totem set active at a time.|r", 1, 1, 1)
            end)
        LichborneShamanMenu.treeNcDpsBtn = treeNcDpsBtn

        -- ── Row 4: Assist ────────────────────────────────────────────
        local ASS_TOTAL_W = 3 * EXT_ICON_SIZE                                  -- 78px, no gaps
        local assHdrX     = TREE_X + math.floor((TREE_TOTAL_W - ASS_TOTAL_W) / 2)

        MakeWideBox(assHdrX, assBoxY, ASS_TOTAL_W, "Assist")

        local function assX(idx)
            return assHdrX + idx * EXT_ICON_SIZE
        end

        local treeTankAssistBtn = MakeTreeBtn(assX(0), assIconY,
            "Interface\\Icons\\inv_shield_02",
            function()
                GameTooltip:SetText("|cffffcc00Tank Assist|r |cff999999- |r|cffff8000tank assist|r |cffffcc00CO|r")
                GameTooltip:AddLine("|cffffcc00Tank target focus|r", 1, 1, 1)
                GameTooltip:AddLine("Bot attacks whatever the main tank is targeting.", 1, 1, 1)
            end)
        LichborneShamanMenu.treeTankAssistBtn = treeTankAssistBtn

        local treeDpsAssistBtn = MakeTreeBtn(assX(1), assIconY,
            "Interface\\Icons\\Ability_Warrior_Challange",
            function()
                GameTooltip:SetText("|cffffcc00DPS Assist|r |cff999999- |r|cffff8000dps assist|r |cffffcc00CO|r")
                GameTooltip:AddLine("|cffffcc00Assists the main assist target|r", 1, 1, 1)
                GameTooltip:AddLine("Bot attacks the group DPS focus target.", 1, 1, 1)
            end)
        LichborneShamanMenu.treeDpsAssistBtn = treeDpsAssistBtn

        local treeDpsAoeBtn = MakeTreeBtn(assX(2), assIconY,
            "Interface\\Icons\\Spell_Shadow_RainOfFire",
            function()
                GameTooltip:SetText("|cffffcc00DPS AoE|r |cff999999- |r|cff0070DEaoe|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Cross-role AoE mode|r", 1, 1, 1)
                GameTooltip:AddLine("Switches to AoE rotation on multiple targets.", 1, 1, 1)
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
        cureSideHdrLabel:SetText("Cure")

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
            GameTooltip:SetText("|cffffcc00Cure|r |cff999999- |r|cffd4af37cure|r |cffff8000CO|r")
            GameTooltip:AddLine("|cffffcc00Cure debuffs on group members|r", 1, 1, 1)
            GameTooltip:AddLine("Cleanses poison, disease, and curses.", 1, 1, 1)
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
            IconOff(treeCasterAoeBtn); IconOff(treeMeleeAoeBtn);  IconOff(treeHealerDpsBtn)
            IconOff(treeTotemsBtn)
            IconOff(treeCombatManaBtn); IconOff(treeCombatDpsBtn)
            IconOff(treeNcManaBtn);     IconOff(treeNcDpsBtn)
            IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
            IconOff(treeCureBtn)

            local _baseReset = LichborneShamanMenu.resetSharedIcons
            LichborneShamanMenu.resetAllIcons = function()
                if _baseReset then _baseReset() end
                -- class-specific tree buttons only (food/loot/gather handled by base)
                IconOff(treeEleBtn);       IconOff(treeEnhBtn);       IconOff(treeRestoBtn)
                IconOff(treeCasterAoeBtn); IconOff(treeMeleeAoeBtn);  IconOff(treeHealerDpsBtn)
                IconOff(treeTotemsBtn)
                IconOff(treeCombatManaBtn); IconOff(treeCombatDpsBtn)
                IconOff(treeNcManaBtn);     IconOff(treeNcDpsBtn)
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

            treeCasterAoeBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeCasterAoeBtn.state then
                    PBM.SendToBot("co -caster aoe,?", bot)
                    IconOff(treeCasterAoeBtn)
                else
                    PBM.SendToBot("co +caster aoe,?", bot)
                    IconOn(treeCasterAoeBtn)
                end
            end)

            treeMeleeAoeBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeMeleeAoeBtn.state then
                    PBM.SendToBot("co -melee aoe,?", bot)
                    IconOff(treeMeleeAoeBtn)
                else
                    PBM.SendToBot("co +melee aoe,?", bot)
                    IconOn(treeMeleeAoeBtn)
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

            -- ── Row 3: Totems ─────────────────────────────────────────

            treeTotemsBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeTotemsBtn.state then
                    PBM.SendToBot("co -totems,?", bot)
                    IconOff(treeTotemsBtn)
                else
                    PBM.SendToBot("co +totems,?", bot)
                    IconOn(treeTotemsBtn)
                end
            end)

            -- CO totems: radio pair
            treeCombatManaBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeCombatManaBtn.state then
                    PBM.SendToBot("co -bmana,?", bot)
                    IconOff(treeCombatManaBtn)
                else
                    PBM.SendToBot("co +bmana,?", bot)
                    IconOn(treeCombatManaBtn)
                    IconOff(treeCombatDpsBtn)
                end
            end)

            treeCombatDpsBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeCombatDpsBtn.state then
                    PBM.SendToBot("co -bdps,?", bot)
                    IconOff(treeCombatDpsBtn)
                else
                    PBM.SendToBot("co +bdps,?", bot)
                    IconOn(treeCombatDpsBtn)
                    IconOff(treeCombatManaBtn)
                end
            end)

            -- NC totems: radio pair
            treeNcManaBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeNcManaBtn.state then
                    PBM.SendToBot("nc -bmana,?", bot)
                    IconOff(treeNcManaBtn)
                else
                    PBM.SendToBot("nc +bmana,?", bot)
                    IconOn(treeNcManaBtn)
                    IconOff(treeNcDpsBtn)
                end
            end)

            treeNcDpsBtn:SetScript("OnClick", function()
                local bot = LichborneShamanMenu.botName or ""
                LichborneShamanMenu._specUserSet = true
                if treeNcDpsBtn.state then
                    PBM.SendToBot("nc -bdps,?", bot)
                    IconOff(treeNcDpsBtn)
                else
                    PBM.SendToBot("nc +bdps,?", bot)
                    IconOn(treeNcDpsBtn)
                    IconOff(treeNcManaBtn)
                end
            end)

            -- ── Row 4: Assist (mutually exclusive) ────────────────────

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
                        if activeSet["caster aoe"]  then IconOn(treeCasterAoeBtn)  else IconOff(treeCasterAoeBtn) end
                        if activeSet["melee aoe"]   then IconOn(treeMeleeAoeBtn)   else IconOff(treeMeleeAoeBtn)  end
                        if activeSet["healer dps"]  then IconOn(treeHealerDpsBtn)  else IconOff(treeHealerDpsBtn) end
                        -- Totems
                        if activeSet["totems"] then IconOn(treeTotemsBtn) else IconOff(treeTotemsBtn) end
                        if activeSet["bmana"]  then IconOn(treeCombatManaBtn) else IconOff(treeCombatManaBtn) end
                        if activeSet["bdps"]   then IconOn(treeCombatDpsBtn)  else IconOff(treeCombatDpsBtn)  end
                        -- Assist + Cure
                        if activeSet["tank assist"] then IconOn(treeTankAssistBtn) else IconOff(treeTankAssistBtn) end
                        if activeSet["dps assist"]  then IconOn(treeDpsAssistBtn)  else IconOff(treeDpsAssistBtn)  end
                        if activeSet["aoe"]         then IconOn(treeDpsAoeBtn)     else IconOff(treeDpsAoeBtn)     end
                        if activeSet["cure"]        then IconOn(treeCureBtn)       else IconOff(treeCureBtn)       end
                    elseif stratType == "nc" then
                        if activeSet["bmana"]  then IconOn(treeNcManaBtn)   else IconOff(treeNcManaBtn)   end
                        if activeSet["bdps"]   then IconOn(treeNcDpsBtn)    else IconOff(treeNcDpsBtn)    end
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
