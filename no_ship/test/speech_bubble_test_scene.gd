extends Control

@onready var button: Button = %Button
@onready var speech_component: SpeechComponent = %SpeechComponent
@onready var line_edit: TextEdit = %LineEdit
@onready var check_button: CheckButton = $CheckButton

func _on_button_button_down() -> void:
	if speech_component.get_speech_state() == SpeechComponent.SPEECH_STATES.SPEAKING:
		speech_component.bubble_input()
	else:
		speech_component.speak(line_edit.text,check_button.button_pressed)


func _on_button_2_button_down() -> void:
	if speech_component.get_speech_state() == SpeechComponent.SPEECH_STATES.OFF:
		speech_component.send_notice(line_edit.text)
