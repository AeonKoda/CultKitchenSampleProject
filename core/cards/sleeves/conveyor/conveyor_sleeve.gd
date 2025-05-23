class_name SleeveConveyor extends Sleeve

const TRANSFER_ITEM_Z_INDEX:int = 1

var conveyor_resource:ConveyorSleeveResource

# Base stats
var transfer_time:float = 3.0
var transfer_rate:float = 1.0

# Altar Upgrades
var max_senders:int = 3



var transfering_items:Dictionary[Control,Dictionary]
var power:bool = false

var reciever:SleeveConveyor
var senders:Dictionary = {}
var sender:SleeveConveyor

var transfer_tween:Tween

@onready var conveyor_button: ConveyorButton = %ConveyorButton
@onready var conveyor_line: ConveyorLine = %ConveyorLine

@onready var wheel_1: TextureRect = %Wheel1
@onready var wheel_2: TextureRect = %Wheel2
@onready var wheel_3: TextureRect = %Wheel3
@onready var wheel_4: TextureRect = %Wheel4

var wheels:Array[TextureRect]

func setup(item:Control,resource:SleeveResource)-> void:
	super(item,resource)
	
	conveyor_resource = sleeve_resource
	transfer_time = conveyor_resource.transfer_time
	transfer_rate = conveyor_resource.transfer_rate
	
	var stat_dict:Dictionary
	if Global.game:
		stat_dict = Global.game.sleeve_upgrade_stats["conveyor_sleeve"]
	if stat_dict:
		max_senders = stat_dict.get("max_senders",max_senders)
	wheels = [wheel_1,wheel_2,wheel_3,wheel_4]
	conveyor_button.entity = entity
	conveyor_button.boarder_control = get_parent()
	connect_signals()
	

func connect_signals()-> void:
	if not conveyor_button.power_toggled.is_connected(_on_conveyor_button_toggled):
		conveyor_button.power_toggled.connect(_on_conveyor_button_toggled)
	if not conveyor_button.reciever_added.is_connected(_on_conveyor_reciever_added):
		conveyor_button.reciever_added.connect(_on_conveyor_reciever_added)
	if not conveyor_button.reciever_removed.is_connected(_on_conveyor_reciever_removed):
		conveyor_button.reciever_removed.connect(_on_conveyor_reciever_removed)


func sleeved(card:Card)-> void:
	for button:ConveyorButton in senders.values():
		button.boarder_control = card.texture
	conveyor_button.boarder_control = card.texture
	super(card)

func unsleeved()-> void:
	for button:ConveyorButton in senders.values():
		button.boarder_control = get_parent()
	conveyor_button.boarder_control = get_parent()
	
	conveyor_button.power = false
	for sleeve:SleeveConveyor in senders.keys():
		sleeve.conveyor_button.power = false
	if reciever:
		reciever.conveyor_button.power = false
	
	super()


func can_add_sender()-> bool:
	if reciever:
		return false
	return senders.size() < max_senders


func _on_conveyor_button_toggled(value:bool)-> void:
	power = value
	if power:
		if reciever:
			if transfer_tween and transfer_tween.is_valid():
				transfer_tween.play()
			else:
				create_transfer_tween()
			wheels_power(true)
	elif not power:
		if transfer_tween and transfer_tween.is_running():
			transfer_tween.stop()
		wheels_power(false)
	
	var reciever_button:ConveyorButton = conveyor_button.reciever
	if reciever_button:
		reciever_button.power = value

func _on_conveyor_reciever_added(new_reciever:SleeveConveyor)-> void:
	conveyor_button.power = false
	reciever = new_reciever
	new_reciever.add_sender(self)

func _on_conveyor_reciever_removed(old_reciever:SleeveConveyor)-> void:
	reciever = null
	old_reciever.remove_sender(self)

func add_sender(sender_conveyor:SleeveConveyor)-> void:
	var button:ConveyorButton = conveyor_button
	if senders.is_empty():
		for item:Control in wheels:
			item.hide()
	else:
		button = conveyor_button.duplicate()
		button.remove_link(conveyor_button.sender)
		button.entity = entity
		button.boarder_control = conveyor_button.boarder_control
		button.current_offset = conveyor_button.current_offset
		conveyor_button.get_parent().add_child(button)
	sender_conveyor.conveyor_button.add_link(button)
	senders[sender_conveyor] = button

func remove_sender(sender_conveyor:SleeveConveyor)-> void:
	var button_matching_sender:ConveyorButton = senders[sender_conveyor]
	var num_senders:int = senders.size()
	
	senders.erase(sender_conveyor)
	sender_conveyor.conveyor_button.remove_link(button_matching_sender)
	
	if num_senders > 1:
		if button_matching_sender == conveyor_button:
			conveyor_button = senders.values()[0]
		button_matching_sender.hide()
		button_matching_sender.queue_free()
		

	if senders.is_empty():
		for item:Control in wheels:
			item.show()

func wheels_power(on:bool)->void:
	if on:
		for item:Control in wheels:
			item.spin(1.0)
	else:
		for item:Control in wheels:
			item.stop()

func create_transfer_tween()-> void:
	if transfer_tween and transfer_tween.is_valid():
		return
	
	transfer_tween = create_tween().set_loops()
	transfer_tween.tween_interval(transfer_rate)
	transfer_tween.loop_finished.connect(begin_transfer.unbind(1))

