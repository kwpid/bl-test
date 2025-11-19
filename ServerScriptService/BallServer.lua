local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local BallPhysics = require(ReplicatedStorage.BallPhysics)
local Config = require(ReplicatedStorage.BallConfig)

local RemoteEventsFolder = ReplicatedStorage:WaitForChild(Config.Paths.REMOTE_EVENTS_FOLDER)

local RemoteEvents = {
        ballUpdate = RemoteEventsFolder:WaitForChild("BallUpdateEvent"),
}

local ServerEvents = {
        ballHit = RemoteEventsFolder:WaitForChild("ServerBallHit"),
}

local ball = workspace:WaitForChild("Ball")
ball.Anchored = true
ball.CanCollide = false
ball.Shape = Enum.PartType.Ball

local ballState = BallPhysics.new(ball.Position)
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = { ball }

local lastGroundCheck = 0
local lastNetworkUpdate = 0

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

local currentGroundHeight = 0

RunService.Heartbeat:Connect(function(dt)
        lastGroundCheck = lastGroundCheck + dt
        if lastGroundCheck > 0.1 then
                currentGroundHeight = getGroundHeight(ballState.position)
                lastGroundCheck = 0
        end

        local updated = ballState:update(dt, checkCollision, currentGroundHeight)

        ballState:enforceFloatHeight(currentGroundHeight)

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

ServerEvents.ballHit.Event:Connect(function(player, cameraDirection)
        local currentTime = tick()
        if currentTime - lastHitTime < Config.Parry.MIN_HIT_INTERVAL then
                return
        end

        if not cameraDirection or typeof(cameraDirection) ~= "Vector3" then
                return
        end

        lastHitTime = currentTime

        ballState:applyHit(cameraDirection)

        RemoteEvents.ballUpdate:FireAllClients(ballState:serialize())
end)

print("Ball server initialized")
