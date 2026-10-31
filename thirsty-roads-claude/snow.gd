class_name Snow
extends RefCounted

# Two layers of falling snow drawn on the screen (they ignore the camera):
#  far  = behind the ground and truck, small and slow
#  near = in front of everything except the HUD, bigger and faster
static func build(level: Node, viewport_size: Vector2) -> void:
	_layer(level, -50, viewport_size, 200, 2.0, 4.0, 60.0, 100.0, Color(1, 1, 1, 0.55))
	_layer(level, 5, viewport_size, 70, 4.0, 7.0, 130.0, 190.0, Color(1, 1, 1, 0.9))

static func _layer(level: Node, layer_index: int, vp: Vector2, amount: int,
		size_min: float, size_max: float, speed_min: float, speed_max: float,
		color: Color) -> void:
	var cl := CanvasLayer.new()
	cl.layer = layer_index
	level.add_child(cl)

	var p := CPUParticles2D.new()
	p.position = Vector2(vp.x * 0.5, -30.0)
	p.amount = amount
	p.lifetime = (vp.y + 120.0) / speed_min        # long enough to cross the whole screen
	p.preprocess = p.lifetime                       # snow is already falling when the level starts
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x, 4.0)    # wide strip above the screen
	p.direction = Vector2(-0.3, 1.0).normalized()   # slants left, like wind
	p.spread = 12.0
	p.initial_velocity_min = speed_min
	p.initial_velocity_max = speed_max
	p.gravity = Vector2.ZERO
	p.scale_amount_min = size_min                   # flakes are small squares (blocky style)
	p.scale_amount_max = size_max
	p.color = color
	p.emitting = true
	cl.add_child(p)
