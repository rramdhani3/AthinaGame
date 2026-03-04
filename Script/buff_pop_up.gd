extends Control

@onready var blur_overlay = $BlurOverlay
@onready var buttons = [$VBoxContainer/Buff1, $VBoxContainer/Buff2, $VBoxContainer/Buff3]
@onready var content = $VBoxContainer

var buff_pool = ["speed", "damage", "heal"]
var selected_buffs = []
var player_ref
var stage_ref

func show_buff(player, stage):
	player_ref = player
	stage_ref = stage
	visible = true
	content.pivot_offset = content.size / 2 
	content.scale = Vector2.ZERO 
	var tween = create_tween().set_parallel(true)
	tween.tween_property(content, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	selected_buffs = buff_pool.duplicate()
	selected_buffs.shuffle()
	selected_buffs = selected_buffs.slice(0, 3)
	for i in range(3):
		setup_button(buttons[i], selected_buffs[i])

func setup_button(button: TextureButton, buff_type: String):
	match buff_type:
		"speed":
			button.texture_normal = preload("res://Assets/Pop Up Buff/speed.png")
		"damage":
			button.texture_normal = preload("res://Assets/Pop Up Buff/damage.png")
		"heal":
			button.texture_normal = preload("res://Assets/Pop Up Buff/heal.png")


	for connection in button.pressed.get_connections():
		button.pressed.disconnect(connection.callable)

	button.pressed.connect(
		func(): apply_buff(buff_type),
		CONNECT_ONE_SHOT
	)

func apply_buff(buff_type):
	player_ref.apply_buff(buff_type)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(content, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	visible = false
	stage_ref.resume_game()
