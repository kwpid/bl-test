local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local swingEvent = ReplicatedStorage:WaitForChild("SwingEvent")
local ballHitEvent = ReplicatedStorage:WaitForChild("BallHitEvent")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		swingEvent:FireServer()
	end
end)

ballHitEvent.OnClientEvent:Connect(function()
	local cameraDirection = camera.CFrame.LookVector
	ballHitEvent:FireServer(cameraDirection)
end)
