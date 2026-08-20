PBM = PBM or {}

-- ─────────────────────────────────────────────────────────────────────────────
--  PBM_CharSheet.lua
--  Superposició de la fitxa de personatge compartida utilitzada pels 10 menús de classe.
--
--  PBM.CreateCharSheet(config)  → menu, catcher
--    Construeix el marc de superposició complet i omple tots els components compartits.
--    Cada fitxer de classe ho crida una vegada, i després afegeix el seu propi arbre d'estratègia a sobre.
--
--  config = {
--    menuName    = "LichborneDruidMenu",     -- nom del marc global (requerit per ClassTabs)
--    catcherName = "LichborneDruidCatcher",
--    className   = "Druid",                  -- passat a InstallTieredStratDisplay
--    classHex    = "FF7D0A",                 -- color de classe (sense # inicial)
--    leftExt     = 5,                        -- píxels que la superposició s'estén a l'esquerra de la col. iLvl
--    overlayW    = number,
--    overlayH    = number,
--    talentSpecs = { {label, spec, wowSpec, icon}, ... },
--    hideCallback = fn,                      -- cridat en prémer ESC / fer clic fora
--  }
--
--  PBM.HideCharSheet(menu, catcher)
--  PBM.ShowCharSheet(menu, catcher, row, leftExt)
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Auxiliar de temporitzador ────────────────────────────────────────────────
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

-- ── Plantilles de fons compartides ───────────────────────────────────────────
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

-- ── Mides de les icones ──────────────────────────────────────────────────────
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

    -- ── Catcher (captura de clics a fora) ────────────────────────────────────
    local catcher = CreateFrame("Button", catcherName, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("HIGH")
    catcher:SetFrameLevel(10)
    catcher:EnableMouse(true)
    catcher:SetScript("OnMouseDown", hideCallback)
    catcher:Hide()

    -- ── Panell de superposició ────────────────────────────────────────────────
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

    -- ── Fila de la capçalera (barra d'equipament) ────────────────────────────
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

    -- ── Icona d'especialització (botó de Plantilles) ─────────────────────────
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
    specLabel:SetText("Plantilles")

    -- ── Desplegable d'especialització de talents ─────────────────────────────
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
        GameTooltip:AddLine("Establir Talents", 1, 0.82, 0)
        GameTooltip:AddLine("Selecciona una plantilla de talents per a aquest Bot", 1, 1, 1)
        GameTooltip:Show()
    end)
    specBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- ── Etiquetes d'informació general (Who) ──────────────────────────────────
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

    -- ── Etiquetes d'estadístiques ──────────────────────────────────────────────
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

    -- ── Botó d'actualització (A la dreta de les línies d'estats, centrat verticalment)
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
    refreshLbl:SetText("Actualitza")
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

    -- ── Etiqueta d'estratègies ────────────────────────────────────────────────
    local strategyLabel = menu:CreateFontString(nil, "OVERLAY")
    strategyLabel:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    strategyLabel:SetTextColor(0.78, 0.61, 0.23, 1)
    strategyLabel:SetText("Estratègies")
    strategyLabel:SetPoint("TOP", menu, "TOP", 0, -(HDR_H + 30))
    strategyLabel:SetWidth(overlayW - 60)
    strategyLabel:SetJustifyH("CENTER")

    -- ── Llista d'estratègies (columna dreta) ──────────────────────────────────
    PBM.InstallTieredStratDisplay(menu, className)

    -- ── Barra vertical de 6 botons ────────────────────────────────────────────
    -- Talents / Inventari / Llibre d'hechizos (activar) + Menjar / Botí / Recol·lectar (commutar NC)
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

    -- Fila 1: Talents (activar)
    local talentBtn = MakeLeftBtn(statLine3, "BOTTOMLEFT", 20, -15, "Ability_Marksmanship")
    talentBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Obrir Talents", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Obre la finestra darrere del Tracker", 1, 0.2, 0.2)
        GameTooltip:Show()
    end)
    talentBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    talentBtn:SetScript("OnClick", function()
        local bot = menu.botName or ""
        if PBM.OpenTalentWindow then PBM.OpenTalentWindow(bot) end
    end)

    -- Fila 2: Inventari (activar)
    local invBtn = MakeLeftBtn(talentBtn, "BOTTOMLEFT", 0, -ICON_GAP, "INV_Misc_Bag_08")
    invBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Obrir Inventari", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Obre la finestra darrere del Tracker", 1, 0.2, 0.2)
        GameTooltip:Show()
    end)
    invBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    invBtn:SetScript("OnClick", function()
        local bot = menu.botName or ""
        if PBM.OpenInventoryWindow then PBM.OpenInventoryWindow(bot) end
    end)

    -- Fila 3: Llibre de conjurs (activar)
    local spellBtn = MakeLeftBtn(invBtn, "BOTTOMLEFT", 0, -ICON_GAP, "INV_Misc_Book_09")
    spellBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Obrir Llibre de conjurs", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Obre la finestra darrere del Tracker", 1, 0.2, 0.2)
        GameTooltip:Show()
    end)
    spellBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    spellBtn:SetScript("OnClick", function()
        local bot = menu.botName or ""
        if PBM.OpenSpellbookWindow then PBM.OpenSpellbookWindow(bot) end
    end)

    -- Fila 4: Menjar i Beure (commutar NC)
    local treeFoodBtn = MakeLeftBtn(spellBtn, "BOTTOMLEFT", 0, -ICON_GAP, "INV_Drink_24_SealWhey")
    IconOff(treeFoodBtn)
    treeFoodBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetFrameLevel(menu:GetFrameLevel() + 20)
        GameTooltip:ClearLines()
        GameTooltip:SetText("|cffffcc00Menjar i Beure|r |cff999999- |r|cffC79C3Bfood|r |cff00cc00NC|r", 1, 0.82, 0)
        GameTooltip:AddLine("|cffffcc00Menjar i beure després del combat|r", 1, 1, 1)
        GameTooltip:AddLine("El Bot menja i beu aigua per a restaurar", 1, 1, 1)
        GameTooltip:AddLine("|cffffcc00salut|r i |cff3A8FC4manà|r entre combats.", 1, 1, 1)
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

    -- Fila 5: Botí / Saqueig (commutar NC)
    local treeLootBtn = MakeLeftBtn(treeFoodBtn, "BOTTOMLEFT", 0, -ICON_GAP, "INV_Misc_Coin_16")
    IconOff(treeLootBtn)
    treeLootBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetFrameLevel(menu:GetFrameLevel() + 20)
        GameTooltip:ClearLines()
        GameTooltip:SetText("|cffffcc00Botí|r |cff999999- |r|cffC79C3Bloot|r |cff00cc00NC|r", 1, 0.82, 0)
        GameTooltip:AddLine("|cffffcc00Saquejar cossos automàticament|r", 1, 1, 1)
        GameTooltip:AddLine("El Bot es queda el botí dels enemics morts automàticament.", 1, 1, 1)
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

