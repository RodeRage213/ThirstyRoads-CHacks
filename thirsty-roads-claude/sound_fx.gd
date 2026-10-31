class_name SoundFX
extends RefCounted

static var engine_stream: AudioStream
static var victory_stream: AudioStream

static func _static_init() -> void:
	if ResourceLoader.exists("res://engine.wav"):
		engine_stream = load("res://engine.wav")
	elif ResourceLoader.exists("res://engine.ogg"):
		engine_stream = load("res://engine.ogg")
		
	if ResourceLoader.exists("res://victory.wav"):
		victory_stream = load("res://victory.wav")
	elif ResourceLoader.exists("res://victory.ogg"):
		victory_stream = load("res://victory.ogg")

static func play_sound(node: Node, stream: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> AudioStreamPlayer:
	if stream == null or node == null: return null
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	node.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	return player
