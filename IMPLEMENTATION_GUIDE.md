# Implementation Guide

## New Architecture Overview

The codebase has been completely overhauled with a professional, modular architecture:

### Module Structure

**ReplicatedStorage/** (Shared modules)
- `BallConfig.lua` - Centralized configuration constants
- `BallPhysics.lua` - Shared physics engine (client + server)

**ServerScriptService/** (Server-only scripts)
- `BallServer.lua` - Server-authoritative ball physics
- `SwordServer.lua` - Sword equipment and parry system

**StarterCharacterScripts/** (Client-only scripts)
- `BallClient.lua` - Client-side prediction with smooth interpolation
- `InputClient.lua` - User input handling

## Key Improvements

### 1. Client-Side Prediction
- **Smooth gameplay**: Ball movement is predicted on client for zero perceived latency
- **Server reconciliation**: Client smoothly interpolates to server position
- **Visual fidelity**: Separate client ball with trail effects

### 2. Modular Design
- **BallPhysics module**: Reusable physics engine for both client and server
- **BallConfig module**: Single source of truth for all constants
- **Separation of concerns**: Each script has a single, clear responsibility

### 3. Network Optimization
- **60Hz update rate**: Server sends updates 60 times per second
- **State buffering**: Client maintains buffer of server states
- **Smart interpolation**: Smooth blending between client prediction and server state

### 4. Professional Code Quality
- **Clean architecture**: No spaghetti code, clear separation of concerns
- **Better error handling**: Proper validation and fallbacks
- **Performance optimized**: Efficient raycasting and update patterns
- **Maintainable**: Easy to modify constants and add features

## Setup Instructions

1. **Delete old scripts** (deprecated files):
   - `SeverScriptService/BallSever.lua` (typo in original)
   - `SeverScriptService/swap.lua`
   - `StarterCharacterScripts/LocalScript.lua`

2. **Place new files** in Roblox Studio:
   
   **ReplicatedStorage:**
   - Create `BallConfig` ModuleScript
   - Create `BallPhysics` ModuleScript
   - Ensure `Swords` folder exists with `DefaultSword` model
   - (Optional) Create `DashAnimation` Animation for dash animation
   - (Optional) Create `DoubleJumpAnimation` Animation for double jump

   **ServerScriptService:**
   - Add `BallServer` Script
   - Add `SwordServer` Script
   - Add `PlayerSetup` Script
   - Add `DashServer` Script

   **StarterPlayer > StarterCharacterScripts:**
   - Add `BallClient` LocalScript
   - Add `InputClient` LocalScript
   - Add `DashClient` LocalScript
   - Add `DoubleJumpClient` LocalScript

3. **Required workspace objects** (same as before):
   - `Ball` part in Workspace
   - `Dummy` model with proper attachments
   - RemoteEvents (auto-created by scripts)

## Configuration

All game parameters are in `BallConfig.lua`:

```lua
Physics = {
    FLOAT_HEIGHT = 2.5,        -- Ball height above ground
    BASE_SPEED = 20,           -- Starting speed
    SPEED_INCREMENT = 15,      -- Speed gain per hit
    MAX_SPEED = 150,           -- Speed cap
    DECELERATION = 0.994,      -- Slowdown rate
}

Parry = {
    RANGE = 10,                -- Parry distance
    COOLDOWN = 0.5,            -- Input cooldown
    TIMEOUT = 5,               -- Parry window timeout
}

Player = {
    WALKSPEED = 21,            -- Default player walkspeed
    DOUBLE_JUMP_POWER = 50,    -- Vertical velocity for double jump
}

Dash = {
    DISTANCE = 25,             -- Dash distance in studs
    DURATION = 0.3,            -- Dash duration in seconds
    COOLDOWN = 5,              -- Cooldown between dashes
    KEYBIND = Enum.KeyCode.Q,  -- Key to press for dash
}

Network = {
    UPDATE_RATE = 60,          -- Server updates/sec
    INTERPOLATION_DELAY = 0.1, -- Smoothing delay
}
```

## How It Works

### Server Flow
1. `BallServer.lua` runs authoritative physics using `BallPhysics` module
2. Sends state updates to all clients 60 times/sec
3. Validates player hits and applies velocity changes
4. Broadcasts state changes immediately on hit

### Client Flow
1. `BallClient.lua` receives server updates
2. Runs local prediction using same `BallPhysics` module
3. Smoothly interpolates between prediction and server state
4. Renders visual effects (trail, colors)
5. `InputClient.lua` handles mouse input with client-side cooldown

### Visual Improvements
- Server ball is hidden (transparency = 1)
- Client renders smooth predicted ball (transparency = 0)
- Trail only shows on client for performance
- No network jitter visible to players

## Testing Checklist

- [ ] Ball spawns and floats correctly
- [ ] Ball responds to parries with proper direction
- [ ] Speed increases with each hit
- [ ] Trail appears and changes color based on speed
- [ ] Ball movement is smooth (no jitter)
- [ ] Multiple players can hit simultaneously
- [ ] Collisions work properly
- [ ] Ground detection works on various terrain
- [ ] No console errors on server or client
- [ ] Parry animations play correctly

## Performance Notes

- Client prediction eliminates perceived latency
- 60Hz updates provide smooth server reconciliation
- Raycasting is optimized with proper filtering
- State buffering prevents packet loss issues
- Interpolation smooths network jitter
