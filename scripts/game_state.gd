extends Node
## Owns five persistent save slots and the current play session.

signal quest_changed
signal save_finished(slot: int, reason: String)
signal save_failed(message: String)

enum QuestStage { AVAILABLE, ACCEPTED, MET_CORVIN, WORK_DONE, APPROVED, COMPLETED }

const SAVE_VERSION: int = 2
const Catalog = preload("res://scripts/quest_catalog.gd")
# Initial video-game balance, independent of the role-playing campaign.
const BASE_STATS := {"Сила": 1, "Выносливость": 1, "Ловкость": 1, "Интеллект": 1, "Восприятие": 1, "Координация": 1, "Магия": 0, "Удача": 0}
var attributes: Dictionary = BASE_STATS.duplicate()
var inventory: Dictionary = {}
var side_quests: Dictionary = {"archive": "available", "parcel": "available"}
var npc_knowledge: Dictionary = {"mira": [], "corvin": []}
var work_trust: Dictionary = {"mira": 0, "corvin": 0}
const SLOT_COUNT: int = 5
const REWARD: int = 18
const GUILD_SCENE := "res://scenes/guild.tscn"
const SQUARE_SCENE := "res://scenes/square.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const VALID_SCENES := [GUILD_SCENE, SQUARE_SCENE]
const WORK_STEPS := {
	"planks": "Разобрать доски",
	"goods": "Расставить товар",
	"canopy": "Закрепить навес",
}

var save_directory: String = "user://saves"
var active_slot: int = 0
var quest_stage: QuestStage = QuestStage.AVAILABLE
var pending_spawn: Vector2 = Vector2.INF
var completed_steps: Array[String] = []
var personal_coins: int = 0
var play_seconds: float = 0.0
var game_active: bool = false
var transition_autosave_pending: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="):
			save_directory = argument.trim_prefix("--save-dir=")
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E], "journal": [KEY_J], "cancel_work": [KEY_Q],
		"pause": [KEY_ESCAPE], "inventory": [KEY_I],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)


func _process(delta: float) -> void:
	if game_active and not get_tree().paused:
		play_seconds += delta


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		autosave("exit")
		get_tree().quit()


func reset_game() -> void:
	attributes = BASE_STATS.duplicate()
	inventory = {}
	side_quests = {"archive": "available", "parcel": "available"}
	npc_knowledge = {"mira": [], "corvin": []}
	work_trust = {"mira": 0, "corvin": 0}
	quest_stage = QuestStage.AVAILABLE
	completed_steps.clear()
	personal_coins = 0
	play_seconds = 0.0
	pending_spawn = Vector2.INF
	transition_autosave_pending = false
	quest_changed.emit()


func start_new_game(slot: int) -> bool:
	if not valid_slot(slot):
		return false
	reset_game()
	active_slot = slot
	game_active = true
	pending_spawn = Vector2(384, 310)
	if not save_game(slot, GUILD_SCENE, pending_spawn, "new_game"):
		game_active = false
		active_slot = 0
		return false
	return get_tree().change_scene_to_file(GUILD_SCENE) == OK


func load_game(slot: int) -> bool:
	var data := read_slot(slot)
	if data.is_empty() or not apply_data(data):
		return false
	active_slot = slot
	game_active = true
	return get_tree().change_scene_to_file(str(data.location_scene)) == OK


func return_to_main_menu() -> bool:
	autosave("exit_to_menu")
	game_active = false
	get_tree().paused = false
	return get_tree().change_scene_to_file(MAIN_MENU_SCENE) == OK


func exit_game() -> void:
	autosave("exit")
	get_tree().quit()


func accept_quest() -> void:
	if quest_stage != QuestStage.AVAILABLE:
		return
	quest_stage = QuestStage.ACCEPTED
	quest_changed.emit()
	autosave("quest")


func meet_corvin() -> void:
	if quest_stage != QuestStage.ACCEPTED:
		return
	quest_stage = QuestStage.MET_CORVIN
	quest_changed.emit()
	autosave("quest")


func finish_work(step_id: String) -> bool:
	if quest_stage != QuestStage.MET_CORVIN or not WORK_STEPS.has(step_id) or step_id in completed_steps:
		return false
	completed_steps.append(step_id)
	if completed_steps.size() == WORK_STEPS.size():
		quest_stage = QuestStage.WORK_DONE
	quest_changed.emit()
	autosave("work")
	return true


func approve_work() -> void:
	if quest_stage != QuestStage.WORK_DONE:
		return
	quest_stage = QuestStage.APPROVED
	quest_changed.emit()
	autosave("quest")


func claim_reward() -> void:
	if quest_stage != QuestStage.APPROVED:
		return
	quest_stage = QuestStage.COMPLETED
	personal_coins += REWARD
	quest_changed.emit()
	autosave("reward")


func work_checklist() -> String:
	var lines: PackedStringArray = []
	for step_id in WORK_STEPS:
		lines.append(("✓ " if step_id in completed_steps else "• ") + WORK_STEPS[step_id])
	return "\n".join(lines)


