extends CanvasLayer
signal closed
signal work_requested(id: String)
const UI = preload("res://scripts/ui_theme.gd")
const Catalog = preload("res://scripts/quest_catalog.gd")
const Icon = preload("res://scripts/item_icon.gd")
const Portrait = preload("res://scripts/pixel_character.gd")
var is_open := false
var mode := "inventory"
var state: Node
var body: VBoxContainer
var info: Label
var close_button: Button
var heading: Label
var wallet: Label
var tabs: HBoxContainer
var scroll: ScrollContainer
var panel: PanelContainer
var details: VBoxContainer
var quest_actions: VBoxContainer
var detail_scroll: ScrollContainer
var selected_item := ""
var selected_quest := ""
var completed_filter := false
var item_buttons: Dictionary = {}
var quest_buttons: Dictionary = {}

func _ready() -> void:
	layer = 22
	state = get_node("/root/GameState")
	state.quest_changed.connect(refresh)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.06, 0.06, 0.68)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = UI.box(UI.DARK, 12)
	panel.custom_minimum_size = Vector2(600, 336)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	heading = UI.label("МЕНЮ ГЕРОЯ", 18, UI.GOLD)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	wallet = UI.label("", 12)
	wallet.custom_minimum_size.x = 130
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(wallet)
	tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	column.add_child(tabs)
	for entry in [["inventory", "Сумка · I"], ["hero", "Герой"], ["quests", "Задания · J"]]:
		var b := UI.button(entry[1], true)
		b.name = entry[0]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(switch_tab.bind(entry[0]))
		tabs.add_child(b)
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(574, 212)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	scroll.add_child(body)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	column.add_child(footer)
	var help := UI.label("Tab — выбор · Enter — действие · PgUp/PgDn — текст", 11, UI.MUTED)
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(help)
	close_button = UI.button("Закрыть", true)
	close_button.custom_minimum_size.x = 100
	close_button.pressed.connect(close)
	footer.add_child(close_button)
	hide()

func label(text: String, font_size: int = 13) -> Label:
	return UI.label(text, font_size)

func button(text: String) -> Button:
	return UI.button(text)

func open(context: String) -> void:
	mode = context
	is_open = true
	refresh()
	show()
	UI.trap_focus(panel)
	close_button.grab_focus()

func switch_tab(context: String) -> void:
	mode = context
	refresh()
	(tabs.get_node(context) as Button).grab_focus()

func refresh() -> void:
	if not is_open:
		return
	UI.clear(body)
	item_buttons.clear()
	quest_buttons.clear()
	scroll.scroll_vertical = 0
	tabs.visible = mode in ["inventory", "hero", "quests"]
	heading.text = "МЕНЮ ГЕРОЯ" if tabs.visible else ("ПОРУЧЕНИЯ МИРЫ" if mode == "jobs" else "РАБОЧЕЕ МЕСТО")
	wallet.text = "%d медяков" % state.personal_coins
	for b in tabs.get_children():
		b.add_theme_stylebox_override("normal", UI.panel_style("496050" if b.name == mode else "30494a", UI.GOLD if b.name == mode else "50625a", 6))
	match mode:
		"inventory": build_inventory()
		"hero": build_hero()
		"quests": build_journal()
		_: build_quests()
	UI.trap_focus.call_deferred(panel)
	if get_viewport().gui_get_focus_owner() == null:
		close_button.grab_focus()

func make_details(parent: Node, journal: bool = false) -> void:
	var box := UI.box()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	details = VBoxContainer.new()
	details.add_theme_constant_override("separation", 6)
	if not journal:
		box.add_child(details)
		return
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	box.add_child(column)
	detail_scroll = ScrollContainer.new()
	detail_scroll.custom_minimum_size.y = 80
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(detail_scroll)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(details)
	quest_actions = VBoxContainer.new()
	quest_actions.add_theme_constant_override("separation", 5)
	column.add_child(quest_actions)

