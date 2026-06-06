-- ============================================================
--  LBT_StratList.lua  |  Tiered strategy display for class tab overlays
--  Provides:
--    PBM.CLASS_STRAT_LIST  — static reference data (tier lookup, kept for reference)
--    PBM.InstallTieredStratDisplay(menuFrame, cls)
--       Replaces the duplicated "Right-side strategy display column" block in
--       each class tab.  Driven by live co?/nc? bot data; sorts into 5 tiers;
--       deduplicates; labels CO / NC / BOTH.
-- ============================================================
PBM = PBM or {}

-- ── Class colour hex strings ─────────────────────────────────────
PBM.CLASS_COLOR_HEX = {
    ["Death Knight"] = "C41F3B",
    ["Druid"]        = "FF7D0A",
    ["Hunter"]       = "ABD473",
    ["Mage"]         = "40C7EB",
    ["Paladin"]      = "F58CBA",
    ["Priest"]       = "FFFFFF",
    ["Rogue"]        = "FFF569",
    ["Shaman"]       = "0070DE",
    ["Warlock"]      = "8787ED",
    ["Warrior"]      = "C79C6E",
}

-- ── Label / name colours by tier ─────────────────────────────────
local LAB_RED       = "ee4433"   -- T1  class-specific label
local NAME_YELLOW   = "ffff00"   -- T2  healer/buffs name
local LAB_ORANGE    = "ff8000"   -- T2  healer/buffs label
local NAME_ORANGE   = "ff8000"   -- T3  cross-role name
local LAB_GOLD      = "ffcc00"   -- T3  cross-role label
local NAME_DARKGOLD = "d4af37"   -- T4  loot/gather/food name
local LAB_GREEN     = "44aa44"   -- T4  loot/gather/food label
local LAB_GREY      = "aaaaaa"   -- T5  grey tier label (light grey)

-- Universal system strategies shown in grey for all classes
local UNIVERSAL_GREY = {
    ["aggressive"] = "CO",
    ["chat"]       = "NC",
    ["default"]    = "NC",
    ["duel"]       = "NC",
    ["emote"]      = "NC",
    ["mount"]      = "NC",
    ["quest"]      = "NC",
}

