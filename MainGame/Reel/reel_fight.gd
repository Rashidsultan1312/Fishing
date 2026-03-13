extends CanvasLayer

signal fight_won(fish_data: FishData)
signal fight_lost(fish_data: FishData)

var tension: float = 0.5
var fish_data: FishData = null
var rod_bonus: float = 0.0
var active: bool = false
var fight_timer: float = 0.0
var win_time: float = 4.0
var progress: float = 0.0
var max_fight_time: float = 20.0

var tap_power: float = 0.12
var tension_decay: float = 0.12
var fish_pull_base: float = 0.1
var zone_width: float = 0.28

var fish_pull_timer: float = 0.0
var fish_pull_dir: float = 1.0
var fish_pull_strength: float = 0.0

var zone_center: float = 0.5
var zone_drift_dir: float = 1.0
var zone_drift_speed: float = 0.04

var dash_timer: float = 0.0
var dash_cooldown: float = 5.0
var is_dashing: bool = false
var dash_remaining: float = 0.0

var hint_tween: Tween = null
var fish_icon_base_pos: Vector2 = Vector2.ZERO
var bar_bg_base_x: float = 0.0
var flash_ref: ColorRect = null

@onready var bar_bg: Control = $UI/BarBG
@onready var bar_fill: ColorRect = $UI/BarFill
@onready var green_zone: ColorRect = $UI/GreenZone
@onready var fish_icon: TextureRect = $UI/FishIcon
@onready var fish_name_label: Label = $UI/FishName
@onready var pct_label: Label = $UI/PctLabel
@onready var progress_fill: ColorRect = $UI/ProgressFill
@onready var progress_bg: ColorRect = $UI/ProgressBG
@onready var tap_area: Button = $UI/TapArea
@onready var hint_label: Label = $UI/HintLabel
@onready var snap_label: Label = $UI/SnapLabel
@onready var lose_label: Label = $UI/LoseLabel
@onready var reel_sfx: AudioStreamPlayer = $UI/ReelSFX
@onready var snap_sfx: AudioStreamPlayer = $UI/SnapSFX
@onready var win_sfx: AudioStreamPlayer = $UI/WinSFX
@onready var zone_arrow: Label = $UI/ZoneArrow

func _ready() -> void:
	hide()
	if tap_area:
		tap_area.pressed.connect(_on_tap)
	_create_flash_overlay()

func _create_flash_overlay() -> void:
	flash_ref = ColorRect.new()
	flash_ref.anchors_preset = Control.PRESET_FULL_RECT
	flash_ref.anchor_right = 1.0
	flash_ref.anchor_bottom = 1.0
	flash_ref.color = Color(0, 0, 0, 0)
	flash_ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(flash_ref)
	$UI.move_child(flash_ref, 0)

func start(data: FishData, bonus: float = 0.0) -> void:
	fish_data = data
	rod_bonus = bonus
	tension = 0.5
	progress = 0.0
	fight_timer = 0.0
	active = true
	fish_pull_timer = 0.0
	is_dashing = false
	dash_remaining = 0.0
	zone_center = 0.5
	zone_drift_dir = 1.0

	var diff = data.reel_difficulty if data else 1.0
	win_time = 3.0 + diff * 2.0
	fish_pull_strength = fish_pull_base * diff
	max_fight_time = 18.0 + (3.0 - diff) * 4.0
	zone_drift_speed = 0.03 + diff * 0.03
	zone_width = maxf(0.18, 0.3 - diff * 0.04)
	dash_cooldown = maxf(2.0, 5.0 - diff)
	dash_timer = dash_cooldown * 0.6

	if fish_icon:
		fish_icon_base_pos = fish_icon.position
		fish_icon.modulate = Color.WHITE
		fish_icon.scale = Vector2.ONE
	if fish_icon and data and data.texture:
		fish_icon.texture = data.texture
		fish_icon.modulate = data.tint if data.tint != Color.WHITE else Color.WHITE
	if fish_name_label and data:
		fish_name_label.text = data.fish_name
	if bar_bg:
		bar_bg_base_x = bar_bg.position.x
	if snap_label:
		snap_label.modulate.a = 0.0
	if lose_label:
		lose_label.modulate.a = 0.0
	if flash_ref:
		flash_ref.color = Color(0, 0, 0, 0)

	_apply_location_colors()
	_update_visuals()
	show()
	_pulse_hint()

func _apply_location_colors() -> void:
	var loc = Global.current_location
	if loc == null:
		return
	var overlay = get_node_or_null("Overlay")
	if overlay and overlay.material:
		overlay.material.set_shader_parameter("color_top", loc.reel_bg_top)
		overlay.material.set_shader_parameter("color_bottom", loc.reel_bg_bottom)
	var bubbles = get_node_or_null("Bubbles") as CPUParticles2D
	if bubbles:
		bubbles.color = loc.bubble_color

