extends CanvasLayer
const UI = preload("res://scripts/ui_theme.gd")
var world: Node
var state: Node
var objective_label: Label
var activity_label: Label
var action_button: Button
var toast: Label
var toast_panel: PanelContainer
var toast_icon: Label
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
	toast_panel = UI.box(UI.DARK, 6)
	toast_panel.position = Vector2(12, 75)
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_panel)
	var toast_row := HBoxContainer.new()
	toast_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_row.add_theme_constant_override("separation", 6)
	toast_panel.add_child(toast_row)
	toast_icon = UI.label("◆", 11, UI.GOLD)
	toast_icon.custom_minimum_size.x = 12
	toast_icon.autowrap_mode = TextServer.AUTOWRAP_OFF
	toast_row.add_child(toast_icon)
	toast = UI.label("", 10, UI.PAPER)
	toast.custom_minimum_size.x = 156
	toast_row.add_child(toast)
	toast_panel.hide()
	state.save_finished.connect(on_saved)
	state.save_failed.connect(on_save_failed)
	state.notice.connect(queue_notice)
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
	toast_icon.text = "+" if text.begins_with("Получено") else "◆"
	toast_icon.add_theme_color_override("font_color", Color(UI.GOLD))
	toast_panel.size = Vector2.ZERO
	toast_panel.modulate.a = 1.0
	toast_panel.visible = not world.dialogue.is_open and not world.character_panel.is_open and not world.busy

func on_saved(slot: int, reason: String) -> void:
	if reason in ["transition","purchase","equipment","book","quest","tracking","discovery"]: return
	if reason == "reward" and toast_remaining > 0:
		return # The reward notice already represents this saved event.
	elif reason == "work":
		queue_notice("Работа выполнена")
	else:
		show_toast("Сохранено · Слот %d" % slot, 2.5)

func on_save_failed(message: String) -> void:
	show_toast(message, 8.0)
	toast_icon.text = "!"
	toast_icon.add_theme_color_override("font_color", Color("e5a18c"))

func _process(delta: float) -> void:
	if not is_instance_valid(world.character_panel): return
	controls.visible = world.can_manual_save()
	var action: String = world.interaction_text()
	action_button.visible = not action.is_empty()
	action_button.text = "E · " + action
	if toast_remaining > 0:
		toast_panel.visible = controls.visible
		if controls.visible:
			toast_remaining -= delta
			toast_panel.modulate.a = minf(1.0, toast_remaining / 0.35)
	else:
		toast_panel.hide()
		if not notices.is_empty(): show_toast(notices.pop_front(),3.0)

var notices: Array[String] = []
func queue_notice(message: String) -> void:
	if toast_remaining<=0: show_toast(message,3.0)
	else: notices.append(message)
