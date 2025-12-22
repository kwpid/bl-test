local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- Ensure teams exist
local function setupTeams()
	if not Teams:FindFirstChild("Lobby") then
		local lobby = Instance.new("Team")
		lobby.Name = "Lobby"
		lobby.TeamColor = BrickColor.new("White")
		lobby.AutoAssignable = true
		lobby.Parent = Teams
	end
	if not Teams:FindFirstChild("In-Game") then
		local inGame = Instance.new("Team")
		inGame.Name = "In-Game"
		inGame.TeamColor = BrickColor.new("Bright red")
		inGame.AutoAssignable = false
		inGame.Parent = Teams
	end
end
setupTeams()

local ModulesFolder = ReplicatedStorage.Modules
local HttpService = game:GetService("HttpService")

local Configs = script.Parent.Config
local BallConfig = require(ReplicatedStorage:WaitForChild("BallConfig"))
local RemoteEventsFolder = ReplicatedStorage:WaitForChild(BallConfig.Paths.REMOTE_EVENTS_FOLDER)
local ResetBallEvent = RemoteEventsFolder:WaitForChild("ResetBall")
local GoalScoredEvent = RemoteEventsFolder:WaitForChild("GoalScored")

local redScore = 0
local blueScore = 0
local remainingTime = 120 -- 2 minutes
local clockRunning = false

local Zones = require(ModulesFolder.Zone)

local Plate1Container = script.Parent.Plate1.Zone

local Plate2Container = script.Parent.Plate2.Zone

local MainBoard = script.Parent.MainBoard

local Plate1Board = script.Parent.Plate1.Board

local Plate2Board = script.Parent.Plate2.Board

local T1 = script.Parent.T1

local T2 = script.Parent.T2

local BallSpawn = script.Parent:FindFirstChild("BallSpawn")

local Plate1HasPlayer = false

local Plate2HasPlayer = false

local countdownRunning = false

local InProgress = false

local timerRunning = true

local gameDuration = Configs.GameDuration.Value --In seconds, so if both players are alive, then it will end the game

local Zone1 = Zones.new(Plate1Container)

local Zone2 = Zones.new(Plate2Container)

local thumbType = Enum.ThumbnailType.HeadShot

local thumbSize = Enum.ThumbnailSize.Size420x420

local playersWaiting = {}

local teleportCFrames = {
	T1.CFrame,
	T2.CFrame,
}

local function Reset(excludedPlayer)
	for _, player in ipairs(playersWaiting) do
		if player.Name ~= (excludedPlayer and excludedPlayer.Name) then
			player:SetAttribute("Team", nil)
			player:SetAttribute("GameId", nil)
			player.Team = Teams:FindFirstChild("Lobby")
			player:LoadCharacter()
		end
	end

	if #playersWaiting ~= Configs.MaxPlayers.Value then
		print(("player '%s' won!"):format(playersWaiting[1].Name))
	end

	SetGameUIVisibility(false)
	playersWaiting = {}
	Plate1HasPlayer = false
	Plate2HasPlayer = false

	Plate1Board.SurfaceGui.Frame.PlayerIcon.Image = "rbxassetid://9319891706"
	Plate1Board.SurfaceGui.Frame.PlayerName.Text = "..."
	Plate2Board.SurfaceGui.Frame.PlayerIcon.Image = "rbxassetid://9319891706"
	Plate2Board.SurfaceGui.Frame.PlayerName.Text = "..."

	MainBoard.SurfaceGui.Frame.Status.Text = "Waiting..."
	timerRunning = true

	Plate1Board.Parent.Union.Color = Color3.new(1, 1, 1)
	Plate2Board.Parent.Union.Color = Color3.new(1, 1, 1)
	
	redScore = 0
	blueScore = 0
	remainingTime = 120
	clockRunning = false
	UpdateScoreUI()
	UpdateClockUI()
end

function SetGameUIVisibility(visible, gameId)
	for _, player in ipairs(playersWaiting) do
		local gui = player:FindFirstChild("PlayerGui")
		if gui then
			local gameGui = gui:FindFirstChild("GameGUI")
			if gameGui then
				local screen = gameGui:FindFirstChild("GameScreen")
				if screen then
					screen.Visible = visible
					if visible and gameId then
						screen:SetAttribute("GameId", gameId)
					else
						screen:SetAttribute("GameId", nil)
					end
				end
			end
		end
	end
end

function UpdateScoreUI()
	for _, player in ipairs(Players:GetPlayers()) do
		local gui = player:FindFirstChild("PlayerGui")
		if gui then
			local gameGui = gui:FindFirstChild("GameGUI")
			if gameGui then
				local redLabel = gameGui:FindFirstChild("GameScreen") and gameGui.GameScreen:FindFirstChild("Red") and gameGui.GameScreen.Red:FindFirstChild("RedScore")
				local blueLabel = gameGui:FindFirstChild("GameScreen") and gameGui.GameScreen:FindFirstChild("Blue") and gameGui.GameScreen.Blue:FindFirstChild("BlueScore")
				if redLabel then redLabel.Text = tostring(redScore) end
				if blueLabel then blueLabel.Text = tostring(blueScore) end
			end
		end
	end
