extends RefCounted
## Offline mesh helpers. Runtime ships load generated GLB assets.
var surfaces: Dictionary = {}
var finishes: Dictionary = {}

func finish(id: String, color: String, metallic: float, roughness: float, unlit: bool = false) -> void:
	var material := StandardMaterial3D.new()
	material.resource_name = id
	material.albedo_color = Color(color)
	material.metallic = metallic
	material.roughness = roughness
	if unlit:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = Color(color)
	finishes[id] = material
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	surfaces[id] = st

func triangle(id: String, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.length_squared() < 0.1:
		return
	if normal.dot(outward) < 0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	var st: SurfaceTool = surfaces[id]
	# Godot renders clockwise front faces. Keep explicit outward normals.
	for v in [a, c, b]:
		st.set_normal(normal)
		st.add_vertex(v)

func quad(id: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
	triangle(id, a, b, c, outward)
	triangle(id, a, c, d, outward)

func block(id: String, at: Vector3, size: Vector3) -> void:
	var h := size / 2.0
	var p := [at + Vector3(-h.x,-h.y,-h.z), at + Vector3(h.x,-h.y,-h.z), at + Vector3(h.x,h.y,-h.z), at + Vector3(-h.x,h.y,-h.z), at + Vector3(-h.x,-h.y,h.z), at + Vector3(h.x,-h.y,h.z), at + Vector3(h.x,h.y,h.z), at + Vector3(-h.x,h.y,h.z)]
	for face in [[0,1,2,3,Vector3.FORWARD], [5,4,7,6,Vector3.BACK], [4,0,3,7,Vector3.LEFT], [1,5,6,2,Vector3.RIGHT], [3,2,6,7,Vector3.UP], [4,5,1,0,Vector3.DOWN]]:
		quad(id,p[face[0]],p[face[1]],p[face[2]],p[face[3]],face[4])

func beam(id: String, from: Vector3, to: Vector3, width: float, depth: float = -1) -> void:
	if depth < 0:
		depth = width
	var axis := (to - from).normalized()
	var right := axis.cross(Vector3.UP).normalized()
	if right.length() < 0.1:
		right = Vector3.RIGHT
	var up := right.cross(axis).normalized()
	var points: Array[Vector3] = []
	for center in [from, to]:
		for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
			points.append(center + right * corner.x * width / 2 + up * corner.y * depth / 2)
	for i in range(4):
		var j := (i + 1) % 4
		quad(id,points[i],points[j],points[j+4],points[i+4],(points[i]+points[j])/2-from)
	quad(id,points[0],points[1],points[2],points[3],-axis)
	quad(id,points[4],points[5],points[6],points[7],axis)

func loft(top: String, lower: String, at_x: float, sections: Array) -> void:
	# Section = z, half-width, upper height, lower height, vertical center.
	var rings: Array = []
	for s in sections:
		var ring: Array[Vector3] = []
		for xy in [Vector2(0,1),Vector2(0.76,0.72),Vector2(1,0),Vector2(0.72,-0.75),Vector2(0,-1),Vector2(-0.72,-0.75),Vector2(-1,0),Vector2(-0.76,0.72)]:
			ring.append(Vector3(at_x + xy.x * s[1], s[4] + xy.y * (s[2] if xy.y >= 0 else s[3]), s[0]))
		rings.append(ring)
	for r in range(rings.size()-1):
		for i in range(8):
			var j := (i+1)%8
			var outward: Vector3 = (rings[r][i] + rings[r][j]) / 2 - Vector3(at_x,sections[r][4],sections[r][0])
			quad(top if i in [0,1,6,7] else lower,rings[r][i],rings[r][j],rings[r+1][j],rings[r+1][i],outward)
	for end in [0,rings.size()-1]:
		var center := Vector3(at_x, sections[end][4],sections[end][0])
		for i in range(8):
			triangle(lower,center,rings[end][i],rings[end][(i+1)%8],Vector3.FORWARD if end == 0 else Vector3.BACK)

func plate(id: String, outline: Array, y: float, thickness: float, side: float = 1) -> void:
	var points := PackedVector2Array()
	for point in outline:
		points.append(Vector2(point[0]*side,point[1]))
	var faces := Geometry2D.triangulate_polygon(points)
	for i in range(0,faces.size(),3):
		var a := points[faces[i]]
		var b := points[faces[i+1]]
		var c := points[faces[i+2]]
		triangle(id,Vector3(a.x,y,a.y),Vector3(b.x,y,b.y),Vector3(c.x,y,c.y),Vector3.UP)
		triangle("underside",Vector3(a.x,y-thickness,a.y),Vector3(b.x,y-thickness,b.y),Vector3(c.x,y-thickness,c.y),Vector3.DOWN)
	for i in range(points.size()):
		var a := points[i]
		var b := points[(i+1)%points.size()]
		var outward := Vector3(b.y-a.y,0,a.x-b.x) * side
		quad("edge",Vector3(a.x,y,a.y),Vector3(b.x,y,b.y),Vector3(b.x,y-thickness,b.y),Vector3(a.x,y-thickness,a.y),outward)

func tube(id: String, center: Vector3, profiles: Array, segments: int = 16) -> void:
	# Profile = local z, radius. Also supports reversing inward for a nozzle throat.
	for p in range(profiles.size()-1):
		for i in range(segments):
			var angle := TAU * i / segments
			var next := TAU * (i+1) / segments
			var a: Vector3 = center + Vector3(cos(angle)*profiles[p][1],sin(angle)*profiles[p][1],profiles[p][0])
			var b: Vector3 = center + Vector3(cos(next)*profiles[p][1],sin(next)*profiles[p][1],profiles[p][0])
			var c: Vector3 = center + Vector3(cos(next)*profiles[p+1][1],sin(next)*profiles[p+1][1],profiles[p+1][0])
			var d: Vector3 = center + Vector3(cos(angle)*profiles[p+1][1],sin(angle)*profiles[p+1][1],profiles[p+1][0])
			var outward := Vector3(cos((angle+next)/2),sin((angle+next)/2),0)
			if is_equal_approx(profiles[p][0], profiles[p+1][0]):
				outward = Vector3.BACK
			elif profiles[p+1][0] < profiles[p][0]:
				outward = -outward
			quad(id,a,b,c,d,outward)
