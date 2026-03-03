extends Control

const HAND_EMOJI := "✋"
const HOVER_FADE_DURATION := 0.2
const PULL_ANIMATION_DURATION := 0.4
const PULL_DISTANCE := 200.0


@onready var margin_container: MarginContainer = $MarginContainer
@onready var vbox_container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var popup_backdrop: ColorRect = $PopupBackdrop
@onready var help_popup: Control = $HelpPopup
@onready var credits_popup: Control = $CreditsPopup
@onready var help_close_btn: Button = $HelpPopup/VBox/HelpCloseBtn
@onready var credits_close_btn: Button = $CreditsPopup/VBox/CreditsCloseBtn

var _row_data: Dictionary = {}
var _current_focused_row: String = ""
var _is_animating: bool = false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	_setup_menu_rows()
	_setup_popups()
	
	# Wait for layout to calculate before grabbing focus
	await get_tree().process_frame
	_focus_first_button()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
		
	if help_popup.visible:
		_close_popup(help_popup)
		get_viewport().set_input_as_handled()
	elif credits_popup.visible:
		_close_popup(credits_popup)
		get_viewport().set_input_as_handled()


# Setup 

func _setup_menu_rows() -> void:
	for row in vbox_container.get_children():
		if not row is HBoxContainer:
			continue
			
		var row_name: String = row.name.trim_suffix("Row").to_lower()
		var arm: Control = row.get_node_or_null("ArmRect")
		var hand: Label = row.get_node_or_null("HandLabel")
		var button: Button = row.get_node_or_null(row.name.replace("Row", "Button"))
		
		if arm and hand and button:
			hand.text = HAND_EMOJI
			arm.modulate.a = 0.0
			hand.modulate.a = 0.0
			
			_row_data[row_name] = {"row": row, "arm": arm, "hand": hand, "button": button}

			button.focus_entered.connect(_on_row_focused.bind(row_name))
			button.mouse_entered.connect(button.grab_focus) # Mouse hovering forces keyboard focus
			button.pressed.connect(_on_row_pressed.bind(row_name))


func _setup_popups() -> void:
	help_close_btn.pressed.connect(_close_popup.bind(help_popup))
	credits_close_btn.pressed.connect(_close_popup.bind(credits_popup))


func _focus_first_button() -> void:
	if _row_data.has("start"):
		_row_data["start"].button.grab_focus()


# Input Logic

func _on_row_focused(row_name: String) -> void:
	if _is_animating:
		return
		
	# Fade out
	if _current_focused_row != "" and _current_focused_row != row_name:
		var prev = _row_data[_current_focused_row]
		_fade_arm_and_hand(prev.arm, prev.hand, 0.0)
		
	# Fade in
	_current_focused_row = row_name
	var current = _row_data[row_name]
	_fade_arm_and_hand(current.arm, current.hand, 1.0)


func _on_row_pressed(row_name: String) -> void:
	if _is_animating:
		return
		
	match row_name:
		"start":
			await _play_pull_animation("start")
			get_tree().change_scene_to_file("res://TestScenes/JoshTestScene.tscn")
		"options":
			await _play_pull_animation("options")
			# add options scene when I get around it it 
		"help":
			await _play_pull_animation("help")
			_open_popup(help_popup, help_close_btn)
		"credits":
			await _play_pull_animation("credits")
			_open_popup(credits_popup, credits_close_btn)


# Animation 

func _fade_arm_and_hand(arm: Control, hand: Control, target_alpha: float) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).set_parallel(true)
	tween.tween_property(arm, "modulate:a", target_alpha, HOVER_FADE_DURATION)
	tween.tween_property(hand, "modulate:a", target_alpha, HOVER_FADE_DURATION)


func _play_pull_animation(row_name: String) -> void:
	if not _row_data.has(row_name): return
	
	_is_animating = true # Lock interactions 
	
	var d: Dictionary = _row_data[row_name]
	var row: HBoxContainer = d.row
	var button: Control = d.button
	var arm: Control = d.arm
	var hand: Control = d.hand

	_fade_arm_and_hand(arm, hand, 1.0)

	#  save 4 later
	var btn_size := button.size
	var hand_size := hand.size
	var arm_size := arm.size
	var btn_global := button.global_position
	var hand_global := hand.global_position
	var arm_global := arm.global_position

	var placeholders: Array[Control] = [
		_make_placeholder(btn_size), 
		_make_placeholder(hand_size), 
		_make_placeholder(arm_size)
	]
	
	for i in placeholders.size():
		row.add_child(placeholders[i])
		row.move_child(placeholders[i], i)

	# Reparent 
	for node in [button, hand, arm]:
		row.remove_child(node)
		add_child(node)
		
	button.global_position = btn_global
	hand.global_position = hand_global
	arm.global_position = arm_global
	
	# Sizes must be manually reapplied
	button.size = btn_size
	hand.size = hand_size
	arm.size = arm_size

	var move_right := Vector2(PULL_DISTANCE, 0)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	
	tween.tween_property(button, "position", button.position + move_right, PULL_ANIMATION_DURATION)
	tween.tween_property(hand, "position", hand.position + move_right, PULL_ANIMATION_DURATION)
	tween.tween_property(arm, "position", arm.position + move_right, PULL_ANIMATION_DURATION)
	tween.tween_property(arm, "size:x", maxf(0.0, arm.size.x - PULL_DISTANCE), PULL_ANIMATION_DURATION)
	
	await tween.finished

	_restore_row(row, button, hand, arm, placeholders)
	_is_animating = false


func _make_placeholder(min_size: Vector2) -> Control:
	var c := Control.new()
	c.custom_minimum_size = min_size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _restore_row(row: HBoxContainer, button: Control, hand: Control, arm: Control, placeholders: Array[Control]) -> void:
	for node in [button, hand, arm]:
		remove_child(node)
		
	for ph in placeholders:
		row.remove_child(ph)
		ph.queue_free()
		
	row.add_child(button)
	row.add_child(hand)
	row.add_child(arm)
	
	row.move_child(button, 0)
	row.move_child(hand, 1)
	row.move_child(arm, 2)


# Popups

func _open_popup(popup: Control, focus_target: Control) -> void:
	margin_container.hide()
	popup_backdrop.show()
	popup.show()
	focus_target.grab_focus()


func _close_popup(popup: Control) -> void:
	popup.hide()
	popup_backdrop.hide()
	margin_container.show()
	_focus_first_button()
