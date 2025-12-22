local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local BallPhysics = require(ReplicatedStorage.BallPhysics)
local Config = require(ReplicatedStorage.BallConfig)

local RemoteEventsFolder = ReplicatedStorage:WaitForChild(Config.Paths.REMOTE_EVENTS_FOLDER)
local ballUpdateEvent = RemoteEventsFolder:WaitForChild("BallUpdateEvent")
local player = Players.LocalPlayer
local ball = workspace:FindFirstChild("Ball")
if not ball then
	-- Wait for the ball to be spawned by the server
	ball = workspace:WaitForChild("Ball", 30)
end

if not ball then
	error("Ball not found in Workspace after waiting! Ensure BallServer.lua is correctly spawning it.")
end



-- Clean up old local ball if it exists
for _, child in ipairs(workspace:GetChildren()) do
	if child.Name == "ClientBall" and child:IsA("BasePart") then
		child:Destroy()
	end
end

local clientBall = ball:Clone()
clientBall.Name = "ClientBall"
clientBall.Transparency = 0
clientBall.CanCollide = false
clientBall.Anchored = true -- Script handles movement
clientBall.Parent = workspace

ball.Transparency = 1
ball.Anchored = true -- Ensure server ball is also anchored

local debugFolder = workspace:FindFirstChild("BallDebug")
if not debugFolder then
	debugFolder = Instance.new("Folder")
	debugFolder.Name = "BallDebug"
	debugFolder.Parent = workspace
end

local TextChatService = game:GetService("TextChatService")

local clientState = BallPhysics.new(clientBall.Position)
local serverStateBuffer = {}
local lastServerUpdate = tick()



local debugEnabled = false
local debugHitboxEnabled = false
local balLCamEnabled = false
local originalCameraSubject = nil


local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function updateRaycastFilter()
	local filterList = { ball, clientBall }

	if debugFolder then
		table.insert(filterList, debugFolder)
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(filterList, p.Character)
		end
	end

	raycastParams.FilterDescendantsInstances = filterList
end

local function onPlayerAdded(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.1)
		updateRaycastFilter()
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

updateRaycastFilter()

local function getHitRange()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return Config.Parry.MOBILE_RANGE
	elseif UserInputService.GamepadEnabled then
		return Config.Parry.CONSOLE_RANGE
	else
		return Config.Parry.RANGE
	end
end

-- chat command 4 debugs
TextChatService.SendingMessage:Connect(function(message)
	local isDev = false
	if Config.Debug and Config.Debug.DeveloperIds then
		for _, id in ipairs(Config.Debug.DeveloperIds) do
			if player.UserId == id then
				isDev = true
				break
			end
		end
	end

		if isDev then
		if message.Text == "/debug" then
			debugEnabled = not debugEnabled
		elseif message.Text == "/debug:reset" then
			local debugResetEvent = RemoteEventsFolder:WaitForChild("DebugReset", 5)
			if debugResetEvent then
				debugResetEvent:FireServer()
			else
				warn("DebugReset event not found")
			end
		elseif message.Text == "/debug:hitbox" then
			debugHitboxEnabled = not debugHitboxEnabled
		elseif message.Text == "/debug:freeze" then
			local debugFreezeEvent = RemoteEventsFolder:WaitForChild("DebugFreeze", 5)
			if debugFreezeEvent then
				debugFreezeEvent:FireServer()
			else
				warn("DebugFreeze event not found")
			end
		elseif message.Text == "/debug:unfreeze" then
			local debugUnfreezeEvent = RemoteEventsFolder:WaitForChild("DebugUnfreeze", 5)
			if debugUnfreezeEvent then
				debugUnfreezeEvent:FireServer()
			else
				warn("DebugUnfreeze event not found")
			end
		elseif message.Text == "/ballcam" then
			ballCamEnabled = not ballCamEnabled
			local camera = workspace.CurrentCamera

			if ballCamEnabled then
				originalCameraSubject = camera.CameraSubject
				camera.CameraSubject = clientBall
				camera.CameraType = Enum.CameraType.Follow
			else
				if originalCameraSubject then
					camera.CameraSubject = originalCameraSubject
				end
				camera.CameraType = Enum.CameraType.Custom
			end
		end
	end
end)

local function interpolateColor(percent)
	return Color3.new(1, 1, 1):Lerp(Color3.new(0.7, 0.6, 1), percent)
end

ballUpdateEvent.OnClientEvent:Connect(function(serverState)
	table.insert(serverStateBuffer, {
		state = serverState,
		timestamp = tick(),
	})

	if #serverStateBuffer > 10 then
		table.remove(serverStateBuffer, 1)
	end

	lastServerUpdate = tick()
end)

