extends AudioStreamPlayer2D

const JEDA_DETIK = 5.0

func _ready():
	play()

	connect("finished", _on_finished)


func _on_finished():

	await get_tree().create_timer(JEDA_DETIK).timeout
	play()
