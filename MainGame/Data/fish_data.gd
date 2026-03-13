extends Resource
class_name FishData

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum SwimPattern { LINEAR, SINE, ZIGZAG, CIRCLE, IDLE }

@export var fish_name: String = ""
@export var texture: Texture2D
@export var price: int = 10
@export var rarity: Rarity = Rarity.COMMON
@export var depth_min: float = 200.0
@export var depth_max: float = 800.0
@export var speed: float = 100.0
@export var swim_pattern: SwimPattern = SwimPattern.SINE
@export var reel_difficulty: float = 1.0
@export var flee_on_hook: bool = false
@export var tint: Color = Color.WHITE
@export_multiline var description: String = ""
