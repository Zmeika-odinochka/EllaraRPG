@tool
extends Node2D
## Floor and back wall, kept behind the y-sorted characters and furniture.


func rect(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))


func _draw() -> void:
	rect(16, 24, 736, 436, "1f2528")
	rect(24, 96, 720, 352, "694c3b")
	# Staggered oak floorboards; deterministic pattern, no random state.
	var floor_colors := ["8c654b", "90694c", "936d50", "896148", "946f51"]
	for row in range(22):
		for col in range(10):
			var x: int = 24 + col * 80 - (40 if row % 2 == 1 else 0)
			var left: int = maxi(x, 24)
			var right: int = mini(x + 79, 744)
			if right > left:
				rect(left, 96 + row * 16, right - left, 15, floor_colors[(row * 3 + col * 7) % 5])
				rect(left + 2, 97 + row * 16, maxi(0, right - left - 4), 1, "a07a56")
				if right - left > 32:
					rect(left + 10, 104 + row * 16, 17, 1, "87573c")
	# Back wall: plaster, wainscot, timber beams.
	rect(24, 24, 720, 72, "c2aa79")
	rect(24, 80, 720, 24, "65422f")
	for x in range(24, 744, 24):
		rect(x + 1, 82, 22, 18, "765039")
	rect(24, 96, 720, 5, "ad7948")
	rect(24, 101, 720, 5, "392e27")
	for x in [24, 248, 512, 732]:
		rect(x, 24, 12, 77, "49342b")
		rect(x + 2, 26, 3, 70, "87603d")
	rect(24, 24, 720, 9, "49342b")
	rect(26, 32, 716, 3, "9c754c")
	window_at(112)
	window_at(568)
	# Guild crest above reception.
	rect(345, 36, 78, 44, "6f4933")
	rect(348, 39, 72, 38, "d6bc83")
	rect(351, 42, 66, 32, "42625b")
	draw_colored_polygon(PackedVector2Array([Vector2(384, 47), Vector2(397, 54), Vector2(394, 64), Vector2(384, 71), Vector2(374, 64), Vector2(371, 54)]), Color("d5b977"))
	rect(382, 50, 4, 15, "42625b")
	rect(377, 54, 14, 3, "42625b")
	# Central runner.
	rect(323, 217, 126, 190, "634837")
	rect(325, 217, 122, 185, "6e363b")
	rect(329, 220, 114, 179, "aa7550")
	rect(332, 223, 108, 173, "75494a")
	for y in range(229, 393, 16):
		rect(335, y, 3, 4, "c19765")
		rect(434, y, 3, 4, "c19765")
	for x in range(328, 445, 6):
		rect(x, 402, 2, 5, "c49b68")
	# Stone threshold and a closed exit for this one-room prototype.
	rect(341, 431, 86, 17, "736f63")
	rect(345, 433, 78, 2, "aaa38a")
	# Low side walls and foreground cutaway.
	rect(16, 96, 12, 356, "473b31")
	rect(740, 96, 12, 356, "473b31")
	rect(17, 96, 3, 356, "92704b")
	rect(744, 96, 3, 356, "92704b")
	rect(16, 448, 736, 12, "473b31")
	rect(24, 448, 720, 3, "b28d59")
	# Sunlit patches from the windows.
	for x in [124, 580]:
		draw_colored_polygon(PackedVector2Array([Vector2(x, 108), Vector2(x + 44, 108), Vector2(x + 82, 171), Vector2(x + 12, 171)]), Color(1.0, 0.87, 0.56, 0.10))


func window_at(x: int) -> void:
	rect(x - 5, 38, 70, 45, "684631")
	rect(x, 41, 60, 36, "6c989c")
	rect(x + 3, 43, 54, 13, "9bbfbd")
	rect(x + 3, 58, 54, 16, "769b83")
	rect(x + 9, 65, 10, 9, "4f796b")
	rect(x + 41, 62, 13, 12, "4f796b")
	rect(x + 28, 41, 4, 36, "634d35")
	rect(x, 56, 60, 3, "634d35")
	rect(x - 7, 77, 74, 5, "dbbb80")
