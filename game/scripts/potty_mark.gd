class_name PottyMark
extends Node3D
## A cartoon pee puddle or poop swirl that fades away. Pee spots are in the
## "pee_spots" group so timid dogs can find and sniff them.

const PEE := Color("#F2DC6B")
const POOP := Color("#8A5A3B")

var kind := "pee"
var _age := 0.0
var _materials: Array[StandardMaterial3D] = []


static func spawn(parent: Node, mark_kind: String, pos: Vector3) -> PottyMark:
	var m := PottyMark.new()
	m.kind = mark_kind
	m.position = Vector3(pos.x, 0.0, pos.z)
	parent.add_child(m)
	return m


func _ready() -> void:
	if kind == "pee":
		add_to_group("pee_spots")
		_add(_disc(0.42, 0.012), Vector3(0, 0.03, 0), PEE, 0.75)
		_add(_disc(0.22, 0.012), Vector3(0.3, 0.031, 0.15), PEE, 0.75)
	else:
		# Three stacked, shrinking blobs and a little tip: the classic swirl.
		for i in 3:
			var r := 0.17 - i * 0.045
			var blob := SphereMesh.new()
			blob.radius = r
			blob.height = r * 1.2
			_add(blob, Vector3(0, 0.06 + i * 0.075, 0), POOP, 1.0)
		var tip := CylinderMesh.new()
		tip.top_radius = 0.0
		tip.bottom_radius = 0.05
		tip.height = 0.08
		_add(tip, Vector3(0.01, 0.26, 0), POOP, 1.0)
	scale = Vector3.ONE * 0.2
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_age += delta
	var left := GameState.MARK_LIFETIME - _age
	if left <= 0.0:
		queue_free()
	elif left < 3.0:
		for mat in _materials:
			mat.albedo_color.a = minf(mat.albedo_color.a, left / 3.0)


func _disc(radius: float, height: float) -> CylinderMesh:
	var d := CylinderMesh.new()
	d.top_radius = radius
	d.bottom_radius = radius
	d.height = height
	d.radial_segments = 20
	return d


func _add(mesh: Mesh, pos: Vector3, color: Color, alpha: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.4 if kind == "pee" else 0.8
	_materials.append(mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if kind == "pee" \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
