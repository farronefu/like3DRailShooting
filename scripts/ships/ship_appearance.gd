extends Resource
## Per-design presentation data. Flight rules and collision sizes live elsewhere.
@export var display_name: String = "Ship"
@export var model_scene: PackedScene
@export var model_scale: Vector3 = Vector3.ONE
@export var model_offset: Vector3 = Vector3.ZERO
@export var model_rotation_degrees: Vector3 = Vector3.ZERO
@export var preview_rotation_degrees: Vector3 = Vector3(-8, 155, -14)
@export var preview_scale: float = 2.3
