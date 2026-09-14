extends Control

const UI = preload("res://scripts/ui_theme.gd")
var state: Node
var home: VBoxContainer
var slot_panel: PanelContainer
var slot_title: Label
var slot_rows: VBoxContainer
var status_label: Label
var confirm_overlay: Control
var confirm_text: Label
var confirm_yes: Button
var slot_mode: String = "load"
var pending_action: String = ""
var pending_slot: int = 0
var continue_button: Button
var confirm_no: Button


func _ready() -> void:
	state = get_node("/root/GameState")
	get_tree().paused = false
	state.game_active = false
	get_node("/root/Soundscape").set_location("")
	build_ui()
	refresh_home()
	UI.trap_focus(home)
	UI.focus_first(home)


func label(text: String, size: int, color: String = "f1dfb1") -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", Color(color))
	return result


func button(text: String) -> Button:
	return UI.button(text)


func build_ui() -> void:
	var title_box := VBoxContainer.new()
	title_box.position = Vector2(322, 22)
	title_box.custom_minimum_size.x = 282
	add_child(title_box)
	var title := label("ЭЛЛАРА", 38, "efd58d")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(title)
	var subtitle := label("ФИЛИПП И ТРИ БОГИНИ", 14, "c9d2b8")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(subtitle)
	home = VBoxContainer.new()
	home.position = Vector2(375, 113)
	home.custom_minimum_size = Vector2(182, 230)
	home.add_theme_constant_override("separation", 6)
	add_child(home)
	continue_button = button("Продолжить")
	continue_button.pressed.connect(continue_recent)
	home.add_child(continue_button)
	var new_button := button("Новая игра")
	new_button.pressed.connect(open_slots.bind("new"))
	home.add_child(new_button)
	var load_button := button("Загрузить игру")
	load_button.pressed.connect(open_slots.bind("load"))
	home.add_child(load_button)
	var display_button := button("Экран")
	display_button.pressed.connect(get_node("/root/DisplaySettings").open_menu)
	home.add_child(display_button)
	var exit_button := button("Выйти")
	exit_button.pressed.connect(state.exit_game)
	home.add_child(exit_button)
	status_label = label("", 11, "d4c899")
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home.add_child(status_label)
	build_slot_panel()
	build_confirmation()


