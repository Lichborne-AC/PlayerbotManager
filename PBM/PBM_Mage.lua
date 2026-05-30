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
local MAGE_TALENT_SPECS = {
    { label="Arcane |cffffcc00PvE|r",    spec="arcane pve",   wowSpec="Arcane", icon="Interface\\Icons\\Spell_Holy_MagicalSentry"     },
    { label="Fire |cffffcc00PvE|r",      spec="fire pve",     wowSpec="Fire",   icon="Interface\\Icons\\Spell_Fire_FireBolt02"        },
    { label="Frost |cffffcc00PvE|r",     spec="frost pve",    wowSpec="Frost",  icon="Interface\\Icons\\Spell_Frost_FrostBolt02"      },
    { label="Frostfire |cffffcc00PvE|r", spec="frostfire pve",wowSpec="Fire",   icon="Interface\\Icons\\Ability_Mage_FrostFireBolt"   },
    { label="Arcane |cffff4444PvP|r",    spec="arcane pvp",   wowSpec="Arcane", icon="Interface\\Icons\\Spell_Holy_MagicalSentry"     },
    { label="Fire |cffff4444PvP|r",      spec="fire pvp",     wowSpec="Fire",   icon="Interface\\Icons\\Spell_Fire_FireBolt02"        },
    { label="Frost |cffff4444PvP|r",     spec="frost pvp",    wowSpec="Frost",  icon="Interface\\Icons\\Spell_Frost_FrostBolt02"      },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Mage class-specific overlay panel
-- ─────────────────────────────────────────────────────────────────────────────
local LichborneMageMenu
local LichborneMageCatcher

local MAGE_LEFT_EXT = 5
local MAGE_OVL_W = (PBM.GEAR_OFF + PBM.GEAR_SLOTS * PBM.COL_GEAR_W) - PBM.GS_OFF + MAGE_LEFT_EXT
local MAGE_OVL_H = PBM.MAX_ROWS * PBM.ROW_HEIGHT + 12

local EXT_ICON_SIZE  = 26
local EXT_ICON_GAP   = 4
local EXT_COL_STEP   = EXT_ICON_SIZE + EXT_ICON_GAP

local function HideAllMage()
    PBM.HideCharSheet(LichborneMageMenu, LichborneMageCatcher)
end

function PBM.CloseMageMenu()
    HideAllMage()
end

function PBM.OpenMageMenu(row)
    if not LichborneMageMenu then
        LichborneMageMenu, LichborneMageCatcher = PBM.CreateCharSheet({
            menuName    = "LichborneMageMenu",
            catcherName = "LichborneMageCatcher",
            className   = "Mage",
            classHex    = "69CCF0",
            leftExt     = MAGE_LEFT_EXT,
            overlayW    = MAGE_OVL_W,
            overlayH    = MAGE_OVL_H,
            talentSpecs = MAGE_TALENT_SPECS,
            hideCallback = HideAllMage,
        })

        -- ── Arcane spec tree (upper-center) ────────────────────────────
        local HDR_H = PBM.ROW_HEIGHT
        local TREE_TOTAL_W = 4 * 70 + 3 * 4   -- 4 boxes × 70px + 3 gaps × 4px = 292
        local TREE_X = math.floor((MAGE_OVL_W - TREE_TOTAL_W) / 2)
        local TREE_TOP_Y = -(HDR_H + 68)

        local arcaneSpecBox = CreateFrame("Frame", nil, LichborneMageMenu)
        arcaneSpecBox:SetSize(70, 18)
        arcaneSpecBox:SetPoint("TOPLEFT", LichborneMageMenu, "TOPLEFT", TREE_X, TREE_TOP_Y - 16)
        arcaneSpecBox:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        arcaneSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        arcaneSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local arcaneBoxIcon = arcaneSpecBox:CreateTexture(nil, "ARTWORK")
        arcaneBoxIcon:SetSize(14, 14)
        arcaneBoxIcon:SetPoint("LEFT", arcaneSpecBox, "LEFT", 2, 0)
        arcaneBoxIcon:SetTexture("Interface\\Icons\\Spell_Holy_MagicalSentry")
        local arcaneSpecLabel = arcaneSpecBox:CreateFontString(nil, "OVERLAY")
        arcaneSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        arcaneSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        arcaneSpecLabel:SetText("Arcane")
        arcaneSpecLabel:SetPoint("LEFT", arcaneSpecBox, "LEFT", 18, 0)
        arcaneSpecLabel:SetPoint("RIGHT", arcaneSpecBox, "RIGHT", -2, 0)
        arcaneSpecLabel:SetJustifyH("CENTER")

        local treeArcaneBtn = CreateFrame("Button", nil, LichborneMageMenu)
        treeArcaneBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeArcaneBtn:SetPoint("TOPLEFT", arcaneSpecBox, "BOTTOMLEFT", 22, -4)
        local treeArcaneTex = treeArcaneBtn:CreateTexture(nil, "ARTWORK")
        treeArcaneTex:SetAllPoints()
        treeArcaneTex:SetTexture("Interface\\Icons\\Spell_Holy_MagicalSentry")
        treeArcaneBtn.icon = treeArcaneTex
        treeArcaneBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeArcaneBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneMageMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Arcane|r |cff999999- |r|cff69CCF0arcane|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Arcane mage DPS|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Fire, Frost, Frostfire.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeArcaneBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeArcaneBtn.state = false
        treeArcaneBtn.icon:SetDesaturated(true)
        LichborneMageMenu.treeArcaneBtn = treeArcaneBtn

        -- ── Fire spec tree ──────────────────────────────────────────────
        local fireSpecBox = CreateFrame("Frame", nil, LichborneMageMenu)
        fireSpecBox:SetSize(70, 18)
        fireSpecBox:SetPoint("TOPLEFT", arcaneSpecBox, "TOPRIGHT", 4, 0)
        fireSpecBox:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        fireSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        fireSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local fireBoxIcon = fireSpecBox:CreateTexture(nil, "ARTWORK")
        fireBoxIcon:SetSize(14, 14)
        fireBoxIcon:SetPoint("LEFT", fireSpecBox, "LEFT", 2, 0)
        fireBoxIcon:SetTexture("Interface\\Icons\\Spell_Fire_FireBolt02")
        local fireSpecLabel = fireSpecBox:CreateFontString(nil, "OVERLAY")
        fireSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        fireSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        fireSpecLabel:SetText("Fire")
        fireSpecLabel:SetPoint("LEFT", fireSpecBox, "LEFT", 18, 0)
        fireSpecLabel:SetPoint("RIGHT", fireSpecBox, "RIGHT", -2, 0)
        fireSpecLabel:SetJustifyH("CENTER")

        local treeFireBtn = CreateFrame("Button", nil, LichborneMageMenu)
        treeFireBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeFireBtn:SetPoint("TOPLEFT", fireSpecBox, "BOTTOMLEFT", 22, -4)
        local treeFireTex = treeFireBtn:CreateTexture(nil, "ARTWORK")
        treeFireTex:SetAllPoints()
        treeFireTex:SetTexture("Interface\\Icons\\Spell_Fire_FireBolt02")
        treeFireBtn.icon = treeFireTex
        treeFireBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeFireBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneMageMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Fire|r |cff999999- |r|cff69CCF0fire|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Fire mage DPS|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Arcane, Frost, Frostfire.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeFireBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeFireBtn.state = false
        treeFireBtn.icon:SetDesaturated(true)
        LichborneMageMenu.treeFireBtn = treeFireBtn

        -- ── Frost spec tree ─────────────────────────────────────────────
        local frostSpecBox = CreateFrame("Frame", nil, LichborneMageMenu)
        frostSpecBox:SetSize(70, 18)
        frostSpecBox:SetPoint("TOPLEFT", fireSpecBox, "TOPRIGHT", 4, 0)
        frostSpecBox:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        frostSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        frostSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local frostBoxIcon = frostSpecBox:CreateTexture(nil, "ARTWORK")
        frostBoxIcon:SetSize(14, 14)
        frostBoxIcon:SetPoint("LEFT", frostSpecBox, "LEFT", 2, 0)
        frostBoxIcon:SetTexture("Interface\\Icons\\Spell_Frost_FrostBolt02")
        local frostSpecLabel = frostSpecBox:CreateFontString(nil, "OVERLAY")
        frostSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        frostSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        frostSpecLabel:SetText("Frost")
        frostSpecLabel:SetPoint("LEFT", frostSpecBox, "LEFT", 18, 0)
        frostSpecLabel:SetPoint("RIGHT", frostSpecBox, "RIGHT", -2, 0)
        frostSpecLabel:SetJustifyH("CENTER")

        local treeFrostBtn = CreateFrame("Button", nil, LichborneMageMenu)
        treeFrostBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeFrostBtn:SetPoint("TOPLEFT", frostSpecBox, "BOTTOMLEFT", 22, -4)
        local treeFrostTex = treeFrostBtn:CreateTexture(nil, "ARTWORK")
        treeFrostTex:SetAllPoints()
        treeFrostTex:SetTexture("Interface\\Icons\\Spell_Frost_FrostBolt02")
        treeFrostBtn.icon = treeFrostTex
        treeFrostBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeFrostBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneMageMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Frost|r |cff999999- |r|cff69CCF0frost|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Frost mage DPS|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Arcane, Fire, Frostfire.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeFrostBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeFrostBtn.state = false
        treeFrostBtn.icon:SetDesaturated(true)
        LichborneMageMenu.treeFrostBtn = treeFrostBtn

        -- ── Frostfire spec tree ──────────────────────────────────────────
        local frostfireSpecBox = CreateFrame("Frame", nil, LichborneMageMenu)
        frostfireSpecBox:SetSize(70, 18)
        frostfireSpecBox:SetPoint("TOPLEFT", frostSpecBox, "TOPRIGHT", 4, 0)
        frostfireSpecBox:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        frostfireSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        frostfireSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local frostfireBoxIcon = frostfireSpecBox:CreateTexture(nil, "ARTWORK")
        frostfireBoxIcon:SetSize(14, 14)
        frostfireBoxIcon:SetPoint("LEFT", frostfireSpecBox, "LEFT", 2, 0)
        frostfireBoxIcon:SetTexture("Interface\\Icons\\Ability_Mage_FrostFireBolt")
        local frostfireSpecLabel = frostfireSpecBox:CreateFontString(nil, "OVERLAY")
        frostfireSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        frostfireSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        frostfireSpecLabel:SetText("Frostfire")
        frostfireSpecLabel:SetPoint("LEFT", frostfireSpecBox, "LEFT", 18, 0)
        frostfireSpecLabel:SetPoint("RIGHT", frostfireSpecBox, "RIGHT", -2, 0)
        frostfireSpecLabel:SetJustifyH("CENTER")

        local treeFrostFireBtn = CreateFrame("Button", nil, LichborneMageMenu)
        treeFrostFireBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeFrostFireBtn:SetPoint("TOPLEFT", frostfireSpecBox, "BOTTOMLEFT", 22, -4)
        local treeFrostFireTex = treeFrostFireBtn:CreateTexture(nil, "ARTWORK")
        treeFrostFireTex:SetAllPoints()
        treeFrostFireTex:SetTexture("Interface\\Icons\\Ability_Mage_FrostFireBolt")
        treeFrostFireBtn.icon = treeFrostFireTex
        treeFrostFireBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeFrostFireBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneMageMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Frostfire|r |cff999999- |r|cff69CCF0frostfire|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Frostfire mage DPS|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Arcane, Fire, Frost.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeFrostFireBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeFrostFireBtn.state = false
        treeFrostFireBtn.icon:SetDesaturated(true)
        LichborneMageMenu.treeFrostFireBtn = treeFrostFireBtn

        -- ── Shared AoE section (centered below all spec trees) ──────────
        -- arcaneSpecBox left + 111px centers the 70px box over the 292px tree span
        local aoeSpecBox = CreateFrame("Frame", nil, LichborneMageMenu)
        aoeSpecBox:SetSize(70, 18)
        aoeSpecBox:SetPoint("TOPLEFT", arcaneSpecBox, "BOTTOMLEFT", 74, -45)
        aoeSpecBox:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        aoeSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        aoeSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local aoeSpecLabel = aoeSpecBox:CreateFontString(nil, "OVERLAY")
        aoeSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        aoeSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        aoeSpecLabel:SetText("AoE")
        aoeSpecLabel:SetAllPoints()
        aoeSpecLabel:SetJustifyH("CENTER")

        local treeAoeBtn = CreateFrame("Button", nil, LichborneMageMenu)
        treeAoeBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeAoeBtn:SetPoint("TOPLEFT", aoeSpecBox, "BOTTOMLEFT", 22, -4)
        local treeAoeTex = treeAoeBtn:CreateTexture(nil, "ARTWORK")
        treeAoeTex:SetAllPoints()
        treeAoeTex:SetTexture("Interface\\Icons\\Spell_Frost_IceStorm")
        treeAoeBtn.icon = treeAoeTex
        treeAoeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeAoeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneMageMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00AoE|r |cff999999- |r|cff69CCF0aoe|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00AoE rotation modifier|r", 1, 1, 1)
            GameTooltip:AddLine("Spec-aware — adapts to the active talent tree.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeAoeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeAoeBtn.state = false
        treeAoeBtn.icon:SetDesaturated(true)
        LichborneMageMenu.treeAoeBtn = treeAoeBtn

        -- ── Firestarter section (to the right of AoE) ──────────────────
        local firestarterSpecBox = CreateFrame("Frame", nil, LichborneMageMenu)
        firestarterSpecBox:SetSize(70, 18)
        firestarterSpecBox:SetPoint("TOPLEFT", aoeSpecBox, "TOPRIGHT", 4, 0)
        firestarterSpecBox:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        firestarterSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        firestarterSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local firestarterSpecLabel = firestarterSpecBox:CreateFontString(nil, "OVERLAY")
        firestarterSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        firestarterSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        firestarterSpecLabel:SetText("Firestarter")
        firestarterSpecLabel:SetAllPoints()
        firestarterSpecLabel:SetJustifyH("CENTER")

        local treeFirestarterBtn = CreateFrame("Button", nil, LichborneMageMenu)
        treeFirestarterBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeFirestarterBtn:SetPoint("TOPLEFT", firestarterSpecBox, "BOTTOMLEFT", 22, -4)
        local treeFirestarterTex = treeFirestarterBtn:CreateTexture(nil, "ARTWORK")
        treeFirestarterTex:SetAllPoints()
        treeFirestarterTex:SetTexture("Interface\\Icons\\Ability_Mage_Firestarter")
        treeFirestarterBtn.icon = treeFirestarterTex
        treeFirestarterBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeFirestarterBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneMageMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Firestarter|r |cff999999- |r|cff69CCF0firestarter|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Melee range opener|r", 1, 1, 1)
            GameTooltip:AddLine("Runs to melee range to use |cff5599EEDragon's Breath|r", 1, 1, 1)
            GameTooltip:AddLine("and |cff5599EEBlast Wave|r as openers.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeFirestarterBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeFirestarterBtn.state = false
        treeFirestarterBtn.icon:SetDesaturated(true)
        LichborneMageMenu.treeFirestarterBtn = treeFirestarterBtn

        -- ── Buffs tier (Mage Armor / Molten Armor) ─────────────────────
        local buffsSpecBox = CreateFrame("Frame", nil, LichborneMageMenu)
        buffsSpecBox:SetSize(60, 18)
        buffsSpecBox:SetPoint("TOPLEFT", aoeSpecBox, "BOTTOMLEFT", 42, -45)
        buffsSpecBox:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        buffsSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        buffsSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local buffsSpecLabel = buffsSpecBox:CreateFontString(nil, "OVERLAY")
        buffsSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        buffsSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        buffsSpecLabel:SetText("Buffs (Self)")
        buffsSpecLabel:SetAllPoints()
        buffsSpecLabel:SetJustifyH("CENTER")

        local treeMageArmorBtn = CreateFrame("Button", nil, LichborneMageMenu)
        treeMageArmorBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeMageArmorBtn:SetPoint("TOPLEFT", buffsSpecBox, "BOTTOMLEFT", 2, -4)
        local treeMageArmorTex = treeMageArmorBtn:CreateTexture(nil, "ARTWORK")
        treeMageArmorTex:SetAllPoints()
        treeMageArmorTex:SetTexture("Interface\\Icons\\Spell_MageArmor")
        treeMageArmorBtn.icon = treeMageArmorTex
        treeMageArmorBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeMageArmorBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneMageMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Mage Armor|r |cff999999- |r|cffffff00bmana|r |cffff8000NC|r")
            GameTooltip:AddLine("|cffffcc00Mana regen armor|r", 1, 1, 1)
            GameTooltip:AddLine("Increases |cff1EFF00resistance|r to magic debuffs.", 1, 1, 1)
            GameTooltip:AddLine("|cff3A8FC4Mana|r regeneration continues while casting.", 1, 1, 1)
            GameTooltip:AddLine("Best for survivability and mana-intensive fights.", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Molten Armor.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeMageArmorBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeMageArmorBtn.state = false
        treeMageArmorBtn.icon:SetDesaturated(true)
        LichborneMageMenu.treeMageArmorBtn = treeMageArmorBtn

        local treeMoltenArmorBtn = CreateFrame("Button", nil, LichborneMageMenu)
        treeMoltenArmorBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeMoltenArmorBtn:SetPoint("TOPLEFT", buffsSpecBox, "BOTTOMLEFT", 32, -4)
        local treeMoltenArmorTex = treeMoltenArmorBtn:CreateTexture(nil, "ARTWORK")
        treeMoltenArmorTex:SetAllPoints()
        treeMoltenArmorTex:SetTexture("Interface\\Icons\\Ability_Mage_MoltenArmor")
        treeMoltenArmorBtn.icon = treeMoltenArmorTex
        treeMoltenArmorBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeMoltenArmorBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneMageMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Molten Armor|r |cff999999- |r|cffffff00bdps|r |cffff8000NC|r")
            GameTooltip:AddLine("|cffffcc00Crit DPS armor|r", 1, 1, 1)
            GameTooltip:AddLine("Causes |cffFF4444fire damage|r when hit.", 1, 1, 1)
            GameTooltip:AddLine("Increases |cffFF9900crit chance|r by your |cff1EFF00Spirit|r.", 1, 1, 1)
            GameTooltip:AddLine("Best for pure DPS output.", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Mage Armor.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeMoltenArmorBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeMoltenArmorBtn.state = false
        treeMoltenArmorBtn.icon:SetDesaturated(true)
        LichborneMageMenu.treeMoltenArmorBtn = treeMoltenArmorBtn

        -- ── Assist section (below Buffs row) ───────────────────────────
        local assistSpecBox = CreateFrame("Frame", nil, LichborneMageMenu)
        assistSpecBox:SetSize(56, 18)
        assistSpecBox:SetPoint("TOPLEFT", buffsSpecBox, "BOTTOMLEFT", 2, -45)
        assistSpecBox:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        assistSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        assistSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local assistSpecLabel = assistSpecBox:CreateFontString(nil, "OVERLAY")
        assistSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        assistSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        assistSpecLabel:SetText("Assist")
        assistSpecLabel:SetAllPoints()
        assistSpecLabel:SetJustifyH("CENTER")

        local treeTankAssistBtn = CreateFrame("Button", nil, LichborneMageMenu)
        treeTankAssistBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeTankAssistBtn:SetPoint("TOPLEFT", assistSpecBox, "BOTTOMLEFT", 0, -4)
        local treeTankAssistTex = treeTankAssistBtn:CreateTexture(nil, "ARTWORK")
        treeTankAssistTex:SetAllPoints()
        treeTankAssistTex:SetTexture("Interface\\Icons\\inv_shield_02")
        treeTankAssistBtn.icon = treeTankAssistTex
        treeTankAssistBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeTankAssistBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneMageMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Tank Assist|r |cff999999- |r|cffff8000tank assist|r |cffffcc00CO|r")
            GameTooltip:AddLine("|cffffcc00Tank target focus|r", 1, 1, 1)
            GameTooltip:AddLine("Bot attacks the tank's current target.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeTankAssistBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeTankAssistBtn.state = false
        treeTankAssistBtn.icon:SetDesaturated(true)
        LichborneMageMenu.treeTankAssistBtn = treeTankAssistBtn

        local treeDpsAssistBtn = CreateFrame("Button", nil, LichborneMageMenu)
        treeDpsAssistBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeDpsAssistBtn:SetPoint("TOPLEFT", assistSpecBox, "BOTTOMLEFT", 30, -4)
        local treeDpsAssistTex = treeDpsAssistBtn:CreateTexture(nil, "ARTWORK")
        treeDpsAssistTex:SetAllPoints()
        treeDpsAssistTex:SetTexture("Interface\\Icons\\Ability_Warrior_Challange")
        treeDpsAssistBtn.icon = treeDpsAssistTex
        treeDpsAssistBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeDpsAssistBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneMageMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00DPS Assist|r |cff999999- |r|cffff8000dps assist|r |cffffcc00CO|r")
            GameTooltip:AddLine("|cffffcc00DPS target focus|r", 1, 1, 1)
            GameTooltip:AddLine("Bot attacks the main DPS focus target.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeDpsAssistBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeDpsAssistBtn.state = false
        treeDpsAssistBtn.icon:SetDesaturated(true)
        LichborneMageMenu.treeDpsAssistBtn = treeDpsAssistBtn

        local treeDpsAoeBtn = CreateFrame("Button", nil, LichborneMageMenu)
        treeDpsAoeBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeDpsAoeBtn:SetPoint("TOPLEFT", assistSpecBox, "BOTTOMLEFT", 62, -4)
        local treeDpsAoeTex = treeDpsAoeBtn:CreateTexture(nil, "ARTWORK")
        treeDpsAoeTex:SetAllPoints()
        treeDpsAoeTex:SetTexture("Interface\\Icons\\Spell_Shadow_RainOfFire")
        treeDpsAoeBtn.icon = treeDpsAoeTex
        treeDpsAoeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeDpsAoeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneMageMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00DPS AoE|r |cff999999- |r|cff69CCF0aoe|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Cross-role AoE mode|r", 1, 1, 1)
            GameTooltip:AddLine("Bot switches to |cffffcc00AoE|r rotation.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeDpsAoeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeDpsAoeBtn.state = false
        treeDpsAoeBtn.icon:SetDesaturated(true)
        treeDpsAoeBtn:Hide()
        LichborneMageMenu.treeDpsAoeBtn = treeDpsAoeBtn

        -- ── Left-side Buff header+button (below PvP) ─────────────────
        local BUFF_HDR_W = EXT_ICON_SIZE + 8
        local buffSideHdrBox = CreateFrame("Frame", nil, LichborneMageMenu)
        buffSideHdrBox:SetSize(BUFF_HDR_W, 18)
        buffSideHdrBox:SetPoint("TOPLEFT", LichborneMageMenu.treePvpBtn, "BOTTOMLEFT", -4, -8)
        buffSideHdrBox:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        buffSideHdrBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        buffSideHdrBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local buffSideHdrLabel = buffSideHdrBox:CreateFontString(nil, "OVERLAY")
        buffSideHdrLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        buffSideHdrLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        buffSideHdrLabel:SetAllPoints(); buffSideHdrLabel:SetJustifyH("CENTER")
        buffSideHdrLabel:SetText("Buff")

        local treeSideBuffBtn = CreateFrame("Button", nil, LichborneMageMenu)
        treeSideBuffBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeSideBuffBtn:SetPoint("TOPLEFT", buffSideHdrBox, "BOTTOMLEFT",
            math.floor((BUFF_HDR_W - EXT_ICON_SIZE) / 2), -1)
        local treeSideBuffTex = treeSideBuffBtn:CreateTexture(nil, "ARTWORK")
        treeSideBuffTex:SetAllPoints()
        treeSideBuffTex:SetTexture("Interface\\Icons\\Spell_Holy_MagicalSentry")
        treeSideBuffBtn.icon = treeSideBuffTex
        treeSideBuffBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeSideBuffBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneMageMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Buff|r |cff999999- |r|cffffff00buff|r |cffff8000NC|r")
            GameTooltip:AddLine("|cffffcc00Group Intellect buff|r", 1, 1, 1)
            GameTooltip:AddLine("|cff5599EEArcane Intellect|r on all party members.", 1, 1, 1)
            GameTooltip:AddLine("Increases |cffffcc00Intellect|r for 30 min.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeSideBuffBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeSideBuffBtn.state = false
        treeSideBuffBtn.icon:SetDesaturated(true)
        LichborneMageMenu.treeSideBuffBtn = treeSideBuffBtn

        -- ── Wire Mage class-specific toggle logic ─────────────────────
        do
            local function IconOn(btn)
                btn.state = true
                if btn.icon then btn.icon:SetDesaturated(false) end
            end
            local function IconOff(btn)
                btn.state = false
                if btn.icon then btn.icon:SetDesaturated(true) end
            end

            -- Start all toggleable icons desaturated (OFF)
            IconOff(treeFirestarterBtn)
            IconOff(treeMageArmorBtn); IconOff(treeMoltenArmorBtn)
            IconOff(treeSideBuffBtn)
            IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)

            -- Expose reset so OpenMageMenu can clear all icons before each query
            local _baseReset = LichborneMageMenu.resetSharedIcons
            LichborneMageMenu.resetAllIcons = function()
                if _baseReset then _baseReset() end
                -- class-specific tree buttons only (food/loot/gather handled by base)
                IconOff(treeArcaneBtn); IconOff(treeFireBtn)
                IconOff(treeFrostBtn); IconOff(treeFrostFireBtn)
                IconOff(treeAoeBtn); IconOff(treeFirestarterBtn)
                IconOff(treeMageArmorBtn); IconOff(treeMoltenArmorBtn)
                IconOff(treeSideBuffBtn)
                IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
            end

            -- Shared aoe sync helper — all aoe buttons represent the same strategy
            local function AoeAllOn()
                IconOn(treeAoeBtn)
            end
            local function AoeAllOff()
                IconOff(treeAoeBtn)
            end

            -- TREE: Arcane (exclusive with Frost/Fire/FrostFire)
            treeArcaneBtn:SetScript("OnClick", function()
                local bot = LichborneMageMenu.botName or ""
                LichborneMageMenu._specUserSet = true
                if treeArcaneBtn.state then
                    PBM.SendToBot("co -arcane,?", bot)
                    IconOff(treeArcaneBtn)
                else
                    PBM.SendToBot("co +arcane,?", bot)
                    IconOn(treeArcaneBtn)
                    IconOff(treeFrostBtn)
                    IconOff(treeFireBtn)
                    IconOff(treeFrostFireBtn)
                end
            end)

            -- TREE: Fire (exclusive with Arcane/Frost/FrostFire)
            treeFireBtn:SetScript("OnClick", function()
                local bot = LichborneMageMenu.botName or ""
                LichborneMageMenu._specUserSet = true
                if treeFireBtn.state then
                    PBM.SendToBot("co -fire,?", bot)
                    IconOff(treeFireBtn)
                else
                    PBM.SendToBot("co +fire,?", bot)
                    IconOn(treeFireBtn)
                    IconOff(treeArcaneBtn)
                    IconOff(treeFrostBtn)
                    IconOff(treeFrostFireBtn)
                end
            end)

            -- TREE: Frost (exclusive with Arcane/Fire/FrostFire)
            treeFrostBtn:SetScript("OnClick", function()
                local bot = LichborneMageMenu.botName or ""
                LichborneMageMenu._specUserSet = true
                if treeFrostBtn.state then
                    PBM.SendToBot("co -frost,?", bot)
                    IconOff(treeFrostBtn)
                else
                    PBM.SendToBot("co +frost,?", bot)
                    IconOn(treeFrostBtn)
                    IconOff(treeArcaneBtn)
                    IconOff(treeFireBtn)
                    IconOff(treeFrostFireBtn)
                end
            end)

            -- TREE: Frostfire (exclusive with Arcane/Fire/Frost)
            treeFrostFireBtn:SetScript("OnClick", function()
                local bot = LichborneMageMenu.botName or ""
                LichborneMageMenu._specUserSet = true
                if treeFrostFireBtn.state then
                    PBM.SendToBot("co -frostfire,?", bot)
                    IconOff(treeFrostFireBtn)
                else
                    PBM.SendToBot("co +frostfire,?", bot)
                    IconOn(treeFrostFireBtn)
                    IconOff(treeArcaneBtn)
                    IconOff(treeFireBtn)
                    IconOff(treeFrostBtn)
                end
            end)

            -- TREE: AoE (shared, mirrors all pb AoE buttons)
            treeAoeBtn:SetScript("OnClick", function()
                local bot = LichborneMageMenu.botName or ""
                LichborneMageMenu._specUserSet = true
                if treeAoeBtn.state then
                    PBM.SendToBot("co -aoe,?", bot); AoeAllOff()
                else
                    PBM.SendToBot("co +aoe,?", bot); AoeAllOn()
                end
            end)

            -- TREE: Firestarter (independent)
            treeFirestarterBtn:SetScript("OnClick", function()
                local bot = LichborneMageMenu.botName or ""
                LichborneMageMenu._specUserSet = true
                if treeFirestarterBtn.state then
                    PBM.SendToBot("co -firestarter,?", bot)
                    IconOff(treeFirestarterBtn)
                else
                    PBM.SendToBot("co +firestarter,?", bot)
                    IconOn(treeFirestarterBtn)
                end
            end)

            -- LEFT-SIDE: Buff — nc +buff / nc -buff, independent
            treeSideBuffBtn:SetScript("OnClick", function()
                local bot = LichborneMageMenu.botName or ""
                LichborneMageMenu._specUserSet = true
                if treeSideBuffBtn.state then
                    PBM.SendToBot("nc -buff,?", bot)
                    IconOff(treeSideBuffBtn)
                else
                    PBM.SendToBot("nc +buff,?", bot)
                    IconOn(treeSideBuffBtn)
                end
            end)

            -- TREE: Tank Assist
            treeTankAssistBtn:SetScript("OnClick", function()
                local bot = LichborneMageMenu.botName or ""
                LichborneMageMenu._specUserSet = true
                if treeTankAssistBtn.state then
                    PBM.SendToBot("co -tank assist,?", bot)
                    IconOff(treeTankAssistBtn)
                else
                    PBM.SendToBot("co +tank assist,?", bot)
                    IconOn(treeTankAssistBtn)
                    IconOff(treeDpsAssistBtn)
                    IconOff(treeDpsAoeBtn)
                end
            end)

            -- TREE: DPS Assist
            treeDpsAssistBtn:SetScript("OnClick", function()
                local bot = LichborneMageMenu.botName or ""
                LichborneMageMenu._specUserSet = true
                if treeDpsAssistBtn.state then
                    PBM.SendToBot("co -dps assist,?", bot)
                    IconOff(treeDpsAssistBtn)
                else
                    PBM.SendToBot("co +dps assist,?", bot)
                    IconOn(treeDpsAssistBtn)
                    IconOff(treeTankAssistBtn)
                    IconOff(treeDpsAoeBtn)
                end
            end)

            -- TREE: DPS AoE
            treeDpsAoeBtn:SetScript("OnClick", function()
                local bot = LichborneMageMenu.botName or ""
                LichborneMageMenu._specUserSet = true
                if treeDpsAoeBtn.state then
                    PBM.SendToBot("co -aoe,?", bot)
                    IconOff(treeDpsAoeBtn)
                else
                    PBM.SendToBot("co +aoe,?", bot)
                    IconOn(treeDpsAoeBtn)
                    IconOff(treeTankAssistBtn)
                    IconOff(treeDpsAssistBtn)
                end
            end)

            -- TREE: Mage Armor (bmana NC, exclusive with Molten Armor)
            treeMageArmorBtn:SetScript("OnClick", function()
                local bot = LichborneMageMenu.botName or ""
                LichborneMageMenu._specUserSet = true
                if treeMageArmorBtn.state then
                    PBM.SendToBot("nc -bmana,?", bot)
                    IconOff(treeMageArmorBtn)
                else
                    PBM.SendToBot("nc +bmana,?", bot)
                    IconOn(treeMageArmorBtn); IconOff(treeMoltenArmorBtn)
                end
            end)

            -- TREE: Molten Armor (bdps NC, exclusive with Mage Armor)
            treeMoltenArmorBtn:SetScript("OnClick", function()
                local bot = LichborneMageMenu.botName or ""
                LichborneMageMenu._specUserSet = true
                if treeMoltenArmorBtn.state then
                    PBM.SendToBot("nc -bdps,?", bot)
                    IconOff(treeMoltenArmorBtn)
                else
                    PBM.SendToBot("nc +bdps,?", bot)
                    IconOn(treeMoltenArmorBtn); IconOff(treeMageArmorBtn)
                end
            end)

            -- ── State restore from co? query ──────────────────────────
            -- Wraps the strat-list callback so arriving strategy data also
            -- syncs icon visual states.
            -- Role/strategy buttons: sync only on initial menu load (MultiBot pattern).
            -- _specUserSet = true after any click; flag blocks reply-driven re-sync.
            local _baseSU = LichborneMageMenu.onStrategyUpdate
            LichborneMageMenu.onStrategyUpdate = function(stratType, activeSet)
                if _baseSU then _baseSU(stratType, activeSet) end
                if not LichborneMageMenu._specUserSet then
                    if stratType == "co" then
                        if activeSet["tank assist"]   then IconOn(treeTankAssistBtn)    else IconOff(treeTankAssistBtn)    end
                        if activeSet["dps assist"]    then IconOn(treeDpsAssistBtn)     else IconOff(treeDpsAssistBtn)     end
                        if activeSet["aoe"]            then IconOn(treeDpsAoeBtn)        else IconOff(treeDpsAoeBtn)        end
                        if activeSet["arcane"]        then IconOn(treeArcaneBtn)        else IconOff(treeArcaneBtn)        end
                        if activeSet["fire"]          then IconOn(treeFireBtn)          else IconOff(treeFireBtn)          end
                        if activeSet["frost"]         then IconOn(treeFrostBtn)         else IconOff(treeFrostBtn)         end
                        if activeSet["frostfire"]     then IconOn(treeFrostFireBtn)     else IconOff(treeFrostFireBtn)     end
                        if activeSet["aoe"]           then IconOn(treeAoeBtn)           else IconOff(treeAoeBtn)           end
                        if activeSet["firestarter"]   then IconOn(treeFirestarterBtn)   else IconOff(treeFirestarterBtn)   end
                    elseif stratType == "nc" then
                        if activeSet["bmana"] then IconOn(treeMageArmorBtn)   else IconOff(treeMageArmorBtn)   end
                        if activeSet["bdps"]  then IconOn(treeMoltenArmorBtn) else IconOff(treeMoltenArmorBtn) end
                        if activeSet["buff"]  then IconOn(treeSideBuffBtn)    else IconOff(treeSideBuffBtn)    end
                    end
                end
            end
        end -- end toggle wire block
    end

    if LichborneMageMenu:IsShown() and LichborneMageMenu.sourceRow == row then
        HideAllMage(); return
    end
    PBM.ShowCharSheet(LichborneMageMenu, LichborneMageCatcher, row, MAGE_LEFT_EXT)
end
