extends Control

const HOME_SCENE: String = "res://main_menu.tscn"
const GAME_SCENE: String = "res://game.tscn"
const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SAVE_SECTION: String = "progress"
const KEY_SAVED_SCORE: String = "saved_score"
const KEY_PROGRESSION: String = "saved_progression_level"
## Must match game.gd — primary unlock depth for the map.
const KEY_FURTHEST_LEVEL: String = "furthest_level_unlocked"
const KEY_CURRENT_LEVEL: String = "current_level_playing"
const MAX_LIVES_DISPLAY: int = 5
const DEBUG_LEVEL_MAP_FLOW: bool = true

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
@onready var _simple_popup: SimplePopup = $SimplePopupLayer
@onready var _shop_popup: Node = $ShopPopupLayer
@onready var _trophies_popup: Node = $TrophiesPopupLayer
@onready var _events_popup: Node = $EventsPopupLayer
@onready var _pregame_popup: Control = $PreGameBoostersPopup
@onready var _journey_layer: Control = $JourneyRewardsLayer
@onready var _rank_layer: Control = $LocalRankLayer
@onready var _profile_btn: Button = $TopBar/HBox/ProfileBtn
@onready var _coin_plus_btn: Button = $TopBar/HBox/CoinPill/Margin/HBox/CoinPlusBtn
@onready var _lives_plus_btn: Button = $TopBar/HBox/LivesPill/Margin/HBox/LivesPlusBtn
@onready var _nav_home: Button = $BottomNav/NavMargin/NavRow/BtnHome
@onready var _nav_journey: Button = $BottomNav/NavMargin/NavRow/BtnJourney
@onready var _nav_levels: Button = $BottomNav/NavMargin/NavRow/BtnLevels
@onready var _nav_shop: Button = $BottomNav/NavMargin/NavRow/BtnShop
@onready var _nav_trophy: Button = $BottomNav/NavMargin/NavRow/BtnTrophy
@onready var _shop_notif_badge: PanelContainer = $BottomNav/NavMargin/NavRow/BtnShop/NotifBadge

var _furthest_level: int = 1
## From save `current_level_playing` (next level to play / last selection).
var _saved_current_level: int = 0
var _selected_level: int = 1
var _display_levels: int = 32
## First level index shown in the sliding map window (1-based).
var _window_level_start: int = 1
var _node_center_x: float = 260.0
var _level_centers: Array[Vector2] = []
## Highest unlocked level node — gentle pulse + glow (may differ from selection when replaying).
var _pulse_frontier_btn: Button = null
var _pulse_t: float = 0.0
var _sway_nodes: Array[TextureRect] = []
var _lock_tex: Texture2D


func _ready() -> void:
	set_process(false)
	_lock_tex = load("res://ui/map_art/lock_map.svg") as Texture2D
	_settings_layer.visible = false
	if _shop_popup != null and _shop_popup.has_signal("toast_requested"):
		_shop_popup.connect("toast_requested", Callable(self, "_open_info_popup"))
	if is_instance_valid(_rank_layer) and _rank_layer.has_signal("trophies_requested"):
		_rank_layer.trophies_requested.connect(_on_rank_layer_trophies_requested)
	_load_save_summary()
	var requested: int = LevelSelectState.consume_pending_level()
	if requested > 0:
		_selected_level = clampi(requested, 1, _furthest_level)
	else:
		# No explicit pending map request: use saved current level (never a hardcoded level index).
		if _saved_current_level > 0:
			_selected_level = clampi(_saved_current_level, 1, _furthest_level)
		else:
			_selected_level = _furthest_level
	if DEBUG_LEVEL_MAP_FLOW:
		print("[LevelMap] selected_level=", _selected_level, " (requested=", requested, " saved_current=", _saved_current_level, ") unlocked_level=", _furthest_level)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_main_play.pressed.connect(_on_main_play_pressed)
	if _pregame_popup != null:
		if _pregame_popup.has_signal("play_pressed"):
			_pregame_popup.play_pressed.connect(_on_pregame_play_pressed)
		if _pregame_popup.has_signal("closed_popup"):
			_pregame_popup.closed_popup.connect(_on_pregame_closed)
	_settings_layer.progress_reset.connect(_on_map_progress_reset)
	call_deferred("_deferred_build_map")
	call_deferred("_setup_arcade_ui")


