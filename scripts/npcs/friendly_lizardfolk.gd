extends FriendlyRatfolk
class_name FriendlyLizardfolk

const LIZARDFOLK_SHEET_PATH: String = "res://assets/external/ElthenAssets/lizardfolk/Lizardfolk Archer Sprite Sheet.png"
const LIZARDFOLK_SCENE_PATH: String = "res://scenes/npcs/FriendlyLizardfolk.tscn"
const LIZARD_ARROW_PROJECTILE_SCENE_PATH: String = "res://scenes/projectiles/LizardArrowProjectile.tscn"
const LIZARD_ARROW_PROJECTILE_SCRIPT := preload("res://scripts/projectiles/lizard_arrow_projectile.gd")
const LIZARDFOLK_HFRAMES: int = 8
const LIZARDFOLK_VFRAMES: int = 6

const LIZARD_ANIM_ROWS: Dictionary = {
	"idle": 0,
	"run": 1,
	"attack": 3,
	"hurt": 4,
	"death": 5
}

const LIZARD_ANIM_FRAME_COLUMNS: Dictionary = {
	"idle": [0, 1, 2, 3],
	"run": [0, 1, 2, 3, 4, 5, 6, 7],
	"attack": [0, 1, 2, 3, 4, 5],
	"hurt": [0, 1, 2, 3],
	"death": [0, 1, 2, 3, 4, 5]
}

const LIZARD_ANIM_FPS: Dictionary = {
	"idle": 7.0,
	"run": 9.2,
	"attack": 10.4,
	"hurt": 11.5,
	"death": 8.0
}
const LIZARDFOLK_ITEM_PRICE: int = 15
const LIZARDFOLK_WEAPON_DEFINITIONS: Dictionary = {
	"boghunter_longbow": {
		"id": "boghunter_longbow",
		"name": "Boghunter Longbow",
		"icon": "BOW",
		"description": "Basic shot damage +16% and projectile speed +18%.",
		"attack_damage_multiplier": 1.16,
		"arrow_projectile_speed_multiplier": 1.18
	},
	"stormcall_recurve": {
		"id": "stormcall_recurve",
		"name": "Stormcall Recurve",
		"icon": "BOW",
		"description": "Shot cooldown -14% and range +12%.",
		"attack_cooldown_multiplier": 0.86,
		"attack_range_multiplier": 1.12
	},
	"sunspine_warbow": {
		"id": "sunspine_warbow",
		"name": "Sunspine Warbow",
		"icon": "BOW",
		"description": "Flurry damage +24% and flurry range +18%.",
		"flurry_arrow_damage_multiplier": 1.24,
		"flurry_trigger_range_multiplier": 1.18
	}
}
const LIZARDFOLK_TRINKET_DEFINITIONS: Dictionary = {
	"embercoil_talisman": {
		"id": "embercoil_talisman",
		"name": "Embercoil Talisman",
		"icon": "TRK",
		"description": "Special gain +30% and Flurry cooldown -12%.",
		"special_gain_multiplier": 1.3,
		"flurry_cooldown_multiplier": 0.88
	},
	"scaleguard_idol": {
		"id": "scaleguard_idol",
		"name": "Scaleguard Idol",
		"icon": "TRK",
		"description": "Max health +20% and damage taken -12%.",
		"max_health_multiplier": 1.2,
		"damage_taken_multiplier": 0.88
	},
	"hawk_eye_fetish": {
		"id": "hawk_eye_fetish",
		"name": "Hawk-Eye Fetish",
		"icon": "TRK",
		"description": "Arrow range +18% and Flurry lasts 20% longer.",
		"arrow_projectile_max_distance_multiplier": 1.18,
		"flurry_duration_multiplier": 1.2
	}
}
const LIZARDFOLK_BOOT_DEFINITIONS: Dictionary = {
	"brushrunner_boots": {
		"id": "brushrunner_boots",
		"name": "Brushrunner Boots",
		"icon": "BTS",
		"description": "Movement speed +15%.",
		"move_speed_multiplier": 1.15
	},
	"reedshadow_boots": {
		"id": "reedshadow_boots",
		"name": "Reedshadow Boots",
		"icon": "BTS",
		"description": "Roll cooldown -30% and roll speed +18%.",
		"roll_cooldown_multiplier": 0.7,
		"roll_speed_multiplier": 1.18
	},
	"quickdraw_greaves": {
		"id": "quickdraw_greaves",
		"name": "Quickdraw Greaves",
		"icon": "BTS",
		"description": "Shot windup -16% and Flurry windup -22%.",
		"attack_windup_multiplier": 0.84,
		"flurry_windup_multiplier": 0.78
	}
}
const LIZARDFOLK_WEAPON_ORDER: Array[String] = [
	"boghunter_longbow",
	"stormcall_recurve",
	"sunspine_warbow"
]
const LIZARDFOLK_TRINKET_ORDER: Array[String] = [
	"embercoil_talisman",
	"scaleguard_idol",
	"hawk_eye_fetish"
]
const LIZARDFOLK_BOOT_ORDER: Array[String] = [
	"brushrunner_boots",
	"reedshadow_boots",
	"quickdraw_greaves"
]
const LIZARDFOLK_STORE_ITEM_ORDER: Array[String] = [
	"boghunter_longbow",
	"stormcall_recurve",
	"sunspine_warbow",
	"embercoil_talisman",
	"scaleguard_idol",
	"hawk_eye_fetish",
	"brushrunner_boots",
	"reedshadow_boots",
	"quickdraw_greaves"
]

var lizardfolk_sheet_texture: Texture2D = null
var lizardfolk_scene_cache: PackedScene = null
var lizard_arrow_projectile_scene_cache: PackedScene = null

@export var arrow_projectile_speed: float = 560.0
@export var arrow_projectile_max_distance: float = 700.0
@export var arrow_spawn_forward_offset: float = 22.0
@export var arrow_spawn_vertical_offset: float = -21.0
@export var arrow_impact_hitstop: float = 0.04
@export var flurry_enabled: bool = true
@export var flurry_cooldown: float = 8.0
@export var flurry_windup: float = 0.34
@export var flurry_duration: float = 1.05
@export var flurry_shot_interval: float = 0.16
@export var flurry_min_targets: int = 1
@export var flurry_max_targets_per_volley: int = 3
@export var flurry_trigger_range: float = 560.0
@export var flurry_arrow_damage_scale: float = 0.65
@export var flurry_arrow_speed_scale: float = 1.12
@export var flurry_aim_spread_degrees: float = 3.5
@export_range(0.0, 1.0, 0.01) var flurry_opening_cooldown_ratio: float = 0.45
@export var behind_tank_distance: float = 148.0
@export var behind_tank_depth_offset: float = 18.0
@export var engage_distance_from_player: float = 260.0
@export var disengage_distance_from_player: float = 340.0
@export var tank_guard_hold_radius: float = 20.0
@export_range(-0.25, 0.95, 0.01) var tank_guard_alignment_threshold: float = 0.35
@export var tank_guard_max_distance: float = 228.0

