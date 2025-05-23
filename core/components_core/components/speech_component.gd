class_name SpeechComponent extends Component
const TYPE_ID:StringName = &"SpeechComponent"

signal state_changed(state:SPEECH_STATES)

enum SPEECH_STATES {
	SHOWING,
	SPEAKING,
	AWAITING_INPUT,
	AWAITING_OPEN,
	HIDING,
	OFF,
}

var _speech_state:SPEECH_STATES = SPEECH_STATES.OFF

var speech_bubble:SpeechBubble

var notice_text:String = ""

var speech_tween:Tween
var speech_chr_per_sec:float = 0.08 # in character per second

var animation_tween:Tween

var sped_up:bool = false

func _ready() -> void:
	super()
	if not speech_bubble:
		speech_bubble = Global.speech_bubble_scene.instantiate()
	
	# [to-do] put this in the coordinator
	var animation_container:AnimationContainer =  AnimationContainer.get_component_or_null(entity)
	if animation_container:
		animation_container.add_child(speech_bubble)
	else:
		entity.add_child.call_deferred(speech_bubble)
	
	speech_bubble.gui_input.connect(_bubble_gui_input)

func _bubble_gui_input(event:InputEvent)-> void:
	if event.is_action_pressed("secondary_input"):
		bubble_input()

func bubble_input()-> void:
	if get_speech_state() == SPEECH_STATES.AWAITING_INPUT:
		hide_bubble()
	elif get_speech_state() == SPEECH_STATES.AWAITING_OPEN:
		speech_bubble.exclamation.hide()
		speak(notice_text,true)
		notice_text = ""
	elif get_speech_state() == SPEECH_STATES.SPEAKING:
		#speech_tween.set_speed_scale(5.0)
		sped_up = true
		speech_tween.custom_step(90000)
		

func speak(text:String,await_input:bool = false)-> void:
	#if get_speech_state() == SPEECH_STATES.SPEAKING:
		#
		## Queues speech for when current is finished
		#await state_changed
		#if get_speech_state() != SPEECH_STATES.AWAITING_INPUT: return
		
	if  get_speech_state() != SPEECH_STATES.AWAITING_INPUT:
		show_bubble()
	
		# Allow for bubble to show
		await state_changed
		if get_speech_state() != SPEECH_STATES.AWAITING_INPUT: return
	
	# Set starting values
	sped_up = false
	var text_label:RichTextLabel = speech_bubble.rich_text_label
	text_label.text = text
	text_label.visible_characters = 0
	
	var chr_count:int = text_label.get_total_character_count()
	var tween_time:float = float(chr_count) * speech_chr_per_sec
	
	# Setup tween
	if speech_tween:
		speech_tween.kill()
		#speech_tween.free()

	speech_tween = create_tween()
	speech_tween.tween_property(text_label,"visible_characters",chr_count,tween_time)
	set_speech_state(SPEECH_STATES.SPEAKING)
	
	speech_tween.finished.connect(finish_speech.bind(await_input))

func finish_speech(await_input:bool)-> void:
	if await_input or sped_up:
		set_speech_state(SPEECH_STATES.AWAITING_INPUT)
	else:
		hide_bubble(1.0)

func send_notice(text:String)-> void:
	# Manage states
	var state:SPEECH_STATES = get_speech_state()
	if not(state == SPEECH_STATES.OFF or state == SPEECH_STATES.HIDING):
		return
	set_speech_state(SPEECH_STATES.SHOWING)
	
	notice_text = text
	
	# Set starting values
	speech_bubble.rich_text_label.text = ""
	speech_bubble.scale = Vector2.ONE * 0.1
	speech_bubble.self_modulate = Color.WHITE
	speech_bubble.exclamation.show()
	speech_bubble.show()
	
	# Setup tween
	if animation_tween:
		animation_tween.kill()
		#animation_tween.free()
		
	animation_tween = create_tween()
	animation_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	animation_tween.tween_property(speech_bubble,"scale",Vector2.ONE*0.5,0.4)
	
	animation_tween.finished.connect(set_speech_state.bind(SPEECH_STATES.AWAITING_OPEN),4)

func show_bubble()-> void:
	# Manage states
	var state:SPEECH_STATES = get_speech_state()
	if state == SPEECH_STATES.SPEAKING or state == SPEECH_STATES.AWAITING_INPUT or state == SPEECH_STATES.SHOWING:
		return
	set_speech_state(SPEECH_STATES.SHOWING)
	
	# Set starting values
	speech_bubble.rich_text_label.text = ""
	speech_bubble.scale = Vector2.ONE * 0.1
	speech_bubble.self_modulate = Color.WHITE
	speech_bubble.show()
	
	# Setup tween
	if animation_tween:
		animation_tween.kill()
		#animation_tween.free()
		
	animation_tween = create_tween()
	animation_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	animation_tween.tween_property(speech_bubble,"scale",Vector2.ONE,0.4)
	
	animation_tween.finished.connect(set_speech_state.bind(SPEECH_STATES.AWAITING_INPUT),4)

func hide_bubble(delay:float  = 0)-> void:
	# Manage states
	var state:SPEECH_STATES = get_speech_state()
	if state == SPEECH_STATES.HIDING:
		return
	set_speech_state(SPEECH_STATES.HIDING)
	
	# Setup tween
	if animation_tween:
		animation_tween.kill()
		#animation_tween.free()
	
	animation_tween = create_tween()
	
	if delay > 0:
		animation_tween.tween_interval(delay)
	
	animation_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	animation_tween.tween_property(speech_bubble,"scale",Vector2.ONE*0.01,0.6)
	animation_tween.parallel().tween_property(speech_bubble.rich_text_label,"text","",0)
	#animation_tween.parallel().tween_property(speech_bubble,"self_modulate",Color.TRANSPARENT,0.6)
	animation_tween.finished.connect(func()-> void: 
		speech_bubble.hide()
		set_speech_state(SPEECH_STATES.OFF)
		,4)
	

func set_speech_state(state:SPEECH_STATES)->void:
	if state != SPEECH_STATES.AWAITING_INPUT and _speech_state == SPEECH_STATES.AWAITING_INPUT:
		speech_bubble.input_waiting.hide()
	if not (state == SPEECH_STATES.AWAITING_OPEN or state == SPEECH_STATES.SHOWING):
		speech_bubble.exclamation.hide()
	
	match state:
		SPEECH_STATES.SHOWING:
			_speech_state = state
		SPEECH_STATES.SPEAKING:
			_speech_state = state
		SPEECH_STATES.AWAITING_INPUT:
			_speech_state = state
			speech_bubble.input_waiting.show()
		SPEECH_STATES.AWAITING_OPEN:
			_speech_state = state
		SPEECH_STATES.HIDING:
			_speech_state = state
		SPEECH_STATES.OFF:
			_speech_state = state
	
	state_changed.emit(state)

func get_speech_state()->SPEECH_STATES:
	return _speech_state

static func get_component_or_null(s_entity:Control,_name:StringName="")-> SpeechComponent:
	if not s_entity:
		return null
	
	if s_entity.has_meta(TYPE_ID):
		return s_entity.get_meta(TYPE_ID)
	return null
