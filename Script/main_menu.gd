extends CanvasLayer

@onready var hover_sfx_player = $Hover
@onready var press_sfx_player = $Press
@onready var title = $Title
@onready var chara = $Char
@onready var buttons = $VBoxContainer
@onready var background = $Background
var chara_base_pos: Vector2
var parallax_strength := 50
var parallax_enabled := false
var tilt_strength := 2.5
var bg_base_pos : Vector2
var bg_parallax_strength := 8


func _ready():
	background.pivot_offset = background.size / 2
	background.scale = Vector2(1.03,1.03)
	start_menu_animation()
	for m in $VBoxContainer.get_children():

		var btn = m.get_child(0)

		btn.mouse_entered.connect(_hover_enter.bind(btn))
		btn.mouse_exited.connect(_hover_exit.bind(btn))
	
	

func _process(delta):

	if !parallax_enabled:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var screen_size = get_viewport().get_visible_rect().size

	var offset = (mouse_pos / screen_size - Vector2(0.5,0.5)) * parallax_strength

	var target_x = chara_base_pos.x + offset.x

	chara.position.x = lerp(chara.position.x, target_x, 4 * delta)
	
	var tilt = (mouse_pos.x / screen_size.x - 0.5) * tilt_strength
	chara.rotation_degrees = lerp(chara.rotation_degrees, tilt, 4 * delta)
	
	var bg_target = bg_base_pos + offset * 0.3
	background.position = background.position.lerp(bg_target, 4 * delta)
	
func start_menu_animation():

	var title_start = title.position
	var chara_start = chara.position

	# posisi awal (di luar layar)
	title.position.y -= 300
	chara.position.x += 400

	title.modulate.a = 0
	chara.modulate.a = 0
	var tween = create_tween()

	# TITLE turun dari atas
	tween.tween_property(title,"position",title_start,0.8)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(title,"modulate:a",1.0,0.5)

	# CHARACTER masuk dari kanan
	tween.tween_property(chara,"position",chara_start,0.9)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(chara,"modulate:a",1.0,0.6)

# BUTTON stagger dari kiri
# BUTTON stagger
	for m in buttons.get_children():

		m.add_theme_constant_override("margin_left",-200)
		m.modulate.a = 0

		tween.tween_method(
			func(v): m.add_theme_constant_override("margin_left",v),
			-200,0,0.5
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		tween.parallel().tween_property(m,"modulate:a",1.0,0.4)

		tween.tween_interval(0.1)

	await tween.finished
	chara_base_pos = chara.position
	bg_base_pos = background.position
	parallax_enabled = true

	start_character_idle()
		
func start_character_idle():

	var start_y = chara.position.y
	
	var tween = create_tween()
	tween.set_loops()

	tween.parallel().tween_property(chara,"scale",Vector2(1,1),1.6)
	tween.tween_property(chara, "position:y", start_y - 8, 1.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(chara, "position:y", start_y, 1.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	tween.parallel().tween_property(chara,"scale",Vector2(1.02,1.02),1.6)

func _on_button_pressed() -> void:
	await change_scene_with_transition("res://ChooseStory.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

const JEDA_DETIK = 0.9
func _on_greeting_ready() -> void:
	await get_tree().create_timer(JEDA_DETIK).timeout
	$Greeting.play()
	

func _hover_enter(button):
	if hover_sfx_player.is_playing():
		hover_sfx_player.stop()

	hover_sfx_player.play()

	var tween = create_tween()
	tween.tween_property(
		button,
		"scale",
		Vector2(1.08,1.08),
		0.18
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hover_exit(button):
	var tween = create_tween()
	tween.tween_property(
		button,
		"scale",
		Vector2(1,1),
		0.15
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_button_down() -> void:
	if press_sfx_player.is_playing():
		press_sfx_player.stop()
		
	press_sfx_player.play()

func change_scene_with_transition(path):
	var transition = preload("res://transisi.tscn").instantiate()
	add_child(transition)
	await transition.play_in()
	get_tree().change_scene_to_file(path)
	await transition.play_out()
	transition.queue_free()
