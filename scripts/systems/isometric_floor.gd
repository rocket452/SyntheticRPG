extends Node2D

@export var arena_width: float = 1560.0
@export var arena_height: float = 420.0
@export var sidewalk_height: float = 48.0
@export var lane_count: int = 3
@export var divider_dash: float = 52.0
@export var divider_gap: float = 34.0
@export var vertical_grid_step: float = 120.0

@export var lane_divider_color: Color = Color(0.86, 0.82, 0.68, 0.0)
@export var vertical_grid_color: Color = Color(0.78, 0.82, 0.92, 0.0)
@export var border_color: Color = Color(0.32, 0.34, 0.4, 0.0)

@export var dungeon_tileset_texture: Texture2D = preload("res://assets/external/ElthenAssets/tilesets/dungeon/Dungeon_Tileset.png")
@export var dungeon_tile_size: Vector2i = Vector2i(32, 32)
@export var dungeon_tileset_source_id: int = 0
@export var floor_tile_coords: Array[Vector2i] = [
	Vector2i(5, 8), Vector2i(6, 8), Vector2i(8, 8), Vector2i(9, 8)
]
@export var wall_cap_tile_coords: Array[Vector2i] = [
	Vector2i(10, 1), Vector2i(11, 1)
]
@export var wall_face_tile_coords: Array[Vector2i] = [
	Vector2i(10, 3), Vector2i(11, 3)
]
@export var wall_left_tile_coords: Array[Vector2i] = [
	Vector2i(0, 1)
]
@export var wall_right_tile_coords: Array[Vector2i] = [
	Vector2i(2, 1)
]
@export var decor_tile_coords: Array[Vector2i] = [
	Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4),
	Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5)
]
@export_range(0.0, 1.0, 0.01) var floor_tile_variation_chance: float = 0.04
@export_range(0.0, 1.0, 0.01) var wall_tile_variation_chance: float = 0.1
@export_range(0.0, 1.0, 0.01) var decor_spawn_chance: float = 0.0
@export var top_border_rows: int = 1
@export var bottom_border_rows: int = 1
@export var border_columns: int = 1

var _tile_layer: TileMapLayer = null
var _decor_layer: TileMapLayer = null


func _ready() -> void:
	_ensure_tile_layer()
	_ensure_decor_layer()
	_rebuild_floor_tiles()
	queue_redraw()


func _draw() -> void:
	var clamped_lane_count := maxi(1, lane_count)
	var half_width := arena_width * 0.5
	var half_height := arena_height * 0.5
	var arena_rect := Rect2(Vector2(-half_width, -half_height), Vector2(arena_width, arena_height))
	if border_color.a > 0.01:
		draw_rect(arena_rect, border_color, false, 3.0, true)

	var clamped_sidewalk_height := clampf(sidewalk_height, 0.0, arena_height * 0.45)
	var playable_top := arena_rect.position.y + clamped_sidewalk_height
	var playable_bottom := arena_rect.end.y - clamped_sidewalk_height
	var playable_height := playable_bottom - playable_top
	if playable_height <= 2.0:
		return

	var lane_height := playable_height / float(clamped_lane_count)
	if lane_divider_color.a > 0.01:
		for lane_idx in range(1, clamped_lane_count):
			var lane_y := playable_top + (lane_height * float(lane_idx))
			_draw_horizontal_dash_line(
				Vector2(arena_rect.position.x + 18.0, lane_y),
				Vector2(arena_rect.end.x - 18.0, lane_y),
				divider_dash,
				divider_gap,
				lane_divider_color,
				2.0
			)

	if vertical_grid_color.a > 0.01 and vertical_grid_step > 16.0:
		var x := arena_rect.position.x + vertical_grid_step
		while x < arena_rect.end.x:
			draw_line(Vector2(x, playable_top), Vector2(x, playable_bottom), vertical_grid_color, 1.0, true)
			x += vertical_grid_step


