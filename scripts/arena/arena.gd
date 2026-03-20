extends Node2D
class_name Arena

enum EncounterType {
	MINOTAUR,
	CACODEMON,
	SHARDSOUL,
	COBRA,
	COBRA_TWO_ROOM_TEST
}

signal player_health_changed(current: float, maximum: float)
signal player_xp_changed(current: int, needed: int, level: int)
signal cooldowns_changed(values: Dictionary)
signal objective_changed(text: String)
signal item_collected(item_name: String, total_owned: int)
signal player_died
signal demo_won
signal combat_debug_changed(values: Dictionary)
signal status_message(text: String, duration: float)
signal two_room_chest_item_received(item_id: String)

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const FRIENDLY_HEALER_SCENE: PackedScene = preload("res://scenes/npcs/FriendlyHealer.tscn")
const FRIENDLY_RATFOLK_SCENE: PackedScene = preload("res://scenes/npcs/FriendlyRatfolk.tscn")
const FRIENDLY_LIZARDFOLK_SCENE: PackedScene = preload("res://scenes/npcs/FriendlyLizardfolk.tscn")
const MELEE_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/MeleeEnemy.tscn")
const ITEM_SCENE: PackedScene = preload("res://scenes/items/ItemPickup.tscn")
const DEFAULT_DUNGEON_TILESET_TEXTURE: Texture2D = preload("res://assets/external/ElthenAssets/tilesets/dungeon/Dungeon_Tileset.png")
const ARENA_TILESET_TEXTURE: Texture2D = preload("res://assets/external/ElthenAssets/tilesets/arena/Arena Tileset.png")
const COMPANION_BREATH_RESPONSE_SCRIPT := preload("res://ai/CompanionBreathResponse.gd")
const IMP_SUMMON_PENTAGRAM_EFFECT_SCRIPT := preload("res://scripts/effects/imp_summon_pentagram.gd")
const PARTY_MEMBER_TANK: String = "tank"
const PARTY_MEMBER_HEALER: String = "healer"
const PARTY_MEMBER_RATFOLK: String = "ratfolk"
const PARTY_MEMBER_LIZARDFOLK: String = "lizardfolk"
const CONTROLLED_CHARACTER_TANK: String = "tank"
const CONTROLLED_CHARACTER_HEALER: String = "healer"
const CONTROLLED_CHARACTER_RATFOLK: String = "ratfolk"
const CONTROLLED_CHARACTER_LIZARDFOLK: String = "lizardfolk"
const MAX_PARTY_SIZE: int = 3
const PARTY_MEMBER_LABELS: Dictionary = {
	PARTY_MEMBER_TANK: "Tank",
	PARTY_MEMBER_HEALER: "Healer",
	PARTY_MEMBER_RATFOLK: "Ratfolk Rogue",
	PARTY_MEMBER_LIZARDFOLK: "Lizardfolk Archer"
}
const PARTY_MEMBER_DESCRIPTIONS: Dictionary = {
	PARTY_MEMBER_TANK: "Frontline fighter (disable only while controlling another ally).",
	PARTY_MEMBER_HEALER: "Sustains the party with healing and support.",
	PARTY_MEMBER_RATFOLK: "Mobile DPS that marks enemies and pressures targets.",
	PARTY_MEMBER_LIZARDFOLK: "Ranged skirmisher companion with agile positioning."
}
const TWO_ROOM_SWORD_PICKUP_IDS: Array[String] = [
	"sword_extended_charge",
	"sword_slowing",
	"sword_stacking_dot"
]
const TWO_ROOM_SHIELD_PICKUP_IDS: Array[String] = [
	"shield_revenge",
	"shield_thorns",
	"shield_wide_guard"
]
const TWO_ROOM_BOOT_PICKUP_IDS: Array[String] = [
	"swift_boots",
	"strider_boots",
	"bodyguard_boots"
]
const TWO_ROOM_RING_PICKUP_IDS: Array[String] = [
	"ring_bulwark",
	"ring_berserker",
	"ring_shield"
]
const TWO_ROOM_SWORD_PICKUP_BY_SWORD_ID: Dictionary = {
	"extended_charge": "sword_extended_charge",
	"slowing": "sword_slowing",
	"stacking_dot": "sword_stacking_dot"
}
const TWO_ROOM_SHIELD_PICKUP_BY_SHIELD_ID: Dictionary = {
	"revenge_shield": "shield_revenge",
	"thorns_shield": "shield_thorns",
	"wide_guard_shield": "shield_wide_guard"
}
const TWO_ROOM_RING_PICKUP_BY_RING_ID: Dictionary = {
	"bulwark": "ring_bulwark",
	"berserker": "ring_berserker",
	"shield": "ring_shield"
}
const TWO_ROOM_TEST_TOTAL_ROOMS: int = 6

@export var regular_enemy_count: int = 1
@export var allow_multiple_minotaurs: bool = true
@export var max_active_minotaurs: int = 2
@export var timed_extra_minotaur_enabled: bool = true
@export var timed_extra_minotaur_delay: float = 12.0
@export var spawn_jitter: float = 18.0
@export var encounter_initial_enemy_distance_scale: float = 1.55
@export var encounter_initial_enemy_min_party_distance: float = 360.0
@export var encounter_initial_enemy_max_party_distance: float = 700.0
@export var encounter_initial_enemy_min_enemy_distance: float = 132.0
@export var encounter_spawn_reposition_step: float = 52.0
@export var encounter_spawn_reposition_attempts: int = 12
@export var encounter_pair_vertical_spacing: float = 124.0
@export var encounter_edge_spawn_inset: float = 22.0
@export var encounter_spacing_debug_logging: bool = false
@export var encounter_spacing_debug_opening_window: float = 6.0
@export var encounter_spacing_debug_log_interval: float = 0.85
@export var arena_min_x: float = -760.0
@export var arena_max_x: float = 760.0
@export var arena_min_y: float = -165.0
@export var arena_max_y: float = 165.0
@export var camera_limit_padding: Vector2 = Vector2(84.0, 60.0)
@export var summoned_minion_edge_inset: float = 28.0
@export var summoned_minion_y_spacing: float = 34.0
@export var summoned_imp_spawn_distance_x: float = 88.0
@export var summoned_imp_spawn_x_stagger: float = 18.0
@export var summoned_minion_health_scale: float = 0.68
@export var summoned_imp_health_multiplier: float = 0.75
@export var summoned_minion_speed_scale: float = 0.9
@export var summoned_minion_damage_scale: float = 0.82
@export var summoned_imp_damage_multiplier: float = 0.5
@export var summoned_minion_xp_scale: float = 0.35
@export var miniboss_health_scale: float = 4.0
@export var cobra_health_scale: float = 1.26
@export var cobra_damage_scale: float = 0.62
@export var imp_summon_pentagram_enabled: bool = true
@export var imp_summon_pentagram_y_offset: float = 12.0
@export var summoned_imp_spawn_stagger: float = 0.04
@export var two_room_test_room_edge_inset: float = 18.0
@export var two_room_test_room_gap: float = 52.0
@export var two_room_test_exit_width: float = 32.0
@export var two_room_test_exit_height: float = 124.0
@export var two_room_test_right_exit_center_inset: float = 0.0
@export var two_room_test_transition_delay: float = 0.25
@export var two_room_test_spawn_margin_x: float = 78.0
@export var two_room_test_spawn_vertical_spacing: float = 78.0
@export var two_room_test_second_room_offset_x: float = 1040.0
@export var two_room_test_second_room_offset_y: float = 0.0
@export var two_room_test_third_room_offset_x: float = 2080.0
@export var two_room_test_third_room_offset_y: float = 0.0
@export var two_room_test_fourth_room_offset_x: float = 3120.0
@export var two_room_test_fourth_room_offset_y: float = 0.0
@export var two_room_test_fifth_room_offset_x: float = 4160.0
@export var two_room_test_fifth_room_offset_y: float = 0.0
@export var two_room_test_sixth_room_offset_x: float = 5200.0
@export var two_room_test_sixth_room_offset_y: float = 0.0
@export var two_room_test_room2_right_spawn_band_start_ratio: float = 0.84
@export var two_room_test_room2_right_spawn_inset: float = 26.0
@export var two_room_test_room2_spawn_center_pull_ratio: float = 0.3
@export var two_room_test_room3_spawn_center_pull_ratio: float = 0.35
@export var two_room_test_room4_spawn_center_pull_ratio: float = 0.48
@export var two_room_test_room2_healer_cage_y_offset: float = -46.0
@export var two_room_test_room3_rat_cage_y_offset: float = -46.0
@export var two_room_test_room6_lizard_cage_y_offset: float = -46.0
@export var two_room_test_cage_width: float = 68.0
@export var two_room_test_cage_height: float = 78.0
@export var two_room_test_companion_transition_spacing: float = 40.0
@export var two_room_test_final_chest_offset_x: float = 0.0
@export var two_room_test_final_chest_offset_y: float = 0.0
@export var two_room_test_chest_width: float = 56.0
@export var two_room_test_chest_height: float = 42.0
@export var two_room_test_return_portal_offset_x: float = 0.0
@export var two_room_test_return_portal_offset_y: float = 84.0
@export var two_room_test_return_portal_width: float = 86.0
@export var two_room_test_return_portal_height: float = 44.0

@onready var actors: Node2D = $Actors
@onready var drops: Node2D = $Drops
@onready var spawn_points: Array[Node] = $SpawnPoints.get_children()
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var healer_spawn: Marker2D = get_node_or_null("HealerSpawn") as Marker2D
@onready var ratfolk_spawn: Marker2D = get_node_or_null("RatfolkSpawn") as Marker2D
@onready var lizardfolk_spawn: Marker2D = get_node_or_null("LizardfolkSpawn") as Marker2D
@onready var floor_root: Node2D = get_node_or_null("Floor") as Node2D

var player: Player = null
var healer: Node2D = null
var ratfolk: Node2D = null
var lizardfolk: Node2D = null
var tank_party_enabled: bool = true
var tank_collision_layer_cache: int = 0
var tank_collision_mask_cache: int = 0
var tank_state_cached: bool = false
var party_member_enabled_by_id: Dictionary = {
	PARTY_MEMBER_HEALER: true,
	PARTY_MEMBER_RATFOLK: true,
	PARTY_MEMBER_LIZARDFOLK: false
}
var party_member_toggle_failure_reason: String = ""
var controlled_character_id: String = CONTROLLED_CHARACTER_TANK
var adventure_start_control_id: String = CONTROLLED_CHARACTER_TANK
var control_target_failure_reason: String = ""
var alive_regular_enemies: int = 0
var demo_started: bool = false
var spawn_next_debug_enemy_on_left: bool = true
var demo_elapsed: float = 0.0
var timed_extra_minotaur_spawned: bool = false
var initial_minotaur_spawn_on_left: bool = false
var spawned_minotaurs_total: int = 0
var selected_encounter: int = EncounterType.MINOTAUR
var rng := RandomNumberGenerator.new()
var hitbox_debug_mode_enabled: bool = false
var hitbox_debug_sync_left: float = 0.0
var spacing_debug_runtime_enabled: bool = false
var spacing_debug_next_log_at: float = 0.0
var two_room_test_active: bool = false
var two_room_test_room_index: int = 0
var two_room_test_transition_in_progress: bool = false
var two_room_force_next_transition_spawn_on_left: bool = false
var two_room_exit_root: Node2D = null
var two_room_exit_area: Area2D = null
var two_room_second_floor_root: Node2D = null
var two_room_third_floor_root: Node2D = null
var two_room_fourth_floor_root: Node2D = null
var two_room_fifth_floor_root: Node2D = null
var two_room_sixth_floor_root: Node2D = null
var two_room_cage_root: Node2D = null
var two_room_cage_area: Area2D = null
var two_room_caged_healer: Node2D = null
var two_room_caged_rat: Node2D = null
var two_room_caged_lizard: Node2D = null
var two_room_caged_tank: Node2D = null
var two_room_chest_root: Node2D = null
var two_room_chest_area: Area2D = null
var two_room_return_portal_root: Node2D = null
var two_room_return_portal_area: Area2D = null
var two_room_healer_released: bool = false
var two_room_rat_released: bool = false
var two_room_lizard_released: bool = false
var two_room_final_chest_opened: bool = false
var two_room_loot_drop_count: int = 0
var tank_caged_active: bool = false
var adventure_tank_cage_room_index: int = 0
var party_defeat_emitted: bool = false
var default_floor_tileset_texture: Texture2D = null


func _ready() -> void:
	if _is_autoplay_requested():
		rng.seed = 1337
	else:
		rng.randomize()
	_enforce_companion_selection_limit()
	spacing_debug_runtime_enabled = encounter_spacing_debug_logging or _is_env_flag_enabled("ENCOUNTER_SPACING_DEBUG")
	if is_instance_valid(floor_root):
		var configured_tileset: Variant = floor_root.get("dungeon_tileset_texture")
		if configured_tileset is Texture2D:
			default_floor_tileset_texture = configured_tileset as Texture2D
	if default_floor_tileset_texture == null:
		default_floor_tileset_texture = DEFAULT_DUNGEON_TILESET_TEXTURE


func _process(delta: float) -> void:
	if not demo_started:
		return
	demo_elapsed += maxf(0.0, delta)
	if hitbox_debug_mode_enabled:
		hitbox_debug_sync_left = maxf(0.0, hitbox_debug_sync_left - maxf(0.0, delta))
		if hitbox_debug_sync_left <= 0.0:
			hitbox_debug_sync_left = 0.2
			_sync_hitbox_debug_mode()
	_maybe_log_opening_spacing()
	_try_spawn_timed_extra_minotaur()
	_sync_control_mode_availability()
	_sync_tank_proxy_position()
	_emit_combat_debug()
	_emit_manual_control_cooldowns()
	_try_auto_activate_two_room_exit_if_ready()
	_try_auto_activate_two_room_return_portal_if_ready()


func start_demo_with_encounter(encounter_type: int) -> void:
	set_encounter_type(encounter_type)
	start_demo()


func set_encounter_type(encounter_type: int) -> void:
	if encounter_type == EncounterType.COBRA:
		selected_encounter = EncounterType.COBRA
	elif encounter_type == EncounterType.COBRA_TWO_ROOM_TEST:
		selected_encounter = EncounterType.COBRA_TWO_ROOM_TEST
	elif encounter_type == EncounterType.CACODEMON:
		selected_encounter = EncounterType.CACODEMON
	elif encounter_type == EncounterType.SHARDSOUL:
		selected_encounter = EncounterType.SHARDSOUL
	else:
		selected_encounter = EncounterType.MINOTAUR


func _encounter_uses_companions() -> bool:
	return selected_encounter != EncounterType.COBRA and selected_encounter != EncounterType.COBRA_TWO_ROOM_TEST


func get_max_party_size() -> int:
	return MAX_PARTY_SIZE


func get_party_member_toggle_failure_reason() -> String:
	return party_member_toggle_failure_reason


func get_control_target_failure_reason() -> String:
	return control_target_failure_reason


func get_controlled_character_id() -> String:
	return controlled_character_id


func get_adventure_start_character_id() -> String:
	return adventure_start_control_id


func set_adventure_start_character(control_id: String) -> bool:
	var normalized := control_id.strip_edges().to_lower()
	if normalized == "rat":
		normalized = CONTROLLED_CHARACTER_RATFOLK
	if normalized != CONTROLLED_CHARACTER_TANK and normalized != CONTROLLED_CHARACTER_HEALER and normalized != CONTROLLED_CHARACTER_RATFOLK:
		return false
	adventure_start_control_id = normalized
	return true


func get_controlled_inventory_actor() -> Object:
	if controlled_character_id == CONTROLLED_CHARACTER_HEALER and is_instance_valid(healer):
		return healer
	if controlled_character_id == CONTROLLED_CHARACTER_RATFOLK and is_instance_valid(ratfolk):
		return ratfolk
	if controlled_character_id == CONTROLLED_CHARACTER_LIZARDFOLK and is_instance_valid(lizardfolk):
		return lizardfolk
	if is_instance_valid(player):
		return player
	if is_instance_valid(healer):
		return healer
	if is_instance_valid(ratfolk):
		return ratfolk
	if is_instance_valid(lizardfolk):
		return lizardfolk
	return null


func _get_controlled_adventure_interaction_actor() -> Node:
	if _is_manual_healer_control_active() and is_instance_valid(healer):
		return healer
	if _is_manual_ratfolk_control_active() and is_instance_valid(ratfolk):
		return ratfolk
	if _is_manual_lizardfolk_control_active() and is_instance_valid(lizardfolk):
		return lizardfolk
	if is_instance_valid(player):
		return player
	return get_controlled_inventory_actor() as Node


func get_controlled_character_display_name() -> String:
	if controlled_character_id == CONTROLLED_CHARACTER_HEALER:
		return "Healer"
	if controlled_character_id == CONTROLLED_CHARACTER_RATFOLK:
		return "Ratfolk"
	if controlled_character_id == CONTROLLED_CHARACTER_LIZARDFOLK:
		return "Lizardfolk"
	return "Tank"


func get_control_target_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	entries.append({
		"id": CONTROLLED_CHARACTER_TANK,
		"name": "Tank",
		"description": "Directly control the tank fighter.",
		"available": is_instance_valid(player) and tank_party_enabled,
		"selected": controlled_character_id == CONTROLLED_CHARACTER_TANK
	})
	var healer_available := _is_healer_control_available()
	entries.append({
		"id": CONTROLLED_CHARACTER_HEALER,
		"name": "Healer",
		"description": "Directly control the healer; tank fights with AI.",
		"available": healer_available,
		"selected": controlled_character_id == CONTROLLED_CHARACTER_HEALER
	})
	var ratfolk_available := _is_ratfolk_control_available()
	entries.append({
		"id": CONTROLLED_CHARACTER_RATFOLK,
		"name": "Ratfolk",
		"description": "Directly control the ratfolk striker; tank fights with AI.",
		"available": ratfolk_available,
		"selected": controlled_character_id == CONTROLLED_CHARACTER_RATFOLK
	})
	var lizardfolk_available := _is_lizardfolk_control_available()
	entries.append({
		"id": CONTROLLED_CHARACTER_LIZARDFOLK,
		"name": "Lizardfolk",
		"description": "Directly control the lizard ranger; tank fights with AI.",
		"available": lizardfolk_available,
		"selected": controlled_character_id == CONTROLLED_CHARACTER_LIZARDFOLK
	})
	return entries


func set_controlled_character(control_id: String) -> bool:
	control_target_failure_reason = ""
	var normalized_control_id := control_id.strip_edges().to_lower()
	if normalized_control_id != CONTROLLED_CHARACTER_TANK and normalized_control_id != CONTROLLED_CHARACTER_HEALER and normalized_control_id != CONTROLLED_CHARACTER_RATFOLK and normalized_control_id != CONTROLLED_CHARACTER_LIZARDFOLK:
		control_target_failure_reason = "Unknown controlled character."
		return false
	if normalized_control_id == CONTROLLED_CHARACTER_TANK and not tank_party_enabled:
		control_target_failure_reason = "Tank is locked in a cage." if tank_caged_active else "Tank is disabled while controlling another ally."
		return false
	if normalized_control_id == CONTROLLED_CHARACTER_HEALER and not _is_healer_control_available():
		control_target_failure_reason = "Healer control is unavailable right now."
		return false
	if normalized_control_id == CONTROLLED_CHARACTER_RATFOLK and not _is_ratfolk_control_available():
		control_target_failure_reason = "Ratfolk control is unavailable right now."
		return false
	if normalized_control_id == CONTROLLED_CHARACTER_LIZARDFOLK and not _is_lizardfolk_control_available():
		control_target_failure_reason = "Lizardfolk control is unavailable right now."
		return false
	if controlled_character_id == normalized_control_id:
		return false
	controlled_character_id = normalized_control_id
	_apply_control_mode_runtime()
	return true


func _get_max_companion_count() -> int:
	return maxi(0, MAX_PARTY_SIZE - 1)


func _get_enabled_companion_count() -> int:
	var count := 0
	for member_id_variant in [PARTY_MEMBER_HEALER, PARTY_MEMBER_RATFOLK, PARTY_MEMBER_LIZARDFOLK]:
		var member_id := String(member_id_variant)
		if two_room_test_active:
			if _is_party_member_active(member_id):
				count += 1
		elif bool(party_member_enabled_by_id.get(member_id, false)):
			count += 1
	return count


func _is_party_member_unlocked_for_menu(member_id: String) -> bool:
	if not two_room_test_active:
		return true
	match member_id:
		PARTY_MEMBER_HEALER:
			return two_room_healer_released
		PARTY_MEMBER_RATFOLK:
			return two_room_rat_released
		PARTY_MEMBER_LIZARDFOLK:
			return two_room_lizard_released
		_:
			return false


func get_party_member_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var companions_available_now := _encounter_uses_companions()
	var visible_member_ids: Array[String] = []
	for member_id_variant in [PARTY_MEMBER_HEALER, PARTY_MEMBER_RATFOLK, PARTY_MEMBER_LIZARDFOLK]:
		var member_id := String(member_id_variant)
		if _is_party_member_unlocked_for_menu(member_id):
			visible_member_ids.append(member_id)
	var enabled_companion_count := 0
	for member_id in visible_member_ids:
		if two_room_test_active:
			if _is_party_member_active(member_id):
				enabled_companion_count += 1
		elif bool(party_member_enabled_by_id.get(member_id, false)):
			enabled_companion_count += 1
	var max_companion_count := _get_max_companion_count()
	var display_enabled_companion_count := enabled_companion_count if companions_available_now or two_room_test_active else 0
	var active_party_size := 1 + display_enabled_companion_count
	if controlled_character_id != CONTROLLED_CHARACTER_TANK:
		var tank_available := is_instance_valid(player) and not tank_caged_active
		entries.append({
			"id": PARTY_MEMBER_TANK,
			"name": String(PARTY_MEMBER_LABELS.get(PARTY_MEMBER_TANK, "Tank")),
			"description": String(PARTY_MEMBER_DESCRIPTIONS.get(PARTY_MEMBER_TANK, "Frontline fighter.")),
			"enabled": tank_party_enabled,
			"active": tank_party_enabled and tank_available,
			"available": tank_available,
			"blocked_by_party_limit": false,
			"enabled_companion_count": display_enabled_companion_count,
			"max_companion_count": max_companion_count,
			"active_party_size": active_party_size,
			"max_party_size": MAX_PARTY_SIZE
		})
	for member_id in visible_member_ids:
		var member_name := String(PARTY_MEMBER_LABELS.get(member_id, member_id))
		var member_description := String(PARTY_MEMBER_DESCRIPTIONS.get(member_id, "Companion option."))
		var enabled := bool(party_member_enabled_by_id.get(member_id, true))
		if two_room_test_active:
			enabled = _is_party_member_active(member_id)
		var blocked_by_party_limit := companions_available_now and (not enabled) and display_enabled_companion_count >= max_companion_count
		entries.append({
			"id": member_id,
			"name": member_name,
			"description": member_description,
			"enabled": enabled,
			"active": _is_party_member_active(member_id),
			"available": companions_available_now,
			"blocked_by_party_limit": blocked_by_party_limit,
			"enabled_companion_count": display_enabled_companion_count,
			"max_companion_count": max_companion_count,
			"active_party_size": active_party_size,
			"max_party_size": MAX_PARTY_SIZE
		})
	return entries


