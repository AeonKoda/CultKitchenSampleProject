class_name ComponentEventCoordinatorSingleton extends Node

signal component_added(component:Component)
signal entity_added_to_board
signal entity_dropped

func _ready() -> void:
	connect_target_controller_signals()

func component_ready(component:Component)-> void:
	configure_component_interfaces(component)
	if not component.entity.child_entered_tree.is_connected(_on_entity_new_child):
		component.entity.child_entered_tree.connect(_on_entity_new_child)
	
	component_added.emit(component)

func _on_entity_new_child(child:Node)-> void:
	if child is Component:
		configure_component_interfaces(child)

func configure_component_interfaces(component:Component)-> void:
	var signal_connector:StringName = "connect_%s_signals" % [component.TYPE_ID.to_snake_case()]
	call(signal_connector,component)

# =====================================================
# TARGET CONTROLLER INTERFACES
# =====================================================
func connect_target_controller_signals()-> void:
	#if not TargetController.entity_removed_from_held.is_connected(_on_target_controller_entity_removed_from_held):
		#TargetController.entity_removed_from_held.connect(_on_target_controller_entity_removed_from_held)
	if not TargetController.target_changed.is_connected(_on_target_controller_target_changed):
		TargetController.target_changed.connect(_on_target_controller_target_changed)
	pass

func _target_controller_on_board_closing()-> void:
	# This is so if you try to move a board_component card outside of a board 
	# your hand is dropped
	if not TargetController.held_entities.is_empty():
		# go through each held looking for board lock
		for held_item:Control in TargetController.held_entities:
			# If you find a board lock, remove from stack, stop dragging it
			if held_item.get("board_lock"):
				held_item.hide()
			
				var stack_component:StackComponent = StackComponent.get_component_or_null(held_item)
				var next:Control = stack_component.next
				var is_bottom:bool
				if stack_component:
					if not stack_component.previous:
						is_bottom = true
					stack_component.pop_self()
					
				var lift_component:LiftComponent = LiftComponent.get_component_or_null(held_item)
				if lift_component:
					lift_component.stop_dragging()
					held_item.move_to_front()
					
				if next and is_bottom:
					var next_lift_component:LiftComponent = LiftComponent.get_component_or_null(next)
					next.global_position = held_item.global_position
					next_lift_component.start_dragging()

# =====================================================
# LIFT INTERFACES
# =====================================================
func connect_lift_component_signals(lift_component:LiftComponent)-> void:
	if not lift_component.entity_lifted.is_connected(_on_entity_lifted):
		lift_component.entity_lifted.connect(_on_entity_lifted)
	if not lift_component.entity_dropped.is_connected(_on_entity_dropped):
		lift_component.entity_dropped.connect(_on_entity_dropped)

func _lift_component_on_board_toggled(lift_component:LiftComponent, board_open:bool)-> void:
	lift_component.enabled = not board_open

# =====================================================
# STACK INTERFACES
# =====================================================
func connect_stack_component_signals(stack_component:StackComponent)-> void:
	if not stack_component.item_added_to_entity_stack.is_connected(_on_item_added_to_entity_stack):
		stack_component.item_added_to_entity_stack.connect(_on_item_added_to_entity_stack)
	if not stack_component.previous_changed.is_connected(_on_previous_changed):
		stack_component.previous_changed.connect(_on_previous_changed.bind(stack_component.entity))
	if not stack_component.entity_removed_from_item_stack.is_connected(_on_entity_removed_from_item_stack):
		stack_component.entity_removed_from_item_stack.connect(_on_entity_removed_from_item_stack)

#func _stack_component_on_target_controller_entity_removed_from_held(entity:Control,stack_component:StackComponent)-> void:
	pass
	

func _stack_component_on_entity_lifted(stack_component:StackComponent)-> void:
	# Default behavior, lift card and all card above
	if not Input.is_action_pressed("select"):
		stack_component.slice_at_previous()
		
		# Update Target Controller and Visual Order
		update_chain_lift(stack_component.next)

	# Alternate behavior, lifts only targeted card
	else:
		stack_component.pop_self()