func objective() -> String:
	if quest_stage in [QuestStage.AVAILABLE, QuestStage.COMPLETED]:
		for id in Catalog.QUESTS:
			if side_quests[id] in ["active", "packed", "ready"]:
				return side_objective(id)
	match quest_stage:
		QuestStage.AVAILABLE:
			return "Поговорить с Мирой о работе"
		QuestStage.ACCEPTED:
			return "Найти Корвина на центральной площади"
		QuestStage.MET_CORVIN:
			return "Подготовить площадь: %d / 3" % completed_steps.size()
		QuestStage.WORK_DONE:
			return "Сдать работу Корвину"
		QuestStage.APPROVED:
			return "Получить 18 медяков у Миры"
		_:
			return "Поручение выполнено · Получено 18 медяков"


func valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOT_COUNT


func slot_path(slot: int) -> String:
	return save_directory.path_join("slot_%d.json" % slot)


func ensure_save_directory() -> bool:
	var result := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_directory))
	return result == OK or result == ERR_ALREADY_EXISTS


func current_location() -> Dictionary:
	var scene_path := GUILD_SCENE
	var position := Vector2(384, 310)
	var scene := get_tree().current_scene
	if scene != null and scene.scene_file_path in VALID_SCENES:
		scene_path = scene.scene_file_path
		if scene.has_node("Actors/Player"):
			position = scene.get_node("Actors/Player").position
	return {"scene": scene_path, "position": position}


func save_game(slot: int, scene_path: String = "", position: Vector2 = Vector2.INF, reason: String = "manual") -> bool:
	if not valid_slot(slot) or not ensure_save_directory():
		save_failed.emit("Не удалось подготовить папку сохранений")
		return false
	var location := current_location()
	if scene_path.is_empty():
		scene_path = location.scene
	if not position.is_finite():
		position = location.position
	if scene_path not in VALID_SCENES:
		save_failed.emit("Неизвестная локация")
		return false
	var data := {
		"version": SAVE_VERSION,
		"saved_at": int(Time.get_unix_time_from_system()),
		"location_scene": scene_path,
		"player_position": [position.x, position.y],
		"quest_stage": int(quest_stage),
		"completed_steps": completed_steps.duplicate(),
		"personal_coins": personal_coins,
		"play_seconds": play_seconds,
		"attributes": attributes.duplicate(true),
		"inventory": inventory.duplicate(true),
		"side_quests": side_quests.duplicate(true),
		"npc_knowledge": npc_knowledge.duplicate(true),
		"work_trust": work_trust.duplicate(true),
	}
	var final_path := slot_path(slot)
	var temp_path := final_path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		save_failed.emit("Не удалось записать сохранение")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var final_absolute := ProjectSettings.globalize_path(final_path)
	var temp_absolute := ProjectSettings.globalize_path(temp_path)
	var backup_absolute := final_absolute + ".bak"
	if FileAccess.file_exists(final_path + ".bak"):
		DirAccess.remove_absolute(backup_absolute)
	if FileAccess.file_exists(final_path):
		var backup_result := DirAccess.rename_absolute(final_absolute, backup_absolute)
		if backup_result != OK:
			DirAccess.remove_absolute(temp_absolute)
			save_failed.emit("Не удалось заменить сохранение")
			return false
	var rename_result := DirAccess.rename_absolute(temp_absolute, final_absolute)
	if rename_result != OK:
		if FileAccess.file_exists(final_path + ".bak"):
			DirAccess.rename_absolute(backup_absolute, final_absolute)
		save_failed.emit("Не удалось завершить сохранение")
		return false
	if FileAccess.file_exists(final_path + ".bak"):
		DirAccess.remove_absolute(backup_absolute)
	active_slot = slot
	save_finished.emit(slot, reason)
	return true


func autosave(reason: String) -> bool:
	if not game_active or not valid_slot(active_slot):
		return false
	return save_game(active_slot, "", Vector2.INF, reason)


func read_slot(slot: int) -> Dictionary:
	if not valid_slot(slot) or not FileAccess.file_exists(slot_path(slot)):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
	if typeof(parsed) != TYPE_DICTIONARY or not validate_data(parsed):
		return {}
	return parsed


func validate_data(data: Dictionary) -> bool:
	if int(data.get("version", -1)) not in [1, SAVE_VERSION]:
		return false
	if str(data.get("location_scene", "")) not in VALID_SCENES:
		return false
	var position = data.get("player_position", [])
	if typeof(position) != TYPE_ARRAY or position.size() != 2:
		return false
	var stage := int(data.get("quest_stage", -1))
	if stage < QuestStage.AVAILABLE or stage > QuestStage.COMPLETED:
		return false
	if int(data.get("personal_coins", -1)) < 0 or float(data.get("play_seconds", -1)) < 0:
		return false
	if int(data.version) == SAVE_VERSION:
		for field in ["attributes", "inventory", "side_quests", "npc_knowledge", "work_trust"]:
			if typeof(data.get(field)) != TYPE_DICTIONARY:
				return false
		for id in Catalog.QUESTS:
			if data.side_quests.get(id, "available") not in ["available", "active", "packed", "ready", "completed"]:
				return false
	return true


