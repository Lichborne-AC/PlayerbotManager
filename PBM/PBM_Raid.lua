PBM = PBM or {}
PBM.State = PBM.State or {}

PBM.State.raidRowFrames    = PBM.State.raidRowFrames    or {}
PBM.State.raidFrameBuilt   = PBM.State.raidFrameBuilt   or false
PBM.State.LichborneRaidCountLabels  = PBM.State.LichborneRaidCountLabels  or nil
PBM.State.LichborneRosterIlvlLabel  = PBM.State.LichborneRosterIlvlLabel  or nil
PBM.State.LichborneRosterGsLabel    = PBM.State.LichborneRosterGsLabel    or nil

-- ── RefreshRaidRows ───────────────────────────────────────────
function PBM.RefreshRaidRows()
    if not PBM.State.raidRowFrames or #PBM.State.raidRowFrames == 0 then return end

    -- Remove anyone from the current roster who no longer exists in class tabs
    local classTabNames = {}
    if LichborneTrackerDB.rows then
        for _, classRow in ipairs(LichborneTrackerDB.rows) do
            if classRow.name and classRow.name ~= "" then
                classTabNames[classRow.name:lower()] = true
            end
        end
    end
    local roster, _ = PBM.GetCurrentRoster()
    for i = 1, 40 do
        if roster[i] and roster[i].name and roster[i].name ~= "" then
            if not classTabNames[roster[i].name:lower()] then
                roster[i] = {name="", cls="", spec="", gs=0}
            end
        end
    end

    PBM.SortRaidRows()
    local rows, raidSize = PBM.GetCurrentRoster()
    for i = 1, PBM.MAX_RAID_SLOTS do
        local rf = PBM.State.raidRowFrames[i]
        if not rf then break end
        -- Hide rows beyond current raid size
        if i > raidSize then
            rf:Hide()
        else
            rf:Show()
        end
        local data = rows[i] or {name="", cls="", spec="", gs=0, role="", notes=""}

        -- Class icon
        local cIcon = PBM.CLASS_ICONS[data.cls]
        if rf.classIcon then
            if cIcon then rf.classIcon:SetTexture(cIcon); rf.classIcon:SetAlpha(1)
            else rf.classIcon:SetTexture(0,0,0,0) end
        end

        -- Sync spec from class tab rows (refresh keeps it current)
        if data.name and data.name ~= "" then
            for _, classRow in ipairs(LichborneTrackerDB.rows) do
                if classRow.name and classRow.name:lower() == data.name:lower() then
                    if classRow.spec and classRow.spec ~= "" then
                        data.spec = classRow.spec
                    end
                    data.realGs = classRow.realGs or 0
                    break
                end
            end
        end

        -- Spec icon
        local sIcon = data.spec and data.spec ~= "" and PBM.SPEC_ICONS[data.spec]
        if rf.specIcon then
            if sIcon then
                rf.specIcon:SetTexture(sIcon); rf.specIcon:SetAlpha(1)
            elseif data.name and data.name ~= "" then
                rf.specIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); rf.specIcon:SetAlpha(0.2)
            else
                rf.specIcon:SetTexture(0,0,0,0)
            end
        end

        -- Needs cell refresh
        if rf.needsCell then
            PBM.RefreshNeedsCell(rf.needsCell, data.name or "")
        end

        -- Role button
        if rf.roleBtn and rf.roleLbl then
            if not data.role then data.role = "" end
            local rd = PBM.ROLE_BY_KEY[data.role]
            local botNE = LichborneTrackerDB.botNotes and data.name and data.name ~= ""
                          and LichborneTrackerDB.botNotes[data.name:lower()]
            local hasBotRoles = botNE and botNE.roles and #botNE.roles > 0
            if hasBotRoles then
                -- Show computed role icons from botNotes, packed left, no gaps
                if rf.roleIcon then rf.roleIcon:SetTexture(0,0,0,0) end
                rf.roleLbl:SetText("")
                rf.roleBtn:SetBackdropBorderColor(0.20,0.30,0.50,0.3)
                local visRoles = {}
                for _, r in ipairs(botNE.roles) do
                    if PBM.NOTES_ROLE_ICONS and PBM.NOTES_ROLE_ICONS[r] then
                        visRoles[#visRoles+1] = r
                    end
                end
                local roleOrder = { T=1, H=2, D=3, A=4 }
                table.sort(visRoles, function(a, b)
                    return (roleOrder[a] or 9) < (roleOrder[b] or 9)
                end)
                for ni = 1, 2 do
                    if rf.noteRoleIcons and rf.noteRoleIcons[ni] then
                        if visRoles[ni] then
                            rf.noteRoleIcons[ni]:SetTexture(PBM.NOTES_ROLE_ICONS[visRoles[ni]])
                            rf.noteRoleIcons[ni]:SetAlpha(0.9)
                        else
                            rf.noteRoleIcons[ni]:SetTexture(0,0,0,0)
                        end
                    end
                end
            elseif rd then
                -- Manual role: pack to left slot via noteRoleIcons
                rf.roleLbl:SetText("")
                rf.roleBtn:SetBackdropBorderColor(rd.color.r, rd.color.g, rd.color.b, 0.9)
                if rf.roleIcon then rf.roleIcon:SetTexture(0,0,0,0) end
                if rf.noteRoleIcons then
                    rf.noteRoleIcons[1]:SetTexture(rd.icon); rf.noteRoleIcons[1]:SetAlpha(1.0)
                    if rf.noteRoleIcons[2] then rf.noteRoleIcons[2]:SetTexture(0,0,0,0) end
                end
            else
                rf.roleLbl:SetText("")
                rf.roleBtn:SetBackdropBorderColor(0.20,0.30,0.50,0.3)
                if rf.roleIcon then rf.roleIcon:SetTexture(0,0,0,0) end
                if rf.noteRoleIcons then for ni=1,2 do rf.noteRoleIcons[ni]:SetTexture(0,0,0,0) end end
            end
            local idx = i
            rf.roleBtn:SetScript("OnEnter", function()
                local roster2, _ = PBM.GetCurrentRoster()
                local d2 = roster2[idx]
                GameTooltip:SetOwner(rf.roleBtn, "ANCHOR_RIGHT")
                local botNE3 = LichborneTrackerDB.botNotes and d2 and d2.name and d2.name ~= ""
                               and LichborneTrackerDB.botNotes[d2.name:lower()]
                GameTooltip:AddLine("Role", 1, 1, 1)
                if botNE3 and botNE3.roles and #botNE3.roles > 0 then
                    local roleLabels = { T="Tank", H="Healer", D="DPS", A="AoE" }
                    local roleOrder = { T=1, H=2, D=3, A=4 }
                    local sortedRoles = {}
                    for _, r in ipairs(botNE3.roles) do sortedRoles[#sortedRoles+1] = r end
                    table.sort(sortedRoles, function(a, b)
                        return (roleOrder[a] or 9) < (roleOrder[b] or 9)
                    end)
                    for _, r in ipairs(sortedRoles) do
                        local icon = PBM.NOTES_ROLE_ICONS and PBM.NOTES_ROLE_ICONS[r] or ""
                        local label = roleLabels[r] or r
                        local cr,cg,cb = 0.8,0.8,0.8
                        if r=="T" then cr,cg,cb=0.20,0.60,1.00
                        elseif r=="H" then cr,cg,cb=0.20,1.00,0.40
                        elseif r=="D" then cr,cg,cb=1.00,0.40,0.20
                        elseif r=="A" then cr,cg,cb=0.58,0.51,0.79 end
                        GameTooltip:AddLine("|T"..icon..":14:14|t  "..label, cr, cg, cb)
                    end
                end
                GameTooltip:Show()
            end)
            rf.roleBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            rf.roleBtn:SetScript("OnClick", nil)
        end

        -- Notes
        if rf.notesBox then
            rf.notesBox:SetScript("OnTextChanged", nil)
            local botNE2 = LichborneTrackerDB.botNotes and data.name and data.name ~= ""
                           and LichborneTrackerDB.botNotes[data.name:lower()]
            if botNE2 and botNE2.notes and botNE2.notes ~= "" then
                rf.notesBox:SetText(botNE2.notes)
                rf.notesBox:SetCursorPosition(0)
            else
                rf.notesBox:SetText(data.notes or "")
                rf.notesBox:SetCursorPosition(0)
                local idx = i
                rf.notesBox:SetScript("OnTextChanged", function()
                    local r2, _ = PBM.GetCurrentRoster()
                    if r2[idx] then r2[idx].notes = rf.notesBox:GetText() end
                end)
            end
        end

        -- Name
        if rf.nameBox then
            rf.nameBox:SetText(data.name or "")
            local c = PBM.CLASS_COLORS[data.cls]
            if c then rf.nameBox:SetTextColor(c.r, c.g, c.b)
            else rf.nameBox:SetTextColor(0.9, 0.95, 1.0) end
        end

        -- iLvl (read-only)
        if rf.gsBox then
            rf.gsBox:SetText(data.gs and data.gs > 0 and tostring(data.gs) or "")
        end

        -- GS (read-only)
        if rf.realGsBox then
            rf.realGsBox:SetText(data.realGs and data.realGs > 0 and tostring(data.realGs) or "")
        end




        -- Spec icon hover - reads live from rows[i] at hover time
        if rf.specBtn then
            local rowIdx = i
            rf.specBtn:SetScript("OnEnter", function()
                local roster4, _ = PBM.GetCurrentRoster()
                local d4 = roster4[rowIdx]
                local spec = d4 and d4.spec or ""
                local cls = d4 and d4.cls or ""
                local c = cls ~= "" and PBM.CLASS_COLORS[cls]
                GameTooltip:SetOwner(rf.specBtn, "ANCHOR_RIGHT")
                if spec ~= "" then GameTooltip:AddLine(spec, 1, 1, 1) end
                if cls ~= "" then
                    if c then GameTooltip:AddLine(cls, c.r, c.g, c.b)
                    else GameTooltip:AddLine(cls, 0.8, 0.8, 0.9) end
                end
                if spec == "" and cls == "" then GameTooltip:AddLine("Empty", 0.4, 0.4, 0.4) end
                GameTooltip:Show()
            end)
            rf.specBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end

        -- Delete button
        if rf.delBtn then
            local idx = i
            rf.delBtn:SetScript("OnClick", function()
local r5, _ = PBM.GetCurrentRoster(); r5[idx] = {name="", cls="", spec="", gs=0, realGs=0, role="", notes=""}
                PBM.RefreshRaidRows()
            end)
        end
    end

    -- Update raid class count bar
    if PBM.State.LichborneRaidCountLabels then
        local raidCounts = {}
        for _, cls in ipairs(PBM.CLASS_TABS) do if cls ~= "Raid" then raidCounts[cls] = 0 end end
        local rosterC, sizeC = PBM.GetCurrentRoster()
        for i2 = 1, sizeC do
            local r2 = rosterC[i2]
            if r2 and r2.name and r2.name ~= "" and raidCounts[r2.cls] then
                raidCounts[r2.cls] = raidCounts[r2.cls] + 1
            end
        end
        for cls, lbl in pairs(PBM.State.LichborneRaidCountLabels) do
            local c = PBM.CLASS_COLORS[cls]
            if c then
                local hex = string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255))
                local n = raidCounts[cls] or 0
                lbl:SetText(hex..(PBM.TAB_LABELS[cls])..": |cffd4af37"..n.."|r")
                -- Color background if has members
                local sw = lbl:GetParent()
                if sw and sw.bg then
                    if n > 0 then sw.bg:SetTexture(c.r*0.25, c.g*0.25, c.b*0.30, 1)
                    else sw.bg:SetTexture(0.08, 0.10, 0.18, 1) end
                end
            end
        end
    end
