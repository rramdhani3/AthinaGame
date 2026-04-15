extends Area2D

var distance := 700
var direction := 1
var move_time := 0.8
var damage := 50
var stay_time := 3.15
var hit_interval := 0.8

var enemies_inside = []
var is_looping = false
var knockback := 700

func start():
	$Visual/AnimatedSprite2D.play("skill2")
	$SFXwaves.play()
	if direction == -1:
		$Visual/AnimatedSprite2D.scale.x = sign(direction)

	move_waves()


func move_waves():
	var target_x = global_position.x + (distance * direction)

	var tween = create_tween()
	tween.tween_property(self, "global_position:x", target_x, move_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(start_loop_damage)


func start_loop_damage():
	is_looping = true
	start_damage_loop()
	stop_waves()


func stop_waves():
	await get_tree().create_timer(stay_time).timeout
	queue_free()


func start_damage_loop():
	while is_inside_tree():
		$SFXwaves2.play()
		await get_tree().create_timer(hit_interval).timeout
		for enemy in enemies_inside:
			if is_instance_valid(enemy) and enemy.has_method("take_damage"):
				enemy.take_damage(damage)


func _on_area_entered(area):
	if area.is_in_group("Enemy"):
		var enemy = area.get_parent()
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(Vector2(knockback * direction, 0))
		if enemy not in enemies_inside:
			enemies_inside.append(enemy)

func _on_area_exited(area):
	if area.is_in_group("Enemy"):
		var enemy = area.get_parent()
		enemies_inside.erase(enemy)
