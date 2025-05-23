extends Script

static func click(card:Card,card_resource:CardResource = card.card_resource) ->void:
	var new_resource:CardResource = card.card_resource.spawn_cards[0]
	
	var clicker:ClickerComponent  = ClickerComponent.get_component_or_null(card)
	var ticker:TickerComponent = TickerComponent.get_component_or_null(card)
	
	if clicker:
		clicker.release()
	if ticker:
		ticker.release()
	
	card.card_resource = new_resource
	card._ready()
	
	if card_resource.card_name == "LOOSE_STONE_IN_WALL":
		var altar:Card = Global.create_card(Global.altar_resource)
		altar.global_position = card.get_viewport_rect().size/2 - card.pivot_offset
		card.get_parent().add_child(altar)
		
		var board_component:BoardComponent = BoardComponent.get_component_or_null(card)
		board_component.add_to_board(altar,false)
