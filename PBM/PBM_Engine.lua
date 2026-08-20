PBM = PBM or {}
PBM.frames = PBM.frames or {}

PBM.CLEAR = function(pString, pAmount, o1, o2, o3)
	for i = 1, pAmount, 1 do
		if(o1 == nil) then
			pString = PBM.doReplace(pString, "|cff%w%w%w%w%w%w", "")
			pString = PBM.doReplace(pString, "|h", "")
			pString = PBM.doReplace(pString, "|r", "")
		else
			if(o1 ~= nil) then pString = PBM.doReplace(pString, o1, "") end
			if(o2 ~= nil) then pString = PBM.doReplace(pString, o1, "") end
			if(o3 ~= nil) then pString = PBM.doReplace(pString, o1, "") end
		end
	end

	return pString
end

PBM.CASE = function(pCondition, pDefault, oCase1, oCase2, oCase3, oCase4, oCase5, oCase6, oCase7, oCase8, oCase9)
	if(pCondition == 1 and oCase1 ~= nil) then return oCase1 end
	if(pCondition == 2 and oCase2 ~= nil) then return oCase2 end
	if(pCondition == 3 and oCase3 ~= nil) then return oCase3 end
	if(pCondition == 4 and oCase4 ~= nil) then return oCase4 end
	if(pCondition == 5 and oCase5 ~= nil) then return oCase5 end
	if(pCondition == 6 and oCase6 ~= nil) then return oCase6 end
	if(pCondition == 7 and oCase7 ~= nil) then return oCase7 end
	if(pCondition == 8 and oCase8 ~= nil) then return oCase8 end
	if(pCondition == 9 and oCase9 ~= nil) then return oCase9 end
	return pDefault
end

PBM.IF = function(pCondition, pSuccess, pFailure)
	if(pCondition) then return pSuccess else return pFailure end
end

PBM.doSlash = function(pCommand, pArguments)
	local tCommand = string.upper(string.sub(pCommand, 2))

	for tKey, tFunc in pairs(SlashCmdList) do
		if(tKey == tCommand) then
			tFunc(pArguments)
			return true
		end
	end

	SendChatMessage(PBM.info.command, "SAY")
	return false
end

PBM.doDot = function(pCommand, oArguments)
	SendChatMessage(pCommand .. " " .. oArguments)
	return false
end

PBM.doDotWithTarget = function(pCommand, oArguments)
	local tName = UnitName("target")

	if(tName ~= nil and tName ~= "Unknown Entity") then
		if(oArguments ~= nil)
		then SendChatMessage(pCommand .. " " .. tName .. " " .. oArguments)
		else SendChatMessage(pCommand .. " " .. tName)
		end

		return true
	end

	SendChatMessage(PBM.info.target, "SAY")
	return false
end

PBM.doSplit = function(pString, pPattern)
    if not pString or pString == "" then -- Secure function if pString empty
        return {}
    end
	local tResult = {}
	local tStart = 1
	local tFrom, tTo = string.find(pString, pPattern, tStart)

	while tFrom do
		table.insert(tResult, string.sub(pString, tStart, tFrom - 1))
		tStart = tTo + 1
		tFrom, tTo = string.find(pString, pPattern, tStart)
	end

	table.insert(tResult, string.sub(pString, tStart))
	return tResult
end

PBM.doReplace = function(pString, pSearch, pReplace)
	local tFrom, tTo = string.find(pString, pSearch)
	if(tFrom == nil or tTo == nil) then return pString end
	return string.sub(pString, 1, tFrom - 1) .. pReplace .. string.sub(pString, tTo + 1)
end

PBM.doRemove = function(pIndex, pName)
	if(pIndex == nil) then return end
	local tFound = 0

	--for i = 1, table.getn(pIndex) do
	for i = 1, #pIndex do
		if(pIndex[i] == pName) then
			tFound = i
			break
		end
	end

	if(tFound == 0) then return false end
	table.remove(pIndex, tFound)
	return true
end

PBM.doRepos = function(pIndex, pOffsetX)
	local tButton = PBM.frames["MultiBar"].buttons[pIndex]
	local tFrame = PBM.frames["MultiBar"].frames[pIndex]
	if(tButton == nil) then tButton = PBM.frames["MultiBar"].frames["Left"].buttons[pIndex] end
	if(tFrame == nil) then tFrame = PBM.frames["MultiBar"].frames["Left"].frames[pIndex] end
	if(tButton == nil) then tButton = PBM.frames["MultiBar"].frames["Right"].buttons[pIndex] end
	if(tFrame == nil) then tFrame = PBM.frames["MultiBar"].frames["Right"].frames[pIndex] end
	if(tButton ~= nil) then tButton.setPoint(tButton.x + pOffsetX, tButton.y) end
	if(tFrame ~= nil) then tFrame.setPoint(tFrame.x + pOffsetX, tFrame.y) end
	return true
end

PBM.isActive = function(pName)
	for key, value in pairs(PBM.index.actives) do if(value == pName) then return true end end
	return false
end

--[[PBM.isInside = function(pString, p1stPattern, o2ndPattern, o3rdPattern,
    o4thPattern, o5thPattern, o6thPattern, o7thPattern, o8thPattern, o9thPattern)
	if(pString == nil) then return false end
	if(p1stPattern ~= nil and string.find(pString, p1stPattern)) then return true end
	if(o2ndPattern ~= nil and string.find(pString, o2ndPattern)) then return true end
	if(o3rdPattern ~= nil and string.find(pString, o3rdPattern)) then return true end
	if(o4thPattern ~= nil and string.find(pString, o4thPattern)) then return true end
	if(o5thPattern ~= nil and string.find(pString, o5thPattern)) then return true end
	if(o6thPattern ~= nil and string.find(pString, o6thPattern)) then return true end
	if(o7thPattern ~= nil and string.find(pString, o7thPattern)) then return true end
	if(o8thPattern ~= nil and string.find(pString, o8thPattern)) then return true end
	if(o9thPattern ~= nil and string.find(pString, o9thPattern)) then return true end
	return false
end]]--

PBM.isInside = function(pString, ...)
	if(pString == nil) then return false end
	for i = 1, select("#", ...) do
		local pattern = select(i, ...)
		if(pattern ~= nil and string.find(pString, pattern)) then
			return true
		end
	end
	return false
end

--[[PBM.beInside = function(pString, p1stPattern, o2ndPattern, o3rdPattern,
    o4thPattern, o5thPattern, o6thPattern, o7thPattern, o8thPattern, o9thPattern)
	if(pString == nil) then return false end
	if(p1stPattern ~= nil and nil == string.find(pString, p1stPattern)) then return false end
	if(o2ndPattern ~= nil and nil == string.find(pString, o2ndPattern)) then return false end
	if(o3rdPattern ~= nil and nil == string.find(pString, o3rdPattern)) then return false end
	if(o4thPattern ~= nil and nil == string.find(pString, o4thPattern)) then return false end
	if(o5thPattern ~= nil and nil == string.find(pString, o5thPattern)) then return false end
	if(o6thPattern ~= nil and nil == string.find(pString, o6thPattern)) then return false end
	if(o7thPattern ~= nil and nil == string.find(pString, o7thPattern)) then return false end
	if(o8thPattern ~= nil and nil == string.find(pString, o8thPattern)) then return false end
	if(o9thPattern ~= nil and nil == string.find(pString, o9thPattern)) then return false end
	return true
end]]--

PBM.beInside = function(pString, ...)
	if(pString == nil) then return false end
	for i = 1, select("#", ...) do
		local pattern = select(i, ...)
		if(pattern ~= nil and nil == string.find(pString, pattern)) then
			return false
		end
	end
	return true
end

PBM.isRoster = function(pRoster, pName)
	for key, value in pairs(PBM.index[pRoster]) do if(pName == value) then return true end end
	return false
end

PBM.isMember = function(pName)
	if(GetNumRaidMembers() > 5) then
		for i = 1, GetNumRaidMembers() do
			if(UnitName("raid" .. i) == pName) then return true end
		end
	end

	if(GetNumPartyMembers() > 0) then
		for i = 1, 4 do
			if(UnitName("party" .. i) == pName) then return true end
		end
	end

	if(UnitName("player") == pName) then
		return true
	end

	return false
