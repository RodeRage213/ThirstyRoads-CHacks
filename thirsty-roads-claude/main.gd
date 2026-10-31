extends Node2D

enum MenuState { MAIN_TITLE, PLAY_MENU, GARAGE, SHOP, WORLDS, LEVELS, IN_GAME, END_SCREEN }

const MENU_BUTTON_WIDTH := 1080.0

var worlds: Array = []
var current_world_idx := 0
var level_index := 0
var level: Level
var playing := false
var is_capturing_end := false
var total_stars := 0
var total_coins := 0
var total_cash := 2000
var time_remaining := 0.0
var current_state := MenuState.MAIN_TITLE

# Progression tracking
var max_unlocked_world := 0
var max_unlocked_levels: Array[int] = []

var victory_player: AudioStreamPlayer

var current_car := "classic"
var cars_data := {
	"classic": {"owned": true, "cost": 0, "accel": 0, "control": 0},
	"heavy_tanker": {"owned": false, "cost": 400, "accel": 0, "control": 0},
	"speed_rover": {"owned": false, "cost": 600, "accel": 0, "control": 0},
	"nitro_jet": {"owned": false, "cost": 900, "accel": 0, "control": 0}
}

var inventory := {"lid": 0, "fly": 0, "extra_life": 0}
var lid_active := false
var lid_timer := 0.0
var fly_active := false
var fly_timer := 0.0
var extra_life_used := false

var ui: CanvasLayer
var water_bar: ProgressBar
var level_label: Label
var timer_label: Label
var coin_label: Label
var cash_label: Label
var powerup_status_label: Label
var overlay: ColorRect
var warn_label: Label

var title_label: Label
var main_play_btn: Button
var sub_menu_box: VBoxContainer
var garage_box: VBoxContainer
var shop_box: VBoxContainer
var worlds_box: VBoxContainer
var levels_box: VBoxContainer
var end_card_box: VBoxContainer
var polaroid_card: PanelContainer
var photo_texture_rect: TextureRect
var ov_title: Label
var ov_body: Label
var button_container: HBoxContainer

func _ready() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	
	_setup_input()
	worlds = Levels.get_all_worlds()
	
	max_unlocked_levels.resize(worlds.size())
	max_unlocked_levels.fill(0)
	
	_build_ui()
	_load_level(0, 0, false)
	_show_main_home()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and playing:
		call_deferred("_load_level", current_world_idx, level_index, true)
		
	if playing and level and level.truck and level.truck.active:
		if Input.is_key_pressed(KEY_1) and inventory["lid"] > 0 and not lid_active:
			_activate_lid()
		elif Input.is_key_pressed(KEY_2) and inventory["fly"] > 0 and not fly_active:
			_activate_fly()
		elif Input.is_key_pressed(KEY_3):
			level.truck.trigger_nitro()

func _process(delta: float) -> void:
	var warn := false
	if playing and level and level.truck:
		time_remaining = maxf(0.0, time_remaining - delta)
		if timer_label:
			timer_label.text = "⏱️ TIMER: %.1fs" % time_remaining
		
		warn = level.truck.on_bridge and absf(level.truck.strain) > 0.45
		
		if lid_active:
			lid_timer -= delta
			if lid_timer <= 0.0:
				lid_active = false
				level.truck.spill_rate = 0.0012

		if fly_active:
			fly_timer -= delta
			for w in [level.truck.wheel_back, level.truck.wheel_front]:
				if w.angular_velocity < level.truck.max_wheel_speed:
					w.apply_torque(level.truck.engine_torque * 1.2)
					
			var vert_dir := Input.get_axis("ui_up", "ui_down")
			if vert_dir < 0.0:
				level.truck.body.apply_central_force(Vector2(0, -9800.0))
			elif vert_dir > 0.0:
				level.truck.body.apply_central_force(Vector2(0, 3500.0))
			else:
				level.truck.body.apply_central_force(Vector2(0, -3200.0))
				
			if fly_timer <= 0.0:
				fly_active = false
				if level.truck.body.global_position.y < -150.0:
					level.truck._fail("Fell from high altitude after flight expired!")
					
		_update_powerup_status_ui()
		
	warn_label.visible = warn
	if warn:
		warn_label.modulate.a = 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.02)

func _stop_victory_sound() -> void:
	if victory_player:
		victory_player.stop()
		victory_player.queue_free()
		victory_player = null

