extends CanvasLayer
## NPC conversations own their topics; the journal remains a separate player menu.
signal closed
const UI = preload("res://scripts/ui_theme.gd")
const Catalog = preload("res://scripts/quest_catalog.gd")
const Portrait = preload("res://scripts/pixel_character.gd")
var is_open := false
var mode := "mira"
var topic := "main"
var state: Node
var overlay: Control
var panel: PanelContainer
var speaker_label: Label
var body_label: Label
var reply_label: Label
var text_scroll: ScrollContainer
var accept_button: Button
var options_button: Button
var close_button: Button
var topic_buttons: VBoxContainer
var portrait: Node2D

func reply_button(text: String, parent: Node) -> Button:
	var b := UI.button(text, true)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(b)
	return b

func _ready() -> void:
	state = get_node("/root/GameState")
	state.quest_changed.connect(refresh)
	layer = 20
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	panel = UI.box(UI.DARK, 10)
	panel.position = Vector2(14, 98)
	panel.custom_minimum_size = Vector2(612, 0)
	panel.minimum_size_changed.connect(panel.reset_size.call_deferred)
	panel.resized.connect(func(): panel.position.y = 348 - panel.size.y)
	overlay.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	reply_label = UI.label("", 10, UI.MUTED)
	column.add_child(reply_label)
	var speech := HBoxContainer.new()
	speech.add_theme_constant_override("separation", 12)
	speech.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(speech)
	var portrait_box := UI.box(UI.PANEL, 0)
	portrait_box.custom_minimum_size = Vector2(64, 86)
	portrait_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	speech.add_child(portrait_box)
	var canvas := Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_box.add_child(canvas)
	portrait = Portrait.new()
	portrait.position = Vector2(32, 80)
	portrait.scale = Vector2(2, 2)
	canvas.add_child(portrait)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 4)
	speech.add_child(words)
	speaker_label = UI.label("", 17, UI.GOLD)
	words.add_child(speaker_label)
	text_scroll = ScrollContainer.new()
	text_scroll.custom_minimum_size.y = 72
	text_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	words.add_child(text_scroll)
	body_label = UI.label("", 14)
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_scroll.add_child(body_label)
	var replies := VBoxContainer.new()
	replies.add_theme_constant_override("separation", 3)
	column.add_child(replies)
	accept_button = reply_button("Берусь.", replies)
	accept_button.pressed.connect(_accept)
	options_button = reply_button("Есть ещё работа?", replies)
	options_button.pressed.connect(_options)
	topic_buttons = VBoxContainer.new()
	topic_buttons.add_theme_constant_override("separation", 3)
	replies.add_child(topic_buttons)
	for id in Catalog.QUESTS:
		var b := reply_button("Расскажи про архив." if id == "archive" else "Что нужно передать Корвину?", topic_buttons)
		b.pressed.connect(select_topic.bind(id, b.text))
	close_button = reply_button("До встречи.", replies)
	close_button.pressed.connect(_back)
	overlay.hide()

func refresh() -> void:
	if not is_open: return
	speaker_label.text = "Мира" if mode == "mira" else "Корвин"
	portrait.is_mira = mode == "mira"
	portrait.modulate = Color.WHITE if mode == "mira" else Color(1, 0.88, 0.7)
	accept_button.hide()
	options_button.visible = topic == "main" and (mode == "mira" or state.side_quests.parcel == "packed")
	options_button.text = "Есть ещё работа?" if mode == "mira" else "Мира просила передать тебе этот пакет."
	topic_buttons.visible = topic == "topics"
	close_button.text = "До встречи." if topic == "main" else "Поговорим о другом."
	reply_label.visible = not reply_label.text.is_empty()
	if topic == "topics":
		body_label.text = "О чём хочешь поговорить — об архиве или о доставке Корвину?"
	elif topic in Catalog.QUESTS:
		refresh_side()
	elif mode == "mira":
		refresh_mira()
	else:
		refresh_corvin()
	text_scroll.scroll_vertical = 0
	UI.trap_focus.call_deferred(overlay)
	panel.reset_size.call_deferred()

func refresh_mira() -> void:
	match state.quest_stage:
		state.QuestStage.AVAILABLE:
			body_label.text = "Есть работа на площади для одного человека. До завтрашней ярмарки нужно помочь Корвину с подготовкой. Восемнадцать медяков лично тебе — после его подписи. Берёшься?"
			accept_button.text = "Берусь. Где найти Корвина?"
			accept_button.show()
			close_button.text = "Пока не готов браться."
		state.QuestStage.ACCEPTED:
			body_label.text = "Записала поручение за тобой. Корвин у торговых навесов на площади. Выход — внизу зала."
		state.QuestStage.APPROVED:
			body_label.text = "Вижу подпись Корвина. Всё принято. Вот твои восемнадцать медяков — пересчитай."
			accept_button.text = "Спасибо. Заберу свои 18 медяков."
			accept_button.show()
		state.QuestStage.COMPLETED:
			body_label.text = "Расчёт закрыт. Спасибо за работу, Филипп. С тобой можно иметь дело."
		_:
			body_label.text = "Как дела на площади? За расчётом приходи после приёмки: Корвин должен проверить работу и поставить подпись."

