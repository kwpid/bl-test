local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local PARRY_RANGE = 10 -- Distance in studs that the ball must be within to parry

local swordFolder = ReplicatedStorage.Swords
local DEFAULT_SWORD_NAME = "DefaultSword"
local DUMMY_ATTACHMENT_PATH = workspace:WaitForChild("Dummy"):WaitForChild("Torso"):WaitForChild("SwordAttachment")
local DUMMY_ATTACHMENT_PATH2 = workspace:WaitForChild("Dummy"):WaitForChild("Right Arm"):WaitForChild("SwordSwing")

local swingEvent = ReplicatedStorage:FindFirstChild("SwingEvent")
if not swingEvent then
	swingEvent = Instance.new("RemoteEvent")
	swingEvent.Name = "SwingEvent"
	swingEvent.Parent = ReplicatedStorage
end

local ballHitEvent = ReplicatedStorage:FindFirstChild("BallHitEvent")
if not ballHitEvent then
	ballHitEvent = Instance.new("RemoteEvent")
	ballHitEvent.Name = "BallHitEvent"
	ballHitEvent.Parent = ReplicatedStorage
end

local playerCooldowns = {}
local activeParries = {}

local function cloneTorsoAttachment(torso)
	if torso:FindFirstChild("SwordAttachment") then return end
	local cloned = DUMMY_ATTACHMENT_PATH:Clone()
	cloned.Parent = torso
end

local function cloneRightArmAttachment(rightArm)
	if rightArm:FindFirstChild("SwordSwing") then return end
	local cloned = DUMMY_ATTACHMENT_PATH2:Clone()
	cloned.Parent = rightArm
end

local function attachSwordToHip(character, swordModel)
	local torso = character:FindFirstChild("Torso")
	local rightArm = character:FindFirstChild("Right Arm")
	if not torso or not rightArm then return end

	cloneTorsoAttachment(torso)
	cloneRightArmAttachment(rightArm)

	local swordClone = swordModel:Clone()
	swordClone.Name = "HipSword"
	swordClone.Parent = character

	local handle = swordClone:FindFirstChild("Handle")
	if not handle then return end

	local swordAttachment = handle:FindFirstChild("SwordAttachment")
	local torsoAttachment = torso:FindFirstChild("SwordAttachment")

	if swordAttachment and torsoAttachment then
		local weld = Instance.new("Weld")
		weld.Part0 = torso
		weld.Part1 = handle
		weld.C0 = torsoAttachment.CFrame
		weld.C1 = swordAttachment.CFrame
		weld.Parent = torso
	end
end

local function checkBallProximity(player, character, parryActive, animator, parryAnim, failTrack, swordWeld, torso, rightArm, swingAttachment, torsoAttachment, swordAttachment)
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not parryActive.active then
			connection:Disconnect()
			return
		end

		local ball = workspace:FindFirstChild("Ball")
		if not ball then return end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local distance = (hrp.Position - ball.Position).Magnitude
		if distance <= PARRY_RANGE and not parryActive.hitBall then
			parryActive.hitBall = true
			print("Ball hit! Switching to parry animation")

			failTrack:Stop()

			swordWeld.Part0 = rightArm
			swordWeld.C0 = swingAttachment.CFrame
			swordWeld.C1 = swordAttachment.CFrame * CFrame.Angles(0, 0, math.rad(90))

			local parryTrack = animator:LoadAnimation(parryAnim)
			parryTrack:Play()

			ballHitEvent:FireClient(player)

			parryTrack.Stopped:Connect(function()
				swordWeld.Part0 = torso
				swordWeld.C0 = torsoAttachment.CFrame
				swordWeld.C1 = swordAttachment.CFrame
			end)
		end
	end)
end

local function onSwing(player)
	local character = player.Character
	if not character then return end

	if playerCooldowns[player.UserId] then return end

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

	local parryAnim = handle:FindFirstChild("Parry")
	local parryFailAnim = handle:FindFirstChild("ParryFail")

	if not parryAnim or not parryFailAnim then
		warn("Animations not found for player: " .. player.Name)
		return
	end

	playerCooldowns[player.UserId] = true

	local torso = character:FindFirstChild("Torso")
	local rightArm = character:FindFirstChild("Right Arm")

	if not torso or not rightArm then
		playerCooldowns[player.UserId] = nil
		return
	end

	local torsoAttachment = torso:FindFirstChild("SwordAttachment")
	local swingAttachment = rightArm:FindFirstChild("SwordSwing")
	local swordAttachment = handle:FindFirstChild("SwordAttachment")

	if not torsoAttachment or not swingAttachment or not swordAttachment then
		playerCooldowns[player.UserId] = nil
		return
	end

	local swordWeld = nil
	for _, obj in pairs(torso:GetChildren()) do
		if obj:IsA("Weld") and obj.Part1 == handle then
			swordWeld = obj
			break
		end
	end

	if not swordWeld then
		playerCooldowns[player.UserId] = nil
		return
	end

	local failTrack = animator:LoadAnimation(parryFailAnim)
	failTrack:Play()
	print("ParryFail animation started for: " .. player.Name)

	local parryActive = {
		active = true,
		hitBall = false
	}

	activeParries[player.UserId] = parryActive
	checkBallProximity(player, character, parryActive, animator, parryAnim, failTrack, swordWeld, torso, rightArm, swingAttachment, torsoAttachment, swordAttachment)

	failTrack.Stopped:Connect(function()
		parryActive.active = false

		if parryActive.hitBall then
			print("Successfully hit ball!")
		else
			print("Missed - ball never came within range")
		end

		playerCooldowns[player.UserId] = nil
		activeParries[player.UserId] = nil
	end)

	task.delay(5, function()
		if parryActive.active then
			parryActive.active = false
			playerCooldowns[player.UserId] = nil
			activeParries[player.UserId] = nil
			print("Parry timeout for: " .. player.Name)
		end
	end)
end

swingEvent.OnServerEvent:Connect(onSwing)

local function onCharacterAdded(character)
	local swordModel = swordFolder:FindFirstChild(DEFAULT_SWORD_NAME)
	if swordModel then
		task.wait(0.5)
		attachSwordToHip(character, swordModel)
	end
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
