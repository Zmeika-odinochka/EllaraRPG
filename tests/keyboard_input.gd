extends "res://tests/guild_smoke.gd"
## Reproduce Windows events observed with a valid keycode and incorrect scan code.

var test_physical: int = 4194313

func send_key(logical: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = logical
	event.physical_keycode = test_physical
	event.pressed = pressed
	Input.parse_input_event(event)

func key_press(key: Key) -> void:
	send_key(key, true)
	await frames(2)
	send_key(key, false)
	await frames(2)

func run_checks() -> void:
	var game = load("res://scenes/guild.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await frames(5)
	for scan_code in [4194313, 0]:
		test_physical = scan_code
		for key in [KEY_D, "В".unicode_at(0), KEY_RIGHT]:
			game.player.position = Vector2(384, 310)
			send_key(key, true)
			await frames(10)
			check(game.player.position.x > 390, "Logical movement with scan code %d, key %d" % [scan_code, key])
			send_key(key, false)
			await frames(3)
			check(game.player.velocity.is_zero_approx(), "Release stops movement")
		for key in [KEY_I, "Ш".unicode_at(0)]:
			await key_press(key)
			check(game.character_panel.is_open, "Logical I/RU opens inventory")
			await key_press(key)
			check(not game.character_panel.is_open, "Same key closes inventory")
		for key in [KEY_J, "О".unicode_at(0)]:
			await key_press(key)
			check(game.character_panel.is_open and game.character_panel.mode == "quests", "Logical J/RU opens journal")
			await key_press(key)
			check(not game.character_panel.is_open, "Same key closes journal")
		game.player.position = Vector2(384, 205)
		await frames()
		await key_press(KEY_E)
		check(game.dialogue.is_open, "Logical E opens Mira dialogue")
		game.dialogue.close_button.pressed.emit()
		await frames()
		await key_press(KEY_ESCAPE)
		check(paused, "Logical Escape pauses")
		await key_press(KEY_ESCAPE)
		check(not paused, "Logical Escape resumes")
		game.activity_game.open_game("archive")
		await key_press(KEY_1)
		check(game.activity_game.step == 1, "Logical number advances work once")
		await key_press(KEY_Q)
		check(not game.activity_game.is_open, "Logical Q cancels work")
		game.activity_game.open_game("canopy")
		game.activity_game.cursor = 0.5
		await key_press(KEY_SPACE)
		check(game.activity_game.step == 1, "Logical Space advances timing game once")
		await key_press("Й".unicode_at(0))
		check(not game.activity_game.is_open, "Russian Q cancels work")
	print("KEYBOARD CHECKS: ", failures, " failure(s)")
	quit(1 if failures else 0)