end

PBM.isTarget = function()
	local tName = UnitName("target")

	if(tName ~= nil and tName ~=  "Unknown Entity") then
		return true
	end

	SendChatMessage(PBM.info.target, "SAY")
	return false
end

PBM.isUnit = function(pUnit)
	local tName = UnitName(pUnit)

	if(tName == nil or tName == "Unknown Entity") then
		return false
	end

	return true
end

-- Safe texture resolver to avoid calling string.sub on nil and to normalize paths
-- Returns a usable texture path string. Falls back to the question mark icon.
PBM.SafeTexturePath = function(pTexture)
	-- Guard: nil or non-string => fallback
	if type(pTexture) ~= "string" or pTexture == "" then
		return "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	-- Si l’appelant fournit déjà un chemin (avec / ou \), on le considère explicite
	-- et on le renvoie tel quel, après normalisation vers "\"
    local tex = pTexture:gsub("/", "\\")
	if tex:find("\\", 1, true) then
		return tex
	end
	-- Normalize: only prefix when not already an Interface path
	local head = string.sub(tex, 1, 9)
	local needsPrefix = string.lower(head) ~= "interface"
	if needsPrefix then
        return "Interface\\Icons\\" .. tex
	end
    return tex
end



--[[PBM.toClass = function(pClass)
	local pLower = string.lower(pClass)
	local pStart = string.sub(pLower, 1, 5)

	for i = 1, 10 do
		local tOutput = PBM.data.classes.output[i]
		local tInput = PBM.data.classes.input[i]
		local tLower = string.lower(tInput)
		local tStart = string.sub(tLower, 1, 5)

		if(pClass == tInput) then return tOutput end
		if(pLower == tLower) then return tOutput end
		if(pStart == tStart) then return tOutput end
	end

	local tClass = string.lower(string.sub(pClass, 1, 1) .. string.sub(pClass, 4, 4))
	if(tClass == "te" or tClass == "dt") then return "DeathKnight" end
	if(tClass == "di" or tClass == "di") then return "Druid" end
	if(tClass == "jg" or tClass == "ht") then return "Hunter" end
	if(tClass == "mi" or tClass == "me") then return "Mage" end
	if(tClass == "pa" or tClass == "pa") then return "Paladin" end
	if(tClass == "pe" or tClass == "pe") then return "Priest" end
	if(tClass == "su" or tClass == "ru") then return "Rogue" end
	if(tClass == "sa" or tClass == "sm") then return "Shaman" end
	if(tClass == "he" or tClass == "wl") then return "Warlock" end
	if(tClass == "ke" or tClass == "wr") then return "Warrior" end
	if(pClass == "dk") then return "DeathKnight" end
	return "Unknown"
end]]--

-- Classe refactor
-- Sauvegarde l’ancienne version si elle existait avant refactor
if not PBM._toClass_legacy and type(PBM.toClass) == "function" then
  PBM._toClass_legacy = PBM.toClass
end

-- Class token → TalentData key mapping
local _classMap = {
	DEATHKNIGHT = "DeathKnight", DRUID = "Druid", HUNTER = "Hunter",
	MAGE = "Mage", PALADIN = "Paladin", PRIEST = "Priest",
	ROGUE = "Rogue", SHAMAN = "Shaman", WARLOCK = "Warlock",
	WARRIOR = "Warrior",
	-- Also accept already-formatted keys
	DeathKnight = "DeathKnight", Druid = "Druid", Hunter = "Hunter",
	Mage = "Mage", Paladin = "Paladin", Priest = "Priest",
	Rogue = "Rogue", Shaman = "Shaman", Warlock = "Warlock",
	Warrior = "Warrior",
}
PBM.toClass = function(pClass)
	if not pClass then return "Unknown" end
	return _classMap[pClass] or _classMap[string.upper(pClass)] or "Unknown"
end

PBM.toUnit = function(pName)
	if(GetNumRaidMembers() > 5) then
		for i = 1, GetNumRaidMembers() do
			if(UnitName("raid" .. i) == pName) then
				return "raid" .. i
			end
		end
	end

	if(GetNumPartyMembers() > 0) then
		for i = 1, GetNumPartyMembers() do
			if(UnitName("party" .. i) == pName) then
				return "party" .. i
			end
		end
	end

	if(UnitName("player") == pName) then
		return "player"
	end

	return nil
end

PBM.toTip = function(pClass, pLevel, pName)
	local tTip = pClass .. " - "
	if(pLevel ~= nil) then tTip = tTip .. pLevel .. " - " end
	tTip = tTip .. pName .. PBM.tips.unit.button
	tTip = PBM.doReplace(tTip, PBM_L["NAME"], pName)
	tTip = PBM.doReplace(tTip, PBM_L["NAME"], pName)
	tTip = PBM.doReplace(tTip, PBM_L["NAME"], pName)
	return tTip
end

--[[PBM.toPoint = function(pFrame)
	local tX = pFrame:GetRight()
	local tY = pFrame:GetBottom()
	local tResolution = PBM.doSplit(({ GetScreenResolutions() })[GetCurrentResolution()], "x")
	local tHeight = tonumber(tResolution[2])
	local tWidth = tonumber(tResolution[1])
	local tScale = 1 / tWidth * PBM:GetRight()
	return math.floor(tX - (tWidth * tScale)), math.floor(tY)
end]]--

PBM.toPoint = function(pFrame)
    -- Mesurer par rapport au parent global stable et arrondir à l’unité.
    local uiRight = (UIParent and UIParent:GetRight()) or GetScreenWidth()
    local xRight  = pFrame:GetRight() or 0
    local yBottom = pFrame:GetBottom() or 0
    -- Offset vers BOTTOMRIGHT (négatif ou nul)
    local offX = xRight - uiRight
    local offY = yBottom
    -- Arrondi au plus proche pour éviter la dérive cumulée
    return math.floor(offX + 0.5), math.floor(offY + 0.5)
end

