extends RefCounted
## All meshes are original procedural primitives; no external game assets.
static var materials: Dictionary = {}

static func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var key := str(color) + str(glow)
	if materials.has(key):
		return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.72
	if glow:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	materials[key] = m
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = material(color, glow)
	n.position = pos
	parent.add_child(n)
	return n

static func sphere(parent: Node3D, pos: Vector3, radius: float, color: Color, glow: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	n.mesh = mesh
	n.material_override = material(color, glow)
	n.position = pos
	parent.add_child(n)
	return n

static func ring(parent: Node3D, radius: float, color: Color, thickness: float = 0.12) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	for i in range(16):
		var angle := float(i) * TAU / 16.0
		var part := box(root, Vector3(cos(angle), sin(angle), 0) * radius, Vector3(thickness, radius * 0.40, thickness), color, true)
		part.rotation.z = angle
	return root

static func ship(parent: Node3D, enemy: bool = false) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var body := Color("d1e5ee") if not enemy else Color("ee7858")
	var dark := Color("263b55") if not enemy else Color("66324a")
	var light := Color("54e4f2") if not enemy else Color("ffc185")
	box(root, Vector3.ZERO, Vector3(0.8, 0.5, 2.5), body)
	var nose := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.48
	cone.height = 1.5
	cone.radial_segments = 4
	nose.mesh = cone
	nose.material_override = material(body)
	nose.position.z = -1.8
	nose.rotation.x = -PI / 2.0
	root.add_child(nose)
	box(root, Vector3(0, 0.38, -0.35), Vector3(0.48, 0.24, 0.85), light, true)
	for side in [-1.0, 1.0]:
		var wing := box(root, Vector3(side * 1.3, -0.08, 0.25), Vector3(2.1, 0.13, 1.0), body)
		wing.rotation.y = side * -0.32
		box(root, Vector3(side * 2.15, 0, 0.1), Vector3(0.18, 0.22, 1.65), dark)
		box(root, Vector3(side * 0.65, 0, 1.1), Vector3(0.35, 0.4, 0.6), dark)
		var jet := box(root, Vector3(side * 0.65, 0, 1.65), Vector3(0.22, 0.22, 0.72), light, true)
		jet.name = "JetLeft" if side < 0 else "JetRight"
	var fin := box(root, Vector3(0, 0.6, 0.8), Vector3(0.12, 0.9, 0.8), dark)
	fin.rotation.x = -0.25
	return root
