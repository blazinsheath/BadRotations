local addonName, br = ...
-- Sell Greys Macros
SLASH_Greys1 = "/grey"
SLASH_Greys2 = "/greys"
function SlashCmdList.Greys(msg, editbox)
	SellGreys()
end
function SellGreys()
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local item = GetContainerItemLink(bag, slot)
			if item then
				-- Is it grey quality item?
				if string.find(item, br.qualityColors.grey) ~= nil then
					greyPrice = select(11, GetItemInfo(item)) * select(2, GetContainerItemInfo(bag, slot))
					if greyPrice > 0 then
						PickupContainerItem(bag, slot)
						PickupMerchantItem()
					end
				end
			end
		end
	end
	RepairAllItems(1)
	RepairAllItems(0)
	br.ChatOverlay("Sold Greys.")
end
-- Dump Greys Macros
SLASH_DumpGrey1 = "/dumpgreys"
SLASH_DumpGrey2 = "/dg"
function SlashCmdList.DumpGrey(msg, editbox)
	DumpGreys(1)
end
function DumpGreys(Num)
	local greyTable = {}
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local item = GetContainerItemLink(bag, slot)
			if item then
				-- Is it grey quality item?
				if string.find(item, br.qualityColors.grey) ~= nil then
					greyPrice = select(11, GetItemInfo(item)) * select(2, GetContainerItemInfo(bag, slot))
					if greyPrice > 0 then
						tinsert(greyTable, {Bag = bag, Slot = slot, Price = greyPrice, Item = item})
					end
				end
			end
		end
	end
	table.sort(
		greyTable,
		function(x, y)
			if x.Price and y.Price then
				return x.Price < y.Price
			end
		end
	)
	for i = 1, Num do
		if greyTable[i] ~= nil then
			PickupContainerItem(greyTable[i].Bag, greyTable[i].Slot)
			DeleteCursorItem()
			Print("|cffFF0000Removed Grey Item:" .. greyTable[i].Item)
		end
	end
end
------------------
-- Loot Manager --
------------------
br.lootManager = {}
lM = br.lootManager
-- Debug
function br.lootManager:debug(message)
	if message and lM.oldMessage ~= message then
		br.addonDebug("<lootManager> " .. (math.floor(GetTime() * 1000) / 1000) .. " " .. message, true)
		lM.oldMessage = message
	end
end
-- Check if availables bag slots, return true if at least 1 free bag space
function br.lootManager:emptySlots()
	local openSlots = 0
	for i = 0, 4 do --Let's look at each bag
		local numBagSlots = GetContainerNumSlots(i)
		if numBagSlots > 0 then -- Only look for slots if bag present
			openSlots = openSlots + select(1, GetContainerNumFreeSlots(i))
		end
	end
	return openSlots
end

local looting = false
local fetching = false
function br.lootManager:getLoot(lootUnit)
	-- if we have a unit to loot, check if its time to
	if br.timer:useTimer("getLoot", br.getOptionValue("Auto Loot")) then
		if br.getDistance(lootUnit) < 7 then
			if not looting then
				looting = true
				lM:debug("Looting " .. br._G.UnitName(lootUnit))
				br._G.InteractUnit(lootUnit)
				-- Manually loot if Auto Loot Interface Option not set
				if br._G.GetCVar("AutoLootDefault") == "0" then
					if br._G.LootFrame:IsShown() then
						for l = 1, br._G.GetNumLootItems() do
							if br._G.LootSlotHasItem(l) then
								br._G.LootSlot(l)
							end
						end
						br._G.CloseLoot()
					end
				end
			end
		elseif br.isChecked("Fetch") and (not isInCombat("player") or br.player.enemies.get(40)[1] == nil) and br._G.UnitExists("pet") and not deadPet and br.getDistance(lootUnit) > 7 and br.getDistance(lootUnit) < 40 then
			if not fetching then
				fetching = true
				lM:debug("Looting " .. br._G.UnitName(lootUnit))
				br._G.CastSpellByName(br._G.GetSpellInfo(125050))
			end
		end
		if not isInCombat("player") and looting then
			br._G.ClearTarget()
		end
		looting = false
		fetching = false
		lM.lootUnit = nil
		br.lootable = {}
		return
	end
end
-- function br.lootManager:getLoot(lootUnit)
-- 	local looting = false
-- 	-- if we have a unit to loot, check if its time to
-- 	if br.timer:useTimer("getLoot", br.getOptionValue("Auto Loot")) then
-- 		if not looting then
-- 			looting = true
-- 			--Print("Looting "..UnitName(lootUnit))
-- 			lM:debug("Looting " .. UnitName(lootUnit))
-- 			InteractUnit(lootUnit)
-- 			-- Manually loot if Auto Loot Interface Option not set
-- 			if GetCVar("AutoLootDefault") == "0" then
-- 				if LootFrame:IsShown() then
-- 					for l = 1, GetNumLootItems() do
-- 						if LootSlotHasItem(l) then
-- 							LootSlot(l)
-- 						end
-- 					end
-- 					CloseLoot()
-- 				end
-- 			end
-- 			-- Clean Up
-- 			ClearTarget()
-- 			looting = false
-- 			lM.lootUnit = nil
-- 			br.lootable = {}
-- 			return
-- 		end
-- 	end
-- end
-- function br.lootManager:findLoot()
-- 	if br.timer:useTimer("findLoot", br.getOptionValue("Auto Loot")) then
-- 		lM:debug("Find Unit")
-- 		for k, v in pairs(br.lootable) do
-- 			local thisUnit = br.lootable[k].unit
-- 			local hasLoot, canLoot = CanLootUnit(thisUnit)
-- 			if br.GetObjectExists(thisUnit) and canLoot then
-- 				--Print("Should loot "..UnitName(thisUnit))
-- 				lM:debug("Should loot " .. UnitName(thisUnit))
-- 				lM:getLoot(thisUnit)
-- 				break
-- 			end
-- 		end
-- 	end
-- end
function br.lootManager:lootCount()
	local lootCount = 0
	lM.lootUnit = nil
	for k, v in pairs(br.lootable) do
		if br.lootable[k] ~= nil then
			local thisUnit = br.lootable[k].unit
			local hasLoot, canLoot = CanLootUnit(br.lootable[k].guid)
			if br.GetObjectExists(thisUnit) and hasLoot then
				lootCount = lootCount + 1
				lM.lootUnit = br.lootable[k].unit
				break
			end
		end
	end
	return lootCount
end
function autoLoot()
	if br.getOptionCheck("Auto Loot") then
		--br.player.enemies.get(40)
		if (not br.isInCombat("player") or br.player.enemies.get(10)[1] == nil) then
			-- start loot manager
			if lM and lM:lootCount() > 0 then
				if lM:emptySlots() ~= 0 then
					if UnitCastingInfo("player") == nil and UnitChannelInfo("player") == nil and not IsMounted("player") then
						-- Print("Getting Loot")
						lM:getLoot(lM.lootUnit)
					end
				else
					br.ChatOverlay("Bags are full, nothing will be looted!")
				end
			end
		end
	end
end
