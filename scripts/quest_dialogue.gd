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


const ThemeUI = preload("res://scripts/ui_theme.gd")
var panel: PanelContainer
var text_scroll: ScrollContainer

static func panel_style(background: String, border: String, margin: int = 16) -> StyleBoxFlat:
	return ThemeUI.panel_style(background, border, margin)

func text_label(font_size: int, color: String) -> Label:
	return ThemeUI.label("", font_size, color)

func make_button(text: String) -> Button:
	var b := ThemeUI.button(text)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b

func _ready() -> void:
	state = get_node("/root/GameState")
	state.quest_changed.connect(refresh)
	layer = 20
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.06, 0.06, 0.25)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	panel = ThemeUI.box(ThemeUI.DARK, 12)
	panel.position = Vector2(14, 136)
	panel.size = Vector2(612, 252)
	overlay.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	speaker_label = text_label(11, ThemeUI.GOLD)
	column.add_child(speaker_label)
	var scroll := ScrollContainer.new()
	text_scroll = scroll
	scroll.custom_minimum_size.y = 142
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 6)
	scroll.add_child(text_column)
	title_label = text_label(19, ThemeUI.PAPER)
	body_label = text_label(14, ThemeUI.PAPER)
	detail_label = text_label(11, ThemeUI.MUTED)
	status_label = text_label(11, ThemeUI.GOLD)
	for l in [title_label, body_label, detail_label]:
		text_column.add_child(l)
	column.add_child(status_label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	column.add_child(buttons)
	options_button = make_button("Другие поручения")
	options_button.pressed.connect(_options)
	accept_button = make_button("Принять")
	close_button = make_button("Закрыть")
	buttons.add_child(accept_button)
	buttons.add_child(options_button)
	buttons.add_child(close_button)
	accept_button.pressed.connect(_accept)
	close_button.pressed.connect(close)
	overlay.hide()

func refresh() -> void:
	if is_open: ThemeUI.trap_focus.call_deferred(overlay)
	options_button.visible = mode == "mira" or (mode == "corvin" and state.side_quests.parcel == "packed")
	options_button.text = "Передать пакет Миры" if mode == "corvin" else "Другие поручения"
	var phase: int = state.quest_stage
	var available: bool = phase == state.QuestStage.AVAILABLE
	accept_button.hide()
	accept_button.text = "Принять"
	close_button.text = "Закрыть"
	title_label.text = "Подготовка ярмарки"
	detail_label.text = "18 медяков лично тебе · До начала завтрашней ярмарки\nОплата у Миры после подписи Корвина."
	status_label.text = "Задание ещё не принято" if available else state.main_objective()
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


func _options() -> void:
	if mode == "corvin":
		state.deliver_parcel()
		refresh()
		return
	var context := "jobs"
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
	text_scroll.scroll_vertical = 0
	overlay.show()
	ThemeUI.trap_focus(overlay)
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
	if not is_open or event.is_echo(): return
	if event.is_action_pressed("page_up") or event.is_action_pressed("page_down"):
		text_scroll.scroll_vertical += -64 if event.is_action_pressed("page_up") else 64
		get_viewport().set_input_as_handled()
