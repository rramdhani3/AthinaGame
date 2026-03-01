extends CanvasLayer

@export var music: AudioStream
func _ready():
	music_manager.play_music(music)
	
func _on_stage_1_pressed() -> void:
	get_tree().change_scene_to_file("res://Story.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_Menu.tscn")


func _on_glosa_button_pressed() -> void:
	get_tree().change_scene_to_file("res://glosarium.tscn")
	


func _on_stage_2_pressed() -> void:
	get_tree().change_scene_to_file("res://GameplayS2.tscn")


func _on_stage_3_button_up() -> void:
	get_tree().change_scene_to_file("res://GameplayS3.tscn")
