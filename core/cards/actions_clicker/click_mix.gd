extends Script

static func click(card:Card,card_resource:CardResource = card.card_resource) ->void:
	var stack_component:StackComponent = StackComponent.get_component_or_null(card)
	
	var object_slice:Array[Control] = stack_component.get_slice(0,RecipeBook.MAX_COMBINATION_SIZE)
	var resource_slice:Array = object_slice.map(func(obj:Control)->CardResource:return obj.get("card_resource"))
	var result:Dictionary = RecipeBook.check_combine(resource_slice,true)

	if result:
		var bottom:Control = stack_component.get_bottom()
		var bottom_stack_component:StackComponent = StackComponent.get_component_or_null(bottom)
		var reagents:Array = result["reagents"].map(func(index:int)->Control:return object_slice[index])
		var new_card:Card = Global.create_card(result["resource"])
		new_card.created_from_mix = true
		card.get_parent().add_child(new_card)
		new_card.position = stack_component.get_top().position + Vector2(0,StackComponent.STACK_OFFSET_Y)*3
		
		reagents.pop_front() # removes the tool
		
		if reagents.has(bottom):
			bottom_stack_component = StackComponent.get_component_or_null(reagents[-1])
			bottom = bottom_stack_component.next
		for reagent_card:Card in reagents:
			var reagent_stack_component:StackComponent = StackComponent.get_component_or_null(reagent_card)
			reagent_stack_component.pop_self()
			reagent_card.queue_release()
		
		if bottom:
			bottom_stack_component.append(new_card)
		else:
			new_card.position  = reagents[0].position
		
		
	if card.card_resource.one_shot and result.has("resource"):
		card.board.remove_card_from_chain(card)
		card.queue_release()
