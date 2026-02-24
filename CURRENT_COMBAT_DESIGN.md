# CURRENT COMBAT DESIGN

## Scope
This is a documentation-only snapshot of the combat implementation currently in the repository.

## Source Of Truth Files
- `scenes/main/Main.tscn`
- `scripts/main/main.gd`
- `scenes/world/Arena.tscn`
- `scripts/arena/arena.gd`
- `scenes/player/Player.tscn`
- `scripts/player/player.gd`
- `scenes/enemies/MeleeEnemy.tscn`
- `scripts/enemies/enemy_base.gd`
- `scenes/enemies/MiniBoss.tscn`
- `scripts/enemies/mini_boss.gd`
- `scenes/npcs/FriendlyHealer.tscn`
- `scripts/npcs/friendly_healer.gd`
- `scenes/npcs/FriendlyRatfolk.tscn`
- `scripts/npcs/friendly_ratfolk.gd`
- `scripts/systems/input_config.gd`
- `scripts/ui/hud.gd`

## 1. Runtime Composition
- `Main` scene (`scenes/main/Main.tscn`, `scripts/main/main.gd`) starts input mapping and calls `Arena.start_demo()`.
- `Arena` (`scenes/world/Arena.tscn`, `scripts/arena/arena.gd`) spawns:
  - Player (`scenes/player/Player.tscn`)
  - Friendly Healer (`scenes/npcs/FriendlyHealer.tscn`)
  - Friendly Ratfolk (`scenes/npcs/FriendlyRatfolk.tscn`)
  - Regular enemies using `scenes/enemies/MeleeEnemy.tscn`
- Default enemy count is `regular_enemy_count = 1` in `scripts/arena/arena.gd`.
- Hotkey `8` in `scripts/main/main.gd` spawns an additional minotaur on alternating arena edges via `Arena.spawn_debug_minotaur_alternating()`.

## 2. Input And Control Model
- Input bindings are configured in `scripts/systems/input_config.gd`.
- Current bindings:
  - `W A S D` -> movement
  - `J` -> `basic_attack`
  - `K` -> `ability_1`
  - `L` -> `ability_2`
  - `SPACE` -> `roll`
  - `I` -> `block`
- Direct control is only for the Player (`scripts/player/player.gd`).
- Healer and Ratfolk are autonomous runtime actors (`scripts/npcs/friendly_healer.gd`, `scripts/npcs/friendly_ratfolk.gd`).

## 3. Player Character And Ability System
- Scene/script: `scenes/player/Player.tscn`, `scripts/player/player.gd`.
- Player is in group `"player"` (`add_to_group("player")`).
- Ability handling is centralized in `player.gd`:
  - Input gate: `_handle_actions()`
  - Timers: `_tick_timers()`, `_tick_charge_attack_state()`
  - Windup queue: `QueuedAttack` + `_queue_attack()` + `_resolve_queued_attack()`
  - Hit apply: `_queue_melee_hit_for_final_attack_frame()` + `_apply_queued_melee_hit()` + `_apply_melee_strike()`

### 3.1 Player Combat States
- Enum `CombatState` in `scripts/player/player.gd`:
  - `IDLE_MOVE`
  - `CHARGING_ATTACK`
  - `ATTACK_WINDUP`
  - `ATTACK_ACTIVE`
  - `ATTACK_RECOVERY`
  - `HITSTUN`
- `_set_combat_state()` emits autoplay logs for `WINDUP`, `ACTIVE`, `RECOVERY`.

### 3.2 Existing Player Abilities
- Basic attack (`J`):
  - Starts at `_start_basic_single_attack()`.
  - Combo progression uses `_start_basic_combo_attack()` with `BASIC_COMBO_MAX_HITS = 3`.
  - Hits are applied on the final animation frame through queued-hit logic.
  - End of full combo applies `basic_combo_end_cooldown`.

- Ability 1 / charge attack (`K`):
  - Hold starts `_start_charge_attack()` and enters `CHARGING_ATTACK`.
  - If released before `min_charge_time`, it falls back to `_begin_basic_combo_sequence()` (auto basic combo chain).
  - If released after min charge, heavy path runs windup -> active -> recovery.
  - Auto-release occurs at `max_charge_time`.
  - Scales damage/range/arc/knockback/hitstop/stun/vfx by charge ratio.
  - Super armor exists while charging in configured window and during charge active (`_has_super_armor()`).

