# SyntheticRPG Combat Demo (Godot 4.4)

Action RPG combat prototype for PC (keyboard + mouse), focused on systems depth and a short combat demo objective.

## Scope Implemented
- Side-scrolling beat-'em-up lane presentation
- Melee combat with:
  - Basic attack
  - Ability 1: wide cleave
  - Ability 2: lunge strike
  - Roll with invulnerability frames
  - Directional block
- Enemy progression loop:
  - Kill enemies to gain XP and level up
  - Random item drops with persistent stat bonuses
- Enemy type:
  - Melee grunt
- External art integration:
  - Player sprite from Elthen's Fishfolk Knight sheet
  - Enemy sprite from Dwarf sheet
- Win condition:
  - Defeat all enemies in the arena

## Controls
- `WASD`: Move
- `J`: Basic attack
- `K`: Ability 1 (Cleave)
- `L`: Ability 2 (Lunge)
- `I`: Block
- `Space`: Roll (i-frames)

## Project Layout
- `scenes/`: Godot scenes
- `scripts/`: gameplay systems and scene logic
  - `scripts/player/`: player combat + progression
  - `scripts/enemies/`: AI and boss behavior
  - `scripts/arena/`: spawn flow, objective, loot/xp routing
  - `scripts/ui/`: HUD and objective feedback
  - `scripts/systems/`: shared support systems

## Demo Flow
1. Player spawns in arena.
2. Regular enemies spawn and pursue/attack.
3. Defeat all enemies to complete the demo.
