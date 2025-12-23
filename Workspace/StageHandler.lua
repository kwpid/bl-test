local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local Vector3 = Vector3
local task = task
local Enum = Enum
local workspace = workspace
local Color3 = Color3
local Instance = Instance
local BrickColor = BrickColor
local RaycastParams = RaycastParams
local CFrame = CFrame
local math = math

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
local Configs = script.Parent.Config
local BallConfig = require(ReplicatedStorage:WaitForChild("BallConfig"))
local MapManager = require(ReplicatedStorage:WaitForChild("MapManager"))
local RemoteEventsFolder = ReplicatedStorage:WaitForChild(BallConfig.Paths.REMOTE_EVENTS_FOLDER)
local ResetBallEvent = RemoteEventsFolder:WaitForChild("ResetBall")
local GoalScoredEvent = RemoteEventsFolder:WaitForChild("GoalScored")

local Zones = require(ModulesFolder.Zone)

local MapContainer = script.Parent

local GameInstance = {}
GameInstance.__index = GameInstance

local ActiveGames = {} 
local PlayerQueue = {}

function GameInstance.new(gameId, offsetIndex)
        local self = setmetatable({}, GameInstance)
        self.GameId = gameId
        self.OffsetIndex = offsetIndex
        self.Players = {} 
        self.Scores = { red = 0, blue = 0 }
        self.RemainingTime = 120 
        self.InProgress = false
        self.TimerRunning = false
        self.IsOvertime = false
        self.OvertimeSeconds = 0
        
        -- Use MapManager to create arena from available maps
        self.Arena, self.Refs = MapManager.createGameArena(gameId, offsetIndex, MapContainer)
        
        if not self.Arena then
                warn("StageHandler: Failed to create game arena for", gameId)
                return nil
        end
        
        -- Ensure Board references exist
        if self.Refs.Plate1 and not self.Refs.Board1 then
                self.Refs.Board1 = self.Refs.Plate1:FindFirstChild("Board")
        end
        if self.Refs.Plate2 and not self.Refs.Board2 then
                self.Refs.Board2 = self.Refs.Plate2:FindFirstChild("Board")
        end

        return self
end

function GameInstance:Start(p1, p2)
        self.Players = {p1, p2}
        self.InProgress = true
        
        p1:SetAttribute("GameId", self.GameId)
        p1:SetAttribute("Team", "red")
        p1.Team = Teams:FindFirstChild("In-Game")
        
        p2:SetAttribute("GameId", self.GameId)
        p2:SetAttribute("Team", "blue")
        p2.Team = Teams:FindFirstChild("In-Game")
        
        self:ConnectDeaths()
        
        self:UpdateBoard(p1, self.Refs.Board1, Color3.new(1,0,0))
        self:UpdateBoard(p2, self.Refs.Board2, Color3.new(0,0,1))
        
        if p1.Character and p1.Character.PrimaryPart then
                p1.Character.PrimaryPart.CFrame = self.Refs.T1.CFrame + Vector3.new(0, 3, 0)
        end
        if p2.Character and p2.Character.PrimaryPart then
                p2.Character.PrimaryPart.CFrame = self.Refs.T2.CFrame + Vector3.new(0, 3, 0)
        end

        self:SetGameUIVisibility(true)
        self:UpdateScoreUI()
        
        task.spawn(function()
                self:Kickoff()
        end)
        
        task.spawn(function()
                self:RunTimer()
        end)
end

function GameInstance:UpdateBoard(player, boardInfo, color)
        local surface = boardInfo:FindFirstChild("SurfaceGui")
        if surface and surface:FindFirstChild("Frame") then
                local frame = surface.Frame
                frame.PlayerName.Text = player.Name
                boardInfo.Parent.Union.Color = color
                task.spawn(function()
                        local content = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
                        frame.PlayerIcon.Image = content
                end)
        end
end

function GameInstance:Kickoff()
        self.TimerRunning = false
        
        self:SetControls(false)
        
        if self.Players[1].Character and self.Players[1].Character.PrimaryPart then
                self.Players[1].Character.PrimaryPart.CFrame = self.Refs.T1.CFrame + Vector3.new(0, 3, 0)
        end
        if self.Players[2].Character and self.Players[2].Character.PrimaryPart then
                self.Players[2].Character.PrimaryPart.CFrame = self.Refs.T2.CFrame + Vector3.new(0, 3, 0)
        end

        if self.Refs.BallSpawn then
                ResetBallEvent:Fire(self.Refs.BallSpawn.Position, self.GameId, self.Arena)
        end

        for i = 3, 1, -1 do
                self:SetCountdownText(tostring(i))
                task.wait(1)
        end
        self:SetCountdownText("GO!")
        
        self:SetControls(true)
        self.TimerRunning = true
        task.wait(1)
        self:SetCountdownText("")
