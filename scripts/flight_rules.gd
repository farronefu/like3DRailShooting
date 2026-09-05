extends RefCounted
## Pure gameplay rules shared by native and browser builds.
const DURATION := 240.0
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
	var ab := b - a
	var t := clampf((center - a).dot(ab) / maxf(ab.length_squared(), 0.000001), 0.0, 1.0)
	return (a + ab * t).distance_squared_to(center) <= radius * radius

static func phase(time: float) -> int:
	if time < 60.0:
		return 0
	if time < 125.0:
		return 1
	if time < 190.0:
		return 2
	return 3

static func phase_name(time: float) -> String:
	return ["OUTER APPROACH", "DEBRIS FIELD", "DEFENSE GRID", "FINAL RUN"][phase(time)]
