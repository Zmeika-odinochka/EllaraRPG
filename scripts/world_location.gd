extends Node2D

const Dialogue = preload("res://scripts/quest_dialogue.gd")
const UI = preload("res://scripts/ui_theme.gd")
const PauseMenu = preload("res://scripts/pause_menu.gd")
const CharacterPanel = preload("res://scripts/character_panel.gd")
const ActivityGame = preload("res://scripts/activity_game.gd")
var character_panel: CanvasLayer
var activity_game: CanvasLayer
var current_work := ""
var work_prompt: Label
@onready var player: CharacterBody2D = $Actors/Player
@onready var actors: Node2D = $Actors
var state: Node
var dialogue: CanvasLayer
var prompt: Label
var portal_prompt: Label
var objective_label: Label
var activity_label: Label
var hud: CanvasLayer
var pause_menu: CanvasLayer
var inspection: CanvasLayer
var exploration: Node2D
var city: Node2D
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
	character_panel = CharacterPanel.new()
	add_child(character_panel)
	character_panel.closed.connect(_on_dialogue_closed)
	character_panel.work_requested.connect(begin_work)
	activity_game = ActivityGame.new()
	add_child(activity_game)
	activity_game.finished.connect(_on_activity_finished)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	inspection = preload("res://scripts/inspection_panel.gd").new()
	add_child(inspection)
	inspection.closed.connect(_on_dialogue_closed)
	exploration = preload("res://scripts/exploration_interactions.gd").new()
	add_child(exploration)
	city = preload("res://scripts/city_interactions.gd").new()
	add_child(city)
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
	hud = preload("res://scripts/game_hud.gd").new()
	add_child(hud)
	objective_label = hud.objective_label
	activity_label = hud.activity_label
	prompt = make_prompt("E · " + npc_name, npc_prompt_at)
	prompt.name = "NpcPrompt"
	work_prompt = make_prompt("E · Рабочее место", Vector2(584, 150))
	work_prompt.hide()
	portal_prompt = make_prompt("E · " + portal_label, portal_point + Vector2(-48, -48))


func make_prompt(text: String, at: Vector2) -> Label:
	var result := Label.new()
	result.text = text
	result.position = at
	result.z_index = 10
	result.add_theme_font_size_override("font_size", 12)
	result.add_theme_color_override("font_color", Color("fff0cc"))
	result.add_theme_stylebox_override("normal", UI.panel_style("253c39", "b79c69", 5))
	add_child(result)
	return result


func refresh_objective() -> void:
	hud.refresh()

func npc_is_reachable() -> bool:
	return player.position.distance_to(npc_point) <= 38.0


func _process(_delta: float) -> void:
	near_npc = npc_is_reachable()
	near_portal = player.position.distance_to(portal_point) <= 27.0
	var free: bool = can_manual_save()
	prompt.visible = near_npc and free
	portal_prompt.visible = near_portal and free
	work_prompt.visible = near_guild_work() and free


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not can_manual_save():
		return
	if event.is_action_pressed("inventory"):
		open_character_panel("inventory")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("journal"):
		open_character_panel("quests")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact()


func interaction_text() -> String:
	if is_instance_valid(city):
		var action: Dictionary = city.nearest_action()
		if not action.is_empty(): return action.label
	if is_instance_valid(exploration):
		var action: Dictionary = exploration.nearest_action()
		if not action.is_empty(): return action.label
	if near_guild_work(): return "Рабочее место"
	if near_npc: return npc_name
	if near_portal: return portal_label
	return ""


func interact() -> void:
	if not can_manual_save() or get_tree().paused: return
	if city.interact(): return
	if exploration.interact(): return
	if near_guild_work(): open_character_panel("work")
	elif near_npc:
		player.set_controls_enabled(false)
		dialogue.open(npc_mode)
	elif near_portal: travel()


func travel() -> void:
	travel_to(portal_scene, portal_spawn)

func travel_to(destination: String, spawn: Vector2) -> void:
	if not can_manual_save() or get_tree().paused: return
	transitioning = true
	player.set_controls_enabled(false)
	state.pending_spawn = spawn
	state.transition_autosave_pending = true
	var result: int = get_tree().change_scene_to_file(destination)
	if result != OK:
		state.pending_spawn = Vector2.INF
		state.transition_autosave_pending = false
		transitioning = false
		player.set_controls_enabled(true)
		hud.show_toast("Не удалось открыть локацию. Попробуйте ещё раз.", 8.0)
		push_error("Scene transition failed: " + error_string(result))


func _on_dialogue_closed() -> void:
	player.set_controls_enabled(true)

func near_guild_work() -> bool:
	return scene_file_path == state.GUILD_SCENE and player.position.distance_to(Vector2(650, 174)) < 36.0

func open_character_panel(context: String) -> void:
	player.set_controls_enabled(false)
	character_panel.open(context)

func begin_work(id: String) -> void:
	if busy or transitioning or dialogue.is_open or character_panel.is_open:
		return
	if id in state.Catalog.QUESTS and state.side_quests[id] != "active":
		return
	current_work = id
	busy = true
	player.set_controls_enabled(false)
	activity_game.open_game(id)

func _on_activity_finished(success: bool) -> void:
	if success:
		if current_work in state.Catalog.QUESTS:
			state.finish_side_work(current_work)
		else:
			state.finish_work(current_work)
	busy = false
	current_work = ""
	player.set_controls_enabled(true)


func can_manual_save() -> bool:
	return not transitioning and not busy and not dialogue.is_open and not character_panel.is_open and (not is_instance_valid(inspection) or not inspection.is_open) and (not is_instance_valid(city) or not city.conversation.is_open)
