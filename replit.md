# Roblox Ball Game Project

## Overview
Professional Roblox ball parry game with client-side prediction, server-authoritative physics, and modular architecture.

## Recent Changes (Latest Update)
**Cross-platform support and ball spawn fix**:
- ✅ Enhanced mobile/console support with configurable hitbox multipliers
- ✅ Fixed ball spawning mid-air: ball now spawns at ground level + float height
- ✅ Console range multiplier (1.3x) added to config alongside mobile multiplier
- ✅ Ball initialization properly calculates ground height on server start
- ✅ Input support: Mouse (PC), Touch (Mobile), Gamepad R1/R2/A (Console)

**Previous: Dash and ball physics improvements**:
- ✅ Fixed dash falling issue: gravity completely disabled during dash (PlatformStand)
- ✅ Type 2 dash now dashes TO the ball in full 3D (not height-locked)
- ✅ Increased ball-facing angle to 70° (more lenient detection)
- ✅ Reduced ball deceleration: 0.994 → 0.998 (maintains speed longer)
- ✅ Added smooth gravity: ball falls when speed < 30 studs/sec
- ✅ Fixed mid-air freeze bug: ball now smoothly descends to ground

**Previous: Dash system overhaul**:
- ✅ Removed debug logs from BallServer
- ✅ Added AssetManager folder for animation references
- ✅ Implemented Type 1 dash: Height-locked dashing (maintains Y position)
- ✅ Implemented Type 2 dash: Ball-seeking dash when facing ball
- ✅ Cleaner, more modular dash code
- ✅ Animation support for dash mechanic

**Previous: Hit detection improvements**:
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
- `AssetManager/` - Folder containing animation objects (Dash, etc.)
- `BallConfig.lua` - Configuration constants
- `BallPhysics.lua` - Physics engine (client + server)

**ServerScriptService/** (Server)
- `BallServer.lua` - Authoritative ball physics (no debug logs)
- `SwordServer.lua` - Sword equipment & parry system
- `PlayerSetup.lua` - Player walkspeed configuration
- `DashServer.lua` - Height-locked & ball-seeking dash
- ~~`BallSever.lua`~~ - Deprecated
- ~~`swap.lua`~~ - Deprecated

**StarterCharacterScripts/** (Client)
- `BallClient.lua` - Client-side prediction
- `InputClient.lua` - User input handling
- `DashClient.lua` - Dash type detection (normal vs ball-seeking)
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
