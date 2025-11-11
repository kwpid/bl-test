local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dashEvent = ReplicatedStorage:WaitForChild("DashEvent")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local DASH_COOLDOWN = 3
local lastDashTime = 0

local function canDash()
        return tick() - lastDashTime >= DASH_COOLDOWN
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
        local dashDirection = lookDirection
        
        if dashDirection.Magnitude > 0 then
                dashEvent:FireServer(dashDirection)
                lastDashTime = tick()
        end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
                performDash()
        end
end)

print("Dash client initialized - Keybind: Shift, Cooldown:", DASH_COOLDOWN)
