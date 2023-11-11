extends CanvasLayer

signal round_over
signal reset_board

@export var round_length := 30

var _scores := {}
var _score_labels := {}
var _wins := {}
var _pending_new_round := false
var _pending_new_game := false
var _pause_menu_open := false
var _total_rounds := -1
var _rounds_elapsed := 0
var _main_menu_open := false
var _control_menu_open := false

@onready var _label_container : VBoxContainer = $Control/ScoreContainer
@onready var _game_timer : Timer = $Control/GameTimer
@onready var _game_time_label : Label = $Control/GameTimeLabel
@onready var _game_over_overlay : Control = $Control/GameOver
@onready var _game_over_banner : TextureRect = $Control/GameOver/TextureRect
@onready var _game_over_label : Label = $Control/GameOver/Label
@onready var _pause_menu : Control = $Control/PauseMenu
@onready var _game_length_label : Label = $Control/MainMenu/GridContainer/GameLengthLabel
@onready var _main_menu : ColorRect = $Control/MainMenu
@onready var _main_menu_options : GridContainer = $Control/MainMenu/GridContainer
@onready var _pause_menu_options : PanelContainer = $Control/PauseMenu/PanelContainer
@onready var _controls : PanelContainer = $Control/ControlInfo
@onready var _win_gem_container : GridContainer = $Control/GameOver/GridContainer


func _ready()->void:
	_open_main_menu()


func _input(event:InputEvent)->void:
	if event is InputEventJoypadButton:
		if _main_menu_open:
			_resolve_main_menu_event(event)
		
		elif _pending_new_game:
			if event.pressed:
				_open_main_menu()
		
		elif _pending_new_round:
			if event.pressed:
				round_over.emit()
				_reset_round()
		
		elif _pause_menu_open and event.pressed:
			match event.button_index:
				JOY_BUTTON_B:
					if not _control_menu_open:
						_close_pause_menu()
					
				JOY_BUTTON_BACK:
					if not _control_menu_open:
						_close_pause_menu()
						_open_main_menu()
				JOY_BUTTON_Y:
					_toggle_controls()
		
		elif event.button_index == JOY_BUTTON_BACK and event.pressed:
			_show_pause_menu()
		
		if _control_menu_open and event.pressed and event.button_index != JOY_BUTTON_Y:
			_toggle_controls()


func _toggle_controls()->void:
	_control_menu_open = not _control_menu_open
	if _control_menu_open:
		_controls.show()
		if _main_menu_open:
			_main_menu_options.hide()
		elif _pause_menu_open:
			_pause_menu_options.hide()
	else:
		_controls.hide()
		_main_menu_options.show()
		_pause_menu_options.show()


func _process(_delta:float)->void:
	_game_time_label.text = str(round(_game_timer.time_left))


func _resolve_main_menu_event(event:InputEventJoypadButton)->void:
	if event.pressed:
		if not _control_menu_open:
			match event.button_index:
				JOY_BUTTON_DPAD_UP:
					_increase_game_length()
				JOY_BUTTON_DPAD_DOWN:
					_decrease_game_length()
				JOY_BUTTON_START:
					_start_game()
				JOY_BUTTON_BACK:
					get_tree().quit()
				JOY_BUTTON_X:
					if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
						DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
					else:
						DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if event.button_index == JOY_BUTTON_Y:
			_toggle_controls()


func _open_main_menu()->void:
	get_tree().paused = true
	_clear_win_gems()
	_clear_score_labels()
	_scores.clear()
	
	_game_over_overlay.hide()
	_pause_menu.hide()
	_game_over_label.hide()
	
	_main_menu_open = true
	_main_menu.show()
	
	_update_game_length_label()


func _clear_win_gems()->void:
	for gem in _win_gem_container.get_children():
		gem.queue_free()


func _clear_score_labels()->void:
	_score_labels.clear()
	for label in _label_container.get_children():
		label.queue_free()


func _increase_game_length()->void:
	_total_rounds += 2
	_update_game_length_label()


func _decrease_game_length()->void:
	if _total_rounds != -1:
		_total_rounds -= 2
		_update_game_length_label()


func _update_game_length_label()->void:
	if _total_rounds == -1:
		_game_length_label.text = "indefinite"
	elif _total_rounds == 1:
		_game_length_label.text = "1 round"
	else:
		_game_length_label.text = str(_total_rounds) + " rounds"


func _start_game()->void:
	_main_menu_open = false
	_main_menu.hide()
	_rounds_elapsed = 0
	reset_board.emit()
	_reset_wins()
	_reset_round()


