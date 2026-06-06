-- ============================================================
--  LBT_Sort.lua  |  All sorting logic — class, raid, overview sort state and headers
-- ============================================================
PBM = PBM or {}
PBM.State = PBM.State or {}

-- ── Shared state ───────────────────────────────────────────────
PBM.State.classSortKey  = {}
PBM.State.classSortAsc  = {}
PBM.State.classSortHdrs = {}
PBM.State.classScroll   = {}
PBM.State.allSortMenus  = {}
PBM.State.activeInviteFrame = nil

PBM.State.raidSortKey     = nil
PBM.State.raidSortAsc     = true
PBM.State.raidSortPending = false
PBM.State.raidSortHdrs    = {}

PBM.State.allSortKey  = nil
PBM.State.allSortAsc  = true
PBM.State.allSortHdrs = {}

-- ── Shared state declared in LBT_ClassTabs.lua (forward refs) ─
-- PBM.State.activeTab, PBM.State.tabButtons, PBM.State.rowFrames

-- ── Class rows helpers ─────────────────────────────────────────
function PBM.GetAllClassRows(cls)
    -- Returns ALL row indices for a class regardless of page (for add/search ops)
    local out = {}
    if cls == "Raid" or cls == "Overview" then return out end
    for i, row in ipairs(LichborneTrackerDB.rows) do
        if row.cls == cls then out[#out+1] = i end
    end
    return out
end

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

function PBM.GetClassRows(cls)
    local out = {}
    if cls == "Raid" or cls == "Overview" then return out end
    local offset = PBM.State.classScroll[cls] or 0
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
    local filledCount = 0
    for _, ai in ipairs(allIdx) do
        if LichborneTrackerDB.rows[ai].name ~= "" then filledCount = filledCount + 1 end
    end
    local maxOffset = math.max(0, filledCount - PBM.MAX_ROWS)
    offset = math.min(math.max(0, offset), maxOffset)
    PBM.State.classScroll[cls] = offset
    local total = #allIdx
    for i = offset + 1, math.min(offset + PBM.MAX_ROWS, total) do
        out[#out+1] = allIdx[i]
    end
    return out
end

-- ── Sort menus helper ──────────────────────────────────────────
function PBM.CloseAllSortMenus()
    for _, m in ipairs(PBM.State.allSortMenus) do m:Hide() end
end

-- ── Invite button state ────────────────────────────────────────
function PBM.UpdateInviteButtons()
    -- Both invite buttons always show in their normal state
    if LichborneInviteRaidBtn then
        LichborneInviteRaidBtn:Show()
        LichborneInviteRaidBtn:SetBackdropColor(0.30, 0.15, 0.01, 1)
        if LichborneInviteRaidBtn.lbl then
            LichborneInviteRaidBtn.lbl:SetText("|cffd4af37Invite Raid|r")
        end
    end
    if _G["LichborneInviteGroupBtn"] then
        local grpBtn = _G["LichborneInviteGroupBtn"]
        grpBtn:Show()
        grpBtn:SetBackdropColor(0.035, 0.14, 0.245, 1)
        if grpBtn.lbl then grpBtn.lbl:SetText("|cffd4af37Invite Group|r") end
    end
    -- Stop Invite overlay: covers both invite buttons when an invite is active
    if _G["LichborneStopInviteBtn"] then
        if PBM.State.activeInviteFrame then
            _G["LichborneStopInviteBtn"]:Show()
        else
            _G["LichborneStopInviteBtn"]:Hide()
        end
    end
end

-- ── Tab switching ──────────────────────────────────────────────
function PBM.UpdateTabs()
    if PBM.OnTopTabChanged then PBM.OnTopTabChanged() end
    if LichborneSpecMenu then LichborneSpecMenu:Hide() end
    PBM.CloseAllSortMenus()
    if _G["LichborneOverviewGroupMenu"] then _G["LichborneOverviewGroupMenu"]:Hide() end
    -- Close raid tab dropdowns when switching away
    if _G["LichborneRaidTierMenu"] then _G["LichborneRaidTierMenu"]:Hide() end
    if _G["LichborneRaidRaidMenu"] then _G["LichborneRaidRaidMenu"]:Hide() end
    if _G["LichborneRaidGroupMenu"] then _G["LichborneRaidGroupMenu"]:Hide() end
    -- Close all class overlays when switching tabs
    PBM.CloseAllClassMenus()
    for cls, btn in pairs(PBM.State.tabButtons) do
        local c = PBM.CLASS_COLORS[cls]
        if cls == PBM.State.activeTab then
            btn:SetAlpha(1.0)
            if c then
                btn.bg:SetTexture(c.r*0.45, c.g*0.45, c.b*0.45, 1)
                btn.bottomLine:SetTexture(c.r, c.g, c.b, 1)
            elseif cls == "Raid" then
                btn.bg:SetTexture(0.42, 0.22, 0.00, 1)
                btn.bottomLine:SetTexture(0.70, 0.36, 0.00, 1)
            elseif cls == "Overview" then
                btn.bg:SetTexture(0.20, 0.45, 0.20, 1)
                btn.bottomLine:SetTexture(0.40, 0.90, 0.40, 1)
            elseif cls == "Group" then
                btn.bg:SetTexture(0.035, 0.14, 0.245, 1)
                btn.bottomLine:SetTexture(0.14, 0.56, 1.0, 1)
            elseif cls == "Settings" then
                btn.bg:SetTexture(0.21, 0.27, 0.45, 1)
                btn.bottomLine:SetTexture(0.467, 0.600, 1.000, 1)
            end
        else
            btn:SetAlpha(0.5)
            btn.bg:SetTexture(0.05, 0.07, 0.12, 1)
            btn.bottomLine:SetTexture(0, 0, 0, 0)
        end
    end
    -- Show/hide raid frame vs normal rows+headers
    if LichborneRaidFrame then
        local isRaid     = PBM.State.activeTab == "Raid"
        local isAll      = PBM.State.activeTab == "Overview"
        local isGroup    = PBM.State.activeTab == "Group"
        local isSettings = PBM.State.activeTab == "Settings"
        if isGroup then
            -- Build group view frame lazily the first time
            if not PBM.State.groupViewBuilt and PBM.State.mainParent then
                PBM.BuildGroupView(PBM.State.mainParent, PBM.State.mainFl)
            end
            if PBM.State.groupViewFrame then PBM.State.groupViewFrame:Show() end
            if PBM.State.LichborneOverviewFrame then PBM.State.LichborneOverviewFrame:Hide() end
            if LichborneRaidFrame then LichborneRaidFrame:Hide() end
            if PBM.State.LichborneBotSettingsFrame then PBM.State.LichborneBotSettingsFrame:Hide() end
            if LichborneHeaderBar then LichborneHeaderBar:Hide() end
            if LichborneAvgBar then LichborneAvgBar:Hide() end
            if LichborneCountBar then LichborneCountBar:Hide() end
            if _G["LichborneRaidCountBar"] then _G["LichborneRaidCountBar"]:Hide() end
            for _, rf in ipairs(PBM.State.rowFrames) do rf:Hide() end
            PBM.UpdateInviteButtons()
        elseif isAll then
            -- Show either the standard overview or the group-view depending on filter state
            if PBM.State.groupViewActive and PBM.State.groupViewFrame then
                if PBM.State.LichborneOverviewFrame then PBM.State.LichborneOverviewFrame:Hide() end
                PBM.State.groupViewFrame:Show()
            else
                if PBM.State.LichborneOverviewFrame then PBM.State.LichborneOverviewFrame:Show() end
                if PBM.State.groupViewFrame then PBM.State.groupViewFrame:Hide() end
            end
            if PBM.State.LichborneBotSettingsFrame then PBM.State.LichborneBotSettingsFrame:Hide() end
            if LichborneRaidFrame then LichborneRaidFrame:Hide() end
            if LichborneHeaderBar then LichborneHeaderBar:Hide() end
            if LichborneAvgBar then LichborneAvgBar:Hide() end
            if LichborneCountBar then LichborneCountBar:Hide() end
            if _G["LichborneRaidCountBar"] then _G["LichborneRaidCountBar"]:Hide() end
            for _, rf in ipairs(PBM.State.rowFrames) do rf:Hide() end
            PBM.UpdateInviteButtons()
        elseif isRaid then
            LichborneRaidFrame:Show()
            if PBM.State.LichborneOverviewFrame then PBM.State.LichborneOverviewFrame:Hide() end
            if PBM.State.groupViewFrame then PBM.State.groupViewFrame:Hide() end
            if PBM.State.LichborneBotSettingsFrame then PBM.State.LichborneBotSettingsFrame:Hide() end
            if LichborneHeaderBar then LichborneHeaderBar:Hide() end
            if LichborneAvgBar then LichborneAvgBar:Hide() end
            if LichborneCountBar then LichborneCountBar:Hide() end
            for _, rf in ipairs(PBM.State.rowFrames) do rf:Hide() end
            if _G["LichborneRaidCountBar"] then _G["LichborneRaidCountBar"]:Show() end
            PBM.UpdateInviteButtons()
        elseif isSettings then
            if PBM.State.LichborneBotSettingsFrame then PBM.State.LichborneBotSettingsFrame:Show() end
            if PBM.State.LichborneOverviewFrame then PBM.State.LichborneOverviewFrame:Hide() end
            if PBM.State.groupViewFrame then PBM.State.groupViewFrame:Hide() end
            LichborneRaidFrame:Hide()
            if LichborneHeaderBar then LichborneHeaderBar:Hide() end
            if LichborneAvgBar then LichborneAvgBar:Hide() end
            if LichborneCountBar then LichborneCountBar:Hide() end
            if _G["LichborneRaidCountBar"] then _G["LichborneRaidCountBar"]:Hide() end
            for _, rf in ipairs(PBM.State.rowFrames) do rf:Hide() end
            PBM.UpdateInviteButtons()
        elseif PBM.State.bottomTabPanels and PBM.State.bottomTabPanels[PBM.State.activeTab] then
            local panel = PBM.State.bottomTabPanels[PBM.State.activeTab]
            if PBM.State.LichborneBotSettingsFrame then PBM.State.LichborneBotSettingsFrame:Hide() end
            if PBM.State.LichborneOverviewFrame then PBM.State.LichborneOverviewFrame:Hide() end
            if PBM.State.groupViewFrame then PBM.State.groupViewFrame:Hide() end
            LichborneRaidFrame:Hide()
            if LichborneHeaderBar then LichborneHeaderBar:Hide() end
            if LichborneAvgBar then LichborneAvgBar:Hide() end
            if LichborneCountBar then LichborneCountBar:Hide() end
            if _G["LichborneRaidCountBar"] then _G["LichborneRaidCountBar"]:Hide() end
            for _, rf in ipairs(PBM.State.rowFrames) do rf:Hide() end
            panel:Show()
            PBM.UpdateInviteButtons()
        else
            LichborneRaidFrame:Hide()
            if PBM.State.LichborneOverviewFrame then PBM.State.LichborneOverviewFrame:Hide() end
            if PBM.State.groupViewFrame then PBM.State.groupViewFrame:Hide() end
            if PBM.State.LichborneBotSettingsFrame then PBM.State.LichborneBotSettingsFrame:Hide() end
            if LichborneHeaderBar then LichborneHeaderBar:Hide() end
            if LichborneAvgBar then LichborneAvgBar:Hide() end
            if LichborneCountBar then LichborneCountBar:Hide() end
            if _G["LichborneRaidCountBar"] then _G["LichborneRaidCountBar"]:Hide() end
            -- restore class tab UI
            if LichborneHeaderBar then LichborneHeaderBar:Show() end
            if LichborneAvgBar then LichborneAvgBar:Show() end
            if LichborneCountBar then LichborneCountBar:Show() end
            if _G["LichborneRaidCountBar"] then _G["LichborneRaidCountBar"]:Hide() end
            PBM.UpdateInviteButtons()
        end
    end
end

-- ── Raid sort ──────────────────────────────────────────────────
function PBM.UpdateRaidSortHeaders()
    for key, entry in pairs(PBM.State.raidSortHdrs) do
        if PBM.State.raidSortKey == key then
            local arrow
            if key == "role" then
                arrow = PBM.State.raidSortAsc and " (T)" or " (H)"
            else
                arrow = PBM.State.raidSortAsc and " ^" or " v"
            end
            entry.fs:SetText("|cffd4af37"..entry.lbl..arrow.."|r")
        else
            entry.fs:SetText("|cffd4af37"..entry.lbl.."|r")
        end
    end
end

function PBM.SortRaidRows()
    local roster, raidSize = PBM.GetCurrentRoster()
    local filled, empty = {}, {}
    for i = 1, PBM.MAX_RAID_SLOTS do
        local r = roster[i]
        if r and r.name and r.name ~= "" then
            filled[#filled+1] = r
        else
            empty[#empty+1] = {name="", cls="", spec="", gs=0, realGs=0}
        end
    end
    if not PBM.State.raidSortKey then
        -- No sort active: just compact (filled first, empty last) and return
        local idx = 1
        for _, r in ipairs(filled) do roster[idx] = r; idx = idx + 1 end
        for _, r in ipairs(empty)  do roster[idx] = r; idx = idx + 1 end
        return
    end
    if PBM.State.raidSortPending then
        PBM.State.raidSortPending = false
        if PBM.State.raidSortKey == "spec" then
            table.sort(filled, function(a, b)
                local ca, cb = a.cls or "", b.cls or ""
                if ca ~= cb then
                    if PBM.State.raidSortAsc then return ca < cb else return ca > cb end
                end
                local sa, sb2 = a.spec or "", b.spec or ""
                if sa ~= sb2 then return sa < sb2 end
                return (a.name or "") < (b.name or "")
            end)
        elseif PBM.State.raidSortKey == "name" then
            table.sort(filled, function(a, b)
                local na, nb = a.name or "", b.name or ""
                if na ~= nb then
                    if PBM.State.raidSortAsc then return na < nb else return na > nb end
                end
                return false
            end)
        elseif PBM.State.raidSortKey == "ilvl" then
            table.sort(filled, function(a, b)
                local ga, gb2 = a.gs or 0, b.gs or 0
                if ga ~= gb2 then
                    if PBM.State.raidSortAsc then return ga < gb2 else return ga > gb2 end
                end
                return (a.name or "") < (b.name or "")
            end)
        elseif PBM.State.raidSortKey == "gs" then
            table.sort(filled, function(a, b)
                local ga, gb2 = a.realGs or 0, b.realGs or 0
                if ga ~= gb2 then
                    if PBM.State.raidSortAsc then return ga < gb2 else return ga > gb2 end
                end
                return (a.name or "") < (b.name or "")
            end)
        elseif PBM.State.raidSortKey == "role" then
            local ROLE_ORDER  = {T=1, H=2, D=3, A=3}  -- A same tier as D
            local ROLE_MANUAL = {TNK=1, HLR=2, DPS=3}
            local function getRaidRoleRank(r)
                local bn = LichborneTrackerDB.botNotes and r.name and r.name ~= ""
                           and LichborneTrackerDB.botNotes[r.name:lower()]
                if bn and bn.roles and bn.roles[1] then
                    return ROLE_ORDER[bn.roles[1]] or 4
                end
                return ROLE_MANUAL[r.role or ""] or 4
            end
            table.sort(filled, function(a, b)
                local ra, rb2 = getRaidRoleRank(a), getRaidRoleRank(b)
                if ra ~= rb2 then
                    if PBM.State.raidSortAsc then return ra < rb2 else return ra > rb2 end
                end
                if ra == 3 then  -- DPS tier: sub-sort by class then spec
                    local ac, bc = a.cls or "", b.cls or ""
                    if ac ~= bc then return ac < bc end
                    local as2, bs2 = a.spec or "", b.spec or ""
                    if as2 ~= bs2 then return as2 < bs2 end
                end
                return (a.name or "") < (b.name or "")
            end)
        end
    end
    local idx = 1
    for _, r in ipairs(filled) do roster[idx] = r; idx = idx + 1 end
    for _, r in ipairs(empty)  do roster[idx] = r; idx = idx + 1 end
end

-- ── Overview sort dropdown ─────────────────────────────────────
function PBM.MakeSortDropdown(parent, fl, onSelect)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(90, 16); btn:SetFrameLevel(fl+2)
    btn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=6,insets={left=1,right=1,top=1,bottom=1}})
    btn:SetBackdropColor(0.10,0.08,0.02,1); btn:SetBackdropBorderColor(0.70,0.55,0.10,0.9)
    btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local lbl = btn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    lbl:SetAllPoints(btn); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
    lbl:SetText(PBM.SORT_GOLD.."Sort  v|r")

    local menu = CreateFrame("Frame", nil, UIParent)
    menu:SetFrameStrata("TOOLTIP"); menu:SetSize(150, #PBM.SORT_OPTS*22+8)
    menu:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    menu:SetBackdropColor(0.08,0.06,0.01,0.98); menu:SetBackdropBorderColor(0.70,0.55,0.10,1)
    menu:Hide()

    for i, opt in ipairs(PBM.SORT_OPTS) do
        local mb = CreateFrame("Button", nil, menu); mb:SetSize(146, 20)
        mb:SetPoint("TOPLEFT", menu, "TOPLEFT", 2, -2-(i-1)*22)
        mb:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        mb:SetBackdropColor(0.08,0.06,0.01,1); mb:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        local ml = mb:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); ml:SetAllPoints(mb); ml:SetJustifyH("CENTER")
        ml:SetText(PBM.SORT_GOLD..opt.label.."|r")
        local cap = opt
        mb:SetScript("OnClick", function()
            menu:Hide()
            lbl:SetText(PBM.SORT_GOLD..cap.label.."  v|r")
            onSelect(cap.mode)
        end)
    end

    PBM.State.allSortMenus[#PBM.State.allSortMenus+1] = menu

    btn:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide()
        else
            PBM.CloseAllSortMenus()
            menu:ClearAllPoints()
            menu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
            menu:Show()
        end
    end)

    btn._menu = menu
    return btn
end
