class_name Urban
extends RefCounted

# ---------------------------------------------------------------
# BACKGROUND: hazy apartment blocks (far) + shanty rooftops (near)
# ---------------------------------------------------------------
static func build_background(level: Node2D, base: Color) -> void:
	var parallax := ParallaxBackground.new()
	level.add_child(parallax)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33

	# Far layer: tall apartment blocks with lit windows
	var far := ParallaxLayer.new()
	far.motion_scale = Vector2(0.15, 0.15)
	parallax.add_child(far)
	var far_col := base.lightened(0.25)
	var x := -2200.0
	while x < 3000.0:
		var w := rng.randf_range(130.0, 230.0)
		var h := rng.randf_range(260.0, 560.0)
		var top := 150.0 - h
		Shapes.rect(far, Rect2(x, top, w, h + 1100.0), far_col)
		var wy := top + 24.0
		while wy < 100.0:
			var wx := x + 16.0
			while wx < x + w - 24.0:
				if rng.randf() < 0.22:
					Shapes.rect(far, Rect2(wx, wy, 14.0, 18.0), Color(1.0, 0.85, 0.45, 0.85))
				elif rng.randf() < 0.5:
					Shapes.rect(far, Rect2(wx, wy, 14.0, 18.0), far_col.darkened(0.12))
				wx += 30.0
			wy += 40.0
		x += w + rng.randf_range(8.0, 40.0)

	# Near layer: crowded shanty rooftops
	var near := ParallaxLayer.new()
	near.motion_scale = Vector2(0.4, 0.4)
	parallax.add_child(near)
	var near_col := base.darkened(0.2)
	var tin := near_col.darkened(0.3)
	x = -1800.0
	while x < 3200.0:
		var w := rng.randf_range(90.0, 170.0)
		var h := rng.randf_range(60.0, 150.0)
		var top := 60.0 - h
		Shapes.rect(near, Rect2(x, top, w, h + 1100.0), near_col)
		Shapes.rect(near, Rect2(x - 6.0, top - 8.0, w + 12.0, 8.0), tin)
		var roll := rng.randf()
		if roll < 0.25:   # rooftop water tank
			Shapes.rect(near, Rect2(x + w * 0.5, top - 34.0, 28.0, 26.0), Color("3d6f94"))
		elif roll < 0.5:  # TV antenna
			Shapes.rect(near, Rect2(x + w * 0.3, top - 48.0, 3.0, 40.0), tin)
			Shapes.rect(near, Rect2(x + w * 0.3 - 9.0, top - 42.0, 21.0, 3.0), tin)
			Shapes.rect(near, Rect2(x + w * 0.3 - 6.0, top - 32.0, 15.0, 3.0), tin)
		x += w * rng.randf_range(0.7, 1.0)

