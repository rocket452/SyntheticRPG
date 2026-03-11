extends RefCounted
class_name ShieldDefinitions

const REVENGE_SHIELD: String = "revenge_shield"

const SHIELD_DEFINITIONS: Dictionary = {
	REVENGE_SHIELD: {
		"id": REVENGE_SHIELD,
		"name": "Revenge Shield",
		"icon": "SHD",
		"description": "Enables Perfect Block revenge counter.",
		"accent_color": Color(0.56, 0.9, 1.0, 1.0),
		"unlocks_counter_strike": true
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
