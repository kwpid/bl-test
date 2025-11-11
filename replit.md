# Roblox Ball Game Project

## Overview
Professional Roblox ball parry game with client-side prediction, server-authoritative physics, and modular architecture.

## Recent Changes (Latest Update)
**Complete code overhaul** - Rewrote entire codebase with professional architecture:
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
- ~~`BallSever.lua`~~ - Deprecated
- ~~`swap.lua`~~ - Deprecated

**StarterCharacterScripts/** (Client)
- `BallClient.lua` - Client-side prediction
- `InputClient.lua` - User input handling
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
