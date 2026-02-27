class_name Hand
extends RigidBody3D

@export var hand = "left"
@onready var hand_sensor: Area3D = $HandSensor
var just_touched = false


enum hand_states{
	extending,
	retracting,
	still,
}
var holdingon = false
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match hand:
		"left":
			
			if !Global.left_arm_out: self.queue_free()
			if Global.justclicked:
				Global.justclicked = false;
				linear_velocity = -linear_velocity
				
			var left_sensor_list = hand_sensor.get_overlapping_bodies()
			if hand_sensor.has_overlapping_bodies():
				for body in left_sensor_list:
					if body.is_in_group("Walls"):
						print("TOUCHING WALL")
						Global.left_extending = false
						linear_velocity = -linear_velocity
				
		"right":
			if !Global.right_arm_out: self.queue_free()
			if Global.justclicked:
				Global.justclicked = false;
				linear_velocity = -linear_velocity
			var right_sensor_list = hand_sensor.get_overlapping_bodies()
			if hand_sensor.has_overlapping_bodies():
				for body in right_sensor_list:
					if body.is_in_group("Walls") and Global.right_extending:
						print("TOUCHING WALL")
						Global.right_extending = false
						linear_velocity = -linear_velocity
