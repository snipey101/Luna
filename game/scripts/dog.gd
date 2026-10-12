class_name Dog
extends CharacterBody3D
## An NPC dog. Personality (from Breeds) decides how it reacts to Luna.

enum State { IDLE, WANDER, ATTENTIVE, FLEE, TIRED, CHASE, SCARED, RETURN, FOLLOW, HAPPY, LURED, SNIFF }

const P := Breeds.Personality
const FOLLOW_TIME := 8.0
const HEART := preload("res://assets/models/heart.glb")

var breed_key := ""
var personality: Breeds.Personality
var stats := {}
var home := Vector3.ZERO
var luna: Luna
var world: World
var state := State.IDLE
var befriended := false

var model: Node3D
var anim: DogAnim
var _path := PackedVector3Array()
var _path_i := 0
var _timer := 0.0          # time left in the current state
var _flee_time := 0.0
var _cooldown := 0.0       # aggressive: time until it can bite again
var _repath := 0.0
var _speed := 0.0
var _scale := 1.0
var _heart: Node3D
var _last_alert_ms := -100000
var _lure: Node3D            # pee spot being visited
var _sniffed: Array[int] = [] # pee spots already visited (instance ids)


func setup(key: String, home_pos: Vector3, luna_ref: Luna, world_ref: World) -> void:
	breed_key = key
	personality = Breeds.DATA[key].personality
	stats = Breeds.stats_for(key)
	_scale = Breeds.DATA[key].scale * Breeds.MODEL_SCALE
	home = home_pos
	luna = luna_ref
	world = world_ref
	position = home_pos


func _ready() -> void:
	add_to_group("dogs")
	collision_layer = 4
	collision_mask = 1
	model = Breeds.model_for(breed_key).instantiate()
	model.rotation.y = randf() * TAU
	add_child(model)
	anim = DogAnim.new()
	add_child(anim)
	anim.setup(model)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.2 * _scale
	cap.height = maxf(0.55 * _scale, cap.radius * 2.0 + 0.01)
	col.shape = cap
	col.position.y = cap.height / 2.0
	add_child(col)
	_enter(State.IDLE)


func _physics_process(delta: float) -> void:
	_timer -= delta
	_cooldown = maxf(0.0, _cooldown - delta)
	_repath -= delta
	var to_luna := luna.global_position - global_position
	to_luna.y = 0
	var dist := to_luna.length()

	match state:
		State.IDLE, State.WANDER:
			if _try_lure():
				pass
			elif not _react_to_luna(dist):
				if state == State.IDLE and _timer <= 0.0:
					_wander_to_random_point()
				elif state == State.WANDER and (_timer <= 0.0 or _path_finished()):
					_enter(State.IDLE)
		State.ATTENTIVE:
			if dist > _notice() + 1.0:
				_enter(State.IDLE)
		State.FLEE:
			_flee_time += delta
			if _flee_time >= stats.flee_time:
				_enter(State.TIRED)
			elif dist > _notice() + 4.0:
				_enter(State.IDLE)
			elif _repath <= 0.0:
				_set_flee_target()
		State.TIRED:
			if _timer <= 0.0:
				_flee_time = 0.0
				_enter(State.IDLE)
		State.CHASE:
			var luna_from_home := luna.global_position.distance_to(home)
			if _cooldown > 0.0 or luna_from_home > stats.leash or global_position.distance_to(home) > stats.leash:
				_enter(State.RETURN)
			elif _repath <= 0.0:
				_go_to(luna.global_position, stats.chase_speed)
				_repath = 0.2
		State.LURED:
			if not is_instance_valid(_lure):
				_enter(State.IDLE)
			elif _flat_dist(_lure.global_position) < 0.6 * _scale + 0.3 or _path_finished():
				_enter(State.SNIFF)
		State.SNIFF:
			if _timer <= 0.0 or not is_instance_valid(_lure):
				_lure = null
				_enter(State.IDLE)
		State.SCARED:
			if _timer <= 0.0:
				_enter(State.RETURN)
			elif _repath <= 0.0:
				_set_flee_target(stats.scared_speed)
		State.RETURN:
			if _path_finished() or global_position.distance_to(home) < 1.5:
				_enter(State.IDLE)
		State.FOLLOW:
			if _timer <= 0.0:
				home = global_position
				_enter(State.HAPPY)
			elif _repath <= 0.0:
				var behind := luna.global_position - to_luna.normalized() * 1.6
				_go_to(behind, 4.6 if dist > 2.5 else 0.0)
				_repath = 0.25
		State.HAPPY:
			if _timer <= 0.0 or _path_finished():
				_wander_to_random_point()

	_move(delta, to_luna)


