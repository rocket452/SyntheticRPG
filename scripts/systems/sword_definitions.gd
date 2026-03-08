extends RefCounted
class_name SwordDefinitions

const EXTENDED_CHARGE_SWORD: String = "extended_charge"
const SLOWING_SWORD: String = "slowing"
const STACKING_DOT_SWORD: String = "stacking_dot"
const DEFAULT_SWORD_ID: String = EXTENDED_CHARGE_SWORD

const SWORD_DEFINITIONS: Dictionary = {
	EXTENDED_CHARGE_SWORD: {
		"id": EXTENDED_CHARGE_SWORD,
		"name": "Extended Charge Sword",
		"icon": "EXT",
		"description": "Basic attack swings reach farther.",
		"accent_color": Color(1.0, 0.77, 0.34, 1.0),
		"aura_color": Color(1.0, 0.76, 0.28, 0.82),
		"charge_preview_color": Color(1.0, 0.78, 0.32, 0.44),
		"charge_release_color": Color(1.0, 0.64, 0.26, 0.52),
		"impact_color": Color(1.0, 0.82, 0.45, 0.95),
		"extended_basic_range_multiplier": 1.7
	},
	SLOWING_SWORD: {
		"id": SLOWING_SWORD,
		"name": "Slowing Sword",
		"icon": "SLOW",
		"description": "Basic hits slow movement briefly.",
		"accent_color": Color(0.5, 0.9, 1.0, 1.0),
		"aura_color": Color(0.34, 0.86, 1.0, 0.84),
		"charge_preview_color": Color(0.42, 0.86, 1.0, 0.44),
		"charge_release_color": Color(0.36, 0.8, 1.0, 0.55),
		"impact_color": Color(0.58, 0.9, 1.0, 0.95),
		"slow_duration": 2.6,
		"slow_speed_multiplier": 0.5
	},
	STACKING_DOT_SWORD: {
		"id": STACKING_DOT_SWORD,
		"name": "Stacking DoT Sword",
		"icon": "DOT",
		"description": "Basic hits add stacking burn damage.",
		"accent_color": Color(0.96, 0.54, 1.0, 1.0),
		"aura_color": Color(0.9, 0.42, 1.0, 0.84),
		"charge_preview_color": Color(0.92, 0.48, 1.0, 0.44),
		"charge_release_color": Color(0.98, 0.4, 0.9, 0.56),
		"impact_color": Color(1.0, 0.58, 0.9, 0.95),
		"dot_duration": 4.0,
		"dot_tick_interval": 0.5,
		"dot_damage_per_stack": 2.4,
		"dot_max_stacks": 5
	}
}

static func get_sword_ids() -> Array[String]:
	var ids: Array[String] = []
	for sword_id in SWORD_DEFINITIONS.keys():
		ids.append(String(sword_id))
	ids.sort()
	return ids


static func get_definition(sword_id: String) -> Dictionary:
	if SWORD_DEFINITIONS.has(sword_id):
		return (SWORD_DEFINITIONS[sword_id] as Dictionary).duplicate(true)
	return (SWORD_DEFINITIONS[DEFAULT_SWORD_ID] as Dictionary).duplicate(true)


static func get_display_name(sword_id: String) -> String:
	var definition := get_definition(sword_id)
	return String(definition.get("name", sword_id))