func _process(delta: float) -> void:
	_pulse_t += delta
	if _pulse_frontier_btn != null and is_instance_valid(_pulse_frontier_btn):
		var s: float = 1.0 + 0.095 * sin(_pulse_t * 2.05)
		_pulse_frontier_btn.pivot_offset = _pulse_frontier_btn.size * 0.5
		_pulse_frontier_btn.scale = Vector2(s, s)
		var gl: float = 1.0 + 0.1 * sin(_pulse_t * 3.05)
		var g2: float = 1.0 + 0.06 * sin(_pulse_t * 4.2 + 0.8)
		_pulse_frontier_btn.modulate = Color(minf(1.12, gl * g2), minf(1.1, gl * 0.99 * g2), minf(1.08, gl * 1.02), 1.0)
	if is_instance_valid(_main_play):
		var mp: float = 1.0 + 0.042 * sin(_pulse_t * 2.4)
		_main_play.pivot_offset = _main_play.size * 0.5
		_main_play.scale = Vector2(mp, mp)
	for c in _levels_layer.get_children():
		if c is Button and c != _pulse_frontier_btn:
			var b: Button = c as Button
			b.scale = Vector2.ONE
			b.modulate = Color.WHITE
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
	set_process(_pulse_frontier_btn != null or not _sway_nodes.is_empty() or is_instance_valid(_main_play))


func _load_save_summary() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		_furthest_level = 1
		_saved_current_level = 1
		return
	# Prefer furthest_level_unlocked (same as game.gd); fall back to legacy key.
	var from_furthest: int = int(cfg.get_value(SAVE_SECTION, KEY_FURTHEST_LEVEL, -1))
	var from_prog: int = int(cfg.get_value(SAVE_SECTION, KEY_PROGRESSION, 1))
	_furthest_level = clampi(from_furthest if from_furthest > 0 else from_prog, 1, 999_999)
	_saved_current_level = clampi(int(cfg.get_value(SAVE_SECTION, KEY_CURRENT_LEVEL, _furthest_level)), 1, _furthest_level)
	if DEBUG_LEVEL_MAP_FLOW:
		print("[LevelMap] load save: furthest_unlocked=", _furthest_level, " key_progression=", from_prog, " saved_current_level=", _saved_current_level)


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


func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


func _smooth_path(pts: PackedVector2Array, steps_per_seg: int) -> PackedVector2Array:
	if pts.size() < 2:
		return pts
	var out: PackedVector2Array = PackedVector2Array()
	var n: int = pts.size()
	for i in range(n - 1):
		var p0: Vector2 = pts[i - 1] if i > 0 else pts[i] + (pts[i] - pts[i + 1])
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[i + 2] if i + 2 < n else pts[i + 1] + (pts[i + 1] - pts[i])
		for s in range(steps_per_seg):
			var u: float = float(s) / float(steps_per_seg)
			out.append(_catmull_rom(p0, p1, p2, p3, u))
	out.append(pts[n - 1])
	return out


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

	var coin_pile_tex: Texture2D = load("res://ui/map_art/coin_small.svg") as Texture2D
	var rng_bg := RandomNumberGenerator.new()
	rng_bg.seed = hash(Vector2i(int(w), int(total_h))) ^ 0x5EED
	if coin_pile_tex != null:
		for _pi in range(10):
			var cx: float = rng_bg.randf_range(24, w - 40)
			var cy: float = rng_bg.randf_range(total_h * 0.35, total_h - 120)
			var n_c: int = rng_bg.randi_range(4, 7)
			for u in range(n_c):
				var pc := TextureRect.new()
				pc.texture = coin_pile_tex
				pc.custom_minimum_size = Vector2(20, 20)
				pc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				pc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
				pc.position = Vector2(cx + float(u) * 5 + rng_bg.randf_range(-2, 2), cy + float(u % 3) * 4)
				pc.modulate = Color(1, 0.92, 0.5, rng_bg.randf_range(0.55, 0.85))
				pc.rotation_degrees = rng_bg.randf_range(-14, 14)
				_background_layer.add_child(pc)

	var gem_tex: Texture2D = load("res://diamond.svg") as Texture2D
	if gem_tex != null:
		for _gi in range(6):
			var g := TextureRect.new()
			g.texture = gem_tex
			g.custom_minimum_size = Vector2(26, 26)
			g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			g.mouse_filter = Control.MOUSE_FILTER_IGNORE
			g.position = Vector2(rng_bg.randf_range(16, w - 36), rng_bg.randf_range(80, total_h - 100))
			g.modulate = Color(0.75, 0.92, 1.0, rng_bg.randf_range(0.45, 0.75))
			_background_layer.add_child(g)
			_add_sway_tex(g, rng_bg.randf() * TAU)

	var star_tex: Texture2D = load("res://ui/map_art/sparkle.svg") as Texture2D
	if star_tex != null:
		for _si in range(12):
			var st := TextureRect.new()
			st.texture = star_tex
			var ssz: float = rng_bg.randf_range(12, 22)
			st.custom_minimum_size = Vector2(ssz, ssz)
			st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			st.mouse_filter = Control.MOUSE_FILTER_IGNORE
			st.position = Vector2(rng_bg.randf_range(4, w - 28), rng_bg.randf_range(30, total_h - 50))
			st.modulate = Color(1, 1, 0.92, rng_bg.randf_range(0.25, 0.5))
			_background_layer.add_child(st)

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
			tr.modulate = Color(1.12, 0.94, 0.48, 0.94)
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


