extends SceneTree
## Hand-authored Wolfen study based on the user-supplied reference image.
## No geometry or textures are extracted from an existing game.
const Builder = preload("res://tools/mesh_builder.gd")
var m: RefCounted

func _initialize() -> void:
	call_deferred("build")

func panel(id: String, vertices: Array, normal: Vector3, thickness: float = 0.045) -> void:
	for i in range(1, vertices.size()-1):
		m.triangle(id, vertices[0], vertices[i], vertices[i+1], normal)
		m.triangle("underside", vertices[0]-normal*thickness, vertices[i]-normal*thickness, vertices[i+1]-normal*thickness, -normal)
	for i in range(vertices.size()):
		var a: Vector3 = vertices[i]
		var b: Vector3 = vertices[(i+1)%vertices.size()]
		m.quad("edge",a,b,b-normal*thickness,a-normal*thickness,(b-a).cross(normal))

func build() -> void:
	m = Builder.new()
	m.finish("white","e8e8e7",0.25,0.40)
	m.finish("white_shadow","aeb5bf",0.38,0.46)
	m.finish("red","b91d34",0.28,0.38)
	m.finish("red_light","cc2638",0.22,0.40)
	m.finish("red_dark","5c1027",0.40,0.47)
	m.finish("hull","444b56",0.48,0.40)
	m.finish("edge","8b919a",0.65,0.36)
	m.finish("underside","252b34",0.50,0.50)
	m.finish("graphite","111923",0.35,0.51)
	m.finish("glass","817566",0.65,0.19)
	m.finish("green","39e6a4",0,0.5,true)
	m.finish("violet","785ee8",0,0.5,true)
	m.finish("hot_core","d8bfff",0,0.5,true)
	# Central spear: sharply faceted upper hull and narrow armored underside.
	m.loft("hull","underside",0,[[-3.05,0.024,0.025,0.02,-0.15],[-2.38,0.17,0.11,0.075,-0.09],[-1.12,0.41,0.29,0.18,0.03],[-0.18,0.48,0.34,0.22,0.08],[0.74,0.38,0.34,0.24,0.09],[1.62,0.28,0.24,0.17,0.14],[2.32,0.10,0.09,0.09,0.29],[2.75,0.018,0.026,0.025,0.38]])
	# Nose center seam, tip sensor and inset angular cheek plates.
	m.beam("edge",Vector3(0,-0.09,-2.92),Vector3(0,0.33,-0.46),0.024,0.012)
	for side in [-1.0,1.0]:
		panel("hull",[Vector3(side*0.09,0.055,-2.28),Vector3(side*0.29,0.20,-1.35),Vector3(side*0.38,0.20,-0.88),Vector3(side*0.17,0.09,-1.58)],Vector3(side*0.65,0.75,0),0.025)
		m.beam("graphite",Vector3(side*0.105,0.061,-2.12),Vector3(side*0.30,0.242,-0.78),0.024)
		m.beam("green",Vector3(side*0.045,-0.028,-2.67),Vector3(side*0.066,0.017,-2.45),0.018)
	# Long bronze-black cockpit; the raised polygonal frame reads at gameplay scale.
	m.loft("edge","graphite",0,[[-1.30,0.07,0.07,0.04,0.29],[-0.51,0.25,0.23,0.05,0.32],[0.16,0.19,0.27,0.05,0.37],[0.43,0.12,0.13,0.04,0.37]])
	m.loft("glass","graphite",0,[[-1.18,0.045,0.045,0.018,0.32],[-0.50,0.21,0.20,0.022,0.37],[0.12,0.15,0.22,0.022,0.425],[0.33,0.078,0.10,0.02,0.415]])
	m.beam("graphite",Vector3(0,0.373,-1.15),Vector3(0,0.572,-0.50),0.024)
	m.beam("edge",Vector3(0,0.572,-0.50),Vector3(0,0.667,0.10),0.028)
	# Large, blade-like central dorsal stabilizer and its pale top cap.
	panel("hull",[Vector3(0.052,0.41,0.49),Vector3(0.052,1.24,1.58),Vector3(0.052,1.63,2.64),Vector3(0.052,0.61,2.02)],Vector3.RIGHT,0.104)
	panel("hull",[Vector3(-0.055,0.41,0.49),Vector3(-0.055,0.61,2.02),Vector3(-0.055,1.63,2.64),Vector3(-0.055,1.24,1.58)],Vector3.LEFT,0.015)
	for side in [-1.0,1.0]:
		panel("graphite",[Vector3(side*0.065,0.63,0.85),Vector3(side*0.065,1.14,1.60),Vector3(side*0.065,1.39,2.23),Vector3(side*0.065,0.75,1.76)],Vector3.RIGHT*side,0.005)
		panel("white_shadow",[Vector3(side*0.063,1.33,2.03),Vector3(side*0.063,1.63,2.64),Vector3(side*0.063,1.35,2.47)],Vector3.RIGHT*side,0.008)
		m.beam("green",Vector3(side*0.072,0.63,0.72),Vector3(side*0.072,0.77,0.97),0.03)
		# Red cockpit-side horns with bright leading edges.
		panel("red",[Vector3(side*0.24,0.35,0.22),Vector3(side*0.45,0.94,0.87),Vector3(side*0.35,0.35,0.88)],Vector3.RIGHT*side,0.065)
		m.beam("red_light",Vector3(side*0.24,0.37,0.25),Vector3(side*0.45,0.94,0.87),0.025)
		# Articulated-looking structural arms: separate shoulder root, hinges and skins.
		m.beam("graphite",Vector3(side*0.32,0.27,0.65),Vector3(side*1.04,0.16,0.75),0.26,0.26)
		m.plate("white",[[0.40,0.92],[0.43,0.59],[1.20,0.42],[1.28,0.79]],0.39,0.15,side)
		for x in [0.53,0.62]:
			m.beam("graphite",Vector3(side*x,0.40,0.61),Vector3(side*x,0.40,0.87),0.028,0.013)
		# Bulky red power modules, shaped across six cross-sections.
		m.loft("red","red_dark",side*1.00,[[-0.51,0.18,0.22,0.20,-0.05],[-0.14,0.43,0.44,0.33,-0.02],[0.61,0.51,0.48,0.35,0.01],[1.15,0.43,0.39,0.30,0.04],[1.53,0.24,0.25,0.20,0.06],[1.72,0.13,0.13,0.13,0.08]])
		panel("red_light",[Vector3(side*0.78,0.38,-0.12),Vector3(side*0.73,0.44,0.64),Vector3(side*1.03,0.54,0.87),Vector3(side*1.13,0.40,0.10)],Vector3.UP,0.018)
		panel("red_dark",[Vector3(side*1.39,0.10,-0.01),Vector3(side*1.48,0.11,0.65),Vector3(side*1.31,0.24,1.13),Vector3(side*1.31,-0.17,0.65)],Vector3.RIGHT*side,0.022)
		# Black intakes have a metal lip, green status slot and visible grille bars.
		m.block("edge",Vector3(side*1.02,-0.10,-0.45),Vector3(0.42,0.38,0.13))
		m.block("graphite",Vector3(side*1.02,-0.095,-0.526),Vector3(0.32,0.28,0.038))
		m.block("green",Vector3(side*1.02,0.036,-0.552),Vector3(0.26,0.025,0.016))
		for j in range(4):
			m.block("edge",Vector3(side*1.02,-0.19+j*0.064,-0.551),Vector3(0.24,0.013,0.013))
		# Grey inward-mounted cannons and machined barrel ends.
		m.loft("edge","graphite",side*0.60,[[-1.09,0.09,0.10,0.10,-0.04],[-0.80,0.15,0.19,0.19,-0.01],[0.12,0.18,0.23,0.20,0.02],[0.38,0.12,0.16,0.14,0.08]])
		m.tube("graphite",Vector3(side*0.60,-0.045,0),[[-1.27,0.086],[-0.94,0.10]],12)
		m.tube("edge",Vector3(side*0.60,-0.045,0),[[-1.285,0.089],[-1.22,0.10]],12)
		m.block("violet",Vector3(side*0.60,-0.045,-1.29),Vector3(0.073,0.063,0.008))
		m.beam("graphite",Vector3(side*0.62,0.21,-0.58),Vector3(side*0.62,0.255,0.12),0.035)
		# Signature long forward blades: raised leading ridge, white panels and dark seams.
		var a := Vector3(side*1.25,-0.03,0.12)
		var b := Vector3(side*1.70,-0.02,-0.30)
		var tip := Vector3(side*3.14,-0.52,-3.26)
		var d := Vector3(side*1.68,-0.27,-1.28)
		var ridge := Vector3(side*1.97,-0.15,-1.25)
		panel("white",[a,b,ridge,d],Vector3.UP,0.10)
		panel("white",[b,tip,ridge],Vector3.UP,0.06)
		panel("white_shadow",[ridge,tip,d],Vector3.UP,0.07)
		m.beam("edge",a,d,0.023)
		m.beam("graphite",a.lerp(d,0.41),b.lerp(tip,0.40),0.022)
		m.beam("edge",ridge,tip,0.014)
		# Short upper swept blades form the second pair of wings.
		panel("white",[Vector3(side*1.10,0.43,0.75),Vector3(side*1.45,0.43,0.52),Vector3(side*2.50,0.22,-0.28),Vector3(side*1.73,0.31,0.04)],Vector3.UP,0.10)
		panel("white_shadow",[Vector3(side*1.45,0.445,0.51),Vector3(side*2.50,0.23,-0.28),Vector3(side*1.84,0.34,0.12)],Vector3.UP,0.02)
		m.beam("graphite",Vector3(side*1.60,0.38,0.10),Vector3(side*1.47,0.45,0.50),0.023)
		# Red rear stabilizers project beyond the wing roots.
		panel("red",[Vector3(side*1.21,0.23,0.90),Vector3(side*1.47,1.05,1.70),Vector3(side*1.67,0.35,1.34),Vector3(side*1.56,0.12,0.83)],Vector3.RIGHT*side,0.08)
		m.beam("red_light",Vector3(side*1.21,0.26,0.94),Vector3(side*1.47,1.05,1.70),0.03)
		# Exhaust iris, segmented metal collar, luminous throat and tapered jet.
		var engine := Vector3(side*1.01,-0.06,0)
		m.tube("graphite",engine,[[1.19,0.27],[1.45,0.31],[1.68,0.265],[1.70,0.21],[1.43,0.16]],16)
		m.tube("edge",engine,[[1.56,0.282],[1.64,0.278],[1.69,0.255]],16)
		m.tube("violet",engine,[[1.704,0.209],[1.708,0.155]],16)
		m.tube("hot_core",engine,[[1.53,0],[1.54,0.16],[1.76,0.12],[2.22,0]],16)
		for j in range(12):
			var angle := TAU*j/12.0
			m.beam("edge",engine+Vector3(cos(angle)*0.31,sin(angle)*0.31,1.46),engine+Vector3(cos(angle)*0.266,sin(angle)*0.266,1.65),0.022)
		# Recessed access panels, bolts and small side marker lights.
		for z in [0.03,0.19,0.35]:
			m.block("graphite",Vector3(side*1.22,0.395,z),Vector3(0.09,0.015,0.025))
		for p in [Vector3(side*0.82,0.405,-0.06),Vector3(side*1.25,0.342,0.84)]:
			m.block("edge",p,Vector3(0.035,0.016,0.035))
		m.block("green",Vector3(side*1.425,0.09,0.28),Vector3(0.012,0.035,0.13))
	var model := Node3D.new()
	model.name = "Wolfen"
	var mesh := ArrayMesh.new()
	var triangles := 0
	for id in m.surfaces:
		var st: SurfaceTool = m.surfaces[id]
		st.index()
		st.commit(mesh)
	for i in range(mesh.get_surface_count()):
		triangles += mesh.surface_get_array_index_len(i)/3
	var airframe := MeshInstance3D.new()
	airframe.name = "Airframe"
	airframe.mesh = mesh
	model.add_child(airframe)
	airframe.owner = model
	DirAccess.make_dir_recursive_absolute("res://assets/models")
	var document := GLTFDocument.new()
	var data := GLTFState.new()
	var error := document.append_from_scene(model,data)
	if error == OK:
		error = document.write_to_filesystem(data,"res://assets/models/wolfen.glb")
	print("Wolfen: %d triangles / %d materials / GLB export=%d" % [triangles,mesh.get_surface_count(),error])
	model.free()
	quit(error)
