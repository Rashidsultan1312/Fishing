extends Control

@onready var progress_bar: ColorRect = $ProgressFill
@onready var progress_bg: ColorRect = $ProgressBG
@onready var status_label: Label = $StatusLabel

var scenes_to_load: Array[String] = [
	"res://UI/MainMenu/main_menu.tscn",
	"res://UI/Location/locations.tscn",
	"res://MainGame/Main/main.tscn",
	"res://MainGame/Underwater/underwater.tscn",
	"res://MainGame/Reel/reel_fight.tscn",
	"res://MainGame/Main/result_panel.tscn",
	"res://MainGame/Underwater/fish.tscn",
	"res://UI/Shop/shop.tscn",
	"res://UI/settings.tscn",
	"res://UI/Fishbook/fishbook.tscn",
]

var pending: Array[String] = []
var total: int = 0

func _ready() -> void:
	_update_progress(0.0)
	_start_loading()

func _start_loading() -> void:
	for path in scenes_to_load:
		var err = ResourceLoader.load_threaded_request(path)
		if err == OK:
			pending.append(path)
	total = pending.size()
	if total == 0:
		_loading_done()

func _process(_delta: float) -> void:
	if pending.is_empty():
		return

	var path = pending[0]
	var status = ResourceLoader.load_threaded_get_status(path)

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var res = ResourceLoader.load_threaded_get(path)
		if res is PackedScene:
			Global.cache_scene(path, res)
		pending.remove_at(0)
		_update_progress(1.0 - float(pending.size()) / float(total))
		if pending.is_empty():
			_loading_done()
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		pending.remove_at(0)
		if pending.is_empty():
			_loading_done()

func _update_progress(pct: float) -> void:
	if progress_bar and progress_bg:
		progress_bar.size.x = progress_bg.size.x * pct
	if status_label:
		status_label.text = str(int(pct * 100.0)) + "%"

func _loading_done() -> void:
	set_process(false)
	SceneTransition.color_rect.modulate.a = 1.0
	get_tree().tree_changed.connect(_on_tree_ready, CONNECT_ONE_SHOT)
	var menu = Global.get_cached_scene("res://UI/MainMenu/main_menu.tscn")
	if menu:
		get_tree().change_scene_to_packed(menu)
	else:
		get_tree().change_scene_to_file("res://UI/MainMenu/main_menu.tscn")

func _on_tree_ready() -> void:
	SceneTransition.animation_player.play_backwards("Transition")