PBM.RaidPool = function(pUnit, oWho)
	if(pUnit ~= "player" and PBM.getBot(pUnit) == nil) then return end

	local tGender = PBM.CASE(UnitSex(pUnit), "[U]", "[N]", "[M]", "[F]")
	local tLocalClass, tClass = UnitClass(pUnit)
	local tLocalRace, tRace = UnitRace(pUnit)
	local tLevel = UnitLevel(pUnit)
	local tName = UnitName(pUnit)
	local tIndex = { 4, 5, 6 }
	local tTabs = {}
	--local tScore = ""
	local tScore

	if(oWho ~= nil) then
		local tWho = PBM.CLEAR(oWho, 20)
		tWho = PBM.doReplace(tWho, "beast mastery", "Beast-Mastery")
		tWho = PBM.doReplace(tWho, "feral combat", "Feral-Combat")
		tWho = PBM.doReplace(tWho, "Blood Elf", "Blood-Elf")
		tWho = PBM.doReplace(tWho, "Night Elf", "Night-Elf")

		tParts = PBM.doSplit(tWho, ", ")
		tSpace = PBM.doSplit(tParts[1], " ")
		tScore = PBM.doSplit(tParts[2], " ")[1]

		if(PBM.isInside(tSpace[5], "/")) then tIndex = { 5, 6, 7 } else
		if(PBM.isInside(tSpace[6], "/")) then tIndex = { 6, 7, 8 } else
		if(PBM.isInside(tSpace[7], "/")) then tIndex = { 7, 8, 9 }
		end end end

		tTabs = PBM.doSplit(strsub(tSpace[tIndex[1]], 2, strlen(tSpace[tIndex[1]]) - 1), "/")

		if(tGender == nil) then tGender = tSpace[2] end
		if(tClass == nil) then tClass = PBM.toClass(tSpace[tIndex[2]]) end
		if(tRace == nil) then tRace = tSpace[1] end
		if(tName == nil) then tName = pUnit end
		if(tLevel == nil) then tLevel = substr(PBM.doSplit(tSpace[tIndex[3]], " ")[1], 2) end
	else
		tScore = PBM.ItemLevel(pUnit)
		tTabs[1] = GetNumTalents(1)
		tTabs[2] = GetNumTalents(2)
		tTabs[3] = GetNumTalents(3)
	end

	   --[[-- [SAFETY] tTabs doivent être numériques
       tTabs[1] = tonumber(tTabs[1]) or 0
       tTabs[2] = tonumber(tTabs[2]) or 0
       tTabs[3] = tonumber(tTabs[3]) or 0

       -- [SAFETY] iLevel : toujours un nombre, même si tScore est vide ou textuel
       local iLevel = nil
       do
         if type(tScore) == "number" then
           iLevel = tScore
           tScore = tostring(tScore)               -- on garde tScore chaîne pour l’enregistrement final
         elseif type(tScore) == "string" then
           -- prend le DERNIER nombre trouvé dans la chaîne (ex: "GS: 5120" -> 5120)
           for d in string.gmatch(tScore, "(%d+)") do iLevel = tonumber(d) end
         end
         if not iLevel then iLevel = tonumber(tLevel) end
         if not iLevel then iLevel = (UnitLevel and UnitLevel(pUnit)) or 0 end
       end]]--

	-- [SAFETY] tTabs doivent être numériques
	tTabs[1] = tonumber(tTabs[1]) or 0
	tTabs[2] = tonumber(tTabs[2]) or 0
	tTabs[3] = tonumber(tTabs[3]) or 0

	local tTabIndex = PBM.IF(tTabs[3] > tTabs[2] and tTabs[3] > tTabs[1], 3, PBM.IF(tTabs[2] > tTabs[3] and tTabs[2] > tTabs[1], 2, 1))
	local tSpecial = PBM.CLEAR(PBM.info.talent[PBM.toClass(tClass) .. tTabIndex], 1)

	if(tLocalClass == nil) then tLocalClass = tClass end
	if(tLocalRace == nil) then tLocalRace = tRace end

	PBMGlobalSave[tName] =  tLocalRace .. "," .. tGender .. "," .. tSpecial .. "," .. tTabs[1] .. "/" .. tTabs[2] .. "/" .. tTabs[3] .. "," .. tLocalClass .. "," .. tLevel .. "," .. tScore
end

--[[PBM.ItemLevel = function(pUnit)
	local tTitan = IsSpellKnown(49152) -- Titan's Grip
	local tCount = 16
	local tScore = 0

	for i = 1, 18, 1 do
		local tItem = GetInventoryItemLink(pUnit, i)
		if(tItem ~= nil and i ~= 4) then
			--local iName, iLink, iRare, iLevel, iMinLevel, iType, iSubType, iStack, iEquipLoc = GetItemInfo(tItem)
			local _, _, _, iLevel, _, _, _, _, iEquipLoc = GetItemInfo(tItem)
			if((i == 16 and iEquipLoc ~= "INVTYPE_2HWEAPON") or (i == 16 and tTitan) or (i == 17)) then tCount = 17 end
			tScore = tScore + iLevel
		end
	end

	return floor(tScore / tCount), tCount
end--]]

-- New Score formula
PBM.ItemLevel = function(pUnit)
	-- Calcule un “ilvl moyen” dans l’esprit de GetAverageItemLevel :
	--  - les slots vides comptent comme ilvl 0 (on divise toujours par 16 ou 17)
	--  - 2M sans Titan's Grip : 16 slots (pas d’off-hand possible)
	--  - 1M / 2x1M / 2M avec Titan's Grip : 17 slots (main + off-hand)
	--  - on garde la même plage de slots que le code d’origine (1..18) et on ignore la chemise.

	local hasTitanGrip = IsSpellKnown and IsSpellKnown(49152) or false

	local hasMainHand  = false
	local mainIs2H     = false
	local hasOffhand   = false

	local score = 0

	for slot = 1, 18 do
		-- On ignore la chemise (slot 4)
		if slot ~= 4 then
			local link = GetInventoryItemLink(pUnit, slot)
			if link then
				local _, _, _, iLevel, _, _, _, _, equipLoc = GetItemInfo(link)
				iLevel = iLevel or 0

				-- Gestion des slots arme principale / main gauche
				if slot == 16 then
					hasMainHand = true
					if equipLoc == "INVTYPE_2HWEAPON" then
						mainIs2H = true
					end
				elseif slot == 17 then
					hasOffhand = true
				end

				score = score + iLevel
			end
		end
	end

	-- Nombre de slots "théoriques" comme le client :
	--  - 16 si 2M sans Titan's Grip
	--  - 17 dès qu’un off-hand est possible ou présent
	local count = 16
	if (hasMainHand and not mainIs2H) or (hasMainHand and hasTitanGrip) or hasOffhand then
		count = 17
	end

	if count <= 0 then
		return 0, 0
	end

	return floor(score / count), count
end

PBM.SavePortal = function(pButton)
	local tSave = PBM.IF(pButton.goMap == nil, "", pButton.goMap)
	tSave = tSave .. ";" .. (math.ceil(pButton.goX * 1000) / 1000)
	tSave = tSave .. ";" .. (math.ceil(pButton.goY * 1000) / 1000)
	tSave = tSave .. ";" .. (math.ceil(pButton.goZ * 1000) / 1000)
	tSave = tSave .. ";" .. pButton.tip
	tSave = tSave .. ";" .. PBM.IF(pButton.state, 1, 0)
	return tSave
end

PBM.LoadPortal = function(pButton, pValue)
	local tValue = PBM.doSplit(pValue, ";")
	pButton.goMap = tonumber(tValue[1])
	pButton.goX = tonumber(tValue[2])
	pButton.goY = tonumber(tValue[3])
	pButton.goZ = tonumber(tValue[4])
	pButton.tip = tValue[5]
	if(tValue[6] == "1")
	then pButton.setEnable()
	else pButton.setDisable()
	end
end

PBM.SpellToMacro = function(pName, pSpell, pTexture)
	--local tGlobal, tAmount = GetNumMacros()
	local _, tAmount = GetNumMacros()

	if(pSpell == nil or pSpell == 0) then
		return SendChatMessage(PBM.info.spell, "SAY")
	end
	if(tAmount == 18) then
		return SendChatMessage(PBM.info.macro, "SAY")
	end

	local tMacro = string.sub(pName, 1, 14) .. tAmount
	--local tSpell, tIcon, tBody = GetMacroInfo(tMacro)
	local tSpell = GetMacroInfo(tMacro)

	if(tSpell == nil) then
		-- Sécurité : si l’icône n’est pas définie dans PBM.spellbook.icons,
		-- on utilise une icône par défaut (index 1).
		local icon = 1
		if PBM.spellbook and PBM.spellbook.icons then
			icon = PBM.spellbook.icons[pTexture] or 1
		end
		CreateMacro(tMacro, icon, "/t " .. pName .. " cast " .. pSpell, true)
	end
	PickupMacro(tMacro)
end

PBM.ActionToTarget = function(pAction, oTarget)
	local tName = PBM.IF(oTarget == nil, UnitName("target"), oTarget)

	if(tName ~= nil and tName ~= "Unknown Entity") then
		SendChatMessage(pAction, "WHISPER", nil, tName)
		return true
	end

	SendChatMessage(PBM.info.target, "SAY")
	return false
end

PBM.ActionToTargetOrGroup = function(pAction)
	local tName = UnitName("target")

	if(tName ~= nil and tName ~= "Unknown Entity") then
		SendChatMessage(pAction, "WHISPER", nil, tName)
		return true
	end

	if(GetNumRaidMembers() > 5) then
		SendChatMessage(pAction, "RAID")
		return true
	end

	if(GetNumPartyMembers() > 0) then
		SendChatMessage(pAction, "PARTY")
		return true
	end

	SendChatMessage(PBM.info.neither, "SAY")
	return false
end

PBM.ActionToGroup = function(pAction)
	if(GetNumRaidMembers() > 5) then
		SendChatMessage(pAction, "RAID")
		return true
	end

	if(GetNumPartyMembers() > 0) then
		SendChatMessage(pAction, "PARTY")
		return true
	end

	SendChatMessage(PBM.info.group, "SAY")
	return false
