extends CharacterBody2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_attack: AnimationPlayer = $AnimationPlayer
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackAreaRange

@export var speed := 80.0
@export var speed_run := 150.0
@export var player_y_offset := 108.0
@export var attack_damage_enemy := 4

const MAX_HEALTH := 200
const FLEE_THRESHOLD := MAX_HEALTH / 2.0

var current_health := MAX_HEALTH
var player_target: CharacterBody2D
var fade_duration := 0.5


# Lifecycle
func _ready():
	player_target = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if current_health <= 0:
		return

	apply_rules()
	move_and_slide()


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
	var dir = (target_pos - global_position).normalized()

	velocity = dir * speed
	anim_sprite.play("walk")
	anim_sprite.flip_h = dir.x < 0

func attack_player():
	velocity = Vector2.ZERO
	if anim_attack.current_animation != "attack":
		anim_attack.play("attack")
		$SfxAtt.play()

func flee_player():
	var target_y = player_target.global_position.y + player_y_offset
	var target_pos = Vector2(player_target.global_position.x, target_y)
	var dir = (target_pos - global_position).normalized() * -1

	velocity = dir * speed_run
	anim_sprite.play("run")
	anim_sprite.flip_h = dir.x < 0

# Damage & Death (Status System)
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerAttack"):
		var damage = area.get_parent().get_parent().attack_damage
		take_damage(damage)
		area.set_deferred("monitoring", false)

func take_damage(amount: int):
	current_health -= amount
	$TextureProgressBar.value = current_health
	if anim_sprite.animation != "hurt":
		anim_sprite.play("hurt")
	if current_health <= 0:
		die()

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

# Damage Output
func give_damage_to_player():
	if player_target and player_target.has_method("take_damage"):
		player_target.take_damage(attack_damage_enemy)
