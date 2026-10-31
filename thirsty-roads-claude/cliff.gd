class_name Cliff
extends StaticBody2D

const CLIFF_COLOR := Color("f4b9a5")
const GRASS_COLOR := Color("4cd964")
const PLANK_COLOR := Color("a8505c")
const PLANK_EDGE_COLOR := Color("8a3f4a")
const GRASS_THICKNESS := 22.0
const RAMP_PLANK_LENGTH := 32.0
const RAMP_PLANK_THICKNESS := 18.0

# top_points: left-to-right surface points (x strictly increasing)
func setup(top_points: PackedVector2Array, depth: float = 1400.0) -> void:
	var mat := PhysicsMaterial.new()
	mat.friction = 1.0
	physics_material_override = mat

	var poly := PackedVector2Array(top_points) # copy
	poly.append(Vector2(top_points[-1].x, top_points[-1].y + depth))
	poly.append(Vector2(top_points[0].x, top_points[0].y + depth))

	var col := CollisionPolygon2D.new()
	col.polygon = poly
	add_child(col)

	var fill := Polygon2D.new()
	fill.polygon = poly
	fill.color = CLIFF_COLOR
	add_child(fill)

	_draw_surface_features(top_points)

func _draw_surface_features(top_points: PackedVector2Array) -> void:
	for i in range(top_points.size() - 1):
		var p1 := top_points[i]
		var p2 := top_points[i + 1]
		var dir := p2 - p1
		var length := dir.length()
		if length < 0.1:
			continue

		var angle := dir.angle()
		# Segment is treated as a wooden ramp if it has significant incline/decline
		var is_ramp := absf(angle) > 0.12

		if is_ramp:
			_build_wooden_ramp_segment(p1, p2, dir, length)
		else:
			_build_grass_segment(p1, p2)

func _build_wooden_ramp_segment(p1: Vector2, p2: Vector2, dir: Vector2, length: float) -> void:
	var norm := dir.normalized()
	var perp := Vector2(-norm.y, norm.x) # upward normal
	var plank_count := maxi(1, int(length / RAMP_PLANK_LENGTH))
	var step := length / float(plank_count)

	for j in plank_count:
		var seg_start := p1 + norm * (j * step)
		var seg_end := p1 + norm * ((j + 1) * step)
		var center := (seg_start + seg_end) * 0.5
		
		var plank_node := Node2D.new()
		plank_node.position = center
		plank_node.rotation = dir.angle()
		add_child(plank_node)

		var color := PLANK_COLOR if j % 2 == 0 else PLANK_COLOR.darkened(0.12)
		var size := Vector2(step + 2.0, RAMP_PLANK_THICKNESS)
		
		# Main plank rectangle
		Shapes.rect(plank_node, Rect2(-size * 0.5, size), color)
		# Edge highlight trim to match Drive Mad wooden plank look
		Shapes.rect(plank_node, Rect2(-size.x * 0.5, -size.y * 0.5, size.x, 3.0), PLANK_EDGE_COLOR)

func _build_grass_segment(p1: Vector2, p2: Vector2) -> void:
	var grass := Line2D.new()
	grass.points = PackedVector2Array([p1, p2])
	grass.width = GRASS_THICKNESS
	grass.default_color = GRASS_COLOR
	grass.position.y = GRASS_THICKNESS * 0.5  # top edge of grass = surface
	add_child(grass)