- Ability 2 / ally dash (`L`):
  - `_start_ally_dash()` finds nearest valid ally in facing direction (`_find_nearest_facing_ally()`).
  - Ally candidates come from groups `"friendly_npcs"` and `"player"`.
  - Dash movement uses `lunge_time_left` and `lunge_direction`.
  - `_apply_lunge_strike()` currently gives recovery + instant-block grace; it does not directly apply strike damage.

- Roll (`SPACE`):
  - `_start_roll()` sets invulnerability for `roll_duration`.
  - Cancels queued attacks and charge state.

- Block (`I`):
  - Directional reduction in `receive_hit()` using `block_arc_degrees` and `block_damage_reduction`.
  - Block pose readiness uses `_is_block_pose_ready()`.
  - Visual is circular `BlockIndicator` (`Line2D`).
  - Shield query API:
    - `is_block_shield_active()`
    - `get_block_shield_center_global()`
    - `is_point_inside_block_shield(world_point)`

### 3.3 Movement Restrictions During Combat States
- `_apply_movement()` enforces:
  - No normal movement while charging (`is_charging_attack`) or blocking (`is_blocking`), except knockback/charge-lunge components.
  - Dedicated movement behavior during roll and ally dash.

## 4. Boss (Minotaur) Logic
- Runtime boss/minotaur scene/script:
  - `scenes/enemies/MeleeEnemy.tscn`
  - `scripts/enemies/enemy_base.gd`
- `EnemyBase` uses timer/flag state, not an enum.

### 4.1 Boss State Handling (Flag/Timer Driven)
- Core flags/timers in `scripts/enemies/enemy_base.gd`:
  - Basic attack: `pending_attack`, `attack_windup_left`, `attack_prestrike_hold_left`, `attack_recovery_hold_left`
  - Spin attack: `spin_charge_left`, `spin_active_left`, `spin_hit_tick_left`, `spin_attack_cooldown_left`
  - Spin trigger counter: `basic_attacks_since_last_spin`

### 4.2 Basic Attack Flow
- Chase player when outside range.
- If in range and cooldown ready:
  - Start pending basic attack windup.
  - Optional pre-strike hold frame uses `attack_hold_frame`.
  - `_perform_attack()` increments `basic_attacks_since_last_spin` and applies sweep hits to valid friendly targets.

### 4.3 Spin Attack Flow
- Spin starts only if all are true:
  - `spin_attack_enabled`
  - `spin_attack_cooldown_left <= 0`
  - in trigger range (`spin_trigger_range`)
  - `basic_attacks_since_last_spin >= basic_attacks_required_for_spin` (default 3)
- `_begin_spin_charge()`:
  - Resets basic attack flags/counter
  - Starts `spin_charge_left`
  - Shows warning polygon (`spin_warning_area`)
- `_begin_spin_attack()`:
  - Starts active spin timer
  - Hides warning
- `_perform_spin_attack_hit()`:
  - Tick-based AoE hits every `spin_hit_interval`
- `_finish_spin_attack()`:
  - Applies spin cooldown and short recovery hold

### 4.4 Boss Interrupt Handling
- In `receive_hit()`:
  - During spin charge (`spin_charge_left > 0`), interrupts are ignored (`ignore_interrupts`), so stun/knockback cancellation is suppressed.
  - Outside spin charge, stun can cancel current attack/spin sequence.
- If the player blocks a minotaur hit and guard break is false, minotaur may self-stun via `_apply_blocked_counter_stun()`.

### 4.5 Multi-Enemy Spacing
- Soft enemy separation is implemented in `_apply_soft_enemy_separation()` using:
  - `soft_collision_radius`
  - `soft_collision_push_speed`
  - `soft_collision_max_push_per_frame`

## 5. Minion Logic (Current)
- No separate enemy-minion archetype is auto-spawned by `Arena.start_demo()`.
- Additional enemies are still `MeleeEnemy` instances (debug key spawn).
- Friendly minion-like units exist via Ratfolk shadow clone spawning in `scripts/npcs/friendly_ratfolk.gd`.

## 6. Targeting And Aggro Rules
### 6.1 Enemy Targeting
- Aggro/movement target is player only (`_reacquire_player()` uses group `"player"`).
- Damage target list is built by `_get_attackable_friendly_targets()`:
  - Player (if `receive_hit` exists)
  - Every node in group `"friendly_npcs"` with `receive_hit`
- Both basic and spin attacks use that shared target list.

