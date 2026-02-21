extends CanvasLayer


func _on_stage_1_pressed() -> void:
	get_tree().change_scene_to_file("res://Story.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_Menu.tscn")


func _on_glosa_button_pressed() -> void:
	get_tree().change_scene_to_file("res://glosarium.tscn")
