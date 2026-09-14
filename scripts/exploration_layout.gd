extends RefCounted
## Geometry only. Discovery IDs, interactions and save format remain unchanged.
const CELL := 16
const ROAD_BOUNDS := Rect2(-512, -448, 1280, 928)
const POST_BOUNDS := Rect2(16, -240, 736, 720)
const MAIN := [Vector2(100,436), Vector2(100,400), Vector2(12,370), Vector2(-24,298), Vector2(-146,288), Vector2(-200,214), Vector2(-300,214), Vector2(-332,108), Vector2(-422,64), Vector2(-422,-96), Vector2(-352,-160), Vector2(-224,-192), Vector2(-146,-110), Vector2(-44,-142), Vector2(80,-184), Vector2(176,-128), Vector2(288,-168), Vector2(352,-78), Vector2(438,-44), Vector2(444,64), Vector2(456,180), Vector2(500,200), Vector2(560,190), Vector2(560,238)]
const BRANCH := [Vector2(-44,-142), Vector2(-12,-46), Vector2(52,-20), Vector2(88,56), Vector2(88,116)]
const SHORTCUT := [Vector2(100,400), Vector2(250,410), Vector2(330,380), Vector2(420,400), Vector2(490,350), Vector2(560,324), Vector2(560,238)]
const POST_ROUTE := [Vector2(384,428), Vector2(384,344), Vector2(384,280), Vector2(144,280), Vector2(144,190), Vector2(144,112), Vector2(144,24), Vector2(300,24), Vector2(300,-80), Vector2(460,-80), Vector2(460,24), Vector2(600,24), Vector2(600,160)]
const POST_ROOMS := [Rect2(320,336,144,112), Rect2(120,248,400,64), Rect2(112,88,208,144), Rect2(272,-112,216,64), Rect2(544,104,128,112)]

static func bounds(inside: bool) -> Rect2:
	return POST_BOUNDS if inside else ROAD_BOUNDS

static func distance_to_path(point: Vector2, path: Array) -> float:
	var result := INF
	for i in range(path.size() - 1):
		result = minf(result, point.distance_to(Geometry2D.get_closest_point_to_segment(point, path[i], path[i+1])))
	return result

static func open_ground(point: Vector2, inside: bool) -> bool:
	if not bounds(inside).grow(-16).has_point(point): return false
	if inside:
		# The table and collapsed furniture are solid inside otherwise open rooms.
		if Rect2(206,135,76,42).has_point(point): return false
		if Rect2(112,92,16,76).has_point(point): return false
		for room in POST_ROOMS:
			if room.has_point(point): return true
		return distance_to_path(point, POST_ROUTE) <= 25
	if Rect2(496,40,208,132).has_point(point): return false
	return distance_to_path(point, MAIN) <= 32 or distance_to_path(point, BRANCH) <= 23 or distance_to_path(point, SHORTCUT) <= 23 or point.distance_to(Vector2(88,116)) < 42

static func cell_open(point: Vector2, inside: bool) -> bool:
	var cell := (point / CELL).floor() * CELL + Vector2.ONE * CELL * 0.5
	return open_ground(cell, inside)

static func safe_feet(point: Vector2, inside: bool, gate_open: bool) -> bool:
	var feet := Rect2(point + Vector2(-7,-9), Vector2(14,10))
	if not inside and not gate_open and feet.intersects(Rect2(532,260,56,28)): return false
	for offset in [Vector2(-7,-9), Vector2(7,-9), Vector2(-7,1), Vector2(7,1)]:
		if not cell_open(point + offset, inside): return false
	return true

static func nearest_safe(point: Vector2, inside: bool, gate_open: bool) -> Vector2:
	if safe_feet(point, inside, gate_open): return point
	var area := bounds(inside)
	var best := Vector2(384,392) if inside else Vector2(100,410)
	var nearest := INF
	for y in range(int(area.position.y), int(area.end.y), CELL):
		for x in range(int(area.position.x), int(area.end.x), CELL):
			var candidate := Vector2(x+8,y+12)
			if safe_feet(candidate, inside, gate_open) and candidate.distance_squared_to(point) < nearest:
				best = candidate
				nearest = candidate.distance_squared_to(point)
	return best

static func path_length(path: Array) -> float:
	var total := 0.0
	for i in range(path.size()-1): total += path[i].distance_to(path[i+1])
	return total