func _show_main_home() -> void:
	_stop_victory_sound()
	current_state = MenuState.MAIN_TITLE
	title_label.text = "ThirstyRoads"
	title_label.visible = true
	main_play_btn.visible = true
	sub_menu_box.visible = false
	if garage_box: garage_box.visible = false
	if shop_box: shop_box.visible = false
	if worlds_box: worlds_box.visible = false
	if levels_box: levels_box.visible = false
	end_card_box.visible = false
	overlay.visible = true

func _on_main_play_pressed() -> void:
	current_state = MenuState.PLAY_MENU
	title_label.text = "ThirstyRoads"
	title_label.visible = true
	main_play_btn.visible = false
	sub_menu_box.visible = true
	if garage_box: garage_box.visible = false
	if shop_box: shop_box.visible = false
	if worlds_box: worlds_box.visible = false
	if levels_box: levels_box.visible = false
	end_card_box.visible = false

func _open_garage() -> void:
	current_state = MenuState.GARAGE
	title_label.text = "🚗 GARAGE"
	title_label.visible = true
	main_play_btn.visible = false
	sub_menu_box.visible = false
	_refresh_garage_ui()
	garage_box.visible = true
	shop_box.visible = false
	worlds_box.visible = false
	levels_box.visible = false
	end_card_box.visible = false

func _open_shop() -> void:
	current_state = MenuState.SHOP
	title_label.text = "🛒 POWERUP SHOP"
	title_label.visible = true
	main_play_btn.visible = false
	sub_menu_box.visible = false
	_refresh_shop_ui()
	garage_box.visible = false
	shop_box.visible = true
	worlds_box.visible = false
	levels_box.visible = false
	end_card_box.visible = false

func _open_worlds() -> void:
	current_state = MenuState.WORLDS
	title_label.text = "🌍 SELECT WORLD"
	title_label.visible = true
	main_play_btn.visible = false
	sub_menu_box.visible = false
	garage_box.visible = false
	shop_box.visible = false
	_build_worlds_ui()
	worlds_box.visible = true
	levels_box.visible = false
	end_card_box.visible = false

func _open_levels_for_world(w_idx: int) -> void:
	if w_idx > max_unlocked_world:
		return
	current_world_idx = w_idx
	current_state = MenuState.LEVELS
	title_label.text = worlds[w_idx]["world_name"]
	title_label.visible = true
	main_play_btn.visible = false
	sub_menu_box.visible = false
	garage_box.visible = false
	shop_box.visible = false
	worlds_box.visible = false
	_build_levels_ui(w_idx)
	levels_box.visible = true
	end_card_box.visible = false

func _start_selected_level(lvl_idx: int) -> void:
	if lvl_idx > max_unlocked_levels[current_world_idx]:
		return
	_stop_victory_sound()
	overlay.visible = false
	current_state = MenuState.IN_GAME
	_reset_run_powerups()
	call_deferred("_load_level", current_world_idx, lvl_idx, true)

func _select_or_buy_car(car_key: String) -> void:
	var data: Dictionary = cars_data[car_key]
	if data["owned"]:
		current_car = car_key
	elif total_cash >= data["cost"]:
		total_cash -= data["cost"]
		data["owned"] = true
		current_car = car_key
		_update_hud_ui()
	_refresh_garage_ui()

func _upgrade_car_stat(car_key: String, stat: String) -> void:
	var data: Dictionary = cars_data[car_key]
	var current_tier: int = data[stat]
	var cost := (current_tier + 1) * 150
	if current_tier < 5 and total_cash >= cost:
		total_cash -= cost
		data[stat] += 1
		_update_hud_ui()
		_refresh_garage_ui()

func _buy_powerup(item: String, cost: int) -> void:
	if total_cash >= cost:
		total_cash -= cost
		inventory[item] += 1
		_update_hud_ui()
		_refresh_shop_ui()

func _reset_run_powerups() -> void:
	lid_active = false
	lid_timer = 0.0
	fly_active = false
	fly_timer = 0.0
	extra_life_used = false

func _activate_lid() -> void:
	inventory["lid"] -= 1
	lid_active = true
	lid_timer = 10.0
	if level and level.truck:
		level.truck.spill_rate = 0.0

func _activate_fly() -> void:
	inventory["fly"] -= 1
	fly_active = true
	fly_timer = 5.0

