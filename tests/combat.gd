extends "res://tests/save_and_pause.gd"
var combat: Node2D

func mouse_button(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	# Input.parse_input_event enters before window stretch, like a native event.
	event.position = root.get_final_transform()*at
	event.global_position = event.position
	event.pressed = pressed
	Input.parse_input_event(event)
	await frames(2)

func click_enemy(held_frames: int = 2) -> void:
	var at: Vector2 = game.get_viewport().get_canvas_transform()*combat.enemy.position
	await mouse_button(at,true)
	await frames(held_frames)
	await mouse_button(at,false)

func fresh() -> void:
	state.post_guard_defeated = false
	game = await load_world(state.OUTPOST_SCENE)
	combat = game.combat
	await frames(18)

func wait_phase(wanted: String, limit: int = 240) -> void:
	for i in range(limit):
		if combat.phase == wanted: break
		await frames(1)
	check(combat.phase == wanted,"Enemy reaches " + wanted)

func run_checks() -> void:
	state = root.get_node("GameState")
	state.save_directory = "user://combat_test_%d" % OS.get_process_id()
	clear_test_saves()
	state.reset_game()
	state.active_slot = 1
	state.game_active = true
	await fresh()
	game.player.position = Vector2(244,208)
	await frames(3)
	await click_enemy(48)
	check(combat.strikes_started==1 and combat.enemy_health==17,"Real mouse hold makes one swing and one damage event")
	await frames(35)
	check(combat.strikes_started==1 and combat.enemy_health==17,"No automatic attack from held or released input")
	check(combat.swing_weapon=="" and combat.swing_damage==1,"Unarmed swing uses fist and actual unarmed damage")
	state.inventory.simple_dagger = 1
	await click_enemy()
	await frames(35)
	check(combat.enemy_health==16 and combat.swing_weapon=="","Owning a dagger in the bag does not wield it")
	check(state.set_equipped_weapon("simple_dagger"),"Owned dagger can be equipped before combat")
	await click_enemy()
	await frames(35)
	check(combat.enemy_health==10 and combat.swing_weapon=="simple_dagger" and combat.swing_damage==6,"Equipped dagger deals exactly six damage and selects dagger art")
	state.set_equipped_weapon("")
	await click_enemy()
	await frames(35)
	check(combat.enemy_health==9 and combat.swing_weapon=="" and combat.swing_damage==1,"Removing the dagger restores fist damage and art")
	await fresh()
	game.player.position = Vector2(144,200)
	check(combat.start_swing(Vector2(0,200)),"An empty swing starts")
	await frames(35)
	check(combat.enemy_health==18,"Out-of-range or wrong-facing attack misses")
	# The actual room table is between these two safe floor positions.
	check(not combat.line_clear(Vector2(244,120),Vector2(244,200)),"Solid table blocks damage visibility")
	await fresh()
	game.player.position = Vector2(244,208)
	await wait_phase("windup")
	var time_before: float = combat.phase_time
	var health_before: int = combat.health
	await key_press(KEY_ESCAPE)
	await frames(50)
	check(paused and combat.phase=="windup" and is_equal_approx(combat.phase_time,time_before),"Pause freezes anticipation")
	check(combat.health==health_before,"No damage under pause")
	await capture_paused("combat-pause.png")
	await key_press(KEY_ESCAPE)
	await wait_phase("strike")
	check(combat.health==75,"Readable strike deals one 25-point hit")
	await frames(5)
	check(combat.health==75,"Strike active frames do not multiply damage")
	await wait_phase("recovery")
	check(combat.phase_time>0.7,"Strike leaves a recovery window")
	await fresh()
	game.player.position = Vector2(244,208)
	await wait_phase("windup")
	game.open_character_panel("inventory")
	var frozen: float = combat.phase_time
	await frames(35)
	await mouse_button(Vector2(20,20),true)
	check(combat.strikes_started==0 and combat.phase_time==frozen,"Menu clicks cannot attack and menu freezes enemy")
	game.character_panel.close()
	await frames(20)
	check(combat.strikes_started==0,"Closing a menu with held mouse does not attack")
	await mouse_button(Vector2(20,20),false)
	await frames(18)
	combat._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	frozen = combat.phase_time
	await frames(30)
	check(combat.phase_time==frozen and game.player.combat_movement_scale==0,"Lost window focus freezes combat and movement")
	combat._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await frames(18)
	check(combat.strikes_started==0,"Restoring focus does not synthesize a swing")
	# Move out of the locked direction while the enemy prepares its attack.
	await fresh()
	game.player.position = Vector2(244,208)
	await wait_phase("windup")
	game.player.position = Vector2(304,224)
	await wait_phase("recovery")
	check(combat.health==100,"Leaving the marked arc avoids damage")
	# Real movement down the known doorway disengages; enemy cannot follow to foyer.
	game.player.position = Vector2(144,224)
	Input.action_press("move_down")
	await frames(35)
	Input.action_release("move_down")
	check(game.player.position.y>256 and not combat.engaged,"Existing passage allows physical retreat")
	await wait_phase("idle")
	check(combat.health==100 and combat.enemy_health==18 and combat.enemy.position.distance_to(combat.HOME)<4,"Retreat resets both participants after enemy returns")
	# Defeat uses the live enemy loop, preserving all persistent progress.
	await fresh()
	state.personal_coins = 37
	state.attributes["Сила"] = 4
	state.inventory.watch_notes = 1
	state.discoveries.assign(["road_cache","shortcut"])
	game.player.position = Vector2(244,208)
	for i in range(600):
		if combat.defeated: break
		await frames(1)
	check(combat.defeated and combat.health==0 and game.busy,"Four live enemy attacks open defeat")
	check(not game.can_manual_save() and not game.player.controls_enabled,"Defeat blocks world actions")
	check(Rect2(0,0,640,360).encloses(combat.defeat_panel.get_global_rect()),"Defeat fits logical 640x360")
	await capture("combat-defeat.png")
	await key_press(KEY_ESCAPE)
	check(paused and combat.defeated,"Escape remains available on defeat")
	await key_press(KEY_ESCAPE)
	await key_press(KEY_ENTER)
	check(not combat.defeated and combat.health==100 and combat.enemy_health==18,"Keyboard retry restores the whole encounter")
	check(game.player.position.distance_to(combat.RETRY)<4 and not game.busy,"Retry starts at safe doorway")
	check(state.personal_coins==37 and state.attributes["Сила"]==4 and state.inventory.watch_notes==1 and "shortcut" in state.discoveries,"Defeat preserves money, attributes, find and shortcut")
	# Exercise the other choice with an actual GUI mouse event.
	combat.health = 25
	combat.invulnerability = 0
	combat.hurt_player()
	await frames(3)
	await mouse_button(combat.exit_button.get_global_rect().get_center(),true)
	await mouse_button(combat.exit_button.get_global_rect().get_center(),false)
	check(not combat.defeated and game.player.position.distance_to(Vector2(384,392))<4,"Mouse defeat choice returns to the safe exit")
	# Kill with separate actual mouse clicks. No artificial reward is granted.
	state.inventory.simple_dagger = 1
	state.set_equipped_weapon("simple_dagger")
	game.player.position = Vector2(244,208)
	await frames(20)
	for i in range(3):
		await click_enemy()
		await frames(35)
	check(combat.phase=="cleared" and state.post_guard_defeated,"Three separate dagger hits clear the encounter")
	check(state.personal_coins==37 and state.attributes["Сила"]==4,"No unimplemented XP or coin reward")
	check(state.read_slot(1).post_guard_defeated,"Victory autosaves")
	var saved: Dictionary = state.read_slot(1)
	check(state.apply_data(saved),"Version 4 loads")
	game = await load_world(state.OUTPOST_SCENE)
	combat = game.combat
	check(combat.phase=="cleared" and combat.enemy.collision_layer==0,"Loaded victory does not respawn a blocking enemy")
	for version in [1,2,3]:
		var legacy := saved.duplicate(true)
		legacy.version = version
		legacy.erase("post_guard_defeated")
		check(state.apply_data(legacy) and not state.post_guard_defeated,"Legacy v%d defaults to unfinished encounter" % version)
		check(state.personal_coins==37 and state.inventory.watch_notes==1,"Legacy progress preserved")
	var corrupt := saved.duplicate(true)
	corrupt.post_guard_defeated = "false"
	check(not state.apply_data(corrupt),"Malformed combat state rejected")
	# An unfinished saved attempt reloads both health pools, not just the hero.
	await fresh()
	game.player.position = Vector2(244,208)
	await click_enemy()
	await frames(40)
	check(state.save_game(1),"Unfinished attempt can be saved")
	check(state.apply_data(state.read_slot(1)),"Unfinished attempt loads")
	game = await load_world(state.OUTPOST_SCENE)
	combat = game.combat
	check(combat.health==100 and combat.enemy_health==18,"Loading resets both health pools consistently")
	game.player.position = Vector2(244,208)
	await wait_phase("windup")
	check(combat.health_bar.size.y<=8,"Combat health bar stays compact")
	await capture("combat-telegraph.png")
	# Continue pursuit around the real table rather than through its collision.
	game.player.position = Vector2(296,112)
	await frames(65)
	await wait_phase("windup",300)
	check(combat.enemy.position.distance_to(game.player.position)<=34,"Enemy navigates around furniture to a new approach")
	state.pending_spawn = combat.HOME
	game = await load_world(state.OUTPOST_SCENE)
	combat = game.combat
	check(game.player.position==combat.HOME and combat.enemy.position.distance_to(game.player.position)>26,"Old save at enemy home preserves hero position without overlapping the new actor")
	clear_test_saves()
	print("Combat checks complete: %d failure(s)" % failures)
	quit(1 if failures else 0)
