PBM = PBM or {}

-- ─────────────────────────────────────────────────────────────────────────────
--  PBM_CharSheet.lua
--  Shared character-sheet overlay used by all 10 class menus.
--
--  PBM.CreateCharSheet(config)  → menu, catcher
--    Builds the full overlay frame and populates every shared component.
--    Each class file calls this once, then adds its own strategy tree on top.
--
--  config = {
--    menuName    = "LichborneDruidMenu",     -- global frame name (required by ClassTabs)
--    catcherName = "LichborneDruidCatcher",
--    className   = "Druid",                  -- passed to InstallTieredStratDisplay
--    classHex    = "FF7D0A",                 -- class color (no leading #)
--    leftExt     = 5,                        -- pixels the overlay extends left of iLvl col
--    overlayW    = number,
--    overlayH    = number,
--    talentSpecs = { {label, spec, wowSpec, icon}, ... },
--    hideCallback = fn,                      -- called on ESC / click-away
--  }
--
--  PBM.HideCharSheet(menu, catcher)
--  PBM.ShowCharSheet(menu, catcher, row, leftExt)
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Timer helper ─────────────────────────────────────────────────────────────
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

-- ── Shared backdrop templates ─────────────────────────────────────────────────
local OVERLAY_BD = {
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = {left=2, right=2, top=2, bottom=2},
}
local HDR_CELL_BD = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = {left=1, right=1, top=1, bottom=1},
}

-- ── Icon sizes ────────────────────────────────────────────────────────────────
local ICON_SIZE = 26
local ICON_GAP  = 4

