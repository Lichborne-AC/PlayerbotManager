-- ============================================================
--  LBT_Database.lua  |  SavedVars init + low-level DB helpers
-- ============================================================
PBM = PBM or {}
PBM.State = PBM.State or {}

-- ── SavedVariables initialization ─────────────────────────────
if not LichborneTrackerDB then LichborneTrackerDB = {} end
if not LichborneTrackerDB.rows then LichborneTrackerDB.rows = {} end
if not LichborneTrackerDB.notes then LichborneTrackerDB.notes = "" end
if not LichborneTrackerDB.raid then LichborneTrackerDB.raid = "" end
if not LichborneTrackerDB.raidRows then LichborneTrackerDB.raidRows = {} end
if not LichborneTrackerDB.raidRosters then LichborneTrackerDB.raidRosters = {} end
if not LichborneTrackerDB.raidTier then LichborneTrackerDB.raidTier = 0 end
if not LichborneTrackerDB.needs then LichborneTrackerDB.needs = {} end
if not LichborneTrackerDB.raidName then LichborneTrackerDB.raidName = "N/A (5-Man)" end
if not LichborneTrackerDB.raidSize then LichborneTrackerDB.raidSize = 5 end
if not LichborneTrackerDB.raidGroup then LichborneTrackerDB.raidGroup = "A" end
if not LichborneTrackerDB.allGroups then
    LichborneTrackerDB.allGroups = {}
    for _, g in ipairs({"A","B","C"}) do
        LichborneTrackerDB.allGroups[g] = {}
        for i = 1, 60 do LichborneTrackerDB.allGroups[g][i] = {name="",cls="",spec="",gs=0,realGs=0} end
    end
end
if not LichborneTrackerDB.allGroup then LichborneTrackerDB.allGroup = "A" end
if not LichborneTrackerDB.botNotes then LichborneTrackerDB.botNotes = {} end
if not LichborneTrackerDB.ipData then LichborneTrackerDB.ipData = {} end

-- Legacy migration: allRows → allGroups
if LichborneTrackerDB.allRows then
    if not LichborneTrackerDB.allGroups then LichborneTrackerDB.allGroups = {A={},B={},C={}} end
    for i,v in ipairs(LichborneTrackerDB.allRows) do
        if v.realGs == nil then v.realGs = 0 end
        LichborneTrackerDB.allGroups["A"][i] = v
    end
    LichborneTrackerDB.allRows = nil
end

-- ── Filter state ───────────────────────────────────────────────
PBM.State.LBFilter = PBM.State.LBFilter or {
    groupActive = false,
    showLevel   = false,
    showIP      = false,
    hideRaid    = false,
    showTierKey = true,
}

-- ── DB functions ───────────────────────────────────────────────
function PBM.GetCurrentRoster()
    if not LichborneTrackerDB then LichborneTrackerDB = {} end
    if not LichborneTrackerDB.raidRosters then LichborneTrackerDB.raidRosters = {} end
    if not LichborneTrackerDB.raidName then LichborneTrackerDB.raidName = "N/A (5-Man)" end
    if not LichborneTrackerDB.raidSize then LichborneTrackerDB.raidSize = 5 end
    if not LichborneTrackerDB.raidGroup then LichborneTrackerDB.raidGroup = "A" end
    if not LichborneTrackerDB.allGroups then
        LichborneTrackerDB.allGroups = {}
        for _, g in ipairs({"A","B","C"}) do
            LichborneTrackerDB.allGroups[g] = {}
            for i = 1, 60 do
                LichborneTrackerDB.allGroups[g][i] = {name="",cls="",spec="",gs=0,realGs=0}
            end
        end
    end
    if not LichborneTrackerDB.allGroup then LichborneTrackerDB.allGroup = "A" end
    local name = LichborneTrackerDB.raidName
    local size = LichborneTrackerDB.raidSize
    if type(size) ~= "number" then size = tonumber(size) or 5 end
    if size < 1 then size = 1 end
    if size > PBM.MAX_RAID_SLOTS then size = PBM.MAX_RAID_SLOTS end
    LichborneTrackerDB.raidSize = size
    local group = LichborneTrackerDB.raidGroup
    local key = name .. "_" .. group
    if not LichborneTrackerDB.raidRosters[key] then
        LichborneTrackerDB.raidRosters[key] = {}
        for i = 1, PBM.MAX_RAID_SLOTS do
            LichborneTrackerDB.raidRosters[key][i] = {name="", cls="", spec="", gs=0, realGs=0, role="", notes=""}
        end
    end
    local roster = LichborneTrackerDB.raidRosters[key]
    for i = 1, PBM.MAX_RAID_SLOTS do
        if not roster[i] then roster[i] = {name="", cls="", spec="", gs=0, realGs=0, role="", notes=""} end
    end
    return roster, size
