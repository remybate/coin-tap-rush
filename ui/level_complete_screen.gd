extends Control
class_name LevelCompleteScreen

const WorldThemesResolve = preload("res://world_themes_resolve.gd")

signal continue_pressed
signal home_pressed

@onready var _world_backdrop: TextureRect = $WorldBackdrop
@onready var title_label: Label = $Center/MainPanel/InnerMargin/VBox/TitleLabel
@onready var score_label: Label = $Center/MainPanel/InnerMargin/VBox/ScoreLabel
@onready var level_coins_label: Label = $Center/MainPanel/InnerMargin/VBox/LevelCoinsLabel
@onready var rewards_label: Label = $Center/MainPanel/InnerMargin/VBox/RewardPanel/RVBox/RewardsLabel
@onready var coin_fly_anchor: Control = $Center/MainPanel/InnerMargin/VBox/RewardPanel/RVBox/CoinFlyAnchor
@onready var next_button: Button = $Center/MainPanel/InnerMargin/VBox/ButtonWrap/ButtonRow/ContinueButton
@onready var home_button: Button = $Center/MainPanel/InnerMargin/VBox/ButtonWrap/ButtonRow/HomeButton
@onready var reward_panel: Control = $Center/MainPanel/InnerMargin/VBox/RewardPanel
@onready var hint_label: Label = $Center/MainPanel/InnerMargin/VBox/RewardPanel/RVBox/Hint
@onready var close_button_top: Button = $CloseButton
@onready var _dim: ColorRect = $Dim
@onready var _sparkle_burst: CPUParticles2D = $SparkleBurst


func _ready() -> void:
	next_button.pressed.connect(func() -> void: continue_pressed.emit())
	home_button.pressed.connect(func() -> void: home_pressed.emit())
	close_button_top.pressed.connect(func() -> void: home_pressed.emit())
	_dim.gui_input.connect(_on_dim_gui_input)
	set_continue_enabled(false)


func set_continue_enabled(enabled: bool) -> void:
	next_button.disabled = not enabled
	home_button.disabled = not enabled
	# Keep ✕ always tappable so players can exit even during intro / fly FX.
	close_button_top.disabled = false


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		home_pressed.emit()


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


func show_for(completed_level: int, current_score: int, next_level: int, run_level_coins: int, rewards_text: String) -> void:
	_apply_world_backdrop(maxi(1, completed_level))
	title_label.text = "LEVEL %d\nCOMPLETE!" % completed_level
	score_label.text = "Score: %d" % current_score
	level_coins_label.text = "Coins this run: +%d" % run_level_coins
	rewards_label.text = rewards_text
	next_button.text = "Continue → Level %d" % next_level
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
	scale = Vector2(0.9, 0.9)
	title_label.scale = Vector2.ONE

	if is_instance_valid(_sparkle_burst):
		var vr: Rect2 = get_viewport_rect()
		_sparkle_burst.position = Vector2(vr.size.x * 0.5, vr.size.y * 0.16)
		_sparkle_burst.restart()
		_sparkle_burst.emitting = true

	score_label.modulate.a = 0.0
	level_coins_label.modulate.a = 0.0
	reward_panel.modulate.a = 0.0
	next_button.modulate.a = 0.0
	home_button.modulate.a = 0.0

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(self, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Title bounce + subtle glow pulse (by modulating alpha).
	tw.tween_property(title_label, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(title_label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(title_label, "modulate:a", 1.0, 0.01)
	tw.parallel().tween_property(title_label, "modulate:a", 0.92, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(title_label, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Rewards reveal one by one.
	tw.tween_property(score_label, "modulate:a", 1.0, 0.12)
	tw.tween_property(level_coins_label, "modulate:a", 1.0, 0.12)
	tw.tween_property(reward_panel, "modulate:a", 1.0, 0.14)
	tw.tween_property(home_button, "modulate:a", 1.0, 0.10)
	tw.tween_property(next_button, "modulate:a", 1.0, 0.10)
	tw.tween_callback(func() -> void:
		set_continue_enabled(true)
	)
