extends Control
class_name SettingsScreen

signal closed
signal progress_reset

@onready var music_check: CheckButton = $Center/Panel/Margin/VBox/MusicCheck
@onready var sfx_check: CheckButton = $Center/Panel/Margin/VBox/SfxCheck
@onready var vibration_check: CheckButton = $Center/Panel/Margin/VBox/VibrationCheck
@onready var reset_button: Button = $Center/Panel/Margin/VBox/ResetProgressButton
@onready var reset_hint: Label = $Center/Panel/Margin/VBox/ResetHint
@onready var close_button: Button = $Center/Panel/Margin/VBox/CloseButton
@onready var close_x: Button = $CloseX

const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SECTION_SETTINGS: String = "settings"
const KEY_VIBRATION: String = "vibration_on"

var _reset_armed: bool = false


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	close_x.pressed.connect(_on_close_pressed)
	music_check.toggled.connect(_on_music_toggled)
	sfx_check.toggled.connect(_on_sfx_toggled)
	vibration_check.toggled.connect(_on_vibration_toggled)
	reset_button.pressed.connect(_on_reset_pressed)
	reset_hint.visible = false


func open_settings() -> void:
	music_check.set_pressed_no_signal(AudioService.get_music_enabled())
	sfx_check.set_pressed_no_signal(AudioService.get_sfx_enabled())
	vibration_check.set_pressed_no_signal(_read_vibration_enabled())
	_reset_armed = false
	reset_button.text = "Reset progress"
	reset_hint.visible = false
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


func _read_vibration_enabled() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return true
	return bool(cfg.get_value(SECTION_SETTINGS, KEY_VIBRATION, true))


func _write_vibration_enabled(on: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value(SECTION_SETTINGS, KEY_VIBRATION, on)
	cfg.save(SAVE_PATH)


func _on_vibration_toggled(pressed: bool) -> void:
	_write_vibration_enabled(pressed)
	if pressed:
		# No-op on desktop; on mobile this gives immediate feedback.
		Input.vibrate_handheld(30)


func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		reset_button.text = "Tap again to confirm reset"
		reset_hint.text = "This resets your vault progress: coins, boosters, trophies, daily streak, and card unlocks. Audio/vibration settings stay."
		reset_hint.visible = true
		return

	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	if cfg.has_section("progress"):
		cfg.erase_section("progress")
	if cfg.has_section("daily_missions"):
		cfg.erase_section("daily_missions")
	cfg.save(SAVE_PATH)

	_reset_armed = false
	reset_button.text = "Reset progress"
	reset_hint.visible = false
	progress_reset.emit()
