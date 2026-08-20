PBM = PBM or {}

-- ── Playerbots tab panel ───────────────────────────────────────
-- Called from PBM_TopTabs.lua:BuildBottomTabs as:
--   PBM.BuildPlayerbotsPanel(panel, ctx)
-- ctx fields used: PERI_R/G/B, ActionToGroup, ActionToTargetOrGroup

function PBM.BuildPlayerbotsPanel(pbPanel, ctx)
    local LT_PERI_R             = ctx.PERI_R
    local LT_PERI_G             = ctx.PERI_G
    local LT_PERI_B             = ctx.PERI_B
    local LT_GOLD_R             = ctx.GOLD_R
    local LT_GOLD_G             = ctx.GOLD_G
    local LT_GOLD_B             = ctx.GOLD_B
    local ActionToGroup         = ctx.ActionToGroup
    local ActionToTargetOrGroup = ctx.ActionToTargetOrGroup

    local pbfl       = pbPanel:GetFrameLevel()
    local PB_ICON_SZ = 32
    local PB_STEP    = 38
    local PB_ADDON   = "Interface\\AddOns\\PlayerBotManager\\Icons\\"
    local PB_ICON    = "Interface\\Icons\\"
    local PB_ROW_TOP = 52

    local function PBLabel(x, y, text)
        local fs = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", pbPanel, "TOPLEFT", x, -y)
        fs:SetText("|cffd4af37"..text.."|r")
    end

    local function PBDivider(x, y, w)
        local t = pbPanel:CreateTexture(nil, "ARTWORK")
        t:SetPoint("TOPLEFT", pbPanel, "TOPLEFT", x, -y)
        t:SetSize(w, 1)
        t:SetTexture(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B, 0.45)
    end

    local function PBIconBtn(x, y, iconPath, tipTitle, tipBody)
        local btn = CreateFrame("Button", nil, pbPanel)
        btn:SetSize(PB_ICON_SZ, PB_ICON_SZ)
        btn:SetPoint("TOPLEFT", pbPanel, "TOPLEFT", x, -y)
        btn:SetFrameLevel(pbfl + 2)
        local bdr = btn:CreateTexture(nil, "BACKGROUND")
        bdr:SetAllPoints()
        bdr:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        bdr:SetBlendMode("ADD"); bdr:SetAlpha(0.5)
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT",     btn, "TOPLEFT",     2, -2)
        tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
        tex:SetTexture(iconPath); btn.icon = tex
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        btn.state = false
        function btn:setOn()  self.icon:SetDesaturated(nil); self.state = true  end
        function btn:setOff() self.icon:SetDesaturated(1);   self.state = false end
        if tipTitle then
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(tipTitle, 0.78, 0.61, 0.23)
                if tipBody then GameTooltip:AddLine(tipBody, 1, 1, 1, true) end
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        return btn
    end

    local function PBToggle(btn, onFn, offFn)
        btn:setOff()
        btn:SetScript("OnClick", function(self)
            if self.state then offFn(); self:setOff() else onFn(); self:setOn() end
        end)
    end

    -- ── Column 1 – Add RndBot (x = 400) ───────────────────────
    PBLabel(400, PB_ROW_TOP, PBM_L["Add RndBot"])
    PBDivider(400, PB_ROW_TOP + 16, 190)

    local CLASS_DEFS = {
        { name=PBM_L["Death Knight"], cmd="dk",      hex="C41F3B", icon=PB_ADDON.."addclass_deathknight.blp" },
        { name=PBM_L["Druid"],        cmd="druid",   hex="FF7D0A", icon=PB_ADDON.."addclass_druid.blp"       },
        { name=PBM_L["Hunter"],       cmd="hunter",  hex="ABD473", icon=PB_ADDON.."addclass_hunter.blp"      },
        { name=PBM_L["Mage"],         cmd="mage",    hex="3FC7EB", icon=PB_ADDON.."addclass_mage.blp"        },
        { name=PBM_L["Paladin"],      cmd="paladin", hex="F58CBA", icon=PB_ADDON.."addclass_paladin.blp"     },
        { name=PBM_L["Priest"],       cmd="priest",  hex="FFFFFF", icon=PB_ADDON.."addclass_priest.blp"      },
        { name=PBM_L["Rogue"],        cmd="rogue",   hex="FFF569", icon=PB_ADDON.."addclass_rogue.blp"       },
        { name=PBM_L["Shaman"],       cmd="shaman",  hex="0070DE", icon=PB_ADDON.."addclass_shaman.blp"      },
        { name=PBM_L["Warlock"],      cmd="warlock", hex="8787ED", icon=PB_ADDON.."addclass_warlock.blp"     },
        { name=PBM_L["Warrior"],      cmd="warrior", hex="C79C3B", icon=PB_ADDON.."addclass_warrior.blp"     },
    }
    local cy = PB_ROW_TOP + 24
    for _, cd in ipairs(CLASS_DEFS) do
        local cb = PBIconBtn(400, cy, cd.icon, cd.name, string.format(PBM_L["Summon a random %s RndBot."], cd.name))
        local cap = cd.cmd
        cb:SetScript("OnClick", function() SendChatMessage(".playerbots bot addclass "..cap, "SAY") end)
        local cl = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cl:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        cl:SetText("|cff"..cd.hex..cd.name.."|r")
        cy = cy + PB_STEP
    end

    -- ── Column 2 – Bot Commands (x = 35) ──────────────────────
    local CMD_X1    = 35
    local CMD_DIV_W = 190
    local CMD_STEP  = 34

    PBLabel(CMD_X1, PB_ROW_TOP, PBM_L["Bot Commands"])
    PBDivider(CMD_X1, PB_ROW_TOP + 16, CMD_DIV_W)

    local function CMDEntry(x, y, cmd, desc)
        local fc = pbPanel:CreateFontString(nil, "OVERLAY")
        fc:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        fc:SetPoint("TOPLEFT", pbPanel, "TOPLEFT", x, -y)
        fc:SetWidth(255); fc:SetJustifyH("LEFT")
        fc:SetText("|cffC69B3A"..cmd.."|r")
        local fd = pbPanel:CreateFontString(nil, "OVERLAY")
        fd:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        fd:SetPoint("TOPLEFT", pbPanel, "TOPLEFT", x + 4, -(y + 13))
        fd:SetWidth(255); fd:SetJustifyH("LEFT")
        fd:SetText("|cffaaaaaa"..desc.."|r")
    end

    local function CMDSection(x, y, text)
        local fs = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", pbPanel, "TOPLEFT", x, -y)
        fs:SetText("|cffd4af37"..text.."|r")
        local t = pbPanel:CreateTexture(nil, "ARTWORK")
        t:SetPoint("TOPLEFT", pbPanel, "TOPLEFT", x, -(y + 16))
        t:SetSize(190, 1); t:SetTexture(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B, 0.45)
    end

    -- Bot management commands
    local ey1 = PB_ROW_TOP + 26
    local ALTBOT_CMDS = {
        { ".playerbots bot add <name>",        PBM_L["Login altbot(s)"]               },
        { ".playerbots bot addaccount <acct>", PBM_L["Login entire account"]          },
        { "maintenance",                       PBM_L["Learn spells, enchant, repair"] },
        { "autogear",                          PBM_L["Auto-equip best gear"]          },
    }
    for _, e in ipairs(ALTBOT_CMDS) do
        CMDEntry(CMD_X1, ey1, e[1], e[2])
        ey1 = ey1 + CMD_STEP
    end

    -- Account Linking sub-section
    ey1 = ey1 + 8
    CMDSection(CMD_X1, ey1, PBM_L["Account Linking"])
    ey1 = ey1 + 20

    local ACCT_CMDS = {
        { ".playerbots account setKey <key>",      PBM_L["Set account security key"] },
        { ".playerbots account link <acct> <key>", PBM_L["Link account by key"]      },
        { ".playerbots account linkedAccounts",    PBM_L["List linked accounts"]     },
        { ".playerbots account unlink <acct>",     PBM_L["Unlink account"]           },
    }
    for _, e in ipairs(ACCT_CMDS) do
        CMDEntry(CMD_X1, ey1, e[1], e[2])
        ey1 = ey1 + CMD_STEP
    end

    -- Reset Instances sub-section
    ey1 = ey1 + 8
    CMDSection(CMD_X1, ey1, PBM_L["Reset Instances"])
    ey1 = ey1 + 20

    if not StaticPopupDialogs["PBM_RESET_INSTANCES"] then
        StaticPopupDialogs["PBM_RESET_INSTANCES"] = {
            text = "|cffd4af37" .. PBM_L["Reset Instances"] .. "|r\n\n" .. PBM_L["Send |cffFF8C00.playerbots bot refresh=raid *|r\nfor your current group/raid?"],
            button1 = PBM_L["Yes, Reset All"],
            button2 = PBM_L["Cancel"],
            OnAccept = function()
                SendChatMessage(".playerbots bot refresh=raid *", "SAY")
            end,
            timeout      = 0,
            whileDead    = true,
            hideOnEscape = true,
        }
    end

    local resetInstBtn = PBIconBtn(CMD_X1, ey1, PB_ICON.."inv_misc_punchcards_yellow",
        PBM_L["Reset Instances"], nil)
    resetInstBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(PBM_L["Reset Instances"], 0.78, 0.61, 0.23)
        GameTooltip:AddLine(PBM_L["Resets instances for entire group using"], 0.8, 0.8, 0.8)
        GameTooltip:AddLine(".playerbots bot refresh=raid *", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(PBM_L["Requires AiPlayerbot.ResetInstanceIdForAltBots = 1"], 1, 0.2, 0.2)
        GameTooltip:Show()
    end)
    resetInstBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    resetInstBtn:SetScript("OnClick", function() StaticPopup_Show("PBM_RESET_INSTANCES") end)
    local riyl = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    riyl:SetPoint("LEFT", resetInstBtn, "RIGHT", 6, 0)
    riyl:SetJustifyH("LEFT")
    riyl:SetText("|cffffffff"..PBM_L["Reset Instances for group"].."|r")
    ey1 = ey1 + PB_STEP

    -- ── Universal Strategies List ─────────────────────────────────
    -- Alphabetical, two columns, colored per strat-tree reference.
    -- n=name  hex=name color  tp=type label  tphex=badge color
    -- desc=tooltip description
    local SL_X1  = 700    -- left column
    local SL_X2  = 900    -- right column
    local SL_W   = 190
    local SL_ROW = 19

    PBLabel(SL_X1, PB_ROW_TOP, PBM_L["Universal Strategies"])
    PBDivider(SL_X1, PB_ROW_TOP + 16, 285)

    -- 38 entries, alphabetical — left col = 1-19, right col = 20-38
    local STRAT_LIST = {
        { n="adds",        hex="aaaaaa", tp="CO",    tphex="aaaaaa",
          desc=PBM_L["Abort the pull if extra mobs are detected near the target"] },
        { n="aggressive",  hex="aabb55", tp="CO",    tphex="aaaaaa",
          desc=PBM_L["Proactively engages nearby threats"] },
        { n="avoid aoe",   hex="7799ff", tp="CO",    tphex="aaaaaa",
          desc=PBM_L["Reposition to avoid AoE damage patterns"] },
        { n="boost",       hex="ff9900", tp="CO",    tphex="aaaaaa",
          desc=PBM_L["Activate offensive cooldowns (class-specific)"] },
        { n="buff",        hex="ffff00", tp="NC",    tphex="44aa44",
          desc=PBM_L["Apply class-specific party buffs to the group out of combat"] },
        { n="cast time",   hex="ffff88", tp="CO",    tphex="aaaaaa",
          desc=PBM_L["Skip long casts when target is about to die"] },
        { n="chat",        hex="aaaaaa", tp="NC",    tphex="44aa44",
          desc=PBM_L["Respond to party chat commands"] },
        { n="cure",        hex="ffff00", tp="CO",    tphex="ff8000",
          desc=PBM_L["Cleanse party debuffs (class-appropriate ability)"] },
        { n="default",     hex="aaaaaa", tp="NC",    tphex="aaaaaa",
          desc=PBM_L["Revert to base default rotation"] },
        { n="dps",         hex="ddaa00", tp="CO",    tphex="ee4433",
          desc=PBM_L["Generic DPS rotation (spec inferred from talents)"] },
        { n="dps aoe",     hex="ff8000", tp="CO",    tphex="ffcc00",
          desc=PBM_L["Bot switches to AoE rotation (area attacks)"] },
        { n="dps assist",  hex="ff8000", tp="CO",    tphex="ffcc00",
          desc=PBM_L["Bot attacks the group DPS focus target (coordinates kill order)"] },
        { n="duel",        hex="aaaaaa", tp="NC",    tphex="aaaaaa",
          desc=PBM_L["Auto-accept or decline duel requests"] },
        { n="emote",       hex="aaaaaa", tp="NC",    tphex="aaaaaa",
          desc=PBM_L["Play social emotes"] },
        { n="flee",        hex="aaaaaa", tp="CO",    tphex="aaaaaa",
          desc=PBM_L["Retreat when critical HP or outnumbered"] },
        { n="follow",      hex="7799bb", tp="NC",    tphex="44aa44",
          desc=PBM_L["Follow master"] },
        { n="food",        hex="d4af37", tp="NC",    tphex="44aa44",
          desc=PBM_L["Auto-eat and drink to recover health and mana between pulls"] },
        { n="formation",   hex="5599ee", tp="CO",    tphex="aaaaaa",
          desc=PBM_L["Maintain positional formation with group"] },
        { n="gather",      hex="d4af37", tp="NC",    tphex="44aa44",
          desc=PBM_L["Harvest herbs, ore, or skinning nodes while moving"] },
        { n="grind",       hex="aaaaaa", tp="NC",    tphex="aaaaaa",
          desc=PBM_L["Auto-attack nearby mobs, manage food/drink"] },
        -- right column starts here (20)
        { n="guard",       hex="aaaa44", tp="NC",    tphex="44aa44",
          desc=PBM_L["Hold position as a guard"] },
        { n="heal",        hex="ffcc00", tp="CO",    tphex="ee4433",
          desc=PBM_L["Bot takes healer role (must be healer-capable class)"] },
        { n="healer dps",  hex="ffcc00", tp="CO",    tphex="ee4433",
          desc=PBM_L["Healer bot also attacks between heals"] },
        { n="kite",        hex="aaaaaa", tp="",      tphex="",
          desc=PBM_L["Runs the bot away the instant it has aggro — keeps melee mobs perpetually chasing"] },
        { n="loot",        hex="d4af37", tp="NC",    tphex="44aa44",
          desc=PBM_L["Auto-loot corpses and containers"] },
        { n="mount",       hex="aaaaaa", tp="NC",    tphex="aaaaaa",
          desc=PBM_L["Use a mount when traveling"] },
        { n="offheal",     hex="55cc77", tp="CO",    tphex="ee4433",
          desc=PBM_L["DPS bot assists with emergency heals (Paladin only)"] },
        { n="passive",     hex="aabb55", tp="",      tphex="",
          desc=PBM_L["Bot does nothing (fully passive)"] },
        { n="potions",     hex="00ffaa", tp="CO",    tphex="aaaaaa",
          desc=PBM_L["Auto-use health and mana potions / healthstones"] },
        { n="pull",        hex="ff8000", tp="CO/NC", tphex="ffcc00",
          desc=PBM_L["Class-specific opening attack — tank-only initiation"] },
        { n="pull back",   hex="ff8000", tp="CO",    tphex="ffcc00",
          desc=PBM_L["Anchor at pull spot — bot opens then returns instead of running into melee"] },
        { n="pvp",         hex="ee4433", tp="CO",    tphex="ee4433",
          desc=PBM_L["Enable attacking hostile players (player-targeting toggle ONLY — rotation unchanged)"] },
        { n="racials",     hex="cc88ff", tp="CO",    tphex="aaaaaa",
          desc=PBM_L["Use racial abilities — EMFH, War Stomp, Berserking, etc."] },
        { n="save mana",   hex="6699cc", tp="CO",    tphex="aaaaaa",
          desc=PBM_L["Suppress expensive casts when mana is low"] },
        { n="stay",        hex="aaaaaa", tp="",      tphex="",
          desc=PBM_L["Hold at current spot; return to saved stay position if drifted"] },
        { n="tank assist", hex="ff8000", tp="CO",    tphex="ffcc00",
          desc=PBM_L["Bot attacks the tank's current target"] },
        { n="tank face",   hex="ff9966", tp="",      tphex="",
          desc=PBM_L["Tank rotates to face the current target each combat tick"] },
        { n="threat",      hex="aaaaaa", tp="CO",    tphex="aaaaaa",
          desc=PBM_L["Suppress actions when threat >80% (prevents pulling aggro)"] },
    }

    for i, def in ipairs(STRAT_LIST) do
        local col = (i <= 19) and 1 or 2
        local row = (i <= 19) and i or (i - 19)
        local ex  = (col == 1) and SL_X1 or SL_X2
        local ey  = PB_ROW_TOP + 24 + (row - 1) * SL_ROW

        local r = tonumber(def.hex:sub(1,2), 16) / 255
        local g = tonumber(def.hex:sub(3,4), 16) / 255
        local b = tonumber(def.hex:sub(5,6), 16) / 255

        local btn = CreateFrame("Button", nil, pbPanel)
        btn:SetSize(SL_W, SL_ROW - 1)
        btn:SetPoint("TOPLEFT", pbPanel, "TOPLEFT", ex, -ey)
        btn:SetFrameLevel(pbfl + 2)

        local hlTex = btn:CreateTexture(nil, "BACKGROUND")
        hlTex:SetAllPoints()
        hlTex:SetTexture("Interface\\Buttons\\WHITE8x8")
        hlTex:SetVertexColor(r, g, b, 0.0)

        local fs = btn:CreateFontString(nil, "OVERLAY")
        fs:SetFont("Fonts\\FRIZQT__.TTF", 10)
        fs:SetPoint("LEFT", btn, "LEFT", 2, 0)
        fs:SetHeight(SL_ROW - 1)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("MIDDLE")
        fs:SetText(def.n)
        fs:SetTextColor(r, g, b, 1)

        btn:SetScript("OnEnter", function(self)
            hlTex:SetVertexColor(r, g, b, 0.12)
            fs:SetTextColor(math.min(r*1.25,1), math.min(g*1.25,1), math.min(b*1.25,1), 1)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:ClearLines()
            local line1 = "|cff" .. def.hex .. def.n .. "|r"
            if def.tp ~= "" then
                line1 = line1 .. "  |cff" .. def.tphex .. def.tp .. "|r"
            end
            GameTooltip:AddLine(line1, 1, 1, 1)
            GameTooltip:AddLine(def.desc, 0.85, 0.85, 0.85, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            hlTex:SetVertexColor(r, g, b, 0.0)
            fs:SetTextColor(r, g, b, 1)
            GameTooltip:Hide()
        end)
    end

    -- ── Bottom footer ────────────────────────────────────────────
    local pbFooter = pbPanel:CreateFontString(nil, "OVERLAY")
    pbFooter:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    pbFooter:SetPoint("BOTTOMLEFT",  pbPanel, "BOTTOMLEFT",  310, 6)
    pbFooter:SetPoint("BOTTOMRIGHT", pbPanel, "BOTTOMRIGHT", -10, 6)
    pbFooter:SetJustifyH("CENTER")
    pbFooter:SetText("|cffff4444" .. PBM_L["** Information and strategies are subject to change as mod-playerbots is updated."] .. "|r")
end