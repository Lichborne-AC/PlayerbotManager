-- ============================================================
--  LBT_Needs.lua  |  Needs system — state, picker popup, cell builder
-- ============================================================
PBM = PBM or {}
PBM.State = PBM.State or {}

PBM.State.needsPicker = nil
PBM.State.needsPickerOwner = nil
PBM.State.needsCellFrames = {}
PBM.State.MAX_NEEDS_DISPLAY = PBM.MAX_NEEDS  -- set from LBT_Constants.lua

PBM.State.profPicker = nil
PBM.State.profPickerOwner = nil
PBM.State.profCellFrames = {}
PBM.State.profSelectSeq = 0

function PBM.GetNeeds(charName)
    if not charName or charName == "" then return {} end
    local k = charName:lower()
    if not LichborneTrackerDB.needs then LichborneTrackerDB.needs = {} end
    if not LichborneTrackerDB.needs[k] then LichborneTrackerDB.needs[k] = {} end
    return LichborneTrackerDB.needs[k]
end

function PBM.SetNeed(charName, slotKey, val)
    if not charName or charName == "" then return end
    if not LichborneTrackerDB.needs then LichborneTrackerDB.needs = {} end
    local k = charName:lower()
    if not LichborneTrackerDB.needs[k] then LichborneTrackerDB.needs[k] = {} end
    if val then
        local count = 0
        for _ in pairs(LichborneTrackerDB.needs[k]) do count = count + 1 end
        if count < PBM.MAX_NEEDS then
            LichborneTrackerDB.needs[k][slotKey] = true
        end
    else
        LichborneTrackerDB.needs[k][slotKey] = nil
    end
end

function PBM.HasNeeds(charName)
    if not charName or charName == "" then return false end
    if not LichborneTrackerDB.needs then return false end
    local n = LichborneTrackerDB.needs[charName:lower()]
    if not n then return false end
    for _ in pairs(n) do return true end
    return false
end

