extends Node2D
const Catalog = preload("res://scripts/exploration_catalog.gd")
var world: Node
var state: Node
var actions: Array[Dictionary] = []

func _ready() -> void:
	world = get_parent()
	state = get_node("/root/GameState")
	if world.scene_file_path == state.SQUARE_SCENE:
		actions.append({"at": Vector2(714, 398), "label": "На старую дорогу", "scene": Catalog.ROAD, "spawn": Vector2(100, 410)})
		var sign := Label.new()
		sign.text = "Старая дорога →"
		sign.position = Vector2(612, 360)
		sign.add_theme_font_size_override("font_size", 11)
		sign.add_theme_color_override("font_color", Color("fff0cc"))
		sign.add_theme_color_override("font_shadow_color", Color("28352e"))
		sign.add_theme_constant_override("shadow_offset_y", 1)
		add_child(sign)
	elif world.scene_file_path == Catalog.ROAD:
		actions.append({"at": Vector2(560, 190), "label": "В дозорный пост", "scene": Catalog.POST, "spawn": Vector2(384, 392)})
		actions.append({"at": Vector2(560, 302), "label": "Осмотреть калитку", "blocked_gate": true})
	for id in Catalog.DISCOVERIES:
		var definition: Dictionary = Catalog.DISCOVERIES[id]
		if definition.scene == world.scene_file_path:
			actions.append({"at": definition.at, "label": definition.title, "id": id})

func nearest_action() -> Dictionary:
	var selected: Dictionary = {}
	var distance := 34.0
	for action in actions:
		if action.has("blocked_gate") and "shortcut" in state.discoveries: continue
		if action.get("id", "") == "shortcut":
			if "shortcut" in state.discoveries or world.player.position.y >= 260: continue
		var next_distance: float = world.player.position.distance_to(action.at)
		if next_distance < distance:
			distance = next_distance
			selected = action
	return selected

func interact() -> bool:
	var action := nearest_action()
	if action.is_empty(): return false
	if action.has("scene"):
		world.travel_to(action.scene, action.spawn)
		return true
	world.player.set_controls_enabled(false)
	if action.has("blocked_gate"):
		world.inspection.open("Калитка заперта", "Засов с другой стороны. Западная тропа огибает стену и ведёт к посту — оттуда получится подобраться к калитке.")
		return true
	var id: String = action.id
	var definition: Dictionary = Catalog.DISCOVERIES[id]
	if id in state.discoveries:
		world.inspection.open(definition.title, "Сумка пуста. Найденные записки лежат в твоей сумке." if id == "road_cache" else definition.text)
	else:
		world.inspection.open(definition.title, definition.text, definition.action, finish_discovery.bind(id))
	return true

func finish_discovery(id: String) -> void:
	if not world.inspection.is_open: return
	if not state.discover(id): return
	world.inspection.close()
	world.hud.show_toast("Получены записки" if id == "road_cache" else ("Открыт короткий путь" if id == "shortcut" else "Место запомнено"))