func set_party_member_enabled(member_id: String, enabled: bool) -> bool:
	party_member_toggle_failure_reason = ""
	var normalized_member_id := member_id.strip_edges().to_lower()
	if not PARTY_MEMBER_LABELS.has(normalized_member_id):
		party_member_toggle_failure_reason = "Unknown party member."
		return false
	if normalized_member_id == PARTY_MEMBER_TANK:
		if not is_instance_valid(player):
			party_member_toggle_failure_reason = "Tank is unavailable."
			return false
		if tank_caged_active and bool(enabled):
			party_member_toggle_failure_reason = "Tank is locked in a cage."
			return false
		if controlled_character_id == CONTROLLED_CHARACTER_TANK and not bool(enabled):
			party_member_toggle_failure_reason = "Switch control before disabling the tank."
			return false
		var next_tank_enabled := bool(enabled)
		if tank_party_enabled == next_tank_enabled:
			return false
		tank_party_enabled = next_tank_enabled
		_apply_tank_party_state()
		return true
	var next_enabled := bool(enabled)
	var previous_enabled := bool(party_member_enabled_by_id.get(normalized_member_id, true))
	if previous_enabled == next_enabled:
		return false
	if next_enabled and _get_enabled_companion_count() >= _get_max_companion_count():
		party_member_toggle_failure_reason = "Party is full (max 3 total including Player)."
		return false
	party_member_enabled_by_id[normalized_member_id] = next_enabled
	if demo_started and _encounter_uses_companions():
		if two_room_test_active:
			if not _is_party_member_unlocked_for_menu(normalized_member_id):
				party_member_toggle_failure_reason = "Companion not rescued yet."
				party_member_enabled_by_id[normalized_member_id] = previous_enabled
				return false
			if next_enabled:
				if normalized_member_id == PARTY_MEMBER_HEALER and not is_instance_valid(healer):
					_spawn_friendly_healer()
				elif normalized_member_id == PARTY_MEMBER_RATFOLK and not is_instance_valid(ratfolk):
					_spawn_friendly_ratfolk()
				elif normalized_member_id == PARTY_MEMBER_LIZARDFOLK and not is_instance_valid(lizardfolk):
					_spawn_friendly_lizardfolk()
			else:
				_despawn_companion(normalized_member_id)
		else:
			_apply_party_selection_runtime()
	return true


func _is_party_member_active(member_id: String) -> bool:
	if member_id == PARTY_MEMBER_HEALER:
		return is_instance_valid(healer)
	if member_id == PARTY_MEMBER_RATFOLK:
		return is_instance_valid(ratfolk)
	if member_id == PARTY_MEMBER_LIZARDFOLK:
		return is_instance_valid(lizardfolk)
	return false


func _is_party_member_enabled(member_id: String, default_enabled: bool = true) -> bool:
	return bool(party_member_enabled_by_id.get(member_id, default_enabled))


func _enforce_companion_selection_limit() -> void:
	var max_companions := _get_max_companion_count()
	var keep_order: Array[String] = [PARTY_MEMBER_RATFOLK, PARTY_MEMBER_HEALER, PARTY_MEMBER_LIZARDFOLK]
	var kept := 0
	for member_id in keep_order:
		if not bool(party_member_enabled_by_id.get(member_id, false)):
			continue
		kept += 1
		if kept <= max_companions:
			continue
		party_member_enabled_by_id[member_id] = false


func _apply_party_selection_runtime() -> void:
	if not _encounter_uses_companions() or two_room_test_active:
		_apply_control_mode_runtime()
		return
	_enforce_companion_selection_limit()
	if _is_party_member_enabled(PARTY_MEMBER_HEALER, true):
		if not is_instance_valid(healer):
			_spawn_friendly_healer()
	else:
		_despawn_companion(PARTY_MEMBER_HEALER)
	if _is_party_member_enabled(PARTY_MEMBER_RATFOLK, true):
		if not is_instance_valid(ratfolk):
			_spawn_friendly_ratfolk()
	else:
		_despawn_companion(PARTY_MEMBER_RATFOLK)
	if _is_party_member_enabled(PARTY_MEMBER_LIZARDFOLK, true):
		if not is_instance_valid(lizardfolk):
			_spawn_friendly_lizardfolk()
	else:
		_despawn_companion(PARTY_MEMBER_LIZARDFOLK)
	_apply_control_mode_runtime()
	_sync_hitbox_debug_mode()


func _cache_tank_runtime_state() -> void:
	if tank_state_cached:
		return
	if not is_instance_valid(player):
		return
	tank_collision_layer_cache = player.collision_layer
	tank_collision_mask_cache = player.collision_mask
	tank_state_cached = true


func _disable_tank_actor() -> void:
	if not is_instance_valid(player):
		return
	_cache_tank_runtime_state()
	if player.is_in_group("player"):
		player.remove_from_group("player")
	player.visible = false
	player.collision_layer = 0
	player.collision_mask = 0
	player.set_process(false)
	player.set_physics_process(false)
	player.set_process_input(false)


func _enable_tank_actor() -> void:
	if not is_instance_valid(player):
		return
	_cache_tank_runtime_state()
	if not player.is_in_group("player"):
		player.add_to_group("player")
	player.visible = true
	if tank_state_cached:
		player.collision_layer = tank_collision_layer_cache
		player.collision_mask = tank_collision_mask_cache
	player.set_process(true)
	player.set_physics_process(true)
	player.set_process_input(true)


func _apply_tank_party_state() -> void:
	if tank_party_enabled:
		_enable_tank_actor()
	else:
		_disable_tank_actor()
	_apply_control_mode_runtime()


func _sync_tank_proxy_position() -> void:
	if tank_party_enabled:
		return
	if not is_instance_valid(player):
		return
	var proxy := get_controlled_inventory_actor() as Node2D
	if proxy == null or proxy == player:
		return
	player.global_position = proxy.global_position


func _despawn_companion(member_id: String) -> void:
	if member_id == PARTY_MEMBER_HEALER:
		if is_instance_valid(healer):
			healer.queue_free()
		healer = null
		_apply_control_mode_runtime()
		return
	if member_id == PARTY_MEMBER_RATFOLK:
		if is_instance_valid(ratfolk):
			ratfolk.queue_free()
		ratfolk = null
		_apply_control_mode_runtime()
		return
	if member_id == PARTY_MEMBER_LIZARDFOLK:
		if is_instance_valid(lizardfolk):
			lizardfolk.queue_free()
		lizardfolk = null
		_apply_control_mode_runtime()


func _get_fallback_lizard_spawn_position() -> Vector2:
	if is_instance_valid(ratfolk):
		return ratfolk.global_position + Vector2(-26.0, -38.0)
	if is_instance_valid(healer):
		return healer.global_position + Vector2(-18.0, 36.0)
	if is_instance_valid(player):
		return player.global_position + Vector2(-42.0, -28.0)
	return global_position + Vector2(-240.0, -42.0)


func start_demo() -> void:
	if demo_started:
		return
	demo_started = true
	demo_elapsed = 0.0
	spacing_debug_next_log_at = 0.0
	timed_extra_minotaur_spawned = false
	initial_minotaur_spawn_on_left = false
	spawned_minotaurs_total = 0
	party_defeat_emitted = false
	two_room_test_active = false
	two_room_test_room_index = 0
	two_room_test_transition_in_progress = false
	two_room_force_next_transition_spawn_on_left = false
	two_room_healer_released = false
	two_room_rat_released = false
	two_room_lizard_released = false
	two_room_final_chest_opened = false
	two_room_loot_drop_count = 0
	tank_caged_active = false
	adventure_tank_cage_room_index = 0
	_teardown_two_room_exit()
	_teardown_two_room_cage()
	_teardown_two_room_chest()
	_teardown_two_room_return_portal()
	_teardown_two_room_second_play_area()
	_teardown_two_room_third_play_area()
	_teardown_two_room_fourth_play_area()
	_teardown_two_room_fifth_play_area()
	_teardown_two_room_sixth_play_area()
	_apply_floor_tileset_to_node(floor_root, _get_default_floor_tileset_texture())
	_spawn_player()
	if _encounter_uses_companions():
		_apply_party_selection_runtime()
	else:
		healer = null
		ratfolk = null
		lizardfolk = null
		_apply_control_mode_runtime()
	_prewarm_imp_summon_effect_cache()
	_spawn_regular_enemies()
	_log_encounter_spacing_snapshot("spawn_init")
	_sync_hitbox_debug_mode()
	_update_objective()
	broadcast_current_state()


func broadcast_current_state() -> void:
	if is_instance_valid(player):
		player.emit_initial_state()
	_update_objective()


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	if player == null:
		push_error("Failed to instantiate player scene.")
		return
	actors.add_child(player)
	player.global_position = player_spawn.global_position
	_apply_bounds_to_player(player)
	_apply_hitbox_debug_to_node(player)

	player.health_changed.connect(_on_player_health_changed)
	player.xp_changed.connect(_on_player_xp_changed)
	player.cooldowns_changed.connect(_on_player_cooldowns_changed)
	player.item_looted.connect(_on_player_item_looted)
	player.died.connect(_on_player_died)
	if player.has_signal("combat_status_message"):
		player.combat_status_message.connect(_on_player_combat_status_message)
	_cache_tank_runtime_state()
	_apply_tank_party_state()
	if player.has_method("set_level_up_full_heal_enabled"):
		var enable_full_heal := selected_encounter != EncounterType.COBRA_TWO_ROOM_TEST
		player.call("set_level_up_full_heal_enabled", enable_full_heal)


func _spawn_friendly_healer() -> void:
	if not is_instance_valid(healer_spawn):
		return
	healer = FRIENDLY_HEALER_SCENE.instantiate() as Node2D
	if healer == null:
		push_error("Failed to instantiate friendly healer scene.")
		return
	actors.add_child(healer)
	healer.global_position = healer_spawn.global_position
	_apply_hitbox_debug_to_node(healer)
	_connect_companion_died(healer)
	if healer.has_method("set_player") and is_instance_valid(player):
		healer.set_player(player)
	if healer.has_method("set_manual_control_enabled"):
		healer.call("set_manual_control_enabled", false)
	_apply_control_mode_runtime()


func _spawn_friendly_ratfolk() -> void:
	if not is_instance_valid(ratfolk_spawn):
		return
	ratfolk = FRIENDLY_RATFOLK_SCENE.instantiate() as Node2D
	if ratfolk == null:
		push_error("Failed to instantiate friendly ratfolk scene.")
		return
	actors.add_child(ratfolk)
	ratfolk.global_position = ratfolk_spawn.global_position
	_apply_hitbox_debug_to_node(ratfolk)
	_connect_companion_died(ratfolk)
	if ratfolk.has_method("set_player") and is_instance_valid(player):
		ratfolk.set_player(player)
	if ratfolk.has_method("set_arena_bounds"):
		ratfolk.call("set_arena_bounds", arena_min_x, arena_max_x, arena_min_y, arena_max_y)
	if ratfolk.has_method("set_manual_control_enabled"):
		ratfolk.call("set_manual_control_enabled", false)
	_apply_control_mode_runtime()


func _spawn_friendly_lizardfolk() -> void:
	if is_instance_valid(lizardfolk):
		return
	lizardfolk = FRIENDLY_LIZARDFOLK_SCENE.instantiate() as Node2D
	if lizardfolk == null:
		push_error("Failed to instantiate friendly lizardfolk scene.")
		return
	actors.add_child(lizardfolk)
	if is_instance_valid(lizardfolk_spawn):
		lizardfolk.global_position = lizardfolk_spawn.global_position
	else:
		lizardfolk.global_position = _get_fallback_lizard_spawn_position()
	_apply_hitbox_debug_to_node(lizardfolk)
	_connect_companion_died(lizardfolk)
	if lizardfolk.has_method("set_player") and is_instance_valid(player):
		lizardfolk.call("set_player", player)
	if lizardfolk.has_method("set_arena_bounds"):
		lizardfolk.call("set_arena_bounds", arena_min_x, arena_max_x, arena_min_y, arena_max_y)
	if lizardfolk.has_method("set_manual_control_enabled"):
		lizardfolk.call("set_manual_control_enabled", false)


func _spawn_regular_enemies() -> void:
	alive_regular_enemies = 0
	if is_instance_valid(player):
		if selected_encounter == EncounterType.COBRA_TWO_ROOM_TEST and player.has_method("reset_sword_inventory_for_encounter"):
			player.call("reset_sword_inventory_for_encounter")
		elif player.has_method("restore_default_sword_inventory"):
			player.call("restore_default_sword_inventory")
	if selected_encounter == EncounterType.COBRA_TWO_ROOM_TEST:
		_spawn_two_room_cobra_test()
		return
	if selected_encounter == EncounterType.COBRA:
		_spawn_cobra_encounter()
		return
	if selected_encounter == EncounterType.CACODEMON:
		_spawn_cacodemon_encounter()
		return
	if selected_encounter == EncounterType.SHARDSOUL:
		_spawn_shardsoul_encounter()
		return
	var spawn_count := regular_enemy_count
	var minotaur_cap := _get_minotaur_spawn_cap()
	spawn_count = mini(spawn_count, minotaur_cap)
	if spawn_count >= 2:
		var pair_offset := maxf(20.0, encounter_pair_vertical_spacing * 0.5)
		_spawn_edge_minotaur_on_side(false, -pair_offset)
		_spawn_edge_minotaur_on_side(false, pair_offset)
		spawn_count -= 2
	if spawn_count <= 0:
		return
	if spawn_points.is_empty():
		push_error("No spawn points configured in Arena scene.")
		return
	for i in spawn_count:
		var spawn_marker := spawn_points[rng.randi_range(0, spawn_points.size() - 1)] as Marker2D
		if spawn_marker == null:
			continue
		var spawn_position := spawn_marker.global_position + Vector2(
			rng.randf_range(-spawn_jitter, spawn_jitter),
			rng.randf_range(-spawn_jitter, spawn_jitter)
		)
		spawn_position = _resolve_encounter_spawn_position(spawn_position)
		var enemy := _spawn_enemy(MELEE_ENEMY_SCENE, spawn_position)
		if enemy == null:
			continue
		_configure_miniboss(enemy)
		if alive_regular_enemies <= 0:
			initial_minotaur_spawn_on_left = spawn_position.x < _get_arena_center_x()
		alive_regular_enemies += 1
		spawned_minotaurs_total += 1


func spawn_debug_minotaur_alternating() -> void:
	if not demo_started:
		return
	if selected_encounter != EncounterType.MINOTAUR:
		return
	if not _can_spawn_additional_minotaur():
		return
	_spawn_edge_minotaur()


func _try_spawn_timed_extra_minotaur() -> void:
	if selected_encounter != EncounterType.MINOTAUR:
		return
	if not timed_extra_minotaur_enabled:
		return
	if timed_extra_minotaur_spawned:
		return
	if not _can_spawn_additional_minotaur():
		return
	if alive_regular_enemies <= 0:
		return
	if demo_elapsed < maxf(0.0, timed_extra_minotaur_delay):
		return
	timed_extra_minotaur_spawned = true
	_spawn_edge_minotaur_on_side(initial_minotaur_spawn_on_left)


func _spawn_cacodemon_encounter() -> void:
	_spawn_air_boss_encounter(int(EnemyBase.MonsterVisualProfile.CACODEMON))


func _spawn_shardsoul_encounter() -> void:
	_spawn_air_boss_encounter(int(EnemyBase.MonsterVisualProfile.SHARDSOUL))


func _spawn_cobra_encounter() -> void:
	var enemy := _spawn_ground_boss_encounter(int(EnemyBase.MonsterVisualProfile.COBRA))
	if enemy == null:
		return
	_configure_cobra_enemy(enemy, true)


func _configure_cobra_enemy(enemy: EnemyBase, as_miniboss: bool = false) -> void:
	if enemy == null:
		return
	var cobra_range_scale := 0.5
	var cobra_attack_range_multiplier := 1.3
	if as_miniboss:
		_configure_miniboss(enemy)
	else:
		enemy.is_miniboss = false
		enemy.boss_can_summon_minions = false
		enemy.boss_summon_count = 0
	# Keep Cobra encounter intentionally simple: close poke + baitable heavy strike.
	enemy.use_single_phase_loop = false
	enemy.spin_attack_enabled = false
	enemy.boss_can_summon_minions = false
	enemy.attack_windup = 0.56
	enemy.attack_prestrike_hold_duration = 0.1
	enemy.attack_recovery_hold_duration = 0.04
	enemy.attack_cooldown = 1.2
	enemy.attack_range = 74.0 * cobra_range_scale * cobra_attack_range_multiplier
	enemy.basic_attack_hit_end_bonus = 18.0 * cobra_range_scale * cobra_attack_range_multiplier
	enemy.cobra_tongue_reach_bonus = 62.0 * cobra_range_scale * cobra_attack_range_multiplier
	enemy.cobra_tongue_telegraph_start_offset = 30.0 * cobra_range_scale
	enemy.cobra_preferred_range = 114.0 * cobra_range_scale
	enemy.cobra_preferred_range_tolerance = maxf(6.0, 22.0 * cobra_range_scale)
	enemy.cobra_close_attack_trigger_range = 56.0 * cobra_range_scale * cobra_attack_range_multiplier
	enemy.cobra_close_attack_reach = 58.0 * cobra_range_scale * cobra_attack_range_multiplier
	enemy.cobra_close_attack_half_width = 10.0
	enemy.cobra_close_attack_windup = 0.14
	enemy.cobra_close_attack_damage_scale = 0.5
	enemy.cobra_close_attack_stun_scale = 0.42
	enemy.cobra_close_attack_knockback_scale = 0.82
	enemy.cobra_close_attack_recovery = 0.18
	enemy.cobra_close_attack_cooldown = 0.8
	enemy.cobra_attack_min_range = 72.0 * cobra_range_scale * cobra_attack_range_multiplier
	enemy.cobra_attack_max_range = 132.0 * cobra_range_scale * cobra_attack_range_multiplier
	enemy.cobra_approach_speed_scale = 0.66
	enemy.cobra_stalk_speed_scale = 0.4
	enemy.cobra_retreat_speed_scale = 0.95
	enemy.cobra_spacing_pause_duration = 0.2
	enemy.cobra_heavy_attack_windup = 0.62
	enemy.cobra_heavy_attack_cooldown = 1.28
	enemy.cobra_close_attack_enabled = false
	enemy.cobra_heavy_bait_range_band = 16.0 * cobra_range_scale * cobra_attack_range_multiplier
	enemy.cobra_attack_recovery_on_hit = 0.18
	enemy.cobra_attack_recovery_on_block = 0.68
	enemy.cobra_attack_recovery_on_miss = 1.15
	enemy.cobra_max_range_bait_bonus_recovery = 0.42
	enemy.cobra_punish_damage_taken_multiplier = 1.7
	enemy.cobra_block_punish_damage_multiplier = 1.45
	enemy.cobra_dodge_punish_damage_multiplier = 2.1
	enemy.cobra_bait_punish_damage_bonus = 0.3
	enemy.cobra_punish_recoil_pose_duration = 0.28
	enemy.cobra_hit_stun_scale = 0.42
	enemy.cobra_hit_knockback_scale = 0.62
	enemy.max_health = maxf(1.0, enemy.max_health * clampf(cobra_health_scale, 0.0, 1000.0))
	enemy.current_health = enemy.max_health
	enemy.attack_damage = maxf(0.0, enemy.attack_damage * clampf(cobra_damage_scale, 0.0, 1000.0))


func _apply_adventure_start_selection(room_one_bounds: Rect2, start_position: Vector2) -> void:
	var normalized := adventure_start_control_id.strip_edges().to_lower()
	if normalized == "rat":
		normalized = CONTROLLED_CHARACTER_RATFOLK
	if normalized != CONTROLLED_CHARACTER_TANK and normalized != CONTROLLED_CHARACTER_HEALER and normalized != CONTROLLED_CHARACTER_RATFOLK:
		normalized = CONTROLLED_CHARACTER_TANK
		adventure_start_control_id = normalized
	tank_caged_active = false
	adventure_tank_cage_room_index = 0
	if normalized == CONTROLLED_CHARACTER_HEALER:
		controlled_character_id = CONTROLLED_CHARACTER_HEALER
		two_room_healer_released = true
		if not is_instance_valid(healer):
			_spawn_friendly_healer()
		if is_instance_valid(healer):
			healer.position = start_position
			if healer.has_method("set_arena_bounds"):
				healer.call(
					"set_arena_bounds",
					room_one_bounds.position.x,
					room_one_bounds.end.x,
					room_one_bounds.position.y,
					room_one_bounds.end.y
				)
		tank_party_enabled = false
		tank_caged_active = true
		adventure_tank_cage_room_index = 2
		_apply_tank_party_state()
		return
	if normalized == CONTROLLED_CHARACTER_RATFOLK:
		controlled_character_id = CONTROLLED_CHARACTER_RATFOLK
		two_room_rat_released = true
		if not is_instance_valid(ratfolk):
			_spawn_friendly_ratfolk()
		if is_instance_valid(ratfolk):
			ratfolk.position = start_position
			if ratfolk.has_method("set_arena_bounds"):
				ratfolk.call(
					"set_arena_bounds",
					room_one_bounds.position.x,
					room_one_bounds.end.x,
					room_one_bounds.position.y,
					room_one_bounds.end.y
				)
		tank_party_enabled = false
		tank_caged_active = true
		adventure_tank_cage_room_index = 3
		_apply_tank_party_state()
		return
	controlled_character_id = CONTROLLED_CHARACTER_TANK
	tank_party_enabled = true
	_apply_tank_party_state()


