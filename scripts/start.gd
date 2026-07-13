extends Button



func _on_host_pressed() -> void:
	disabled = false


func _on_pressed() -> void:
	show_crossair.rpc()
	queue_free()

@rpc("any_peer","call_local","reliable")
func show_crossair() -> void:
	$"../ColorRect".show()
	$"../ColorRect2".show()
