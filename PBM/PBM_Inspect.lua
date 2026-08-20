-- ============================================================
--  LBT_Inspect.lua  |  CalcGS + inspectFrame timer + INSPECT_READY handler
-- ============================================================
PBM = PBM or {}
PBM.State = PBM.State or {}

PBM.State.LichborneInspectTarget = nil
PBM.State.LichborneInspectRow = nil
PBM.State.LichborneInspectUnit = "target"
PBM.State.LichborneInspectRetries = 0
PBM.State.LichborneCacheRetries = 0
PBM.State.lastCalcGsDi = nil
PBM.State.inspectWait = 0
PBM.State.LichborneInspectGUID = nil
PBM.State.LichborneGroupScanActive = false

local INSPECT_MAX_RETRIES = 6
local CACHE_MAX_RETRIES = 6

local function CalcGS()
    local di = PBM.State.LichborneInspectTarget
    if not di then return end
    -- Reset retry counters when starting a new player (handles 25s cap forced advance)
    if di ~= PBM.State.lastCalcGsDi then
        PBM.State.LichborneInspectRetries = 0
        PBM.State.LichborneCacheRetries = 0
        PBM.State.lastCalcGsDi = di
    end
    local inspUnit = PBM.State.LichborneInspectUnit or "target"
    local rowName = (LichborneTrackerDB.rows[di] and LichborneTrackerDB.rows[di].name) or "?"
    if not LichborneTrackerDB.rows[di] then
        PBM.DBG("|cffff4444[NIL]|r LichborneTrackerDB.rows["..tostring(di).."] is nil mid-scan - aborting CalcGS")
        PBM.State.LichborneInspectTarget = nil; return
    end
    local slots = {1,2,3,15,5,9,10,6,7,8,11,12,13,14,16,17,18}
    local total, count = 0, 0

    PBM.DBG("CalcGS start: |cffffff88"..rowName.."|r unit=|cffffff88"..inspUnit.."|r UnitExists=|cffffff88"..tostring(UnitExists(inspUnit)).."|r")
    local gsStartTime = GetTime()

    if not LichborneTrackerDB.rows[di].ilvl then
        local g = {}
        for i = 1, 17 do g[i] = 0 end
        LichborneTrackerDB.rows[di].ilvl = g
    end
    if not LichborneTrackerDB.rows[di].ilvlLink then
        local lnk = {}
        for i = 1, 17 do lnk[i] = "" end
        LichborneTrackerDB.rows[di].ilvlLink = lnk
    end

    local anyPending = false
    local linkCount, cachedCount, uncachedCount, emptyCount, zeroIlvlCount = 0, 0, 0, 0, 0
    local slotDiag = {}

    -- Check if MH is a 2H weapon so we can blank OH instead of duplicating it
    local mhLink = GetInventoryItemLink(inspUnit, 16)
    local mhIs2H = false
    if mhLink then
        local _, _, _, _, _, _, _, _, mhEquipLoc = GetItemInfo(mhLink)
        if mhEquipLoc == "INVTYPE_2HWEAPON" then
            mhIs2H = true
        end
    end

    for g, slot in ipairs(slots) do
        -- slot 17 = OH; if MH is 2H, WoW mirrors the same link into slot 17 — blank it out
        -- Exception: Warriors are NOT mirrored by AzerothCore, so Fury/Titan's Grip OH must be kept
        if slot == 17 and mhIs2H and LichborneTrackerDB.rows[di].cls ~= "Warrior" then
            LichborneTrackerDB.rows[di].ilvl[g] = 0
            LichborneTrackerDB.rows[di].ilvlLink[g] = ""
            slotDiag[g] = string.format("%-5s", PBM.SLOT_ABBR[g]).."(s17)=|cff888888[2H-OH]|r"
        else
            local link = GetInventoryItemLink(inspUnit, slot)
            if link then
                linkCount = linkCount + 1
                local itemName, _, itemQuality, itemIlvl = GetItemInfo(link)
                if itemIlvl and itemIlvl > 0 then
                    cachedCount = cachedCount + 1
                    total = total + itemIlvl
                    count = count + 1
                    LichborneTrackerDB.rows[di].ilvl[g] = itemIlvl
                    LichborneTrackerDB.rows[di].ilvlLink[g] = link
                    slotDiag[g] = string.format("%-5s", PBM.SLOT_ABBR[g]).."(s"..slot..")=|cff44ff44"..itemIlvl.."|r"
                else
                    LichborneTrackerDB.rows[di].ilvl[g] = 0
                    LichborneTrackerDB.rows[di].ilvlLink[g] = link
                    if itemName then
                        -- Link cached but iLvl=0 (PvP trinket, quest item, relic, etc.)
                        zeroIlvlCount = zeroIlvlCount + 1
                        slotDiag[g] = string.format("%-5s", PBM.SLOT_ABBR[g]).."(s"..slot..")=|cffffff00iLvl0|r("..itemName..(itemQuality and " q"..itemQuality or "")..")"
                    else
                        -- GetItemInfo returned nil - item not in client cache yet; request it
                        GetItemInfo(link)
                        anyPending = true
                        uncachedCount = uncachedCount + 1
                        slotDiag[g] = string.format("%-5s", PBM.SLOT_ABBR[g]).."(s"..slot..")=|cffff9900uncached|r"
                    end
                end
            else
                emptyCount = emptyCount + 1
                LichborneTrackerDB.rows[di].ilvl[g] = 0
                LichborneTrackerDB.rows[di].ilvlLink[g] = ""
                slotDiag[g] = string.format("%-5s", PBM.SLOT_ABBR[g]).."(s"..slot..")=|cff555555NIL|r"
            end
        end
    end

    PBM.DBG("Slots: |cff44ff44"..linkCount.." links|r (cached="..cachedCount.." uncached="..uncachedCount.." iLvl0="..zeroIlvlCount..") nil-link=|cffff4444"..emptyCount.."|r")
    if anyPending then
        PBM.State.LichborneCacheRetries = PBM.State.LichborneCacheRetries + 1
        PBM.DBG("|cffffff88"..rowName.."|r: "..uncachedCount.." items uncached - cache retry "..PBM.State.LichborneCacheRetries.."/"..CACHE_MAX_RETRIES)
        if PBM.State.LichborneCacheRetries < CACHE_MAX_RETRIES then
            PBM.State.inspectWait = 0  -- reset so OnUpdate waits another full interval before next attempt
            return
        end
        -- Exhausted cache retries — proceed with whatever data we have
        PBM.DBG("|cffff4444Cache retries exhausted for |r|cffffff88"..rowName.."|r — proceeding with "..cachedCount.." cached slots")
        if LichborneAddStatus then
            LichborneAddStatus:SetText("|cffff4444" .. PBM_L["Some items not cached — using available data."] .. "|r")
        end
        PBM.State.LichborneCacheRetries = 0
    end

    for _, row in ipairs(PBM.State.rowFrames) do
        if row.dbIndex == di and row.gearBoxes then
            for g = 1, 17 do
                local v = LichborneTrackerDB.rows[di].ilvl[g] or 0
                if row.gearBoxes[g] then
                    local link2 = LichborneTrackerDB.rows[di].ilvlLink and LichborneTrackerDB.rows[di].ilvlLink[g]
                    row.gearBoxes[g]:SetText((v > 0 or (link2 and link2 ~= "")) and tostring(v) or "")
                    local qc2 = PBM.GetItemQualityColor(link2)
                    if qc2 then
                        row.gearBoxes[g]:SetTextColor(qc2.r, qc2.g, qc2.b)
                    else
                        row.gearBoxes[g]:SetTextColor(1, 1, 1)
                    end
                end
            end
            break
        end
    end

    if count > 0 then
        local rowData = LichborneTrackerDB.rows[di]
        local ilvl = math.floor(total / count)
        local realGs = PBM.CalculateUnitGearScore(inspUnit)

        local prevGS     = rowData.gs or 0
        local prevRealGS = rowData.realGs or 0
        rowData.gs = ilvl
        rowData.realGs = realGs
        PBM.DBG("DB write |cffffff88"..rowName.."|r: iLvl "..(prevGS~=ilvl and "|cffff9900"..prevGS.."|r->".."|cff44ff44"..ilvl.."|r" or "|cffaaaaaa"..ilvl.."|r").." GS "..(prevRealGS~=realGs and "|cffff9900"..prevRealGS.."|r->".."|cff44ff44"..realGs.."|r" or "|cffaaaaaa"..realGs.."|r"))

        for _, row in ipairs(PBM.State.rowFrames) do
            if row.dbIndex == di then
                if row.gsBox then row.gsBox:SetText(tostring(ilvl)) end
                if row.realGsBox then row.realGsBox:SetText(realGs > 0 and tostring(realGs) or "") end
                break
            end
        end

        local updatedName = rowData.name
        if updatedName and updatedName ~= "" and LichborneTrackerDB.raidRosters then
            for _, roster in pairs(LichborneTrackerDB.raidRosters) do
                for _, slot in ipairs(roster) do
                    if slot.name and slot.name:lower() == updatedName:lower() then
                        slot.gs = ilvl
                        slot.realGs = realGs
                    end
                end
            end
        end

        local name = rowData.name or "?"
        local cls = rowData.cls or "?"
        local c = PBM.CLASS_COLORS[cls]
        local hex = c and string.format("|cff%02x%02x%02x", math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255)) or "|cffffffff"
        if LichborneAddStatus then
            LichborneAddStatus:SetText(hex..name.."|r ("..cls..") - iLvl |cffffff00"..ilvl.."|r, GS |cffffff00"..realGs.."|r " .. PBM_L["added!"])
        end
        LichborneOutput(hex..name.."|r: iLvl |cffffff00"..ilvl.."|r  GS |cffffff00"..realGs.."|r ("..count.." " .. PBM_L["slots"] .. ")", 1, 0.85, 0)
        PBM.DBG("|cff44ff44SUCCESS|r |cffffff88"..rowName.."|r iLvl="..ilvl.." GS="..realGs.." slots="..count)

        local targetName = UnitName("target")
        if targetName and targetName == UnitName("player") then
            local specNames = PBM.CLASS_SPECS[rowData.cls or ""]
            if specNames then
                local bestTab, bestPoints = 1, 0
                for tab = 1, 3 do
                    local _, _, pts = GetTalentTabInfo(tab)
                    if pts and pts > bestPoints then
                        bestPoints = pts
                        bestTab = tab
                    end
                end
                if bestPoints > 0 then
                    rowData.spec = specNames[bestTab] or rowData.spec
                    LichborneOutput(hex..name.."|r: |cffffff00"..specNames[bestTab].."|r ("..bestPoints.." " .. PBM_L["pts"] .. ")", 1, 0.85, 0)
                end
            end
        end

        PBM.RefreshRows()
        if PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames > 0 then PBM.RefreshOverviewRows() end
        if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
        PBM.State.LichborneInspectRetries = 0
    else
        -- No slots came back — inspect data not ready yet.
        PBM.State.LichborneInspectRetries = PBM.State.LichborneInspectRetries + 1
        local unit = PBM.State.LichborneInspectUnit or "target"
        local unitExists = UnitExists(unit)
        local maxGsRetries = PBM.State.LichborneGroupScanActive and 1 or 0
        PBM.DBG("|cffff4444No slot data for |r|cffffff88"..rowName.."|r — retry "..PBM.State.LichborneInspectRetries.."/"..maxGsRetries.." UnitExists=|cffffff88"..tostring(unitExists).."|r links="..linkCount)
        if PBM.State.LichborneInspectRetries < maxGsRetries then
            if unitExists then
                InspectUnit(unit)
                PBM.DBG("Re-fired InspectUnit("..unit..") for |cffffff88"..rowName.."|r")
            else
                PBM.DBG("|cffff4444UnitExists("..unit..") = false — cannot re-fire InspectUnit|r")
            end
            PBM.State.inspectWait = 0
            return  -- do NOT clear LichborneInspectTarget — keep retrying
        end
        -- Exhausted retries
        PBM.DBG("|cffff4444FAILED |r|cffffff88"..rowName.."|r — exhausted "..INSPECT_MAX_RETRIES.." retries, 0 slots. UnitExists="..tostring(unitExists).." links="..linkCount)
        PBM.DBG("|cffff4444FAIL breakdown:|r cached="..cachedCount.." uncached="..uncachedCount.." iLvl0="..zeroIlvlCount.." nil-link=|cffff4444"..emptyCount.."|r total-links="..linkCount)
        if LichborneDebugMode then
            for g2 = 1, #slots do
                if slotDiag[g2] then PBM.DBG("  "..slotDiag[g2]) end
            end
        end
        if LichborneAddStatus then
            LichborneAddStatus:SetText("|cffff4444" .. PBM_L["No gear data returned. Target may be out of range."] .. "|r")
        end
        LichborneOutput("|cffff4444"..rowName..":|r |cffff4444" .. PBM_L["FAILED — no gear data returned."] .. "|r", 1, 0.5, 0)
    end

    PBM.DBG("CalcGS elapsed: |cffffff88"..string.format("%.3f", GetTime()-gsStartTime).."s|r")
    PBM.State.LichborneInspectRetries = 0
    PBM.State.LichborneCacheRetries = 0
    ClearInspectPlayer()
    PBM.State.LichborneInspectTarget = nil
    PBM.State.LichborneInspectRow = nil
