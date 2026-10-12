class_name IsoCamera
extends Camera3D
## Fixed-angle orthographic camera that smoothly follows a target.
## Zoom is player-adjustable (mouse wheel or +/-) and remembered between runs.

const BASE_SIZE := 13.0      ## ortho size at zoom 1.0 (the original wide view)
const DEFAULT_ZOOM := 2.0    ## 200%: closer, cuter view
const ZOOM_MIN := 1.0
const ZOOM_MAX := 3.0
const ZOOM_STEP := 0.25
const SETTINGS_PATH := "user://settings.cfg"

@export var yaw_deg := 45.0
@export var pitch_deg := 38.0
@export var distance := 40.0
@export var follow_speed := 5.0

var target: Node3D
var zoom := DEFAULT_ZOOM


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	near = 0.5
	far = 120.0
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		zoom = clampf(cfg.get_value("camera", "zoom", DEFAULT_ZOOM), ZOOM_MIN, ZOOM_MAX)
	size = BASE_SIZE / zoom
	GameState.range_scale = GameState.range_scale_for_zoom(zoom)
	if target:
		_snap()


## Set zoom immediately (no smoothing). `save` persists it for next time.
## Not clamped to the player range so debug flags can zoom right out.
func set_zoom(z: float, save := false) -> void:
	zoom = maxf(z, 0.1)
	size = BASE_SIZE / zoom
	GameState.range_scale = GameState.range_scale_for_zoom(zoom)
	if save:
		_save()


func _unhandled_input(event: InputEvent) -> void:
	var step := 0.0
	if event.is_action_pressed("zoom_in"):
		step = ZOOM_STEP
	elif event.is_action_pressed("zoom_out"):
		step = -ZOOM_STEP
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			step = ZOOM_STEP
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			step = -ZOOM_STEP
	if step != 0.0:
		zoom = clampf(zoom + step, ZOOM_MIN, ZOOM_MAX)
		GameState.range_scale = GameState.range_scale_for_zoom(zoom)
		_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("camera", "zoom", zoom)
	cfg.save(SETTINGS_PATH)


func _snap() -> void:
	global_position = target.global_position + _offset()
	look_at(target.global_position)


func _offset() -> Vector3:
	var yaw := deg_to_rad(yaw_deg)
	var pitch := deg_to_rad(pitch_deg)
	return Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance


func _process(delta: float) -> void:
	if target == null:
		return
	var goal := target.global_position + _offset()
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))
	size = lerpf(size, BASE_SIZE / zoom, 1.0 - exp(-10.0 * delta))
