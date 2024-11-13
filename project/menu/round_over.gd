class_name RoundOverMenu
extends Control

const HEAD_SHADER_PATH := "res://world/win_banner.gdshader"
const WIN_GEM_SHADER_PATH := "res://world/win_gem.gdshader"
const WIN_GEM_IMAGE_PATH := "res://world/win_gem.png"

@onready var _round_over_head : TextureRect = $WinnerHead
@onready var _win_label_container : VBoxContainer = $WinLabelContainer
@onready var _end_game_label : Label = $EndGameLabel
@onready var _round_indicator : Label = $RoundIndicator

var _wins_by_color := {}


func end_round(winning_colors:Array[Color], rounds_elapsed: int, total_rounds: int)->void:
	show()
	set_colors(winning_colors)
	_update_wins(winning_colors)
	
	if total_rounds > 0:
		_round_indicator.text = "Round %d/%d" % [rounds_elapsed, total_rounds]
	else:
		_round_indicator.text = ""


func _update_wins(colors: Array[Color]) -> void:
	for color in colors:
		if color in _wins_by_color:
			_wins_by_color[color] += 1
		else:
			_wins_by_color[color] = 1
	_update_win_labels()


func _update_win_labels() -> void:
	for child in _win_label_container.get_children():
		child.queue_free()
	for color in _wins_by_color.keys():
		var label := Label.new()
		label.modulate = color
		label.text = "%d Win%s" % [_wins_by_color[color], "" if _wins_by_color[color] == 1 else "s"]
		_win_label_container.add_child(label)


func end_game(winning_colors:Array[Color])->void:
	show()
	_round_indicator.text = ""
	set_colors(winning_colors)
	_wins_by_color.clear()
	_end_game_label.show()


func start_new_round()->void:
	hide()
	_end_game_label.hide()


func set_colors(colors:Array[Color])->void:
	var new_material := ShaderMaterial.new()
	new_material.shader = load(HEAD_SHADER_PATH)
	
	_set_shader_colors(new_material, colors)
	
	_round_over_head.material = new_material


func _set_shader_colors(shader_material:ShaderMaterial, colors:Array[Color])->void:
	shader_material.set_shader_parameter("segments", colors.size())
	for i in colors.size():
		shader_material.set_shader_parameter("color" + str(i + 1), colors[i])
