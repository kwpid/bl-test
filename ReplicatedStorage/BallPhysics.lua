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

function BallPhysics:update(dt, raycastFunc, groundHeight)
        if not self.isMoving then
                return false
        end
        
        self.velocity = self.velocity * Config.Physics.DECELERATION
        
        local currentSpeed = self.velocity.Magnitude
        if currentSpeed < Config.Physics.GRAVITY_THRESHOLD then
                local gravityForce = Config.Physics.GRAVITY * dt * 60
                self.velocity = Vector3.new(
                        self.velocity.X,
                        self.velocity.Y - gravityForce,
                        self.velocity.Z
                )
        end
        
        local postGravitySpeed = self.velocity.Magnitude
        
        if postGravitySpeed < Config.Physics.MIN_SPEED then
                local horizontalSpeed = Vector3.new(self.velocity.X, 0, self.velocity.Z).Magnitude
                local verticalSpeed = math.abs(self.velocity.Y)
                
                if horizontalSpeed < 0.5 and verticalSpeed < 0.1 then
                        self.velocity = Vector3.new(0, 0, 0)
                        self.isMoving = false
                        return false
                end
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
                                local hitPartName = collision.Instance and collision.Instance.Name or ""
                                local isFloor = hitPartName == Config.Paths.FLOOR_PART_NAME or 
                                               (collision.Instance and collision.Instance:FindFirstAncestor(Config.Paths.FLOOR_PART_NAME))
                                local currentSpeed = self.velocity.Magnitude
                                
                                local shouldBounce = true
                                
                                if isFloor then
                                        local bounceHeight = groundHeight + Config.Physics.FLOAT_HEIGHT
                                        
                                        if nextPosition.Y <= bounceHeight then
                                                if currentSpeed < Config.Physics.MIN_BOUNCE_SPEED then
                                                        local velocityDirection = self.velocity.Unit
                                                        local impactAngle = math.deg(math.asin(math.abs(velocityDirection.Y)))
                                                        
                                                        if impactAngle < Config.Physics.MIN_BOUNCE_ANGLE then
                                                                shouldBounce = false
                                                                self.velocity = Vector3.new(self.velocity.X, 0, self.velocity.Z) * 0.5
                                                                self.position = Vector3.new(nextPosition.X, bounceHeight, nextPosition.Z)
                                                        end
                                                end
                                                
                                                if shouldBounce then
                                                        local reflectedVelocity = self.velocity - 2 * self.velocity:Dot(normal) * normal
                                                        self.velocity = reflectedVelocity * Config.Physics.BOUNCE_ENERGY_LOSS
                                                        self.position = Vector3.new(nextPosition.X, bounceHeight, nextPosition.Z)
                                                end
                                        else
                                                self.position = nextPosition
                                        end
                                else
                                        local reflectedVelocity = self.velocity - 2 * self.velocity:Dot(normal) * normal
                                        self.velocity = reflectedVelocity * Config.Physics.BOUNCE_ENERGY_LOSS
                                        self.position = collision.Position + (normal * 1.2)
                                        
                                        if self.velocity.Magnitude < 2 then
                                                self.velocity = Vector3.new(0, 0, 0)
                                                self.isMoving = false
                                        end
                                end
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
