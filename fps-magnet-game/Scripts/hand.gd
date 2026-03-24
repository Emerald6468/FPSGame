class_name Hand
extends RigidBody3D

@export var hand = "left"
@export var Hand_Speed = .175
@onready var hand_sensor: Area3D = $HandSensor
var dont_check_left = false
var dont_check_right = false
var just_letgo = false
var left_letgo = false
var right_letgo = false
var just_spawned = true

enum hand_states{
	extending,
	retracting,
	still,
}
var left_hand_state
var right_hand_state

	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	just_spawned = true
	Global.hand_speed = Hand_Speed
	match hand:
		"left": left_hand_state = hand_states.extending
		"right": right_hand_state = hand_states.extending

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match hand:
		"left":
			if !Global.left_arm_out: 
				self.queue_free()
			if Global.justclicked and Global.leftclicked and !just_spawned:
				#let go
				if Global.left_holding_on or Global.player_pulled:
					let_go(hand)
				else:	
					match left_hand_state:
						hand_states.extending:
							left_hand_state = hand_states.retracting
						hand_states.retracting:
							left_hand_state = hand_states.extending
						hand_states.still:
							left_hand_state = hand_states.retracting
			if just_spawned: just_spawned = false
			var left_sensor_list = hand_sensor.get_overlapping_bodies()
			if hand_sensor.has_overlapping_bodies():
				for body in left_sensor_list:
					if body.is_in_group("Walls"):
						if body is MagneticWall and !dont_check_left:
							#pulls player towards it
							Global.player_pulled = true
							left_hand_state = hand_states.still
						else:
							Global.left_extending = false
							left_hand_state = hand_states.retracting
					elif body.is_in_group("Grabbable") and !Global.left_holding_on:
						#grabbing on
						if left_hand_state == hand_states.extending and !dont_check_left:
							body.set_touched(true)
							body.set_hand(hand)
							Global.left_holding_on = true
							Global.left_extending = false
							left_hand_state = hand_states.retracting
						#letting go
						elif left_letgo:
							body.set_touched(false)
							left_letgo = false
			move_hand(left_hand_state,hand)
		
		"right":
			if !Global.right_arm_out: 
				self.queue_free()
			if Global.justclicked and !Global.leftclicked and !just_spawned:
				#let go
				if Global.right_holding_on:
					let_go(hand)
				match right_hand_state:
					hand_states.extending:
						right_hand_state = hand_states.retracting
					hand_states.retracting:
						right_hand_state = hand_states.extending
					hand_states.still:
						right_hand_state = hand_states.retracting
			if just_spawned: just_spawned = false
			var right_sensor_list = hand_sensor.get_overlapping_bodies()
			if hand_sensor.has_overlapping_bodies():
				for body in right_sensor_list:
					if body.is_in_group("Walls"):
						if body is MagneticWall and !dont_check_left:
							#pulls player towards it
							Global.player_pushed = true
							right_hand_state = hand_states.still
						else:
							Global.right_extending = false
							right_hand_state = hand_states.retracting
					elif body.is_in_group("Grabbable") and !Global.right_holding_on:
						#grabbing on
						if right_hand_state == hand_states.extending and !dont_check_right:
							body.set_touched(true)
							body.set_hand(hand)
							Global.right_holding_on = true
							Global.right_extending = true
							right_hand_state = hand_states.extending
						#letting go
						elif right_letgo:
							body.set_touched(false)
							right_letgo = false
			move_hand(right_hand_state,hand)
	
	
	if Global.justclicked:
		Global.justclicked = false;
	
	
#let go
func let_go(hand):
	match hand:
		"left":
			Global.left_holding_on = false
			Global.player_pulled = false
			left_letgo = true
			if !dont_check_left:
				dont_check_left = true
				await get_tree().create_timer(.1).timeout
				dont_check_left = false
		"right":
			Global.right_holding_on = false
			Global.player_pushed = false
			right_letgo = true
			if !dont_check_right:
				dont_check_right = true
				await get_tree().create_timer(.1).timeout
				dont_check_right = false
#movement
func move_hand(hand_state,hand):
	if !Global.justclicked:
		match hand_state:
			hand_states.extending:
				#print("extending")
				match hand:
					"left": 
						if global_position.distance_to(Global.left_raycast_point) < .2 and !Global.left_collision: 
							left_hand_state = hand_states.retracting
						else: global_transform.origin = global_transform.origin.move_toward(Global.left_raycast_point,Hand_Speed)
					"right": 
						if !Global.right_holding_on:
							if global_position.distance_to(Global.right_raycast_point) < .2 and !Global.right_collision: 
								right_hand_state = hand_states.retracting
							else:global_transform.origin = global_transform.origin.move_toward(Global.right_raycast_point,Hand_Speed)
						else:
							if global_position.distance_to(Global.right_farthest_point) < .2: 
								right_hand_state = hand_states.retracting
								let_go(hand)
							else:global_transform.origin = global_transform.origin.move_toward(Global.right_farthest_point,Hand_Speed)
			hand_states.retracting:
				#print("retracting")
				global_transform.origin = global_transform.origin.move_toward(Global.player_point,Hand_Speed)
			hand_states.still:
				pass
