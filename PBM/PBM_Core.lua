-- ============================================================
--  PBM_Core.lua  |  Init, events, slash commands, frame factory
-- ============================================================
PBM       = PBM       or {}
PBM.State = PBM.State or {}

PBM.State.allFrames        = PBM.State.allFrames        or {}
PBM.State.strategyPending  = PBM.State.strategyPending  or {}  -- [botName] = {frame, step}
PBM.State.lastQueriedMenu  = PBM.State.lastQueriedMenu  or {}  -- [botName] = menuFrame (most-recently-opened)
PBM.State.lastStratType    = PBM.State.lastStratType    or {}  -- [botName] = "co"|"nc" (last command type sent)
PBM.State.joinPending      = PBM.State.joinPending      or {}  -- [botName] = {step=1..4} join-time query chain
PBM.State.pickingPending   = PBM.State.pickingPending   or {}  -- [botName] = true while waiting for "Picking X" reply

local function CoreTimerAfter(delay, func)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, func)
    else
        local elapsed = 0
        local f = CreateFrame("Frame")
        f:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= delay then
                self:SetScript("OnUpdate", nil)
                func()
            end
        end)
    end
end

-- ── Event Handler ────────────────────────────────────────────

local _coreFrame = CreateFrame("Frame")
_coreFrame:RegisterEvent("ADDON_LOADED")
_coreFrame:RegisterEvent("PLAYER_LOGIN")
_coreFrame:RegisterEvent("PLAYER_LOGOUT")
_coreFrame:RegisterEvent("CHAT_MSG_WHISPER")
_coreFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "PlayerBotManager" then
        PBM.InitConfig()

    elseif event == "PLAYER_LOGIN" then
        for key, frame in pairs(PBM.State.allFrames) do
            PBM.RestoreFramePos(key, frame)
        end

    elseif event == "PLAYER_LOGOUT" then
        PBM.ClearQueue()
        for key, frame in pairs(PBM.State.allFrames) do
            PBM.SaveFramePos(key, frame)
        end

    elseif event == "CHAT_MSG_WHISPER" then
        -- arg1 = message text, arg2 = sender name
        local msg, sender = arg1, arg2

        -- Bot join greeting → start sequential query chain (co? → nc? → ss? → who)
        if msg == "Hello!" or msg == "你好" then
            PBM.State.joinPending[sender] = { step = 1 }
            PBM.SendToBot("co ?", sender)
            return
        end

        -- Join-flow state machine: co? → wait → nc? → done
        local join = PBM.State.joinPending[sender]
        if join then
            if join.step == 1 and msg:match("^Strategies:") then
                local rest = msg:sub(12)
                local coSet = {}
                for token in rest:gmatch("[^,]+") do
                    local trimmed = token:match("^%s*(.-)%s*$")
                    if trimmed ~= "" then coSet[trimmed:lower()] = true end
                end
                join.coSet = coSet
                PBM.SendToBot("nc ?", sender)
                join.step = 2
                return
            elseif join.step == 2 and msg:match("^Strategies:") then
                local rest = msg:sub(12)
                local ncSet = {}
                for token in rest:gmatch("[^,]+") do
                    local trimmed = token:match("^%s*(.-)%s*$")
                    if trimmed ~= "" then ncSet[trimmed:lower()] = true end
                end
                local coSet = join.coSet or {}
                PBM.State.joinPending[sender] = nil
                if PBM.ApplyBotNotes then PBM.ApplyBotNotes(sender, coSet, ncSet) end
                return
            end
        end

        -- Extended click-query chain: step 3 — stats response contains "Bag"
        local ep = PBM.State.strategyPending[sender]
        if ep and ep.extended and ep.step == 3 and msg:find("Bag") then
            local statsClean = msg
                :gsub("|c%x%x%x%x%x%x%x%x", "")
                :gsub("|H[^|]*|h", "")
                :gsub("|h", "")
                :gsub("|r", "")
            local menuFrame = PBM.State.lastQueriedMenu[sender]
            if menuFrame and menuFrame.onStatsResponse then
                menuFrame.onStatsResponse(sender, statsClean)
            end
            PBM.SendToBot("who", sender)
            ep.step = 4
            return
        end

        -- Extended query chain: step 4 — who response
        if ep and ep.extended and ep.step == 4 then
            local clean = msg
                :gsub("|c%x%x%x%x%x%x%x%x", "")
                :gsub("|H[^|]*|h", "")
                :gsub("|h", "")
                :gsub("|r", "")
            if clean:find("lvl%)") then
                local menuFrame = PBM.State.lastQueriedMenu[sender]
                if menuFrame and menuFrame.onWhoResponse then
                    menuFrame.onWhoResponse(sender, clean)
                end
                PBM.SendToBot("ss ?", sender)
                ep.step = 5
            end
            return
        end

        -- Talent spec picked: bot replies "Picking <spec>"
        -- Clear Strategy List and repopulate via full QueryBotStrategies chain
        if PBM.State.pickingPending[sender] and msg:find("^Picking ") then
            PBM.State.pickingPending[sender] = nil
            local menuFrame = PBM.State.lastQueriedMenu[sender]
            if menuFrame and menuFrame:IsShown() then
                if menuFrame.clearStratDisplay then menuFrame.clearStratDisplay() end
                if menuFrame.resetAllIcons  then menuFrame.resetAllIcons()  end
                if menuFrame.resetRoleIcons then menuFrame.resetRoleIcons() end
                if menuFrame.resetSpecIcons then menuFrame.resetSpecIcons() end
                menuFrame._specUserSet = nil
                -- extended=true: co? → nc? → stats → who (same path as OpenXMenu)
                PBM.QueryBotStrategies(sender, menuFrame, true)
            end
            return
        end

        -- Ignored spell list response: "Ignored spell list: [SpellA], [SpellB], ..."
        if msg:match("^Ignored spell list:") then
            local spells = {}
            for spell in msg:gmatch("%[([^%]]+)%]") do
                spells[#spells + 1] = spell
            end
            PBM.State.ignoredSpells = PBM.State.ignoredSpells or {}
            PBM.State.ignoredSpells[sender] = spells
            PBM.State.ignoredSpellChar   = sender
            PBM.State.ignoredSpellScroll = 0
            if PBM.RefreshIgnoredSpellTable then PBM.RefreshIgnoredSpellTable() end
            local ep2 = PBM.State.strategyPending[sender]
            if ep2 and ep2.step == 5 then
                PBM.State.strategyPending[sender] = nil
            end
            return
        end

        if not msg:match("^Strategies:") then return end

        -- Parse the strategy list
        local rest = msg:sub(12)
        local activeSet = {}
        for token in rest:gmatch("[^,]+") do
            local trimmed = token:match("^%s*(.-)%s*$")
            if trimmed ~= "" then activeSet[trimmed:lower()] = true end
        end

        -- Single unified path: always route through lastQueriedMenu + lastStratType.
        -- Both solicited (menu open) and unsolicited (toggle click) replies go here.
        local menuFrame = PBM.State.lastQueriedMenu[sender]
        if not menuFrame or not menuFrame:IsShown() then
            -- Fire notes update for any completed two-step query that finished without the menu.
            local ep = PBM.State.strategyPending[sender]
            if ep and ep.step == 2 and PBM.ApplyBotNotes then
                -- CO-first flow: NC reply arrived; apply notes.
                PBM.ApplyBotNotes(sender, ep.coSet or {}, activeSet)
            elseif ep and ep.step == 1 and ep.ncSet and PBM.ApplyBotNotes then
                -- NC-first flow: CO reply arrived; apply notes.
                PBM.ApplyBotNotes(sender, activeSet, ep.ncSet)
            end
            PBM.State.strategyPending[sender] = nil
            return
        end

        local stratType = PBM.State.lastStratType[sender] or "co"
        PBM.UpdateStrategyToggles(menuFrame, stratType, activeSet)

        -- Advance the solicited query chain if active (co reply → send nc?, etc.)
        local pending = PBM.State.strategyPending[sender]
        if pending then
            if pending.step == 1 then
                if pending.ncSet then
                    -- NC-first flow: CO just arrived; apply notes immediately.
                    if PBM.ApplyBotNotes then
                        PBM.ApplyBotNotes(sender, activeSet, pending.ncSet)
                    end
                    PBM.State.strategyPending[sender] = nil
                else
                    -- CO-first flow: CO received; save coSet, send NC query.
                    pending.coSet = activeSet
                    pending.step = 2
                    PBM.SendToBot("nc ?", sender)
                end
            elseif pending.step == 2 then
                if PBM.ApplyBotNotes then
                    PBM.ApplyBotNotes(sender, pending.coSet or {}, activeSet)
                end
                if pending.extended then
                    PBM.SendToBot("stats", sender)
                    pending.step = 3
                else
                    PBM.State.strategyPending[sender] = nil
                end
            end
        elseif stratType == "co" then
            -- Unsolicited CO toggle — follow up with nc? so NC strats stay current.
            PBM.State.strategyPending[sender] = { step = 2, extended = false, coSet = activeSet }
            PBM.SendToBot("nc ?", sender)
        elseif stratType == "nc" then
            -- Unsolicited NC toggle — follow up with co? to complete the picture.
            PBM.State.strategyPending[sender] = { step = 1, extended = false, ncSet = activeSet }
            PBM.SendToBot("co ?", sender)
        end
    end
end)