func _place_treasure_checkpoints() -> void:
	var chest: Texture2D = load("res://ui/map_art/treasure_chest.svg") as Texture2D
	if chest == null:
		return
	for i in range(_display_levels):
		var lv: int = _window_level_start + i
		if lv <= 0:
			continue
		var is_milestone_50: bool = (lv % 50 == 0)
		var is_milestone_10: bool = (lv % 10 == 0)
		if not is_milestone_50 and not is_milestone_10:
			continue
		var p: Vector2 = _level_centers[i]
		var tr := TextureRect.new()
		tr.texture = chest
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sz: Vector2
		if is_milestone_50:
			sz = Vector2(78, 60)
			tr.modulate = Color(1.15, 0.92, 0.42, 1)
		else:
			sz = Vector2(48, 38)
			tr.modulate = Color(1.05, 0.98, 0.88, 1)
		tr.custom_minimum_size = sz
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.pivot_offset = sz * 0.5
		var off_x: float = (-sz.x * 0.5 - 46.0) if is_milestone_50 else (-sz.x * 0.5 - 38.0)
		var off_y: float = (-sz.y * 0.5 + 2.0) if is_milestone_50 else (-sz.y * 0.5 - 4.0)
		tr.position = p + Vector2(off_x, off_y)
		tr.z_index = 4
		_decor_layer.add_child(tr)
		if is_milestone_50:
			_add_sway_tex(tr, float(lv) * 0.07)
		var crown := Label.new()
		crown.text = "★" if is_milestone_50 else "◇"
		crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crown.add_theme_font_size_override("font_size", 22 if is_milestone_50 else 16)
		crown.add_theme_color_override("font_color", Color(1, 0.92, 0.45, 0.95) if is_milestone_50 else Color(0.85, 0.95, 1, 0.9))
		crown.position = tr.position + Vector2(sz.x * 0.5 - 10.0, -20.0 if is_milestone_50 else -16.0)
		crown.z_index = 5
		_decor_layer.add_child(crown)


func _place_world_props(pts: PackedVector2Array, w: float, total_h: float) -> void:
	var bush: Texture2D = load("res://ui/map_art/bush.svg") as Texture2D
	var chest: Texture2D = load("res://ui/map_art/treasure_chest.svg") as Texture2D
	var coin_s: Texture2D = load("res://ui/map_art/coin_small.svg") as Texture2D
	var lantern: Texture2D = load("res://ui/map_art/lantern.svg") as Texture2D
	var stone: Texture2D = load("res://ui/map_art/stone.svg") as Texture2D
	var gem_tex: Texture2D = load("res://diamond.svg") as Texture2D
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

		if i % 4 == 2 and gem_tex != null:
			var gm := TextureRect.new()
			gm.texture = gem_tex
			gm.custom_minimum_size = Vector2(22, 22)
			gm.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			gm.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			gm.position = p + Vector2(rng.randf_range(-96, -72), rng.randf_range(8, 22))
			gm.mouse_filter = Control.MOUSE_FILTER_IGNORE
			gm.modulate = Color(0.7, 0.9, 1.0, 0.82)
			_decor_layer.add_child(gm)

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
	_pulse_frontier_btn = null
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

	var span: int = 34
	var teaser_end: int = mini(_furthest_level + 1, 999999)
	_window_level_start = maxi(1, _selected_level - 12)
	var window_end: int = _window_level_start + span - 1
	if window_end < teaser_end:
		window_end = teaser_end
	_window_level_start = maxi(1, window_end - span + 1)
	_display_levels = window_end - _window_level_start + 1

	var w: float = _map_content_width()
	_node_center_x = w * 0.5
	var total_h: float = map_top_padding + float(_display_levels) * level_spacing + 240.0
	_map_root.custom_minimum_size = Vector2(w, total_h)

	## Lower level numbers sit at the bottom of the scroll; locked future levels climb upward.
	var raw_pts: PackedVector2Array = PackedVector2Array()
	for i in range(_display_levels):
		var t: float = float(i)
		var row_from_bottom: float = float(_display_levels - 1 - i)
		var y: float = map_top_padding + row_from_bottom * level_spacing
		var x: float = _node_center_x \
			+ sin(t * path_wave_frequency) * path_wave_amplitude \
			+ sin(t * path_wave_frequency * 0.33 + 0.95) * (path_wave_amplitude * 0.48) \
			+ sin(t * 0.31 + 0.22) * (path_wave_amplitude * 0.2)
		var p := Vector2(x, y)
		raw_pts.append(p)
		_level_centers.append(p)

	var smooth_pts: PackedVector2Array = _smooth_path(raw_pts, 12)

	_build_background_layers(w, total_h)
	_path_drawer.set_path_points(smooth_pts)
	_place_path_tiles_on_curve(smooth_pts)
	_place_world_props(smooth_pts, w, total_h)
	_place_treasure_checkpoints()
	_ambience.build(w, total_h, raw_pts, smooth_pts)

	for i in range(_display_levels):
		var lv: int = _window_level_start + i
		var pos: Vector2 = _level_centers[i]
		var btn := Button.new()
		btn.text = str(lv)
		btn.set_meta(&"level_id", lv)
		btn.custom_minimum_size = Vector2(76, 76)
		btn.position = pos - btn.custom_minimum_size * 0.5
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_level_button_style(btn, lv)
		btn.pressed.connect(_on_level_node_pressed.bind(lv))
		_levels_layer.add_child(btn)
		if lv == _furthest_level:
			_pulse_frontier_btn = btn


