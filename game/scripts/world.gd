class_name World
extends Node3D
## Builds the play area in code: sandy ground, fenced grass yards and gardens,
## a tree border, scattered props and a baked navmesh for the dogs.

const HALF := 30.0
const SAND := Color("#E8D2A2")
const SAND_DARK := Color("#E2CA98")
const SAND_LIGHT := Color("#ECD8AC")
const TUFT := Color("#A8CF7A")
const GRASS := Color("#9BD372")
const GRASS_OUTER := Color("#8CC765")

const FENCE := preload("res://assets/models/fence.glb")
const TREE_ROUND := preload("res://assets/models/tree_round.glb")
const TREE_PINE := preload("res://assets/models/tree_pine.glb")
const BUSH := preload("res://assets/models/bush.glb")
const ROCK := preload("res://assets/models/rock.glb")
const FLOWERS := preload("res://assets/models/flowers.glb")

## Fenced grass areas. Yards have a gate and are home to aggressive dogs;
## gardens are closed and just act as obstacles.
const YARDS := [
	{"rect": Rect2(-22, -20, 12, 10), "gate": "+z"},
	{"rect": Rect2(10, 10, 12, 10), "gate": "-z"},
]
## Unfenced grass lawns out on the sand: nice spots for Luna to go potty.
## [centre x, centre z, radius]
const LAWNS := [[6.0, 6.0, 3.0], [-12.0, 0.0, 3.5], [2.0, -12.0, 3.0], [20.0, 0.0, 3.0]]
const GARDENS := [
	{"rect": Rect2(10, -20, 10, 8), "gate": ""},
	{"rect": Rect2(-20, 10, 10, 8), "gate": ""},
]

var nav_region: NavigationRegion3D
var _blocked: Array = []  # [Vector2 centre, radius]
var _rng := RandomNumberGenerator.new()


func build(seed_value: int) -> void:
	_rng.seed = seed_value
	nav_region = NavigationRegion3D.new()
	var nm := NavigationMesh.new()
	nm.agent_radius = 0.5
	nm.agent_height = 1.0
	nm.agent_max_climb = 0.25
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nav_region.navigation_mesh = nm
	add_child(nav_region)

	_build_ground()
	for area in YARDS + GARDENS:
		_build_fenced_area(area.rect, area.gate)
	_build_lawns()
	_build_border()
	_decorate_gardens()
	_add_ground_detail()
	_scatter_props()
	nav_region.bake_navigation_mesh(false)


func yard_homes() -> Array[Vector3]:
	var homes: Array[Vector3] = []
	for y in YARDS:
		var c: Vector2 = y.rect.get_center()
		homes.append(Vector3(c.x, 0, c.y))
	return homes


## True if a point (x, z) is open sand: inside the bounds, outside every
## fenced area and clear of props.
func is_free(p: Vector2, margin := 0.8) -> bool:
	if absf(p.x) > HALF - margin - 1.0 or absf(p.y) > HALF - margin - 1.0:
		return false
	for area in YARDS + GARDENS:
		if (area.rect as Rect2).grow(margin).has_point(p):
			return false
	for b in _blocked:
		if p.distance_to(b[0]) < b[1] + margin:
			return false
	return true


## True on grass Luna can reach: the yards and the open lawns.
func is_grass(p: Vector2) -> bool:
	if in_yard(p):
		return true
	for l in LAWNS:
		if p.distance_to(Vector2(l[0], l[1])) <= l[2]:
			return true
	return false


func in_yard(p: Vector2) -> bool:
	for y in YARDS:
		if (y.rect as Rect2).has_point(p):
			return true
	return false


func random_free_point(rng: RandomNumberGenerator, avoid: Vector2, avoid_radius: float) -> Vector2:
	for i in 200:
		var p := Vector2(rng.randf_range(-HALF, HALF), rng.randf_range(-HALF, HALF))
		if is_free(p, 1.0) and p.distance_to(avoid) > avoid_radius:
			return p
	return Vector2(avoid.x + avoid_radius, avoid.y)


# --- construction -----------------------------------------------------------

