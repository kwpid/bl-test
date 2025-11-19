local BallConfig = {}

BallConfig.Paths = {
        REMOTE_EVENTS_FOLDER = "Ball_RemoteEvents",
        FLOOR_PART_NAME = "Floor",
}

BallConfig.Physics = {
        FLOAT_HEIGHT = 2.5,
        BASE_SPEED = 20,
        SPEED_INCREMENT = 10,
        MAX_SPEED = 110,
        DECELERATION = 0.998,
        MIN_SPEED = 1,
        BOUNCE_ENERGY_LOSS = 0.8,
        GRAVITY = 0.15,
        GRAVITY_THRESHOLD = 30,
        
        MIN_BOUNCE_ANGLE = 45,
}

BallConfig.Parry = {
        RANGE = 10,
        COOLDOWN = 0.5,
        TIMEOUT = 5,
        MIN_PARRY_TIME = 0.05,
        HIT_IMMUNITY_TIME = 0.5,
        MIN_HIT_INTERVAL = 0.05,
        
        MOBILE_RANGE_MULTIPLIER = 1.3,
        CONSOLE_RANGE_MULTIPLIER = 1.3,
}

BallConfig.Network = {
        UPDATE_RATE = 60,
        INTERPOLATION_DELAY = 0.1,
}

return BallConfig
