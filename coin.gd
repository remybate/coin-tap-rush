extends Button
class_name Collectible

enum Kind { GOLD, SILVER_BIG, DIAMOND, BOMB }

## SVG cannot use preload() in Godot 4.2 — use load() so the texture importer remap applies.
static var TEX_GOLD: Texture2D = load("res://gold_coin.svg") as Texture2D
static var TEX_SILVER: Texture2D = load("res://silver_coin.svg") as Texture2D
static var TEX_DIAMOND: Texture2D = load("res://diamond.svg") as Texture2D
static var TEX_BOMB: Texture2D = load("res://bomb.svg") as Texture2D

## <1 slows lateral sine motion (same path shape, fewer zigzags per second of fall).
const ZIG_ANGULAR_SCALE: float = 0.52

var rng := RandomNumberGenerator.new()
var kind: Kind = Kind.GOLD

var fall_speed: float = 220.0
var base_x: float = 0.0
## Primary zigzag
var zig_amplitude: float = 60.0
var zig_angular_speed: float = 1.56
var phase: float = 0.0
## Secondary wobble (irregular zigzag, not a straight line)
var zig_amplitude2: float = 24.0
var zig_angular_speed2: float = 2.86
var phase2: float = 0.0
## Spin (rad/s); sign = direction
var spin_rad_per_sec: float = 2.5
var time_falling: float = 0.0
## Eases into target fall speed so spawns feel less stiff (gameplay path unchanged once settled).
var _fall_vel_smooth: float = 0.0
var _play_margin: float = 72.0
var _play_w: float = 1080.0
var _spark_trail: Line2D
const TRAIL_MAX_PTS: int = 14


func _ready() -> void:
	add_to_group("coin")
	_spark_trail = Line2D.new()
	_spark_trail.width = 5.0
	_spark_trail.default_color = Color(1.0, 0.95, 0.65, 0.42)
	_spark_trail.antialiased = true
	_spark_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_spark_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	_spark_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	_spark_trail.z_index = -1
	add_child(_spark_trail)
	rng.randomize()
	flat = true
	expand_icon = true
	text = ""
	pressed.connect(_on_pressed)


func reset_for_new_game() -> void:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("should_run_collectible") and not main.should_run_collectible(self):
		visible = false
		set_process(false)
		disabled = true
		position = Vector2(-4000, -4000)
		return
	disabled = false
	set_process(true)
	visible = true
	_pick_random_path(true)


func _pick_random_kind() -> Kind:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("get_collectible_kind_for_spawn"):
		return main.get_collectible_kind_for_spawn(rng)
	var bombs_ok: bool = true
	if main and main.has_method("bombs_enabled"):
		bombs_ok = main.bombs_enabled()
	var r: float = rng.randf()
	if not bombs_ok:
		if r < 0.58:
			return Kind.GOLD
		if r < 0.82:
			return Kind.SILVER_BIG
		return Kind.DIAMOND
	if r < 0.50:
		return Kind.GOLD
	if r < 0.74:
		return Kind.SILVER_BIG
	if r < 0.86:
		return Kind.DIAMOND
	return Kind.BOMB


func _apply_kind() -> void:
	match kind:
		Kind.GOLD:
			icon = TEX_GOLD
			custom_minimum_size = Vector2(76, 76)
			if _spark_trail:
				_spark_trail.default_color = Color(1.0, 0.92, 0.45, 0.48)
				_spark_trail.width = 5.0
		Kind.SILVER_BIG:
			icon = TEX_SILVER
			custom_minimum_size = Vector2(96, 96)
			if _spark_trail:
				_spark_trail.default_color = Color(0.78, 0.92, 1.0, 0.5)
				_spark_trail.width = 6.0
		Kind.DIAMOND:
			icon = TEX_DIAMOND
			custom_minimum_size = Vector2(84, 84)
			if _spark_trail:
				_spark_trail.default_color = Color(0.55, 0.98, 1.0, 0.62)
				_spark_trail.width = 6.5
		Kind.BOMB:
			icon = TEX_BOMB
			custom_minimum_size = Vector2(88, 88)
			if _spark_trail:
				_spark_trail.clear_points()
				_spark_trail.width = 0.0
	_update_pivot()
	_apply_world_style_overrides()


