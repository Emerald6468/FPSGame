extends RayCast3D

@onready var debug_scene = preload("res://Prefabs/Debug.tscn")
@onready var farthest_point: Marker3D = $FarthestPoint

var debug_created = false
var collision_point: Vector3
var target_point: Vector3
var debug_obj
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#create_debug()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
		
	

func clicked():
	if is_colliding(): create_point()
	else: 
		target_point = farthest_point.global_position
		match Global.leftclicked:
			true: 
				if !Global.left_arm_out:
					Global.left_collision = false 
					Global.left_raycast_point = target_point
			false: 
				if !Global.right_arm_out: 
					Global.right_collision = false
					Global.right_raycast_point = target_point

func create_point():
	collision_point = get_collision_point()
	match Global.leftclicked:
		true: if !Global.left_arm_out:
			Global.left_collision = true
			Global.left_raycast_point = collision_point
		false: if !Global.right_arm_out: 
			Global.right_collision = true
			Global.right_raycast_point = collision_point
	#create_debug()

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
		
