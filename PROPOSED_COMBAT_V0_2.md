# PROPOSED COMBAT V0.2

## Scope
This document compares the current implementation to the requested target direction.
No gameplay code is changed by this document.

## Requested Target Direction
- Player directly controls only the Tank.
- Healer and DPS are AI-controlled companions.
- Healer has no cleanse mechanic.
- DPS identity is Shadow Clone Assault (instead of burst-centric behavior).
- Boss loop is a single-phase Minotaur pattern.
- Add CombatTest debug overlay showing companion AI state and current target.
- AI should support Tank interception gameplay and avoid stealing spotlight.

## Current Baseline (Reference)
- Tank runtime: `scenes/player/Player.tscn`, `scripts/player/player.gd`
- Healer runtime: `scenes/npcs/FriendlyHealer.tscn`, `scripts/npcs/friendly_healer.gd`
- DPS runtime: `scenes/npcs/FriendlyRatfolk.tscn`, `scripts/npcs/friendly_ratfolk.gd`
- Boss runtime: `scenes/enemies/MeleeEnemy.tscn`, `scripts/enemies/enemy_base.gd`
- Spawning/orchestration: `scenes/world/Arena.tscn`, `scripts/arena/arena.gd`
- Bootstrap/input/debug spawn key: `scenes/main/Main.tscn`, `scripts/main/main.gd`
- Current HUD: `scenes/ui/HUD.tscn`, `scripts/ui/hud.gd`

---

## 1. Tank (Guardian Dash Intercept Model)

### KEEP
- Direct player-control architecture in `scripts/player/player.gd`.
- Existing defensive block framework:
  - directional mitigation in `receive_hit()`
  - circular shield area via `is_point_inside_block_shield()`.
- Existing ally-dash base plumbing:
  - `_start_ally_dash()`
  - `_find_nearest_facing_ally()`
  - instant block grace handling.
- Existing combat state framework (`CombatState` enum and timers).

### MODIFY
- `ability_2` selection logic in `scripts/player/player.gd`:
  - current: nearest facing ally dash.
  - desired: Guardian Dash intercept selection based on ally-threat interception.
- Tank priority feel:
  - shift from mobility utility toward interception/peel decision quality.
- Dash outcome feedback:
  - make successful interception clearly legible in combat flow.

### REMOVE
- Remove expectation that dash is primarily an offensive strike action.

### CREATE
- Interception target evaluator (ally + threat trajectory aware).
- Explicit intercept result hooks (design event points for VFX/SFX/UI response).

---

## 2. Healer (AI Companion, No Cleanse)

### KEEP
- Healer companion role in `scripts/npcs/friendly_healer.gd`.
- Existing no-cleanse toolkit (already aligned).
- Existing heal + tidal-wave support concept.
- Existing interaction with Tank shield protection area.

### MODIFY
- Movement/control model in `scripts/npcs/friendly_healer.gd`:
  - current: pseudo-human stochastic steering (`rng`, input decision timers/noise/quantization).
  - desired: deterministic, priority-based AI state decisions.
- Tactical priorities:
  - maintain support spacing around Tank,
  - avoid frontline over-commitment,
  - avoid drawing aggro focus away from Tank.
- Ability usage policy:
  - deterministic priority ordering and cooldown governance.

### REMOVE
- Remove randomness-driven behavior as the primary controller in healer combat movement/decision making.

### CREATE
- `HealerAI` deterministic state model (example states):
  - `HEALING`
  - `SHIELDING`
  - `REPOSITIONING`
  - `IDLE_SUPPORT`
- Companion debug outputs for `current_state` and `current_target` suitable for CombatTest overlay.

---

## 3. DPS (AI Companion, Shadow Clone Assault)

### KEEP
- Ratfolk companion base in `scripts/npcs/friendly_ratfolk.gd`.
- Existing melee + shadow clone cast/spawn framework.
- Existing enemy-target acquisition constraints relative to player position.

### MODIFY
- DPS identity emphasis:
  - current: mixed melee pressure plus periodic clone cast.
  - desired: Shadow Clone Assault as the primary identity and decision anchor.
