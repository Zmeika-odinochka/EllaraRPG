@tool
extends Node2D


func rect(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))


func _draw() -> void:
	rect(0, 0, 640, 360, "152725")
	# Evening sky and distant Elgard rooftops.
	for y in range(0, 250, 10):
		var shade := Color("203a37").lerp(Color("6f6650"), float(y) / 250.0)
		draw_rect(Rect2(0, y, 640, 10), shade)
	for star in [Vector2(42, 46), Vector2(91, 78), Vector2(151, 39), Vector2(207, 65), Vector2(286, 31), Vector2(362, 77), Vector2(432, 45), Vector2(523, 71), Vector2(590, 32)]:
		rect(star.x, star.y, 2, 2, "e8dba9")
	draw_circle(Vector2(174, 64), 17, Color("bfc2a1"))
	draw_circle(Vector2(181, 60), 17, Color("2c423d"))
	# Hill line.
	draw_colored_polygon(PackedVector2Array([Vector2(0, 229), Vector2(75, 174), Vector2(143, 213), Vector2(226, 151), Vector2(313, 208), Vector2(410, 164), Vector2(505, 214), Vector2(640, 165), Vector2(640, 360), Vector2(0, 360)]), Color("20342f"))
	# City walls and staggered roofs, original silhouettes rather than an empty hill.
	for x in range(5,335,27):
		var top := 213-(x*7)%31
		rect(x,top,25,80,"2b4038")
		draw_colored_polygon(PackedVector2Array([Vector2(x-3,top),Vector2(x+12,top-15),Vector2(x+29,top)]),Color("33483d"))
		if x%3==0: rect(x+8,top+12,3,5,"9c956b")
	for x in [278,314]:
		rect(x,142,16,112,"2a4038")
		for y in range(142,238,12): rect(x+2,y,12,1,"3c5042")
		for crown in range(x-2,x+20,7): rect(crown,135,4,10,"31473b")
	# Guild silhouette and warm windows.
	rect(42, 253, 212, 147, "26332f")
	draw_colored_polygon(PackedVector2Array([Vector2(24, 259), Vector2(147, 186), Vector2(272, 259)]), Color("302f2b"))
	for y in range(206,256,7):
		var half := (y-185)*1.62
		for x in range(int(147-half),int(147+half),12): rect(x,y,10,2,"534c3b" if (x+y)%3 else "665641")
	rect(37,258,224,4,"69573e")
	for x in [44,130,242]:
		rect(x,262,5,64,"171f1d")
		rect(x+1,265,1,59,"5c5740")
	for y in [268,314]: rect(44,y,205,3,"494631")
	rect(83,224,14,29,"444536")
	for y in range(225,248,6): rect(84,y,11,1,"67634b")
	rect(78, 280, 39, 34, "d7a85c")
	rect(181, 280, 39, 34, "d7a85c")
	for x in [78,181]:
		rect(x+4,283,31,27,"bb935a")
		rect(x+18,280,3,34,"51452e")
		rect(x,296,39,3,"51452e")
		rect(x-3,314,45,3,"8b7551")
	rect(134, 315, 34, 85, "49372e")
	for x in range(138,166,6): rect(x,315,1,15,"7c6141")
	# Foreground cobbles and lantern light.
	rect(0, 326, 640, 34, "485146")
	for x in range(0, 640, 32):
		rect(x, 335 + int(x / 32.0) % 2 * 12, 28, 2, "62695a")
	draw_circle(Vector2(150, 300), 74, Color(0.92, 0.69, 0.34, 0.07))
	# A quiet dark field gives the title and menu their own visual space.
	draw_rect(Rect2(316,12,308,341),Color(0.06,0.14,0.14,0.30))
	for x in [11,286]:
		rect(x,276,3,55,"1a2922")
		for i in range(4):
			var w := 15-i*3
			draw_colored_polygon(PackedVector2Array([Vector2(x-w,301-i*12),Vector2(x+1,276-i*12),Vector2(x+w,301-i*12)]),Color("1d3028"))
