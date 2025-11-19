local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.BallConfig)

local dashEvent = ReplicatedStorage:FindFirstChild("DashEvent")
if not dashEvent then
        dashEvent = Instance.new("RemoteEvent")
        dashEvent.Name = "DashEvent"
        dashEvent.Parent = ReplicatedStorage
end

local playerCooldowns = {}

local function performDash(player, dashData)
        local character = player.Character
        if not character then return false end
        
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp then return false end
        
        if playerCooldowns[player.UserId] then
                return false
        end
        
        playerCooldowns[player.UserId] = true
        
        humanoid.PlatformStand = true
        
        local assetManager = ReplicatedStorage:FindFirstChild("AssetManager")
        if assetManager then
                local dashAnim = assetManager:FindFirstChild("Dash")
                if dashAnim then
                        local animator = humanoid:FindFirstChildOfClass("Animator")
                        if not animator then
                                animator = Instance.new("Animator")
                                animator.Parent = humanoid
                        end
                        
                        local animClone = dashAnim:Clone()
                        local animTrack = animator:LoadAnimation(animClone)
                        animTrack:Play()
                end
        end
        
        local dashDirection
        local dashDistance = Config.Dash.DISTANCE
        local startHeight = hrp.Position.Y
        local isDashingToBall = false
        
        if dashData.dashType == 2 and dashData.ballPosition then
                local toBall = (dashData.ballPosition - hrp.Position)
                local ballDistance = toBall.Magnitude
                
                if ballDistance > 0.1 then
                        dashDistance = math.min(ballDistance, Config.Dash.DISTANCE)
                        dashDirection = toBall.Unit
                        isDashingToBall = true
                else
                        dashDirection = dashData.direction
                        dashDistance = Config.Dash.DISTANCE
                end
        else
                dashDirection = dashData.direction
        end
        
        if not isDashingToBall then
                local horizontalDirection = Vector3.new(dashDirection.X, 0, dashDirection.Z)
                
                if horizontalDirection.Magnitude < 0.01 then
                        local lookVector = hrp.CFrame.LookVector
                        horizontalDirection = Vector3.new(lookVector.X, 0, lookVector.Z)
                        
                        if horizontalDirection.Magnitude < 0.01 then
                                humanoid.PlatformStand = false
                                playerCooldowns[player.UserId] = nil
                                return false
                        end
                end
                
                dashDirection = horizontalDirection.Unit
        end
        
        local dashSpeed = dashDistance / Config.Dash.DURATION
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
        bodyVelocity.Velocity = dashDirection * dashSpeed
        bodyVelocity.Parent = hrp
        
        local bodyPosition
        if not isDashingToBall then
                bodyPosition = Instance.new("BodyPosition")
                bodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
                bodyPosition.Position = Vector3.new(hrp.Position.X, startHeight, hrp.Position.Z)
                bodyPosition.D = 5000
                bodyPosition.P = 50000
                bodyPosition.Parent = hrp
        end
        
        local connection
        if bodyPosition then
                connection = game:GetService("RunService").Heartbeat:Connect(function()
                        if bodyPosition and bodyPosition.Parent then
                                bodyPosition.Position = Vector3.new(hrp.Position.X, startHeight, hrp.Position.Z)
                        end
                end)
        end
        
        task.delay(Config.Dash.DURATION, function()
                humanoid.PlatformStand = false
                if connection then
                        connection:Disconnect()
                end
                if bodyVelocity and bodyVelocity.Parent then
                        bodyVelocity:Destroy()
                end
                if bodyPosition and bodyPosition.Parent then
                        bodyPosition:Destroy()
                end
        end)
        
        task.delay(Config.Dash.COOLDOWN, function()
                playerCooldowns[player.UserId] = nil
        end)
        
        return true
end

dashEvent.OnServerEvent:Connect(function(player, dashData)
        if not dashData or typeof(dashData) ~= "table" then return end
        if not dashData.direction or typeof(dashData.direction) ~= "Vector3" then return end
        if not dashData.dashType or typeof(dashData.dashType) ~= "number" then return end
        if dashData.dashType ~= 1 and dashData.dashType ~= 2 then return end
        if dashData.dashType == 2 then
                if not dashData.ballPosition or typeof(dashData.ballPosition) ~= "Vector3" then return end
        end
        
        performDash(player, dashData)
end)

local function onPlayerRemoving(player)
        playerCooldowns[player.UserId] = nil
end

Players.PlayerRemoving:Connect(onPlayerRemoving)
