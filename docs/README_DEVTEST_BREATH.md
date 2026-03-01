Breath Mechanic Dev Test

Files
- `res://combat/boss/BreathAttack.gd`
- `res://vfx/breath/BreathVFX.gd`
- `res://ai/CompanionBreathResponse.gd`

In-Game Debug Keys
- `F6`: Force the current boss to start the breath attack immediately.
- `F7`: Cycle cacodemon breath VFX modes.
- `F9`: Toggle player auto-block for breath testing.

Breath VFX Modes
- `0`: Mode A - Torrent Split
- `1`: Mode B - Inferno Wall
- `2`: Mode C - Braided Ribbons

Expected Gameplay Rules
- Breath has `Charge -> Fire -> Cooldown`.
- During `Charge` and `Fire`, companions should prioritize moving behind the Tank.
- The safe pocket exists only while the Tank is actively blocking.
- A blocking Tank fully negates breath damage to them.
- Allies inside the safe pocket take no breath damage.
- If the Tank is not blocking, the safe pocket is invalid and companions scatter.

Autoplay Scenarios
- Block validation:
  - PowerShell:
    - `$env:AUTOPLAY_ENCOUNTER='cacodemon'; $env:AUTOPLAY_SCENARIO='cacodemon_breath_block'; .\scripts\run_capture.ps1`
  - Pass condition:
    - Tank blocks the breath and takes no damage.

- Companion stack validation:
  - PowerShell:
    - `$env:AUTOPLAY_ENCOUNTER='cacodemon'; $env:AUTOPLAY_SCENARIO='cacodemon_breath_stack'; .\scripts\run_capture.ps1`
  - Pass condition:
    - Both healer and rat enter the safe pocket during the active breath.

- Style override:
  - PowerShell:
    - `$env:CACODEMON_BREATH_STYLE='2'`
  - Valid values:
    - `0`, `1`, `2`

On-Screen Debug
- Arena combat debug now includes:
  - breath state
  - breath time remaining
  - tank blocking
  - pocket valid
  - companions safe

Manual Test Checklist
1. Start the `Cacodemon` encounter from the startup encounter popup.
2. Force breath with `F6`.
3. Confirm the charge telegraph appears before the fire starts.
4. Hold block on the Tank.
5. Confirm the flame fills the lane and visibly splits around the Tank.
6. Confirm the pocket behind the Tank shows a calmer sheltered region.
7. Confirm healer and rat move behind the Tank and briefly show the `SAFE` indicator.
8. Release block and force breath again.
9. Confirm the pocket disappears and companions stop stacking behind the Tank.

Implementation Notes
- `BreathAttack.gd` owns the gameplay state and safe-pocket geometry.
- `BreathVFX.gd` owns the telegraph, pocket overlay, and mode switching.
- `cacodemon_breath_stream.gd` is the low-level fire-torrent renderer used by `BreathVFX.gd`.
