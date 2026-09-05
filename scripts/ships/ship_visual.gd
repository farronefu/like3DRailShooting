extends Node3D
## Stable gameplay-facing root. Replacing the child only changes presentation.
const Appearance = preload("res://scripts/ships/ship_appearance.gd")
var appearance: Resource
var model: Node3D

static func spawn(parent: Node3D, definition: Resource) -> Node3D:
	var visual := new()
	parent.add_child(visual)
	visual.set_appearance(definition)
	return visual

func set_appearance(definition: Resource) -> void:
	if not definition is Appearance or definition.model_scene == null:
		push_error("A ship appearance must provide a valid model scene.")
		return
	var replacement: Node = definition.model_scene.instantiate()
	if not replacement is Node3D:
		replacement.free()
		push_error("Ship model scenes must have a Node3D root.")
		return
	if is_instance_valid(model):
		remove_child(model)
		model.queue_free()
	appearance = definition
	model = replacement
	add_child(model)
	model.position = definition.model_offset
	model.rotation_degrees = definition.model_rotation_degrees
	model.scale = definition.model_scale
