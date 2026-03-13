extends Resource
class_name LocationData

@export var location_id: String = ""
@export var location_name: String = ""
@export_multiline var description: String = ""
@export var difficulty_label: String = "Easy"
@export var order: int = 0

@export_group("Background")
@export var bg_texture: Texture2D
@export var game_bg_texture: Texture2D
@export var use_shader_bg: bool = false
@export var sky_top: Color = Color(0.4, 0.7, 1.0)
@export var sky_bottom: Color = Color(0.2, 0.4, 0.8)
@export var water_color: Color = Color(0.1, 0.3, 0.6)
@export var terrain_color: Color = Color(0.2, 0.5, 0.2)

@export_group("Underwater")
@export var color_surface: Color = Color(0.2, 0.6, 0.9, 1.0)
@export var color_deep: Color = Color(0.02, 0.05, 0.15, 1.0)
@export var ray_intensity: float = 0.15
@export var max_depth: float = 2000.0
@export var bubble_color: Color = Color(0.8, 0.9, 1.0, 0.35)

@export_group("Reel")
@export var reel_bg_top: Color = Color(0.05, 0.2, 0.4, 0.92)
@export var reel_bg_bottom: Color = Color(0.01, 0.04, 0.12, 0.96)

@export_group("Gameplay")
@export var reward_multiplier: float = 1.0
@export var fish_speed_mult: float = 1.0
@export var spawn_interval: float = 0.9
@export var fish_ids: Array[String] = []

@export_group("Unlock")
@export var unlock_type: String = "free"
@export var unlock_value: int = 0
