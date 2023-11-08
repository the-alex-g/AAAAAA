class_name Goblin
extends CharacterBody2D

signal died

const GRAVITY := 8.0

@export_group("attack effects")
@export var kick_knockback := 200.0
@export var punch_stun_duration := 0.5
@export_group("movement")
@export var speed := 80
@export var slide := Vector2(0.3, 0.1)
@export var jump_strength := 150
@export_group("attack cooldowns")
@export var kick_cooldown := 0.5
@export var punch_cooldown := 0.5
@export var super_cooldown := 2.0
@export_group("growth")
@export var growth_duration := 5.0
@export var super_punch_knockback := 400.0
@export_group("utilities")
@export var color1 := Color.BLACK : set = _set_color_1
@export var color2 := Color.WHITE : set = _set_color_2
@export var index := 0
@export var attack_range := 8.0
@export var disabled := false

var _stun_time := 0.0
var small := true
var _can_attack := true
var _special_animation_playing := false

@onready var _sprite : AnimatedSprite2D = $Sprite
@onready var _cooldown_timer : Timer = $CooldownTimer
@onready var _growth_timer : Timer = $GrowthTimer
@onready var _attack_sound : AudioStreamPlayer2D = $AttackSound
@onready var _grow_sound : AudioStreamPlayer2D = $GrowSound
@onready var _shrink_sound : AudioStreamPlayer2D = $ShrinkSound
@onready var _hit_area : Area2D = $HitArea


func _physics_process(delta:float)->void:
	if not is_on_floor() or velocity.y > 0.0:
		velocity.y += GRAVITY
	
	if _stun_time <= 0.0 and not disabled:
		_process_actions()
	else:
		_stun_time -= delta
		velocity.x = lerp(velocity.x, 0.0, slide.x)
	
	_process_animation()
	
	move_and_slide()
	
	position.x = fposmod(position.x, 160)
	
	if position.y >= 200.0:
		died.emit()


func _process_actions()->void:
	var axis := Input.get_joy_axis(index, JOY_AXIS_LEFT_X)
	var movement := (axis if abs(axis) > 0.25 else 0.0) * speed
	
	velocity.x = lerp(velocity.x, movement, slide.y)
	
	if Input.is_action_just_pressed("jump_" + str(index)) and is_on_floor():
		velocity.y -= jump_strength
	
	if Input.is_action_pressed("punch_" + str(index)) and _can_attack:
		if Input.get_joy_axis(index, JOY_AXIS_LEFT_Y) < -0.3:
			_uppercut()
		else:
			_punch()
	
	elif Input.is_action_pressed("kick_" + str(index)) and _can_attack and small:
		_kick()
	
	elif Input.is_action_pressed("super_" + str(index)) and _can_attack and small:
		_drop_bomb()


func _uppercut()->void:
	var target := _get_target(-PI / 2)
	if target != null:
		if small:
			target.stun(punch_stun_duration)
			target.knockback(kick_knockback, -PI / 2 + randf() - 0.5)
		else:
			target.stun(punch_stun_duration)
			target.knockback(super_punch_knockback, -PI / 2 + randf() - 0.5)
	
	_sprite.play("uppercut_" + ("s" if small else "l"))
	_play_attack_sound()
	
	_attack_cooldown(punch_cooldown)


func _punch()->void:
	var target := _get_target()
	if target != null:
		if small:
			target.stun(punch_stun_duration)
		else:
			target.knockback(super_punch_knockback, -PI / 2 + PI / 3 * _sprite.scale.x)
	
	_sprite.play("punch_"  + ("s" if small else "l"))
	_play_attack_sound()
	
	_attack_cooldown(punch_cooldown)


func _kick()->void:
	var target := _get_target()
	if target != null:
		target.knockback(kick_knockback, get_angle_to(target.global_position))
	
	_sprite.play("kick_s")
	_play_attack_sound()
	
	_attack_cooldown(kick_cooldown)


func _drop_bomb()->void:
	_sprite.play("super_s")
	
	var bomb : Bomb = preload("res://goblin/bomb/bomb.tscn").instantiate()
	bomb.global_position = global_position + Vector2(4 * _sprite.scale.x, -1)
	bomb.modulate = color1
	get_parent().add_child(bomb)
	
	_attack_cooldown(super_cooldown)


func _get_target(angle := 0.0)->Goblin:
	_hit_area.rotation = angle if angle != 0.0 else (PI if _sprite.scale.x == -1 else 0.0)
	var potential_targets := _hit_area.get_overlapping_bodies()
	
	for target in potential_targets:
		if target is Goblin:
			if target.index != index:
				return target
	
	return null


func _attack_cooldown(duration:float)->void:
	_special_animation_playing = true
	_can_attack = false
	_cooldown_timer.start(duration)
	
	await _cooldown_timer.timeout
	
	_can_attack = true


func _process_animation()->void:
	if velocity.x < -0.1:
		_sprite.scale.x = -1.0
	elif velocity.x > 0.1:
		_sprite.scale.x = 1.0
	
	if not _special_animation_playing:
		if abs(velocity.x) > 10.0:
			_sprite.play("run_"  + ("s" if small else "l"))
		else:
			_sprite.play("idle_"  + ("s" if small else "l"))


func stun(duration:float)->void:
	if small:
		_stun_time = duration


func knockback(strength:float, direction:float)->void:
	velocity += Vector2.RIGHT.rotated(direction) * strength * (1.0 if small else 0.5)


func reset()->void:
	velocity = Vector2.ZERO
	disabled = false
	small = true
	_stun_time = 0.0
	_cooldown_timer.timeout.emit() # this should end any cooldowns that are currently running
	_cooldown_timer.stop()
	_growth_timer.stop()
	_special_animation_playing = false


func grow()->void:
	small = false
	_sprite.play("grow")
	_grow_sound.play()
	_special_animation_playing = true
	_growth_timer.start(growth_duration)


func _on_sprite_animation_finished()->void:
	_special_animation_playing = false


func _on_growth_timer_timeout()->void:
	small = true
	_sprite.play_backwards("grow")
	_special_animation_playing = true
	_shrink_sound.play()


func _set_color_1(value:Color)->void:
	color1 = value
	call_deferred("_reload_shader")


func _set_color_2(value:Color)->void:
	color2 = value
	call_deferred("_reload_shader")


func _reload_shader()->void:
	var new_material := ShaderMaterial.new()
	new_material.shader = load("res://goblin/goblin.gdshader")
	new_material.set_shader_parameter("color1", color1)
	new_material.set_shader_parameter("color2", color2)
	_sprite.material = new_material


func _play_attack_sound()->void:
	_attack_sound.pitch_scale = randf() + (2 if small else 0)
	_attack_sound.play()