-- ── Per-class strategy reference data ───────────────────────────
-- Each entry: {n=name, lab="CO"|"NC"|"BOTH", t=tier}
--   t=1  Class Spec   — class colour name + red label
--   t=2  Healer/Buffs — yellow name + orange label (heal specs, buffs, blessings, resist auras)
--   t=3  Cross-Role   — orange name + gold label (tank assist, dps assist, cc)
--   t=4  Loot Tier    — dark gold name + green label (loot, gather, food only)
--   t=5  Grey Tier    — per-strategy colour name + grey label (everything else)
PBM.CLASS_STRAT_LIST = {

    -- ── Warrior ─────────────────────────────────────────────────
    ["Warrior"] = {
        {n="tank",        lab="CO", t=1},
        {n="arms",        lab="CO", t=1},
        {n="fury",        lab="CO", t=1},
        {n="aoe",         lab="CO", t=1},
        {n="dps aoe",     lab="CO", t=1},
        {n="PvP",         lab="CO", t=1},
        -- Tier 3 (cross-role)
        {n="pull",        lab="BOTH", t=3},
        {n="pull back",   lab="BOTH", t=3},
        {n="tank assist", lab="CO", t=3},
        {n="dps assist",  lab="CO", t=3},
        -- Tier 2 (buffs)
        {n="buff",        lab="NC", t=2},
        -- Tier 4 (loot)
        {n="loot",        lab="NC", t=4},
        {n="gather",      lab="NC", t=4},
        {n="food",        lab="NC", t=4},
        -- Tier 5 (grey)
        {n="boost",       lab="CO", t=5},
        {n="formation",   lab="CO", t=5},
        {n="avoid aoe",   lab="CO", t=5},
        {n="cast time",   lab="CO", t=5},
        {n="potions",     lab="CO", t=5},
        {n="racials",     lab="CO", t=5},
        {n="behind",      lab="CO", t=5},
        {n="save mana",   lab="CO", t=5},
        {n="nc",          lab="NC", t=5},
        {n="follow",      lab="NC", t=5},
        {n="guard",       lab="NC", t=5},
        {n="passive",     lab="NC", t=5},
        {n="tank face",   lab="NC", t=5},
    },

    -- ── Paladin ──────────────────────────────────────────────────
    ["Paladin"] = {
        {n="tank",        lab="CO",   t=1},
        {n="dps",         lab="CO",   t=1},
        {n="heal",        lab="CO",   t=1},
        {n="offheal",     lab="CO",   t=1},
        {n="healer dps",  lab="CO",   t=1},
        {n="dps aoe",     lab="CO",   t=1},
        {n="PvP",         lab="CO",   t=1},
        -- Tier 1 (blessings — pink name + red label)
        {n="bkings",      lab="NC",   t=1},
        {n="bsanc",       lab="NC",   t=1},
        {n="bwisdom",     lab="NC",   t=1},
        {n="bmight",      lab="NC",   t=1},
        -- Tier 2 (auras/buffs)
        {n="bthreat",     lab="BOTH", t=2},
        {n="bspeed",      lab="BOTH", t=2},
        {n="barmor",      lab="BOTH", t=2},
        {n="bcast",       lab="BOTH", t=2},
        {n="baoe",        lab="BOTH", t=2},
        {n="rshadow",     lab="BOTH", t=2},
        {n="rfrost",      lab="BOTH", t=2},
        {n="rfire",       lab="BOTH", t=2},
        {n="buff",        lab="NC",   t=2},
        {n="cure",        lab="CO",   t=2},
        -- Tier 3 (cross-role)
        {n="pull",        lab="BOTH", t=3},
        {n="pull back",   lab="BOTH", t=3},
        {n="dps assist",  lab="CO",   t=3},
        {n="tank assist", lab="CO",   t=3},
        {n="cc",          lab="CO",   t=3},
        -- Tier 4 (loot)
        {n="loot",        lab="NC",   t=4},
        {n="gather",      lab="NC",   t=4},
        {n="food",        lab="NC",   t=4},
        -- Tier 5 (grey)
        {n="boost",       lab="CO",   t=5},
        {n="avoid aoe",   lab="CO",   t=5},
        {n="cast time",   lab="CO",   t=5},
        {n="potions",     lab="CO",   t=5},
        {n="racials",     lab="CO",   t=5},
        {n="formation",   lab="CO",   t=5},
        {n="save mana",   lab="CO",   t=5},
        {n="nc",          lab="NC",   t=5},
        {n="follow",      lab="NC",   t=5},
        {n="guard",       lab="NC",   t=5},
        {n="behind",      lab="NC",   t=5},
        {n="passive",     lab="NC",   t=5},
        {n="tank face",   lab="NC",   t=5},
    },

    -- ── Hunter ───────────────────────────────────────────────────
    ["Hunter"] = {
        {n="bm",          lab="CO",   t=1},
        {n="mm",          lab="CO",   t=1},
        {n="surv",        lab="CO",   t=1},
        {n="aoe",         lab="CO",   t=1},
        {n="dps aoe",     lab="CO",   t=1},
        {n="trap weave",  lab="CO",   t=1},
        {n="pet",         lab="NC",   t=1},
        {n="PvP",         lab="CO",   t=1},
        -- Tier 2 (buffs)
        {n="buff",        lab="NC",   t=2},
        {n="bdps",        lab="BOTH", t=2},
        {n="bspeed",      lab="BOTH", t=2},
        {n="rnature",     lab="BOTH", t=2},
        -- Tier 3 (cross-role)
        {n="pull",        lab="BOTH", t=3},
        {n="dps assist",  lab="CO",   t=3},
        {n="tank assist", lab="CO",   t=3},
        {n="cc",          lab="CO",   t=3},
        -- Tier 4 (loot)
        {n="loot",        lab="NC",   t=4},
        {n="gather",      lab="NC",   t=4},
        {n="food",        lab="NC",   t=4},
        -- Tier 5 (grey)
        {n="boost",       lab="CO",   t=5},
        {n="avoid aoe",   lab="CO",   t=5},
        {n="cast time",   lab="CO",   t=5},
        {n="potions",     lab="CO",   t=5},
        {n="racials",     lab="CO",   t=5},
        {n="formation",   lab="CO",   t=5},
        {n="save mana",   lab="CO",   t=5},
        {n="nc",          lab="NC",   t=5},
        {n="follow",      lab="NC",   t=5},
        {n="guard",       lab="NC",   t=5},
        {n="behind",      lab="NC",   t=5},
        {n="passive",     lab="NC",   t=5},
        {n="tank face",   lab="NC",   t=5},
    },

    -- ── Rogue ────────────────────────────────────────────────────
    ["Rogue"] = {
        {n="dps",         lab="CO", t=1},
        {n="melee",       lab="CO", t=1},
        {n="aoe",         lab="CO", t=1},
        {n="dps aoe",     lab="CO", t=1},
        {n="stealth",     lab="CO", t=1},
        {n="stealthed",   lab="CO", t=1},
        {n="boost",       lab="CO", t=1},
        {n="PvP",         lab="CO", t=1},
        -- Tier 2 (buffs)
        {n="buff",        lab="NC", t=2},
        -- Tier 3 (cross-role)
        {n="pull",        lab="BOTH", t=3},
        {n="dps assist",  lab="CO", t=3},
        {n="tank assist", lab="CO", t=3},
        {n="cc",          lab="CO", t=3},
        -- Tier 4 (loot)
        {n="loot",        lab="NC", t=4},
        {n="gather",      lab="NC", t=4},
        {n="food",        lab="NC", t=4},
        -- Tier 5 (grey)
        {n="behind",      lab="CO", t=5},
        {n="avoid aoe",   lab="CO", t=5},
        {n="cast time",   lab="CO", t=5},
        {n="potions",     lab="CO", t=5},
        {n="racials",     lab="CO", t=5},
        {n="formation",   lab="CO", t=5},
        {n="save mana",   lab="CO", t=5},
        {n="nc",          lab="NC", t=5},
        {n="follow",      lab="NC", t=5},
        {n="guard",       lab="NC", t=5},
        {n="passive",     lab="NC", t=5},
        {n="tank face",   lab="NC", t=5},
    },

    -- ── Priest ───────────────────────────────────────────────────
    ["Priest"] = {
        {n="holy heal",     lab="CO", t=1},
        {n="heal",          lab="CO", t=1},
        {n="shadow",        lab="CO", t=1},
        {n="holy dps",      lab="CO", t=1},
        {n="shadow debuff", lab="CO", t=1},
        {n="shadow aoe",    lab="CO", t=1},
        {n="aoe",           lab="CO", t=1},
        {n="dps aoe",       lab="CO", t=1},
        {n="healer dps",    lab="CO", t=1},
        {n="rshadow",       lab="NC", t=1},
        {n="PvP",           lab="CO", t=1},
        -- Tier 2 (buffs)
        {n="buff",          lab="NC", t=2},
        {n="cure",          lab="CO", t=2},
        -- Tier 3 (cross-role)
        {n="pull",          lab="BOTH", t=3},
        {n="dps assist",    lab="CO", t=3},
        {n="tank assist",   lab="CO", t=3},
        {n="cc",            lab="CO", t=3},
        -- Tier 4 (loot)
        {n="loot",          lab="NC", t=4},
        {n="gather",        lab="NC", t=4},
        {n="food",          lab="NC", t=4},
        -- Tier 5 (grey)
        {n="boost",         lab="CO", t=5},
        {n="avoid aoe",     lab="CO", t=5},
        {n="cast time",     lab="CO", t=5},
        {n="potions",       lab="CO", t=5},
        {n="racials",       lab="CO", t=5},
        {n="formation",     lab="CO", t=5},
        {n="save mana",     lab="CO", t=5},
        {n="nc",            lab="NC", t=5},
        {n="follow",        lab="NC", t=5},
        {n="guard",         lab="NC", t=5},
        {n="behind",        lab="NC", t=5},
        {n="passive",       lab="NC", t=5},
        {n="tank face",     lab="NC", t=5},
    },

    -- ── Shaman ───────────────────────────────────────────────────
    ["Shaman"] = {
        {n="ele",              lab="CO", t=1},
        {n="enh",              lab="CO", t=1},
        {n="resto",            lab="CO", t=1},
        {n="aoe",              lab="CO", t=1},
        {n="dps aoe",          lab="CO", t=1},
        {n="healer dps",       lab="CO", t=1},
        {n="PvP",              lab="CO", t=1},
        -- Tier 2 (buffs + totems)
        {n="totems",           lab="CO", t=2},
        {n="bmana",            lab="BOTH", t=2},
        {n="bdps",             lab="BOTH", t=2},
        {n="strength of earth",lab="CO", t=2},
        {n="stoneskin",        lab="CO", t=2},
        {n="tremor",           lab="CO", t=2},
        {n="earthbind",        lab="CO", t=2},
        {n="searing",          lab="CO", t=2},
        {n="magma",            lab="CO", t=2},
        {n="flametongue",      lab="CO", t=2},
        {n="wrath",            lab="CO", t=2},
        {n="frost resistance", lab="CO", t=2},
        {n="healing stream",   lab="CO", t=2},
        {n="mana spring",      lab="CO", t=2},
        {n="cleansing",        lab="CO", t=2},
        {n="fire resistance",  lab="CO", t=2},
        {n="wrath of air",     lab="CO", t=2},
        {n="windfury",         lab="CO", t=2},
        {n="nature resistance",lab="CO", t=2},
        {n="grounding",        lab="CO", t=2},
        {n="buff",             lab="NC", t=2},
        {n="cure",             lab="CO", t=2},
        -- Tier 3 (cross-role)
        {n="pull",             lab="BOTH", t=3},
        {n="dps assist",       lab="CO", t=3},
        {n="tank assist",      lab="CO", t=3},
        {n="cc",               lab="CO", t=3},
        -- Tier 4 (loot)
        {n="loot",             lab="NC", t=4},
        {n="gather",           lab="NC", t=4},
        {n="food",             lab="NC", t=4},
        -- Tier 5 (grey)
        {n="boost",            lab="CO", t=5},
        {n="avoid aoe",        lab="CO", t=5},
        {n="cast time",        lab="CO", t=5},
        {n="potions",          lab="CO", t=5},
        {n="racials",          lab="CO", t=5},
        {n="formation",        lab="CO", t=5},
        {n="save mana",        lab="CO", t=5},
        {n="nc",               lab="NC", t=5},
        {n="follow",           lab="NC", t=5},
        {n="guard",            lab="NC", t=5},
        {n="behind",           lab="CO", t=5},
        {n="passive",          lab="NC", t=5},
        {n="tank face",        lab="NC", t=5},
    },

    -- ── Mage ─────────────────────────────────────────────────────
    ["Mage"] = {
        {n="frost",       lab="CO", t=1},
        {n="fire",        lab="CO", t=1},
        {n="arcane",      lab="CO", t=1},
        {n="frostfire",   lab="CO", t=1},
        {n="aoe",         lab="CO", t=1},
        {n="firestarter", lab="CO", t=1},
        {n="PvP",         lab="CO", t=1},
        -- Tier 2 (buffs)
        {n="bmana",       lab="NC", t=2},
        {n="bdps",        lab="NC", t=2},
        {n="buff",        lab="NC", t=2},
        {n="cure",        lab="CO", t=2},
        -- Tier 3 (cross-role)
        {n="pull",        lab="BOTH", t=3},
        {n="dps aoe",     lab="CO", t=3},
        {n="dps assist",  lab="CO", t=3},
        {n="tank assist", lab="CO", t=3},
        {n="cc",          lab="CO", t=3},
        -- Tier 4 (loot)
        {n="loot",        lab="NC", t=4},
        {n="gather",      lab="NC", t=4},
        {n="food",        lab="NC", t=4},
        -- Tier 5 (grey)
        {n="boost",       lab="CO", t=5},
        {n="avoid aoe",   lab="CO", t=5},
        {n="cast time",   lab="CO", t=5},
        {n="potions",     lab="CO", t=5},
        {n="racials",     lab="CO", t=5},
        {n="formation",   lab="CO", t=5},
        {n="save mana",   lab="CO", t=5},
        {n="nc",          lab="NC", t=5},
        {n="follow",      lab="NC", t=5},
        {n="guard",       lab="NC", t=5},
        {n="behind",      lab="NC", t=5},
        {n="passive",     lab="NC", t=5},
        {n="tank face",   lab="NC", t=5},
    },

    -- ── Warlock ──────────────────────────────────────────────────
    ["Warlock"] = {
        {n="affli",              lab="CO", t=1},
        {n="demo",               lab="CO", t=1},
        {n="destro",             lab="CO", t=1},
        {n="aoe",                lab="CO", t=1},
        {n="dps aoe",            lab="CO", t=1},
        {n="meta melee",         lab="CO", t=1},
        {n="tank",               lab="CO", t=1},
        {n="curse of agony",     lab="CO", t=1},
        {n="curse of elements",  lab="CO", t=1},
        {n="curse of doom",      lab="CO", t=1},
        {n="curse of exhaustion",lab="CO", t=1},
        {n="curse of tongues",   lab="CO", t=1},
        {n="curse of weakness",  lab="CO", t=1},
        {n="imp",                lab="NC", t=1},
        {n="voidwalker",         lab="NC", t=1},
        {n="succubus",           lab="NC", t=1},
        {n="felhunter",          lab="NC", t=1},
        {n="felguard",           lab="NC", t=1},
        {n="ss self",            lab="NC", t=1},
        {n="ss master",          lab="NC", t=1},
        {n="ss tank",            lab="NC", t=1},
        {n="ss healer",          lab="NC", t=1},
        {n="firestone",          lab="NC", t=1},
        {n="spellstone",         lab="NC", t=1},
        {n="PvP",                lab="CO", t=1},
        -- Tier 2 (buffs)
        {n="buff",               lab="NC", t=2},
        -- Tier 3 (cross-role)
        {n="pull",               lab="BOTH", t=3},
        {n="dps assist",         lab="CO", t=3},
        {n="tank assist",        lab="CO", t=3},
        {n="cc",                 lab="CO", t=3},
        -- Tier 4 (loot)
        {n="loot",               lab="NC", t=4},
        {n="gather",             lab="NC", t=4},
        {n="food",               lab="NC", t=4},
        -- Tier 5 (grey)
        {n="boost",              lab="CO", t=5},
        {n="avoid aoe",          lab="CO", t=5},
        {n="cast time",          lab="CO", t=5},
        {n="potions",            lab="CO", t=5},
        {n="racials",            lab="CO", t=5},
        {n="formation",          lab="CO", t=5},
        {n="save mana",          lab="CO", t=5},
        {n="nc",                 lab="NC", t=5},
        {n="follow",             lab="NC", t=5},
        {n="guard",              lab="NC", t=5},
        {n="behind",             lab="NC", t=5},
        {n="passive",            lab="NC", t=5},
        {n="tank face",          lab="NC", t=5},
    },

    -- ── Druid ────────────────────────────────────────────────────
    ["Druid"] = {
        {n="bear",         lab="CO", t=1},
        {n="cat",          lab="CO", t=1},
        {n="balance",      lab="CO", t=1},
        {n="caster",       lab="CO", t=1},  -- server fallback for balance
        {n="restoration",  lab="CO", t=1},
        {n="resto",        lab="CO", t=1},  -- server canonical key (maps to "Restoration" display)
        {n="heal",         lab="CO", t=1},  -- server fallback for restoration
        {n="offheal",      lab="CO", t=1},
        {n="healer dps",   lab="CO", t=1},
        {n="tranquility",  lab="CO", t=1},
        {n="blanketing",   lab="CO", t=1},
        {n="aoe",          lab="CO", t=1},
        {n="feral charge", lab="CO", t=1},
        {n="dps aoe",      lab="CO", t=1},
        {n="PvP",          lab="CO", t=1},
        -- Tier 2 (buffs)
        {n="buff",         lab="NC", t=2},
        {n="cure",         lab="CO", t=2},
        -- Tier 3 (cross-role)
        {n="pull",         lab="BOTH", t=3},
        {n="pull back",    lab="BOTH", t=3},
        {n="dps assist",   lab="CO", t=3},
        {n="tank assist",  lab="CO", t=3},
        {n="cc",           lab="CO", t=3},
        -- Tier 4 (loot)
        {n="loot",         lab="NC", t=4},
        {n="gather",       lab="NC", t=4},
        {n="food",         lab="NC", t=4},
        -- Tier 5 (grey)
        {n="boost",        lab="CO", t=5},
        {n="avoid aoe",    lab="CO", t=5},
        {n="cast time",    lab="CO", t=5},
        {n="potions",      lab="CO", t=5},
        {n="racials",      lab="CO", t=5},
        {n="formation",    lab="CO", t=5},
        {n="save mana",    lab="CO", t=5},
        {n="nc",           lab="NC", t=5},
        {n="follow",       lab="NC", t=5},
        {n="guard",        lab="NC", t=5},
        {n="behind",       lab="NC", t=5},
        {n="passive",      lab="NC", t=5},
        {n="tank face",    lab="NC", t=5},
    },

    -- ── Death Knight ─────────────────────────────────────────────
    ["Death Knight"] = {
        {n="blood",      lab="CO", t=1},
        {n="frost",      lab="CO", t=1},
        {n="unholy",     lab="CO", t=1},
        {n="frost aoe",  lab="CO", t=1},
        {n="unholy aoe", lab="CO", t=1},
        {n="dps aoe",    lab="CO", t=1},
        {n="PvP",        lab="CO", t=1},
        -- Tier 2 (buffs)
        {n="bdps",       lab="NC", t=2},
        {n="buff",       lab="NC", t=2},
        -- Tier 3 (cross-role)
        {n="pull",       lab="BOTH", t=3},
        {n="pull back",  lab="BOTH", t=3},
        {n="dps assist", lab="CO", t=3},
        {n="tank assist",lab="CO", t=3},
        -- Tier 4 (loot)
        {n="loot",       lab="NC", t=4},
        {n="gather",     lab="NC", t=4},
        {n="food",       lab="NC", t=4},
        -- Tier 5 (grey)
        {n="boost",      lab="CO", t=5},
        {n="avoid aoe",  lab="CO", t=5},
        {n="cast time",  lab="CO", t=5},
        {n="potions",    lab="CO", t=5},
        {n="racials",    lab="CO", t=5},
        {n="formation",  lab="CO", t=5},
        {n="save mana",  lab="CO", t=5},
        {n="nc",         lab="NC", t=5},
        {n="follow",     lab="NC", t=5},
        {n="guard",      lab="NC", t=5},
        {n="behind",     lab="NC", t=5},
        {n="passive",    lab="NC", t=5},
        {n="tank face",  lab="NC", t=5},
    },
}

