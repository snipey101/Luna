class_name Luna
extends CharacterBody3D
## The player: a labrador puppy. WASD to move, Shift to sneak, Space to bark.

const WALK_SPEED := 5.5
const SNEAK_SPEED := 2.6
const INVULN_TIME := 1.5
const HEAD_HEIGHT := 1.35  ## where speech bubbles start
const BARK_RADIUS := 4.5    ## aggressive dogs this close get scared off
const BARK_COOLDOWN := 1.5  ## stops bark spam making Luna untouchable

var camera_yaw := deg_to_rad(45.0)
var controls_enabled := true
var sneaking := false
var invulnerable := 0.0

var model: Node3D
var anim: DogAnim
var _move_vel := Vector3.ZERO
var _knock := Vector3.ZERO
var _touch: Area3D
var _step_timer := 0.0
var _bark_cooldown := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	model = preload("res://assets/models/dog_luna.glb").instantiate()
	add_child(model)
	anim = DogAnim.new()
	add_child(anim)
	anim.setup(model)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.1
	col.shape = cap
	col.position.y = 0.55
	add_child(col)

	# Overlap sensor for touching dogs (layer 3).
	_touch = Area3D.new()
	_touch.collision_layer = 0
	_touch.collision_mask = 4
	var ts := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.75
	ts.shape = sphere
	ts.position.y = 0.5
	_touch.add_child(ts)
	add_child(_touch)


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if controls_enabled:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	sneaking = controls_enabled and Input.is_action_pressed("sneak")
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, camera_yaw)
	var speed := SNEAK_SPEED if sneaking else WALK_SPEED
	_move_vel = _move_vel.lerp(dir * speed, 1.0 - exp(-14.0 * delta))
	_knock = _knock.move_toward(Vector3.ZERO, 18.0 * delta)

	velocity.x = _move_vel.x + _knock.x
	velocity.z = _move_vel.z + _knock.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()

	if dir.length() > 0.1:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-dir.x, -dir.z), 1.0 - exp(-14.0 * delta))
	var planar := Vector2(velocity.x, velocity.z).length()
	anim.speed_ratio = planar / WALK_SPEED * (1.6 if sneaking else 1.0)
	anim.crouch = sneaking
	anim.wag = 0.5

	_bark_cooldown = maxf(0.0, _bark_cooldown - delta)
	_update_steps(delta, planar)
	_update_invulnerability(delta)
	for body in _touch.get_overlapping_bodies():
		if body.has_method("on_luna_touch"):
			body.on_luna_touch(self)


func _unhandled_input(event: InputEvent) -> void:
	if controls_enabled and event.is_action_pressed("bark"):
		bark()


func bark() -> void:
	if _bark_cooldown > 0.0:
		return
	_bark_cooldown = BARK_COOLDOWN
	Sfx.play("bark", -2.0, 0.12)
	anim.squash()
	Fx.popup(self, "Woof!", Color("#7A5230"), Vector3(0, HEAD_HEIGHT, 0), 0.8)
	for dog in get_tree().get_nodes_in_group("dogs"):
		if dog.global_position.distance_to(global_position) <= BARK_RADIUS:
			dog.on_bark(self)


## Called by an aggressive dog. Returns false while still recovering.
func hit(from: Vector3) -> bool:
	if invulnerable > 0.0:
		return false
	invulnerable = INVULN_TIME
	var away := global_position - from
	away.y = 0
	_knock = away.normalized() * 7.0 if away.length() > 0.01 else Vector3(0, 0, 7)
	Sfx.play("whimper", -3.0)
	anim.squash()
	return true


func _update_invulnerability(delta: float) -> void:
	if invulnerable > 0.0:
		invulnerable -= delta
		model.visible = invulnerable <= 0.0 or int(invulnerable * 12.0) % 2 == 0


func _update_steps(delta: float, planar: float) -> void:
	if planar < 0.5 or not is_on_floor():
		_step_timer = 0.0
		return
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = 0.45 if sneaking else 0.28
		Sfx.play("step", -20.0 if sneaking else -14.0, 0.2)
