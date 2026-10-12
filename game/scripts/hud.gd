class_name Hud
extends CanvasLayer
## Score counter, controls hint, pause menu and win screen.

signal play_again
signal quit

const CREAM := Color("#FFF7E6")
const BROWN := Color("#7A5230")
const PINK := Color("#FF6F91")

var _score_label: Label
var _score_box: Control
var _hint: Label
var _win_panel: Control
var _pause_panel: Control


class HeartIcon:
	extends Control
	var color := Color("#FF6F91")

	func _draw() -> void:
		var s := size
		var r := s.x * 0.26
		draw_circle(Vector2(s.x * 0.3, s.y * 0.35), r, color)
		draw_circle(Vector2(s.x * 0.7, s.y * 0.35), r, color)
		draw_colored_polygon(PackedVector2Array([
			Vector2(s.x * 0.06, s.y * 0.45), Vector2(s.x * 0.94, s.y * 0.45),
			Vector2(s.x * 0.5, s.y * 0.92)]), color)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_score()
	_build_hint()
	_win_panel = _build_panel("Luna made 10 friends!", "What a good girl. Every dog in the park loves her.",
			[["Play Again", func(): play_again.emit()], ["Quit", func(): quit.emit()]])
	_pause_panel = _build_panel("Paused", "WASD move  ·  Shift sneak  ·  Space bark  ·  Wheel or +/- zoom",
			[["Resume", func(): set_paused(false)], ["Quit", func(): quit.emit()]])
	GameState.score_changed.connect(_on_score_changed)
	_on_score_changed(GameState.score, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not _win_panel.visible:
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func set_paused(p: bool) -> void:
	get_tree().paused = p
	_pause_panel.visible = p


func show_win() -> void:
	_win_panel.visible = true
	_win_panel.modulate.a = 0.0
	create_tween().tween_property(_win_panel, "modulate:a", 1.0, 0.4)


func _on_score_changed(score: int, delta: int) -> void:
	_score_label.text = "%d / %d" % [score, GameState.TARGET]
	if delta != 0:
		_score_box.pivot_offset = _score_box.size / 2.0
		var tw := create_tween()
		tw.tween_property(_score_box, "scale", Vector2.ONE * (1.2 if delta > 0 else 0.85), 0.08)
		tw.tween_property(_score_box, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)


func _style(bg: Color, radius: int, border := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border)
	sb.border_color = BROWN
	sb.set_content_margin_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.15)
	sb.shadow_size = 6
	return sb


func _build_score() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(CREAM, 22))
	panel.position = Vector2(20, 20)
	add_child(panel)
	_score_box = panel
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var heart := HeartIcon.new()
	heart.custom_minimum_size = Vector2(40, 40)
	row.add_child(heart)
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 34)
	_score_label.add_theme_color_override("font_color", BROWN)
	row.add_child(_score_label)


func _build_hint() -> void:
	_hint = Label.new()
	_hint.text = "WASD move  ·  Shift sneak  ·  Space bark  ·  Make 10 friends!"
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", BROWN)
	_hint.add_theme_color_override("font_outline_color", CREAM)
	_hint.add_theme_constant_override("outline_size", 8)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_top = -60
	_hint.offset_bottom = -24
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)
	var tw := create_tween()
	tw.tween_interval(10.0)
	tw.tween_property(_hint, "modulate:a", 0.0, 1.5)


func _build_panel(title: String, body: String, buttons: Array) -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0.2, 0.15, 0.1, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	var sb := _style(CREAM, 32, 6)
	sb.set_content_margin_all(36)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	panel.add_child(col)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 44)
	t.add_theme_color_override("font_color", PINK)
	t.add_theme_color_override("font_outline_color", BROWN)
	t.add_theme_constant_override("outline_size", 6)
	col.add_child(t)
	var b := Label.new()
	b.text = body
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", BROWN)
	col.add_child(b)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	col.add_child(row)
	for spec in buttons:
		var btn := Button.new()
		btn.text = spec[0]
		btn.custom_minimum_size = Vector2(170, 56)
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_color_override("font_color", BROWN)
		btn.add_theme_color_override("font_hover_color", BROWN)
		btn.add_theme_color_override("font_pressed_color", BROWN)
		btn.add_theme_color_override("font_focus_color", BROWN)
		btn.add_theme_stylebox_override("normal", _style(Color("#FFE3A3"), 18))
		btn.add_theme_stylebox_override("hover", _style(Color("#FFD47A"), 18))
		btn.add_theme_stylebox_override("pressed", _style(Color("#F5C060"), 18))
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.pressed.connect(spec[1])
		row.add_child(btn)
	return dim