function PBM.RefreshNeedsCell(cf, charName)
    if not cf or not cf.icons then return end
    local needs = PBM.GetNeeds(charName)
    local active = {}
    for _, slot in ipairs(PBM.NEEDS_SLOTS) do
        if needs[slot.key] then active[#active+1] = slot end
    end
    local show = math.min(#active, PBM.State.MAX_NEEDS_DISPLAY)
    for idx = 1, show do
        local ic = cf.icons[idx]
        if ic then ic:SetTexture(active[idx].icon); ic:SetAlpha(1); ic:Show() end
    end
    for j = show+1, PBM.State.MAX_NEEDS_DISPLAY do
        if cf.icons[j] then cf.icons[j]:Hide() end
    end
end

function PBM.RefreshAllNeedsCells()
    for _, entry in ipairs(PBM.State.needsCellFrames) do
        if entry.frame and entry.getCharName then
            PBM.RefreshNeedsCell(entry.frame, entry.getCharName())
        end
    end
end

function PBM.ClosePicker()
    if PBM.State.needsPicker then PBM.State.needsPicker:Hide() end
    PBM.State.needsPickerOwner = nil
end

function PBM.BuildPickerIfNeeded()
    if PBM.State.needsPicker then return end
    local COLS, BSIZE, PAD = 5, 26, 4
    local ROWS = math.ceil(#PBM.NEEDS_SLOTS / COLS)
    local W = COLS*(BSIZE+PAD)+PAD
    local H = ROWS*(BSIZE+PAD)+PAD+20
    local pf = CreateFrame("Frame","LichborneNeedsPicker",UIParent)
    pf:SetFrameStrata("TOOLTIP"); pf:SetFrameLevel(200)
    pf:SetSize(W,H)
    pf:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    pf:SetBackdropColor(0.04,0.06,0.12,0.98); pf:SetBackdropBorderColor(0.78,0.61,0.23,1)
    local ttl = pf:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    ttl:SetPoint("TOPLEFT",pf,"TOPLEFT",6,-5); pf.title=ttl
    pf.slotBtns = {}
    for si, slot in ipairs(PBM.NEEDS_SLOTS) do
        local col = (si-1)%COLS
        local row = math.floor((si-1)/COLS)
        local btn = CreateFrame("Button",nil,pf)
        btn:SetSize(BSIZE,BSIZE)
        btn:SetPoint("TOPLEFT",pf,"TOPLEFT",PAD+col*(BSIZE+PAD),-20-PAD-row*(BSIZE+PAD))
        btn:SetFrameLevel(pf:GetFrameLevel()+1)
        local bg=btn:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(btn); bg:SetTexture(0.08,0.10,0.18,1)
        local tex=btn:CreateTexture(nil,"ARTWORK")
        tex:SetPoint("CENTER",btn,"CENTER",0,0); tex:SetSize(BSIZE-4,BSIZE-4); tex:SetTexture(slot.icon)
        btn.tex=tex
        local hi=btn:CreateTexture(nil,"OVERLAY")
        hi:SetAllPoints(btn); hi:SetTexture(0.3,0.8,0.3,0.35); hi:Hide(); btn.hi=hi
        btn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=6,insets={left=1,right=1,top=1,bottom=1}})
        btn:SetBackdropColor(0.08,0.10,0.18,1); btn:SetBackdropBorderColor(0.25,0.35,0.55,0.8)
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        btn.slotKey=slot.key; btn.slotLabel=slot.label
        btn:SetScript("OnEnter",function()
            if pf.title then
                local owned = PBM.State.needsPickerOwner and PBM.GetNeeds(PBM.State.needsPickerOwner)[slot.key]
                local hint = owned and "|cffff6666  (right-click to remove)|r" or "|cff66ff66  click to mark|r"
                pf.title:SetText("|cffC69B3A"..slot.label.."|r"..hint)
            end
        end)
        btn:SetScript("OnLeave",function()
            if pf.title and PBM.State.needsPickerOwner then
                pf.title:SetText("|cffC69B3ANeeds: |r|cffffff00"..PBM.State.needsPickerOwner.."|r")
            end
        end)
        btn:SetScript("OnClick",function(_, mouseButton)
            if not PBM.State.needsPickerOwner or PBM.State.needsPickerOwner=="" then return end
            local k=slot.key
            local cur=PBM.GetNeeds(PBM.State.needsPickerOwner)[k]
            if mouseButton=="RightButton" then PBM.SetNeed(PBM.State.needsPickerOwner,k,false)
            else PBM.SetNeed(PBM.State.needsPickerOwner,k,not cur) end
            local needs2=PBM.GetNeeds(PBM.State.needsPickerOwner)
            local count2=0; for _ in pairs(needs2) do count2=count2+1 end
            for _,sb in ipairs(pf.slotBtns) do
                if needs2[sb.slotKey] then
                    sb.hi:Show(); sb:SetBackdropBorderColor(0.3,0.8,0.3,0.9); sb.tex:SetAlpha(1)
                elseif count2 >= PBM.MAX_NEEDS then
                    sb.hi:Hide(); sb:SetBackdropBorderColor(0.15,0.15,0.15,0.5); sb.tex:SetAlpha(0.35)
                else
                    sb.hi:Hide(); sb:SetBackdropBorderColor(0.25,0.35,0.55,0.8); sb.tex:SetAlpha(1)
                end
            end
            PBM.RefreshAllNeedsCells()
        end)
        btn:RegisterForClicks("LeftButtonUp","RightButtonUp")
        pf.slotBtns[si]=btn
    end
    pf.closeTimer = 0
    pf:SetScript("OnUpdate",function(_, elapsed)
        if not pf:IsShown() then return end
        if not MouseIsOver(pf) then
            pf.closeTimer = (pf.closeTimer or 0) + elapsed
            if pf.closeTimer > 0.3 then
                PBM.ClosePicker()
            end
        else
            pf.closeTimer = 0
        end
    end)
    pf:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" then PBM.ClosePicker() end
    end)
    pf:EnableKeyboard(true)
    PBM.State.needsPicker=pf
end

