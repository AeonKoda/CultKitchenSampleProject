class_name ClickerComponent extends Component
const TYPE_ID:StringName = &"ClickerComponent"

signal reached_max

const SMOOTH_SCALAR:int = 60
const TWEEN_TIME:float = 0.2

var progress: CardProgressBar

var disabled:bool
var progress_tween:Tween
var max_progress:int
var progress_value:int = 0
var click_action:Script
var click_action_resource:Resource


func _init(max_to_trigger:int,action:Script,action_resource:Resource) -> void:
	max_progress = max_to_trigger
	click_action = action
	click_action_resource = action_resource

func _ready() -> void:
	disabled = click_action_resource.locked
	
	#progress = CardProgressBar.get_component_or_null(entity)
	if not progress:
		progress = Global.card_progress_bar_scene.instantiate()
		progress.entity = entity
		progress.max_value = (max_progress - 1)*SMOOTH_SCALAR
		# [to-do] put this in the coordinator
		var animation_container:AnimationContainer =  AnimationContainer.get_component_or_null(entity)
		if animation_container:
			animation_container.add_child(progress)
		else:
			entity.add_child.call_deferred(progress)
			
		set_progress_color()
	super()

func set_progress_color()-> void:
	progress.set_progress_color(click_action_resource)

func click(_double:bool = false) ->void:
	if progress_value == max_progress - 1:
		progress.value = progress.max_value
		if progress_tween:
			progress_tween.kill()
		progress.value = 0
		progress_value = 0
		click_action.click(entity,click_action_resource)
		reached_max.emit()
	else:
		if progress_tween:
			progress_tween.kill()
		progress_tween = create_tween()
		progress_value += 1
		progress_tween.tween_property(progress,"value",(progress_value)*SMOOTH_SCALAR-1,TWEEN_TIME)

func release()->void:
	if progress:
		progress.queue_free()
	queue_free()

static func get_component_or_null(s_entity:Control,_name:StringName="")-> ClickerComponent:
	if not s_entity:
		return null
	
	if s_entity.has_meta(TYPE_ID):
		return s_entity.get_meta(TYPE_ID)
	return null
