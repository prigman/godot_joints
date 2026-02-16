extends Node3D

@export var bodyRoot: RigidBody3D
@export var cameraRoot: Node3D
@export var camera: Camera3D
@export var head: RigidBody3D
@export var animationPlayer: AnimationPlayer
@export var skeleton: Skeleton3D
@export var playerRigHead: Node3D
@export var leftArmIk: CCDIK3D
@export var rightArmIk: CCDIK3D
@export var pickupJointLeft: HingeJoint3D
@export var pickupJointRight: HingeJoint3D
@export var pickupAreaLeft: Area3D
@export var pickupAreaRight: Area3D

@export var velocityStiffness := 50.0 #speed acceleration / the higher, the faster the speed is achieved
@export var velocityDamping := 10.0 #braking, smoothness / dampens jerks, leaves smoothness
@export var transformStiffness := 10.0
@export var transformDamping := 2.0
@export var animationStiffness := 500.0
@export var animationDamping := 2.0

@export var rightArm1: RigidBody3D
@export var rightArm2: RigidBody3D
@export var leftArm1: RigidBody3D
@export var leftArm2: RigidBody3D

@onready var bones := {
	"UpperArm.R": rightArm1,
	"LowerArm.R": rightArm2,
	"UpperArm.L": leftArm1,
	"LowerArm.L": leftArm2
}

var playerWeapon: RigidBody3D

const CAMERA_MIN_PITCH := deg_to_rad(-75)
const CAMERA_MAX_PITCH := deg_to_rad(80)

const MOVE_SPEED := 7.0
const ANGULAR_SPEED := 6.0

const CAMERA_Y_OFFSET := 0.1

var lookDirection: Vector2
var cameraSensitivity := 1.0

var isCursorHidden := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func isMoving() -> bool:
	return Input.is_action_pressed("ui_up") or \
		Input.is_action_pressed("ui_down") or \
		Input.is_action_pressed("ui_left") or \
		Input.is_action_pressed("ui_right")

func _process(_delta: float) -> void:
	if Input.is_action_pressed("shoot") and playerWeapon:
		playerWeapon.shoot()

func _physics_process(_delta: float) -> void:
	var inputDir := Vector3.ZERO
	var velocity := Vector3.ZERO
	
	if isMoving():
		animationPlayer.play("playerAnimLibrary/pose_1")
	else:
		animationPlayer.play("playerAnimLibrary/pose_2")
	
	if(Input.is_action_pressed("rightMouse")):
		leftArmIk.active = true
	else:
		leftArmIk.active = false
	if(Input.is_action_pressed("leftMouse")):
		rightArmIk.active = true
	else:
		rightArmIk.active = false
	
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
	
	cameraRoot.global_transform.origin = head.global_transform.origin # Move camera position to the head
	playerRigHead.global_transform.origin.y = cameraRoot.transform.origin.y
	
	# rotate bodyRoot to the camera direction
	bodyRoot.angular_velocity.y = getTargetAngular(camera)

func driveBone(boneName: String, body: RigidBody3D) -> void:
	var boneIdx := skeleton.find_bone(boneName)
	var boneWorldTransform := skeleton.global_transform * skeleton.get_bone_global_pose(boneIdx)
	var targetQuaternion := boneWorldTransform.basis.get_rotation_quaternion()
	
	var currentQuaternion := body.global_transform.basis.get_rotation_quaternion()

	var deltaQuaternion := targetQuaternion * currentQuaternion.inverse()
	
	var deltaEuler := deltaQuaternion.get_euler()
	
	var torque := deltaEuler * animationStiffness - body.angular_velocity * animationDamping
	body.apply_torque(torque)


func getTargetAngular(entity: Camera3D) -> float: 
	var entityForward := -entity.global_transform.basis.z
	entityForward.y = 0
	entityForward = entityForward.normalized()

	var bodyRootForward := -bodyRoot.global_transform.basis.z
	bodyRootForward.y = 0
	bodyRootForward = bodyRootForward.normalized()

	var angle := bodyRootForward.signed_angle_to(entityForward, Vector3.UP)

	var targetAngular := angle * 10.0
	targetAngular = clamp(targetAngular, -ANGULAR_SPEED, ANGULAR_SPEED)

	return targetAngular

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"): get_tree().quit()
	if Input.is_action_just_pressed("pickup"):
		pickupAreaLeft.monitoring = true
		pickupAreaRight.monitoring = true
	else:
		pickupAreaLeft.monitoring = false
		pickupAreaRight.monitoring = false
	if Input.is_action_just_pressed("drop"):
		if(playerWeapon):
			playerWeapon = null
		if(pickupJointLeft.node_a):
			pickupJointLeft.node_a = ''
			pickupJointLeft.node_b = ''
		if(pickupJointRight.node_a):
			pickupJointRight.node_a = ''
			pickupJointRight.node_b = ''
	if Input.is_action_just_pressed("ui_focus_next"):
		if isCursorHidden:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			isCursorHidden = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			isCursorHidden = true
	if event is InputEventMouseMotion:
		lookDirection = event.relative * 0.001
		camera.rotation.x = clamp(camera.rotation.x - lookDirection.y * cameraSensitivity, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)
		cameraRoot.rotation.y -= lookDirection.x * cameraSensitivity
		playerRigHead.rotation.x = camera.rotation.x

func syncRigidbodyToSkeleton():
	for boneName in bones.keys():
		driveBone(boneName, bones[boneName])

func _on_area_3d_body_entered(body: Node3D) -> void:
	if(leftArmIk.active):
		pickupJointLeft.node_a = leftArm2.get_path()
		pickupJointLeft.node_b = body.get_path()
		if(body.has_method('shoot')):
			playerWeapon = body

func _on_skeleton_3d_skeleton_updated() -> void:
	syncRigidbodyToSkeleton()

func _on_area_3d_body_right_entered(body: Node3D) -> void:
	if(rightArmIk.active):
		pickupJointRight.node_a = rightArm2.get_path()
		pickupJointRight.node_b = body.get_path()
		if(body.has_method('shoot')):
			playerWeapon = body
