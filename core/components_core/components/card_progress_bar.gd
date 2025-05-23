extends TextureProgressBar
class_name CardProgressBar
const TYPE_ID:StringName = &"CardProgressBar"

var tween:Tween
var start_position:Vector2
var start_size:Vector2
var entity:Control
var default_color:Color
var disabled:bool = false


func _enter_tree() -> void:
	if not entity:
		push_warning(get_script().get_global_name()," did not get set entity")
		set_script.call_deferred(null)
		return
		
	if not entity.has_meta(get_script().get_global_name()):
		entity.set_meta(get_script().get_global_name(),self)
		set_default_size_and_position()


func _exit_tree() -> void:
	if entity and entity.has_meta(get_script().get_global_name()):
		entity.remove_meta(get_script().get_global_name())


func _ready() -> void:
	default_color = Color.html("8670ff")
	value_changed.connect(change_animation.unbind(1))


func set_default_size_and_position()-> void:
	var par_size:Vector2 = get_parent().size
	size.x = par_size.x - 8
	start_size = size
	
	position.x = 4
	position.y = par_size.y-3
	start_position = position


func reset_size_and_position()-> void:
	size = start_size
	position = start_position


func _value_changed(_new_value: float) -> void:
	if disabled:
		set_value_no_signal(0)


func set_disabled(on:bool)-> void:
	if on:
		disabled = true
	else:
		disabled = false


func change_animation()->void:
	#if max_value > 20:
	if value != max_value:
		return
	
	
	var animation_time:float = 0.2
	var delta:int = 8
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel()
	tween.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self,"position",Vector2(start_position.x+delta/2.0,start_position.y),animation_time/2)
	tween.tween_property(self,"size",Vector2(get_parent().size.x - 8-delta,5),animation_time/2.0)
	
	await tween.finished
	tween = create_tween()
	tween.set_parallel()
	tween.set_trans(Tween.TRANS_SPRING)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"position",start_position,animation_time/2.0)
	tween.tween_property(self,"size",Vector2(get_parent().size.x - 8,5),animation_time/2.0)


func set_progress_color(resource:Resource)-> void:
	if not resource:
		return
		
	tint_under = resource.color.darkened(.4)
	
	var color:Color = resource.spawn_cards[0].color if not resource.spawn_cards.is_empty() else default_color
	var stack_component:StackComponent = StackComponent.get_component_or_null(entity)
	var previous:Control = stack_component.previous if stack_component else null
	
	
	if resource.card_name in Global.land_cards and previous and previous is Card:
		var crop_cards:Array = Global.crop_cards
		if previous.card_resource.card_name in crop_cards:
			color = previous.card_resource.color
	
	tint_progress = color
