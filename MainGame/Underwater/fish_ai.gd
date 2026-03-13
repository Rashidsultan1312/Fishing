extends Area2D

var data: FishData
var swim_time: float = 0.0
var direction: float = 1.0
var base_y: float = 0.0
var speed: float = 100.0
var amplitude: float = 30.0
var viewport_width: float = 1080.0
var active: bool = true

var fleeing: bool = false
var alert_dist: float = 250.0
var flee_mult: float = 2.8
var hook_ref: Node2D = null
var burst_timer: float = 0.0
var burst_speed: float = 1.0

func setup(fish_data: FishData, spawn_pos: Vector2, dir: float = 1.0) -> void:
	data = fish_data
	position = spawn_pos
	base_y = spawn_pos.y
	direction = dir
	speed = data.speed
	set_meta("fish_data", data)

	if data.texture:
		$Sprite.texture = data.texture
		var tex_size = data.texture.get_size()
		var target = 120.0
		var fit = target / maxf(tex_size.x, tex_size.y)
		$Sprite.scale = Vector2(fit, fit)

	if data.tint != Color.WHITE:
		$Sprite.modulate = data.tint
	$Sprite.flip_h = direction < 0
	amplitude = randf_range(20.0, 50.0)
	burst_timer = randf_range(2.0, 6.0)

func _physics_process(delta: float) -> void:
	if not active:
		return

	swim_time += delta
	burst_timer -= delta

	if burst_timer <= 0.0:
		burst_timer = randf_range(3.0, 8.0)
		burst_speed = randf_range(1.5, 2.5)

	burst_speed = lerpf(burst_speed, 1.0, delta * 2.0)

	if hook_ref and hook_ref.visible and not fleeing:
		var dist = position.distance_to(hook_ref.position)
		if dist < alert_dist:
			if data.flee_on_hook:
				fleeing = true
				direction = sign(position.x - hook_ref.position.x)
				if direction == 0:
					direction = 1.0
				$Sprite.flip_h = direction < 0
			else:
				var react = clampf(1.0 - dist / alert_dist, 0.0, 1.0)
				burst_speed = maxf(burst_speed, 1.0 + react * 1.2)
				if dist < 100.0 and randf() < 0.02:
					direction *= -1.0
					$Sprite.flip_h = direction < 0

	var spd = speed * burst_speed
	if fleeing:
		spd = speed * flee_mult

	match data.swim_pattern:
		FishData.SwimPattern.LINEAR:
			position.x += spd * direction * delta
		FishData.SwimPattern.SINE:
			position.x += spd * direction * delta
			if not fleeing:
				position.y = base_y + sin(swim_time * 2.0) * amplitude
		FishData.SwimPattern.ZIGZAG:
			position.x += spd * direction * delta
			if not fleeing:
				position.y = base_y + (fmod(swim_time, 1.0) - 0.5) * amplitude * 2.0
		FishData.SwimPattern.CIRCLE:
			position.x += cos(swim_time * 1.5) * spd * 0.5 * delta
			position.y = base_y + sin(swim_time * 1.5) * amplitude
		FishData.SwimPattern.IDLE:
			position.y = base_y + sin(swim_time * 0.8) * amplitude * 0.3
			if hook_ref and position.distance_to(hook_ref.position) < 180.0:
				position.x += spd * direction * delta * 0.5

	if position.x < -300 or position.x > viewport_width + 300:
		queue_free()
