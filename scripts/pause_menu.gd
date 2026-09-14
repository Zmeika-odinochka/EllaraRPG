extends CanvasLayer
## Always-available pause. Underlying dialogue or work stays untouched.

const UI = preload("res://scripts/quest_dialogue.gd")
var world: Node
var state: Node
var home: VBoxContainer
var save_panel: VBoxContainer
var save_rows: VBoxContainer
var status_label: Label
var save_button: Button
var confirm_overlay: Control
var confirm_text: Label
var pending_slot: int = 0
var is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	world = get_parent()
	state = get_node("/root/GameState")
	build_ui()
	hide_pause()


func label(text: String, size: int, color: String = "f1dfb1") -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", Color(color))
	return result


func button(text: String) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 36
	result.add_theme_font_size_override("font_size", 14)
	result.add_theme_color_override("font_color", Color("f1dfb1"))
	result.add_theme_color_override("font_hover_color", Color.WHITE)
	result.add_theme_color_override("font_disabled_color", Color("7f887c"))
	result.add_theme_stylebox_override("normal", UI.panel_style("29463f", "9b8256", 7))
	result.add_theme_stylebox_override("hover", UI.panel_style("416558", "d1b777", 7))
	result.add_theme_stylebox_override("pressed", UI.panel_style("203a34", "d1b777", 7))
	result.add_theme_stylebox_override("disabled", UI.panel_style("283733", "53635a", 7))
	return result


func build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.05, 0.05, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var root_panel := PanelContainer.new()
	root_panel.custom_minimum_size = Vector2(600, 330)
	root_panel.add_theme_stylebox_override("panel", UI.panel_style("e4d1a6", "76543b", 16))
	center.add_child(root_panel)
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	root_panel.add_child(container)
	var title := label("ПАУЗА", 24, "3f3a30")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	status_label = label("", 12, "635b49")
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(status_label)
	home = VBoxContainer.new()
	home.add_theme_constant_override("separation", 7)
	container.add_child(home)
	var resume := button("Продолжить")
	resume.pressed.connect(close_pause)
	home.add_child(resume)
	save_button = button("Сохранить")
	save_button.pressed.connect(open_save_slots)
	home.add_child(save_button)
	var main_menu := button("В главное меню")
	main_menu.pressed.connect(state.return_to_main_menu)
	home.add_child(main_menu)
	var exit := button("Выйти из игры")
	exit.pressed.connect(state.exit_game)
	home.add_child(exit)
	save_panel = VBoxContainer.new()
	save_panel.add_theme_constant_override("separation", 4)
	container.add_child(save_panel)
	var save_title := label("Выберите слот", 16, "3f3a30")
	save_panel.add_child(save_title)
	save_rows = VBoxContainer.new()
	save_rows.add_theme_constant_override("separation", 4)
	save_panel.add_child(save_rows)
	var back := button("Назад")
	back.pressed.connect(close_save_slots)
	save_panel.add_child(back)
	save_panel.hide()
	build_confirmation()


func build_confirmation() -> void:
	confirm_overlay = Control.new()
	confirm_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(confirm_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.04, 0.74)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 390
	panel.add_theme_stylebox_override("panel", UI.panel_style("e4d1a6", "76543b", 18))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	confirm_text = label("", 16, "3f3a30")
	confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(confirm_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	var yes := button("Перезаписать")
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(confirm_overwrite)
	row.add_child(yes)
	var no := button("Отмена")
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(close_confirmation)
	row.add_child(no)
	confirm_overlay.hide()


func open_pause() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	home.show()
	save_panel.hide()
	confirm_overlay.hide()
	var can_save: bool = world.can_manual_save()
	save_button.disabled = not can_save
	status_label.text = "Текущий слот: %d" % state.active_slot
	if not can_save:
		status_label.text += " · Сохранение доступно после диалога или действия"
	get_tree().paused = true


func close_pause() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = false


func hide_pause() -> void:
	is_open = false
	visible = false


func open_save_slots() -> void:
	if not world.can_manual_save():
		return
	home.hide()
	save_panel.show()
	refresh_slots()


func close_save_slots() -> void:
	save_panel.hide()
	home.show()
	status_label.text = "Текущий слот: %d" % state.active_slot


func slot_text(slot: int, data: Dictionary) -> String:
	if data.is_empty():
		return "СЛОТ %d · Пусто" % slot
	return "СЛОТ %d · %s · %s · %d мед. · %s · %s" % [slot, state.location_name(str(data.location_scene)), state.quest_summary(int(data.quest_stage)), int(data.personal_coins), state.format_play_time(float(data.play_seconds)), state.format_saved_at(int(data.saved_at))]


func refresh_slots() -> void:
	for child in save_rows.get_children():
		child.queue_free()
	for entry in state.slots():
		var slot := int(entry.slot)
		var select := button(slot_text(slot, entry.data))
		select.add_theme_font_size_override("font_size", 11)
		select.alignment = HORIZONTAL_ALIGNMENT_LEFT
		select.pressed.connect(select_save_slot.bind(slot, bool(entry.occupied)))
		save_rows.add_child(select)


func select_save_slot(slot: int, occupied: bool) -> void:
	if occupied:
		pending_slot = slot
		confirm_text.text = "Перезаписать слот %d текущим прогрессом?" % slot
		confirm_overlay.show()
	else:
		perform_save(slot)


func confirm_overwrite() -> void:
	var slot := pending_slot
	close_confirmation()
	perform_save(slot)


func close_confirmation() -> void:
	pending_slot = 0
	confirm_overlay.hide()


func perform_save(slot: int) -> void:
	if state.save_game(slot, "", Vector2.INF, "manual"):
		close_save_slots()
		status_label.text = "Сохранено в слот %d · Теперь это текущий слот" % slot
	else:
		status_label.text = "Не удалось сохранить игру"


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or event.is_echo():
		return
	if not is_open:
		open_pause()
	elif confirm_overlay.visible:
		close_confirmation()
	elif save_panel.visible:
		close_save_slots()
	else:
		close_pause()
	get_viewport().set_input_as_handled()
