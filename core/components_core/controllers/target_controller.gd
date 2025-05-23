class_name TargetControllerSingleton extends Node2D

signal entity_removed_from_held(entity:Control)
signal held_changed
signal targets_changed
signal select_changed
signal speacial_area_targets_changed
signal primary_input_released

signal begin_hold
signal end_hold

signal target_hovered
signal off_hovered

signal on_select
signal off_select

signal state_changed
signal target_changed(node:Node)
signal speacial_area_target_changed(node:Node)

enum States {
	DEFAULT        = 0,
	HOVER          = 1 << 0, # 1 [1]
	HOLD           = 1 << 1, # 2 [10]
	SELECT         = 1 << 2, # 4 [100]
	SPECIAL_HOVER  = 1 << 3, # 8 [1000]
	HOVER_HOLD     = HOVER | HOLD, # 1 | 2 = 3
	SELECT_HOVER   = SELECT | HOVER, # 4 | 1 = 5
	SELECT_HOLD    = SELECT | HOLD, # 4 | 2 = 6
	SELECT_HOVER_HOLD = SELECT | HOVER | HOLD, # 4 | 1 | 2 = 7
	SELECT_SPECIAL_HOVER_HOLD = SELECT | SPECIAL_HOVER | HOLD, # 4 | 8 | 2 = 14
	SELECT_SPECIAL_HOVER = SELECT | SPECIAL_HOVER, # 4 | 8 = 12
}
var state:States = States.DEFAULT:
	set(value):
		previous_state = state
		state = value
var previous_state:States = States.DEFAULT

var targets:Array[Control]
var _target:Control:
	set(value):
		previous_target = _target
		_target = value
		
		if _target != previous_target:
			target_changed.emit(_target)
var previous_target:Control

var special_area_targets:Array[Control]
var special_area_target:Control:
	set(value):
		previous_special_area_target = special_area_target
		special_area_target = value
		
		if special_area_target != previous_special_area_target:
			speacial_area_target_changed.emit(special_area_target)
var previous_special_area_target:Control


var state_checked: bool = false

var held_entities:Array[Control]
var select_enabled:bool = false:
	set(value):
		if value != select_enabled:
			select_enabled = value
			if value:
				on_select.emit()
			else:
				off_select.emit()
			select_changed.emit()

var global_mouse_position:Vector2
var cursor:Control

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	held_changed.connect(check_state.call_deferred)
	targets_changed.connect(check_state.call_deferred)
	select_changed.connect(check_state.call_deferred)
	speacial_area_targets_changed.connect(check_state.call_deferred)
	
	for target_component:TargetComponent in get_tree().get_nodes_in_group("TARGET_COMPONENTS"):
		_regiter_target_component(target_component)
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)

func _input(event: InputEvent) -> void:
	if event.is_action_released("primary_input"):
		# This code allows you to input while holding a card. vvv
		if event.has_meta("Dummy"):
			return
		# This code allows you to input while holding a card. ^^^
		primary_input_released.emit()

#Target nodes should emit a node added signal and the coordinator should emit this,
# Then target controller listens to coordinator 
func _on_node_added(node:Node)-> void:
	if node is TargetComponent:
		_regiter_target_component(node)

func _regiter_target_component(target_component:TargetComponent)-> void:
	if not target_component.entity_mouse_entered.is_connected(_on_entity_mouse_entered):
		target_component.entity_mouse_entered.connect(_on_entity_mouse_entered)
	if not target_component.entity_mouse_exited.is_connected(_on_entity_mouse_exited):
		target_component.entity_mouse_exited.connect(_on_entity_mouse_exited)
	if not target_component.entity_special_area_entered.is_connected(_on_entity_special_area_mouse_entered):
		target_component.entity_special_area_entered.connect(_on_entity_special_area_mouse_entered)
	if not target_component.entity_special_area_exited.is_connected(_on_entity_special_area_mouse_exited):
		target_component.entity_special_area_exited.connect(_on_entity_special_area_mouse_exited)
	if not target_component.releasing.is_connected(_on_component_releasing):
		target_component.releasing.connect(_on_component_releasing)


func _on_entity_mouse_entered(entity:Control)-> void:
	add_target(entity)

func _on_entity_mouse_exited(entity:Control)-> void:
	if targets.has(entity):
		remove_target(entity)

func _on_entity_special_area_mouse_entered(entity:Control)-> void:
	add_special_area_target(entity)