func _load_level(w_idx: int, l_idx: int, active: bool) -> void:
	playing = false
	current_world_idx = w_idx
	level_index = l_idx
	var w_data: Dictionary = worlds[w_idx]
	var l_data: Dictionary = w_data["levels"][l_idx]
	
	RenderingServer.set_default_clear_color(Color(w_data["bg_color"]))
	time_remaining = l_data["time_limit"]
	
	if level:
		remove_child(level)
		level.queue_free()
		level = null
		
	var level_dict: Dictionary = l_data.duplicate(true)
	level_dict["theme"] = w_data["theme"]
	
	level = Level.new()
	add_child(level)
	level.build(level_dict)
	
	var car_info: Dictionary = cars_data[current_car]
	level.truck.setup_stats(current_car, car_info["accel"], car_info["control"])
	
	level.finished.connect(_on_finished)
	level.failed.connect(_on_failed)
	level.coin_collected.connect(_on_coin_collected)
	level.truck.water_changed.connect(_on_water_changed)
	level.truck.set_active(active)
	level_label.text = l_data["name"]
	water_bar.value = 100.0
	playing = active

func _retry() -> void:
	_stop_victory_sound()
	overlay.visible = false
	_reset_run_powerups()
	call_deferred("_load_level", current_world_idx, level_index, true)

func _next_level() -> void:
	_stop_victory_sound()
	overlay.visible = false
	_reset_run_powerups()
	var current_world_levels: Array = worlds[current_world_idx]["levels"]
	if level_index < current_world_levels.size() - 1:
		call_deferred("_load_level", current_world_idx, level_index + 1, true)
	elif current_world_idx < worlds.size() - 1:
		call_deferred("_load_level", current_world_idx + 1, 0, true)
	else:
		_show_main_home()

func _on_water_changed(value: float) -> void:
	water_bar.value = value

func _on_coin_collected() -> void:
	total_coins += 1
	_update_hud_ui()

func _update_hud_ui() -> void:
	if coin_label:
		coin_label.text = "💧 DROPLETS: %d" % total_coins
	if cash_label:
		cash_label.text = "💵 CASH: $%d" % total_cash

func _update_powerup_status_ui() -> void:
	if not powerup_status_label: return
	var txt := ""
	if lid_active:
		txt += "🔒 LID SEALED: %.1fs  " % lid_timer
	elif inventory["lid"] > 0:
		txt += "[1] Tight Lid (%d)  " % inventory["lid"]
		
	if fly_active:
		txt += "🕊️ FLYING: %.1fs  " % fly_timer
	elif inventory["fly"] > 0:
		txt += "[2] Fly Wings (%d)  " % inventory["fly"]
		
	if inventory["extra_life"] > 0 and not extra_life_used:
		txt += "💖 Extra Life  "
		
	if level and level.truck and level.truck.car_type == "nitro_jet":
		if level.truck.nitro_active:
			txt += "🚀 NITRO BOOST: %.1fs" % level.truck.nitro_timer
		elif level.truck.nitro_cooldown_timer > 5.0:
			txt += "🚀 RECHARGING: %.1fs" % (level.truck.nitro_cooldown_timer - 5.0)
		else:
			txt += "[3] NITRO READY"
		
	powerup_status_label.text = txt

