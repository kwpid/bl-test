local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.BallConfig)

local dashEvent = ReplicatedStorage:WaitForChild("DashEvent")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local lastDashTime = 0

local function canDash()
	return tick() - lastDashTime >= Config.Dash.COOLDOWN
end

local function isFacingBall()
	local ball = workspace:FindFirstChild("Ball")
	if not ball then return false, nil end
	
	local character = player.Character
	if not character then return false, nil end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false, nil end
	
	local toBall = (ball.Position - hrp.Position)
	local distance = toBall.Magnitude
	
	-- Check if ball is within reasonable distance
	if distance > Config.Dash.BALL_FACING_MAX_DISTANCE then
		return false, nil
	end
	
	-- Calculate angle between camera look direction and direction to ball
	local lookDirection = camera.CFrame.LookVector
	local toBallDirection = toBall.Unit
	
	local dotProduct = lookDirection:Dot(toBallDirection)
	local angle = math.deg(math.acos(math.clamp(dotProduct, -1, 1)))
	
	-- Check if angle is within threshold
	if angle <= Config.Dash.BALL_FACING_ANGLE then
		return true, ball.Position
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
	
	-- Check if player is facing the ball
	local facingBall, ballPosition = isFacingBall()
	
	local dashData = {
		direction = camera.CFrame.LookVector,
		dashType = facingBall and 2 or 1,
		ballPosition = ballPosition
	}
	
	dashEvent:FireServer(dashData)
	lastDashTime = tick()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Config.Dash.KEYBIND then
		performDash()
	end
end)
