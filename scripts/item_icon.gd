extends Control
## Original pixel icons drawn by Godot; no external bitmap dependency.
var kind := "sorted_records"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(32, 32)

func rect(x: int, y: int, w: int, h: int, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))

func _draw() -> void:
	var origin := ((size - Vector2(32, 32)) * 0.5).floor()
	draw_set_transform(origin)
	match kind:
		"simple_dagger":
			rect(14,3,5,19,"354542")
			rect(15,4,3,15,"c9d1c1")
			rect(16,2,1,5,"eef0d2")
			rect(10,20,13,3,"b19765")
			rect(15,23,4,7,"80543a")
			rect(14,29,6,2,"b19765")
		"permit_parcel":
			rect(3, 8, 26, 19, "141f24")
			rect(4, 7, 24, 18, "c39c65")
			rect(5, 8, 22, 3, "e2bd81")
			rect(15, 7, 3, 18, "654738")
			rect(4, 15, 24, 3, "654738")
			rect(13, 13, 7, 7, "a35b4b")
			rect(15, 14, 3, 3, "d58965")
		"delivery_receipt":
			rect(7, 4, 19, 26, "142426")
			rect(6, 3, 19, 25, "eddfbc")
			rect(9, 7, 13, 2, "ad996f")
			rect(9, 12, 11, 1, "ad996f")
			rect(9, 15, 13, 1, "ad996f")
			rect(16, 20, 6, 5, "69856b")
		_:
			rect(5, 8, 24, 21, "142426")
			rect(4, 7, 22, 20, "b4a17e")
			rect(7, 4, 19, 21, "eddfbc")
			rect(10, 8, 13, 2, "ad996f")
			for y in [13, 17, 21]:
				rect(10, y, 11, 1, "ad996f")