end

-- ── GetRosterAvgIlvl ──────────────────────────────────────────
function PBM.GetRosterAvgIlvl()
    local total, namedRows = 0, 0
    for _, row in ipairs(LichborneTrackerDB.rows) do
        if row.name and row.name ~= "" then
            namedRows = namedRows + 1
            total = total + (row.gs or 0)  -- row.gs stores the iLvl column value
        end
    end
    if namedRows == 0 then return 0 end
    return math.floor(total / namedRows + 0.5)
end

-- ── GetRosterAvgGS ────────────────────────────────────────────
function PBM.GetRosterAvgGS()
    local total, namedRows = 0, 0
    for _, row in ipairs(LichborneTrackerDB.rows) do
        if row.name and row.name ~= "" then
            namedRows = namedRows + 1
            total = total + (row.realGs or 0)  -- row.realGs stores actual GS (1000s)
        end
    end
    if namedRows == 0 then return 0 end
    return math.floor(total / namedRows + 0.5)
end

-- ── UpdateInviteButtons ───────────────────────────────────────
function PBM.UpdateInviteButtons()
    -- Both invite buttons always show in their normal state
    if LichborneInviteRaidBtn then
        LichborneInviteRaidBtn:Show()
        LichborneInviteRaidBtn:SetBackdropColor(0.30, 0.15, 0.01, 1)
        if LichborneInviteRaidBtn.lbl then
            LichborneInviteRaidBtn.lbl:SetText("|cffd4af37Invite Raid|r")
        end
    end
    if _G["LichborneInviteGroupBtn"] then
        local grpBtn = _G["LichborneInviteGroupBtn"]
        grpBtn:Show()
        grpBtn:SetBackdropColor(0.035, 0.14, 0.245, 1)
        if grpBtn.lbl then grpBtn.lbl:SetText("|cffd4af37Invite Group|r") end
    end
    -- Stop Invite overlay: covers both invite buttons when an invite is active
    if _G["LichborneStopInviteBtn"] then
        if PBM.State.activeInviteFrame then
            _G["LichborneStopInviteBtn"]:Show()
        else
            _G["LichborneStopInviteBtn"]:Hide()
        end
    end
end

