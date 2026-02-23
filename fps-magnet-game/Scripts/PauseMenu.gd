extends Control


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # importnat I guess, so it can detect pause input even when paused

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	visible = paused
	
	if paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



func _on_resume_pressed() -> void:
	_toggle_pause()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