func _stack_component_on_entity_dropped(stack_component:StackComponent)-> void:
	# Update TargetController on held cards
	update_chain_drop(stack_component.next)
	
	var current_target:Control = TargetController.get_target(["BoardActive"])
	var special_target:Control = TargetController.special_area_target
	var entity:Control = stack_component.entity
	var default:bool = false
	
	if current_target:
		var target_stack_component:StackComponent = StackComponent.get_component_or_null(current_target)
		var target_board_component:BoardComponent = BoardComponent.get_component_or_null(current_target)
		if target_stack_component and not target_board_component:
			default = true
			# Alternate behavior, places card(s) in middle of chain
			if Input.is_action_pressed("select"):
				target_stack_component.insert_as_next(entity)
				
			# Default behavior, places card(s) on top
			else:
				target_stack_component.append(entity)
		elif target_board_component and not target_board_component.open:
			target_board_component.add_to_board(entity)
	
	# The special target is a small area beneath the bottom card, used to place cards at bottom of stack
	if special_target and not default:
		# Alternate behavior, places card(s) at bottom
		if Input.is_action_pressed("select"):
			var special_target_stack_component:StackComponent = StackComponent.get_component_or_null(special_target)
			if special_target_stack_component:
				special_target_stack_component.insert_as_previous(entity)

func _stack_component_on_entity_added_to_board(_entity:Control, board_component:BoardComponent,stack_component:StackComponent)-> void:
	if stack_component.next:
		# This is defered so that stacked cards are added in the order of bottom to top if listening
		# to the board_component entity_added_to_board.
		
		# If this is undeffered you will need to change things in SideStorage to connect with the signal here
		board_component.add_to_board.call_deferred(stack_component.next,false)

func update_chain_lift(entity:Control)-> void:
	if not entity:return
	entity.z_index = LiftComponent.LIFT_Z_INDEX
	entity.move_to_front()
	TargetController.add_held(entity)
	update_chain_lift(StackComponent.get_component_or_null(entity).next)

func update_chain_drop(entity:Control)-> void:
	if not entity:return
	var stack_component:StackComponent = StackComponent.get_component_or_null(entity)
	entity.z_index = stack_component.get_bottom().z_index
	entity.move_to_front()
	update_chain_drop(stack_component.next)

# =====================================================
# TARGET INTERFACES
# =====================================================
func connect_target_component_signals(target_component:TargetComponent)-> void:
	if not target_component.targetable_entity_primary_input_pressed.is_connected(_on_targetable_entity_primary_input_pressed):
		target_component.targetable_entity_primary_input_pressed.connect(_on_targetable_entity_primary_input_pressed)
	if not target_component.targetable_entity_primary_input_released.is_connected(_on_targetable_entity_primary_input_released):
		target_component.targetable_entity_primary_input_released.connect(_on_targetable_entity_primary_input_released)
	if not target_component.targetable_entity_secondary_input_pressed.is_connected(_on_targetable_entity_secondary_input_pressed):
		target_component.targetable_entity_secondary_input_pressed.connect(_on_targetable_entity_secondary_input_pressed)
	if not target_component.targetable_entity_secondary_input_pressed_echo.is_connected(_on_targetable_entity_secondary_input_pressed_echo):
		target_component.targetable_entity_secondary_input_pressed_echo.connect(_on_targetable_entity_secondary_input_pressed_echo)
	if not target_component.targetable_entity_sleeve_pressed.is_connected(_on_targetable_entity_sleeve_pressed):
		target_component.targetable_entity_sleeve_pressed.connect(_on_targetable_entity_sleeve_pressed)

func _target_component_on_entity_lifted(entity:Control, target_component:TargetComponent)-> void:
	TargetController.add_held(entity)
	
	# This code allows you to input while holding a card. vvv
	var release_event := InputEventMouseButton.new()
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.pressed = false
	release_event.position = get_viewport().get_mouse_position()
	release_event.global_position = release_event.position
	release_event.set_meta("Dummy",true)

	# Push the event directly to the viewport
	get_viewport().push_input(release_event)
	target_component.targetable_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# This code allows you to input while holding a card. ^^^
	
	target_component.add_target_lock("Lifted")

