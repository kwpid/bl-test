# Roblox Ball Game - Architecture Documentation

## Overview
Professional Roblox ball parry game with client-side prediction, server-authoritative physics, and modular architecture designed for easy integration into other projects.

---

## Core Components

### 1. **BallPhysics.lua** (Shared Module)
**Location:** `ReplicatedStorage/BallPhysics.lua`

**Purpose:** Shared physics engine used by both server and client for consistent ball behavior.

**Key Functions:**
- `BallPhysics.new(position)` - Creates new ball state
- `applyHit(direction)` - Applies parry hit to ball
- `update(dt, raycastFunc, groundHeight)` - Updates ball physics per frame
- `enforceFloatHeight(groundHeight)` - Keeps ball at float height when idle

**Floor Bounce Logic:**
- Ball bounces when crossing float height plane (`groundHeight + FLOAT_HEIGHT`)
- **Bounce Condition:** Impact angle >= 45° (steep impacts)
- **Slide Condition:** Impact angle < 45° (shallow impacts, loses 5% speed)
- Bounce happens AT the float height, not ground level (prevents stutter)

---

### 2. **BallConfig.lua** (Configuration)
**Location:** `ReplicatedStorage/BallConfig.lua`

**Purpose:** Centralized configuration for all game parameters.

**Sections:**
- `Paths` - Asset locations (RemoteEvents folder, Floor part name)
- `Physics` - Ball physics constants (speed, gravity, bounce)
- `Parry` - Combat system settings (range, cooldown, immunity)
- `Network` - Server update rates

**Key Parameters for Tuning:**
```lua
FLOAT_HEIGHT = 2.5           -- Ball hovers this many studs above ground
MIN_BOUNCE_ANGLE = 45        -- Minimum angle (degrees) to bounce (not slide)
BOUNCE_ENERGY_LOSS = 0.8     -- Energy retained after bounce (0.8 = 80%)
DECELERATION = 0.998         -- Speed loss per frame
```

---

### 3. **BallServer.lua** (Server Authority)
**Location:** `ServerScriptService/BallServer.lua`

**Purpose:** Authoritative ball physics simulation and network broadcasting.

**Responsibilities:**
- Run physics simulation at 60 FPS
- Broadcast ball state to all clients at 60Hz
- Validate and process player hits
- Update raycast filters to exclude players/swords
- Prevent exploits (validates input vectors)

**Security:** Validates camera direction magnitude to prevent zero-vector exploits.

---

### 4. **BallClient.lua** (Client Prediction)
**Location:** `StarterCharacterScripts/BallClient.lua`

**Purpose:** Client-side prediction for smooth, lag-free ball movement.

**How It Works:**
1. Receives server state updates (60Hz)
2. Runs local prediction using same physics engine
3. Smoothly interpolates between prediction and server state
4. Renders visual effects (trail, color based on speed)

**Raycast Filter:** Automatically updates on respawn to exclude player character.

---

### 5. **SwordServer.lua** (Combat System)
**Location:** `ServerScriptService/SwordServer.lua`

**Purpose:** Handles sword equipment and parry mechanics.

**Features:**
- Auto-equips swords to players on spawn
- Creates parry windows with hit detection
- Validates hits within range
- Prevents double-hits with immunity system
- Plays animations (success/fail)

---

### 6. **InputClient.lua** (User Input)
**Location:** `StarterCharacterScripts/InputClient.lua`

**Purpose:** Captures player mouse clicks and sends to server.

**Flow:**
1. Player clicks left mouse button
2. Client applies cooldown (prevents spam)
3. Sends camera direction to server via RemoteEvent

---

## Network Architecture

### RemoteEvents Setup
**Location:** `ReplicatedStorage/Ball_RemoteEvents/`

**Required Events:**
1. **BallUpdateEvent** (RemoteEvent) - Server → All Clients (ball state)
2. **SwingEvent** (RemoteEvent) - Client → Server (parry input)
3. **ServerBallHit** (BindableEvent) - Server internal (SwordServer → BallServer)

### Data Flow
```
Player Clicks
    ↓
InputClient → SwingEvent → SwordServer
                              ↓
                         (validates hit)
                              ↓
                         ServerBallHit → BallServer
                                           ↓
                                      (applies physics)
                                           ↓
                                      BallUpdateEvent → All Clients
                                                          ↓
                                                      BallClient
                                                    (smooth render)
```

