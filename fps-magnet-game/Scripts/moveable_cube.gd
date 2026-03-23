class_name Cube
extends RigidBody3D

var touched = false
var hand = "left"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func set_touched(b:bool):
	touched = b

func set_hand(h:String):
	hand = h
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if touched:
		match hand:
			"left":
				global_transform.origin = global_transform.origin.move_toward(Global.player_point,Global.hand_speed)
			"right":
				global_transform.origin = global_transform.origin.move_toward(Global.right_farthest_point,Global.hand_speed)
