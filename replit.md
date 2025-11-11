# Roblox Ball Game Project

## Overview
Professional Roblox ball parry game with client-side prediction, server-authoritative physics, and modular architecture.

## Recent Changes (Latest Update)
**Hit detection improvements**:
- ✅ Fixed double-hit bug when ball bounces off walls
- ✅ Added 0.5s immunity after successful hit
- ✅ Improved hit validation and reliability
- ✅ Added minimum parry window time (0.05s)
- ✅ Better server-side hit verification

**Player movement**:
- ✅ Dash mechanic (Shift key) - 15 studs in 0.2s
- ✅ Walkspeed set to 21

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
- `DashClient.lua` - Dash input (Shift key)
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
