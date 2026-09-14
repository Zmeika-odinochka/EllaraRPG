extends "res://scripts/world_location.gd"
const Catalog = preload("res://scripts/exploration_catalog.gd")
const Layout = preload("res://scripts/exploration_layout.gd")
var gate: StaticBody2D
var combat: Node2D

func configure_location() -> void:
	var outside := scene_file_path == Catalog.ROAD
	location_title = "Окраина · Старая дорога" if outside else "Дозорный пост"
	npc_point = Vector2(-1000, -1000)
	npc_prompt_at = npc_point
	portal_point = Vector2(100, 436) if outside else Vector2(384, 428)
	portal_label = "К Южным воротам" if outside else "На старую дорогу"
	portal_scene = state.City.GATES if outside else Catalog.ROAD
	portal_spawn = Vector2(384, 400) if outside else Vector2(560, 212)
	var area := Layout.bounds(not outside)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = int(area.position.x)
	camera.limit_top = int(area.position.y)
	camera.limit_right = int(area.end.x)
	camera.limit_bottom = int(area.end.y)
	camera.position = Vector2(0,-24)

func _ready() -> void:
	super._ready()
	state.quest_changed.connect(update_discoveries)
	update_discoveries()
	# Old saves may occupy a newly added wall. Only those positions are relocated.
	player.position = Layout.nearest_safe(player.position, scene_file_path == Catalog.POST, "shortcut" in state.discoveries)
	var canopy = preload("res://scripts/exploration_art.gd").new()
	canopy.interior = scene_file_path == Catalog.POST
	canopy.foreground = true
	canopy.z_index = 3
	add_child(canopy)
	if scene_file_path == Catalog.POST:
		combat = preload("res://scripts/post_combat.gd").new()
		add_child(combat)

func build_walls() -> void:
	var inside := scene_file_path == Catalog.POST
	var area := Layout.bounds(inside)
	# Merge adjacent solid cells into strips. The picture uses the same geometry.
	for y in range(int(area.position.y), int(area.end.y), Layout.CELL):
		var run := -1
		for x in range(int(area.position.x), int(area.end.x) + Layout.CELL, Layout.CELL):
			var solid := x < area.end.x and not Layout.open_ground(Vector2(x+8,y+8), inside)
			if solid and run == -1: run = x
			elif not solid and run != -1:
				add_boundary(Rect2(run,y,x-run,Layout.CELL))
				run = -1
	if not inside:
		gate = StaticBody2D.new()
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(56,28)
		collider.shape = shape
		gate.add_child(collider)
		gate.position = Vector2(560,274)
		add_child(gate)

func update_discoveries() -> void:
	$Art.discoveries = state.discoveries.duplicate()
	$Art.queue_redraw()
	if is_instance_valid(gate): gate.get_child(0).set_deferred("disabled", "shortcut" in state.discoveries)
