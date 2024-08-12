class_name MainMenu
extends ColorRect

signal game_started(round_count)

var _control_menu_open := false
var _total_rounds := -1

@onready var _game_length_label : Label = $MainMenuOptions/GameLengthLabel
@onready var _control_info : PanelContainer = $ControlInfo
@onready var _main_menu_options : GridContainer = $MainMenuOptions


func _input(event:InputEvent)->void:
	if event is InputEventJoypadButton:
		if event.pressed and visible:
			_resolve_main_menu_event(event)


func _resolve_main_menu_event(event:InputEventJoypadButton)->void:
	if _control_menu_open:
		_toggle_controls()
	else:
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
			JOY_BUTTON_Y:
				_toggle_controls()


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
	game_started.emit(_total_rounds)


func _toggle_controls()->void:
	_main_menu_options.visible = not _main_menu_options.visible
	_control_info.visible = not _main_menu_options.visible
	_control_menu_open = not _control_menu_open
