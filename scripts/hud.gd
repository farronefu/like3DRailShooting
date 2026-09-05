extends Control

const CYAN := Color("70e4e8")
const WHITE := Color("e8f0f5")
const MUTED := Color("8ca7ba")
const ORANGE := Color("ffb06d")
var game: Node3D
var primary: Button
var secondary: Button
var pause_button: Button
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	primary = make_button("LAUNCH MISSION   >", func(): game.start_run())
	secondary = make_button("RETURN TO BRIEFING", func(): game.return_to_menu())
	pause_button = make_button("II", func(): game.toggle_pause())
	resized.connect(layout_buttons)
	layout_buttons()

func make_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 18)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("88e5e6")
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color("c0ffff")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_color_override("font_color", Color("102633"))
	button.add_theme_color_override("font_hover_color", Color("102633"))
	button.pressed.connect(action)
	add_child(button)
	return button

func layout_buttons() -> void:
	if not primary:
		return
	var scale_factor := size / Vector2(1280, 720)
	primary.position = Vector2(68, 568) * scale_factor
	primary.size = Vector2(294, 56) * scale_factor
	secondary.position = Vector2(380, 568) * scale_factor
	secondary.size = Vector2(265, 56) * scale_factor
	pause_button.position = Vector2(1196, 30) * scale_factor
	pause_button.size = Vector2(44, 40) * scale_factor

func _process(_dt: float) -> void:
	if not game:
		return
	var menu: bool = game.state != "playing"
	primary.visible = menu
	secondary.visible = game.state in ["paused", "clear", "over"]
	pause_button.visible = game.state == "playing"
	if game.state == "paused":
		primary.text = "RESUME FLIGHT   >"
	elif game.state in ["over", "clear"]:
		primary.text = "FLY AGAIN   >"
	else:
		primary.text = "LAUNCH MISSION   >"
	queue_redraw()

func label_at(text: String, at: Vector2, font_size: int = 16, color: Color = WHITE) -> void:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func panel(rect: Rect2, alpha: float = 0.84) -> void:
	draw_rect(rect, Color(0.025, 0.055, 0.09, alpha))
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color(0.3, 0.6, 0.7, 0.4), 1)

func _draw() -> void:
	if not game:
		return
	draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(1280, 720))
	if game.state == "playing":
		draw_flight()
	else:
		draw_menu()
	if game.hit_flash > 0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(1, 0.2, 0.13, game.hit_flash * 0.24))

func draw_menu() -> void:
	draw_rect(Rect2(0, 0, 730, 720), Color(0.016, 0.035, 0.063, 0.93))
	draw_rect(Rect2(730, 0, 550, 720), Color(0.016, 0.035, 0.063, 0.22))
	label_at("V W  /  FLIGHT SYSTEMS", Vector2(68, 62), 17, CYAN)
	label_at("PROTOTYPE  01", Vector2(1070, 62), 14, MUTED)
	draw_line(Vector2(68, 88), Vector2(660, 88), Color("345365"), 1)
	if game.state == "menu":
		label_at("VECTOR", Vector2(62, 214), 87)
		label_at("WING", Vector2(62, 298), 87)
		label_at("01  /  THE SILENT CORRIDOR", Vector2(68, 346), 19, CYAN)
		label_at("A four-minute run through the orbital defense line.", Vector2(68, 384), 18)
		label_at("Break formations. Dodge incoming fire. Make it through.", Vector2(68, 414), 17, MUTED)
		draw_controls(458)
	elif game.state == "paused":
		label_at("FLIGHT PAUSED", Vector2(68, 224), 49)
		label_at("Take a breath. Your mission is waiting.", Vector2(68, 274), 20, MUTED)
		draw_controls(352)
		label_at("I  /  Invert vertical input: " + ("ON" if game.invert_y else "OFF"), Vector2(68, 484), 17, CYAN)
		label_at("M  /  Sound: " + ("OFF" if game.muted else "ON"), Vector2(68, 516), 17, CYAN)
	else:
		var cleared: bool = game.state == "clear"
		label_at("MISSION CLEAR" if cleared else "SIGNAL LOST", Vector2(68, 218), 52, CYAN if cleared else ORANGE)
		label_at("You made it beyond the defense line." if cleared else "Your wing was lost. The corridor awaits another run.", Vector2(68, 265), 18, MUTED)
		label_at("FINAL SCORE", Vector2(68, 332), 15, MUTED)
		label_at("%06d" % game.score, Vector2(68, 392), 54)
		label_at("TARGETS", Vector2(68, 459), 14, MUTED)
		label_at("%02d" % game.kills, Vector2(68, 496), 30, CYAN)
		label_at("ACCURACY", Vector2(257, 459), 14, MUTED)
		label_at("%d%%" % game.accuracy(), Vector2(257, 496), 30, CYAN)
		label_at("FLIGHT TIME", Vector2(449, 459), 14, MUTED)
		label_at(format_time(game.elapsed), Vector2(449, 496), 30, CYAN)
	label_at("ENTER / A  TO START     ·     ESC / START  TO PAUSE", Vector2(68, 661), 13, MUTED)
	label_at("ORIGINAL GEOMETRY  /  GODOT 4", Vector2(955, 679), 12, MUTED)
	# Mission dossier at the right, leaving the spacecraft unobscured.
	panel(Rect2(912, 470, 300, 128), 0.78)
	label_at("MISSION PROFILE", Vector2(933, 502), 13, CYAN)
	label_at("RAIL FLIGHT  /  04:00", Vector2(933, 535), 19)
	label_at("4 SECTORS     •     1 WAY THROUGH", Vector2(933, 568), 12, MUTED)

