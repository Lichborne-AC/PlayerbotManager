-- ============================================================
--  LBT_Core.lua  |  Entry point, main frame, event handlers, slash commands
-- ============================================================
PBM = PBM or {}
PBM.State = PBM.State or {}

PBM.State.setupDone      = false
PBM.State.frameBgBuilt   = false

-- ── Lichborne Output helper ───────────────────────────────────
-- Writes a message to the in-frame output box instead of chat.
-- Falls back gracefully if the frame hasn't been built yet.
LichborneOutput = function(msg, r, g, b)
    local sf = _G["LichborneOutputMsgFrame"]
    if sf then
        sf:AddMessage(msg, r or 1, g or 0.85, b or 0)
    end
end

local function OnFirstShow()
    if PBM.State.setupDone then return end
    PBM.State.setupDone = true
    local f = LichborneTrackerFrame
    local fl = f:GetFrameLevel()

    -- Tabs (centered in frame)
    local tabFrame = CreateFrame("Frame", "LichborneTabBar", f)
    tabFrame:SetPoint("TOP", f, "TOP", 0, -36)
    tabFrame:SetSize(1090, 28)
    tabFrame:SetFrameLevel(fl + 8)
    local tabW = 1090 / #PBM.CLASS_TABS
    for i, cls in ipairs(PBM.CLASS_TABS) do
        local btn = CreateFrame("Button", "LichborneTab"..i, tabFrame)
        btn:SetSize(tabW - 1, 26)
        btn:SetPoint("LEFT", tabFrame, "LEFT", (i-1)*tabW, 0)
        btn:SetFrameLevel(fl + 9)
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(btn); bg:SetTexture(0.05, 0.07, 0.12, 1)
        btn.bg = bg
        local bl = btn:CreateTexture(nil, "OVERLAY")
        bl:SetHeight(3); bl:SetWidth(tabW-1)
        bl:SetPoint("BOTTOM", btn, "BOTTOM", 0, 0)
        bl:SetTexture(0, 0, 0, 0)
        btn.bottomLine = bl
        local cc = PBM.CLASS_COLORS[cls]
        local hex
        if cls == "Raid" or cls == "Overview" then
            hex = cls == "Overview" and "|cffd4af37" or "|cffC69B3A"
        elseif cls == "Group" then
            hex = "|cff248FFF"   -- blue matching Invite Group button hue
        elseif cls == "Settings" then
            hex = "|cff7799ff"
        else
            hex = cc and string.format("|cff%02x%02x%02x",math.floor(cc.r*255),math.floor(cc.g*255),math.floor(cc.b*255)) or "|cffdddddd"
        end
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints(btn); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
        lbl:SetText(hex..(PBM.TAB_BUTTON_LABELS[cls] or PBM.TAB_LABELS[cls] or cls).."|r")
        btn:SetScript("OnClick", function()
            PBM.State.activeTab = cls
            PBM.UpdateTabs()
            PBM.RefreshRows()
        end)
        btn:SetScript("OnEnter", function()
            btn:SetAlpha(1.0)
            if cls ~= PBM.State.activeTab then
                local c = PBM.CLASS_COLORS[cls]
                if c then
                    btn.bg:SetTexture(c.r*0.3, c.g*0.3, c.b*0.3, 1)
                    btn.bottomLine:SetTexture(c.r, c.g, c.b, 0.6)
                elseif cls == "Raid" then
                    btn.bg:SetTexture(0.28, 0.15, 0.00, 1)
                    btn.bottomLine:SetTexture(0.70, 0.36, 0.00, 0.6)
                elseif cls == "Overview" then
                    btn.bg:SetTexture(0.14, 0.30, 0.14, 1)
                    btn.bottomLine:SetTexture(0.40, 0.90, 0.40, 0.6)
                elseif cls == "Group" then
                    btn.bg:SetTexture(0.035, 0.14, 0.245, 1)
                    btn.bottomLine:SetTexture(0.14, 0.56, 1.0, 0.6)
                elseif cls == "Settings" then
                    btn.bg:SetTexture(0.14, 0.18, 0.30, 1)
                    btn.bottomLine:SetTexture(0.467, 0.600, 1.000, 0.6)
                end
            end
        end)
        btn:SetScript("OnLeave", function()
            if cls ~= PBM.State.activeTab then
                btn:SetAlpha(0.5)
                btn.bg:SetTexture(0.05, 0.07, 0.12, 1)
                btn.bottomLine:SetTexture(0, 0, 0, 0)
            end
        end)
        PBM.State.tabButtons[cls] = btn
    end
    PBM.UpdateTabs()

    -- Column headers
    local hf = CreateFrame("Frame", "LichborneHeaderBar", f)
    hf:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -66)
    hf:SetSize(1086, 20)
    hf:SetFrameLevel(fl + 10)
    local hbg = hf:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints(hf); hbg:SetTexture(0.08, 0.20, 0.42, 1)

    -- Gold border wrapping header through count bar
    local contentBorder = CreateFrame("Frame", nil, f)
    contentBorder:SetPoint("TOPLEFT", f, "TOPLEFT", 13, -64)
    contentBorder:SetSize(1090, 518)
    contentBorder:SetFrameLevel(fl + 9)
    contentBorder:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    contentBorder:SetBackdropColor(0, 0, 0, 0)
    contentBorder:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    local function H(lbl, x, w)
        local fs = hf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", hf, "LEFT", x, 0)
        fs:SetWidth(w); fs:SetJustifyH("CENTER")
        fs:SetText("|cffd4af37"..lbl.."|r")
    end
    local function SH(lbl, x, w, key, isNumeric)
        local btn = CreateFrame("Button", nil, hf)
        btn:SetPoint("TOPLEFT", hf, "TOPLEFT", x, 0)
        btn:SetSize(w, 20); btn:SetFrameLevel(hf:GetFrameLevel() + 2)
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetAllPoints(btn); fs:SetJustifyH("CENTER"); fs:SetJustifyV("MIDDLE")
        fs:SetText("|cffd4af37"..lbl.."|r")
        PBM.State.classSortHdrs[key] = {lbl = lbl, fs = fs}
        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM")
            GameTooltip:AddLine("Click to sort", 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function()
            local cls = PBM.State.activeTab
            if PBM.State.classSortKey[cls] == key then
                PBM.State.classSortAsc[cls] = not PBM.State.classSortAsc[cls]
            else
                PBM.State.classSortKey[cls] = key
                PBM.State.classSortAsc[cls] = not isNumeric
            end
            PBM.UpdateClassSortHeaders()
            PBM.RefreshRows()
        end)
    end
    do
        local fs = hf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", hf, "TOPLEFT", PBM.DRAG_OFF, 0)
        fs:SetSize(18, 20); fs:SetJustifyH("CENTER"); fs:SetJustifyV("MIDDLE")
        fs:SetText("|cffd4af37#|r")
    end
    local specHdr = hf:CreateTexture(nil, "OVERLAY")
    specHdr:SetPoint("LEFT", hf, "LEFT", PBM.SPEC_OFF + 1, 0)
    specHdr:SetSize(PBM.COL_SPEC_W - 2, 18)
    specHdr:SetTexture("Interface\\Icons\\Ability_Rogue_Deadliness")
    SH("Spec", PBM.SPEC_OFF - 4, PBM.COL_SPEC_W + 12, "spec", false)
    SH("Name", PBM.NAME_OFF - 4, PBM.COL_NAME_W - 40, "name", false)
    SH("iLvL", PBM.GS_OFF+2,    PBM.COL_GS_W-4,       "ilvl", true)
    SH("GS",   PBM.REALGS_OFF+2, PBM.COL_GS_W-4,      "gs",   true)
    local needsProfHdrFs = hf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    needsProfHdrFs:SetPoint("LEFT", hf, "LEFT", PBM.NEEDS_OFF+2, 0)
    needsProfHdrFs:SetWidth(PBM.COL_NEEDS_W-4); needsProfHdrFs:SetJustifyH("CENTER")
    needsProfHdrFs:SetText("|cffd4af37Prof|r")
    PBM.State.needsProfHdrLabel = needsProfHdrFs
    for g, a in ipairs(PBM.SLOT_ABBR) do SH(a, PBM.GEAR_OFF+(g-1)*PBM.COL_GEAR_W, PBM.COL_GEAR_W, "gear_"..g, true) end

    -- Build row frames parented directly to main frame, below headers
    PBM.BuildRows(f, -90)
    PBM.BuildIgnoredSpellTable()

    -- Mouse wheel scrolling for class tabs
    local function ClassTabScrollWheel(delta)
        if PBM.State.activeTab == "Raid" or PBM.State.activeTab == "Overview" then return end
        local cls = PBM.State.activeTab
        local offset = PBM.State.classScroll[cls] or 0
        local count = 0
        for _, r in ipairs(LichborneTrackerDB.rows) do
            if r.cls == cls and r.name and r.name ~= "" then count = count + 1 end
        end
        local maxOffset = math.max(0, count - PBM.MAX_ROWS)
        PBM.State.classScroll[cls] = math.max(0, math.min(offset - delta, maxOffset))
        PBM.RefreshRows()
    end
    for _, rowFr in ipairs(PBM.State.rowFrames) do
        rowFr:EnableMouseWheel(true)
        rowFr:SetScript("OnMouseWheel", function(_, delta) ClassTabScrollWheel(delta) end)
    end
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(_, delta) ClassTabScrollWheel(delta) end)


    -- Avg iLvl bar
    local avgFrame = CreateFrame("Frame", "LichborneAvgBar", f)
    LichborneAvgBar = avgFrame
    avgFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -530)
    avgFrame:SetSize(1086, 24)
    avgFrame:SetFrameLevel(fl + 10)
    local avgbg = avgFrame:CreateTexture(nil, "BACKGROUND")
    avgbg:SetAllPoints(avgFrame); avgbg:SetTexture(0.05, 0.07, 0.13, 1)
    local avgTitle = avgFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    avgTitle:SetPoint("LEFT", avgFrame, "LEFT", 4, 0)
    avgTitle:SetText("|cffC69B3AAvg iLvL:|r"); avgTitle:SetWidth(52)
    LichborneAvgSwatches = {}
    -- Roster block is 130px wide, 4px gap, label is 56px: swatches fill 1086-56-4-130 = 896px for 10 classes
    local rosterBlockW = 130
    local swTotalW = 1086 - 56 - 4 - rosterBlockW
    local swW = swTotalW / 10
    local avgIdx = 0
    for i, cls in ipairs(PBM.CLASS_TABS) do
        if cls == "Raid" or cls == "Group" then break end
        avgIdx = avgIdx + 1
        local c = PBM.CLASS_COLORS[cls]
        local sw = CreateFrame("Button", "LichborneAvgSwatch"..avgIdx, avgFrame)
        sw:SetSize(swW - 2, 20)
        sw:SetPoint("LEFT", avgFrame, "LEFT", 56 + (avgIdx-1)*swW, 0)
        sw:SetFrameLevel(avgFrame:GetFrameLevel() + 1)
        local swbg = sw:CreateTexture(nil, "BACKGROUND")
        swbg:SetAllPoints(sw); swbg:SetTexture(0.08, 0.10, 0.18, 1); sw.bg = swbg
        local hex = string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255))
        local lbl = sw:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints(sw); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
        lbl:SetText(hex..(PBM.TAB_LABELS[cls])..": |cff555555--|r"); sw.lbl = lbl; sw.cls = cls
        sw:EnableMouse(true)
        sw:SetScript("OnEnter", function()
            GameTooltip:SetOwner(sw, "ANCHOR_TOP")
            local avg = PBM.GetClassAvgIlvl(cls)
            GameTooltip:AddLine(PBM.TAB_LABELS[cls], c.r, c.g, c.b)
            GameTooltip:AddLine("Average item level of all tracked "..PBM.TAB_LABELS[cls].."s.", 1,1,1)
            if avg > 0 then
                GameTooltip:AddLine("Current: |cffd4af37"..avg.."|r", 1,1,1)
            else
                GameTooltip:AddLine("No gear data yet.", 0.6,0.6,0.6)
            end
            GameTooltip:AddLine("Click to switch to this tab.", 0.5,0.5,0.5)
            GameTooltip:Show()
        end)
        sw:SetScript("OnLeave", function() GameTooltip:Hide() end)
        sw:SetScript("OnClick", function()
            PBM.State.activeTab = cls
            PBM.UpdateTabs()
            PBM.RefreshRows()
        end)
        LichborneAvgSwatches[i] = sw
    end

    -- Roster iLvl block — right-anchored, gold border, fills remaining space
    local rosterIlvlBlock = CreateFrame("Frame", "LichborneRosterIlvlBlock", avgFrame)
    rosterIlvlBlock:SetPoint("RIGHT", avgFrame, "RIGHT", 0, 0)
    rosterIlvlBlock:SetSize(rosterBlockW, 24)
    rosterIlvlBlock:SetFrameLevel(avgFrame:GetFrameLevel() + 1)
    rosterIlvlBlock:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=8,
        insets={left=2,right=2,top=2,bottom=2}
    })
    rosterIlvlBlock:SetBackdropColor(0.05, 0.07, 0.13, 1)
    rosterIlvlBlock:SetBackdropBorderColor(0.78, 0.61, 0.23, 1.0)
    local rosterIlvlLbl = rosterIlvlBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rosterIlvlLbl:SetAllPoints(rosterIlvlBlock)
    rosterIlvlLbl:SetJustifyH("CENTER"); rosterIlvlLbl:SetJustifyV("MIDDLE")
    rosterIlvlLbl:SetText("|cffC69B3ARoster iLvL:|r |cff555555--|r")
    PBM.State.LichborneRosterIlvlLabel = rosterIlvlLbl
    rosterIlvlBlock:EnableMouse(true)
    rosterIlvlBlock:SetScript("OnEnter", function()
        GameTooltip:SetOwner(rosterIlvlBlock, "ANCHOR_TOP")
        GameTooltip:AddLine("Roster Avg iLvL", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Average item level across your", 1,1,1)
        GameTooltip:AddLine("entire tracked roster.", 1,1,1)
        GameTooltip:Show()
    end)
    rosterIlvlBlock:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- ── Filters label ──────────────────────────────────────────
    local filtersLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filtersLbl:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 497, 152)
    filtersLbl:SetJustifyH("LEFT")
    filtersLbl:SetText("|cffC69B3AFilters:|r")

    -- ── Info/Help label (between last filter and help icons) ──────
    local infoHelpLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoHelpLbl:SetJustifyH("LEFT")
    infoHelpLbl:SetText("|cffC69B3AHelp:|r")

    -- ── Admin label (between overview help icon and import button) ─
    local adminLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    adminLbl:SetJustifyH("LEFT")
    adminLbl:SetText("|cffC69B3AMenu:|r")

    -- ── Add Target button ──────────────────────────────────────
    local addBtn = CreateFrame("Button", "LichborneAddTargetBtn", f)
    addBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 144)
    addBtn:SetSize(155, 29)
    addBtn:SetFrameLevel(fl + 12)
    addBtn:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=8,
        insets={left=2,right=2,top=2,bottom=2}
    })
    addBtn:SetBackdropColor(0.10*0.35, 0.40*0.35, 0.70*0.35, 1)
    addBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    local addBtnLabel = addBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addBtnLabel:SetAllPoints(addBtn)
    addBtnLabel:SetJustifyH("CENTER"); addBtnLabel:SetJustifyV("MIDDLE")
    addBtnLabel:SetText("|cffd4af37+ Add Target|r")
    addBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    -- LichborneAddStatus is created inside outputBox after it is built (see below)

    addBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(addBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("+ Add Target", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Adds target to tracker.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    addBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Shared helper used by Add Target and Target Strategies buttons.
    -- Returns name, isNew on success; nil on invalid target.
    local function AddTargetToTracker()
        if not UnitExists("target") or not UnitIsPlayer("target") then
            LichborneAddStatus:SetText("|cffff4444No player targeted.|r")
            return nil
        end
        local targetName = UnitName("target")
        local _, targetClass = UnitClass("target")
        local cls = targetClass and PBM.CLASS_TOKEN_MAP[targetClass]
        if not cls then
            LichborneAddStatus:SetText("|cffff4444Unknown class: "..(targetClass or "nil").."|r")
            return nil
        end
        local c = PBM.CLASS_COLORS[cls]
        local hex = string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255))
        PBM.EnsureClass(cls)
        local indices = PBM.GetAllClassRows(cls)
        for _, di in ipairs(indices) do
            local row = LichborneTrackerDB.rows[di]
            if row.name and row.name:lower() == targetName:lower() then
                LichborneTrackerDB.rows[di].level = UnitLevel("target")
                if PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames > 0 then PBM.RefreshOverviewRows() end
                if PBM.State.rowFrames and #PBM.State.rowFrames > 0 then PBM.RefreshRows() end
                return targetName, false
            end
        end
        local slot = nil
        for _, di in ipairs(indices) do
            local row = LichborneTrackerDB.rows[di]
            if not row.name or row.name == "" then slot = di; break end
        end
        if not slot then
            table.insert(LichborneTrackerDB.rows, PBM.DefaultRow(cls))
            slot = #LichborneTrackerDB.rows
        end
        LichborneTrackerDB.rows[slot].name = targetName
        LichborneTrackerDB.rows[slot].level = UnitLevel("target")
        LichborneOutput("|cffC69B3APBM:|r Added "..hex..targetName.."|r ("..cls..")", 1, 0.85, 0)
        if PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames > 0 then PBM.RefreshOverviewRows() end
        if PBM.State.rowFrames and #PBM.State.rowFrames > 0 then PBM.RefreshRows() end
        return targetName, true
    end

    addBtn:SetScript("OnClick", function()
        local name, isNew = AddTargetToTracker()
        if not name then return end
        local _, targetClass = UnitClass("target")
        local cls = targetClass and PBM.CLASS_TOKEN_MAP[targetClass]
        local c = cls and PBM.CLASS_COLORS[cls]
        local hex = c and string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255)) or ""
        if isNew then
            LichborneAddStatus:SetText(hex..name.."|r added to Overview tab.")
        else
            LichborneAddStatus:SetText(hex..name.."|r already in tracker. Level updated.")
        end
    end)

    -- ── Add Group button ───────────────────────────────────────
    local SetScanActive, AddGroupMembers
    local activeInspectFrame = nil  -- shared by all scan phases; Stop button kills it

    local addGroupBtn = CreateFrame("Button", "LichborneAddGroupBtn", f)
    addGroupBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 175, 144)
    addGroupBtn:SetSize(155, 29)
    addGroupBtn:SetFrameLevel(fl + 12)
    addGroupBtn:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=8,
        insets={left=2,right=2,top=2,bottom=2}
    })
    addGroupBtn:SetBackdropColor(0.10*0.35, 0.40*0.35, 0.70*0.35, 1)
    addGroupBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    local addGroupLbl = addGroupBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addGroupLbl:SetAllPoints(addGroupBtn); addGroupLbl:SetJustifyH("CENTER"); addGroupLbl:SetJustifyV("MIDDLE")
    addGroupLbl:SetText("|cffd4af37+ Add Group|r")
    addGroupBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    addGroupBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(addGroupBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("+ Add Group", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Adds group to tracker.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    addGroupBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    addGroupBtn:SetScript("OnClick", function()
        if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
            if LichborneAddStatus then
                LichborneAddStatus:SetText("|cffff4444Not in a group, or no other members found.|r")
            end
            return
        end
        SetScanActive(true)
        AddGroupMembers(function(added, skipped)
            SetScanActive(false)
            if LichborneAddStatus then
                local lvlNote = skipped > 0 and " Levels updated." or ""
                LichborneAddStatus:SetText("|cff44ff44Added "..added.." new, skipped "..skipped.." duplicates."..lvlNote.."|r")
            end
            LichborneOutput("|cffC69B3APBM:|r Group scan complete. Added: "..added..", Skipped: "..skipped..(skipped > 0 and ". Levels updated." or ""), 1, 0.85, 0)
        end)
    end)

    -- ── Shared helper: silently add all group members to tracker ──
    AddGroupMembers = function(onDone)
        local playerName = UnitName("player")
        local members = {}
        local _, selfClsKey = UnitClass("player")
        members[#members+1] = {name=playerName, clsKey=selfClsKey, level=UnitLevel("player")}
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                local unit = "raid"..i
                if UnitExists(unit) and UnitName(unit) ~= playerName then
                    local name2 = UnitName(unit)
                    local _, clsKey = UnitClass(unit)
                    members[#members+1] = {name=name2, clsKey=clsKey, level=UnitLevel(unit)}
                end
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                local unit = "party"..i
                if UnitExists(unit) then
                    local name2 = UnitName(unit)
                    local _, clsKey = UnitClass(unit)
                    members[#members+1] = {name=name2, clsKey=clsKey, level=UnitLevel(unit)}
                end
            end
        end
        local toProcess = {}
        for _, m in ipairs(members) do
            local cls = m.clsKey and PBM.CLASS_TOKEN_MAP[m.clsKey]
            if cls then toProcess[#toProcess+1] = {name=m.name, cls=cls, level=m.level or 0} end
        end
        if #toProcess == 0 then
            if onDone then onDone(0, 0) end
            return
        end
        local addIdx, addWait, addedCount, skippedCount = 1, 0, 0, 0
        local agFrame = CreateFrame("Frame")
        activeInspectFrame = agFrame
        agFrame:SetScript("OnUpdate", function(_, elapsed)
            addWait = addWait + elapsed
            if addWait < 0.15 then return end
            addWait = 0
            if addIdx > #toProcess then
                agFrame:SetScript("OnUpdate", nil)
                if activeInspectFrame == agFrame then activeInspectFrame = nil end
                PBM.RefreshRows()
                if PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames > 0 then PBM.RefreshOverviewRows() end
                if onDone then onDone(addedCount, skippedCount) end
                return
            end
            local m = toProcess[addIdx]; addIdx = addIdx + 1
            PBM.EnsureClass(m.cls)
            local indices = PBM.GetAllClassRows(m.cls)
            for _, di in ipairs(indices) do
                local row = LichborneTrackerDB.rows[di]
                if row.name and row.name:lower() == m.name:lower() then
                    LichborneTrackerDB.rows[di].level = m.level or 0
                    skippedCount = skippedCount + 1; return
                end
            end
            local slot = nil
            for _, di in ipairs(indices) do
                local row = LichborneTrackerDB.rows[di]
                if not row.name or row.name == "" then slot = di; break end
            end
            if not slot then
                table.insert(LichborneTrackerDB.rows, PBM.DefaultRow(m.cls))
                slot = #LichborneTrackerDB.rows
            end
            LichborneTrackerDB.rows[slot].name = m.name
            LichborneTrackerDB.rows[slot].level = m.level or 0
            addedCount = addedCount + 1
        end)
    end

    -- ── Helper: make a tracker button ──────────────────────────
    local function MakeTrackerBtn(name, x, y, w, h, br, bg2, bb, label)
        local btn = CreateFrame("Button", name, f)
        btn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, y)
        btn:SetSize(w, h); btn:SetFrameLevel(fl+12)
        btn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
        btn:SetBackdropColor(br*0.35,bg2*0.35,bb*0.35,1); btn:SetBackdropBorderColor(0.78,0.61,0.23,0.9)
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        local lbl=btn:CreateFontString(nil,"OVERLAY","GameFontNormal"); lbl:SetAllPoints(btn); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
        lbl:SetText(label)
        return btn
    end

    -- ── Update Target GS (row y=78, left) ────────────────────
    local gsBtn = MakeTrackerBtn("LichborneUpdateGSBtn", 15, 110, 155, 29, 0.10, 0.40, 0.70, "|cffd4af37+ Add Target Gear|r")
    gsBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(gsBtn,"ANCHOR_TOP"); GameTooltip:AddLine("+ Add Target Gear",0.78,0.61,0.23)
        GameTooltip:AddLine("Adds target's gear.",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    gsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    gsBtn:SetScript("OnClick", function()
        if not UnitExists("target") or not UnitIsPlayer("target") then LichborneAddStatus:SetText("|cffff4444No player targeted.|r"); return end
        local targetName = UnitName("target")
        local _, targetClassGS = UnitClass("target")
        local clsGS = targetClassGS and PBM.CLASS_TOKEN_MAP[targetClassGS]
        -- Add to tracker if not already there
        local foundDi = nil
        for i, row in ipairs(LichborneTrackerDB.rows) do
            if row.name and row.name:lower() == targetName:lower() then foundDi = i; break end
        end
        if not foundDi then
            if not clsGS then LichborneAddStatus:SetText("|cffff4444Unknown class for "..targetName.."|r"); return end
            PBM.EnsureClass(clsGS)
            local idxs = PBM.GetAllClassRows(clsGS)
            for _, di in ipairs(idxs) do
                local row = LichborneTrackerDB.rows[di]
                if not row.name or row.name == "" then foundDi = di; break end
            end
            if not foundDi then
                table.insert(LichborneTrackerDB.rows, PBM.DefaultRow(clsGS))
                foundDi = #LichborneTrackerDB.rows
            end
            LichborneTrackerDB.rows[foundDi].name = targetName
            LichborneTrackerDB.rows[foundDi].level = UnitLevel("target")
            if PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames > 0 then PBM.RefreshOverviewRows() end
            local cA = PBM.CLASS_COLORS[clsGS]; local hA = cA and string.format("|cff%02x%02x%02x",math.floor(cA.r*255),math.floor(cA.g*255),math.floor(cA.b*255)) or "|cffffffff"
            LichborneOutput("|cffC69B3APBM:|r Added "..hA..targetName.."|r to tracker.", 1, 0.85, 0)
        end
        local rowData = LichborneTrackerDB.rows[foundDi]
        local c = PBM.CLASS_COLORS[rowData.cls or ""]; local hex = c and string.format("|cff%02x%02x%02x",math.floor(c.r*255),math.floor(c.g*255),math.floor(c.b*255)) or "|cffffffff"
        LichborneAddStatus:SetText("Updating Gear for "..hex..targetName.."|r...")
        LichborneOutput("|cffC69B3APBM:|r Updating Gear for "..hex..targetName.."|r...", 1, 0.85, 0)
        local gsDi = foundDi
        -- Lock all buttons (including Stop and invite) during single-target scan
        SetScanActive(true)
        local stopBtn = _G["LichborneStopInspectBtn"]
        if stopBtn then stopBtn:Disable(); stopBtn:SetAlpha(0.35) end
        -- Self-contained OnUpdate loop: owns the entire lock-to-unlock lifecycle
        local gsPhase = "delay"
        local gsElapsed = 0
        local GS_TIMEOUT = 15  -- hard safety timeout in seconds
        local gsTotalTime = 0
        local gsFrame = CreateFrame("Frame")
        gsFrame:SetScript("OnUpdate", function(_, delta)
            gsElapsed = gsElapsed + delta
            gsTotalTime = gsTotalTime + delta
            -- Hard timeout: always unlock no matter what
            if gsTotalTime >= GS_TIMEOUT then
                gsFrame:SetScript("OnUpdate", nil)
                PBM.State.LichborneInspectTarget = nil
                ClearInspectPlayer()
                SetScanActive(false)
                if stopBtn then stopBtn:Enable(); stopBtn:SetAlpha(1.0) end
                if LichborneAddStatus then LichborneAddStatus:SetText("|cffff4444GS scan timed out.|r") end
                LichborneOutput("|cffC69B3APBM:|r |cffff4444Target GS scan timed out.|r", 1, 0.85, 0)
                return
            end
            if gsPhase == "delay" then
                if gsElapsed < 0.5 then return end
                gsElapsed = 0
                PBM.State.LichborneInspectTarget = gsDi; PBM.State.LichborneInspectUnit = "target"
                PBM.DBG("InspectUnit(target) -> GS scan for |cffffff88"..((LichborneTrackerDB.rows[gsDi] and LichborneTrackerDB.rows[gsDi].name) or "?").."|r UnitExists=|cffffff88"..tostring(UnitExists("target")).."|r InRange=|cffffff88"..tostring(CheckInteractDistance("target",1)).."|r")
                InspectUnit("target"); PBM.State.LichborneInspectGUID = UnitGUID("target"); if not PBM.State.LichborneInspectGUID then PBM.DBG("|cffff4444[NIL]|r UnitGUID(target)=nil â€” GUID capture skipped") end; PBM.State.inspectWait = 0
                gsPhase = "wait"
            elseif gsPhase == "wait" then
                -- CalcGS sets PBM.State.LichborneInspectTarget = nil when done
                if PBM.State.LichborneInspectTarget == nil then
                    gsFrame:SetScript("OnUpdate", nil)
                    SetScanActive(false)
                    if stopBtn then stopBtn:Enable(); stopBtn:SetAlpha(1.0) end
                    return
                end
            end
        end)
    end)

    -- ── Update Target Spec (row y=78, right) ──────────────────
    local tsBtn = MakeTrackerBtn("LichborneUpdateTargetSpecBtn", 15, 76, 155, 29, 0.10, 0.40, 0.70, "|cffd4af37+ Add Target Spec|r")
    tsBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(tsBtn,"ANCHOR_TOP")
        GameTooltip:AddLine("+ Add Target Spec",0.78,0.61,0.23)
        GameTooltip:AddLine("Adds targets spec.",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    tsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    tsBtn:SetScript("OnClick", function()
        if not UnitExists("target") or not UnitIsPlayer("target") then LichborneAddStatus:SetText("|cffff4444No player targeted.|r"); return end
        local targetName = UnitName("target")
        local _, targetClassSP = UnitClass("target")
        local clsSP = targetClassSP and PBM.CLASS_TOKEN_MAP[targetClassSP]
        -- Add to tracker if not already there
        local foundDi = nil
        for i, row in ipairs(LichborneTrackerDB.rows) do
            if row.name and row.name:lower() == targetName:lower() then foundDi = i; break end
        end
        if not foundDi then
            if not clsSP then LichborneAddStatus:SetText("|cffff4444Unknown class for "..targetName.."|r"); return end
            PBM.EnsureClass(clsSP)
            local idxs = PBM.GetAllClassRows(clsSP)
            for _, di in ipairs(idxs) do
                local row = LichborneTrackerDB.rows[di]
                if not row.name or row.name == "" then foundDi = di; break end
            end
            if not foundDi then
                table.insert(LichborneTrackerDB.rows, PBM.DefaultRow(clsSP))
                foundDi = #LichborneTrackerDB.rows
            end
            LichborneTrackerDB.rows[foundDi].name = targetName
            LichborneTrackerDB.rows[foundDi].level = UnitLevel("target")
            if PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames > 0 then PBM.RefreshOverviewRows() end
            local cA = PBM.CLASS_COLORS[clsSP]; local hA = cA and string.format("|cff%02x%02x%02x",math.floor(cA.r*255),math.floor(cA.g*255),math.floor(cA.b*255)) or "|cffffffff"
            LichborneOutput("|cffC69B3APBM:|r Added "..hA..targetName.."|r to tracker.", 1, 0.85, 0)
        end
        local rowData = LichborneTrackerDB.rows[foundDi]
        local c = PBM.CLASS_COLORS[rowData.cls or ""]; local hex = c and string.format("|cff%02x%02x%02x",math.floor(c.r*255),math.floor(c.g*255),math.floor(c.b*255)) or "|cffffffff"
        LichborneAddStatus:SetText("Adding Specialization for "..hex..targetName.."|r...")
        LichborneOutput("|cffC69B3APBM:|r Adding Specialization for "..hex..targetName.."|r...", 1, 0.85, 0)
        local spDi = foundDi
        -- Lock all buttons (including Stop and invite) during single-target scan
        SetScanActive(true)
        local stopBtn = _G["LichborneStopInspectBtn"]
        if stopBtn then stopBtn:Disable(); stopBtn:SetAlpha(0.35) end
        -- Self-contained OnUpdate loop: owns the entire lock-to-unlock lifecycle
        local spPhase = "delay"
        local spElapsed = 0
        local SP_TIMEOUT = 15  -- hard safety timeout in seconds
        local spTotalTime = 0
        local spFrame = CreateFrame("Frame")
        spFrame:SetScript("OnUpdate", function(_, delta)
            spElapsed = spElapsed + delta
            spTotalTime = spTotalTime + delta
            -- Hard timeout: always unlock no matter what
            if spTotalTime >= SP_TIMEOUT then
                spFrame:SetScript("OnUpdate", nil)
                PBM.State.LichborneSpecTarget = nil
                ClearInspectPlayer()
                SetScanActive(false)
                if stopBtn then stopBtn:Enable(); stopBtn:SetAlpha(1.0) end
                if LichborneAddStatus then LichborneAddStatus:SetText("|cffff4444Specialization scan timed out.|r") end
                LichborneOutput("|cffC69B3APBM:|r |cffff4444Target Specialization scan timed out.|r", 1, 0.85, 0)
                return
            end
            if spPhase == "delay" then
                if spElapsed < 0.5 then return end
                spElapsed = 0
                PBM.State.LichborneSpecTarget = spDi; PBM.State.LichborneInspectUnit = "target"
                LichborneTrackerDB.rows[spDi].spec = ""
                PBM.DBG("InspectUnit(target) -> Spec scan for |cffffff88"..((LichborneTrackerDB.rows[spDi] and LichborneTrackerDB.rows[spDi].name) or "?").."|r UnitExists=|cffffff88"..tostring(UnitExists("target")).."|r InRange=|cffffff88"..tostring(CheckInteractDistance("target",1)).."|r")
                InspectUnit("target"); PBM.State.LichborneSpecGUID = UnitGUID("target"); if not PBM.State.LichborneSpecGUID then PBM.DBG("|cffff4444[NIL]|r UnitGUID(target)=nil â€” GUID capture skipped") end; PBM.State.specWait = 0
                spPhase = "wait"
            elseif spPhase == "wait" then
                -- CalcSpec sets PBM.State.LichborneSpecTarget = nil when done
                if PBM.State.LichborneSpecTarget == nil then
                    spFrame:SetScript("OnUpdate", nil)
                    SetScanActive(false)
                    if stopBtn then stopBtn:Enable(); stopBtn:SetAlpha(1.0) end
                    return
                end
            end
        end)
    end)

    -- ── Update Group GS (row y=44, left) ──────────────────────

    -- Disable/enable all buttons except Stop during a scan
    SetScanActive = function(active)
        PBM.SetButtonsLocked(active)
        -- Also lock invite buttons and stop overlay during scans
        local inviteRaid = _G["LichborneInviteRaidBtn"]
        if inviteRaid then
            if active then inviteRaid:Disable(); inviteRaid:SetAlpha(0.35)
            else inviteRaid:Enable(); inviteRaid:SetAlpha(1.0) end
        end
        local inviteGroup = _G["LichborneInviteGroupBtn"]
        if inviteGroup then
            if active then inviteGroup:Disable(); inviteGroup:SetAlpha(0.35)
            else inviteGroup:Enable(); inviteGroup:SetAlpha(1.0) end
        end
        local stopInv = _G["LichborneStopInviteBtn"]
        if stopInv then
            if active then stopInv:Disable(); stopInv:SetAlpha(0.35)
            else stopInv:Enable(); stopInv:SetAlpha(1.0) end
        end
    end
    local uggsBtn = MakeTrackerBtn("LichborneUpdateGroupGSBtn", 175, 110, 155, 29, 0.10, 0.40, 0.70, "|cffd4af37+ Add Group Gear|r")
    uggsBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(uggsBtn,"ANCHOR_TOP"); GameTooltip:AddLine("+ Add Group Gear",0.78,0.61,0.23)
        GameTooltip:AddLine("Adds members gear.",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    uggsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    uggsBtn:SetScript("OnClick", function()
        local playerName = UnitName("player")
        if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
            LichborneAddStatus:SetText("|cffff4444Not in a group.|r"); return
        end
        SetScanActive(true)
        PBM.State.LichborneGroupScanActive = true
        LichborneAddStatus:SetText("Adding group members first...")
        AddGroupMembers(function(added, skipped)
            if not PBM.State.LichborneGroupScanActive then SetScanActive(false); return end
            -- Now build unit list and run GS scan
            local units = {}
            units[#units+1] = "player"
            if GetNumRaidMembers() > 0 then
                for i = 1, GetNumRaidMembers() do local unit="raid"..i; if UnitExists(unit) and UnitIsPlayer(unit) and UnitName(unit)~=playerName then units[#units+1]=unit end end
            elseif GetNumPartyMembers() > 0 then
                for i = 1, GetNumPartyMembers() do local unit="party"..i; if UnitExists(unit) then units[#units+1]=unit end end
            end
            if #units == 0 then SetScanActive(false); LichborneAddStatus:SetText("|cffff4444No group members found.|r"); return end
            local totalTime = math.ceil(#units*2.5)
            LichborneAddStatus:SetText("|cffff9900Added "..added.." new, skipped "..skipped.." duplicates"..(skipped > 0 and ". Levels updated." or ".").."\nInspecting "..#units.." players (~"..totalTime.."s)...|r")
            LichborneOutput("|cffC69B3APBM:|r Group synced (+"..added..", skipped "..skipped..(skipped > 0 and ". Levels updated." or "")..").\nStarting GS scan for "..#units.." players.", 1, 0.85, 0)
            local scanGsStartTime = GetTime()  -- PBM.DBG: group scan timing
            local idx,elapsed,inspecting = 1,0,false
            local gFrame = CreateFrame("Frame")
            activeInspectFrame = gFrame
            gFrame:SetScript("OnUpdate", function(_, delta)
                elapsed = elapsed + delta
                if inspecting then
                    if PBM.State.LichborneInspectTarget ~= nil and elapsed < 25 then return end
                    if PBM.State.LichborneInspectTarget ~= nil then
                        PBM.DBG("|cffff9900GS 25s cap|r — forcing advance to next player")
                    else
                        PBM.DBG("|cff44ff44GS wait done|r — CalcGS signaled complete; advancing")
                    end
                    inspecting=false; elapsed=0
                end
                if idx > #units then
                    gFrame:SetScript("OnUpdate",nil)
                    PBM.State.LichborneGroupScanActive = false
                    SetScanActive(false)
                    LichborneAddStatus:SetText("|cff44ff44Group GS update complete!|r")
                    LichborneOutput("|cffC69B3APBM:|r |cff44ff44Group GS update complete.|r", 1, 0.85, 0)
                    PBM.DBG("|cff44ff44Group GS scan done|r - "..#units.." units, elapsed |cffffff88"..string.format("%.1f", GetTime()-scanGsStartTime).."s|r")
                    PBM.RefreshRows(); return
                end
                local unit = units[idx]; if not UnitExists(unit) then idx=idx+1; return end
                local targetName = UnitName(unit)
                if not targetName then PBM.DBG("|cffff4444[NIL]|r UnitName("..unit..") returned nil - skipping"); idx=idx+1; return end
                local foundDi = nil
                for i, row in ipairs(LichborneTrackerDB.rows) do if row.name and row.name:lower()==targetName:lower() then foundDi=i; break end end
                if not foundDi then LichborneOutput("|cffC69B3APBM:|r Skipping "..tostring(targetName).." (not tracked)",1,0.6,0.3); idx=idx+1; return end
                LichborneAddStatus:SetText("Updating Gear for |cffffff88"..tostring(targetName).."|r... ("..(idx).."/"..#units..")")
                PBM.State.LichborneInspectTarget = foundDi; PBM.State.LichborneInspectUnit = unit
                PBM.DBG("InspectUnit("..unit..") -> group GS for |cffffff88"..tostring(targetName).."|r ("..idx.."/"..#units..") UnitExists=|cffffff88"..tostring(UnitExists(unit)).."|r InRange=|cffffff88"..tostring(CheckInteractDistance(unit,1)).."|r")
                InspectUnit(unit); PBM.State.LichborneInspectGUID = UnitGUID(unit); if not PBM.State.LichborneInspectGUID then PBM.DBG("|cffff4444[NIL]|r UnitGUID("..unit..")=nil â€” GUID capture skipped") end; PBM.State.inspectWait=0; idx=idx+1; inspecting=true; elapsed=0
            end)
        end)
    end)

    -- ── Update Group Spec (row y=44, right) ───────────────────
    local ugsBtn = MakeTrackerBtn("LichborneUpdateGroupSpecBtn", 175, 76, 155, 29, 0.10, 0.40, 0.70, "|cffd4af37+ Add Group Spec|r")
    ugsBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(ugsBtn,"ANCHOR_TOP"); GameTooltip:AddLine("+ Add Group Spec",0.78,0.61,0.23)
        GameTooltip:AddLine("Adds members spec.",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    ugsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    ugsBtn:SetScript("OnClick", function()
        local playerName = UnitName("player")
        if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
            LichborneAddStatus:SetText("|cffff4444Not in a group.|r"); return
        end
        SetScanActive(true)
        PBM.State.LichborneGroupScanActive = true
        LichborneAddStatus:SetText("Adding group members first...")
        AddGroupMembers(function(added, skipped)
            if not PBM.State.LichborneGroupScanActive then SetScanActive(false); return end
            -- Now build unit list and run Spec scan
            local units = {}
            units[#units+1] = "player"
            if GetNumRaidMembers() > 0 then
                for i = 1, GetNumRaidMembers() do local unit="raid"..i; if UnitExists(unit) and UnitIsPlayer(unit) and UnitName(unit)~=playerName then units[#units+1]=unit end end
            elseif GetNumPartyMembers() > 0 then
                for i = 1, GetNumPartyMembers() do local unit="party"..i; if UnitExists(unit) then units[#units+1]=unit end end
            end
            if #units == 0 then SetScanActive(false); LichborneAddStatus:SetText("|cffff4444No group members found.|r"); return end
            local totalTime = math.ceil(#units*3)
            LichborneAddStatus:SetText("|cffff9900Added "..added.." new, skipped "..skipped.." duplicates"..(skipped > 0 and ". Levels updated." or ".").."\nReading Specialization for "..#units.." players (~"..totalTime.."s)...|r")
            LichborneOutput("|cffC69B3APBM:|r Group synced (+"..added..", skipped "..skipped..(skipped > 0 and ". Levels updated." or "")..").\nStarting Specialization scan for "..#units.." players.", 1, 0.85, 0)
            local scanSpecStartTime = GetTime()  -- PBM.DBG: group scan timing
            local idx,elapsed,inspecting = 1,0,false
            local sFrame = CreateFrame("Frame")
            activeInspectFrame = sFrame
            PBM.State.LichborneGroupScanActive = true
            sFrame:SetScript("OnUpdate", function(_, delta)
                elapsed = elapsed + delta
                if inspecting then
                    if PBM.State.LichborneSpecTarget ~= nil and elapsed < 25 then return end
                    if PBM.State.LichborneSpecTarget ~= nil then
                        PBM.DBG("|cffff9900Spec 25s cap|r — forcing advance to next player")
                    else
                        PBM.DBG("|cff44ff44Spec wait done|r — CalcSpec signaled complete; advancing")
                    end
                    inspecting=false; elapsed=0
                end
                if idx > #units then
                    sFrame:SetScript("OnUpdate",nil)
                    PBM.State.LichborneGroupScanActive = false
                    SetScanActive(false)
                    LichborneAddStatus:SetText("|cff44ff44Group Specialization update complete!|r")
                    LichborneOutput("|cffC69B3APBM:|r |cff44ff44Group Specialization update complete.|r", 1, 0.85, 0)
                    PBM.DBG("|cff44ff44Group Spec scan done|r - "..#units.." units, elapsed |cffffff88"..string.format("%.1f", GetTime()-scanSpecStartTime).."s|r")
                    PBM.RefreshRows(); if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end; return
                end
                local unit = units[idx]; if not UnitExists(unit) then idx=idx+1; return end
                local targetName = UnitName(unit)
                if not targetName then PBM.DBG("|cffff4444[NIL]|r UnitName("..unit..") returned nil - skipping"); idx=idx+1; return end
                local foundDi = nil
                for i, row in ipairs(LichborneTrackerDB.rows) do if row.name and row.name:lower()==targetName:lower() then foundDi=i; break end end
                if not foundDi then LichborneOutput("|cffC69B3APBM:|r Skipping "..tostring(targetName).." (not tracked)",1,0.6,0.3); idx=idx+1; return end
                LichborneAddStatus:SetText("Reading Specialization |cffffff88"..tostring(targetName).."|r... ("..(idx).."/"..#units..")")
                PBM.State.LichborneSpecTarget = foundDi; PBM.State.LichborneInspectUnit = unit
                if LichborneTrackerDB.rows[foundDi] then LichborneTrackerDB.rows[foundDi].spec="" end
                PBM.DBG("InspectUnit("..unit..") -> group Spec for |cffffff88"..tostring(targetName).."|r ("..idx.."/"..#units..") UnitExists=|cffffff88"..tostring(UnitExists(unit)).."|r InRange=|cffffff88"..tostring(CheckInteractDistance(unit,1)).."|r")
                InspectUnit(unit); PBM.State.LichborneSpecGUID = UnitGUID(unit); if not PBM.State.LichborneSpecGUID then PBM.DBG("|cffff4444[NIL]|r UnitGUID("..unit..")=nil â€” GUID capture skipped") end; PBM.State.specWait=0; idx=idx+1; inspecting=true; elapsed=0
            end)
        end)
    end)

    -- ── Stop Inspect button (below Get Group Spec) ────────────
    local stopInspectBtn = MakeTrackerBtn("LichborneStopInspectBtn", 15, 8, 155, 29, 0.90, 0.20, 0.20, "|cffd4af37Stop Scan|r")
    stopInspectBtn:SetBackdropColor(0.90*0.30, 0.20*0.30, 0.20*0.30, 1)
    stopInspectBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(stopInspectBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("Stop Scan", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Cancels the running Gear or Spec scan.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    stopInspectBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    stopInspectBtn:SetScript("OnClick", function()
        if activeInspectFrame then
            activeInspectFrame:SetScript("OnUpdate", nil)
            activeInspectFrame = nil
        end
        PBM.State.LichborneInspectTarget = nil
        PBM.State.LichborneSpecTarget = nil
        PBM.State.LichborneGroupScanActive = false
        PBM.State.ipQueryActive = false
        SetScanActive(false)
        LichborneAddStatus:SetText("|cffff4444Scan stopped.|r")
        LichborneOutput("|cffC69B3APBM:|r |cffff4444Scan stopped.|r", 1, 0.85, 0)
    end)

    -- Row y=10: Add Target / Add Group (existing buttons stay here)
    -- Avg GS bar (repurposed from Count bar)
    local clsFrame = CreateFrame("Frame", "LichborneClassBar", f)
    LichborneCountBar = clsFrame
    clsFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -556)
    clsFrame:SetSize(1086, 24)
    clsFrame:SetFrameLevel(fl + 10)
    local clsbg = clsFrame:CreateTexture(nil, "BACKGROUND")
    clsbg:SetAllPoints(clsFrame); clsbg:SetTexture(0.05, 0.07, 0.13, 1)
    local clsTitle = clsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    clsTitle:SetPoint("LEFT", clsFrame, "LEFT", 4, 0)
    clsTitle:SetText("|cffC69B3AAvg GS:|r"); clsTitle:SetWidth(52)
    LichborneCountLabels = {}
    local cRosterBlockW = 130
    local cswTotalW = 1086 - 56 - 4 - cRosterBlockW
    local cswW = cswTotalW / 10
    local cswIdx = 0
    for i, cls in ipairs(PBM.CLASS_TABS) do
        if cls == "Raid" or cls == "Overview" or cls == "Group" then break end
        cswIdx = cswIdx + 1
        local c = PBM.CLASS_COLORS[cls]
        local csw = CreateFrame("Button", "LichborneClassSwatch"..cswIdx, clsFrame)
        csw:SetSize(cswW - 2, 20)
        csw:SetPoint("LEFT", clsFrame, "LEFT", 56 + (cswIdx-1)*cswW, 0)
        csw:SetFrameLevel(clsFrame:GetFrameLevel() + 1)
        local cswbg = csw:CreateTexture(nil, "BACKGROUND")
        cswbg:SetAllPoints(csw); cswbg:SetTexture(0.08, 0.10, 0.18, 1); csw.bg = cswbg
        local hex = string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255))
        local lbl = csw:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints(csw); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
        lbl:SetText(hex..(PBM.TAB_LABELS[cls])..": |cff555555--|r"); csw.lbl = lbl; csw.cls = cls
        LichborneCountLabels[cls] = lbl
        csw:EnableMouse(true)
        csw:SetScript("OnEnter", function()
            GameTooltip:SetOwner(csw, "ANCHOR_TOP")
            local gs = PBM.GetClassAvgGS(cls)
            GameTooltip:AddLine(PBM.TAB_LABELS[cls], c.r, c.g, c.b)
            GameTooltip:AddLine("Average gear score of all tracked "..PBM.TAB_LABELS[cls].."s.", 1,1,1)
            if gs > 0 then
                GameTooltip:AddLine("Current: |cffd4af37"..gs.."|r", 1,1,1)
            else
                GameTooltip:AddLine("No gear data yet.", 0.6,0.6,0.6)
            end
            GameTooltip:AddLine("Click to switch to this tab.", 0.5,0.5,0.5)
            GameTooltip:Show()
        end)
        csw:SetScript("OnLeave", function() GameTooltip:Hide() end)
        csw:SetScript("OnClick", function()
            PBM.State.activeTab = cls
            PBM.UpdateTabs()
            PBM.RefreshRows()
        end)
    end

    -- Roster GS block — right-anchored, gold border, fills remaining space
    local rosterGsBlock = CreateFrame("Frame", "LichborneRosterGsBlock", clsFrame)
    rosterGsBlock:SetPoint("RIGHT", clsFrame, "RIGHT", 0, 0)
    rosterGsBlock:SetSize(cRosterBlockW, 24)
    rosterGsBlock:SetFrameLevel(clsFrame:GetFrameLevel() + 1)
    rosterGsBlock:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=8,
        insets={left=2,right=2,top=2,bottom=2}
    })
    rosterGsBlock:SetBackdropColor(0.05, 0.07, 0.13, 1)
    rosterGsBlock:SetBackdropBorderColor(0.78, 0.61, 0.23, 1.0)
    local rosterGsLbl = rosterGsBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rosterGsLbl:SetAllPoints(rosterGsBlock)
    rosterGsLbl:SetJustifyH("CENTER"); rosterGsLbl:SetJustifyV("MIDDLE")
    rosterGsLbl:SetText("|cffC69B3ARoster GS:|r |cff555555--|r")
    PBM.State.LichborneRosterGsLabel = rosterGsLbl
    rosterGsBlock:EnableMouse(true)
    rosterGsBlock:SetScript("OnEnter", function()
        GameTooltip:SetOwner(rosterGsBlock, "ANCHOR_TOP")
        GameTooltip:AddLine("Roster Avg GS", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Average gear score across your", 1,1,1)
        GameTooltip:AddLine("entire tracked roster.", 1,1,1)
        GameTooltip:Show()
    end)
    rosterGsBlock:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Build raid frame
    PBM.BuildRaidFrame(f, fl)
    PBM.BuildOverviewFrame(f, fl)
    PBM.BuildBotSettingsFrame(f, fl)
    PBM.BuildBottomTabs(f, fl)


    -- ── Playerbot section ─────────────────────────────────────
    -- Border frame styled like the title bar
    -- ── Bot buttons (left column, no border) ─────────────────
    local function MakeSimpleBtn(name, label, r, g, b, x, y, w, tooltip)
        local btn = CreateFrame("Button", name, f)
        btn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, y)
        btn:SetSize(w or 185, 29)
        btn:SetFrameLevel(fl + 12)
        btn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
        btn:SetBackdropColor(r*0.3, g*0.3, b*0.3, 1)
        btn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetAllPoints(btn); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
        lbl:SetText(label)
        if tooltip then
            btn:SetScript("OnEnter", function()
                GameTooltip:SetOwner(btn, "ANCHOR_TOP")
                for _, line in ipairs(tooltip) do
                    GameTooltip:AddLine(line[1], line[2] or 1, line[3] or 1, line[4] or 1)
                end
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        return btn
    end

    local maintBtn = MakeSimpleBtn("LichborneMaintBtn", "|cffd4af37+ Full Group Scan|r",
        0.2, 0.5, 0.9, 175, 8,
        155, {
            {"Full Group Scan",0.78,0.61,0.23},
            {"Long scan is used for first time setup",0.8,0.8,0.8},
            {"or reconfiguration of raid. Performs",0.8,0.8,0.8},
            {"gear and spec scan. Allow 6s per",0.8,0.8,0.8},
            {"character.",0.8,0.8,0.8},
        })
    maintBtn:SetScript("OnClick", function()
        local playerName = UnitName("player")
        if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
            LichborneAddStatus:SetText("|cffff4444Not in a group.|r"); return
        end
        SetScanActive(true)
        PBM.State.LichborneGroupScanActive = true
        LichborneAddStatus:SetText("Adding group members...")
        AddGroupMembers(function(added, skipped)
            -- Abort if Stop Scan was pressed during the add phase
            if not PBM.State.LichborneGroupScanActive then return end
            -- Build shared unit list used by both GS and Spec phases
            local units = {}
            units[#units+1] = "player"
            if GetNumRaidMembers() > 0 then
                for i = 1, GetNumRaidMembers() do
                    local unit = "raid"..i
                    if UnitExists(unit) and UnitIsPlayer(unit) and UnitName(unit) ~= playerName then
                        units[#units+1] = unit
                    end
                end
            elseif GetNumPartyMembers() > 0 then
                for i = 1, GetNumPartyMembers() do
                    local unit = "party"..i
                    if UnitExists(unit) then units[#units+1] = unit end
                end
            end
            if #units == 0 then
                SetScanActive(false)
                LichborneAddStatus:SetText("|cffff4444No group members found.|r")
                return
            end
            -- ── Phase 2: GS scan ──────────────────────────────────────────
            local totalTime = math.ceil(#units * 6)
            LichborneAddStatus:SetText("|cffff9900Added "..added.." new, skipped "..skipped.." duplicates"..(skipped > 0 and ". Levels updated." or ".").."\nFull scan: "..#units.." players (~"..totalTime.."s)...|r")
            LichborneOutput("|cffC69B3APBM:|r Full Group Scan started (+"..added..", skipped "..skipped..(skipped > 0 and ". Levels updated." or "")..").\nGS phase: "..#units.." players.", 1, 0.85, 0)
            local scanStartTime = GetTime()
            local idx, elapsed, inspecting = 1, 0, false
            local gFrame = CreateFrame("Frame")
            activeInspectFrame = gFrame
            gFrame:SetScript("OnUpdate", function(_, delta)
                elapsed = elapsed + delta
                if inspecting then
                    if PBM.State.LichborneInspectTarget ~= nil and elapsed < 25 then return end
                    if PBM.State.LichborneInspectTarget ~= nil then
                        PBM.DBG("|cffff9900FullScan GS 25s cap|r — forcing advance to next player")
                    else
                        PBM.DBG("|cff44ff44FullScan GS wait done|r — advancing")
                    end
                    inspecting = false; elapsed = 0
                end
                if idx > #units then
                    gFrame:SetScript("OnUpdate", nil)
                    PBM.DBG("|cff44ff44FullScan GS phase done|r — elapsed |cffffff88"..string.format("%.1f", GetTime()-scanStartTime).."s|r")
                    -- ── Phase 3: Spec scan ────────────────────────────────
                    LichborneAddStatus:SetText("|cffff9900GS done. Starting Specialization scan ("..#units.." players)...|r")
                    LichborneOutput("|cffC69B3APBM:|r GS phase complete. Starting Specialization phase.", 1, 0.85, 0)
                    local sIdx, sElapsed, sInspecting = 1, 0, false
                    local sFrame = CreateFrame("Frame")
                    activeInspectFrame = sFrame
                    sFrame:SetScript("OnUpdate", function(_, sdelta)
                        sElapsed = sElapsed + sdelta
                        if sInspecting then
                            if PBM.State.LichborneSpecTarget ~= nil and sElapsed < 25 then return end
                            if PBM.State.LichborneSpecTarget ~= nil then
                                PBM.DBG("|cffff9900FullScan Spec 25s cap|r — forcing advance")
                            else
                                PBM.DBG("|cff44ff44FullScan Spec wait done|r — advancing")
                            end
                            sInspecting = false; sElapsed = 0
                        end
                        if sIdx > #units then
                            sFrame:SetScript("OnUpdate", nil)
                            PBM.State.LichborneGroupScanActive = false
                            SetScanActive(false)
                            LichborneAddStatus:SetText("|cff44ff44Full Group Scan complete!|r")
                            LichborneOutput("|cffC69B3APBM:|r |cff44ff44Full Group Scan complete.|r", 1, 0.85, 0)
                            PBM.DBG("|cff44ff44FullScan complete|r — total elapsed |cffffff88"..string.format("%.1f", GetTime()-scanStartTime).."s|r")
                            PBM.RefreshRows(); if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
                            -- Trigger group strategies query for all scanned members
                            local strCount = 0
                            for _, unit in ipairs(units) do
                                if not UnitIsUnit(unit, "player") then
                                    local name = UnitName(unit)
                                    if name and name ~= "" and UnitIsPlayer(unit) then
                                        PBM.State.joinPending[name] = { step = 1 }
                                        PBM.SendToBot("co ?", name)
                                        strCount = strCount + 1
                                    end
                                end
                            end
                            if strCount > 0 then
                                LichborneAddStatus:SetText("|cff44ff44Full Group Scan complete!|r |cffd4af37Fetching strategies: "..strCount.." members...|r")
                            end
                            return
                        end
                        local unit = units[sIdx]; if not UnitExists(unit) then sIdx = sIdx + 1; return end
                        local targetName = UnitName(unit)
                        if not targetName then PBM.DBG("|cffff4444[NIL]|r UnitName("..unit..") nil - skipping"); sIdx = sIdx + 1; return end
                        local foundDi = nil
                        for i, row in ipairs(LichborneTrackerDB.rows) do
                            if row.name and row.name:lower() == targetName:lower() then foundDi = i; break end
                        end
                        if not foundDi then
                            LichborneOutput("|cffC69B3APBM:|r Skipping "..tostring(targetName).." (not tracked)", 1, 0.6, 0.3)
                            sIdx = sIdx + 1; return
                        end
                        LichborneAddStatus:SetText("Specialization scan |cffffff88"..tostring(targetName).."|r... ("..sIdx.."/"..#units..")")
                        PBM.State.LichborneSpecTarget = foundDi; PBM.State.LichborneInspectUnit = unit
                        if LichborneTrackerDB.rows[foundDi] then LichborneTrackerDB.rows[foundDi].spec = "" end
                        PBM.DBG("InspectUnit("..unit..") -> FullScan Spec for |cffffff88"..tostring(targetName).."|r ("..sIdx.."/"..#units..")")
                        InspectUnit(unit); PBM.State.LichborneSpecGUID = UnitGUID(unit); if not PBM.State.LichborneSpecGUID then PBM.DBG("|cffff4444[NIL]|r UnitGUID("..unit..")=nil — GUID capture skipped") end; PBM.State.specWait = 0; sIdx = sIdx + 1; sInspecting = true; sElapsed = 0
                    end)
                    return
                end
                local unit = units[idx]; if not UnitExists(unit) then idx = idx + 1; return end
                local targetName = UnitName(unit)
                if not targetName then PBM.DBG("|cffff4444[NIL]|r UnitName("..unit..") nil - skipping"); idx = idx + 1; return end
                local foundDi = nil
                for i, row in ipairs(LichborneTrackerDB.rows) do
                    if row.name and row.name:lower() == targetName:lower() then foundDi = i; break end
                end
                if not foundDi then
                    LichborneOutput("|cffC69B3APBM:|r Skipping "..tostring(targetName).." (not tracked)", 1, 0.6, 0.3)
                    idx = idx + 1; return
                end
                LichborneAddStatus:SetText("Updating Gear for |cffffff88"..tostring(targetName).."|r... ("..idx.."/"..#units..")")
                PBM.State.LichborneInspectTarget = foundDi; PBM.State.LichborneInspectUnit = unit
                PBM.DBG("InspectUnit("..unit..") -> FullScan GS for |cffffff88"..tostring(targetName).."|r ("..idx.."/"..#units..")")
                InspectUnit(unit); PBM.State.LichborneInspectGUID = UnitGUID(unit); if not PBM.State.LichborneInspectGUID then PBM.DBG("|cffff4444[NIL]|r UnitGUID("..unit..")=nil — GUID capture skipped") end; PBM.State.inspectWait = 0; idx = idx + 1; inspecting = true; elapsed = 0
            end)
        end)
    end)

    local loginBtn = MakeSimpleBtn("LichborneLoginBtn", "|cffd4af37Log in All Bots|r",
        0.1, 0.6, 0.2, 335, 110,
        155, {{"Log in All Bots",0.78,0.61,0.23},{".playerbots bot add *",0.8,0.8,0.8}})
    loginBtn:SetScript("OnClick", function() SendChatMessage(".playerbots bot add *", "PARTY") end)

    local logoutBtn = MakeSimpleBtn("LichborneLogoutBtn", "|cffd4af37Log Out All Bots|r",
        0.90, 0.20, 0.20, 335, 76,
        155, {{"Log Out All Bots",0.78,0.61,0.23},{".playerbots bot remove *",0.8,0.8,0.8}})
    logoutBtn:SetScript("OnClick", function() SendChatMessage(".playerbots bot remove *", "PARTY") end)

    -- ── Remove Orphaned Bots button ────────────────────────────
    -- Sends .playerbots bot remove <name> for every character in the Overview tab roster
    -- Used when bots are still logged in but player has left the group
    local orphanedBotsBtn = CreateFrame("Button", "LichborneOrphanedBotsBtn", f)
    orphanedBotsBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 335, 42)
    orphanedBotsBtn:SetSize(155, 29)
    orphanedBotsBtn:SetFrameLevel(fl + 12)
    orphanedBotsBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    orphanedBotsBtn:SetBackdropColor(0.90*0.30, 0.20*0.30, 0.20*0.30, 1)
    orphanedBotsBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    orphanedBotsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local orphanedBotsLbl = orphanedBotsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    orphanedBotsLbl:SetAllPoints(orphanedBotsBtn); orphanedBotsLbl:SetJustifyH("CENTER"); orphanedBotsLbl:SetJustifyV("MIDDLE")
    orphanedBotsLbl:SetText("|cffd4af37Remove Orphaned Bots|r")
    orphanedBotsBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(orphanedBotsBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("Remove Orphaned Bots", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Logs out all bots in your Overview tab", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("that are not currently in your", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("group or raid.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    orphanedBotsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    orphanedBotsBtn:SetScript("OnClick", function()
        -- Get current group/raid members
        local groupMembers = {}
        local playerName = UnitName("player")
        if playerName then groupMembers[playerName:lower()] = true end
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                local unit = "raid"..i
                if UnitExists(unit) then
                    local name = UnitName(unit)
                    if name then groupMembers[name:lower()] = true end
                end
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                local unit = "party"..i
                if UnitExists(unit) then
                    local name = UnitName(unit)
                    if name then groupMembers[name:lower()] = true end
                end
            end
        end
        -- Collect names from Overview tab that are NOT in the current group
        local botNames = {}
        local seen = {}
        if LichborneTrackerDB.allGroups then
            for _, g in ipairs({"A","B","C"}) do
                local grp = LichborneTrackerDB.allGroups[g]
                if grp then
                    for i = 1, 60 do
                        local r = grp[i]
                        if r and r.name and r.name ~= "" and not seen[r.name:lower()] then
                            seen[r.name:lower()] = true
                            if not groupMembers[r.name:lower()] then
                                botNames[#botNames+1] = r.name
                            end
                        end
                    end
                end
            end
        end
        if #botNames == 0 then
            LichborneOutput("|cffC69B3APBM:|r No orphaned bots found.", 1, 0.5, 0.5)
            if LichborneAddStatus then LichborneAddStatus:SetText("|cffff4444No orphaned bots found.|r") end
            return
        end
        LichborneOutput("|cffC69B3APBM:|r Logging out "..#botNames.." orphaned bots...", 1, 0.85, 0)
        if LichborneAddStatus then LichborneAddStatus:SetText("|cffff9900Logging out "..#botNames.." orphaned bots...") end
        SetScanActive(true)
        local stopBtn = _G["LichborneStopInspectBtn"]
        if stopBtn then stopBtn:Disable(); stopBtn:SetAlpha(0.35) end
        local orphanIdx = 1
        local orphanWait = 0
        local orphanFrame = CreateFrame("Frame")
        orphanFrame:SetScript("OnUpdate", function(_, elapsed)
            orphanWait = orphanWait + elapsed
            if orphanWait < 0.2 then return end
            orphanWait = 0
            if orphanIdx > #botNames then
                orphanFrame:SetScript("OnUpdate", nil)
                SetScanActive(false)
                local stopBtn2 = _G["LichborneStopInspectBtn"]
                if stopBtn2 then stopBtn2:Enable(); stopBtn2:SetAlpha(1.0) end
                LichborneOutput("|cffC69B3APBM:|r |cff44ff44All "..#botNames.." orphaned bots logged out.|r", 1, 0.85, 0)
                if LichborneAddStatus then LichborneAddStatus:SetText("|cff44ff44Orphaned bots logged out ("..#botNames..").|r") end
                return
            end
            local bname = botNames[orphanIdx]
            SendChatMessage(".playerbots bot remove "..bname, "SAY")
            orphanIdx = orphanIdx + 1
        end)
    end)

    -- ── +Add Group IP Tiers button ─────────────────────────────
    local ipTiersBtn = CreateFrame("Button", "LichborneIPTiersBtn", f)
    ipTiersBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 335, 144)
    ipTiersBtn:SetSize(155, 29)
    ipTiersBtn:SetFrameLevel(fl + 12)
    ipTiersBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    ipTiersBtn:SetBackdropColor(0.10*0.35, 0.40*0.35, 0.70*0.35, 1)
    ipTiersBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    ipTiersBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local ipTiersLbl = ipTiersBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ipTiersLbl:SetAllPoints(ipTiersBtn); ipTiersLbl:SetJustifyH("CENTER"); ipTiersLbl:SetJustifyV("MIDDLE")
    ipTiersLbl:SetText("|cffd4af37+ Add IP Tiers|r")
    ipTiersBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(ipTiersBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("+ Add IP Tiers", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Adds Individual Progression Tiers.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("To display tiers, enable |cffd4af37Show IP Tiers|r in the filter bar.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Tier is shown in the number column next to each character.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Requires |cffFF8C00mod-Individual-Progression|r", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    ipTiersBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- CHAT_MSG_SYSTEM listener: parses "Progression Level for <Name> = <N>" from .ip get
    PBM.State.ipQueryActive = false
    local ipEventFrame = CreateFrame("Frame", "LichborneIPEventFrame")
    ipEventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    ipEventFrame:SetScript("OnEvent", function(_, _, msg)
        if not PBM.State.ipQueryActive then return end
        local clean = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        local name, tierStr = clean:match("Progression Level for (%S+) = (%d+)")
        if name and tierStr then
            local num = tonumber(tierStr)
            if num and num >= 0 and num <= 18 then
                if not LichborneTrackerDB.ipData then LichborneTrackerDB.ipData = {} end
                LichborneTrackerDB.ipData[name:lower()] = num
                if PBM.State.LBFilter.showIP then
                    PBM.RefreshRows()
                    if PBM.State.LichborneOverviewFrame then PBM.RefreshOverviewRows() end
                    if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
                end
            end
        end
    end)

    ipTiersBtn:SetScript("OnClick", function()
        SetScanActive(true)
        LichborneAddStatus:SetText("Adding group members first...")
        AddGroupMembers(function(added, skipped)
            -- Always include self, then add group members (deduped)
            local selfName = UnitName("player")
            local seen = {}
            local members = {}
            local function addMember(name)
                if name and name ~= "" and not seen[name:lower()] then
                    seen[name:lower()] = true
                    members[#members+1] = name
                end
            end
            addMember(selfName)
            if GetNumRaidMembers() > 0 then
                for i = 1, GetNumRaidMembers() do addMember(UnitName("raid"..i)) end
            elseif GetNumPartyMembers() > 0 then
                for i = 1, GetNumPartyMembers() do addMember(UnitName("party"..i)) end
            end
            if #members == 0 then
                SetScanActive(false)
                if LichborneAddStatus then LichborneAddStatus:SetText("|cffff4444Could not determine any targets.|r") end
                return
            end
            if not LichborneTrackerDB.ipData then LichborneTrackerDB.ipData = {} end
            PBM.State.ipQueryActive = true
            if LichborneAddStatus then
                LichborneAddStatus:SetText("|cffd4af37Added "..added.." new, skipped "..skipped..". Querying IP tiers...|r")
            end
            local idx = 1
            local wait = 0
            local ipQueryFrame = CreateFrame("Frame")
            activeInspectFrame = ipQueryFrame
            ipQueryFrame:SetScript("OnUpdate", function(_, elapsed)
                wait = wait + elapsed
                if wait < 0.2 then return end
                wait = 0
                if idx > #members then
                    ipQueryFrame:SetScript("OnUpdate", nil)
                    PBM.State.ipQueryActive = false
                    SetScanActive(false)
                    if LichborneAddStatus then
                        LichborneAddStatus:SetText("|cff44ff44IP Tier query complete ("..#members.." members).|r")
                    end
                    return
                end
                local name = members[idx]
                SendChatMessage(".ip get "..name, "SAY")
                if LichborneAddStatus then
                    LichborneAddStatus:SetText("|cffd4af37Querying IP: |r"..name.." ("..idx.."/"..#members..")")
                end
                idx = idx + 1
            end)
        end)
    end)

    local disbandBtn = CreateFrame("Button", "LichborneDisbandBtn", f)
    disbandBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 335, 8)
    disbandBtn:SetSize(155, 29)
    disbandBtn:SetFrameLevel(fl + 12)
    disbandBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    disbandBtn:SetBackdropColor(0.90*0.30, 0.20*0.30, 0.20*0.30, 1)
    disbandBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    disbandBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local disbandLbl = disbandBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    disbandLbl:SetAllPoints(disbandBtn); disbandLbl:SetJustifyH("CENTER"); disbandLbl:SetJustifyV("MIDDLE")
    disbandLbl:SetText("|cffd4af37Disband Group|r")
    disbandBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(disbandBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("Disband Group", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Removes all bots and leaves the group.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    disbandBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Confirmation dialog for Disband Group (standard WoW dialog)
    if not StaticPopupDialogs["PBM_DISBAND_GROUP"] then
        StaticPopupDialogs["PBM_DISBAND_GROUP"] = {
            text = "Disband Group?\n\nRemoves all bots and leaves the group.\n|cffff4444This cannot be undone.|r",
            button1 = "Yes, Disband",
            button2 = "Cancel",
            OnAccept = function()
                PBM.SetButtonsLocked(true)
                local function lockExtra(locked)
                    for _, n in ipairs({"LichborneStopInspectBtn","LichborneInviteRaidBtn","LichborneInviteGroupBtn","LichborneStopInviteBtn"}) do
                        local b = _G[n]
                        if b then
                            if locked then b:Disable(); b:SetAlpha(0.35)
                            else b:Enable(); b:SetAlpha(1.0) end
                        end
                    end
                end
                lockExtra(true)
                LichborneOutput("|cffC69B3APBM:|r |cffd4af37Disbanding group...|r", 1, 0.85, 0)
                SendChatMessage(".playerbots bot remove *", "SAY")
                local waited = 0
                local disbFrame = CreateFrame("Frame")
                disbFrame:SetScript("OnUpdate", function(_, elapsed)
                    waited = waited + elapsed
                    if waited < 1.0 then return end
                    LeaveParty()
                    PBM.SetButtonsLocked(false)
                    lockExtra(false)
                    LichborneOutput("|cffC69B3APBM:|r |cffd4af37Group disbanded.|r", 1, 0.85, 0)
                    disbFrame:SetScript("OnUpdate", nil)
                end)
            end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
    end
    disbandBtn:SetScript("OnClick", function()
        StaticPopup_Show("PBM_DISBAND_GROUP")
    end)

    -- ── Column button registry (x=335, bottom-to-top order) ──────
    PBM.State.ipColumnBtns = {
        {btn = disbandBtn,      isIPTiers = false},
        {btn = orphanedBotsBtn, isIPTiers = false},
        {btn = logoutBtn,       isIPTiers = false},
        {btn = loginBtn,        isIPTiers = false},
        {btn = ipTiersBtn,      isIPTiers = true},
    }

    -- Redistributes the x=335 column height when +Add IP Tiers is hidden.
    -- Buttons span BOTTOMLEFT y=8 to y=173 (165px total, 5px gaps).
    local function RefreshIPColumn()
        if not PBMConfig then return end
        local ipHidden = PBMConfig.hiddenTabs and PBMConfig.hiddenTabs["IPTiers"]
        local COL_X = 335; local COL_W = 155
        local COL_BOTTOM = 8; local COL_TOP = 173; local GAP = 5
        local visible = {}
        for _, entry in ipairs(PBM.State.ipColumnBtns) do
            if entry.isIPTiers then
                if ipHidden then entry.btn:Hide() else entry.btn:Show() end
            end
            if not (entry.isIPTiers and ipHidden) then
                visible[#visible + 1] = entry.btn
            end
        end
        local n     = #visible
        local avail = (COL_TOP - COL_BOTTOM) - (n - 1) * GAP
        local h     = math.floor(avail / n)
        local extra = avail - h * n
        local curY  = COL_BOTTOM
        for i, btn in ipairs(visible) do
            local bh = h + (i > (n - extra) and 1 or 0)
            btn:ClearAllPoints()
            btn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", COL_X, curY)
            btn:SetSize(COL_W, bh)
            curY = curY + bh + GAP
        end
    end

    -- ── Top-row strategy buttons + upcoming placeholder ──────────
    local strTargetBtn = MakeTrackerBtn("LichborneTargetStrategiesBtn", 15, 42, 155, 29, 0.10, 0.40, 0.70, "|cffd4af37+ Add Target Strategies|r")
    strTargetBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(strTargetBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("+ Add Target Strategies", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Adds target to tracker, then uses", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("co / nc to acquire strategies.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    strTargetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    strTargetBtn:SetScript("OnClick", function()
        local name = AddTargetToTracker()
        if not name then return end
        PBM.State.joinPending[name] = { step = 1 }
        PBM.SendToBot("co ?", name)
        LichborneAddStatus:SetText("|cffd4af37Resyncing strategies: "..name.."...|r")
    end)

    local strGroupBtn = MakeTrackerBtn("LichborneGroupStrategiesBtn", 175, 42, 155, 29, 0.10, 0.40, 0.70, "|cffd4af37+ Add Group Strategies|r")
    strGroupBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(strGroupBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("+ Add Group Strategies", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Adds group to tracker, then uses", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("co / nc to acquire strategies.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    strGroupBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    strGroupBtn:SetScript("OnClick", function()
        if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
            LichborneAddStatus:SetText("|cffff4444Not in a group.|r")
            return
        end
        SetScanActive(true)
        AddGroupMembers(function(added, skipped)
            SetScanActive(false)
            local count = 0
            local function triggerMember(unit)
                if UnitIsUnit(unit, "player") then return end
                local name = UnitName(unit)
                if name and name ~= "" and UnitIsPlayer(unit) then
                    PBM.State.joinPending[name] = { step = 1 }
                    PBM.SendToBot("co ?", name)
                    count = count + 1
                end
            end
            if GetNumRaidMembers() > 0 then
                for i = 1, GetNumRaidMembers() do triggerMember("raid"..i) end
            elseif GetNumPartyMembers() > 0 then
                for i = 1, GetNumPartyMembers() do triggerMember("party"..i) end
            end
            LichborneAddStatus:SetText("|cffd4af37Added "..added..", resyncing strategies: "..count.." members...|r")
        end)
    end)


    -- ── Scrollable Output Box ────────────────────────────────────
    local outputBox = CreateFrame("Frame", "LichborneOutputBox", f)
    outputBox:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  655, 8)
    outputBox:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -17, 8)
    outputBox:SetHeight(130)
    outputBox:SetFrameLevel(fl + 20)
    outputBox:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    outputBox:SetBackdropColor(0.04, 0.06, 0.14, 1.0)
    outputBox:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    outputBox:EnableMouse(true)
    outputBox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(outputBox, "ANCHOR_TOP")
        GameTooltip:AddLine("Output Log", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Scroll up/down with the mouse wheel.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    outputBox:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Status label (replaces the old "Output" title and the standalone addStatus FontString)
    local addStatus = outputBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addStatus:SetPoint("TOPLEFT",  outputBox, "TOPLEFT",  6,  -6)
    addStatus:SetPoint("TOPRIGHT", outputBox, "TOPRIGHT", -50, -6)
    addStatus:SetJustifyH("LEFT")
    addStatus:SetText("")
    LichborneAddStatus = addStatus


    -- Debug toggle button
    local dbgBtn = CreateFrame("Button", "LichborneDbgBtn", outputBox)
    dbgBtn:SetPoint("TOPRIGHT", outputBox, "TOPRIGHT", -4, -2)
    dbgBtn:SetSize(34, 18)
    dbgBtn:SetFrameLevel(outputBox:GetFrameLevel() + 2)
    dbgBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=6,insets={left=1,right=1,top=1,bottom=1}})
    dbgBtn:SetBackdropColor(0.10, 0.10, 0.10, 1)
    dbgBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
    dbgBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local dbgLbl = dbgBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dbgLbl:SetAllPoints(dbgBtn); dbgLbl:SetJustifyH("CENTER"); dbgLbl:SetJustifyV("MIDDLE")
    dbgLbl:SetText("|cff888888DBG|r")
    dbgBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(dbgBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("Debug Mode", 0.78, 0.61, 0.23)
        if LichborneDebugMode then
            GameTooltip:AddLine("Currently: |cff44ff44ON|r", 1, 1, 1)
        else
            GameTooltip:AddLine("Currently: |cffff4444OFF|r", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    dbgBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    dbgBtn:SetScript("OnClick", function()
        LichborneDebugMode = not LichborneDebugMode
        if LichborneDebugMode then
            dbgLbl:SetText("|cff44ff44DBG|r")
            dbgBtn:SetBackdropColor(0.05, 0.20, 0.05, 1)
            dbgBtn:SetBackdropBorderColor(0.3, 0.9, 0.3, 0.9)
            LichborneOutput("|cff44ff44[PBM.DBG] Debug mode ON — inspect logging active.|r")
        else
            dbgLbl:SetText("|cff888888DBG|r")
            dbgBtn:SetBackdropColor(0.10, 0.10, 0.10, 1)
            dbgBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
            LichborneOutput("|cffaaaaaa[PBM.DBG] Debug mode OFF.|r")
        end
    end)

    -- Expand/Collapse output box button (/\ expands up, V collapses)
    local outputExpanded = false
    local OUTPUT_H_COLLAPSED = 130
    local OUTPUT_H_EXPANDED  = 650   -- 130 + 40 lines * ~13px
    local expBtn = CreateFrame("Button", "LichborneOutputExpBtn", outputBox)
    expBtn:SetPoint("RIGHT", dbgBtn, "LEFT", -2, 0)
    expBtn:SetSize(16, 18)
    expBtn:SetFrameLevel(outputBox:GetFrameLevel() + 2)
    expBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=6,insets={left=1,right=1,top=1,bottom=1}})
    expBtn:SetBackdropColor(0.10, 0.10, 0.10, 1)
    expBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
    expBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local expLbl = expBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    expLbl:SetAllPoints(expBtn); expLbl:SetJustifyH("CENTER"); expLbl:SetJustifyV("MIDDLE")
    expLbl:SetText("|cffaaaaaa/\\|r")
    expBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(expBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("Output Box Size", 0.78, 0.61, 0.23)
        if outputExpanded then
            GameTooltip:AddLine("Click to collapse the output box.", 0.8, 0.8, 0.8)
        else
            GameTooltip:AddLine("Click to expand the output box upward.", 0.8, 0.8, 0.8)
        end
        GameTooltip:Show()
    end)
    expBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    expBtn:SetScript("OnClick", function()
        outputExpanded = not outputExpanded
        if outputExpanded then
            outputBox:SetHeight(OUTPUT_H_EXPANDED)
            expLbl:SetText("|cffaaaaaa V|r")
        else
            outputBox:SetHeight(OUTPUT_H_COLLAPSED)
            expLbl:SetText("|cffaaaaaa/\\|r")
        end
    end)

    local outputScroll = CreateFrame("ScrollingMessageFrame", "LichborneOutputMsgFrame", outputBox)
    outputScroll:SetPoint("TOPLEFT", outputBox, "TOPLEFT", 4, -20)
    outputScroll:SetPoint("BOTTOMRIGHT", outputBox, "BOTTOMRIGHT", -4, 4)
    outputScroll:SetFont("Fonts\\FRIZQT__.TTF", 9.5)
    outputScroll:SetJustifyH("LEFT")
    outputScroll:SetMaxLines(500)
    outputScroll:SetInsertMode("BOTTOM")
    outputScroll:SetFading(false)
    outputScroll:EnableMouseWheel(true)
    outputScroll:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then self:ScrollUp() else self:ScrollDown() end
    end)

    -- ── Export Data button (above output box, right-aligned) ─────
    local exportBtn = CreateFrame("Button", "LichborneExportBtn", f)
    exportBtn:SetPoint("BOTTOMRIGHT", outputBox, "TOPRIGHT", -2, 4)
    exportBtn:SetSize(24, 24)
    exportBtn:SetFrameLevel(fl + 12)
    exportBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    exportBtn:SetBackdropColor(0, 0, 0, 1)
    exportBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    exportBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local exportLbl = exportBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    exportLbl:SetAllPoints(exportBtn); exportLbl:SetJustifyH("CENTER"); exportLbl:SetJustifyV("MIDDLE")
    exportLbl:SetText("|cffd4af37>>|r")
    exportBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(exportBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("Export Tracker Data", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Saves all tracker data to a text string.", 1, 1, 1)
        GameTooltip:AddLine("Warning: Opening this window may", 1, 0.2, 0.2)
        GameTooltip:AddLine("take several minutes.", 1, 0.2, 0.2)
        GameTooltip:AddLine("Exports characters, raid rosters, and role data.", 1, 0.55, 0.0)
        GameTooltip:AddLine("Gear data is excluded — a fresh scan is needed.", 1, 0.55, 0.0)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("On Account A:", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("1. Click >> to open the export window.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("2. Click 'Select All' to highlight the text.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("3. Press Ctrl+C to copy.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("On Account B:", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("4. Log in and open Lichborne.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("5. Click << to open the import window.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("6. Click Select, press Ctrl+V to paste.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("7. Click Import to apply the data.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    exportBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- ── Import button (left of Export button) ──────────────────
    local importBtn = CreateFrame("Button", "LichborneImportBtn", f)
    importBtn:SetPoint("RIGHT", exportBtn, "LEFT", -2, 0)
    importBtn:SetSize(24, 24)
    importBtn:SetFrameLevel(fl + 12)
    importBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    importBtn:SetBackdropColor(0, 0, 0, 1)
    importBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    importBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local importLbl = importBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importLbl:SetAllPoints(importBtn); importLbl:SetJustifyH("CENTER"); importLbl:SetJustifyV("MIDDLE")
    importLbl:SetText("|cffd4af37<<|r")
    importBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(importBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("Import Tracker Data", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Loads tracker data from a copied export string.", 1, 1, 1)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("On Account A:", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("1. Click >> to open the export window.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("2. Click 'Select All' to highlight the text.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("3. Press Ctrl+C to copy.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("On Account B:", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("4. Log in and open Lichborne.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("5. Click << to open this import window.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("6. Click Select, press Ctrl+V to paste.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("7. Click Import to apply the data.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    importBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- ── Export popup ────────────────────────────────────────────
    local exportPopup = CreateFrame("Frame", "LichborneExportPopup", UIParent)
    exportPopup:SetSize(520, 320)
    exportPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    exportPopup:SetFrameStrata("FULLSCREEN_DIALOG")
    exportPopup:SetFrameLevel(200)
    exportPopup:SetMovable(true); exportPopup:EnableMouse(true)
    exportPopup:SetScript("OnMouseDown", function(self, btn) if btn=="LeftButton" then self:StartMoving() end end)
    exportPopup:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
    exportPopup:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,edgeSize=0,insets={left=0,right=0,top=0,bottom=0}})
    exportPopup:SetBackdropColor(0,0,0,1)
    exportPopup:Hide()

    local expTitle = exportPopup:CreateFontString(nil,"OVERLAY","GameFontNormal")
    expTitle:SetPoint("TOP",exportPopup,"TOP",0,-12)
    expTitle:SetText("|cffC69B3AExport Tracker Data|r")

    -- Dark inset behind the EditBox (no border — direct fill)
    local expBoxBg = CreateFrame("Frame", nil, exportPopup)
    expBoxBg:SetPoint("TOPLEFT",  exportPopup, "TOPLEFT",   0, -28)
    expBoxBg:SetPoint("BOTTOMRIGHT", exportPopup, "BOTTOMRIGHT", -8, 44)
    expBoxBg:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,edgeSize=0,insets={left=0,right=0,top=0,bottom=0}})
    expBoxBg:SetBackdropColor(0.02,0.02,0.06,1)
    expBoxBg:SetFrameLevel(exportPopup:GetFrameLevel() + 1)

    local expScroll = CreateFrame("ScrollFrame", nil, exportPopup)
    expScroll:SetPoint("TOPLEFT",     expBoxBg, "TOPLEFT",     2, -2)
    expScroll:SetPoint("BOTTOMRIGHT", expBoxBg, "BOTTOMRIGHT", -2,  2)
    expScroll:SetFrameLevel(exportPopup:GetFrameLevel() + 1)

    local expEditBox = CreateFrame("EditBox","LichborneExpEditBox",expScroll)
    expEditBox:SetMultiLine(true)
    expEditBox:SetMaxLetters(0)
    expEditBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    expEditBox:SetTextColor(1, 1, 1, 1)
    expEditBox:SetAutoFocus(false)
    expEditBox:EnableMouse(true)
    expEditBox:SetWidth(492)
    expEditBox:SetFrameLevel(exportPopup:GetFrameLevel() + 2)
    expEditBox:SetScript("OnEscapePressed", function() exportPopup:Hide() end)
    expScroll:SetScrollChild(expEditBox)

    local expSelectBtn = CreateFrame("Button",nil,exportPopup,"UIPanelButtonTemplate")
    expSelectBtn:SetSize(110,24); expSelectBtn:SetPoint("BOTTOMLEFT",exportPopup,"BOTTOMLEFT",8,10)
    expSelectBtn:SetText("Select All")
    expSelectBtn:SetFrameLevel(exportPopup:GetFrameLevel() + 3)
    expSelectBtn:SetScript("OnClick", function()
        expEditBox:SetFocus()
        expEditBox:HighlightText()
    end)

    local expHint = exportPopup:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    expHint:SetPoint("LEFT",expSelectBtn,"RIGHT",10,0)
    expHint:SetText("|cffd4af37Push Select All then Ctrl+C to copy|r")

    local expCloseBtn = CreateFrame("Button",nil,exportPopup,"UIPanelButtonTemplate")
    expCloseBtn:SetSize(100,24); expCloseBtn:SetPoint("BOTTOMRIGHT",exportPopup,"BOTTOMRIGHT",-8,10)
    expCloseBtn:SetText("Close")
    expCloseBtn:SetFrameLevel(exportPopup:GetFrameLevel() + 3)
    expCloseBtn:SetScript("OnClick", function() exportPopup:Hide() end)

    exportBtn:SetScript("OnClick", function()
        if exportPopup:IsShown() then exportPopup:Hide(); return end
        if _G["LichborneImportPopup"] then _G["LichborneImportPopup"]:Hide() end
        if _G["LichborneOptionsPanel"] then _G["LichborneOptionsPanel"]:Hide() end
        local blob = PBM.LB_ExportDB()
        expEditBox:SetText(blob)
        expEditBox:SetFocus()
        expEditBox:HighlightText()
        exportPopup:Show()
        LichborneOutput("|cffC69B3APBM:|r |cffd4af37Export ready — click Select All, then press Ctrl+C.|r")
    end)

    -- ── Import popup ────────────────────────────────────────────
    local importPopup = CreateFrame("Frame","LichborneImportPopup",UIParent)
    importPopup:SetSize(520,320)
    importPopup:SetPoint("CENTER",UIParent,"CENTER",0,40)
    importPopup:SetFrameStrata("FULLSCREEN_DIALOG")
    importPopup:SetFrameLevel(200)
    importPopup:SetMovable(true); importPopup:EnableMouse(true)
    importPopup:SetScript("OnMouseDown", function(self,btn) if btn=="LeftButton" then self:StartMoving() end end)
    importPopup:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
    importPopup:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,edgeSize=0,insets={left=0,right=0,top=0,bottom=0}})
    importPopup:SetBackdropColor(0,0,0,1)
    importPopup:Hide()

    local impTitle = importPopup:CreateFontString(nil,"OVERLAY","GameFontNormal")
    impTitle:SetPoint("TOP",importPopup,"TOP",0,-12)
    impTitle:SetText("|cffC69B3AImport Tracker Data|r")

    local impWarn = importPopup:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    impWarn:SetPoint("TOP",impTitle,"BOTTOM",0,-4)
    impWarn:SetWidth(480); impWarn:SetJustifyH("CENTER")
    impWarn:SetText("|cffff3333WARNING: Paste may take several minutes — do not close WoW!|r")

    local impBoxBg = CreateFrame("Frame",nil,importPopup)
    impBoxBg:SetPoint("TOPLEFT",  importPopup, "TOPLEFT",   0, -46)
    impBoxBg:SetPoint("BOTTOMRIGHT", importPopup, "BOTTOMRIGHT", 0, 62)
    impBoxBg:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,edgeSize=0,insets={left=0,right=0,top=0,bottom=0}})
    impBoxBg:SetBackdropColor(0,0,0,1)
    impBoxBg:SetFrameLevel(importPopup:GetFrameLevel() + 1)

    local impScroll = CreateFrame("ScrollFrame", nil, importPopup)
    impScroll:SetPoint("TOPLEFT",     impBoxBg, "TOPLEFT",     2, -2)
    impScroll:SetPoint("BOTTOMRIGHT", impBoxBg, "BOTTOMRIGHT", -2,  2)
    impScroll:SetFrameLevel(importPopup:GetFrameLevel() + 1)

    local impEditBox = CreateFrame("EditBox","LichborneImpEditBox",impScroll)
    impEditBox:SetMultiLine(true)
    impEditBox:SetMaxLetters(0)
    impEditBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    impEditBox:SetTextColor(1, 1, 1, 1)
    impEditBox:SetAutoFocus(false)
    impEditBox:EnableMouse(true)
    impEditBox:SetWidth(492)
    impEditBox:SetFrameLevel(importPopup:GetFrameLevel() + 2)
    impEditBox:SetScript("OnEscapePressed", function() importPopup:Hide() end)
    impScroll:SetScrollChild(impEditBox)

    -- Status / confirm label (reused for both error and "are you sure?" text)
    local impStatus = importPopup:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    impStatus:SetPoint("BOTTOM",importPopup,"BOTTOM",0,30)
    impStatus:SetWidth(500); impStatus:SetJustifyH("CENTER")
    impStatus:SetText("")

    -- Normal bottom buttons
    local impPasteBtn = CreateFrame("Button",nil,importPopup,"UIPanelButtonTemplate")
    impPasteBtn:SetSize(100,24); impPasteBtn:SetPoint("BOTTOMLEFT",importPopup,"BOTTOMLEFT",8,10)
    impPasteBtn:SetText("Select")
    impPasteBtn:SetFrameLevel(importPopup:GetFrameLevel() + 3)
    impPasteBtn:SetScript("OnClick", function() impEditBox:SetFocus() end)

    local impHint = importPopup:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    impHint:SetPoint("CENTER",importPopup,"BOTTOM",0,22)
    impHint:SetWidth(500); impHint:SetJustifyH("CENTER")
    impHint:SetText("|cffd4af37Click Select, press Ctrl+V to paste, then click Import.|r")

    -- X close button — top right corner
    local impCancelBtn = CreateFrame("Button",nil,importPopup)
    impCancelBtn:SetSize(22,22)
    impCancelBtn:SetPoint("TOPRIGHT",importPopup,"TOPRIGHT",-6,-6)
    impCancelBtn:SetFrameLevel(importPopup:GetFrameLevel() + 3)
    impCancelBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    impCancelBtn:SetBackdropColor(0.25,0.04,0.04,1)
    impCancelBtn:SetBackdropBorderColor(0.8,0.1,0.1,1)
    impCancelBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local impCancelLbl = impCancelBtn:CreateFontString(nil,"OVERLAY","GameFontNormal")
    impCancelLbl:SetAllPoints(impCancelBtn); impCancelLbl:SetJustifyH("CENTER")
    impCancelLbl:SetText("|cffff4444X|r")

    -- Import button — bottom right
    local impDoBtn = CreateFrame("Button",nil,importPopup,"UIPanelButtonTemplate")
    impDoBtn:SetSize(100,24); impDoBtn:SetPoint("BOTTOMRIGHT",importPopup,"BOTTOMRIGHT",-8,10)
    impDoBtn:SetText("Import")
    impDoBtn:SetFrameLevel(importPopup:GetFrameLevel() + 3)

    -- Inline confirm buttons — centered pair (150+10+110=270px, start at (520-270)/2=125)
    local impYesBtn = CreateFrame("Button",nil,importPopup,"UIPanelButtonTemplate")
    impYesBtn:SetSize(150,24); impYesBtn:SetPoint("BOTTOMLEFT",importPopup,"BOTTOMLEFT",125,10)
    impYesBtn:SetText("Yes, Replace Data")
    impYesBtn:SetFrameLevel(importPopup:GetFrameLevel() + 3)
    impYesBtn:Hide()

    local impNoBtn = CreateFrame("Button",nil,importPopup,"UIPanelButtonTemplate")
    impNoBtn:SetSize(110,24); impNoBtn:SetPoint("LEFT",impYesBtn,"RIGHT",10,0)
    impNoBtn:SetText("No, Go Back")
    impNoBtn:SetFrameLevel(importPopup:GetFrameLevel() + 3)
    impNoBtn:Hide()

    local function impShowNormal()
        impPasteBtn:Show(); impDoBtn:Show()
        impYesBtn:Hide(); impNoBtn:Hide()
        impHint:Show()
        impStatus:SetText("")
    end

    local function impShowConfirm()
        impPasteBtn:Hide(); impDoBtn:Hide()
        impYesBtn:Show(); impNoBtn:Show()
        impHint:Hide()
        impStatus:SetPoint("BOTTOM",importPopup,"BOTTOM",0,42)
        impStatus:SetText("|cffC69B3AReplace ALL tracker data? This cannot be undone.|r")
    end

    local pendingImport = nil

    impNoBtn:SetScript("OnClick", function()
        pendingImport = nil
        impShowNormal()
    end)

    impYesBtn:SetScript("OnClick", function()
        if not pendingImport then impShowNormal(); return end
        local db = LichborneTrackerDB
        if pendingImport.rows        then db.rows        = pendingImport.rows        end
        if pendingImport.profs       then db.profs       = pendingImport.profs       end
        if pendingImport.raidRosters then db.raidRosters = pendingImport.raidRosters end
        if pendingImport.allGroups   then db.allGroups   = pendingImport.allGroups   end
        if pendingImport.allGroup    then db.allGroup    = pendingImport.allGroup    end
        if pendingImport.notes       then db.notes       = pendingImport.notes       end
        -- raidName/raidSize/raidGroup/raidTier are intentionally NOT imported;
        -- they are per-account settings and should not be overwritten by Account A's config.
        -- botNotes (roles/notes) ARE imported — they describe character behavior, not account config.
        -- Initialize gear fields on imported rows (ilvl array, ilvlLink, gs, realGs)
        -- since V3 exports strip gear data — PBM.MigrateGearField fills in the defaults.
        PBM.MigrateGearField()
        pendingImport = nil
        importPopup:Hide()
        impShowNormal()
        if PBM.RefreshRows then PBM.RefreshRows() end
        if LichborneRaidFrame then PBM.RefreshRaidRows() end
        if PBM.State.LichborneOverviewFrame  then PBM.RefreshOverviewRows()  end
        PBM.UpdateSummary()
        LichborneOutput("|cffC69B3APBM:|r |cffd4af37Import complete — tracker data loaded.|r")
    end)

    impDoBtn:SetScript("OnClick", function()
        local raw = impEditBox:GetText()
        local result, err = PBM.LB_ImportDB(raw)
        if not result then
            impStatus:SetText("|cffff4444Error: " .. (err or "unknown") .. "|r")
            return
        end
        pendingImport = result
        impShowConfirm()
    end)

    impCancelBtn:SetScript("OnClick", function() importPopup:Hide() end)

    importPopup:SetScript("OnHide", function() pendingImport = nil; impShowNormal() end)

    importBtn:SetScript("OnClick", function()
        if importPopup:IsShown() then importPopup:Hide(); return end
        if _G["LichborneExportPopup"] then _G["LichborneExportPopup"]:Hide() end
        if _G["LichborneOptionsPanel"] then _G["LichborneOptionsPanel"]:Hide() end
        impEditBox:SetText("")
        impShowNormal()
        impEditBox:SetFocus()
        importPopup:Show()
    end)

    -- ── Help button (left of Import button) ────────────────────
    local helpBtn = CreateFrame("Button", "LichborneHelpBtn", f)
    helpBtn:SetPoint("RIGHT", importBtn, "LEFT", -2, 0)
    helpBtn:SetSize(24, 24)
    helpBtn:SetFrameLevel(fl + 12)
    -- no backdrop
    helpBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local helpIcon = helpBtn:CreateTexture(nil, "OVERLAY")
    helpIcon:SetPoint("CENTER", helpBtn, "CENTER", 0, 0)
    helpIcon:SetSize(22, 22)
    helpIcon:SetTexture("Interface\\Icons\\Inv_misc_book_08")
    helpBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(helpBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("SETTING UP YOUR TRACKER", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("For First Time Use", 0.4, 0.8, 1)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("1. Add your PlayerBots to the group.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("2. Click |cff4488FF+Full Group Scan|r to |cffC69B3Aadd bots,|r gear score", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   |cffC69B3A(GS)|r, |cffC69B3AiLvL|r, |cffC69B3Agear,|r |cffC69B3Aspecialization,|r and", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   |cffC69B3APlayerbot Strategies|r to the tracker.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   Allow 4-5 minutes for a complete scan.", 1, 0.55, 0.0)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("TIP: Use |cffC69B3A.playerbot bot addaccount <account>|r to", 0.4, 0.8, 1)
        GameTooltip:AddLine("     quickly add bots for first time set up.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: |cffC69B3A+Add Target|r buttons are used for |cffC69B3ASingle|r scans.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: |cffC69B3A+Add Group|r buttons are used for |cffC69B3AGroup|r scans.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: |cffC69B3ARemove Orphaned Bots|r removes bots currently not", 0.4, 0.8, 1)
        GameTooltip:AddLine("     in your group. (.playerbot bot remove)", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: |cffC69B3ADisband Group|r removes PlayerBots before", 0.4, 0.8, 1)
        GameTooltip:AddLine("     disbanding the group.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: |cffC69B3AStop Scan|r stops the current scan.", 0.4, 0.8, 1)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cffC69B3ANote:|r All |cffC69B3AScans|r add characters to the tracker before", 0.4, 0.8, 1)
        GameTooltip:AddLine("     executing, to prevent corruption.", 0.4, 0.8, 1)
        GameTooltip:Show()
    end)
    helpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- ── Raid Tab help button ──────────────────────────────────────
    local raidHelpBtn = CreateFrame("Button", "LichborneRaidHelpBtn", f)
    raidHelpBtn:SetPoint("RIGHT", helpBtn, "LEFT", -2, 0)
    raidHelpBtn:SetSize(24, 24)
    raidHelpBtn:SetFrameLevel(fl + 12)
    raidHelpBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local raidHelpIcon = raidHelpBtn:CreateTexture(nil, "OVERLAY")
    raidHelpIcon:SetPoint("CENTER", raidHelpBtn, "CENTER", 0, 0)
    raidHelpIcon:SetSize(22, 22)
    raidHelpIcon:SetTexture("Interface\\Icons\\Inv_misc_book_06")
    raidHelpBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(raidHelpBtn, "ANCHOR_LEFT")
        GameTooltip:AddLine("RAID TAB", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Allows you to plan raid configurations,", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("invite groups, and select roles for your", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("PlayerBot team.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("For Groups:", 0.27, 0.53, 1)
        GameTooltip:AddLine("1. Select the |cff4488ffTO 5-Man Dungeons|r tab.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("2. Add characters via the Class or Overview tabs.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("3. Click |cff4488ffINVITE GROUP|r at the bottom of", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   the tracker to log in your PlayerBots.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("For Raids:", 1, 0.4, 0)
        GameTooltip:AddLine("1. Pick a Tier and Raid from the dropdowns", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   in the raid table header.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("2. Add characters via the Class or Overview tabs.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("3. Click |cffFF6600INVITE RAID|r at the bottom of", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   the tracker to log in your PlayerBots.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("TIP: |cffC69B3AInvite Group|r always invites your 5-Man team,", 0.4, 0.8, 1)
        GameTooltip:AddLine("     regardless of which raid tab is active.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: |cffC69B3AInvite Raid|r always invites from the", 0.4, 0.8, 1)
        GameTooltip:AddLine("     currently selected raid.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: You can have multiple raid configurations", 0.4, 0.8, 1)
        GameTooltip:AddLine("     for each raid.  Use the dropdown menu located", 0.4, 0.8, 1)
        GameTooltip:AddLine("     in the header (|cffC69B3AA, B, C|r).", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Use |cffC69B3ACopy|r to duplicate your selected config", 0.4, 0.8, 1)
        GameTooltip:AddLine("     into another raid category (see header).", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Use |cffC69B3AClear|r (next to Copy) to reset your", 0.4, 0.8, 1)
        GameTooltip:AddLine("     current selected raid.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Raid configurations are saved after reloads.", 0.4, 0.8, 1)
        GameTooltip:AddLine("     You must manually clear them.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Assign |cffC69B3ARoles|r (Tank, Healer, DPS)", 0.4, 0.8, 1)
        GameTooltip:AddLine("     by clicking the Roles Column.  Write", 0.4, 0.8, 1)
        GameTooltip:AddLine("     notes to help keep organized.", 0.4, 0.8, 1)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cffC69B3ANote:|r All Raids have a unique table that work", 0.4, 0.8, 1)
        GameTooltip:AddLine("     |cffC69B3Aindependently|r of each other.", 0.4, 0.8, 1)
        GameTooltip:Show()
    end)
    raidHelpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- ── Class Tab help button ─────────────────────────────────────
    local classHelpBtn = CreateFrame("Button", "LichborneClassHelpBtn", f)
    classHelpBtn:SetPoint("RIGHT", raidHelpBtn, "LEFT", -2, 0)
    classHelpBtn:SetSize(24, 24)
    classHelpBtn:SetFrameLevel(fl + 12)
    classHelpBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local classHelpIcon = classHelpBtn:CreateTexture(nil, "OVERLAY")
    classHelpIcon:SetPoint("CENTER", classHelpBtn, "CENTER", 0, 0)
    classHelpIcon:SetSize(22, 22)
    classHelpIcon:SetTexture("Interface\\Icons\\Inv_misc_book_01")
    classHelpBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(classHelpBtn, "ANCHOR_LEFT")
        GameTooltip:AddLine("CLASS TABS", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Each class has its own dedicated tab.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("1. Scan to add gear score (|cffC69B3AGS|r), |cffC69B3AiLvL|r and gear.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("2. Hover on a gear slot to view the equipped item.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("3. The |cffC69B3AiLvL|r and |cffC69B3AGS|r is calculated after a scan", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   (not manual edits)", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("4. After a gear upgrade, it is suggested to use", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   |cff4488FF+Add Target Gear|r to update the row.  OR", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   |cff4488FF+Add Group Gear|r at the end of the raid.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   Gear only updates after a scan, not on equip.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("TIP: Click any column header to |cffC69B3ASort|r.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Use the |cffC69B3AProf|r cell to track a character's", 0.4, 0.8, 1)
        GameTooltip:AddLine("     profession, gear needs, or role.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: You can change the spec by clicking the icon.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Click |cff00cc00[+]|r on a PlayerBot row to add to the", 0.4, 0.8, 1)
        GameTooltip:AddLine("     |cffC69B3ARaid Tab|r.  Right-click |cffFF6600[+]|r to remove.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Click |cff00cc00[>]|r to invite PlayerBot to your", 0.4, 0.8, 1)
        GameTooltip:AddLine("     |cffC69B3AGroup|r.  Right-click |cff00cc00[>]|r to remove.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Use |cff66CCFFDelete Character|r |cffff3333[x]|r to remove", 0.4, 0.8, 1)
        GameTooltip:AddLine("     PlayerBots from your tracker.", 0.4, 0.8, 1)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cffC69B3ANote:|r Some |cff00cc00<Random Enchantment>|r gear may", 0.4, 0.8, 1)
        GameTooltip:AddLine("     not display correctly.", 0.4, 0.8, 1)
        GameTooltip:AddLine("|cffC69B3ANote:|r Some items may display with a 0 Gear Score.", 0.4, 0.8, 1)
        GameTooltip:AddLine("     Such as PvP gear.", 0.4, 0.8, 1)
        GameTooltip:Show()
    end)
    classHelpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- ── Setting up Playerbots help button ─────────────────────────
    local setupHelpBtn = CreateFrame("Button", "LichborneSetupHelpBtn", f)
    setupHelpBtn:SetPoint("RIGHT", classHelpBtn, "LEFT", -2, 0)
    setupHelpBtn:SetSize(24, 24)
    setupHelpBtn:SetFrameLevel(fl + 12)
    setupHelpBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local setupHelpIcon = setupHelpBtn:CreateTexture(nil, "OVERLAY")
    setupHelpIcon:SetPoint("CENTER", setupHelpBtn, "CENTER", 0, 0)
    setupHelpIcon:SetSize(22, 22)
    setupHelpIcon:SetTexture("Interface\\Icons\\inv_misc_book_11")
    setupHelpBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(setupHelpBtn, "ANCHOR_LEFT")
        GameTooltip:AddLine("SETTING UP PLAYERBOTS", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("|cffd4af37Linking Accounts|r", 1, 1, 1)
        GameTooltip:AddLine("Linking sets you as the |cffFF8C00owner|r of bots on other accounts.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("|cffff4444Requires:|r  AiPlayerbot.AllowTrustedAccountBots = 1", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("  |cff69CCF0.playerbots account setKey <key>|r", 1, 1, 1)
        GameTooltip:AddLine("  |cff69CCF0.playerbots account link <acct> <key>|r", 1, 1, 1)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cffFF8C00Altbots|r", 1, 1, 1)
        GameTooltip:AddLine("Characters you create on your account (or a linked", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("account) that you log in as bots. You control them,", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("party with them, and they persist.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("They follow their own IP progression tier.", 1, 0.55, 0.0)
        GameTooltip:AddLine("  |cff69CCF0.playerbots bot add <name>|r", 1, 1, 1)
        GameTooltip:AddLine("  |cff69CCF0.playerbots bot addaccount <account>|r", 1, 1, 1)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cffFF8C00Rndbots|r", 1, 1, 1)
        GameTooltip:AddLine("Server-generated bots that populate the world", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("automatically. No manual setup needed.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("They follow the group leader's IP tier.", 1, 0.55, 0.0)
        GameTooltip:AddLine("  |cff69CCF0.playerbots bot addclass <class>|r", 1, 1, 1)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cffd4af37GitHub:|r  github.com/mod-playerbots/mod-playerbots", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    setupHelpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- ── Overview Tab help button ──────────────────────────────────
    local overviewHelpBtn = CreateFrame("Button", "LichborneOverviewHelpBtn", f)
    overviewHelpBtn:SetPoint("RIGHT", raidHelpBtn, "LEFT", -2, 0)
    overviewHelpBtn:SetSize(24, 24)
    overviewHelpBtn:SetFrameLevel(fl + 12)
    overviewHelpBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local overviewHelpIcon = overviewHelpBtn:CreateTexture(nil, "OVERLAY")
    overviewHelpIcon:SetPoint("CENTER", overviewHelpBtn, "CENTER", 0, 0)
    overviewHelpIcon:SetSize(22, 22)
    overviewHelpIcon:SetTexture("Interface\\Icons\\Inv_misc_book_05")
    overviewHelpBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(overviewHelpBtn, "ANCHOR_LEFT")
        GameTooltip:AddLine("OVERVIEW TAB", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Provides an overview of all current PlayerBots", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("you have in your tracker.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("1. Click |cff00cc00[+]|r on a PlayerBot row to add to the", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   selected raid. (in |cffC69B3ARaid Tab|r)", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   Right-click |cffFF6600[+]|r to remove from raid.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("2. Click |cff00cc00[>]|r to invite a PlayerBot to your |cffC69B3AGroup|r.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   Right-click to remove from your |cffC69B3AGroup|r.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("3. If you have more than 60 characters, use the", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   |cffC69B3APage|r dropdown in the header to view overflow.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("TIP: Click any column header to |cffC69B3ASort|r.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Use Delete Character |cffff3333[x]|r to remove", 0.4, 0.8, 1)
        GameTooltip:AddLine("     PlayerBots from your tracker.", 0.4, 0.8, 1)
        GameTooltip:Show()
    end)
    overviewHelpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local bookHelpBtn = CreateFrame("Button", "LichborneBookHelpBtn", f)
    bookHelpBtn:SetPoint("RIGHT", adminLbl, "LEFT", -2, 0)
    bookHelpBtn:SetSize(24, 24)
    bookHelpBtn:SetFrameLevel(fl + 12)
    bookHelpBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local bookHelpIcon = bookHelpBtn:CreateTexture(nil, "OVERLAY")
    bookHelpIcon:SetPoint("CENTER", bookHelpBtn, "CENTER", 0, 0)
    bookHelpIcon:SetSize(22, 22)
    bookHelpIcon:SetTexture("Interface\\Icons\\inv_misc_book_07")
    bookHelpBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(bookHelpBtn, "ANCHOR_LEFT")
        GameTooltip:AddLine("CLASS STRATEGIES", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Strategies control what your PlayerBots do in combat.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Each bot can have its own unique strategy loadout.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("HOW TO OPEN THE STRATEGIES MENU", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("1. Go to any |cffC69B3AClass Tab|r (Warrior, Priest, etc.)", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("2. Click on a |cffC69B3Acharacter's name|r in the table.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("3. This opens that bot's |cffC69B3AStrategies Menu|r.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("4. Toggle individual strategies on/off from there.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("HOW STRATEGIES WORK", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Strategies are behavior modifiers — they tell the bot", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("which spells to cast, when to use cooldowns, how to", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("position, and what role to fill during combat.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Strategies stack — multiple can be active at once.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("USING TEMPLATES  |cffC69B3A(Recommended)|r", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Instead of toggling strategies one by one, use", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("|cffC69B3ATemplates|r — pre-built strategy sets optimized", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("for each spec and role.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Templates are found in each |cffC69B3AClass Tab|r — click |cffC69B3A?|r", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("or the |cffC69B3ASpec icon|r in the top-left of the tab.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("TIP: Always set strategies via a |cffC69B3ATemplate|r first,", 0.4, 0.8, 1)
        GameTooltip:AddLine("     then fine-tune individual strategies if needed.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Bots retain their strategies between sessions.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: |cffC69B3ACO|r is Combat Strategies.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: |cffC69B3ANC|r is Non-Combat Strategies.", 0.4, 0.8, 1)
        GameTooltip:Show()
    end)
    bookHelpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- ── LevelSync help button ─────────────────────────────────────
    local levelSyncHelpBtn = CreateFrame("Button", "LichborneLevelSyncHelpBtn", f)
    levelSyncHelpBtn:SetPoint("RIGHT", bookHelpBtn, "LEFT", -2, 0)
    levelSyncHelpBtn:SetSize(24, 24)
    levelSyncHelpBtn:SetFrameLevel(fl + 12)
    levelSyncHelpBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local levelSyncHelpIcon = levelSyncHelpBtn:CreateTexture(nil, "OVERLAY")
    levelSyncHelpIcon:SetPoint("CENTER", levelSyncHelpBtn, "CENTER", 0, 0)
    levelSyncHelpIcon:SetSize(22, 22)
    levelSyncHelpIcon:SetTexture("Interface\\Icons\\inv_misc_groupneedmore")
    levelSyncHelpBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(levelSyncHelpBtn, "ANCHOR_LEFT")
        GameTooltip:AddLine("LEVELSYNC", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("This was added for my personal server to give players", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("the ability to run a full raid without leveling 40+", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("characters. It is designed for |cffFF8C00large altbot setups|r.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("LevelSync is a shortcut to set your characters'", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("IP levels and tiers automatically across accounts.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cffff4444Level sync and IP sync are not recommended for all players.|r", 1, 1, 1)
        GameTooltip:AddLine("|cffff4444Use at your own risk.  Double check entries before toggles.|r", 1, 1, 1)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cffd4af37Toggle Only|r", 1, 1, 1)
        GameTooltip:AddLine("LevelSync must first be enabled by the server, then", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("toggled by the player. It will not fire until both", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("conditions are met. Syncs do not run automatically", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("— you must enter the toggle command to fire each sync.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("  |cff69CCF0.levelsync level on|r  /  |cff69CCF0.levelsync IP on|r", 1, 1, 1)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cffd4af37Pool Gold|r", 1, 1, 1)
        GameTooltip:AddLine("Collects all gold from every member of your level", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("sync group and transfers it to the caller.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("  |cff69CCF0.levelsync money|r", 1, 1, 1)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("To learn how to use LevelSync, see the", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("|cffd4af37LevelSync Tab|r in this addon.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cffd4af37GitHub:|r  github.com/Lichborne-AC/mod-levelsync", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    levelSyncHelpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Options panel (DBM-style, Update tab)
    local optionsPanel = CreateFrame("Frame", "LichborneOptionsPanel", UIParent)
    optionsPanel:SetSize(500, 420)
    optionsPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    optionsPanel:SetFrameStrata("FULLSCREEN_DIALOG")
    optionsPanel:SetFrameLevel(200)
    optionsPanel:SetMovable(true)
    optionsPanel:EnableMouse(true)
    optionsPanel:SetScript("OnMouseDown", function(self, btn) if btn == "LeftButton" then self:StartMoving() end end)
    optionsPanel:SetScript("OnMouseUp",   function(self) self:StopMovingOrSizing() end)
    optionsPanel:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=16,
        insets={left=5, right=5, top=5, bottom=5}
    })
    optionsPanel:SetBackdropColor(0.06, 0.07, 0.14, 0.98)
    optionsPanel:SetBackdropBorderColor(0.50, 0.50, 0.50, 1)
    optionsPanel:Hide()

    -- Title bar
    local optsTitleBg = optionsPanel:CreateTexture(nil, "ARTWORK")
    optsTitleBg:SetPoint("TOPLEFT",  optionsPanel, "TOPLEFT",  6, -6)
    optsTitleBg:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", -6, -6)
    optsTitleBg:SetHeight(30)
    optsTitleBg:SetTexture(0.07, 0.09, 0.20, 1)

    local optsTitleText = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    optsTitleText:SetPoint("CENTER", optsTitleBg, "CENTER", 0, 0)
    optsTitleText:SetText("|cffC69B3APlayerbot Manager|r")

    local optsXBtn = CreateFrame("Button", nil, optionsPanel, "UIPanelCloseButton")
    optsXBtn:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", 4, 4)
    optsXBtn:SetFrameLevel(optionsPanel:GetFrameLevel() + 3)
    optsXBtn:SetScript("OnClick", function() optionsPanel:Hide() end)

    local optsTitleDiv = optionsPanel:CreateTexture(nil, "OVERLAY")
    optsTitleDiv:SetPoint("TOPLEFT",  optionsPanel, "TOPLEFT",  6, -36)
    optsTitleDiv:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", -6, -36)
    optsTitleDiv:SetHeight(1)
    optsTitleDiv:SetTexture(0.78, 0.61, 0.23, 0.9)

    local function MakeOptsTab(label, x, w)
        local btn = CreateFrame("Button", nil, optionsPanel)
        btn:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", x, -40)
        btn:SetSize(w or 100, 24)
        btn:SetFrameLevel(optionsPanel:GetFrameLevel() + 2)
        btn:SetBackdrop({
            bgFile="Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
            tile=true, tileSize=16, edgeSize=8,
            insets={left=2, right=2, top=2, bottom=2}
        })
        btn:SetBackdropColor(0.12, 0.16, 0.30, 1)
        btn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints(btn); lbl:SetJustifyH("CENTER")
        lbl:SetText("|cffFFFFFF"..label.."|r")
        btn.lbl = lbl
        return btn
    end

    local optsTabChanges = MakeOptsTab("Recent Changes", 8)
    local optsTabOptions = MakeOptsTab("Show/Hide",     112, 84)
    local optsTabData    = MakeOptsTab("Data",           200, 84)
    local optsTabGeneral = MakeOptsTab("Links",          288, 84)
    local optsTabCredits = MakeOptsTab("Credits",        376, 84)

    -- ── Options tab content ───────────────────────────────────────────
    local optsOptionsBox = CreateFrame("Frame", nil, optionsPanel)
    optsOptionsBox:SetPoint("TOPLEFT",     optionsPanel, "TOPLEFT",    6, -66)
    optsOptionsBox:SetPoint("BOTTOMRIGHT", optionsPanel, "BOTTOMRIGHT", -6, 48)
    optsOptionsBox:SetFrameLevel(optionsPanel:GetFrameLevel() + 1)
    optsOptionsBox:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=8,
        insets={left=3, right=3, top=3, bottom=3}
    })
    optsOptionsBox:SetBackdropColor(0.03, 0.04, 0.09, 1)
    optsOptionsBox:SetBackdropBorderColor(0.60, 0.60, 0.60, 0.8)
    optsOptionsBox:Hide()

    -- Forward reference: assigned after confirmAll is created below
    if not StaticPopupDialogs["PBM_CLEAR_ALL_DATA"] then
        StaticPopupDialogs["PBM_CLEAR_ALL_DATA"] = {
            text = "|cffd4af37Clear All Data|r\n\nThis permanently deletes ALL tracked characters,\ngear data, raid rosters, and the Overview list.\n|cffff4444This cannot be undone.|r",
            button1 = "Yes, Clear All",
            button2 = "Cancel",
            OnAccept = function()
                LichborneTrackerDB.rows        = {}
                LichborneTrackerDB.raidRosters = {}
                LichborneTrackerDB.needs       = {}
                LichborneTrackerDB.profs       = {}
                LichborneTrackerDB.botNotes    = {}
                LichborneTrackerDB.allGroups   = {A={}, B={}, C={}}
                for _, g in ipairs({"A", "B", "C"}) do
                    for i = 1, 60 do
                        LichborneTrackerDB.allGroups[g][i] = {name="",cls="",spec="",gs=0,realGs=0}
                    end
                end
                LichborneOutput("|cffC69B3APBM:|r |cffff4444All data wiped.|r", 1, 0.5, 0.5)
                PBM.RefreshRows()
                if PBM.State.LichborneOverviewFrame then PBM.RefreshOverviewRows() end
                if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
            end,
            timeout      = 0,
            whileDead    = true,
            hideOnEscape = true,
        }
    end

    local _optShowConfirmAll = function() StaticPopup_Show("PBM_CLEAR_ALL_DATA") end

    do
        local OPT_FL    = optionsPanel:GetFrameLevel() + 2
        local OPT_FONT  = "Fonts\\FRIZQT__.TTF"
        local OPT_GR, OPT_GG, OPT_GB = 0.78, 0.61, 0.23
        local OPT_MX    = 14
        local OPT_BTN_H = 26

        local optSecHdr = optsOptionsBox:CreateFontString(nil, "OVERLAY")
        optSecHdr:SetFont(OPT_FONT, 11, "OUTLINE")
        optSecHdr:SetPoint("TOPLEFT", optsOptionsBox, "TOPLEFT", OPT_MX, -14)
        optSecHdr:SetTextColor(OPT_GR, OPT_GG, OPT_GB)
        optSecHdr:SetText("Data Management")

        local optSecDiv = optsOptionsBox:CreateTexture(nil, "ARTWORK")
        optSecDiv:SetPoint("TOPLEFT",  optsOptionsBox, "TOPLEFT",  OPT_MX, -28)
        optSecDiv:SetPoint("TOPRIGHT", optsOptionsBox, "TOPRIGHT", -OPT_MX, -28)
        optSecDiv:SetHeight(1)
        optSecDiv:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        optSecDiv:SetVertexColor(OPT_GR, OPT_GG, OPT_GB, 0.5)

        local function OptActionBtn(yTop, label, desc, r, g, b, clickFn)
            local btn = CreateFrame("Button", nil, optsOptionsBox)
            btn:SetPoint("TOPLEFT",  optsOptionsBox, "TOPLEFT",  OPT_MX, yTop)
            btn:SetPoint("TOPRIGHT", optsOptionsBox, "TOPRIGHT", -OPT_MX, yTop)
            btn:SetHeight(OPT_BTN_H)
            btn:SetFrameLevel(OPT_FL)
            btn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=3,right=3,top=3,bottom=3}})
            btn:SetBackdropColor(r, g, b, 1)
            btn:SetBackdropBorderColor(OPT_GR, OPT_GG, OPT_GB, 0.85)
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(OPT_FONT, 10, "OUTLINE")
            lbl:SetAllPoints(btn); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
            lbl:SetText("|cffd4af37"..label.."|r")
            local dfs = optsOptionsBox:CreateFontString(nil, "OVERLAY")
            dfs:SetFont(OPT_FONT, 9, "OUTLINE")
            dfs:SetPoint("TOPLEFT",  optsOptionsBox, "TOPLEFT",  OPT_MX + 4, yTop - OPT_BTN_H - 3)
            dfs:SetPoint("TOPRIGHT", optsOptionsBox, "TOPRIGHT", -OPT_MX,    yTop - OPT_BTN_H - 3)
            dfs:SetJustifyH("CENTER")
            dfs:SetTextColor(0.72, 0.72, 0.72)
            dfs:SetText(desc)
            btn:SetScript("OnClick", clickFn)
        end

        OptActionBtn(-34,
            "Export Data",
            "Export all tracked character and raid data to a string.  Click Select All, then Ctrl+C to copy.",
            0.04, 0.07, 0.14,
            function()
                if exportPopup:IsShown() then exportPopup:Hide(); return end
                if _G["LichborneImportPopup"] then _G["LichborneImportPopup"]:Hide() end
                optionsPanel:Hide()
                local blob = PBM.LB_ExportDB()
                expEditBox:SetText(blob)
                expEditBox:SetFocus(); expEditBox:HighlightText()
                exportPopup:Show()
                LichborneOutput("|cffC69B3APBM:|r |cffd4af37Export ready — click Select All, then press Ctrl+C.|r")
            end)

        OptActionBtn(-104,
            "Import Data",
            "Load tracker data from a previously exported string.  Paste the export string and click Import.",
            0.04, 0.07, 0.14,
            function()
                if importPopup:IsShown() then importPopup:Hide(); return end
                if _G["LichborneExportPopup"] then _G["LichborneExportPopup"]:Hide() end
                optionsPanel:Hide()
                impEditBox:SetText("")
                impShowNormal()
                impEditBox:SetFocus()
                importPopup:Show()
            end)

        OptActionBtn(-174,
            "Clear All Data",
            "|cffff6666Permanently deletes ALL tracked characters, gear data,\nraid rosters, and the Overview list.  This cannot be undone.|r",
            0.22, 0.03, 0.03,
            function()
                optionsPanel:Hide()
                _optShowConfirmAll()
            end)
    end

    -- Content area (the bordered box like DBM)
    local optsContentBox = CreateFrame("Frame", nil, optionsPanel)
    optsContentBox:SetPoint("TOPLEFT",     optionsPanel, "TOPLEFT",    6, -66)
    optsContentBox:SetPoint("BOTTOMRIGHT", optionsPanel, "BOTTOMRIGHT", -6, 48)
    optsContentBox:SetFrameLevel(optionsPanel:GetFrameLevel() + 1)
    optsContentBox:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=8,
        insets={left=3, right=3, top=3, bottom=3}
    })
    optsContentBox:SetBackdropColor(0.03, 0.04, 0.09, 1)
    optsContentBox:SetBackdropBorderColor(0.60, 0.60, 0.60, 0.8)
    -- ── Links tab content (scrollable) ───────────────────────────────
    local LNK_GOLD_R, LNK_GOLD_G, LNK_GOLD_B = 0.78, 0.61, 0.23
    local lnkFL = optionsPanel:GetFrameLevel()

    local linksScroll = CreateFrame("ScrollFrame", "PBMLinksScrollFrame", optsContentBox)
    linksScroll:SetPoint("TOPLEFT",     optsContentBox, "TOPLEFT",      4,  -4)
    linksScroll:SetPoint("BOTTOMRIGHT", optsContentBox, "BOTTOMRIGHT", -22,  4)
    linksScroll:SetFrameLevel(lnkFL + 2)
    linksScroll:EnableMouseWheel(true)
    linksScroll:SetScript("OnMouseWheel", function(self, delta)
        local new = math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 40))
        self:SetVerticalScroll(new)
    end)

    local linksChild = CreateFrame("Frame", nil, linksScroll)
    linksChild:SetSize(920, 600)
    linksScroll:SetScrollChild(linksChild)

    -- Scrollbar
    local linksBar = CreateFrame("Slider", "PBMLinksScrollBar", optsContentBox, "UIPanelScrollBarTemplate")
    linksBar:SetPoint("TOPLEFT",    linksScroll, "TOPRIGHT",    4, -16)
    linksBar:SetPoint("BOTTOMLEFT", linksScroll, "BOTTOMRIGHT", 4,  16)
    linksBar:SetMinMaxValues(0, 1)
    linksBar:SetValueStep(1)
    linksBar:SetScript("OnValueChanged", function(self, value)
        linksScroll:SetVerticalScroll(value)
    end)
    linksBar:SetValue(0)
    linksBar:SetFrameLevel(lnkFL + 3)
    linksScroll:SetScript("OnScrollRangeChanged", function(self, _, yrange)
        local range = math.max(yrange or 0, 1)
        linksBar:SetMinMaxValues(0, range)
        linksBar:SetValue(self:GetVerticalScroll())
    end)
    linksScroll:SetScript("OnVerticalScroll", function(self, offset)
        linksBar:SetValue(offset)
    end)

    local function LnkSep(y)
        local t = linksChild:CreateTexture(nil, "ARTWORK")
        t:SetPoint("TOPLEFT",  linksChild, "TOPLEFT",  10, y)
        t:SetPoint("TOPRIGHT", linksChild, "TOPRIGHT", -10, y)
        t:SetHeight(2)
        t:SetTexture(LNK_GOLD_R, LNK_GOLD_G, LNK_GOLD_B, 0.7)
    end

    local function LnkEntry(label, url, y, ebName)
        local lbl = linksChild:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
        lbl:SetPoint("TOPLEFT", linksChild, "TOPLEFT", 10, y)
        lbl:SetText("|cffd4af37"..label.."|r")

        local bg = CreateFrame("Frame", nil, linksChild)
        bg:SetPoint("TOPLEFT",  linksChild, "TOPLEFT",  8, y - 20)
        bg:SetPoint("TOPRIGHT", linksChild, "TOPRIGHT", -8, y - 20)
        bg:SetHeight(22)
        bg:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
        bg:SetBackdropColor(0.02, 0.02, 0.06, 1)
        bg:SetBackdropBorderColor(LNK_GOLD_R, LNK_GOLD_G, LNK_GOLD_B, 0.8)
        bg:SetFrameLevel(lnkFL + 3)

        local eb = CreateFrame("EditBox", ebName, bg)
        eb:SetPoint("TOPLEFT",     bg, "TOPLEFT",      4, -2)
        eb:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -4,  2)
        eb:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        eb:SetTextColor(1, 1, 1, 1)
        eb:SetAutoFocus(false)
        eb:EnableMouse(true)
        eb:SetText(url)
        eb:SetFrameLevel(lnkFL + 4)

        local btn = CreateFrame("Button", nil, linksChild, "UIPanelButtonTemplate")
        btn:SetSize(90, 22)
        btn:SetPoint("TOPLEFT", linksChild, "TOPLEFT", 8, y - 48)
        btn:SetText("Select All")
        btn:SetFrameLevel(lnkFL + 4)
        btn:SetScript("OnClick", function() eb:SetFocus(); eb:HighlightText() end)

        local hint = linksChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("LEFT", btn, "RIGHT", 10, 0)
        hint:SetText("|cffd4af37Ctrl+C to copy|r")

        return y - 76  -- bottom y of this entry (label16 + box22 + btn22 + gap16)
    end

    local cy = -14
    cy = LnkEntry("PlayerBot Manager:",                                    "https://github.com/Lichborne-AC/PlayerbotManager",           cy, "LichborneUpdateRepoBox")
    LnkSep(cy - 10); cy = cy - 30
    cy = LnkEntry("mod-playerbots:",            "https://github.com/mod-playerbots/mod-playerbots",           cy, "PBMUpdatePlayerbotsBox")
    LnkSep(cy - 10); cy = cy - 30
    cy = LnkEntry("mod-levelsync:",             "https://github.com/Lichborne-AC/mod-levelsync",              cy, "PBMUpdateLevelSyncBox")
    LnkSep(cy - 10); cy = cy - 30
    cy = LnkEntry("mod-individual-progression:", "https://github.com/ZhengPeiRu21/mod-individual-progression", cy, "PBMUpdateIndivProgBox")
    LnkSep(cy - 10); cy = cy - 30
    cy = LnkEntry("Multibot:",  "https://github.com/Wishmaster117/MultiBot-Chatless",         cy, "PBMUpdateMultibotBox")
    linksChild:SetHeight(math.abs(cy) + 20)

    -- ── Recent Changes tab content ────────────────────────────────────
    local optsChangesBox = CreateFrame("Frame", nil, optionsPanel)
    optsChangesBox:SetPoint("TOPLEFT",     optionsPanel, "TOPLEFT",     6, -66)
    optsChangesBox:SetPoint("BOTTOMRIGHT", optionsPanel, "BOTTOMRIGHT", -6, 48)
    optsChangesBox:SetFrameLevel(optionsPanel:GetFrameLevel() + 1)
    optsChangesBox:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=8,
        insets={left=2, right=2, top=2, bottom=2}
    })
    optsChangesBox:SetBackdropColor(0.03, 0.04, 0.09, 1)
    optsChangesBox:SetBackdropBorderColor(0.60, 0.60, 0.60, 0.8)
    optsChangesBox:Hide()

    local chgFL = optionsPanel:GetFrameLevel() + 3
    local chgScroll = CreateFrame("ScrollFrame", "PBMChangesScrollFrame", optsChangesBox, "UIPanelScrollFrameTemplate")
    chgScroll:SetPoint("TOPLEFT",     optsChangesBox, "TOPLEFT",     4, -4)
    chgScroll:SetPoint("BOTTOMRIGHT", optsChangesBox, "BOTTOMRIGHT", -22, 4)
    chgScroll:SetFrameLevel(chgFL)
    chgScroll:EnableMouseWheel(true)
    chgScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 20)))
    end)

    local chgChild = CreateFrame("Frame", nil, chgScroll)
    chgChild:SetSize(440, 1160)
    chgChild:SetFrameLevel(chgFL + 1)
    chgScroll:SetScrollChild(chgChild)

    local function ChgLine(text, yOff, size, align)
        local fs = chgChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT",  chgChild, "TOPLEFT",  12, yOff)
        fs:SetPoint("TOPRIGHT", chgChild, "TOPRIGHT", -12, yOff)
        if size then fs:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE") end
        fs:SetJustifyH(align or "LEFT")
        fs:SetText(text)
    end
    local function ChgDiv(yOff)
        local t = chgChild:CreateTexture(nil, "ARTWORK")
        t:SetPoint("TOPLEFT",  chgChild, "TOPLEFT",  10, yOff)
        t:SetPoint("TOPRIGHT", chgChild, "TOPRIGHT", -10, yOff)
        t:SetHeight(1)
        t:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        t:SetVertexColor(0.78, 0.61, 0.23, 0.4)
    end

    -- Auto-advancing cursor so new releases can be prepended at the top
    -- without re-numbering every entry below. Held in one table to keep the
    -- enclosing function's local count down.
    local CT = { y = -14, rel = false }
    function CT.title(t)
        ChgLine(t, CT.y, 14, "LEFT"); CT.y = CT.y - 20
        ChgDiv(CT.y); CT.y = CT.y - 16
    end
    function CT.release(t)
        if CT.rel then CT.y = CT.y - 8; ChgDiv(CT.y); CT.y = CT.y - 18 end
        CT.rel = true
        ChgLine(t, CT.y, 13, "CENTER"); CT.y = CT.y - 15
        ChgDiv(CT.y); CT.y = CT.y - 16
    end
    function CT.section(t)
        CT.y = CT.y - 7
        ChgLine(t, CT.y, 10); CT.y = CT.y - 13
        ChgDiv(CT.y); CT.y = CT.y - 13
    end
    function CT.line(t) ChgLine(t, CT.y); CT.y = CT.y - 13 end

    CT.title("|cffFF8C00Recent Changes|r")

    -- ── Release v1.4 ───────────────────────────────────────────────
    CT.release("|cffd4af37Release v1.4|r  |cffFF8C00July 3, 2026|r")
    CT.section("|cffC69B3AReorder Rows|r")
    CT.line("|cff888888-|r  |cffffcc00Drag to reorder|r — grab the |cff888888#|r handle at the left of a")
    CT.line("    row and drag. Works in |cffABD473Class|r, |cffFF8C00Raid|r, and |cffffcc00Group|r tabs")
    CT.line("|cff888888-|r  Manual order is saved and clears the active column sort")
    CT.section("|cffC69B3ALevelSync|r")
    CT.line("|cff888888-|r  New |cffd4af37Export|r button (bottom-right) — copies synced")
    CT.line("    characters |cff888888(name, class, level, IP tier)|r into the tracker")
    CT.section("|cffC69B3AIndividual Progression|r")
    CT.line("|cff888888-|r  New |cffd4af37.ip attune onyxia/blacktemple|r command added")
    CT.line("    to the Commands list")
    CT.section("|cffC69B3AClass Tabs|r")
    CT.line("|cff888888-|r  Gear cells now |cffffcc00highlight on hover|r, matching the")
    CT.line("    |cffffcc00Group|r tab")
    CT.section("|cffC69B3ACC|r")
    CT.line("|cff888888-|r  Added |cffC69B3ACC|r button to character sheet — toggles the |cffff8000cc|r")
    CT.line("    strategy for |cff40C7EBMage|r, |cffFFFFFFPriest|r, |cff8787EDWarlock|r, and |cffFF7D0ADruid|r")
    CT.line("|cff888888-|r  |cff40C7EBMage|r: |cffffcc00Polymorph|r")
    CT.line("|cff888888-|r  |cffFFFFFFPriest|r: |cffffcc00Shackle Undead|r")
    CT.line("|cff888888-|r  |cff8787EDWarlock|r: |cffffcc00Fear|r / |cffffcc00Banish|r")
    CT.line("|cff888888-|r  |cffFF7D0ADruid|r: |cffffcc00Cyclone|r / |cffffcc00Hibernate|r / |cffffcc00Entangling Roots|r")
    CT.section("|cffFF8C00Invite Raid|r")
    CT.line("|cff888888-|r  Removed the 6th-member |cffffcc00pause/re-add|r workaround —")
    CT.line("    party->raid conversion is now handled server-side by")
    CT.line("    mod-playerbots |cff66ccffPR #2502|r")

    -- ── Release v1.3 ───────────────────────────────────────────────
    CT.release("|cffd4af37Release v1.3|r  |cffFF8C00June 5, 2026|r")
    CT.section("|cffABD473Hunter|r")
    CT.line("|cff888888-|r  Removed |cffABD473dps|r button from character sheet (CO)")
    CT.line("|cff888888-|r  Removed |cffABD473dps debuff|r button from character sheet (CO)")
    CT.line("|cff888888-|r  Removed |cffABD473bviper|r aspect from character sheet (CO + NC)")
    CT.section("|cffF58CBAPaladin|r")
    CT.line("|cff888888-|r  |cffF58CBABlessings renamed|r — mod-playerbots |cff66ccffPR #2432|r")
    CT.line("|cff888888-|r  |cffd4af37bstats|r  ->  |cffF58CBAbkings   |cffF58CBA(Blessing of Kings)|r")
    CT.line("|cff888888-|r  |cffd4af37bhealth|r  ->  |cffF58CBAbsanc   |cffF58CBA(Blessing of Sanctuary)|r")
    CT.line("|cff888888-|r  |cffd4af37bmana|r  ->  |cffF58CBAbwisdom   |cffF58CBA(Blessing of Wisdom)|r")
    CT.line("|cff888888-|r  |cffd4af37bdps|r  ->  |cffF58CBAbmight   |cffF58CBA(Blessing of Might)|r")
    CT.section("|cffFFF569Rogue|r")
    CT.line("|cff888888-|r  Added |cffFFF569Melee|r button — DPS column: DPS / Melee / Boost")
    CT.line("|cff888888-|r  Combat section split into |cffFFF569DPS|r and |cffFFF569Stealth|r columns")
    CT.section("|cffC69B3APlayerbots Tab|r")
    CT.line("|cff888888-|r  Reset Instances now uses |cff66ccff.playerbots bot refresh=raid *|r")
    CT.line("|cff888888-|r  Removed GM Reset Instances button")
    CT.section("|cffC69B3ABug Fixes|r")
    CT.line("|cff888888-|r  Fixed: |cffFF7D0ADruid|r offheal strategy showing up red in notes")
    CT.section("|cffC69B3AUI|r")
    CT.line("|cff888888-|r  New |cffffcc00Group|r tab added — shows current group members")
    CT.line("|cff888888-|r  Character sheet: bag colors now correspond to how full the inventory is")
    CT.section("|cffC69B3AFilters|r")
    CT.line("|cff888888-|r  New filter: removes generated notes in the |cffFF8C00Raid|r tab — allows for manual entry")
    CT.line("|cff888888-|r  New filter: removes generated roles in the |cffFF8C00Raid|r/|cffABD473Overview|r tab —")
    CT.line("    allows for manual entry")
    CT.line("|cff888888-|r  New filter: Show/Hide new |cffffcc00Group|r tab")
    CT.line("|cff888888-|r  New filter: Show/Hide |cff66ccffStrategy|r responses in output box")
    CT.line("|cff888888-|r  New filter: Show/Hide |cff66ccff+Add Target/Group Strategies|r buttons")
    CT.line("|cff888888-|r  New filter: Show/Hide Who response (when opening character menus)")
    CT.line("|cff888888-|r  New filter: |cffffcc00Hide Group Members|r — hides chars in your party")
    CT.line("|cff888888-|r  New toggles: name-click char sheet — |cffffcc00Group|r + Class tabs")
    CT.section("|cffC69B3AButtons|r")
    CT.line("|cff888888-|r  Added |cffff8c00\"Does not work for rndbots.\"|r note in Invite Group & Raid buttons")
    CT.section("|cffC69B3ATemplates|r")
    CT.line("|cff888888-|r  |cffC41F3BDK:|r |cffC69B3ADbl Aura Blood PvE|r (43-26-2) added — spec \"double aura blood pve\"")

    -- ── Release v1.2 ───────────────────────────────────────────────
    CT.release("|cffd4af37Release v1.2|r  |cffFF8C00May 30, 2026|r")
    CT.section("|cffC69B3ABug Fixes|r")
    CT.line("|cff888888-|r  Fixed: Invite Raid no longer kicks and reinvites members in partial groups")
    CT.line("|cff888888-|r  Stop Scan now stops |cffffcc00+Add IP Tiers|r mid-run")
    CT.line("|cff888888-|r  Clear All no longer resets Raid tier/raid selection")
    CT.section("|cffC69B3AUI|r")
    CT.line("|cff888888-|r  Show/Hide menu added: toggle tab and button visibility per bot row")
    CT.line("|cff888888-|r  Needs column restored — shares the Prof. column |cff888888(use either)|r")
    CT.line("|cff888888-|r  Raid tab: note color brightened for readability")
    CT.line("|cff888888-|r  Tracker section header renamed: |cffffcc00Admin:|r  ->  |cffffcc00Menu:|r")
    CT.line("|cff888888-|r  Character sheet: name on its own line in class color")
    CT.line("|cff888888-|r  PvP tooltip: moved above button, wording cleaned up")
    CT.line("|cff888888-|r  Several AoE icons updated to Blizzard |cff888888(spell_frost_icestorm)|r")
    CT.line("|cff888888-|r  Reset Instances: tooltips updated")
    CT.section("|cffC69B3AClass Menus|r")
    CT.line("|cff888888-|r  Removed ability rotation lines from all 10 class spec tooltips")
    CT.line("    |cff999999Due to time restraints and constantly evolving Playerbot strategies.|r")
    CT.line("|cff888888-|r  |cff8787EDWarlock:|r removed DPS toggle button, Combat row shrunk to 3 icons")
    CT.line("|cff888888-|r  |cff8787EDWarlock|r & |cff0070DEShaman:|r increased vertical row spacing |cff888888(15 px gap)|r")
    CT.line("|cff888888-|r  |cff0070DEShaman:|r Caster AoE + Melee AoE merged into single |cffffcc00AoE|r button")
    CT.line("|cff888888-|r  |cff0070DEShaman|r Totem section removed — use |cffffcc00Multibot|r for totem functions")
    CT.line("|cff888888-|r  |cffFF7D0ADruid:|r added |cffffcc00Tranquility|r, |cffffcc00Blanketing|r, and |cffffcc00Feral Charge|r strategies")
    CT.section("|cffC69B3AButtons|r")
    CT.line("|cff888888-|r  Buttons disabled while |cffffcc00+Add IP Tiers|r is running")

    chgChild:SetHeight(-CT.y + 30)

    -- ── Credits tab content ───────────────────────────────────────────
    local optsCreditsBox = CreateFrame("Frame", nil, optionsPanel)
    optsCreditsBox:SetPoint("TOPLEFT",     optionsPanel, "TOPLEFT",     6, -66)
    optsCreditsBox:SetPoint("BOTTOMRIGHT", optionsPanel, "BOTTOMRIGHT", -6, 48)
    optsCreditsBox:SetFrameLevel(optionsPanel:GetFrameLevel() + 1)
    optsCreditsBox:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=8,
        insets={left=3, right=3, top=3, bottom=3}
    })
    optsCreditsBox:SetBackdropColor(0.03, 0.04, 0.09, 1)
    optsCreditsBox:SetBackdropBorderColor(0.60, 0.60, 0.60, 0.8)
    optsCreditsBox:Hide()

    local function CreditsLine(text, yOff, size, align)
        local fs = optsCreditsBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT",  optsCreditsBox, "TOPLEFT",  12, yOff)
        fs:SetPoint("TOPRIGHT", optsCreditsBox, "TOPRIGHT", -12, yOff)
        fs:SetJustifyH(align or "LEFT")
        if size then fs:SetFont("Fonts\\FRIZQT__.TTF", size) end
        fs:SetText(text)
        return fs
    end
    local function CreditsDivider(yOff)
        local t = optsCreditsBox:CreateTexture(nil, "ARTWORK")
        t:SetPoint("TOPLEFT",  optsCreditsBox, "TOPLEFT",  10, yOff)
        t:SetPoint("TOPRIGHT", optsCreditsBox, "TOPRIGHT", -10, yOff)
        t:SetHeight(1)
        t:SetTexture(0.78, 0.61, 0.23, 0.4)
    end

    CreditsLine("|cffC69B3ACredits|r", -14, 14)
    CreditsDivider(-34)
    CreditsLine("|cffd4af37Special thanks to:|r", -60, nil, "CENTER")
    CreditsLine("|cffffffffDohtt|r",                                 -74, nil, "CENTER")
    CreditsLine("|cffffffffScarecr0w12 |cffaaaaaa- TheCGN.net|r",   -86, nil, "CENTER")
    CreditsLine("|cffffffffDreathean|r",                             -98, nil, "CENTER")
    CreditsLine("|cffffffffRevision|r",                             -110, nil, "CENTER")
    CreditsLine("|cffffffffCrow|r",                                 -122, nil, "CENTER")
    CreditsLine("|cffffffffLatChee|r",                              -134, nil, "CENTER")
    CreditsLine("|cffffffffInvaderCanuck|r",                        -146, nil, "CENTER")
    CreditsLine("|cffffffffScoobyPwnsOnU|r",                        -158, nil, "CENTER")
    CreditsLine("|cffffffffGrimfeather|r",                          -170, nil, "CENTER")
    CreditsLine("|cffffffffKeleborn|r",                             -182, nil, "CENTER")
    CreditsLine("|cffffffffGromleq|r",                              -194, nil, "CENTER")
    CreditsLine("|cffffffffPortions of PBM's character menu code were derived from Wishmaster117's Multibot.|r", -238, nil, "CENTER")
    CreditsLine("|cffffffffThank you for the work.|r", -252, nil, "CENTER")
    CreditsDivider(-270)
    CreditsLine("|cffd4af37Questions & Support:|r  lichborne.wow@proton.me  —  |cffd4af37Discord:|r jared2219", -292, nil, "CENTER")

    -- ── Store bottom-button refs for Show/Hide menu ──────────────────
    PBM.State.trackerBtns = {
        addTarget      = _G["LichborneAddTargetBtn"],
        addGroup       = _G["LichborneAddGroupBtn"],
        addTargetGS    = _G["LichborneUpdateGSBtn"],
        addGroupGS     = _G["LichborneUpdateGroupGSBtn"],
        addTargetSpec  = _G["LichborneUpdateTargetSpecBtn"],
        addGroupSpec   = _G["LichborneUpdateGroupSpecBtn"],
        addTargetStrat = _G["LichborneTargetStrategiesBtn"],
        addGroupStrat  = _G["LichborneGroupStrategiesBtn"],
        stop           = _G["LichborneStopInspectBtn"],
        maintBtn       = _G["LichborneMaintBtn"],
    }

    -- Repositions/resizes bottom-column buttons when strategy row is shown or hidden
    function PBM.RefreshStrategyBtnLayout()
        local b = PBM.State.trackerBtns
        if not b then return end
        local shown = not (PBMConfig and PBMConfig.hiddenButtons and PBMConfig.hiddenButtons.strategies)
        if b.addTargetStrat then if shown then b.addTargetStrat:Show() else b.addTargetStrat:Hide() end end
        if b.addGroupStrat  then if shown then b.addGroupStrat:Show()  else b.addGroupStrat:Hide()  end end
        local par = f  -- main tracker frame
        if shown then
            -- Standard layout: 5 rows of 29px at y = 8, 42, 76, 110, 144
            if b.stop          then b.stop:ClearAllPoints();          b.stop:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",15, 8);   b.stop:SetSize(155,29) end
            if b.maintBtn      then b.maintBtn:ClearAllPoints();      b.maintBtn:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",175,8); b.maintBtn:SetSize(155,29) end
            if b.addTargetStrat then b.addTargetStrat:ClearAllPoints(); b.addTargetStrat:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",15,42);  b.addTargetStrat:SetSize(155,29) end
            if b.addGroupStrat  then b.addGroupStrat:ClearAllPoints();  b.addGroupStrat:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",175,42); b.addGroupStrat:SetSize(155,29) end
            if b.addTargetSpec then b.addTargetSpec:ClearAllPoints();  b.addTargetSpec:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",15,76);  b.addTargetSpec:SetSize(155,29) end
            if b.addGroupSpec  then b.addGroupSpec:ClearAllPoints();   b.addGroupSpec:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",175,76); b.addGroupSpec:SetSize(155,29) end
            if b.addTargetGS   then b.addTargetGS:ClearAllPoints();   b.addTargetGS:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",15,110); b.addTargetGS:SetSize(155,29) end
            if b.addGroupGS    then b.addGroupGS:ClearAllPoints();    b.addGroupGS:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",175,110); b.addGroupGS:SetSize(155,29) end
            if b.addTarget     then b.addTarget:ClearAllPoints();     b.addTarget:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",15,144);  b.addTarget:SetSize(155,29) end
            if b.addGroup      then b.addGroup:ClearAllPoints();      b.addGroup:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",175,144); b.addGroup:SetSize(155,29) end
        else
            -- Expanded layout: 4 rows of 37px at y = 8, 50, 92, 134
            if b.stop          then b.stop:ClearAllPoints();         b.stop:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",15, 8);   b.stop:SetSize(155,37) end
            if b.maintBtn      then b.maintBtn:ClearAllPoints();     b.maintBtn:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",175,8); b.maintBtn:SetSize(155,37) end
            if b.addTargetSpec then b.addTargetSpec:ClearAllPoints(); b.addTargetSpec:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",15, 50);  b.addTargetSpec:SetSize(155,37) end
            if b.addGroupSpec  then b.addGroupSpec:ClearAllPoints();  b.addGroupSpec:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",175,50); b.addGroupSpec:SetSize(155,37) end
            if b.addTargetGS   then b.addTargetGS:ClearAllPoints();  b.addTargetGS:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",15, 92);  b.addTargetGS:SetSize(155,37) end
            if b.addGroupGS    then b.addGroupGS:ClearAllPoints();   b.addGroupGS:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",175,92); b.addGroupGS:SetSize(155,37) end
            if b.addTarget     then b.addTarget:ClearAllPoints();    b.addTarget:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",15, 134); b.addTarget:SetSize(155,37) end
            if b.addGroup      then b.addGroup:ClearAllPoints();     b.addGroup:SetPoint("BOTTOMLEFT",par,"BOTTOMLEFT",175,134); b.addGroup:SetSize(155,37) end
        end
    end

    -- ── Options tab content (Section Visibility) ──────────────────────
    local optsVisBox = CreateFrame("Frame", nil, optionsPanel)
    optsVisBox:SetPoint("TOPLEFT",     optionsPanel, "TOPLEFT",    6, -66)
    optsVisBox:SetPoint("BOTTOMRIGHT", optionsPanel, "BOTTOMRIGHT", -6, 48)
    optsVisBox:SetFrameLevel(optionsPanel:GetFrameLevel() + 1)
    optsVisBox:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=8,
        insets={left=3, right=3, top=3, bottom=3}
    })
    optsVisBox:SetBackdropColor(0.03, 0.04, 0.09, 1)
    optsVisBox:SetBackdropBorderColor(0.60, 0.60, 0.60, 0.8)
    optsVisBox:Hide()

    do
        -- ── Scroll frame wrapper so the vis content is mousewheel-scrollable ──
        local visScrollFL = optionsPanel:GetFrameLevel() + 3
        local visSF = CreateFrame("ScrollFrame", nil, optsVisBox)
        visSF:SetPoint("TOPLEFT",     optsVisBox, "TOPLEFT",     2,  -2)
        visSF:SetPoint("BOTTOMRIGHT", optsVisBox, "BOTTOMRIGHT", -2,  2)
        visSF:SetFrameLevel(visScrollFL)
        visSF:EnableMouseWheel(true)
        visSF:SetScript("OnMouseWheel", function(self, delta)
            local cur = self:GetVerticalScroll()
            local max = self:GetVerticalScrollRange()
            self:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 20)))
        end)
        local visSC = CreateFrame("Frame", nil, visSF)
        visSC:SetSize(620, 640)   -- tall content frame; scroll range auto-calculated
        visSC:SetFrameLevel(visScrollFL + 1)
        visSF:SetScrollChild(visSC)
        -- Shadow optsVisBox so every widget below is parented to the scroll child
        local optsVisBox = visSC

        local VIS_FL   = visScrollFL + 2
        local VIS_FONT = "Fonts\\FRIZQT__.TTF"
        local VIS_GR, VIS_GG, VIS_GB = 0.78, 0.61, 0.23
        local VIS_MX   = 14
        local VIS_BTN_H = 30
        local COL2_X   = VIS_MX + 190 + 20

        local visHdr = optsVisBox:CreateFontString(nil, "OVERLAY")
        visHdr:SetFont(VIS_FONT, 11, "OUTLINE")
        visHdr:SetPoint("TOPLEFT", optsVisBox, "TOPLEFT", VIS_MX, -14)
        visHdr:SetTextColor(VIS_GR, VIS_GG, VIS_GB)
        visHdr:SetText("Show/Hide")

        local visHdrDiv = optsVisBox:CreateTexture(nil, "ARTWORK")
        visHdrDiv:SetPoint("TOPLEFT",  optsVisBox, "TOPLEFT",  VIS_MX, -28)
        visHdrDiv:SetPoint("TOPRIGHT", optsVisBox, "TOPRIGHT", -VIS_MX, -28)
        visHdrDiv:SetHeight(1)
        visHdrDiv:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        visHdrDiv:SetVertexColor(VIS_GR, VIS_GG, VIS_GB, 0.5)

        local VIS_SECTIONS = {
            {id = "Playerbots",            label = "Playerbots Tab"},
            {id = "IndividualProgression", label = "Ind. Prog. Tab"},
            {id = "LevelSync",             label = "LevelSync Tab"},
            {id = "Notes",                 label = "Notes Tab"},
            {id = "Group",                 label = "Group Tab"},
        }

        PBM.State.visToggleBtns = {}

        local function MakeVisToggle(yTop, sectionId, sectionLabel, xOff)
            local btn = CreateFrame("Button", nil, optsVisBox)
            btn:SetPoint("TOPLEFT", optsVisBox, "TOPLEFT", xOff or VIS_MX, yTop)
            btn:SetSize(190, VIS_BTN_H)
            btn:SetFrameLevel(VIS_FL)
            btn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=3,right=3,top=3,bottom=3}})
            btn:SetBackdropBorderColor(VIS_GR, VIS_GG, VIS_GB, 0.85)
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

            local nameLbl = btn:CreateFontString(nil, "OVERLAY")
            nameLbl:SetFont(VIS_FONT, 10, "OUTLINE")
            nameLbl:SetPoint("LEFT", btn, "LEFT", 10, 0)
            nameLbl:SetText("|cffd4af37" .. sectionLabel .. "|r")

            local stateLbl = btn:CreateFontString(nil, "OVERLAY")
            stateLbl:SetFont(VIS_FONT, 10, "OUTLINE")
            stateLbl:SetPoint("RIGHT", btn, "RIGHT", -10, 0)

            function btn:Refresh()
                if not PBMConfig then PBMConfig = {} end
                local isHidden = PBMConfig.hiddenTabs and PBMConfig.hiddenTabs[sectionId]
                if isHidden then
                    btn:SetBackdropColor(0.18, 0.04, 0.04, 1)
                    stateLbl:SetText("|cffff6666Hidden|r")
                else
                    btn:SetBackdropColor(0.04, 0.14, 0.06, 1)
                    stateLbl:SetText("|cff55dd77Visible|r")
                end
            end
            btn:Refresh()

            btn:SetScript("OnClick", function()
                if not PBMConfig then PBMConfig = {} end
                if not PBMConfig.hiddenTabs then PBMConfig.hiddenTabs = {} end
                local nowHidden = not PBMConfig.hiddenTabs[sectionId]
                PBMConfig.hiddenTabs[sectionId] = nowHidden or nil
                PBM.RefreshBottomTabPositions()
                if sectionId == "IPTiers" then RefreshIPColumn() end
                if sectionId == "Group" then
                    local tb = PBM.State.tabButtons and PBM.State.tabButtons["Group"]
                    if tb then
                        if nowHidden then
                            tb:Hide()
                            if PBM.State.activeTab == "Group" then
                                PBM.State.activeTab = "Overview"
                            end
                        else
                            tb:Show()
                        end
                    end
                end
                for _, b in ipairs(PBM.State.visToggleBtns) do b:Refresh() end
                PBM.UpdateTabs()
                PBM.RefreshRows()
            end)

            return btn
        end

        local yPos = -34
        for _, sec in ipairs(VIS_SECTIONS) do
            local btn = MakeVisToggle(yPos, sec.id, sec.label)
            PBM.State.visToggleBtns[#PBM.State.visToggleBtns + 1] = btn
            yPos = yPos - VIS_BTN_H - 6
        end

        -- ── Second column (no header; shares the Show/Hide divider line) ──
        -- Order: Add IP Tiers, Strategy Buttons, Strategy Whispers, Who Commands, Role Filter, Notes Filter

        -- (1) Add IP Tiers — tab/button visibility toggle, reuses MakeVisToggle
        local ipTiersToggle = MakeVisToggle(-34, "IPTiers", "+Add IP Tiers (button)", COL2_X)
        PBM.State.visToggleBtns[#PBM.State.visToggleBtns + 1] = ipTiersToggle

        -- (2) Strategy Buttons show/hide toggle
        local stratVisBtn = CreateFrame("Button", nil, optsVisBox)
        stratVisBtn:SetPoint("TOPLEFT", optsVisBox, "TOPLEFT", COL2_X, -34 - (VIS_BTN_H + 6))
        stratVisBtn:SetSize(190, VIS_BTN_H); stratVisBtn:SetFrameLevel(VIS_FL)
        stratVisBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=3,right=3,top=3,bottom=3}})
        stratVisBtn:SetBackdropBorderColor(VIS_GR, VIS_GG, VIS_GB, 0.85)
        stratVisBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        local svNLbl = stratVisBtn:CreateFontString(nil,"OVERLAY"); svNLbl:SetFont(VIS_FONT,10,"OUTLINE")
        svNLbl:SetPoint("LEFT",stratVisBtn,"LEFT",10,0); svNLbl:SetText("|cffd4af37+Add Strategy Buttons|r")
        local svSLbl = stratVisBtn:CreateFontString(nil,"OVERLAY"); svSLbl:SetFont(VIS_FONT,10,"OUTLINE")
        svSLbl:SetPoint("RIGHT",stratVisBtn,"RIGHT",-10,0)
        function stratVisBtn:Refresh()
            local hidden = PBMConfig and PBMConfig.hiddenButtons and PBMConfig.hiddenButtons.strategies
            if hidden then stratVisBtn:SetBackdropColor(0.18,0.04,0.04,1); svSLbl:SetText("|cffff6666Hidden|r")
            else            stratVisBtn:SetBackdropColor(0.04,0.14,0.06,1); svSLbl:SetText("|cff55dd77Visible|r") end
        end
        stratVisBtn:Refresh()
        stratVisBtn:SetScript("OnClick", function()
            if not PBMConfig.hiddenButtons then PBMConfig.hiddenButtons = {} end
            PBMConfig.hiddenButtons.strategies = not PBMConfig.hiddenButtons.strategies or nil
            stratVisBtn:Refresh()
            PBM.RefreshStrategyBtnLayout()
            for _, b in ipairs(PBM.State.visToggleBtns) do b:Refresh() end
        end)
        stratVisBtn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(stratVisBtn, "ANCHOR_TOP")
            GameTooltip:AddLine("+Add Strategy Buttons", 0.78, 0.61, 0.23)
            GameTooltip:AddLine("Hides +Add Target/Group Strategies buttons", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("and expands the remaining buttons to fill the gap.", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        stratVisBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        PBM.State.visToggleBtns[#PBM.State.visToggleBtns+1] = stratVisBtn

        -- Apply strategy-button layout on load
        PBM.RefreshStrategyBtnLayout()

        -- (3) Strategy Whispers
        local stratBtn = CreateFrame("Button", nil, optsVisBox)
        stratBtn:SetPoint("TOPLEFT", optsVisBox, "TOPLEFT", COL2_X, -34 - (VIS_BTN_H + 6) * 2)
        stratBtn:SetSize(190, VIS_BTN_H)
        stratBtn:SetFrameLevel(VIS_FL)
        stratBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=3,right=3,top=3,bottom=3}})
        stratBtn:SetBackdropBorderColor(VIS_GR, VIS_GG, VIS_GB, 0.85)
        stratBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

        local stratNameLbl = stratBtn:CreateFontString(nil, "OVERLAY")
        stratNameLbl:SetFont(VIS_FONT, 10, "OUTLINE")
        stratNameLbl:SetPoint("LEFT", stratBtn, "LEFT", 10, 0)
        stratNameLbl:SetText("|cffd4af37Strategy Whispers|r")

        local stratStateLbl = stratBtn:CreateFontString(nil, "OVERLAY")
        stratStateLbl:SetFont(VIS_FONT, 10, "OUTLINE")
        stratStateLbl:SetPoint("RIGHT", stratBtn, "RIGHT", -10, 0)

        function stratBtn:Refresh()
            if PBMConfig and PBMConfig.hideStrategyOutput then
                stratBtn:SetBackdropColor(0.18, 0.04, 0.04, 1)
                stratStateLbl:SetText("|cffff6666Hidden|r")
            else
                stratBtn:SetBackdropColor(0.04, 0.14, 0.06, 1)
                stratStateLbl:SetText("|cff55dd77Visible|r")
            end
        end
        stratBtn:Refresh()
        PBM.State.visToggleBtns[#PBM.State.visToggleBtns + 1] = stratBtn

        stratBtn:SetScript("OnClick", function()
            if not PBMConfig then PBMConfig = {} end
            PBMConfig.hideStrategyOutput = (not PBMConfig.hideStrategyOutput) or nil
            stratBtn:Refresh()
        end)
        stratBtn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(stratBtn, "ANCHOR_TOP")
            GameTooltip:AddLine("Strategy Whispers", 0.78, 0.61, 0.23)
            GameTooltip:AddLine("Filters bot strategy replies from the", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("PBM output box when you open a bot menu.", 0.8, 0.8, 0.8)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Filtered messages:", 0.6, 0.6, 0.6)
            GameTooltip:AddLine("|cffd4af37[Bot] whispers: Strategies: tank, heal ...|r", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        stratBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- (4) Who Commands
        local whoBtn = CreateFrame("Button", nil, optsVisBox)
        whoBtn:SetPoint("TOPLEFT", optsVisBox, "TOPLEFT", COL2_X, -34 - (VIS_BTN_H + 6) * 3)
        whoBtn:SetSize(190, VIS_BTN_H)
        whoBtn:SetFrameLevel(VIS_FL)
        whoBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=3,right=3,top=3,bottom=3}})
        whoBtn:SetBackdropBorderColor(VIS_GR, VIS_GG, VIS_GB, 0.85)
        whoBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

        local whoNameLbl = whoBtn:CreateFontString(nil, "OVERLAY")
        whoNameLbl:SetFont(VIS_FONT, 10, "OUTLINE")
        whoNameLbl:SetPoint("LEFT", whoBtn, "LEFT", 10, 0)
        whoNameLbl:SetText("|cffd4af37Who Commands|r")

        local whoStateLbl = whoBtn:CreateFontString(nil, "OVERLAY")
        whoStateLbl:SetFont(VIS_FONT, 10, "OUTLINE")
        whoStateLbl:SetPoint("RIGHT", whoBtn, "RIGHT", -10, 0)

        function whoBtn:Refresh()
            if PBMConfig and PBMConfig.hideWhoCommands then
                whoBtn:SetBackdropColor(0.18, 0.04, 0.04, 1)
                whoStateLbl:SetText("|cffff6666Hidden|r")
            else
                whoBtn:SetBackdropColor(0.04, 0.14, 0.06, 1)
                whoStateLbl:SetText("|cff55dd77Visible|r")
            end
        end
        whoBtn:Refresh()
        PBM.State.visToggleBtns[#PBM.State.visToggleBtns + 1] = whoBtn

        whoBtn:SetScript("OnClick", function()
            if not PBMConfig then PBMConfig = {} end
            PBMConfig.hideWhoCommands = (not PBMConfig.hideWhoCommands) or nil
            whoBtn:Refresh()
        end)
        whoBtn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(whoBtn, "ANCHOR_TOP")
            GameTooltip:AddLine("Who Commands", 0.78, 0.61, 0.23)
            GameTooltip:AddLine("Filters the bot query commands and their", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("responses from your chat window.", 0.8, 0.8, 0.8)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Filtered outgoing:", 0.6, 0.6, 0.6)
            GameTooltip:AddLine("|cffd4af37To [Bot]: co ?  /  nc ?  /  stats  /  who  /  ss ?|r", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("Filtered incoming:", 0.6, 0.6, 0.6)
            GameTooltip:AddLine("|cffd4af37[Bot] whispers: stats, bag, durability line|r", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("|cffd4af37[Bot] whispers: race/class/level/GS line|r", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("|cffd4af37[Bot] whispers: Ignored spell list ...|r", 0.8, 0.8, 0.8)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("|cffaaaaaa\"who\" is sent automatically when opening", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cffaaaaaaa character's strategy menu.|r", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        whoBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- (5) Talent Whispers — hides the Templates-menu talents exchange
        local talBtn = CreateFrame("Button", nil, optsVisBox)
        talBtn:SetPoint("TOPLEFT", optsVisBox, "TOPLEFT", COL2_X, -34 - (VIS_BTN_H + 6) * 4)
        talBtn:SetSize(190, VIS_BTN_H)
        talBtn:SetFrameLevel(VIS_FL)
        talBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=3,right=3,top=3,bottom=3}})
        talBtn:SetBackdropBorderColor(VIS_GR, VIS_GG, VIS_GB, 0.85)
        talBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        local talNameLbl = talBtn:CreateFontString(nil, "OVERLAY")
        talNameLbl:SetFont(VIS_FONT, 10, "OUTLINE")
        talNameLbl:SetPoint("LEFT", talBtn, "LEFT", 10, 0)
        talNameLbl:SetText("|cffd4af37Talent Whispers|r")
        local talStateLbl = talBtn:CreateFontString(nil, "OVERLAY")
        talStateLbl:SetFont(VIS_FONT, 10, "OUTLINE")
        talStateLbl:SetPoint("RIGHT", talBtn, "RIGHT", -10, 0)
        function talBtn:Refresh()
            if PBMConfig and PBMConfig.hideTalentsOutput then
                talBtn:SetBackdropColor(0.18, 0.04, 0.04, 1); talStateLbl:SetText("|cffff6666Hidden|r")
            else
                talBtn:SetBackdropColor(0.04, 0.14, 0.06, 1); talStateLbl:SetText("|cff55dd77Visible|r")
            end
        end
        talBtn:Refresh()
        PBM.State.visToggleBtns[#PBM.State.visToggleBtns + 1] = talBtn
        talBtn:SetScript("OnClick", function()
            if not PBMConfig then PBMConfig = {} end
            PBMConfig.hideTalentsOutput = (not PBMConfig.hideTalentsOutput) or nil
            talBtn:Refresh()
        end)
        talBtn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(talBtn, "ANCHOR_TOP")
            GameTooltip:AddLine("Talent Whispers", 0.78, 0.61, 0.23)
            GameTooltip:AddLine("Filters the talents exchange triggered by the", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("Templates menu (same for all 10 classes).", 0.8, 0.8, 0.8)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Filtered outgoing:", 0.6, 0.6, 0.6)
            GameTooltip:AddLine("|cffd4af37To [Bot]: talents  /  talents spec list ...|r", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("Filtered incoming:", 0.6, 0.6, 0.6)
            GameTooltip:AddLine("|cffd4af37[Bot] whispers: My current talent spec is ...|r", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("|cffd4af37[Bot] whispers: numbered spec list, Total N specs|r", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        talBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- ── Col2 continued: Role Filter (6th) / Notes Filter (7th) ──
        -- Col2 slots from -34, step (VIS_BTN_H+6): 1=IPTiers 2=StratBtns 3=StratWhisper 4=Who 5=Talents 6=Role 7=Notes
        local col2Y = -34 - (VIS_BTN_H + 6) * 5  -- 6th slot = Role Filter

        local function MakeMenuFilterBtn(yTop, label, getState, onToggle, ttLines, xOff)
            local btn = CreateFrame("Button", nil, optsVisBox)
            btn:SetPoint("TOPLEFT", optsVisBox, "TOPLEFT", xOff or COL2_X, yTop)
            btn:SetSize(190, VIS_BTN_H); btn:SetFrameLevel(VIS_FL)
            btn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=3,right=3,top=3,bottom=3}})
            btn:SetBackdropBorderColor(VIS_GR, VIS_GG, VIS_GB, 0.85)
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
            local nLbl = btn:CreateFontString(nil,"OVERLAY"); nLbl:SetFont(VIS_FONT,10,"OUTLINE")
            nLbl:SetPoint("LEFT",btn,"LEFT",10,0); nLbl:SetText("|cffd4af37"..label.."|r")
            local sLbl = btn:CreateFontString(nil,"OVERLAY"); sLbl:SetFont(VIS_FONT,10,"OUTLINE")
            sLbl:SetPoint("RIGHT",btn,"RIGHT",-10,0)
            function btn:Refresh()
                if getState() then
                    btn:SetBackdropColor(0.04,0.14,0.06,1); sLbl:SetText("|cff55dd77On|r")
                else
                    btn:SetBackdropColor(0.18,0.04,0.04,1); sLbl:SetText("|cffff6666Off|r")
                end
            end
            btn:Refresh()
            PBM.State.visToggleBtns[#PBM.State.visToggleBtns+1] = btn
            btn:SetScript("OnClick", function() onToggle(); btn:Refresh() end)
            if ttLines then
                btn:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(btn,"ANCHOR_TOP")
                    for _,l in ipairs(ttLines) do GameTooltip:AddLine(l[1],l[2] or 1,l[3] or 1,l[4] or 1) end
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
            return btn
        end

        MakeMenuFilterBtn(col2Y, "Role Filter",
            function() return PBM.State.LBFilter and PBM.State.LBFilter.raidRoleFilter end,
            function()
                PBM.State.LBFilter.raidRoleFilter = not PBM.State.LBFilter.raidRoleFilter
                LichborneTrackerDB.raidRoleFilter = PBM.State.LBFilter.raidRoleFilter
                local updFn = _G["UpdateRaidRoleFilterBtn"]  -- updates MISC bar icon if visible
                if type(updFn) == "function" then pcall(updFn) end
                if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
                if PBM.State.LichborneOverviewFrame then PBM.RefreshOverviewRows() end
                if PBM.State.groupViewFrame then PBM.RefreshGroupViewRows() end
            end,
            {{"Role Filter",0.78,0.61,0.23},{"Hides strategy roles in the Raid tab.",0.7,0.7,0.7},{"Allows manual role assignment per slot.",0.7,0.7,0.7}})

        MakeMenuFilterBtn(col2Y - (VIS_BTN_H + 6), "Notes Filter",
            function() return PBM.State.LBFilter and PBM.State.LBFilter.raidNotesFilter end,
            function()
                PBM.State.LBFilter.raidNotesFilter = not PBM.State.LBFilter.raidNotesFilter
                LichborneTrackerDB.raidNotesFilter = PBM.State.LBFilter.raidNotesFilter
                if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
            end,
            {{"Notes Filter",0.78,0.61,0.23},{"Hides strategy notes in the Raid tab.",0.7,0.7,0.7},{"Enables manual note entry per slot.",0.7,0.7,0.7}})

        -- Col1 slots 6 & 7: Char Sheet toggles (under Group Tab)
        -- Col1 step = VIS_BTN_H+6 = 36; 5 tabs placed, so next y = -34 - 36*5 = -214
        MakeMenuFilterBtn(-214, "Group Tab: Char Sheet",
            function() return PBM.State.LBFilter and PBM.State.LBFilter.gvCharSheet ~= false end,
            function()
                PBM.State.LBFilter.gvCharSheet = not (PBM.State.LBFilter.gvCharSheet ~= false)
                LichborneTrackerDB.gvCharSheet = PBM.State.LBFilter.gvCharSheet
            end,
            {{"Group Tab: Char Sheet",0.78,0.61,0.23},{"Enable or disable clicking a name in the",0.7,0.7,0.7},{"Group tab to open their character sheet.",0.7,0.7,0.7}},
            VIS_MX)

        MakeMenuFilterBtn(-250, "Class Tabs: Char Sheet",
            function() return PBM.State.LBFilter and PBM.State.LBFilter.classCharSheet ~= false end,
            function()
                PBM.State.LBFilter.classCharSheet = not (PBM.State.LBFilter.classCharSheet ~= false)
                LichborneTrackerDB.classCharSheet = PBM.State.LBFilter.classCharSheet
            end,
            {{"Class Tabs: Char Sheet",0.78,0.61,0.23},{"Enable or disable clicking a name in any",0.7,0.7,0.7},{"class tab to open their character sheet.",0.7,0.7,0.7}},
            VIS_MX)
    end

    -- ── Tab switching ─────────────────────────────────────────────────
    local function SetOptsTab(which)
        optsOptionsBox:Hide(); optsContentBox:Hide(); optsCreditsBox:Hide(); optsVisBox:Hide(); optsChangesBox:Hide()
        optsTabData:SetBackdropColor(0.12, 0.16, 0.30, 1)
        optsTabGeneral:SetBackdropColor(0.12, 0.16, 0.30, 1)
        optsTabCredits:SetBackdropColor(0.12, 0.16, 0.30, 1)
        optsTabOptions:SetBackdropColor(0.12, 0.16, 0.30, 1)
        optsTabChanges:SetBackdropColor(0.12, 0.16, 0.30, 1)
        if which == "changes" then
            optsChangesBox:Show()
            optsTabChanges:SetBackdropColor(0.20, 0.26, 0.48, 1)
        elseif which == "data" then
            optsOptionsBox:Show()
            optsTabData:SetBackdropColor(0.20, 0.26, 0.48, 1)
        elseif which == "update" then
            optsContentBox:Show()
            optsTabGeneral:SetBackdropColor(0.20, 0.26, 0.48, 1)
        elseif which == "options" then
            optsVisBox:Show()
            if PBM.State.visToggleBtns then
                for _, b in ipairs(PBM.State.visToggleBtns) do b:Refresh() end
            end
            optsTabOptions:SetBackdropColor(0.20, 0.26, 0.48, 1)
        else
            optsCreditsBox:Show()
            optsTabCredits:SetBackdropColor(0.20, 0.26, 0.48, 1)
        end
    end
    optsTabChanges:SetScript("OnClick", function() SetOptsTab("changes") end)
    optsTabData:SetScript("OnClick",    function() SetOptsTab("data")    end)
    optsTabGeneral:SetScript("OnClick", function() SetOptsTab("update")  end)
    optsTabCredits:SetScript("OnClick", function() SetOptsTab("credits") end)
    optsTabOptions:SetScript("OnClick", function() SetOptsTab("options") end)
    SetOptsTab("changes")

    -- Bottom divider
    local optsBottomDiv = optionsPanel:CreateTexture(nil, "OVERLAY")
    optsBottomDiv:SetPoint("BOTTOMLEFT",  optionsPanel, "BOTTOMLEFT",  6, 46)
    optsBottomDiv:SetPoint("BOTTOMRIGHT", optionsPanel, "BOTTOMRIGHT", -6, 46)
    optsBottomDiv:SetHeight(1)
    optsBottomDiv:SetTexture(0.78, 0.61, 0.23, 0.5)

    -- Close button
    local optsCloseBtn = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
    optsCloseBtn:SetPoint("BOTTOMRIGHT", optionsPanel, "BOTTOMRIGHT", -8, 12)
    optsCloseBtn:SetSize(80, 24)
    optsCloseBtn:SetText("Close")
    optsCloseBtn:SetFrameLevel(optionsPanel:GetFrameLevel() + 3)
    optsCloseBtn:SetScript("OnClick", function() optionsPanel:Hide() end)

    -- Settings button (rightmost of the button row)
    local settingsBtn = CreateFrame("Button", "LichborneSettingsBtn", f)
    settingsBtn:SetPoint("BOTTOMRIGHT", outputBox, "TOPRIGHT", 0, 7)
    settingsBtn:SetSize(24, 24)
    settingsBtn:SetFrameLevel(fl + 12)
    -- no backdrop
    settingsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local settingsIcon = settingsBtn:CreateTexture(nil, "OVERLAY")
    settingsIcon:SetPoint("CENTER", settingsBtn, "CENTER", 0, 0)
    settingsIcon:SetSize(22, 22)
    settingsIcon:SetTexture("Interface\\Icons\\Trade_Engineering")
    settingsBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(settingsBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("Menu", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Open the Playerbot Manager menu.", 1, 1, 1)
        GameTooltip:Show()
    end)
    settingsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    settingsBtn:SetScript("OnClick", function()
        if optionsPanel:IsShown() then
            optionsPanel:Hide()
        else
            if _G["LichborneExportPopup"] then _G["LichborneExportPopup"]:Hide() end
            if _G["LichborneImportPopup"] then _G["LichborneImportPopup"]:Hide() end
            optionsPanel:Show()
        end
    end)

    -- Forward-declare update functions so each OnClick can reference the others
    local UpdateGroupFilterBtn, UpdateHideRaidBtn, UpdateHideGroupBtn

    -- Group filter button: pvp icon swaps red/green with filter state
    local groupFilterBtn = CreateFrame("Button", "LichborneGroupFilterBtn", f)
    groupFilterBtn:SetSize(24, 24)
    groupFilterBtn:SetFrameLevel(fl + 12)
    groupFilterBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,insets={left=0,right=0,top=0,bottom=0}})
    groupFilterBtn:SetBackdropColor(0.05, 0.08, 0.18, 1)
    groupFilterBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local gfIcon = groupFilterBtn:CreateTexture(nil, "OVERLAY")
    gfIcon:SetPoint("CENTER", groupFilterBtn, "CENTER", 0, 0)
    gfIcon:SetSize(22, 22)
    gfIcon:SetTexture("Interface\\Icons\\Achievement_pvp_h_02")  -- red = off
    UpdateGroupFilterBtn = function()
        if PBM.State.LBFilter.groupActive then
            gfIcon:SetTexture("Interface\\Icons\\Achievement_pvp_g_02")
        else
            gfIcon:SetTexture("Interface\\Icons\\Achievement_pvp_h_02")
        end
    end
    groupFilterBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(groupFilterBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("Party Filter", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Hides characters |cffFF8C00not|r in your group/raid.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    groupFilterBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    groupFilterBtn:SetScript("OnClick", function()
        PBM.State.LBFilter.groupActive = not PBM.State.LBFilter.groupActive
        LichborneTrackerDB.groupActive = PBM.State.LBFilter.groupActive
        if PBM.State.LBFilter.groupActive then
            PBM.State.LBFilter.hideRaid = false
            LichborneTrackerDB.hideRaid = false
            UpdateHideRaidBtn()
            PBM.State.LBFilter.hideGroupMembers = false
            LichborneTrackerDB.hideGroupMembers = false
            UpdateHideGroupBtn()
        end
        UpdateGroupFilterBtn()
        PBM.RefreshRows()
        if PBM.State.LichborneOverviewFrame then PBM.RefreshOverviewRows() end
    end)
    UpdateGroupFilterBtn()

    -- ── Show Only Raid Members filter button ─────────────────────────
    local hideRaidBtn = CreateFrame("Button", "LichborneHideRaidBtn", f)
    hideRaidBtn:SetSize(24, 24)
    hideRaidBtn:SetFrameLevel(fl + 12)
    hideRaidBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,insets={left=0,right=0,top=0,bottom=0}})
    hideRaidBtn:SetBackdropColor(0.05, 0.08, 0.18, 1)
    hideRaidBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local hrIcon = hideRaidBtn:CreateTexture(nil, "OVERLAY")
    hrIcon:SetPoint("CENTER", hideRaidBtn, "CENTER", 0, 0)
    hrIcon:SetSize(22, 22)
    hrIcon:SetTexture("Interface\\Icons\\Achievement_pvp_h_12")  -- red = off (raid members visible)
    hideRaidBtn:SetPoint("LEFT", groupFilterBtn, "RIGHT", 2, 0)
    UpdateHideRaidBtn = function()
        if PBM.State.LBFilter.hideRaid then
            hrIcon:SetTexture("Interface\\Icons\\Achievement_pvp_g_12")
            hideRaidBtn:SetBackdropColor(0.05, 0.35, 0.10, 1)
        else
            hrIcon:SetTexture("Interface\\Icons\\Achievement_pvp_h_12")
            hideRaidBtn:SetBackdropColor(0.05, 0.08, 0.18, 1)
        end
    end
    hideRaidBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(hideRaidBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("Raid Tab Filter", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Shows characters that have been added to the raid tab.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    hideRaidBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    hideRaidBtn:SetScript("OnClick", function()
        PBM.State.LBFilter.hideRaid = not PBM.State.LBFilter.hideRaid
        LichborneTrackerDB.hideRaid = PBM.State.LBFilter.hideRaid
        if PBM.State.LBFilter.hideRaid then
            PBM.State.LBFilter.groupActive = false
            LichborneTrackerDB.groupActive = false
            UpdateGroupFilterBtn()
            PBM.State.LBFilter.hideGroupMembers = false
            LichborneTrackerDB.hideGroupMembers = false
            UpdateHideGroupBtn()
        end
        UpdateHideRaidBtn()
        PBM.RefreshRows()
        if PBM.State.LichborneOverviewFrame then PBM.RefreshOverviewRows() end
    end)
    UpdateHideRaidBtn()

    -- ── Hide Group Members filter button — hides tracked chars already in your party ──
    local hideGroupBtn = CreateFrame("Button", "LichborneHideGroupBtn", f)
    hideGroupBtn:SetSize(24, 24)
    hideGroupBtn:SetFrameLevel(fl + 12)
    hideGroupBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,insets={left=0,right=0,top=0,bottom=0}})
    hideGroupBtn:SetBackdropColor(0.05, 0.08, 0.18, 1)
    hideGroupBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local hgIcon = hideGroupBtn:CreateTexture(nil, "OVERLAY")
    hgIcon:SetPoint("CENTER", hideGroupBtn, "CENTER", 0, 0)
    hgIcon:SetSize(22, 22)
    UpdateHideGroupBtn = function()
        if PBM.State.LBFilter.hideGroupMembers then
            hgIcon:SetTexture("Interface\\Icons\\Achievement_pvp_g_10")
            hideGroupBtn:SetBackdropColor(0.05, 0.35, 0.10, 1)
        else
            hgIcon:SetTexture("Interface\\Icons\\Achievement_pvp_h_10")
            hideGroupBtn:SetBackdropColor(0.05, 0.08, 0.18, 1)
        end
    end
    hideGroupBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(hideGroupBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("Hide Group Members", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Hides characters in your current group.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    hideGroupBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    hideGroupBtn:SetScript("OnClick", function()
        PBM.State.LBFilter.hideGroupMembers = not PBM.State.LBFilter.hideGroupMembers
        LichborneTrackerDB.hideGroupMembers = PBM.State.LBFilter.hideGroupMembers
        if PBM.State.LBFilter.hideGroupMembers then
            PBM.State.LBFilter.groupActive = false
            LichborneTrackerDB.groupActive = false
            UpdateGroupFilterBtn()
            PBM.State.LBFilter.hideRaid = false
            LichborneTrackerDB.hideRaid = false
            UpdateHideRaidBtn()
        end
        UpdateHideGroupBtn()
        PBM.RefreshRows()
        if PBM.State.LichborneOverviewFrame then PBM.RefreshOverviewRows() end
    end)
    UpdateHideGroupBtn()

    -- ── Filter button 2 — Show Level ──────────────────────────
    local UpdateIPBtn  -- forward declared; assigned after filterBtn3 is created
    local filterBtn2 = CreateFrame("Button", "LichborneFilterBtn2", f)
    filterBtn2:SetSize(24, 24)
    filterBtn2:SetFrameLevel(fl + 12)
    filterBtn2:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,insets={left=0,right=0,top=0,bottom=0}})
    filterBtn2:SetBackdropColor(0.05, 0.08, 0.18, 1)
    filterBtn2:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local fb2Icon = filterBtn2:CreateTexture(nil, "OVERLAY")
    fb2Icon:SetPoint("CENTER", filterBtn2, "CENTER", 0, 0)
    fb2Icon:SetSize(22, 22)
    fb2Icon:SetTexture("Interface\\Icons\\Achievement_pvp_h_06")  -- off by default
    filterBtn2:SetPoint("LEFT", hideRaidBtn, "RIGHT", 2, 0)

    local function UpdateLevelBtn()
        if PBM.State.LBFilter.showLevel then
            fb2Icon:SetTexture("Interface\\Icons\\Achievement_pvp_g_06")
        else
            fb2Icon:SetTexture("Interface\\Icons\\Achievement_pvp_h_06")
        end
    end
    filterBtn2:SetScript("OnEnter", function()
        GameTooltip:SetOwner(filterBtn2, "ANCHOR_TOP")
        GameTooltip:AddLine("Show Level", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Replaces row numbers with character level", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    filterBtn2:SetScript("OnLeave", function() GameTooltip:Hide() end)
    filterBtn2:SetScript("OnClick", function()
        PBM.State.LBFilter.showLevel = not PBM.State.LBFilter.showLevel
        LichborneTrackerDB.showLevel = PBM.State.LBFilter.showLevel
        if PBM.State.LBFilter.showLevel and PBM.State.LBFilter.showIP then
            PBM.State.LBFilter.showIP = false
            LichborneTrackerDB.showIP = false
            if UpdateIPBtn then UpdateIPBtn() end
        end
        UpdateLevelBtn()
        PBM.RefreshRows()
        if PBM.State.LichborneOverviewFrame then PBM.RefreshOverviewRows() end
        if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
        if PBM.State.groupViewActive and PBM.State.groupViewFrame then PBM.RefreshGroupViewRows() end
    end)
    UpdateLevelBtn()

    -- ── Filter button 3 — Show IP Tiers ───────────────────────
    local filterBtn3 = CreateFrame("Button", "LichborneFilterBtn3", f)
    filterBtn3:SetSize(24, 24)
    filterBtn3:SetFrameLevel(fl + 12)
    filterBtn3:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,insets={left=0,right=0,top=0,bottom=0}})
    filterBtn3:SetBackdropColor(0.05, 0.08, 0.18, 1)
    filterBtn3:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local fb3Icon = filterBtn3:CreateTexture(nil, "OVERLAY")
    fb3Icon:SetPoint("CENTER", filterBtn3, "CENTER", 0, 0)
    fb3Icon:SetSize(22, 22)
    fb3Icon:SetTexture("Interface\\Icons\\Achievement_pvp_h_15")  -- off by default
    filterBtn3:SetPoint("LEFT", filterBtn2, "RIGHT", 2, 0)

    UpdateIPBtn = function()
        if PBM.State.LBFilter.showIP then
            fb3Icon:SetTexture("Interface\\Icons\\Achievement_pvp_g_15")
        else
            fb3Icon:SetTexture("Interface\\Icons\\Achievement_pvp_h_15")
        end
    end
    filterBtn3:SetScript("OnEnter", function()
        GameTooltip:SetOwner(filterBtn3, "ANCHOR_TOP")
        GameTooltip:AddLine("Show IP Tiers", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Replaces row numbers with IP tier (1-18)", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    filterBtn3:SetScript("OnLeave", function() GameTooltip:Hide() end)
    filterBtn3:SetScript("OnClick", function()
        PBM.State.LBFilter.showIP = not PBM.State.LBFilter.showIP
        LichborneTrackerDB.showIP = PBM.State.LBFilter.showIP
        if PBM.State.LBFilter.showIP and PBM.State.LBFilter.showLevel then
            PBM.State.LBFilter.showLevel = false
            LichborneTrackerDB.showLevel = false
            UpdateLevelBtn()
        end
        UpdateIPBtn()
        PBM.RefreshRows()
        if PBM.State.LichborneOverviewFrame then PBM.RefreshOverviewRows() end
        if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
        if PBM.State.groupViewActive and PBM.State.groupViewFrame then PBM.RefreshGroupViewRows() end
    end)
    UpdateIPBtn()

    -- ── Tier Key visibility toggle button ────────────────────────────
    local tierKeyFrames = {}
    local tkLabel  -- forward declared; assigned in tier key section below

    local tierKeyToggleBtn = CreateFrame("Button", "LichborneTierKeyToggleBtn", f)
    tierKeyToggleBtn:SetSize(24, 24)
    tierKeyToggleBtn:SetFrameLevel(fl + 12)
    tierKeyToggleBtn:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=8,
        insets   = {left=2,right=2,top=2,bottom=2},
    })
    tierKeyToggleBtn:SetBackdropColor(0.05, 0.08, 0.18, 1)
    tierKeyToggleBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 1)
    tierKeyToggleBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    tierKeyToggleBtn:SetPoint("LEFT", filterBtn2, "RIGHT", 2, 0)
    local tkvIcon = tierKeyToggleBtn:CreateTexture(nil, "OVERLAY")
    tkvIcon:SetPoint("CENTER", tierKeyToggleBtn, "CENTER", 0, 0)
    tkvIcon:SetSize(24, 24)
    local function UpdateTierKeyToggleBtn()
        if PBM.State.LBFilter.showTierKey then
            tkvIcon:SetTexture("Interface\\Icons\\Achievement_pvp_h_11")
            if tkLabel then tkLabel:Show() end
            for _, frm in ipairs(tierKeyFrames) do frm:Show() end
        else
            tkvIcon:SetTexture("Interface\\Icons\\Achievement_pvp_g_11")
            if tkLabel then tkLabel:Hide() end
            for _, frm in ipairs(tierKeyFrames) do frm:Hide() end
        end
    end
    tierKeyToggleBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(tierKeyToggleBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("|cffC69B3AIndividual Progression Tiers|r", 1, 1, 1)
        GameTooltip:AddLine("Show or hide the tier key bar.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    tierKeyToggleBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    tierKeyToggleBtn:SetScript("OnClick", function()
        PBM.State.LBFilter.showTierKey = not PBM.State.LBFilter.showTierKey
        LichborneTrackerDB.showTierKey = PBM.State.LBFilter.showTierKey
        UpdateTierKeyToggleBtn()
    end)
    UpdateTierKeyToggleBtn()

    -- Tier Key filter swatches (bottom bar)
    tkLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tkLabel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 152)
    tkLabel:SetText("|cffC69B3ATiers:|r")

    -- Single combined Tier Key button replacing T1–T17 individual swatches
    local tierKeyAllBtn = CreateFrame("Button", "LichborneTierKeyAllBtn", f)
    tierKeyAllBtn:SetSize(24, 24)
    tierKeyAllBtn:SetFrameLevel(fl + 12)
    tierKeyAllBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,insets={left=0,right=0,top=0,bottom=0}})
    tierKeyAllBtn:SetBackdropColor(0.05, 0.08, 0.18, 1)
    tierKeyAllBtn:SetPoint("LEFT", tkLabel, "RIGHT", 2, 0)
    tierKeyAllBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local tkBtnIcon = tierKeyAllBtn:CreateTexture(nil, "OVERLAY")
    tkBtnIcon:SetPoint("CENTER", tierKeyAllBtn, "CENTER", 0, 0)
    tkBtnIcon:SetSize(22, 22)
    tkBtnIcon:SetTexture("Interface\\Icons\\inv_banner_03")
    table.insert(tierKeyFrames, tierKeyAllBtn)
    tierKeyAllBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(tierKeyAllBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("|cffC69B3AIndividual Progression Tiers|r", 1, 1, 1)
        GameTooltip:AddLine("Level 60 Raids", 0.85, 0.85, 0.85)
        for t = 0, 6 do
            local c = PBM.TIER_COLORS[t] or {r=0.6,g=0.6,b=0.6}
            GameTooltip:AddLine("  "..(PBM.TIER_LABELS[t] or ("T"..t)), c.r, c.g, c.b)
        end
        GameTooltip:AddLine("Level 70 Raids", 0.85, 0.85, 0.85)
        for t = 7, 12 do
            local c = PBM.TIER_COLORS[t] or {r=0.6,g=0.6,b=0.6}
            GameTooltip:AddLine("  "..(PBM.TIER_LABELS[t] or ("T"..t)), c.r, c.g, c.b)
        end
        GameTooltip:AddLine("Level 80 Raids", 0.85, 0.85, 0.85)
        for t = 13, 18 do
            local c = PBM.TIER_COLORS[t] or {r=0.6,g=0.6,b=0.6}
            GameTooltip:AddLine("  "..(PBM.TIER_LABELS[t] or ("T"..t)), c.r, c.g, c.b)
        end
        GameTooltip:Show()
    end)
    tierKeyAllBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    UpdateTierKeyToggleBtn()

    -- Tier key toggle removed from filter row; Tiers icon always visible
    tierKeyToggleBtn:Hide()
    PBM.State.LBFilter.showTierKey = true
    UpdateTierKeyToggleBtn()

    -- Full right-side chain (left to right):
    --   Filters: | [group] | [hideRaid] | [groupView] | [level] | [IP] | Help: | [tier key] | [help icons] | settings
    exportBtn:Hide()
    importBtn:Hide()
    -- Menu: label removed to make room for the Hide Group Members filter button
    adminLbl:Hide()
    levelSyncHelpBtn:ClearAllPoints()
    levelSyncHelpBtn:SetPoint("RIGHT", settingsBtn, "LEFT", -4, 0)
    bookHelpBtn:ClearAllPoints()
    bookHelpBtn:SetPoint("RIGHT", levelSyncHelpBtn, "LEFT", -2, 0)
    overviewHelpBtn:ClearAllPoints()
    overviewHelpBtn:SetPoint("RIGHT", bookHelpBtn, "LEFT", -2, 0)
    raidHelpBtn:ClearAllPoints()
    raidHelpBtn:SetPoint("RIGHT", overviewHelpBtn, "LEFT", -2, 0)
    classHelpBtn:ClearAllPoints()
    classHelpBtn:SetPoint("RIGHT", raidHelpBtn, "LEFT", -2, 0)
    setupHelpBtn:ClearAllPoints()
    setupHelpBtn:SetPoint("RIGHT", classHelpBtn, "LEFT", -2, 0)
    helpBtn:ClearAllPoints()
    helpBtn:SetPoint("RIGHT", setupHelpBtn, "LEFT", -2, 0)
    -- Tier key sits inside Help section, immediately left of first help icon
    tkLabel:Hide()
    tierKeyAllBtn:ClearAllPoints()
    tierKeyAllBtn:SetPoint("RIGHT", helpBtn, "LEFT", -2, 0)
    infoHelpLbl:SetPoint("RIGHT", tierKeyAllBtn, "LEFT", -1, 0)
    -- Filters: shifted right to sit closer to Help label
    filterBtn3:ClearAllPoints()
    filterBtn3:SetPoint("RIGHT", infoHelpLbl, "LEFT", -6, 0)
    filterBtn2:ClearAllPoints()
    filterBtn2:SetPoint("RIGHT", filterBtn3, "LEFT", -2, 0)
    -- Full right-side chain (left to right):
    --   Filters: | [group] | [hideGroup] | [hideRaid] | [level] | [IP] | Help: | ...
    hideRaidBtn:ClearAllPoints()
    hideRaidBtn:SetPoint("RIGHT", filterBtn2, "LEFT", -2, 0)
    hideGroupBtn:ClearAllPoints()
    hideGroupBtn:SetPoint("RIGHT", hideRaidBtn, "LEFT", -2, 0)
    groupFilterBtn:ClearAllPoints()
    groupFilterBtn:SetPoint("RIGHT", hideGroupBtn, "LEFT", -2, 0)
    filtersLbl:ClearAllPoints()
    filtersLbl:SetPoint("RIGHT", groupFilterBtn, "LEFT", -2, 0)

    -- Apply persisted tab/column visibility (reads PBMConfig.hiddenTabs)
    PBM.RefreshBottomTabPositions()
    RefreshIPColumn()
end

PBM.UpdateSummary = function()
    if not LichborneAvgSwatches then return end
    for _, sw in ipairs(LichborneAvgSwatches) do
        local cls = sw.cls
        if cls == "Raid" then break end
        local avg = PBM.GetClassAvgIlvl(cls)
        local c = PBM.CLASS_COLORS[cls]
        if not c then break end
        local hex = string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255))
        sw.bg:SetTexture(0.08, 0.10, 0.18, 1)
        if avg > 0 then
            sw.lbl:SetText(hex..(PBM.TAB_LABELS[cls])..": |cffd4af37"..avg.."|r")
        else
            sw.lbl:SetText(hex..(PBM.TAB_LABELS[cls])..": |cff555555--|r")
        end
    end
    -- Update Avg GS bar
    if LichborneCountLabels then
        local classIndex = {["Death Knight"]=1,["Druid"]=2,["Hunter"]=3,["Mage"]=4,["Paladin"]=5,["Priest"]=6,["Rogue"]=7,["Shaman"]=8,["Warlock"]=9,["Warrior"]=10}
        for cls, lbl in pairs(LichborneCountLabels) do
            local c = PBM.CLASS_COLORS[cls]
            if not c then break end
            local hex = string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255))
            local gs = PBM.GetClassAvgGS(cls)
            if gs > 0 then
                lbl:SetText(hex..(PBM.TAB_LABELS[cls])..": |cffd4af37"..gs.."|r")
            else
                lbl:SetText(hex..(PBM.TAB_LABELS[cls])..": |cff555555--|r")
            end
            local sw = _G["LichborneClassSwatch"..classIndex[cls]]
            if sw and sw.bg then
                sw.bg:SetTexture(0.08, 0.10, 0.18, 1)
            end
        end
    end
    -- Update Roster iLvl and Roster GS blocks
    if PBM.State.LichborneRosterIlvlLabel then
        local rIlvl = PBM.GetRosterAvgIlvl()
        if rIlvl > 0 then
            PBM.State.LichborneRosterIlvlLabel:SetText("|cffC69B3ARoster iLvL:|r |cffff8000"..rIlvl.."|r")
        else
            PBM.State.LichborneRosterIlvlLabel:SetText("|cffC69B3ARoster iLvL:|r |cff555555--|r")
        end
    end
    if PBM.State.LichborneRosterGsLabel then
        local rGs = PBM.GetRosterAvgGS()
        if rGs > 0 then
            PBM.State.LichborneRosterGsLabel:SetText("|cffC69B3ARoster GS:|r |cffff8000"..rGs.."|r")
        else
            PBM.State.LichborneRosterGsLabel:SetText("|cffC69B3ARoster GS:|r |cff555555--|r")
        end
    end
end


-- ── Open ──────────────────────────────────────────────────────
-- PBM.State.PBM.State.frameBgBuilt declared at module top
local function BuildFrameBG()
    if PBM.State.frameBgBuilt then return end
    PBM.State.frameBgBuilt = true
    local f = LichborneTrackerFrame
    f:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=16,
        insets={left=3,right=3,top=3,bottom=3}
    })
    f:SetBackdropColor(0.04, 0.06, 0.13, 1.0)
    f:SetBackdropBorderColor(0.78, 0.61, 0.23, 1.0)
    local titleBg = f:CreateTexture(nil, "ARTWORK")
    titleBg:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -3)
    titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3)
    titleBg:SetHeight(30)
    titleBg:SetTexture(0.06, 0.09, 0.20, 1)
    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -33)
    divider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -33)
    divider:SetHeight(2)
    divider:SetTexture(0.78, 0.61, 0.23, 1)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -12)
    title:SetPoint("TOPRIGHT", f, "TOPRIGHT", -280, -12)
    title:SetJustifyH("LEFT")
    title:SetText("|cffC69B3APlayerbot Manager|r |cffffffff- v1.4|r")
    local closeBtn = CreateFrame("Button", "LichborneCloseBtn", f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Close all dropdown menus when the frame hides (ESC key or close button)
    f:SetScript("OnHide", function()
        if _G["LichborneRaidTierMenu"]  then _G["LichborneRaidTierMenu"]:Hide()  end
        if _G["LichborneRaidRaidMenu"]  then _G["LichborneRaidRaidMenu"]:Hide()  end
        if _G["LichborneRaidGroupMenu"] then _G["LichborneRaidGroupMenu"]:Hide() end
        if _G["LichborneOverviewGroupMenu"]  then _G["LichborneOverviewGroupMenu"]:Hide()  end
        if LichborneSpecMenu            then LichborneSpecMenu:Hide()            end
        PBM.CloseAllSortMenus()
        PBM.CloseAllClassMenus()
    end)

    -- ── Danger zone buttons (far right of title bar) ──────────
    local function MakeDangerConfirm(title2, lines, onConfirm)
        local cf = CreateFrame("Frame", nil, UIParent)
        cf:SetFrameStrata("FULLSCREEN_DIALOG")
        cf:SetSize(340, 130)
        cf:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
        cf:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=4,right=4,top=4,bottom=4}})
        cf:SetBackdropColor(0.08,0.04,0.04,0.98)
        cf:SetBackdropBorderColor(0.90,0.20,0.20,1)
        cf:Hide()

        local hdr = cf:CreateFontString(nil,"OVERLAY","GameFontNormal")
        hdr:SetPoint("TOP",cf,"TOP",0,-12)
        hdr:SetText("|cffff4444"..title2.."|r")

        local sub = cf:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        sub:SetPoint("TOP",hdr,"BOTTOM",0,-4); sub:SetWidth(310)
        sub:SetText("|cffaaaaaa"..lines.."|r")

        local yBtn = CreateFrame("Button",nil,cf)
        yBtn:SetSize(140,26); yBtn:SetPoint("BOTTOMLEFT",cf,"BOTTOMLEFT",12,10)
        yBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
        yBtn:SetBackdropColor(0.35,0.04,0.04,1); yBtn:SetBackdropBorderColor(1,0.2,0.2,0.9)
        yBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        local yLbl=yBtn:CreateFontString(nil,"OVERLAY","GameFontNormal"); yLbl:SetAllPoints(yBtn); yLbl:SetJustifyH("CENTER")
        yLbl:SetText("|cffff5555Yes, wipe it all|r")
        yBtn:SetScript("OnClick",function() onConfirm(); cf:Hide() end)

        local nBtn = CreateFrame("Button",nil,cf)
        nBtn:SetSize(140,26); nBtn:SetPoint("BOTTOMRIGHT",cf,"BOTTOMRIGHT",-12,10)
        nBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
        nBtn:SetBackdropColor(0.04,0.15,0.04,1); nBtn:SetBackdropBorderColor(0.2,0.8,0.2,0.9)
        nBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        local nLbl=nBtn:CreateFontString(nil,"OVERLAY","GameFontNormal"); nLbl:SetAllPoints(nBtn); nLbl:SetJustifyH("CENTER")
        nLbl:SetText("|cff44ff44Keep my data|r")
        nBtn:SetScript("OnClick",function() cf:Hide() end)
        return cf
    end

    -- Confirm: Clear ALL data (characters + all raids)
    local confirmAll = MakeDangerConfirm(
        "⚠  Wipe Entire Database?",
        "This permanently deletes ALL tracked characters,\ngear data, raid rosters, and the Overview list.",
        function()
            LichborneTrackerDB.rows = {}
            LichborneTrackerDB.raidRosters = {}
            LichborneTrackerDB.needs = {}
            LichborneTrackerDB.profs = {}
            LichborneTrackerDB.botNotes = {}
            LichborneTrackerDB.allGroups = {A={}, B={}, C={}}
            for _, g in ipairs({"A", "B", "C"}) do
                for i=1,60 do
                    LichborneTrackerDB.allGroups[g][i] = {name="",cls="",spec="",gs=0,realGs=0}
                end
            end
            LichborneOutput("|cffC69B3APBM:|r |cffff4444All data wiped.|r", 1, 0.5, 0.5)
            PBM.RefreshRows()
            if PBM.State.LichborneOverviewFrame then PBM.RefreshOverviewRows() end
            if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
        end
    )

    -- Clear All button
    local clrAllBtn = CreateFrame("Button", nil, f)
    clrAllBtn:SetSize(100, 20)
    clrAllBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -450, -8)
    clrAllBtn:SetFrameLevel(f:GetFrameLevel()+10)
    clrAllBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    clrAllBtn:SetBackdropColor(0.30,0.04,0.04,1); clrAllBtn:SetBackdropBorderColor(0.78,0.61,0.23,0.9)
    clrAllBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local clrAllLbl=clrAllBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); clrAllLbl:SetAllPoints(clrAllBtn); clrAllLbl:SetJustifyH("CENTER")
    clrAllLbl:SetText("|cffd4af37Clear All Data|r")
    clrAllBtn:SetScript("OnEnter",function()
        GameTooltip:SetOwner(clrAllBtn,"ANCHOR_BOTTOM")
        GameTooltip:AddLine("|cffff2020Clear All Data|r",1,1,1)
        GameTooltip:AddLine("Deletes ALL characters, gear data,",0.8,0.8,0.8)
        GameTooltip:AddLine("raid rosters, and the Overview list.",0.8,0.8,0.8)
        GameTooltip:AddLine("|cffFF8C00Does not clear LevelSync data.|r",1,1,1)
        GameTooltip:AddLine("|cffff2020This cannot be undone.|r",1,1,1)
        GameTooltip:Show()
    end)
    clrAllBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)
    clrAllBtn:SetScript("OnClick",function() confirmAll:Show() end)
    clrAllBtn:Hide()

    PBM.DBG("|cff44ff44OnFirstShow complete|r PBM.State.rowFrames=|cffffff88"..#PBM.State.rowFrames.."|r PBM.State.raidRowFrames=|cffffff88"..#PBM.State.raidRowFrames.."|r PBM.State.overviewRowFrames=|cffffff88"..(PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames or 0).."|r")
end

function LichborneTracker_Open()
    if not PBM.State.activeTab then PBM.State.activeTab = "Overview" end
    BuildFrameBG()
    OnFirstShow()
    LichborneTrackerFrame:Show()
    PBM.UpdateTabs()
    PBM.RefreshRows()
end

table.insert(_G["UISpecialFrames"], "LichborneTrackerFrame")

do
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("ADDON_LOADED")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "PlayerBotManager" then
            -- DB migration and roster repair run at ADDON_LOADED so SavedVars
            -- are available as early as possible.
            PBM.MigrateGearField()
            -- Restore filter toggle states from DB (SavedVars are live at ADDON_LOADED)
            if LichborneTrackerDB.showTierKey == nil then LichborneTrackerDB.showTierKey = true end
            PBM.State.LBFilter.showTierKey = LichborneTrackerDB.showTierKey
            if LichborneTrackerDB.showLevel == nil then LichborneTrackerDB.showLevel = false end
            PBM.State.LBFilter.showLevel = LichborneTrackerDB.showLevel
            if LichborneTrackerDB.showIP == nil then LichborneTrackerDB.showIP = false end
            PBM.State.LBFilter.showIP = LichborneTrackerDB.showIP
            if LichborneTrackerDB.groupActive == nil then LichborneTrackerDB.groupActive = false end
            PBM.State.LBFilter.groupActive = LichborneTrackerDB.groupActive
            if LichborneTrackerDB.hideRaid == nil then LichborneTrackerDB.hideRaid = false end
            PBM.State.LBFilter.hideRaid = LichborneTrackerDB.hideRaid
            if LichborneTrackerDB.raidNotesFilter == nil then LichborneTrackerDB.raidNotesFilter = false end
            PBM.State.LBFilter.raidNotesFilter = LichborneTrackerDB.raidNotesFilter
            if LichborneTrackerDB.raidRoleFilter == nil then LichborneTrackerDB.raidRoleFilter = false end
            PBM.State.LBFilter.raidRoleFilter = LichborneTrackerDB.raidRoleFilter
            if LichborneTrackerDB.gvCharSheet == nil then LichborneTrackerDB.gvCharSheet = true end
            PBM.State.LBFilter.gvCharSheet = LichborneTrackerDB.gvCharSheet
            if LichborneTrackerDB.classCharSheet == nil then LichborneTrackerDB.classCharSheet = true end
            PBM.State.LBFilter.classCharSheet = LichborneTrackerDB.classCharSheet
            if LichborneTrackerDB.hideGroupMembers == nil then LichborneTrackerDB.hideGroupMembers = false end
            PBM.State.LBFilter.hideGroupMembers = LichborneTrackerDB.hideGroupMembers
            -- Repair all raid rosters: fill any nil/missing slots
            if LichborneTrackerDB and LichborneTrackerDB.raidRosters then
                for key, roster in pairs(LichborneTrackerDB.raidRosters) do
                    if type(roster) == "table" then
                        for i = 1, PBM.MAX_RAID_SLOTS do
                            if not roster[i] or type(roster[i]) ~= "table" then
                                roster[i] = {name="",cls="",spec="",gs=0,realGs=0,role="",notes=""}
                            else
                                if roster[i].role == nil then roster[i].role = "" end
                                if roster[i].notes == nil then roster[i].notes = "" end
                                if roster[i].name == nil then roster[i].name = "" end
                                if roster[i].cls == nil then roster[i].cls = "" end
                                if roster[i].spec == nil then roster[i].spec = "" end
                                if roster[i].gs == nil then roster[i].gs = 0 end
                                if roster[i].realGs == nil then roster[i].realGs = 0 end
                            end
                        end
                    end
                end
            end
        elseif event == "PLAYER_LOGIN" then
            self:UnregisterEvent("PLAYER_LOGIN")
        elseif event == "GET_ITEM_INFO_RECEIVED" then
            -- An item just entered the client cache; re-color any visible gear boxes
            -- whose link now resolves. This fixes imported data where GetItemInfo
            -- returned nil at display time because the item wasn't cached yet.
            for _, row in ipairs(PBM.State.rowFrames) do
                if row:IsShown() and row.dbIndex and row.gearBoxes then
                    local data = LichborneTrackerDB.rows[row.dbIndex]
                    if data and data.ilvlLink then
                        for g = 1, PBM.GEAR_SLOTS do
                            local gb = row.gearBoxes[g]
                            if gb then
                                local link = data.ilvlLink[g]
                                local qc = PBM.GetItemQualityColor(link)
                                if qc then
                                    gb:SetTextColor(qc.r, qc.g, qc.b)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    initFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
end

SLASH_LICHBORNE1 = "/lichborne"
SLASH_LICHBORNE2 = "/lbt"
SlashCmdList["LICHBORNE"] = function(msg)
    if LichborneTrackerFrame and LichborneTrackerFrame:IsShown() then
        LichborneTrackerFrame:Hide()
    else
        LichborneTracker_Open()
    end
end

