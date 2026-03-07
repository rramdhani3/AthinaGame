extends Node

var transition

func _ready():
	transition = preload("res://transisi.tscn").instantiate()
	add_child(transition)

func change_scene(path):

	await transition.play_in()

	get_tree().change_scene_to_file(path)

	await transition.play_out()
	transition.queue_free()
