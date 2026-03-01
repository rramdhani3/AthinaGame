extends CanvasLayer

@onready var dialog_label = $Dialog/RichTextLabel
@onready var name_label = $Dialog/Label
@onready var char_left = $CharacterLayer/CharacterLeft
@onready var char_right = $CharacterLayer/CharacterRight
@onready var fade_rect = $FadeRect
@onready var button_auto = $HBoxContainer/ButtonAuto
@onready var skip_popup = $PopUp
@onready var panel_popup = $PanelPopUp
@onready var indikator = $Dialog/Indikator
@onready var sfx_dialog_button = $HBoxContainer/Press

@onready var characters := {
	"Louis": {
		"node": $"CharacterLayer/CharacterLeft",
		"expressions": {
			"neutral": $"CharacterLayer/CharacterLeft/LouisNeutral",
			"happy": $"CharacterLayer/CharacterLeft/LouisHappy"
		}
	},
	"Lynier": {
		"node": $"CharacterLayer/CharacterRight",
		"expressions": {
			"neutral": $"CharacterLayer/CharacterRight/LynierNeutral"
		}
	}
}
var dialogs := [
	{
		"name": "Louis",
		"text": "Hai, saya Louis. Senang bertemu denganmu!",
		"char_left": "Louis",
		"expr_left": "neutral",
		"mod_left": "BRIGHT",
		#"char_right": "Lynier",
		#"expr_right": "neutral",
		"mod_right": "DARK",
		"anim_left": "slide_in_right",
	},
	{
		"name": "Lynier",
		"text": "Hai Louis, aku Lynier. Kamu sedang apa di sini?",
		"char_left": "Louis",
		"expr_left": "neutral",
		"mod_left": "DARK",
		"char_right": "Lynier",
		"expr_right": "neutral",
		"mod_right": "BRIGHT",
		"anim_right": "slide_in_left"
	},
	{
		"name": "Louis",
		"text": "Aku sedang mencari bunga yang tumbuh hanya saat senja tiba. Selamat tinggal Lynier!",
		"char_left": "Louis",
		"expr_left": "happy",
		"mod_left": "BRIGHT",
		"char_right": "Lynier",
		"expr_right": "neutral",
		"mod_right": "DARK"
	},
	{
		"name": "Lynier",
		"text": "Tunggu Sebentar, hutan ini sangat luas, kamu sendirian?",
		"char_left": "Louis",
		"expr_left": "happy",
		"mod_left": "DARK",
		"char_right": "Lynier",
		"expr_right": "neutral",
		"mod_right": "BRIGHT",
		"anim_right": "shake"
	},
	{
		"name": "Louis",
		"text": "Iya, Kenapa? apakah aneh jika sendirian?",
		"char_left": "Louis",
		"expr_left": "neutral",
		"mod_left": "BRIGHT",
		"char_right": "Lynier",
		"expr_right": "neutral",
		"mod_right": "DARK"
	},
	{
		"name": "Lynier",
		"text": "Nggak juga, cuma ini di hutan loh, gak takut kalau sendirian?",
		"char_left": "Louis",
		"expr_left": "neutral",
		"mod_left": "DARK",
		"char_right": "Lynier",
		"expr_right": "neutral",
		"mod_right": "BRIGHT"
	},
	{
		"name": "Louis",
		"text": "Tapi, kamu juga sendirian",
		"char_left": "Louis",
		"expr_left": "happy",
		"mod_left": "BRIGHT",
		"char_right": "Lynier",
		"expr_right": "neutral",
		"mod_right": "DARK",
		"anim_left" : "wiggle"
	},
	{
		"name": "Lynier",
		"text": "Ah itu... aku tersesat ketika mencoba menangkap kupu-kupu",
		"char_left": "Louis",
		"expr_left": "happy",
		"mod_left": "DARK",
		"char_right": "Lynier",
		"expr_right": "neutral",
		"mod_right": "BRIGHT",
		"bounce_right": true
	},
	{
		"name": "Louis",
		"text": "Kupu-Kupu?",
		"char_left": "Louis",
		"expr_left": "neutral",
		"mod_left": "BRIGHT",
		"char_right": "Lynier",
		"expr_right": "neutral",
		"mod_right": "DARK",
		"anim_left": "slide_right",
		"anim_right": "slide_out_right"
	},
	{
		"name": "Louis",
		"text": "Ngomong apa dia?!",
		"char_left": "Louis",
		"expr_left": "neutral",
		"mod_left": "BRIGHT",
		#"char_right": "Lynier",
		#"expr_right": "neutral",
		"mod_right": "DARK",
		"anim_left": "zoom",
	}
]

var dialog_index := 0
var is_typing := false
var typing_speed := 0.03
func _ready():
	music_manager.stop_music()
	_hide_all_characters()
	show_dialog(dialog_index)

