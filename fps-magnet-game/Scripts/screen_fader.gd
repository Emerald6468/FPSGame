extends CanvasLayer

@export var death_fade_duration := 0.28
@export var transition_fade_duration := 0.18

const MAIN_UI_THEME := preload("res://Assets/Themes/main_theme.tres")

var _overlay_rect: ColorRect
var _overlay_material: ShaderMaterial
var _menu_center: CenterContainer
var _menu_panel: PanelContainer
var _retry_callback: Callable = Callable()
var _is_busy := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_overlay()
	_build_menu()
	_set_radius(1.6)
	_set_overlay_visible(false)

func quick_scene_transition(scene_path: String) -> void:
	if _is_busy:
		return
	if scene_path.is_empty():
		return
	_is_busy = true
	_retry_callback = Callable()
	_menu_panel.visible = false
	get_tree().paused = false
	_set_overlay_visible(true)
	await _animate_radius(1.6, 0.0, transition_fade_duration)
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await _animate_radius(0.0, 1.6, transition_fade_duration)
	_set_overlay_visible(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_is_busy = false

func show_death_menu(retry_callback: Callable) -> void:
	if _is_busy:
		return
	_is_busy = true
	_retry_callback = retry_callback
	_menu_panel.visible = false
	_set_overlay_visible(true)
	await _animate_radius(1.6, 0.0, death_fade_duration)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_menu_panel.visible = true

func _on_retry_pressed() -> void:
	if not _is_busy:
		return
	_menu_panel.visible = false
	get_tree().paused = false
	if _retry_callback.is_valid():
		_retry_callback.call()
	await get_tree().process_frame
	await _animate_radius(0.0, 1.6, death_fade_duration)
	_set_overlay_visible(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_is_busy = false

func _on_main_menu_pressed() -> void:
	if not _is_busy:
		return
	_menu_panel.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	await get_tree().process_frame
	await _animate_radius(0.0, 1.6, transition_fade_duration)
	_set_overlay_visible(false)
	_is_busy = false

func _animate_radius(from_value: float, to_value: float, duration: float) -> void:
	_set_radius(from_value)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(_set_radius, from_value, to_value, duration)
	await tween.finished

func _set_radius(radius: float) -> void:
	if _overlay_material:
		_overlay_material.set_shader_parameter("radius", radius)

func _set_overlay_visible(overlay_enabled: bool) -> void:
	if _overlay_rect:
		_overlay_rect.visible = overlay_enabled

func _build_overlay() -> void:
	_overlay_rect = ColorRect.new()
	_overlay_rect.name = "CircleFadeOverlay"
	_overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_rect.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay_rect.theme = MAIN_UI_THEME
	_overlay_rect.color = Color.BLACK

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float radius : hint_range(0.0, 2.0) = 1.6;
uniform float feather : hint_range(0.0, 0.2) = 0.03;
uniform vec2 center = vec2(0.5, 0.5);

void fragment() {
	float dist = distance(SCREEN_UV, center);
	float alpha = smoothstep(radius - feather, radius, dist);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
"""
	_overlay_material = ShaderMaterial.new()
	_overlay_material.shader = shader
	_overlay_rect.material = _overlay_material
	add_child(_overlay_rect)

func _build_menu() -> void:
	_menu_center = CenterContainer.new()
	_menu_center.name = "DeathMenuCenter"
	_menu_center.process_mode = Node.PROCESS_MODE_ALWAYS
	_menu_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_rect.add_child(_menu_center)

	_menu_panel = PanelContainer.new()
	_menu_panel.name = "DeathMenu"
	_menu_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_menu_panel.custom_minimum_size = Vector2(340, 220)
	_menu_panel.theme_type_variation = &"MenuPopupCard"
	_menu_panel.visible = false
	_menu_center.add_child(_menu_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_menu_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "You Died"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_type_variation = &"PopupTitleLabel"
	layout.add_child(title)

	var retry_button := Button.new()
	retry_button.text = "Retry"
	retry_button.custom_minimum_size = Vector2(220, 46)
	retry_button.theme_type_variation = &"PrimaryButton"
	retry_button.pressed.connect(_on_retry_pressed)
	layout.add_child(retry_button)

	var menu_button := Button.new()
	menu_button.text = "Main Menu"
	menu_button.custom_minimum_size = Vector2(220, 46)
	menu_button.pressed.connect(_on_main_menu_pressed)
	layout.add_child(menu_button)
