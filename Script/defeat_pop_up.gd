extends Control

@onready var color_rect = $ColorRect
@onready var retry_button = $Retry
@onready var backmenu_button = $BackMenu
@onready var label1 = $Label
@onready var slide_labels = [$Label2, $Label3, $Label4 ]

var original_positions = {}

func _ready():
	for lbl in slide_labels:
		original_positions[lbl] = lbl.position

func show_defeat():
	get_tree().current_scene.get_node("BackgroundMusic").stop()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	visible = true

	process_mode = Node.PROCESS_MODE_ALWAYS
	
	color_rect.modulate.a = 0
	
	label1.modulate.a = 0
	label1.scale = Vector2(0.8, 0.8)

	for lbl in slide_labels:
		lbl.modulate.a = 0
		lbl.position = original_positions[lbl] + Vector2(-200, 0)
	
	retry_button.visible = false
	backmenu_button.visible = false
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	tween.tween_property(color_rect, "modulate:a", 0.85, 1.2)
	tween.tween_interval(0.3)
	
	animate_main_label(tween, label1)
	tween.tween_interval(0.2)
	$Defeat.play()
	
	for lbl in slide_labels:
		animate_slide_label(tween, lbl)
		tween.tween_interval(0.1)
	
	tween.tween_callback(show_buttons)


func animate_main_label(tween: Tween, lbl: Label):
	tween.tween_property(lbl, "modulate:a", 1.0, 0.6)
	tween.parallel().tween_property(lbl, "scale", Vector2(1.05,1.05), 0.6)
	tween.tween_property(lbl, "scale", Vector2(1,1), 0.2)
	
	tween.tween_property(lbl, "modulate:a", 0.6, 0.05)
	tween.tween_property(lbl, "modulate:a", 1.0, 0.05)


func animate_slide_label(tween: Tween, lbl: Label):
	tween.tween_property(lbl, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(lbl, "position", original_positions[lbl], 0.5)


func show_buttons():
	retry_button.visible = true
	backmenu_button.visible = true


func _on_retry_pressed():
	get_tree().paused = false
	Engine.time_scale = 1
	get_tree().reload_current_scene()


func _on_back_menu_pressed():
	get_tree().paused = false
	Engine.time_scale = 1
	get_tree().change_scene_to_file("res://ChooseStory.tscn")