var flurry_cooldown_left: float = 0.0
var flurry_windup_left: float = 0.0
var flurry_active_left: float = 0.0
var flurry_shot_left: float = 0.0
var flurry_sequence_active: bool = false
var flurry_has_started_firing: bool = false
var lizard_combat_engaged: bool = false
var base_arrow_projectile_speed: float = 0.0
var base_arrow_projectile_max_distance: float = 0.0
var base_attack_windup: float = 0.0
var base_attack_cooldown: float = 0.0
var base_flurry_cooldown: float = 0.0
var base_flurry_windup: float = 0.0
var base_flurry_duration: float = 0.0
var base_flurry_shot_interval: float = 0.0
var base_flurry_trigger_range: float = 0.0
var base_flurry_arrow_damage_scale: float = 0.0


func _ready() -> void:
	# Keep this ally focused as a straightforward ranged striker (no clone branching).
	shadow_clone_enabled = false
	shadow_fear_enabled = false
	backstab_dash_enabled = false
	attack_range = 430.0
	attack_depth_tolerance = 122.0
	preferred_attack_spacing = 336.0
	preferred_attack_spacing_tolerance = 24.0
	follow_player_distance = 236.0
	follow_player_min_distance = 132.0
	max_chase_distance_from_player = 720.0
	attack_windup = 0.48
	attack_recovery = 0.16
	attack_cooldown = 1.08
	attack_impact_vfx_scale = 1.0
	outgoing_hit_stun_duration = 0.2
	attack_knockback_scale = 0.72
	move_speed *= 0.7
	super._ready()
	flurry_cooldown_left = maxf(0.0, flurry_cooldown * clampf(flurry_opening_cooldown_ratio, 0.0, 1.0))
	flurry_windup_left = 0.0
	flurry_active_left = 0.0
	flurry_shot_left = 0.0
	flurry_sequence_active = false
	flurry_has_started_firing = false


func _uses_combo_points() -> bool:
	return false


func get_manual_control_cooldown_state() -> Dictionary:
	return {
		"ability_layout": "lizardfolk",
		"basic": attack_cooldown_left,
		"basic_unlocked": true,
		"ability_1": 0.0,
		"ability_1_unlocked": false,
		"counter": 0.0,
		"counter_unlocked": false,
		"ability_2": flurry_cooldown_left,
		"ability_2_unlocked": _can_start_manual_flurry(),
		"roll": manual_roll_cooldown_left,
		"roll_unlocked": not is_shadow_clone,
		"block_cooldown_left": 0.0,
		"block_unlocked": false,
		"special_meter_ratio": _get_special_meter_ratio()
	}


func get_available_sword_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for weapon_id in available_weapon_ids:
		if not LIZARDFOLK_WEAPON_DEFINITIONS.has(weapon_id):
			continue
		var weapon_data_variant: Variant = LIZARDFOLK_WEAPON_DEFINITIONS[weapon_id]
		if weapon_data_variant is Dictionary:
			entries.append((weapon_data_variant as Dictionary).duplicate(true))
	return entries


func get_equipped_sword_name() -> String:
	if equipped_weapon_id.is_empty():
		return "No Bow"
	if not LIZARDFOLK_WEAPON_DEFINITIONS.has(equipped_weapon_id):
		return equipped_weapon_id
	var weapon_data_variant: Variant = LIZARDFOLK_WEAPON_DEFINITIONS[equipped_weapon_id]
	if weapon_data_variant is Dictionary:
		return String((weapon_data_variant as Dictionary).get("name", equipped_weapon_id))
	return equipped_weapon_id


func equip_sword(sword_id: String) -> bool:
	var weapon_id := sword_id.strip_edges().to_lower()
	if weapon_id.is_empty():
		return false
	if available_weapon_ids.find(weapon_id) == -1:
		return false
	if equipped_weapon_id == weapon_id:
		return false
	equipped_weapon_id = weapon_id
	_refresh_equipment_stats()
	return true


func get_available_shield_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for trinket_id in available_trinket_ids:
		if not LIZARDFOLK_TRINKET_DEFINITIONS.has(trinket_id):
			continue
		var trinket_data_variant: Variant = LIZARDFOLK_TRINKET_DEFINITIONS[trinket_id]
		if trinket_data_variant is Dictionary:
			entries.append((trinket_data_variant as Dictionary).duplicate(true))
	return entries


func get_equipped_shield_name() -> String:
	if equipped_trinket_id.is_empty():
		return "No Trinket"
	if not LIZARDFOLK_TRINKET_DEFINITIONS.has(equipped_trinket_id):
		return equipped_trinket_id
	var trinket_data_variant: Variant = LIZARDFOLK_TRINKET_DEFINITIONS[equipped_trinket_id]
	if trinket_data_variant is Dictionary:
		return String((trinket_data_variant as Dictionary).get("name", equipped_trinket_id))
	return equipped_trinket_id


func equip_shield(shield_id: String) -> bool:
	var trinket_id := shield_id.strip_edges().to_lower()
	if trinket_id.is_empty():
		return false
	if available_trinket_ids.find(trinket_id) == -1:
		return false
	if equipped_trinket_id == trinket_id:
		return false
	equipped_trinket_id = trinket_id
	_refresh_equipment_stats()
	return true


func get_equipped_boot_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for boot_id in available_boot_ids:
		if not LIZARDFOLK_BOOT_DEFINITIONS.has(boot_id):
			continue
		var boot_data_variant: Variant = LIZARDFOLK_BOOT_DEFINITIONS[boot_id]
		if not (boot_data_variant is Dictionary):
			continue
		var boot_data := (boot_data_variant as Dictionary).duplicate(true)
		boot_data["equipped"] = true
		entries.append(boot_data)
	return entries


func get_store_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for item_id_variant in LIZARDFOLK_STORE_ITEM_ORDER:
		var item_id := String(item_id_variant).strip_edges().to_lower()
		if item_id.is_empty():
			continue
		var item_data := _get_lizardfolk_store_definition(item_id)
		if item_data.is_empty():
			continue
		entries.append({
			"item_id": item_id,
			"name": String(item_data.get("name", item_id)),
			"description": String(item_data.get("description", "Lizardfolk upgrade.")),
			"price": LIZARDFOLK_ITEM_PRICE,
			"owned": _is_lizard_store_item_owned(item_id)
		})
	return entries


