-- ============================================================
--  PBM_Windows.lua  |  Inventory, Spellbook, Talent windows
--
--  Ported directly from MultiBot addon with namespace rename.
--  Requires: PBM_Engine.lua (frame factory), PBM_TalentData.lua,
--            PBM_Item.lua, PBM_Spell.lua
-- ============================================================
PBM = PBM or {}

-- ── Parent frame for all multibot-style windows ──────────────
PBM._windowParent = CreateFrame("Frame", "PBMWindowParent", UIParent)
PBM._windowParent:SetAllPoints(UIParent)

-- ── State variables ──────────────────────────────────────────
PBM.auto   = PBM.auto   or { talent = false }
PBM.timer  = PBM.timer  or { talent = { elapsed = 0, interval = 3 } }
PBM.spells = PBM.spells or {}
PBM.data   = PBM.data   or {}
PBM.frames = PBM.frames or {}
PBM._waitFor = {}  -- [botName] = state string

-- ── Info strings (localization defaults) ─────────────────────
PBM.info = PBM.info or {}
PBM.info.talent = PBM.info.talent or {
    ["Points"] = PBM_L["Talent Points: "],
    ["Title"]  = PBM_L["Talents: NAME"],
    Apply      = PBM_L["Apply"],
    Copy       = PBM_L["Copy Target"],
    -- Class spec names (class..specNum)
    DeathKnight1 = PBM_L["Blood"],        DeathKnight2 = PBM_L["Frost"],        DeathKnight3 = PBM_L["Unholy"],
    Druid1       = PBM_L["Balance"],      Druid2       = PBM_L["Feral"],        Druid3       = PBM_L["Restoration"],
    Hunter1      = PBM_L["Beast"],        Hunter2      = PBM_L["Marks"],        Hunter3      = PBM_L["Survival"],
    Mage1        = PBM_L["Arcane"],       Mage2        = PBM_L["Fire"],         Mage3        = PBM_L["Frost"],
    Paladin1     = PBM_L["Holy"],         Paladin2     = PBM_L["Protection"],   Paladin3     = PBM_L["Retribution"],
    Priest1      = PBM_L["Discipline"],   Priest2      = PBM_L["Holy"],         Priest3      = PBM_L["Shadow"],
    Rogue1       = PBM_L["Assassination"], Rogue2      = PBM_L["Combat"],       Rogue3       = PBM_L["Subtlety"],
    Shaman1      = PBM_L["Elemental"],    Shaman2      = PBM_L["Enhancement"],  Shaman3      = PBM_L["Restoration"],
    Warlock1     = PBM_L["Affliction"],   Warlock2     = PBM_L["Demonology"],   Warlock3     = PBM_L["Destruction"],
    Warrior1     = PBM_L["Arms"],         Warrior2     = PBM_L["Fury"],         Warrior3     = PBM_L["Protection"],
}
PBM.info.inventory       = PBM_L["Inventory: NAME"]
PBM.info.spellbook       = PBM_L["Spellbook: NAME"]
PBM.info.target          = PBM_L["No target selected"]
PBM.info.action          = PBM_L["No action selected"]
PBM.info.itemsellalert   = PBM_L["Cannot sell Hearthstone!"]
PBM.info.keydestroyalert = PBM_L["Cannot destroy a key!"]
PBM.info.itemdestroyalert = PBM_L["Are you sure you want to destroy %s?"]
PBM.info.glyphsglyphsfor = PBM_L["Glyphs for"]

PBM.tips = PBM.tips or {}
PBM.tips.move = PBM.tips.move or {
    talent    = PBM_L["Move Talent Window"],
    inventory = PBM_L["Move Inventory Window"],
    spellbook = PBM_L["Move Spellbook Window"],
    stats     = PBM_L["Move Stats Window"],
}
PBM.tips.inventory = PBM.tips.inventory or {
    sell       = PBM_L["Sell selected item"],
    sellgrey   = PBM_L["Sell all grey items"],
    sellvendor = PBM_L["Sell all vendor items"],
    equip      = PBM_L["Equip item"],
    use        = PBM_L["Use item"],
    trade      = PBM_L["Trade item to you"],
    drop       = PBM_L["Destroy item"],
    open       = PBM_L["Open all containers"],
}

-- ════════════════════════════════════════════════════════════
-- INVENTORY FRAME
-- ════════════════════════════════════════════════════════════

PBM.inventory = PBM.newFrame(PBM._windowParent, -700, -144, 32, 442, 884)
PBM.inventory.addTexture("Interface\\AddOns\\PlayerBotManager\\Textures\\Inventory.blp")
PBM.inventory.addText("Title", PBM_L["Inventory"], "CENTER", -58, 429, 12)
PBM.inventory.action = "s"
PBM.inventory:SetMovable(true)
PBM.inventory:Hide()

PBM.inventory.movButton("Move", -406, 849, 34, PBM.tips.move.inventory)

PBM.inventory.wowButton("X", -126, 862, 15, 18, 13)
.doLeft = function(pButton)
	PBM.inventory:Hide()
end

PBM.inventory.addButton("Sell", -94, 806, "inv_misc_coin_16", PBM.tips.inventory.sell).setEnable()
.doLeft = function(pButton)
	if(pButton.state) then
		PBM.inventory.action = ""
		pButton.setDisable()
	else
		CancelTrade()
		PBM.inventory.action = "s"
		pButton.getButton("Destroy").setDisable()
		pButton.getButton("Equip").setDisable()
		pButton.getButton("Trade").setDisable()
		pButton.getButton("Use").setDisable()
		pButton.setEnable()
	end
end

-- Bouton vendre tous les objets gris (s *)
PBM.inventory.addButton("SellGrey", -94, 768, "inv_misc_coin_03", PBM.tips.inventory.sellgrey)
.doLeft = function(pButton)
    if not PBM.isTarget() then
        return
    end
		CancelTrade()
		PBM.inventory.action = ""
		pButton.getButton("Destroy").setDisable()
		pButton.getButton("Equip").setDisable()
		pButton.getButton("Trade").setDisable()
		pButton.getButton("Sell").setDisable()
		pButton.getButton("Use").setDisable()
		SendChatMessage("s *", "WHISPER", nil, pButton.getName())
    if PBM.RefreshInventory then
    	PBM.RefreshInventory(0.5)
    end
end

