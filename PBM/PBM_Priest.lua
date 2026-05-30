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
local PRIEST_TALENT_SPECS = {
    { label="Discipline |cffffcc00PvE|r", spec="disc pve",   wowSpec="Discipline",  icon="Interface\\Icons\\Spell_Holy_WordFortitude"    },
    { label="Holy |cffffcc00PvE|r",       spec="holy pve",   wowSpec="Holy Priest", icon="Interface\\Icons\\Spell_Holy_GuardianSpirit"   },
    { label="Shadow |cffffcc00PvE|r",     spec="shadow pve", wowSpec="Shadow",      icon="Interface\\Icons\\Spell_Shadow_ShadowWordPain" },
    { label="Discipline |cffff4444PvP|r", spec="disc pvp",   wowSpec="Discipline",  icon="Interface\\Icons\\Spell_Holy_WordFortitude"    },
    { label="Holy |cffff4444PvP|r",       spec="holy pvp",   wowSpec="Holy Priest", icon="Interface\\Icons\\Spell_Holy_GuardianSpirit"   },
    { label="Shadow |cffff4444PvP|r",     spec="shadow pvp", wowSpec="Shadow",      icon="Interface\\Icons\\Spell_Shadow_ShadowWordPain" },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Priest class-specific overlay panel
-- ─────────────────────────────────────────────────────────────────────────────
local LichbornePriestMenu
local LichbornePriestCatcher

local PRIEST_LEFT_EXT = 5
local PRIEST_OVL_W = (PBM.GEAR_OFF + PBM.GEAR_SLOTS * PBM.COL_GEAR_W) - PBM.GS_OFF + PRIEST_LEFT_EXT
local PRIEST_OVL_H = PBM.MAX_ROWS * PBM.ROW_HEIGHT + 12

local EXT_ICON_SIZE  = 26

local function HideAllPriest()
    if LichbornePriestMenu and LichbornePriestMenu._closeMultibotSub then
        LichbornePriestMenu._closeMultibotSub()
    end
    PBM.HideCharSheet(LichbornePriestMenu, LichbornePriestCatcher)
end

function PBM.ClosePriestMenu()
    HideAllPriest()
end

function PBM.OpenPriestMenu(row)
    if not LichbornePriestMenu then
        LichbornePriestMenu, LichbornePriestCatcher = PBM.CreateCharSheet({
            menuName    = "LichbornePriestMenu",
            catcherName = "LichbornePriestCatcher",
            className   = "Priest",
            classHex    = "FFFFFF",
            leftExt     = PRIEST_LEFT_EXT,
            overlayW    = PRIEST_OVL_W,
            overlayH    = PRIEST_OVL_H,
            talentSpecs = PRIEST_TALENT_SPECS,
            hideCallback = HideAllPriest,
        })

        -- ── Strategy tree layout ─────────────────────────────────────
        local TREE_TOTAL_W = 2 * 107 + 4       -- 2 columns × 107px + 1 gap × 4px = 218
        local TREE_X = math.floor((PRIEST_OVL_W - TREE_TOTAL_W) / 2)
        local TREE_TOP_Y = -(PBM.ROW_HEIGHT + 68)

        -- ── Healing column header ───────────────────────────────────
        local healingSpecBox = CreateFrame("Frame", nil, LichbornePriestMenu)
        healingSpecBox:SetSize(107, 18)
        healingSpecBox:SetPoint("TOPLEFT", LichbornePriestMenu, "TOPLEFT", TREE_X, TREE_TOP_Y - 16)
        healingSpecBox:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        healingSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        healingSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local healDiscIcon = healingSpecBox:CreateTexture(nil, "ARTWORK")
        healDiscIcon:SetSize(14, 14)
        healDiscIcon:SetPoint("LEFT", healingSpecBox, "LEFT", 2, 0)
        healDiscIcon:SetTexture("Interface\\Icons\\Spell_Holy_WordFortitude")
        local healHolyIcon = healingSpecBox:CreateTexture(nil, "ARTWORK")
        healHolyIcon:SetSize(14, 14)
        healHolyIcon:SetPoint("LEFT", healingSpecBox, "LEFT", 18, 0)
        healHolyIcon:SetTexture("Interface\\Icons\\Spell_Holy_GuardianSpirit")
        local healingSpecLabel = healingSpecBox:CreateFontString(nil, "OVERLAY")
        healingSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        healingSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        healingSpecLabel:SetText("Healing")
        healingSpecLabel:SetPoint("LEFT", healingSpecBox, "LEFT", 34, 0)
        healingSpecLabel:SetPoint("RIGHT", healingSpecBox, "RIGHT", -2, 0)
        healingSpecLabel:SetJustifyH("CENTER")

        -- ── DPS column header ───────────────────────────────────────
        local dpsSpecBox = CreateFrame("Frame", nil, LichbornePriestMenu)
        dpsSpecBox:SetSize(107, 18)
        dpsSpecBox:SetPoint("TOPLEFT", healingSpecBox, "TOPRIGHT", 4, 0)
        dpsSpecBox:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        dpsSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        dpsSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local dpsHolyIcon = dpsSpecBox:CreateTexture(nil, "ARTWORK")
        dpsHolyIcon:SetSize(14, 14)
        dpsHolyIcon:SetPoint("LEFT", dpsSpecBox, "LEFT", 2, 0)
        dpsHolyIcon:SetTexture("Interface\\Icons\\Spell_Holy_GuardianSpirit")
        local dpsShadowIcon = dpsSpecBox:CreateTexture(nil, "ARTWORK")
        dpsShadowIcon:SetSize(14, 14)
        dpsShadowIcon:SetPoint("LEFT", dpsSpecBox, "LEFT", 18, 0)
        dpsShadowIcon:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowWordPain")
        local dpsSpecLabel = dpsSpecBox:CreateFontString(nil, "OVERLAY")
        dpsSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        dpsSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        dpsSpecLabel:SetText("DPS")
        dpsSpecLabel:SetPoint("LEFT", dpsSpecBox, "LEFT", 34, 0)
        dpsSpecLabel:SetPoint("RIGHT", dpsSpecBox, "RIGHT", -2, 0)
        dpsSpecLabel:SetJustifyH("CENTER")

        -- ── Spec tree buttons ───────────────────────────────────────
        -- Healing column: Heal + Holy Heal side by side (centered in 107px)
        local treeHealBtn = CreateFrame("Button", nil, LichbornePriestMenu)
        treeHealBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeHealBtn:SetPoint("TOPLEFT", healingSpecBox, "BOTTOMLEFT", 25, -4)
        local treeHealTex = treeHealBtn:CreateTexture(nil, "ARTWORK")
        treeHealTex:SetAllPoints()
        treeHealTex:SetTexture("Interface\\Icons\\Spell_Holy_WordFortitude")
        treeHealBtn.icon = treeHealTex
        treeHealBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeHealBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichbornePriestMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Heal|r |cff999999- |r|cffFFFFFFheal|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Discipline healing|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Holy Heal, Holy DPS, Shadow.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeHealBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeHealBtn.state = false
        treeHealBtn.icon:SetDesaturated(true)
        LichbornePriestMenu.treeHealBtn = treeHealBtn

        local treeHolyHealBtn = CreateFrame("Button", nil, LichbornePriestMenu)
        treeHolyHealBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeHolyHealBtn:SetPoint("TOPLEFT", treeHealBtn, "TOPRIGHT", 4, 0)
        local treeHolyHealTex = treeHolyHealBtn:CreateTexture(nil, "ARTWORK")
        treeHolyHealTex:SetAllPoints()
        treeHolyHealTex:SetTexture("Interface\\Icons\\Spell_Holy_GuardianSpirit")
        treeHolyHealBtn.icon = treeHolyHealTex
        treeHolyHealBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeHolyHealBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichbornePriestMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Holy Heal|r |cff999999- |r|cffFFFFFFholy heal|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Holy healing specialization|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Discipline, Holy DPS, Shadow.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeHolyHealBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeHolyHealBtn.state = false
        treeHolyHealBtn.icon:SetDesaturated(true)
        LichbornePriestMenu.treeHolyHealBtn = treeHolyHealBtn

        -- DPS column: Holy DPS + Shadow side by side (centered in 107px)
        local treeHolyDpsBtn = CreateFrame("Button", nil, LichbornePriestMenu)
        treeHolyDpsBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeHolyDpsBtn:SetPoint("TOPLEFT", dpsSpecBox, "BOTTOMLEFT", 25, -4)
        local treeHolyDpsTex = treeHolyDpsBtn:CreateTexture(nil, "ARTWORK")
        treeHolyDpsTex:SetAllPoints()
        treeHolyDpsTex:SetTexture("Interface\\Icons\\Spell_Holy_SealOfWrath")
        treeHolyDpsBtn.icon = treeHolyDpsTex
        treeHolyDpsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeHolyDpsBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichbornePriestMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Holy DPS|r |cff999999- |r|cffFFFFFFholy|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Holy DPS specialization|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Discipline, Holy Heal, Shadow.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeHolyDpsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeHolyDpsBtn.state = false
        treeHolyDpsBtn.icon:SetDesaturated(true)
        LichbornePriestMenu.treeHolyDpsBtn = treeHolyDpsBtn

        local treeShadowDpsBtn = CreateFrame("Button", nil, LichbornePriestMenu)
        treeShadowDpsBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeShadowDpsBtn:SetPoint("TOPLEFT", treeHolyDpsBtn, "TOPRIGHT", 4, 0)
        local treeShadowDpsTex = treeShadowDpsBtn:CreateTexture(nil, "ARTWORK")
        treeShadowDpsTex:SetAllPoints()
        treeShadowDpsTex:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowWordPain")
        treeShadowDpsBtn.icon = treeShadowDpsTex
        treeShadowDpsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeShadowDpsBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichbornePriestMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Shadow|r |cff999999- |r|cffFFFFFFshadow|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Shadow DPS specialization|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Discipline, Holy Heal, Holy DPS.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeShadowDpsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeShadowDpsBtn.state = false
        treeShadowDpsBtn.icon:SetDesaturated(true)
        LichbornePriestMenu.treeShadowDpsBtn = treeShadowDpsBtn

        -- Healer DPS button — centered horizontally between Holy Heal and Holy DPS,
        -- top aligned with their vertical midpoints
        local treeHealerDpsBtn = CreateFrame("Button", nil, LichbornePriestMenu)
        treeHealerDpsBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeHealerDpsBtn:SetPoint("TOPLEFT", treeHolyHealBtn, "TOPRIGHT", 15, -13)
        local treeHealerDpsTex = treeHealerDpsBtn:CreateTexture(nil, "ARTWORK")
        treeHealerDpsTex:SetAllPoints()
        treeHealerDpsTex:SetTexture("Interface\\Icons\\Spell_Holy_DivineProvidence")
        treeHealerDpsBtn.icon = treeHealerDpsTex
        treeHealerDpsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeHealerDpsBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichbornePriestMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Healer DPS|r |cff999999- |r|cffFFFFFFhealer dps|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Healer that fills with DPS|r", 1, 1, 1)
            GameTooltip:AddLine("Priest heals when needed, then fills with", 1, 1, 1)
            GameTooltip:AddLine("|cffFFFFFFShadow Word: Pain|r and |cffFFFFFFMind Blast|r between heals.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeHealerDpsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeHealerDpsBtn.state = false
        treeHealerDpsBtn.icon:SetDesaturated(true)
        LichbornePriestMenu.treeHealerDpsBtn = treeHealerDpsBtn

        -- ── AoE header + buttons ────────────────────────────────────
        local aoeHeader = CreateFrame("Frame", nil, LichbornePriestMenu)
        aoeHeader:SetSize(56, 14)
        aoeHeader:SetPoint("TOPLEFT", healingSpecBox, "BOTTOMLEFT", 81, -(4 + 13 + EXT_ICON_SIZE + 8))
        aoeHeader:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        aoeHeader:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        aoeHeader:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local aoeLabel = aoeHeader:CreateFontString(nil, "OVERLAY")
        aoeLabel:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        aoeLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        aoeLabel:SetText("AoE")
        aoeLabel:SetAllPoints()
        aoeLabel:SetJustifyH("CENTER")

        local treeDpsAoeBtn = CreateFrame("Button", nil, LichbornePriestMenu)
        treeDpsAoeBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeDpsAoeBtn:SetPoint("TOPLEFT", aoeHeader, "BOTTOMLEFT", 0, -4)
        local treeDpsAoeTex = treeDpsAoeBtn:CreateTexture(nil, "ARTWORK")
        treeDpsAoeTex:SetAllPoints()
        treeDpsAoeTex:SetTexture("Interface\\Icons\\Spell_Shadow_RainOfFire")
        treeDpsAoeBtn.icon = treeDpsAoeTex
        treeDpsAoeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeDpsAoeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichbornePriestMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00DPS AoE|r |cff999999- |r|cffFFFFFFshadow aoe|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00AoE shadow rotation|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeDpsAoeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeDpsAoeBtn.state = false
        treeDpsAoeBtn.icon:SetDesaturated(true)
        LichbornePriestMenu.treeDpsAoeBtn = treeDpsAoeBtn

        local treeShadowAoeBtn = CreateFrame("Button", nil, LichbornePriestMenu)
        treeShadowAoeBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeShadowAoeBtn:SetPoint("TOPLEFT", treeDpsAoeBtn, "TOPRIGHT", 4, 0)
        local treeShadowAoeTex = treeShadowAoeBtn:CreateTexture(nil, "ARTWORK")
        treeShadowAoeTex:SetAllPoints()
        treeShadowAoeTex:SetTexture("Interface\\Icons\\Spell_Arcane_ArcaneTorrent")
        treeShadowAoeBtn.icon = treeShadowAoeTex
        treeShadowAoeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeShadowAoeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichbornePriestMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Shadow AoE|r |cff999999- |r|cffFFFFFFshadow aoe|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Shadow AoE rotation|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeShadowAoeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeShadowAoeBtn.state = false
        treeShadowAoeBtn.icon:SetDesaturated(true)
        LichbornePriestMenu.treeShadowAoeBtn = treeShadowAoeBtn


        -- ── Debuff header + buttons ──────────────────────────────────
        local debuffHeader = CreateFrame("Frame", nil, LichbornePriestMenu)
        debuffHeader:SetSize(56, 14)
        debuffHeader:SetPoint("TOPLEFT", aoeHeader, "BOTTOMLEFT", 0, -45)

        debuffHeader:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        debuffHeader:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        debuffHeader:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local debuffLabel = debuffHeader:CreateFontString(nil, "OVERLAY")
        debuffLabel:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        debuffLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        debuffLabel:SetText("Debuff")
        debuffLabel:SetAllPoints()
        debuffLabel:SetJustifyH("CENTER")

        local treeDpsDebuffBtn = CreateFrame("Button", nil, LichbornePriestMenu)
        treeDpsDebuffBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeDpsDebuffBtn:SetPoint("TOPLEFT", debuffHeader, "BOTTOMLEFT", 0, -4)
        local treeDpsDebuffTex = treeDpsDebuffBtn:CreateTexture(nil, "ARTWORK")
        treeDpsDebuffTex:SetAllPoints()
        treeDpsDebuffTex:SetTexture("Interface\\Icons\\Spell_Holy_Restoration")
        treeDpsDebuffBtn.icon = treeDpsDebuffTex
        treeDpsDebuffBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeDpsDebuffBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichbornePriestMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00DPS Debuff|r |cff999999- |r|cffFFFFFFshadow debuff|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Target debuff rotation|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeDpsDebuffBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeDpsDebuffBtn.state = false
        treeDpsDebuffBtn.icon:SetDesaturated(true)
        LichbornePriestMenu.treeDpsDebuffBtn = treeDpsDebuffBtn

        local treeShadowDebuffBtn = CreateFrame("Button", nil, LichbornePriestMenu)
        treeShadowDebuffBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeShadowDebuffBtn:SetPoint("TOPLEFT", treeDpsDebuffBtn, "TOPRIGHT", 4, 0)
        local treeShadowDebuffTex = treeShadowDebuffBtn:CreateTexture(nil, "ARTWORK")
        treeShadowDebuffTex:SetAllPoints()
        treeShadowDebuffTex:SetTexture("Interface\\Icons\\Spell_Shadow_DemonicEmpathy")
        treeShadowDebuffBtn.icon = treeShadowDebuffTex
        treeShadowDebuffBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeShadowDebuffBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichbornePriestMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Shadow Debuff|r |cff999999- |r|cffFFFFFFshadow debuff|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Shadow debuff rotation|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeShadowDebuffBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeShadowDebuffBtn.state = false
        treeShadowDebuffBtn.icon:SetDesaturated(true)
        LichbornePriestMenu.treeShadowDebuffBtn = treeShadowDebuffBtn

        -- ── Assist header + button ───────────────────────────────────
        local assistHeader = CreateFrame("Frame", nil, LichbornePriestMenu)
        assistHeader:SetSize(56, 14)
        assistHeader:SetPoint("TOPLEFT", debuffHeader, "BOTTOMLEFT", 0, -45)
        assistHeader:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        })
        assistHeader:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        assistHeader:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local assistLabel = assistHeader:CreateFontString(nil, "OVERLAY")
        assistLabel:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        assistLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        assistLabel:SetText("Assist")
        assistLabel:SetAllPoints()
        assistLabel:SetJustifyH("CENTER")

        local treeTankAssistBtn = CreateFrame("Button", nil, LichbornePriestMenu)
        treeTankAssistBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeTankAssistBtn:SetPoint("TOPLEFT", assistHeader, "BOTTOMLEFT", 15, -4)
        local treeTankAssistTex = treeTankAssistBtn:CreateTexture(nil, "ARTWORK")
        treeTankAssistTex:SetAllPoints()
        treeTankAssistTex:SetTexture("Interface\\Icons\\inv_shield_02")
        treeTankAssistBtn.icon = treeTankAssistTex
        treeTankAssistBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeTankAssistBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichbornePriestMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Tank Assist|r |cff999999- |r|cffff8000tank assist|r |cffffcc00CO|r")
            GameTooltip:AddLine("|cffffcc00Tank target focus|r", 1, 1, 1)
            GameTooltip:AddLine("Bot attacks the tank's current target.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeTankAssistBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeTankAssistBtn.state = false
        treeTankAssistBtn.icon:SetDesaturated(true)
        LichbornePriestMenu.treeTankAssistBtn = treeTankAssistBtn

        -- ── Left-side Buff header + 2 buttons (below PvP) ─────────
        local BUFF_HDR_W = 56   -- wide enough for 2×26px buttons + 4px gap
        local buffSideHdrBox = CreateFrame("Frame", nil, LichbornePriestMenu)
        buffSideHdrBox:SetSize(BUFF_HDR_W, 18)
        buffSideHdrBox:SetPoint("TOP", LichbornePriestMenu.treePvpBtn, "BOTTOM", 0, -8)
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

        local treeSideBuffBtn = CreateFrame("Button", nil, LichbornePriestMenu)
        treeSideBuffBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeSideBuffBtn:SetPoint("TOPLEFT", buffSideHdrBox, "BOTTOMLEFT", 0, -1)
        local treeSideBuffTex = treeSideBuffBtn:CreateTexture(nil, "ARTWORK")
        treeSideBuffTex:SetAllPoints()
        treeSideBuffTex:SetTexture("Interface\\Icons\\Spell_Holy_WordFortitude")
        treeSideBuffBtn.icon = treeSideBuffTex
        treeSideBuffBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeSideBuffBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichbornePriestMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Buff|r |cff999999- |r|cffffff00buff|r |cffff8000NC|r")
            GameTooltip:AddLine("|cffffcc00Group stat buffs|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFFFFFFPower Word: Fortitude, Divine Spirit,|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFFFFFFShadow Protection|r.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeSideBuffBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeSideBuffBtn.state = false
        treeSideBuffBtn.icon:SetDesaturated(true)
        LichbornePriestMenu.treeSideBuffBtn = treeSideBuffBtn

        local treeSideResBtn = CreateFrame("Button", nil, LichbornePriestMenu)
        treeSideResBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeSideResBtn:SetPoint("TOPLEFT", treeSideBuffBtn, "TOPRIGHT", 4, 0)
        local treeSideResTex = treeSideResBtn:CreateTexture(nil, "ARTWORK")
        treeSideResTex:SetAllPoints()
        treeSideResTex:SetTexture("Interface\\Icons\\Spell_Shadow_AntiShadow")
        treeSideResBtn.icon = treeSideResTex
        treeSideResBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeSideResBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichbornePriestMenu:GetFrameLevel() + 20)
            GameTooltip:ClearLines()
            GameTooltip:SetText("|cffffcc00Shadow Resistance|r |cff999999- |r|cffFFFFFFrshadow|r |cffee4433NC|r")
            GameTooltip:AddLine("|cffffcc00Shadow resistance buff|r", 1, 1, 1)
            GameTooltip:AddLine("Applies |cffFFFFFFShadow Protection|r to the group.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeSideResBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeSideResBtn.state = false
        treeSideResBtn.icon:SetDesaturated(true)
        LichbornePriestMenu.treeSideResBtn = treeSideResBtn

        -- ── Wire Priest class-specific toggle logic ──────────────────
        do
            local function IconOn(btn)
                btn.state = true
                if btn.icon    then btn.icon:SetDesaturated(false)    end
                if btn.subIconR then btn.subIconR:SetDesaturated(false) end
                if btn.subIconL then btn.subIconL:SetDesaturated(false) end
            end
            local function IconOff(btn)
                btn.state = false
                if btn.icon    then btn.icon:SetDesaturated(true)    end
                if btn.subIconR then btn.subIconR:SetDesaturated(true) end
                if btn.subIconL then btn.subIconL:SetDesaturated(true) end
            end

            -- Start all toggleable icons desaturated (OFF)
            IconOff(treeHealBtn); IconOff(treeHolyHealBtn); IconOff(treeHealerDpsBtn); IconOff(treeHolyDpsBtn); IconOff(treeShadowDpsBtn)
            IconOff(treeDpsAoeBtn); IconOff(treeShadowAoeBtn)
            IconOff(treeDpsDebuffBtn); IconOff(treeShadowDebuffBtn)
            IconOff(treeSideBuffBtn); IconOff(treeSideResBtn)
            IconOff(treeTankAssistBtn)

            -- Expose reset so OpenPriestMenu can clear all icons before each query
            local _baseReset = LichbornePriestMenu.resetSharedIcons
            LichbornePriestMenu.resetAllIcons = function()
                if _baseReset then _baseReset() end
                -- class-specific tree buttons only (food/loot/gather handled by base)
                IconOff(treeHealBtn); IconOff(treeHolyHealBtn); IconOff(treeHolyDpsBtn)
                IconOff(treeShadowDpsBtn); IconOff(treeHealerDpsBtn)
                IconOff(treeDpsAoeBtn); IconOff(treeShadowAoeBtn)
                IconOff(treeDpsDebuffBtn); IconOff(treeShadowDebuffBtn)
                IconOff(treeSideBuffBtn); IconOff(treeSideResBtn); IconOff(treeTankAssistBtn)
            end

            -- TREE: Heal (Discipline column)
            treeHealBtn:SetScript("OnClick", function()
                local bot = LichbornePriestMenu.botName or ""
                LichbornePriestMenu._specUserSet = true
                if treeHealBtn.state then
                    PBM.SendToBot("co -heal,?", bot)
                    IconOff(treeHealBtn)
                else
                    PBM.SendToBot("co +heal,?", bot)
                    IconOn(treeHealBtn)
                    IconOff(treeShadowDpsBtn); IconOff(treeHolyHealBtn); IconOff(treeHolyDpsBtn)
                end
            end)

            -- TREE: Holy Heal (Holy column)
            treeHolyHealBtn:SetScript("OnClick", function()
                local bot = LichbornePriestMenu.botName or ""
                LichbornePriestMenu._specUserSet = true
                if treeHolyHealBtn.state then
                    PBM.SendToBot("co -holy heal,?", bot)
                    IconOff(treeHolyHealBtn)
                else
                    PBM.SendToBot("co +holy heal,?", bot)
                    IconOn(treeHolyHealBtn)
                    IconOff(treeShadowDpsBtn); IconOff(treeHealBtn); IconOff(treeHolyDpsBtn)
                end
            end)

            -- TREE: DPS / Shadow (Shadow column)
            treeShadowDpsBtn:SetScript("OnClick", function()
                local bot = LichbornePriestMenu.botName or ""
                LichbornePriestMenu._specUserSet = true
                if treeShadowDpsBtn.state then
                    PBM.SendToBot("co -shadow,?", bot)
                    IconOff(treeShadowDpsBtn)
                else
                    PBM.SendToBot("co +shadow,?", bot)
                    IconOn(treeShadowDpsBtn)
                    IconOff(treeHealBtn); IconOff(treeHolyHealBtn); IconOff(treeHolyDpsBtn)
                end
            end)

            -- TREE: Healer DPS (center button)
            treeHealerDpsBtn:SetScript("OnClick", function()
                local bot = LichbornePriestMenu.botName or ""
                LichbornePriestMenu._specUserSet = true
                if treeHealerDpsBtn.state then
                    PBM.SendToBot("co -healer dps,?", bot)
                    IconOff(treeHealerDpsBtn)
                else
                    PBM.SendToBot("co +healer dps,?", bot)
                    IconOn(treeHealerDpsBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            -- TREE: DPS AoE
            treeDpsAoeBtn:SetScript("OnClick", function()
                local bot = LichbornePriestMenu.botName or ""
                LichbornePriestMenu._specUserSet = true
                if treeDpsAoeBtn.state then
                    PBM.SendToBot("co -shadow aoe,?", bot)
                    IconOff(treeDpsAoeBtn)
                else
                    PBM.SendToBot("co +shadow aoe,?", bot)
                    IconOn(treeDpsAoeBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeHealerDpsBtn)
                end
            end)

            -- TREE: Shadow AoE
            treeShadowAoeBtn:SetScript("OnClick", function()
                local bot = LichbornePriestMenu.botName or ""
                LichbornePriestMenu._specUserSet = true
                if treeShadowAoeBtn.state then
                    PBM.SendToBot("co -shadow aoe,?", bot)
                    IconOff(treeShadowAoeBtn)
                else
                    PBM.SendToBot("co +shadow aoe,?", bot)
                    IconOn(treeShadowAoeBtn)
                end
            end)

            -- TREE: DPS Debuff
            treeDpsDebuffBtn:SetScript("OnClick", function()
                local bot = LichbornePriestMenu.botName or ""
                LichbornePriestMenu._specUserSet = true
                if treeDpsDebuffBtn.state then
                    PBM.SendToBot("co -shadow debuff,?", bot)
                    IconOff(treeDpsDebuffBtn); IconOff(treeShadowDebuffBtn)
                else
                    PBM.SendToBot("co +shadow debuff,?", bot)
                    IconOn(treeDpsDebuffBtn); IconOn(treeShadowDebuffBtn)
                end
            end)

            -- TREE: Shadow Debuff
            treeShadowDebuffBtn:SetScript("OnClick", function()
                local bot = LichbornePriestMenu.botName or ""
                LichbornePriestMenu._specUserSet = true
                if treeShadowDebuffBtn.state then
                    PBM.SendToBot("co -shadow debuff,?", bot)
                    IconOff(treeShadowDebuffBtn); IconOff(treeDpsDebuffBtn)
                else
                    PBM.SendToBot("co +shadow debuff,?", bot)
                    IconOn(treeShadowDebuffBtn); IconOn(treeDpsDebuffBtn)
                end
            end)

            -- LEFT-SIDE: Buff
            treeSideBuffBtn:SetScript("OnClick", function()
                local bot = LichbornePriestMenu.botName or ""
                LichbornePriestMenu._specUserSet = true
                if treeSideBuffBtn.state then
                    PBM.SendToBot("nc -buff,?", bot)
                    IconOff(treeSideBuffBtn)
                else
                    PBM.SendToBot("nc +buff,?", bot)
                    IconOn(treeSideBuffBtn)
                end
            end)

            -- LEFT-SIDE: Shadow Resistance
            treeSideResBtn:SetScript("OnClick", function()
                local bot = LichbornePriestMenu.botName or ""
                LichbornePriestMenu._specUserSet = true
                if treeSideResBtn.state then
                    PBM.SendToBot("nc -rshadow,?", bot)
                    IconOff(treeSideResBtn)
                else
                    PBM.SendToBot("nc +rshadow,?", bot)
                    IconOn(treeSideResBtn)
                end
            end)

            -- TREE: Tank Assist
            treeTankAssistBtn:SetScript("OnClick", function()
                local bot = LichbornePriestMenu.botName or ""
                LichbornePriestMenu._specUserSet = true
                if treeTankAssistBtn.state then
                    PBM.SendToBot("co -tank assist,?", bot)
                    IconOff(treeTankAssistBtn)
                else
                    PBM.SendToBot("co +tank assist,?", bot)
                    IconOn(treeTankAssistBtn)
                    IconOff(treeHealerDpsBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            -- TREE: Holy DPS (DPS column)
            treeHolyDpsBtn:SetScript("OnClick", function()
                local bot = LichbornePriestMenu.botName or ""
                LichbornePriestMenu._specUserSet = true
                if treeHolyDpsBtn.state then
                    PBM.SendToBot("co -holy dps,?", bot)
                    IconOff(treeHolyDpsBtn)
                else
                    PBM.SendToBot("co +holy dps,?", bot)
                    IconOn(treeHolyDpsBtn)
                    IconOff(treeHealBtn); IconOff(treeHolyHealBtn); IconOff(treeShadowDpsBtn)
                end
            end)

            -- ── State restore from co?/nc? query ─────────────────────
            -- Wrap the strat-list callback so arriving strategy data also
            -- syncs icon visual states.  Shadow and shadow debuff each
            -- appear on two buttons simultaneously.
            -- Role/strategy buttons: sync only on initial menu load (MultiBot pattern).
            -- _specUserSet = true after any click; flag blocks reply-driven re-sync.
            local _baseSU = LichbornePriestMenu.onStrategyUpdate
            LichbornePriestMenu.onStrategyUpdate = function(stratType, activeSet)
                if _baseSU then _baseSU(stratType, activeSet) end
                if not LichbornePriestMenu._specUserSet then
                    if stratType == "co" then
                        if activeSet["heal"]        then IconOn(treeHealBtn)        else IconOff(treeHealBtn)        end
                        if activeSet["holy heal"]   then IconOn(treeHolyHealBtn)    else IconOff(treeHolyHealBtn)    end
                        if activeSet["holy dps"]    then IconOn(treeHolyDpsBtn)     else IconOff(treeHolyDpsBtn)     end
                        if activeSet["shadow"]      then IconOn(treeShadowDpsBtn)   else IconOff(treeShadowDpsBtn)   end
                        if activeSet["healer dps"]  then IconOn(treeHealerDpsBtn)   else IconOff(treeHealerDpsBtn)   end
                        if activeSet["tank assist"] then IconOn(treeTankAssistBtn)  else IconOff(treeTankAssistBtn)  end
                        if activeSet["shadow aoe"]  then IconOn(treeDpsAoeBtn)      else IconOff(treeDpsAoeBtn)      end
                        if activeSet["shadow aoe"]  then IconOn(treeShadowAoeBtn)   else IconOff(treeShadowAoeBtn)   end
                        if activeSet["shadow debuff"] then IconOn(treeDpsDebuffBtn); IconOn(treeShadowDebuffBtn)
                        else IconOff(treeDpsDebuffBtn); IconOff(treeShadowDebuffBtn) end
                    elseif stratType == "nc" then
                        if activeSet["buff"]    then IconOn(treeSideBuffBtn)  else IconOff(treeSideBuffBtn)  end
                        if activeSet["rshadow"] then IconOn(treeSideResBtn)   else IconOff(treeSideResBtn)   end
                    end
                end
            end
        end -- end toggle wire block
    end

    if LichbornePriestMenu:IsShown() and LichbornePriestMenu.sourceRow == row then
        HideAllPriest(); return
    end
    PBM.ShowCharSheet(LichbornePriestMenu, LichbornePriestCatcher, row, PRIEST_LEFT_EXT)
end
