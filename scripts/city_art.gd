@tool
extends Node2D
const City = preload("res://scripts/city_catalog.gd")
const Layout = preload("res://scripts/city_layout.gd")
var district := City.MARKET

func box(r: Rect2, color: String) -> void: draw_rect(r,Color(color))
func text(at: Vector2, words: String, color: String = "e1d0a4") -> void:
	draw_string(ThemeDB.fallback_font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(color))
func building(r: Rect2, roof: String, plaster: String) -> void:
	box(Rect2(r.position+Vector2(7,9),r.size),"46483c")
	box(r,plaster)
	box(Rect2(r.position+Vector2(0,r.size.y-18),Vector2(r.size.x,18)),"70664e")
	for x in range(int(r.position.x),int(r.end.x),48):
		box(Rect2(x,r.position.y,5,r.size.y),"60503e")
		if x+35<r.end.x:
			box(Rect2(x+15,r.end.y-62,22,30),"433f32")
			box(Rect2(x+18,r.end.y-59,16,24),"83998c")
			box(Rect2(x+25,r.end.y-59,2,24),"c0b384")
	box(Rect2(r.position-Vector2(6,6),Vector2(r.size.x+12,44)),roof)
	for y in range(int(r.position.y)-5,int(r.position.y)+35,8):
		for x in range(int(r.position.x)-5,int(r.end.x)+5,16):
			box(Rect2(x,y,14,2),"5d5146")
	box(Rect2(r.position+Vector2(-7,36),Vector2(r.size.x+14,6)),"493f33")
func door(at: Vector2) -> void:
	box(Rect2(at-Vector2(18,48),Vector2(36,48)),"514431")
	box(Rect2(at-Vector2(14,44),Vector2(28,44)),"8b6a48")
	for x in [-9,-2,5]: box(Rect2(at+Vector2(x,-42),Vector2(1,40)),"5b4934")
	box(Rect2(at+Vector2(8,-20),Vector2(3,3)),"d7b878")
	box(Rect2(at+Vector2(-24,0),Vector2(48,5)),"c3b899")
func lamp(at: Vector2) -> void:
	box(Rect2(at-Vector2(2,32),Vector2(4,32)),"403f32")
	box(Rect2(at-Vector2(7,38),Vector2(14,14)),"4b4635")
	box(Rect2(at-Vector2(4,35),Vector2(8,8)),"d9b474")
	box(Rect2(at-Vector2(2,33),Vector2(4,4)),"f1d69a")
func shrub(at: Vector2, shade: String = "68795a") -> void:
	box(Rect2(at-Vector2(12,6),Vector2(24,9)),"344b3d")
	box(Rect2(at-Vector2(14,14),Vector2(28,12)),shade)
	box(Rect2(at-Vector2(8,20),Vector2(18,10)),shade)
	box(Rect2(at-Vector2(7,16),Vector2(8,3)),"91a071")
func blade(at: Vector2) -> void:
	box(Rect2(at,Vector2(3,23)),"c5caba")
	box(Rect2(at+Vector2(-4,24),Vector2(11,3)),"bea16d")
	box(Rect2(at+Vector2(0,27),Vector2(3,8)),"8f6747")

