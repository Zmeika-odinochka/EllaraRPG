extends Node2D

const Furniture = preload("res://scripts/furniture.gd")
const Dialogue = preload("res://scripts/quest_dialogue.gd")
const INTERACTION_POINT := Vector2(384, 209)
const INTERACTION_RADIUS: float = 38.0

@onready var player: CharacterBody2D = $Actors/Player
@onready var actors: Node2D = $Actors
var dialogue: CanvasLayer
var prompt: Label
var near_mira: bool = false


func _ready() -> void:
	configure_input()
	build_furniture()
	build_walls()
	build_hud()
	dialogue = Dialogue.new()
	add_child(dialogue)
	dialogue.closed.connect(_on_dialogue_closed)


func configure_input() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E],
		"close_dialogue": [KEY_ESCAPE],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)


func build_furniture() -> void:
	add_furniture("counter", Vector2(384, 186), Rect2(-88, -25, 176, 25))
	add_furniture("board", Vector2(650, 139), Rect2(-35, -12, 70, 12))
	add_furniture("shelf", Vector2(100, 147), Rect2(-35, -18, 70, 18))
	for at in [Vector2(175, 279), Vector2(591, 326)]:
		add_furniture("table", at, Rect2(-45, -32, 90, 32))
		add_furniture("bench", at + Vector2(0, 28), Rect2(-34, -10, 68, 10))
		add_furniture("bench", at + Vector2(0, -57), Rect2(-34, -10, 68, 10))
	for at in [Vector2(57, 171), Vector2(711, 165), Vector2(61, 415)]:
		add_furniture("plant", at, Rect2(-11, -15, 22, 15))
	for at in [Vector2(691, 411), Vector2(723, 411)]:
		add_furniture("barrel", at, Rect2(-13, -19, 26, 19))


func add_furniture(kind: String, at: Vector2, footprint: Rect2) -> void:
	var item := Furniture.new()
	item.name = kind.capitalize()
	item.setup(kind, at, footprint)
	actors.add_child(item)


func build_walls() -> void:
	for boundary in [Rect2(16, 96, 12, 364), Rect2(740, 96, 12, 364), Rect2(16, 88, 736, 18), Rect2(16, 448, 736, 12)]:
		var wall := StaticBody2D.new()
		var shape := RectangleShape2D.new()
		shape.size = boundary.size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		wall.position = boundary.get_center()
		wall.add_child(collision)
		add_child(wall)
	# Mira occupies space behind reception like the rest of the room's objects.
	var mira_body := StaticBody2D.new()
	var mira_shape := RectangleShape2D.new()
	mira_shape.size = Vector2(14, 10)
	var mira_collision := CollisionShape2D.new()
	mira_collision.shape = mira_shape
	mira_body.position = $Actors/Mira.position - Vector2(0, 5)
	mira_body.add_child(mira_collision)
	add_child(mira_body)


func build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var header := PanelContainer.new()
	header.position = Vector2(12, 12)
	header.add_theme_stylebox_override("panel", Dialogue.panel_style("253c39", "a98d59", 10))
	layer.add_child(header)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	header.add_child(titles)
	var title := Label.new()
	title.text = "ЭЛЛАРА"
	title.add_theme_color_override("font_color", Color("edcf91"))
	title.add_theme_font_size_override("font_size", 15)
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Эльгард · Гильдия"
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color("c8d0b7"))
	titles.add_child(subtitle)
	var help := Label.new()
	help.text = "WASD / стрелки — ходить     E — разговор"
	help.position = Vector2(14, 374)
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color("f3dfb5"))
	help.add_theme_color_override("font_shadow_color", Color("292c2b"))
	help.add_theme_constant_override("shadow_offset_x", 1)
	help.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(help)
	var badge := Label.new()
	badge.text = "ПРОТОТИП  /  01"
	badge.position = Vector2(513, 16)
	badge.add_theme_font_size_override("font_size", 11)
	badge.modulate = Color("d3c19c")
	layer.add_child(badge)
	prompt = Label.new()
	prompt.name = "MiraPrompt"
	prompt.text = "E  ·  Мира"
	prompt.position = Vector2(340, 78)
	prompt.z_index = 10
	prompt.add_theme_font_size_override("font_size", 12)
	prompt.add_theme_color_override("font_color", Color("fff0cc"))
	prompt.add_theme_stylebox_override("normal", Dialogue.panel_style("253c39", "b79c69", 5))
	add_child(prompt)


func _process(_delta: float) -> void:
	near_mira = player.position.distance_to(INTERACTION_POINT) <= INTERACTION_RADIUS and player.position.y >= 190
	prompt.visible = near_mira and not dialogue.is_open


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		if near_mira and not dialogue.is_open:
			player.set_controls_enabled(false)
			dialogue.open()
			get_viewport().set_input_as_handled()


func _on_dialogue_closed() -> void:
	player.set_controls_enabled(true)
