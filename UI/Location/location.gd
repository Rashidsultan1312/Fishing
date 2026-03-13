extends Control

@onready var texture_rect: TextureRect = $Texture
@onready var particles: CPUParticles2D = $Particles
@onready var lock_overlay: ColorRect = $LockOverlay
@onready var lock_icon: Label = $LockOverlay/LockVBox/LockIcon
@onready var lock_req: Label = $LockOverlay/LockVBox/LockReq
@onready var lock_progress: Label = $LockOverlay/LockVBox/LockProgress
@onready var diff_badge: Label = $InfoOverlay/DiffBadge
@onready var mult_badge: Label = $InfoOverlay/MultBadge
@onready var name_label: Label = $InfoOverlay/NameLabel

var loc_data: LocationData

func setup(loc: LocationData) -> void:
	loc_data = loc

	if loc.bg_texture:
		texture_rect.texture = loc.bg_texture
		texture_rect.material = null

	name_label.text = loc.location_name
	diff_badge.text = loc.difficulty_label
	mult_badge.text = str(loc.reward_multiplier) + "x"

	_color_diff_badge(loc.difficulty_label)
	_setup_particles(loc)
	_setup_lock(loc)

func _color_diff_badge(diff: String) -> void:
	var col: Color
	match diff:
		"Easy":
			col = Color(0.3, 0.85, 0.4)
		"Medium":
			col = Color(1.0, 0.8, 0.2)
		"Hard":
			col = Color(1.0, 0.45, 0.2)
		"Expert":
			col = Color(0.9, 0.2, 0.3)
		_:
			col = Color.WHITE
	diff_badge.add_theme_color_override("font_color", col)

func _setup_particles(loc: LocationData) -> void:
	if not particles:
		return
	match loc.location_id:
		"sakura":
			particles.color = Color(1.0, 0.7, 0.85, 0.5)
			particles.gravity = Vector2(15, 40)
			particles.direction = Vector2(-1, 1)
			particles.initial_velocity_min = 15.0
			particles.initial_velocity_max = 35.0
			particles.scale_amount_min = 4.0
			particles.scale_amount_max = 7.0
			particles.amount = 18
		"tropical":
			particles.color = Color(1.0, 0.95, 0.4, 0.45)
			particles.gravity = Vector2(0, -10)
			particles.direction = Vector2(0, -1)
			particles.initial_velocity_min = 5.0
			particles.initial_velocity_max = 20.0
			particles.scale_amount_min = 2.0
			particles.scale_amount_max = 4.0
			particles.amount = 12
		"arctic":
			particles.color = Color(0.85, 0.9, 1.0, 0.6)
			particles.gravity = Vector2(5, 50)
			particles.direction = Vector2(0, 1)
			particles.initial_velocity_min = 10.0
			particles.initial_velocity_max = 25.0
			particles.scale_amount_min = 3.0
			particles.scale_amount_max = 6.0
			particles.amount = 25
		"abyss":
			particles.color = Color(0.6, 0.3, 1.0, 0.5)
			particles.gravity = Vector2(0, -20)
			particles.direction = Vector2(0, -1)
			particles.initial_velocity_min = 8.0
			particles.initial_velocity_max = 18.0
			particles.scale_amount_min = 2.0
			particles.scale_amount_max = 5.0
			particles.amount = 15

func _setup_lock(loc: LocationData) -> void:
	var purchased = Global.is_location_purchased(loc)
	if purchased:
		lock_overlay.hide()
		texture_rect.modulate = Color.WHITE
		return

	var unlocked = Global.is_location_unlocked(loc)

	if unlocked:
		lock_overlay.show()
		lock_icon.text = "READY"
		lock_icon.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		lock_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
		texture_rect.modulate = Color.WHITE
	else:
		lock_overlay.show()
		lock_icon.text = "LOCKED"
		lock_icon.add_theme_color_override("font_color", Color(0.95, 0.7, 0.3))
		lock_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
		texture_rect.modulate = Color.WHITE

	match loc.unlock_type:
		"money":
			lock_req.text = "$" + str(loc.unlock_value)
			var money = Global.save_data.get("Money", 0)
			if money >= loc.unlock_value:
				lock_progress.text = "You have enough!"
				lock_progress.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 0.9))
			else:
				lock_progress.text = "$" + str(money) + " / $" + str(loc.unlock_value)
				lock_progress.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5, 0.8))
		"fish_caught":
			var caught = Global.save_data.get("TotalCaught", 0)
			lock_req.text = "Catch " + str(loc.unlock_value) + " fish"
			if caught >= loc.unlock_value:
				lock_progress.text = "Requirement met!"
				lock_progress.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 0.9))
			else:
				lock_progress.text = str(caught) + " / " + str(loc.unlock_value)
				lock_progress.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5, 0.8))
		_:
			lock_req.text = ""
			lock_progress.text = ""
			lock_overlay.hide()
			texture_rect.modulate = Color.WHITE
