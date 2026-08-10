PBM = PBM or {}
PBM.State = PBM.State or {}

local CLASS_NAMES = {
    ["DeathKnight"] = "Death Knight",
    ["Death Knight"] = "Death Knight",
    ["Druid"] = "Druid",
    ["Hunter"] = "Hunter",
    ["Mage"] = "Mage",
    ["Paladin"] = "Paladin",
    ["Priest"] = "Priest",
    ["Rogue"] = "Rogue",
    ["Shaman"] = "Shaman",
    ["Warlock"] = "Warlock",
    ["Warrior"] = "Warrior",
}

local function Trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function FindTrackedBot(name)
    local wanted = name:lower()
    for _, row in ipairs(LichborneTrackerDB.rows or {}) do
        if row.name and row.name ~= "" and row.name:lower() == wanted then
            return row
        end
    end
end

local function AddTrackedBot(name, cls)
    local existing = FindTrackedBot(name)
    if existing then return false end

    PBM.EnsureClass(cls)
    local slot
    for _, row in ipairs(LichborneTrackerDB.rows) do
        if row.cls == cls and (not row.name or row.name == "") then
            slot = row
            break
        end
    end
    if not slot then
        slot = PBM.DefaultRow(cls)
        table.insert(LichborneTrackerDB.rows, slot)
    end

    slot.name = name
    return true
end

-- Parse the exact response emitted by mod-playerbots ListBots():
--   Bot roster: +OnlineName Class, -OfflineName Class
-- Returns recognized, numberAdded, numberListed.
function PBM.ImportBotRosterMessage(message)
    if type(message) ~= "string" then return false end

    local clean = message:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    local payload = clean:match("^Bot roster:%s*(.*)$")
    if payload == nil then return false end

    local added, total = 0, 0
    for rawEntry in payload:gmatch("([^,]+)") do
        local entry = Trim(rawEntry)
        local _, name, rawClass = entry:match("^([+-])(%S+)%s+(.+)$")
        local cls = rawClass and CLASS_NAMES[Trim(rawClass)]
        if name and cls then
            total = total + 1
            if AddTrackedBot(name, cls) then added = added + 1 end
        end
    end

    if PBM.RefreshRows then PBM.RefreshRows() end
    if PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames > 0 and PBM.RefreshOverviewRows then
        PBM.RefreshOverviewRows()
    end

    return true, added, total
end

function PBM.RequestBotRoster()
    PBM.State.rosterSyncPending = true
    SendChatMessage(".playerbots bot list", "SAY")
end

local rosterTimerFrame

function PBM.ScheduleBotRosterRequest(delay)
    local callback = function() PBM.RequestBotRoster() end
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, callback)
        return
    end

    if not rosterTimerFrame then rosterTimerFrame = CreateFrame("Frame") end
    local elapsed = 0
    rosterTimerFrame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= delay then
            self:SetScript("OnUpdate", nil)
            callback()
        end
    end)
end

local rosterEventFrame = CreateFrame and CreateFrame("Frame", "PBMRosterSyncEventFrame")
if rosterEventFrame then
    rosterEventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    rosterEventFrame:SetScript("OnEvent", function(_, _, message)
        local matched, added, total = PBM.ImportBotRosterMessage(message)
        if not matched then return end

        PBM.State.rosterSyncPending = false
        local status = "|cff44ff44Roster synced: " .. total .. " found, " .. added .. " added.|r"
        if LichborneAddStatus then LichborneAddStatus:SetText(status) end
        if LichborneOutput then
            LichborneOutput("|cffC69B3APBM:|r Roster synced: " .. total .. " found, " .. added .. " added.", 1, 0.85, 0)
        end
    end)
end
