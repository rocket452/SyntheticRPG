extends RefCounted
class_name InputConfig

static func ensure_actions() -> void:
	var action_map: Dictionary = {
		"move_up": [_make_key(KEY_W)],
		"move_down": [_make_key(KEY_S)],
		"move_left": [_make_key(KEY_A)],
		"move_right": [_make_key(KEY_D)],
		"basic_attack": [_make_key(KEY_J)],
		"ability_1": [_make_key(KEY_K)],
		"ability_2": [_make_key(KEY_L)],
		"roll": [_make_key(KEY_SPACE)],
		"block": [_make_key(KEY_I)],
		"inventory_toggle": [_make_key(KEY_TAB)]
	}

	for action_name in action_map.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		_replace_action_events(action_name, action_map[action_name])


static func _make_key(keycode_value: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode_value
	event.physical_keycode = keycode_value
	return event


static func _replace_action_events(action_name: StringName, desired_events: Array) -> void:
	for existing_event in InputMap.action_get_events(action_name):
		InputMap.action_erase_event(action_name, existing_event)
	for event in desired_events:
		InputMap.action_add_event(action_name, event)