func _spawn_two_room_cobra_test() -> void:
	two_room_test_active = true
	two_room_test_room_index = 1
	two_room_test_transition_in_progress = false
	two_room_force_next_transition_spawn_on_left = false
	two_room_healer_released = false
	two_room_rat_released = false
	two_room_lizard_released = false
	two_room_final_chest_opened = false
	two_room_loot_drop_count = 0
	_teardown_two_room_exit()
	_teardown_two_room_cage()
	_teardown_two_room_chest()
	_teardown_two_room_return_portal()
	_apply_floor_tileset_to_node(floor_root, ARENA_TILESET_TEXTURE)

	var room_one_bounds := _get_two_room_bounds(1)
	var room_two_bounds := _get_two_room_bounds(2)
	var room_three_bounds := _get_two_room_bounds(3)
	var room_four_bounds := _get_two_room_bounds(4)
	var room_five_bounds := _get_two_room_bounds(5)
	var room_six_bounds := _get_two_room_bounds(6)
	_setup_two_room_second_play_area(room_two_bounds)
	_setup_two_room_third_play_area(room_three_bounds)
	_setup_two_room_fourth_play_area(room_four_bounds)
	_setup_two_room_fifth_play_area(room_five_bounds)
	_setup_two_room_sixth_play_area(room_six_bounds)
	var room_center_y := room_one_bounds.position.y + (room_one_bounds.size.y * 0.5)
	var start_position := Vector2(
		room_one_bounds.position.x + maxf(24.0, two_room_test_spawn_margin_x),
		room_center_y
	)
	if is_instance_valid(player):
		player.position = start_position
		_apply_local_bounds_to_player(
			player,
			room_one_bounds.position.x,
			room_one_bounds.end.x,
			room_one_bounds.position.y,
			room_one_bounds.end.y,
			true
		)
	_apply_adventure_start_selection(room_one_bounds, start_position)

	_spawn_two_room_room_content(1, room_one_bounds)
	_refresh_two_room_exits_for_room(1, room_one_bounds)
	_update_objective()


func _get_two_room_bounds(room_index: int) -> Rect2:
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	var size := Vector2(maxf(24.0, max_x - min_x), maxf(24.0, max_y - min_y))
	if room_index == 2:
		var offset := Vector2(two_room_test_second_room_offset_x, two_room_test_second_room_offset_y)
		return Rect2(Vector2(min_x, min_y) + offset, size)
	if room_index == 3:
		var offset := Vector2(two_room_test_third_room_offset_x, two_room_test_third_room_offset_y)
		return Rect2(Vector2(min_x, min_y) + offset, size)
	if room_index == 4:
		var offset := Vector2(two_room_test_fourth_room_offset_x, two_room_test_fourth_room_offset_y)
		return Rect2(Vector2(min_x, min_y) + offset, size)
	if room_index == 5:
		var offset := Vector2(two_room_test_fifth_room_offset_x, two_room_test_fifth_room_offset_y)
		return Rect2(Vector2(min_x, min_y) + offset, size)
	if room_index == 6:
		var offset := Vector2(two_room_test_sixth_room_offset_x, two_room_test_sixth_room_offset_y)
		return Rect2(Vector2(min_x, min_y) + offset, size)
	return Rect2(Vector2(min_x, min_y), size)


func _setup_two_room_second_play_area(room_two_bounds: Rect2) -> void:
	_teardown_two_room_second_play_area()
	if not is_instance_valid(floor_root):
		return
	var duplicate_flags := Node.DUPLICATE_GROUPS | Node.DUPLICATE_SIGNALS | Node.DUPLICATE_SCRIPTS
	var second_floor := floor_root.duplicate(duplicate_flags) as Node2D
	if second_floor == null:
		return
	second_floor.name = "FloorRoom2"
	add_child(second_floor)
	move_child(second_floor, get_child_count() - 1)
	second_floor.position = room_two_bounds.position + (room_two_bounds.size * 0.5)
	two_room_second_floor_root = second_floor
	_apply_floor_tileset_to_node(two_room_second_floor_root, ARENA_TILESET_TEXTURE)


func _teardown_two_room_second_play_area() -> void:
	if is_instance_valid(two_room_second_floor_root):
		two_room_second_floor_root.queue_free()
	two_room_second_floor_root = null


func _setup_two_room_third_play_area(room_three_bounds: Rect2) -> void:
	_teardown_two_room_third_play_area()
	if not is_instance_valid(floor_root):
		return
	var duplicate_flags := Node.DUPLICATE_GROUPS | Node.DUPLICATE_SIGNALS | Node.DUPLICATE_SCRIPTS
	var third_floor := floor_root.duplicate(duplicate_flags) as Node2D
	if third_floor == null:
		return
	third_floor.name = "FloorRoom3"
	add_child(third_floor)
	move_child(third_floor, get_child_count() - 1)
	third_floor.position = room_three_bounds.position + (room_three_bounds.size * 0.5)
	two_room_third_floor_root = third_floor
	_apply_floor_tileset_to_node(two_room_third_floor_root, _get_default_floor_tileset_texture())


func _duplicate_floor_template_chunk(parent_node: Node, chunk_name: String, local_position: Vector2 = Vector2.ZERO) -> Node2D:
	if parent_node == null or not is_instance_valid(parent_node):
		return null
	if not is_instance_valid(floor_root):
		return null
	var duplicate_flags := Node.DUPLICATE_GROUPS | Node.DUPLICATE_SIGNALS | Node.DUPLICATE_SCRIPTS
	var chunk := floor_root.duplicate(duplicate_flags) as Node2D
	if chunk == null:
		return null
	chunk.name = chunk_name
	chunk.position = local_position
	parent_node.add_child(chunk)
	return chunk


func _configure_floor_chunk_visual(
	target_floor: Node2D,
	size: Vector2,
	tileset_texture: Texture2D,
	floor_coords: Array,
	sidewalk_height: float,
	top_border_rows: int,
	bottom_border_rows: int,
	border_columns: int,
	decor_spawn_chance: float,
	floor_variation_chance: float,
	wall_variation_chance: float,
	bottom_border_align_to_playable_area: bool
) -> void:
	if target_floor == null or not is_instance_valid(target_floor):
		return
	target_floor.set("arena_width", maxf(96.0, size.x))
	target_floor.set("arena_height", maxf(96.0, size.y))
	target_floor.set("sidewalk_height", maxf(0.0, sidewalk_height))
	target_floor.set("top_border_rows", maxi(0, top_border_rows))
	target_floor.set("bottom_border_rows", maxi(0, bottom_border_rows))
	target_floor.set("border_columns", maxi(0, border_columns))
	target_floor.set("bottom_border_align_to_playable_area", bottom_border_align_to_playable_area)
	target_floor.set("decor_spawn_chance", clampf(decor_spawn_chance, 0.0, 1.0))
	target_floor.set("floor_tile_variation_chance", clampf(floor_variation_chance, 0.0, 1.0))
	target_floor.set("wall_tile_variation_chance", clampf(wall_variation_chance, 0.0, 1.0))
	if not floor_coords.is_empty():
		target_floor.set("floor_tile_coords", floor_coords.duplicate())
	_apply_floor_tileset_to_node(target_floor, tileset_texture)


func _get_floor_chunk_visible_cell_counts(target_floor: Node2D) -> Vector2i:
	if target_floor == null or not is_instance_valid(target_floor):
		return Vector2i.ONE
	var tile_size_variant: Variant = target_floor.get("dungeon_tile_size")
	var tile_size: Vector2i = tile_size_variant if tile_size_variant is Vector2i else Vector2i(32, 32)
	var tile_w := maxi(4, tile_size.x)
	var tile_h := maxi(4, tile_size.y)
	var chunk_width := maxf(32.0, float(target_floor.get("arena_width")))
	var chunk_height := maxf(32.0, float(target_floor.get("arena_height")))
	var visible_columns := maxi(1, int(floor((chunk_width - 0.001) / float(tile_w))) + 1)
	var visible_rows := maxi(1, int(floor((chunk_height - 0.001) / float(tile_h))) + 1)
	return Vector2i(visible_columns, visible_rows)


func _decorate_room_three_platform_chunk(target_floor: Node2D, is_left_platform: bool) -> void:
	if target_floor == null or not is_instance_valid(target_floor):
		return
	var decor_layer := target_floor.get_node_or_null("DungeonDecorLayer") as TileMapLayer
	if decor_layer == null or not is_instance_valid(decor_layer):
		return
	var visible_cells := _get_floor_chunk_visible_cell_counts(target_floor)
	var source_id := int(target_floor.get("dungeon_tileset_source_id"))
	var top_row := 1
	var bottom_row := maxi(top_row + 1, visible_cells.y - 2)
	var mid_row := mini(bottom_row - 1, maxi(top_row + 1, int(floor(float(visible_cells.y) * 0.5))))
	var inner_edge_x := maxi(1, visible_cells.x - 2) if is_left_platform else 1
	var outer_edge_x := 1 if is_left_platform else maxi(1, visible_cells.x - 2)
	decor_layer.set_cell(Vector2i(inner_edge_x, top_row), source_id, Vector2i(0, 13))
	decor_layer.set_cell(Vector2i(inner_edge_x, bottom_row), source_id, Vector2i(1, 13))
	decor_layer.set_cell(Vector2i(outer_edge_x, mid_row), source_id, Vector2i(2, 13))
	var brace_x := clampi(inner_edge_x + (-1 if is_left_platform else 1), 1, maxi(1, visible_cells.x - 2))
	decor_layer.set_cell(Vector2i(brace_x, top_row + 1), source_id, Vector2i(4, 13))
	decor_layer.set_cell(Vector2i(brace_x, max(top_row + 1, bottom_row - 1)), source_id, Vector2i(4, 14))


func _decorate_room_three_bridge_chunk(target_floor: Node2D) -> void:
	if target_floor == null or not is_instance_valid(target_floor):
		return
	var decor_layer := target_floor.get_node_or_null("DungeonDecorLayer") as TileMapLayer
	if decor_layer == null or not is_instance_valid(decor_layer):
		return
	var visible_cells := _get_floor_chunk_visible_cell_counts(target_floor)
	var source_id := int(target_floor.get("dungeon_tileset_source_id"))
	var top_row := 1
	var bottom_row := maxi(top_row + 1, visible_cells.y - 2)
	for x in range(1, maxi(2, visible_cells.x - 1)):
		if x % 2 == 0:
			continue
		decor_layer.set_cell(Vector2i(x, top_row), source_id, Vector2i(4, 13))
		decor_layer.set_cell(Vector2i(x, bottom_row), source_id, Vector2i(4, 14))
	var anchor_row := mini(bottom_row, maxi(top_row, int(floor(float(visible_cells.y) * 0.5))))
	var center_x := maxi(1, mini(visible_cells.x - 2, int(floor(float(visible_cells.x) * 0.5))))
	decor_layer.set_cell(Vector2i(1, anchor_row), source_id, Vector2i(5, 13))
	decor_layer.set_cell(Vector2i(maxi(1, visible_cells.x - 2), anchor_row), source_id, Vector2i(5, 13))
	decor_layer.set_cell(Vector2i(center_x, top_row), source_id, Vector2i(5, 13))
	decor_layer.set_cell(Vector2i(center_x, bottom_row), source_id, Vector2i(5, 13))


func _decorate_room_three_boss_dais_chunk(target_floor: Node2D) -> void:
	if target_floor == null or not is_instance_valid(target_floor):
		return
	var decor_layer := target_floor.get_node_or_null("DungeonDecorLayer") as TileMapLayer
	if decor_layer == null or not is_instance_valid(decor_layer):
		return
	var visible_cells := _get_floor_chunk_visible_cell_counts(target_floor)
	var source_id := int(target_floor.get("dungeon_tileset_source_id"))
	var top_row := 1
	var bottom_row := maxi(top_row + 2, visible_cells.y - 2)
	var mid_row := mini(bottom_row - 1, maxi(top_row + 1, int(floor(float(visible_cells.y) * 0.5))))
	var left_x := 1
	var right_x := maxi(1, visible_cells.x - 2)
	var center_x := maxi(left_x, mini(right_x, int(floor(float(visible_cells.x) * 0.5))))
	decor_layer.set_cell(Vector2i(left_x, top_row), source_id, Vector2i(0, 13))
	decor_layer.set_cell(Vector2i(left_x, bottom_row), source_id, Vector2i(1, 13))
	decor_layer.set_cell(Vector2i(right_x, top_row), source_id, Vector2i(0, 13))
	decor_layer.set_cell(Vector2i(right_x, bottom_row), source_id, Vector2i(1, 13))
	decor_layer.set_cell(Vector2i(center_x, top_row), source_id, Vector2i(5, 13))
	decor_layer.set_cell(Vector2i(center_x, bottom_row), source_id, Vector2i(5, 13))
	decor_layer.set_cell(Vector2i(center_x, mid_row), source_id, Vector2i(2, 13))
	var inner_left := clampi(center_x - 2, left_x, right_x)
	var inner_right := clampi(center_x + 2, left_x, right_x)
	decor_layer.set_cell(Vector2i(inner_left, top_row + 1), source_id, Vector2i(4, 13))
	decor_layer.set_cell(Vector2i(inner_left, max(top_row + 1, bottom_row - 1)), source_id, Vector2i(4, 14))
	decor_layer.set_cell(Vector2i(inner_right, top_row + 1), source_id, Vector2i(4, 13))
	decor_layer.set_cell(Vector2i(inner_right, max(top_row + 1, bottom_row - 1)), source_id, Vector2i(4, 14))
	if right_x - left_x >= 6:
		decor_layer.set_cell(Vector2i(left_x + 2, mid_row), source_id, Vector2i(5, 13))
		decor_layer.set_cell(Vector2i(right_x - 2, mid_row), source_id, Vector2i(5, 13))


func _build_room_three_ellipse_polygon(center: Vector2, radii: Vector2, segments: int = 18) -> PackedVector2Array:
	var safe_segments := maxi(8, segments)
	var radius_x := maxf(1.0, radii.x)
	var radius_y := maxf(1.0, radii.y)
	var points := PackedVector2Array()
	for index in range(safe_segments):
		var angle := (TAU * float(index)) / float(safe_segments)
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


func _spawn_room_three_bridge_ambience(parent_node: Node2D, bridge_width: float, bridge_height: float, boss_spawn_local: Vector2) -> void:
	if parent_node == null or not is_instance_valid(parent_node):
		return
	var bridge_shadow := Polygon2D.new()
	bridge_shadow.z_index = -95
	bridge_shadow.color = Color(0.0, 0.0, 0.0, 0.26)
	bridge_shadow.polygon = PackedVector2Array([
		Vector2(-bridge_width * 0.56, -bridge_height * 0.36),
		Vector2(bridge_width * 0.48, -bridge_height * 0.36),
		Vector2(bridge_width * 0.58, 0.0),
		Vector2(bridge_width * 0.48, bridge_height * 0.36),
		Vector2(-bridge_width * 0.56, bridge_height * 0.36),
		Vector2(-bridge_width * 0.64, 0.0)
	])
	parent_node.add_child(bridge_shadow)

	for rail_y in [-bridge_height * 0.42, bridge_height * 0.42]:
		var bridge_rail := Line2D.new()
		bridge_rail.z_index = -89
		bridge_rail.width = 2.0
		bridge_rail.default_color = Color(0.48, 0.42, 0.32, 0.84)
		bridge_rail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		bridge_rail.end_cap_mode = Line2D.LINE_CAP_ROUND
		bridge_rail.points = PackedVector2Array([
			Vector2(-bridge_width * 0.46, rail_y),
			Vector2(bridge_width * 0.46, rail_y)
		])
		parent_node.add_child(bridge_rail)

	var outer_glow := Polygon2D.new()
	outer_glow.z_index = -89
	outer_glow.color = Color(1.0, 0.36, 0.12, 0.08)
	outer_glow.polygon = _build_room_three_ellipse_polygon(boss_spawn_local + Vector2(0.0, 8.0), Vector2(90.0, 48.0), 22)
	parent_node.add_child(outer_glow)

	var inner_glow := Polygon2D.new()
	inner_glow.z_index = -88
	inner_glow.color = Color(1.0, 0.5, 0.18, 0.12)
	inner_glow.polygon = _build_room_three_ellipse_polygon(boss_spawn_local + Vector2(0.0, 8.0), Vector2(54.0, 28.0), 18)
	parent_node.add_child(inner_glow)


func _spawn_room_three_rift_visuals(parent_node: Node2D, room_size: Vector2, bridge_height: float, rift_half_width: float) -> void:
	if parent_node == null or not is_instance_valid(parent_node):
		return
	var half_room_h := room_size.y * 0.5
	var bridge_shoulder := maxf(bridge_height * 0.58, 74.0)
	var left_edge := PackedVector2Array([
		Vector2(-rift_half_width * 1.02, -half_room_h + 18.0),
		Vector2(-rift_half_width * 0.82, -bridge_shoulder - 36.0),
		Vector2(-rift_half_width * 0.66, -bridge_shoulder + 14.0),
		Vector2(-rift_half_width * 0.74, bridge_shoulder - 18.0),
		Vector2(-rift_half_width * 0.92, half_room_h - 18.0)
	])
	var right_edge := PackedVector2Array([
		Vector2(rift_half_width * 0.88, half_room_h - 14.0),
		Vector2(rift_half_width * 0.7, bridge_shoulder + 28.0),
		Vector2(rift_half_width * 0.62, bridge_shoulder - 12.0),
		Vector2(rift_half_width * 0.74, -bridge_shoulder + 20.0),
		Vector2(rift_half_width * 0.96, -half_room_h + 14.0)
	])
	var outer_polygon_points := PackedVector2Array()
	for point in left_edge:
		outer_polygon_points.append(point)
	for point in right_edge:
		outer_polygon_points.append(point)
	var outer_rift := Polygon2D.new()
	outer_rift.z_index = -100
	outer_rift.color = Color(0.12, 0.09, 0.08, 0.96)
	outer_rift.polygon = outer_polygon_points
	parent_node.add_child(outer_rift)

	var inner_rift := Polygon2D.new()
	inner_rift.z_index = -100
	inner_rift.color = Color(0.05, 0.04, 0.04, 0.98)
	inner_rift.polygon = PackedVector2Array([
		Vector2(-rift_half_width * 0.58, -half_room_h + 32.0),
		Vector2(-rift_half_width * 0.46, -bridge_shoulder - 10.0),
		Vector2(-rift_half_width * 0.36, bridge_shoulder - 8.0),
		Vector2(-rift_half_width * 0.52, half_room_h - 28.0),
		Vector2(rift_half_width * 0.54, half_room_h - 24.0),
		Vector2(rift_half_width * 0.38, bridge_shoulder + 10.0),
		Vector2(rift_half_width * 0.34, -bridge_shoulder + 8.0),
		Vector2(rift_half_width * 0.48, -half_room_h + 28.0)
	])
	parent_node.add_child(inner_rift)

	var ember_glow := Polygon2D.new()
	ember_glow.z_index = -99
	ember_glow.color = Color(0.72, 0.18, 0.08, 0.14)
	ember_glow.polygon = PackedVector2Array([
		Vector2(-rift_half_width * 0.32, -half_room_h + 44.0),
		Vector2(-rift_half_width * 0.22, -bridge_shoulder - 12.0),
		Vector2(-rift_half_width * 0.18, bridge_shoulder - 8.0),
		Vector2(-rift_half_width * 0.28, half_room_h - 40.0),
		Vector2(rift_half_width * 0.28, half_room_h - 36.0),
		Vector2(rift_half_width * 0.16, bridge_shoulder + 6.0),
		Vector2(rift_half_width * 0.2, -bridge_shoulder + 4.0),
		Vector2(rift_half_width * 0.34, -half_room_h + 40.0)
	])
	parent_node.add_child(ember_glow)

	var ember_core := Polygon2D.new()
	ember_core.z_index = -98
	ember_core.color = Color(1.0, 0.32, 0.08, 0.08)
	ember_core.polygon = PackedVector2Array([
		Vector2(-rift_half_width * 0.16, -half_room_h + 56.0),
		Vector2(-rift_half_width * 0.1, -bridge_shoulder + 6.0),
		Vector2(-rift_half_width * 0.08, bridge_shoulder - 4.0),
		Vector2(-rift_half_width * 0.14, half_room_h - 52.0),
		Vector2(rift_half_width * 0.14, half_room_h - 48.0),
		Vector2(rift_half_width * 0.08, bridge_shoulder + 4.0),
		Vector2(rift_half_width * 0.09, -bridge_shoulder - 2.0),
		Vector2(rift_half_width * 0.18, -half_room_h + 52.0)
	])
	parent_node.add_child(ember_core)

	var left_rim := Line2D.new()
	left_rim.z_index = -100
	left_rim.width = 2.4
	left_rim.default_color = Color(0.34, 0.3, 0.24, 0.82)
	left_rim.begin_cap_mode = Line2D.LINE_CAP_ROUND
	left_rim.end_cap_mode = Line2D.LINE_CAP_ROUND
	left_rim.points = left_edge
	parent_node.add_child(left_rim)

	var right_rim_points := PackedVector2Array()
	for idx in range(right_edge.size() - 1, -1, -1):
		right_rim_points.append(right_edge[idx])
	var right_rim := Line2D.new()
	right_rim.z_index = -100
	right_rim.width = 2.4
	right_rim.default_color = Color(0.34, 0.3, 0.24, 0.82)
	right_rim.begin_cap_mode = Line2D.LINE_CAP_ROUND
	right_rim.end_cap_mode = Line2D.LINE_CAP_ROUND
	right_rim.points = right_rim_points
	parent_node.add_child(right_rim)


