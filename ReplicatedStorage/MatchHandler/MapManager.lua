local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapManager = {}
local function setupMapsFolder()
	local mapsFolder = ReplicatedStorage:FindFirstChild("Maps")
	if not mapsFolder then
		mapsFolder = Instance.new("Folder")
		mapsFolder.Name = "Maps"
		mapsFolder.Parent = ReplicatedStorage
	end
	return mapsFolder
end

local function getAvailableMaps()
	local mapsFolder = setupMapsFolder()
	local maps = {}

	for _, map in ipairs(mapsFolder:GetChildren()) do
		if map:IsA("Model") then
			table.insert(maps, map)
		end
	end

	return maps
end

local function selectRandomMap()
	local availableMaps = getAvailableMaps()
	if #availableMaps == 0 then
		warn("MapManager: No maps found in ReplicatedStorage/Maps!")
		return nil
	end

	local randomIndex = math.random(1, #availableMaps)
	return availableMaps[randomIndex]
end

local function getMapMaxPlayers(map)
	if not map then return 2 end

	local config = map:FindFirstChild("Config")
	if config and config:IsA("IntValue") then
		return config.Value
	end

	return 2
end

function MapManager.createGameArena(gameId, offsetIndex, mapContainer)
	local selectedMap = selectRandomMap()

	if not selectedMap then
		warn("MapManager: Failed to select a map for game", gameId)
		return nil
	end

	local arena = selectedMap:Clone()
	arena.Name = "Arena_" .. gameId

	local offsetPos = Vector3.new(offsetIndex * 2500, 0, 0)
	arena:PivotTo(arena:GetPivot() + offsetPos)
	arena.Parent = mapContainer
	local refs = {
		BallSpawn = arena:FindFirstChild("BallSpawn"),
		T1 = arena:FindFirstChild("T1"),
		T2 = arena:FindFirstChild("T2"),
		Plate1 = arena:FindFirstChild("Plate1"),
		Plate2 = arena:FindFirstChild("Plate2"),
	}

	if refs.Plate1 then
		refs.Board1 = refs.Plate1:FindFirstChild("Board")
	end
	if refs.Plate2 then
		refs.Board2 = refs.Plate2:FindFirstChild("Board")
	end
	if not refs.BallSpawn or not refs.T1 or not refs.T2 then
		warn("MapManager: Selected map missing critical parts! Ensure map has BallSpawn, T1, and T2.")
		arena:Destroy()
		return nil
	end

	return arena, refs
end

function MapManager.getMapPlayerCount()
	local selectedMap = selectRandomMap()
	if not selectedMap then return 2 end
	return getMapMaxPlayers(selectedMap)
end

function MapManager.validateMap(map)
	local required = {"BallSpawn", "T1", "T2"}

	for _, partName in ipairs(required) do
		if not map:FindFirstChild(partName) then
			return false, "Map missing required part: " .. partName
		end
	end

	return true
end

function MapManager.listMaps()
	local maps = getAvailableMaps()
	local mapInfo = {}

	for _, map in ipairs(maps) do
		table.insert(mapInfo, {
			Name = map.Name,
			MaxPlayers = getMapMaxPlayers(map)
		})
	end

	return mapInfo
end

return MapManager
