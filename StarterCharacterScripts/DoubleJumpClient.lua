local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local DOUBLE_JUMP_POWER = 50
local canDoubleJump = false
local hasDoubleJumped = false

local function playDoubleJumpAnimation()
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	
	local doubleJumpAnim = ReplicatedStorage:FindFirstChild("DoubleJumpAnimation")
	if doubleJumpAnim then
		local animTrack = animator:LoadAnimation(doubleJumpAnim)
		animTrack:Play()
	end
end

local function onJumpRequest()
	if humanoid:GetState() == Enum.HumanoidStateType.Freefall or 
	   humanoid:GetState() == Enum.HumanoidStateType.Flying then
		
		if canDoubleJump and not hasDoubleJumped then
			hasDoubleJumped = true
			canDoubleJump = false
			
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local currentVelocity = hrp.AssemblyLinearVelocity
				hrp.AssemblyLinearVelocity = Vector3.new(
					currentVelocity.X,
					DOUBLE_JUMP_POWER,
					currentVelocity.Z
				)
			end
			
			playDoubleJumpAnimation()
		end
	end
end

humanoid.StateChanged:Connect(function(oldState, newState)
	if newState == Enum.HumanoidStateType.Landed then
		canDoubleJump = false
		hasDoubleJumped = false
	elseif newState == Enum.HumanoidStateType.Freefall then
		if oldState == Enum.HumanoidStateType.Jumping then
			canDoubleJump = true
		end
	end
end)

UserInputService.JumpRequest:Connect(onJumpRequest)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	canDoubleJump = false
	hasDoubleJumped = false
	
	humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Landed then
			canDoubleJump = false
			hasDoubleJumped = false
		elseif newState == Enum.HumanoidStateType.Freefall then
			if oldState == Enum.HumanoidStateType.Jumping then
				canDoubleJump = true
			end
		end
	end)
end)

print("Double jump initialized - Power:", DOUBLE_JUMP_POWER)
