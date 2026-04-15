extends Control

@onready var container = $Container
@onready var confirm_button = $Container/Confirm
@onready var color_rect = $ColorRect


@onready var result_question = $Container/VBoxContainer/HBoxContainer/ResultQuestionTotal
@onready var result_coin_total = $Container/VBoxContainer/HBoxContainer2/ResultCoinTotal


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	container.pivot_offset = container.size / 2

func show_victory(correct_count: int, coins_count: int):
	get_tree().current_scene.get_node("BackgroundMusic").stop()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	visible = true
	if result_question == null:
		print("Ternyata Question yang null!")
	else:
		result_question.text = str(correct_count)
		
	if result_coin_total == null:
		print("Ternyata Coin yang null!")
	else:
		result_coin_total.text = str(coins_count)
		
	color_rect.modulate.a = 0
	container.scale = Vector2(0.2,0.2)
	container.modulate.a = 0
	confirm_button.visible = false
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	tween.tween_property(color_rect,"modulate:a",0.8,1.0)
	
	tween.tween_property(container,"modulate:a",1.0,0.5)
	tween.parallel().tween_property(container,"scale",Vector2(1.1,1.1),0.5)
	
	tween.tween_property(container,"scale",Vector2(1,1),0.2)
	
	$Victory.play()
	
	tween.tween_callback(show_buttons)

func show_buttons():
	confirm_button.visible = true
	confirm_button.modulate.a = 0
	confirm_button.position.y += 20
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	tween.tween_property(confirm_button,"modulate:a",1.0,0.4)
	tween.parallel().tween_property(confirm_button,"position:y",confirm_button.position.y - 20,0.4)

#entry = https://docs.google.com/forms/d/e/1FAIpQLSfX84GbrEIZClsggJctyBCWE-LlPCobKKT2ciKFQJb_8CvSMQ/viewform?usp=pp_url&entry.1737170028=rizky&entry.159315586=5&entry.1673600480=10
var form_url = "https://docs.google.com/forms/d/e/1FAIpQLSfX84GbrEIZClsggJctyBCWE-LlPCobKKT2ciKFQJb_8CvSMQ/formResponse"
func send_data_to_sheets(player_name: String, correct: int, coins: int):
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	var body = "entry.1737170028=" + player_name.uri_encode() + "&entry.159315586=" + str(correct) + "&entry.1673600480=" + str(coins)
	$HTTPRequest.request(form_url, headers, HTTPClient.METHOD_POST, body)
	print("Data dikirim ke Spreadsheet...")
	
func _on_confirm_pressed() -> void:
	var nama = username.player_name
	send_data_to_sheets(nama, int(result_question.text), int(result_coin_total.text))
	$Confirmsfx.play()
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(container, "scale", Vector2(0.85, 0.85), 0.08)
	tween.tween_property(container, "scale", Vector2(0.85, 0.85), 0.08)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(container, "scale", Vector2(1.1, 1.1), 0.15)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	#tween.parallel().tween_property(container, "rotation_degrees", 1, 0.15)
	tween.tween_property(container, "scale", Vector2(0.0, 0.0), 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(color_rect, "modulate:a", 1.0, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	await tween.finished
	await get_tree().create_timer(2.0).timeout
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ChooseStory.tscn")