-- ── Strategy color-coding ────────────────────────────────────
PBM.STRATEGY_COLORS = {
    -- CO strategies
    ["tank"]          = "ff6655",   -- coral red
    ["tank assist"]   = "ff8833",   -- orange
    ["heal"]          = "44ff88",   -- mint green
    ["healer dps"]    = "88ff44",   -- lime
    ["offheal"]       = "55cc77",   -- medium green
    ["bear"]          = "cc9933",   -- amber
    ["cat"]           = "44ddcc",   -- teal
    ["cat aoe"]       = "22aabb",   -- dark teal
    ["melee"]         = "ddaa00",   -- dark gold
    ["caster"]        = "bb99ff",   -- lavender
    ["caster aoe"]    = "dd44ff",   -- violet
    ["caster debuff"] = "9922cc",   -- deep purple
    ["aoe"]           = "ff4488",   -- hot pink
    ["dps aoe"]       = "ff6699",   -- salmon pink
    ["dps assist"]    = "00ccff",   -- bright cyan
    ["avoid aoe"]     = "7799ff",   -- periwinkle
    ["behind"]        = "ee8844",   -- terra cotta
    ["boost"]         = "ff9900",   -- deep orange-gold
    ["formation"]     = "5599ee",   -- cornflower blue
    ["cast time"]     = "ffff88",   -- pale yellow
    ["frost"]         = "bbddff",   -- ice blue
    ["potions"]       = "00ffaa",   -- mint teal
    ["racials"]       = "cc88ff",   -- lilac
    ["cure"]          = "00eeff",   -- bright cyan-blue
    ["default"]       = "888888",   -- grey (system)
    ["duel"]          = "888888",   -- grey (system)
    ["chat"]          = "888888",   -- grey (system)
    ["emote"]         = "888888",   -- grey (system)
    ["quest"]         = "888888",   -- grey (system)
    -- NC strategies
    ["food"]          = "d4af37",   -- dark gold (loot tier)
    ["loot"]          = "d4af37",   -- dark gold (loot tier)
    ["gather"]        = "d4af37",   -- dark gold (loot tier)
    ["mount"]         = "888888",   -- grey (system)
    ["buff"]          = "ffdd00",   -- warm yellow
    ["bmana"]         = "ffcc00",   -- gold
    ["bdps"]          = "ffcc00",   -- gold
    ["guard"]         = "aaaa44",   -- olive
    ["pvp"]           = "ff2222",   -- bright red
    -- Added: missing common strategy
    ["save mana"]     = "888888",   -- grey (system)
    -- Added: Paladin
    ["bthreat"]       = "ff6655",   -- coral red (same as tank)
    ["barmor"]        = "cc9933",   -- amber
    ["bcast"]         = "3355ff",   -- deep blue (same as bmana)
    ["bhealth"]       = "44ff88",   -- mint green
    ["bstats"]        = "ffdd00",   -- warm yellow
    ["baoe"]          = "ff4488",   -- hot pink
    ["rshadow"]       = "9922cc",   -- deep purple
    ["rfrost"]        = "bbddff",   -- ice blue
    ["rfire"]         = "ff4400",   -- fire red
    ["offheal"]       = "55cc77",   -- medium green
    ["healer dps"]    = "88ff44",   -- lime
    ["bspeed"]        = "44aaff",   -- sky blue
    ["rnature"]       = "44aa44",   -- forest green
    -- Added: Hunter
    ["bm"]            = "ABD473",   -- hunter class color
    ["mm"]            = "88cc55",   -- slightly different green
    ["surv"]          = "669933",   -- darker green
    ["trap weave"]    = "cc8822",   -- dark amber
    ["pet"]           = "aaccaa",   -- muted green-gray
    -- Added: Rogue
    ["stealth"]       = "888844",   -- dark olive
    ["stealthed"]     = "aaaa00",   -- yellow-olive
    ["cc"]            = "ff88aa",   -- soft pink (shared CC color)
    -- Added: Shaman totems
    ["strength of earth"] = "cc8833",
    ["stoneskin"]         = "aaaaaa",
    ["tremor"]            = "cc6600",
    ["earthbind"]         = "887755",
    ["searing"]           = "ff6600",
    ["magma"]             = "ee3300",
    ["flametongue"]       = "ff9900",
    ["wrath"]             = "ffdd00",   -- Totem of Wrath
    ["wrath of shaman"]   = "ffdd00",   -- alias
    ["frost resistance"]  = "bbddff",
    ["healing stream"]    = "44ffaa",
    ["mana spring"]       = "3355ff",
    ["cleansing"]         = "00eeff",
    ["fire resistance"]   = "ff4400",
    ["wrath of air"]      = "ddddff",
    ["windfury"]          = "88aaff",
    ["nature resistance"] = "44aa44",
    ["grounding"]         = "aaaaff",
    -- Added: Warlock
    ["affli"]              = "8787ED",   -- warlock class color
    ["demo"]               = "6655cc",   -- darker purple
    ["destro"]             = "ff3300",   -- destruction red
    ["meta melee"]         = "aa44ff",   -- violet
    ["curse of agony"]     = "cc22cc",
    ["curse of elements"]  = "aa00ff",
    ["curse of doom"]      = "880088",
    ["curse of exhaustion"]= "996699",
    ["curse of tongues"]   = "bb44bb",
    ["curse of weakness"]  = "aa6688",
    ["imp"]                = "ff9944",
    ["voidwalker"]         = "5544aa",
    ["succubus"]           = "ee44aa",
    ["felhunter"]          = "6644aa",
    ["felguard"]           = "884499",
    ["ss self"]            = "aaaaaa",
    ["ss master"]          = "ffdd00",
    ["ss tank"]            = "ff6655",
    ["ss healer"]          = "44ff88",
    ["firestone"]          = "ff4400",
    ["spellstone"]         = "aa88ff",
    -- Added: Death Knight
    ["blood"]              = "C41F3B",   -- DK class color
    ["unholy"]             = "336633",   -- dark green
    ["frost aoe"]          = "aaddff",   -- light ice blue
    ["unholy aoe"]         = "226622",   -- darker green
    ["pull"]               = "ffaa44",   -- warm orange
    -- Added: Mage
    ["arcane"]             = "cc88ff",   -- purple-lavender
    ["fire"]               = "ff6600",   -- fire orange
    ["frostfire"]          = "8899ff",   -- blue-purple blend
    ["firestarter"]        = "ffbb44",   -- warm yellow-orange
    -- Added: Warrior
    ["arms"]               = "cc9944",   -- dark gold
    ["fury"]               = "dd5522",   -- dark orange-red
    -- Added: Druid (already have cat aoe and caster debuff above)
    -- Added: Shaman specs
    ["ele"]                = "44aaee",   -- sky teal (elemental)
    ["enh"]                = "cc8833",   -- amber (enhancement)
    ["resto"]              = "44cc88",   -- mint (restoration)
    -- Added: Priest
    ["holy heal"]          = "ffffff",   -- white (priest class color)
    ["shadow"]             = "9966cc",   -- medium purple
    ["holy dps"]           = "ffddaa",   -- pale gold
    ["shadow debuff"]      = "882299",   -- dark purple
    -- Added: Rogue/Paladin/shared
    ["dps"]                = "ddaa00",   -- dark gold (generic DPS)
    -- Added: missing common strategies
    ["passive"]            = "aabb55",   -- yellow-green
    ["tank face"]          = "ff9966",   -- peach-orange
    ["nc"]                 = "888888",   -- grey (system)
    ["follow"]             = "7799bb",   -- muted steel blue
    ["melee"]              = "ddaa77",   -- muted tan (Druid physical)
}

