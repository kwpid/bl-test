local BallPhysics = {}
local Config = require(script.Parent.BallConfig)

function BallPhysics.new(initialPosition)
        local self = {
                position = initialPosition or Vector3.new(0, 10, 0),
                velocity = Vector3.new(0, 0, 0),
                isMoving = false,
                hitCount = 0,
        }
        
        setmetatable(self, {__index = BallPhysics})
        return self
end

function BallPhysics:applyHit(direction, customSpeed)
        self.hitCount = self.hitCount + 1
        
        local speed = customSpeed or (Config.Physics.BASE_SPEED + (self.hitCount - 1) * Config.Physics.SPEED_INCREMENT)
        speed = math.min(speed, Config.Physics.MAX_SPEED)
        
        self.velocity = direction.Unit * speed
        self.isMoving = true
        
        return speed
end

function BallPhysics:update(dt, raycastFunc)
        if not self.isMoving then
                return false
        end
        
        self.velocity = self.velocity * Config.Physics.DECELERATION
        
        -- Apply gravity when ball is slow and in the air
        local currentSpeed = self.velocity.Magnitude
        if currentSpeed < Config.Physics.GRAVITY_THRESHOLD then
                local gravityForce = Config.Physics.GRAVITY * dt * 60
                self.velocity = Vector3.new(
                        self.velocity.X,
                        self.velocity.Y - gravityForce,
                        self.velocity.Z
                )
        end
        
        -- Recompute speed after gravity
        local postGravitySpeed = self.velocity.Magnitude
        
        -- Only stop if speed is very low AND no significant vertical movement
        -- This allows gravity to keep pulling the ball down
        if postGravitySpeed < Config.Physics.MIN_SPEED then
                local horizontalSpeed = Vector3.new(self.velocity.X, 0, self.velocity.Z).Magnitude
                local verticalSpeed = math.abs(self.velocity.Y)
                
                -- Stop only if both horizontal and vertical speeds are negligible
                if horizontalSpeed < 0.5 and verticalSpeed < 0.1 then
                        self.velocity = Vector3.new(0, 0, 0)
                        self.isMoving = false
                        return false
                end
                -- Otherwise keep moving (gravity is still pulling it down)
        end
        
        local moveDistance = self.velocity * dt
        local steps = math.max(1, math.ceil(moveDistance.Magnitude / 0.5))
        local stepVector = moveDistance / steps
        
        for i = 1, steps do
                local nextPosition = self.position + stepVector
                
                if raycastFunc then
                        local collision = raycastFunc(self.position, nextPosition)
                        
                        if collision then
                                local normal = collision.Normal
                                local reflectedVelocity = self.velocity - 2 * self.velocity:Dot(normal) * normal
                                self.velocity = reflectedVelocity * Config.Physics.BOUNCE_ENERGY_LOSS
                                self.position = collision.Position + (normal * 0.6)
                                break
                        else
                                self.position = nextPosition
                        end
                else
                        self.position = nextPosition
                end
        end
        
        return true
end

function BallPhysics:enforceFloatHeight(groundHeight)
        local targetHeight = groundHeight + Config.Physics.FLOAT_HEIGHT
        
        if self.position.Y < targetHeight and (not self.isMoving or self.velocity.Y < 1) then
                self.position = Vector3.new(self.position.X, targetHeight, self.position.Z)
                
                if self.isMoving and self.velocity.Y < 0 then
                        self.velocity = Vector3.new(self.velocity.X, 0, self.velocity.Z)
                end
        end
end

function BallPhysics:getSpeed()
        return self.velocity.Magnitude
end

function BallPhysics:getSpeedPercent()
        return math.clamp(self:getSpeed() / Config.Physics.MAX_SPEED, 0, 1)
end

function BallPhysics:serialize()
        return {
                position = self.position,
                velocity = self.velocity,
                isMoving = self.isMoving,
                hitCount = self.hitCount,
        }
end

function BallPhysics:deserialize(data)
        self.position = data.position
        self.velocity = data.velocity
        self.isMoving = data.isMoving
        self.hitCount = data.hitCount
end

return BallPhysics
