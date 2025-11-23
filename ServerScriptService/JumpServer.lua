local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local doubleJumpEvent = ReplicatedStorage.RemoteEvents:WaitForChild("DoubleJumpEvent")

local jumpEffect = ReplicatedStorage:FindFirstChild("JumpEffect")
if not jumpEffect then
	jumpEffect = Instance.new("Part")
	jumpEffect.Name = "JumpEffect"
	jumpEffect.Size = Vector3.new(0.5, 4, 4)
	jumpEffect.Transparency = 0.5
	jumpEffect.Anchored = true
	jumpEffect.CanCollide = false
	jumpEffect.Material = Enum.Material.Neon
	jumpEffect.Shape = Enum.PartType.Cylinder
	jumpEffect.Color = Color3.fromRGB(255, 255, 255)
	jumpEffect.Parent = ReplicatedStorage
end

doubleJumpEvent.OnServerEvent:Connect(function(player)
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			doubleJumpEvent:FireClient(otherPlayer, player)
		end
	end
end)
