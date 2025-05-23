class_name Game extends Node2D

signal gold_changed(value:int)

const INNER_POSITION:Vector2 = Vector2(50,50)
var screen_size:Vector2 = Vector2(1280,720)
var inner_size:Vector2 = screen_size - INNER_POSITION*2
@export var guide_1:Card
@export var family_farm:Card
@export var farm_starting_cards:Array[Card]
@export var farm_stack_cards:Array[Card]
@export var kitchen_starting_cards:Array[Card]


@export var gold:int = 20000:
	set(value):
		gold = value
		gold_changed.emit(value)
@export var show_tutorial:bool = true
@export var show_input_help:bool = true
@export var grid_snap_always_on:bool = false

@export_group("Scene Variables")
@export var shop:Shop
@export var debug:DebugHUD
@export var hud:HUD

@export_file var sleeve_upgrade_path:String

var sleeve_upgrade_stats:Dictionary
var altar_upgrades:Dictionary

# 7,9,14,18,21,42 recomended sizes
var grid_size:int = 18
var in_tutorial:bool = true

var farm_board_component:BoardComponent

var active_boards:Array[BoardComponent] = []

@onready var board: Node2D = %Board
@onready var grid_overlay: GridOverlay = %GridOverlay

#ready
func _ready() -> void:
	#Setup for Global
	Global.game = self #Should have a game manager to include main menu etc at bootup.
	Global.grid_snap_always_on = grid_snap_always_on
	
	#Setup UI
	shop.close_shop()
	grid_overlay.grid_size = grid_size
	shop.set_gold(gold)
	hud.set_gold(gold)
	
	# setup boards
	for entity:Control in get_tree().get_nodes_in_group("boards"):
		var board_component:BoardComponent = BoardComponent.get_component_or_null(entity)
		if board_component:
			board_component.board_toggled.connect(_on_board_toggled)
	
	ComponentEventCoordinator.component_added.connect(func(compoent:Component)-> void:
		if compoent is BoardComponent:
			compoent.board_toggled.connect(_on_board_toggled)
		)
	
	# Setup Starting Board
	setup_starting_board()
	
	# connect signals
	connect_signals()

	sleeve_upgrade_stats = load_json(sleeve_upgrade_path)
	
	Global.game_ready.emit()
	
	if not show_tutorial:
		await  get_tree().process_frame
		_on_debug_skip_tutorial.call_deferred()


func _on_shop_button_pressed()-> void:
	if not shop.open:
		shop.open_shop()
	else:
		shop.close_shop()


func _on_debug_skip_tutorial()-> void:
	if in_tutorial:
		debug.tutorial_button.hide() # [debug code]
		for node:Node in board.get_children():
			if node is Card and node not in farm_starting_cards:
				if node == family_farm: continue
				if node.has_meta("BoardGroup"):continue
				node.queue_release()
		end_tutorial()


func _on_shop_buy_request(card:Card)-> void:
	var card_resource:CardResource = card.card_resource
	var new_card:Card = Global.create_card(card.card_resource)
	new_card.created_from_mix = true # for the sound effect
	var price:int = floori(card_resource.value)
	
	
	if gold >= price:
		gold -= price
		
		new_card.global_position = card.global_position
		
		board.add_child(new_card)
		var top_board:Card = ComponentEventCoordinatorSingleton.get_top_board(board)
		if top_board:
			var board_component:BoardComponent = BoardComponent.get_component_or_null(top_board)
			if board_component:
				board_component.add_to_board(new_card,false)
	else:
		shop.play_not_enough_gold()


func _on_hud_pig_request_sell(cards:Array)-> void:
	var value:float = 0
	var failed_stack_head:Card = null
	var fraction_value:int = 2
	var sell_time:float = 0.2/cards.size()*5
	
	for card:Control in cards.duplicate():
		var stack_component:StackComponent = StackComponent.get_component_or_null(card)
		
		if card is not Card:pass

		if card.card_resource.sellable and not card.card_resource.occult:
			value += card.card_resource.value
			card.queue_release()
			var poof:Node = card.poof()
			poof.reparent(hud.pig)
		else:
			stack_component.pop_self()
			if failed_stack_head:
				var failed_stack_component:StackComponent = StackComponent.get_component_or_null(failed_stack_head)
				failed_stack_component.append(card)
			else:
				failed_stack_head = card
		await  get_tree().create_timer(sell_time).timeout
		
	gold += ceili(value/fraction_value)

