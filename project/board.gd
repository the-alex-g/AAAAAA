extends TileMapLayer

const MAP_FILE_PATH := "res://maps.cfg"

@export var map_to_load := -1
@export_enum("load", "save", "run", "save as spawn") var map_status := "load"

var _last_map_loaded := -1
var number_of_maps := _get_number_of_maps()
var editor_open := false
var _current_map := 0 :
	set(value):
		if value < 0:
			value = number_of_maps - 1
		_current_map = value % number_of_maps
		map_to_load = _current_map
		load_map()


func _ready()->void:
	if map_status == "save":
		save_map()
	elif map_status == "save as spawn":
		_save_map_as_spawn()
	elif map_status == "run":
		_save_map_as_current()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.is_pressed() and editor_open:
		match event.button_index:
			JOY_BUTTON_LEFT_SHOULDER:
				_current_map -= 1
			JOY_BUTTON_RIGHT_SHOULDER:
				_current_map += 1



func _get_number_of_maps() -> int:
	var i := 0
	var file := ConfigFile.new()
	file.load(MAP_FILE_PATH)
	while file.has_section_key("maps", str(i)):
		i += 1
	return i


func save_map()->void:
	var file := ConfigFile.new()
	file.load(MAP_FILE_PATH)
	
	var map_index := 0
	var map := _compress_map()
	if map_to_load == -1:
		while file.has_section_key("maps", str(map_index)):
			if file.get_value("maps", str(map_index)) == map:
				print("map already exists")
				return
			map_index += 1
	else:
		map_index = map_to_load

	file.set_value("maps", str(map_index), map)
	
	file.save(MAP_FILE_PATH)
	
	print("map saved")


func _save_map_as_spawn()->void:
	var file := ConfigFile.new()
	file.load(MAP_FILE_PATH)
	file.set_value("spawn map", "spawn map", _compress_map())
	file.save(MAP_FILE_PATH)
	
	print("map saved as spawn map")


func _save_map_as_current()->void:
	var file := ConfigFile.new()
	file.load(MAP_FILE_PATH)
	file.set_value("current map", "current map", _compress_map())
	file.save(MAP_FILE_PATH)


# Use run length compression to get map data
func _compress_map() -> Array[int]:
	var data : Array[int] = []
	var counting := "none"
	var count := 0
	for y in 24:
		for x in range(-1, 25):
			if get_cell_source_id(Vector2i(x, y)) == -1:
				if counting == "tiles":
					counting = "none"
					data.append(count)
					count = 0
				count += 1
			else:
				if counting == "none":
					counting = "tiles"
					data.append(count)
					count = 0
				count += 1
	data.append(count)
	return data


func load_spawn_map() -> void:
	load_map(true)


func load_map(spawn_map := false)->void:
	clear()
	
	var file := ConfigFile.new()
	file.load(MAP_FILE_PATH)
	
	var map : Array = []
	
	if spawn_map:
		map = file.get_value("spawn map", "spawn map")
	elif map_status == "run":
		map = file.get_value("current map", "current map")
	elif map_to_load == -1:
		var map_index := randi() % number_of_maps
		while number_of_maps > 1 and _last_map_loaded == map_index:
			map_index = randi() % number_of_maps
		
		map = file.get_value("maps", str(map_index))
		_last_map_loaded = map_index
	else:
		map = file.get_value("maps", str(map_to_load))
	
	set_cells_terrain_connect(_decompress_map(map), 0, 0)
	
	update_internals()


func _decompress_map(map: Array[int]) -> Array[Vector2i]:
	var cell_map : Array[Vector2i] = []
	var placing := false
	var run_length := 0
	for run in map:
		for x in run:
			if placing:
				cell_map.append(Vector2i(run_length % 26 - 1, floori(run_length / 26.0)))
			run_length += 1
		placing = not placing
	return cell_map
