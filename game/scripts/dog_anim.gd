class_name DogAnim
extends Node
## Procedural animation for the Blender dog models: leg swing, body bob,
## tail wag, ear flop, sitting, panting and squash. Drive it by setting the
## public vars each frame.

var speed_ratio := 0.0   ## 0 = still, 1 = full walk speed
var wag := 0.3           ## 0..1 tail excitement
var sitting := false
var panting := false
var crouch := false

var model: Node3D
var _body: Node3D
var _head: Node3D
var _tail: Node3D
var _legs: Array[Node3D] = []
var _ears: Array[Node3D] = []
var _base := {}
var _t := randf() * 10.0
var _sit := 0.0
var _crouch := 0.0
var _height := 0.3


func setup(m: Node3D) -> void:
	model = m
	_body = m.find_child("Body", true, false)
	_head = m.find_child("Head", true, false)
	_tail = m.find_child("Tail", true, false)
	for n in ["LegFL", "LegFR", "LegBL", "LegBR"]:
		_legs.append(m.find_child(n, true, false))
	for n in ["EarL", "EarR"]:
		var e: Node3D = m.find_child(n, true, false)
		if e:
			_ears.append(e)
	for n: Node3D in [_body, _head, _tail] + _legs + _ears:
		if n:
			_base[n] = n.transform
	_height = _body.position.y if _body else 0.3


func squash() -> void:
	var tw := create_tween()
	tw.tween_property(model, "scale", Vector3(1.18, 0.82, 1.18), 0.07)
	tw.tween_property(model, "scale", Vector3(0.92, 1.1, 0.92), 0.08)
	tw.tween_property(model, "scale", Vector3.ONE, 0.12)


func _process(delta: float) -> void:
	if model == null:
		return
	var moving := clampf(speed_ratio, 0.0, 1.4)
	_t += delta * (6.0 + 8.0 * moving)
	_sit = move_toward(_sit, 1.0 if sitting else 0.0, delta * 4.0)
	_crouch = move_toward(_crouch, 1.0 if crouch else 0.0, delta * 6.0)

	var swing := sin(_t) * 0.75 * moving
	var leg_sign := [1.0, -1.0, -1.0, 1.0]
	for i in _legs.size():
		var leg := _legs[i]
		if leg:
			leg.transform = _base[leg]
			# Back legs fold forward when sitting.
			var sit_fold := -1.1 * _sit if i >= 2 else 0.0
			leg.rotate_object_local(Vector3.RIGHT, swing * leg_sign[i] + sit_fold)

	if _body:
		_body.transform = _base[_body]
		_body.position.y += absf(sin(_t)) * 0.08 * _height * moving
		_body.position.y -= _crouch * 0.25 * _height + _sit * 0.2 * _height
		_body.rotate_object_local(Vector3.RIGHT, _sit * 0.45)
		_body.rotate_object_local(Vector3.FORWARD, sin(_t) * 0.05 * moving)

	if _head:
		_head.transform = _base[_head]
		var nod := sin(_t * 0.25) * 0.05
		if panting:
			nod = sin(Time.get_ticks_msec() * 0.025) * 0.08
		_head.rotate_object_local(Vector3.RIGHT, nod - _sit * 0.3 + _crouch * 0.15)

	if _tail:
		_tail.transform = _base[_tail]
		var wag_speed := 0.012 + 0.02 * wag
		var w := sin(Time.get_ticks_msec() * wag_speed) * (0.25 + 0.55 * wag)
		_tail.rotate_object_local(Vector3.FORWARD, w)
		_tail.rotate_object_local(Vector3.UP, w * 0.5)

	for i in _ears.size():
		var ear := _ears[i]
		ear.transform = _base[ear]
		var side := -1.0 if i == 0 else 1.0
		ear.rotate_object_local(Vector3.FORWARD, side * (sin(_t * 2.0) * 0.12 * moving + _crouch * 0.3))
