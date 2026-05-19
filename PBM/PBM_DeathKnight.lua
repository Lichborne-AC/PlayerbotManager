PBM = PBM or {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Death Knight class-specific overlay panel
-- ─────────────────────────────────────────────────────────────────────────────

local function PBM_TimerAfter(delay, func)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, func)
    else
        local elapsed = 0
        local f = CreateFrame("Frame")
        f:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= delay then
                self:SetScript("OnUpdate", nil)
                func()
            end
        end)
    end
end

local DK_TALENT_SPECS = {
    { label="Blood |cffffcc00PvE|r",  spec="blood pve",  wowSpec="Blood",    icon="Interface\\Icons\\Spell_DeathKnight_BloodPresence"  },
    { label="Frost |cffffcc00PvE|r",  spec="frost pve",  wowSpec="Frost DK", icon="Interface\\Icons\\Spell_DeathKnight_FrostPresence"  },
    { label="Unholy |cffffcc00PvE|r", spec="unholy pve", wowSpec="Unholy",   icon="Interface\\Icons\\Spell_DeathKnight_UnholyPresence" },
    { label="Blood |cffff4444PvP|r",  spec="blood pvp",  wowSpec="Blood",    icon="Interface\\Icons\\Spell_DeathKnight_BloodPresence"  },
    { label="Frost |cffff4444PvP|r",  spec="frost pvp",  wowSpec="Frost DK", icon="Interface\\Icons\\Spell_DeathKnight_FrostPresence"  },
    { label="Unholy |cffff4444PvP|r", spec="unholy pvp", wowSpec="Unholy",   icon="Interface\\Icons\\Spell_DeathKnight_UnholyPresence" },
}

local LichborneDKMenu
local LichborneDKCatcher

local DK_LEFT_EXT = 5
local DK_OVL_W = (PBM.GEAR_OFF + PBM.GEAR_SLOTS * PBM.COL_GEAR_W) - PBM.GS_OFF + DK_LEFT_EXT
local DK_OVL_H = PBM.MAX_ROWS * PBM.ROW_HEIGHT + 12

local EXT_ICON_SIZE = 26

local function HideAllDK()
    PBM.HideCharSheet(LichborneDKMenu, LichborneDKCatcher)
end

function PBM.CloseDKMenu()
    HideAllDK()
end

