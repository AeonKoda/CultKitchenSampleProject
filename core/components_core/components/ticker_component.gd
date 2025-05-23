class_name TickerComponent extends Component
const TYPE_ID:StringName = &"TickerComponent"

signal reached_max
signal power_toggled(entity:Control,power:bool)
signal disabled_changed(entity:Control,disabled:bool)

var disabled:bool = false:
	set(value):
		if disabled != value:
			disabled_changed.emit(entity,value)
		disabled = value

var disable_control:bool = false

var tick_resource:Resource

var max_progress:int 
var default_speed:float
var current_speed:float


var tick_action:Script

var speed_boost:bool = false
var texture_container:Control
var timer_tween:Tween

var power:bool = false:
	set(value):
		power = value
		
		if progress:
			progress.set_progress_color(tick_resource)
		#entity.ticker_power = power
		if value:
			indicator.on()
			indicator.show()
			progress.hide()
			var is_on:bool = await indicator.toggle_finished
			if is_on:
				indicator.hide()
				progress.show()
				progress.value = 0
				if timer_tween:
					timer_tween.kill()
				timer_tween = create_tween()
				timer_tween.set_loops()
				timer_tween.tween_property(progress,"value",progress.max_value,max_progress/current_speed)
				timer_tween.loop_finished.connect(tick_up)
				if disabled:
					set_disabled(true)
		else:
			indicator.off()
			indicator.show()
			progress.hide()
			if timer_tween:
				timer_tween.kill()
			progress.value = 0
		

@onready var progress: CardProgressBar
@onready var indicator: Indicator
@onready var timer: Timer

func _init(resource:CardResource) -> void:
	tick_resource = resource
	max_progress = resource.progress_max_value
	default_speed = resource.tick_speed
	current_speed = default_speed
	tick_action = resource.tick_action


func _ready() -> void:
	#progress = CardProgressBar.get_component_or_null(entity)
	if not progress:
		progress = Global.card_progress_bar_scene.instantiate()
		progress.entity = entity
		progress.max_value = max_progress*60 #*60 gives a smooth growth
		progress.set_progress_color(tick_resource)
		var animation_container:AnimationContainer =  AnimationContainer.get_component_or_null(entity)
		if animation_container:
			animation_container.add_child(progress)
		else:
			entity.add_child.call_deferred(progress)
	
	indicator = Indicator.get_component_or_null(entity)
	if not indicator:
		indicator = Global.card_indicator_scene.instantiate()
		indicator.entity = entity
		indicator.modulate = tick_resource.color.darkened(.3)
		var animation_container:AnimationContainer =  AnimationContainer.get_component_or_null(entity)
		if animation_container:
			animation_container.add_child(indicator)
		else:
			entity.add_child.call_deferred(indicator)
	indicator.off()
	progress.hide()
	
	power = tick_resource.auto_on
	disable_control = tick_resource.disable_control
	super()

func _on_indicator_toggle_finished()-> void:
	if power:
		progress.show()
		indicator.hide()
		return
	progress.hide()
	indicator.show()


func toggle_power() ->void:
	if disable_control:return
	if power:
		power = false
	else:
		power = true 
	power_toggled.emit(entity,power)

func set_progress_color()-> void:
	progress.set_progress_color(tick_resource)

func set_disabled(value:bool)-> void:
	if not power:return
	disabled = value
	if value:
		progress.value = 0
		progress.set_disabled(true)
		if timer_tween and timer_tween.is_valid():
			timer_tween.stop()
	else:
		progress.set_disabled(false)
		if timer_tween and timer_tween.is_valid():
			timer_tween.play()

func remove()->void:
	progress.queue_free()
	indicator.queue_free()
	timer.queue_free()
	queue_free()

func tick_up(_double:bool = false) ->void:
	tick_action.tick(entity)
	progress.value = 0
	reached_max.emit()

func set_invisible(value:bool)-> void:
	if value:
		if not progress.visibility_changed.is_connected(progress.hide):
			progress.visibility_changed.connect(progress.hide)
		if not indicator.visibility_changed.is_connected(indicator.hide):
			indicator.visibility_changed.connect(indicator.hide)
		progress.hide()
		indicator.hide()
	else:
		if progress.visibility_changed.is_connected(progress.hide):
			progress.visibility_changed.disconnect(progress.hide)
		if indicator.visibility_changed.is_connected(indicator.hide):
			indicator.visibility_changed.disconnect(indicator.hide)
		
		if power:
			progress.show()
			indicator.hide()
		else:
			progress.hide()
			indicator.show()

func release()->void:
	if progress:
		progress.queue_free()
	if indicator:
		indicator.queue_free()
	queue_free()

static func get_component_or_null(s_entity:Control,_name:StringName="")-> TickerComponent:
	if not s_entity:
		return null
	
	if s_entity.has_meta(TYPE_ID):
		return s_entity.get_meta(TYPE_ID)
	return null
