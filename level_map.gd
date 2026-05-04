extends Control

const HOME_SCENE: String = "res://main_menu.tscn"
const GAME_SCENE: String = "res://game.tscn"
const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SAVE_SECTION: String = "progress"
const KEY_SAVED_SCORE: String = "saved_score"
const KEY_PROGRESSION: String = "saved_progression_level"
const MAX_LIVES_DISPLAY: int = 5

@export var level_spacing: float = 108.0
@export var path_wave_amplitude: float = 86.0
@export var path_wave_frequency: float = 0.62
@export var map_top_padding: float = 64.0

@onready var _map_scroll: ScrollContainer = $MapScroll
@onready var _map_root: Control = $MapScroll/Margin/MapRoot
@onready var _background_layer: Control = $MapScroll/Margin/MapRoot/BackgroundLayer
@onready var _path_drawer: MapPathDrawer = $MapScroll/Margin/MapRoot/PathDrawer
@onready var _path_tile_layer: Control = $MapScroll/Margin/MapRoot/PathTileLayer
@onready var _decor_layer: Control = $MapScroll/Margin/MapRoot/DecorLayer
@onready var _ambience: LevelMapAmbience = $MapScroll/Margin/MapRoot/AmbienceHost
@onready var _levels_layer: Control = $MapScroll/Margin/MapRoot/LevelsLayer
@onready var _main_play: Button = $MainPlayButton
@onready var _coin_value: Label = $TopBar/HBox/CoinPill/Margin/HBox/CoinValue
@onready var _lives_value: Label = $TopBar/HBox/LivesPill/Margin/HBox/LivesValue
@onready var _settings_btn: Button = $TopBar/HBox/SettingsBtn
@onready var _stub: AcceptDialog = $StubDialog
@onready var _settings_layer: SettingsScreen = $SettingsLayer

var _furthest_level: int = 1
var _selected_level: int = 1
var _display_levels: int = 24
var _node_center_x: float = 260.0
var _level_centers: Array[Vector2] = []
var _pulse_btn: Button = null
var _pulse_t: float = 0.0
var _sway_nodes: Array[TextureRect] = []


func _ready() -> void:
	set_process(false)
	_settings_layer.visible = false
	_load_save_summary()
	_selected_level = _furthest_level
	_display_levels = clampi(maxi(18, _furthest_level + 4), 12, 72)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_main_play.pressed.connect(_on_main_play_pressed)
	call_deferred("_deferred_build_map")


func _process(delta: float) -> void:
	_pulse_t += delta
	if _pulse_btn != null and is_instance_valid(_pulse_btn):
		var s: float = 1.0 + 0.024 * sin(_pulse_t * 2.05)
		_pulse_btn.pivot_offset = _pulse_btn.size * 0.5
		_pulse_btn.scale = Vector2(s, s)
	for tr in _sway_nodes:
		if is_instance_valid(tr) and tr.has_meta(&"sway_ph"):
			var ph: float = float(tr.get_meta(&"sway_ph"))
			tr.rotation_degrees = sin(_pulse_t * 0.95 + ph) * 1.15


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and is_node_ready():
		_refresh_hud()


func _deferred_build_map() -> void:
	_build_visual_map()
	_refresh_hud()
	_update_main_play_label()
	_scroll_to_selected()
	set_process(_pulse_btn != null or not _sway_nodes.is_empty())


func _load_save_summary() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		_furthest_level = 1
		return
	_furthest_level = clampi(int(cfg.get_value(SAVE_SECTION, KEY_PROGRESSION, 1)), 1, 999_999)


func _refresh_hud() -> void:
	if _coin_value == null or _lives_value == null:
		return
	var cfg := ConfigFile.new()
	var coins: int = 0
	if cfg.load(SAVE_PATH) == OK:
		coins = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_SAVED_SCORE, 0)))
	_coin_value.text = str(coins)
	_lives_value.text = str(MAX_LIVES_DISPLAY)


func _map_content_width() -> float:
	var w: float = _map_scroll.size.x - 32.0
	if w < 120.0:
		w = get_viewport_rect().size.x - 184.0
	return maxf(300.0, w)


func _make_gradient_tex(width_px: int, height_px: int, colors: PackedColorArray, offsets: PackedFloat32Array) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.colors = colors
	grad.offsets = offsets
	var gtx := GradientTexture2D.new()
	gtx.gradient = grad
	gtx.width = maxi(4, width_px)
	gtx.height = maxi(32, height_px)
	gtx.fill_from = Vector2(0.5, 0)
	gtx.fill_to = Vector2(0.5, 1)
	return gtx


