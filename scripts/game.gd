extends Node3D

const rules = preload("res://scripts/flight_rules.gd")
const visual = preload("res://scripts/visuals.gd")
const HUD = preload("res://scripts/hud.gd")
const ShipVisual = preload("res://scripts/ships/ship_visual.gd")
@export var player_appearance: Resource = preload("res://resources/ships/player_wolfen.tres")
@export var enemy_appearance: Resource = preload("res://resources/ships/enemy_scout.tres")
var state := "menu"
var elapsed := 0.0
var health := 100.0
var score := 0
var kills := 0
var shots_fired := 0
var shots_hit := 0
var input_device := "KEYBOARD"
var invert_y := false
var muted := false
var hit_flash := 0.0
var hit_marker := 0.0
var invulnerable := 0.0
var banner_time := 0.0
var banner := ""
var camera: Camera3D
var player: Node3D
var ship_model: Node3D
var hud: Control
var actors: Node3D
var scenery: Node3D
var chunks: Array[Node3D] = []
var enemies: Array[Dictionary] = []
var obstacles: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var repairs: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var shoot_timer := 0.0
var next_wave := 2.0
var next_obstacle := 10.0
var next_repair := 35.0
var last_phase := -1
var mouse_steering := false
var mouse_target := Vector2.ZERO
var menu_time := 0.0
var audio_players: Dictionary = {}
var run_count := 0

func _ready() -> void:
	rng.seed = 640024
	build_world()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = HUD.new()
	hud.game = self
	canvas.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for sound in ["laser", "hit", "damage", "repair", "clear"]:
		var stream := AudioStreamPlayer.new()
		stream.stream = load("res://assets/audio/%s.wav" % sound)
		stream.volume_db = -15 if sound == "laser" else -9
		stream.max_polyphony = 5
		add_child(stream)
		audio_players[sound] = stream
	# Exported test builds can be inspected without changing production rules.
	if "--autostart" in OS.get_cmdline_user_args():
		start_run()

func build_world() -> void:
	actors = Node3D.new()
	actors.name = "Actors"
	add_child(actors)
	scenery = Node3D.new()
	add_child(scenery)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("071221")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("91b3d0")
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -35, 0)
	sun.light_color = Color("b0e1ed")
	sun.light_energy = 1.8
	add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(20, 140, 0)
	rim.light_color = Color("fa865c")
	rim.light_energy = 1.1
	add_child(rim)
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 5, 27)
	camera.look_at(Vector3(0, 0, -60))
	camera.fov = 65
	camera.far = 1500
	player = Node3D.new()
	add_child(player)
	player.position = Vector3(0, 0, 8)
	ship_model = ShipVisual.spawn(player, player_appearance)
	visual.box(scenery, Vector3(0, -10, -300), Vector3(170, 1, 750), Color("112338"))
	# Recycled architecture gives clear speed cues without an infinite scene tree.
	for i in range(24):
		var chunk := Node3D.new()
		scenery.add_child(chunk)
		chunk.position.z = 40.0 - i * 24.0
		for side in [-1.0, 1.0]:
			var height := rng.randf_range(10, 31)
			visual.box(chunk, Vector3(side * 25, height / 2 - 10, 0), Vector3(8, height, 10), Color("1b3349"))
			visual.box(chunk, Vector3(side * 20.85, -1, 0), Vector3(0.16, 0.16, 8), Color("50a7b5"), true)
			visual.box(chunk, Vector3(side * 16, -9.35, 0), Vector3(0.15, 0.12, 14), Color("4598ab"), true)
		visual.box(chunk, Vector3(0, -9.4, 0), Vector3(31, 0.09, 0.15), Color("2c546b"), true)
		chunks.append(chunk)
	# Low draw-call star field.
	var stars := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.35
	star_mesh.height = 0.7
	star_mesh.radial_segments = 4
	star_mesh.rings = 2
	star_mesh.material = visual.material(Color("769cab"), true)
	multi.mesh = star_mesh
	multi.instance_count = 240
	for i in range(240):
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(rng.randf_range(-450, 450), rng.randf_range(35, 300), rng.randf_range(-950, -350))))
	stars.multimesh = multi
	scenery.add_child(stars)
	var planet := visual.sphere(scenery, Vector3(150, 155, -600), 70, Color("346078"))
	planet.scale = Vector3.ONE
	var orbital_ring := visual.ring(scenery, 95, Color("52808f"), 0.7)
	orbital_ring.position = Vector3(150, 155, -600)
	orbital_ring.rotation = Vector3(1.1, 0.1, -0.3)
	var station := Node3D.new()
	scenery.add_child(station)
	station.position = Vector3(0, 3, -570)
	visual.ring(station, 52, Color("476879"), 3.0)
	visual.ring(station, 47, Color("b07d60"), 0.8)
	for side in [-1.0, 1.0]:
		visual.box(station, Vector3(side * 95, 0, 0), Vector3(95, 13, 18), Color("274357"))
		visual.box(station, Vector3(side * 65, 0, 11), Vector3(52, 1, 0.2), Color("df9869"), true)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_P]:
			toggle_pause()
		elif event.keycode == KEY_ENTER and state != "playing":
			start_run()
		elif event.keycode == KEY_I:
			invert_y = not invert_y
		elif event.keycode == KEY_M:
			muted = not muted
		elif event.keycode in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			mouse_steering = false
			input_device = "KEYBOARD"
	if event is InputEventMouseMotion and event.relative.length() > 1 and state == "playing":
		mouse_steering = true
		input_device = "MOUSE"
		var vp := get_viewport().get_visible_rect().size
		mouse_target = Vector2((event.position.x / vp.x - 0.5) * 29.0, (0.5 - event.position.y / vp.y) * 18.0 + 1.5)
	if event is InputEventJoypadButton and event.pressed:
		input_device = "GAMEPAD"
		if event.button_index == JOY_BUTTON_START:
			if state == "menu":
				start_run()
			else:
				toggle_pause()
		elif event.button_index == JOY_BUTTON_A and state != "playing":
			start_run()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing":
		state = "paused"

