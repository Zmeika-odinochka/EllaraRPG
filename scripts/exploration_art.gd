@tool
extends Node2D
const Layout = preload("res://scripts/exploration_layout.gd")
@export var interior := false
@export var foreground := false
var discoveries: Array[String] = []

func rect(x: float,y: float,w: float,h: float,color: String) -> void:
	draw_rect(Rect2(x,y,w,h),Color(color))

func hash_at(x: int,y: int) -> int:
	return posmod(x*73+y*137,997)

func pine(x: int,y: int,shade: int) -> void:
	if not foreground:
		rect(x-13,y-4,29,9,"182b27")
		rect(x-4,y-30,8,31,"514b3b")
		return
	for i in range(4):
		var span := 27-i*5
		var top := y-28-i*13
		rect(x-span,top,span*2,15,"203a32" if shade%2 else "293f35")
		rect(x-span+5,top-5,span*2-10,12,"304a3c")
		rect(x-span+7,top-5,span*2-14,3,"425644")
	rect(x-3,y-77,6,8,"53624b")

func rubble(x: int,y: int,large: bool = false) -> void:
	var w := 34 if large else 13
	var h := 23 if large else 8
	rect(x,y,w,h,"242f2d")
	rect(x+2,y-4,w-4,h,"505953")
	rect(x+5,y-7,w-11,5,"73786a")
	rect(x+3,y+3,w-7,2,"3c4742")

func lamp(x: int,y: int,lit: bool = true) -> void:
	if lit:
		for radius in [32,24,16]:
			draw_rect(Rect2(x-radius,y-radius,radius*2,radius*2),Color(0.66,0.48,0.2,0.025))
	rect(x-5,y-9,10,17,"242d29")
	rect(x-3,y-6,6,10,"c1a26d" if lit else "54594f")
	if lit: rect(x-1,y-4,2,6,"ecd8a5")
	rect(x-7,y-10,14,3,"5f5b47")

func _draw() -> void:
	if foreground:
		if not interior: vegetation()
		return
	var area := Layout.bounds(interior)
	draw_rect(area,Color("182322" if interior else "293c32"))
	for y in range(int(area.position.y),int(area.end.y),16):
		for x in range(int(area.position.x),int(area.end.x),16):
			var open := Layout.open_ground(Vector2(x+8,y+8),interior)
			var n := hash_at(x,y)
			if open:
				if interior:
					var tone := "6e6856" if y>312 else ("4b514b" if y<80 else "5b6054")
					rect(x,y,16,16,"303a35")
					rect(x+1,y+1,14,14,tone)
					if n%5==0: rect(x+5,y+7,8,1,"3d4740")
				else:
					var tones := ["746e57","7d765e","6d6a54"] if y>300 else ["555d4e","5a6252","606553"]
					rect(x,y,16,16,tones[n%3])
					if n%4==0: rect(x+4,y+10,4,2,"8b8970")
			else:
				if interior:
					rect(x,y,16,16,"1e2b28")
					if Layout.open_ground(Vector2(x+8,y+24),true):
						rect(x,y-15,16,31,"35433e")
						rect(x+1,y-14,14,12,"667065")
						rect(x+1,y+1,14,12,"4e5d52")
						rect(x,y-16,16,3,"88907b")
					if Layout.open_ground(Vector2(x+24,y+8),true):
						rect(x+5,y,11,16,"526154")
						rect(x+13,y,3,16,"82907c")
					if Layout.open_ground(Vector2(x-8,y+8),true):
						rect(x,y,11,16,"42534a")
						rect(x,y,3,16,"6d7d6c")
					if Layout.open_ground(Vector2(x+8,y-8),true):
						rect(x,y,16,9,"405147")
						rect(x,y,16,3,"71826e")
				else:
					rect(x,y,16,16,["2c4034","304237","344639"][n%3])
					if n%7==0: rect(x+3,y+5,4,2,"4e6047")
	if interior: post_details()
	else:
		vegetation()
		road_details()

func vegetation() -> void:
	for y in range(-360,448,48):
		for x in range(-472,728,48):
			var n := hash_at(x,y)
			var at := Vector2(x+n%13,y+n%17)
			# Canopies conceal adjacent ground without covering the travelled centre.
			var clear := true
			for offset in [Vector2.ZERO,Vector2(-24,-32),Vector2(24,-32),Vector2(0,-64),Vector2(0,16)]:
				if Layout.open_ground(at+offset,false): clear = false
			if Rect2(460,0,280,224).has_point(at): clear = false
			if clear: pine(int(at.x),int(at.y),n)

