extends Node2D

const Dialogue = preload("res://scripts/quest_dialogue.gd")
const PauseMenu = preload("res://scripts/pause_menu.gd")
@onready var player: CharacterBody2D = $Actors/Player
@onready var actors: Node2D = $Actors
var state: Node
var dialogue: CanvasLayer
var prompt: Label
var portal_prompt: Label
var objective_label: Label
var wallet_label: Label
var activity_label: Label
var pause_menu: CanvasLayer
var busy: bool = false
var near_npc: bool = false
var near_portal: bool = false
var transitioning: bool = false
var location_title: String
var npc_mode: String
var npc_name: String
var npc_point: Vector2
var npc_prompt_at: Vector2
var portal_point: Vector2
var portal_label: String
var portal_scene: String
var portal_spawn: Vector2


func _ready() -> void:
	state = get_node("/root/GameState")
	configure_location()
	if state.pending_spawn.is_finite():
		player.position = state.pending_spawn
		state.pending_spawn = Vector2.INF
	build_furniture()
	build_walls()
	build_hud()
	dialogue = Dialogue.new()
	add_child(dialogue)
	dialogue.closed.connect(_on_dialogue_closed)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	state.quest_changed.connect(refresh_objective)
	if state.transition_autosave_pending:
		state.transition_autosave_pending = false
		state.autosave("transition")


func configure_location() -> void:
	pass


func build_furniture() -> void:
	pass


func build_walls() -> void:
	pass


func add_boundary(boundary: Rect2) -> void:
	var wall := StaticBody2D.new()
	var shape := RectangleShape2D.new()
	shape.size = boundary.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	wall.position = boundary.get_center()
	wall.add_child(collision)
	add_child(wall)


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
	subtitle.text = location_title
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color("c8d0b7"))
	titles.add_child(subtitle)
	var help := Label.new()
	help.text = "WASD / стрелки — ходить   E — действие   J — журнал   Esc — пауза"
	help.position = Vector2(14, 374)
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color("f3dfb5"))
	help.add_theme_color_override("font_shadow_color", Color("292c2b"))
	help.add_theme_constant_override("shadow_offset_x", 1)
	help.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(help)
	var badge := Label.new()
	badge.text = "ПРОТОТИП  /  03"
	badge.position = Vector2(513, 16)
	badge.add_theme_font_size_override("font_size", 11)
	badge.modulate = Color("d3c19c")
	layer.add_child(badge)
	wallet_label = Label.new()
	wallet_label.position = Vector2(482, 37)
	wallet_label.add_theme_font_size_override("font_size", 12)
	wallet_label.add_theme_color_override("font_color", Color("f3dfb5"))
	wallet_label.add_theme_stylebox_override("normal", Dialogue.panel_style("253c39", "a98d59", 4))
	layer.add_child(wallet_label)
	prompt = Label.new()
	prompt.name = "NpcPrompt"
	prompt.text = "E · " + npc_name
	prompt.position = npc_prompt_at
	prompt.z_index = 10
	prompt.add_theme_font_size_override("font_size", 12)
	prompt.add_theme_color_override("font_color", Color("fff0cc"))
	prompt.add_theme_stylebox_override("normal", Dialogue.panel_style("253c39", "b79c69", 5))
	add_child(prompt)


	portal_prompt = Label.new()
	portal_prompt.text = "E · " + portal_label
	portal_prompt.position = portal_point + Vector2(-48, -48)
	portal_prompt.z_index = 10
	portal_prompt.add_theme_font_size_override("font_size", 12)
	portal_prompt.add_theme_stylebox_override("normal", Dialogue.panel_style("253c39", "b79c69", 5))
	add_child(portal_prompt)
	objective_label = Label.new()
	objective_label.position = Vector2(14, 345)
	objective_label.add_theme_font_size_override("font_size", 12)
	objective_label.add_theme_color_override("font_color", Color("fff0cc"))
	objective_label.add_theme_stylebox_override("normal", Dialogue.panel_style("253c39", "a98d59", 4))
	layer.add_child(objective_label)
	activity_label = Label.new()
	activity_label.position = Vector2(14, 316)
	activity_label.add_theme_font_size_override("font_size", 12)
	activity_label.add_theme_stylebox_override("normal", Dialogue.panel_style("253c39", "a98d59", 4))
	activity_label.hide()
	layer.add_child(activity_label)
	refresh_objective()


func refresh_objective() -> void:
	objective_label.text = "J · " + state.objective()
	wallet_label.text = "Медяки: %d" % state.personal_coins


func npc_is_reachable() -> bool:
	return player.position.distance_to(npc_point) <= 38.0


func _process(_delta: float) -> void:
	near_npc = npc_is_reachable()
	near_portal = player.position.distance_to(portal_point) <= 27.0
	prompt.visible = near_npc and not dialogue.is_open and not transitioning and not busy
	portal_prompt.visible = near_portal and not dialogue.is_open and not transitioning and not busy


func _unhandled_input(event: InputEvent) -> void:
	if transitioning or event.is_echo() or dialogue.is_open or busy:
		return
	if event.is_action_pressed("journal"):
		player.set_controls_enabled(false)
		dialogue.open("journal")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if near_npc:
			player.set_controls_enabled(false)
			dialogue.open(npc_mode)
			get_viewport().set_input_as_handled()
		elif near_portal:
			get_viewport().set_input_as_handled()
			travel()


func travel() -> void:
	if transitioning or dialogue.is_open or busy:
		return
	transitioning = true
	player.set_controls_enabled(false)
	state.pending_spawn = portal_spawn
	state.transition_autosave_pending = true
	var result: int = get_tree().change_scene_to_file(portal_scene)
	if result != OK:
		state.pending_spawn = Vector2.INF
		state.transition_autosave_pending = false
		transitioning = false
		player.set_controls_enabled(true)
		objective_label.text = "Не удалось открыть локацию. Попробуйте ещё раз."
		push_error("Scene transition failed: " + error_string(result))


func _on_dialogue_closed() -> void:
	player.set_controls_enabled(true)


func can_manual_save() -> bool:
	return not transitioning and not busy and not dialogue.is_open