func _get_room_three_walkable_rects(room_three_bounds: Rect2) -> Array[Rect2]:
	var template_width := room_three_bounds.size.x
	var template_height := room_three_bounds.size.y
	if is_instance_valid(floor_root):
		template_width = maxf(template_width, float(floor_root.get("arena_width")))
		template_height = maxf(template_height, float(floor_root.get("arena_height")))
	var full_room_size := Vector2(
		maxf(room_three_bounds.size.x + 24.0, template_width),
		maxf(room_three_bounds.size.y + 48.0, template_height)
	)
	var platform_width := clampf(room_three_bounds.size.x * 0.34, 272.0, full_room_size.x * 0.4)
	var platform_height := clampf(room_three_bounds.size.y + 68.0, room_three_bounds.size.y + 28.0, full_room_size.y - 44.0)
	var bridge_width := clampf(room_three_bounds.size.x * 0.42, 320.0, full_room_size.x * 0.52)
	var bridge_height := clampf(room_three_bounds.size.y * 0.62, 150.0, platform_height - 72.0)
	var platform_offset_x := room_three_bounds.size.x * 0.26
	var center := room_three_bounds.position + (room_three_bounds.size * 0.5)
	var bridge_clearance := 10.0
	var platform_clearance := 8.0
	var west_platform := Rect2(
		center + Vector2(-platform_offset_x - (platform_width * 0.5), -(platform_height * 0.5)),
		Vector2(platform_width, platform_height)
	).grow(-platform_clearance)
	var east_platform := Rect2(
		center + Vector2(platform_offset_x - (platform_width * 0.5), -(platform_height * 0.5)),
		Vector2(platform_width, platform_height)
	).grow(-platform_clearance)
	var bridge_rect := Rect2(
		center + Vector2(-(bridge_width * 0.5), -(bridge_height * 0.5)),
		Vector2(bridge_width, bridge_height)
	).grow(-bridge_clearance)
	return [west_platform, east_platform, bridge_rect]


func _get_room_three_boss_spawn_position(room_three_bounds: Rect2) -> Vector2:
	var walkable_rects := _get_room_three_walkable_rects(room_three_bounds)
	if walkable_rects.size() < 3:
		return room_three_bounds.position + (room_three_bounds.size * 0.5)
	var east_platform := walkable_rects[1]
	var bridge_rect := walkable_rects[2]
	var spawn_x := clampf(
		bridge_rect.end.x + maxf(18.0, east_platform.size.x * 0.08),
		bridge_rect.end.x - 2.0,
		east_platform.end.x - 28.0
	)
	var spawn_y := clampf(
		bridge_rect.position.y + (bridge_rect.size.y * 0.5),
		east_platform.position.y + 18.0,
		east_platform.end.y - 18.0
	)
	return Vector2(spawn_x, spawn_y)


func _get_nearest_point_in_rect(point: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)


func _clamp_global_position_to_room_three_walkway(world_position: Vector2, room_three_bounds: Rect2) -> Vector2:
	var local_position := to_local(world_position)
	if not room_three_bounds.grow(18.0).has_point(local_position):
		return world_position
	var walkable_rects := _get_room_three_walkable_rects(room_three_bounds)
	if walkable_rects.is_empty():
		return world_position
	for rect in walkable_rects:
		if rect.has_point(local_position):
			return world_position
	var nearest_point := local_position
	var nearest_distance_sq := INF
	for rect in walkable_rects:
		var candidate := _get_nearest_point_in_rect(local_position, rect)
		var distance_sq := local_position.distance_squared_to(candidate)
		if distance_sq >= nearest_distance_sq:
			continue
		nearest_distance_sq = distance_sq
		nearest_point = candidate
	return to_global(nearest_point)


func _clamp_room_three_actor_to_walkway(actor: Node) -> void:
	var actor_2d := actor as Node2D
	if actor_2d == null or not is_instance_valid(actor_2d):
		return
	var room_three_bounds := _get_two_room_bounds(3)
	var clamped_position := _clamp_global_position_to_room_three_walkway(actor_2d.global_position, room_three_bounds)
	if actor_2d.global_position.distance_squared_to(clamped_position) <= 0.0001:
		return
	actor_2d.global_position = clamped_position


func _enforce_room_three_bridge_walkway() -> void:
	if not two_room_test_active:
		return
	_clamp_room_three_actor_to_walkway(player)
	_clamp_room_three_actor_to_walkway(healer)
	_clamp_room_three_actor_to_walkway(ratfolk)
	_clamp_room_three_actor_to_walkway(lizardfolk)
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		_clamp_room_three_actor_to_walkway(enemy)


func _teardown_two_room_third_play_area() -> void:
	if is_instance_valid(two_room_third_floor_root):
		two_room_third_floor_root.queue_free()
	two_room_third_floor_root = null


func _setup_two_room_fourth_play_area(room_four_bounds: Rect2) -> void:
	_teardown_two_room_fourth_play_area()
	if not is_instance_valid(floor_root):
		return
	var duplicate_flags := Node.DUPLICATE_GROUPS | Node.DUPLICATE_SIGNALS | Node.DUPLICATE_SCRIPTS
	var fourth_floor := floor_root.duplicate(duplicate_flags) as Node2D
	if fourth_floor == null:
		return
	fourth_floor.name = "FloorRoom4"
	add_child(fourth_floor)
	move_child(fourth_floor, get_child_count() - 1)
	fourth_floor.position = room_four_bounds.position + (room_four_bounds.size * 0.5)
	two_room_fourth_floor_root = fourth_floor
	_apply_floor_tileset_to_node(two_room_fourth_floor_root, _get_default_floor_tileset_texture())


func _teardown_two_room_fourth_play_area() -> void:
	if is_instance_valid(two_room_fourth_floor_root):
		two_room_fourth_floor_root.queue_free()
	two_room_fourth_floor_root = null


func _setup_two_room_fifth_play_area(room_five_bounds: Rect2) -> void:
	_teardown_two_room_fifth_play_area()
	if not is_instance_valid(floor_root):
		return
	var duplicate_flags := Node.DUPLICATE_GROUPS | Node.DUPLICATE_SIGNALS | Node.DUPLICATE_SCRIPTS
	var fifth_floor := floor_root.duplicate(duplicate_flags) as Node2D
	if fifth_floor == null:
		return
	fifth_floor.name = "FloorRoom5"
	add_child(fifth_floor)
	move_child(fifth_floor, get_child_count() - 1)
	fifth_floor.position = room_five_bounds.position + (room_five_bounds.size * 0.5)
	two_room_fifth_floor_root = fifth_floor
	_apply_floor_tileset_to_node(two_room_fifth_floor_root, _get_default_floor_tileset_texture())


func _teardown_two_room_fifth_play_area() -> void:
	if is_instance_valid(two_room_fifth_floor_root):
		two_room_fifth_floor_root.queue_free()
	two_room_fifth_floor_root = null


func _setup_two_room_sixth_play_area(room_six_bounds: Rect2) -> void:
	_teardown_two_room_sixth_play_area()
	if not is_instance_valid(floor_root):
		return
	var duplicate_flags := Node.DUPLICATE_GROUPS | Node.DUPLICATE_SIGNALS | Node.DUPLICATE_SCRIPTS
	var sixth_floor := floor_root.duplicate(duplicate_flags) as Node2D
	if sixth_floor == null:
		return
	sixth_floor.name = "FloorRoom6"
	add_child(sixth_floor)
	move_child(sixth_floor, get_child_count() - 1)
	sixth_floor.position = room_six_bounds.position + (room_six_bounds.size * 0.5)
	two_room_sixth_floor_root = sixth_floor
	_apply_floor_tileset_to_node(two_room_sixth_floor_root, _get_default_floor_tileset_texture())


func _teardown_two_room_sixth_play_area() -> void:
	if is_instance_valid(two_room_sixth_floor_root):
		two_room_sixth_floor_root.queue_free()
	two_room_sixth_floor_root = null


func _get_default_floor_tileset_texture() -> Texture2D:
	if default_floor_tileset_texture != null:
		return default_floor_tileset_texture
	return DEFAULT_DUNGEON_TILESET_TEXTURE


func _apply_floor_tileset_to_node(target_floor: Node2D, tileset_texture: Texture2D) -> void:
	if target_floor == null or not is_instance_valid(target_floor):
		return
	if tileset_texture == null:
		return
	target_floor.set("dungeon_tileset_texture", tileset_texture)
	if target_floor.has_method("_rebuild_floor_tiles"):
		target_floor.call("_rebuild_floor_tiles")
	target_floor.queue_redraw()


func _spawn_two_room_exit(room_bounds: Rect2, place_on_left: bool, target_room_index: int) -> void:
	if target_room_index <= 0:
		return
	if not is_instance_valid(two_room_exit_root):
		var root := Node2D.new()
		root.name = "TwoRoomExit"
		root.z_index = 8
		add_child(root)
		two_room_exit_root = root

	var local_target_room := clampi(target_room_index, 1, TWO_ROOM_TEST_TOTAL_ROOMS)
	var area := Area2D.new()
	area.name = "TriggerToRoom%d" % local_target_room
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 0
	area.collision_mask = 1
	var visual_half_w := maxf(6.0, two_room_test_exit_width * 0.5)
	var left_center_inset := maxf(10.0, visual_half_w)
	# Right exits are centered on the room boundary so the doorway sits exactly on the play-area edge.
	var right_center_inset := maxf(0.0, two_room_test_right_exit_center_inset)
	var door_center_x := (
		room_bounds.position.x + left_center_inset
		if place_on_left
		else room_bounds.end.x - right_center_inset
	)
	# Keep right-door visuals on the edge, but nudge the trigger inward so it remains reachable.
	var trigger_center_x := door_center_x
	if not place_on_left:
		var inward_trigger_padding := maxf(6.0, visual_half_w * 0.75)
		trigger_center_x = room_bounds.end.x - inward_trigger_padding
	area.position = Vector2(
		trigger_center_x,
		room_bounds.position.y + (room_bounds.size.y * 0.5)
	)
	area.set_meta("target_room_index", local_target_room)
	two_room_exit_root.add_child(area)
	two_room_exit_area = area

	var trigger_shape := CollisionShape2D.new()
	var trigger_rect := RectangleShape2D.new()
	var trigger_width := maxf(12.0, two_room_test_exit_width)
	# Right-side adventure exits sit against the room wall; widen the trigger so it always catches the player.
	if not place_on_left:
		trigger_width = maxf(trigger_width, visual_half_w * 4.0)
	trigger_rect.size = Vector2(trigger_width, maxf(56.0, two_room_test_exit_height))
	trigger_shape.shape = trigger_rect
	area.add_child(trigger_shape)
	area.body_entered.connect(_on_two_room_exit_body_entered.bind(local_target_room))

	var door_visual := Polygon2D.new()
	door_visual.color = Color(0.28, 0.76, 0.9, 0.32) if not place_on_left else Color(0.34, 0.88, 0.56, 0.28)
	var half_w := visual_half_w
	var half_h := trigger_rect.size.y * 0.5
	door_visual.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	door_visual.position.x = door_center_x - trigger_center_x
	area.add_child(door_visual)

	var border := Line2D.new()
	border.default_color = Color(0.52, 0.9, 1.0, 0.8) if not place_on_left else Color(0.48, 0.94, 0.72, 0.8)
	border.width = 2.0
	border.closed = true
	border.points = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	border.position.x = door_center_x - trigger_center_x
	area.add_child(border)

	var arrow := Line2D.new()
	arrow.default_color = border.default_color
	arrow.width = 2.0
	var arrow_len := maxf(8.0, half_w * 0.55)
	if place_on_left:
		arrow.points = PackedVector2Array([
			Vector2(arrow_len, -6.0),
			Vector2(-arrow_len, 0.0),
			Vector2(arrow_len, 6.0)
		])
	else:
		arrow.points = PackedVector2Array([
			Vector2(-arrow_len, -6.0),
			Vector2(arrow_len, 0.0),
			Vector2(-arrow_len, 6.0)
		])
	arrow.position.x = door_center_x - trigger_center_x
	area.add_child(arrow)


func _refresh_two_room_exits_for_room(room_index: int, room_bounds: Rect2) -> void:
	_teardown_two_room_exit()
	if room_index > 1:
		_spawn_two_room_exit(room_bounds, true, room_index - 1)

	match room_index:
		1:
			_spawn_two_room_exit(room_bounds, false, 2)
		2:
			_spawn_two_room_exit(room_bounds, false, 3)
		3:
			_spawn_two_room_exit(room_bounds, false, 4)
		4:
			_spawn_two_room_exit(room_bounds, false, 5)
		5:
			_spawn_two_room_exit(room_bounds, false, 6)
		_:
			pass


func _teardown_two_room_exit() -> void:
	if is_instance_valid(two_room_exit_root):
		two_room_exit_root.queue_free()
	two_room_exit_root = null
	two_room_exit_area = null


func _is_tank_caged_for_room(room_index: int) -> bool:
	return tank_caged_active and adventure_tank_cage_room_index == room_index


func _spawn_two_room_caged_tank(cage_position: Vector2, room_bounds: Rect2) -> void:
	if is_instance_valid(two_room_caged_tank):
		two_room_caged_tank.queue_free()
	two_room_caged_tank = null
	var caged := PLAYER_SCENE.instantiate() as Node2D
	if caged == null:
		return
	actors.add_child(caged)
	caged.global_position = to_global(cage_position + Vector2(0.0, 8.0))
	caged.set_process(false)
	caged.set_physics_process(false)
	caged.set_process_input(false)
	var caged_player := caged as Player
	if caged_player != null:
		caged_player.collision_layer = 0
		caged_player.collision_mask = 0
		if caged_player.has_method("_set_health_bar_visible"):
			caged_player.call("_set_health_bar_visible", false)
		if caged_player.has_method("set_ai_control_enabled"):
			caged_player.call("set_ai_control_enabled", false)
	caged.call_deferred("remove_from_group", "player")
	caged.call_deferred("remove_from_group", "hitbox_debuggable")
	var camera := caged.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.enabled = false
		camera.set_process(false)
		camera.set_physics_process(false)
	if caged.has_method("set_arena_bounds"):
		caged.call(
			"set_arena_bounds",
			room_bounds.position.x,
			room_bounds.end.x,
			room_bounds.position.y,
			room_bounds.end.y
		)
	two_room_caged_tank = caged


func _spawn_two_room_healer_cage(room_two_bounds: Rect2) -> void:
	_teardown_two_room_cage()
	var center_y := room_two_bounds.position.y + (room_two_bounds.size.y * 0.5)
	var cage_position := Vector2(
		room_two_bounds.end.x - maxf(56.0, two_room_test_spawn_margin_x),
		clampf(center_y + two_room_test_room2_healer_cage_y_offset, room_two_bounds.position.y + 12.0, room_two_bounds.end.y - 12.0)
	)

	var root := Node2D.new()
	root.name = "TwoRoomHealerCage"
	root.z_index = 10
	root.position = cage_position
	add_child(root)
	two_room_cage_root = root

	var area := Area2D.new()
	area.name = "HealerCageTrigger"
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 0
	area.collision_mask = 1
	root.add_child(area)
	two_room_cage_area = area

	var trigger_shape := CollisionShape2D.new()
	var trigger_rect := RectangleShape2D.new()
	trigger_rect.size = Vector2(maxf(28.0, two_room_test_cage_width), maxf(42.0, two_room_test_cage_height))
	trigger_shape.shape = trigger_rect
	area.add_child(trigger_shape)
	area.body_entered.connect(_on_two_room_cage_body_entered)

	var half_w := trigger_rect.size.x * 0.5
	var half_h := trigger_rect.size.y * 0.5
	var cage_bg := Polygon2D.new()
	cage_bg.color = Color(0.16, 0.2, 0.24, 0.46)
	cage_bg.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	root.add_child(cage_bg)

	var cage_outline := Line2D.new()
	cage_outline.default_color = Color(0.76, 0.86, 0.96, 0.88)
	cage_outline.width = 2.0
	cage_outline.closed = true
	cage_outline.points = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	root.add_child(cage_outline)

	for bar_index in range(1, 4):
		var t := float(bar_index) / 4.0
		var bar_x := lerpf(-half_w, half_w, t)
		var bar := Line2D.new()
		bar.default_color = Color(0.72, 0.82, 0.9, 0.84)
		bar.width = 1.4
		bar.points = PackedVector2Array([
			Vector2(bar_x, -half_h),
			Vector2(bar_x, half_h)
		])
		root.add_child(bar)

	if _is_tank_caged_for_room(2):
		_spawn_two_room_caged_tank(cage_position, room_two_bounds)
		return

	var caged := FRIENDLY_HEALER_SCENE.instantiate() as Node2D
	if caged != null:
		actors.add_child(caged)
		caged.global_position = to_global(cage_position + Vector2(0.0, 8.0))
		caged.set_process(false)
		caged.set_physics_process(false)
		caged.set_process_input(false)
		if caged.has_method("set_arena_bounds"):
			caged.call(
				"set_arena_bounds",
				room_two_bounds.position.x,
				room_two_bounds.end.x,
				room_two_bounds.position.y,
				room_two_bounds.end.y
			)
		_apply_hitbox_debug_to_node(caged)
		two_room_caged_healer = caged


func _spawn_two_room_rat_cage(room_bounds: Rect2) -> void:
	if two_room_rat_released and not _is_tank_caged_for_room(3):
		return
	_teardown_two_room_cage()
	var center_y := room_bounds.position.y + (room_bounds.size.y * 0.5)
	var cage_position := Vector2(
		room_bounds.end.x - maxf(56.0, two_room_test_spawn_margin_x),
		clampf(center_y + two_room_test_room3_rat_cage_y_offset, room_bounds.position.y + 12.0, room_bounds.end.y - 12.0)
	)

	var root := Node2D.new()
	root.name = "TwoRoomRatCage"
	root.z_index = 10
	root.position = cage_position
	add_child(root)
	two_room_cage_root = root

	var area := Area2D.new()
	area.name = "RatCageTrigger"
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 0
	area.collision_mask = 1
	root.add_child(area)
	two_room_cage_area = area

	var trigger_shape := CollisionShape2D.new()
	var trigger_rect := RectangleShape2D.new()
	trigger_rect.size = Vector2(maxf(28.0, two_room_test_cage_width), maxf(42.0, two_room_test_cage_height))
	trigger_shape.shape = trigger_rect
	area.add_child(trigger_shape)
	area.body_entered.connect(_on_two_room_cage_body_entered)

	var half_w := trigger_rect.size.x * 0.5
	var half_h := trigger_rect.size.y * 0.5
	var cage_bg := Polygon2D.new()
	cage_bg.color = Color(0.16, 0.2, 0.24, 0.46)
	cage_bg.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	root.add_child(cage_bg)

	var cage_outline := Line2D.new()
	cage_outline.default_color = Color(0.76, 0.86, 0.96, 0.88)
	cage_outline.width = 2.0
	cage_outline.closed = true
	cage_outline.points = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	root.add_child(cage_outline)

	for bar_index in range(1, 4):
		var t := float(bar_index) / 4.0
		var bar_x := lerpf(-half_w, half_w, t)
		var bar := Line2D.new()
		bar.default_color = Color(0.72, 0.82, 0.9, 0.84)
		bar.width = 1.4
		bar.points = PackedVector2Array([
			Vector2(bar_x, -half_h),
			Vector2(bar_x, half_h)
		])
		root.add_child(bar)

	if _is_tank_caged_for_room(3):
		_spawn_two_room_caged_tank(cage_position, room_bounds)
		return

	var caged := FRIENDLY_RATFOLK_SCENE.instantiate() as Node2D
	if caged != null:
		actors.add_child(caged)
		caged.global_position = to_global(cage_position + Vector2(0.0, 8.0))
		caged.set_process(false)
		caged.set_physics_process(false)
		caged.set_process_input(false)
		if caged.has_method("set_arena_bounds"):
			caged.call(
				"set_arena_bounds",
				room_bounds.position.x,
				room_bounds.end.x,
				room_bounds.position.y,
				room_bounds.end.y
			)
		_apply_hitbox_debug_to_node(caged)
		two_room_caged_rat = caged


func _spawn_two_room_lizard_cage(room_bounds: Rect2) -> void:
	if two_room_lizard_released:
		return
	_teardown_two_room_cage()
	var center_y := room_bounds.position.y + (room_bounds.size.y * 0.5)
	var cage_position := Vector2(
		room_bounds.end.x - maxf(56.0, two_room_test_spawn_margin_x),
		clampf(center_y + two_room_test_room6_lizard_cage_y_offset, room_bounds.position.y + 12.0, room_bounds.end.y - 12.0)
	)

	var root := Node2D.new()
	root.name = "TwoRoomLizardCage"
	root.z_index = 10
	root.position = cage_position
	add_child(root)
	two_room_cage_root = root

	var area := Area2D.new()
	area.name = "LizardCageTrigger"
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 0
	area.collision_mask = 1
	root.add_child(area)
	two_room_cage_area = area

	var trigger_shape := CollisionShape2D.new()
	var trigger_rect := RectangleShape2D.new()
	trigger_rect.size = Vector2(maxf(28.0, two_room_test_cage_width), maxf(42.0, two_room_test_cage_height))
	trigger_shape.shape = trigger_rect
	area.add_child(trigger_shape)
	area.body_entered.connect(_on_two_room_cage_body_entered)

	var half_w := trigger_rect.size.x * 0.5
	var half_h := trigger_rect.size.y * 0.5
	var cage_bg := Polygon2D.new()
	cage_bg.color = Color(0.16, 0.2, 0.24, 0.46)
	cage_bg.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	root.add_child(cage_bg)

	var cage_outline := Line2D.new()
	cage_outline.default_color = Color(0.76, 0.86, 0.96, 0.88)
	cage_outline.width = 2.0
	cage_outline.closed = true
	cage_outline.points = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	root.add_child(cage_outline)

	for bar_index in range(1, 4):
		var t := float(bar_index) / 4.0
		var bar_x := lerpf(-half_w, half_w, t)
		var bar := Line2D.new()
		bar.default_color = Color(0.72, 0.82, 0.9, 0.84)
		bar.width = 1.4
		bar.points = PackedVector2Array([
			Vector2(bar_x, -half_h),
			Vector2(bar_x, half_h)
		])
		root.add_child(bar)

	var caged := FRIENDLY_LIZARDFOLK_SCENE.instantiate() as Node2D
	if caged != null:
		actors.add_child(caged)
		caged.global_position = to_global(cage_position + Vector2(0.0, 8.0))
		caged.set_process(false)
		caged.set_physics_process(false)
		caged.set_process_input(false)
		if caged.has_method("set_arena_bounds"):
			caged.call(
				"set_arena_bounds",
				room_bounds.position.x,
				room_bounds.end.x,
				room_bounds.position.y,
				room_bounds.end.y
			)
		_apply_hitbox_debug_to_node(caged)
		two_room_caged_lizard = caged


