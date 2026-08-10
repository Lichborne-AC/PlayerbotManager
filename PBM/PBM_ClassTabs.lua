PBM = PBM or {}
PBM.State = PBM.State or {}

-- ── Class-tab drag-to-reorder state (mirrors LichborneTracker) ────
-- classMouseHeld is toggled by the drag handle's OnMouseDown/OnMouseUp.
-- Dragging reorders LichborneTrackerDB.rows directly and clears the active
-- class sort so the manual order sticks.
local classDragPoll   = CreateFrame("Frame")
local classMouseHeld  = false
local classDragSource = nil   -- row frame currently being dragged

classDragPoll:SetScript("OnUpdate", function()
    if not classDragSource then return end
    if not classMouseHeld then
        -- Released — find the row under the cursor and move there
        local cx, cy = GetCursorPosition()
        local sc = UIParent:GetEffectiveScale()
        cx, cy = cx/sc, cy/sc
        local targetRow = nil
        for _, rf in ipairs(PBM.State.rowFrames) do
            if rf:IsShown() and rf ~= classDragSource and rf.dbIndex then
                local d = LichborneTrackerDB.rows[rf.dbIndex]
                if d and d.name and d.name ~= "" then
                    local l,r,b,t = rf:GetLeft(),rf:GetRight(),rf:GetBottom(),rf:GetTop()
                    if l and cx>=l and cx<=r and cy>=b and cy<=t then
                        targetRow = rf; break
                    end
                end
            end
        end
        if targetRow then
            local a = classDragSource.dbIndex
            local b = targetRow.dbIndex
            if a and b and a ~= b then
                local rows = LichborneTrackerDB.rows
                local item = rows[a]
                table.remove(rows, a)
                local insertAt = b > a and b - 1 or b
                table.insert(rows, insertAt, item)
                if PBM.State.classSortKey then PBM.State.classSortKey[PBM.State.activeTab] = nil end
                if PBM.UpdateClassSortHeaders then PBM.UpdateClassSortHeaders() end
                PBM.RefreshRows()
                if PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames > 0 then PBM.RefreshOverviewRows() end
            end
        end
        for _, rf in ipairs(PBM.State.rowFrames) do
            if rf.hov then rf.hov:SetTexture(0,0,0,0) end
            if rf.dropHi then rf.dropHi:SetTexture(0,0,0,0) end
            if rf.dragTex then rf.dragTex:SetVertexColor(0.3,0.4,0.6,0) end
        end
        classDragSource = nil
        return
    end
    -- Still dragging — highlight whichever row the cursor is over
    local cx, cy = GetCursorPosition()
    local sc = UIParent:GetEffectiveScale()
    cx, cy = cx/sc, cy/sc
    for _, rf in ipairs(PBM.State.rowFrames) do
        if rf:IsShown() and rf ~= classDragSource and rf.dropHi then
            local d = rf.dbIndex and LichborneTrackerDB.rows[rf.dbIndex]
            local l,r,b,t = rf:GetLeft(),rf:GetRight(),rf:GetBottom(),rf:GetTop()
            if l and d and d.name and d.name ~= "" and cx>=l and cx<=r and cy>=b and cy<=t then
                rf.dropHi:SetTexture(0.9,0.7,0.1,0.20)
            else
                rf.dropHi:SetTexture(0,0,0,0)
            end
        end
    end
end)

-- Installs gear slot tooltip handlers on a character menu's header cells.
-- Call once at menu build time. menuFrame._gearLinks must be set on open.
function PBM.InstallGearTooltips(menuFrame, hdr)
    for g = 1, PBM.GEAR_SLOTS do
        local cell = hdr.gearCells[g]
        cell:EnableMouse(true)
        cell:SetScript("OnEnter", function()
            local link = menuFrame._gearLinks and menuFrame._gearLinks[g]
            if link and link ~= "" then
                GetItemInfo(link)
                GameTooltip:SetOwner(cell, "ANCHOR_BOTTOM")
                local ok = pcall(function() GameTooltip:SetHyperlink(link) end)
                if ok then GameTooltip:Show() else GameTooltip:Hide() end
            end
        end)
        cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
end

-- State declarations (module-level in original)
PBM.State.rowFrames  = PBM.State.rowFrames  or {}
PBM.State.tabButtons = PBM.State.tabButtons or {}
PBM.State.activeTab  = PBM.State.activeTab  or "Overview"

PBM.State.ignoredSpells      = PBM.State.ignoredSpells      or {}
PBM.State.ignoredSpellChar   = PBM.State.ignoredSpellChar   -- nil by default
PBM.State.ignoredSpellScroll = PBM.State.ignoredSpellScroll or 0
PBM.State.ignoredSpellRows   = PBM.State.ignoredSpellRows   or {}
PBM.State.ignoredSpellFrame  = PBM.State.ignoredSpellFrame  -- nil by default

PBM.State.classSortKey  = PBM.State.classSortKey  or {}   -- classSortKey[cls]  nil|"spec"|"name"|"ilvl"|"gs"|"gear_N"
PBM.State.classSortAsc  = PBM.State.classSortAsc  or {}   -- classSortAsc[cls]  bool; true=A-Z/low-high
PBM.State.classSortHdrs = PBM.State.classSortHdrs or {}   -- key -> {lbl=str, fs=FontString} for indicator update

