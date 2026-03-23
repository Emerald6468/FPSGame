extends Control

const HOVER_FADE_DURATION := 0.2
const PULL_ANIMATION_DURATION := 0.4
const PULL_DISTANCE := 200.0
const BOB_AMPLITUDE := 0.18
const BOB_SPEED := 3.0
const HAND_GAP := 12.0
const HAND_SIZE := 120.0
const INTRO_ANIMATION_DURATION := 0.24
const FOCUS_SCALE := Vector2(1.01, 1.01)
const REST_SCALE := Vector2.ONE


@onready var margin_container: MarginContainer = $MarginContainer
@onready var menu_vbox: VBoxContainer = $MarginContainer/CenterContainer/ContentColumn/MenuPanel/MenuVBox
@onready var popup_backdrop: ColorRect = $PopupBackdrop
@onready var help_popup: Control = $HelpPopup
@onready var credits_popup: Control = $CreditsPopup
@onready var help_close_btn: Button = $HelpPopup/VBox/HelpCloseBtn
@onready var credits_close_btn: Button = $CreditsPopup/VBox/CreditsCloseBtn
@onready var main_camera: Camera3D = $SceneView/SceneViewport/MainCamera
@onready var fill_light: OmniLight3D = $SceneView/SceneViewport/FillLight
@onready var accent_light: OmniLight3D = $SceneView/SceneViewport/AccentLight
@onready var overhead_light: OmniLight3D = get_node_or_null("SceneView/SceneViewport/OverheadLight") as OmniLight3D
@onready var cyan_rim_light: OmniLight3D = get_node_or_null("SceneView/SceneViewport/CyanRimLight") as OmniLight3D
@onready var gold_bounce_light: OmniLight3D = get_node_or_null("SceneView/SceneViewport/GoldBounceLight") as OmniLight3D
@onready var test_chamber: Node3D = $SceneView/SceneViewport/TestChamber
@onready var pedestal_left_hand: Node3D = get_node_or_null("SceneView/SceneViewport/TestChamber/PedestalLeftHand") as Node3D
@onready var pedestal_right_hand: Node3D = get_node_or_null("SceneView/SceneViewport/TestChamber/PedestalRightHand") as Node3D
@onready var hand_view: SubViewportContainer = $HandView
@onready var title_panel: Control = $MarginContainer/CenterContainer/ContentColumn/TitlePanel
@onready var menu_panel: Control = $MarginContainer/CenterContainer/ContentColumn/MenuPanel

var _row_data: Dictionary = {}
var _current_focused_row: String = ""
var _is_animating: bool = false
var _hand_mesh: MeshInstance3D = null
var _camera_base_position := Vector3.ZERO
var _camera_base_rotation := Vector3.ZERO
var _base_light_energy: Dictionary = {}


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_cache_scene_defaults()
	
	_setup_menu_rows()
	_setup_popups()
	_prepare_intro_cards()
	
	# Wait for layout to calculate before grabbing focus
	await get_tree().process_frame
	_update_card_pivots()
	_focus_first_button()
	_play_intro_animation()


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

func _cache_scene_defaults() -> void:
	_camera_base_position = main_camera.position
	_camera_base_rotation = main_camera.rotation_degrees
	_cache_light_energy(fill_light)
	_cache_light_energy(accent_light)
	_cache_light_energy(overhead_light)
	_cache_light_energy(cyan_rim_light)
	_cache_light_energy(gold_bounce_light)


func _cache_light_energy(light: OmniLight3D) -> void:
	if light:
		_base_light_energy[light] = light.light_energy


func _setup_menu_rows() -> void:
	hand_view.modulate.a = 0.0
	var vp := hand_view.get_node_or_null("HandViewport") as SubViewport
	if vp:
		_hand_mesh = vp.get_node_or_null("HandMesh") as MeshInstance3D
	
	for row in menu_vbox.get_children():
		if not row is HBoxContainer:
			continue
			
		var row_name: String = row.name.trim_suffix("Row").to_lower()
		var button: Button = row.get_node_or_null(row.name.replace("Row", "Button"))
		var accent: CanvasItem = row.get_node_or_null(row.name.replace("Row", "Accent"))
		
		if button:
			_row_data[row_name] = {
				"row": row,
				"button": button,
				"accent": accent
			}

			button.focus_entered.connect(_on_row_focused.bind(row_name))
			button.mouse_entered.connect(button.grab_focus)
			button.pressed.connect(_on_row_pressed.bind(row_name))
			button.pivot_offset = button.size * 0.5
			button.scale = REST_SCALE
			if accent:
				accent.modulate.a = 0.45


func _setup_popups() -> void:
	help_close_btn.pressed.connect(_close_popup.bind(help_popup))
	credits_close_btn.pressed.connect(_close_popup.bind(credits_popup))


func _focus_first_button() -> void:
	if _row_data.has("start"):
		_row_data["start"].button.grab_focus()


# Input Logic

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	_animate_background_scene(t)
	if _hand_mesh:
		_hand_mesh.rotation_degrees = Vector3(sin(t * 1.2) * 1.5, cos(t * 1.5) * 4.0, sin(t * 1.8) * 2.0)
	
	if _current_focused_row == "" or _is_animating or not _row_data.has(_current_focused_row):
		return
	if not margin_container.visible:
		return
	
	var button: Control = _row_data[_current_focused_row].button
	var bob := sin(t * BOB_SPEED) * BOB_AMPLITUDE * 40.0 # convert 3D units to pixels
	_update_hand_position(button, bob)


