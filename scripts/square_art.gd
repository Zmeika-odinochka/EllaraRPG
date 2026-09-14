@tool
extends Node2D
## Temporary original outdoor art for the quest prototype.
var completed_steps: Array[String] = []


func rect(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))


func _draw() -> void:
	rect(0, 0, 768, 480, "5c7250")
	rect(24, 24, 720, 432, "98937d")
	var stones := ["a8a189", "aaa28b", "ada48c", "a69e87"]
	for row in range(27):
		for col in range(31):
			var x: int = 24 + col * 24 - (12 if row % 2 else 0)
			var left: int = maxi(x, 24)
			var right: int = mini(x + 22, 744)
			if right > left:
				rect(left, 24 + row * 16, right - left, 14, stones[(row * 7 + col * 3) % 4])
	# Dark grass edge and stone boundary.
	for x in range(24, 745, 24):
		rect(x, 18, 21, 6, "777e61")
		rect(x, 456, 21, 6, "777e61")
	for y in range(24, 456, 24):
		rect(18, y, 6, 21, "777e61")
		rect(744, y, 6, 21, "777e61")
	# Guild front, roof, timber frame, and entrance.
	rect(60, 77, 216, 144, "655140")
	rect(68, 88, 200, 121, "c5b082")
	rect(68, 185, 200, 24, "9a855f")
	for x in [68, 129, 203, 260]:
		rect(x, 100, 7, 109, "72513a")
	rect(60, 76, 216, 33, "58433a")
	for row in range(4):
		for col in range(14):
			rect(58 + col * 16, 66 + row * 9, 15, 7, "995f49" if (row + col) % 3 else "ac7152")
	rect(55, 102, 225, 7, "503d33")
	rect(145, 152, 46, 59, "554233")
	rect(149, 156, 38, 55, "8f6543")
	for x in range(151, 186, 7):
		rect(x, 157, 1, 52, "664b37")
	rect(179, 182, 3, 3, "e3bd70")
	rect(141, 211, 54, 9, "ccc2a3")
	rect(136, 220, 64, 6, "afa990")
	for x in [89, 221]:
		rect(x, 133, 25, 36, "694e38")
		rect(x + 3, 136, 19, 29, "83a5a0")
		rect(x + 11, 136, 2, 29, "d2bb86")
		rect(x + 3, 149, 19, 2, "d2bb86")
	# Sign above the door.
	rect(137, 116, 62, 26, "725039")
	rect(140, 119, 56, 20, "35564c")
	draw_string(ThemeDB.fallback_font, Vector2(144, 133), "Гильдия", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ead297"))
	stall(405, "526f78", "a6beb3")
	stall(576, "87554b", "c49a79")
	# Small fountain, built as a solid landmark; clear paths around it.
	rect(340, 315, 88, 54, "6f756e")
	rect(344, 307, 80, 54, "c3bca0")
	rect(350, 313, 68, 39, "737f76")
	rect(353, 316, 62, 33, "739da0")
	for x in range(358, 412, 12):
		rect(x, 330, 8, 2, "a8c4b6")
	rect(375, 304, 18, 32, "8d9385")
	rect(370, 300, 28, 7, "d1c6a4")
	rect(382, 294, 4, 7, "b0ccbc")
	# Work materials beside the stalls.
	for y in range(371, 401, 6):
		var offset: int = 0 if "planks" in completed_steps else (int(y) % 3 - 1) * 5
		rect(539 + offset, y, 84, 4, "996d46")
		rect(540 + offset, y, 80, 1, "c29a64")
	if "canopy" in completed_steps:
		rect(691, 145, 3, 48, "d3c394")
		rect(688, 182, 9, 3, "c5a373")
		rect(692, 191, 3, 6, "5d503b")


func stall(x: int, base: String, light: String) -> void:
	rect(x + 4, 128, 5, 61, "624834")
	rect(x + 111, 128, 5, 61, "624834")
	rect(x, 105, 122, 38, "54483b")
	for stripe in range(8):
		rect(x + stripe * 15, 88, 15, 48, base if stripe % 2 else light)
		rect(x + stripe * 15, 136, 15, 7 + (stripe % 2) * 3, base if stripe % 2 else light)
	rect(x - 2, 85, 124, 4, "664d39")
	rect(x + 1, 165, 119, 7, "c3945f")
	rect(x + 6, 172, 109, 17, "8d6546")
	for bx in [16, 43, 78]:
		var offset: int = 0 if x != 405 or "goods" in completed_steps else (bx % 3) * 4
		rect(x + bx, 155 - offset, 18, 10, "8b8450")
		rect(x + bx + 2, 153 - offset, 14, 3, "b0ab70")