func _on_finished(water_left: float, droplets: int) -> void:
	if not playing: return
	playing = false
	
	# Progression unlock check
	var current_world_levels: Array = worlds[current_world_idx]["levels"]
	if level_index < current_world_levels.size() - 1:
		max_unlocked_levels[current_world_idx] = max(max_unlocked_levels[current_world_idx], level_index + 1)
	else:
		if current_world_idx + 1 < worlds.size():
			max_unlocked_world = max(max_unlocked_world, current_world_idx + 1)
			max_unlocked_levels[current_world_idx + 1] = max(max_unlocked_levels[current_world_idx + 1], 0)

	if SoundFX.victory_stream:
		_stop_victory_sound()
		victory_player = AudioStreamPlayer.new()
		victory_player.stream = SoundFX.victory_stream
		add_child(victory_player)
		victory_player.play()
		victory_player.finished.connect(func():
			if victory_player:
				victory_player.play()
		)

	var is_gold := time_remaining > 0.0 and water_left > 75.0
	var stars := 3 if water_left > 70.0 else (2 if water_left > 35.0 else 1)
	total_stars += stars
	
	var water_cash := int(water_left)
	var gold_bonus := 100 if is_gold else 0
	var level_total_earned := water_cash + (droplets * 10) + gold_bonus
	total_cash += level_total_earned
	_update_hud_ui()

	var l_data: Dictionary = worlds[current_world_idx]["levels"][level_index]
	var gold_badge := "🥇 GOLD TIME CLEAR! (+$100 Bonus)\n" if is_gold else ""
	var text := "%sTime Remaining: %.1fs\nWater Delivered: %d%% (+$%d)\nDroplets Bonus: %d (+$%d)\nTotal Earned: +$%d\nTotal Cash: $%d\n\n%s" % [
		gold_badge, time_remaining, int(water_left), water_cash, droplets, droplets * 10, level_total_earned, total_cash, l_data["fact"]]
	
	var btns := []
	if level_index < current_world_levels.size() - 1 or current_world_idx < worlds.size() - 1:
		btns.append({"text": "Retry", "action": _retry})
		btns.append({"text": "Next Level", "action": _next_level})
	else:
		btns.append({"text": "Home", "action": _show_main_home})
		
	var title_str := "🥇 GOLD BADGE EARNED!" if is_gold else "LEVEL COMPLETE!"
	_capture_and_show(title_str, text, btns)

func _on_failed(reason: String) -> void:
	if not playing: return
	
	if inventory["extra_life"] > 0 and not extra_life_used:
		inventory["extra_life"] -= 1
		extra_life_used = true
		_update_hud_ui()
		
		if level and level.truck:
			level.is_completed = false
			level.truck.alive = true
			level.truck.active = true
			level.truck.body.rotation = 0
			level.truck.body.linear_velocity = Vector2.ZERO
			level.truck.body.angular_velocity = 0.0
			level.truck.body.global_position.y -= 80.0
			return

	playing = false
	var text := reason + "\n\nEvery drop counts."
	var btns := [
		{"text": "Home", "action": _show_main_home},
		{"text": "Retry", "action": _retry}
	]
	_capture_and_show("WIPEOUT!", text, btns)

func _capture_and_show(title: String, text: String, buttons: Array) -> void:
	if is_capturing_end: return
	is_capturing_end = true
	
	overlay.visible = false
	
	await RenderingServer.frame_post_draw
	
	if get_viewport():
		var vp_tex := get_viewport().get_texture()
		if vp_tex:
			var img := vp_tex.get_image()
			if img and not img.is_empty():
				photo_texture_rect.texture = ImageTexture.create_from_image(img)
				
	_show_polaroid(title, text, buttons)
	is_capturing_end = false

func _setup_input() -> void:
	_add_action("accelerate", [KEY_RIGHT, KEY_D])
	_add_action("brake", [KEY_LEFT, KEY_A])
	_add_action("restart", [KEY_R])
	_add_action("ui_up", [KEY_UP, KEY_W])
	_add_action("ui_down", [KEY_DOWN, KEY_S])

func _add_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)

func _style_label(l: Label, size: int) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)

