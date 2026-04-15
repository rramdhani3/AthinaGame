extends CharacterBody2D

# --- VARIABEL PERFORMA ---
var logic_start_time: float = 0.0
var logic_durations: Array = []
var frame_counts: Array = []
var monitoring_timer: float = 0.0
const LOG_INTERVAL = 60.0

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

func apply_knockback(force: Vector2):
	knockback_velocity = force
	
func _physics_process(delta):
	logic_start_time = Time.get_ticks_usec()
	if current_health <= 0:
		return

	apply_rules()
	
	var logic_end_time = Time.get_ticks_usec()
	var duration_ms = (logic_end_time - logic_start_time) / 1000.0
	logic_durations.append(duration_ms)
	frame_counts.append(Engine.get_frames_per_second())
	
	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 600 * delta)
	move_and_slide()
	
	monitoring_timer += delta
	if monitoring_timer >= LOG_INTERVAL:
		calculate_and_log_performance()
		monitoring_timer = 0.0

func calculate_and_log_performance():
	if frame_counts.is_empty(): return

	# Hitung FPS
	var avg_fps = 0.0
	var min_fps = frame_counts[0]
	for f in frame_counts:
		avg_fps += f
		if f < min_fps: min_fps = f
	avg_fps /= frame_counts.size()

	# Hitung Waktu Logika
	var avg_logic = 0.0
	for d in logic_durations:
		avg_logic += d
	avg_logic /= logic_durations.size()

	# OUTPUT DEBUG SESUAI TABEL
	print("--- PERFORMA NPC Rule Based System (Interval 1 Menit) ---")
	print("FPS Rata-rata            : ", snapped(avg_fps, 0.01))
	print("FPS Minimum             : ", min_fps)
	print("Waktu Pemrosesan Logika : ", snapped(avg_logic, 0.0001), " ms")
	print("-----------------------------------------------")

	# Reset data untuk menit berikutnya
	frame_counts.clear()
	logic_durations.clear()

func apply_rules():
	if rule_flee():
		flee_player()
		return

	if rule_attack():
		attack_player()
		return

	chase_player()

func rule_flee() -> bool:
	return current_health <= FLEE_THRESHOLD

func rule_attack() -> bool:
	return attack_area.get_overlapping_bodies().has(player_target)

# Actions
func chase_player():
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

func spawn_coins():
	if coin_scene == null:
		return
	
	for i in coin_drop_amount:
		var coin = coin_scene.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position
