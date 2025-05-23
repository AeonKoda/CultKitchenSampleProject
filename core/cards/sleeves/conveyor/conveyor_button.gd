class_name ConveyorButton extends TextureButton

signal power_toggled(power:bool)
signal reciever_added(link:CardSleeve)
signal reciever_removed(link:CardSleeve)

const INNER_MARGIN:float  = 1
var current_offset: float = 149
var speed: float = 300.0

var entity:Control
var boarder_control:Control:
	set(value):
		boarder_control = value
#var conveyor_component:ConveyorComponent

var linked:bool = false
var dragging:bool = false

var reciever:ConveyorButton
var sender:ConveyorButton

var power:bool = false:
	set(value):
		if value != power:
			power_toggled.emit(value)
		power = value
		
		if value:
			spin(1.0)
		else:
			stop()

var enabled:bool = true

var tween:Tween
var index:int = 0
@export var frames:SpriteFrames
@export var line:ConveyorLine

func _ready() -> void:
	boarder_control = entity if not boarder_control else boarder_control
	pivot_offset = size/2

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary_input"):
		if not dragging and not sender and enabled:
			start_dragging()
		elif not dragging and sender:
			sender.start_dragging()
		#accept_event()
	elif event.is_action_released("primary_input"):
		if dragging:
			stop_dragging()
		elif sender and sender.dragging:
			sender.stop_dragging()
	elif event.is_action_pressed("secondary_input"):
		if reciever and (entity.sleeved_card and reciever.entity.sleeved_card):
			power = !power
		elif not reciever and sender and (entity.sleeved_card and sender.entity.sleeved_card):
			sender.power = !sender.power
		#accept_event()

func start_dragging()-> void:
	dragging = true
	line.start_node = self
	line.end_node = TargetController.cursor
	

func stop_dragging()-> void:
	var target:Control = TargetController.get_target()
	
	if reciever:
		reciever_removed.emit(reciever.entity.sleeve)
		#remove_link(reciever)
	line.points = [Vector2.ZERO]
	line.end_node = null
	dragging = false
	
	
	if not target or target == entity: return
	var card_sleeve:CardSleeve
	
	if target is CardSleeve:
		card_sleeve = target
	elif target is Card:
		if target.has_meta("Sleeve"):
			card_sleeve = target.get_meta("Sleeve") 
			if card_sleeve.sleeve is not SleeveConveyor:return
		
	if not card_sleeve or card_sleeve == entity:return
	var target_conveyor_sleeve:SleeveConveyor = card_sleeve.sleeve
	
	
	if target_conveyor_sleeve.can_add_sender():
		reciever_added.emit(target_conveyor_sleeve)

func add_link(target:ConveyorButton)-> void:
	reciever = target
	target.sender = self
	line.start_node = self
	line.end_node = reciever.line
	

func remove_link(with:ConveyorButton)-> void:
	if not with:return
	power = false
	if sender == with:
		sender = null
		with.remove_link(self)
		
	if reciever == with:
		#reciever_removed.emit(reciever.entity.sleeve)
		reciever = null
		with.remove_link(self)
		line.points = [Vector2.ZERO]
		line.end_node = null

func _process(delta: float) -> void:
	
	var target_node:CanvasItem = sender if sender else reciever
	if not boarder_control: return
	var target_offset: float = 150
	if not target_node and current_offset == target_offset:return
	
	
	# 1. Build the inset rectangle
	var outer_rectangle: Rect2 = boarder_control.get_global_rect()
	var left_bound: float      = outer_rectangle.position.x + INNER_MARGIN
	var top_bound: float       = outer_rectangle.position.y + INNER_MARGIN
	var right_bound: float     = outer_rectangle.position.x + outer_rectangle.size.x - INNER_MARGIN
	var bottom_bound: float    = outer_rectangle.position.y + outer_rectangle.size.y - INNER_MARGIN

	var inset_width: float     = max(right_bound - left_bound, 0.0)
	var inset_height: float    = max(bottom_bound - top_bound, 0.0)

	var inset_rectangle: Rect2 = Rect2(
		Vector2(left_bound, top_bound),
		Vector2(inset_width, inset_height)
	)
	var perimeter_length: float = 2.0 * (inset_width + inset_height)
	
	if target_node:
		target_node = target_node.entity.sleeved_card if target_node.entity.sleeved_card else target_node.entity
		# 2. Find the intersection point of the ray from center → target with this rectangle
		var intersection_point: Vector2 = _compute_perimeter_intersection(inset_rectangle, target_node.global_position+target_node.pivot_offset)

		# 3. Turn that intersection into an offset along the loop
		target_offset = _point_to_offset(inset_rectangle, intersection_point, inset_width, inset_height)

	# 4. March around the loop toward target_offset
	var raw_delta: float = fposmod(target_offset - current_offset + perimeter_length, perimeter_length)
	if raw_delta > perimeter_length * 0.5:
		raw_delta -= perimeter_length

	var step: float = speed * delta * sign(raw_delta)
	if abs(step) > abs(raw_delta):
		step = raw_delta
	
	current_offset = fposmod(current_offset + step, perimeter_length)
	
	# 5. Move to the new perimeter point
	global_position = _offset_to_point(inset_rectangle, current_offset, inset_width, inset_height) - pivot_offset

