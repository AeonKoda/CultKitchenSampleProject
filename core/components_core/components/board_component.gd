class_name BoardComponent extends Component
const TYPE_ID:StringName = &"BoardComponent"

signal board_closing(entity:Control)
signal failed_remove_item_from_board(item:Control,entity:Control)
signal board_toggled(entity:Control, on:bool)
signal entity_removed_from_board
signal entity_added_to_board

const INNER_POSITION:Vector2 = Vector2(50,50)
var screen_size:Vector2 = Global.VIEWPORT_SIZE
var inner_size:Vector2 = screen_size - INNER_POSITION*2

var door:Card
var door_stack_component:StackComponent

var sub_boards:Array[BoardComponent] = []
var group_name:String

var open:bool = false
var locked:bool = false

var original_size:Vector2
var original_position:Vector2

var toggle_tween:Tween
var toggle_tween_time:float = 0.2

func _ready() -> void:
	entity.add_to_group("boards")
	
	if not group_name:
		group_name = str(ResourceUID.create_id())
		while group_name in get_groups():
			group_name = str(ResourceUID.create_id())
	
	create_door()
	
	super()


func _exit_tree() -> void:
	super()
	
	var items_on_board:Array = get_tree().get_nodes_in_group(group_name)
	for item:Control in items_on_board:
		remove_from_board(item)


func _on_door_input_event(event:InputEvent)-> void:
	if event.is_action_pressed("secondary_input"):
		toggle_board()


func create_door()-> void:
	if not door:
		door = Global.create_card(Global.door_resource)
		add_to_board(door,false)
		door.global_position = Vector2(inner_size.x/16,27*inner_size.y/32)
		entity.get_parent().add_child.call_deferred(door)
		door.input_event.connect(_on_door_input_event)
		door.ready.connect(func()->void:
			door_stack_component = StackComponent.get_component_or_null(door)
			,4)
		door.hide()


func toggle_board()->void:
	if locked:
		return
	
	resize_board(not open)
	if open:
		# Allows cleanup when closing board
		board_closing.emit(entity)
		await get_tree().process_frame # this is needed for cleanu p

	open = not open
	entity.move_to_front()
	toggle_on_board_entities()
	board_toggled.emit(entity,open)

func toggle_on_board_entities()-> void:
	if open:
		for group_entity:Control in get_tree().get_nodes_in_group(group_name):
			group_entity.show()
			group_entity.move_to_front()
	else:
		for group_entity:Control in get_tree().get_nodes_in_group(group_name):
			if group_entity not in TargetController.held_entities:
				group_entity.hide()

func add_to_board(item:Control,stack:bool = true)-> void:
	
	# This code checks if the item is already on a board and if so, removes it.
	# If the item cannot be removed (i.e. its locked to a board) then it returns early
	if item.has_meta("BoardGroup"):
		var item_group_name:String = item.get_meta("BoardGroup")
		if item_group_name == group_name: return
		else:
			var old_board:BoardComponent = get_board_from_group_name(item,item_group_name)
			if not old_board.remove_from_board(item): return
	#***
	
	var board_component:BoardComponent = BoardComponent.get_component_or_null(item)
	if board_component:
		sub_boards.append(board_component)
	
	if not open:
		item.hide()
	
	if stack and door:
		door_stack_component.append(item)
	
	item.add_to_group(group_name)
	item.set_meta("BoardGroup",group_name)
	#item.move_to_front() # commented this so when adding new cards in back they dont pop to front.
	# not sure why i added it in the first place
	
	entity_added_to_board.emit(item)

func remove_from_board(item:Control)-> bool:
	if item.get("board_lock"):
		failed_remove_item_from_board.emit(item,entity)
		return false
	
	var board_component:BoardComponent = BoardComponent.get_component_or_null(item)
	if board_component:
		sub_boards.erase(board_component)
	
	item.remove_from_group(group_name)
	item.remove_meta("BoardGroup")
	item.show()
	
	entity_removed_from_board.emit(item)
	return true

func resize_board(big:bool)-> void:
	if big:
		original_size = entity.custom_minimum_size
		original_position = entity.global_position
		
		# Animations dont look good yet
		
		#if toggle_tween:
			#toggle_tween.kill()
			#entity.size = original_size
			#entity.global_position = original_position 
			#
			#
		#toggle_tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		#toggle_tween.tween_property(entity,"size",inner_size,toggle_tween_time)
		#toggle_tween.tween_property(entity,"global_position",INNER_POSITION,toggle_tween_time)
		entity.set_deferred("size",inner_size) # deferred these to avoid a warning about anchors
		entity.set_deferred("global_position",INNER_POSITION) 
	else:
		#if toggle_tween:
			#toggle_tween.kill()
			#
		#toggle_tween = create_tween().set_parallel()
		#toggle_tween.tween_property(entity,"global_position",original_position,toggle_tween_time)
		#toggle_tween.tween_property(entity,"size",original_size,toggle_tween_time)
		#toggle_tween.set_parallel(false)
		#toggle_tween.tween_property(entity,"scale",Vector2(0.85,0.85),toggle_tween_time/3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		#toggle_tween.tween_property(entity,"scale",Vector2.ONE,toggle_tween_time/3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		
		entity.set_deferred("size",original_size) # deferred these to avoid a warning about anchors
		entity.set_deferred("global_position",original_position) 

static func get_board_from_group_name(member:Control,board_group_name:String)-> BoardComponent:
	var boards:Array = member.get_tree().get_nodes_in_group("boards")
	for board_entity:Control in boards:
		var board_component:BoardComponent = get_component_or_null(board_entity)
		if board_component.group_name == board_group_name:
			return board_component
	return null

static func get_component_or_null(s_entity:Control,_name:StringName="")-> BoardComponent:
	if not s_entity:
		return null
	
	if s_entity.has_meta(TYPE_ID):
		return s_entity.get_meta(TYPE_ID)
	elif s_entity.has_meta("Side"+TYPE_ID): #Inherited
		return s_entity.get_meta("Side"+TYPE_ID)
	return null
