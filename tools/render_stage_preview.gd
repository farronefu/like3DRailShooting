extends SceneTree
## Render real gameplay, with frozen reproducible states, to local build artifacts.
func _initialize() -> void:
	call_deferred("render_preview")

func render_preview() -> void:
	root.size = Vector2i(1280,720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.muted = true
	game.start_run()
	game.invulnerable = 0
	var directory := "res://build/previews"
	DirAccess.make_dir_recursive_absolute(directory)
	for view in ["forest", "boss"]:
		if view == "forest":
			game.elapsed = 65
			game.banner_time = 0
			game.spawn_wave(1)
			for i in range(game.enemies.size()):
				game.enemies[i].node.position = Vector3(-7+i*7,2+i%2,-45-i*13)
			game.aim_screen = game.camera.unproject_position(game.enemies[2].node.position) / Vector2(1280,720)
		else:
			game.elapsed = 190
			game.spawn_boss()
			game.boss.update(game,5.0)
			game.boss.health = 180
			game.boss.update(game,0)
			game.banner_time = 0
			game.aim_screen = game.camera.unproject_position(game.boss.position+Vector3(0,0,7.7))/Vector2(1280,720)
		for i in range(6):
			await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png(directory + "/" + view + ".png")
		print("Stage preview ",view,": ",error)
	game.free()
	quit()
