extends Node
## Headless gameplay checks. Run:
##   godot --headless --path game res://tests/test_gameplay.tscn
## Exits with code 0 if everything passes, 1 otherwise.

var main: Node3D
var failures := 0


func _ready() -> void:
	GameState.reset()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	main.camera.set_zoom(2.0)  # don't depend on the player's saved zoom
	await _seconds(0.3)
	await _run()
	print("\n%s (%d failures)" % ["ALL PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(1 if failures else 0)


func _run() -> void:
	var luna: Luna = main.luna
	check(GameState.score == 0, "score starts at 0")
	check(is_equal_approx(GameState.range_scale, 0.75), "notice ranges shrink to 75% at 200% zoom")
	check(main.dogs.size() == 17, "17 dogs spawned (got %d)" % main.dogs.size())
	var befriendable: Array = main.dogs.filter(func(d): return d.personality != Breeds.Personality.AGGRESSIVE)
	check(befriendable.size() >= GameState.TARGET + 3, "enough befriendable dogs to win")

	# Friendly: touch gives +1, only once.
	var friendly: Dog = _first(Breeds.Personality.FRIENDLY)
	await _put_luna_on(friendly)
	check(GameState.score == 1 and friendly.befriended, "touching a friendly dog befriends it (+1)")
	await _seconds(0.5)
	check(GameState.score == 1, "a befriended dog can't be scored twice")
	check(friendly.state == Dog.State.FOLLOW, "befriended dog follows Luna")

	# Aggressive: touch costs a point, never below zero, with cooldown.
	var aggro: Dog = _first(Breeds.Personality.AGGRESSIVE)
	await _put_luna_on(aggro)
	check(GameState.score == 0, "aggressive dog takes a point")
	check(luna.invulnerable > 0.0, "Luna is briefly invulnerable after a hit")
	await _put_luna_on(aggro)
	check(GameState.score == 0, "no double hit while recovering")
	luna.invulnerable = 0.0
	aggro._cooldown = 0.0
	await _put_luna_on(aggro)
	check(GameState.score == 0, "score never goes below zero")
	check(aggro.state in [Dog.State.RETURN, Dog.State.IDLE] and aggro._cooldown > 0.0, "aggressive dog loses interest and goes home")

	# Aggressive chase: Luna inside notice range near its home.
	luna.invulnerable = 99.0
	var aggro2: Dog = main.dogs.filter(func(d): return d.personality == Breeds.Personality.AGGRESSIVE)[1]
	aggro2._cooldown = 0.0
	aggro2._enter(Dog.State.IDLE)
	# Both inside the yard, either side of its home, so no fence is in the way.
	aggro2.global_position = aggro2.home + Vector3(2, 0, 0)
	luna.global_position = aggro2.home - Vector3(2, 0, 0)
	await _seconds(0.5)
	check(aggro2.state == Dog.State.CHASE, "aggressive dog chases nearby Luna")
	var gap_before := aggro2.global_position.distance_to(luna.global_position)
	await _seconds(0.5)
	check(aggro2.global_position.distance_to(luna.global_position) < gap_before - 0.5, "chasing dog closes the gap")
	luna.global_position = aggro2.global_position + Vector3(3, 0, 0)
	luna.bark()
	await _seconds(0.1)
	check(aggro2.state == Dog.State.SCARED and aggro2._cooldown > 0.0, "barking scares off a chasing dog")
	aggro2._cooldown = 0.0
	aggro2._enter(Dog.State.CHASE)
	luna.bark()
	check(aggro2.state == Dog.State.CHASE, "bark has a cooldown (no spamming)")

	# Scared aggressive dogs can be befriended within the window, and not after.
	await _seconds(Luna.BARK_COOLDOWN)
	luna.invulnerable = 0.0
	luna.global_position = aggro2.global_position + Vector3(3, 0, 0)
	luna.bark()
	await _seconds(0.1)
	var before_scared := GameState.score
	await _put_luna_on(aggro2)
	check(aggro2.befriended and GameState.score == before_scared + 1, "a scared aggressive dog can be befriended (+1)")
	check(luna.invulnerable <= 0.0, "a befriended aggressive dog doesn't bite")
	aggro._cooldown = 0.0
	aggro.on_bark(luna)
	aggro._timer = 0.0
	await _seconds(0.1)
	check(aggro.state != Dog.State.SCARED, "the scared window runs out")
	await _put_luna_on(aggro)
	check(not aggro.befriended, "can't befriend once the window has passed")
	luna.invulnerable = 0.0

	# Timid: flees when Luna walks close, not when she sneaks.
	var timids: Array = main.dogs.filter(func(d): return d.personality == Breeds.Personality.TIMID)
	var timid: Dog = timids[0]
	_park_luna()
	timid._enter(Dog.State.IDLE)
	Input.action_press("sneak")
	await _seconds(0.1)
	luna.global_position = _beside(timid, 5.0)
	await _seconds(0.4)
	check(timid.state != Dog.State.FLEE, "timid dog ignores sneaking Luna at 5 m")
	Input.action_release("sneak")
	var start := timid.global_position.distance_to(luna.global_position)
	await _seconds(0.8)
	check(timid.state == Dog.State.FLEE, "timid dog flees walking Luna")
	check(timid.find_children("*", "Label3D", true, false).size() > 0, "a ! pops up when a dog notices Luna")
	check(timid.global_position.distance_to(luna.global_position) > start + 1.0, "timid dog gets further away")
	# Luna keeps chasing (stays ~4 m behind) until it tires.
	for i in int(timid.stats.flee_time * 10.0):
		if timid.state == Dog.State.TIRED:
			break
		var back := luna.global_position - timid.global_position
		back.y = 0
		luna.global_position = timid.global_position + back.normalized() * 4.0
		await _seconds(0.1)
	check(timid.state == Dog.State.TIRED, "timid dog tires after fleeing")
	var before := GameState.score
	var was_befriended := timid.befriended
	await _put_luna_on(timid)
	check(timid.befriended and (was_befriended or GameState.score == before + 1), "tired timid dog can be befriended")

	# Win at TARGET.
	var won := [false]
	GameState.won.connect(func(): won[0] = true)
	GameState.score = GameState.TARGET - 1
	var last: Dog = main.dogs.filter(func(d): return not d.befriended and d.personality != Breeds.Personality.AGGRESSIVE)[0]
	await _put_luna_on(last)
	check(won[0] and GameState.score == GameState.TARGET, "reaching %d wins" % GameState.TARGET)
	await _seconds(2.0)
	check(get_tree().paused, "game pauses on the win screen")
	get_tree().paused = false


func check(ok: bool, msg: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + msg)
	if not ok:
		failures += 1


func _first(p: Breeds.Personality) -> Dog:
	return main.dogs.filter(func(d): return d.personality == p)[0]


func _put_luna_on(dog: Dog) -> void:
	main.luna.global_position = dog.global_position + Vector3(0.3, 0, 0)
	await _seconds(0.1)


func _park_luna() -> void:
	main.luna.global_position = Vector3(0, 0, 0)


func _beside(dog: Dog, dist: float) -> Vector3:
	var dir := (Vector3.ZERO - dog.global_position)
	dir.y = 0
	return dog.global_position + dir.normalized() * dist


func _seconds(t: float) -> void:
	await get_tree().create_timer(t, true, true).timeout
