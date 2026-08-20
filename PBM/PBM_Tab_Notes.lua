PBM = PBM or {}

-- ── Notes tab panel ────────────────────────────────────────────
-- Three user-labelled, free-form columns saved to
-- LichborneTrackerDB.notesCols[1..3] = { title="", text="" }
-- Scroll is mouse-wheel only — no scrollbar chrome.
-- Called from PBM_TopTabs.lua as: PBM.BuildNotesPanel(pf, ctx)

function PBM.BuildNotesPanel(pf, ctx)
    local pfl  = pf:GetFrameLevel()
    local FONT = ctx.FONT

    -- ── Layout constants ──────────────────────────────────────
    -- Panel: 1086 × 512, header already drawn at 24 px.
    local MARGIN  = 12
    local HDR_H   = 24
    local PAD     = 6
    local TITLE_H = 24
    local COL_W   = math.floor((1086 - MARGIN * 2 - MARGIN * 2) / 3)  -- 346
    local COL_H   = 512 - HDR_H - MARGIN * 2                          -- 464

    local sfW  = COL_W - PAD * 2   -- 334
    local ebW  = sfW - 2           -- 332

    local sfOffY = PAD + TITLE_H + 3 + 1 + 4   -- 38 px from col top
    local sfH    = COL_H - sfOffY - PAD         -- 420 px

    -- ── Ensure DB per-column structure ────────────────────────
    if not LichborneTrackerDB.notesCols then
        LichborneTrackerDB.notesCols = {}
    end
    for i = 1, 3 do
        if not LichborneTrackerDB.notesCols[i] then
            LichborneTrackerDB.notesCols[i] = { title = "", text = "" }
        end
    end

    -- ── Build three columns ───────────────────────────────────
    for i = 1, 3 do
        local db   = LichborneTrackerDB.notesCols[i]
        local colX = MARGIN + (i - 1) * (COL_W + MARGIN)
        local colY = -(HDR_H + MARGIN)

        local col = CreateFrame("Frame", nil, pf)
        col:SetPoint("TOPLEFT", pf, "TOPLEFT", colX, colY)
        col:SetSize(COL_W, COL_H)
        col:SetFrameLevel(pfl + 1)
        col:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left = 2, right = 2, top = 2, bottom = 2},
        })
        col:SetBackdropColor(0.05, 0.07, 0.15, 1)
        col:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.6)

        -- ── Column title (single-line, user-editable) ─────────
        local HINT_TEXT  = PBM_L["Column Title..."]
        local HINT_R, HINT_G, HINT_B = 0.38, 0.38, 0.38
        local REAL_R, REAL_G, REAL_B = 0.78, 0.61, 0.23

        local titleEB = CreateFrame("EditBox", "PBMNotesTitleEB"..i, col)
        titleEB:SetPoint("TOPLEFT",  col, "TOPLEFT",  PAD, -PAD)
        titleEB:SetPoint("TOPRIGHT", col, "TOPRIGHT", -PAD, -PAD)
        titleEB:SetHeight(TITLE_H)
        titleEB:SetFont(FONT, 11, "OUTLINE")
        titleEB:SetJustifyH("CENTER")
        titleEB:SetAutoFocus(false)
        titleEB:EnableMouse(true)
        titleEB:SetMaxLetters(64)
        titleEB:SetFrameLevel(pfl + 3)
        titleEB:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            tile = true, tileSize = 8,
            insets = {left = 2, right = 2, top = 2, bottom = 2},
        })
        titleEB:SetBackdropColor(0.07, 0.09, 0.20, 1)

        local savedTitle = db.title or ""
        if savedTitle == "" then
            titleEB:SetText(HINT_TEXT)
            titleEB:SetTextColor(HINT_R, HINT_G, HINT_B, 1)
        else
            titleEB:SetText(savedTitle)
            titleEB:SetTextColor(REAL_R, REAL_G, REAL_B, 1)
        end
        titleEB:SetCursorPosition(0)

        titleEB:SetScript("OnEditFocusGained", function(self)
            if self:GetText() == HINT_TEXT then
                self:SetText("")
                self:SetTextColor(REAL_R, REAL_G, REAL_B, 1)
            end
        end)
        titleEB:SetScript("OnEditFocusLost", function(self)
            if self:GetText() == "" then
                self:SetText(HINT_TEXT)
                self:SetTextColor(HINT_R, HINT_G, HINT_B, 1)
                LichborneTrackerDB.notesCols[i].title = ""
            end
        end)
        titleEB:SetScript("OnTextChanged", function(self, userInput)
            if not userInput then return end
            local t = self:GetText()
            if t ~= HINT_TEXT then
                LichborneTrackerDB.notesCols[i].title = t
            end
        end)
        titleEB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        titleEB:SetScript("OnEscapePressed", function(self)
            if self:GetText() == "" then
                self:SetText(HINT_TEXT)
                self:SetTextColor(HINT_R, HINT_G, HINT_B, 1)
            end
            self:ClearFocus()
        end)

        -- Gold divider under title
        local div = col:CreateTexture(nil, "ARTWORK")
        div:SetPoint("TOPLEFT",  titleEB, "BOTTOMLEFT",  0, -3)
        div:SetPoint("TOPRIGHT", titleEB, "BOTTOMRIGHT", 0, -3)
        div:SetHeight(1)
        div:SetTexture(0.78, 0.61, 0.23, 0.45)

        -- ── Plain ScrollFrame — mouse-wheel only, no chrome ───
        local sf = CreateFrame("ScrollFrame", "PBMNotesSF"..i, col)
        sf:SetPoint("TOPLEFT", col, "TOPLEFT", PAD, -sfOffY)
        sf:SetSize(sfW, sfH)
        sf:SetFrameLevel(pfl + 2)
        sf:EnableMouseWheel(true)
        sf:SetScript("OnMouseWheel", function(self, delta)
            local cur = self:GetVerticalScroll()
            local rng = self:GetVerticalScrollRange()
            self:SetVerticalScroll(math.max(0, math.min(rng, cur - delta * 20)))
        end)

        -- Multiline EditBox as scroll child
        local NOTE_HINT  = PBM_L["Click here to add a note..."]
        local NOTE_HR, NOTE_HG, NOTE_HB = 0.38, 0.38, 0.38
        local NOTE_RR, NOTE_RG, NOTE_RB = 0.78, 0.61, 0.23

        local eb = CreateFrame("EditBox", "PBMNotesEB"..i, sf)
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false)
        eb:SetFont(FONT, 10, "OUTLINE")
        eb:SetWidth(ebW)
        eb:SetHeight(2000)
        eb:EnableMouse(true)
        eb:SetFrameLevel(pfl + 4)
        eb:SetMaxLetters(0)

        sf:SetScrollChild(eb)

        local savedText = db.text or ""
        if savedText == "" then
            eb:SetText(NOTE_HINT)
            eb:SetTextColor(NOTE_HR, NOTE_HG, NOTE_HB, 1)
        else
            eb:SetText(savedText)
            eb:SetTextColor(NOTE_RR, NOTE_RG, NOTE_RB, 1)
        end
        eb:SetCursorPosition(0)

        eb:SetScript("OnEditFocusGained", function(self)
            if self:GetText() == NOTE_HINT then
                self:SetText("")
                self:SetTextColor(NOTE_RR, NOTE_RG, NOTE_RB, 1)
            end
        end)
        eb:SetScript("OnEditFocusLost", function(self)
            if self:GetText() == "" then
                self:SetText(NOTE_HINT)
                self:SetTextColor(NOTE_HR, NOTE_HG, NOTE_HB, 1)
                LichborneTrackerDB.notesCols[i].text = ""
            end
        end)
        eb:SetScript("OnTextChanged", function(self, userInput)
            if not userInput then return end
            local t = self:GetText()
            if t ~= NOTE_HINT then
                LichborneTrackerDB.notesCols[i].text = t
            end
        end)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    end
end