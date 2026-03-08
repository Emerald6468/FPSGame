class_name Hand
extends RigidBody3D

@export var hand = "left"
@export var Hand_Speed = .175
@onready var hand_sensor: Area3D = $HandSensor
var just_touched = false


enum hand_states{
	extending,
	retracting,
	still,
}
var left_hand_state
var right_hand_state

	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.hand_speed = Hand_Speed
	match hand:
		"left": left_hand_state = hand_states.extending
		"right": right_hand_state = hand_states.extending

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Global.left_extending: left_hand_state = hand_states.extending
	if Global.right_extending: right_hand_state = hand_states.extending
	match hand:
		"left":
			if !Global.left_arm_out: 
				self.queue_free()
			if Global.justclicked and Global.leftclicked:
				if Global.left_holding_on: 
					Global.left_holding_on = false
				match left_hand_state:
					hand_states.extending:
						left_hand_state = hand_states.retracting
					hand_states.retracting:
						left_hand_state = hand_states.extending
					hand_states.still:
						left_hand_state = hand_states.retracting
			var left_sensor_list = hand_sensor.get_overlapping_bodies()
			if hand_sensor.has_overlapping_bodies():
				for body in left_sensor_list:
					if body.is_in_group("Walls"):
						Global.left_extending = false
						left_hand_state = hand_states.retracting
					elif body.is_in_group("Grabbable") and !Global.left_holding_on:
						if left_hand_state == hand_states.extending:
							body.set_touched(true)
							Global.left_holding_on = true
							Global.left_extending = false
							left_hand_state = hand_states.retracting
						elif left_hand_state == hand_states.retracting:
							body.set_touched(false)
			move_hand(left_hand_state,hand)
		
		"right":
			if !Global.right_arm_out: 
				self.queue_free()
			if Global.justclicked and !Global.leftclicked:
				match right_hand_state:
					hand_states.extending:
						right_hand_state = hand_states.retracting
					hand_states.retracting:
						right_hand_state = hand_states.extending
					hand_states.still:
						right_hand_state = hand_states.retracting
			var right_sensor_list = hand_sensor.get_overlapping_bodies()
			if hand_sensor.has_overlapping_bodies():
				for body in right_sensor_list:
					if body.is_in_group("Walls"):
						Global.right_extending = false
						right_hand_state = hand_states.retracting
					elif body.is_in_group("Grabbable") and !Global.right_holding_on:
						body.set_touched(true)
						Global.right_holding_on = true
						Global.right_extending = false
						right_hand_state = hand_states.retracting
			move_hand(right_hand_state,hand)
	
	
	if Global.justclicked:
		Global.justclicked = false;
	
#movement
func move_hand(hand_state,hand):
	if !Global.justclicked:
		match hand_state:
			hand_states.extending:
				#print("extending")
				match hand:
					"left": 
						look_at(Global.left_raycast_point)
						if global_position.distance_to(Global.left_raycast_point) < .2: 
							left_hand_state = hand_states.retracting
						else: global_transform.origin = global_transform.origin.move_toward(Global.left_raycast_point,Hand_Speed)
					"right": 
						look_at(Global.right_raycast_point)
						if global_position.distance_to(Global.right_raycast_point) < .2: 
							right_hand_state = hand_states.retracting
						else:global_transform.origin = global_transform.origin.move_toward(Global.right_raycast_point,Hand_Speed)
			hand_states.retracting:
				#print("retracting")
				global_transform.origin = global_transform.origin.move_toward(Global.player_point,Hand_Speed)
			hand_states.still:
				pass
