-- ============================================================
--  PBM_Commands.lua  |  Bot command dispatch helpers
--
--  All sends go through the throttled SendChatMessage wrapper
--  installed by PBM_Throttle.lua.
-- ============================================================
PBM = PBM or {}

-- Send a command to the entire party or raid.
function PBM.SendToGroup(cmd)
    if GetNumRaidMembers() > 0 then
        SendChatMessage(cmd, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage(cmd, "PARTY")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFAA00PBM:|r Not in a group.")
    end
end

-- Whisper a command to a specific bot by name.
function PBM.SendToBot(cmd, name)
    if not name or name == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFAA00PBM:|r No bot name specified.")
        return
    end
    -- Track CO/NC type so unsolicited Strategies replies route correctly
    local _stype = cmd:match("^(co)%s") or cmd:match("^(nc)%s")
    if _stype then
        PBM.State.lastStratType[name] = _stype
    end
    SendChatMessage(cmd, "WHISPER", nil, name)
end

-- Send a server admin (.bot / .playerbots) command via SAY.
function PBM.SendAdmin(cmd)
    SendChatMessage(cmd, "SAY")
end

-- Convert a player name to a WoW unit token ("party1", "raid5", etc.).
-- Returns nil if the name is not found in the current group.
function PBM.NameToUnit(name)
    if not name then return nil end
    if UnitName("player") == name then return "player" end
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            if UnitName("raid" .. i) == name then return "raid" .. i end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            if UnitName("party" .. i) == name then return "party" .. i end
        end
    end
    return nil
end

-- Send a command prefixed with a role selector.
-- role: "tank" | "healer" | "dps" | "melee" | "ranged" | "groupN"
function PBM.SendToRole(role, cmd)
    PBM.SendToGroup("@" .. role .. " " .. cmd)
end
