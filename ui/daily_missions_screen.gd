extends Control

signal closed
signal info_requested(title: String, msg: String)

@onready var _dim: ColorRect = $Dim
@onready var _close_x: Button = $CloseX
@onready var _list: VBoxContainer = $MainMargin/MainPanel/Margin/VBox/Scroll/ListHost
@onready var _subtitle: Label = $MainMargin/MainPanel/Margin/VBox/Subtitle
@onready var _close_btn: Button = $MainMargin/MainPanel/Margin/VBox/FooterRow/CloseBtn


func _ready() -> void:
	_close_x.pressed.connect(_on_close)
	_close_btn.pressed.connect(_on_close)
	_dim.gui_input.connect(_on_dim_input)
	hide()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close()


func _daily_missions_node() -> Node:
	var st: SceneTree = get_tree()
	if st == null or st.root == null:
		return null
	return st.root.get_node_or_null("DailyMissions")


func open_missions() -> void:
	var dm: Node = _daily_missions_node()
	if dm != null:
		dm.call("ensure_current_day")
	_subtitle.text = "Resets when the calendar day changes (local time). Claim rewards when a bar fills!"
	_rebuild_list()
	show()


func _on_close() -> void:
	AudioService.play_button_click()
	hide()
	closed.emit()


func _rebuild_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	var dm: Node = _daily_missions_node()
	if dm == null:
		return
	var rows: Variant = dm.call("get_rows_for_ui")
	if rows is Array:
		for row in rows as Array:
			if row is Dictionary:
				_list.add_child(_make_mission_card(row as Dictionary))


func _make_mission_card(d: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.12, 0.1, 0.22, 0.96)
	frame.border_color = Color(0.95, 0.78, 0.35, 0.9)
	frame.set_border_width_all(3)
	frame.corner_radius_top_left = 18
	frame.corner_radius_top_right = 18
	frame.corner_radius_bottom_right = 18
	frame.corner_radius_bottom_left = 18
	frame.shadow_color = Color(0.4, 0.2, 0.65, 0.35)
	frame.shadow_size = 10
	frame.shadow_offset = Vector2(0, 4)
	frame.content_margin_left = 14
	frame.content_margin_top = 12
	frame.content_margin_right = 14
	frame.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", frame)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var title := Label.new()
	title.text = str(d["title"])
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.25, 1))
	title.add_theme_constant_override("outline_size", 5)
	v.add_child(title)
	var desc := Label.new()
	desc.text = str(d["desc"])
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.82, 0.9, 0.98, 1))
	v.add_child(desc)
	var goal: int = int(d["goal"])
	var cur: int = int(d["current"])
	var pct: float = 0.0 if goal <= 0 else clamp(float(cur) / float(goal), 0.0, 1.0)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = pct * 100.0
	bar.custom_minimum_size = Vector2(0, 28)
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.07, 0.14, 1)
	bg.corner_radius_top_left = 10
	bg.corner_radius_top_right = 10
	bg.corner_radius_bottom_right = 10
	bg.corner_radius_bottom_left = 10
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.35, 0.88, 0.58, 1)
	fill.border_color = Color(0.2, 0.55, 0.35, 1)
	fill.set_border_width_all(1)
	fill.corner_radius_top_left = 10
	fill.corner_radius_top_right = 10
	fill.corner_radius_bottom_right = 10
	fill.corner_radius_bottom_left = 10
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	v.add_child(bar)
	var prog_lbl := Label.new()
	if goal == 1:
		prog_lbl.text = "Progress: done!" if cur >= 1 else "Progress: not yet — keep your streak!"
	else:
		prog_lbl.text = "Progress: %d / %d" % [mini(cur, goal), goal]
	prog_lbl.add_theme_font_size_override("font_size", 16)
	prog_lbl.add_theme_color_override("font_color", Color(0.78, 0.86, 1.0, 1))
	v.add_child(prog_lbl)
	var rew := Label.new()
	rew.text = "Reward: %s" % str(d["reward"])
	rew.add_theme_font_size_override("font_size", 15)
	rew.add_theme_color_override("font_color", Color(0.95, 0.75, 1.0, 1))
	v.add_child(rew)
	var claimed: bool = bool(d["claimed"])
	var complete: bool = cur >= goal
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(btn_row)
	var claim := Button.new()
	claim.text = "Claimed ✓" if claimed else ("Claim!" if complete else "Locked")
	claim.disabled = claimed or not complete
	claim.focus_mode = Control.FOCUS_NONE
	claim.custom_minimum_size = Vector2(200, 54)
	claim.add_theme_font_size_override("font_size", 20)
	_style_claim_button(claim, claimed, complete)
	var mid: int = int(d["id"])
	claim.pressed.connect(_on_claim_pressed.bind(mid))
	btn_row.add_child(claim)
	return panel


func _style_claim_button(btn: Button, claimed: bool, complete: bool) -> void:
	var n := StyleBoxFlat.new()
	if claimed:
		n.bg_color = Color(0.22, 0.28, 0.22, 0.95)
		n.border_color = Color(0.5, 0.75, 0.55, 0.8)
	elif complete:
		n.bg_color = Color(0.85, 0.35, 0.55, 1)
		n.border_color = Color(1, 0.92, 0.45, 1)
	else:
		n.bg_color = Color(0.25, 0.22, 0.32, 0.85)
		n.border_color = Color(0.45, 0.42, 0.55, 1)
	n.set_border_width_all(3)
	n.corner_radius_top_left = 16
	n.corner_radius_top_right = 16
	n.corner_radius_bottom_right = 16
	n.corner_radius_bottom_left = 16
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", n)
	btn.add_theme_stylebox_override("pressed", n)
	btn.add_theme_stylebox_override("disabled", n)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.12, 1))
	btn.add_theme_constant_override("outline_size", 4)


func _on_claim_pressed(mission_id: int) -> void:
	AudioService.play_button_click()
	var dm: Node = _daily_missions_node()
	if dm == null:
		return
	var res: Dictionary = dm.call("claim_mission", mission_id) as Dictionary
	if bool(res.get("ok", false)):
		info_requested.emit("Daily reward", str(res.get("msg", "")))
	else:
		info_requested.emit("Daily missions", str(res.get("msg", "Can't claim yet.")))
	_rebuild_list()
