local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryDataStore = DataStoreService:GetDataStore("PlayerInventory_v1")
local StatsDataStore = DataStoreService:GetDataStore("PlayerStats_v1")

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

local statsUpdatedEvent = createRemote("RemoteEvent", "StatsUpdatedEvent")

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

local function calculateLevelFromXP(xp)
	local level = 1
	local cumulativeXP = 0
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

========
	
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
	
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	while true do
		local xpForNextLevel = level * 100
		if cumulativeXP + xpForNextLevel > xp then
			break
		end
		cumulativeXP = cumulativeXP + xpForNextLevel
		level = level + 1
	end
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

========
	
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
	
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	return level
end

local function getXPForLevel(level)
	local totalXP = 0
	for i = 1, level - 1 do
		totalXP = totalXP + (i * 100)
	end
	return totalXP
end

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
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

========
	
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
	
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
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
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

========
	
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
	
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
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
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

	local statsSuccess, statsData = pcall(function()
		return StatsDataStore:GetAsync(tostring(userId))
	end)

========
=======
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	
	local statsSuccess, statsData = pcall(function()
		return StatsDataStore:GetAsync(tostring(userId))
	end)
	
<<<<<<< HEAD
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	if statsSuccess and statsData then
		sessionData[userId].Stats = statsData
	else
		sessionData[userId].Stats = {
			Wins = 0,
			Losses = 0,
			WinStreak = 0,
			PeakWinStreak = 0,
			XP = 0,
			TotalGoals = 0,
		}
	end
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local stats = sessionData[userId].Stats
	local level = calculateLevelFromXP(stats.XP)

========
=======
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local stats = sessionData[userId].Stats
	local level = calculateLevelFromXP(stats.XP)
	
<<<<<<< HEAD
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = stats.Wins
	wins.Parent = leaderstats
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

========
	
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
	
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	local winStreak = Instance.new("IntValue")
	winStreak.Name = "Win Streak"
	winStreak.Value = stats.WinStreak
	winStreak.Parent = leaderstats
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

========
	
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
	
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	local levelValue = Instance.new("IntValue")
	levelValue.Name = "Level"
	levelValue.Value = level
	levelValue.Parent = leaderstats
end

local function saveData(player)
	local userId = player.UserId
	if sessionData[userId] then
		pcall(function()
			InventoryDataStore:SetAsync(tostring(userId), {
				Inventory = sessionData[userId].Inventory,
				Equipped = sessionData[userId].Equipped
			})
		end)
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

========
		
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
		
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
		pcall(function()
			StatsDataStore:SetAsync(tostring(userId), sessionData[userId].Stats)
		end)
	end
end

getInventoryFunction.OnServerInvoke = function(player)
	local data = sessionData[player.UserId]
	return data and data.Inventory or {}
end

getEquippedItemsFunction.OnServerInvoke = function(player)
	local data = sessionData[player.UserId]

	if not data then return {} end
<<<<<<< HEAD

=======
	
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
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
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

========
		
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
		
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
		if #data.Equipped == 0 then
			table.insert(data.Equipped, "DefaultSword")
		end
	else
		data.Equipped = { itemName }
	end

	inventoryUpdatedEvent:FireClient(player)
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

========
	
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
	
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
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

function DataService.AddWin(player)
	local data = sessionData[player.UserId]
	if not data or not data.Stats then return end
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

	data.Stats.Wins = data.Stats.Wins + 1
	data.Stats.WinStreak = data.Stats.WinStreak + 1

	if data.Stats.WinStreak > data.Stats.PeakWinStreak then
		data.Stats.PeakWinStreak = data.Stats.WinStreak
	end

========
=======
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	
	data.Stats.Wins = data.Stats.Wins + 1
	data.Stats.WinStreak = data.Stats.WinStreak + 1
	
	if data.Stats.WinStreak > data.Stats.PeakWinStreak then
		data.Stats.PeakWinStreak = data.Stats.WinStreak
	end
	
<<<<<<< HEAD
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	DataService.UpdateLeaderStats(player)
end

function DataService.AddLoss(player)
	local data = sessionData[player.UserId]
	if not data or not data.Stats then return end
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

	data.Stats.Losses = data.Stats.Losses + 1
	data.Stats.WinStreak = 0

========
=======
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	
	data.Stats.Losses = data.Stats.Losses + 1
	data.Stats.WinStreak = 0
	
<<<<<<< HEAD
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	DataService.UpdateLeaderStats(player)
end

function DataService.AddXP(player, amount)
	local data = sessionData[player.UserId]
	if not data or not data.Stats then return end
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

	data.Stats.XP = data.Stats.XP + amount

========
	
	data.Stats.XP = data.Stats.XP + amount
	
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
	
	data.Stats.XP = data.Stats.XP + amount
	
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	local newLevel = calculateLevelFromXP(data.Stats.XP)
	DataService.UpdateLeaderStats(player)
end

function DataService.AddGoal(player)
	local data = sessionData[player.UserId]
	if not data or not data.Stats then return end
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

========
	
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
	
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	data.Stats.TotalGoals = data.Stats.TotalGoals + 1
end

function DataService.UpdateLeaderStats(player)
	local data = sessionData[player.UserId]
	if not data or not data.Stats then return end
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local stats = data.Stats
	local level = calculateLevelFromXP(stats.XP)

========
=======
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	
	local stats = data.Stats
	local level = calculateLevelFromXP(stats.XP)
	
<<<<<<< HEAD
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	local winsValue = leaderstats:FindFirstChild("Wins")
	if winsValue then
		winsValue.Value = stats.Wins
	end
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

========
	
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
	
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	local winStreakValue = leaderstats:FindFirstChild("Win Streak")
	if winStreakValue then
		winStreakValue.Value = stats.WinStreak
	end
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

========
	
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
	
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	local levelValue = leaderstats:FindFirstChild("Level")
	if levelValue then
		levelValue.Value = level
	end
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

========
	
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
	
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	statsUpdatedEvent:FireClient(player, stats, level)
end

function DataService.GetStats(player)
	local data = sessionData[player.UserId]
	if not data or not data.Stats then return nil end
<<<<<<< HEAD
<<<<<<<< HEAD:ReplicatedStorage/DataService.lua

	local stats = data.Stats
	local level = calculateLevelFromXP(stats.XP)

========
=======
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	
	local stats = data.Stats
	local level = calculateLevelFromXP(stats.XP)
	
<<<<<<< HEAD
>>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80:ServerScriptService/DataService.lua
=======
>>>>>>> ea4cf3b7158848a244bfc943a493ca9819c44b80
	return {
		Wins = stats.Wins,
		Losses = stats.Losses,
		WinStreak = stats.WinStreak,
		PeakWinStreak = stats.PeakWinStreak,
		XP = stats.XP,
		Level = level,
		TotalGoals = stats.TotalGoals,
	}
end

_G.DataService = DataService

return DataService
