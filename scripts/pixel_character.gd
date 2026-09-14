@tool
extends Node2D
## Temporary original characters drawn on a whole-pixel grid.

@export var is_mira: bool = false
var facing: Vector2 = Vector2.DOWN
var walking: bool = false
var step_time: float = 0.0
var attack_time := -1.0
var attack_direction := Vector2.DOWN
var attack_weapon := ""


func _process(delta: float) -> void:
	step_time = step_time + delta if walking else 0.0
	queue_redraw()


func pixel(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))


func _draw() -> void:
	var attacking := attack_time >= 0.0 and attack_time < 0.34
	var extension := attack_extension() if attacking else 0.0
	var stride: int = int(signf(sin(step_time * 18.0))) * 2 if walking else 0
	if attacking: stride = 1
	draw_rect(Rect2(-10, -3, 20, 4), Color(0.1, 0.08, 0.07, 0.25))
	# Keep the head and torso anchored; only the limbs move during a step.
	# Boots, trousers, tunic, belt, hands, then the head.
	pixel(-6, -7 + stride, 5, 7, "342b2b")
	pixel(1, -7 - stride, 5, 7, "342b2b")
	pixel(-6, -12, 12, 7, "475166" if not is_mira else "35594b")
	# A small weight shift moves the torso as one piece, not a stretched limb.
	var lean := (Vector2(attack_direction.x,attack_direction.y*0.5) * lerpf(-1.0,3.0,extension)).round() if attacking else Vector2.ZERO
	draw_set_transform(lean)
	if attacking and attack_direction.y < -0.5: draw_attack(extension)
	pixel(-8, -23, 16, 13, "30343b")
	pixel(-7, -22, 14, 10, "648892" if not is_mira else "5a8062")
	pixel(-5, -22, 4, 9, "8daaa4" if not is_mira else "8da879")
	pixel(-7, -12, 14, 3, "6f4432")
	pixel(-1, -12, 3, 3, "dbb66c")
	if not attacking:
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
	if attacking and attack_direction.y >= -0.5: draw_attack(extension)
	if is_mira:
		pixel(-7, -34, 14, 2, "9fc57a")
		pixel(6, -35, 4, 4, "699d59")
		pixel(7, -31, 2, 5, "9fc57a")
	draw_set_transform(Vector2.ZERO)


func attack_extension() -> float:
	# Contact at 0.12 s matches combat.resolve_swing; recovery is deliberately slower.
	if attack_time < 0.08: return 0.0
	if attack_time < 0.12: return clampf((attack_time-0.08)/0.04,0.0,1.0)
	if attack_time < 0.16: return 1.0
	var recovery := clampf((attack_time-0.16)/0.18,0.0,1.0)
	return 1.0-recovery*recovery*(3.0-2.0*recovery)


func draw_attack(extension: float) -> void:
	var forward := attack_direction
	var side := forward.orthogonal()
	var chest := Vector2(0,-20)
	var shoulder := chest+side*5
	var reach := Vector2(forward.x,forward.y*0.65)
	var lateral := lerpf(3.0,10.0,absf(forward.y))
	var hand := (chest+reach*lerpf(3,18,extension)+side*lerpf(7,lateral,extension)).round()
	var elbow := ((shoulder+hand)*0.5+side*lerpf(5,2,extension)-forward*2).round()
	# The guard hand stays tucked; there are exactly two arms during the attack.
	var guard := (chest-side*6+forward*4).round()
	draw_line((chest-side*6).round(),guard,Color("30343b"),5)
	draw_line((chest-side*6).round(),guard,Color("648892"),3)
	draw_rect(Rect2(guard-Vector2(2,2),Vector2(4,4)),Color("c68b67"))
	for segment in [[shoulder.round(),elbow],[elbow,hand]]:
		draw_line(segment[0],segment[1],Color("30343b"),6)
		draw_line(segment[0],segment[1],Color("648892"),4)
	draw_line(elbow,hand,Color("8daaa4"),2)
	if attack_weapon != "":
		var blade := forward.rotated(lerpf(-0.85,0.2,extension))
		var cross := blade.orthogonal()
		var base := hand+blade*3
		var tip := hand+blade*15
		draw_colored_polygon(PackedVector2Array([(base-cross*2).round(),(base+cross*2).round(),tip.round()]),Color("c7cec0"))
		draw_line(base.round(),tip.round(),Color("edf0da"),1)
		draw_line((base-cross*3).round(),(base+cross*3).round(),Color("c1a876"),2)
		draw_line(hand.round(),base.round(),Color("87603d"),3)
	draw_rect(Rect2(hand-Vector2(3,3),Vector2(6,6)),Color("634335"))
	draw_rect(Rect2(hand-Vector2(2,2),Vector2(4,4)),Color("d7a77f"))
	draw_rect(Rect2(hand-Vector2(2,2),Vector2(3,1)),Color("f3cc9d"))
