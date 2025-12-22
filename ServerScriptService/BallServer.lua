local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local BallPhysics = require(ReplicatedStorage.BallPhysics)
local Config = require(ReplicatedStorage.BallConfig)

local RemoteEventsFolder = ReplicatedStorage:WaitForChild(Config.Paths.REMOTE_EVENTS_FOLDER)

local RemoteEvents = {
	ballUpdate = RemoteEventsFolder:WaitForChild("BallUpdateEvent"),
}

local ServerEvents = {}
ServerEvents.ballHit = RemoteEventsFolder:FindFirstChild("ServerBallHit")
if not ServerEvents.ballHit then
	ServerEvents.ballHit = Instance.new("BindableEvent")
	ServerEvents.ballHit.Name = "ServerBallHit"
	ServerEvents.ballHit.Parent = RemoteEventsFolder
end

local ResetBallEvent = RemoteEventsFolder:FindFirstChild("ResetBall")
if not ResetBallEvent then
	ResetBallEvent = Instance.new("BindableEvent")
	ResetBallEvent.Name = "ResetBall"
	ResetBallEvent.Parent = RemoteEventsFolder
end

local GoalScoredEvent = RemoteEventsFolder:FindFirstChild("GoalScored")
if not GoalScoredEvent then
	GoalScoredEvent = Instance.new("BindableEvent")
	GoalScoredEvent.Name = "GoalScored"
	GoalScoredEvent.Parent = RemoteEventsFolder
end

local ballTemplate = ReplicatedStorage:WaitForChild("Ball")
local ball = workspace:FindFirstChild("Ball")
if not ball then
	ball = ballTemplate:Clone()
	ball.Name = "Ball"
	ball.Parent = workspace
end

ball.Anchored = true
ball.CanCollide = false
ball:SetAttribute("LastTeam", "None")
ball.Shape = Enum.PartType.Ball
ball.Transparency = 1 -- Hide until game starts

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = { ball }

local function getGroundHeightInitial(position)
	local rayOrigin = Vector3.new(position.X, position.Y + 10, position.Z)
	local rayDirection = Vector3.new(0, -200, 0)
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	return rayResult and rayResult.Position.Y or 0
end

local initialGroundHeight = getGroundHeightInitial(ball.Position)
local spawnPosition = Vector3.new(ball.Position.X, initialGroundHeight + Config.Physics.FLOAT_HEIGHT, ball.Position.Z)

local ballState = BallPhysics.new(spawnPosition)
ballState.color = ball.Color
ball.Position = spawnPosition

local lastGroundCheck = 0
local lastNetworkUpdate = 0
local ballFrozen = false
local frozenVelocity = Vector3.new(0, 0, 0)

local function updateRaycastFilter()
	local filterList = { ball }

	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			for _, part in pairs(player.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					table.insert(filterList, part)
				end
			end
		end
	end

	-- Exclude Goal Detectors from physics so ball can pass through them
	local map = workspace:FindFirstChild("1v1_Map", true)
	if map then
		local redGoal = map:FindFirstChild("GoalDetectorRed")
		local blueGoal = map:FindFirstChild("GoalDetectorBlue")
		if redGoal then table.insert(filterList, redGoal) end
		if blueGoal then table.insert(filterList, blueGoal) end
	end

	raycastParams.FilterDescendantsInstances = filterList
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		updateRaycastFilter()
	end)
end)

updateRaycastFilter()

local function getGroundHeight(position)
	local rayOrigin = Vector3.new(position.X, position.Y + 10, position.Z)
	local rayDirection = Vector3.new(0, -200, 0)
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	return rayResult and rayResult.Position.Y or 0
end

local function checkCollision(from, to)
	local direction = (to - from)
	local distance = direction.Magnitude
	if distance == 0 then
		return nil
	end

	local rayResult = workspace:Raycast(from, direction.Unit * (distance + ball.Size.X / 2), raycastParams)
	return rayResult
end

local currentGroundHeight = 0

