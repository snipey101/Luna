extends Node
## Global score and input setup. Future stats (energy, hunger) belong here.

signal score_changed(score: int, delta: int)
signal won

const TARGET := 10

var score := 0
var has_won := false
## Multiplier for how far away dogs notice Luna. Set by the camera from its
## zoom so dogs react roughly at the screen edge: 1.0 at 100%, 0.75 at 200%.
var range_scale := 1.0


## Halfway between "unchanged" and "shrinks with the view" so close zooms
## still leave room to react.
static func range_scale_for_zoom(zoom: float) -> float:
	return 0.5 + 0.5 / maxf(zoom, 0.1)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()


func reset() -> void:
	score = 0
	has_won = false


## Adds `delta` to the score, never going below zero. Returns the change applied.
func add_score(delta: int) -> int:
	if has_won:
		return 0
	var before := score
	score = maxi(0, score + delta)
	var applied := score - before
	score_changed.emit(score, applied)
	if score >= TARGET:
		has_won = true
		won.emit()
	return applied


func _register_inputs() -> void:
	var actions := {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"sneak": [KEY_SHIFT],
		"bark": [KEY_SPACE],
		"pause": [KEY_ESCAPE],
		"zoom_in": [KEY_EQUAL, KEY_KP_ADD],
		"zoom_out": [KEY_MINUS, KEY_KP_SUBTRACT],
	}
	for action: String in actions:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in actions[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
