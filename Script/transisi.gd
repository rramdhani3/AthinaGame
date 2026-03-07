extends CanvasLayer

@onready var rect = $ColorRect
var mat : ShaderMaterial

var progress := 0.0


func _ready():
	mat = rect.material


func _process(delta):
	mat.set_shader_parameter("progress", progress)


func play_in():

	progress = 0

	var tween = create_tween()

	tween.tween_property(self,"progress",1.0,0.45)\
	.set_trans(Tween.TRANS_CUBIC)\
	.set_ease(Tween.EASE_IN_OUT)

	await tween.finished


func play_out():

	progress = 0

	var tween = create_tween()

	tween.tween_property(self,"progress",1.0,0.45)\
	.set_trans(Tween.TRANS_CUBIC)\
	.set_ease(Tween.EASE_IN_OUT)

	await tween.finished
