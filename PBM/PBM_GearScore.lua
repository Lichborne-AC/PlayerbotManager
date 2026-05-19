-- ============================================================
--  LBT_GearScore.lua  |  GS math — no UI, no DB writes
-- ============================================================
PBM = PBM or {}

function PBM.CalculateGearScoreForItemLink(itemLink)
    if not itemLink then return 0, 0, nil end

    local _, _, itemRarity, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    local itemType = itemEquipLoc and PBM.GS_ITEM_TYPES[itemEquipLoc]
    if not itemType or not itemRarity or not itemLevel then return 0, itemLevel or 0, itemEquipLoc end

    local qualityScale = 1
    if itemRarity == 5 then
        qualityScale = 1.3
        itemRarity = 4
    elseif itemRarity == 1 or itemRarity == 0 then
        qualityScale = 0.005
        itemRarity = 2
    end

    if itemRarity == 7 then
        itemRarity = 3
        itemLevel = 187.05
    end

    if itemRarity < 2 or itemRarity > 4 then return 0, itemLevel, itemEquipLoc end

    local formulaSet = itemLevel > 120 and PBM.GS_FORMULA.A or PBM.GS_FORMULA.B
    local formula = formulaSet[itemRarity]
    if not formula then return 0, itemLevel, itemEquipLoc end

    local score = ((itemLevel - formula.A) / formula.B) * itemType.slotMod * PBM.GS_SCALE * qualityScale
    if score < 0 then score = 0 end

    return math.floor(score), itemLevel, itemEquipLoc
end

function PBM.CalculateUnitGearScore(unitToken)
    if not unitToken or not UnitExists(unitToken) then return 0 end

    local _, classToken = UnitClass(unitToken)
    local titanGripScale = 1
    local mainHandLink = GetInventoryItemLink(unitToken, 16)
    local offHandLink = GetInventoryItemLink(unitToken, 17)

    if mainHandLink and offHandLink then
        local _, _, _, _, _, _, _, _, mainEquipLoc = GetItemInfo(mainHandLink)
        local _, _, _, _, _, _, _, _, offEquipLoc = GetItemInfo(offHandLink)
        if mainEquipLoc == "INVTYPE_2HWEAPON" or offEquipLoc == "INVTYPE_2HWEAPON" then
            titanGripScale = 0.5
        end
    end

    local totalScore = 0

    if offHandLink then
        local offHandScore = select(1, PBM.CalculateGearScoreForItemLink(offHandLink))
        if classToken == "HUNTER" then offHandScore = offHandScore * 0.3164 end
        totalScore = totalScore + (offHandScore * titanGripScale)
    end

    for slot = 1, 18 do
        if slot ~= 4 and slot ~= 17 then
            local itemLink = GetInventoryItemLink(unitToken, slot)
            if itemLink then
                local itemScore = select(1, PBM.CalculateGearScoreForItemLink(itemLink))
                if classToken == "HUNTER" then
                    if slot == 16 then
                        itemScore = itemScore * 0.3164
                    elseif slot == 18 then
                        itemScore = itemScore * 5.3224
                    end
                end
                if slot == 16 then itemScore = itemScore * titanGripScale end
                totalScore = totalScore + itemScore
            end
        end
    end

    if totalScore <= 0 then return 0 end
    return math.floor(totalScore)
end

function PBM.GetItemQualityColor(link)
    if not link then return nil end
    local _, _, quality = GetItemInfo(link)
    if quality then return PBM.QUALITY_COLORS[quality] end
    return nil
end

function PBM.ApplyTierColor(gb, val, qualityColor)
    if qualityColor then
        gb:SetTextColor(qualityColor.r, qualityColor.g, qualityColor.b)
    else
        gb:SetTextColor(0.831, 0.686, 0.216)
    end
end