func _hide_all_characters():
	for char_data in characters.values():
		var char_node = char_data["node"]
		if char_node != null:
			char_node.visible = false
			
		for expr in char_data["expressions"].values():
			if expr != null:
				expr.visible = false

func _bounce_character(node: Node) -> void:
	if node == null:
		return
	var tween := create_tween()
	var original_pos: Vector2 = node.position
	tween.tween_property(node, "position:y", original_pos.y - 20, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position:y", original_pos.y, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	$Dialog/ChatAwfull.visible = true
	$Dialog/Bounce.play()
	
func _play_animation(node: Control, anim):
	if node == null:
		return
	if anim is Array:
		for a in anim:
			_play_animation(node, a)
		return

	match anim:
		"shake":
			_anim_shake(node)
		"wiggle":
			_anim_wiggle(node)
		"fade_in":
			_anim_fade_in(node)
		"fade_out":
			_anim_fade_out(node)
		"slide_in_left":
			_anim_slide_in(node, 320)
		"slide_in_right":
			_anim_slide_in(node, -320)
		"slide_out_left":
			_anim_slide_out(node, -320)
		"slide_out_right":
			_anim_slide_out(node, 320)
		"slide_right":
			_anim_slide(node, 320)
		"slide_left":
			_anim_slide(node, -320)
		"zoom":
			_anim_zoom(node)
		"hide":
			_anim_hide(node)
		"show":
			_anim_show(node)

func _anim_shake(node: Control):
	var tween := create_tween()
	var original := node.position.x
	for i in range(6):
		tween.tween_property(node, "position:x", original + randf_range(-8, 8), 0.03)
	tween.tween_property(node, "position:x", original, 0.05)
	$Dialog/Shake.play()

func _anim_wiggle(node: Control):
	var tween := create_tween()
	var original := node.position.x
	tween.tween_property(node, "position:x", original - 10, 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position:x", original + 10, 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position:x", original, 0.15).set_trans(Tween.TRANS_SINE)
	$Dialog/Wiggle.play()

func _anim_fade_in(node: Control):
	node.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 1.0, 0.8)
	
func _anim_fade_out(node: Control):
	node.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 0.0, 0.8)

