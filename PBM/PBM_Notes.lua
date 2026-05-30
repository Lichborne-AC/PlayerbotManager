local NOTE_COLORS = {
    red    = "ffff5555",
    gold   = "ffffd100",  -- Charsheet gold (Buffs)
    purple = "ffa335ee",  -- Epic purple   (AoE)
    blue   = "ff0070dd",  -- Rare blue     (Tank)
    green  = "ff1eff00",  -- Uncommon green (Heal)
    orange = "ffff8000",  -- Legendary orange (DPS)
}

PBM.NOTES_ROLE_ICONS = {
    T = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    H = "Interface\\Icons\\Spell_ChargePositive",
    D = "Interface\\Icons\\Ability_DualWield",
    A = "Interface\\Icons\\Spell_Shadow_RainOfFire",
}

PBM.NOTES_CONFIG = {
    druid = {
        { cmd="buff",          p=3, n="Buff",       r={"B"} },
        { cmd="bear",          p=1, n="Bear",       r={"T"} },
        { cmd="cat",           p=1, n="Cat",        r={"D"} },
        { cmd="caster",        p=1, n="Bal",        r={"D"} },
        { cmd="resto",         p=1, n="Rest",       r={"H"} },
        { cmd="tranquility",   p=1, n="Tranq",      r={"H"} },
        { cmd="blanketing",    p=1, n="Blanket",    r={"H"} },
        { cmd="feral charge",  p=2, n="FCharge",    r={"D"} },
        { cmd="melee",         p=3, n="Melee",      r={"D"} },
        { cmd="healer dps",    p=2, n="HealerDPS",  r={"H","D"} },
        { cmd="offheal",       p=2, n="OffHeal",    r={"D","H"} },
        { cmd="aoe",           p=2, n="AoE",        r={"A"} },
        { cmd="caster debuff", p=4, n="Debuff",     r={"B"} },
        { cmd="tank assist",   p=5, n="TAssist",    r={"D"} },
        { cmd="dps assist",    p=5, n="DAssist",    r={"D"} },
    },
    paladin = {
        { cmd="heal",       p=1, n="Heal",       r={"H"} },
        { cmd="tank",       p=1, n="Tank",       r={"T"} },
        { cmd="dps",        p=1, n="Ret",        r={"D"} },
        { cmd="healer dps", p=2, n="HealerDPS",  r={"H","D"} },
        { cmd="offheal",    p=2, n="OffHeal",    r={"D","H"} },
        { cmd="tank assist",p=5, n="TAssist",    r={"D"} },
        { cmd="dps assist", p=5, n="DAssist",    r={"D"} },
        { cmd="dps aoe",    p=2, n="AoE",        r={"A"} },
        { cmd="bspeed",     p=4, n="CrusAura",   r={"B"} },
        { cmd="barmor",     p=4, n="DevAura",    r={"B"} },
        { cmd="bcast",      p=4, n="ConAura",    r={"B"} },
        { cmd="baoe",       p=4, n="RetAura",    r={"B"} },
        { cmd="rfire",      p=4, n="FireRes",    r={"B"} },
        { cmd="rfrost",     p=4, n="FrostRes",   r={"B"} },
        { cmd="rshadow",    p=4, n="ShadRes",    r={"B"} },
        { cmd="bstats",     p=3, n="Kings",      r={"B"} },
        { cmd="bhealth",    p=3, n="Sanct",      r={"B"} },
        { cmd="bmana",      p=3, n="Wisdom",     r={"B"} },
        { cmd="bdps",       p=3, n="Might",      r={"B"} },
    },
    priest = {
        { cmd="buff",         p=3, n="Buff",      r={"B"} },
        { cmd="rshadow",      p=3, n="ShadRes",   r={"B"} },
        { cmd="heal",         p=1, n="Heal",      r={"H"} },
        { cmd="holy heal",    p=1, n="HolyHeal",  r={"H"} },
        { cmd="holy dps",     p=1, n="HolyDPS",   r={"H","D"} },
        { cmd="shadow",       p=1, n="Shadow",    r={"D"} },
        { cmd="healer dps",   p=2, n="HealerDPS", r={"H","D"} },
        { cmd="shadow aoe",   p=4, n="AoE",       r={"A"} },
        { cmd="shadow debuff",p=4, n="Debuff",    r={"B"} },
        { cmd="tank assist",  p=5, n="TAssist",   r={"D"} },
    },
    mage = {
        { cmd="buff",        p=3, n="Buff",       r={"B"} },
        { cmd="cure",        p=3, n="Cure",       r={"B"} },
        { cmd="arcane",      p=1, n="Arcane",     r={"D"} },
        { cmd="fire",        p=1, n="Fire",       r={"D"} },
        { cmd="frost",       p=1, n="Frost",      r={"D"} },
        { cmd="frostfire",   p=1, n="Frostfire",  r={"D"} },
        { cmd="aoe",         p=2, n="AoE",        r={"A"} },
        { cmd="firestarter", p=1, n="Firestarter",r={"D"} },
        { cmd="bmana",       p=3, n="MageArmor",  r={"B"} },
        { cmd="bdps",        p=3, n="Molten",     r={"B"} },
        { cmd="tank assist", p=5, n="TAssist",    r={"D"} },
        { cmd="dps assist",  p=5, n="DAssist",    r={"D"} },
    },
    warrior = {
        { cmd="tank",        p=1, n="Tank",    r={"T"} },
        { cmd="aoe",         p=2, n="AoE",     r={"A"} },
        { cmd="tank assist", p=5, n="TAssist", r={"D"} },
        { cmd="dps assist",  p=5, n="DAssist", r={"D"} },
    },
    hunter = {
        { cmd="bm",          p=1, n="Beast",     r={"D"} },
        { cmd="mm",          p=1, n="Marksman",  r={"D"} },
        { cmd="surv",        p=1, n="Surv",      r={"D"} },
        { cmd="dps",         p=2, n="DPS",       r={"D"} },
        { cmd="dps debuff",  p=3, n="Debuff",    r={"D"} },
        { cmd="trap weave",  p=3, n="TrapWeave", r={"D"} },
        { cmd="tank assist", p=5, n="TAssist",   r={"D"} },
        { cmd="dps assist",  p=5, n="DAssist",   r={"D"} },
        { cmd="aoe",         p=2, n="AoE",       r={"A"} },
        { cmd="bdps",        p=4, n="DHawk",     r={"B"} },
        { cmd="bmana",       p=4, n="Viper",     r={"B"} },
        { cmd="bspeed",      p=4, n="Pack",      r={"B"} },
        { cmd="rnature",     p=4, n="Wild",      r={"B"} },
    },
    rogue = {
        { cmd="melee",       p=1, n="Melee",     r={"D"} },
        { cmd="dps",         p=1, n="Combat",    r={"D"} },
        { cmd="stealth",     p=3, n="Stealth",   r={"D"} },
        { cmd="stealthed",   p=3, n="Stealthed", r={"D"} },
        { cmd="boost",       p=3, n="Boost",     r={"D"} },
        { cmd="tank assist", p=5, n="TAssist",   r={"D"} },
        { cmd="dps assist",  p=5, n="DAssist",   r={"D"} },
        { cmd="aoe",         p=2, n="AoE",       r={"A"} },
    },
    shaman = {
        { cmd="cure",        p=3, n="Cure",      r={"B"} },
        { cmd="ele",         p=1, n="Ele",       r={"D"} },
        { cmd="enh",         p=1, n="Enh",       r={"D"} },
        { cmd="resto",       p=1, n="Resto",     r={"H"} },
        { cmd="caster aoe",  p=3, n="CAoE",      r={"A"} },
        { cmd="melee aoe",   p=3, n="MAoE",      r={"A"} },
        { cmd="healer dps",  p=2, n="HealerDPS", r={"H","D"} },
        { cmd="totems",      p=4, n="Totem",     r={"B"} },
        { cmd="bmana",       p=5, n="ManaTotem", r={"B"} },
        { cmd="bdps",        p=5, n="DPSTotem",  r={"B"} },
        { cmd="tank assist", p=4, n="TAssist",   r={"D"} },
        { cmd="dps assist",  p=4, n="DAssist",   r={"D"} },
        { cmd="aoe",         p=4, n="AoE",       r={"A"} },
    },
    warlock = {
        { cmd="spellstone",          p=5, n="Spellstone",  r={"B"} },
        { cmd="firestone",           p=5, n="Firestone",   r={"B"} },
        { cmd="affli",               p=1, n="Afflict",    r={"D"} },
        { cmd="demo",                p=1, n="Demono",     r={"D"} },
        { cmd="destro",              p=1, n="Destru",     r={"D"} },
        { cmd="aoe",                 p=2, n="AoE",        r={"A"} },
        { cmd="meta melee",          p=2, n="MMelee",     r={"A"} },
        { cmd="tank",                p=5, n="Tank",       r={} },
        { cmd="dps",                 p=3, n="DPS",        r={"D"} },
        { cmd="tank assist",         p=5, n="TAssist",    r={"D"} },
        { cmd="dps assist",          p=5, n="DAssist",    r={"D"} },
        { cmd="curse of agony",      p=5, n="Agony",      r={"D"} },
        { cmd="curse of elements",   p=5, n="Elements",   r={"D"} },
        { cmd="curse of exhaustion", p=5, n="Exhaust",    r={"D"} },
        { cmd="curse of doom",       p=5, n="Doom",       r={"D"} },
        { cmd="curse of weakness",   p=5, n="Weakness",   r={"D"} },
        { cmd="curse of tongues",    p=5, n="Tongues",    r={"D"} },
        { cmd="imp",                 p=4, n="Imp",        r={"B"} },
        { cmd="voidwalker",          p=4, n="Void",       r={"B"} },
        { cmd="succubus",            p=4, n="Succ",       r={"B"} },
        { cmd="felhunter",           p=4, n="Felhtr",     r={"B"} },
        { cmd="felguard",            p=4, n="Felgrd",     r={"B"} },
        { cmd="ss self",             p=5, n="SSSelf",     r={"B"} },
        { cmd="ss master",           p=5, n="SSMaster",   r={"B"} },
        { cmd="ss tank",             p=5, n="SSTank",     r={"B"} },
        { cmd="ss healer",           p=5, n="SSHealer",   r={"B"} },
    },
    deathknight = {
        { cmd="blood",       p=1, n="Blood",      r={"T"} },
        { cmd="frost",       p=1, n="Frost",      r={"D"} },
        { cmd="unholy",      p=1, n="Unholy",     r={"D"} },
        { cmd="frost aoe",   p=2, n="FrostAoE",   r={"A"} },
        { cmd="unholy aoe",  p=2, n="UnholyAoE",  r={"A"} },
        { cmd="tank assist", p=5, n="TAssist",    r={"D"} },
        { cmd="dps assist",  p=5, n="DAssist",    r={"D"} },
        { cmd="dps aoe",     p=3, n="AoE",        r={"A"} },
    },
}

