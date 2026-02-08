extends CharacterBody3D

@onready var camera3d: Camera3D = $Camera3D

const SPEED := 5.0
const JUMP_VELOCITY := 4.5

var lookDirection: Vector2
var cameraSensitivity := 1.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"): get_tree().quit()
	if event is InputEventMouseMotion:
		lookDirection = event.relative * 0.001
		#camera3d.rotation.y -= lookDirection.x * cameraSensitivity
		camera3d.rotation.x = clamp(camera3d.rotation.x - lookDirection.y * cameraSensitivity, -1.5, 1.5)
		rotation.y -= lookDirection.x * cameraSensitivity

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var inputDir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var direction := (transform.basis * Vector3(inputDir.x, 0, inputDir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
