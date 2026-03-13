extends Control

const RARITY_COLORS = {
	0: Color(0.7, 0.7, 0.7),
	1: Color(0.3, 0.8, 0.3),
	2: Color(0.3, 0.5, 0.95),
	3: Color(0.7, 0.3, 0.9),
	4: Color(1.0, 0.8, 0.1),
}

const RARITY_NAMES = {
	0: "Common",
	1: "Uncommon",
	2: "Rare",
	3: "Epic",
	4: "Legendary",
}

var all_fish: Array[FishData] = []

@onready var container: VBoxContainer = $Scroll/List
@onready var title_label: Label = $Title
@onready var count_label: Label = $CountLabel

func _ready() -> void:
	hide()

func _on_visibility_changed() -> void:
	if visible:
		_build()

func _build() -> void:
	for child in container.get_children():
		child.queue_free()

	all_fish = _load_all_fish()
	var collection: Dictionary = Global.save_data.get("Collection", {})
	var caught_count = 0

	for fd in all_fish:
		var is_caught = collection.has(fd.fish_name) and collection[fd.fish_name] > 0
		if is_caught:
			caught_count += 1
		_add_card(fd, is_caught, collection.get(fd.fish_name, 0))

	if count_label:
		count_label.text = str(caught_count) + " / " + str(all_fish.size())

func _add_card(fd: FishData, is_caught: bool, count: int) -> void:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.15, 0.7)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", style)

	var rarity_col = RARITY_COLORS.get(fd.rarity, Color.WHITE)
	style.border_color = rarity_col
	style.border_width_left = 4
	style.border_width_bottom = 2

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	card.add_child(hbox)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(160, 120)
	icon.expand_mode = 1
	icon.stretch_mode = 5
	if is_caught and fd.texture:
		icon.texture = fd.texture
		if fd.tint != Color.WHITE:
			icon.modulate = fd.tint
	elif fd.texture:
		icon.texture = fd.texture
		icon.modulate = Color(0.1, 0.1, 0.1, 0.6)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 6)
	hbox.add_child(info)

	var font = load("res://Assets/Baloo2-ExtraBold.ttf") as Font

	var name_label = Label.new()
	name_label.text = fd.fish_name if is_caught else "???"
	name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 42)
	name_label.add_theme_color_override("font_color", Color.WHITE if is_caught else Color(0.4, 0.4, 0.4))
	name_label.add_theme_color_override("font_outline_color", rarity_col if is_caught else Color(0.2, 0.2, 0.2))
	name_label.add_theme_constant_override("outline_size", 10)
	info.add_child(name_label)

	var rarity_label = Label.new()
	rarity_label.text = RARITY_NAMES.get(fd.rarity, "")
	if is_caught:
		rarity_label.text += "  ×" + str(count)
	rarity_label.add_theme_font_override("font", font)
	rarity_label.add_theme_font_size_override("font_size", 28)
	rarity_label.add_theme_color_override("font_color", rarity_col)
	rarity_label.add_theme_constant_override("outline_size", 6)
	rarity_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	info.add_child(rarity_label)

	if is_caught and fd.description != "":
		var desc = Label.new()
		desc.text = fd.description
		desc.add_theme_font_override("font", font)
		desc.add_theme_font_size_override("font_size", 24)
		desc.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(desc)

	var price_label = Label.new()
	price_label.text = str(fd.price) + " coins" if is_caught else ""
	price_label.add_theme_font_override("font", font)
	price_label.add_theme_font_size_override("font_size", 26)
	price_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	price_label.add_theme_constant_override("outline_size", 6)
	price_label.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.0))
	info.add_child(price_label)

	container.add_child(card)

func _load_all_fish() -> Array[FishData]:
	var pool: Array[FishData] = []
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
		var res = load(path)
		if res is FishData:
			pool.append(res)
	pool.sort_custom(func(a, b): return a.rarity < b.rarity)
	return pool

func _on_back_pressed() -> void:
	SceneTransition._transition(hide)