-- Bouton vendre tous les objets vendables (s vendor)
PBM.inventory.addButton("SellVendor", -94, 731, "inv_misc_coin_04", PBM.tips.inventory.sellvendor)
.doLeft = function(pButton)
    if not PBM.isTarget() then
        return
    end
        CancelTrade()
		PBM.inventory.action = ""
		pButton.getButton("Destroy").setDisable()
		pButton.getButton("Equip").setDisable()
		pButton.getButton("Trade").setDisable()
		pButton.getButton("Sell").setDisable()
		pButton.getButton("Use").setDisable()
		SendChatMessage("s vendor", "WHISPER", nil, pButton.getName())
		if PBM.RefreshInventory then
			PBM.RefreshInventory()
		end
end

PBM.inventory.addButton("Equip", -94, 694, "inv_helmet_22", PBM.tips.inventory.equip).setDisable()
.doLeft = function(pButton)
	if(pButton.state) then
		PBM.inventory.action = ""
		pButton.setDisable()
	else
		CancelTrade()
		PBM.inventory.action = "e"
		pButton.getButton("Destroy").setDisable()
		pButton.getButton("Trade").setDisable()
		pButton.getButton("Sell").setDisable()
		pButton.getButton("Use").setDisable()
		pButton.setEnable()
	end
end

PBM.inventory.addButton("Use", -94, 657, "inv_gauntlets_25", PBM.tips.inventory.use).setDisable()
.doLeft = function(pButton)
	if(pButton.state) then
		PBM.inventory.action = ""
		pButton.setDisable()
	else
		CancelTrade()
		PBM.inventory.action = "u"
		pButton.getButton("Destroy").setDisable()
		pButton.getButton("Equip").setDisable()
		pButton.getButton("Trade").setDisable()
		pButton.getButton("Sell").setDisable()
		pButton.setEnable()
	end
end

PBM.inventory.addButton("Trade", -94, 620, "achievement_reputation_01", PBM.tips.inventory.trade).setDisable()
.doLeft = function(pButton)
	if(pButton.state) then
		PBM.inventory.action = ""
		pButton.setDisable()
		CancelTrade()
	else
		InitiateTrade(pButton.getName())
		PBM.inventory.action = "give"
		pButton.getButton("Destroy").setDisable()
		pButton.getButton("Equip").setDisable()
		pButton.getButton("Sell").setDisable()
		pButton.getButton("Use").setDisable()
		pButton.setEnable()
	end
end

PBM.inventory.addButton("Destroy", -94, 583, "inv_hammer_15", PBM.tips.inventory.drop).setDisable()
.doLeft = function(pButton)
	if(pButton.state) then
		PBM.inventory.action = ""
		pButton.setDisable()
	else
		CancelTrade()
		PBM.inventory.action = "destroy"
		pButton.getButton("Equip").setDisable()
		pButton.getButton("Trade").setDisable()
		pButton.getButton("Sell").setDisable()
		pButton.getButton("Use").setDisable()
		pButton.setEnable()
	end
end

PBM.inventory.addButton("Open", -94, 322.5, "inv_misc_gift_05", PBM.tips.inventory.open)
.doLeft = function(pButton)
	SendChatMessage("open items", "WHISPER", nil, pButton.getName())
end

local tFrame = PBM.inventory.addFrame("Items", -397, 807, 32)
tFrame:Show()

-- ════════════════════════════════════════════════════════════
-- SPELLBOOK FRAME
-- ════════════════════════════════════════════════════════════

PBM.spellbook = PBM.newFrame(PBM._windowParent, -802, 302, 28, 336, 448)
PBM.spellbook.spells = {}
PBM.spellbook.icons = {}
PBM.spellbook.max = 1
PBM.spellbook.now = 1
PBM.spellbook:SetMovable(true)
PBM.spellbook:Hide()

for i = 1, GetNumMacroIcons() do PBM.spellbook.icons[GetMacroIconInfo(i)] = i end

local tFrame = PBM.spellbook.addFrame("Icon", -276, 392, 28, 50, 50)
tFrame.addTexture("Interface/Spellbook/Spellbook-Icon")
tFrame:SetFrameLevel(0)

local tFrame = PBM.spellbook.addFrame("TopLeft", -112, 224, 28, 224, 224)
tFrame.addTexture("Interface/ItemTextFrame/UI-ItemText-TopLeft")
tFrame:SetFrameLevel(1)

local tFrame = PBM.spellbook.addFrame("TopRight", -0, 224, 28, 112, 224)
tFrame.addTexture("Interface/Spellbook/UI-SpellbookPanel-TopRight")
tFrame:SetFrameLevel(2)

local tFrame = PBM.spellbook.addFrame("BottomLeft", -112, 0, 28, 224, 224)
tFrame.addTexture("Interface/ItemTextFrame/UI-ItemText-BotLeft")
tFrame:SetFrameLevel(3)

local tFrame = PBM.spellbook.addFrame("BottomRight", -0, 0, 28, 112, 224)
tFrame.addTexture("Interface/Spellbook/UI-SpellbookPanel-BotRight")
tFrame:SetFrameLevel(4)

local tOverlay = PBM.spellbook.addFrame("Overlay", -47, 81, 28, 258, 292)
tOverlay.addText("Title", PBM_L["Spellbook"], "CENTER", 14, 200, 13)
tOverlay.addText("Pages", "0/0", "CENTER", 14, 173, 13)
tOverlay:SetFrameLevel(5)

tOverlay.movButton("Move", -226, 310, 50, PBM.tips.move.spellbook, PBM.spellbook)

tOverlay.wowButton("<", -159, 309, 15, 18, 13)
.doLeft = function(pButton)
	PBM.spellbook.to = PBM.spellbook.to - 16
	PBM.spellbook.now = PBM.spellbook.now - 1
	PBM.spellbook.from = PBM.spellbook.from - 16
	PBM.spellbook.frames["Overlay"].setText("Pages", PBM.spellbook.now .. "/" .. PBM.spellbook.max)
	PBM.spellbook.frames["Overlay"].buttons[">"].doShow()

	if(PBM.spellbook.now == 1) then pButton.doHide() end
	local tIndex = 1

	for i = PBM.spellbook.from, PBM.spellbook.to do
		PBM.setSpell(tIndex, PBM.spellbook.spells[i], pButton.getName())
		tIndex = tIndex + 1
	end
end

