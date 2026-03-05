extends CharacterBody2D

@export var speed :float= 300.0
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
@export var attack_damage :float= 20.0
@export var max_hp :float= 200.0

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
var current_health :float= 200.0



func _ready():
	original_sprite_position = sprite.position
	ultimate_cooldown_timer.timeout.connect(_on_ultimate_cooldown_timeout)
	skill_cooldown_timer.timeout.connect(_on_skill_cooldown_timeout)
	
func _physics_process(delta):
	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_just_pressed("skill_q"): 
		if not is_skill_on_cooldown:
			activate_skill_and_cooldown()
	if Input.is_action_just_pressed("ulti_r"): 
		if not is_ultimate_on_cooldown:
			activate_ultimate_and_cooldown()

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
	ghost.z_index = sprite.z_index
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
	if current_health < 0:
		current_health = 0
	health_changed.emit(current_health)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyAttack"):
		var enemy_root = area.get_parent()
		var damage = enemy_root.attack_damage_enemy
		take_damage(damage)
		area.set_deferred("monitoring", false)
		
		
@onready var skill_cooldown_timer: Timer = $SkillTimer
var skill_cooldown_time: float = 3.0
var is_skill_on_cooldown: bool = false
func activate_skill_and_cooldown():
	get_tree().call_group("Skill", "activate_skill_ui")
	is_skill_on_cooldown = true
	skill_cooldown_timer.start(skill_cooldown_time)
	
func _on_skill_cooldown_timeout():
	is_skill_on_cooldown = false

var has_ultimate_damage_applied: bool = false
var is_ultimate_on_cooldown: bool = false 
var current_ultimate_instance: CanvasLayer = null
@export var ultimate_scene_prefab: PackedScene = preload("res://ultimate.tscn")
@onready var ultimate_cooldown_timer: Timer = $UltiTimer 
@onready var ultimate_vfx_damage: Area2D = $UltimateVFXDamage
@onready var ultimate_vfx_sprite: AnimatedSprite2D = $UltimateVFXDamage/AnimatedSprite2D
@onready var ultimate_sfx: AudioStreamPlayer2D = $UltimateVFXDamage/Sfx
@export var ultimate_cooldown_time: float = 3.0
@export var ultimate_damage_amount: int = 200
func activate_ultimate_and_cooldown():
	if is_ultimate_on_cooldown or is_instance_valid(current_ultimate_instance):
		return
	is_ultimate_on_cooldown = true
	ultimate_cooldown_timer.start(ultimate_cooldown_time)
	get_tree().paused = true 
	current_ultimate_instance = ultimate_scene_prefab.instantiate()
	get_tree().get_root().call_deferred("add_child", current_ultimate_instance) 
	if current_ultimate_instance.has_signal("ultimate_finished"):
		current_ultimate_instance.ultimate_finished.connect(Callable(self, "_on_ultimate_scene_finished"))

func _on_ultimate_cooldown_timeout():
	is_ultimate_on_cooldown = false

const VFX_OFFSET_X: float = 400.0
func _on_ultimate_scene_finished():
	if is_instance_valid(current_ultimate_instance):
		if current_ultimate_instance.is_connected("ultimate_finished", Callable(self, "_on_ultimate_scene_finished")):
			current_ultimate_instance.ultimate_finished.disconnect(Callable(self, "_on_ultimate_scene_finished"))
			get_tree().paused = false
			current_ultimate_instance = null
			has_ultimate_damage_applied = false
			var target_x: float = self.global_position.x
			if is_instance_valid(sprite):
				ultimate_vfx_sprite.flip_h = sprite.flip_h 
				if sprite.flip_h:
					target_x -= VFX_OFFSET_X
				else:
					target_x += VFX_OFFSET_X
			var world_pos = Vector2(target_x, global_position.y)
			ultimate_vfx_damage.global_position = world_pos
			var world_transform = ultimate_vfx_damage.global_transform
			ultimate_vfx_damage.get_parent().remove_child(ultimate_vfx_damage)
			get_tree().current_scene.add_child(ultimate_vfx_damage)
			ultimate_vfx_damage.global_transform = world_transform
			ultimate_vfx_sprite.flip_h = sprite.flip_h
			ultimate_vfx_damage.show()
			ultimate_vfx_damage.set_deferred("monitoring", true)
			ultimate_vfx_sprite.play("vfxanim")
			ultimate_sfx.play()
			ultimate_vfx_sprite.animation_finished.connect(Callable(self, "_on_vfx_animation_finished"), CONNECT_ONE_SHOT)
			
	else:
		get_tree().paused = false
		current_ultimate_instance = null
		print("Ultimate sequence finished, node already freed. Game resumed.")
		
func _on_vfx_animation_finished():
	ultimate_vfx_damage.set_deferred("monitoring", false)
	ultimate_vfx_damage.hide()
	
	
func _on_ultimate_vfx_damage_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy") and not has_ultimate_damage_applied:
		var enemy_root = area.get_parent()
		if enemy_root and enemy_root.has_method("take_damage"):
			enemy_root.take_damage(ultimate_damage_amount)
			#has_ultimate_damage_applied = false
			
func apply_buff(buff_type):
	match buff_type:
		"speed":
			speed *= 1.5
		"damage":
			attack_damage *= 2.0
		"heal":
			current_health *= 1.2
			current_health = clamp(current_health, 0, max_hp)
			health_changed.emit(current_health)

var total_coins: int = 0
@onready var coin_label: Label = $"../CanvasLayer/CoinLabel"
func add_coin(amount: int):
	total_coins += amount
	update_coin_ui()

func update_coin_ui():
	if coin_label:
		coin_label.text = str(total_coins)
