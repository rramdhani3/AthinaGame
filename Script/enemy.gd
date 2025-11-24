extends CharacterBody2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_attack: AnimationPlayer = $AnimationPlayer
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackAreaRange

@export var speed: float = 80.0
@export var player_y_offset: float = 108.0
@export var attack_damage_enemy := 4

enum { CHASE, ATTACK }
var current_state = CHASE
var player_target: CharacterBody2D = null
var current_health := 200
var fade_duration := 0.5
 
func _ready():
	player_target = get_tree().get_first_node_in_group("player")
	current_state = CHASE

func _physics_process(delta):
	match current_state:
		CHASE:
			if player_target and current_health > 0:
				chase_player()
			else:
				velocity = Vector2.ZERO
		
		ATTACK:
			velocity = Vector2.ZERO
			if anim_attack.current_animation != "attack":
				anim_attack.play("attack")
			
	move_and_slide()
	
func chase_player():
	var player_floor_y = player_target.global_position.y + player_y_offset
	var target_position = Vector2(player_target.global_position.x, player_floor_y)
	var direction = (target_position - global_position).normalized()
	velocity.x = direction.x * speed
	velocity.y = direction.y * speed
	anim_sprite.play("walk")
	if direction.x > 0:
		anim_sprite.flip_h = false
	elif direction.x < 0:
		anim_sprite.flip_h = true

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerAttack"):
		var player_root = area.get_parent().get_parent()
		var damage = player_root.attack_damage
		take_damage(damage)
		area.set_deferred("monitoring", false)

func take_damage(amount: int):
	current_health -= amount
	$TextureProgressBar.value = current_health
	if current_health <= 0:
		die()
		return
	else:
		if anim_sprite.animation_finished.is_connected(Callable(self, "back_to_chase")):
			anim_sprite.animation_finished.disconnect(Callable(self, "back_to_chase"))
	anim_sprite.play("hurt")
	anim_sprite.animation_finished.connect(Callable(self, "back_to_chase"), CONNECT_ONE_SHOT)
	print("Enemy took damage. Health: ", current_health)

func start_fade_out():
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_tween.tween_callback(Callable(self, "after_die"))

func die():
	hurtbox.set_deferred("monitoring", false)
	anim_sprite.play("die")
	set_physics_process(false)
	set_process(false)
	if anim_sprite.animation_finished.is_connected(Callable(self, "start_fade_out")):
		anim_sprite.animation_finished.disconnect(Callable(self, "start_fade_out"))
	anim_sprite.animation_finished.connect(Callable(self, "start_fade_out"), CONNECT_ONE_SHOT)

func back_to_chase():
	if current_health > 0:
		current_state = CHASE

func after_die():
		queue_free()

func _on_attack_area_range_body_entered(body: Node2D) -> void:
	if body == player_target:
		current_state = ATTACK
		
func _on_attack_area_range_body_exited(body: Node2D) -> void:
	if body == player_target:
		current_state = CHASE

func give_damage_to_player():
	if player_target:
		if player_target.has_method("take_damage"):
			player_target.take_damage(attack_damage_enemy)
