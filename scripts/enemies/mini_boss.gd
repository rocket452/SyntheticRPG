extends EnemyBase
class_name MiniBoss

@export var shockwave_cooldown: float = 5.5
@export var shockwave_telegraph: float = 0.55
@export var shockwave_range: float = 150.0
@export var shockwave_damage: float = 26.0

var shockwave_cooldown_left: float = 2.6
var charging_shockwave: bool = false
var shockwave_telegraph_left: float = 0.0
var shockwave_flash_left: float = 0.0
var charge_anim_time: float = 0.0

var chest_core_base_color: Color = Color(1, 1, 1, 1)
var chest_core_base_scale: Vector2 = Vector2.ONE
var torso_crack_a_base_color: Color = Color(1, 1, 1, 1)
var torso_crack_b_base_color: Color = Color(1, 1, 1, 1)
var crest_base_position: Vector2 = Vector2.ZERO
var crest_base_rotation: float = 0.0
var warcloth_front_base_position: Vector2 = Vector2.ZERO
var warcloth_back_base_position: Vector2 = Vector2.ZERO
var warcloth_front_base_rotation: float = 0.0
var warcloth_back_base_rotation: float = 0.0
var shockwave_fill_base_color: Color = Color(1, 1, 1, 1)

@onready var shockwave_telegraph_line: Line2D = $ShockwaveTelegraph
@onready var shockwave_fill: Polygon2D = $ShockwaveFill
@onready var chest_core_visual: Polygon2D = $Body/ChestCore
@onready var torso_crack_a_visual: Polygon2D = $Body/TorsoCrackA
@onready var torso_crack_b_visual: Polygon2D = $Body/TorsoCrackB
@onready var crest_visual: Polygon2D = $Body/Crest
@onready var warcloth_front_visual: Polygon2D = $Body/WarclothFront
@onready var warcloth_back_visual: Polygon2D = $Body/WarclothBack


func _ready() -> void:
	super._ready()
	shockwave_telegraph_line.visible = false
	shockwave_fill.visible = false
	chest_core_base_color = chest_core_visual.color
	chest_core_base_scale = chest_core_visual.scale
	torso_crack_a_base_color = torso_crack_a_visual.color
	torso_crack_b_base_color = torso_crack_b_visual.color
	crest_base_position = crest_visual.position
	crest_base_rotation = crest_visual.rotation
	warcloth_front_base_position = warcloth_front_visual.position
	warcloth_back_base_position = warcloth_back_visual.position
	warcloth_front_base_rotation = warcloth_front_visual.rotation
	warcloth_back_base_rotation = warcloth_back_visual.rotation
	shockwave_fill_base_color = shockwave_fill.color


func _physics_process(delta: float) -> void:
	if dead:
		return

	_update_health_bar()
	charge_anim_time += delta
	shockwave_flash_left = maxf(0.0, shockwave_flash_left - delta)

	if charging_shockwave:
		if not is_instance_valid(player):
			_reacquire_player()

		shockwave_telegraph_left -= delta
		velocity = Vector2.ZERO

		var progress := clampf(1.0 - (shockwave_telegraph_left / maxf(0.01, shockwave_telegraph)), 0.0, 1.0)
		_update_shockwave_telegraph(progress)
		_update_shockwave_fill(progress)
		_update_charge_animation(delta, progress)
		_set_model_palette(
			base_body_color.lerp(Color(0.64, 0.14, 0.12, 1.0), 0.8),
			base_head_color.lerp(Color(0.74, 0.34, 0.3, 1.0), 0.62),
			base_arm_color.lerp(Color(0.56, 0.12, 0.12, 1.0), 0.7),
			base_weapon_color.lerp(Color(0.9, 0.58, 0.32, 1.0), 0.68)
		)
		scale = scale.lerp(Vector2(1.06, 0.94), clampf(delta * 12.0, 0.0, 1.0))
		move_and_slide()
		_update_health_bar()
		if shockwave_telegraph_left <= 0.0:
			_release_shockwave()
		return

	shockwave_telegraph_line.visible = false
	shockwave_fill.visible = false
	super._physics_process(delta)
	_update_health_bar()
	if dead:
		return

	_update_idle_boss_details(delta)

	if shockwave_flash_left > 0.0:
		_set_model_palette(
			Color(0.68, 0.3, 0.2, 1.0),
			Color(0.76, 0.42, 0.3, 1.0),
			Color(0.6, 0.24, 0.18, 1.0),
			Color(0.9, 0.7, 0.46, 1.0)
		)
		scale = scale.lerp(Vector2(1.16, 0.86), clampf(delta * 14.0, 0.0, 1.0))

	shockwave_cooldown_left = maxf(0.0, shockwave_cooldown_left - delta)
	if shockwave_cooldown_left <= 0.0 and not pending_attack:
		_begin_shockwave()