### 6.2 Healer Targeting
- Healer binds only to player (`set_player()`, `_bind_player()`).
- Heal checks target only the player (`_player_needs_healing()`, `_apply_heal()`).
- Tidal wave hit processing:
  - heals player targets intersecting the wave sweep
  - damages enemies in group `"enemies"` intersecting the sweep
- Healer movement computes a tactical follow position relative to player and nearest enemy.

### 6.3 Ratfolk Targeting
- Ratfolk chooses nearest enemy from group `"enemies"` inside `max_chase_distance_from_player` around player.
- If no valid target, ratfolk follows player with follow-distance constraints.
- Shadow clone cast requires valid target and cooldown readiness.

## 7. Damage Model
### 7.1 Player Incoming Damage
- `Player.receive_hit(...)` in `scripts/player/player.gd`:
  - Block direction and mitigation
  - Charge super-armor threshold handling
  - Stun/hurt timing
  - Knockback
  - Death when health reaches 0

### 7.2 Enemy Incoming Damage
- `EnemyBase.receive_hit(...)` in `scripts/enemies/enemy_base.gd`:
  - Health reduction
  - Hit flash/effects
  - Hurt/stun/knockback unless in spin-charge interrupt-immune window
  - Death when health reaches 0

### 7.3 Companion Incoming Damage
- `FriendlyHealer.receive_hit(...)` and `FriendlyRatfolk.receive_hit(...)`:
  - Both can take enemy damage
  - Both are damage-immune while inside player shield area (`player.is_point_inside_block_shield(global_position)`)

### 7.4 Player Outgoing Damage Behavior
- Player melee uses arc/depth/range filtering in `_query_attack_hits()`.
- On confirmed hits, player applies:
  - enemy damage and stun
  - knockback scaling
  - hitstop and camera shake
- Enemy melee tradeback can occur when `enemy.can_trade_melee_with(self)` is true.

## 8. State Machine Flow Summary
### 8.1 Player Flow (`scripts/player/player.gd`)
- `IDLE_MOVE`
  - `K` press -> `CHARGING_ATTACK`
  - `J` valid queue -> `ATTACK_WINDUP`
  - `L` valid dash -> `ATTACK_ACTIVE` (lunge)
  - hit interrupt -> `HITSTUN`
- `CHARGING_ATTACK`
  - release before min charge -> basic combo sequence
  - release/auto-release at charge threshold -> `ATTACK_WINDUP`
- `ATTACK_WINDUP` -> `ATTACK_ACTIVE` -> `ATTACK_RECOVERY` -> `IDLE_MOVE`
- `HITSTUN` clears back to `IDLE_MOVE` when stun and attack locks end.

### 8.2 Minotaur Flow (`scripts/enemies/enemy_base.gd`)
- Idle/chase player
- Basic attack pending -> windup/hold -> hit -> recovery
- After required basic count and cooldown/range gates:
  - spin charge telegraph -> spin active ticks -> recovery/cooldown
- Stun can cancel attacks except during spin-charge interrupt immunity.

### 8.3 Healer Flow (`scripts/npcs/friendly_healer.gd`)
- Tactical follow movement loop
- Healing timer and readiness checks
- Cast sequence (`is_casting`) then:
  - tidal wave if ready
  - otherwise basic heal
- Returns to movement loop

### 8.4 Ratfolk Flow (`scripts/npcs/friendly_ratfolk.gd`)
- Acquire target
- Optional shadow clone cast state
- Attack windup -> attack -> recovery
- Follow player when no target

## 9. Existing Debug/HUD Notes
- HUD reads cooldown dictionary from player via `scripts/ui/hud.gd`.
- Current player cooldown payload maps:
  - `"basic"` -> `basic_attack_cooldown_left`
  - `"ability_1"` -> `basic_attack_cooldown_left` (currently same value as basic in `_emit_cooldown_state()`)
  - `"ability_2"` -> `ability_2_cooldown_left`
  - `"roll"` -> `roll_cooldown_left`
- Enemy debug overlay exists in `scripts/enemies/enemy_base.gd` (`debug_orientation_overlay`), but no dedicated companion AI-state overlay scene currently exists.

## 10. Combat-Capable Script Present But Not Spawned By Arena
- `scenes/enemies/MiniBoss.tscn` with `scripts/enemies/mini_boss.gd` exists and extends `EnemyBase`.
- Current `Arena.start_demo()` spawns `MeleeEnemy` only, not `MiniBoss`.
