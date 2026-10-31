class_name Desert
extends RefCounted

# =====================================================================
# DESERT WORLD SCENERY
#   build_props      -> cacti, rocks, cattle skulls (sit on the ground)
#   build_atmosphere -> blowing dust, tumbleweeds, heat shimmer
# =====================================================================

# ---------------- Tumbleweed: rolls left with the wind, purely decorative ----------------
class Tumbleweed extends Node2D:
	var cliffs: Array = []
	var radius := 28.0
	var speed := 170.0
	var target_y := 0.0

	func setup(cliff_list: Array, start_x: float, r: float, spd: float, rng: RandomNumberGenerator) -> void:
		cliffs = cliff_list
		radius = r
		speed = spd
		position.x = start_x
		var gy := Desert.ground_y(cliffs, start_x)
		target_y = (gy if not is_inf(gy) else 0.0) - radius
		position.y = target_y

		# a tangle of thin brown rings
		var cols := [Color("9c7a4b"), Color("7a5c36"), Color("b08d57")]
		for i in 7:
			var ring := Line2D.new()
			ring.closed = true
			ring.width = 2.5
			ring.default_color = cols[rng.randi() % cols.size()]
			var rx := r * rng.randf_range(0.65, 1.0)
			var ry := r * rng.randf_range(0.65, 1.0)
			var tilt := rng.randf_range(0.0, PI)
			for k in 14:
				var a := TAU * k / 14.0
				var jitter := rng.randf_range(0.88, 1.08)
				ring.add_point(Vector2(cos(a) * rx, sin(a) * ry).rotated(tilt) * jitter)
			add_child(ring)

	func _process(delta: float) -> void:
		var cam := get_viewport().get_camera_2d()
		if cam == null:
			return
		var cam_x := cam.get_screen_center_position().x
		position.x -= speed * delta
		if position.x < cam_x - 1600.0:   # left the screen: re-enter from the right
			position.x = cam_x + 1600.0 + randf_range(0.0, 900.0)
		var gy := Desert.ground_y(cliffs, position.x)
		if not is_inf(gy):                 # over a gap it just keeps gliding at its last height
			target_y = gy - radius - 16.0 * absf(sin(position.x * 0.02)) + 4.0
		position.y = lerpf(position.y, target_y, 1.0 - exp(-14.0 * delta))
		rotation = position.x / radius


# ---------------- Heat shimmer: wobbles the air just above the horizon ----------------
class Shimmer extends CanvasLayer:
	var mat := ShaderMaterial.new()

	func _ready() -> void:
		layer = 3   # above the world, below the HUD
		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float horizon_y = 0.6;
