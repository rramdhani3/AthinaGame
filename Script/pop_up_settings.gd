extends Control

@onready var slider_music: HSlider = $HSliderMusic
@onready var slider_sfx: HSlider = $HSliderSFX

@onready var label_music_volume: Label = $LabelMusicVolume
@onready var label_sfx_volume: Label = $LabelSFXVolume

func _ready() -> void:
	pivot_offset = size / 2
	
	self.scale = Vector2.ZERO
	self.hide()

	_setup_audio_logic()

func open_popup() -> void:
	self.show()
	
	pivot_offset = size / 2
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func close_popup() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	
	await tween.finished
	self.hide()

#func _setup_audio_logic() -> void:
	#var music_bus_idx = AudioServer.get_bus_index("Music")
	#var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	#
	#if music_bus_idx != -1:
		#_update_label_text(label_music_volume, slider_music.value)
		#slider_music.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_idx))
		#
		#slider_music.value_changed.connect(func(v): 
			#AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(v))
			#_update_label_text(label_music_volume, v)
		#)
		#
	#if sfx_bus_idx != -1:
		#_update_label_text(label_sfx_volume, slider_music.value)
		#slider_sfx.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_idx))
		#slider_sfx.value_changed.connect(func(v): 
			#AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(v))
			#_update_label_text(label_sfx_volume, v)
		#)

#func _update_label_text(label: Label, value: float) -> void:
	#label.text = str(round(value * 100))
	
func _setup_audio_logic() -> void:
	var music_bus_idx = AudioServer.get_bus_index("Music")
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	
	if music_bus_idx != -1:
		slider_music.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_idx))
		_update_label_visual(label_music_volume, slider_music)
		slider_music.value_changed.connect(func(v): 
			AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(v))
			_update_label_visual(label_music_volume, slider_music)
		)
		
	if sfx_bus_idx != -1:
		slider_sfx.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_idx))
		_update_label_visual(label_sfx_volume, slider_sfx)
		slider_sfx.value_changed.connect(func(v): 
			AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(v))
			_update_label_visual(label_sfx_volume, slider_sfx)
		)

func _update_label_visual(label: Label, slider: HSlider) -> void:
	label.text = str(round(slider.value * 100))
	var slider_width = slider.size.x
	var grabber_width = 20.0 
	if slider.has_theme_icon("grabber"):
		grabber_width = slider.get_theme_icon("grabber").get_width()
	var usable_width = slider_width - grabber_width
	var grabber_pos = (slider.value - slider.min_value) / (slider.max_value - slider.min_value)
	var target_x = slider.position.x + (grabber_pos * usable_width) + (grabber_width / 2) - (label.size.x / 2)
	label.position.x = target_x

func _on_button_pressed() -> void:
	close_popup()
