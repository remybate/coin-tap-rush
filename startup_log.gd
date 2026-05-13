extends Node

## Runs first (listed first under [autoload]) so boot issues show in `adb logcat` / Godot prints.


func _ready() -> void:
	var t0: int = Time.get_ticks_msec()
	print("[StartupLog] Coin Tap Rush boot t=", t0, "ms OS=", OS.get_name())
	if OS.has_feature("android"):
		print("[StartupLog] Android model=", OS.get_model_name())
	print("[StartupLog] Godot ", Engine.get_version_info())
	var ra: String = str(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	print("[StartupLog] rendering_method=", ra)
