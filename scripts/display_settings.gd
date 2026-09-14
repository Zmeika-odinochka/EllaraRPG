extends Node
## Video preferences are separate from game saves. Preview is never written to disk.
const BASE_SIZE := Vector2i(640, 360)
const RESOLUTIONS := [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
const Menu = preload("res://scripts/display_menu.gd")
var config_path := "user://display.cfg"
var resolution := Vector2i(1280, 720)
var fullscreen := false
var menu: CanvasLayer
var previewing := false
var candidate_resolution := Vector2i.ZERO
var candidate_fullscreen := false
var previous_window: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.min_size = BASE_SIZE
	# Integration tests must not read or overwrite the player's display preferences.
	if not "--script" in OS.get_cmdline_args() and DisplayServer.get_name() != "headless":
		load_preferences()
		apply_window(resolution, fullscreen)
	menu = Menu.new()
	add_child(menu)

func usable_screen() -> Rect2i:
	if DisplayServer.get_name() == "headless": return Rect2i(0, 0, 1920, 1080)
	return DisplayServer.screen_get_usable_rect(get_tree().root.current_screen)

func fits_window(value: Vector2i) -> bool:
	var usable := usable_screen().size - Vector2i(16, 48)
	return value.x <= usable.x and value.y <= usable.y

func fitting_resolution(requested: Vector2i) -> Vector2i:
	var result := BASE_SIZE
	for value in RESOLUTIONS:
		if value.x <= requested.x and fits_window(value): result = value
	return result

func load_preferences() -> void:
	resolution = Vector2i(1280, 720)
	fullscreen = false
	var config := ConfigFile.new()
	if config.load(config_path) == OK:
		var width = config.get_value("display", "width", 1280)
		var height = config.get_value("display", "height", 720)
		var full = config.get_value("display", "fullscreen", false)
		if typeof(width) == TYPE_INT and typeof(height) == TYPE_INT:
			var saved := Vector2i(width, height)
			if saved in RESOLUTIONS: resolution = saved
		if typeof(full) == TYPE_BOOL: fullscreen = full
	resolution = fitting_resolution(resolution)

func apply_window(value: Vector2i, full: bool) -> void:
	if DisplayServer.get_name() == "headless": return
	var window := get_tree().root
	window.mode = Window.MODE_WINDOWED
	window.size = value
	window.position = usable_screen().position + (usable_screen().size - value) / 2
	if full: window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN

func begin_preview(value: Vector2i, full: bool) -> bool:
	if previewing or value not in RESOLUTIONS or (not full and not fits_window(value)): return false
	var window := get_tree().root
	previous_window = {"size": window.size, "position": window.position, "mode": window.mode}
	candidate_resolution = value
	candidate_fullscreen = full
	previewing = true
	apply_window(value, full)
	return true

func confirm_preview() -> bool:
	if not previewing: return false
	var config := ConfigFile.new()
	config.set_value("display", "width", candidate_resolution.x)
	config.set_value("display", "height", candidate_resolution.y)
	config.set_value("display", "fullscreen", candidate_fullscreen)
	if config.save(config_path) != OK:
		cancel_preview()
		return false
	resolution = candidate_resolution
	fullscreen = candidate_fullscreen
	previewing = false
	previous_window.clear()
	return true

func cancel_preview() -> void:
	if not previewing: return
	if DisplayServer.get_name() != "headless":
		var window := get_tree().root
		window.mode = Window.MODE_WINDOWED
		window.size = previous_window.size
		window.position = previous_window.position
		window.mode = previous_window.mode
	previewing = false
	previous_window.clear()

func open_menu() -> void:
	menu.open()