-- Build fast lookup: class -> cmd -> entry (first match wins)
PBM.NOTES_CMD_LOOKUP = {}
for cls, entries in pairs(PBM.NOTES_CONFIG) do
    local lookup = {}
    for _, e in ipairs(entries) do
        if not lookup[e.cmd] then
            lookup[e.cmd] = e
        end
    end
    PBM.NOTES_CMD_LOOKUP[cls] = lookup
end

local function DeriveColor(cmd, roles)
    if cmd == "pvp" then return "red" end
    for _, r in ipairs(roles) do if r == "B" then return "gold" end end
    for _, r in ipairs(roles) do if r == "A" then return "purple" end end
    local r1 = roles[1] or ""
    local r2 = roles[2] or ""
    local rs = r1 .. r2
    if rs == "T" then return "blue" end
    if rs == "H" or rs == "HD" then return "green" end
    if rs == "DH" then return "red" end
    if rs == "D" then return "orange" end
    return nil
end

local function ColorWrap(text, colorKey)
    local hex = NOTE_COLORS[colorKey]
    if not hex then return "[" .. text .. "]" end
    return "|cff" .. hex:sub(3) .. "[" .. text .. "]|r"
end

function PBM.GetBotClass(name)
    local key = name:lower()
    if LichborneTrackerDB and LichborneTrackerDB.rows then
        for _, row in ipairs(LichborneTrackerDB.rows) do
            if row.name and row.name:lower() == key and row.cls and row.cls ~= "" then
                return row.cls:lower():gsub("%s+", "")
            end
        end
    end
    return nil
