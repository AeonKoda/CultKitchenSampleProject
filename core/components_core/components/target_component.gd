class_name TargetComponent extends Component
const TYPE_ID:StringName = &"TargetComponent"

signal targetable_entity_primary_input_pressed(entity:Control)
signal targetable_entity_primary_input_released(entity:Control)
signal targetable_entity_primary_input_alt_pressed(entity:Control)


signal targetable_entity_secondary_input_pressed(entity:Control)
signal targetable_entity_secondary_input_pressed_echo(entity:Control)
signal targetable_entity_secondary_input_released(entity:Control)
signal targetable_entity_secondary_input_alt_pressed(entity:Control)

signal targetable_entity_sleeve_pressed(entity:Control)

signal entity_mouse_entered(entity:Control)
signal entity_mouse_exited(entity:Control)
signal entity_special_area_entered(entity:Control)
signal entity_special_area_exited(entity:Control)

signal releasing(target_component:TargetComponent)

var targetable:bool = true
var target_locks:Array[String] = []

@export var targetable_item:Control

var echo:bool = true
var has_mouse:bool = false
var entity_global_rect:Rect2
var entity_special_area_rect:Rect2

var special_area_has_mouse:bool = false

func _enter_tree() -> void:
	super()
	add_to_group("TARGET_COMPONENTS")
	
func _ready() -> void:
	if not targetable_item:
		targetable_item = entity
	
	if not targetable_item.gui_input.is_connected(_on_entity_input_handler):
		targetable_item.gui_input.connect(_on_entity_input_handler)
	
	if targetable_item.has_signal("releasing"):
		if not targetable_item.releasing.is_connnected(release):
			targetable_item.releasing.connect(release.unbind(1))
	
	if entity.has_signal("releasing"):
		if not entity.releasing.is_connnected(release):
			entity.releasing.connect(release.unbind(1))
	
	if not targetable_item.visibility_changed.is_connected(_on_entity_visibility_changed):
		targetable_item.visibility_changed.connect(_on_entity_visibility_changed)
	
	super()

func release()-> void:
	targetable = false
	add_target_lock("Releasing")
	releasing.emit(self)
	
	super()

func _on_entity_input_handler(event:InputEvent)-> void:
	if targetable or (target_locks.size() == 1 and target_locks.has("BoardActive")):
		if event.is_action_pressed("primary_input") and Input.is_action_pressed("sleeve"):
			targetable_entity_sleeve_pressed.emit(entity)
		elif event.is_action_pressed("primary_input"):
			targetable_entity_primary_input_pressed.emit(entity)
		elif event.is_action_pressed("secondary_input"):
			targetable_entity_secondary_input_pressed.emit(entity)
			pass
	if event.is_action_released("primary_input") and has_mouse:
		targetable_entity_primary_input_released.emit(entity)
	elif event.is_action_released("secondary_input") and has_mouse:
		targetable_entity_secondary_input_released.emit(entity)
	
	

func _process(_delta: float) -> void:
	#if targetable:
	var mouse_position:Vector2 = entity.get_global_mouse_position()
	var targetable_rect:Rect2 = targetable_item.get_global_rect()
	var targetable_special_rect:Rect2 = get_special_rect(entity.get_global_rect())
	
	if targetable_rect.has_point(mouse_position):
		if not has_mouse:
			has_mouse = true
			_on_entity_mouse_entered()
	else:
		if has_mouse:
			has_mouse = false
			_on_entity_mouse_exited()
	if targetable_special_rect.has_point(mouse_position):
		if not special_area_has_mouse:
			special_area_has_mouse = true
			_on_entity_special_area_mouse_entered()
	else:
		if special_area_has_mouse:
			special_area_has_mouse = false
			_on_entity_special_area_mouse_exited()


func _on_rect_changed()-> void:
	entity_global_rect = targetable_item.get_global_rect()
	entity_special_area_rect = get_special_rect(entity_global_rect)

func _on_entity_mouse_entered()-> void:
	if targetable:
		entity_mouse_entered.emit(entity)


func _on_entity_mouse_exited()-> void:
	entity_mouse_exited.emit(entity)


func _on_entity_special_area_mouse_entered()-> void:
	if targetable:
		entity_special_area_entered.emit(entity)

func _on_entity_special_area_mouse_exited()-> void:
	entity_special_area_exited.emit(entity)

func _on_entity_visibility_changed()-> void:
	if targetable_item.is_visible_in_tree():
		if target_locks.has("Hidden"):
			remove_target_lock("Hidden")
	else:
		add_target_lock("Hidden")

# To-do: make target locks bit flags?

func add_target_lock(lock:String)-> void:
	target_locks.append(lock)
	targetable = false

func remove_target_lock(lock:String)-> void:
	target_locks.erase(lock)
	if target_locks.is_empty():
		targetable = true

func get_special_rect(global_rect: Rect2, OFFSET: float = abs(StackComponent.STACK_OFFSET_Y)) -> Rect2:
	var new_position:Vector2 = Vector2(global_rect.position.x, global_rect.end.y)
	var new_size:Vector2 = Vector2(global_rect.size.x, abs(OFFSET))
	return Rect2(new_position, new_size)

static func get_component_or_null(s_entity:Control,_name:StringName="")-> TargetComponent:
	if not s_entity:
		return null
	
	if s_entity.has_meta(TYPE_ID):
		return s_entity.get_meta(TYPE_ID)
	return null
