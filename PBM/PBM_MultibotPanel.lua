-- ============================================================
--  PBM_MultibotPanel.lua  |  Multibot per-bot controls (vertical)
--
--  Adds a vertical icon-button column to the LEFT side of each
--  class overlay menu.  Clicking any icon either:
--    submenu  — reveals a horizontal submenu to the right
--    activate — executes immediately on click
--    toggle   — toggles on/off with desaturate visual
--
--  Based on MultiBotEvery.lua right-side panel.
--  Excluded: SetTalents, Uninvite, Invite.
--
--  Usage:  PBM.AddMultibotButtons(overlayFrame)
--    Call once inside each class menu's lazy-init block.
--    The overlay must have .botName set before it is shown.
-- ============================================================
PBM = PBM or {}

-- ── Layout constants (match class overlay icon grid) ────────
local ICON_SIZE = 26
local ICON_GAP  = 4
local COL_STEP  = ICON_SIZE + ICON_GAP   -- 30px per row

-- ── Confirmation popup ──────────────────────────────────────
local confirmFrame

local function ShowConfirm(titleText, bodyText, onYes)
    if not confirmFrame then
        confirmFrame = CreateFrame("Frame", "PBMMultibotConfirm", UIParent)
        confirmFrame:SetFrameStrata("TOOLTIP")
        confirmFrame:SetFrameLevel(200)
        confirmFrame:SetSize(300, 110)
        confirmFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
        confirmFrame:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        confirmFrame:SetBackdropColor(0.08, 0.04, 0.04, 0.98)
        confirmFrame:SetBackdropBorderColor(0.78, 0.61, 0.23, 1)
        confirmFrame:Hide()

        local hdr = confirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hdr:SetPoint("TOP", confirmFrame, "TOP", 0, -12)
        confirmFrame._hdr = hdr

        local body = confirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        body:SetPoint("TOP", hdr, "BOTTOM", 0, -4)
        body:SetWidth(270)
        confirmFrame._body = body

        local yBtn = CreateFrame("Button", nil, confirmFrame)
        yBtn:SetSize(120, 24)
        yBtn:SetPoint("BOTTOMLEFT", confirmFrame, "BOTTOMLEFT", 14, 10)
        yBtn:SetFrameLevel(confirmFrame:GetFrameLevel() + 5)
        local yBg = yBtn:CreateTexture(nil, "ARTWORK")
        yBg:SetAllPoints()
        yBg:SetTexture("Interface\\BUTTONS\\WHITE8X8")
        yBg:SetVertexColor(0.1, 0.55, 0.1, 1)
        yBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        local yLbl = yBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        yLbl:SetAllPoints(yBtn); yLbl:SetJustifyH("CENTER")
        yLbl:SetText(PBM_L["Yes"])
        yLbl:SetTextColor(1, 1, 1)
        confirmFrame._yBtn = yBtn

        local nBtn = CreateFrame("Button", nil, confirmFrame)
        nBtn:SetSize(120, 24)
        nBtn:SetPoint("BOTTOMRIGHT", confirmFrame, "BOTTOMRIGHT", -14, 10)
        nBtn:SetFrameLevel(confirmFrame:GetFrameLevel() + 5)
        local nBg = nBtn:CreateTexture(nil, "ARTWORK")
        nBg:SetAllPoints()
        nBg:SetTexture("Interface\\BUTTONS\\WHITE8X8")
        nBg:SetVertexColor(0.6, 0.1, 0.1, 1)
        nBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        local nLbl = nBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nLbl:SetAllPoints(nBtn); nLbl:SetJustifyH("CENTER")
        nLbl:SetText(PBM_L["Cancel"])
        nLbl:SetTextColor(1, 1, 1)
        nBtn:SetScript("OnClick", function() confirmFrame:Hide() end)
    end

    confirmFrame._hdr:SetText("|cffd4af37" .. titleText .. "|r")
    confirmFrame._body:SetText("|cffaaaaaa" .. bodyText .. "|r")
    confirmFrame._yBtn:SetScript("OnClick", function()
        confirmFrame:Hide()
        if onYes then onYes() end
    end)
    confirmFrame:Show()
end

