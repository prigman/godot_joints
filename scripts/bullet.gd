extends RigidBody3D

@export var lifeTime := 5.0

func _ready() -> void:
	get_tree().create_timer(lifeTime).timeout.connect(queue_free)

func _on_body_entered(_body: Node) -> void:
	pass