func build_inventory() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size.y = 212
	body.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 240
	left.add_theme_constant_override("separation", 8)
	row.add_child(left)
	left.add_child(UI.label("ПРЕДМЕТЫ И НАХОДКИ", 11, UI.MUTED))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	left.add_child(grid)
	var keys: Array = state.inventory.keys()
	keys.sort()
	for index in range(maxi(15, keys.size())):
		var id := str(keys[index]) if index < keys.size() else ""
		var b := UI.button("", true)
		b.custom_minimum_size = Vector2(44, 44)
		b.disabled = id.is_empty()
		b.tooltip_text = "Пустая ячейка" if id.is_empty() else Catalog.ITEMS[id].name
		grid.add_child(b)
		if id.is_empty():
			continue
		var icon := Icon.new()
		icon.kind = id
		b.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var count := UI.label(str(state.inventory[id]), 11, UI.GOLD)
		count.position = Vector2(31, 29)
		count.size = Vector2(12, 15)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		b.add_child(count)
		b.pressed.connect(show_item.bind(id))
		b.focus_entered.connect(show_item.bind(id))
		b.mouse_entered.connect(show_item.bind(id))
		item_buttons[id] = b
	left.add_child(UI.label("Занято: %d\nВыбери предмет, чтобы рассмотреть." % keys.size(), 11, UI.MUTED))
	make_details(row)
	if not keys.is_empty():
		show_item(selected_item if selected_item in keys else str(keys[0]))
	else:
		details.add_child(UI.label("Сумка пока пуста", 18, UI.GOLD))
		info = UI.label("Возьми поручение у Миры. После работы здесь появятся документы и посылки, которые нужно передать.", 13)
		details.add_child(info)
		details.add_child(UI.label("Деньги хранятся в кошельке — сумма указана вверху.", 11, UI.MUTED))

func show_item(id: String) -> void:
	if not is_instance_valid(details) or id not in Catalog.ITEMS:
		return
	selected_item = id
	UI.clear(details)
	details.add_child(UI.label("ОРУЖИЕ" if id == "simple_dagger" else ("НАХОДКА" if id == "watch_notes" else "ПРЕДМЕТ ПОРУЧЕНИЯ"), 11, UI.MUTED))
	details.add_child(UI.label(Catalog.ITEMS[id].name, 18, UI.GOLD))
	info = UI.label(Catalog.ITEMS[id].description)
	details.add_child(info)
	details.add_child(UI.label("Количество: %d" % int(state.inventory.get(id, 0)), 12, UI.MUTED))
	if id == "simple_dagger":
		details.add_child(UI.label("Базовый урон: %d" % state.Weapons.DAGGER.base_damage,12,UI.GOLD))
		var equip := UI.button("Снять оружие" if state.equipped_weapon == id else "Экипировать",true)
		equip.pressed.connect(toggle_weapon)
		details.add_child(equip)
		UI.trap_focus.call_deferred(panel)
	for key in item_buttons:
		item_buttons[key].add_theme_stylebox_override("normal", UI.panel_style("405b51" if key == id else "30494a", UI.GOLD if key == id else "50625a", 6))