func stop() -> void:
	active = false
	if hint_tween and hint_tween.is_running():
		hint_tween.kill()
	if fish_icon:
		fish_icon.position = fish_icon_base_pos
		fish_icon.rotation = 0.0
		fish_icon.modulate = Color.WHITE
		fish_icon.scale = Vector2.ONE
	if bar_bg:
		bar_bg.position.x = bar_bg_base_x
	if flash_ref:
		flash_ref.color = Color(0, 0, 0, 0)
	hide()

func _pulse_hint() -> void:
	if not hint_label:
		return
	if hint_tween and hint_tween.is_running():
		hint_tween.kill()
	hint_label.modulate.a = 1.0
	hint_tween = create_tween().set_loops(2).bind_node(hint_label)
	hint_tween.tween_property(hint_label, "modulate:a", 0.3, 0.8)
	hint_tween.tween_property(hint_label, "modulate:a", 1.0, 0.8)
	hint_tween.chain().tween_property(hint_label, "modulate:a", 0.0, 0.5)

func _process(delta: float) -> void:
	if not active:
		return

	fight_timer += delta
	tension -= tension_decay * delta
	tension -= rod_bonus * 0.04 * delta

	_update_zone_drift(delta)
	_update_fish_pull(delta)
	_update_dash(delta)

	tension = clampf(tension, 0.0, 1.0)

	var green_min = zone_center - zone_width / 2.0
	var green_max = zone_center + zone_width / 2.0
	var in_zone = tension >= green_min and tension <= green_max

	if in_zone:
		progress += delta / win_time
	else:
		progress = maxf(0.0, progress - delta * 0.15 / win_time)

	_update_visuals()

	if tension >= 1.0:
		_finish(false)
		return
	if tension <= 0.0:
		_finish(false)
		return
	if fight_timer >= max_fight_time:
		_finish(false)
		return
	if progress >= 1.0:
		_finish(true)

func _finish(won: bool) -> void:
	active = false
	if won:
		if win_sfx:
			win_sfx.play()
		if pct_label:
			pct_label.text = "CATCH!"
		if fish_icon:
			var tw = create_tween().bind_node(fish_icon)
			tw.tween_property(fish_icon, "scale", Vector2(1.25, 1.25), 0.12).set_ease(Tween.EASE_OUT)
			tw.tween_property(fish_icon, "scale", Vector2.ONE, 0.15)
		if flash_ref:
			var tw2 = create_tween().bind_node(flash_ref)
			tw2.tween_property(flash_ref, "color", Color(0.0, 0.4, 0.1, 0.25), 0.1)
			tw2.tween_property(flash_ref, "color", Color(0, 0, 0, 0), 0.3)
		await get_tree().create_timer(0.5).timeout
		fight_won.emit(fish_data)
	else:
		if snap_sfx:
			snap_sfx.play()
		if pct_label:
			pct_label.text = "ESCAPED!"
		if fish_icon:
			var tw = create_tween().bind_node(fish_icon)
			tw.tween_property(fish_icon, "modulate:a", 0.0, 0.25)
		if flash_ref:
			var tw2 = create_tween().bind_node(flash_ref)
			tw2.tween_property(flash_ref, "color", Color(0.5, 0.0, 0.0, 0.35), 0.08)
			tw2.tween_property(flash_ref, "color", Color(0, 0, 0, 0), 0.35)
		await get_tree().create_timer(0.5).timeout
		fight_lost.emit(fish_data)

func _update_zone_drift(delta: float) -> void:
	zone_center += zone_drift_dir * zone_drift_speed * delta
	if zone_center > 0.7:
		zone_drift_dir = -1.0
	elif zone_center < 0.3:
		zone_drift_dir = 1.0
	zone_center = clampf(zone_center, 0.22, 0.78)

func _update_fish_pull(delta: float) -> void:
	fish_pull_timer += delta
	if fish_pull_timer > randf_range(0.3, 1.0):
		fish_pull_timer = 0.0
		fish_pull_dir = 1.0 if randf() > 0.4 else -1.0
		var diff = fish_data.reel_difficulty if fish_data else 1.0
		fish_pull_strength = fish_pull_base * diff * randf_range(0.6, 1.6)
	tension += fish_pull_dir * fish_pull_strength * delta

func _update_dash(delta: float) -> void:
	dash_timer += delta
	if is_dashing:
		dash_remaining -= delta
		tension += fish_pull_dir * 0.4 * delta
		if dash_remaining <= 0.0:
			is_dashing = false
		return
	if dash_timer >= dash_cooldown:
		dash_timer = 0.0
		is_dashing = true
		dash_remaining = randf_range(0.3, 0.6)
		fish_pull_dir = 1.0 if randf() > 0.5 else -1.0
		_shake_bar()
		if fish_pull_dir > 0 and snap_label:
			_flash_warning(snap_label)
		elif fish_pull_dir < 0 and lose_label:
			_flash_warning(lose_label)

