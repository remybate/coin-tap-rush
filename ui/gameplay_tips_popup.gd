extends Control

## In-game tips / tutorial overlay (not the main-menu How To Play).

signal closed

const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SECTION: String = "settings"
const KEY_HIDE_AUTO: String = "gameplay_tips_hide_auto"

@onready var _dim: ColorRect = $Dim
@onready var _panel: PanelContainer = $Center/Panel
@onready var _title: Label = $Center/Panel/Margin/VBox/Title
@onready var _scroll: ScrollContainer = $Center/Panel/Margin/VBox/Scroll
@onready var _body: Label = $Center/Panel/Margin/VBox/Scroll/Body
@onready var _dont_again: CheckBox = $Center/Panel/Margin/VBox/FooterRow/DontAgain
@onready var _close: Button = $Center/Panel/Margin/VBox/FooterRow/CloseBtn


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _dim:
		_dim.gui_input.connect(_on_dim_gui_input)
	if _close:
		_close.pressed.connect(_on_close_pressed)


func should_suppress_auto() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	return bool(cfg.get_value(SECTION, KEY_HIDE_AUTO, false))


func set_suppress_auto(on: bool) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	cfg.set_value(SECTION, KEY_HIDE_AUTO, on)
	cfg.save(SAVE_PATH)


func present(title: String, body_text: String) -> void:
	if _title:
		_title.text = title
	if _body:
		_body.text = body_text
	if _dont_again:
		_dont_again.button_pressed = false
	visible = true
	if _panel:
		_panel.scale = Vector2(0.92, 0.92)
		_panel.modulate.a = 0.0
		var tw := create_tween()
		tw.set_ease(Tween.EASE_OUT)
		tw.set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
		tw.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.28)


func hide_popup() -> void:
	if not visible:
		return
	if _dont_again != null and _dont_again.button_pressed:
		set_suppress_auto(true)
	if _panel == null:
		visible = false
		closed.emit()
		return
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.16)
	tw.parallel().tween_property(_panel, "scale", Vector2(0.94, 0.94), 0.18)
	await tw.finished
	visible = false
	closed.emit()


func _on_close_pressed() -> void:
	hide_popup()


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_popup()
