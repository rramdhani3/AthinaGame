extends CharacterBody2D

# --- VARIABEL PERFORMA ---
var logic_start_time: float = 0.0
var logic_durations: Array = []
var frame_counts: Array = []
var monitoring_timer: float = 0.0
const LOG_INTERVAL = 60.0

# ===== METRIK PENELITIAN =====
# Response Time
var response_times: Array = []
var detection_time := 0
var waiting_response := false
# Decision Latency
var decision_latencies: Array = []
# Memory Usage
var memory_samples: Array = []
# Transition Frequency
var transition_count := 0
var current_decision := ""
# Attack Success Rate
var total_attacks := 0
var successful_attacks := 0

@onready var anim_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var anim_attack: AnimationPlayer = $AnimationPlayer
@onready var visual: Node2D = $Visual
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackAreaRange
@export var speed := 80.0
@export var speed_run := 150.0
@export var player_y_offset := 108.0
@export var attack_damage_enemy := 1
@export var coin_scene: PackedScene
@export var coin_drop_amount: int = 5
var knockback_velocity: Vector2 = Vector2.ZERO

const MAX_HEALTH := 200
var current_health := MAX_HEALTH

var player_target: CharacterBody2D
var can_attack := false
var fade_duration := 0.5

# Lifecycle
func _ready():
	player_target = get_tree().get_first_node_in_group("player")
	if player_target:
		detection_time = Time.get_ticks_msec()
		waiting_response = true
	#var u_attack := utility_attack()
	#var u_flee   := utility_flee()
	#var u_chase  := utility_chase()

	#print(
		#"Utility | Attack:", u_attack,
		#" Flee:", u_flee,
		#" Chase:", u_chase,
		#" HP:", current_health
	#)
	
func change_decision(new_decision: String):
	if current_decision != new_decision:
		transition_count += 1
		current_decision = new_decision

func apply_knockback(force: Vector2):
	knockback_velocity = force
	
func _physics_process(delta):
	logic_start_time = Time.get_ticks_usec()
	if current_health <= 0 or player_target == null:
		return

	var u_attack := utility_attack()
	var decision_start = Time.get_ticks_usec()
	var u_flee   := utility_flee()
	var u_chase  := utility_chase()

	if u_flee >= u_attack and u_flee >= u_chase:
		change_decision("FLEE")
		flee_player()
	elif u_attack >= u_chase:
		change_decision("ATTACK")
		attack_player()
	else:
		change_decision("CHASE")
		chase_player()

	var decision_end = Time.get_ticks_usec()
	decision_latencies.append(
		(decision_end - decision_start) / 1000.0
)
	var logic_end_time = Time.get_ticks_usec()
	var duration_ms = (logic_end_time - logic_start_time) / 1000.0
	logic_durations.append(duration_ms)
	frame_counts.append(Engine.get_frames_per_second())

	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 600 * delta)
	move_and_slide()
	
	monitoring_timer += delta
	var memory_mb = (
	Performance.get_monitor(
		Performance.MEMORY_STATIC
	) / 1024.0 / 1024.0
)
	memory_samples.append(memory_mb)
	if monitoring_timer >= LOG_INTERVAL:
		calculate_and_log_performance()
		monitoring_timer = 0.0

func calculate_and_log_performance():

	if frame_counts.is_empty():
		return
	# FPS
	var avg_fps = 0.0
	var min_fps = frame_counts[0]
	for f in frame_counts:
		avg_fps += f
		if f < min_fps:
			min_fps = f
	avg_fps /= frame_counts.size()

	# Logic Processing
	var avg_logic = 0.0
	for d in logic_durations:
		avg_logic += d

	if logic_durations.size() > 0:
		avg_logic /= logic_durations.size()

	# Response Time
	var avg_response = 0.0
	for r in response_times:
		avg_response += r
	if response_times.size() > 0:
		avg_response /= response_times.size()

	# Decision Latency
	var avg_decision = 0.0
	for d in decision_latencies:
		avg_decision += d
	if decision_latencies.size() > 0:
		avg_decision /= decision_latencies.size()

	# Memory Usage
	var avg_memory = 0.0
	for m in memory_samples:
		avg_memory += m
	if memory_samples.size() > 0:
		avg_memory /= memory_samples.size()

	# Attack Success Rate
	var attack_rate = 0.0
	if total_attacks > 0:
		attack_rate = (
			successful_attacks * 100.0
		) / total_attacks

	print("")
	print("===== Utility Based-AI (Interval 1 Menit) =====")
	#print("FPS Average            : ", snapped(avg_fps, 0.01))
	#print("FPS Minimum            : ", min_fps)
	#print("Logic Processing (ms)  : ", snapped(avg_logic, 0.0001))
	print("Response Time (ms)     : ", snapped(avg_response, 0.01))
	print("Decision Latency (ms)  : ", snapped(avg_decision, 0.0001))
	print("Memory Usage (MB)      : ", snapped(avg_memory, 0.01))
	print("Transition Frequency   : ", transition_count)
	print("Attack Success Rate %  : ", snapped(attack_rate, 0.01))
	print("==============================================")
	print("")

	frame_counts.clear()
	logic_durations.clear()
	response_times.clear()
	decision_latencies.clear()
	memory_samples.clear()
