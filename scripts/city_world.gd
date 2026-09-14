extends "res://scripts/world_location.gd"
const City = preload("res://scripts/city_catalog.gd")
const Layout = preload("res://scripts/city_layout.gd")

func configure_location() -> void:
	location_title = "Эльгард · " + ("Оружейная" if scene_file_path == City.ARMORY else City.TITLES[scene_file_path])
	npc_point = Vector2(-1000,-1000)
	npc_prompt_at = npc_point
	portal_point = npc_point
	portal_label = ""
	var art := preload("res://scripts/city_art.gd").new()
	art.district = scene_file_path
	add_child(art)
	move_child(art,0)

func build_walls() -> void:
	for rect in Layout.obstacles(scene_file_path): add_boundary(rect)
	for rect in [Rect2(0,0,768,24),Rect2(0,0,24,480),Rect2(744,0,24,480),Rect2(0,456,768,24)]: add_boundary(rect)
