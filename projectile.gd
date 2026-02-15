extends Area3D

@export var speed = 20.0
@export var damage = 10.0
@export var lifetime = 5.0

var is_slow = false

func _ready():
	if is_slow:
		# Change visual to blue
		var mesh = $MeshInstance3D
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0, 0, 1) # Blue
		mat.emission_enabled = true
		mat.emission = Color(0, 0, 1)
		mesh.set_surface_override_material(0, mat)
		
	# Automatically destroy the projectile after its lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	# Move the projectile forward in its local Z axis
	position -= transform.basis.z * speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		if is_slow and body.has_method("apply_slow"):
			body.apply_slow()
		body.take_damage(damage)
		queue_free()
	elif body is StaticBody3D:
		# Hit a wall or floor
		queue_free()
