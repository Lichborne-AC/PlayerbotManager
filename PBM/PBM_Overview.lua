PBM = PBM or {}
PBM.State = PBM.State or {}

PBM.State.overviewFrameBuilt      = PBM.State.overviewFrameBuilt      or false
PBM.State.LichborneOverviewFrame  = PBM.State.LichborneOverviewFrame  or nil
PBM.State.LichborneAllCountLabels = PBM.State.LichborneAllCountLabels or nil
PBM.State.overviewRowFrames       = PBM.State.overviewRowFrames       or {}
PBM.RefreshOverviewRows           = PBM.RefreshOverviewRows           or nil  -- assigned below

function PBM.GetCurrentOverviewRows()
    if not LichborneTrackerDB.allGroups then
        LichborneTrackerDB.allGroups = {}
    end
    if not LichborneTrackerDB.allGroup then LichborneTrackerDB.allGroup = "A" end
    local g = LichborneTrackerDB.allGroup
    if not LichborneTrackerDB.allGroups[g] then
        LichborneTrackerDB.allGroups[g] = {}
        for i=1,60 do LichborneTrackerDB.allGroups[g][i]={name="",cls="",spec="",gs=0,realGs=0,role=""} end
    end
    local rows = LichborneTrackerDB.allGroups[g]
    for i=1,60 do if not rows[i] then rows[i]={name="",cls="",spec="",gs=0,realGs=0,role=""} end end
    return rows
end

