extends Node2D
## One task marker, rebuilt from session state whenever the square is entered.

var step_id: String
var finished: bool = false
var active: bool = false
var label: Label


func _ready() -> void:
	label = Label.new()
	label.position = Vector2(-78, -55)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_stylebox_override("normal", preload("res://scripts/quest_dialogue.gd").panel_style("253c39", "d1b777", 5))
	label.z_index = 12
	label.hide()
	add_child(label)


func update_status(is_finished: bool, is_active: bool, highlighted: bool, title: String) -> void:
	finished = is_finished
	active = is_active
	visible = active or finished
	label.visible = highlighted and active and not finished
	label.text = "E · " + title
	queue_redraw()


func _draw() -> void:
	# Keep the marker beside the player, clear of the face and walking sprite.
	draw_set_transform(Vector2(-20, 0))
	draw_rect(Rect2(-7, -19, 14, 14), Color("263e37"))
	draw_rect(Rect2(-7, -19, 14, 14), Color("d1b777"), false, 1)
	if finished:
		draw_line(Vector2(-4, -12), Vector2(-1, -9), Color("a5c78a"), 2)
		draw_line(Vector2(-1, -9), Vector2(4, -15), Color("a5c78a"), 2)
	else:
		draw_rect(Rect2(-1, -16, 2, 6), Color("f0d896"))
		draw_rect(Rect2(-1, -9, 2, 2), Color("f0d896"))
