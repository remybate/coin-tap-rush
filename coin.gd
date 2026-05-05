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
var _play_margin: float = 72.0
var _play_w: float = 1080.0


func _ready() -> void:
	add_to_group("coin")
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
		Kind.SILVER_BIG:
			icon = TEX_SILVER
			custom_minimum_size = Vector2(96, 96)
		Kind.DIAMOND:
			icon = TEX_DIAMOND
			custom_minimum_size = Vector2(84, 84)
		Kind.BOMB:
			icon = TEX_BOMB
			custom_minimum_size = Vector2(88, 88)
	_update_pivot()


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
	if main and main.has_method("register_collectible"):
		main.register_collectible(kind)
	if kind != Kind.BOMB and main and main.has_method("set_magnet_focus"):
		main.set_magnet_focus(global_position.x)
	if kind != Kind.BOMB and main and main.has_method("play_collect_burst"):
		main.play_collect_burst(global_position, kind)
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
	var y_top: float = -140.0
	var y_bot: float = -24.0
	if main and main.has_method("get_spawn_depth_range"):
		var yr: Vector2 = main.get_spawn_depth_range()
		y_top = yr.x
		y_bot = yr.y
	position.y = rng.randf_range(y_top, y_bot) if not first_spawn else rng.randf_range(minf(y_bot, -10.0), 0.0)
	position.x = _x_at_time(0.0)


func _x_at_time(t: float) -> float:
	var x: float = base_x
	x += sin(t * zig_angular_speed + phase) * zig_amplitude
	x += sin(t * zig_angular_speed2 + phase2) * zig_amplitude2
	return clamp(x, _play_margin, _play_w - _play_margin)


func _process(delta: float) -> void:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("is_game_over") and main.is_game_over():
		return

	var rect := get_viewport_rect()
	var h: float = max(rect.size.y, 600.0)
	var miss_y: float = h + 80.0
	if main and main.has_method("get_danger_y"):
		miss_y = main.get_danger_y()

	var vm: float = 1.0
	if main and main.has_method("get_collectible_vertical_mult"):
		vm = main.get_collectible_vertical_mult()

	time_falling += delta * vm
	position.y += fall_speed * delta * vm
	position.x = _x_at_time(time_falling)
	rotation += spin_rad_per_sec * delta * vm

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
