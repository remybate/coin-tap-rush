extends Control
class_name SettingsScreen

signal closed

@onready var music_check: CheckButton = $Center/Panel/Margin/VBox/MusicCheck
@onready var sfx_check: CheckButton = $Center/Panel/Margin/VBox/SfxCheck
@onready var close_button: Button = $Center/Panel/Margin/VBox/CloseButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	music_check.toggled.connect(_on_music_toggled)
	sfx_check.toggled.connect(_on_sfx_toggled)


func open_settings() -> void:
	music_check.set_pressed_no_signal(AudioService.get_music_enabled())
	sfx_check.set_pressed_no_signal(AudioService.get_sfx_enabled())
	visible = true


func close_settings() -> void:
	visible = false
	closed.emit()


func _on_close_pressed() -> void:
	AudioService.play_button_click()
	close_settings()


func _on_music_toggled(pressed: bool) -> void:
	AudioService.set_music_enabled(pressed)


func _on_sfx_toggled(pressed: bool) -> void:
	AudioService.set_sfx_enabled(pressed)
