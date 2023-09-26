extends Node2D

signal player_joined(index, color)
signal player_color_changed(index, color)
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
const CONFIG_PATH := "res://config.cfg"

@export_enum("load", "save", "run", "load_specific") var map_status := "load"
@export var map_to_load := -1

var player_count := 0
var _players_added := []
var _game_on := false
var _used_colors := []
var _spawn_points : Array[Vector2i] = []
var _totem : Totem

@onready var _player_container : Node2D = $Players
@onready var _tile_map : TileMap = $TileMap


func _ready()->void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	if map_status == "save":
		_save_map()
	elif map_status == "load" or map_status == "load_specific":
		_load_map()
	
	_find_spawn_points()
	_spawn_totem()


func _input(event:InputEvent)->void:
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
	
	for tile_position in _tile_map.get_used_cells(0):
		if tile_position.y < 10 and tile_position.x >= 0 and tile_position.x < 20:
			if _tile_map.get_cell_tile_data(0, tile_position + Vector2i.UP) == null:
				_spawn_points.append(Vector2i(tile_position.x * 8 + 4, tile_position.y * 8))


func _instance_player(index:int)->void:
	var player : Goblin = load("res://goblin/goblin.tscn").instantiate()
	player.position = _spawn_points.pick_random()
	player.index = index
	# don't get this next one...
	player.jump_strength = 150
	
	player.color1 = COLORS.keys()[0]
	while _used_colors.has(player.color1):
		player.color1 = COLORS.keys()[COLORS.keys().find(player.color1) + 1]
	_used_colors.append(player.color1)
	
	player.color2 = COLORS[player.color1]
	
	_player_container.add_child(player)
	
	player_joined.emit(index, player.color1)


func _change_player_color(index:int, direction:int)->void:
	var player : Goblin
	for goblin in _player_container.get_children():
		if goblin.index == index:
			player = goblin
			break
	
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
	
	player_color_changed.emit(index, new_color)


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


func _on_death_zone_body_entered(body:Goblin)->void:
	if _game_on:
		body.disabled = true
		player_count -= 1
		if player_count <= 1:
			_end_game()
	else:
		_respawn(body)
	player_died.emit(body.index)


func _end_game()->void:
	_reset()


func _reset()->void:
	for player in _player_container.get_children():
		_respawn(player)


func _respawn(player:Goblin)->void:
	player.reset()
	player.position = _spawn_points.pick_random()


func _on_totem_used()->void:
	await get_tree().create_timer(5.0 + randf() * 3.0).timeout
	_spawn_totem()


func _spawn_totem()->void:
	if is_instance_valid(_totem):
		return
	
	_totem = load("res://totem/totem.tscn").instantiate()
	_totem.position = _spawn_points.pick_random()
	call_deferred("add_child", _totem)
	_totem.used.connect(Callable(self, "_on_totem_used"))


func _save_map()->void:
	var file := ConfigFile.new()
	file.load(CONFIG_PATH)
	
	var map_index := 0
	var map := _tile_map.get_used_cells(0)
	while file.has_section_key("maps", str(map_index)):
		if file.get_value("maps", str(map_index)) == map:
			return
		map_index += 1

	file.set_value("maps", str(map_index), map)
	
	file.save(CONFIG_PATH)
	
	print("map saved")


func _load_map()->void:
	_tile_map.clear()
	
	var file := ConfigFile.new()
	file.load(CONFIG_PATH)
	
	var map : Array[Vector2i] = []
	
	if map_status == "load":
		var number_of_maps := 0
		while file.has_section_key("maps", str(number_of_maps)):
			number_of_maps += 1
		map = file.get_value("maps", str(randi() % number_of_maps))
	
	elif map_status == "load_specific":
		map = file.get_value("maps", str(map_to_load))
	
	for cell in map:
		_tile_map.set_cell(0, cell, 0, Vector2i.ZERO, 0)
	
	_tile_map.set_cells_terrain_connect(0, map, 0, 0)


func _on_hud_game_over()->void:
	if map_status == "load":
		_load_map()
		_find_spawn_points()
	
	for player in _player_container.get_children():
		if player is Goblin: # there's a chance that bombs could be in there.
			_respawn(player)
	
	if is_instance_valid(_totem):
		_totem.position = _spawn_points.pick_random()
