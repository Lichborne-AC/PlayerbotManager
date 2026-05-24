-- ============================================================
--  LBT_Constants.lua  |  Pure data — no logic, no UI, no state
-- ============================================================
PBM = PBM or {}

PBM.MAX_RAID_SLOTS = 40
PBM.ROW_HEIGHT     = 24
PBM.GEAR_SLOTS     = 17
PBM.MAX_ROWS       = 18
PBM.SLOT_ABBR      = {"Head","Neck","Shldr","Back","Chest","Wrist","Hands","Waist","Legs","Feet","Ring1","Ring2","Trnk1","Trnk2","MH","OH","Rngd"}

PBM.GS_SCALE = 1.8618
PBM.GS_ITEM_TYPES = {
    ["INVTYPE_RELIC"] = { slotMod = 0.3164 },
    ["INVTYPE_TRINKET"] = { slotMod = 0.5625 },
    ["INVTYPE_2HWEAPON"] = { slotMod = 2.0000 },
    ["INVTYPE_WEAPONMAINHAND"] = { slotMod = 1.0000 },
    ["INVTYPE_WEAPONOFFHAND"] = { slotMod = 1.0000 },
    ["INVTYPE_RANGED"] = { slotMod = 0.3164 },
    ["INVTYPE_THROWN"] = { slotMod = 0.3164 },
    ["INVTYPE_RANGEDRIGHT"] = { slotMod = 0.3164 },
    ["INVTYPE_SHIELD"] = { slotMod = 1.0000 },
    ["INVTYPE_WEAPON"] = { slotMod = 1.0000 },
    ["INVTYPE_HOLDABLE"] = { slotMod = 1.0000 },
    ["INVTYPE_HEAD"] = { slotMod = 1.0000 },
    ["INVTYPE_NECK"] = { slotMod = 0.5625 },
    ["INVTYPE_SHOULDER"] = { slotMod = 0.7500 },
    ["INVTYPE_CHEST"] = { slotMod = 1.0000 },
    ["INVTYPE_ROBE"] = { slotMod = 1.0000 },
    ["INVTYPE_WAIST"] = { slotMod = 0.7500 },
    ["INVTYPE_LEGS"] = { slotMod = 1.0000 },
    ["INVTYPE_FEET"] = { slotMod = 0.7500 },
    ["INVTYPE_WRIST"] = { slotMod = 0.5625 },
    ["INVTYPE_HAND"] = { slotMod = 0.7500 },
    ["INVTYPE_FINGER"] = { slotMod = 0.5625 },
    ["INVTYPE_CLOAK"] = { slotMod = 0.5625 },
    ["INVTYPE_BODY"] = { slotMod = 0.0000 },
}

PBM.GS_FORMULA = {
    A = {
        [4] = { A = 91.4500, B = 0.6500 },
        [3] = { A = 81.3750, B = 0.8125 },
        [2] = { A = 73.0000, B = 1.0000 },
    },
    B = {
        [4] = { A = 26.0000, B = 1.2000 },
        [3] = { A = 0.7500, B = 1.8000 },
        [2] = { A = 8.0000, B = 2.0000 },
        [1] = { A = 0.0000, B = 2.2500 },
    },
}

-- ── Needs ─────────────────────────────────────────────────────
PBM.NEEDS_SLOTS = {
    { key="head",    icon="Interface\\Icons\\INV_Helmet_03",              label="Head"      },
    { key="neck",    icon="Interface\\Icons\\INV_Jewelry_Necklace_07",    label="Neck"      },
    { key="shoulder",icon="Interface\\Icons\\INV_Shoulder_22",            label="Shoulders" },
    { key="back",    icon="Interface\\Icons\\INV_Misc_Cape_07",           label="Back"      },
    { key="chest",   icon="Interface\\Icons\\INV_Chest_Cloth_04",         label="Chest"     },
    { key="wrist",   icon="Interface\\Icons\\INV_Bracer_07",              label="Wrists"    },
    { key="hands",   icon="Interface\\Icons\\INV_Gauntlets_04",           label="Hands"     },
    { key="waist",   icon="Interface\\Icons\\INV_Belt_13",                label="Waist"     },
    { key="legs",    icon="Interface\\Icons\\INV_Pants_06",               label="Legs"      },
    { key="feet",    icon="Interface\\Icons\\INV_Boots_05",               label="Feet"      },
    { key="ring",    icon="Interface\\Icons\\INV_Jewelry_Ring_02",        label="Ring"      },
    { key="trinket", icon="Interface\\Icons\\INV_Misc_Rune_06",           label="Trinket"   },
    { key="mh",      icon="Interface\\Icons\\INV_Sword_27",               label="Main Hand" },
    { key="oh",      icon="Interface\\Icons\\INV_Shield_06",              label="Off Hand"  },
    { key="ranged",  icon="Interface\\Icons\\INV_Weapon_Bow_07",          label="Ranged"    },
}
PBM.NEEDS_ICON_SIZE = 18
PBM.MAX_NEEDS = 2

