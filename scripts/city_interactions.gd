extends Node2D
const City = preload("res://scripts/city_catalog.gd")
var world: Node
var actions: Array[Dictionary] = []
var conversation: CanvasLayer

func _ready() -> void:
	world = get_parent()
	actions = City.actions(world.scene_file_path)
	conversation = preload("res://scripts/city_dialogue.gd").new()
	add_child(conversation)
	conversation.closed.connect(world._on_dialogue_closed)
	for action in actions:
		if action.has("npc"):
			var body := StaticBody2D.new()
			body.position = action.actor_at
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(12,8)
			shape.shape = rect
			shape.position.y = -4
			body.add_child(shape)
			var art := preload("res://scripts/city_npc_art.gd").new()
			art.profile = action.npc
			art.seated = world.scene_file_path == City.GUILD
			if action.npc == "astra": art.facing = Vector2.UP
			body.add_child(art)
			world.actors.add_child(body)
		elif action.has("scene"):
			var sign := Label.new()
			sign.text = action.label
			sign.position = Vector2(clampf(action.at.x-70,26,550),action.at.y-26)
			sign.add_theme_font_size_override("font_size",11)
			sign.add_theme_color_override("font_color",Color("f0ddb4"))
			sign.add_theme_color_override("font_shadow_color",Color("33463a"))
			sign.add_theme_constant_override("shadow_offset_y",1)
			add_child(sign)

func nearest_action() -> Dictionary:
	var nearest: Dictionary = {}
	var distance := 34.0
	for action in actions:
		var next: float = world.player.position.distance_to(action.at)
		if next < distance:
			distance = next
			nearest = action
	return nearest

func interact() -> bool:
	var action := nearest_action()
	if action.is_empty(): return false
	if action.has("scene"):
		world.travel_to(action.scene,action.spawn)
	elif action.has("npc"):
		world.player.set_controls_enabled(false)
		conversation.open(action.npc)
	else:
		world.player.set_controls_enabled(false)
		world.inspection.open(action.label,action.text)
	return true
