-- ============================================================
--  LBT_UI.lua  |  Shared UI utilities used by multiple modules
-- ============================================================
PBM = PBM or {}
PBM.State = PBM.State or {}

PBM.State.LOCKABLE_BUTTONS = {
    "LichborneAddTargetBtn",
    "LichborneAddGroupBtn",
    "LichborneUpdateGSBtn",
    "LichborneUpdateTargetSpecBtn",
    "LichborneUpdateGroupGSBtn",
    "LichborneUpdateGroupSpecBtn",
    "LichborneDisbandBtn",
    "LichborneLoginBtn",
    "LichborneLogoutBtn",
    "LichborneMaintBtn",
    "LichborneOrphanedBotsBtn",
    "LichborneTargetStrategiesBtn",
    "LichborneGroupStrategiesBtn",
}

PBM.State.activeInviteFrame = nil

-- Debug helper — LichborneDebugMode is a global toggled by the DBG button
-- LichborneOutput is a global defined in LBT_Core.lua (resolved at call time)
function PBM.DBG(msg)
    if LichborneDebugMode then LichborneOutput("|cffaaaaaa[DBG]|r "..msg) end
end

function PBM.SetButtonsLocked(locked)
    for _, name in ipairs(PBM.State.LOCKABLE_BUTTONS) do
        local btn = _G[name]
        if btn then
            if locked then btn:Disable(); btn:SetAlpha(0.35)
            else btn:Enable(); btn:SetAlpha(1.0) end
        end
    end
end

-- During an invite, also lock the Stop (scan) button since no scan is running
function PBM.SetInviteActive(active)
    PBM.SetButtonsLocked(active)
    local stopBtn = _G["LichborneStopInspectBtn"]
    if stopBtn then
        if active then stopBtn:Disable(); stopBtn:SetAlpha(0.35)
        else stopBtn:Enable(); stopBtn:SetAlpha(1.0) end
    end
end

-- Hooks OnEnter/OnLeave on a child frame to show/hide the parent row highlight
function PBM.HookRowHighlight(child, row, hovTex)
    local orig_enter = child:GetScript("OnEnter")
    local orig_leave = child:GetScript("OnLeave")
    child:SetScript("OnEnter", function()
        hovTex:SetTexture(0.78, 0.61, 0.23, 0.12)
        if orig_enter then orig_enter() end
    end)
    child:SetScript("OnLeave", function()
        -- Only hide if mouse isn't still on the row
        local f = GetMouseFocus()
        if f ~= row then
            hovTex:SetTexture(0, 0, 0, 0)
        end
        if orig_leave then orig_leave() end
    end)
end
