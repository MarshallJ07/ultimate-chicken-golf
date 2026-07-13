extends Button



func _on_host_pressed() -> void:
	disabled = false


func _on_pressed() -> void:
	$"../ColorRect".show()
	$"../ColorRect2".show()
	queue_free()
