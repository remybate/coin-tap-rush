extends Control
class_name LevelCompleteScreen

signal continue_pressed
signal home_pressed

@onready var title_label: Label = $Center/VBox/TitleLabel
@onready var score_label: Label = $Center/VBox/ScoreLabel
@onready var level_coins_label: Label = $Center/VBox/LevelCoinsLabel
@onready var rewards_label: Label = $Center/VBox/RewardPanel/RVBox/RewardsLabel
@onready var coin_fly_anchor: Control = $Center/VBox/RewardPanel/RVBox/CoinFlyAnchor
@onready var next_button: Button = $Center/VBox/ButtonRow/ContinueButton
@onready var home_button: Button = $Center/VBox/ButtonRow/HomeButton


func _ready() -> void:
	next_button.pressed.connect(func() -> void: continue_pressed.emit())
	home_button.pressed.connect(func() -> void: home_pressed.emit())


func set_continue_enabled(enabled: bool) -> void:
	next_button.disabled = not enabled
	home_button.disabled = not enabled


func get_coin_fly_start_global() -> Vector2:
	if coin_fly_anchor != null:
		return coin_fly_anchor.get_global_rect().get_center()
	return get_viewport_rect().get_center()


## Runs while tree is paused (this node uses process_mode = ALWAYS).
func play_coin_fly(amount: int, target_global: Vector2, done: Callable) -> void:
	if amount <= 0:
		done.call()
		return
	var host := Control.new()
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
				if is_instance_valid(host):
					host.queue_free()
				done.call()
		)


func show_for(completed_level: int, current_score: int, next_level: int, run_level_coins: int, rewards_text: String) -> void:
	title_label.text = "Level %d complete!" % completed_level
	score_label.text = "Score: %d" % current_score
	level_coins_label.text = "Coins this run: +%d" % run_level_coins
	rewards_label.text = rewards_text
	next_button.text = "Continue → Level %d" % next_level
	set_continue_enabled(false)
	visible = true


func hide_screen() -> void:
	visible = false
