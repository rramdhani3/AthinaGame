extends CanvasLayer

@onready var hover_sfx_player = $VBoxContainer/Hover
@onready var press_sfx_player = $VBoxContainer/Press

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ChooseStory.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()

const JEDA_DETIK = 0.9
func _on_greeting_ready() -> void:
	await get_tree().create_timer(JEDA_DETIK).timeout
	$Greeting.play()
	

func _on_button_hovered() -> void:
	if hover_sfx_player.is_playing():
		hover_sfx_player.stop()
		
	hover_sfx_player.play()


func _on_button_down() -> void:
	if press_sfx_player.is_playing():
		press_sfx_player.stop()
		
	press_sfx_player.play()