func _teardown_two_room_cage() -> void:
	if is_instance_valid(two_room_cage_root):
		two_room_cage_root.queue_free()
	two_room_cage_root = null
	two_room_cage_area = null
	if is_instance_valid(two_room_caged_healer):
		two_room_caged_healer.queue_free()
	two_room_caged_healer = null
	if is_instance_valid(two_room_caged_rat):
		two_room_caged_rat.queue_free()
	two_room_caged_rat = null
	if is_instance_valid(two_room_caged_lizard):
		two_room_caged_lizard.queue_free()
	two_room_caged_lizard = null
	if is_instance_valid(two_room_caged_tank):
		two_room_caged_tank.queue_free()
	two_room_caged_tank = null


func _spawn_two_room_final_reward_chest(room_bounds: Rect2) -> void:
	if two_room_final_chest_opened:
		return
	_teardown_two_room_chest()
	var center_x := room_bounds.position.x + (room_bounds.size.x * 0.5)
	var center_y := room_bounds.position.y + (room_bounds.size.y * 0.5)
	var chest_position := Vector2(
		center_x + two_room_test_final_chest_offset_x,
		clampf(
			center_y + two_room_test_final_chest_offset_y,
			room_bounds.position.y + 14.0,
			room_bounds.end.y - 14.0
		)
	)

	var root := Node2D.new()
	root.name = "TwoRoomTreasureChest"
	root.z_index = 10
	root.position = chest_position
	add_child(root)
	two_room_chest_root = root

	var area := Area2D.new()
	area.name = "TreasureChestTrigger"
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 0
	area.collision_mask = 1
	root.add_child(area)
	two_room_chest_area = area

	var trigger_shape := CollisionShape2D.new()
	var trigger_rect := RectangleShape2D.new()
	trigger_rect.size = Vector2(maxf(24.0, two_room_test_chest_width), maxf(18.0, two_room_test_chest_height))
	trigger_shape.shape = trigger_rect
	area.add_child(trigger_shape)
	area.body_entered.connect(_on_two_room_chest_body_entered)

	var half_w := trigger_rect.size.x * 0.5
	var half_h := trigger_rect.size.y * 0.5

	var chest_base := Polygon2D.new()
	chest_base.name = "ChestBase"
	chest_base.color = Color(0.4, 0.24, 0.1, 0.95)
	chest_base.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h * 0.2),
		Vector2(half_w, -half_h * 0.2),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	root.add_child(chest_base)

	var chest_lid := Polygon2D.new()
	chest_lid.name = "ChestLid"
	chest_lid.color = Color(0.56, 0.36, 0.16, 0.96)
	chest_lid.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h * 0.86),
		Vector2(half_w, -half_h * 0.86),
		Vector2(half_w, -half_h * 0.2),
		Vector2(-half_w, -half_h * 0.2)
	])
	root.add_child(chest_lid)

	var outline := Line2D.new()
	outline.default_color = Color(0.92, 0.8, 0.4, 0.9)
	outline.width = 2.0
	outline.closed = true
	outline.points = PackedVector2Array([
		Vector2(-half_w, -half_h * 0.86),
		Vector2(half_w, -half_h * 0.86),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	root.add_child(outline)

	var lock_plate := Polygon2D.new()
	lock_plate.color = Color(0.94, 0.78, 0.3, 0.96)
	var lock_half_w := maxf(3.0, half_w * 0.12)
	lock_plate.polygon = PackedVector2Array([
		Vector2(-lock_half_w, -half_h * 0.2),
		Vector2(lock_half_w, -half_h * 0.2),
		Vector2(lock_half_w, half_h * 0.36),
		Vector2(-lock_half_w, half_h * 0.36)
	])
	root.add_child(lock_plate)


func _teardown_two_room_chest() -> void:
	if is_instance_valid(two_room_chest_root):
		two_room_chest_root.queue_free()
	two_room_chest_root = null
	two_room_chest_area = null


func _spawn_two_room_return_portal(room_bounds: Rect2) -> void:
	_teardown_two_room_return_portal()
	var center_x := room_bounds.position.x + (room_bounds.size.x * 0.5)
	var center_y := room_bounds.position.y + (room_bounds.size.y * 0.5)
	var portal_position := Vector2(
		center_x + two_room_test_return_portal_offset_x,
		clampf(
			center_y + two_room_test_return_portal_offset_y,
			room_bounds.position.y + 18.0,
			room_bounds.end.y - 18.0
		)
	)

	var root := Node2D.new()
	root.name = "TwoRoomReturnPortal"
	root.z_index = 10
	root.position = portal_position
	add_child(root)
	two_room_return_portal_root = root

	var area := Area2D.new()
	area.name = "ReturnPortalTrigger"
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 0
	area.collision_mask = 1
	root.add_child(area)
	two_room_return_portal_area = area

	var trigger_shape := CollisionShape2D.new()
	var trigger_rect := RectangleShape2D.new()
	trigger_rect.size = Vector2(maxf(34.0, two_room_test_return_portal_width), maxf(20.0, two_room_test_return_portal_height))
	trigger_shape.shape = trigger_rect
	area.add_child(trigger_shape)
	area.body_entered.connect(_on_two_room_return_portal_body_entered)

	var half_w := trigger_rect.size.x * 0.5
	var half_h := trigger_rect.size.y * 0.5

	var fill := Polygon2D.new()
	fill.color = Color(0.26, 0.54, 1.0, 0.28)
	fill.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	root.add_child(fill)

	var border := Line2D.new()
	border.default_color = Color(0.52, 0.9, 1.0, 0.9)
	border.width = 2.0
	border.closed = true
	border.points = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	root.add_child(border)

	var arrow := Line2D.new()
	arrow.default_color = Color(0.78, 0.96, 1.0, 0.95)
	arrow.width = 2.2
	var arrow_len := maxf(10.0, half_w * 0.38)
	arrow.points = PackedVector2Array([
		Vector2(arrow_len, -7.0),
		Vector2(-arrow_len, 0.0),
		Vector2(arrow_len, 7.0)
	])
	root.add_child(arrow)

	var label := Label.new()
	label.text = "Portal: Return to Room 1"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(220.0, 24.0)
	label.position = Vector2(-110.0, -half_h - 28.0)
	label.modulate = Color(0.84, 0.96, 1.0, 0.96)
	root.add_child(label)


func _teardown_two_room_return_portal() -> void:
	if is_instance_valid(two_room_return_portal_root):
		two_room_return_portal_root.queue_free()
	two_room_return_portal_root = null
	two_room_return_portal_area = null


func _on_two_room_cage_body_entered(body: Node) -> void:
	if not two_room_test_active:
		return
	var interaction_actor := _get_controlled_adventure_interaction_actor()
	if body == null or interaction_actor == null or not is_instance_valid(interaction_actor) or body != interaction_actor:
		return
	if _is_two_room_cage_locked():
		var room_label := "Room %d" % clampi(two_room_test_room_index, 1, TWO_ROOM_TEST_TOTAL_ROOMS)
		status_message.emit("%s cage locked - defeat enemies first (%d remaining)." % [room_label, maxi(1, alive_regular_enemies)], 1.1)
		_update_objective()
		return
	if _is_tank_caged_for_room(two_room_test_room_index):
		if not tank_caged_active:
			return
		tank_caged_active = false
		adventure_tank_cage_room_index = 0
		tank_party_enabled = true
		_apply_tank_party_state()
		if is_instance_valid(two_room_caged_tank):
			two_room_caged_tank.queue_free()
		two_room_caged_tank = null
		if is_instance_valid(two_room_cage_root):
			two_room_cage_root.queue_free()
		two_room_cage_root = null
		two_room_cage_area = null
		status_message.emit("Tank rescued! Companion joined.", 1.2)
		_update_objective()
		return
	if two_room_test_room_index == 2:
		if two_room_healer_released:
			return
		two_room_healer_released = true
		if is_instance_valid(two_room_caged_healer):
			healer = two_room_caged_healer
			two_room_caged_healer = null
			_connect_companion_died(healer)
			if healer.has_method("set_player") and is_instance_valid(player):
				healer.call("set_player", player)
			var room_two_bounds := _get_two_room_bounds(2)
			if healer.has_method("set_arena_bounds"):
				healer.call(
					"set_arena_bounds",
					room_two_bounds.position.x,
					room_two_bounds.end.x,
					room_two_bounds.position.y,
					room_two_bounds.end.y
				)
			healer.set_process(true)
			healer.set_physics_process(true)
			healer.set_process_input(false)
			_apply_hitbox_debug_to_node(healer)
		if is_instance_valid(two_room_cage_root):
			two_room_cage_root.queue_free()
		two_room_cage_root = null
		two_room_cage_area = null
		status_message.emit("Healer rescued! Companion joined.", 1.2)
		_update_objective()
		return
	if two_room_test_room_index == 3:
		if two_room_rat_released:
			return
		two_room_rat_released = true
		if is_instance_valid(two_room_caged_rat):
			ratfolk = two_room_caged_rat
			two_room_caged_rat = null
			_connect_companion_died(ratfolk)
			if ratfolk.has_method("set_player") and is_instance_valid(player):
				ratfolk.call("set_player", player)
			var room_three_bounds := _get_two_room_bounds(3)
			if ratfolk.has_method("set_arena_bounds"):
				ratfolk.call(
					"set_arena_bounds",
					room_three_bounds.position.x,
					room_three_bounds.end.x,
					room_three_bounds.position.y,
					room_three_bounds.end.y
				)
			ratfolk.set_process(true)
			ratfolk.set_physics_process(true)
			ratfolk.set_process_input(false)
			_apply_hitbox_debug_to_node(ratfolk)
		if is_instance_valid(two_room_cage_root):
			two_room_cage_root.queue_free()
		two_room_cage_root = null
		two_room_cage_area = null
		status_message.emit("Rat rescued! Companion joined.", 1.2)
		objective_changed.emit("Objective: Rat rescued")
		return
	if two_room_test_room_index != 6:
		return
	if two_room_lizard_released:
		return
	two_room_lizard_released = true
	if is_instance_valid(two_room_caged_lizard):
		lizardfolk = two_room_caged_lizard
		two_room_caged_lizard = null
		_connect_companion_died(lizardfolk)
		if lizardfolk.has_method("set_player") and is_instance_valid(player):
			lizardfolk.call("set_player", player)
		var room_six_bounds := _get_two_room_bounds(6)
		if lizardfolk.has_method("set_arena_bounds"):
			lizardfolk.call(
				"set_arena_bounds",
				room_six_bounds.position.x,
				room_six_bounds.end.x,
				room_six_bounds.position.y,
				room_six_bounds.end.y
			)
		lizardfolk.set_process(true)
		lizardfolk.set_physics_process(true)
		lizardfolk.set_process_input(false)
		_apply_hitbox_debug_to_node(lizardfolk)
	if is_instance_valid(two_room_cage_root):
		two_room_cage_root.queue_free()
	two_room_cage_root = null
	two_room_cage_area = null
	status_message.emit("Lizard Ranger rescued! Companion joined.", 1.2)
	_update_objective()


func _is_two_room_cage_locked() -> bool:
	if not two_room_test_active:
		return false
	if _is_tank_caged_for_room(two_room_test_room_index):
		return alive_regular_enemies > 0
	if two_room_test_room_index == 2 and not two_room_healer_released:
		return alive_regular_enemies > 0
	if two_room_test_room_index == 3 and not two_room_rat_released:
		return alive_regular_enemies > 0
	if two_room_test_room_index == 6 and not two_room_lizard_released:
		return alive_regular_enemies > 0
	return false


func _try_auto_release_two_room_cage_if_ready() -> void:
	if _is_two_room_cage_locked():
		return
	if not is_instance_valid(two_room_cage_area):
		return
	var interaction_actor := _get_controlled_adventure_interaction_actor()
	if interaction_actor == null or not is_instance_valid(interaction_actor):
		return
	if not _is_actor_inside_trigger_area(interaction_actor, two_room_cage_area):
		return
	_on_two_room_cage_body_entered(interaction_actor)


func _on_two_room_chest_body_entered(body: Node) -> void:
	if not two_room_test_active:
		return
	if two_room_test_room_index != TWO_ROOM_TEST_TOTAL_ROOMS:
		return
	if two_room_final_chest_opened:
		return
	var interaction_actor := _get_controlled_adventure_interaction_actor()
	if body == null or interaction_actor == null or not is_instance_valid(interaction_actor) or body != interaction_actor:
		return
	if _is_two_room_chest_locked():
		status_message.emit("Treasure chest locked - defeat enemies first (%d remaining)." % maxi(1, alive_regular_enemies), 1.1)
		_update_objective()
		return
	_open_two_room_final_reward_chest()


func _on_two_room_return_portal_body_entered(body: Node) -> void:
	if not two_room_test_active:
		return
	if two_room_test_room_index != TWO_ROOM_TEST_TOTAL_ROOMS:
		return
	if two_room_test_transition_in_progress:
		return
	var interaction_actor := _get_controlled_adventure_interaction_actor()
	if body == null or interaction_actor == null or not is_instance_valid(interaction_actor) or body != interaction_actor:
		return
	status_message.emit("Portal activated - returning to Room 1", 1.0)
	two_room_force_next_transition_spawn_on_left = true
	_transition_two_room_to_room(1)


func _is_two_room_chest_locked() -> bool:
	if not two_room_test_active:
		return false
	if two_room_test_room_index != TWO_ROOM_TEST_TOTAL_ROOMS:
		return false
	if two_room_final_chest_opened:
		return false
	return alive_regular_enemies > 0


func _try_auto_open_two_room_chest_if_ready() -> void:
	if _is_two_room_chest_locked():
		return
	if not is_instance_valid(two_room_chest_area):
		return
	var interaction_actor := _get_controlled_adventure_interaction_actor()
	if interaction_actor == null or not is_instance_valid(interaction_actor):
		return
	if not _is_actor_inside_trigger_area(interaction_actor, two_room_chest_area):
		return
	_on_two_room_chest_body_entered(interaction_actor)


func _is_controlled_actor_inside_trigger_area(area: Area2D) -> bool:
	var interaction_actor := _get_controlled_adventure_interaction_actor()
	return _is_actor_inside_trigger_area(interaction_actor, area)


func _is_actor_inside_trigger_area(actor: Node, area: Area2D) -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	if area == null or not is_instance_valid(area):
		return false
	for body in area.get_overlapping_bodies():
		if body == actor:
			return true
	var actor_node := actor as Node2D
	if actor_node == null or not is_instance_valid(actor_node):
		return false
	for child in area.get_children():
		var collision_shape := child as CollisionShape2D
		if collision_shape == null or not is_instance_valid(collision_shape) or collision_shape.disabled:
			continue
		if _is_point_inside_trigger_shape(collision_shape.to_local(actor_node.global_position), collision_shape.shape):
			return true
	return false


func _is_point_inside_trigger_shape(local_point: Vector2, shape: Shape2D) -> bool:
	if shape == null:
		return false
	var rectangle := shape as RectangleShape2D
	if rectangle != null:
		var half_size := rectangle.size * 0.5
		return absf(local_point.x) <= half_size.x and absf(local_point.y) <= half_size.y
	var circle := shape as CircleShape2D
	if circle != null:
		return local_point.length_squared() <= circle.radius * circle.radius
	return false


func _open_two_room_final_reward_chest() -> void:
	if two_room_final_chest_opened:
		return
	two_room_final_chest_opened = true
	var chest_world_position := Vector2.ZERO
	if is_instance_valid(two_room_chest_root):
		chest_world_position = two_room_chest_root.global_position
	_teardown_two_room_chest()
	var item_id := _select_two_room_chest_pickup_id()
	if not item_id.is_empty():
		var granted_directly := false
		if is_instance_valid(player) and player.has_method("collect_item"):
			player.call("collect_item", item_id, 1)
			granted_directly = true
			two_room_chest_item_received.emit(item_id)
		if not granted_directly:
			_spawn_item_pickup_at_world_position(chest_world_position, item_id)
	status_message.emit("Treasure chest opened!", 1.0)
	if two_room_test_active and two_room_test_room_index >= TWO_ROOM_TEST_TOTAL_ROOMS and alive_regular_enemies <= 0:
		demo_won.emit()
	_update_objective()


func _on_two_room_exit_body_entered(body: Node, target_room_index: int) -> void:
	if not two_room_test_active:
		return
	if two_room_test_room_index < 1:
		return
	if two_room_test_transition_in_progress:
		return
	var interaction_actor := _get_controlled_adventure_interaction_actor()
	if body == null or interaction_actor == null or not is_instance_valid(interaction_actor) or body != interaction_actor:
		return
	var clamped_target := clampi(target_room_index, 1, TWO_ROOM_TEST_TOTAL_ROOMS)
	if clamped_target == two_room_test_room_index:
		return
	_transition_two_room_to_room(clamped_target)


func _try_auto_activate_two_room_exit_if_ready() -> void:
	if not two_room_test_active:
		return
	if two_room_test_transition_in_progress:
		return
	var interaction_actor := _get_controlled_adventure_interaction_actor()
	if interaction_actor == null or not is_instance_valid(interaction_actor):
		return
	if not is_instance_valid(two_room_exit_root):
		return
	for child in two_room_exit_root.get_children():
		var area := child as Area2D
		if area == null or not is_instance_valid(area):
			continue
		var target_room_index := int(area.get_meta("target_room_index", 0))
		if target_room_index <= 0:
			continue
		if _is_actor_inside_trigger_area(interaction_actor, area):
			_on_two_room_exit_body_entered(interaction_actor, target_room_index)
			return


func _try_auto_activate_two_room_return_portal_if_ready() -> void:
	if not two_room_test_active:
		return
	if two_room_test_room_index != TWO_ROOM_TEST_TOTAL_ROOMS:
		return
	if two_room_test_transition_in_progress:
		return
	if not _is_controlled_actor_inside_trigger_area(two_room_return_portal_area):
		return
	var interaction_actor := _get_controlled_adventure_interaction_actor()
	if interaction_actor == null or not is_instance_valid(interaction_actor):
		return
	_on_two_room_return_portal_body_entered(interaction_actor)


func _transition_two_room_to_room(target_room_index: int) -> void:
	if two_room_test_transition_in_progress:
		return
	var local_target_room_index := clampi(target_room_index, 1, TWO_ROOM_TEST_TOTAL_ROOMS)
	if local_target_room_index == two_room_test_room_index:
		return
	var previous_room_index := two_room_test_room_index
	# Starting a new loop from room 1 should allow the final-room chest to spawn again.
	if local_target_room_index == 1 and previous_room_index != 1:
		two_room_final_chest_opened = false
	two_room_test_transition_in_progress = true
	_teardown_two_room_exit()
	_teardown_two_room_cage()
	_teardown_two_room_chest()
	_teardown_two_room_return_portal()
	_clear_two_room_room_enemies()
	status_message.emit("Door crossed - entering Room %d" % local_target_room_index, 0.8)

	if is_instance_valid(player) and player.has_method("set_gameplay_input_blocked"):
		player.call("set_gameplay_input_blocked", true)
	await get_tree().create_timer(maxf(0.0, two_room_test_transition_delay)).timeout

	var next_room_bounds := _get_two_room_bounds(local_target_room_index)
	var room_center_y := next_room_bounds.position.y + (next_room_bounds.size.y * 0.5)
	if is_instance_valid(player):
		var entering_from_left := local_target_room_index > previous_room_index
		if two_room_force_next_transition_spawn_on_left:
			entering_from_left = true
			two_room_force_next_transition_spawn_on_left = false
		var spawn_x := (
			next_room_bounds.position.x + maxf(24.0, two_room_test_spawn_margin_x)
			if entering_from_left
			else next_room_bounds.end.x - maxf(24.0, two_room_test_spawn_margin_x)
		)
		player.position = Vector2(
			spawn_x,
			room_center_y
		)
		_apply_local_bounds_to_player(
			player,
			next_room_bounds.position.x,
			next_room_bounds.end.x,
			next_room_bounds.position.y,
			next_room_bounds.end.y,
			true
		)
	_sync_two_room_rescued_companions(next_room_bounds)
	_spawn_two_room_room_content(local_target_room_index, next_room_bounds)
	two_room_test_room_index = local_target_room_index
	_refresh_two_room_exits_for_room(two_room_test_room_index, next_room_bounds)
	two_room_test_transition_in_progress = false
	if is_instance_valid(player) and player.has_method("set_gameplay_input_blocked"):
		player.call("set_gameplay_input_blocked", false)
	_update_objective()


func _spawn_two_room_room_content(room_index: int, room_bounds: Rect2) -> void:
	match room_index:
		1:
			_spawn_two_room_first_room_cobra(room_bounds)
		2:
			_spawn_two_room_second_room_cobras(room_bounds)
			if not two_room_healer_released or _is_tank_caged_for_room(2):
				_spawn_two_room_healer_cage(room_bounds)
		3:
			_spawn_two_room_third_room_minotaur(room_bounds)
			if not two_room_rat_released or _is_tank_caged_for_room(3):
				_spawn_two_room_rat_cage(room_bounds)
		4:
			_spawn_two_room_fourth_room_minotaurs(room_bounds)
		5:
			_spawn_two_room_fifth_room_cacodemon(room_bounds)
		6:
			_spawn_two_room_sixth_room_final_room(room_bounds)
		_:
			alive_regular_enemies = 0


func _spawn_two_room_first_room_cobra(room_one_bounds: Rect2) -> void:
	alive_regular_enemies = 0
	var center_y := room_one_bounds.position.y + (room_one_bounds.size.y * 0.5)
	var enemy_x := room_one_bounds.end.x - maxf(40.0, two_room_test_spawn_margin_x)
	var enemy := _spawn_enemy(
		MELEE_ENEMY_SCENE,
		to_global(Vector2(enemy_x, center_y)),
		int(EnemyBase.MonsterVisualProfile.COBRA)
	)
	if enemy == null:
		return
	_configure_cobra_enemy(enemy, false)
	_apply_local_bounds_to_enemy(
		enemy,
		room_one_bounds.position.x,
		room_one_bounds.end.x,
		room_one_bounds.position.y,
		room_one_bounds.end.y
	)
	alive_regular_enemies = 1


func _spawn_two_room_second_room_cobras(room_two_bounds: Rect2) -> void:
	alive_regular_enemies = 0
	var center_x := room_two_bounds.position.x + (room_two_bounds.size.x * 0.5)
	var center_y := room_two_bounds.position.y + (room_two_bounds.size.y * 0.5)
	var right_band_start := room_two_bounds.position.x + (room_two_bounds.size.x * clampf(two_room_test_room2_right_spawn_band_start_ratio, 0.55, 0.96))
	var base_spawn_x := room_two_bounds.end.x - maxf(12.0, two_room_test_room2_right_spawn_inset)
	var pull_ratio := clampf(two_room_test_room2_spawn_center_pull_ratio, 0.0, 0.9)
	var y_spacing := maxf(26.0, two_room_test_spawn_vertical_spacing * 0.55)
	var room_min_y := room_two_bounds.position.y + 12.0
	var room_max_y := room_two_bounds.end.y - 12.0
	var x_offsets := PackedFloat32Array([0.0, -24.0, -48.0])
	var y_offsets := PackedFloat32Array([0.0, -y_spacing, y_spacing])
	for i in range(mini(x_offsets.size(), y_offsets.size())):
		var spawn_x := maxf(base_spawn_x + x_offsets[i], right_band_start)
		spawn_x = lerpf(spawn_x, center_x, pull_ratio)
		var y_offset := y_offsets[i]
		var enemy_y := clampf(center_y + y_offset, room_min_y, room_max_y)
		var enemy := _spawn_enemy(
			MELEE_ENEMY_SCENE,
			to_global(Vector2(spawn_x, enemy_y)),
			int(EnemyBase.MonsterVisualProfile.COBRA),
			false
		)
		if enemy == null:
			continue
		_configure_cobra_enemy(enemy, false)
		_apply_local_bounds_to_enemy(
			enemy,
			room_two_bounds.position.x,
			room_two_bounds.end.x,
			room_two_bounds.position.y,
			room_two_bounds.end.y
		)
		alive_regular_enemies += 1


func _sync_two_room_rescued_companions(room_bounds: Rect2) -> void:
	if not is_instance_valid(player):
		return
	var local_min_x := room_bounds.position.x
	var local_max_x := room_bounds.end.x
	var local_min_y := room_bounds.position.y
	var local_max_y := room_bounds.end.y
	var spacing := maxf(16.0, two_room_test_companion_transition_spacing)
	var slot := 0
	var rescued_allies: Array[Node2D] = []
	if is_instance_valid(healer):
		rescued_allies.append(healer)
	if is_instance_valid(ratfolk):
		rescued_allies.append(ratfolk)
	if is_instance_valid(lizardfolk):
		rescued_allies.append(lizardfolk)
	var controlled_actor := _get_controlled_adventure_interaction_actor() as Node2D
	if controlled_actor != null and rescued_allies.has(controlled_actor):
		rescued_allies.erase(controlled_actor)
		rescued_allies.insert(0, controlled_actor)
	var center_x := room_bounds.position.x + (room_bounds.size.x * 0.5)
	var offset_sign := 1.0 if player.position.x <= center_x else -1.0
	for ally in rescued_allies:
		if ally == null or not is_instance_valid(ally):
			continue
		if ally.has_method("set_player"):
			ally.call("set_player", player)
		if ally.has_method("set_arena_bounds"):
			ally.call("set_arena_bounds", local_min_x, local_max_x, local_min_y, local_max_y)
		var offset_x := 0.0
		var offset_y := 0.0
		if ally != controlled_actor:
			offset_x = offset_sign * (spacing + (float(slot) * spacing * 0.55))
			offset_y = (float(slot % 2) * 2.0 - 1.0) * (spacing * 0.35)
			slot += 1
		ally.position = Vector2(
			clampf(player.position.x + offset_x, local_min_x + 10.0, local_max_x - 10.0),
			clampf(player.position.y + offset_y, local_min_y + 10.0, local_max_y - 10.0)
		)
		ally.set_process(true)
		ally.set_physics_process(true)
		ally.set_process_input(false)
		_apply_hitbox_debug_to_node(ally)


func _spawn_two_room_third_room_minotaur(room_three_bounds: Rect2) -> void:
	alive_regular_enemies = 0
	var center_x := room_three_bounds.position.x + (room_three_bounds.size.x * 0.5)
	var center_y := room_three_bounds.position.y + (room_three_bounds.size.y * 0.5)
	var base_spawn_x := room_three_bounds.end.x - maxf(40.0, two_room_test_spawn_margin_x)
	var pull_ratio := clampf(two_room_test_room3_spawn_center_pull_ratio, 0.0, 0.95)
	var spawn_x := lerpf(base_spawn_x, center_x, pull_ratio)
	var enemy := _spawn_enemy(
		MELEE_ENEMY_SCENE,
		to_global(Vector2(spawn_x, center_y)),
		int(EnemyBase.MonsterVisualProfile.MINOTAUR),
		false
	)
	if enemy == null:
		return
	_configure_miniboss(enemy)
	_apply_local_bounds_to_enemy(
		enemy,
		room_three_bounds.position.x,
		room_three_bounds.end.x,
		room_three_bounds.position.y,
		room_three_bounds.end.y
	)
	alive_regular_enemies = 1


func _spawn_two_room_fourth_room_minotaurs(room_four_bounds: Rect2) -> void:
	alive_regular_enemies = 0
	var center_x := room_four_bounds.position.x + (room_four_bounds.size.x * 0.5)
	var center_y := room_four_bounds.position.y + (room_four_bounds.size.y * 0.5)
	var room_min_y := room_four_bounds.position.y + 14.0
	var room_max_y := room_four_bounds.end.y - 14.0
	var base_x := room_four_bounds.end.x - maxf(46.0, two_room_test_spawn_margin_x)
	var pull_ratio := clampf(two_room_test_room4_spawn_center_pull_ratio, 0.0, 0.95)
	var x_offsets := PackedFloat32Array([0.0, -56.0])
	var y_offsets := PackedFloat32Array([-42.0, 42.0])
	for i in range(mini(x_offsets.size(), y_offsets.size())):
		var raw_spawn_x := clampf(base_x + x_offsets[i], room_four_bounds.position.x + 20.0, room_four_bounds.end.x - 20.0)
		var spawn_x := lerpf(raw_spawn_x, center_x, pull_ratio)
		var spawn_y := clampf(center_y + y_offsets[i], room_min_y, room_max_y)
		var enemy := _spawn_enemy(
			MELEE_ENEMY_SCENE,
			to_global(Vector2(spawn_x, spawn_y)),
			int(EnemyBase.MonsterVisualProfile.MINOTAUR),
			false
		)
		if enemy == null:
			continue
		_configure_miniboss(enemy)
		_apply_local_bounds_to_enemy(
			enemy,
			room_four_bounds.position.x,
			room_four_bounds.end.x,
			room_four_bounds.position.y,
			room_four_bounds.end.y
		)
		alive_regular_enemies += 1


func _spawn_two_room_fifth_room_cacodemon(room_five_bounds: Rect2) -> void:
	alive_regular_enemies = 0
	var center_x := room_five_bounds.position.x + (room_five_bounds.size.x * 0.5)
	var center_y := room_five_bounds.position.y + (room_five_bounds.size.y * 0.5)
	var base_spawn_x := room_five_bounds.end.x - maxf(48.0, two_room_test_spawn_margin_x)
	var spawn_x := lerpf(base_spawn_x, center_x, 0.24)
	var enemy := _spawn_enemy(
		MELEE_ENEMY_SCENE,
		to_global(Vector2(spawn_x, center_y)),
		int(EnemyBase.MonsterVisualProfile.CACODEMON),
		false
	)
	if enemy == null:
		return
	_configure_miniboss(enemy)
	_configure_cacodemon_miniboss(enemy)
	_apply_local_bounds_to_enemy(
		enemy,
		room_five_bounds.position.x,
		room_five_bounds.end.x,
		room_five_bounds.position.y,
		room_five_bounds.end.y
	)
	alive_regular_enemies = 1


func _spawn_two_room_sixth_room_final_room(room_six_bounds: Rect2) -> void:
	alive_regular_enemies = 0
	if not two_room_final_chest_opened:
		_spawn_two_room_final_reward_chest(room_six_bounds)
	if not two_room_lizard_released:
		_spawn_two_room_lizard_cage(room_six_bounds)
	if not is_instance_valid(two_room_return_portal_root):
		_spawn_two_room_return_portal(room_six_bounds)


func _clear_two_room_room_enemies() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		enemy.dead = true
		enemy.queue_free()
	alive_regular_enemies = 0


func _spawn_ground_boss_encounter(visual_profile: int) -> EnemyBase:
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	var edge_inset := maxf(8.0, encounter_edge_spawn_inset)
	var spawn_x := max_x - edge_inset
	var spawn_y := lerpf(min_y, max_y, 0.5)
	if is_instance_valid(player):
		spawn_y = clampf(player.position.y, min_y + 8.0, max_y - 8.0)
	var spawn_position := _resolve_encounter_spawn_position(to_global(Vector2(spawn_x, spawn_y)))
	var enemy := _spawn_enemy(MELEE_ENEMY_SCENE, spawn_position, visual_profile)
	if enemy == null:
		return null
	alive_regular_enemies = 1
	return enemy


func _spawn_air_boss_encounter(visual_profile: int) -> void:
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	var edge_inset := maxf(8.0, encounter_edge_spawn_inset)
	var spawn_x := max_x - edge_inset
	var spawn_y := lerpf(min_y, max_y, 0.5)
	if is_instance_valid(player):
		spawn_y = clampf(player.position.y, min_y + 10.0, max_y - 10.0)
	var spawn_position := _resolve_encounter_spawn_position(to_global(Vector2(spawn_x, spawn_y)))
	var enemy := _spawn_enemy(MELEE_ENEMY_SCENE, spawn_position, visual_profile)
	if enemy == null:
		return
	_configure_miniboss(enemy)
	if visual_profile == int(EnemyBase.MonsterVisualProfile.CACODEMON):
		_configure_cacodemon_miniboss(enemy)
	alive_regular_enemies = 1


func _configure_miniboss(enemy: EnemyBase) -> void:
	if enemy == null:
		return
	enemy.is_miniboss = true
	enemy.boss_can_summon_minions = false
	enemy.boss_summon_count = 0
	enemy.max_health = maxf(10.0, enemy.max_health * miniboss_health_scale)
	enemy.current_health = enemy.max_health


func _configure_cacodemon_miniboss(enemy: EnemyBase) -> void:
	if enemy == null:
		return
	enemy.boss_can_summon_minions = true
	enemy.boss_summon_count = 4
	enemy.boss_summon_interval = 20.0
	enemy.boss_summon_cycle_left = 15.0


func _spawn_edge_minotaur() -> void:
	_spawn_edge_minotaur_on_side(spawn_next_debug_enemy_on_left)
	spawn_next_debug_enemy_on_left = not spawn_next_debug_enemy_on_left


func _spawn_edge_minotaur_on_side(spawn_on_left: bool, vertical_offset: float = 0.0) -> void:
	if not _can_spawn_additional_minotaur():
		return
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	var edge_inset := maxf(8.0, encounter_edge_spawn_inset)
	var spawn_x := min_x + edge_inset if spawn_on_left else max_x - edge_inset
	var spawn_y := lerpf(min_y, max_y, 0.5)
	if is_instance_valid(player):
		spawn_y = clampf(player.position.y, min_y + 8.0, max_y - 8.0)
	spawn_y = clampf(spawn_y + vertical_offset, min_y + 8.0, max_y - 8.0)
	var spawn_position := _resolve_encounter_spawn_position(to_global(Vector2(spawn_x, spawn_y)))
	var enemy := _spawn_enemy(MELEE_ENEMY_SCENE, spawn_position)
	if enemy == null:
		return
	_configure_miniboss(enemy)
	if alive_regular_enemies <= 0:
		initial_minotaur_spawn_on_left = spawn_on_left
	alive_regular_enemies += 1
	spawned_minotaurs_total += 1
	_update_objective()


func _can_spawn_additional_minotaur() -> bool:
	var minotaur_cap := _get_minotaur_spawn_cap()
	if spawned_minotaurs_total >= minotaur_cap:
		return false
	return _count_alive_minotaurs() < minotaur_cap


func _get_minotaur_spawn_cap() -> int:
	var minotaur_cap := maxi(1, max_active_minotaurs)
	if not allow_multiple_minotaurs:
		minotaur_cap = 1
	return minotaur_cap


func _count_alive_minotaurs() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if not enemy.is_miniboss:
			continue
		count += 1
	return count


func _get_arena_center_x() -> float:
	return (minf(arena_min_x, arena_max_x) + maxf(arena_min_x, arena_max_x)) * 0.5


func _spawn_enemy(
	scene: PackedScene,
	spawn_position: Vector2,
	visual_profile_override: int = -1,
	apply_default_bounds: bool = true
) -> EnemyBase:
	var enemy := scene.instantiate() as EnemyBase
	if enemy == null:
		push_error("Failed to instantiate enemy scene: %s" % scene.resource_path)
		return null
	if visual_profile_override >= 0:
		enemy.monster_visual_profile = visual_profile_override
	actors.add_child(enemy)
	enemy.global_position = spawn_position
	_apply_hitbox_debug_to_node(enemy)
	if apply_default_bounds:
		_apply_bounds_to_enemy(enemy)
	enemy.died.connect(_on_enemy_died)
	if not enemy.summon_minions_requested.is_connected(_on_enemy_summon_minions_requested):
		enemy.summon_minions_requested.connect(_on_enemy_summon_minions_requested)
	if not enemy.breath_threat.is_connected(_on_enemy_breath_threat):
		enemy.breath_threat.connect(_on_enemy_breath_threat.bind(enemy))
	return enemy


func _on_enemy_summon_minions_requested(source_enemy: EnemyBase, count: int) -> void:
	if not demo_started:
		return
	var use_fire_elemental_profile := source_enemy != null and is_instance_valid(source_enemy) and source_enemy.monster_visual_profile == EnemyBase.MonsterVisualProfile.CACODEMON
	var total_to_spawn := 4 if use_fire_elemental_profile else maxi(1, count)
	var summon_bounds := _get_local_summon_bounds_for_source(source_enemy)
	var min_x := summon_bounds.position.x
	var max_x := summon_bounds.end.x
	var min_y := summon_bounds.position.y
	var max_y := summon_bounds.end.y
	var source_local := to_local(source_enemy.global_position) if is_instance_valid(source_enemy) else Vector2.ZERO
	var spawn_positions: Array[Vector2] = []
	if use_fire_elemental_profile and is_instance_valid(source_enemy):
		var center_local := Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)
		source_enemy.global_position = to_global(center_local)
		source_enemy.velocity = Vector2.ZERO
		source_enemy.knockback_velocity = Vector2.ZERO
		source_local = center_local
		var edge_inset := maxf(8.0, maxf(summoned_minion_edge_inset, encounter_edge_spawn_inset))
		var left_x := min_x + edge_inset
		var right_x := max_x - edge_inset
		var top_y := min_y + edge_inset
		var bottom_y := max_y - edge_inset
		spawn_positions = [
			to_global(Vector2(left_x, top_y)),
			to_global(Vector2(right_x, top_y)),
			to_global(Vector2(left_x, bottom_y)),
			to_global(Vector2(right_x, bottom_y))
		]
	else:
		for i in range(total_to_spawn):
			var spawn_on_left := spawn_next_debug_enemy_on_left
			var spawn_x := (min_x + summoned_minion_edge_inset) if spawn_on_left else (max_x - summoned_minion_edge_inset)
			var y_offset := (float(i) - (float(total_to_spawn - 1) * 0.5)) * summoned_minion_y_spacing
			var spawn_y := clampf(source_local.y + y_offset, min_y + 10.0, max_y - 10.0)
			var spawn_position := to_global(Vector2(spawn_x, spawn_y))
			spawn_positions.append(spawn_position)
			spawn_next_debug_enemy_on_left = not spawn_next_debug_enemy_on_left

	if use_fire_elemental_profile:
		var summon_delay := 0.0
		for spawn_position in spawn_positions:
			var effect := _spawn_imp_summon_pentagram(spawn_position)
			if effect == null or not is_instance_valid(effect):
				continue
			if effect.has_method("get_expected_duration"):
				var duration_variant: Variant = effect.call("get_expected_duration")
				if duration_variant is float:
					summon_delay = maxf(summon_delay, float(duration_variant))
		if summon_delay > 0.0:
			await get_tree().create_timer(summon_delay).timeout
		if not demo_started:
			return

	var spawn_stagger := maxf(0.0, summoned_imp_spawn_stagger) if use_fire_elemental_profile else 0.0
	if use_fire_elemental_profile:
		# Spread fire-elemental instantiation over a few frames to avoid a single-frame hitch.
		spawn_stagger = maxf(spawn_stagger, 0.08)
	for spawn_index in range(spawn_positions.size()):
		var spawn_position := spawn_positions[spawn_index]
		var minion_profile := int(EnemyBase.MonsterVisualProfile.FIRE_ELEMENTAL) if use_fire_elemental_profile else -1
		var minion := _spawn_enemy(MELEE_ENEMY_SCENE, spawn_position, minion_profile, false)
		if minion == null:
			continue
		_apply_local_bounds_to_enemy(minion, min_x, max_x, min_y, max_y)
		minion.is_miniboss = false
		minion.use_single_phase_loop = false
		minion.boss_can_summon_minions = false
		minion.spin_attack_enabled = false
		minion.prioritize_companion_targets = true
		minion.max_health = maxf(10.0, minion.max_health * summoned_minion_health_scale)
		if use_fire_elemental_profile:
			minion.max_health = maxf(10.0, minion.max_health * maxf(0.0, summoned_imp_health_multiplier))
		minion.current_health = minion.max_health
		minion.move_speed = maxf(40.0, minion.move_speed * summoned_minion_speed_scale)
		minion.attack_damage = maxf(1.0, minion.attack_damage * summoned_minion_damage_scale)
		if use_fire_elemental_profile:
			minion.attack_damage = maxf(1.0, minion.attack_damage * maxf(0.0, summoned_imp_damage_multiplier))
		if use_fire_elemental_profile:
			minion.pending_attack = false
			minion.attack_windup_left = 0.0
			minion.attack_prestrike_hold_left = 0.0
			minion.attack_recovery_hold_left = 0.0
			minion.attack_prestrike_hold_duration = maxf(minion.attack_prestrike_hold_duration, 0.05)
			minion.attack_hold_frame = 2
			# Fire elementals should be immediate melee threats.
			minion.attack_cooldown_left = minf(minion.attack_cooldown_left, 0.2)
			minion.attack_cooldown = minf(minion.attack_cooldown, 1.1)
			minion.attack_windup = minf(minion.attack_windup, 0.18)
			minion.attack_range = maxf(minion.attack_range, 56.0)
			minion.velocity = Vector2.ZERO
			if is_instance_valid(player):
				var to_player := player.global_position - minion.global_position
				if to_player.length_squared() > 0.0001:
					var facing := to_player.normalized()
					minion.external_sprite_facing_direction = facing
					minion.committed_attack_facing_direction = facing
		minion.xp_reward = maxi(1, int(round(float(minion.xp_reward) * summoned_minion_xp_scale)))
		alive_regular_enemies += 1
		if spawn_stagger > 0.0 and spawn_index < (spawn_positions.size() - 1):
			await get_tree().create_timer(spawn_stagger).timeout
	_update_objective()


func _get_local_summon_bounds_for_source(source_enemy: EnemyBase) -> Rect2:
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	if source_enemy != null and is_instance_valid(source_enemy):
		var source_min_x := minf(source_enemy.lane_min_x, source_enemy.lane_max_x)
		var source_max_x := maxf(source_enemy.lane_min_x, source_enemy.lane_max_x)
		var source_min_y := minf(source_enemy.lane_min_y, source_enemy.lane_max_y)
		var source_max_y := maxf(source_enemy.lane_min_y, source_enemy.lane_max_y)
		if source_max_x > source_min_x + 8.0 and source_max_y > source_min_y + 8.0:
			min_x = source_min_x
			max_x = source_max_x
			min_y = source_min_y
			max_y = source_max_y
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func _spawn_imp_summon_pentagram(spawn_position: Vector2) -> Node2D:
	if not imp_summon_pentagram_enabled:
		return null
	var effect := IMP_SUMMON_PENTAGRAM_EFFECT_SCRIPT.new() as Node2D
	if effect == null:
		return null
	actors.add_child(effect)
	effect.global_position = spawn_position + Vector2(0.0, imp_summon_pentagram_y_offset)
	return effect


func _prewarm_imp_summon_effect_cache() -> void:
	if selected_encounter != EncounterType.CACODEMON \
		and selected_encounter != EncounterType.SHARDSOUL \
		and selected_encounter != EncounterType.COBRA_TWO_ROOM_TEST:
		return
	EnemyBase.warm_fire_elemental_visual_cache()
	if not imp_summon_pentagram_enabled:
		return
	ImpSummonPentagramEffect.warm_cache()


func _on_enemy_breath_threat(active: bool, boss_pos: Vector2, dir: Vector2, time_remaining: float, source_enemy: EnemyBase) -> void:
	if not active:
		return
	if source_enemy == null or not is_instance_valid(source_enemy):
		return
	if not source_enemy.has_method("get_breath_threat_snapshot"):
		return
	var snapshot_variant: Variant = source_enemy.call("get_breath_threat_snapshot")
	if not (snapshot_variant is Dictionary):
		return
	var snapshot := snapshot_variant as Dictionary
	if not bool(snapshot.get("charge_active", false)):
		return
	status_message.emit("BREATH INCOMING!", 0.85)


func _has_any_alive_enemy() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.dead:
			continue
		return true
	return false


func _apply_bounds_to_player(target_player: Player) -> void:
	_apply_local_bounds_to_player(
		target_player,
		arena_min_x,
		arena_max_x,
		arena_min_y,
		arena_max_y,
		true
	)


func _apply_local_bounds_to_player(
	target_player: Player,
	min_x: float,
	max_x: float,
	min_y: float,
	max_y: float,
	configure_camera: bool = false
) -> void:
	if target_player == null:
		return
	var local_min_x := minf(min_x, max_x)
	var local_max_x := maxf(min_x, max_x)
	var local_min_y := minf(min_y, max_y)
	var local_max_y := maxf(min_y, max_y)
	target_player.set_arena_bounds(local_min_x, local_max_x, local_min_y, local_max_y)
	target_player.position.x = clampf(target_player.position.x, local_min_x, local_max_x)
	target_player.position.y = clampf(target_player.position.y, local_min_y, local_max_y)
	if not configure_camera:
		return
	var top_left := to_global(Vector2(local_min_x, local_min_y))
	var bottom_right := to_global(Vector2(local_max_x, local_max_y))
	var global_bounds := Rect2(top_left, bottom_right - top_left)
	target_player.configure_camera_limits(
		global_bounds.position.x - camera_limit_padding.x,
		global_bounds.position.y - camera_limit_padding.y,
		global_bounds.end.x + camera_limit_padding.x,
		global_bounds.end.y + camera_limit_padding.y
	)
	target_player.apply_encounter_start_camera_focus(global_bounds)


func _apply_bounds_to_enemy(enemy: EnemyBase) -> void:
	_apply_local_bounds_to_enemy(
		enemy,
		arena_min_x,
		arena_max_x,
		arena_min_y,
		arena_max_y
	)


func _apply_local_bounds_to_enemy(
	enemy: EnemyBase,
	min_x: float,
	max_x: float,
	min_y: float,
	max_y: float
) -> void:
	if enemy == null:
		return
	var local_min_x := minf(min_x, max_x)
	var local_max_x := maxf(min_x, max_x)
	var local_min_y := minf(min_y, max_y)
	var local_max_y := maxf(min_y, max_y)
	enemy.set_arena_bounds(local_min_x, local_max_x, local_min_y, local_max_y)
	enemy.position.x = clampf(enemy.position.x, local_min_x, local_max_x)
	enemy.position.y = clampf(enemy.position.y, local_min_y, local_max_y)


func _get_global_arena_bounds() -> Rect2:
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	var top_left := to_global(Vector2(min_x, min_y))
	var bottom_right := to_global(Vector2(max_x, max_y))
	return Rect2(top_left, bottom_right - top_left)


func _on_enemy_died(enemy: EnemyBase) -> void:
	if is_instance_valid(player):
		player.add_experience(enemy.xp_reward)

	_award_enemy_gold_drop(enemy)

	alive_regular_enemies = max(0, alive_regular_enemies - 1)
	if selected_encounter == EncounterType.COBRA_TWO_ROOM_TEST:
		var room_five_cacodemon_killed := (
			two_room_test_room_index == 5
			and enemy != null
			and enemy.monster_visual_profile == EnemyBase.MonsterVisualProfile.CACODEMON
		)
		if room_five_cacodemon_killed:
			# Ensure the room 6 door appears even if any summoned adds were previously counted.
			alive_regular_enemies = 0
		if two_room_test_room_index >= 1:
			var room_bounds := _get_two_room_bounds(two_room_test_room_index)
			_refresh_two_room_exits_for_room(two_room_test_room_index, room_bounds)
			if alive_regular_enemies <= 0:
				if two_room_test_room_index == 5:
					status_message.emit("Cacodemon defeated - proceed to the final room.", 1.2)
				call_deferred("_try_auto_release_two_room_cage_if_ready")
				call_deferred("_try_auto_open_two_room_chest_if_ready")
	if alive_regular_enemies == 0:
		objective_changed.emit("Objective: Victory")
		demo_won.emit()
		return
	_update_objective()


func _award_enemy_gold_drop(enemy: EnemyBase) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if not is_instance_valid(player) or not player.has_method("add_gold"):
		return
	var gold_amount := _get_enemy_gold_drop_amount(enemy)
	if gold_amount <= 0:
		return
	player.call("add_gold", gold_amount)
	status_message.emit("+%d Gold" % gold_amount, 0.55)


func _get_enemy_gold_drop_amount(enemy: EnemyBase) -> int:
	if enemy == null:
		return 0
	match enemy.monster_visual_profile:
		EnemyBase.MonsterVisualProfile.CACODEMON:
			return rng.randi_range(9, 12)
		EnemyBase.MonsterVisualProfile.MINOTAUR:
			return rng.randi_range(6, 8)
		EnemyBase.MonsterVisualProfile.COBRA:
			return rng.randi_range(3, 4)
		EnemyBase.MonsterVisualProfile.SHARDSOUL:
			return rng.randi_range(8, 11)
		EnemyBase.MonsterVisualProfile.IMP:
			return rng.randi_range(1, 2)
		EnemyBase.MonsterVisualProfile.FIRE_ELEMENTAL:
			return rng.randi_range(2, 3)
		_:
			return rng.randi_range(1, 2)


func _try_spawn_item_drop(enemy: EnemyBase) -> void:
	if selected_encounter == EncounterType.COBRA_TWO_ROOM_TEST:
		if enemy == null or not is_instance_valid(enemy):
			return
		if enemy.monster_visual_profile != EnemyBase.MonsterVisualProfile.COBRA:
			return
		var loot_item_id := _select_two_room_loot_pickup_id()
		if loot_item_id.is_empty():
			return
		_spawn_item_pickup(enemy, loot_item_id)
		two_room_loot_drop_count += 1
		return
	if enemy.drop_table.is_empty():
		return
	if rng.randf() > enemy.drop_chance:
		return

	var item_id: String = enemy.drop_table[rng.randi_range(0, enemy.drop_table.size() - 1)]
	_spawn_item_pickup(enemy, item_id)


func _spawn_item_pickup(enemy: EnemyBase, item_id: String) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	_spawn_item_pickup_at_world_position(enemy.global_position, item_id)


func _spawn_item_pickup_at_world_position(world_position: Vector2, item_id: String) -> void:
	if item_id.is_empty():
		return
	var pickup := ITEM_SCENE.instantiate() as ItemPickup
	if pickup == null:
		return
	drops.add_child(pickup)
	pickup.global_position = world_position + Vector2(
		rng.randf_range(-10.0, 10.0),
		rng.randf_range(-10.0, 10.0)
	)
	pickup.set_item(item_id, 1)


func _select_two_room_chest_pickup_id() -> String:
	var pool := _get_two_room_chest_pickup_pool()
	if pool.is_empty():
		return ""
	if is_instance_valid(player) and player.has_method("get_missing_ring_ids"):
		var missing_pool: Array[String] = []
		var missing_ring_ids: Array = player.call("get_missing_ring_ids")
		for ring_id_variant in missing_ring_ids:
			var ring_id := String(ring_id_variant)
			var pickup_id := String(TWO_ROOM_RING_PICKUP_BY_RING_ID.get(ring_id, ""))
			if pickup_id.is_empty():
				continue
			missing_pool.append(pickup_id)
		if not missing_pool.is_empty():
			return missing_pool[rng.randi_range(0, missing_pool.size() - 1)]
	return pool[rng.randi_range(0, pool.size() - 1)]


func _get_two_room_chest_pickup_pool() -> Array[String]:
	return TWO_ROOM_RING_PICKUP_IDS.duplicate()


func _select_two_room_loot_pickup_id() -> String:
	if two_room_loot_drop_count <= 0:
		return "shield_revenge"

	var missing_shield_candidates: Array[String] = []
	if is_instance_valid(player) and player.has_method("get_missing_shield_ids"):
		var missing_shield_variants: Array = player.call("get_missing_shield_ids")
		for shield_variant in missing_shield_variants:
			var shield_id := String(shield_variant)
			var pickup_id := String(TWO_ROOM_SHIELD_PICKUP_BY_SHIELD_ID.get(shield_id, ""))
			if pickup_id.is_empty() or pickup_id == "shield_revenge":
				continue
			missing_shield_candidates.append(pickup_id)
	if not missing_shield_candidates.is_empty():
		return missing_shield_candidates[rng.randi_range(0, missing_shield_candidates.size() - 1)]

	if is_instance_valid(player) and player.has_method("has_inventory_item"):
		for boot_pickup_id in TWO_ROOM_BOOT_PICKUP_IDS:
			var has_boot_pickup := bool(player.call("has_inventory_item", boot_pickup_id))
			if not has_boot_pickup:
				return boot_pickup_id

	var candidates: Array[String] = []
	if is_instance_valid(player) and player.has_method("get_missing_sword_ids"):
		var missing_variants: Array = player.call("get_missing_sword_ids")
		for sword_variant in missing_variants:
			var sword_id := String(sword_variant)
			var pickup_id := String(TWO_ROOM_SWORD_PICKUP_BY_SWORD_ID.get(sword_id, ""))
			if pickup_id.is_empty():
				continue
			candidates.append(pickup_id)
	if candidates.is_empty():
		candidates.assign(TWO_ROOM_SWORD_PICKUP_IDS)
	if candidates.is_empty():
		return ""
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _update_objective() -> void:
	if not demo_started:
		objective_changed.emit("Objective: Prepare for combat")
		return
	if selected_encounter == EncounterType.COBRA_TWO_ROOM_TEST:
		if two_room_test_room_index <= 0:
			objective_changed.emit("Objective: Enter the 6-room test")
			return
		if two_room_test_room_index == 1:
			if alive_regular_enemies > 0:
				objective_changed.emit("Objective: Room 1 - Defeat the Cobra")
			elif two_room_test_transition_in_progress:
				objective_changed.emit("Objective: Transitioning to room 2...")
			else:
				objective_changed.emit("Objective: Proceed through the door")
			return
		if two_room_test_room_index == 2:
			var tank_caged_here := _is_tank_caged_for_room(2)
			if alive_regular_enemies > 0:
				if tank_caged_here:
					objective_changed.emit("Objective: Room 2 - Defeat cobras to unlock Tank cage (%d remaining)" % alive_regular_enemies)
				elif two_room_healer_released:
					objective_changed.emit("Objective: Room 2 - Defeat cobras (%d remaining)" % alive_regular_enemies)
				else:
					objective_changed.emit("Objective: Room 2 - Defeat cobras to unlock Healer cage (%d remaining)" % alive_regular_enemies)
			elif two_room_test_transition_in_progress:
				objective_changed.emit("Objective: Transitioning to room 3...")
			else:
				if tank_caged_here:
					objective_changed.emit("Objective: Room 2 clear - Rescue the Tank (cage unlocked)")
				elif two_room_healer_released:
					objective_changed.emit("Objective: Room 2 clear - Proceed through the door")
				else:
					objective_changed.emit("Objective: Room 2 clear - Rescue the Healer (cage unlocked)")
			return
		if two_room_test_room_index == 3:
			var tank_caged_here := _is_tank_caged_for_room(3)
			if alive_regular_enemies > 0:
				if tank_caged_here:
					objective_changed.emit("Objective: Room 3 - Defeat the Minotaur to unlock Tank cage")
				elif two_room_rat_released:
					objective_changed.emit("Objective: Room 3 - Defeat the Minotaur")
				else:
					objective_changed.emit("Objective: Room 3 - Defeat the Minotaur to unlock Rat cage")
			elif two_room_test_transition_in_progress:
				objective_changed.emit("Objective: Transitioning to room 4...")
			else:
				if tank_caged_here:
					objective_changed.emit("Objective: Room 3 clear - Rescue the Tank (cage unlocked)")
				elif two_room_rat_released:
					objective_changed.emit("Objective: Room 3 clear - Proceed through the door")
				else:
					objective_changed.emit("Objective: Room 3 clear - Rescue Rat (cage unlocked)")
			return
		if two_room_test_room_index == 4:
			if alive_regular_enemies > 0:
				objective_changed.emit("Objective: Room 4 - Defeat Minotaurs (%d remaining)" % alive_regular_enemies)
			elif two_room_test_transition_in_progress:
				objective_changed.emit("Objective: Transitioning to room 5...")
			else:
				objective_changed.emit("Objective: Room 4 clear - Proceed through the door")
			return
		if two_room_test_room_index == 5:
			if alive_regular_enemies > 0:
				objective_changed.emit("Objective: Room 5 - Defeat the Cacodemon")
			elif two_room_test_transition_in_progress:
				objective_changed.emit("Objective: Transitioning to room 6...")
			else:
				objective_changed.emit("Objective: Room 5 clear - Proceed to the final room")
			return
		if two_room_test_room_index == 6:
			if not two_room_lizard_released:
				objective_changed.emit("Objective: Final room - Rescue the Lizard Ranger")
			elif not two_room_final_chest_opened:
				objective_changed.emit("Objective: Final room - Open the treasure chest")
			else:
				objective_changed.emit("Objective: Final room clear - Use the portal to return")
			return
		if alive_regular_enemies > 0:
			objective_changed.emit("Objective: Defeat enemies (%d remaining)" % alive_regular_enemies)
		else:
			objective_changed.emit("Objective: Victory")
		return
	if alive_regular_enemies <= 0:
		objective_changed.emit("Objective: Victory")
		return
	if selected_encounter == EncounterType.CACODEMON:
		objective_changed.emit("Objective: Defeat the Cacodemon")
		return
	if selected_encounter == EncounterType.COBRA:
		objective_changed.emit("Objective: Defeat the Cobra")
		return
	if selected_encounter == EncounterType.SHARDSOUL:
		objective_changed.emit("Objective: Defeat the Shardsoul")
		return
	objective_changed.emit("Objective: Defeat enemies (%d remaining)" % alive_regular_enemies)


func _emit_combat_debug() -> void:
	var tank_basic_cd_left := 0.0
	if is_instance_valid(player):
		tank_basic_cd_left = player.basic_attack_cooldown_left

	var healer_state := "-"
	var healer_target := "-"
	if is_instance_valid(healer):
		if healer.has_method("get_ai_debug_state"):
			healer_state = String(healer.call("get_ai_debug_state"))
		if healer.has_method("get_ai_debug_target"):
			healer_target = String(healer.call("get_ai_debug_target"))
	var dps_state := "-"
	var dps_target := "-"
	var primary_dps_companion: Node2D = ratfolk if is_instance_valid(ratfolk) else lizardfolk
	if is_instance_valid(primary_dps_companion):
		if primary_dps_companion.has_method("get_ai_debug_state"):
			dps_state = String(primary_dps_companion.call("get_ai_debug_state"))
		if primary_dps_companion.has_method("get_ai_debug_target"):
			dps_target = String(primary_dps_companion.call("get_ai_debug_target"))

	var marked_ally := "-"
	var boss_state := "Idle"
	var vulnerable_left := 0.0
	var boss_windup_duration := 0.0
	var boss_lunge_cycle_left := 0.0
	var minion_count := 0
	var clone_count := 0
	var breath_state := "Idle"
	var breath_time_left := 0.0
	var tank_blocking := is_instance_valid(player) and player.is_blocking
	var pocket_valid := false
	var companions_safe := 0

	var debug_boss := _get_debug_boss()
	if debug_boss != null:
		if debug_boss.has_method("get_boss_marked_ally_name"):
			marked_ally = String(debug_boss.call("get_boss_marked_ally_name"))
		if debug_boss.has_method("get_boss_debug_state"):
			boss_state = String(debug_boss.call("get_boss_debug_state"))
		if debug_boss.has_method("get_boss_vulnerable_time_left"):
			var vulnerable_variant: Variant = debug_boss.call("get_boss_vulnerable_time_left")
			if vulnerable_variant is float:
				vulnerable_left = vulnerable_variant
			elif vulnerable_variant is int:
				vulnerable_left = float(vulnerable_variant)
		if debug_boss.has_method("get_breath_threat_snapshot"):
			var breath_variant: Variant = debug_boss.call("get_breath_threat_snapshot")
			if breath_variant is Dictionary:
				var breath_snapshot := breath_variant as Dictionary
				breath_state = String(breath_snapshot.get("state_name", "Idle"))
				breath_time_left = float(breath_snapshot.get("time_remaining", 0.0))
				tank_blocking = bool(breath_snapshot.get("tank_blocking", tank_blocking))
				pocket_valid = bool(breath_snapshot.get("safe_pocket_valid", false))
				companions_safe = COMPANION_BREATH_RESPONSE_SCRIPT.count_friendlies_in_pocket(get_tree(), breath_snapshot)
		boss_windup_duration = debug_boss.boss_windup_duration
		boss_lunge_cycle_left = debug_boss.boss_mark_cycle_left

	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if not enemy.is_miniboss:
			minion_count += 1

	for clone_node in get_tree().get_nodes_in_group("shadow_clones"):
		var clone := clone_node as Node2D
		if clone == null or not is_instance_valid(clone):
			continue
		clone_count += 1

	combat_debug_changed.emit({
		"healer_state": healer_state,
		"healer_target": healer_target,
		"dps_state": dps_state,
		"dps_target": dps_target,
		"marked_ally": marked_ally,
		"boss_state": boss_state,
		"boss_vulnerable_left": vulnerable_left,
		"tank_basic_cd_left": tank_basic_cd_left,
		"boss_windup_duration": boss_windup_duration,
		"boss_lunge_cycle_left": boss_lunge_cycle_left,
		"minion_count": minion_count,
		"clone_count": clone_count,
		"breath_state": breath_state,
		"breath_time_left": breath_time_left,
		"tank_blocking": tank_blocking,
		"pocket_valid": pocket_valid,
		"companions_safe": companions_safe
	})


func _get_debug_boss() -> EnemyBase:
	var nearest_enemy: EnemyBase = null
	var nearest_dist_sq := INF
	var player_position := player.global_position if is_instance_valid(player) else global_position
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		var dist_sq := enemy.global_position.distance_squared_to(player_position)
		if nearest_enemy == null or dist_sq < nearest_dist_sq:
			nearest_enemy = enemy
			nearest_dist_sq = dist_sq
	return nearest_enemy


func force_debug_boss_breath() -> void:
	var debug_boss := _get_debug_boss()
	if debug_boss == null or not is_instance_valid(debug_boss):
		return
	if debug_boss.has_method("debug_force_cacodemon_breath"):
		debug_boss.call("debug_force_cacodemon_breath")


func cycle_debug_breath_vfx_mode() -> int:
	var debug_boss := _get_debug_boss()
	if debug_boss == null or not is_instance_valid(debug_boss):
		return -1
	if debug_boss.has_method("cycle_cacodemon_breath_visual_mode"):
		return int(debug_boss.call("cycle_cacodemon_breath_visual_mode"))
	return -1


func toggle_player_auto_block() -> bool:
	if not is_instance_valid(player):
		return false
	if player.has_method("toggle_debug_auto_block"):
		return bool(player.call("toggle_debug_auto_block"))
	return false


func get_adventure_room_count() -> int:
	return TWO_ROOM_TEST_TOTAL_ROOMS


func is_adventure_mode_active() -> bool:
	return demo_started and two_room_test_active and selected_encounter == EncounterType.COBRA_TWO_ROOM_TEST


func apply_adventure_death_penalty() -> Dictionary:
	var result := {
		"applied": false,
		"gold_before": 0,
		"gold_lost": 0,
		"gold_remaining": 0
	}
	if not is_adventure_mode_active():
		return result
	if not is_instance_valid(player):
		return result
	if not player.has_method("get_gold_total") or not player.has_method("add_gold"):
		return result
	var gold_before := maxi(0, int(player.call("get_gold_total")))
	var gold_lost := maxi(0, ceili(float(gold_before) * 0.5))
	if gold_lost > 0:
		player.call("add_gold", -gold_lost)
	var gold_remaining := maxi(0, int(player.call("get_gold_total")))
	result["applied"] = true
	result["gold_before"] = gold_before
	result["gold_lost"] = gold_lost
	result["gold_remaining"] = gold_remaining
	return result


func _ensure_rescued_adventure_companions_spawned() -> void:
	if not two_room_test_active:
		return
	if two_room_healer_released and not is_instance_valid(healer):
		_spawn_friendly_healer()
	if two_room_rat_released and not is_instance_valid(ratfolk):
		_spawn_friendly_ratfolk()
	if two_room_lizard_released and not is_instance_valid(lizardfolk):
		_spawn_friendly_lizardfolk()
	_apply_control_mode_runtime()


func _revive_party_member_if_needed(member: Node2D) -> void:
	if member == null or not is_instance_valid(member):
		return
	if member.has_method("revive_at_full_health"):
		member.call("revive_at_full_health")
	if member.has_method("set_player") and is_instance_valid(player):
		member.call("set_player", player)
	member.set_process(true)
	member.set_physics_process(true)
	member.set_process_input(false)
	_apply_hitbox_debug_to_node(member)
	_apply_control_mode_runtime()


func _revive_active_adventure_companions() -> void:
	_revive_party_member_if_needed(healer)
	_revive_party_member_if_needed(ratfolk)
	_revive_party_member_if_needed(lizardfolk)


func recover_from_adventure_death() -> bool:
	if not is_adventure_mode_active():
		return false
	if not is_instance_valid(player):
		return false
	if player.has_method("set_gameplay_input_blocked"):
		player.call("set_gameplay_input_blocked", true)
	if not player.has_method("revive_at_full_health"):
		if player.has_method("set_gameplay_input_blocked"):
			player.call("set_gameplay_input_blocked", false)
		return false
	player.call("revive_at_full_health")
	if two_room_test_transition_in_progress:
		if player.has_method("set_gameplay_input_blocked"):
			player.call("set_gameplay_input_blocked", false)
		return false
	_ensure_rescued_adventure_companions_spawned()
	_revive_active_adventure_companions()
	_apply_control_mode_runtime()
	party_defeat_emitted = false
	two_room_force_next_transition_spawn_on_left = true
	if two_room_test_room_index > 1:
		_transition_two_room_to_room(1)
		status_message.emit("You were defeated - returning to Room 1.", 1.0)
		return true
	_reset_adventure_to_room_one_after_death()
	status_message.emit("You were defeated - returned to Room 1.", 1.1)
	return true


func _reset_adventure_to_room_one_after_death() -> void:
	two_room_test_transition_in_progress = true
	_teardown_two_room_exit()
	_teardown_two_room_cage()
	_teardown_two_room_chest()
	_teardown_two_room_return_portal()
	_clear_two_room_room_enemies()
	var room_one_bounds := _get_two_room_bounds(1)
	var room_center_y := room_one_bounds.position.y + (room_one_bounds.size.y * 0.5)
	if is_instance_valid(player):
		player.position = Vector2(
			room_one_bounds.position.x + maxf(24.0, two_room_test_spawn_margin_x),
			room_center_y
		)
		_apply_local_bounds_to_player(
			player,
			room_one_bounds.position.x,
			room_one_bounds.end.x,
			room_one_bounds.position.y,
			room_one_bounds.end.y,
			true
		)
	_sync_two_room_rescued_companions(room_one_bounds)
	_spawn_two_room_room_content(1, room_one_bounds)
	two_room_test_room_index = 1
	_refresh_two_room_exits_for_room(1, room_one_bounds)
	two_room_test_transition_in_progress = false
	if is_instance_valid(player) and player.has_method("set_gameplay_input_blocked"):
		player.call("set_gameplay_input_blocked", false)
	_update_objective()


func debug_jump_to_adventure_room(target_room_index: int) -> bool:
	if selected_encounter != EncounterType.COBRA_TWO_ROOM_TEST or not demo_started or not two_room_test_active:
		status_message.emit("Adventure Mode must be active before jumping rooms.", 1.25)
		return false
	if two_room_test_transition_in_progress:
		status_message.emit("Room transition already in progress.", 0.9)
		return false
	var clamped_target := clampi(target_room_index, 1, TWO_ROOM_TEST_TOTAL_ROOMS)
	if clamped_target == two_room_test_room_index:
		status_message.emit("Already in Adventure Room %d." % clamped_target, 0.9)
		return false
	# For testing, always enter debug-jumped rooms from the left side.
	two_room_force_next_transition_spawn_on_left = true
	_transition_two_room_to_room(clamped_target)
	return true


func _is_healer_control_available() -> bool:
	if not is_instance_valid(healer):
		return false
	var healer_ref := healer as FriendlyHealer
	if healer_ref != null and healer_ref.dead:
		return false
	if two_room_test_active:
		return two_room_healer_released
	if not _encounter_uses_companions():
		return false
	return _is_party_member_enabled(PARTY_MEMBER_HEALER, true)


func _is_ratfolk_control_available() -> bool:
	if not is_instance_valid(ratfolk):
		return false
	var ratfolk_ref := ratfolk as FriendlyRatfolk
	if ratfolk_ref != null and ratfolk_ref.dead:
		return false
	if two_room_test_active:
		return two_room_rat_released
	if not _encounter_uses_companions():
		return false
	return _is_party_member_enabled(PARTY_MEMBER_RATFOLK, true)


func _is_lizardfolk_control_available() -> bool:
	if not is_instance_valid(lizardfolk):
		return false
	var lizardfolk_ref := lizardfolk as FriendlyLizardfolk
	if lizardfolk_ref != null and lizardfolk_ref.dead:
		return false
	if two_room_test_active:
		return two_room_lizard_released
	if not _encounter_uses_companions():
		return false
	return _is_party_member_enabled(PARTY_MEMBER_LIZARDFOLK, true)


func _get_next_available_control_id() -> String:
	if _is_healer_control_available():
		return CONTROLLED_CHARACTER_HEALER
	if _is_ratfolk_control_available():
		return CONTROLLED_CHARACTER_RATFOLK
	if _is_lizardfolk_control_available():
		return CONTROLLED_CHARACTER_LIZARDFOLK
	return CONTROLLED_CHARACTER_TANK


func _apply_control_mode_runtime() -> void:
	if controlled_character_id == CONTROLLED_CHARACTER_HEALER and not _is_healer_control_available():
		controlled_character_id = _get_next_available_control_id()
	if controlled_character_id == CONTROLLED_CHARACTER_RATFOLK and not _is_ratfolk_control_available():
		controlled_character_id = _get_next_available_control_id()
	if controlled_character_id == CONTROLLED_CHARACTER_LIZARDFOLK and not _is_lizardfolk_control_available():
		controlled_character_id = _get_next_available_control_id()
	if controlled_character_id == CONTROLLED_CHARACTER_TANK and not tank_party_enabled:
		if tank_caged_active:
			controlled_character_id = _get_next_available_control_id()
		else:
			tank_party_enabled = true
			_enable_tank_actor()
	var manual_healer_control := controlled_character_id == CONTROLLED_CHARACTER_HEALER and _is_healer_control_available()
	var manual_ratfolk_control := controlled_character_id == CONTROLLED_CHARACTER_RATFOLK and _is_ratfolk_control_available()
	var manual_lizardfolk_control := controlled_character_id == CONTROLLED_CHARACTER_LIZARDFOLK and _is_lizardfolk_control_available()
	if is_instance_valid(player) and player.has_method("set_ai_control_enabled"):
		player.call("set_ai_control_enabled", manual_healer_control or manual_ratfolk_control or manual_lizardfolk_control)
	if is_instance_valid(healer) and healer.has_method("set_manual_control_enabled"):
		healer.call("set_manual_control_enabled", manual_healer_control)
	if is_instance_valid(ratfolk) and ratfolk.has_method("set_manual_control_enabled"):
		ratfolk.call("set_manual_control_enabled", manual_ratfolk_control)
	if is_instance_valid(lizardfolk) and lizardfolk.has_method("set_manual_control_enabled"):
		lizardfolk.call("set_manual_control_enabled", manual_lizardfolk_control)
	if is_instance_valid(player) and player.has_method("_emit_cooldown_state"):
		player.call("_emit_cooldown_state")


func _is_manual_healer_control_active() -> bool:
	if controlled_character_id != CONTROLLED_CHARACTER_HEALER:
		return false
	if not _is_healer_control_available():
		return false
	if not is_instance_valid(healer):
		return false
	if healer.has_method("is_manual_control_enabled"):
		return bool(healer.call("is_manual_control_enabled"))
	return _is_healer_control_available()


func _is_manual_ratfolk_control_active() -> bool:
	if controlled_character_id != CONTROLLED_CHARACTER_RATFOLK:
		return false
	if not _is_ratfolk_control_available():
		return false
	if not is_instance_valid(ratfolk):
		return false
	if ratfolk.has_method("is_manual_control_enabled"):
		return bool(ratfolk.call("is_manual_control_enabled"))
	return _is_ratfolk_control_available()


func _is_manual_lizardfolk_control_active() -> bool:
	if controlled_character_id != CONTROLLED_CHARACTER_LIZARDFOLK:
		return false
	if not _is_lizardfolk_control_available():
		return false
	if not is_instance_valid(lizardfolk):
		return false
	if lizardfolk.has_method("is_manual_control_enabled"):
		return bool(lizardfolk.call("is_manual_control_enabled"))
	return _is_lizardfolk_control_available()


func _build_healer_manual_control_cooldowns() -> Dictionary:
	var fallback := {
		"ability_layout": "healer",
		"basic": 0.0,
		"basic_unlocked": false,
		"quick_heal": 0.0,
		"quick_heal_unlocked": true,
		"ability_1": 0.0,
		"ability_1_unlocked": true,
		"ability_2": 0.0,
		"ability_2_unlocked": false,
		"roll": 0.0,
		"roll_unlocked": false,
		"block_active": false,
		"block_cooldown_left": 0.0,
		"counter_unlocked": true,
		"counter_ready": false,
		"counter_window_left": 0.0,
		"special_meter_ratio": 0.0
	}
	if not is_instance_valid(healer):
		return fallback
	if not healer.has_method("get_manual_control_cooldown_state"):
		return fallback
	var data_variant: Variant = healer.call("get_manual_control_cooldown_state")
	if not (data_variant is Dictionary):
		return fallback
	var data := (data_variant as Dictionary).duplicate(true)
	data["ability_layout"] = "healer"
	return data


func _build_ratfolk_manual_control_cooldowns() -> Dictionary:
	var fallback := {
		"ability_layout": "ratfolk",
		"basic": 0.0,
		"basic_unlocked": false,
		"ability_1": 0.0,
		"ability_1_unlocked": false,
		"counter": 0.0,
		"counter_unlocked": false,
		"ability_2": 0.0,
		"ability_2_unlocked": false,
		"roll": 0.0,
		"roll_unlocked": false,
		"block_cooldown_left": 0.0,
		"block_unlocked": false,
		"special_meter_ratio": 0.0
	}
	if not is_instance_valid(ratfolk):
		return fallback
	if not ratfolk.has_method("get_manual_control_cooldown_state"):
		return fallback
	var data_variant: Variant = ratfolk.call("get_manual_control_cooldown_state")
	if not (data_variant is Dictionary):
		return fallback
	var data := (data_variant as Dictionary).duplicate(true)
	data["ability_layout"] = "ratfolk"
	return data


func _build_lizardfolk_manual_control_cooldowns() -> Dictionary:
	var fallback := {
		"ability_layout": "lizardfolk",
		"basic": 0.0,
		"basic_unlocked": false,
		"ability_1": 0.0,
		"ability_1_unlocked": false,
		"counter": 0.0,
		"counter_unlocked": false,
		"ability_2": 0.0,
		"ability_2_unlocked": false,
		"roll": 0.0,
		"roll_unlocked": false,
		"block_cooldown_left": 0.0,
		"block_unlocked": false,
		"special_meter_ratio": 0.0
	}
	if not is_instance_valid(lizardfolk):
		return fallback
	if not lizardfolk.has_method("get_manual_control_cooldown_state"):
		return fallback
	var data_variant: Variant = lizardfolk.call("get_manual_control_cooldown_state")
	if not (data_variant is Dictionary):
		return fallback
	var data := (data_variant as Dictionary).duplicate(true)
	data["ability_layout"] = "lizardfolk"
	return data


func _emit_manual_control_cooldowns() -> void:
	if _is_manual_healer_control_active():
		cooldowns_changed.emit(_build_healer_manual_control_cooldowns())
		return
	if _is_manual_ratfolk_control_active():
		cooldowns_changed.emit(_build_ratfolk_manual_control_cooldowns())
		return
	if _is_manual_lizardfolk_control_active():
		cooldowns_changed.emit(_build_lizardfolk_manual_control_cooldowns())


func _sync_control_mode_availability() -> void:
	if controlled_character_id == CONTROLLED_CHARACTER_HEALER and not _is_healer_control_available():
		_apply_control_mode_runtime()
		return
	if controlled_character_id == CONTROLLED_CHARACTER_RATFOLK and not _is_ratfolk_control_available():
		_apply_control_mode_runtime()
		return
	if controlled_character_id == CONTROLLED_CHARACTER_LIZARDFOLK and not _is_lizardfolk_control_available():
		_apply_control_mode_runtime()


func toggle_hitbox_debug_mode() -> bool:
	hitbox_debug_mode_enabled = not hitbox_debug_mode_enabled
	hitbox_debug_sync_left = 0.0
	_sync_hitbox_debug_mode()
	return hitbox_debug_mode_enabled


func _sync_hitbox_debug_mode() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.set_meta("debug_hitbox_mode_enabled", hitbox_debug_mode_enabled)
	_apply_hitbox_debug_to_node(player)
	_apply_hitbox_debug_to_node(healer)
	_apply_hitbox_debug_to_node(ratfolk)
	_apply_hitbox_debug_to_node(lizardfolk)
	for node in tree.get_nodes_in_group("hitbox_debuggable"):
		_apply_hitbox_debug_to_node(node as Node)


func _resolve_encounter_spawn_position(start_global_position: Vector2) -> Vector2:
	var resolved := _clamp_global_position_to_arena(start_global_position)
	var desired_party_distance := _get_desired_initial_enemy_party_distance()
	var desired_enemy_distance := maxf(12.0, encounter_initial_enemy_min_enemy_distance)
	var reposition_step := maxf(6.0, encounter_spawn_reposition_step)
	var max_attempts := maxi(0, encounter_spawn_reposition_attempts)
	var original := resolved
	var party_nodes := _get_alive_party_nodes()
	var party_distance_targets: Dictionary = {}
	var distance_scale := maxf(1.0, encounter_initial_enemy_distance_scale)
	var distance_cap := maxf(desired_party_distance, encounter_initial_enemy_max_party_distance)
	var max_party_target_distance := desired_party_distance
	for ally in party_nodes:
		var ally_id := ally.get_instance_id()
		var baseline_distance := original.distance_to(ally.global_position)
		var target_distance := clampf(maxf(desired_party_distance, baseline_distance * distance_scale), desired_party_distance, distance_cap)
		party_distance_targets[ally_id] = target_distance
		max_party_target_distance = maxf(max_party_target_distance, target_distance)
	for attempt in range(max_attempts):
		var adjusted := false
		var fallback_angle := float(attempt) * 0.78
		for ally in party_nodes:
			var to_candidate := resolved - ally.global_position
			var distance := to_candidate.length()
			var ally_id := ally.get_instance_id()
			var ally_target_distance := float(party_distance_targets.get(ally_id, desired_party_distance))
			if distance >= ally_target_distance:
				continue
			var push_direction := to_candidate.normalized() if distance > 0.001 else _get_spawn_fallback_direction(fallback_angle)
			var deficit := ally_target_distance - distance
			resolved += push_direction * (deficit + (reposition_step * 0.12))
			adjusted = true
		for enemy in _get_alive_enemy_nodes():
			var to_candidate := resolved - enemy.global_position
			var distance := to_candidate.length()
			if distance >= desired_enemy_distance:
				continue
			var push_direction := to_candidate.normalized() if distance > 0.001 else _get_spawn_fallback_direction(fallback_angle + 1.17)
			var deficit := desired_enemy_distance - distance
			resolved += push_direction * (deficit + (reposition_step * 0.16))
			adjusted = true
		resolved = _clamp_global_position_to_arena(resolved)
		if not adjusted:
			break
	if spacing_debug_runtime_enabled:
		var moved_distance := original.distance_to(resolved)
		if moved_distance >= 1.0:
			print(
				"[SPACING] spawn_adjust moved=%.1f party_min=%.1f enemy_min=%.1f from=%s to=%s" % [
					moved_distance,
					max_party_target_distance,
					desired_enemy_distance,
					original,
					resolved
				]
			)
	return resolved


func _get_desired_initial_enemy_party_distance() -> float:
	var base_distance := maxf(0.0, encounter_initial_enemy_min_party_distance)
	var scaled_distance := base_distance * maxf(0.1, encounter_initial_enemy_distance_scale)
	return maxf(base_distance, scaled_distance)


func _clamp_global_position_to_arena(world_position: Vector2) -> Vector2:
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	var local := to_local(world_position)
	local.x = clampf(local.x, min_x, max_x)
	local.y = clampf(local.y, min_y, max_y)
	return to_global(local)


func _get_alive_party_nodes() -> Array[Node2D]:
	var party_nodes: Array[Node2D] = []
	if tank_party_enabled and is_instance_valid(player):
		party_nodes.append(player)
	if is_instance_valid(healer):
		party_nodes.append(healer)
	if is_instance_valid(ratfolk):
		party_nodes.append(ratfolk)
	if is_instance_valid(lizardfolk):
		party_nodes.append(lizardfolk)
	return party_nodes


func _get_alive_enemy_nodes() -> Array[EnemyBase]:
	var enemies: Array[EnemyBase] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		enemies.append(enemy)
	return enemies


func _get_spawn_fallback_direction(angle_offset: float = 0.0) -> Vector2:
	var avg_party_position := Vector2.ZERO
	var party_nodes := _get_alive_party_nodes()
	if party_nodes.is_empty():
		return Vector2.RIGHT.rotated(angle_offset)
	for ally in party_nodes:
		avg_party_position += ally.global_position
	avg_party_position /= float(party_nodes.size())
	var away_from_party := global_position - avg_party_position
	if away_from_party.length_squared() <= 0.0001:
		away_from_party = Vector2.RIGHT
	return away_from_party.normalized().rotated(angle_offset)


func _maybe_log_opening_spacing() -> void:
	if not spacing_debug_runtime_enabled:
		return
	var opening_window := maxf(0.0, encounter_spacing_debug_opening_window)
	if demo_elapsed > opening_window:
		return
	if demo_elapsed + 0.0001 < spacing_debug_next_log_at:
		return
	_log_encounter_spacing_snapshot("t=%.2f" % demo_elapsed)
	spacing_debug_next_log_at = demo_elapsed + maxf(0.2, encounter_spacing_debug_log_interval)


func _log_encounter_spacing_snapshot(label: String) -> void:
	if not spacing_debug_runtime_enabled:
		return
	var enemies := _get_alive_enemy_nodes()
	var party_nodes := _get_alive_party_nodes()
	var min_enemy_to_party := INF
	var avg_enemy_to_party := 0.0
	var enemy_to_party_samples := 0
	for enemy in enemies:
		if party_nodes.is_empty():
			continue
		var nearest_party_distance := INF
		for ally in party_nodes:
			nearest_party_distance = minf(nearest_party_distance, enemy.global_position.distance_to(ally.global_position))
		if nearest_party_distance < INF:
			min_enemy_to_party = minf(min_enemy_to_party, nearest_party_distance)
			avg_enemy_to_party += nearest_party_distance
			enemy_to_party_samples += 1
	var min_enemy_to_enemy := INF
	for i in range(enemies.size()):
		for j in range(i + 1, enemies.size()):
			var separation := enemies[i].global_position.distance_to(enemies[j].global_position)
			min_enemy_to_enemy = minf(min_enemy_to_enemy, separation)
	var separation_active_count := 0
	var separation_push_sum := 0.0
	var approach_slot_active_count := 0
	var approach_slot_offset_sum := 0.0
	for enemy in enemies:
		if not enemy.has_method("get_soft_separation_debug_snapshot"):
			continue
		var snapshot_variant: Variant = enemy.call("get_soft_separation_debug_snapshot")
		if not (snapshot_variant is Dictionary):
			continue
		var snapshot := snapshot_variant as Dictionary
		if bool(snapshot.get("applied", false)):
			separation_active_count += 1
			separation_push_sum += float(snapshot.get("push_magnitude", 0.0))
		if bool(snapshot.get("approach_slot_applied", false)):
			approach_slot_active_count += 1
			var slot_offset_variant: Variant = snapshot.get("approach_slot_offset", Vector2.ZERO)
			if slot_offset_variant is Vector2:
				approach_slot_offset_sum += (slot_offset_variant as Vector2).length()
	var avg_enemy_to_party_text := "-"
	if enemy_to_party_samples > 0:
		avg_enemy_to_party_text = "%.1f" % (avg_enemy_to_party / float(enemy_to_party_samples))
	var min_enemy_to_party_text := "-" if min_enemy_to_party == INF else "%.1f" % min_enemy_to_party
	var min_enemy_to_enemy_text := "-" if min_enemy_to_enemy == INF else "%.1f" % min_enemy_to_enemy
	var avg_push_text := "-"
	if separation_active_count > 0:
		avg_push_text = "%.2f" % (separation_push_sum / float(separation_active_count))
	var avg_slot_offset_text := "-"
	if approach_slot_active_count > 0:
		avg_slot_offset_text = "%.1f" % (approach_slot_offset_sum / float(approach_slot_active_count))
	print(
		"[SPACING] snapshot=%s enemies=%d party=%d min_enemy_party=%s avg_enemy_party=%s min_enemy_enemy=%s sep_active=%d sep_avg_push=%s slot_active=%d slot_avg_offset=%s" % [
			label,
			enemies.size(),
			party_nodes.size(),
			min_enemy_to_party_text,
			avg_enemy_to_party_text,
			min_enemy_to_enemy_text,
			separation_active_count,
			avg_push_text,
			approach_slot_active_count,
			avg_slot_offset_text
		]
	)


func _apply_hitbox_debug_to_node(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.has_method("set_hitbox_debug_enabled"):
		node.call("set_hitbox_debug_enabled", hitbox_debug_mode_enabled)


func _on_player_health_changed(current: float, maximum: float) -> void:
	player_health_changed.emit(current, maximum)


func _on_player_xp_changed(current: int, needed: int, level: int) -> void:
	player_xp_changed.emit(current, needed, level)


func _on_player_cooldowns_changed(values: Dictionary) -> void:
	if _is_manual_healer_control_active():
		cooldowns_changed.emit(_build_healer_manual_control_cooldowns())
		return
	if _is_manual_ratfolk_control_active():
		cooldowns_changed.emit(_build_ratfolk_manual_control_cooldowns())
		return
	if _is_manual_lizardfolk_control_active():
		cooldowns_changed.emit(_build_lizardfolk_manual_control_cooldowns())
		return
	var emitted_values := values.duplicate(true)
	emitted_values["ability_layout"] = "tank"
	cooldowns_changed.emit(emitted_values)


func _on_player_item_looted(item_name: String, total_owned: int) -> void:
	item_collected.emit(item_name, total_owned)


func _on_player_combat_status_message(text: String, duration: float = 0.9) -> void:
	status_message.emit(text, duration)


func _on_player_died() -> void:
	_try_emit_party_defeat()


func _on_party_member_died(_member: Node) -> void:
	_try_emit_party_defeat()


func _connect_companion_died(companion: Node) -> void:
	if companion == null or not is_instance_valid(companion):
		return
	if not companion.has_signal("died"):
		return
	var died_callable := Callable(self, "_on_party_member_died")
	if companion.is_connected("died", died_callable):
		return
	companion.connect("died", died_callable)


func _is_tank_alive() -> bool:
	if not tank_party_enabled:
		return false
	if not is_instance_valid(player):
		return false
	return not player.is_dead


func _is_healer_alive() -> bool:
	if not is_instance_valid(healer):
		return false
	var healer_ref := healer as FriendlyHealer
	if healer_ref == null:
		return false
	return not healer_ref.dead


func _is_ratfolk_alive() -> bool:
	if not is_instance_valid(ratfolk):
		return false
	var rat_ref := ratfolk as FriendlyRatfolk
	if rat_ref == null:
		return false
	return not rat_ref.dead


func _is_lizardfolk_alive() -> bool:
	if not is_instance_valid(lizardfolk):
		return false
	var lizard_ref := lizardfolk as FriendlyRatfolk
	if lizard_ref == null:
		return false
	return not lizard_ref.dead


func _has_any_alive_team_member() -> bool:
	return _is_tank_alive() or _is_healer_alive() or _is_ratfolk_alive() or _is_lizardfolk_alive()


func _try_emit_party_defeat() -> void:
	if party_defeat_emitted:
		return
	if _has_any_alive_team_member():
		return
	party_defeat_emitted = true
	objective_changed.emit("Objective: Defeat")
	player_died.emit()


func _is_autoplay_requested() -> bool:
	var autoplay_raw := OS.get_environment("AUTOPLAY_TEST").strip_edges().to_lower()
	if not autoplay_raw.is_empty() and autoplay_raw not in ["0", "false", "off", "no"]:
		return true
	for arg in OS.get_cmdline_user_args():
		var normalized := String(arg).strip_edges().to_lower()
		if normalized == "--autoplay_test" or normalized == "autoplay_test" or normalized == "--autoplay_test=1":
			return true
	return false


func _is_env_flag_enabled(env_key: String) -> bool:
	var raw := OS.get_environment(env_key).strip_edges().to_lower()
	return not raw.is_empty() and raw not in ["0", "false", "off", "no"]
