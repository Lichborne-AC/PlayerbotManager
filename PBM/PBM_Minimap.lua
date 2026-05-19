-- ============================================================
--  LBT_Minimap.lua  |  Minimap button (standalone – zero library dependency)
-- ============================================================
-- Built entirely with standard WoW frame API.  Position is saved in
-- LichborneMinimapIconDB.minimapPos (degrees, 0-360) and restored at login.
PBM = PBM or {}
PBM.State = PBM.State or {}

local minimapBtn = CreateFrame("Button", "LichborneMinimapButton", Minimap)
minimapBtn:SetWidth(31); minimapBtn:SetHeight(31)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)
minimapBtn:RegisterForClicks("anyUp")
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

do
    local overlay = minimapBtn:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(53); overlay:SetHeight(53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    local bg = minimapBtn:CreateTexture(nil, "BACKGROUND")
    bg:SetWidth(20); bg:SetHeight(20)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("TOPLEFT", 7, -5)

    local icon = minimapBtn:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(20); icon:SetHeight(20)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_11")
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    icon:SetPoint("TOPLEFT", 7, -5)
    minimapBtn.icon = icon
end

local function LichborneUpdateMinimapPos()
    local angle = math.rad(
        (LichborneMinimapIconDB and LichborneMinimapIconDB.minimapPos) or 225
    )
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * 80, math.sin(angle) * 80)
end

minimapBtn:SetScript("OnClick", function(self, btn)
    if LichborneTrackerFrame and LichborneTrackerFrame:IsShown() then
        LichborneTrackerFrame:Hide()
    else
        LichborneTracker_Open()
    end
end)

minimapBtn:SetScript("OnDragStart", function(self)
    self.icon:SetTexCoord(0, 1, 0, 1)
    self:LockHighlight()
    self:SetScript("OnUpdate", function(self)
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        if LichborneMinimapIconDB then
            LichborneMinimapIconDB.minimapPos =
                math.deg(math.atan2(py - my, px - mx)) % 360
        end
        LichborneUpdateMinimapPos()
    end)
end)

minimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
    self.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cffC69B3ALichborne Gear Tracker|r")
    GameTooltip:AddLine("Click to open / close", 1, 1, 1)
    GameTooltip:AddLine("Drag to reposition", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)

minimapBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

minimapBtn:Hide()  -- hidden until PLAYER_LOGIN positions it

PBM.State.minimapBtn = minimapBtn
PBM.LichborneUpdateMinimapPos = LichborneUpdateMinimapPos