func build_hero() -> void:
	var equipment := HBoxContainer.new()
	body.add_child(equipment)
	var slot := UI.label(("Кинжал" if state.equipped_weapon == "simple_dagger" else "Без оружия") + " · Урон: %d" % state.weapon_base_damage(), 13, UI.GOLD)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment.add_child(slot)
	if state.inventory.has("simple_dagger"):
		var equip := UI.button("Снять" if state.equipped_weapon != "" else "Экипировать кинжал",true)
		equip.pressed.connect(toggle_weapon)
		equipment.add_child(equip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	body.add_child(row)
	var portrait_box := UI.box()
	portrait_box.custom_minimum_size.x = 156
	row.add_child(portrait_box)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 5)
	portrait_box.add_child(left)
	left.add_child(UI.label("Филипп", 18, UI.GOLD))
	left.add_child(UI.label("Уровень 1 · Ранг F", 12))
	var canvas := Control.new()
	canvas.custom_minimum_size.y = 76
	left.add_child(canvas)
	var portrait := Portrait.new()
	portrait.position = Vector2(64, 70)
	portrait.scale = Vector2(2, 2)
	canvas.add_child(portrait)
	left.add_child(UI.label("Игра: " + state.format_play_time(state.play_seconds), 11, UI.MUTED))
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	row.add_child(right)
	right.add_child(UI.label("ХАРАКТЕРИСТИКИ", 11, UI.MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	right.add_child(grid)
	for key in state.BASE_STATS:
		var card := UI.box(UI.PANEL, 5)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var pair := HBoxContainer.new()
		card.add_child(pair)
		var name_label := UI.label(key, 12)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pair.add_child(name_label)
		var value := UI.label(str(state.attributes.get(key, 0)), 15, UI.GOLD)
		value.custom_minimum_size.x = 20
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pair.add_child(value)

func toggle_weapon() -> void:
	state.set_equipped_weapon("simple_dagger" if state.equipped_weapon == "" else "")
	close_button.grab_focus()

func build_journal() -> void:
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 6)
	body.add_child(filters)
	var entries: Array = state.journal_entries()
	for completed in [false, true]:
		var count := 0
		for entry in entries:
			if entry.completed == completed: count += 1
		var b := UI.button(("Завершённые" if completed else "Активные") + " · %d" % count, true)
		b.pressed.connect(set_filter.bind(completed))
		if completed == completed_filter:
			b.add_theme_stylebox_override("normal", UI.panel_style("496050", UI.GOLD, 6))
		filters.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size.y = 174
	body.add_child(row)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 210
	list.add_theme_constant_override("separation", 6)
	row.add_child(list)
	var visible_entries: Array = []
	for entry in entries:
		if entry.completed != completed_filter: continue
		visible_entries.append(entry)
		var b := UI.button(entry.title)
		b.custom_minimum_size.y = 46
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(show_quest.bind(entry))
		b.focus_entered.connect(show_quest.bind(entry))
		list.add_child(b)
		quest_buttons[entry.id] = b
	make_details(row, true)
	if visible_entries.is_empty():
		details.add_child(UI.label("Пока нет завершённых заданий" if completed_filter else "Нет активных заданий", 18, UI.GOLD))
		details.add_child(UI.label("Мира у стойки гильдии предлагает работу. Принятые поручения появятся здесь."))
		return
	var selected: Dictionary = visible_entries[0]
	for entry in visible_entries:
		if entry.id == selected_quest or (selected_quest.is_empty() and entry.id == state.current_tracked_quest()): selected = entry
	show_quest(selected)

func set_filter(completed: bool) -> void:
	completed_filter = completed
	selected_quest = ""
	refresh()
	(body.get_child(0).get_child(1 if completed else 0) as Button).grab_focus()

func show_quest(entry: Dictionary) -> void:
	if not is_instance_valid(details): return
	selected_quest = entry.id
	detail_scroll.scroll_vertical = 0
	UI.clear(details)
	UI.clear(quest_actions)
	details.add_child(UI.label(entry.status.to_upper(), 11, UI.MUTED))
	details.add_child(UI.label(entry.title, 17, UI.GOLD))
	details.add_child(UI.label(entry.objective, 13))
	details.add_child(UI.label(entry.details, 11, UI.MUTED))
	quest_actions.add_child(UI.label(("Получено: " if entry.completed else "Награда: ") + "%d медяков" % entry.reward, 12, UI.GOLD))
	if not entry.completed:
		var tracked: bool = state.current_tracked_quest() == entry.id
		var b := UI.button("Отслеживается" if tracked else "Отслеживать на экране", true)
		b.disabled = tracked
		b.pressed.connect(state.track_quest.bind(entry.id))
		quest_actions.add_child(b)
	for key in quest_buttons:
		quest_buttons[key].add_theme_stylebox_override("normal", UI.panel_style("405b51" if key == entry.id else "30494a", UI.GOLD if key == entry.id else "50625a", 6))
	UI.trap_focus.call_deferred(panel)

func build_quests() -> void:
	body.add_child(UI.label("Выбери работу. Поручения выдаёт Мира у стойки." if mode == "work" else "Можно взять несколько поручений. Каждое оплачивается отдельно.", 13, UI.MUTED))
	for id in Catalog.QUESTS:
		var definition: Dictionary = Catalog.QUESTS[id]
		var card := UI.box()
		body.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 6)
		card.add_child(column)
		column.add_child(UI.label(definition.title + " · %d медяков" % definition.reward, 16, UI.GOLD))
		var status: String = state.side_quests[id]
		column.add_child(UI.label(definition.offer if mode == "jobs" and status == "available" else state.side_objective(id), 13))
		if mode == "work":
			var b := UI.button(definition.title)
			b.disabled = status != "active"
			b.pressed.connect(request_work.bind(id))
			column.add_child(b)
		elif status == "available":
			var accept := UI.button("Взяться за поручение")
			accept.pressed.connect(state.accept_side_quest.bind(id))
			column.add_child(accept)
		elif status == "ready":
			var claim := UI.button("Показать результат и получить %d медяков" % definition.reward)
			claim.pressed.connect(state.claim_side_reward.bind(id))
			column.add_child(claim)
		elif status == "completed":
			column.add_child(UI.label(definition.ready, 12, UI.MUTED))

func close() -> void:
	if not is_open: return
	is_open = false
	hide()
	closed.emit()

func request_work(id: String) -> void:
	close()
	work_requested.emit(id)

func _input(event: InputEvent) -> void:
	if not is_open or event.is_echo(): return
	if event.is_action_pressed("page_up") or event.is_action_pressed("page_down"):
		var target: ScrollContainer = detail_scroll if mode == "quests" else scroll
		target.scroll_vertical += -64 if event.is_action_pressed("page_up") else 64
		get_viewport().set_input_as_handled()
		return
	if mode not in ["inventory", "hero", "quests"]: return
	if event.is_action_pressed("inventory"):
		if mode == "inventory": close()
		else: switch_tab("inventory")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("journal"):
		if mode == "quests": close()
		else: switch_tab("quests")
		get_viewport().set_input_as_handled()
