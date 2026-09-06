extends RefCounted
## Pure gameplay rules shared by native and browser builds.
const BOSS_ARRIVAL := 180.0
const MAX_HEALTH := 100.0
const PLAYER_SPEED := 18.0
const LIMIT_X := 13.0
const MIN_Y := -5.0
const MAX_Y := 8.0
const DEADZONE := 0.18

static func stick(raw: Vector2) -> Vector2:
	var length := raw.length()
	if length <= DEADZONE:
		return Vector2.ZERO
	return raw.normalized() * minf(1.0, (length - DEADZONE) / (1.0 - DEADZONE))

static func segment_hits(a: Vector3, b: Vector3, center: Vector3, radius: float) -> bool:
	return segment_entry(a,b,center,radius) < INF

static func segment_entry(a: Vector3, b: Vector3, center: Vector3, radius: float) -> float:
	var offset := a - center
	var c := offset.length_squared() - radius * radius
	if c <= 0:
		return 0.0
	var travel := b - a
	var length_squared := travel.length_squared()
	if length_squared < 0.000001:
		return INF
	var projection := offset.dot(travel)
	var discriminant := projection * projection - length_squared * c
	if discriminant < 0:
		return INF
	var t := (-projection - sqrt(discriminant)) / length_squared
	return t if t >= 0 and t <= 1 else INF

static func phase(time: float) -> int:
	if time < 60.0:
		return 0
	if time < 120.0:
		return 1
	if time < BOSS_ARRIVAL:
		return 2
	return 3

static func phase_name(time: float) -> String:
	return ["FOREST APPROACH", "RIVER VALLEY", "GUARDIAN TERRITORY", "RIVER GUARDIAN"][phase(time)]
