extends Node2D
## Original stone-backed crawler, drawn on the same pixel grid as the world.
var combat: Node2D
var effects_only := false
var ground_only := false

func pixel(at: Vector2, size: Vector2, color: String) -> void:
	draw_rect(Rect2(at.round(),size), Color(color))

func _draw() -> void:
	if not is_instance_valid(combat): return
	if effects_only:
		if ground_only: draw_warning()
		else:
			draw_swing()
			draw_damage_numbers()
		return
	if combat.phase == "cleared":
		pixel(Vector2(-13,-7),Vector2(26,7),"333d3b")
		pixel(Vector2(-9,-11),Vector2(9,7),"59635c")
		pixel(Vector2(3,-9),Vector2(9,6),"667069")
		return
	draw_rect(Rect2(-17,-3,34,6),Color(0.04,0.06,0.05,0.4))
	var crouch := 3 if combat.phase == "windup" else 0
	var stride := 2 if combat.phase in ["chase","returning"] and int(combat.animation_time/0.12)%2 == 0 else 0
	for side in [-1,1]:
		for leg in range(3):
			var at := Vector2(side*11,-16+leg*6+crouch)
			draw_line(at,at+Vector2(side*(8+stride),4),Color("252f2e"),3)
			draw_line(at+Vector2(side*5,2),at+Vector2(side*(8+stride),4),Color("899083"),2)
	var shell := "f1d3a0" if combat.enemy_flash>0 else "566760"
	pixel(Vector2(-12,-23+crouch),Vector2(24,20),"263631")
	pixel(Vector2(-10,-24+crouch),Vector2(20,17),shell)
	pixel(Vector2(-8,-22+crouch),Vector2(8,7),"849085" if combat.enemy_flash<=0 else "fff1c9")
	pixel(Vector2(1,-19+crouch),Vector2(8,9),"687970")
	pixel(Vector2(-1,-23+crouch),Vector2(2,16),"35463f")
	pixel(Vector2(-7,-10+crouch),Vector2(7,4),"394c43")
	var head: Vector2 = combat.enemy_direction*12+Vector2(0,-10+crouch)
	pixel(head-Vector2(5,4),Vector2(10,8),"313d36")
	var eye := "e6b478" if combat.phase == "windup" else "ad956b"
	pixel(head+Vector2(-3,-2),Vector2(2,2),eye)
	pixel(head+Vector2(2,-2),Vector2(2,2),eye)
	if combat.engaged:
		pixel(Vector2(-13,-32),Vector2(26,3),"293734")
		var width := ceilf(26.0*combat.enemy_health/combat.ENEMY_HEALTH)
		if width>0: pixel(Vector2(-13,-32),Vector2(width,3),"c68a68")

func draw_damage_numbers() -> void:
	var font := ThemeDB.fallback_font
	for hit in combat.damage_numbers:
		var text := str(hit.amount)
		var opacity := clampf((0.8-float(hit.age))/0.3,0.0,1.0)
		var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
		var at: Vector2 = (hit.at+Vector2(-width/2.0,-38.0-float(hit.age)*22.5)).round()
		draw_string_outline(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,10,2,Color(0.09,0.14,0.14,opacity))
		draw_string(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color(0.93,0.88,0.74,opacity))

func draw_warning() -> void:
	if combat.phase in ["windup","strike"]:
		var center: Vector2 = combat.strike_origin
		var direction: Vector2 = combat.enemy_direction
		var wedge := PackedVector2Array([center])
		for i in range(13):
			wedge.append((center+direction.rotated(-1.1+i*2.2/12)*43).round())
		draw_colored_polygon(wedge,Color(0.72,0.40,0.23,0.30 if combat.phase=="windup" else 0.65))
		var edge := Color("ce9667") if combat.phase=="windup" else Color("f3d6a0")
		for i in range(1,wedge.size()-1): draw_line(wedge[i],wedge[i+1],edge,1)
		# Short contracting marks reinforce the crouch without filling the screen.
		if combat.phase=="windup":
			var distance: float = 10+combat.phase_time/combat.WINDUP*22
			pixel(center+direction*distance-Vector2(1,1),Vector2(3,3),"efd8aa")

func draw_swing() -> void:
	if combat.swing_time>0.18:
		var progress: float = clampf((0.5-combat.swing_time)/0.32,0,1)
		var origin: Vector2 = combat.player.position+Vector2(0,-14)
		if combat.swing_weapon == "":
			var reach := 10.0+22.0*sin(progress*PI)
			var fist: Vector2 = (origin+combat.swing_direction*reach).round()
			draw_line(origin,(fist-combat.swing_direction*3).round(),Color("648892"),5)
			pixel(fist-Vector2(3,3),Vector2(6,6),"d7a77f")
			pixel(fist-Vector2(2,3),Vector2(4,2),"f3cc9d")
			return
		var direction: Vector2 = combat.swing_direction.rotated(-1.0+progress*2.0)
		var hand := (origin+direction*12).round()
		var tip := (origin+direction*28).round()
		draw_line(hand,tip,Color("243332"),5)
		draw_line(hand,tip,Color("c7cec0"),3)
		draw_line(hand,(hand+direction*6).round(),Color("87603d"),3)
		var cross := direction.orthogonal()*3
		draw_line((hand+direction*7-cross).round(),(hand+direction*7+cross).round(),Color("c1a876"),2)
		if combat.swing_time<0.38:
			for i in range(9):
				var point: Vector2 = combat.player.position+combat.swing_direction.rotated(-0.95+i*0.24)*combat.ATTACK_RANGE+Vector2(0,-6)
				pixel(point,Vector2(2,2),"ced2b7")
