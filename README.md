# Roblox Ball Parry Game

A Roblox game featuring advanced ball physics and sword parrying mechanics.

## Features

### Ball System
- **Physics Engine**: Custom ball physics with floating, collision detection, and realistic bouncing
- **Speed Mechanics**: Progressive speed increase with each successful hit (20 → 150 studs/sec)
- **Visual Effects**: Dynamic trail that changes color based on ball speed
- **Smart Collision**: Raycasting-based collision detection with smooth interpolation

### Combat System
- **Sword Parrying**: Timing-based parrying mechanic with 10-stud range
- **Animations**: Two-state animation system (miss/success)
- **Cooldown System**: Prevents spam clicking
- **Auto-Equipment**: Swords automatically attach to player characters

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
SeverScriptService/
├── BallSever.lua      # Ball physics engine
└── swap.lua           # Sword/parry system

StarterCharacterScripts/
└── LocalScript.lua    # Player input handler
```

## Note
This repository serves as **version control** for the Roblox game scripts. The actual game runs in Roblox Studio/Platform, not in Replit.
