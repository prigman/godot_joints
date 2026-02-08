extends Node3D

@export var bodyRoot: RigidBody3D
@export var cameraRoot: Node3D
@export var head: RigidBody3D

@export var velocityStiffness := 50.0 #speed acceleration / the higher, the faster the speed is achieved
@export var velocityDamping := 10.0 #braking, smoothness / dampens jerks, leaves smoothness

@onready var r_leg_1: RigidBody3D = $RLeg1
@onready var r_leg_3: RigidBody3D = $Node3D/RLeg3

const CAMERA_MIN_PITCH := deg_to_rad(-60)
const CAMERA_MAX_PITCH := deg_to_rad(80)

const MOVE_SPEED := 7.0
const ANGULAR_SPEED := 6.0

var lookDirection: Vector2
var cameraSensitivity := 1.0

func _physics_process(_delta: float):
	var inputDir = Vector3.ZERO
	var velocity = Vector3.ZERO

	if Input.is_action_pressed("ui_up"):
		inputDir.z -= 1
	if Input.is_action_pressed("ui_down"):
		inputDir.z += 1
	if Input.is_action_pressed("ui_left"):
		inputDir.x -= 1
	if Input.is_action_pressed("ui_right"):
		inputDir.x += 1

	if inputDir.length():
		inputDir = inputDir.normalized()
		var camBasis = cameraRoot.global_transform.basis
		var moveDir = (camBasis.x * inputDir.x + camBasis.z * inputDir.z)
		velocity = moveDir.normalized() * MOVE_SPEED
	
	var velocityDifference = velocity - bodyRoot.linear_velocity
	var force = velocityDifference * bodyRoot.mass * velocityStiffness - bodyRoot.linear_velocity * velocityDamping
	bodyRoot.apply_central_force(force)
	
	cameraRoot.global_transform.origin = head.global_transform.origin + Vector3(0, .35, 0)
	
	var cameraForward = -cameraRoot.global_transform.basis.z
	cameraForward.y = 0
	cameraForward = cameraForward.normalized()

	var bodyRootForward = -bodyRoot.global_transform.basis.z
	bodyRootForward.y = 0
	bodyRootForward = bodyRootForward.normalized()

	var angle = bodyRootForward.signed_angle_to(cameraForward, Vector3.UP)

	var targetAngular = angle * 10.0
	targetAngular = clamp(targetAngular, -ANGULAR_SPEED, ANGULAR_SPEED)

	bodyRoot.angular_velocity.y = targetAngular


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"): get_tree().quit()
	if event is InputEventMouseMotion:
		lookDirection = event.relative * 0.001
		cameraRoot.rotation.x = clamp(cameraRoot.rotation.x - lookDirection.y * cameraSensitivity, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)
		cameraRoot.rotation.y -= lookDirection.x * cameraSensitivity
