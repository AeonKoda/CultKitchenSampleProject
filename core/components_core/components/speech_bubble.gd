class_name SpeechBubble extends NinePatchRect

@onready var margin_container: MarginContainer = %MarginContainer
@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var input_waiting: RichTextLabel = %InputWaiting
@onready var exclamation: TextureRect = %Exclamation


#var waiting_tween:Tween
#var waiting_tween_target:float 
#var waiting:bool = false

const OFFSET:Vector2 = Vector2(0,24)

func _ready() -> void:
	#mouse_entered.connect(_on_mouse_entered)
	#mouse_exited.connect(_on_mouse_exited)
	#waiting_tween_target = input_waiting.get_total_character_count()
	pass

func _physics_process(_delta: float) -> void:
	var parent_rect:Rect2 = get_parent().get_global_rect() if get_parent() is Control else null
	if not parent_rect:return
	
	var top_right:Vector2 = Vector2(parent_rect.position.x + parent_rect.size.x - 8, parent_rect.position.y) - pivot_offset*scale
	global_position = top_right + OFFSET


#func start_waiting_tween()->void:
	#waiting = true
	#waiting_tween_loop()
#
#func stop_waiting_tween()-> void:
	#waiting = false
	#if waiting_tween:
		#if waiting_tween.finished.is_connected(_on_waiting_tween_finished):
			#waiting_tween.finished.disconnect(_on_waiting_tween_finished)
		#waiting_tween.kill()
#
#func waiting_tween_loop()-> void:
	#waiting_tween = create_tween()
	#waiting_tween.tween_property(input_waiting,"visible_characters",waiting_tween_target,0.8)
	#waiting_tween.finished.connect(_on_waiting_tween_finished,4)
#
#func _on_waiting_tween_finished()-> void:
	#waiting_tween_target = input_waiting.get_total_character_count() if waiting_tween_target <= 0 else 0
	#waiting_tween.kill()
	#waiting_tween_loop()
