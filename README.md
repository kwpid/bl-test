# Roblox Ball Parry Game

A Roblox game featuring advanced ball physics and sword parrying mechanics.

## Features

### Ball System
- **Smart Spawn**: Ball automatically spawns at ground level + float height (no mid-air spawning)
- **Physics Engine**: Custom ball physics with floating, collision detection, and realistic bouncing
- **Speed Mechanics**: Progressive speed increase with each successful hit (20 → 150 studs/sec)
- **Reduced Deceleration**: Ball maintains speed longer (0.998 deceleration rate)
- **Smooth Gravity**: When ball slows below 30 studs/sec, gravity gradually pulls it down
- **Visual Effects**: Dynamic trail that changes color based on ball speed
- **Smart Collision**: Raycasting-based collision detection with smooth interpolation
- **Client Prediction**: Smooth ball movement with zero perceived latency

### Combat System
- **Sword Parrying**: Timing-based parrying mechanic with 10-stud range
- **Cross-Platform Support**: Full support for PC, Mobile, and Console
  - **Mobile**: Touch input + increased hitbox range (configurable multiplier)
  - **Console**: Gamepad buttons (R1/R2/A) + increased hitbox range (configurable multiplier)
  - **PC**: Mouse click input with standard range
- **Animations**: Two-state animation system (miss/success)
- **Cooldown System**: Prevents spam clicking
- **Auto-Equipment**: Swords automatically attach to player characters

### Movement System
- **Enhanced Speed**: Walkspeed set to 21 (faster than default)
- **Dash Mechanic**: Press Shift to dash with zero gravity
  - **Type 1 (Normal)**: Dash in camera direction while maintaining current height
  - **Type 2 (Ball-Seeking)**: When facing the ball (within 70° angle), dash directly to it in 3D
- **No Falling During Dash**: Gravity is completely disabled during dash
- **Height Lock (Type 1)**: Player maintains exact Y position during normal dash
- **3D Movement (Type 2)**: Ball-seeking dash moves in full 3D space towards the ball
- **Dash Animation**: Custom animation plays during dash (optional)
- **Dash Cooldown**: 3 second cooldown between dashes
- **Dash Distance**: 15 studs per dash over 0.2 seconds

## Technical Details

**Language**: Lua (Roblox)  
**Scripts**: 3 total (2 server, 1 client)

### Required Roblox Components
- Ball part in Workspace
- Dummy model with attachments
- Sword models in ReplicatedStorage
- Parry animations
- (Optional) AssetManager folder in ReplicatedStorage with Dash animation

## Setup Instructions

1. Open this project in **Roblox Studio** (not Replit)
2. Place scripts in their designated service folders
3. Create the required workspace objects and attachments
4. Configure sword models and animations
5. Test in Roblox Studio

## Project Structure
```
ReplicatedStorage/
├── AssetManager/        # Folder containing animations
│   └── Dash            # Dash animation object
├── BallConfig.lua       # Centralized configuration
└── BallPhysics.lua      # Shared physics engine

ServerScriptService/
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