func purchase_store_item(item_id: String) -> Dictionary:
	var normalized_item_id := item_id.strip_edges().to_lower()
	if normalized_item_id.is_empty() or _get_lizardfolk_store_definition(normalized_item_id).is_empty():
		return {
			"success": false,
			"reason": "Item unavailable.",
			"gold_total": get_gold_total()
		}
	if _is_lizard_store_item_owned(normalized_item_id):
		return {
			"success": false,
			"reason": "Already owned.",
			"gold_total": get_gold_total()
		}
	if get_gold_total() < LIZARDFOLK_ITEM_PRICE:
		return {
			"success": false,
			"reason": "Not enough gold.",
			"gold_total": get_gold_total()
		}
	if not _spend_shared_gold(LIZARDFOLK_ITEM_PRICE):
		return {
			"success": false,
			"reason": "Unable to spend gold.",
			"gold_total": get_gold_total()
		}
	var granted := _grant_lizard_store_item(normalized_item_id)
	if not granted:
		return {
			"success": false,
			"reason": "Grant failed.",
			"gold_total": get_gold_total()
		}
	var item_data := _get_lizardfolk_store_definition(normalized_item_id)
	return {
		"success": true,
		"item_id": normalized_item_id,
		"item_name": String(item_data.get("name", normalized_item_id)),
		"price": LIZARDFOLK_ITEM_PRICE,
		"gold_total": get_gold_total()
	}


func _initialize_default_equipment_inventory() -> void:
	available_weapon_ids.clear()
	equipped_weapon_id = ""
	available_trinket_ids.clear()
	equipped_trinket_id = ""
	available_boot_ids.clear()


func _cache_base_stats() -> void:
	super._cache_base_stats()
	base_arrow_projectile_speed = arrow_projectile_speed
	base_arrow_projectile_max_distance = arrow_projectile_max_distance
	base_attack_windup = attack_windup
	base_attack_cooldown = attack_cooldown
	base_flurry_cooldown = flurry_cooldown
	base_flurry_windup = flurry_windup
	base_flurry_duration = flurry_duration
	base_flurry_shot_interval = flurry_shot_interval
	base_flurry_trigger_range = flurry_trigger_range
	base_flurry_arrow_damage_scale = flurry_arrow_damage_scale


func _refresh_equipment_stats() -> void:
	if base_max_health <= 0.0:
		return
	max_health = base_max_health
	move_speed = base_move_speed
	attack_damage = base_attack_damage
	attack_range = base_attack_range
	attack_windup = base_attack_windup
	attack_cooldown = base_attack_cooldown
	shadow_fear_duration = base_shadow_fear_duration
	shadow_fear_cooldown = base_shadow_fear_cooldown
	shadow_clone_count = base_shadow_clone_count
	shadow_clone_cooldown = base_shadow_clone_cooldown
	boss_mark_duration = base_boss_mark_duration
	boss_mark_range = base_boss_mark_range
	manual_roll_speed = base_manual_roll_speed
	manual_roll_cooldown = base_manual_roll_cooldown
	backstab_dash_speed = base_backstab_dash_speed
	backstab_dash_cooldown = base_backstab_dash_cooldown
	special_meter_gain_per_damage = base_special_meter_gain_per_damage
	special_meter_gain_per_heal = base_special_meter_gain_per_heal
	arrow_projectile_speed = base_arrow_projectile_speed
	arrow_projectile_max_distance = base_arrow_projectile_max_distance
	flurry_cooldown = base_flurry_cooldown
	flurry_windup = base_flurry_windup
	flurry_duration = base_flurry_duration
	flurry_shot_interval = base_flurry_shot_interval
	flurry_trigger_range = base_flurry_trigger_range
	flurry_arrow_damage_scale = base_flurry_arrow_damage_scale

	var weapon_data := _get_equipped_lizardfolk_weapon_data()
	if not weapon_data.is_empty():
		attack_damage *= maxf(0.1, float(weapon_data.get("attack_damage_multiplier", 1.0)))
		attack_range *= maxf(0.1, float(weapon_data.get("attack_range_multiplier", 1.0)))
		attack_cooldown *= clampf(float(weapon_data.get("attack_cooldown_multiplier", 1.0)), 0.1, 10.0)
		arrow_projectile_speed *= maxf(0.1, float(weapon_data.get("arrow_projectile_speed_multiplier", 1.0)))
		arrow_projectile_max_distance *= maxf(0.1, float(weapon_data.get("arrow_projectile_max_distance_multiplier", 1.0)))
		flurry_trigger_range *= maxf(0.1, float(weapon_data.get("flurry_trigger_range_multiplier", 1.0)))
		flurry_arrow_damage_scale *= maxf(0.1, float(weapon_data.get("flurry_arrow_damage_multiplier", 1.0)))

	var trinket_data := _get_equipped_lizardfolk_trinket_data()
	if not trinket_data.is_empty():
		max_health *= maxf(0.1, float(trinket_data.get("max_health_multiplier", 1.0)))
		special_meter_gain_per_damage *= maxf(0.1, float(trinket_data.get("special_gain_multiplier", 1.0)))
		special_meter_gain_per_heal *= maxf(0.1, float(trinket_data.get("special_gain_multiplier", 1.0)))
		flurry_cooldown *= clampf(float(trinket_data.get("flurry_cooldown_multiplier", 1.0)), 0.1, 10.0)
		flurry_duration *= maxf(0.1, float(trinket_data.get("flurry_duration_multiplier", 1.0)))
		arrow_projectile_max_distance *= maxf(0.1, float(trinket_data.get("arrow_projectile_max_distance_multiplier", 1.0)))

	if _has_lizardfolk_boot("brushrunner_boots"):
		var move_boot_data := LIZARDFOLK_BOOT_DEFINITIONS.get("brushrunner_boots", {}) as Dictionary
		move_speed *= maxf(1.0, float(move_boot_data.get("move_speed_multiplier", 1.0)))
	if _has_lizardfolk_boot("reedshadow_boots"):
		var roll_boot_data := LIZARDFOLK_BOOT_DEFINITIONS.get("reedshadow_boots", {}) as Dictionary
		manual_roll_speed *= maxf(1.0, float(roll_boot_data.get("roll_speed_multiplier", 1.0)))
		manual_roll_cooldown *= clampf(float(roll_boot_data.get("roll_cooldown_multiplier", 1.0)), 0.1, 10.0)
	if _has_lizardfolk_boot("quickdraw_greaves"):
		var quickdraw_boot_data := LIZARDFOLK_BOOT_DEFINITIONS.get("quickdraw_greaves", {}) as Dictionary
		attack_windup *= clampf(float(quickdraw_boot_data.get("attack_windup_multiplier", 1.0)), 0.1, 10.0)
		flurry_windup *= clampf(float(quickdraw_boot_data.get("flurry_windup_multiplier", 1.0)), 0.1, 10.0)

	max_health = maxf(1.0, max_health)
	move_speed = maxf(24.0, move_speed)
	attack_damage = maxf(1.0, attack_damage)
	attack_range = maxf(24.0, attack_range)
	attack_windup = maxf(0.05, attack_windup)
	attack_cooldown = maxf(0.05, attack_cooldown)
	manual_roll_speed = maxf(48.0, manual_roll_speed)
	manual_roll_cooldown = maxf(0.05, manual_roll_cooldown)
	arrow_projectile_speed = maxf(120.0, arrow_projectile_speed)
	arrow_projectile_max_distance = maxf(48.0, arrow_projectile_max_distance)
	flurry_cooldown = maxf(0.1, flurry_cooldown)
	flurry_windup = maxf(0.05, flurry_windup)
	flurry_duration = maxf(0.1, flurry_duration)
	flurry_shot_interval = maxf(0.03, flurry_shot_interval)
	flurry_trigger_range = maxf(48.0, flurry_trigger_range)
	flurry_arrow_damage_scale = maxf(0.1, flurry_arrow_damage_scale)

	current_health = minf(current_health, max_health)
	attack_cooldown_left = minf(attack_cooldown_left, attack_cooldown)
	manual_roll_cooldown_left = minf(manual_roll_cooldown_left, manual_roll_cooldown)
	flurry_cooldown_left = minf(flurry_cooldown_left, flurry_cooldown)
	if _uses_combo_points():
		combo_point_count = clampi(combo_point_count, 0, _get_combo_point_max())
	else:
		special_meter = clampf(special_meter, 0.0, maxf(1.0, special_meter_max))
	if is_inside_tree() and not dead and current_health > 0.0:
		_update_health_bar()
		health_changed.emit(current_health, max_health)


