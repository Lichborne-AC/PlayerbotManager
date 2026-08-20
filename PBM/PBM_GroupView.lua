PBM = PBM or {}
PBM.State = PBM.State or {}

PBM.State.groupViewActive    = PBM.State.groupViewActive    or false
PBM.State.groupViewFrame     = PBM.State.groupViewFrame     or nil
PBM.State.groupViewBuilt     = PBM.State.groupViewBuilt     or false
PBM.State.groupViewRowFrames = PBM.State.groupViewRowFrames or {}
PBM.State.gvScrollOffset     = PBM.State.gvScrollOffset     or 0
PBM.State.gvMembers          = PBM.State.gvMembers          or {}
PBM.State.gvFilterIcon       = PBM.State.gvFilterIcon       or nil
PBM.State.gvSortKey          = PBM.State.gvSortKey          or nil
PBM.State.gvSortAsc          = PBM.State.gvSortAsc          or true
PBM.State.gvSortHdrs         = PBM.State.gvSortHdrs         or {}

PBM.State.gvAvgSwatches    = PBM.State.gvAvgSwatches    or {}  -- [cls] = fontstring (iLvL bar)
PBM.State.gvGsSwatches     = PBM.State.gvGsSwatches     or {}  -- [cls] = fontstring (GS bar)
PBM.State.gvGroupIlvlLabel = PBM.State.gvGroupIlvlLabel or nil
PBM.State.gvGroupGsLabel   = PBM.State.gvGroupGsLabel   or nil

-- ── Drag-to-reorder state (mirrors the Raid tab) ─────────────────
-- Manual order is persisted per-name in LichborneTrackerDB.gvManualOrder so it
-- survives refreshes and relogs; new group members append to the end.
local gvDragPoll   = CreateFrame("Frame")
local gvMouseHeld  = false
local gvDragSource = nil   -- visible row index (1..GV_VISIBLE) being dragged

-- ── GV-specific column layout (mirrors class tab constants) ─────
local GV_RH        = 22   -- row height; 20 rows then the two avg bars (flush, no gap)
local GV_VISIBLE   = 20
local GV_NUM_OFF   = 0;   local GV_NUM_W   = 18
local GV_SPEC_OFF  = 20;  local GV_SPEC_W  = 22   -- PBM.SPEC_OFF / PBM.COL_SPEC_W-2
local GV_NAME_OFF  = 50;  local GV_NAME_W  = 96   -- PBM.NAME_OFF / PBM.COL_NAME_W-44
local GV_ILVL_OFF  = 150; local GV_ILVL_W  = 40   -- PBM.GS_OFF / PBM.COL_GS_W-2
local GV_GS_OFF    = 194; local GV_GS_W    = 40   -- PBM.REALGS_OFF / PBM.COL_GS_W-2
local GV_PROF_OFF  = 238; local GV_PROF_W  = PBM.COL_NEEDS_W  -- 42, PBM.NEEDS_OFF
-- 17 slots × step44 = 748px; 282+748=1030 < 1086 row width.  +Raid at RIGHT-36, >Group at RIGHT-20, x at RIGHT-2.
local GV_GEAR_OFF  = 282  -- PBM.GEAR_OFF
local GV_GEAR_STEP = 44   -- PBM.COL_GEAR_W
local GV_GEAR_BSIZ = 42   -- PBM.COL_GEAR_W-2

