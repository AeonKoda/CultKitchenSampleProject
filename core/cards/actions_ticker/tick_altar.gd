extends Script

static func tick(card:Card) ->void:
	var pile:Array = card.head.stack.get_pile(card)
	
	for offering:Card in pile:
		if offering.card_resource.meal:
			card.head.stack.lift_from_stack(offering)
			offering.queue_release()
			Global.game.tribute += offering.card_resource.value
	
	
	if card.card_resource.one_shot:
		var old_head:Card = card.head
		
		card.head.stack.pull_card(card)
		old_head.stack.stack()
		card.queue_release()
