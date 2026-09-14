@tool
extends StaticBody2D
## Position is the bottom edge: y-sorting places a walker naturally behind it.

var kind: String = "table"


func setup(new_kind: String, at: Vector2, footprint: Rect2) -> void:
	kind = new_kind
	position = at
	var shape := RectangleShape2D.new()
	shape.size = footprint.size
	var collision := CollisionShape2D.new()
	collision.position = footprint.get_center()
	collision.shape = shape
	add_child(collision)


func rect(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))


func _draw() -> void:
	match kind:
		"counter":
			draw_rect(Rect2(-91, -6, 184, 10), Color(0.15, 0.09, 0.06, 0.3))
			rect(-88, -29, 176, 29, "49342b")
			rect(-85, -25, 170, 22, "805134")
			for x in [-80, -25, 30]:
				rect(x, -22, 49, 17, "a16b42")
				rect(x + 3, -20, 43, 2, "ba8550")
			rect(-91, -38, 182, 12, "4a342a")
			rect(-89, -37, 178, 8, "bf8b53")
			rect(-88, -37, 176, 2, "ddb476")
			rect(-89, -29, 178, 3, "8c5b39")
			# Open ledger and ink bottle.
			rect(-26, -39, 33, 10, "614737")
			rect(-24, -40, 29, 9, "e3cf99")
			rect(-10, -39, 1, 7, "b09a6f")
			for y in [-38, -35]:
				rect(-21, y, 8, 1, "9d8b68")
				rect(-7, y, 8, 1, "9d8b68")
			rect(15, -39, 6, 7, "354451")
			rect(17, -44, 2, 7, "e6d7aa")
			rect(57, -40, 15, 8, "996050")
			rect(59, -40, 11, 2, "d0a978")
		"table":
			draw_rect(Rect2(-46, -6, 94, 10), Color(0.15, 0.09, 0.06, 0.25))
			rect(-39, -18, 7, 18, "50382c")
			rect(32, -18, 7, 18, "50382c")
			rect(-45, -45, 90, 32, "4b342a")
			rect(-44, -44, 88, 26, "ba8751")
			rect(-43, -44, 86, 2, "d7aa6b")
			for y in [-36, -28, -20]:
				rect(-42, y, 84, 1, "986438")
			rect(-45, -18, 90, 4, "7a4e32")
			rect(-23, -39, 9, 8, "e6d2a3")
			rect(-21, -39, 5, 3, "6d4732")
			rect(-15, -37, 3, 4, "d0b184")
			rect(10, -32, 19, 9, "d2ba82")
			rect(13, -33, 12, 5, "b98047")
			if position.x>500:
				# Three places at the shared table, a folded cloth and a modest meal.
				rect(-6,-43,14,27,"789080")
				rect(-4,-42,2,24,"b1b69a")
				for at in [Vector2(22,-39),Vector2(1,-24)]:
					rect(at.x,at.y,6,5,"d2ba82")
					rect(at.x+1,at.y,4,2,"69503a")
		"bench":
			rect(-30, -10, 5, 10, "4d362a")
			rect(25, -10, 5, 10, "4d362a")
			rect(-34, -16, 68, 9, "50392c")
			rect(-32, -16, 64, 5, "bb8852")
			rect(-31, -16, 62, 1, "d8ad72")
		"board":
			rect(-35, -68, 70, 66, "42362c")
			rect(-32, -65, 64, 59, "b4854d")
			rect(-28, -61, 56, 51, "7d5a3b")
			for paper in [Vector2(-23, -55), Vector2(4, -53), Vector2(-8, -32)]:
				rect(paper.x + 1, paper.y + 1, 18, 21, "4d3c2f")
				rect(paper.x, paper.y, 18, 21, "e1cd98")
				rect(paper.x + 7, paper.y, 3, 3, "976448")
				for line in range(3):
					rect(paper.x + 3, paper.y + 7 + line * 4, 11, 1, "ad996b")
		"shelf":
			rect(-35, -65, 70, 65, "4a352c")
			rect(-30, -61, 60, 56, "654530")
			var colors := ["6d8790", "9b5850", "ba965d", "667e57"]
			for level in range(2):
				for book in range(7):
					var h: int = 14 + (book * 3 % 7)
					rect(-26 + book * 8, -34 + level * 26 - h, 6, h, colors[(book + level) % 4])
					rect(-25 + book * 8, -36 + level * 26, 4, 1, "d1b784")
				rect(-32, -34 + level * 26, 64, 4, "ae7b4c")
		"plant":
			rect(-10, -16, 20, 15, "795346")
			rect(-8, -13, 16, 11, "b37957")
			rect(-12, -18, 24, 5, "d09c6e")
			rect(-2, -39, 3, 22, "567249")
			rect(-14, -33, 13, 8, "456b49")
			rect(-10, -35, 9, 4, "7a9956")
			rect(1, -40, 12, 8, "5c844f")
			rect(3, -42, 8, 4, "95ae67")
			rect(1, -27, 14, 6, "789754")
		"barrel":
			rect(-13, -30, 26, 28, "60422e")
			rect(-11, -29, 22, 27, "a47345")
			for x in [-6, 2, 8]:
				rect(x, -27, 1, 24, "825531")
			rect(-13, -25, 26, 3, "59605b")
			rect(-13, -9, 26, 3, "59605b")
			rect(-10, -32, 20, 5, "bd925d")