uniform float band = 0.10;
uniform float strength = 0.0018;
void fragment() {
	vec2 uv = SCREEN_UV;
	float d = horizon_y - uv.y;
	float mask = smoothstep(0.0, 0.02, d) * (1.0 - smoothstep(0.0, band, d));
	float wave = sin(uv.y * 160.0 + TIME * 3.0) * 0.6 + sin(uv.y * 70.0 - TIME * 2.0) * 0.4;
	uv.x += wave * strength * mask;
	COLOR = texture(screen_tex, uv);
}
"""
		mat.shader = shader
		var rect := ColorRect.new()
		rect.material = mat
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(_delta: float) -> void:
		var cam := get_viewport().get_camera_2d()
		if cam == null:
			return
		var vp := get_viewport().get_visible_rect().size
		var cy := cam.get_screen_center_position().y
		var screen_y := (0.0 - cy) * cam.zoom.y + vp.y * 0.5   # where world y=0 (the road) is on screen
		mat.set_shader_parameter("horizon_y", screen_y / vp.y)


# =====================================================================
# PROPS (on the ground, behind the truck)
# =====================================================================
static func build_props(level: Node2D, cliffs: Array, finish_x: float, spawn_x: float = -600.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(finish_x) + 11   # different layout per level, same every run
	var skulls := 0

	var x := -820.0
	while x < finish_x + 500.0:
		x += rng.randf_range(150.0, 300.0)
		if absf(x - finish_x) < 160.0 or absf(x - spawn_x) < 110.0:
			continue
		if not plantable(cliffs, x):
			continue

		var root := Node2D.new()
		root.position = Vector2(x, ground_y(cliffs, x) + 6.0)   # +6 = sunk slightly into the sand
		level.add_child(root)
		var roll := rng.randf()
		if roll < 0.36:
			_saguaro(root, rng)
		elif roll < 0.52:
			_barrel(root, rng)
		elif roll < 0.64:
			_prickly_pear(root, rng)
		elif roll < 0.90:
			_rocks(root, rng)
		elif skulls < 2:
			_skull(root, rng)
			skulls += 1
		else:
			_rocks(root, rng)

		# sometimes a small barrel cactus grows next to it
		if rng.randf() < 0.30:
			var bx := x + rng.randf_range(50.0, 80.0)
			if plantable(cliffs, bx):
				var buddy := Node2D.new()
				buddy.position = Vector2(bx, ground_y(cliffs, bx) + 6.0)
				level.add_child(buddy)
				_barrel(buddy, rng)

	# make sure every level has at least one cattle skull
	if skulls == 0:
		var target := finish_x * 0.5
		for off in [0.0, 70.0, -70.0, 140.0, -140.0, 210.0, -210.0, 280.0, -280.0]:
			var sx: float = target + off
			if plantable(cliffs, sx) and absf(sx - finish_x) > 160.0 and absf(sx - spawn_x) > 110.0:
				var sroot := Node2D.new()
				sroot.position = Vector2(sx, ground_y(cliffs, sx) + 6.0)
				level.add_child(sroot)
				_skull(sroot, rng)
				break


# =====================================================================
# ATMOSPHERE (dust, tumbleweeds, heat shimmer)
# =====================================================================
static func build_atmosphere(level: Node2D, vp: Vector2, cliffs: Array) -> void:
	# Blowing dust: far = faint (behind the ground), near = stronger (in front)
	_dust(level, -50, vp, 60, 260.0, 420.0, 3.0, 6.0, Color(0.93, 0.78, 0.52, 0.30))
	_dust(level, 5, vp, 26, 480.0, 760.0, 5.0, 9.0, Color(0.95, 0.82, 0.58, 0.32))

	# Tumbleweeds rolling past
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 3:
		var t := Tumbleweed.new()
		level.add_child(t)
		t.setup(cliffs, -100.0 + i * 800.0, rng.randf_range(22.0, 34.0), rng.randf_range(140.0, 220.0), rng)

	# Heat shimmer (to turn it off, delete or comment out the next line)
	level.add_child(Shimmer.new())

static func _dust(level: Node, layer_index: int, vp: Vector2, amount: int,
		speed_min: float, speed_max: float, scale_min: float, scale_max: float, color: Color) -> void:
	var cl := CanvasLayer.new()
	cl.layer = layer_index
	level.add_child(cl)

	# a tiny white streak texture (20 x 1 pixels) so each dust particle is a thin horizontal line
	var img := Image.create_empty(20, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)

	var p := CPUParticles2D.new()
	p.texture = ImageTexture.create_from_image(img)
	p.position = Vector2(vp.x + 60.0, vp.y * 0.5)            # just off the right edge
	p.amount = amount
	p.lifetime = (vp.x + 200.0) / speed_min                   # long enough to cross the whole screen
	p.preprocess = p.lifetime                                 # already blowing when the level starts
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(10.0, vp.y * 0.5)       # a tall strip along the right edge
	p.direction = Vector2(-1.0, 0.04)                         # blows to the left
	p.spread = 6.0
	p.initial_velocity_min = speed_min
	p.initial_velocity_max = speed_max
	p.gravity = Vector2.ZERO
	p.scale_amount_min = scale_min
	p.scale_amount_max = scale_max
	p.color = color
	p.emitting = true
	cl.add_child(p)


# =====================================================================
# CACTI (y = 0 is the ground)
# =====================================================================
static func _saguaro(root: Node2D, rng: RandomNumberGenerator) -> void:
	var green := Color("3f9b5a")
	var dark := Color("2f7a46")
	var light := Color("5cbf78")
	var h := rng.randf_range(100.0, 160.0)
	var w := 24.0

	Shapes.rect(root, Rect2(-w * 0.5, -h, w, h), green)                       # trunk
	Shapes.rect(root, Rect2(-w * 0.5 + 4.0, -h - 6.0, w - 8.0, 6.0), green)   # rounded top
	Shapes.rect(root, Rect2(-3.0, -h, 6.0, h), dark)                           # centre rib
	Shapes.rect(root, Rect2(-w * 0.5, -h + 4.0, 4.0, h - 4.0), light)         # sunlit edge

	if rng.randf() < 0.85:
		_arm(root, 1.0, -h * rng.randf_range(0.30, 0.50), rng.randf_range(30.0, 55.0), green, dark)
	if rng.randf() < 0.85:
		_arm(root, -1.0, -h * rng.randf_range(0.45, 0.65), rng.randf_range(30.0, 55.0), green, dark)

	if rng.randf() < 0.4:   # flower on top
		Shapes.rect(root, Rect2(-5.0, -h - 13.0, 10.0, 7.0), Color("f06292"))

static func _arm(root: Node2D, side: float, y: float, rise: float, green: Color, dark: Color) -> void:
	var reach := 24.0
	var x0 := 12.0 * side            # trunk edge
	var x1 := x0 + reach * side      # outer end of the arm
	Shapes.rect(root, Rect2(minf(x0, x1), y, reach, 14.0), green)             # sideways part
	var vx := x1 - (14.0 if side > 0.0 else 0.0)
	Shapes.rect(root, Rect2(vx, y - rise, 14.0, rise + 14.0), green)          # upward part
	Shapes.rect(root, Rect2(vx + 4.0, y - rise - 5.0, 6.0, 5.0), green)       # rounded tip
	Shapes.rect(root, Rect2(vx + 5.0, y - rise, 4.0, rise + 14.0), dark)      # rib

static func _barrel(root: Node2D, rng: RandomNumberGenerator) -> void:
	var r := rng.randf_range(20.0, 28.0)
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		pts.append(Vector2(cos(a) * r, sin(a) * r * 0.9))
	var body := Polygon2D.new()
	body.polygon = pts
	body.position = Vector2(0, -r * 0.8)
	body.color = Color("4aa563")
	root.add_child(body)
	for k in [-0.55, -0.2, 0.2, 0.55]:   # ribs
		Shapes.rect(root, Rect2(k * r - 1.5, -r * 1.6 + 4.0, 3.0, r * 1.5), Color("2f7a46"))
	Shapes.rect(root, Rect2(-5.0, -r * 1.7 - 4.0, 10.0, 6.0), Color("f7d046"))   # yellow flower

static func _prickly_pear(root: Node2D, rng: RandomNumberGenerator) -> void:
	var green := Color("56a86a")
	_pad(root, Vector2(0, -14), Vector2(20, 15), 0.0, green)
	_pad(root, Vector2(-20, -40), Vector2(13, 11), -0.5, green)
	_pad(root, Vector2(19, -42), Vector2(12, 10), 0.45, green)
	if rng.randf() < 0.7:
		_pad(root, Vector2(-6, -58), Vector2(11, 9), 0.1, green)
	for p in [Vector2(-30, -52), Vector2(28, -52), Vector2(-6, -68)]:   # red fruit
		Shapes.rect(root, Rect2(p.x - 3.0, p.y - 3.0, 6.0, 6.0), Color("e0457b"))

static func _pad(root: Node2D, pos: Vector2, radii: Vector2, rot: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		pts.append(Vector2(cos(a) * radii.x, sin(a) * radii.y))
	var pad := Polygon2D.new()
	pad.polygon = pts
	pad.position = pos
	pad.rotation = rot
	pad.color = color
	root.add_child(pad)
	for j in 3:   # little spines
		Shapes.rect(pad, Rect2(-radii.x * 0.5 + j * radii.x * 0.5, -2.0 + (j % 2) * 4.0, 3.0, 3.0), Color("f2edc0"))


# =====================================================================
# ROCKS and CATTLE SKULL
# =====================================================================
static func _rocks(root: Node2D, rng: RandomNumberGenerator) -> void:
	var count := rng.randi_range(1, 3)
	var x := 0.0
	for i in count:
		var r := rng.randf_range(10.0, 22.0)
		_rock(root, Vector2(x, 0.0), r, rng)
		x += r * rng.randf_range(1.2, 1.8)

static func _rock(parent: Node2D, pos: Vector2, r: float, rng: RandomNumberGenerator) -> void:
	var tones := [Color("a1785a"), Color("8d6748"), Color("b58b66")]
	var col: Color = tones[rng.randi() % tones.size()]

	var rock := Polygon2D.new()
	rock.polygon = PackedVector2Array([
		Vector2(-r, 0.0), Vector2(-r * 0.85, -r * 0.55), Vector2(-r * 0.35, -r * 0.95),
		Vector2(r * 0.25, -r * 0.9), Vector2(r * 0.8, -r * 0.5), Vector2(r, 0.0)])
	rock.position = pos
	rock.color = col
	parent.add_child(rock)

	var facet := Polygon2D.new()   # lighter top face
	facet.polygon = PackedVector2Array([
		Vector2(-r * 0.85, -r * 0.55), Vector2(-r * 0.35, -r * 0.95), Vector2(r * 0.25, -r * 0.9),
		Vector2(r * 0.8, -r * 0.5), Vector2(0.0, -r * 0.45)])
	facet.position = pos
	facet.color = col.lightened(0.18)
	parent.add_child(facet)

static func _skull(root: Node2D, rng: RandomNumberGenerator) -> void:
	var bone := Color("efe6d2")
	var shade := Color("cdbf9f")
	var dark := Color("3b2f2a")
	root.scale.x = -1.0 if rng.randf() < 0.5 else 1.0

	# horns (drawn first, so the skull overlaps their base)
	for side in [-1.0, 1.0]:
		var horn := Polygon2D.new()
		horn.polygon = PackedVector2Array([
			Vector2(13.0 * side, -30.0), Vector2(26.0 * side, -31.0), Vector2(40.0 * side, -42.0),
			Vector2(46.0 * side, -56.0), Vector2(40.0 * side, -54.0), Vector2(32.0 * side, -41.0),
			Vector2(18.0 * side, -22.0)])
		horn.color = shade
		root.add_child(horn)

	Shapes.rect(root, Rect2(-15.0, -40.0, 30.0, 32.0), bone)      # cranium
	Shapes.rect(root, Rect2(8.0, -40.0, 7.0, 32.0), shade)        # shaded side
	Shapes.rect(root, Rect2(-17.0, -31.0, 34.0, 5.0), shade)      # brow ridge
	Shapes.rect(root, Rect2(-10.0, -12.0, 20.0, 12.0), bone)      # muzzle
	Shapes.rect(root, Rect2(-11.0, -28.0, 8.0, 9.0), dark)        # eye sockets
	Shapes.rect(root, Rect2(3.0, -28.0, 8.0, 9.0), dark)
	Shapes.rect(root, Rect2(-6.0, -6.0, 3.0, 4.0), dark)          # nostrils
	Shapes.rect(root, Rect2(3.0, -6.0, 3.0, 4.0), dark)
	var crack := Line2D.new()
	crack.width = 2.0
	crack.default_color = shade.darkened(0.2)
	crack.points = PackedVector2Array([Vector2(2, -40), Vector2(-2, -34), Vector2(3, -28)])
	root.add_child(crack)


# =====================================================================
# GROUND HELPERS (public: the Tumbleweed class uses them too)
# =====================================================================

# Only place things where there is ground on both sides and the slope is gentle
static func plantable(cliffs: Array, x: float) -> bool:
	var m := ground_y(cliffs, x)
	var a := ground_y(cliffs, x - 30.0)
	var b := ground_y(cliffs, x + 30.0)
	if is_inf(m) or is_inf(a) or is_inf(b):
		return false
	return absf(b - a) < 22.0

static func ground_y(cliffs: Array, x: float) -> float:
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
