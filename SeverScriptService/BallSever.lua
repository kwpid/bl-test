local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ballHitEvent = ReplicatedStorage:FindFirstChild("BallHitEvent")
if not ballHitEvent then
	ballHitEvent = Instance.new("RemoteEvent")
	ballHitEvent.Name = "BallHitEvent"
	ballHitEvent.Parent = ReplicatedStorage
end

local ball = workspace:WaitForChild("Ball")
ball.Anchored = true -- We control all physics manually
ball.CanCollide = false -- We handle collisions manually
ball.Shape = Enum.PartType.Ball

-- Create trail
local trail = Instance.new("Trail")
trail.Parent = ball
trail.Lifetime = 0.5
trail.MinLength = 0.1
trail.FaceCamera = true
trail.WidthScale = NumberSequence.new(1, 0)
trail.Transparency = NumberSequence.new(0.3, 1)

-- Create attachments for trail
local attachment0 = Instance.new("Attachment")
attachment0.Parent = ball
attachment0.Position = Vector3.new(0, 0, 0)

local attachment1 = Instance.new("Attachment")
attachment1.Parent = ball
attachment1.Position = Vector3.new(0, 0, 0)

trail.Attachment0 = attachment0
trail.Attachment1 = attachment1

-- Physics constants
local FLOAT_HEIGHT = 2.5 -- Studs above ground
local BASE_SPEED = 20 -- Starting speed
local SPEED_INCREMENT = 15 -- Speed increase per hit
local MAX_SPEED = 150 -- Maximum speed cap
local DECELERATION = 0.994 -- How fast ball slows down (closer to 1 = slower deceleration)
local MIN_SPEED = 1 -- Speed at which ball stops

-- Ball state
local ballPosition = ball.Position
local ballVelocity = Vector3.new(0, 0, 0)
local isMoving = false
local hitCount = 0

local ignoredParts = {}

local function makePlayersNonCollidable()
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			for _, part in pairs(player.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					table.insert(ignoredParts, part)
				end
			end
		end
	end
end

local function ignoreSwords()
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			local sword = player.Character:FindFirstChild("HipSword")
			if sword then
				for _, part in pairs(sword:GetDescendants()) do
					if part:IsA("BasePart") then
						table.insert(ignoredParts, part)
					end
				end
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		task.wait(0.5)
		makePlayersNonCollidable()
		ignoreSwords()
	end)
end)

makePlayersNonCollidable()
task.wait(1)
ignoreSwords()

local function getGroundHeight(position)
	local rayOrigin = Vector3.new(position.X, position.Y + 10, position.Z)
	local rayDirection = Vector3.new(0, -200, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {ball}

	for _, part in pairs(ignoredParts) do
		if part and part:IsDescendantOf(workspace) then
			table.insert(raycastParams.FilterDescendantsInstances, part)
		end
	end

	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if rayResult then
		return rayResult.Position.Y
	else
		return 0
	end
end

local function checkCollision(from, to)
	local direction = (to - from)
	local distance = direction.Magnitude

	if distance == 0 then return nil end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {ball}

	for _, part in pairs(ignoredParts) do
		if part and part:IsDescendantOf(workspace) then
			table.insert(raycastParams.FilterDescendantsInstances, part)
		end
	end

	local rayResult = workspace:Raycast(from, direction.Unit * (distance + ball.Size.X/2), raycastParams)
	return rayResult
end

-- Main physics loop
local lastGroundCheck = 0
RunService.Heartbeat:Connect(function(dt)
	if isMoving then
		-- Apply deceleration
		ballVelocity = ballVelocity * DECELERATION

		-- Update trail color based on speed (white to blue)
		local currentSpeed = ballVelocity.Magnitude
		local speedPercent = math.clamp(currentSpeed / MAX_SPEED, 0, 1)

		-- Interpolate from white (1,1,1) to blue (0,0.5,1)
		local r = 1 - (speedPercent * 1) -- 1 to 0
		local g = 1 - (speedPercent * 0.5) -- 1 to 0.5
		local b = 1 -- stays 1

		trail.Color = ColorSequence.new(Color3.new(r, g, b))
		trail.Enabled = currentSpeed > 5 -- Only show trail when moving fast enough

		-- Check if ball should stop
		if currentSpeed < MIN_SPEED then
			ballVelocity = Vector3.new(0, 0, 0)
			isMoving = false
			trail.Enabled = false
			print("Ball stopped - too slow")
		else
			-- Calculate next position with smoother interpolation
			local moveDistance = ballVelocity * dt
			local steps = math.max(1, math.ceil(moveDistance.Magnitude / 0.5)) -- Check collisions in smaller steps for smoothness
			local stepVector = moveDistance / steps

			for i = 1, steps do
				local nextPosition = ballPosition + stepVector

				-- Check for collisions
				local collision = checkCollision(ballPosition, nextPosition)

				if collision then
					-- Bounce off surface
					local normal = collision.Normal
					local reflectedVelocity = ballVelocity - 2 * ballVelocity:Dot(normal) * normal
					ballVelocity = reflectedVelocity * 0.8 -- Lose some energy on bounce

					-- Move to collision point with small offset
					ballPosition = collision.Position + (normal * (ball.Size.X/2 + 0.1))

					print("Ball bounced! New velocity: " .. tostring(ballVelocity.Magnitude))
					break -- Stop checking this frame after bounce
				else
					-- No collision, move normally
					ballPosition = nextPosition
				end
			end
		end
	else
		trail.Enabled = false
	end

	-- Only check ground height periodically for performance, and only enforce minimum when not moving upward
	lastGroundCheck = lastGroundCheck + dt
	if lastGroundCheck > 0.1 then
		local groundHeight = getGroundHeight(ballPosition)
		local targetHeight = groundHeight + FLOAT_HEIGHT

		-- Only snap to minimum height if ball is below it AND not moving upward significantly
		if ballPosition.Y < targetHeight and (not isMoving or ballVelocity.Y < 1) then
			ballPosition = Vector3.new(ballPosition.X, targetHeight, ballPosition.Z)
			-- If ball was moving down and hit the floor, zero out downward velocity
			if isMoving and ballVelocity.Y < 0 then
				ballVelocity = Vector3.new(ballVelocity.X, 0, ballVelocity.Z)
			end
		end

		lastGroundCheck = 0
	end

	-- Update ball position smoothly
	ball.Position = ballPosition
end)

ballHitEvent.OnServerEvent:Connect(function(player, cameraDirection)
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local distance = (hrp.Position - ballPosition).Magnitude
	if distance > 5 then 
		print("Ball too far: " .. distance)
		return 
	end

	hitCount = hitCount + 1

	-- Calculate speed (starts slow, gets faster with each hit)
	local speed = BASE_SPEED + (hitCount - 1) * SPEED_INCREMENT
	speed = math.min(speed, MAX_SPEED) -- Cap at max speed

	print("Hit #" .. hitCount .. " - Speed: " .. speed)

	-- Set velocity in EXACT camera direction
	local direction = cameraDirection.Unit
	ballVelocity = direction * speed

	isMoving = true

	print("Ball hit by " .. player.Name .. " | Direction: " .. tostring(direction) .. " | Speed: " .. speed)
end)

print("Ball script loaded - Float height:", FLOAT_HEIGHT)