-- ── Overview tab: mirrors Raid tab with 3 columns of 20 = 60 slots ──────────
PBM.RefreshOverviewRows = function()
    if not PBM.State.LichborneOverviewFrame then return end
    local rows = PBM.GetCurrentOverviewRows()

    -- Update Overview tab group label
    local g = LichborneTrackerDB.allGroup or "A"
    if LichborneAllPageLbl then
        local pageNum = ({A="1",B="2",C="3"})[g] or g
        LichborneAllPageLbl:SetText("|cffd4af37Page "..pageNum.." v|r")
    end

    -- Overflow sync: rebuild all three groups from class tabs sequentially
    -- A=slots 1-60, B=slots 61-120, C=slots 121-180
    -- Collect ALL tracked characters in order
    local allTracked = {}
    for _, classRow in ipairs(LichborneTrackerDB.rows or {}) do
        if classRow.name and classRow.name ~= "" then
            allTracked[#allTracked+1] = classRow
        end
    end
    -- Apply group filter: show only party/raid members in Overview tab
    if PBM.State.LBFilter.groupActive then
        local gnames = PBM.GetGroupMemberNameSet()
        local filtered = {}
        for _, r in ipairs(allTracked) do
            if gnames[r.name] then filtered[#filtered+1] = r end
        end
        allTracked = filtered
    end
    -- Apply hide-raid filter: exclude characters already in the raid tab roster
    if PBM.State.LBFilter.hideRaid then
        local raidFiltered = {}
        for _, r in ipairs(allTracked) do
            if PBM.IsInActiveRaid(r.name or "") then raidFiltered[#raidFiltered+1] = r end
        end
        allTracked = raidFiltered
    end
    -- Apply sort globally across ALL characters before splitting into pages
    if PBM.State.allSortKey then
        local function nameEmpty(r) return not r.name or r.name == "" end
        if PBM.State.allSortKey == "spec" then
            table.sort(allTracked, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local ac, bc = a.cls or "", b.cls or ""
                if ac ~= bc then
                    if PBM.State.allSortAsc then return ac < bc else return ac > bc end
                end
                local as2, bs2 = a.spec or "", b.spec or ""
                if as2 ~= bs2 then return as2 < bs2 end
                return (a.name or "") < (b.name or "")
            end)
        elseif PBM.State.allSortKey == "name" then
            table.sort(allTracked, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local an, bn = a.name or "", b.name or ""
                if an ~= bn then
                    if PBM.State.allSortAsc then return an < bn else return an > bn end
                end
                return false
            end)
        elseif PBM.State.allSortKey == "ilvl" then
            table.sort(allTracked, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local ag, bg2 = a.gs or 0, b.gs or 0
                if ag ~= bg2 then
                    if PBM.State.allSortAsc then return ag < bg2 else return ag > bg2 end
                end
                return (a.name or "") < (b.name or "")
            end)
        elseif PBM.State.allSortKey == "gs" then
            table.sort(allTracked, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local ag, bg2 = a.realGs or 0, b.realGs or 0
                if ag ~= bg2 then
                    if PBM.State.allSortAsc then return ag < bg2 else return ag > bg2 end
                end
                return (a.name or "") < (b.name or "")
            end)
        elseif PBM.State.allSortKey == "inraid" then
            table.sort(allTracked, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local ai = PBM.IsInActiveRaid(a.name or "") and 1 or 0
                local bi = PBM.IsInActiveRaid(b.name or "") and 1 or 0
                if ai ~= bi then
                    if PBM.State.allSortAsc then return ai > bi else return ai < bi end
                end
                local ac, bc = a.cls or "", b.cls or ""
                if ac ~= bc then return ac < bc end
                local as2, bs2 = a.spec or "", b.spec or ""
                if as2 ~= bs2 then return as2 < bs2 end
                return (a.name or "") < (b.name or "")
            end)
        elseif PBM.State.allSortKey == "level" then
            table.sort(allTracked, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local la, lb = a.level or 0, b.level or 0
                if la ~= lb then
                    if PBM.State.allSortAsc then return la < lb else return la > lb end
                end
                return (a.name or "") < (b.name or "")
            end)
        elseif PBM.State.allSortKey == "role" then
            local ROLE_ORDER = {T=1, H=2, D=3, A=3}  -- A same tier as D
            local function getRoleRank(r)
                local bn = LichborneTrackerDB.botNotes and r.name and r.name ~= ""
                           and LichborneTrackerDB.botNotes[r.name:lower()]
                local primary = bn and bn.roles and bn.roles[1]
                return ROLE_ORDER[primary or ""] or 4
            end
            table.sort(allTracked, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local ra, rb2 = getRoleRank(a), getRoleRank(b)
                if ra ~= rb2 then
                    if PBM.State.allSortAsc then return ra < rb2 else return ra > rb2 end
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
    -- Fill groups in order
    local groups = {"A","B","C"}
    for gi, g in ipairs(groups) do
        if not LichborneTrackerDB.allGroups[g] then
            LichborneTrackerDB.allGroups[g] = {}
        end
        local gRows = LichborneTrackerDB.allGroups[g]
        for i=1,60 do if not gRows[i] then gRows[i]={name="",cls="",spec="",gs=0,realGs=0,role=""} end end
        local startIdx = (gi-1)*60 + 1
        local endIdx   = gi*60
        -- Clear first
        for i=1,60 do gRows[i]={name="",cls="",spec="",gs=0,realGs=0,level=0,role=""} end
        -- Fill with tracked chars for this range
        for i=startIdx,endIdx do
            local slot = i - startIdx + 1
            if allTracked[i] then
                local cr = allTracked[i]
                gRows[slot] = {name=cr.name, cls=cr.cls or "", spec=cr.spec or "", gs=cr.gs or 0, realGs=cr.realGs or 0, level=cr.level or 0, role=cr.role or ""}
            end
        end
    end
    -- Re-get rows for current group display
    rows = PBM.GetCurrentOverviewRows()

    -- Apply sort if active (sort a copy so DB order is unchanged)
    if PBM.State.allSortKey then
        local function nameEmpty(r) return not r.name or r.name == "" end
        local sorted = {}
        for i = 1, 60 do sorted[i] = rows[i] end
        if PBM.State.allSortKey == "spec" then
            table.sort(sorted, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local ac, bc = a.cls or "", b.cls or ""
                if ac ~= bc then
                    if PBM.State.allSortAsc then return ac < bc else return ac > bc end
                end
                local as2, bs2 = a.spec or "", b.spec or ""
                if as2 ~= bs2 then return as2 < bs2 end
                return (a.name or "") < (b.name or "")
            end)
        elseif PBM.State.allSortKey == "name" then
            table.sort(sorted, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local an, bn = a.name or "", b.name or ""
                if an ~= bn then
                    if PBM.State.allSortAsc then return an < bn else return an > bn end
                end
                return false
            end)
        elseif PBM.State.allSortKey == "ilvl" then
            table.sort(sorted, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local ag, bg2 = a.gs or 0, b.gs or 0
                if ag ~= bg2 then
                    if PBM.State.allSortAsc then return ag < bg2 else return ag > bg2 end
                end
                return (a.name or "") < (b.name or "")
            end)
        elseif PBM.State.allSortKey == "gs" then
            table.sort(sorted, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local ag, bg2 = a.realGs or 0, b.realGs or 0
                if ag ~= bg2 then
                    if PBM.State.allSortAsc then return ag < bg2 else return ag > bg2 end
                end
                return (a.name or "") < (b.name or "")
            end)
        elseif PBM.State.allSortKey == "inraid" then
            table.sort(sorted, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local ai = PBM.IsInActiveRaid(a.name or "") and 1 or 0
                local bi = PBM.IsInActiveRaid(b.name or "") and 1 or 0
                if ai ~= bi then
                    if PBM.State.allSortAsc then return ai > bi else return ai < bi end
                end
                -- within same raid-status group: class A-Z, then spec A-Z, then name
                local ac, bc = a.cls or "", b.cls or ""
                if ac ~= bc then return ac < bc end
                local as2, bs2 = a.spec or "", b.spec or ""
                if as2 ~= bs2 then return as2 < bs2 end
                return (a.name or "") < (b.name or "")
            end)
        elseif PBM.State.allSortKey == "level" then
            table.sort(sorted, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local la, lb = a.level or 0, b.level or 0
                if la ~= lb then
                    if PBM.State.allSortAsc then return la < lb else return la > lb end
                end
                return (a.name or "") < (b.name or "")
            end)
        elseif PBM.State.allSortKey == "role" then
            local ROLE_ORDER = {T=1, H=2, D=3, A=3}  -- A same tier as D
            local function getRoleRank(r)
                local bn = LichborneTrackerDB.botNotes and r.name and r.name ~= ""
                           and LichborneTrackerDB.botNotes[r.name:lower()]
                local primary = bn and bn.roles and bn.roles[1]
                return ROLE_ORDER[primary or ""] or 4
            end
            table.sort(sorted, function(a, b)
                if nameEmpty(a) ~= nameEmpty(b) then return not nameEmpty(a) end
                local ra, rb2 = getRoleRank(a), getRoleRank(b)
                if ra ~= rb2 then
                    if PBM.State.allSortAsc then return ra < rb2 else return ra > rb2 end
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
        rows = sorted
    end

    for i = 1, 60 do
        local rf = PBM.State.overviewRowFrames[i]
        if not rf then break end
        local data = rows[i]
        local dataRef = data
        local hasData = data.name and data.name ~= ""

        -- Sync spec from class tabs
        if hasData then
            for _, r in ipairs(LichborneTrackerDB.rows) do
                if r.name and r.name:lower() == data.name:lower() then
                    if r.spec and r.spec ~= "" then data.spec = r.spec end
                    if r.cls and r.cls ~= "" then data.cls = r.cls end
                    if r.gs and r.gs > 0 then data.gs = r.gs end
                    data.realGs = r.realGs or 0
                    data.level = r.level or 0
                    break
                end
            end
        end

        -- Role slot display (top 2 from botNotes, sorted T→H→D→A)
        if rf.roleSlots then
            local botNE = hasData and LichborneTrackerDB.botNotes
                          and LichborneTrackerDB.botNotes[(data.name or ""):lower()]
            local rawRoles = botNE and botNE.roles or {}
            local roles = {}
            for _, r in ipairs(rawRoles) do
                if PBM.NOTES_ROLE_ICONS and PBM.NOTES_ROLE_ICONS[r] then
                    roles[#roles+1] = r
                end
            end
            local isTank = false
            for _, r in ipairs(roles) do if r == "T" then isTank = true; break end end
            local roleOrder = isTank and { T=1, A=2, D=3, H=4 } or { T=1, H=2, D=3, A=4 }
            table.sort(roles, function(a, b)
                return (roleOrder[a] or 9) < (roleOrder[b] or 9)
            end)
            for si = 1, 2 do
                local tex = rf.roleSlots[si]
                local icon = roles[si] and PBM.NOTES_ROLE_ICONS[roles[si]]
                if tex then
                    if icon then tex:SetTexture(icon); tex:SetAlpha(1.0)
                    else tex:SetAlpha(0) end
                end
            end
        end

        -- Class icon
        if rf.classIcon then
            local cIcon = PBM.CLASS_ICONS[data.cls or ""]
            if cIcon and hasData then rf.classIcon:SetTexture(cIcon); rf.classIcon:SetAlpha(1)
            else rf.classIcon:SetTexture(0,0,0,0) end
        end
        -- Spec icon
        if rf.specIcon then
            local sIcon = data.spec and data.spec ~= "" and PBM.SPEC_ICONS[data.spec]
            if sIcon and hasData then rf.specIcon:SetTexture(sIcon); rf.specIcon:SetAlpha(1)
            elseif hasData then rf.specIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); rf.specIcon:SetAlpha(0.2)
            else rf.specIcon:SetTexture(0,0,0,0) end
        end
        -- Name (read-only - populated from class tabs)
        if rf.nameBox then
            local name = data.name or ""
            rf.nameBox:SetText(name)
            local c = data.cls and PBM.CLASS_COLORS[data.cls]
            if c then rf.nameBox:SetTextColor(c.r, c.g, c.b)
            else rf.nameBox:SetTextColor(0.7,0.8,0.9) end
        end
        -- iLvl (read-only on Overview tab)
        if rf.gsBox then
            rf.gsBox:SetText(data.gs and data.gs > 0 and tostring(data.gs) or "")
        end
        -- GS (read-only on Overview tab)
        if rf.realGsBox then
            rf.realGsBox:SetText(data.realGs and data.realGs > 0 and tostring(data.realGs) or "")
        end
        -- Row number
        if rf.numLbl then
            if PBM.State.LBFilter.showIP then
                local ipVal = hasData and LichborneTrackerDB.ipData and LichborneTrackerDB.ipData[(data.name or ""):lower()]
                if ipVal then
                    rf.numLbl:SetText(tostring(ipVal))
                    rf.numLbl:SetTextColor(0.83, 0.69, 0.22)
                else
                    rf.numLbl:SetText("")
                end
            elseif PBM.State.LBFilter.showLevel then
                if hasData and (data.level or 0) > 0 then
                    rf.numLbl:SetText(tostring(data.level))
                    rf.numLbl:SetTextColor(0.83, 0.69, 0.22)
                else
                    rf.numLbl:SetText("")
                end
            else
                rf.numLbl:SetText(tostring(i))
                rf.numLbl:SetTextColor(0.4, 0.5, 0.6)
            end
        end
        -- No delete on Overview tab

        -- Spec button popup (same menu as raid/class tabs)
        if rf.specIcon then
            local specFrame = rf.specIcon and rf.specIcon:GetParent()
            if specFrame then
                specFrame:SetScript("OnEnter", function()
                    local d4 = dataRef
                    local spec = d4 and d4.spec or ""
                    local cls = d4 and d4.cls or ""
                    local c = cls ~= "" and PBM.CLASS_COLORS[cls]
                    GameTooltip:SetOwner(specFrame, "ANCHOR_RIGHT")
                    if spec ~= "" then
                        GameTooltip:AddLine(spec, 1, 1, 1)
                    end
                    if cls ~= "" then
                        if c then GameTooltip:AddLine(cls, c.r, c.g, c.b)
                        else GameTooltip:AddLine(cls, 0.8, 0.8, 0.9) end
                    end
                    if spec == "" and cls == "" then
                        GameTooltip:AddLine("Empty", 0.4, 0.4, 0.4)
                    end
                    GameTooltip:Show()
                end)
                specFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
        end
        -- Add to Group btn
        if rf.addGroupBtn then
            rf.addGroupBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            rf.addGroupBtn:SetScript("OnClick", function(self, btn)
                local d = dataRef
                if not d or not d.name or d.name == "" then return end
                local c = d.cls and PBM.CLASS_COLORS[d.cls]
                local hex = c and string.format("|cff%02x%02x%02x",math.floor(c.r*255),math.floor(c.g*255),math.floor(c.b*255)) or "|cffffffff"
                if btn == "RightButton" then
                    UninviteUnit(d.name)
                    SendChatMessage(".playerbots bot remove "..d.name, "SAY")
                    LichborneOutput("|cffC69B3ALichborne:|r Removed "..hex..d.name.."|r from bots.", 1, 0.85, 0)
                    return
                end
                SendChatMessage(".playerbots bot add "..d.name, "SAY")
                if LichborneAddStatus then LichborneAddStatus:SetText("Invited "..hex..d.name.."|r to group.") end
            end)
        end
        -- Add to Raid btn
        if rf.addRaidBtn then
            -- Color + orange (T1) when in raid, green when not
            if PBM.IsInActiveRaid(data.name) then
                rf.addRaidBtn:SetText("|cffb25b00+|r")
            else
                rf.addRaidBtn:SetText("|cff44ff44+|r")
            end
            rf.addRaidBtn:SetScript("OnClick", function(self, btn)
                local d = dataRef
                if not d or not d.name or d.name == "" then return end
                local c = d.cls and PBM.CLASS_COLORS[d.cls]
                local hex = c and string.format("|cff%02x%02x%02x",math.floor(c.r*255),math.floor(c.g*255),math.floor(c.b*255)) or "|cffffffff"
                if btn == "RightButton" then
                    -- Remove from raid
                    local roster, _ = PBM.GetCurrentRoster()
                    for ri = 1, PBM.MAX_RAID_SLOTS do
                        if roster[ri] and roster[ri].name and roster[ri].name:lower() == d.name:lower() then
                            local slot = ri
                            roster[ri] = {name="", cls="", spec="", gs=0, realGs=0, role="", notes=""}
                            rf.addRaidBtn:SetText("|cff44ff44+|r")
                            if LichborneAddStatus then
                                LichborneAddStatus:SetText(hex..d.name.."|r removed from raid slot "..slot..".")
                            end
                            if LichborneRaidFrame then PBM.RefreshRaidRows() end
                            PBM.RefreshOverviewRows()
                            return
                        end
                    end
                    return
                end
                -- Left click: add to raid
                local roster, raidSize = PBM.GetCurrentRoster()
                for ri = 1, raidSize do
                    if roster[ri] and roster[ri].name and roster[ri].name:lower() == d.name:lower() then
                        if LichborneAddStatus then LichborneAddStatus:SetText(hex..d.name.."|r is already in the Raid.") end; return
                    end
                end
                for ri = 1, raidSize do
                    if not roster[ri] or roster[ri].name == "" then
                        roster[ri] = {name=d.name, cls=d.cls or "",spec=d.spec or "",gs=d.gs or 0, realGs=d.realGs or 0, role="", notes=""}
                        if LichborneAddStatus then LichborneAddStatus:SetText(hex..d.name.."|r added to raid slot "..ri..".") end
                        -- Color + orange after successful add
                        rf.addRaidBtn:SetText("|cffb25b00+|r")
                        if LichborneRaidFrame then PBM.RefreshRaidRows() end
                        return
                    end
                end
                if LichborneAddStatus then LichborneAddStatus:SetText("Raid is full!") end
            end)
        end
        -- Wire delete button
        if rf.allDelBtnFrame then
            rf.allDelBtnFrame:SetScript("OnClick", function()
                local d = dataRef
                if not d or not d.name or d.name == "" then return end
                local charName = d.name
                PBM.RemoveCharacterReferences(charName)
                if LichborneAddStatus then
                    LichborneAddStatus:SetText("|cffff6666"..charName.."|r removed from tracker.")
                end
                PBM.RefreshRows()
                PBM.RefreshOverviewRows()
                if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
            end)
        end
    end

    -- Count bar
    if PBM.State.LichborneAllCountLabels then
        local allCounts = {}
        for _, cls in ipairs(PBM.CLASS_TABS) do if cls ~= "Raid" and cls ~= "Overview" then allCounts[cls] = 0 end end
        -- Count from ALL tracked rows, not just the current page
        for _, r in ipairs(LichborneTrackerDB.rows or {}) do
            if r and r.name and r.name ~= "" and r.cls and allCounts[r.cls] ~= nil then
                allCounts[r.cls] = allCounts[r.cls] + 1
            end
        end
        for cls, lbl in pairs(PBM.State.LichborneAllCountLabels) do
            local c = PBM.CLASS_COLORS[cls]
            if c then
                local n = allCounts[cls] or 0
                local hex = string.format("|cff%02x%02x%02x",math.floor(c.r*255),math.floor(c.g*255),math.floor(c.b*255))
                lbl:SetText(hex..(PBM.TAB_LABELS[cls])..": |cffd4af37"..n.."|r")
                local sw = lbl:GetParent()
                if sw and sw.bg then
                    if n > 0 then sw.bg:SetTexture(c.r*0.25,c.g*0.25,c.b*0.30,1)
                    else sw.bg:SetTexture(0.08,0.10,0.18,1) end
                end
            end
        end
    end
end  -- PBM.RefreshOverviewRows

-- Overview frame uses same layout as Raid: 3 columns of 20, same row height
local ALL_PER_COL = PBM.ALL_PER_COL
local ALL_NCOLS   = PBM.ALL_NCOLS
local ALL_COL_W   = PBM.ALL_COL_W

function PBM.BuildOverviewFrame(parent, fl)
    if PBM.State.overviewFrameBuilt then return end
    PBM.State.overviewFrameBuilt = true

    PBM.State.LichborneOverviewFrame = CreateFrame("Frame","LichborneOverviewFrame",parent)
    PBM.State.LichborneOverviewFrame:SetPoint("TOPLEFT",parent,"TOPLEFT",15,-66)
    PBM.State.LichborneOverviewFrame:SetSize(ALL_NCOLS*ALL_COL_W, 512)  -- 24hdr+20+18hdr+20+440rows+10+24count
    PBM.State.LichborneOverviewFrame:SetFrameLevel(fl+10)
    PBM.State.LichborneOverviewFrame:Hide()

    -- Green header bar
    local allHdr = CreateFrame("Frame",nil,PBM.State.LichborneOverviewFrame)
    allHdr:SetPoint("TOPLEFT",PBM.State.LichborneOverviewFrame,"TOPLEFT",0,0)
    allHdr:SetSize(ALL_NCOLS*ALL_COL_W,24); allHdr:SetFrameLevel(fl+11)
    local allHdrBg = allHdr:CreateTexture(nil,"BACKGROUND"); allHdrBg:SetAllPoints(allHdr); allHdrBg:SetTexture(0.05,0.20,0.05,1)
    local allTitle = allHdr:CreateFontString(nil,"OVERLAY","GameFontNormal")
    allTitle:SetPoint("TOPLEFT",allHdr,"TOPLEFT",0,0); allTitle:SetPoint("TOPRIGHT",allHdr,"TOPRIGHT",0,0)
    allTitle:SetHeight(24); allTitle:SetJustifyH("CENTER"); allTitle:SetJustifyV("MIDDLE")
    allTitle:SetText("|cffd4af37Overview|r")

    -- Sort / Clear buttons
    local function MakeHdrBtn(lbl, br, bg2, bb, xOff, w)
        local btn = CreateFrame("Button",nil,allHdr); btn:SetSize(w or 55,20)
        btn:SetPoint("RIGHT",allHdr,"RIGHT",xOff,0); btn:SetFrameLevel(fl+12)
        btn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,insets={left=0,right=0,top=0,bottom=0}})
        btn:SetBackdropColor(br*0.4,bg2*0.4,bb*0.4,1); btn:SetBackdropBorderColor(br,bg2,bb,0.9)
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        local l=btn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); l:SetAllPoints(btn); l:SetJustifyH("CENTER"); l:SetJustifyV("MIDDLE"); l:SetText(lbl)
        return btn
    end
    -- Page label (far right, dropdown trigger)
    -- Page button - same style as Sort
    local overviewPageBtn = CreateFrame("Button", "LichborneOverviewPageBtn", allHdr)
    overviewPageBtn:SetSize(55, 20)
    overviewPageBtn:SetPoint("RIGHT", allHdr, "RIGHT", -4, 0)
    overviewPageBtn:SetFrameLevel(fl+12)
    overviewPageBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    overviewPageBtn:SetBackdropColor(0.10, 0.08, 0.02, 1)
    overviewPageBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    overviewPageBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local allPageLbl = overviewPageBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    allPageLbl:SetAllPoints(overviewPageBtn); allPageLbl:SetJustifyH("CENTER"); allPageLbl:SetJustifyV("MIDDLE")
    allPageLbl:SetText("|cffd4af37Page 1 v|r")
    LichborneAllPageLbl  = allPageLbl
    LichborneAllPagePrev = nil
    LichborneAllPageNext = nil
    local allPrevBtn = {}
    local allNextBtn = {}

    -- Single group dropdown on the right (replaces both left Group: and page < > buttons)
    local function UpdateOverviewGroupDD()
        local g = LichborneTrackerDB.allGroup or "A"
        if LichborneAllPageLbl then
            local pageNum = ({A="1",B="2",C="3"})[g] or g
            LichborneAllPageLbl:SetText("|cffd4af37Page "..pageNum.." v|r")
        end
        if LichborneAllPagePrev then LichborneAllPagePrev:SetAlpha(g ~= "A" and 1.0 or 0.35) end
        if LichborneAllPageNext then LichborneAllPageNext:SetAlpha(g ~= "C" and 1.0 or 0.35) end
    end
    UpdateOverviewGroupDD()

    -- Dropdown menu triggered by clicking the Group label
    local overviewGroupMenu = CreateFrame("Frame","LichborneOverviewGroupMenu",UIParent)
    overviewGroupMenu:SetFrameStrata("TOOLTIP"); overviewGroupMenu:SetSize(90,3*22+8)
    overviewGroupMenu:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    overviewGroupMenu:SetBackdropColor(0.05,0.08,0.20,0.98); overviewGroupMenu:SetBackdropBorderColor(0.30,0.50,0.80,1)
    overviewGroupMenu:Hide()
    for gi, gname in ipairs({"A","B","C"}) do
        local mb=CreateFrame("Button",nil,overviewGroupMenu); mb:SetSize(86,20)
        mb:SetPoint("TOPLEFT",overviewGroupMenu,"TOPLEFT",2,-2-(gi-1)*22)
        mb:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        mb:SetBackdropColor(0.05,0.08,0.20,1); mb:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        local mblbl=mb:CreateFontString(nil,"OVERLAY","GameFontNormal"); mblbl:SetAllPoints(mb); mblbl:SetJustifyH("CENTER")
        mblbl:SetText("|cffd4af37Page "..gi.."|r")
        local cap=gname
        mb:SetScript("OnClick",function()
            LichborneTrackerDB.allGroup=cap; UpdateOverviewGroupDD(); overviewGroupMenu:Hide(); PBM.RefreshOverviewRows()
        end)
    end
    -- Wire the page button to open the dropdown menu
    overviewPageBtn:SetScript("OnClick", function()
        if overviewGroupMenu:IsShown() then overviewGroupMenu:Hide()
        else overviewGroupMenu:ClearAllPoints(); overviewGroupMenu:SetPoint("TOPRIGHT",overviewPageBtn,"BOTTOMRIGHT",0,-2); overviewGroupMenu:Show() end
    end)

    -- Column headers (3 cols; left col has sortable buttons, right cols plain labels)
    local RH_ALL = 22
    PBM.State.allSortHdrs = {}
    local function UpdateAllSortHeaders()
        for key, entry in pairs(PBM.State.allSortHdrs) do
            local baseLbl = key == "inraid" and "+" or entry.lbl
            if key == PBM.State.allSortKey then
                local arrow = PBM.State.allSortAsc and " ^" or " v"
                for _, fs in ipairs(entry.fsList) do
                    fs:SetText("|cffd4af37"..baseLbl..arrow.."|r")
                end
            else
                for _, fs in ipairs(entry.fsList) do
                    fs:SetText("|cffd4af37"..baseLbl.."|r")
                end
            end
        end
    end
    for col = 0, ALL_NCOLS-1 do
        local hdr = CreateFrame("Frame",nil,PBM.State.LichborneOverviewFrame)
        hdr:SetPoint("TOPLEFT",PBM.State.LichborneOverviewFrame,"TOPLEFT",col*ALL_COL_W,-26)
        hdr:SetSize(ALL_COL_W,18); hdr:SetFrameLevel(fl+11)
        local hbg=hdr:CreateTexture(nil,"BACKGROUND"); hbg:SetAllPoints(hdr); hbg:SetTexture(0.08,0.20,0.42,1)
        local function H(txt,x,w) local fs=hdr:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); fs:SetPoint("LEFT",hdr,"LEFT",x,0); fs:SetWidth(w); fs:SetJustifyH("CENTER"); fs:SetText("|cffd4af37"..txt.."|r") end
        if col == 0 then
            local function ASH(lbl, x, w, key, isNumeric)
                if not PBM.State.allSortHdrs[key] then PBM.State.allSortHdrs[key] = {lbl=lbl, fsList={}} end
                local entry = PBM.State.allSortHdrs[key]
                local btn = CreateFrame("Button",nil,hdr)
                btn:SetPoint("TOPLEFT",hdr,"TOPLEFT",x,0)
                btn:SetSize(w,18); btn:SetFrameLevel(hdr:GetFrameLevel()+1)
                btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
                local fs = btn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
                fs:SetPoint("CENTER",btn,"CENTER",0,0); fs:SetSize(w+6,18); fs:SetJustifyH("CENTER"); fs:SetJustifyV("MIDDLE")
                fs:SetText("|cffd4af37"..lbl.."|r")
                entry.fsList[#entry.fsList+1] = fs
                btn:SetScript("OnEnter",function()
                    GameTooltip:SetOwner(btn,"ANCHOR_RIGHT")
                    GameTooltip:AddLine("Click to sort",1,1,1)
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave",function() GameTooltip:Hide() end)
                btn:SetScript("OnClick",function()
                    if PBM.State.allSortKey == key then
                        PBM.State.allSortAsc = not PBM.State.allSortAsc
                    else
                        PBM.State.allSortKey = key
                        PBM.State.allSortAsc = not isNumeric
                    end
                    UpdateAllSortHeaders()
                    PBM.RefreshOverviewRows()
                end)
            end
            H("#",0,14)
            ASH("Spec",14,48,"spec",false)
            ASH("Name",60,128,"name",false)
            ASH("iLvL",189,38,"ilvl",true)
            ASH("GS",227,38,"gs",true)
            ASH("Role",268,36,"role",false)
            ASH("+",308,18,"inraid",false)
        else
            H("Spec",16,44); H("Name",62,126); H("iLvL",192,36); H("GS",230,36); H("Role",268,36)
        end
    end

    -- 60 rows across 3 columns
    for i = 1, 60 do
        local col = math.floor((i-1)/ALL_PER_COL)
        local rowInCol = (i-1) % ALL_PER_COL
        local rf = CreateFrame("Frame",nil,PBM.State.LichborneOverviewFrame)
        rf:SetPoint("TOPLEFT",PBM.State.LichborneOverviewFrame,"TOPLEFT",col*ALL_COL_W,-(46+rowInCol*RH_ALL))
        rf:SetSize(ALL_COL_W, RH_ALL); rf:SetFrameLevel(fl+11)
        local rbg=rf:CreateTexture(nil,"BACKGROUND"); rbg:SetAllPoints(rf)
        rbg:SetTexture(rowInCol%2==0 and 0.06 or 0.04, rowInCol%2==0 and 0.08 or 0.06, rowInCol%2==0 and 0.16 or 0.12, 1)
        local allHov=rf:CreateTexture(nil,"OVERLAY"); allHov:SetAllPoints(rf); allHov:SetTexture(0,0,0,0)
        rf:EnableMouse(true)
        rf:SetScript("OnEnter", function() allHov:SetTexture(0.78, 0.61, 0.23, 0.12) end)
        rf:SetScript("OnLeave", function() allHov:SetTexture(0, 0, 0, 0) end)

        -- Row number
        local nl=rf:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); nl:SetPoint("LEFT",rf,"LEFT",2,0); nl:SetWidth(18); nl:SetJustifyH("CENTER"); nl:SetTextColor(0.4,0.5,0.6); rf.numLbl=nl

        -- Class icon
        local cF=CreateFrame("Frame",nil,rf); cF:SetPoint("LEFT",rf,"LEFT",20,0); cF:SetSize(18,18)
        local cT=cF:CreateTexture(nil,"ARTWORK"); cT:SetAllPoints(cF); rf.classIcon=cT

        -- Spec icon
        local sF=CreateFrame("Button",nil,rf); sF:SetPoint("LEFT",rf,"LEFT",40,0); sF:SetSize(18,18)
        sF:SetFrameLevel(rf:GetFrameLevel()+4)
        sF:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        local sT=sF:CreateTexture(nil,"ARTWORK"); sT:SetAllPoints(sF); rf.specIcon=sT

        -- Name editbox
        local nb=CreateFrame("EditBox",nil,rf); nb:SetPoint("LEFT",rf,"LEFT",60,0); nb:SetSize(128,RH_ALL-2)
        nb:SetAutoFocus(false); nb:SetMaxLetters(32); nb:EnableKeyboard(false); nb:EnableMouse(false)
        nb:SetFont("Fonts\\FRIZQT__.TTF",10); nb:SetTextColor(0.9,0.95,1.0)
        nb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        nb:SetBackdropColor(0.05,0.07,0.14,0.6); nb:SetBackdropBorderColor(0.12,0.18,0.30,0.5)
        rf.nameBox=nb

        -- iLvl editbox
        local gb=CreateFrame("EditBox",nil,rf); gb:SetPoint("LEFT",rf,"LEFT",190,0); gb:SetSize(36,RH_ALL-2)
        gb:SetAutoFocus(false); gb:SetMaxLetters(5); gb:EnableKeyboard(false)
        gb:SetFont("Fonts\\FRIZQT__.TTF",10,"OUTLINE"); gb:SetTextColor(0.831, 0.686, 0.216); gb:SetJustifyH("CENTER")
        gb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        gb:SetBackdropColor(0.05,0.07,0.14,0.6); gb:SetBackdropBorderColor(0.12,0.18,0.30,0.5)
        gb:SetScript("OnEditFocusGained", function(self) self:ClearFocus() end)
        rf.gsBox=gb
        gb:SetScript("OnEnter", function() allHov:SetTexture(0.78, 0.61, 0.23, 0.12) end)
        gb:SetScript("OnLeave", function() if GetMouseFocus()~=rf then allHov:SetTexture(0,0,0,0) end end)

        -- GS editbox
        local rgb=CreateFrame("EditBox",nil,rf); rgb:SetPoint("LEFT",rf,"LEFT",228,0); rgb:SetSize(36,RH_ALL-2)
        rgb:SetAutoFocus(false); rgb:SetMaxLetters(5); rgb:EnableKeyboard(false)
        rgb:SetFont("Fonts\\FRIZQT__.TTF",10,"OUTLINE"); rgb:SetTextColor(0.831, 0.686, 0.216); rgb:SetJustifyH("CENTER")
        rgb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        rgb:SetBackdropColor(0.05,0.07,0.14,0.6); rgb:SetBackdropBorderColor(0.12,0.18,0.30,0.5)
        rgb:SetScript("OnEditFocusGained", function(self) self:ClearFocus() end)
        rf.realGsBox=rgb
        rgb:SetScript("OnEnter", function() allHov:SetTexture(0.78, 0.61, 0.23, 0.12) end)
        rgb:SetScript("OnLeave", function() if GetMouseFocus()~=rf then allHov:SetTexture(0,0,0,0) end end)

        -- Role display - 3 icons (Tank/Healer/DPS), read-only, auto-populated
        local roleArea = CreateFrame("Button",nil,rf)
        roleArea:SetPoint("LEFT",rf,"LEFT",266,0); roleArea:SetSize(36,RH_ALL-2)
        roleArea:SetFrameLevel(rf:GetFrameLevel()+6)
        roleArea:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        roleArea:SetBackdropColor(0.05,0.07,0.14,0.8); roleArea:SetBackdropBorderColor(0.20,0.30,0.50,0.4)
        roleArea:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        roleArea:SetScript("OnEnter", function()
            GameTooltip:SetOwner(roleArea, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Role",1,1,1)
            local roleLabels = { T={"Tank",0.20,0.60,1.00}, H={"Healer",0.20,1.00,0.40}, D={"DPS",1.00,0.40,0.20}, A={"AoE",0.58,0.51,0.79} }
            for _, k in ipairs({"T","H","D","A"}) do
                local v = roleLabels[k]
                local icon = PBM.NOTES_ROLE_ICONS and PBM.NOTES_ROLE_ICONS[k] or ""
                GameTooltip:AddLine("|T"..icon..":14:14|t  "..v[1], v[2], v[3], v[4])
            end
            GameTooltip:Show()
        end)
        roleArea:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rf.roleSlots = {}
        for si = 1, 2 do
            local tex = roleArea:CreateTexture(nil,"ARTWORK")
            tex:SetPoint("LEFT",roleArea,"LEFT",(si-1)*18+1,0)
            tex:SetSize(16,16)
            tex:SetAlpha(0)
            rf.roleSlots[si] = tex
        end

        -- Add to Group btn >
        -- Add to Raid btn + (first)
        local ar=CreateFrame("Button",nil,rf); ar:SetPoint("LEFT",rf,"LEFT",312,0); ar:SetSize(16,RH_ALL-2)
        ar:SetNormalFontObject("GameFontNormalSmall"); ar:SetText("|cff44ff44+|r")
        ar:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        ar:SetScript("OnEnter",function()
            local raidName = LichborneTrackerDB.raidName or "?"
            local raidAbbr = PBM.RAID_ABBR and PBM.RAID_ABBR[raidName] or raidName
            local tier = LichborneTrackerDB.raidTier or 0
            local tierStr = tier > 0 and ("T"..tier) or "T0"
            local grp = LichborneTrackerDB.raidGroup or "A"
            GameTooltip:SetOwner(ar,"ANCHOR_RIGHT")
            GameTooltip:AddLine("|cff44ff44+ Add to Raid|r", 1, 1, 1)
            GameTooltip:AddLine("Adds to the Raid tab.", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cff44ff44Left-click to add to raid.|r", 1, 1, 1)
            GameTooltip:AddLine("|cffff2020Right-click to remove.|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        ar:SetScript("OnLeave",function() GameTooltip:Hide() end)
        ar:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        rf.addRaidBtn=ar

        -- Invite to group btn > (second)
        local ag=CreateFrame("Button",nil,rf); ag:SetPoint("LEFT",rf,"LEFT",330,0); ag:SetSize(16,RH_ALL-2)
        ag:SetNormalFontObject("GameFontNormalSmall"); ag:SetText("|cff44eeff>|r")
        ag:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        ag:SetScript("OnEnter",function()
            GameTooltip:SetOwner(ag,"ANCHOR_RIGHT")
            GameTooltip:AddLine("|cff44eeff> Invite to Group|r",1,1,1)
            GameTooltip:AddLine("|cff44ff44Left-click to invite to group.|r",1,1,1)
            GameTooltip:AddLine("|cffff2020Right-click to remove.|r",1,1,1)
            GameTooltip:Show()
        end)
        ag:SetScript("OnLeave",function() GameTooltip:Hide() end)
        rf.addGroupBtn=ag

        -- Delete btn x (third)
        local dx=CreateFrame("Button",nil,rf); dx:SetPoint("LEFT",rf,"LEFT",348,0); dx:SetSize(16,RH_ALL-2)
        dx:SetNormalFontObject("GameFontNormalSmall"); dx:SetText("|cffaa2222x|r")
        dx:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        dx:SetScript("OnEnter",function()
            GameTooltip:SetOwner(dx,"ANCHOR_RIGHT")
            GameTooltip:AddLine("Delete Character",1,0.3,0.3)
            GameTooltip:AddLine("Removes from tracker.",0.8,0.8,0.8)
            GameTooltip:Show()
        end)
        dx:SetScript("OnLeave",function() GameTooltip:Hide() end)
        rf.allDelBtn=dx

        -- Hook child elements to propagate row highlight
        PBM.HookRowHighlight(ag, rf, allHov)
        PBM.HookRowHighlight(ar, rf, allHov)
        PBM.HookRowHighlight(dx, rf, allHov)
        if rf.specBtn then PBM.HookRowHighlight(rf.specBtn, rf, allHov) end

        -- Wire delete button in RefreshOverviewRows (needs dbIndex set first)
        rf.allDelBtnFrame = dx

        -- Divider
        local ln=rf:CreateTexture(nil,"OVERLAY"); ln:SetHeight(1); ln:SetWidth(ALL_COL_W)
        ln:SetPoint("BOTTOMLEFT",rf,"BOTTOMLEFT",0,0); ln:SetTexture(0.10,0.16,0.28,0.4)

        PBM.State.overviewRowFrames[i]=rf
    end

    -- Count bar at bottom
    local cbY = -(46 + ALL_PER_COL*RH_ALL + 2)  -- below last row
    local allCB = CreateFrame("Frame","LichborneOverviewCountBar",PBM.State.LichborneOverviewFrame)
    allCB:SetPoint("TOPLEFT",PBM.State.LichborneOverviewFrame,"TOPLEFT",0,cbY)
    allCB:SetSize(ALL_NCOLS*ALL_COL_W,24); allCB:SetFrameLevel(fl+11)
    local acbBg=allCB:CreateTexture(nil,"BACKGROUND"); acbBg:SetAllPoints(allCB); acbBg:SetTexture(0.05,0.07,0.13,1)
    local acT=allCB:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); acT:SetPoint("LEFT",allCB,"LEFT",4,0); acT:SetText("|cffC69B3ACount:|r"); acT:SetWidth(44)
    PBM.State.LichborneAllCountLabels={}
    local acW=(ALL_NCOLS*ALL_COL_W-50)/10
    for ci,cls in ipairs(PBM.CLASS_TABS) do
        if cls=="Raid" or cls=="All" then break end
        local c=PBM.CLASS_COLORS[cls]
        local sw=CreateFrame("Button",nil,allCB); sw:SetSize(acW-2,20); sw:SetPoint("LEFT",allCB,"LEFT",48+(ci-1)*acW,0)
        sw:SetFrameLevel(allCB:GetFrameLevel()+1)
        local sbg=sw:CreateTexture(nil,"BACKGROUND"); sbg:SetAllPoints(sw); sbg:SetTexture(0.08,0.10,0.18,1); sw.bg=sbg
        local hex=string.format("|cff%02x%02x%02x",math.floor(c.r*255),math.floor(c.g*255),math.floor(c.b*255))
        local sl=sw:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sl:SetAllPoints(sw); sl:SetJustifyH("CENTER"); sl:SetJustifyV("MIDDLE")
        sl:SetText(hex..(PBM.TAB_LABELS[cls])..": "..hex.."0|r"); sw.lbl=sl; PBM.State.LichborneAllCountLabels[cls]=sl
    end
end