- Control style:
  - move to deterministic priority-based `DPSAI` behavior.
- Team behavior:
  - ensure DPS supports Tank-led engagement timing and does not dominate encounter pacing.

### REMOVE
- Remove burst-centric framing for DPS role progression in this design track.

### CREATE
- `DPSAI` deterministic state model (example states):
  - `ATTACKING`
  - `ASSAULT_CAST`
  - `REPOSITIONING`
  - `FOLLOWING`
- Clone assault policy tied to Tank engagement windows.

---

## 4. Boss (Single-Phase Minotaur Loop)

### KEEP
- Existing minotaur shell in `scripts/enemies/enemy_base.gd`:
  - basic attacks
  - telegraphed spin attack
  - cooldown/timer-gated attack cadence.
- Existing telegraph and hit-query infrastructure.

### MODIFY
- Current timer/flag behavior should be formalized into an explicit single-phase contract:
  - deterministic loop order
  - explicit transition conditions
  - clear counterplay windows for Tank interception and companion support.
- Keep spin trigger cadence readable and deliberate.

### SINGLE-PHASE LOOP CONTRACT (CONCRETE, AUTHORITATIVE)
- Required sequence:
  - `MARK -> WINDUP -> LUNGE -> (VULNERABLE on intercept/miss OR SHORT_RECOVERY on hit) -> SUMMON_CHECK -> IDLE_TRACK`
- Default timing targets (V0.2 baseline):
  - `MARK_DURATION`: `0.70s`
  - `WINDUP_DURATION`: `0.45s`
  - `LUNGE_DURATION`: `0.32s`
  - `SHORT_RECOVERY_ON_LUNGE_HIT`: `0.35s`
  - `VULNERABLE_DURATION_ON_INTERCEPT_OR_MISS`: `1.00s`
  - `SUMMON_STAGE_DURATION`: `0.55s`
  - `SUMMON_CADENCE`: every `3` completed lunge cycles
  - `SUMMON_COUNT_PER_CADENCE`: `2` minotaur minions (one per side lane)
- Stage behavior contract:
  - `MARK`:
    - boss selects one ally target from valid friendlies and publishes it as `marked_ally`.
    - mark telegraph must track the selected ally for the stage duration.
  - `WINDUP`:
    - boss rotates toward marked ally threat line.
    - at windup end, lunge direction is committed and locked.
  - `LUNGE`:
    - boss moves along committed vector only (no retarget turn during lunge).
    - all lunge hit checks happen only in this stage.
  - `VULNERABLE`:
    - entered when lunge is intercepted by Guardian Dash or lunge misses valid friendly targets.
    - boss cannot start a new mark/windup while vulnerable.
  - `SHORT_RECOVERY`:
    - entered when lunge lands successfully and was not intercepted.
  - `SUMMON_CHECK`:
    - after each completed lunge cycle, increment cycle counter.
    - if counter reaches cadence threshold, enter `SUMMON` and spawn minions, then reset counter.
    - otherwise return directly to `IDLE_TRACK`.
- Transition guard contract:
  - `MARK -> WINDUP`: mark timer elapsed and `marked_ally` still valid; else reacquire once, then fallback to `IDLE_TRACK`.
  - `WINDUP -> LUNGE`: windup timer elapsed.
  - `LUNGE -> VULNERABLE`: intercept event OR no lunge hit landed by lunge end.
  - `LUNGE -> SHORT_RECOVERY`: lunge hit landed and not intercepted.
  - `SHORT_RECOVERY/VULNERABLE -> SUMMON_CHECK`: stage timer elapsed.
  - `SUMMON -> IDLE_TRACK`: summon stage timer elapsed.

### REMOVE
- Remove ambiguous state branching that obscures the intended one-phase boss loop semantics.

### CREATE
- Single-phase minotaur behavior spec with named loop stages and transition guards.

---

## 5. System-Wide AI + Debug Requirements

