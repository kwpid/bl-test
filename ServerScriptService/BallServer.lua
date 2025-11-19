local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local BallPhysics = require(ReplicatedStorage.BallPhysics)
local Config = require(ReplicatedStorage.BallConfig)

local RemoteEvents = {
        ballUpdate = ReplicatedStorage:FindFirstChild("BallUpdateEvent") or Instance.new("RemoteEvent"),
        ballHit = ReplicatedStorage:FindFirstChild("BallHitEvent") or Instance.new("RemoteEvent"),
}
RemoteEvents.ballUpdate.Name = "BallUpdateEvent"
RemoteEvents.ballUpdate.Parent = ReplicatedStorage
RemoteEvents.ballHit.Name = "BallHitEvent"
RemoteEvents.ballHit.Parent = ReplicatedStorage

local map = workspace:WaitForChild("Map")
local spawn = map:WaitForChild("Spawn")
local goalBlue = map:WaitForChild("GoalDetectorBlue")
local goalRed = map:WaitForChild("GoalDetectorRed")

local ball = workspace:WaitForChild("Ball")
ball.Anchored = true
ball.CanCollide = false
ball.Shape = Enum.PartType.Ball

local spawnPosition = spawn.Position
local ballState = BallPhysics.new(spawnPosition)
ball.Position = spawnPosition
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = { ball }

local lastGroundCheck = 0
local lastNetworkUpdate = 0
local isResetting = false

local function updateRaycastFilter()
        local filterList = { ball }

        for _, player in pairs(Players:GetPlayers()) do
                if player.Character then
                        for _, part in pairs(player.Character:GetDescendants()) do
                                if part:IsA("BasePart") then
                                        table.insert(filterList, part)
                                end
                        end
                        
                        local sword = player.Character:FindFirstChild("HipSword")
                        if sword then
                                for _, part in pairs(sword:GetDescendants()) do
                                        if part:IsA("BasePart") then
                                                table.insert(filterList, part)
                                        end
                                end
                        end
                end
        end

        raycastParams.FilterDescendantsInstances = filterList
end

Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
                task.wait(0.5)
                updateRaycastFilter()
        end)
end)

updateRaycastFilter()

local function resetBall()
        isResetting = true
        ballState.position = spawnPosition
        ballState.velocity = Vector3.new(0, 0, 0)
        ballState.isMoving = false
        ballState.hitCount = 0
        ball.Position = spawnPosition
        RemoteEvents.ballUpdate:FireAllClients(ballState:serialize())
        task.wait(0.1)
        isResetting = false
end

local function checkGoalCollision(position)
        if isResetting then return end
        
        local ballRegion = Region3.new(position - Vector3.new(2, 2, 2), position + Vector3.new(2, 2, 2))
        ballRegion:ExpandToGrid(4)
        
        local blueMin = goalBlue.Position - (goalBlue.Size / 2)
        local blueMax = goalBlue.Position + (goalBlue.Size / 2)
        
        if position.X >= blueMin.X and position.X <= blueMax.X and
           position.Y >= blueMin.Y and position.Y <= blueMax.Y and
           position.Z >= blueMin.Z and position.Z <= blueMax.Z then
                print("GOAL! Blue team was scored on!")
                task.delay(Config.Goal.RESET_DELAY, resetBall)
                return true
        end
        
        local redMin = goalRed.Position - (goalRed.Size / 2)
        local redMax = goalRed.Position + (goalRed.Size / 2)
        
        if position.X >= redMin.X and position.X <= redMax.X and
           position.Y >= redMin.Y and position.Y <= redMax.Y and
           position.Z >= redMin.Z and position.Z <= redMax.Z then
                print("GOAL! Red team was scored on!")
                task.delay(Config.Goal.RESET_DELAY, resetBall)
                return true
        end
        
        return false
end

local function getGroundHeight(position)
        local rayOrigin = Vector3.new(position.X, position.Y + 10, position.Z)
        local rayDirection = Vector3.new(0, -200, 0)
        local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        return rayResult and rayResult.Position.Y or 0
end

local function checkCollision(from, to)
        local direction = (to - from)
        local distance = direction.Magnitude
        if distance == 0 then return nil end

        local rayResult = workspace:Raycast(from, direction.Unit * (distance + ball.Size.X / 2), raycastParams)
        return rayResult
end

RunService.Heartbeat:Connect(function(dt)
        if isResetting then return end
        
        local updated = ballState:update(dt, checkCollision)
        
        checkGoalCollision(ballState.position)

        lastGroundCheck = lastGroundCheck + dt
        if lastGroundCheck > 0.1 then
                local groundHeight = getGroundHeight(ballState.position)
                ballState:enforceFloatHeight(groundHeight)
                lastGroundCheck = 0
        end

        ball.Position = ballState.position

        lastNetworkUpdate = lastNetworkUpdate + dt
        if lastNetworkUpdate >= 1 / Config.Network.UPDATE_RATE then
                if updated or ballState.isMoving then
                        RemoteEvents.ballUpdate:FireAllClients(ballState:serialize())
                end
                lastNetworkUpdate = 0
        end
end)

local lastHitTime = 0

RemoteEvents.ballHit.OnServerEvent:Connect(function(player, cameraDirection)
        if isResetting then return end
        
        local character = player.Character
        if not character then return end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local currentTime = tick()
        if currentTime - lastHitTime < Config.Parry.MIN_HIT_INTERVAL then
                return
        end

        local distance = (hrp.Position - ballState.position).Magnitude
        if distance > Config.Parry.RANGE then
                warn(string.format("Ball too far: %.1f studs (max: %d)", distance, Config.Parry.RANGE))
                return
        end

        if not cameraDirection or typeof(cameraDirection) ~= "Vector3" then
                warn("Invalid camera direction")
                return
        end

        lastHitTime = currentTime

        ballState:applyHit(cameraDirection)

        RemoteEvents.ballUpdate:FireAllClients(ballState:serialize())
end)

print("Ball server initialized")