end

local inspectFrame = CreateFrame("Frame")
inspectFrame:SetScript("OnUpdate", function(_, elapsed)
    if not PBM.State.LichborneInspectTarget then return end
    PBM.State.inspectWait = PBM.State.inspectWait + elapsed
    if PBM.State.inspectWait >= 3.0 then
        PBM.State.inspectWait = 0
        local di = PBM.State.LichborneInspectTarget
        PBM.DBG("Timer fallback → CalcGS for |cffffff88"..(LichborneTrackerDB.rows[di] and LichborneTrackerDB.rows[di].name or "?").."|r (no INSPECT_READY in 3.0s)")
        CalcGS()
    end
end)

inspectFrame:RegisterEvent("INSPECT_READY")
inspectFrame:SetScript("OnEvent", function(_, event, guid)
    if not PBM.State.LichborneInspectTarget then return end
    local di = PBM.State.LichborneInspectTarget
    local guidInfo = guid and ("|cffffff88"..guid.."|r") or "|cff888888(no GUID)|r"
    if guid and PBM.State.LichborneInspectGUID and guid ~= PBM.State.LichborneInspectGUID then
        PBM.DBG("|cffff4444GUID MISMATCH (GS)|r got "..guidInfo.." expected |cffffff88"..PBM.State.LichborneInspectGUID.."|r for |cffffff88"..(LichborneTrackerDB.rows[di] and LichborneTrackerDB.rows[di].name or "?").."|r")
    else
        PBM.DBG("INSPECT_READY (GS) for |cffffff88"..(LichborneTrackerDB.rows[di] and LichborneTrackerDB.rows[di].name or "?").."|r GUID="..guidInfo)
    end
    PBM.State.inspectWait = 0
    PBM.State.LichborneInspectRetries = 0  -- fresh INSPECT_READY means fresh data incoming
    CalcGS()
end)