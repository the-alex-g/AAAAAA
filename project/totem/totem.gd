class_name Totem
extends Area2D

signal used

var enabled := true

@onready var _sprite : AnimatedSprite2D = $Sprite


func _on_body_entered(body:Node2D)->void:
	if body is Goblin and enabled and body.small:
		body.grow()
		_crumble()


func _crumble()->void:
	enabled = false
	used.emit()
	_sprite.play("crumble")
	
	await _sprite.animation_finished
	
	queue_free()
