extends Script

static func click(card:Card,_card_resource:CardResource = card.card_resource) ->void:
	Global.game.end_tutorial()
	card.queue_release()
