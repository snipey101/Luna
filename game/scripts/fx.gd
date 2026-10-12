class_name Fx
## Small visual effects shared across scripts.

const BUBBLE_FILL := Color("#FFFDF7")
const BUBBLE_EDGE := Color("#7A5230")
const FONT_SIZE := 96
const PIXEL := 0.0055  ## world metres per font pixel at scale 1


## Speech bubble with coloured text, popping in above `pos` (the tail tip),
## in `parent`'s space. Parent it to the speaker so it follows them.
## `rise` drifts it upwards; `hold` is how long it stays before fading.
static func speech_bubble(parent: Node, text: String, color: Color, pos: Vector3,
		scale_f := 1.0, rise := 0.35, hold := 0.7) -> Node3D:
	var px := PIXEL * scale_f
	var font: Font = ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE) * px
	var text_h := font.get_height(FONT_SIZE) * px * 0.78
	var pad := Vector2(0.16, 0.08) * scale_f
	var size := Vector2(maxf(text_size.x + pad.x * 2.0, text_h + pad.y * 2.0), text_h + pad.y * 2.0)
	var tail_h := 0.16 * scale_f
	var centre_y := tail_h + size.y / 2.0

	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ZERO

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.render_priority = 10
	var bubble := MeshInstance3D.new()
	bubble.mesh = _bubble_mesh(size, centre_y, tail_h, 0.045 * scale_f)
	bubble.material_override = mat
	bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(bubble)

	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = FONT_SIZE
	label.outline_size = 0
	label.pixel_size = px
	label.modulate = color
	label.render_priority = 11
	# Offset in billboard (screen) space so it stays centred on the bubble.
	label.offset = Vector2(0, centre_y / px)
	root.add_child(label)
	parent.add_child(root)

	var tw := root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if rise > 0.0:
		tw.parallel().tween_property(root, "position:y", pos.y + rise, 0.2 + hold + 0.3) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.3)
	tw.tween_callback(root.queue_free)
	return root


## Short-lived bubble that drifts up, used for score changes and barks.
static func popup(parent: Node, text: String, color: Color, pos: Vector3, scale_f := 1.0) -> void:
	speech_bubble(parent, text, color, pos, scale_f)


## Rounded-rectangle bubble with a tail, in the XY plane, tail tip at the
## origin. Drawn as an outline layer then a fill layer (no depth test, so
## triangle order decides what's on top).
static func _bubble_mesh(size: Vector2, centre_y: float, tail_h: float, edge: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Vector2(0, centre_y)
	var tail_x := -size.x * 0.12
	for layer in 2:
		var grow := edge if layer == 0 else 0.0
		var col := BUBBLE_EDGE if layer == 0 else BUBBLE_FILL
		var half := size / 2.0 + Vector2(grow, grow)
		var r := minf(half.y, half.x) * 0.9
		var pts := _rounded_rect(c, half, r)
		for i in pts.size():
			_tri(st, col, c, pts[i], pts[(i + 1) % pts.size()])
		# Tail: from the bubble's bottom edge down to the tip at the origin.
		var base_y := c.y - half.y + 0.02
		var tw := 0.11 * size.y / 0.5 + grow
		var tip := Vector2(0, 0) + Vector2(0, -grow * 1.2)
		_tri(st, col, Vector2(tail_x - tw, base_y + 0.04), Vector2(tail_x + tw, base_y + 0.04), tip)
	return st.commit()


static func _rounded_rect(c: Vector2, half: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(half.x - r, half.y - r), 0.0],
		[Vector2(-half.x + r, half.y - r), PI / 2.0],
		[Vector2(-half.x + r, -half.y + r), PI],
		[Vector2(half.x - r, -half.y + r), PI * 1.5],
	]
	for corner in corners:
		for i in 7:
			var a: float = corner[1] + PI / 2.0 * i / 6.0
			pts.append(c + corner[0] + Vector2(cos(a), sin(a)) * r)
	return pts


static func _tri(st: SurfaceTool, col: Color, a: Vector2, b: Vector2, d: Vector2) -> void:
	for p in [a, b, d]:
		st.set_color(col)
		st.add_vertex(Vector3(p.x, p.y, 0))
