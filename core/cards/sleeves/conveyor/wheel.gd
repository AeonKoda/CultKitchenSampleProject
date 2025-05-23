extends TextureRect
var tween:Tween
var index:int = 0
@export var frames:SpriteFrames

func stop()->void:
	if tween and tween.is_valid():
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

func stall(duration:float)-> void:
	if tween and tween.is_valid():
		tween.play()
		return
	
	var num_frames:int = frames.get_frame_count("stall")
	var interval:float = duration/(num_frames+1)
	tween = create_tween().set_loops()
	tween.tween_interval(interval)
	tween.loop_finished.connect(func(_count:int)-> void:
		set_frame("stall",index)
		index += 1
		index = index % num_frames
		)

func set_frame(anim:String,f_index:int)-> void:
	texture = frames.get_frame_texture(anim,f_index)