func apply_world_visuals() -> void:
	_apply_kind()


func _apply_world_style_overrides() -> void:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main == null or not main.has_method("get_active_world_theme"):
		modulate = Color.WHITE
		return
	var t: Dictionary = main.get_active_world_theme()
	if t.is_empty():
		modulate = Color.WHITE
		return
	match kind:
		Kind.GOLD:
			modulate = t.get("coin_mod_gold", Color.WHITE) as Color
		Kind.SILVER_BIG:
			modulate = t.get("coin_mod_silver", Color.WHITE) as Color
		Kind.DIAMOND:
			modulate = t.get("coin_mod_diamond", Color.WHITE) as Color
		Kind.BOMB:
			modulate = t.get("coin_mod_bomb", Color.WHITE) as Color
	if _spark_trail and kind != Kind.BOMB:
		var tk: String = "trail_gold"
		match kind:
			Kind.SILVER_BIG:
				tk = "trail_silver"
			Kind.DIAMOND:
				tk = "trail_diamond"
			_:
				pass
		_spark_trail.default_color = t.get(tk, _spark_trail.default_color) as Color


func _update_pivot() -> void:
	pivot_offset = custom_minimum_size * 0.5


func _on_pressed() -> void:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("is_game_over") and main.is_game_over():
		return
	if kind == Kind.BOMB:
		AudioService.play_bomb_tap()
	else:
		AudioService.play_coin_tap()
	if main and main.has_method("play_collect_burst"):
		main.play_collect_burst(global_position, kind)
	if main and main.has_method("register_collectible"):
		main.register_collectible(kind, global_position)
	if kind != Kind.BOMB and main and main.has_method("set_magnet_focus"):
		main.set_magnet_focus(global_position.x)
	_pick_random_path(false)


func convert_bomb_to_safe_coin() -> void:
	if kind != Kind.BOMB:
		return
	var safety: int = 0
	while kind == Kind.BOMB and safety < 14:
		kind = _pick_random_kind()
		safety += 1
	if kind == Kind.BOMB:
		kind = Kind.GOLD
	_apply_kind()


func _pick_random_path(first_spawn: bool = false) -> void:
	var main_chk: Node = get_tree().get_first_node_in_group("main")
	if main_chk and main_chk.has_method("should_run_collectible") and not main_chk.should_run_collectible(self):
		return
	kind = _pick_random_kind()
	_apply_kind()

	var rect := get_viewport_rect()
	_play_margin = 72.0
	_play_w = max(rect.size.x, 400.0)
	var margin := _play_margin
	var w: float = _play_w
	## Random lane across the screen (not only center)
	base_x = rng.randf_range(margin, w - margin)

	zig_amplitude = rng.randf_range(36.0, 130.0)
	zig_angular_speed = rng.randf_range(1.8, 6.2) * ZIG_ANGULAR_SCALE
	phase = rng.randf() * TAU

	zig_amplitude2 = rng.randf_range(12.0, 48.0)
	zig_angular_speed2 = rng.randf_range(3.5, 9.5) * ZIG_ANGULAR_SCALE
	phase2 = rng.randf() * TAU

	var bounds := Vector2(170.0, 290.0)
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("get_fall_speed_range"):
		bounds = main.get_fall_speed_range()
	## Different fall speeds per spawn, scaled by current level range
	var base_fall: float = rng.randf_range(bounds.x, bounds.y)
	fall_speed = base_fall * rng.randf_range(0.82, 1.18)
	if main and main.has_method("get_fall_speed_bonus_scale"):
		fall_speed *= main.get_fall_speed_bonus_scale()

	## Rotation: direction and rate (bombs spin a bit faster)
	var spin_roll: float = rng.randf_range(1.8, 4.2)
	if kind == Kind.BOMB:
		spin_roll *= 1.35
	spin_rad_per_sec = spin_roll * (1 if rng.randf() > 0.5 else -1)
	rotation = rng.randf() * TAU

	time_falling = 0.0
	_fall_vel_smooth = 0.0
	scale = Vector2.ONE
	var y_top: float = -140.0
	var y_bot: float = -24.0
	if main and main.has_method("get_spawn_depth_range"):
		var yr: Vector2 = main.get_spawn_depth_range()
		y_top = yr.x
		y_bot = yr.y
	position.y = rng.randf_range(y_top, y_bot) if not first_spawn else rng.randf_range(minf(y_bot, -10.0), 0.0)
	position.x = _x_at_time(0.0)
	if _spark_trail != null:
		_spark_trail.clear_points()


