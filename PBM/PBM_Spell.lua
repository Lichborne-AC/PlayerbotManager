PBM.getSpellID = function(pInfo)
	local tInfo = PBM.doSplit(pInfo, "|")
	if(string.sub(tInfo[3], 1, 6) == "Hspell") then return string.sub(tInfo[3], 8) end
	return 0
end

PBM.addSpell = function(pInfo, pName)
	-- local tInfo = PBM.doSplit(pInfo, "|")
	local tID = PBM.getSpellID(pInfo)
	if(tID == 0) then return end

	local tName, tRank, tIcon = GetSpellInfo(tID)
	local tLink = GetSpellLink(tID)

	if(tName == nil) then tName = "" end
	if(tRank == nil) then tRank = "" end
	if(tIcon == nil) then tIcon = "inv_misc_questionmark" end
	if(tLink == nil) then tLink = tName end

	local tSpell = { tID, tName, tRank, tIcon, tLink }

	table.insert(PBM.spellbook.spells, tSpell)
	PBM.spellbook.index = PBM.spellbook.index + 1

	if(PBM.spells[pName] == nil) then PBM.spells[pName] = {} end
	if(PBM.spells[pName][tID] == nil) then PBM.spells[pName][tID] = true end

	if(PBM.spellbook.index < 17) then
		PBM.setSpell(PBM.spellbook.index, tSpell, pName)
	end
end

PBM.setSpell = function(pIndex, pSpell, pName)
	local tIndex = PBM.IF(pIndex < 10, "0", "") .. pIndex
	local tOverlay = PBM.spellbook.frames["Overlay"]

	if(pSpell ~= nil) then
		local tTitle = PBM.IF(string.len(pSpell[2]) > 16, string.sub(pSpell[2], 1, 16) .. "...", pSpell[2])
		tOverlay.setButton("S" .. tIndex, pSpell[4], pSpell[5])
		tOverlay.setText("T" .. tIndex, "|cffffcc00" .. tTitle .. "|r")
		tOverlay.setText("R" .. tIndex, "|cff402000" .. pSpell[3] .. "|r")
		tOverlay.buttons["S" .. tIndex].spell = pSpell[1]
		tOverlay.buttons["C" .. tIndex].spell = pSpell[1]
		tOverlay.buttons["S" .. tIndex].doShow()
		tOverlay.buttons["C" .. tIndex].doShow()
		tOverlay.texts["T" .. tIndex]:Show()
		tOverlay.texts["R" .. tIndex]:Show()
		tOverlay.buttons["C" .. tIndex]:SetChecked(PBM.spells[pName][pSpell[1]])
		tOverlay.buttons["C" .. tIndex].doClick = function(pButton)
			local tName = pButton.getName()
			local tAction = ""
			PBM.spells[tName][pButton.spell] = PBM.IF(PBM.spells[tName][pButton.spell], false, true)
			pButton:SetChecked(PBM.spells[tName][pButton.spell])
			for id, state in pairs(PBM.spells[tName]) do
				if(state == false) then tAction = tAction .. PBM.IF(tAction == "", "ss +", ", +") .. id end
			end
			PBM.ActionToTarget(PBM.IF(tAction == "", "ss -" .. pButton.spell, tAction), tName)
		end
	else
		tOverlay.buttons["S" .. tIndex].spell = 0
		tOverlay.buttons["C" .. tIndex].spell = 0
		tOverlay.buttons["S" .. tIndex].doHide()
		tOverlay.buttons["C" .. tIndex].doHide()
		tOverlay.texts["T" .. tIndex]:Hide()
		tOverlay.texts["R" .. tIndex]:Hide()
	end
end