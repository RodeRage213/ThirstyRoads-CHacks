class_name Level
extends Node2D

signal finished(water_left: float, droplets: int)
signal failed(reason: String)
signal coin_collected

var level_data: Dictionary
var truck: Truck
var bridges: Array[Bridge] = []
var coins_collected := 0
var is_completed := false

func build(data: Dictionary) -> void:
	level_data = data
	is_completed = false
	
	var theme: Dictionary = data.get("theme", {
		"ground_fill": Color("e8a87c"),
		"top_grass": Color("4cd964"),
		"mountains": Color("1f4e79")
	})
	var fin: Vector2 = data["finish"]
	var vp_size := get_viewport().get_visible_rect().size
	
	# Which world look? (from the theme, or from the level name as a fallback)
	var style: String = theme.get("style", "")
	if style == "":
		var lvl_name: String = data.get("name", "")
		if lvl_name.begins_with("W2-"):
			style = "desert"
		elif lvl_name.begins_with("W4-"):
			style = "glacier"
	
	# Background
	if style == "urban":
		Urban.build_background(self, theme["mountains"])
	else:
		_build_background(theme["mountains"])
	
	# Ground
	_build_terrain(theme["ground_fill"], theme["top_grass"])
	
	# World scenery (sits behind bridges and the truck)
	match style:
		"urban":
			Urban.build_props(self, level_data["cliffs"], fin.x, theme["ground_fill"])
		"desert":
			Desert.build_props(self, level_data["cliffs"], fin.x)
			Desert.build_atmosphere(self, vp_size, level_data["cliffs"])
		"glacier":
			Glacier.build_props(self, level_data["cliffs"], fin.x)
			Snow.build(self, vp_size)
	
	_build_bridges()
	_spawn_truck()
	_connect_bridges_to_truck()
	_build_coins()
	_build_finish()

func _process(_delta: float) -> void:
	if not is_completed and truck and is_instance_valid(truck.body):
		if truck.body.global_position.y > 1000.0:
			_trigger_fail("Fell into the canyon chasm!")

func _physics_process(_delta: float) -> void:
	if is_completed or truck == null:
		return
	var on := false
	for br in bridges:
		if br.loaded:
			on = true
	truck.on_bridge = on

func _trigger_finish() -> void:
	if is_completed: return
	is_completed = true
	if truck:
		truck.finish()
	call_deferred("_emit_finished")

func _emit_finished() -> void:
	var w_amount := truck.water if truck else 0.0
	finished.emit(w_amount, coins_collected)

func _trigger_fail(reason: String) -> void:
	if is_completed: return
	is_completed = true
	call_deferred("_emit_failed", reason)

func _emit_failed(reason: String) -> void:
	failed.emit(reason)

func _build_background(bg_color: Color) -> void:
	var parallax := ParallaxBackground.new()
	add_child(parallax)
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(0.2, 0.2)
	parallax.add_child(layer)

	var bg_poly := Polygon2D.new()
	bg_poly.color = bg_color
	var pts := PackedVector2Array()
	pts.append(Vector2(-2000, 1200))
	for x in range(-2000, 6000, 400):
		pts.append(Vector2(x, -200 + sin(x * 0.002) * 150))
	pts.append(Vector2(6000, 1200))
	bg_poly.polygon = pts
	layer.add_child(bg_poly)

func _build_terrain(fill_color: Color, top_color: Color) -> void:
	for cliff_poly in level_data["cliffs"]:
		var static_body := StaticBody2D.new()
		add_child(static_body)
		
		var shape := CollisionPolygon2D.new()
		var full_pts := PackedVector2Array(cliff_poly)
		full_pts.append(Vector2(cliff_poly[-1].x, 1200))
		full_pts.append(Vector2(cliff_poly[0].x, 1200))
		shape.polygon = full_pts
		static_body.add_child(shape)

		var visual_poly := Polygon2D.new()
		visual_poly.polygon = full_pts
		visual_poly.color = fill_color
		static_body.add_child(visual_poly)

		var top_line := Line2D.new()
		top_line.points = cliff_poly
		top_line.width = 12.0
		top_line.default_color = top_color
		static_body.add_child(top_line)

func _spawn_truck() -> void:
	truck = Truck.new()
	add_child(truck)
	truck.build(Vector2(-600, -80))
	truck.failed.connect(func(reason: String):
		_trigger_fail(reason)
	)

func _build_bridges() -> void:
	for b in level_data["bridges"]:
		var br := Bridge.new()
		add_child(br)
		br.setup(b["from"], b["to"], b.get("y", 0.0), b.get("flex", 45.0), b.get("planks", 10))
		bridges.append(br)

func _connect_bridges_to_truck() -> void:
	for br in bridges:
		br.wheels = [truck.wheel_back, truck.wheel_front]
		br.wheel_radius = truck.wheel_radius

func _build_coins() -> void:
	for coin_pos in level_data["coins"]:
		var area := Area2D.new()
		area.position = coin_pos
		add_child(area)
		
		var cs := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 20.0
		cs.shape = circle
		area.add_child(cs)
		
		var drop_poly := Polygon2D.new()
		var pts := PackedVector2Array()
		pts.append(Vector2(0, -18))
		pts.append(Vector2(12, 6))
		pts.append(Vector2(0, 16))
		pts.append(Vector2(-12, 6))
		drop_poly.polygon = pts
		drop_poly.color = Color("5fd3ff")
		area.add_child(drop_poly)
		
		area.body_entered.connect(func(b):
			if truck and (b == truck.body or b == truck.wheel_back or b == truck.wheel_front):
				coins_collected += 1
				coin_collected.emit()
				area.queue_free()
		)

func _build_finish() -> void:
	var fin_pos: Vector2 = level_data["finish"]
	
	var stopper := StaticBody2D.new()
	stopper.position = fin_pos + Vector2(30, 0)
	add_child(stopper)
	
	var stop_cs := CollisionShape2D.new()
	var stop_rect := RectangleShape2D.new()
	stop_rect.size = Vector2(40, 300)
	stop_cs.shape = stop_rect
	stop_cs.position = Vector2(0, -100)
	stopper.add_child(stop_cs)
	
	Shapes.rect(stopper, Rect2(-20, -250, 40, 300), Color("2c3e50"))

	var area := Area2D.new()
	area.position = fin_pos
	add_child(area)
	
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(100, 300)
	cs.shape = rect
	cs.position = Vector2(0, -100)
	area.add_child(cs)
	
	var flag_container := Node2D.new()
	flag_container.position = fin_pos + Vector2(-20, -180)
	add_child(flag_container)

	Shapes.rect(flag_container, Rect2(-6, 0, 12, 180), Color("111111"))
	Shapes.rect(flag_container, Rect2(42, 0, 12, 180), Color("111111"))

	var rows := 6
	var cols := 3
	var tile_size := 16.0
	for r in range(rows):
		for c in range(cols):
			var tile := Polygon2D.new()
			var is_white := (r + c) % 2 == 0
			var color := Color.WHITE if is_white else Color.BLACK
			
			var x0 := c * tile_size - 6.0
			var y0 := r * tile_size
			var pts := PackedVector2Array([
				Vector2(x0, y0),
				Vector2(x0 + tile_size, y0),
				Vector2(x0 + tile_size, y0 + tile_size),
				Vector2(x0, y0 + tile_size)
			])
			tile.polygon = pts
			tile.color = color
			flag_container.add_child(tile)

	area.body_entered.connect(func(b):
		if not is_completed and truck and (b == truck.body or b == truck.wheel_back or b == truck.wheel_front):
			_trigger_finish()
	)
