PBM = PBM or {}

-- ── Individual Progression tab panel ─────────────────────────────
-- Called from PBM_TopTabs.lua:BuildBottomTabs as:
--   PBM.BuildIPProgressionPanel(panel, ctx)
-- ctx fields used: GOLD_R/G/B, FONT

function PBM.BuildIPProgressionPanel(ipPanel, ctx)
    local IP_GOLD_R = ctx.GOLD_R
    local IP_GOLD_G = ctx.GOLD_G
    local IP_GOLD_B = ctx.GOLD_B
    local IP_FONT   = ctx.FONT

    -- Mage light blue (#69CCF0)
    local IP_R, IP_G, IP_B = 0.78, 0.61, 0.23   -- gold (matches LevelSync)

    local MARGIN = 15

    -- ── Separator helpers ────────────────────────────────────────
    local function IPGoldLine(yAbs)
        local t = ipPanel:CreateTexture(nil, "OVERLAY")
        t:SetHeight(1)
        t:SetPoint("TOPLEFT",  ipPanel, "TOPLEFT",   MARGIN,  yAbs)
        t:SetPoint("TOPRIGHT", ipPanel, "TOPRIGHT", -MARGIN, yAbs)
        t:SetTexture(IP_GOLD_R, IP_GOLD_G, IP_GOLD_B, 0.55)
    end

    local function IPBlueLine(yAbs)
        local t = ipPanel:CreateTexture(nil, "OVERLAY")
        t:SetHeight(1)
        t:SetPoint("TOPLEFT",  ipPanel, "TOPLEFT",   MARGIN,  yAbs)
        t:SetPoint("TOPRIGHT", ipPanel, "TOPRIGHT", -MARGIN, yAbs)
        t:SetTexture(IP_R, IP_G, IP_B, 0.35)
    end

    -- ── Info columns (4-column, evenly spaced) ───────────────────
    IPGoldLine(-35)

    local INFO_TOP  = -55
    local INFO_STEP = 13
    local INFO_W    = 260
    -- Center the 4-column block in the 1090px panel:
    -- block = 4*260 + 3*10 = 1070  →  margin = (1090-1070)/2 = 10px each side
    local INFO_COL1 = 67               -- x = 67
    local INFO_COL2 = 337              -- x = 337
    local INFO_COL3 = 622              -- x = 622
    local INFO_COL4 = 892              -- x = 892
    local INFO_CMD_W = 230             -- Commands column width (shorter → flush right)

    local function IPInfoTitle(x, y, text, w, drawLine)
        local fs = ipPanel:CreateFontString(nil, "OVERLAY")
        fs:SetFont(IP_FONT, 10, "OUTLINE")
        fs:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", x, y)
        fs:SetWidth(w or INFO_W); fs:SetJustifyH("LEFT")
        fs:SetTextColor(IP_R, IP_G, IP_B)
        fs:SetText(text)
        -- Underline: exactly as wide as the rendered text, text sits on it
        if drawLine ~= false then
            local line = ipPanel:CreateTexture(nil, "OVERLAY")
            line:SetHeight(1)
            line:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, 1)
            line:SetWidth(fs:GetStringWidth())
            line:SetTexture(IP_R, IP_G, IP_B, 0.75)
        end
    end

    local function IPInfoLine(x, y, text, w, size)
        local fs = ipPanel:CreateFontString(nil, "OVERLAY")
        fs:SetFont(IP_FONT, size or 9, "OUTLINE")
        fs:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", x, y)
        fs:SetWidth(w or INFO_W); fs:SetJustifyH("LEFT")
        fs:SetTextColor(0.82, 0.82, 0.82)
        fs:SetText(text)
    end

    -- Column 1: What is Individual Progression?
    IPInfoTitle(INFO_COL1, INFO_TOP, "What is Individual Progression?", nil, false)
    IPInfoLine(INFO_COL1, INFO_TOP - INFO_STEP,
        "Each character advances through")
    IPInfoLine(INFO_COL1, INFO_TOP - INFO_STEP * 2,
        "WoW's raid tiers chronologically.")
    IPInfoLine(INFO_COL1, INFO_TOP - INFO_STEP * 3,
        "Content is |cff69CCF0gated|r \226\128\148 clear each")
    IPInfoLine(INFO_COL1, INFO_TOP - INFO_STEP * 4,
        "tier before the next one opens.")
    IPInfoLine(INFO_COL1, INFO_TOP - INFO_STEP * 5,
        "|cffFF8C00Each tier unlocks new raids,|r")
    IPInfoLine(INFO_COL1, INFO_TOP - INFO_STEP * 6,
        "|cffFF8C00and/or expansions.|r")

    -- Column 2: How to Advance Your Tier
    IPInfoTitle(INFO_COL2, INFO_TOP, "How to Advance Your Tier", nil, false)
    IPInfoLine(INFO_COL2, INFO_TOP - INFO_STEP,
        "|cffd4af371.|r Defeat the |cff69CCF0final boss|r or the")
    IPInfoLine(INFO_COL2, INFO_TOP - INFO_STEP * 2,
        "   |cff69CCF0final quest|r listed in the table.")
    IPInfoLine(INFO_COL2, INFO_TOP - INFO_STEP * 3,
        "|cffd4af372.|r Tier advances automatically on")
    IPInfoLine(INFO_COL2, INFO_TOP - INFO_STEP * 4,
        "   final boss / quest completion.")
    IPInfoLine(INFO_COL2, INFO_TOP - INFO_STEP * 5,
        "|cffFF8C00Altbots follow their own progression tier.|r", nil, 8)
    IPInfoLine(INFO_COL2, INFO_TOP - INFO_STEP * 6,
        "|cffFF8C00Rndbots follow the group leader's tier.|r", nil, 8)

    -- Column 3: Commands
    IPInfoTitle(INFO_COL3, INFO_TOP, "Commands", INFO_W, false)
    IPInfoLine(INFO_COL3, INFO_TOP - INFO_STEP,
        "Check Tier:  |cffd4af37.ip get <target>/<name>|r", INFO_W)
    IPInfoLine(INFO_COL3, INFO_TOP - INFO_STEP * 2,
        "Check PvP:  |cffd4af37.ip pvp <target>/<name>|r", INFO_W)
    IPInfoLine(INFO_COL3, INFO_TOP - INFO_STEP * 3,
        "Sync Bots:   |cffd4af37.ip setbot (Tier)|r", INFO_W)
    IPInfoLine(INFO_COL3, INFO_TOP - INFO_STEP * 4,
        "Sync Bots:   |cffd4af37.ip setrep (Reputation)|r", INFO_W)
    IPInfoLine(INFO_COL3, INFO_TOP - INFO_STEP * 5,
        "|cffff4444GM (Required):|r  |cffd4af37.ip set (Change tier)|r", INFO_W)
    IPInfoLine(INFO_COL3, INFO_TOP - INFO_STEP * 6,
        "|cffff4444GM (Required):|r  |cffd4af37.ip tele (Teleport)|r", INFO_W)

    -- Column 4: Expansion Level Caps (no header, vertically centered)
    -- Each block: name line, indented Tier line, indented Level Cap line (11px steps)
    -- 3 blocks × 22px + 2 gaps × 8px = 82px total; centered in ~127px between gold lines
    local EXP_DOT_X  = INFO_COL4
    local EXP_NAME_X = INFO_COL4 + 12
    local EXP_SUB_X  = INFO_COL4 + 22   -- indent for Tier/Level Cap lines
    local EXP_LINE   = 11               -- px between lines within a block
    local EXP_GAP    = 30               -- px between block starts (22px content + 8px gap)

    local function ExpBadge(y, bgR, bgG, bgB, colorCode, label, tierRange, capLvl)
        local tierCol = string.format("|cff%02x%02x%02x",
            IP_GOLD_R * 255, IP_GOLD_G * 255, IP_GOLD_B * 255)
        -- Colored dot
        local dot = ipPanel:CreateTexture(nil, "ARTWORK")
        dot:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", EXP_DOT_X, y + 1)
        dot:SetSize(8, 8)
        dot:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        dot:SetVertexColor(bgR, bgG, bgB, 1)
        -- Expansion name
        local nameFS = ipPanel:CreateFontString(nil, "OVERLAY")
        nameFS:SetFont(IP_FONT, 9, "OUTLINE")
        nameFS:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", EXP_NAME_X, y)
        nameFS:SetWidth(200); nameFS:SetJustifyH("LEFT")
        nameFS:SetText(colorCode .. label .. "|r")
        -- Tier line (indented)
        local tierFS = ipPanel:CreateFontString(nil, "OVERLAY")
        tierFS:SetFont(IP_FONT, 8, "OUTLINE")
        tierFS:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", EXP_SUB_X, y - EXP_LINE)
        tierFS:SetWidth(190); tierFS:SetJustifyH("LEFT")
        tierFS:SetTextColor(0.82, 0.82, 0.82)
        tierFS:SetText("Tiers: " .. tierCol .. tierRange .. "|r")
        -- Level Cap line (indented)
        local capFS = ipPanel:CreateFontString(nil, "OVERLAY")
        capFS:SetFont(IP_FONT, 8, "OUTLINE")
        capFS:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", EXP_SUB_X, y - EXP_LINE * 2)
        capFS:SetWidth(190); capFS:SetJustifyH("LEFT")
        capFS:SetTextColor(0.82, 0.82, 0.82)
        capFS:SetText("Level Cap: |cffd4af37" .. capLvl .. "|r")
    end

    -- Center 3 blocks (82px) in the 127px space between gold lines
    local EXP_Y = INFO_TOP  -- align with Commands header row
    ExpBadge(EXP_Y,
        0.55, 0.08, 0.08, "|cffFF7070", "Classic World of Warcraft", "T0 \226\128\147 T7",  "60")
    ExpBadge(EXP_Y - EXP_GAP,
        0.05, 0.45, 0.10, "|cff66CC44", "The Burning Crusade",       "T8 \226\128\147 T12", "70")
    ExpBadge(EXP_Y - EXP_GAP * 2,
        0.05, 0.18, 0.50, "|cff69CCF0", "Wrath of the Lich King",    "T13 \226\128\147 T17","80")

    -- ── Tier table ───────────────────────────────────────────────
    local TABLE_TOP = -162
    IPGoldLine(TABLE_TOP)

    -- Column x-positions
    local COL_TIER_X   = MARGIN           -- width 50
    local COL_TIER_W   = 50
    local COL_RAID_X   = MARGIN + 56      -- width 294
    local COL_RAID_W   = 294
    local COL_LEVEL_X  = MARGIN + 56 + 300 -- width 40
    local COL_LEVEL_W  = 40
    local COL_FINAL_X  = MARGIN + 56 + 300 + 46  -- width 270
    local COL_FINAL_W  = 270
    local COL_UNLOCK_X = MARGIN + 56 + 300 + 46 + 276  -- width ~360
    local COL_UNLOCK_W = 362

    local tblHdrY = TABLE_TOP - 8

    local function TblHdr(x, y, text, w, jh)
        local fs = ipPanel:CreateFontString(nil, "OVERLAY")
        fs:SetFont(IP_FONT, 10, "OUTLINE")
        fs:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", x, y)
        fs:SetWidth(w); fs:SetJustifyH(jh or "LEFT")
        fs:SetTextColor(IP_GOLD_R, IP_GOLD_G, IP_GOLD_B)
        fs:SetText(text)
    end

    TblHdr(COL_TIER_X,   tblHdrY, "Tier",              COL_TIER_W,  "CENTER")
    TblHdr(COL_RAID_X,   tblHdrY, "Raid / Event",       COL_RAID_W)
    TblHdr(COL_LEVEL_X,  tblHdrY, "LvL",                COL_LEVEL_W, "CENTER")
    TblHdr(COL_FINAL_X,  tblHdrY, "Final Boss / Quest", COL_FINAL_W)
    TblHdr(COL_UNLOCK_X, tblHdrY, "Unlocks",            COL_UNLOCK_W)

    -- ── Tier data ────────────────────────────────────────────────
    -- { tierNum, raidName, levelCap, finalBoss, unlocks, tooltipText }
    -- In tooltipText: \n = line break. Boss/quest names wrapped in |cffFFD900...|r
    local TIER_DATA = {
        { 0,  "Starting Tier",                         60, "Ragnaros & Onyxia",
              "Default starting tier (no unlock required)",
              "All players start at this tier by default. Level is capped to 60.\n \nTier 0 and Tier 1 are available simultaneously, as was the case for the original Vanilla release.\n \nFinal bosses: |cffFFD900Ragnaros|r and |cffFFD900Onyxia|r." },
        { 1,  "Molten Core / Onyxia's Lair",          60, "Ragnaros & Onyxia",
              "Default starting tier (no unlock required)",
              "All players start at this tier by default. Level is capped to 60.\n \nTier 0 and Tier 1 are available simultaneously, as was the case for the original Vanilla release.\n \nFinal bosses: |cffFFD900Ragnaros|r and |cffFFD900Onyxia|r." },
        { 2,  "Blackwing Lair",                       60, "Nefarian",
              "BWL access (Onyxia Scale Cloak required)",
              "Blackwing Lair is now available. Players can enter without having defeated |cffFFD900Onyxia|r, but will not survive Shadowflame without the Onyxia Scale Cloak.\n \nThis tier has a natural RPG-style progression requirement.\n \nFinal boss: |cffFFD900Nefarian|r.\n \n|cffFF8C00Altbots and Rndbots do not require the Onyxia Scale Cloak. The effect is applied automatically.|r" },
        { 3,  "Ahn'Qiraj War Effort",                  60, "Bang a Gong!",
              "AQ war effort unlocked; Zul'Gurub (optional) opens",
              "This phase includes the Scarab Lord quest chain and the AQ war effort. Every player must complete each resource turn-in quest at least once.\n \nZul'Gurub becomes available during this tier.\n \nFinal quest: |cffFFD900Bang a Gong!|r\n \n|cffFF8C00Zul'Gurub is optional and can be configured to open at an earlier tier.|r" },
        { 4,  "Ahn'Qiraj War",                         60, "Chaos and Destruction",
              "AQ20 and AQ40 become available",
              "The AQ conflict is active and both AQ20 and AQ40 are accessible. Quest NPCs for AQ equipment are not available until after the war effort ends.\n \nFinal quest: |cffFFD900Chaos and Destruction|r.\n \n|cffFF8C00The Scarab Gate does not stay open during the war. AQ War enemies will block the gate when it is closed. Click the gong to re-open it. Once the war is fully completed, the gate stays open permanently.|r" },
        { 5,  "Ahn'Qiraj",                            60, "C'Thun",
              "Catch-up gearing quests in Silithus",
              "Completing AQ40 is required to advance to the next tier. Catch-up gearing quests and upgrades are available through AQ20.\n \nFinal boss: |cffFFD900C'Thun|r" },
        { 6,  "Naxxramas 40",                         60, "Kel'Thuzad",
              "Scourge Invasion; Light's Hope attunement",
              "The Light's Hope Chapel and its associated quests unlock, enabling the Naxxramas attunement. Once attuned, players can enter through the Naxxramas teleport in the Eastern Plaguelands.\n \nThe Scourge Invasion is also active during this tier.\n \nFinal boss: |cffFFD900Kel'Thuzad|r\n \n|cffFF8C00The crystal teleporter is located in the Eastern Plaguelands, inside the Ziggurat that hosts the Naxxramas meeting stone.|r" },
        { 7,  "Pre-TBC",                              60, "Into the Breach",
              "Dark Portal defense scenario",
              "A brief phase where enemies are emerging from the Dark Portal, requiring players to mount a defense.\n \nFinal quest: |cffFFD900Into the Breach|r" },
        { 8,  "Karazhan / Gruul's Lair / Magtheridon's Lair", 70, "Prince Malchezaar",
              "Dark Portal opens; level cap raised to 70",
              "Players may enter the Dark Portal and level to 70.\n \nFinal boss: |cffFFD900Prince Malchezaar|r\n \n|cffFF8C00Attunements will be necessary to enter TBC raids, which will require completing TBC heroics.|r" },
        { 9,  "Serpentshrine Cavern / Tempest Keep",  70, "Kael'thas Sunstrider",
              "Hyjal Summit / Black Temple - Attunements required",
              "Players complete attunements for the next tier of TBC raids, progressing through Serpentshrine Cavern and Tempest Keep.\n \nFinal boss: |cffFFD900Kael'thas Sunstrider|r" },
        { 10, "Hyjal Summit / Black Temple",          70, "Illidan Stormrage",
              "Completing this tier unlocks Sunwell Plateau",
              "Hyjal Summit and Black Temple are now accessible. Completing this tier unlocks Sunwell Plateau.\n \nFinal boss: |cffFFD900Illidan Stormrage|r\n \n|cffFF8C00You may enter Black Temple without fully completing Hyjal.|r" },
        { 11, "Zul'Aman (Optional)",                  70, "Zul'jin",
              "Optional \226\128\148 Ghostlands raid; can be configured earlier",
              "An optional raid located in the Ghostlands.\n \nFinal boss: |cffFFD900Zul'jin|r\n \n|cffFF8C00Can be configured to open earlier; by default unlocks after Black Temple.|r" },
        { 12, "Sunwell Plateau",                      70, "Kil'jaeden",
              "Isle of Quel'Danas; final TBC raid content",
              "The Isle of Quel'Danas unlocks, enabling its questlines and access to Sunwell Plateau.\n \nFinal boss: |cffFFD900Kil'jaeden|r\n \n|cffFF8C00Unlocks daily quests and areas as their reputation with the Shattered Sun Offensive increases.|r" },
        { 13, "Naxxramas / Eye of Eternity / Obsidian Sanctum", 80, "Kel'Thuzad  (80)",
              "Northrend opens; level cap raised to 80",
              "Players enter Northrend and may level to 80. Three raids are available: Naxxramas, Eye of Eternity, and Obsidian Sanctum.\n \nFinal boss: |cffFFD900Kel'Thuzad|r (level 80)" },
        { 14, "Ulduar",                               80, "Yogg-Saron",
              "Ulduar access with associated quest chain",
              "Players are now able to enter and complete Ulduar, along with its associated quest chain.\n \nFinal boss: |cffFFD900Yogg-Saron|r" },
        { 15, "Trial of the Crusader",                80, "Anub'arak",
              "Argent Tournament and associated content",
              "The Argent Tournament and all related content unlock alongside Trial of the Crusader.\n \nFinal boss: |cffFFD900Anub'arak|r" },
        { 16, "Icecrown Citadel",                     80, "The Lich King",
              "Final WotLK raid tier",
              "Players can finally enter Icecrown Citadel and challenge the Lich King.\n \nFinal boss: |cffFFD900The Lich King|r" },
        { 17, "Ruby Sanctum",                         80, "Halion",
              "Bonus endgame content",
              "Ruby Sanctum is the only content unlocked in this tier, considered bonus endgame content.\n \nFinal boss: |cffFFD900Halion|r" },
    }

    local ROW_H   = 22
    local curY    = TABLE_TOP - 16  -- first row top

    -- Expansion section divider: simple colored line with label sitting above it
    local function ExpDivider(y, r, g, b, label)
        -- Full-width colored line
        local line = ipPanel:CreateTexture(nil, "OVERLAY")
        line:SetHeight(2)
        line:SetPoint("TOPLEFT",  ipPanel, "TOPLEFT",   MARGIN, y)
        line:SetPoint("TOPRIGHT", ipPanel, "TOPRIGHT", -MARGIN, y)
        line:SetTexture(r, g, b, 0.75)
        -- Label: bottom of text sits on the line, left-aligned
        local fs = ipPanel:CreateFontString(nil, "OVERLAY")
        fs:SetFont(IP_FONT, 11, "OUTLINE")
        fs:SetPoint("BOTTOMRIGHT", ipPanel, "TOPRIGHT", -MARGIN - 4, y)
        fs:SetWidth(500); fs:SetJustifyH("RIGHT")
        fs:SetTextColor(r, g, b, 1.0)
        fs:SetText(label)
    end

    for _, td in ipairs(TIER_DATA) do
        local tierNum = td[1]

        -- Expansion section dividers
        if tierNum == 0 then
            curY = curY - 10    -- room for "CLASSIC" text above the line
            ExpDivider(curY, 0.85, 0.18, 0.18, "CLASSIC")
            curY = curY - 6    -- gap below line before first row
        elseif tierNum == 8 then
            curY = curY - 8    -- gap from T7
            TblHdr(COL_TIER_X,   curY, "Tier",               COL_TIER_W,  "CENTER")
            TblHdr(COL_RAID_X,   curY, "Raid / Event",       COL_RAID_W)
            TblHdr(COL_LEVEL_X,  curY, "LvL",                COL_LEVEL_W, "CENTER")
            TblHdr(COL_FINAL_X,  curY, "Final Boss / Quest", COL_FINAL_W)
            TblHdr(COL_UNLOCK_X, curY, "Unlocks",            COL_UNLOCK_W)
            curY = curY - 14   -- room for expansion label above line
            ExpDivider(curY, 0.12, 0.68, 0.20, "THE BURNING CRUSADE")
            curY = curY - 6
        elseif tierNum == 13 then
            curY = curY - 8    -- gap from T12
            TblHdr(COL_TIER_X,   curY, "Tier",               COL_TIER_W,  "CENTER")
            TblHdr(COL_RAID_X,   curY, "Raid / Event",       COL_RAID_W)
            TblHdr(COL_LEVEL_X,  curY, "LvL",                COL_LEVEL_W, "CENTER")
            TblHdr(COL_FINAL_X,  curY, "Final Boss / Quest", COL_FINAL_W)
            TblHdr(COL_UNLOCK_X, curY, "Unlocks",            COL_UNLOCK_W)
            curY = curY - 14   -- room for expansion label above line
            ExpDivider(curY, 0.20, 0.50, 0.95, "WRATH OF THE LICH KING")
            curY = curY - 6
        end

        local tc = PBM.TIER_COLORS[tierNum]    or PBM.TIER_COLORS[0]
        local kc = PBM.TIER_KEY_COLORS[tierNum] or {r=0.1, g=0.1, b=0.1}

        -- Tier badge
        local badgeBg = ipPanel:CreateTexture(nil, "ARTWORK")
        badgeBg:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", COL_TIER_X, curY - 1)
        badgeBg:SetSize(COL_TIER_W, ROW_H - 3)
        badgeBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        badgeBg:SetVertexColor(kc.r, kc.g, kc.b, 1)

        -- centre text vertically: ROW_H=22, ~11px font → 5px from top
        local textY = curY - 5

        local tierFS = ipPanel:CreateFontString(nil, "OVERLAY")
        tierFS:SetFont(IP_FONT, 9, "OUTLINE")
        tierFS:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", COL_TIER_X, textY)
        tierFS:SetWidth(COL_TIER_W)
        tierFS:SetJustifyH("CENTER")
        tierFS:SetTextColor(IP_GOLD_R, IP_GOLD_G, IP_GOLD_B)
        tierFS:SetText("T" .. tierNum)

        -- Raid / Event
        local raidFS = ipPanel:CreateFontString(nil, "OVERLAY")
        raidFS:SetFont(IP_FONT, 9, "OUTLINE")
        raidFS:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", COL_RAID_X, textY)
        raidFS:SetWidth(COL_RAID_W); raidFS:SetJustifyH("LEFT")
        raidFS:SetTextColor(IP_GOLD_R, IP_GOLD_G, IP_GOLD_B)
        raidFS:SetText(td[2])

        -- Level cap
        local lvlFS = ipPanel:CreateFontString(nil, "OVERLAY")
        lvlFS:SetFont(IP_FONT, 9, "OUTLINE")
        lvlFS:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", COL_LEVEL_X, textY)
        lvlFS:SetWidth(COL_LEVEL_W); lvlFS:SetJustifyH("CENTER")
        lvlFS:SetTextColor(0.83, 0.69, 0.22)
        lvlFS:SetText(tostring(td[3]))

        -- Full-row hover: gold highlight + tooltip from anywhere on the row
        local tipTitle = td[4]
        local tipBody  = td[6]
        local rowHover = CreateFrame("Frame", nil, ipPanel)
        rowHover:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", COL_FINAL_X, curY)
        rowHover:SetSize(COL_FINAL_W, ROW_H)
        rowHover:SetFrameLevel(ipPanel:GetFrameLevel() + 5)
        rowHover:EnableMouse(true)
        local rowHl = rowHover:CreateTexture(nil, "OVERLAY")
        rowHl:SetAllPoints(rowHover)
        rowHl:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        rowHl:SetVertexColor(0.78, 0.61, 0.23, 0.12)
        rowHl:Hide()
        rowHover:SetScript("OnEnter", function(self)
            rowHl:Show()
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(tipTitle, 1.0, 0.85, 0.0)
            if tipBody then
                for line in tipBody:gmatch("[^\n]+") do
                    GameTooltip:AddLine(line, 1, 1, 1, true)
                end
            end
            GameTooltip:Show()
        end)
        rowHover:SetScript("OnLeave", function()
            rowHl:Hide()
            GameTooltip:Hide()
        end)

        -- Alternating row stripe — OVERLAY so it renders after child frames,
        -- semi-transparent so the badge bg and panel bg show through beneath it.
        -- Text FontStrings are created after this so they sit on top.
        local rowIdx = tierNum + 1
        if rowIdx % 2 == 0 then
            local stripe = ipPanel:CreateTexture(nil, "OVERLAY")
            stripe:SetPoint("TOPLEFT",  ipPanel, "TOPLEFT",   COL_RAID_X - 2, curY)
            stripe:SetPoint("TOPRIGHT", ipPanel, "TOPRIGHT", -MARGIN - 1,    curY)
            stripe:SetHeight(ROW_H - 1)
            stripe:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
            stripe:SetVertexColor(0.12, 0.15, 0.26, 0.55)
        end

        local finalFS = ipPanel:CreateFontString(nil, "OVERLAY")
        finalFS:SetFont(IP_FONT, 9, "OUTLINE")
        finalFS:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", COL_FINAL_X, textY)
        finalFS:SetWidth(COL_FINAL_W); finalFS:SetJustifyH("LEFT")
        finalFS:SetTextColor(1.0, 0.85, 0.0)
        finalFS:SetText(td[4])

        -- Unlocks
        local unlockFS = ipPanel:CreateFontString(nil, "OVERLAY")
        unlockFS:SetFont(IP_FONT, 9, "OUTLINE")
        unlockFS:SetPoint("TOPLEFT", ipPanel, "TOPLEFT", COL_UNLOCK_X, textY)
        unlockFS:SetWidth(COL_UNLOCK_W); unlockFS:SetJustifyH("LEFT")
        unlockFS:SetTextColor(0.72, 0.72, 0.72)
        unlockFS:SetText(td[5])

        curY = curY - ROW_H
    end

    -- ── Bottom footer ────────────────────────────────────────────
    local footerFS = ipPanel:CreateFontString(nil, "OVERLAY")
    footerFS:SetFont(IP_FONT, 10, "OUTLINE")
    footerFS:SetPoint("BOTTOMLEFT",  ipPanel, "BOTTOMLEFT",  MARGIN, 6)
    footerFS:SetPoint("BOTTOMRIGHT", ipPanel, "BOTTOMRIGHT", -MARGIN, 6)
    footerFS:SetJustifyH("CENTER")
    footerFS:SetTextColor(0.72, 0.72, 0.72)
    footerFS:SetText("** This tab requires |cffd4af37mod-individual-progression|r." ..
                     "  Source: |cff69CCF0github.com/ZhengPeiRu21/mod-individual-progression|r")

    local footerFS2 = ipPanel:CreateFontString(nil, "OVERLAY")
    footerFS2:SetFont(IP_FONT, 9, "OUTLINE")
    footerFS2:SetPoint("BOTTOMLEFT",  ipPanel, "BOTTOMLEFT",  MARGIN, 20)
    footerFS2:SetPoint("BOTTOMRIGHT", ipPanel, "BOTTOMRIGHT", -MARGIN, 20)
    footerFS2:SetJustifyH("CENTER")
    footerFS2:SetText("|cffff4444** Information is subject to change as mod-individual-progression is updated.|r")
end
