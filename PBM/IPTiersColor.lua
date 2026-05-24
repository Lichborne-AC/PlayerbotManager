-- ============================================================
--  IPTiersColor.lua  |  Single source of truth for IP Tier data
--  Edit ONLY this file to change tier names, colors, or raids.
-- ============================================================
PBM = PBM or {}

-- ── Tier display colors ───────────────────────────────────────
PBM.TIER_COLORS = {
    [0]  = {r=0.20, g=0.60, b=0.80},  -- T0  : No tier (silver-blue)
    [1]  = {r=0.70, g=0.36, b=0.00},  -- T1  : Molten Core (orange-brown)
    [2]  = {r=0.62, g=0.15, b=0.75},  -- T2  : Blackwing Lair (purple)
    [3]  = {r=0.80, g=0.12, b=0.12},  -- T3  : Pre-AQ (dark red)
    [4]  = {r=0.18, g=0.49, b=0.20},  -- T4  : AQ War Effort (green)
    [5]  = {r=0.08, g=0.40, b=0.75},  -- T5  : Ahn'Qiraj (blue)
    [6]  = {r=0.85, g=0.55, b=0.20},  -- T6  : Naxxramas 40 (amber)
    [7]  = {r=0.65, g=0.22, b=0.78},  -- T7  : Pre-TBC (violet)
    [8]  = {r=0.00, g=0.51, b=0.56},  -- T8  : Kara/Gruul/Mag (teal)
    [9]  = {r=0.52, g=0.42, b=0.00},  -- T9  : SSC/TK (gold-olive)
    [10] = {r=0.68, g=0.08, b=0.34},  -- T10 : Hyjal/BT (dark pink)
    [11] = {r=0.33, g=0.43, b=0.48},  -- T11 : (Optional) (slate)
    [12] = {r=0.90, g=0.29, b=0.00},  -- T12 : Sunwell (orange-red)
    [13] = {r=0.00, g=0.41, b=0.36},  -- T13 : Naxx/EoE/OS (dark teal)
    [14] = {r=0.28, g=0.38, b=0.85},  -- T14 : Ulduar (blue)
    [15] = {r=0.34, g=0.55, b=0.18},  -- T15 : ToC (lime)
    [16] = {r=0.55, g=0.18, b=0.82},  -- T16 : ICC (violet)
    [17] = {r=0.00, g=0.38, b=0.39},  -- T17 : Ruby Sanctum (dark cyan)
    [18] = {r=0.53, g=0.06, b=0.31},  -- T18 : Tiers Complete (dark magenta)
}

-- ── Tier key/badge background colors (tooltip key panel) ─────
PBM.TIER_KEY_COLORS = {
    -- Classic (T0-T7)
    [0]={r=0.315,g=0.07,b=0.07}, [1]={r=0.315,g=0.07,b=0.07},
    [2]={r=0.315,g=0.07,b=0.07}, [3]={r=0.315,g=0.07,b=0.07},
    [4]={r=0.315,g=0.07,b=0.07}, [5]={r=0.315,g=0.07,b=0.07},
    [6]={r=0.315,g=0.07,b=0.07}, [7]={r=0.315,g=0.07,b=0.07},
    -- TBC (T8-T12)
    [8]={r=0.03,g=0.18,b=0.06},  [9]={r=0.03,g=0.18,b=0.06},
    [10]={r=0.03,g=0.18,b=0.06}, [11]={r=0.03,g=0.18,b=0.06},
    [12]={r=0.03,g=0.18,b=0.06},
    -- WotLK (T13-T18)
    [13]={r=0.035,g=0.14,b=0.245}, [14]={r=0.035,g=0.14,b=0.245},
    [15]={r=0.035,g=0.14,b=0.245}, [16]={r=0.035,g=0.14,b=0.245},
    [17]={r=0.035,g=0.14,b=0.245}, [18]={r=0.035,g=0.14,b=0.245},
}

-- ── Full tier names (dropdowns, tooltips) ─────────────────────
PBM.TIER_LABELS = {
    [0]  = "T0 — Molten Core / Onyxia",
    [1]  = "T1 — Molten Core / Onyxia",
    [2]  = "T2 — Blackwing Lair",
    [3]  = "T3 — Ahn'Qiraj War Effort",
    [4]  = "T4 — AQ War",
    [5]  = "T5 — Ahn'Qiraj",
    [6]  = "T6 — Naxxramas 40",
    [7]  = "T7 — Pre-TBC",
    [8]  = "T8 — Karazhan / Gruul's Lair / Magtheridon's Lair",
    [9]  = "T9 — Serpentshrine Cavern / Tempest Keep",
    [10] = "T10 — Hyjal Summit / Black Temple",
    [11] = "T11 — Zul'Aman (Optional)",
    [12] = "T12 — Sunwell Plateau",
    [13] = "T13 — Naxx / Eye of Eternity / Obsidian Sanctum",
    [14] = "T14 — Ulduar",
    [15] = "T15 — Trial of the Crusader",
    [16] = "T16 — Icecrown Citadel",
    [17] = "T17 — Ruby Sanctum",
    [18] = "T18 — Tiers Complete",
}

-- ── Short tier names (LevelSync grid, numLbl column) ─────────
-- T0 stays "None" because the server uses 0 to mean no tier achieved.
PBM.TIER_SHORT = {
    [0]  = "None",
    [1]  = "T1 - Molten Core",
    [2]  = "T2 - Blackwing Lair",
    [3]  = "T3 - Ahn'Qiraj War Effort",
    [4]  = "T4 - AQ War",
    [5]  = "T5 - Ahn'Qiraj",
    [6]  = "T6 - Naxxramas 40",
    [7]  = "T7 - Pre-TBC",
    [8]  = "T8 - Karazhan, Gruul's, Mag's",
    [9]  = "T9 - Serpentshrine / TK",
    [10] = "T10 - Hyjal / Black Temple",
    [11] = "T11 - Zul'Aman (Optional)",
    [12] = "T12 - Sunwell Plateau",
    [13] = "T13 - Naxx/EoE/OS",
    [14] = "T14 - Ulduar",
    [15] = "T15 - Trial of the Crusader",
    [16] = "T16 - Icecrown Citadel",
    [17] = "T17 - Ruby Sanctum",
    [18] = "T18 - Complete",
}

-- ── Raid lists per tier (tooltip key hover) ───────────────────
PBM.TIER_TOOLTIP_RAIDS = {
    [0]  = {"Molten Core", "Onyxia's Lair"},
    [1]  = {"Molten Core", "Onyxia's Lair"},
    [2]  = {"Blackwing Lair"},
    [3]  = {"Ahn'Qiraj War Effort"},
    [4]  = {"AQ War"},
    [5]  = {"Ahn'Qiraj", "Ruins of Ahn'Qiraj"},
    [6]  = {"Naxxramas 40"},
    [7]  = {"Pre-TBC"},
    [8]  = {"Karazhan", "Gruul's Lair", "Magtheridon's Lair"},
    [9]  = {"Serpentshrine Cavern", "Tempest Keep"},
    [10] = {"Mount Hyjal", "Black Temple"},
    [11] = {"Zul'Aman (Optional)"},
    [12] = {"Sunwell Plateau"},
    [13] = {"Naxxramas", "Eye of Eternity", "Obsidian Sanctum"},
    [14] = {"Ulduar"},
    [15] = {"Trial of the Crusader"},
    [16] = {"Icecrown Citadel"},
    [17] = {"Ruby Sanctum"},
    [18] = {"Tiers Complete"},
}
