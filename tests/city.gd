extends "res://tests/save_and_pause.gd"
const City = preload("res://scripts/city_catalog.gd")

func click(button: Button) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = root.get_final_transform()*button.get_global_rect().get_center()
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(2)

func walk_to(target: Vector2) -> void:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0,0,48,30)
	grid.cell_size = Vector2(16,16)
	grid.offset = Vector2(8,12)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14,10)
	query.shape = shape
	query.exclude = [game.player.get_rid()]
	var start := Vector2i.ZERO
	var finish := Vector2i.ZERO
	var start_distance := INF
	var end_distance := INF
	for y in range(2,28):
		for x in range(2,46):
			var point := Vector2(x*16+8,y*16+12)
			query.transform = Transform2D(0,point+Vector2(0,-4))
			var solid: bool = not game.get_world_2d().direct_space_state.intersect_shape(query).is_empty()
			grid.set_point_solid(Vector2i(x,y),solid)
			if solid: continue
			if point.distance_squared_to(game.player.position)<start_distance:
				start_distance = point.distance_squared_to(game.player.position)
				start = Vector2i(x,y)
			if point.distance_squared_to(target)<end_distance:
				end_distance = point.distance_squared_to(target)
				finish = Vector2i(x,y)
	var path := grid.get_point_path(start,finish)
	check(not path.is_empty(),"Physical route exists to " + str(target))
	for point in path:
		for frame in range(55):
			var offset: Vector2 = point-game.player.position
			if offset.length()<3: break
			for pair in [["move_left",offset.x < -1.5],["move_right",offset.x > 1.5],["move_up",offset.y < -1.5],["move_down",offset.y > 1.5]]:
				if pair[1]: Input.action_press(pair[0])
				else: Input.action_release(pair[0])
			await frames(1)
		for action in ["move_left","move_right","move_up","move_down"]: Input.action_release(action)
		if game.player.position.distance_to(point)>6:
			check(false,"Movement obstructed at " + str(point))
			break
	await frames(2)
	check(game.player.position.distance_to(target)<34,"Can approach interaction through real movement")

