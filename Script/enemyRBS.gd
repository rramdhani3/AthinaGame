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
var current_rule := ""
# Attack Success Rate
var total_attacks := 0
var successful_attacks := 0

@onready var anim_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var anim_attack: AnimationPlayer = $AnimationPlayer
@onready var visual: Node2D = $Visual
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackAreaRange

@export var speed :float= 80.0
@export var speed_run :float= 150.0
@export var player_y_offset :float= 108.0
@export var attack_damage_enemy := 1
@export var coin_scene: PackedScene
@export var coin_drop_amount: int = 5
var knockback_velocity: Vector2 = Vector2.ZERO


const MAX_HEALTH := 200
const FLEE_THRESHOLD := MAX_HEALTH / 2.0
var current_health := MAX_HEALTH
var player_target: CharacterBody2D
var fade_duration := 0.5


# Lifecycle
func _ready():
	player_target = get_tree().get_first_node_in_group("player")
	if player_target:
		detection_time = Time.get_ticks_msec()
		waiting_response = true

func change_rule(new_rule: String):
	if current_rule != new_rule:
		transition_count += 1
		current_rule = new_rule

func apply_knockback(force: Vector2):
	knockback_velocity = force
	
func _physics_process(delta):
	logic_start_time = Time.get_ticks_usec()
	if current_health <= 0:
		return

	var decision_start = Time.get_ticks_usec()
	apply_rules()
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
	print("===== Rule Based System (Interval 1 Menit) =====")
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

func apply_rules():

	if rule_flee():
		change_rule("FLEE")
		flee_player()
		return

	if rule_attack():
		change_rule("ATTACK")
		attack_player()
		return

	change_rule("CHASE")
	chase_player()

func rule_flee() -> bool:
	return current_health <= FLEE_THRESHOLD

func rule_attack() -> bool:
	return attack_area.get_overlapping_bodies().has(player_target)

# Actions
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
	if direction.x !=0 :
		visual.scale.x = sign(direction.x)

func attack_player():
	velocity = Vector2.ZERO
	if anim_attack.current_animation != "attack":
		total_attacks += 1
		anim_attack.play("attack")
		$SfxAtt.play()

func flee_player():
	var target_y = player_target.global_position.y + player_y_offset
	var target_pos = Vector2(player_target.global_position.x, target_y)
	var flee_direction = (target_pos - global_position).normalized() * -1

	velocity = flee_direction * speed_run
	anim_sprite.play("run")
	if flee_direction.x !=0 :
		visual.scale.x = sign(flee_direction.x)

func flash_red():
	var tween = create_tween()
	visual.modulate = Color(1, 0.2, 0.2)
	tween.tween_property(visual, "modulate", Color(1,1,1), 0.15)
	
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerAttack"):
		var damage = area.get_parent().get_parent().attack_damage
		take_damage(damage)
		area.set_deferred("monitoring", false)

func take_damage(amount: int):
	current_health -= amount
	$TextureProgressBar.value = current_health
	flash_red()
	if is_dead:
		return
	if anim_sprite.animation != "hurt":
		anim_sprite.play("hurt")
	if current_health <= 0:
		die()

var is_dead = false
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
	spawn_coins()
	queue_free()

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
