extends Script

static func tick(card:Card) ->void:
	var stack_component:StackComponent = StackComponent.get_component_or_null(card)
	var next:Card = stack_component.next if stack_component else null
	while next:
		if next.card_resource.clicker:
			var next_target_component:TargetComponent = TargetComponent.get_component_or_null(next)
			if next_target_component:
				next_target_component.targetable_entity_secondary_input_pressed.emit(next)
			#next.mouse_right.emit()
			#if not next.custom_cards.is_empty():
				#next.click_custom()
			break
		var next_stack_component:StackComponent = StackComponent.get_component_or_null(next)
		next = next_stack_component.next if next_stack_component else null
