extends Node2D

@export var arena_width: float = 1560.0
@export var arena_height: float = 420.0
@export var sidewalk_height: float = 48.0
@export var lane_count: int = 3
@export var divider_dash: float = 52.0
@export var divider_gap: float = 34.0
@export var vertical_grid_step: float = 120.0

@export var asphalt_color: Color = Color(0.15, 0.17, 0.2, 0.95)
@export var border_color: Color = Color(0.32, 0.34, 0.4, 0.95)
@export var sidewalk_color: Color = Color(0.28, 0.3, 0.35, 0.92)
@export var lane_divider_color: Color = Color(0.86, 0.82, 0.68, 0.55)
@export var vertical_grid_color: Color = Color(0.78, 0.82, 0.92, 0.12)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var clamped_lane_count := maxi(1, lane_count)
	var half_width := arena_width * 0.5
	var half_height := arena_height * 0.5
	var arena_rect := Rect2(Vector2(-half_width, -half_height), Vector2(arena_width, arena_height))
	draw_rect(arena_rect, asphalt_color, true)
	draw_rect(arena_rect, border_color, false, 4.0, true)

	var clamped_sidewalk_height := clampf(sidewalk_height, 0.0, arena_height * 0.45)
	if clamped_sidewalk_height > 0.0:
		draw_rect(
			Rect2(arena_rect.position, Vector2(arena_rect.size.x, clamped_sidewalk_height)),
			sidewalk_color,
			true
		)
		draw_rect(
			Rect2(
				Vector2(arena_rect.position.x, arena_rect.end.y - clamped_sidewalk_height),
				Vector2(arena_rect.size.x, clamped_sidewalk_height)
			),
			sidewalk_color,
			true
		)

	var playable_top := arena_rect.position.y + clamped_sidewalk_height
	var playable_bottom := arena_rect.end.y - clamped_sidewalk_height
	var playable_height := playable_bottom - playable_top
	if playable_height <= 2.0:
		return

	var lane_height := playable_height / float(clamped_lane_count)
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

	if vertical_grid_step > 16.0:
		var x := arena_rect.position.x + vertical_grid_step
		while x < arena_rect.end.x:
			draw_line(Vector2(x, playable_top), Vector2(x, playable_bottom), vertical_grid_color, 1.0, true)
			x += vertical_grid_step


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
