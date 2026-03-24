extends CharacterBody3D

@export_category("Controls")
@export var SPEED = 10.0
var current_speed = SPEED
@export var JUMP_VELOCITY = 4.5

#camera
var look_dir:Vector2
@onready var camera: Camera3D = $Camera3D
@export var camera_sens = 50

#arm variables
@export var handspeed = 10
@onready var despawn_zone: Area3D = $Despawn_Zone
var dont_check = false

@onready var left_spawn_point: Node3D = %Left_Spawn_Point
@onready var right_spawn_point: Node3D = %Right_Spawn_Point

@onready var left_hand_scene = preload("res://Prefabs/left_hand.tscn")
@onready var right_hand_scene = preload("res://Prefabs/right_hand.tscn")

var left_hand_instance: Node3D = null
var right_hand_instance: Node3D = null
var left_arm_visual: MeshInstance3D = null
var right_arm_visual: MeshInstance3D = null

@export var player_ray_cast: RayCast3D
@onready var farthest_point: Marker3D = $FarthestPoint

#Sounds
@onready var step_1: AudioStreamPlayer = %Step1
@onready var step_2: AudioStreamPlayer = $Step2
@onready var step_3: AudioStreamPlayer = $Step3
@onready var step_4: AudioStreamPlayer = $Step4
@onready var step_5: AudioStreamPlayer = $Step5
@onready var current_step_sound = step_1
var step_num = 1

func _ready() -> void:
	left_arm_visual = _create_arm_visual_node("LeftArmVisual")
	right_arm_visual = _create_arm_visual_node("RightArmVisual")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	
	if not is_on_floor() and motion_mode == MOTION_MODE_GROUNDED:
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("test_left"):left_clicked()
	if Input.is_action_just_pressed("test_right"):right_clicked()
	# Get the input direction and handle the movement/deceleration.
	#MOVEMENT
	if Global.player_pulled:
		set_motion_mode(MOTION_MODE_FLOATING)
		global_transform.origin = global_transform.origin.move_toward(Global.left_raycast_point,Global.hand_speed)
	elif Global.player_pushed:
		pass
	else:
		set_motion_mode(MOTION_MODE_GROUNDED)
		if !Global.left_arm_out and !Global.right_arm_out: current_speed = SPEED
		else: current_speed = 2.0
		var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
		if velocity.x > .5 or velocity.z > .5: step_sounds()
	Global.player_point = self.global_position
	

	
	
	#checks to see if it needs to delete hands
	var body_list = despawn_zone.get_overlapping_bodies()
	#print(body_list)
	
	if despawn_zone.has_overlapping_bodies() and !dont_check:
		for body in body_list:
			if body is Cube:
				body.set_touched(false)
			if body is Hand:
				var hand : Hand = body
				if hand.hand == "left":
					hand.queue_free()
					left_hand_instance = null
					set_deferred("Global.player_pulled",false)
					Global.left_holding_on = false
					Global.left_arm_out = false
				if hand.hand == "right":
					hand.queue_free()
					right_hand_instance = null
					Global.right_holding_on = false
					Global.right_arm_out = false
	_rotate_camera(delta)
	move_and_slide()
	_update_arm_visuals()
	
func _input(event: InputEvent):
	if event is InputEventMouseMotion: look_dir = event.relative * 0.01
	#hand stuff
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("left_click"):
			left_clicked()
		if Input.is_action_just_pressed("right_click"):
			right_clicked()
	

func left_clicked():
	Global.leftclicked = true
	Global.left_extending = !Global.left_extending
	Global.justclicked = true;
	player_ray_cast.clicked()
	Global.left_farthest_point = farthest_point.global_position
	if !Global.left_arm_out: call_deferred("spawn_lefthand")
	Global.set_deferred("just_clicked", false)

func right_clicked():
	Global.leftclicked = false
	Global.right_extending = !Global.right_extending
	Global.justclicked = true;
	player_ray_cast.clicked()
	Global.right_farthest_point = farthest_point.global_position
	if !Global.right_arm_out: call_deferred("spawn_righthand")
	Global.set_deferred("just_clicked", false)
	
func spawn_lefthand():
	Global.left_arm_out = true
	var left_hand = left_hand_scene.instantiate()
	left_hand_instance = left_hand
	dont_check = true
	add_sibling(left_hand)
	left_hand.transform = left_spawn_point.global_transform
	dont_check = false

func spawn_righthand():
	Global.right_arm_out = true
	Global.right_arm_out = true
	var right_hand = right_hand_scene.instantiate()
	right_hand_instance = right_hand
	dont_check = true
	add_sibling(right_hand)
	right_hand.transform = right_spawn_point.global_transform
	dont_check = false

func _create_arm_visual_node(node_name: String) -> MeshInstance3D:
	var arm_mesh_instance := MeshInstance3D.new()
	arm_mesh_instance.name = node_name
	arm_mesh_instance.top_level = true
	arm_mesh_instance.visible = false
	arm_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var arm_mesh := CylinderMesh.new()
	arm_mesh.height = 1.0
	arm_mesh.top_radius = 0.045
	arm_mesh.bottom_radius = 0.045

	var arm_material := StandardMaterial3D.new()
	arm_material.albedo_color = Color.WHITE
	arm_mesh.material = arm_material

	arm_mesh_instance.mesh = arm_mesh
	add_child(arm_mesh_instance)
	return arm_mesh_instance

func _update_arm_visuals() -> void:
	if left_hand_instance != null and !is_instance_valid(left_hand_instance):
		left_hand_instance = null
	if right_hand_instance != null and !is_instance_valid(right_hand_instance):
		right_hand_instance = null

	_update_arm_visual(left_arm_visual, left_spawn_point.global_position, left_hand_instance, Global.left_arm_out)
	_update_arm_visual(right_arm_visual, right_spawn_point.global_position, right_hand_instance, Global.right_arm_out)

func _update_arm_visual(arm_mesh: MeshInstance3D, start_point: Vector3, hand_node: Node3D, arm_out: bool) -> void:
	if arm_mesh == null:
		return

	if !arm_out or hand_node == null or !is_instance_valid(hand_node):
		arm_mesh.visible = false
		return

	var end_point := hand_node.global_position
	var arm_dir := end_point - start_point
	var arm_length := arm_dir.length()
	if arm_length <= 0.01:
		arm_mesh.visible = false
		return

	var y_axis := arm_dir / arm_length
	var x_axis := Vector3.FORWARD.cross(y_axis)
	if x_axis.length() <= 0.01:
		x_axis = Vector3.RIGHT.cross(y_axis)
	x_axis = x_axis.normalized()
	var z_axis := x_axis.cross(y_axis).normalized()

	arm_mesh.global_transform = Transform3D(Basis(x_axis, y_axis, z_axis), (start_point + end_point) * 0.5)
	arm_mesh.scale = Vector3(1.0, arm_length, 1.0)
	arm_mesh.visible = true

func _rotate_camera(delta: float, sens_mod: float = 1.0):
	var input := Input.get_vector("ui_left","ui_right","ui_down","ui_up")
	look_dir += input
	rotation.y -= look_dir.x * camera_sens * delta
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod * delta, -1.5,1.5)
	look_dir = Vector2.ZERO
	
func step_sounds():
	if !current_step_sound.playing:
		step_num = round(randf_range(1,5))
		match step_num:
			1:
				current_step_sound = step_1
			2:
				current_step_sound = step_2
			3:
				current_step_sound = step_4
			4:
				current_step_sound = step_5
			5:
				current_step_sound = step_1
		current_step_sound.play()
	pass
