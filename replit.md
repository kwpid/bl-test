# Roblox Lua Game Scripts

## Overview
This repository contains Lua scripts for a Roblox game. These scripts implement game mechanics including ball physics, player input handling, sword combat, jumping mechanics, and inventory management.

## Project Type
**Roblox Game Scripts** - These files are designed to run within Roblox Studio or the Roblox game engine, not as standalone applications.

## Project Structure
```
ReplicatedStorage/       - Shared modules accessible by both client and server
  BallConfig.lua        - Configuration values for ball physics and gameplay
  BallPhysics.lua       - Physics simulation for the ball
  MapManager.lua        - Dynamic map/stage selection and arena creation
  Maps/                 - Folder containing map models (created automatically)
    [MapName]/          - Each map model with:
      BallSpawn         - Ball spawn location
      T1, T2            - Team spawn locations
      Plate1, Plate2    - Team areas
      Config (IntValue) - MaxPlayers configuration

ServerScriptService/     - Server-side scripts (run on Roblox servers)
  BallServer.lua        - Server-side ball logic and networking
  DataService.lua       - Player data persistence
  JumpServer.lua        - Server-side jump mechanics
  SwordServer.lua       - Server-side sword combat

StarterCharacterScripts/ - Scripts attached to player characters
  BallClient.lua        - Client-side ball rendering
  InputClient.lua       - Player input handling
  JumpClient.lua        - Client-side jump visuals

StarterGUI/              - GUI scripts and interfaces
  InventoryGUI.lua      - Inventory user interface

Workspace/               - Scripts placed in the game world
  StageHandler.lua      - Stage/match management (uses MapManager)
```

## Recent Changes (Scalable Map System)

### New MapManager Module
- Centralized map/stage logic in `ReplicatedStorage/MapManager.lua`
- Dynamically selects random maps from `ReplicatedStorage/Maps/` folder
- Each map can have its own configuration (MaxPlayers IntValue)
- Eliminates need to update StageHandler for each new map

### Updated StageHandler
- Refactored to use MapManager for arena creation
- Removed hardcoded template parts
- Now supports unlimited map variations
- Automatically reads map configurations

## Setup Instructions

### Adding New Maps
1. Create a Model in `ReplicatedStorage/Maps/`
2. Inside the model, include:
   - **BallSpawn** - Part where the ball spawns
   - **T1** - Team 1 spawn location
   - **T2** - Team 2 spawn location
   - **Plate1** - Team 1 playing area (optional, for UI boards)
   - **Plate2** - Team 2 playing area (optional, for UI boards)
   - **Config** - IntValue named "Config" with MaxPlayers value
3. The system will automatically use this map for new games

### Using MapManager in Scripts
```lua
local MapManager = require(ReplicatedStorage:WaitForChild("MapManager"))

-- Get a random map and create an arena
local arena, refs = MapManager.createGameArena(gameId, offsetIndex, parentFolder)
-- refs contains: BallSpawn, T1, T2, Plate1, Plate2, Board1, Board2

-- List all available maps (for debugging)
local maps = MapManager.listMaps()

-- Validate a map structure
local isValid, error = MapManager.validateMap(myMap)
```

## Game Features
- Ball physics with parrying/hitting mechanics
- Team-based gameplay (red vs blue)
- Goal scoring system
- Jump mechanics
- Sword combat
- Inventory system
- Developer debug commands
- **Dynamic map system** - Add maps without code changes

## ⚠️ ROBLOX STUDIO PROJECT - Cannot Run in Replit

**This repository contains a Roblox game project that REQUIRES Roblox Studio to run.** Replit cannot execute Roblox code - it's only suitable for version control and code editing.

### Quick Setup in Roblox Studio

1. **Open Roblox Studio** with your game project
2. **Copy these files** from this repository into your game:
   - `ReplicatedStorage/MapManager.lua` → ReplicatedStorage folder
   - `Workspace/StageHandler.lua` → Workspace/Stage folder (replace old one)
   - Other scripts as needed

3. **Create your maps:**
   - In Studio: `ReplicatedStorage` → Create Folder → Name it `Maps`
   - Inside `Maps`: Create Models for each game arena
   - Each map model MUST have:
     - **BallSpawn** (Part) - where the ball spawns
     - **T1** (Part) - Team 1 spawn location
     - **T2** (Part) - Team 2 spawn location
   - Optional extras:
     - **Plate1**, **Plate2** (Parts with Board inside) - game arena UI
     - **Config** (IntValue) - Set value to max players (default: 2)

4. **Your lobby (Workspace/Stage) stays as-is** - it's separate from game maps

### What Changed

- **MapManager.lua** - New system that selects random maps from ReplicatedStorage/Maps/
- **StageHandler.lua** - Refactored to use MapManager (no code updates needed for new maps)
- Maps are now dynamic and scalable - add unlimited maps without touching StageHandler
- Fixed error handling for missing board parts

### Common Issues

| Issue | Solution |
|-------|----------|
| Game fails to start | Check that at least one map exists in ReplicatedStorage/Maps/ with BallSpawn, T1, T2 |
| Players not teleported | Verify T1 and T2 parts exist in your map |
| Ball doesn't spawn | Ensure BallSpawn part exists in your map |
| Output shows warnings | Check ReplicatedStorage has Modules folder (Zone module needed) |
