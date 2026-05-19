-- ============================================================
--  PBM_BotSettings.lua  |  Bot Settings tab (Admin panel)
-- ============================================================
PBM = PBM or {}
PBM.State = PBM.State or {}

local BSET_W  = 1086
local BSET_H  = 512
local PERI_R, PERI_G, PERI_B = 0.467, 0.600, 1.000   -- #7799ff

-- ── Layout helpers ───────────────────────────────────────────
local ICON_SZ  = 32   -- icon button size
local ICON_GAP = 6    -- gap between icons
local STEP     = ICON_SZ + ICON_GAP   -- 38px per slot

local ADDON_PATH = "Interface\\AddOns\\PlayerBotManager\\Icons\\"
local ICON_PATH  = "Interface\\Icons\\"

-- ── Section label ────────────────────────────────────────────
local function MakeLabel(parent, text, x, y, fl)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    fs:SetText("|cff7799ff" .. text .. "|r")
    return fs
end

-- ── Divider line ─────────────────────────────────────────────
local function MakeDivider(parent, x, y, w, fl)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    t:SetSize(w, 1)
    t:SetTexture(PERI_R, PERI_G, PERI_B, 0.35)
    return t
end

-- ── Icon button factory ───────────────────────────────────────
local function MakeIconBtn(parent, x, y, iconPath, tipTitle, tipBody, fl)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(ICON_SZ, ICON_SZ)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    btn:SetFrameLevel(fl)

    local border = btn:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetAlpha(0.5)

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT",     btn, "TOPLEFT",     2, -2)
    tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2,  2)
    tex:SetTexture(iconPath)
    btn.icon = tex

    btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    btn.state = false
    function btn:setOn()
        self.icon:SetDesaturated(nil)
        self.state = true
    end
    function btn:setOff()
        self.icon:SetDesaturated(1)
        self.state = false
    end

    if tipTitle then
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(tipTitle, 0.78, 0.61, 0.23)
            if tipBody then GameTooltip:AddLine(tipBody, 1, 1, 1, true) end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return btn
end

-- ── Toggle helper ────────────────────────────────────────────
local function WireToggle(btn, onFn, offFn)
    btn:setOff()
    btn:SetScript("OnClick", function(self)
        if self.state then
            offFn()
            self:setOff()
        else
            onFn()
            self:setOn()
        end
    end)
end