### KEEP
- Existing scene orchestration and signal flow in:
  - `scripts/main/main.gd`
  - `scripts/arena/arena.gd`
  - `scripts/ui/hud.gd`

### MODIFY
- Companion runtime logic should be deterministic priority AI for both healer and DPS.
- Ensure companion decisions reinforce Tank interception gameplay.

### DETERMINISTIC AI PRIORITY CONTRACTS

#### HealerAI
- State set:
  - `HEALING`
  - `SHIELDING`
  - `WAVE_CAST`
  - `REPOSITIONING`
  - `IDLE_SUPPORT`
- Decision cadence:
  - evaluate priorities every `0.10s` (fixed tick).
  - no stochastic input noise or random side flips.
- Priority order (highest to lowest):
  1. `HEALING`:
     Tank HP below threshold and basic heal available.
  2. `SHIELDING`:
     Tank is blocking and healer is outside shield-protected radius but can step in safely.
  3. `WAVE_CAST`:
     tidal wave cooldown ready and at least one enemy is in forward lane corridor.
  4. `REPOSITIONING`:
     healer outside support distance band or currently in front of Tank relative to nearest threat.
  5. `IDLE_SUPPORT`:
     maintain lane and light follow behavior.
- Distance rules:
  - target follow distance behind Tank: `110-165`.
  - hard minimum distance to Tank: `>= 32`.
  - never idle in front of Tank on enemy side unless forced by bounds.
  - cast movement may continue but with reduced speed cap.
- Deterministic target and tie-break rules:
  - nearest enemy by squared distance to Tank (then lower instance id on ties).
  - no random tie resolution.

#### DPSAI
- State set:
  - `FOLLOWING`
  - `ATTACKING`
  - `ASSAULT_CAST`
  - `REPOSITIONING`
- Decision cadence:
  - evaluate priorities every `0.10s` (fixed tick).
- Priority order (highest to lowest):
  1. `ASSAULT_CAST`:
     clone assault cooldown ready, valid enemy target exists, and Tank is engaged in the same lane.
  2. `ATTACKING`:
     target in melee envelope and depth tolerance.
  3. `REPOSITIONING`:
     out of safe lane window, clipped in front of Tank, or too far from support leash.
  4. `FOLLOWING`:
     default trail behavior.
- Distance rules:
  - maintain behind/side offset from Tank: `90-150`.
  - do not chase enemies beyond `max_chase_distance_from_player`.
  - collapse to follow state when no valid target.
- Determinism rules:
  - fixed update cadence and deterministic target tie-breaks.
  - clone cast point always uses current DPS world position at cast completion.

### REMOVE
- Remove companion behavior that steals encounter spotlight from the Tank (over-aggressive autonomous dominance).

### CREATE
- CombatTest debug overlay showing for each companion:
  - AI current state (for example `HEALING`, `SHIELDING`, `ATTACKING`, `REPOSITIONING`)
  - AI current target (node/name or null)
- Deterministic AI instrumentation points to support reproducible debugging.
- Boss overlay fields:
  - marked ally
  - boss loop stage (`Idle`, `Windup`, `Lunge`, `Vulnerable`, `Summon`)
  - vulnerable timer remaining.

## 6. Shadow Clone Assault Constraints

### KEEP
- Clone visuals and temporary combat entities remain part of DPS identity.

### MODIFY
- Clone behavior must reinforce assault windows without owning encounter aggro.

### REMOVE
- Remove clone influence on boss aggro/mark target selection.
- Remove clone inclusion from friendly-protected target pools used for boss targeting.

### CREATE
- Explicit filtering rule in boss targeting/mark logic:
  - shadow clones are ignored for aggro/mark candidate selection.
- Explicit companion grouping rule:
  - clones do not join the same friendly target group used by boss targeting.
  - clones must not be added to `friendly_npcs`; use a dedicated group such as `shadow_clones`.
  - all boss friendly-target queries must ignore `is_shadow_clone == true`.

---

## 7. Implementation Note
- This file defines the target contract for V0.2 and is intentionally design-focused.
- Runtime implementation status should be verified in code/tests, not inferred from this section.
