-- ============================================================
--  PBM_BottomTabs.lua  |  Title-bar tabs: Playerbots / LevelSync / Notes
--  Panel content is delegated to per-tab files:
--    PBM_Tab_Playerbots.lua  → PBM.BuildPlayerbotsPanel(panel, ctx)
--    PBM_Tab_LevelSync.lua   → PBM.BuildLevelSyncPanel(panel, ctx)
--    PBM_Tab_Notes.lua       → PBM.BuildNotesPanel(panel, ctx)
-- ============================================================
PBM = PBM or {}
PBM.State = PBM.State or {}

local PERI_R, PERI_G, PERI_B = 0.467, 0.600, 1.000
local GOLD_R, GOLD_G, GOLD_B = 0.78,  0.61,  0.23
local BG_R,   BG_G,   BG_B   = 0.04,  0.06,  0.12
local FONT = "Fonts\\FRIZQT__.TTF"

local BD_CELL = {
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true, tileSize=8, edgeSize=6,
    insets={left=1, right=1, top=1, bottom=1},
}

-- ── Tab definitions (colors match LT exactly) ─────────────────
local BOTTOM_TABS = {
    { id="Playerbots", label="Playerbots", r=PERI_R,  g=PERI_G,  b=PERI_B  },
    { id="LevelSync",  label="LevelSync",  r=GOLD_R,  g=GOLD_G,  b=GOLD_B  },
    { id="Notes",      label="Notes",      r=GOLD_R,  g=GOLD_G,  b=GOLD_B  },
}

-- ── Tab button layout (title bar row, right of Clear buttons) ─
local TAB_W       = 83
local TAB_H       = 26
local TAB_STEP    = 84
local TAB_START_X = 829
local TAB_START_Y = -7

-- ── Content panel dimensions ──────────────────────────────────
local CONTENT_W = 1086
local CONTENT_H = 512
local CONTENT_X = 15
local CONTENT_Y = -66

-- ── Module state ──────────────────────────────────────────────
PBM.State.activeBottomTab  = nil
PBM.State.bottomTabButtons = {}
PBM.State.bottomTabPanels  = {}

-- ── Public: sync bottom tab highlight states ──────────────────
function PBM.UpdateBottomTabHighlights()
    if not PBM.State.bottomTabButtons then return end
    for _, tabDef in ipairs(BOTTOM_TABS) do
        local btn = PBM.State.bottomTabButtons[tabDef.id]
        if btn then
            local isActive = (PBM.State.activeBottomTab == tabDef.id)
            if isActive then
                btn:SetAlpha(1.0)
                btn.bg:SetTexture(tabDef.r*0.45, tabDef.g*0.45, tabDef.b*0.45, 1)
                btn.bottomLine:SetTexture(tabDef.r, tabDef.g, tabDef.b, 1)
            else
                btn:SetAlpha(0.5)
                btn.bg:SetTexture(0.05, 0.07, 0.12, 1)
                btn.bottomLine:SetTexture(0, 0, 0, 0)
            end
        end
    end
end

-- ── Public: called from UpdateTabs at the start of every tab switch ─
function PBM.OnTopTabChanged()
    local isBottomPanel = PBM.State.bottomTabPanels and
                          PBM.State.bottomTabPanels[PBM.State.activeTab] ~= nil
    -- Hide every panel except the one we are switching TO
    for id, p in pairs(PBM.State.bottomTabPanels) do
        if id ~= PBM.State.activeTab then p:Hide() end
    end
    -- Resolve which bottom tab is now "active"
    if isBottomPanel then
        PBM.State.activeBottomTab = PBM.State.activeTab
    else
        PBM.State.activeBottomTab = nil
    end
    PBM.UpdateBottomTabHighlights()
end

-- ── Public: activate a bottom tab ────────────────────────────
function PBM.ActivateBottomTab(id)
    PBM.State.activeTab = id
    PBM.UpdateTabs()
    PBM.RefreshRows()
    if id == "LevelSync" and PBM.LevelSyncAutoRefresh then
        PBM.LevelSyncAutoRefresh()
    end
end

-- ── Content frame factory ─────────────────────────────────────
--  fullHeight=true: covers the full lower area (LevelSync only) so
--  underlying PBM buttons can't bleed through.
--  fullHeight=false: standard 1086×512 panel at fl+10.
--  hr/hg/hb: header accent colour (defaults to periwinkle).
local FS_SIDE   = 13          -- flush with gold content border
local FS_BOT    = 8           -- clears BOTTOMLEFT y=8 buttons
local FULL_W    = 1120 - 2 * FS_SIDE        -- 1094
local FULL_H    = 758 + CONTENT_Y - FS_BOT  -- 684  (758 - 66 - 8)

