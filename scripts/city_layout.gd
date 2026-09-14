extends RefCounted
const City = preload("res://scripts/city_catalog.gd")

static func obstacles(scene: String) -> Array[Rect2]:
	match scene:
		City.BOOKSHOP: return [Rect2(80,72,608,16),Rect2(80,72,16,376),Rect2(672,72,16,376),Rect2(80,440,608,16),Rect2(280,176,208,28),Rect2(128,112,88,72),Rect2(552,112,88,72),Rect2(136,256,80,20),Rect2(544,272,96,40)]
		City.MARKET: return [Rect2(64,64,144,160),Rect2(248,72,224,128),Rect2(496,128,88,80),Rect2(176,352,272,104)]
		City.CRAFT: return [Rect2(64,48,208,176),Rect2(464,64,240,200),Rect2(80,368,176,88),Rect2(496,352,208,104),Rect2(328,216,72,24)]
		City.TEMPLE: return [Rect2(272,32,224,176),Rect2(80,64,136,112),Rect2(80,216,112,24),Rect2(552,112,128,136)]
		City.GATES: return [Rect2(80,60,160,96),Rect2(528,64,168,104),Rect2(56,288,88,128),Rect2(624,288,88,128),Rect2(144,328,184,40),Rect2(440,328,184,40),Rect2(136,216,104,48)]
		City.ARMORY: return [Rect2(80,72,608,16),Rect2(80,72,16,376),Rect2(672,72,16,376),Rect2(80,440,608,16),Rect2(280,176,208,28),Rect2(136,120,80,28),Rect2(136,228,64,24),Rect2(552,120,64,120),Rect2(520,328,72,40)]
	return []
