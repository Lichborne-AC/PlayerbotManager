-- ============================================================
--  LBT_ExportImport.lua  |  Clipboard serialization only
-- ============================================================
PBM = PBM or {}

local function LB_SerializeValue(v)
    local t = type(v)
    if t == "string" then
        return '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    elseif t == "number" then
        return tostring(v)
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "table" then
        local parts = {}
        local maxN = 0
        for k, _ in pairs(v) do
            if type(k) == "number" and k == math.floor(k) and k >= 1 then
                if k > maxN then maxN = k end
            end
        end
        local isArr = maxN > 0
        if isArr then
            for i = 1, maxN do
                if v[i] == nil then isArr = false; break end
            end
        end
        if isArr then
            for i = 1, maxN do
                parts[#parts+1] = LB_SerializeValue(v[i])
            end
        else
            for k, val in pairs(v) do
                local key
                if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                    key = k
                elseif type(k) == "number" then
                    key = "[" .. tostring(k) .. "]"
                else
                    key = '["' .. tostring(k):gsub('"','\\"') .. '"]'
                end
                parts[#parts+1] = key .. "=" .. LB_SerializeValue(val)
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    else
        return "nil"
    end
end

function PBM.LB_ExportDB()
    local db = LichborneTrackerDB
    -- Build stripped row copies: only identity/social fields.
    -- Gear slot data (ilvl array, ilvlLink, gs, realGs) is excluded intentionally —
    -- a fresh gear scan on Account B will populate those fields correctly.
    local strippedRows = {}
    for i, row in ipairs(db.rows or {}) do
        strippedRows[i] = {
            cls    = row.cls    or "",
            name   = row.name   or "",
            spec   = row.spec   or "",
            role   = row.role   or "",
            gs     = row.gs     or 0,
            realGs = row.realGs or 0,
        }
    end
    local payload = {
        rows        = strippedRows,
        profs       = db.profs,
        raidRosters = db.raidRosters,
        allGroups   = db.allGroups,
        allGroup    = db.allGroup,
        notes       = db.notes,
    }
    return PBM.EXPORT_PREFIX .. LB_SerializeValue(payload)
end

function PBM.LB_ImportDB(str)
    if not str or str == "" then return nil, "Nothing to import — paste text first." end
    str = str:match("^%s*(.-)%s*$")
    local data
    if str:find(PBM.EXPORT_PREFIX, 1, true) then
        data = str:sub(#PBM.EXPORT_PREFIX + 1)
    elseif str:find(PBM.EXPORT_PREFIX_V2, 1, true) then
        -- V2: had ZZPIPEZZ escaping; restore pipes after loading
        data = str:sub(#PBM.EXPORT_PREFIX_V2 + 1)
    elseif str:find(PBM.EXPORT_PREFIX_V1, 1, true) then
        data = str:sub(#PBM.EXPORT_PREFIX_V1 + 1)
    else
        return nil, "Not a valid Lichborne export string."
    end
    local fn, err = loadstring("return " .. data)
    if not fn then return nil, "Parse error: " .. (err or "unknown") end
    local ok, result = pcall(fn)
    if not ok then return nil, "Load error: " .. tostring(result) end
    if type(result) ~= "table" then return nil, "Invalid data format." end
    -- V2 legacy: restore pipe placeholders in any ilvlLink strings
    if str:find(PBM.EXPORT_PREFIX_V2, 1, true) and result.rows then
        for _, row in pairs(result.rows) do
            if row.ilvlLink then
                for i, lnk in ipairs(row.ilvlLink) do
                    if type(lnk) == "string" and lnk ~= "" then
                        row.ilvlLink[i] = lnk:gsub("ZZPIPEZZ", "|")
                    end
                end
            end
        end
    end
    return result, nil
end