func _target_component_on_entity_dropped(_entity:Control, target_component:TargetComponent)-> void:
	target_component.targetable_item.mouse_filter = Control.MOUSE_FILTER_PASS # This code allows you to input while holding a card.
	# Why do I defer this?
	target_component.remove_target_lock.call_deferred("Lifted")

func _target_component_on_board_toggled(target_component:TargetComponent, board_open:bool)-> void:
	if board_open:
		target_component.add_target_lock("BoardActive")
	else:
		target_component.remove_target_lock("BoardActive")

# [to-do] this needs to be so that if a card is held and has stack component, the base card listens for stack adding
# right now its checking everytime a card is added which is a bit much
func _target_controller_on_item_added_to_entity_stack(entity:Control,item:Control)-> void:
	if entity in TargetController.held_entities:
		TargetController.add_held(item)

func _target_controller_on_entity_removed_from_item_stack(entity:Control,item:Control)-> void:
	if item not in TargetController.held_entities:return
	
	if entity in TargetController.held_entities:
		entity.z_index = 0
		entity.move_to_front()
		TargetController.remove_held(entity) 

# =====================================================
# CLICKER INTERFACES
# =====================================================
func connect_clicker_component_signals(_clicker_component:ClickerComponent)-> void:
	pass

func _clicker_component_on_previous_changed(entity:Control)-> void:
	var clicker_component:ClickerComponent = ClickerComponent.get_component_or_null(entity)
	if clicker_component:
		clicker_component.set_progress_color()

# =====================================================
# TICKER INTERFACES
# =====================================================
func connect_ticker_component_signals(ticker_component:TickerComponent)-> void:
	if not ticker_component.disabled_changed.is_connected(_on_disabled_changed):
		ticker_component.disabled_changed.connect(_on_disabled_changed)
	if not ticker_component.power_toggled.is_connected(_on_power_toggled):
		ticker_component.power_toggled.connect(_on_power_toggled)

func _ticker_component_on_previous_changed(entity:Control)-> void:
	var ticker_component:TickerComponent = TickerComponent.get_component_or_null(entity)
	if ticker_component:
		ticker_component.set_progress_color()
	
	
	
		if entity is not Card or entity.card_resource.fuel_cards.is_empty():return
		
		var stack_component:StackComponent = StackComponent.get_component_or_null(entity)
		var previous:Card = stack_component.previous if stack_component else null
		if previous and previous is Card:
			if previous.card_resource in entity.card_resource.fuel_cards:
				ticker_component.set_disabled(false)
				return
		ticker_component.set_disabled(true)

func _ticker_component_on_any_primary_input(entity:Control,ticker_component:TickerComponent)-> void:
	ticker_component.toggle_power()
	
	if entity is not Card or entity.card_resource.fuel_cards.is_empty():return
		
	var stack_component:StackComponent = StackComponent.get_component_or_null(entity)
	var previous:Card = stack_component.previous if stack_component else null
	if entity.card_resource.fuel_cards.is_empty():return
	
	if previous and previous is Card:
		if previous.card_resource in entity.card_resource.fuel_cards:
			ticker_component.set_disabled(false)
			return
	ticker_component.set_disabled(true)
	
	
# =====================================================
# BOARD INTERFACES
# =====================================================
func connect_board_component_signals(board_component:BoardComponent)-> void:
	if not board_component.board_toggled.is_connected(_on_board_toggled):
		board_component.board_toggled.connect(_on_board_toggled)
	if not board_component.failed_remove_item_from_board.is_connected(_on_board_failed_remove_item_from_board):
		board_component.failed_remove_item_from_board.connect(_on_board_failed_remove_item_from_board)
	if not board_component.board_closing.is_connected(_on_board_closing):
		board_component.board_closing.connect(_on_board_closing)
	if not board_component.entity_added_to_board.is_connected(_on_entity_added_to_board):
		board_component.entity_added_to_board.connect(_on_entity_added_to_board.bind(board_component))
	if not board_component.entity_removed_from_board.is_connected(_on_entity_removed_from_board):
		board_component.entity_removed_from_board.connect(_on_entity_removed_from_board.bind(board_component))

