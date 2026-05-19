PBM = PBM or {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Druid class-specific overlay panel — data
-- ─────────────────────────────────────────────────────────────────────────────

local DRUID_TALENT_SPECS = {
    { label="Balance |cffffcc00PvE|r",     spec="balance pve", wowSpec="Balance",     icon="Interface\\Icons\\Spell_Nature_StarFall"     },
    { label="Bear |cffffcc00PvE|r",        spec="bear pve",    wowSpec="Feral",       icon="Interface\\Icons\\Ability_Racial_BearForm"   },
    { label="Restoration |cffffcc00PvE|r", spec="resto pve",   wowSpec="Restoration", icon="Interface\\Icons\\Spell_Nature_HealingTouch" },
    { label="Cat |cffffcc00PvE|r",         spec="cat pve",     wowSpec="Feral",       icon="Interface\\Icons\\Ability_Druid_CatForm"     },
    { label="Balance |cffff4444PvP|r",     spec="balance pvp", wowSpec="Balance",     icon="Interface\\Icons\\Spell_Nature_StarFall"     },
    { label="Cat |cffff4444PvP|r",         spec="cat pvp",     wowSpec="Feral",       icon="Interface\\Icons\\Ability_Druid_CatForm"     },
    { label="Restoration |cffff4444PvP|r", spec="resto pvp",   wowSpec="Restoration", icon="Interface\\Icons\\Spell_Nature_HealingTouch" },
}

local EXT_ICON_SIZE = 26

-- ─────────────────────────────────────────────────────────────────────────────
-- Druid class-specific overlay panel — implementation
-- ─────────────────────────────────────────────────────────────────────────────
local LichborneDruidMenu
local LichborneDruidCatcher

local DRUID_LEFT_EXT = 5
local DRUID_OVL_W = (PBM.GEAR_OFF + PBM.GEAR_SLOTS * PBM.COL_GEAR_W) - PBM.GS_OFF + DRUID_LEFT_EXT
local DRUID_OVL_H = PBM.MAX_ROWS * PBM.ROW_HEIGHT + 12

local function HideAllDruid()
    PBM.HideCharSheet(LichborneDruidMenu, LichborneDruidCatcher)
end

function PBM.CloseDruidMenu()
    HideAllDruid()
end

function PBM.OpenDruidMenu(row)
    -- ── Lazy init ────────────────────────────────────────────────
    if not LichborneDruidMenu then

        LichborneDruidMenu, LichborneDruidCatcher = PBM.CreateCharSheet({
            menuName     = "LichborneDruidMenu",
            catcherName  = "LichborneDruidCatcher",
            className    = "Druid",
            classHex     = "FF7D0A",
            leftExt      = DRUID_LEFT_EXT,
            overlayW     = DRUID_OVL_W,
            overlayH     = DRUID_OVL_H,
            talentSpecs  = DRUID_TALENT_SPECS,
            hideCallback = HideAllDruid,
        })

        -- ── Strategy tree layout ─────────────────────────────────
        local HDR_H = PBM.ROW_HEIGHT

        local SPEC_BOX_BD = {
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        }
        local TREE_TOTAL_W = 4 * 70 + 3 * 4
        local TREE_X       = math.floor((DRUID_OVL_W - TREE_TOTAL_W) / 2)
        local TREE_TOP_Y   = -(HDR_H + 68)

        local function MakeSpecBox(parent, x, y, w, label, icon)
            local box = CreateFrame("Frame", nil, parent)
            box:SetSize(w, 18)
            box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
            box:SetBackdrop(SPEC_BOX_BD)
            box:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
            box:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
            if icon then
                local ico = box:CreateTexture(nil, "ARTWORK")
                ico:SetSize(14, 14)
                ico:SetPoint("LEFT", box, "LEFT", 2, 0)
                ico:SetTexture(icon)
            end
            local lbl = box:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            lbl:SetTextColor(0.78, 0.61, 0.23, 1)
            lbl:SetText(label)
            lbl:SetPoint("LEFT", box, "LEFT", icon and 18 or 4, 0)
            lbl:SetPoint("RIGHT", box, "RIGHT", -2, 0)
            lbl:SetJustifyH("CENTER")
            return box
        end

        local function MakeTreeBtn(parent, anchorFrame, anchorPoint, ox, oy, tex)
            local btn = CreateFrame("Button", nil, parent)
            btn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
            btn:SetPoint("TOPLEFT", anchorFrame, anchorPoint, ox, oy)
            local t = btn:CreateTexture(nil, "ARTWORK")
            t:SetAllPoints()
            t:SetTexture(tex)
            btn.icon = t
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            btn.state = false
            t:SetDesaturated(true)
            return btn
        end

        -- ── ROW 1 — Spec columns: Bear | Cat | Balance | Restoration ─
        local bearSpecBox = MakeSpecBox(LichborneDruidMenu,
            TREE_X,       TREE_TOP_Y - 16, 70, "Bear",        "Interface\\Icons\\Ability_Racial_BearForm")
        local catSpecBox  = MakeSpecBox(LichborneDruidMenu,
            TREE_X + 74,  TREE_TOP_Y - 16, 70, "Cat",         "Interface\\Icons\\Ability_Druid_CatForm")
        local balSpecBox  = MakeSpecBox(LichborneDruidMenu,
            TREE_X + 148, TREE_TOP_Y - 16, 70, "Balance",     "Interface\\Icons\\Spell_Nature_StarFall")
        local restoSpecBox = MakeSpecBox(LichborneDruidMenu,
            TREE_X + 222, TREE_TOP_Y - 16, 70, "Restoration", "Interface\\Icons\\Spell_Nature_HealingTouch")

        local treeBearBtn   = MakeTreeBtn(LichborneDruidMenu, bearSpecBox,  "BOTTOMLEFT", 22, -4, "Interface\\Icons\\Ability_Racial_BearForm")
        local treeCatBtn    = MakeTreeBtn(LichborneDruidMenu, catSpecBox,   "BOTTOMLEFT", 22, -4, "Interface\\Icons\\Ability_Druid_CatForm")
        local treeCasterBtn = MakeTreeBtn(LichborneDruidMenu, balSpecBox,   "BOTTOMLEFT", 22, -4, "Interface\\Icons\\Spell_Nature_StarFall")
        local treeHealBtn   = MakeTreeBtn(LichborneDruidMenu, restoSpecBox, "BOTTOMLEFT", 22, -4, "Interface\\Icons\\Spell_Nature_HealingTouch")

        treeBearBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Bear|r |cff999999- |r|cffFF7D0Abear|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Dire Bear Form|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0AFeral Charge, Mangle,|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0ALacerate|r |cffffcc00(5-stack),|r |cffFF7D0AMaul,|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0ASwipe|r |cffffcc00(AoE Threat),|r |cffFF7D0AFaerie Fire.|r", 1, 1, 1)
            GameTooltip:AddLine("|cffffcc00Defensive CDs:|r |cffFF7D0AFrenzied Regen, Barkskin.|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Cat, Balance, Heal, Off-Heal.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeBearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        treeCatBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Cat|r |cff999999- |r|cffFF7D0Acat|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Feral Cat melee DPS|r", 1, 1, 1)
            GameTooltip:AddLine("|cffffcc00Cat Form|r. Uses |cffffcc00Stealth|r opener:", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0APounce, Ravage, Savage Roar,|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0AMangle, Rake, Rip,|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0AFerocious Bite, Shred.|r", 1, 1, 1)
            GameTooltip:AddLine("|cffffcc00Energy CD:|r |cffFF7D0ATiger's Fury|r.", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Bear, Balance, Heal, Off-Heal.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeCatBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        treeCasterBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Balance|r |cff999999- |r|cffFF7D0Acaster|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Moonkin Form — Balance caster DPS|r", 1, 1, 1)
            GameTooltip:AddLine("|cffffcc00DoTs:|r |cffFF7D0AMoonfire, Insect Swarm.|r", 1, 1, 1)
            GameTooltip:AddLine("|cffffcc00Solar Eclipse:|r |cffFF7D0AWrath|r.", 1, 1, 1)
            GameTooltip:AddLine("|cffffcc00Lunar Eclipse:|r |cffFF7D0AStarfire|r.", 1, 1, 1)
            GameTooltip:AddLine("|cffffcc00Major CDs:|r |cffFF7D0AStarfall, Force of Nature.|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Bear, Cat, Heal, Off-Heal.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeCasterBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        treeHealBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Restoration|r |cff999999- |r|cffFF7D0Aheal|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Tree of Life — Restoration healer|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0ARejuvenation, Regrowth,|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0AWild Growth, Swiftmend.|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0AInnervate|r on lowest-|cff3A8FC4mana|r healer.", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0ARebirth|r battle-rez (highest priority).", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Bear, Cat, Balance, Off-Heal.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeHealBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        LichborneDruidMenu.treeBearBtn   = treeBearBtn
        LichborneDruidMenu.treeCatBtn    = treeCatBtn
        LichborneDruidMenu.treeCasterBtn = treeCasterBtn
        LichborneDruidMenu.treeHealBtn   = treeHealBtn

        -- ── ROW 2 — Melee (left) + Hybrid modifier (right) ──────────
        local meleeSpecBox = MakeSpecBox(LichborneDruidMenu, TREE_X, TREE_TOP_Y - 16, 70, "Melee", nil)
        meleeSpecBox:ClearAllPoints()
        meleeSpecBox:SetPoint("TOPLEFT", bearSpecBox, "BOTTOMLEFT", 79, -45)

        local treeMeleeBtn = MakeTreeBtn(LichborneDruidMenu, meleeSpecBox, "BOTTOMLEFT", 22, -4,
            "Interface\\Icons\\inv_sword_27")
        treeMeleeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Melee|r |cff999999- |r|cffddaa77melee|r |cffaaaaaaCO|r")
            GameTooltip:AddLine("|cffffcc00Generic melee mode|r", 1, 1, 1)
            GameTooltip:AddLine("Auto-attack with |cffffcc00Melee|r cooldowns.", 1, 1, 1)
            GameTooltip:AddLine("Stay in melee range, prefer physical attacks.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeMeleeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeMeleeBtn = treeMeleeBtn

        local hybridSpecBox = MakeSpecBox(LichborneDruidMenu, 0, 0, 60, "Hybrid", nil)
        hybridSpecBox:ClearAllPoints()
        hybridSpecBox:SetPoint("TOPLEFT", restoSpecBox, "BOTTOMLEFT", -69, -45)

        local treeHealerDpsBtn = MakeTreeBtn(LichborneDruidMenu, hybridSpecBox, "BOTTOMLEFT", 2, -4,
            "Interface\\Icons\\INV_Alchemy_Elixir_02")
        treeHealerDpsBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Healer DPS|r |cff999999- |r|cffFF7D0Ahealer dps|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Healer contributes DPS between heals|r", 1, 1, 1)
            GameTooltip:AddLine("Casts |cffFF7D0AMoonfire|r and |cffFF7D0AWrath|r when all", 1, 1, 1)
            GameTooltip:AddLine("party HP is high and no |cffffcc00HoTs|r are falling off.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeHealerDpsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeHealerDpsBtn = treeHealerDpsBtn

        local treeOffhealBtn = MakeTreeBtn(LichborneDruidMenu, hybridSpecBox, "BOTTOMLEFT", 32, -4,
            "Interface\\Icons\\Spell_Nature_HealingTouch")
        treeOffhealBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Off-Heal|r |cff999999- |r|cffFF7D0Aoffheal|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Cat DPS primary, heals when party drops low|r", 1, 1, 1)
            GameTooltip:AddLine("Stays in |cffffcc00Cat Form|r for DPS.", 1, 1, 1)
            GameTooltip:AddLine("Shifts out to cast |cffFF7D0ARegrowth, Rejuvenation,|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0ASwiftmend|r when a party member drops low.", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Bear, Cat, Balance, Heal.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeOffhealBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeOffhealBtn = treeOffhealBtn

        -- ── ROW 3 — AoE ──────────────────────────────────────────────
        local aoeSpecBox = MakeSpecBox(LichborneDruidMenu, 0, 0, 100, "AoE", nil)
        aoeSpecBox:ClearAllPoints()
        aoeSpecBox:SetPoint("TOPLEFT", meleeSpecBox, "BOTTOMLEFT", 17, -45)

        local treeCatAoeBtn = MakeTreeBtn(LichborneDruidMenu, aoeSpecBox, "BOTTOMLEFT", 2, -4,
            "Interface\\Icons\\Ability_Druid_Bash")
        treeCatAoeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Cat AoE|r |cff999999- |r|cffFF7D0Acat aoe|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Feral AoE rotation|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0ASwipe|r spam on melee-range targets.", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0AThrash|r (bleed AoE on all nearby).", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0AHurricane|r fallback at range.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeCatAoeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeCatAoeBtn = treeCatAoeBtn

        local treeCasterAoeBtn = MakeTreeBtn(LichborneDruidMenu, aoeSpecBox, "BOTTOMLEFT", 32, -4,
            "Interface\\Icons\\Spell_Arcane_StarFire")
        treeCasterAoeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Caster AoE|r |cff999999- |r|cffFF7D0Acaster aoe|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Balance AoE rotation|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0AHurricane|r channel (8-sec AoE slow + damage).", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0AStarfall|r if off cooldown.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeCasterAoeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeCasterAoeBtn = treeCasterAoeBtn

        local treeCasterDebuffBtn = MakeTreeBtn(LichborneDruidMenu, aoeSpecBox, "BOTTOMLEFT", 62, -4,
            "Interface\\Icons\\Ability_Druid_Cower")
        treeCasterDebuffBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Caster Debuff|r |cff999999- |r|cffFF7D0Acaster debuff|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Spread Balance DoTs|r", 1, 1, 1)
            GameTooltip:AddLine("Spreads |cffffcc00DoTs|r: |cffFF7D0AMoonfire, Insect Swarm|r", 1, 1, 1)
            GameTooltip:AddLine("across as many targets as possible.", 1, 1, 1)
            GameTooltip:AddLine("|cffffcc00DoTs|r run 12–18 sec before reapplication.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeCasterDebuffBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeCasterDebuffBtn = treeCasterDebuffBtn

        -- ── ROW 4 — Assist + Buff ─────────────────────────────────────
        local assistSpecBox = MakeSpecBox(LichborneDruidMenu, 0, 0, 90, "Assist", nil)
        assistSpecBox:ClearAllPoints()
        assistSpecBox:SetPoint("TOPLEFT", aoeSpecBox, "BOTTOMLEFT", 5, -45)

        local treeTankAssistBtn = MakeTreeBtn(LichborneDruidMenu, assistSpecBox, "BOTTOMLEFT", 2, -4,
            "Interface\\Icons\\inv_shield_02")
        treeTankAssistBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Tank Assist|r |cff999999- |r|cffff8000tank assist|r |cffffcc00CO|r")
            GameTooltip:AddLine("|cffffcc00Tank target focus|r", 1, 1, 1)
            GameTooltip:AddLine("Bot attacks the tank's current target.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeTankAssistBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeTankAssistBtn = treeTankAssistBtn

        local treeDpsAssistBtn = MakeTreeBtn(LichborneDruidMenu, assistSpecBox, "BOTTOMLEFT", 32, -4,
            "Interface\\Icons\\Ability_Warrior_Challange")
        treeDpsAssistBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00DPS Assist|r |cff999999- |r|cffff8000dps assist|r |cffffcc00CO|r")
            GameTooltip:AddLine("|cffffcc00Focus single-target DPS on assist target|r", 1, 1, 1)
            GameTooltip:AddLine("Bot attacks the group DPS focus target.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeDpsAssistBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeDpsAssistBtn = treeDpsAssistBtn

        local treeDpsAoeBtn = MakeTreeBtn(LichborneDruidMenu, assistSpecBox, "BOTTOMLEFT", 62, -4,
            "Interface\\Icons\\Spell_Shadow_RainOfFire")
        treeDpsAoeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00DPS AoE|r |cff999999- |r|cffFF7D0Adps aoe|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Cross-role AoE mode|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0ASwipe, Hurricane, Typhoon.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeDpsAoeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeDpsAoeBtn = treeDpsAoeBtn


        -- ── Left-side Buff header + button (below PvP in universal panel) ────────
        local buffSideHdrBox = CreateFrame("Frame", nil, LichborneDruidMenu)
        buffSideHdrBox:SetSize(EXT_ICON_SIZE + 8, 18)
        buffSideHdrBox:SetPoint("TOPLEFT", LichborneDruidMenu.treePvpBtn, "BOTTOMLEFT", -4, -8)
        buffSideHdrBox:SetBackdrop(SPEC_BOX_BD)
        buffSideHdrBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        buffSideHdrBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local buffSideHdrFs = buffSideHdrBox:CreateFontString(nil, "OVERLAY")
        buffSideHdrFs:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        buffSideHdrFs:SetTextColor(0.78, 0.61, 0.23, 1)
        buffSideHdrFs:SetAllPoints()
        buffSideHdrFs:SetJustifyH("CENTER")
        buffSideHdrFs:SetText("Buff")

        local treeSideBuffBtn = MakeTreeBtn(LichborneDruidMenu, buffSideHdrBox, "BOTTOMLEFT", 4, -1,
            "Interface\\Icons\\spell_nature_regeneration")
        treeSideBuffBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Buff|r |cff999999- |r|cffffff00buff|r |cffff8000NC|r")
            GameTooltip:AddLine("|cffffcc00Group stats buff|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF7D0AMark of the Wild|r on all party members.", 1, 1, 1)
            GameTooltip:AddLine("Upgrades to |cffFF7D0AGift of the Wild|r when |cffffcc00Wild Thornroot|r", 1, 1, 1)
            GameTooltip:AddLine("is in the bot's bags.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeSideBuffBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeSideBuffBtn = treeSideBuffBtn

        -- ── Wire toggle logic ─────────────────────────────────────────
        do
            local function IconOn(btn)
                btn.state = true
                if btn.icon then btn.icon:SetDesaturated(false) end
            end
            local function IconOff(btn)
                btn.state = false
                if btn.icon then btn.icon:SetDesaturated(true) end
            end

            IconOff(treeBearBtn);       IconOff(treeCatBtn)
            IconOff(treeCasterBtn);     IconOff(treeHealBtn)
            IconOff(treeMeleeBtn)
            IconOff(treeHealerDpsBtn);  IconOff(treeOffhealBtn)
            IconOff(treeCatAoeBtn);     IconOff(treeCasterAoeBtn); IconOff(treeCasterDebuffBtn)
            IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
            IconOff(treeSideBuffBtn)

            -- resetAllIcons extends the shared base (Food/Loot/Gather)
            local _baseReset = LichborneDruidMenu.resetSharedIcons
            LichborneDruidMenu.resetAllIcons = function()
                if _baseReset then _baseReset() end
                IconOff(treeBearBtn);       IconOff(treeCatBtn)
                IconOff(treeCasterBtn);     IconOff(treeHealBtn)
                IconOff(treeMeleeBtn)
                IconOff(treeHealerDpsBtn);  IconOff(treeOffhealBtn)
                IconOff(treeCatAoeBtn);     IconOff(treeCasterAoeBtn); IconOff(treeCasterDebuffBtn)
                IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
                IconOff(treeSideBuffBtn)
            end

            -- ── Row 1: Spec buttons (mutually exclusive) ──────────────
            treeBearBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeBearBtn.state then
                    PBM.SendToBot("co -bear,?", bot); IconOff(treeBearBtn)
                else
                    PBM.SendToBot("co +bear,?", bot); IconOn(treeBearBtn)
                    IconOff(treeCatBtn); IconOff(treeCasterBtn); IconOff(treeHealBtn)
                    IconOff(treeOffhealBtn)
                end
            end)

            treeCatBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeCatBtn.state then
                    PBM.SendToBot("co -cat,?", bot); IconOff(treeCatBtn)
                else
                    PBM.SendToBot("co +cat,?", bot); IconOn(treeCatBtn)
                    IconOff(treeBearBtn); IconOff(treeCasterBtn); IconOff(treeHealBtn)
                    IconOff(treeOffhealBtn)
                end
            end)

            treeCasterBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeCasterBtn.state then
                    PBM.SendToBot("co -caster,?", bot); IconOff(treeCasterBtn)
                else
                    PBM.SendToBot("co +caster,?", bot); IconOn(treeCasterBtn)
                    IconOff(treeBearBtn); IconOff(treeCatBtn); IconOff(treeHealBtn)
                    IconOff(treeOffhealBtn)
                end
            end)

            treeHealBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeHealBtn.state then
                    PBM.SendToBot("co -heal,?", bot); IconOff(treeHealBtn)
                else
                    PBM.SendToBot("co +heal,?", bot); IconOn(treeHealBtn)
                    IconOff(treeBearBtn); IconOff(treeCatBtn); IconOff(treeCasterBtn)
                    IconOff(treeOffhealBtn)
                end
            end)

            -- ── Row 2: Melee + Hybrid ──────────────────────────────────
            treeMeleeBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeMeleeBtn.state then
                    PBM.SendToBot("co -melee,?", bot); IconOff(treeMeleeBtn)
                else
                    PBM.SendToBot("co +melee,?", bot); IconOn(treeMeleeBtn)
                end
            end)

            treeHealerDpsBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeHealerDpsBtn.state then
                    PBM.SendToBot("co -healer dps,?", bot); IconOff(treeHealerDpsBtn)
                else
                    PBM.SendToBot("co +healer dps,?", bot); IconOn(treeHealerDpsBtn)
                    IconOff(treeOffhealBtn)
                end
            end)

            treeOffhealBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeOffhealBtn.state then
                    PBM.SendToBot("co -offheal,?", bot); IconOff(treeOffhealBtn)
                else
                    PBM.SendToBot("co +offheal,?", bot); IconOn(treeOffhealBtn)
                    IconOff(treeBearBtn); IconOff(treeCatBtn); IconOff(treeCasterBtn)
                    IconOff(treeHealerDpsBtn); IconOff(treeHealBtn)
                end
            end)

            -- ── Row 3: AoE (independent) ───────────────────────────────
            treeCatAoeBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeCatAoeBtn.state then
                    PBM.SendToBot("co -cat aoe,?", bot); IconOff(treeCatAoeBtn)
                else
                    PBM.SendToBot("co +cat aoe,?", bot); IconOn(treeCatAoeBtn)
                end
            end)

            treeCasterAoeBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeCasterAoeBtn.state then
                    PBM.SendToBot("co -caster aoe,?", bot); IconOff(treeCasterAoeBtn)
                else
                    PBM.SendToBot("co +caster aoe,?", bot); IconOn(treeCasterAoeBtn)
                end
            end)

            treeCasterDebuffBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeCasterDebuffBtn.state then
                    PBM.SendToBot("co -caster debuff,?", bot); IconOff(treeCasterDebuffBtn)
                else
                    PBM.SendToBot("co +caster debuff,?", bot); IconOn(treeCasterDebuffBtn)
                end
            end)

            -- ── Row 4: Assist (mutually exclusive) ────────────────────
            treeTankAssistBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeTankAssistBtn.state then
                    PBM.SendToBot("co -tank assist,?", bot); IconOff(treeTankAssistBtn)
                else
                    PBM.SendToBot("co +tank assist,?", bot); IconOn(treeTankAssistBtn)
                    IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            treeDpsAssistBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeDpsAssistBtn.state then
                    PBM.SendToBot("co -dps assist,?", bot); IconOff(treeDpsAssistBtn)
                else
                    PBM.SendToBot("co +dps assist,?", bot); IconOn(treeDpsAssistBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            treeDpsAoeBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeDpsAoeBtn.state then
                    PBM.SendToBot("co -dps aoe,?", bot); IconOff(treeDpsAoeBtn)
                else
                    PBM.SendToBot("co +dps aoe,?", bot); IconOn(treeDpsAoeBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn)
                end
            end)

            treeSideBuffBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeSideBuffBtn.state then
                    PBM.SendToBot("nc -buff,?", bot); IconOff(treeSideBuffBtn)
                else
                    PBM.SendToBot("nc +buff,?", bot); IconOn(treeSideBuffBtn)
                end
            end)

            -- onStrategyUpdate extends shared base (CO buttons + NC buff)
            local _baseSU = LichborneDruidMenu.onStrategyUpdate
            LichborneDruidMenu.onStrategyUpdate = function(stratType, activeSet)
                if _baseSU then _baseSU(stratType, activeSet) end
                if not LichborneDruidMenu._specUserSet then
                    if stratType == "co" then
                        if activeSet["bear"]          then IconOn(treeBearBtn)         else IconOff(treeBearBtn)         end
                        if activeSet["cat"]           then IconOn(treeCatBtn)          else IconOff(treeCatBtn)          end
                        if activeSet["caster"]        then IconOn(treeCasterBtn)       else IconOff(treeCasterBtn)       end
                        if activeSet["heal"]          then IconOn(treeHealBtn)         else IconOff(treeHealBtn)         end
                        if activeSet["melee"]         then IconOn(treeMeleeBtn)        else IconOff(treeMeleeBtn)        end
                        if activeSet["healer dps"]    then IconOn(treeHealerDpsBtn)    else IconOff(treeHealerDpsBtn)    end
                        if activeSet["offheal"]       then IconOn(treeOffhealBtn)      else IconOff(treeOffhealBtn)      end
                        if activeSet["cat aoe"]       then IconOn(treeCatAoeBtn)       else IconOff(treeCatAoeBtn)       end
                        if activeSet["caster aoe"]    then IconOn(treeCasterAoeBtn)    else IconOff(treeCasterAoeBtn)    end
                        if activeSet["caster debuff"] then IconOn(treeCasterDebuffBtn) else IconOff(treeCasterDebuffBtn) end
                        if activeSet["tank assist"]   then IconOn(treeTankAssistBtn)   else IconOff(treeTankAssistBtn)   end
                        if activeSet["dps assist"]    then IconOn(treeDpsAssistBtn)    else IconOff(treeDpsAssistBtn)    end
                        if activeSet["dps aoe"]       then IconOn(treeDpsAoeBtn)       else IconOff(treeDpsAoeBtn)       end
                    elseif stratType == "nc" then
                        if activeSet["buff"] then IconOn(treeSideBuffBtn) else IconOff(treeSideBuffBtn) end
                    end
                end
            end
        end -- end wire block
    end -- end lazy init

    -- ── Toggle: clicking same row while open closes the menu ─────
    if LichborneDruidMenu:IsShown() and LichborneDruidMenu.sourceRow == row then
        HideAllDruid()
        return
    end

    -- Clear previous row's name highlight if switching rows
    if LichborneDruidMenu.sourceRow and LichborneDruidMenu.sourceRow ~= row then
        local oldNb = LichborneDruidMenu.sourceRow.nameBox
        if oldNb then
            oldNb:SetBackdropColor(0.05, 0.07, 0.14, 0.8)
            oldNb:SetBackdropBorderColor(0.15, 0.22, 0.38, 0.7)
        end
    end

    PBM.ShowCharSheet(LichborneDruidMenu, LichborneDruidCatcher, row, DRUID_LEFT_EXT)
end
