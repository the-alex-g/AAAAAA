extends Control

signal return_to_game
signal return_to_menu

var _control_menu_open := false

@onready var _options : PanelContainer = $PanelContainer
@onready var _control_info : PanelContainer = $ControlInfo


func _input(event:InputEvent)->void:
	if event is InputEventJoypadButton:
		if event.pressed and visible:
			_resolve_event(event)


func _resolve_event(event:InputEventJoypadButton)->void:
	if _control_menu_open:
		_toggle_controls()
	else:
		match event.button_index:
			JOY_BUTTON_B:
				return_to_game.emit()
			JOY_BUTTON_BACK:
				return_to_menu.emit()
			JOY_BUTTON_Y:
				_toggle_controls()


func _toggle_controls()->void:
	_options.visible = not _options.visible
	_control_info.visible = not _options.visible
	_control_menu_open = not _control_menu_open
