local Players = game:GetService("Players")

local function onCharacterAdded(character)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.WalkSpeed = 21
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

print("Player setup initialized - WalkSpeed: 21")
