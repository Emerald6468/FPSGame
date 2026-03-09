class_name DoorController
extends CSGBox3D

## settings
@export var open_offset: Vector3 = Vector3(0, 6, 0)
@export var move_speed := 5.0

var closed_position: Vector3
var open_position: Vector3
var is_open := false

func _ready() -> void:
	# save postions for resetting or death
	closed_position = position
	open_position = closed_position + open_offset
	add_to_group("LevelResettable")
	reset_state()

func _physics_process(delta: float) -> void:
	#annimate door
	var target := open_position if is_open else closed_position
	position = position.move_toward(target, move_speed * delta)

func set_open(value: bool) -> void:
	# Buttons call this 
	is_open = value

func reset_state() -> void:
	# Respawns always force doors back to closed
	is_open = false
	position = closed_position