func _anim_slide_in(node: Control, offset_x: float):
	node.visible = true
	var tween := create_tween()
	var original := node.position
	var start_pos := original + Vector2(offset_x, 0)
	node.position = start_pos
	tween.tween_property(node, "position", original, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	$Dialog/Slide.play()

func _anim_slide_out(node: Control, offset_x: float):
	var tween := create_tween()
	var original := node.position
	var target_pos := original + Vector2(offset_x, 0)
	tween.tween_property(node, "position", target_pos, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	node.visible = false
	node.position = original
	$Dialog/Slide.play()

func _anim_slide(node: Control, offset_x: float):
	var tween := create_tween()
	var original := node.position
	var target_pos := original + Vector2(offset_x, 0)
	tween.tween_property(node, "position", target_pos, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	node.visible = true
	#node.position = original
	$Dialog/Slide.play()

func _anim_zoom(node: Control):
	var tween := create_tween()
	#var original := node.scale
	tween.tween_property(node, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	$Dialog/Zoom.play()
	
func _anim_hide(node: Control):
	node.visible = false
	
func _anim_show(node: Control):
	node.visible = true

const ICON_AUTO_ON = preload("res://animated_texture.tres") 
const ICON_AUTO_OFF = preload("res://Assets/dialog UI/Auto-Normal.png") 
const ICON_HOVER_OFF = preload("res://Assets/dialog UI/Auto-Hover.png")
var is_auto_mode := false
const AUTO_DELAY = 0.8
func _on_button_auto_pressed() -> void:
	is_auto_mode = !is_auto_mode
	print("Mode Auto: ", is_auto_mode)
	if is_auto_mode:
		button_auto.texture_normal = ICON_AUTO_ON
		button_auto.texture_hover = null
		sfx_dialog_button.pitch_scale = 1.0
		sfx_dialog_button.play()
	else:
		button_auto.texture_normal = ICON_AUTO_OFF
		button_auto.texture_hover = ICON_HOVER_OFF
		sfx_dialog_button.pitch_scale = 0.6
		sfx_dialog_button.play()
	if is_auto_mode and not is_typing:
		_auto_continue_dialog()
		
func _auto_continue_dialog():
	await get_tree().create_timer(AUTO_DELAY).timeout
	if is_auto_mode:
		dialog_index += 1
		show_dialog(dialog_index)
		
var is_popup_open = false
func _on_button_skip_pressed() -> void:
	is_popup_open = true
	panel_popup.show()
	sfx_dialog_button.pitch_scale = 1.0
	sfx_dialog_button.play()

	var viewport_size = get_viewport().get_visible_rect().size
	var node_size = skip_popup.size
	skip_popup.position = (viewport_size - node_size) / 2
	
	skip_popup.scale = Vector2(0.0, 0.0)
	skip_popup.show()
	
	var tween = create_tween()
	tween.tween_property(skip_popup, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	is_auto_mode = false

func _on_skip_confirm_pressed() -> void:
	$HBoxContainer/Confirm.play()
	skip_popup.hide()
	_change_scene_fade()

func _on_skip_cancel_pressed() -> void:
	panel_popup.hide()
	is_popup_open = false
	sfx_dialog_button.pitch_scale = 0.4
	sfx_dialog_button.play()
	var tween = create_tween()
	tween.tween_property(skip_popup, "scale", Vector2(0.0, 0.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
const NEXT_SCENE_PATH = "res://Gameplay.tscn"
func _change_scene_fade() -> void:
	fade_rect.visible = true 
	var tween = create_tween()
	fade_rect.modulate.a = 0.0
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.5) 
	await tween.finished 
	if get_tree().change_scene_to_file(NEXT_SCENE_PATH) != OK:
		print("ERROR: Gagal memuat scene: ", NEXT_SCENE_PATH)

func _change_scene() -> void:
	if get_tree().change_scene_to_file(NEXT_SCENE_PATH) != OK:
		print("ERROR: Gagal memuat scene: ", NEXT_SCENE_PATH)

func show_dialog(index: int) -> void:
	if index >= dialogs.size():
		_change_scene_fade()
		print("Dialog selesai.")
		return
	$Dialog/ChatAwfull.visible = false
	var d = dialogs[index]
	name_label.text = d["name"]
	dialog_label.text = ""
	is_typing = true

	if d.has("char_left"):
		_update_character(d["char_left"], d.get("expr_left", null))
	if d.has("char_right"):
		_update_character(d["char_right"], d.get("expr_right", null))

	if d.has("bounce_left") and d["bounce_left"] == true:
		_bounce_character(char_left)
	if d.has("bounce_right") and d["bounce_right"] == true:
		_bounce_character(char_right)

	if d.has("anim_left"):
		_play_animation(char_left, d["anim_left"])
	if d.has("anim_right"):
		_play_animation(char_right, d["anim_right"])
		
	_process_dialog_modulate(d)
	start_typing(d["text"])

func _get_modulate_color(status: String) -> Color:
	match status.to_upper():
		"BRIGHT":
			return Color(1, 1, 1, 1)
		"DARK":
			return Color(0.5, 0.5, 0.5, 1)
		_:
			return Color(1, 1, 1, 1) 

func _update_character(char_name: String, expr_name: String) -> void:
	var char_data = characters.get(char_name)
	if char_data == null:
		print("ERROR: character", char_name, "not found.")
		return
	var char_node = char_data["node"]
	char_node.visible = true
	char_node.modulate = Color(1,1,1,1)
	for expr in char_data["expressions"].values():
		expr.visible = false
	if expr_name != null and char_data["expressions"].has(expr_name):
		char_data["expressions"][expr_name].visible = true

func _process_dialog_modulate(d: Dictionary) -> void:
	var tween := get_tree().create_tween()
	if d.has("mod_left") and d["mod_left"] != null and char_left.visible:
		var target_color = _get_modulate_color(d["mod_left"])
		tween.tween_property(char_left, "modulate", target_color, 0.0)
	if d.has("mod_right") and d["mod_right"] != null and char_right.visible:
		var target_color = _get_modulate_color(d["mod_right"])
		tween.tween_property(char_right, "modulate", target_color, 0.0)

func _input(event):
	if is_popup_open:
		return
	if event.is_action_pressed("klik_dialog"):
		$Dialog/Klik.play()
		if not is_auto_mode: 
			if is_typing:
				dialog_label.text = dialogs[dialog_index]["text"]
				is_typing = false
			else:
				dialog_index += 1
				show_dialog(dialog_index)
				
func start_typing(text: String) -> void:
	is_typing = true
	indikator.visible = false
	dialog_label.text = ""
	var original_text = text
	for i in original_text.length():
		if not is_typing:
			break
		dialog_label.text += original_text[i]
		await get_tree().create_timer(typing_speed).timeout
	if not is_typing:
		dialog_label.text = original_text
	is_typing = false
	indikator.visible = true
	var tween = create_tween()
	var original_y = indikator.position.y
	indikator.modulate.a = 0.0
	tween.tween_property(indikator, "modulate:a", 1.0, 0.5)
	tween.tween_property(indikator, "position:y", original_y - 8, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(indikator, "position:y", original_y, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tween.finished
	if is_auto_mode:
		_auto_continue_dialog()
