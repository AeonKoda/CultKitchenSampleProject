class_name StackComponent extends Component
const TYPE_ID:StringName = &"StackComponent"

signal entity_repositioned(old_position:Vector2)
signal item_added_to_entity_stack(entity:Control,item:Control)
signal previous_changed
signal entity_removed_from_item_stack(entity:Control, item:Control)

const STACK_OFFSET_Y:int = -18
@export var stack_offset_y:int = STACK_OFFSET_Y
@export var stack_limit:int = 50

var previous:Control:
	set(value):
		#print(entity," previous ",value)
		if previous != value:
			previous = value
			previous_changed.emit()
var next:Control:
	set(value):
		next = value
		#print(entity," next ",value)

var old_position:Vector2
var position_changed:bool = false

func release()->void:
	if next or previous:
		pop_self()
	super()


# =====================================================
# CHAIN MANAGMENT
# =====================================================
func append(item:Control,from_removal:bool = false)-> void:
	if not can_stack():
		set_to_side()
		return
	
	var item_stack_component:StackComponent = get_component_or_null(item)
	if not item_stack_component or item_stack_component == self:
		return
	elif item in get_chain():
		push_warning("Adding item to own chain")
		return
	
	var top_stack_component:StackComponent = get_component_or_null(get_top())
	top_stack_component.next = item
	item_stack_component.set_previous(top_stack_component.entity)
	
	refresh_index()
	item_stack_component._on_previous_item_rect_changed()
	
	reposition_chain_from(item)
	if not from_removal:
		item_added_to_entity_stack.emit(entity,item)


func insert_as_next(item:Control)-> void:
	if not can_stack():
		set_to_side()
		return
	
	var item_stack_component:StackComponent = get_component_or_null(item)
	if not item_stack_component or item_stack_component == self:
		return
	elif item in get_chain():
		push_warning("Adding item to own chain")
		breakpoint
		return
	
	var next_stack_component:StackComponent = get_component_or_null(next)
	var old_next:Control = next
	
	if next_stack_component:
		next_stack_component.set_previous(item_stack_component.get_top())
		
	var item_top_stack_component:StackComponent = get_component_or_null(item_stack_component.get_top())
	item_top_stack_component.next = old_next
	item_stack_component.set_previous(entity)
	
	next = item
	
	refresh_index()
	item_stack_component._on_previous_item_rect_changed()
	reposition_chain_from(item)
	item_added_to_entity_stack.emit(entity,item)

func insert_as_previous(item:Control)-> void:
	if not can_stack():
		set_to_side()
		return
	
	var item_stack_component:StackComponent = get_component_or_null(item)
	if not item_stack_component or item_stack_component == self:
		return
	elif item in get_chain():
		push_warning("Adding item to own chain")
		breakpoint
		return
	
	var previous_stack_component:StackComponent = get_component_or_null(previous)
	
	if previous_stack_component:
		previous_stack_component.next = item
	
	var item_top_stack_component:StackComponent = get_component_or_null(item_stack_component.get_top())
	item_top_stack_component.next = entity
	
	if previous_stack_component:
		item_stack_component.set_previous(previous_stack_component.entity)
	
	set_previous(item_top_stack_component.entity)
	if not previous_stack_component:
		item.global_position = entity.global_position + Vector2(0,(entity.size.y-item.size.y))
		
	refresh_index()
	if item_stack_component.next:
		reposition_chain_from(item_stack_component.next)
	item_added_to_entity_stack.emit(entity,item)

func slice_at_previous()-> void:
	remove_previous()

func pop_self()-> void:
	var previous_stack_component:StackComponent = get_component_or_null(previous)
	var next_stack_component:StackComponent =  get_component_or_null(next)
	
	if next_stack_component:
		next_stack_component.remove_previous()
	if previous_stack_component:
		remove_previous()
	if previous_stack_component and next_stack_component:
		previous_stack_component.append(next_stack_component.entity,true)
	
	if previous_stack_component:
		entity_removed_from_item_stack.emit(entity,previous_stack_component.entity)
	elif next_stack_component:
		entity_removed_from_item_stack.emit(entity,next_stack_component.entity)
	
	# Update Visuals
	if not previous_stack_component and next_stack_component:
		next_stack_component.entity.global_position = entity.global_position + Vector2(0,(entity.size.y-next_stack_component.entity.size.y))
		next_stack_component.reposition_chain_from(next_stack_component.entity)
	if next_stack_component and next_stack_component.previous:
		next_stack_component._on_previous_item_rect_changed()
	refresh_index()
	
	if next_stack_component:
		reposition_chain_from(next_stack_component.entity)

func set_previous(item:Control)-> void:
	if item != previous:
		if previous:
			remove_previous()
		
		if item:
			previous = item
			set_previous_signals()

func remove_previous()-> void:
	if previous:
		var previous_stack_component:StackComponent = get_component_or_null(previous)
		previous_stack_component.next = null
		
		remove_previous_signals()
		previous = null

func set_to_side()-> void:
	pass

