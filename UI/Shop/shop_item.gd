extends MarginContainer

var rod_data : Rod
@onready var button: Button = %Buy
@onready var item_name: Label = %Name
@onready var texture: TextureRect = %Texture
@onready var cost: Label = %Cost
@onready var info: RichTextLabel = %Info
var index : int = 0
var bought : bool = false
signal equip
signal money_spent

func _ready() -> void:
	texture.resized.connect(_update_pivot)

func _update_pivot() -> void:
	texture.pivot_offset = texture.size * 0.5

func _update_data() -> void:
	item_name.text = rod_data.item_name
	texture.texture = rod_data.texture
	cost.text = str(rod_data.cost)
	info.text = rod_data.info + "\n\n" \
		+ "Luck: +" + str(int(rod_data.luck * 100)) + "%\n" \
		+ "Depth: " + str(int(rod_data.line_length)) + "m\n" \
		+ "Speed: " + str(int(rod_data.sink_speed)) + "\n" \
		+ "Reel Bonus: +" + str(int(rod_data.tension_bonus * 100)) + "%"

func _set_margins(left : int = 90, right : int = 90) -> void:
	add_theme_constant_override("margin_left", left)
	add_theme_constant_override("margin_right", right)

func _on_buy_pressed() -> void:
	if bought:
		if Global.save_data.get("Rod") == index:
			return
		Global.save_data["Luck"] = rod_data.luck
		Global.save_data.set("Rod", index)
		equip.emit(self)
		_update()
		Global._save()
		return
	var current_money = Global.save_data.get("Money")
	if current_money >= rod_data.cost:
		var bought_items = Global.save_data.get("Shop")
		bought_items[index] = true
		Global.save_data.set("Money", current_money - rod_data.cost)
		money_spent.emit()
		Global.save_data["Luck"] = rod_data.luck
		Global.save_data.set("Rod", index)
		equip.emit(self)
		bought = true
		_update()
		Global._save()

func _update() -> void:
	var normal := StyleBoxTexture.new()
	var pressed := StyleBoxTexture.new()
	var hover := StyleBoxTexture.new()
	normal.texture = load("res://UI/Sprites/Equip.png")
	pressed.texture = load("res://UI/Sprites/Equipped.png")
	hover.texture = load("res://Assets/EquipHover.png")
	cost.text = "Equip"
	if Global.save_data.get("Rod") == index:
		cost.text = "Equipped"
		normal = pressed
		hover = pressed
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("pressed", pressed)

func unequip() -> void:
	_update()