func _build_background_layers(w: float, total_h: float) -> void:
	for c in _background_layer.get_children():
		c.queue_free()

	var sky_h: float = total_h * 0.42
	var sky := TextureRect.new()
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.texture = _make_gradient_tex(
		int(w),
		int(sky_h),
		PackedColorArray([Color(0.55, 0.78, 1.0, 1), Color(0.42, 0.55, 0.98, 1), Color(0.55, 0.35, 0.92, 0.35)]),
		PackedFloat32Array([0.0, 0.45, 1.0])
	)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.position = Vector2.ZERO
	sky.size = Vector2(w, sky_h)
	_background_layer.add_child(sky)

	var band := ColorRect.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.color = Color(0.28, 0.62, 0.38, 0.55)
	band.position = Vector2(0, sky_h * 0.55)
	band.size = Vector2(w, total_h * 0.12)
	_background_layer.add_child(band)

	var ground := ColorRect.new()
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.color = Color(0.12, 0.48, 0.28, 1)
	ground.position = Vector2(0, total_h * 0.3)
	ground.size = Vector2(w, total_h * 0.72)
	_background_layer.add_child(ground)

	var stripe_y: float = total_h * 0.32
	for k in range(5):
		var stripe := ColorRect.new()
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stripe.color = Color(0.18, 0.58, 0.32, 0.22 + float(k) * 0.04)
		stripe.position = Vector2(0, stripe_y + float(k) * 70.0)
		stripe.size = Vector2(w, 26.0)
		_background_layer.add_child(stripe)

	var hill := ColorRect.new()
	hill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hill.color = Color(0.1, 0.42, 0.24, 0.88)
	hill.position = Vector2(-40, total_h * 0.26)
	hill.size = Vector2(w + 80, total_h * 0.14)
	hill.rotation_degrees = -1.2
	_background_layer.add_child(hill)


func _place_path_tiles_on_curve(pts: PackedVector2Array) -> void:
	for c in _path_tile_layer.get_children():
		c.queue_free()
	var tex: Texture2D = load("res://ui/map_art/path_tile.svg") as Texture2D
	if tex == null or pts.size() < 2:
		return
	var step_px: float = 26.0
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var dist: float = a.distance_to(b)
		var steps: int = maxi(1, int(dist / step_px))
		for s in range(steps):
			var t: float = float(s) / float(steps)
			var p: Vector2 = a.lerp(b, t)
			var ang: float = (b - a).angle()
			var tr := TextureRect.new()
			tr.texture = tex
			tr.custom_minimum_size = Vector2(44, 44)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.pivot_offset = Vector2(22, 22)
			tr.rotation = ang
			tr.position = p - Vector2(22, 22)
			tr.modulate = Color(1.05, 0.98, 0.82, 0.92)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_path_tile_layer.add_child(tr)
			var sh := TextureRect.new()
			sh.texture = tex
			sh.custom_minimum_size = Vector2(44, 44)
			sh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sh.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sh.pivot_offset = Vector2(22, 22)
			sh.rotation = ang
			sh.position = p - Vector2(20, 18)
			sh.modulate = Color(0.2, 0.12, 0.08, 0.35)
			sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sh.z_index = -1
			_path_tile_layer.add_child(sh)


func _add_sway_tex(tr: TextureRect, phase: float) -> void:
	tr.set_meta(&"sway_ph", phase)
	_sway_nodes.append(tr)


