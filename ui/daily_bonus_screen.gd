extends Control
class_name DailyBonusScreen

signal bonus_claimed(amount: int)

@onready var title_label: Label = $Center/Panel/Margin/VBox/Title
@onready var subtitle_label: Label = $Center/Panel/Margin/VBox/Subtitle
@onready var bonus_70_button: Button = $Center/Panel/Margin/VBox/Bonus70
@onready var bonus_120_button: Button = $Center/Panel/Margin/VBox/Bonus120
@onready var bonus_200_button: Button = $Center/Panel/Margin/VBox/Bonus200
@onready var close_x: Button = $CloseX


func _ready() -> void:
	bonus_70_button.pressed.connect(func() -> void: _claim_bonus(70))
	bonus_120_button.pressed.connect(func() -> void: _claim_bonus(120))
	bonus_200_button.pressed.connect(func() -> void: _claim_bonus(200))
	close_x.pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	AudioService.play_button_click()
	hide_bonus()


func show_for_day(day_num: int) -> void:
	var d: int = clampi(day_num, 1, 7)
	title_label.text = "Daily Bonus - Day %d" % d
	subtitle_label.text = "Welcome back! Pick one bonus and get extra coins instantly."
	visible = true


func hide_bonus() -> void:
	visible = false


func _claim_bonus(amount: int) -> void:
	AudioService.play_button_click()
	hide_bonus()
	bonus_claimed.emit(amount)
