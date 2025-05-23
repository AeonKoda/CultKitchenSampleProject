class_name AnimationControllerSingleton extends Node
var held_entities_alpha_change:bool = false
var target_entity_offset_down:bool = false
var target_chain_offset_up:bool = false

var active_animations:Dictionary[String, Array] = {
	"held_entities_alpha_change":[],
	"target_entity_offset_down":[],
	"target_chain_offset_up":[],
}


func _ready() -> void:
	TargetController.held_changed.connect(_on_held_changed)
	TargetController.target_changed.connect(_on_target_changed.unbind(1))
	TargetController.speacial_area_target_changed.connect(_on_special_area_target_changed.unbind(1))
	TargetController.state_changed.connect(_on_state_changed.unbind(1))

func _on_held_changed()-> void:
	set_held_entities_alpha_change_animtaion()

func _on_target_changed()-> void:
	set_target_entity_offset_down_animation()
	set_target_chain_offset_up_animation()

func _on_special_area_target_changed()-> void:
	set_target_chain_offset_up_animation()

func _on_state_changed()-> void:
	set_held_entities_alpha_change_animtaion()
	set_target_entity_offset_down_animation()
	set_target_chain_offset_up_animation()

# =====================================================
# HELD ENTITIES ALPHA CHANGE ANIMATION
# =====================================================
func set_held_entities_alpha_change_animtaion()-> void:
	held_entities_alpha_change = should_held_entities_alpha_change()
	
	# animation should be activated
	if held_entities_alpha_change: 
		var held_entities:Array[Control] = TargetController.held_entities
		var currently_active:Array = active_animations["held_entities_alpha_change"].duplicate()
		
		# deactivate any active entities that are not held
		for entity:Control in currently_active:
			if entity not in held_entities:
				active_animations["held_entities_alpha_change"].erase(entity)
				
			var anim_container:AnimationContainer = AnimationContainer.get_component_or_null(entity)
			if anim_container:
				anim_container.held_entities_alpha_change(false)
		
		# active any held entities not already active
		var stack_component:StackComponent = get_stack_component(held_entities[0]) if not held_entities.is_empty() else null
		var bottom:Control = stack_component.get_bottom() if stack_component else null
		for entity:Control in held_entities:
			if entity not in currently_active:
				active_animations["held_entities_alpha_change"].append(entity)
				
			var anim_container:AnimationContainer = AnimationContainer.get_component_or_null(entity)
			if anim_container:
				var first:float = true if entity == bottom else false
				anim_container.held_entities_alpha_change(true, first)
	
	# animation should be deactivated
	else:
		var currently_active:Array = active_animations["held_entities_alpha_change"].duplicate()
		for entity:Control in currently_active:
			active_animations["held_entities_alpha_change"].erase(entity)
			
			var anim_container:AnimationContainer = AnimationContainer.get_component_or_null(entity)
			if anim_container:
				anim_container.held_entities_alpha_change(false)


func should_held_entities_alpha_change()-> bool:
	var active:bool = false
	if TargetController.state == TargetController.States.SELECT_HOVER_HOLD or TargetController.state == TargetController.States.SELECT_SPECIAL_HOVER_HOLD:
		active = true
	return active

# =====================================================
# TARGET ENTITY OFFSET DOWN ANIMATION
# =====================================================
func set_target_entity_offset_down_animation()-> void:
	target_entity_offset_down = should_target_entity_offset_down()
	
	if target_entity_offset_down:
		var target:Control = TargetController.get_target()
		# deactivate any active entities that are not target
		for entity:Control in active_animations["target_entity_offset_down"].duplicate():
			if entity != target:
				active_animations["target_entity_offset_down"].erase(entity)
				
				var anim_container:AnimationContainer = AnimationContainer.get_component_or_null(entity)
				if anim_container:
					anim_container.target_entity_offset_down(false)

		
		# active the target entity not already active
		active_animations["target_entity_offset_down"].append(target)
		
		var target_anim_container:AnimationContainer = AnimationContainer.get_component_or_null(target)
		if target_anim_container:
			target_anim_container.target_entity_offset_down(true)
	else:
		# deactivate any active entities
		for entity:Control in active_animations["target_entity_offset_down"].duplicate():
			active_animations["target_entity_offset_down"].erase(entity)
			
			var anim_container:AnimationContainer = AnimationContainer.get_component_or_null(entity)
			if anim_container:
				anim_container.target_entity_offset_down(false)

func should_target_entity_offset_down()-> bool:
	var active:bool = false
	if TargetController.state == TargetController.States.SELECT_HOVER:
		active = true
	return active


# =====================================================
# TARGET CHAIN OFFSET UP ANIMATION
# =====================================================

func set_target_chain_offset_up_animation()-> void:
	target_chain_offset_up = should_target_chain_offset_up()
	
	if target_chain_offset_up:
		var controller_target:Control = TargetController.get_target()
		var target:Control = controller_target if controller_target else TargetController.special_area_target
		var target_stack_component:StackComponent = get_stack_component(target)
		var target_is_bottom:bool = false if controller_target else true
		if target_stack_component:
			var chain_to_animate:Array = target_stack_component.get_chain(target)
			if not target_is_bottom:
				chain_to_animate.erase(target)
			
			# deactivate any active entities that are not in chain_to_aniamte
			for entity:Control in active_animations["target_chain_offset_up"].duplicate():
				if entity not in chain_to_animate:
					active_animations["target_chain_offset_up"].erase(entity)
					
					var anim_container:AnimationContainer = AnimationContainer.get_component_or_null(entity)
					if anim_container:
						anim_container.target_chain_offset_up(false)

		
			# active the target entity not already active
			for entity:Control in chain_to_animate:
				if entity not in active_animations["target_chain_offset_up"]:
					active_animations["target_chain_offset_up"].append(entity)
					
				var anim_container:AnimationContainer = AnimationContainer.get_component_or_null(entity)
				if anim_container:
					var is_bottom:bool = true if entity == target and target_is_bottom else false
					anim_container.target_chain_offset_up(true,is_bottom)
	else:
		# on queue release do clean up so freed containers arent in memeory
		#active_animations["target_chain_offset_up"].clear()
		# deactivate any active entities
		for entity:Control in active_animations["target_chain_offset_up"].duplicate():
			active_animations["target_chain_offset_up"].erase(entity)
			
			var anim_container:AnimationContainer = AnimationContainer.get_component_or_null(entity)
			if anim_container:
				anim_container.target_chain_offset_up(false)

func should_target_chain_offset_up()-> bool:
	var active:bool = false

	if ((TargetController.state == TargetController.States.SELECT_HOVER_HOLD or 
			TargetController.state == TargetController.States.SELECT_SPECIAL_HOVER_HOLD) and 
			(TargetController.get_target() or TargetController.special_area_target)):
		active = true
	return active

func get_stack_component(item:Control)-> StackComponent:
	var item_stack_component:StackComponent = null
	for child:Node in item.get_children():
		if child is StackComponent:
			item_stack_component = child
			break
	return item_stack_component
