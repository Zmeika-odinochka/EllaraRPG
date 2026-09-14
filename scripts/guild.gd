extends "res://scripts/world_location.gd"

const Furniture = preload("res://scripts/furniture.gd")


func configure_location() -> void:
	location_title = "Эльгард · Гильдия"
	npc_mode = "mira"
	npc_name = "Мира"
	npc_point = Vector2(384, 209)
	npc_prompt_at = Vector2(340, 78)
	portal_point = Vector2(384, 432)
	portal_label = "На площадь"
	portal_scene = "res://scenes/square.tscn"
	portal_spawn = Vector2(168, 260)


func npc_is_reachable() -> bool:
	return super.npc_is_reachable() and player.position.y >= 190


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
