extends Node
## Owns five persistent save slots and the current play session.

signal quest_changed
signal save_finished(slot: int, reason: String)
signal save_failed(message: String)
signal notice(message: String)

enum QuestStage { AVAILABLE, ACCEPTED, MET_CORVIN, WORK_DONE, APPROVED, COMPLETED }

const SAVE_VERSION: int = 6
const Progress = preload("res://scripts/progression_catalog.gd")
var attribute_xp: Dictionary = {}
var attribute_thresholds: Dictionary = {}
var credited_events: Array[String] = []
var studied_books: Array[String] = []
var skills: Array[String] = []
const City = preload("res://scripts/city_catalog.gd")
const Weapons = preload("res://scripts/weapon_catalog.gd")
var equipped_weapon := ""
var post_guard_defeated := false
const Exploration = preload("res://scripts/exploration_catalog.gd")
var discoveries: Array[String] = []
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
const OUTSKIRTS_SCENE := "res://scenes/outskirts.tscn"
const OUTPOST_SCENE := "res://scenes/outpost.tscn"
const VALID_SCENES := [GUILD_SCENE, SQUARE_SCENE, OUTSKIRTS_SCENE, OUTPOST_SCENE, City.MARKET, City.CRAFT, City.TEMPLE, City.GATES, City.ARMORY, City.BOOKSHOP]
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
var tracked_quest: String = ""


func _ready() -> void:
	reset_progression()
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
		"work_timing": [KEY_SPACE], "work_choice_1": [KEY_1],
		"work_choice_2": [KEY_2], "work_choice_3": [KEY_3],
		"page_up": [KEY_PAGEUP], "page_down": [KEY_PAGEDOWN],
	}
	# Some Windows input sources send an unusable scan code but a valid logical key.
	# Keep physical positions for any layout and logical EN/RU fallbacks for those sources.
	var russian_keys := {KEY_A: "Ф", KEY_D: "В", KEY_W: "Ц", KEY_S: "Ы",
		KEY_E: "У", KEY_J: "О", KEY_Q: "Й", KEY_I: "Ш"}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
			add_logical_binding(action, key)
			if russian_keys.has(key):
				add_logical_binding(action, str(russian_keys[key]).unicode_at(0))


func add_logical_binding(action: String, key: int) -> void:
	var event := InputEventKey.new()
	event.keycode = key
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
	equipped_weapon = ""
	post_guard_defeated = false
	discoveries.clear()
	tracked_quest = ""
	attributes = BASE_STATS.duplicate()
	reset_progression()
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
	award_event("work:"+step_id)
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
	var selected := current_tracked_quest()
	if selected == "fair":
		return main_objective()
	if selected in Catalog.QUESTS:
		return side_objective(selected)
	return "Поговорить с Мирой о работе" if quest_stage == QuestStage.AVAILABLE else "Все поручения завершены"


func main_objective() -> String:
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
		"tracked_quest": tracked_quest,
		"discoveries": discoveries.duplicate(),
		"post_guard_defeated": post_guard_defeated,
		"equipped_weapon": equipped_weapon,
		"attribute_xp": attribute_xp.duplicate(),
		"attribute_thresholds": attribute_thresholds.duplicate(),
		"credited_events": credited_events.duplicate(),
		"studied_books": studied_books.duplicate(),
		"skills": skills.duplicate(),
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
	var audio := get_node_or_null("/root/Soundscape")
	if audio and reason in ["purchase","book","work","discovery"]: audio.play({"purchase":"purchase","book":"item","work":"work","discovery":"item"}[reason])
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
	if int(data.get("version", -1)) not in [1, 2, 3, 4, 5, SAVE_VERSION]:
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
	if int(data.version) >= 2:
		for field in ["attributes", "inventory", "side_quests", "npc_knowledge", "work_trust"]:
			if typeof(data.get(field)) != TYPE_DICTIONARY:
				return false
		for id in Catalog.QUESTS:
			if data.side_quests.get(id, "available") not in ["available", "active", "packed", "ready", "completed"]:
				return false
	if int(data.version) >= 3:
		if typeof(data.get("discoveries")) != TYPE_ARRAY: return false
		for id in data.discoveries:
			if typeof(id) != TYPE_STRING or id not in Exploration.DISCOVERIES: return false
	if int(data.version) >= 4 and typeof(data.get("post_guard_defeated")) != TYPE_BOOL:
		return false
	if int(data.version) >= 5:
		var weapon = data.get("equipped_weapon")
		if typeof(weapon) != TYPE_STRING or weapon not in ["", Weapons.DAGGER_ID]: return false
		if data.inventory.has(Weapons.DAGGER_ID):
			var count = data.inventory[Weapons.DAGGER_ID]
			if typeof(count) not in [TYPE_INT,TYPE_FLOAT] or float(count) != 1.0: return false
		if weapon != "" and not data.inventory.has(weapon): return false
	if int(data.version) >= 6 and not validate_progression(data): return false
	return true


