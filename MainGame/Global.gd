extends Node

const FILE_PATH: String = "user://Data.json"
var bought_fishing_rods : Array[bool] = [false,false,false,false,false,false,false,false,false]
var current_equipped_rod : int = 0
var save_data: Dictionary = {
	"Money" : 0,
	"Luck" : 0.0,
	"CAN_VIBRATE" : true,
	"SFX" : 50.0,
	"Music" : 50.0,
	"Shop" : bought_fishing_rods,
	"Rod" : current_equipped_rod,
	"Collection" : {},
	"MaxDepth" : 0.0,
	"TotalCaught" : 0,
	"TutorialDone" : {},
	"CurrentLocation" : "sakura",
	"UnlockedLocations" : ["sakura"],
}
var scene_cache: Dictionary = {}
var current_location: LocationData = null

func _ready() -> void:
	_load()
	_load_current_location()

const LOCATION_FILES: Array[String] = [
	"res://MainGame/Data/Locations/sakura_pond.tres",
	"res://MainGame/Data/Locations/tropical_reef.tres",
	"res://MainGame/Data/Locations/arctic_ice.tres",
	"res://MainGame/Data/Locations/deep_abyss.tres",
]

func _load_current_location() -> void:
	var loc_id = save_data.get("CurrentLocation", "sakura")
	for path in LOCATION_FILES:
		var res = load(path)
		if res is LocationData and res.location_id == loc_id:
			current_location = res
			return
	var fallback = load(LOCATION_FILES[0])
	if fallback is LocationData:
		current_location = fallback

func cache_scene(path: String, scene: PackedScene) -> void:
	scene_cache[path] = scene

func get_cached_scene(path: String) -> PackedScene:
	return scene_cache.get(path, null) as PackedScene

func is_location_unlocked(loc: LocationData) -> bool:
	var unlocked: Array = save_data.get("UnlockedLocations", ["sakura"])
	if loc.location_id in unlocked:
		return true
	match loc.unlock_type:
		"free":
			return true
		"money":
			return save_data.get("Money", 0) >= loc.unlock_value
		"fish_caught":
			return save_data.get("TotalCaught", 0) >= loc.unlock_value
	return false

func can_afford_location(loc: LocationData) -> bool:
	if loc.unlock_type == "money":
		return save_data.get("Money", 0) >= loc.unlock_value
	return true

func unlock_location(loc: LocationData) -> bool:
	var unlocked: Array = save_data.get("UnlockedLocations", ["sakura"])
	if loc.location_id in unlocked:
		return true
	if not is_location_unlocked(loc):
		return false
	if loc.unlock_type == "money":
		save_data["Money"] -= loc.unlock_value
	unlocked.append(loc.location_id)
	save_data["UnlockedLocations"] = unlocked
	_save()
	return true

func is_location_purchased(loc: LocationData) -> bool:
	var unlocked: Array = save_data.get("UnlockedLocations", ["sakura"])
	return loc.location_id in unlocked

#region Save-Load
func _save() -> void:
	var file : FileAccess = FileAccess.open_encrypted_with_pass(FILE_PATH, FileAccess.WRITE,"9f3c2a1d8e4b7f6a5d0e91c8b2a3476c5e8d0f1a9b4c7e2d6a3f8b1c0e4")
	file.store_var(save_data)
	file.close()
func _load() -> void:
	if FileAccess.file_exists(FILE_PATH):
		var file : FileAccess = FileAccess.open_encrypted_with_pass(FILE_PATH, FileAccess.READ,"9f3c2a1d8e4b7f6a5d0e91c8b2a3476c5e8d0f1a9b4c7e2d6a3f8b1c0e4")
		var data : Dictionary = file.get_var()
		for i in data:
			if save_data.has(i):
				save_data[i] = data[i]
		file.close()
#endregion
