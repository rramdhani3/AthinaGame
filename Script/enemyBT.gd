extends CharacterBody2D

@onready var anim_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var anim_attack: AnimationPlayer = $AnimationPlayer
@onready var visual: Node2D = $Visual
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackAreaRange
@export var speed: float = 80.0
@export var speed_run: float = 150.0
@export var player_y_offset: float = 108.0
@export var attack_damage_enemy := 4


const MAX_HEALTH = 200
const FLEE_THRESHOLD = MAX_HEALTH / 2.0
var current_health := MAX_HEALTH
var player_target: CharacterBody2D = null
var fade_duration := 0.5

# BEHAVIOR TREE CORE
enum BTStatus { SUCCESS, FAILURE, RUNNING }
class BTNode:
	func tick(enemy) -> int:
		return BTStatus.FAILURE

class Selector extends BTNode:
	var children := []

	func _init(_children):
		children = _children

	func tick(enemy) -> int:
		for child in children:
			var status = child.tick(enemy)
			if status != BTStatus.FAILURE:
				return status
		return BTStatus.FAILURE


class Sequence extends BTNode:
	var children := []

	func _init(_children):
		children = _children

	func tick(enemy) -> int:
		for child in children:
			var status = child.tick(enemy)
			if status != BTStatus.SUCCESS:
				return status
		return BTStatus.SUCCESS

var has_logged_spawn := false
func log_bt(context: String, detail: String):
	print("[BT][", context, "] ", detail)

# CONDITION NODES
class CondLowHP extends BTNode:
	func tick(enemy) -> int:
		var result = enemy.current_health <= FLEE_THRESHOLD
		return BTStatus.SUCCESS if result else BTStatus.FAILURE

class CondPlayerInAttackRange extends BTNode:
	func tick(enemy) -> int:
		var in_range = enemy.attack_area.get_overlapping_bodies().has(enemy.player_target)
		return BTStatus.SUCCESS if in_range else BTStatus.FAILURE

class CondPlayerExist extends BTNode:
	func tick(enemy) -> int:
		var exist = enemy.player_target != null
		return BTStatus.SUCCESS if exist else BTStatus.FAILURE


# ACTION NODES
class ActFlee extends BTNode:
	func tick(enemy) -> int:
		enemy.flee_player()
		return BTStatus.RUNNING

class ActAttack extends BTNode:
	func tick(enemy) -> int:
		enemy.attack_player()
		return BTStatus.RUNNING

class ActChase extends BTNode:
	func tick(enemy) -> int:
		enemy.chase_player()
		return BTStatus.RUNNING

# BT ROOT
var bt_root: BTNode
#LIFECYCLE
func _ready():
	player_target = get_tree().get_first_node_in_group("player")

	bt_root = Selector.new([
		Sequence.new([
			CondLowHP.new(),
			ActFlee.new()
		]),
		Sequence.new([
			CondPlayerInAttackRange.new(),
			ActAttack.new()
		]),
		Sequence.new([
			CondPlayerExist.new(),
			ActChase.new()
		])
	])
	if not has_logged_spawn:
		log_bt("SPAWN", "HP:" + str(current_health))
		has_logged_spawn = true

func _physics_process(delta):
	if current_health <= 0:
		return

	bt_root.tick(self)
	move_and_slide()


func chase_player():
	var player_floor_y = player_target.global_position.y + player_y_offset
	var target_position = Vector2(player_target.global_position.x, player_floor_y)
	var direction = (target_position - global_position).normalized()

	velocity = direction * speed
	anim_sprite.play("walk")
	#anim_sprite.flip_h = direction.x < 0
	if direction.x != 0:
		visual.scale.x = sign(direction.x)


func flee_player():
	var player_floor_y = player_target.global_position.y + player_y_offset
	var target_position = Vector2(player_target.global_position.x, player_floor_y)
	var flee_direction = (target_position - global_position).normalized() * -1

	velocity = flee_direction * speed_run
	anim_sprite.play("run")
	#anim_sprite.flip_h = flee_direction.x < 0
	if flee_direction.x != 0:
		visual.scale.x = sign(flee_direction.x)


func attack_player():
	velocity = Vector2.ZERO
	if anim_attack.current_animation != "attack":
		anim_attack.play("attack")
		$SfxAtt.play()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerAttack"):
		var player_root = area.get_parent().get_parent()
		var damage = player_root.attack_damage
		take_damage(damage)
		area.set_deferred("monitoring", false)

func flash_red():
	var tween = create_tween()
	visual.modulate = Color(1, 0.2, 0.2)
	tween.tween_property(visual, "modulate", Color(1,1,1), 0.15)
	
func take_damage(amount: int):
	current_health -= amount
	$TextureProgressBar.value = current_health
	flash_red()
	log_bt(
		"DAMAGE",
		"HP:" + str(current_health) +
		" | LowHP:" + str(current_health <= FLEE_THRESHOLD)
	)
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

func give_damage_to_player():
	if player_target and player_target.has_method("take_damage"):
		player_target.take_damage(attack_damage_enemy)
