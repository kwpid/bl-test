local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.BallConfig)
local AssetManager = require(ReplicatedStorage.AssetManager)

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
        
        -- Load and play dash animation
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
                animator = Instance.new("Animator")
                animator.Parent = humanoid
        end
        
        local dashAnimId = AssetManager.Dash
        if dashAnimId and dashAnimId ~= "rbxassetid://0" then
                local dashAnim = Instance.new("Animation")
                dashAnim.AnimationId = dashAnimId
                local animTrack = animator:LoadAnimation(dashAnim)
                animTrack:Play()
        end
        
        local dashDirection
        local dashDistance = Config.Dash.DISTANCE
        local startHeight = hrp.Position.Y
        
        -- Determine dash direction and distance based on dash type
        if dashData.dashType == 2 and dashData.ballPosition then
                -- Type 2: Dash towards ball (clamp to actual ball distance)
                local toBall = (dashData.ballPosition - hrp.Position)
                local ballDistance = toBall.Magnitude
                
                if ballDistance > 0.1 then
                        -- Clamp dash distance to actual ball distance
                        dashDistance = math.min(ballDistance, Config.Dash.DISTANCE)
                        dashDirection = toBall.Unit
                else
                        -- Ball too close, use normal dash
                        dashDirection = dashData.direction
                        dashDistance = Config.Dash.DISTANCE
                end
        else
                -- Type 1: Normal dash in camera direction (height-locked)
                dashDirection = dashData.direction
        end
        
        -- Lock the Y component to maintain height
        local horizontalDirection = Vector3.new(dashDirection.X, 0, dashDirection.Z)
        
        -- Guard against zero-length vector (looking straight up/down)
        if horizontalDirection.Magnitude < 0.01 then
                -- Fallback: use character's facing direction
                local lookVector = hrp.CFrame.LookVector
                horizontalDirection = Vector3.new(lookVector.X, 0, lookVector.Z)
                
                -- If still zero, abort dash
                if horizontalDirection.Magnitude < 0.01 then
                        playerCooldowns[player.UserId] = nil
                        return false
                end
        end
        
        dashDirection = horizontalDirection.Unit
        
        local dashSpeed = dashDistance / Config.Dash.DURATION
        
        -- Use BodyVelocity for smooth dash with height locking
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
        bodyVelocity.Velocity = dashDirection * dashSpeed
        bodyVelocity.Parent = hrp
        
        -- Create BodyPosition to lock height
        local bodyPosition = Instance.new("BodyPosition")
        bodyPosition.MaxForce = Vector3.new(0, 100000, 0)
        bodyPosition.Position = Vector3.new(hrp.Position.X, startHeight, hrp.Position.Z)
        bodyPosition.D = 1000
        bodyPosition.P = 10000
        bodyPosition.Parent = hrp
        
        -- Update height lock during dash
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
                if bodyPosition and bodyPosition.Parent then
                        bodyPosition.Position = Vector3.new(hrp.Position.X, startHeight, hrp.Position.Z)
                end
        end)
        
        -- Clean up after dash duration
        task.delay(Config.Dash.DURATION, function()
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
        
        -- Reset cooldown
        task.delay(Config.Dash.COOLDOWN, function()
                playerCooldowns[player.UserId] = nil
        end)
        
        return true
end

dashEvent.OnServerEvent:Connect(function(player, dashData)
        -- Validate all remote parameters
        if not dashData or typeof(dashData) ~= "table" then return end
        if not dashData.direction or typeof(dashData.direction) ~= "Vector3" then return end
        if not dashData.dashType or typeof(dashData.dashType) ~= "number" then return end
        
        -- Validate dash type
        if dashData.dashType ~= 1 and dashData.dashType ~= 2 then return end
        
        -- Validate ball position if dash type 2
        if dashData.dashType == 2 then
                if not dashData.ballPosition or typeof(dashData.ballPosition) ~= "Vector3" then return end
        end
        
        performDash(player, dashData)
end)

local function onPlayerRemoving(player)
        playerCooldowns[player.UserId] = nil
end

Players.PlayerRemoving:Connect(onPlayerRemoving)