-- ── Button definitions (Talent at top, Misc at bottom) ──────
--
-- btype:
--   "submenu"  — click opens horizontal sub-buttons to the right
--   "activate" — click executes cmd(bot) immediately
--   "toggle"   — click toggles on/off; icon desaturates when off

local BUTTONS = {
    -- ── submenu ─────────────────────────────────────────────
    {
        name = PBM_L["Talent"], icon = "Ability_Marksmanship", btype = "activate",
        tipTitle = PBM_L["Open Talents"],
        cmd = function(bot) PBM.OpenTalentWindow(bot) end,
    },
    -- ── activate ────────────────────────────────────────────
    {
        name = PBM_L["Inv."], icon = "INV_Misc_Bag_08", btype = "activate",
        tipTitle = PBM_L["Open Inventory"],
        cmd = function(bot) PBM.OpenInventoryWindow(bot) end,
    },
    {
        name = PBM_L["Spells"], icon = "INV_Misc_Book_09", btype = "activate",
        tipTitle = PBM_L["Open Spellbook"],
        cmd = function(bot) PBM.OpenSpellbookWindow(bot) end,
    },
}

-- Submenu button sizing (horizontal row items)
local SUB_BTN_W = 58
local SUB_BTN_H = ICON_SIZE   -- same height as icon for alignment

