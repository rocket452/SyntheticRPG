extends Node2D
class_name ImpSummonPentagramEffect

signal summon_finished

const SUMMON_SHEET_PATH: String = "res://assets/external/pentagram/fire_fear_summon-Sheet.png"
const SUMMON_ANIM: StringName = &"summon"
const SUMMON_FRAME_SIZE: Vector2i = Vector2i(816, 816)
const SUMMON_FRAME_COUNT: int = 54

static var summon_sheet_image_cache: Image = null
static var summon_frames_cache: SpriteFrames = null

@export var animation_fps: float = 12.0
@export var summon_duration: float = 2.0
@export var sprite_scale: Vector2 = Vector2(0.11, 0.11)
@export var layer_z_index: int = 2

var summon_sprite: AnimatedSprite2D = null


static func warm_cache() -> void:
	if summon_frames_cache != null:
		return
	var sheet_image := _load_summon_sheet_image()
	if sheet_image == null:
		return
	summon_sheet_image_cache = sheet_image
	summon_frames_cache = _build_summon_frames_from_image(sheet_image, 12.0)


func _ready() -> void:
	top_level = true
	z_index = layer_z_index
	_ensure_sprite()
	if summon_sprite == null or not is_instance_valid(summon_sprite):
		queue_free()
		return
	var frames := _get_summon_frames()
	if frames == null:
		queue_free()
		return
	summon_sprite.sprite_frames = frames
	summon_sprite.scale = sprite_scale
	summon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	summon_sprite.speed_scale = _get_playback_speed_scale()
	summon_sprite.play(SUMMON_ANIM)
	summon_sprite.animation_finished.connect(_on_summon_finished, CONNECT_ONE_SHOT)


func _ensure_sprite() -> void:
	if summon_sprite != null and is_instance_valid(summon_sprite):
		return
	summon_sprite = AnimatedSprite2D.new()
	summon_sprite.centered = true
	add_child(summon_sprite)


func _on_summon_finished() -> void:
	summon_finished.emit()
	queue_free()


func get_expected_duration() -> float:
	var clamped_duration := maxf(0.05, summon_duration)
	return clamped_duration


func _get_summon_frames() -> SpriteFrames:
	if summon_frames_cache != null:
		return summon_frames_cache
	var sheet_image := _get_summon_sheet_image()
	if sheet_image == null:
		return null
	var frames := _build_summon_frames_from_image(sheet_image, animation_fps)
	if frames == null:
		return null
	summon_frames_cache = frames
	return summon_frames_cache


func _get_summon_sheet_image() -> Image:
	if summon_sheet_image_cache != null:
		return summon_sheet_image_cache
	var image := _load_summon_sheet_image()
	if image == null:
		return null
	summon_sheet_image_cache = image
	return summon_sheet_image_cache


static func _build_summon_frames_from_image(sheet_image: Image, fps: float) -> SpriteFrames:
	if sheet_image == null:
		return null
	var sheet_width := sheet_image.get_width()
	var sheet_height := sheet_image.get_height()
	if sheet_width <= 0 or sheet_height <= 0:
		push_warning("Invalid imp summon pentagram sheet size: %dx%d" % [sheet_width, sheet_height])
		return null
	var frames := SpriteFrames.new()
	frames.add_animation(SUMMON_ANIM)
	frames.set_animation_speed(SUMMON_ANIM, maxf(1.0, fps))
	frames.set_animation_loop(SUMMON_ANIM, false)
	var frame_total := mini(SUMMON_FRAME_COUNT, int(floor(float(sheet_width) / float(SUMMON_FRAME_SIZE.x))))
	for frame_index in range(frame_total):
		var region := Rect2i(frame_index * SUMMON_FRAME_SIZE.x, 0, SUMMON_FRAME_SIZE.x, mini(SUMMON_FRAME_SIZE.y, sheet_height))
		if region.position.x + region.size.x > sheet_width:
			break
		if region.size.x <= 0 or region.size.y <= 0:
			continue
		var frame_image := sheet_image.get_region(region)
		if frame_image == null:
			continue
		var frame_texture := ImageTexture.create_from_image(frame_image)
		if frame_texture == null:
			continue
		frames.add_frame(SUMMON_ANIM, frame_texture)
	if frames.get_frame_count(SUMMON_ANIM) <= 0:
		push_warning("Failed to build imp summon pentagram frames from sheet: %s" % SUMMON_SHEET_PATH)
		return null
	return frames


static func _load_summon_sheet_image() -> Image:
	var image := Image.new()
	var file_path := ProjectSettings.globalize_path(SUMMON_SHEET_PATH)
	var err := image.load(file_path)
	if err != OK:
		push_warning("Failed to load imp summon pentagram image (%d): %s" % [err, SUMMON_SHEET_PATH])
		return null
	return image


func _get_playback_speed_scale() -> float:
	var base_fps := maxf(1.0, animation_fps)
	var desired_duration := maxf(0.05, summon_duration)
	var frame_count := SUMMON_FRAME_COUNT
	if summon_frames_cache != null:
		frame_count = maxi(1, summon_frames_cache.get_frame_count(SUMMON_ANIM))
	var desired_fps := float(frame_count) / desired_duration
	return desired_fps / base_fps