func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(HALF * 2 + 4, 1, HALF * 2 + 4)
	col.shape = shape
	col.position.y = -0.5
	body.add_child(col)
	nav_region.add_child(body)

	_flat_box(Vector3(160, 0.1, 160), Vector3(0, -0.06, 0), GRASS_OUTER, self)
	_flat_box(Vector3(HALF * 2 + 2, 0.1, HALF * 2 + 2), Vector3(0, -0.04, 0), SAND, self)

	# Invisible walls keep everyone inside the tree line.
	for side in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var wall := StaticBody3D.new()
		var wc := CollisionShape3D.new()
		var ws := BoxShape3D.new()
		ws.size = Vector3(1 if side.x != 0 else HALF * 2 + 2, 3, 1 if side.z != 0 else HALF * 2 + 2)
		wc.shape = ws
		wall.add_child(wc)
		wall.position = side * (HALF + 0.5) + Vector3(0, 1.5, 0)
		nav_region.add_child(wall)


## Soft sand patches and little grass tufts so the ground isn't one flat colour.
func _add_ground_detail() -> void:
	for i in 40:
		var p := Vector2(_rng.randf_range(-HALF, HALF), _rng.randf_range(-HALF, HALF))
		var mi := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		var r := _rng.randf_range(1.2, 3.5)
		disc.top_radius = r
		disc.bottom_radius = r
		disc.height = 0.02
		disc.radial_segments = 20
		var mat := StandardMaterial3D.new()
		mat.albedo_color = SAND_DARK if i % 2 == 0 else SAND_LIGHT
		mat.roughness = 1.0
		disc.material = mat
		mi.mesh = disc
		mi.position = Vector3(p.x, 0.012 + i * 0.0002, p.y)
		mi.scale = Vector3(_rng.randf_range(0.8, 1.6), 1, _rng.randf_range(0.8, 1.6))
		mi.rotation.y = _rng.randf() * TAU
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)

	var tuft := CylinderMesh.new()
	tuft.top_radius = 0.0
	tuft.bottom_radius = 0.07
	tuft.height = 0.3
	tuft.radial_segments = 4
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = TUFT
	tuft.material = tmat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = tuft
	mm.instance_count = 150 * 3
	for i in 150:
		var c := Vector2(_rng.randf_range(-HALF, HALF), _rng.randf_range(-HALF, HALF))
		for j in 3:
			var basis := Basis(Vector3.FORWARD, _rng.randf_range(-0.35, 0.35)).scaled(Vector3.ONE * _rng.randf_range(0.7, 1.2))
			var off := Vector3(_rng.randf_range(-0.12, 0.12), 0.13, _rng.randf_range(-0.12, 0.12))
			mm.set_instance_transform(i * 3 + j, Transform3D(basis, Vector3(c.x, 0, c.y) + off))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _flat_box(size: Vector3, pos: Vector3, color: Color, parent: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi


func _build_lawns() -> void:
	for l in LAWNS:
		var mi := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = l[2]
		disc.bottom_radius = l[2]
		disc.height = 0.06
		disc.radial_segments = 28
		var mat := StandardMaterial3D.new()
		mat.albedo_color = GRASS
		mat.roughness = 1.0
		disc.material = mat
		mi.mesh = disc
		mi.position = Vector3(l[0], 0.0, l[1])
		add_child(mi)
		for i in 3:
			var a := _rng.randf() * TAU
			var p := Vector3(l[0], 0.02, l[1]) + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(0.5, l[2] - 0.6)
			_place(FLOWERS, p, _rng.randf_range(1.0, 1.5), false)


func _build_fenced_area(rect: Rect2, gate: String) -> void:
	var c := rect.get_center()
	_flat_box(Vector3(rect.size.x, 0.06, rect.size.y), Vector3(c.x, 0.0, c.y), GRASS, self)
	var x0 := rect.position.x
	var z0 := rect.position.y
	var x1 := rect.end.x
	var z1 := rect.end.y
	_fence_line(Vector3(x0, 0, z0), Vector3(x1, 0, z0), gate == "-z")
	_fence_line(Vector3(x0, 0, z1), Vector3(x1, 0, z1), gate == "+z")
	_fence_line(Vector3(x0, 0, z0), Vector3(x0, 0, z1), gate == "-x")
	_fence_line(Vector3(x1, 0, z0), Vector3(x1, 0, z1), gate == "+x")


## Fence segments are 2 m long; a gated line leaves its middle 4 m open.
func _fence_line(a: Vector3, b: Vector3, gated: bool) -> void:
	var dir := (b - a).normalized()
	var n := int(round(a.distance_to(b) / 2.0))
	var yaw := atan2(-dir.z, dir.x)
	var mid := n / 2
	for i in n:
		if gated and (i == mid or i == mid - 1):
			continue
		var start := a + dir * 2.0 * i
		var seg: Node3D = FENCE.instantiate()
		seg.position = start
		seg.rotation.y = yaw
		add_child(seg)
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(2.0, 1.0, 0.25)
		col.shape = shape
		body.add_child(col)
		body.position = start + dir + Vector3(0, 0.5, 0)
		body.rotation.y = yaw
		nav_region.add_child(body)


func _build_border() -> void:
	for side in 4:
		var t := -HALF - 4.0
		while t < HALF + 4.0:
			for row in 2:
				var depth := HALF + 1.8 + row * 2.6 + _rng.randf_range(-0.4, 0.6)
				var along := t + row * 1.3 + _rng.randf_range(-0.5, 0.5)
				var pos := Vector3(along, 0, depth) if side < 2 else Vector3(depth, 0, along)
				if side % 2 == 1:
					pos = -pos
				_place(TREE_PINE if _rng.randf() < 0.45 else TREE_ROUND, pos,
						_rng.randf_range(0.9, 1.35), false)
			t += 2.6


func _decorate_gardens() -> void:
	for g in GARDENS:
		var r: Rect2 = g.rect
		var c := r.get_center()
		_place(TREE_ROUND, Vector3(c.x - r.size.x * 0.2, 0, c.y), 1.1, true, 0.35)
		for i in 7:
			var p := Vector2(_rng.randf_range(r.position.x + 0.8, r.end.x - 0.8),
					_rng.randf_range(r.position.y + 0.8, r.end.y - 0.8))
			_place(FLOWERS, Vector3(p.x, 0.02, p.y), _rng.randf_range(1.0, 1.6), false)
		_place(BUSH, Vector3(c.x + r.size.x * 0.28, 0, c.y + 1.5), 1.0, false)
	for y in YARDS:
		var r: Rect2 = y.rect
		_place(BUSH, Vector3(r.position.x + 1.2, 0, r.position.y + 1.2), 0.9, false)
		_place(ROCK, Vector3(r.end.x - 1.5, 0, r.position.y + 1.5), 1.0, false)


func _scatter_props() -> void:
	var specs := [
		[TREE_ROUND, 5, 0.35, 1.0, true],
		[BUSH, 9, 0.75, 1.0, true],
		[ROCK, 7, 0.55, 1.0, true],
	]
	for spec in specs:
		var placed := 0
		var tries := 0
		while placed < spec[1] and tries < 400:
			tries += 1
			var p := Vector2(_rng.randf_range(-HALF + 3, HALF - 3), _rng.randf_range(-HALF + 3, HALF - 3))
			if p.length() < 6.0 or not is_free(p, 2.5):
				continue
			var s := _rng.randf_range(0.85, 1.25)
			_place(spec[0], Vector3(p.x, 0, p.y), s, spec[4], spec[2] * s)
			placed += 1
	# Flowers are walk-through decoration.
	for i in 30:
		var p := Vector2(_rng.randf_range(-HALF + 2, HALF - 2), _rng.randf_range(-HALF + 2, HALF - 2))
		if is_free(p, 0.6):
			_place(FLOWERS, Vector3(p.x, 0, p.y), _rng.randf_range(1.0, 1.8), false)


func _place(scene: PackedScene, pos: Vector3, scale_f: float, solid: bool,
		radius := 0.0) -> void:
	var inst: Node3D = scene.instantiate()
	inst.position = pos
	inst.rotation.y = _rng.randf() * TAU
	inst.scale = Vector3.ONE * scale_f
	add_child(inst)
	if solid:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = 1.5
		col.shape = shape
		body.add_child(col)
		body.position = pos + Vector3(0, 0.75, 0)
		nav_region.add_child(body)
		_blocked.append([Vector2(pos.x, pos.z), radius])