func build_slot_panel() -> void:
	slot_panel = PanelContainer.new()
	slot_panel.position = Vector2(20, 8)
	slot_panel.custom_minimum_size = Vector2(600, 344)
	slot_panel.add_theme_stylebox_override("panel", UI.panel_style(UI.DARK, "50625a", 14))
	add_child(slot_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	slot_panel.add_child(column)
	slot_title = label("Сохранения", 20, UI.GOLD)
	column.add_child(slot_title)
	slot_rows = VBoxContainer.new()
	slot_rows.add_theme_constant_override("separation", 4)
	column.add_child(slot_rows)
	var back := button("Назад")
	back.pressed.connect(close_slots)
	column.add_child(back)
	slot_panel.hide()


func build_confirmation() -> void:
	confirm_overlay = Control.new()
	confirm_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(confirm_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.05, 0.05, 0.75)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 390
	panel.add_theme_stylebox_override("panel", UI.panel_style(UI.DARK, UI.GOLD, 18))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	confirm_text = label("", 16)
	confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(confirm_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	confirm_yes = button("Подтвердить")
	confirm_yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_yes.pressed.connect(confirm_action)
	row.add_child(confirm_yes)
	var no := button("Отмена")
	confirm_no = no
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(close_confirmation)
	row.add_child(no)
	confirm_overlay.hide()


func refresh_home() -> void:
	var recent: int = state.most_recent_slot()
	continue_button.disabled = recent == 0
	status_label.text = "Нет сохранений" if recent == 0 else "Последнее сохранение: слот %d" % recent


func slot_text(slot: int, data: Dictionary) -> String:
	if data.is_empty():
		return "СЛОТ %d  ·  Пусто" % slot
	return "СЛОТ %d  ·  %s\n%s  ·  Медяки: %d  ·  %s  ·  %s" % [
		slot, state.location_name(str(data.location_scene)), state.quest_summary(int(data.quest_stage)),
		int(data.personal_coins), state.format_play_time(float(data.play_seconds)), state.format_saved_at(int(data.saved_at))]


func open_slots(mode: String) -> void:
	slot_mode = mode
	home.hide()
	slot_panel.show()
	slot_title.text = "Выберите слот для новой игры" if mode == "new" else "Загрузить игру"
	refresh_slots()
	UI.trap_focus(slot_panel)
	focus_slot()


func refresh_slots() -> void:
	for child in slot_rows.get_children():
		child.queue_free()
		slot_rows.remove_child(child)
	for entry in state.slots():
		var slot := int(entry.slot)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		slot_rows.add_child(row)
		var select := button(slot_text(slot, entry.data))
		select.custom_minimum_size.y = 44
		select.add_theme_font_size_override("font_size", 12)
		select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select.alignment = HORIZONTAL_ALIGNMENT_LEFT
		select.disabled = slot_mode == "load" and not entry.occupied
		select.pressed.connect(select_slot.bind(slot, bool(entry.occupied)))
		row.add_child(select)
		var remove := button("Удалить")
		remove.custom_minimum_size = Vector2(78, 44)
		remove.add_theme_font_size_override("font_size", 12)
		remove.disabled = not entry.occupied
		remove.pressed.connect(request_delete.bind(slot))
		row.add_child(remove)
	UI.trap_focus(slot_panel)
	focus_slot()


func close_slots() -> void:
	slot_panel.hide()
	home.show()
	refresh_home()
	UI.trap_focus(home)
	UI.focus_first(home)


func continue_recent() -> void:
	var slot: int = state.most_recent_slot()
	if slot > 0 and not state.load_game(slot):
		status_label.text = "Не удалось загрузить сохранение"


func select_slot(slot: int, occupied: bool) -> void:
	if slot_mode == "load":
		if not state.load_game(slot):
			slot_title.text = "Не удалось загрузить слот %d" % slot
	elif occupied:
		pending_action = "new"
		pending_slot = slot
		confirm_text.text = "Перезаписать слот %d и начать новую игру? Текущий прогресс этого слота будет заменён." % slot
		confirm_yes.text = "Перезаписать"
		confirm_overlay.show()
		UI.trap_focus(confirm_overlay)
		confirm_no.grab_focus()
	else:
		state.start_new_game(slot)


func request_delete(slot: int) -> void:
	pending_action = "delete"
	pending_slot = slot
	confirm_text.text = "Удалить сохранение из слота %d? Это действие нельзя отменить." % slot
	confirm_yes.text = "Удалить"
	confirm_overlay.show()
	UI.trap_focus(confirm_overlay)
	confirm_no.grab_focus()


func confirm_action() -> void:
	var action := pending_action
	var slot := pending_slot
	close_confirmation()
	if action == "delete":
		if state.delete_slot(slot):
			refresh_slots()
		else:
			slot_title.text = "Не удалось удалить слот %d" % slot
	elif action == "new":
		state.start_new_game(slot)


func close_confirmation() -> void:
	pending_action = ""
	pending_slot = 0
	confirm_overlay.hide()
	UI.trap_focus(slot_panel)
	focus_slot()


func focus_slot() -> void:
	var choices := UI.focusable_buttons(slot_panel)
	if not choices.is_empty(): choices[0].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if get_node("/root/DisplaySettings").menu.is_open: return
	if event.is_action_pressed("pause") and not event.is_echo():
		if confirm_overlay.visible:
			close_confirmation()
		elif slot_panel.visible:
			close_slots()
		get_viewport().set_input_as_handled()