# =====================================================
# CHAIN SIGNAL MANAGMENT
# =====================================================
func set_previous_signals()-> void:
	if not previous.item_rect_changed.is_connected(_on_previous_item_rect_changed):
		previous.item_rect_changed.connect(_on_previous_item_rect_changed)
	if not previous.visibility_changed.is_connected(_on_previous_visibility_changed):
		previous.visibility_changed.connect(_on_previous_visibility_changed)

func remove_previous_signals()-> void:
	if previous.item_rect_changed.is_connected(_on_previous_item_rect_changed):
		previous.item_rect_changed.disconnect(_on_previous_item_rect_changed)
	if previous.visibility_changed.is_connected(_on_previous_visibility_changed):
		previous.visibility_changed.disconnect(_on_previous_visibility_changed)


# =====================================================
# VISUAL MANAGMENT
# =====================================================
func reposition_chain_from(item:Control)-> void:
	#visual reposition only
	
	var chain:Array[Control] = get_chain(item)
	for link:Control in chain:
		var link_stack_component:StackComponent = get_component_or_null(link)
		link_stack_component.entity_repositioned.emit(link_stack_component.old_position)

func _on_previous_item_rect_changed()-> void:
	if not position_changed:
		old_position = entity.global_position
		position_changed = true
		get_tree().process_frame.connect(func()-> void:position_changed = false,4)
	var previous_stack_component:StackComponent = StackComponent.get_component_or_null(previous)
	entity.global_position = previous.global_position + Vector2(0,(previous.size.y-entity.size.y)) + Vector2(0,previous_stack_component.stack_offset_y)

func _on_previous_visibility_changed()-> void:
	pass
	
	# not needed anymore
	#entity.visible = previous.is_visible_in_tree()

func refresh_index()-> void:
	var chain:Array[Control] = get_chain()
	if chain.is_empty():
		return
	
	var lowest_index:int = chain[0].get_index()
	var max_index:int = entity.get_parent().get_child_count() - 1
	
	if lowest_index + chain.size() <= max_index:
		var parent:Node = entity.get_parent()
		for i:int in chain.size():
			var link:Control = chain[i]
			parent.move_child(link,lowest_index + i)
			link.z_index = chain[0].z_index
	else:
		for link:Control in chain:
			link.move_to_front()
			link.z_index = chain[0].z_index


# =====================================================
# CHAIN QUERIES
# =====================================================

func can_stack()-> bool:
	var bottom_stack_component:StackComponent = StackComponent.get_component_or_null(get_bottom())
	if get_stack_size() >= bottom_stack_component.stack_limit: 
		return false
	return true

func get_bottom()-> Control:
	var bottom:Control = entity
	var i:int = 0
	
	var stack_component:StackComponent = self
	while bottom:
		if not stack_component.previous:
			break
		bottom = stack_component.previous
		stack_component = StackComponent.get_component_or_null(bottom)
		i += 1
		if i > stack_limit*2:
			push_warning("corrupted chain detected")
			breakpoint
			return bottom
	return bottom

func get_top()-> Control:
	var top:Control = entity
	var i:int = 0
	
	var stack_component:StackComponent = self
	while top:
		if not stack_component.next:
			break
		top = stack_component.next
		stack_component = StackComponent.get_component_or_null(top)
		i += 1
		if i > stack_limit*2:
			push_warning("corrupted chain detected")
			breakpoint
	return top

func get_chain(from:Control = null)-> Array[Control]:
	var chain:Array[Control] = []
	var bottom:Control = get_bottom() if not from else from
	while bottom:
		chain.append(bottom)
		var new_bottom_stack:StackComponent = get_component_or_null(bottom)
		bottom = new_bottom_stack.next if new_bottom_stack else null
	return chain

func get_slice(num_previous:int, num_next:int)-> Array[Control]:
	var slice:Array[Control] = []
	
	var previous_link:Control = previous
	for i in range(num_previous):
		if previous_link:
			slice.append(previous_link)
			var previous_stack_component:StackComponent = StackComponent.get_component_or_null(previous_link)
			previous_link = previous_stack_component.previous if previous_stack_component else null
		else:
			break
	
	slice.reverse()
	
	slice.append(entity)
	
	var next_link:Control = next
	for i in range(num_next):
		if next_link:
			slice.append(next_link)
			var next_stack_component:StackComponent = StackComponent.get_component_or_null(next_link)
			next_link = next_stack_component.next if next_stack_component else null
		else:
			break

	return slice

func get_stack_size()-> int:
	var size:int = 0
	var bottom:Control = get_bottom()
	while bottom:
		size += 1
		var new_bottom_stack:StackComponent = get_component_or_null(bottom)
		bottom = new_bottom_stack.next if new_bottom_stack else null
	return size
	

static func get_component_or_null(s_entity:Control,_name:StringName="")-> StackComponent:
	if not s_entity:
		return null
	
	if s_entity.has_meta(TYPE_ID):
		return s_entity.get_meta(TYPE_ID)
	return null
