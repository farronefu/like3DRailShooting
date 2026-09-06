extends Node3D
## Presentation only. Replace this PackedScene in boss_guardian.tres freely.
const V = preload("res://scripts/visuals.gd")

func _ready() -> void:
	var armor := Color("4b5550")
	var edge := Color("969c85")
	var dark := Color("222d2c")
	var body := V.sphere(self, Vector3.ZERO, 6.2, armor)
	body.scale = Vector3(1.1, 0.65, 1.4)
	V.box(self, Vector3(0,1.1,1), Vector3(5.8,2.7,10), edge)
	V.box(self, Vector3(0,2.6,0), Vector3(4.4,0.5,8), armor)
	for side in [-1.0,1.0]:
		var wing := V.box(self, Vector3(side*8,0,-1),Vector3(10,1.0,6), armor)
		wing.rotation.z = side * -0.12
		V.box(self,Vector3(side*8,0.6,-1),Vector3(7.8,0.35,4.8),edge)
		V.box(self,Vector3(side*8,0.9,-1),Vector3(7,0.22,3.8),armor)
		var pod := V.sphere(self,Vector3(side*11,-0.8,0),2.8,dark)
		pod.scale = Vector3(0.9,0.9,2.0)
		for z in [-3.0,0.0,3.0]:
			var rib := V.ring(self,2.6,edge,0.27)
			rib.position = Vector3(side*11,-0.8,z)
		V.box(self,Vector3(side*7,-1.5,5),Vector3(2.2,2.2,5),dark)
		V.box(self,Vector3(side*7,-1.5,7.6),Vector3(1.5,1.5,0.3),Color("ffb35a"),true)
		for i in range(5):
			V.box(self,Vector3(side*(3.8+i*1.35),1.2,-0.5),Vector3(0.28,0.12,3.4),dark)
		V.box(self,Vector3(side*3.5,3.2,-3),Vector3(0.4,2.6,4),armor)
		V.box(self,Vector3(side*5,0.2,2.7),Vector3(2.4,0.2,0.1),Color("e8b85e"),true)
		var jet := V.sphere(self,Vector3(side*11,-0.8,-5.3),1.6,Color("c0e7d0"),true)
		jet.scale.z = 0.45
	var core_ring := V.ring(self,2.9,dark,0.65)
	core_ring.position = Vector3(0,-0.2,7.5)
	var core := V.sphere(self,Vector3(0,-0.2,7.7),2.2,Color("ffb951"),true)
	core.scale.z = 0.42
	for side in [-1.0,1.0]:
		V.box(self,Vector3(side*1.2,-0.2,8.7),Vector3(0.2,3.5,0.15),dark)
