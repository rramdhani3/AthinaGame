extends Node

var bgm: AudioStreamPlayer
var current_stream: AudioStream = null

func _ready():
	bgm = AudioStreamPlayer.new()
	add_child(bgm)

func play_music(stream: AudioStream):
	if current_stream == stream and bgm.playing:
		return
	
	current_stream = stream
	bgm.stream = stream
	bgm.play()

func stop_music():
	bgm.stop()
	current_stream = null
