extends Node3D
## Title screen: Luna and a few friends wagging on a little lawn, with the
## game title and Play / Quit. Enter, Space or a click on Play starts.
##
## Any debug flags on the command line (e.g. --screenshot) skip straight to
## the game, unless --splash is given (for screenshots of this screen).
## --splash --autoplay presses Play after a moment, to check the hand-over.

const MAIN_SCENE := "res://scenes/Main.tscn"
const PINK := Color("#FF6F91")

## [breed, position, facing (deg)]: Luna front and centre.
const CAST := [
	["luna", Vector3(0, 0, 0.6), 0.0],
	["golden", Vector3(-1.9, 0, -0.6), 25.0],
	["corgi", Vector3(1.7, 0, -0.2), -30.0],
	["poodle", Vector3(-0.9, 0, -2.0), 10.0],
	["chihuahua", Vector3(1.0, 0, -1.8), -15.0],
]

var _dogs: Array[Dictionary] = []  # {model, anim}
var _camera: Camera3D
var _t := 0.0
var _hop := 2.0
var _starting := false
var _fade: ColorRect


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and not "--splash" in args:
		get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)
		return
	World.add_environment(self)
	_build_stage()
	_build_ui()
	Sfx.start_music()
	if "--autoplay" in args:
		get_tree().create_timer(0.8).timeout.connect(_start)
	elif "--splash" in args:
		_screenshot_if_asked(args)


func _process(delta: float) -> void:
	_t += delta
	# Gentle camera sway.
	_camera.position.x = sin(_t * 0.3) * 0.6
	_camera.look_at(Vector3(0, 0.55, -0.4))
	# Every couple of seconds a random dog does a happy hop.
	_hop -= delta
	if _hop <= 0.0 and not _dogs.is_empty():
		_hop = randf_range(1.2, 2.4)
		var d: Dictionary = _dogs.pick_random()
		d.anim.squash()
		var m: Node3D = d.model
		var tw := create_tween()
		tw.tween_property(m, "position:y", 0.25, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(m, "position:y", 0.0, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().quit()


func _start() -> void:
	if _starting:
		return
	_starting = true
	Sfx.play("bark", -2.0, 0.1)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.4)
	tw.tween_callback(func(): get_tree().change_scene_to_file(MAIN_SCENE))


func _build_stage() -> void:
	_camera = Camera3D.new()
	_camera.fov = 38.0
	_camera.position = Vector3(0, 2.0, 6.2)
	add_child(_camera)
	_camera.current = true

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	var sand := StandardMaterial3D.new()
	sand.albedo_color = World.SAND
	sand.roughness = 1.0
	plane.material = sand
	ground.mesh = plane
	add_child(ground)

	var lawn := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 3.6
	disc.bottom_radius = 3.6
	disc.height = 0.06
	disc.radial_segments = 40
	var grass := StandardMaterial3D.new()
	grass.albedo_color = World.GRASS
	grass.roughness = 1.0
	disc.material = grass
	lawn.mesh = disc
	lawn.position = Vector3(0, 0, -0.6)
	add_child(lawn)

	var props := [
		[World.TREE_ROUND, Vector3(-4.2, 0, -4.0), 1.2],
		[World.TREE_PINE, Vector3(4.6, 0, -4.6), 1.3],
		[World.TREE_ROUND, Vector3(6.5, 0, -1.0), 1.0],
		[World.BUSH, Vector3(-3.6, 0, 0.6), 0.9],
		[World.FLOWERS, Vector3(-2.2, 0.02, 1.4), 1.6],
		[World.FLOWERS, Vector3(2.4, 0.02, 1.1), 1.4],
		[World.FLOWERS, Vector3(0.4, 0.02, -3.2), 1.5],
	]
	for p in props:
		var inst: Node3D = (p[0] as PackedScene).instantiate()
		inst.position = p[1]
		inst.scale = Vector3.ONE * p[2]
		inst.rotation.y = randf() * TAU
		add_child(inst)

	for c in CAST:
		var holder := Node3D.new()
		holder.position = c[1]
		add_child(holder)
		var model: Node3D = Breeds.model_for(c[0]).instantiate()
		# Models face -Z; turn them to the camera, angled a little for character.
		model.rotation.y = PI + deg_to_rad(c[2])
		holder.add_child(model)
		var anim := DogAnim.new()
		anim.wag = 1.0
		holder.add_child(anim)
		anim.setup(model)
		_dogs.append({"model": model, "anim": anim})


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.offset_top = 40
	col.add_theme_constant_override("separation", 0)
	ui.add_child(col)

	var title := Label.new()
	title.text = "Luna"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 132)
	title.add_theme_color_override("font_color", PINK)
	title.add_theme_color_override("font_outline_color", Hud.BROWN)
	title.add_theme_constant_override("outline_size", 22)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.18))
	title.add_theme_constant_override("shadow_offset_y", 6)
	col.add_child(title)

	var tag := Label.new()
	tag.text = "Help Luna the puppy make 10 dog friends"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 26)
	tag.add_theme_color_override("font_color", Hud.BROWN)
	tag.add_theme_color_override("font_outline_color", Hud.CREAM)
	tag.add_theme_constant_override("outline_size", 10)
	col.add_child(tag)

	var buttons := HBoxContainer.new()
	buttons.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	buttons.grow_horizontal = Control.GROW_DIRECTION_BOTH
	buttons.grow_vertical = Control.GROW_DIRECTION_BEGIN
	buttons.offset_bottom = -78
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	ui.add_child(buttons)
	var play := Button.new()
	play.text = "Play"
	play.custom_minimum_size = Vector2(190, 60)
	Hud.style_button(play)
	play.pressed.connect(_start)
	buttons.add_child(play)
	var quit := Button.new()
	quit.text = "Quit"
	quit.custom_minimum_size = Vector2(150, 60)
	Hud.style_button(quit)
	quit.pressed.connect(get_tree().quit)
	buttons.add_child(quit)
	play.grab_focus.call_deferred()  # Enter / Space start the game

	var controls := Label.new()
	controls.text = "WASD move  ·  Shift sneak  ·  Space bark  ·  E potty  ·  Wheel zoom  ·  Esc pause"
	controls.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	controls.grow_horizontal = Control.GROW_DIRECTION_BOTH
	controls.grow_vertical = Control.GROW_DIRECTION_BEGIN
	controls.offset_bottom = -28
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 18)
	controls.add_theme_color_override("font_color", Hud.BROWN)
	controls.add_theme_color_override("font_outline_color", Hud.CREAM)
	controls.add_theme_constant_override("outline_size", 8)
	ui.add_child(controls)

	_fade = ColorRect.new()
	_fade.color = Color(Hud.CREAM, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_fade)


func _screenshot_if_asked(args: PackedStringArray) -> void:
	for a in args:
		if a.begins_with("--screenshot="):
			await get_tree().create_timer(1.5).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(a.trim_prefix("--screenshot="))
			print("screenshot saved")
			get_tree().quit()