end

function PBM.ComputeBotNotes(name, coSet, ncSet)
    local cls = PBM.GetBotClass(name)
    if not cls then
        LichborneOutput("|cffff4444CHARACTER NOT AVAILABLE: " .. name .. "|r")
        return nil, {}
    end

    local lookup = PBM.NOTES_CMD_LOOKUP[cls]
    if not lookup then return nil, {} end

    -- Collect matching entries (deduplicate by entry reference)
    local seen = {}
    local matched = {}
    for cmd, _ in pairs(coSet) do
        local e = lookup[cmd]
        if e and not seen[e] then
            seen[e] = true
            table.insert(matched, e)
        end
    end
    for cmd, _ in pairs(ncSet) do
        local e = lookup[cmd]
        if e and not seen[e] then
            seen[e] = true
            table.insert(matched, e)
        end
    end

    -- Sort: pvp first, then by priority ascending
    table.sort(matched, function(a, b)
        if a.cmd == "pvp" then return true end
        if b.cmd == "pvp" then return false end
        return a.p < b.p
    end)

    -- Build note string and role list
    local parts = {}
    local rolesSeen = {}
    local roleList = {}

    for _, e in ipairs(matched) do
        local color = DeriveColor(e.cmd, e.r)
        if color then
            table.insert(parts, ColorWrap(e.n, color))
        end
        for _, r in ipairs(e.r) do
            if r ~= "B" and not rolesSeen[r] then
                rolesSeen[r] = true
                table.insert(roleList, r)
            end
        end
    end

    local noteStr = table.concat(parts, "")
    return noteStr, roleList