func apply_data(data: Dictionary) -> bool:
	if not validate_data(data):
		return false
	equipped_weapon = data.equipped_weapon if int(data.version) >= 5 else ""
	post_guard_defeated = data.post_guard_defeated if int(data.version) >= 4 else false
	discoveries.clear()
	if int(data.version) >= 3:
		for id in data.discoveries:
			if id not in discoveries: discoveries.append(id)
	tracked_quest = str(data.get("tracked_quest", ""))
	if tracked_quest != "fair" and tracked_quest not in Catalog.QUESTS:
		tracked_quest = ""
	attributes = data.get("attributes", BASE_STATS).duplicate(true)
	for id in BASE_STATS: attributes[id] = int(attributes.get(id,BASE_STATS[id]))
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
	load_progression(data)
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
	award_event("work:"+id)
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


func journal_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if quest_stage != QuestStage.AVAILABLE:
		entries.append({"id": "fair", "title": "Подготовка ярмарки", "reward": REWARD,
			"completed": quest_stage == QuestStage.COMPLETED,
			"status": quest_summary(quest_stage), "objective": main_objective(),
			"details": "Подготовить площадь до завтрашней ярмарки.\n\n" + (work_checklist() + "\n\n" if quest_stage >= QuestStage.MET_CORVIN else "") + "Приёмка у Корвина. Оплата у Миры."})
	for id in Catalog.QUESTS:
		var status: String = side_quests[id]
		if status == "available":
			continue
		entries.append({"id": id, "title": Catalog.QUESTS[id].title, "reward": Catalog.QUESTS[id].reward,
			"completed": status == "completed", "objective": side_objective(id),
			"status": {"active": "В работе", "packed": "Готово к доставке", "ready": "Ожидает оплаты", "completed": "Завершено"}.get(status, "В работе"),
			"details": Catalog.QUESTS[id].offer})
	return entries


func current_tracked_quest() -> String:
	var first := ""
	for entry in journal_entries():
		if entry.completed:
			continue
		if entry.id == tracked_quest:
			return tracked_quest
		if first.is_empty():
			first = entry.id
	return first


func track_quest(id: String) -> bool:
	for entry in journal_entries():
		if entry.id == id and not entry.completed:
			tracked_quest = id
			quest_changed.emit()
			autosave("tracking")
			return true
	return false


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
	if scene_path in City.TITLES: return City.TITLES[scene_path]
	return {GUILD_SCENE: "Гильдия", SQUARE_SCENE: "Центральная площадь", OUTSKIRTS_SCENE: "Старая дорога", OUTPOST_SCENE: "Дозорный пост"}.get(scene_path, "Неизвестное место")

func buy_dagger() -> bool:
	var location := current_location()
	if get_tree().paused or location.scene != City.ARMORY or location.position.distance_to(Vector2(384,222))>40: return false
	if inventory.has(Weapons.DAGGER_ID) or personal_coins<Weapons.DAGGER.price: return false
	personal_coins -= Weapons.DAGGER.price
	inventory[Weapons.DAGGER_ID] = 1
	if game_active and valid_slot(active_slot) and not autosave("purchase"):
		personal_coins += Weapons.DAGGER.price
		inventory.erase(Weapons.DAGGER_ID)
		return false
	quest_changed.emit()
	notice.emit("Получен простой кинжал")
	return true

func set_equipped_weapon(id: String) -> bool:
	if get_tree().paused or id not in ["",Weapons.DAGGER_ID]: return false
	if id != "" and inventory.get(id,0) != 1: return false
	if equipped_weapon == id: return true
	var previous := equipped_weapon
	equipped_weapon = id
	if game_active and valid_slot(active_slot) and not autosave("equipment"):
		equipped_weapon = previous
		return false
	quest_changed.emit()
	return true

func weapon_base_damage() -> int:
	return Weapons.base_damage(equipped_weapon)+(Progress.BLADE_BONUS if equipped_weapon==Weapons.DAGGER_ID and "blade_basics" in skills else 0)


func discover(id: String) -> bool:
	if id in discoveries or id not in Exploration.DISCOVERIES: return false
	var definition: Dictionary = Exploration.DISCOVERIES[id]
	var location := current_location()
	if location.scene != definition.scene or location.position.distance_to(definition.at) > 38.0: return false
	if id == "shortcut" and location.position.y >= 260: return false
	discoveries.append(id)
	award_event("discovery:"+id)
	if definition.has("item"): inventory[definition.item] = int(inventory.get(definition.item, 0)) + 1
	quest_changed.emit()
	autosave("discovery")
	return true


func reset_progression() -> void:
	attribute_xp.clear()
	attribute_thresholds.clear()
	credited_events.clear()
	studied_books.clear()
	skills.clear()
	for id in BASE_STATS:
		attribute_xp[id] = 0
		attribute_thresholds[id] = Progress.threshold(int(attributes.get(id,BASE_STATS[id])),BASE_STATS[id])

