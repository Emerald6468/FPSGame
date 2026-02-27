extends CharacterBody3D

@export_category("Controls")
@export var SPEED = 10.0
@export var JUMP_VELOCITY = 4.5

var look_dir:Vector2
@onready var camera: Camera3D = $Camera3D
@export var camera_sens = 50

#arm variables
@export var handspeed = 10
@onready var despawn_zone: Area3D = $Despawn_Zone

@onready var left_spawn_point: Node3D = %Left_Spawn_Point
@onready var right_spawn_point: Node3D = %Right_Spawn_Point

@onready var left_hand_scene = preload("res://Prefabs/left_hand.tscn")
@onready var right_hand_scene = preload("res://Prefabs/right_hand.tscn")
var left_arm_out = Global.left_arm_out
var right_arm_out = Global.right_arm_out
var left_extending = Global.left_extending
var right_extending = Global.right_extending


func _physics_process(delta: float) -> void:
	if Global.justclicked:
		Global.justclicked = false;
	left_arm_out = Global.left_arm_out
	right_arm_out = Global.right_arm_out
	left_extending = Global.left_extending
	right_extending = Global.right_extending
	# Add the gravity.
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if !left_arm_out and !right_arm_out:
		var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			
	else:
		Global.player_point = self.global_position
		velocity.x = 0
		velocity.z = 0
	
	
	#checks to see if it needs to delete hands
	var body_list = despawn_zone.get_overlapping_bodies()
	#print(body_list)
	
	if despawn_zone.has_overlapping_bodies():
		for body in body_list:
			if body is Hand:
				var hand : Hand = body
				if hand.hand == "left" and !left_extending:
					left_arm_out = false
				if hand.hand == "right" and !right_extending:
					right_arm_out = false
		for i in range(len(despawn_zone.get_overlapping_bodies())):
			var checked_body = str(body_list[i])
			if checked_body.contains("LeftHand") and !left_extending:
				left_arm_out = false
			if checked_body.contains("RightHand") and !right_extending:
				right_arm_out = false

	_rotate_camera(delta)
	move_and_slide()
	Global.left_arm_out = left_arm_out
	Global.right_arm_out = right_arm_out
	Global.left_extending = left_extending
	Global.right_extending = right_extending
	
func _input(event: InputEvent):
	if event is InputEventMouseMotion: look_dir = event.relative * 0.01
	#hand stuff
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("left_click"):
			Global.leftclicked = true
			left_extending = !left_extending
			Global.justclicked = true;
			if !left_arm_out: spawn_lefthand()
		if Input.is_action_just_pressed("right_click"):
			Global.leftclicked = false
			right_extending = !right_extending
			Global.justclicked = true;
			if !right_arm_out: spawn_righthand()
		Global.left_extending = left_extending
		Global.right_extending = right_extending
	

func spawn_lefthand():
	#print("test")
	Global.justclicked = false;
	left_arm_out = true
	Global.left_arm_out = true
	var left_hand = left_hand_scene.instantiate()
	add_sibling(left_hand)
	left_hand.transform = left_spawn_point.global_transform
	#left_hand.linear_velocity = left_spawn_point.global_transform.basis.z * -1 * handspeed

func spawn_righthand():
	Global.justclicked = false;
	right_arm_out = true
	Global.right_arm_out = true
	var right_hand = right_hand_scene.instantiate()
	add_sibling(right_hand)
	right_hand.transform = right_spawn_point.global_transform
	#right_hand.linear_velocity = right_spawn_point.global_transform.basis.z * -1 * handspeed

func _rotate_camera(delta: float, sens_mod: float = 1.0):
	var input := Input.get_vector("ui_left","ui_right","ui_down","ui_up")
	look_dir += input
	rotation.y -= look_dir.x * camera_sens * delta
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod * delta, -1.5,1.5)
	look_dir = Vector2.ZERO
	
