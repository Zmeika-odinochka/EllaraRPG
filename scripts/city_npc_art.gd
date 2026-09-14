extends "res://scripts/pixel_character.gd"
var profile := "guard"
var seated := false
const CLOTH := {"irridia":"786570","celesta":"849178","astra":"586e71","smith":"947854","hawker":"92915c","artisan":"776449","pilgrim":"89948b","guard":"687b70"}
func _draw() -> void:
	super._draw()
	pixel(-7,-22,14,10,CLOTH.get(profile,"687b70"))
	pixel(-5,-22,3,8,"a6aa8c")
	if profile in ["irridia","celesta","astra"]:
		var hair: String = {"irridia":"554043","celesta":"a59470","astra":"514a40"}[profile]
		pixel(-7,-36,14,5,hair)
		pixel(-8,-32,3,11,hair)
		pixel(6,-32,3,11,hair)
	if profile == "smith":
		pixel(-5,-19,10,10,"514434")
		pixel(-4,-25,8,3,"88775e")
	if seated:
		pixel(-7,-7,14,5,"514b40")
		pixel(-8,-2,6,3,"383b32")
		pixel(2,-2,6,3,"383b32")