func _on_entity_special_area_mouse_exited(entity:Control)-> void:
	if special_area_targets.has(entity):
		remove_special_area_target(entity)

func _on_component_releasing(target_component:TargetComponent)-> void:
	var entity:Control = target_component.entity
	if entity:
		remove_target(entity)
		remove_special_area_target(entity)
		remove_held(entity)

# =====================================================
# CORE
# =====================================================

func _process(_delta: float) -> void:
	global_mouse_position = get_global_mouse_position()
	select_enabled = Input.is_action_pressed("select")
	_target = get_target()
	special_area_target = get_special_area_target() if not _target else null

func check_state() -> States:
	if not state_checked:
		var old_state:States = state
		var new_state:int = States.DEFAULT

		if select_enabled:
			new_state |= States.SELECT
		if get_target():
			new_state |= (States.HOVER as States)
		elif get_special_area_target() and select_enabled:
			new_state |= (States.SPECIAL_HOVER as States)
		if not held_entities.is_empty():
			new_state |= (States.HOLD as States)
		
		if new_state != old_state:
			state = new_state as States
			state_changed.emit(state)
		
		state_checked = true
		set.call_deferred("state_checked",false)
	return state

func add_target(entity:Control)-> void:
	if targets.is_empty():
		target_hovered.emit()
	
	targets.append(entity)
	
	_target = get_target()
	
	targets_changed.emit()

func remove_target(entity:Control)-> void:
	if entity in targets:
		targets.erase(entity)
	
		_target = get_target()
		targets_changed.emit()
		
		if targets.is_empty():
			off_hovered.emit()

func add_special_area_target(entity:Control)-> void:
	if not entity in special_area_targets:
		special_area_targets.append(entity)
	
	special_area_target = get_special_area_target() if not _target else null
	
	speacial_area_targets_changed.emit()

func remove_special_area_target(entity:Control)-> void:
	if entity in special_area_targets:
		special_area_targets.erase(entity)
	
		special_area_target = get_special_area_target() if not _target else null
		speacial_area_targets_changed.emit()

func get_target(ignore_locks:Array[String] = [])-> Control:
	if targets.is_empty():
		return null
	var top:Control =  get_top_drawn_node(targets)
	
	var target_component:TargetComponent = get_target_component(top)
	if target_component:
		var target_locks:Array =  target_component.target_locks
		var result:Array = target_locks.filter(func(item:String)->bool: return item not in ignore_locks)
		if not result.is_empty():
			return null
	return top

func get_special_area_target(ignore_locks:Array[String] = [])-> Control:
	if special_area_targets.is_empty():
		return null
	var top:Control = get_top_drawn_node(special_area_targets)
	
	var target_component:TargetComponent = get_target_component(top)
	if target_component:
		var target_locks:Array =  target_component.target_locks
		var result:Array = target_locks.filter(func(item:String)->bool: return item not in ignore_locks)
		if not result.is_empty():
			return null
	return 

func add_held(entity:Control)-> void:
	if held_entities.is_empty():
		begin_hold.emit()
	
	if entity not in held_entities:
		held_entities.append(entity)
		held_changed.emit()

func remove_held(entity:Control)-> void:
	if entity in held_entities:
		held_entities.erase(entity)
		
		entity_removed_from_held.emit(entity)
		held_changed.emit()
		
		if held_entities.is_empty():
			end_hold.emit()

func clear_held()-> void:
	held_entities.clear()
	end_hold.emit()
	held_changed.emit()

func get_top_drawn_node(nodes: Array[Control]) -> Node:
	if nodes.is_empty():
		return null
	var top_node: Node = null

	for node in nodes:
		if _is_drawn_higher(node, top_node):
			var target_component:TargetComponent = get_target_component(node)
			if target_component and node not in held_entities and node.is_visible_in_tree():
				top_node = node
	
	return top_node

func _is_drawn_higher(a: Node, b: Node) -> bool:
	if not b:
		return true
	
	if a.z_index > b.z_index:
		return true
	if a.z_index < b.z_index:
		return false
		
	# Compare their order within the LCA
	return a.get_index() > b.get_index()

func get_target_component(node:Control)-> TargetComponent:
	if not node:
		return null
	
	var target_component:TargetComponent = null
	
	for child:Node in node.get_children():
		if child is TargetComponent:
			target_component = child
			break
	return target_component

func is_holding()-> bool:
	return state & States.HOLD

func is_hovering()-> bool:
	return state & States.HOVER

func is_select()-> bool:
	return state & States.SELECT
