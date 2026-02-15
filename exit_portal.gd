extends Area3D

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_key:
			if body.has_method("win"):
				body.win()
		else:
			if body.has_method("display_message"):
				body.display_message("¡NECESITAS LA LLAVE!")
