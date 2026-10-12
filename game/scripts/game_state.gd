extends Node
## Global score, Luna's needs (energy, tummy) and input setup.
## All needs tuning lives in the constants below.

signal score_changed(score: int, delta: int)
signal won
signal energy_changed(energy: float)
signal need_changed(need: String)  ## "", "pee" or "poop"

const TARGET := 10

# --- Needs tuning ---------------------------------------------------------
const ENERGY_MAX := 100.0
const ENERGY_LOW := 25.0          ## below this Luna is slower and droopy
const LOW_ENERGY_SPEED := 0.75    ## speed multiplier when low
const DRAIN_IDLE := 0.25          ## energy per second standing still
const DRAIN_SNEAKING := 0.6
const DRAIN_MOVING := 1.2
const DRAIN_BARK := 3.0           ## per bark
const BOWL_COUNT := 6
const BOWL_ENERGY := 40.0
const BOWL_REFILL_TIME := 30.0
const EAT_TIME := 1.0
const BOWLS_TO_PEE := 2
const BOWLS_TO_POOP := 4
const ACCIDENT_TIME := 20.0       ## seconds of ignoring a need before an accident
const POTTY_TIME := 1.4
const MARK_LIFETIME := 20.0       ## puddles and poops fade after this
const LURE_RADIUS := 10.0         ## timid dogs this close come to sniff a pee spot
const SNIFF_TIME := 6.0

var score := 0
var has_won := false
var energy := ENERGY_MAX
var bowls_since_pee := 0
var bowls_since_poop := 0
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
	energy = ENERGY_MAX
	bowls_since_pee = 0
	bowls_since_poop = 0


func change_energy(delta: float) -> void:
	var before := energy
	energy = clampf(energy + delta, 0.0, ENERGY_MAX)
	if energy != before:
		energy_changed.emit(energy)


## What Luna currently needs to do. Poop takes priority over pee.
func need() -> String:
	if bowls_since_poop >= BOWLS_TO_POOP:
		return "poop"
	if bowls_since_pee >= BOWLS_TO_PEE:
		return "pee"
	return ""


func ate_bowl() -> void:
	var before := need()
	change_energy(BOWL_ENERGY)
	bowls_since_pee += 1
	bowls_since_poop += 1
	if need() != before:
		need_changed.emit(need())


func relieved(kind: String) -> void:
	if kind == "poop":
		bowls_since_poop = 0
	else:
		bowls_since_pee = 0
	need_changed.emit(need())


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
		"potty": [KEY_E],
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