tOverlay.wowButton(">", -59, 309, 15, 18, 11)
.doLeft = function(pButton)
	PBM.spellbook.to = PBM.spellbook.to + 16
	PBM.spellbook.now = PBM.spellbook.now + 1
	PBM.spellbook.from = PBM.spellbook.from + 16
	PBM.spellbook.frames["Overlay"].setText("Pages", PBM.spellbook.now .. "/" .. PBM.spellbook.max)
	PBM.spellbook.frames["Overlay"].buttons["<"].doShow()

	if(PBM.spellbook.now == PBM.spellbook.max) then pButton.doHide() end
	local tIndex = 1

	for i = PBM.spellbook.from, PBM.spellbook.to do
		PBM.setSpell(tIndex, PBM.spellbook.spells[i], pButton.getName())
		tIndex = tIndex + 1
	end
end

tOverlay.wowButton("X", 16, 336, 15, 18, 11)
.doLeft = function(pButton)
	PBM.spellbook:Hide()
end

tOverlay.addText("R01", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 44, -16, 11)
tOverlay.addText("T01", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 30, -2, 12)
local tButton = tOverlay.addButton("S01", -230, 264, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R02", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 172, -16, 11)
tOverlay.addText("T02", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 159, -2, 12)
local tButton = tOverlay.addButton("S02", -101, 264, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R03", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 44, -52, 11)
tOverlay.addText("T03", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 30, -38, 12)
local tButton = tOverlay.addButton("S03", -230, 228, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R04", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 172, -52, 11)
tOverlay.addText("T04", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 159, -38, 12)
local tButton = tOverlay.addButton("S04", -101, 228, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R05", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 44, -88, 11)
tOverlay.addText("T05", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 30, -74, 12)
local tButton = tOverlay.addButton("S05", -230, 192, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R06", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 172, -88, 11)
tOverlay.addText("T06", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 159, -74, 12)
local tButton = tOverlay.addButton("S06", -101, 192, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R07", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 44, -124, 11)
tOverlay.addText("T07", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 30, -110, 12)
local tButton = tOverlay.addButton("S07", -230, 156, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R08", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 172, -124, 11)
tOverlay.addText("T08", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 159, -110, 12)
local tButton = tOverlay.addButton("S08", -101, 156, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R09", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 44, -160, 11)
tOverlay.addText("T09", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 30, -146, 12)
local tButton = tOverlay.addButton("S09", -230, 120, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R10", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 172, -160, 11)
tOverlay.addText("T10", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 159, -146, 12)
local tButton = tOverlay.addButton("S10", -101, 120, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R11", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 44, -196, 11)
tOverlay.addText("T11", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 30, -182, 12)
local tButton = tOverlay.addButton("S11", -230, 84, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R12", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 172, -196, 11)
tOverlay.addText("T12", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 159, -182, 12)
local tButton = tOverlay.addButton("S12", -101, 84, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R13", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 44, -232, 11)
tOverlay.addText("T13", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 30, -218, 12)
local tButton = tOverlay.addButton("S13", -230, 48, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R14", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 172, -232, 11)
tOverlay.addText("T14", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 159, -218, 12)
local tButton = tOverlay.addButton("S14", -101, 48, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R15", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 44, -268, 11)
tOverlay.addText("T15", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 30, -254, 12)
local tButton = tOverlay.addButton("S15", -230, 12, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.addText("R16", "|cff402000" .. PBM_L["Rank"] .. "|r", "TOPLEFT", 172, -268, 11)
tOverlay.addText("T16", "|cffffcc00" .. PBM_L["Title"] .. "|r", "TOPLEFT", 159, -254, 12)
local tButton = tOverlay.addButton("S16", -101, 12, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	PBM.SpellToMacro(PBM.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, PBM.spellbook.name)
end

tOverlay.boxButton("C01", -214, 262, 16, true)
tOverlay.boxButton("C02",  -85, 262, 16, true)
tOverlay.boxButton("C03", -214, 226, 16, true)
tOverlay.boxButton("C04",  -85, 226, 16, true)
tOverlay.boxButton("C05", -214, 190, 16, true)
tOverlay.boxButton("C06",  -85, 190, 16, true)
tOverlay.boxButton("C07", -214, 154, 16, true)
tOverlay.boxButton("C08",  -85, 154, 16, true)
tOverlay.boxButton("C09", -214, 118, 16, true)
tOverlay.boxButton("C10",  -85, 118, 16, true)
tOverlay.boxButton("C11", -214,  82, 16, true)
tOverlay.boxButton("C12",  -85,  82, 16, true)
tOverlay.boxButton("C13", -214,  46, 16, true)
tOverlay.boxButton("C14",  -85,  46, 16, true)
tOverlay.boxButton("C15", -214,  10, 16, true)
tOverlay.boxButton("C16",  -85,  10, 16, true)

-- ════════════════════════════════════════════════════════════
-- TALENT FRAME
-- ════════════════════════════════════════════════════════════

PBM.talent = PBM.newFrame(PBM._windowParent, -104, -276, 28, 1024, 1024)
PBM.talent.addTexture("Interface\\AddOns\\PlayerBotManager\\Textures\\Talent.blp")
PBM.talent.addText("Points", PBM.info.talent["Points"], "CENTER", -228, -8, 13)
PBM.talent.addText("Title", PBM.info.talent["Title"], "CENTER", -228, 491, 13)
PBM.talent:SetMovable(true)
PBM.talent:Hide()

PBM.talent.movButton("Move", -960, 960, 64, PBM.tips.move.talent)

PBM.talent.wowButton(PBM.info.talent.Apply, -474, 966, 100, 20, 12).doHide()
.doLeft = function(pButton)
	local tValues = ""

	for i = 1, 3 do
		local tTab = PBM.talent.frames["Tab" .. i]

		for j = 1, table.getn(tTab.buttons) do
			tValues = tValues .. tTab.buttons[j].value
		end

		if(i < 3) then tValues = tValues .. "-" end
	end

	SendChatMessage("talents apply " ..tValues, "WHISPER", nil, PBM.talent.name)
	pButton.doHide()
end

local tApply = PBM.talent.buttons[ PBM.info.talent.Apply ]

PBM.talent.wowButton(PBM.info.talent.Copy, -854, 966, 100, 20, 12)
local copyBtn = PBM.talent.buttons[PBM.info.talent.Copy]

copyBtn.doLeft = function(pButton)
	local tName = UnitName("target")
	if(tName == nil or tName == "Unknown Entity") then return SendChatMessage(PBM.info.target, "SAY") end

	local tLocClass, tClass = UnitClass("target")
	if(PBM.talent.class ~= PBM.toClass(tClass)) then return SendChatMessage(PBM_L["The Classes do not match."], "SAY") end

	local tUnit = PBM.toUnit(PBM.talent.name)
	if(UnitLevel(tUnit) ~= UnitLevel("target")) then return SendChatMessage(PBM_L["The Levels do not match."], "SAY") end

	local tValues = ""

	for i = 1, 3 do
		local tTab = PBM.talent.frames["Tab" .. i]

		for j = 1, table.getn(tTab.buttons) do
			tValues = tValues .. tTab.buttons[j].value
		end

		if(i < 3) then tValues = tValues .. "-" end
	end

	SendChatMessage("talents apply " ..tValues, "WHISPER", nil, tName)
end

PBM.talent.wowButton("X", -470, 992, 17, 20, 13)
.doLeft = function(pButton)
	PBM.talent:Hide()
end

local tTab = PBM.talent.addFrame("Tab1", -830, 518, 28, 170, 408)
tTab.addTexture("Interface\\AddOns\\PlayerBotManager\\Textures\\White.blp")
tTab.addText("Title", PBM_L["Title"], "CENTER", 0, 214, 13)
tTab.arrows = {}
tTab.value = 0
tTab.id = 1

local tTab = PBM.talent.addFrame("Tab2", -656, 518, 28, 170, 408)
tTab.addTexture("Interface\\AddOns\\PlayerBotManager\\Textures\\White.blp")
tTab.addText("Title", PBM_L["Title"], "CENTER", 0, 214, 13)
tTab.arrows = {}
tTab.value = 0
tTab.id = 2

local tTab = PBM.talent.addFrame("Tab3", -482, 518, 28, 170, 408)
tTab.addTexture("Interface\\AddOns\\PlayerBotManager\\Textures\\White.blp")
tTab.addText("Title", PBM_L["Title"], "CENTER", 0, 214, 13)
tTab.arrows = {}
tTab.value = 0
tTab.id = 3

-- ACTUAL GLYPHES START --

-- Minimum level for each Socket (in order 1→6)
local socketReq = { 15, 15, 30, 50, 70, 80 }

local function ShowGlyphTooltip(self)
    local id = self.glyphID
    if not id then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    -- 1) try like a spell
    if GameTooltip:SetSpellByID(id) then
        return
    end

    -- 2) try like a item
    GameTooltip:SetHyperlink("item:"..id..":0:0:0:0:0:0:0")
end

local function HideGlyphTooltip()
    GameTooltip:Hide()
end

function PBM.FillDefaultGlyphs()
    local botName = PBM.talent.name
    local unit    = PBM.toUnit(botName)
    if not unit then return end

    -- rec is the table received from the handler, in the following format
    -- { [1]={id=…,type=…}, …, [6]={…} }
    local rec = PBM.receivedGlyphs and PBM.receivedGlyphs[botName]
    if not rec then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[PBM]|r " .. PBM_L["Waiting for glyphs…"])
        return
    end

    -- Derive the class key to access glyphDB
    local _, classFile = UnitClass(unit)
    local classKey = (classFile == "DEATHKNIGHT" and "DeathKnight")
                   or (classFile:sub(1,1) .. classFile:sub(2):lower())
    local glyphDB = PBM.data.talent.glyphs[classKey] or {}

    -- Loop through each slot i = 1..6
    for i, entry in ipairs(rec) do
        local id, typ = entry.id, entry.type
        local f = PBM.talent.frames["Tab4"].frames["Socket"..i]
        if f and f.frames then
            -- 1) Glow
            f.type, f.item = typ, id
            f.frames.Glow:Show()

            -- 2) Rune
            local raw = glyphDB[typ] and glyphDB[typ][id] or ""
            local _, runeIdx = strsplit(",%s*", raw)
            runeIdx = runeIdx or "1"
            local rFrame = f.frames.Rune
            if rFrame then
                rFrame:Hide()
                local runeTex = rFrame.texture or rFrame
                runeTex:SetTexture(PBM.SafeTexturePath("Interface\\Spellbook\\UI-Glyph-Rune"..runeIdx))
            end

            -- 3) Icon + Tooltip
            local tex = GetSpellTexture(id)
                     or select(10, GetItemInfo(id))
                     -- or "Interface\\Icons\\INV_Misc_QuestionMark"
					 or "Interface\\AddOns\\PlayerBotManager\\Textures\\UI-GlyphFrame-Glow.blp"
            local btn = f.frames.IconBtn
            if not btn then
                btn = CreateFrame("Button", nil, f)
                btn:SetAllPoints(f)
                btn:SetScript("OnEnter", ShowGlyphTooltip)
                btn:SetScript("OnLeave", HideGlyphTooltip)

                -- Creating the texture
                local icon = btn:CreateTexture(nil, "ARTWORK")
                icon:ClearAllPoints()
                icon:SetPoint("CENTER", btn, "CENTER", -9, 8)

                -- resizing
                local factor = (typ == "Major") and 0.64 or 0.66
                icon:SetSize(f:GetWidth() * factor, f:GetHeight() * factor)

                -- croping
                local crop = (typ == "Major") and 0.14 or 0.20
                icon:SetTexCoord(crop, 1 - crop, crop, 1 - crop)

                btn.icon = icon
                f.frames.IconBtn = btn
            end

            -- Update icon
            btn.glyphID = id
            btn.icon:SetTexture(PBM.SafeTexturePath(tex))
            btn:Show()

            -- Overlay circle
            local ov = f.frames.Overlay
            if ov and not ov.texture then
                ov.texture = ov:CreateTexture(nil, "BORDER")
                ov.texture:SetAllPoints(ov)
                local base = "Interface\\AddOns\\PlayerBotManager\\Textures\\"
                ov.texture:SetTexture(
                    base .. (typ == "Major"
                            and "gliph_majeur_layout.blp"
                            or "gliph_mineur_layout.blp"))
            end
            if ov then ov:Show() end
        end
    end

    -- Chat display (optional)
    local names = {}
    for _, entry in ipairs(rec) do
        local n = select(1, GetItemInfo(entry.id))   -- name of object (glyphe)
              or GetSpellInfo(entry.id)              -- fallback if no objecy
              or ("ID "..entry.id)
        table.insert(names,
            (entry.type=="Major" and "|cffffff00" or "|cff00ff00") .. n .. "|r")
    end
    --[[DEFAULT_CHAT_FRAME:AddMessage(
        "|cff66ccff[PBM]|r Glyphs for "..botName.." : "..table.concat(names, ", "))]]--
end

-- Add a custom background to the Glyphs Frame (tTab)
local tTab = PBM.talent.addFrame("Tab4", -513, 518, 28, 456, 430) -- offset x, offset y, strata level, widht, height
tTab.addFrame("Glow", 0, 0, 28, 456, 430).setAlpha(0.5).doHide()-- .addTexture("Interface/Spellbook/Talent_Glyphs_Glow.blp")
tTab.addTexture("Interface\\AddOns\\PlayerBotManager\\Textures\\Background-GlyphFrame.blp")
tTab:Hide()

local parentTab4 = PBM.talent.frames["Tab4"]   -- alias

-- Bouton “Apply Glyphs” – créé **une seule fois** :
gApply = parentTab4.wowButton(PBM_L["Apply Glyphs"], 0, 0, 100, 20, 12)
gApply:ClearAllPoints()
gApply:SetPoint("TOPRIGHT", parentTab4, "TOPRIGHT", -20, -20)
gApply:SetFrameLevel(parentTab4:GetFrameLevel() + 10)
gApply:Hide()          -- invisible till no modif
gApply:SetScript("OnClick", function()
    local ids = {}
    for i = 1, 6 do
        ids[i] = parentTab4.frames["Socket"..i].item or 0
    end
    local payload = "glyph equip " .. table.concat(ids, " ")
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[DBG]|r " ..
        (PBM.talent.name or "?") .. " : " .. payload)
    SendChatMessage(payload, "WHISPER", nil, PBM.talent.name)
    gApply:Hide()
end)

-- GLYPH:SOCKET1 --

-- Level 15
local tGlyph = tTab.addFrame("Socket1", -176.5, 310, 102) -- 1st socket at the top: Major (offset x, offset y, frame size)
tGlyph.addFrame("Glow",   0,  0, 102).setLevel(7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Slot-Major.blp")
tGlyph.addFrame("Rune", -29, 29,  44).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
tGlyph.frames = tGlyph.frames or {}
tGlyph.type = "Major"
tGlyph.item = 0

tGlyph.addFrame("Overlay", -12, 12, 96).setLevel(9).doHide()

-- GLYPH:SOCKET2 --

-- Level 15
local tGlyph = tTab.addFrame("Socket2", -187, 18.5, 82) -- Minor socket at the very bottom: Minor
tGlyph.addFrame("Glow",   0,  0, 82).setLevel(7).doHide().addTexture("Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp")
tGlyph.addFrame("Rune", -25, 25, 32).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
tGlyph.frames = tGlyph.frames or {}
tGlyph.type = "Minor"

tGlyph.addFrame("Overlay", -9, 9, 80).setLevel(9).doHide()

-- GLYPH:SOCKET3 --

-- Level 30
local tGlyph = tTab.addFrame("Socket3", -18.5, 50.5, 102) -- Bottom-right socket: Major
tGlyph.addFrame("Glow",   0,  0, 102).setLevel(7).doHide().addTexture("Interface\\Spellbook\\UI-Glyph-Slot-Major.blp")
tGlyph.addFrame("Rune", -29, 29,  44).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
tGlyph.frames = tGlyph.frames or {}
tGlyph.type = "Major"

tGlyph.addFrame("Overlay", -12, 12, 96) .setLevel(9).doHide()

-- GLYPH:SOCKET4 --

-- Level 50
local tGlyph = tTab.addFrame("Socket4", -302.5, 218, 82) -- Top-left socket: Minor
tGlyph.addFrame("Glow",   0,  0, 82).setLevel(7).doHide().addTexture("Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp")
tGlyph.addFrame("Rune", -25, 25, 32).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
tGlyph.frames = tGlyph.frames or {}
tGlyph.type = "Minor"

tGlyph.addFrame("Overlay", -9, 9, 80).setLevel(9).doHide()

-- GLYPH:SOCKET5 --

-- Level 70
local tGlyph = tTab.addFrame("Socket5", -72.5, 218, 82) -- Top-right socket: Minor
tGlyph.addFrame("Glow",   0,  0, 82).setLevel(7).doHide().addTexture("Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp")
tGlyph.addFrame("Rune", -25, 25, 32).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
tGlyph.frames = tGlyph.frames or {}
tGlyph.type = "Minor"

tGlyph.addFrame("Overlay", -9, 9, 80).setLevel(9).doHide()

-- GLYPH:SOCKET6 --

-- Level 80
local tGlyph = tTab.addFrame("Socket6", -336, 50.5, 102) -- Bottom-left socket: Major
tGlyph.addFrame("Glow",   0,  0, 102).setLevel(7).doHide().addTexture("Interface\\Spellbook\\UI-Glyph-Slot-Major.blp")
tGlyph.addFrame("Rune", -29, 29,  44).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
tGlyph.frames = tGlyph.frames or {}
tGlyph.type = "Major"

tGlyph.addFrame("Overlay", -12, 12, 96) .setLevel(9).doHide()

-- TAB TALENTS --
local tTab = PBM.talent.addFrame("Tab5", -900, 461, 28, 96, 24)
tTab.addTexture("Interface\\AddOns\\PlayerBotManager\\Textures\\Talent_Tab.blp")
tTab.wowButton(PBM_L["Talents"], -2, 6, 92, 17, 11)
.doLeft = function(pButton)
	if gApply then gApply:Hide() end
    -- Update UI
    PBM.talent.setText("Title", PBM.doReplace(PBM.info.talent.Title, "NAME", PBM.talent.name))
    PBM.talent.texts["Points"]:Show()
    PBM.talent.frames["Tab1"]:Show()
    PBM.talent.frames["Tab2"]:Show()
    PBM.talent.frames["Tab3"]:Show()
    PBM.talent.frames["Tab4"]:Hide()
	copyBtn:doShow()
end

-- TAB GLYPHS --
local tTab = PBM.talent.addFrame("Tab6", -800, 461, 28, 96, 24)
tTab.addTexture("Interface\\AddOns\\PlayerBotManager\\Textures\\Talent_Tab.blp")
tTab.wowButton(PBM_L["Glyphs"], -2, 6, 92, 17, 11)

.doLeft = function(pButton)
	if gApply then gApply:Hide() end
    -- UI
    PBM.talent.setText("Title", "|cffffff00" .. PBM.info.glyphsglyphsfor .. " |r" .. (PBM.talent.name or "?"))
    PBM.talent.texts["Points"]:Hide()
    PBM.talent.frames["Tab1"]:Hide()
    PBM.talent.frames["Tab2"]:Hide()
    PBM.talent.frames["Tab3"]:Hide()
    PBM.talent.frames["Tab4"]:Show()
	copyBtn:doHide()
    local botName = PBM.talent.name
    PBM.awaitGlyphs = botName
    SendChatMessage("glyphs", "WHISPER", nil, botName)
end

-- GLYPHES END --

-- ════════════════════════════════════════════════════════════
-- TALENT FUNCTIONS
-- ════════════════════════════════════════════════════════════

PBM.talent.setGrid = function(pTab)
	pTab.grid = {}
	pTab.grid.icons = {}
	pTab.grid.icons.size = pTab.size + 8
	pTab.grid.icons.x = pTab.width / 2 + pTab.grid.icons.size * 2 + 4
	pTab.grid.icons.y = pTab.height / 2 + pTab.grid.icons.size * 5.5 + 4
	pTab.grid.arrows = {}
	pTab.grid.arrows.size = pTab.grid.icons.size + 8
	pTab.grid.arrows.x = pTab.width / 2 + pTab.grid.icons.size * 2 - 4
	pTab.grid.arrows.y = pTab.height / 2 + pTab.grid.icons.size * 5.5 - 4
	pTab.grid.values = {}
	pTab.grid.values.x = pTab.width / 2 + pTab.grid.icons.size * 2
	pTab.grid.values.y = pTab.height / 2 + pTab.grid.icons.size * 5.5
	return pTab
end

PBM.talent.addArrow = function(pTab, pID, pNeeds, piX, piY, pTexture)
	local tArrow = pTab.addFrame("Arrow" .. pID, piX * pTab.grid.icons.size - pTab.grid.arrows.x, pTab.grid.arrows.y - piY * pTab.grid.icons.size, pTab.grid.arrows.size)
	tArrow.addTexture("Interface\\AddOns\\PlayerBotManager\\Textures\\Talent_Silver_" .. pTexture .. ".blp")
	tArrow.active = "Interface\\AddOns\\PlayerBotManager\\Textures\\Talent_Gold_" .. pTexture .. ".blp"
	tArrow.needs = pNeeds
	tArrow:SetFrameLevel(7)
	return tArrow
end

PBM.talent.addTalent = function(pTab, pID, pNeeds, pValue, pMax, piX, piY, pTexture, pTips)
	local tTalent = pTab.addButton(pID, piX * pTab.grid.icons.size - pTab.grid.icons.x, pTab.grid.icons.y - piY * pTab.grid.icons.size, pTexture, pTips[pValue + 1])
    tTalent:RegisterForClicks("LeftButtonUp", "RightButtonUp") 	-- Added for custom talents accept right and left click
	tTalent.points = piY * 5 - 5
	tTalent.needs = pNeeds
	tTalent.value = pValue
	tTalent.tips = pTips
	tTalent.max = pMax
	tTalent.id = pID

	tTalent.doLeft = function(pButton)
		if(PBM.talent.points == 0) then return end

		local tButtons = pButton.parent.buttons
		local tValue = pButton.parent.frames[pButton.id]
		local tTab = pButton.parent

		if(pButton.state == false) then return end
		if(pButton.value == pButton.max) then return end
		if(pButton.needs > 0 and tButtons[pButton.needs].value == 0) then return end

		PBM.talent.points = PBM.talent.points - 1
		PBM.talent.setText("Points", PBM.info.talent["Points"] .. PBM.talent.points)

		tTab.value = tTab.value + 1
		tTab.setText("Title", PBM.info.talent[pButton.getClass() .. tTab.id] .. " ("  .. tTab.value .. ")")

		pButton.value = pButton.value + 1
		pButton.tip = pButton.tips[pButton.value + 1]

		local tColor = PBM.IF(pButton.value < pButton.max, "|cff4db24d", "|cffffcc00")
		tValue.setText("Value", tColor .. pButton.value .. "/" .. pButton.max .. "|r")
		tValue:Show()

		for i = 1, table.getn(tButtons) do
			if(tButtons[i].points > tTab.value)
			then tButtons[i].setDisable()
			else
				if(tButtons[i].needs > 0)
				then if(tButtons[tButtons[i].needs].value > 0) then tButtons[i].setEnable() end
				else tButtons[i].setEnable()
				end
			end
		end

		PBM.talent.buttons[PBM.info.talent.Apply].doShow()
		PBM.talent.doState()
	end

	-- Add right click to remove custom Points
	-- Right click : –1 point
	tTalent.doRight = function(pButton)
		if pButton.value == 0 then return end          -- Nothing to remove

		local tTab   = pButton.parent                  -- Tab (tree)
		local tValue = tTab.frames[pButton.id]         -- Text 1/5

		-- Restore the global point
		PBM.talent.points = PBM.talent.points + 1
		PBM.talent.setText("Points",
			PBM.info.talent["Points"] .. PBM.talent.points)

		-- -- Update this talent + the tab
		pButton.value = pButton.value - 1
		pButton.tip   = pButton.tips[pButton.value + 1]
		tTab.value    = tTab.value  - 1
		-- Updates the title at the top of the tree
		tTab.setText("Title",
			PBM.info.talent[pButton.getClass() .. tTab.id] ..
			" (" .. tTab.value .. ")")

		-- Color based on rank
		local c = (pButton.value == 0)      and "|cffffffff"
			or (pButton.value < pButton.max) and "|cff4db24d"
			or "|cffffcc00"
		tValue.setText("Value",
			c .. pButton.value .. "/" .. pButton.max .. "|r")
		if PBM.talent.points == 0 and pButton.value == 0 then
			tValue:Hide()
		else
			tValue:Show()
		end

		-- -- Re-evaluate the state of all buttons/arrows
		PBM.talent.doState()

		-- -- Re-display the "Apply" button (modified build)
		PBM.talent.buttons[PBM.info.talent.Apply].doShow()
	end
		tTalent:SetFrameLevel(8)
		return tTalent
end

PBM.talent.addValue = function(pTab, pID, piX, piY, pRank, pMax)
	local tColor = PBM.IF(pRank > 0, PBM.IF(pRank < pMax, "|cff4db24d", "|cffffcc00"), "|cffffffff")
	local tValue = pTab.addFrame(pID, piX * pTab.grid.icons.size - pTab.grid.values.x, pTab.grid.values.y - piY * pTab.grid.icons.size, 24, 18, 12)
	tValue.addTexture("Interface\\AddOns\\PlayerBotManager\\Textures\\Talent_Black.blp")
	tValue.addText("Value", tColor .. pRank .. "/" .. pMax .. "|r", "CENTER", -0.5, 1, 10)
	if(PBM.talent.points == 0 and pRank == 0) then tValue:Hide() end
	tValue:SetFrameLevel(9)
	return tValue
end

PBM.talent.setTalents = function()
    -- 1) Check datas
    local tClass = PBM.data.talent.talents[ PBM.talent.class ]
    if not tClass then
        print("|cffff0000[PBM] " .. PBM_L["No build found for class "]
              .. tostring(PBM.talent.class) .. "!|r")
        return
    end

    local tArrow = PBM.data.talent.arrows[ PBM.talent.class ]
    if not tArrow then
        print("|cffff0000[PBM] " .. PBM_L["No arrow schem found for class "]
              .. tostring(PBM.talent.class) .. "!|r")
        return
    end

	local activeGroup = GetActiveTalentGroup(true) or 1

    -- No talents loaded yet ? we retry in 0,1 s
    if not GetTalentInfo(1, 1, true) then
        TimerAfter(0.1, PBM.talent.setTalents)
        return
    end

    -- 2) Frame update
    PBM.talent.points = tonumber(GetUnspentTalentPoints(true))
    PBM.talent.setText("Points",
        PBM.info.talent["Points"] .. PBM.talent.points)
    PBM.talent.setText("Title",
        PBM.doReplace(PBM.info.talent["Title"], "NAME",
                           PBM.talent.name))

    for i = 1, 3 do
        local tMarker = PBM.talent.class .. i
        local tTab    = PBM.talent.setGrid(
                            PBM.talent.frames["Tab" .. i])
        tTab.setTexture("Interface\\AddOns\\PlayerBotManager\\Textures\\Talent_" ..
                        tMarker .. ".blp")
        tTab.value, tTab.id = 0, i

        -- arrows
        for j = 1, #tArrow[i] do
            local tData = PBM.doSplit(tArrow[i][j], ", ")
            local tNeed = tonumber(tData[1])
            tTab.arrows[j] = PBM.talent.addArrow(
                                 tTab, j, tNeed, tData[2], tData[3], tData[4])
        end

        -- talents
        for j = 1, #tClass[i] do
            local link = GetTalentLink(i,j,true,nil,activeGroup)

            local tTale = PBM.doSplit(PBM.doSplit(link, "|")[3], ":")[2]

            local iName, iIcon, iTier, iColumn, iRank = GetTalentInfo(i, j, true, nil, activeGroup)

            if not iName then
                TimerAfter(0.1, PBM.talent.setTalents)
                return
            end

            local tData = PBM.doSplit(tClass[i][j], ", ")
            local tMax  = #tData - 4
            local tNeed = tonumber(tData[1])
            local tRank = tonumber(iRank)
            local tTips = {}

            tTab.value = tTab.value + tRank
            table.insert(tTips,
                "|cff4e96f7|Htalent:" .. tTale ..":-1|h[" .. iName .. "]|h|r")
            for k = 5, #tData do
                table.insert(tTips,
                    "|cff4e96f7|Htalent:" .. tTale ..":" .. (k - 5) ..
                    "|h[" .. iName .. "]|h|r")
            end

            PBM.talent.addTalent(
                tTab, j, tNeed, tRank, tMax,
                tData[2], tData[3], tData[4], tTips)
            PBM.talent.addValue(
                tTab, j, tData[2], tData[3], tRank, tMax)
        end

        tTab.setText("Title",
            PBM.info.talent[tMarker] .. " (" .. tTab.value .. ")")
    end

    -- 3) Final display
    PBM.talent.doState()
	PBM.talent:Show()
	PBM.auto.talent = false
end

PBM.talent.doState = function()
	for i = 1, 3 do
		local tTab = PBM.talent.frames["Tab" .. i]

		for j = 1, table.getn(tTab.buttons) do
			local tTalent = tTab.buttons[j]
			local tValue = tTab.frames[j]

			if(PBM.talent.points == 0) then
				if(tTalent.value == 0) then
					tTalent.setDisable(false)
					tValue:Hide()
				else
					tTalent.setEnable(false)
					tValue:Show()
				end
			else
				if(tTab.value < tTalent.points) then
					tTalent.setDisable(false)
					tValue:Hide()
				else
					tTalent.setEnable(false)
					tValue:Show()
				end
			end
		end

		for j = 1, table.getn(tTab.arrows) do
			if(tTab.buttons[tTab.arrows[j].needs].value > 0) then
				tTab.arrows[j].setTexture(tTab.arrows[j].active)
			end
		end
	end
end

PBM.talent.doClear = function()
	for i = 1, 3 do
		local tTab = PBM.talent.frames["Tab" .. i]
		for j = 1, table.getn(tTab.buttons) do tTab.buttons[j]:Hide() end
		for j = 1, table.getn(tTab.frames) do tTab.frames[j]:Hide() end
		for j = 1, table.getn(tTab.arrows) do tTab.arrows[j]:Hide() end
		table.wipe(tTab.buttons)
		table.wipe(tTab.frames)
		table.wipe(tTab.arrows)
		tTab.buttons = {}
		tTab.frames = {}
		tTab.arrows = {}
	end
end

-- ════════════════════════════════════════════════════════════
-- ONUPDATE TIMER (talent auto-display after InspectUnit)
-- ════════════════════════════════════════════════════════════

local _timerFrame = CreateFrame("Frame")
_timerFrame:SetScript("OnUpdate", function(self, elapsed)
	if PBM.auto.talent then
		PBM.timer.talent.elapsed = PBM.timer.talent.elapsed + elapsed
		if PBM.timer.talent.elapsed >= PBM.timer.talent.interval then
			PBM.talent.setTalents()
			PBM.timer.talent.elapsed = 0
			PBM.auto.talent = false
		end
	end
end)

-- ════════════════════════════════════════════════════════════
-- WHISPER HANDLER (inventory/spellbook data parsing)
-- ════════════════════════════════════════════════════════════

local _whisperFrame = CreateFrame("Frame")
_whisperFrame:RegisterEvent("CHAT_MSG_WHISPER")
_whisperFrame:SetScript("OnEvent", function(self, event, msg, sender)
	local waitFor = PBM._waitFor[sender]
	if not waitFor then return end

	-- ── Inventory ──
	if waitFor == "INVENTORY" and PBM.isInside(msg, "Inventory") then
		local tItems = PBM.inventory.frames["Items"]
		for key, value in pairs(tItems.buttons) do value:Hide() end
		for key in pairs(tItems.buttons) do tItems.buttons[key] = nil end
		PBM.inventory.setText("Title", PBM.doReplace(PBM.info.inventory, "NAME", sender))
		PBM.inventory.name = sender
		tItems.index = 0
		PBM._waitFor[sender] = "ITEM"
		SendChatMessage("stats", "WHISPER", nil, sender)
		return
	end

	if waitFor == "ITEM" and (PBM.beInside(msg, "Bag,", "Dur") or PBM.beInside(msg, "背包", "耐久度")) then
		PBM.inventory:Show()
		PBM._waitFor[sender] = nil
		return
	end

	if waitFor == "ITEM" then
		if string.sub(msg, 1, 3) == "---" then return end
		PBM.addItem(PBM.inventory.frames["Items"], msg)
		return
	end

	-- ── Spellbook ──
	if waitFor == "SPELLBOOK" and PBM.isInside(msg, "Spells") then
		local tOverlay = PBM.spellbook.frames["Overlay"]
		local tSpellbook = PBM.spellbook
		for key in pairs(tSpellbook.spells) do tSpellbook.spells[key] = nil end
		tOverlay.setText("Title", PBM.doReplace(PBM.info.spellbook, "NAME", sender))
		tSpellbook.name = sender
		tSpellbook.index = 0
		tSpellbook.from = 1
		tSpellbook.to = 16
		PBM._waitFor[sender] = "SPELL"
		SendChatMessage("stats", "WHISPER", nil, sender)
		return
	end

	if waitFor == "SPELL" and PBM.isInside(msg, "Bag,", "Dur", "XP") then
		local tOverlay = PBM.spellbook.frames["Overlay"]
		local tSpellbook = PBM.spellbook
		tSpellbook.now = 1
		tSpellbook.max = math.ceil(tSpellbook.index / 16)
		tOverlay.setText("Pages", "|cffffffff" .. tSpellbook.now .. "/" .. tSpellbook.max .. "|r")
		if tSpellbook.now == tSpellbook.max then tOverlay.buttons[">"].doHide() else tOverlay.buttons[">"].doShow() end
		tOverlay.buttons["<"].doHide()
		tSpellbook:Show()
		PBM._waitFor[sender] = nil
		return
	end

	if waitFor == "SPELL" then
		PBM.addSpell(msg, sender)
		return
	end
end)

-- ════════════════════════════════════════════════════════════
-- PUBLIC API  (called by PBM_MultibotPanel.lua buttons)
-- ════════════════════════════════════════════════════════════

--- Open the talent window for a bot.
-- Checks InspectUnit conflicts with PBM, then fires InspectUnit + 3-sec timer.
function PBM.OpenTalentWindow(botName)
	if not botName or botName == "" then return end

	local unit = PBM.NameToUnit(botName)
	if not unit then
		DEFAULT_CHAT_FRAME:AddMessage("|cffFFAA00PBM:|r " .. botName .. PBM_L[" is not in your group."])
		return
	end

	-- Level check
	local level = UnitLevel(unit)
	if level and level < 10 then
		DEFAULT_CHAT_FRAME:AddMessage("|cffFFAA00PBM:|r " .. botName .. PBM_L[" must be level 10+ for talents."])
		return
	end

	-- Range check
	if not CheckInteractDistance(unit, 1) then
		DEFAULT_CHAT_FRAME:AddMessage("|cffFFAA00PBM:|r " .. botName .. PBM_L[" is too far away to inspect."])
		return
	end

	-- InspectUnit conflict prevention with PBM
	if PBM and PBM.State then
		if PBM.State.LichborneInspectTarget then
			DEFAULT_CHAT_FRAME:AddMessage("|cffFFAA00PBM:|r " .. PBM_L["Cannot inspect — PBM gear/spec scan in progress."])
			return
		end
		if PBM.State.LichborneGroupScanActive then
			DEFAULT_CHAT_FRAME:AddMessage("|cffFFAA00PBM:|r " .. PBM_L["Cannot inspect — PBM group scan in progress."])
			return
		end
	end

	-- Get class for talent data lookup
	local _, classFile = UnitClass(unit)
	local classKey = PBM.toClass(classFile)

	-- Clear previous talent data and set up new request
	PBM.talent.doClear()
	PBM.talent.name = botName
	PBM.talent.class = classKey

	-- Show talent tabs, hide glyph tab
	PBM.talent.frames["Tab1"]:Show()
	PBM.talent.frames["Tab2"]:Show()
	PBM.talent.frames["Tab3"]:Show()
	if PBM.talent.frames["Tab4"] then PBM.talent.frames["Tab4"]:Hide() end

	-- Fire InspectUnit and start the 3-second timer
	NotifyInspect(unit)
	PBM.auto.talent = true
	PBM.timer.talent.elapsed = 0
end

--- Open the inventory window for a bot.
-- Sets waitFor state, sends "items" whisper to trigger bot response.
function PBM.OpenInventoryWindow(botName)
	if not botName or botName == "" then return end

	-- If already waiting for this bot, don't double-send
	if PBM._waitFor[botName] then
		DEFAULT_CHAT_FRAME:AddMessage("|cffFFAA00PBM:|r " .. PBM_L["Already waiting for "] .. botName .. PBM_L[" data."])
		return
	end

	PBM._waitFor[botName] = "INVENTORY"
	PBM.inventory.name = botName
	SendChatMessage("items", "WHISPER", nil, botName)
end

--- Open the spellbook window for a bot.
-- Sets waitFor state, sends "spells" whisper to trigger bot response.
function PBM.OpenSpellbookWindow(botName)
	if not botName or botName == "" then return end

	-- If already waiting for this bot, don't double-send
	if PBM._waitFor[botName] then
		DEFAULT_CHAT_FRAME:AddMessage("|cffFFAA00PBM:|r " .. PBM_L["Already waiting for "] .. botName .. PBM_L[" data."])
		return
	end

	PBM._waitFor[botName] = "SPELLBOOK"
	PBM.spellbook.name = botName
	SendChatMessage("spells", "WHISPER", nil, botName)
end