end

PBM.SelectToTarget = function(pParent, pIndex, pTexture, pAction, oTarget)
	if(PBM.ActionToTarget(pAction, oTarget)) then
		local tFrame = pParent.frames[pIndex]
		local tButton = pParent.buttons[pIndex]
		tButton.setTexture(pTexture)
		tFrame:Hide()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(tFrame) end
		return true
	end

	return false
end

PBM.SelectToTargetButton = function(pParent, pIndex, pTexture, pAction, oTarget)
	local tFrame = pParent.frames[pIndex]
	local tButton = pParent.buttons[pIndex]
	tButton.doLeft = function(pButton) PBM.ActionToTarget(pAction, oTarget) end
	tButton.setTexture(pTexture)
	tFrame:Hide()
	if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(tFrame) end
	return true
end

PBM.SelectToGroupButtonWithTarget = function(pParent, pIndex, pTexture, pAction)
	local tFrame = pParent.frames[pIndex]
	local tButton = pParent.buttons[pIndex]
	tButton.doLeft = function(pButton) if(PBM.isTarget()) then PBM.ActionToGroup(pAction) end end
	tButton.setTexture(pTexture)
	tFrame:Hide()
	if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(tFrame) end
	return true
end

PBM.SelectToGroupButton = function(pParent, pIndex, pTexture, pAction)
	local tFrame = pParent.frames[pIndex]
	local tButton = pParent.buttons[pIndex]
	tButton.doLeft = function(pButton) PBM.ActionToGroup(pAction) end
	tButton.setTexture(pTexture)
	tFrame:Hide()
	if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(tFrame) end
	return true
end

PBM.SelectToGroup = function(pParent, pIndex, pTexture, pAction)
	if(PBM.ActionToGroup(pAction)) then
		local tFrame = pParent.frames[pIndex]
		local tButton = pParent.buttons[pIndex]
		tButton.setTexture(pTexture)
		tFrame:Hide()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(tFrame) end
		return true
	end

	return false
end

PBM.Select = function(pParent, pIndex, pTexture)
	local tFrame = pParent.frames[pIndex]
	local tButton = pParent.buttons[pIndex]
	tButton.setTexture(pTexture)
	tFrame:Hide()
	if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(tFrame) end
	return true
end

PBM.ShowHideSwitch = function(pFrame)
	if(pFrame:IsVisible()) then
		pFrame:Hide()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(pFrame) end
		return false
	end

	pFrame:Show()
	if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(pFrame) end
	return true
end

PBM.OnOffActionToTarget = function(pButton, pOn, pOff, pTarget)
	if(pButton.state) then
		PBM.ActionToTarget(pOff, pTarget)
		pButton.setDisable()
		return false
	else
		PBM.ActionToTarget(pOn, pTarget)
		pButton.setEnable()
		return true
	end
end

PBM.OnOffSwitch = function(pButton)
	if(pButton.state) then
		pButton.setDisable()
		return false
	end

	pButton.setEnable()
	return true
end

-- CLICK BLOCKER --
-- Fond invisible placé sous les barres de boutons (et leurs zones extensibles) afin
-- d'empêcher les clics de "traverser" l'UI dans les espaces entre boutons.

PBM._clickBlockerQueue = PBM._clickBlockerQueue or {}

local function _mbQueueClickBlockerUpdate(f)
	if(not f or not f.clickBlocker) then return end
	PBM._clickBlockerQueue[f] = true

	if(not PBM._clickBlockerTicker) then
		PBM._clickBlockerTicker = CreateFrame("Frame", nil, UIParent)
		PBM._clickBlockerTicker.running = false
	end

	local t = PBM._clickBlockerTicker
	if(t.running) then return end

	t.running = true
	t:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil)
		self.running = false

		local queue = PBM._clickBlockerQueue
		PBM._clickBlockerQueue = {}
		for frame in pairs(queue) do
			if(PBM.UpdateClickBlocker) then
				PBM.UpdateClickBlocker(frame)
			end
		end
	end)
end

-- Demande une mise à jour pour le frame et tous ses parents PBM.newFrame (cascade).
function PBM.RequestClickBlockerUpdate(frame)
	local f = frame
	while(f) do
		_mbQueueClickBlockerUpdate(f)
		f = f.parent
	end
end

-- Recalcule la zone à bloquer à partir des coordonnées réelles (écran) de tous les boutons visibles.
function PBM.UpdateClickBlocker(frame)
	local cb = frame and frame.clickBlocker
	if(not cb) then return end

	if(not frame:IsShown()) then
		cb:Hide()
		return
	end

	local brx, bry = frame:GetRight(), frame:GetBottom()
	if(not brx or not bry) then
		cb:Hide()
		return
	end

	local minL, maxR, minB, maxT
	local foundButton = false

	local function consider(l, r, b, t)
		if(not l or not r or not b or not t) then return end
		if(not minL or l < minL) then minL = l end
		if(not maxR or r > maxR) then maxR = r end
		if(not minB or b < minB) then minB = b end
		if(not maxT or t > maxT) then maxT = t end
	end

	local function scan(f)
		if(not f or not f.IsShown or not f:IsShown()) then return end

		if(f.buttons) then
			for _, b in pairs(f.buttons) do
				if(b and b.IsVisible and b:IsVisible()) then
					consider(b:GetLeft(), b:GetRight(), b:GetBottom(), b:GetTop())
					foundButton = true
				end
			end
		end
	end

	scan(frame)

	if(not foundButton) then
		cb:Hide()
		return
	end

	if(not minL or not maxR or not minB or not maxT) then
		cb:Hide()
		return
	end

	local pad = 2
	local minX = (minL - brx) - pad
	local maxX = (maxR - brx) + pad
	local minY = (minB - bry) - pad
	local maxY = (maxT - bry) + pad

	cb:ClearAllPoints()
	cb:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", maxX, minY)
	cb:SetPoint("TOPLEFT", frame, "BOTTOMRIGHT", minX, maxY)
	cb:SetFrameLevel(frame:GetFrameLevel())
	cb:Show()
end

-- MULTIBOT:FRAME --

