extends RigidBody3D

@export var bulletScene: PackedScene
@export var shootForce := 100.0
@export var recoilForce := 150.0
@export var horizontalRecoil := 100.0
@export var fireRate := 0.2
@export var muzzle: Marker3D
@export var shootTimer: Timer

func shoot() -> void:
	if shootTimer.is_stopped():
		executeShot()
		shootTimer.start(fireRate)

func executeShot() -> void:
	var bullet := bulletScene.instantiate() as RigidBody3D
	get_tree().root.add_child(bullet)
	
	bullet.global_transform = muzzle.global_transform
	
	var shootDirection = muzzle.global_transform.basis.z
	bullet.apply_central_impulse(shootDirection * shootForce)
	
	apply_recoil(shootDirection)

func apply_recoil(direction: Vector3) -> void:
	var recoilDirection = -direction

	apply_central_impulse(recoilDirection * recoilForce)
	
	var muzzleBasis = muzzle.global_transform.basis
	
	var upKick = muzzleBasis.x * (recoilForce * 0.5)
	var sideKick = muzzleBasis.y * (randf_range(-1.0, 1.0) * horizontalRecoil)
	
	var combinedTorque = upKick + sideKick
	
	apply_torque_impulse(combinedTorque)
