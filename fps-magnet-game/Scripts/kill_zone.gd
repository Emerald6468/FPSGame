class_name KillZone
extends Area3D


enum TargetMode {
	PLAYER,
	CUBES,
	BOTH,
}

@export var target_mode := TargetMode.BOTH

var level_controller: LevelController

func _ready() -> void:
	# assume the active scene root is the LevelController for the current map.
	level_controller = get_tree().current_scene as LevelController
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not level_controller:
		return
	# Player deaths reset the level,  cube deaths only restore that cube.
	if body is CharacterBody3D and target_mode != TargetMode.CUBES:
		level_controller.handle_player_death()
		return
	if body is RigidBody3D and body.is_in_group("Grabbable") and target_mode != TargetMode.PLAYER:
		level_controller.respawn_cube(body)
