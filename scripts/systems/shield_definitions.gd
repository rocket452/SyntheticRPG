extends RefCounted
class_name ShieldDefinitions

const REVENGE_SHIELD: String = "revenge_shield"
const THORNS_SHIELD: String = "thorns_shield"
const WIDE_GUARD_SHIELD: String = "wide_guard_shield"

const SHIELD_DEFINITIONS: Dictionary = {
	REVENGE_SHIELD: {
		"id": REVENGE_SHIELD,
		"name": "Revenge Shield",
		"icon": "SHD",
		"description": "Counter Strike deals double damage.",
		"accent_color": Color(0.56, 0.9, 1.0, 1.0),
		"counter_damage_multiplier": 2.0
	},
	THORNS_SHIELD: {
		"id": THORNS_SHIELD,
		"name": "Thorns Shield",
		"icon": "THR",
		"description": "Reflects 30% of blocked damage back to the attacker.",
		"accent_color": Color(0.92, 0.76, 0.44, 1.0),
		"blocked_damage_reflect_ratio": 0.3
	},
	WIDE_GUARD_SHIELD: {
		"id": WIDE_GUARD_SHIELD,
		"name": "Wide Guard Shield",
		"icon": "WGD",
		"description": "Increases block area by 30%.",
		"accent_color": Color(0.74, 0.88, 1.0, 1.0),
		"block_area_multiplier": 1.3
	}
}


static func get_shield_ids() -> Array[String]:
	var ids: Array[String] = []
	for shield_id in SHIELD_DEFINITIONS.keys():
		ids.append(String(shield_id))
	ids.sort()
	return ids


static func has_definition(shield_id: String) -> bool:
	return SHIELD_DEFINITIONS.has(shield_id)


static func get_definition(shield_id: String) -> Dictionary:
	if SHIELD_DEFINITIONS.has(shield_id):
		return (SHIELD_DEFINITIONS[shield_id] as Dictionary).duplicate(true)
	return {}


static func get_display_name(shield_id: String) -> String:
	var definition := get_definition(shield_id)
	return String(definition.get("name", "No Shield"))
