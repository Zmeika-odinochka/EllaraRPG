extends CanvasLayer

signal closed
var is_open: bool = false
var mode: String = "mira"
var overlay: Control
var close_button: Button
var accept_button: Button
var speaker_label: Label
var title_label: Label
var body_label: Label
var detail_label: Label
var status_label: Label
var state: Node


static func panel_style(background: String, border: String, margin: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(background)
	style.border_color = Color(border)
	style.set_border_width_all(2)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style


func text_label(size: int, color: String) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(color))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 34
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("f1dfb1"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", panel_style("35554b", "254038", 6))
	button.add_theme_stylebox_override("hover", panel_style("496e59", "d1b777", 6))
	button.add_theme_stylebox_override("pressed", panel_style("263f37", "d1b777", 6))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("d1b777")
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	return button


func _ready() -> void:
	state = get_node("/root/GameState")
	state.quest_changed.connect(refresh)
	layer = 20
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.08, 0.08, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 470
	panel.add_theme_stylebox_override("panel", panel_style("e7d5ab", "72523b", 18))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	speaker_label = text_label(12, "647052")
	title_label = text_label(22, "3c3930")
	body_label = text_label(14, "65533f")
	detail_label = text_label(14, "463e33")
	status_label = text_label(12, "647052")
	for label in [speaker_label, title_label, body_label, detail_label, status_label]:
		column.add_child(label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	accept_button = make_button("Принять")
	close_button = make_button("Закрыть · Esc")
	buttons.add_child(accept_button)
	buttons.add_child(close_button)
	accept_button.pressed.connect(_accept)
	close_button.pressed.connect(close)
	overlay.hide()


func refresh() -> void:
	var available: bool = state.quest_stage == state.QuestStage.AVAILABLE
	var met_corvin: bool = state.quest_stage == state.QuestStage.MET_CORVIN
	accept_button.visible = mode == "mira" and available
	close_button.text = "Отказаться · Esc" if accept_button.visible else "Закрыть · Esc"
	title_label.text = "Подготовка ярмарки"
	detail_label.text = "Награда: 18 медяков группе.\nСрок: до начала завтрашней ярмарки.\nРасчёт: в гильдии после подписи Корвина."
	status_label.text = "Задание ещё не принято" if available else "Принято · " + state.objective()
	match mode:
		"mira":
			speaker_label.text = "МИРА / ГИЛЬДИЯ ЭЛЬГАРДА"
			if available:
				body_label.text = "«На площади нужны руки. Если берёшься, найди Корвина — он определит работу на месте»."
			elif met_corvin:
				body_label.text = "«С Корвином уже поговорил? За расчётом приходи с его подписью после работы»."
			else:
				body_label.text = "«Записала поручение за вами. Корвин у торговых навесов на площади. Выход — внизу зала»."
		"journal":
			speaker_label.text = "ЖУРНАЛ ЗАДАНИЙ / J"
			if available:
				title_label.text = "Пока нет заданий"
				body_label.text = "Мира у стойки гильдии подскажет, где нужна помощь."
				detail_label.text = "Поговорите с ней и выберите «Принять», чтобы добавить поручение в журнал."
				status_label.text = "Активных заданий: 0"
			else:
				body_label.text = "Помочь с подготовкой центральной площади. Объём работ определяет Корвин."
				status_label.text = "Активных заданий: 1\n" + state.objective()
		"corvin":
			speaker_label.text = "КОРВИН / РАСПОРЯДИТЕЛЬ ЯРМАРКИ"
			if available:
				title_label.text = "Ищешь работу?"
				body_label.text = "«Сначала зайди к Мире в гильдию. Она оформит поручение, потом возвращайся ко мне»."
				detail_label.text = "Гильдия — здание слева от площади."
			else:
				body_label.text = "«От Миры? Хорошо. Работы хватает — сначала согласуем, за что вы возьмётесь»."
				detail_label.text = "Вы нашли Корвина. Подготовка ярмарки продолжится в следующем этапе игры."
				status_label.text = "Встреча отмечена в журнале · Награда ещё не получена"


func _accept() -> void:
	if is_open and mode == "mira" and state.quest_stage == state.QuestStage.AVAILABLE:
		state.accept_quest()
		close_button.grab_focus()


func open(context: String = "mira") -> void:
	if is_open:
		return
	mode = context
	is_open = true
	if mode == "corvin":
		state.meet_corvin()
	refresh()
	overlay.show()
	# Opening a window never accepts a quest through a held key.
	close_button.grab_focus()


func close() -> void:
	if not is_open:
		return
	is_open = false
	overlay.hide()
	close_button.release_focus()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not is_open or event.is_echo():
		return
	if event.is_action_pressed("close_dialogue") or (mode == "journal" and event.is_action_pressed("journal")):
		close()
		get_viewport().set_input_as_handled()