func _compute_perimeter_intersection(rectangle: Rect2, target_point: Vector2) -> Vector2:
	var center: Vector2 = rectangle.position + rectangle.size * 0.5
	var direction: Vector2 = target_point - center

	var candidate_ts: Array = []
	var candidate_points: Array = []

	# Left edge
	if not is_equal_approx(direction.x, 0.0):
		var t_left: float = (rectangle.position.x - center.x) / direction.x
		if t_left > 0.0:
			var y_left: float = center.y + t_left * direction.y
			if y_left >= rectangle.position.y and y_left <= rectangle.position.y + rectangle.size.y:
				candidate_ts.append(t_left)
				candidate_points.append(center + direction * t_left)
	# Right edge
	if not is_equal_approx(direction.x, 0.0):
		var right_x: float = rectangle.position.x + rectangle.size.x
		var t_right: float = (right_x - center.x) / direction.x
		if t_right > 0.0:
			var y_right: float = center.y + t_right * direction.y
			if y_right >= rectangle.position.y and y_right <= rectangle.position.y + rectangle.size.y:
				candidate_ts.append(t_right)
				candidate_points.append(center + direction * t_right)
	# Top edge
	if not is_equal_approx(direction.y, 0.0):
		var t_top: float = (rectangle.position.y - center.y) / direction.y
		if t_top > 0.0:
			var x_top: float = center.x + t_top * direction.x
			if x_top >= rectangle.position.x and x_top <= rectangle.position.x + rectangle.size.x:
				candidate_ts.append(t_top)
				candidate_points.append(center + direction * t_top)
	# Bottom edge
	if not is_equal_approx(direction.y, 0.0):
		var bottom_y: float = rectangle.position.y + rectangle.size.y
		var t_bottom: float = (bottom_y - center.y) / direction.y
		if t_bottom > 0.0:
			var x_bottom: float = center.x + t_bottom * direction.x
			if x_bottom >= rectangle.position.x and x_bottom <= rectangle.position.x + rectangle.size.x:
				candidate_ts.append(t_bottom)
				candidate_points.append(center + direction * t_bottom)
	# If nothing valid, fallback to center
	if candidate_ts.is_empty():
		return center

	# Choose the intersection with the smallest positive t
	var best_index: int = 0
	var smallest_t: float = candidate_ts[0]

	# This will loop from 1 up to candidate_ts.size()–1,
	# and do nothing if the size is ≤ 1.
	for can_index:int in range(1, candidate_ts.size()):
		if candidate_ts[can_index] < smallest_t:
			smallest_t = candidate_ts[can_index]
			best_index = can_index

	return candidate_points[best_index]

func _point_to_offset(
		rectangle: Rect2,
		perimeter_point: Vector2,
		width: float,
		height: float
	) -> float:
	var local_point: Vector2 = perimeter_point - rectangle.position

	if is_equal_approx(local_point.y, 0.0):
		return clamp(local_point.x, 0.0, width)
	if is_equal_approx(local_point.x, width):
		return width + clamp(local_point.y, 0.0, height)
	if is_equal_approx(local_point.y, height):
		return width + height + clamp(width - local_point.x, 0.0, width)
	# left edge
	return 2.0 * width + height + clamp(height - local_point.y, 0.0, height)

func _offset_to_point(
		rectangle: Rect2,
		offset_value: float,
		width: float,
		height: float
	) -> Vector2:
	var perimeter_length: float = fposmod(offset_value, 2.0 * (width + height))
	var origin: Vector2 = rectangle.position

	if perimeter_length <= width:
		return origin + Vector2(perimeter_length, 0.0)
	elif perimeter_length <= width + height:
		return origin + Vector2(width, perimeter_length - width)
	elif perimeter_length <= 2.0 * width + height:
		return origin + Vector2(
			width - (perimeter_length - (width + height)),
			height
		)
	else:
		return origin + Vector2(
			0.0,
			height - (perimeter_length - (2.0 * width + height))
		)


func stop()->void:
	if tween and tween.is_valid():
		index = 0
		set_frame("spin",index)
		tween.pause()

func spin(duration:float)-> void:
	if tween and tween.is_valid():
		tween.play()
		return
	
	var num_frames:int = frames.get_frame_count("spin")
	var interval:float = duration/(num_frames+1)
	tween = create_tween().set_loops()
	tween.tween_interval(interval)
	tween.loop_finished.connect(func(_count:int)-> void:
		set_frame("spin",index)
		index += 1
		index = index % num_frames
		)

func set_frame(anim:String,f_index:int)-> void:
	texture_normal = frames.get_frame_texture(anim,f_index)
