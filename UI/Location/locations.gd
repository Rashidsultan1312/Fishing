extends Control

@onready var locations_hbox: HBoxContainer = %Locations
@onready var locations_container: ScrollContainer = %LocationsContainer
@onready var enter_btn: Button = $VBoxContainer/Container2/VBoxContainer/Enter
@onready var money_label: Label = %MoneyLabel
const LOCATION = preload("uid://b28l8gujf6nxv")

var location_data_list: Array[LocationData] = []
var is_playing: bool = false
var scene_index: int = 0
var offset: float = 904.0

func _ready() -> void:
	_load_locations()
	_update_items()

func _load_locations() -> void:
	location_data_list.clear()
	for path in Global.LOCATION_FILES:
		var res = load(path)
		if res is LocationData:
			location_data_list.append(res)
	location_data_list.sort_custom(func(a, b): return a.order < b.order)

func _on_right_arrow_pressed() -> void:
	if is_playing:
		return
	is_playing = true
	if scene_index < location_data_list.size() - 1:
		scene_index += 1
		var tween = _create_tween()
		tween.tween_property(locations_container, "scroll_horizontal", float(scene_index) * offset, 0.7)
		await tween.finished
	else:
		scene_index = 0
		var tween = _create_tween()
		tween.tween_property(locations_container, "scroll_horizontal", 0, 0.4)
		await tween.finished
	is_playing = false
	_update_enter_btn()

func _on_left_arrow_pressed() -> void:
	if is_playing:
		return
	is_playing = true
	if scene_index > 0:
		scene_index -= 1
		var tween = _create_tween()
		tween.tween_property(locations_container, "scroll_horizontal", float(scene_index) * offset, 0.7)
		await tween.finished
	else:
		scene_index = location_data_list.size() - 1
		var tween = _create_tween()
		tween.tween_property(locations_container, "scroll_horizontal", float(scene_index) * offset, 0.4)
		await tween.finished
	is_playing = false
	_update_enter_btn()

func _create_tween() -> Tween:
	var tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	return tween

func _update_items() -> void:
	for child in locations_hbox.get_children():
		child.queue_free()
	await get_tree().process_frame

	for i in range(location_data_list.size()):
		var loc = location_data_list[i]
		var item = LOCATION.instantiate()
		locations_hbox.add_child(item)
		item.setup(loc)
		await get_tree().process_frame

	await get_tree().process_frame
	offset = 1080.0
	_update_enter_btn()
	_update_money()

func _update_enter_btn() -> void:
	if scene_index >= location_data_list.size():
		return
	var loc = location_data_list[scene_index]
	var purchased = Global.is_location_purchased(loc)
	var unlocked = Global.is_location_unlocked(loc)
	if purchased:
		enter_btn.text = "Enter\n"
		enter_btn.disabled = false
	elif unlocked:
		if loc.unlock_type == "money":
			enter_btn.text = "Unlock $" + str(loc.unlock_value) + "\n"
		else:
			enter_btn.text = "Unlock\n"
		enter_btn.disabled = false
	else:
		enter_btn.text = "Locked\n"
		enter_btn.disabled = true

func _update_money() -> void:
	if money_label:
		money_label.text = str(Global.save_data.get("Money", 0))

func _on_back_pressed() -> void:
	SceneTransition._change_scene("res://UI/MainMenu/main_menu.tscn")

func _on_enter_pressed() -> void:
	if scene_index >= location_data_list.size():
		return
	var loc = location_data_list[scene_index]
	var purchased = Global.is_location_purchased(loc)
	if purchased:
		Global.current_location = loc
		Global.save_data["CurrentLocation"] = loc.location_id
		Global._save()
		SceneTransition._change_scene("res://MainGame/Main/main.tscn")
		return
	if Global.is_location_unlocked(loc):
		if Global.unlock_location(loc):
			_update_enter_btn()
			_update_money()
			_refresh_cards()

func _refresh_cards() -> void:
	for i in range(locations_hbox.get_child_count()):
		if i < location_data_list.size():
			var card = locations_hbox.get_child(i)
			if card.has_method("setup"):
				card.setup(location_data_list[i])
