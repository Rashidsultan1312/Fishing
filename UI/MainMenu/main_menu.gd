extends Control

func _on_play_pressed() -> void:
	SceneTransition._change_scene("res://UI/Location/locations.tscn")

func _on_setting_pressed() -> void:
	SceneTransition._transition(%Settings.show)

func _on_shop_pressed() -> void:
	SceneTransition._transition(%Shop.show)

func _on_fishbook_pressed() -> void:
	SceneTransition._transition(%Fishbook.show)
