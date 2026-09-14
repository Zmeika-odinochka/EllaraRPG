extends CharacterBody2D

const SPEED: float = 105.0
var controls_enabled: bool = true
var facing: Vector2 = Vector2.DOWN
var combat_movement_scale := 1.0
@onready var appearance: Node2D = $Appearance


func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	if controls_enabled:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED * combat_movement_scale
	if not direction.is_zero_approx():
		if absf(direction.x) > absf(direction.y):
			facing = Vector2(signf(direction.x), 0)
		else:
			facing = Vector2(0, signf(direction.y))
	move_and_slide()
	appearance.facing = facing
	if appearance.attack_time >= 0.0 and appearance.attack_time < 0.34:
		var aim: Vector2 = appearance.attack_direction
		appearance.facing = Vector2(signf(aim.x),0) if absf(aim.x)>absf(aim.y) else Vector2(0,signf(aim.y))
	appearance.walking = velocity.length_squared() > 1.0


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
		appearance.walking = false