-- ── Build + sort the live member list ────────────────────────────
local function BuildGVMemberList()
    local gnames = PBM.GetGroupMemberNameSet()
    local names  = {}
    for name in pairs(gnames) do names[#names + 1] = name end
    table.sort(names)  -- base alphabetical

    local dbLookup = {}
    for idx, r in ipairs(LichborneTrackerDB.rows or {}) do
        if r.name and r.name ~= "" then dbLookup[r.name:lower()] = { data = r, idx = idx } end
    end

    local out = {}
    for _, name in ipairs(names) do
        local entry = dbLookup[name:lower()]
        out[#out + 1] = { name = name, data = entry and entry.data, dbIndex = entry and entry.idx }
    end

    local key = PBM.State.gvSortKey
    local asc = PBM.State.gvSortAsc
    if key then
        table.sort(out, function(a, b)
            local ad, bd = a.data, b.data
            if key == "cls" then
                local ac = ad and ad.cls  or "";  local bc = bd and bd.cls  or ""
                if ac ~= bc then
                    if asc then return ac < bc else return ac > bc end
                end
                local as2 = ad and ad.spec or "";  local bs2 = bd and bd.spec or ""
                if as2 ~= bs2 then return as2 < bs2 end
            elseif key == "name" then
                if a.name ~= b.name then
                    if asc then return a.name < b.name else return a.name > b.name end
                end
                return false
            elseif key == "ilvl" then
                local av = ad and (ad.gs    or 0) or 0
                local bv = bd and (bd.gs    or 0) or 0
                if av ~= bv then
                    if asc then return av < bv else return av > bv end
                end
            elseif key == "gs" then
                local av = ad and (ad.realGs or 0) or 0
                local bv = bd and (bd.realGs or 0) or 0
                if av ~= bv then
                    if asc then return av < bv else return av > bv end
                end
            elseif key == "role" then
                local ROLE_ORDER = {T=1, H=2, D=3, A=3}
                local function getRank(e)
                    local bn = LichborneTrackerDB.botNotes and e.name and LichborneTrackerDB.botNotes[e.name:lower()]
                    local primary = bn and bn.roles and bn.roles[1]
                    return ROLE_ORDER[primary or ""] or 4
                end
                local ra, rb2 = getRank(a), getRank(b)
                if ra ~= rb2 then
                    if asc then return ra < rb2 else return ra > rb2 end
                end
            else
                local gIdx = tonumber(key:sub(6))
                if gIdx then
                    local av = ad and ad.ilvl and ad.ilvl[gIdx] or 0
                    local bv = bd and bd.ilvl and bd.ilvl[gIdx] or 0
                    if av ~= bv then
                        if asc then return av < bv else return av > bv end
                    end
                end
            end
            return a.name < b.name  -- stable tie-break
        end)
    else
        -- No column sort active: honour the saved manual (drag) order.
        local order = LichborneTrackerDB.gvManualOrder
        if order and #order > 0 then
            local rank = {}
            for ri, nm in ipairs(order) do if not rank[nm] then rank[nm] = ri end end
            table.sort(out, function(a, b)
                local ra = rank[a.name:lower()]
                local rb = rank[b.name:lower()]
                if ra and rb then return ra < rb end
                if ra then return true end      -- ordered names come before new/unknown
                if rb then return false end
                return a.name < b.name           -- both unknown → alphabetical
            end)
        end
    end

    PBM.State.gvMembers = out
end

-- Persist the current displayed order so it survives refreshes/relogs
local function SaveGVManualOrder()
    local order = {}
    for _, m in ipairs(PBM.State.gvMembers or {}) do
        if m.name then order[#order+1] = m.name:lower() end
    end
    LichborneTrackerDB.gvManualOrder = order
end

-- ── Populate the 20 visible rows from the current offset ─────────
function PBM.RefreshGroupViewRows()
    if not PBM.State.groupViewFrame then return end

    local members = PBM.State.gvMembers
    local total   = #members
    local maxOff  = math.max(0, total - GV_VISIBLE)
    PBM.State.gvScrollOffset = math.max(0, math.min(PBM.State.gvScrollOffset, maxOff))
    local offset  = PBM.State.gvScrollOffset

    for i = 1, GV_VISIBLE do
        local rf    = PBM.State.groupViewRowFrames[i]
        if not rf then break end

        local entry = members[offset + i]
        local name  = entry and entry.name
        local data  = entry and entry.data
        local hasDb = data ~= nil

        rf.charName = name
        rf.dbIndex  = entry and entry.dbIndex or nil

        -- Row number (or level / IP tier when those filters are active)
        if name then
            if PBM.State.LBFilter.showIP then
                local ipVal = LichborneTrackerDB.ipData and LichborneTrackerDB.ipData[name:lower()]
                if ipVal then
                    rf.numLbl:SetText(tostring(ipVal))
                    rf.numLbl:SetTextColor(0.83, 0.69, 0.22)
                else
                    rf.numLbl:SetText("")
                end
            elseif PBM.State.LBFilter.showLevel then
                local lvl = data and (data.level or 0) or 0
                if lvl > 0 then
                    rf.numLbl:SetText(tostring(lvl))
                    rf.numLbl:SetTextColor(0.83, 0.69, 0.22)
                else
                    rf.numLbl:SetText("")
                end
            else
                rf.numLbl:SetText(tostring(offset + i))
                rf.numLbl:SetTextColor(0.4, 0.5, 0.6)
            end
        else
            rf.numLbl:SetText("")
        end

        -- Spec icon
        local spec    = hasDb and data.spec or ""
        local specTex = spec ~= "" and PBM.SPEC_ICONS[spec]
        if specTex then
            rf.specIcon:SetTexture(specTex); rf.specIcon:SetAlpha(1.0)
        elseif hasDb then
            rf.specIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); rf.specIcon:SetAlpha(0.25)
        else
            rf.specIcon:SetAlpha(0)
        end

        -- Name (class-coloured)
        local cls = hasDb and data.cls or ""
        rf.nameBox:SetText(name or "")
        local c = cls ~= "" and PBM.CLASS_COLORS[cls]
        if c then rf.nameBox:SetTextColor(c.r, c.g, c.b)
        else      rf.nameBox:SetTextColor(0.9, 0.95, 1.0) end

        -- iLvl / GS
        local gs  = hasDb and (data.gs    or 0) or 0
        local rgs = hasDb and (data.realGs or 0) or 0
        rf.gsBox:SetText(gs  > 0 and tostring(gs)  or "")
        rf.realGsBox:SetText(rgs > 0 and tostring(rgs) or "")

        -- Prof cell
        if rf.profCell then PBM.RefreshProfCell(rf.profCell, name or "") end

        -- +Raid button
        if rf.addRaidBtn then
            local di = rf.dbIndex
            if di and hasDb and data.name and data.name ~= "" then
                if PBM.IsInActiveRaid and PBM.IsInActiveRaid(data.name) then
                    rf.addRaidBtn:SetText("|cffb25b00+|r")
                else
                    rf.addRaidBtn:SetText("|cff44ff44+|r")
                end
                rf.addRaidBtn:SetScript("OnClick", function(self, btn)
                    local srcData = di and LichborneTrackerDB.rows[di]
                    if not srcData or not srcData.name or srcData.name == "" then return end
                    local clr = PBM.CLASS_COLORS[srcData.cls]
                    local hex = clr and string.format("|cff%02x%02x%02x", math.floor(clr.r*255), math.floor(clr.g*255), math.floor(clr.b*255)) or "|cffffffff"
                    if btn == "RightButton" then
                        local roster = PBM.GetCurrentRoster()
                        for ri = 1, PBM.MAX_RAID_SLOTS do
                            if roster[ri] and roster[ri].name and roster[ri].name:lower() == srcData.name:lower() then
                                roster[ri] = {name="", cls="", spec="", gs=0, realGs=0, role="", notes=""}
                                rf.addRaidBtn:SetText("|cff44ff44+|r")
                                if LichborneAddStatus then LichborneAddStatus:SetText(hex..srcData.name.."|r" .. PBM_L[" removed from raid slot "] .. ri..".") end
                                if LichborneRaidFrame then PBM.RefreshRaidRows() end
                                return
                            end
                        end
                        return
                    end
                    local roster2 = PBM.GetCurrentRoster()
                    for ri = 1, PBM.MAX_RAID_SLOTS do
                        if not roster2[ri] or roster2[ri].name == "" then
                            roster2[ri] = {name=srcData.name, cls=srcData.cls or "", spec=srcData.spec or "", gs=srcData.gs or 0, realGs=srcData.realGs or 0, role="", notes=""}
                            LichborneOutput("|cffC69B3APBM:|r Added "..hex..srcData.name.."|r" .. PBM_L[" added to raid slot "] .. ri..".", 1, 0.85, 0)
                            if LichborneAddStatus then LichborneAddStatus:SetText(hex..srcData.name.."|r" .. PBM_L[" added to raid slot "] .. ri..".") end
                            rf.addRaidBtn:SetText("|cffb25b00+|r")
                            if LichborneRaidFrame then PBM.RefreshRaidRows() end
                            return
                        end
                    end
                    if LichborneAddStatus then LichborneAddStatus:SetText("|cffff6666" .. PBM_L["Raid roster is full."] .. "|r") end
                end)
                rf.addRaidBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            else
                rf.addRaidBtn:SetText("|cff44ff44+|r")
                rf.addRaidBtn:SetScript("OnClick", nil)
            end
        end

        -- Gear boxes
        for g = 1, PBM.GEAR_SLOTS do
            local gb   = rf.gearBoxes[g]
            local val  = hasDb and data.ilvl     and data.ilvl[g]     or 0
            local link = hasDb and data.ilvlLink and data.ilvlLink[g] or nil
            gb:SetText((val > 0 or (link and link ~= "")) and tostring(val) or "")
            local qc = PBM.GetItemQualityColor(link)
            if qc then gb:SetTextColor(qc.r, qc.g, qc.b)
            else
                if link and link ~= "" then GetItemInfo(link) end
                gb:SetTextColor(1, 1, 1)
            end
        end

        -- >Group click
        rf.addGroupBtn:SetScript("OnClick", function(self, btn)
            local cn = rf.charName; if not cn then return end
            local d
            for _, r in ipairs(LichborneTrackerDB.rows or {}) do
                if r.name and r.name:lower() == cn:lower() then d = r; break end
            end
            if not d then return end
            local clr = d.cls and PBM.CLASS_COLORS[d.cls]
            local hex = clr and string.format("|cff%02x%02x%02x",math.floor(clr.r*255),math.floor(clr.g*255),math.floor(clr.b*255)) or "|cffffffff"
            if btn == "RightButton" then
                UninviteUnit(d.name)
                SendChatMessage(".playerbots bot remove "..d.name, "SAY")
                LichborneOutput("|cffC69B3APBM:|r" .. PBM_L[" Removed "] ..hex..d.name.."|r" .. PBM_L[" from bots."], 1, 0.85, 0)
                return
            end
            SendChatMessage(".playerbots bot add "..d.name, "SAY")
            if LichborneAddStatus then LichborneAddStatus:SetText(PBM_L["Invited "] ..hex..d.name.."|r" .. PBM_L[" to group."]) end
        end)

        -- x Delete click — removes character from tracker (mirrors class tabs)
        if rf.delBtn then
            local di = rf.dbIndex
            if di and hasDb and data.name and data.name ~= "" then
                rf.delBtn:SetScript("OnClick", function()
                    local srcData = LichborneTrackerDB.rows[di]
                    if not srcData or not srcData.name or srcData.name == "" then return end
                    PBM.RemoveCharacterReferences(srcData.name)
                    PBM.RefreshGroupViewRows()
                    if PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames > 0 then PBM.RefreshOverviewRows() end
                end)
            else
                rf.delBtn:SetScript("OnClick", nil)
            end
        end

        rf:Show()
    end

    -- Keep the Avg iLvL / Avg GS bars in sync with the current group
    if PBM.UpdateGroupSummary then PBM.UpdateGroupSummary() end
end

-- ── Build the group-view frame (called lazily on first toggle) ────
function PBM.BuildGroupView(parent, fl)
    if PBM.State.groupViewBuilt then return end
    PBM.State.groupViewBuilt = true

    local totalW = PBM.ALL_NCOLS * PBM.ALL_COL_W  -- 1086
    local RH     = GV_RH

    local gvf = CreateFrame("Frame", "LichborneGroupViewFrame", parent)
    gvf:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -66)
    gvf:SetSize(totalW, 516)  -- colHdr(18)+gap(2)+20rows(440)+bar1(24)+gap(2)+bar2(24)+buffer(6)
    gvf:SetFrameLevel(fl + 10)
    gvf:Hide()
    PBM.State.groupViewFrame = gvf

    -- ── Column headers (no title bar — mirrors class tab style) ─────
    local colHdr = CreateFrame("Frame", nil, gvf)
    colHdr:SetPoint("TOPLEFT", gvf, "TOPLEFT", 0, 0)
    colHdr:SetSize(totalW, 18); colHdr:SetFrameLevel(fl + 11)
    local chBg = colHdr:CreateTexture(nil, "BACKGROUND")
    chBg:SetAllPoints(colHdr); chBg:SetTexture(0.08, 0.20, 0.42, 1)

    local function H(txt, x, w)
        local fs = colHdr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", colHdr, "LEFT", x, 0); fs:SetWidth(w); fs:SetJustifyH("CENTER")
        fs:SetText("|cffd4af37" .. txt .. "|r")
    end

    local function UpdateGVSortHeaders()
        for k, entry in pairs(PBM.State.gvSortHdrs) do
            if k == PBM.State.gvSortKey then
                local arrow = PBM.State.gvSortAsc and " ^" or " v"
                entry.fs:SetText("|cffd4af37" .. entry.lbl .. arrow .. "|r")
            else
                entry.fs:SetText("|cffd4af37" .. entry.lbl .. "|r")
            end
        end
    end
    PBM.State.UpdateGVSortHeaders = UpdateGVSortHeaders

    local function SH(lbl, x, w, key, isNumeric)
        local btn = CreateFrame("Button", nil, colHdr)
        btn:SetPoint("TOPLEFT", colHdr, "TOPLEFT", x, 0)
        btn:SetSize(w, 18); btn:SetFrameLevel(colHdr:GetFrameLevel() + 1)
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("CENTER", btn, "CENTER", 0, 0); fs:SetSize(w + 6, 18)
        fs:SetJustifyH("CENTER"); fs:SetJustifyV("MIDDLE")
        fs:SetText("|cffd4af37" .. lbl .. "|r")
        PBM.State.gvSortHdrs[key] = { lbl = lbl, fs = fs }
        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:AddLine(PBM_L["Click to sort"], 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function()
            if PBM.State.gvSortKey == key then
                PBM.State.gvSortAsc = not PBM.State.gvSortAsc
            else
                PBM.State.gvSortKey = key
                PBM.State.gvSortAsc = not isNumeric
            end
            UpdateGVSortHeaders()
            BuildGVMemberList()
            PBM.State.gvScrollOffset = 0
            PBM.RefreshGroupViewRows()
        end)
    end

    H("#",       GV_NUM_OFF,  GV_NUM_W)
    SH(PBM_L["Spec"],   GV_SPEC_OFF, GV_NAME_OFF - GV_SPEC_OFF,      "cls",  false)
    SH(PBM_L["Name"],   GV_NAME_OFF, GV_NAME_W,                      "name", false)
    SH(PBM_L["iLvL"],   GV_ILVL_OFF, GV_ILVL_W,                     "ilvl", true)
    SH(PBM_L["GS"],     GV_GS_OFF,   GV_GS_W,   "gs",   true)
    H(PBM_L["Prof"],    GV_PROF_OFF, GV_PROF_W)
    for g = 1, PBM.GEAR_SLOTS do
        SH(PBM.SLOT_ABBR[g] or tostring(g), GV_GEAR_OFF + (g-1)*GV_GEAR_STEP, GV_GEAR_BSIZ, "gear_"..g, true)
    end

    -- Refresh button — sits in the column header above the + > x buttons
    local refreshBtn = CreateFrame("Button", nil, colHdr)
    refreshBtn:SetSize(52, 16)
    refreshBtn:SetPoint("RIGHT", colHdr, "RIGHT", -2, 0)
    refreshBtn:SetFrameLevel(colHdr:GetFrameLevel() + 1)
    refreshBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    refreshBtn:SetBackdropColor(0.10, 0.08, 0.02, 1)
    refreshBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    refreshBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local refreshLbl = refreshBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    refreshLbl:SetAllPoints(refreshBtn); refreshLbl:SetJustifyH("CENTER"); refreshLbl:SetJustifyV("MIDDLE")
    refreshLbl:SetText("|cffd4af37" .. PBM_L["Refresh"] .. "|r")
    refreshBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(refreshBtn, "ANCHOR_TOP")
        GameTooltip:AddLine(PBM_L["Refresh Group"], 0.78, 0.61, 0.23)
        GameTooltip:AddLine(PBM_L["Rebuild the member list from your current group."], 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    refreshBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    refreshBtn:SetScript("OnClick", function() PBM.OpenGroupView() end)

    -- ── Mousewheel ───────────────────────────────────────────────
    local function GVScroll(delta)
        local onGroupTab    = PBM.State.activeTab == "Group"
        local onOverviewGV  = PBM.State.activeTab == "Overview" and PBM.State.groupViewActive
        if not onGroupTab and not onOverviewGV then return end
        local maxOff = math.max(0, #PBM.State.gvMembers - GV_VISIBLE)
        PBM.State.gvScrollOffset = math.max(0, math.min(PBM.State.gvScrollOffset - delta, maxOff))
        PBM.RefreshGroupViewRows()
    end
    gvf:EnableMouseWheel(true)
    gvf:SetScript("OnMouseWheel", function(_, delta) GVScroll(delta) end)

    -- ── 20 static row frames ─────────────────────────────────────
    local yStart = -20
    for i = 1, GV_VISIBLE do
        local rf = CreateFrame("Frame", "LichborneGVRow" .. i, gvf)
        rf:SetPoint("TOPLEFT", gvf, "TOPLEFT", 0, yStart - (i-1)*RH)
        rf:SetSize(totalW, RH); rf:SetFrameLevel(fl + 12)

        local rbg = rf:CreateTexture(nil, "BACKGROUND"); rbg:SetAllPoints(rf)
        rbg:SetTexture(i%2==0 and 0.04 or 0.06, i%2==0 and 0.06 or 0.08, i%2==0 and 0.12 or 0.16, 1)

        local hov = rf:CreateTexture(nil, "OVERLAY"); hov:SetAllPoints(rf); hov:SetTexture(0,0,0,0)
        rf.hov = hov
        local gvDropHi = rf:CreateTexture(nil, "OVERLAY"); gvDropHi:SetAllPoints(rf); gvDropHi:SetTexture(0,0,0,0)
        rf.gvDropHi = gvDropHi
        rf:EnableMouse(true)
        rf:SetScript("OnEnter", function() if not gvDragSource then hov:SetTexture(0.78, 0.61, 0.23, 0.12) end end)
        rf:SetScript("OnLeave", function() if not gvDragSource then hov:SetTexture(0, 0, 0, 0) end end)
        rf:EnableMouseWheel(true)
        rf:SetScript("OnMouseWheel", function(_, delta) GVScroll(delta) end)

        -- Row number
        local nl = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nl:SetPoint("LEFT", rf, "LEFT", GV_NUM_OFF, 0); nl:SetWidth(GV_NUM_W); nl:SetJustifyH("CENTER")
        nl:SetTextColor(0.4, 0.5, 0.6)
        rf.numLbl = nl

        -- Drag handle (over the # column) — drag to reorder the group list
        local rowI = i
        local dragBtn = CreateFrame("Button", nil, rf)
        dragBtn:SetPoint("LEFT", rf, "LEFT", GV_NUM_OFF, 0); dragBtn:SetSize(GV_NUM_W, RH)
        dragBtn:SetFrameLevel(rf:GetFrameLevel()+5)
        local dragTex = dragBtn:CreateTexture(nil, "ARTWORK"); dragTex:SetAllPoints(dragBtn)
        dragTex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        dragTex:SetVertexColor(0.2,0.3,0.5,0)
        dragBtn:SetScript("OnEnter", function()
            if not gvDragSource and rf.charName then
                dragTex:SetVertexColor(0.9,0.7,0.1,1.0)
                GameTooltip:SetOwner(dragBtn,"ANCHOR_RIGHT")
                GameTooltip:AddLine(PBM_L["Drag to reorder"],1,1,1)
                GameTooltip:Show()
            end
        end)
        dragBtn:SetScript("OnLeave", function()
            if not gvDragSource then dragTex:SetVertexColor(0.2,0.3,0.5,0) end
            GameTooltip:Hide()
        end)
        dragBtn:SetScript("OnMouseDown", function(_, mouseButton)
            if mouseButton == "LeftButton" and rf.charName then
                gvDragSource = rowI
                gvMouseHeld = true
                dragTex:SetVertexColor(0.9,0.7,0.1,1.0)
                hov:SetTexture(0.9,0.7,0.1,0.12)
            end
        end)
        dragBtn:SetScript("OnMouseUp", function() gvMouseHeld = false end)
        dragBtn:EnableMouseWheel(true); dragBtn:SetScript("OnMouseWheel", function(_, d) GVScroll(d) end)
        rf.gvDragTex = dragTex

        -- Spec icon
        local sF = CreateFrame("Frame", nil, rf)
        sF:SetPoint("LEFT", rf, "LEFT", GV_SPEC_OFF, 0); sF:SetSize(GV_SPEC_W, GV_SPEC_W)
        local sT = sF:CreateTexture(nil, "ARTWORK"); sT:SetAllPoints(sF); sT:SetAlpha(0)
        rf.specIcon = sT

        -- Name box (read-only display)
        local nb = CreateFrame("EditBox", nil, rf)
        nb:SetPoint("LEFT", rf, "LEFT", GV_NAME_OFF, 0); nb:SetSize(GV_NAME_W, RH-4)
        nb:SetAutoFocus(false); nb:SetMaxLetters(32); nb:EnableKeyboard(false); nb:EnableMouse(false)
        nb:SetFont("Fonts\\FRIZQT__.TTF", 11); nb:SetTextColor(0.9, 0.95, 1.0)
        nb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
        nb:SetBackdropColor(0.05,0.07,0.14,0.8); nb:SetBackdropBorderColor(0.15,0.22,0.38,0.7)
        rf.nameBox = nb

        -- Transparent button over name box — opens char sheet on click (same as class tabs)
        local nameBtn = CreateFrame("Button", nil, rf)
        nameBtn:SetPoint("LEFT", rf, "LEFT", GV_NAME_OFF, 0)
        nameBtn:SetSize(GV_NAME_W, RH)
        nameBtn:SetFrameLevel(nb:GetFrameLevel() + 2)
        nameBtn:SetScript("OnClick", function()
            if not rf.dbIndex then return end
            if PBM.State.LBFilter and PBM.State.LBFilter.gvCharSheet == false then return end
            PBM.OpenNameMenu(rf)
        end)
        nameBtn:SetScript("OnEnter", function()
            hov:SetTexture(0.78, 0.61, 0.23, 0.12)
        end)
        nameBtn:SetScript("OnLeave", function()
            hov:SetTexture(0, 0, 0, 0)
            GameTooltip:Hide()
        end)
        nameBtn:EnableMouseWheel(true)
        nameBtn:SetScript("OnMouseWheel", function(_, d) GVScroll(d) end)
        rf.nameBtn = nameBtn

        -- iLvl
        local gsb = CreateFrame("EditBox", nil, rf)
        gsb:SetPoint("LEFT", rf, "LEFT", GV_ILVL_OFF, 0); gsb:SetSize(GV_ILVL_W, RH-4)
        gsb:SetAutoFocus(false); gsb:SetMaxLetters(5); gsb:EnableKeyboard(false)
        gsb:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE"); gsb:SetTextColor(0.831,0.686,0.216); gsb:SetJustifyH("CENTER")
        gsb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        gsb:SetBackdropColor(0.05,0.07,0.14,1); gsb:SetBackdropBorderColor(0.12,0.18,0.30,0.8)
        gsb:SetScript("OnEditFocusGained", function(self) self:ClearFocus() end)
        gsb:EnableMouseWheel(true); gsb:SetScript("OnMouseWheel", function(_, d) GVScroll(d) end)
        rf.gsBox = gsb

        -- GS
        local rgsb = CreateFrame("EditBox", nil, rf)
        rgsb:SetPoint("LEFT", rf, "LEFT", GV_GS_OFF, 0); rgsb:SetSize(GV_GS_W, RH-4)
        rgsb:SetAutoFocus(false); rgsb:SetMaxLetters(5); rgsb:EnableKeyboard(false)
        rgsb:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE"); rgsb:SetTextColor(0.831,0.686,0.216); rgsb:SetJustifyH("CENTER")
        rgsb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        rgsb:SetBackdropColor(0.05,0.07,0.14,1); rgsb:SetBackdropBorderColor(0.12,0.18,0.30,0.8)
        rgsb:SetScript("OnEditFocusGained", function(self) self:ClearFocus() end)
        rgsb:EnableMouseWheel(true); rgsb:SetScript("OnMouseWheel", function(_, d) GVScroll(d) end)
        rf.realGsBox = rgsb

        -- Prof cell (mirrors class tab behaviour — includes Role section in picker)
        rf.profCell = PBM.MakeProfCell(rf, GV_PROF_OFF, RH, function() return rf.charName or "" end, hov, GV_PROF_W)

        -- Gear boxes (shifted to GV_GEAR_OFF=350)
        rf.gearBoxes = {}
        for g = 1, PBM.GEAR_SLOTS do
            local gx  = GV_GEAR_OFF + (g-1)*GV_GEAR_STEP
            local gbb = CreateFrame("EditBox", "LichborneGVRow"..i.."Gear"..g, rf)
            gbb:SetPoint("LEFT", rf, "LEFT", gx, 0); gbb:SetSize(GV_GEAR_BSIZ, RH-2)
            gbb:SetAutoFocus(false); gbb:SetMaxLetters(3); gbb:SetNumeric(true); gbb:EnableKeyboard(false)
            gbb:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE"); gbb:SetTextColor(1,1,1); gbb:SetJustifyH("CENTER")
            gbb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
            gbb:SetBackdropColor(0.05,0.07,0.14,1); gbb:SetBackdropBorderColor(0.12,0.18,0.30,0.8)
            gbb:SetScript("OnEditFocusGained", function(self) self:ClearFocus() end)
            local glow = CreateFrame("Frame", nil, rf)
            glow:SetAllPoints(gbb); glow:SetFrameLevel(gbb:GetFrameLevel()+1)
            glow:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=6,insets={left=1,right=1,top=1,bottom=1}})
            glow:SetBackdropColor(0,0,0,0); glow:SetBackdropBorderColor(0,0,0,0); glow:EnableMouse(false)
            local slotIdx = g
            gbb:SetScript("OnEnter", function()
                hov:SetTexture(0.78, 0.61, 0.23, 0.12)
                glow:SetBackdropBorderColor(0.3,0.7,1.0,1.0); glow:SetBackdropColor(0.05,0.15,0.35,0.4)
                local cn = rf.charName; if not cn then return end
                local d
                for _, r in ipairs(LichborneTrackerDB.rows or {}) do
                    if r.name and r.name:lower() == cn:lower() then d = r; break end
                end
                local lnk = d and d.ilvlLink and d.ilvlLink[slotIdx]
                if lnk and lnk ~= "" then
                    GetItemInfo(lnk)
                    local anchor = (i <= 10) and "ANCHOR_BOTTOM" or "ANCHOR_TOP"
                    GameTooltip:SetOwner(gbb, anchor)
                    local ok = pcall(function() GameTooltip:SetHyperlink(lnk) end)
                    if ok then GameTooltip:Show() else GameTooltip:Hide() end
                end
            end)
            gbb:SetScript("OnLeave", function()
                if GetMouseFocus() ~= rf then hov:SetTexture(0,0,0,0) end
                glow:SetBackdropBorderColor(0,0,0,0); glow:SetBackdropColor(0,0,0,0)
                GameTooltip:Hide()
            end)
            gbb:EnableMouseWheel(true); gbb:SetScript("OnMouseWheel", function(_, d) GVScroll(d) end)
            rf.gearBoxes[g] = gbb
        end

        -- +Raid button (green +, mirrors class tabs; RIGHT-36)
        local arb = CreateFrame("Button", "LichborneGVRow"..i.."AddRaid", rf)
        arb:SetPoint("RIGHT", rf, "RIGHT", -36, 0); arb:SetSize(16, RH-2)
        arb:SetNormalFontObject("GameFontNormalSmall"); arb:SetText("|cff44ff44+|r")
        arb:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        arb:RegisterForClicks("LeftButtonUp","RightButtonUp")
        arb:SetScript("OnEnter", function()
            GameTooltip:SetOwner(arb, "ANCHOR_RIGHT")
            GameTooltip:AddLine("|cff44ff44" .. PBM_L["+ Add to Raid"] .. "|r",1,1,1)
            GameTooltip:AddLine(PBM_L["Adds character to the Raid tab."], 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cff44ff44" .. PBM_L["Left-click to add to raid."] .. "|r",1,1,1)
            GameTooltip:AddLine("|cffff2020" .. PBM_L["Right-click to remove."] .. "|r",1,1,1)
            GameTooltip:Show()
        end)
        arb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rf.addRaidBtn = arb
        PBM.HookRowHighlight(arb, rf, hov)

        -- >Group button (RIGHT-20)
        local agb = CreateFrame("Button", "LichborneGVRow"..i.."AddGroup", rf)
        agb:SetPoint("RIGHT", rf, "RIGHT", -20, 0); agb:SetSize(16, RH-2)
        agb:SetNormalFontObject("GameFontNormalSmall"); agb:SetText("|cff44eeff>|r")
        agb:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        agb:RegisterForClicks("LeftButtonUp","RightButtonUp")
        agb:SetScript("OnEnter", function()
            GameTooltip:SetOwner(agb, "ANCHOR_RIGHT")
            GameTooltip:AddLine("|cff44eeff" .. PBM_L["> Invite to Group"] .. "|r",1,1,1)
            GameTooltip:AddLine("|cff44ff44" .. PBM_L["Left-click to invite."] .. "|r",1,1,1)
            GameTooltip:AddLine("|cffff2020" .. PBM_L["Right-click to remove."] .. "|r",1,1,1)
            GameTooltip:Show()
        end)
        agb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rf.addGroupBtn = agb
        PBM.HookRowHighlight(agb, rf, hov)

        -- x Delete button (RIGHT-2, matches class tabs)
        local db = CreateFrame("Button", "LichborneGVRow"..i.."Del", rf)
        db:SetPoint("RIGHT", rf, "RIGHT", -2, 0); db:SetSize(18, RH-2)
        db:SetNormalFontObject("GameFontNormalSmall"); db:SetText("|cffaa2222x|r")
        db:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        db:SetScript("OnEnter", function()
            GameTooltip:SetOwner(db, "ANCHOR_RIGHT")
            GameTooltip:AddLine(PBM_L["Remove Character"], 1, 0.3, 0.3)
            GameTooltip:AddLine(PBM_L["Removes from tracker."], 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        db:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rf.delBtn = db
        PBM.HookRowHighlight(db, rf, hov)

        local ln = rf:CreateTexture(nil, "OVERLAY")
        ln:SetHeight(1); ln:SetWidth(totalW)
        ln:SetPoint("BOTTOMLEFT", rf, "BOTTOMLEFT", 0, 0); ln:SetTexture(0.12,0.20,0.35,0.4)

        PBM.State.groupViewRowFrames[i] = rf
    end

    -- ── Group drag-to-reorder ─────────────────────────────────────
    if LichborneTrackerFrame then
        LichborneTrackerFrame:HookScript("OnMouseUp", function()
            if gvDragSource then gvMouseHeld = false end
        end)
    end

    gvDragPoll:SetScript("OnUpdate", function()
        if not gvDragSource then return end
        if not gvMouseHeld then
            -- Released — find the visible row under the cursor
            local cx, cy = GetCursorPosition()
            local scl = UIParent:GetEffectiveScale()
            cx, cy = cx/scl, cy/scl
            local targetVis = nil
            for j, rf2 in ipairs(PBM.State.groupViewRowFrames) do
                if rf2:IsShown() and j ~= gvDragSource and rf2.charName then
                    local l,r,b,t = rf2:GetLeft(),rf2:GetRight(),rf2:GetBottom(),rf2:GetTop()
                    if l and cx>=l and cx<=r and cy>=b and cy<=t then
                        targetVis = j; break
                    end
                end
            end
            if targetVis then
                local off  = PBM.State.gvScrollOffset or 0
                local mem  = PBM.State.gvMembers
                local a, b2 = off + gvDragSource, off + targetVis
                if mem and mem[a] and mem[b2] and a ~= b2 then
                    local item = mem[a]
                    if a < b2 then
                        for k = a, b2 - 1 do mem[k] = mem[k+1] end
                    else
                        for k = a, b2 + 1, -1 do mem[k] = mem[k-1] end
                    end
                    mem[b2] = item
                    PBM.State.gvSortKey = nil          -- drop column sort so manual order shows
                    if PBM.State.UpdateGVSortHeaders then PBM.State.UpdateGVSortHeaders() end
                    SaveGVManualOrder()
                    PBM.RefreshGroupViewRows()
                end
            end
            for _, rf2 in ipairs(PBM.State.groupViewRowFrames) do
                if rf2.hov then rf2.hov:SetTexture(0,0,0,0) end
                if rf2.gvDropHi then rf2.gvDropHi:SetTexture(0,0,0,0) end
                if rf2.gvDragTex then rf2.gvDragTex:SetVertexColor(0.2,0.3,0.5,0) end
            end
            gvDragSource = nil
            return
        end
        -- Dragging — highlight the row under the cursor
        local cx, cy = GetCursorPosition()
        local scl = UIParent:GetEffectiveScale()
        cx, cy = cx/scl, cy/scl
        for j, rf2 in ipairs(PBM.State.groupViewRowFrames) do
            if rf2:IsShown() and j ~= gvDragSource and rf2.gvDropHi then
                local l,r,b,t = rf2:GetLeft(),rf2:GetRight(),rf2:GetBottom(),rf2:GetTop()
                if l and rf2.charName and cx>=l and cx<=r and cy>=b and cy<=t then
                    rf2.gvDropHi:SetTexture(0.9,0.7,0.1,0.20)
                else
                    rf2.gvDropHi:SetTexture(0,0,0,0)
                end
            end
        end
    end)

    -- ── Avg iLvL / Avg GS bars (mirror the class tabs) ───────────
    local rosterBlockW = 130
    local swTotalW = totalW - 56 - 4 - rosterBlockW
    local swW = swTotalW / 10

    -- mode = "ilvl" or "gs"; store labels into the given swatch table + sets the right block label
    local function BuildAvgBar(yTop, titleText, mode, swatchStore, blockLabelText)
        local bar = CreateFrame("Frame", nil, gvf)
        bar:SetPoint("TOPLEFT", gvf, "TOPLEFT", 0, yTop)
        bar:SetSize(totalW, 24); bar:SetFrameLevel(fl + 11)
        local bg = bar:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(bar); bg:SetTexture(0.05, 0.07, 0.13, 1)
        local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("LEFT", bar, "LEFT", 4, 0); title:SetWidth(52); title:SetText("|cffC69B3A"..titleText.."|r")

        local idx = 0
        for _, cls in ipairs(PBM.CLASS_TABS) do
            if cls == "Raid" or cls == "Overview" or cls == "Group" then break end
            idx = idx + 1
            local c = PBM.CLASS_COLORS[cls]
            local sw = CreateFrame("Button", nil, bar)
            sw:SetSize(swW - 2, 20)
            sw:SetPoint("LEFT", bar, "LEFT", 56 + (idx-1)*swW, 0)
            sw:SetFrameLevel(bar:GetFrameLevel() + 1)
            local swbg = sw:CreateTexture(nil, "BACKGROUND"); swbg:SetAllPoints(sw); swbg:SetTexture(0.08, 0.10, 0.18, 1)
            local hex = string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255))
            local lbl = sw:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetAllPoints(sw); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
            lbl:SetText(hex..(PBM.TAB_LABELS[cls])..": |cff555555--|r")
            swatchStore[cls] = lbl
            sw:EnableMouse(true)
            local capCls = cls
            sw:SetScript("OnEnter", function()
                GameTooltip:SetOwner(sw, "ANCHOR_TOP")
                GameTooltip:AddLine(PBM.TAB_LABELS[capCls], c.r, c.g, c.b)
                GameTooltip:AddLine(PBM_L["Current-group average "] .. (mode == "gs" and PBM_L["gear score"] or PBM_L["item level"]) .. PBM_L[" for this class."], 1,1,1)
                GameTooltip:AddLine(PBM_L["Click to switch to this tab."], 0.5,0.5,0.5)
                GameTooltip:Show()
            end)
            sw:SetScript("OnLeave", function() GameTooltip:Hide() end)
            sw:SetScript("OnClick", function()
                PBM.State.activeTab = capCls
                PBM.UpdateTabs()
                PBM.RefreshRows()
            end)
        end

        -- Right block: "Group iLvL:" / "Group GS:"
        local block = CreateFrame("Frame", nil, bar)
        block:SetPoint("RIGHT", bar, "RIGHT", 0, 0); block:SetSize(rosterBlockW, 24)
        block:SetFrameLevel(bar:GetFrameLevel() + 1)
        block:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
        block:SetBackdropColor(0.05, 0.07, 0.13, 1); block:SetBackdropBorderColor(0.78, 0.61, 0.23, 1.0)
        local blbl = block:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        blbl:SetAllPoints(block); blbl:SetJustifyH("CENTER"); blbl:SetJustifyV("MIDDLE")
        blbl:SetText("|cffC69B3A"..blockLabelText..":|r |cff555555--|r")
        block:EnableMouse(true)
        block:SetScript("OnEnter", function()
            GameTooltip:SetOwner(block, "ANCHOR_TOP")
            GameTooltip:AddLine(blockLabelText, 0.78, 0.61, 0.23)
            GameTooltip:AddLine(PBM_L["Average "] .. (mode == "gs" and PBM_L["gear score"] or PBM_L["item level"]) .. PBM_L[" across your current group."], 1,1,1)
            GameTooltip:Show()
        end)
        block:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return blbl
    end

    -- 20 rows end at yStart - 20*RH = -20 - 440 = -460; bars sit flush below with 2px gap between them.
    PBM.State.gvGroupIlvlLabel = BuildAvgBar(-460, PBM_L["Avg iLvL:"], "ilvl", PBM.State.gvAvgSwatches, PBM_L["Group iLvL"])
    PBM.State.gvGroupGsLabel   = BuildAvgBar(-486, PBM_L["Avg GS:"],   "gs",   PBM.State.gvGsSwatches,  PBM_L["Group GS"])
end

-- ── Current-group averages (computed from the built member list) ─
-- field = "gs" (iLvL column value) or "realGs" (gear score)
local function GroupClassAvg(cls, field)
    local total, n = 0, 0
    for _, m in ipairs(PBM.State.gvMembers or {}) do
        local d = m.data
        if d and d.cls == cls then total = total + (d[field] or 0); n = n + 1 end
    end
    if n == 0 then return 0 end
    return math.floor(total / n + 0.5)
end

local function GroupAvg(field)
    local total, n = 0, 0
    for _, m in ipairs(PBM.State.gvMembers or {}) do
        local d = m.data
        if d then total = total + (d[field] or 0); n = n + 1 end
    end
    if n == 0 then return 0 end
    return math.floor(total / n + 0.5)
end

-- Populate the two avg bars from the current group
function PBM.UpdateGroupSummary()
    for cls, lbl in pairs(PBM.State.gvAvgSwatches) do
        local c = PBM.CLASS_COLORS[cls]
        if c then
            local hex = string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255))
            local v = GroupClassAvg(cls, "gs")
            lbl:SetText(hex..(PBM.TAB_LABELS[cls])..": "..(v > 0 and "|cffd4af37"..v.."|r" or "|cff555555--|r"))
        end
    end
    for cls, lbl in pairs(PBM.State.gvGsSwatches) do
        local c = PBM.CLASS_COLORS[cls]
        if c then
            local hex = string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255))
            local v = GroupClassAvg(cls, "realGs")
            lbl:SetText(hex..(PBM.TAB_LABELS[cls])..": "..(v > 0 and "|cffd4af37"..v.."|r" or "|cff555555--|r"))
        end
    end
    if PBM.State.gvGroupIlvlLabel then
        local v = GroupAvg("gs")
        PBM.State.gvGroupIlvlLabel:SetText("|cffC69B3A" .. PBM_L["Group iLvL:"] .. "|r "..(v > 0 and "|cffff8000"..v.."|r" or "|cff555555--|r"))
    end
    if PBM.State.gvGroupGsLabel then
        local v = GroupAvg("realGs")
        PBM.State.gvGroupGsLabel:SetText("|cffC69B3A" .. PBM_L["Group GS:"] .. "|r "..(v > 0 and "|cffff8000"..v.."|r" or "|cff555555--|r"))
    end
end

-- ── Called when the view is toggled ON ───────────────────────────
function PBM.OpenGroupView()
    BuildGVMemberList()
    PBM.State.gvScrollOffset = 0
    if PBM.State.UpdateGVSortHeaders then PBM.State.UpdateGVSortHeaders() end
    PBM.RefreshGroupViewRows()
end