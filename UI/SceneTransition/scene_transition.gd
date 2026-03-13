extends CanvasLayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	_setup_animation()
	color_rect.modulate.a = 0.0

func _setup_animation() -> void:
	var anim := Animation.new()
	anim.length = 0.4
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, "ColorRect:modulate")
	anim.track_insert_key(track, 0.0, Color(1, 1, 1, 0))
	anim.track_insert_key(track, 0.4, Color(1, 1, 1, 1))
	var lib := AnimationLibrary.new()
	lib.add_animation("Transition", anim)
	animation_player.add_animation_library("", lib)

func _change_scene(scene_path: String) -> void:
	animation_player.play("Transition")
	await animation_player.animation_finished
	var cached = Global.get_cached_scene(scene_path)
	if cached:
		get_tree().change_scene_to_packed(cached)
	else:
		get_tree().change_scene_to_file(scene_path)
	await get_tree().tree_changed
	animation_player.play_backwards("Transition")

func _transition(function: Callable) -> void:
	animation_player.play("Transition")
	await animation_player.animation_finished
	await function.call()
	animation_player.play_backwards("Transition")
