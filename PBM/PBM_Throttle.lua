-- ============================================================
--  PBM_Throttle.lua  |  Token bucket rate limiter
--
--  Wraps the global SendChatMessage and drains a queue at a
--  configurable rate.  Default: 5 msg/s, burst capacity 8.
--  Pattern ported from MultiBotThrottle.lua.
-- ============================================================
PBM = PBM or {}

local _origSend = SendChatMessage
local _tokens   = 8    -- start full so first burst goes immediately
local _queue    = {}

local _throttleFrame = CreateFrame("Frame")
_throttleFrame:SetScript("OnUpdate", function(_, dt)
    local cfg   = PBMConfig and PBMConfig.throttle
    local rate  = (cfg and cfg.rate)  or 5
    local burst = (cfg and cfg.burst) or 8

    _tokens = math.min(burst, _tokens + rate * dt)

    while _tokens >= 1 and #_queue > 0 do
        local item = table.remove(_queue, 1)
        _origSend(item.msg, item.chatType, item.language, item.target)
        _tokens = _tokens - 1
    end
end)

-- Override global so all addon sends are throttled automatically
SendChatMessage = function(msg, chatType, language, target)
    _queue[#_queue + 1] = {
        msg      = msg,
        chatType = chatType,
        language = language,
        target   = target,
    }
end

-- Utility: how many messages are waiting
function PBM.GetQueueSize()
    return #_queue
end

-- Utility: discard pending messages (e.g. on logout)
function PBM.ClearQueue()
    _queue = {}
end
