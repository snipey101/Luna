extends Node3D
## Sets up the world, Luna, the dogs, camera, lighting and HUD.
##
## Debug: `godot --path game -- --screenshot=out.png [--shot-delay=2.0] [--seed=N]`
## saves a screenshot after the delay and quits.

const LUNA_START := Vector3(0, 0, 0)

var world: World
var luna: Luna
var camera: IsoCamera
var hud: Hud
var dogs: Array[Dog] = []
var _rng := RandomNumberGenerator.new()
var _args := {}


func _ready() -> void:
	_parse_args()
	var seed_value: int = int(_args.get("seed", randi()))
	_rng.seed = seed_value

	_build_environment()
	world = World.new()
	add_child(world)
	world.build(seed_value)

	luna = Luna.new()
	luna.position = LUNA_START
	add_child(luna)
	if _args.has("luna-pos"):
		var xz: PackedStringArray = _args["luna-pos"].split(",")
		luna.position = Vector3(float(xz[0]), 0, float(xz[1]))

	camera = IsoCamera.new()
	camera.target = luna
	add_child(camera)
	camera.current = true
	if _args.has("zoom"):
		camera.set_zoom(float(_args["zoom"]))
	if _args.has("cam-size"):
		camera.set_zoom(IsoCamera.BASE_SIZE / float(_args["cam-size"]))
	luna.camera_yaw = deg_to_rad(camera.yaw_deg)

	_spawn_dogs()

	hud = Hud.new()
	add_child(hud)
	hud.play_again.connect(_on_play_again)
	hud.quit.connect(func(): get_tree().quit())
	GameState.won.connect(_on_won)
	Sfx.start_music()

	if _args.has("demo"):
		_demo.call_deferred()
	if _args.has("screenshot"):
		_take_screenshot(_args.screenshot, float(_args.get("shot-delay", 2.0)))


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#BFE6FF")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#FFF1DC")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.ssao_enabled = true
	env.ssao_radius = 0.6
	env.ssao_intensity = 1.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("#FFF0D2")
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)


func _spawn_dogs() -> void:
	var yard_homes := world.yard_homes()
	var yard_i := 0
	for key: String in Breeds.DATA:
		var breed: Dictionary = Breeds.DATA[key]
		for i in breed.count:
			var home: Vector3
			if breed.personality == Breeds.Personality.AGGRESSIVE:
				var yh := yard_homes[yard_i % yard_homes.size()]
				home = yh + Vector3(_rng.randf_range(-2.5, 2.5), 0, _rng.randf_range(-2, 2))
				yard_i += 1
			else:
				var p := _random_spawn()
				home = Vector3(p.x, 0, p.y)
			var dog := Dog.new()
			dog.name = "%s_%d" % [key, i]
			dog.setup(key, home, luna, world)
			add_child(dog)
			dogs.append(dog)


## Free sand at least 7 m from Luna's start and 4 m from other dogs.
func _random_spawn() -> Vector2:
	for attempt in 100:
		var p := world.random_free_point(_rng, Vector2(LUNA_START.x, LUNA_START.z), 7.0)
		var ok := true
		for d in dogs:
			if p.distance_to(Vector2(d.home.x, d.home.z)) < 4.0:
				ok = false
				break
		if ok:
			return p
	return world.random_free_point(_rng, Vector2.ZERO, 7.0)


func _on_won() -> void:
	luna.controls_enabled = false
	luna.anim.wag = 1.0
	Sfx.stop_music()
	Sfx.play("win", 0.0, 0.0)
	Fx.popup(luna, "Hooray!", Color("#FF6F91"), Vector3(0, Luna.HEAD_HEIGHT, 0), 1.2)
	await get_tree().create_timer(1.6).timeout
	get_tree().paused = true
	hud.show_win()


func _on_play_again() -> void:
	GameState.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()


## Debug helper for screenshots: befriend a few dogs and walk Luna next to them.
func _demo() -> void:
	await get_tree().create_timer(0.3).timeout
	var near := dogs.filter(func(d): return d.personality != Breeds.Personality.AGGRESSIVE)
	near.sort_custom(func(a, b): return a.global_position.length() < b.global_position.length())
	for d: Dog in near.slice(0, 3):
		d.befriend()
	luna.global_position = near[0].global_position + Vector3(1.5, 0, 1.5)
	luna.bark()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "true"


func _take_screenshot(path: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("screenshot saved: ", path)
	get_tree().quit()