RunService.Heartbeat:Connect(function(dt)
	local updated = false
	if not ballFrozen then
		lastGroundCheck = lastGroundCheck + dt
		if lastGroundCheck > 0.1 then
			currentGroundHeight = getGroundHeight(ballState.position)
			lastGroundCheck = 0
		end

		updated = ballState:update(dt, checkCollision, currentGroundHeight, ball.Size.X / 2)
		ballState:enforceFloatHeight(currentGroundHeight)
	end

	ball.Position = ballState.position
	ball.Color = ballState.color
	ball.Transparency = ballState.transparency or 0

	-- Goal Detection
	if not ballFrozen and ballState.isMoving then
		local map = workspace:FindFirstChild("1v1_Map", true) -- Search descendants
		if map then
			local redGoal = map:FindFirstChild("GoalDetectorRed")
			local blueGoal = map:FindFirstChild("GoalDetectorBlue")
			
			if not redGoal or not blueGoal then
				warn("Goal detectors not found in map! Red:", redGoal ~= nil, "Blue:", blueGoal ~= nil)
			end
			
			local function isPointInPart(point, part, radius)
				radius = radius or 0
				local relativePos = part.CFrame:PointToObjectSpace(point)
				return math.abs(relativePos.X) <= (part.Size.X/2 + radius)
					and math.abs(relativePos.Y) <= (part.Size.Y/2 + radius)
					and math.abs(relativePos.Z) <= (part.Size.Z/2 + radius)
			end

			if redGoal then
				local dist = (ball.Position - redGoal.Position).Magnitude
				local isInside = isPointInPart(ball.Position, redGoal, ball.Size.X / 2)
				
				if isInside or dist <= 6 then -- Lenient distance check (6 studs)
					print("GOAL DETECTION: BALL IN RED GOAL! dist:", dist, "inside:", isInside)
					ballFrozen = true
					ball.Transparency = 1
					ballState.transparency = 1 -- Sync to client
					ball.Anchored = true
					
					-- Fire one final update to ensure transparency is synced
					RemoteEvents.ballUpdate:FireAllClients(ballState:serialize())
					
					GoalScoredEvent:Fire("blue") -- Red goal = Blue scores
				elseif dist < 25 then
					-- Still log for debugging
					if tick() % 0.5 < 0.05 then
						print(string.format("DEBUG: Ball near RED goal: Dist=%.2f, BallPos=%s", dist, tostring(ball.Position)))
					end
				end
			end
			
			if blueGoal then
				local dist = (ball.Position - blueGoal.Position).Magnitude
				local isInside = isPointInPart(ball.Position, blueGoal, ball.Size.X / 2)
				
				if isInside or dist <= 6 then -- Lenient distance check (6 studs)
					print("GOAL DETECTION: BALL IN BLUE GOAL! dist:", dist, "inside:", isInside)
					ballFrozen = true
					ball.Transparency = 1
					ballState.transparency = 1 -- Sync to client
					ball.Anchored = true
					
					-- Fire one final update to ensure transparency is synced
					RemoteEvents.ballUpdate:FireAllClients(ballState:serialize())
					
					GoalScoredEvent:Fire("red") -- Blue goal = Red scores
				elseif dist < 25 then
					-- Still log for debugging
					if tick() % 0.5 < 0.05 then
						print(string.format("DEBUG: Ball near BLUE goal: Dist=%.2f, BallPos=%s", dist, tostring(ball.Position)))
					end
				end
			end
		else
			if tick() % 10 < 0.1 then -- Log occasionally
				warn("1v1_Map not found in workspace for goal detection.")
			end
		end
	end

	lastNetworkUpdate = lastNetworkUpdate + dt
	if lastNetworkUpdate >= 1 / Config.Network.UPDATE_RATE then
		-- Always send update if moving, or if updated, or if recently hit/goal
		if updated or ballState.isMoving or ballFrozen then
			RemoteEvents.ballUpdate:FireAllClients(ballState:serialize())
		end
		lastNetworkUpdate = 0
	end
end)

local lastHitTime = 0

ServerEvents.ballHit.Event:Connect(function(player, cameraDirection)
	print("BallServer: Received ballHit from player:", player.Name)
	local currentTime = tick()
	if currentTime - lastHitTime < Config.Parry.MIN_HIT_INTERVAL then
		return
	end

	if not cameraDirection or typeof(cameraDirection) ~= "Vector3" then
		return
	end

	if cameraDirection.Magnitude < 0.001 then
		warn("Invalid camera direction from player: " .. player.Name)
		return
	end

	lastHitTime = currentTime

	ballState:applyHit(cameraDirection, nil, player.Name)

	-- Update ball color based on team
	local team = player:GetAttribute("Team")
	print("Ball hit by player:", player.Name, "Team:", team)
	if team == "red" then
		ballState.color = Color3.fromRGB(255, 0, 0)
	elseif team == "blue" then
		ballState.color = Color3.fromRGB(0, 0, 255)
	end
	ball.Color = ballState.color
	ball:SetAttribute("LastTeam", team)
	ballState.lastHitter = player.Name

	local serialized = ballState:serialize()

	RemoteEvents.ballUpdate:FireAllClients(serialized)
end)

local function resetBall(position)
	ballState = BallPhysics.new(position)
	ballState.transparency = 0 -- Initialize transparency
	ballState.color = Color3.new(1, 1, 1) -- Reset to white
	ball.Position = position
	ball.Color = ballState.color
	ball.Transparency = 0.8 -- Semi-visible on server for debugging
	ballState.transparency = 0
	ballState.lastHitter = "None"
	ball:SetAttribute("LastTeam", "None")
	ball.CanCollide = false
	ball.Anchored = true -- Script handles movement, must be anchored
	ballFrozen = false -- Unfreeze on reset
	
	-- Fire update to sync reset state
	RemoteEvents.ballUpdate:FireAllClients(ballState:serialize())
end

ResetBallEvent.Event:Connect(resetBall)

-- reset ball (debug)
local debugResetEvent = RemoteEventsFolder:FindFirstChild("DebugReset")

debugResetEvent.OnServerEvent:Connect(function(player)
	local isDev = false

	for _, id in ipairs(Config.Debug.DeveloperIds) do
		if player.UserId == id then
			isDev = true
			break
		end
	end

	if isDev then
		resetBall(spawnPosition)
	end
end)

-- freeze ball (debug)
local debugFreezeEvent = RemoteEventsFolder:FindFirstChild("DebugFreeze")


debugFreezeEvent.OnServerEvent:Connect(function(player)
	local isDev = false
	for _, id in ipairs(Config.Debug.DeveloperIds) do
		if player.UserId == id then
			isDev = true
			break
		end
	end

	if isDev then
		ballFrozen = true
		frozenVelocity = ballState.velocity
	end
end)

-- unfreeze ball (debug)
local debugUnfreezeEvent = RemoteEventsFolder:FindFirstChild("DebugUnfreeze")

debugUnfreezeEvent.OnServerEvent:Connect(function(player)
	local isDev = false
	for _, id in ipairs(Config.Debug.DeveloperIds) do
		if player.UserId == id then
			isDev = true
			break
		end
	end

	if isDev then
		ballFrozen = false
		ballState.velocity = frozenVelocity
	end
end)
