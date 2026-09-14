extends "res://tests/save_and_pause.gd"
const City = preload("res://scripts/city_catalog.gd")
func run_checks() -> void:
	state = root.get_node("GameState")
	state.reset_game()
	state.game_active = false
	for scene in City.SCENES:
		game = await load_world(scene)
		await frames(5)
		await capture("city-"+scene.get_file().get_basename()+".png")
		for action in game.city.actions:
			if action.has("text"):
				game.player.position = action.at+Vector2(0,16)
				await frames(3)
				await key_press(KEY_E)
				check(game.inspection.is_open,"Environmental inspection works in "+scene)
				game.inspection.close()
				break
	game = await load_world(City.GUILD)
	game.player.position = Vector2(548,360)
	await frames(4)
	await capture("city-guild-table.png")
	game = await load_world(City.ARMORY)
	game.player.position = Vector2(384,224)
	state.personal_coins = 24
	await frames(3)
	await key_press(KEY_E)
	await capture("city-armory-shop.png")
	game.city.conversation.buy()
	game.city.conversation.close()
	state.set_equipped_weapon("simple_dagger")
	await key_press(KEY_I)
	await capture("city-dagger-bag.png")
	game.character_panel.switch_tab("hero")
	await frames(3)
	await capture("city-weapon-slot.png")
	quit(1 if failures else 0)
