extends Control
class_name TreasureChestPopup

signal finished
signal chest_opened_applied

@onready var _dim: ColorRect = $Dim
@onready var _panel: PanelContainer = $Center/Panel
@onready var _title: Label = $Center/Panel/Margin/VBox/TitleLabel
@onready var _subtitle: Label = $Center/Panel/Margin/VBox/SubtitleLabel
@onready var _chest_host: Control = $Center/Panel/Margin/VBox/ChestHost
@onready var _chest_body: TextureRect = $Center/Panel/Margin/VBox/ChestHost/Body
@onready var _chest_lid: TextureRect = $Center/Panel/Margin/VBox/ChestHost/Lid
@onready var _flash: ColorRect = $Center/Panel/Margin/VBox/ChestHost/Flash
@onready var _rewards_vbox: VBoxContainer = $Center/Panel/Margin/VBox/RewardsVBox
@onready var _claim: Button = $Center/Panel/Margin/VBox/ClaimButton


func _ready() -> void:
	visible = false
	_claim.pressed.connect(_on_claim_pressed)
	_style_claim_button()


func _style_claim_button() -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.14, 0.88, 0.48, 1)
	n.border_color = Color(0.98, 0.82, 0.22, 1)
	n.border_width_left = 4
	n.border_width_top = 4
	n.border_width_right = 4
	n.border_width_bottom = 8
	n.corner_radius_top_left = 22
	n.corner_radius_top_right = 22
	n.corner_radius_bottom_right = 22
	n.corner_radius_bottom_left = 22
	n.shadow_size = 12
	n.shadow_offset = Vector2(0, 5)
	n.shadow_color = Color(0.02, 0.35, 0.12, 0.45)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.26, 0.96, 0.58, 1)
	var p := n.duplicate() as StyleBoxFlat
	p.bg_color = Color(0.1, 0.72, 0.4, 1)
	_claim.add_theme_stylebox_override("normal", n)
	_claim.add_theme_stylebox_override("hover", h)
	_claim.add_theme_stylebox_override("pressed", p)
	_claim.add_theme_stylebox_override("focus", n)


func _on_claim_pressed() -> void:
	AudioService.play_button_click()
	visible = false
	finished.emit()


func open_chest():
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var res: Dictionary = TreasureChestProgress.try_open_one_chest(rng)
	if not bool(res.get("ok", false)):
		visible = false
		return
	chest_opened_applied.emit()
	_title.text = "Treasure chest!"
	_subtitle.text = "The latch snaps — loot within!"
	_claim.disabled = true
	_prep_rewards(res)
	visible = true
	await get_tree().process_frame
	_rewards_vbox.modulate.a = 0.0
	_rewards_vbox.scale = Vector2(0.88, 0.88)
	_chest_host.scale = Vector2(0.72, 0.72)
	_chest_host.rotation_degrees = -5.0
	_chest_lid.rotation_degrees = 0.0
	_chest_lid.position = Vector2(40.0, 12.0)
	_flash.visible = true
	_flash.color = Color(1.0, 0.92, 0.45, 0.0)
	_panel.pivot_offset = _panel.size * 0.5
	if _panel.pivot_offset.length_squared() < 1.0:
		_panel.pivot_offset = Vector2(270, 280)
	_panel.scale = Vector2(0.9, 0.9)
	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.16)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain()
	tw.set_parallel(true)
	tw.tween_property(_chest_host, "scale", Vector2(1.1, 1.1), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_chest_host, "rotation_degrees", 0.0, 0.22)
	tw.chain()
	tw.set_parallel(true)
	tw.tween_property(_chest_lid, "rotation_degrees", -28.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_chest_lid, "position", Vector2(34.0, 2.0), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_flash, "color:a", 0.52, 0.12)
	tw.chain()
	tw.tween_property(_flash, "color:a", 0.0, 0.26)
	tw.chain().tween_callback(func() -> void:
		AudioService.play_coin_tap()
	)
	tw.set_parallel(true)
	tw.tween_property(_rewards_vbox, "modulate:a", 1.0, 0.2)
	tw.tween_property(_rewards_vbox, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_chest_host, "scale", Vector2.ONE, 0.2)
	tw.chain().tween_callback(func() -> void:
		_claim.disabled = false
	)


func _prep_rewards(res: Dictionary) -> void:
	for c in _rewards_vbox.get_children():
		c.queue_free()
	var lines: Array = res.get("lines", [])
	for line in lines:
		var lbl := Label.new()
		lbl.text = str(line)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 26)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.62, 1))
		lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.22, 1))
		lbl.add_theme_constant_override("outline_size", 6)
		_rewards_vbox.add_child(lbl)
