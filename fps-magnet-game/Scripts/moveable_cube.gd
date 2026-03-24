class_name Cube
extends RigidBody3D

var touched = false
var hand = "left"

func _get_first_mesh_instance(node: Node) -> MeshInstance3D:
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
		var found := _get_first_mesh_instance(child)
		if found:
			return found
	return null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mesh_instance := _get_first_mesh_instance(self)
	if mesh_instance:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.82, 0.82, 0.82)
		material.metallic = 0.1
		material.roughness = 0.2
		mesh_instance.material_override = material

func set_touched(b:bool):
	touched = b

func set_hand(h:String):
	hand = h
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if touched:
		match hand:
			"left":
				global_transform.origin = global_transform.origin.move_toward(Global.player_point,Global.hand_speed)
			"right":
				global_transform.origin = global_transform.origin.move_toward(Global.right_farthest_point,Global.hand_speed)
