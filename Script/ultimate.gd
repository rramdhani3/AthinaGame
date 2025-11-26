extends CanvasLayer

signal ultimate_finished

@onready var ultimate_sprite: AnimatedSprite2D = $UltiSprite2D

func _ready():
	set_process_mode(Node.ProcessMode.PROCESS_MODE_ALWAYS)
	self.layer = 2
	if is_instance_valid(ultimate_sprite):
		ultimate_sprite.play("ulti")
		ultimate_sprite.animation_finished.connect(_on_playback_finished)

func _on_playback_finished():
	emit_signal("ultimate_finished")
	queue_free()