func run_checks() -> void:
	state = root.get_node("GameState")
	state.save_directory = "user://city_test_%d" % OS.get_process_id()
	clear_test_saves()
	state.reset_game()
	state.active_slot = 1
	state.game_active = true
	game = await load_world(City.ARMORY)
	await walk_to(Vector2(384,222))
	await key_press(KEY_E)
	var talk = game.city.conversation
	check(talk.is_open and talk.npc_id=="smith","Weapon shop opens as a conversation")
	check(not game.player.controls_enabled and not game.can_manual_save(),"Shop is modal")
	state.personal_coins = 23
	talk.refresh()
	check(talk.buy_button.disabled and not state.buy_dagger() and state.personal_coins==23,"Insufficient coins cannot buy or subtract")
	state.personal_coins = 24
	talk.refresh()
	await frames(3)
	check(Rect2(0,0,640,360).encloses(talk.panel.get_global_rect()),"Shop fits 640x360")
	check(visible_text(talk).contains("Базовый урон: 6"),"Shop shows dagger damage")
	await capture("city-armory-shop.png")
	await key_press(KEY_ESCAPE)
	check(paused and talk.is_open and not state.buy_dagger(),"Pause preserves shop and blocks purchases")
	await key_press(KEY_ESCAPE)
	await click(talk.buy_button)
	check(state.personal_coins==0 and state.inventory.get("simple_dagger",0)==1,"Mouse purchase subtracts exactly 24 and gives one dagger")
	check(talk.buy_button.disabled and not state.buy_dagger() and state.personal_coins==0,"Second purchase cannot double charge")
	check(state.read_slot(1).inventory.get("simple_dagger",0)==1,"Purchased dagger is saved")
	check(state.equipped_weapon=="","Purchase does not silently equip")
	talk.close()
	await key_press(KEY_I)
	game.character_panel.show_item("simple_dagger")
	await frames(3)
	var equip: Button = game.character_panel.details.get_child(game.character_panel.details.get_child_count()-1)
	equip.grab_focus()
	await key_press(KEY_ENTER)
	check(state.equipped_weapon=="simple_dagger" and state.read_slot(1).equipped_weapon=="simple_dagger","Keyboard equip persists")
	check(state.weapon_base_damage()==6,"Weapon model exposes dagger base damage")
	check(visible_text(game.character_panel).contains("Базовый урон: 6"),"Dagger details show damage")
	await capture("city-dagger-bag.png")
	game.character_panel.switch_tab("hero")
	await frames(3)
	await capture("city-weapon-slot.png")
	check(visible_text(game.character_panel).contains("Кинжал · Урон: 6"),"Weapon slot shows equipped damage")
	check(Rect2(0,0,640,360).encloses(game.character_panel.panel.get_global_rect()),"Equipped hero panel fits viewport")
	game.character_panel.close()
	var saved: Dictionary = state.read_slot(1)
	state.reset_game()
	check(state.apply_data(saved) and state.equipped_weapon=="simple_dagger" and state.inventory.simple_dagger==1,"Purchase and equipment survive loading")
	state.pending_spawn = Vector2.INF
	check(state.set_equipped_weapon("") and state.inventory.simple_dagger==1,"Removing equipment keeps owned item")
	check(state.read_slot(1).equipped_weapon=="" and state.weapon_base_damage()==1,"Unequipped state persists and exposes unarmed damage")
	for version in [1,2,3,4]:
		var old := saved.duplicate(true)
		old.version = version
		old.erase("equipped_weapon")
		old.inventory.erase("simple_dagger")
		old.personal_coins = 37
		check(state.apply_data(old) and state.equipped_weapon=="" and state.personal_coins==37,"Legacy v%d preserves progress with empty weapon slot" % version)
		check(not state.set_equipped_weapon("simple_dagger"),"Cannot equip unowned dagger")
	var invalid := saved.duplicate(true)
	invalid.inventory.erase("simple_dagger")
	check(not state.apply_data(invalid),"Equipped but unowned dagger rejected")
	# A failed write must leave both wallet and ownership unchanged.
	state.reset_game()
	state.game_active = true
	state.active_slot = 1
	state.pending_spawn = Vector2.INF
	game = await load_world(City.ARMORY)
	game.player.position = Vector2(384,222)
	state.personal_coins = 24
	var blocker: String = ProjectSettings.globalize_path(state.slot_path(1)+".tmp")
	DirAccess.make_dir_absolute(blocker)
	check(not state.buy_dagger() and state.personal_coins==24 and not state.inventory.has("simple_dagger"),"Failed persistence rolls back purchase")
	DirAccess.remove_absolute(blocker)
	# Static guild conversations are independent of Mira and do not form a party.
	state.game_active = false
	game = await load_world(City.GUILD)
	for entry in game.city.actions:
		await walk_to(entry.at)
		await key_press(KEY_E)
		check(game.city.conversation.npc_id==entry.npc and game.city.conversation.is_open,"Seated goddess reachable: "+entry.npc)
		await key_press(KEY_ESCAPE)
		check(paused and game.city.conversation.is_open,"Pause preserves short conversation")
		await key_press(KEY_ESCAPE)
		if entry.npc=="astra": await capture("city-guild-table.png")
		game.city.conversation.close()
	# Every new city exit is physically reachable and loads its declared destination.
	for scene in [City.SQUARE,City.MARKET,City.CRAFT,City.TEMPLE,City.GATES,City.ARMORY]:
		for entry in City.actions(scene):
			if not entry.has("scene"): continue
			state.pending_spawn = Vector2.INF
			game = await load_world(scene)
			await walk_to(entry.at)
			await key_press(KEY_E)
			await frames(5)
			game = current_scene
			check(game.scene_file_path==entry.scene,"Connected district: "+scene+" -> "+entry.scene)
			check(game.hud.toast_remaining==0,"Transition does not show a save toast")
	# Road return now uses the southern gateway, with no weapon requirement.
	state.game_active = true
	state.pending_spawn = Vector2(100,410)
	game = await load_world(state.OUTSKIRTS_SCENE)
	await key_press(KEY_E)
	await frames(5)
	game = current_scene
	check(game.scene_file_path==City.GATES and state.equipped_weapon=="","Old road returns to city without a weapon gate")
	check(state.read_slot(1).location_scene==City.GATES,"Quiet transition still saves the destination")
	check(game.hud.toast_remaining==0,"Real transition autosave is quiet")
	check(state.save_game(1),"Manual save succeeds after quiet transition")
	check(game.hud.toast_remaining>0 and game.hud.toast.text.contains("Сохранено"),"Manual save confirmation remains visible")
	var blocked_write: String = ProjectSettings.globalize_path(state.slot_path(1)+".tmp")
	DirAccess.make_dir_absolute(blocked_write)
	check(not state.autosave("transition"),"Transition write failure is reported")
	check(game.hud.toast_icon.text=="!" and game.hud.toast_remaining>0,"Quiet autosave does not hide failures")
	DirAccess.remove_absolute(blocked_write)
	clear_test_saves()
	print("CITY: %d failure(s)" % failures)
	quit(1 if failures else 0)
