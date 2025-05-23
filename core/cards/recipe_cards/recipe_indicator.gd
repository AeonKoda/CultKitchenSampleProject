extends TextureButton
# Following code is based on the TWEEN ANIMATION PLUGIN by EVILBUNNYMAN obtained
	# on 5/17/25. As such it will be subject to the MIT License
	
	# MIT License
	
	# Copyright (c) 2025 EvilBunnyMan
	
	# Permission is hereby granted, free of charge, to any person obtaining a copy
	# of this software and associated documentation files (the "Software"), to deal
	# in the Software without restriction, including without limitation the rights
	# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	# copies of the Software, and to permit persons to whom the Software is
	# furnished to do so, subject to the following conditions:
	
	# The above copyright notice and this permission notice shall be included in all
	# copies or substantial portions of the Software.
	
	# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	# SOFTWARE.

var jittering:bool = false

func jitter(bounce_scale: float = 1.5, _spin_speed: float = 180.0, duration: float = 0.1) -> void:
	if jittering: return
	jittering = true
	
	var original_scale:Vector2 = scale
	var original_position:Vector2 = position
	var tween:Tween = create_tween()

	
	tween.parallel().tween_property(self, "position", original_position + Vector2(randf_range(-bounce_scale, bounce_scale),randf_range(-bounce_scale, bounce_scale)), duration)

	tween.finished.connect(func()-> void:
		scale = original_scale
		position = original_position
		jittering = false
		)
