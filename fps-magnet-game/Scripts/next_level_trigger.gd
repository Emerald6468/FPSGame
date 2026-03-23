class_name NextLevelTrigger
extends Area3D

@export var one_shot := true
@export_file("*.tscn") var next_level_scene: String = ""

var _is_triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if one_shot and _is_triggered:
		return
	if not body is CharacterBody3D:
		return
	_is_triggered = true
	if next_level_scene.is_empty():
		return
	get_tree().paused = false
	call_deferred("_change_scene_deferred", next_level_scene)

func _change_scene_deferred(scene_path: String) -> void:
	if scene_path.is_empty():
		return
	ScreenFader.quick_scene_transition(scene_path)