func start_run() -> void:
	if state == "paused":
		state = "playing"
		return
	clear_actors()
	run_count += 1
	rng.seed = 640024
	state = "playing"
	elapsed = 0.0
	health = rules.MAX_HEALTH
	score = 0
	kills = 0
	shots_fired = 0
	shots_hit = 0
	shoot_timer = 0
	invulnerable = 1.0
	hit_flash = 0
	hit_marker = 0
	next_wave = 2.0
	next_obstacle = 10.0
	next_repair = 35.0
	last_phase = -1
	player.position = Vector3(0, 0, 8)
	player.rotation = Vector3.ZERO
	ship_model.rotation = Vector3.ZERO
	ship_model.scale = Vector3.ONE
	ship_model.visible = true
	mouse_steering = false
	hud.primary.release_focus()

func clear_actors() -> void:
	for child in actors.get_children():
		child.free()
	enemies.clear()
	obstacles.clear()
	projectiles.clear()
	repairs.clear()
	particles.clear()

func return_to_menu() -> void:
	clear_actors()
	state = "menu"
	player.visible = true
	ship_model.visible = true
	hit_flash = 0

func toggle_pause() -> void:
	if state == "playing":
		state = "paused"
	elif state == "paused":
		state = "playing"

func _process(dt: float) -> void:
	if state in ["menu", "over", "clear"]:
		hit_flash = maxf(0.0, hit_flash - dt * 3)
	if state == "menu":
		menu_time += dt
		player.position = Vector3(8, 3.0 + sin(menu_time) * 0.45, 6)
		ship_model.scale = Vector3.ONE * player_appearance.preview_scale
		ship_model.rotation_degrees = player_appearance.preview_rotation_degrees + Vector3(0, sin(menu_time * 0.3) * 10, 0)
		move_scenery(dt * 0.16)
		return
	if state != "playing":
		return
	# Fixed-step physics owns gameplay. Frame rate only updates the HUD/preview.

func _physics_process(dt: float) -> void:
	if state != "playing":
		return
	step(dt, read_input())

