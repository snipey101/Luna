class_name FoodBowl
extends Node3D
## A bowl of kibble. Luna eats it by walking into it; it refills after a while.

const MODEL := preload("res://assets/models/food_bowl.glb")
const EAT_RADIUS := 0.9

var has_food := true
var _kibble: Node3D
var _refill := 0.0


func _ready() -> void:
	add_to_group("bowls")
	var model: Node3D = MODEL.instantiate()
	model.scale = Vector3.ONE * 2.2
	add_child(model)
	_kibble = model.find_child("Kibble", true, false)


func eat() -> void:
	has_food = false
	_kibble.visible = false
	_refill = GameState.BOWL_REFILL_TIME


func _process(delta: float) -> void:
	if has_food:
		return
	_refill -= delta
	if _refill <= 0.0:
		has_food = true
		_kibble.visible = true
		_kibble.scale = Vector3.ZERO
		create_tween().tween_property(_kibble, "scale", Vector3.ONE, 0.3) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