-- ============================================================
function PBM.BuildBotSettingsFrame(parent, fl)
    if PBM.State.botSettingsFrameBuilt then return end
    PBM.State.botSettingsFrameBuilt = true

    local f = CreateFrame("Frame", "LichborneBotSettingsFrame", parent)
    PBM.State.LichborneBotSettingsFrame = f
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -66)
    f:SetSize(BSET_W, BSET_H)
    f:SetFrameLevel(fl + 10)
    f:Hide()

    -- Content background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetTexture(0.04, 0.05, 0.12, 1)

    -- Header bar
    local hdr = CreateFrame("Frame", nil, f)
    hdr:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    hdr:SetSize(BSET_W, 24)
    hdr:SetFrameLevel(fl + 11)
    local hdrBg = hdr:CreateTexture(nil, "BACKGROUND")
    hdrBg:SetAllPoints(hdr)
    hdrBg:SetTexture(PERI_R * 0.18, PERI_G * 0.18, PERI_B * 0.18, 1)
    local hdrBorder = hdr:CreateTexture(nil, "BORDER")
    hdrBorder:SetPoint("BOTTOMLEFT",  hdr, "BOTTOMLEFT",  0, 0)
    hdrBorder:SetPoint("BOTTOMRIGHT", hdr, "BOTTOMRIGHT", 0, 0)
    hdrBorder:SetHeight(2)
    hdrBorder:SetTexture(PERI_R, PERI_G, PERI_B, 0.6)
    local hdrTitle = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdrTitle:SetPoint("TOPLEFT",  hdr, "TOPLEFT",  0, 0)
    hdrTitle:SetPoint("TOPRIGHT", hdr, "TOPRIGHT", 0, 0)
    hdrTitle:SetHeight(24)
    hdrTitle:SetJustifyH("CENTER"); hdrTitle:SetJustifyV("MIDDLE")
    hdrTitle:SetText("|cff7799ffBot Settings|r")

    local BL = fl + 12   -- base frame level for content
    local ROW_START = 52   -- top padding below header

    -- ============================================================
    --  COLUMN 1 – ADD RNDBOT  (x=35)
    -- ============================================================
    local COL1_X = 35

    MakeLabel(f, "Add RndBot", COL1_X, ROW_START, BL)
    MakeDivider(f, COL1_X, ROW_START + 16, 220, BL)

    local CLASS_DEFS = {
        { name = "Death Knight", cmd = "dk",      icon = ADDON_PATH .. "addclass_deathknight.blp" },
        { name = "Druid",        cmd = "druid",   icon = ADDON_PATH .. "addclass_druid.blp"       },
        { name = "Hunter",       cmd = "hunter",  icon = ADDON_PATH .. "addclass_hunter.blp"      },
        { name = "Mage",         cmd = "mage",    icon = ADDON_PATH .. "addclass_mage.blp"        },
        { name = "Paladin",      cmd = "paladin", icon = ADDON_PATH .. "addclass_paladin.blp"     },
        { name = "Priest",       cmd = "priest",  icon = ADDON_PATH .. "addclass_priest.blp"      },
        { name = "Rogue",        cmd = "rogue",   icon = ADDON_PATH .. "addclass_rogue.blp"       },
        { name = "Shaman",       cmd = "shaman",  icon = ADDON_PATH .. "addclass_shaman.blp"      },
        { name = "Warlock",      cmd = "warlock", icon = ADDON_PATH .. "addclass_warlock.blp"     },
        { name = "Warrior",      cmd = "warrior", icon = ADDON_PATH .. "addclass_warrior.blp"     },
    }

    local classRowY = ROW_START + 24

    for _, cd in ipairs(CLASS_DEFS) do
        local classBtn = MakeIconBtn(f, COL1_X, classRowY,
            cd.icon,
            cd.name,
            "Summon a random " .. cd.name .. " RndBot.", BL)

        local capturedCmd = cd.cmd
        classBtn:SetScript("OnClick", function()
            SendChatMessage(".playerbots bot addclass " .. capturedCmd, "SAY")
        end)

        local cLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cLabel:SetPoint("LEFT", classBtn, "RIGHT", 6, 0)
        cLabel:SetText("|cffcccccc" .. cd.name .. "|r")

        classRowY = classRowY + STEP
    end

    -- ============================================================
    --  COLUMN 2 – BOT CONTROLS  (x=296)
    -- ============================================================
    local COL2_X = 296

    MakeLabel(f, "Bot Controls", COL2_X, ROW_START, BL)
    MakeDivider(f, COL2_X, ROW_START + 16, 220, BL)

    local rowY = ROW_START + 24

    -- ── Selfbot ──────────────────────────────────────────────
    local selfbotBtn = MakeIconBtn(f, COL2_X, rowY,
        ICON_PATH .. "inv_misc_head_clockworkgnome_01",
        "Selfbot",
        "Switches Selfbot mode on and off.\nLeft-click to toggle.", BL)
    WireToggle(selfbotBtn,
        function() PBM.ActionToGroup("selfbot on")  end,
        function() PBM.ActionToGroup("selfbot off") end)

    local selfLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    selfLabel:SetPoint("LEFT", selfbotBtn, "RIGHT", 6, 0)
    selfLabel:SetText("|cffccccccSelfbot|r")

    rowY = rowY + STEP

    -- ── GameMaster Toggle ─────────────────────────────────────
    local gmBtn = MakeIconBtn(f, COL2_X, rowY,
        ICON_PATH .. "mail_gmicon",
        "GameMaster Switch",
        "Enable or disable GameMaster control.\nRequires GM rights.", BL)
    WireToggle(gmBtn,
        function() PBM.ActionToGroup("gm on")  end,
        function() PBM.ActionToGroup("gm off") end)

    local gmLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    gmLabel:SetPoint("LEFT", gmBtn, "RIGHT", 6, 0)
    gmLabel:SetText("|cffccccccGameMaster|r")

    rowY = rowY + STEP

    -- ── RTSC Toggle ───────────────────────────────────────────
    local rtscBtn = MakeIconBtn(f, COL2_X, rowY,
        ICON_PATH .. "ability_hunter_markedfordeath",
        "RTSC",
        "Enable or disable RTSC.\nLeft-click to toggle.", BL)
    WireToggle(rtscBtn,
        function() PBM.ActionToGroup("rtsc")       end,
        function() PBM.ActionToGroup("rtsc reset") end)

    local rtscLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rtscLabel:SetPoint("LEFT", rtscBtn, "RIGHT", 6, 0)
    rtscLabel:SetText("|cffccccccRTSC|r")

    rowY = rowY + STEP

    -- ── Auto Release ──────────────────────────────────────────
    local releaseBtn = MakeIconBtn(f, COL2_X, rowY,
        ICON_PATH .. "achievement_bg_xkills_avgraveyard",
        "Auto Release",
        "Toggle automatic spirit release on bot death.", BL)
    WireToggle(releaseBtn,
        function() PBM.ActionToGroup("release")    end,
        function() PBM.ActionToGroup("no release") end)

    local relLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    relLabel:SetPoint("LEFT", releaseBtn, "RIGHT", 6, 0)
    relLabel:SetText("|cffccccccAuto Release|r")

    rowY = rowY + STEP

    -- ── Auto Stats ────────────────────────────────────────────
    local statsBtn = MakeIconBtn(f, COL2_X, rowY,
        ICON_PATH .. "inv_scroll_08",
        "Auto Stats",
        "Toggle automatic stats broadcast to group.", BL)
    WireToggle(statsBtn,
        function() PBM.ActionToGroup("stats on")  end,
        function() PBM.ActionToGroup("stats off") end)

    local statsLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statsLabel:SetPoint("LEFT", statsBtn, "RIGHT", 6, 0)
    statsLabel:SetText("|cffccccccAuto Stats|r")

    rowY = rowY + STEP

    -- ── Reset Bot AI ──────────────────────────────────────────
    local resetAIBtn = MakeIconBtn(f, COL2_X, rowY,
        ICON_PATH .. "inv_misc_tournaments_symbol_gnome",
        "Reset Bot AI",
        "Reset AI for targeted bot or entire group.", BL)
    resetAIBtn:SetScript("OnClick", function()
        PBM.ActionToTargetOrGroup("reset botAI")
    end)

    local resetAILabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetAILabel:SetPoint("LEFT", resetAIBtn, "RIGHT", 6, 0)
    resetAILabel:SetText("|cffccccccReset Bot AI|r")

    rowY = rowY + STEP

    -- ── Reset Action ──────────────────────────────────────────
    local resetActBtn = MakeIconBtn(f, COL2_X, rowY,
        ICON_PATH .. "inv_helmet_02",
        "Reset Action",
        "Reset actions for targeted bot or entire group.", BL)
    resetActBtn:SetScript("OnClick", function()
        PBM.ActionToTargetOrGroup("reset")
    end)

    local resetActLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetActLabel:SetPoint("LEFT", resetActBtn, "RIGHT", 6, 0)
    resetActLabel:SetText("|cffccccccReset Action|r")

end
