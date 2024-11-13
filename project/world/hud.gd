extends CanvasLayer

signal new_round_started
signal new_game_started

@export var round_length := 30

var _scores := {}
var _score_labels := {}
var _wins := {}
var _player_count := 0
var _pending_new_round := false
var _pending_new_game := false
var _in_spawn_round := false :
	set(value):
		_in_spawn_round = value
		_spawn_round_label.visible = _in_spawn_round
var _pause_menu_open := false
var _total_rounds := -1
var _rounds_elapsed := 0
var _main_menu_open := false
var _final_round := false

@onready var _label_container : VBoxContainer = $Control/ScoreContainer
@onready var _game_timer : Timer = $Control/GameTimer
@onready var _game_time_label : Label = $Control/GameTimeLabel
@onready var _round_over_overlay : RoundOverMenu = $Control/RoundOver
@onready var _pause_menu : Control = $Control/PauseMenu
@onready var _main_menu : ColorRect = $Control/MainMenu
@onready var _spawn_round_label : Label = $Control/SpawnRoundLabel


func _ready()->void:
	_open_main_menu()


func _input(event:InputEvent)->void:
	if event is InputEventJoypadButton and event.pressed:
		if _pending_new_game:
			_open_main_menu()
		
		elif _pending_new_round:
			if _final_round:
				_end_game()
			else:
				_reset_round()
		
		elif event.button_index == JOY_BUTTON_BACK and not _pause_menu_open and not _main_menu_open:
			_show_pause_menu()
		
		elif _in_spawn_round and _player_count > 1:
			if event.button_index == JOY_BUTTON_START:
				_reset_round()


func _process(_delta:float)->void:
	_game_time_label.text = str(round(_game_timer.time_left))


func _open_main_menu()->void:
	get_tree().paused = true
	_clear_score_labels()
	_scores.clear()
	
	_round_over_overlay.hide()
	
	_main_menu_open = true
	_main_menu.show()
	
	_spawn_round_label.hide()


func _clear_score_labels()->void:
	_score_labels.clear()
	for label in _label_container.get_children():
		label.queue_free()


func _show_pause_menu()->void:
	_pause_menu.show()
	get_tree().paused = true
	_pause_menu_open = true
	
	if _in_spawn_round:
		_spawn_round_label.hide()


func _close_pause_menu()->void:
	_pause_menu.hide()
	get_tree().paused = false
	_pause_menu_open = false
	
	if _in_spawn_round:
		_spawn_round_label.show()


func _on_world_player_color_changed(index:int, color:Color, former_color:Color)->void:
	_update_label_color(index, color)
	_round_over_overlay.update_gem_colors(former_color, color)


func _on_world_player_died(index:int)->void:
	_scores[index] += 1
	_update_score(index)


func _on_world_player_joined(index:int, color:Color)->void:
	_scores[index] = 0
	_wins[index] = 0
	_player_count += 1
	_add_score_label(index, color)


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
			_final_round = true
	_end_round()


func _log_wins()->void:
	var winning_score := _get_winning_score()
	for player in _scores:
		if _scores[player] == winning_score:
			_wins[player] += 1


func _end_game()->void:
	get_tree().paused = true
	
	var most_wins := 0
	for winner in _wins:
		if _wins[winner] > most_wins:
			most_wins = _wins[winner]
	
	var winner_colors : Array[Color] = []
	for player in _wins:
		if _wins[player] == most_wins:
			winner_colors.append(_score_labels[player].modulate)
	
	_round_over_overlay.end_game(winner_colors)
	_final_round = false
	_reset_wins()
	
	await get_tree().create_timer(2.0).timeout
	
	_pending_new_game = true


func _reset_wins()->void:
	_wins.clear()


func _end_round()->void:
	get_tree().paused = true
	_round_over_overlay.end_round(_get_winner_colors(), _rounds_elapsed, _total_rounds)
	
	await get_tree().create_timer(1.0).timeout
	
	_pending_new_round = true


func _get_winner_colors()->Array[Color]:
	var winning_score := _get_winning_score()
	
	var winning_colors : Array[Color] = []
	for player in _scores.keys():
		if _scores[player] == winning_score:
			winning_colors.append(_score_labels[player].modulate)
	
	return winning_colors


func _get_winning_score()->int:
	var winning_score := INF
	for player in _scores.keys():
		if _scores[player] < winning_score:
			winning_score = _scores[player]
	@warning_ignore("narrowing_conversion")
	return winning_score


func _reset_round(spawn_round := false)->void:
	get_tree().paused = false
	
	_pending_new_round = false
	_pending_new_game = false
	_round_over_overlay.start_new_round()
	for i in _scores.keys():
		_scores[i] = 0
		_update_score(i)
	_in_spawn_round = spawn_round
	
	if not spawn_round:
		new_round_started.emit()
		_game_timer.start(round_length)


func _on_main_menu_game_started(round_count:int)->void:
	_main_menu_open = false
	_main_menu.hide()
	_rounds_elapsed = 0
	_player_count = 0
	new_game_started.emit()
	_reset_wins()
	_reset_round(true)
	_total_rounds = round_count


func _on_pause_menu_return_to_game()->void:
	_close_pause_menu()


func _on_pause_menu_return_to_menu()->void:
	_close_pause_menu()
	_open_main_menu()