func _is_lizard_store_item_owned(item_id: String) -> bool:
	if LIZARDFOLK_WEAPON_DEFINITIONS.has(item_id):
		return available_weapon_ids.find(item_id) != -1
	if LIZARDFOLK_TRINKET_DEFINITIONS.has(item_id):
		return available_trinket_ids.find(item_id) != -1
	if LIZARDFOLK_BOOT_DEFINITIONS.has(item_id):
		return available_boot_ids.find(item_id) != -1
	return false


func _get_lizardfolk_store_definition(item_id: String) -> Dictionary:
	if LIZARDFOLK_WEAPON_DEFINITIONS.has(item_id):
		return (LIZARDFOLK_WEAPON_DEFINITIONS[item_id] as Dictionary).duplicate(true)
	if LIZARDFOLK_TRINKET_DEFINITIONS.has(item_id):
		return (LIZARDFOLK_TRINKET_DEFINITIONS[item_id] as Dictionary).duplicate(true)
	if LIZARDFOLK_BOOT_DEFINITIONS.has(item_id):
		return (LIZARDFOLK_BOOT_DEFINITIONS[item_id] as Dictionary).duplicate(true)
	return {}


func _grant_lizard_store_item(item_id: String) -> bool:
	if LIZARDFOLK_WEAPON_DEFINITIONS.has(item_id):
		if available_weapon_ids.find(item_id) == -1:
			available_weapon_ids.append(item_id)
		if equipped_weapon_id.is_empty():
			equipped_weapon_id = item_id
		_sort_lizardfolk_owned_items()
		_refresh_equipment_stats()
		return true
	if LIZARDFOLK_TRINKET_DEFINITIONS.has(item_id):
		if available_trinket_ids.find(item_id) == -1:
			available_trinket_ids.append(item_id)
		if equipped_trinket_id.is_empty():
			equipped_trinket_id = item_id
		_sort_lizardfolk_owned_items()
		_refresh_equipment_stats()
		return true
	if LIZARDFOLK_BOOT_DEFINITIONS.has(item_id):
		if available_boot_ids.find(item_id) == -1:
			available_boot_ids.append(item_id)
		_sort_lizardfolk_owned_items()
		_refresh_equipment_stats()
		return true
	return false


func _get_equipped_lizardfolk_weapon_data() -> Dictionary:
	if equipped_weapon_id.is_empty() or not LIZARDFOLK_WEAPON_DEFINITIONS.has(equipped_weapon_id):
		return {}
	return (LIZARDFOLK_WEAPON_DEFINITIONS[equipped_weapon_id] as Dictionary).duplicate(true)


func _get_equipped_lizardfolk_trinket_data() -> Dictionary:
	if equipped_trinket_id.is_empty() or not LIZARDFOLK_TRINKET_DEFINITIONS.has(equipped_trinket_id):
		return {}
	return (LIZARDFOLK_TRINKET_DEFINITIONS[equipped_trinket_id] as Dictionary).duplicate(true)


func _has_lizardfolk_boot(boot_id: String) -> bool:
	return not boot_id.is_empty() and available_boot_ids.find(boot_id) != -1


func _get_ratfolk_damage_taken_multiplier() -> float:
	var trinket_data := _get_equipped_lizardfolk_trinket_data()
	if trinket_data.is_empty():
		return 1.0
	return clampf(float(trinket_data.get("damage_taken_multiplier", 1.0)), 0.1, 10.0)


func _sort_lizardfolk_owned_items() -> void:
	available_weapon_ids = _sort_ids_by_order(available_weapon_ids, LIZARDFOLK_WEAPON_ORDER)
	available_trinket_ids = _sort_ids_by_order(available_trinket_ids, LIZARDFOLK_TRINKET_ORDER)
	available_boot_ids = _sort_ids_by_order(available_boot_ids, LIZARDFOLK_BOOT_ORDER)


func _configure_sprite() -> void:
	if not is_instance_valid(sprite):
		return
	sprite.texture = _get_ratfolk_sheet_texture()
	sprite.hframes = LIZARDFOLK_HFRAMES
	sprite.vframes = LIZARDFOLK_VFRAMES
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _set_loop_anim(anim_key: String, delta: float) -> void:
	if sprite_anim_key != anim_key:
		sprite_anim_key = anim_key
		sprite_anim_time = 0.0
	else:
		sprite_anim_time += delta
	var columns: Array = LIZARD_ANIM_FRAME_COLUMNS.get(anim_key, [])
	if columns.is_empty():
		return
	var fps := float(LIZARD_ANIM_FPS.get(anim_key, 8.0))
	var frame_index := int(floor(sprite_anim_time * fps)) % columns.size()
	_set_sprite_frame(anim_key, frame_index)


func _set_non_loop_anim(anim_key: String, progress: float) -> void:
	sprite_anim_key = anim_key
	var columns: Array = LIZARD_ANIM_FRAME_COLUMNS.get(anim_key, [])
	if columns.is_empty():
		return
	var frame_index := mini(int(floor(clampf(progress, 0.0, 1.0) * float(columns.size()))), columns.size() - 1)
	_set_sprite_frame(anim_key, frame_index)


