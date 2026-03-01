extends Control

@onready var question_label = $QuestionLabel
@onready var buttons = [$Option1, $Option2, $Option3, $Option4]
var current_question
var stage_ref

func _ready():
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_option_pressed.bind(i))

func show_question(data, stage):
	stage_ref = stage
	current_question = data
	visible = true
	
	pivot_offset = size / 2 
	scale = Vector2.ZERO 
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	question_label.text = data["question"]
	for i in range(4):
		buttons[i].get_node("Label").text = data["options"][i]

func _on_option_pressed(index):
	visible = false
	if index == current_question["correct"]:
		stage_ref.answer_correct()
	else:
		stage_ref.answer_wrong()
