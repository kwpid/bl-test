local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("BallConfig"))

local function onCharacterAdded(character)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.WalkSpeed = Config.Player.WALKSPEED
end

local function onPlayerAdded(player)
        player.CharacterAdded:Connect(onCharacterAdded)
        
        if player.Character then
                onCharacterAdded(player.Character)
        end
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
end

print("Player setup initialized - WalkSpeed:", Config.Player.WALKSPEED)
