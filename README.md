# Roblox Tower Defense Game

A complete, feature-rich core for a Tower Defense game in Roblox Studio. This project includes enemy waves, an economy system, dynamic tower placement with range visualization, and a robust combat system.

## 🚀 Key Features

*   **Wave System:** Automated wave spawning with increasing difficulty and inter-wave countdowns.
*   **Dynamic Tower Placement:** Client-server placement system with a "Ghost" preview and real-time range rings.
*   **Combat Mechanics:** Towers automatically target the closest enemy, featuring a unique "Tall Pole" punch animation with neon impact effects.
*   **Economy & Base Health:** Integrated currency system (earning cash on kills) and global base health with dynamic UI updates.
*   **Map Management:** Automated cleanup process that clears towers and leftover enemies on Game Over.

## 📁 Project Structure

| File | Location in Studio | Description |
| :--- | :--- | :--- |
| `GameManager.lua` | `ServerScriptService` | The master controller for game state, waves, and health. |
| `TowerPunchServer.lua` | Inside `BasicTower` Model | Handles targeting, punch animations, and damage logic. |
| `TowerPlacementServer.lua` | `ServerScriptService` | Manages server-side spawning and cash deduction. |
| `EnemyMovement.lua` | Inside `Alien` Model | Multi-waypoint pathfinding logic for enemies. |
| `TowerPlacementClient.lua` | `StarterPlayerScripts` | Handles player input and placement previews. |
| `CashDisplayClient.lua` | `StarterPlayerScripts` | Manages the Cash and Base Health UI. |

## 🛠 Setup Instructions

### 1. Environment Setup
- Create a folder in `Workspace` named **Waypoints** and place parts named `1`, `2`, `3`, etc., in order.
- Create a folder in `ReplicatedStorage` named **Enemies** and place your enemy model (named `Alien`) inside.
- Create a folder in `ReplicatedStorage` named **Towers** for your tower models.

### 2. Building the Tower
Run the following script in the Roblox Studio **Command Bar** to generate the "Tall Pole" tower:

```lua
local model = Instance.new("Model")
model.Name = "BasicTower"
model.Parent = game.ReplicatedStorage.Towers
-- (See 'create asset' file for full construction script)
```

### 3. Remote Events & Functions
Ensure the following are created in `ReplicatedStorage`:
- `RemoteEvent` named **UpdateBaseHealth**
- `RemoteEvent` named **PlaceTowerEvent**
- `RemoteFunction` named **GetInitialHealth**

## 🤺 How it Works
- **Enemies:** Spawn at Waypoint 1 and move toward the end. If they reach the end, they call `_G.DamageBase`.
- **Towers:** Place towers using the ghost preview. Towers stand tall and punch any enemies within their 35-stud range.
- **Victory/Defeat:** Kill enemies to earn cash for more towers. If the base health hits 0, the map resets for a new round.

---
*Created with 💙 for the Roblox Developer Community.*