func _make_stylish_button(text_str: String, min_size: Vector2, font_sz: int, bg_hex: String) -> Button:
	var btn := Button.new()
	btn.text = text_str
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", font_sz)
	
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(bg_hex)
	normal_style.set_corner_radius_all(12)
	normal_style.shadow_color = Color(0, 0, 0, 0.3)
	normal_style.shadow_size = 6
	normal_style.shadow_offset = Vector2(0, 4)
	
	var disabled_style := normal_style.duplicate()
	disabled_style.bg_color = Color(bg_hex).darkened(0.5)
	
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("disabled", disabled_style)
	return btn

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)

	var top := HBoxContainer.new()
	ui.add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 20)

	var left := VBoxContainer.new()
	top.add_child(left)
	var wl := Label.new()
	wl.text = "WATER"
	_style_label(wl, 18)
	left.add_child(wl)

	water_bar = ProgressBar.new()
	water_bar.custom_minimum_size = Vector2(240, 26)
	water_bar.max_value = 100.0
	water_bar.value = 100.0
	water_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("2ba4ee")
	water_bar.add_theme_stylebox_override("fill", fill)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0, 0, 0, 0.5)
	water_bar.add_theme_stylebox_override("background", back)
	left.add_child(water_bar)

	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer1)

	var center_hud := HBoxContainer.new()
	center_hud.add_theme_constant_override("separation", 24)
	top.add_child(center_hud)

	timer_label = Label.new()
	timer_label.text = "⏱️ TIMER: 0.0s"
	_style_label(timer_label, 20)
	center_hud.add_child(timer_label)

	coin_label = Label.new()
	coin_label.text = "💧 DROPLETS: 0"
	_style_label(coin_label, 20)
	center_hud.add_child(coin_label)

	cash_label = Label.new()
	cash_label.text = "💵 CASH: $2000"
	cash_label.add_theme_color_override("font_color", Color("4cd964"))
	_style_label(cash_label, 20)
	center_hud.add_child(cash_label)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer2)

	level_label = Label.new()
	_style_label(level_label, 22)
	top.add_child(level_label)

	powerup_status_label = Label.new()
	_style_label(powerup_status_label, 22)
	powerup_status_label.position = Vector2(20, 680)
	ui.add_child(powerup_status_label)

	warn_label = Label.new()
	warn_label.text = "EASE OFF THE PEDAL!"
	warn_label.custom_minimum_size = Vector2(700, 0)
	warn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_label.add_theme_color_override("font_color", Color("ff5a4d"))
	_style_label(warn_label, 44)
	ui.add_child(warn_label)
	warn_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	warn_label.position.y = 100
	warn_label.visible = false

	overlay = ColorRect.new()
	overlay.color = Color(0.1, 0.5, 0.85, 0.80)
	ui.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center_container := CenterContainer.new()
	overlay.add_child(center_container)
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var root_vbox := VBoxContainer.new()
	root_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_theme_constant_override("separation", 20)
	center_container.add_child(root_vbox)

	title_label = Label.new()
	title_label.text = "ThirstyRoads"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(MENU_BUTTON_WIDTH, 0)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color("f5c518"))
	title_label.add_theme_color_override("font_outline_color", Color("174f9c"))
	title_label.add_theme_constant_override("outline_size", 14)
	root_vbox.add_child(title_label)

	main_play_btn = _make_stylish_button("PLAY ▶", Vector2(240, 72), 32, "4cd964")
	main_play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_play_btn.pressed.connect(_on_main_play_pressed)
	root_vbox.add_child(main_play_btn)

	sub_menu_box = VBoxContainer.new()
	sub_menu_box.alignment = BoxContainer.ALIGNMENT_CENTER
	sub_menu_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sub_menu_box.add_theme_constant_override("separation", 16)
	sub_menu_box.visible = false
	root_vbox.add_child(sub_menu_box)

	var garage_btn := _make_stylish_button("🚗 GARAGE", Vector2(260, 56), 24, "1e88e5")
	garage_btn.pressed.connect(_open_garage)
	sub_menu_box.add_child(garage_btn)

	var shop_btn := _make_stylish_button("🛒 SHOP", Vector2(260, 56), 24, "1e88e5")
	shop_btn.pressed.connect(_open_shop)
	sub_menu_box.add_child(shop_btn)

	var worlds_btn := _make_stylish_button("🌍 WORLDS", Vector2(260, 56), 24, "ff9800")
	worlds_btn.pressed.connect(_open_worlds)
	sub_menu_box.add_child(worlds_btn)

	garage_box = VBoxContainer.new()
	garage_box.alignment = BoxContainer.ALIGNMENT_CENTER
	garage_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	garage_box.add_theme_constant_override("separation", 12)
	garage_box.visible = false
	root_vbox.add_child(garage_box)
	_build_garage_items()

	shop_box = VBoxContainer.new()
	shop_box.alignment = BoxContainer.ALIGNMENT_CENTER
	shop_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	shop_box.add_theme_constant_override("separation", 14)
	shop_box.visible = false
	root_vbox.add_child(shop_box)
	_build_shop_items()

	worlds_box = VBoxContainer.new()
	worlds_box.alignment = BoxContainer.ALIGNMENT_CENTER
	worlds_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	worlds_box.add_theme_constant_override("separation", 14)
	worlds_box.visible = false
	root_vbox.add_child(worlds_box)

	levels_box = VBoxContainer.new()
	levels_box.alignment = BoxContainer.ALIGNMENT_CENTER
	levels_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	levels_box.add_theme_constant_override("separation", 12)
	levels_box.visible = false
	root_vbox.add_child(levels_box)

	end_card_box = VBoxContainer.new()
	end_card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	end_card_box.add_theme_constant_override("separation", 20)
	end_card_box.visible = false
	root_vbox.add_child(end_card_box)

	polaroid_card = PanelContainer.new()
	polaroid_card.rotation = -0.04
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color.WHITE
	card_style.set_corner_radius_all(12)
	card_style.set_expand_margin_all(18)
	card_style.shadow_color = Color(0, 0, 0, 0.4)
	card_style.shadow_size = 14
	card_style.shadow_offset = Vector2(6, 10)
	polaroid_card.add_theme_stylebox_override("panel", card_style)
	end_card_box.add_child(polaroid_card)

	var card_vbox := VBoxContainer.new()
	card_vbox.custom_minimum_size = Vector2(420, 0)
	card_vbox.add_theme_constant_override("separation", 14)
	polaroid_card.add_child(card_vbox)

	photo_texture_rect = TextureRect.new()
	photo_texture_rect.custom_minimum_size = Vector2(400, 240)
	photo_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	card_vbox.add_child(photo_texture_rect)

	ov_title = Label.new()
	ov_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ov_title.add_theme_color_override("font_color", Color("222222"))
	ov_title.add_theme_font_size_override("font_size", 30)
	card_vbox.add_child(ov_title)

	ov_body = Label.new()
	ov_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ov_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ov_body.add_theme_color_override("font_color", Color("444444"))
	ov_body.add_theme_font_size_override("font_size", 16)
	card_vbox.add_child(ov_body)

	button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 16)
	end_card_box.add_child(button_container)

