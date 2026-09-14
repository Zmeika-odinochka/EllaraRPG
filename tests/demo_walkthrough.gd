extends "res://tests/city.gd"
## Graphical end-to-end route: UI and movement input only; no progress/position writes.
const Route = preload("res://scripts/exploration_layout.gd")

func find_button(node: Node, fragment: String) -> Button:
	if node is Button and node.is_visible_in_tree() and not node.disabled and node.text.contains(fragment): return node
	for child in node.get_children():
		var found := find_button(child,fragment)
		if found: return found
	return null

func choose(fragment: String) -> void:
	var button := find_button(current_scene,fragment)
	check(button!=null,"Available reply: "+fragment)
	if button: await click(button)
	await frames(3)

func close_talk() -> void:
	for i in range(3):
		if not game.dialogue.is_open: return
		await click(game.dialogue.close_button)

func enter(at: Vector2, expected: String) -> void:
	await walk_to(at)
	await key_press(KEY_E)
	await frames(8)
	game = current_scene
	check(game.scene_file_path==expected,"Travel to "+expected)

func straight(target: Vector2) -> void:
	for i in range(650):
		var delta: Vector2 = target-game.player.position
		if delta.length()<4: break
		for pair in [["move_left",delta.x < -2],["move_right",delta.x>2],["move_up",delta.y < -2],["move_down",delta.y>2]]:
			if pair[1]: Input.action_press(pair[0])
			else: Input.action_release(pair[0])
		await frames(1)
	for action in ["move_left","move_right","move_up","move_down"]: Input.action_release(action)
	await frames(2)
	check(game.player.position.distance_to(target)<5,"Exploration movement to "+str(target))

func inspect_action() -> void:
	await key_press(KEY_E)
	check(game.inspection.is_open,"Inspection opens on approach")
	await click(game.inspection.action)
	await frames(3)