PBM.newFrame = function(pParent, pX, pY, pSize, oWidth, oHeight, oAlign)
	local frame = CreateFrame("Frame", nil, pParent)
	frame:SetPoint(PBM.IF(oAlign ~= nil, oAlign, "BOTTOMRIGHT"), pX, pY)
	frame:Show()

	if(oWidth ~= nil and oHeight ~= nil)
	then frame:SetSize(oWidth, oHeight)
	else frame:SetSize(pSize, pSize)
	end

	frame.buttons = {}
	frame.frames = {}
	frame.texts = {}

	frame.parent = pParent
	frame.height = PBM.IF(oHeight ~= nil, oHeight, pSize)
	frame.width = PBM.IF(oWidth ~= nil, oWidth, pSize)
	frame.align = PBM.IF(oAlign ~= nil, oAlign, "BOTTOMRIGHT")
	frame.size = pSize
	frame.x = pX
	frame.y = pY

	-- click blocker: absorbe les clics dans les espaces entre boutons
	frame.clickBlocker = CreateFrame("Frame", nil, frame)
	frame.clickBlocker:SetFrameLevel(frame:GetFrameLevel())
	frame.clickBlocker:EnableMouse(true)
	frame.clickBlocker.texture = frame.clickBlocker:CreateTexture(nil, "BACKGROUND")
	frame.clickBlocker.texture:SetAllPoints(frame.clickBlocker)
	frame.clickBlocker.texture:SetTexture("Interface\\Buttons\\WHITE8X8")
	frame.clickBlocker.texture:SetVertexColor(0, 0, 0, 0) -- fond totalement transparent
	frame.clickBlocker:SetAllPoints(frame)

	frame:HookScript("OnShow", function() if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(frame) end end)
	frame:HookScript("OnHide", function() if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(frame) end end)
	-- ADD --

	frame.addTexture = function(pTexture)
		if(frame.texture ~= nil) then frame.texture:Hide() end
		frame.texture = frame:CreateTexture(nil, "BACKGROUND")
		frame.texture:SetTexture(PBM.SafeTexturePath(pTexture))
		frame.texture:SetAllPoints(frame)
		frame.texture:Show()
		return frame.texture
	end

	--frame.addModel = function(pName, pX, pY, pWidth, pHeight, oScale)
	frame.addModel = function(pName, x, y, pWidth, pHeight, oScale)
		if(frame.model ~= nil) then frame.model:Hide() end
		frame.model = CreateFrame("DressUpModel", "MyModel" .. pName, frame)
		--frame.model:SetPoint("CENTER", pX, pY)
		frame.model:SetPoint("CENTER", x, y)
		frame.model:SetSize(pWidth, pHeight)
		frame.model:SetUnit(pName)
		if(oScale ~= nil) then frame.model:SetScale(oScale) end
		return frame.model
	end

	--frame.addText = function(pIndex, pText, pAlign, pX, pY, pSize)
	frame.addText = function(pIndex, pText, pAlign, x, y, fontSize)
		if(frame.texts[pIndex] ~= nil) then frame.texts[pIndex]:Hide() end
		frame.texts[pIndex] = frame:CreateFontString(nil, "ARTWORK")
		--frame.texts[pIndex]:SetFont("Fonts\\ARIALN.ttf", pSize, "PLAIN")
		--frame.texts[pIndex]:SetPoint(pAlign, pX, pY)
        frame.texts[pIndex]:SetFont("Fonts\\ARIALN.ttf", fontSize, "PLAIN")
        frame.texts[pIndex]:SetPoint(pAlign, x, y)
		frame.texts[pIndex]:SetText(pText)
		frame.texts[pIndex]:Show()
		return frame.texts[pIndex]
	end

	--frame.wowButton = function(pName, pX, pY, pWidth, pHeight, pSize)
	frame.wowButton = function(pName, x, y, pWidth, pHeight, size)
		if(frame.buttons[pName] ~= nil) then frame.buttons[pName]:Hide() end
		--frame.buttons[pName] = PBM.wowButton(frame, pName, pX, pY, pWidth, pHeight, pSize)
		frame.buttons[pName] = PBM.wowButton(frame, pName, x, y, pWidth, pHeight, size)
		return frame.buttons[pName]
	end

	--frame.addButton = function(pName, pX, pY, pTexture, pTip, oTemplate)
	frame.addButton = function(pName, x, y, pTexture, pTip, oTemplate)
		if(frame.buttons[pName] ~= nil) then frame.buttons[pName]:Hide() end
		--frame.buttons[pName] = PBM.newButton(frame, pX, pY, frame.size, pTexture, pTip, oTemplate)
		frame.buttons[pName] = PBM.newButton(frame, x, y, frame.size, pTexture, pTip, oTemplate)
		return frame.buttons[pName]
	end

	--frame.movButton = function(pName, pX, pY, pSize, pTip, oFrame)
	frame.movButton = function(pName, x, y, size, pTip, oFrame)
		if(frame.buttons[pName] ~= nil) then frame.buttons[pName]:Hide() end
		--frame.buttons[pName] = PBM.movButton(frame, pX, pY, pSize, pTip, oFrame)
		frame.buttons[pName] = PBM.movButton(frame, x, y, size, pTip, oFrame)
		return frame.buttons[pName]
	end

	--frame.boxButton = function(pName, pX, pY, pSize, pState)
	frame.boxButton = function(pName, x, y, size, pState)
		if(frame.buttons[pName] ~= nil) then frame.buttons[pName]:Hide() end
		--frame.buttons[pName] = PBM.boxButton(frame, pX, pY, pSize, pState)
		frame.buttons[pName] = PBM.boxButton(frame, x, y, size, pState)
		return frame.buttons[pName]
	end

	--frame.catButton = function(pName, pX, pY, pWidth, pHeight)
	frame.catButton = function(pName, x, y, pWidth, pHeight)
		if(frame.buttons[pName] ~= nil) then frame.buttons[pName]:Hide() end
		--frame.buttons[pName] = PBM.catButton(frame, pX, pY, pWidth, pHeight)
		frame.buttons[pName] = PBM.catButton(frame, x, y, pWidth, pHeight)
		return frame.buttons[pName]
	end

	--frame.addFrame = function(pName, pX, pY, oSize, oWidth, oHeight)
	frame.addFrame = function(pName, x, y, oSize, subWidth, subHeight)
		if(frame.frames[pName] ~= nil) then frame.frames[pName]:Hide() end
		--frame.frames[pName] = PBM.newFrame(frame, pX, pY, PBM.IF(oSize ~= nil, oSize, frame.size - 4), oWidth, oHeight)
		frame.frames[pName] = PBM.newFrame(frame, x, y, PBM.IF(oSize ~= nil, oSize, frame.size - 4), subWidth, subHeight)
		return frame.frames[pName]
	end

	-- SET --

	--[[frame.setPoint = function(pX, pY)
		frame:SetPoint("BOTTOMRIGHT", pX, pY)
		frame.x = pX
		frame.y = pY]]--
    frame.setPoint = function(x, y)
        frame:SetPoint("BOTTOMRIGHT", x, y)
        frame.x = x
        frame.y = y
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(frame) end
		return frame
	end

	frame.setButton = function(pIndex, pTexture, pTip)
		frame.buttons[pIndex].setButton(pTexture, pTip)
		return frame
	end

	frame.setTexture = function(pTexture)
		frame.texture:SetTexture(PBM.SafeTexturePath(pTexture))
		frame.texture:SetAllPoints(frame)
		frame.texture:Show()
		return frame
	end

	frame.setText = function(pIndex, pText)
		frame.texts[pIndex]:SetText(pText)
		frame.texts[pIndex]:Show()
		return frame
	end

	frame.setLevel = function(pLevel)
		frame:SetFrameLevel(pLevel)
		return frame
	end

	frame.setAlpha = function(pAlpha)
		frame:SetAlpha(pAlpha)
		return frame
	end

	-- GET --

	frame.getButton = function(pIndex)
		if(frame.buttons[pIndex] ~= nil) then
			return frame.buttons[pIndex]
		end

		for key, value in pairs(frame.frames) do
			local tButton = value.getButton(pIndex)
			if(tButton ~= nil) then return tButton end
		end

		return nil
	end

	frame.getFrame = function(pIndex)
		if(frame.frames[pIndex] ~= nil) then
			return frame.frames[pIndex]
		end

		for key, value in pairs(frame.frames) do
			local tFrame = value.getFrame(pIndex)
			if(tFrame ~= nil) then return tFrame end
		end

		return nil
	end

	frame.getClass = function()
		if(frame.class ~= nil) then return frame.class end
		return frame.parent.getClass()
	end

	frame.getName = function()
		if(frame.name ~= nil) then return frame.name end
		return frame.parent.getName()
	end

	frame.get = function()
		if(frame.name ~= nil) then return frame end
		return frame.parent.get()
	end

	-- DO --

	frame.doShow = function()
		frame:Show()
		return frame
	end

	frame.doHide = function()
		frame:Hide()
		return frame
	end

	if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(frame) end

	return frame
end

-- MULTIBOT:BUTTON --