end

function PBM.IsInActiveRaid(charName)
    if not LichborneTrackerDB or not LichborneTrackerDB.raidRosters then return false end
    local raidName  = LichborneTrackerDB.raidName  or ""
    local raidGroup = LichborneTrackerDB.raidGroup or "A"
    local key = raidName .. "_" .. raidGroup
    local roster = LichborneTrackerDB.raidRosters[key]
    if not roster then return false end
    for i = 1, PBM.MAX_RAID_SLOTS do
        if roster[i] and roster[i].name and roster[i].name ~= "" and
           roster[i].name:lower() == charName:lower() then
            return true
        end
    end
    return false
end

function PBM.MigrateGearField()
    if not LichborneTrackerDB or not LichborneTrackerDB.rows then return end
    for _, row in ipairs(LichborneTrackerDB.rows) do
        if row.gear and not row.ilvl then
            row.ilvl = row.gear
            row.gear = nil
        end
        if not row.ilvl then
            local g = {}
            for i = 1, 17 do g[i] = 0 end
            row.ilvl = g
        end
        if not row.ilvlLink then
            local lnk = {}
            for i = 1, 17 do lnk[i] = "" end
            row.ilvlLink = lnk
        end
        if row.realGs == nil then row.realGs = 0 end
    end
end

function PBM.DefaultRow(cls)
    local g = {}
    for i = 1, PBM.GEAR_SLOTS do g[i] = 0 end
    local lnk = {}
    for i = 1, PBM.GEAR_SLOTS do lnk[i] = "" end
    return {cls = cls or "", name = "", ilvl = g, ilvlLink = lnk, gs = 0, realGs = 0, spec = "", level = 0}
end

function PBM.FindTrackedRowIndexByName(charName)
    if not charName or charName == "" then return nil end
    local needle = charName:lower()
    for i, row in ipairs(LichborneTrackerDB.rows or {}) do
        if row.name and row.name ~= "" and row.name:lower() == needle then
            return i, row
        end
    end
    return nil
end

function PBM.RemoveCharacterReferences(charName)
    if not charName or charName == "" then return false end

    local removed = false
    local rowIndex, rowData = PBM.FindTrackedRowIndexByName(charName)
    if rowIndex and rowData then
        local cls = rowData.cls
        table.remove(LichborneTrackerDB.rows, rowIndex)
        removed = true
        if cls and cls ~= "" and cls ~= "Raid" and cls ~= "Overview" then
            local remaining = 0
            for _, r in ipairs(LichborneTrackerDB.rows) do
                if r.cls == cls then remaining = remaining + 1 end
            end
            local maxOffset = math.max(0, remaining - PBM.MAX_ROWS)
            if (PBM.State.classScroll[cls] or 0) > maxOffset then
                PBM.State.classScroll[cls] = maxOffset
            end
        end
    end

    if LichborneTrackerDB.needs then
        LichborneTrackerDB.needs[charName:lower()] = nil
    end

    if LichborneTrackerDB.raidRosters then
        for _, roster in pairs(LichborneTrackerDB.raidRosters) do
            if type(roster) == "table" then
                for i, slot in ipairs(roster) do
                    if slot and slot.name and slot.name ~= "" and slot.name:lower() == charName:lower() then
                        roster[i] = {name="", cls="", spec="", gs=0, realGs=0, role="", notes=""}
                    end
                end
            end
        end
    end

    return removed
end

function PBM.EnsureClass(cls)
    if cls == "Raid" or cls == "Overview" then return end
    local count = 0
    for _, row in ipairs(LichborneTrackerDB.rows) do
        if row.cls == cls then count = count + 1 end
    end
    while count < PBM.MAX_ROWS do
        table.insert(LichborneTrackerDB.rows, PBM.DefaultRow(cls))
        count = count + 1
    end
end
