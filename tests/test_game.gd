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
	game.start_run()
	var max_actors := 0
	var observed_phases: Dictionary = {}
	for frame in range(14401):
		game.invulnerable = 1000 # Test the entire schedule independently of pilot skill.
		var target := Vector2.ZERO
		if not game.enemies.is_empty():
			var p: Vector3 = game.enemies[0].node.position
			target = Vector2(p.x - game.player.position.x, p.y - game.player.position.y).limit_length()
		game.step(1.0 / 60, {"move": target, "fire": true})
		observed_phases[Rules.phase(game.elapsed)] = true
		max_actors = maxi(max_actors, game.enemies.size() + game.projectiles.size() + game.obstacles.size() + game.particles.size())
		if frame % 60 == 0:
			await process_frame
	check(game.state == "clear" and is_equal_approx(game.elapsed, 240), "full 4-minute schedule reaches mission clear")
	check(observed_phases.size() == 4, "all four mission sectors execute")
	check(game.kills > 20, "autopilot can track and destroy targets through a full mission")
	check(max_actors < 250, "active actor counts remain bounded during full mission")
	print("SIMULATION: kills=%d score=%d max_actors=%d accuracy=%d%%" % [game.kills, game.score, max_actors, game.accuracy()])
	game.start_run()
	check(game.state == "playing" and game.elapsed == 0 and game.shots_fired == 0, "mission clear can restart cleanly")
	game.return_to_menu()
	check(game.state == "menu" and game.actors.get_child_count() == 0, "return to briefing removes all gameplay actors")
	game.free()
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