function PBM.OpenNeedsPicker(anchorFrame, charName)
    if not charName or charName=="" then return end
    PBM.BuildPickerIfNeeded()
    PBM.State.needsPickerOwner=charName
    PBM.State.needsPicker.title:SetText("|cffC69B3ANeeds: |r|cffffff00"..charName.."|r")
    local needs3=PBM.GetNeeds(charName)
    local count3=0; for _ in pairs(needs3) do count3=count3+1 end
    for _,sb in ipairs(PBM.State.needsPicker.slotBtns) do
        if needs3[sb.slotKey] then
            sb.hi:Show(); sb:SetBackdropBorderColor(0.3,0.8,0.3,0.9); sb.tex:SetAlpha(1)
        elseif count3 >= PBM.MAX_NEEDS then
            sb.hi:Hide(); sb:SetBackdropBorderColor(0.15,0.15,0.15,0.5); sb.tex:SetAlpha(0.35)
        else
            sb.hi:Hide(); sb:SetBackdropBorderColor(0.25,0.35,0.55,0.8); sb.tex:SetAlpha(1)
        end
    end
    PBM.State.needsPicker:ClearAllPoints()
    PBM.State.needsPicker:SetPoint("TOPLEFT",anchorFrame,"BOTTOMLEFT",0,-2)
    PBM.State.needsPicker.closeTimer = 0
    PBM.State.needsPicker:Show(); PBM.State.needsPicker:Raise()
end