func _build_worlds_ui() -> void:
	for c in worlds_box.get_children():
		c.queue_free()

	for idx in range(worlds.size()):
		var w_data: Dictionary = worlds[idx]
		var is_unlocked := idx <= max_unlocked_world
		var title_str: String = w_data["world_name"] if is_unlocked else "🔒 " + w_data["world_name"]
		var color_hex := "ff9800" if is_unlocked else "555555"
		
		var btn := _make_stylish_button(title_str, Vector2(MENU_BUTTON_WIDTH, 52), 20, color_hex)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.disabled = not is_unlocked
		btn.pressed.connect(func(): _open_levels_for_world(idx))
		worlds_box.add_child(btn)

	var back_btn := _make_stylish_button("⬅ BACK", Vector2(180, 44), 18, "ff5a4d")
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(_on_main_play_pressed)
	worlds_box.add_child(back_btn)

func _build_levels_ui(w_idx: int) -> void:
	for c in levels_box.get_children():
		c.queue_free()

	var current_world_levels: Array = worlds[w_idx]["levels"]
	var max_lvl_unlocked: int = max_unlocked_levels[w_idx]

	for l_idx in range(current_world_levels.size()):
		var l_data: Dictionary = current_world_levels[l_idx]
		var is_unlocked := l_idx <= max_lvl_unlocked
		var title_str: String = l_data["name"] if is_unlocked else "🔒 " + l_data["name"]
		var color_hex := "1e88e5" if is_unlocked else "555555"
		
		var btn := _make_stylish_button(title_str, Vector2(MENU_BUTTON_WIDTH, 46), 18, color_hex)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.disabled = not is_unlocked
		btn.pressed.connect(func(): _start_selected_level(l_idx))
		levels_box.add_child(btn)

	var back_btn := _make_stylish_button("⬅ WORLDS", Vector2(180, 44), 18, "ff5a4d")
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(_open_worlds)
	levels_box.add_child(back_btn)