end

function GameInstance:RunTimer()
        local buzzerGrace = 0
        while self.InProgress do
                if self.TimerRunning then
                        if not self.IsOvertime then
                                if self.RemainingTime > 0 then
                                        self.RemainingTime = self.RemainingTime - 1
                                end
                                
                                if self.RemainingTime <= 0 then
                                        local ball = self.Arena:FindFirstChild("Ball", true)
                                        local isGrounded = not ball or ball:GetAttribute("Grounded")
                                        
                                        if isGrounded then
                                                if self.Scores.red == self.Scores.blue then
                                                        self.IsOvertime = true
                                                        self.TimerRunning = false
                                                        self:Kickoff()
                                                else
                                                        self:EndGame("Time Limit")
                                                        break
                                                end
                                        else
                                                local safetyTimeout = 0
                                                while self.InProgress and safetyTimeout < 15 do
                                                        task.wait()
                                                        safetyTimeout = safetyTimeout + 0.03
                                                        
                                                        ball = self.Arena:FindFirstChild("Ball", true)
                                                        isGrounded = not ball or ball:GetAttribute("Grounded") == true
                                                        
                                                        if isGrounded then break end
                                                end
                                                if self.Scores.red == self.Scores.blue then
                                                        self.IsOvertime = true
                                                        self.TimerRunning = false
                                                        self:Kickoff()
                                                else
                                                        self:EndGame("Time Limit")
                                                        break
                                                end
                                        end
                                end
                        else
                                self.OvertimeSeconds = self.OvertimeSeconds + 1
                        end
                        self:UpdateClockUI()
                end
                task.wait(1)
        end
end

function GameInstance:ForceEnd(reason)
        if not self.InProgress then return end
        self:EndGame(reason)
end

function GameInstance:EndGame(reason)
        print("Ending Game:", self.GameId, "Reason:", reason)
        self.InProgress = false
        self.TimerRunning = false
        
        self:SetGameUIVisibility(false)
        
        for _, p in ipairs(self.Players) do
                p:SetAttribute("GameId", nil)
                p:SetAttribute("Team", nil)
                p.Team = Teams:FindFirstChild("Lobby")
                p:LoadCharacter()
        end
        
        if self.Arena then
                self.Arena:Destroy()
        end
        
        ActiveGames[self.GameId] = nil
end

function GameInstance:SetGameUIVisibility(visible)
        for _, p in ipairs(self.Players) do
                local gui = p:FindFirstChild("PlayerGui")
                if gui and gui:FindFirstChild("GameGUI") then
                        local screen = gui.GameGUI:FindFirstChild("GameScreen")
                        if screen then 
                                screen.Visible = visible 
                        end
                end
        end
end

function GameInstance:UpdateScoreUI()
        for _, p in ipairs(self.Players) do
                local gui = p:FindFirstChild("PlayerGui")
                if gui and gui:FindFirstChild("GameGUI") then
                        local screen = gui.GameGUI:FindFirstChild("GameScreen")
                        if screen then
                                if screen:FindFirstChild("Red") then screen.Red.RedScore.Text = tostring(self.Scores.red) end
                                if screen:FindFirstChild("Blue") then screen.Blue.BlueScore.Text = tostring(self.Scores.blue) end
                        end
                end
        end
end

function GameInstance:UpdateClockUI()
        local min, sec, txt
        if self.IsOvertime and not self.TimerRunning then
                txt = "OVERTIME"
        elseif not self.IsOvertime then
                min = math.floor(self.RemainingTime / 60)
                sec = self.RemainingTime % 60
                txt = string.format("%d:%02d", min, sec)
        else
                min = math.floor(self.OvertimeSeconds / 60)
                sec = self.OvertimeSeconds % 60
                txt = string.format("+%d:%02d", min, sec)
        end
        
        for _, p in ipairs(self.Players) do
                local gui = p:FindFirstChild("PlayerGui")
                if gui and gui:FindFirstChild("GameGUI") and gui.GameGUI:FindFirstChild("GameScreen") then
                        local clock = gui.GameGUI.GameScreen:FindFirstChild("Clock")
                        if clock then clock.ClockText.Text = txt end
                end
        end
end