func _board_component_on_secondary_input(_entity:Control,board_component:BoardComponent)-> void:
	board_component.toggle_board()

# =====================================================
# SPEECH INTERFACES
# =====================================================
func connect_speech_component_signals(_speech_component:SpeechComponent)-> void:
	pass

func _speech_component_on_secondary_input(_entity:Control,speech_component:SpeechComponent)-> void:
	speech_component.bubble_input()

# =====================================================
# MIXING INTERFACES
# =====================================================

func _mixer_on_item_added_to_entity_stack(entity:Control,item:Control)-> void:
	if (entity is not Card or item is not Card):
		return
	if (entity.releasing or item.releasing):
		return

	
	var item_stack_component:StackComponent = StackComponent.get_component_or_null(item)
	var chain:Array[Control] = item_stack_component.get_chain()
	var bottom_position:Vector2 = item_stack_component.get_bottom().global_position
	
	var object_slice:Array[Control] = item_stack_component.get_slice(RecipeBook.MAX_COMBINATION_SIZE,RecipeBook.MAX_COMBINATION_SIZE)
	var resource_slice:Array = object_slice.map(func(obj:Control)->CardResource:return obj.get("card_resource"))
	while resource_slice.has(null):
		resource_slice.erase(null)
	
	var result:Dictionary = RecipeBook.check_combine(resource_slice)
	var new_cards:Array[Card]
	
	while result:
		var stack_component:StackComponent = StackComponent.get_component_or_null(entity)
		
		var reagents:Array = result["reagents"].map(func(index:int)->Control:return object_slice[index])
		var new_card:Card = Global.create_card(result["resource"])
		
		new_card.created_from_mix = true
		entity.get_parent().add_child(new_card)
		new_card.position = stack_component.get_top().position + Vector2(0,stack_component.stack_offset_y)*3
		
		new_cards.append(new_card)
		
		var first_reagent_previous:Card = object_slice[result["reagents"][0]-1] if result["reagents"][0] > 0 else null
		
		for reagent_card:Card in reagents:
			var reagent_stack_component:StackComponent = StackComponent.get_component_or_null(reagent_card)
			reagent_stack_component.pop_self()
			object_slice.erase(reagent_card)
			chain.erase(reagent_card)
			reagent_card.queue_release()
		
		if first_reagent_previous:
			var first_reagent_previous_stack_component:StackComponent = StackComponent.get_component_or_null(first_reagent_previous)
			
			object_slice = first_reagent_previous_stack_component.get_slice(RecipeBook.MAX_COMBINATION_SIZE,RecipeBook.MAX_COMBINATION_SIZE)
			if object_slice.is_empty():
				break
			
			resource_slice = object_slice.map(func(obj:Control)->CardResource:return obj.get("card_resource"))
			result = RecipeBook.check_combine(resource_slice)
		else:
			break
	
	if not chain.is_empty():
		var bottom_stack_component:StackComponent = StackComponent.get_component_or_null(chain[0])
		for card:Card in new_cards:
			bottom_stack_component.append(card)
	else:
		var first_card:Card = new_cards[0]
		var first_card_stack_component:StackComponent = StackComponent.get_component_or_null(first_card)
		
		first_card.global_position = bottom_position
		new_cards.pop_front()
		
		for card:Card in new_cards:
			first_card_stack_component.append(card)

func get_contiguous_segment(input_array: Array, reference_index: int) -> Array:
	# Validate the reference index
	var array_length: int = input_array.size()
	if reference_index < 0 or reference_index >= array_length:
		return [] 

	var start_index: int = reference_index
	while start_index > 0 and input_array[start_index - 1] != null:
		start_index -= 1
	
	var end_index: int = reference_index
	while end_index < array_length - 1 and input_array[end_index + 1] != null:
		end_index += 1

	return input_array.slice(start_index, end_index + 1)

