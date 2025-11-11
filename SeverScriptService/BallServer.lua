local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local BallPhysics = require(ReplicatedStorage.BallPhysics)
local Config = require(ReplicatedStorage.BallConfig)

local RemoteEvents = {
	ballHit = ReplicatedStorage:FindFirstChild("BallHitEvent") or Instance.new("RemoteEvent"),
	ballUpdate = ReplicatedStorage:FindFirstChild("BallUpdateEvent") or Instance.new("RemoteEvent"),
}
RemoteEvents.ballHit.Name = "BallHitEvent"
RemoteEvents.ballUpdate.Name = "BallUpdateEvent"
RemoteEvents.ballHit.Parent = ReplicatedStorage
RemoteEvents.ballUpdate.Parent = ReplicatedStorage

local ball = workspace:WaitForChild("Ball")
ball.Anchored = true
ball.CanCollide = false
ball.Shape = Enum.PartType.Ball

local ballState = BallPhysics.new(ball.Position)
local ignoredParts = {}
local lastGroundCheck = 0
local lastNetworkUpdate = 0

local function updateIgnoredParts()
	ignoredParts = {}
	
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			for _, part in pairs(player.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					table.insert(ignoredParts, part)
				end
			end
			
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
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		updateIgnoredParts()
	end)
end)

updateIgnoredParts()

local function createRaycastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {ball}
	
	for _, part in pairs(ignoredParts) do
		if part and part:IsDescendantOf(workspace) then
			table.insert(params.FilterDescendantsInstances, part)
		end
	end
	
	return params
end

local function getGroundHeight(position)
	local rayOrigin = Vector3.new(position.X, position.Y + 10, position.Z)
	local rayDirection = Vector3.new(0, -200, 0)
	local params = createRaycastParams()
	
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, params)
	return rayResult and rayResult.Position.Y or 0
end

local function checkCollision(from, to)
	local direction = (to - from)
	local distance = direction.Magnitude
	
	if distance == 0 then return nil end
	
	local params = createRaycastParams()
	local rayResult = workspace:Raycast(from, direction.Unit * (distance + ball.Size.X/2), params)
	
	return rayResult
end

RunService.Heartbeat:Connect(function(dt)
	local updated = ballState:update(dt, checkCollision)
	
	lastGroundCheck = lastGroundCheck + dt
	if lastGroundCheck > 0.1 then
		local groundHeight = getGroundHeight(ballState.position)
		ballState:enforceFloatHeight(groundHeight)
		lastGroundCheck = 0
	end
	
	ball.Position = ballState.position
	
	lastNetworkUpdate = lastNetworkUpdate + dt
	if lastNetworkUpdate >= 1/Config.Network.UPDATE_RATE then
		if updated or ballState.isMoving then
			RemoteEvents.ballUpdate:FireAllClients(ballState:serialize())
		end
		lastNetworkUpdate = 0
	end
end)

RemoteEvents.ballHit.OnServerEvent:Connect(function(player, cameraDirection)
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local distance = (hrp.Position - ballState.position).Magnitude
	if distance > Config.Parry.RANGE then 
		return 
	end
	
	local speed = ballState:applyHit(cameraDirection)
	
	RemoteEvents.ballUpdate:FireAllClients(ballState:serialize())
	
	print(string.format("Ball hit by %s | Hit #%d | Speed: %.1f", 
		player.Name, ballState.hitCount, speed))
end)

print("Ball server initialized")
