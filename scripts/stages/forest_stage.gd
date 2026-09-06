extends Node3D
## Finite recycled scenery. Visual terrain has no gameplay collision.
const Visual = preload("res://scripts/visuals.gd")
const LENGTH := 48.0
const COUNT := 12
var chunks: Array[Node3D] = []
var water_material: ShaderMaterial
var travel := 0.0
var random := RandomNumberGenerator.new()

func _ready() -> void:
	random.seed = 94067
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var atmosphere := ProceduralSkyMaterial.new()
	atmosphere.sky_top_color = Color("507b94")
	atmosphere.sky_horizon_color = Color("d1d3bb")
	atmosphere.ground_bottom_color = Color("304238")
	atmosphere.ground_horizon_color = Color("b7c8b3")
	atmosphere.sky_curve = 0.2
	sky.sky_material = atmosphere
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("a5b9a5")
	env.fog_light_energy = 0.7
	env.fog_density = 0.0045
	env.fog_sky_affect = 0.18
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-27, -32, 0)
	sun.light_color = Color("fff0d6")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 135
	sun.shadow_bias = 0.06
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	fill.rotation_degrees = Vector3(-12, 145, 0)
	fill.light_color = Color("9ebfcb")
	fill.light_energy = 0.16
	add_child(fill)
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(49, 720)
	plane.subdivide_width = 24
	plane.subdivide_depth = 120
	water.mesh = plane
	water.position = Vector3(0, -9.3, -290)
	water_material = ShaderMaterial.new()
	water_material.shader = preload("res://scripts/stages/river.gdshader")
	water.material_override = water_material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)
	var ground_material := ShaderMaterial.new()
	ground_material.shader = preload("res://scripts/stages/ground.gdshader")
	var tree_mesh := make_tree()
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.13
	trunk.bottom_radius = 0.55
	trunk.height = 12
	trunk.radial_segments = 7
	trunk.material = Visual.material(Color("30291e"))
	for index in range(COUNT):
		var chunk := Node3D.new()
		add_child(chunk)
		chunks.append(chunk)
		for side in [-1.0, 1.0]:
			var bank := MeshInstance3D.new()
			bank.mesh = make_bank(side)
			bank.material_override = ground_material
			chunk.add_child(bank)
		var crowns := make_instances(chunk, tree_mesh, 72)
		var trunks := make_instances(chunk, trunk, 72)
		for i in range(72):
			var side := -1.0 if i % 2 == 0 else 1.0
			var x := side * random.randf_range(25, 115)
			var z := random.randf_range(-24, 24)
			var scale_tree := random.randf_range(0.7, 1.8)
			var basis := Basis(Vector3.UP, random.randf() * TAU).scaled(Vector3(scale_tree * random.randf_range(0.85, 1.2), scale_tree, scale_tree))
			var at := Vector3(x, height_at(x, z), z)
			crowns.set_instance_transform(i, Transform3D(basis, at))
			crowns.set_instance_color(i, Color.from_hsv(random.randf_range(0.22, 0.31), random.randf_range(0.28, 0.55), random.randf_range(0.65, 1.0)))
			trunks.set_instance_transform(i, Transform3D(basis, at + Vector3(0, 6 * scale_tree, 0)))
		for i in range(10):
			var x: float = [-1, 1][i % 2] * random.randf_range(20, 28)
			var z := random.randf_range(-24, 24)
			var rock := Visual.sphere(chunk, Vector3(x, -9 + random.randf_range(0, 1), z), random.randf_range(1, 3), Color("414940"))
			rock.scale = Vector3(1.3, 0.65, 1)
			rock.rotation.y = random.randf() * TAU
	# Distant ridges are static, softened by atmospheric fog.
	for side in [-1.0, 1.0]:
		for i in range(6):
			var ridge := Visual.sphere(self, Vector3(side * (190 + i * 45), -35, -440 - i * 48), 65, Color("314c43"))
			ridge.scale = Vector3(1.8, random.randf_range(1.0, 2.1), 2.5)
	reset()

func reset() -> void:
	travel = 0
	for i in range(chunks.size()):
		chunks[i].position.z = 48 - i * LENGTH
	water_material.set_shader_parameter("flow_time", 0.0)

func advance(dt: float, speed: float = 38.0) -> void:
	travel += dt * speed
	for chunk in chunks:
		chunk.position.z += dt * speed
		if chunk.position.z > 72:
			chunk.position.z -= LENGTH * COUNT
	water_material.set_shader_parameter("flow_time", travel / 38.0)

func height_at(x: float, z: float) -> float:
	var inland := maxf(0, absf(x) - (20.5 + sin(z * TAU / LENGTH) * 1.2))
	return -10.2 + minf(inland * 0.6, 13) + sin(x * 0.17) * sin(z * TAU / LENGTH) * minf(2, inland * 0.12)

func make_bank(side: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(22):
		for z in range(12):
			var points: Array[Vector3] = []
			for uv in [Vector2(x,z), Vector2(x+1,z), Vector2(x+1,z+1), Vector2(x,z+1)]:
				var px: float = side * (18 + uv.x * 5)
				var pz: float = -24 + uv.y * 4
				points.append(Vector3(px, height_at(px,pz), pz))
			for corner in ([0,1,2,0,2,3] if side > 0 else [0,2,1,0,3,2]):
				surface.add_vertex(points[corner])
	surface.generate_normals()
	return surface.commit()

func make_instances(parent: Node3D, mesh: Mesh, count: int) -> MultiMesh:
	var node := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = count
	node.multimesh = multi
	parent.add_child(node)
	return multi

func make_tree() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Crossed fronds with cut-out needles, rather than solid stacked cones.
	for tier in range(10):
		var bottom := 3.0 + tier * 1.1
		var radius := 4.5 - tier * 0.39
		for segment in range(9):
			var angle := segment * TAU / 9.0 + tier * 0.73
			var outward := Vector3(cos(angle), 0, sin(angle))
			var start := Vector3(0, bottom + 0.5, 0)
			var end := start + outward * radius * random.randf_range(0.8,1.2) + Vector3(0,-0.7,0)
			for across in [Vector3(-sin(angle),0.25,cos(angle)),Vector3(-sin(angle)*0.3,1.0,cos(angle)*0.3)]:
				var width: Vector3 = across * (0.45 + radius * 0.24)
				var vertices := [start-width,start+width,end+width*0.5,end-width*0.5]
				var uvs := [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]
				for corner in [0,1,2,0,2,3]:
					surface.set_uv(uvs[corner])
					surface.add_vertex(vertices[corner])
	surface.generate_normals()
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/stages/needles.gdshader")
	surface.set_material(material)
	return surface.commit()
