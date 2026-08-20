-- ============================================================
--  LBT_Spec.lua  |  CalcSpec + specFrame timer + INSPECT_READY handler
-- ============================================================
PBM = PBM or {}
PBM.State = PBM.State or {}

PBM.State.LichborneSpecTarget = nil
PBM.State.specRetries = 0
PBM.State.lastCalcSpecDi = nil
PBM.State.specWait = 0
PBM.State.LichborneSpecGUID = nil

local function CalcSpec()
    local di = PBM.State.LichborneSpecTarget
    if not di then return end
    -- Reset retry counter when starting a new player (handles 25s cap forced advance)
    if di ~= PBM.State.lastCalcSpecDi then
        PBM.State.specRetries = 0
        PBM.State.lastCalcSpecDi = di
    end
    local rowData = LichborneTrackerDB.rows[di]
    if not rowData then PBM.State.LichborneSpecTarget = nil; PBM.State.specRetries = 0; return end

    local cls = rowData.cls or ""
    local specNames = PBM.CLASS_SPECS[cls]
    PBM.DBG("CalcSpec start: |cffffff88"..(rowData.name or "?").."|r cls=|cffffff88"..cls.."|r unit=|cffffff88"..(PBM.State.LichborneInspectUnit or "?").."|r UnitExists=|cffffff88"..tostring(UnitExists(PBM.State.LichborneInspectUnit or "target")).."|r")
    local specStartTime = GetTime()
    if not specNames then
        LichborneOutput("|cffC69B3APBM:|r " .. PBM_L["Unknown class: "] .. cls, 1, 0.5, 0.5)
        PBM.State.LichborneSpecTarget = nil; PBM.State.specRetries = 0
        return
    end

    -- WotLK 3.3.5a: pass inspect=true to read target's talents
    local inspectSelf = (PBM.State.LichborneInspectUnit and UnitIsUnit(PBM.State.LichborneInspectUnit, "player"))
    local inspFlag = inspectSelf and false or true
    local activeGroup = (GetActiveTalentGroup and GetActiveTalentGroup(inspFlag)) or 1
    local treePts = {0, 0, 0}
    for tab = 1, 3 do
        local numTalents = GetNumTalents(tab, inspFlag)
        if numTalents and numTalents > 0 then
            for t = 1, numTalents do
                local name, _, _, _, currRank = GetTalentInfo(tab, t, inspFlag, false, activeGroup)
                if currRank and currRank > 0 then
                    treePts[tab] = treePts[tab] + currRank
                end
            end
        end
    end

    -- Try the direct tab points API
    local tabPts = {0, 0, 0}
    local gotTabData = false
    for tab = 1, 3 do
        local tabName, _, pts = GetTalentTabInfo(tab, inspFlag, false, activeGroup)
        if pts == nil then PBM.DBG("|cffff4444[NIL]|r GetTalentTabInfo(tab="..tab..") pts=nil (tabName=|cffffff88"..(tabName or "nil").."|r)") end
        if pts and pts > 0 then
            tabPts[tab] = pts
            gotTabData = true
        end
    end
    -- Prefer tabPts if available, else fall back to treePts
    local pts = gotTabData and tabPts or treePts

    PBM.DBG("Talent pts (tree/tab): T1=|cffffff88"..pts[1].."|r T2=|cffffff88"..pts[2].."|r T3=|cffffff88"..pts[3].."|r (gotTabData=|cffffff88"..tostring(gotTabData).."|r)")
    local treeNames = specNames and {specNames[1] or "?", specNames[2] or "?", specNames[3] or "?"} or {"?","?","?"}
    PBM.DBG("Trees: T1=|cffffff88"..treeNames[1].."|r("..pts[1].."pts) T2=|cffffff88"..treeNames[2].."|r("..pts[2].."pts) T3=|cffffff88"..treeNames[3].."|r("..pts[3].."pts)")

    local best, bestPoints = 1, 0
    for tab = 1, 3 do
        if pts[tab] > bestPoints then
            bestPoints = pts[tab]
            best = tab
        end
    end

    if bestPoints == 0 then
        PBM.State.specRetries = PBM.State.specRetries + 1
        local maxSpecRetries = PBM.State.LichborneGroupScanActive and 1 or 0
        PBM.DBG("|cffff4444Spec talent data = 0/0/0 for |r|cffffff88"..(rowData.name or "?").."|r — retry "..PBM.State.specRetries.."/"..maxSpecRetries)
        if PBM.State.specRetries >= maxSpecRetries then
            PBM.DBG("|cffff4444FAILED spec for |r|cffffff88"..(rowData.name or "?").."|r — all trees 0 after "..maxSpecRetries.." retries")
            LichborneOutput("|cffff4444"..(rowData.name or "?").."|r" .. PBM_L[": FAILED — could not read talent data."], 1, 0.5, 0.5)
            if LichborneAddStatus then
                LichborneAddStatus:SetText("|cffff4444" .. PBM_L["Talent data unavailable. Try standing closer."] .. "|r")
            end
            PBM.State.LichborneSpecTarget = nil; PBM.State.specRetries = 0
        end
        return
    end

    PBM.State.specRetries = 0
    local specName = specNames[best] or ""
    local prevSpec = rowData.spec or ""
    rowData.spec = specName
    PBM.DBG("DB write spec |cffffff88"..(rowData.name or "?").."|r: "..(prevSpec~=specName and "|cffff9900"..prevSpec.."|r->|cff44ff44"..specName.."|r" or "|cffaaaaaa"..specName.."|r (unchanged)"))

    local c = PBM.CLASS_COLORS[cls]
    local hex = c and string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255)) or "|cffffffff"
    if LichborneAddStatus then
        LichborneAddStatus:SetText(hex..(rowData.name or "?").."|r" .. PBM_L[" — Specialization: "] .. "|cffffff00"..specName.."|r ("..bestPoints.. PBM_L[" pts)"])
    end
    LichborneOutput(hex..(rowData.name or "?").."|r: |cffffff00"..specName.."|r ("..bestPoints.. PBM_L[" pts)"], 1, 0.85, 0)
    PBM.DBG("|cff44ff44SUCCESS|r spec |cffffff88"..(rowData.name or "?").."|r = |cffffff00"..specName.."|r tree"..best.." ("..bestPoints.." pts)")
    PBM.DBG("CalcSpec elapsed: |cffffff88"..string.format("%.3f", GetTime()-specStartTime).."s|r")

    ClearInspectPlayer()
    PBM.State.LichborneSpecTarget = nil
    PBM.RefreshRows()
    if PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames > 0 then PBM.RefreshOverviewRows() end
    if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
