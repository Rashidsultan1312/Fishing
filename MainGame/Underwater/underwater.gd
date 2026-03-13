extends Node2D

signal phase_complete(caught_fish: FishData)
signal phase_cancelled

@onready var camera: Camera2D = $Camera2D
@onready var hook: Area2D = $Hook
@onready var spawner: Node2D = $FishSpawner
@onready var bg: ColorRect = $BG
@onready var depth_label: Label = $UI/DepthLabel
@onready var line: Line2D = $FishingLine
@onready var return_btn: Button = $UI/ReturnBtn
@onready var blur_overlay: ColorRect = $UI/BlurOverlay
@onready var hint_label: Label = $UI/HintLabel
@onready var splash_sfx: AudioStreamPlayer = $SplashSFX
@onready var ambient_sfx: AudioStreamPlayer = $AmbientSFX
@onready var bubble_sfx: AudioStreamPlayer = $BubbleSFX
@onready var catch_sfx: AudioStreamPlayer = $CatchSFX

var active: bool = false
var bubble_timer: float = 0.0
var rod: Rod = null
var intro_tween: Tween = null
var blur_tween: Tween = null
var hint_tween: Tween = null
var glow_tween: Tween = null

func _ready() -> void:
	hook.fish_caught.connect(_on_fish_caught)
	hook.hook_returned.connect(_on_hook_returned)
	if return_btn:
		return_btn.pressed.connect(_on_return_pressed)
	if hint_label:
		hint_label.modulate.a = 0.0
	$UI.visible = false
	hide()

