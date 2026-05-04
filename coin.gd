extends Button
class_name Collectible

enum Kind { GOLD, SILVER_BIG, DIAMOND, BOMB }

const TEX_GOLD: Texture2D = preload("res://gold_coin.svg")
const TEX_SILVER: Texture2D = preload("res://silver_coin.svg")
const TEX_DIAMOND: Texture2D = preload("res://diamond.svg")
const TEX_BOMB: Texture2D = preload("res://bomb.svg")

var rng := RandomNumberGenerator.new()
var kind: Kind = Kind.GOLD

var fall_speed: float = 220.0
var base_x: float = 0.0
var zig_amplitude: float = 60.0
var zig_angular_speed: float = 3.0
var phase: float = 0.0
var time_falling: float = 0.0


func _ready() -> void:
	add_to_group("coin")
	rng.randomize()
	flat = true
	expand_icon = true
	text = ""
	pressed.connect(_on_pressed)
	_pick_random_path(true)


func reset_for_new_game() -> void:
	disabled = false
	set_process(true)
	_pick_random_path(true)


func _pick_random_kind() -> Kind:
	var r: float = rng.randf()
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


func _on_pressed() -> void:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("is_game_over") and main.is_game_over():
		return
	if main and main.has_method("register_collectible"):
		main.register_collectible(kind)
	_pick_random_path(false)


func _pick_random_path(first_spawn: bool = false) -> void:
	kind = _pick_random_kind()
	_apply_kind()

	var rect := get_viewport_rect()
	var margin := 72.0
	var w: float = max(rect.size.x, 400.0)
	base_x = rng.randf_range(margin, w - margin)
	zig_amplitude = rng.randf_range(28.0, 110.0)
	zig_angular_speed = rng.randf_range(2.2, 5.5)
	phase = rng.randf() * TAU

	var bounds := Vector2(170.0, 290.0)
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("get_fall_speed_range"):
		bounds = main.get_fall_speed_range()
	fall_speed = rng.randf_range(bounds.x, bounds.y)

	time_falling = 0.0
	position.y = rng.randf_range(-120.0, -20.0) if not first_spawn else rng.randf_range(-40.0, 0.0)
	position.x = base_x + sin(phase) * zig_amplitude


func _process(delta: float) -> void:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("is_game_over") and main.is_game_over():
		return

	var rect := get_viewport_rect()
	var h: float = max(rect.size.y, 600.0)
	var miss_y: float = h + 80.0
	if main and main.has_method("get_danger_y"):
		miss_y = main.get_danger_y()

	time_falling += delta
	position.y += fall_speed * delta
	position.x = base_x + sin(time_falling * zig_angular_speed + phase) * zig_amplitude

	if position.y > miss_y:
		if kind != Kind.BOMB:
			if main and main.has_method("register_miss"):
				main.register_miss()
			if main and main.has_method("is_game_over") and main.is_game_over():
				set_process(false)
				disabled = true
				return
		_pick_random_path(false)