func _draw() -> void:
	var indoor := district in [City.ARMORY,City.BOOKSHOP]
	var palette := ["aaa28b","a9a38c","aea68f","a69f88"]
	if district == City.CRAFT: palette = ["92917e","969380","8f907c","94917d"]
	if district == City.TEMPLE: palette = ["b0b4a2","adb2a0","b5b6a3","aeb39f"]
	if district == City.GATES: palette = ["9a9d88","9c9e8a","969b86","a0a08d"]
	box(Rect2(0,0,768,480),"445f48" if not indoor else "273b36")
	box(Rect2(24,24,720,432),"858875" if not indoor else "675941")
	for y in range(24,456,16):
		for x in range(12 if (y/16)%2 else 24,744,24):
			var color: String = palette[(x/24+y/16*3)%4]
			if indoor: color = "736348" if (y/16)%2==0 else "7b694e"
			var left := maxi(24,x)
			box(Rect2(left,y,mini(x+22,744)-left,14),color)
			if (x*7+y*3)%13==0: box(Rect2(left+6,y+8,7,1),"8d907b" if not indoor else "68583f")
	if indoor:
		if district==City.BOOKSHOP: draw_bookshop()
		else: draw_armory()
		return
	for r in Layout.obstacles(district):
		if district == City.GATES and r.position.y>=288:
			box(r,"687763")
			for y in range(int(r.position.y),int(r.end.y),12):
				for x in range(int(r.position.x),int(r.end.x),16): box(Rect2(x,y,14,10),"939e87" if (x/16+y/12)%3 else "9ba58d")
		elif r.size.y>70: building(r,"856651" if district!=City.TEMPLE else "617873","b7aa87" if district!=City.CRAFT else "a19a7f")
		else:
			box(r,"676d5d")
			box(Rect2(r.position,r.size-Vector2(0,6)),"aba990")
	match district:
		City.MARKET:
			door(Vector2(144,224))
			box(Rect2(80,142,112,20),"344b45")
			text(Vector2(91,156),"Книжная лавка")
			box(Rect2(196,176,15,19),"788b70")
			box(Rect2(199,178,2,15),"eddfbc")
			door(Vector2(360,200))
			box(Rect2(294,125,134,20),"344b45")
			text(Vector2(309,139),"У старого клинка")
			blade(Vector2(459,143))
			for x in range(496,584,11): box(Rect2(x,165,10,12),"737a62" if (x/11)%2 else "c3b184")
			box(Rect2(512,193,52,9),"7f6045")
			for x in range(516,560,8): box(Rect2(x,187,6,6),"c39b54")
			lamp(Vector2(235,219)); lamp(Vector2(481,218))
			shrub(Vector2(200,339)); shrub(Vector2(449,342))
			text(Vector2(474,314),"Южные ворота ↓","525c49")
		City.CRAFT:
			box(Rect2(101,141,61,60),"3c4039")
			box(Rect2(112,171,38,24),"b76d42")
			box(Rect2(120,180,23,12),"e3b76b")
			box(Rect2(202,76,25,76),"60695c")
			for i in range(4): box(Rect2(209-i*4,57-i*10,22+i*4,9),"879084")
			for x in range(497,678,24): box(Rect2(x,213,17,20),"786148")
			text(Vector2(88,251),"Кузня и литейный двор","3f5045")
			box(Rect2(340,222,46,6),"455247")
			lamp(Vector2(461,277))
		City.TEMPLE:
			for x in [280,312,456,488]: box(Rect2(x,78,8,125),"d0cbbb")
			box(Rect2(348,91,72,117),"59675e")
			box(Rect2(357,100,54,103),"708879")
			for i in range(3): box(Rect2(328-i*8,209+i*8,112+i*16,6),"c3c7b4")
			for x in [424,440,456]: lamp(Vector2(x,230))
			for at in [Vector2(110,190),Vector2(190,190),Vector2(604,278),Vector2(642,278)]: shrub(at)
			for x in range(566,668,28): box(Rect2(x,180,12,26),"b8b8a2")
			text(Vector2(322,66),"Дом тихого света")
		City.GATES:
			for x in [65,633]:
				box(Rect2(x,300,70,19),"8d987f")
				for crenel in range(x,x+70,18): box(Rect2(crenel,281,12,23),"a3aa8c")
			for x in [325,435]: box(Rect2(x,309,8,86),"555c48")
			for y in range(357,455,18):
				box(Rect2(372,y,5,14),"696b52"); box(Rect2(399,y,5,14),"696b52")
			lamp(Vector2(311,317)); lamp(Vector2(457,317))
			text(Vector2(330,310),"СТАРАЯ ДОРОГА")
			shrub(Vector2(232,413),"64745c"); shrub(Vector2(551,409),"64745c")

func draw_bookshop() -> void:
	for r in Layout.obstacles(district):
		box(r,"414439")
		box(Rect2(r.position+Vector2(2,2),r.size-Vector2(4,5)),"79634a")
	for x in [130,554]:
		for y in [115,140,165]:
			for i in range(10):
				box(Rect2(x+i*8,y+(i%3)*2,6,18-(i%3)*2),["788b70","9a795a","777e98","b2a079"][i%4])
	box(Rect2(292,167,184,25),"9b825b")
	box(Rect2(322,165,22,14),"eddfbc")
	box(Rect2(345,165,22,14),"c7b793")
	box(Rect2(340,165,2,15),"71634b")
	box(Rect2(411,167,9,9),"2e3934")
	draw_line(Vector2(416,168),Vector2(422,155),Color("cec7a3"),2)
	box(Rect2(148,257,25,14),"c3b38b")
	box(Rect2(175,257,24,14),"e0d1a7")
	box(Rect2(169,257,3,14),"6d5b42")
	for x in range(553,630,22): box(Rect2(x,271,18,14),"8d7761")
	lamp(Vector2(244,142)); lamp(Vector2(516,142)); lamp(Vector2(226,272))
	box(Rect2(330,339,108,83),"576659")
	for y in [342,416]: box(Rect2(333,y,102,3),"a89f79")
	text(Vector2(282,107),"ПЕРЕПЛЁТЫ И ПОЛЕВЫЕ ЗАПИСКИ")
	text(Vector2(286,137),"Не торопись. Здесь можно полистать.","c4b38d")

func draw_armory() -> void:
	for r in Layout.obstacles(district):
		box(r,"41493f")
		box(Rect2(r.position+Vector2(2,2),r.size-Vector2(4,5)),"827154")
	for x in [146,166,186,562,586,610]: blade(Vector2(x,108))
	for x in [146,168,190]: blade(Vector2(x,216))
	box(Rect2(289,161,190,32),"a68b5e")
	box(Rect2(292,162,184,4),"c7ad77")
	box(Rect2(326,170,56,12),"3f5148")
	blade(Vector2(351,148))
	box(Rect2(421,170,23,13),"5d4535")
	box(Rect2(428,168,7,7),"d3b473")
	box(Rect2(546,313,34,45),"333e35")
	box(Rect2(552,335,22,16),"b77646")
	lamp(Vector2(251,146)); lamp(Vector2(512,146))
	box(Rect2(328,376,112,58),"56654c")
	for y in [379,424]: box(Rect2(331,y,106,3),"b3a175")
	text(Vector2(269,107),"У СТАРОГО КЛИНКА")
	text(Vector2(337,138),"Сталь · заточка · ножны","c4b38d")
