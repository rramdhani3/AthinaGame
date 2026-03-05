extends Node2D

@onready var player_health_bar = $CanvasLayer/HealthBarPlayer/TextureProgressBar
@export var enemy_scene: PackedScene
@onready var player = $"CharacterBody2D"
@onready var spawn_timer = $SpawnTimer
@onready var game_timer = $CanvasLayer/GameTimer
var SPAWN_DISTANCE = 700

var question_pool = []
var current_questions = []
var question_index := 0
var elapsed_time := 0
var countdown_time := 5

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup_questions()
	spawn_timer.timeout.connect(spawn_enemy)
	spawn_timer.start()
	game_timer.start()
	if player:
		player.health_changed.connect(_on_player_health_changed)
	

	
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
	#if countdown_time % 60 == 0 and countdown_time != 180:
		#trigger_question_phase()
	if countdown_time % 10 == 0:
		#trigger_question_phase()
		pass
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
	
	$CanvasLayer/VictoryPopUp.show_victory()

func answer_correct():
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
		{
			"question": "Besaran turunan dari panjang adalah?",
			"options": ["Luas", "Massa", "Waktu", "Suhu"],
			"correct": 0
		},
		{
			"question": "Rumus gaya adalah?",
			"options": ["F = m.a", "F = m/v", "F = v/a", "F = m+v"],
			"correct": 0
		},
		{
			"question": "Satuan SI energi adalah?",
			"options": ["Joule", "Newton", "Pascal", "Watt"],
			"correct": 0
		},
		{
			"question": "Kecepatan adalah?",
			"options": ["Perpindahan/waktu", "Jarak/waktu", "Massa/waktu", "Gaya/waktu"],
			  "correct": 1
		}
	]
