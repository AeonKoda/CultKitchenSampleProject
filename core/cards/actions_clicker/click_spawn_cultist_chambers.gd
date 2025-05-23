extends Script

static func click(card:Card,card_resource:Resource = card.card_resource) ->void:
	var stack_component:StackComponent
	var altar:Card
	
	if not card_resource.spawn_cards.is_empty():
		var new_card:Card
		var new_resource:CardResource
		var chambers:Card
		
		for spawn:CardResource in card_resource.spawn_cards:
			new_resource = spawn
			
			new_card = Global.create_card(new_resource)
			card.get_parent().add_child(new_card)
			new_card.position = card.position #card.get_top().position + Global.game.board.CREATE_CARD_OFFSET
			
			if spawn == card_resource.spawn_cards[0]:
				chambers = new_card
				altar = Global.create_card(Global.altar_resource)
				altar.global_position = card.get_viewport_rect().size/2 - card.pivot_offset
				card.get_parent().add_child(altar)
				
				stack_component = StackComponent.get_component_or_null(altar)

				var board_component:BoardComponent = BoardComponent.get_component_or_null(chambers)
				if board_component:
					board_component.add_to_board(altar,false)
				
				var card_stack_component:StackComponent = StackComponent.get_component_or_null(card)
				if stack_component:
					card_stack_component.append(new_card)
				
			elif stack_component:
				stack_component.append(new_card)

	if not card_resource.spawn_recipes.is_empty():
		var new_recipe:Card
		
		for recipe_resource:CardResource in card_resource.spawn_recipes:
			new_recipe = Global.create_recipe(recipe_resource)
			
			card.get_parent().add_child(new_recipe)
			new_recipe.position = altar.position #card.get_top().position + Global.game.board.CREATE_CARD_OFFSET
			
			if stack_component:
				stack_component.append(new_recipe)
			
	if not card_resource.spawn_letters.is_empty():
		var new_letter:CardLetter
		
		for letter_resource:LetterResource in card_resource.spawn_letters:
			new_letter = Global.create_letter(letter_resource)
			
			card.get_parent().add_child(new_letter)
			new_letter.position = altar.position
			
			if stack_component:
				stack_component.append(new_letter)
		
	if card.card_resource.one_shot:
		card.queue_release()