func _apply_locked_face(btn: Button, lv: int) -> void:
	btn.text = ""
	var num := btn.get_node_or_null("LockedNum") as Label
	if num == null:
		num = Label.new()
		num.name = "LockedNum"
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.add_child(num)
	num.text = str(lv)
	num.add_theme_font_size_override("font_size", 17)
	num.add_theme_color_override("font_color", Color(0.72, 0.74, 0.82, 0.88))
	num.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.12, 0.92))
	num.add_theme_constant_override("outline_size", 4)
	num.size = Vector2(btn.custom_minimum_size.x, 22)
	num.position = Vector2(0, btn.custom_minimum_size.y - 26)

	var ic := btn.get_node_or_null("LockIcon") as TextureRect
	if ic == null:
		ic = TextureRect.new()
		ic.name = "LockIcon"
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		btn.add_child(ic)
	if _lock_tex != null:
		ic.texture = _lock_tex
	ic.custom_minimum_size = Vector2(30, 30)
	ic.position = Vector2((btn.custom_minimum_size.x - 30) * 0.5, 10)


func _apply_level_button_style(btn: Button, lv: int) -> void:
	var state: String = "locked"
	if lv < _furthest_level:
		state = "done"
	elif lv == _furthest_level:
		state = "current"
	btn.disabled = state == "locked"

	for decal_name in ["LockIcon", "LockedNum"]:
		var rm: Node = btn.get_node_or_null(decal_name)
		if rm != null:
			btn.remove_child(rm)
			rm.free()

	if state == "locked":
		btn.text = ""
	else:
		btn.text = str(lv)

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
		s.shadow_color = Color(0.02, 0.04, 0.12, 0.42)
		s.shadow_size = 7
		s.shadow_offset = Vector2(0, 4)

	match state:
		"locked":
			n.bg_color = Color(0.3, 0.32, 0.38, 1)
			n.border_color = Color(0.18, 0.19, 0.24, 1)
			h.bg_color = Color(0.34, 0.36, 0.42, 1)
			p.bg_color = Color(0.26, 0.28, 0.34, 1)
		"done":
			n.bg_color = Color(0.16, 0.78, 0.46, 1)
			n.border_color = Color(1.0, 0.9, 0.28, 1)
			h.bg_color = Color(0.22, 0.88, 0.52, 1)
			p.bg_color = Color(0.12, 0.62, 0.36, 1)
			n.shadow_size = 12
			n.shadow_color = Color(0.75, 0.55, 0.12, 0.42)
			h.shadow_size = 11
			h.shadow_color = Color(0.85, 0.65, 0.15, 0.35)
		"current":
			n.bg_color = Color(1.0, 0.93, 0.38, 1)
			n.border_color = Color(1.0, 0.78, 0.12, 1)
			h.bg_color = Color(1.0, 0.97, 0.52, 1)
			p.bg_color = Color(0.98, 0.82, 0.22, 1)
			n.shadow_size = 28
			n.shadow_color = Color(1.0, 0.72, 0.18, 0.62)
			h.shadow_size = 24
			h.shadow_color = Color(1.0, 0.78, 0.35, 0.5)
			p.shadow_size = 18
			p.shadow_color = Color(0.85, 0.5, 0.05, 0.45)

	if state == "current":
		for s in [n, h, p]:
			s.border_width_left = 6
			s.border_width_top = 6
			s.border_width_right = 6
			s.border_width_bottom = 9
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_constant_override("outline_size", 8)
	else:
		for s in [n, h, p]:
			s.border_width_left = 3
			s.border_width_top = 3
			s.border_width_right = 3
			s.border_width_bottom = 5

	var sel: bool = (lv == _selected_level and state != "locked")
	if sel:
		for s in [n, h, p]:
			s.border_width_left += 2
			s.border_width_top += 2
			s.border_width_right += 2
			s.border_width_bottom += 2
			s.border_color = s.border_color.lerp(Color(1, 0.95, 0.55, 1), 0.35)

	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	if state == "done":
		btn.add_theme_constant_override("outline_size", 7)
	if state == "locked":
		var d := n.duplicate() as StyleBoxFlat
		d.bg_color = Color(0.34, 0.36, 0.44, 0.88)
		btn.add_theme_stylebox_override("disabled", d)
		btn.add_theme_color_override("font_color", Color(0.55, 0.56, 0.62, 0.5))
		_apply_locked_face(btn, lv)


