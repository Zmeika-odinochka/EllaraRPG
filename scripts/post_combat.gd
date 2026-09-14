extends Node2D
## One bounded encounter. Only victory persists; unfinished attempts reset together.
const UI = preload("res://scripts/ui_theme.gd")
const Layout = preload("res://scripts/exploration_layout.gd")
const HOME := Vector2(280, 208)
const RETRY := Vector2(144, 240)
const TERRITORY := Rect2(112, 80, 224, 176)
const MAX_HEALTH := 100
const ENEMY_HEALTH := 3
const ATTACK_RANGE := 42.0
const WINDUP := 0.72
const STRIKE := 0.16
const RECOVERY := 0.95
var world: Node2D
var player: CharacterBody2D
var state: Node
var enemy: CharacterBody2D
var enemy_art: Node2D
var effects: Node2D
var ground_effects: Node2D
var navigation := AStarGrid2D.new()
var health := MAX_HEALTH
var enemy_health := ENEMY_HEALTH
var phase := "idle"
var phase_time := 0.0
var engaged := false
var defeated := false
var enemy_direction := Vector2.LEFT
var strike_origin := Vector2.ZERO
var swing_direction := Vector2.RIGHT
var swing_time := 0.0
var swing_resolved := false
var invulnerability := 0.0
var enemy_flash := 0.0
var player_flash := 0.0
var focus_active := true
var blocked_last := true
var rearm_time := 0.2
var pointer_held := false
var strikes_started := 0
var animation_time := 0.0
var hud: CanvasLayer
var health_label: Label
var hint: Label
var health_bar: Panel
var health_fill: ColorRect
var defeat_panel: PanelContainer
var defeat_overlay: Control
var retry_button: Button
var exit_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world = get_parent()
	player = world.player
	state = world.state
	navigation.region = Rect2i(7, 5, 14, 11)
	navigation.cell_size = Vector2(16, 16)
	navigation.offset = Vector2(8, 8)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	for y in range(5, 16):
		for x in range(7, 21):
			navigation.set_point_solid(Vector2i(x,y), not Layout.safe_feet(Vector2(x*16+8,y*16+8), true, true))
	enemy = CharacterBody2D.new()
	# Choose before registering the collider; a legacy hero may stand at HOME.
	enemy.position = Vector2(168,208) if player.position.distance_to(HOME)<26 else HOME
	enemy.collision_layer = 2
	enemy.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	# Match the footprint used by Layout.safe_feet and the navigation grid.
	rectangle.size = Vector2(14, 8)
	shape.shape = rectangle
	shape.position.y = -4
	enemy.add_child(shape)
	world.actors.add_child(enemy)
	player.collision_mask |= 2
	enemy_art = preload("res://scripts/post_combat_art.gd").new()
	enemy_art.combat = self
	enemy.add_child(enemy_art)
	effects = preload("res://scripts/post_combat_art.gd").new()
	effects.combat = self
	effects.effects_only = true
	effects.z_index = 4
	world.add_child(effects)
	ground_effects = preload("res://scripts/post_combat_art.gd").new()
	ground_effects.combat = self
	ground_effects.effects_only = true
	ground_effects.ground_only = true
	world.add_child(ground_effects)
	world.move_child(ground_effects, world.actors.get_index())
	build_ui()
	if state.post_guard_defeated:
		phase = "cleared"
		enemy.hide()
		enemy.collision_layer = 0
		enemy.collision_mask = 0

