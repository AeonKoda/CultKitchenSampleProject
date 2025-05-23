class_name Pig extends TextureButton

signal request_sell(cards:Array)

var has_mouse:bool = false

@onready var sell_price: Panel = %SellPrice
@onready var price_preview: Label = %PricePreview

func _ready() -> void:
	mouse_entered.connect(mouse_in)
	mouse_exited.connect(mouse_out)

func _input(event: InputEvent) -> void:
	if event.is_action_released("primary_input") and has_mouse:
		drop_card(TargetController.held_entities)

func mouse_in()->void:
	has_mouse = true
	var cards:Array[Control] = TargetController.held_entities
	if cards.is_empty():
		price_preview.text = str("OINK!")
		return
	
	
	var price:int = get_value(cards)
	if price == -1:
		price_preview.text = str("OINK!")
	else:
		price_preview.text = str(price,"G")
	sell_price.show()

func mouse_out()->void:
	has_mouse = false
	sell_price.hide()

func get_value(cards:Array[Control]) ->int:
	var value:float = -1
	
	for card:Control in cards:
		if card is not Card: pass
		
		#if card.card_resource.is_storage and card.current_storage > 0:
			#if value == -1:
				#value = 0
			#value += card.stored_card.card_resource.value * card.current_storage
		if card.card_resource.sellable and not card.card_resource.occult:
			if value == -1:
				value = 0
			value += card.card_resource.value
			
	if value > -1:
		return ceili(value/2)
	else:
		return -1

func drop_card(cards:Array)-> void:
	request_sell.emit(cards)
	mouse_out()
	#sell_cards(card)