end

function UpdateClockUI()
	local minutes = math.floor(remainingTime / 60)
	local seconds = remainingTime % 60
	local timeStr = string.format("%d:%02d", minutes, seconds)
	
	for _, player in ipairs(Players:GetPlayers()) do
		local gui = player:FindFirstChild("PlayerGui")
		if gui then
			local gameGui = gui:FindFirstChild("GameGUI")
			if gameGui then
				local clockLabel = gameGui:FindFirstChild("GameScreen") and gameGui.GameScreen:FindFirstChild("Clock") and gameGui.GameScreen.Clock:FindFirstChild("ClockText")
				if clockLabel then clockLabel.Text = timeStr end
			end
		end
	end
end

function SetCountdownText(text)
	local isVisible = (text ~= "" and text ~= nil)
	for _, player in ipairs(Players:GetPlayers()) do
		local gui = player:FindFirstChild("PlayerGui")
		if gui then
			local gameGui = gui:FindFirstChild("GameGUI")
			if gameGui then
				local countdown = gameGui:FindFirstChild("Countdown")
				if countdown then
					countdown.Visible = isVisible
					local label = countdown:FindFirstChild("TextLabel")
					if label then
						label.Text = text
					end
				end
			end
		end
	end
end

function SetPlayerControls(enabled)
	for _, player in ipairs(playersWaiting) do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				if not enabled then
					humanoid.WalkSpeed = 0
					humanoid.JumpPower = 0
				else
					humanoid.WalkSpeed = 16 -- Default
					humanoid.JumpPower = 50 -- Default
				end
			end
		end
	end
end

local function StartKickoff(gameId)
	clockRunning = false
	
	-- Teleport players
	for i, player in ipairs(playersWaiting) do
		if player and player.Character then
			player.Character.PrimaryPart.CFrame = teleportCFrames[i]
		end
	end
	
	SetPlayerControls(false)
	SetGameUIVisibility(true, gameId)
	
	-- Hide Goal UI at start of kickoff
	for _, player in ipairs(Players:GetPlayers()) do
		local gui = player:FindFirstChild("PlayerGui")
		if gui then
			local gameGui = gui:FindFirstChild("GameGUI")
			if gameGui then
				local goalFrame = gameGui:FindFirstChild("Goal")
				if goalFrame then goalFrame.Visible = false end
			end
		end
	end
	
	if BallSpawn then
		ResetBallEvent:Fire(BallSpawn.Position)
	end

	for i = 3, 1, -1 do
		SetCountdownText(tostring(i))
		task.wait(1)
	end
	
	SetCountdownText("GO!")
	SetPlayerControls(true)
	clockRunning = true
	
	task.wait(1)
	SetCountdownText("")
end

GoalScoredEvent.Event:Connect(function(team)
	if not InProgress then return end
	
	clockRunning = false
	if team == "red" then
		redScore = redScore + 1
	elseif team == "blue" then
		blueScore = blueScore + 1
	end
	
	UpdateScoreUI()
	
	-- Show Goal UI
	for _, player in ipairs(Players:GetPlayers()) do
		local gui = player:FindFirstChild("PlayerGui")
		if gui then
			local gameGui = gui:FindFirstChild("GameGUI")
			if gameGui then
				local goalFrame = gameGui:FindFirstChild("Goal")
				if goalFrame then
					goalFrame.Visible = true
					local textLabel = goalFrame:FindFirstChild("TextLabel")
					if textLabel then
						textLabel.Text = string.upper(team) .. " SCORED"
					end
				end
			end
		end
	end

	task.wait(3)
	if InProgress then
		local gameId = playersWaiting[1] and playersWaiting[1]:GetAttribute("GameId")
		StartKickoff(gameId)
	end
end)

local function StartGameTimer()
	while InProgress and remainingTime > 0 do
		if clockRunning then
			remainingTime = remainingTime - 1
			UpdateClockUI()
		end
		task.wait(1)
	end

	if remainingTime <= 0 then
		print("Game time reached. Resetting the game.")
		InProgress = false
		Reset()
	end
end

local function HandlePlayerDeath(player)
	if InProgress then
		InProgress = false
		print(("player '%s' died! Resetting the game."):format(player.Name))
		local isWaiting = table.find(playersWaiting, player)

		if isWaiting then
			-- Remove the player from the waiting list
			table.remove(playersWaiting, isWaiting)
			print(("player '%s' removed from waiting list."):format(player.Name))
		end
		timerRunning = false -- Add this line to stop the timer
		task.wait(3)
		Reset(player)
	end
end

-- Connect the Humanoid.Died event for each player in the playersWaiting list
local function ConnectPlayerDeathEvents()
	for _, player in ipairs(playersWaiting) do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.Died:Connect(function()
				HandlePlayerDeath(player)
			end)
		end
	end
end

