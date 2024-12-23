extends Node2D

signal player_joined(index, color)
signal player_color_changed(index, color, original_color)
signal player_died(index)


const ACTIONS := {
	"jump":JOY_BUTTON_A,
	"punch":JOY_BUTTON_X,
	"kick":JOY_BUTTON_B,
	"super":JOY_BUTTON_Y,
}
const COLORS := {
	Color.RED:Color.SALMON,
	Color.AQUA:Color.PALE_TURQUOISE,
	Color.YELLOW:Color.KHAKI,
	Color.GREEN:Color.AQUAMARINE,
	Color.MAGENTA:Color.MEDIUM_ORCHID,
}
const MAP_FILE_PATH := "res://maps.cfg"

@export_enum("load", "save", "run", "save as spawn") var map_status := "load"
@export var map_to_load := -1

var player_count := 0
var _players_added := []
var _used_colors := []
var _spawn_points : Array[Vector2i] = []
var _totem : Totem
var _last_map_loaded := -1
var _in_spawn_map := true

@onready var _player_container : Node2D = $Players
@onready var _tile_layer : TileMapLayer = $TileLayer
@onready var _totem_spawn_timer : Timer = $TotemSpawnTimer


func _ready()->void:
	if map_status == "save":
		_save_map()
	elif map_status == "save as spawn":
		_save_map_as_spawn()
	elif map_status == "run":
		_save_map_as_current()


func _input(event:InputEvent)->void:
	if not _in_spawn_map:
		return
	
	if event is InputEventJoypadButton:
		if event.pressed:
			if event.button_index == JOY_BUTTON_A and not _players_added.has(event.device):
				_add_player(event.device)
			else:
				match event.button_index:
					JOY_BUTTON_LEFT_SHOULDER:
						_change_player_color(event.device, -1)
					JOY_BUTTON_RIGHT_SHOULDER:
						_change_player_color(event.device, 1)


func _find_spawn_points()->void:
	_spawn_points.clear()
	
	for tile_position in _tile_layer.get_used_cells():
		if tile_position.y < 10 and tile_position.x >= 0 and tile_position.x < 20:
			if _tile_layer.get_cell_tile_data(tile_position + Vector2i.UP) == null:
				_spawn_points.append(Vector2i(tile_position.x * 8 + 4, tile_position.y * 8))


func _get_spawn_point()->Vector2:
	var occupied_points : Array[Vector2] = []
	
	for object in _player_container.get_children():
		if object is Goblin:
			var map_coords := _tile_layer.local_to_map(object.position)
			occupied_points.append(Vector2(map_coords.x * 8 + 4, map_coords.y * 8))
	
	if is_instance_valid(_totem):
		occupied_points.append(_totem.position)
	
	var spawn_point : Vector2 = _spawn_points.pick_random()
	while occupied_points.has(spawn_point):
		spawn_point = _spawn_points.pick_random()
	
	return spawn_point


func _instance_player(index:int)->void:
	var player : Goblin = load("res://goblin/goblin.tscn").instantiate()
	player.position = _get_spawn_point()
	player.index = index
	# don't get this next one...
	player.jump_strength = 150
	
	player.color1 = COLORS.keys()[0]
	while _used_colors.has(player.color1):
		player.color1 = COLORS.keys()[COLORS.keys().find(player.color1) + 1]
	_used_colors.append(player.color1)
	
	player.color2 = COLORS[player.color1]
	player.died.connect(_on_goblin_died.bind(player))
	
	_player_container.add_child(player)
	
	player_joined.emit(index, player.color1)


func _change_player_color(index:int, direction:int)->void:
	var player : Goblin = null
	for goblin in _player_container.get_children():
		if goblin.index == index:
			player = goblin
			break
	
	if player == null:
		return
	
	var original_color = player.color1
	var color_index := COLORS.keys().find(player.color1)
	var new_color := Color(0, 0, 0, 0)
	while new_color == Color(0, 0, 0, 0) or _used_colors.has(new_color):
		color_index += direction
		color_index %= COLORS.size()
		new_color = COLORS.keys()[color_index]
	
	_used_colors.erase(player.color1)
	_used_colors.append(new_color)
	player.color1 = new_color
	player.color2 = COLORS[new_color]
	
	player_color_changed.emit(index, new_color, original_color)


