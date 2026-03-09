extends Node

var left_arm_out = false
var right_arm_out = false
var left_extending = false
var right_extending = false
var justclicked = false
var leftclicked = false

var player_point: Vector3

var left_raycast_point: Vector3
var left_farthest_point: Vector3
var left_collision = false

var right_raycast_point: Vector3
var right_farthest_point: Vector3
var right_collision = false

var hand_speed = 0.0
var left_holding_on = false
var right_holding_on = false

func reset_state() -> void:
	left_arm_out = false
	right_arm_out = false
	left_extending = false
	right_extending = false
	justclicked = false
	leftclicked = false
	player_point = Vector3.ZERO
	left_raycast_point = Vector3.ZERO
	left_farthest_point = Vector3.ZERO
	left_collision = false
	right_raycast_point = Vector3.ZERO
	right_farthest_point = Vector3.ZERO
	right_collision = false
	hand_speed = 0.0
	left_holding_on = false
	right_holding_on = false
