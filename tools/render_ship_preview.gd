extends SceneTree
## Render the real game asset for visual review. Requires a graphics device.
func _initialize() -> void:
	call_deferred("render_preview")

func render_preview() -> void:
	root.size = Vector2i(1500,1000)
	root.msaa_3d = Viewport.MSAA_4X
	var world := Node3D.new()
	root.add_child(world)
	var scene: PackedScene = load("res://assets/models/wolfen.glb")
	var model := scene.instantiate()
	world.add_child(model)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("111824")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a5b4cc")
	env.ambient_light_energy = 0.65
	environment.environment = env
	world.add_child(environment)
	for entry in [[Vector3(-48,-35,0),Color("e8efff"),1.5],[Vector3(-20,145,0),Color("98c0df"),1.0],[Vector3(15,60,0),Color("ffb7a4"),0.7]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = entry[0]
		light.light_color = entry[1]
		light.light_energy = entry[2]
		world.add_child(light)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.3
	var directory := "res://build/previews"
	DirAccess.make_dir_recursive_absolute(directory)
	for view in [["front",Vector3(5.5,5.1,-8)],["rear",Vector3(-5.5,4.1,8)],["top",Vector3(0,10,-0.2)]]:
		camera.position = view[1]
		camera.look_at(Vector3(0,0.2,-0.2),Vector3.BACK if view[0] == "top" else Vector3.UP)
		for i in range(4):
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var error := img.save_png(directory+"/wolfen_"+view[0]+".png")
		print("Preview ",view[0],": ",error)
	quit()