# ---------------------------------------------------------------
# PROPS: houses, laundry, water points, clutter, poles, road detail
# ---------------------------------------------------------------
static func build_props(level: Node2D, cliffs: Array, finish_x: float, fill_color: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77

	# Road details: slab joints, cracks, puddles
	var seam := fill_color.darkened(0.22)
	var sx := -880.0
	while sx < finish_x + 600.0:
		if _is_flat(cliffs, sx, 20.0):
			var sy := _ground_y(cliffs, sx)
			Shapes.rect(level, Rect2(sx - 1.5, sy + 8.0, 3.0, 70.0), seam)
			if rng.randf() < 0.4:
				_crack(level, Vector2(sx + 30.0, sy + 14.0), seam)
			elif rng.randf() < 0.3:
				_puddle(level, Vector2(sx + 60.0, sy + 1.0), rng.randf_range(70.0, 130.0))
		sx += 140.0

	# Houses and street props (only on flat ground, never over gaps)
	var x := -700.0
	while x < finish_x + 500.0:
		if _is_flat(cliffs, x, 110.0):
			var root := Node2D.new()
			root.position = Vector2(x, _ground_y(cliffs, x))
			if rng.randf() < 0.5:
				root.scale.x = -1.0   # mirror for variety
			level.add_child(root)
			var roll := rng.randf()
			if roll < 0.40:
				_shack(root, rng)
			elif roll < 0.55:
				_laundry(root, rng)
			elif roll < 0.70:
				_water_point(root)
			elif roll < 0.85:
				_clutter(root)
			else:
				_wall(root, rng)
		x += rng.randf_range(170.0, 250.0)

	# Power poles and wires (wires also cross the gaps)
	var tops: Array[Vector2] = []
	var px := -650.0
	while px < finish_x + 600.0:
		if _is_flat(cliffs, px, 14.0):
			var base_y := _ground_y(cliffs, px)
			_pole(level, Vector2(px, base_y))
			tops.append(Vector2(px, base_y - 292.0))
		px += 520.0
	for i in range(tops.size() - 1):
		_wire(level, tops[i], tops[i + 1], 0.0)
		_wire(level, tops[i], tops[i + 1], 30.0)

# ---------------------------------------------------------------
# Individual props (all drawn with y = 0 at the road surface)
# ---------------------------------------------------------------
static func _shack(root: Node2D, rng: RandomNumberGenerator) -> void:
	var walls := [Color("8d6e63"), Color("6f8f9d"), Color("a58b5b"), Color("7d8f69"), Color("b5655c"), Color("9a7fa6")]
	var roofs := [Color("7f8c8d"), Color("a0522d"), Color("95a5a6"), Color("8e6e53")]
	var w := rng.randf_range(120.0, 190.0)
	var h := rng.randf_range(90.0, 150.0)
	var wall: Color = walls[rng.randi() % walls.size()]
	var roof: Color = roofs[rng.randi() % roofs.size()]
	var l := -w * 0.5

	# walls with patched panels
	Shapes.rect(root, Rect2(l, -h, w, h), wall)
	Shapes.rect(root, Rect2(l, -h, w * 0.35, h * 0.55), wall.lightened(0.12))
	Shapes.rect(root, Rect2(l + w * 0.6, -h * 0.5, w * 0.4, h * 0.5), wall.darkened(0.12))

	# corrugated tin roof
	Shapes.rect(root, Rect2(l - 10.0, -h - 14.0, w + 20.0, 14.0), roof)
	var rx := l - 8.0
	while rx < l + w + 8.0:
		Shapes.rect(root, Rect2(rx, -h - 14.0, 3.0, 14.0), roof.darkened(0.3))
		rx += 9.0

	# door and lit window
	Shapes.rect(root, Rect2(l + w * 0.12, -h * 0.62, w * 0.2, h * 0.62), Color("3e2f28"))
	Shapes.rect(root, Rect2(l + w * 0.55, -h * 0.78, w * 0.26, h * 0.26), Color("2c3e50"))
	Shapes.rect(root, Rect2(l + w * 0.58, -h * 0.75, w * 0.2, h * 0.2), Color(1.0, 0.85, 0.45, 0.85))

	# rooftop extras
	var top := -h - 14.0
	var roll := rng.randf()
	if roll < 0.35:      # water tank on stilts
		var tx := l + w * 0.5
		Shapes.rect(root, Rect2(tx + 4.0, top - 10.0, 4.0, 10.0), Color("2b2b2b"))
		Shapes.rect(root, Rect2(tx + 32.0, top - 10.0, 4.0, 10.0), Color("2b2b2b"))
		Shapes.rect(root, Rect2(tx, top - 42.0, 40.0, 32.0), Color("2e86c1"))
		Shapes.rect(root, Rect2(tx, top - 30.0, 40.0, 4.0), Color("1b5e8a"))
	elif roll < 0.6:     # TV antenna
		var ax := l + w * 0.3
		Shapes.rect(root, Rect2(ax, top - 44.0, 3.0, 44.0), Color("2b2b2b"))
		Shapes.rect(root, Rect2(ax - 10.0, top - 38.0, 23.0, 3.0), Color("2b2b2b"))
		Shapes.rect(root, Rect2(ax - 7.0, top - 28.0, 17.0, 3.0), Color("2b2b2b"))
	elif roll < 0.8:     # chimney with smoke
		var cx := l + w * 0.2
		Shapes.rect(root, Rect2(cx, top - 28.0, 12.0, 28.0), Color("4a3f3a"))
		_smoke(root, Vector2(cx + 6.0, top - 28.0))
	else:                # tyres weighing the roof down
		for i in range(3):
			Shapes.rect(root, Rect2(l + w * 0.6 + i * 6.0, top - 12.0 * (i + 1), 30.0, 12.0), Color("1e1e1e"))

static func _laundry(root: Node2D, rng: RandomNumberGenerator) -> void:
	var span := rng.randf_range(110.0, 170.0)
	var h := 110.0
	var pole := Color("5d4a3f")
	Shapes.rect(root, Rect2(-span * 0.5 - 3.0, -h, 6.0, h), pole)
	Shapes.rect(root, Rect2(span * 0.5 - 3.0, -h, 6.0, h), pole)
	var rope := Line2D.new()
	rope.width = 2.0
	rope.default_color = Color("2b2b2b")
	for i in range(9):
		var t := i / 8.0
		rope.add_point(Vector2(lerpf(-span * 0.5, span * 0.5, t), -h + 6.0 + sin(t * PI) * 10.0))
	root.add_child(rope)
	var cols := [Color("e74c3c"), Color("f1c40f"), Color("ecf0f1"), Color("3498db"), Color("2ecc71")]
	for i in range(4):
		var t := (i + 0.7) / 4.4
		var cx := lerpf(-span * 0.5, span * 0.5, t)
		var cy := -h + 6.0 + sin(t * PI) * 10.0
		var cw := rng.randf_range(12.0, 20.0)
		var ch := rng.randf_range(18.0, 34.0)
		Shapes.rect(root, Rect2(cx - cw * 0.5, cy, cw, ch), cols[rng.randi() % cols.size()])

static func _water_point(root: Node2D) -> void:
	# concrete base, standpipe and tap
	Shapes.rect(root, Rect2(-18.0, -14.0, 36.0, 14.0), Color("8a8d8f"))
	Shapes.rect(root, Rect2(-4.0, -90.0, 8.0, 76.0), Color("6c7a89"))
	Shapes.rect(root, Rect2(-4.0, -90.0, 30.0, 7.0), Color("6c7a89"))
	Shapes.rect(root, Rect2(20.0, -84.0, 6.0, 12.0), Color("2e86c1"))
	# dripping leak
	var drip := CPUParticles2D.new()
	drip.position = Vector2(23.0, -72.0)
	drip.amount = 5
	drip.lifetime = 0.55
	drip.direction = Vector2(0, 1)
	drip.spread = 5.0
	drip.initial_velocity_min = 10.0
	drip.initial_velocity_max = 20.0
	drip.gravity = Vector2(0, 900)
	drip.scale_amount_min = 2.0
	drip.scale_amount_max = 3.5
	drip.color = Color("5fd3ff")
	root.add_child(drip)
	_puddle(root, Vector2(24.0, 1.0), 70.0)
	# queue of jerrycans waiting for water
	var can_cols := [Color("f1c40f"), Color("2e86c1"), Color("e67e22"), Color("27ae60")]
	for i in range(5):
		var cx := 50.0 + i * 24.0
		Shapes.rect(root, Rect2(cx, -22.0, 16.0, 22.0), can_cols[i % 4])
		Shapes.rect(root, Rect2(cx + 4.0, -27.0, 8.0, 5.0), can_cols[i % 4].darkened(0.3))

static func _clutter(root: Node2D) -> void:
	# oil drum
	Shapes.rect(root, Rect2(-62.0, -38.0, 28.0, 38.0), Color("a0522d"))
	Shapes.rect(root, Rect2(-62.0, -28.0, 28.0, 4.0), Color("6e2c0f"))
	Shapes.rect(root, Rect2(-62.0, -12.0, 28.0, 4.0), Color("6e2c0f"))
	# stacked crates
	Shapes.rect(root, Rect2(-24.0, -34.0, 34.0, 34.0), Color("b08d57"))
	Shapes.rect(root, Rect2(-24.0, -34.0, 34.0, 4.0), Color("7d6335"))
	Shapes.rect(root, Rect2(-16.0, -62.0, 26.0, 28.0), Color("c19a62"))
	# trash bags
	for i in range(2):
		var pts := PackedVector2Array()
		for k in range(10):
			var a := TAU * k / 10.0
			pts.append(Vector2(cos(a) * 17.0, sin(a) * 13.0))
		var bag := Polygon2D.new()
		bag.polygon = pts
		bag.position = Vector2(34.0 + i * 26.0, -13.0)
		bag.color = Color("2f3b2f")
		root.add_child(bag)
	# tyre stack
	for i in range(3):
		Shapes.rect(root, Rect2(88.0, -14.0 * (i + 1), 32.0, 14.0), Color("1e1e1e"))

static func _wall(root: Node2D, rng: RandomNumberGenerator) -> void:
	var w := 170.0
	var h := 120.0
	Shapes.rect(root, Rect2(-w * 0.5, -h, w, h), Color("9a9a96"))
	Shapes.rect(root, Rect2(-w * 0.5, -h, w, 8.0), Color("7b7b77"))
	var cols := [Color("e74c3c"), Color("f1c40f"), Color("9b59b6"), Color("27ae60")]
	for i in range(3):
		var gx := -w * 0.5 + 14.0 + i * 52.0
		var gh := rng.randf_range(20.0, 36.0)
		Shapes.rect(root, Rect2(gx, -h + 24.0 + rng.randf_range(0.0, 24.0), 38.0, gh), cols[rng.randi() % cols.size()])
	# a blue water-drop tag
	var drop := Polygon2D.new()
	drop.polygon = PackedVector2Array([Vector2(0, -22), Vector2(14, 6), Vector2(0, 18), Vector2(-14, 6)])
	drop.position = Vector2(0, -30)
	drop.color = Color("5fd3ff")
	root.add_child(drop)

static func _smoke(parent: Node2D, pos: Vector2) -> void:
	var smoke := CPUParticles2D.new()
	smoke.position = pos
	smoke.amount = 10
	smoke.lifetime = 2.5
	smoke.direction = Vector2(0.3, -1.0)
	smoke.spread = 15.0
	smoke.initial_velocity_min = 20.0
	smoke.initial_velocity_max = 40.0
	smoke.gravity = Vector2(10.0, -10.0)
	smoke.scale_amount_min = 6.0
	smoke.scale_amount_max = 14.0
	var g := Gradient.new()
	g.set_color(0, Color(0.5, 0.5, 0.5, 0.6))
	g.set_color(1, Color(0.5, 0.5, 0.5, 0.0))
	smoke.color_ramp = g
	parent.add_child(smoke)

static func _pole(level: Node2D, base: Vector2) -> void:
	var c := Color("3b2f2a")
	Shapes.rect(level, Rect2(base.x - 5.0, base.y - 300.0, 10.0, 300.0), c)
	Shapes.rect(level, Rect2(base.x - 36.0, base.y - 296.0, 72.0, 6.0), c)
	Shapes.rect(level, Rect2(base.x - 26.0, base.y - 266.0, 52.0, 5.0), c)

static func _wire(level: Node2D, a: Vector2, b: Vector2, y_offset: float) -> void:
	var line := Line2D.new()
	line.width = 2.5
	line.default_color = Color("2b2b2b")
	var sag := a.distance_to(b) * 0.06
	for i in range(13):
		var t := i / 12.0
		var p := a.lerp(b, t)
		p.y += y_offset + sin(t * PI) * sag
		line.add_point(p)
	level.add_child(line)

static func _crack(level: Node2D, pos: Vector2, color: Color) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = color
	line.position = pos
	line.points = PackedVector2Array([Vector2(0, 0), Vector2(8, 14), Vector2(1, 28), Vector2(12, 46), Vector2(6, 60)])
	level.add_child(line)

static func _puddle(parent: Node, pos: Vector2, width: float) -> void:
	var pts := PackedVector2Array()
	for i in range(12):
		var a := TAU * i / 12.0
		pts.append(Vector2(cos(a) * width * 0.5, sin(a) * 4.0))
	var p := Polygon2D.new()
	p.polygon = pts
	p.position = pos
	p.color = Color(0.45, 0.65, 0.8, 0.75)
	parent.add_child(p)

# ---------------------------------------------------------------
# Ground helpers (so props only sit on flat road, never over gaps)
# ---------------------------------------------------------------
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

static func _is_flat(cliffs: Array, x: float, half: float) -> bool:
	var m := _ground_y(cliffs, x)
	var a := _ground_y(cliffs, x - half)
	var b := _ground_y(cliffs, x + half)
	if is_inf(m) or is_inf(a) or is_inf(b):
		return false
	return absf(a - m) < 6.0 and absf(b - m) < 6.0
