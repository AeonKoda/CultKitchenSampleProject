class_name Card extends Control
static func get_type_id()-> StringName:return &"Card"

signal input_event(event:InputEvent)
signal space(event:InputEvent)
signal card_created
signal card_changed_types
signal card_queued_free


@export var card_resource:CardResource
@export_group("Scenes")
@export var poof_effect_scene:PackedScene
@export var recipe_container_scene:PackedScene

var releasing:bool = false
var created_from_mix:bool = false
var real_card:bool = true
var board_lock:bool = false
var can_grid_snap:bool = true

@onready var card_container:MarginContainer = get_node_or_null("%CardContainer") 
@onready var texture: NinePatchRect = get_node_or_null("%Texture") 
@onready var title_label: RichTextLabel = get_node_or_null("%TitleLabel")
@onready var card_art: TextureRect = get_node_or_null("%CardArt")

@onready var phantom_card: NinePatchRect = get_node_or_null("%PhantomCard")
@onready var animation_container: AnimationContainer = get_node_or_null("%AnimationContainer")

func _ready() -> void:
	if not card_resource:
		return
	
	name = card_resource.card_name.to_camel_case().capitalize()
	# Matches class type with name. Then searches for the path and loads it.
	var change_type:Card = check_change_type() if real_card else self
	if change_type != self:
		get_parent().add_child.call_deferred(change_type)
		card_changed_types.emit.call_deferred(self,change_type)
		queue_release()
		return
	set_art()
	set_title()
	
	texture.gui_input.connect(func(event:InputEvent)->void: input_event.emit(event))
	
	if created_from_mix:
		poof()
	
	if card_resource.clicker:
		create_clicker()
	
	if card_resource.ticker:
		create_ticker()
	
	if card_resource.board:
		create_board()
	board_lock = card_resource.board_lock
	
	if card_resource.has_speech:
		create_speech_component()
	
	grid_snap()
	item_rect_changed.connect(_on_item_rect_changed)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("grid_snap"):
		grid_snap()

func _on_item_rect_changed()->void:
	if Global.grid_snap_always_on:
		grid_snap()

func check_change_type()-> Card:
	if card_resource.extended_class != CardResource.TYPES.CARD and get_type_id() != CardResource.get_type_class_name(card_resource.extended_class):
		var dict_entry:Array = ProjectSettings.get_global_class_list().filter(
			func(entry:Dictionary) ->bool:return entry["class"] == CardResource.get_type_class_name(card_resource.extended_class)
			)
		if not dict_entry.is_empty():
			var class_script:Script = load(dict_entry[0]["path"])
			var new_node:Card = class_script.new()
			var new_card:Card = Global.create_card(card_resource)
			new_node.card_resource = card_resource
			new_node.poof_effect_scene = poof_effect_scene
			new_node.recipe_container_scene = recipe_container_scene
			new_node.mouse_filter = mouse_filter
			new_node.created_from_mix = created_from_mix
			name = name + "Old"
			new_node.name = dict_entry[0]["class"]
			if card_resource.extended_class_resource:
				new_node.name = card_resource.extended_class_resource.resource_path.get_file().trim_suffix(".tres").to_pascal_case() + new_node.name
			new_node.global_position = global_position
			new_node.size = new_card.size
			new_node.pivot_offset = pivot_offset
			
			new_card.replace_by(new_node)
			new_card.queue_free()
			#replace_by.call_deferred(new_node)
			#queue_release.call_deferred()
			return new_node
	return self

func poof()-> PoofAnimation:
	var poof_effect:Node = poof_effect_scene.instantiate()
	if animation_container:
		animation_container.add_child(poof_effect)
	else:
		get_parent().add_child(poof_effect)
	return poof_effect

func create_clicker(resource:Resource = card_resource)-> void:
	var clicker:ClickerComponent = ClickerComponent.new(resource.progress_max_value,resource.click_action,resource)
	add_child(clicker)
	
func create_ticker(resource:Resource = card_resource)-> TickerComponent:
	var ticker:TickerComponent = TickerComponent.new(resource)
	add_child(ticker)
	return ticker

func create_board()-> void:
	var board_component:BoardComponent = BoardComponent.new()
	var indicator:Indicator = Global.card_indicator_scene.instantiate()
	add_child(board_component)
	if animation_container:
		indicator.entity = self
		animation_container.add_child(indicator)

func create_speech_component()-> SpeechComponent:
	var speech_component:SpeechComponent = SpeechComponent.new()
	add_child(speech_component)
	return speech_component

func set_title() ->void:
	var card_name:String = card_resource.card_name
	if title_label:
		title_label.text = str("[center]",card_name.replace("_"," "),"[/center]")
		title_label.add_theme_color_override("default_color",card_resource.text_color)

func set_art()-> void:
	texture.self_modulate = card_resource.color
	if phantom_card:
		phantom_card.self_modulate = card_resource.color
	if card_resource.art_texture:
		card_art.texture = card_resource.art_texture

func update_card_art(new_texture:Texture)-> void:
	card_art.texture = new_texture

func replace_node_with(new_node: Card) -> void:
	var parent:Node = get_parent()
	if parent == null:
		push_error("Cannot replace a root node.")
		return

	# Remember position in its parent
	var index:int = get_index()
	new_node.global_position = global_position
	new_node.card_resource = card_resource
	new_node.name = card_resource.card_name

	# Detach children from self and attach to new_node
	for child in get_children():
		remove_child(child)
		new_node.add_child(child)
	
	# Set variables
	new_node.texture = texture
	new_node.title_label = title_label
	new_node.card_art = card_art

	new_node.phantom_card = phantom_card
	new_node.animation_container = animation_container

	# Swap self and new_node in the parent's hierarchy
	parent.remove_child(self)
	parent.add_child(new_node)
	parent.move_child(new_node, index)

	# free it
	queue_free()

## -----------------------------------------------------
## GRID SNAP
## -----------------------------------------------------
func grid_snap() -> void:
	# Only snap bottom cards (cards with no previous card).
	var stack_component:StackComponent = StackComponent.get_component_or_null(self)
	var board_compoent:BoardComponent = BoardComponent.get_component_or_null(self)
	
	if not can_grid_snap: return
	if board_compoent and board_compoent.open: return
	
	if (stack_component and not stack_component.previous) or (not stack_component):
		# snaps to the bottom left corner, so we have to convert
		
		var grid_size:int = Global.game.grid_size if Global.game else Global.DEFAULT_GRID_SIZE
		var bottom_left:Vector2 = Vector2(global_position.x,global_position.y + size.y)
		
		var snapped_x:int = roundi(bottom_left.x / grid_size) * grid_size
		var snapped_y:int = roundi(bottom_left.y / grid_size) * grid_size
		
		var bottom_left_grid_position:Vector2 = Vector2(snapped_x, snapped_y)
		var top_left_grid_position:Vector2 = Vector2(bottom_left_grid_position.x,bottom_left_grid_position.y - size.y)
		
		global_position = top_left_grid_position
		#_reposition_stack_with_base(child, new_base)

## -----------------------------------------------------
## UTIL
## -----------------------------------------------------

func queue_release() ->void:
	hide()
	releasing = true
	card_queued_free.emit(self)
	queue_free()