-- ── Profession Slots ────────────────────────────────────────────
PBM.PROF_SLOTS = {
    -- Row 1 (crafting professions)
    { key="alchemy",        icon="Interface\\Icons\\Trade_Alchemy",                label="Alchemy"        },
    { key="blacksmithing",  icon="Interface\\Icons\\Trade_BlackSmithing",          label="Blacksmithing"  },
    { key="jewelcrafting",  icon="Interface\\Icons\\INV_Misc_Gem_01",              label="Jewelcrafting"  },
    { key="enchanting",     icon="Interface\\Icons\\Trade_Engraving",              label="Enchanting"     },
    { key="engineering",    icon="Interface\\Icons\\Trade_Engineering",            label="Engineering"    },
    { key="leatherworking", icon="Interface\\Icons\\Trade_LeatherWorking",         label="Leatherworking" },
    { key="tailoring",      icon="Interface\\Icons\\Trade_Tailoring",              label="Tailoring"      },
    -- Row 2 (gathering / secondary professions)
    { key="inscription",    icon="Interface\\Icons\\INV_Inscription_Tradeskill01", label="Inscription"    },
    { key="herbalism",      icon="Interface\\Icons\\Trade_Herbalism",              label="Herbalism"      },
    { key="mining",         icon="Interface\\Icons\\Trade_Mining",                 label="Mining"         },
    { key="skinning",       icon="Interface\\Icons\\INV_Misc_Pelt_Wolf_01",        label="Skinning"       },
    { key="cooking",        icon="Interface\\Icons\\INV_Misc_Food_15",             label="Cooking"        },
    { key="fishing",        icon="Interface\\Icons\\Trade_Fishing",                label="Fishing"        },
}
PBM.MAX_PROFS = 2

-- ── Column layout ──────────────────────────────────────────────
PBM.COL_NAME_W  = 140
PBM.COL_GS_W    = 42
PBM.COL_GEAR_W  = 44
PBM.COL_NEEDS_W = 42
PBM.NAME_OFF    = 4
PBM.GS_OFF      = PBM.NAME_OFF + PBM.COL_NAME_W + 6
PBM.REALGS_OFF  = PBM.GS_OFF + PBM.COL_GS_W + 2
PBM.NEEDS_OFF   = PBM.REALGS_OFF + PBM.COL_GS_W + 2
PBM.GEAR_OFF    = PBM.NEEDS_OFF + PBM.COL_NEEDS_W + 2

PBM.COL_DRAG_W  = 18
PBM.COL_SPEC_W  = 24
PBM.DRAG_OFF    = 0
PBM.SPEC_OFF    = PBM.COL_DRAG_W + 2
PBM.NAME_OFF    = PBM.NAME_OFF + PBM.COL_DRAG_W + 2 + PBM.COL_SPEC_W + 2

-- ── Spec icons ─────────────────────────────────────────────────
PBM.SPEC_ICONS = {
    ["Blood"]       = "Interface\\Icons\\Spell_DeathKnight_BloodPresence",
    ["Frost DK"]    = "Interface\\Icons\\Spell_DeathKnight_FrostPresence",
    ["Unholy"]      = "Interface\\Icons\\Spell_DeathKnight_UnholyPresence",
    ["Balance"]     = "Interface\\Icons\\Spell_Nature_StarFall",
    ["Feral"]       = "Interface\\Icons\\Ability_Druid_CatForm",
    ["Restoration"] = "Interface\\Icons\\Spell_Nature_HealingTouch",
    ["Beast Mastery"] = "Interface\\Icons\\Ability_Hunter_BeastTaming",
    ["Marksmanship"]  = "Interface\\Icons\\Ability_Marksmanship",
    ["Survival"]      = "Interface\\Icons\\Ability_Hunter_SwiftStrike",
    ["Arcane"]      = "Interface\\Icons\\Spell_Holy_MagicalSentry",
    ["Fire"]        = "Interface\\Icons\\Spell_Fire_FireBolt02",
    ["Frost"]       = "Interface\\Icons\\Spell_Frost_FrostBolt02",
    ["Holy Pala"]   = "Interface\\Icons\\Spell_Holy_HolyBolt",
    ["Protection"]  = "Interface\\Icons\\Ability_Paladin_ShieldoftheTemplar",
    ["Retribution"] = "Interface\\Icons\\Spell_Holy_AuraofLight",
    ["Discipline"]  = "Interface\\Icons\\Spell_Holy_WordFortitude",
    ["Holy Priest"] = "Interface\\Icons\\Spell_Holy_GuardianSpirit",
    ["Shadow"]      = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
    ["Assassination"] = "Interface\\Icons\\Ability_Rogue_Eviscerate",
    ["Combat"]        = "Interface\\Icons\\Ability_BackStab",
    ["Subtlety"]      = "Interface\\Icons\\Ability_Stealth",
    ["Elemental"]   = "Interface\\Icons\\Spell_Nature_Lightning",
    ["Enhancement"] = "Interface\\Icons\\Spell_Nature_LightningShield",
    ["Restoration Shaman"] = "Interface\\Icons\\Spell_Nature_MagicImmunity",
    ["Affliction"]  = "Interface\\Icons\\Spell_Shadow_DeathCoil",
    ["Demonology"]  = "Interface\\Icons\\Spell_Shadow_Metamorphosis",
    ["Destruction"] = "Interface\\Icons\\Spell_Shadow_RainOfFire",
    ["Arms"]        = "Interface\\Icons\\Ability_Warrior_Sunder",
    ["Fury"]        = "Interface\\Icons\\Ability_Warrior_InnerRage",
    ["Protection Warrior"] = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
}

