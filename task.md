# RobloxJ Game Understanding

## Current State
The game is a Tower Defense game with a Lobby and a Combat map. 
- **Lobby Phase**: Players can roll for towers, manage their storage, and vote for a level.
- **Combat Phase**: Players place towers to defend against waves of Aliens.

## Towers
1. **BasicTower** (100 Cash): Slow, single target.
2. **FastNoob** (100 Cash): High speed, low damage.
3. **StrongNoob** (200 Cash): Slow speed, high damage.
4. **ALL OUT NOOB** (300 Cash): AoE (Area of Effect) attacks.
5. **TRIPLE PUNCH NOOB** (400 Cash): Hits up to 3 enemies.
6. **SUPPORTER NOOB** (400 Cash): Buffs nearby towers (+10 damage).
7. **FIRE NOOB** (600 Cash): Combo attack (AoE then Single).
8. **WATER NOOB** (700 Cash): AoE damage + Stun puddles (5s).
9. **SUMO NOOB** (800 Cash): Very high damage (100), slow speed.

## Recent Changes
- **Modular Attack Routines**: Extracted logic from `TowerPunchServer.lua` into `AttackRoutine_*.lua` scripts for each tower.
- **Tower Storage System**: 
  - Active bar reverted to 5 slots.
  - Global collection (`globalTowers`) stores all owned units.
  - Storage UI for swapping units.
- **Enemy Movement Fix**: Enemies now use `HumanoidRootPart` instead of `PrimaryPart` to avoid navigation hangs.
- **Lobby Phase Fix**: Improved spawn reliability while keeping original elevator flow (`MAX_PLAYERS = 3`, no mandatory delay).

## To-Do / Issues
- [x] Fix Lobby Spawn skip (Game starts immediately).
- [ ] Implement Save/Load for Tower Storage.
- [ ] Add more Maps/Levels.
- [ ] Balance Sumo and Water Noob stats.