func _begin_shockwave() -> void:
	charging_shockwave = true
	shockwave_telegraph_left = shockwave_telegraph
	pending_attack = false
	attack_windup_left = 0.0
	attack_prestrike_hold_left = 0.0
	attack_recovery_hold_left = 0.0
	velocity = Vector2.ZERO
	attack_telegraph.visible = false
	weapon_trail.visible = false
	weapon_trail_alpha = 0.0
	shockwave_fill.visible = true
	shockwave_fill.scale = Vector2.ONE


func _release_shockwave() -> void:
	charging_shockwave = false
	shockwave_cooldown_left = shockwave_cooldown
	shockwave_flash_left = 0.12
	_start_attack_animation(0.28, 1.75)
	_trigger_slash_effect(shockwave_range * 0.92, 320.0, Color(0.98, 0.52, 0.24, 0.92), 0.24, 7.2)
	weapon_trail_alpha = maxf(weapon_trail_alpha, 0.9)
	shockwave_telegraph_line.visible = false
	_play_shockwave_fill_burst()

	if not is_instance_valid(player):
		_reacquire_player()
	if not is_instance_valid(player):
		return

	if global_position.distance_to(player.global_position) <= shockwave_range and player.has_method("receive_hit"):
		_attempt_player_hit(player, shockwave_damage, true)


func _perform_attack() -> void:
	attack_flash_left = 0.12
	_start_attack_animation(0.24, 1.58)
	_trigger_slash_effect(attack_range + 18.0, 120.0, Color(0.96, 0.48, 0.24, 0.9), 0.2, 5.8)

	if not is_instance_valid(player):
		_reacquire_player()
	if not is_instance_valid(player):
		return

	if global_position.distance_to(player.global_position) <= attack_range + 18.0 and player.has_method("receive_hit"):
		_attempt_player_hit(player, attack_damage, false, outgoing_hit_stun_duration)


func _update_shockwave_telegraph(progress: float) -> void:
	shockwave_telegraph_line.visible = true
	var point_count := 34
	var radius := lerpf(30.0, shockwave_range, clampf(progress, 0.0, 1.0))
	var points := PackedVector2Array()
	for i in range(point_count):
		var angle := TAU * (float(i) / float(point_count))
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	shockwave_telegraph_line.points = points
	shockwave_telegraph_line.width = lerpf(2.0, 6.0, progress)
	shockwave_telegraph_line.default_color = Color(0.98, lerpf(0.48, 0.22, progress), lerpf(0.26, 0.14, progress), 0.85)


func _update_shockwave_fill(progress: float) -> void:
	shockwave_fill.visible = true
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var pulse := 0.5 + (sin((charge_anim_time * 9.6) + (clamped_progress * 4.0)) * 0.5)
	var radius := lerpf(20.0, shockwave_range, clamped_progress)
	var point_count := 42
	var points := PackedVector2Array([Vector2.ZERO])
	for i in range(point_count + 1):
		var angle := TAU * (float(i) / float(point_count))
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	shockwave_fill.polygon = points
	shockwave_fill.rotation = charge_anim_time * (0.3 + (clamped_progress * 0.25))
	var fill_color := shockwave_fill_base_color.lerp(Color(0.98, 0.34, 0.2, 1.0), 0.72)
	fill_color.a = clampf(lerpf(0.12, 0.32, clamped_progress) + (pulse * 0.04), 0.0, 1.0)
	shockwave_fill.color = fill_color