local function ColorizeStrategies(msg, cls)
    if not msg:match("^Strategies:") then return msg end
    local rest = msg:sub(12)

    -- Build a fast tier + lab lookup for this class if we have one
    local tierLookup = {}
    if cls and PBM and PBM.CLASS_STRAT_LIST and PBM.CLASS_STRAT_LIST[cls] then
        for _, entry in ipairs(PBM.CLASS_STRAT_LIST[cls]) do
            tierLookup[entry.n:lower()] = entry.t
        end
    end
    local clsHex = cls and PBM and PBM.CLASS_COLOR_HEX and PBM.CLASS_COLOR_HEX[cls]

    local parts = {}
    for token in rest:gmatch("[^,]+") do
        local name = token:match("^%s*(.-)%s*$")
        if name ~= "" then
            local lname = name:lower()
            local tier  = tierLookup[lname] or 5
            local color
            if tier == 1 then
                if lname == "pvp" then
                    color = "ee4433"                               -- red
                else
                    color = clsHex or "999999"                     -- class color
                end
            elseif tier == 2 then
                color = "ffff00"                                   -- yellow (healer/buffs)
            elseif tier == 3 then
                color = "ff8000"                                   -- orange (cross-role)
            elseif tier == 4 then
                color = "d4af37"                                   -- dark gold (loot/gather/food)
            else
                color = PBM.STRATEGY_COLORS[lname] or "888888"   -- T5 per-strategy or fallback
            end
            parts[#parts + 1] = "|cff" .. color .. name .. "|r"
        end
    end
    return "|cffd4af37Strategies:|r " .. table.concat(parts, "|cff666666, |r")
end

-- Map lowercased spec names from bot login messages to PBM spec names
local SPEC_NAME_MAP = {
    -- Druid
    ["balance"]="Balance", ["feral"]="Feral", ["feral combat"]="Feral", ["restoration"]="Restoration",
    -- Death Knight
    ["blood"]="Blood", ["frost"]="Frost DK", ["unholy"]="Unholy",
    -- Hunter
    ["beast mastery"]="Beast Mastery", ["marksmanship"]="Marksmanship", ["survival"]="Survival",
    -- Mage
    ["arcane"]="Arcane", ["fire"]="Fire",
    -- Paladin
    ["holy"]="Holy Pala", ["protection"]="Protection", ["retribution"]="Retribution",
    -- Priest
    ["discipline"]="Discipline", ["shadow"]="Shadow",
    -- Rogue
    ["assassination"]="Assassination", ["combat"]="Combat", ["subtlety"]="Subtlety",
    -- Shaman
    ["elemental"]="Elemental", ["enhancement"]="Enhancement",
    -- Warlock
    ["affliction"]="Affliction", ["demonology"]="Demonology", ["destruction"]="Destruction",
    -- Warrior
    ["arms"]="Arms", ["fury"]="Fury",
}

-- Try to extract and store the bot's spec from a login message
-- Format: "Race [G] specname (talents) classname (level lvl), ..."
local function TryParseSpec(msg, sender)
    -- Match: anything [letter] specname (digit
    local rawSpec = msg:match("%[%a%]%s+(.-)%s+%(")
    if not rawSpec then return end
    local lspec = rawSpec:lower()
    local mappedSpec = SPEC_NAME_MAP[lspec]
    if not mappedSpec then return end
    -- Update the row's spec in the tracker DB
    if LichborneTrackerDB and LichborneTrackerDB.rows then
        for _, row in ipairs(LichborneTrackerDB.rows) do
            if row.name == sender then
                row.spec = mappedSpec
                break
            end
        end
    end
    -- Update the spec icon on the visible row frame if present
    if PBM and PBM.State and PBM.State.rowFrames then
        for _, rf in ipairs(PBM.State.rowFrames) do
            if rf.dbIndex then
                local rd = LichborneTrackerDB.rows[rf.dbIndex]
                if rd and rd.name == sender and rf.specIcon then
                    local icon = PBM.SPEC_ICONS and PBM.SPEC_ICONS[mappedSpec]
                    if icon then
                        rf.specIcon:SetTexture(icon)
                        rf.specIcon:SetAlpha(1.0)
                    end
                    break
                end
            end
        end
    end
end

-- ── Bot Strategy Filter ─────────────────────────────────────
-- "Strategies:" whispers (co/nc replies) → tracker output only.
-- Everything else flows through to regular chat unchanged.

ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(_, _, msg, sender)
    if not msg:match("^Strategies:") then return end
    if LichborneOutput then
        local prefix = "[" .. sender .. "]:"
        if LichborneTrackerDB and LichborneTrackerDB.rows and PBM.CLASS_COLORS then
            for _, row in ipairs(LichborneTrackerDB.rows) do
                if row.name == sender then
                    local c = PBM.CLASS_COLORS[row.cls]
                    if c then
                        prefix = string.format("|cff%02x%02x%02x[%s]:|r",
                            c.r * 255, c.g * 255, c.b * 255, sender)
                    end
                    break
                end
            end
        end
        local senderCls
        if LichborneTrackerDB and LichborneTrackerDB.rows then
            for _, row in ipairs(LichborneTrackerDB.rows) do
                if row.name == sender then senderCls = row.cls; break end
            end
        end
        LichborneOutput(prefix .. " " .. ColorizeStrategies(msg, senderCls))
    end
    return true  -- suppress from regular chat
end)

-- ── Strategy Query ───────────────────────────────────────────

-- Whisper co ? then nc ? to a bot and register the menu frame to receive updates.
-- Pass extended=true to continue with stats → who → ss? after nc?.
-- Responses are handled in the CHAT_MSG_WHISPER event above.
function PBM.QueryBotStrategies(botName, menuFrame, extended)
    PBM.State.lastQueriedMenu[botName] = menuFrame
    PBM.State.strategyPending[botName] = {
        step     = 1,  -- 1=awaiting co, 2=awaiting nc, 3=stats, 4=who, 5=ss?
        extended = extended or false,
    }
    -- Send co? only; nc? is sent sequentially after the co reply arrives.
    -- This guarantees lastStratType is always correct when each reply lands.
    PBM.SendToBot("co ?", botName)
end

-- ── Slash Commands ───────────────────────────────────────────

SLASH_PBM1 = "/pmb"
SLASH_PBM2 = "/playerbotmanager"
SlashCmdList["PBM"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)")
    if cmd == "hide" then
        for _, f in pairs(PBM.State.allFrames) do f:Hide() end
    elseif cmd == "show" then
        for _, f in pairs(PBM.State.allFrames) do f:Show() end
    else
        -- Toggle all modules
        local anyShown = false
        for _, f in pairs(PBM.State.allFrames) do
            if f:IsShown() then anyShown = true; break end
        end
        for _, f in pairs(PBM.State.allFrames) do
            if anyShown then f:Hide() else f:Show() end
        end
    end
end

-- ── Module Frame Factory ─────────────────────────────────────
--
-- Creates a movable, closeable frame with a dark header bar.
--   name   : display name (used in title and frame global name)
--   key    : PBMConfig.frames key for position persistence
--   width  : total frame width in pixels
--   height : total frame height in pixels (including header)
--
-- Returns: frame (outer), content (inner area below header)

local HEADER_H  = 22
local HEADER_BG = "Interface\\BUTTONS\\WHITE8X8"
local FRAME_BG  = "Interface\\ChatFrame\\ChatFrameBackground"
local FRAME_EDGE= "Interface\\Tooltips\\UI-Tooltip-Border"

function PBM.CreateModuleFrame(name, key, width, height)
    local def  = PBM.DEFAULTS and PBM.DEFAULTS.frames and PBM.DEFAULTS.frames[key]
    local defX = (def and def.x) or 100
    local defY = (def and def.y) or -200

    local f = CreateFrame("Frame", "PBM" .. name .. "Frame", UIParent)
    f:SetSize(width, height)
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", defX, defY)
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetBackdrop({
        bgFile   = FRAME_BG,
        edgeFile = FRAME_EDGE,
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left=3, right=3, top=3, bottom=3 },
    })
    f:SetBackdropColor(0, 0, 0, 0.85)
    f:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)

    -- Header bar (drag handle)
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(HEADER_H)
    header:SetPoint("TOPLEFT",  f, "TOPLEFT",   3, -3)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT",  -3, -3)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop",  function()
        f:StopMovingOrSizing()
        PBM.SaveFramePos(key, f)
    end)

    local hbg = header:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints()
    hbg:SetTexture(HEADER_BG)
    hbg:SetVertexColor(0.12, 0.12, 0.12, 1.0)

    local titleStr = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleStr:SetPoint("LEFT", header, "LEFT", 5, 0)
    titleStr:SetText(name:upper())
    titleStr:SetTextColor(0.9, 0.9, 0.9, 1)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(14, 14)
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Content area (below header, inside border insets)
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT",     f, "TOPLEFT",     4, -(HEADER_H + 6))
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)

    -- Register for position save/restore and /pmb toggle
    PBM.State.allFrames[key] = f

    return f, content
end

-- ── Shared Widget Helpers ─────────────────────────────────────

-- Standard button using WoW's built-in panel style
function PBM.MakeButton(parent, label, x, y, w, h, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(w or 88, h or 22)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetText(label)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- Small dimmed section separator label
function PBM.MakeSectionLabel(parent, text, x, y)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    lbl:SetText(text)
    lbl:SetTextColor(0.55, 0.55, 0.55, 1)
    return lbl
end
