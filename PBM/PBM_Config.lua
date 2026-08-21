-- ============================================================
--  PBM_Config.lua  |  SavedVariables management
-- ============================================================
PBM = PBM or {}

PBM.DEFAULTS = {
    throttle = {
        rate  = 5,
        burst = 8,
    },
    frames = {},
}

function PBM.InitConfig()
    if not PBMConfig then PBMConfig = {} end

    if not PBMConfig.throttle then
        PBMConfig.throttle = {
            rate  = PBM.DEFAULTS.throttle.rate,
            burst = PBM.DEFAULTS.throttle.burst,
        }
    end

    if not PBMConfig.frames then
        PBMConfig.frames = {}
        for k, v in pairs(PBM.DEFAULTS.frames) do
            PBMConfig.frames[k] = { x = v.x, y = v.y, point = v.point }
        end
    else
        -- Fill in any new frame keys added since last save
        for k, v in pairs(PBM.DEFAULTS.frames) do
            if not PBMConfig.frames[k] then
                PBMConfig.frames[k] = { x = v.x, y = v.y, point = v.point }
            end
        end
    end

    if not PBMConfig.hiddenTabs then
        PBMConfig.hiddenTabs = {}
    end

    -- One-time migration: Strategy Whispers now defaults to Hidden (off).
    -- Runs once ever so existing users' saved toggle state isn't clobbered afterward.
    if not PBMConfig.stratWhisperDefaultApplied then
        PBMConfig.hideStrategyOutput = true
        PBMConfig.stratWhisperDefaultApplied = true
    end

end

function PBM.SaveFramePos(key, frame)
    if not PBMConfig or not PBMConfig.frames then return end
    -- After dragging, WoW changes the anchor type internally (e.g. BOTTOMLEFT).
    -- Save the point type alongside x/y so we restore with the correct anchor.
    local point, _, _, x, y = frame:GetPoint()
    PBMConfig.frames[key] = PBMConfig.frames[key] or {}
    PBMConfig.frames[key].point = point
    PBMConfig.frames[key].x     = x
    PBMConfig.frames[key].y     = y
end

function PBM.RestoreFramePos(key, frame)
    if not PBMConfig or not PBMConfig.frames then return end
    local cfg = PBMConfig.frames[key]
    if cfg and cfg.x and cfg.y then
        local point = cfg.point or "TOPLEFT"
        frame:ClearAllPoints()
        frame:SetPoint(point, UIParent, point, cfg.x, cfg.y)
    end
end
