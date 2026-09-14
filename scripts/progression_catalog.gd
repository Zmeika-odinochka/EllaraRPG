extends RefCounted
## Temporary P3 balance. Only completed, unique events grant experience.
const BASE_THRESHOLD := 10
const THRESHOLD_STEP := 5
const CANOPY_BASE_HALF := 0.10
const CANOPY_BONUS := 0.04
const CANOPY_MAX_HALF := 0.22
const ARCHIVE_HELP_LEVEL := 2
const STRENGTH_BATCH_LEVEL := 2
const BLADE_BONUS := 1
const EVENTS := {
	"work:planks": {"Сила":10,"Выносливость":5},
	"work:goods": {"Координация":6},
	"work:canopy": {"Координация":6,"Выносливость":5},
	"work:archive": {"Интеллект":10},
	"work:parcel": {"Координация":4},
	"discovery:road_cache": {"Восприятие":6},
	"combat:post_guard": {"Сила":4,"Выносливость":4,"Ловкость":10},
}
const BOOKS := {
	"book_observation": {"name":"Замечать незаметное","description":"Полевые заметки о следах и приметах. Автор начинает с простого: сначала смотри, потом делай выводы.","price":2,"intellect":1,"xp":{"Интеллект":10,"Восприятие":4},"skill":"","effect":"Интеллект +10 XP · Восприятие +4 XP","color":"788b70"},
	"book_knots": {"name":"Мера и узел","description":"Затёртая тетрадь с рисунками креплений. На полях отмечено, где держать верёвку, чтобы она не выскользнула.","price":3,"intellect":1,"xp":{"Координация":10,"Сила":5},"skill":"","effect":"Координация +10 XP · Сила +5 XP","color":"a38b60"},
	"book_blade": {"name":"Первый клинок","description":"Короткие уроки о хвате и направлении лезвия. Схемы требуют внимания: одного острого края недостаточно.","price":3,"intellect":2,"xp":{"Выносливость":3},"skill":"blade_basics","effect":"Основы клинка · Выносливость +3 XP","color":"777e98"},
}
const SKILLS := {"blade_basics":{"name":"Основы клинка","description":"+1 к урону экипированного кинжала."}}

static func threshold(value: int, base: int) -> int:
	return BASE_THRESHOLD+maxi(0,value-base)*THRESHOLD_STEP

static func canopy_half(coordination: int) -> float:
	return minf(CANOPY_MAX_HALF,CANOPY_BASE_HALF+maxi(0,coordination-1)*CANOPY_BONUS)

static func stat_effect(id: String, value: int) -> String:
	match id:
		"Координация": return "Зона навеса: %d%%" % roundi(canopy_half(value)*200)
		"Интеллект": return "Помощь в архиве" if value>=ARCHIVE_HELP_LEVEL else "С 2: помощь в архиве"
		"Сила": return "Доски: 4 связки вместо 5" if value>=STRENGTH_BATCH_LEVEL else "С 2: меньше связок досок"
		_: return "Опыт от дел и изучения"