end

-- Returns a sorted, display-ready role list for a bot (up to 2 entries).
-- If only 1 role exists it is mirrored so both icon slots are always filled.
-- Used by both the Raid tab and the Overview tab.
function PBM.GetSortedVisRoles(name)
    local botNE = LichborneTrackerDB.botNotes and name and name ~= ""
                  and LichborneTrackerDB.botNotes[name:lower()]
    local rawRoles = botNE and botNE.roles or {}
    local visRoles = {}
    for _, r in ipairs(rawRoles) do
        if PBM.NOTES_ROLE_ICONS and PBM.NOTES_ROLE_ICONS[r] then
            visRoles[#visRoles+1] = r
        end
    end
    local isTank = false
    for _, r in ipairs(visRoles) do if r == "T" then isTank = true; break end end
    local roleOrder = isTank and { T=1, A=2, D=3, H=4 } or { T=1, H=2, D=3, A=4 }
    table.sort(visRoles, function(a, b)
        return (roleOrder[a] or 9) < (roleOrder[b] or 9)
    end)
    if #visRoles == 1 then visRoles[2] = visRoles[1] end
    return visRoles
end

function PBM.ApplyBotNotes(name, coSet, ncSet)
    local noteStr, roleList = PBM.ComputeBotNotes(name, coSet, ncSet)
    if noteStr == nil then return end

    if not LichborneTrackerDB.botNotes then
        LichborneTrackerDB.botNotes = {}
    end

    local key = name:lower()
    LichborneTrackerDB.botNotes[key] = {
        notes = noteStr,
        roles = roleList,
    }

    -- Refresh UI if visible
    if PBM.RefreshRaidRows then PBM.RefreshRaidRows() end
    if PBM.RefreshOverviewRows then PBM.RefreshOverviewRows() end
end