function GameInstance:SetCountdownText(txt)
        for _, p in ipairs(self.Players) do
                local gui = p:FindFirstChild("PlayerGui")
                if gui and gui:FindFirstChild("GameGUI") then
                        local cd = gui.GameGUI:FindFirstChild("Countdown")
                        if cd then
                                cd.Visible = (txt ~= "")
                                cd.TextLabel.Text = txt
                        end
                end
        end
end

function GameInstance:SetControls(enabled)
        self.StoredSpeeds = self.StoredSpeeds or {}
        
        for _, p in ipairs(self.Players) do
                if p.Character then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                                if not enabled then
                                        self.StoredSpeeds[p.UserId] = {
                                                ws = hum.WalkSpeed,
                                                jp = hum.JumpPower
                                        }
                                        hum.WalkSpeed = 0
                                        hum.JumpPower = 0
                                else
                                        local stored = self.StoredSpeeds[p.UserId]
                                        if stored then
                                                hum.WalkSpeed = stored.ws
                                                hum.JumpPower = stored.jp
                                        else
                                                hum.WalkSpeed = 16
                                                hum.JumpPower = 50
                                        end
                                end
                        end
                end
        end
end

function GameInstance:ShowGoalUI(playerName)
        for _, p in ipairs(self.Players) do
                local gui = p:FindFirstChild("PlayerGui")
                if gui and gui:FindFirstChild("GameGUI") then
                        local goalFrame = gui.GameGUI:FindFirstChild("Goal")
                        if goalFrame then
                                goalFrame.Visible = true
                                if goalFrame:FindFirstChild("TextLabel") then
                                        goalFrame.TextLabel.Text = (playerName or "Someone") .. " SCORED!"
                                end
                                task.delay(3, function()
                                        goalFrame.Visible = false
                                end)
                        end
                end
        end
end

function GameInstance:ConnectDeaths()
        for _, p in ipairs(self.Players) do
                if p.Character then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                                hum.Died:Connect(function()
                                        if self.InProgress then
                                                local winner = (p == self.Players[1]) and self.Players[2] or self.Players[1]
                                                print(winner.Name .. " wins by disconnect/death")
                                                self:EndGame("Player Died")
                                        end
                                end)
                        end
                end
        end
end

local function TryStartGame()
        if #PlayerQueue >= 2 then
                local p1 = table.remove(PlayerQueue, 1)
                local p2 = table.remove(PlayerQueue, 1)
                
                local usedIndices = {}
                for _, g in pairs(ActiveGames) do usedIndices[g.OffsetIndex] = true end
                
                local freeIndex = 0
                while usedIndices[freeIndex] do freeIndex = freeIndex + 1 end
                
                local gameId = HttpService:GenerateGUID(false)
                local newGame = GameInstance.new(gameId, freeIndex)
                ActiveGames[gameId] = newGame
                
                newGame:Start(p1, p2)
        end
end

local LobbyRef = {
        Plate1 = MapContainer:WaitForChild("Plate1").Zone,
        Plate2 = MapContainer:WaitForChild("Plate2").Zone,
        Board1 = MapContainer:WaitForChild("Plate1").Board,
        Board2 = MapContainer:WaitForChild("Plate2").Board,
        MainBoard = MapContainer:WaitForChild("MainBoard"),
}
local Zone1 = Zones.new(LobbyRef.Plate1)
local Zone2 = Zones.new(LobbyRef.Plate2)

local function UpdateLobbyBoard(board, player)
        local frame = board.SurfaceGui.Frame
        if player then
                frame.PlayerName.Text = player.Name
                board.Parent.Union.Color = Color3.new(0,1,0) 
                task.spawn(function()
                        frame.PlayerIcon.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
                end)
        else
                frame.PlayerName.Text = "Waiting..."
                board.Parent.Union.Color = Color3.new(1,1,1)
                frame.PlayerIcon.Image = "rbxassetid://9319891706"
        end
end

local QueuedP1 = nil
local QueuedP2 = nil
local LobbyCountdownTask = nil

local function CancelLobbyCountdown()
        if LobbyCountdownTask then
                task.cancel(LobbyCountdownTask)
                LobbyCountdownTask = nil
        end
        
        if QueuedP1 then UpdateLobbyBoard(LobbyRef.Board1, QueuedP1) end
        if QueuedP2 then UpdateLobbyBoard(LobbyRef.Board2, QueuedP2) end
        
        local mainSurf = LobbyRef.MainBoard:FindFirstChild("SurfaceGui")
        if mainSurf and mainSurf:FindFirstChild("Frame") then
                local status = mainSurf.Frame:FindFirstChild("Status")
                if status then status.Text = "Waiting for Players..."
                else
                        local lbl = mainSurf.Frame:FindFirstChild("PlayerName") or mainSurf.Frame:FindFirstChildOfClass("TextLabel")
                        if lbl then lbl.Text = "Waiting..." end
                end
        end