func _update_charge_animation(delta: float, progress: float) -> void:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var pulse := 0.5 + (sin((charge_anim_time * 10.2) + (clamped_progress * 3.4)) * 0.5)
	var energy := clampf(clamped_progress + (pulse * 0.24), 0.0, 1.0)
	chest_core_visual.scale = chest_core_base_scale * lerpf(1.0, 1.36, energy)
	var core_color := chest_core_base_color.lerp(Color(1.0, 0.62, 0.28, 1.0), 0.82)
	core_color.a = lerpf(chest_core_base_color.a, 1.0, energy)
	chest_core_visual.color = core_color
	var crack_a_color := torso_crack_a_base_color.lerp(Color(0.98, 0.52, 0.3, 1.0), 0.78)
	crack_a_color.a = clampf(lerpf(torso_crack_a_base_color.a, 0.92, energy), 0.0, 1.0)
	torso_crack_a_visual.color = crack_a_color
	var crack_b_color := torso_crack_b_base_color.lerp(Color(0.98, 0.52, 0.3, 1.0), 0.72)
	crack_b_color.a = clampf(lerpf(torso_crack_b_base_color.a, 0.9, energy), 0.0, 1.0)
	torso_crack_b_visual.color = crack_b_color
	crest_visual.position = crest_base_position + Vector2(0.0, -lerpf(0.0, 2.6, clamped_progress) - (pulse * 0.8))
	crest_visual.rotation = crest_base_rotation + (sin(charge_anim_time * 3.8) * 0.06)
	warcloth_back_visual.position = warcloth_back_base_position + Vector2(0.0, lerpf(0.0, 3.2, clamped_progress) + (pulse * 1.4))
	warcloth_front_visual.position = warcloth_front_base_position + Vector2(0.0, lerpf(0.0, 1.9, clamped_progress) + (pulse * 0.9))
	warcloth_back_visual.rotation = warcloth_back_base_rotation - (clamped_progress * 0.18) - (pulse * 0.05)
	warcloth_front_visual.rotation = warcloth_front_base_rotation + (clamped_progress * 0.12) + (pulse * 0.05)
	var chest_rotation_target := (sin(charge_anim_time * 4.6) * 0.03) + (clamped_progress * 0.04)
	body_visual.rotation = lerp_angle(body_visual.rotation, chest_rotation_target, clampf(delta * 7.0, 0.0, 1.0))


func _update_idle_boss_details(delta: float) -> void:
	var idle_pulse := 0.5 + (sin(anim_time * 2.6) * 0.5)
	var target_scale := chest_core_base_scale * lerpf(0.98, 1.1, idle_pulse)
	chest_core_visual.scale = chest_core_visual.scale.lerp(target_scale, clampf(delta * 8.0, 0.0, 1.0))
	var core_color := chest_core_base_color.lerp(Color(0.9, 0.5, 0.26, 1.0), 0.42)
	core_color.a = chest_core_base_color.a
	chest_core_visual.color = core_color
	var crack_a_color := torso_crack_a_base_color
	crack_a_color.a = clampf(torso_crack_a_base_color.a + (idle_pulse * 0.05), 0.0, 1.0)
	torso_crack_a_visual.color = crack_a_color
	var crack_b_color := torso_crack_b_base_color
	crack_b_color.a = clampf(torso_crack_b_base_color.a + (idle_pulse * 0.05), 0.0, 1.0)
	torso_crack_b_visual.color = crack_b_color
	crest_visual.position = crest_base_position + Vector2(0.0, sin(anim_time * 1.8) * 0.7)
	crest_visual.rotation = lerp_angle(crest_visual.rotation, crest_base_rotation + (sin(anim_time * 1.6) * 0.03), clampf(delta * 7.0, 0.0, 1.0))
	warcloth_back_visual.position = warcloth_back_base_position + Vector2(0.0, sin(anim_time * 3.0) * 0.9)
	warcloth_front_visual.position = warcloth_front_base_position + Vector2(0.0, sin(anim_time * 3.0 + 0.4) * 0.5)
	warcloth_back_visual.rotation = lerp_angle(warcloth_back_visual.rotation, warcloth_back_base_rotation - (sin(anim_time * 2.4) * 0.04), clampf(delta * 8.0, 0.0, 1.0))
	warcloth_front_visual.rotation = lerp_angle(warcloth_front_visual.rotation, warcloth_front_base_rotation + (sin(anim_time * 2.4 + 0.4) * 0.03), clampf(delta * 8.0, 0.0, 1.0))


func _play_shockwave_fill_burst() -> void:
	shockwave_fill.visible = true
	shockwave_fill.scale = Vector2.ONE * 0.72
	var burst_color := Color(0.98, 0.38, 0.2, 0.38)
	shockwave_fill.color = burst_color
	var burst_tween: Tween = create_tween()
	burst_tween.tween_property(shockwave_fill, "scale", Vector2.ONE * 1.55, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	burst_tween.parallel().tween_property(shockwave_fill, "color:a", 0.0, 0.16)
	burst_tween.finished.connect(func() -> void:
		shockwave_fill.visible = false
		shockwave_fill.scale = Vector2.ONE
		shockwave_fill.color = shockwave_fill_base_color
	)
