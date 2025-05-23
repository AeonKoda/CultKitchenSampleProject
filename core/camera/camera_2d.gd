extends Camera2D

@export var zoom_speed: float = 0.1
@export var min_zoom: Vector2 = Vector2(0.5, 0.5)
@export var max_zoom: Vector2 = Vector2(2, 2)
@export var buffer:float = 300
var third_eye:bool = true


var is_dragging: bool = false
var last_mouse_position: Vector2
var drag_speed:float = 1
var starting_position:Vector2
var menu_pos:Vector2

func _ready() -> void:
	var viewport_size:Vector2 = Global.VIEWPORT_SIZE
	starting_position = viewport_size * Vector2(0.5,0.5)
	#menu_pos = viewport_size * Vector2(0.5,-0.5)
	#global_position = menu_pos

func _unhandled_input(event: InputEvent) -> void:
	if third_eye:
		if event.is_action_pressed("mouse_middle"):
			last_mouse_position = get_global_mouse_position()
			Input.set_default_cursor_shape(Input.CURSOR_CAN_DROP)
			if event.double_click:
				var tween:Tween = create_tween()
				tween.tween_property(self,"global_position",starting_position,0.5)
				#tween.tween_property(self,"zoom",Vector2.ONE,0.5).set_ease(Tween.EASE_OUT)#.set_trans(Tween.TRANS_QUART)
		if event.is_action_released("mouse_middle"):
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)

		
		elif event is InputEventMouseMotion and Input.is_action_pressed("mouse_middle"):
			var new_position:Vector2 = position - (get_global_mouse_position()-last_mouse_position)*drag_speed
			position = Vector2(clampf(new_position.x,starting_position.x-buffer,starting_position.x+
			buffer),clampf(new_position.y,starting_position.y-buffer,starting_position.y+buffer))

			last_mouse_position = get_global_mouse_position()
