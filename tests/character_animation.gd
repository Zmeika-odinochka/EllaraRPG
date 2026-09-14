extends SceneTree
## Render multiple walk phases and verify that the head stays anchored.

const Character = preload("res://scripts/pixel_character.gd")
var failures: int = 0


func _initialize() -> void:
	call_deferred("run_checks")


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func render_character(viewport: SubViewport, character: Node2D, phase: float) -> Image:
	character.step_time = phase
	character.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()


func run_checks() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Animation rendering check requires a graphical renderer; omit --headless.")
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(64, 64)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var character := Character.new()
	character.position = Vector2(32, 56)
	viewport.add_child(character)
	character.set_process(false)
	for facing in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
		character.facing = facing
		character.walking = false
		var idle: Image = await render_character(viewport, character, 0.0)
		var head := idle.get_region(Rect2i(20, 16, 24, 17)).get_data()
		var limbs := idle.get_region(Rect2i(20, 36, 24, 24)).get_data()
		var head_is_stable: bool = true
		var limbs_animate: bool = false
		character.walking = true
		for phase in [0.06, 0.12, 0.24, 0.36]:
			var frame: Image = await render_character(viewport, character, phase)
			head_is_stable = head_is_stable and frame.get_region(Rect2i(20, 16, 24, 17)).get_data() == head
			limbs_animate = limbs_animate or frame.get_region(Rect2i(20, 36, 24, 24)).get_data() != limbs
		check(head_is_stable, "Head stays fixed through walk phases facing " + str(facing))
		check(limbs_animate, "Limbs still animate facing " + str(facing))
	viewport.queue_free()
	await process_frame
	print("RESULT: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
