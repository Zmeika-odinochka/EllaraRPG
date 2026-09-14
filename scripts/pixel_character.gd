@tool
extends Node2D
## Temporary original characters drawn on a whole-pixel grid.

@export var is_mira: bool = false
var facing: Vector2 = Vector2.DOWN
var walking: bool = false
var step_time: float = 0.0


func _process(delta: float) -> void:
	step_time = step_time + delta if walking else 0.0
	queue_redraw()


func pixel(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))


func _draw() -> void:
	var bob: int = 1 if walking and sin(step_time * 18.0) > 0 else 0
	var stride: int = int(signf(sin(step_time * 18.0))) * 2 if walking else 0
	draw_rect(Rect2(-10, -3, 20, 4), Color(0.1, 0.08, 0.07, 0.25))
	draw_set_transform(Vector2(0, -bob))
	# Boots, trousers, tunic, belt, hands, then the head.
	pixel(-6, -7 + stride, 5, 7, "342b2b")
	pixel(1, -7 - stride, 5, 7, "342b2b")
	pixel(-6, -12, 12, 7, "475166" if not is_mira else "35594b")
	pixel(-8, -23, 16, 13, "30343b")
	pixel(-7, -22, 14, 10, "648892" if not is_mira else "5a8062")
	pixel(-5, -22, 4, 9, "8daaa4" if not is_mira else "8da879")
	pixel(-7, -12, 14, 3, "6f4432")
	pixel(-1, -12, 3, 3, "dbb66c")
	pixel(-10, -20 - stride, 3, 8, "648892" if not is_mira else "5a8062")
	pixel(7, -20 + stride, 3, 8, "648892" if not is_mira else "5a8062")
	pixel(-10, -13 - stride, 3, 3, "d7a77f")
	pixel(7, -13 + stride, 3, 3, "d7a77f")
	pixel(-3, -25, 6, 4, "c68b67")
	pixel(-8, -37, 16, 14, "352b2b")
	pixel(-7, -36, 14, 13, "61412f" if is_mira else "4f382e")
	if facing != Vector2.UP:
		pixel(-6, -32, 12, 9, "e7b98f")
		pixel(-6, -32, 12, 2, "f3cc9d")
		pixel(-7, -36, 14, 5, "61412f" if is_mira else "4f382e")
		pixel(-7, -31, 3, 5, "61412f" if is_mira else "4f382e")
		if facing == Vector2.LEFT:
			pixel(-6, -29, 2, 2, "30343b")
			pixel(-8, -27, 2, 3, "e7b98f")
		elif facing == Vector2.RIGHT:
			pixel(4, -29, 2, 2, "30343b")
			pixel(6, -27, 2, 3, "e7b98f")
		else:
			pixel(-4, -29, 2, 2, "30343b")
			pixel(3, -29, 2, 2, "30343b")
			pixel(-1, -25, 3, 1, "ad695a")
	if is_mira:
		pixel(-7, -34, 14, 2, "9fc57a")
		pixel(6, -35, 4, 4, "699d59")
		pixel(7, -31, 2, 5, "9fc57a")
	draw_set_transform(Vector2.ZERO)
