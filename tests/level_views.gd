extends "res://tests/save_and_pause.gd"
## Repeatable visual review without altering user saves or discovery mechanics.
func run_checks() -> void:
	state = root.get_node("GameState")
	state.reset_game()
	state.game_active = false
	for view in [[state.OUTSKIRTS_SCENE,Vector2(100,410),"exploration-road.png"],[state.OUTSKIRTS_SCENE,Vector2(-332,108),"exploration-gorge.png"],[state.OUTSKIRTS_SCENE,Vector2(-44,-142),"exploration-branch-hint.png"],[state.OUTSKIRTS_SCENE,Vector2(88,116),"exploration-cache.png"],[state.OUTSKIRTS_SCENE,Vector2(456,180),"exploration-post-exterior.png"],[state.OUTPOST_SCENE,Vector2(384,392),"exploration-post-entry.png"],[state.OUTPOST_SCENE,Vector2(490,280),"exploration-barred-view.png"],[state.OUTPOST_SCENE,Vector2(244,208),"exploration-guardroom.png"],[state.OUTPOST_SCENE,Vector2(300,-80),"exploration-gallery.png"],[state.OUTPOST_SCENE,Vector2(600,160),"exploration-post.png"]]:
		state.pending_spawn = view[1]
		game = await load_world(view[0])
		await frames(4)
		print(view[2], " player=", game.player.position, " screen=", game.player.get_global_transform_with_canvas().origin, " visible=", game.player.is_visible_in_tree())
		await capture(view[2])
	print("LEVEL VIEWS: %d failure(s)" % failures)
	quit(0 if failures==0 else 1)
