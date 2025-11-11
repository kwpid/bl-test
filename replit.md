# Roblox Ball Game Project

## Overview
Professional Roblox ball parry game with client-side prediction, server-authoritative physics, and modular architecture.

## Recent Changes (Latest Update)
**Player movement enhancements**:
- ✅ Set default walkspeed to 21 (faster movement)
- ✅ Added dash mechanic (Q key) with 5 second cooldown
- ✅ Smart ball detection - dash toward ball if looking at it
- ✅ Double jump mechanic with animation support
- ✅ Faster dash (0.15s, more instant feel)

**Previous: Complete code overhaul**:
- ✅ Added client-side ball prediction for smooth gameplay
- ✅ Implemented modular design with shared physics engine
- ✅ Server remains authoritative with 60Hz update rate
- ✅ Network optimizations with interpolation and state buffering
- ✅ Centralized configuration system
- ✅ Better code organization and maintainability

## Architecture

### Modular Structure
**ReplicatedStorage/** (Shared)
- `BallConfig.lua` - Configuration constants
- `BallPhysics.lua` - Physics engine (client + server)

**ServerScriptService/** (Server)
- `BallServer.lua` - Authoritative ball physics
- `SwordServer.lua` - Sword equipment & parry system
- `PlayerSetup.lua` - Player walkspeed configuration
- `DashServer.lua` - Dash mechanic (server-side)
- ~~`BallSever.lua`~~ - Deprecated
- ~~`swap.lua`~~ - Deprecated

**StarterCharacterScripts/** (Client)
- `BallClient.lua` - Client-side prediction
- `InputClient.lua` - User input handling
- `DashClient.lua` - Dash input (Q key)
- `DoubleJumpClient.lua` - Double jump mechanic
- ~~`LocalScript.lua`~~ - Deprecated

## Key Features

### Client-Side Prediction
- Zero perceived latency for ball movement
- Smooth interpolation to server state
- Separate visual ball on client
- No network jitter

### Server Authority
- Physics simulation runs on server
- 60Hz state updates to clients
- Validates all hits and collisions
- Prevents cheating

### Professional Code
- Modular, reusable components
- Single source of truth for config
- Clean separation of concerns
- Easy to maintain and extend

## Implementation Guide
See `IMPLEMENTATION_GUIDE.md` for detailed setup instructions.

## Development Environment
This Replit serves as **version control** for the Roblox project. Code runs in Roblox Studio, not here.
