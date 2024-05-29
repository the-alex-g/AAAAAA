class_name RoundOverMenu
extends Control

const HEAD_SHADER_PATH := "res://world/win_banner.gdshader"
const WIN_GEM_SHADER_PATH := "res://world/win_gem.gdshader"
const WIN_GEM_IMAGE_PATH := "res://world/win_gem.png"

@onready var _round_over_head : TextureRect = $WinnerHead
@onready var _win_gem_container : GridContainer = $WinGemContainer
@onready var _end_game_label : Label = $EndGameLabel


func end_round(winning_colors:Array[Color])->void:
	show()
	set_colors(winning_colors)
	add_win_gem(winning_colors)


func end_game(winning_colors:Array[Color])->void:
	end_round(winning_colors)
	_end_game_label.show()


func start_new_round()->void:
	hide()
	_end_game_label.hide()


func set_colors(colors:Array[Color])->void:
	var new_material := ShaderMaterial.new()
	new_material.shader = load(HEAD_SHADER_PATH)
	
	_set_shader_colors(new_material, colors)
	
	_round_over_head.material = new_material


func add_win_gem(colors:Array[Color]) -> void:
	var new_material := ShaderMaterial.new()
	new_material.shader = load(WIN_GEM_SHADER_PATH)
	
	_set_shader_colors(new_material, colors)
	
	_create_win_gem_with_material(new_material)


func _set_shader_colors(shader_material:ShaderMaterial, colors:Array[Color])->void:
	shader_material.set_shader_parameter("segments", colors.size())
	for i in colors.size():
		shader_material.set_shader_parameter("color" + str(i + 1), colors[i])


func _create_win_gem_with_material(gem_material:ShaderMaterial)->void:
	var win_gem := TextureRect.new()
	win_gem.texture = load(WIN_GEM_IMAGE_PATH)
	win_gem.material = gem_material
	_win_gem_container.add_child(win_gem)


func clear_win_gems()->void:
	for win_gem in _win_gem_container.get_children():
		win_gem.queue_free()
