extends Node3D

@export var bodyRoot: RigidBody3D
@export var cameraRoot: Node3D
@export var head: RigidBody3D

@export var velocityStiffness := 50.0 #speed acceleration / the higher, the faster the speed is achieved
@export var velocityDamping := 10.0 #braking, smoothness / dampens jerks, leaves smoothness
@export var transformStiffness := 10.0
@export var transformDamping := 2.0

@export var rightArm1: RigidBody3D
@export var rightArm2: RigidBody3D

const CAMERA_MIN_PITCH := deg_to_rad(-60)
const CAMERA_MAX_PITCH := deg_to_rad(80)

const MOVE_SPEED := 7.0
const ANGULAR_SPEED := 6.0

const CAMERA_Y_OFFSET := 0.35

var lookDirection: Vector2
var cameraSensitivity := 1.0

func _physics_process(_delta: float):
	var inputDir := Vector3.ZERO
	var velocity := Vector3.ZERO

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
		var camBasis := cameraRoot.global_transform.basis
		var moveDir := (camBasis.x * inputDir.x + camBasis.z * inputDir.z)
		velocity = moveDir.normalized() * MOVE_SPEED
	
	var velocityDifference := velocity - bodyRoot.linear_velocity
	var force := velocityDifference * bodyRoot.mass * velocityStiffness - bodyRoot.linear_velocity * velocityDamping
	bodyRoot.apply_central_force(force)
	
	cameraRoot.global_transform.origin = head.global_transform.origin + Vector3(0, CAMERA_Y_OFFSET, 0) # Move camera position to the head
	
	# rotate bodyRoot to the camera direction
	bodyRoot.angular_velocity.y = getTargetAngular(cameraRoot)
	
	var targetPosition = cameraRoot.global_transform.origin + cameraRoot.global_transform.basis.z * 2.0
	var upperArmTorque = getTargetTorque(rightArm1, targetPosition)
	var lowerArmTorque = getTargetTorque(rightArm2, targetPosition)
	rightArm1.apply_torque(upperArmTorque)
	rightArm2.apply_torque(lowerArmTorque)

func getTargetTorque(entity: RigidBody3D, targetPosition: Vector3):
	var entityPostion := entity.global_transform.origin
	var direction := (targetPosition - entityPostion).normalized()
	var currentRotation := entity.global_transform.basis.get_rotation_quaternion()
	var targetRotation := Quaternion(Vector3.FORWARD, direction)
	var torque := (targetRotation * currentRotation.inverse()).get_euler() * transformStiffness
	torque -= entity.angular_velocity * transformDamping
	return torque

func getTargetAngular(entity: Node3D) -> float: 
	var entityForward := -entity.global_transform.basis.z
	entityForward = entityForward.normalized()

	var bodyRootForward := -bodyRoot.global_transform.basis.z
	bodyRootForward = bodyRootForward.normalized()

	var angle := bodyRootForward.signed_angle_to(entityForward, Vector3.UP)

	var targetAngular := angle * 10.0
	targetAngular = clamp(targetAngular, -ANGULAR_SPEED, ANGULAR_SPEED)

	return targetAngular


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"): get_tree().quit()
	if event is InputEventMouseMotion:
		lookDirection = event.relative * 0.001
		cameraRoot.rotation.x = clamp(cameraRoot.rotation.x - lookDirection.y * cameraSensitivity, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)
		cameraRoot.rotation.y -= lookDirection.x * cameraSensitivity
