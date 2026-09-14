extends CanvasLayer
## Work requires deliberate answers; time alone never grants completion.
signal finished(success: bool)
const UI = preload("res://scripts/ui_theme.gd")
var is_open := false
var activity := ""
var step := 0
var cursor := 0.0
var direction := 1.0
var sequence: Array = []
var column: VBoxContainer
var title: Label
var instruction: Label
var prompt: Label
var feedback: Label
var choices: HBoxContainer
var track: Control
var marker: ColorRect
var answer_buttons: Array[Button] = []
var panel: PanelContainer
var cancel_button: Button
var success_zone: ColorRect
var timing_half := 0.1
var archive_help := false

func _ready() -> void:
	layer = 25
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.06, 0.06, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(548, 300)
	panel.add_theme_stylebox_override("panel", UI.panel_style(UI.DARK, "50625a", 18))
	center.add_child(panel)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	title = add_label(22, UI.GOLD)
	instruction = add_label(14, UI.MUTED)
	prompt = add_label(20, UI.PAPER)
	track = Control.new()
	track.custom_minimum_size = Vector2(480, 30)
	column.add_child(track)
	var bar := ColorRect.new()
	bar.color = Color("29463f")
	bar.size = Vector2(480, 30)
	track.add_child(bar)
	var zone := ColorRect.new()
	success_zone = zone
	zone.color = Color("82ab60")
	zone.position = Vector2(192, 0)
	zone.size = Vector2(96, 30)
	track.add_child(zone)
	marker = ColorRect.new()
	marker.color = Color("ffe9ac")
	marker.size = Vector2(4, 30)
	track.add_child(marker)
	choices = HBoxContainer.new()
	choices.add_theme_constant_override("separation", 8)
	column.add_child(choices)
	for index in range(3):
		var b := make_button("")
		b.pressed.connect(answer.bind(index))
		choices.add_child(b)
		answer_buttons.append(b)
	feedback = add_label(13, UI.MUTED)
	var cancel := make_button("Отменить работу · Q")
	cancel_button = cancel
	cancel.pressed.connect(cancel_game)
	column.add_child(cancel)
	hide()

func add_label(size: int, color: String) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(color))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(label)
	return label

func make_button(text: String) -> Button:
	var b := UI.button(text)
	b.custom_minimum_size.y = 36
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b

func open_game(id: String) -> void:
	var state := get_node("/root/GameState")
	timing_half = state.Progress.canopy_half(int(state.attributes.get("Координация",1)))
	archive_help = int(state.attributes.get("Интеллект",1))>=state.Progress.ARCHIVE_HELP_LEVEL
	success_zone.position.x = (0.5-timing_half)*480
	success_zone.size.x = timing_half*960
	activity = id
	step = 0
	cursor = 0.0
	direction = 1.0
	is_open = true
	feedback.text = "Ошибку можно исправить. Esc — пауза."
	track.visible = id == "canopy"
	var names: Array = []
	match id:
		"planks":
			title.text = "Доски по размеру"
			instruction.text = "Выбери стопку для каждой доски: кнопкой или клавишами 1–3."
			names = ["Короткие", "Средние", "Длинные"]
			sequence = [["Короткая доска  ▰", 0], ["Длинная доска  ▰▰▰", 2], ["Средняя доска  ▰▰", 1], ["Короткая доска  ▰", 0], ["Длинная доска  ▰▰▰", 2]]
		"goods":
			title.text = "Товар на прилавке"
			instruction.text = "Разложи товары по отделам: кнопкой или клавишами 1–3."
			names = ["Продукты", "Ткани", "Инструменты"]
			sequence = [["Яблоки", 0], ["Молоток", 2], ["Льняной рулон", 1], ["Хлеб", 0], ["Клещи", 2]]
		"archive":
			title.text = "Порядок в архиве"
			instruction.text = "Прочти документ и выбери папку: кнопкой или клавишами 1–3."
			names = ["Заказы", "Оплата", "Разрешения"]
			sequence = [["Просьба починить ставни", 0], ["Квитанция: уплачено 4 медяка", 1], ["Допуск к торговле на площади", 2], ["Просьба доставить ткань", 0], ["Подтверждение выплаты рабочему", 1]]
		"parcel":
			title.text = "Сборка пакета"
			instruction.text = "Собери документы по порядку: вложить → перевязать → запечатать."
			names = ["Вложить", "Перевязать", "Запечатать"]
			sequence = [["Положи разрешения в конверт", 0], ["Закрепи конверт бечёвкой", 1], ["Поставь гильдейскую печать", 2]]
		"canopy":
			title.text = "Крепление навеса"
			instruction.text = "Нажми пробел или кнопку, когда бегунок в зелёной зоне. Нужно 3 попадания."
			names = ["Затянуть · Пробел"]
			sequence = [["Крепление 1", 0], ["Крепление 2", 0], ["Крепление 3", 0]]
	if id=="planks" and int(state.attributes.get("Сила",1))>=state.Progress.STRENGTH_BATCH_LEVEL:
		sequence.pop_back()
		instruction.text += " Силы хватает на более крупные связки: всего 4."
	if id=="canopy":
		instruction.text = "Лови зелёную зону: Пробел или кнопка. Три крепления."
		feedback.text = "Координация %d · зона %d%%" % [int(state.attributes.get("Координация",1)),roundi(timing_half*200)]
	for index in range(answer_buttons.size()):
		answer_buttons[index].visible = index < names.size()
		if index < names.size():
			answer_buttons[index].text = str(names[index]) if id == "canopy" else "%d · %s" % [index + 1, names[index]]
	update_prompt()
	show()
	UI.trap_focus(panel)
	answer_buttons[0].grab_focus()

func update_prompt() -> void:
	prompt.text = "%d / %d · %s" % [step, sequence.size(), sequence[step][0]]
	if activity=="archive" and archive_help:
		feedback.text = "Пометка на полях: "+["Заказы","Оплата","Разрешения"][int(sequence[step][1])]

func _process(delta: float) -> void:
	if not is_open or activity != "canopy":
		return
	cursor = clampf(cursor + direction * delta * 0.6, 0.0, 1.0)
	if cursor >= 1.0 or cursor <= 0.0:
		direction *= -1.0
	marker.position.x = cursor * 476.0

func answer(index: int) -> void:
	if not is_open or get_tree().paused:
		return
	var correct: bool = absf(cursor-0.5)<=timing_half if activity == "canopy" else index == int(sequence[step][1])
	if not correct:
		feedback.text = "Попробуй ещё раз. Верные ответы повторять не нужно."
		return
	step += 1
	if step == sequence.size():
		is_open = false
		hide()
		finished.emit(true)
		return
	cursor = 0.0
	direction = 1.0
	feedback.text = "Верно! Продолжай."
	update_prompt()

func cancel_game() -> void:
	if not is_open:
		return
	is_open = false
	hide()
	finished.emit(false)

func _input(event: InputEvent) -> void:
	if not is_open or event.is_echo():
		return
	if event.is_action_pressed("cancel_work"):
		cancel_game()
		get_viewport().set_input_as_handled()
	elif activity == "canopy" and event.is_action_pressed("work_timing"):
		answer(0)
		get_viewport().set_input_as_handled()
	elif activity != "canopy":
		for index in range(3):
			if event.is_action_pressed("work_choice_%d" % (index + 1)):
				answer(index)
				get_viewport().set_input_as_handled()
				return
