extends Control

signal play_pressed(use_bomb_clear: bool, use_start_slow: bool)
signal closed_popup

@onready var _dim: ColorRect = $Dim
@onready var _close_x: Button = $CloseX
@onready var _play_btn: Button = $Center/Panel/Margin/Root/Footer/PlayButton
@onready var _card_bomb: PanelContainer = $Center/Panel/Margin/Root/CardsRow/BombClearCard
@onready var _card_slow: PanelContainer = $Center/Panel/Margin/Root/CardsRow/StartSlowCard
@onready var _toggle_bomb: CheckButton = $Center/Panel/Margin/Root/CardsRow/BombClearCard/Margin/VBox/Toggle
@onready var _toggle_slow: CheckButton = $Center/Panel/Margin/Root/CardsRow/StartSlowCard/Margin/VBox/Toggle
@onready var _count_bomb: Label = $Center/Panel/Margin/Root/CardsRow/BombClearCard/Margin/VBox/CountLabel
@onready var _count_slow: Label = $Center/Panel/Margin/Root/CardsRow/StartSlowCard/Margin/VBox/CountLabel
@onready var _hint: Label = $Center/Panel/Margin/Root/HintLabel

var _stock_bomb_clear: int = 0
var _stock_start_slow: int = 0
var _hourglass_milestone_ok: bool = true


func _ready() -> void:
	_close_x.pressed.connect(_on_close)
	_play_btn.pressed.connect(_on_play)
	_toggle_bomb.toggled.connect(_on_bomb_toggled)
	_toggle_slow.toggled.connect(_on_slow_toggled)


func present(bomb_clear_stock: int, start_slow_stock: int, furthest_unlocked: int = 999999) -> void:
	_stock_bomb_clear = maxi(0, bomb_clear_stock)
	_stock_start_slow = maxi(0, start_slow_stock)
	_hourglass_milestone_ok = LevelProgression.is_booster_unlocked("pregame_hourglass", furthest_unlocked)
	_toggle_bomb.set_pressed_no_signal(false)
	_toggle_slow.set_pressed_no_signal(false)
	_refresh_counts()
	_apply_lock_styles()
	_hint.text = "Pick up to two charms, or tap Play with none — your river, your rules."
	visible = true


func _refresh_counts() -> void:
	_count_bomb.text = "×%d" % _stock_bomb_clear
	_count_slow.text = "×%d" % _stock_start_slow


func _apply_lock_styles() -> void:
	_toggle_bomb.disabled = _stock_bomb_clear <= 0
	_toggle_slow.disabled = _stock_start_slow <= 0 or not _hourglass_milestone_ok
	_card_bomb.modulate = Color(1, 1, 1, 1) if _stock_bomb_clear > 0 else Color(0.55, 0.58, 0.65, 0.9)
	var slow_ok: bool = _stock_start_slow > 0 and _hourglass_milestone_ok
	_card_slow.modulate = Color(1, 1, 1, 1) if slow_ok else Color(0.55, 0.58, 0.65, 0.9)


func _selected_count() -> int:
	var n: int = 0
	if _toggle_bomb.button_pressed and _stock_bomb_clear > 0:
		n += 1
	if _toggle_slow.button_pressed and _stock_start_slow > 0 and _hourglass_milestone_ok:
		n += 1
	return n


func _on_bomb_toggled(pressed: bool) -> void:
	if pressed and _stock_bomb_clear <= 0:
		_toggle_bomb.set_pressed_no_signal(false)
		return
	if pressed and _selected_count() > 2:
		_toggle_bomb.set_pressed_no_signal(false)


func _on_slow_toggled(pressed: bool) -> void:
	if pressed and (_stock_start_slow <= 0 or not _hourglass_milestone_ok):
		_toggle_slow.set_pressed_no_signal(false)
		return
	if pressed and _selected_count() > 2:
		_toggle_slow.set_pressed_no_signal(false)


func _on_play() -> void:
	AudioService.play_button_click()
	var u_bc: bool = _toggle_bomb.button_pressed and _stock_bomb_clear > 0
	var u_ss: bool = _toggle_slow.button_pressed and _stock_start_slow > 0 and _hourglass_milestone_ok
	visible = false
	play_pressed.emit(u_bc, u_ss)


func _on_close() -> void:
	AudioService.play_button_click()
	visible = false
	closed_popup.emit()
