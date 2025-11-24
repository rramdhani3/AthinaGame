extends CharacterBody2D

@export var speed := 200
@export var dash_speed := 600
@export var dash_duration := 0.15
@export var dash_cooldown := 0.5
@export var afterimage_interval := 0.05
@export var afterimage_lifetime := 0.3
@export var footstep_delay := 0.3
@export var attack_offset := Vector2(10, 0)
@export var attack_cooldown := 0.8
@export var attack_push_time := 0.15 
@export var attack_return_time := 0.2
@export var attack_effect_duration := 0.3
@export var attack_effect_speed := 150
@export var attack_effect_offset := Vector2(20, 0)
@export var attack_damage := 20

@onready var hitbox: Area2D = $AttackEffect/Hitbox
@onready var sprite: AnimatedSprite2D = $PlayerSprite2D
@onready var footstep = $PlayerSprite2D/FootstepPlayer
@onready var attack_effect = $AttackEffect
@onready var attack_effect_anim = $AttackEffect/EffectSprite2D

var original_sprite_position := Vector2.ZERO
var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := Vector2.ZERO
var afterimage_timer := 0.0
var footstep_timer := 0.0
var is_attacking := false
var attack_timer := 0.0
var current_health := 200


func _ready():
	original_sprite_position = sprite.position
	get_parent().start_timer()
	
func _physics_process(delta):
	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1

	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0 and not is_attacking:
		if direction != Vector2.ZERO:
			start_dash(direction)
		else:
			start_dash(Vector2.LEFT if sprite.flip_h else Vector2.RIGHT)
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_dashing:
		start_attack()
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
			sprite.position = original_sprite_position
	if is_dashing:
		velocity = dash_direction * dash_speed
		dash_timer -= delta
		afterimage_timer -= delta
		if afterimage_timer <= 0:
			spawn_afterimage()
			afterimage_timer = afterimage_interval
		if dash_timer <= 0:
			is_dashing = false
	else:
		if not is_attacking:
			velocity = direction.normalized() * speed
		else:
			velocity = Vector2.ZERO
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	move_and_slide()

	if is_attacking:
		if sprite.animation != "attack":
			sprite.play("attack")
	elif direction.x != 0 or is_dashing:
		sprite.flip_h = (direction.x < 0 and not is_dashing) or (dash_direction.x < 0 and is_dashing)
		if sprite.animation != "walk":
			sprite.play("walk")
		play_footstep(delta)
	else:
		if sprite.animation != "idle":
			sprite.play("idle")
		stop_footstep()

func spawn_attack_effect():
	attack_effect.visible = true
	attack_effect_anim.play("slash_2")
	var offset = attack_effect_offset
	if sprite.flip_h:
		offset.x = -offset.x
	attack_effect.position = sprite.position + offset
	attack_effect.scale.x = -1 if sprite.flip_h else 1
	var tween = get_tree().create_tween()
	var target_pos = attack_effect.position + Vector2(offset.x * 1.5, 0)
	tween.tween_property(attack_effect, "position", target_pos, attack_effect_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_hide_attack_effect"))
	$AttackSound.play()
	$DubSound.play()

func _hide_attack_effect():
	attack_effect.visible = false
	attack_effect_anim.stop()
	hitbox.monitoring = false
	hitbox.monitorable = false

func start_dash(dir: Vector2):
	is_dashing = true
	dash_direction = dir.normalized()
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	afterimage_timer = 0
	spawn_afterimage()
	$DubSoundDash.play()

func spawn_afterimage():
	var ghost = sprite.duplicate()
	ghost.modulate = Color(0.8, 1, 1, 0.8) 
	ghost.global_position = sprite.global_position
	ghost.global_scale = sprite.global_scale
	ghost.flip_h = sprite.flip_h
	ghost.z_index = sprite.z_index + 1
	get_tree().current_scene.add_child(ghost)
	var tween = get_tree().create_tween()
	tween.tween_property(ghost, "modulate:a", 0, afterimage_lifetime).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(Callable(ghost, "queue_free"))

func start_attack():
	is_attacking = true
	attack_timer = attack_cooldown
	sprite.play("attack")
	hitbox.monitoring = true
	hitbox.monitorable = true
	var offset = attack_offset
	if sprite.flip_h:
		offset.x = -offset.x
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "position", original_sprite_position + offset, attack_push_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position", original_sprite_position, attack_return_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	spawn_attack_effect()

func play_footstep(delta):
	footstep_timer -= delta
	if footstep_timer <= 0:
		if not footstep.playing:
			footstep.play()
		footstep_timer = footstep_delay

func stop_footstep():
	if footstep.playing:
		footstep.stop()
	footstep_timer = 0

signal health_changed(new_health)
func take_damage(amount: int):
	current_health -= amount
	health_changed.emit(current_health)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyAttack"):
		var enemy_root = area.get_parent()
		var damage = enemy_root.attack_damage_enemy
		take_damage(damage)
		area.set_deferred("monitoring", false)
