extends CanvasLayer

signal closed
var is_open: bool = false
var overlay: Control
var close_button: Button


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


func text_label(text: String, size: int, color: String, wrap: bool = true) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(color))
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _ready() -> void:
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
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	column.add_child(text_label("МИРА  /  ГИЛЬДИЯ ЭЛЬГАРДА", 12, "647052"))
	column.add_child(text_label("Подготовка ярмарки", 22, "3c3930"))
	column.add_child(text_label("«На площади нужны руки. Вот условия поручения — ознакомься».", 14, "65533f"))
	var line := HSeparator.new()
	line.add_theme_color_override("separator", Color("a58b5d"))
	column.add_child(line)
	column.add_child(text_label("Помочь с подготовкой центральной площади. Объём работ на месте определяет Корвин, распорядитель ярмарки.", 14, "463e33"))
	column.add_child(text_label("Награда: 18 медяков группе.\nСрок: до начала завтрашней ярмарки.\nРасчёт: в гильдии после подписи Корвина.", 14, "463e33"))
	column.add_child(text_label("Просмотр поручения", 11, "837451"))
	close_button = Button.new()
	close_button.text = "Закрыть  ·  Esc"
	close_button.custom_minimum_size.y = 34
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.add_theme_font_size_override("font_size", 14)
	close_button.add_theme_color_override("font_color", Color("f1dfb1"))
	close_button.add_theme_color_override("font_hover_color", Color("ffffff"))
	close_button.add_theme_color_override("font_focus_color", Color("ffffff"))
	close_button.add_theme_stylebox_override("normal", panel_style("35554b", "254038", 6))
	close_button.add_theme_stylebox_override("hover", panel_style("496e59", "d1b777", 6))
	close_button.add_theme_stylebox_override("pressed", panel_style("263f37", "d1b777", 6))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = Color("d1b777")
	focus.set_border_width_all(2)
	close_button.add_theme_stylebox_override("focus", focus)
	column.add_child(close_button)
	close_button.pressed.connect(close)
	overlay.hide()


func open() -> void:
	if is_open:
		return
	is_open = true
	overlay.show()
	close_button.grab_focus()


func close() -> void:
	if not is_open:
		return
	is_open = false
	overlay.hide()
	close_button.release_focus()
	closed.emit()


func _input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("close_dialogue") and not event.is_echo():
		close()
		get_viewport().set_input_as_handled()
