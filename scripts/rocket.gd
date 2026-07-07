extends Node3D

var id:int



func _ready() -> void:
	$MultiplayerSynchronizer.set_multiplayer_authority(1)
	if not is_multiplayer_authority():
		get_child(0).freeze = true
