extends Node2D

@onready var player_health_bar = $CanvasLayer/HealthBarPlayer/TextureProgressBar
@export var enemy_scene: PackedScene
@onready var player = $"CharacterBody2D"
@onready var spawn_timer = $SpawnTimer
@onready var game_timer = $CanvasLayer/GameTimer
var SPAWN_DISTANCE = 400

var question_pool = []
var current_questions = []
var question_index := 0
var elapsed_time := 0
var countdown_time := 90

var correct_answers := 0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup_questions()
	spawn_timer.timeout.connect(spawn_enemy)
	spawn_timer.start()
	game_timer.start()
	if player:
		player.health_changed.connect(_on_player_health_changed)
	
	
	#await get_tree().process_frame
	#await get_tree().create_timer(5).timeout
	#spawn_all_types_once()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_Menu.tscn")

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_button_pressed()

	if event.is_action_pressed("hold_cursor"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event.is_action_released("hold_cursor"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func format_time(t: int) -> String:
	var minutes = t / 60.0
	var seconds = t % 60
	return "%02d:%02d" % [minutes, seconds]

func _on_game_timer_timeout() -> void:
	countdown_time -= 1
	$CanvasLayer/TimeLabel.text = format_time(countdown_time)
	if countdown_time % 15 == 0 and countdown_time !=0 and countdown_time !=90:
		trigger_question_phase()
	if countdown_time <= 0:
		game_timer.stop()
		trigger_victory()
		
func trigger_question_phase():
	get_tree().paused = true
	current_questions = question_pool.duplicate()
	current_questions.shuffle()
	var question_data = current_questions[0]
	$CanvasLayer/QuestionPopUp.show_question(question_data, self)

func trigger_victory():
	spawn_timer.stop()
	Engine.time_scale = 0.25
	await get_tree().create_timer(0.6).timeout
	Engine.time_scale = 1
	get_tree().paused = true
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($CharacterBody2D/Camera2D, "zoom", Vector2(0.8,0.8), 1.5)
	var coins_total = $CharacterBody2D.total_coins
	$CanvasLayer/VictoryPopUp.show_victory(correct_answers, coins_total)



func answer_correct():
	correct_answers += 1
	start_buff_phase()

func answer_wrong():
	resume_game()
	

func start_buff_phase():
	$CanvasLayer/BuffPopUp.show_buff(player, self)

func resume_game():
	get_tree().paused = false
	
func _on_player_health_changed(new_health: int):
	player_health_bar.value = new_health
	if new_health <= 0:
		player_died()
	
#lebih dari 1 tapi berjarak
func spawn_enemy():
	var new_enemy = enemy_scene.instantiate()
	var random_side = randi() % 2 
	var spawn_x: float
	if random_side == 0:
		spawn_x = player.global_position.x - SPAWN_DISTANCE
	else:
		spawn_x = player.global_position.x + SPAWN_DISTANCE
	var spawn_y = player.global_position.y + 108
	new_enemy.global_position = Vector2(spawn_x, spawn_y)
	get_tree().current_scene.add_child(new_enemy)

#ini yang satu enemy
#var spawned_enemy: Node2D = null
#func spawn_enemy():
	#if spawned_enemy != null:
		#return
	#spawned_enemy = enemy_scene.instantiate()
	#var random_side = randi() % 2
	#var spawn_x: float
#
	#if random_side == 0:
		#spawn_x = player.global_position.x - SPAWN_DISTANCE
	#else:
		#spawn_x = player.global_position.x + SPAWN_DISTANCE
#
	#var spawn_y = player.global_position.y + 108
	#spawned_enemy.global_position = Vector2(spawn_x, spawn_y)
#
	#get_tree().current_scene.add_child(spawned_enemy)


#@export_group("Enemy Scenes")
#@export var scene_fsm: PackedScene
#@export var scene_bt: PackedScene
#@export var scene_rbs: PackedScene
#@export var scene_utility: PackedScene
#
#var spawned_enemies: Array[Node2D] = []
#func spawn_enemy(type: String):
	#var selected_scene: PackedScene
	#
	#match type.to_lower():
		#"fsm": selected_scene = scene_fsm
		#"bt": selected_scene = scene_bt
		#"rbs": selected_scene = scene_rbs
		#"utility": selected_scene = scene_utility
		#_: 
			#return
#
	#if selected_scene == null:
		#return
#
	#var new_enemy = selected_scene.instantiate()
	#
	## Logika posisi agar tidak menumpuk
	#var random_side = randi() % 2
	#var offset_x = randf_range(-100, 100)
	#var spawn_x = player.global_position.x + (SPAWN_DISTANCE if random_side == 1 else -SPAWN_DISTANCE) + offset_x
	#var spawn_y = player.global_position.y + 108
	#
	#new_enemy.global_position = Vector2(spawn_x, spawn_y)
	#
	#get_tree().current_scene.add_child(new_enemy)
	#spawned_enemies.append(new_enemy)
	#
	## Hapus dari array saat enemy mati
	#new_enemy.tree_exited.connect(func(): spawned_enemies.erase(new_enemy))
	#
#func spawn_all_types_once():
	#print("--- Memulai Spawn 1 Enemy per Algoritma ---")
	#var types = ["fsm", "bt", "rbs", "utility"]
	#for type in types:
		#spawn_enemy(type)
		#await get_tree().create_timer(1).timeout
		
var is_dead = false
func player_died():
	if is_dead:
		return
	is_dead = true
	Engine.time_scale = 0.2
	await get_tree().create_timer(0.2).timeout
	Engine.time_scale = 1
	get_tree().paused = true

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($CharacterBody2D/Camera2D, "zoom", Vector2(1.2,1.2), 1.2)
	$CanvasLayer/DefeatPopUp.show_defeat()
	
func setup_questions():
	question_pool = [
		# === Bab 3: Usaha, Energi, Pesawat Sederhana ===
		{
			"question": "Rumus usaha adalah?",
			"options": ["W = F x s", "W = m x a", "W = v x t", "W = F / s"],
			"correct": 0
		},
		{
			"question": "Energi kinetik dipengaruhi oleh?",
			"options": ["Massa dan kecepatan", "Gaya dan waktu", "Jarak dan waktu", "Tekanan dan volume"],
			"correct": 0
		},
		{
			"question": "Rumus energi potensial adalah?",
			"options": ["Ep = m g h", "Ep = m v", "Ep = F s", "Ep = v t"],
			"correct": 0
		},
		{
			"question": "Alat yang termasuk pesawat sederhana adalah?",
			"options": ["Tuas", "Mesin mobil", "Generator", "Komputer"],
			"correct": 0
		},
		{
			"question": "Keuntungan mekanis tuas dipengaruhi oleh?",
			"options": ["Panjang lengan kuasa dan beban", "Waktu", "Kecepatan", "Suhu"],
			"correct": 0
		},

		# === Bab 4: Getaran, Gelombang, Cahaya ===
		{
			"question": "Satu getaran adalah?",
			"options": ["Gerak bolak-balik satu kali penuh", "Gerak lurus", "Gerak melingkar", "Gerak acak"],
			"correct": 0
		},
		{
			"question": "Frekuensi adalah?",
			"options": ["Jumlah getaran per detik", "Waktu satu getaran", "Jarak tempuh", "Kecepatan"],
			"correct": 0
		},
		{
			"question": "Rumus cepat rambat gelombang adalah?",
			"options": ["v = f x λ", "v = s/t", "v = m x a", "v = λ / f"],
			"correct": 0
		},
		{
			"question": "Gelombang yang tidak memerlukan medium adalah?",
			"options": ["Gelombang cahaya", "Gelombang bunyi", "Gelombang air", "Gelombang tali"],
			"correct": 0
		},
		{
			"question": "Pemantulan cahaya mengikuti hukum?",
			"options": ["Sudut datang = sudut pantul", "F = m.a", "v = s/t", "Ep = mgh"],
			"correct": 0
		},
		{
			"question": "Alat optik yang digunakan untuk melihat benda kecil adalah?",
			"options": ["Mikroskop", "Teleskop", "Periskop", "Kamera"],
			"correct": 0
		}
	]
