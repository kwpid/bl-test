local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local swingEvent = ReplicatedStorage:WaitForChild("SwingEvent")
local ballHitEvent = ReplicatedStorage:WaitForChild("BallHitEvent")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local isOnCooldown = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or isOnCooldown then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isOnCooldown = true
                swingEvent:FireServer()
                
                task.delay(0.5, function()
                        isOnCooldown = false
                end)
        end
end)

ballHitEvent.OnClientEvent:Connect(function()
        local cameraDirection = camera.CFrame.LookVector
        ballHitEvent:FireServer(cameraDirection)
end)

print("Input client initialized")
