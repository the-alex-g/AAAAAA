extends CanvasLayer

signal game_over

@export var round_length := 30

var _scores := {}
var _score_labels := {}
var _pending_new_round := false

@onready var _label_container : VBoxContainer = $Control/ScoreContainer
@onready var _game_timer : Timer = $Control/GameTimer
@onready var _game_time_label : Label = $Control/GameTimeLabel
@onready var _game_over_overlay : Control = $Control/GameOver
@onready var _game_over_banner : TextureRect = $Control/GameOver/TextureRect


func _ready()->void:
	_game_over_overlay.hide()
	_game_timer.start(round_length)


func _input(event:InputEvent)->void:
	if not _pending_new_round:
		return
	
	if event is InputEventJoypadButton:
		if event.pressed:
			game_over.emit()
			_reset()


func _process(_delta:float)->void:
	_game_time_label.text = str(round(_game_timer.time_left))


func _on_world_player_color_changed(index:int, color:Color)->void:
	_update_label_color(index, color)


func _on_world_player_died(index:int)->void:
	_scores[index] += 1
	_update_score(index)


func _on_world_player_joined(index:int, color:Color)->void:
	_scores[index] = 0
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
	get_tree().paused = true
	_game_over_overlay.show()
	
	_load_banner_shader()
	
	await get_tree().create_timer(1.0).timeout
	_pending_new_round = true


func _load_banner_shader()->void:
	var material := ShaderMaterial.new()
	material.shader = load("res://world/win_banner.gdshader")
	
	var winner_colors := _get_winner_colors()
	material.set_shader_parameter("segments", winner_colors.size())
	for color in winner_colors:
		material.set_shader_parameter("color" + str(winner_colors.find(color) + 1), color)
	
	_game_over_banner.material = material


func _get_winner_colors()->Array[Color]:
	var winning_score := INF
	for player in _scores.keys():
		if _scores[player] < winning_score:
			winning_score = _scores[player]
	
	var winning_colors : Array[Color] = []
	for player in _scores.keys():
		if _scores[player] == winning_score:
			winning_colors.append(_score_labels[player].modulate)
	
	return winning_colors


func _reset()->void:
	get_tree().paused = false
	_pending_new_round = false
	_game_over_overlay.hide()
	for i in _scores.keys():
		_scores[i] = 0
		_update_score(i)
	_game_timer.start(round_length)
