extends CanvasLayer
signal closed
signal work_requested(id: String)
const UI = preload("res://scripts/quest_dialogue.gd")
const Catalog = preload("res://scripts/quest_catalog.gd")
var is_open := false
var mode := "inventory"
var state: Node
var body: VBoxContainer
var info: Label
var close_button: Button

func _ready() -> void:
	layer = 22
	state = get_node("/root/GameState")
	state.quest_changed.connect(refresh)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.06, 0.06, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 370)
	panel.add_theme_stylebox_override("panel", UI.panel_style("e7d5ab", "72523b", 14))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(552, 294)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 9)
	scroll.add_child(body)
	close_button = button("Закрыть")
	close_button.pressed.connect(close)
	column.add_child(close_button)
	hide()

func label(text: String, size: int = 14) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color("463e33"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 34
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", UI.panel_style("35554b", "72523b", 6))
	b.add_theme_stylebox_override("hover", UI.panel_style("496e59", "d1b777", 6))
	return b

func open(context: String) -> void:
	mode = context
	is_open = true
	refresh()
	show()
	close_button.grab_focus()

func refresh() -> void:
	if not is_open:
		return
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if mode == "inventory":
		build_inventory()
	else:
		build_quests()

func build_inventory() -> void:
	body.add_child(label("ФИЛИПП · УРОВЕНЬ 1 · РАНГ F", 21))
	body.add_child(label("Медяки: %d   ·   Время игры: %s" % [state.personal_coins, state.format_play_time(state.play_seconds)]))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	body.add_child(row)
	var stats := VBoxContainer.new()
	stats.custom_minimum_size.x = 174
	row.add_child(stats)
	stats.add_child(label("Характеристики", 17))
	for key in state.BASE_STATS:
		stats.add_child(label("%s: %d" % [key, int(state.attributes.get(key, 0))], 13))
	var items := VBoxContainer.new()
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(items)
	items.add_child(label("Инвентарь", 17))
	var grid := GridContainer.new()
	grid.columns = 2
	items.add_child(grid)
	var keys: Array = state.inventory.keys()
	for index in range(6):
		var id := str(keys[index]) if index < keys.size() else ""
		var b := button("—")
		b.custom_minimum_size = Vector2(160, 38)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = id.is_empty()
		if not id.is_empty():
			b.text = "%s ×%d" % [Catalog.ITEMS[id].name, int(state.inventory[id])]
			b.pressed.connect(show_item.bind(id))
		grid.add_child(b)
	info = label("Здесь появятся предметы поручений. Выбери предмет, чтобы прочитать описание.", 12)
	items.add_child(info)
	if not keys.is_empty():
		show_item(str(keys[0]))

func show_item(id: String) -> void:
	info.text = Catalog.ITEMS[id].description

func build_quests() -> void:
	if mode == "work":
		body.add_child(label("Рабочее место гильдии", 22))
		body.add_child(label("Выбери работу. Поручения выдаёт Мира у стойки.", 13))
		for id in Catalog.QUESTS:
			var b := button(Catalog.QUESTS[id].title)
			b.disabled = state.side_quests[id] != "active"
			b.pressed.connect(request_work.bind(id))
			body.add_child(b)
		return
	body.add_child(label("Поручения Миры" if mode == "jobs" else "Все задания", 22))
	if mode == "quests":
		body.add_child(label("Подготовка ярмарки · 18 медяков", 17))
		body.add_child(label(state.quest_summary(state.quest_stage), 13))
	for id in Catalog.QUESTS:
		var definition: Dictionary = Catalog.QUESTS[id]
		body.add_child(label("%s · %d медяков" % [definition.title, definition.reward], 17))
		body.add_child(label(definition.offer if mode == "jobs" and state.side_quests[id] == "available" else state.side_objective(id), 13))
		if mode == "jobs":
			var status: String = state.side_quests[id]
			if status == "available":
				var accept := button("Взяться за поручение")
				accept.pressed.connect(state.accept_side_quest.bind(id))
				body.add_child(accept)
			elif status == "ready":
				var claim := button("Показать результат и получить %d медяков" % definition.reward)
				claim.pressed.connect(state.claim_side_reward.bind(id))
				body.add_child(claim)
			elif status == "completed":
				body.add_child(label(definition.ready, 13))
	if mode == "jobs" and state.work_trust.mira > 0:
		body.add_child(label("«Ты уже помог гильдии. Хорошо, что зашёл снова».", 13))

func close() -> void:
	if not is_open:
		return
	is_open = false
	hide()
	closed.emit()

func request_work(id: String) -> void:
	close()
	work_requested.emit(id)

func _input(event: InputEvent) -> void:
	if not is_open or event.is_echo():
		return
	if (mode == "inventory" and event.is_action_pressed("inventory")) or (mode == "quests" and event.is_action_pressed("journal")):
		close()
		get_viewport().set_input_as_handled()