func road_details() -> void:
	# Safety fades: old paving and the last maintained light at the city threshold.
	for y in range(394,446,13):
		for x in range(78,118,13): rect(x,y,11,10,"a69b80")
	lamp(133,415)
	rect(147,394,4,31,"6f6047")
	rect(135,394,27,10,"9b8b68")
	# Wet gullies and broken rock faces close long views around the bends.
	for at in [Vector2i(-94,194),Vector2i(-256,121),Vector2i(-369,-82),Vector2i(-270,-132),Vector2i(125,-64),Vector2i(355,24),Vector2i(498,302),Vector2i(302,314)]:
		for i in range(4): rubble(at.x+i*13,at.y-(i%2)*11,true)
	for i in range(30):
		var x := -310+i*12
		var y := -280+(i%5)*3
		rect(x,y,14,9,"233735")
		rect(x+2,y+2,9,1,"557169")
	# A snagged strip of cloth hints at the optional track; no quest marker.
	rect(-7,-114,4,23,"5a5843")
	rect(-9,-112,9,5,"a49879")
	rect(-8,-107,4,8,"8c866a")
	# Abandoned rest: uprooted trunk, broken cart wheel, cold fire, torn bedding.
	for i in range(6): rect(25+i*8,71+i*3,14,9,"564c39")
	rect(70,91,43,10,"4c4635")
	rect(72,94,36,3,"8b7954")
	draw_arc(Vector2(119,77),11,0,TAU,16,Color("8e805c"),2)
	rect(109,76,20,2,"665c44")
	rect(119,67,2,20,"665c44")
	for at in [Vector2i(44,124),Vector2i(54,120),Vector2i(60,129),Vector2i(48,134)]: rubble(at.x,at.y)
	rect(48,127,12,6,"242b27")
	rect(105,140,25,9,"606e5b")
	rect(108,141,17,2,"88917b")
	rect(82,95,20,13,"775c42")
	if "road_cache" not in discoveries: rect(89,96,8,7,"d6c79e")
	# Gate uses the original position and persistent state; cliffs close its sides.
	for x in [524,584]:
		rect(x,244,8,44,"5a6657")
		rect(x-2,242,12,5,"93957b")
	if "shortcut" not in discoveries:
		for x in range(535,585,9): rect(x,254,5,29,"544f3d")
		rect(532,265,56,5,"998e70")
	else: rect(590,250,30,5,"998e70")
	# Only the final bend reveals the doorway and ruined roof.
	rect(490,36,216,142,"29342f")
	for y in range(48,172,16):
		for x in range(496,696,24):
			rect(x,y,22,14,"637064" if (x+y)%3 else "535f54")
	for y in range(30,84,9):
		for x in range(484,708,17):
			if x>635 and y<58: continue
			rect(x,y,15,7,"515a4f" if (x+y)%2 else "69705f")
	rect(538,123,44,48,"28382f")
	rect(543,128,34,43,"172623")
	rect(539,170,44,7,"93917a")
	lamp(592,142,false)
	for at in [Vector2i(658,21),Vector2i(690,113),Vector2i(499,12)]: rubble(at.x,at.y,true)

func post_details() -> void:
	# Damp stains collect by walls, while three scrapes point into the guard room.
	for at in [Vector2(122,82),Vector2(452,-65),Vector2(495,179)]:
		for i in range(5): rect(at.x+i*4,at.y+i%3*6,7,3,"354940")
	for x in [218,224,230]:
		draw_line(Vector2(x,244),Vector2(x+12,230),Color("85816a"),1)
	# Foyer, transverse passage, guard room, collapsed north gallery, sealed chamber.
	for y in range(176,232,8):
		for x in range(128,304,32):
			rect(x,y,30,6,"716d53" if (x+y)%3 else "625f4b")
	for at in [Vector2i(358,323),Vector2i(410,323),Vector2i(115,235),Vector2i(164,235)]:
		rect(at.x,at.y,8,19,"6f6950")
		rect(at.x+2,at.y,2,19,"999075")
	for y in range(362,447,17): rect(369,y,31,13,"968d73")
	lamp(346,391)
	lamp(433,375,false)
	rect(326,353,18,25,"61583f")
	rect(326,363,18,3,"343c30")
	for y in range(108,156,22):
		rect(115,y,13,18,"726e57")
		rect(116,y+2,9,4,"a1967d")
	rect(206,135,76,42,"4a4837")
	rect(209,137,70,29,"877653")
	rect(228,142,29,18,"c7ba92")
	rect(242,142,2,18,"756d52")
	for y in range(146,158,4):
		rect(231,y,8,1,"877c5a")
		rect(247,y,7,1,"877c5a")
	lamp(278,119,false)
	# A barred view from the entrance-side passage suggests an unreachable room.
	rect(522,229,158,90,"253c34")
	for y in range(239,307,16):
		for x in range(536,669,16): rect(x,y,14,14,"3e5044")
	# Rubble fills the inaccessible gallery; its glow is visible through iron bars.
	for at in [Vector2i(551,238),Vector2i(590,262),Vector2i(635,240),Vector2i(566,289)]: rubble(at.x,at.y,true)
	rect(516,241,17,75,"687763")
	rect(518,249,12,55,"172925")
	for y in range(252,304,10): rect(519,y,11,3,"8a9984")
	rect(531,252,3,50,"687c65")
	rect(643,273,10,17,"819778")
	# Breaks in the north gallery, damp trail and fallen lintels.
	for at in [Vector2i(190,48),Vector2i(270,-139),Vector2i(359,-137),Vector2i(491,-26)]:
		rubble(at.x,at.y,true)
		rubble(at.x+20,at.y+11)
	for x in range(325,427,16): rect(x,-91+(x%5),10,3,"314b45")
	# Existing magical detail is quiet, local and still mechanically sealed.
	rect(565,109,68,29,"263e38")
	rect(572,112,54,22,"4b6a5d")
	rect(583,116,33,13,"7f9877")
	rect(598,111,3,22,"c3c7a0")
	rect(584,124,30,3,"c3c7a0")