func _level_button_for(lv: int) -> Button:
	for c in _levels_layer.get_children():
		if c is Button and int((c as Button).get_meta(&"level_id", 0)) == lv:
			return c as Button
	return null


func _play_level_tap_bounce(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	var y0: float = btn.position.y
	var tw := create_tween()
	tw.tween_property(btn, "position:y", y0 - 11.0, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "position:y", y0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _on_level_node_pressed(lv: int) -> void:
	if lv > _furthest_level:
		return
	_play_level_tap_bounce(_level_button_for(lv))
	_selected_level = lv
	_update_main_play_label()
	_refresh_all_level_styles()
	AudioService.play_button_click()


func _refresh_all_level_styles() -> void:
	for child in _levels_layer.get_children():
		if child is Button:
			var id: int = int((child as Button).get_meta(&"level_id", 0))
			if id > 0:
				_apply_level_button_style(child as Button, id)


func _update_main_play_label() -> void:
	_main_play.text = "LEVEL %d" % _selected_level


func _scroll_to_selected() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var idx: int = _selected_level - _window_level_start
	if idx < 0 or idx >= _level_centers.size():
		return
	var target_y: float = _level_centers[idx].y
	var view_h: float = _map_scroll.size.y
	var max_scroll: float = float(_map_scroll.get_v_scroll_bar().max_value)
	_map_scroll.scroll_vertical = int(clampf(target_y - view_h * 0.38, 0.0, max_scroll))


func _read_pregame_booster_stocks() -> Vector2i:
	var cfg := ConfigFile.new()
	var bc: int = 3
	var ss: int = 3
	if cfg.load(SAVE_PATH) == OK:
		bc = clampi(int(cfg.get_value(SAVE_SECTION, BoosterManager.KEY_BOMB_CLEAR, 3)), 0, 99)
		ss = clampi(int(cfg.get_value(SAVE_SECTION, BoosterManager.KEY_START_SLOW, 3)), 0, 99)
	return Vector2i(bc, ss)


func _start_gameplay() -> void:
	if _pregame_popup != null and _pregame_popup.has_method("present"):
		var st: Vector2i = _read_pregame_booster_stocks()
		_pregame_popup.call("present", st.x, st.y, _furthest_level)
		return
	LevelSelectState.set_pregame_boosters(false, false)
	LevelSelectState.request_start_at_level(_selected_level)
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_pregame_play_pressed(use_bomb_clear: bool, use_start_slow: bool) -> void:
	LevelSelectState.set_pregame_boosters(use_bomb_clear, use_start_slow)
	LevelSelectState.request_start_at_level(_selected_level)
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_pregame_closed() -> void:
	pass


func _on_main_play_pressed() -> void:
	AudioService.play_button_click()
	_start_gameplay()


func _on_settings_pressed() -> void:
	AudioService.play_button_click()
	_settings_layer.open_settings()


func _open_info_popup(title: String, msg: String) -> void:
	if _simple_popup != null:
		_simple_popup.open_popup(title, msg)
	else:
		_show_stub(title, msg)


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


func _on_nav_journey_pressed() -> void:
	AudioService.play_button_click()
	if is_instance_valid(_journey_layer) and _journey_layer.has_method("open_journey"):
		_journey_layer.open_journey()


func _on_nav_shop_pressed() -> void:
	AudioService.play_button_click()
	if _shop_popup != null and _shop_popup.has_method("open_shop"):
		_shop_popup.call("open_shop")
	else:
		_open_info_popup("Treasure Emporium", "The shop cart rolled away — try again from Home.")


func _on_nav_trophy_pressed() -> void:
	AudioService.play_button_click()
	if is_instance_valid(_rank_layer) and _rank_layer.has_method("open_rank"):
		_rank_layer.open_rank()
	elif _trophies_popup != null and _trophies_popup.has_method("open_trophies"):
		_trophies_popup.call("open_trophies")
	else:
		_open_info_popup("Hall of Gleams", "Trophies are polishing — open them from Home.")


func _on_rank_layer_trophies_requested() -> void:
	if _trophies_popup != null and _trophies_popup.has_method("open_trophies"):
		_trophies_popup.call("open_trophies")
	else:
		_open_info_popup("Hall of Gleams", "Trophies are polishing — open them from Home.")


func _on_side_shop_pressed() -> void:
	_on_nav_shop_pressed()


func _on_side_rewards_pressed() -> void:
	AudioService.play_button_click()
	get_tree().change_scene_to_file(HOME_SCENE)


func _on_side_events_pressed() -> void:
	AudioService.play_button_click()
	if _events_popup != null and _events_popup.has_method("open_events"):
		_events_popup.call("open_events")
	else:
		_open_info_popup("Vault events", "Events are unavailable right now.")


func _on_map_progress_reset() -> void:
	_load_save_summary()
	_selected_level = clampi(_furthest_level, 1, 999_999)
	_refresh_hud()
	call_deferred("_deferred_build_map")


func _make_flat_style(bg: Color, border: Color, border_w: int, radius: int, shadow_sz: int, shadow: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = border_w
	s.border_width_top = border_w
	s.border_width_right = border_w
	s.border_width_bottom = border_w
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_right = radius
	s.corner_radius_bottom_left = radius
	s.shadow_size = shadow_sz
	s.shadow_offset = Vector2(0, 6)
	s.shadow_color = shadow
	return s


func _make_play_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = 9
	s.border_width_top = 9
	s.border_width_right = 9
	s.border_width_bottom = 13
	s.corner_radius_top_left = 36
	s.corner_radius_top_right = 36
	s.corner_radius_bottom_right = 36
	s.corner_radius_bottom_left = 36
	s.shadow_size = 28
	s.shadow_offset = Vector2(0, 10)
	s.shadow_color = Color(0.02, 0.12, 0.06, 0.65)
	return s


func _apply_main_play_arcade_styles() -> void:
	if not is_instance_valid(_main_play):
		return
	var n := _make_play_style(Color(0.14, 0.98, 0.55, 1), Color(0.05, 0.12, 0.42, 1))
	var h := _make_play_style(Color(0.28, 1.0, 0.62, 1), Color(0.06, 0.14, 0.48, 1))
	var p := _make_play_style(Color(0.1, 0.78, 0.44, 1), Color(0.04, 0.1, 0.36, 1))
	_main_play.add_theme_stylebox_override("normal", n)
	_main_play.add_theme_stylebox_override("hover", h)
	_main_play.add_theme_stylebox_override("pressed", p)
	_main_play.add_theme_stylebox_override("focus", n)
	_main_play.add_theme_font_size_override("font_size", 52)
	_main_play.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_main_play.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.06, 1))
	_main_play.add_theme_constant_override("outline_size", 16)
	_main_play.clip_contents = false


func _apply_top_bar_arcade_styles() -> void:
	if not is_instance_valid(_profile_btn):
		return
	var bar := _make_flat_style(Color(0.16, 0.38, 0.88, 0.96), Color(0.98, 0.82, 0.28, 1), 3, 22, 12, Color(0, 0, 0, 0.4))
	var cream := _make_flat_style(Color(0.99, 0.97, 0.92, 1), Color(0.92, 0.72, 0.2, 1), 3, 20, 6, Color(0.08, 0.05, 0.02, 0.28))
	var plus := _make_flat_style(Color(0.22, 0.78, 0.38, 1), Color(0.12, 0.48, 0.22, 1), 2, 14, 4, Color(0.02, 0.2, 0.06, 0.35))
	var prof_n := _make_flat_style(Color(0.28, 0.55, 0.95, 1), Color(0.98, 0.8, 0.25, 1), 3, 99, 8, Color(0, 0, 0, 0.35))
	var prof_h := prof_n.duplicate() as StyleBoxFlat
	prof_h.bg_color = Color(0.38, 0.65, 1.0, 1)
	var gear_n := _make_flat_style(Color(0.24, 0.48, 0.92, 1), Color(0.95, 0.78, 0.22, 1), 3, 99, 9, Color(0, 0, 0, 0.38))
	var gear_h := gear_n.duplicate() as StyleBoxFlat
	gear_h.bg_color = Color(0.34, 0.58, 1.0, 1)
	$TopBar.add_theme_stylebox_override("panel", bar)
	$TopBar/HBox/CoinPill.add_theme_stylebox_override("panel", cream)
	$TopBar/HBox/LivesPill.add_theme_stylebox_override("panel", cream)
	_profile_btn.add_theme_stylebox_override("normal", prof_n)
	_profile_btn.add_theme_stylebox_override("hover", prof_h)
	_profile_btn.add_theme_stylebox_override("pressed", prof_h)
	_profile_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_profile_btn.add_theme_font_size_override("font_size", 26)
	_settings_btn.add_theme_stylebox_override("normal", gear_n)
	_settings_btn.add_theme_stylebox_override("hover", gear_h)
	_settings_btn.add_theme_stylebox_override("pressed", gear_h)
	_settings_btn.add_theme_stylebox_override("focus", gear_n)
	_coin_plus_btn.add_theme_stylebox_override("normal", plus)
	_coin_plus_btn.add_theme_stylebox_override("hover", plus)
	_coin_plus_btn.add_theme_stylebox_override("pressed", plus)
	_coin_plus_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_coin_plus_btn.add_theme_font_size_override("font_size", 22)
	_lives_plus_btn.add_theme_stylebox_override("normal", plus)
	_lives_plus_btn.add_theme_stylebox_override("hover", plus)
	_lives_plus_btn.add_theme_stylebox_override("pressed", plus)
	_lives_plus_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_lives_plus_btn.add_theme_font_size_override("font_size", 22)
	if _coin_value:
		_coin_value.add_theme_font_size_override("font_size", 26)
		_coin_value.add_theme_color_override("font_color", Color(0.18, 0.14, 0.08, 1))
		_coin_value.add_theme_color_override("font_outline_color", Color(1, 0.95, 0.8, 0.85))
		_coin_value.add_theme_constant_override("outline_size", 5)
	if _lives_value:
		_lives_value.add_theme_font_size_override("font_size", 26)
		_lives_value.add_theme_color_override("font_color", Color(0.22, 0.1, 0.1, 1))
		_lives_value.add_theme_color_override("font_outline_color", Color(1, 0.85, 0.85, 0.9))
		_lives_value.add_theme_constant_override("outline_size", 5)
	var heart := $TopBar/HBox/LivesPill/Margin/HBox/HeartLbl as Label
	if heart:
		heart.add_theme_font_size_override("font_size", 28)


func _apply_bottom_nav_arcade_styles() -> void:
	## Icon-only bar: large centered icons, glossy tiles, gold rim; Levels tab reads as selected.
	var nav_n := _make_flat_style(Color(0.34, 0.2, 0.82, 1), Color(0.98, 0.82, 0.28, 1), 3, 22, 11, Color(0, 0, 0, 0.48))
	var nav_h := nav_n.duplicate() as StyleBoxFlat
	nav_h.bg_color = Color(0.46, 0.34, 0.95, 1)
	nav_h.shadow_color = Color(0.15, 0.05, 0.35, 0.4)
	var nav_p := nav_n.duplicate() as StyleBoxFlat
	nav_p.bg_color = Color(0.26, 0.12, 0.68, 1)
	var sel_n := _make_flat_style(Color(0.5, 0.36, 0.98, 1), Color(1, 0.9, 0.38, 1), 4, 24, 14, Color(0.45, 0.28, 0.95, 0.5))
	var sel_h := sel_n.duplicate() as StyleBoxFlat
	sel_h.bg_color = Color(0.58, 0.45, 1.0, 1)
	var bottom := _make_flat_style(Color(0.06, 0.04, 0.16, 0.99), Color(0.95, 0.72, 0.2, 1), 0, 26, 16, Color(0, 0, 0, 0.58))
	bottom.border_width_top = 5
	bottom.border_width_left = 0
	bottom.border_width_right = 0
	bottom.border_width_bottom = 0
	$BottomNav.add_theme_stylebox_override("panel", bottom)
	var tex_home: Texture2D = load("res://ui/map_art/nav_home.svg") as Texture2D
	var tex_journey: Texture2D = load("res://ui/map_art/nav_journey.svg") as Texture2D
	var tex_map: Texture2D = load("res://ui/map_art/nav_map.svg") as Texture2D
	var tex_shop: Texture2D = load("res://ui/map_art/nav_shop.svg") as Texture2D
	var tex_trophy: Texture2D = load("res://ui/map_art/nav_trophy.svg") as Texture2D
	const NAV_MIN := Vector2(78, 102)
	const NAV_SEL_MIN := Vector2(96, 118)
	for b: Button in [_nav_home, _nav_journey, _nav_shop, _nav_trophy]:
		b.add_theme_stylebox_override("normal", nav_n)
		b.add_theme_stylebox_override("hover", nav_h)
		b.add_theme_stylebox_override("pressed", nav_p)
		b.add_theme_stylebox_override("focus", nav_n)
		b.text = ""
		b.add_theme_constant_override("icon_max_width", 70)
		b.add_theme_constant_override("h_separation", 0)
		b.custom_minimum_size = NAV_MIN
		b.clip_contents = false
	_nav_levels.add_theme_stylebox_override("normal", sel_n)
	_nav_levels.add_theme_stylebox_override("hover", sel_h)
	_nav_levels.add_theme_stylebox_override("pressed", nav_p)
	_nav_levels.add_theme_stylebox_override("focus", sel_n)
	_nav_levels.text = ""
	_nav_levels.add_theme_constant_override("icon_max_width", 84)
	_nav_levels.add_theme_constant_override("h_separation", 0)
	_nav_levels.custom_minimum_size = NAV_SEL_MIN
	_nav_levels.clip_contents = false
	if tex_home:
		_nav_home.icon = tex_home
	if tex_journey:
		_nav_journey.icon = tex_journey
	if tex_map:
		_nav_levels.icon = tex_map
	if tex_shop:
		_nav_shop.icon = tex_shop
	if tex_trophy:
		_nav_trophy.icon = tex_trophy
	for b in [_nav_home, _nav_journey, _nav_levels, _nav_shop, _nav_trophy]:
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_instance_valid(_shop_notif_badge):
		var bn := _make_flat_style(Color(0.92, 0.18, 0.22, 1), Color(1, 1, 1, 0.9), 2, 99, 3, Color(0, 0, 0, 0.35))
		_shop_notif_badge.add_theme_stylebox_override("panel", bn)
		var lbl := _shop_notif_badge.get_node_or_null("Margin/Label") as Label
		if lbl:
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color", Color.WHITE)


func _on_bottom_nav_down(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.size * 0.5
	var base: float = _nav_base_scale(btn)
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2(base * 0.94, base * 0.94), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_bottom_nav_up(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	var base: float = _nav_base_scale(btn)
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2(base, base), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _wire_arcade_extras() -> void:
	if is_instance_valid(_profile_btn):
		_profile_btn.pressed.connect(_on_profile_avatar_pressed)
	if is_instance_valid(_coin_plus_btn):
		_coin_plus_btn.pressed.connect(_on_coin_plus_pressed)
	if is_instance_valid(_lives_plus_btn):
		_lives_plus_btn.pressed.connect(_on_lives_plus_pressed)
	for b in [_nav_home, _nav_journey, _nav_levels, _nav_shop, _nav_trophy]:
		if is_instance_valid(b):
			b.button_down.connect(_on_bottom_nav_down.bind(b))
			b.button_up.connect(_on_bottom_nav_up.bind(b))
	call_deferred("_apply_levels_tab_selected_scale")


func _nav_base_scale(btn: Button) -> float:
	return 1.12 if btn == _nav_levels else 1.0


func _apply_levels_tab_selected_scale() -> void:
	if is_instance_valid(_nav_levels):
		_nav_levels.pivot_offset = _nav_levels.size * 0.5
		_nav_levels.scale = Vector2(1.12, 1.12)
		_nav_levels.z_index = 2


func _on_profile_avatar_pressed() -> void:
	AudioService.play_button_click()
	_open_info_popup("Adventurer", "Profile perks are on the way — keep clearing levels!")


func _on_coin_plus_pressed() -> void:
	_on_nav_shop_pressed()


func _on_lives_plus_pressed() -> void:
	_on_nav_shop_pressed()


func _setup_arcade_ui() -> void:
	_apply_main_play_arcade_styles()
	_apply_top_bar_arcade_styles()
	_apply_bottom_nav_arcade_styles()
	_apply_side_rail_arcade_styles()
	_apply_main_play_chrome_children()
	_wire_arcade_extras()


func _apply_side_rail_arcade_styles() -> void:
	var rail_n := _make_flat_style(Color(0.36, 0.2, 0.74, 1), Color(0.96, 0.76, 0.22, 1), 2, 14, 5, Color(0, 0, 0, 0.32))
	var rail_h := rail_n.duplicate() as StyleBoxFlat
	rail_h.bg_color = Color(0.44, 0.28, 0.88, 1)
	var rail_p := rail_n.duplicate() as StyleBoxFlat
	rail_p.bg_color = Color(0.28, 0.14, 0.58, 1)
	for nm in [&"SideShop", &"SideRewards", &"SideEvents"]:
		var sb: Button = $SideRail.get_node(NodePath(str(nm))) as Button
		if sb == null:
			continue
		sb.add_theme_stylebox_override("normal", rail_n)
		sb.add_theme_stylebox_override("hover", rail_h)
		sb.add_theme_stylebox_override("pressed", rail_p)
		sb.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		sb.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.16, 1))
		sb.add_theme_constant_override("outline_size", 4)


func _apply_main_play_chrome_children() -> void:
	if not is_instance_valid(_main_play):
		return
	var rim := _main_play.get_node_or_null("InnerGoldRim") as Panel
	if rim != null:
		var g := StyleBoxFlat.new()
		g.draw_center = false
		g.border_color = Color(0.98, 0.86, 0.2, 1)
		g.border_width_left = 3
		g.border_width_top = 3
		g.border_width_right = 3
		g.border_width_bottom = 3
		g.corner_radius_top_left = 30
		g.corner_radius_top_right = 30
		g.corner_radius_bottom_right = 30
		g.corner_radius_bottom_left = 30
		rim.add_theme_stylebox_override("panel", g)
	var shine := _main_play.get_node_or_null("TopShine") as Panel
	if shine != null:
		var sh := StyleBoxFlat.new()
		sh.bg_color = Color(1, 1, 1, 0.22)
		sh.border_width_left = 0
		sh.border_width_top = 0
		sh.border_width_right = 0
		sh.border_width_bottom = 0
		sh.corner_radius_top_left = 40
		sh.corner_radius_top_right = 40
		sh.corner_radius_bottom_right = 40
		sh.corner_radius_bottom_left = 40
		shine.add_theme_stylebox_override("panel", sh)
