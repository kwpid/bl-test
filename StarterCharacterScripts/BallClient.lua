local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BallPhysics = require(ReplicatedStorage.BallPhysics)
local Config = require(ReplicatedStorage.BallConfig)

local ballUpdateEvent = ReplicatedStorage:WaitForChild("BallUpdateEvent")
local player = Players.LocalPlayer
local ball = workspace:WaitForChild("Ball")

local clientBall = ball:Clone()
clientBall.Name = "ClientBall"
clientBall.Transparency = 0
clientBall.Parent = workspace

ball.Transparency = 1

local trail = Instance.new("Trail")
trail.Parent = clientBall
trail.Lifetime = Config.Visual.TRAIL_LIFETIME
trail.MinLength = Config.Visual.TRAIL_MIN_LENGTH
trail.FaceCamera = true
trail.WidthScale = NumberSequence.new(1, 0)
trail.Transparency = NumberSequence.new(0.3, 1)

local attachment0 = Instance.new("Attachment")
attachment0.Parent = clientBall

local attachment1 = Instance.new("Attachment")
attachment1.Parent = clientBall

trail.Attachment0 = attachment0
trail.Attachment1 = attachment1

local clientState = BallPhysics.new(clientBall.Position)
local serverStateBuffer = {}
local lastServerUpdate = tick()

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {ball, clientBall, player.Character}

local function interpolateColor(percent)
        return Color3.new(1, 1, 1):Lerp(Color3.new(0.7, 0.6, 1), percent)
end

ballUpdateEvent.OnClientEvent:Connect(function(serverState)
        table.insert(serverStateBuffer, {
                state = serverState,
                timestamp = tick(),
        })
        
        if #serverStateBuffer > 10 then
                table.remove(serverStateBuffer, 1)
        end
        
        lastServerUpdate = tick()
end)

local function checkCollision(from, to)
        local direction = (to - from)
        local distance = direction.Magnitude
        if distance == 0 then return nil end
        
        local rayResult = workspace:Raycast(from, direction.Unit * (distance + clientBall.Size.X/2), raycastParams)
        return rayResult
end

local function getGroundHeight(position)
        local rayOrigin = Vector3.new(position.X, position.Y + 10, position.Z)
        local rayDirection = Vector3.new(0, -200, 0)
        local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        return rayResult and rayResult.Position.Y or 0
end

RunService.Heartbeat:Connect(function(dt)
        if #serverStateBuffer > 0 then
                local serverState = serverStateBuffer[#serverStateBuffer].state
                
                local positionDiff = (serverState.position - clientState.position).Magnitude
                if positionDiff > 5 then
                        clientState:deserialize(serverState)
                else
                        local alpha = math.clamp(dt * 10, 0, 1)
                        clientState.position = clientState.position:Lerp(serverState.position, alpha)
                        clientState.velocity = clientState.velocity:Lerp(serverState.velocity, alpha)
                        clientState.isMoving = serverState.isMoving
                end
        end
        
        if tick() - lastServerUpdate < 0.5 then
                clientState:update(dt, checkCollision)
                
                local groundHeight = getGroundHeight(clientState.position)
                clientState:enforceFloatHeight(groundHeight)
        end
        
        clientBall.Position = clientState.position
        
        local speedPercent = clientState:getSpeedPercent()
        trail.Color = ColorSequence.new(interpolateColor(speedPercent))
        trail.Enabled = clientState:getSpeed() > Config.Visual.MIN_TRAIL_SPEED
end)

print("Ball client initialized")
