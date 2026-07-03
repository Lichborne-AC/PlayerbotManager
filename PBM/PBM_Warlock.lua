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
local WARLOCK_TALENT_SPECS = {
    { label="Affliction |cffffcc00PvE|r",  spec="affli pve",  wowSpec="Affliction",  icon="Interface\\Icons\\Spell_Shadow_DeathCoil"      },
    { label="Demonology |cffffcc00PvE|r",  spec="demo pve",   wowSpec="Demonology",  icon="Interface\\Icons\\Spell_Shadow_Metamorphosis"  },
    { label="Destruction |cffffcc00PvE|r", spec="destro pve", wowSpec="Destruction", icon="Interface\\Icons\\Spell_Shadow_RainOfFire"     },
    { label="Affliction |cffff4444PvP|r",  spec="affli pvp",  wowSpec="Affliction",  icon="Interface\\Icons\\Spell_Shadow_DeathCoil"      },
    { label="Demonology |cffff4444PvP|r",  spec="demo pvp",   wowSpec="Demonology",  icon="Interface\\Icons\\Spell_Shadow_Metamorphosis"  },
    { label="Destruction |cffff4444PvP|r", spec="destro pvp", wowSpec="Destruction", icon="Interface\\Icons\\Spell_Shadow_RainOfFire"     },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Warlock class-specific overlay panel
-- ─────────────────────────────────────────────────────────────────────────────
local LichborneWarlockMenu
local LichborneWarlockCatcher

local WARLOCK_LEFT_EXT = 5
local WARLOCK_OVL_W = (PBM.GEAR_OFF + PBM.GEAR_SLOTS * PBM.COL_GEAR_W) - PBM.GS_OFF + WARLOCK_LEFT_EXT
local WARLOCK_OVL_H = PBM.MAX_ROWS * PBM.ROW_HEIGHT + 12

local EXT_ICON_SIZE = 26

local function HideAllWarlock()
    PBM.HideCharSheet(LichborneWarlockMenu, LichborneWarlockCatcher)
end

function PBM.CloseWarlockMenu()
    HideAllWarlock()
end

function PBM.OpenWarlockMenu(row)
    if not LichborneWarlockMenu then
        LichborneWarlockMenu, LichborneWarlockCatcher = PBM.CreateCharSheet({
            menuName    = "LichborneWarlockMenu",
            catcherName = "LichborneWarlockCatcher",
            className   = "Warlock",
            classHex    = "9482C9",
            leftExt     = WARLOCK_LEFT_EXT,
            overlayW    = WARLOCK_OVL_W,
            overlayH    = WARLOCK_OVL_H,
            talentSpecs = WARLOCK_TALENT_SPECS,
            hideCallback = HideAllWarlock,
        })

        -- ═══════════════════════════════════════════════════════════════
        -- Strategy tree layout
        -- ═══════════════════════════════════════════════════════════════
        local HDR_H = PBM.ROW_HEIGHT

        local SPEC_COL_W   = 82
        local SPEC_COL_GAP = 6
        local TREE_TOTAL_W = 3 * SPEC_COL_W + 2 * SPEC_COL_GAP   -- 258
        local TREE_X       = math.floor((WARLOCK_OVL_W - TREE_TOTAL_W) / 2)
        local TREE_TOP_Y   = -(HDR_H + 68)
        local ICON_OFF     = math.floor((SPEC_COL_W - EXT_ICON_SIZE) / 2)

        local col1X = TREE_X
        local col2X = TREE_X + SPEC_COL_W + SPEC_COL_GAP
        local col3X = TREE_X + 2 * (SPEC_COL_W + SPEC_COL_GAP)

        local SPEC_BOX_BD = {
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        }

        -- Shared helpers ──────────────────────────────────────────────
        local function MakeSpecBox(x, y, w, label, iconTex)
            local box = CreateFrame("Frame", nil, LichborneWarlockMenu)
            box:SetSize(w, 18)
            box:SetPoint("TOPLEFT", LichborneWarlockMenu, "TOPLEFT", x, y)
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
            local box = CreateFrame("Frame", nil, LichborneWarlockMenu)
            box:SetSize(w, 18)
            box:SetPoint("TOPLEFT", LichborneWarlockMenu, "TOPLEFT", x, y)
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
            local btn = CreateFrame("Button", nil, LichborneWarlockMenu)
            btn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
            btn:SetPoint("TOPLEFT", LichborneWarlockMenu, "TOPLEFT", bx, by)
            local tex = btn:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:SetTexture(icon)
            btn.icon = tex
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            btn.state = false
            btn.icon:SetDesaturated(true)
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetFrameLevel(LichborneWarlockMenu:GetFrameLevel() + 20)
                tipFn()
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            return btn
        end

        -- Y row coordinates (18px box + 4px gap + 26px icon + 15px inter-tier, matching Mage)
        local specBoxY  = TREE_TOP_Y - 16
        local specIconY = specBoxY  - 18 - 4
        local r2BoxY    = specIconY - 26 - 15
        local r2IconY   = r2BoxY   - 18 - 4
        local r5BoxY    = r2IconY  - 26 - 15
        local r5IconY   = r5BoxY   - 18 - 4
        local r6BoxY    = r5IconY  - 26 - 15
        local r6IconY   = r6BoxY   - 18 - 4

        -- Right column: Pets (1-wide) beside Destruction
        local petsX      = col3X + SPEC_COL_W + SPEC_COL_GAP
        local petsHdrY   = specBoxY
        local petIcon1Y  = petsHdrY  - 18 - 4
        local petIcon2Y  = petIcon1Y - EXT_ICON_SIZE - 3
        local petIcon3Y  = petIcon2Y - EXT_ICON_SIZE - 3
        local petIcon4Y  = petIcon3Y - EXT_ICON_SIZE - 3
        local petIcon5Y  = petIcon4Y - EXT_ICON_SIZE - 3

        -- Left column: Curses beside Affliction
        -- Header right-edge is SPEC_COL_GAP from Affliction; buttons centered under header
        local cursesHdrX  = col1X - SPEC_COL_GAP - 44
        local cursesX     = cursesHdrX + math.floor((44 - EXT_ICON_SIZE) / 2)
        local cursesHdrY  = specBoxY
        local curseIcon1Y = cursesHdrY  - 18 - 4
        local curseIcon2Y = curseIcon1Y - EXT_ICON_SIZE - 3
        local curseIcon3Y = curseIcon2Y - EXT_ICON_SIZE - 3
        local curseIcon4Y = curseIcon3Y - EXT_ICON_SIZE - 3
        local curseIcon5Y = curseIcon4Y - EXT_ICON_SIZE - 3
        local curseIcon6Y = curseIcon5Y - EXT_ICON_SIZE - 3
        local stonesColW  = 2 * EXT_ICON_SIZE + 4

        -- ── Row 1: Spec columns ──────────────────────────────────────
        MakeSpecBox(col1X, specBoxY, SPEC_COL_W, "Affliction",
            "Interface\\Icons\\Spell_Shadow_DeathCoil")
        MakeSpecBox(col2X, specBoxY, SPEC_COL_W, "Demonology",
            "Interface\\Icons\\Spell_Shadow_Metamorphosis")
        MakeSpecBox(col3X, specBoxY, SPEC_COL_W, "Destruction",
            "Interface\\Icons\\Spell_Shadow_RainOfFire")

        local treeAffliBtn = MakeTreeBtn(col1X + ICON_OFF, specIconY,
            "Interface\\Icons\\Spell_Shadow_DeathCoil",
            function()
                GameTooltip:SetText("|cffffcc00Affliction|r |cff999999- |r|cff8787EDaffli|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Affliction DoT specialization|r", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Mutually exclusive with Demonology, Destruction.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeAffliBtn = treeAffliBtn

        local treeDemoBtn = MakeTreeBtn(col2X + ICON_OFF, specIconY,
            "Interface\\Icons\\Spell_Shadow_Metamorphosis",
            function()
                GameTooltip:SetText("|cffffcc00Demonology|r |cff999999- |r|cff8787EDdemo|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Demonology burst specialization|r", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Mutually exclusive with Affliction, Destruction.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeDemoBtn = treeDemoBtn

        local treeDestroBtn = MakeTreeBtn(col3X + ICON_OFF, specIconY,
            "Interface\\Icons\\Spell_Shadow_RainOfFire",
            function()
                GameTooltip:SetText("|cffffcc00Destruction|r |cff999999- |r|cff8787EDdestro|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Destruction fire specialization|r", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Mutually exclusive with Affliction, Demonology.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeDestroBtn = treeDestroBtn

        -- ── Row 2: Combat ────────────────────────────────────────────
        -- 3 buttons: AoE, MetaMelee, Tank
        local R2_TOTAL = 3 * EXT_ICON_SIZE + 2 * 4
        local R2_PAD   = math.floor((TREE_TOTAL_W - R2_TOTAL) / 2)
        local function r2X(i) return TREE_X + R2_PAD + i * (EXT_ICON_SIZE + 4) end
        MakeWideBox(TREE_X + R2_PAD, r2BoxY, R2_TOTAL, "Combat")

        local treeWarlockAoeBtn = MakeTreeBtn(r2X(0), r2IconY,
            "Interface\\Icons\\Spell_Frost_IceStorm",
            function()
                GameTooltip:SetText("|cffffcc00AoE|r |cff999999- |r|cff8787EDaoe|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Warlock AoE rotation|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeWarlockAoeBtn = treeWarlockAoeBtn

        local treeMetaMeleeBtn = MakeTreeBtn(r2X(1), r2IconY,
            "Interface\\Icons\\Spell_Shadow_DemonForm",
            function()
                GameTooltip:SetText("|cffffcc00Meta Melee|r |cff999999- |r|cff8787EDmeta melee|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Demonology melee mode|r", 1, 1, 1)
                GameTooltip:AddLine("While |cff8787EDImmolation Aura|r is active,", 1, 1, 1)
                GameTooltip:AddLine("closes to melee and uses |cff8787EDDemon Charge|r.", 1, 1, 1)
                GameTooltip:AddLine("No effect without |cffffcc00Metamorphosis|r active.", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeMetaMeleeBtn = treeMetaMeleeBtn

        local treeTankBtn = MakeTreeBtn(r2X(2), r2IconY,
            "Interface\\Icons\\Ability_Warrior_ShieldMastery",
            function()
                GameTooltip:SetText("|cffffcc00Tank|r |cff999999- |r|cff8787EDtank|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Warlock tank role|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeTankBtn = treeTankBtn


        -- ── Left column: Curses (1-wide) beside Affliction ──────────
        MakeSpecBox(cursesHdrX, cursesHdrY, 44, "Curses")

        local treeCurseAgonyBtn = MakeTreeBtn(cursesX, curseIcon1Y,
            "Interface\\Icons\\Spell_Shadow_CurseOfSargeras",
            function()
                GameTooltip:SetText("|cffffcc00Curse of Agony|r |cff999999- |r|cff8787EDcurse of agony|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Shadow DoT curse|r", 1, 1, 1)
                GameTooltip:AddLine("Stacking shadow damage over 24 seconds.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one curse active at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeCurseAgonyBtn = treeCurseAgonyBtn

        local treeCurseElementsBtn = MakeTreeBtn(cursesX, curseIcon2Y,
            "Interface\\Icons\\Spell_Shadow_ChillTouch",
            function()
                GameTooltip:SetText("|cffffcc00Curse of the Elements|r |cff999999- |r|cff8787EDcurse of elements|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Spell damage amplifier|r", 1, 1, 1)
                GameTooltip:AddLine("Increases Fire, Frost, Arcane, Shadow damage taken.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one curse active at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeCurseElementsBtn = treeCurseElementsBtn

        local treeCurseExhaustionBtn = MakeTreeBtn(cursesX, curseIcon3Y,
            "Interface\\Icons\\Spell_Shadow_GrimWard",
            function()
                GameTooltip:SetText("|cffffcc00Curse of Exhaustion|r |cff999999- |r|cff8787EDcurse of exhaustion|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Movement speed slow curse|r", 1, 1, 1)
                GameTooltip:AddLine("Reduces target movement speed by 30%.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one curse active at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeCurseExhaustionBtn = treeCurseExhaustionBtn

        local treeCurseDoomBtn = MakeTreeBtn(cursesX, curseIcon4Y,
            "Interface\\Icons\\Spell_Shadow_AuraOfDarkness",
            function()
                GameTooltip:SetText("|cffffcc00Curse of Doom|r |cff999999- |r|cff8787EDcurse of doom|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Heavy delayed-hit curse|r", 1, 1, 1)
                GameTooltip:AddLine("Massive shadow damage after 60 seconds.", 1, 1, 1)
                GameTooltip:AddLine("Best on long boss fights.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one curse active at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeCurseDoomBtn = treeCurseDoomBtn

        local treeCurseWeaknessBtn = MakeTreeBtn(cursesX, curseIcon5Y,
            "Interface\\Icons\\Spell_Shadow_CurseOfMannoroth",
            function()
                GameTooltip:SetText("|cffffcc00Curse of Weakness|r |cff999999- |r|cff8787EDcurse of weakness|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Attack power reduction curse|r", 1, 1, 1)
                GameTooltip:AddLine("Reduces target attack power by 478.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one curse active at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeCurseWeaknessBtn = treeCurseWeaknessBtn

        local treeCurseTonguesBtn = MakeTreeBtn(cursesX, curseIcon6Y,
            "Interface\\Icons\\Spell_Shadow_CurseOfTounges",
            function()
                GameTooltip:SetText("|cffffcc00Curse of Tongues|r |cff999999- |r|cff8787EDcurse of tongues|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Spellcasting slow curse|r", 1, 1, 1)
                GameTooltip:AddLine("Reduces target casting speed by 50%.", 1, 1, 1)
                GameTooltip:AddLine("Best against caster targets.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one curse active at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeCurseTonguesBtn = treeCurseTonguesBtn

        -- ── Left-side Stones header + 2 buttons (below PvP toggle) ──
        local stonesHdrBox = CreateFrame("Frame", nil, LichborneWarlockMenu)
        stonesHdrBox:SetSize(stonesColW, 18)
        stonesHdrBox:SetPoint("TOP", LichborneWarlockMenu.treePvpBtn, "BOTTOM", 0, -8)
        stonesHdrBox:SetBackdrop(SPEC_BOX_BD)
        stonesHdrBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        stonesHdrBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local stonesHdrLbl = stonesHdrBox:CreateFontString(nil, "OVERLAY")
        stonesHdrLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        stonesHdrLbl:SetTextColor(0.78, 0.61, 0.23, 1)
        stonesHdrLbl:SetAllPoints(); stonesHdrLbl:SetJustifyH("CENTER")
        stonesHdrLbl:SetText("Stones")

        local treeStoneSpellBtn = CreateFrame("Button", nil, LichborneWarlockMenu)
        treeStoneSpellBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeStoneSpellBtn:SetPoint("TOPLEFT", stonesHdrBox, "BOTTOMLEFT", 0, -1)
        local treeStoneSpellTex = treeStoneSpellBtn:CreateTexture(nil, "ARTWORK")
        treeStoneSpellTex:SetAllPoints()
        treeStoneSpellTex:SetTexture("Interface\\Icons\\INV_Misc_Gem_Amethyst_02")
        treeStoneSpellBtn.icon = treeStoneSpellTex
        treeStoneSpellBtn.state = false
        treeStoneSpellTex:SetDesaturated(true)
        treeStoneSpellBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeStoneSpellBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneWarlockMenu:GetFrameLevel() + 20)
            GameTooltip:SetText("|cffffcc00Spellstone|r |cff999999- |r|cff8787EDspellstone|r |cffee4433NC|r")
            GameTooltip:AddLine("|cffffcc00Apply Spellstone|r", 1, 1, 1)
            GameTooltip:AddLine("Max |cff3A8FC4mana|r, spell |cffFF9900crit|r, dispels one magic effect.", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Only one stone active at a time.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeStoneSpellBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneWarlockMenu.treeStoneSpellBtn = treeStoneSpellBtn

        local treeStoneFireBtn = CreateFrame("Button", nil, LichborneWarlockMenu)
        treeStoneFireBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeStoneFireBtn:SetPoint("TOPLEFT", treeStoneSpellBtn, "TOPRIGHT", 4, 0)
        local treeStoneFireTex = treeStoneFireBtn:CreateTexture(nil, "ARTWORK")
        treeStoneFireTex:SetAllPoints()
        treeStoneFireTex:SetTexture("Interface\\Icons\\INV_Ammo_FireTar")
        treeStoneFireBtn.icon = treeStoneFireTex
        treeStoneFireBtn.state = false
        treeStoneFireTex:SetDesaturated(true)
        treeStoneFireBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeStoneFireBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneWarlockMenu:GetFrameLevel() + 20)
            GameTooltip:SetText("|cffffcc00Firestone|r |cff999999- |r|cff8787EDfirestone|r |cffee4433NC|r")
            GameTooltip:AddLine("|cffffcc00Apply Firestone|r", 1, 1, 1)
            GameTooltip:AddLine("Adds |cffFF4444fire damage|r procs to weapon.", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Only one stone active at a time.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeStoneFireBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneWarlockMenu.treeStoneFireBtn = treeStoneFireBtn

        -- ── Left-side CC header + button (below Stones) ─────────────
        local CC_HDR_W = EXT_ICON_SIZE + 8
        local ccSideHdrBox = CreateFrame("Frame", nil, LichborneWarlockMenu)
        ccSideHdrBox:SetSize(CC_HDR_W, 18)
        ccSideHdrBox:SetPoint("TOP", LichborneWarlockMenu.treePvpBtn, "BOTTOM", 0, -61)
        ccSideHdrBox:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        ccSideHdrBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        ccSideHdrBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local ccSideHdrLabel = ccSideHdrBox:CreateFontString(nil, "OVERLAY")
        ccSideHdrLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        ccSideHdrLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        ccSideHdrLabel:SetAllPoints(); ccSideHdrLabel:SetJustifyH("CENTER")
        ccSideHdrLabel:SetText("CC")

        local treeCCBtn = CreateFrame("Button", nil, LichborneWarlockMenu)
        treeCCBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeCCBtn:SetPoint("TOPLEFT", ccSideHdrBox, "BOTTOMLEFT",
            math.floor((CC_HDR_W - EXT_ICON_SIZE) / 2), -1)
        local treeCCTex = treeCCBtn:CreateTexture(nil, "ARTWORK")
        treeCCTex:SetAllPoints()
        treeCCTex:SetTexture("Interface\\Icons\\Spell_Shadow_Possession")
        treeCCBtn.icon = treeCCTex
        treeCCBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeCCBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneWarlockMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00CC|r |cff999999- |r|cff8787EDcc|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Crowd control|r", 1, 1, 1)
            GameTooltip:AddLine("Fears or Banishes extra targets in combat.", 1, 1, 1)
            GameTooltip:AddLine("Re-applies when the effect breaks.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeCCBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeCCBtn.state = false
        treeCCBtn.icon:SetDesaturated(true)
        LichborneWarlockMenu.treeCCBtn = treeCCBtn

        -- ── Right column: Pets (1-wide) beside Destruction ─────────
        MakeSpecBox(petsX, petsHdrY, EXT_ICON_SIZE, "Pets")

        local treePetImpBtn = MakeTreeBtn(petsX, petIcon1Y,
            "Interface\\Icons\\Spell_Shadow_SummonImp",
            function()
                GameTooltip:SetText("|cffffcc00Imp|r |cff999999- |r|cff8787EDimp|r |cffee4433NC|r")
                GameTooltip:AddLine("|cffffcc00Summon Imp|r", 1, 1, 1)
                GameTooltip:AddLine("Ranged fire damage, Firebolt spam.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one pet active at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treePetImpBtn = treePetImpBtn

        local treePetVoidBtn = MakeTreeBtn(petsX, petIcon2Y,
            "Interface\\Icons\\Spell_Shadow_SummonVoidWalker",
            function()
                GameTooltip:SetText("|cffffcc00Voidwalker|r |cff999999- |r|cff8787EDvoidwalker|r |cffee4433NC|r")
                GameTooltip:AddLine("|cffffcc00Summon Voidwalker|r", 1, 1, 1)
                GameTooltip:AddLine("Tanking pet — taunts and absorbs damage.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one pet active at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treePetVoidBtn = treePetVoidBtn

        local treePetSuccubusBtn = MakeTreeBtn(petsX, petIcon3Y,
            "Interface\\Icons\\Spell_Shadow_SummonSuccubus",
            function()
                GameTooltip:SetText("|cffffcc00Succubus|r |cff999999- |r|cff8787EDsuccubus|r |cffee4433NC|r")
                GameTooltip:AddLine("|cffffcc00Summon Succubus|r", 1, 1, 1)
                GameTooltip:AddLine("DPS pet — |cff8787EDLash of Pain, Seduction|r CC.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one pet active at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treePetSuccubusBtn = treePetSuccubusBtn

        local treePetFelhunterBtn = MakeTreeBtn(petsX, petIcon4Y,
            "Interface\\Icons\\Spell_Shadow_SummonFelHunter",
            function()
                GameTooltip:SetText("|cffffcc00Felhunter|r |cff999999- |r|cff8787EDfelhunter|r |cffee4433NC|r")
                GameTooltip:AddLine("|cffffcc00Summon Felhunter|r", 1, 1, 1)
                GameTooltip:AddLine("|cff8787EDSpell Lock|r interrupts enemy casters.", 1, 1, 1)
                GameTooltip:AddLine("|cff8787EDDevour Magic|r purges buffs, cleanses allies.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one pet active at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treePetFelhunterBtn = treePetFelhunterBtn

        local treePetFelguardBtn = MakeTreeBtn(petsX, petIcon5Y,
            "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
            function()
                GameTooltip:SetText("|cffffcc00Felguard|r |cff999999- |r|cff8787EDfelguard|r |cffee4433NC|r")
                GameTooltip:AddLine("|cffffcc00Summon Felguard|r", 1, 1, 1)
                GameTooltip:AddLine("Melee DPS pet, empowered by |cffffcc00Demonic Empowerment|r.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one pet active at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treePetFelguardBtn = treePetFelguardBtn

        -- ── Row 5: Soulstone (4-button wide) ────────────────────────
        local SS_TOTAL = 4 * EXT_ICON_SIZE + 3 * 4
        local ssPad    = math.floor((TREE_TOTAL_W - SS_TOTAL) / 2)
        local function ssX(i) return TREE_X + ssPad + i * (EXT_ICON_SIZE + 4) end
        MakeWideBox(TREE_X + ssPad, r5BoxY, SS_TOTAL, "Soulstone")

        local treeSSSelfBtn = MakeTreeBtn(ssX(0), r5IconY,
            "Interface\\Icons\\Spell_Shadow_Shadowform",
            function()
                GameTooltip:SetText("|cffffcc00SS Self|r |cff999999- |r|cff8787EDss self|r |cffee4433NC|r")
                GameTooltip:AddLine("|cffffcc00Soulstone self|r", 1, 1, 1)
                GameTooltip:AddLine("Bot places |cff8787EDSoulstone|r on itself.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one Soulstone target at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeSSSelfBtn = treeSSSelfBtn

        local treeSSMasterBtn = MakeTreeBtn(ssX(1), r5IconY,
            "Interface\\Icons\\Achievement_WorldEvent_LittleHelper",
            function()
                GameTooltip:SetText("|cffffcc00SS Master|r |cff999999- |r|cff8787EDss master|r |cffee4433NC|r")
                GameTooltip:AddLine("|cffffcc00Soulstone the group leader|r", 1, 1, 1)
                GameTooltip:AddLine("Bot places |cff8787EDSoulstone|r on the group leader.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one Soulstone target at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeSSMasterBtn = treeSSMasterBtn

        local treeSSTankBtn = MakeTreeBtn(ssX(2), r5IconY,
            "Interface\\Icons\\Ability_Warrior_DefensiveStance",
            function()
                GameTooltip:SetText("|cffffcc00SS Tank|r |cff999999- |r|cff8787EDss tank|r |cffee4433NC|r")
                GameTooltip:AddLine("|cffffcc00Soulstone the main tank|r", 1, 1, 1)
                GameTooltip:AddLine("Bot places |cff8787EDSoulstone|r on the tank.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one Soulstone target at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeSSTankBtn = treeSSTankBtn

        local treeSSHealerBtn = MakeTreeBtn(ssX(3), r5IconY,
            "Interface\\Icons\\INV_Elemental_Primal_Life",
            function()
                GameTooltip:SetText("|cffffcc00SS Healer|r |cff999999- |r|cff8787EDss healer|r |cffee4433NC|r")
                GameTooltip:AddLine("|cffffcc00Soulstone the main healer|r", 1, 1, 1)
                GameTooltip:AddLine("Bot places |cff8787EDSoulstone|r on the healer.", 1, 1, 1)
                GameTooltip:AddLine("|cffFF4444Only one Soulstone target at a time.|r", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeSSHealerBtn = treeSSHealerBtn

        -- ── Row 6: Assist ────────────────────────────────────────────
        local R6_TOTAL = 3 * EXT_ICON_SIZE + 2 * 4
        local R6_PAD   = math.floor((TREE_TOTAL_W - R6_TOTAL) / 2)
        local function r6X(i) return TREE_X + R6_PAD + i * (EXT_ICON_SIZE + 4) end
        MakeWideBox(TREE_X + R6_PAD, r6BoxY, R6_TOTAL, "Assist")

        local treeTankAssistBtn = MakeTreeBtn(r6X(0), r6IconY,
            "Interface\\Icons\\inv_shield_02",
            function()
                GameTooltip:SetText("|cffffcc00Tank Assist|r |cff999999- |r|cffff8000tank assist|r |cffffcc00CO|r")
                GameTooltip:AddLine("|cffffcc00Tank target focus|r", 1, 1, 1)
                GameTooltip:AddLine("Bot attacks the tank's current target.", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeTankAssistBtn = treeTankAssistBtn

        local treeDpsAssistBtn = MakeTreeBtn(r6X(1), r6IconY,
            "Interface\\Icons\\Ability_Warrior_Challange",
            function()
                GameTooltip:SetText("|cffffcc00DPS Assist|r |cff999999- |r|cffff8000dps assist|r |cffffcc00CO|r")
                GameTooltip:AddLine("|cffffcc00DPS target focus|r", 1, 1, 1)
                GameTooltip:AddLine("Bot attacks the group's coordinated DPS target.", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeDpsAssistBtn = treeDpsAssistBtn

        local treeDpsAoeBtn = MakeTreeBtn(r6X(2), r6IconY,
            "Interface\\Icons\\Spell_Shadow_RainOfFire",
            function()
                GameTooltip:SetText("|cffffcc00DPS AoE|r |cff999999- |r|cff8787EDaoe|r |cffee4433CO|r")
                GameTooltip:AddLine("|cffffcc00Cross-role AoE mode|r", 1, 1, 1)
                GameTooltip:AddLine("Switches to AoE rotation on multiple targets.", 1, 1, 1)
            end)
        LichborneWarlockMenu.treeDpsAoeBtn = treeDpsAoeBtn

        -- ══════════════════════════════════════════════════════════════
        -- Wire toggle logic
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

            local _baseReset = LichborneWarlockMenu.resetSharedIcons
            LichborneWarlockMenu.resetAllIcons = function()
                if _baseReset then _baseReset() end
                -- class-specific tree buttons only (food/loot/gather handled by base)
                IconOff(treeAffliBtn); IconOff(treeDemoBtn); IconOff(treeDestroBtn)
                IconOff(treeWarlockAoeBtn); IconOff(treeMetaMeleeBtn)
                IconOff(treeTankBtn)
                IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
                IconOff(treeCurseAgonyBtn); IconOff(treeCurseElementsBtn)
                IconOff(treeCurseExhaustionBtn); IconOff(treeCurseDoomBtn)
                IconOff(treeCurseWeaknessBtn); IconOff(treeCurseTonguesBtn)
                IconOff(treePetImpBtn); IconOff(treePetVoidBtn); IconOff(treePetSuccubusBtn)
                IconOff(treePetFelhunterBtn); IconOff(treePetFelguardBtn)
                IconOff(treeStoneSpellBtn); IconOff(treeStoneFireBtn)
                IconOff(treeSSSelfBtn); IconOff(treeSSMasterBtn)
                IconOff(treeSSTankBtn); IconOff(treeSSHealerBtn)
                IconOff(treeCCBtn)
            end

            -- ── Row 1: Specs (mutually exclusive CO) ──────────────────
            local specList = {
                { cmd="affli",  btn=treeAffliBtn  },
                { cmd="demo",   btn=treeDemoBtn   },
                { cmd="destro", btn=treeDestroBtn },
            }
            for _, entry in ipairs(specList) do
                local btn = entry.btn
                local cmd = entry.cmd
                btn:SetScript("OnClick", function()
                    local bot = LichborneWarlockMenu.botName or ""
                    LichborneWarlockMenu._specUserSet = true
                    if btn.state then
                        PBM.SendToBot("co -" .. cmd .. ",?", bot)
                        IconOff(btn)
                    else
                        PBM.SendToBot("co +" .. cmd .. ",?", bot)
                        IconOn(btn)
                        for _, other in ipairs(specList) do
                            if other.cmd ~= cmd then IconOff(other.btn) end
                        end
                    end
                end)
            end

            -- ── Row 2: Combat (independent / exclusive as noted) ──────

            treeWarlockAoeBtn:SetScript("OnClick", function()
                local bot = LichborneWarlockMenu.botName or ""
                LichborneWarlockMenu._specUserSet = true
                if treeWarlockAoeBtn.state then
                    PBM.SendToBot("co -aoe,?", bot); IconOff(treeWarlockAoeBtn)
                else
                    PBM.SendToBot("co +aoe,?", bot); IconOn(treeWarlockAoeBtn)
                end
            end)

            treeMetaMeleeBtn:SetScript("OnClick", function()
                local bot = LichborneWarlockMenu.botName or ""
                LichborneWarlockMenu._specUserSet = true
                if treeMetaMeleeBtn.state then
                    PBM.SendToBot("co -meta melee,?", bot); IconOff(treeMetaMeleeBtn)
                else
                    PBM.SendToBot("co +meta melee,?", bot); IconOn(treeMetaMeleeBtn)
                end
            end)

            -- Tank (exclusive with Dps)
            treeTankBtn:SetScript("OnClick", function()
                local bot = LichborneWarlockMenu.botName or ""
                LichborneWarlockMenu._specUserSet = true
                if treeTankBtn.state then
                    PBM.SendToBot("co -tank,?", bot); IconOff(treeTankBtn)
                else
                    PBM.SendToBot("co +tank,?", bot); IconOn(treeTankBtn)
                end
            end)


            -- TankAssist (exclusive with DpsAssist, DpsAoe)
            treeTankAssistBtn:SetScript("OnClick", function()
                local bot = LichborneWarlockMenu.botName or ""
                LichborneWarlockMenu._specUserSet = true
                if treeTankAssistBtn.state then
                    PBM.SendToBot("co -tank assist,?", bot); IconOff(treeTankAssistBtn)
                else
                    PBM.SendToBot("co +tank assist,?", bot); IconOn(treeTankAssistBtn)
                    IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            -- DpsAssist (exclusive with TankAssist, DpsAoe)
            treeDpsAssistBtn:SetScript("OnClick", function()
                local bot = LichborneWarlockMenu.botName or ""
                LichborneWarlockMenu._specUserSet = true
                if treeDpsAssistBtn.state then
                    PBM.SendToBot("co -dps assist,?", bot); IconOff(treeDpsAssistBtn)
                else
                    PBM.SendToBot("co +dps assist,?", bot); IconOn(treeDpsAssistBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            -- DpsAoe (exclusive with TankAssist, DpsAssist)
            treeDpsAoeBtn:SetScript("OnClick", function()
                local bot = LichborneWarlockMenu.botName or ""
                LichborneWarlockMenu._specUserSet = true
                if treeDpsAoeBtn.state then
                    PBM.SendToBot("co -aoe,?", bot); IconOff(treeDpsAoeBtn)
                else
                    PBM.SendToBot("co +aoe,?", bot); IconOn(treeDpsAoeBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn)
                end
            end)

            -- LEFT-SIDE: CC — co +cc / co -cc, independent
            treeCCBtn:SetScript("OnClick", function()
                local bot = LichborneWarlockMenu.botName or ""
                LichborneWarlockMenu._specUserSet = true
                if treeCCBtn.state then
                    PBM.SendToBot("co -cc,?", bot); IconOff(treeCCBtn)
                else
                    PBM.SendToBot("co +cc,?", bot); IconOn(treeCCBtn)
                end
            end)

            -- ── Row 3: Curses (radio CO) ───────────────────────────────
            local curseList = {
                { cmd="curse of agony",      btn=treeCurseAgonyBtn      },
                { cmd="curse of elements",   btn=treeCurseElementsBtn   },
                { cmd="curse of exhaustion", btn=treeCurseExhaustionBtn },
                { cmd="curse of doom",       btn=treeCurseDoomBtn       },
                { cmd="curse of weakness",   btn=treeCurseWeaknessBtn   },
                { cmd="curse of tongues",    btn=treeCurseTonguesBtn    },
            }
            for _, entry in ipairs(curseList) do
                local btn = entry.btn
                local cmd = entry.cmd
                btn:SetScript("OnClick", function()
                    local bot = LichborneWarlockMenu.botName or ""
                    LichborneWarlockMenu._specUserSet = true
                    if btn.state then
                        PBM.SendToBot("co -" .. cmd .. ",?", bot); IconOff(btn)
                    else
                        PBM.SendToBot("co +" .. cmd .. ",?", bot); IconOn(btn)
                        for _, other in ipairs(curseList) do
                            if other.cmd ~= cmd then IconOff(other.btn) end
                        end
                    end
                end)
            end

            -- ── Row 4: Pets (radio NC) ────────────────────────────────
            local petList = {
                { cmd="imp",        btn=treePetImpBtn       },
                { cmd="voidwalker", btn=treePetVoidBtn      },
                { cmd="succubus",   btn=treePetSuccubusBtn  },
                { cmd="felhunter",  btn=treePetFelhunterBtn },
                { cmd="felguard",   btn=treePetFelguardBtn  },
            }
            for _, entry in ipairs(petList) do
                local btn = entry.btn
                local cmd = entry.cmd
                btn:SetScript("OnClick", function()
                    local bot = LichborneWarlockMenu.botName or ""
                    LichborneWarlockMenu._specUserSet = true
                    if btn.state then
                        PBM.SendToBot("nc -" .. cmd .. ",?", bot); IconOff(btn)
                    else
                        PBM.SendToBot("nc +" .. cmd .. ",?", bot); IconOn(btn)
                        for _, other in ipairs(petList) do
                            if other.cmd ~= cmd then IconOff(other.btn) end
                        end
                    end
                end)
            end

            -- ── Row 5: Stones (radio NC) ───────────────────────────────
            local stoneList = {
                { cmd="spellstone", btn=treeStoneSpellBtn },
                { cmd="firestone",  btn=treeStoneFireBtn  },
            }
            for _, entry in ipairs(stoneList) do
                local btn = entry.btn
                local cmd = entry.cmd
                btn:SetScript("OnClick", function()
                    local bot = LichborneWarlockMenu.botName or ""
                    LichborneWarlockMenu._specUserSet = true
                    if btn.state then
                        PBM.SendToBot("nc -" .. cmd .. ",?", bot); IconOff(btn)
                    else
                        PBM.SendToBot("nc +" .. cmd .. ",?", bot); IconOn(btn)
                        for _, other in ipairs(stoneList) do
                            if other.cmd ~= cmd then IconOff(other.btn) end
                        end
                    end
                end)
            end

            -- ── Row 5: Soulstone (radio NC) ───────────────────────────
            local ssList = {
                { cmd="ss self",   btn=treeSSSelfBtn   },
                { cmd="ss master", btn=treeSSMasterBtn },
                { cmd="ss tank",   btn=treeSSTankBtn   },
                { cmd="ss healer", btn=treeSSHealerBtn },
            }
            for _, entry in ipairs(ssList) do
                local btn = entry.btn
                local cmd = entry.cmd
                btn:SetScript("OnClick", function()
                    local bot = LichborneWarlockMenu.botName or ""
                    LichborneWarlockMenu._specUserSet = true
                    if btn.state then
                        PBM.SendToBot("nc -" .. cmd .. ",?", bot); IconOff(btn)
                    else
                        PBM.SendToBot("nc +" .. cmd .. ",?", bot); IconOn(btn)
                        for _, other in ipairs(ssList) do
                            if other.cmd ~= cmd then IconOff(other.btn) end
                        end
                    end
                end)
            end

            -- ── Strategy state sync ───────────────────────────────────
            local _baseSU = LichborneWarlockMenu.onStrategyUpdate  -- MUST BE BEFORE the assignment below
            LichborneWarlockMenu.onStrategyUpdate = function(stratType, activeSet)
                if _baseSU then _baseSU(stratType, activeSet) end
                if not LichborneWarlockMenu._specUserSet then
                    if stratType == "co" then
                        if activeSet["affli"]        then IconOn(treeAffliBtn)        else IconOff(treeAffliBtn)        end
                        if activeSet["demo"]         then IconOn(treeDemoBtn)         else IconOff(treeDemoBtn)         end
                        if activeSet["destro"]       then IconOn(treeDestroBtn)       else IconOff(treeDestroBtn)       end
                        if activeSet["aoe"]          then IconOn(treeWarlockAoeBtn)   else IconOff(treeWarlockAoeBtn)   end
                        if activeSet["meta melee"]   then IconOn(treeMetaMeleeBtn)    else IconOff(treeMetaMeleeBtn)    end
                        if activeSet["tank"]         then IconOn(treeTankBtn)         else IconOff(treeTankBtn)         end
                        if activeSet["tank assist"]  then IconOn(treeTankAssistBtn)   else IconOff(treeTankAssistBtn)   end
                        if activeSet["dps assist"]   then IconOn(treeDpsAssistBtn)    else IconOff(treeDpsAssistBtn)    end
                        if activeSet["aoe"]           then IconOn(treeDpsAoeBtn)       else IconOff(treeDpsAoeBtn)       end
                        if activeSet["cc"]           then IconOn(treeCCBtn)           else IconOff(treeCCBtn)           end
                        for _, e in ipairs(curseList) do
                            if activeSet[e.cmd] then IconOn(e.btn) end
                        end
                    elseif stratType == "nc" then
                        for _, e in ipairs(petList)   do if activeSet[e.cmd] then IconOn(e.btn) end end
                        for _, e in ipairs(stoneList) do if activeSet[e.cmd] then IconOn(e.btn) end end
                        for _, e in ipairs(ssList)    do if activeSet[e.cmd] then IconOn(e.btn) end end
                    end
                end
            end
        end -- end toggle wire block
    end

    if LichborneWarlockMenu:IsShown() and LichborneWarlockMenu.sourceRow == row then
        HideAllWarlock(); return
    end
    PBM.ShowCharSheet(LichborneWarlockMenu, LichborneWarlockCatcher, row, WARLOCK_LEFT_EXT)
end
