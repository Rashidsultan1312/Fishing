extends Node2D

enum State { IDLE, CASTING, UNDERWATER, REELING, RESULT }

var state: State = State.IDLE
var luck: float = 0.0
var current_rod: Rod = null
var caught_fish_data: FishData = null
var dive_tween: Tween = null
var dive_shader: ShaderMaterial = null

@onready var money_label: Label = %MoneyLabel1
@onready var money_container: MarginContainer = $"UI/Main/MoneyLabel"
@onready var points: GPUParticles2D = %Points
@onready var underwater: Node2D = $Underwater
@onready var reel_fight: CanvasLayer = $ReelFight
@onready var result_panel: CanvasLayer = $ResultPanel
@onready var above_water: CanvasLayer = $CanvasLayer2
@onready var catch_btn: Button = $"UI/Main/CatchFish"
@onready var tutorial: CanvasLayer = $Tutorial
@onready var dive_overlay: ColorRect = $DiveLayer/DiveOverlay

func _ready() -> void:
	_update_money()
	%Shop.shop_items._update_money.connect(_update_money)
	%Shop.shop_items._update_rarities.connect(_update_rarities)
	%Shop.visibility_changed.connect(_toggle_main_ui)
	%Settings.visibility_changed.connect(_toggle_main_ui)
	$UI/Hint2.hide()

	underwater.phase_complete.connect(_on_fish_caught_underwater)
	underwater.phase_cancelled.connect(_on_underwater_cancelled)
	reel_fight.fight_won.connect(_on_reel_won)
	reel_fight.fight_lost.connect(_on_reel_lost)

	_disable_all_focus($UI)
	_update_rarities()
	_load_rod()
	_apply_location()
	_enter_idle()
	_try_tutorial("welcome")

func _disable_all_focus(node: Node) -> void:
	if node is Control:
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_disable_all_focus(child)

func _load_rod() -> void:
	var rod_idx = Global.save_data.get("Rod", 0)
	var rods = _get_all_rods()
	if rod_idx < rods.size():
		current_rod = rods[rod_idx]

const ROD_FILES: Array[String] = [
	"res://UI/Shop/ShopItems/1wooden_rod.tres",
	"res://UI/Shop/ShopItems/2iron_rod.tres",
	"res://UI/Shop/ShopItems/3bronze_rod.tres",
	"res://UI/Shop/ShopItems/4golden_rod.tres",
	"res://UI/Shop/ShopItems/5emerald_rod.tres",
	"res://UI/Shop/ShopItems/6diamond_rod.tres",
	"res://UI/Shop/ShopItems/7amethyst_rod.tres",
	"res://UI/Shop/ShopItems/8ice_rod.tres",
	"res://UI/Shop/ShopItems/9petal_rod.tres",
]

func _get_all_rods() -> Array[Rod]:
	var rods: Array[Rod] = []
	for path in ROD_FILES:
		var res = load(path)
		if res is Rod:
			rods.append(res)
	return rods

func _apply_location() -> void:
	var loc = Global.current_location
	if loc == null:
		return
	var bg_node = above_water.get_node_or_null("Control/BG") as TextureRect
	if bg_node == null:
		return
	if loc.game_bg_texture:
		bg_node.material = null
		bg_node.texture = loc.game_bg_texture
	var girl = above_water.get_node_or_null("Girl2") as AnimatedSprite2D
	if girl:
		match loc.location_id:
			"sakura":
				girl.position = Vector2(430, 850)
				girl.scale = Vector2(0.85, 0.85)
			"tropical":
				girl.position = Vector2(280, 840)
				girl.scale = Vector2(0.82, 0.82)
			"arctic":
				girl.position = Vector2(230, 830)
				girl.scale = Vector2(0.82, 0.82)
			"abyss":
				girl.position = Vector2(280, 840)
				girl.scale = Vector2(0.82, 0.82)

