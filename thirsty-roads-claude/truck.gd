class_name Truck
extends Node2D

signal water_changed(value: float)
signal failed(reason: String)

@export var engine_torque := 90000.0
@export var lean_torque := 35000.0
@export var max_wheel_speed := 36.0
@export var jolt_threshold := 6500.0
@export var spill_rate := 0.0012
@export var wheel_radius := 34.0
@export var fall_y := 450.0

@export var bridge_strain_time := 1.0
@export var bridge_tip_torque := 450000.0
@export var bridge_tip_angle := 1.15

var body: RigidBody2D
var wheel_back: RigidBody2D
var wheel_front: RigidBody2D
var chassis: Polygon2D
var tank: Polygon2D
var splash: CPUParticles2D
var engine_player: AudioStreamPlayer

var water := 100.0
var active := false
var alive := true
var on_bridge := false
var strain := 0.0
var grace := 1.0
var flip_time := 0.0
var last_velocity := Vector2.ZERO

var car_type := "classic"
var nitro_available := false
var nitro_active := false
var nitro_timer := 0.0
var nitro_cooldown_timer := 0.0

func setup_stats(type: String, accel_tier: int, control_tier: int) -> void:
	car_type = type
	var body_color := Color("f5c518")

	match type:
		"classic":
			engine_torque = 90000.0
			lean_torque = 35000.0
			max_wheel_speed = 36.0
			spill_rate = 0.0012
			nitro_available = false
			body_color = Color("f5c518")
		"heavy_tanker":
			engine_torque = 70000.0
			lean_torque = 25000.0
			max_wheel_speed = 30.0
			spill_rate = 0.0006
			nitro_available = false
			body_color = Color("3b5998")
		"speed_rover":
			engine_torque = 120000.0
			lean_torque = 50000.0
			max_wheel_speed = 46.0
			spill_rate = 0.0015
			nitro_available = false
			body_color = Color("e74c3c")
		"nitro_jet":
			engine_torque = 95000.0
			lean_torque = 35000.0
			max_wheel_speed = 38.0
			spill_rate = 0.0012
			nitro_available = true
			body_color = Color("9b59b6")

	if body:
		body.mass = 4.0 if type == "heavy_tanker" else 3.0
	if chassis:
		chassis.color = body_color

	engine_torque += accel_tier * 8000.0
	max_wheel_speed += accel_tier * 2.5
	lean_torque = maxf(15000.0, lean_torque - control_tier * 4000.0)

func build(spawn: Vector2) -> void:
	body = _make_body(spawn, 3.0)
	var box := RectangleShape2D.new()
	box.size = Vector2(160, 50)
	var box_cs := CollisionShape2D.new()
	box_cs.shape = box
	body.add_child(box_cs)
	_build_body_visuals()

	var back_pos := spawn + Vector2(-55, 25)
	var front_pos := spawn + Vector2(55, 25)
	wheel_back = _make_wheel(back_pos)
	wheel_front = _make_wheel(front_pos)
	_pin(back_pos, body, wheel_back)
	_pin(front_pos, body, wheel_front)

	_build_splash()
	_build_camera()
	_setup_engine_audio()

func _setup_engine_audio() -> void:
	if SoundFX.engine_stream:
		engine_player = AudioStreamPlayer.new()
		engine_player.stream = SoundFX.engine_stream
		engine_player.volume_db = -6.0
		engine_player.autoplay = false
		add_child(engine_player)

func set_active(value: bool) -> void:
	active = value
	grace = 1.0
	last_velocity = body.linear_velocity

func finish() -> void:
	active = false
	strain = 0.0
	body.linear_damp = 1.5
	wheel_back.angular_damp = 2.0
	wheel_front.angular_damp = 2.0
	if engine_player and engine_player.playing:
		engine_player.stop()

func trigger_nitro() -> bool:
	if car_type == "nitro_jet" and not nitro_active and nitro_cooldown_timer <= 0.0:
		nitro_active = true
		nitro_timer = 5.0
		nitro_cooldown_timer = 10.0
		return true
	return false