## Timid dogs can't resist sniffing a fresh pee spot, and stay calm while
## they do. Each spot only lures each dog once.
func _try_lure() -> bool:
	if personality != P.TIMID or befriended:
		return false
	for spot: Node3D in get_tree().get_nodes_in_group("pee_spots"):
		var id := spot.get_instance_id()
		if id in _sniffed or _flat_dist(spot.global_position) > GameState.LURE_RADIUS:
			continue
		_sniffed.append(id)
		_lure = spot
		_enter(State.LURED)
		return true
	return false


func _flat_dist(p: Vector3) -> float:
	return Vector2(p.x - global_position.x, p.z - global_position.z).length()


## Returns true if the personality reacted (and changed state).
func _react_to_luna(dist: float) -> bool:
	match personality:
		P.FRIENDLY:
			if dist < _notice():
				_enter(State.ATTENTIVE)
				return true
		P.TIMID:
			if dist < _notice():
				_enter(State.FLEE)
				_alert(Color("#4A90D9"))
				return true
		P.AGGRESSIVE:
			if _cooldown <= 0.0 and dist < _notice() and luna.global_position.distance_to(home) < stats.leash:
				_enter(State.CHASE)
				_alert(Color("#E5484D"))
				Sfx.play("bark", -6.0, 0.05)
				return true
	return false


## Roughly the top of this dog's head, for bubbles and markers.
func _head_height() -> float:
	return 0.6 * _scale + 0.3


## How close Luna can get before this dog reacts, scaled to the camera zoom.
func _notice() -> float:
	var base: float = stats.notice_sneak if personality == P.TIMID and luna.sneaking else stats.notice
	return base * GameState.range_scale


## Pops a "!" over the dog's head so the player sees it react, even near the
## screen edge. Rate-limited so a dog dithering at the range edge doesn't spam.
func _alert(color: Color) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_alert_ms < 2500:
		return
	_last_alert_ms = now
	Fx.speech_bubble(self, "!", color, Vector3(0, _head_height(), 0), 1.0, 0.0, 0.8)


func _enter(s: State) -> void:
	state = s
	_repath = 0.0
	anim.sitting = s == State.TIRED
	anim.panting = s == State.TIRED
	anim.crouch = s == State.SCARED  # cowering
	anim.sniffing = s == State.SNIFF
	match s:
		State.IDLE:
			_timer = randf_range(1.5, 4.0)
			_stop()
		State.ATTENTIVE:
			_stop()
		State.FLEE:
			_set_flee_target()
		State.TIRED:
			_timer = stats.tired_time
			_stop()
		State.LURED:
			# Stop with the nose over the spot.
			var from_spot := global_position - _lure.global_position
			from_spot.y = 0
			var stand := _lure.global_position + from_spot.normalized() * (0.6 * _scale)
			_go_to(stand, stats.wander_speed * 2.2)
			Fx.speech_bubble(self, "Sniff?", Color("#4A90D9"), Vector3(0, _head_height(), 0), 0.7, 0.0, 1.0)
		State.SNIFF:
			_timer = GameState.SNIFF_TIME
			_stop()
		State.SCARED:
			_timer = stats.scared_time
			_set_flee_target(stats.scared_speed)
		State.RETURN:
			_go_to(home, stats.wander_speed * 1.6)
		State.FOLLOW:
			_timer = FOLLOW_TIME
		State.HAPPY:
			_timer = randf_range(2.0, 5.0)


func _wander_to_random_point() -> void:
	var radius: float = stats.wander_radius
	var target := home
	for i in 10:
		var off := Vector2.from_angle(randf() * TAU) * randf_range(1.0, radius)
		var p := Vector2(home.x, home.z) + off
		var in_own_yard := world.in_yard(Vector2(home.x, home.z))
		if (in_own_yard and world.in_yard(p)) or (not in_own_yard and world.is_free(p, 0.6)):
			target = Vector3(p.x, 0, p.y)
			break
	_go_to(target, stats.wander_speed)
	if state != State.HAPPY:
		state = State.WANDER
	_timer = 8.0


