class_name CardPack extends Control

signal buy_request
signal card_pack_dropped

var target:CardPack
var price:int

var sale:bool = false:
	set(value):
		if sale != value:
			sale = value
			
			if value:
				price = ceili(price/2.0)
			else:
				price = ceili(card_resource.value)
				
var sale_color:Color = Color("a40000")

@export var card_resource:CardResource
@export_group("Variables")
@export var card: Card
@export var lift_component: LiftComponent
@onready var gold_label: Label = %GoldLabel
@onready var texture: NinePatchRect = %Texture



func _enter_tree() -> void:
	card.card_resource = card_resource
	card.real_card = false


func _ready() -> void:
	price = floori(card_resource.value)
	gold_label.text = str(price,"g")
	
	#if card.item_rect_changed.is_connected(card._on_item_rect_changed):
		#card.item_rect_changed.disconnect(card._on_item_rect_changed)
	card.can_grid_snap = false
	
	lift_component.entity_lifted.connect(_on_card_pack_lifted.unbind(1))
	lift_component.entity_dropped.connect(_on_card_pack_dropped.unbind(1))


func _on_card_pack_lifted()-> void:
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_card_pack_dropped()-> void:
	texture.mouse_filter = Control.MOUSE_FILTER_PASS
	card_pack_dropped.emit()


#func toggle_sale(active:bool)-> void:
	#if sale != active:
		#sale = active
		#label.text = str(price,"g")
		#if active:
			#label.add_theme_color_override("font_color",sale_color)
		#else:
			#label.add_theme_color_override("font_color",Color.BLACK)