func _build_garage_items() -> void:
	for c in garage_box.get_children():
		c.queue_free()

	var cars_info := [
		{"key": "classic", "name": "🚚 Classic Tanker"},
		{"key": "heavy_tanker", "name": "🛡️ Heavy Tanker"},
		{"key": "speed_rover", "name": "⚡ Speed Rover"},
		{"key": "nitro_jet", "name": "🚀 Nitro Jet"}
	]

	for car in cars_info:
		var key: String = car["key"]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		garage_box.add_child(row)

		var car_btn := _make_stylish_button(car["name"], Vector2(200, 44), 16, "1e88e5")
		car_btn.name = "select_" + key
		car_btn.pressed.connect(func(): _select_or_buy_car(key))
		row.add_child(car_btn)

		var accel_btn := _make_stylish_button("Accel +1", Vector2(110, 44), 14, "4cd964")
		accel_btn.name = "accel_" + key
		accel_btn.pressed.connect(func(): _upgrade_car_stat(key, "accel"))
		row.add_child(accel_btn)

		var ctrl_btn := _make_stylish_button("Control +1", Vector2(110, 44), 14, "ff9800")
		ctrl_btn.name = "ctrl_" + key
		ctrl_btn.pressed.connect(func(): _upgrade_car_stat(key, "control"))
		row.add_child(ctrl_btn)

	var back_btn := _make_stylish_button("⬅ BACK", Vector2(180, 44), 18, "ff5a4d")
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(_on_main_play_pressed)
	garage_box.add_child(back_btn)

func _refresh_garage_ui() -> void:
	for key in cars_data.keys():
		var data: Dictionary = cars_data[key]
		var select_btn: Button = garage_box.find_child("select_" + key, true, false)
		var accel_btn: Button = garage_box.find_child("accel_" + key, true, false)
		var ctrl_btn: Button = garage_box.find_child("ctrl_" + key, true, false)

		if select_btn:
			if current_car == key:
				select_btn.text = select_btn.text.split(" -")[0] + " [EQUIPPED]"
			elif data["owned"]:
				select_btn.text = select_btn.text.split(" -")[0] + " [SELECT]"
			else:
				select_btn.text = select_btn.text.split(" -")[0] + " -$%d" % data["cost"]

		if accel_btn:
			if data["accel"] >= 5:
				accel_btn.text = "Accel MAX"
			else:
				accel_btn.text = "Accel T%d ($%d)" % [data["accel"], (data["accel"] + 1) * 150]

		if ctrl_btn:
			if data["control"] >= 5:
				ctrl_btn.text = "Ctrl MAX"
			else:
				ctrl_btn.text = "Ctrl T%d ($%d)" % [data["control"], (data["control"] + 1) * 150]

func _build_shop_items() -> void:
	for c in shop_box.get_children():
		c.queue_free()

	var items := [
		{"key": "lid", "name": "🔒 Tight Lid (10s No Spill)", "cost": 150},
		{"key": "fly", "name": "🕊️ Fly Wings (5s Flight)", "cost": 350},
		{"key": "extra_life", "name": "💖 Extra Life (1 Use)", "cost": 250}
	]

	for item in items:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		shop_box.add_child(row)

		var btn := _make_stylish_button("%s - $%d" % [item["name"], item["cost"]], Vector2(360, 50), 18, "1e88e5")
		var k: String = item["key"]
		var c: int = item["cost"]
		btn.pressed.connect(func(): _buy_powerup(k, c))
		row.add_child(btn)

		var count_lbl := Label.new()
		count_lbl.name = "count_" + k
		count_lbl.text = "Owned: %d" % inventory[item["key"]]
		_style_label(count_lbl, 18)
		row.add_child(count_lbl)

	var back_btn := _make_stylish_button("⬅ BACK", Vector2(180, 46), 20, "ff5a4d")
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(_on_main_play_pressed)
	shop_box.add_child(back_btn)

func _refresh_shop_ui() -> void:
	for k in ["lid", "fly", "extra_life"]:
		var lbl: Label = shop_box.find_child("count_" + k, true, false)
		if lbl:
			lbl.text = "Owned: %d" % inventory[k]

func _show_polaroid(title: String, text: String, buttons: Array) -> void:
	current_state = MenuState.END_SCREEN
	title_label.visible = false
	main_play_btn.visible = false
	sub_menu_box.visible = false
	if garage_box: garage_box.visible = false
	if shop_box: shop_box.visible = false
	if worlds_box: worlds_box.visible = false
	if levels_box: levels_box.visible = false
	end_card_box.visible = true

	ov_title.text = title
	ov_body.text = text

	for c in button_container.get_children():
		c.queue_free()

	for btn_info in buttons:
		var btn := _make_stylish_button(btn_info["text"], Vector2(160, 52), 22, "1e88e5")
		var action_func: Callable = btn_info["action"]
		btn.pressed.connect(func(): action_func.call())
		button_container.add_child(btn)

	overlay.visible = true
	if button_container.get_child_count() > 0:
		button_container.get_child(0).grab_focus()
