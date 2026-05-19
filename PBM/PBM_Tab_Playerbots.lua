PBM = PBM or {}

-- ── Playerbots tab panel ───────────────────────────────────────
-- Called from PBM_TopTabs.lua:BuildBottomTabs as:
--   PBM.BuildPlayerbotsPanel(panel, ctx)
-- ctx fields used: PERI_R/G/B, ActionToGroup, ActionToTargetOrGroup

function PBM.BuildPlayerbotsPanel(pbPanel, ctx)
    local LT_PERI_R             = ctx.PERI_R
    local LT_PERI_G             = ctx.PERI_G
    local LT_PERI_B             = ctx.PERI_B
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
        fs:SetText("|cff7799ff"..text.."|r")
    end

    local function PBDivider(x, y, w)
        local t = pbPanel:CreateTexture(nil, "ARTWORK")
        t:SetPoint("TOPLEFT", pbPanel, "TOPLEFT", x, -y)
        t:SetSize(w, 1)
        t:SetTexture(LT_PERI_R, LT_PERI_G, LT_PERI_B, 0.35)
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

    -- ── Column 1 – Add RndBot (x = 35) ────────────────────────
    PBLabel(35, PB_ROW_TOP, "Add RndBot")
    PBDivider(35, PB_ROW_TOP + 16, 220)

    local CLASS_DEFS = {
        { name="Death Knight", cmd="dk",      icon=PB_ADDON.."addclass_deathknight.blp" },
        { name="Druid",        cmd="druid",   icon=PB_ADDON.."addclass_druid.blp"       },
        { name="Hunter",       cmd="hunter",  icon=PB_ADDON.."addclass_hunter.blp"      },
        { name="Mage",         cmd="mage",    icon=PB_ADDON.."addclass_mage.blp"        },
        { name="Paladin",      cmd="paladin", icon=PB_ADDON.."addclass_paladin.blp"     },
        { name="Priest",       cmd="priest",  icon=PB_ADDON.."addclass_priest.blp"      },
        { name="Rogue",        cmd="rogue",   icon=PB_ADDON.."addclass_rogue.blp"       },
        { name="Shaman",       cmd="shaman",  icon=PB_ADDON.."addclass_shaman.blp"      },
        { name="Warlock",      cmd="warlock", icon=PB_ADDON.."addclass_warlock.blp"     },
        { name="Warrior",      cmd="warrior", icon=PB_ADDON.."addclass_warrior.blp"     },
    }
    local cy = PB_ROW_TOP + 24
    for _, cd in ipairs(CLASS_DEFS) do
        local cb = PBIconBtn(35, cy, cd.icon, cd.name, "Summon a random "..cd.name.." RndBot.")
        local cap = cd.cmd
        cb:SetScript("OnClick", function() SendChatMessage(".playerbots bot addclass "..cap, "SAY") end)
        local cl = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cl:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        cl:SetText("|cffcccccc"..cd.name.."|r")
        cy = cy + PB_STEP
    end

    -- ── Column 2 – Bot Controls (x = 296) ─────────────────────
    PBLabel(296, PB_ROW_TOP, "Bot Controls")
    PBDivider(296, PB_ROW_TOP + 16, 220)
    local ry = PB_ROW_TOP + 24

    local selfbotBtn = PBIconBtn(296, ry, PB_ICON.."inv_misc_head_clockworkgnome_01",
        "Selfbot", "Switches Selfbot mode on and off.\nLeft-click to toggle.")
    PBToggle(selfbotBtn,
        function() ActionToGroup("selfbot on")  end,
        function() ActionToGroup("selfbot off") end)
    local sl = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sl:SetPoint("LEFT", selfbotBtn, "RIGHT", 6, 0); sl:SetText("|cffccccccSelfbot|r")
    ry = ry + PB_STEP

    local gmBtn = PBIconBtn(296, ry, PB_ICON.."mail_gmicon",
        "GameMaster Switch", "Enable or disable GameMaster control.\nRequires GM rights.")
    PBToggle(gmBtn,
        function() ActionToGroup("gm on")  end,
        function() ActionToGroup("gm off") end)
    local gl = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    gl:SetPoint("LEFT", gmBtn, "RIGHT", 6, 0); gl:SetText("|cffccccccGameMaster|r")
    ry = ry + PB_STEP

    local rtscBtn = PBIconBtn(296, ry, PB_ICON.."ability_hunter_markedfordeath",
        "RTSC", "Enable or disable RTSC.\nLeft-click to toggle.")
    PBToggle(rtscBtn,
        function() ActionToGroup("rtsc")       end,
        function() ActionToGroup("rtsc reset") end)
    local rl = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rl:SetPoint("LEFT", rtscBtn, "RIGHT", 6, 0); rl:SetText("|cffccccccRTSC|r")
    ry = ry + PB_STEP

    local relBtn = PBIconBtn(296, ry, PB_ICON.."achievement_bg_xkills_avgraveyard",
        "Auto Release", "Toggle automatic spirit release on bot death.")
    PBToggle(relBtn,
        function() ActionToGroup("release")    end,
        function() ActionToGroup("no release") end)
    local rll = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rll:SetPoint("LEFT", relBtn, "RIGHT", 6, 0); rll:SetText("|cffccccccAuto Release|r")
    ry = ry + PB_STEP

    local statsBtn = PBIconBtn(296, ry, PB_ICON.."inv_scroll_08",
        "Auto Stats", "Toggle automatic stats broadcast to group.")
    PBToggle(statsBtn,
        function() ActionToGroup("stats on")  end,
        function() ActionToGroup("stats off") end)
    local stl = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stl:SetPoint("LEFT", statsBtn, "RIGHT", 6, 0); stl:SetText("|cffccccccAuto Stats|r")
    ry = ry + PB_STEP

    local resetAIBtn = PBIconBtn(296, ry, PB_ICON.."inv_misc_tournaments_symbol_gnome",
        "Reset Bot AI", "Reset AI for targeted bot or entire group.")
    resetAIBtn:SetScript("OnClick", function() ActionToTargetOrGroup("reset botAI") end)
    local ral = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ral:SetPoint("LEFT", resetAIBtn, "RIGHT", 6, 0); ral:SetText("|cffccccccReset Bot AI|r")
    ry = ry + PB_STEP

    local resetActBtn = PBIconBtn(296, ry, PB_ICON.."inv_helmet_02",
        "Reset Action", "Reset actions for targeted bot or entire group.")
    resetActBtn:SetScript("OnClick", function() ActionToTargetOrGroup("reset") end)
    local rcl = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rcl:SetPoint("LEFT", resetActBtn, "RIGHT", 6, 0); rcl:SetText("|cffccccccReset Action|r")
    ry = ry + PB_STEP

    -- ── Reset Instances sub-section ───────────────────────────
    ry = ry + 10
    PBLabel(296, ry, "Reset Instances")
    PBDivider(296, ry + 16, 220)
    ry = ry + 24

    if not StaticPopupDialogs["PBM_RESET_INSTANCES"] then
        StaticPopupDialogs["PBM_RESET_INSTANCES"] = {
            text = "|cffd4af37Reset Instances|r\n\nSend |cffFF8C00.levelsync unbindall|r for every\nmember in your group/raid?",
            button1 = "Yes, Reset All",
            button2 = "Cancel",
            OnAccept = function()
                local names = {}
                if GetNumRaidMembers() > 0 then
                    for i = 1, GetNumRaidMembers() do
                        local n = UnitName("raid" .. i)
                        if n then names[#names + 1] = n end
                    end
                else
                    names[#names + 1] = UnitName("player")
                    for i = 1, GetNumPartyMembers() do
                        local n = UnitName("party" .. i)
                        if n then names[#names + 1] = n end
                    end
                end
                local idx    = 1
                local timer  = 0
                local ticker = CreateFrame("Frame")
                ticker:SetScript("OnUpdate", function(self, dt)
                    timer = timer + dt
                    if timer >= 0.4 then
                        timer = 0
                        if idx <= #names then
                            SendChatMessage(".levelsync unbindall " .. names[idx], "SAY")
                            idx = idx + 1
                        else
                            self:SetScript("OnUpdate", nil)
                        end
                    end
                end)
            end,
            timeout      = 0,
            whileDead    = true,
            hideOnEscape = true,
        }
    end

    local resetInstBtn = PBIconBtn(296, ry, PB_ICON.."inv_misc_punchcards_yellow",
        "Reset Instances", nil)
    resetInstBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Reset Instances", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Resets instances for entire group using", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(".levelsync unbindall <name>", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Requires mod-levelsync", 1, 0.55, 0.0)
        GameTooltip:Show()
    end)
    resetInstBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    resetInstBtn:SetScript("OnClick", function()
        StaticPopup_Show("PBM_RESET_INSTANCES")
    end)
    local riyl = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    riyl:SetPoint("LEFT", resetInstBtn, "RIGHT", 6, 0)
    riyl:SetJustifyH("LEFT")
    riyl:SetText("|cffccccccReset Instances for entire group|r\n|cffFF8C00Requires mod-levelsync|r")
    ry = ry + PB_STEP

    if not StaticPopupDialogs["PBM_RESET_INSTANCES_GM"] then
        StaticPopupDialogs["PBM_RESET_INSTANCES_GM"] = {
            text = "|cffd4af37GM Reset Instances|r\n\nSend |cffFF8C00.levelsync gm unbindall|r for every\nmember in your group/raid?\n\n|cffFF4444Requires GM privileges.|r",
            button1 = "Yes, Reset All",
            button2 = "Cancel",
            OnAccept = function()
                local names = {}
                if GetNumRaidMembers() > 0 then
                    for i = 1, GetNumRaidMembers() do
                        local n = UnitName("raid" .. i)
                        if n then names[#names + 1] = n end
                    end
                else
                    names[#names + 1] = UnitName("player")
                    for i = 1, GetNumPartyMembers() do
                        local n = UnitName("party" .. i)
                        if n then names[#names + 1] = n end
                    end
                end
                local idx    = 1
                local timer  = 0
                local ticker = CreateFrame("Frame")
                ticker:SetScript("OnUpdate", function(self, dt)
                    timer = timer + dt
                    if timer >= 0.4 then
                        timer = 0
                        if idx <= #names then
                            SendChatMessage(".levelsync gm unbindall " .. names[idx], "SAY")
                            idx = idx + 1
                        else
                            self:SetScript("OnUpdate", nil)
                        end
                    end
                end)
            end,
            timeout      = 0,
            whileDead    = true,
            hideOnEscape = true,
        }
    end

    local gmResetInstBtn = PBIconBtn(296, ry, PB_ICON.."inv_misc_key_06", "GM Reset Instances", nil)
    gmResetInstBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("GM Reset Instances", 0.78, 0.61, 0.23)
        GameTooltip:AddLine("Resets instances for entire group using", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(".levelsync gm unbindall <name>", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Requires mod-levelsync", 1, 0.55, 0.0)
        GameTooltip:AddLine("Requires GM Access", 1, 0.2, 0.2)
        GameTooltip:Show()
    end)
    gmResetInstBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    gmResetInstBtn:SetScript("OnClick", function()
        StaticPopup_Show("PBM_RESET_INSTANCES_GM")
    end)
    local gmriyl = pbPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    gmriyl:SetPoint("LEFT", gmResetInstBtn, "RIGHT", 6, 0)
    gmriyl:SetJustifyH("LEFT")
    gmriyl:SetText("|cffccccccGM Reset Instances for entire group|r\n|cffFF8C00Requires mod-levelsync|r\n|cffff4444Requires GM Access|r")

    -- ── Column 3 – Command Reference (x = 560) ────────────────
    local CMD_X1    = 560
    local CMD_X2    = 820
    local CMD_DIV_W = 511
    local CMD_STEP  = 44

    PBLabel(CMD_X1, PB_ROW_TOP, "Bot Commands")
    PBDivider(CMD_X1, PB_ROW_TOP + 16, CMD_DIV_W)

    local function CMDEntry(x, y, cmd, desc)
        local fc = pbPanel:CreateFontString(nil, "OVERLAY")
        fc:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        fc:SetPoint("TOPLEFT", pbPanel, "TOPLEFT", x, -y)
        fc:SetWidth(255); fc:SetJustifyH("LEFT")
        fc:SetText("|cffd4af37"..cmd.."|r")
        local fd = pbPanel:CreateFontString(nil, "OVERLAY")
        fd:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        fd:SetPoint("TOPLEFT", pbPanel, "TOPLEFT", x + 4, -(y + 13))
        fd:SetWidth(255); fd:SetJustifyH("LEFT")
        fd:SetText("|cffaaaaaa"..desc.."|r")
    end

    local function CMDSection(x, y, text)
        local fs = pbPanel:CreateFontString(nil, "OVERLAY")
        fs:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        fs:SetPoint("TOPLEFT", pbPanel, "TOPLEFT", x, -y)
        fs:SetText("|cff7799ff"..text.."|r")
        local t = pbPanel:CreateTexture(nil, "ARTWORK")
        t:SetPoint("TOPLEFT", pbPanel, "TOPLEFT", x, -(y + 12))
        t:SetSize(245, 1); t:SetTexture(LT_PERI_R, LT_PERI_G, LT_PERI_B, 0.25)
    end

    -- Left sub-column: Altbot management
    local ey1 = PB_ROW_TOP + 26
    local ALTBOT_CMDS = {
        { ".playerbots bot add [name,...]",     "Login altbot(s)"               },
        { ".playerbots bot addaccount [acct]",  "Login entire account"          },
        { ".playerbots bot remove [name,...]",  "Logout altbot(s)"              },
        { ".playerbots bot add *",              "Login all in party/raid"       },
        { ".playerbots bot remove *",           "Logout all in party/raid"      },
        { "maintenance",             "Learn spells, enchant, repair" },
        { "autogear",                "Auto-equip best gear"          },
        { "talents",                 "Show current spec"             },
        { "talents spec list",       "List available specs"          },
        { "talents spec [name]",     "Change to named spec"          },
    }
    for _, e in ipairs(ALTBOT_CMDS) do
        CMDEntry(CMD_X1, ey1, e[1], e[2])
        ey1 = ey1 + CMD_STEP
    end

    -- Right sub-column: Talents / Glyphs / Reset
    local ey2 = PB_ROW_TOP + 26
    local MISC_CMDS = {
        { "talents apply <link>",      "Apply talent link"         },
        { "glyphs",                    "List equipped glyphs"      },
        { "glyph equip [ID1..ID6]",    "Apply glyphs to bot"       },
        { "reset botAI",               "Reset bot AI settings"     },
        { "reset",                     "Reset current bot actions" },
    }
    for _, e in ipairs(MISC_CMDS) do
        CMDEntry(CMD_X2, ey2, e[1], e[2])
        ey2 = ey2 + CMD_STEP
    end

    ey2 = ey2 + 8
    CMDSection(CMD_X2, ey2, "Account Linking")
    ey2 = ey2 + 20

    local ACCT_CMDS = {
        { ".playerbots account setKey [key]",      "Set account security key"  },
        { ".playerbots account link [acct] [key]", "Link account by key"       },
        { ".playerbots account linkedAccounts",    "List linked accounts"      },
        { ".playerbots account unlink [acct]",     "Unlink account"            },
    }
    for _, e in ipairs(ACCT_CMDS) do
        CMDEntry(CMD_X2, ey2, e[1], e[2])
        ey2 = ey2 + CMD_STEP
    end
end
