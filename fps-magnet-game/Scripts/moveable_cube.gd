extends CSGBox3D

var touched = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func set_touched(b:bool):
	touched = b
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if touched and Global.left_holding_on:
		global_transform.origin = global_transform.origin.move_toward(Global.player_point,Global.hand_speed)