PBM.newButton = function(pParent, pX, pY, pSize, pTexture, pTip, oTemplate)
	local button = CreateFrame("Button", nil, pParent, PBM.IF(oTemplate ~= nil, oTemplate, "ActionButtonTemplate"))
	button:SetPoint("BOTTOMRIGHT", pX, pY)
	button:SetSize(pSize, pSize)
	button:Show()

	button.icon = button:CreateTexture(nil, "BACKGROUND")
	button.icon:SetTexture(PBM.SafeTexturePath(pTexture))
	button.icon:SetAllPoints(button)
	button.icon:Show()

	button.border = button:CreateTexture(nil, "ARTWORK")
	button.border:SetTexture("Interface\\AddOns\\PBM\\Icons\\border.blp")
	button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
	button.border:SetSize(pSize + 4, pSize + 4)
	button.border:Hide()

	button:EnableMouse(true)
	button:RegisterForClicks("LeftButtonDown", "RightButtonDown")
	button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square", "ADD")
	button:SetPushedTexture("Interface/Buttons/UI-Quickslot-Depress")
	button:SetNormalTexture("")

	--button.texture = pTexture
    button.texture = PBM.SafeTexturePath(pTexture)
	button.parent = pParent
	button.size = pSize
	button.tip = pTip
	button.x = pX
	button.y = pY
	if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
	button:HookScript("OnShow", function() if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end end)
	button:HookScript("OnHide", function() if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end end)

	-- ADD --

	button.addMacro = function(pType, pMacro)
		button:SetAttribute("macrotext", pMacro);
		button:SetAttribute(pType, "macro");
		return button
	end

	-- SET --

    button.setPoint = function(x, y)
        button:SetPoint("BOTTOMRIGHT", x, y)
        button.x = x
        button.y = y
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
		return button
	end

    button.setButton = function(texture, tip)
        local safe = PBM.SafeTexturePath(texture)
        button.icon:SetTexture(safe)
		button.icon:SetAllPoints(button)
        button.texture = safe
        button.tip = tip
		return button
	end

    button.setTexture = function(texture)
        local safe = PBM.SafeTexturePath(texture)
        button.icon:SetTexture(safe)
		button.icon:SetAllPoints(button)
        button.texture = safe
		return button
	end

    button.setHighlight = function(texture)
        button:SetHighlightTexture(texture, "ADD")
		return button
	end

	button.setAmount = function(pAmount)
		if(button.amount ~= nil) then button.amount:Hide() end
		button.amount = button:CreateFontString(nil, "ARTWORK")
		button.amount:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
		button.amount:SetPoint("BOTTOMRIGHT", 0, 0)
		button.amount:SetText(pAmount)
		return button
	end

	button.setDisable = function(oBorder)
		button.icon:SetDesaturated(1)
		if(oBorder == nil) then oBorder = true end
		if(oBorder) then button.border:Hide() end
		button.state = false
		return button
	end

	button.setEnable = function(oBorder)
		button.icon:SetDesaturated(nil)
		if(oBorder == nil) then oBorder = true end
		if(oBorder) then button.border:Show() end
		button.state = true
		return button
	end

	-- GET --

	button.getButton = function(pIndex)
		return button.parent.get().getButton(pIndex)
	end

	button.getFrame = function(pIndex)
		return button.parent.get().getFrame(pIndex)
	end

	button.getClass = function()
		return button.parent.getClass()
	end

	button.getName = function()
		return button.parent.getName()
	end

	button.get = function()
		return button.parent.get()
	end

	-- DO --

	button.doHide = function()
		button:SetPoint("BOTTOMRIGHT", button.x, button.y)
		button:SetSize(button.size, button.size)
		button:Hide()
		return button
	end

	button.doShow = function()
		button:SetPoint("BOTTOMRIGHT", button.x, button.y)
		button:SetSize(button.size, button.size)
		button:Show()
		return button
	end

	-- EVENT --

	button:SetScript("OnEnter", function()
		if(type(button.tip) == "string") then
			GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT", 0 - button.size, 2)
			if(string.sub(button.tip, 1, 1) == "|") then GameTooltip:SetHyperlink(button.tip) else GameTooltip:SetText(button.tip) end
			GameTooltip:Show()
			return
		end

		if(type(button.tip) == "table") then
			button.tip:Show()
			return
		end
	end)

	button:SetScript("OnLeave", function()
		button:SetPoint("BOTTOMRIGHT", button.x, button.y)
		button:SetSize(button.size, button.size)

		button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
		button.border:SetSize(button.size + 4, button.size + 4)

		if(type(button.tip) == "string") then GameTooltip:Hide() end
		if(type(button.tip) == "table") then button.tip:Hide() end
	end)

	button:SetScript("PostClick", function(pSelf, pEvent)
		button:SetPoint("BOTTOMRIGHT", button.x - 1, button.y + 1)
		button:SetSize(button.size - 2, button.size - 2)

		button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
		button.border:SetSize(button.size + 2, button.size + 2)

		if(type(button.tip) == "string") then GameTooltip:Hide() end
		if(type(button.tip) == "table") then button.tip:Hide() end

		if(pEvent == "RightButton" and button.doRight ~= nil) then button.doRight(button) end
		if(pEvent == "LeftButton" and button.doLeft ~= nil) then button.doLeft(button) end
	end)

	return button
end

-- BUTTON:WOW --

PBM.wowButton = function(pParent, pName, pX, pY, pWidth, pHeight, pSize)
	local button = CreateFrame("Button", nil, pParent, "UIPanelButtonTemplate")
	button:SetPoint("BOTTOMRIGHT", pX, pY)
	button:SetSize(pWidth, pHeight)
	button:Show()

	button.text = button:CreateFontString(nil, "ARTWORK")
	button.text:SetFont("Fonts\\ARIALN.ttf", pSize, "OUTLINE")
	button.text:SetPoint("CENTER", 0, 0)
	button.text:SetText("|cffffcc00" .. pName .. "|r")
	button.text:Show()

	button:EnableMouse(true)
	button:RegisterForClicks("LeftButtonDown", "RightButtonDown")

	button.parent = pParent
	button.state = true
	button.y = pY
	button.x = pX

	if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end

	button:HookScript("OnShow", function()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
	end)

	button:HookScript("OnHide", function()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
	end)

	-- GET --

	button.getButton = function(pIndex)
		return button.parent.get().getButton(pIndex)
	end

	button.getFrame = function(pIndex)
		return button.parent.get().getFrame(pIndex)
	end

	button.getClass = function()
		return button.parent.getClass()
	end

	button.getName = function()
		return button.parent.getName()
	end

	button.get = function()
		return button.parent.get()
	end

	-- SET --

	button.setDisable = function()
		button:GetNormalTexture():SetDesaturated(1)
		button.state = false
		return button
	end

	button.setEnable = function()
		button:GetNormalTexture():SetDesaturated(nil)
		button.state = true
		return button
	end

	-- DO --

	button.doHide = function()
		button:Hide()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
		return button
	end

	button.doShow = function()
		button:Show()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
		return button
	end

	-- EVENT --

	button:SetScript("OnEnter", function()
	end)

	button:SetScript("OnLeave", function()
		button.text:SetPoint("CENTER", 0, 0)
	end)

	button:SetScript("OnClick", function(pSelf, pEvent)
		button.text:SetPoint("CENTER", -1, -1)
		if(pEvent == "RightButton" and button.doRight ~= nil) then button.doRight(button) end
		if(pEvent == "LeftButton" and button.doLeft ~= nil) then button.doLeft(button) end
	end)

	return button
end

-- BUTTON:MOVE --

