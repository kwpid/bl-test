local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local MapManager = {}
MapManager.__index = MapManager

-- Initialize Maps folder if it doesn't exist
local function setupMapsFolder()
        local mapsFolder = ReplicatedStorage:FindFirstChild("Maps")
        if not mapsFolder then
                mapsFolder = Instance.new("Folder")
                mapsFolder.Name = "Maps"
                mapsFolder.Parent = ReplicatedStorage
        end
        return mapsFolder
end

-- Create a legacy map from existing Workspace structure
local function createLegacyMapFromWorkspace()
        local workspace = game:GetService("Workspace")
        local stage = workspace:FindFirstChild("Stage")
        
        if not stage then
                warn("MapManager: Cannot find Workspace.Stage for legacy migration")
                return nil
        end
        
        local mapsFolder = setupMapsFolder()
        
        -- Check if legacy map already exists
        if mapsFolder:FindFirstChild("Legacy_1v1") then
                return mapsFolder:FindFirstChild("Legacy_1v1")
        end
        
        -- Create a new map model from existing stage parts
        local legacyMap = Instance.new("Model")
        legacyMap.Name = "Legacy_1v1"
        
        local requiredParts = {"Plate1", "Plate2", "T1", "T2", "BallSpawn"}
        for _, partName in ipairs(requiredParts) do
                local part = stage:FindFirstChild(partName)
                if part then
                        local clone = part:Clone()
                        clone.Parent = legacyMap
                else
                        warn("MapManager: Legacy stage missing part:", partName)
                end
        end
        
        -- Add config IntValue
        local config = Instance.new("IntValue")
        config.Name = "Config"
        config.Value = 2
        config.Parent = legacyMap
        
        legacyMap.Parent = mapsFolder
        return legacyMap
end

-- Get all available maps from ReplicatedStorage/Maps
local function getAvailableMaps()
        local mapsFolder = setupMapsFolder()
        local maps = {}
        
        for _, map in ipairs(mapsFolder:GetChildren()) do
                if map:IsA("Model") then
                        table.insert(maps, map)
                end
        end
        
        -- If no maps exist, try to create legacy map from workspace
        if #maps == 0 then
                local legacyMap = createLegacyMapFromWorkspace()
                if legacyMap then
                        table.insert(maps, legacyMap)
                end
        end
        
        return maps
end

-- Select a random map from available maps
local function selectRandomMap()
        local availableMaps = getAvailableMaps()
        if #availableMaps == 0 then
                warn("MapManager: No maps found in ReplicatedStorage/Maps!")
                return nil
        end
        
        local randomIndex = math.random(1, #availableMaps)
        return availableMaps[randomIndex]
end

-- Get max players for a map from its Config
local function getMapMaxPlayers(map)
        if not map then return 2 end -- Default to 1v1
        
        local config = map:FindFirstChild("Config")
        if config and config:IsA("IntValue") then
                return config.Value
        end
        
        return 2 -- Default to 1v1
end

-- Clone and setup a game arena from a selected map
function MapManager.createGameArena(gameId, offsetIndex, mapContainer)
        local selectedMap = selectRandomMap()
        
        if not selectedMap then
                warn("MapManager: Failed to select a map for game", gameId)
                return nil
        end
        
        local arena = selectedMap:Clone()
        arena.Name = "Arena_" .. gameId
        
        -- Apply offset position for multiple simultaneous games
        local offsetPos = Vector3.new(offsetIndex * 300, 0, 0)
        arena:PivotTo(arena:GetPivot() + offsetPos)
        arena.Parent = mapContainer
        
        -- Get necessary references from the arena
        local refs = {
                BallSpawn = arena:FindFirstChild("BallSpawn"),
                T1 = arena:FindFirstChild("T1"),
                T2 = arena:FindFirstChild("T2"),
                Plate1 = arena:FindFirstChild("Plate1"),
                Plate2 = arena:FindFirstChild("Plate2"),
        }
        
        -- Setup additional references for UI boards if they exist
        if refs.Plate1 then
                refs.Board1 = refs.Plate1:FindFirstChild("Board")
        end
        if refs.Plate2 then
                refs.Board2 = refs.Plate2:FindFirstChild("Board")
        end
        
        -- Validate critical references
        if not refs.BallSpawn or not refs.T1 or not refs.T2 then
                warn("MapManager: Selected map missing critical parts! Ensure map has BallSpawn, T1, and T2.")
                arena:Destroy()
                return nil
        end
        
        return arena, refs
end

-- Get max players from the selected map's config
function MapManager.getMapPlayerCount()
        local selectedMap = selectRandomMap()
        if not selectedMap then return 2 end
        return getMapMaxPlayers(selectedMap)
end

-- Validate that all required parts exist in a map
function MapManager.validateMap(map)
        local required = {"BallSpawn", "T1", "T2"}
        
        for _, partName in ipairs(required) do
                if not map:FindFirstChild(partName) then
                        return false, "Map missing required part: " .. partName
                end
        end
        
        return true
end

-- List all available maps (useful for debugging)
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
