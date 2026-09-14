extends CanvasLayer
const UI = preload("res://scripts/ui_theme.gd")
var settings: Node
var is_open := false
var panel: PanelContainer
var options: VBoxContainer
var confirmation: VBoxContainer
var resolution_choice: OptionButton
var mode_choice: OptionButton
var note: Label
var countdown: Label
var seconds_left := 0.0
var was_paused := false
var previous_focus: WeakRef
var revert_button: Button
var apply_button: Button
var title: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 70
	settings = get_parent()
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.05, 0.05, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = UI.box(UI.DARK, 14)
	panel.custom_minimum_size = Vector2(460, 310)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	title = UI.label("ЭКРАН", 22, UI.GOLD)
	column.add_child(title)
	options = VBoxContainer.new()
	options.add_theme_constant_override("separation", 9)
	column.add_child(options)
	options.add_child(UI.label("Режим экрана", 12, UI.MUTED))
	mode_choice = choice()
	mode_choice.add_item("Оконный")
	mode_choice.add_item("На весь экран")
	mode_choice.item_selected.connect(func(_index): update_note())
	options.add_child(mode_choice)
	options.add_child(UI.label("Разрешение окна · 16:9", 12, UI.MUTED))
	resolution_choice = choice()
	for value in settings.RESOLUTIONS:
		resolution_choice.add_item("%d × %d" % [value.x, value.y])
	options.add_child(resolution_choice)
	note = UI.label("", 11, UI.MUTED)
	note.custom_minimum_size.y = 45
	options.add_child(note)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	options.add_child(buttons)
	apply_button = UI.button("Применить")
	apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_button.pressed.connect(preview)
	buttons.add_child(apply_button)
	var back := UI.button("Назад")
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(close)
	buttons.add_child(back)
	confirmation = VBoxContainer.new()
	confirmation.add_theme_constant_override("separation", 14)
	column.add_child(confirmation)
	confirmation.add_child(UI.label("Оставить эти настройки?", 18))
	countdown = UI.label("", 13, UI.MUTED)
	confirmation.add_child(countdown)
	var keep := UI.button("Оставить")
	keep.pressed.connect(confirm)
	confirmation.add_child(keep)
	revert_button = UI.button("Вернуть прежние")
	revert_button.pressed.connect(revert)
	confirmation.add_child(revert_button)
	hide()

func choice() -> OptionButton:
	var b := OptionButton.new()
	b.custom_minimum_size.y = 30
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", Color(UI.PAPER))
	b.add_theme_stylebox_override("normal", UI.panel_style(UI.PANEL, "50625a", 6))
	b.add_theme_stylebox_override("hover", UI.panel_style("405d58", UI.GOLD, 6))
	b.add_theme_stylebox_override("focus", UI.panel_style("00000000", UI.GOLD, 0))
	return b

func open() -> void:
	if is_open: return
	was_paused = get_tree().paused
	var focused := get_viewport().gui_get_focus_owner()
	previous_focus = weakref(focused) if focused != null else null
	is_open = true
	get_tree().paused = true
	show()
	show_options()

func show_options() -> void:
	options.show()
	confirmation.hide()
	mode_choice.select(1 if settings.fullscreen else 0)
	resolution_choice.select(settings.RESOLUTIONS.find(settings.resolution))
	for index in range(settings.RESOLUTIONS.size()):
		resolution_choice.set_item_disabled(index, not settings.fits_window(settings.RESOLUTIONS[index]))
	update_note()
	UI.trap_focus(panel)
	mode_choice.grab_focus()

func update_note() -> void:
	resolution_choice.disabled = mode_choice.selected == 1
	note.text = "На весь экран — разрешение монитора. Формат игры 16:9 сохраняется." if resolution_choice.disabled else "Чёткие пиксели без размытия. Недоступные размеры не помещаются на этом мониторе."
	UI.trap_focus.call_deferred(panel)

func preview() -> void:
	if not settings.begin_preview(settings.RESOLUTIONS[resolution_choice.selected], mode_choice.selected == 1):
		note.text = "Этот размер недоступен. Выбери меньшее разрешение."
		return
	seconds_left = 15.0
	options.hide()
	confirmation.show()
	update_countdown()
	UI.trap_focus(panel)
	revert_button.grab_focus()

func confirm() -> void:
	var saved: bool = settings.confirm_preview()
	show_options()
	note.text = "Настройки экрана сохранены." if saved else "Не удалось записать настройки. Возвращён прежний режим."

func revert() -> void:
	settings.cancel_preview()
	show_options()
	note.text = "Возвращены прежние настройки."

func close() -> void:
	if not is_open: return
	settings.cancel_preview()
	is_open = false
	hide()
	get_tree().paused = was_paused
	if previous_focus != null:
		var focused = previous_focus.get_ref()
		if is_instance_valid(focused) and focused.is_visible_in_tree(): focused.grab_focus()
	previous_focus = null

func update_countdown() -> void:
	countdown.text = "Возврат к прежнему режиму через %d сек.\nEsc — отмена." % ceili(seconds_left)

func _process(delta: float) -> void:
	if is_open and settings.previewing:
		seconds_left -= delta
		if seconds_left <= 0: revert()
		else: update_countdown()

func _input(event: InputEvent) -> void:
	if not is_open or event.is_echo(): return
	if event.is_action_pressed("pause"):
		if settings.previewing: revert()
		else: close()
		get_viewport().set_input_as_handled()