func _add_player(index:int)->void:
	player_count += 1
	_players_added.append(index)
	if not InputMap.has_action(ACTIONS.keys()[0] + "_" + str(index)):
		_create_inputs(index)
	_instance_player(index)


func _create_inputs(player_index:int)->void:
	for action_name in ACTIONS.keys():
		InputMap.add_action(action_name + "_" + str(player_index))
		
		var input : int = ACTIONS[action_name]
		var event := InputEventJoypadButton.new()
		@warning_ignore("int_as_enum_without_cast")
		event.button_index = input
		
		event.device = player_index
		
		InputMap.action_add_event(action_name + "_" + str(player_index), event)


func _on_goblin_died(body:Goblin)->void:
	_respawn(body)
	player_died.emit(body.index)


func _respawn(player:Goblin)->void:
	player.reset()
	player.position = _get_spawn_point()


func _on_totem_used()->void:
	_totem_spawn_timer.start(5.0 + randf() * 3.0)
	await _totem_spawn_timer.timeout
	_spawn_totem()


func _spawn_totem()->void:
	if is_instance_valid(_totem):
		_totem.position = _get_spawn_point()
		return
	
	_totem_spawn_timer.stop()
	_totem = load("res://totem/totem.tscn").instantiate()
	_totem.position = _get_spawn_point()
	call_deferred("add_child", _totem)
	_totem.used.connect(_on_totem_used)


func _save_map()->void:
	var file := ConfigFile.new()
	file.load(MAP_FILE_PATH)
	
	var map_index := 0
	var map := _get_map_save_data()
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
	file.set_value("spawn map", "spawn map", _get_map_save_data())
	file.save(MAP_FILE_PATH)
	
	print("map saved as spawn map")


func _save_map_as_current()->void:
	var file := ConfigFile.new()
	file.load(MAP_FILE_PATH)
	file.set_value("current map", "current map", _get_map_save_data())
	file.save(MAP_FILE_PATH)


# Use run length compression to get map data
func _get_map_save_data() -> Array[int]:
	var data : Array[int] = []
	var counting := "none"
	var count := 0
	for y in 24:
		for x in range(-1, 25):
			if _tile_layer.get_cell_source_id(Vector2i(x, y)) == -1:
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


func _load_map(spawn_map := false)->void:
	_tile_layer.clear()
	_in_spawn_map = spawn_map
	
	var file := ConfigFile.new()
	file.load(MAP_FILE_PATH)
	
	var map : Array = []
	
	if spawn_map:
		map = file.get_value("spawn map", "spawn map")
	elif map_status == "run":
		map = file.get_value("current map", "current map")
	elif map_to_load == -1:
		var number_of_maps := 0
		while file.has_section_key("maps", str(number_of_maps)):
			number_of_maps += 1
		
		var map_index := randi() % number_of_maps
		while number_of_maps > 1 and _last_map_loaded == map_index:
			map_index = randi() % number_of_maps
		
		map = file.get_value("maps", str(map_index))
		_last_map_loaded = map_index
	else:
		map = file.get_value("maps", str(map_to_load))
	
	_tile_layer.set_cells_terrain_connect(_decompress_map(map), 0, 0)
	
	_tile_layer.update_internals()
	
	_find_spawn_points()
	_spawn_totem()


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


func _on_hud_new_round_started()->void:
	_load_map()
	
	for object in _player_container.get_children():
		if object is Goblin: # there's a chance that bombs could be in there.
			_respawn(object)
		if object is Bomb:
			object.queue_free()


func _on_hud_new_game_started()->void:
	_players_added.clear()
	player_count = 0
	_used_colors.clear()
	for player in _player_container.get_children():
		player.queue_free()
	
	_load_map(true)