func _on_board_button_pressed(index:int)-> void:
	if not active_boards.is_empty():
		var boards:Array[BoardComponent] = active_boards.duplicate()
		for i:int in boards.size():
			var i_r:int = boards.size() - (i+1)
			if i_r <= index: return
			
			var board_component:BoardComponent = active_boards[i_r]
			board_component.toggle_board()
			

func _on_board_toggled(entity:Control,on:bool)-> void:
	var board_component:BoardComponent = BoardComponent.get_component_or_null(entity)
	if board_component:
		if on:
			active_boards.append(board_component)
			if entity is Card:
				var card_resource:CardResource = entity.card_resource
				var board_name:String = card_resource.card_name.replace("_"," ").capitalize()
				var board_color:Color = card_resource.color
				var board_font_color:Color = card_resource.text_color
				
				hud.add_board_button(board_name,board_color,board_font_color)
		else:
			active_boards.erase(board_component)
			hud.reduce_board_buttons_to_size(active_boards.size())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("board_back"):
		if not active_boards.is_empty():
			active_boards[-1].toggle_board()
	if event.is_action_pressed("board_forward"):
		if not active_boards.is_empty():
			var active_board_component:BoardComponent = active_boards[-1]
			if active_board_component.sub_boards.size() == 1:
				active_board_component.sub_boards[0].toggle_board()


func end_tutorial()-> void:
	var family_board:BoardComponent = BoardComponent.get_component_or_null(Global.game.family_farm)
	family_board.locked = false
	Global.game.family_farm.show()
	family_board.toggle_board()
	family_board.locked = true
	Global.game.family_farm.poof()
	
	in_tutorial = false



func setup_starting_board()-> void:
	var guide_ticker:TickerComponent = TickerComponent.get_component_or_null(guide_1)
	if guide_ticker:
		guide_ticker.set_invisible(true)
		guide_ticker.tick_up()
	
	farm_board_component = BoardComponent.get_component_or_null(family_farm)
	farm_board_component.toggle_board()
	
	
	farm_starting_cards[0].global_position = Vector2(Global.VIEWPORT_SIZE.x-72-96,27*inner_size.y/32)
	kitchen_starting_cards[0].global_position = Vector2(Global.VIEWPORT_SIZE.x-72-96,27*inner_size.y/32)
	var kitchen_board_component:BoardComponent = BoardComponent.get_component_or_null(farm_starting_cards[0])
	for card:Card in kitchen_starting_cards:
		kitchen_board_component.add_to_board(card,false)
	
	for card:Card in farm_starting_cards:
		card.show() # ensure cards are visible on start if hidden in editor
		farm_board_component.add_to_board(card,false)
	
	var stack_component:StackComponent = StackComponent.get_component_or_null(farm_stack_cards[0])
	farm_stack_cards[0].show()
	farm_stack_cards.pop_front()
	for card:Card in farm_stack_cards:
		card.show()
		stack_component.append(card)
	
	farm_board_component.toggle_board()
	farm_board_component.locked = true
	family_farm.hide()

func connect_signals()-> void:
	gold_changed.connect(shop.set_gold)
	gold_changed.connect(hud.set_gold)
	
	hud.shop_button_pressed.connect(_on_shop_button_pressed)
	hud.pig.request_sell.connect(_on_hud_pig_request_sell)
	hud.board_button_pressed.connect(_on_board_button_pressed)
	debug.skip_tutorial_pressed.connect(_on_debug_skip_tutorial)
	shop.buy_request.connect(_on_shop_buy_request)

func load_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.ModeFlags.READ)
	var err: Error = FileAccess.get_open_error()
	if err != OK:
		push_error("Failed to open file '%s' (Error %d)" % [path, err])
		return {}
	var text: String = file.get_as_text()
	file.close()

	var parse_result: Variant = JSON.parse_string(text)
	return parse_result