# =====================================================
# CARD INTERFACES
# =====================================================
func _card_on_previous_changed(entity:Card)-> void:
	var resource:CardResource = entity.card_resource
	if resource.card_name not in Global.land_cards:return
	
	var new_texture:Texture = resource.art_texture
	var stack_component:StackComponent = StackComponent.get_component_or_null(entity)
	var previous:Card = stack_component.previous if stack_component else null
	
	if previous:
		var previous_resource:CardResource = previous.card_resource
		var crop_cards:Array = Global.crop_cards
		if previous_resource.card_name in crop_cards:
			new_texture = resource.alternate_art_texture
			
	entity.update_card_art(new_texture)

func _card_on_disabled_changed(entity:Control, value:bool)-> void:
	if entity is not Card:return
	var card:Card = entity
	
	var ticker_component:TickerComponent = TickerComponent.get_component_or_null(entity)
	if ticker_component and ticker_component.power:
		if value:
			card.card_art.texture = card.card_resource.art_texture
		else:
			card.card_art.texture = card.card_resource.alternate_art_texture

func _card_on_power_toggled(entity:Control, value:bool)-> void:
	if entity is not Card:return
	var card:Card = entity
	var ticker_component:TickerComponent = TickerComponent.get_component_or_null(entity)
	if not value:
		card.card_art.texture = card.card_resource.art_texture
	elif value and not ticker_component.disabled:
		card.card_art.texture = card.card_resource.alternate_art_texture

func _card_on_board_toggled(card:Card,on:bool)-> void:
	if card.has_meta("Sleeve"):
		var card_sleeve:CardSleeve = card.get_meta("Sleeve")
		var sleeve:Sleeve = card_sleeve.sleeve
		if on:
			if sleeve is SleeveConveyor:
				sleeve.conveyor_button.hide()
		else:
			if card_sleeve.sleeve is SleeveConveyor:
				sleeve.conveyor_button.show()

# =====================================================
# SLEEVE INTERFACES
# =====================================================

func _sleeve_on_entity_dropped(sleeve:CardSleeve)-> void:
	var current_target:Control = TargetController.get_target()
	if current_target and current_target != self and current_target is Card:
		if not sleeve.sleeve_card(current_target):
			return
		
		var target_component:TargetComponent = TargetComponent.get_component_or_null(sleeve)
		if target_component:
			target_component.add_target_lock("Sleeve")
			sleeve.card_unsleeved.connect(func(_card:Card)-> void:
				target_component.remove_target_lock("Sleeve")
				,4)
# =====================================================
# LIFT SIGNAL PIPELINES
# =====================================================

func _on_entity_lifted(entity:Control)-> void:
	var entity_lift_component:LiftComponent = LiftComponent.get_component_or_null(entity)
	if entity_lift_component:
		if not TargetController.primary_input_released.is_connected(entity_lift_component.stop_dragging):
			TargetController.primary_input_released.connect(entity_lift_component.stop_dragging,4)
	
	var target_component:TargetComponent = TargetComponent.get_component_or_null(entity)
	if target_component:
		#target_component.targetable_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_target_component_on_entity_lifted(entity,target_component)
	
	var stack_component:StackComponent = StackComponent.get_component_or_null(entity)
	if stack_component:
		_stack_component_on_entity_lifted(stack_component)

func _on_entity_dropped(entity:Control)-> void:
	var top_board:Card = get_top_board(entity)
	if top_board:
		var top_board_component:BoardComponent = BoardComponent.get_component_or_null(top_board)
		if top_board_component:
			if not get_tree().get_nodes_in_group(top_board_component.group_name).has(entity):
				top_board_component.add_to_board(entity,false)
	
	var board_component:BoardComponent = BoardComponent.get_component_or_null(entity)
	var stack_component:StackComponent = StackComponent.get_component_or_null(entity)
	if stack_component and not board_component:
		_stack_component_on_entity_dropped(stack_component)
	
	var target_component:TargetComponent = TargetComponent.get_component_or_null(entity)
	if target_component:
		#target_component.targetable_item.mouse_filter = Control.MOUSE_FILTER_PASS
		_target_component_on_entity_dropped(entity,target_component)
	
	if entity is CardSleeve:
		_sleeve_on_entity_dropped(entity)
	
	entity_dropped.emit(entity)
	TargetController.clear_held()
	# refactor board
	#BoardController._on_entity_dropped(entity)

