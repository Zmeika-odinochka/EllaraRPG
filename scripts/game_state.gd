extends Node
## Prototype session state. No writes to the role-playing campaign or disk saves.

signal quest_changed
enum QuestStage { AVAILABLE, ACCEPTED, MET_CORVIN, WORK_DONE, APPROVED, COMPLETED }
const REWARD: int = 18
const WORK_STEPS := {
	"planks": "Разобрать доски",
	"goods": "Расставить товар",
	"canopy": "Закрепить навес",
}
var quest_stage: QuestStage = QuestStage.AVAILABLE
var pending_spawn: Vector2 = Vector2.INF
var completed_steps: Array[String] = []
var personal_coins: int = 0


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


func finish_work(step_id: String) -> bool:
	if quest_stage != QuestStage.MET_CORVIN or not WORK_STEPS.has(step_id) or step_id in completed_steps:
		return false
	completed_steps.append(step_id)
	if completed_steps.size() == WORK_STEPS.size():
		quest_stage = QuestStage.WORK_DONE
	quest_changed.emit()
	return true


func approve_work() -> void:
	if quest_stage != QuestStage.WORK_DONE:
		return
	quest_stage = QuestStage.APPROVED
	quest_changed.emit()


func claim_reward() -> void:
	if quest_stage != QuestStage.APPROVED:
		return
	quest_stage = QuestStage.COMPLETED
	personal_coins += REWARD
	quest_changed.emit()


func work_checklist() -> String:
	var lines: PackedStringArray = []
	for step_id in WORK_STEPS:
		lines.append(("✓ " if step_id in completed_steps else "• ") + WORK_STEPS[step_id])
	return "\n".join(lines)


func objective() -> String:
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