func _ensure_tile_layer() -> void:
	if _tile_layer != null and is_instance_valid(_tile_layer):
		return
	var existing := get_node_or_null("DungeonTileLayer") as TileMapLayer
	if existing != null:
		_tile_layer = existing
		return
	var layer := TileMapLayer.new()
	layer.name = "DungeonTileLayer"
	layer.z_index = -100
	layer.y_sort_enabled = false
	add_child(layer)
	move_child(layer, 0)
	_tile_layer = layer


func _ensure_decor_layer() -> void:
	if _decor_layer != null and is_instance_valid(_decor_layer):
		return
	var existing := get_node_or_null("DungeonDecorLayer") as TileMapLayer
	if existing != null:
		_decor_layer = existing
		return
	var layer := TileMapLayer.new()
	layer.name = "DungeonDecorLayer"
	layer.z_index = -90
	layer.y_sort_enabled = false
	add_child(layer)
	if _tile_layer != null and is_instance_valid(_tile_layer):
		move_child(layer, get_child_count() - 1)
	_decor_layer = layer


func _rebuild_floor_tiles() -> void:
	if _tile_layer == null or not is_instance_valid(_tile_layer):
		return
	if _decor_layer == null or not is_instance_valid(_decor_layer):
		_ensure_decor_layer()
	if dungeon_tileset_texture == null:
		push_warning("Dungeon floor: missing tileset texture.")
		return

	var tile_w := maxi(4, dungeon_tile_size.x)
	var tile_h := maxi(4, dungeon_tile_size.y)
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tile_w, tile_h)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = dungeon_tileset_texture
	atlas.texture_region_size = Vector2i(tile_w, tile_h)

	var all_coords: Array[Vector2i] = []
	all_coords.append_array(floor_tile_coords)
	all_coords.append_array(wall_cap_tile_coords)
	all_coords.append_array(wall_face_tile_coords)
	all_coords.append_array(wall_left_tile_coords)
	all_coords.append_array(wall_right_tile_coords)
	all_coords.append_array(decor_tile_coords)
	var unique_coords: Dictionary = {}
	for coord in all_coords:
		if unique_coords.has(coord):
			continue
		unique_coords[coord] = true
		if _atlas_coord_in_bounds(coord, tile_w, tile_h):
			atlas.create_tile(coord)

	tile_set.add_source(atlas, dungeon_tileset_source_id)
	_tile_layer.tile_set = tile_set
	_tile_layer.clear()
	if _decor_layer != null and is_instance_valid(_decor_layer):
		_decor_layer.tile_set = tile_set
		_decor_layer.clear()

	var half_width := arena_width * 0.5
	var half_height := arena_height * 0.5
	var fill_columns := maxi(1, int(ceili(arena_width / float(tile_w))) + 2)
	var fill_rows := maxi(1, int(ceili(arena_height / float(tile_h))) + 2)
	_tile_layer.position = Vector2(-half_width, -half_height)

	var top_rim_rows := maxi(0, top_border_rows)
	var bottom_rim_rows := maxi(0, bottom_border_rows)
	var rim_cols := maxi(0, border_columns)
	var max_row := fill_rows - 1
	var top_rim_end := top_rim_rows - 1
	var bottom_rim_start := maxi(0, fill_rows - bottom_rim_rows)
	var left_rim_end := rim_cols - 1
	# Anchor the right wall to the actual arena/play-area boundary instead of the
	# padded tile fill width so doors and wall visuals line up.
	var right_edge_column := clampi(
		int(floor((maxf(0.0, arena_width) - 0.001) / float(tile_w))),
		0,
		fill_columns - 1
	)
	var right_rim_start := maxi(0, right_edge_column - rim_cols + 1)
	var right_rim_end := right_edge_column

	for y in range(fill_rows):
		for x in range(fill_columns):
			# Do not render padded overflow columns beyond the playable right edge.
			if x > right_edge_column:
				continue
			var use_top_rim := top_rim_rows > 0 and y <= top_rim_end
			var use_bottom_rim := bottom_rim_rows > 0 and y >= bottom_rim_start
			var use_left_rim := rim_cols > 0 and x <= left_rim_end
			var use_right_rim := rim_cols > 0 and x >= right_rim_start and x <= right_rim_end
			var atlas_coord: Vector2i
			if use_top_rim:
				atlas_coord = _pick_tile_coord(
					wall_cap_tile_coords if y == 0 else wall_face_tile_coords,
					x,
					y,
					wall_tile_variation_chance
				)
			elif use_bottom_rim:
				atlas_coord = _pick_tile_coord(wall_face_tile_coords, x, y, wall_tile_variation_chance)
			elif use_left_rim:
				atlas_coord = _pick_tile_coord(wall_left_tile_coords, x, y, wall_tile_variation_chance)
			elif use_right_rim:
				atlas_coord = _pick_tile_coord(wall_right_tile_coords, x, y, wall_tile_variation_chance)
			else:
				atlas_coord = _pick_tile_coord(floor_tile_coords, x, y, floor_tile_variation_chance)
			if not _atlas_coord_in_bounds(atlas_coord, tile_w, tile_h):
				atlas_coord = Vector2i(5, 8)
			_tile_layer.set_cell(Vector2i(x, y), dungeon_tileset_source_id, atlas_coord)
			var can_place_decor := not use_top_rim and not use_bottom_rim and not use_left_rim and not use_right_rim
			if can_place_decor and _decor_layer != null and is_instance_valid(_decor_layer):
				if _hash_roll01(x, y, 41333, 17431) <= clampf(decor_spawn_chance, 0.0, 1.0):
					var decor_coord := _pick_tile_coord(decor_tile_coords, x, y, 1.0)
					if _atlas_coord_in_bounds(decor_coord, tile_w, tile_h):
						_decor_layer.set_cell(Vector2i(x, y), dungeon_tileset_source_id, decor_coord)


