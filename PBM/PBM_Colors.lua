-- ============================================================
--  PBM_Colors.lua  |  UI color constants
-- ============================================================
PBM = PBM or {}

PBM.Colors = {
    class = {
        WARRIOR     = { r=0.78, g=0.61, b=0.43 },
        PALADIN     = { r=0.96, g=0.55, b=0.73 },
        HUNTER      = { r=0.67, g=0.83, b=0.45 },
        ROGUE       = { r=1.00, g=0.96, b=0.41 },
        PRIEST      = { r=1.00, g=1.00, b=1.00 },
        DEATHKNIGHT = { r=0.77, g=0.12, b=0.23 },
        SHAMAN      = { r=0.00, g=0.44, b=0.87 },
        MAGE        = { r=0.41, g=0.80, b=0.94 },
        WARLOCK     = { r=0.58, g=0.51, b=0.79 },
        DRUID       = { r=1.00, g=0.49, b=0.04 },
    },
    ui = {
        background = { r=0,    g=0,    b=0,    a=0.85 },
        header     = { r=0.12, g=0.12, b=0.12, a=1.0  },
        border     = { r=0.3,  g=0.3,  b=0.3,  a=1.0  },
        text       = { r=0.9,  g=0.9,  b=0.9,  a=1.0  },
        textDim    = { r=0.6,  g=0.6,  b=0.6,  a=1.0  },
    },
    -- Raid target marker colors (index matches WoW API: 1=Star ... 8=Skull)
    marker = {
        [1] = { r=1.0,  g=1.0,  b=1.0  },  -- Star     (white)
        [2] = { r=1.0,  g=0.5,  b=0.75 },  -- Circle   (pink)
        [3] = { r=1.0,  g=0.8,  b=0.0  },  -- Diamond  (yellow)
        [4] = { r=0.1,  g=0.8,  b=0.1  },  -- Triangle (green)
        [5] = { r=0.6,  g=0.0,  b=0.9  },  -- Moon     (purple)
        [6] = { r=0.1,  g=0.3,  b=1.0  },  -- Square   (blue)
        [7] = { r=1.0,  g=0.4,  b=0.0  },  -- Cross/X  (orange)
        [8] = { r=1.0,  g=0.0,  b=0.0  },  -- Skull    (red)
    },
    markerName = {
        [1] = "Star",   [2] = "Circle",   [3] = "Diamond", [4] = "Triangle",
        [5] = "Moon",   [6] = "Square",   [7] = "Cross",   [8] = "Skull",
    },
}
