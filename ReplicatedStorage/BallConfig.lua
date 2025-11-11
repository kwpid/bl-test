local BallConfig = {}

BallConfig.Physics = {
        FLOAT_HEIGHT = 2.5,
        BASE_SPEED = 20,
        SPEED_INCREMENT = 15,
        MAX_SPEED = 150,
        DECELERATION = 0.994,
        MIN_SPEED = 1,
        BOUNCE_ENERGY_LOSS = 0.8,
        GRAVITY = 0,
}

BallConfig.Visual = {
        TRAIL_LIFETIME = 0.5,
        TRAIL_MIN_LENGTH = 0.1,
        MIN_TRAIL_SPEED = 5,
        COLOR_SLOW = Color3.new(1, 1, 1),
        COLOR_FAST = Color3.new(0, 0.5, 1),
}

BallConfig.Parry = {
        RANGE = 10,
        COOLDOWN = 0.5,
        TIMEOUT = 5,
        MIN_PARRY_TIME = 0.05,
        HIT_IMMUNITY_TIME = 0.5,
        MIN_HIT_INTERVAL = 0.1,
}

BallConfig.Network = {
        UPDATE_RATE = 60,
        INTERPOLATION_DELAY = 0.1,
}

BallConfig.Player = {
        WALKSPEED = 21,
}

BallConfig.Dash = {
        DISTANCE = 15,
        DURATION = 0.2,
        COOLDOWN = 3,
        KEYBIND = Enum.KeyCode.LeftShift,
}

return BallConfig
