@tool
extends Node2D


func rect(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))


func _draw() -> void:
	rect(0, 0, 640, 400, "152725")
	# Evening sky and distant Elgard rooftops.
	for y in range(0, 250, 10):
		var shade := Color("203a37").lerp(Color("6f6650"), float(y) / 250.0)
		draw_rect(Rect2(0, y, 640, 10), shade)
	for star in [Vector2(42, 46), Vector2(91, 78), Vector2(151, 39), Vector2(207, 65), Vector2(286, 31), Vector2(362, 77), Vector2(432, 45), Vector2(523, 71), Vector2(590, 32)]:
		rect(star.x, star.y, 2, 2, "e8dba9")
	draw_circle(Vector2(522, 80), 25, Color("e7d59a"))
	draw_circle(Vector2(531, 72), 25, Color("29433d"))
	# Hill line.
	draw_colored_polygon(PackedVector2Array([Vector2(0, 229), Vector2(75, 174), Vector2(143, 213), Vector2(226, 151), Vector2(313, 208), Vector2(410, 164), Vector2(505, 214), Vector2(640, 165), Vector2(640, 400), Vector2(0, 400)]), Color("20342f"))
	# Guild silhouette and warm windows.
	rect(42, 253, 212, 147, "26332f")
	draw_colored_polygon(PackedVector2Array([Vector2(24, 259), Vector2(147, 186), Vector2(272, 259)]), Color("302f2b"))
	rect(78, 280, 39, 34, "d7a85c")
	rect(181, 280, 39, 34, "d7a85c")
	rect(134, 315, 34, 85, "49372e")
	# Foreground cobbles and lantern light.
	rect(0, 356, 640, 44, "485146")
	for x in range(0, 640, 32):
		rect(x, 365 + int(x / 32.0) % 2 * 12, 28, 2, "62695a")
	draw_circle(Vector2(150, 300), 74, Color(0.92, 0.69, 0.34, 0.07))
