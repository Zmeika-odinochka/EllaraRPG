extends CanvasLayer

signal closed
signal options_requested(context: String)
var options_button: Button
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
	panel.custom_minimum_size.x = 540
	panel.add_theme_stylebox_override("panel", panel_style("e7d5ab", "72523b", 18))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 230
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 8)
	scroll.add_child(text_column)
	speaker_label = text_label(12, "647052")
	title_label = text_label(22, "3c3930")
	body_label = text_label(14, "65533f")
	detail_label = text_label(14, "463e33")
	status_label = text_label(12, "647052")
	for label in [speaker_label, title_label, body_label, detail_label, status_label]:
		text_column.add_child(label)
	options_button = make_button("Другие поручения")
	options_button.pressed.connect(_options)
	column.add_child(options_button)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	accept_button = make_button("Принять")
	close_button = make_button("Закрыть")
	buttons.add_child(accept_button)
	buttons.add_child(close_button)
	close_button.focus_next = accept_button.get_path()
	accept_button.pressed.connect(_accept)
	close_button.pressed.connect(close)
	overlay.hide()


func refresh() -> void:
	options_button.visible = mode in ["mira", "journal"] or (mode == "corvin" and state.side_quests.parcel == "packed")
	options_button.text = "Все задания" if mode == "journal" else ("Передать пакет Миры" if mode == "corvin" else "Другие поручения")
	var phase: int = state.quest_stage
	var available: bool = phase == state.QuestStage.AVAILABLE
	accept_button.hide()
	accept_button.text = "Принять"
	close_button.text = "Закрыть"
	title_label.text = "Подготовка ярмарки"
	detail_label.text = "Награда: 18 медяков лично тебе.\nСрок: до начала завтрашней ярмарки.\nРасчёт: у Миры после подписи Корвина."
	status_label.text = "Задание ещё не принято" if available else state.objective()
	match mode:
		"mira":
			speaker_label.text = "МИРА / ГИЛЬДИЯ ЭЛЬГАРДА"
			if available:
				body_label.text = "«Есть работа на площади для одного человека. Если берёшься, найди Корвина — он объяснит, что сделать»."
				accept_button.show()
				close_button.text = "Отказаться"
			elif phase == state.QuestStage.ACCEPTED:
				body_label.text = "«Записала поручение за тобой. Корвин у торговых навесов на площади. Выход — внизу зала»."
			elif phase == state.QuestStage.APPROVED:
				body_label.text = "«Вижу подпись Корвина. Работа принята — можешь получить свои восемнадцать медяков»."
				detail_label.text = "Поручение выполнено лично тобой.\nК выплате: 18 медяков."
				accept_button.text = "Получить 18 медяков"
				accept_button.show()
			elif phase == state.QuestStage.COMPLETED:
				body_label.text = "«Расчёт закрыт. Спасибо за работу — с тобой можно иметь дело»."
				detail_label.text = "Награда получена: 18 медяков.\nВ твоём кошельке: %d." % state.personal_coins
				status_label.text = "Поручение завершено"
			else:
				body_label.text = "«За расчётом приходи после приёмки. Корвин должен проверить твою работу и поставить подпись»."
		"journal":
			speaker_label.text = "ЖУРНАЛ ЗАДАНИЙ / J"
			if available:
				title_label.text = "Пока нет заданий"
				body_label.text = "Мира у стойки гильдии подскажет, где нужна помощь."
				detail_label.text = "Поговори с ней и выбери «Принять», чтобы добавить поручение в журнал."
				status_label.text = "Активных заданий: 0"
			elif phase == state.QuestStage.COMPLETED:
				body_label.text = "Ты подготовил площадь, сдал работу Корвину и получил оплату у Миры."
				detail_label.text = "Получено лично: 18 медяков.\nКошелёк: %d медяков." % state.personal_coins
				status_label.text = "Активных: 0 · Завершённых: 1"
			else:
				body_label.text = "Личное поручение: помочь с подготовкой центральной площади."
				if phase >= state.QuestStage.MET_CORVIN:
					detail_label.text = state.work_checklist() + "\nНаграда: 18 медяков лично тебе."
				status_label.text = "Активных заданий: 1\n" + state.objective()
		"corvin":
			speaker_label.text = "КОРВИН / РАСПОРЯДИТЕЛЬ ЯРМАРКИ"
			if available:
				title_label.text = "Ищешь работу?"
				body_label.text = "«Сначала зайди к Мире в гильдию. Она оформит поручение, потом возвращайся ко мне»."
				detail_label.text = "Гильдия — здание слева от площади."
			elif phase == state.QuestStage.MET_CORVIN:
				body_label.text = "«Разбери доски у бочек, расставь товар на синем прилавке и закрепи красный навес. Потом позови меня на проверку»."
				detail_label.text = state.work_checklist()
				status_label.text = "Готово: %d / 3 · Награда ещё не получена" % state.completed_steps.size()
			elif phase == state.QuestStage.WORK_DONE:
				body_label.text = "«Всё подготовил? Давай проверю доски, товар и крепление навеса»."
				detail_label.text = state.work_checklist()
				accept_button.text = "Сдать работу"
				accept_button.show()
				status_label.text = "Работа сделана · Ожидает приёмки"
			elif phase == state.QuestStage.APPROVED:
				body_label.text = "«Порядок. Доски сложены, товар на месте, навес закреплён. Подписываю поручение — отнеси его Мире»."
				detail_label.text = "Подпись Корвина получена.\nЗа 18 медяками вернись в гильдию."
				status_label.text = "Принято Корвином · Награда ещё не получена"
			else:
				body_label.text = "«Твою работу я уже принял. Хорошо справился»."
				detail_label.text = "Поручение завершено.\n18 медяков уже выплачены Мирой."
				status_label.text = "Расчёт закрыт"
			if "permits_delivered" in state.npc_knowledge.corvin:
				body_label.text += "\n«Разрешения получил. Торговцам больше не придётся ждать»."
	if mode == "journal":
		var active_count := 1 if phase > state.QuestStage.AVAILABLE and phase < state.QuestStage.COMPLETED else 0
		var completed_count := 1 if phase == state.QuestStage.COMPLETED else 0
		var extra_lines: PackedStringArray = []
		for id in state.Catalog.QUESTS:
			var status: String = state.side_quests[id]
			if status == "available":
				continue
			if status == "completed":
				completed_count += 1
			else:
				active_count += 1
			extra_lines.append(state.Catalog.QUESTS[id].title + "\n" + state.side_objective(id))
		if not extra_lines.is_empty():
			title_label.text = "Журнал заданий"
			body_label.text = "Подготовка ярмарки: " + state.quest_summary(phase)
			detail_label.text = "\n\n".join(extra_lines)
			status_label.text = "Активных: %d · Завершённых: %d" % [active_count, completed_count]


func _options() -> void:
	if mode == "corvin":
		state.deliver_parcel()
		refresh()
		return
	var context := "quests" if mode == "journal" else "jobs"
	close()
	options_requested.emit(context)


func _accept() -> void:
	if not is_open:
		return
	if mode == "mira":
		if state.quest_stage == state.QuestStage.AVAILABLE:
			state.accept_quest()
		elif state.quest_stage == state.QuestStage.APPROVED:
			state.claim_reward()
	elif mode == "corvin":
		state.approve_work()
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
	if mode == "journal" and event.is_action_pressed("journal"):
		close()
		get_viewport().set_input_as_handled()