-- ─────────────────────────────────────────────────────────────────────────────
--  PBM.CreateCharSheet
-- ─────────────────────────────────────────────────────────────────────────────
function PBM.CreateCharSheet(config)
    local menuName    = config.menuName
    local catcherName = config.catcherName
    local className   = config.className
    local classHex    = config.classHex
    local leftExt     = config.leftExt or 5
    local overlayW    = config.overlayW
    local overlayH    = config.overlayH
    local talentSpecs = config.talentSpecs or {}
    local hideCallback = config.hideCallback

    -- ── Catcher (click-away) ─────────────────────────────────────────────────
    local catcher = CreateFrame("Button", catcherName, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("HIGH")
    catcher:SetFrameLevel(10)
    catcher:EnableMouse(true)
    catcher:SetScript("OnMouseDown", hideCallback)
    catcher:Hide()

    -- ── Overlay panel ────────────────────────────────────────────────────────
    local menu = CreateFrame("Frame", menuName, UIParent)
    menu:SetFrameStrata("TOOLTIP")
    menu:EnableMouse(true)
    menu:SetSize(overlayW, overlayH)
    menu:SetBackdrop(OVERLAY_BD)
    menu:SetBackdropColor(0.05, 0.07, 0.14, 1.0)
    menu:SetBackdropBorderColor(0.78, 0.61, 0.23, 1)

    menu:EnableKeyboard(true)
    menu:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then hideCallback() end
    end)

    menu:SetScript("OnHide", function()
        if menu.sourceRow then
            local nb = menu.sourceRow.nameBox
            if nb then
                nb:SetBackdropColor(0.05, 0.07, 0.14, 0.8)
                nb:SetBackdropBorderColor(0.15, 0.22, 0.38, 0.7)
            end
            menu.sourceRow = nil
        end
        if catcher then catcher:Hide() end
    end)

    -- ── Header row (gear bar) ────────────────────────────────────────────────
    local HDR_H = PBM.ROW_HEIGHT
    local hdr   = {}

    local hdrBg = menu:CreateTexture(nil, "ARTWORK")
    hdrBg:SetPoint("TOPLEFT",  menu, "TOPLEFT",  2, -2)
    hdrBg:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -2, -2)
    hdrBg:SetHeight(HDR_H)
    hdrBg:SetTexture(0.08, 0.10, 0.18, 0.8)
    hdr.bg = hdrBg

    local function MakeHdrCell(x, w, h)
        local cell = CreateFrame("Frame", nil, menu)
        cell:SetPoint("TOPLEFT", menu, "TOPLEFT", x + leftExt, -2)
        cell:SetSize(w - 2, h - 2)
        cell:SetBackdrop(HDR_CELL_BD)
        cell:SetBackdropColor(0.05, 0.07, 0.14, 1)
        cell:SetBackdropBorderColor(0.12, 0.18, 0.30, 0.8)
        return cell
    end

    local ilvlCell = MakeHdrCell(0, PBM.COL_GS_W, HDR_H)
    local hdrIlvl  = ilvlCell:CreateFontString(nil, "OVERLAY")
    hdrIlvl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    hdrIlvl:SetTextColor(0.831, 0.686, 0.216)
    hdrIlvl:SetJustifyH("CENTER")
    hdrIlvl:SetAllPoints()
    hdr.ilvl = hdrIlvl

    local gsCell = MakeHdrCell(PBM.REALGS_OFF - PBM.GS_OFF, PBM.COL_GS_W, HDR_H)
    local hdrGs  = gsCell:CreateFontString(nil, "OVERLAY")
    hdrGs:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    hdrGs:SetTextColor(0.831, 0.686, 0.216)
    hdrGs:SetJustifyH("CENTER")
    hdrGs:SetAllPoints()
    hdr.gs = hdrGs

    local profCell = PBM.MakeProfCell(
        menu, 0, HDR_H + 2,
        function() return menu.botName or "" end,
        nil, PBM.COL_NEEDS_W - 2)
    profCell:ClearAllPoints()
    profCell:SetPoint("TOPLEFT", menu, "TOPLEFT",
        PBM.NEEDS_OFF - PBM.GS_OFF + leftExt, -2)
    menu.profCell = profCell

    hdr.gear      = {}
    hdr.gearCells = {}
    for g = 1, PBM.GEAR_SLOTS do
        local gx   = PBM.GEAR_OFF + (g - 1) * PBM.COL_GEAR_W - PBM.GS_OFF
        local cell = MakeHdrCell(gx, PBM.COL_GEAR_W, HDR_H)
        local fs   = cell:CreateFontString(nil, "OVERLAY")
        fs:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        fs:SetTextColor(1, 1, 1)
        fs:SetJustifyH("CENTER")
        fs:SetAllPoints()
        hdr.gear[g]      = fs
        hdr.gearCells[g] = cell
    end
    PBM.InstallGearTooltips(menu, hdr)
    menu.hdr = hdr

    -- ── Spec icon (Templates button) ─────────────────────────────────────────
    local SPEC_BTN_SIZE = 39
    local specBtn = CreateFrame("Button", nil, menu)
    specBtn:SetSize(SPEC_BTN_SIZE, SPEC_BTN_SIZE)
    specBtn:SetPoint("TOPLEFT", menu, "TOPLEFT", 15, -(HDR_H + 15))
    local specTex = specBtn:CreateTexture(nil, "ARTWORK")
    specTex:SetAllPoints()
    specTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    specBtn.icon = specTex
    specBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    menu.specBtn = specBtn

    local specLabel = menu:CreateFontString(nil, "OVERLAY")
    specLabel:SetFont("Fonts\\FRIZQT__.TTF", 7)
    specLabel:SetPoint("BOTTOM", specBtn, "TOP", 0, 2)
    specLabel:SetTextColor(1, 0.82, 0)
    specLabel:SetText("Templates")

    -- ── Talent spec dropdown ──────────────────────────────────────────────────
    local talentsMenu = CreateFrame("Frame", nil, menu)
    talentsMenu:SetFrameStrata("TOOLTIP")
    talentsMenu:SetFrameLevel(menu:GetFrameLevel() + 10)
    talentsMenu:EnableMouse(true)
    talentsMenu:SetSize(150, 4 + #talentSpecs * 23)
    talentsMenu:SetBackdrop(OVERLAY_BD)
    talentsMenu:SetBackdropColor(0.05, 0.07, 0.14, 0.98)
    talentsMenu:SetBackdropBorderColor(0.78, 0.61, 0.23, 1)
    talentsMenu:SetPoint("TOPLEFT", specBtn, "TOPRIGHT", 2, 0)
    talentsMenu:Hide()

    for i, def in ipairs(talentSpecs) do
        local mb = CreateFrame("Button", nil, talentsMenu)
        mb:SetSize(142, 22)
        mb:SetPoint("TOPLEFT", talentsMenu, "TOPLEFT", 4, -4 - (i - 1) * 23)
        local mbIcon = mb:CreateTexture(nil, "ARTWORK")
        mbIcon:SetSize(18, 18)
        mbIcon:SetPoint("LEFT", mb, "LEFT", 2, 0)
        mbIcon:SetTexture(def.icon)
        local mbLabel = mb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        mbLabel:SetPoint("LEFT", mb, "LEFT", 24, 0)
        mbLabel:SetTextColor(1, 1, 1)
        mbLabel:SetText(def.label)
        mb:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        mb:SetScript("OnClick", function()
            local bot = menu.botName or ""
            if bot ~= "" then
                PBM.SendToBot("stopcasting", bot)
                PBM.SendToBot("talents switch 1", bot)
                PBM_TimerAfter(0.4, function()
                    PBM.SendToBot("talents spec " .. def.spec, bot)
                    PBM.State.pickingPending[bot] = true
                end)
            end
            specTex:SetTexture(def.icon)
            local rd = menu.sourceRow
                and menu.sourceRow.dbIndex
                and LichborneTrackerDB.rows[menu.sourceRow.dbIndex]
            if rd then rd.spec = def.wowSpec end
            if PBM.RefreshRows then PBM.RefreshRows() end
            if PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames > 0 then PBM.RefreshOverviewRows() end
            if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
            talentsMenu:Hide()
        end)
    end
    menu.talentsMenu = talentsMenu

    specBtn:SetScript("OnClick", function()
        local bot = menu.botName or ""
        if talentsMenu:IsShown() then
            talentsMenu:Hide()
        else
            if bot ~= "" then
                PBM.SendToBot("talents", bot)
                PBM_TimerAfter(0.2, function()
                    PBM.SendToBot("talents spec list", bot)
                end)
            end
            talentsMenu:Show()
        end
    end)
    specBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetFrameLevel(menu:GetFrameLevel() + 20)
        GameTooltip:AddLine("Set Talents", 1, 0.82, 0)
        GameTooltip:AddLine("Select a talent template for this Bot", 1, 1, 1)
        GameTooltip:Show()
    end)
    specBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- ── Who-info labels ───────────────────────────────────────────────────────
    local whoLine1 = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    whoLine1:SetPoint("TOPLEFT", specBtn, "TOPRIGHT", 8, 0)
    whoLine1:SetTextColor(1, 1, 1)
    whoLine1:SetText("--")
    local whoLine2 = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    whoLine2:SetPoint("TOPLEFT", specBtn, "TOPRIGHT", 8, -14)
    whoLine2:SetTextColor(1, 1, 1)
    whoLine2:SetText("")
    local whoLine3 = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    whoLine3:SetPoint("TOPLEFT", specBtn, "TOPRIGHT", 8, -28)
    whoLine3:SetTextColor(1, 1, 1)
    whoLine3:SetText("")
    menu.whoLine1 = whoLine1
    menu.whoLine2 = whoLine2
    menu.whoLine3 = whoLine3

    -- ── Stat labels ───────────────────────────────────────────────────────────
    local statLine1 = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statLine1:SetPoint("TOPLEFT", specBtn, "BOTTOMLEFT", 0, -6)
    statLine1:SetTextColor(1, 1, 1)
    statLine1:SetText("")
    local statLine2 = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statLine2:SetPoint("TOPLEFT", specBtn, "BOTTOMLEFT", 0, -20)
    statLine2:SetTextColor(1, 1, 1)
    statLine2:SetText("")
    local statLine3 = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statLine3:SetPoint("TOPLEFT", specBtn, "BOTTOMLEFT", 0, -34)
    statLine3:SetTextColor(1, 1, 1)
    statLine3:SetText("")
    menu.statLine1 = statLine1
    menu.statLine2 = statLine2
    menu.statLine3 = statLine3

    -- ── Refresh button (right of stat lines, centered vertically) ────────────
    local refreshBtn = CreateFrame("Button", nil, menu)
    refreshBtn:SetSize(58, 18)
    refreshBtn:SetPoint("TOPLEFT", specBtn, "BOTTOMRIGHT", 52, -16)
    refreshBtn:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = {left=2, right=2, top=2, bottom=2},
    })
    refreshBtn:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
    refreshBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    refreshBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    local refreshLbl = refreshBtn:CreateFontString(nil, "OVERLAY")
    refreshLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    refreshLbl:SetTextColor(0.78, 0.61, 0.23, 1)
    refreshLbl:SetAllPoints()
    refreshLbl:SetJustifyH("CENTER")
    refreshLbl:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        if menu.clearStratDisplay then menu.clearStratDisplay() end
        local botName = menu.botName or ""
        if botName ~= "" and PBM.QueryBotStrategies then
            if menu.resetAllIcons then menu.resetAllIcons() end
            menu._specUserSet = nil
            whoLine1:SetText("--"); whoLine2:SetText(""); whoLine3:SetText("")
            statLine1:SetText(""); statLine2:SetText(""); statLine3:SetText("")
            PBM.QueryBotStrategies(botName, menu, true)
        end
    end)

    -- ── Strategies label ──────────────────────────────────────────────────────
    local strategyLabel = menu:CreateFontString(nil, "OVERLAY")
    strategyLabel:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    strategyLabel:SetTextColor(0.78, 0.61, 0.23, 1)
    strategyLabel:SetText("Strategies")
    strategyLabel:SetPoint("TOP", menu, "TOP", 0, -(HDR_H + 30))
    strategyLabel:SetWidth(overlayW - 60)
    strategyLabel:SetJustifyH("CENTER")

    -- ── Strat list (right column) ─────────────────────────────────────────────
    PBM.InstallTieredStratDisplay(menu, className)

    -- ── 6-button vertical bar ─────────────────────────────────────────────────
    -- Talent / Inventory / Spellbook (activate) + Food / Loot / Gather (toggle NC)
    local function MakeLeftBtn(anchorFrame, anchorPoint, ox, oy, iconPath)
        local btn = CreateFrame("Button", nil, menu)
        btn:SetSize(ICON_SIZE, ICON_SIZE)
        btn:SetPoint("TOPLEFT", anchorFrame, anchorPoint, ox, oy)
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture("Interface\\Icons\\" .. iconPath)
        btn.icon = tex
        btn.state = false
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        return btn
    end

    local function IconOn(btn)
        btn.state = true
        if btn.icon then btn.icon:SetDesaturated(false) end
    end
    local function IconOff(btn)
        btn.state = false
        if btn.icon then btn.icon:SetDesaturated(true) end
    end

    -- Row 1: Talent (activate)
    local talentBtn = MakeLeftBtn(statLine3, "BOTTOMLEFT", 20, -15, "Ability_Marksmanship")
    talentBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Open Talents", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Opens Window Behind Tracker", 1, 0.2, 0.2)
        GameTooltip:Show()
    end)
    talentBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    talentBtn:SetScript("OnClick", function()
        local bot = menu.botName or ""
        if PBM.OpenTalentWindow then PBM.OpenTalentWindow(bot) end
    end)

    -- Row 2: Inventory (activate)
    local invBtn = MakeLeftBtn(talentBtn, "BOTTOMLEFT", 0, -ICON_GAP, "INV_Misc_Bag_08")
    invBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Open Inventory", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Opens Window Behind Tracker", 1, 0.2, 0.2)
        GameTooltip:Show()
    end)
    invBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    invBtn:SetScript("OnClick", function()
        local bot = menu.botName or ""
        if PBM.OpenInventoryWindow then PBM.OpenInventoryWindow(bot) end
    end)

    -- Row 3: Spellbook (activate)
    local spellBtn = MakeLeftBtn(invBtn, "BOTTOMLEFT", 0, -ICON_GAP, "INV_Misc_Book_09")
    spellBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Open Spellbook", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Opens Window Behind Tracker", 1, 0.2, 0.2)
        GameTooltip:Show()
    end)
    spellBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    spellBtn:SetScript("OnClick", function()
        local bot = menu.botName or ""
        if PBM.OpenSpellbookWindow then PBM.OpenSpellbookWindow(bot) end
    end)

    -- Row 4: Food and Drink (toggle NC)
    local treeFoodBtn = MakeLeftBtn(spellBtn, "BOTTOMLEFT", 0, -ICON_GAP, "INV_Drink_24_SealWhey")
    IconOff(treeFoodBtn)
    treeFoodBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetFrameLevel(menu:GetFrameLevel() + 20)
        GameTooltip:ClearLines()
        GameTooltip:SetText("|cffffcc00Food and Drink|r |cff999999- |r|cffC79C3Bfood|r |cff00cc00NC|r", 1, 0.82, 0)
        GameTooltip:AddLine("|cffffcc00Eat and drink after combat|r", 1, 1, 1)
        GameTooltip:AddLine("Bot eats food and drinks water to restore", 1, 1, 1)
        GameTooltip:AddLine("|cffffcc00health|r and |cff3A8FC4mana|r between fights.", 1, 1, 1)
        GameTooltip:Show()
    end)
    treeFoodBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    treeFoodBtn:SetScript("OnClick", function()
        local bot = menu.botName or ""
        menu._specUserSet = true
        if treeFoodBtn.state then
            PBM.SendToBot("nc -food,?", bot); IconOff(treeFoodBtn)
        else
            PBM.SendToBot("nc +food,?", bot); IconOn(treeFoodBtn)
        end
    end)
    menu.treeFoodBtn = treeFoodBtn

    -- Row 5: Loot (toggle NC)
    local treeLootBtn = MakeLeftBtn(treeFoodBtn, "BOTTOMLEFT", 0, -ICON_GAP, "INV_Misc_Coin_16")
    IconOff(treeLootBtn)
    treeLootBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetFrameLevel(menu:GetFrameLevel() + 20)
        GameTooltip:ClearLines()
        GameTooltip:SetText("|cffffcc00Loot|r |cff999999- |r|cffC79C3Bloot|r |cff00cc00NC|r", 1, 0.82, 0)
        GameTooltip:AddLine("|cffffcc00Auto loot bodies|r", 1, 1, 1)
        GameTooltip:AddLine("Bot loots killed enemies automatically.", 1, 1, 1)
        GameTooltip:Show()
    end)
    treeLootBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    treeLootBtn:SetScript("OnClick", function()
        local bot = menu.botName or ""
        menu._specUserSet = true
        if treeLootBtn.state then
            PBM.SendToBot("nc -loot,?", bot); IconOff(treeLootBtn)
        else
            PBM.SendToBot("nc +loot,?", bot); IconOn(treeLootBtn)
        end
    end)
    menu.treeLootBtn = treeLootBtn

    -- Row 6: Gather (toggle NC)
    local treeGatherBtn = MakeLeftBtn(treeLootBtn, "BOTTOMLEFT", 0, -ICON_GAP, "Trade_Mining")
    IconOff(treeGatherBtn)
    treeGatherBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetFrameLevel(menu:GetFrameLevel() + 20)
        GameTooltip:ClearLines()
        GameTooltip:SetText("|cffffcc00Gather|r |cff999999- |r|cffC79C3Bgather|r |cff00cc00NC|r", 1, 0.82, 0)
        GameTooltip:AddLine("|cffffcc00Gather resource nodes|r", 1, 1, 1)
        GameTooltip:AddLine("Bot harvests nearby resource nodes.", 1, 1, 1)
        GameTooltip:Show()
    end)
    treeGatherBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    treeGatherBtn:SetScript("OnClick", function()
        local bot = menu.botName or ""
        menu._specUserSet = true
        if treeGatherBtn.state then
            PBM.SendToBot("nc -gather,?", bot); IconOff(treeGatherBtn)
        else
            PBM.SendToBot("nc +gather,?", bot); IconOn(treeGatherBtn)
        end
    end)
    menu.treeGatherBtn = treeGatherBtn

    -- ── PvP toggle (universal — appears in all class menus) ──────────────────
    local PVP_HDR_W = ICON_SIZE + 8   -- 34px header centers the 26px button
    local pvpHdrOffX = 72              -- pixels right of talentBtn's left edge

    do
        local pvpBox = CreateFrame("Frame", nil, menu)
        pvpBox:SetSize(PVP_HDR_W, 18)
        pvpBox:SetPoint("TOPLEFT", talentBtn, "TOPLEFT", pvpHdrOffX + 11, -15)
        pvpBox:SetBackdrop(OVERLAY_BD)
        pvpBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        pvpBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local fs = pvpBox:CreateFontString(nil, "OVERLAY")
        fs:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        fs:SetTextColor(0.93, 0.27, 0.20, 1)   -- red (ee4433)
        fs:SetAllPoints()
        fs:SetJustifyH("CENTER")
        fs:SetText("PvP")
    end

    local treePvpBtn = CreateFrame("Button", nil, menu)
    treePvpBtn:SetSize(ICON_SIZE, ICON_SIZE)
    treePvpBtn:SetPoint("TOPLEFT", talentBtn, "TOPLEFT",
        pvpHdrOffX + 11 + math.floor((PVP_HDR_W - ICON_SIZE) / 2),
        -15 - 18 - 1)
    local pvpTex = treePvpBtn:CreateTexture(nil, "ARTWORK")
    pvpTex:SetAllPoints()
    pvpTex:SetTexture("Interface\\Icons\\Ability_Warrior_Challange")
    pvpTex:SetDesaturated(true)
    treePvpBtn.icon = pvpTex
    treePvpBtn.state = false
    treePvpBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    treePvpBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetFrameLevel(menu:GetFrameLevel() + 20)
        GameTooltip:ClearLines()
        GameTooltip:SetText("|cffffff00PvP|r |cff999999- |r|cffee4433PvP|r |cffffcc00NC|r")
        GameTooltip:AddLine("Activates player targeting.", 1, 1, 1)
        GameTooltip:AddLine("Rotations are unchanged.", 1, 1, 1)
        GameTooltip:Show()
    end)
    treePvpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    treePvpBtn:SetScript("OnClick", function()
        local bot = menu.botName or ""
        menu._specUserSet = true
        if treePvpBtn.state then
            PBM.SendToBot("nc -pvp,?", bot); IconOff(treePvpBtn)
        else
            PBM.SendToBot("nc +pvp,?", bot); IconOn(treePvpBtn)
        end
    end)
    menu.treePvpBtn = treePvpBtn

    -- ── Base resetSharedIcons (class file extends this for tree buttons) ───────
    menu.resetSharedIcons = function()
        IconOff(treeFoodBtn)
        IconOff(treeLootBtn)
        IconOff(treeGatherBtn)
        IconOff(treePvpBtn)
    end

    -- ── Base onStrategyUpdate (handles NC food/loot/gather + CO pvp state) ──────
    local _baseSU = menu.onStrategyUpdate
    menu.onStrategyUpdate = function(stratType, activeSet)
        if _baseSU then _baseSU(stratType, activeSet) end
        if not menu._specUserSet then
            if stratType == "nc" then
                if activeSet["food"]   then IconOn(treeFoodBtn)   else IconOff(treeFoodBtn)   end
                if activeSet["loot"]   then IconOn(treeLootBtn)   else IconOff(treeLootBtn)   end
                if activeSet["gather"] then IconOn(treeGatherBtn) else IconOff(treeGatherBtn) end
                if activeSet["pvp"]    then IconOn(treePvpBtn)    else IconOff(treePvpBtn)    end
            end
        end
    end

    -- ── onWhoResponse ─────────────────────────────────────────────────────────
    menu.onWhoResponse = function(sender, msg)
        local race    = msg:match("([%a ]+) %[")
        local spec    = msg:match("%] ([%a ]+) %(")
        local talents = msg:match("%((%d+/%d+/%d+)%)")
        local class   = msg:match("%d+/%d+/%d+%) (%a+) %(%d+ lvl%)")
        local level   = msg:match("%((%d+) lvl%)")
        local name    = menu.botName or sender
        local function cap(s) return s and (s:sub(1,1):upper() .. s:sub(2)) or "?" end
        menu.whoLine1:SetText("|cff" .. classHex .. name .. "|r")
        menu.whoLine2:SetText("|cffFFD100" .. (level or "?") .. "|r |cffFFFFFF" .. cap(race) .. "|r |cff" .. classHex .. cap(class) .. "|r")
        menu.whoLine3:SetText("|cffFFFFFF" .. cap(spec) .. "|r |cffFFD100(" .. (talents or "?") .. ")|r")
    end

    -- ── onStatsResponse ───────────────────────────────────────────────────────
    menu.onStatsResponse = function(sender, msg, rawMsg)
        local gold = msg:match("(%d+)g") or msg:match("(%d+), %d+/%d+ Bag")
        local bag  = msg:match("(%d+/%d+) Bag")
        local dur  = msg:match("(%d+)%% %(")
        menu.statLine1:SetText(gold and ("|cffFFD100" .. gold .. "g|r") or "")
        if bag then
            local used, total = bag:match("(%d+)/(%d+)")
            -- Use the exact color the playerbot applied to the bag count in its whisper.
            -- rawMsg still has the |cAARRGGBB code immediately before the "N/N" value.
            local bagHex = rawMsg and rawMsg:match("|c(%x%x%x%x%x%x%x%x)%d+/%d+")
            local colorTag = bagHex and ("|c" .. bagHex) or "|cffFFFFFF"
            menu.statLine2:SetText(colorTag .. used .. "/" .. total .. "|r|cffFFFFFF Bag|r")
        else
            menu.statLine2:SetText("")
        end
        if dur then
            local t = (tonumber(dur) or 0) / 100
            local r = math.floor(math.min(1, t * 2) * 255)
            local g = math.floor(math.min(1, (1 - t) * 2) * 255)
            menu.statLine3:SetText("|cff" .. string.format("%02x%02x00", r, g) .. dur .. "% Durability|r")
        else
            menu.statLine3:SetText("")
        end
    end

    -- ── Bottom notes (left-aligned, right of Ignored Spell List, single line) ──
    local noteFont  = "Fonts\\FRIZQT__.TTF"
    local noteSize  = 9
    local noteColor = { 0.70, 0.70, 0.70, 1 }
    local noteX     = 138   -- clears the 115px ignored-spell-list (at x=15) + gap

    local note2 = menu:CreateFontString(nil, "OVERLAY")
    note2:SetFont(noteFont, noteSize, "OUTLINE")
    note2:SetTextColor(unpack(noteColor))
    note2:SetWordWrap(false)
    note2:SetJustifyH("LEFT")
    note2:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", noteX, 8)
    note2:SetText("|cffFFD100Note:|r During raid encounters, strategies are based on spec and are automatically overwritten. To change bot behavior, use a different template or spec.")

    local note1 = menu:CreateFontString(nil, "OVERLAY")
    note1:SetFont(noteFont, noteSize, "OUTLINE")
    note1:SetTextColor(unpack(noteColor))
    note1:SetWordWrap(false)
    note1:SetJustifyH("LEFT")
    note1:SetPoint("BOTTOMLEFT", note2, "TOPLEFT", 0, 4)
    note1:SetText("|cffFFD100Note:|r The Strategy List on the right is what the bot actually uses. The center buttons are for changes/visual reference. Confirm the list reflects your setup.")

    local note0 = menu:CreateFontString(nil, "OVERLAY")
    note0:SetFont(noteFont, noteSize, "OUTLINE")
    note0:SetTextColor(unpack(noteColor))
    note0:SetWordWrap(false)
    note0:SetJustifyH("LEFT")
    note0:SetPoint("BOTTOMLEFT", note1, "TOPLEFT", 0, 4)
    note0:SetText("|cffFFD100Note:|r For quick setup, use the Templates menu in the top-left corner of each character tab. This will automatically configure both talents and strategies for you.")

    local stratNoteLabel = menu:CreateFontString(nil, "OVERLAY")
    stratNoteLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    stratNoteLabel:SetText("|cffff4444** Strategies are subject to change.|r")
    stratNoteLabel:SetPoint("BOTTOMLEFT",  menu, "BOTTOMLEFT",   8, 52)
    stratNoteLabel:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -8, 52)
    stratNoteLabel:SetJustifyH("CENTER")

    -- ── CO ! / NC ! Reset buttons (above notes) ──────────────────────────────
    local RESET_BOX_BD = {
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = {left=2, right=2, top=2, bottom=2},
    }
    local resetBtnW   = 26
    local resetBtnH   = 18
    local resetBtnGap = 4
    local resetTotalW = resetBtnW * 2 + resetBtnGap  -- 34px, matches PVP_HDR_W

    local coResetBtn = CreateFrame("Button", nil, menu)
    coResetBtn:SetSize(resetBtnW, resetBtnH)
    coResetBtn:SetPoint("BOTTOMLEFT", note0, "TOPLEFT", 0, 8)
    coResetBtn:SetBackdrop(RESET_BOX_BD)
    coResetBtn:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
    coResetBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    coResetBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    local coResetLbl = coResetBtn:CreateFontString(nil, "OVERLAY")
    coResetLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    coResetLbl:SetTextColor(0.78, 0.61, 0.23, 1)
    coResetLbl:SetAllPoints()
    coResetLbl:SetJustifyH("CENTER")
    coResetLbl:SetText("CO")
    coResetBtn:SetScript("OnClick", function()
        PBM.SendToBot("co !", menu.botName or "")
    end)
    coResetBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetFrameLevel(menu:GetFrameLevel() + 20)
        GameTooltip:ClearLines()
        GameTooltip:SetText("|cffFFD100Reset CO Strategies|r")
        GameTooltip:AddLine("Resets combat strategies to defaults.", 1, 1, 1)
        GameTooltip:AddLine("Non-combat strategies are preserved.", 1, 1, 1)
        GameTooltip:Show()
    end)
    coResetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local ncResetBtn = CreateFrame("Button", nil, menu)
    ncResetBtn:SetSize(resetBtnW, resetBtnH)
    ncResetBtn:SetPoint("TOPLEFT", coResetBtn, "TOPRIGHT", resetBtnGap, 0)
    ncResetBtn:SetBackdrop(RESET_BOX_BD)
    ncResetBtn:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
    ncResetBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    ncResetBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    local ncResetLbl = ncResetBtn:CreateFontString(nil, "OVERLAY")
    ncResetLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    ncResetLbl:SetTextColor(0.78, 0.61, 0.23, 1)
    ncResetLbl:SetAllPoints()
    ncResetLbl:SetJustifyH("CENTER")
    ncResetLbl:SetText("NC")
    ncResetBtn:SetScript("OnClick", function()
        PBM.SendToBot("nc !", menu.botName or "")
    end)
    ncResetBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetFrameLevel(menu:GetFrameLevel() + 20)
        GameTooltip:ClearLines()
        GameTooltip:SetText("|cffFFD100Reset NC Strategies|r")
        GameTooltip:AddLine("Resets non-combat strategies to defaults.", 1, 1, 1)
        GameTooltip:AddLine("Combat strategies are preserved.", 1, 1, 1)
        GameTooltip:Show()
    end)
    ncResetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local resetHdr = CreateFrame("Frame", nil, menu)
    resetHdr:SetSize(resetTotalW, resetBtnH)
    resetHdr:SetPoint("BOTTOMLEFT", coResetBtn, "TOPLEFT", 0, 4)
    resetHdr:SetBackdrop(RESET_BOX_BD)
    resetHdr:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
    resetHdr:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    local resetHdrLbl = resetHdr:CreateFontString(nil, "OVERLAY")
    resetHdrLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    resetHdrLbl:SetTextColor(0.78, 0.61, 0.23, 1)
    resetHdrLbl:SetAllPoints()
    resetHdrLbl:SetJustifyH("CENTER")
    resetHdrLbl:SetText("Reset")

    menu:Hide()
    return menu, catcher
