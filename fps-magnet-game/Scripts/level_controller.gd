class_name LevelController
extends Node3D

@export var player_path: NodePath = ^"Player"
@export var respawn_y_limit: float = -8.0

var player: CharacterBody3D
var player_start_transform: Transform3D
## Stores each cube's spawn
var cube_start_transforms: Dictionary = {}
var is_respawning := false

func _ready() -> void:
	player = get_node_or_null(player_path) as CharacterBody3D
	if player:
		player_start_transform = player.global_transform
	_cache_cube_starts()
	Global.reset_state()

func _physics_process(_delta: float) -> void:
	# watch for cubes or player falling below the playable space.
	if is_respawning:
		return
	if player and player.global_position.y < respawn_y_limit:
		respawn_to_level_start()
		return
	for cube in cube_start_transforms.keys():
		if not is_instance_valid(cube):
			continue
		if cube.global_position.y < respawn_y_limit:
			respawn_cube(cube)

func respawn_to_level_start() -> void:
	# Full respawn resets everything
	if is_respawning:
		return
	is_respawning = true
	_clear_spawned_hands()
	Global.reset_state()
	_reset_player()
	_reset_all_cubes()
	_reset_level_objects()
	await get_tree().physics_frame
	is_respawning = false

func respawn_cube(cube: RigidBody3D) -> void:
	# Cube-only respawns
	if is_respawning:
		return
	var start_transform: Transform3D = cube_start_transforms.get(cube, Transform3D.IDENTITY)
	if start_transform == Transform3D.IDENTITY and not cube_start_transforms.has(cube):
		return
	_restore_cube(cube, start_transform)

func _cache_cube_starts() -> void:
	# Only cubes that belong to this level
	cube_start_transforms.clear()
	for node in get_tree().get_nodes_in_group("Grabbable"):
		if node is RigidBody3D and is_ancestor_of(node):
			cube_start_transforms[node] = node.global_transform

func _reset_player() -> void:
	if not player:
		return
	player.velocity = Vector3.ZERO
	player.global_transform = player_start_transform

func _reset_all_cubes() -> void:
	for cube in cube_start_transforms.keys():
		if not is_instance_valid(cube):
			continue
		_restore_cube(cube, cube_start_transforms[cube])

func _restore_cube(cube: RigidBody3D, start_transform: Transform3D) -> void:
	# Reset the cube
	if cube.has_method("set_touched"):
		cube.call("set_touched", false)
	cube.linear_velocity = Vector3.ZERO
	cube.angular_velocity = Vector3.ZERO
	cube.global_transform = start_transform
	cube.sleeping = true

func _reset_level_objects() -> void:
	# Buttons and doors
	for node in get_tree().get_nodes_in_group("LevelResettable"):
		if is_ancestor_of(node) and node.has_method("reset_state"):
			node.call("reset_state")

func _clear_spawned_hands() -> void:
	_clear_hands_recursive(self)

func _clear_hands_recursive(node: Node) -> void:
	# hands are kinda weird so gotta search and kill all of them
	for child in node.get_children():
		if child is Hand:
			child.queue_free()
			continue
		_clear_hands_recursive(child)
