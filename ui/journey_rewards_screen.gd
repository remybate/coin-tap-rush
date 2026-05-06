extends Control
class_name JourneyRewardsScreen

## Milestone preview every 10 levels (display-only; progress from save furthest unlock).

signal closed

const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SAVE_SECTION: String = "progress"
const KEY_FURTHEST_LEVEL: String = "furthest_level_unlocked"
const KEY_PROGRESSION: String = "saved_progression_level"

@onready var _dim: ColorRect = $Dim
@onready var _list: VBoxContainer = $Center/Panel/Margin/VBox/Scroll/ListHost
@onready var _close_btn: Button = $Center/Panel/Margin/VBox/Footer/CloseBtn
@onready var _subtitle: Label = $Center/Panel/Margin/VBox/Subtitle

var _lock_tex: Texture2D
var _chest_tex: Texture2D


func _ready() -> void:
	_lock_tex = load("res://ui/map_art/lock_map.svg") as Texture2D
	_chest_tex = load("res://ui/map_art/treasure_chest.svg") as Texture2D
	_close_btn.pressed.connect(_on_close)
	_dim.gui_input.connect(_on_dim_input)
	hide()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close()


func open_journey() -> void:
	_refresh_list()
	show()


func _on_close() -> void:
	AudioService.play_button_click()
	hide()
	closed.emit()


func _read_furthest_unlocked() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 1
	var from_f: int = int(cfg.get_value(SAVE_SECTION, KEY_FURTHEST_LEVEL, -1))
	var from_p: int = int(cfg.get_value(SAVE_SECTION, KEY_PROGRESSION, 1))
	return clampi(from_f if from_f > 0 else from_p, 1, 999_999)


func _target_milestone(furthest: int) -> int:
	return mini(999_999, ((furthest + 9) / 10) * 10)


func _reward_bundle(milestone: int) -> Dictionary:
	var tier: int = milestone / 10
	var coins: int = 40 + tier * 30
	var boost: String = ["❄️ +1 freeze", "🌀 +1 slow", "🧲 +1 magnet", "🛡️ +1 shield", "💣 +1 bomb zap", "⏳ +1 start slow"][tier % 6]
	var show_chest: bool = milestone % 30 == 0
	return {"coins": coins, "boost_label": boost, "chest": show_chest}


func _refresh_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	var furthest: int = _read_furthest_unlocked()
	var target: int = _target_milestone(furthest)
	var max_m: int = mini(999_999, maxi(100, ((furthest + 59) / 10) * 10))
	_subtitle.text = "Highest unlocked level: %d  ·  Next milestone: %d" % [furthest, target]
	for m in range(10, max_m + 1, 10):
		_list.add_child(_make_row(m, furthest, target))


func _panel_style(completed: bool, locked: bool, current: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_right = 16
	s.corner_radius_bottom_left = 16
	s.border_width_left = 3
	s.border_width_top = 3
	s.border_width_right = 3
	s.border_width_bottom = 4
	s.shadow_offset = Vector2(0, 4)
	s.shadow_size = 8
	if current:
		s.bg_color = Color(0.22, 0.16, 0.42, 0.98)
		s.border_color = Color(1, 0.88, 0.35, 1)
		s.shadow_color = Color(0.75, 0.45, 0.12, 0.45)
	elif completed:
		s.bg_color = Color(0.12, 0.32, 0.22, 0.95)
		s.border_color = Color(0.45, 0.92, 0.55, 1)
		s.shadow_color = Color(0.05, 0.2, 0.1, 0.35)
	elif locked:
		s.bg_color = Color(0.18, 0.18, 0.24, 0.92)
		s.border_color = Color(0.35, 0.36, 0.42, 1)
		s.shadow_color = Color(0, 0, 0, 0.25)
	else:
		s.bg_color = Color(0.16, 0.14, 0.28, 0.95)
		s.border_color = Color(0.45, 0.42, 0.55, 1)
		s.shadow_color = Color(0, 0, 0, 0.3)
	return s


func _make_row(milestone: int, furthest: int, target: int) -> PanelContainer:
	var completed: bool = furthest > milestone
	var current: bool = (milestone == target) and not completed
	var locked: bool = not completed and not current
	var bundle: Dictionary = _reward_bundle(milestone)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(completed, locked, current))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var status := TextureRect.new()
	status.custom_minimum_size = Vector2(40, 40)
	status.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	status.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if completed:
		var chk := Label.new()
		chk.text = "✓"
		chk.add_theme_font_size_override("font_size", 32)
		chk.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65, 1))
		chk.add_theme_color_override("font_outline_color", Color(0.05, 0.2, 0.08, 1))
		chk.add_theme_constant_override("outline_size", 6)
		chk.custom_minimum_size = Vector2(40, 40)
		chk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(chk)
	elif locked:
		status.texture = _lock_tex
		status.modulate = Color(0.75, 0.78, 0.88, 0.95)
		row.add_child(status)
	else:
		var pulse := Label.new()
		pulse.text = "★"
		pulse.add_theme_font_size_override("font_size", 28)
		pulse.add_theme_color_override("font_color", Color(1, 0.92, 0.45, 1))
		pulse.add_theme_color_override("font_outline_color", Color(0.35, 0.15, 0.05, 1))
		pulse.add_theme_constant_override("outline_size", 5)
		pulse.custom_minimum_size = Vector2(40, 40)
		pulse.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pulse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(pulse)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid)

	var title := Label.new()
	if current:
		title.text = "Level %d — Your journey target" % milestone
	elif completed:
		title.text = "Level %d — Cleared" % milestone
	else:
		title.text = "Level %d — Locked" % milestone
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.98, 0.96, 1, 1))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.18, 1))
	title.add_theme_constant_override("outline_size", 4)
	mid.add_child(title)

	var desc := Label.new()
	desc.text = "Rewards: %d vault coins · %s" % [int(bundle["coins"]), str(bundle["boost_label"])]
	if bool(bundle.get("chest", false)):
		desc.text += " · Bonus treasure cache"
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.82, 0.88, 0.95, 1))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(desc)

	var icons := HBoxContainer.new()
	icons.add_theme_constant_override("separation", 8)
	row.add_child(icons)

	var coin_l := Label.new()
	coin_l.text = "🪙 %d" % int(bundle["coins"])
	coin_l.add_theme_font_size_override("font_size", 18)
	icons.add_child(coin_l)

	if bool(bundle.get("chest", false)) and _chest_tex != null:
		var ch := TextureRect.new()
		ch.texture = _chest_tex
		ch.custom_minimum_size = Vector2(36, 28)
		ch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icons.add_child(ch)

	return panel