PBM.movButton = function(pParent, pX, pY, pSize, pTip, oFrame)
	local button = CreateFrame("Button", nil, pParent)
	button:SetPoint("BOTTOMRIGHT", pX, pY)
	button:SetSize(pSize, pSize)
	button:Show()

	button:EnableMouse(true)
	button:RegisterForClicks("RightButtonDown")
	button:RegisterForDrag("RightButton")

	button.parent = pParent
	button.frame = oFrame
	button.size = pSize
	button.tip = pTip
	button.x = pX
	button.y = pY

	if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end

	button:HookScript("OnShow", function()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
	end)

	button:HookScript("OnHide", function()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
	end)

	-- EVENT --

	button:SetScript("OnEnter", function()
		GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT", 0 - button.size, 2)
		GameTooltip:SetText(button.tip)
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	button:SetScript("OnClick", function(pSelf, pEvent)
		GameTooltip:Hide()
	end)

	button:SetScript("OnDragStart", function()
		if(button.frame ~= nil) then button.frame:StartMoving() else button.parent:StartMoving() end
	end)

	button:SetScript("OnDragStop", function()
		if(button.frame ~= nil) then button.frame:StopMovingOrSizing() else button.parent:StopMovingOrSizing() end
	end)

	return button
end

-- BUTTON:BOX --

PBM.boxButton = function(pParent, pX, pY, pSize, pState)
	local button = CreateFrame("CheckButton", nil, pParent, "ChatConfigCheckButtonTemplate");
	button:SetPoint("BOTTOMRIGHT", pX, pY)
	button:SetHitRectInsets(0, 0, 0, 0)
	button:SetSize(pSize, pSize)
	button:SetChecked(pState)
	button:Show()

	button.parent = pParent
	button.state = pState
	button.size = pSize
	button.x = pX
	button.y = pY

	if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end

	button:HookScript("OnShow", function()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
	end)

	button:HookScript("OnHide", function()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
	end)

	-- GET --

	button.getButton = function(pIndex)
		return button.parent.get().getButton(pIndex)
	end

	button.getFrame = function(pIndex)
		return button.parent.get().getFrame(pIndex)
	end

	button.getClass = function()
		return button.parent.getClass()
	end

	button.getName = function()
		return button.parent.getName()
	end

	button.get = function()
		return button.parent.get()
	end

	-- DO --

	button.doHide = function()
		button:Hide()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
		return button
	end

	button.doShow = function()
		button:Show()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
		return button
	end

	-- EVENT --

	button:SetScript("OnClick", function()
		if(button.doClick ~= nil) then button.doClick(button) end
	end)

	return button;
end

-- BUTTON:CAT --

PBM.catButton = function(pParent, pX, pY, pWidth, pHeight)
	local button = CreateFrame("CheckButton", nil, pParent, "SecureActionButtonTemplate");
	button:SetPoint("BOTTOMRIGHT", pX, pY)
	button:SetSize(pWidth, pHeight)
	button:Show()

	button.parent = pParent
	if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end

	button:HookScript("OnShow", function()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
	end)

	button:HookScript("OnHide", function()
		if(PBM.RequestClickBlockerUpdate) then PBM.RequestClickBlockerUpdate(button.parent) end
	end)

	-- EVENT --

	button:SetScript("OnClick", function()
		if(button.doClick ~= nil) then button.doClick(button) end
	end)

	return button;
end

-- MULTIBOT:ADD --

PBM.addFrame = function(pName, pX, pY, pSize)
	local tFrame = PBM.newFrame(PBM, pX, pY, pSize)
	PBM.frames[pName] = tFrame
	return tFrame
end

-- MULTIBOT: SELL ALL BOTS --
-- Envoie une commande de vente à tous les bots listés dans l’onglet "Units".
-- pCommand : "s *" (tout le gris) ou "s vendor" (tout ce qui est vendable).
PBM.SellAllBots = function(pCommand)
	-- Par défaut : vendre tous les objets gris (safe)
	pCommand = pCommand or "s *"

	if not PBM.isTarget or not PBM.isTarget() then
		return 0
	end

	local frames = PBM.frames
	if not frames then return 0 end

	local multiBar = frames["MultiBar"]
	if not multiBar or not multiBar.frames or not multiBar.frames["Units"] then
		return 0
	end

	local units = multiBar.frames["Units"]
	if not units.buttons then
		return 0
	end

	CancelTrade()

	local count = 0

	for key, btn in pairs(units.buttons) do
		if type(btn) == "table" then
			local botName = btn.name or (btn.getName and btn.getName()) or key
			if botName and botName ~= "" then
				SendChatMessage(pCommand, "WHISPER", nil, botName)
				count = count + 1
			end
		end
	end

	-- Si une fenêtre d’inventaire est ouverte, on la rafraîchit pour le bot affiché
	if PBM.inventory and PBM.inventory:IsVisible() and PBM.RefreshInventory then
		PBM.RefreshInventory(0.5)
	end

	return count
end

-- MULTIBOT: MAINTENANCE ALL BOTS --
-- Envoie la commande "maintenance" à tous les bots listés dans l’onglet "Units".
PBM.MaintenanceAllBots = function()
	local frames = PBM.frames
	if not frames then return 0 end

	local multiBar = frames["MultiBar"]
	if not multiBar or not multiBar.frames or not multiBar.frames["Units"] then
		return 0
	end

	local units = multiBar.frames["Units"]
	if not units.buttons then
		return 0
	end

	CancelTrade()

	local count = 0

	for key, btn in pairs(units.buttons) do
		if type(btn) == "table" then
			local botName = btn.name or (btn.getName and btn.getName()) or key
			if botName and botName ~= "" then
				SendChatMessage("maintenance", "WHISPER", nil, botName)
				count = count + 1
			end
		end
	end

	-- Si une fenêtre d’inventaire est ouverte, on peut la rafraîchir pour refléter d’éventuels changements
	if PBM.inventory and PBM.inventory:IsVisible() and PBM.RefreshInventory then
		PBM.RefreshInventory(0.5)
	end

	return count
end

--[[PBM.addSelf = function(pClass, pName)
PBM.dprint("addSelf", pName, pClass) -- DEBUG
	if(PBM.frames["MultiBar"].frames["Units"].buttons[pName] ~= nil) then return PBM.frames["MultiBar"].frames["Units"].buttons[pName] end
	local tClass = PBM.toClass(pClass)
	local tButton = PBM.frames["MultiBar"].frames["Units"].addButton(pName, 0, 0, "inv_misc_head_clockworkgnome_01", PBM.tips.unit.selfbot)
	if(PBM.index.classes.players[tClass] == nil) then PBM.index.classes.players[tClass] = {} end
	table.insert(PBM.index.classes.players[tClass], pName)
	-- table.insert(PBM.index.players, pName)
	table.insert(PBM.index.players, pName); PBM.dprint("players++", pName, "total", table.getn(PBM.index.players)) -- DEBUG
	tButton.roster = "players"
	tButton.class = tClass
	tButton.name = pName
	-- Si ce joueur est en favoris, on rafraîchit l’index
	if PBM.IsFavorite and PBM.IsFavorite(pName) and PBM.UpdateFavoritesIndex then
		PBM.UpdateFavoritesIndex()
	end
	return tButton
end]]--

PBM.addSelf = function(pClass, pName)
  local units = PBM.frames["MultiBar"].frames["Units"]
  local btn   = units.buttons[pName]
  local tClass = (PBM.toClass and PBM.toClass(pClass)) or (pClass or "Unknown")
  tClass = tClass or "Unknown"
  if not btn then
    btn = units.addButton(pName, 0, 0, "inv_misc_head_clockworkgnome_01", PBM.tips.unit.selfbot)
  end
  -- Assurer la présence dans les index (sans doublons)
  PBM.index.classes.players[tClass] = PBM.index.classes.players[tClass] or {}
  local byClass = PBM.index.classes.players[tClass]
  local found = false
  for i=1,#byClass do if byClass[i] == pName then found = true; break end end
  if not found then table.insert(byClass, pName) end
  local pidx = PBM.index.players
  local found2 = false
  for i=1,#pidx do if pidx[i] == pName then found2 = true; break end end
  if not found2 then table.insert(pidx, pName) end
  btn.roster = "players"
  btn.class  = tClass
  btn.name   = pName
  if PBM.IsFavorite and PBM.IsFavorite(pName) and PBM.UpdateFavoritesIndex then
    PBM.UpdateFavoritesIndex()
  end
  return btn
end

--[[PBM.addPlayer = function(pClass, pName)
PBM.dprint("addPlayer", pName, pClass) -- DEBUG
	if(PBM.frames["MultiBar"].frames["Units"].buttons[pName] ~= nil) then return PBM.frames["MultiBar"].frames["Units"].buttons[pName] end
	local tClass = PBM.toClass(pClass)
	local tTexture = "Interface\\AddOns\\PBM\\Icons\\class_" .. string.lower(tClass) .. ".blp"
	local tButton = PBM.frames["MultiBar"].frames["Units"].addButton(pName, 0, 0, tTexture, PBM.toTip(tClass, nil, pName))
	if(PBM.index.classes.players[tClass] == nil) then PBM.index.classes.players[tClass] = {} end
	table.insert(PBM.index.classes.players[tClass], pName)
	table.insert(PBM.index.players, pName)
	tButton.roster = "players"
	tButton.class = tClass
	tButton.name = pName
	return tButton
end]]--

PBM.addPlayer = function(pClass, pName)
  local units = PBM.frames["MultiBar"].frames["Units"]
  local btn   = units.buttons[pName]
  local tClass = (PBM.toClass and PBM.toClass(pClass)) or (pClass or "Unknown")
  tClass = tClass or "Unknown"
  local tTexture = "Interface\\AddOns\\PBM\\Icons\\class_" .. string.lower(tClass) .. ".blp"
  if not btn then
    btn = units.addButton(pName, 0, 0, tTexture, PBM.toTip(tClass, nil, pName))
  else
    if btn.icon and tTexture then btn.icon:SetTexture(PBM.SafeTexturePath(tTexture)) end
  end
  -- Assurer la présence dans les index (sans doublons)
  PBM.index.classes.players[tClass] = PBM.index.classes.players[tClass] or {}
  local byClass = PBM.index.classes.players[tClass]
  local found = false
  for i=1,#byClass do if byClass[i] == pName then found = true; break end end
  if not found then table.insert(byClass, pName) end
  local pidx = PBM.index.players
  local found2 = false
  for i=1,#pidx do if pidx[i] == pName then found2 = true; break end end
  if not found2 then table.insert(pidx, pName) end
  btn.roster = "players"
  btn.class  = tClass
  btn.name   = pName
  return btn
end

--[[local function MB_InsertUnique(pTable, pValue)
  if(pTable == nil) then return end
  for i = 1, table.getn(pTable) do
    if(pTable[i] == pValue) then return end
  end
  table.insert(pTable, pValue)
end]]--
local function MB_InsertUnique(pTable, pValue)
  if(pTable == nil) then return end
  for i = 1, #pTable do
    if(pTable[i] == pValue) then return end
  end
  table.insert(pTable, pValue)
end

PBM.addMember = function(pClass, pLevel, pName)
	--[[if(PBM.frames["MultiBar"].frames["Units"].buttons[pName] ~= nil) then return PBM.frames["MultiBar"].frames["Units"].buttons[pName] end
	local tClass = PBM.toClass(pClass)
	local tTexture = "Interface\\AddOns\\PBM\\Icons\\class_" .. string.lower(tClass) .. ".blp"
	local tButton = PBM.frames["MultiBar"].frames["Units"].addButton(pName, 0, 0, tTexture, PBM.toTip(tClass, pLevel, pName))
	if(PBM.index.classes.members[tClass] == nil) then PBM.index.classes.members[tClass] = {} end
	table.insert(PBM.index.classes.members[tClass], pName)
	table.insert(PBM.index.members, pName)
	tButton.roster = "members"
	tButton.class = tClass
	tButton.name = pName
	return tButton]]--
  local tUnits = PBM.frames["MultiBar"].frames["Units"]
  local tButton = tUnits.buttons[pName]
  local tClass = PBM.toClass(pClass)
  local tTexture = "Interface\\AddOns\\PBM\\Icons\\class_" .. string.lower(tClass) .. ".blp"
  if(tButton == nil) then
    tButton = tUnits.addButton(pName, 0, 0, tTexture, PBM.toTip(tClass, pLevel, pName))
  else
    if(tButton.setButton ~= nil) then
      tButton.setButton(tTexture, PBM.toTip(tClass, pLevel, pName))
    end
  end
  if(PBM.index.classes.members[tClass] == nil) then PBM.index.classes.members[tClass] = {} end
  MB_InsertUnique(PBM.index.classes.members[tClass], pName)
  MB_InsertUnique(PBM.index.members, pName)
  tButton.roster = "members"
  tButton.class = tClass
  tButton.name = pName
  return tButton
end

PBM.addFriend = function(pClass, pLevel, pName)
	--[[if(PBM.frames["MultiBar"].frames["Units"].buttons[pName] ~= nil) then return PBM.frames["MultiBar"].frames["Units"].buttons[pName] end
	local tClass = PBM.toClass(pClass)
	local tTexture = "Interface\\AddOns\\PBM\\Icons\\class_" .. string.lower(tClass) .. ".blp"
	local tButton = PBM.frames["MultiBar"].frames["Units"].addButton(pName, 0, 0, tTexture, PBM.toTip(tClass, pLevel, pName))
	if(PBM.index.classes.friends[tClass] == nil) then PBM.index.classes.friends[tClass] = {} end
	table.insert(PBM.index.classes.friends[tClass], pName)
	table.insert(PBM.index.friends, pName)
	tButton.roster = "friends"
	tButton.class = tClass
	tButton.name = pName
	return tButton]]--

  local tUnits = PBM.frames["MultiBar"].frames["Units"]
  local tButton = tUnits.buttons[pName]
  local tClass = PBM.toClass(pClass)
  local tTexture = "Interface\\AddOns\\PBM\\Icons\\class_" .. string.lower(tClass) .. ".blp"
  if(tButton == nil) then
    tButton = tUnits.addButton(pName, 0, 0, tTexture, PBM.toTip(tClass, pLevel, pName))
  else
    if(tButton.setButton ~= nil) then
      tButton.setButton(tTexture, PBM.toTip(tClass, pLevel, pName))
    end
  end
  if(PBM.index.classes.friends[tClass] == nil) then PBM.index.classes.friends[tClass] = {} end
  MB_InsertUnique(PBM.index.classes.friends[tClass], pName)
  MB_InsertUnique(PBM.index.friends, pName)
  tButton.roster = "friends"
  tButton.class = tClass
  tButton.name = pName
  return tButton
end

PBM.addActive = function(pClass, pLevel, pName)
	if(PBM.frames["MultiBar"].frames["Units"].buttons[pName] ~= nil) then return PBM.frames["MultiBar"].frames["Units"].buttons[pName] end
	local tClass = PBM.toClass(pClass)
	local tTexture = "Interface\\AddOns\\PBM\\Icons\\class_" .. string.lower(tClass) .. ".blp"
	local tButton = PBM.frames["MultiBar"].frames["Units"].addButton(pName, 0, 0, tTexture, PBM.toTip(tClass, pLevel, pName))
	tButton.roster = "actives"
	tButton.class = tClass
	tButton.name = pName
	return tButton
end

-- MULTIBOT:GET --

PBM.getBot = function(pName)
	return PBM.frames["MultiBar"].frames["Units"].buttons[pName]
end

-- MULTIBOT:INVENTORY REFRESH --
-- Rafraîchit l’inventaire du bot actuellement affiché dans la frame Inventory
-- en rejouant le même flux que le bouton "Inventory" (waitFor = "INVENTORY" + "items").
PBM.RefreshInventory = function(delay)
	-- Si la frame d’inventaire n’est pas visible ou pas encore initialisée, on ne fait rien
	if not PBM.inventory or not PBM.inventory:IsVisible() then
		return false
	end

	local botName = PBM.inventory.name
	if not botName or botName == "" then
		return false
	end

	-- On retrouve le bouton "Units" correspondant à ce bot
	local frames   = PBM.frames
	if not frames then return false end

	local multiBar = frames["MultiBar"]
	if not multiBar or not multiBar.frames or not multiBar.frames["Units"] then
		return false
	end

	local units = multiBar.frames["Units"]
	if not units.buttons or not units.buttons[botName] then
		return false
	end

	local function doRefresh()
		-- Entre le moment où on programme le refresh et l’exécution, il est possible
		-- que la frame ou le bouton n’existent plus : on recheck.
		if not units.buttons or not units.buttons[botName] then
			return
		end

		-- On relance le flux INVENTORY -> ITEM comme lors de l’ouverture de l’inventaire
		units.buttons[botName].waitFor = "INVENTORY"
		SendChatMessage("items", "WHISPER", nil, botName)
	end

	-- Si on a un délai > 0 et TimerAfter dispo, on planifie le refresh un peu plus tard
	if type(delay) == "number" and delay > 0 and PBM.TimerAfter then
		PBM.TimerAfter(delay, doRefresh)
	else
		-- Sinon on rafraîchit immédiatement (comportement d’origine)
		doRefresh()
	end

	return true
end