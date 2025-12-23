local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryDataStore = DataStoreService:GetDataStore("PlayerInventory_v1")


local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

local function createRemote(className, name)
	local remote = remoteEvents:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remoteEvents
	end
	return remote
end

local getInventoryFunction = createRemote("RemoteFunction", "GetInventoryFunction")
local getEquippedItemsFunction = createRemote("RemoteFunction", "GetEquippedItemsFunction")
local equipItemEvent = createRemote("RemoteEvent", "EquipItemEvent")
local inventoryUpdatedEvent = createRemote("RemoteEvent", "InventoryUpdatedEvent")
local sellItemEvent = createRemote("RemoteEvent", "SellItemEvent")
local sellAllItemEvent = createRemote("RemoteEvent", "SellAllItemEvent")
local toggleLockItemEvent = createRemote("RemoteEvent", "ToggleLockItemEvent")


local sessionData = {}


local SWORD_DEFINITIONS = {
	["DefaultSword"] = {
		Name = "DefaultSword",
		RobloxId = 1133333333,

		Value = 0,
		Rarity = "Common",
	},
	["Dark Scythe"] = {
		Name = "Dark Scythe",
		RobloxId = 1133333334,
		Value = 1000,
		Rarity = "Rare",
	}
}

local function getFullItemData(itemName)
	local def = SWORD_DEFINITIONS[itemName]
	if def then
		return {
			Name = def.Name,
			RobloxId = def.RobloxId,
			Value = def.Value,
			Rarity = def.Rarity,
			IsLocked = false,
		}
	end
	return nil
end

local function loadData(player)
	local userId = player.UserId
	local success, data = pcall(function()
		return InventoryDataStore:GetAsync(tostring(userId))
	end)

	if success and data then
		sessionData[userId] = data
	else
		sessionData[userId] = {
			Inventory = {},
			Equipped = {}
		}
	end

	local STARTER_ITEMS = { "DefaultSword", "Dark Scythe" }


	local inventory = sessionData[userId].Inventory
	

	local ownedItems = {}
	for _, item in ipairs(inventory) do
		ownedItems[item.Name] = true
	end


	for _, itemName in ipairs(STARTER_ITEMS) do
		if not ownedItems[itemName] then
			local itemData = getFullItemData(itemName)
			if itemData then
				table.insert(inventory, itemData)
			end
		end
	end


	if #sessionData[userId].Equipped == 0 then
		table.insert(sessionData[userId].Equipped, "DefaultSword")
	end
end

local function saveData(player)
	local userId = player.UserId
	if sessionData[userId] then
		pcall(function()
			InventoryDataStore:SetAsync(tostring(userId), sessionData[userId])
		end)
	end
end


getInventoryFunction.OnServerInvoke = function(player)
	local data = sessionData[player.UserId]
	return data and data.Inventory or {}
end

getEquippedItemsFunction.OnServerInvoke = function(player)
	local data = sessionData[player.UserId]
	local data = sessionData[player.UserId]

	if not data then return {} end
	
	local equippedNames = {}
	for _, itemName in ipairs(data.Equipped) do

		if SWORD_DEFINITIONS[itemName] then
			table.insert(equippedNames, itemName)
		end
	end
	return equippedNames
end

equipItemEvent.OnServerEvent:Connect(function(player, itemName, isUnequip)
	local data = sessionData[player.UserId]
	if not data then return end



	local ownsItem = false
	for _, item in ipairs(data.Inventory) do
		if item.Name == itemName then
			ownsItem = true
			break
		end
	end

	if not ownsItem then return end

	if isUnequip then
		local index = table.find(data.Equipped, itemName)
		if index then
			table.remove(data.Equipped, index)
		end
	
		if #data.Equipped == 0 then
			table.insert(data.Equipped, "DefaultSword")
		end
	else

		data.Equipped = { itemName }
	end

	inventoryUpdatedEvent:FireClient(player)
	

	if player.Character then
		local newSword = data.Equipped[1] or "None"
		player.Character:SetAttribute("EquippedSword", newSword)
	end
end)

Players.PlayerAdded:Connect(loadData)
Players.PlayerRemoving:Connect(saveData)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadData, player)
end


local DataService = {}
function DataService.GetEquippedSword(player)
	local data = sessionData[player.UserId]
	return data and data.Equipped[1] or "DefaultSword"
end

_G.DataService = DataService


return DataService
