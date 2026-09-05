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
