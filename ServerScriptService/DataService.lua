local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryDataStore = DataStoreService:GetDataStore("PlayerInventory_v1")

-- Remote Setup
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

-- Player Data Cache
local sessionData = {}

-- Items Configuration (Template)
local SWORD_DEFINITIONS = {
	["DefaultSword"] = {
		Name = "DefaultSword",
		RobloxId = 1133333333, -- Placeholder if not provided, but GUI uses it for icons
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
		-- New player or load failed
		sessionData[userId] = {
			Inventory = {
				getFullItemData("DefaultSword"),
				getFullItemData("Dark Scythe")
			},
			Equipped = { "DefaultSword" } -- Array of equipped names (assuming one for now)
		}
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

-- Remote Handlers
getInventoryFunction.OnServerInvoke = function(player)
	local data = sessionData[player.UserId]
	return data and data.Inventory or {}
end

getEquippedItemsFunction.OnServerInvoke = function(player)
	local data = sessionData[player.UserId]
	-- GUI expects a list of RobloxIds or Names? 
	-- Looking at InventoryGUI.lua line 135: for _, robloxId in ipairs(equippedResult) do
	-- It expects RobloxIds.
	if not data then return {} end
	
	local equippedIds = {}
	for _, itemName in ipairs(data.Equipped) do
		local def = SWORD_DEFINITIONS[itemName]
		if def then
			table.insert(equippedIds, def.RobloxId)
		end
	end
	return equippedIds
end

equipItemEvent.OnServerEvent:Connect(function(player, robloxId, isUnequip)
	local data = sessionData[player.UserId]
	if not data then return end

	-- Find item name by RobloxId
	local itemName = nil
	for _, item in ipairs(data.Inventory) do
		if item.RobloxId == robloxId then
			itemName = item.Name
			break
		end
	end

	if not itemName then return end

	if isUnequip then
		local index = table.find(data.Equipped, itemName)
		if index then
			table.remove(data.Equipped, index)
		end
	else
		-- Only allow one equipped at a time for swords?
		data.Equipped = { itemName }
	end

	inventoryUpdatedEvent:FireClient(player)
	
	-- Tell SwordServer to refresh
	if player.Character then
		-- Fire custom attribute or bindable?
		-- We'll just trigger character reload or equipment update logic in SwordServer
		local swordServer = player.Character:SetAttribute("EquippedSword", data.Equipped[1] or "None")
	end
end)

Players.PlayerAdded:Connect(loadData)
Players.PlayerRemoving:Connect(saveData)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadData, player)
end

-- Export for other server scripts
local DataService = {}
function DataService.GetEquippedSword(player)
	local data = sessionData[player.UserId]
	return data and data.Equipped[1] or "DefaultSword"
end

_G.DataService = DataService -- Simple way to share across scripts if not using ModuleScript

print("DataService initialized")
return DataService
