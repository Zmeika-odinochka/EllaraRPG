extends "res://tests/save_and_pause.gd"
const Layout = preload("res://scripts/exploration_layout.gd")
var walked := 0.0

func walk_to(target: Vector2, limit: int = 500) -> void:
	for frame in range(limit):
		var difference: Vector2 = target - game.player.position
		if difference.length() < 4: break
		var before: Vector2 = game.player.position
		for entry in [["move_left",difference.x < -2],["move_right",difference.x > 2],["move_up",difference.y < -2],["move_down",difference.y > 2]]:
			if entry[1]: Input.action_press(entry[0])
			else: Input.action_release(entry[0])
		await frames(1)
		walked += game.player.position.distance_to(before)
	for action in ["move_left","move_right","move_up","move_down"]: Input.action_release(action)
	await frames(2)
	check(game.player.position.distance_to(target)<5,"Walkable route to "+str(target))

func inspect_here() -> void:
	await key_press(KEY_E)
	check(game.inspection.is_open and not game.player.controls_enabled,"Inspection blocks movement")
	await frames()
	check(Rect2(0,0,640,360).encloses(game.inspection.panel.get_global_rect()),"Inspection fits 16:9")

func run_checks() -> void:
	state = root.get_node("GameState")
	state.save_directory = "user://exploration_test_%d" % OS.get_process_id()
	clear_test_saves()
	state.reset_game()
	state.active_slot = 1
	state.game_active = true
	game = await load_world(state.SQUARE_SCENE)
	game.player.position = Vector2(714,398)
	await frames()
	await key_press(KEY_E)
	await frames(5)
	game = current_scene
	check(game.scene_file_path == state.OUTSKIRTS_SCENE and state.quest_stage == state.QuestStage.AVAILABLE,"Road accessible without quest")
	var view := Rect2(game.player.get_node("Camera2D").get_screen_center_position()-Vector2(320,180),Vector2(640,360))
	check(not view.intersects(Rect2(496,40,208,132)),"Entry screen does not reveal the post")
	await capture("exploration-road.png")
	check(not state.discover("road_cache"),"No remote collection")
	# The first reveal is around the gorge bend, rather than across an open park.
	walked = 0
	for point in Layout.MAIN:
		if point == Vector2(100,436): continue
		await walk_to(point)
		if point == Vector2(-332,108): await capture("exploration-gorge.png")
		if point == Vector2(-44,-142):
			await capture("exploration-branch-hint.png")
			for branch_point in Layout.BRANCH:
				await walk_to(branch_point)
			await capture("exploration-cache.png")
			await inspect_here()
			check(not state.inventory.has("watch_notes"),"Looking does not take notes")
			await key_press(KEY_ESCAPE)
			check(paused and game.inspection.is_open,"Pause preserves inspection")
			await key_press(KEY_ESCAPE)
			await key_press(KEY_TAB)
			check(game.inspection.action.has_focus(),"Take action is keyboard accessible")
			await key_press(KEY_ENTER)
			check(state.inventory.get("watch_notes",0)==1 and not state.discover("road_cache"),"Original find still awarded once")
			for i in range(Layout.BRANCH.size()-2,-1,-1): await walk_to(Layout.BRANCH[i])
		if point == Vector2(560,190): break
	var outward_distance := walked
	print("OUTWARD WALK WITH BRANCH: %.0f" % outward_distance)
	await capture("exploration-post-exterior.png")
	await key_press(KEY_E)
	await frames(5)
	game = current_scene
	check(game.scene_file_path == state.OUTPOST_SCENE,"Original doorway enters divided post")
	await capture("exploration-post-entry.png")
	for point in [Vector2(384,344),Vector2(384,280),Vector2(490,280)]: await walk_to(point)
	await capture("exploration-barred-view.png")
	# The glowing room cannot be reached through the viewing grate.
	Input.action_press("move_right")
	await frames(35)
	Input.action_release("move_right")
	check(game.player.position.x < 520,"Grate blocks direct entry to far room")
	for point in [Vector2(384,280),Vector2(144,280),Vector2(144,190),Vector2(244,190)]: await walk_to(point)
	await inspect_here()
	game.inspection.action.pressed.emit()
	await capture("exploration-guardroom.png")
	for point in [Vector2(244,208),Vector2(144,208),Vector2(144,112),Vector2(144,24),Vector2(300,24),Vector2(300,-80),Vector2(460,-80),Vector2(460,24),Vector2(600,24),Vector2(600,160)]: await walk_to(point)
	await capture("exploration-post.png")
	await inspect_here()
	game.inspection.action.pressed.emit()
	check(state.save_game(1),"New geometry keeps saving working")
	var saved: Dictionary = state.read_slot(1)
	state.reset_game()
	state.apply_data(saved)
	game = await load_world(saved.location_scene)
	check(game.player.position.distance_to(Vector2(600,160))<5 and "sealed_arch" in state.discoveries,"Valid old coordinates and discoveries remain unchanged")
	for point in [Vector2(600,24),Vector2(460,24),Vector2(460,-80),Vector2(300,-80),Vector2(300,24),Vector2(144,24),Vector2(144,112),Vector2(144,280),Vector2(384,280),Vector2(384,428)]: await walk_to(point)
	await key_press(KEY_E)
	await frames(5)
	game = current_scene
	await walk_to(Vector2(560,238))
	check("shortcut" not in state.discoveries,"Layout does not auto-open the shortcut")
	await inspect_here()
	game.inspection.action.pressed.emit()
	await frames()
	check(game.gate.get_child(0).disabled,"Existing latch removes physical gate")
	state.save_game(1)
	saved = state.read_slot(1)
	state.reset_game()
	state.apply_data(saved)
	game = await load_world(saved.location_scene)
	check(game.gate.get_child(0).disabled and state.inventory.get("watch_notes",0)==1,"Shortcut and find survive reload")
	await capture("exploration-shortcut.png")
	walked = 0
	for i in range(Layout.SHORTCUT.size()-2,-1,-1): await walk_to(Layout.SHORTCUT[i])
	await walk_to(Vector2(100,436))
	print("SHORTCUT RETURN WALK: %.0f" % walked)
	check(walked < (outward_distance-Layout.path_length(Layout.BRANCH)*2)*0.55,"Shortcut saves over 45 percent even excluding the optional branch")
	await key_press(KEY_E)
	await frames(5)
	game = current_scene
	check(game.scene_file_path == state.SQUARE_SCENE,"Original square return still works")
	# Formerly valid empty-floor positions may now be masonry/rock. Preserve state;
	# relocate only the feet, to a physically free point in the same location.
	for entry in [[state.OUTSKIRTS_SCENE,Vector2(160,190)],[state.OUTPOST_SCENE,Vector2(384,216)]]:
		var old: Dictionary = saved.duplicate(true)
		old.location_scene = entry[0]
		old.player_position = [entry[1].x,entry[1].y]
		old.personal_coins = 37
		old.attributes["Сила"] = 4
		state.apply_data(old)
		game = await load_world(entry[0])
		check(Layout.safe_feet(game.player.position,entry[0]==state.OUTPOST_SCENE,true),"Old save inside new terrain relocates safely")
		check(state.personal_coins==37 and state.attributes["Сила"]==4 and state.inventory.get("watch_notes",0)==1 and "shortcut" in state.discoveries,"Relocation preserves all progress")
	# Closed shortcut remains a real barrier in a fresh session.
	state.reset_game()
	state.pending_spawn = Vector2(560,324)
	game = await load_world(state.OUTSKIRTS_SCENE)
	Input.action_press("move_up")
	await frames(40)
	Input.action_release("move_up")
	check(game.player.position.y>=288 and not state.discover("shortcut"),"Locked side cannot bypass the retained gate")
	var legacy: Dictionary = saved.duplicate(true)
	legacy.version = 2
	legacy.location_scene = state.GUILD_SCENE
	legacy.erase("discoveries")
	legacy.personal_coins = 37
	check(state.apply_data(legacy) and state.discoveries.is_empty() and state.personal_coins==37,"Version 2 migration preserved")
	legacy.version = 1
	check(state.apply_data(legacy),"Version 1 migration preserved")
	clear_test_saves()
	print("EXPLORATION: %d failure(s)" % failures)
	quit(0 if failures==0 else 1)
