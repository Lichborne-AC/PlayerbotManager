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
    local tabW = 1090 / 12
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
        elseif cls == "Settings" then
            hex = "|cff7799ff"
        else
            hex = cc and string.format("|cff%02x%02x%02x",math.floor(cc.r*255),math.floor(cc.g*255),math.floor(cc.b*255)) or "|cffdddddd"
        end
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints(btn); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
        lbl:SetText(hex..(PBM.TAB_LABELS[cls] or cls).."|r")
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
    SH("#", PBM.DRAG_OFF, 18, "level", true)
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
    needsProfHdrFs:SetText("|cffd4af37Need|r")
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
        if cls == "Raid" then break end
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
    infoHelpLbl:SetText("|cffC69B3AInfo/Help:|r")

    -- ── Admin label (between overview help icon and import button) ─
    local adminLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    adminLbl:SetJustifyH("LEFT")
    adminLbl:SetText("|cffC69B3AAdmin:|r")

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
        LichborneOutput("|cffC69B3ALichborne:|r Added "..hex..targetName.."|r ("..cls..")", 1, 0.85, 0)
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
            LichborneOutput("|cffC69B3ALichborne:|r Group scan complete. Added: "..added..", Skipped: "..skipped..(skipped > 0 and ". Levels updated." or ""), 1, 0.85, 0)
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
            LichborneOutput("|cffC69B3ALichborne:|r Added "..hA..targetName.."|r to tracker.", 1, 0.85, 0)
        end
        local rowData = LichborneTrackerDB.rows[foundDi]
        local c = PBM.CLASS_COLORS[rowData.cls or ""]; local hex = c and string.format("|cff%02x%02x%02x",math.floor(c.r*255),math.floor(c.g*255),math.floor(c.b*255)) or "|cffffffff"
        LichborneAddStatus:SetText("Updating Gear for "..hex..targetName.."|r...")
        LichborneOutput("|cffC69B3ALichborne:|r Updating Gear for "..hex..targetName.."|r...", 1, 0.85, 0)
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
                LichborneOutput("|cffC69B3ALichborne:|r |cffff4444Target GS scan timed out.|r", 1, 0.85, 0)
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
            LichborneOutput("|cffC69B3ALichborne:|r Added "..hA..targetName.."|r to tracker.", 1, 0.85, 0)
        end
        local rowData = LichborneTrackerDB.rows[foundDi]
        local c = PBM.CLASS_COLORS[rowData.cls or ""]; local hex = c and string.format("|cff%02x%02x%02x",math.floor(c.r*255),math.floor(c.g*255),math.floor(c.b*255)) or "|cffffffff"
        LichborneAddStatus:SetText("Adding Specialization for "..hex..targetName.."|r...")
        LichborneOutput("|cffC69B3ALichborne:|r Adding Specialization for "..hex..targetName.."|r...", 1, 0.85, 0)
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
                LichborneOutput("|cffC69B3ALichborne:|r |cffff4444Target Specialization scan timed out.|r", 1, 0.85, 0)
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
            LichborneOutput("|cffC69B3ALichborne:|r Group synced (+"..added..", skipped "..skipped..(skipped > 0 and ". Levels updated." or "")..").\nStarting GS scan for "..#units.." players.", 1, 0.85, 0)
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
                    LichborneOutput("|cffC69B3ALichborne:|r |cff44ff44Group GS update complete.|r", 1, 0.85, 0)
                    PBM.DBG("|cff44ff44Group GS scan done|r - "..#units.." units, elapsed |cffffff88"..string.format("%.1f", GetTime()-scanGsStartTime).."s|r")
                    PBM.RefreshRows(); return
                end
                local unit = units[idx]; if not UnitExists(unit) then idx=idx+1; return end
                local targetName = UnitName(unit)
                if not targetName then PBM.DBG("|cffff4444[NIL]|r UnitName("..unit..") returned nil - skipping"); idx=idx+1; return end
                local foundDi = nil
                for i, row in ipairs(LichborneTrackerDB.rows) do if row.name and row.name:lower()==targetName:lower() then foundDi=i; break end end
                if not foundDi then LichborneOutput("|cffC69B3ALichborne:|r Skipping "..tostring(targetName).." (not tracked)",1,0.6,0.3); idx=idx+1; return end
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
            LichborneOutput("|cffC69B3ALichborne:|r Group synced (+"..added..", skipped "..skipped..(skipped > 0 and ". Levels updated." or "")..").\nStarting Specialization scan for "..#units.." players.", 1, 0.85, 0)
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
                    LichborneOutput("|cffC69B3ALichborne:|r |cff44ff44Group Specialization update complete.|r", 1, 0.85, 0)
                    PBM.DBG("|cff44ff44Group Spec scan done|r - "..#units.." units, elapsed |cffffff88"..string.format("%.1f", GetTime()-scanSpecStartTime).."s|r")
                    PBM.RefreshRows(); if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end; return
                end
                local unit = units[idx]; if not UnitExists(unit) then idx=idx+1; return end
                local targetName = UnitName(unit)
                if not targetName then PBM.DBG("|cffff4444[NIL]|r UnitName("..unit..") returned nil - skipping"); idx=idx+1; return end
                local foundDi = nil
                for i, row in ipairs(LichborneTrackerDB.rows) do if row.name and row.name:lower()==targetName:lower() then foundDi=i; break end end
                if not foundDi then LichborneOutput("|cffC69B3ALichborne:|r Skipping "..tostring(targetName).." (not tracked)",1,0.6,0.3); idx=idx+1; return end
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
        SetScanActive(false)
        LichborneAddStatus:SetText("|cffff4444Scan stopped.|r")
        LichborneOutput("|cffC69B3ALichborne:|r |cffff4444Scan stopped.|r", 1, 0.85, 0)
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
        if cls == "Raid" or cls == "Overview" then break end
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
            LichborneOutput("|cffC69B3ALichborne:|r Full Group Scan started (+"..added..", skipped "..skipped..(skipped > 0 and ". Levels updated." or "")..").\nGS phase: "..#units.." players.", 1, 0.85, 0)
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
                    LichborneOutput("|cffC69B3ALichborne:|r GS phase complete. Starting Specialization phase.", 1, 0.85, 0)
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
                            LichborneOutput("|cffC69B3ALichborne:|r |cff44ff44Full Group Scan complete.|r", 1, 0.85, 0)
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
                            LichborneOutput("|cffC69B3ALichborne:|r Skipping "..tostring(targetName).." (not tracked)", 1, 0.6, 0.3)
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
                    LichborneOutput("|cffC69B3ALichborne:|r Skipping "..tostring(targetName).." (not tracked)", 1, 0.6, 0.3)
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
        0.1, 0.6, 0.2, 335, 92,
        155, {{"Log in All Bots",0.78,0.61,0.23},{".playerbots bot add *",0.8,0.8,0.8}})
    loginBtn:SetHeight(39)
    loginBtn:SetScript("OnClick", function() SendChatMessage(".playerbots bot add *", "PARTY") end)

    local logoutBtn = MakeSimpleBtn("LichborneLogoutBtn", "|cffd4af37Log Out All Bots|r",
        0.90, 0.20, 0.20, 335, 50,
        155, {{"Log Out All Bots",0.78,0.61,0.23},{".playerbots bot remove *",0.8,0.8,0.8}})
    logoutBtn:SetHeight(39)
    logoutBtn:SetScript("OnClick", function() SendChatMessage(".playerbots bot remove *", "PARTY") end)

    -- ── Remove Orphaned Bots button ────────────────────────────
    -- Sends .playerbots bot remove <name> for every character in the Overview tab roster
    -- Used when bots are still logged in but player has left the group
    local orphanedBotsBtn = CreateFrame("Button", "LichborneOrphanedBotsBtn", f)
    orphanedBotsBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 335, 134)
    orphanedBotsBtn:SetSize(155, 39)
    orphanedBotsBtn:SetFrameLevel(fl + 12)
    orphanedBotsBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    orphanedBotsBtn:SetBackdropColor(0.90*0.30, 0.20*0.30, 0.20*0.30, 1)
    orphanedBotsBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    orphanedBotsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local orphanedBotsLbl = orphanedBotsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    orphanedBotsLbl:SetAllPoints(orphanedBotsBtn); orphanedBotsLbl:SetJustifyH("CENTER"); orphanedBotsLbl:SetJustifyV("MIDDLE")
    orphanedBotsLbl:SetText("|cffd4af37Clean Up Bots|r")
    orphanedBotsBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(orphanedBotsBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("Clean Up Bots", 0.78, 0.61, 0.23)
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
            LichborneOutput("|cffC69B3ALichborne:|r No orphaned bots found.", 1, 0.5, 0.5)
            if LichborneAddStatus then LichborneAddStatus:SetText("|cffff4444No orphaned bots found.|r") end
            return
        end
        LichborneOutput("|cffC69B3ALichborne:|r Logging out "..#botNames.." orphaned bots...", 1, 0.85, 0)
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
                LichborneOutput("|cffC69B3ALichborne:|r |cff44ff44All "..#botNames.." orphaned bots logged out.|r", 1, 0.85, 0)
                if LichborneAddStatus then LichborneAddStatus:SetText("|cff44ff44Orphaned bots logged out ("..#botNames..").|r") end
                return
            end
            local bname = botNames[orphanIdx]
            SendChatMessage(".playerbots bot remove "..bname, "SAY")
            orphanIdx = orphanIdx + 1
        end)
    end)
    local disbandBtn = CreateFrame("Button", "LichborneDisbandBtn", f)
    disbandBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 335, 8)
    disbandBtn:SetSize(155, 39)
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

    -- Confirmation dialog
    local disbConfirm = CreateFrame("Frame", nil, UIParent)
    disbConfirm:SetSize(260, 80)
    disbConfirm:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    disbConfirm:SetFrameStrata("FULLSCREEN_DIALOG")
    disbConfirm:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=3,right=3,top=3,bottom=3}})
    disbConfirm:SetBackdropColor(0.04, 0.06, 0.13, 0.98)
    disbConfirm:SetBackdropBorderColor(0.90, 0.20, 0.20, 1)
    disbConfirm:Hide()

    local disbText = disbConfirm:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    disbText:SetPoint("TOP", disbConfirm, "TOP", 0, -12)
    disbText:SetText("|cffd4af37Disband Group?|r")
    local disbSub = disbConfirm:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    disbSub:SetPoint("TOP", disbText, "BOTTOM", 0, -4)
    disbSub:SetText("|cffaaaaaaRemoves all bots and leaves the group.|r")

    local disbYes = CreateFrame("Button", nil, disbConfirm)
    disbYes:SetSize(100, 22); disbYes:SetPoint("BOTTOMLEFT", disbConfirm, "BOTTOMLEFT", 12, 10)
    disbYes:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    disbYes:SetBackdropColor(0.32, 0.07, 0.07, 1); disbYes:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    disbYes:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local disbYesLbl = disbYes:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    disbYesLbl:SetAllPoints(disbYes); disbYesLbl:SetJustifyH("CENTER")
    disbYesLbl:SetText("|cffd4af37Yes, Disband|r")

    local disbNo = CreateFrame("Button", nil, disbConfirm)
    disbNo:SetSize(100, 22); disbNo:SetPoint("BOTTOMRIGHT", disbConfirm, "BOTTOMRIGHT", -12, 10)
    disbNo:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    disbNo:SetBackdropColor(0.08, 0.10, 0.18, 1); disbNo:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    disbNo:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local disbNoLbl = disbNo:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    disbNoLbl:SetAllPoints(disbNo); disbNoLbl:SetJustifyH("CENTER")
    disbNoLbl:SetText("|cffd4af37Cancel|r")

    disbNo:SetScript("OnClick", function() disbConfirm:Hide() end)

    disbYes:SetScript("OnClick", function()
        disbConfirm:Hide()
        PBM.SetButtonsLocked(true)
        -- Also lock Stop and Invite Raid/Group during disband
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
        LichborneOutput("|cffC69B3ALichborne:|r |cffd4af37Disbanding group...|r", 1, 0.85, 0)
        SendChatMessage(".playerbots bot remove *", "SAY")
        local waited = 0
        local disbFrame = CreateFrame("Frame")
        disbFrame:SetScript("OnUpdate", function(_, elapsed)
            waited = waited + elapsed
            if waited < 1.0 then return end
            LeaveParty()
            PBM.SetButtonsLocked(false)
            lockExtra(false)
            LichborneOutput("|cffC69B3ALichborne:|r |cffd4af37Group disbanded.|r", 1, 0.85, 0)
            disbFrame:SetScript("OnUpdate", nil)
        end)
    end)

    disbandBtn:SetScript("OnClick", function()
        disbConfirm:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        disbConfirm:Show()
    end)

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
    outputScroll:SetPoint("TOPLEFT", outputBox, "TOPLEFT", 4, -26)
    outputScroll:SetPoint("BOTTOMRIGHT", outputBox, "BOTTOMRIGHT", -4, 4)
    outputScroll:SetFontObject("GameFontNormalSmall")
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
        LichborneOutput("|cffC69B3ALichborne:|r |cffd4af37Export ready — click Select All, then press Ctrl+C.|r")
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
        LichborneOutput("|cffC69B3ALichborne:|r |cffd4af37Import complete — tracker data loaded.|r")
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
        GameTooltip:AddLine("   |cffC69B3A(GS)|r, |cffC69B3AiLvL|r, |cffC69B3Agear,|r and |cffC69B3Aspecialization|r to the tracker.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("   Allow 4-5 minutes for a complete scan.", 1, 0.55, 0.0)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("TIP: Use |cffC69B3A.playerbot bot addaccount <account>|r to", 0.4, 0.8, 1)
        GameTooltip:AddLine("     quickly add bots for first time set up.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: |cffC69B3A+Add Target|r buttons are used for |cffC69B3ASingle|r scans.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: |cffC69B3A+Add Group|r buttons are used for |cffC69B3AGroup|r scans.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: |cffC69B3AClean Up Bots|r removes bots currently not", 0.4, 0.8, 1)
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
        GameTooltip:AddLine("TIP: Use the |cffC69B3ANeed|r cell to flag which gear slot", 0.4, 0.8, 1)
        GameTooltip:AddLine("     a character needs to upgrade.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: You can change the spec by clicking the icon.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Click |cff00cc00[+]|r on a PlayerBot row to add to the", 0.4, 0.8, 1)
        GameTooltip:AddLine("     |cffC69B3ARaid Tab|r.  Right-click |cffFF6600[+]|r to remove.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Click |cff00cc00[>]|r to invite PlayerBot to your", 0.4, 0.8, 1)
        GameTooltip:AddLine("     |cffC69B3AGroup|r.  Right-click |cff00cc00[>]|r to remove.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Use |cff66CCFFDelete Character|r |cffff3333[x]|r to remove", 0.4, 0.8, 1)
        GameTooltip:AddLine("     PlayerBots from your tracker.", 0.4, 0.8, 1)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cffC69B3ANote:|r Some |cff00cc00<Random Enchantment>|r gear cannot", 0.4, 0.8, 1)
        GameTooltip:AddLine("     be displayed correctly, due to client limitations.", 0.4, 0.8, 1)
        GameTooltip:AddLine("|cffC69B3ANote:|r Some items may display with a 0 Gear Score.", 0.4, 0.8, 1)
        GameTooltip:AddLine("     Such as PvP gear.", 0.4, 0.8, 1)
        GameTooltip:Show()
    end)
    classHelpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

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
        GameTooltip:AddLine("TIP: Use the |cffC69B3ANeed|r cell to mark which slot a", 0.4, 0.8, 1)
        GameTooltip:AddLine("     PlayerBot needs an upgrade.", 0.4, 0.8, 1)
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
        GameTooltip:AddLine("Templates are found in each |cffC69B3AClass Tab|r — click the", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("|cffC69B3A?|r or |cffC69B3ASpec icon|r in the top-left of the tab.", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("TIP: Always set strategies via a |cffC69B3ATemplate|r first,", 0.4, 0.8, 1)
        GameTooltip:AddLine("     then fine-tune individual strategies if needed.", 0.4, 0.8, 1)
        GameTooltip:AddLine("TIP: Bots retain their strategies between sessions.", 0.4, 0.8, 1)
        GameTooltip:Show()
    end)
    bookHelpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

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
    optsTitleText:SetText("|cffC69B3ALichborne Gear Tracker|r")

    local optsXBtn = CreateFrame("Button", nil, optionsPanel, "UIPanelCloseButton")
    optsXBtn:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", 4, 4)
    optsXBtn:SetFrameLevel(optionsPanel:GetFrameLevel() + 3)
    optsXBtn:SetScript("OnClick", function() optionsPanel:Hide() end)

    local optsTitleDiv = optionsPanel:CreateTexture(nil, "OVERLAY")
    optsTitleDiv:SetPoint("TOPLEFT",  optionsPanel, "TOPLEFT",  6, -36)
    optsTitleDiv:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", -6, -36)
    optsTitleDiv:SetHeight(1)
    optsTitleDiv:SetTexture(0.78, 0.61, 0.23, 0.9)

    -- Update tab button
    local optsTabGeneral = CreateFrame("Button", nil, optionsPanel)
    optsTabGeneral:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 8, -40)
    optsTabGeneral:SetSize(100, 24)
    optsTabGeneral:SetFrameLevel(optionsPanel:GetFrameLevel() + 2)
    optsTabGeneral:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=8,
        insets={left=2, right=2, top=2, bottom=2}
    })
    optsTabGeneral:SetBackdropColor(0.12, 0.16, 0.30, 1)
    optsTabGeneral:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    optsTabGeneral:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local optsTabLbl = optsTabGeneral:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    optsTabLbl:SetAllPoints(optsTabGeneral)
    optsTabLbl:SetJustifyH("CENTER")
    optsTabLbl:SetText("|cffFFFFFFUpdate|r")

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
    -- ── Update tab content ────────────────────────────────────────────

    -- Get latest version via Git clone
    local updLabel1 = optsContentBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    updLabel1:SetPoint("TOPLEFT", optsContentBox, "TOPLEFT", 10, -14)
    updLabel1:SetText("|cffd4af37Get the latest version -- clone the repository with Git:|r")

    local updBg1 = CreateFrame("Frame", nil, optsContentBox)
    updBg1:SetPoint("TOPLEFT",  optsContentBox, "TOPLEFT",  8, -34)
    updBg1:SetPoint("TOPRIGHT", optsContentBox, "TOPRIGHT", -8, -34)
    updBg1:SetHeight(22)
    updBg1:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    updBg1:SetBackdropColor(0.02, 0.02, 0.06, 1)
    updBg1:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.8)
    updBg1:SetFrameLevel(optionsPanel:GetFrameLevel() + 2)

    local updEdit1 = CreateFrame("EditBox", "LichborneUpdateCloneBox", updBg1)
    updEdit1:SetPoint("TOPLEFT",     updBg1, "TOPLEFT",      4, -2)
    updEdit1:SetPoint("BOTTOMRIGHT", updBg1, "BOTTOMRIGHT", -4,  2)
    updEdit1:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    updEdit1:SetTextColor(1, 1, 1, 1)
    updEdit1:SetAutoFocus(false)
    updEdit1:EnableMouse(true)
    updEdit1:SetText("git clone https://github.com/Lichborne-AC/LichborneTracker")
    updEdit1:SetFrameLevel(optionsPanel:GetFrameLevel() + 3)

    local updSelectBtn1 = CreateFrame("Button", nil, optsContentBox, "UIPanelButtonTemplate")
    updSelectBtn1:SetSize(90, 22)
    updSelectBtn1:SetPoint("TOPLEFT", optsContentBox, "TOPLEFT", 8, -62)
    updSelectBtn1:SetText("Select All")
    updSelectBtn1:SetFrameLevel(optionsPanel:GetFrameLevel() + 3)
    updSelectBtn1:SetScript("OnClick", function()
        updEdit1:SetFocus()
        updEdit1:HighlightText()
    end)

    local updHint1 = optsContentBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    updHint1:SetPoint("LEFT", updSelectBtn1, "RIGHT", 10, 0)
    updHint1:SetText("|cffd4af37Push Select All then Ctrl+C to copy|r")

    -- Browse / download from GitHub
    local updLabel2 = optsContentBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    updLabel2:SetPoint("TOPLEFT", optsContentBox, "TOPLEFT", 10, -96)
    updLabel2:SetText("|cffd4af37Browse or download from the GitHub repository:|r")

    local updBg2 = CreateFrame("Frame", nil, optsContentBox)
    updBg2:SetPoint("TOPLEFT",  optsContentBox, "TOPLEFT",  8, -116)
    updBg2:SetPoint("TOPRIGHT", optsContentBox, "TOPRIGHT", -8, -116)
    updBg2:SetHeight(22)
    updBg2:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    updBg2:SetBackdropColor(0.02, 0.02, 0.06, 1)
    updBg2:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.8)
    updBg2:SetFrameLevel(optionsPanel:GetFrameLevel() + 2)

    local updEdit2 = CreateFrame("EditBox", "LichborneUpdateRepoBox", updBg2)
    updEdit2:SetPoint("TOPLEFT",     updBg2, "TOPLEFT",      4, -2)
    updEdit2:SetPoint("BOTTOMRIGHT", updBg2, "BOTTOMRIGHT", -4,  2)
    updEdit2:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    updEdit2:SetTextColor(1, 1, 1, 1)
    updEdit2:SetAutoFocus(false)
    updEdit2:EnableMouse(true)
    updEdit2:SetText("https://github.com/Lichborne-AC/LichborneTracker")
    updEdit2:SetFrameLevel(optionsPanel:GetFrameLevel() + 3)

    local updSelectBtn2 = CreateFrame("Button", nil, optsContentBox, "UIPanelButtonTemplate")
    updSelectBtn2:SetSize(90, 22)
    updSelectBtn2:SetPoint("TOPLEFT", optsContentBox, "TOPLEFT", 8, -144)
    updSelectBtn2:SetText("Select All")
    updSelectBtn2:SetFrameLevel(optionsPanel:GetFrameLevel() + 3)
    updSelectBtn2:SetScript("OnClick", function()
        updEdit2:SetFocus()
        updEdit2:HighlightText()
    end)

    local updHint2 = optsContentBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    updHint2:SetPoint("LEFT", updSelectBtn2, "RIGHT", 10, 0)
    updHint2:SetText("|cffd4af37Push Select All then Ctrl+C to copy|r")
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

    -- Apply button
    local optsApplyBtn = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
    optsApplyBtn:SetPoint("RIGHT", optsCloseBtn, "LEFT", -6, 0)
    optsApplyBtn:SetSize(80, 24)
    optsApplyBtn:SetText("Apply")
    optsApplyBtn:SetFrameLevel(optionsPanel:GetFrameLevel() + 3)
    optsApplyBtn:SetScript("OnClick", function()
        -- placeholder: will apply settings when populated
    end)

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
        GameTooltip:AddLine("Options", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Open the Lichborne options panel.", 1, 1, 1)
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
    local function UpdateGroupFilterBtn()
        if PBM.State.LBFilter.groupActive then
            gfIcon:SetTexture("Interface\\Icons\\Achievement_pvp_g_02")
        else
            gfIcon:SetTexture("Interface\\Icons\\Achievement_pvp_h_02")
        end
    end
    groupFilterBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(groupFilterBtn, "ANCHOR_TOP")
        GameTooltip:AddLine("Party Filter", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Hides characters not in your party or raid.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    groupFilterBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    groupFilterBtn:SetScript("OnClick", function()
        PBM.State.LBFilter.groupActive = not PBM.State.LBFilter.groupActive
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
    local function UpdateHideRaidBtn()
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
        GameTooltip:AddLine("Shows only characters in your currently selected raid.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    hideRaidBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    hideRaidBtn:SetScript("OnClick", function()
        PBM.State.LBFilter.hideRaid = not PBM.State.LBFilter.hideRaid
        UpdateHideRaidBtn()
        PBM.RefreshRows()
        if PBM.State.LichborneOverviewFrame then PBM.RefreshOverviewRows() end
    end)
    UpdateHideRaidBtn()

    -- ── Filter button 2 ────────────────────────────────────────
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
        UpdateLevelBtn()
        PBM.RefreshRows()
        if PBM.State.LichborneOverviewFrame then PBM.RefreshOverviewRows() end
    end)
    UpdateLevelBtn()

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
        GameTooltip:AddLine("Tier Key", 0.78, 0.61, 0.23)
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
        GameTooltip:AddLine("Tier Key", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Level 60 Raids", 0.85, 0.85, 0.85)
        for t = 1, 6 do
            local c = PBM.TIER_COLORS[t]
            GameTooltip:AddLine("  "..(PBM.TIER_LABELS[t] or ("T"..t)), c.r, c.g, c.b)
        end
        GameTooltip:AddLine("Level 70 Raids", 0.85, 0.85, 0.85)
        for t = 7, 12 do
            local c = PBM.TIER_COLORS[t]
            GameTooltip:AddLine("  "..(PBM.TIER_LABELS[t] or ("T"..t)), c.r, c.g, c.b)
        end
        GameTooltip:AddLine("Level 80 Raids", 0.85, 0.85, 0.85)
        for t = 13, 17 do
            local c = PBM.TIER_COLORS[t]
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
    --   Filters: | [filter icons] | Info/Help: | [tier key] | [help icons] | Admin: | << >> | settings
    exportBtn:ClearAllPoints()
    exportBtn:SetPoint("RIGHT", settingsBtn, "LEFT", -2, 0)
    importBtn:ClearAllPoints()
    importBtn:SetPoint("RIGHT", exportBtn, "LEFT", -2, 0)
    adminLbl:SetPoint("RIGHT", importBtn, "LEFT", -4, 0)
    bookHelpBtn:ClearAllPoints()
    bookHelpBtn:SetPoint("RIGHT", adminLbl, "LEFT", -2, 0)
    overviewHelpBtn:ClearAllPoints()
    overviewHelpBtn:SetPoint("RIGHT", bookHelpBtn, "LEFT", -2, 0)
    raidHelpBtn:ClearAllPoints()
    raidHelpBtn:SetPoint("RIGHT", overviewHelpBtn, "LEFT", -2, 0)
    classHelpBtn:ClearAllPoints()
    classHelpBtn:SetPoint("RIGHT", raidHelpBtn, "LEFT", -2, 0)
    helpBtn:ClearAllPoints()
    helpBtn:SetPoint("RIGHT", classHelpBtn, "LEFT", -2, 0)
    -- Tier key sits inside Info/Help section, immediately left of first help icon
    tkLabel:Hide()
    tierKeyAllBtn:ClearAllPoints()
    tierKeyAllBtn:SetPoint("RIGHT", helpBtn, "LEFT", -2, 0)
    infoHelpLbl:SetPoint("RIGHT", tierKeyAllBtn, "LEFT", -4, 0)
    -- Filters: immediately left of Info/Help label, uniform 2px gaps throughout
    filterBtn2:ClearAllPoints()
    filterBtn2:SetPoint("RIGHT", infoHelpLbl, "LEFT", -2, 0)
    hideRaidBtn:ClearAllPoints()
    hideRaidBtn:SetPoint("RIGHT", filterBtn2, "LEFT", -2, 0)
    groupFilterBtn:ClearAllPoints()
    groupFilterBtn:SetPoint("RIGHT", hideRaidBtn, "LEFT", -2, 0)
    filtersLbl:ClearAllPoints()
    filtersLbl:SetPoint("RIGHT", groupFilterBtn, "LEFT", -2, 0)

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
    title:SetText("|cffC69B3APlayerbot Manager|r  |cffffffff v1.0|r")
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
            LichborneTrackerDB.raidName = "N/A (5-Man)"
            LichborneTrackerDB.raidSize = 5
            LichborneTrackerDB.raidTier = 0
            LichborneTrackerDB.raidGroup = "A"
            LichborneOutput("|cffC69B3ALichborne:|r |cffff4444All data wiped.|r", 1, 0.5, 0.5)
            PBM.RefreshRows()
            if PBM.State.LichborneOverviewFrame then PBM.RefreshOverviewRows() end
            if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
        end
    )

    -- Confirm: Clear all raid rosters only
    local confirmRaids = MakeDangerConfirm(
        "⚠  Wipe All Raid Rosters?",
        "This clears every raid roster (all tiers, raids,\nand groups A/B/C). Characters remain in class tabs.",
        function()
            LichborneTrackerDB.raidRosters = {}
            LichborneTrackerDB.botNotes = {}
            LichborneOutput("|cffC69B3ALichborne:|r |cffff9900All raid rosters cleared.|r", 1, 0.7, 0)
            if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
            if PBM.State.LichborneOverviewFrame then PBM.RefreshOverviewRows() end
        end
    )

    -- Clear Raids button (now on LEFT)
    local clrRaidsBtn = CreateFrame("Button", nil, f)
    clrRaidsBtn:SetSize(100, 20)
    clrRaidsBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -415, -8)
    clrRaidsBtn:SetFrameLevel(f:GetFrameLevel()+10)
    clrRaidsBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    clrRaidsBtn:SetBackdropColor(0.30,0.04,0.04,1); clrRaidsBtn:SetBackdropBorderColor(0.78,0.61,0.23,0.9)
    clrRaidsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local clrRaidsLbl=clrRaidsBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); clrRaidsLbl:SetAllPoints(clrRaidsBtn); clrRaidsLbl:SetJustifyH("CENTER")
    clrRaidsLbl:SetText("|cffd4af37Clear Raids|r")
    clrRaidsBtn:SetScript("OnEnter",function()
        GameTooltip:SetOwner(clrRaidsBtn,"ANCHOR_BOTTOM")
        GameTooltip:AddLine("Clear All Raid Rosters",1,0.5,0.5)
        GameTooltip:AddLine("Wipes every raid group across all tiers.",0.8,0.8,0.8)
        GameTooltip:AddLine("Character data is NOT affected.",0.6,0.8,0.6)
        GameTooltip:Show()
    end)
    clrRaidsBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)
    clrRaidsBtn:SetScript("OnClick",function() confirmRaids:Show() end)

    -- Clear All button
    local clrAllBtn = CreateFrame("Button", nil, f)
    clrAllBtn:SetSize(100, 20)
    clrAllBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -311, -8)
    clrAllBtn:SetFrameLevel(f:GetFrameLevel()+10)
    clrAllBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    clrAllBtn:SetBackdropColor(0.30,0.04,0.04,1); clrAllBtn:SetBackdropBorderColor(0.78,0.61,0.23,0.9)
    clrAllBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local clrAllLbl=clrAllBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); clrAllLbl:SetAllPoints(clrAllBtn); clrAllLbl:SetJustifyH("CENTER")
    clrAllLbl:SetText("|cffd4af37Clear All Data|r")
    clrAllBtn:SetScript("OnEnter",function()
        GameTooltip:SetOwner(clrAllBtn,"ANCHOR_BOTTOM")
        GameTooltip:AddLine("Wipe Entire Database",1,0.3,0.3)
        GameTooltip:AddLine("Permanently deletes ALL characters,",0.8,0.8,0.8)
        GameTooltip:AddLine("gear data, raid rosters, and the Overview list.",0.8,0.8,0.8)
        GameTooltip:AddLine("|cffff4444This cannot be undone.|r",1,0.4,0.4)
        GameTooltip:Show()
    end)
    clrAllBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)
    clrAllBtn:SetScript("OnClick",function() confirmAll:Show() end)
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

