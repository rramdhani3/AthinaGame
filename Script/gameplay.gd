extends Node2D
	
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_Menu.tscn")

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_button_pressed()

var elapsed_time := 0
var countdown_time := 120
func start_timer():
	elapsed_time = 0
	$CanvasLayer/GameTimer.start()
	
func format_time(t: int) -> String:
	var minutes = t / 60
	var seconds = t % 60
	return "%02d:%02d" % [minutes, seconds]

func _on_game_timer_timeout() -> void:
	elapsed_time += 1
	$CanvasLayer/TimeLabel.text = format_time(elapsed_time)

#func _on_game_timer_timeout() -> void:
	#countdown_time -= 1
	#if countdown_time <= 0:
		#$GameTimer.stop()

@export var enemy_scene: PackedScene
@onready var player = $"CharacterBody2D"
@onready var spawn_timer = $SpawnTimer
var SPAWN_DISTANCE = 700 

func _ready():
	spawn_timer.timeout.connect(spawn_enemy)
	spawn_timer.start()
	
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
