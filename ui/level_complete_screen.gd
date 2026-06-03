extends Control
class_name LevelCompleteScreen

const WorldThemesResolve = preload("res://world_themes_resolve.gd")

const STAR_ACTIVE := Color(1, 0.92, 0.26, 1)
const STAR_DIM := Color(0.28, 0.22, 0.18, 0.5)

signal continue_pressed
signal home_pressed

@onready var _world_backdrop: TextureRect = $WorldBackdrop
@onready var hero_section: VBoxContainer = $SafeMargins/Scroll/VBoxMain/HeroSection
@onready var excellent_label: Label = $SafeMargins/Scroll/VBoxMain/HeroSection/RibbonBanner/ExcellentLabel
@onready var star_left: Label = $SafeMargins/Scroll/VBoxMain/HeroSection/StarsRow/StarLeft
@onready var star_center: Label = $SafeMargins/Scroll/VBoxMain/HeroSection/StarsRow/StarCenter
@onready var star_right: Label = $SafeMargins/Scroll/VBoxMain/HeroSection/StarsRow/StarRight
@onready var score_label: Label = $SafeMargins/Scroll/VBoxMain/ScoreLabel
@onready var level_coins_label: Label = $SafeMargins/Scroll/VBoxMain/LevelCoinsLabel
@onready var rewards_label: Label = $SafeMargins/Scroll/VBoxMain/RewardPanel/RVBox/RewardsLabel
@onready var coin_fly_anchor: Control = $SafeMargins/Scroll/VBoxMain/RewardPanel/RVBox/CoinFlyAnchor
@onready var next_button: Button = $SafeMargins/Scroll/VBoxMain/ButtonWrap/ContinueFrame/ContinueButton
@onready var reward_panel: Control = $SafeMargins/Scroll/VBoxMain/RewardPanel
@onready var hint_label: Label = $SafeMargins/Scroll/VBoxMain/RewardPanel/RVBox/Hint
@onready var _sparkle_burst: CPUParticles2D = $SparkleBurst


func _ready() -> void:
	next_button.pressed.connect(func() -> void: continue_pressed.emit())
	set_continue_enabled(false)


static func stars_from_level_time(sec: float) -> int:
	if sec < 60.0:
		return 3
	if sec < 90.0:
		return 2
	return 1


func _apply_star_row(stars_lit: int) -> void:
	stars_lit = clampi(stars_lit, 0, 3)
	var labels: Array[Label] = [star_left, star_center, star_right]
	for i in 3:
		labels[i].modulate = STAR_ACTIVE if i < stars_lit else STAR_DIM


func set_continue_enabled(enabled: bool) -> void:
	next_button.disabled = not enabled


func get_coin_fly_start_global() -> Vector2:
	if coin_fly_anchor != null:
		return coin_fly_anchor.get_global_rect().get_center()
	return get_viewport_rect().get_center()


var _coin_fly_host: Control = null


## Runs while tree is paused (this node uses process_mode = ALWAYS).
func play_coin_fly(amount: int, target_global: Vector2, done: Callable) -> void:
	if amount <= 0:
		done.call()
		return
	var host := Control.new()
	_coin_fly_host = host
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.z_index = 20
	add_child(host)
	var tex: Texture2D = load("res://gold_coin.svg") as Texture2D
	var n: int = clampi(amount / 3 + 4, 5, 14)
	var start_g: Vector2 = get_coin_fly_start_global()
	var finished: int = 0
	var emitted: bool = false
	for i in n:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(30, 30)
		tr.size = Vector2(30, 30)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		host.add_child(tr)
		var jitter := Vector2(randf_range(-28.0, 28.0), randf_range(-22.0, 22.0))
		tr.global_position = start_g - tr.size * 0.5 + jitter
		tr.pivot_offset = tr.size * 0.5
		var tw := create_tween()
		# Game tree is paused during level complete; tweens must still run.
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_interval(0.04 * float(i))
		tw.tween_property(tr, "global_position", target_global - tr.size * 0.5, 0.52).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(tr, "scale", Vector2(0.38, 0.38), 0.52)
		tw.parallel().tween_property(tr, "modulate:a", 0.7, 0.48)
		tw.tween_callback(func() -> void:
			if is_instance_valid(tr):
				tr.queue_free()
			finished += 1
			if finished >= n and not emitted:
				emitted = true
				_coin_fly_host = null
				if is_instance_valid(host):
					host.queue_free()
				done.call()
		)


func abort_coin_fly() -> void:
	if is_instance_valid(_coin_fly_host):
		_coin_fly_host.queue_free()
		_coin_fly_host = null


func show_for(completed_level: int, current_score: int, _next_level: int, run_level_coins: int, rewards_text: String, level_elapsed_sec: float) -> void:
	_apply_world_backdrop(maxi(1, completed_level))
	_apply_star_row(stars_from_level_time(level_elapsed_sec))
	excellent_label.text = "Excellent"
	score_label.text = "Score: %d" % current_score
	level_coins_label.text = "Coins this run: +%d" % run_level_coins
	rewards_label.text = rewards_text
	next_button.text = "Continue"
	visible = true
	_play_intro_sequence()


func _apply_world_backdrop(level: int) -> void:
	if not is_instance_valid(_world_backdrop):
		return
	var t: Dictionary = WorldThemesResolve.theme_for_level(level)
	var p: String = str(t.get("world_backdrop_path", t.get("playfield_texture", "")))
	var tex: Texture2D = null
	if p != "" and ResourceLoader.exists(p):
		tex = load(p) as Texture2D
	if tex == null and ResourceLoader.exists(WorldThemesResolve.FALLBACK_BG):
		tex = load(WorldThemesResolve.FALLBACK_BG) as Texture2D
	if tex == null:
		_world_backdrop.texture = null
		_world_backdrop.visible = false
		return
	_world_backdrop.texture = tex
	_world_backdrop.modulate = t.get("playfield_modulate", Color.WHITE) as Color
	_world_backdrop.visible = true


func hide_screen() -> void:
	visible = false


func _play_intro_sequence() -> void:
	# Keep gameplay paused, but UI must remain interactive after intro.
	set_continue_enabled(false)

	modulate.a = 0.0
	scale = Vector2(0.97, 0.97)
	excellent_label.scale = Vector2.ONE
	hero_section.modulate.a = 1.0

	if is_instance_valid(_sparkle_burst):
		var vr: Rect2 = get_viewport_rect()
		_sparkle_burst.position = Vector2(vr.size.x * 0.5, vr.size.y * 0.16)
		_sparkle_burst.restart()
		_sparkle_burst.emitting = true

	score_label.modulate.a = 0.0
	level_coins_label.modulate.a = 0.0
	reward_panel.modulate.a = 0.0
	next_button.modulate.a = 0.0

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(self, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Ribbon title bounce + subtle pulse.
	tw.tween_property(excellent_label, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(excellent_label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(excellent_label, "modulate:a", 1.0, 0.01)
	tw.parallel().tween_property(excellent_label, "modulate:a", 0.92, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(excellent_label, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Rewards reveal one by one.
	tw.tween_property(score_label, "modulate:a", 1.0, 0.12)
	tw.tween_property(level_coins_label, "modulate:a", 1.0, 0.12)
	tw.tween_property(reward_panel, "modulate:a", 1.0, 0.14)
	tw.tween_property(next_button, "modulate:a", 1.0, 0.10)
	tw.tween_callback(func() -> void:
		set_continue_enabled(true)
	)