func _set_sprite_frame(anim_key: String, frame_index: int) -> void:
	if not is_instance_valid(sprite):
		return
	var row := int(LIZARD_ANIM_ROWS.get(anim_key, 0))
	var columns: Array = LIZARD_ANIM_FRAME_COLUMNS.get(anim_key, [])
	if columns.is_empty():
		return
	var safe_index := clampi(frame_index, 0, columns.size() - 1)
	var column := int(columns[safe_index])
	sprite.frame_coords = Vector2i(column, row)
	sprite.flip_h = facing_left


func _get_anim_duration(anim_key: String) -> float:
	var columns: Array = LIZARD_ANIM_FRAME_COLUMNS.get(anim_key, [])
	var fps := float(LIZARD_ANIM_FPS.get(anim_key, 8.0))
	if columns.is_empty() or fps <= 0.0:
		return 0.2
	return float(columns.size()) / fps


func _get_ratfolk_sheet_texture() -> Texture2D:
	if is_instance_valid(lizardfolk_sheet_texture):
		return lizardfolk_sheet_texture
	var source_image := Image.load_from_file(ProjectSettings.globalize_path(LIZARDFOLK_SHEET_PATH))
	if source_image == null or source_image.is_empty():
		return null
	lizardfolk_sheet_texture = ImageTexture.create_from_image(source_image)
	return lizardfolk_sheet_texture


func _get_ratfolk_scene() -> PackedScene:
	if is_instance_valid(lizardfolk_scene_cache):
		return lizardfolk_scene_cache
	var loaded_scene := load(LIZARDFOLK_SCENE_PATH)
	if loaded_scene is PackedScene:
		lizardfolk_scene_cache = loaded_scene as PackedScene
	return lizardfolk_scene_cache


func _tick_timers(delta: float) -> void:
	super._tick_timers(delta)
	flurry_cooldown_left = maxf(0.0, flurry_cooldown_left - maxf(0.0, delta))
	flurry_windup_left = maxf(0.0, flurry_windup_left - maxf(0.0, delta))
	flurry_active_left = maxf(0.0, flurry_active_left - maxf(0.0, delta))
	flurry_shot_left = maxf(0.0, flurry_shot_left - maxf(0.0, delta))


func _interrupt_attack() -> void:
	super._interrupt_attack()
	_reset_flurry_state()


func _die() -> void:
	_reset_flurry_state()
	super._die()


func _update_animation(delta: float) -> void:
	if flurry_sequence_active and (flurry_windup_left > 0.0 or flurry_active_left > 0.0):
		_set_loop_anim("attack", delta)
		return
	super._update_animation(delta)


func _get_preferred_attack_position(enemy: EnemyBase) -> Vector2:
	if enemy == null or not is_instance_valid(enemy) or not is_instance_valid(player):
		return super._get_preferred_attack_position(enemy)
	var tank_position := player.global_position
	var tank_to_enemy := enemy.global_position - tank_position
	var away_from_enemy := Vector2.ZERO
	if tank_to_enemy.length_squared() > 0.0001:
		away_from_enemy = -tank_to_enemy.normalized()
	else:
		away_from_enemy = Vector2.LEFT if facing_left else Vector2.RIGHT
	var depth_sign := 1.0 if (int(get_instance_id()) % 2) == 0 else -1.0
	var depth_offset := depth_sign * minf(maxf(6.0, behind_tank_depth_offset), attack_depth_tolerance * 0.55)
	var desired_position := tank_position + (away_from_enemy * maxf(24.0, behind_tank_distance)) + Vector2(0.0, depth_offset)

	var min_enemy_distance := _get_attack_spacing_min()
	var desired_to_enemy := enemy.global_position - desired_position
	if desired_to_enemy.length() < min_enemy_distance:
		var fallback_away := away_from_enemy
		if fallback_away.length_squared() <= 0.0001:
			fallback_away = (desired_position - enemy.global_position).normalized()
		if fallback_away.length_squared() <= 0.0001:
			fallback_away = Vector2.LEFT if facing_left else Vector2.RIGHT
		desired_position = enemy.global_position + (fallback_away.normalized() * min_enemy_distance)

	return _clamp_world_position_to_bounds(desired_position)


func _get_backstab_target_position(enemy: EnemyBase) -> Vector2:
	# Reuse the ranger's guarded firing slot so inherited miniboss flank logic
	# keeps this ally behind the tank instead of circling behind the boss.
	return _get_preferred_attack_position(enemy)


func _is_position_behind_enemy(enemy: EnemyBase, world_position: Vector2) -> bool:
	if enemy == null or not is_instance_valid(enemy) or not is_instance_valid(player):
		return super._is_position_behind_enemy(enemy, world_position)
	var tank_to_enemy := enemy.global_position - player.global_position
	if tank_to_enemy.length_squared() <= 0.0001:
		return world_position.distance_to(player.global_position) <= maxf(24.0, behind_tank_distance * 0.72)
	var tank_to_self := world_position - player.global_position
	if tank_to_self.length_squared() <= 0.0001:
		return false
	var away_from_enemy := -tank_to_enemy.normalized()
	var self_direction := tank_to_self.normalized()
	var alignment := away_from_enemy.dot(self_direction)
	return alignment >= clampf(tank_guard_alignment_threshold, -0.25, 0.95) \
		and tank_to_self.length() <= maxf(48.0, tank_guard_max_distance)


func _compute_reposition_velocity(enemy: EnemyBase, to_enemy: Vector2, distance_to_enemy: float) -> Vector2:
	var fallback_velocity := super._compute_reposition_velocity(enemy, to_enemy, distance_to_enemy)
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return fallback_velocity
	if not enemy.is_miniboss:
		return fallback_velocity
	var preferred_position := _get_preferred_attack_position(enemy)
	var to_preferred := preferred_position - global_position
	var hold_radius := maxf(8.0, tank_guard_hold_radius)
	if distance_to_enemy < _get_attack_spacing_min():
		if to_preferred.length() > hold_radius:
			return to_preferred.normalized() * move_speed * 0.9
		var retreat_direction := -to_enemy
		if retreat_direction.length_squared() <= 0.0001:
			retreat_direction = Vector2.LEFT if facing_left else Vector2.RIGHT
		return retreat_direction.normalized() * move_speed * 0.86
	if to_preferred.length() > hold_radius:
		return to_preferred.normalized() * move_speed * 0.9
	return Vector2.ZERO


