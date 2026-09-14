extends SceneTree
## Integration checks against the real main scene and physics engine.

var failures: int = 0
var screenshot_dir: String = ""


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			screenshot_dir = argument.trim_prefix("--capture=")
	call_deferred("run_checks")


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func frames(count: int = 3) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame


func key_press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)


func capture(filename: String) -> void:
	if screenshot_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var result: int = root.get_texture().get_image().save_png(screenshot_dir.path_join(filename))
	check(result == OK, "Screenshot " + filename)


func run_checks() -> void:
	var packed = load("res://scenes/guild.tscn")
	if packed == null:
		check(false, "Main scene loads")
		quit(1)
		return
	var game = packed.instantiate()
	root.add_child(game)
	current_scene = game
	await frames(5)
	var player = game.player
	if "--preview-mira" in OS.get_cmdline_user_args():
		player.position = Vector2(384, 205)
		return
	check(not game.dialogue.is_open, "Dialogue starts closed")
	await capture("guild-room.png")
	await key_press(KEY_E)
	check(not game.dialogue.is_open, "E far from Mira does not open dialogue")
	var start: Vector2 = player.position
	Input.action_press("move_right")
	await frames(10)
	check(player.position.x > start.x + 5, "Movement moves player")
	var straight_speed: float = player.velocity.length()
	Input.action_press("move_down")
	await frames(3)
	check(absf(player.velocity.length() - straight_speed) < 0.1, "Diagonal speed is normalized")
	Input.action_release("move_right")
	Input.action_release("move_down")
	await frames()
	check(player.velocity.is_zero_approx(), "Releasing movement stops player")
	player.position = Vector2(384, 225)
	Input.action_press("move_up")
	await frames(40)
	Input.action_release("move_up")
	await frames()
	check(player.position.y >= 193 and player.position.y < 205, "Reception counter blocks movement")
	check(game.near_npc, "Mira is reachable from front of counter")
	check(game.prompt.visible, "Interaction prompt appears near Mira")
	await key_press(KEY_E)
	check(game.dialogue.is_open, "Physical E opens quest window")
	check(not player.controls_enabled, "Dialogue disables movement")
	check(game.dialogue.close_button.has_focus(), "Close button gets keyboard focus")
	await capture("guild-quest.png")
	start = player.position
	Input.action_press("move_down")
	await frames(10)
	check(player.position.distance_to(start) < 0.1, "Player cannot move behind dialogue")
	Input.action_release("move_down")
	await key_press(KEY_ESCAPE)
	check(not game.dialogue.is_open and player.controls_enabled, "Esc closes dialogue and restores movement")
	await key_press(KEY_E)
	check(game.dialogue.is_open, "Quest window can reopen")
	game.dialogue.close_button.pressed.emit()
	await frames()
	check(not game.dialogue.is_open and player.controls_enabled, "Close button restores movement")
	player.position = Vector2(384, 121)
	await frames()
	await key_press(KEY_E)
	check(not game.dialogue.is_open, "Cannot interact through rear of counter")
	player.position = Vector2(175, 320)
	Input.action_press("move_up")
	await frames(25)
	Input.action_release("move_up")
	await frames()
	check(player.position.y >= 314, "Bench blocks movement")
	player.position = Vector2(55, 350)
	Input.action_press("move_left")
	await frames(30)
	Input.action_release("move_left")
	await frames()
	check(player.position.x >= 34, "Left wall contains player")
	player.position = Vector2(710, 350)
	Input.action_press("move_right")
	await frames(30)
	Input.action_release("move_right")
	await frames()
	check(player.position.x <= 734, "Right wall contains player")
	var camera = player.get_node("Camera2D")
	check(camera.get_screen_center_position().x <= 448.1, "Camera stays inside right room boundary")
	player.position = Vector2(500, 430)
	Input.action_press("move_down")
	await frames(30)
	Input.action_release("move_down")
	await frames()
	check(player.position.y <= 448, "Bottom wall contains player")
	player.position = Vector2(280, 124)
	Input.action_press("move_up")
	await frames(30)
	Input.action_release("move_up")
	await frames()
	check(player.position.y >= 114, "Top wall contains player")
	print("RESULT: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
