local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dashEvent = ReplicatedStorage:WaitForChild("DashEvent")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local DASH_COOLDOWN = 5
local BALL_DETECTION_ANGLE = 30
local BALL_DETECTION_DISTANCE = 50

local lastDashTime = 0

local function canDash()
        return tick() - lastDashTime >= DASH_COOLDOWN
end

local function isFacingBall()
        local ball = workspace:FindFirstChild("Ball") or workspace:FindFirstChild("ClientBall")
        if not ball then return false, nil end
        
        local character = player.Character
        if not character then return false, nil end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false, nil end
        
        local toBall = (ball.Position - hrp.Position)
        local distance = toBall.Magnitude
        
        if distance > BALL_DETECTION_DISTANCE then
                return false, nil
        end
        
        local lookDirection = camera.CFrame.LookVector
        local toBallDirection = toBall.Unit
        
        local dotProduct = lookDirection:Dot(toBallDirection)
        local angle = math.deg(math.acos(dotProduct))
        
        if angle <= BALL_DETECTION_ANGLE then
                return true, toBallDirection
        end
        
        return false, nil
end

local function performDash()
        if not canDash() then 
                return 
        end
        
        local character = player.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        
        local lookDirection = camera.CFrame.LookVector
        local facingBall, ballDirection = isFacingBall()
        
        local dashDirection
        local allowVertical = false
        
        if facingBall and ballDirection then
                dashDirection = ballDirection
                allowVertical = true
        else
                dashDirection = Vector3.new(lookDirection.X, 0, lookDirection.Z)
                allowVertical = false
        end
        
        if dashDirection.Magnitude > 0 then
                dashEvent:FireServer(dashDirection, allowVertical)
                lastDashTime = tick()
        end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Q then
                performDash()
        end
end)

print("Dash client initialized - Keybind: Q, Cooldown:", DASH_COOLDOWN)
