extends Control

## -1 = none, 0 = lightning (slower drops), 1 = hourglass (extra life this run)
signal play_again_pressed(booster_id: int)
signal home_pressed

const MAX_RETRIES_DISPLAY: int = 5

@onready var final_score_label: Label = $Center/MainColumn/ScoreColumn/FinalScoreLabel
@onready var coins_lost_label: Label = $Center/MainColumn/ScoreColumn/CoinsLostLabel
@onready var best_score_label: Label = $Center/MainColumn/ScoreColumn/BestScoreLabel
@onready var retries_label: Label = $Center/MainColumn/RetriesLabel
@onready var minus_badge: Label = $Center/MainColumn/HeartRow/HeartPanel/MinusBadge
@onready var booster_lightning: Button = $Center/MainColumn/BoosterRow/LightningBooster
@onready var booster_hourglass: Button = $Center/MainColumn/BoosterRow/HourglassBooster
@onready var lightning_count_label: Label = $Center/MainColumn/BoosterRow/LightningBooster/Badge/Count
@onready var hourglass_count_label: Label = $Center/MainColumn/BoosterRow/HourglassBooster/Badge/Count
@onready var retry_button: Button = $Center/MainColumn/RetryButton
@onready var home_button: Button = $Center/MainColumn/HomeButton
@onready var close_button: Button = $CloseButton


func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	home_button.pressed.connect(_on_home_button_pressed)
	close_button.pressed.connect(func() -> void: home_pressed.emit())
	booster_lightning.toggled.connect(_on_lightning_toggled)
	booster_hourglass.toggled.connect(_on_hourglass_toggled)


func _on_lightning_toggled(pressed: bool) -> void:
	if pressed:
		booster_hourglass.set_pressed_no_signal(false)


func _on_hourglass_toggled(pressed: bool) -> void:
	if pressed:
		booster_lightning.set_pressed_no_signal(false)


## Which “strike” this fail is (1…5) from charges remaining: first fail −1, after 4 retries then fail −5.
func _strike_index_from_charges(charges: int) -> int:
	return clampi(MAX_RETRIES_DISPLAY - charges + 1, 1, MAX_RETRIES_DISPLAY)


func _fmt_hms(secs: int) -> String:
	var s: int = maxi(0, secs)
	var h: int = s / 3600
	var m: int = (s % 3600) / 60
	var sec: int = s % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, sec]
	return "%02d:%02d" % [m, sec]


func refresh_retry_ui(charges: int, wait_sec: int) -> void:
	if not visible:
		return
	retries_label.text = "Retries left: %d / %d" % [charges, MAX_RETRIES_DISPLAY]
	minus_badge.text = "-%d" % _strike_index_from_charges(charges)
	if wait_sec > 0:
		retry_button.disabled = true
		retry_button.text = "Wait %s" % _fmt_hms(wait_sec)
	else:
		retry_button.disabled = false
		retry_button.text = "Retry"


func _on_home_button_pressed() -> void:
	home_pressed.emit()


func _on_retry_pressed() -> void:
	if retry_button.disabled:
		return
	var id: int = -1
	if booster_lightning.button_pressed and booster_lightning.visible and not booster_lightning.disabled:
		var n: int = int(lightning_count_label.text)
		if n > 0:
			id = 0
	elif booster_hourglass.button_pressed and booster_hourglass.visible and not booster_hourglass.disabled:
		var n2: int = int(hourglass_count_label.text)
		if n2 > 0:
			id = 1
	play_again_pressed.emit(id)


func show_results(final_score: int, best: int, lightning_left: int, hourglass_left: int, retries_left: int, retry_wait_sec: int, run_coins_lost: int = 0) -> void:
	final_score_label.text = "Score: %d" % final_score
	if coins_lost_label != null:
		if run_coins_lost > 0:
			coins_lost_label.text = "Coins not banked: %d — finish a level to send them to your vault." % run_coins_lost
			coins_lost_label.visible = true
		else:
			coins_lost_label.visible = false
	best_score_label.text = "Best: %d" % best
	lightning_count_label.text = str(lightning_left)
	hourglass_count_label.text = str(hourglass_left)
	booster_lightning.disabled = lightning_left <= 0
	booster_hourglass.disabled = hourglass_left <= 0
	booster_lightning.modulate = Color(1, 1, 1, 1) if lightning_left > 0 else Color(0.55, 0.55, 0.6, 1)
	booster_hourglass.modulate = Color(1, 1, 1, 1) if hourglass_left > 0 else Color(0.55, 0.55, 0.6, 1)
	booster_lightning.set_pressed_no_signal(false)
	booster_hourglass.set_pressed_no_signal(false)
	visible = true
	refresh_retry_ui(retries_left, retry_wait_sec)


func hide_screen() -> void:
	visible = false