func _shake_bar() -> void:
	if not bar_bg:
		return
	var tw = create_tween().bind_node(bar_bg)
	tw.tween_property(bar_bg, "position:x", bar_bg_base_x + 14.0, 0.03)
	tw.tween_property(bar_bg, "position:x", bar_bg_base_x - 12.0, 0.03)
	tw.tween_property(bar_bg, "position:x", bar_bg_base_x + 6.0, 0.03)
	tw.tween_property(bar_bg, "position:x", bar_bg_base_x, 0.03)

func _flash_warning(label: Label) -> void:
	var tw = create_tween().bind_node(label)
	tw.tween_property(label, "modulate:a", 1.0, 0.06)
	tw.tween_property(label, "modulate:a", 0.0, 0.4)

func _on_tap() -> void:
	if not active:
		return
	tension += tap_power
	if reel_sfx and not reel_sfx.playing:
		reel_sfx.pitch_scale = randf_range(0.9, 1.1)
		reel_sfx.play()
	_tap_feedback()

func _tap_feedback() -> void:
	if flash_ref:
		var tw = create_tween().bind_node(flash_ref)
		tw.tween_property(flash_ref, "color", Color(0.3, 0.5, 0.8, 0.12), 0.03)
		tw.tween_property(flash_ref, "color", Color(0, 0, 0, 0), 0.1)
	if fish_icon:
		var tw2 = create_tween().bind_node(fish_icon)
		tw2.tween_property(fish_icon, "scale", Vector2(1.08, 0.93), 0.04)
		tw2.tween_property(fish_icon, "scale", Vector2.ONE, 0.08).set_ease(Tween.EASE_OUT)

func _input(event: InputEvent) -> void:
	if not active:
		return
	if not visible:
		return
	if event is InputEventScreenTouch and event.pressed:
		tension += tap_power
		_tap_feedback()
	elif event is InputEventMouseButton and event.pressed:
		tension += tap_power
		_tap_feedback()

func _update_visuals() -> void:
	_update_green_zone()
	_update_bar()
	_update_progress_bar()
	_update_fish_anim()
	_update_danger_flash()
	_update_zone_arrow()

func _update_green_zone() -> void:
	if not green_zone or not bar_bg:
		return
	var bar_h = bar_bg.size.y
	var bar_y = bar_bg.position.y
	var gmin = zone_center - zone_width / 2.0
	var gmax = zone_center + zone_width / 2.0
	green_zone.position.y = bar_y + bar_h * (1.0 - gmax)
	green_zone.size.y = bar_h * (gmax - gmin)
	green_zone.position.x = bar_bg.position.x + 8
	green_zone.size.x = bar_bg.size.x - 16

func _update_bar() -> void:
	if not bar_fill or not bar_bg:
		return
	var bar_h = bar_bg.size.y
	var bar_y = bar_bg.position.y
	bar_fill.size.y = bar_h * tension
	bar_fill.position.y = bar_y + bar_h - bar_fill.size.y
	bar_fill.size.x = bar_bg.size.x - 16
	bar_fill.position.x = bar_bg.position.x + 8

	var gmin = zone_center - zone_width / 2.0
	var gmax = zone_center + zone_width / 2.0
	if tension >= gmin and tension <= gmax:
		bar_fill.color = Color(0.2, 0.8, 0.3)
	elif tension > 0.82 or tension < 0.18:
		bar_fill.color = Color(0.95, 0.2, 0.15)
	else:
		bar_fill.color = Color(0.95, 0.7, 0.1)

func _update_progress_bar() -> void:
	var pct = clampf(progress, 0.0, 1.0)
	if pct_label:
		pct_label.text = str(int(pct * 100.0)) + "%"
	if progress_fill and progress_bg:
		progress_fill.size.x = progress_bg.size.x * pct
		progress_fill.position.x = progress_bg.position.x
		progress_fill.position.y = progress_bg.position.y
		progress_fill.size.y = progress_bg.size.y

func _update_zone_arrow() -> void:
	if not zone_arrow or not bar_bg:
		return
	var bar_h = bar_bg.size.y
	var bar_y = bar_bg.position.y
	zone_arrow.position.y = bar_y + bar_h * (1.0 - zone_center) - 20.0

func _update_fish_anim() -> void:
	if not fish_icon:
		return
	var shake = 2.0
	if is_dashing:
		shake = 18.0
	elif tension > 0.82 or tension < 0.18:
		shake = 14.0 * absf(tension - 0.5)
	fish_icon.position.x = fish_icon_base_pos.x + sin(fight_timer * 20.0) * shake
	fish_icon.rotation = sin(fight_timer * 15.0) * shake * 0.005

func _update_danger_flash() -> void:
	if not flash_ref:
		return
	var danger = 0.0
	if tension > 0.8:
		danger = (tension - 0.8) / 0.2
	elif tension < 0.2:
		danger = (0.2 - tension) / 0.2
	if danger > 0.3:
		flash_ref.color.r = lerpf(flash_ref.color.r, 0.5 * danger, 0.1)
		flash_ref.color.a = lerpf(flash_ref.color.a, 0.2 * danger, 0.1)