local function checkCollision(from, to)
	local direction = (to - from)
	local distance = direction.Magnitude
	if distance == 0 then
		return nil
	end

	local rayResult = workspace:Raycast(from, direction.Unit * (distance + clientBall.Size.X / 2), raycastParams)
	return rayResult
end

local function getGroundHeight(position)
	local rayOrigin = Vector3.new(position.X, position.Y + 10, position.Z)
	local rayDirection = Vector3.new(0, -200, 0)
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	return rayResult and rayResult.Position.Y or 0
end

RunService.Heartbeat:Connect(function(dt)
	if #serverStateBuffer > 0 then
		local serverState = serverStateBuffer[#serverStateBuffer].state

		local positionDiff = (serverState.position - clientState.position).Magnitude
		if positionDiff > 8 then
			clientState:deserialize(serverState)
		else
			local velocityDiff = (serverState.velocity - clientState.velocity).Magnitude
			local isHit = velocityDiff > 20

			if isHit then
				clientState.velocity = serverState.velocity
				local alpha = math.clamp(dt * 20, 0, 0.6)
				clientState.position = clientState.position:Lerp(serverState.position, alpha)
			else
				local alpha = math.clamp(dt * 12, 0, 0.5)

				clientState.position = clientState.position:Lerp(serverState.position, alpha)
				clientState.velocity = clientState.velocity:Lerp(serverState.velocity, alpha * 0.8)
			end

			clientState.isMoving = serverState.isMoving
			clientState.hitCount = serverState.hitCount
			clientState.lastHitter = serverState.lastHitter
			if serverState.color and serverState.color ~= clientState.color then
				print("COLOR SYNC: Server=" .. tostring(serverState.color) .. " Client=" .. tostring(clientState.color))
				clientState.color = serverState.color
			end
			if serverState.transparency ~= nil and serverState.transparency ~= clientState.transparency then
				print("TRANSPARENCY SYNC: Server=" .. tostring(serverState.transparency) .. " Client=" .. tostring(clientState.transparency))
				clientState.transparency = serverState.transparency
			end
		end
	end

	if tick() - lastServerUpdate < 1.0 then
		local groundHeight = getGroundHeight(clientState.position)
		clientState:update(dt, checkCollision, groundHeight, clientBall.Size.X / 2)

		clientState:enforceFloatHeight(groundHeight)
	end
	clientBall.Position = clientState.position
	clientBall.Color = clientState.color
	clientBall.Transparency = clientState.transparency or 0
	
	-- Update LastTeam attribute on client ball
	if clientState.lastHitter and clientState.lastHitter ~= "None" then
		local lastHitterPlayer = Players:FindFirstChild(clientState.lastHitter)
		if lastHitterPlayer then
			local team = lastHitterPlayer:GetAttribute("Team")
			if team then
				clientBall:SetAttribute("LastTeam", team)
			end
		end
	end

	if ballCamEnabled then
		local camera = workspace.CurrentCamera
		if camera.CameraSubject ~= clientBall then
			camera.CameraSubject = clientBall
			camera.CameraType = Enum.CameraType.Follow
		end
	end

	local speedPercent = clientState:getSpeedPercent()

	-- Debug Visualization
	local debugGui = clientBall:FindFirstChild("DebugGui")
	if not debugGui then
		debugGui = Instance.new("BillboardGui")
		debugGui.Name = "DebugGui"
		debugGui.Size = UDim2.new(0, 400, 0, 150)
		debugGui.StudsOffset = Vector3.new(0, 4, 0)
		debugGui.AlwaysOnTop = true
		debugGui.Parent = clientBall

		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "TextLabel"
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.TextColor3 = Color3.new(1, 1, 1)
		textLabel.TextStrokeTransparency = 0
		textLabel.Font = Enum.Font.Code
		textLabel.TextSize = 18
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextYAlignment = Enum.TextYAlignment.Top
		textLabel.Parent = debugGui
	end

	local groundHeight = getGroundHeight(clientState.position)
	local heightOffFloat = clientState.position.Y - (groundHeight + Config.Physics.FLOAT_HEIGHT)
	local maxSpeed
	if clientState.hitCount == 0 then
		maxSpeed = Config.Physics.BASE_SPEED
	else
		maxSpeed = Config.Physics.START_SPEED + (clientState.hitCount - 1) * Config.Physics.SPEED_INCREMENT
	end

	maxSpeed = math.min(maxSpeed, Config.Physics.MAX_SPEED)
	local verticalSpeed = clientState.velocity.Y

	local debugText = string.format(
		"VELOCITY          POSITION\n"
			.. "Speed: %.1f       Height: %.1f\n"
			.. "Vert:  %.1f       \n\n"
			.. "STATS             INFO\n"
			.. "Hits:  %d         Last: %s\n"
			.. "Max:   %.1f",
		clientState.velocity.Magnitude,
		heightOffFloat,
		verticalSpeed,
		clientState.hitCount,
		clientState.lastHitter or "None",
		maxSpeed
	)

	if clientState.isFrozen and debugEnabled then
		debugText = "FROZEN\n\n" .. debugText
	end

	debugGui.TextLabel.Text = debugText
	debugGui.Enabled = debugEnabled

	local hitboxPart = workspace:FindFirstChild("DebugHitbox_" .. player.UserId)
	if debugHitboxEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		if not hitboxPart then
			hitboxPart = Instance.new("Part")
			hitboxPart.Name = "DebugHitbox_" .. player.UserId
			hitboxPart.Shape = Enum.PartType.Ball
			hitboxPart.Anchored = true
			hitboxPart.CanCollide = false
			hitboxPart.CanQuery = false
			hitboxPart.CanTouch = false
			hitboxPart.Transparency = 0.85
			hitboxPart.Material = Enum.Material.Neon
			hitboxPart.Color = Color3.new(1, 0, 0)
			hitboxPart.Size = Vector3.new(1, 1, 1)
			hitboxPart.Parent = workspace
		end

		local hitRange = getHitRange()
		hitboxPart.Size = Vector3.new(hitRange * 2, hitRange * 2, hitRange * 2)
		hitboxPart.CFrame = player.Character.HumanoidRootPart.CFrame
	elseif hitboxPart then
		hitboxPart:Destroy()
	end	


	local debugParts = debugFolder:GetChildren()
	local partIndex = 1

	if debugEnabled then
		local function getDebugPart()
			local part = debugParts[partIndex]
			if not part then
				part = Instance.new("Part")
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false 
				part.CanTouch = false 
				part.Material = Enum.Material.Neon
				part.Color = Color3.new(1, 0, 0) 
				part.Size = Vector3.new(0.2, 0.2, 0.2)
				part.Parent = debugFolder
			end
			partIndex = partIndex + 1
			return part
		end

		-- 1. float point line (blue)
		local groundHeight = getGroundHeight(clientState.position)
		local floatPoint = Vector3.new(clientState.position.X, groundHeight, clientState.position.Z)
		local distToFloat = (clientState.position - floatPoint).Magnitude

		if distToFloat > 0.1 then
			local part = getDebugPart()
			part.Color = Color3.new(0, 0, 1) 
			part.Size = Vector3.new(0.05, 0.05, distToFloat)
			part.CFrame = CFrame.lookAt(clientState.position, floatPoint) * CFrame.new(0, 0, -distToFloat / 2)
			part.Transparency = 0.5
		end

		-- 2. velocity vector (green)
		if clientState.velocity.Magnitude > 0.1 then
			local part = getDebugPart()
			part.Color = Color3.new(0, 1, 0) 
			local len = math.min(clientState.velocity.Magnitude / 10, 10) 
			part.Size = Vector3.new(0.1, 0.1, len)
			part.CFrame = CFrame.lookAt(clientState.position, clientState.position + clientState.velocity)
				* CFrame.new(0, 0, -len / 2)
			part.Transparency = 0
		end

		-- 3. ball predict path (Red)
		if clientState.isMoving then
			local ghostState = BallPhysics.new(clientState.position)
			ghostState:deserialize(clientState:serialize())

			-- ball predict config
			local collisionCount = 0
			local maxCollisions = 10 
			local simDt = 1 / 60
			local maxSteps = 1200 

			local points = { ghostState.position }

			for i = 1, maxSteps do
				if collisionCount >= maxCollisions then
					break
				end

				local collided = false
				ghostState:update(
					simDt,
					checkCollision,
					getGroundHeight(ghostState.position),
					clientBall.Size.X / 2,
					function()
						collided = true
						collisionCount = collisionCount + 1
					end
				)

				if i % 2 == 0 then
					table.insert(points, ghostState.position)
				end

				if not ghostState.isMoving then
					break
				end
			end

			-- draw lines between points
			for i = 1, #points - 1 do
				local p1 = points[i]
				local p2 = points[i + 1]
				local dist = (p2 - p1).Magnitude
				if dist > 0.1 then
					local part = getDebugPart()
					part.Color = Color3.new(1, 0, 0)
					part.Size = Vector3.new(0.1, 0.1, dist)
					part.CFrame = CFrame.lookAt(p1, p2) * CFrame.new(0, 0, -dist / 2)
					part.Transparency = 0
				end
			end
		end
	end

	-- hide unused parts
	for i = partIndex, #debugParts do
		debugParts[i].Transparency = 1
		debugParts[i].CFrame = CFrame.new(0, -1000, 0)
	end
end)
