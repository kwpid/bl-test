local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local DASH_DISTANCE = 25
local DASH_DURATION = 0.15
local DASH_COOLDOWN = 5

local dashEvent = ReplicatedStorage:FindFirstChild("DashEvent")
if not dashEvent then
        dashEvent = Instance.new("RemoteEvent")
        dashEvent.Name = "DashEvent"
        dashEvent.Parent = ReplicatedStorage
end

local playerCooldowns = {}

local function performDash(player, direction, allowVertical)
        local character = player.Character
        if not character then return false end
        
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp then return false end
        
        if playerCooldowns[player.UserId] then
                return false
        end
        
        playerCooldowns[player.UserId] = true
        
        local dashDirection
        if allowVertical then
                dashDirection = direction.Unit
        else
                dashDirection = Vector3.new(direction.X, 0, direction.Z).Unit
        end
        
        local targetCFrame = hrp.CFrame + (dashDirection * DASH_DISTANCE)
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
        bodyVelocity.Velocity = dashDirection * (DASH_DISTANCE / DASH_DURATION)
        bodyVelocity.Parent = hrp
        
        if allowVertical then
                local bodyGyro = Instance.new("BodyGyro")
                bodyGyro.MaxTorque = Vector3.new(0, 0, 0)
                bodyGyro.P = 0
                bodyGyro.Parent = hrp
                
                task.delay(DASH_DURATION, function()
                        if bodyGyro and bodyGyro.Parent then
                                bodyGyro:Destroy()
                        end
                end)
        end
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
                animator = Instance.new("Animator")
                animator.Parent = humanoid
        end
        
        local dashAnim = ReplicatedStorage:FindFirstChild("DashAnimation")
        if dashAnim then
                local animTrack = animator:LoadAnimation(dashAnim)
                animTrack:Play()
        end
        
        task.delay(DASH_DURATION, function()
                if bodyVelocity and bodyVelocity.Parent then
                        bodyVelocity:Destroy()
                end
        end)
        
        task.delay(DASH_COOLDOWN, function()
                playerCooldowns[player.UserId] = nil
        end)
        
        return true
end

dashEvent.OnServerEvent:Connect(function(player, direction, allowVertical)
        if not direction or typeof(direction) ~= "Vector3" then return end
        performDash(player, direction, allowVertical)
end)

local function onPlayerRemoving(player)
        playerCooldowns[player.UserId] = nil
end

Players.PlayerRemoving:Connect(onPlayerRemoving)

print("Dash server initialized - Distance:", DASH_DISTANCE, "Cooldown:", DASH_COOLDOWN)
