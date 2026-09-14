extends "res://scripts/world_location.gd"

const Furniture = preload("res://scripts/furniture.gd")


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
