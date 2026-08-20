PBM.addItem = function(pFrame, pInfo)
	local tInfo = PBM.doSplit(pInfo, "|")
	local tID = PBM.doSplit(tInfo[3], ":")[2]

	local tIcon = GetItemIcon(tID)
	local tName, tLink, tRare = GetItemInfo(tID)

	local tX = (pFrame.index%8) * 38
	local tY = math.floor(pFrame.index/8) * -37.1

	if(tName == nil) then tName = string.sub(tInfo[4], 3, string.len(tInfo[4]) - 1) end
	if(tLink == nil) then tLink = "|" .. tInfo[2] .. "|" .. tInfo[3] .. "|" .. tInfo[4] .. "|h|r" end
	if(tRare == nil) then tRare = 4 end -- for Security

	local tButton = pFrame.addButton(tName, tX, tY, tIcon, tLink)
	pFrame.catButton(PBM_L["Catecher"], 270, -490, 308, 524)

	tButton.item = {}
	tButton.item.id = tID
	tButton.item.link = tLink
	tButton.item.name = tName
	tButton.item.info = pInfo
	tButton.item.rare = tRare

	--tButton.doLeft = function(pButton)
		--local tAction = PBM.inventory.action
		--local tName = PBM.inventory.name

    tButton.doLeft = function(pButton)
        local tAction = PBM.inventory.action
        -- Nom du bot cible (destinataire du whisper), on évite de masquer tName (nom de l'objet)
        local botName = PBM.inventory.name

		if(tAction == "") then
			SendChatMessage(PBM.info.action, "SAY")
			return
		end

		--[[if(tAction == "s" and PBM.isTarget()) then
			if(pButton.item.id == "6948") then return SendChatMessage(PBM.info.itemsellalert, "SAY") end
			if(PBM.isInside(pButton.item.info or "", "%f[%a][Kk]ey%f[%A]")) then
                return SendChatMessage(PBM.info.keydestroyalert, "SAY")
			end
			--SendChatMessage(tAction .. " " .. pButton.tip, "WHISPER", nil, tName)
			SendChatMessage(tAction .. " " .. pButton.tip, "WHISPER", nil, botName)
			pButton:Hide()
			return
		end]]--

        if(tAction == "s" and PBM.isTarget()) then
			if(pButton.item.id == "6948") then
				return SendChatMessage(PBM.info.itemsellalert, "SAY")
			end

			if(PBM.isInside(pButton.item.info or "", "%f[%a][Kk]ey%f[%A]")) then
                return SendChatMessage(PBM.info.keydestroyalert, "SAY")
			end

			-- Envoi de la commande "s [item]" au bot dont l’inventaire est ouvert
			--SendChatMessage(tAction .. " " .. pButton.tip, "WHISPER", nil, tName)
			SendChatMessage(tAction .. " " .. pButton.tip, "WHISPER", nil, botName)

			-- On masque l’item cliqué pour un feedback immédiat
			pButton:Hide()

			-- Puis on relit proprement l’inventaire du bot pour se resynchroniser
			if PBM.RefreshInventory then
				PBM.RefreshInventory(0.3)
			end

			return
		end

		if(tAction == "e" or tAction == "u" or tAction == "give") then
			--SendChatMessage(tAction .. " " .. pButton.tip, "WHISPER", nil, tName)
			SendChatMessage(tAction .. " " .. pButton.tip, "WHISPER", nil, botName)
			return
		end

		if(tAction == "destroy") then
			local needsConfirm = false
			if(pButton.item.id == "6948") then needsConfirm = true end -- Hearthstone
			if(PBM.isInside(pButton.item.info, "%f[%a][Kk]ey%f[%A]")) then needsConfirm = true end
			if(pButton.item.rare > 3) then needsConfirm = true end -- Épique ou mieux
			if needsConfirm then
				if not StaticPopupDialogs["MULTIBOT_CONFIRM_DESTROY"] then
					StaticPopupDialogs["MULTIBOT_CONFIRM_DESTROY"] = {
						text = PBM.info.itemdestroyalert,
						button1 = OKAY,
						button2 = CANCEL,
						timeout = 0,
						whileDead = 1,
						hideOnEscape = 1,
						OnAccept = function(self, data)
							if not data or not data.button then return end
							SendChatMessage("destroy" .. " " .. data.button.tip, "WHISPER", nil, data.tName)
							data.button:Hide()
						end,
					}
				end
				--local data = { button = pButton, tName = tName }
				local data = { button = pButton, tName = botName }
				StaticPopup_Show("MULTIBOT_CONFIRM_DESTROY", pButton.item.link, nil, data)
				return
			end
			-- Pas de confirmation requise
			--SendChatMessage(tAction .. " " .. pButton.tip, "WHISPER", nil, tName)
			SendChatMessage(tAction .. " " .. pButton.tip, "WHISPER", nil, botName)
			pButton:Hide()
			return
		end
	end

	if(string.sub(tInfo[6], 1, 2) == "rx") then
		tButton.setAmount(string.sub(PBM.doSplit(tInfo[6], " ")[1], 3))
	end

	pFrame.index = pFrame.index + 1
end