PBM.CLASS_SPECS = {
    ["Death Knight"] = {"Blood", "Frost DK", "Unholy"},
    ["Druid"]        = {"Balance", "Feral", "Restoration"},
    ["Hunter"]       = {"Beast Mastery", "Marksmanship", "Survival"},
    ["Mage"]         = {"Arcane", "Fire", "Frost"},
    ["Paladin"]      = {"Holy Pala", "Protection", "Retribution"},
    ["Priest"]       = {"Discipline", "Holy Priest", "Shadow"},
    ["Rogue"]        = {"Assassination", "Combat", "Subtlety"},
    ["Shaman"]       = {"Elemental", "Enhancement", "Restoration Shaman"},
    ["Warlock"]      = {"Affliction", "Demonology", "Destruction"},
    ["Warrior"]      = {"Arms", "Fury", "Protection Warrior"},
}

PBM.CLASS_COLORS = {
    ["Death Knight"]={r=0.77,g=0.12,b=0.23}, ["Druid"]={r=1.00,g=0.49,b=0.04},
    ["Hunter"]={r=0.67,g=0.83,b=0.45},       ["Mage"]={r=0.25,g=0.78,b=0.92},
    ["Paladin"]={r=0.96,g=0.55,b=0.73},      ["Priest"]={r=1.00,g=1.00,b=1.00},
    ["Rogue"]={r=1.00,g=0.96,b=0.41},        ["Shaman"]={r=0.00,g=0.44,b=0.87},
    ["Warlock"]={r=0.53,g=0.53,b=0.93},      ["Warrior"]={r=0.78,g=0.61,b=0.23},
}
PBM.CLASS_TABS = {"Death Knight","Druid","Hunter","Mage","Paladin","Priest","Rogue","Shaman","Warlock","Warrior","Raid","Overview"}
PBM.TAB_LABELS = {
    ["Death Knight"]="DK",["Druid"]="Druid",["Hunter"]="Hunter",["Mage"]="Mage",
    ["Paladin"]="Paladin",["Priest"]="Priest",["Rogue"]="Rogue",["Shaman"]="Shaman",
    ["Warlock"]="Warlock",["Warrior"]="Warrior",["Raid"]="Raid",["Overview"]="Overview",
}

-- Tier tables moved to IPTiersColor.lua (single source of truth).
-- PBM.TIER_COLORS, TIER_KEY_COLORS, TIER_LABELS, TIER_SHORT,
-- and TIER_TOOLTIP_RAIDS are all defined there.

PBM.ROLE_DEFS = {
    {key="TNK", label="Tank",   color={r=0.20,g=0.60,b=1.00}, icon="Interface\\Icons\\Ability_Warrior_DefensiveStance"},
    {key="HLR", label="Healer", color={r=0.20,g=1.00,b=0.40}, icon="Interface\\Icons\\Spell_ChargePositive"},
    {key="DPS", label="DPS",    color={r=1.00,g=0.40,b=0.20}, icon="Interface\\Icons\\Ability_DualWield"},
}
PBM.ROLE_BY_KEY = {}
for _, rd in ipairs(PBM.ROLE_DEFS) do PBM.ROLE_BY_KEY[rd.key] = rd end