end

local function StartLobbyCountdown()
        if LobbyCountdownTask then return end
        
        LobbyCountdownTask = task.spawn(function()
                for i = 5, 1, -1 do
                        local msg = "Starting in " .. i
                        if QueuedP1 then
                                LobbyRef.Board1.SurfaceGui.Frame.PlayerName.Text = msg
                        end
                        if QueuedP2 then
                                LobbyRef.Board2.SurfaceGui.Frame.PlayerName.Text = msg
                        end
                        
                        local mainSurf = LobbyRef.MainBoard:FindFirstChild("SurfaceGui")
                        if mainSurf and mainSurf:FindFirstChild("Frame") then
                                local status = mainSurf.Frame:FindFirstChild("Status")
                                if status then
                                        status.Text = msg
                                else
                                        local lbl = mainSurf.Frame:FindFirstChild("PlayerName") or mainSurf.Frame:FindFirstChildOfClass("TextLabel")
                                        if lbl then lbl.Text = msg end
                                end
                        end
                        
                        task.wait(1)
                end
                
                LobbyCountdownTask = nil
                
                local mainSurf = LobbyRef.MainBoard:FindFirstChild("SurfaceGui")
                if mainSurf and mainSurf:FindFirstChild("Frame") then
                        local status = mainSurf.Frame:FindFirstChild("Status")
                        if status then status.Text = "Waiting for Players..." 
                        else
                                local lbl = mainSurf.Frame:FindFirstChild("PlayerName") or mainSurf.Frame:FindFirstChildOfClass("TextLabel")
                                if lbl then lbl.Text = "Waiting..." end
                        end
                end
                
                if QueuedP1 and QueuedP2 then
                        table.insert(PlayerQueue, QueuedP1)
                        table.insert(PlayerQueue, QueuedP2)
                        
                        QueuedP1 = nil
                        QueuedP2 = nil
                        
                        UpdateLobbyBoard(LobbyRef.Board1, nil)
                        UpdateLobbyBoard(LobbyRef.Board2, nil)
                        
                        TryStartGame()
                else
                        CancelLobbyCountdown()
                end
        end)
end

local function CheckQueue()
        if QueuedP1 and QueuedP2 then
                StartLobbyCountdown()
        end
end

Zone1.playerEntered:Connect(function(player)
        if not QueuedP1 then
                QueuedP1 = player
                UpdateLobbyBoard(LobbyRef.Board1, player)
                CheckQueue()
        end
end)
Zone1.playerExited:Connect(function(player)
        if QueuedP1 == player then
                QueuedP1 = nil
                UpdateLobbyBoard(LobbyRef.Board1, nil)
                CancelLobbyCountdown()
        end
end)

Zone2.playerEntered:Connect(function(player)
        if not QueuedP2 then
                QueuedP2 = player
                UpdateLobbyBoard(LobbyRef.Board2, player)
                CheckQueue()
        end
end)
Zone2.playerExited:Connect(function(player)
        if QueuedP2 == player then
                QueuedP2 = nil
                UpdateLobbyBoard(LobbyRef.Board2, nil)
                CancelLobbyCountdown()
        end
end)

GoalScoredEvent.Event:Connect(function(team, gameId, hitterName)
        local gameInst = ActiveGames[gameId]
        if gameInst and gameInst.InProgress then
                gameInst.TimerRunning = false
                if team == "red" then gameInst.Scores.red += 1 end
                if team == "blue" then gameInst.Scores.blue += 1 end
                gameInst:UpdateScoreUI()
                gameInst:ShowGoalUI(hitterName)
                
                if gameInst.IsOvertime or gameInst.RemainingTime <= 0 then
                        task.wait(2)
                        gameInst:EndGame("Buzzer Goal")
                        return
                end
                
                task.wait(3)
                if gameInst.InProgress then
                        gameInst:Kickoff()
                end
        end
end)

Players.PlayerRemoving:Connect(function(player)
        if QueuedP1 == player then QueuedP1 = nil; UpdateLobbyBoard(LobbyRef.Board1, nil) end
        if QueuedP2 == player then QueuedP2 = nil; UpdateLobbyBoard(LobbyRef.Board2, nil) end
        
        local gid = player:GetAttribute("GameId")
        if gid and ActiveGames[gid] then
                ActiveGames[gid]:ForceEnd("Player Left")
        end
end)