-- ── PBM.AddMultibotButtons(overlay) ─────────────────────────
function PBM.AddMultibotButtons(overlay)
    local activeSubMenu = nil

    local function CloseSubMenu()
        if activeSubMenu then activeSubMenu:Hide(); activeSubMenu = nil end
    end

    overlay._closeMultibotSub = CloseSubMenu

    local NUM = #BUTTONS
    local toggleRefs = {}
    local prevBtn = nil

    for idx, def in ipairs(BUTTONS) do
        local row = NUM - idx  -- last entry at bottom, first at top

        local btn = CreateFrame("Button", nil, overlay)
        btn:SetSize(ICON_SIZE, ICON_SIZE)
        if overlay.statLine3 then
            -- anchor below Durability line (15px gap), then stack downward
            if idx == 1 then
                btn:SetPoint("TOPLEFT", overlay.statLine3, "BOTTOMLEFT", 0, -15)
            else
                btn:SetPoint("TOPLEFT", prevBtn, "BOTTOMLEFT", 0, -ICON_GAP)
            end
        else
            btn:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 15, 15 + row * COL_STEP)
        end
        prevBtn = btn

        -- Icon
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture("Interface\\Icons\\" .. def.icon)
        btn.icon = tex

        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

        -- Toggle state
        btn.state = false

        -- ── Tooltip (common to all types) ───────────────────
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_NONE")
            GameTooltip:SetPoint("LEFT", self, "RIGHT", 5, 0)
            GameTooltip:AddLine(def.tipTitle, 0.78, 0.61, 0.23)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- ── Wire up OnClick based on btype ──────────────────

        if def.btype == "activate" then
            -- Direct action: single click executes
            btn:SetScript("OnClick", function()
                CloseSubMenu()
                local bot = overlay.botName or ""
                def.cmd(bot)
            end)

        elseif def.btype == "toggle" then
            -- Start disabled (greyed out)
            tex:SetDesaturated(1)
            btn.state = false

            if def.stratKey then
                toggleRefs[#toggleRefs + 1] = { btn = btn, tex = tex, stratKey = def.stratKey }
            end

            btn:SetScript("OnClick", function()
                CloseSubMenu()
                overlay._specUserSet = true  -- lock sync (matches Buff/Heal pattern)
                local bot = overlay.botName or ""
                if btn.state then
                    def.offCmd(bot)
                    tex:SetDesaturated(1)
                    btn.state = false
                else
                    def.onCmd(bot)
                    tex:SetDesaturated(nil)
                    btn.state = true
                end
            end)

        elseif def.btype == "submenu" and def.sub then
            -- Horizontal submenu to the right
            local nSub = #def.sub
            local subW = nSub * SUB_BTN_W + (nSub - 1) * 1
            local subH = SUB_BTN_H

            local sub = CreateFrame("Frame", nil, overlay)
            sub:SetSize(subW + 4, subH + 4)
            sub:SetPoint("LEFT", btn, "RIGHT", 4, 0)
            sub:SetFrameLevel(overlay:GetFrameLevel() + 5)
            sub:SetBackdrop({
                bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 8,
                insets = { left = 2, right = 2, top = 2, bottom = 2 },
            })
            sub:SetBackdropColor(0.05, 0.07, 0.14, 0.95)
            sub:SetBackdropBorderColor(0.78, 0.61, 0.23, 1.0)
            sub:Hide()

            local sc = CreateFrame("Frame", nil, sub)
            sc:SetPoint("TOPLEFT",     sub, "TOPLEFT",      2, -2)
            sc:SetPoint("BOTTOMRIGHT", sub, "BOTTOMRIGHT",  -2,  2)

            for j, s in ipairs(def.sub) do
                local sbtn = CreateFrame("Button", nil, sc)
                sbtn:SetSize(SUB_BTN_W, SUB_BTN_H)
                sbtn:SetPoint("TOPLEFT", sc, "TOPLEFT", (j - 1) * (SUB_BTN_W + 1), 0)

                local sbg = sbtn:CreateTexture(nil, "BACKGROUND")
                sbg:SetAllPoints()
                sbg:SetTexture("Interface\\BUTTONS\\WHITE8X8")
                sbg:SetVertexColor(0.05, 0.07, 0.14, 0.8)

                sbtn:SetHighlightTexture("Interface\\BUTTONS\\WHITE8X8")
                sbtn:GetHighlightTexture():SetVertexColor(0.78, 0.61, 0.23, 0.35)

                local stxt = sbtn:CreateFontString(nil, "OVERLAY")
                stxt:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
                stxt:SetAllPoints()
                stxt:SetJustifyH("CENTER")
                stxt:SetText(s.label)
                stxt:SetTextColor(0.78, 0.61, 0.23, 1.0)

                sbtn:SetScript("OnClick", function()
                    local bot = overlay.botName or ""
                    s.cmd(bot)
                    if not s.confirm then
                        CloseSubMenu()
                    end
                end)

                sbtn:SetScript("OnEnter", function(self2)
                    GameTooltip:SetOwner(self2, "ANCHOR_TOP")
                    GameTooltip:AddLine(s.tip, 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                sbtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

                if j < nSub then
                    local vl = sc:CreateTexture(nil, "OVERLAY")
                    vl:SetWidth(1)
                    vl:SetPoint("TOPLEFT",    sbtn, "TOPRIGHT",    0, 0)
                    vl:SetPoint("BOTTOMLEFT", sbtn, "BOTTOMRIGHT", 0, 0)
                    vl:SetTexture("Interface\\BUTTONS\\WHITE8X8")
                    vl:SetVertexColor(0.78, 0.61, 0.23, 1.0)
                end
            end

            btn:SetScript("OnClick", function()
                if activeSubMenu == sub then
                    CloseSubMenu()
                else
                    CloseSubMenu()
                    sub:Show()
                    activeSubMenu = sub
                end
            end)
        end
    end

    -- Wrap onStrategyUpdate to sync NC toggle states from bot replies
    local _prevSU = overlay.onStrategyUpdate
    overlay.onStrategyUpdate = function(stratType, activeSet)
        if _prevSU then _prevSU(stratType, activeSet) end
        if stratType == "nc" and not overlay._specUserSet then
            for _, t in ipairs(toggleRefs) do
                if activeSet[t.stratKey] then
                    t.tex:SetDesaturated(nil); t.btn.state = true
                else
                    t.tex:SetDesaturated(1);   t.btn.state = false
                end
            end
        end
    end

    -- Extend reset functions to reset multibot toggles before each new bot query
    -- (classes use either resetRoleIcons or resetAllIcons — wrap both)
    local function resetToggles()
        for _, t in ipairs(toggleRefs) do
            t.tex:SetDesaturated(1); t.btn.state = false
        end
    end

    local _prevReset = overlay.resetRoleIcons
    overlay.resetRoleIcons = function()
        if _prevReset then _prevReset() end
        resetToggles()
    end

    local _prevResetAll = overlay.resetAllIcons
    overlay.resetAllIcons = function()
        if _prevResetAll then _prevResetAll() end
        resetToggles()
    end

    overlay._lastMultibotBtn = prevBtn
end