extends CanvasLayer

@onready var hover_sfx_player = $Hover
@onready var press_sfx_player = $Press
@onready var title = $Title
@onready var chara = $Char
@onready var buttons = $VBoxContainer
@onready var background = $Background
@onready var sakura = $GPUParticles2D
@onready var click_particles = $GPUParticles2D2
@onready var cursor_particles = $GPUParticles2D3
var chara_base_pos: Vector2
var parallax_strength := 75
var parallax_enabled := false
var tilt_strength := 2.5
var bg_base_pos : Vector2
var bg_parallax_strength := 8
var sakura_base_pos: Vector2



func _ready():
	setup_sakura()
	setup_cursor_trail()
	setup_click_particles() 
	#setup_glow()
	sakura_base_pos = Vector2(600, -50)
	sakura.position = sakura_base_pos
	background.pivot_offset = background.size / 2
	background.scale = Vector2(1.03,1.03)
	start_menu_animation()
	for m in $VBoxContainer.get_children():

		var btn = m.get_child(0)

		btn.mouse_entered.connect(_hover_enter.bind(btn))
		btn.mouse_exited.connect(_hover_exit.bind(btn))
	

func setup_sakura():
	# 1. Pastikan materialnya ada
	if not sakura.process_material:
		sakura.process_material = ParticleProcessMaterial.new()
	
	var mat = sakura.process_material as ParticleProcessMaterial
	
	# 2. Area Muncul (Emmision Shape)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	# x: 1152 (lebar layar standar), y: 1, z: 1
	mat.emission_box_extents = Vector3(1366, 1, 1) 
	
	# 3. Arah dan Kecepatan (Movement)
	mat.direction = Vector3(-1, 1, 0)
	mat.spread = 20.0
	mat.initial_velocity_min = 60.0
	mat.initial_velocity_max = 120.0
	mat.gravity = Vector3(-20, 30, 0)
	
	# 4. Visual (Rotasi & Ukuran)
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	mat.scale_min = 0.1
	mat.scale_max = 0.4
	
	# 5. Konfigurasi Node Utama
	sakura.amount = 100
	sakura.lifetime = 8.0
	sakura.preprocess = 5.0 
	
	sakura.local_coords = false
	
func setup_cursor_trail():
	cursor_particles.amount = 50
	cursor_particles.lifetime = 0.5
	cursor_particles.local_coords = false # PENTING: Agar partikel tertinggal di belakang
	
	var mat = ParticleProcessMaterial.new()
	mat.gravity = Vector3(0, 0, 0) # Partikel diam di tempat saat muncul
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 10.0
	

	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0)) 
	var scale_curve = CurveTexture.new()
	scale_curve.curve = curve
	mat.scale_curve = scale_curve

	mat.color = Color(5.0, 2.0, 4.0) # Nilai > 1.0 untuk Glow
   
	cursor_particles.process_material = mat
	cursor_particles.emitting = true
	
func setup_click_particles():
	click_particles.emitting = false
	click_particles.one_shot = true
	click_particles.amount = 40 # Tambah sedikit jumlahnya
	click_particles.explosiveness = 1.0
	click_particles.lifetime = 0.8 # Lebih cepat lebih "snappy"
	
	var canvas_mat = CanvasItemMaterial.new()
	canvas_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	click_particles.material = canvas_mat
	
	var mat = ParticleProcessMaterial.new()
	mat.gravity = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 250.0
	mat.initial_velocity_max = 500.0 # Kecepatan tinggi agar terlihat seperti percikan
	
	# Variasi ukuran kotak agar ada yang besar dan kecil (seperti debu cahaya)
	mat.scale_min = 0.05
	mat.scale_max = 0.2
	
	# Kurva agar kotak mengecil sampai hilang (menghindari "pop-out" yang kasar)
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	var scale_curve = CurveTexture.new()
	scale_curve.curve = curve
	mat.scale_curve = scale_curve
	
	
	click_particles.process_material = mat
	
func setup_glow():
	# Membuat node WorldEnvironment otomatis tanpa perlu klik di editor
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.glow_intensity = 1.0
	env.glow_bloom = 0.6 # Membuat partikel HDR terlihat berpendar
	env.set_glow_level(0, 1.0)
	env.set_glow_level(1, 1.0)
	env.set_glow_level(2, 1.0)
	env.set_glow_level(4, 1.0)
	world_env.environment = env
	add_child(world_env)

# Deteksi klik di mana saja (Global)
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			trigger_click_effect(event.position)

func trigger_click_effect(pos: Vector2):
	click_particles.global_position = pos
	click_particles.restart()
	click_particles.emitting = true
	
func _process(delta):
	cursor_particles.global_position = get_viewport().get_mouse_position()
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
	
	var sakura_target = sakura_base_pos + (offset * 1.2) 
	sakura.position = sakura.position.lerp(sakura_target, 4 * delta)
	
	var mouse_x_ratio = get_viewport().get_mouse_position().x / get_viewport().get_visible_rect().size.x
	sakura.process_material.gravity.x = lerp(-50, 50, mouse_x_ratio)
	
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

func _on_story_pressed() -> void:
	if not $NameInput.visible:
			$NameInput.visible = true
			$NameInput.grab_focus()
			return
	if $NameInput.text.strip_edges() == "":
		shake_node($NameInput)
		$NameInput/Error.play()
		return
	username.player_name = $NameInput.text
	if press_sfx_player.is_playing():
		press_sfx_player.stop()
	press_sfx_player.play()
	await change_scene_with_transition("res://ChooseStory.tscn")

func _on_name_input_text_submitted(new_text: String) -> void:
	if new_text.strip_edges() == "":
		shake_node($NameInput)
		$NameInput/Error.play()
		return
	username.player_name = new_text
	if press_sfx_player.is_playing():
		press_sfx_player.stop()
	press_sfx_player.play()
	await change_scene_with_transition("res://ChooseStory.tscn")

var original_pos : Vector2 = Vector2.ZERO
func shake_node(node: Control):
	if original_pos == Vector2.ZERO:
		original_pos = node.position
	var tween = create_tween()
	node.modulate = Color.RED 
	tween.tween_property(node, "position:x", original_pos.x + 10, 0.07)
	tween.tween_property(node, "position:x", original_pos.x - 10, 0.07)
	tween.tween_property(node, "position:x", original_pos.x, 0.07)
	await tween.finished
	node.modulate = Color.WHITE

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



func change_scene_with_transition(path):
	var transition = preload("res://transisi.tscn").instantiate()
	add_child(transition)
	await transition.play_in()
	get_tree().change_scene_to_file(path)
	await transition.play_out()
	transition.queue_free()


@export var popup_settings: Control
func _on_option_pressed() -> void:
	if press_sfx_player.is_playing():
		press_sfx_player.stop()
	press_sfx_player.play()
	popup_settings.open_popup()
