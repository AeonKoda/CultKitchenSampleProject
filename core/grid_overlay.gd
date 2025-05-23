extends Control
class_name GridOverlay

@export var grid_size: int = 18
@export var overlay_radius: float = 150.0  # Desired radius in pixels

var shader_material: ShaderMaterial

func _ready() -> void:
	shader_material = material

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("grid_snap"):
		show()
	elif event.is_action_released("grid_snap"):
		hide()

func _process(_delta: float) -> void:
	if visible:
		var local_mouse_pos: Vector2 = get_viewport().get_mouse_position()
		# Convert to global screen coordinates.
		var final_transform: Transform2D = get_viewport().get_final_transform()
		var global_mouse_pos: Vector2 = final_transform * local_mouse_pos
		
		shader_material.set_shader_parameter("circle_center", global_mouse_pos)
		shader_material.set_shader_parameter("circle_radius", overlay_radius*final_transform.get_scale().x)
		shader_material.set_shader_parameter("control_size", size)

func _draw() -> void:
	# Draw your grid lines over the entire control.
	var grid_color: Color = Color(0.8, 0.8, 0.8, 0.6)
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	
	var start_x: int = int(floor(r.position.x / grid_size)) * grid_size
	var end_x: int = int(r.position.x + r.size.x)
	for x in range(start_x, end_x + grid_size, grid_size):
		draw_line(Vector2(x, r.position.y), Vector2(x, r.position.y + r.size.y), grid_color)
	
	var start_y: int = int(floor(r.position.y / grid_size)) * grid_size
	var end_y: int = int(r.position.y + r.size.y)
	for y in range(start_y, end_y + grid_size, grid_size):
		draw_line(Vector2(r.position.x, y), Vector2(r.position.x + r.size.x, y), grid_color)
