extends Control

const HOVER_FADE_DURATION := 0.2
const PULL_ANIMATION_DURATION := 0.4
const PULL_DISTANCE := 200.0
const BOB_AMPLITUDE := 0.18
const BOB_SPEED := 3.0
const HAND_GAP := 16.0
const HAND_SIZE := 120.0


@onready var margin_container: MarginContainer = $MarginContainer
@onready var vbox_container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var popup_backdrop: ColorRect = $PopupBackdrop
@onready var help_popup: Control = $HelpPopup
@onready var credits_popup: Control = $CreditsPopup
@onready var help_close_btn: Button = $HelpPopup/VBox/HelpCloseBtn
@onready var credits_close_btn: Button = $CreditsPopup/VBox/CreditsCloseBtn
@onready var hand_view: SubViewportContainer = $HandView

var _row_data: Dictionary = {}
var _current_focused_row: String = ""
var _is_animating: bool = false
var _hand_mesh: MeshInstance3D = null


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
	hand_view.modulate.a = 0.0
	var vp := hand_view.get_node_or_null("HandViewport") as SubViewport
	if vp:
		_hand_mesh = vp.get_node_or_null("HandMesh") as MeshInstance3D
	
	for row in vbox_container.get_children():
		if not row is HBoxContainer:
			continue
			
		var row_name: String = row.name.trim_suffix("Row").to_lower()
		var button: Button = row.get_node_or_null(row.name.replace("Row", "Button"))
		
		if button:
			_row_data[row_name] = {"row": row, "button": button}

			button.focus_entered.connect(_on_row_focused.bind(row_name))
			button.mouse_entered.connect(button.grab_focus)
			button.pressed.connect(_on_row_pressed.bind(row_name))


func _setup_popups() -> void:
	help_close_btn.pressed.connect(_close_popup.bind(help_popup))
	credits_close_btn.pressed.connect(_close_popup.bind(credits_popup))


func _focus_first_button() -> void:
	if _row_data.has("start"):
		_row_data["start"].button.grab_focus()


# Input Logic

func _process(_delta: float) -> void:
	if _current_focused_row == "" or _is_animating or not _row_data.has(_current_focused_row):
		return
	if not margin_container.visible:
		return
	
	var button: Control = _row_data[_current_focused_row].button
	var t := Time.get_ticks_msec() * 0.001
	var bob := sin(t * BOB_SPEED) * BOB_AMPLITUDE * 40.0 # convert 3D units to pixels
	
	hand_view.size = Vector2(HAND_SIZE, HAND_SIZE)
	hand_view.position = Vector2(
		button.global_position.x + button.size.x + HAND_GAP,
		button.global_position.y + (button.size.y - HAND_SIZE) * 0.5 + bob
	)


func _on_row_focused(row_name: String) -> void:
	if _is_animating:
		return
	
	_current_focused_row = row_name
	_fade_hand(1.0)


func _on_row_pressed(row_name: String) -> void:
	if _is_animating:
		return
		
	match row_name:
		"start":
			await _play_pull_animation("start")
			get_tree().change_scene_to_file("res://Scenes/Level_1.tscn")
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

func _fade_hand(target_alpha: float) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(hand_view, "modulate:a", target_alpha, HOVER_FADE_DURATION)


func _play_pull_animation(row_name: String) -> void:
	if not _row_data.has(row_name): return
	
	_is_animating = true
	
	var d: Dictionary = _row_data[row_name]
	var row: HBoxContainer = d.row
	var button: Control = d.button

	hand_view.modulate.a = 1.0

	var btn_size := button.size
	var btn_global := button.global_position

	var placeholder := _make_placeholder(btn_size)
	row.add_child(placeholder)
	row.move_child(placeholder, 0)

	row.remove_child(button)
	add_child(button)
	button.global_position = btn_global
	button.size = btn_size

	var move_right := Vector2(PULL_DISTANCE, 0)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	tween.tween_property(button, "position", button.position + move_right, PULL_ANIMATION_DURATION)
	tween.tween_property(hand_view, "position", hand_view.position + move_right, PULL_ANIMATION_DURATION)

	await tween.finished

	remove_child(button)
	row.remove_child(placeholder)
	placeholder.queue_free()
	row.add_child(button)
	row.move_child(button, 0)
	_is_animating = false


func _make_placeholder(min_size: Vector2) -> Control:
	var c := Control.new()
	c.custom_minimum_size = min_size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


# Popups

func _open_popup(popup: Control, focus_target: Control) -> void:
	hand_view.hide()
	margin_container.hide()
	popup_backdrop.show()
	popup.show()
	focus_target.grab_focus()


func _close_popup(popup: Control) -> void:
	popup.hide()
	popup_backdrop.hide()
	margin_container.show()
	hand_view.show()
	_focus_first_button()