func start(equipped_rod: Rod, _cast_power: float) -> void:
	rod = equipped_rod
	hook.setup(rod)

	var fish_pool = _load_fish_pool()
	spawner.setup(fish_pool)
	spawner.hook_ref = hook
	spawner.luck = rod.luck if rod else 0.0

	_apply_location_theme()

	show()
	$UI.visible = true
	active = true
	camera.position = Vector2(540, -960)
	camera.enabled = true

	hook.start()
	spawner.start()

	intro_tween = create_tween()
	intro_tween.tween_property(camera, "position:y", 400, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	_animate_blur()
	_show_hint()
	_start_glow()
	_play_splash()
	bubble_timer = 0.0

func stop() -> void:
	active = false
	hook.stop()
	spawner.stop()
	if intro_tween and intro_tween.is_running():
		intro_tween.kill()
	if blur_tween and blur_tween.is_running():
		blur_tween.kill()
	if hint_tween and hint_tween.is_running():
		hint_tween.kill()
	if glow_tween and glow_tween.is_running():
		glow_tween.kill()
	if blur_overlay and blur_overlay.material:
		blur_overlay.material.set_shader_parameter("intensity", 0.0)
		blur_overlay.material.set_shader_parameter("chromatic", 0.0)
	if ambient_sfx and ambient_sfx.playing:
		ambient_sfx.stop()
	camera.enabled = false
	$UI.visible = false
	hide()

func _animate_blur() -> void:
	if not blur_overlay or not blur_overlay.material:
		return
	if blur_tween and blur_tween.is_running():
		blur_tween.kill()
	blur_overlay.material.set_shader_parameter("intensity", 0.0)
	blur_overlay.material.set_shader_parameter("chromatic", 0.0)
	blur_tween = create_tween()
	blur_tween.tween_method(_set_blur, 0.0, 0.9, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	blur_tween.parallel().tween_method(_set_chromatic, 0.0, 0.008, 0.3).set_ease(Tween.EASE_OUT)
	blur_tween.tween_method(_set_blur, 0.9, 0.0, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	blur_tween.parallel().tween_method(_set_chromatic, 0.008, 0.002, 0.8).set_ease(Tween.EASE_IN)

func _set_blur(val: float) -> void:
	if blur_overlay and blur_overlay.material:
		blur_overlay.material.set_shader_parameter("intensity", val)

func _set_chromatic(val: float) -> void:
	if blur_overlay and blur_overlay.material:
		blur_overlay.material.set_shader_parameter("chromatic", val)

func _show_hint() -> void:
	if not hint_label:
		return
	hint_label.text = "Swipe to move\nthe hook"
	hint_label.modulate.a = 0.0
	if hint_tween and hint_tween.is_running():
		hint_tween.kill()
	hint_tween = create_tween()
	hint_tween.tween_property(hint_label, "modulate:a", 1.0, 0.8).set_delay(1.5)
	hint_tween.tween_property(hint_label, "modulate:a", 0.0, 1.0).set_delay(2.5)

func _start_glow() -> void:
	var glow = hook.get_node_or_null("Glow")
	if not glow:
		return
	if glow_tween and glow_tween.is_running():
		glow_tween.kill()
	glow_tween = create_tween().set_loops().bind_node(glow)
	glow_tween.tween_property(glow, "modulate:a", 0.5, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	glow_tween.tween_property(glow, "modulate:a", 0.2, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _process(_delta: float) -> void:
	if not active:
		return

	if intro_tween and intro_tween.is_running():
		return

	camera.position.y = lerpf(camera.position.y, hook.position.y - 400, 0.05)
	camera.position.x = 540.0
	spawner.update_depth(camera.position.y)

	if bg and bg.material:
		bg.material.set_shader_parameter("depth_offset", hook.depth)

	if depth_label:
		depth_label.text = str(int(hook.depth / 10.0)) + " m"

	if line:
		var eye = hook.position + Vector2(-8, -30)
		line.clear_points()
		line.add_point(Vector2(eye.x, camera.position.y - 960))
		line.add_point(eye)

	bubble_timer += _delta
	if bubble_timer > randf_range(2.0, 5.0):
		bubble_timer = 0.0
		if bubble_sfx and not bubble_sfx.playing:
			bubble_sfx.pitch_scale = randf_range(0.8, 1.4)
			bubble_sfx.play()

func _play_splash() -> void:
	if splash_sfx:
		splash_sfx.play()
	await get_tree().create_timer(1.0).timeout
	if ambient_sfx and active:
		ambient_sfx.play()

func _on_fish_caught(data: FishData) -> void:
	active = false
	spawner.stop()
	_hide_hint()
	if catch_sfx:
		catch_sfx.play()
	_shake_camera()
	phase_complete.emit(data)

func _shake_camera() -> void:
	var tw = create_tween()
	var base = camera.position
	for i in range(6):
		var offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		tw.tween_property(camera, "position", base + offset, 0.04)
	tw.tween_property(camera, "position", base, 0.05)

func _on_hook_returned() -> void:
	active = false
	spawner.stop()
	_hide_hint()
	phase_cancelled.emit()

func _hide_hint() -> void:
	if hint_tween and hint_tween.is_running():
		hint_tween.kill()
	if hint_label:
		hint_label.modulate.a = 0.0

func _on_return_pressed() -> void:
	if active:
		hook.start_return()

func _apply_location_theme() -> void:
	var loc = Global.current_location
	if loc == null:
		return
	spawner.spawn_interval = loc.spawn_interval

func _load_fish_pool() -> Array[FishData]:
	var pool: Array[FishData] = []
	var loc = Global.current_location
	var allowed_ids: Array[String] = []
	if loc:
		allowed_ids = loc.fish_ids

	const FISH_FILES: Array[String] = [
		"res://MainGame/Data/Fish/01_karass.tres",
		"res://MainGame/Data/Fish/02_plotva.tres",
		"res://MainGame/Data/Fish/03_okun.tres",
		"res://MainGame/Data/Fish/04_sudak.tres",
		"res://MainGame/Data/Fish/05_shuka.tres",
		"res://MainGame/Data/Fish/06_som.tres",
		"res://MainGame/Data/Fish/07_sterlyad.tres",
		"res://MainGame/Data/Fish/08_zolotaya.tres",
		"res://MainGame/Data/Fish/a01_arctic_char.tres",
		"res://MainGame/Data/Fish/a02_ice_cod.tres",
		"res://MainGame/Data/Fish/a03_narwhal.tres",
		"res://MainGame/Data/Fish/d01_anglerfish.tres",
		"res://MainGame/Data/Fish/d02_gulper_eel.tres",
		"res://MainGame/Data/Fish/d03_ghost_shark.tres",
		"res://MainGame/Data/Fish/t01_clownfish.tres",
		"res://MainGame/Data/Fish/t02_parrotfish.tres",
		"res://MainGame/Data/Fish/t03_lionfish.tres",
	]
	for path in FISH_FILES:
		var fid = path.get_file().get_basename()
		if allowed_ids.is_empty() or fid in allowed_ids:
			var res = load(path)
			if res is FishData:
				pool.append(res)
	if pool.is_empty():
		return _create_default_fish()
	return pool

func _create_default_fish() -> Array[FishData]:
	var pool: Array[FishData] = []

	var blue = FishData.new()
	blue.fish_name = "Crucian Carp"
	blue.price = 25
	blue.rarity = FishData.Rarity.COMMON
	blue.depth_min = 100
	blue.depth_max = 600
	blue.speed = 80
	blue.swim_pattern = FishData.SwimPattern.SINE
	blue.reel_difficulty = 0.5
	blue.texture = load("res://Assets/Fish/Blue.png") if ResourceLoader.exists("res://Assets/Fish/Blue.png") else null
	pool.append(blue)

	var orange = FishData.new()
	orange.fish_name = "Perch"
	orange.price = 50
	orange.rarity = FishData.Rarity.UNCOMMON
	orange.depth_min = 300
	orange.depth_max = 900
	orange.speed = 120
	orange.swim_pattern = FishData.SwimPattern.ZIGZAG
	orange.reel_difficulty = 1.0
	orange.texture = load("res://Assets/Fish/Orange.png") if ResourceLoader.exists("res://Assets/Fish/Orange.png") else null
	pool.append(orange)

	var red = FishData.new()
	red.fish_name = "Pike"
	red.price = 75
	red.rarity = FishData.Rarity.RARE
	red.depth_min = 500
	red.depth_max = 1200
	red.speed = 160
	red.swim_pattern = FishData.SwimPattern.ZIGZAG
	red.reel_difficulty = 1.8
	red.texture = load("res://Assets/Fish/Red.png") if ResourceLoader.exists("res://Assets/Fish/Red.png") else null
	pool.append(red)

	return pool
