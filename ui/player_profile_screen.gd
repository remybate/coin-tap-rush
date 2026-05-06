extends Control

const PlayerProfileResolve = preload("res://player_profile_resolve.gd")

signal closed
signal avatar_changed

const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"

@onready var _dim: ColorRect = $Dim
@onready var _panel: PanelContainer = $Center/Panel
@onready var _badge_tier: Label = $Center/Panel/Margin/VBox/BadgeRow/BadgeTier
@onready var _badge_rank: Label = $Center/Panel/Margin/VBox/BadgeRow/BadgeRank
@onready var _title_lbl: Label = $Center/Panel/Margin/VBox/TitleLabel
@onready var _level_lbl: Label = $Center/Panel/Margin/VBox/LevelRow/LevelLabel
@onready var _xp_bar: ProgressBar = $Center/Panel/Margin/VBox/XpBar
@onready var _xp_hint: Label = $Center/Panel/Margin/VBox/XpHint
@onready var _avatar_row: HBoxContainer = $Center/Panel/Margin/VBox/AvatarRow
@onready var _close_btn: Button = $Center/Panel/Margin/VBox/CloseBtn


func _ready() -> void:
	hide()
	_close_btn.pressed.connect(_on_close)
	_dim.gui_input.connect(_on_dim)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.18, 0.9, 0.5, 1)
	_xp_bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.12, 0.2, 1)
	_xp_bar.add_theme_stylebox_override("background", bg)
	_build_avatar_buttons()


func _on_close() -> void:
	AudioService.play_button_click()
	hide()
	closed.emit()


func _on_dim(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close()


func open_profile() -> void:
	_refresh()
	show()


func _refresh() -> void:
	var pp: Node = PlayerProfileResolve.node()
	if pp == null:
		_badge_tier.text = "—"
		_badge_rank.text = ""
		_title_lbl.text = "Profile unavailable"
		_level_lbl.text = "Player Lv. —"
		_xp_bar.max_value = 1.0
		_xp_bar.value = 0.0
		_xp_hint.text = ""
		return

	var cfg := ConfigFile.new()
	var xp: int = 0
	var av_id: int = 0
	if cfg.load(SAVE_PATH) == OK:
		xp = pp.read_xp_from_cfg(cfg)
		av_id = pp.read_avatar_from_cfg(cfg)
	var lv: int = pp.player_level_from_xp(xp)
	var fixed_av: int = pp.clamp_avatar_to_unlocked(av_id, lv)
	if fixed_av != av_id:
		if cfg.load(SAVE_PATH) == OK:
			pp.write_avatar_on_cfg(cfg, fixed_av)
			cfg.save(SAVE_PATH)
		av_id = fixed_av
	var prog: Dictionary = pp.xp_progress_in_level(xp)
	var bd: Dictionary = pp.rank_badge_for_level(lv)
	_badge_tier.text = str(bd.get("tier", ""))
	_badge_rank.text = str(bd.get("rank", ""))
	_badge_tier.add_theme_color_override("font_color", bd.get("accent", Color.WHITE))
	_badge_rank.add_theme_color_override("font_color", bd.get("accent", Color.WHITE))
	_title_lbl.text = pp.title_for_level(lv)
	_level_lbl.text = "Player Lv. %d" % int(prog.get("level", 1))
	_xp_bar.max_value = float(prog.get("span", 1))
	_xp_bar.value = float(prog.get("into", 0))
	_xp_hint.text = "%d / %d XP this level" % [int(prog.get("into", 0)), int(prog.get("span", 1))]
	_refresh_avatar_buttons(lv, av_id)


func _build_avatar_buttons() -> void:
	for c in _avatar_row.get_children():
		c.queue_free()
	var pp: Node = PlayerProfileResolve.node()
	if pp == null:
		return
	for d in pp.avatar_defs():
		var id: int = int(d["id"])
		var b := Button.new()
		b.custom_minimum_size = Vector2(72, 72)
		b.focus_mode = Control.FOCUS_NONE
		b.text = str(d["emoji"]) + "\n" + str(d["name"])
		b.add_theme_font_size_override("font_size", 22)
		b.set_meta("avatar_id", id)
		b.pressed.connect(_on_avatar_picked.bind(id))
		_avatar_row.add_child(b)


func _refresh_avatar_buttons(player_lv: int, selected_id: int) -> void:
	var pp: Node = PlayerProfileResolve.node()
	for b in _avatar_row.get_children():
		if not b is Button:
			continue
		var id: int = int(b.get_meta("avatar_id", 0))
		var ok: bool = pp.avatar_unlocked(id, player_lv) if pp != null else false
		b.disabled = not ok
		b.modulate = Color(1, 1, 1, 1) if ok else Color(0.45, 0.45, 0.5, 0.85)
		if id == selected_id:
			b.add_theme_color_override("font_outline_color", Color(1, 0.85, 0.2, 1))
			b.add_theme_constant_override("outline_size", 5)
		else:
			b.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.14, 1))
			b.add_theme_constant_override("outline_size", 3)


func _on_avatar_picked(id: int) -> void:
	var pp: Node = PlayerProfileResolve.node()
	if pp == null:
		return
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var lv: int = pp.player_level_from_xp(pp.read_xp_from_cfg(cfg))
	if not pp.avatar_unlocked(id, lv):
		AudioService.play_button_click()
		return
	pp.write_avatar_on_cfg(cfg, id)
	cfg.save(SAVE_PATH)
	AudioService.play_coin_tap()
	_refresh_avatar_buttons(lv, id)
	avatar_changed.emit()