func _on_row_focused(row_name: String) -> void:
	if _is_animating:
		return
	
	_current_focused_row = row_name
	_emphasize_row(row_name)
	_fade_hand(1.0)


func _on_row_pressed(row_name: String) -> void:
	if _is_animating:
		return
		
	match row_name:
		"start":
			await _play_pull_animation("start")
			await ScreenFader.quick_scene_transition("res://Scenes/Level_1.tscn")
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
	var button_index := button.get_index()

	var placeholder := _make_placeholder(btn_size)
	row.add_child(placeholder)
	row.move_child(placeholder, button_index)

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
	row.move_child(button, button_index)
	button.scale = REST_SCALE
	_is_animating = false


func _make_placeholder(min_size: Vector2) -> Control:
	var c := Control.new()
	c.custom_minimum_size = min_size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _update_hand_position(button: Control, bob: float) -> void:
	hand_view.size = Vector2(HAND_SIZE, HAND_SIZE)
	hand_view.position = Vector2(
		button.global_position.x + button.size.x + HAND_GAP,
		button.global_position.y + (button.size.y - HAND_SIZE) * 0.5 + bob
	)


# Popups

func _open_popup(popup: Control, focus_target: Control) -> void:
	hand_view.hide()
	margin_container.hide()
	popup_backdrop.modulate.a = 0.0
	popup_backdrop.show()
	popup.scale = Vector2(0.96, 0.96)
	popup.modulate.a = 0.0
	popup.show()
	popup.pivot_offset = popup.size * 0.5
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.tween_property(popup_backdrop, "modulate:a", 1.0, 0.18)
	tween.tween_property(popup, "modulate:a", 1.0, 0.22)
	tween.tween_property(popup, "scale", Vector2.ONE, 0.22)
	focus_target.grab_focus()


func _close_popup(popup: Control) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.tween_property(popup_backdrop, "modulate:a", 0.0, 0.16)
	tween.tween_property(popup, "modulate:a", 0.0, 0.16)
	tween.tween_property(popup, "scale", Vector2(0.96, 0.96), 0.16)
	await tween.finished
	popup.hide()
	popup_backdrop.hide()
	margin_container.show()
	hand_view.show()
	_focus_first_button()


func _prepare_intro_cards() -> void:
	for card in [title_panel, menu_panel]:
		card.modulate.a = 0.0
		card.scale = Vector2(0.992, 0.992)


func _update_card_pivots() -> void:
	for card in [title_panel, menu_panel]:
		card.pivot_offset = card.size * 0.5


func _play_intro_animation() -> void:
	var cards: Array[Control] = [title_panel, menu_panel]
	var delay := 0.0
	
	for card in cards:
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, INTRO_ANIMATION_DURATION)
		tween.tween_property(card, "scale", Vector2.ONE, INTRO_ANIMATION_DURATION)
		delay += 0.04


func _emphasize_row(row_name: String) -> void:
	for key in _row_data.keys():
		var data: Dictionary = _row_data[key]
		var button := data.button as Button
		var accent := data.accent as CanvasItem
		var target_scale := FOCUS_SCALE if key == row_name else REST_SCALE
		var target_alpha := 1.0 if key == row_name else 0.45
		
		button.pivot_offset = button.size * 0.5
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(button, "scale", target_scale, 0.16)
		
		if accent:
			var accent_tween := create_tween()
			accent_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			accent_tween.tween_property(accent, "modulate:a", target_alpha, 0.16)


func _animate_background_scene(t: float) -> void:
	if main_camera:
		main_camera.position = _camera_base_position + Vector3(
			sin(t * 0.23) * 0.14,
			cos(t * 0.31) * 0.08,
			sin(t * 0.19) * 0.2
		)
		main_camera.rotation_degrees = _camera_base_rotation + Vector3(
			cos(t * 0.27) * 0.45,
			sin(t * 0.24) * 0.9,
			sin(t * 0.2) * 0.18
		)
		main_camera.fov = 28.5 + sin(t * 0.27) * 0.18
	if test_chamber:
		test_chamber.rotation_degrees.y = sin(t * 0.18) * 1.2
	_pulse_light(fill_light, t, 1.15, 0.22)
	_pulse_light(accent_light, t, 1.7, 0.24, PI * 0.5)
	_pulse_light(overhead_light, t, 0.95, 0.18, 0.7)
	_pulse_light(cyan_rim_light, t, 1.35, 0.25, 0.8)
	_pulse_light(gold_bounce_light, t, 1.1, 0.18, 1.4, true)
	if pedestal_left_hand:
		pedestal_left_hand.position.y = 0.84 + sin(t * 0.8) * 0.03
	if pedestal_right_hand:
		pedestal_right_hand.position.y = 0.84 + cos(t * 0.75) * 0.03


func _pulse_light(light: OmniLight3D, t: float, speed: float, amount: float, phase: float = 0.0, use_cos: bool = false) -> void:
	if not light:
		return
	
	var wave := cos(t * speed + phase) if use_cos else sin(t * speed + phase)
	light.light_energy = _base_light_energy.get(light, light.light_energy) + wave * amount