local function MakeContentFrame(name, parent, fl, title, fullHeight, hr, hg, hb)
    hr = hr or PERI_R; hg = hg or PERI_G; hb = hb or PERI_B
    local f = CreateFrame("Frame", name, parent)
    if fullHeight then
        f:SetPoint("TOPLEFT", parent, "TOPLEFT", FS_SIDE, CONTENT_Y)
        f:SetSize(FULL_W, FULL_H)
        f:SetFrameLevel(fl + 25)
        f:EnableMouse(true)
    else
        f:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_X, CONTENT_Y)
        f:SetSize(CONTENT_W, CONTENT_H)
        f:SetFrameLevel(fl + 10)
    end

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f); bg:SetTexture(BG_R, BG_G, BG_B, 1)

    local pfl = f:GetFrameLevel()
    local hdr = CreateFrame("Frame", nil, f)
    hdr:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    hdr:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    hdr:SetHeight(24); hdr:SetFrameLevel(pfl + 1)
    local hdrBg = hdr:CreateTexture(nil, "BACKGROUND")
    hdrBg:SetAllPoints(hdr)
    hdrBg:SetTexture(hr*0.18, hg*0.18, hb*0.18, 1)
    local hdrBorder = hdr:CreateTexture(nil, "BORDER")
    hdrBorder:SetPoint("BOTTOMLEFT",  hdr, "BOTTOMLEFT",  0, 0)
    hdrBorder:SetPoint("BOTTOMRIGHT", hdr, "BOTTOMRIGHT", 0, 0)
    hdrBorder:SetHeight(2); hdrBorder:SetTexture(hr, hg, hb, 0.6)
    local titleHex = string.format("|cff%02x%02x%02x", math.floor(hr*255), math.floor(hg*255), math.floor(hb*255))
    local hdrTitle = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdrTitle:SetPoint("TOPLEFT",  hdr, "TOPLEFT",  0, 0)
    hdrTitle:SetPoint("TOPRIGHT", hdr, "TOPRIGHT", 0, 0)
    hdrTitle:SetHeight(24); hdrTitle:SetJustifyH("CENTER"); hdrTitle:SetJustifyV("MIDDLE")
    hdrTitle:SetText(titleHex..title.."|r")

    f:Hide()
    return f
end

-- ── Chat helpers (passed to tab builders via ctx) ─────────────
local function ActionToGroup(cmd)
    if GetNumRaidMembers() > 5 then SendChatMessage(cmd, "RAID")
    elseif GetNumPartyMembers() > 0 then SendChatMessage(cmd, "PARTY")
    else SendChatMessage(cmd, "SAY") end
end

local function ActionToTargetOrGroup(cmd)
    local t = UnitName("target")
    if t and t ~= "Unknown Entity" and UnitIsPlayer("target") then
        SendChatMessage(cmd, "WHISPER", nil, t)
    else ActionToGroup(cmd) end
end

-- ============================================================
--  BuildBottomTabs — main entry point (called from TrackerCore)
-- ============================================================
function PBM.BuildBottomTabs(parent, fl)
    if PBM.State.bottomTabsBuilt then return end
    PBM.State.bottomTabsBuilt = true

    -- Context table passed to each panel builder
    local ctx = {
        PERI_R = PERI_R, PERI_G = PERI_G, PERI_B = PERI_B,
        GOLD_R = GOLD_R, GOLD_G = GOLD_G, GOLD_B = GOLD_B,
        BG_R   = BG_R,   BG_G   = BG_G,   BG_B   = BG_B,
        FONT    = FONT,
        BD_CELL = BD_CELL,
        ActionToGroup         = ActionToGroup,
        ActionToTargetOrGroup = ActionToTargetOrGroup,
    }

    -- ── Playerbots panel ─────────────────────────────────────
    local pbPanel = MakeContentFrame("PBMTabPanel_Playerbots", parent, fl, "Playerbots", false)
    PBM.State.bottomTabPanels["Playerbots"] = pbPanel
    PBM.BuildPlayerbotsPanel(pbPanel, ctx)

    -- ── LevelSync panel (gold header, full height) ────────────
    local lsPanel = MakeContentFrame("PBMTabPanel_LevelSync", parent, fl, "LevelSync", true, GOLD_R, GOLD_G, GOLD_B)
    PBM.State.bottomTabPanels["LevelSync"] = lsPanel
    PBM.BuildLevelSyncPanel(lsPanel, ctx)

    -- ── Notes panel (gold header) ─────────────────────────────
    local notesPanel = MakeContentFrame("PBMTabPanel_Notes", parent, fl, "Notes", false, GOLD_R, GOLD_G, GOLD_B)
    PBM.State.bottomTabPanels["Notes"] = notesPanel
    PBM.BuildNotesPanel(notesPanel, ctx)

    -- ── Tab buttons ──────────────────────────────────────────
    for i, tabDef in ipairs(BOTTOM_TABS) do
        local xOff = TAB_START_X + (i-1) * TAB_STEP
        local btn = CreateFrame("Button", "LichborneBottomTab_"..tabDef.id, parent)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, TAB_START_Y)
        btn:SetSize(TAB_W, TAB_H)
        btn:SetFrameLevel(fl + 12)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(btn); bg:SetTexture(0.05, 0.07, 0.12, 1); btn.bg = bg

        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

        local bottomLine = btn:CreateTexture(nil, "OVERLAY")
        bottomLine:SetHeight(3); bottomLine:SetWidth(TAB_W - 4)
        bottomLine:SetPoint("BOTTOM", btn, "BOTTOM", 0, 1)
        bottomLine:SetTexture(0, 0, 0, 0); btn.bottomLine = bottomLine

        local hex = string.format("|cff%02x%02x%02x",
            math.floor(tabDef.r*255), math.floor(tabDef.g*255), math.floor(tabDef.b*255))
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints(btn); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
        lbl:SetText(hex..tabDef.label.."|r")

        local captured_id = tabDef.id
        btn:SetScript("OnClick", function() PBM.ActivateBottomTab(captured_id) end)
        btn:SetScript("OnEnter", function()
            btn:SetAlpha(1.0)
        end)
        btn:SetScript("OnLeave", function()
            if PBM.State.activeBottomTab ~= captured_id then btn:SetAlpha(0.5) end
        end)
        btn:SetAlpha(0.5)
        PBM.State.bottomTabButtons[tabDef.id] = btn
    end

    PBM.UpdateBottomTabHighlights()
end
