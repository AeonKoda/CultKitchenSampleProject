class_name Shop extends CanvasLayer

signal sale(active:bool)
signal buy_request(card:Card)

enum MENUS {
	CARD,
	RECIPE,
	BLACK_MARKET
}

var first_open:bool = true
var menu:MENUS = MENUS.CARD
var gold:int = 0

var open:bool = false
var background_has_mouse:bool = false

@export var cardpack_scene:PackedScene
@export var normal_pig:Resource# = preload("res://art/piggy_bank_icon.png")
@export var occult_pig:Resource# = preload("res://art/occult_piggy_bank_icon.png")

@export var shop_cards:Array[CardResource]
@export var shop_recipes:Array[CardResource]
@export var market_cards:Array[CardResource]
@export var coupons:int:
	set(value):
		coupons = value
		if coupons != value:
			if value > 0:
				sale_panel.show()
				sale.emit(true)
				if value == 1:
					sale_label.text = "(1 ITEM ONLY)"
				else:
					sale_label.text = "(%s ITEMS)"%value
			else:
				sale.emit(false)
				sale_panel.hide()

@onready var shop_table: Panel = %ShopTable
@onready var background: Button = %Background
@onready var pack_board: FlowContainer = %PackBoard
@onready var shop_panel: Panel = %ShopPanel
@onready var piggy_bank: TextureRect = %PiggyBank
@onready var gold_label: Label = %GoldLabel

@onready var card_button: Button = %CardButton
@onready var recipe_button: Button = %RecipeButton
@onready var black_market_button: Button = %BlackMarketButton
@onready var sale_panel: Panel = %SalePanel
@onready var sale_label: Label = %SaleLabel




@onready var first_time_panel: ColorRect = %FirstTimePanel


func _ready() -> void:
	# hides the welcome screen if first open is false
	if not first_open:
		_on_first_time_button_pressed()
	
	load_board.call_deferred(shop_cards)
	
	card_button.pressed.connect(_on_card_button_pressed)
	recipe_button.pressed.connect(_on_recipe_button_pressed)
	black_market_button.pressed.connect(_on_black_market_button_pressed)
	
	background.pressed.connect(_on_background_pressed)
	background.mouse_entered.connect(_background_mouse_entered)
	background.mouse_exited.connect(_background_mouse_exited)

func open_shop()-> void:
	Global.pause()
	open = true
	menu = MENUS.CARD
	change_theme(false)
	show()
	load_board(shop_cards)
	sort()
	pack_board.queue_sort()

func close_shop()-> void:
	Global.unpause()
	open = false
	hide()

func set_gold(value:int)-> void:
	gold_label.text = str(value,"G")
	gold = value


func sort()-> void:
	for card_pack:CardPack in pack_board.get_children():
		card_pack.card.position = Vector2.ZERO

func _on_background_pressed()-> void:
	close_shop()


func _background_mouse_entered()-> void:
	background_has_mouse = true


func _background_mouse_exited()-> void:
	background_has_mouse = false


func load_board(inventory:Array) ->void:
	for child:CardPack in pack_board.get_children():
		child.queue_free()
		
	for card_resource:CardResource in inventory:
		var new_pack:CardPack =cardpack_scene.instantiate()
		new_pack.card_resource = card_resource
		pack_board.add_child(new_pack)
		new_pack.card_pack_dropped.connect(_on_card_pack_dropped.bind(new_pack))
	if coupons> 0:
		sale.emit(true)
	pack_board.queue_sort()


func _on_card_pack_dropped(card_pack:CardPack)-> void:
	if background_has_mouse:
		buy_request.emit(card_pack.card)
	sort()


func change_theme(toggle:bool) ->void:
	if toggle:
		shop_panel.theme_type_variation = "Occult_Panel"
		shop_table.theme_type_variation = "Occult_Panel"
		card_button.theme_type_variation = "Occult"
		recipe_button.theme_type_variation = "Occult"
	else:
		shop_panel.theme_type_variation = "Shop_Panel"
		shop_table.theme_type_variation = ""
		card_button.theme_type_variation = ""
		recipe_button.theme_type_variation = ""


func add_coupon()->void:
	coupons += 1


func play_not_enough_gold()-> void:
	gold_label.text  = "OINK!"
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Following code is based on the TWEEN ANIMATION PLUGIN by EVILBUNNYMAN obtained
	# on 5/17/25. As such it will be subject to the MIT License
	
	# MIT License
	
	# Copyright (c) 2025 EvilBunnyMan
	
	# Permission is hereby granted, free of charge, to any person obtaining a copy
	# of this software and associated documentation files (the "Software"), to deal
	# in the Software without restriction, including without limitation the rights
	# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	# copies of the Software, and to permit persons to whom the Software is
	# furnished to do so, subject to the following conditions:
	
	# The above copyright notice and this permission notice shall be included in all
	# copies or substantial portions of the Software.
	
	# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	# SOFTWARE.
	
	var amount: float = 5.0
	var shakes: int = 7
	var duration: float = 0.4
	var node:CanvasItem = piggy_bank# $ShopBox/ShopPanel/PiggyBank/Panel
	var original_pos:Vector2 = node.position
	var tween:Tween = create_tween()

	
	for i:int in range(shakes):
		var shake_offset:Vector2 = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		tween.tween_property(node, "position", original_pos + shake_offset, duration / (shakes * 2))
		tween.tween_property(node, "position", original_pos, duration / (shakes * 2))
	
	# End of code subject to the MIT License and copy right.
	
	tween.finished.connect(func()-> void:
		gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		set_gold(gold)
		,4)


func _on_black_market_button_pressed() -> void:
	if menu != MENUS.BLACK_MARKET:
		menu = MENUS.BLACK_MARKET
		
		change_theme(true)
		piggy_bank.texture.region = Rect2(70,0,70,0)
		#piggy_bank.texture = occult_pig
		load_board(market_cards)


func _on_recipe_button_pressed() -> void:
	if menu != MENUS.RECIPE:
		menu = MENUS.RECIPE
		
		change_theme(false)
		piggy_bank.texture.region = Rect2(0,0,70,0)
		load_board(shop_recipes)


func _on_card_button_pressed() -> void:
	if menu != MENUS.CARD:
		menu = MENUS.CARD
		piggy_bank.texture.region = Rect2(0,0,70,0)
		#piggy_bank.texture = normal_pig
		change_theme(false)
		load_board(shop_cards)



func _on_first_time_button_pressed() -> void:
	first_time_panel.queue_free()