func _show_pause_menu()->void:
	_game_timer.paused = true
	_pause_menu.show()
	get_tree().paused = true
	_pause_menu_open = true


func _close_pause_menu()->void:
	_game_timer.paused = false
	_pause_menu.hide()
	get_tree().paused = false
	_pause_menu_open = false


func _on_world_player_color_changed(index:int, color:Color, former_color:Color)->void:
	_update_label_color(index, color)
	_update_gem_colors(former_color, color)


func _on_world_player_died(index:int)->void:
	_scores[index] += 1
	_update_score(index)


func _on_world_player_joined(index:int, color:Color)->void:
	_scores[index] = 0
	_wins[index] = 0
	_add_score_label(index, color)


func _update_gem_colors(from:Color, to:Color)->void:
	if from == Color(0.0, 0.0, 0.0, 0.0):
		return
	
	for child in $Control/GameOver/GridContainer.get_children():
		for i in 4:
			if child.material.get_shader_parameter("color" + str(i + 1)) != null:
				var color:Color = child.material.get_shader_parameter("color" + str(i + 1))
				if color == from:
					child.material.set_shader_parameter("color" + str(i + 1), to)


func _add_score_label(index:int, color:Color)->void:
	var label := Label.new()
	_label_container.add_child(label)
	_score_labels[index] = label
	_update_label_color(index, color)
	_update_score(index)


func _update_label_color(index:int, color:Color)->void:
	_score_labels[index].set_deferred("modulate", color)


func _update_score(index:int)->void:
	_score_labels[index].text = str(_scores[index])


func _on_game_timer_timeout()->void:
	_log_wins()
	if _total_rounds > _rounds_elapsed:
		_rounds_elapsed += 1
		if _rounds_elapsed == _total_rounds:
			_end_game()
		else:
			_end_round()
	else:
		_end_round()


func _log_wins()->void:
	var winning_score := _get_winning_score()
	for player in _scores:
		if _scores[player] == winning_score:
			_wins[player] += 1


func _end_game()->void:
	get_tree().paused = true
	_add_win_gem()
	
	_game_over_overlay.show()
	_game_over_label.show()
	
	var most_wins := 0
	for winner in _wins:
		if _wins[winner] > most_wins:
			most_wins = _wins[winner]
	
	var winner_colors : Array[Color] = []
	for player in _wins:
		if _wins[player] == most_wins:
			winner_colors.append(_score_labels[player].modulate)
	
	_load_banner_shader(winner_colors)
	
	_reset_wins()
	
	await get_tree().create_timer(2.0).timeout
	
	_pending_new_game = true


func _reset_wins()->void:
	_wins.clear()


func _end_round()->void:
	get_tree().paused = true
	_game_over_overlay.show()
	
	_add_win_gem()
	_load_banner_shader(_get_winner_colors())
	
	await get_tree().create_timer(1.0).timeout
	
	_pending_new_round = true


func _add_win_gem() -> void:
	var material := ShaderMaterial.new()
	material.shader = load("res://world/win_gem.gdshader")
	
	var winner_colors := _get_winner_colors()
	material.set_shader_parameter("segments", winner_colors.size())
	for color in winner_colors:
		material.set_shader_parameter("color" + str(winner_colors.find(color) + 1), color)
	
	var win_gem := TextureRect.new()
	win_gem.texture = load("res://world/win_gem.png")
	win_gem.material = material
	
	_win_gem_container.add_child(win_gem)


func _load_banner_shader(winner_colors:Array[Color])->void:
	var material := ShaderMaterial.new()
	material.shader = load("res://world/win_banner.gdshader")
	
	material.set_shader_parameter("segments", winner_colors.size())
	for color in winner_colors:
		material.set_shader_parameter("color" + str(winner_colors.find(color) + 1), color)
	
	_game_over_banner.material = material


func _get_winner_colors()->Array[Color]:
	var winning_score := _get_winning_score()
	
	var winning_colors : Array[Color] = []
	for player in _scores.keys():
		if _scores[player] == winning_score:
			winning_colors.append(_score_labels[player].modulate)
	
	return winning_colors


func _get_winning_score()->int:
	var winning_score := 100000 # if you die that many times, you'ma got probbles.
	for player in _scores.keys():
		if _scores[player] < winning_score:
			winning_score = _scores[player]
	return winning_score


func _reset_round()->void:
	get_tree().paused = false
	_pending_new_round = false
	_pending_new_game = false
	_game_over_overlay.hide()
	for i in _scores.keys():
		_scores[i] = 0
		_update_score(i)
	_game_timer.start(round_length)