func _enter_idle() -> void:
	state = State.IDLE
	if dive_tween and dive_tween.is_running():
		dive_tween.kill()
	above_water.offset = Vector2.ZERO
	above_water.show()
	if dive_overlay:
		dive_overlay.hide()
		dive_overlay.material = null
		dive_shader = null
	underwater.stop()
	reel_fight.stop()
	if result_panel:
		result_panel.hide()
	$UI/Main.show()
	catch_btn.show()
	catch_btn.disabled = false

func _enter_underwater(power: float) -> void:
	state = State.UNDERWATER
	above_water.hide()
	$UI/Main.hide()
	_load_rod()
	underwater.start(current_rod, power)

func _enter_reeling(fish_data: FishData) -> void:
	state = State.REELING
	caught_fish_data = fish_data
	underwater.stop()
	var bonus = current_rod.tension_bonus if current_rod else 0.0
	reel_fight.start(fish_data, bonus)

func _enter_result(fish_data: FishData, success: bool) -> void:
	state = State.RESULT
	reel_fight.stop()
	if success and fish_data:
		underwater.stop()
		var mult = Global.current_location.reward_multiplier if Global.current_location else 1.0
		var reward = int(fish_data.price * mult)
		Global.save_data["Money"] += reward
		Global.save_data["TotalCaught"] = Global.save_data.get("TotalCaught", 0) + 1

		var collection: Dictionary = Global.save_data.get("Collection", {})
		var fname = fish_data.fish_name
		var is_new = not collection.has(fname) or collection[fname] == 0
		collection[fname] = collection.get(fname, 0) + 1
		Global.save_data["Collection"] = collection

		var max_depth = Global.save_data.get("MaxDepth", 0.0)
		Global.save_data["MaxDepth"] = maxf(max_depth, underwater.hook.depth if underwater.hook else 0.0)

		Global._save()
		_update_money()
		_show_result(fish_data, reward, is_new)
	else:
		_show_miss()

func _show_result(fish_data: FishData, reward: int, is_new: bool = false) -> void:
	above_water.show()
	if not result_panel:
		await get_tree().create_timer(1.5).timeout
		_enter_idle()
		return

	result_panel.show()
	$UI/Main.hide()

	var icon = result_panel.get_node_or_null("UI/FishIcon")
	if icon and fish_data.texture:
		icon.texture = fish_data.texture
		icon.modulate = fish_data.tint if fish_data.tint != Color.WHITE else Color.WHITE
	var name_label = result_panel.get_node_or_null("UI/FishName")
	if name_label:
		name_label.text = fish_data.fish_name
		name_label.modulate = Color.WHITE
	var reward_label = result_panel.get_node_or_null("UI/RewardLabel")
	if reward_label:
		reward_label.text = "+" + str(reward)
		reward_label.modulate = Color.WHITE
		reward_label.scale = Vector2.ONE

	var new_label = result_panel.get_node_or_null("UI/NewLabel")
	var fishbook_hint = result_panel.get_node_or_null("UI/FishbookHint")
	if new_label:
		if is_new:
			new_label.text = "NEW SPECIES!"
			new_label.modulate = Color.WHITE
		else:
			new_label.text = ""
	if fishbook_hint:
		if is_new:
			fishbook_hint.text = "Check your Fishbook!"
			fishbook_hint.modulate = Color.WHITE
		else:
			fishbook_hint.text = ""

	points.emitting = true
	await get_tree().create_timer(3.0 if is_new else 2.5).timeout
	_enter_idle()

func _show_miss() -> void:
	if underwater.visible:
		_animate_surface()
		await dive_tween.finished
	else:
		above_water.show()
	_enter_idle()