func read_input(pads: Variant = null) -> Dictionary:
	if pads == null:
		pads = Input.get_connected_joypads()
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)) - float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)))
	var fire := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	for pad in pads:
		var stick := rules.stick(Vector2(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X), -Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y)))
		var pad_fire := Input.is_joy_button_pressed(pad, JOY_BUTTON_A) or Input.is_joy_button_pressed(pad, JOY_BUTTON_RIGHT_SHOULDER) or Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT) > 0.25
		if stick.length() > 0.01 or pad_fire:
			mouse_steering = false
			input_device = "GAMEPAD"
			direction = stick
		fire = fire or pad_fire
	if direction.length() > 0.01:
		mouse_steering = false
	if invert_y:
		direction.y *= -1
	return {"move": direction.limit_length(), "fire": fire, "mouse": mouse_steering}

func step(dt: float, controls: Dictionary) -> void:
	if state != "playing":
		return
	elapsed = minf(elapsed + dt, rules.DURATION)
	invulnerable = maxf(0.0, invulnerable - dt)
	hit_flash = maxf(0.0, hit_flash - dt * 3)
	hit_marker = maxf(0.0, hit_marker - dt * 4)
	banner_time = maxf(0.0, banner_time - dt)
	shoot_timer -= dt
	var old_pos := player.position
	if controls.get("mouse", false):
		var target := mouse_target
		if invert_y:
			target.y = 3.0 - target.y
		player.position.x = move_toward(player.position.x, target.x, rules.PLAYER_SPEED * dt * 1.3)
		player.position.y = move_toward(player.position.y, target.y, rules.PLAYER_SPEED * dt * 1.3)
	else:
		var direction: Vector2 = controls.get("move", Vector2.ZERO)
		player.position += Vector3(direction.x, direction.y, 0) * rules.PLAYER_SPEED * dt
	player.position.x = clampf(player.position.x, -rules.LIMIT_X, rules.LIMIT_X)
	player.position.y = clampf(player.position.y, rules.MIN_Y, rules.MAX_Y)
	var movement := (player.position - old_pos) / maxf(dt, 0.0001)
	ship_model.rotation.z = lerpf(ship_model.rotation.z, -movement.x * 0.028, minf(1, dt * 10))
	ship_model.rotation.x = lerpf(ship_model.rotation.x, movement.y * 0.012, minf(1, dt * 8))
	ship_model.visible = invulnerable < 0.01 or int(elapsed * 15) % 2 == 0
	if controls.get("fire", false) and shoot_timer <= 0:
		fire_player()
		shoot_timer = 0.14
	move_scenery(dt)
	update_schedule()
	update_enemies(dt)
	update_obstacles(dt)
	update_projectiles(dt)
	update_repairs(dt)
	update_particles(dt)
	if state == "playing" and elapsed >= rules.DURATION:
		state = "clear"
		score += int(health) * 20 + 2000
		ship_model.visible = true
		play_sound("clear")

func move_scenery(dt: float) -> void:
	for chunk in chunks:
		chunk.position.z += dt * 38
		if chunk.position.z > 55:
			chunk.position.z -= 576

func update_schedule() -> void:
	var phase := rules.phase(elapsed)
	if phase != last_phase:
		last_phase = phase
		banner = ["01 / OUTER APPROACH — WEAPONS ONLINE", "02 / DEBRIS FIELD — WATCH YOUR FLIGHT PATH", "03 / DEFENSE GRID — INCOMING CROSS FIRE", "04 / FINAL RUN — HOLD THE LINE"][phase]
		banner_time = 4.5
	if elapsed >= next_wave and elapsed < 231:
		spawn_wave(phase)
		next_wave += [6.0, 5.5, 4.5, 3.8][phase]
	if elapsed >= next_obstacle and elapsed < 231:
		spawn_obstacle(phase)
		next_obstacle += [9.0, 4.0, 6.0, 4.5][phase]
	if elapsed >= next_repair and elapsed < 226:
		spawn_repair()
		next_repair += 35.0