end

-- ─────────────────────────────────────────────────────────────────────────────
--  PBM.HideCharSheet(menu, catcher)
-- ─────────────────────────────────────────────────────────────────────────────
function PBM.HideCharSheet(menu, catcher)
    if menu then
        if menu.sourceRow then
            local nb = menu.sourceRow.nameBox
            if nb then
                nb:SetBackdropColor(0.05, 0.07, 0.14, 0.8)
                nb:SetBackdropBorderColor(0.15, 0.22, 0.38, 0.7)
            end
            menu.sourceRow = nil
        end
        menu:Hide()
    end
    if catcher then catcher:Hide() end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  PBM.ShowCharSheet(menu, catcher, row, leftExt)
-- ─────────────────────────────────────────────────────────────────────────────
function PBM.ShowCharSheet(menu, catcher, row, leftExt)
    local row1 = PBM.State.rowFrames[1]
    if not row1 then return end

    if menu.sourceRow and menu.sourceRow ~= row then
        local oldNb = menu.sourceRow.nameBox
        if oldNb then
            oldNb:SetBackdropColor(0.05, 0.07, 0.14, 0.85)
            oldNb:SetBackdropBorderColor(0.3, 0.3, 0.5, 0.8)
        end
    end

    menu.sourceRow = row
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", row1, "TOPLEFT", PBM.GS_OFF - leftExt, 5)

    local rowData = row.dbIndex and LichborneTrackerDB.rows[row.dbIndex]
    menu.botName = (rowData and rowData.name) or ""

    local nb = row.nameBox
    if nb then
        nb:SetBackdropColor(0.78, 0.61, 0.23, 0.35)
        nb:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.8)
    end

    if menu.talentsMenu then menu.talentsMenu:Hide() end

    -- Update spec icon from row data
    local specName = rowData and rowData.spec or ""
    local specIcon = PBM.SPEC_ICONS and PBM.SPEC_ICONS[specName]
    if menu.specBtn then
        menu.specBtn.icon:SetTexture(specIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end

    -- Refresh prof cell
    if menu.profCell then
        PBM.RefreshProfCell(menu.profCell, menu.botName or "")
    end

    -- Populate gear bar from row data
    if menu.hdr and rowData then
        local h = menu.hdr
        local gsval = rowData.gs or 0
        h.ilvl:SetText(gsval > 0 and tostring(gsval) or "")
        local realGsVal = rowData.realGs or 0
        h.gs:SetText(realGsVal > 0 and tostring(realGsVal) or "")
        for g = 1, PBM.GEAR_SLOTS do
            local val  = rowData.ilvl and rowData.ilvl[g] or 0
            local link = rowData.ilvlLink and rowData.ilvlLink[g]
            h.gear[g]:SetText((val > 0 or (link and link ~= "")) and tostring(val) or "")
            local qc = PBM.GetItemQualityColor and PBM.GetItemQualityColor(link)
            if qc then
                h.gear[g]:SetTextColor(qc.r, qc.g, qc.b)
            else
                h.gear[g]:SetTextColor(1, 1, 1)
            end
        end
        menu._gearLinks = rowData.ilvlLink
    end

    -- Clear strategy display and re-query
    if menu.clearStratDisplay then menu.clearStratDisplay() end

    local botName = menu.botName
    if botName ~= "" and PBM and PBM.QueryBotStrategies then
        if menu.resetAllIcons then menu.resetAllIcons() end
        menu._specUserSet = nil
        if menu.whoLine1 then menu.whoLine1:SetText("--") end
        if menu.whoLine2 then menu.whoLine2:SetText("") end
        if menu.whoLine3 then menu.whoLine3:SetText("") end
        if menu.statLine1 then menu.statLine1:SetText("") end
        if menu.statLine2 then menu.statLine2:SetText("") end
        if menu.statLine3 then menu.statLine3:SetText("") end
        PBM.QueryBotStrategies(botName, menu, true)
    end

    menu:Show()
    catcher:Show()
    GameTooltip:Hide()
end