end

local specFrame = CreateFrame("Frame")
specFrame:SetScript("OnUpdate", function(_, elapsed)
    if not PBM.State.LichborneSpecTarget then return end
    PBM.State.specWait = PBM.State.specWait + elapsed
    if PBM.State.specWait >= 3.0 then
        PBM.State.specWait = 0
        CalcSpec()
    end
end)
specFrame:RegisterEvent("INSPECT_READY")
specFrame:SetScript("OnEvent", function(_, event, guid)
    if not PBM.State.LichborneSpecTarget then return end
    local guidInfo = guid and ("|cffffff88"..guid.."|r") or "|cff888888(no GUID)|r"
    if guid and PBM.State.LichborneSpecGUID and guid ~= PBM.State.LichborneSpecGUID then
        PBM.DBG("|cffff4444GUID MISMATCH (Spec)|r got "..guidInfo.." expected |cffffff88"..PBM.State.LichborneSpecGUID.."|r for |cffffff88"..(LichborneTrackerDB.rows[PBM.State.LichborneSpecTarget] and LichborneTrackerDB.rows[PBM.State.LichborneSpecTarget].name or "?").."|r")
    else
        PBM.DBG("INSPECT_READY (Spec) for |cffffff88"..(LichborneTrackerDB.rows[PBM.State.LichborneSpecTarget] and LichborneTrackerDB.rows[PBM.State.LichborneSpecTarget].name or "?").."|r GUID="..guidInfo)
    end
    PBM.State.specWait = 0
    CalcSpec()
end)