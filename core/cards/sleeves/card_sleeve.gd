class_name CardSleeve extends Card
static func get_type_id()-> StringName:return &"CardSleeve"

signal card_unsleeved(card:Card)

var sleeved_card:Card
var sleeve_resource:SleeveResource
var sleeve:Sleeve

@export var removable:bool = true

func _ready() -> void:
	super()
	
	var stack_component:StackComponent = StackComponent.get_component_or_null(self)
	if stack_component:
		stack_component.release()
	
	texture.self_modulate.a = 0.2
	sleeve_resource = card_resource.extended_class_resource
	add_sleeve(sleeve_resource.sleeve_scene.instantiate())
	
	#card_resource.extended_class_resource.setup_script.setup(self)
	

func add_sleeve(node:Control)-> void:
	if animation_container:
		animation_container.add_child(node)
	else:
		add_child(node)
	sleeve = node
	sleeve.setup(self,sleeve_resource)
	#set_meta("Sleeve",node)

func sleeve_card(card:Card)-> bool:
	if card is CardSleeve or sleeved_card:return false
	if card.has_meta("Sleeve"):return false
	card.set_meta("Sleeve",self)
	
	sleeved_card = card
	sleeve.sleeved(card)
	sleeve.reparent(card.animation_container,false)
	
	card.card_queued_free.connect(unsleeve_card,4)

	get_parent().remove_child.call_deferred(self)
	return true

func unsleeve_card(card:Card)-> void:
	if sleeved_card != card:return
	if not removable:return
	
	if card.card_queued_free.is_connected(unsleeve_card):
		card.card_queued_free.disconnect(unsleeve_card)
	
	global_position = card.global_position
	card.get_parent().add_child(self)
	
	
	sleeve.reparent(animation_container)
	
	sleeve.unsleeved()
	card.remove_meta("Sleeve")
	#poof()
	sleeved_card = null
	card_unsleeved.emit(card)
