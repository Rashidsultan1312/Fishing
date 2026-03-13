extends Node2D

signal cast_released(power: float, angle: float)

var active: bool = false

func start() -> void:
	active = true
	_auto_cast()

func stop() -> void:
	active = false

func _auto_cast() -> void:
	if not active:
		return
	var power = randf_range(0.4, 0.8)
	active = false
	cast_released.emit(power, -PI / 2.0)