func _atlas_coord_in_bounds(coord: Vector2i, tile_w: int, tile_h: int) -> bool:
	if coord.x < 0 or coord.y < 0:
		return false
	var atlas_columns := dungeon_tileset_texture.get_width() / tile_w
	var atlas_rows := dungeon_tileset_texture.get_height() / tile_h
	return coord.x < atlas_columns and coord.y < atlas_rows


func _pick_tile_coord(coords: Array[Vector2i], cell_x: int, cell_y: int, variation_chance: float) -> Vector2i:
	if coords.is_empty():
		return Vector2i(5, 8)
	if coords.size() == 1:
		return coords[0]
	var base_coord := coords[0]
	var chance := clampf(variation_chance, 0.0, 1.0)
	var roll := _hash_roll01(cell_x, cell_y, 92821, 68917)
	if roll > chance:
		return base_coord
	var variant_hash: int = abs((cell_x * 73856093) ^ (cell_y * 19349663))
	var variant_index: int = 1 + (variant_hash % (coords.size() - 1))
	return coords[variant_index]


func _hash_roll01(cell_x: int, cell_y: int, seed_a: int, seed_b: int) -> float:
	var roll_hash: int = abs((cell_x * seed_a) ^ (cell_y * seed_b))
	return float(roll_hash % 1000) / 1000.0


func _draw_horizontal_dash_line(
	start_point: Vector2,
	end_point: Vector2,
	dash_length: float,
	gap_length: float,
	color: Color,
	width: float
) -> void:
	var total_length := end_point.x - start_point.x
	if total_length <= 0.0:
		return

	var safe_dash_length := maxf(4.0, dash_length)
	var safe_gap_length := maxf(2.0, gap_length)
	var segment_start := start_point.x
	while segment_start < end_point.x:
		var segment_end := minf(segment_start + safe_dash_length, end_point.x)
		draw_line(
			Vector2(segment_start, start_point.y),
			Vector2(segment_end, start_point.y),
			color,
			width,
			true
		)
		segment_start += safe_dash_length + safe_gap_length
