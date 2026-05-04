extends RefCounted
class_name AudioService

## Resolves the AudioManager autoload by path so scripts compile even when the
## editor analyzer does not treat project autoloads as globals.


static func _mgr() -> Object:
	var st := Engine.get_main_loop() as SceneTree
	if st == null:
		return null
	return st.root.get_node_or_null("/root/AudioManager")


static func play_coin_tap() -> void:
	var m := _mgr()
	if m:
		m.play_coin_tap()


static func play_bomb_tap() -> void:
	var m := _mgr()
	if m:
		m.play_bomb_tap()


static func play_miss() -> void:
	var m := _mgr()
	if m:
		m.play_miss()


static func play_game_over() -> void:
	var m := _mgr()
	if m:
		m.play_game_over()


static func play_button_click() -> void:
	var m := _mgr()
	if m:
		m.play_button_click()


static func play_level_up() -> void:
	var m := _mgr()
	if m:
		m.play_level_up()


static func get_music_enabled() -> bool:
	var m := _mgr()
	if m == null:
		return true
	return bool(m.get("music_enabled"))


static func get_sfx_enabled() -> bool:
	var m := _mgr()
	if m == null:
		return true
	return bool(m.get("sfx_enabled"))


static func set_music_enabled(on: bool) -> void:
	var m := _mgr()
	if m:
		m.set_music_enabled(on)


static func set_sfx_enabled(on: bool) -> void:
	var m := _mgr()
	if m:
		m.set_sfx_enabled(on)
