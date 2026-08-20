PBM = PBM or {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Druid class-specific overlay panel — data
-- ─────────────────────────────────────────────────────────────────────────────

local DRUID_TALENT_SPECS = {
    { label=PBM_L["Balance |cffffcc00PvE|r"],     spec="balance pve", wowSpec="Balance",     icon="Interface\\Icons\\Spell_Nature_StarFall"     },
    { label=PBM_L["Bear |cffffcc00PvE|r"],        spec="bear pve",    wowSpec="Feral",       icon="Interface\\Icons\\Ability_Racial_BearForm"   },
    { label=PBM_L["Restoration |cffffcc00PvE|r"], spec="resto pve",   wowSpec="Restoration", icon="Interface\\Icons\\Spell_Nature_HealingTouch" },
    { label=PBM_L["Cat |cffffcc00PvE|r"],         spec="cat pve",     wowSpec="Feral",       icon="Interface\\Icons\\Ability_Druid_CatForm"     },
    { label=PBM_L["Balance |cffff4444PvP|r"],     spec="balance pvp", wowSpec="Balance",     icon="Interface\\Icons\\Spell_Nature_StarFall"     },
    { label=PBM_L["Cat |cffff4444PvP|r"],         spec="cat pvp",     wowSpec="Feral",       icon="Interface\\Icons\\Ability_Druid_CatForm"     },
    { label=PBM_L["Restoration |cffff4444PvP|r"], spec="resto pvp",   wowSpec="Restoration", icon="Interface\\Icons\\Spell_Nature_HealingTouch" },
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
            TREE_X,       TREE_TOP_Y - 16, 70, PBM_L["Bear"],        "Interface\\Icons\\Ability_Racial_BearForm")
        local catSpecBox  = MakeSpecBox(LichborneDruidMenu,
            TREE_X + 74,  TREE_TOP_Y - 16, 70, PBM_L["Cat"],         "Interface\\Icons\\Ability_Druid_CatForm")
        local balSpecBox  = MakeSpecBox(LichborneDruidMenu,
            TREE_X + 148, TREE_TOP_Y - 16, 70, PBM_L["Balance"],     "Interface\\Icons\\Spell_Nature_StarFall")
        local restoSpecBox = MakeSpecBox(LichborneDruidMenu,
            TREE_X + 222, TREE_TOP_Y - 16, 70, PBM_L["Restoration"], "Interface\\Icons\\Spell_Nature_HealingTouch")

        local treeBearBtn   = MakeTreeBtn(LichborneDruidMenu, bearSpecBox,  "BOTTOMLEFT", 22, -4, "Interface\\Icons\\Ability_Racial_BearForm")
        local treeCatBtn    = MakeTreeBtn(LichborneDruidMenu, catSpecBox,   "BOTTOMLEFT", 22, -4, "Interface\\Icons\\Ability_Druid_CatForm")
        local treeCasterBtn = MakeTreeBtn(LichborneDruidMenu, balSpecBox,   "BOTTOMLEFT", 22, -4, "Interface\\Icons\\Spell_Nature_StarFall")
        local treeHealBtn   = MakeTreeBtn(LichborneDruidMenu, restoSpecBox, "BOTTOMLEFT", 22, -4, "Interface\\Icons\\Spell_Nature_HealingTouch")

        treeBearBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText(PBM_L["|cffffcc00Bear|r |cff999999- |r|cffFF7D0Abear|r |cffee4433CO|r"])
            GameTooltip:AddLine(PBM_L["|cffffcc00Dire Bear Form|r"], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["|cffFF4444Mutually exclusive with Cat, Balance, Heal, Off-Heal.|r"], 1, 1, 1)
            GameTooltip:Show()
        end)
        treeBearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        treeCatBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText(PBM_L["|cffffcc00Cat|r |cff999999- |r|cffFF7D0Acat|r |cffee4433CO|r"])
            GameTooltip:AddLine(PBM_L["|cffffcc00Feral Cat melee DPS|r"], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["|cffFF4444Mutually exclusive with Bear, Balance, Heal, Off-Heal.|r"], 1, 1, 1)
            GameTooltip:Show()
        end)
        treeCatBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        treeCasterBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText(PBM_L["|cffffcc00Balance|r |cff999999- |r|cffFF7D0Abalance|r |cffee4433CO|r"])
            GameTooltip:AddLine(PBM_L["|cffffcc00Moonkin Form — Balance caster DPS|r"], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["|cffFF4444Mutually exclusive with Bear, Cat, Heal, Off-Heal.|r"], 1, 1, 1)
            GameTooltip:Show()
        end)
        treeCasterBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        treeHealBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText(PBM_L["|cffffcc00Restoration|r |cff999999- |r|cffFF7D0Aresto|r |cffee4433CO|r"])
            GameTooltip:AddLine(PBM_L["|cffffcc00Tree of Life — Restoration healer|r"], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["|cffFF4444Mutually exclusive with Bear, Cat, Balance, Off-Heal.|r"], 1, 1, 1)
            GameTooltip:Show()
        end)
        treeHealBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        LichborneDruidMenu.treeBearBtn   = treeBearBtn
        LichborneDruidMenu.treeCatBtn    = treeCatBtn
        LichborneDruidMenu.treeCasterBtn = treeCasterBtn
        LichborneDruidMenu.treeHealBtn   = treeHealBtn

        -- ── ROW 2 — Healing (left) + Hybrid modifier (right) ──────────
        local healingSpecBox = MakeSpecBox(LichborneDruidMenu, TREE_X, TREE_TOP_Y - 16, 60, PBM_L["Healing"], nil)
        healingSpecBox:ClearAllPoints()
        healingSpecBox:SetPoint("TOPLEFT", bearSpecBox, "BOTTOMLEFT", 79, -45)

        local treeTranqBtn = MakeTreeBtn(LichborneDruidMenu, healingSpecBox, "BOTTOMLEFT", 2, -4,
            "Interface\\Icons\\Spell_Nature_Tranquility")
        treeTranqBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText(PBM_L["|cffffcc00Tranquility|r |cff999999- |r|cffFF7D0Atranquility|r |cffee4433CO|r"])
            GameTooltip:AddLine(PBM_L["Auto-loaded on Resto,"], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["Heals ALL nearby party members."], 1, 1, 1)
            GameTooltip:Show()
        end)
        treeTranqBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeTranqBtn = treeTranqBtn

        local treeBlankBtn = MakeTreeBtn(LichborneDruidMenu, healingSpecBox, "BOTTOMLEFT", 32, -4,
            "Interface\\Icons\\Spell_Nature_Rejuvenation")
        treeBlankBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText(PBM_L["|cffffcc00Blanketing|r |cff999999- |r|cffFF7D0Ablanketing|r |cffee4433CO|r"])
            GameTooltip:AddLine(PBM_L["pre-HoT party with Wild Growth"], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["+ Rejuvenation regardless of HP."], 1, 1, 1)
            GameTooltip:Show()
        end)
        treeBlankBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeBlankBtn = treeBlankBtn

        local hybridSpecBox = MakeSpecBox(LichborneDruidMenu, 0, 0, 60, PBM_L["Hybrid"], nil)
        hybridSpecBox:ClearAllPoints()
        hybridSpecBox:SetPoint("TOPLEFT", restoSpecBox, "BOTTOMLEFT", -69, -45)

        local treeHealerDpsBtn = MakeTreeBtn(LichborneDruidMenu, hybridSpecBox, "BOTTOMLEFT", 2, -4,
            "Interface\\Icons\\INV_Alchemy_Elixir_02")
        treeHealerDpsBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText(PBM_L["|cffffcc00Healer DPS|r |cff999999- |r|cffFF7D0Ahealer dps|r |cffee4433CO|r"])
            GameTooltip:AddLine(PBM_L["|cffffcc00Healer contributes DPS between heals|r"], 1, 1, 1)
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
            GameTooltip:SetText(PBM_L["|cffffcc00Off-Heal|r |cff999999- |r|cffFF7D0Aoffheal|r |cffee4433CO|r"])
            GameTooltip:AddLine(PBM_L["|cffffcc00Cat DPS primary, heals when party drops low|r"], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["|cffFF4444Mutually exclusive with Bear, Cat, Balance, Heal.|r"], 1, 1, 1)
            GameTooltip:Show()
        end)
        treeOffhealBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeOffhealBtn = treeOffhealBtn

        -- ── ROW 3 — AoE + Charge ─────────────────────────────────────
        local aoeSpecBox = MakeSpecBox(LichborneDruidMenu, 0, 0, 34, PBM_L["AoE"], nil)
        aoeSpecBox:ClearAllPoints()
        aoeSpecBox:SetPoint("TOPLEFT", healingSpecBox, "BOTTOMLEFT", 31, -45)

        local treeAoeBtn = MakeTreeBtn(LichborneDruidMenu, aoeSpecBox, "BOTTOMLEFT", 4, -4,
            "Interface\\Icons\\Spell_Frost_IceStorm")
        treeAoeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText(PBM_L["|cffffcc00AoE|r |cff999999- |r|cffFF7D0Aaoe|r |cffee4433CO|r"])
            GameTooltip:AddLine(PBM_L["Shared AoE strategy across all druid specs."], 1, 1, 1)
            GameTooltip:Show()
        end)
        treeAoeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeAoeBtn = treeAoeBtn

        local chargeSpecBox = MakeSpecBox(LichborneDruidMenu, 0, 0, 50, PBM_L["Charge"], nil)
        chargeSpecBox:ClearAllPoints()
        chargeSpecBox:SetPoint("TOPLEFT", aoeSpecBox, "TOPRIGHT", 4, 0)

        local treeChargeBtn = MakeTreeBtn(LichborneDruidMenu, chargeSpecBox, "BOTTOMLEFT", 12, -4,
            "Interface\\Icons\\Ability_Hunter_Pet_Bear")
        treeChargeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText(PBM_L["|cffffcc00Feral Charge|r |cff999999- |r|cffFF7D0Aferal charge|r |cffee4433CO|r"])
            GameTooltip:AddLine(PBM_L["Cat & Bear, for encounters when"], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["charging in is unfavorable."], 1, 1, 1)
            GameTooltip:Show()
        end)
        treeChargeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeChargeBtn = treeChargeBtn

        -- ── ROW 4 — Assist ────────────────────────────────────────────
        local assistSpecBox = MakeSpecBox(LichborneDruidMenu, 0, 0, 90, PBM_L["Assist"], nil)
        assistSpecBox:ClearAllPoints()
        -- Center assistSpecBox within the tree (TREE_TOTAL_W=292, box=90px → left offset=101)
        -- aoeSpecBox left = TREE_X+110, so delta = 101-110 = -9
        assistSpecBox:SetPoint("TOPLEFT", aoeSpecBox, "BOTTOMLEFT", -9, -45)

        local treeTankAssistBtn = MakeTreeBtn(LichborneDruidMenu, assistSpecBox, "BOTTOMLEFT", 2, -4,
            "Interface\\Icons\\inv_shield_02")
        treeTankAssistBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText(PBM_L["|cffffcc00Tank Assist|r |cff999999- |r|cffff8000tank assist|r |cffffcc00CO|r"])
            GameTooltip:AddLine(PBM_L["|cffffcc00Tank target focus|r"], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["Bot attacks the tank's current target."], 1, 1, 1)
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
            GameTooltip:SetText(PBM_L["|cffffcc00DPS Assist|r |cff999999- |r|cffff8000dps assist|r |cffffcc00CO|r"])
            GameTooltip:AddLine(PBM_L["|cffffcc00Focus single-target DPS on assist target|r"], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["Bot attacks the group DPS focus target."], 1, 1, 1)
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
            GameTooltip:SetText(PBM_L["|cffffcc00DPS AoE|r |cff999999- |r|cffFF7D0Adps aoe|r |cffee4433CO|r"])
            GameTooltip:AddLine(PBM_L["|cffffcc00Cross-role AoE mode|r"], 1, 1, 1)
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
        buffSideHdrFs:SetText(PBM_L["Buff"])

        local treeSideBuffBtn = MakeTreeBtn(LichborneDruidMenu, buffSideHdrBox, "BOTTOMLEFT", 4, -1,
            "Interface\\Icons\\spell_nature_regeneration")
        treeSideBuffBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText(PBM_L["|cffffcc00Buff|r |cff999999- |r|cffffff00buff|r |cffff8000NC|r"])
            GameTooltip:AddLine(PBM_L["|cffffcc00Group stats buff|r"], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["|cffFF7D0AMark of the Wild|r on all party members."], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["Upgrades to |cffFF7D0AGift of the Wild|r when |cffffcc00Wild Thornroot|r"], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["is in the bot's bags."], 1, 1, 1)
            GameTooltip:Show()
        end)
        treeSideBuffBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeSideBuffBtn = treeSideBuffBtn

        -- ── Left-side CC header + button (below Buff) ─────────────────
        local ccSideHdrBox = CreateFrame("Frame", nil, LichborneDruidMenu)
        ccSideHdrBox:SetSize(EXT_ICON_SIZE + 8, 18)
        ccSideHdrBox:SetPoint("TOPLEFT", treeSideBuffBtn, "BOTTOMLEFT", -4, -8)
        ccSideHdrBox:SetBackdrop(SPEC_BOX_BD)
        ccSideHdrBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        ccSideHdrBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local ccSideHdrFs = ccSideHdrBox:CreateFontString(nil, "OVERLAY")
        ccSideHdrFs:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        ccSideHdrFs:SetTextColor(0.78, 0.61, 0.23, 1)
        ccSideHdrFs:SetAllPoints()
        ccSideHdrFs:SetJustifyH("CENTER")
        ccSideHdrFs:SetText(PBM_L["CC"])

        local treeCCBtn = MakeTreeBtn(LichborneDruidMenu, ccSideHdrBox, "BOTTOMLEFT", 4, -1,
            "Interface\\Icons\\Spell_Nature_EarthBind")
        treeCCBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDruidMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText(PBM_L["|cffffcc00CC|r |cff999999- |r|cffff8000cc|r |cffffcc00CO|r"])
            GameTooltip:AddLine(PBM_L["|cffffcc00Crowd control|r"], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["Cyclones, Hibernates, or Roots extra targets in combat."], 1, 1, 1)
            GameTooltip:AddLine(PBM_L["Re-applies when the effect breaks."], 1, 1, 1)
            GameTooltip:Show()
        end)
        treeCCBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        LichborneDruidMenu.treeCCBtn = treeCCBtn

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
            IconOff(treeTranqBtn);      IconOff(treeBlankBtn)
            IconOff(treeHealerDpsBtn);  IconOff(treeOffhealBtn)
            IconOff(treeAoeBtn);        IconOff(treeChargeBtn)
            IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
            IconOff(treeSideBuffBtn);   IconOff(treeCCBtn)

            -- resetAllIcons extends the shared base (Food/Loot/Gather)
            local _baseReset = LichborneDruidMenu.resetSharedIcons
            LichborneDruidMenu.resetAllIcons = function()
                if _baseReset then _baseReset() end
                IconOff(treeBearBtn);       IconOff(treeCatBtn)
                IconOff(treeCasterBtn);     IconOff(treeHealBtn)
                IconOff(treeTranqBtn);      IconOff(treeBlankBtn)
                IconOff(treeHealerDpsBtn);  IconOff(treeOffhealBtn)
                IconOff(treeAoeBtn);        IconOff(treeChargeBtn)
                IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
                IconOff(treeSideBuffBtn);   IconOff(treeCCBtn)
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
                    PBM.SendToBot("co -balance,?", bot); IconOff(treeCasterBtn)
                else
                    PBM.SendToBot("co +balance,?", bot); IconOn(treeCasterBtn)
                    IconOff(treeBearBtn); IconOff(treeCatBtn); IconOff(treeHealBtn)
                    IconOff(treeOffhealBtn)
                end
            end)

            treeHealBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeHealBtn.state then
                    PBM.SendToBot("co -resto,?", bot); IconOff(treeHealBtn)
                else
                    PBM.SendToBot("co +resto,?", bot); IconOn(treeHealBtn)
                    IconOff(treeBearBtn); IconOff(treeCatBtn); IconOff(treeCasterBtn)
                    IconOff(treeOffhealBtn)
                end
            end)

            -- ── Row 2: Healing + Hybrid ────────────────────────────────
            treeTranqBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeTranqBtn.state then
                    PBM.SendToBot("co -tranquility,?", bot); IconOff(treeTranqBtn)
                else
                    PBM.SendToBot("co +tranquility,?", bot); IconOn(treeTranqBtn)
                end
            end)

            treeBlankBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeBlankBtn.state then
                    PBM.SendToBot("co -blanketing,?", bot); IconOff(treeBlankBtn)
                else
                    PBM.SendToBot("co +blanketing,?", bot); IconOn(treeBlankBtn)
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

            -- ── Row 3: AoE + Charge (independent) ─────────────────────
            treeAoeBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeAoeBtn.state then
                    PBM.SendToBot("co -aoe,?", bot); IconOff(treeAoeBtn)
                else
                    PBM.SendToBot("co +aoe,?", bot); IconOn(treeAoeBtn)
                end
            end)

            treeChargeBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeChargeBtn.state then
                    PBM.SendToBot("co -feral charge,?", bot); IconOff(treeChargeBtn)
                else
                    PBM.SendToBot("co +feral charge,?", bot); IconOn(treeChargeBtn)
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

            treeCCBtn:SetScript("OnClick", function()
                local bot = LichborneDruidMenu.botName or ""
                LichborneDruidMenu._specUserSet = true
                if treeCCBtn.state then
                    PBM.SendToBot("co -cc,?", bot); IconOff(treeCCBtn)
                else
                    PBM.SendToBot("co +cc,?", bot); IconOn(treeCCBtn)
                end
            end)

            -- onStrategyUpdate extends shared base (CO buttons + NC buff)
            local _baseSU = LichborneDruidMenu.onStrategyUpdate
            LichborneDruidMenu.onStrategyUpdate = function(stratType, activeSet)
                if _baseSU then _baseSU(stratType, activeSet) end
                if not LichborneDruidMenu._specUserSet then
                    if stratType == "co" then
                        if activeSet["bear"]         then IconOn(treeBearBtn)       else IconOff(treeBearBtn)       end
                        if activeSet["cat"]          then IconOn(treeCatBtn)        else IconOff(treeCatBtn)        end
                        if activeSet["balance"]      then IconOn(treeCasterBtn)     else IconOff(treeCasterBtn)     end
                        if activeSet["resto"]        then IconOn(treeHealBtn)       else IconOff(treeHealBtn)       end
                        if activeSet["tranquility"]  then IconOn(treeTranqBtn)      else IconOff(treeTranqBtn)      end
                        if activeSet["blanketing"]   then IconOn(treeBlankBtn)      else IconOff(treeBlankBtn)      end
                        if activeSet["healer dps"]   then IconOn(treeHealerDpsBtn)  else IconOff(treeHealerDpsBtn)  end
                        if activeSet["offheal"]      then IconOn(treeOffhealBtn)    else IconOff(treeOffhealBtn)    end
                        if activeSet["aoe"]          then IconOn(treeAoeBtn)        else IconOff(treeAoeBtn)        end
                        if activeSet["feral charge"] then IconOn(treeChargeBtn)     else IconOff(treeChargeBtn)     end
                        if activeSet["tank assist"]  then IconOn(treeTankAssistBtn) else IconOff(treeTankAssistBtn) end
                        if activeSet["dps assist"]   then IconOn(treeDpsAssistBtn)  else IconOff(treeDpsAssistBtn)  end
                        if activeSet["dps aoe"]      then IconOn(treeDpsAoeBtn)     else IconOff(treeDpsAoeBtn)     end
                        if activeSet["cc"]           then IconOn(treeCCBtn)         else IconOff(treeCCBtn)         end
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