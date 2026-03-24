class_name ButtonTrigger
extends CSGBox3D

## Paths
@export var trigger_area_path: NodePath = ^"TriggerArea"
@export var unpressed_visual_path: NodePath = ^"ButtonUnpressed"
@export var pressed_visual_path: NodePath = ^"ButtonPressed"
@export var door_paths: Array[NodePath] = []
@export var activate_for_player := false #player no push buttons
@export var activate_for_cubes := true
## the model is really small so i scale it up in code
@export var press_offset: Vector3 = Vector3(0, -0.05, 0)
@export var visual_scale: Vector3 = Vector3(8, 8, 8)

var trigger_area: Area3D
var unpressed_visual: Node
var pressed_visual: Node
var door_nodes: Array[Node] = []
var base_position: Vector3
var is_pressed := false

const PUSHED_BUTTON_SCENE: PackedScene = preload("res://Assets/placeholder button (pushed).fbx")

func _ready() -> void:
	# save button for reload,death 
	base_position = position
	trigger_area = get_node_or_null(trigger_area_path) as Area3D
	unpressed_visual = get_node_or_null(unpressed_visual_path)
	pressed_visual = get_node_or_null(pressed_visual_path)
	if not pressed_visual and PUSHED_BUTTON_SCENE:
		pressed_visual = PUSHED_BUTTON_SCENE.instantiate()
		pressed_visual.name = "ButtonPressed"
		add_child(pressed_visual)
		if pressed_visual is Node3D and unpressed_visual is Node3D:
			(pressed_visual as Node3D).transform = (unpressed_visual as Node3D).transform
	if unpressed_visual:
		_apply_visual_scale(unpressed_visual)
	if pressed_visual:
		_apply_visual_scale(pressed_visual)
	for path in door_paths:
		var door := get_node_or_null(path)
		if door:
			door_nodes.append(door)
	add_to_group("LevelResettable")
	_hide_logic_mesh_if_needed()
	_apply_visual_state()
	_apply_doors()

func _physics_process(_delta: float) -> void:
	# added player detection just in case we change our minds
	if not trigger_area:
		return
	var should_press := false
	for body in trigger_area.get_overlapping_bodies():
		if activate_for_player and body is CharacterBody3D:
			should_press = true
			break
		if activate_for_cubes and body.is_in_group("Grabbable"):
			should_press = true
			break
	if should_press == is_pressed:
		return
	is_pressed = should_press
	_apply_visual_state()
	_apply_doors()

func reset_state() -> void:
	# LevelController calls this
	is_pressed = false
	_apply_visual_state()
	_apply_doors()

func _hide_logic_mesh_if_needed() -> void:
	# The CSG box handles collision
	if not unpressed_visual and not pressed_visual:
		return
	var transparent_material := StandardMaterial3D.new()
	transparent_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	transparent_material.albedo_color = Color(1, 1, 1, 0)
	material = transparent_material

func _apply_visual_state() -> void:
	# Swap visual variants so press state is always obvious.
	position = base_position + (press_offset if is_pressed else Vector3.ZERO)
	if unpressed_visual:
		unpressed_visual.visible = not is_pressed
	if pressed_visual:
		pressed_visual.visible = is_pressed

func _apply_doors() -> void:
	# reusable for each door
	for door in door_nodes:
		if door and door.has_method("set_open"):
			door.call("set_open", is_pressed)

func _apply_visual_scale(node: Node) -> void:
	# the modle will glitch without this idk why
	if node is Node3D:
		var node3d := node as Node3D
		node3d.scale = visual_scale
	for child in node.get_children():
		_apply_visual_scale(child)
