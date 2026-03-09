extends Node3D

## Set theses in the inspector please
@export var position_a: Vector3 = Vector3.ZERO
@export var position_b: Vector3 = Vector3(5, 0, 0)
@export var speed: float = 0.2

var elapsed_time: float = 0.0


func _ready() -> void:
	# Start exactly at the first endpoint
	global_position = position_a


func _physics_process(delta: float) -> void:
	elapsed_time += delta * speed
	var t: float = (sin(elapsed_time * PI) + 1.0) / 2.0
	global_position = position_a.lerp(position_b, t)