---

## Performance Considerations

### Optimizations
✅ **Client prediction** - Zero perceived latency for local player  
✅ **60Hz updates** - Smooth network synchronization  
✅ **Raycast filtering** - Excludes players/swords for accurate collision  
✅ **State buffering** - Client maintains buffer to handle packet loss  
✅ **Stepped raycasting** - Subdivides movement for accurate collision detection

### Potential Bottlenecks
⚠️ **Ground height raycasting** - Called every 0.1s, acceptable for most games  
⚠️ **Player raycast filter updates** - Rebuilds filter on player join (minimal impact)

---

## Modifying for Your Game

### Easy Customizations (Config Only)
**File:** `ReplicatedStorage/BallConfig.lua`

- **Ball Speed:** Adjust `BASE_SPEED`, `SPEED_INCREMENT`, `MAX_SPEED`
- **Bounce Behavior:** Change `MIN_BOUNCE_ANGLE`, `BOUNCE_ENERGY_LOSS`
- **Float Height:** Modify `FLOAT_HEIGHT`
- **Parry Range:** Change `Parry.RANGE`
- **Update Rate:** Adjust `Network.UPDATE_RATE`

### Advanced Customizations

**Adding Custom Collision Logic:**
Edit `BallPhysics.lua` → `update()` function around line 95-110

**Changing Floor Detection:**
Edit `BallConfig.lua` → `Paths.FLOOR_PART_NAME` to match your floor part

**Modifying Hit Validation:**
Edit `SwordServer.lua` → `createParryWindow()` function

**Custom Trail Effects:**
Edit `BallClient.lua` → Trail creation section (lines 19-34)

---

## Common Issues & Solutions

### Ball doesn't bounce
- ✅ Ensure `FLOOR_PART_NAME` matches your floor part name in workspace
- ✅ Check `MIN_BOUNCE_ANGLE` - lower value = more forgiving bounces

### Ball stutters on ground
- ✅ Verify `FLOAT_HEIGHT` is at least 1.5 studs above floor
- ✅ Check `enforceFloatHeight()` isn't being called too frequently

### Clients desync from server
- ✅ Increase `Network.UPDATE_RATE` for more frequent updates
- ✅ Check raycast filters are updating on player respawn

### Exploiters causing issues
- ✅ Server validates all input (magnitude checks on vectors)
- ✅ Hit immunity prevents spam abuse

---

## Code Quality Notes

### ✅ Strengths
- **Modular design** - Easy to understand and modify
- **Centralized config** - One place to tune all parameters
- **Clear separation** - Client vs Server responsibilities well-defined
- **Security hardened** - Input validation prevents exploits
- **Well-commented** - Key logic explained in code

### 📝 For Other Developers
- **All config in one file** - Check `BallConfig.lua` first
- **Physics are deterministic** - Same `BallPhysics` module used everywhere
- **Network is abstracted** - RemoteEvents clearly defined
- **Extensible** - Add new features by extending modules, not rewriting

---

## Testing Checklist

When integrating into your game:

- [ ] Create `Ball_RemoteEvents` folder with 3 events in ReplicatedStorage
- [ ] Name floor part "Floor" (or update config)
- [ ] Test ball bounces at high speed (drops from ceiling)
- [ ] Test ball slides at shallow angles
- [ ] Verify multiple players can see ball movement
- [ ] Test parrying from different angles
- [ ] Check performance with 10+ players
- [ ] Verify no console errors on server or client

---

## Version History

**Latest:** Floor bounce detection refactor
- Ball bounces at float height (no stutter)
- Angle-based bounce logic (steep = bounce, shallow = slide)
- RemoteEvents centralized in folder
- Security hardening (input validation)
- Client raycast filter auto-updates on respawn

---

## Support & Modification

This codebase is designed for other developers to integrate and modify. Key principles:

1. **Config-first** - Try changing config values before editing code
2. **Modular** - Each file has a single, clear purpose
3. **Readable** - Variable names are descriptive, logic is clear
4. **Secure** - Server validates all client input
5. **Documented** - This file + inline comments explain everything

**Need help?** Check the config file comments and this architecture doc first!
