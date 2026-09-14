@tool
extends Node2D
@export var interior := false
var discoveries: Array[String] = []

func rect(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))

func stone_wall(x: int, y: int, w: int, h: int) -> void:
	rect(x, y, w, h, "34403e")
	for row in range(h / 12):
		for col in range(w / 20):
			rect(x + col * 20 + 1, y + row * 12 + 1, 18, 9, "636d5c" if (row + col) % 3 else "747b63")
	rect(x, y, w, 3, "929580")
	rect(x, y + h, w, 7, "253932")

func tree(x: int, y: int) -> void:
	rect(x - 17, y - 8, 39, 13, "24392e")
	rect(x - 4, y - 36, 8, 35, "62523b")
	for tier in range(3):
		var span := 25 - tier * 6
		var top := y - 32 - tier * 16
		rect(x - span, top, span * 2, 17, "284838")
		rect(x - span + 3, top, span * 2 - 7, 4, "4d6b49")
		rect(x - span + 7, top - 5, span * 2 - 14, 8, "375c41")
	rect(x - 4, y - 78, 8, 9, "607750")

func lantern(x: int, y: int) -> void:
	rect(x - 8, y - 10, 16, 18, "776a43")
	rect(x - 5, y - 7, 10, 12, "bb9a56")
	rect(x - 2, y - 5, 4, 8, "ead395")
	rect(x - 7, y - 10, 14, 3, "3d4238")

func _draw() -> void:
	if interior: draw_post()
	else: draw_road()

func draw_road() -> void:
	rect(0, 0, 768, 480, "253b32")
	rect(24, 24, 720, 432, "445940")
	for i in range(450):
		var x := 24 + (i * 137) % 714
		var y := 28 + (i * 83) % 420
		rect(x, y, 3, 2, "66714b" if i % 3 else "344c38")
	# Wide west approach; the closed gate connects the return trail to the post.
	for path in [Rect2(70, 344, 520, 90), Rect2(120, 168, 76, 228), Rect2(136, 166, 470, 69), Rect2(124, 98, 67, 114), Rect2(64, 102, 112, 42), Rect2(529, 217, 62, 181)]:
		draw_rect(path, Color("77735a"))
		draw_rect(path.grow(-7), Color("89806a"))
	for i in range(66):
		var x := 135 + (i * 43) % 48
		var y := 174 + (i * 19) % 231
		rect(x, y, 4, 2, "ada087")
	for x in range(202, 504, 31):
		rect(x, 195 + x % 9, 6, 2, "ada087")
	stone_wall(220, 260, 312, 24)
	stone_wall(588, 260, 136, 24)
	# The destination is visible from the approach: broken roof, warm doorway.
	rect(486, 47, 226, 133, "253830")
	stone_wall(496, 48, 200, 120)
	rect(487, 36, 216, 48, "4e5348")
	for y in range(36, 78, 8):
		for x in range(490, 701, 16):
			if x > 644 and y < 57: continue
			rect(x, y, 14, 6, "676858" if (x + y) % 3 else "787968")
	rect(538, 123, 44, 48, "273a35")
	rect(543, 129, 34, 42, "17292a")
	rect(539, 169, 44, 8, "aaa186")
	lantern(592, 140)
	rect(621, 99, 38, 34, "253632")
	for x in range(627, 660, 10): rect(x, 101, 3, 29, "858a71")
	# Gate visibly moves aside once the player opens the latch from the north.
	for x in [529, 585]: rect(x, 247, 5, 41, "a39775")
	if "shortcut" not in discoveries:
		for x in range(535, 585, 9): rect(x, 254, 5, 29, "5e5642")
		rect(532, 265, 56, 5, "aba082")
		rect(541, 258, 34, 3, "b4a272")
	else:
		rect(590, 250, 30, 5, "aba082")
	for at in [Vector2i(54, 71), Vector2i(97, 71), Vector2i(274, 110), Vector2i(316, 109), Vector2i(58, 300), Vector2i(689, 408), Vector2i(718, 352), Vector2i(45, 207), Vector2i(367, 75), Vector2i(440, 69), Vector2i(273, 327)]: tree(at.x, at.y)
	# A pale sheet beside exposed roots draws attention to the optional branch.
	rect(70, 96, 39, 9, "514b36")
	rect(82, 95, 20, 13, "856343")
	rect(84, 94, 16, 4, "ae8e59")
	if "road_cache" not in discoveries:
		rect(89, 97, 8, 7, "e4d3a0")
		rect(91, 98, 4, 1, "897652")
	# Return to town, with a distinct stone threshold.
	for x in range(68, 129, 15): rect(x, 432, 13, 10, "b1a78e")
	rect(38, 370, 5, 42, "70583d")
	rect(24, 369, 40, 14, "a18c60")
	rect(27, 375, 28, 2, "4e503b")

func draw_post() -> void:
	rect(0, 0, 768, 480, "17282a")
	rect(72, 76, 624, 380, "4e5147")
	for row in range(18):
		for col in range(26):
			rect(74 + col * 24, 80 + row * 20, 22, 18, "626558" if (row * 3 + col) % 4 else "6d6e5d")
	stone_wall(24, 24, 720, 48)
	stone_wall(24, 72, 40, 384)
	stone_wall(704, 72, 40, 384)
	# Old cots and damp crates frame an open, readable centre.
	for y in [108, 139]:
		rect(80, y, 92, 24, "383e37")
		rect(84, y + 2, 84, 18, "7f7960")
		rect(86, y + 3, 18, 14, "ada28a")
	rect(200, 138, 86, 45, "353b32")
	rect(206, 133, 76, 40, "8a7350")
	rect(209, 135, 70, 4, "b19a6a")
	rect(229, 142, 28, 19, "dbcea4")
	rect(242, 142, 2, 19, "81745b")
	for y in range(146, 159, 4):
		rect(232, y, 7, 1, "968667")
		rect(247, y, 7, 1, "968667")
	lantern(290, 119)
	for x in [480, 520]:
		rect(x, 259, 35, 43, "3e463b")
		rect(x + 2, 258, 30, 34, "79694a")
		rect(x + 2, 270, 30, 4, "4d4f3d")
	# Sealed niche: local mystery, no claim of a currently implemented ability.
	stone_wall(530, 93, 140, 48)
	rect(560, 95, 82, 42, "293f3d")
	rect(568, 102, 66, 28, "4f716a")
	rect(579, 108, 43, 15, "779a7d")
	rect(598, 102, 4, 25, "d5ddad")
	rect(582, 117, 35, 3, "d5ddad")
	for i in range(15): rect(84 + (i * 47) % 590, 211 + (i * 73) % 198, 12, 2, "343f38")
	# Entry path is left clear, regardless of quest progress.
	for y in range(353, 456, 22): rect(364, y, 40, 18, "99927a")
	lantern(335, 410)
	lantern(433, 410)