# Utility Functions
#func utility_attack() -> float:
	#if can_attack:
		#return current_health / MAX_HEALTH
	#return 0.0
#
#func utility_flee() -> float:
	#return 1.0 - (current_health / MAX_HEALTH)
#
#func utility_chase() -> float:
	#return 0.3 + (current_health / MAX_HEALTH) * 0.3

func utility_attack() -> float:
	if can_attack:
		return float(current_health) / float(MAX_HEALTH)
	return 0.0

func utility_flee() -> float:
	return 1.0 - (float(current_health) / float(MAX_HEALTH))

func utility_chase() -> float:
	return 0.3 + (float(current_health) / float(MAX_HEALTH)) * 0.3



func attack_player():
	velocity = Vector2.ZERO
	if anim_attack.current_animation != "attack":
		total_attacks += 1
		anim_attack.play("attack")
		$SfxAtt.play()

func chase_player():
	if waiting_response:
		var response = Time.get_ticks_msec() - detection_time
		response_times.append(response)
		waiting_response = false
	var target_y = player_target.global_position.y + player_y_offset
	var target_pos = Vector2(player_target.global_position.x, target_y)
	var direction = (target_pos - global_position).normalized()

	velocity = direction * speed
	anim_sprite.play("walk")
	if direction.x != 0:
		visual.scale.x = sign(direction.x)

func flee_player():
	var target_y = player_target.global_position.y + player_y_offset
	var target_pos = Vector2(player_target.global_position.x, target_y)
	var flee_direction = (target_pos - global_position).normalized() * -1

	velocity = flee_direction * speed_run
	anim_sprite.play("run")
	if flee_direction.x != 0:
		visual.scale.x = sign(flee_direction.x)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerAttack"):
		var damage = area.get_parent().get_parent().attack_damage
		take_damage(damage)
		area.set_deferred("monitoring", false)

func take_damage(amount: int):
	current_health -= amount
	$TextureProgressBar.value = current_health
	flash_red()
	#var u_attack := utility_attack()
	#var u_flee   := utility_flee()
	#var u_chase  := utility_chase()
	if is_dead:
		return
	#print(
		#"Utility | Attack:", u_attack,
		#" Flee:", u_flee,
		#" Chase:", u_chase,
		#" HP:", current_health
	#)
	if anim_sprite.animation != "hurt":
		anim_sprite.play("hurt")
	if current_health <= 0:
		die()

		
func flash_red():
	var tween = create_tween()
	visual.modulate = Color(1, 0.2, 0.2)
	tween.tween_property(visual, "modulate", Color(1,1,1), 0.15)
	
var is_dead := false
func die():
	if is_dead:
		return
	is_dead = true
	hurtbox.set_deferred("monitoring", false)
	anim_sprite.play("die")
	$SfxDie.play()
	set_physics_process(false)
	set_process(false)
	anim_sprite.animation_finished.connect(Callable(start_fade_out), CONNECT_ONE_SHOT)

	
func start_fade_out():
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_tween.tween_callback(after_die)

func after_die():
	queue_free()
	spawn_coins()

func _on_attack_area_range_body_entered(body: Node2D) -> void:
	if body == player_target:
		can_attack = true

func _on_attack_area_range_body_exited(body: Node2D) -> void:
	if body == player_target:
		can_attack = false
		anim_attack.stop()

func give_damage_to_player():
	if player_target and player_target.has_method("take_damage"):
		player_target.take_damage(attack_damage_enemy)
		successful_attacks += 1
func spawn_coins():
	if coin_scene == null:
		return
	
	for i in coin_drop_amount:
		var coin = coin_scene.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position