func draw_controls(y: float) -> void:
	label_at("MOUSE + KEYBOARD", Vector2(68, y), 13, CYAN)
	label_at("Mouse / WASD  Move     Click / Space  Fire", Vector2(68, y + 27), 16)
	label_at("GAMEPAD", Vector2(68, y + 63), 13, CYAN)
	label_at("Left stick  Move     A / RT  Fire     Start  Pause", Vector2(68, y + 90), 16)

func draw_flight() -> void:
	panel(Rect2(32, 30, 276, 91))
	label_at("VECTOR WING", Vector2(49, 57), 15, CYAN)
	label_at("HULL", Vector2(49, 84), 11, MUTED)
	draw_rect(Rect2(99, 74, 160, 8), Color("243d50"))
	draw_rect(Rect2(99, 74, 160 * game.health / 100.0, 8), CYAN if game.health > 30 else ORANGE)
	label_at("%03d" % int(game.health), Vector2(267, 84), 13)
	label_at("%s  INPUT" % game.input_device, Vector2(49, 106), 11, MUTED)
	panel(Rect2(480, 30, 320, 73))
	label_at(game.rules.phase_name(game.elapsed), Vector2(501, 56), 15, CYAN)
	label_at("%s  /  04:00" % format_time(game.elapsed), Vector2(501, 82), 15)
	draw_rect(Rect2(480, 99, 320 * game.elapsed / 240.0, 3), CYAN)
	panel(Rect2(1010, 30, 173, 73))
	label_at("SCORE", Vector2(1028, 55), 11, MUTED)
	label_at("%06d" % game.score, Vector2(1028, 84), 27)
	var reticle: Vector2 = game.camera.unproject_position(Vector3(game.player.position.x, game.player.position.y, -60)) / (size / Vector2(1280, 720))
	var r := Rect2(reticle - Vector2(19, 19), Vector2(38, 38))
	for side in [-1.0, 1.0]:
		for vertical in [-1.0, 1.0]:
			var corner := reticle + Vector2(side, vertical) * 19
			draw_line(corner, corner - Vector2(side * 9, 0), CYAN, 2)
			draw_line(corner, corner - Vector2(0, vertical * 9), CYAN, 2)
	draw_circle(r.get_center(), 2, WHITE)
	# Short-lived confirmation makes successful hits readable.
	if game.hit_marker > 0:
		draw_arc(reticle, 28, 0, TAU, 24, ORANGE, 2, true)
	if game.banner_time > 0:
		panel(Rect2(360, 140, 560, 64), 0.8)
		label_at(game.banner, Vector2(386, 179), 19, CYAN)
	panel(Rect2(32, 635, 349, 53), 0.70)
	label_at("%02d  TARGETS" % game.kills, Vector2(49, 657), 13, CYAN)
	label_at("CLICK / SPACE / A / RT   HOLD TO FIRE", Vector2(49, 677), 11, MUTED)
	label_at("STAY IN THE CORRIDOR", Vector2(984, 662), 12, MUTED)
	label_at("ESC  PAUSE     M  SOUND", Vector2(1023, 684), 11, MUTED)
	if game.health <= 30:
		label_at("HULL CRITICAL — EVADE INCOMING FIRE", Vector2(418, 613), 17, ORANGE)

func format_time(t: float) -> String:
	return "%02d:%02d" % [int(t) / 60, int(t) % 60]