func apply_data(data: Dictionary) -> bool:
	if not validate_data(data):
		return false
	attributes = data.get("attributes", BASE_STATS).duplicate(true)
	inventory = data.get("inventory", {}).duplicate(true)
	side_quests = data.get("side_quests", {"archive": "available", "parcel": "available"}).duplicate(true)
	npc_knowledge = data.get("npc_knowledge", {"mira": [], "corvin": []}).duplicate(true)
	work_trust = data.get("work_trust", {"mira": 0, "corvin": 0}).duplicate(true)
	quest_stage = int(data.quest_stage)
	completed_steps.clear()
	for step_id in data.get("completed_steps", []):
		if WORK_STEPS.has(str(step_id)) and str(step_id) not in completed_steps:
			completed_steps.append(str(step_id))
	personal_coins = int(data.personal_coins)
	play_seconds = float(data.play_seconds)
	pending_spawn = Vector2(float(data.player_position[0]), float(data.player_position[1]))
	transition_autosave_pending = false
	quest_changed.emit()
	return true


func delete_slot(slot: int) -> bool:
	if not valid_slot(slot):
		return false
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return true
	var result := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if result == OK and active_slot == slot:
		active_slot = 0
		game_active = false
	return result == OK


func accept_side_quest(id: String) -> bool:
	if not Catalog.QUESTS.has(id) or side_quests[id] != "available":
		return false
	side_quests[id] = "active"
	quest_changed.emit()
	autosave("quest")
	return true


func finish_side_work(id: String) -> bool:
	if not Catalog.QUESTS.has(id) or side_quests[id] != "active":
		return false
	side_quests[id] = "packed" if id == "parcel" else "ready"
	inventory[Catalog.QUESTS[id].item] = 1
	quest_changed.emit()
	autosave("work")
	return true


func deliver_parcel() -> bool:
	if side_quests.parcel != "packed" or not inventory.has("permit_parcel"):
		return false
	inventory.erase("permit_parcel")
	inventory.delivery_receipt = 1
	side_quests.parcel = "ready"
	if "permits_delivered" not in npc_knowledge.corvin:
		npc_knowledge.corvin.append("permits_delivered")
	work_trust.corvin += 1
	quest_changed.emit()
	autosave("quest")
	return true


func claim_side_reward(id: String) -> bool:
	if not Catalog.QUESTS.has(id) or side_quests[id] != "ready":
		return false
	side_quests[id] = "completed"
	personal_coins += int(Catalog.QUESTS[id].reward)
	inventory.erase("delivery_receipt" if id == "parcel" else "sorted_records")
	var fact: String = Catalog.QUESTS[id].knowledge
	if fact not in npc_knowledge.mira:
		npc_knowledge.mira.append(fact)
	work_trust.mira += 1
	quest_changed.emit()
	autosave("reward")
	return true


func side_objective(id: String) -> String:
	match str(side_quests[id]):
		"available": return "Можно взять у Миры"
		"active": return Catalog.QUESTS[id].objective
		"packed": return "Передать пакет Корвину на площади"
		"ready": return "Вернуться к Мире за оплатой"
		_: return "Завершено · %d медяков получено" % int(Catalog.QUESTS[id].reward)


func slots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in range(1, SLOT_COUNT + 1):
		var data := read_slot(slot)
		result.append({"slot": slot, "data": data, "occupied": not data.is_empty()})
	return result


func most_recent_slot() -> int:
	var best_slot := 0
	var best_time := -1
	for entry in slots():
		if entry.occupied and int(entry.data.saved_at) > best_time:
			best_time = int(entry.data.saved_at)
			best_slot = int(entry.slot)
	return best_slot


func location_name(scene_path: String) -> String:
	return "Центральная площадь" if scene_path == SQUARE_SCENE else "Гильдия"


func quest_summary(stage: int) -> String:
	match stage:
		QuestStage.AVAILABLE:
			return "До первого поручения"
		QuestStage.ACCEPTED:
			return "Найти Корвина"
		QuestStage.MET_CORVIN:
			return "Подготовка площади"
		QuestStage.WORK_DONE:
			return "Работа готова"
		QuestStage.APPROVED:
			return "Получить оплату"
		_:
			return "Поручение завершено"


func format_play_time(seconds: float) -> String:
	var total := maxi(0, int(seconds))
	return "%02d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]


func format_saved_at(unix_time: int) -> String:
	var zone := Time.get_time_zone_from_system()
	var date := Time.get_datetime_dict_from_unix_time(unix_time + int(zone.get("bias", 0)) * 60)
	return "%02d.%02d.%04d  %02d:%02d" % [date.day, date.month, date.year, date.hour, date.minute]
