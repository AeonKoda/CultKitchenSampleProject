class_name Indicator extends NinePatchRect
const TYPE_ID:StringName = &"Indicator"

var start_position:Vector2

var color:Color = Color("afffa1")
var color_n:Color = Color("fffca1")
var color_b:Color = Color("ffa1a1")
var tween:Tween
var entity:Control

signal toggle_finished(on:bool)

func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		if not entity:
			push_warning(get_script().get_global_name()," did not get set entity")
			set_script.call_deferred(null)
			return
			
		if not entity.has_meta(get_script().get_global_name()):
			entity.set_meta(get_script().get_global_name(),self)
	if what == NOTIFICATION_EXIT_TREE:
		if entity and entity.has_meta(get_script().get_global_name()):
			entity.remove_meta(get_script().get_global_name())


func _ready() -> void:
	#temp inverse change
	start_position =  Vector2(get_parent().size.x/2-4,get_parent().size.y-4)
	position =  start_position


func on() ->void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self,"position",Vector2(5,start_position.y),0.4)
	tween.tween_property(self,"size",Vector2(80,5),0.4)
	tween.finished.connect(tween_finished.bind(true))
	#self_modulate = color

func off() ->void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self,"position",Vector2(entity.size.x/2-4,start_position.y),0.4)
	tween.tween_property(self,"size",Vector2(8,5),0.4)
	tween.finished.connect(tween_finished.bind(false))

func tween_finished(is_on:bool)-> void:
	toggle_finished.emit(is_on)

static func get_component_or_null(s_entity:Control)-> Indicator:
	if not s_entity:
		return null
	
	if s_entity.has_meta(TYPE_ID):
		return s_entity.get_meta(TYPE_ID)
	return null
