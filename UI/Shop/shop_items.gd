extends HBoxContainer

signal _update_money
signal _update_rarities

func _equip(item) -> void:
	for shop_item in get_children():
		if shop_item != item and shop_item.bought:
			shop_item.unequip()
	_update_rarities.emit()
