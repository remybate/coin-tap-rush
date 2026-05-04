extends Node2D

## Taps needed to reach the next level (level 1 = score 0 .. POINTS_PER_LEVEL-1).
const POINTS_PER_LEVEL: int = 12
## Level 1: slow fall. Each extra level adds this much to min/max speed (pixels/sec).
const SPEED_LVL1_MIN: float = 78.0
const SPEED_LVL1_MAX: float = 112.0
const SPEED_BUMP_PER_LEVEL: float = 16.0
## Lives (shown as hearts). Game over when this hits zero.
const MAX_LIVES: int = 3
const HEART_EMOJI: String = "❤️"
## Playfield: coins that fall below this Y (viewport pixels) count as missed — aligns with bottom HUD strip.
const BOTTOM_HUD_RESERVE_PX: float = 128.0

var score: int = 0
var lives: int = MAX_LIVES
var missed_coins: int = 0
var game_over: bool = false

@onready var score_label: Label = $CanvasLayer/TopBar/Margin/Row/ScoreLabel
@onready var lives_label: Label = $CanvasLayer/TopBar/Margin/Row/LivesLabel
@onready var level_label: Label = $CanvasLayer/TopBar/Margin/Row/LevelLabel
@onready var miss_summary_label: Label = $CanvasLayer/BottomBar/Margin/VBox/MissSummaryLabel
@onready var warning_label: Label = $CanvasLayer/BottomBar/Margin/VBox/WarningLabel
@onready var game_over_overlay: Control = $CanvasLayer/GameOverOverlay
@onready var final_score_label: Label = $CanvasLayer/GameOverOverlay/Center/VBox/FinalScoreLabel
@onready var play_again_button: Button = $CanvasLayer/GameOverOverlay/Center/VBox/PlayAgainButton


func _ready() -> void:
	add_to_group("main")
	play_again_button.pressed.connect(_on_play_again_pressed)
	_refresh_ui()


func get_danger_y() -> float:
	var h: float = max(get_viewport_rect().size.y, 600.0)
	return h - BOTTOM_HUD_RESERVE_PX


func is_game_over() -> bool:
	return game_over


func get_level() -> int:
	return score / POINTS_PER_LEVEL + 1


func get_fall_speed_range() -> Vector2:
	var lvl: int = get_level()
	var t: float = float(lvl - 1)
	var mn: float = SPEED_LVL1_MIN + t * SPEED_BUMP_PER_LEVEL
	var mx: float = SPEED_LVL1_MAX + t * SPEED_BUMP_PER_LEVEL * 1.06
	return Vector2(mn, mx)


func register_collectible(k: Collectible.Kind) -> void:
	if game_over:
		return
	match k:
		Collectible.Kind.GOLD:
			score += 1
		Collectible.Kind.SILVER_BIG:
			score += 5
		Collectible.Kind.DIAMOND:
			score += 10
		Collectible.Kind.BOMB:
			lives -= 1
			_refresh_ui()
			if lives <= 0:
				_trigger_game_over()
			return
	_refresh_ui()


func register_miss() -> void:
	if game_over:
		return
	lives -= 1
	missed_coins += 1
	_refresh_ui()
	if lives <= 0:
		_trigger_game_over()


func _trigger_game_over() -> void:
	if game_over:
		return
	game_over = true
	final_score_label.text = "Final score: %d" % score
	game_over_overlay.visible = true
	for c in get_tree().get_nodes_in_group("coin"):
		c.set_process(false)
		c.disabled = true


func _on_play_again_pressed() -> void:
	game_over = false
	score = 0
	lives = MAX_LIVES
	missed_coins = 0
	game_over_overlay.visible = false
	for c in get_tree().get_nodes_in_group("coin"):
		if c.has_method("reset_for_new_game"):
			c.reset_for_new_game()
	_refresh_ui()


func _lives_text() -> String:
	var hearts := ""
	for _i in range(max(lives, 0)):
		hearts += HEART_EMOJI
	return "Lives: %s" % hearts


func _refresh_ui() -> void:
	if score_label:
		score_label.text = "Score: %d" % score
	if lives_label:
		lives_label.text = _lives_text()
	if level_label:
		level_label.text = "Level: %d" % get_level()
	if miss_summary_label:
		miss_summary_label.text = "Missed coins: %d" % missed_coins
	if warning_label:
		if game_over:
			warning_label.text = "Game over — tap Play Again to retry."
		elif lives <= 1:
			warning_label.add_theme_color_override("font_color", Color(1, 0.55, 0.45))
			warning_label.text = "Danger: last life! Avoid red bombs (tap). Catch gold, big silver (+5), and diamonds (+10)."
		elif lives == 2:
			warning_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
			warning_label.text = "Warning: red bombs cost a life if tapped. Missed gold or gems in the red zone cost a life."
		else:
			warning_label.add_theme_color_override("font_color", Color(0.62, 0.7, 0.8))
			warning_label.text = "Gold +1, big silver +5, diamond +10. Bombs −1 life. Letting gold or gems hit the strip costs a life."
