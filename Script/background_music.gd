extends AudioStreamPlayer

const JEDA_DETIK = 5.0
func _ready():
	music_manager.stop_music()
	play()

	connect("finished", _on_finished)


func _on_finished():

	await get_tree().create_timer(JEDA_DETIK).timeout
	play()
