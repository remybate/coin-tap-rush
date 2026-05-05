extends Control
class_name SimplePopup

signal closed

@onready var title_label: Label = $Center/Panel/Margin/VBox/Title
@onready var body_label: Label = $Center/Panel/Margin/VBox/Body
@onready var close_x: Button = $CloseX
@onready var close_button: Button = $Center/Panel/Margin/VBox/CloseButton


func _ready() -> void:
	close_x.pressed.connect(_on_close_pressed)
	close_button.pressed.connect(_on_close_pressed)


func open_popup(title: String, body: String) -> void:
	title_label.text = title
	body_label.text = body
	visible = true


func close_popup() -> void:
	visible = false
	closed.emit()


func _on_close_pressed() -> void:
	AudioService.play_button_click()
	close_popup()