func _place_world_props(pts: PackedVector2Array, w: float, total_h: float) -> void:
	var bush: Texture2D = load("res://ui/map_art/bush.svg") as Texture2D
	var chest: Texture2D = load("res://ui/map_art/treasure_chest.svg") as Texture2D
	var coin_s: Texture2D = load("res://ui/map_art/coin_small.svg") as Texture2D
	var lantern: Texture2D = load("res://ui/map_art/lantern.svg") as Texture2D
	var stone: Texture2D = load("res://ui/map_art/stone.svg") as Texture2D
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(int(w), int(total_h))) + pts.size()

	for i in range(pts.size()):
		var p: Vector2 = pts[i]
		var ph: float = rng.randf() * TAU

		if i % 2 == 0 and bush != null:
			var b := TextureRect.new()
			b.texture = bush
			b.custom_minimum_size = Vector2(64, 50)
			b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			b.position = p + Vector2(-rng.randf_range(92, 118), -18 + rng.randf_range(-6, 10))
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_decor_layer.add_child(b)
			_add_sway_tex(b, ph)

		if i % 3 == 1 and chest != null:
			var ch := TextureRect.new()
			ch.texture = chest
			ch.custom_minimum_size = Vector2(56, 44)
			ch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ch.position = p + Vector2(rng.randf_range(68, 100), 4)
			ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_decor_layer.add_child(ch)

		if i % 4 == 0 and coin_s != null:
			for k in range(3):
				var c := TextureRect.new()
				c.texture = coin_s
				c.custom_minimum_size = Vector2(22, 22)
				c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				c.position = p + Vector2(-rng.randf_range(48, 72) + float(k) * 6, 22 + float(k) * 4)
				c.mouse_filter = Control.MOUSE_FILTER_IGNORE
				c.modulate = Color(1, 0.95, 0.55, 0.9)
				_decor_layer.add_child(c)

		if i % 6 == 2 and lantern != null:
			var L := TextureRect.new()
			L.texture = lantern
			L.custom_minimum_size = Vector2(36, 46)
			L.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			L.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			L.position = p + Vector2(rng.randf_range(88, 112), -36)
			L.mouse_filter = Control.MOUSE_FILTER_IGNORE
			L.modulate = Color(1.1, 1.05, 0.85, 1)
			_decor_layer.add_child(L)
			_add_sway_tex(L, ph + 1.3)

		if i % 5 == 3 and stone != null:
			var st := TextureRect.new()
			st.texture = stone
			st.custom_minimum_size = Vector2(32, 26)
			st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			st.position = p + Vector2(rng.randf_range(-110, -70), 28)
			st.mouse_filter = Control.MOUSE_FILTER_IGNORE
			st.modulate = Color(0.9, 0.92, 1, 0.75)
			_decor_layer.add_child(st)

	# A few extra sparkles as static sprites (animated alpha handled in AmbienceHost)
	var spark_tex: Texture2D = load("res://ui/map_art/sparkle.svg") as Texture2D
	if spark_tex != null:
		for _j in range(8):
			var sp := TextureRect.new()
			sp.texture = spark_tex
			sp.custom_minimum_size = Vector2(18, 18)
			sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sp.position = Vector2(rng.randf_range(8, w - 24), rng.randf_range(40, total_h - 60))
			sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sp.modulate = Color(1, 1, 1, 0.4)
			_decor_layer.add_child(sp)


func _build_visual_map() -> void:
	_pulse_btn = null
	_sway_nodes.clear()
	for c in _background_layer.get_children():
		c.queue_free()
	for c in _path_tile_layer.get_children():
		c.queue_free()
	for c in _decor_layer.get_children():
		c.queue_free()
	_ambience.clear_all()
	for c in _levels_layer.get_children():
		c.queue_free()
	_level_centers.clear()

	var w: float = _map_content_width()
	_node_center_x = w * 0.5
	var total_h: float = map_top_padding + float(_display_levels) * level_spacing + 240.0
	_map_root.custom_minimum_size = Vector2(w, total_h)

	var pts: PackedVector2Array = []
	for i in range(_display_levels):
		var t: float = float(i)
		var y: float = map_top_padding + t * level_spacing
		var x: float = _node_center_x + sin(t * path_wave_frequency) * path_wave_amplitude
		var p := Vector2(x, y)
		pts.append(p)
		_level_centers.append(p)

	_build_background_layers(w, total_h)
	_path_drawer.set_path_points(pts)
	_place_path_tiles_on_curve(pts)
	_place_world_props(pts, w, total_h)
	_ambience.build(w, total_h, pts)

	for i in range(_display_levels):
		var lv: int = i + 1
		var pos: Vector2 = _level_centers[i]
		var btn := Button.new()
		btn.text = str(lv)
		btn.custom_minimum_size = Vector2(76, 76)
		btn.position = pos - btn.custom_minimum_size * 0.5
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_level_button_style(btn, lv)
		btn.pressed.connect(_on_level_node_pressed.bind(lv))
		_levels_layer.add_child(btn)
		if lv == _furthest_level:
			_pulse_btn = btn