# =====================================================
# TARGET CONTROLLER SIGNAL PIPELINES
# =====================================================

#func _on_target_controller_entity_removed_from_held(entity:Control)-> void:
	#var stack_component:StackComponent = StackComponent.get_component_or_null(entity)
	#if stack_component:
		#_stack_component_on_target_controller_entity_removed_from_held(entity,stack_component)

func _on_target_controller_target_changed(_entity:Control)-> void:
	pass
	#if not entity: return
	#
	#if entity.has_meta("Sleeve"):
		#var card_sleeve:CardSleeve = entity.get_meta("Sleeve")
		#var sleeve:Sleeve = card_sleeve.sleeve
		#
		#if Input.is_action_pressed("sleeve"):
			#sleeve.scale = Vector2.ONE * 1.1
			#
			#var target_component:TargetComponent = TargetComponent.get_component_or_null(entity)
			#if target_component:
				#target_component.entity_mouse_exited.connect(func(_entity:Control)-> void:
					#sleeve.scale = Vector2.ONE
				#,4)

# =====================================================
# STACK SIGNAL PIPELINES
# =====================================================
func _on_item_added_to_entity_stack(entity:Control,item:Control)-> void:
	_target_controller_on_item_added_to_entity_stack(entity,item)
	_mixer_on_item_added_to_entity_stack(entity,item)
	
	if entity.has_meta("BoardGroup"):
		var board_component:BoardComponent =  BoardComponent.get_board_from_group_name(entity,entity.get_meta("BoardGroup"))
		board_component.add_to_board(item,false)

func _on_entity_removed_from_item_stack(entity:Control,item:Control)-> void:
	_target_controller_on_entity_removed_from_item_stack(entity,item)

func _on_previous_changed(entity:Control)-> void:
	_clicker_component_on_previous_changed(entity)
	#_ticker_component_on_previous_changed(entity)
	
	if entity is Card:
		_card_on_previous_changed(entity)

# =====================================================
# TARGET SIGNAL PIPELINES
# =====================================================
func _on_targetable_entity_primary_input_pressed(entity:Control)-> void:
	var lift_component:LiftComponent = LiftComponent.get_component_or_null(entity)
	if lift_component:
		lift_component.start_dragging()

func _on_targetable_entity_primary_input_released(_entity:Control)-> void:
	pass

func _on_targetable_entity_secondary_input_pressed(entity:Control)-> void:
	var stack_component:StackComponent = StackComponent.get_component_or_null(entity)
	if stack_component:
		var previous:Control = stack_component.previous
		if previous:
			var previous_target_component:TargetComponent = TargetComponent.get_component_or_null(previous)
			if previous_target_component:
				previous_target_component.targetable_entity_secondary_input_pressed_echo.emit(previous)
	
	var board_component:BoardComponent = BoardComponent.get_component_or_null(entity)
	if board_component:
		_board_component_on_secondary_input(entity,board_component)
	
	var clicker_component:ClickerComponent = ClickerComponent.get_component_or_null(entity)
	if clicker_component and not clicker_component.disabled:
		clicker_component.click()
	
	var ticker_component:TickerComponent = TickerComponent.get_component_or_null(entity)
	if ticker_component:
		_ticker_component_on_any_primary_input(entity,ticker_component)
	
	var speech_component:SpeechComponent = SpeechComponent.get_component_or_null(entity)
	if speech_component:
		_speech_component_on_secondary_input(entity,speech_component)