func build_ui() -> void:
	hud = CanvasLayer.new()
	hud.layer = 6
	add_child(hud)
	var controls := Control.new()
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(controls)
	health_label = UI.label("", 11)
	health_label.position = Vector2(12, 284)
	health_label.size = Vector2(180, 18)
	controls.add_child(health_label)
	health_bar = Panel.new()
	health_bar.position = Vector2(12, 307)
	health_bar.size = Vector2(126, 7)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.add_theme_stylebox_override("panel", UI.panel_style("152427", "536359", 0))
	controls.add_child(health_bar)
	health_fill = ColorRect.new()
	health_fill.position = Vector2(1,1)
	health_fill.size = Vector2(124,5)
	health_fill.color = Color("aa6856")
	health_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.add_child(health_fill)
	hint = UI.label("", 11, UI.MUTED)
	hint.position = Vector2(12, 326)
	hint.size = Vector2(415, 22)
	controls.add_child(hint)
	var layer := CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	defeat_overlay = Control.new()
	defeat_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(defeat_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03,0.04,0.04,0.8)
	defeat_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	defeat_overlay.add_child(center)
	defeat_panel = UI.box(UI.DARK, 18)
	defeat_panel.custom_minimum_size.x = 420
	center.add_child(defeat_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	defeat_panel.add_child(column)
	column.add_child(UI.label("НЕ УДАЛОСЬ УСТОЯТЬ", 19, UI.GOLD))
	column.add_child(UI.label("Деньги, вещи и открытия остаются с тобой.\nПри новой попытке здоровье восстановится\nу тебя и у ползуна.", 13))
	retry_button = UI.button("Повторить · у входа в караульную")
	retry_button.pressed.connect(func(): recover(RETRY))
	column.add_child(retry_button)
	exit_button = UI.button("Вернуться к выходу поста")
	exit_button.pressed.connect(func(): recover(Vector2(384, 392)))
	column.add_child(exit_button)
	defeat_overlay.hide()

func blocked() -> bool:
	return get_tree().paused or not focus_active or not world.can_manual_save()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focus_active = false
		cancel_swing()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focus_active = true
		rearm_time = 0.2

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_held = event.pressed

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var target: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
		if start_swing(target): get_viewport().set_input_as_handled()

func start_swing(target: Vector2) -> bool:
	if blocked() or defeated or rearm_time > 0 or swing_time > 0 or not player.controls_enabled: return false
	swing_direction = (target - player.position).normalized()
	if swing_direction.is_zero_approx(): swing_direction = player.facing
	player.facing = Vector2(signf(swing_direction.x),0) if absf(swing_direction.x)>absf(swing_direction.y) else Vector2(0,signf(swing_direction.y))
	swing_time = 0.5
	swing_resolved = false
	strikes_started += 1
	return true

func cancel_swing() -> void:
	swing_time = 0.0
	swing_resolved = true
	rearm_time = 0.2

func _physics_process(delta: float) -> void:
	var is_blocked := blocked()
	if is_blocked:
		if not blocked_last: cancel_swing()
		blocked_last = true
		player.combat_movement_scale = 0.0 if not focus_active or defeated else 1.0
	else:
		animation_time += delta
		if blocked_last: rearm_time = 0.2
		blocked_last = false
		if not pointer_held: rearm_time = maxf(0, rearm_time-delta)
		invulnerability = maxf(0, invulnerability-delta)
		player_flash = maxf(0, player_flash-delta)
		enemy_flash = maxf(0, enemy_flash-delta)
		if swing_time > 0:
			swing_time = maxf(0, swing_time-delta)
			if swing_time <= 0.38 and not swing_resolved:
				swing_resolved = true
				resolve_swing()
		player.combat_movement_scale = 0.55 if swing_time > 0.18 else 1.0
		if not defeated and phase != "cleared": tick_enemy(delta)
	player.appearance.modulate = Color("ffb49e") if player_flash > 0 else Color.WHITE
	var near: bool = player.position.distance_to(HOME) < 205 and phase != "cleared"
	hud.visible = not is_blocked and not defeated and (near or engaged)
	health_label.text = "Филипп · %d / %d" % [health, MAX_HEALTH]
	health_fill.size.x = roundf(124.0*health/MAX_HEALTH)
	hint.text = "Ползун отступает · здоровье восстанавливается" if phase == "returning" else "ЛКМ — удар к указателю · можно отступить в проход"
	enemy_art.queue_redraw()
	effects.queue_redraw()
	ground_effects.queue_redraw()

func line_clear(from: Vector2, to: Vector2) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(from+Vector2(0,-4), to+Vector2(0,-4), 1)
	ray.exclude = [player.get_rid(), enemy.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func in_arc(origin: Vector2, target: Vector2, direction: Vector2, radius: float) -> bool:
	var offset := target-origin
	return offset.length() <= radius and (offset.length()<8 or offset.normalized().dot(direction)>=0.45) and line_clear(origin,target)

func resolve_swing() -> void:
	if phase in ["cleared", "returning"]: return
	if not in_arc(player.position, enemy.position, swing_direction, ATTACK_RANGE): return
	enemy_health -= 1
	enemy_flash = 0.18
	engaged = true
	if enemy_health <= 0:
		phase = "cleared"
		engaged = false
		health = MAX_HEALTH
		enemy.collision_layer = 0
		enemy.collision_mask = 0
		state.post_guard_defeated = true
		state.autosave("combat")
		world.hud.show_toast("Караульная затихла", 3.0)
	# Damage does not cancel a telegraphed enemy strike: repeated clicks cannot stunlock it.

func tick_enemy(delta: float) -> void:
	var distance: float = enemy.position.distance_to(player.position)
	if phase == "returning":
		move_enemy(HOME, delta)
		if enemy.position.distance_to(HOME) < 4:
			enemy.position = HOME
			phase = "idle"
			enemy_health = ENEMY_HEALTH
		return
	if engaged and not TERRITORY.has_point(player.position):
		engaged = false
		phase = "returning"
		health = MAX_HEALTH
		world.hud.show_toast("Удалось отступить", 2.4)
		return
	if not engaged:
		if distance < 108 and TERRITORY.has_point(player.position) and line_clear(enemy.position,player.position):
			engaged = true
			phase = "chase"
		else: return
	match phase:
		"idle", "chase":
			phase = "chase"
			if distance <= 33 and line_clear(enemy.position,player.position):
				enemy_direction = (player.position-enemy.position).normalized()
				strike_origin = enemy.position
				phase = "windup"
				phase_time = WINDUP
			else: move_enemy(player.position, delta)
		"windup":
			phase_time -= delta
			if phase_time <= 0:
				phase = "strike"
				phase_time = STRIKE
				if in_arc(strike_origin,player.position,enemy_direction,43): hurt_player()
		"strike":
			phase_time -= delta
			if phase_time <= 0:
				phase = "recovery"
				phase_time = RECOVERY
		"recovery":
			phase_time -= delta
			if phase_time <= 0: phase = "chase"

func move_enemy(target: Vector2, _delta: float) -> void:
	var from_cell := Vector2i((enemy.position/16).floor())
	var to_cell := Vector2i((target/16).floor())
	if not navigation.region.has_point(from_cell) or not navigation.region.has_point(to_cell): return
	if navigation.is_point_solid(from_cell) or navigation.is_point_solid(to_cell): return
	var path := navigation.get_point_path(from_cell,to_cell)
	var next_point := target
	if path.size()>1: next_point = path[1]
	enemy.velocity = enemy.position.direction_to(next_point)*48.0
	if enemy.position.distance_to(target) < 3: enemy.velocity = Vector2.ZERO
	enemy.move_and_slide()
	if not enemy.velocity.is_zero_approx(): enemy_direction = enemy.velocity.normalized()

func hurt_player() -> void:
	if blocked() or defeated or invulnerability>0: return
	health = maxi(0, health-25)
	invulnerability = 0.65
	player_flash = 0.22
	if health > 0: return
	defeated = true
	world.busy = true
	player.set_controls_enabled(false)
	cancel_swing()
	defeat_overlay.show()
	UI.trap_focus(defeat_panel)
	retry_button.grab_focus()

func recover(at: Vector2) -> void:
	if not defeated or get_tree().paused: return
	defeated = false
	world.busy = false
	defeat_overlay.hide()
	health = MAX_HEALTH
	enemy_health = ENEMY_HEALTH
	enemy.position = HOME
	phase = "idle"
	phase_time = 0
	engaged = false
	player.position = at
	player.set_controls_enabled(true)
	player.combat_movement_scale = 1
	invulnerability = 1
	player_flash = 0
	cancel_swing()