local function Teleport()
	print("Game Started!")
	InProgress = true
	if #playersWaiting < Configs.MaxPlayers.Value then
		warn("Not enough players to start the game.")
		Reset()
		return
	end
	local gameId = game:GetService("HttpService"):GenerateGUID(false)
	
	for i, player in ipairs(playersWaiting) do
		if player then
			local teleportPosition = teleportCFrames[i]

			if teleportPosition then
				player.Character.PrimaryPart.CFrame = teleportPosition
				
				-- Set attributes and team
				local teamName = (i == 1) and "red" or "blue"
				player:SetAttribute("Team", teamName)
				player:SetAttribute("GameId", gameId)
				player.Team = Teams:FindFirstChild("In-Game")
			else
				warn("Teleport position not defined for player: " .. player.Name)
				Reset()
			end
		else
			warn("Player not found: " .. player.Name)
			Reset()
		end

		-- Connect Humanoid.Died event for each player after teleporting
		ConnectPlayerDeathEvents()
	end
	
	StartKickoff(gameId)
end

local function RunCountdown()
	countdownRunning = true
	for i = Configs.StartCountDown.Value, 1, -1 do
		MainBoard.SurfaceGui.Frame.Status.Text = "Starting in: " .. i
		task.wait(1)
		if #playersWaiting < Configs.MaxPlayers.Value then
			countdownRunning = false
			MainBoard.SurfaceGui.Frame.Status.Text = "Waiting..."
			print("Someone Left During The Countdown.")
			return
		end
	end
	Teleport()
	countdownRunning = false
	MainBoard.SurfaceGui.Frame.Status.Text = "In Progress..."
	StartGameTimer()
end

local function PlayerLeaving(player)
	print(("player '%s' is leaving!"):format(player.Name))

	local isWaiting = table.find(playersWaiting, player)

	if isWaiting then
		-- Remove the player from the waiting list
		table.remove(playersWaiting, isWaiting)
		print(("player '%s' removed from waiting list."):format(player.Name))
	end

	-- Check if the game is in progress
	if InProgress then
		print("A player left during the game. Resetting the game.")
		timerRunning = false -- Add this line to stop the timer
		InProgress = false
		Reset()
	end
end

Zone1.playerEntered:Connect(function(player)
	if InProgress == false then --Has to wait for the game to finish
		print(("player '%s' entered the zone!"):format(player.Name))
		local isWaiting = table.find(playersWaiting, player)

		if player and not isWaiting and #playersWaiting < Configs.MaxPlayers.Value and not Plate1HasPlayer then
			table.insert(playersWaiting, player)
			Plate1HasPlayer = true
			local userId = player.UserId
			local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
			Plate1Board.SurfaceGui.Frame.PlayerIcon.Image = content
			Plate1Board.SurfaceGui.Frame.PlayerName.Text = player.Name
			Plate1Board.Parent.Union.Color = Color3.new(1, 0, 0)
			print(playersWaiting)
			if not countdownRunning and #playersWaiting == Configs.MaxPlayers.Value then
				RunCountdown()
			end
		end
	end
end)

Zone1.playerExited:Connect(function(player)
	print(("player '%s' exited the zone!"):format(player.Name))
	local isWaiting = table.find(playersWaiting, player)
	if isWaiting and Plate1HasPlayer and not InProgress then
		table.remove(playersWaiting, isWaiting)
		Plate1HasPlayer = false
		Plate1Board.SurfaceGui.Frame.PlayerIcon.Image = "rbxassetid://9319891706"
		Plate1Board.SurfaceGui.Frame.PlayerName.Text = "..."
		Plate1Board.Parent.Union.Color = Color3.new(1, 1, 1)
		print(playersWaiting)
	end
end)

Zone2.playerEntered:Connect(function(player)
	if InProgress == false then --Has to wait for the game to finish
		print(("player '%s' entered the zone!"):format(player.Name))
		local isWaiting = table.find(playersWaiting, player)

		if player and not isWaiting and #playersWaiting < Configs.MaxPlayers.Value and not Plate2HasPlayer then
			table.insert(playersWaiting, player)
			Plate2HasPlayer = true
			local userId = player.UserId
			local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
			Plate2Board.SurfaceGui.Frame.PlayerIcon.Image = content
			Plate2Board.SurfaceGui.Frame.PlayerName.Text = player.Name
			Plate2Board.Parent.Union.Color = Color3.new(1, 0, 0)
			print(playersWaiting)
			if not countdownRunning and #playersWaiting == Configs.MaxPlayers.Value then
				RunCountdown()
			end
		end
	end
end)

Zone2.playerExited:Connect(function(player)
	print(("player '%s' exited the zone!"):format(player.Name))
	local isWaiting = table.find(playersWaiting, player)
	if isWaiting and Plate2HasPlayer and not InProgress then
		table.remove(playersWaiting, isWaiting)
		Plate2HasPlayer = false
		Plate2Board.SurfaceGui.Frame.PlayerIcon.Image = "rbxassetid://9319891706"
		Plate2Board.SurfaceGui.Frame.PlayerName.Text = "..."
		Plate2Board.Parent.Union.Color = Color3.new(1, 1, 1)
		print(playersWaiting)
	end
end)

Players.PlayerRemoving:Connect(PlayerLeaving)
