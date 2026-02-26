extends RigidBody3D

@export var hand = "left"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match hand:
		"left":
			if !Global.left_arm_out: self.queue_free()
			if !Global.left_extending and Global.justclicked:
				Global.justclicked = false;
				linear_velocity = -linear_velocity
				
		"right":
			if !Global.right_arm_out: self.queue_free()
			if !Global.right_extending and Global.justclicked:
				Global.justclicked = false;
				linear_velocity = -linear_velocity


func _on_despawn_zone_body_entered(body: Node3D) -> void:
	print("delete left")
	if hand == "left" and !Global.left_extending: 
		Global.left_arm_out = false
		self.queue_free()
		