-- Fila 6: Recol·lectar (commutar NC)
    local treeGatherBtn = MakeLeftBtn(treeLootBtn, "BOTTOMLEFT", 0, -ICON_GAP, "Trade_Mining")
    IconOff(treeGatherBtn)
    treeGatherBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetFrameLevel(menu:GetFrameLevel() + 20)
        GameTooltip:ClearLines()
        GameTooltip:SetText("|cffffcc00Recol·lectar|r |cff999999- |r|cffC79C3Bgather|r |cff00cc00NC|r", 1, 0.82, 0)
        GameTooltip:AddLine("|cffffcc00Recol·lectar nodes de recursos|r", 1, 1, 1)
        GameTooltip:AddLine("El Bot recol·lecta els nodes de recursos propers.", 1, 1, 1)
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

    -- ── Commutador de PvP (universal — apareix a tots els menús de classe) ──
    local PVP_HDR_W = ICON_SIZE + 8   -- La capçalera de 34px centra el botó de 26px
    local pvpHdrOffX = 72              -- Píxels a la dreta de la vora esquerra de talentBtn

    do
        local pvpBox = CreateFrame("Frame", nil, menu)
        pvpBox:SetSize(PVP_HDR_W, 18)
        pvpBox:SetPoint("TOPLEFT", talentBtn, "TOPLEFT", pvpHdrOffX + 11, -15)
        pvpBox:SetBackdrop(OVERLAY_BD)
        pvpBox:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
        pvpBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        local fs = pvpBox:CreateFontString(nil, "OVERLAY")
        fs:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        fs:SetTextColor(0.93, 0.27, 0.20, 1)   -- vermell (ee4433)
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
        GameTooltip:AddLine("Activa la selecció de jugadors com a objectiu.", 1, 1, 1)
        GameTooltip:AddLine("Les rotacions no canvien.", 1, 1, 1)
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

    -- ── Base resetSharedIcons (el fitxer de classe ho estén per als botons de l'arbre) ─
    menu.resetSharedIcons = function()
        IconOff(treeFoodBtn)
        IconOff(treeLootBtn)
        IconOff(treeGatherBtn)
        IconOff(treePvpBtn)
    end

    -- ── Base onStrategyUpdate (gestiona NC food/loot/gather + estat de CO pvp) ─
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
        local race    = msg:match("([%a ]+) %[" )
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
            -- Utilitza el color exacte que el playerbot ha aplicat al recompte de la bossa en el seu xat privat.
            -- rawMsg encara té el codi |cAARRGGBB immediatament abans del valor "N/N".
            local bagHex = rawMsg and rawMsg:match("|c(%x%x%x%x%x%x%x%x)%d+/%d+")
            local colorTag = bagHex and ("|c" .. bagHex) or "|cffFFFFFF"
            menu.statLine2:SetText(colorTag .. used .. "/" .. total .. "|r|cffFFFFFF Bossa|r")
        else
            menu.statLine2:SetText("")
        end
        if dur then
            local t = (tonumber(dur) or 0) / 100
            local r = math.floor(math.min(1, t * 2) * 255)
            local g = math.floor(math.min(1, (1 - t) * 2) * 255)
            menu.statLine3:SetText("|cff" .. string.format("%02x%02x00", r, g) .. dur .. "% Durabilitat|r")
        else
            menu.statLine3:SetText("")
        end
    end

    -- ── Notes inferiors (alineades a l'esquerra, a la dreta de Ignored Spell List, línia única) ──
    local noteFont  = "Fonts\\FRIZQT__.TTF"
    local noteSize  = 9
    local noteColor = { 0.70, 0.70, 0.70, 1 }
    local noteX     = 138   -- Deixa espai per a la llista d'hechizos ignorats de 115px (a x=15) + espaiat

    local note2 = menu:CreateFontString(nil, "OVERLAY")
    note2:SetFont(noteFont, noteSize, "OUTLINE")
    note2:SetTextColor(unpack(noteColor))
    note2:SetWordWrap(false)
    note2:SetJustifyH("LEFT")
    note2:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", noteX, 8)
    note2:SetText("|cffFFD100Nota:|r Durant els trobades de banda, les estratègies es basen en l'especialització i es sobreescriuen automàticament. Per canviar el comportament del bot, utilitza una altra plantilla o especialització.")

    local note1 = menu:CreateFontString(nil, "OVERLAY")
    note1:SetFont(noteFont, noteSize, "OUTLINE")
    note1:SetTextColor(unpack(noteColor))
    note1:SetWordWrap(false)
    note1:SetJustifyH("LEFT")
    note1:SetPoint("BOTTOMLEFT", note2, "TOPLEFT", 0, 4)
    note1:SetText("|cffFFD100Nota:|r La llista d'estratègies de la dreta és la que utilitza realment el bot. Els botons centrals són per a canvis/referència visual. Confirma que la llista reflecteix la teva configuració.")

    local note0 = menu:CreateFontString(nil, "OVERLAY")
    note0:SetFont(noteFont, noteSize, "OUTLINE")
    note0:SetTextColor(unpack(noteColor))
    note0:SetWordWrap(false)
    note0:SetJustifyH("LEFT")
    note0:SetPoint("BOTTOMLEFT", note1, "TOPLEFT", 0, 4)
    note0:SetText("|cffFFD100Nota:|r Per a una configuració ràpida, utilitza el menú Plantilles a la cantonada superior esquerra de cada pestanya de personatge. Això configurarà automàticament tant els talents com les estratègies per a tu.")

    local stratNoteLabel = menu:CreateFontString(nil, "OVERLAY")
    stratNoteLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    stratNoteLabel:SetText("|cffff4444** Les estratègies estan subjectes a canvis.|r")
    stratNoteLabel:SetPoint("BOTTOMLEFT",  menu, "BOTTOMLEFT",   8, 52)
    stratNoteLabel:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -8, 52)
    stratNoteLabel:SetJustifyH("CENTER")

    -- ── Botons de reinici de CO ! / NC ! (a sobre de les notes) ───────────────
    local RESET_BOX_BD = {
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = {left=2, right=2, top=2, bottom=2},
    }
    local resetBtnW   = 26
    local resetBtnH   = 18
    local resetBtnGap = 4
    local resetTotalW = resetBtnW * 2 + resetBtnGap  -- 34px, coincideix amb PVP_HDR_W

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
        GameTooltip:SetText("|cffFFD100Reiniciar estratègies de CO|r")
        GameTooltip:AddLine("Restableix les estratègies de combat als valors per defecte.", 1, 1, 1)
        GameTooltip:AddLine("Les estratègies de fora de combat es mantenen.", 1, 1, 1)
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
        GameTooltip:SetText("|cffFFD100Reiniciar estratègies de NC|r")
        GameTooltip:AddLine("Restableix les estratègies de fora de combat als valors per defecte.", 1, 1, 1)
        GameTooltip:AddLine("Les estratègies de combat es mantenen.", 1, 1, 1)
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

    -- Actualitza la icona d'especialització a partir de les dades de la fila
    local specName = rowData and rowData.spec or ""
    local specIcon = PBM.SPEC_ICONS and PBM.SPEC_ICONS[specName]
    if menu.specBtn then
        menu.specBtn.icon:SetTexture(specIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end

    -- Actualitza la cel·la de professió
    if menu.profCell then
        PBM.RefreshProfCell(menu.profCell, menu.botName or "")
    end

    -- Omple la barra d'equipament a partir de les dades de la fila
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

    -- Neteja la visualització d'estratègies i torna a consultar
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
