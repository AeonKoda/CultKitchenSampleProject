extends Script

static func click(card:Card,card_resource:Resource = card.card_resource) ->void:
	var stack_component:StackComponent = StackComponent.get_component_or_null(card)
	
	if not card_resource.spawn_cards.is_empty():
		var new_card:Card
		var new_resource:CardResource
		
		for spawn:CardResource in card_resource.spawn_cards:
			new_resource = spawn
			if card_resource.card_name in Global.land_cards:
				var previous_card:Card = stack_component.previous if stack_component and stack_component.previous is Card else null
				if previous_card:
					if previous_card.card_resource.card_name in Global.crop_cards:
						new_resource = previous_card.card_resource
			
			new_card = Global.create_card(new_resource)
			card.get_parent().add_child(new_card)
			new_card.position = card.position #card.get_top().position + Global.game.board.CREATE_CARD_OFFSET
			
			if stack_component:
				stack_component.append(new_card)

	if not card_resource.spawn_recipes.is_empty():
		var new_recipe:Card
		
		for recipe_resource:CardResource in card_resource.spawn_recipes:
			new_recipe = Global.create_recipe(recipe_resource)
			
			card.get_parent().add_child(new_recipe)
			new_recipe.position = card.position #card.get_top().position + Global.game.board.CREATE_CARD_OFFSET
			
			if stack_component:
				stack_component.append(new_recipe)
			
	if not card_resource.spawn_letters.is_empty():
		var new_letter:CardLetter
		
		for letter_resource:LetterResource in card_resource.spawn_letters:
			new_letter = Global.create_letter(letter_resource)
			
			card.get_parent().add_child(new_letter)
			new_letter.position = card.position
			
			if stack_component:
				stack_component.append(new_letter)
		
	#if card.card_resource.card_name == "GUIDE_1":
		#card.clicker.progress.queue_free()
		#card.clicker.queue_free()
		#card.title_label.text = "[center]GUIDE 1"
		
	if card.card_resource.one_shot:
		card.queue_release()
