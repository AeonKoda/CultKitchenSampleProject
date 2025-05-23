extends Script

static func tick(card:Card) ->void:
	var speech_component:SpeechComponent = SpeechComponent.get_component_or_null(card)
	if speech_component:
		speech_component.speak("Turn on GUIDE 4 then place me on top.")
