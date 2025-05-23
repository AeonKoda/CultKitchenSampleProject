class_name LiftComponent extends Component
const TYPE_ID:StringName = &"LiftComponent"

const LIFT_Z_INDEX:int = 10

signal entity_lifted
signal entity_dropped

var enabled:bool = true
var dragging:bool = false
var dragging_offset:Vector2

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_dragging() -> void:
	if not dragging and enabled:
		dragging = true
		entity.z_index = LIFT_Z_INDEX
		entity.move_to_front()
		dragging_offset = entity.global_position - entity.get_global_mouse_position()
		entity_lifted.emit(entity)
		get_window().window_input.connect(_on_window_input)

func stop_dragging()-> void:
	if dragging:
		dragging = false
		entity.z_index = 0
		#entity.move_to_front()
		entity_dropped.emit(entity)
		get_window().window_input.disconnect(_on_window_input)

func _on_window_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if dragging:
			_update_dragging_position(event.global_position)

# to-do: make it so you cannot drag off screen boarder.

func _update_dragging_position(global_position:Vector2)-> void:
	# 1. Mouse‐based “desired” position
	var mouse_pos: Vector2 = entity.get_global_mouse_position()
	var desired_pos: Vector2 = mouse_pos + dragging_offset  # dragging_offset should be Vector2
	var screen_margin:int = Global.game.grid_size if Global.game else Global.DEFAULT_GRID_SIZE

	# 2. Sizes of card and viewport
	var card_rect: Rect2 = entity.get_global_rect()
	var card_size: Vector2 = card_rect.size
	var vp_rect: Rect2 = get_viewport().get_visible_rect()
	var vp_size: Vector2 = vp_rect.size

	# 3. Compute clamping bounds
	var min_x: float = -card_size.x + float(screen_margin)
	var max_x: float = vp_size.x -card_size.x

	# Ensure bottom edge never goes above y=screen_margin: pos.y >= screen_margin - card_height
	var min_y: float = float(screen_margin) - card_size.y
	# Ensure bottom edge never goes below viewport bottom: pos.y <= viewport_height - card_height
	var max_y: float = vp_size.y - card_size.y

	# 4. Clamp each axis
	var clamped_x: float = clamp(desired_pos.x, min_x, max_x)
	var clamped_y: float = clamp(desired_pos.y, min_y, max_y)

	# 5. Apply
	entity.global_position = Vector2(clamped_x, clamped_y)


static func get_component_or_null(s_entity:Control,_name:StringName="")-> LiftComponent:
	if not s_entity:
		return null
	
	if s_entity.has_meta(TYPE_ID):
		return s_entity.get_meta(TYPE_ID)
	return null