func refresh_corvin() -> void:
	match state.quest_stage:
		state.QuestStage.AVAILABLE:
			body_label.text = "Ищешь работу? Сначала зайди к Мире в гильдию — вон то здание слева. Она оформит поручение, потом возвращайся."
		state.QuestStage.MET_CORVIN:
			body_label.text = "Разбери доски у бочек, расставь товар на синем прилавке и закрепи красный навес. Потом позови меня на проверку. Мира заплатит после моей подписи."
		state.QuestStage.WORK_DONE:
			body_label.text = "Всё подготовил? Давай проверю доски, товар и крепление навеса."
			accept_button.text = "Всё готово. Посмотришь?"
			accept_button.show()
		state.QuestStage.APPROVED:
			body_label.text = "Порядок. Доски сложены, товар на месте, навес закреплён. Подписываю поручение — отнеси Мире, получишь свои восемнадцать медяков."
		_:
			body_label.text = "Твою работу я уже принял. Хорошо справился. Теперь можно готовиться к ярмарке."
	if topic == "delivered":
		body_label.text = "Вот и разрешения! Теперь торговцам не придётся ждать. Держи расписку — покажешь Мире, она рассчитается с тобой."
	elif "permits_delivered" in state.npc_knowledge.corvin:
		body_label.text += " Разрешения, которые ты принёс, уже у меня."

func refresh_side() -> void:
	var definition: Dictionary = Catalog.QUESTS[topic]
	match str(state.side_quests[topic]):
		"available":
			body_label.text = definition.offer.trim_prefix("«").trim_suffix("».")
			accept_button.text = "Разберу бумаги." if topic == "archive" else "Хорошо, соберу и отнесу пакет."
			accept_button.show()
		"active":
			body_label.text = "Бумаги ждут у доски объявлений. Разложи их по папкам, а потом покажи мне результат." if topic == "archive" else "Собери документы у доски объявлений: вложи, перевяжи и запечатай. Корвин ждёт пакет на площади."
		"packed":
			body_label.text = "Вижу, пакет готов. Отнеси его Корвину лично и принеси расписку. Тогда и рассчитаемся."
		"ready":
			body_label.text = "Уже разобрал бумаги? Покажи, что получилось." if topic == "archive" else "Вернулся от Корвина? Он получил разрешения?"
			accept_button.text = "Вот записи. Проверь, пожалуйста." if topic == "archive" else "Да. Вот его расписка."
			accept_button.show()
		"completed":
			body_label.text = definition.ready.trim_prefix("«").trim_suffix("».")
	options_button.show()
	options_button.text = "А какие ещё есть поручения?"

func select_topic(id: String, reply: String) -> void:
	if not is_open or mode != "mira" or id not in Catalog.QUESTS: return
	topic = id
	reply_label.text = "Филипп: " + reply
	refresh()
	close_button.grab_focus()

func _options() -> void:
	if not is_open or not options_button.visible: return
	reply_label.text = "Филипп: " + options_button.text
	if mode == "corvin":
		if state.deliver_parcel(): topic = "delivered"
	else:
		topic = "topics"
	refresh()
	close_button.grab_focus()

func _accept() -> void:
	if not is_open or not accept_button.visible: return
	reply_label.text = "Филипп: " + accept_button.text
	if topic in Catalog.QUESTS and mode == "mira":
		if state.side_quests[topic] == "available": state.accept_side_quest(topic)
		elif state.side_quests[topic] == "ready": state.claim_side_reward(topic)
	elif mode == "mira" and topic == "main":
		if state.quest_stage == state.QuestStage.AVAILABLE: state.accept_quest()
		elif state.quest_stage == state.QuestStage.APPROVED: state.claim_reward()
	elif mode == "corvin" and topic == "main":
		state.approve_work()
	refresh()
	close_button.grab_focus()

func _back() -> void:
	if topic == "main": close()
	else:
		topic = "main"
		reply_label.text = ""
		refresh()
		close_button.grab_focus()

func open(context: String = "mira") -> void:
	if is_open: return
	mode = context
	topic = "main"
	reply_label.text = ""
	is_open = true
	if mode == "corvin": state.meet_corvin()
	refresh()
	overlay.show()
	UI.trap_focus(overlay)
	close_button.grab_focus()

func close() -> void:
	if not is_open: return
	is_open = false
	overlay.hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if not is_open or event.is_echo(): return
	if event.is_action_pressed("page_up") or event.is_action_pressed("page_down"):
		text_scroll.scroll_vertical += -64 if event.is_action_pressed("page_up") else 64
		get_viewport().set_input_as_handled()