PBM.CLASS_TOKEN_MAP = {
    DEATHKNIGHT="Death Knight", DRUID="Druid", HUNTER="Hunter",
    MAGE="Mage", PALADIN="Paladin", PRIEST="Priest", ROGUE="Rogue",
    SHAMAN="Shaman", WARLOCK="Warlock", WARRIOR="Warrior"
}

PBM.RAID_ABBR = {
    ["Molten Core"]="MC", ["Onyxia's Lair"]="Ony", ["Blackwing Lair"]="BWL",
    ["Zul'Gurub"]="ZG", ["Ruins of Ahn'Qiraj"]="AQ20", ["Ahn'Qiraj (AQ40)"]="AQ40",
    ["Ahn'Qiraj (AQ20)"]="AQ20", ["Naxxramas (Classic)"]="Naxx60",
    ["Karazhan"]="Kara", ["Gruul's Lair"]="Gruul", ["Magtheridon's Lair"]="Mag",
    ["Serpentshrine Cavern"]="SSC", ["Tempest Keep"]="TK",
    ["Mount Hyjal"]="Hyjal", ["Black Temple"]="BT", ["Zul'Aman"]="ZA",
    ["Sunwell Plateau"]="SW",
    ["Naxxramas 10"]="Naxx10", ["Naxxramas 25"]="Naxx25",
    ["Eye of Eternity 10"]="EoE10", ["Eye of Eternity 25"]="EoE25",
    ["Obsidian Sanctum 10"]="OS10", ["Obsidian Sanctum 25"]="OS25",
    ["Ulduar 10"]="Uld10", ["Ulduar 25"]="Uld25",
    ["Trial of the Crusader 10"]="ToC10", ["Trial of the Crusader 25"]="ToC25",
    ["Trial of the Grand Crusader 10"]="ToGC10", ["Trial of the Grand Crusader 25"]="ToGC25",
    ["Icecrown Citadel 10"]="ICC10", ["Icecrown Citadel 25"]="ICC25",
    ["Icecrown Citadel 10 Heroic"]="ICC10H", ["Icecrown Citadel 25 Heroic"]="ICC25H",
    ["Ruby Sanctum 10"]="RS10", ["Ruby Sanctum 25"]="RS25",
    ["N/A"]="N/A",
}

PBM.CLASS_ICONS = {
    ["Death Knight"] = "Interface\\Icons\\Spell_DeathKnight_ClassIcon",
    ["Druid"]        = "Interface\\Icons\\Ability_Druid_Maul",
    ["Hunter"]       = "Interface\\Icons\\INV_Weapon_Bow_07",
    ["Mage"]         = "Interface\\Icons\\INV_Staff_13",
    ["Paladin"]      = "Interface\\Icons\\Spell_Holy_HolyBolt",
    ["Priest"]       = "Interface\\Icons\\INV_Staff_30",
    ["Rogue"]        = "Interface\\Icons\\Ability_Stealth",
    ["Shaman"]       = "Interface\\Icons\\Spell_Nature_BloodLust",
    ["Warlock"]      = "Interface\\Icons\\Spell_Nature_FaerieFire",
    ["Warrior"]      = "Interface\\Icons\\Ability_Warrior_BattleShout",
}

PBM.QUALITY_COLORS = {
    [0]={r=0.62,g=0.62,b=0.62},
    [1]={r=1.00,g=1.00,b=1.00},
    [2]={r=0.12,g=1.00,b=0.00},
    [3]={r=0.00,g=0.44,b=0.87},
    [4]={r=0.64,g=0.21,b=0.93},
    [5]={r=1.00,g=0.50,b=0.00},
    [6]={r=0.90,g=0.80,b=0.50},
}

-- Sort
PBM.SORT_GOLD = "|cffd4af37"
PBM.SORT_OPTS = {
    {key="gs",   label="GS",   numeric=true},
    {key="ilvl", label="iLvL", numeric=true},
    {key="name", label="Name", numeric=false},
    {key="spec", label="Spec", numeric=false},
    {key="role", label="Role", numeric=false},
}

-- Overview layout
PBM.ALL_PER_COL = 20
PBM.ALL_NCOLS   = 3
PBM.ALL_COL_W   = 362

-- Export/Import prefixes
PBM.EXPORT_PREFIX    = "LICHBORNE_V3:"
PBM.EXPORT_PREFIX_V2 = "LICHBORNE_V2:"
PBM.EXPORT_PREFIX_V1 = "LICHBORNE_V1:"

-- Role order for invite sorting
PBM.ROLE_ORDER_TNK = {TNK=1, HLR=2, DPS=3}
PBM.ROLE_ORDER_HLR = {HLR=1, TNK=2, DPS=3}

-- Spec scan retry limit
PBM.MAX_SPEC_RETRIES = 6