func begin_transfer(transfering_item:Control = null)-> void:
	if not entity or not entity.sleeved_card:return
	var entity_stack_component:StackComponent = StackComponent.get_component_or_null(entity.sleeved_card)
	
	transfering_item = entity_stack_component.next if entity_stack_component else transfering_item
	if not transfering_item or not reciever:return
	if not reciever.entity.sleeved_card: return
	
	var transfering_item_stack_component:StackComponent = StackComponent.get_component_or_null(transfering_item)

	if transfering_item_stack_component:
		if transfering_item_stack_component == StackComponent.get_component_or_null(reciever.entity.sleeved_card):
			return
		transfering_item_stack_component.pop_self()
	
	
	
	var reciever_entity:Control = reciever.entity.sleeved_card
	var item_lift_component:LiftComponent = LiftComponent.get_component_or_null(transfering_item)
	var tween:Tween = transfering_item.create_tween()
	var transfer_data:Dictionary = {
		"reciever_entity":reciever_entity,
		"reciever_conveyor_component":reciever,
		"sender_conveyor_component":self,
		"item_lift_component":item_lift_component,
		"tween":tween,
		"partial_transfer_time":transfer_time
	}
	transfering_items[transfering_item] = transfer_data
	var target_pos:Vector2 = reciever.global_position
	
	#transfering_item.z_index = max(entity.z_index+1, reciever_entity.z_index+1)
	tween.tween_property(transfering_item,"global_position",target_pos,transfer_time)
	
	if item_lift_component:
		item_lift_component.entity_lifted.connect(interupt.bind(transfering_item).unbind(1),4)
	
	if not reciever_entity.item_rect_changed.is_connected(target_moved):
		reciever_entity.item_rect_changed.connect(target_moved)
	tween.finished.connect(reciever.accept_transfer.bind(transfering_item,transfering_items[transfering_item]),4)

func target_moved()-> void:
	for transfering_item:Control in transfering_items:
		var reciever_entity:Control = transfering_items[transfering_item]["reciever_entity"]
		var tween:Tween = transfering_items[transfering_item]["tween"]
		var partial_transfer_time:float = transfering_items[transfering_item]["partial_transfer_time"]
		var reciever_conveyor_component:SleeveConveyor = transfering_items[transfering_item]["reciever_conveyor_component"]
		
		var transfering_item_stack_component:StackComponent = StackComponent.get_component_or_null(transfering_item)
		if reciever_entity in transfering_item_stack_component.get_chain():
			interupt(transfering_item)
			return
		
		#transfering_item.z_index = max(entity.z_index+1, reciever_entity.z_index+1)
		if tween:
			var time_remaining:float = partial_transfer_time - tween.get_total_elapsed_time()
			transfering_items[transfering_item]["partial_transfer_time"] = time_remaining
			if time_remaining > 0:
				tween.kill()
				tween = transfering_item.create_tween()
				transfering_items[transfering_item]["tween"] = tween
				
				var target_pos:Vector2 = reciever_conveyor_component.conveyor_button.global_position - transfering_item.pivot_offset
				tween.tween_property(transfering_item,"global_position",target_pos,time_remaining)
				tween.finished.connect(reciever_conveyor_component.accept_transfer.bind(transfering_item,transfering_items[transfering_item]),4)

func interupt(transfering_item:Control)-> void:
	var tween:Tween = transfering_items[transfering_item]["tween"]
	var reciever_entity:Control = transfering_items[transfering_item]["reciever_entity"]
	var item_lift_component:LiftComponent =  transfering_items[transfering_item]["item_lift_component"]
	
	if tween:
		tween.kill()
	
	
	transfer_complete(transfering_item)
	if transfering_items.is_empty():
		if reciever_entity.item_rect_changed.is_connected(target_moved):
			reciever_entity.item_rect_changed.disconnect(target_moved)
	
	if item_lift_component:
		if item_lift_component.entity_lifted.is_connected(interupt):
			item_lift_component.entity_lifted.disconnect(interupt)

func accept_transfer(item:Control,transfer_data:Dictionary)-> void:
	var item_lift_component:LiftComponent = transfer_data["item_lift_component"]
	var reciever_entity:Control = transfer_data["reciever_entity"]
	var sender_conveyor_component:SleeveConveyor =  transfer_data["sender_conveyor_component"]
	
	if item_lift_component:
		if item_lift_component.entity_lifted.is_connected(sender_conveyor_component.interupt):
			item_lift_component.entity_lifted.disconnect(sender_conveyor_component.interupt)
	
	
	sender_conveyor_component.transfer_complete(item)
	if sender_conveyor_component.transfering_items.is_empty():
		if reciever_entity.item_rect_changed.is_connected(sender_conveyor_component.target_moved):
			reciever_entity.item_rect_changed.disconnect(sender_conveyor_component.target_moved)
	
	await get_tree().process_frame
	var entity_stack_component:StackComponent = StackComponent.get_component_or_null(entity.sleeved_card)
	var entity_board_component:BoardComponent = BoardComponent.get_component_or_null(entity.sleeved_card)
	
	if entity_board_component:
		entity_board_component.add_to_board(item)
		#entity_board_component.door_stack_component.insert_as_next(item)
	elif entity_stack_component:
		var next:Control = entity_stack_component.next
		var target:Control = entity.sleeved_card
		while next:
			if next.has_meta("Sleeve"):
				var card_sleeve:CardSleeve = next.get_meta("Sleeve")
				if card_sleeve.sleeve is SleeveConveyor and not card_sleeve.sleeve.senders.is_empty():
					var next_stack_component:StackComponent = StackComponent.get_component_or_null(next)
					target = next
					if next_stack_component.next:
						next = next_stack_component.next
					else:
						break
				else:
					break
			else:
				break
		
		var target_stack_component:StackComponent = StackComponent.get_component_or_null(target)
		target_stack_component.insert_as_next(item)
	elif reciever:
		item.global_position = conveyor_button.global_position - item.pivot_offset # Set this to the open pos of given link
		begin_transfer(item)

func transfer_complete(transfering_item:Control)-> void:
	transfering_items.erase(transfering_item)
