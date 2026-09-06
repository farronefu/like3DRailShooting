extends SceneTree

const Rules = preload("res://scripts/flight_rules.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func run() -> void:
	check(Rules.stick(Vector2(0.10, 0.10)) == Vector2.ZERO, "gamepad deadzone suppresses stick drift")
	check(is_equal_approx(Rules.stick(Vector2(1, 1)).length(), 1), "diagonal gamepad input stays normalized")
	check(Rules.segment_hits(Vector3(0, 0, 10), Vector3(0, 0, -10), Vector3.ZERO, 1), "swept bullet collision catches tunneling")
	check(not Rules.segment_hits(Vector3(3, 0, 10), Vector3(3, 0, -10), Vector3.ZERO, 1), "swept collision rejects a near miss")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.muted = true
	game.start_run()
	Input.use_accumulated_input = false
	check(game.ship_model.model is Node3D and game.ship_model.appearance == game.player_appearance, "player loads its configured standalone 3D model")
	var old_player_id: int = game.player.get_instance_id()
	var old_position: Vector3 = game.player.position
	game.ship_model.set_appearance(game.enemy_appearance)
	check(game.ship_model.model.scale == Vector3.ONE * 0.9, "replacement model receives its own presentation scale")
	check(game.player.get_instance_id() == old_player_id and game.player.position == old_position and game.health == 100 and game.score == 0, "swapping appearance preserves player identity, movement and game state")
	game.ship_model.set_appearance(game.player_appearance)
	check(game.ship_model.get_child_count() == 1, "repeated visual swaps leave only one active model")
	game.spawn_wave(0)
	var enemy_visual: Node3D = game.enemies[0].node.get_child(0)
	check(enemy_visual.appearance == game.enemy_appearance and game.ship_model.appearance == game.player_appearance, "enemy and player designs are selected independently")
	game.clear_actors()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	check(game.read_input().move.x > 0.9, "physical keyboard D reaches the movement adapter")
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	var axis := InputEventJoypadMotion.new()
	axis.device = 0
	axis.axis = JOY_AXIS_LEFT_X
	axis.axis_value = 0.8
	Input.parse_input_event(axis)
	check(game.read_input([0]).move.x > 0.7 and game.input_device == "GAMEPAD", "synthetic controller events reach the movement adapter")
	var trigger := InputEventJoypadMotion.new()
	trigger.device = 0
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1.0
	Input.parse_input_event(trigger)
	check(game.read_input([0]).fire, "controller right trigger reaches the fire adapter")
	axis = axis.duplicate()
	axis.axis = JOY_AXIS_RIGHT_X
	axis.axis_value = -0.8
	Input.parse_input_event(axis)
	var combined: Dictionary = game.read_input([0])
	check(combined.move.x > 0.7 and combined.aim.x < -0.7, "left and right sticks independently move ship and aim in opposite directions")
	var mouse := InputEventMouseMotion.new()
	mouse.position = game.get_viewport().get_visible_rect().size * Vector2(0.8,0.3)
	mouse.relative = Vector2(20,-4)
	var ship_before: Vector3 = game.player.position
	game._input(mouse)
	check(game.aim_screen.is_equal_approx(Vector2(0.8,0.3)) and game.player.position == ship_before, "mouse updates screen reticle without moving the ship")
	game.step(0.1,{"move":Vector2.RIGHT})
	check(game.player.position.x > ship_before.x and game.aim_screen.is_equal_approx(Vector2(0.8,0.3)), "keyboard movement preserves mouse aim")
	game.step(5,{"aim":Vector2(-1,1)})
	check(game.aim_screen.is_equal_approx(Vector2(0.04,0.92)), "right stick reticle stays within visible bounds")
	game.start_run()

	check(game.read_input([]).move == Vector2.ZERO and not game.read_input([]).fire, "no enumerated controller leaves no stuck movement or fire")
	for i in range(120):
		game.step(1.0 / 60, {"move": Vector2.ONE.normalized()})
	check(is_equal_approx(game.player.position.x, Rules.LIMIT_X) and is_equal_approx(game.player.position.y, Rules.MAX_Y), "player remains inside flight bounds")
	var frozen: float = game.elapsed
	game.toggle_pause()
	game.step(1, {"move": Vector2.ONE, "fire": true})
	check(game.elapsed == frozen and game.shots_fired == 0, "pause freezes time and fire")
	game.start_run()
	check(game.state == "playing" and game.elapsed == frozen, "resume preserves mission progress")
	game.invulnerable = 0
	game.damage(10)
	game.damage(10)
	check(game.health == 90, "damage cooldown prevents repeated contact damage")
	game.invulnerable = 0
	game.damage(200)
	check(game.state == "over" and game.health == 0, "lethal damage triggers game over")
	game.start_run()
	check(game.elapsed == 0 and game.health == 100 and game.score == 0 and game.enemies.is_empty(), "retry resets mission state and actors")
	game.spawn_wave(0)
	game.enemies[0].node.position = Vector3(0, 0, -10)
	game.enemies[0].health = 1
	game.enemies[1].node.position = Vector3(9, 5, -100)
	game.aim_screen = game.camera.unproject_position(game.enemies[0].node.position) / game.get_viewport().get_visible_rect().size
	game.fire_player()
	game.update_projectiles(0.15)
	check(game.kills == 1 and game.score == 100 and game.shots_hit == 1, "a real projectile destroys a target and scores once")
	game.clear_actors()
	game.invulnerable = 0
	game.spawn_projectile(Vector3(0, 0, -10), Vector3(0, 0, 100), true)
	game.update_projectiles(0.3)
	check(game.health == 90, "hostile projectile damages the player using swept collision")
	game.clear_actors()
	game.spawn_repair()
	game.repairs[0].node.position = game.player.position
	game.health = 65
	game.update_repairs(0)
	check(game.health == 90 and game.repairs.is_empty(), "repair ring restores health and is consumed")
	game.spawn_obstacle(0)
	game.obstacles[0].node.position = game.player.position
	game.invulnerable = 0
	game.update_obstacles(0)
	check(game.health == 65 and game.obstacles.is_empty(), "obstacle contact damages player and removes obstacle")

	# The old fixed-Z shot misses a target centered on its reticle at a different depth.
	game.start_run()
	var viewport_size: Vector2 = game.get_viewport().get_visible_rect().size
	var off_axis_enemy := Vector3(11,0,-120)
	var pixel: Vector2 = game.camera.unproject_position(off_axis_enemy)
	var ray: Vector3 = game.camera.project_ray_normal(pixel)
	var ray_origin: Vector3 = game.camera.project_ray_origin(pixel)
	var old_plane: Vector3 = ray_origin + ray * ((-60-ray_origin.z)/ray.z)
	var old_muzzle := Vector3(old_plane.x,old_plane.y,6)
	check(not Rules.segment_hits(old_muzzle,old_muzzle+Vector3(0,0,-200),off_axis_enemy,2.3), "reproduces old right-lane miss caused by reticle depth parallax")
	for side in [-1.0,1.0]:
		for depth in [-25.0,-60.0,-120.0]:
			game.start_run()
			game.player.position.x = -side*8 # Also test shooting across the lane.
			game.spawn_wave(0)
			game.enemies[0].node.position = Vector3(side*11,2,depth)
			game.enemies[0].health = 1
			game.enemies[1].node.position = Vector3(40,30,-200)
			game.aim_screen = game.camera.unproject_position(game.enemies[0].node.position)/viewport_size
			game.fire_player()
			for frame in range(90):
				game.update_projectiles(1.0/60)
			check(game.kills == 1 and game.shots_hit == 1, "screen-centered target hit: lane=%d depth=%d" % [int(side),int(depth)])
	game.start_run()
	game.spawn_wave(0)
	game.enemies[0].node.position = Vector3(0,0,-60)
	game.enemies[0].health = 1
	game.enemies[1].node.position = Vector3(40,30,-200)
	game.spawn_obstacle(0)
	game.obstacles[0].node.position = Vector3(0,0,-25)
	game.obstacles[0].radius = 4
	game.spawn_projectile(Vector3.ZERO,Vector3(0,0,-230),false)
	game.update_projectiles(0.5)
	check(game.kills == 0 and game.projectiles.is_empty(), "foreground rock blocks an enemy even in a long physics step")
	check(Rules.segment_entry(Vector3.ZERO,Vector3(0,0,-100),Vector3(0,0,-30),12) < Rules.segment_entry(Vector3.ZERO,Vector3(0,0,-100),Vector3(0,0,-25),1), "surface intersection correctly orders large nearer surfaces despite farther centers")
	check(Rules.segment_entry(Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,1) == 0 and Rules.segment_entry(Vector3.ZERO,Vector3.ZERO,Vector3(3,0,0),1) == INF, "stationary segments handle overlap and separation")
	game.start_run()
	game.elapsed = Rules.BOSS_ARRIVAL-0.01
	game.step(0.02,{})
	check(is_instance_valid(game.boss) and game.state == "playing" and game.enemies.is_empty(), "forest end spawns boss and clears approach hazards without clearing mission")
	check(game.boss.get_child(0).appearance == game.boss_appearance, "boss uses an independently replaceable ship appearance")
	check(not game.boss.active and game.boss.volumes().is_empty(), "boss entrance has no invisible damageable hit volumes")
	game.boss.update(game,5)
	check(game.boss.active and game.boss.attack_count > 0 and game.projectiles.size() > 0, "boss reaches combat position and launches hostile volleys")
	game.hit_boss(211)
	game.boss.update(game,0)
	check(game.boss.phase == 2 and game.boss.health == 209, "boss switches to enraged attack phase below half health")
	game.elapsed = 360
	game.invulnerable = 1000
	game.step(0.01,{})
	check(game.state == "playing" and not game.boss_defeated, "elapsed time alone never clears an undefeated boss")
	var boss_age: float = game.boss.age
	game.toggle_pause()
	game.step(1,{"fire":true,"aim":Vector2.ONE})
	check(game.boss.age == boss_age, "pause freezes boss behavior")
	game.start_run()
	game.hit_boss(1000)
	check(game.boss_defeated and game.victory_timer > 0 and game.state == "playing", "boss defeat starts a short victory explosion")
	var reward: int = game.score
	game.hit_boss(1000)
	game.step(2,{})
	check(game.state == "clear" and game.score == reward, "boss defeat clears mission and rewards exactly once")
	game.start_run()
	check(not is_instance_valid(game.boss) and not game.boss_defeated and game.victory_timer < 0 and game.aim_screen == Vector2(0.5,0.5), "retry resets boss lifecycle and reticle")
	var max_actors := 0
	var observed_phases: Dictionary = {}
	var observed_boss := false
	for frame in range(18000):
		game.invulnerable = 1000 # Test schedule independently of pilot skill.
		if is_instance_valid(game.boss):
			observed_boss = true
			game.aim_screen = game.camera.unproject_position(game.boss.position+Vector3(0,-0.2,7.7))/viewport_size
		elif not game.enemies.is_empty():
			game.aim_screen = game.camera.unproject_position(game.enemies[0].node.position)/viewport_size
		game.step(1.0/60,{"fire":true})
		observed_phases[Rules.phase(game.elapsed)] = true
		max_actors = maxi(max_actors,game.enemies.size()+game.projectiles.size()+game.obstacles.size()+game.particles.size())
		if frame%60 == 0:
			await process_frame
		if game.state == "clear":
			break
	check(game.state == "clear" and game.boss_defeated and game.elapsed > 180 and game.elapsed < 300, "full forest-to-boss simulation wins in the intended 3–5 minute range")
	check(observed_phases.size() == 4 and observed_boss, "three forest sectors and final boss encounter execute")
	check(game.kills > 20, "screen-aim autopilot destroys enemies throughout the mission")
	check(max_actors < 250, "active actor counts remain bounded through the boss battle")
	check(game.scenery.chunks.size() == 12, "forest recycling keeps a fixed chunk count")
	print("SIMULATION: time=%.2f kills=%d score=%d max_actors=%d accuracy=%d%%" % [game.elapsed,game.kills,game.score,max_actors,game.accuracy()])
	game.start_run()
	check(game.state == "playing" and game.elapsed == 0 and game.shots_fired == 0, "mission clear can restart cleanly")
	game.return_to_menu()
	check(game.state == "menu" and game.actors.get_child_count() == 0, "return to briefing removes all gameplay actors")
	game.free()
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
