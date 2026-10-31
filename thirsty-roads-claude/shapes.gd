class_name Shapes
extends RefCounted

# Adds a flat-coloured rectangle (Polygon2D) to `parent`
static func rect(parent: Node, r: Rect2, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([
		r.position,
		Vector2(r.end.x, r.position.y),
		r.end,
		Vector2(r.position.x, r.end.y),
	])
	p.color = color
	parent.add_child(p)
	return p
