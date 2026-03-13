extends CanvasLayer

signal dismissed

var active: bool = false
var pulse_tween: Tween = null

@onready var bg: ColorRect = $BG
@onready var msg_label: Label = $Msg
@onready var tap_label: Label = $TapHint
@onready var arrow: Label = $Arrow
@onready var tap_area: Button = $TapArea

func _ready() -> void:
	hide()
	if tap_area:
		tap_area.pressed.connect(_dismiss)

func show_tip(msg: String, arrow_pos: Vector2 = Vector2.ZERO, arrow_rot: float = 0.0) -> void:
	msg_label.text = msg
	if arrow_pos != Vector2.ZERO:
		arrow.position = arrow_pos
		arrow.rotation = arrow_rot
		arrow.show()
	else:
		arrow.hide()

	tap_label.text = "Tap to continue"
	tap_label.modulate.a = 0.0

	show()
	active = true

	msg_label.modulate.a = 0.0
	msg_label.scale = Vector2(0.8, 0.8)
	msg_label.pivot_offset = msg_label.size * 0.5

	var tw = create_tween()
	tw.tween_property(msg_label, "modulate:a", 1.0, 0.4)
	tw.parallel().tween_property(msg_label, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	if pulse_tween and pulse_tween.is_running():
		pulse_tween.kill()
	pulse_tween = create_tween().set_loops().bind_node(tap_label)
	pulse_tween.tween_interval(1.0)
	pulse_tween.tween_property(tap_label, "modulate:a", 0.8, 0.6)
	pulse_tween.tween_property(tap_label, "modulate:a", 0.3, 0.6)

func _dismiss() -> void:
	if not active:
		return
	active = false
	if pulse_tween and pulse_tween.is_running():
		pulse_tween.kill()
	var tw = create_tween()
	tw.tween_property(msg_label, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		hide()
		dismissed.emit()
	)

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch and event.pressed:
		_dismiss()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		_dismiss()
		get_viewport().set_input_as_handled()
