extends VBoxContainer

func _ready() -> void:
	$SFX.value = Global.save_data["SFX"]
	$Music.value = Global.save_data["Music"]

func _on_back_pressed() -> void:
	Global.save_data["Music"] = $Music.value
	Global.save_data["SFX"] = $SFX.value
	Global._save()
	SceneTransition._transition(owner.hide)

func _on_music_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, value / 5)

func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, value / 5)
