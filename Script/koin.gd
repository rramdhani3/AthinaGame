extends Area2D

@export var coin_value: int = 1
@export var bounce_force: float = 250.0
@export var gravity_force: float = 300.0
@export var magnet_speed: float = 800.0
@export var magnet_radius: float = 250.0
@export var max_bounce: int = 4

var velocity: Vector2
var ground_y: float
var bounce_count := 0
var can_magnet := false
var player_ref: CharacterBody2D


func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	player_ref = get_tree().get_first_node_in_group("player")
	ground_y = global_position.y + 60.0

	velocity = Vector2(
		randf_range(-1.0, 1.0),
		-1.0
	).normalized() * bounce_force
	
	$PickupDelay.start()


func _physics_process(delta):
	if not can_magnet:
		velocity.y += gravity_force * delta
		global_position += velocity * delta
		
		if global_position.y >= ground_y and velocity.y > 0:
			if bounce_count < max_bounce:
				velocity.y = -velocity.y * 0.5
				bounce_count += 1
			else:
				global_position.y = ground_y
				velocity = Vector2.ZERO
	else:
		if player_ref:
			var dist = global_position.distance_to(player_ref.global_position)
			if dist <= magnet_radius:
				global_position = global_position.move_toward(
					player_ref.global_position,
					magnet_speed * delta
				)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("add_coin"):
			body.add_coin(coin_value)
		$Sprite2D.visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		$CoinReceived.play()
		await $CoinReceived.finished
		queue_free()
		
func _on_pickup_delay_timeout():
	can_magnet = true
