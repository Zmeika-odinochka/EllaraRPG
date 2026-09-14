extends Node2D
## Small original floor details and local light, without hiding traversable routes.
const City = preload("res://scripts/city_catalog.gd")
var scene := ""
var phase := 0.0
var frame_clock := 0.0

func _process(delta: float) -> void:
	phase += delta
	frame_clock += delta
	if frame_clock>0.1:
		frame_clock = 0
		queue_redraw()

func tile(at: Vector2, size: Vector2, color: String) -> void:
	draw_rect(Rect2(at.round(),size),Color(color))

func glow(at: Vector2, color: Color, radius: int) -> void:
	for i in range(3):
		var r := radius-i*6
		draw_colored_polygon(PackedVector2Array([at+Vector2(-r,-r/2.0),at+Vector2(r,-r/2.0),at+Vector2(r+8,r/2.0),at+Vector2(-r+8,r/2.0)]),color)

func _draw() -> void:
	match scene:
		City.GUILD:
			# Warm window dust and a worn mat: a room used every day.
			for origin in [Vector2(149,134),Vector2(602,135)]:
				for i in range(5):
					var at: Vector2 = origin+Vector2(i*8-16+sin(phase*0.3+i)*3,fmod(phase*2+i*9,42))
					draw_rect(Rect2(at.round(),Vector2(1,1)),Color(0.93,0.81,0.56,0.3))
			tile(Vector2(46,381),Vector2(56,32),"645c43")
			for y in range(384,410,5): tile(Vector2(49,y),Vector2(50,1),"9a875a")
			glow(Vector2(197,320),Color(0.9,0.65,0.25,0.018),38)
		City.SQUARE:
			for i in range(5):
				var x := 356+i*11
				var y := 331+int(sin(phase*1.3+i)*4)
				tile(Vector2(x,y),Vector2(6,1),"aac5b7")
			for at in [Vector2(300,251),Vector2(331,231),Vector2(724,262)]: fallen_leaves(at)
		City.MARKET,City.CRAFT,City.TEMPLE,City.GATES:
			for at in [Vector2(42,116),Vector2(728,264),Vector2(98,438),Vector2(680,434)]: fallen_leaves(at)
			if scene==City.CRAFT:
				glow(Vector2(144,213),Color(0.95,0.42,0.12,0.035),32)
				for i in range(3): tile(Vector2(131+i*5,179-fmod(phase*9+i*11,30)),Vector2(1,2),"d19b59")
			if scene==City.TEMPLE:
				glow(Vector2(445,240),Color(0.93,0.83,0.51,0.025),36)
			if scene==City.GATES:
				for x in [307,453]: glow(Vector2(x,321),Color(0.96,0.72,0.39,0.025),22)
		City.ARMORY,City.BOOKSHOP:
			for x in [240,517]: glow(Vector2(x,157),Color(0.94,0.71,0.33,0.027),35)
			for y in range(350,427,9): tile(Vector2(373+(y%3)*7,y),Vector2(3,1),"9c8d66")
		"res://scenes/outskirts.tscn":
			for at in [Vector2(-164,80),Vector2(-92,-245),Vector2(209,-51)]:
				glow(at,Color(0.43,0.57,0.55,0.025),30)
				for i in range(3): tile(at+Vector2(-12+i*10,2+sin(phase*0.7+i)*2),Vector2(6,1),"556960")
			fallen_leaves(Vector2(114,145))
		"res://scenes/outpost.tscn":
			# Cold shafts enter through broken masonry; the entrance lamp remains warm.
			for at in [Vector2(140,90),Vector2(373,-119)]:
				draw_colored_polygon(PackedVector2Array([at,at+Vector2(13,0),at+Vector2(47,81),at+Vector2(21,81)]),Color(0.69,0.77,0.68,0.055))
			glow(Vector2(346,394),Color(0.96,0.67,0.29,0.025),28)
			glow(Vector2(598,139),Color(0.49,0.77,0.60,0.025+sin(phase*0.6)*0.004),32)

func fallen_leaves(at: Vector2) -> void:
	for i in range(7):
		var offset := Vector2((i*13)%29,(i*7)%19)
		tile(at+offset,Vector2(3,1),"827a4e" if i%2 else "696b48")
