extends CanvasLayer
const UI = preload("res://scripts/ui_theme.gd")
var world: Node
var state: Node
var objective_label: Label
var wallet_label: Label
var activity_label: Label
var tracker_title: Label
var tracker: Button
var toolbar: HBoxContainer
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
	wallet_label = UI.label("", 13, UI.GOLD)
	wallet_label.position = Vector2(474, 14)
	wallet_label.size = Vector2(152, 28)
	wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wallet_label.add_theme_stylebox_override("normal", UI.panel_style(UI.DARK, "50625a", 7))
	controls.add_child(wallet_label)
	tracker = UI.button("")
	tracker.position = Vector2(12, 330)
	tracker.size = Vector2(290, 58)
	tracker.tooltip_text = "Открыть журнал заданий · J"
	tracker.pressed.connect(open_menu.bind("quests"))
	controls.add_child(tracker)
	tracker_title = UI.label("ТЕКУЩАЯ ЦЕЛЬ · J", 10, UI.GOLD)
	tracker_title.position = Vector2(9, 6)
	tracker_title.size.x = 272
	tracker.add_child(tracker_title)
	objective_label = UI.label("", 12)
	objective_label.position = Vector2(9, 22)
	objective_label.size = Vector2(272, 31)
	tracker.add_child(objective_label)
	toolbar = HBoxContainer.new()
	toolbar.position = Vector2(322, 356)
	toolbar.size = Vector2(306, 32)
	toolbar.add_theme_constant_override("separation", 5)
	controls.add_child(toolbar)
	for entry in [["Сумка · I", "inventory"], ["Задания · J", "quests"], ["Esc", "pause"]]:
		var b := UI.button(entry[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(open_menu.bind(entry[1]))
		toolbar.add_child(b)
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

func open_menu(context: String) -> void:
	if not world.can_manual_save(): return
	if context == "pause": world.pause_menu.open_pause()
	else: world.open_character_panel(context)

func refresh() -> void:
	objective_label.text = state.objective()
	wallet_label.text = "%d медяков" % state.personal_coins
	tracker_title.text = "ТЕКУЩАЯ ЦЕЛЬ · J" if not state.current_tracked_quest().is_empty() else "ГИЛЬДИЯ · J"
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
