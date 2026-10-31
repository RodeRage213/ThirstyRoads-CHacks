class_name Bridge
extends Node2D

const PLANK_COLOR := Color("a8505c")
const POST_COLOR := Color("8a3f4a")

var max_flex := 45.0      # px the middle sinks under the full truck weight
var response := 6.0       # spring speed. Higher = reacts faster. Never bounces.
var impact_gain := 1.0    # extra sag when the truck lands hard on it
var wheels: Array = []    # filled in by Level
var wheel_radius := 34.0
var loaded := false       # true while a wheel is on this bridge

var x_from := 0.0
var x_to := 0.0
var y0 := 0.0
var thickness := 18.0
var count := 8
var planks: Array[StaticBody2D] = []
var node_x := PackedFloat32Array()   # x of each joint point (count + 1)
var defl := PackedFloat32Array()     # current sink (px, downward) at each point
var vel := PackedFloat32Array()      # sink speed at each point

func setup(from_x: float, to_x: float, y: float, flex: float = 45.0, plank_count: int = 8) -> void:
	x_from = from_x
	x_to = to_x
	y0 = y
	max_flex = flex
	count = plank_count

	var mat := PhysicsMaterial.new()
	mat.friction = 1.0
	var spacing := (x_to - x_from) / count

	for i in count + 1:
		node_x.append(lerpf(x_from, x_to, float(i) / count))
		defl.append(0.0)
		vel.append(0.0)

	for i in count:
		var p := StaticBody2D.new()
		p.physics_material_override = mat
		var shape := RectangleShape2D.new()
		shape.size = Vector2(spacing + 4.0, thickness)
		var cs := CollisionShape2D.new()
		cs.shape = shape
		p.add_child(cs)
		var color := PLANK_COLOR if i % 2 == 0 else PLANK_COLOR.darkened(0.15)
		Shapes.rect(p, Rect2(-shape.size * 0.5, shape.size), color)
		add_child(p)
		planks.append(p)

	_apply_pose()

	# Decorative end posts (no collision)
	Shapes.rect(self, Rect2(x_from - 14, y0 - 70, 14, 70), POST_COLOR)
	Shapes.rect(self, Rect2(x_to, y0 - 70, 14, 70), POST_COLOR)

func _physics_process(delta: float) -> void:
	if planks.is_empty():
		return

	var span := x_to - x_from
	var target := PackedFloat32Array()
	target.resize(count + 1)
	loaded = false

	# Work out how far each point should sink, from the wheels that are on the bridge
	for w in wheels:
		var wx: float = w.global_position.x
		if wx <= x_from or wx >= x_to:
			continue
		var bottom: float = w.global_position.y + wheel_radius
		var surf := _surface_y(wx)
		if bottom < surf - 24.0 or bottom > surf + 40.0:
			continue   # wheel is in the air above the bridge, or far below it
		loaded = true
		var load_factor := 1.0 + clampf(w.linear_velocity.y / 700.0, 0.0, 1.5) * impact_gain
		var a := wx - x_from
		for i in count + 1:
			var x := node_x[i] - x_from
			var g := x * (span - a) / span if x <= a else a * (span - x) / span
			target[i] += max_flex * 0.5 * load_factor * g / (span * 0.25)

	# Critically damped spring toward the target: smooth, elastic, no bounce
	var k := response * response
	var c := 2.0 * response
	for i in range(1, count):   # end points stay fixed on the cliffs
		var t := minf(target[i], max_flex * 2.0)
		vel[i] += (k * (t - defl[i]) - c * vel[i]) * delta
		defl[i] += vel[i] * delta

	_apply_pose()

func _surface_y(x: float) -> float:
	var t := clampf((x - x_from) / (x_to - x_from), 0.0, 1.0) * count
	var i := mini(int(t), count - 1)
	return y0 + lerpf(defl[i], defl[i + 1], t - i)

func _apply_pose() -> void:
	var cy := y0 + thickness * 0.5
	for i in count:
		var a := Vector2(node_x[i], cy + defl[i])
		var b := Vector2(node_x[i + 1], cy + defl[i + 1])
		planks[i].position = (a + b) * 0.5
		planks[i].rotation = (b - a).angle()
