extends RefCounted
const SQUARE := "res://scenes/square.tscn"
const GUILD := "res://scenes/guild.tscn"
const MARKET := "res://scenes/market.tscn"
const CRAFT := "res://scenes/craft.tscn"
const TEMPLE := "res://scenes/temple.tscn"
const GATES := "res://scenes/south_gates.tscn"
const ARMORY := "res://scenes/armory.tscn"
const ROAD := "res://scenes/outskirts.tscn"
const SCENES := [MARKET, CRAFT, TEMPLE, GATES, ARMORY]
const TITLES := {MARKET:"Торговая улица", CRAFT:"Ремесленный квартал", TEMPLE:"Храмовая улица", GATES:"Южные ворота", ARMORY:"Оружейная «У старого клинка»"}
const NPCS := {
	"irridia": {"name":"Ирридия", "lines":["У города хорошая память на долги. На добрые дела — похуже. Забирай плату, пока тебя помнят.","За восточными навесами начинается торговая улица. Если решишь покупать оружие, смотри на клинок, а не на улыбку продавца."]},
	"celesta": {"name":"Селеста", "lines":["Я заняла стол. Самый полезный вклад в любое возвращение — место, куда можно сесть.","На храмовой улице сегодня тихо. Даже торговцы там спорят шёпотом. Почти чудо."]},
	"astra": {"name":"Астра", "lines":["Проверь снаряжение до ворот. На дороге неудобно выяснять, что всё нужное осталось в сумке.","Я пока здесь. Вернёшься — расскажешь, как выглядит дорога за стенами."]},
	"smith": {"name":"Оружейник Рем", "lines":["Этот кинжал без украшений. Сталь хорошая, рукоять не скользит. Двадцать четыре медяка — и он твой."]},
	"hawker": {"name":"Торговка", "lines":["Соль — в сухой мешок, яблоки — наверх. А оружейная вон там, под вывеской с клинком."]},
	"artisan": {"name":"Подмастерье", "lines":["Не наступай в угольную пыль. Потом весь день будешь оставлять следы — и мастер сразу узнает, где ты ходил."]},
	"pilgrim": {"name":"Паломница", "lines":["Здесь оставляют свет за тех, кто ещё в пути. Не обязательно знать их имена."]},
	"guard": {"name":"Стражник", "lines":["За воротами старая дорога. У поста давно не было смены. Без оружия я бы держался осторожнее — но выход свободный."]}
}

static func portal(at: Vector2, title: String, scene: String, spawn: Vector2) -> Dictionary:
	return {"at":at,"label":title,"scene":scene,"spawn":spawn}
static func npc(id: String, at: Vector2, actor_at: Vector2 = Vector2.INF) -> Dictionary:
	return {"at":at,"label":NPCS[id].name,"npc":id,"actor_at":at if not actor_at.is_finite() else actor_at}
static func inspect(at: Vector2, title: String, body: String) -> Dictionary:
	return {"at":at,"label":title,"text":body}

static func actions(scene: String) -> Array[Dictionary]:
	match scene:
		GUILD: return [npc("irridia",Vector2(548,284),Vector2(559,288)),npc("celesta",Vector2(634,284),Vector2(623,288)),npc("astra",Vector2(591,383),Vector2(591,352))]
		SQUARE: return [portal(Vector2(714,398),"Торговая улица →",MARKET,Vector2(80,360)),portal(Vector2(54,298),"← Ремесленный квартал",CRAFT,Vector2(688,336)),portal(Vector2(352,48),"↑ Храмовая улица",TEMPLE,Vector2(384,392)),portal(Vector2(384,432),"↓ Южные ворота",GATES,Vector2(384,88))]
		MARKET: return [portal(Vector2(56,360),"← Центральная площадь",SQUARE,Vector2(690,398)),portal(Vector2(640,48),"↑ Храмовая улица",TEMPLE,Vector2(688,368)),portal(Vector2(640,432),"↓ Южные ворота",GATES,Vector2(688,208)),portal(Vector2(360,212),"Оружейная",ARMORY,Vector2(384,392)),npc("hawker",Vector2(164,292)),inspect(Vector2(534,230),"Торговые весы","Под чашей весов застрял медяк. На гирях выбито клеймо городского смотрителя, поверх него — свежие царапины.")]
		CRAFT: return [portal(Vector2(712,336),"Центральная площадь →",SQUARE,Vector2(80,298)),portal(Vector2(384,48),"↑ Храмовая улица",TEMPLE,Vector2(80,416)),portal(Vector2(384,432),"↓ Южные ворота",GATES,Vector2(80,208)),npc("artisan",Vector2(248,280)),inspect(Vector2(542,288),"Остывающая отливка","В песке лежит половина дверной петли. Рядом — оттиск той же детали: работа ещё не закончена.")]
		TEMPLE: return [portal(Vector2(384,424),"↓ Центральная площадь",SQUARE,Vector2(352,76)),portal(Vector2(56,368),"← Ремесленный квартал",CRAFT,Vector2(384,80)),portal(Vector2(712,368),"Торговая улица →",MARKET,Vector2(640,80)),npc("pilgrim",Vector2(276,290)),inspect(Vector2(454,248),"Светильники у храма","Под навесом стоят три низких светильника. Один погас; два других заслонены от ветра ладонями каменной фигуры.")]
		GATES: return [portal(Vector2(384,56),"↑ Центральная площадь",SQUARE,Vector2(384,408)),portal(Vector2(56,208),"← Ремесленный квартал",CRAFT,Vector2(384,408)),portal(Vector2(712,208),"Торговая улица →",MARKET,Vector2(640,408)),portal(Vector2(384,424),"На Старую дорогу",ROAD,Vector2(100,410)),npc("guard",Vector2(444,300)),inspect(Vector2(270,276),"Следы у ворот","Свежие колеи идут из города. Обратно тянутся только отпечатки сапог. На камне ещё держится дорожная грязь.")]
		ARMORY: return [portal(Vector2(384,428),"На торговую улицу",MARKET,Vector2(360,236)),npc("smith",Vector2(384,222),Vector2(384,178)),inspect(Vector2(166,268),"Клинки на стойке","У каждого клинка своя отметина у гарды. Несколько гнёзд пусты; под ними лежат завёрнутые в ткань ножны.")]
	return []
