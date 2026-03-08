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


func _physics_process(delta: float) -> void:
	# Add the gravity.
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("test_left"):left_clicked()
	if Input.is_action_just_pressed("test_right"):right_clicked()
	# Get the input direction and handle the movement/deceleration.
	#MOVEMENT
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
	Global.player_point = self.global_position

	
	
	#checks to see if it needs to delete hands
	var body_list = despawn_zone.get_overlapping_bodies()
	#print(body_list)
	
	if despawn_zone.has_overlapping_bodies() and !dont_check:
		for body in body_list:
			if body is Hand:
				var hand : Hand = body
				if hand.hand == "left":
					hand.queue_free()
					Global.left_arm_out = false
				if hand.hand == "right":
					hand.queue_free()
					Global.right_arm_out = false
	_rotate_camera(delta)
	move_and_slide()
	
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
	print("clicked left")
	if !Global.left_arm_out: spawn_lefthand()

func right_clicked():
	Global.leftclicked = false
	Global.right_extending = !Global.right_extending
	Global.justclicked = true;
	print("clicked right")
	if !Global.right_arm_out: spawn_righthand()
	
func spawn_lefthand():
	Global.left_arm_out = true
	var left_hand = left_hand_scene.instantiate()
	dont_check = true
	add_sibling(left_hand)
	left_hand.transform = left_spawn_point.global_transform
	dont_check = false
	#left_hand.linear_velocity = left_spawn_point.global_transform.basis.z * -1 * handspeed

func spawn_righthand():
	Global.right_arm_out = true
	Global.right_arm_out = true
	var right_hand = right_hand_scene.instantiate()
	dont_check = true
	add_sibling(right_hand)
	right_hand.transform = right_spawn_point.global_transform
	dont_check = false
	#right_hand.linear_velocity = right_spawn_point.global_transform.basis.z * -1 * handspeed

func _rotate_camera(delta: float, sens_mod: float = 1.0):
	var input := Input.get_vector("ui_left","ui_right","ui_down","ui_up")
	look_dir += input
	rotation.y -= look_dir.x * camera_sens * delta
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod * delta, -1.5,1.5)
	look_dir = Vector2.ZERO
	
