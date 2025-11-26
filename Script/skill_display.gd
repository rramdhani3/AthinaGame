extends Control

const DURATION_IN_MOVE = 0.2
const DURATION_HOLD_TIME = 1.5
const DURATION_FADE_OUT = 0.1
const TARGET_Y_POSITION = 768
const TARGET_X_POSITION = -484

var current_tween: Tween = null
var initial_global_position: Vector2

func activate_skill_ui():
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		reset_position_and_hide()
	initial_global_position = self.global_position
	self.modulate.a = 1.0
	self.show()
	$AudioSkill.play()
	$SFXSkill.play()
	
	
	current_tween = create_tween()
	current_tween.tween_property(self, "global_position:y", TARGET_Y_POSITION, DURATION_IN_MOVE)
	current_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

	current_tween.parallel().tween_property(self, "global_position:x", TARGET_X_POSITION, DURATION_IN_MOVE)
	current_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	
	current_tween.tween_interval(DURATION_HOLD_TIME)
	current_tween.tween_property(self, "modulate:a", 0.0, DURATION_FADE_OUT)
	current_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	current_tween.tween_callback(Callable(self, "reset_position_and_hide"))
	
func reset_position_and_hide():
	self.hide()
	self.global_position = initial_global_position
