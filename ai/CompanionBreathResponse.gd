extends RefCounted
class_name CompanionBreathResponse


static func get_active_threat(tree: SceneTree) -> Dictionary:
	if tree == null:
		return {}
	var best_threat: Dictionary = {}
	var best_priority := -1
	for node in tree.get_nodes_in_group("enemies"):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("get_breath_threat_snapshot"):
			continue
		var snapshot_variant: Variant = node.call("get_breath_threat_snapshot")
		if not (snapshot_variant is Dictionary):
			continue
		var snapshot := snapshot_variant as Dictionary
		if not bool(snapshot.get("active", false)):
			continue
		var priority := 1 if bool(snapshot.get("fire_active", false)) else 0
		if best_threat.is_empty() or priority > best_priority:
			best_threat = snapshot.duplicate(true)
			best_priority = priority
	return best_threat


static func compute_cover_position(threat: Dictionary, slot_index: int, slot_count: int = 2) -> Vector2:
	if threat.is_empty():
		return Vector2.ZERO
	var center: Vector2 = threat.get("safe_pocket_center", Vector2.ZERO)
	var dir: Vector2 = threat.get("dir", Vector2.RIGHT)
	var side := Vector2(-dir.y, dir.x)
	var total_slots := maxi(1, slot_count)
	var slot_value := clampi(slot_index, 0, total_slots - 1)
	var lateral_step := maxf(10.0, float(threat.get("safe_pocket_half_width", 36.0)) * 0.46)
	var centered_index := float(slot_value) - (float(total_slots - 1) * 0.5)
	return center + (side * centered_index * lateral_step)


static func compute_scatter_position(threat: Dictionary, actor_position: Vector2, slot_index: int) -> Vector2:
	if threat.is_empty():
		return actor_position
	var tank_position: Vector2 = threat.get("tank_position", actor_position)
	var dir: Vector2 = threat.get("dir", Vector2.RIGHT)
	var side := Vector2(-dir.y, dir.x)
	var branch_sign := -1.0 if slot_index <= 0 else 1.0
	var retreat := tank_position + (dir * maxf(78.0, float(threat.get("safe_pocket_half_depth", 32.0)) * 2.4))
	return retreat + (side * branch_sign * maxf(56.0, float(threat.get("safe_pocket_half_width", 36.0)) * 1.6))


static func is_position_safe(world_position: Vector2, threat: Dictionary) -> bool:
	if threat.is_empty():
		return false
	if not bool(threat.get("safe_pocket_valid", false)):
		return false
	var center: Vector2 = threat.get("safe_pocket_center", Vector2.ZERO)
	var dir: Vector2 = threat.get("dir", Vector2.RIGHT)
	var half_depth := maxf(1.0, float(threat.get("safe_pocket_half_depth", 32.0)))
	var half_width := maxf(1.0, float(threat.get("safe_pocket_half_width", 36.0)))
	var delta := world_position - center
	var local_x := delta.dot(-dir)
	var local_y := delta.dot(Vector2(-dir.y, dir.x))
	var normalized_x := local_x / half_depth
	var normalized_y := local_y / half_width
	return (normalized_x * normalized_x) + (normalized_y * normalized_y) <= 1.0


static func count_friendlies_in_pocket(tree: SceneTree, threat: Dictionary) -> int:
	if tree == null or threat.is_empty():
		return 0
	var count := 0
	for node in tree.get_nodes_in_group("friendly_npcs"):
		var actor := node as Node2D
		if actor == null or not is_instance_valid(actor):
			continue
		if is_position_safe(actor.global_position, threat):
			count += 1
	return count
