extends "res://tests/guild_smoke.gd"
## Persistent slots, manual/automatic saves and pause state preservation.

var state: Node
var game: Node


func clear_test_saves() -> void:
	state.game_active = false
	state.active_slot = 0
	for slot in range(1, state.SLOT_COUNT + 1):
		for suffix in ["", ".tmp", ".bak"]:
			var path: String = state.slot_path(slot) + suffix
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var absolute := ProjectSettings.globalize_path(state.save_directory)
	if DirAccess.dir_exists_absolute(absolute):
		DirAccess.remove_absolute(absolute)


func load_world(path: String) -> Node:
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
		await frames(2)
	var scene = load(path).instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(5)
	return scene


func capture_paused(filename: String) -> void:
	if screenshot_dir.is_empty():
		return
	RenderingServer.force_draw()
	var result: int = root.get_texture().get_image().save_png(screenshot_dir.path_join(filename))
	check(result == OK, "Screenshot " + filename)


func run_checks() -> void:
	state = root.get_node("GameState")
	state.save_directory = "user://automated_save_test_%d" % OS.get_process_id()
	clear_test_saves()
	state.reset_game()
	state.active_slot = 1
	state.game_active = true
	game = await load_world(state.GUILD_SCENE)

	var entries: Array[Dictionary] = state.slots()
	check(entries.size() == 5, "Exactly five save slots exist")
	check(entries.all(func(entry): return not entry.occupied), "Fresh slots are empty")

	game.player.position = Vector2(301, 333)
	state.play_seconds = 61.0
	check(state.save_game(2, "", Vector2.INF, "manual"), "Manual save writes an empty slot")
	check(state.active_slot == 2 and not state.read_slot(2).is_empty(), "Selected manual slot becomes current")
	state.accept_quest()
	check(int(state.read_slot(2).quest_stage) == state.QuestStage.ACCEPTED, "Quest change autosaves")

	state.personal_coins = 7
	state.play_seconds = 145.0
	game.player.position = Vector2(444, 333)
	check(state.save_game(4, "", Vector2.INF, "manual"), "A second slot can be written")
	state.personal_coins = 99
	state.quest_stage = state.QuestStage.COMPLETED
	check(state.load_game(4), "Occupied slot loads")
	await frames(8)
	game = current_scene
	check(state.active_slot == 4 and state.personal_coins == 7, "Load restores slot data and makes it current")
	check(state.quest_stage == state.QuestStage.ACCEPTED, "Load restores quest stage")
	check(game.player.position.distance_to(Vector2(444, 333)) < 1.0, "Load restores player position")
	check(state.format_play_time(state.play_seconds).begins_with("00:02:"), "Slot tracks play time")

	game.player.position = Vector2(384, 205)
	await frames()
	await key_press(KEY_E)
	check(game.dialogue.is_open, "Mira dialogue opens before pausing")
	await key_press(KEY_ESCAPE)
	check(paused and game.pause_menu.is_open, "Escape opens pause during dialogue")
	check(game.dialogue.is_open, "Pause keeps the dialogue open underneath")
	check(game.pause_menu.save_button.disabled, "Manual save is unavailable during dialogue")
	capture_paused("pause-over-dialogue.png")
	await key_press(KEY_ESCAPE)
	check(not paused and game.dialogue.is_open, "Resume returns to the same dialogue")
	game.dialogue.close_button.pressed.emit()
	await frames()

	await key_press(KEY_ESCAPE)
	check(not game.pause_menu.save_button.disabled, "Manual save is available while freely standing")
	game.pause_menu.open_save_slots()
	await frames()
	check(game.pause_menu.save_rows.get_child_count() == 5, "Manual save picker shows all five slots")
	var slot_two_date: String = state.format_saved_at(int(state.read_slot(2).saved_at))
	check(game.pause_menu.save_rows.get_child(1).text.contains(slot_two_date), "Manual save slot includes its last save date")
	capture_paused("manual-save-slots.png")
	game.pause_menu.select_save_slot(3, false)
	await frames()
	check(state.active_slot == 3 and not state.read_slot(3).is_empty(), "Saving to an empty slot switches the current slot")

	state.personal_coins = 11
	game.pause_menu.open_save_slots()
	await frames()
	game.pause_menu.select_save_slot(4, true)
	check(game.pause_menu.confirm_overlay.visible, "Occupied manual slot asks before overwrite")
	check(int(state.read_slot(4).personal_coins) == 7, "Overwrite waits for confirmation")
	game.pause_menu.confirm_overwrite()
	await frames()
	check(state.active_slot == 4 and int(state.read_slot(4).personal_coins) == 11, "Confirmed overwrite replaces and selects the slot")
	await key_press(KEY_ESCAPE)

	state.quest_stage = state.QuestStage.AVAILABLE
	state.accept_quest()
	check(int(state.read_slot(4).quest_stage) == state.QuestStage.ACCEPTED, "Important quest event updates the current slot")
	game.player.position = Vector2(384, 428)
	await frames()
	await key_press(KEY_E)
	await frames(8)
	game = current_scene
	var transition_data: Dictionary = state.read_slot(4)
	check(game.scene_file_path == state.SQUARE_SCENE, "Door changes location")
	check(str(transition_data.location_scene) == state.SQUARE_SCENE, "Location transition autosaves")

	state.meet_corvin()
	game.player.position = game.WORK_POSITIONS.planks
	await frames()
	await key_press(KEY_E)
	await frames(20)
	check(game.busy, "Work begins")
	await key_press(KEY_ESCAPE)
	check(paused and game.pause_menu.save_button.disabled, "Pause opens during work and blocks manual save")
	var elapsed_before_pause: float = game.work_elapsed
	await frames(20)
	check(is_equal_approx(game.work_elapsed, elapsed_before_pause), "Work timer freezes while paused")
	capture_paused("pause-over-work.png")
	await key_press(KEY_ESCAPE)
	check(game.busy and not paused, "Resume continues the same work action")
	await key_press(KEY_Q)
	check(not game.busy, "Q cancels work independently from pause")

	state.personal_coins = 13
	game.player.position = Vector2(580, 410)
	check(state.return_to_main_menu(), "Return to main menu succeeds")
	await frames(8)
	var menu := current_scene
	var exit_data: Dictionary = state.read_slot(4)
	check(not state.game_active and not paused, "Main menu ends the active session")
	check(int(exit_data.personal_coins) == 13, "Returning to main menu autosaves")
	check(not menu.continue_button.disabled, "Continue is enabled when a save exists")
	await capture("main-menu-home.png")
	menu.open_slots("load")
	await frames()
	check(menu.slot_rows.get_child_count() == 5, "Load screen shows all five slots")
	var slot_four_date: String = state.format_saved_at(int(state.read_slot(4).saved_at))
	check(menu.slot_rows.get_child(3).get_child(0).text.contains(slot_four_date), "Load slot includes its last save date")
	await capture("main-menu-slots.png")
	menu.close_slots()
	menu.open_slots("new")
	await frames()
	menu.select_slot(4, true)
	check(menu.confirm_overlay.visible and menu.pending_action == "new", "New game asks before replacing an occupied slot")
	menu.close_confirmation()
	check(not state.read_slot(4).is_empty(), "Cancelling new game keeps the save")
	menu.request_delete(4)
	check(menu.confirm_overlay.visible and menu.pending_action == "delete", "Delete has a separate confirmation")
	menu.close_confirmation()
	check(not state.read_slot(4).is_empty(), "Cancelling deletion keeps the save")
	menu.request_delete(4)
	menu.confirm_action()
	await frames()
	check(state.read_slot(4).is_empty(), "Confirmed deletion removes only that slot")
	check(not state.read_slot(2).is_empty() and not state.read_slot(3).is_empty(), "Other slots remain after deletion")

	clear_test_saves()
	print("RESULT: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
