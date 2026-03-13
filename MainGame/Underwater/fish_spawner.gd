extends Node2D

signal fish_spawned(fish: Area2D)

@export var spawn_interval: float = 0.9
@export var max_fish: int = 18
@export var viewport_width: float = 1080.0

var fish_pool: Array[FishData] = []
var spawn_timer: float = 0.0
var active: bool = false
var current_depth_offset: float = 0.0
var hook_ref: Node2D = null
var luck: float = 0.0

const BASE_WEIGHTS := {
	FishData.Rarity.COMMON: 10.0,
	FishData.Rarity.UNCOMMON: 6.0,
	FishData.Rarity.RARE: 3.0,
	FishData.Rarity.EPIC: 1.5,
	FishData.Rarity.LEGENDARY: 0.5,
}
const LUCK_BOOST := {
	FishData.Rarity.COMMON: 0.0,
	FishData.Rarity.UNCOMMON: 0.5,
	FishData.Rarity.RARE: 1.5,
	FishData.Rarity.EPIC: 3.0,
	FishData.Rarity.LEGENDARY: 5.0,
}

const FISH_SCENE_PATH = "res://MainGame/Underwater/fish.tscn"
var fish_scene: PackedScene

func _ready() -> void:
	fish_scene = load(FISH_SCENE_PATH) if ResourceLoader.exists(FISH_SCENE_PATH) else null

func setup(pool: Array[FishData]) -> void:
	fish_pool = pool

func start() -> void:
	active = true
	spawn_timer = 0.0

func stop() -> void:
	active = false
	for child in get_children():
		child.queue_free()

func update_depth(camera_y: float) -> void:
	current_depth_offset = camera_y

func _process(delta: float) -> void:
	if not active or fish_pool.is_empty():
		return

	spawn_timer += delta
	if spawn_timer >= spawn_interval and get_child_count() < max_fish:
		spawn_timer = 0.0
		_spawn_fish()

func _spawn_fish() -> void:
	var visible_top = current_depth_offset - 300
	var visible_bottom = current_depth_offset + 1920 + 300

	var valid_fish: Array[FishData] = []
	for fd in fish_pool:
		if fd.depth_max >= visible_top and fd.depth_min <= visible_bottom:
			valid_fish.append(fd)

	if valid_fish.is_empty():
		return

	var data = _weighted_pick(valid_fish)
	var dir = 1.0 if randf() > 0.5 else -1.0
	var spawn_x = -150.0 if dir > 0 else viewport_width + 150.0
	var spawn_y = randf_range(
		maxf(data.depth_min, visible_top + 200),
		minf(data.depth_max, visible_bottom - 200)
	)

	var fish_node: Area2D
	if fish_scene:
		fish_node = fish_scene.instantiate()
	else:
		fish_node = _create_fish_node()

	add_child(fish_node)
	fish_node.setup(data, Vector2(spawn_x, spawn_y), dir)
	fish_node.viewport_width = viewport_width
	if hook_ref:
		fish_node.hook_ref = hook_ref
	fish_spawned.emit(fish_node)

func _create_fish_node() -> Area2D:
	var area = Area2D.new()
	area.set_script(load("res://MainGame/Underwater/fish_ai.gd"))
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitorable = true

	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	area.add_child(sprite)

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(140, 90)
	shape.shape = rect
	area.add_child(shape)

	return area

func _weighted_pick(pool: Array[FishData]) -> FishData:
	var weights: Array[float] = []
	var total := 0.0
	for fd in pool:
		var w = BASE_WEIGHTS.get(fd.rarity, 5.0) * (1.0 + luck * LUCK_BOOST.get(fd.rarity, 0.0))
		weights.append(w)
		total += w
	var roll = randf() * total
	for i in pool.size():
		roll -= weights[i]
		if roll <= 0.0:
			return pool[i]
	return pool[-1]