-- ── BuildRaidFrame ────────────────────────────────────────────
function PBM.BuildRaidFrame(parent, fl)
    if PBM.State.raidFrameBuilt then return end
    PBM.State.raidFrameBuilt = true

    -- Main container hidden behind header bar area
    LichborneRaidFrame = CreateFrame("Frame", "LichborneRaidFrame", parent)
    LichborneRaidFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -66)
    LichborneRaidFrame:SetSize(1070, 510)
    LichborneRaidFrame:SetFrameLevel(fl + 10)
    LichborneRaidFrame:Hide()
    -- Full frame background so no gaps show between columns
    local raidFrameBg = LichborneRaidFrame:CreateTexture(nil, "BACKGROUND")
    raidFrameBg:SetAllPoints(LichborneRaidFrame)
    raidFrameBg:SetTexture(0.05, 0.07, 0.13, 1)


    -- Tier bar across top with dropdown
    -- Raid definitions: tier -> list of {name, size}
    local RAID_DEFS = {
        [0]  = {{"N/A (5-Man)",5}},
        [1]  = {{"Molten Core",40}},
        [2]  = {{"Onyxia's Lair",40}},
        [3]  = {{"Blackwing Lair",40},{"Zul'Gurub",20}},
        [4]  = {{"Ruins of Ahn'Qiraj",20},{"Ahn'Qiraj (AQ40)",40}},
        [5]  = {{"World Event",5}},
        [6]  = {{"Naxxramas (Classic)",40}},
        [7]  = {{"World Event",5}},
        [8]  = {{"Karazhan",10},{"Gruul's Lair",25},{"Magtheridon's Lair",25}},
        [9]  = {{"Serpentshrine Cavern",25},{"Tempest Keep",25}},
        [10] = {{"Mount Hyjal",25},{"Black Temple",25}},
        [11] = {{"Zul'Aman",10}},
        [12] = {{"Sunwell Plateau",25}},
        [13] = {{"Naxxramas 10",10},{"Naxxramas 25",25},{"Eye of Eternity 10",10},{"Eye of Eternity 25",25},{"Obsidian Sanctum 10",10},{"Obsidian Sanctum 25",25}},
        [14] = {{"Ulduar 10",10},{"Ulduar 25",25}},
        [15] = {{"Trial of the Crusader 10",10},{"Trial of the Crusader 25",25},{"Trial of the Grand Crusader 10",10},{"Trial of the Grand Crusader 25",25}},
        [16] = {{"Icecrown Citadel 10",10},{"Icecrown Citadel 25",25},{"ICC 10 Heroic",10},{"ICC 25 Heroic",25}},
        [17] = {{"Ruby Sanctum 10",10},{"Ruby Sanctum 25",25}},
    }

    -- Init raid selection state
    if not LichborneTrackerDB.raidName then LichborneTrackerDB.raidName = "N/A (5-Man)" end
    if not LichborneTrackerDB.raidSize then LichborneTrackerDB.raidSize = 5 end

    local tierBar = CreateFrame("Frame", nil, LichborneRaidFrame)
    tierBar:SetPoint("TOPLEFT", LichborneRaidFrame, "TOPLEFT", -5, 0)
    tierBar:SetSize(1086, 24)
    tierBar:SetFrameLevel(fl + 11)
    local tierBarBg = tierBar:CreateTexture(nil, "BACKGROUND")
    tierBarBg:SetAllPoints(tierBar)

    local function UpdateTierBar()
        local t = LichborneTrackerDB.raidTier or 0
        local colorKey = t
        local c = PBM.TIER_COLORS[colorKey]
        if c then tierBarBg:SetTexture(c.r*0.6, c.g*0.6, c.b*0.6, 1) end
    end
    UpdateTierBar()

    -- Helper to make a dropdown button
    local function MakeDD(name, w, parent)
        local btn = CreateFrame("Button", name, parent or tierBar)
        btn:SetSize(w, 20)
        btn:SetFrameLevel(fl + 12)
        btn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",tile=true,tileSize=16,insets={left=0,right=0,top=0,bottom=0}})
        btn:SetBackdropColor(0.05,0.07,0.14,1)
        btn:SetBackdropBorderColor(0.78,0.61,0.23,0.8)
        local lbl = btn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        lbl:SetAllPoints(btn); lbl:SetJustifyH("CENTER")
        btn.lbl = lbl
        return btn
    end

    -- ── Tier label + dropdown ──────────────────────────────────
    local tierLbl = tierBar:CreateFontString(nil,"OVERLAY","GameFontNormal")
    tierLbl:SetPoint("LEFT",tierBar,"LEFT",100,0)
    tierLbl:SetText("|cffC69B3ATier:|r")

    local tierDD = MakeDD("LichborneRaidTierDrop", 200)
    tierDD:SetPoint("LEFT",tierLbl,"RIGHT",6,0)

    local raidDD = MakeDD("LichborneRaidRaidDrop", 220)
    local raidDDMenu  -- forward ref

    local function UpdateRaidDD(hex)
        local t = LichborneTrackerDB.raidTier or 1
        local defs = RAID_DEFS[t] or {}
        -- Find current raid in this tier, fallback to first
        local found = false
        for _, rd in ipairs(defs) do
            if rd[1] == LichborneTrackerDB.raidName then found = true; break end
        end
        if not found and #defs > 0 then
            LichborneTrackerDB.raidName = defs[1][1]
            LichborneTrackerDB.raidSize = defs[1][2]
        end
        local raidName = LichborneTrackerDB.raidName or "---"
        local raidSize = LichborneTrackerDB.raidSize or 40
        local h = hex or "|cffd4af37"
        raidDD.lbl:SetText(h..raidName.."|r  |cffaaaaaa("..raidSize..")|r  v")
    end

    local function UpdateTierDD()
        local t = LichborneTrackerDB.raidTier or 1
        local colorKey = t
        local c = PBM.TIER_COLORS[colorKey]
        local hex = c and string.format("|cff%02x%02x%02x",math.floor(c.r*255),math.floor(c.g*255),math.floor(c.b*255)) or "|cffffffff"
        local label = (PBM.TIER_LABELS[t] or ""):match("^T%d+ %— (.+)") or ""
        tierDD.lbl:SetText(hex.."T"..t.."  "..label.."  v|r")
        UpdateTierBar()
        UpdateRaidDD(hex)
    end
    UpdateTierDD()

    -- Raid label
    local raidLbl = tierBar:CreateFontString(nil,"OVERLAY","GameFontNormal")
    raidLbl:SetPoint("LEFT",tierDD,"RIGHT",14,0)
    raidLbl:SetText("|cffC69B3ARaid:|r")
    raidDD:SetPoint("LEFT",raidLbl,"RIGHT",6,0)

    -- Tier dropdown menu
    local tierDDMenu = CreateFrame("Frame","LichborneRaidTierMenu",UIParent)
    tierDDMenu:SetFrameStrata("TOOLTIP")
    tierDDMenu:SetSize(260, 18*22+8)
    tierDDMenu:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    tierDDMenu:SetBackdropColor(0.04,0.06,0.12,0.98)
    tierDDMenu:SetBackdropBorderColor(0.78,0.61,0.23,1)
    tierDDMenu:Hide()
    for t=0,17 do
        local mb = CreateFrame("Button",nil,tierDDMenu)
        mb:SetSize(256,20); mb:SetPoint("TOPLEFT",tierDDMenu,"TOPLEFT",2,-2-(t)*22)
        local mbbg=mb:CreateTexture(nil,"BACKGROUND"); mbbg:SetAllPoints(mb)
        local colorKey2 = t
        local c=PBM.TIER_COLORS[colorKey2]; if not c then c={r=0.1,g=0.1,b=0.1} end
        mbbg:SetTexture(c.r*0.35,c.g*0.35,c.b*0.35,1)
        mb:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        local mblbl=mb:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); mblbl:SetAllPoints(mb); mblbl:SetJustifyH("CENTER")
        local hex=string.format("|cff%02x%02x%02x",math.floor(c.r*255),math.floor(c.g*255),math.floor(c.b*255))
        mblbl:SetText(hex..(PBM.TIER_LABELS[t] or ("T"..t)).."|r")
        mb:SetScript("OnClick",function()
            LichborneTrackerDB.raidTier = t
            UpdateTierDD()
            tierDDMenu:Hide()
            if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
            PBM.UpdateInviteButtons()
        end)
    end
    tierDD:SetScript("OnClick",function()
        if raidDDMenu then raidDDMenu:Hide() end
        if tierDDMenu:IsShown() then tierDDMenu:Hide()
        else tierDDMenu:ClearAllPoints(); tierDDMenu:SetPoint("TOPLEFT",tierDD,"BOTTOMLEFT",0,-2); tierDDMenu:Show() end
    end)

    local groupDDMenu

    -- Raid dropdown menu (built dynamically per tier)
    raidDDMenu = CreateFrame("Frame","LichborneRaidRaidMenu",UIParent)
    raidDDMenu:SetFrameStrata("TOOLTIP")
    raidDDMenu:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    raidDDMenu:SetBackdropColor(0.04,0.06,0.12,0.98)
    raidDDMenu:SetBackdropBorderColor(0.78,0.61,0.23,1)
    raidDDMenu:Hide()
    raidDDMenu.btns = {}

    local function PopulateRaidMenu()
        -- Hide old buttons
        for _,b in ipairs(raidDDMenu.btns) do b:Hide() end
        raidDDMenu.btns = {}
        local t = LichborneTrackerDB.raidTier or 1
        local defs = RAID_DEFS[t] or {}
        for idx, rd in ipairs(defs) do
            local mb = CreateFrame("Button",nil,raidDDMenu)
            mb:SetSize(256,20); mb:SetPoint("TOPLEFT",raidDDMenu,"TOPLEFT",2,-2-(idx-1)*22)
            local mbbg=mb:CreateTexture(nil,"BACKGROUND"); mbbg:SetAllPoints(mb)
            local ck=PBM.TIER_COLORS[(t==0) and 18 or t] or PBM.TIER_COLORS[1]; local c=ck; mbbg:SetTexture(c.r*0.25,c.g*0.25,c.b*0.25,1)
            mb:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
            local mblbl=mb:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); mblbl:SetAllPoints(mb); mblbl:SetJustifyH("CENTER")
            mblbl:SetText("|cffffffff"..rd[1].."|r  |cffaaaaaa("..rd[2].." players)|r")
            local capturedName = rd[1]
            local capturedSize = rd[2]
            mb:SetScript("OnClick",function()
                LichborneTrackerDB.raidName = capturedName
                LichborneTrackerDB.raidSize = capturedSize
                LichborneTrackerDB.raidGroup = "A"  -- always start on group A for a new raid
                -- Update group dropdown label to show A
                local gdd = _G["LichborneRaidGroupDrop"]
                if gdd and gdd.lbl then gdd.lbl:SetText("|cffd4af37 A|r  v") end
                UpdateRaidDD()
                raidDDMenu:Hide()
                if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
            end)
            raidDDMenu.btns[idx] = mb
        end
        raidDDMenu:SetSize(260, #defs*22+8)
    end

    raidDD:SetScript("OnClick",function()
        tierDDMenu:Hide()
        if groupDDMenu then groupDDMenu:Hide() end
        PopulateRaidMenu()
        if raidDDMenu:IsShown() then raidDDMenu:Hide()
        else raidDDMenu:ClearAllPoints(); raidDDMenu:SetPoint("TOPLEFT",raidDD,"BOTTOMLEFT",0,-2); raidDDMenu:Show() end
    end)
    UpdateRaidDD()

    -- ── Group dropdown (A / B / C) ─────────────────────────
    local groupLbl = tierBar:CreateFontString(nil,"OVERLAY","GameFontNormal")
    groupLbl:SetPoint("LEFT",raidDD,"RIGHT",14,0)
    groupLbl:SetText("|cffC69B3AGroup:|r")

    local groupDD = MakeDD("LichborneRaidGroupDrop", 70)
    groupDD:SetPoint("LEFT",groupLbl,"RIGHT",6,0)
    groupDD:SetFrameLevel(fl + 12)

    local function UpdateGroupDD()
        local g = LichborneTrackerDB.raidGroup or "A"
        groupDD.lbl:SetText("|cffd4af37"..g.."|r  v")
    end
    UpdateGroupDD()

    groupDDMenu = CreateFrame("Frame","LichborneRaidGroupMenu",UIParent)
    groupDDMenu:SetFrameStrata("TOOLTIP")
    groupDDMenu:SetSize(74, 3*22+8)
    groupDDMenu:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    groupDDMenu:SetBackdropColor(0.04,0.06,0.12,0.98)
    groupDDMenu:SetBackdropBorderColor(0.78,0.61,0.23,1)
    groupDDMenu:Hide()
    for gi, gname in ipairs({"A","B","C"}) do
        local mb = CreateFrame("Button",nil,groupDDMenu)
        mb:SetSize(70,20); mb:SetPoint("TOPLEFT",groupDDMenu,"TOPLEFT",2,-2-(gi-1)*22)
        mb:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        mb:SetBackdropColor(0.06,0.09,0.20,1)
        mb:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        local mblbl=mb:CreateFontString(nil,"OVERLAY","GameFontNormal"); mblbl:SetAllPoints(mb); mblbl:SetJustifyH("CENTER")
        mblbl:SetText("|cffffffff"..gname.."|r")
        local capturedG = gname
        mb:SetScript("OnClick",function()
            LichborneTrackerDB.raidGroup = capturedG
            UpdateGroupDD()
            groupDDMenu:Hide()
            if PBM.State.raidRowFrames and #PBM.State.raidRowFrames > 0 then PBM.RefreshRaidRows() end
        end)
    end
    groupDD:SetScript("OnClick",function()
        tierDDMenu:Hide(); raidDDMenu:Hide()
        if groupDDMenu:IsShown() then groupDDMenu:Hide()
        else groupDDMenu:ClearAllPoints(); groupDDMenu:SetPoint("TOPLEFT",groupDD,"BOTTOMLEFT",0,-2); groupDDMenu:Show() end
    end)

    -- ── Copy / Paste roster buttons ────────────────────────────
    local rosterClipboard = nil       -- session-only clipboard
    local clipboardLabel  = nil       -- human-readable source label e.g. "T1 Molten Core (A)"

    local copyBtn = CreateFrame("Button", nil, tierBar)
    copyBtn:SetSize(55, 20); copyBtn:SetFrameLevel(fl + 12)
    copyBtn:SetPoint("RIGHT", tierBar, "RIGHT", -70, 0)
    copyBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    copyBtn:SetBackdropColor(0.10,0.08,0.02,1); copyBtn:SetBackdropBorderColor(0.78,0.61,0.23,0.9)
    copyBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local copyLbl = copyBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    copyLbl:SetAllPoints(copyBtn); copyLbl:SetJustifyH("CENTER"); copyLbl:SetJustifyV("MIDDLE")
    copyLbl:SetText("|cffd4af37Copy|r")
    copyBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(copyBtn,"ANCHOR_BOTTOM")
        GameTooltip:AddLine("Copy Roster",1,1,1)
        GameTooltip:AddLine("Copies the current roster to clipboard.",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    copyBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local pasteBtn = CreateFrame("Button", nil, tierBar)
    pasteBtn:SetSize(55, 20); pasteBtn:SetFrameLevel(fl + 12)
    pasteBtn:SetPoint("RIGHT", copyBtn, "LEFT", -4, 0)
    pasteBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    pasteBtn:SetBackdropColor(0.10,0.08,0.02,1); pasteBtn:SetBackdropBorderColor(0.78,0.61,0.23,0.9)
    pasteBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local pasteLbl = pasteBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    pasteLbl:SetAllPoints(pasteBtn); pasteLbl:SetJustifyH("CENTER"); pasteLbl:SetJustifyV("MIDDLE")
    pasteLbl:SetText("|cffd4af37Paste|r")
    pasteBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(pasteBtn,"ANCHOR_BOTTOM")
        GameTooltip:AddLine("Paste Roster",1,1,1)
        if clipboardLabel then
            GameTooltip:AddLine("Clipboard: "..clipboardLabel,0.8,0.8,0.8)
        end
        GameTooltip:Show()
    end)
    pasteBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pasteBtn:Hide()

    -- Paste confirmation popup
    local pasteConfirm = CreateFrame("Frame", nil, UIParent)
    pasteConfirm:SetSize(380, 80)
    pasteConfirm:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    pasteConfirm:SetFrameStrata("FULLSCREEN_DIALOG")
    pasteConfirm:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=3,right=3,top=3,bottom=3}})
    pasteConfirm:SetBackdropColor(0.04,0.06,0.13,0.98)
    pasteConfirm:SetBackdropBorderColor(0.78,0.61,0.23,1)
    pasteConfirm:Hide()

    local pasteConfirmText = pasteConfirm:CreateFontString(nil,"OVERLAY","GameFontNormal")
    pasteConfirmText:SetPoint("TOP",pasteConfirm,"TOP",0,-14)
    pasteConfirmText:SetWidth(360)
    pasteConfirmText:SetJustifyH("CENTER")

    local pasteYes = CreateFrame("Button",nil,pasteConfirm)
    pasteYes:SetSize(120,22); pasteYes:SetPoint("BOTTOMLEFT",pasteConfirm,"BOTTOMLEFT",16,10)
    pasteYes:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    pasteYes:SetBackdropColor(0.10,0.08,0.02,1); pasteYes:SetBackdropBorderColor(0.78,0.61,0.23,0.9)
    pasteYes:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local pasteYesLbl = pasteYes:CreateFontString(nil,"OVERLAY","GameFontNormal")
    pasteYesLbl:SetAllPoints(pasteYes); pasteYesLbl:SetJustifyH("CENTER")
    pasteYesLbl:SetText("|cffd4af37Yes, Paste|r")

    local pasteNo = CreateFrame("Button",nil,pasteConfirm)
    pasteNo:SetSize(120,22); pasteNo:SetPoint("BOTTOMRIGHT",pasteConfirm,"BOTTOMRIGHT",-16,10)
    pasteNo:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    pasteNo:SetBackdropColor(0.10,0.08,0.02,1); pasteNo:SetBackdropBorderColor(0.78,0.61,0.23,0.9)
    pasteNo:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local pasteNoLbl = pasteNo:CreateFontString(nil,"OVERLAY","GameFontNormal")
    pasteNoLbl:SetAllPoints(pasteNo); pasteNoLbl:SetJustifyH("CENTER")
    pasteNoLbl:SetText("|cffd4af37Cancel|r")
    pasteNo:SetScript("OnClick", function() pasteConfirm:Hide() end)

    copyBtn:SetScript("OnClick", function()
        local roster, size = PBM.GetCurrentRoster()
        local t    = LichborneTrackerDB.raidTier  or 0
        local name = LichborneTrackerDB.raidName  or "?"
        local grp  = LichborneTrackerDB.raidGroup or "A"
        -- Deep copy the roster
        rosterClipboard = {}
        for i = 1, PBM.MAX_RAID_SLOTS do
            local r = roster[i] or {}
            rosterClipboard[i] = {
                name  = r.name  or "",
                cls   = r.cls   or "",
                spec  = r.spec  or "",
                gs    = r.gs    or 0,
                realGs = r.realGs or 0,
                role  = r.role  or "",
                notes = r.notes or "",
            }
        end
        clipboardLabel = "T"..t.." "..name.." ("..grp..")"
        pasteBtn:Show()
        if LichborneAddStatus then
            LichborneAddStatus:SetText("|cffd4af37Roster copied to clipboard: "..clipboardLabel.."|r")
        end
    end)

    pasteYes:SetScript("OnClick", function()
        pasteConfirm:Hide()
        if not rosterClipboard then return end
        local roster, size = PBM.GetCurrentRoster()
        -- Only paste up to destination size, clear any slots beyond it
        for i = 1, PBM.MAX_RAID_SLOTS do
            if i <= size then
                local src = rosterClipboard[i] or {}
                roster[i] = {
                    name  = src.name  or "",
                    cls   = src.cls   or "",
                    spec  = src.spec  or "",
                    gs    = src.gs    or 0,
                    realGs = src.realGs or 0,
                    role  = src.role  or "",
                    notes = src.notes or "",
                }
            else
                roster[i] = {name="", cls="", spec="", gs=0, realGs=0, role="", notes=""}
            end
        end
        -- Clear clipboard and hide paste button
        rosterClipboard = nil
        clipboardLabel  = nil
        pasteBtn:Hide()
        PBM.RefreshRaidRows()
        if LichborneAddStatus then
            LichborneAddStatus:SetText("|cffd4af37Roster copied!|r")
        end
    end)

    pasteBtn:SetScript("OnClick", function()
        if not rosterClipboard then pasteBtn:Hide(); return end
        local t    = LichborneTrackerDB.raidTier  or 0
        local name = LichborneTrackerDB.raidName  or "?"
        local grp  = LichborneTrackerDB.raidGroup or "A"
        local destLabel = "T"..t.." "..name.." ("..grp..")"
        pasteConfirmText:SetText("|cffd4af37Copy "..clipboardLabel.." roster to "..destLabel.."?|r")
        pasteConfirm:SetPoint("CENTER",UIParent,"CENTER",0,0)
        pasteConfirm:Show()
    end)

    -- Clear All button
    local clearBtn = CreateFrame("Button", nil, tierBar)
    clearBtn:SetSize(60, 20)
    clearBtn:SetPoint("RIGHT", tierBar, "RIGHT", -4, 0)
    clearBtn:SetFrameLevel(fl + 12)
    clearBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    clearBtn:SetBackdropColor(0.25,0.04,0.04,1)
    clearBtn:SetBackdropBorderColor(0.8,0.1,0.1,0.9)
    clearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local clearLbl = clearBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    clearLbl:SetAllPoints(clearBtn); clearLbl:SetJustifyH("CENTER"); clearLbl:SetJustifyV("MIDDLE")
    clearLbl:SetText("|cffd4af37Clear|r")
    clearBtn:SetScript("OnEnter",function()
        local raidName = LichborneTrackerDB and LichborneTrackerDB.raidName or "N/A (5-Man)"
        GameTooltip:SetOwner(clearBtn,"ANCHOR_BOTTOM")
        GameTooltip:AddLine("Clear This Raid (All Groups)",1,1,1)
        GameTooltip:AddLine("Removes all characters from "..raidName,0.8,0.8,0.8)
        GameTooltip:AddLine("across Groups A, B, and C.",0.7,0.7,0.7)
        GameTooltip:Show()
    end)
    clearBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)

    -- Confirm popup for Clear All
    local confirmFrame = CreateFrame("Frame","LichborneRaidClearConfirm",UIParent)
    confirmFrame:SetSize(400,100)
    confirmFrame:SetPoint("CENTER",UIParent,"CENTER",0,0)
    confirmFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    confirmFrame:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=3,right=3,top=3,bottom=3}})
    confirmFrame:SetBackdropColor(0.04,0.06,0.13,0.98)
    confirmFrame:SetBackdropBorderColor(0.78,0.61,0.23,1)
    confirmFrame:Hide()
    local confText = confirmFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
    confText:SetPoint("TOP",confirmFrame,"TOP",0,-12)
    confText:SetWidth(380); confText:SetJustifyH("CENTER")
    confText:SetText("|cffC69B3AClear this raid?|r")
    local confSub = confirmFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    confSub:SetPoint("TOP",confText,"BOTTOM",0,-4)
    confSub:SetText("|cffaaaaaa Clears Groups A, B, and C. Cannot be undone.|r")
    local yesBtn = CreateFrame("Button",nil,confirmFrame)
    yesBtn:SetSize(100,24); yesBtn:SetPoint("BOTTOMLEFT",confirmFrame,"BOTTOMLEFT",16,10)
    yesBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    yesBtn:SetBackdropColor(0.25,0.04,0.04,1); yesBtn:SetBackdropBorderColor(0.8,0.1,0.1,0.9)
    yesBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local yesLbl=yesBtn:CreateFontString(nil,"OVERLAY","GameFontNormal"); yesLbl:SetAllPoints(yesBtn); yesLbl:SetJustifyH("CENTER"); yesLbl:SetText("|cffff4444Yes, Clear|r")
    yesBtn:SetScript("OnClick",function()
        local raidName = LichborneTrackerDB.raidName or "N/A (5-Man)"
        if not LichborneTrackerDB.raidRosters then LichborneTrackerDB.raidRosters = {} end
        for _, g in ipairs({"A","B","C"}) do
            local key = raidName .. "_" .. g
            LichborneTrackerDB.raidRosters[key] = {}
            for i = 1, PBM.MAX_RAID_SLOTS do
                LichborneTrackerDB.raidRosters[key][i] = {name="",cls="",spec="",gs=0,realGs=0,role="",notes=""}
            end
        end
        PBM.RefreshRaidRows()
        if PBM.RefreshOverviewRows then PBM.RefreshOverviewRows() end
        confirmFrame:Hide()
    end)
    local noBtn = CreateFrame("Button",nil,confirmFrame)
    noBtn:SetSize(100,24); noBtn:SetPoint("BOTTOMRIGHT",confirmFrame,"BOTTOMRIGHT",-16,10)
    noBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    noBtn:SetBackdropColor(0.04,0.15,0.04,1); noBtn:SetBackdropBorderColor(0.1,0.7,0.1,0.9)
    noBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local noLbl=noBtn:CreateFontString(nil,"OVERLAY","GameFontNormal"); noLbl:SetAllPoints(noBtn); noLbl:SetJustifyH("CENTER"); noLbl:SetText("|cff44ff44Cancel|r")
    noBtn:SetScript("OnClick",function() confirmFrame:Hide() end)

    clearBtn:SetScript("OnClick",function()
        local raidName = LichborneTrackerDB and LichborneTrackerDB.raidName or "N/A (5-Man)"
        confText:SetText("|cffC69B3AClear |cffd4af37"..raidName.."|cffC69B3A?|r")
        confirmFrame:SetPoint("CENTER",UIParent,"CENTER",0,0)
        confirmFrame:Show()
    end)

    -- Column headers row
    local hdrRow = CreateFrame("Frame",nil,LichborneRaidFrame)
    hdrRow:SetPoint("TOPLEFT",LichborneRaidFrame,"TOPLEFT",-5,-26)
    hdrRow:SetSize(543,18)
    hdrRow:SetFrameLevel(fl+11)
    local hdrBg = hdrRow:CreateTexture(nil,"BACKGROUND"); hdrBg:SetAllPoints(hdrRow); hdrBg:SetTexture(0.08,0.20,0.42,1)

    local function RH(lbl,x,w)
        local fs=hdrRow:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        fs:SetPoint("LEFT",hdrRow,"LEFT",x,0); fs:SetWidth(w); fs:SetJustifyH("CENTER")
        fs:SetText("|cffd4af37"..lbl.."|r")
    end
    local function RSH(lbl,x,w,key,isNumeric,tipExtra)
        local btn = CreateFrame("Button",nil,hdrRow)
        btn:SetPoint("TOPLEFT",hdrRow,"TOPLEFT",x,0)
        btn:SetSize(w,18); btn:SetFrameLevel(hdrRow:GetFrameLevel()+2)
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        local fs=btn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        fs:SetAllPoints(btn); fs:SetJustifyH("CENTER"); fs:SetJustifyV("MIDDLE")
        fs:SetText("|cffd4af37"..lbl.."|r")
        PBM.State.raidSortHdrs[key] = {lbl=lbl, fs=fs}
        btn:SetScript("OnEnter",function()
            GameTooltip:SetOwner(btn,"ANCHOR_BOTTOM")
            GameTooltip:AddLine("Click to sort",1,1,1)
            if tipExtra then GameTooltip:AddLine(tipExtra,0.8,0.8,0.8) end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave",function() GameTooltip:Hide() end)
        btn:SetScript("OnClick",function()
            if PBM.State.raidSortKey == key then
                PBM.State.raidSortAsc = not PBM.State.raidSortAsc
            else
                PBM.State.raidSortKey = key
                PBM.State.raidSortAsc = not isNumeric
            end
            PBM.State.raidSortPending = true
            PBM.UpdateRaidSortHeaders()
            PBM.RefreshRaidRows()
        end)
    end

    -- Layout constants for raid rows (both columns identical, 530px wide)
    local RD=0; local RC=20; local RS=42; local RN=66; local RG=178; local RRealGS=232; local RRole=286; local RNotes=326; local RInvX=0; local RDelX=0  -- InvX/DelX unused, buttons use RIGHT anchor
    -- Spec header icon only (no class icon header)
    local specHdrTex = hdrRow:CreateTexture(nil, "OVERLAY")
    specHdrTex:SetPoint("LEFT", hdrRow, "LEFT", RS, 0)
    specHdrTex:SetSize(18, 16)
    specHdrTex:SetTexture("Interface\\Icons\\Ability_Rogue_Deadliness")
    RH("#", RD, 18)
    RSH("Spec", RS-4, 26, "spec", false, "Click 1: Death Knight first (A-Z classes)\nClick 2: Warrior first (Z-A classes)\nSpec within class always A-Z")
    RSH("Name", RN+2, 108, "name", false, nil)
    RSH("iLvL", RG+2, 50, "ilvl", true, nil)
    RSH("GS",   RRealGS+2, 50, "gs", true, nil)
    RSH("Role", RRole, 36, "role", false, nil)
    RH("Notes", RNotes+2, 169)

    -- Build 40 raid rows (2 columns of 20)
    local ROW_H = 22
    local COL2_X = 538

    for i=1,40 do
        local col = i <= 20 and -5 or COL2_X
        local rowIdx = i <= 20 and (i-1) or (i-21)
        local yOff = -46 - rowIdx * ROW_H

        local rf = CreateFrame("Frame","LichborneRaidRow"..i,LichborneRaidFrame)
        rf:SetPoint("TOPLEFT",LichborneRaidFrame,"TOPLEFT",col,yOff)
        rf:SetSize(543,ROW_H)
        rf:SetFrameLevel(fl+11)

        local rbg = rf:CreateTexture(nil,"BACKGROUND"); rbg:SetAllPoints(rf)
        rbg:SetTexture(i%2==0 and 0.05 or 0.07, i%2==0 and 0.07 or 0.09, i%2==0 and 0.13 or 0.16, 1)

        -- Hover highlight texture
        rf:EnableMouse(true)
        local raidHov = rf:CreateTexture(nil,"OVERLAY"); raidHov:SetAllPoints(rf); raidHov:SetTexture(0,0,0,0); rf.raidHov = raidHov
        rf:SetScript("OnEnter", function()
            raidHov:SetTexture(0.78, 0.61, 0.23, 0.12)
        end)
        rf:SetScript("OnLeave", function()
            raidHov:SetTexture(0, 0, 0, 0)
        end)

        -- Row number
        local rowNum = rf:CreateFontString(nil, "OVERLAY")
        rowNum:SetPoint("LEFT", rf, "LEFT", RD, 0)
        rowNum:SetSize(18, ROW_H)
        rowNum:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        rowNum:SetJustifyH("CENTER")
        rowNum:SetJustifyV("MIDDLE")
        rowNum:SetTextColor(0.55, 0.55, 0.55, 1)
        rowNum:SetText(tostring(i))
        rf.rowNum = rowNum

        -- Class icon (plain Frame, same as All tab)
        local clsBtn = CreateFrame("Frame",nil,rf)
        clsBtn:SetPoint("LEFT",rf,"LEFT",RC,0); clsBtn:SetSize(18,18)
        local clsTex = clsBtn:CreateTexture(nil,"ARTWORK"); clsTex:SetAllPoints(clsBtn); clsTex:SetTexture(0,0,0,0)
        rf.classIcon = clsTex
        -- Class is set automatically when adding from class tabs

        -- Spec icon (Button so it receives mouse events for future use)
        local specBtn = CreateFrame("Button",nil,rf)
        specBtn:SetPoint("LEFT",rf,"LEFT",RS,0); specBtn:SetSize(18,18)
        specBtn:SetFrameLevel(rf:GetFrameLevel()+2)
        specBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        local specTex=specBtn:CreateTexture(nil,"ARTWORK"); specTex:SetAllPoints(specBtn); specTex:SetTexture(0,0,0,0)
        rf.specIcon=specTex; rf.specBtn=specBtn

        -- Name editbox
        local nb=CreateFrame("EditBox",nil,rf)
        nb:SetPoint("LEFT",rf,"LEFT",RN,0); nb:SetSize(106,ROW_H-2)
        nb:SetAutoFocus(false); nb:SetMaxLetters(24); nb:EnableKeyboard(false); nb:EnableMouse(false)
        nb:SetFont("Fonts\\FRIZQT__.TTF",10)
        nb:SetTextColor(0.9,0.95,1.0)
        nb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        nb:SetBackdropColor(0.05,0.07,0.14,0.6)
        nb:SetBackdropBorderColor(0.12,0.18,0.30,0.5)
        rf.nameBox=nb

        -- iLvl editbox
        local gsb=CreateFrame("EditBox",nil,rf)
        gsb:SetPoint("LEFT",rf,"LEFT",RG,0); gsb:SetSize(50,ROW_H-2)
        gsb:SetAutoFocus(false); gsb:SetMaxLetters(5); gsb:EnableKeyboard(false)
        gsb:SetFont("Fonts\\FRIZQT__.TTF",10,"OUTLINE")
        gsb:SetTextColor(0.831, 0.686, 0.216); gsb:SetJustifyH("CENTER")
        gsb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        gsb:SetBackdropColor(0.05,0.07,0.14,0.6)
        gsb:SetBackdropBorderColor(0.12,0.18,0.30,0.5)
        gsb:SetScript("OnEditFocusGained", function(self) self:ClearFocus() end)
        rf.gsBox=gsb
        gsb:SetScript("OnEnter", function() rf.raidHov:SetTexture(0.78, 0.61, 0.23, 0.12) end)
        gsb:SetScript("OnLeave", function() if GetMouseFocus()~=rf then rf.raidHov:SetTexture(0,0,0,0) end end)

        -- GS editbox
        local realGsb=CreateFrame("EditBox",nil,rf)
        realGsb:SetPoint("LEFT",rf,"LEFT",RRealGS,0); realGsb:SetSize(50,ROW_H-2)
        realGsb:SetAutoFocus(false); realGsb:SetMaxLetters(5); realGsb:EnableKeyboard(false)
        realGsb:SetFont("Fonts\\FRIZQT__.TTF",10,"OUTLINE")
        realGsb:SetTextColor(0.831, 0.686, 0.216); realGsb:SetJustifyH("CENTER")
        realGsb:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        realGsb:SetBackdropColor(0.05,0.07,0.14,0.6)
        realGsb:SetBackdropBorderColor(0.12,0.18,0.30,0.5)
        realGsb:SetScript("OnEditFocusGained", function(self) self:ClearFocus() end)
        rf.realGsBox=realGsb
        realGsb:SetScript("OnEnter", function() rf.raidHov:SetTexture(0.78, 0.61, 0.23, 0.12) end)
        realGsb:SetScript("OnLeave", function() if GetMouseFocus()~=rf then rf.raidHov:SetTexture(0,0,0,0) end end)

        -- Role button (combined role placeholder, 3 icons wide)
        local roleBtn = CreateFrame("Button",nil,rf)
        roleBtn:SetPoint("LEFT",rf,"LEFT",RRole,0); roleBtn:SetSize(36,ROW_H-2)
        roleBtn:SetFrameLevel(rf:GetFrameLevel()+6)
        roleBtn:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        roleBtn:SetBackdropColor(0.05,0.07,0.14,0.8); roleBtn:SetBackdropBorderColor(0.20,0.30,0.50,0.4)
        roleBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        local roleIcon=roleBtn:CreateTexture(nil,"ARTWORK")
        roleIcon:SetPoint("CENTER",roleBtn,"CENTER",0,0); roleIcon:SetSize(16,16)
        roleIcon:SetTexture(0,0,0,0)
        local roleLbl=roleBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        roleLbl:SetAllPoints(roleBtn); roleLbl:SetJustifyH("CENTER"); roleLbl:SetJustifyV("MIDDLE")
        roleLbl:SetText(""); rf.roleBtn=roleBtn; rf.roleLbl=roleLbl; rf.roleIcon=roleIcon
        local noteRoleIcons = {}
        for ni = 1, 2 do
            local nri = roleBtn:CreateTexture(nil,"ARTWORK")
            nri:SetPoint("LEFT",roleBtn,"LEFT",(ni-1)*18,0); nri:SetSize(16,16)
            nri:SetTexture(0,0,0,0)
            noteRoleIcons[ni] = nri
        end
        rf.noteRoleIcons = noteRoleIcons
        PBM.HookRowHighlight(roleBtn, rf, rf.raidHov)

        -- Notes editbox
        local notesBox=CreateFrame("EditBox",nil,rf)
        notesBox:SetPoint("LEFT",rf,"LEFT",RNotes,0); notesBox:SetSize(169,ROW_H-2)
        notesBox:SetAutoFocus(false); notesBox:SetMaxLetters(512)
        notesBox:EnableKeyboard(false)
        notesBox:SetFont("Fonts\\FRIZQT__.TTF",9); notesBox:SetTextColor(0.85,0.85,0.70)
        notesBox:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        notesBox:SetBackdropColor(0.05,0.07,0.10,0.6); notesBox:SetBackdropBorderColor(0.25,0.25,0.15,0.5)
        notesBox:SetScript("OnEnterPressed",function() notesBox:ClearFocus() end)
        notesBox:SetScript("OnTabPressed",function() notesBox:ClearFocus() end)
        notesBox:SetScript("OnEscapePressed",function() notesBox:ClearFocus() end)
        rf.notesBox=notesBox
        notesBox:SetScript("OnEnter", function() rf.raidHov:SetTexture(0.78, 0.61, 0.23, 0.12) end)
        notesBox:SetScript("OnLeave", function() if GetMouseFocus()~=rf then rf.raidHov:SetTexture(0,0,0,0) end end)

        -- Class btn reference for color updates
        rf.classBtn=clsBtn; rf.classBtnTex=clsTex

        -- Clear/delete button (far right)
        local db=CreateFrame("Button",nil,rf)
        db:SetPoint("RIGHT",rf,"RIGHT",-2,0)
        db:SetSize(16,ROW_H-2)
        db:SetNormalFontObject("GameFontNormalSmall"); db:SetText("|cffaa2222x|r")
        db:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        db:SetScript("OnEnter", function()
            GameTooltip:SetOwner(db, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Remove from Raid", 1, 0.3, 0.3)
            GameTooltip:AddLine("Clears this slot in the raid roster.", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("Character remains in the tracker.", 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end)
        db:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rf.delBtn=db

        -- Invite to group > button
        local invb = CreateFrame("Button", nil, rf)
        invb:SetPoint("RIGHT",rf,"RIGHT",-20,0)
        invb:SetSize(16, ROW_H-2)
        invb:SetNormalFontObject("GameFontNormalSmall"); invb:SetText("|cff44eeff>|r")
        invb:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        invb:SetScript("OnEnter", function()
            GameTooltip:SetOwner(invb, "ANCHOR_RIGHT")
            GameTooltip:AddLine("|cff44eeff> Invite to Group|r", 1,1,1)
            GameTooltip:AddLine("Left-click to invite to group.", 0.7,0.7,0.7)
            GameTooltip:AddLine("Right-click to remove.", 0.7,0.4,0.4)
            GameTooltip:Show()
        end)
        invb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        invb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        invb:SetScript("OnClick", function(self, btn)
            local roster, _ = PBM.GetCurrentRoster()
            local d = roster[i]
            if d and d.name and d.name ~= "" then
                if btn == "RightButton" then
                    UninviteUnit(d.name)
                    SendChatMessage(".playerbots bot remove "..d.name, "SAY")
                    LichborneOutput("|cffC69B3ALichborne:|r Removed "..d.name.." from bots.", 1, 0.85, 0)
                    return
                end
                SendChatMessage(".playerbots bot add "..d.name, "SAY")
                if LichborneAddStatus then
                    LichborneAddStatus:SetText("|cffd4af37Invited "..d.name.." to group.|r")
                end
            end
        end)
        rf.invBtn = invb

        -- Hook child elements to propagate row highlight
        local rHov = rf.raidHov
        PBM.HookRowHighlight(db, rf, rHov)
        PBM.HookRowHighlight(invb, rf, rHov)
        if rf.specBtn then PBM.HookRowHighlight(rf.specBtn, rf, rHov) end
        if rf.roleBtn then PBM.HookRowHighlight(rf.roleBtn, rf, rHov) end

        -- Divider
        local ln=rf:CreateTexture(nil,"OVERLAY"); ln:SetHeight(1); ln:SetWidth(543)
        ln:SetPoint("BOTTOMLEFT",rf,"BOTTOMLEFT",0,0); ln:SetTexture(0.10,0.16,0.28,0.4)

        PBM.State.raidRowFrames[i]=rf
    end

    -- Second column header
    local hdrRow2 = CreateFrame("Frame",nil,LichborneRaidFrame)
    hdrRow2:SetPoint("TOPLEFT",LichborneRaidFrame,"TOPLEFT",COL2_X,-26)
    hdrRow2:SetSize(543,18); hdrRow2:SetFrameLevel(fl+11)
    local hdrBg2=hdrRow2:CreateTexture(nil,"BACKGROUND"); hdrBg2:SetAllPoints(hdrRow2); hdrBg2:SetTexture(0.08,0.20,0.42,1)
    local RH2 = function(lbl,x,w)
        local fs=hdrRow2:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        fs:SetPoint("LEFT",hdrRow2,"LEFT",x,0); fs:SetWidth(w); fs:SetJustifyH("CENTER")
        fs:SetText("|cffd4af37"..lbl.."|r")
    end
    local specHdrTex2 = hdrRow2:CreateTexture(nil, "OVERLAY")
    specHdrTex2:SetPoint("LEFT", hdrRow2, "LEFT", RS, 0)
    specHdrTex2:SetSize(18, 16)
    specHdrTex2:SetTexture("Interface\\Icons\\Ability_Rogue_Deadliness")
    RH2("Name",RN+2,108); RH2("iLvL",RG+2,50); RH2("GS",RRealGS+2,50); RH2("Role",RRole,36); RH2("Notes",RNotes+2,169)

        -- ── Raid class count bar ──────────────────────────────────
    local raidCountBar = CreateFrame("Frame","LichborneRaidCountBar",LichborneRaidFrame)
    _G["LichborneRaidCountBar"] = raidCountBar
    raidCountBar:SetPoint("TOPLEFT", LichborneRaidFrame, "TOPLEFT", -5, -488)
    raidCountBar:SetSize(1086, 24)
    raidCountBar:SetFrameLevel(fl + 11)
    local rcbBg = raidCountBar:CreateTexture(nil,"BACKGROUND")
    rcbBg:SetAllPoints(raidCountBar); rcbBg:SetTexture(0.05, 0.07, 0.13, 1)
    local rcTitle = raidCountBar:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    rcTitle:SetPoint("LEFT", raidCountBar, "LEFT", 4, 0)
    rcTitle:SetText("|cffC69B3ACount:|r"); rcTitle:SetWidth(44)
    PBM.State.LichborneRaidCountLabels = {}
    local rcW = (1086 - 50) / 10
    local rcIdx = 0
    for ci, cls in ipairs(PBM.CLASS_TABS) do
        if cls == "Raid" or cls == "Overview" then break end
        rcIdx = rcIdx + 1
        local c = PBM.CLASS_COLORS[cls]
        local rcSw = CreateFrame("Button", nil, raidCountBar)
        rcSw:SetSize(rcW - 2, 20)
        rcSw:SetPoint("LEFT", raidCountBar, "LEFT", 48 + (rcIdx-1)*rcW, 0)
        rcSw:SetFrameLevel(raidCountBar:GetFrameLevel() + 1)
        local rcBg2 = rcSw:CreateTexture(nil,"BACKGROUND"); rcBg2:SetAllPoints(rcSw)
        rcBg2:SetTexture(0.08, 0.10, 0.18, 1); rcSw.bg = rcBg2
        local hex = string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255))
        local rcLbl = rcSw:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        rcLbl:SetAllPoints(rcSw); rcLbl:SetJustifyH("CENTER"); rcLbl:SetJustifyV("MIDDLE")
        rcLbl:SetText(hex..(PBM.TAB_LABELS[cls])..": "..hex.."0|r")
        rcSw.lbl = rcLbl; rcSw.cls = cls
        PBM.State.LichborneRaidCountLabels[cls] = rcLbl
        rcSw:SetScript("OnEnter", function()
            GameTooltip:SetOwner(rcSw,"ANCHOR_TOP")
            GameTooltip:AddLine(cls, c.r, c.g, c.b)
            GameTooltip:Show()
        end)
        rcSw:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- ── Invite Raid button (anchored below raid frame) ────────
    -- Invite button lives on main frame beside Add Target/Update GS buttons

    local inviteBtn = CreateFrame("Button","LichborneInviteRaidBtn",LichborneRaidFrame:GetParent())
    inviteBtn:SetPoint("BOTTOMLEFT", LichborneRaidFrame:GetParent(), "BOTTOMLEFT", 495, 8)
    inviteBtn:SetSize(155, 81)
    inviteBtn:SetFrameLevel(fl + 12)
    inviteBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    inviteBtn:SetBackdropColor(0.30,0.15,0.01,1)
    inviteBtn:SetBackdropBorderColor(0.78,0.61,0.23,0.9)
    inviteBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local inviteLbl = inviteBtn:CreateFontString(nil,"OVERLAY","GameFontNormal")
    inviteLbl:SetAllPoints(inviteBtn); inviteLbl:SetJustifyH("CENTER"); inviteLbl:SetJustifyV("MIDDLE")
    inviteLbl:SetText("|cffd4af37Invite Raid|r")
    inviteBtn.lbl = inviteLbl
    inviteBtn:SetScript("OnEnter",function()
        local roster, size = PBM.GetCurrentRoster()
        local count = 0
        for i=1,size do if roster[i] and roster[i].name and roster[i].name ~= "" then count=count+1 end end
        GameTooltip:SetOwner(inviteBtn,"ANCHOR_TOP")
        GameTooltip:AddLine("Invite Raid",0.78,0.61,0.23)
        GameTooltip:AddLine(count.." players in this roster",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    inviteBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)

    inviteBtn:SetScript("OnClick",function()
        local roster, size = PBM.GetCurrentRoster()
        -- Collect non-empty names
        local names = {}
        local nameClasses = {}
        local selfName  = UnitName("player")
        local selfLower = selfName and selfName:lower() or ""
        for i=1,size do
            local r = roster[i]
            if r and r.name and r.name ~= "" and r.name:lower() ~= selfLower then
                names[#names+1] = r.name
                nameClasses[r.name] = r.cls
            end
        end
        if #names == 0 then
            LichborneOutput("|cffC69B3ALichborne:|r No players in this roster.",1,0.5,0.5)
            return
        end
        local function GetClassHex(name)
            local cls = nameClasses[name]
            local c = cls and PBM.CLASS_COLORS[cls]
            if c then return string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255)) end
            return "|cffffff88"
        end

        local totalCount = #names + 1  -- +1 for the player who fired the sequence
        PBM.SetInviteActive(true)
        LichborneOutput("|cffC69B3ALichborne:|r Starting raid invite for "..totalCount.." players...",1,0.85,0)
        if LichborneAddStatus then LichborneAddStatus:SetText("|cffff9900Logging out all bots...") end

        -- Step 0: Remove all bots with wildcard
        SendChatMessage(".playerbots bot remove *", "SAY")

        local inviteIndex = 1
        local waitTime = 0
        local phase = "logout_wait"
        local reinviteSubPhase = "remove"
        local slot6Name = nil

        local inviteFrame = CreateFrame("Frame")
        PBM.State.activeInviteFrame = inviteFrame
        PBM.UpdateInviteButtons()
        inviteFrame:SetScript("OnUpdate",function(_, elapsed)
            waitTime = waitTime + elapsed

            if phase == "logout_wait" then
                if waitTime < 1.5 then return end
                waitTime = 0
                -- Leave party after bots are removed
                LeaveParty()
                phase = "leave_wait"
                LichborneOutput("|cffC69B3ALichborne:|r Bots removed, leaving party...",1,0.85,0)
                if LichborneAddStatus then LichborneAddStatus:SetText("|cffff9900Leaving party, then inviting...") end

            elseif phase == "leave_wait" then
                if waitTime < 1.0 then return end
                waitTime = 0
                phase = "first"
                LichborneOutput("|cffC69B3ALichborne:|r Bots cleared, starting invites...",1,0.85,0)
                if LichborneAddStatus then LichborneAddStatus:SetText("|cffff9900Inviting "..totalCount.." players...") end

            elseif phase == "first" then
                if waitTime < 0.5 then return end
                local firstName = names[1]
                SendChatMessage(".playerbots bot add "..firstName, "SAY")
                LichborneOutput("|cffC69B3ALichborne:|r Inviting "..GetClassHex(firstName)..firstName.."|r...",1,0.85,0)
                inviteIndex = 2
                waitTime = 0
                phase = "rest"

            elseif phase == "rest" then
                if waitTime < 0.8 then return end
                waitTime = 0
                if inviteIndex > #names then
                    -- Initial pass done — wait 3s then verify who's missing
                    phase = "verify_wait"
                    waitTime = 0
                    LichborneOutput("|cffC69B3ALichborne:|r Initial invites sent, verifying...",1,0.85,0)
                    return
                end
                local pname = names[inviteIndex]
                SendChatMessage(".playerbots bot add "..pname, "SAY")
                LichborneOutput("|cffC69B3ALichborne:|r Inviting "..GetClassHex(pname)..pname.."|r...",1,0.85,0)
                inviteIndex = inviteIndex + 1
                -- player + names[1..5] = 6; names[5] just logged in and triggered conversion
                -- store it for InviteUnit after 1s pause, then continue normally
                if inviteIndex == 6 and names[5] then
                    slot6Name = names[5]
                    phase = "raid_pause"
                    waitTime = 0
                    LichborneOutput("|cffC69B3ALichborne:|r Pausing for auto-conversion...",1,0.85,0)
                end

            elseif phase == "raid_pause" then
                if waitTime < 1.0 then return end
                if slot6Name then
                    InviteUnit(slot6Name)
                    LichborneOutput("|cffC69B3ALichborne:|r Native invite "..GetClassHex(slot6Name)..slot6Name.."|r...",1,0.85,0)
                    slot6Name = nil
                end
                waitTime = 0
                phase = "rest"

            elseif phase == "verify_wait" then
                if waitTime < 3.0 then return end
                -- Build set of who is currently in the raid
                local inRaid = {}
                for i = 1, GetNumRaidMembers() do
                    local rname = UnitName("raid"..i)
                    if rname then inRaid[rname:lower()] = true end
                end
                local selfName = UnitName("player")
                if selfName then inRaid[selfName:lower()] = true end
                -- Find missing
                local missing = {}
                for _, pname in ipairs(names) do
                    if not inRaid[pname:lower()] then
                        missing[#missing+1] = pname
                    end
                end
                if #missing == 0 then
                    LichborneOutput("|cffC69B3ALichborne:|r |cff44ff44All "..totalCount.." players confirmed in raid!|r",1,0.85,0)
                    if LichborneAddStatus then LichborneAddStatus:SetText("|cff44ff44All "..totalCount.." players confirmed in raid.|r") end
                    inviteFrame:SetScript("OnUpdate",nil)
                    PBM.State.activeInviteFrame = nil
                    PBM.SetInviteActive(false)
                    PBM.UpdateInviteButtons()
                    return
                end
                LichborneOutput("|cffC69B3ALichborne:|r |cffff9900"..#missing.." missed — re-inviting...|r",1,0.85,0)
                names = missing
                inviteIndex = 1
                phase = "reinvite"
                waitTime = 0

            elseif phase == "reinvite" then
                -- remove then wait 1s then add, per missed character
                if reinviteSubPhase == "remove" then
                    if inviteIndex > #names then
                        LichborneOutput("|cffC69B3ALichborne:|r |cff44ff44Re-invite pass complete.|r",1,0.85,0)
                        if LichborneAddStatus then LichborneAddStatus:SetText("|cff44ff44Invite complete (re-invite pass done).|r") end
                        inviteFrame:SetScript("OnUpdate",nil)
                        PBM.State.activeInviteFrame = nil
                        PBM.SetInviteActive(false)
                        PBM.UpdateInviteButtons()
                        return
                    end
                    local pname = names[inviteIndex]
                    SendChatMessage(".playerbots bot remove "..pname, "SAY")
                    LichborneOutput("|cffC69B3ALichborne:|r Removing "..GetClassHex(pname)..pname.."|r before re-invite...",1,0.85,0)
                    waitTime = 0
                    reinviteSubPhase = "add"

                elseif reinviteSubPhase == "add" then
                    if waitTime < 1.0 then return end
                    local pname = names[inviteIndex]
                    SendChatMessage(".playerbots bot add "..pname, "SAY")
                    LichborneOutput("|cffC69B3ALichborne:|r Re-inviting "..GetClassHex(pname)..pname.."|r...",1,0.85,0)
                    inviteIndex = inviteIndex + 1
                    waitTime = 0
                    reinviteSubPhase = "remove"
                end
            end
        end)
    end)

    -- ── Invite Group button (for T0 5-mans, no raid conversion) ──
    local inviteGroupBtn = CreateFrame("Button","LichborneInviteGroupBtn",LichborneRaidFrame:GetParent())
    inviteGroupBtn:SetPoint("BOTTOMLEFT", LichborneRaidFrame:GetParent(), "BOTTOMLEFT", 495, 92)
    inviteGroupBtn:SetSize(155, 81)
    inviteGroupBtn:SetFrameLevel(fl + 12)
    inviteGroupBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    inviteGroupBtn:SetBackdropColor(0.035,0.14,0.245,1)
    inviteGroupBtn:SetBackdropBorderColor(0.78,0.61,0.23,0.9)
    inviteGroupBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local inviteGroupLbl = inviteGroupBtn:CreateFontString(nil,"OVERLAY","GameFontNormal")
    inviteGroupLbl:SetAllPoints(inviteGroupBtn); inviteGroupLbl:SetJustifyH("CENTER"); inviteGroupLbl:SetJustifyV("MIDDLE")
    inviteGroupLbl:SetText("|cffd4af37Invite Group|r")
    inviteGroupBtn.lbl = inviteGroupLbl
    inviteGroupBtn:SetScript("OnEnter",function()
        -- Always count from T0 5-Man roster
        local t0group = (LichborneTrackerDB and LichborneTrackerDB.raidGroup) or "A"
        local t0key = "N/A (5-Man)_" .. t0group
        local t0roster = (LichborneTrackerDB and LichborneTrackerDB.raidRosters and LichborneTrackerDB.raidRosters[t0key]) or {}
        local count = 0
        for i=1,5 do if t0roster[i] and t0roster[i].name and t0roster[i].name ~= "" then count=count+1 end end
        GameTooltip:SetOwner(inviteGroupBtn,"ANCHOR_TOP")
        GameTooltip:AddLine("Invite Group (5-Man)",0.78,0.61,0.23)
        GameTooltip:AddLine(count.." players in T0 5-Man roster",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    inviteGroupBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)
    inviteGroupBtn:SetScript("OnClick",function()
        -- Always invite from T0 5-Man roster
        local t0group = (LichborneTrackerDB and LichborneTrackerDB.raidGroup) or "A"
        local t0key = "N/A (5-Man)_" .. t0group
        if not LichborneTrackerDB.raidRosters then LichborneTrackerDB.raidRosters = {} end
        if not LichborneTrackerDB.raidRosters[t0key] then
            LichborneTrackerDB.raidRosters[t0key] = {}
            for i = 1, PBM.MAX_RAID_SLOTS do
                LichborneTrackerDB.raidRosters[t0key][i] = {name="", cls="", spec="", gs=0, realGs=0, role="", notes=""}
            end
        end
        local t0roster = LichborneTrackerDB.raidRosters[t0key]
        local names = {}
        local nameClasses = {}
        for i=1,5 do
            local r = t0roster[i]
            if r and r.name and r.name ~= "" then
                names[#names+1] = r.name
                nameClasses[r.name] = r.cls
            end
        end
        if #names == 0 then
            LichborneOutput("|cffC69B3ALichborne:|r No players in T0 5-Man roster.",1,0.5,0.5)
            return
        end
        local function GetClassHex(name)
            local cls = nameClasses[name]
            local c = cls and PBM.CLASS_COLORS[cls]
            if c then return string.format("|cff%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255)) end
            return "|cffffff88"
        end
        PBM.SetInviteActive(true)
        LichborneOutput("|cffC69B3ALichborne:|r Starting group invite for "..#names.." players...",1,0.85,0)
        if LichborneAddStatus then LichborneAddStatus:SetText("|cffff9900Logging out all bots...") end
        -- Remove all bots with wildcard first
        SendChatMessage(".playerbots bot remove *", "SAY")
        local invIdx = 1
        local waited = 0
        local grpPhase = "logout_wait"
        local grpReinviteSubPhase = "remove"
        local grpFrame = CreateFrame("Frame")
        PBM.State.activeInviteFrame = grpFrame
        PBM.UpdateInviteButtons()
        grpFrame:SetScript("OnUpdate",function(_, elapsed)
            waited = waited + elapsed
            if grpPhase == "logout_wait" then
                if waited < 1.5 then return end
                waited = 0
                LeaveParty()
                grpPhase = "leave_wait"
                LichborneOutput("|cffC69B3ALichborne:|r Bots removed, leaving party...",1,0.85,0)
                if LichborneAddStatus then LichborneAddStatus:SetText("|cffff9900Leaving party, then inviting...") end
            elseif grpPhase == "leave_wait" then
                if waited < 1.0 then return end
                waited = 0
                grpPhase = "invite"
                LichborneOutput("|cffC69B3ALichborne:|r Starting group invites...",1,0.85,0)
                if LichborneAddStatus then LichborneAddStatus:SetText("|cffff9900Inviting "..#names.." players...") end
            elseif grpPhase == "invite" then
                if waited < 0.8 then return end
                waited = 0
                if invIdx > #names then
                    -- Verify pass
                    grpPhase = "verify_wait"
                    waited = 0
                    LichborneOutput("|cffC69B3ALichborne:|r Initial invites sent, verifying...",1,0.85,0)
                    return
                end
                local pname = names[invIdx]
                SendChatMessage(".playerbots bot add "..pname, "SAY")
                LichborneOutput("|cffC69B3ALichborne:|r Inviting "..GetClassHex(pname)..pname.."|r...",1,0.85,0)
                invIdx = invIdx + 1
            elseif grpPhase == "verify_wait" then
                if waited < 3.0 then return end
                -- Build set of who is currently in the party
                local inParty = {}
                for pi = 1, GetNumPartyMembers() do
                    local pn = UnitName("party"..pi)
                    if pn then inParty[pn:lower()] = true end
                end
                local selfName = UnitName("player")
                if selfName then inParty[selfName:lower()] = true end
                local missing = {}
                for _, pname in ipairs(names) do
                    if not inParty[pname:lower()] then
                        missing[#missing+1] = pname
                    end
                end
                if #missing == 0 then
                    LichborneOutput("|cffC69B3ALichborne:|r |cff44ff44All "..#names.." players confirmed in group!|r",1,0.85,0)
                    if LichborneAddStatus then LichborneAddStatus:SetText("|cff44ff44All "..#names.." players confirmed in group.|r") end
                    grpFrame:SetScript("OnUpdate",nil)
                    PBM.State.activeInviteFrame = nil
                    PBM.SetInviteActive(false)
                    PBM.UpdateInviteButtons()
                    return
                end
                LichborneOutput("|cffC69B3ALichborne:|r |cffff9900"..#missing.." missed — re-inviting...|r",1,0.85,0)
                names = missing
                invIdx = 1
                grpPhase = "reinvite"
                waited = 0
            elseif grpPhase == "reinvite" then
                if grpReinviteSubPhase == "remove" then
                    if invIdx > #names then
                        LichborneOutput("|cffC69B3ALichborne:|r |cff44ff44Re-invite pass complete.|r",1,0.85,0)
                        if LichborneAddStatus then LichborneAddStatus:SetText("|cff44ff44Invite complete (re-invite pass done).|r") end
                        grpFrame:SetScript("OnUpdate",nil)
                        PBM.State.activeInviteFrame = nil
                        PBM.SetInviteActive(false)
                        PBM.UpdateInviteButtons()
                        return
                    end
                    local pname = names[invIdx]
                    SendChatMessage(".playerbots bot remove "..pname, "SAY")
                    LichborneOutput("|cffC69B3ALichborne:|r Removing "..GetClassHex(pname)..pname.."|r before re-invite...",1,0.85,0)
                    waited = 0
                    grpReinviteSubPhase = "add"
                elseif grpReinviteSubPhase == "add" then
                    if waited < 1.0 then return end
                    local pname = names[invIdx]
                    SendChatMessage(".playerbots bot add "..pname, "SAY")
                    LichborneOutput("|cffC69B3ALichborne:|r Re-inviting "..GetClassHex(pname)..pname.."|r...",1,0.85,0)
                    invIdx = invIdx + 1
                    waited = 0
                    grpReinviteSubPhase = "remove"
                end
            end
        end)
    end)
    _G["LichborneInviteGroupBtn"] = inviteGroupBtn

    -- ── Stop Invite overlay (full right column, covers both invite buttons) ──
    local stopInviteBtn = CreateFrame("Button","LichborneStopInviteBtn",LichborneRaidFrame:GetParent())
    stopInviteBtn:SetPoint("BOTTOMLEFT", LichborneRaidFrame:GetParent(), "BOTTOMLEFT", 495, 8)
    stopInviteBtn:SetSize(155, 165)
    stopInviteBtn:SetFrameLevel(fl + 13)
    stopInviteBtn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    stopInviteBtn:SetBackdropColor(0.25, 0.05, 0.05, 1)
    stopInviteBtn:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
    stopInviteBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    local stopInviteLbl = stopInviteBtn:CreateFontString(nil,"OVERLAY","GameFontNormal")
    stopInviteLbl:SetAllPoints(stopInviteBtn); stopInviteLbl:SetJustifyH("CENTER"); stopInviteLbl:SetJustifyV("MIDDLE")
    stopInviteLbl:SetText("|cffd4af37Stop Invite|r")
    stopInviteBtn:SetScript("OnEnter",function()
        GameTooltip:SetOwner(stopInviteBtn,"ANCHOR_TOP")
        GameTooltip:AddLine("Stop Invite",1,1,1)
        GameTooltip:AddLine("Cancels the running invite script.",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    stopInviteBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)
    stopInviteBtn:SetScript("OnClick",function()
        if PBM.State.activeInviteFrame then
            PBM.State.activeInviteFrame:SetScript("OnUpdate", nil)
            PBM.State.activeInviteFrame = nil
            PBM.SetInviteActive(false)
            PBM.UpdateInviteButtons()
            LichborneOutput("|cffC69B3ALichborne:|r |cffff4444Invite stopped.|r", 1, 0.85, 0)
            if LichborneAddStatus then LichborneAddStatus:SetText("|cffff4444Invite stopped.") end
        end
    end)
    stopInviteBtn:Hide()
    _G["LichborneStopInviteBtn"] = stopInviteBtn

    PBM.UpdateInviteButtons()

end