func _tick_combat_logic(delta: float) -> void:
	if flurry_sequence_active:
		if _handle_breath_threat():
			_reset_flurry_state()
			return
		if _handle_marked_lunge_threat(delta):
			_reset_flurry_state()
			return
		velocity = Vector2.ZERO
		if not flurry_has_started_firing:
			var prep_targets := _get_flurry_targets(1)
			if not prep_targets.is_empty():
				_update_facing(prep_targets[0].global_position - global_position)
			if flurry_windup_left > 0.0:
				return
			flurry_has_started_firing = true
			flurry_active_left = maxf(0.1, flurry_duration)
			flurry_shot_left = 0.0
			_spawn_hit_effect(global_position + Vector2(0.0, -18.0), Color(0.76, 0.96, 0.62, 0.9), 6.8)
		if flurry_active_left <= 0.0:
			_reset_flurry_state()
			return
		var volley_targets := _get_flurry_targets(flurry_max_targets_per_volley)
		if volley_targets.is_empty():
			_reset_flurry_state()
			return
		_update_facing(volley_targets[0].global_position - global_position)
		if flurry_shot_left <= 0.0:
			_fire_flurry_volley(volley_targets)
			flurry_shot_left = maxf(0.03, flurry_shot_interval)
		return

	if _can_start_flurry():
		_start_flurry()
		velocity = Vector2.ZERO
		return

	super._tick_combat_logic(delta)


func _tick_manual_control_logic(delta: float) -> void:
	shadow_fear_focus_target = null
	shadow_fear_resume_target = null
	shadow_fear_pending_left = -1.0
	shadow_fear_pending_total = 0.0
	shadow_fear_focus_requires_close = true
	if flurry_sequence_active:
		if _handle_breath_threat():
			_reset_flurry_state()
			return
		if _handle_marked_lunge_threat(delta):
			_reset_flurry_state()
			return
		velocity = Vector2.ZERO
		if not flurry_has_started_firing:
			var prep_targets := _get_flurry_targets(1)
			if not prep_targets.is_empty():
				_update_facing(prep_targets[0].global_position - global_position)
			if flurry_windup_left > 0.0:
				return
			flurry_has_started_firing = true
			flurry_active_left = maxf(0.1, flurry_duration)
			flurry_shot_left = 0.0
			_spawn_hit_effect(global_position + Vector2(0.0, -18.0), Color(0.76, 0.96, 0.62, 0.9), 6.8)
		if flurry_active_left <= 0.0:
			_reset_flurry_state()
			return
		var volley_targets := _get_flurry_targets(flurry_max_targets_per_volley)
		if volley_targets.is_empty():
			_reset_flurry_state()
			return
		_update_facing(volley_targets[0].global_position - global_position)
		if flurry_shot_left <= 0.0:
			_fire_flurry_volley(volley_targets)
			flurry_shot_left = maxf(0.03, flurry_shot_interval)
		return
	if manual_roll_left > 0.0:
		velocity = manual_roll_vector * maxf(48.0, manual_roll_speed)
		if manual_roll_vector.length_squared() > 0.0001:
			_update_facing(velocity)
		return
	if attack_windup_left > 0.0:
		attack_windup_left = maxf(0.0, attack_windup_left - delta)
		velocity = Vector2.ZERO
		if attack_windup_left <= 0.0:
			_perform_attack()
			attack_recovery_left = maxf(0.01, attack_recovery)
		return
	if attack_recovery_left > 0.0:
		attack_recovery_left = maxf(0.0, attack_recovery_left - delta)
		if attack_recovery_left <= 0.0:
			current_attack_mode = AttackMode.BASIC
		velocity = Vector2.ZERO
		return
	_handle_manual_control_movement()
	_handle_lizard_manual_control_actions()


func _perform_attack() -> void:
	attack_cooldown_left = maxf(0.01, attack_cooldown)
	var target := target_enemy
	if target == null or not is_instance_valid(target) or target.dead:
		target = _find_target_enemy()
	if target == null or not is_instance_valid(target) or target.dead:
		if manual_control_enabled:
			var forward_direction := _get_manual_shot_direction()
			_fire_arrow_in_direction(forward_direction, 1.0, 1.0, 1.0, true)
		return
	if _is_enemy_shadow_feared(target):
		return

	var fired := _fire_arrow_at_target(target, 1.0, 1.0, 1.0, true)
	if fired:
		return

	if target.has_method("receive_hit"):
		var fallback_hit := bool(target.call("receive_hit", attack_damage, global_position, outgoing_hit_stun_duration, true, attack_knockback_scale, self))
		if fallback_hit:
			add_special_meter_from_damage(attack_damage)
		if fallback_hit and target.has_method("apply_hitstop"):
			target.call("apply_hitstop", arrow_impact_hitstop)


func _handle_lizard_manual_control_actions() -> void:
	if not manual_control_enabled or dead:
		return
	if stun_left > 0.0 or flurry_sequence_active:
		return
	if attack_windup_left > 0.0 or attack_recovery_left > 0.0:
		return
	if Input.is_action_just_pressed("roll"):
		if _can_start_manual_roll():
			_start_manual_roll()
			return
	if Input.is_action_just_pressed("ability_2"):
		if _can_start_manual_flurry():
			_start_flurry()
			velocity = Vector2.ZERO
			return
	if Input.is_action_just_pressed("basic_attack") and attack_cooldown_left <= 0.0:
		var attack_target := _find_manual_arrow_target()
		target_enemy = attack_target
		if attack_target != null:
			_update_facing(attack_target.global_position - global_position)
		else:
			_update_facing(_get_manual_shot_direction())
		_set_dps_ai_state(DPSAIState.ATTACKING, attack_target)
		_start_attack_windup("manual")
		velocity = Vector2.ZERO


func _can_start_manual_flurry() -> bool:
	if not manual_control_enabled or dead or is_shadow_clone:
		return false
	if not flurry_enabled or flurry_sequence_active:
		return false
	if flurry_cooldown_left > 0.0:
		return false
	if not _is_special_meter_full():
		return false
	if manual_roll_left > 0.0:
		return false
	if attack_windup_left > 0.0 or attack_recovery_left > 0.0:
		return false
	if stun_left > 0.0:
		return false
	return _get_flurry_targets(flurry_max_targets_per_volley).size() >= maxi(1, flurry_min_targets)


func _find_manual_arrow_target() -> EnemyBase:
	var best_enemy: EnemyBase = null
	var best_distance_sq := INF
	var max_distance_sq := maxf(32.0, arrow_projectile_max_distance) * maxf(32.0, arrow_projectile_max_distance)
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if _is_enemy_shadow_feared(enemy):
			continue
		var to_enemy := enemy.global_position - global_position
		if to_enemy.length_squared() > max_distance_sq:
			continue
		if absf(to_enemy.y) > maxf(48.0, attack_depth_tolerance * 1.1):
			continue
		var distance_sq := to_enemy.length_squared()
		if best_enemy == null or distance_sq < best_distance_sq:
			best_enemy = enemy
			best_distance_sq = distance_sq
	return best_enemy


func _get_manual_shot_direction() -> Vector2:
	var move_input := _get_manual_move_input()
	if move_input.length_squared() > 0.0001:
		return move_input.normalized()
	return Vector2.LEFT if facing_left else Vector2.RIGHT


