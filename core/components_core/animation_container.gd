class_name AnimationContainer extends Control
const TYPE_ID:StringName = &"AnimationContainer"

const HOVER_VERTICAL_OFFSET: float = StackComponent.STACK_OFFSET_Y
const MOVEMENT_TWEEN_DURATION: float = 0.5
const VISIBILITY_TWEEN_DURATION: float = 0.1
const HELD_ENTITIES_ALPHA_CHANGE_FIRST_ALPHA:float = 0.2

@export var phantom_card:NinePatchRect


var entity: Control
# Tween references.
var movement_tween: Tween = null
var visibility_tween: Tween = null
var progress_tween:Tween


func _enter_tree() -> void:
	name = get_script().get_global_name()
	if get_parent() is Control:
		entity = get_parent()
	else:
		push_warning(get_script().get_global_name()," child of ",get_parent()," is not child of Contorl Node")
		set_script.call_deferred(null)
		return
	if not entity.has_meta(get_script().get_global_name()):
		entity.set_meta(get_script().get_global_name(),self)

func _exit_tree() -> void:
	if entity and entity.has_meta(get_script().get_global_name()):
		entity.remove_meta(get_script().get_global_name())
		
	var active_animations:Dictionary = AnimationController.active_animations
	for entry:Array in active_animations.values():
		if entry.has(self):
			entry.erase(self)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	reset_animation()
	connect_emitter_signals()


# =====================================================
# SIGNAL CONFIGURATION
# =====================================================

# [to-do] add this to component event coordinator?
# Connect signals, looks for any entity repositioned signals amoung siblings. 
func connect_emitter_signals() -> void:
	for meta_name:String in entity.get_meta_list():
		var entry:Variant = entity.get_meta(meta_name)
		if entry is not Node:continue
		
		if entry.has_signal("entity_repositioned"):
			if not entry.entity_repositioned.is_connected(_on_entity_repositioned):
				entry.entity_repositioned.connect(_on_entity_repositioned)
	
	if entity.has_signal("entity_repositioned"):
		if not entity.entity_repositioned.is_connected(_on_entity_repositioned):
			entity.entity_repositioned.connect(_on_entity_repositioned)

func _on_entity_repositioned(old_position:Vector2,inline:bool = true) -> void:
	animate_move_from(old_position,inline)

# =====================================================
# ANIMATION STATES
# =====================================================
func held_entities_alpha_change(on:bool,first:bool = false)-> void:
	var alpha:float = 1.0 if not on else 0.0 if not first else HELD_ENTITIES_ALPHA_CHANGE_FIRST_ALPHA
	alpha_animation(alpha)

func target_entity_offset_down(on:bool)-> void:
	var target_location:Vector2 = Vector2(0,HOVER_VERTICAL_OFFSET/-2) if on else Vector2.ZERO
	tween_move_to(target_location)

func target_chain_offset_up(on:bool,is_bottom:bool = false)-> void:
	var target_location:Vector2 = Vector2(0,HOVER_VERTICAL_OFFSET) if on else Vector2.ZERO
	if phantom_card:
		phantom_card.visible = true if on and is_bottom else false
	tween_move_to(target_location)

# =====================================================
# ANIMATIONS
# =====================================================

func alpha_animation(alpha:float, duration:float = VISIBILITY_TWEEN_DURATION)-> void:
	var new_color: Color = modulate
	new_color.a = alpha

	if visibility_tween:
		visibility_tween.kill()
	visibility_tween = create_tween()
	visibility_tween.tween_property(self, "modulate", new_color, duration)

func animate_move_from(old_position:Vector2,inline:bool = true, animation_duration: float = MOVEMENT_TWEEN_DURATION)-> void:
	if old_position == entity.position:
		return

	var from_position: Vector2 = (old_position - entity.position)
	
	# Adjust the container’s position instantly on the Y axis.
	var from_x:float = position.x if inline else from_position.x
	position = Vector2(from_x, from_position.y)
	tween_move_to(Vector2.ZERO, animation_duration)

func tween_move_to(target_position: Vector2, duration: float = MOVEMENT_TWEEN_DURATION) -> void:
	var distance:float = abs(position.y-target_position.y)
	if movement_tween:
		movement_tween.kill()
	
	duration = max(duration * distance/entity.size.y/2,duration)
	
	var transition_type: Tween.TransitionType = Tween.TRANS_BACK 
	movement_tween = create_tween()
	movement_tween.tween_property(self, "position", target_position, duration)\
		.set_trans(transition_type)\
		.set_ease(Tween.EASE_OUT)

# =====================================================
# ANIMATION CONTROL METHODS
# =====================================================

func stop_animation() -> void:
	if movement_tween:
		movement_tween.kill()
	if visibility_tween:
		visibility_tween.kill()

func reset_animation() -> void:
	stop_animation()
	position = Vector2.ZERO
	scale = Vector2.ONE
	modulate = Color(1, 1, 1, 1)
	show()


# =====================================================
# UTIL
# =====================================================

static func get_component_or_null(s_entity:Control,_name:StringName="")-> AnimationContainer:
	if not s_entity:
		return null
	
	if s_entity.has_meta(TYPE_ID):
		return s_entity.get_meta(TYPE_ID)
	return null
