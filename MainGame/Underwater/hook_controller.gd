extends Area2D

signal fish_caught(fish_data: FishData)
signal hook_returned

var sink_speed: float = 200.0
var max_depth: float = 99999.0
var depth: float = 0.0
var active: bool = false
var returning: bool = false
var target_pos: Vector2 = Vector2(540, 100)
var move_speed: float = 500.0
var viewport_width: float = 1080.0
var current_time: float = 0.0

func setup(rod: Rod) -> void:
	sink_speed = rod.sink_speed if rod else 200.0
	max_depth = rod.line_length if rod else 99999.0
	move_speed = sink_speed * 2.5

func start() -> void:
	depth = 0.0
	target_pos = Vector2(viewport_width / 2.0, 100)
	position = Vector2(viewport_width / 2.0, 0)
	active = true
	returning = false
	monitoring = true
	show()

func stop() -> void:
	active = false
	set_deferred("monitoring", false)
	hide()

func start_return() -> void:
	if active and not returning:
		returning = true

func _physics_process(delta: float) -> void:
	if not active:
		return

	if returning:
		position.y -= sink_speed * 3.0 * delta
		if position.y <= -100:
			active = false
			hook_returned.emit()
		return

	position = position.move_toward(target_pos, move_speed * delta)

	current_time += delta
	var current_str = sin(current_time * 0.4) * 50.0 + sin(current_time * 0.7) * 25.0
	var depth_mult = clampf(depth / 500.0, 0.3, 1.5)
	position.x += current_str * depth_mult * delta

	position.x = clampf(position.x, 60.0, viewport_width - 60.0)
	position.y = maxf(position.y, 20.0)
	depth = position.y

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_pos

func _input(event: InputEvent) -> void:
	if not active or returning:
		return

	var screen_pos := Vector2.ZERO
	var valid := false

	if event is InputEventScreenTouch and event.pressed:
		screen_pos = event.position
		valid = true
	elif event is InputEventScreenDrag:
		screen_pos = event.position
		valid = true
	elif event is InputEventMouseButton and event.pressed:
		screen_pos = event.position
		valid = true
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		screen_pos = event.position
		valid = true

	if valid:
		target_pos = _screen_to_world(screen_pos)

func _on_area_entered(area: Area2D) -> void:
	if not active or returning:
		return
	if area.has_meta("fish_data"):
		var data = area.get_meta("fish_data")
		active = false
		set_deferred("monitoring", false)
		area.queue_free()
		fish_caught.emit(data)