func _can_start_flurry() -> bool:
	if not flurry_enabled:
		return false
	if flurry_sequence_active:
		return false
	if not _is_special_meter_full():
		return false
	if attack_windup_left > 0.0 or attack_recovery_left > 0.0:
		return false
	if backstab_dash_left > 0.0 or shadow_clone_cast_active or shadow_fear_cast_active:
		return false
	if not is_instance_valid(player):
		return false
	var ready_targets := _get_flurry_targets(flurry_max_targets_per_volley)
	return ready_targets.size() >= maxi(1, flurry_min_targets)


func _start_flurry() -> void:
	_consume_special_meter()
	flurry_sequence_active = true
	flurry_has_started_firing = false
	flurry_windup_left = maxf(0.06, flurry_windup)
	flurry_active_left = 0.0
	flurry_shot_left = 0.0
	flurry_cooldown_left = maxf(0.1, flurry_cooldown)
	_set_dps_ai_state(DPSAIState.ASSAULT_CAST, target_enemy)
	_spawn_hit_effect(global_position + Vector2(0.0, -14.0), Color(0.72, 0.9, 0.58, 0.86), 5.6)


func _reset_flurry_state() -> void:
	flurry_sequence_active = false
	flurry_has_started_firing = false
	flurry_windup_left = 0.0
	flurry_active_left = 0.0
	flurry_shot_left = 0.0


func _find_target_enemy() -> EnemyBase:
	var candidate := _find_priority_miniboss_target()
	if candidate == null:
		candidate = super._find_target_enemy()
	if candidate == null or not is_instance_valid(candidate):
		lizard_combat_engaged = false
		return null
	if not is_instance_valid(player):
		lizard_combat_engaged = true
		return candidate
	var engage_distance := maxf(40.0, engage_distance_from_player)
	var disengage_distance := maxf(engage_distance + 20.0, disengage_distance_from_player)
	var distance_to_player := player.global_position.distance_to(candidate.global_position)
	if lizard_combat_engaged:
		if distance_to_player <= disengage_distance:
			return candidate
		lizard_combat_engaged = false
		return null
	if distance_to_player <= engage_distance:
		lizard_combat_engaged = true
		return candidate
	return null


func _find_priority_miniboss_target() -> EnemyBase:
	var nearest_boss: EnemyBase = null
	var nearest_boss_distance_sq := INF
	var nearest_boss_id := INF
	var player_position := player.global_position if is_instance_valid(player) else global_position
	var max_chase_distance_sq := maxf(1.0, max_chase_distance_from_player) * maxf(1.0, max_chase_distance_from_player)
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if not enemy.is_miniboss:
			continue
		if _is_enemy_shadow_feared(enemy):
			continue
		if enemy.global_position.distance_squared_to(player_position) > max_chase_distance_sq:
			continue
		var distance_sq := enemy.global_position.distance_squared_to(global_position)
		var enemy_id := enemy.get_instance_id()
		if nearest_boss == null \
			or distance_sq < nearest_boss_distance_sq \
			or (is_equal_approx(distance_sq, nearest_boss_distance_sq) and enemy_id < nearest_boss_id):
			nearest_boss = enemy
			nearest_boss_distance_sq = distance_sq
			nearest_boss_id = enemy_id
	return nearest_boss


func _fire_flurry_volley(targets: Array[EnemyBase]) -> void:
	if targets.is_empty():
		return
	var fired_count := 0
	for enemy in targets:
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		if _fire_arrow_at_target(enemy, flurry_arrow_damage_scale, flurry_arrow_speed_scale, 1.0, false, false):
			fired_count += 1
	if fired_count > 0:
		_spawn_hit_effect(global_position + Vector2(0.0, -16.0), Color(0.72, 0.98, 0.64, 0.9), 4.6 + float(fired_count))


func _get_flurry_targets(max_count: int) -> Array[EnemyBase]:
	var limit := maxi(1, max_count)
	var trigger_range_sq := maxf(32.0, flurry_trigger_range) * maxf(32.0, flurry_trigger_range)
	var chase_range_sq := maxf(1.0, max_chase_distance_from_player) * maxf(1.0, max_chase_distance_from_player)
	var player_position := player.global_position if is_instance_valid(player) else global_position
	var candidates: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if _is_enemy_shadow_feared(enemy):
			continue
		if enemy.global_position.distance_squared_to(player_position) > chase_range_sq:
			continue
		var dist_sq := enemy.global_position.distance_squared_to(global_position)
		if dist_sq > trigger_range_sq:
			continue
		candidates.append({
			"enemy": enemy,
			"dist_sq": dist_sq
		})
	candidates.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("dist_sq", INF)) < float(b.get("dist_sq", INF))
	)
	var selected: Array[EnemyBase] = []
	for entry_variant in candidates:
		var entry := entry_variant as Dictionary
		var enemy_candidate := entry.get("enemy") as EnemyBase
		if enemy_candidate == null or not is_instance_valid(enemy_candidate) or enemy_candidate.dead:
			continue
		selected.append(enemy_candidate)
		if selected.size() >= limit:
			break
	return selected


func _fire_arrow_at_target(target: EnemyBase, damage_scale: float = 1.0, speed_scale: float = 1.0, distance_scale: float = 1.0, spawn_cast_effect: bool = true, grant_special_meter_on_hit: bool = true) -> bool:
	if target == null or not is_instance_valid(target) or target.dead:
		return false
	var fallback_direction := target.global_position - global_position
	if fallback_direction.length_squared() <= 0.0001:
		fallback_direction = Vector2.LEFT if facing_left else Vector2.RIGHT
	var spawn_position := _get_arrow_spawn_position(fallback_direction)
	var aim_point := _get_enemy_arrow_target_point(target)
	var to_target := aim_point - spawn_position
	var fire_direction := to_target.normalized() if to_target.length_squared() > 0.0001 else fallback_direction.normalized()
	if flurry_active_left > 0.0 and flurry_aim_spread_degrees > 0.0:
		var spread_radians := deg_to_rad(clampf(flurry_aim_spread_degrees, 0.0, 45.0))
		fire_direction = fire_direction.rotated(rng.randf_range(-spread_radians, spread_radians))
		if fire_direction.length_squared() <= 0.0001:
			fire_direction = to_target.normalized() if to_target.length_squared() > 0.0001 else fallback_direction.normalized()
		else:
			fire_direction = fire_direction.normalized()
	spawn_position = _get_arrow_spawn_position(fire_direction)
	_update_facing(fire_direction)

	var projectile_scene := _get_arrow_projectile_scene()
	if projectile_scene == null:
		return false

	var projectile := projectile_scene.instantiate()
	if projectile == null:
		return false
	var scene_root := get_parent()
	if scene_root == null:
		projectile.queue_free()
		return false
	scene_root.add_child(projectile)
	if projectile.has_method("setup"):
		projectile.call(
			"setup",
			self,
			spawn_position,
			fire_direction,
			maxf(1.0, arrow_projectile_speed * maxf(0.1, speed_scale)),
			maxf(24.0, arrow_projectile_max_distance * maxf(0.1, distance_scale)),
			maxf(0.1, attack_damage * maxf(0.1, damage_scale)),
			maxf(0.0, outgoing_hit_stun_duration),
			maxf(0.1, attack_knockback_scale),
			target,
			grant_special_meter_on_hit
		)
	if spawn_cast_effect:
		_spawn_hit_effect(spawn_position, Color(0.86, 0.96, 0.72, 0.86), 4.2)
	return true


