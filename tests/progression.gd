extends "res://tests/city.gd"

func run_checks() -> void:
	state = root.get_node("GameState")
	state.save_directory = "user://progression_test_%d" % OS.get_process_id()
	clear_test_saves()
	state.reset_game()
	state.active_slot = 1
	state.game_active = true
	game = await load_world(City.SQUARE)
	state.accept_quest()
	state.meet_corvin()
	game.begin_work("planks")
	await solve_activity(game)
	check(state.attributes["Сила"]==2 and state.attribute_xp["Выносливость"]==5,"Completed plank minigame grants XP and raises strength")
	check(state.attribute_thresholds["Сила"]==15,"Next threshold increases from catalog")
	check(not state.finish_work("planks") and not state.award_event("work:planks") and state.attribute_xp["Сила"]==0,"Repeated work cannot farm XP")
	var activity = game.activity_game
	activity.open_game("planks")
	check(activity.sequence.size()==4,"Strength actually reduces plank batches")
	activity.cancel_game()
	activity.open_game("canopy")
	activity.cursor = 0.365
	activity.answer(0)
	check(activity.step==0,"Base timing rejects edge outside original window")
	activity.cancel_game()
	state.attributes["Координация"] = 2
	activity.open_game("canopy")
	activity.cursor = 0.365
	activity.answer(0)
	check(activity.step==1 and activity.success_zone.size.x>96,"Coordination widens both drawn zone and accepted timing")
	await capture("p3-canopy.png")
	activity.cancel_game()
	activity.open_game("archive")
	check(not activity.archive_help,"Initial intellect gives no archive hint")
	activity.cancel_game()
	state.attributes["Интеллект"] = 2
	activity.open_game("archive")
	check(activity.archive_help and activity.feedback.text.contains("Заказы"),"Intellect supplies the relevant archive folder")
	await capture("p3-archive.png")
	activity.cancel_game()
	state.reset_game()
	state.game_active = true
	state.active_slot = 1
	game = await load_world(City.MARKET)
	await walk_to(Vector2(144,236))
	await key_press(KEY_E)
	await frames(5)
	game = current_scene
	check(game.scene_file_path==City.BOOKSHOP,"Bookshop doorway connects to its interior")
	await walk_to(Vector2(384,222))
	await key_press(KEY_E)
	var talk = game.city.conversation
	check(talk.npc_id=="bookseller" and talk.is_open,"Books are sold through conversation")
	check(not state.buy_book("book_observation") and state.personal_coins==0,"Insufficient funds never grant book")
	state.personal_coins = 8
	talk.refresh()
	await frames(3)
	check(Rect2(0,0,640,360).encloses(talk.panel.get_global_rect()),"Bookshop dialogue fits smallest viewport")
	await capture("p3-bookshop.png")
	await click(talk.buy_button)
	check(state.inventory.get("book_observation",0)==1 and state.personal_coins==6,"Real mouse purchase gives book and subtracts price once")
	check(not state.buy_book("book_observation") and state.personal_coins==6,"Owned book cannot charge again")
	check(state.buy_book("book_knots") and state.buy_book("book_blade") and state.personal_coins==0,"Existing earnings cover all three books")
	talk.close()
	check(not state.study_book("book_blade") and state.skills.is_empty(),"Advanced book requires intellect above start")
	await key_press(KEY_I)
	game.character_panel.show_item("book_observation")
	await frames(3)
	await capture("p3-book-detail.png")
	var study: Button = game.character_panel.details.get_child(game.character_panel.details.get_child_count()-1)
	study.grab_focus()
	await key_press(KEY_ENTER)
	check("book_observation" in state.studied_books and state.attributes["Интеллект"]==2,"Keyboard study grants XP and raises intellect")
	check(not state.study_book("book_observation") and state.attribute_xp["Интеллект"]==0,"Repeated study never pays again")
	check(state.inventory.get("book_observation",0)==1,"Studied book stays in bag")
	check(state.study_book("book_blade") and "blade_basics" in state.skills,"Eligible advanced book grants working skill")
	check(state.study_book("book_knots") and state.attributes["Координация"]==2,"Practical book changes an actual minigame stat")
	state.inventory.simple_dagger = 1
	state.set_equipped_weapon("simple_dagger")
	check(state.weapon_base_damage()==7,"Blade skill adds one real equipped damage")
	game.character_panel.switch_tab("hero")
	await frames(3)
	await capture("p3-hero.png")
	for i in range(5): await key_press(KEY_PAGEDOWN)
	await capture("p3-skills.png")
	check(visible_text(game.character_panel).contains("XP") and visible_text(game.character_panel).contains("Основы клинка"),"Existing hero tab exposes progression and skills")
	game.character_panel.close()
	state.save_game(1)
	var saved: Dictionary = state.read_slot(1)
	state.reset_game()
	check(state.apply_data(saved) and state.studied_books.size()==3 and state.skills.size()==1,"Studied books and skills survive a save/load")
	check(state.attribute_xp["Сила"]==5 and state.attributes["Координация"]==2 and state.weapon_base_damage()==7,"XP, attributes and equipped effect survive loading")
	check(not state.study_book("book_blade"),"Reload cannot repeat skill reward")
	state.pending_spawn = Vector2.INF
	game = await load_world(state.OUTPOST_SCENE)
	game.player.position = Vector2(244,208)
	await frames(20)
	check(game.combat.start_swing(game.combat.enemy.position),"Skilled attack starts in actual encounter")
	await frames(12)
	check(game.combat.enemy_health==11,"Book skill removes seven actual enemy health")
	for version in [1,2,3,4,5]:
		var old := saved.duplicate(true)
		old.version = version
		old.completed_steps = ["planks"]
		for id in state.Progress.BOOKS: old.inventory.erase(id)
		for field in ["attribute_xp","attribute_thresholds","credited_events","studied_books","skills"]: old.erase(field)
		check(state.apply_data(old) and state.studied_books.is_empty() and state.attribute_xp["Сила"]==0,"Legacy v%d migrates with safe empty progress" % version)
		check(not state.award_event("work:planks"),"Migrated completed event cannot replay XP")
	var invalid := saved.duplicate(true)
	invalid.attribute_xp["Сила"] = -1
	check(not state.apply_data(invalid),"Negative XP is rejected before mutating session")
	state.reset_game()
	state.game_active = true
	state.active_slot = 1
	state.pending_spawn = Vector2.INF
	game = await load_world(City.BOOKSHOP)
	game.player.position = Vector2(384,222)
	state.personal_coins = 8
	var blocker: String = ProjectSettings.globalize_path(state.slot_path(1)+".tmp")
	DirAccess.make_dir_absolute(blocker)
	check(not state.buy_book("book_knots") and state.personal_coins==8 and not state.inventory.has("book_knots"),"Failed write rolls back book purchase")
	state.inventory.book_observation = 1
	check(not state.study_book("book_observation") and state.attributes["Интеллект"]==1 and state.studied_books.is_empty(),"Failed write rolls back study and XP")
	DirAccess.remove_absolute(blocker)
	clear_test_saves()
	print("PROGRESSION: %d failure(s)" % failures)
	quit(1 if failures else 0)
