extends RefCounted
## Shared visual vocabulary. Sizes are in the 640×360 logical viewport.
const PAPER := "eddfbc"
const INK := "252f31"
const MUTED := "acbbae"
const GOLD := "e2bd75"
const DARK := "1c2d30"
const PANEL := "293e40"

static func panel_style(background: String, border: String, margin: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(background)
	style.border_color = Color(border)
	style.set_border_width_all(1)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

static func button(text: String, small: bool = false) -> Button:
	var b := Button.new()
	b.pressed.connect(func():
		var audio := b.get_node_or_null("/root/Soundscape")
		if audio: audio.play("ui"))
	b.text = text
	b.custom_minimum_size.y = 27 if small else 32
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 12 if small else 13)
	b.add_theme_color_override("font_color", Color(PAPER))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color(GOLD))
	b.add_theme_color_override("font_disabled_color", Color("82908a"))
	b.add_theme_stylebox_override("normal", panel_style("30494a", "50625a", 6))
	b.add_theme_stylebox_override("hover", panel_style("405d58", GOLD, 6))
	b.add_theme_stylebox_override("pressed", panel_style("17292c", GOLD, 6))
	b.add_theme_stylebox_override("disabled", panel_style("263637", "374b49", 6))
	var focus := panel_style("00000000", GOLD, 0)
	focus.set_border_width_all(2)
	b.add_theme_stylebox_override("focus", focus)
	return b

static func label(text: String, font_size: int = 13, color: String = PAPER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(color))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func box(background: String = PANEL, margin: int = 10) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(background, "50625a", margin))
	return p

static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

static func focus_first(node: Node) -> void:
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree() and not child.disabled:
			child.grab_focus()
			return

static func focusable_buttons(node: Node) -> Array[Control]:
	var result: Array[Control] = []
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree() and not child.disabled:
			result.append(child)
		result.append_array(focusable_buttons(child))
	return result

static func trap_focus(node: Node) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree(): return
	var buttons := focusable_buttons(node)
	for index in range(buttons.size()):
		buttons[index].focus_next = buttons[index].get_path_to(buttons[(index + 1) % buttons.size()])
		buttons[index].focus_previous = buttons[index].get_path_to(buttons[(index - 1 + buttons.size()) % buttons.size()])
		# Explicit neighbours prevent arrow keys from reaching controls behind a modal.
		buttons[index].focus_neighbor_left = buttons[index].focus_previous
		buttons[index].focus_neighbor_top = buttons[index].focus_previous
		buttons[index].focus_neighbor_right = buttons[index].focus_next
		buttons[index].focus_neighbor_bottom = buttons[index].focus_next
