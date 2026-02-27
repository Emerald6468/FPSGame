extends RayCast3D

@onready var debug_scene = preload("res://Prefabs/Debug.tscn")
var debug_created = false
var collision_point: Vector3
var target_point: Vector3
var debug_obj
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_debug()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_colliding(): create_point()
	else: 
		target_point = get_target_position()
		match Global.leftclicked:
			true: if Global.justclicked and !Global.left_extending: Global.left_raycast_point = target_point
			false: if Global.justclicked and !Global.right_extending: Global.right_raycast_point = target_point
		if Global.justclicked: Global.collider_point = target_point


func create_point():
	collision_point = get_collision_point()
	match Global.leftclicked:
		true: if Global.justclicked and !Global.left_extending: Global.left_raycast_point = collision_point
		false: if Global.justclicked and !Global.right_extending: Global.right_raycast_point = collision_point
	create_debug()

func create_debug():
	if !debug_created:
		debug_created = true
		print("colliding")
		print(collision_point)
		debug_obj = debug_scene.instantiate()
		add_sibling.call_deferred(debug_obj)
		debug_obj.global_position = collision_point
	else:
		debug_obj.global_position = collision_point
		