func _physics_process(delta: float) -> void:
	if not alive or not active:
		if engine_player and engine_player.playing:
			engine_player.stop()
		return

	if body.global_position.y > fall_y:
		_fail("You fell in the river!")
		return

	if nitro_cooldown_timer > 0.0:
		nitro_cooldown_timer -= delta

	var current_spill := spill_rate
	if nitro_active:
		nitro_timer -= delta
		body.apply_central_force(Vector2(6500.0, -400.0))
		current_spill = 0.0
		if nitro_timer <= 0.0:
			nitro_active = false

	# Drive input
	var dir := Input.get_axis("brake", "accelerate")

	# Engine audio pitch dynamic bending
	if engine_player and SoundFX.engine_stream:
		if dir > 0.0:
			if not engine_player.playing:
				engine_player.play()
			var speed := body.linear_velocity.length()
			engine_player.pitch_scale = lerpf(engine_player.pitch_scale, 0.8 + (speed / 600.0), 0.1)
		else:
			if engine_player.playing:
				engine_player.stop()

	if dir != 0.0:
		for w in [wheel_back, wheel_front]:
			if dir * w.angular_velocity < max_wheel_speed:
				w.apply_torque(dir * engine_torque)
		body.apply_torque(-dir * lean_torque)

	# Bridge hazard handling
	if on_bridge:
		var rate := 1.0 / bridge_strain_time
		if dir != 0.0:
			if strain != 0.0 and signf(dir) != signf(strain):
				rate *= 3.0
			strain = clampf(strain + dir * rate * delta, -1.0, 1.0)
		else:
			strain = move_toward(strain, 0.0, 2.0 * delta)
		body.apply_torque(-signf(strain) * strain * strain * bridge_tip_torque)

		if absf(wrapf(body.rotation, -PI, PI)) > bridge_tip_angle:
			if absf(strain) > 0.5:
				_fail("You hit the gas too hard on the bridge!")
			else:
				_fail("You tipped over on the bridge!")
			return
	else:
		strain = move_toward(strain, 0.0, 4.0 * delta)

	# Water spilling physics
	var accel := (body.linear_velocity - last_velocity).length() / delta
	last_velocity = body.linear_velocity
	if grace > 0.0:
		grace -= delta
	elif accel > jolt_threshold and current_spill > 0.0:
		_spill((accel - jolt_threshold) * current_spill)
		if not alive:
			return

	# Flip check
	if absf(wrapf(body.rotation, -PI, PI)) > 2.2:
		flip_time += delta
		if flip_time > 1.2:
			_fail("The truck flipped!")
	else:
		flip_time = 0.0

func _process(_delta: float) -> void:
	if tank:
		tank.scale.y = lerpf(tank.scale.y, maxf(water / 100.0, 0.02), 0.15)

func _spill(amount: float) -> void:
	water = maxf(water - amount, 0.0)
	water_changed.emit(water)
	if amount > 0.3:
		splash.restart()
	if water <= 0.0:
		_fail("You ran out of water!")

func _fail(reason: String) -> void:
	if not alive:
		return
	alive = false
	active = false
	if engine_player and engine_player.playing:
		engine_player.stop()
	failed.emit(reason)

func _make_body(pos: Vector2, mass_value: float) -> RigidBody2D:
	var rb := RigidBody2D.new()
	rb.position = pos
	rb.mass = mass_value
	rb.can_sleep = false
	add_child(rb)
	return rb

func _make_wheel(pos: Vector2) -> RigidBody2D:
	var w := _make_body(pos, 1.0)
	var mat := PhysicsMaterial.new()
	mat.friction = 1.0
	mat.bounce = 0.0
	w.physics_material_override = mat

	var shape := CircleShape2D.new()
	shape.radius = wheel_radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	w.add_child(cs)

	var tyre_pts := PackedVector2Array()
	var hub_pts := PackedVector2Array()
	for i in 8:
		var v := Vector2.RIGHT.rotated(TAU * i / 8.0 + PI / 8.0)
		tyre_pts.append(v * wheel_radius * 1.05)
		hub_pts.append(v * wheel_radius * 0.5)
	var tyre := Polygon2D.new()
	tyre.polygon = tyre_pts
	tyre.color = Color("222222")
	w.add_child(tyre)
	var hub := Polygon2D.new()
	hub.polygon = hub_pts
	hub.color = Color("bdbdbd")
	w.add_child(hub)
	Shapes.rect(w, Rect2(-wheel_radius * 0.8, -4, wheel_radius * 1.6, 8), Color("e8e8e8"))
	return w

func _pin(pos: Vector2, a: Node2D, b: Node2D) -> void:
	var j := PinJoint2D.new()
	j.position = pos
	add_child(j)
	j.node_a = j.get_path_to(a)
	j.node_b = j.get_path_to(b)

func _build_body_visuals() -> void:
	chassis = Shapes.rect(body, Rect2(-80, -5, 160, 30), Color("f5c518"))
	Shapes.rect(body, Rect2(-78, -33, 70, 28), Color("174f9c"))
	tank = Shapes.rect(body, Rect2(0, -23, 64, 23), Color("5fd3ff"))
	tank.position = Vector2(-75, -7)
	Shapes.rect(body, Rect2(15, -38, 58, 33), Color("c8c8c8"))
	Shapes.rect(body, Rect2(40, -33, 28, 18), Color("7fb7d9"))
	Shapes.rect(body, Rect2(72, 5, 8, 14), Color("444444"))

func _build_splash() -> void:
	splash = CPUParticles2D.new()
	splash.position = Vector2(-45, -30)
	splash.emitting = false
	splash.one_shot = true
	splash.amount = 16
	splash.lifetime = 0.7
	splash.explosiveness = 1.0
	splash.direction = Vector2(0, -1)
	splash.spread = 70.0
	splash.initial_velocity_min = 200.0
	splash.initial_velocity_max = 380.0
	splash.gravity = Vector2(0, 980)
	splash.scale_amount_min = 5.0
	splash.scale_amount_max = 9.0
	splash.color = Color("5fd3ff")
	body.add_child(splash)

func _build_camera() -> void:
	var cam := Camera2D.new()
	cam.enabled = true
	cam.zoom = Vector2(1.0, 1.0)
	cam.offset = Vector2(200, -40)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	body.add_child(cam)
	cam.reset_smoothing()
