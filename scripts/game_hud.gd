extends CanvasLayer
const UI = preload("res://scripts/ui_theme.gd")
var world: Node
var state: Node
var objective_label: Label
var activity_label: Label
var action_button: Button
var toast: Label
var toast_remaining := 0.0
var previous_coins := 0
var controls: Control

func _ready() -> void:
	layer = 5
	world = get_parent()
	state = get_node("/root/GameState")
	previous_coins = state.personal_coins
	controls = Control.new()
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(controls)
	var location := UI.box(UI.DARK, 8)
	location.position = Vector2(12, 12)
	location.size = Vector2(180, 41)
	controls.add_child(location)
	var title := UI.label(world.location_title.replace(" · ", "\n"), 12)
	location.add_child(title)
	objective_label = UI.label("", 12)
	objective_label.position = Vector2(350, 14)
	objective_label.size = Vector2(278, 40)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective_label.add_theme_color_override("font_shadow_color", Color("182525"))
	objective_label.add_theme_constant_override("shadow_offset_x", 1)
	objective_label.add_theme_constant_override("shadow_offset_y", 1)
	controls.add_child(objective_label)
	action_button = UI.button("", true)
	action_button.position = Vector2(438, 320)
	action_button.size = Vector2(190, 28)
	action_button.pressed.connect(world.interact)
	controls.add_child(action_button)
	activity_label = UI.label("", 12)
	activity_label.hide()
	controls.add_child(activity_label)
	toast = UI.label("", 12, UI.GOLD)
	toast.position = Vector2(198, 63)
	toast.size = Vector2(244, 40)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_stylebox_override("normal", UI.panel_style(UI.DARK, "50625a", 8))
	toast.hide()
	add_child(toast)
	state.save_finished.connect(on_saved)
	state.save_failed.connect(on_save_failed)
	refresh()

func refresh() -> void:
	var has_objective: bool = not state.current_tracked_quest().is_empty()
	objective_label.text = state.objective() if has_objective else ""
	objective_label.visible = has_objective
	if state.personal_coins > previous_coins:
		show_toast("Получено %d медяков" % (state.personal_coins - previous_coins))
	previous_coins = state.personal_coins

func show_toast(text: String, duration: float = 3.0) -> void:
	toast.text = text
	toast_remaining = duration
	toast.show()

func on_saved(slot: int, reason: String) -> void:
	if reason == "reward" and toast_remaining > 0:
		toast.text += "\nПрогресс сохранён · Слот %d" % slot
	elif reason == "work":
		show_toast("Работа выполнена\nСохранено · Слот %d" % slot)
	else:
		show_toast("Сохранено · Слот %d" % slot, 2.5)

func on_save_failed(message: String) -> void:
	show_toast(message, 8.0)

func _process(delta: float) -> void:
	if not is_instance_valid(world.character_panel): return
	controls.visible = not world.dialogue.is_open and not world.character_panel.is_open and not world.busy
	var action: String = world.interaction_text()
	action_button.visible = not action.is_empty()
	action_button.text = "E · " + action
	if toast_remaining > 0:
		toast.visible = controls.visible
		if controls.visible: toast_remaining -= delta
	else:
		toast.hide()
