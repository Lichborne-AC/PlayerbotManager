PBM = PBM or {}

-- Talent spec templates for the Set Talents menu
local PALADIN_TALENT_SPECS = {
    { label="Holy |cffffcc00PvE|r",        spec="holy pve", wowSpec="Holy Pala",    icon="Interface\\Icons\\Spell_Holy_HolyBolt"                  },
    { label="Protection |cffffcc00PvE|r",  spec="prot pve", wowSpec="Protection",   icon="Interface\\Icons\\Ability_Paladin_ShieldoftheTemplar"   },
    { label="Retribution |cffffcc00PvE|r", spec="ret pve",  wowSpec="Retribution",  icon="Interface\\Icons\\Spell_Holy_AuraofLight"               },
    { label="Holy |cffff4444PvP|r",        spec="holy pvp", wowSpec="Holy Pala",    icon="Interface\\Icons\\Spell_Holy_HolyBolt"                  },
    { label="Protection |cffff4444PvP|r",  spec="prot pvp", wowSpec="Protection",   icon="Interface\\Icons\\Ability_Paladin_ShieldoftheTemplar"   },
    { label="Retribution |cffff4444PvP|r", spec="ret pvp",  wowSpec="Retribution",  icon="Interface\\Icons\\Spell_Holy_AuraofLight"               },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Paladin class-specific overlay panel
-- ─────────────────────────────────────────────────────────────────────────────
local LichbornePaladinMenu
local LichbornePaladinCatcher

local PALADIN_LEFT_EXT = 5
local PALADIN_OVL_W = (PBM.GEAR_OFF + PBM.GEAR_SLOTS * PBM.COL_GEAR_W) - PBM.GS_OFF + PALADIN_LEFT_EXT
local PALADIN_OVL_H = PBM.MAX_ROWS * PBM.ROW_HEIGHT + 12

local EXT_ICON_SIZE = 26

local function HideAllPaladin()
    PBM.HideCharSheet(LichbornePaladinMenu, LichbornePaladinCatcher)
end

function PBM.ClosePaladinMenu()
    HideAllPaladin()
end

function PBM.OpenPaladinMenu(row)
    if not LichbornePaladinMenu then
        LichbornePaladinMenu, LichbornePaladinCatcher = PBM.CreateCharSheet({
            menuName    = "LichbornePaladinMenu",
            catcherName = "LichbornePaladinCatcher",
            className   = "Paladin",
            classHex    = "F58CBA",
            leftExt     = PALADIN_LEFT_EXT,
            overlayW    = PALADIN_OVL_W,
            overlayH    = PALADIN_OVL_H,
            talentSpecs = PALADIN_TALENT_SPECS,
            hideCallback = HideAllPaladin,
        })

        -- ── Talent tree helpers ─────────────────────────────────────
        local SPEC_BOX_BD = {
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = {left=2, right=2, top=2, bottom=2},
        }
        local function MakeSpecBox(parent, x, y, w, label, icon)
            local box = CreateFrame("Frame", nil, parent)
            box:SetSize(w, 18)
            box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
            box:SetBackdrop(SPEC_BOX_BD)
            box:SetBackdropColor(0.08, 0.10, 0.28, 0.95)
            box:SetBackdropBorderColor(0.78, 0.61, 0.23, 0.9)
            if icon then
                local ico = box:CreateTexture(nil, "ARTWORK")
                ico:SetSize(14, 14); ico:SetPoint("LEFT", box, "LEFT", 2, 0)
                ico:SetTexture(icon)
            end
            local lbl = box:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            lbl:SetTextColor(0.78, 0.61, 0.23, 1); lbl:SetText(label)
            lbl:SetPoint("LEFT", box, "LEFT", icon and 18 or 4, 0)
            lbl:SetPoint("RIGHT", box, "RIGHT", -2, 0); lbl:SetJustifyH("CENTER")
            return box
        end
        local function MakeTreeBtn(bx, by, tex)
            local btn = CreateFrame("Button", nil, LichbornePaladinMenu)
            btn:SetSize(EXT_ICON_SIZE, EXT_ICON_SIZE)
            btn:SetPoint("TOPLEFT", LichbornePaladinMenu, "TOPLEFT", bx, by)
            local t = btn:CreateTexture(nil, "ARTWORK")
            t:SetAllPoints(); t:SetTexture(tex)
            btn.icon = t
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            btn.state = false; t:SetDesaturated(true)
            return btn
        end

        -- ── Tree layout constants ────────────────────────────────────
        local BTN_GAP  = 4
        local COL_W    = 3 * EXT_ICON_SIZE + 2 * BTN_GAP   -- 86px (3-btn wide)
        local COL_GAP  = 8
        local SPEC_W   = 3 * COL_W + 2 * COL_GAP            -- 274px (3 spec cols)
        -- Full row: 3 specs + gap + CO + gap + NC
        local TREE_Y   = -(PBM.ROW_HEIGHT + 68)

        -- Protection centred on the overlay midpoint; Holy/Retribution derive from it
        local col2X = math.floor(PALADIN_OVL_W / 2) - math.floor(COL_W / 2)
        local col1X = col2X - COL_W - COL_GAP
        local col3X = col2X + COL_W + COL_GAP
        local TREE_X = col1X   -- left edge of Holy; sub-rows centre within SPEC_W from here

        -- CO/NC: right of Retribution
        local coX = col3X + COL_W + COL_GAP
        local ncX = coX + EXT_ICON_SIZE + BTN_GAP

        local specBoxY  = TREE_Y - 16
        local specIconY = specBoxY - 18 - 4

        -- Single btn centered in each 86px spec column
        local singleOff = math.floor((COL_W - EXT_ICON_SIZE) / 2)  -- 30

        -- Heal DPS + Off-Heal: both centered as a pair across full SPEC_W
        local dohW          = 2 * EXT_ICON_SIZE + BTN_GAP               -- 56px
        local dohTotalW     = dohW + BTN_GAP + dohW                      -- 116px
        local healerDpsHdrX = TREE_X + math.floor((SPEC_W - dohTotalW) / 2)
        local offHealHdrX   = healerDpsHdrX + dohW + BTN_GAP
        local dohHdrY       = specIconY - EXT_ICON_SIZE - 15
        local dohIconY      = dohHdrY - 18 - 4
        local healerDpsBtnX = healerDpsHdrX + math.floor((dohW - EXT_ICON_SIZE) / 2)
        local offHealBtnX   = offHealHdrX   + math.floor((dohW - EXT_ICON_SIZE) / 2)

        local blessW     = 4 * EXT_ICON_SIZE + 3 * BTN_GAP          -- 116px
        local blessHdrX  = TREE_X + math.floor((SPEC_W - blessW) / 2)
        local blessHdrY  = dohIconY - EXT_ICON_SIZE - 15
        local blessIconY = blessHdrY - 18 - 4

        local assistW    = 3 * EXT_ICON_SIZE + 2 * BTN_GAP          -- 86px
        local assistHdrX = TREE_X + math.floor((SPEC_W - assistW) / 2)
        local assistHdrY = blessIconY - EXT_ICON_SIZE - 15
        local assistIconY = assistHdrY - 18 - 4

        -- ── Row 1: Spec headers + CO/NC headers (same Y) ──────────
        MakeSpecBox(LichbornePaladinMenu, col1X, specBoxY, COL_W, "Holy",        "Interface\\Icons\\Spell_Holy_HolyBolt")
        MakeSpecBox(LichbornePaladinMenu, col2X, specBoxY, COL_W, "Protection",  "Interface\\Icons\\Ability_Paladin_ShieldoftheTemplar")
        MakeSpecBox(LichbornePaladinMenu, col3X, specBoxY, COL_W, "Retribution", "Interface\\Icons\\Spell_Holy_AuraofLight")
        local aurasHdrW  = EXT_ICON_SIZE + BTN_GAP + EXT_ICON_SIZE  -- 56px (CO + gap + NC)
        local coNcHdrY   = specBoxY - 18 - 3   -- CO/NC headers one step below Auras
        local coNcIconY  = coNcHdrY - 18 - 4   -- first aura button below CO/NC headers
        MakeSpecBox(LichbornePaladinMenu, coX, specBoxY,  aurasHdrW, "Auras")
        MakeSpecBox(LichbornePaladinMenu, coX, coNcHdrY, EXT_ICON_SIZE, "CO")
        MakeSpecBox(LichbornePaladinMenu, ncX, coNcHdrY, EXT_ICON_SIZE, "NC")

        local tHeal = MakeTreeBtn(col1X + singleOff, specIconY, "Interface\\Icons\\Spell_Holy_HolyBolt")
        local tTank = MakeTreeBtn(col2X + singleOff, specIconY, "Interface\\Icons\\Ability_Paladin_ShieldoftheTemplar")
        local tDps  = MakeTreeBtn(col3X + singleOff, specIconY, "Interface\\Icons\\Spell_Holy_AuraofLight")

        -- ── CO/NC Aura columns ──────────────────────────────────────
        local function coRow(i) return coNcIconY - (i - 1) * (EXT_ICON_SIZE + 3) end
        local tCoSpeed  = MakeTreeBtn(coX, coRow(1), "Interface\\Icons\\Spell_Holy_CrusaderAura")
        local tCoArmor  = MakeTreeBtn(coX, coRow(2), "Interface\\Icons\\Spell_Holy_DevotionAura")
        local tCoCast   = MakeTreeBtn(coX, coRow(3), "Interface\\Icons\\Spell_Holy_MindSooth")
        local tCoBaoe   = MakeTreeBtn(coX, coRow(4), "Interface\\Icons\\Spell_Holy_AuraOfLight")
        local tCoFire   = MakeTreeBtn(coX, coRow(5), "Interface\\Icons\\Spell_Fire_SealOfFire")
        local tCoFrost  = MakeTreeBtn(coX, coRow(6), "Interface\\Icons\\Spell_Frost_WizardMark")
        local tCoShadow = MakeTreeBtn(coX, coRow(7), "Interface\\Icons\\Spell_Shadow_SealOfKings")

        local tNcSpeed  = MakeTreeBtn(ncX, coRow(1), "Interface\\Icons\\Spell_Holy_CrusaderAura")
        local tNcArmor  = MakeTreeBtn(ncX, coRow(2), "Interface\\Icons\\Spell_Holy_DevotionAura")
        local tNcCast   = MakeTreeBtn(ncX, coRow(3), "Interface\\Icons\\Spell_Holy_MindSooth")
        local tNcBaoe   = MakeTreeBtn(ncX, coRow(4), "Interface\\Icons\\Spell_Holy_AuraOfLight")
        local tNcFire   = MakeTreeBtn(ncX, coRow(5), "Interface\\Icons\\Spell_Fire_SealOfFire")
        local tNcFrost  = MakeTreeBtn(ncX, coRow(6), "Interface\\Icons\\Spell_Frost_WizardMark")
        local tNcShadow = MakeTreeBtn(ncX, coRow(7), "Interface\\Icons\\Spell_Shadow_SealOfKings")

        -- ── DPS/Off-Healer section (split headers) ───────────────────
        MakeSpecBox(LichbornePaladinMenu, healerDpsHdrX, dohHdrY, dohW, "Heal DPS")
        MakeSpecBox(LichbornePaladinMenu, offHealHdrX,   dohHdrY, dohW, "Off-Heal")

        local tHealerDps = MakeTreeBtn(healerDpsBtnX, dohIconY, "Interface\\Icons\\INV_Alchemy_Elixir_02")
        local tOffHeal   = MakeTreeBtn(offHealBtnX,   dohIconY, "Interface\\Icons\\Spell_Holy_FlashHeal")

        -- ── Blessings section ──────────────────────────────────────
        MakeSpecBox(LichbornePaladinMenu, blessHdrX, blessHdrY, blessW, "Blessings")

        local tBstats  = MakeTreeBtn(blessHdrX,                               blessIconY, "Interface\\Icons\\Spell_Magic_MageArmor")
        local tBhealth = MakeTreeBtn(blessHdrX +   EXT_ICON_SIZE + BTN_GAP,   blessIconY, "Interface\\Icons\\Spell_Holy_HealingAura")
        local tBmana   = MakeTreeBtn(blessHdrX + 2*(EXT_ICON_SIZE + BTN_GAP), blessIconY, "Interface\\Icons\\Spell_Holy_SealOfWisdom")
        local tBdps    = MakeTreeBtn(blessHdrX + 3*(EXT_ICON_SIZE + BTN_GAP), blessIconY, "Interface\\Icons\\INV_Hammer_01")

        -- ── Assist section ─────────────────────────────────────────
        MakeSpecBox(LichbornePaladinMenu, assistHdrX, assistHdrY, assistW, "Assist")

        local tTankAssist = MakeTreeBtn(assistHdrX,                               assistIconY, "Interface\\Icons\\inv_shield_02")
        local tDpsAssist  = MakeTreeBtn(assistHdrX +   EXT_ICON_SIZE + BTN_GAP,   assistIconY, "Interface\\Icons\\Ability_Warrior_Challange")
        local tDpsAoe     = MakeTreeBtn(assistHdrX + 2*(EXT_ICON_SIZE + BTN_GAP), assistIconY, "Interface\\Icons\\Spell_Shadow_RainOfFire")

        -- ── Tree tooltips ─────────────────────────────────────────────
        local function TT(self, header, subtitle, ...)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetFrameLevel(LichbornePaladinMenu:GetFrameLevel() + 20)
            GameTooltip:SetText(header)
            if subtitle then GameTooltip:AddLine(subtitle, 1, 1, 1) end
            for i = 1, select("#", ...) do
                GameTooltip:AddLine((select(i, ...)), 1, 1, 1)
            end
            GameTooltip:Show()
        end
        local function TL() GameTooltip:Hide() end

        tHeal:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Heal|r |cff999999- |r|cffF58CBAheal|r |cffee4433CO|r",
            "|cffffcc00Holy healer|r")
        end); tHeal:SetScript("OnLeave", TL)

        tHealerDps:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Heal DPS|r |cff999999- |r|cffF58CBAhealer dps|r |cffee4433CO|r",
            "|cffffcc00Holy healer that DPS fills|r",
            "Allows the healer to deal damage when healing is not needed.")
        end); tHealerDps:SetScript("OnLeave", TL)

        tOffHeal:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Off-Heal|r |cff999999- |r|cffF58CBAoffheal|r |cffee4433CO|r",
            "|cffffcc00Retribution DPS with emergency heals|r",
            "Switches to |cffF58CBAFlash of Light|r when party members drop low.")
        end); tOffHeal:SetScript("OnLeave", TL)

        tTank:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Tank|r |cff999999- |r|cffF58CBAtank|r |cffee4433CO|r",
            "|cffffcc00Protection tank|r")
        end); tTank:SetScript("OnLeave", TL)

        tTankAssist:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Tank Assist|r |cff999999- |r|cffff8000tank assist|r |cffffcc00CO|r",
            "|cffffcc00Assists the main tank|r",
            "Focuses attacks on the tank's target.")
        end); tTankAssist:SetScript("OnLeave", TL)

        tDps:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Retribution|r |cff999999- |r|cffF58CBAdps|r |cffee4433CO|r",
            "|cffffcc00Retribution DPS|r")
        end); tDps:SetScript("OnLeave", TL)

        tDpsAssist:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00DPS Assist|r |cff999999- |r|cffff8000dps assist|r |cffffcc00CO|r",
            "|cffffcc00Assists the DPS group|r",
            "Focuses attacks on the DPS leader's target.")
        end); tDpsAssist:SetScript("OnLeave", TL)

        tDpsAoe:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00DPS AoE|r |cff999999- |r|cffff8000dps aoe|r |cffffcc00CO|r",
            "|cffffcc00Cross-role AoE mode|r")
        end); tDpsAoe:SetScript("OnLeave", TL)

        -- CO aura tooltips
        tCoSpeed:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Crusader Aura|r |cff999999- |r|cffffff00bspeed|r |cffff8000CO|r",
            "|cffffcc00Movement speed aura|r",
            "Increases mounted speed for all",
            "party members within 30 yards.")
        end); tCoSpeed:SetScript("OnLeave", TL)

        tCoArmor:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Devotion Aura|r |cff999999- |r|cffffff00barmor|r |cffff8000CO|r",
            "|cffffcc00Armor aura|r",
            "Increases |cffffcc00armor|r for all party",
            "members within 30 yards.")
        end); tCoArmor:SetScript("OnLeave", TL)

        tCoCast:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Concentration Aura|r |cff999999- |r|cffffff00bcast|r |cffff8000CO|r",
            "|cffffcc00Pushback resistance aura|r",
            "Reduces spell pushback by 35% for",
            "all party members within 30 yards.")
        end); tCoCast:SetScript("OnLeave", TL)

        tCoBaoe:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Retribution Aura|r |cff999999- |r|cffffff00baoe|r |cffff8000CO|r",
            "|cffffcc00Holy retaliation aura|r",
            "Deals |cffffcc00Holy|r damage to attackers.")
        end); tCoBaoe:SetScript("OnLeave", TL)

        tCoFire:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Fire Resistance Aura|r |cff999999- |r|cffffff00rfire|r |cffff8000CO|r",
            "|cffffcc00Fire resistance aura|r",
            "Increases |cffFF4444Fire resistance|r for all",
            "party members within 30 yards.")
        end); tCoFire:SetScript("OnLeave", TL)

        tCoFrost:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Frost Resistance Aura|r |cff999999- |r|cffffff00rfrost|r |cffff8000CO|r",
            "|cffffcc00Frost resistance aura|r",
            "Increases |cff3A8FC4Frost resistance|r for all",
            "party members within 30 yards.")
        end); tCoFrost:SetScript("OnLeave", TL)

        tCoShadow:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Shadow Resistance Aura|r |cff999999- |r|cffffff00rshadow|r |cffff8000CO|r",
            "|cffffcc00Shadow resistance aura|r",
            "Increases |cff9966CCShadow resistance|r for all",
            "party members within 30 yards.")
        end); tCoShadow:SetScript("OnLeave", TL)

        -- NC aura tooltips
        tNcSpeed:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Crusader Aura|r |cff999999- |r|cffffff00bspeed|r |cffff8000NC|r",
            "|cffffcc00Movement speed aura|r",
            "Increases mounted speed for all",
            "party members within 30 yards.")
        end); tNcSpeed:SetScript("OnLeave", TL)

        tNcArmor:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Devotion Aura|r |cff999999- |r|cffffff00barmor|r |cffff8000NC|r",
            "|cffffcc00Armor aura|r",
            "Increases |cffffcc00armor|r for all party",
            "members within 30 yards.")
        end); tNcArmor:SetScript("OnLeave", TL)

        tNcCast:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Concentration Aura|r |cff999999- |r|cffffff00bcast|r |cffff8000NC|r",
            "|cffffcc00Pushback resistance aura|r",
            "Reduces spell pushback by 35% for",
            "all party members within 30 yards.")
        end); tNcCast:SetScript("OnLeave", TL)

        tNcBaoe:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Retribution Aura|r |cff999999- |r|cffffff00baoe|r |cffff8000NC|r",
            "|cffffcc00Holy retaliation aura|r",
            "Deals |cffffcc00Holy|r damage to attackers.")
        end); tNcBaoe:SetScript("OnLeave", TL)

        tNcFire:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Fire Resistance Aura|r |cff999999- |r|cffffff00rfire|r |cffff8000NC|r",
            "|cffffcc00Fire resistance aura|r",
            "Increases |cffFF4444Fire resistance|r for all",
            "party members within 30 yards.")
        end); tNcFire:SetScript("OnLeave", TL)

        tNcFrost:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Frost Resistance Aura|r |cff999999- |r|cffffff00rfrost|r |cffff8000NC|r",
            "|cffffcc00Frost resistance aura|r",
            "Increases |cff3A8FC4Frost resistance|r for all",
            "party members within 30 yards.")
        end); tNcFrost:SetScript("OnLeave", TL)

        tNcShadow:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Shadow Resistance Aura|r |cff999999- |r|cffffff00rshadow|r |cffff8000NC|r",
            "|cffffcc00Shadow resistance aura|r",
            "Increases |cff9966CCShadow resistance|r for all",
            "party members within 30 yards.")
        end); tNcShadow:SetScript("OnLeave", TL)

        -- Blessing tooltips
        tBstats:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Kings|r |cff999999- |r|cffffff00bkings|r |cffff8000NC|r",
            "|cffffcc00Blessing of Kings|r",
            "Increases all |cffFF9900stats|r by 10% for all",
            "party members.")
        end); tBstats:SetScript("OnLeave", TL)

        tBhealth:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Sanctuary|r |cff999999- |r|cffffff00bsanc|r |cffff8000NC|r",
            "|cffffcc00Blessing of Sanctuary|r",
            "Damage reduction + mana on block.",
            "Applies to all party members.")
        end); tBhealth:SetScript("OnLeave", TL)

        tBmana:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Wisdom|r |cff999999- |r|cffffff00bwisdom|r |cffff8000NC|r",
            "|cffffcc00Blessing of Wisdom|r",
            "Increases |cff3A8FC4mana regeneration|r for all",
            "party members.")
        end); tBmana:SetScript("OnLeave", TL)

        tBdps:SetScript("OnEnter", function(s) TT(s,
            "|cffffcc00Might|r |cff999999- |r|cffffff00bmight|r |cffff8000NC|r",
            "|cffffcc00Blessing of Might|r",
            "Increases |cffFF9900attack power|r for all",
            "party members.")
        end); tBdps:SetScript("OnLeave", TL)

        -- ── Toggle wire block ────────────────────────────────────────
        do
            local function IconOn(btn)
                if not btn then return end
                btn.state = true
                if btn.icon then btn.icon:SetDesaturated(false) end
            end
            local function IconOff(btn)
                if not btn then return end
                btn.state = false
                if btn.icon then btn.icon:SetDesaturated(true) end
            end

            -- Start all icons desaturated (OFF)
            IconOff(tHeal); IconOff(tHealerDps); IconOff(tOffHeal)
            IconOff(tTank); IconOff(tTankAssist)
            IconOff(tDps); IconOff(tDpsAssist); IconOff(tDpsAoe)
            IconOff(tCoSpeed); IconOff(tCoArmor); IconOff(tCoCast); IconOff(tCoBaoe)
            IconOff(tCoFire); IconOff(tCoFrost); IconOff(tCoShadow)
            IconOff(tNcSpeed); IconOff(tNcArmor); IconOff(tNcCast); IconOff(tNcBaoe)
            IconOff(tNcFire); IconOff(tNcFrost); IconOff(tNcShadow)
            IconOff(tBstats); IconOff(tBhealth); IconOff(tBmana); IconOff(tBdps)

            local _baseReset = LichbornePaladinMenu.resetSharedIcons
            LichbornePaladinMenu.resetAllIcons = function()
                if _baseReset then _baseReset() end
                IconOff(tHeal); IconOff(tHealerDps); IconOff(tOffHeal)
                IconOff(tTank); IconOff(tTankAssist)
                IconOff(tDps); IconOff(tDpsAssist); IconOff(tDpsAoe)
                IconOff(tCoSpeed); IconOff(tCoArmor); IconOff(tCoCast); IconOff(tCoBaoe)
                IconOff(tCoFire); IconOff(tCoFrost); IconOff(tCoShadow)
                IconOff(tNcSpeed); IconOff(tNcArmor); IconOff(tNcCast); IconOff(tNcBaoe)
                IconOff(tNcFire); IconOff(tNcFrost); IconOff(tNcShadow)
                IconOff(tBstats); IconOff(tBhealth); IconOff(tBmana); IconOff(tBdps)
            end

            -- ── State restore from co?/nc? query ──────────────────────
            local _baseSU = LichbornePaladinMenu.onStrategyUpdate
            LichbornePaladinMenu.onStrategyUpdate = function(stratType, activeSet)
                if _baseSU then _baseSU(stratType, activeSet) end
                if not LichbornePaladinMenu._specUserSet then
                    if stratType == "co" then
                        if activeSet["heal"]        then IconOn(tHeal)       else IconOff(tHeal)       end
                        if activeSet["healer dps"]  then IconOn(tHealerDps)  else IconOff(tHealerDps)  end
                        if activeSet["offheal"]     then IconOn(tOffHeal)    else IconOff(tOffHeal)    end
                        if activeSet["tank"]        then IconOn(tTank)       else IconOff(tTank)       end
                        if activeSet["tank assist"] then IconOn(tTankAssist) else IconOff(tTankAssist) end
                        if activeSet["dps"]         then IconOn(tDps)        else IconOff(tDps)        end
                        if activeSet["dps assist"]  then IconOn(tDpsAssist)  else IconOff(tDpsAssist)  end
                        if activeSet["dps aoe"]     then IconOn(tDpsAoe)     else IconOff(tDpsAoe)     end
                        if activeSet["bspeed"]  then IconOn(tCoSpeed)  else IconOff(tCoSpeed)  end
                        if activeSet["barmor"]  then IconOn(tCoArmor)  else IconOff(tCoArmor)  end
                        if activeSet["bcast"]   then IconOn(tCoCast)   else IconOff(tCoCast)   end
                        if activeSet["baoe"]    then IconOn(tCoBaoe)   else IconOff(tCoBaoe)   end
                        if activeSet["rfire"]   then IconOn(tCoFire)   else IconOff(tCoFire)   end
                        if activeSet["rfrost"]  then IconOn(tCoFrost)  else IconOff(tCoFrost)  end
                        if activeSet["rshadow"] then IconOn(tCoShadow) else IconOff(tCoShadow) end
                    elseif stratType == "nc" then
                        if activeSet["bspeed"]  then IconOn(tNcSpeed)  else IconOff(tNcSpeed)  end
                        if activeSet["barmor"]  then IconOn(tNcArmor)  else IconOff(tNcArmor)  end
                        if activeSet["bcast"]   then IconOn(tNcCast)   else IconOff(tNcCast)   end
                        if activeSet["baoe"]    then IconOn(tNcBaoe)   else IconOff(tNcBaoe)   end
                        if activeSet["rfire"]   then IconOn(tNcFire)   else IconOff(tNcFire)   end
                        if activeSet["rfrost"]  then IconOn(tNcFrost)  else IconOff(tNcFrost)  end
                        if activeSet["rshadow"] then IconOn(tNcShadow) else IconOff(tNcShadow) end
                        if activeSet["bkings"]  then IconOn(tBstats)  else IconOff(tBstats)  end
                        if activeSet["bsanc"]   then IconOn(tBhealth) else IconOff(tBhealth) end
                        if activeSet["bwisdom"] then IconOn(tBmana)   else IconOff(tBmana)   end
                        if activeSet["bmight"]  then IconOn(tBdps)    else IconOff(tBdps)    end
                    end
                end
            end

            -- ── Tree button click handlers ────────────────────────────

            -- HEAL tree (exclusive with Tank, Dps, OffHeal)
            tHeal:SetScript("OnClick", function()
                local bot = LichbornePaladinMenu.botName or ""
                LichbornePaladinMenu._specUserSet = true
                if tHeal.state then
                    PBM.SendToBot("co -heal,?", bot); IconOff(tHeal)
                else
                    PBM.SendToBot("co +heal,?", bot); IconOn(tHeal)
                    IconOff(tTank); IconOff(tDps); IconOff(tOffHeal)
                end
            end)

            -- HEALER DPS tree (independent)
            tHealerDps:SetScript("OnClick", function()
                local bot = LichbornePaladinMenu.botName or ""
                LichbornePaladinMenu._specUserSet = true
                if tHealerDps.state then
                    PBM.SendToBot("co -healer dps,?", bot); IconOff(tHealerDps)
                else
                    PBM.SendToBot("co +healer dps,?", bot); IconOn(tHealerDps)
                end
            end)

            -- OFF-HEAL tree (exclusive with Heal, Dps)
            tOffHeal:SetScript("OnClick", function()
                local bot = LichbornePaladinMenu.botName or ""
                LichbornePaladinMenu._specUserSet = true
                if tOffHeal.state then
                    PBM.SendToBot("co -offheal,?", bot); IconOff(tOffHeal)
                else
                    PBM.SendToBot("co +offheal,?", bot); IconOn(tOffHeal)
                    IconOff(tHeal); IconOff(tTank); IconOff(tDps)
                end
            end)

            -- TANK tree (exclusive with Heal, Dps)
            tTank:SetScript("OnClick", function()
                local bot = LichbornePaladinMenu.botName or ""
                LichbornePaladinMenu._specUserSet = true
                if tTank.state then
                    PBM.SendToBot("co -tank,?", bot); IconOff(tTank)
                else
                    PBM.SendToBot("co +tank,?", bot); IconOn(tTank)
                    IconOff(tHeal); IconOff(tDps); IconOff(tOffHeal)
                end
            end)

            -- TANK ASSIST tree (exclusive with DpsAssist, DpsAoe)
            tTankAssist:SetScript("OnClick", function()
                local bot = LichbornePaladinMenu.botName or ""
                LichbornePaladinMenu._specUserSet = true
                if tTankAssist.state then
                    PBM.SendToBot("co -tank assist,?", bot); IconOff(tTankAssist)
                else
                    PBM.SendToBot("co +tank assist,?", bot); IconOn(tTankAssist)
                    IconOff(tDpsAssist); IconOff(tDpsAoe)
                end
            end)

            -- DPS tree (exclusive with Heal, Tank)
            tDps:SetScript("OnClick", function()
                local bot = LichbornePaladinMenu.botName or ""
                LichbornePaladinMenu._specUserSet = true
                if tDps.state then
                    PBM.SendToBot("co -dps,?", bot); IconOff(tDps)
                else
                    PBM.SendToBot("co +dps,?", bot); IconOn(tDps)
                    IconOff(tHeal); IconOff(tTank); IconOff(tOffHeal)
                end
            end)

            -- DPS ASSIST tree (exclusive with TankAssist, DpsAoe)
            tDpsAssist:SetScript("OnClick", function()
                local bot = LichbornePaladinMenu.botName or ""
                LichbornePaladinMenu._specUserSet = true
                if tDpsAssist.state then
                    PBM.SendToBot("co -dps assist,?", bot); IconOff(tDpsAssist)
                else
                    PBM.SendToBot("co +dps assist,?", bot); IconOn(tDpsAssist)
                    IconOff(tTankAssist); IconOff(tDpsAoe)
                end
            end)

            -- DPS AOE tree (exclusive with TankAssist, DpsAssist)
            tDpsAoe:SetScript("OnClick", function()
                local bot = LichbornePaladinMenu.botName or ""
                LichbornePaladinMenu._specUserSet = true
                if tDpsAoe.state then
                    PBM.SendToBot("co -dps aoe,?", bot); IconOff(tDpsAoe)
                else
                    PBM.SendToBot("co +dps aoe,?", bot); IconOn(tDpsAoe)
                    IconOff(tTankAssist); IconOff(tDpsAssist)
                end
            end)

            -- CO aura tree (radio: one at a time)
            local coAuraTree = {
                { btn=tCoSpeed,  cmd="bspeed"  },
                { btn=tCoArmor,  cmd="barmor"  },
                { btn=tCoCast,   cmd="bcast"   },
                { btn=tCoBaoe,   cmd="baoe"    },
                { btn=tCoFire,   cmd="rfire"   },
                { btn=tCoFrost,  cmd="rfrost"  },
                { btn=tCoShadow, cmd="rshadow" },
            }
            for _, e in ipairs(coAuraTree) do
                local btn, cmd = e.btn, e.cmd
                btn:SetScript("OnClick", function()
                    local bot = LichbornePaladinMenu.botName or ""
                    LichbornePaladinMenu._specUserSet = true
                    if btn.state then
                        PBM.SendToBot("co -" .. cmd .. ",?", bot)
                        IconOff(btn)
                    else
                        PBM.SendToBot("co +" .. cmd .. ",?", bot)
                        IconOn(btn)
                        for _, o in ipairs(coAuraTree) do
                            if o.btn ~= btn then
                                if o.btn.state then PBM.SendToBot("co -" .. o.cmd .. ",?", bot) end
                                IconOff(o.btn)
                            end
                        end
                    end
                end)
            end

            -- NC aura tree (radio: one at a time)
            local ncAuraTree = {
                { btn=tNcSpeed,  cmd="bspeed"  },
                { btn=tNcArmor,  cmd="barmor"  },
                { btn=tNcCast,   cmd="bcast"   },
                { btn=tNcBaoe,   cmd="baoe"    },
                { btn=tNcFire,   cmd="rfire"   },
                { btn=tNcFrost,  cmd="rfrost"  },
                { btn=tNcShadow, cmd="rshadow" },
            }
            for _, e in ipairs(ncAuraTree) do
                local btn, cmd = e.btn, e.cmd
                btn:SetScript("OnClick", function()
                    local bot = LichbornePaladinMenu.botName or ""
                    LichbornePaladinMenu._specUserSet = true
                    if btn.state then
                        PBM.SendToBot("nc -" .. cmd .. ",?", bot)
                        IconOff(btn)
                    else
                        PBM.SendToBot("nc +" .. cmd .. ",?", bot)
                        IconOn(btn)
                        for _, o in ipairs(ncAuraTree) do
                            if o.btn ~= btn then
                                if o.btn.state then PBM.SendToBot("nc -" .. o.cmd .. ",?", bot) end
                                IconOff(o.btn)
                            end
                        end
                    end
                end)
            end

            -- Blessing tree (radio: one at a time)
            local blessTree = {
                { btn=tBstats,  cmd="bkings"  },
                { btn=tBhealth, cmd="bsanc"   },
                { btn=tBmana,   cmd="bwisdom" },
                { btn=tBdps,    cmd="bmight"  },
            }
            for _, e in ipairs(blessTree) do
                local btn, cmd = e.btn, e.cmd
                btn:SetScript("OnClick", function()
                    local bot = LichbornePaladinMenu.botName or ""
                    LichbornePaladinMenu._specUserSet = true
                    if btn.state then
                        PBM.SendToBot("nc -" .. cmd .. ",?", bot)
                        IconOff(btn)
                    else
                        PBM.SendToBot("nc +" .. cmd .. ",?", bot)
                        IconOn(btn)
                        for _, o in ipairs(blessTree) do
                            if o.btn ~= btn then IconOff(o.btn) end
                        end
                    end
                end)
            end
        end -- end toggle wire block
    end

    if LichbornePaladinMenu:IsShown() and LichbornePaladinMenu.sourceRow == row then
        HideAllPaladin(); return
    end
    PBM.ShowCharSheet(LichbornePaladinMenu, LichbornePaladinCatcher, row, PALADIN_LEFT_EXT)
end
