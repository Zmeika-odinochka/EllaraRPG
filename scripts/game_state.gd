extends Node
## Prototype session state. No writes to the role-playing campaign or disk saves.

signal quest_changed
enum QuestStage { AVAILABLE, ACCEPTED, MET_CORVIN }
var quest_stage: QuestStage = QuestStage.AVAILABLE
var pending_spawn: Vector2 = Vector2.INF


func _ready() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E], "journal": [KEY_J], "close_dialogue": [KEY_ESCAPE],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)


func accept_quest() -> void:
	if quest_stage != QuestStage.AVAILABLE:
		return
	quest_stage = QuestStage.ACCEPTED
	quest_changed.emit()


func meet_corvin() -> void:
	if quest_stage != QuestStage.ACCEPTED:
		return
	quest_stage = QuestStage.MET_CORVIN
	quest_changed.emit()


func objective() -> String:
	match quest_stage:
		QuestStage.AVAILABLE:
			return "Поговорить с Мирой о работе"
		QuestStage.ACCEPTED:
			return "Найти Корвина на центральной площади"
		_:
			return "Встреча с Корвином состоялась"