func award_event(id: String) -> bool:
	if id not in Progress.EVENTS or id in credited_events: return false
	credited_events.append(id)
	grant_xp(Progress.EVENTS[id])
	return true

func grant_xp(rewards: Dictionary, announce: bool = true) -> void:
	var gains: PackedStringArray = []
	for id in rewards:
		attribute_xp[id] = int(attribute_xp.get(id,0))+int(rewards[id])
		var previous := int(attributes[id])
		while attribute_xp[id] >= attribute_thresholds[id]:
			attribute_xp[id] -= attribute_thresholds[id]
			attributes[id] = int(attributes[id])+1
			attribute_thresholds[id] = Progress.threshold(attributes[id],BASE_STATS[id])
		gains.append("%s ↑ %d" % [id,int(attributes[id])] if attributes[id]>previous else "%s +%d XP" % [id,int(rewards[id])])
	if announce: notice.emit(" · ".join(gains))

func validate_progression(data: Dictionary) -> bool:
	for field in ["attribute_xp","attribute_thresholds"]:
		if typeof(data.get(field)) != TYPE_DICTIONARY: return false
	for id in BASE_STATS:
		for field in ["attributes","attribute_xp","attribute_thresholds"]:
			var value = data[field].get(id)
			if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)) or float(value)!=floorf(float(value)): return false
		if int(data.attributes[id])<BASE_STATS[id] or int(data.attribute_xp[id])<0 or int(data.attribute_thresholds[id])<=0: return false
		if int(data.attribute_xp[id])>=int(data.attribute_thresholds[id]): return false
	for field in ["credited_events","studied_books","skills"]:
		if typeof(data.get(field)) != TYPE_ARRAY: return false
		var seen := {}
		for id in data[field]:
			if typeof(id)!=TYPE_STRING or seen.has(id): return false
			seen[id] = true
			if field=="credited_events" and id not in Progress.EVENTS: return false
			if field=="studied_books" and (id not in Progress.BOOKS or data.inventory.get(id,0)!=1): return false
			if field=="skills" and id not in Progress.SKILLS: return false
	for id in Progress.BOOKS:
		if data.inventory.has(id) and data.inventory[id]!=1: return false
		if id in data.studied_books and Progress.BOOKS[id].skill!="" and Progress.BOOKS[id].skill not in data.skills: return false
	if "blade_basics" in data.skills and "book_blade" not in data.studied_books: return false
	return true

func load_progression(data: Dictionary) -> void:
	reset_progression()
	if int(data.version)>=6:
		for id in BASE_STATS:
			attribute_xp[id] = int(data.attribute_xp[id])
			attribute_thresholds[id] = int(data.attribute_thresholds[id])
		for id in data.credited_events: credited_events.append(id)
		for id in data.studied_books: studied_books.append(id)
		for id in data.skills: skills.append(id)
	else:
		# Old accomplishments stay accomplished: no retrospective XP or replay farming.
		for id in completed_steps: credited_events.append("work:"+id)
		for id in Catalog.QUESTS:
			if side_quests.get(id,"available") in ["packed","ready","completed"]: credited_events.append("work:"+id)
		if post_guard_defeated: credited_events.append("combat:post_guard")
		if "road_cache" in discoveries: credited_events.append("discovery:road_cache")

func buy_book(id: String) -> bool:
	var location := current_location()
	if get_tree().paused or id not in Progress.BOOKS or location.scene!=City.BOOKSHOP or location.position.distance_to(Vector2(384,222))>40: return false
	var price := int(Progress.BOOKS[id].price)
	if inventory.has(id) or personal_coins<price: return false
	personal_coins -= price
	inventory[id] = 1
	if game_active and valid_slot(active_slot) and not autosave("purchase"):
		personal_coins += price
		inventory.erase(id)
		return false
	quest_changed.emit()
	notice.emit("Книга в сумке: "+Progress.BOOKS[id].name)
	return true

func study_book(id: String) -> bool:
	if get_tree().paused or id not in Progress.BOOKS or inventory.get(id,0)!=1 or id in studied_books: return false
	var book: Dictionary = Progress.BOOKS[id]
	if int(attributes.get("Интеллект",1))<book.intellect: return false
	var before := [attributes.duplicate(),attribute_xp.duplicate(),attribute_thresholds.duplicate(),skills.duplicate()]
	studied_books.append(id)
	grant_xp(book.xp,false)
	if book.skill!="" and book.skill not in skills: skills.append(book.skill)
	if game_active and valid_slot(active_slot) and not autosave("book"):
		studied_books.erase(id)
		attributes = before[0]
		attribute_xp = before[1]
		attribute_thresholds = before[2]
		skills.assign(before[3])
		return false
	quest_changed.emit()
	notice.emit("Изучено: "+book.name)
	for stat in book.xp:
		if attributes[stat]>before[0][stat]: notice.emit("%s ↑ %d" % [stat,int(attributes[stat])])
	if book.skill!="": notice.emit("Навык: "+Progress.SKILLS[book.skill].name)
	return true

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