func _x_at_time(t: float) -> float:
	var x: float = base_x
	x += sin(t * zig_angular_speed + phase) * zig_amplitude
	x += sin(t * zig_angular_speed2 + phase2) * zig_amplitude2
	## Extra slow drift so the path feels less like a single rigid waveform.
	x += sin(t * zig_angular_speed * 0.41 + phase2 * 1.07) * (zig_amplitude * 0.09)
	return clamp(x, _play_margin, _play_w - _play_margin)


func _process(delta: float) -> void:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("is_game_over") and main.is_game_over():
		return

	var trail_anchor_global := global_position

	var rect := get_viewport_rect()
	var h: float = max(rect.size.y, 600.0)
	var miss_y: float = h + 80.0
	if main and main.has_method("get_danger_y"):
		miss_y = main.get_danger_y()

	var vm: float = 1.0
	if main and main.has_method("get_collectible_vertical_mult"):
		vm = main.get_collectible_vertical_mult()

	time_falling += delta * vm
	var target_v: float = fall_speed * vm
	if vm <= 0.0001:
		_fall_vel_smooth = lerpf(_fall_vel_smooth, 0.0, clampf(14.0 * delta, 0.0, 1.0))
	else:
		_fall_vel_smooth = lerpf(_fall_vel_smooth, target_v, clampf(9.0 * delta, 0.0, 1.0))
	position.y += _fall_vel_smooth * delta

	var target_x: float = _x_at_time(time_falling)
	var x_lerp: float = 10.0 if vm <= 0.0001 else 17.0
	position.x = lerpf(position.x, target_x, clampf(x_lerp * delta, 0.0, 1.0))
	rotation += spin_rad_per_sec * delta * vm

	if vm > 0.0001:
		var breathe: float = 1.0 + 0.026 * sin(time_falling * 3.05 + phase * 0.41)
		scale = Vector2(breathe, breathe)
	else:
		scale = Vector2.ONE

	if _spark_trail != null and kind != Kind.BOMB and vm > 0.0001 and visible:
		var local_pt: Vector2 = _spark_trail.get_global_transform().affine_inverse() * trail_anchor_global
		_spark_trail.add_point(local_pt)
		while _spark_trail.get_point_count() > TRAIL_MAX_PTS:
			_spark_trail.remove_point(0)
	elif _spark_trail != null:
		_spark_trail.clear_points()

	if main and main.has_method("apply_magnet_to_collectible"):
		main.apply_magnet_to_collectible(self, delta)

	if position.y > miss_y:
		if kind == Kind.BOMB:
			if main and main.has_method("register_bomb_dodged"):
				main.register_bomb_dodged()
		else:
			if main and main.has_method("register_miss"):
				main.register_miss()
			if main and main.has_method("is_game_over") and main.is_game_over():
				set_process(false)
				disabled = true
				return
		_pick_random_path(false)
