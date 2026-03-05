extends CharacterBody2D

@onready var anim_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var anim_attack: AnimationPlayer = $AnimationPlayer
@onready var visual: Node2D = $Visual
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackAreaRange
@export var speed := 80.0
@export var speed_run := 150.0
@export var player_y_offset := 108.0
@export var attack_damage_enemy := 10
@export var coin_scene: PackedScene
@export var coin_drop_amount: int = 5

const MAX_HEALTH := 200
var current_health := MAX_HEALTH

var player_target: CharacterBody2D
var can_attack := false
var fade_duration := 0.5

# Lifecycle
func _ready():
	player_target = get_tree().get_first_node_in_group("player")
	var u_attack := utility_attack()
	var u_flee   := utility_flee()
	var u_chase  := utility_chase()

	print(
		"Utility | Attack:", u_attack,
		" Flee:", u_flee,
		" Chase:", u_chase,
		" HP:", current_health
	)

func _physics_process(delta):
	if current_health <= 0 or player_target == null:
		return

	var u_attack := utility_attack()
	var u_flee   := utility_flee()
	var u_chase  := utility_chase()


	if u_flee >= u_attack and u_flee >= u_chase:
		flee_player()
	elif u_attack >= u_chase:
		attack_player()
	else:
		chase_player()

	move_and_slide()

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




# Actions
func attack_player():
	velocity = Vector2.ZERO
	if anim_attack.current_animation != "attack":
		anim_attack.play("attack")
		$SfxAtt.play()

func chase_player():
	var target_y = player_target.global_position.y + player_y_offset
	var target_pos = Vector2(player_target.global_position.x, target_y)
	var direction = (target_pos - global_position).normalized()

	velocity = direction * speed
	anim_sprite.play("walk")
	#anim_sprite.flip_h = dir.x < 0
	if direction.x != 0:
		visual.scale.x = sign(direction.x)

func flee_player():
	var target_y = player_target.global_position.y + player_y_offset
	var target_pos = Vector2(player_target.global_position.x, target_y)
	var flee_direction = (target_pos - global_position).normalized() * -1

	velocity = flee_direction * speed_run
	anim_sprite.play("run")
	#anim_sprite.flip_h = dir.x < 0
	if flee_direction.x != 0:
		visual.scale.x = sign(flee_direction.x)

# Damage & Death (Status System)
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerAttack"):
		var damage = area.get_parent().get_parent().attack_damage
		take_damage(damage)
		area.set_deferred("monitoring", false)

func take_damage(amount: int):
	current_health -= amount
	$TextureProgressBar.value = current_health
	flash_red()
	var u_attack := utility_attack()
	var u_flee   := utility_flee()
	var u_chase  := utility_chase()

	print(
		"Utility | Attack:", u_attack,
		" Flee:", u_flee,
		" Chase:", u_chase,
		" HP:", current_health
	)
	if anim_sprite.animation != "hurt":
		anim_sprite.play("hurt")
	if current_health <= 0:
		die()
		
func flash_red():
	var tween = create_tween()
	visual.modulate = Color(1, 0.2, 0.2)
	tween.tween_property(visual, "modulate", Color(1,1,1), 0.15)
	
func die():
	hurtbox.set_deferred("monitoring", false)
	anim_sprite.play("die")
	$SfxDie.play()
	set_physics_process(false)
	set_process(false)
	anim_sprite.animation_finished.connect(start_fade_out, CONNECT_ONE_SHOT)

func start_fade_out():
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_tween.tween_callback(after_die)

func after_die():
	queue_free()
	spawn_coins()

# Attack Range Sensor (Utility Input)
func _on_attack_area_range_body_entered(body: Node2D) -> void:
	if body == player_target:
		can_attack = true

func _on_attack_area_range_body_exited(body: Node2D) -> void:
	if body == player_target:
		can_attack = false
		anim_attack.stop()

# Damage Output
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
