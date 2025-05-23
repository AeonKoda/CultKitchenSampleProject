extends Script

static func click(card:Card,card_resource:CardResource = card.card_resource) ->void:
	
	var speech_component:SpeechComponent = SpeechComponent.get_component_or_null(card)
	if speech_component:
		speech_component.speak("[shake rate=6.0 level=8 connected=1]Hungry...[/shake]")
	
	if card.card_resource.one_shot:
		Global.game.board.remove_card_from_chain(card)
		card.queue_release()