func run_checks() -> void:
	state = root.get_node("GameState")
	state.save_directory = "user://demo_walkthrough_%d" % OS.get_process_id()
	# Starting scene is the production main menu. New Game performs all initialization.
	game = await load_world(state.MAIN_MENU_SCENE)
	await capture("demo-main.png")
	await choose("Новая игра")
	await choose("СЛОТ 1")
	await frames(10)
	game = current_scene
	check(game.scene_file_path==City.GUILD and state.personal_coins==0,"New game starts normally with empty wallet")
	await capture("demo-guild.png")
	await walk_to(Vector2(384,230))
	await key_press(KEY_E)
	await choose("Берусь.")
	await choose("Есть ещё работа")
	await choose("архив")
	await choose("Разберу бумаги")
	await choose("А какие ещё")
	await choose("Корвину")
	await choose("Хорошо, соберу")
	await close_talk()
	for task in ["архиве","Пакет"]:
		await walk_to(Vector2(650,174))
		await key_press(KEY_E)
		await choose(task)
		await solve_activity(game)
	await walk_to(Vector2(384,230))
	await key_press(KEY_E)
	await choose("Есть ещё работа")
	await choose("архив")
	await choose("Вот записи")
	await close_talk()
	await enter(Vector2(384,432),City.SQUARE)
	await walk_to(Vector2(548,253))
	await key_press(KEY_E)
	await choose("Мира просила")
	await close_talk()
	for work in [Vector2(574,415),Vector2(453,211),Vector2(653,211)]:
		await walk_to(work)
		await key_press(KEY_E)
		await solve_activity(game)
	await walk_to(Vector2(548,253))
	await key_press(KEY_E)
	await choose("Всё готово")
	await close_talk()
	await enter(Vector2(168,238),City.GUILD)
	await walk_to(Vector2(384,230))
	await key_press(KEY_E)
	await choose("Спасибо. Заберу")
	await choose("Есть ещё работа")
	await choose("Корвину")
	await choose("Да. Вот его расписка")
	await close_talk()
	check(state.personal_coins==32,"All existing work earned exactly 32 coins")
	await key_press(KEY_I)
	await choose("Герой")
	await capture("demo-earned-growth.png")
	await choose("Закрыть")
	await enter(Vector2(384,432),City.SQUARE)
	await enter(Vector2(54,298),City.CRAFT)
	await capture("demo-craft.png")
	await enter(Vector2(384,48),City.TEMPLE)
	await capture("demo-temple.png")
	await enter(Vector2(712,368),City.MARKET)
	await capture("demo-market.png")
	await enter(Vector2(360,212),City.ARMORY)
	await walk_to(Vector2(384,222))
	await key_press(KEY_E)
	await choose("Купить")
	await choose("До встречи")
	await key_press(KEY_I)
	# Selecting inventory cells uses the real mouse; item IDs only locate the button.
	await click(game.character_panel.item_buttons.simple_dagger)
	await choose("Экипировать")
	await choose("Закрыть")
	check(state.equipped_weapon=="simple_dagger" and state.personal_coins==8,"Bought and equipped dagger through UI")
	await enter(Vector2(384,428),City.MARKET)
	await enter(Vector2(640,432),City.GATES)
	await capture("demo-gates.png")
	await enter(Vector2(384,424),state.OUTSKIRTS_SCENE)
	await capture("demo-road-entry.png")
	for point in Route.MAIN:
		if point==Vector2(100,436): continue
		await straight(point)
		if point==Vector2(-44,-142):
			await capture("demo-branch.png")
			for branch in Route.BRANCH: await straight(branch)
			await capture("demo-cache.png")
			await inspect_action()
			for i in range(Route.BRANCH.size()-2,-1,-1): await straight(Route.BRANCH[i])
		if point==Vector2(560,190): break
	await key_press(KEY_E)
	await frames(8)
	game = current_scene
	check(game.scene_file_path==state.OUTPOST_SCENE,"Arrived at the outpost by walking")
	for point in [Vector2(384,344),Vector2(384,280),Vector2(490,280)]: await straight(point)
	await capture("demo-barred-view.png")
	for point in [Vector2(384,280),Vector2(144,280),Vector2(144,208)]: await straight(point)
	for i in range(180):
		if game.player.position.distance_to(game.combat.enemy.position)<39: break
		Input.action_press("move_right")
		await frames(1)
	Input.action_release("move_right")
	for i in range(3):
		var aim: Vector2 = game.get_viewport().get_canvas_transform()*game.combat.enemy.position
		for pressed in [true,false]:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.position = root.get_final_transform()*aim
			event.pressed = pressed
			Input.parse_input_event(event)
			await frames(2)
		await frames(36)
	check(state.post_guard_defeated,"Three deliberate mouse attacks win the existing encounter")
	await capture("demo-victory.png")
	await straight(Vector2(244,190))
	await inspect_action()
	for point in [Vector2(244,208),Vector2(144,208),Vector2(144,112),Vector2(144,24),Vector2(300,24),Vector2(300,-80),Vector2(460,-80),Vector2(460,24),Vector2(600,24),Vector2(600,160)]: await straight(point)
	await capture("demo-sealed-room.png")
	await inspect_action()
	for point in [Vector2(600,24),Vector2(460,24),Vector2(460,-80),Vector2(300,-80),Vector2(300,24),Vector2(144,24),Vector2(144,112),Vector2(144,280),Vector2(384,280),Vector2(384,428)]: await straight(point)
	await key_press(KEY_E)
	await frames(8)
	game = current_scene
	await straight(Vector2(560,238))
	await inspect_action()
	for i in range(Route.SHORTCUT.size()-2,-1,-1): await straight(Route.SHORTCUT[i])
	await straight(Vector2(100,436))
	await key_press(KEY_E)
	await frames(8)
	game = current_scene
	await enter(Vector2(712,208),City.MARKET)
	await enter(Vector2(144,236),City.BOOKSHOP)
	await capture("demo-bookshop-room.png")
	await walk_to(Vector2(384,222))
	await key_press(KEY_E)
	for name in ["Замечать незаметное","Мера и узел","Первый клинок"]:
		await choose(name)
		await choose("Купить")
	await choose("До встречи")
	await key_press(KEY_I)
	for id in ["book_observation","book_knots","book_blade"]:
		await click(game.character_panel.item_buttons[id])
		await choose("Изучить книгу")
	await choose("Герой")
	await capture("demo-final-hero.png")
	await key_press(KEY_PAGEDOWN)
	await capture("demo-final-skills.png")
	check(state.studied_books.size()==3 and state.weapon_base_damage()==7 and "shortcut" in state.discoveries and state.inventory.has("watch_notes"),"Complete start-to-books loop preserves discoveries and real growth")
	var saved: Dictionary = state.read_slot(1)
	check(saved.studied_books.size()==3 and saved.post_guard_defeated,"Final ordinary autosave contains the full route")
	print("DEMO WALKTHROUGH: %d failure(s); save directory %s" % [failures,state.save_directory])
	# Keep this isolated QA save as evidence; production saves were never read/written.
	quit(1 if failures else 0)