func _apply_level_button_style(btn: Button, lv: int) -> void:
	var state: String = "locked"
	if lv < _furthest_level:
		state = "done"
	elif lv == _furthest_level:
		state = "current"
	btn.disabled = state == "locked"
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.22, 1))
	btn.add_theme_constant_override("outline_size", 6)

	var n := StyleBoxFlat.new()
	var h := StyleBoxFlat.new()
	var p := StyleBoxFlat.new()
	for s in [n, h, p]:
		s.corner_radius_top_left = 99
		s.corner_radius_top_right = 99
		s.corner_radius_bottom_right = 99
		s.corner_radius_bottom_left = 99
		s.shadow_color = Color(0, 0, 0, 0.32)
		s.shadow_size = 5
		s.shadow_offset = Vector2(0, 3)

	match state:
		"locked":
			n.bg_color = Color(0.42, 0.44, 0.52, 1)
			n.border_color = Color(0.28, 0.3, 0.36, 1)
			h.bg_color = Color(0.48, 0.5, 0.58, 1)
			p.bg_color = Color(0.36, 0.38, 0.46, 1)
		"done":
			n.bg_color = Color(0.28, 0.78, 0.48, 1)
			n.border_color = Color(0.1, 0.45, 0.22, 1)
			h.bg_color = Color(0.34, 0.88, 0.55, 1)
			p.bg_color = Color(0.22, 0.62, 0.38, 1)
			n.shadow_size = 7
			n.shadow_color = Color(0.05, 0.25, 0.1, 0.45)
		"current":
			n.bg_color = Color(1, 0.86, 0.32, 1)
			n.border_color = Color(0.55, 0.25, 0.95, 1)
			h.bg_color = Color(1, 0.92, 0.48, 1)
			p.bg_color = Color(0.92, 0.72, 0.2, 1)
			n.shadow_size = 12
			n.shadow_color = Color(0.75, 0.45, 1.0, 0.55)
			h.shadow_size = 10
			h.shadow_color = Color(0.85, 0.55, 1.0, 0.4)

	if state == "current":
		for s in [n, h, p]:
			s.border_width_left = 5
			s.border_width_top = 5
			s.border_width_right = 5
			s.border_width_bottom = 5
	else:
		for s in [n, h, p]:
			s.border_width_left = 3
			s.border_width_top = 3
			s.border_width_right = 3
			s.border_width_bottom = 3

	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	if state == "locked":
		var d := n.duplicate() as StyleBoxFlat
		d.bg_color = Color(0.38, 0.4, 0.48, 0.72)
		btn.add_theme_stylebox_override("disabled", d)
		btn.add_theme_color_override("font_color", Color(0.88, 0.88, 0.92, 0.65))


func _on_level_node_pressed(lv: int) -> void:
	if lv > _furthest_level:
		return
	_selected_level = lv
	_update_main_play_label()
	_refresh_all_level_styles()
	AudioService.play_button_click()
	_start_gameplay()


func _refresh_all_level_styles() -> void:
	var idx := 0
	for child in _levels_layer.get_children():
		if child is Button:
			idx += 1
			_apply_level_button_style(child as Button, idx)


func _update_main_play_label() -> void:
	_main_play.text = "LEVEL %d" % _selected_level


func _scroll_to_selected() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if _selected_level < 1 or _selected_level > _level_centers.size():
		return
	var target_y: float = _level_centers[_selected_level - 1].y
	var view_h: float = _map_scroll.size.y
	var max_scroll: float = float(_map_scroll.get_v_scroll_bar().max_value)
	_map_scroll.scroll_vertical = int(clampf(target_y - view_h * 0.38, 0.0, max_scroll))


func _start_gameplay() -> void:
	LevelSelectState.request_start_at_level(_selected_level)
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_main_play_pressed() -> void:
	AudioService.play_button_click()
	_start_gameplay()


func _on_settings_pressed() -> void:
	AudioService.play_button_click()
	_settings_layer.open_settings()


func _show_stub(title: String, msg: String) -> void:
	_stub.title = title
	_stub.dialog_text = msg
	_stub.popup_centered()


func _on_home_pressed() -> void:
	AudioService.play_button_click()
	get_tree().change_scene_to_file(HOME_SCENE)


func _on_levels_tab_pressed() -> void:
	AudioService.play_button_click()
	_scroll_to_selected()


func _on_nav_shop_pressed() -> void:
	AudioService.play_button_click()
	_show_stub("Shop", "Treasure deals — coming soon!")


func _on_nav_trophy_pressed() -> void:
	AudioService.play_button_click()
	_show_stub("Trophy", "Your achievements — coming soon!")


func _on_side_shop_pressed() -> void:
	_on_nav_shop_pressed()


func _on_side_rewards_pressed() -> void:
	AudioService.play_button_click()
	_show_stub("Rewards", "Daily streak rewards — open Home for the daily bonus chest!")


func _on_side_events_pressed() -> void:
	AudioService.play_button_click()
	_show_stub("Events", "Limited-time treasure hunts — coming soon!")
