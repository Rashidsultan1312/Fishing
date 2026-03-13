extends TextureRect

@onready var fish: TextureRect = %Fish
signal money_changed
signal fish_caught

func _ready() -> void:
	fish.texture = null
