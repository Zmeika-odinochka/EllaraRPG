extends "res://scripts/world_location.gd"
const Catalog = preload("res://scripts/exploration_catalog.gd")
var gate: StaticBody2D

func configure_location() -> void:
	var outside := scene_file_path == Catalog.ROAD
	location_title = "Окраина · Старая дорога" if outside else "Дозорный пост"
	npc_point = Vector2(-1000, -1000)
	npc_prompt_at = npc_point
	portal_point = Vector2(100, 436) if outside else Vector2(384, 428)
	portal_label = "На площадь" if outside else "На старую дорогу"
	portal_scene = state.SQUARE_SCENE if outside else Catalog.ROAD
	portal_spawn = Vector2(692, 398) if outside else Vector2(560, 212)

func _ready() -> void:
	super._ready()
	state.quest_changed.connect(update_discoveries)
	update_discoveries()

func build_walls() -> void:
	for rect in [Rect2(0, 0, 768, 24), Rect2(0, 0, 24, 480), Rect2(744, 0, 24, 480), Rect2(0, 456, 768, 24)]: add_boundary(rect)
	if scene_file_path == Catalog.ROAD:
		for rect in [Rect2(220, 260, 312, 28), Rect2(588, 260, 136, 28), Rect2(496, 40, 208, 132), Rect2(40, 44, 70, 40), Rect2(60, 92, 54, 10), Rect2(242, 42, 90, 100), Rect2(44, 234, 55, 90), Rect2(654, 352, 66, 72)]: add_boundary(rect)
		gate = StaticBody2D.new()
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(56, 28)
		collider.shape = shape
		gate.add_child(collider)
		gate.position = Vector2(560, 274)
		add_child(gate)
	else:
		for rect in [Rect2(24, 24, 720, 58), Rect2(24, 24, 48, 432), Rect2(696, 24, 48, 432), Rect2(72, 104, 108, 64), Rect2(206, 135, 76, 42), Rect2(530, 96, 142, 52), Rect2(478, 258, 78, 60)]: add_boundary(rect)

func update_discoveries() -> void:
	$Art.discoveries = state.discoveries.duplicate()
	$Art.queue_redraw()
	if is_instance_valid(gate):
		gate.get_child(0).set_deferred("disabled", "shortcut" in state.discoveries)
