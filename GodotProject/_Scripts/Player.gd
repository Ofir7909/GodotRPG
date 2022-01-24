extends KinematicBody2D

# Public Variables
export var moveSpeed: float = 30
export var acceleration: float = 30
export var friction: float = 30
export var attackAnimationMaxRotation: float = 60
export var attackAnimationTime: float = 0.3

# Nodes
onready var animPlayer := $AnimationPlayer
onready var sprite := $YSort/Sprite
onready var tween := $Tween
onready var attackCD := $AttackCD
onready var weaponPivot := $YSort/WeaponPivot

# Private Variables
var velocity := Vector2.ZERO
var weaponRotationOffset: float = 0


func _process(delta: float) -> void:
	# facing
	var mousePos := get_global_mouse_position()
	sprite.set_flip_h(mousePos.x < get_position().x)
	weaponPivot.scale.y = -1 if (mousePos.x < get_position().x) else 1

	# aiming
	weaponPivot.look_at(mousePos)
	weaponPivot.rotation_degrees += weaponRotationOffset

	# attacking
	if Input.is_action_pressed("attack") && attackCD.is_stopped():
		attackCD.start()  # Start cooldown for next attack
		attackAnimationMaxRotation *= -1  # change sword position from top to bottom
		tween.interpolate_property(
			self,
			"weaponRotationOffset",
			null,
			attackAnimationMaxRotation,
			attackAnimationTime,
			tween.TRANS_BACK,
			tween.EASE_OUT
		)
		tween.start()


func _physics_process(delta: float) -> void:
	var moveInput := Vector2(
		Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")
	)
	if moveInput != Vector2.ZERO:
		# move in input direction
		velocity = velocity.move_toward(moveInput.normalized() * moveSpeed, acceleration * delta)
		animPlayer.play("Walk")
	else:
		# slow down by friction
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		animPlayer.play("Idle")

	velocity = move_and_slide(velocity)
