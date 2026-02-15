extends Area3D

@export var speed = 20.0
@export var damage = 10.0
@export var lifetime = 5.0

func _ready():
	# Automatically destroy the projectile after its lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	# Move the projectile forward in its local Z axis
	position -= transform.basis.z * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body is StaticBody3D:
		# Hit a wall or floor
		queue_free()
