extends CanvasLayer
signal closed
const UI = preload("res://scripts/ui_theme.gd")
var is_open := false
var panel: PanelContainer
var title: Label
var body: Label
var action: Button
var close_button: Button
var callback: Callable

func _ready() -> void:
	layer = 21
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = UI.box(UI.DARK, 14)
	panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	title = UI.label("", 19, UI.GOLD)
	column.add_child(title)
	body = UI.label("", 13)
	body.custom_minimum_size.y = 88
	column.add_child(body)
	action = UI.button("")
	action.pressed.connect(func():
		if is_open and callback.is_valid(): callback.call())
	column.add_child(action)
	close_button = UI.button("Закрыть")
	close_button.pressed.connect(close)
	column.add_child(close_button)
	hide()

func open(heading: String, text: String, action_text: String = "", on_action: Callable = Callable()) -> void:
	is_open = true
	title.text = heading
	body.text = text
	callback = on_action
	action.text = action_text
	action.visible = not action_text.is_empty()
	show()
	panel.reset_size.call_deferred()
	UI.trap_focus(panel)
	close_button.grab_focus()

func close() -> void:
	if not is_open: return
	is_open = false
	callback = Callable()
	hide()
	closed.emit()
