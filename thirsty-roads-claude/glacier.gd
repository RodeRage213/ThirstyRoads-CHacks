class_name Glacier
extends RefCounted

# =====================================================================
# GLACIER WORLD SCENERY: frost tint, ice cracks, snow piles, ice crystals, icicles
# (the falling snow itself is in snow.gd)
# =====================================================================
static func build_props(level: Node2D, cliffs: Array, finish_x: float, spawn_x: float = -600.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(finish_x) + 23

	# 1) Frosty tint along the top of every cliff, and cracks in the ice
	for poly in cliffs:
		_frost_band(level, poly)
	_cracks(level, cliffs, finish_x, rng)

	# 2) Snow piles and ice crystals on gentle ground
	var x := -820.0
	while x < finish_x + 500.0:
		x += rng.randf_range(150.0, 280.0)
		if absf(x - finish_x) < 160.0 or absf(x - spawn_x) < 110.0:
			continue
		if not _plantable(cliffs, x):
			continue

		var root := Node2D.new()
		root.position = Vector2(x, _ground_y(cliffs, x) + 4.0)
		level.add_child(root)
		var roll := rng.randf()
		if roll < 0.5:
			_snow_pile(root, rng)
		elif roll < 0.85:
			_crystals(root, rng, 2, 4)
		else:
			# a pile with a couple of crystals poking out from behind it
			var back := Node2D.new()
			back.position = Vector2(rng.randf_range(18.0, 34.0), 0.0)
			root.add_child(back)
			_crystals(back, rng, 1, 2)
			_snow_pile(root, rng)

	# 3) Icicles hanging from every ledge that faces a gap
	for i in cliffs.size():
		var pts: PackedVector2Array = cliffs[i]
		if i < cliffs.size() - 1:
			_icicles(level, pts[pts.size() - 1], -1.0, rng)   # gap on the right
		if i > 0:
			_icicles(level, pts[0], 1.0, rng)                  # gap on the left

# ---------------- frost tint + cracks ----------------
static func _frost_band(level: Node2D, top: PackedVector2Array) -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for p in top:
		pts.append(p)
		cols.append(Color(0.88, 0.96, 1.0, 0.6))      # frosty white-blue at the surface
	for i in range(top.size() - 1, -1, -1):
		pts.append(top[i] + Vector2(0.0, 80.0))
		cols.append(Color(0.88, 0.96, 1.0, 0.0))      # fades to nothing 80 px down
	var band := Polygon2D.new()
	band.polygon = pts
	band.vertex_colors = cols
	level.add_child(band)

static func _cracks(level: Node2D, cliffs: Array, finish_x: float, rng: RandomNumberGenerator) -> void:
	var x := -800.0
	while x < finish_x + 500.0:
		x += rng.randf_range(260.0, 520.0)
		if not _plantable(cliffs, x):
			continue
		var line := Line2D.new()
		line.width = 2.0
		line.default_color = Color(0.82, 0.93, 1.0, 0.8)
		line.position = Vector2(x, _ground_y(cliffs, x) + 14.0)
		var pts := PackedVector2Array([Vector2.ZERO])
		var cur := Vector2.ZERO
		for k in 4:
			cur += Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(12.0, 24.0))
			pts.append(cur)
		line.points = pts
		level.add_child(line)

# ---------------- snow piles ----------------
static func _snow_pile(root: Node2D, rng: RandomNumberGenerator) -> void:
	var w := rng.randf_range(46.0, 90.0)
	var h := rng.randf_range(22.0, 42.0)
	_mound(root, w, h, Color("cfe3f0"), Vector2.ZERO)                                   # shaded base
	_mound(root, w * 0.92, h * 0.88, Color("f7fbff"), Vector2(-w * 0.06, -1.0))         # lit top
	for i in 2:                                                                          # sparkles
		Shapes.rect(root, Rect2(rng.randf_range(-w * 0.5, w * 0.4), -h * rng.randf_range(0.3, 0.8), 3.0, 3.0), Color.WHITE)

static func _mound(parent: Node2D, w: float, h: float, color: Color, offset: Vector2) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0      # sweeps left to right over the top
		pts.append(Vector2(cos(a) * w, sin(a) * h))
	pts.append(Vector2(w, 6.0))
	pts.append(Vector2(-w, 6.0))
	var m := Polygon2D.new()
	m.polygon = pts
	m.position = offset
	m.color = color
	parent.add_child(m)

# ---------------- ice crystals ----------------
static func _crystals(root: Node2D, rng: RandomNumberGenerator, n_min: int, n_max: int) -> void:
	var n := rng.randi_range(n_min, n_max)
	var x := -((n - 1) * 14.0) * 0.5
	for i in n:
		var h := rng.randf_range(34.0, 80.0)
		var w := rng.randf_range(9.0, 15.0)
		var c := Node2D.new()
		c.position = Vector2(x + i * 14.0 + rng.randf_range(-3.0, 3.0), 0.0)
		c.rotation = rng.randf_range(-0.3, 0.3)
		root.add_child(c)

		var body := Polygon2D.new()          # mid-blue body
		body.polygon = PackedVector2Array([
			Vector2(-w, 0.0), Vector2(-w, -h * 0.72), Vector2(0.0, -h), Vector2(w, -h * 0.72), Vector2(w, 0.0)])
		body.color = Color("63bfe8")
		c.add_child(body)

		var lit := Polygon2D.new()           # light left face
		lit.polygon = PackedVector2Array([
			Vector2(-w, 0.0), Vector2(-w, -h * 0.72), Vector2(0.0, -h), Vector2(0.0, 0.0)])
		lit.color = Color("a8e3fa")
		c.add_child(lit)

		Shapes.rect(c, Rect2(-w * 0.55, -h * 0.62, 3.0, h * 0.35), Color(1, 1, 1, 0.85))   # glint

# ---------------- icicles ----------------
# dir = -1: the ledge faces right (icicles run left from the edge)
# dir = +1: the ledge faces left  (icicles run right from the edge)
static func _icicles(level: Node2D, edge: Vector2, dir: float, rng: RandomNumberGenerator) -> void:
	var count := rng.randi_range(4, 6)
	for i in count:
		var ln := rng.randf_range(16.0, 46.0)
		var half := rng.randf_range(4.5, 6.5)
		var root := Node2D.new()
		root.position = Vector2(edge.x + dir * (i * 15.0 - 2.0), edge.y + 5.0)
		level.add_child(root)

		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([Vector2(-half, 0.0), Vector2(half, 0.0), Vector2(0.0, ln)])
		body.color = Color("b7ddf0")
		root.add_child(body)

		var lit := Polygon2D.new()
		lit.polygon = PackedVector2Array([Vector2(-half, 0.0), Vector2(0.0, 0.0), Vector2(0.0, ln)])
		lit.color = Color("eefaff")
		root.add_child(lit)

# ---------------- ground helpers ----------------
static func _plantable(cliffs: Array, x: float) -> bool:
	var m := _ground_y(cliffs, x)
	var a := _ground_y(cliffs, x - 30.0)
	var b := _ground_y(cliffs, x + 30.0)
	if is_inf(m) or is_inf(a) or is_inf(b):
		return false
	return absf(b - a) < 22.0

static func _ground_y(cliffs: Array, x: float) -> float:
	for poly in cliffs:
		var pts: PackedVector2Array = poly
		if x < pts[0].x or x > pts[pts.size() - 1].x:
			continue
		for i in range(pts.size() - 1):
			var a := pts[i]
			var b := pts[i + 1]
			if x >= a.x and x <= b.x:
				return lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
	return INF
