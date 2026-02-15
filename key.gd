extends Area3D

func _ready():
	# Make the key rotate for visual feedback
	var tween = create_tween().set_loops()
	tween.tween_property(get_node("MeshInstance3D"), "rotation:y", PI * 2, 2.0).as_relative()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("collect_key"):
			body.collect_key()
			queue_free()
