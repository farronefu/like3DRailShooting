extends SceneTree
## Offline builder for the original enemy design. Runtime loads enemy_scout.glb.
const Visuals = preload("res://scripts/visuals.gd")
func _initialize() -> void:
	call_deferred("build")
func assign_owner(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		assign_owner(child, owner_node)
func build() -> void:
	var parent := Node3D.new()
	var model := ship(parent, true)
	model.name = "Scout"
	assign_owner(model, model)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var error := doc.append_from_scene(model, state)
	if error == OK:
		error = doc.write_to_filesystem(state, "res://assets/models/enemy_scout.glb")
	print("Enemy model export: ", error)
	parent.free()
	quit(error)

static func ship(parent: Node3D, enemy: bool = false) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var body := Color("d1e5ee") if not enemy else Color("ee7858")
	var dark := Color("263b55") if not enemy else Color("66324a")
	var light := Color("54e4f2") if not enemy else Color("ffc185")
	Visuals.box(root, Vector3.ZERO, Vector3(0.8, 0.5, 2.5), body)
	var nose := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.48
	cone.height = 1.5
	cone.radial_segments = 4
	nose.mesh = cone
	nose.material_override = Visuals.material(body)
	nose.position.z = -1.8
	nose.rotation.x = -PI / 2.0
	root.add_child(nose)
	Visuals.box(root, Vector3(0, 0.38, -0.35), Vector3(0.48, 0.24, 0.85), light, true)
	for side in [-1.0, 1.0]:
		var wing := Visuals.box(root, Vector3(side * 1.3, -0.08, 0.25), Vector3(2.1, 0.13, 1.0), body)
		wing.rotation.y = side * -0.32
		Visuals.box(root, Vector3(side * 2.15, 0, 0.1), Vector3(0.18, 0.22, 1.65), dark)
		Visuals.box(root, Vector3(side * 0.65, 0, 1.1), Vector3(0.35, 0.4, 0.6), dark)
		var jet := Visuals.box(root, Vector3(side * 0.65, 0, 1.65), Vector3(0.22, 0.22, 0.72), light, true)
		jet.name = "JetLeft" if side < 0 else "JetRight"
	var fin := Visuals.box(root, Vector3(0, 0.6, 0.8), Vector3(0.12, 0.9, 0.8), dark)
	fin.rotation.x = -0.25
	return root