-- ── PBM.InstallTieredStratDisplay ───────────────────────────────
function PBM.InstallTieredStratDisplay(menuFrame, cls)
    local clsHex  = PBM.CLASS_COLOR_HEX[cls] or "999999"
    local listDef = PBM.CLASS_STRAT_LIST[cls] or {}

    local tierLookup = {}
    for pos, entry in ipairs(listDef) do
        tierLookup[entry.n:lower()] = { t = entry.t, pos = pos, lab = entry.lab }
    end
    for gname, glab in pairs(UNIVERSAL_GREY) do
        if not tierLookup[gname] then
            tierLookup[gname] = { t = 5, pos = 9998, lab = glab }
        end
    end

    local STRAT_LINE_H    = 14
    local STRAT_MAX       = 25
    local STRAT_RIGHT_PAD = 6
    local STRAT_TOP_PAD   = 6 + PBM.ROW_HEIGHT + 15

    menuFrame.stratLines = {}
    for i = 1, STRAT_MAX do
        local fs = menuFrame:CreateFontString(nil, "OVERLAY")
        fs:SetFont("Fonts\\FRIZQT__.TTF", 9)
        fs:SetJustifyH("RIGHT")
        fs:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", 0, 0)
        fs:SetText("")
        fs:Hide()
        menuFrame.stratLines[i] = fs
    end

    local function ClearStratDisplay()
        for i = 1, STRAT_MAX do
            menuFrame.stratLines[i]:SetText("")
            menuFrame.stratLines[i]:Hide()
        end
        menuFrame._coStrats = nil
        menuFrame._ncStrats = nil
    end

    -- Bot abbreviations → canonical tierLookup key
    local STRAT_ALIAS = {
        ["enc"]   = "enh",
        ["retro"] = "resto",
    }
    -- Canonical key → full display name shown in the strategy list
    local STRAT_DISPLAY = {
        ["ele"]   = "Elemental",
        ["enh"]   = "Enhancement",
        ["resto"] = "resto",
    }

    local CLASS_FILTER = {}

    local function RefreshStratDisplay()
        local FILTER_OUT = {
            chat=true, default=true, duel=true, emote=true,
            mount=true, quest=true, nc=true, ["save mana"]=true,
        }
        -- merge class-specific filters into FILTER_OUT
        if CLASS_FILTER[cls] then
            for k, v in pairs(CLASS_FILTER[cls]) do FILTER_OUT[k] = v end
        end

        local NC_FILTER = { ["dps assist"] = true, ["cure"] = true }
        local rows = {}
        local function addStrats(bucket, lab)
            local extraFilter = (lab == "NC") and NC_FILTER or nil
            for lname, name in pairs(menuFrame[bucket] or {}) do
                if not FILTER_OUT[lname] and not (extraFilter and extraFilter[lname]) then
                    local lkup = tierLookup[lname]
                    rows[#rows + 1] = {
                        name = (lname == "pvp") and "PvP" or name,
                        lab  = lab,
                        t    = (lkup and lkup.t)  or 5,
                        pos  = (lkup and lkup.pos) or 9999,
                    }
                end
            end
        end
        addStrats("_coStrats", "CO")
        addStrats("_ncStrats", "NC")

        -- Sort: T1 → T2 → T3 → T4 → T5, then position within tier; PvP always first
        table.sort(rows, function(a, b)
            if a.t ~= b.t then return a.t < b.t end
            local aP = a.name:lower() == "pvp"
            local bP = b.name:lower() == "pvp"
            if aP ~= bP then return aP end
            return a.pos < b.pos
        end)

        local count     = math.min(#rows, STRAT_MAX)
        local topOffset = STRAT_TOP_PAD + math.floor((STRAT_MAX - count) * STRAT_LINE_H / 2)

        for i = 1, STRAT_MAX do
            local row = rows[i]
            if row then
                local fs = menuFrame.stratLines[i]
                fs:ClearAllPoints()
                fs:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT",
                            -STRAT_RIGHT_PAD, -(topOffset + (i - 1) * STRAT_LINE_H))
                local nameHex, labHex
                local lname = row.name:lower()
                if row.t == 1 then
                    if lname == "pvp" then
                        nameHex = LAB_RED
                    elseif lname == "heal" or lname == "resto" or lname == "healer dps" then
                        local healClasses = {Paladin=true, Druid=true, Priest=true, Shaman=true}
                        nameHex = healClasses[cls] and clsHex or LAB_GOLD
                    else
                        nameHex = clsHex
                    end
                    labHex = LAB_RED
                elseif row.t == 2 then
                    nameHex = NAME_YELLOW; labHex = LAB_ORANGE
                elseif row.t == 3 then
                    nameHex = (lname == "pull" or lname == "pull back") and NAME_YELLOW or NAME_ORANGE
                    labHex  = LAB_GOLD
                elseif row.t == 4 then
                    nameHex = NAME_DARKGOLD; labHex = LAB_GREEN
                elseif row.t == 5 then
                    local sc = PBM and PBM.STRATEGY_COLORS and PBM.STRATEGY_COLORS[lname]
                    nameHex = sc or "888888"
                    labHex  = LAB_GREY
                elseif row.lab == "??" then
                    nameHex = "888888"; labHex = "ff4400"
                else
                    local sc = PBM and PBM.STRATEGY_COLORS and PBM.STRATEGY_COLORS[lname]
                    nameHex = sc or "888888"
                    labHex  = LAB_GREY
                end
                menuFrame.stratLines[i]:SetText(
                    "|cff" .. nameHex .. row.name .. "|r"
                    .. " |cff" .. labHex .. row.lab .. "|r"
                )
                menuFrame.stratLines[i]:Show()
            else
                menuFrame.stratLines[i]:SetText("")
                menuFrame.stratLines[i]:Hide()
            end
        end
    end

    menuFrame.onStrategyUpdate = function(stratType, activeSet)
        local bucket = stratType:lower() == "co" and "_coStrats" or "_ncStrats"
        menuFrame[bucket] = {}
        for name in pairs(activeSet) do
            local lname    = name:lower()
            local canonical = STRAT_ALIAS[lname] or lname
            menuFrame[bucket][canonical] = STRAT_DISPLAY[canonical] or name
        end
        RefreshStratDisplay()
    end

    menuFrame.clearStratDisplay = ClearStratDisplay
end