function PBM.MakeNeedsCell(parent, xOff, rowH, getCharName, hovTex, overrideW)
    local cellW = overrideW or 80
    local cf = CreateFrame("Button",nil,parent)
    cf:SetPoint("LEFT",parent,"LEFT",xOff,0)
    cf:SetSize(cellW,rowH-2)
    cf:SetFrameLevel(parent:GetFrameLevel()+4)
    cf:RegisterForClicks("LeftButtonUp","RightButtonUp")
    cf:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
    cf:SetBackdropColor(0.04,0.06,0.12,0.9); cf:SetBackdropBorderColor(0.15,0.22,0.38,0.6)
    -- No SetHighlightTexture - border changes on hover instead
    cf.icons={}
    for si=1,PBM.State.MAX_NEEDS_DISPLAY do
        local ic=cf:CreateTexture(nil,"ARTWORK")
        ic:SetSize(PBM.NEEDS_ICON_SIZE,PBM.NEEDS_ICON_SIZE)
        ic:SetPoint("LEFT",cf,"LEFT",2+(si-1)*(PBM.NEEDS_ICON_SIZE+2),0)
        ic:Hide(); cf.icons[si]=ic
    end
    cf:SetScript("OnClick",function(_, mouseButton)
        local cname=getCharName()
        if not cname or cname=="" then return end
        if mouseButton=="RightButton" then
            if LichborneTrackerDB.needs then LichborneTrackerDB.needs[cname:lower()]={} end
            PBM.RefreshAllNeedsCells(); PBM.ClosePicker(); return
        end
        if PBM.State.needsPicker and PBM.State.needsPicker:IsShown() and PBM.State.needsPickerOwner==cname then
            PBM.ClosePicker()
        else
            PBM.ClosePicker(); PBM.OpenNeedsPicker(cf,cname)
        end
    end)
    cf:SetScript("OnEnter",function()
        if hovTex then hovTex:SetTexture(0.78,0.61,0.23,0.12) end
        cf:SetBackdropBorderColor(0.78,0.61,0.23,0.9)
        local cname=getCharName()
        if cname and cname~="" then
            GameTooltip:SetOwner(cf,"ANCHOR_RIGHT")
            GameTooltip:AddLine("|cffC69B3ANeeds:|r "..cname,1,1,1)
            local needs4=PBM.GetNeeds(cname)
            local any=false
            for _,slot in ipairs(PBM.NEEDS_SLOTS) do
                if needs4[slot.key] then GameTooltip:AddLine("  "..slot.label,1,0.6,0.2); any=true end
            end
            if not any then GameTooltip:AddLine("  Nothing marked",0.5,0.5,0.5) end
            GameTooltip:AddLine("|cff888888Click to edit  (max 2)  Right-click clears all|r",0.6,0.6,0.6)
            GameTooltip:Show()
        end
    end)
    cf:SetScript("OnLeave",function()
        if hovTex then hovTex:SetTexture(0,0,0,0) end
        cf:SetBackdropBorderColor(0.15,0.22,0.38,0.6)
        GameTooltip:Hide()
    end)
    PBM.State.needsCellFrames[#PBM.State.needsCellFrames+1]={frame=cf,getCharName=getCharName}
    return cf
end

-- ============================================================
--  Profession system  (parallel to needs, Druid-tab only for now)
-- ============================================================

function PBM.GetProfs(charName)
    if not charName or charName == "" then return {} end
    local k = charName:lower()
    if not LichborneTrackerDB.profs then LichborneTrackerDB.profs = {} end
    if not LichborneTrackerDB.profs[k] then LichborneTrackerDB.profs[k] = {} end
    return LichborneTrackerDB.profs[k]
end

function PBM.SetProf(charName, profKey, val)
    if not charName or charName == "" then return end
    if not LichborneTrackerDB.profs then LichborneTrackerDB.profs = {} end
    local k = charName:lower()
    if not LichborneTrackerDB.profs[k] then LichborneTrackerDB.profs[k] = {} end
    if val then
        local count = 0
        for _ in pairs(LichborneTrackerDB.profs[k]) do count = count + 1 end
        if count < PBM.MAX_PROFS then
            PBM.State.profSelectSeq = PBM.State.profSelectSeq + 1
            LichborneTrackerDB.profs[k][profKey] = PBM.State.profSelectSeq
        end
    else
        LichborneTrackerDB.profs[k][profKey] = nil
    end
end

function PBM.RefreshProfCell(cf, charName)
    if not cf or not cf.icons then return end
    local profs = PBM.GetProfs(charName)
    local active = {}
    for _, slot in ipairs(PBM.PROF_SLOTS) do
        local seq = profs[slot.key]
        if seq then active[#active+1] = { icon=slot.icon, seq=seq } end
    end
    table.sort(active, function(a, b) return a.seq < b.seq end)
    local show = math.min(#active, PBM.MAX_PROFS)
    for idx = 1, show do
        local ic = cf.icons[idx]
        if ic then ic:SetTexture(active[idx].icon); ic:SetAlpha(1); ic:Show() end
    end
    for j = show+1, PBM.MAX_PROFS do
        if cf.icons[j] then cf.icons[j]:Hide() end
    end
end

function PBM.RefreshAllProfCells()
    for _, entry in ipairs(PBM.State.profCellFrames) do
        if entry.frame and entry.getCharName then
            PBM.RefreshProfCell(entry.frame, entry.getCharName())
        end
    end
end

function PBM.CloseProfPicker()
    if PBM.State.profPicker then PBM.State.profPicker:Hide() end
    PBM.State.profPickerOwner = nil
end

function PBM.BuildProfPickerIfNeeded()
    if PBM.State.profPicker then return end
    local COLS, BSIZE, PAD = 7, 26, 4
    local ROWS = math.ceil(#PBM.PROF_SLOTS / COLS)
    local W = COLS*(BSIZE+PAD)+PAD
    local H = ROWS*(BSIZE+PAD)+PAD+20
    local pf = CreateFrame("Frame","LichborneProfPicker",UIParent)
    pf:SetFrameStrata("TOOLTIP"); pf:SetFrameLevel(200)
    pf:SetSize(W,H)
    pf:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    pf:SetBackdropColor(0.04,0.06,0.12,0.98); pf:SetBackdropBorderColor(0.78,0.61,0.23,1)
    local ttl = pf:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    ttl:SetPoint("TOPLEFT",pf,"TOPLEFT",6,-5); pf.title=ttl
    pf.slotBtns = {}
    for si, slot in ipairs(PBM.PROF_SLOTS) do
        local col = (si-1)%COLS
        local row = math.floor((si-1)/COLS)
        local btn = CreateFrame("Button",nil,pf)
        btn:SetSize(BSIZE,BSIZE)
        btn:SetPoint("TOPLEFT",pf,"TOPLEFT",PAD+col*(BSIZE+PAD),-20-PAD-row*(BSIZE+PAD))
        btn:SetFrameLevel(pf:GetFrameLevel()+1)
        local bg=btn:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(btn); bg:SetTexture(0.08,0.10,0.18,1)
        local tex=btn:CreateTexture(nil,"ARTWORK")
        tex:SetPoint("CENTER",btn,"CENTER",0,0); tex:SetSize(BSIZE-4,BSIZE-4); tex:SetTexture(slot.icon)
        btn.tex=tex
        local hi=btn:CreateTexture(nil,"OVERLAY")
        hi:SetAllPoints(btn); hi:SetTexture(0.3,0.8,0.3,0.35); hi:Hide(); btn.hi=hi
        btn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=6,insets={left=1,right=1,top=1,bottom=1}})
        btn:SetBackdropColor(0.08,0.10,0.18,1); btn:SetBackdropBorderColor(0.25,0.35,0.55,0.8)
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        btn.slotKey=slot.key; btn.slotLabel=slot.label
        btn:SetScript("OnEnter",function()
            if pf.title then
                local owned = PBM.State.profPickerOwner and PBM.GetProfs(PBM.State.profPickerOwner)[slot.key]
                local hint = owned and "|cffff6666  (right-click to remove)|r" or "|cff66ff66  click to mark|r"
                pf.title:SetText("|cffC69B3A"..slot.label.."|r"..hint)
            end
        end)
        btn:SetScript("OnLeave",function()
            if pf.title and PBM.State.profPickerOwner then
                pf.title:SetText("|cffC69B3AProfs: |r|cffffff00"..PBM.State.profPickerOwner.."|r")
            end
        end)
        btn:SetScript("OnClick",function(_, mouseButton)
            if not PBM.State.profPickerOwner or PBM.State.profPickerOwner=="" then return end
            local k=slot.key
            local cur=PBM.GetProfs(PBM.State.profPickerOwner)[k]
            if mouseButton=="RightButton" then PBM.SetProf(PBM.State.profPickerOwner,k,false)
            else PBM.SetProf(PBM.State.profPickerOwner,k,not cur) end
            local profs2=PBM.GetProfs(PBM.State.profPickerOwner)
            local count2=0; for _ in pairs(profs2) do count2=count2+1 end
            for _,sb in ipairs(pf.slotBtns) do
                if profs2[sb.slotKey] then
                    sb.hi:Show(); sb:SetBackdropBorderColor(0.3,0.8,0.3,0.9); sb.tex:SetAlpha(1)
                elseif count2 >= PBM.MAX_PROFS then
                    sb.hi:Hide(); sb:SetBackdropBorderColor(0.15,0.15,0.15,0.5); sb.tex:SetAlpha(0.35)
                else
                    sb.hi:Hide(); sb:SetBackdropBorderColor(0.25,0.35,0.55,0.8); sb.tex:SetAlpha(1)
                end
            end
            PBM.RefreshAllProfCells()
        end)
        btn:RegisterForClicks("LeftButtonUp","RightButtonUp")
        pf.slotBtns[si]=btn
    end
    pf.closeTimer = 0
    pf:SetScript("OnUpdate",function(_, elapsed)
        if not pf:IsShown() then return end
        if not MouseIsOver(pf) then
            pf.closeTimer = (pf.closeTimer or 0) + elapsed
            if pf.closeTimer > 0.3 then
                PBM.CloseProfPicker()
            end
        else
            pf.closeTimer = 0
        end
    end)
    pf:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" then PBM.CloseProfPicker() end
    end)
    pf:EnableKeyboard(true)
    PBM.State.profPicker=pf
end

function PBM.OpenProfPicker(anchorFrame, charName)
    if not charName or charName=="" then return end
    PBM.BuildProfPickerIfNeeded()
    PBM.State.profPickerOwner=charName
    PBM.State.profPicker.title:SetText("|cffC69B3AProfs: |r|cffffff00"..charName.."|r")
    local profs3=PBM.GetProfs(charName)
    local count3=0; for _ in pairs(profs3) do count3=count3+1 end
    for _,sb in ipairs(PBM.State.profPicker.slotBtns) do
        if profs3[sb.slotKey] then
            sb.hi:Show(); sb:SetBackdropBorderColor(0.3,0.8,0.3,0.9); sb.tex:SetAlpha(1)
        elseif count3 >= PBM.MAX_PROFS then
            sb.hi:Hide(); sb:SetBackdropBorderColor(0.15,0.15,0.15,0.5); sb.tex:SetAlpha(0.35)
        else
            sb.hi:Hide(); sb:SetBackdropBorderColor(0.25,0.35,0.55,0.8); sb.tex:SetAlpha(1)
        end
    end
    PBM.State.profPicker:ClearAllPoints()
    PBM.State.profPicker:SetPoint("TOPLEFT",anchorFrame,"BOTTOMLEFT",0,-2)
    PBM.State.profPicker.closeTimer = 0
    PBM.State.profPicker:Show(); PBM.State.profPicker:Raise()
end

function PBM.MakeProfCell(parent, xOff, rowH, getCharName, hovTex, overrideW)
    local cellW = overrideW or 80
    local cf = CreateFrame("Button",nil,parent)
    cf:SetPoint("LEFT",parent,"LEFT",xOff,0)
    cf:SetSize(cellW,rowH-2)
    cf:SetFrameLevel(parent:GetFrameLevel()+4)
    cf:RegisterForClicks("LeftButtonUp","RightButtonUp")
    cf:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
    cf:SetBackdropColor(0.04,0.06,0.12,0.9); cf:SetBackdropBorderColor(0.15,0.22,0.38,0.6)
    cf.icons={}
    for si=1,PBM.MAX_PROFS do
        local ic=cf:CreateTexture(nil,"ARTWORK")
        ic:SetSize(PBM.NEEDS_ICON_SIZE,PBM.NEEDS_ICON_SIZE)
        ic:SetPoint("LEFT",cf,"LEFT",2+(si-1)*(PBM.NEEDS_ICON_SIZE+2),0)
        ic:Hide(); cf.icons[si]=ic
    end
    cf:SetScript("OnClick",function(_, mouseButton)
        local cname=getCharName()
        if not cname or cname=="" then return end
        if mouseButton=="RightButton" then
            if LichborneTrackerDB.profs then LichborneTrackerDB.profs[cname:lower()]={} end
            PBM.RefreshAllProfCells(); PBM.CloseProfPicker(); return
        end
        if PBM.State.profPicker and PBM.State.profPicker:IsShown() and PBM.State.profPickerOwner==cname then
            PBM.CloseProfPicker()
        else
            PBM.CloseProfPicker(); PBM.OpenProfPicker(cf,cname)
        end
    end)
    cf:SetScript("OnEnter",function()
        if hovTex then hovTex:SetTexture(0.78,0.61,0.23,0.12) end
        cf:SetBackdropBorderColor(0.78,0.61,0.23,0.9)
        local cname=getCharName()
        if cname and cname~="" then
            GameTooltip:SetOwner(cf,"ANCHOR_RIGHT")
            GameTooltip:AddLine("|cffC69B3AProfs:|r "..cname,1,1,1)
            local profs4=PBM.GetProfs(cname)
            local any=false
            for _,slot in ipairs(PBM.PROF_SLOTS) do
                if profs4[slot.key] then GameTooltip:AddLine("  "..slot.label,1,0.6,0.2); any=true end
            end
            if not any then GameTooltip:AddLine("  Nothing marked",0.5,0.5,0.5) end
            GameTooltip:AddLine("|cff888888Click to edit  (max 2)  Right-click clears all|r",0.6,0.6,0.6)
            GameTooltip:Show()
        end
    end)
    cf:SetScript("OnLeave",function()
        if hovTex then hovTex:SetTexture(0,0,0,0) end
        cf:SetBackdropBorderColor(0.15,0.22,0.38,0.6)
        GameTooltip:Hide()
    end)
    PBM.State.profCellFrames[#PBM.State.profCellFrames+1]={frame=cf,getCharName=getCharName}
    return cf
end
