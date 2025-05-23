class_name PoofAnimation extends Node2D

@onready var poof_animation: AnimatedSprite2D = $PoofAnimation
@onready var pop_sound: AudioStreamPlayer = $PopSound

var parent:Node 


func _ready() -> void:
	if get_parent() is not Control:
		queue_free()
		return
	
	pop_sound.play()
	poof_animation.play("default")
	poof_animation.animation_finished.connect(_anim_finished)


func _anim_finished()-> void:
	queue_free()

func _physics_process(_delta: float) -> void:
	global_position = get_parent().global_position + get_parent().size/2
