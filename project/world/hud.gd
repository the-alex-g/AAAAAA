extends CanvasLayer

signal game_over

@export var round_length := 60

var _scores := {}
var _score_labels := {}

@onready var _label_container : VBoxContainer = $Control/ScoreContainer
@onready var _game_timer : Timer = $Control/GameTimer
@onready var _game_time_label : Label = $Control/GameTimeLabel


func _ready()->void:
	_game_timer.start(round_length)


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
	game_over.emit()
	_reset()


func _reset()->void:
	for i in _scores.keys():
		_scores[i] = 0
		_update_score(i)
	_game_timer.start(round_length)
