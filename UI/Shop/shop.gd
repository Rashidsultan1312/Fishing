extends Control

@onready var shop_container: ScrollContainer = %ShopContainer
@onready var shop_items: HBoxContainer = %ShopItems
@onready var money_label: Label = %MoneyLabel
@onready var money_container: MarginContainer = $MoneyLabel

var items_count : int
var scrollable_range : float
var offset : float
var is_playing : bool = false
var current_index : int = 0

func _ready() -> void:
	_update_money()
	_update_items()
	shop_items._update_money.connect(_update_money)

func _update_money() -> void:
	money_label.text = str(Global.save_data.get("Money"))
	_resize_money_container()

func _resize_money_container() -> void:
	await get_tree().process_frame
	var needed := money_label.size.x + 100.0
	money_container.offset_right = maxf(316.0, needed)

func _on_right_arrow_pressed() -> void:
	if is_playing: return
	is_playing = true
	if current_index < items_count - 1:
		current_index += 1
		var tween = _create_tween()
		tween.tween_property(shop_container, "scroll_horizontal", float(current_index) * offset, 0.7)
		await tween.finished
	else:
		current_index = 0
		var tween = _create_tween()
		tween.tween_property(shop_container, "scroll_horizontal", 0, 0.4)
		await tween.finished
	is_playing = false

func _on_left_arrow_pressed() -> void:
	if is_playing: return
	is_playing = true
	if current_index > 0:
		current_index -= 1
		var tween = _create_tween()
		tween.tween_property(shop_container, "scroll_horizontal", float(current_index) * offset, 0.7)
		await tween.finished
	else:
		current_index = items_count - 1
		var tween = _create_tween()
		tween.tween_property(shop_container, "scroll_horizontal", float(current_index) * offset, 0.4)
		await tween.finished
	is_playing = false

func _create_tween() -> Tween:
	var tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	return tween

const SHOP_ITEM = preload("uid://ba4s0lpws24lr")
var path = "res://UI/Shop/ShopItems/"

func _update_items() -> void:
	var rods : Array[Rod] = get_resources_in_folder()
	var i : int = 0
	for rod in rods:
		var item := SHOP_ITEM.instantiate()
		if i == 0:
			item._set_margins(180)
		elif i == rods.size() - 1:
			item._set_margins(90, 180)
		else:
			item._set_margins()
		shop_items.add_child(item)
		item.rod_data = rod
		item.index = i
		item._update_data()
		item.equip.connect(%ShopItems._equip)
		item.money_spent.connect(_update_money)
		if Global.save_data.get("Shop")[i]:
			item.bought = true
			item._update()
		i += 1
		await get_tree().process_frame
	await get_tree().process_frame
	items_count = shop_items.get_child_count()
	scrollable_range = shop_items.size.x - shop_container.size.x
	offset = scrollable_range / (items_count - 1)
	offset = 904.0

func get_resources_in_folder() -> Array[Rod]:
	var resources: Array[Rod] = []
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
	for rod_path in ROD_FILES:
		var res = load(rod_path)
		if res is Rod:
			resources.append(res)
	return resources

func _on_back_pressed() -> void:
	SceneTransition._transition(hide)