func _animate_surface() -> void:
	if dive_tween and dive_tween.is_running():
		dive_tween.kill()

	underwater.hook.active = false
	underwater.hook.set_deferred("monitoring", false)
	underwater.spawner.stop()

	var cam = underwater.camera
	var hook_node = underwater.hook

	_setup_dive_shader()
	dive_overlay.show()

	dive_tween = create_tween()

	dive_tween.tween_property(cam, "position:y", -960, 2.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	dive_tween.parallel().tween_property(hook_node, "position:y", -300, 2.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	dive_tween.parallel().tween_method(_set_dive_ripple, 0.0, 0.8, 2.5)
	dive_tween.parallel().tween_method(_set_dive_chromatic, 0.0, 0.01, 2.5)

	dive_tween.tween_method(_set_dive_flash, 0.0, 0.35, 0.1)
	dive_tween.parallel().tween_method(_set_dive_ripple, 0.8, 1.0, 0.1)

	dive_tween.tween_callback(func():
		above_water.offset = Vector2.ZERO
		above_water.show()
	)

	dive_tween.tween_property(above_water, "offset", Vector2(12, -8), 0.05)
	dive_tween.tween_property(above_water, "offset", Vector2(-14, 10), 0.05)
	dive_tween.tween_property(above_water, "offset", Vector2(10, -6), 0.05)
	dive_tween.tween_property(above_water, "offset", Vector2(-8, 5), 0.04)
	dive_tween.tween_property(above_water, "offset", Vector2(4, -3), 0.04)
	dive_tween.tween_property(above_water, "offset", Vector2.ZERO, 0.03)

	dive_tween.parallel().tween_method(_set_dive_flash, 0.35, 0.0, 0.5)
	dive_tween.parallel().tween_method(_set_dive_ripple, 1.0, 0.0, 0.5)
	dive_tween.parallel().tween_method(_set_dive_chromatic, 0.01, 0.0, 0.5)

	dive_tween.tween_callback(func():
		above_water.offset = Vector2.ZERO
		dive_overlay.hide()
		dive_overlay.material = null
		dive_shader = null
		underwater.active = false
		underwater.stop()
	)

func _on_catch_fish_pressed() -> void:
	if state != State.IDLE:
		return
	if %Shop.visible or %Settings.visible:
		return
	if tutorial.active:
		return
	state = State.UNDERWATER
	$UI/Hint.hide()
	$UI/Hint2.hide()
	catch_btn.hide()
	$UI/Main.hide()
	_load_rod()
	underwater.start(current_rod, 0.6)
	_animate_dive()
	_try_tutorial_delayed("underwater", 2.0)

func _animate_dive() -> void:
	if dive_tween and dive_tween.is_running():
		dive_tween.kill()

	_setup_dive_shader()
	dive_overlay.show()

	dive_tween = create_tween()

	# Phase 1: Blue flash + ripple + zoom (0.3s)
	dive_tween.tween_method(_set_dive_flash, 0.0, 0.3, 0.1)
	dive_tween.parallel().tween_method(_set_dive_ripple, 0.0, 1.0, 0.2)
	dive_tween.parallel().tween_method(_set_dive_chromatic, 0.0, 0.006, 0.2)
	dive_tween.parallel().tween_method(_set_dive_zoom, 0.0, 0.04, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Phase 2: Quick shake
	dive_tween.tween_property(above_water, "offset", Vector2(6, -4), 0.035)
	dive_tween.tween_property(above_water, "offset", Vector2(-8, 5), 0.035)
	dive_tween.tween_property(above_water, "offset", Vector2(5, -3), 0.035)
	dive_tween.tween_property(above_water, "offset", Vector2(0, 0), 0.025)

	# Phase 3: Smooth dive slide + flash fade
	dive_tween.parallel().tween_method(_set_dive_flash, 0.3, 0.0, 0.3)
	dive_tween.parallel().tween_method(_set_dive_ripple, 1.0, 0.0, 0.5)
	dive_tween.tween_property(above_water, "offset", Vector2(0, -1920), 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	dive_tween.parallel().tween_method(_set_dive_chromatic, 0.006, 0.01, 0.4)

	# Phase 4: Cleanup
	dive_tween.tween_callback(func():
		above_water.hide()
		above_water.offset = Vector2.ZERO
		dive_overlay.hide()
		dive_overlay.material = null
		dive_shader = null
	)

func _setup_dive_shader() -> void:
	var shader = load("res://MainGame/Main/dive_effect.gdshader")
	dive_shader = ShaderMaterial.new()
	dive_shader.shader = shader
	dive_shader.set_shader_parameter("progress", 0.0)
	dive_shader.set_shader_parameter("flash_intensity", 0.0)
	dive_shader.set_shader_parameter("chromatic", 0.0)
	dive_shader.set_shader_parameter("vignette_strength", 0.0)
	dive_shader.set_shader_parameter("zoom", 0.0)
	dive_overlay.material = dive_shader

func _set_dive_flash(val: float) -> void:
	if dive_shader:
		dive_shader.set_shader_parameter("flash_intensity", val)

func _set_dive_ripple(val: float) -> void:
	if dive_shader:
		dive_shader.set_shader_parameter("progress", val)

func _set_dive_chromatic(val: float) -> void:
	if dive_shader:
		dive_shader.set_shader_parameter("chromatic", val)

func _set_dive_zoom(val: float) -> void:
	if dive_shader:
		dive_shader.set_shader_parameter("zoom", val)

func _on_fish_caught_underwater(fish_data: FishData) -> void:
	_enter_reeling(fish_data)
	_try_tutorial("reel")

func _on_underwater_cancelled() -> void:
	_enter_result(null, false)

func _on_reel_won(fish_data: FishData) -> void:
	_enter_result(fish_data, true)

func _on_reel_lost(fish_data: FishData) -> void:
	_enter_result(fish_data, false)

func _update_rarities() -> void:
	luck = Global.save_data["Luck"]
	_load_rod()

func _on_shop_pressed() -> void:
	if state != State.IDLE:
		return
	$UI/Hint2.hide()
	SceneTransition._transition(%Shop.show)

func _on_stats_pressed() -> void:
	%Stats.show()

func _on_fish_caught() -> void:
	points.emitting = true
	Global._save()

func _toggle_main_ui() -> void:
	if state == State.IDLE:
		$"UI/Main".visible = not (%Shop.visible or %Settings.visible)

func _update_money() -> void:
	money_label.text = str(Global.save_data.get("Money"))
	_resize_money_container()

func _resize_money_container() -> void:
	await get_tree().process_frame
	var needed := money_label.size.x + 100.0
	money_container.offset_right = maxf(316.0, needed)

func _on_settings_pressed() -> void:
	if state != State.IDLE:
		return
	SceneTransition._transition(%Settings.show)

func _on_back_pressed() -> void:
	if state != State.IDLE:
		return
	SceneTransition._change_scene("res://UI/Location/locations.tscn")

func _is_tutorial_done(key: String) -> bool:
	var done: Dictionary = Global.save_data.get("TutorialDone", {})
	return done.has(key)

func _mark_tutorial_done(key: String) -> void:
	var done: Dictionary = Global.save_data.get("TutorialDone", {})
	done[key] = true
	Global.save_data["TutorialDone"] = done
	Global._save()

func _try_tutorial(key: String) -> void:
	if _is_tutorial_done(key):
		return
	if not tutorial:
		return

	var msgs = {
		"welcome": "Tap anywhere to dive\nunderwater and catch fish!",
		"underwater": "Swipe to steer the hook.\nTouch a fish to catch it!",
		"reel": "Tap to reel in the line!\nKeep the bar in the\ngreen zone to win!",
	}

	if not msgs.has(key):
		return

	_mark_tutorial_done(key)
	tutorial.show_tip(msgs[key])
	await tutorial.dismissed

func _try_tutorial_delayed(key: String, delay: float) -> void:
	if _is_tutorial_done(key):
		return
	await get_tree().create_timer(delay).timeout
	_try_tutorial(key)
