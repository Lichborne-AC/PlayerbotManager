PBM = PBM or {}

-- ── LevelSync tab panel ────────────────────────────────────────
-- Completely self-contained: no external LevelSync addon required.
-- Communicates with mod-levelsync via WoW chat commands (.levelsync <cmd>).
-- Captures and parses CHAT_MSG_SYSTEM responses using a state machine
-- (300 ms commit-delay, multi-line block collection).
-- Called from PBM_TopTabs.lua:BuildBottomTabs as:
--   PBM.BuildLevelSyncPanel(panel, ctx)
-- ctx fields used: GOLD_R/G/B, FONT, BD_CELL

function PBM.BuildLevelSyncPanel(lsPanel, ctx)
    local LT_GOLD_R  = ctx.GOLD_R
    local LT_GOLD_G  = ctx.GOLD_G
    local LT_GOLD_B  = ctx.GOLD_B
    local LT_FONT    = ctx.FONT
    local LT_BD_CELL = ctx.BD_CELL

    local lspfl = lsPanel:GetFrameLevel()

    -- ── Layout constants ───────────────────────────────────────
    local LS_MARGIN   = 15;  local LS_CELL_W  = 348; local LS_CELL_H  = 169
    local LS_CELL_GAP = 6;   local LS_GRID_TOP = -52; local LS_GRID_END = -396
    local LS_SLOT_CNT = 10;  local LS_ROW_H   = 12
    local LS_LVL_X    = 2;   local LS_LVL_W   = 20
    local LS_NAM_X    = 26;  local LS_NAM_W   = 110
    local LS_TIR_X    = 140; local LS_TIR_W   = 180
    local LS_REM_X    = 326; local LS_REM_W   = 16

    -- ── Class colors (hex RGB strings, keyed by class name) ───
    local LS_CLASS_COLORS = {
        ["Warrior"]      = "C79C6E",
        ["Paladin"]      = "F58CBA",
        ["Hunter"]       = "ABD473",
        ["Rogue"]        = "FFF569",
        ["Priest"]       = "FFFFFF",
        ["Death Knight"] = "C41F3B",
        ["Shaman"]       = "0070DE",
        ["Mage"]         = "69CCF0",
        ["Warlock"]      = "9482C9",
        ["Druid"]        = "FF7D0A",
    }

    -- Tier colors and short names come from IPTiersColor.lua (PBM.TIER_COLORS / PBM.TIER_SHORT)

    -- ── Helper: 6-char hex string → r, g, b floats (0-1) ──────
    local function lsHexRGB(hex)
        if not hex then return 1, 1, 1 end
        return tonumber(hex:sub(1,2),16)/255,
               tonumber(hex:sub(3,4),16)/255,
               tonumber(hex:sub(5,6),16)/255
    end

    -- ── Parsed group data ──────────────────────────────────────
    local lsData = {
        inGroup        = false,
        groupId        = nil,
        accountsCur    = 0,
        accountsMax    = 0,
        totalChars     = 0,
        levelSync      = false,
        ipSync         = false,
        ipSyncDisabled = false,
        members        = {},
    }

    -- ── Command sender ─────────────────────────────────────────
    local function lsSendCmd(cmd)
        if InCombatLockdown() then
            LichborneOutput("|cffC69B3APBM:|r " .. (PBM_L["Cannot send commands while in combat."] or "Cannot send commands while in combat."))
            return
        end
        local box = ChatFrame1EditBox
        if not box:IsVisible() then
            ChatFrame_OpenChat("", ChatFrame1)
        end
        box:SetText(".levelsync " .. cmd)
        ChatEdit_SendText(box, false)
        box:Hide()
    end

    PBM.LevelSyncAutoRefresh = function() lsSendCmd("status") end

    -- ── Multi-line status state machine ────────────────────────
    local COMMIT_DELAY    = 0.3
    local sm              = { active = false, lines = {} }
    local commitRemaining = 0
    local lsRebuildGrid   -- forward declaration; assigned after grid is built

    local commitFrame = CreateFrame("Frame", nil, UIParent)
    commitFrame:Hide()

    local function ArmCommitTimer()
        commitRemaining = COMMIT_DELAY
        commitFrame:Show()
    end

    local function CommitStatus()
        sm.active = false
        local d = lsData
        d.inGroup     = false;  d.groupId     = nil
        d.accountsCur = 0;      d.accountsMax = 0
        d.totalChars  = 0;      d.levelSync   = false
        d.ipSync      = false;  d.members     = {}

        local curAccount = nil
        for _, line in ipairs(sm.lines) do
            local gid = line:match("Sync Group #(%d+)")
            if gid then d.inGroup = true; d.groupId = tonumber(gid) end

            local cur, max = line:match("Accounts: (%d+)/(%d+)")
            if cur then d.accountsCur = tonumber(cur); d.accountsMax = tonumber(max) end

            local tc = line:match("Total Characters: (%d+)")
            if tc then d.totalChars = tonumber(tc) end

            local ls = line:match("Level sync: (%a+)")
            if ls then d.levelSync = (ls == "Available") end

            local ps = line:match("Progression sync: (%a+)")
            if ps then d.ipSync = (ps == "Available") end

            local accId = line:match("Account (%d+):")
            if accId then curAccount = tonumber(accId) end

            local name, lvl, cls, tierStr =
                line:match("^%s+(.-)%s+%(lvl (%d+)%)%s+%((.-)%)%s+IP Tier: (.+)$")
            if name and curAccount then
                local tierNum = 0
                if tierStr and tierStr ~= "None" then
                    tierNum = tonumber(tierStr:match("^(%d+)")) or 0
                end
                table.insert(d.members, {
                    accountId = curAccount,
                    name      = name,
                    level     = tonumber(lvl),
                    class     = cls,
                    tierStr   = tierStr,
                    tierNum   = tierNum,
                })
            end
        end
        sm.lines = {}
        if lsRebuildGrid then lsRebuildGrid() end
    end

    commitFrame:SetScript("OnUpdate", function(self, elapsed)
        commitRemaining = commitRemaining - elapsed
        if commitRemaining <= 0 then
            self:Hide()
            if sm.active then CommitStatus() end
        end
    end)

    -- ── CHAT_MSG_SYSTEM event listener ─────────────────────────
    local lsEventFrame = CreateFrame("Frame", "PBMLevelSyncEventFrame", UIParent)
    lsEventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    lsEventFrame:SetScript("OnEvent", function(self, event, msg)
        local clean = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

        if sm.active then
            table.insert(sm.lines, clean)
            ArmCommitTimer()
            return
        end

        if not clean:find("%[LevelSync%]") then return end

        if clean:find("Sync group disbanded") or clean:find("You are not in a sync group") then
            local d = lsData
            d.inGroup     = false; d.groupId     = nil
            d.accountsCur = 0;     d.accountsMax = 0
            d.totalChars  = 0;     d.levelSync   = false
            d.ipSync      = false; d.members     = {}
            if lsRebuildGrid then lsRebuildGrid() end
            return
        end

        if clean:find("Sync Group #") then
            sm.active = true
            sm.lines  = { clean }
            ArmCommitTimer()
            return
        end
    end)

    -- ── Chat filter: suppress status block from the chat frame ─
    local function PBM_LevelSyncFilter(_, _, msg)
        local clean = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

        if sm.active then
            if not clean:find("%[LevelSync%]") then return true end
            if clean:find("Sync Group #") or clean:find("Group members")
               or clean:find("graphical interface") then return true end
            return
        end

        if clean:find("%[LevelSync%]") and clean:find("Sync Group #") then
            return true
        end
    end
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", PBM_LevelSyncFilter)

    -- ── Gold separator helper ──────────────────────────────────
    local function lsGoldLine(yAbs)
        local t = lsPanel:CreateTexture(nil, "OVERLAY")
        t:SetHeight(1)
        t:SetPoint("TOPLEFT",  lsPanel, "TOPLEFT",   LS_MARGIN,  yAbs)
        t:SetPoint("TOPRIGHT", lsPanel, "TOPRIGHT", -LS_MARGIN, yAbs)
        t:SetTexture(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B, 0.55)
    end
    lsGoldLine(-38)

    -- ── 6-cell account grid (2 rows × 3 cols) ─────────────────
    local lsCells = {}
    for idx = 1, 6 do
        local col  = (idx - 1) % 3
        local row  = math.floor((idx - 1) / 3)
        local xOff = LS_MARGIN + col * (LS_CELL_W + LS_CELL_GAP)
        local yTop = LS_GRID_TOP - row * (LS_CELL_H + LS_CELL_GAP)

        local cell = CreateFrame("Frame", nil, lsPanel)
        cell:SetSize(LS_CELL_W, LS_CELL_H)
        cell:SetPoint("TOPLEFT", lsPanel, "TOPLEFT", xOff, yTop)
        cell:SetFrameLevel(lspfl + 1)
        cell:SetBackdrop(LT_BD_CELL)
        cell:SetBackdropColor(0.08, 0.10, 0.18, 1)
        cell:SetBackdropBorderColor(0.25, 0.35, 0.55, 0.80)

        local hdrFS = cell:CreateFontString(nil, "OVERLAY")
        hdrFS:SetFont(LT_FONT, 10, "OUTLINE")
        hdrFS:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, -3)
        hdrFS:SetWidth(LS_CELL_W - 4); hdrFS:SetJustifyH("CENTER")
        hdrFS:SetTextColor(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B)
        hdrFS:SetText(PBM_L["— empty —"])

        local acctSep = cell:CreateTexture(nil, "ARTWORK")
        acctSep:SetHeight(1)
        acctSep:SetPoint("TOPLEFT",  cell, "TOPLEFT",   3, -16)
        acctSep:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -3, -16)
        acctSep:SetTexture(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B, 0.55)

        local function ColHdr(text, x, w, jh)
            local fs = cell:CreateFontString(nil, "OVERLAY")
            fs:SetFont(LT_FONT, 9, "OUTLINE")
            fs:SetPoint("TOPLEFT", cell, "TOPLEFT", x, -22)
            fs:SetWidth(w); fs:SetJustifyH(jh or "LEFT")
            fs:SetTextColor(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B)
            fs:SetText(text)
        end
        ColHdr(PBM_L["Character"], LS_NAM_X, LS_NAM_W)
        ColHdr(PBM_L["Tier"],      LS_TIR_X, LS_TIR_W)

        local hdrSep = cell:CreateTexture(nil, "ARTWORK")
        hdrSep:SetHeight(1)
        hdrSep:SetPoint("TOPLEFT",  cell, "TOPLEFT",   3, -37)
        hdrSep:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -3, -37)
        hdrSep:SetTexture(0.25, 0.35, 0.55, 0.70)

        local rows = {}
        for r = 1, LS_SLOT_CNT do
            local yRow = -(39 + (r - 1) * LS_ROW_H)

            local lvlFS = cell:CreateFontString(nil, "OVERLAY")
            lvlFS:SetFont(LT_FONT, 9, "OUTLINE")
            lvlFS:SetPoint("TOPLEFT", cell, "TOPLEFT", LS_LVL_X, yRow)
            lvlFS:SetWidth(LS_LVL_W); lvlFS:SetJustifyH("CENTER"); lvlFS:SetText("")

            local nameFS = cell:CreateFontString(nil, "OVERLAY")
            nameFS:SetFont(LT_FONT, 9, "OUTLINE")
            nameFS:SetPoint("TOPLEFT", cell, "TOPLEFT", LS_NAM_X, yRow)
            nameFS:SetWidth(LS_NAM_W); nameFS:SetJustifyH("LEFT"); nameFS:SetText("")

            local tierFS = cell:CreateFontString(nil, "OVERLAY")
            tierFS:SetFont(LT_FONT, 9, "OUTLINE")
            tierFS:SetPoint("TOPLEFT", cell, "TOPLEFT", LS_TIR_X, yRow)
            tierFS:SetWidth(LS_TIR_W); tierFS:SetJustifyH("LEFT"); tierFS:SetText("")

            local highlight = cell:CreateTexture(nil, "ARTWORK")
            highlight:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, yRow)
            highlight:SetSize(LS_CELL_W - 6, LS_ROW_H - 1)
            highlight:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
            highlight:SetVertexColor(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B, 0.08)
            highlight:Hide()

            local rowBtn = CreateFrame("Button", nil, cell)
            rowBtn:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, yRow)
            rowBtn:SetSize(LS_CELL_W - 6, LS_ROW_H)
            rowBtn:SetFrameLevel(cell:GetFrameLevel() + 1)
            rowBtn.active = false
            rowBtn:SetScript("OnEnter", function(self) if self.active then highlight:Show() end end)
            rowBtn:SetScript("OnLeave", function() highlight:Hide() end)

            local removeBtn = CreateFrame("Button", nil, cell)
            removeBtn:SetSize(LS_REM_W, LS_ROW_H)
            removeBtn:SetPoint("TOPLEFT", cell, "TOPLEFT", LS_REM_X, yRow)
            removeBtn:SetFrameLevel(cell:GetFrameLevel() + 2)
            removeBtn.charName = ""
            local removeLbl = removeBtn:CreateFontString(nil, "OVERLAY")
            removeLbl:SetFont(LT_FONT, 9, "OUTLINE"); removeLbl:SetAllPoints(removeBtn)
            removeLbl:SetJustifyH("CENTER"); removeLbl:SetTextColor(0.70, 0.20, 0.20)
            removeLbl:SetText("×"); removeBtn.lbl = removeLbl
            removeBtn:SetScript("OnClick", function(self)
                if self.charName ~= "" then lsSendCmd("removechar " .. self.charName) end
            end)
            removeBtn:SetScript("OnEnter", function(self)
                self.lbl:SetTextColor(1.0, 0.4, 0.4)
                if rowBtn.active then highlight:Show() end
            end)
            removeBtn:SetScript("OnLeave", function(self)
                self.lbl:SetTextColor(0.70, 0.20, 0.20); highlight:Hide()
            end)
            removeBtn:Hide()

            rows[r] = {
                lvlFS=lvlFS, nameFS=nameFS, tierFS=tierFS,
                removeBtn=removeBtn, rowBtn=rowBtn, highlight=highlight,
            }
        end
        lsCells[idx] = { frame=cell, hdrFS=hdrFS, rows=rows }
    end

    -- ── Status bar ─────────────────────────────────────────────
    lsGoldLine(LS_GRID_END - 8)
    local lsStatY = LS_GRID_END - 18

    local lsRefreshBtn = CreateFrame("Button", nil, lsPanel)
    lsRefreshBtn:SetSize(90, 22)
    lsRefreshBtn:SetPoint("TOPLEFT", lsPanel, "TOPLEFT", 15, LS_GRID_END - 14)
    lsRefreshBtn:SetFrameLevel(lspfl + 1)
    lsRefreshBtn:SetBackdrop(LT_BD_CELL)
    lsRefreshBtn:SetBackdropColor(0.10, 0.08, 0.02, 1)
    lsRefreshBtn:SetBackdropBorderColor(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B, 1.0)
    lsRefreshBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local lsRefLbl = lsRefreshBtn:CreateFontString(nil, "OVERLAY")
    lsRefLbl:SetFont(LT_FONT, 10, "OUTLINE"); lsRefLbl:SetAllPoints(lsRefreshBtn)
    lsRefLbl:SetJustifyH("CENTER"); lsRefLbl:SetText("|cffd4af37" .. PBM_L["Refresh"] .. "|r")
    lsRefreshBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 0.95, 0.5, 1)
    end)
    lsRefreshBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B, 1)
    end)
    lsRefreshBtn:SetScript("OnClick", function() lsSendCmd("status") end)

    local lsAccountsFS = lsPanel:CreateFontString(nil, "OVERLAY")
    lsAccountsFS:SetFont(LT_FONT, 10, "OUTLINE")
    lsAccountsFS:SetPoint("TOPLEFT", lsPanel, "TOPLEFT", 192, lsStatY)
    lsAccountsFS:SetWidth(130); lsAccountsFS:SetJustifyH("CENTER")
    lsAccountsFS:SetTextColor(0.70, 0.75, 0.85); lsAccountsFS:SetText(PBM_L["Accounts: —"])

    local lsTotalCharsFS = lsPanel:CreateFontString(nil, "OVERLAY")
    lsTotalCharsFS:SetFont(LT_FONT, 10, "OUTLINE")
    lsTotalCharsFS:SetPoint("TOPLEFT", lsPanel, "TOPLEFT", 409, lsStatY)
    lsTotalCharsFS:SetWidth(130); lsTotalCharsFS:SetJustifyH("CENTER")
    lsTotalCharsFS:SetTextColor(0.70, 0.75, 0.85); lsTotalCharsFS:SetText(PBM_L["Characters: —"])

    local lsLevelSyncFS = lsPanel:CreateFontString(nil, "OVERLAY")
    lsLevelSyncFS:SetFont(LT_FONT, 10, "OUTLINE")
    lsLevelSyncFS:SetPoint("TOPLEFT", lsPanel, "TOPLEFT", 626, lsStatY)
    lsLevelSyncFS:SetWidth(130); lsLevelSyncFS:SetJustifyH("CENTER")
    lsLevelSyncFS:SetTextColor(0.70, 0.75, 0.85); lsLevelSyncFS:SetText(PBM_L["Level Sync: —"])

    local lsIpSyncFS = lsPanel:CreateFontString(nil, "OVERLAY")
    lsIpSyncFS:SetFont(LT_FONT, 10, "OUTLINE")
    lsIpSyncFS:SetPoint("TOPLEFT", lsPanel, "TOPLEFT", 843, lsStatY)
    lsIpSyncFS:SetWidth(130); lsIpSyncFS:SetJustifyH("CENTER")
    lsIpSyncFS:SetTextColor(0.70, 0.75, 0.85); lsIpSyncFS:SetText(PBM_L["IP Sync: —"])

    -- ── Command Reference ──────────────────────────────────────
    local LS_CMD_Y    = LS_GRID_END - 42
    local LS_CMD_STEP = 26
    local LS_CMD_COL2 = 375
    local LS_CMD_COL3 = 735
    local LS_CMD_W    = 330

    lsGoldLine(LS_CMD_Y)

    local cmdHdr = lsPanel:CreateFontString(nil, "OVERLAY")
    cmdHdr:SetFont(LT_FONT, 13, "OUTLINE")
    cmdHdr:SetPoint("TOPLEFT", lsPanel, "TOPLEFT", LS_MARGIN, LS_CMD_Y - 8)
    cmdHdr:SetTextColor(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B)
    cmdHdr:SetText(PBM_L["Commands"])

    local notesHdr = lsPanel:CreateFontString(nil, "OVERLAY")
    notesHdr:SetFont(LT_FONT, 13, "OUTLINE")
    notesHdr:SetPoint("TOPLEFT", lsPanel, "TOPLEFT", LS_CMD_COL3, LS_CMD_Y - 8)
    notesHdr:SetTextColor(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B)
    notesHdr:SetText(PBM_L["Notes"])

    local setupHdr = lsPanel:CreateFontString(nil, "OVERLAY")
    setupHdr:SetFont(LT_FONT, 13, "OUTLINE")
    setupHdr:SetPoint("TOPRIGHT", lsPanel, "TOPRIGHT", -(LS_MARGIN + 26), lsStatY)
    setupHdr:SetWidth(90); setupHdr:SetJustifyH("RIGHT")
    setupHdr:SetTextColor(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B)
    setupHdr:SetText(PBM_L["Setup:"])

    local setupIcon1 = CreateFrame("Button", nil, lsPanel)
    setupIcon1:SetSize(20, 20)
    setupIcon1:SetPoint("TOPRIGHT", lsPanel, "TOPRIGHT", -LS_MARGIN, LS_GRID_END - 14)
    local si1tex = setupIcon1:CreateTexture(nil, "ARTWORK")
    si1tex:SetAllPoints(setupIcon1)
    si1tex:SetTexture("Interface\\Icons\\Inv_misc_groupneedmore")
    setupIcon1:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffd4af37" .. PBM_L["HOW TO USE LEVELSYNC"] .. "|r")
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(PBM_L["1. Set a |cffFF8C00security key|r for your account:"], 1, 1, 1)
        GameTooltip:AddLine(PBM_L["   |cffd4af37.levelsync setkey <yourkey>|r"], 1, 1, 1)
        GameTooltip:AddLine(PBM_L["   You need this key to add your accounts to the sync group."], 1, 1, 1)
        GameTooltip:AddLine(PBM_L["   |cffff4444Keep it private \226\128\148 it's the \"password\" for linking.|r"], 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(PBM_L["2. Link other accounts or characters into your |cff66ccffsync|r group:"], 1, 1, 1)
        GameTooltip:AddLine(PBM_L["   |cffd4af37.levelsync addaccount <accountname> <key>|r"], 1, 1, 1)
        GameTooltip:AddLine(PBM_L["   |cffd4af37.levelsync addchar <charname> <key>|r"], 1, 1, 1)
        GameTooltip:AddLine(PBM_L["   The key is |cffff4444NOT|r required if you're adding your own account."], 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(PBM_L["3. |cff66ccffLevel Sync|r and |cff66ccffIP Sync|r are |cffFF8C00toggle only|r. To toggle:"], 1, 1, 1)
        GameTooltip:AddLine(PBM_L["   |cffd4af37.levelsync level on|r"], 1, 1, 1)
        GameTooltip:AddLine(PBM_L["   |cffd4af37.levelsync IP on|r"], 1, 1, 1)
        GameTooltip:AddLine(PBM_L["   |cff44dd44Available|r indicates syncs are available."], 1, 1, 1)
        GameTooltip:AddLine(PBM_L["   |cffdd4444Disabled|r indicates syncs are disabled."], 1, 1, 1)
        GameTooltip:AddLine(PBM_L["   A |cffFF8C0010 second cooldown|r is applied after each sync."], 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(PBM_L["4. Use |cff66ccffpool gold|r to drain your level sync group members'"], 1, 1, 1)
        GameTooltip:AddLine(PBM_L["   wallets into yours:"], 1, 1, 1)
        GameTooltip:AddLine(PBM_L["   |cffd4af37.levelsync money|r"], 1, 1, 1)
        GameTooltip:Show()
    end)
    setupIcon1:SetScript("OnLeave", function() GameTooltip:Hide() end)

    lsGoldLine(LS_CMD_Y - 28)

    local function LSCmdEntry(x, y, cmd, desc)
        local fc = lsPanel:CreateFontString(nil, "OVERLAY")
        fc:SetFont(LT_FONT, 10, "OUTLINE")
        fc:SetPoint("TOPLEFT", lsPanel, "TOPLEFT", x, y)
        fc:SetWidth(LS_CMD_W); fc:SetJustifyH("LEFT")
        fc:SetTextColor(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B)
        fc:SetText(cmd)
        local fd = lsPanel:CreateFontString(nil, "OVERLAY")
        fd:SetFont(LT_FONT, 9, "OUTLINE")
        fd:SetPoint("TOPLEFT", lsPanel, "TOPLEFT", x + 4, y - 12)
        fd:SetWidth(LS_CMD_W); fd:SetJustifyH("LEFT")
        fd:SetTextColor(0.75, 0.75, 0.75)
        fd:SetText(desc)
    end

    local cmdStart = LS_CMD_Y - 36
    local function BuildLSCmdColumn(x, entries)
        local cy = cmdStart
        for _, e in ipairs(entries) do
            LSCmdEntry(x, cy, e[1], e[2])
            cy = cy - LS_CMD_STEP
        end
    end

    BuildLSCmdColumn(LS_MARGIN, {
        { ".levelsync setkey <key>",            PBM_L["Set your account security key"]            },
        { ".levelsync addaccount <acct> [key]", PBM_L["Link all characters from another account"] },
        { ".levelsync addchar <name> [key]",    PBM_L["Link a single character into your group"]  },
        { ".levelsync removechar <name>",       PBM_L["Remove one character from your group"]     },
        { ".levelsync removeaccount <acct>",    PBM_L["Remove all characters of an account"]      },
        { ".levelsync removeaccount # <acct#>", PBM_L["Remove an account by its account number"]  },
        { ".levelsync money",                   PBM_L["Pool all group money to the caller"]       },
    })

    BuildLSCmdColumn(LS_CMD_COL2, {
        { ".levelsync removeall",                PBM_L["Disband your sync group"]                        },
        { ".levelsync disbandaccount",           PBM_L["Disband all groups tied to your account"]        },
        { ".levelsync listaccount <acct> [key]", PBM_L["List all characters on an account"]              },
        { ".levelsync status",                   PBM_L["Show full group summary and all members"]        },
        { ".levelsync level on|off",             PBM_L["Toggle level synchronization for the group"]     },
        { ".levelsync IP on|off",                PBM_L["Toggle progression (IP tier) sync for the group"] },
        { ".levelsync unbindall",                PBM_L["Resets all instances for target (requires server auth)"] },
    })

    -- ── Notes columns (A = left, B = right) ───────────────────
    local noteY      = cmdStart
    local NOTE_STEP  = 36
    local NOTE_W     = 155
    local NOTE_COL_A = LS_CMD_COL3 + 4
    local NOTE_COL_B = LS_CMD_COL3 + 169

    local function MakeNote(colX, offset, text)
        local n = lsPanel:CreateFontString(nil, "OVERLAY")
        n:SetFont(LT_FONT, 9, "OUTLINE")
        n:SetPoint("TOPLEFT", lsPanel, "TOPLEFT", colX, noteY + offset)
        n:SetWidth(NOTE_W); n:SetJustifyH("LEFT")
        n:SetTextColor(0.75, 0.75, 0.75)
        n:SetText(text)
    end

    MakeNote(NOTE_COL_A, 0,              PBM_L["|cffd4af37UPWARD ONLY|r \226\128\148 Levels, XP, and IP tier are never lowered. Sub-max members get pulled up."])
    MakeNote(NOTE_COL_A, -NOTE_STEP,     PBM_L["|cffd4af37SESSION SYNC|r \226\128\148 Syncs must be explicitly triggered via toggle \226\128\148 they do not fire automatically."])
    MakeNote(NOTE_COL_A, -NOTE_STEP * 2, PBM_L["|cffd4af37IP TIER|r \226\128\148 Tier syncs must be triggered manually via the IP toggle."])
    MakeNote(NOTE_COL_A, -NOTE_STEP * 3, PBM_L["|cffd4af37COOLDOWN|r \226\128\148 10-sec shared cooldown covers level, IP, and money commands."])
    MakeNote(NOTE_COL_A, -NOTE_STEP * 4, PBM_L["|cffd4af37SECURITY KEY|r \226\128\148 Controls who can link to your account. Keep it private."])

    MakeNote(NOTE_COL_B, 0,              PBM_L["|cffd4af37DEATH KNIGHTS|r \226\128\148 DK's can't pull up sub-55 levels/IP. Configurable server-side."])
    MakeNote(NOTE_COL_B, -NOTE_STEP,     PBM_L["|cffd4af37MONEY POOL|r \226\128\148 Toggle money pooling on/off. Pools group gold onto the caller."])
    MakeNote(NOTE_COL_B, -NOTE_STEP * 2, PBM_L["|cffd4af37GROUP LIMIT|r \226\128\148 Default cap is 6 accounts per group (up to 10 server-side)."])
    MakeNote(NOTE_COL_B, -NOTE_STEP * 3, PBM_L["|cffd4af37UNBIND ALL|r \226\128\148 Uses the GM command to reset target instances. (Automated in the Playerbots tab)"])

    -- ── Bottom footer ──────────────────────────────────────────
    local lsFooter = lsPanel:CreateFontString(nil, "OVERLAY")
    lsFooter:SetFont(LT_FONT, 10, "OUTLINE")
    lsFooter:SetPoint("BOTTOMLEFT",  lsPanel, "BOTTOMLEFT",  LS_MARGIN, 8)
    lsFooter:SetPoint("BOTTOMRIGHT", lsPanel, "BOTTOMRIGHT", -LS_MARGIN, 8)
    lsFooter:SetJustifyH("CENTER")
    lsFooter:SetTextColor(0.75, 0.75, 0.75)
    lsFooter:SetText(PBM_L["** This tab requires |cffd4af37mod-levelsync|r on your server. Latest release at |cff66ccffgithub.com/Lichborne-AC/mod-levelsync|r"])

    -- ── Export LevelSync data into the PBM tracker ─────────────
    -- Copies each synced character's name, class, level and IP tier into the
    -- main PBM roster (LichborneTrackerDB.rows / .ipData) so they appear in the
    -- class/Overview tabs. Mirrors the AddGroupMembers add pattern.
    local function lsExportToPBM()
        local d = lsData
        if not d.members or #d.members == 0 then
            LichborneOutput("|cffC69B3APBM:|r " .. PBM_L["No LevelSync data to export. Click |cffd4af37Refresh|r first."], 1, 0.6, 0.2)
            return
        end
        if not LichborneTrackerDB.rows   then LichborneTrackerDB.rows   = {} end
        if not LichborneTrackerDB.ipData then LichborneTrackerDB.ipData = {} end

        local added, updated, skipped = 0, 0, 0
        for _, m in ipairs(d.members) do
            local cls = m.class
            if cls and PBM.CLASS_COLORS[cls] then
                -- Find an existing tracker row for this character (any class)
                local foundDi = nil
                for i, row in ipairs(LichborneTrackerDB.rows) do
                    if row.name and row.name ~= "" and row.name:lower() == m.name:lower() then
                        foundDi = i; break
                    end
                end
                if foundDi then
                    local row = LichborneTrackerDB.rows[foundDi]
                    row.cls   = cls
                    row.level = m.level or row.level or 0
                    updated = updated + 1
                else
                    PBM.EnsureClass(cls)
                    local slot = nil
                    for _, di in ipairs(PBM.GetAllClassRows(cls)) do
                        local row = LichborneTrackerDB.rows[di]
                        if not row.name or row.name == "" then slot = di; break end
                    end
                    if not slot then
                        table.insert(LichborneTrackerDB.rows, PBM.DefaultRow(cls))
                        slot = #LichborneTrackerDB.rows
                    end
                    LichborneTrackerDB.rows[slot].name  = m.name
                    LichborneTrackerDB.rows[slot].cls   = cls
                    LichborneTrackerDB.rows[slot].level = m.level or 0
                    added = added + 1
                end
                -- Tier level → IP data (shown in the # column when "Show IP Tiers" is on)
                LichborneTrackerDB.ipData[m.name:lower()] = m.tierNum or 0
            else
                skipped = skipped + 1
            end
        end

        if PBM.RefreshRows then PBM.RefreshRows() end
        if PBM.State.overviewRowFrames and #PBM.State.overviewRowFrames > 0 then PBM.RefreshOverviewRows() end
        if PBM.State.raidRowFrames    and #PBM.State.raidRowFrames    > 0 then PBM.RefreshRaidRows()    end

        local msg = string.format(PBM_L["Exported LevelSync: |cff44ff44%s added|r, |cffd4af37%s updated|r"], tostring(added), tostring(updated))
        if skipped > 0 then msg = msg .. string.format(PBM_L[", |cffff6666%s skipped (unknown class)|r"], tostring(skipped)) end
        LichborneOutput("|cffC69B3APBM:|r "..msg, 1, 0.85, 0)
    end

    if not StaticPopupDialogs["PBM_EXPORT_LEVELSYNC"] then
        StaticPopupDialogs["PBM_EXPORT_LEVELSYNC"] = {
            text         = PBM_L["Are you sure you want to export LevelSync data?\n\nThis copies each synced character's |cffd4af37name, class, level, and IP tier|r into the PBM tracker."],
            button1      = "Yes",
            button2      = "No",
            OnAccept     = function() lsExportToPBM() end,
            timeout      = 0,
            whileDead    = true,
            hideOnEscape = true,
        }
    end

    -- ── Export button (red w/ gold text, bottom-right) ─────────
    local lsExportBtn = CreateFrame("Button", nil, lsPanel)
    lsExportBtn:SetSize(90, 24)
    lsExportBtn:SetPoint("BOTTOMRIGHT", lsPanel, "BOTTOMRIGHT", -LS_MARGIN, 12)
    lsExportBtn:SetFrameLevel(lspfl + 2)
    lsExportBtn:SetBackdrop(LT_BD_CELL)
    lsExportBtn:SetBackdropColor(0.30, 0.05, 0.05, 1)
    lsExportBtn:SetBackdropBorderColor(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B, 1.0)
    lsExportBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local lsExportLbl = lsExportBtn:CreateFontString(nil, "OVERLAY")
    lsExportLbl:SetFont(LT_FONT, 11, "OUTLINE"); lsExportLbl:SetAllPoints(lsExportBtn)
    lsExportLbl:SetJustifyH("CENTER"); lsExportLbl:SetText("|cffd4af37" .. (PBM_L["Export"] or "Export") .. "|r")
    lsExportBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.45, 0.08, 0.08, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(PBM_L["Export LevelSync Data"], 0.78, 0.61, 0.23)
        GameTooltip:AddLine(PBM_L["Copies name, class, level, and IP tier of every"], 0.8, 0.8, 0.8)
        GameTooltip:AddLine(PBM_L["synced character into the PBM tracker."], 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    lsExportBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.30, 0.05, 0.05, 1); GameTooltip:Hide()
    end)
    lsExportBtn:SetScript("OnClick", function() StaticPopup_Show("PBM_EXPORT_LEVELSYNC") end)

    -- ── Grid rebuild (called by state machine after CommitStatus) ──
    lsRebuildGrid = function()
        local d = lsData
        if d.inGroup then
            lsAccountsFS:SetText(string.format(PBM_L["Accounts: |cffd4af37%s/%s|r"], tostring(d.accountsCur), tostring(d.accountsMax)))
            lsTotalCharsFS:SetText(string.format(PBM_L["Characters: |cffd4af37%s|r"], tostring(d.totalChars)))
            lsLevelSyncFS:SetText(PBM_L["Level Sync: "] .. (d.levelSync and "|cff44dd44Available|r" or "|cffdd4444Disabled|r"))
            lsIpSyncFS:SetText(PBM_L["IP Sync: "] .. (d.ipSync and "|cff44dd44Available|r" or "|cffdd4444Disabled|r"))
        else
            lsAccountsFS:SetText(PBM_L["Accounts: —"]); lsTotalCharsFS:SetText(PBM_L["Characters: —"])
            lsLevelSyncFS:SetText(PBM_L["Level Sync: —"]); lsIpSyncFS:SetText(PBM_L["IP Sync: —"])
        end

        local accountOrder, accountMap = {}, {}
        for _, m in ipairs(d.members) do
            if not accountMap[m.accountId] then
                table.insert(accountOrder, m.accountId)
                accountMap[m.accountId] = {}
            end
            table.insert(accountMap[m.accountId], m)
        end

        for cellIdx = 1, 6 do
            local cell  = lsCells[cellIdx]
            local accId = accountOrder[cellIdx]
            if not accId then
                cell.hdrFS:SetTextColor(0.35, 0.35, 0.50); cell.hdrFS:SetText(PBM_L["— empty —"])
                cell.frame:SetBackdropBorderColor(0.25, 0.35, 0.55, 0.80)
                for r = 1, LS_SLOT_CNT do
                    cell.rows[r].nameFS:SetText(""); cell.rows[r].lvlFS:SetText("")
                    cell.rows[r].tierFS:SetText(""); cell.rows[r].removeBtn.charName = ""
                    cell.rows[r].removeBtn:Hide(); cell.rows[r].rowBtn.active = false
                    cell.rows[r].highlight:Hide()
                end
            else
                cell.hdrFS:SetTextColor(LT_GOLD_R, LT_GOLD_G, LT_GOLD_B)
                cell.hdrFS:SetText(PBM_L["Account "] .. accId)
                cell.frame:SetBackdropBorderColor(LT_GOLD_R*0.7, LT_GOLD_G*0.7, LT_GOLD_B*0.7, 0.9)
                local members = accountMap[accId]
                for r = 1, LS_SLOT_CNT do
                    local m = members[r]
                    if m then
                        local cr, cg, cb = lsHexRGB(LS_CLASS_COLORS[m.class])
                        cell.rows[r].nameFS:SetTextColor(cr, cg, cb)
                        cell.rows[r].nameFS:SetText(m.name)
                        cell.rows[r].lvlFS:SetTextColor(0.83, 0.69, 0.22)
                        cell.rows[r].lvlFS:SetText(tostring(m.level))
                        local tc = PBM.TIER_COLORS[m.tierNum] or PBM.TIER_COLORS[0]
                        cell.rows[r].tierFS:SetTextColor(tc.r, tc.g, tc.b)
                        cell.rows[r].tierFS:SetText(PBM.TIER_SHORT[m.tierNum] or "None")
                        cell.rows[r].removeBtn.charName = m.name
                        cell.rows[r].removeBtn:Show()
                        cell.rows[r].rowBtn.active = true
                    else
                        cell.rows[r].nameFS:SetText(""); cell.rows[r].lvlFS:SetText("")
                        cell.rows[r].tierFS:SetText(""); cell.rows[r].removeBtn.charName = ""
                        cell.rows[r].removeBtn:Hide(); cell.rows[r].rowBtn.active = false
                        cell.rows[r].highlight:Hide()
                    end
                end
            end
        end
    end
end