func _set_flee_target(speed := -1.0) -> void:
	var away := global_position - luna.global_position
	away.y = 0
	away = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
	var map := get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return
	var best := global_position
	var best_score := -INF
	for deg in [0, 35, -35, 70, -70, 110, -110]:
		var dir := away.rotated(Vector3.UP, deg_to_rad(deg))
		var p := NavigationServer3D.map_get_closest_point(map, global_position + dir * 5.0)
		if p.y > 1.0:
			continue  # navmesh island on top of an obstacle
		var score := p.distance_to(luna.global_position) + p.distance_to(global_position) - absf(deg) * 0.01
		if score > best_score:
			best_score = score
			best = p
	_go_to(best, speed if speed > 0.0 else stats.flee_speed)
	_repath = 0.35


func _go_to(target: Vector3, speed: float) -> void:
	var map := get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return  # map not synchronised yet (first frame)
	_path = NavigationServer3D.map_get_path(map, global_position, target, true)
	_path_i = 0
	_speed = speed


func _stop() -> void:
	_speed = 0.0
	_path = PackedVector3Array()


func _path_finished() -> bool:
	return _path_i >= _path.size()


## Next path point to steer at, measured on the ground plane (the baked
## navmesh floats a little above the ground).
func _next_waypoint() -> Vector3:
	while _path_i < _path.size():
		var d := _path[_path_i] - global_position
		d.y = 0
		if d.length() > 0.35:
			return d
		_path_i += 1
	return Vector3.ZERO


func _move(delta: float, to_luna: Vector3) -> void:
	var desired := Vector3.ZERO
	if _speed > 0.0:
		var d := _next_waypoint()
		if d != Vector3.ZERO:
			desired = d.normalized() * _speed
	velocity.x = lerpf(velocity.x, desired.x, 1.0 - exp(-10.0 * delta))
	velocity.z = lerpf(velocity.z, desired.z, 1.0 - exp(-10.0 * delta))
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()

	# Face movement, or face Luna when paying attention to her.
	var face := Vector3(velocity.x, 0, velocity.z)
	if state in [State.ATTENTIVE, State.TIRED] or (state == State.FOLLOW and face.length() < 0.3):
		face = to_luna
	elif state == State.SNIFF and is_instance_valid(_lure):
		face = _lure.global_position - global_position
		face.y = 0
	if face.length() > 0.2:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-face.x, -face.z), 1.0 - exp(-8.0 * delta))

	anim.speed_ratio = Vector2(velocity.x, velocity.z).length() / clampf(2.2 * _scale, 2.5, 5.0)
	anim.wag = 1.0 if state in [State.ATTENTIVE, State.FOLLOW, State.HAPPY, State.SNIFF] else 0.2
	if personality == P.AGGRESSIVE and not befriended:
		anim.wag = 0.0
	if _heart:
		_heart.position.y = 0.6 * _scale + 0.55 + sin(Time.get_ticks_msec() * 0.004) * 0.06
		# Face the iso camera (yaw 45°) with a gentle sway rather than spinning edge-on.
		_heart.rotation.y = deg_to_rad(45.0) + sin(Time.get_ticks_msec() * 0.003) * 0.35


## Called every physics frame while Luna overlaps this dog.
func on_luna_touch(l: Luna) -> void:
	if befriended:
		return
	# A scared aggressive dog (just barked at) can be befriended instead.
	if personality == P.AGGRESSIVE and state != State.SCARED:
		if _cooldown > 0.0 or not l.hit(global_position):
			return
		_cooldown = stats.cooldown
		var applied := GameState.add_score(-1)
		Fx.popup(l, "-1" if applied < 0 else "Ouch!", Color("#E5484D"), Vector3(0, Luna.HEAD_HEIGHT, 0))
		_enter(State.RETURN)
	else:
		befriend()


## Luna barked nearby. Aggressive dogs get scared: they cower and run off
## (befriendable for `scared_time`), then go home and leave her alone for
## the rest of their cooldown.
func on_bark(l: Luna) -> void:
	if personality != P.AGGRESSIVE or befriended or _cooldown > 0.0:
		return
	_cooldown = stats.cooldown
	Sfx.play("whimper", -8.0, 0.15)
	anim.squash()
	Fx.popup(self, "Eep!", Color("#5B7FD6"), Vector3(0, _head_height(), 0), 0.8)
	_enter(State.SCARED)


func befriend() -> void:
	befriended = true
	Sfx.play("chime", -4.0, 0.0)
	anim.squash()
	_heart = HEART.instantiate()
	_heart.scale = Vector3.ONE * 1.6
	add_child(_heart)
	Fx.popup(self, "+1", Color("#FF6F91"), Vector3(0, _head_height() + 0.6, 0))  # above the heart
	_enter(State.FOLLOW)
	GameState.add_score(1)
