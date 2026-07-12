extends Control


func _on_button_pressed() -> void:
	_tween_everywhere.rpc()
	
@rpc("any_peer","call_local","reliable")
func _tween_everywhere() -> void:
	var tween = create_tween()
	get_parent().get_node("black").modulate.a = 0
	tween.tween_property(get_parent().get_node("black"),"modulate:a",1,2)
	tween.finished.connect(_reset)
	

func _reset() -> void:
	var tween = create_tween()
	get_parent().get_node("black").modulate.a = 1
	tween.tween_property(get_parent().get_node("black"),"modulate:a",0,2)
	get_parent().get_parent().get_choices.rpc()
	hide()
	