func _fire_arrow_in_direction(direction: Vector2, damage_scale: float = 1.0, speed_scale: float = 1.0, distance_scale: float = 1.0, spawn_cast_effect: bool = true) -> bool:
	var fire_direction := direction.normalized()
	if fire_direction.length_squared() <= 0.0001:
		fire_direction = Vector2.LEFT if facing_left else Vector2.RIGHT
	_update_facing(fire_direction)
	var projectile_scene := _get_arrow_projectile_scene()
	if projectile_scene == null:
		return false
	var projectile := projectile_scene.instantiate()
	if projectile == null:
		return false
	var scene_root := get_parent()
	if scene_root == null:
		projectile.queue_free()
		return false
	scene_root.add_child(projectile)
	var spawn_position := _get_arrow_spawn_position(fire_direction)
	if projectile.has_method("setup"):
		projectile.call(
			"setup",
			self,
			spawn_position,
			fire_direction,
			maxf(1.0, arrow_projectile_speed * maxf(0.1, speed_scale)),
			maxf(24.0, arrow_projectile_max_distance * maxf(0.1, distance_scale)),
			maxf(0.1, attack_damage * maxf(0.1, damage_scale)),
			maxf(0.0, outgoing_hit_stun_duration),
			maxf(0.1, attack_knockback_scale),
			null
		)
	if spawn_cast_effect:
		_spawn_hit_effect(spawn_position, Color(0.86, 0.96, 0.72, 0.86), 4.2)
	return true


func _spawn_attack_range_indicator(reason: String = "") -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent()
	if scene_root == null:
		return
	var direction := Vector2.LEFT if facing_left else Vector2.RIGHT
	var indicator_origin := _get_arrow_spawn_position(direction)
	var telegraph_target := _get_arrow_telegraph_target()
	if telegraph_target != null:
		var to_target := _get_enemy_arrow_target_point(telegraph_target) - indicator_origin
		if to_target.length_squared() > 0.0001:
			direction = to_target.normalized()
			indicator_origin = _get_arrow_spawn_position(direction)
	var indicator := Node2D.new()
	indicator.top_level = true
	indicator.global_position = indicator_origin
	indicator.rotation = direction.angle()
	indicator.z_index = 229
	scene_root.add_child(indicator)
	var target_radius := _get_enemy_attack_collision_radius(telegraph_target) if telegraph_target != null else 0.0
	var telegraph_half_width := maxf(4.0, float(LIZARD_ARROW_PROJECTILE_SCRIPT.DEFAULT_HIT_RADIUS) + target_radius)
	var telegraph_length := maxf(48.0, arrow_projectile_max_distance + target_radius)
	var line_color := Color(0.36, 0.84, 1.0, 0.94) if manual_control_enabled and reason == "manual" else Color(0.82, 0.96, 0.64, 0.86)
	var fill_color := Color(0.18, 0.58, 0.92, 0.16) if manual_control_enabled and reason == "manual" else Color(0.42, 0.9, 0.58, 0.14)
	var lane := Line2D.new()
	lane.default_color = fill_color
	lane.width = telegraph_half_width * 2.0
	lane.begin_cap_mode = Line2D.LINE_CAP_ROUND
	lane.end_cap_mode = Line2D.LINE_CAP_ROUND
	lane.points = PackedVector2Array([Vector2.ZERO, Vector2(telegraph_length, 0.0)])
	indicator.add_child(lane)
	var shaft := Line2D.new()
	shaft.default_color = line_color
	shaft.width = maxf(1.8, telegraph_half_width * 0.38)
	shaft.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shaft.end_cap_mode = Line2D.LINE_CAP_ROUND
	shaft.points = PackedVector2Array([Vector2.ZERO, Vector2(telegraph_length, 0.0)])
	indicator.add_child(shaft)
	var head_length := maxf(12.0, telegraph_half_width * 1.6)
	var head_base_x := maxf(0.0, telegraph_length - head_length)
	var head := Polygon2D.new()
	head.color = line_color
	head.polygon = PackedVector2Array([
		Vector2(head_base_x, -telegraph_half_width),
		Vector2(telegraph_length, 0.0),
		Vector2(head_base_x, telegraph_half_width)
	])
	indicator.add_child(head)
	var tween := create_tween()
	tween.tween_property(indicator, "modulate:a", 0.0, 0.14)
	tween.finished.connect(func() -> void:
		if is_instance_valid(indicator):
			indicator.queue_free()
	)


func _get_arrow_telegraph_target() -> EnemyBase:
	if target_enemy != null and is_instance_valid(target_enemy) and not target_enemy.dead and not _is_enemy_shadow_feared(target_enemy):
		return target_enemy
	return _find_manual_arrow_target()


func _get_cast_progress_ratio() -> float:
	var inherited_ratio := super._get_cast_progress_ratio()
	if inherited_ratio >= 0.0:
		return inherited_ratio
	if attack_windup_left > 0.0 and attack_windup > 0.01:
		return clampf(1.0 - (attack_windup_left / attack_windup), 0.0, 1.0)
	return -1.0


func _get_arrow_spawn_position(direction: Vector2) -> Vector2:
	var fire_direction := direction.normalized()
	if fire_direction.length_squared() <= 0.0001:
		fire_direction = Vector2.LEFT if facing_left else Vector2.RIGHT
	return global_position + Vector2(fire_direction.x * maxf(8.0, arrow_spawn_forward_offset), arrow_spawn_vertical_offset)


func _get_enemy_arrow_target_point(enemy: EnemyBase) -> Vector2:
	if enemy == null or not is_instance_valid(enemy):
		return global_position
	var collision_shape := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		return collision_shape.global_position
	return enemy.global_position + Vector2(0.0, -12.0)


func _get_arrow_projectile_scene() -> PackedScene:
	if is_instance_valid(lizard_arrow_projectile_scene_cache):
		return lizard_arrow_projectile_scene_cache
	var loaded_scene := load(LIZARD_ARROW_PROJECTILE_SCENE_PATH)
	if loaded_scene is PackedScene:
		lizard_arrow_projectile_scene_cache = loaded_scene as PackedScene
	return lizard_arrow_projectile_scene_cache
