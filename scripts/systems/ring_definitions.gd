extends RefCounted
class_name RingDefinitions

const BULWARK_RING: String = "bulwark"
const BERSERKER_RING: String = "berserker"
const SHIELD_RING: String = "shield"

const RING_DEFINITIONS: Dictionary = {
	BULWARK_RING: {
		"id": BULWARK_RING,
		"name": "Ring of the Bulwark",
		"icon": "BLW",
		"description": "Stand still to build Fortify stacks for damage reduction. Moving clears Fortify. Movement speed reduced."
	},
	BERSERKER_RING: {
		"id": BERSERKER_RING,
		"name": "Ring of the Berserker",
		"icon": "BRK",
		"description": "Below 35% health, attacks become faster and stronger, and Counter Strike is empowered."
	},
	SHIELD_RING: {
		"id": SHIELD_RING,
		"name": "Ring of the Shield",
		"icon": "RSH",
		"description": "Blocking negates all damage, but block is brief and then enters cooldown. Successful blocks reduce cooldown."
	}
}


static func get_ring_ids() -> Array[String]:
	var ids: Array[String] = []
	for ring_id in RING_DEFINITIONS.keys():
		ids.append(String(ring_id))
	ids.sort()
	return ids


static func has_definition(ring_id: String) -> bool:
	return RING_DEFINITIONS.has(ring_id)


static func get_definition(ring_id: String) -> Dictionary:
	if RING_DEFINITIONS.has(ring_id):
		return (RING_DEFINITIONS[ring_id] as Dictionary).duplicate(true)
	return {}


static func get_display_name(ring_id: String) -> String:
	var definition := get_definition(ring_id)
	return String(definition.get("name", "No Ring"))
