extends Node3D
## Boss behavior and hit volumes remain independent of the selected model.
const MAX_HEALTH := 420.0
var health := MAX_HEALTH
var age := 0.0
var attack_timer := 2.0
var attack_count := 0
var active := false
var phase := 1
var telegraph := false
var volley_target := Vector3.ZERO

func volumes() -> Array[Dictionary]:
	if not active or health <= 0:
		return []
	return [{"center":position+Vector3(0,-0.2,7.7),"radius":2.5,"damage":2}, {"center":position,"radius":6.5,"damage":1}, {"center":position+Vector3(-10,0,0),"radius":3.4,"damage":1}, {"center":position+Vector3(10,0,0),"radius":3.4,"damage":1}]

func update(game: Node3D, dt: float) -> void:
	age += dt
	position.z = move_toward(position.z, -64, dt * 27)
	active = position.z >= -65
	position.x = sin(age * 0.38) * 7
	position.y = 3 + sin(age * 0.62) * 2.5
	if not active:
		return
	phase = 2 if health <= MAX_HEALTH * 0.5 else 1
	attack_timer -= dt
	if attack_timer <= 0.85 and not telegraph:
		telegraph = true
		volley_target = game.player.position # Warn, then fire at this locked position.
	if attack_timer <= 0:
		attack_count += 1
		for side in [-1.0,1.0]:
			var origin := position + Vector3(side*7,-1.5,8)
			for spread in range(-phase,phase+1):
				var target := volley_target + Vector3(spread*3.8, sin(attack_count)*2,0)
				game.spawn_projectile(origin,(target-origin).normalized()*(37+phase*5),true)
		telegraph = false
		attack_timer = 2.2 if phase == 1 else 1.65