func _on_targetable_entity_secondary_input_pressed_echo(entity:Control)-> void:

	var clicker_component:ClickerComponent = ClickerComponent.get_component_or_null(entity)
	if clicker_component and not Input.is_action_pressed("select") and not clicker_component.disabled:
		clicker_component.click()
	
	var ticker_component:TickerComponent = TickerComponent.get_component_or_null(entity)
	if ticker_component and Input.is_action_pressed("select") and Input.is_action_just_pressed("secondary_input"):
		_ticker_component_on_any_primary_input(entity,ticker_component)
	
	var stack_component:StackComponent = StackComponent.get_component_or_null(entity)
	if stack_component:
		var previous:Control = stack_component.previous
		if previous:
			var previous_target_component:TargetComponent = TargetComponent.get_component_or_null(previous)
			if previous_target_component:
				previous_target_component.targetable_entity_secondary_input_pressed_echo.emit(previous)


func _on_targetable_entity_sleeve_pressed(entity:Control)-> void:
	if entity.has_meta("Sleeve") and entity is Card:
		var sleeve:CardSleeve = entity.get_meta("Sleeve")
		sleeve.unsleeve_card(entity)
	
		var target_component:TargetComponent = TargetComponent.get_component_or_null(sleeve)
		if target_component:
			#target_component.remove_target_lock("Sleeve")
			target_component.targetable_entity_primary_input_pressed.emit(target_component.entity)
			TargetController.primary_input_released.connect(
				target_component.targetable_entity_primary_input_released.emit.bind(target_component.entity)
			,4)
	
# =====================================================
# BOARD SIGNAL PIPELINES
# =====================================================

func _on_board_toggled(entity:Control, board_open:bool)-> void:
	var lift_component:LiftComponent = LiftComponent.get_component_or_null(entity)
	if lift_component:
		_lift_component_on_board_toggled(lift_component,board_open)
	
	var target_component:TargetComponent = TargetComponent.get_component_or_null(entity)
	if target_component:
		_target_component_on_board_toggled(target_component,board_open)
	
	if entity is Card:
		_card_on_board_toggled(entity,board_open)

func _on_board_failed_remove_item_from_board(item:Control, _entity:Control)-> void:
	# If you try to move a locked card on a board that is undone.
	if item in TargetController.held_entities:
		item.hide()
	
	var stack_component:StackComponent = StackComponent.get_component_or_null(item)
	if stack_component:
		stack_component.pop_self()
		
	var lift_component:LiftComponent = LiftComponent.get_component_or_null(item)
	if lift_component:
		lift_component.stop_dragging()
		item.z_index = 0
		item.move_to_front()
		TargetController.remove_held(item)


func _on_board_closing(_entity:Control)-> void:
	_target_controller_on_board_closing()

func _on_entity_added_to_board(entity:Control,board_component:BoardComponent)->void:
	var stack_component:StackComponent = StackComponent.get_component_or_null(entity)
	if stack_component:
		_stack_component_on_entity_added_to_board(entity,board_component,stack_component)
	
	if entity is Card:
		if not entity.card_changed_types.is_connected(_on_card_changed_types):
			entity.card_changed_types.connect(_on_card_changed_types)

func _on_entity_removed_from_board(_entity:Control,_board_component:BoardComponent)->void:
	pass

# =====================================================
# CONVEYOR SIGNAL PIPELINES
# =====================================================

# =====================================================
# TICKER SIGNAL PIPELINES
# =====================================================
func _on_disabled_changed(entity:Control, value:bool)-> void:
	_card_on_disabled_changed(entity, value)

func _on_power_toggled(entity:Control, value:bool)-> void:
	_card_on_power_toggled(entity, value)

func _on_card_changed_types(old_card:Card,new_card:Card)-> void:
	# Board Component
	if old_card.has_meta("BoardGroup"):
		var board_component:BoardComponent = BoardComponent.get_board_from_group_name(old_card,old_card.get_meta("BoardGroup"))
		if board_component:
			board_component.add_to_board.call_deferred(new_card,false)

# =====================================================
# Helper Functions
# =====================================================
static func get_top_board(game_node:Node)-> Node:
	var nodes: Array[Node] = game_node.get_tree().get_nodes_in_group("boards")
	var boards: Array[Control] = []
	for node:Node in nodes:
		var board_componet:BoardComponent = BoardComponent.get_component_or_null(node)
		if board_componet and board_componet.open:
			boards.append(node)
	return TargetController.get_top_drawn_node(boards)
