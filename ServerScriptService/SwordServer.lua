local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.BallConfig)

local SWORD_FOLDER = ReplicatedStorage:WaitForChild("Swords")
local DEFAULT_SWORD_NAME = "DefaultSword"
local DUMMY = workspace:WaitForChild("Dummy")
local DUMMY_TORSO_ATTACHMENT = DUMMY:WaitForChild("Torso"):WaitForChild("SwordAttachment")
local DUMMY_ARM_ATTACHMENT = DUMMY:WaitForChild("Right Arm"):WaitForChild("SwordSwing")

local RemoteEvents = {
        swing = ReplicatedStorage:FindFirstChild("SwingEvent") or Instance.new("RemoteEvent"),
        ballHit = ReplicatedStorage:WaitForChild("BallHitEvent"),
}
RemoteEvents.swing.Name = "SwingEvent"
RemoteEvents.swing.Parent = ReplicatedStorage

local playerData = {}
local ballHitImmunity = {}

local function cloneAttachment(parent, template, name)
        if parent:FindFirstChild(name) then return end
        local cloned = template:Clone()
        cloned.Name = name
        cloned.Parent = parent
end

local function equipSword(character, swordModel)
        local torso = character:FindFirstChild("Torso")
        local rightArm = character:FindFirstChild("Right Arm")
        if not torso or not rightArm then return end
        
        cloneAttachment(torso, DUMMY_TORSO_ATTACHMENT, "SwordAttachment")
        cloneAttachment(rightArm, DUMMY_ARM_ATTACHMENT, "SwordSwing")
        
        local swordClone = swordModel:Clone()
        swordClone.Name = "HipSword"
        swordClone.Parent = character
        
        local handle = swordClone:FindFirstChild("Handle")
        if not handle then return end
        
        local swordAttachment = handle:FindFirstChild("SwordAttachment")
        local torsoAttachment = torso:FindFirstChild("SwordAttachment")
        
        if swordAttachment and torsoAttachment then
                local weld = Instance.new("Weld")
                weld.Name = "SwordWeld"
                weld.Part0 = torso
                weld.Part1 = handle
                weld.C0 = torsoAttachment.CFrame
                weld.C1 = swordAttachment.CFrame
                weld.Parent = torso
        end
end

local function isBallInHitImmunity(userId)
        if not ballHitImmunity[userId] then return false end
        return tick() - ballHitImmunity[userId] < Config.Parry.HIT_IMMUNITY_TIME
end

local function setBallHitImmunity(userId)
        ballHitImmunity[userId] = tick()
end

local function createParryWindow(player, character, animator, animations, weld, attachments, cameraDirection)
        local parryWindow = {
                active = true,
                hitBall = false,
                connection = nil,
                startTime = tick(),
                cameraDirection = cameraDirection,
        }
        
        local failTrack = animator:LoadAnimation(animations.fail)
        failTrack:Play()
        
        parryWindow.connection = RunService.Heartbeat:Connect(function()
                if not parryWindow.active then
                        parryWindow.connection:Disconnect()
                        return
                end
                
                if parryWindow.hitBall then return end
                
                local ball = workspace:FindFirstChild("Ball")
                if not ball then return end
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then 
                        parryWindow.active = false
                        return 
                end
                
                if isBallInHitImmunity(player.UserId) then
                        return
                end
                
                local timeSinceStart = tick() - parryWindow.startTime
                if timeSinceStart < Config.Parry.MIN_PARRY_TIME then
                        return
                end
                
                local distance = (hrp.Position - ball.Position).Magnitude
                
                if distance <= Config.Parry.RANGE then
                        parryWindow.hitBall = true
                        parryWindow.active = false
                        
                        setBallHitImmunity(player.UserId)
                        
                        failTrack:Stop()
                        
                        weld.Part0 = attachments.rightArm
                        weld.C0 = attachments.swing.CFrame
                        weld.C1 = attachments.sword.CFrame * CFrame.Angles(0, 0, math.rad(90))
                        
                        local parryTrack = animator:LoadAnimation(animations.parry)
                        parryTrack:Play()
                        
                        task.wait(0.05)
                        RemoteEvents.ballHit:FireClient(player, parryWindow.cameraDirection)
                        
                        parryTrack.Stopped:Connect(function()
                                weld.Part0 = attachments.torso
                                weld.C0 = attachments.torsoAttachment.CFrame
                                weld.C1 = attachments.sword.CFrame
                        end)
                        
                        playerData[player.UserId].cooldown = false
                end
        end)
        
        failTrack.Stopped:Connect(function()
                if parryWindow.active then
                        parryWindow.active = false
                        playerData[player.UserId].cooldown = false
                end
        end)
        
        task.delay(Config.Parry.TIMEOUT, function()
                if parryWindow.active then
                        parryWindow.active = false
                        failTrack:Stop()
                        playerData[player.UserId].cooldown = false
                end
        end)
        
        return parryWindow
end

local function onSwing(player, cameraDirection)
        if not cameraDirection or typeof(cameraDirection) ~= "Vector3" then return end
        
        local character = player.Character
        if not character then return end
        
        local data = playerData[player.UserId]
        if not data or data.cooldown then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
                animator = Instance.new("Animator")
                animator.Parent = humanoid
        end
        
        local sword = character:FindFirstChild("HipSword")
        if not sword then return end
        
        local handle = sword:FindFirstChild("Handle")
        if not handle then return end
        
        local animations = {
                parry = handle:FindFirstChild("Parry"),
                fail = handle:FindFirstChild("ParryFail"),
        }
        
        if not animations.parry or not animations.fail then
                warn("Animations missing for player: " .. player.Name)
                return
        end
        
        data.cooldown = true
        
        local torso = character:FindFirstChild("Torso")
        local rightArm = character:FindFirstChild("Right Arm")
        
        if not torso or not rightArm then
                data.cooldown = false
                return
        end
        
        local attachments = {
                torso = torso,
                rightArm = rightArm,
                torsoAttachment = torso:FindFirstChild("SwordAttachment"),
                swing = rightArm:FindFirstChild("SwordSwing"),
                sword = handle:FindFirstChild("SwordAttachment"),
        }
        
        if not attachments.torsoAttachment or not attachments.swing or not attachments.sword then
                data.cooldown = false
                return
        end
        
        local weld = torso:FindFirstChild("SwordWeld")
        if not weld then
                data.cooldown = false
                return
        end
        
        createParryWindow(player, character, animator, animations, weld, attachments, cameraDirection)
end

RemoteEvents.swing.OnServerEvent:Connect(onSwing)

local function onCharacterAdded(character)
        local swordModel = SWORD_FOLDER:FindFirstChild(DEFAULT_SWORD_NAME)
        if swordModel then
                task.wait(0.5)
                equipSword(character, swordModel)
        end
end

local function onPlayerAdded(player)
        playerData[player.UserId] = {
                cooldown = false,
        }
        
        player.CharacterAdded:Connect(onCharacterAdded)
        if player.Character then
                onCharacterAdded(player.Character)
        end
end

local function onPlayerRemoving(player)
        playerData[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
end

print("Sword server initialized")