-- ─────────────────────────────────────────────────────────────────────────────
-- GetAllClassRows
-- ─────────────────────────────────────────────────────────────────────────────
function PBM.GetAllClassRows(cls)
    -- Returns ALL row indices for a class regardless of page (for add/search ops)
    local out = {}
    if cls == "Raid" or cls == "Overview" then return out end
    for i, row in ipairs(LichborneTrackerDB.rows) do
        if row.cls == cls then out[#out+1] = i end
    end
    return out
end

-- ─────────────────────────────────────────────────────────────────────────────
-- UpdateClassSortHeaders
-- ─────────────────────────────────────────────────────────────────────────────
function PBM.UpdateClassSortHeaders()
    local cls = PBM.State.activeTab
    local curKey = PBM.State.classSortKey[cls]
    local curAsc = PBM.State.classSortAsc[cls]
    for key, entry in pairs(PBM.State.classSortHdrs) do
        if curKey == key then
            local arrow = curAsc and " ^" or " v"
            entry.fs:SetText("|cffd4af37"..entry.lbl..arrow.."|r")
        else
            entry.fs:SetText("|cffd4af37"..entry.lbl.."|r")
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- GetGroupMemberNameSet
-- ─────────────────────────────────────────────────────────────────────────────
function PBM.GetGroupMemberNameSet()
    local set = {}
    local pname = UnitName("player")
    if pname then set[pname] = true end
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local n = UnitName("raid"..i)
            if n then set[n] = true end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local n = UnitName("party"..i)
            if n then set[n] = true end
        end
    end
    return set
end

-- ─────────────────────────────────────────────────────────────────────────────
-- GetClassRows
-- ─────────────────────────────────────────────────────────────────────────────
function PBM.GetClassRows(cls)
    local out = {}
    if cls == "Raid" or cls == "Overview" then return out end
    local offset = PBM.State.classScroll[cls] or 0
    local count = 0
    -- Collect all matching indices for this class
    local allIdx = {}
    for i, row in ipairs(LichborneTrackerDB.rows) do
        if row.cls == cls then
            allIdx[#allIdx+1] = i
        end
    end
    -- Apply group filter: keep empty rows, hide named non-group members
    if PBM.State.LBFilter.groupActive then
        local gnames = PBM.GetGroupMemberNameSet()
        local filtered = {}
        for _, ai in ipairs(allIdx) do
            local n = LichborneTrackerDB.rows[ai].name or ""
            if n == "" or gnames[n] then filtered[#filtered+1] = ai end
        end
        allIdx = filtered
    end
    -- Apply hide-raid filter: exclude characters already in the raid tab roster
    if PBM.State.LBFilter.hideRaid then
        local raidFiltered = {}
        for _, ai in ipairs(allIdx) do
            local nm = LichborneTrackerDB.rows[ai].name or ""
            if nm ~= "" and PBM.IsInActiveRaid(nm) then raidFiltered[#raidFiltered+1] = ai end
        end
        allIdx = raidFiltered
    end
    -- Apply hide-group filter: hide characters already in your current party/group
    if PBM.State.LBFilter.hideGroupMembers then
        local gnames = PBM.GetGroupMemberNameSet()
        local groupFiltered = {}
        for _, ai in ipairs(allIdx) do
            local nm = LichborneTrackerDB.rows[ai].name or ""
            if nm == "" or not gnames[nm] then groupFiltered[#groupFiltered+1] = ai end
        end
        allIdx = groupFiltered
    end
    -- Apply header-click sort if active; always compact filled before empty
    local curKey = PBM.State.classSortKey[cls]
    local curAsc = PBM.State.classSortAsc[cls]
    if curKey then
        table.sort(allIdx, function(a, b)
            local ra, rb = LichborneTrackerDB.rows[a], LichborneTrackerDB.rows[b]
            local na, nb = ra.name or "", rb.name or ""
            -- Empty rows always sink to the bottom
            if (na == "") ~= (nb == "") then return na ~= "" end
            if curKey == "spec" then
                local sa, sb2 = ra.spec or "", rb.spec or ""
                if sa ~= sb2 then
                    if curAsc then return sa < sb2 else return sa > sb2 end
                end
                return na < nb
            elseif curKey == "name" then
                if na ~= nb then
                    if curAsc then return na < nb else return na > nb end
                end
                return false
            elseif curKey == "ilvl" then
                local ga, gb2 = ra.gs or 0, rb.gs or 0
                if ga ~= gb2 then
                    if curAsc then return ga < gb2 else return ga > gb2 end
                end
                return na < nb
            elseif curKey == "gs" then
                local ga, gb2 = ra.realGs or 0, rb.realGs or 0
                if ga ~= gb2 then
                    if curAsc then return ga < gb2 else return ga > gb2 end
                end
                return na < nb
            elseif curKey == "level" then
                local la, lb = ra.level or 0, rb.level or 0
                if la ~= lb then
                    if curAsc then return la < lb else return la > lb end
                end
                return na < nb
            else  -- "gear_N"
                local g = tonumber(curKey:sub(6)) or 1
                local ga = (ra.ilvl and ra.ilvl[g]) or 0
                local gb2 = (rb.ilvl and rb.ilvl[g]) or 0
                if ga ~= gb2 then
                    if curAsc then return ga < gb2 else return ga > gb2 end
                end
                return na < nb
            end
        end)
    else
        -- No sort key: compact filled rows to top, empty rows to bottom
        local filled, empty = {}, {}
        for _, i in ipairs(allIdx) do
            if LichborneTrackerDB.rows[i].name ~= "" then
                filled[#filled+1] = i
            else
                empty[#empty+1] = i
            end
        end
        allIdx = {}
        for _, i in ipairs(filled) do allIdx[#allIdx+1] = i end
        for _, i in ipairs(empty)  do allIdx[#allIdx+1] = i end
    end
    -- Clamp scroll offset and apply slice (stop at last filled row)
    local total = #allIdx
    local filledCount = 0
    for _, ai in ipairs(allIdx) do
        if LichborneTrackerDB.rows[ai].name ~= "" then filledCount = filledCount + 1 end
    end
    local maxOffset = math.max(0, filledCount - PBM.MAX_ROWS)
    offset = math.min(math.max(0, offset), maxOffset)
    PBM.State.classScroll[cls] = offset
    for i = offset + 1, math.min(offset + PBM.MAX_ROWS, total) do
        out[#out+1] = allIdx[i]
    end
    return out
end

-- ─────────────────────────────────────────────────────────────────────────────
-- BuildRows
-- ─────────────────────────────────────────────────────────────────────────────
-- Called by PBM_Core when a "Strategies: ..." whisper arrives for a class menu
function PBM.UpdateStrategyToggles(menuFrame, stratType, activeSet)
    if not menuFrame then return end
    -- Frame-specific callback (used by class overlay menus)
    if menuFrame.onStrategyUpdate then
        menuFrame.onStrategyUpdate(stratType, activeSet)
    end
end

-- Close all class overlay menus
local CLASS_MENU_CLOSE = {
    "CloseDKMenu", "CloseDruidMenu", "CloseHunterMenu", "CloseMageMenu",
    "ClosePaladinMenu", "ClosePriestMenu", "CloseRogueMenu",
    "CloseShamanMenu", "CloseWarlockMenu", "CloseWarriorMenu",
}

local CLASS_MENU_CLOSE_MAP = {
    ["Death Knight"] = "CloseDKMenu",
    ["Druid"]        = "CloseDruidMenu",
    ["Hunter"]       = "CloseHunterMenu",
    ["Mage"]         = "CloseMageMenu",
    ["Paladin"]      = "ClosePaladinMenu",
    ["Priest"]       = "ClosePriestMenu",
    ["Rogue"]        = "CloseRogueMenu",
    ["Shaman"]       = "CloseShamanMenu",
    ["Warlock"]      = "CloseWarlockMenu",
    ["Warrior"]      = "CloseWarriorMenu",
}

function PBM.CloseAllClassMenus()
    for _, fn in ipairs(CLASS_MENU_CLOSE) do
        if PBM[fn] then PBM[fn]() end
    end
end

-- Class menu dispatch table
local CLASS_MENU_OPEN = {
    ["Death Knight"] = "OpenDKMenu",
    ["Druid"]        = "OpenDruidMenu",
    ["Hunter"]       = "OpenHunterMenu",
    ["Mage"]         = "OpenMageMenu",
    ["Paladin"]      = "OpenPaladinMenu",
    ["Priest"]       = "OpenPriestMenu",
    ["Rogue"]        = "OpenRogueMenu",
    ["Shaman"]       = "OpenShamanMenu",
    ["Warlock"]      = "OpenWarlockMenu",
    ["Warrior"]      = "OpenWarriorMenu",
}

local CLASS_MENU_FRAMES = {
    ["Death Knight"] = "LichborneDKMenu",
    ["Druid"]        = "LichborneDruidMenu",
    ["Hunter"]       = "LichborneHunterMenu",
    ["Mage"]         = "LichborneMageMenu",
    ["Paladin"]      = "LichbornePaladinMenu",
    ["Priest"]       = "LichbornePriestMenu",
    ["Rogue"]        = "LichborneRogueMenu",
    ["Shaman"]       = "LichborneShamanMenu",
    ["Warlock"]      = "LichborneWarlockMenu",
    ["Warrior"]      = "LichborneWarriorMenu",
}

function PBM.OpenNameMenu(row)
    -- Route to class-specific overlay panel. Rows without a recognized
    -- class (unscanned/empty) simply have no menu.
    local _rd = row.dbIndex and LichborneTrackerDB.rows[row.dbIndex]
    if not _rd then return end
    if not _rd.name or _rd.name == "" then
        if LichborneAddStatus then
            LichborneAddStatus:SetText("|cffffaa44Empty slot. Sync the roster or add a target/group first.|r")
        end
        return
    end
    local opener = CLASS_MENU_OPEN[_rd.cls]
    if not (opener and PBM[opener]) then return end

    local frameName = CLASS_MENU_FRAMES[_rd.cls]
    local menuFrame = frameName and _G[frameName]
    -- Toggle off: same menu + same row already open
    if menuFrame and menuFrame:IsShown() and menuFrame.sourceRow == row then
        PBM.CloseAllClassMenus()
        return
    end
    -- Close only OTHER class menus — don't hide+reshow this one
    for cls, closeFn in pairs(CLASS_MENU_CLOSE_MAP) do
        if cls ~= _rd.cls and PBM[closeFn] then
            PBM[closeFn]()
        end
    end
    PBM[opener](row)
    menuFrame = frameName and _G[frameName]
    if menuFrame then PBM.ShowIgnoredSpellTable(menuFrame) end
end

function PBM.BuildRows(parent, yStart)
    if #PBM.State.rowFrames > 0 then return end  -- already built

    for i = 1, PBM.MAX_ROWS do
        local row = CreateFrame("Frame", "LichborneRow"..i, parent)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, yStart - (i-1)*PBM.ROW_HEIGHT)
        row:SetSize(1086, PBM.ROW_HEIGHT)

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(row)
        bg:SetTexture(0.05, 0.07, 0.13, 1)
        row.bg = bg

        -- Hover
        local hov = row:CreateTexture(nil, "OVERLAY")
        hov:SetAllPoints(row)
        hov:SetTexture(0, 0, 0, 0)
        row.hov = hov

        -- Drop-target highlight (shown while dragging another row over this one)
        local dropHi = row:CreateTexture(nil, "OVERLAY")
        dropHi:SetAllPoints(row)
        dropHi:SetTexture(0, 0, 0, 0)
        row.dropHi = dropHi

        row:EnableMouse(true)
        row:SetScript("OnEnter", function()
            if not classDragSource then row.hov:SetTexture(0.78, 0.61, 0.23, 0.12) end
        end)
        row:SetScript("OnLeave", function()
            if not classDragSource then row.hov:SetTexture(0, 0, 0, 0) end
        end)

        -- Row number / level label
        local nl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nl:SetPoint("LEFT", row, "LEFT", 0, 0)
        nl:SetWidth(18); nl:SetJustifyH("CENTER")
        nl:SetTextColor(0.4, 0.5, 0.6)
        row.numLbl = nl

        -- Drag handle (over the reserved drag column) — drag to reorder the list
        local dragBtn = CreateFrame("Button", nil, row)
        dragBtn:SetPoint("LEFT", row, "LEFT", PBM.DRAG_OFF, 0); dragBtn:SetSize(PBM.COL_DRAG_W, PBM.ROW_HEIGHT)
        dragBtn:SetFrameLevel(row:GetFrameLevel() + 5)
        local dragTex = dragBtn:CreateTexture(nil, "ARTWORK")
        dragTex:SetAllPoints(dragBtn)
        dragTex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        dragTex:SetVertexColor(0.3, 0.4, 0.6, 0)  -- invisible until hovered/dragged
        row.dragTex = dragTex
        dragBtn:SetScript("OnEnter", function()
            if not classDragSource and row.dbIndex then
                local d = LichborneTrackerDB.rows[row.dbIndex]
                if d and d.name and d.name ~= "" then
                    dragTex:SetVertexColor(0.9, 0.7, 0.1, 1.0)
                    GameTooltip:SetOwner(dragBtn, "ANCHOR_RIGHT")
                    GameTooltip:AddLine("Drag to reorder", 1, 1, 1)
                    GameTooltip:Show()
                end
            end
        end)
        dragBtn:SetScript("OnLeave", function()
            if not classDragSource then dragTex:SetVertexColor(0.3, 0.4, 0.6, 0) end
            GameTooltip:Hide()
        end)
        dragBtn:SetScript("OnMouseDown", function(_, mouseButton)
            if mouseButton == "LeftButton" and row.dbIndex then
                local d = LichborneTrackerDB.rows[row.dbIndex]
                if d and d.name and d.name ~= "" then
                    classDragSource = row
                    classMouseHeld = true
                    dragTex:SetVertexColor(0.9, 0.7, 0.1, 1.0)
                    row.hov:SetTexture(0.9, 0.7, 0.1, 0.12)
                end
            end
        end)
        dragBtn:SetScript("OnMouseUp", function() classMouseHeld = false end)
        row.dragBtn = dragBtn

        -- Spec icon (click to set spec manually)
        local specBtn = CreateFrame("Button", "LichborneRow"..i.."SpecBtn", row)
        specBtn:SetPoint("LEFT", row, "LEFT", PBM.SPEC_OFF, 0)
        specBtn:SetSize(PBM.COL_SPEC_W - 2, PBM.ROW_HEIGHT - 2)
        specBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        local specIcon = specBtn:CreateTexture(nil, "ARTWORK")
        specIcon:SetAllPoints(specBtn)
        specIcon:SetTexture(0, 0, 0, 0)
        specBtn.icon = specIcon
        row.specIcon = specIcon
        row.specBtn = specBtn
        specBtn:SetScript("OnEnter", function()
            if row.dbIndex and LichborneTrackerDB.rows[row.dbIndex] then
                local spec = LichborneTrackerDB.rows[row.dbIndex].spec or ""
                GameTooltip:SetOwner(specBtn, "ANCHOR_RIGHT")
                GameTooltip:AddLine(spec ~= "" and spec or "No spec set", 1, 1, 1)
                GameTooltip:Show()
            end
        end)
        specBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Name box (display only — editing disabled, click opens dropdown)
        local nb = CreateFrame("EditBox", "LichborneRow"..i.."Name", row)
        nb:SetPoint("LEFT", row, "LEFT", PBM.NAME_OFF, 0)
        nb:SetSize(PBM.COL_NAME_W - 44, PBM.ROW_HEIGHT - 4)
        nb:SetAutoFocus(false); nb:SetMaxLetters(32)
        nb:SetFont("Fonts\\FRIZQT__.TTF", 11)
        nb:SetTextColor(0.90, 0.95, 1.0)
        nb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
        nb:SetBackdropColor(0.05, 0.07, 0.14, 0.8)
        nb:SetBackdropBorderColor(0.15, 0.22, 0.38, 0.7)
        nb:EnableMouse(false)  -- non-interactive; text still displays
        row.nameBox = nb

        -- Invisible overlay button captures clicks on the name area
        local nameBtn = CreateFrame("Button", nil, row)
        nameBtn:SetPoint("LEFT", row, "LEFT", PBM.NAME_OFF, 0)
        nameBtn:SetSize(PBM.COL_NAME_W - 44, PBM.ROW_HEIGHT)
        nameBtn:SetFrameLevel(nb:GetFrameLevel() + 2)
        nameBtn:SetScript("OnClick", function()
            if not row.dbIndex then return end
            if PBM.State.LBFilter and PBM.State.LBFilter.classCharSheet == false then return end
            PBM.OpenNameMenu(row)
        end)
        nameBtn:SetScript("OnEnter", function() row.hov:SetTexture(0.78, 0.61, 0.23, 0.12) end)
        nameBtn:SetScript("OnLeave", function() row.hov:SetTexture(0, 0, 0, 0) end)
        row.nameBtn = nameBtn

        -- iLvl box
        local gsb = CreateFrame("EditBox", "LichborneRow"..i.."GS", row)
        gsb:SetPoint("LEFT", row, "LEFT", PBM.GS_OFF, 0)
        gsb:SetSize(PBM.COL_GS_W - 2, PBM.ROW_HEIGHT - 4)
        gsb:SetAutoFocus(false); gsb:SetMaxLetters(5); gsb:EnableKeyboard(false)
        gsb:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        gsb:SetTextColor(0.831, 0.686, 0.216); gsb:SetJustifyH("CENTER")
        gsb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        gsb:SetBackdropColor(0.05, 0.07, 0.14, 1)
        gsb:SetBackdropBorderColor(0.12, 0.18, 0.30, 0.8)
        gsb:SetScript("OnEditFocusGained", function(self) self:ClearFocus() end)
        row.gsBox = gsb
        gsb:SetScript("OnEnter", function() row.hov:SetTexture(0.78, 0.61, 0.23, 0.12) end)
        gsb:SetScript("OnLeave", function()
            if GetMouseFocus() ~= row then row.hov:SetTexture(0, 0, 0, 0) end
        end)

        -- GS box
        local realGsb = CreateFrame("EditBox", "LichborneRow"..i.."RealGS", row)
        realGsb:SetPoint("LEFT", row, "LEFT", PBM.REALGS_OFF, 0)
        realGsb:SetSize(PBM.COL_GS_W - 2, PBM.ROW_HEIGHT - 4)
        realGsb:SetAutoFocus(false); realGsb:SetMaxLetters(5); realGsb:EnableKeyboard(false)
        realGsb:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        realGsb:SetTextColor(0.831, 0.686, 0.216); realGsb:SetJustifyH("CENTER")
        realGsb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        realGsb:SetBackdropColor(0.05, 0.07, 0.14, 1)
        realGsb:SetBackdropBorderColor(0.12, 0.18, 0.30, 0.8)
        realGsb:SetScript("OnEditFocusGained", function(self) self:ClearFocus() end)
        row.realGsBox = realGsb
        realGsb:SetScript("OnEnter", function() row.hov:SetTexture(0.78, 0.61, 0.23, 0.12) end)
        realGsb:SetScript("OnLeave", function()
            if GetMouseFocus() ~= row then row.hov:SetTexture(0, 0, 0, 0) end
        end)

        -- Gear boxes (ilvl)
        row.gearBoxes = {}
        for g = 1, PBM.GEAR_SLOTS do
            local gx = PBM.GEAR_OFF + (g-1)*PBM.COL_GEAR_W
            local gb = CreateFrame("EditBox", "LichborneRow"..i.."Gear"..g, row)
            gb:SetPoint("LEFT", row, "LEFT", gx, 0)
            gb:SetSize(PBM.COL_GEAR_W - 2, PBM.ROW_HEIGHT - 2)
            gb:SetAutoFocus(false); gb:SetMaxLetters(3); gb:SetNumeric(true); gb:EnableKeyboard(false)
            gb:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            gb:SetTextColor(1,1,1); gb:SetJustifyH("CENTER")
            gb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
            gb:SetBackdropColor(0.05, 0.07, 0.14, 1)
            gb:SetBackdropBorderColor(0.12, 0.18, 0.30, 0.8)
            gb:SetScript("OnEditFocusGained", function(self) self:ClearFocus() end)
            row.gearBoxes[g] = gb
            -- Hover glow overlay frame
            local glow = CreateFrame("Frame", nil, row)
            glow:SetAllPoints(gb)
            glow:SetFrameLevel(gb:GetFrameLevel() + 1)
            glow:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=6,insets={left=1,right=1,top=1,bottom=1}})
            glow:SetBackdropColor(0,0,0,0)
            glow:SetBackdropBorderColor(0,0,0,0)
            glow:EnableMouse(false)
            gb.glow = glow
            gb:SetScript("OnEnter", function()
                row.hov:SetTexture(0.78, 0.61, 0.23, 0.12)
                glow:SetBackdropBorderColor(0.3, 0.7, 1.0, 1.0)
                glow:SetBackdropColor(0.05, 0.15, 0.35, 0.4)
            end)
            gb:SetScript("OnLeave", function()
                local f = GetMouseFocus()
                if f ~= row then row.hov:SetTexture(0, 0, 0, 0) end
                glow:SetBackdropBorderColor(0, 0, 0, 0)
                glow:SetBackdropColor(0, 0, 0, 0)
            end)
        end

        -- Add to Raid button (green +)
        local addRaidX = PBM.GEAR_OFF + PBM.GEAR_SLOTS * PBM.COL_GEAR_W + 3
        local arb = CreateFrame("Button", "LichborneRow"..i.."AddRaid", row)
        arb:SetPoint("RIGHT", row, "RIGHT", -36, 0)
        arb:SetSize(16, PBM.ROW_HEIGHT - 2)
        arb:SetNormalFontObject("GameFontNormalSmall")
        arb:SetText("|cff44ff44+|r")
        arb:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        arb:SetScript("OnEnter", function()
            GameTooltip:SetOwner(arb, "ANCHOR_RIGHT")
            GameTooltip:AddLine("|cff44ff44+ Add to Raid|r", 1, 1, 1)
            GameTooltip:AddLine("Adds to the Raid tab.", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cff44ff44Left-click to add to raid.|r", 1, 1, 1)
            GameTooltip:AddLine("|cffff2020Right-click to remove.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        arb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        arb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.addRaidBtn = arb

        -- Add to Group button (cyan >) - invite to current party
        local agX = addRaidX + 20
        local agb = CreateFrame("Button", "LichborneRow"..i.."AddGroup", row)
        agb:SetPoint("RIGHT", row, "RIGHT", -20, 0)
        agb:SetSize(16, PBM.ROW_HEIGHT - 2)
        agb:SetNormalFontObject("GameFontNormalSmall")
        agb:SetText("|cff44eeff>|r")
        agb:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        agb:SetScript("OnEnter", function()
            GameTooltip:SetOwner(agb, "ANCHOR_RIGHT")
            GameTooltip:AddLine("|cff44eeff> Invite to Group|r", 1, 1, 1)
            GameTooltip:AddLine("|cff44ff44Left-click to invite to group.|r", 1, 1, 1)
            GameTooltip:AddLine("|cffff2020Right-click to remove.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        agb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row.addGroupBtn = agb

        -- Delete button (shifted right)
        local delX = agX + 20
        local db = CreateFrame("Button", "LichborneRow"..i.."Del", row)
        db:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        db:SetSize(18, PBM.ROW_HEIGHT - 2)
        db:SetNormalFontObject("GameFontNormalSmall")
        db:SetText("|cffaa2222x|r")
        db:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        db:SetScript("OnEnter", function()
            GameTooltip:SetOwner(db, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Remove Character", 1, 0.3, 0.3)
            GameTooltip:AddLine("Removes from tracker.", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        db:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row.delBtn = db

        -- Needs cell in class tab (beside GS, before gear slots)
        local classRow = row
        row.needsCell = PBM.MakeNeedsCell(row, PBM.NEEDS_OFF, PBM.ROW_HEIGHT, function()
            if classRow.dbIndex and LichborneTrackerDB.rows[classRow.dbIndex] then
                return LichborneTrackerDB.rows[classRow.dbIndex].name or ""
            end
            return ""
        end, row.hov, PBM.COL_NEEDS_W)

        -- Prof cell (same position as needsCell; shown only when Druid tab is active)
        row.profCell = PBM.MakeProfCell(row, PBM.NEEDS_OFF, PBM.ROW_HEIGHT, function()
            if classRow.dbIndex and LichborneTrackerDB.rows[classRow.dbIndex] then
                return LichborneTrackerDB.rows[classRow.dbIndex].name or ""
            end
            return ""
        end, row.hov, PBM.COL_NEEDS_W)
        row.profCell:Hide()

        -- Hook all child elements to propagate row highlight
        local hov = row.hov
        PBM.HookRowHighlight(specBtn, row, hov)
        PBM.HookRowHighlight(arb, row, hov)
        PBM.HookRowHighlight(agb, row, hov)
        PBM.HookRowHighlight(db, row, hov)

        -- Divider
        local line = row:CreateTexture(nil, "OVERLAY")
        line:SetHeight(1); line:SetWidth(1010)
        line:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        line:SetTexture(0.12, 0.20, 0.35, 0.4)

        PBM.State.rowFrames[i] = row
    end

    -- Backup release detector for drag-reorder: the handle is a Button so it
    -- captures the press and fires OnMouseUp, but also clear the flag if the
    -- press is released anywhere over the main window.
    if LichborneTrackerFrame then
        LichborneTrackerFrame:HookScript("OnMouseUp", function()
            if classDragSource then classMouseHeld = false end
        end)
    end
end

-- ── Toggle needs vs prof cells for all rows ──────────────────
function PBM.SetNeedsCellMode(mode)
    for _, row in ipairs(PBM.State.rowFrames) do
        if row.needsCell then
            if mode == "prof" then row.needsCell:Hide() else row.needsCell:Show() end
        end
        if row.profCell then
            if mode == "prof" then row.profCell:Show() else row.profCell:Hide() end
        end
    end
    if PBM.State.needsProfHdrLabel then
        PBM.State.needsProfHdrLabel:SetText(
            mode == "prof" and "|cffd4af37Prof.|r" or "|cffd4af37Need|r")
    end
end

-- ── Populate rows with current class data ────────────────────
function PBM.RefreshRows()
    if PBM.State.activeTab == "Raid" then
        if LichborneRaidFrame then PBM.RefreshRaidRows() end
        return
    end
    if PBM.State.activeTab == "Overview" then
        if LichborneOverviewFrame then PBM.RefreshOverviewRows() end
        return
    end
    if PBM.State.activeTab == "Group" then
        PBM.OpenGroupView()
        return
    end
    if PBM.State.activeTab == "Settings" then return end
    PBM.SetNeedsCellMode("prof")
    PBM.EnsureClass(PBM.State.activeTab)
    local indices = PBM.GetClassRows(PBM.State.activeTab)
    local offset = PBM.State.classScroll[PBM.State.activeTab] or 0
    local c = PBM.CLASS_COLORS[PBM.State.activeTab]


    for i = 1, PBM.MAX_ROWS do
        local row = PBM.State.rowFrames[i]
        if not row then break end
        local di = indices[i]

        if di then
            local data = LichborneTrackerDB.rows[di]
            row.dbIndex = di
            row:Show()

            -- No background tint - clean dark rows
            row.bg:SetTexture(0.05, 0.07, 0.13, 1)
            -- Name box colored text to match class
            if c then
                row.nameBox:SetTextColor(c.r, c.g, c.b)
            else
                row.nameBox:SetTextColor(0.90, 0.95, 1.0)
            end
            row.nameBox:SetBackdropColor(0.05, 0.07, 0.14, 0.8)
            row.nameBox:SetBackdropBorderColor(0.15, 0.22, 0.38, 0.7)

            -- Row number / level
            if row.numLbl then
                if PBM.State.LBFilter.showIP then
                    local ipVal = (data.name and data.name ~= "") and LichborneTrackerDB.ipData and LichborneTrackerDB.ipData[data.name:lower()]
                    if ipVal then
                        row.numLbl:SetText(tostring(ipVal))
                        row.numLbl:SetTextColor(0.83, 0.69, 0.22)
                    else
                        row.numLbl:SetText("")
                    end
                elseif PBM.State.LBFilter.showLevel then
                    if (data.level or 0) > 0 then
                        row.numLbl:SetText(tostring(data.level))
                        row.numLbl:SetTextColor(0.83, 0.69, 0.22)
                    else
                        row.numLbl:SetText("")
                    end
                else
                    row.numLbl:SetText(tostring(i))
                    row.numLbl:SetTextColor(0.4, 0.5, 0.6)
                end
            end

            -- Spec icon
            if row.specIcon then
                local spec = data.spec or ""
                local icon = spec ~= "" and PBM.SPEC_ICONS[spec] or nil
                if icon then
                    row.specIcon:SetTexture(icon)
                    row.specIcon:SetAlpha(1.0)
                else
                    row.specIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    row.specIcon:SetAlpha(data.name and data.name ~= "" and 0.25 or 0)
                end
            end

            -- Name
            row.nameBox:SetText(data.name or "")

            -- iLvl (read-only)
            local gsval = data.gs or 0
            row.gsBox:SetText(gsval > 0 and tostring(gsval) or "")

            -- GS (read-only)
            local realGsVal = data.realGs or 0
            row.realGsBox:SetText(realGsVal > 0 and tostring(realGsVal) or "")

            -- Gear (ilvl)
            for g = 1, PBM.GEAR_SLOTS do
                local gb = row.gearBoxes[g]
                local val = data.ilvl[g] or 0
                local link = data.ilvlLink and data.ilvlLink[g]
                -- Show 0 when item exists but has iLvl=0 (PvP trinket, relic, etc.)
                -- Show blank only when the slot is truly empty (no link)
                gb:SetText((val > 0 or (link and link ~= "")) and tostring(val) or "")
                -- Apply item quality color; also request cache for uncached links so
                -- GET_ITEM_INFO_RECEIVED fires and re-colors once the server responds.
                local qc = PBM.GetItemQualityColor(link)
                if qc then
                    gb:SetTextColor(qc.r, qc.g, qc.b)
                else
                    if link and link ~= "" then GetItemInfo(link) end  -- queue cache request
                    gb:SetTextColor(1, 1, 1)
                end
                gb:SetScript("OnEnter", function()
                    row.hov:SetTexture(0.78, 0.61, 0.23, 0.12)
                    if gb.glow then
                        gb.glow:SetBackdropBorderColor(0.3, 0.7, 1.0, 1.0)
                        gb.glow:SetBackdropColor(0.05, 0.15, 0.35, 0.4)
                    end
                    local rowData = LichborneTrackerDB.rows[di]
                    local link = rowData and rowData.ilvlLink and rowData.ilvlLink[g]
                    if link and link ~= "" then
                        -- Request cache if not already loaded (triggers GET_ITEM_INFO_RECEIVED)
                        GetItemInfo(link)
                        local anchor = (i <= 11) and "ANCHOR_BOTTOM" or "ANCHOR_TOP"
                        GameTooltip:SetOwner(gb, anchor)
                        local ok = pcall(function() GameTooltip:SetHyperlink(link) end)
                        if ok then
                            GameTooltip:Show()
                        else
                            GameTooltip:Hide()
                        end
                    end
                end)
                gb:SetScript("OnLeave", function()
                    if GetMouseFocus() ~= row then row.hov:SetTexture(0, 0, 0, 0) end
                    if gb.glow then
                        gb.glow:SetBackdropBorderColor(0, 0, 0, 0)
                        gb.glow:SetBackdropColor(0, 0, 0, 0)
                    end
                    GameTooltip:Hide()
                end)
            end

            -- Add to Raid
            if row.addRaidBtn then
                -- Color + orange (T1) when in raid, green when not
                if PBM.IsInActiveRaid(data.name) then
                    row.addRaidBtn:SetText("|cffb25b00+|r")
                else
                    row.addRaidBtn:SetText("|cff44ff44+|r")
                end
                row.addRaidBtn:SetScript("OnClick", function(self, btn)
                    local srcData = LichborneTrackerDB.rows[di]
                    if not srcData or not srcData.name or srcData.name == "" then return end
                    local c = PBM.CLASS_COLORS[srcData.cls]
                    local hex = c and string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255)) or "|cffffffff"
                    if btn == "RightButton" then
                        -- Remove from raid
                        local roster, _ = PBM.GetCurrentRoster()
                        for ri = 1, PBM.MAX_RAID_SLOTS do
                            if roster[ri] and roster[ri].name and roster[ri].name:lower() == srcData.name:lower() then
                                local slot = ri
                                roster[ri] = {name="", cls="", spec="", gs=0, realGs=0, role="", notes=""}
                                row.addRaidBtn:SetText("|cff44ff44+|r")
                                if LichborneAddStatus then
                                    LichborneAddStatus:SetText(hex..srcData.name.."|r removed from raid slot "..slot..".")
                                end
                                if LichborneRaidFrame then PBM.RefreshRaidRows() end
                                PBM.RefreshRows()
                                return
                            end
                        end
                        return
                    end
                    -- Left click: add to raid
                    local roster, maxSlots = PBM.GetCurrentRoster()
                    -- Check for duplicate
                    for ri = 1, maxSlots do
                        local rr = roster[ri]
                        if rr.name and rr.name:lower() == srcData.name:lower() then
                            local c2 = PBM.CLASS_COLORS[srcData.cls]
                            local hex2 = c2 and string.format("|cff%02x%02x%02x", math.floor(c2.r*255), math.floor(c2.g*255), math.floor(c2.b*255)) or "|cffffffff"
                            if LichborneAddStatus then
                                LichborneAddStatus:SetText(hex2..srcData.name.."|r is already in the Raid.")
                            end
                            LichborneOutput("|cffC69B3APBM:|r "..hex2..srcData.name.."|r is already in the Raid.", 1, 0.5, 0.5)
                            return
                        end
                    end
                    -- Find first empty raid slot within size limit
                    local slot = nil
                    for ri = 1, maxSlots do
                        local rr = roster[ri]
                        if not rr.name or rr.name == "" then
                            slot = ri; break
                        end
                    end
                    if not slot then
                        local raidLabel = LichborneTrackerDB.raidName or "Raid"
                        LichborneOutput("|cffC69B3APBM:|r "..raidLabel.." is full ("..maxSlots.."/"..maxSlots..").", 1, 0.5, 0.5)
                        return
                    end
                    roster[slot] = {
                        name   = srcData.name,
                        cls    = srcData.cls,
                        spec   = srcData.spec or "",
                        gs     = srcData.gs or 0,
                        realGs = srcData.realGs or 0,
                        role   = "",
                        notes  = "",
                    }
                    LichborneOutput("|cffC69B3APBM:|r Added "..hex..srcData.name.."|r to Raid slot "..slot..".", 1, 0.85, 0)
                    if LichborneAddStatus then
                        LichborneAddStatus:SetText(hex..srcData.name.."|r added to raid slot "..slot..".")
                    end
                    -- Color + orange after successful add
                    row.addRaidBtn:SetText("|cffb25b00+|r")
                    if LichborneRaidFrame then PBM.RefreshRaidRows() end
                end)
            end

            -- Invite to Group
            if row.addGroupBtn then
                row.addGroupBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                row.addGroupBtn:SetScript("OnClick", function(self, btn)
                    local srcData = LichborneTrackerDB.rows[di]
                    if not srcData or not srcData.name or srcData.name == "" then return end
                    local c = PBM.CLASS_COLORS[srcData.cls]
                    local hex = c and string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255)) or "|cffffffff"
                    if btn == "RightButton" then
                        UninviteUnit(srcData.name)
                        SendChatMessage(".playerbots bot remove "..srcData.name, "SAY")
                        LichborneOutput("|cffC69B3APBM:|r Removed "..hex..srcData.name.."|r from bots.", 1, 0.85, 0)
                        return
                    end
                    SendChatMessage(".playerbots bot add "..srcData.name, "SAY")
                    LichborneOutput("|cffC69B3APBM:|r Inviting "..hex..srcData.name.."|r to group...", 1, 0.85, 0)
                    if LichborneAddStatus then
                        LichborneAddStatus:SetText("Invited "..hex..srcData.name.."|r to group.")
                    end
                end)
            end

            -- Delete. Empty-name rows can still contain stale spec/gear data in
            -- SavedVariables, so remove those directly by DB index instead of
            -- making them impossible to clear.
            row.delBtn:SetScript("OnClick", function()
                local srcData = LichborneTrackerDB.rows[di]
                if not srcData then return end
                if srcData.name and srcData.name ~= "" then
                    PBM.RemoveCharacterReferences(srcData.name)
                else
                    table.remove(LichborneTrackerDB.rows, di)
                end
                PBM.RefreshRows()
                if PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames > 0 then PBM.RefreshOverviewRows() end
                if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
            end)

            -- Needs cell
            if row.needsCell then
                PBM.RefreshNeedsCell(row.needsCell, data.name or "")
            end
            if row.profCell then
                PBM.RefreshProfCell(row.profCell, data.name or "")
            end
        else
            -- Show as blank row (slot filtered out or beyond DB entries)
            if row.needsCell then PBM.RefreshNeedsCell(row.needsCell, "") end
            if row.profCell then PBM.RefreshProfCell(row.profCell, "") end
            row.dbIndex = nil
            row.bg:SetTexture(0.05, 0.07, 0.13, 1)
            if row.numLbl then row.numLbl:SetText("") end
            row.nameBox:SetText("")
            row.nameBox:SetScript("OnTextChanged", nil)
            if row.specIcon then row.specIcon:SetAlpha(0) end
            row.gsBox:SetText("")
            row.realGsBox:SetText("")
            for g = 1, PBM.GEAR_SLOTS do
                local gb = row.gearBoxes[g]
                gb:SetScript("OnEnter", nil)
                gb:SetScript("OnLeave", nil)
                if gb.glow then
                    gb.glow:SetBackdropBorderColor(0, 0, 0, 0)
                    gb.glow:SetBackdropColor(0, 0, 0, 0)
                end
                gb:SetText("")
                gb:SetTextColor(1, 1, 1)
            end
            if row.addRaidBtn then
                row.addRaidBtn:SetText("|cff44ff44+|r")
                row.addRaidBtn:SetScript("OnClick", nil)
            end
            row.delBtn:SetScript("OnClick", nil)
            row.hov:SetTexture(0, 0, 0, 0)
            row:Show()
        end
    end
    PBM.UpdateSummary()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- GetClassAvgIlvl
-- ─────────────────────────────────────────────────────────────────────────────
function PBM.GetClassAvgIlvl(cls)
    if cls == "Raid" then return 0 end
    local total, namedRows = 0, 0
    for _, row in ipairs(LichborneTrackerDB.rows) do
        if row.cls == cls and row.name and row.name ~= "" then
            namedRows = namedRows + 1
            total = total + (row.gs or 0)  -- row.gs stores the iLvl column value
        end
    end
    if namedRows == 0 then return 0 end
    return math.floor(total / namedRows + 0.5)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- GetClassAvgGS
-- ─────────────────────────────────────────────────────────────────────────────
function PBM.GetClassAvgGS(cls)
    if cls == "Raid" then return 0 end
    local total, namedRows = 0, 0
    for _, row in ipairs(LichborneTrackerDB.rows) do
        if row.cls == cls and row.name and row.name ~= "" then
            namedRows = namedRows + 1
            total = total + (row.realGs or 0)  -- row.realGs stores actual GS (1000s)
        end
    end
    if namedRows == 0 then return 0 end
    return math.floor(total / namedRows + 0.5)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Ignored Spell List table (bottom-left of content border)
-- ─────────────────────────────────────────────────────────────────────────────
local NUM_IGNORE_ROWS = 5

function PBM.ShowIgnoredSpellTable(menuFrame)
    local f = PBM.State.ignoredSpellFrame
    if not f then return end
    f:SetParent(menuFrame)
    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", menuFrame, "BOTTOMLEFT", 15, 8)
    f:Show()
    if menuFrame._lastMultibotBtn then
        -- Hide the Misc label and stack food/loot/gather vertically with the talent bar
        if menuFrame.miscSpecBox then menuFrame.miscSpecBox:Hide() end
        local anchor = menuFrame._lastMultibotBtn
        for _, key in ipairs({"treeFoodBtn", "treeLootBtn", "treeGatherBtn"}) do
            local btn = menuFrame[key]
            if btn then
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
                anchor = btn
            end
        end
    end
    -- Clear ISL if opening a different bot's menu
    local botName = menuFrame.botName or ""
    if botName ~= (PBM.State.ignoredSpellChar or "") then
        PBM.State.ignoredSpellChar   = nil
        PBM.State.ignoredSpellScroll = 0
    end
    PBM.RefreshIgnoredSpellTable()
end

function PBM.BuildIgnoredSpellTable()
    if PBM.State.ignoredSpellFrame then return end

    local f = CreateFrame("Frame", "LichborneIgnoreSpellFrame", UIParent)
    f:SetSize(115, 115)
    f:Hide()
    f:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = {left=2, right=2, top=2, bottom=2}
    })
    f:SetBackdropColor(0, 0, 0, 0)
    f:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)

    local hdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOP", f, "TOP", 0, -6)
    hdr:SetText("|cffd4af37Ignored Spell List|r")

    for i = 1, NUM_IGNORE_ROWS do
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -20 - (i - 1) * 18)
        fs:SetWidth(99)
        fs:SetJustifyH("LEFT")
        fs:SetTextColor(0.9, 0.9, 0.9)
        fs:SetText("")
        PBM.State.ignoredSpellRows[i] = fs
    end

    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(self, delta)
        local char   = PBM.State.ignoredSpellChar
        local spells = (char and PBM.State.ignoredSpells[char]) or {}
        local offset = PBM.State.ignoredSpellScroll or 0
        local maxOff = math.max(0, #spells - NUM_IGNORE_ROWS)
        PBM.State.ignoredSpellScroll = math.max(0, math.min(offset - delta, maxOff))
        PBM.RefreshIgnoredSpellTable()
    end)

    PBM.State.ignoredSpellFrame = f
end

function PBM.RefreshIgnoredSpellTable()
    if not PBM.State.ignoredSpellRows or #PBM.State.ignoredSpellRows == 0 then return end
    local char   = PBM.State.ignoredSpellChar
    local spells = (char and PBM.State.ignoredSpells[char]) or {}
    local offset = PBM.State.ignoredSpellScroll or 0
    local maxOff = math.max(0, #spells - NUM_IGNORE_ROWS)
    offset = math.min(math.max(0, offset), maxOff)
    PBM.State.ignoredSpellScroll = offset
    for i = 1, NUM_IGNORE_ROWS do
        local spell = spells[offset + i]
        PBM.State.ignoredSpellRows[i]:SetText(spell or "")
    end
end
