extends Control


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://TestScenes/JoshTestScene.tscn")

func _on_help_pressed() -> void:
	$CenterContainer.visible = false
	$HelpPopup.visible = true

func _on_credits_pressed() -> void:
	$CenterContainer.visible = false
	$CreditsPopup.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_help_close_pressed() -> void:
	$HelpPopup.visible = false
	$CenterContainer.visible = true

func _on_credits_close_pressed() -> void:
	$CreditsPopup.visible = false
	$CenterContainer.visible = true
