extends Node2D

@onready var player_health_bar = $CanvasLayer/HealthBarPlayer/TextureProgressBar
@export var enemy_scene: PackedScene
@onready var player = $"CharacterBody2D"
@onready var spawn_timer = $SpawnTimer
var SPAWN_DISTANCE = 700
	
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_Menu.tscn")

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_button_pressed()

var elapsed_time := 0
var countdown_time := 180
func start_timer():
	elapsed_time = 0
	$CanvasLayer/GameTimer.start()
	
func format_time(t: int) -> String:
	var minutes = t / 60.0
	var seconds = t % 60
	return "%02d:%02d" % [minutes, seconds]

#func _on_game_timer_timeout() -> void:
	#elapsed_time += 1
	#$CanvasLayer/TimeLabel.text = format_time(elapsed_time)

func _on_game_timer_timeout() -> void:
	countdown_time -= 1
	$CanvasLayer/TimeLabel.text = format_time(countdown_time)
	if countdown_time <= 0:
		$GameTimer.stop()

func _ready():
	spawn_timer.timeout.connect(spawn_enemy)
	spawn_timer.start()
	if player:
		player.health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(new_health: int):
	player_health_bar.value = new_health
	
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