function PBM.OpenDKMenu(row)
    if not LichborneDKMenu then
        LichborneDKMenu, LichborneDKCatcher = PBM.CreateCharSheet({
            menuName    = "LichborneDKMenu",
            catcherName = "LichborneDKCatcher",
            className   = "Death Knight",
            classHex    = "C41F3B",
            leftExt     = DK_LEFT_EXT,
            overlayW    = DK_OVL_W,
            overlayH    = DK_OVL_H,
            talentSpecs = DK_TALENT_SPECS,
            hideCallback = HideAllDK,
        })

        -- ── Spec tree columns (Blood / Frost / Unholy) ──────────────
        local TREE_TOTAL_W = 3 * 70 + 2 * 4
        local TREE_X       = math.floor((DK_OVL_W - TREE_TOTAL_W) / 2)
        local HDR_H        = PBM.ROW_HEIGHT
        local TREE_TOP_Y   = -(HDR_H + 68)

        local SPEC_BOX_BD = {
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        }

        -- Blood column
        local bloodSpecBox = CreateFrame("Frame", nil, LichborneDKMenu)
        bloodSpecBox:SetSize(70, 18)
        bloodSpecBox:SetPoint("TOPLEFT", LichborneDKMenu, "TOPLEFT", TREE_X, TREE_TOP_Y - 16)
        bloodSpecBox:SetBackdrop(SPEC_BOX_BD)
        bloodSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        bloodSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local bloodBoxIcon = bloodSpecBox:CreateTexture(nil, "ARTWORK")
        bloodBoxIcon:SetSize(14, 14)
        bloodBoxIcon:SetPoint("LEFT", bloodSpecBox, "LEFT", 2, 0)
        bloodBoxIcon:SetTexture("Interface\\Icons\\Spell_DeathKnight_BloodPresence")
        local bloodSpecLabel = bloodSpecBox:CreateFontString(nil, "OVERLAY")
        bloodSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        bloodSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        bloodSpecLabel:SetText("Blood")
        bloodSpecLabel:SetPoint("LEFT", bloodSpecBox, "LEFT", 18, 0)
        bloodSpecLabel:SetPoint("RIGHT", bloodSpecBox, "RIGHT", -2, 0)
        bloodSpecLabel:SetJustifyH("CENTER")

        local treeBloodBtn = CreateFrame("Button", nil, LichborneDKMenu)
        treeBloodBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeBloodBtn:SetPoint("TOPLEFT", bloodSpecBox, "BOTTOMLEFT", 22, -4)
        local treeBloodTex = treeBloodBtn:CreateTexture(nil, "ARTWORK")
        treeBloodTex:SetAllPoints()
        treeBloodTex:SetTexture("Interface\\Icons\\Spell_DeathKnight_BloodPresence")
        treeBloodBtn.icon = treeBloodTex
        treeBloodBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeBloodBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDKMenu:GetFrameLevel() + 20)
            GameTooltip:SetText("|cffffcc00Blood|r |cff999999- |r|cffC41F3Bblood|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Blood tank specialization|r", 1, 1, 1)
            GameTooltip:AddLine("Activates |cffffcc00Frost Presence|r and tank rotation.", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BDeath Strike|r self-heals from damage taken.", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BHeart Strike|r and |cffC41F3BBone Shield|r for threat.", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BDeath Grip|r taunts and repositions targets.", 1, 1, 1)
            GameTooltip:AddLine("|cffffcc00Defensive CDs:|r |cffC41F3BVampiric Blood,|r", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BIcebound Fortitude, Army of the Dead.|r", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Frost, Unholy.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeBloodBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeBloodBtn.state = false
        treeBloodBtn.icon:SetDesaturated(true)
        LichborneDKMenu.treeBloodBtn = treeBloodBtn

        -- Frost column
        local frostSpecBox = CreateFrame("Frame", nil, LichborneDKMenu)
        frostSpecBox:SetSize(70, 18)
        frostSpecBox:SetPoint("TOPLEFT", bloodSpecBox, "TOPRIGHT", 4, 0)
        frostSpecBox:SetBackdrop(SPEC_BOX_BD)
        frostSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        frostSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local frostBoxIcon = frostSpecBox:CreateTexture(nil, "ARTWORK")
        frostBoxIcon:SetSize(14, 14)
        frostBoxIcon:SetPoint("LEFT", frostSpecBox, "LEFT", 2, 0)
        frostBoxIcon:SetTexture("Interface\\Icons\\Spell_DeathKnight_FrostPresence")
        local frostSpecLabel = frostSpecBox:CreateFontString(nil, "OVERLAY")
        frostSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        frostSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        frostSpecLabel:SetText("Frost")
        frostSpecLabel:SetPoint("LEFT", frostSpecBox, "LEFT", 18, 0)
        frostSpecLabel:SetPoint("RIGHT", frostSpecBox, "RIGHT", -2, 0)
        frostSpecLabel:SetJustifyH("CENTER")

        local treeFrostBtn = CreateFrame("Button", nil, LichborneDKMenu)
        treeFrostBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeFrostBtn:SetPoint("TOPLEFT", frostSpecBox, "BOTTOMLEFT", 22, -4)
        local treeFrostTex = treeFrostBtn:CreateTexture(nil, "ARTWORK")
        treeFrostTex:SetAllPoints()
        treeFrostTex:SetTexture("Interface\\Icons\\Spell_DeathKnight_FrostPresence")
        treeFrostBtn.icon = treeFrostTex
        treeFrostBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeFrostBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDKMenu:GetFrameLevel() + 20)
            GameTooltip:SetText("|cffffcc00Frost|r |cff999999- |r|cffC41F3Bfrost|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Frost DPS specialization|r", 1, 1, 1)
            GameTooltip:AddLine("Activates |cffffcc00Blood Presence|r and DPS rotation.", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BObliterate|r is the primary rune spender.", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BHowling Blast|r on |cffffcc00Rime|r procs.", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BFrost Strike|r on |cffffcc00Killing Machine|r procs.", 1, 1, 1)
            GameTooltip:AddLine("|cffffcc00Major CD:|r |cffC41F3BUnbreakable Armor|r.", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Blood, Unholy.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeFrostBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeFrostBtn.state = false
        treeFrostBtn.icon:SetDesaturated(true)
        LichborneDKMenu.treeFrostBtn = treeFrostBtn

        -- Unholy column
        local unholySpecBox = CreateFrame("Frame", nil, LichborneDKMenu)
        unholySpecBox:SetSize(70, 18)
        unholySpecBox:SetPoint("TOPLEFT", frostSpecBox, "TOPRIGHT", 4, 0)
        unholySpecBox:SetBackdrop(SPEC_BOX_BD)
        unholySpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        unholySpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local unholyBoxIcon = unholySpecBox:CreateTexture(nil, "ARTWORK")
        unholyBoxIcon:SetSize(14, 14)
        unholyBoxIcon:SetPoint("LEFT", unholySpecBox, "LEFT", 2, 0)
        unholyBoxIcon:SetTexture("Interface\\Icons\\Spell_DeathKnight_UnholyPresence")
        local unholySpecLabel = unholySpecBox:CreateFontString(nil, "OVERLAY")
        unholySpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        unholySpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        unholySpecLabel:SetText("Unholy")
        unholySpecLabel:SetPoint("LEFT", unholySpecBox, "LEFT", 18, 0)
        unholySpecLabel:SetPoint("RIGHT", unholySpecBox, "RIGHT", -2, 0)
        unholySpecLabel:SetJustifyH("CENTER")

        local treeUnholyBtn = CreateFrame("Button", nil, LichborneDKMenu)
        treeUnholyBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeUnholyBtn:SetPoint("TOPLEFT", unholySpecBox, "BOTTOMLEFT", 22, -4)
        local treeUnholyTex = treeUnholyBtn:CreateTexture(nil, "ARTWORK")
        treeUnholyTex:SetAllPoints()
        treeUnholyTex:SetTexture("Interface\\Icons\\Spell_DeathKnight_UnholyPresence")
        treeUnholyBtn.icon = treeUnholyTex
        treeUnholyBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeUnholyBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDKMenu:GetFrameLevel() + 20)
            GameTooltip:SetText("|cffffcc00Unholy|r |cff999999- |r|cffC41F3Bunholy|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Unholy DPS specialization|r", 1, 1, 1)
            GameTooltip:AddLine("Activates |cffffcc00Blood Presence|r and DPS rotation.", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BScourge Strike|r is the core damage ability.", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BDeath Coil|r dumps |cffffcc00runic power|r and", 1, 1, 1)
            GameTooltip:AddLine("builds |cffffcc00Ghoul Power|r stacks.", 1, 1, 1)
            GameTooltip:AddLine("Permanent |cffC41F3BRaise Dead|r ghoul companion.", 1, 1, 1)
            GameTooltip:AddLine("|cffffcc00Major CD:|r |cffC41F3BSummon Gargoyle|r.", 1, 1, 1)
            GameTooltip:AddLine("|cffFF4444Mutually exclusive with Blood, Frost.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeUnholyBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeUnholyBtn.state = false
        treeUnholyBtn.icon:SetDesaturated(true)
        LichborneDKMenu.treeUnholyBtn = treeUnholyBtn

        -- ── AoE column (below spec tree row) ────────────────────────
        local aoeSpecBox = CreateFrame("Frame", nil, LichborneDKMenu)
        aoeSpecBox:SetSize(86, 18)
        aoeSpecBox:SetPoint("TOP", treeFrostBtn, "BOTTOM", 0, -15)
        aoeSpecBox:SetBackdrop(SPEC_BOX_BD)
        aoeSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        aoeSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local aoeSpecLabel = aoeSpecBox:CreateFontString(nil, "OVERLAY")
        aoeSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        aoeSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        aoeSpecLabel:SetText("AoE")
        aoeSpecLabel:SetAllPoints()
        aoeSpecLabel:SetJustifyH("CENTER")

        local treeAoeFrostBtn = CreateFrame("Button", nil, LichborneDKMenu)
        treeAoeFrostBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeAoeFrostBtn:SetPoint("TOPLEFT", aoeSpecBox, "BOTTOMLEFT", 0, -4)
        local treeAoeFrostTex = treeAoeFrostBtn:CreateTexture(nil, "ARTWORK")
        treeAoeFrostTex:SetAllPoints()
        treeAoeFrostTex:SetTexture("Interface\\Icons\\Spell_Frost_FrostBolt02")
        treeAoeFrostBtn.icon = treeAoeFrostTex
        treeAoeFrostBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeAoeFrostBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDKMenu:GetFrameLevel() + 20)
            GameTooltip:SetText("|cffffcc00Frost AoE|r |cff999999- |r|cffC41F3Bfrost aoe|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Frost AoE rotation|r", 1, 1, 1)
            GameTooltip:AddLine("Enables |cffffcc00Frost|r-specific AoE mode.", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BHowling Blast|r hits all nearby targets.", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BDeath and Decay, Pestilence,|r", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BBlood Boil|r amplified by diseases.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeAoeFrostBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeAoeFrostBtn.state = false
        treeAoeFrostBtn.icon:SetDesaturated(true)
        LichborneDKMenu.treeAoeFrostBtn = treeAoeFrostBtn

        local treeAoeUnholyBtn = CreateFrame("Button", nil, LichborneDKMenu)
        treeAoeUnholyBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeAoeUnholyBtn:SetPoint("TOPLEFT", treeAoeFrostBtn, "TOPRIGHT", 4, 0)
        local treeAoeUnholyTex = treeAoeUnholyBtn:CreateTexture(nil, "ARTWORK")
        treeAoeUnholyTex:SetAllPoints()
        treeAoeUnholyTex:SetTexture("Interface\\Icons\\Spell_Fire_FelFlameRing")
        treeAoeUnholyBtn.icon = treeAoeUnholyTex
        treeAoeUnholyBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeAoeUnholyBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDKMenu:GetFrameLevel() + 20)
            GameTooltip:SetText("|cffffcc00Unholy AoE|r |cff999999- |r|cffC41F3Bunholy aoe|r |cffee4433CO|r")
            GameTooltip:AddLine("|cffffcc00Unholy AoE rotation|r", 1, 1, 1)
            GameTooltip:AddLine("Enables |cffffcc00Unholy|r-specific AoE mode.", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BDeath and Decay, Corpse Explosion.|r", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BPestilence, Blood Boil|r via base.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeAoeUnholyBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeAoeUnholyBtn.state = false
        treeAoeUnholyBtn.icon:SetDesaturated(true)
        LichborneDKMenu.treeAoeUnholyBtn = treeAoeUnholyBtn

        -- ── Assist column (below AoE row) ────────────────────────────
        local assistSpecBox = CreateFrame("Frame", nil, LichborneDKMenu)
        assistSpecBox:SetSize(56, 18)
        assistSpecBox:SetPoint("TOP", aoeSpecBox, "BOTTOM", 0, -45)
        assistSpecBox:SetBackdrop(SPEC_BOX_BD)
        assistSpecBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        assistSpecBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local assistSpecLabel = assistSpecBox:CreateFontString(nil, "OVERLAY")
        assistSpecLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        assistSpecLabel:SetTextColor(0.78, 0.61, 0.23, 1)
        assistSpecLabel:SetText("Assist")
        assistSpecLabel:SetAllPoints()
        assistSpecLabel:SetJustifyH("CENTER")

        local treeTankAssistBtn = CreateFrame("Button", nil, LichborneDKMenu)
        treeTankAssistBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeTankAssistBtn:SetPoint("TOPLEFT", assistSpecBox, "BOTTOMLEFT", 0, -4)
        local treeTankAssistTex = treeTankAssistBtn:CreateTexture(nil, "ARTWORK")
        treeTankAssistTex:SetAllPoints()
        treeTankAssistTex:SetTexture("Interface\\Icons\\inv_shield_02")
        treeTankAssistBtn.icon = treeTankAssistTex
        treeTankAssistBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeTankAssistBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDKMenu:GetFrameLevel() + 20)
            GameTooltip:SetText("|cffffcc00Tank Assist|r |cff999999- |r|cffff8000tank assist|r |cffffcc00CO|r")
            GameTooltip:AddLine("|cffffcc00Tank target focus|r", 1, 1, 1)
            GameTooltip:AddLine("Bot attacks the tank's current target.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeTankAssistBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeTankAssistBtn.state = false
        treeTankAssistBtn.icon:SetDesaturated(true)
        LichborneDKMenu.treeTankAssistBtn = treeTankAssistBtn

        local treeDpsAssistBtn = CreateFrame("Button", nil, LichborneDKMenu)
        treeDpsAssistBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeDpsAssistBtn:SetPoint("TOPLEFT", treeTankAssistBtn, "TOPRIGHT", 4, 0)
        local treeDpsAssistTex = treeDpsAssistBtn:CreateTexture(nil, "ARTWORK")
        treeDpsAssistTex:SetAllPoints()
        treeDpsAssistTex:SetTexture("Interface\\Icons\\Ability_Warrior_Challange")
        treeDpsAssistBtn.icon = treeDpsAssistTex
        treeDpsAssistBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeDpsAssistBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDKMenu:GetFrameLevel() + 20)
            GameTooltip:SetText("|cffffcc00DPS Assist|r |cff999999- |r|cffff8000dps assist|r |cffffcc00CO|r")
            GameTooltip:AddLine("|cffffcc00Assists the main assist target|r", 1, 1, 1)
            GameTooltip:AddLine("Bot focuses DPS on the DPS assist target.", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeDpsAssistBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeDpsAssistBtn.state = false
        treeDpsAssistBtn.icon:SetDesaturated(true)
        LichborneDKMenu.treeDpsAssistBtn = treeDpsAssistBtn

        local treeDpsAoeBtn = CreateFrame("Button", nil, LichborneDKMenu)
        treeDpsAoeBtn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
        treeDpsAoeBtn:SetPoint("TOPLEFT", treeAoeUnholyBtn, "TOPRIGHT", 4, 0)
        local treeDpsAoeTex = treeDpsAoeBtn:CreateTexture(nil, "ARTWORK")
        treeDpsAoeTex:SetAllPoints()
        treeDpsAoeTex:SetTexture("Interface\\Icons\\Spell_Shadow_RainOfFire")
        treeDpsAoeBtn.icon = treeDpsAoeTex
        treeDpsAoeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        treeDpsAoeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichborneDKMenu:GetFrameLevel() + 20)
            GameTooltip:SetText("|cffffcc00DPS AoE|r |cff999999- |r|cffff8000dps aoe|r |cffffcc00CO|r")
            GameTooltip:AddLine("|cffffcc00Cross-role AoE mode|r", 1, 1, 1)
            GameTooltip:AddLine("Spec-agnostic AoE. Works with any presence.", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BDeath and Decay, Pestilence,|r", 1, 1, 1)
            GameTooltip:AddLine("|cffC41F3BBlood Boil.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        treeDpsAoeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        treeDpsAoeBtn.state = false
        treeDpsAoeBtn.icon:SetDesaturated(true)
        LichborneDKMenu.treeDpsAoeBtn = treeDpsAoeBtn

        -- ── Wire Death Knight class-specific toggle logic ─────────────
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
            IconOff(treeBloodBtn); IconOff(treeFrostBtn); IconOff(treeUnholyBtn)
            IconOff(treeAoeFrostBtn); IconOff(treeAoeUnholyBtn)
            IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)

            local _baseReset = LichborneDKMenu.resetSharedIcons
            LichborneDKMenu.resetAllIcons = function()
                if _baseReset then _baseReset() end
                IconOff(treeBloodBtn); IconOff(treeFrostBtn); IconOff(treeUnholyBtn)
                IconOff(treeAoeFrostBtn); IconOff(treeAoeUnholyBtn)
                IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
            end

            -- TREE BLOOD
            treeBloodBtn:SetScript("OnClick", function()
                local bot = LichborneDKMenu.botName or ""
                LichborneDKMenu._specUserSet = true
                if treeBloodBtn.state then
                    PBM.SendToBot("co -blood,?", bot)
                    IconOff(treeBloodBtn)
                else
                    PBM.SendToBot("co +blood,?", bot)
                    IconOn(treeBloodBtn)
                    IconOff(treeFrostBtn); IconOff(treeUnholyBtn)
                end
            end)

            -- TREE FROST
            treeFrostBtn:SetScript("OnClick", function()
                local bot = LichborneDKMenu.botName or ""
                LichborneDKMenu._specUserSet = true
                if treeFrostBtn.state then
                    PBM.SendToBot("co -frost,?", bot)
                    IconOff(treeFrostBtn)
                else
                    PBM.SendToBot("co +frost,?", bot)
                    IconOn(treeFrostBtn)
                    IconOff(treeBloodBtn); IconOff(treeUnholyBtn)
                end
            end)

            -- TREE UNHOLY
            treeUnholyBtn:SetScript("OnClick", function()
                local bot = LichborneDKMenu.botName or ""
                LichborneDKMenu._specUserSet = true
                if treeUnholyBtn.state then
                    PBM.SendToBot("co -unholy,?", bot)
                    IconOff(treeUnholyBtn)
                else
                    PBM.SendToBot("co +unholy,?", bot)
                    IconOn(treeUnholyBtn)
                    IconOff(treeBloodBtn); IconOff(treeFrostBtn)
                end
            end)

            -- TREE AOE FROST
            treeAoeFrostBtn:SetScript("OnClick", function()
                local bot = LichborneDKMenu.botName or ""
                LichborneDKMenu._specUserSet = true
                if treeAoeFrostBtn.state then
                    PBM.SendToBot("co -frost aoe,?", bot)
                    IconOff(treeAoeFrostBtn)
                else
                    PBM.SendToBot("co +frost aoe,?", bot)
                    IconOn(treeAoeFrostBtn)
                    IconOff(treeAoeUnholyBtn)
                end
            end)

            -- TREE AOE UNHOLY
            treeAoeUnholyBtn:SetScript("OnClick", function()
                local bot = LichborneDKMenu.botName or ""
                LichborneDKMenu._specUserSet = true
                if treeAoeUnholyBtn.state then
                    PBM.SendToBot("co -unholy aoe,?", bot)
                    IconOff(treeAoeUnholyBtn)
                else
                    PBM.SendToBot("co +unholy aoe,?", bot)
                    IconOn(treeAoeUnholyBtn)
                    IconOff(treeAoeFrostBtn)
                end
            end)

            -- TREE TANK ASSIST
            treeTankAssistBtn:SetScript("OnClick", function()
                local bot = LichborneDKMenu.botName or ""
                LichborneDKMenu._specUserSet = true
                if treeTankAssistBtn.state then
                    PBM.SendToBot("co -tank assist,?", bot)
                    IconOff(treeTankAssistBtn)
                else
                    PBM.SendToBot("co +tank assist,?", bot)
                    IconOn(treeTankAssistBtn)
                    IconOff(treeDpsAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            -- TREE DPS ASSIST
            treeDpsAssistBtn:SetScript("OnClick", function()
                local bot = LichborneDKMenu.botName or ""
                LichborneDKMenu._specUserSet = true
                if treeDpsAssistBtn.state then
                    PBM.SendToBot("co -dps assist,?", bot)
                    IconOff(treeDpsAssistBtn)
                else
                    PBM.SendToBot("co +dps assist,?", bot)
                    IconOn(treeDpsAssistBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAoeBtn)
                end
            end)

            -- TREE DPS AOE
            treeDpsAoeBtn:SetScript("OnClick", function()
                local bot = LichborneDKMenu.botName or ""
                LichborneDKMenu._specUserSet = true
                if treeDpsAoeBtn.state then
                    PBM.SendToBot("co -dps aoe,?", bot)
                    IconOff(treeDpsAoeBtn)
                else
                    PBM.SendToBot("co +dps aoe,?", bot)
                    IconOn(treeDpsAoeBtn)
                    IconOff(treeTankAssistBtn); IconOff(treeDpsAssistBtn)
                end
            end)

            -- ── State restore from co? query ──────────────────────────
            local _baseSU = LichborneDKMenu.onStrategyUpdate
            LichborneDKMenu.onStrategyUpdate = function(stratType, activeSet)
                if _baseSU then _baseSU(stratType, activeSet) end
                if not LichborneDKMenu._specUserSet then
                    if stratType == "co" then
                        if activeSet["blood"]       then IconOn(treeBloodBtn)      else IconOff(treeBloodBtn)      end
                        if activeSet["frost"]       then IconOn(treeFrostBtn)      else IconOff(treeFrostBtn)      end
                        if activeSet["unholy"]      then IconOn(treeUnholyBtn)     else IconOff(treeUnholyBtn)     end
                        if activeSet["frost aoe"]   then IconOn(treeAoeFrostBtn)   else IconOff(treeAoeFrostBtn)   end
                        if activeSet["unholy aoe"]  then IconOn(treeAoeUnholyBtn)  else IconOff(treeAoeUnholyBtn)  end
                        if activeSet["tank assist"] then IconOn(treeTankAssistBtn) else IconOff(treeTankAssistBtn) end
                        if activeSet["dps assist"]  then IconOn(treeDpsAssistBtn)  else IconOff(treeDpsAssistBtn)  end
                        if activeSet["dps aoe"]     then IconOn(treeDpsAoeBtn)     else IconOff(treeDpsAoeBtn)     end
                    end
                end
            end
        end -- end toggle wire block
    end

    if LichborneDKMenu:IsShown() and LichborneDKMenu.sourceRow == row then
        HideAllDK(); return
    end
    PBM.ShowCharSheet(LichborneDKMenu, LichborneDKCatcher, row, DK_LEFT_EXT)
end
