class_name Bomb
extends Area2D

@export var blast_radius := 16.0 : set = _set_blast_radius
@export var bomb_radius := 1
@export var blast_strength := 300.0
@export var time_to_detonation := 0.2

@onready var _blink_timer : Timer = $BlinkTimer
@onready var _explode_sound : AudioStreamPlayer2D = $ExplodeSound
@onready var _explosion_sprite : AnimatedSprite2D = $Explosion


func _ready()->void:
	_set_blast_radius(blast_radius)
	_blink_timer.start(time_to_detonation)


func _on_blink_timer_timeout()->void:
	_explode()


func _explode()->void:
	_explode_sound.play()
	
	for body in get_overlapping_bodies():
		if body is Goblin:
			body.knockback(blast_strength, get_angle_to(body.global_position))
	
	_explosion_sprite.play("explode")
	_blink_timer.stop()


func _set_blast_radius(value:float)->void:
	var new_shape := CircleShape2D.new()
	new_shape.radius = value
	$CollisionShape2D.shape = new_shape


func _on_explode_sound_finished()->void:
	queue_free()