func spawn_wave(phase: int) -> void:
	var center_x := rng.randf_range(-7, 7)
	var center_y := rng.randf_range(-2, 5)
	var count := 2 if phase == 0 else 3
	for i in range(count):
		var n := Node3D.new()
		actors.add_child(n)
		ShipVisual.spawn(n, enemy_appearance)
		var x := clampf(center_x + (i - (count-1) / 2.0) * 5.4, -11, 11)
		n.position = Vector3(x, center_y + (i % 2) * 1.7, -155 - i * 10)
		enemies.append({"node": n, "base_x": x, "base_y": n.position.y, "age": 0.0, "phase": float(i), "health": 2 if phase < 3 else 3, "fire": 2.5 + i * 0.7, "speed": 24.0 + phase * 2, "radius": 2.3})

func update_enemies(dt: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[i]
		var n: Node3D = enemy.node
		enemy.age += dt
		n.position.z += enemy.speed * dt
		n.position.x = enemy.base_x + sin(enemy.age * 1.4 + enemy.phase) * 1.8
		n.position.y = enemy.base_y + sin(enemy.age * 1.0 + enemy.phase) * 0.8
		n.rotation.z = cos(enemy.age * 1.4 + enemy.phase) * -0.15
		enemy.fire -= dt
		if enemy.fire <= 0 and n.position.z < -8 and n.position.z > -100:
			fire_enemy(n.position, rules.phase(elapsed))
			enemy.fire = 2.2 - rules.phase(elapsed) * 0.22
		if n.position.distance_to(player.position) < 2.4:
			damage(18)
			burst(n.position, Color("ffab70"), 8)
			n.queue_free()
			enemies.remove_at(i)
		elif n.position.z > 28:
			n.queue_free()
			enemies.remove_at(i)

func spawn_obstacle(phase: int) -> void:
	var n := Node3D.new()
	actors.add_child(n)
	n.position = Vector3(rng.randf_range(-11, 11), rng.randf_range(-4, 5.5), -175)
	var radius := rng.randf_range(1.8, 3.1) if phase != 1 else rng.randf_range(2.3, 3.5)
	var mesh := visual.sphere(n, Vector3.ZERO, radius, Color("745958"))
	mesh.rotation = Vector3(rng.randf(), rng.randf(), rng.randf())
	visual.ring(n, radius * 1.08, Color("f6a15f"), 0.10)
	obstacles.append({"node": n, "radius": radius})

func update_obstacles(dt: float) -> void:
	for i in range(obstacles.size()-1, -1, -1):
		var item := obstacles[i]
		var n: Node3D = item.node
		n.position.z += 38 * dt
		n.get_child(0).rotate_y(dt * 0.2)
		if n.position.distance_to(player.position) < item.radius + 0.9:
			damage(25)
			burst(n.position, Color("ee965a"), 10)
			n.queue_free()
			obstacles.remove_at(i)
		elif n.position.z > 30:
			n.queue_free()
			obstacles.remove_at(i)

func fire_player() -> void:
	shots_fired += 1
	var origin := player.position + Vector3(0, 0, -2)
	spawn_projectile(origin, Vector3(0, 0, -185), false)
	play_sound("laser")

func fire_enemy(origin: Vector3, phase: int) -> void:
	var target := player.position + Vector3(rng.randf_range(-1.2, 1.2), rng.randf_range(-0.8, 0.8), 0)
	spawn_projectile(origin, (target - origin).normalized() * (40 + phase * 3), true)

func spawn_projectile(origin: Vector3, velocity: Vector3, hostile: bool) -> void:
	var n := Node3D.new()
	actors.add_child(n)
	n.position = origin
	if hostile:
		visual.sphere(n, Vector3.ZERO, 0.43, Color("ff8255"), true)
	else:
		for side in [-1.0, 1.0]:
			visual.box(n, Vector3(side * 0.29, 0, 0), Vector3(0.13, 0.13, 2.8), Color("b1ffff"), true)
	projectiles.append({"node": n, "velocity": velocity, "hostile": hostile, "age": 0.0})

func update_projectiles(dt: float) -> void:
	for i in range(projectiles.size()-1, -1, -1):
		var shot := projectiles[i]
		var n: Node3D = shot.node
		var before := n.position
		n.position += shot.velocity * dt
		shot.age += dt
		var consumed := false
		if shot.hostile:
			if rules.segment_hits(before, n.position, player.position, 1.15):
				damage(10)
				consumed = true
		else:
			# Check the nearest intersected object, so rocks shield enemies behind them.
			var nearest := INF
			var enemy_index := -1
			for j in range(enemies.size()):
				var enemy := enemies[j]
				var center: Vector3 = enemy.node.position
				if rules.segment_hits(before, n.position, center, enemy.radius):
					var distance := before.distance_squared_to(center)
					if distance < nearest:
						nearest = distance
						enemy_index = j
			for obstacle in obstacles:
				var center: Vector3 = obstacle.node.position
				if rules.segment_hits(before, n.position, center, obstacle.radius) and before.distance_squared_to(center) < nearest:
					nearest = before.distance_squared_to(center)
					enemy_index = -1
			if nearest < INF:
				consumed = true
				if enemy_index >= 0:
					var target := enemies[enemy_index]
					target.health -= 1
					shots_hit += 1
					hit_marker = 1
					play_sound("hit")
					if target.health <= 0:
						kills += 1
						score += 100
						burst(target.node.position, Color("ffb074"), 10)
						target.node.queue_free()
						enemies.remove_at(enemy_index)
		if consumed or shot.age > 7 or n.position.z < -230 or n.position.z > 40:
			n.queue_free()
			projectiles.remove_at(i)

func spawn_repair() -> void:
	var n := Node3D.new()
	actors.add_child(n)
	n.position = Vector3(rng.randf_range(-8, 8), rng.randf_range(-2, 5), -155)
	visual.ring(n, 2.5, Color("8ff0b3"), 0.25)
	visual.box(n, Vector3.ZERO, Vector3(1, 0.18, 0.18), Color("8ff0b3"), true)
	visual.box(n, Vector3.ZERO, Vector3(0.18, 1, 0.18), Color("8ff0b3"), true)
	repairs.append({"node": n})
	banner = "SUPPLY RING AHEAD — FLY THROUGH TO REPAIR"
	banner_time = 3

func update_repairs(dt: float) -> void:
	for i in range(repairs.size()-1, -1, -1):
		var n: Node3D = repairs[i].node
		n.position.z += 38 * dt
		n.rotation.z += dt * 0.35
		if n.position.distance_to(player.position) < 3.0:
			health = minf(rules.MAX_HEALTH, health + 25)
			score += 150
			play_sound("repair")
			burst(n.position, Color("8ff0b3"), 8)
			n.queue_free()
			repairs.remove_at(i)
		elif n.position.z > 30:
			n.queue_free()
			repairs.remove_at(i)

func damage(amount: float) -> void:
	if invulnerable > 0 or state != "playing":
		return
	health = maxf(0, health - amount)
	invulnerable = 0.85
	hit_flash = 1
	play_sound("damage")
	if health <= 0:
		state = "over"
		ship_model.visible = true

func burst(at: Vector3, color: Color, count: int) -> void:
	for i in range(count):
		var n := visual.box(actors, at, Vector3.ONE * rng.randf_range(0.15, 0.4), color, true)
		particles.append({"node": n, "velocity": Vector3(rng.randf_range(-7, 7), rng.randf_range(-7, 7), rng.randf_range(-5, 8)), "life": rng.randf_range(0.25, 0.65)})

func update_particles(dt: float) -> void:
	for i in range(particles.size()-1, -1, -1):
		var particle := particles[i]
		particle.life -= dt
		particle.node.position += particle.velocity * dt
		particle.node.scale *= maxf(0, 1 - dt * 2)
		if particle.life <= 0:
			particle.node.queue_free()
			particles.remove_at(i)

func play_sound(sound: String) -> void:
	if not muted and audio_players.has(sound):
		audio_players[sound].play()

func accuracy() -> int:
	return roundi(100.0 * shots_hit / maxf(1, shots_fired))
