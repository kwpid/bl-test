# Roblox Ball Parry Game

A Roblox game featuring advanced ball physics and sword parrying mechanics.

## Features

### Ball System
- **Physics Engine**: Custom ball physics with floating, collision detection, and realistic bouncing
- **Speed Mechanics**: Progressive speed increase with each successful hit (20 → 150 studs/sec)
- **Visual Effects**: Dynamic trail that changes color based on ball speed
- **Smart Collision**: Raycasting-based collision detection with smooth interpolation
- **Client Prediction**: Smooth ball movement with zero perceived latency

### Combat System
- **Sword Parrying**: Timing-based parrying mechanic with 10-stud range
- **Animations**: Two-state animation system (miss/success)
- **Cooldown System**: Prevents spam clicking
- **Auto-Equipment**: Swords automatically attach to player characters

### Movement System
- **Enhanced Speed**: Walkspeed set to 21 (faster than default)
- **Dash Mechanic**: Press Shift to dash in camera direction (full 3D movement)
- **Dash Cooldown**: 3 second cooldown between dashes
- **Dash Distance**: 15 studs per dash over 0.2 seconds
- **Aerial Movement**: Dash works in any direction including vertical

## Technical Details

**Language**: Lua (Roblox)  
**Scripts**: 3 total (2 server, 1 client)

### Required Roblox Components
- Ball part in Workspace
- Dummy model with attachments
- Sword models in ReplicatedStorage
- Parry animations

## Setup Instructions

1. Open this project in **Roblox Studio** (not Replit)
2. Place scripts in their designated service folders
3. Create the required workspace objects and attachments
4. Configure sword models and animations
5. Test in Roblox Studio

## Project Structure
```
ReplicatedStorage/
├── BallConfig.lua       # Centralized configuration
└── BallPhysics.lua      # Shared physics engine

SeverScriptService/
├── BallServer.lua       # Server ball physics
├── SwordServer.lua      # Sword/parry system
├── PlayerSetup.lua      # Player configuration
└── DashServer.lua       # Dash mechanics

StarterCharacterScripts/
├── BallClient.lua       # Client ball prediction
├── InputClient.lua      # Parry input handler
└── DashClient.lua       # Dash input handler
```

## Note
This repository serves as **version control** for the Roblox game scripts. The actual game runs in Roblox Studio/Platform, not in Replit.
