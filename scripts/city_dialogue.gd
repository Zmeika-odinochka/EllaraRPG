extends CanvasLayer
signal closed
const UI = preload("res://scripts/ui_theme.gd")
const City = preload("res://scripts/city_catalog.gd")
var state: Node
var is_open := false
var npc_id := ""
var line_index := 0
var panel: PanelContainer
var portrait: Node2D
var speaker: Label
var speech: Label
var offer: PanelContainer
var purse: Label
var status: Label
var buy_button: Button
var next_button: Button
var close_button: Button

func _ready() -> void:
	layer = 23
	state = get_node("/root/GameState")
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	panel = UI.box(UI.DARK,12)
	panel.position = Vector2(14,108)
	panel.custom_minimum_size.x = 612
	panel.resized.connect(func(): panel.position.y = 348-panel.size.y)
	overlay.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	panel.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	column.add_child(row)
	var portrait_box := UI.box(UI.PANEL,0)
	portrait_box.custom_minimum_size = Vector2(64,80)
	row.add_child(portrait_box)
	var canvas := Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_box.add_child(canvas)
	portrait = preload("res://scripts/city_npc_art.gd").new()
	portrait.position = Vector2(32,77)
	portrait.scale = Vector2(2,2)
	canvas.add_child(portrait)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(words)
	speaker = UI.label("",18,UI.GOLD)
	words.add_child(speaker)
	speech = UI.label("",14)
	words.add_child(speech)
	offer = UI.box()
	column.add_child(offer)
	var goods := HBoxContainer.new()
	goods.add_theme_constant_override("separation",12)
	offer.add_child(goods)
	var icon := preload("res://scripts/item_icon.gd").new()
	icon.kind = "simple_dagger"
	icon.custom_minimum_size = Vector2(48,48)
	goods.add_child(icon)
	var item := VBoxContainer.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goods.add_child(item)
	item.add_child(UI.label("Простой кинжал · 24 медяка",16,UI.GOLD))
	purse = UI.label("",12)
	item.add_child(purse)
	status = UI.label("",11,UI.MUTED)
	item.add_child(status)
	buy_button = UI.button("Купить · 24 медяка")
	buy_button.pressed.connect(buy)
	column.add_child(buy_button)
	next_button = UI.button("Продолжить разговор",true)
	next_button.pressed.connect(func(): line_index += 1; refresh())
	column.add_child(next_button)
	close_button = UI.button("До встречи.",true)
	close_button.pressed.connect(close)
	column.add_child(close_button)
	hide()

func open(id: String) -> void:
	if id not in City.NPCS: return
	npc_id = id
	line_index = 0
	is_open = true
	show()
	refresh()
	close_button.grab_focus()

func refresh() -> void:
	speaker.text = City.NPCS[npc_id].name
	speech.text = City.NPCS[npc_id].lines[mini(line_index,City.NPCS[npc_id].lines.size()-1)]
	portrait.profile = npc_id
	portrait.queue_redraw()
	var merchant := npc_id == "smith"
	offer.visible = merchant
	buy_button.visible = merchant
	next_button.visible = line_index+1 < City.NPCS[npc_id].lines.size()
	var owned: bool = state.inventory.has("simple_dagger")
	purse.text = "В кошельке: %d медяков" % state.personal_coins
	buy_button.disabled = owned or state.personal_coins<24
	buy_button.text = "Уже куплено" if owned else "Купить · 24 медяка"
	status.text = "Твой кинжал в сумке." if owned else ("Не хватает %d медяков" % (24-state.personal_coins) if state.personal_coins<24 else "Один клинок в наличии. Можно экипировать после покупки.")
	panel.reset_size.call_deferred()
	UI.trap_focus.call_deferred(panel)
	if next_button.has_focus() and not next_button.visible: close_button.grab_focus()

func buy() -> void:
	if not is_open or npc_id != "smith" or get_tree().paused: return
	if not state.buy_dagger():
		refresh()
		if not buy_button.disabled: status.text = "Покупка не записана. Деньги остались у тебя."
		return
	refresh()
	speech.text = "Держи. Лезвие острое; ножны прилагаются."
	close_button.grab_focus()

func close() -> void:
	if not is_open: return
	is_open = false
	hide()
	closed.emit()
