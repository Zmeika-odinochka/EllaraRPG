extends "res://scripts/world_location.gd"

const Furniture = preload("res://scripts/furniture.gd")
const WorkSpot = preload("res://scripts/work_spot.gd")
const WORK_DURATION: float = 1.5
const WORK_POSITIONS := {
	"planks": Vector2(574, 415),
	"goods": Vector2(453, 211),
	"canopy": Vector2(653, 211),
}
var work_spots: Dictionary = {}
var selected_step: String = ""
var working_step: String = ""
var work_elapsed: float = 0.0


func _ready() -> void:
	super._ready()
	for step_id in WORK_POSITIONS:
		var spot := WorkSpot.new()
		spot.step_id = step_id
		spot.position = WORK_POSITIONS[step_id]
		spot.z_index = 8
		add_child(spot)
		work_spots[step_id] = spot
	state.quest_changed.connect(update_work_art)
	update_work_art()


func update_work_art() -> void:
	$SquareArt.completed_steps = state.completed_steps.duplicate()
	$SquareArt.queue_redraw()


func _process(delta: float) -> void:
	super._process(delta)
	selected_step = ""
	var active: bool = state.quest_stage == state.QuestStage.MET_CORVIN
	if active and not busy and not dialogue.is_open and not transitioning:
		var closest: float = 32.0
		for step_id in WORK_POSITIONS:
			if step_id in state.completed_steps:
				continue
			var distance: float = player.position.distance_to(WORK_POSITIONS[step_id])
			if distance < closest:
				closest = distance
				selected_step = step_id
	for step_id in work_spots:
		work_spots[step_id].update_status(step_id in state.completed_steps, active, selected_step == step_id, state.WORK_STEPS[step_id])
	if busy:
		work_elapsed += delta
		activity_label.text = "%s · %d%% · Esc — отменить" % [state.WORK_STEPS[working_step], mini(100, int(work_elapsed / WORK_DURATION * 100))]
		if work_elapsed >= WORK_DURATION:
			state.finish_work(working_step)
			stop_work()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if busy:
		if event.is_action_pressed("close_dialogue"):
			stop_work()
			get_viewport().set_input_as_handled()
		return
	if not transitioning and not dialogue.is_open and event.is_action_pressed("interact") and not selected_step.is_empty() and not near_npc and not near_portal:
		working_step = selected_step
		work_elapsed = 0.0
		busy = true
		player.set_controls_enabled(false)
		activity_label.show()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)


func stop_work() -> void:
	busy = false
	working_step = ""
	work_elapsed = 0.0
	activity_label.hide()
	player.set_controls_enabled(true)


func configure_location() -> void:
	location_title = "Эльгард · Центральная площадь"
	npc_mode = "corvin"
	npc_name = "Корвин"
	npc_point = Vector2(526, 273)
	npc_prompt_at = Vector2(484, 196)
	portal_point = Vector2(168, 226)
	portal_label = "В гильдию"
	portal_scene = "res://scenes/guild.tscn"
	portal_spawn = Vector2(384, 398)


func npc_is_reachable() -> bool:
	return super.npc_is_reachable() and player.position.y >= 243


func build_walls() -> void:
	for boundary in [Rect2(0, 0, 768, 24), Rect2(0, 0, 24, 480), Rect2(744, 0, 24, 480), Rect2(0, 456, 768, 24), Rect2(64, 72, 208, 145), Rect2(405, 87, 122, 102), Rect2(576, 87, 122, 102), Rect2(343, 307, 82, 59), Rect2(519, 248, 14, 12)]:
		add_boundary(boundary)


func build_furniture() -> void:
	for at in [Vector2(578, 340), Vector2(610, 340), Vector2(681, 416)]:
		var barrel := Furniture.new()
		barrel.setup("barrel", at, Rect2(-13, -19, 26, 19))
		actors.add_child(barrel)
	for at in [Vector2(91, 237), Vector2(245, 237)]:
		var plant := Furniture.new()
		plant.setup("plant", at, Rect2(-11, -15, 22, 15))
		actors.add_child(plant)
