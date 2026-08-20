-- ============================================================
--  PBM_Minimap.lua  |  Minimap button via LibDBIcon-1.0
-- ============================================================
PBM = PBM or {}
PBM.State = PBM.State or {}

local dbicon = LibStub("LibDBIcon-1.0", true)

local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("PlayerBotManager", {
    type = "launcher",
    text = PBM_L["Playerbot Manager"],
    icon = "Interface\\Icons\\INV_Misc_Book_11",
    OnClick = function(self, btn)
        if LichborneTrackerFrame and LichborneTrackerFrame:IsShown() then
            LichborneTrackerFrame:Hide()
        elseif LichborneTracker_Open then
            LichborneTracker_Open()
        end
    end,
    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end
        tooltip:AddLine("|cffC69B3A" .. PBM_L["Playerbot Manager"] .. "|r")
        tooltip:AddLine(PBM_L["Left-Click to Toggle"], 1, 1, 1)
        tooltip:AddLine(PBM_L["Drag to Reposition"], 0.7, 0.7, 0.7)
    end,
})

local _minimapFrame = CreateFrame("Frame")
_minimapFrame:RegisterEvent("PLAYER_LOGIN")
_minimapFrame:SetScript("OnEvent", function()
    LichborneMinimapIconDB = LichborneMinimapIconDB or {}
    if LichborneMinimapIconDB.hide == nil then
        LichborneMinimapIconDB.hide = false
    end
    if dbicon then
        dbicon:Register("PlayerBotManager", miniButton, LichborneMinimapIconDB)
    end
end)