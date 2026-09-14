extends Node
## Original synthesized foley. No external samples or copyrighted recordings.
const RATE := 22050
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var ambience: AudioStreamPlayer
var volume := 0.65
var focused := true
var config_path := "user://audio.cfg"
var can_persist := true
var danger := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	can_persist = not "--script" in OS.get_cmdline_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): config_path = arg.trim_prefix("--save-dir=").path_join("audio.cfg")
	if can_persist:
		var config := ConfigFile.new()
		if config.load(config_path)==OK: volume = clampf(float(config.get_value("audio","volume",0.65)),0,1)
	for id in ["ui","purchase","item","swing","hit","enemy","work"]: sounds[id] = make_sound(id)
	for i in range(6):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	ambience = AudioStreamPlayer.new()
	add_child(ambience)
	ambience.stream = make_sound("wind")
	apply_volume()

func make_sound(id: String) -> AudioStreamWAV:
	var duration := 8.0 if id=="wind" else (0.35 if id in ["purchase","item"] else 0.16)
	var count := int(RATE*duration)
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	var random := RandomNumberGenerator.new()
	random.seed = 4207
	var low := 0.0
	for i in range(count):
		var t := float(i)/RATE
		var progress := t/duration
		var noise := random.randf_range(-1,1)
		low = lerpf(low,noise,0.035)
		var envelope := sin(minf(t/0.006,1.0)*PI*0.5)*pow(1-progress,3)
		var sample := 0.0
		match id:
			"ui": sample = sin(TAU*390*t)*0.10*envelope
			"purchase": sample = (sin(TAU*620*t)+sin(TAU*930*t)*0.35)*0.13*envelope
			"item": sample = (sin(TAU*440*t)+sin(TAU*660*t)*0.3)*0.11*envelope
			"swing": sample = low*1.5*sin(PI*progress)*0.4
			"hit": sample = (sin(TAU*(120*t-150*t*t))*0.32+noise*0.14)*envelope
			"enemy": sample = (low*2+sin(TAU*74*t)*0.2)*envelope
			"work": sample = (sin(TAU*260*t)*0.12+low*0.3)*envelope
			"wind":
				# Periodic tones and a faded seam keep the quiet loop free of clicks.
				var seam := minf(1,minf(t,duration-t)/0.25)
				sample = (low*0.32+sin(TAU*53*t)*0.017+sin(TAU*79*t)*0.008)*(0.65+0.25*sin(TAU*t/8))*seam
		bytes.encode_s16(i*2,int(clampf(sample,-0.95,0.95)*32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	if id=="wind":
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream

func play(id: String) -> void:
	if volume<=0 or not focused or id not in sounds: return
	for voice in voices:
		if not voice.playing:
			voice.stream = sounds[id]
			voice.play()
			return

func set_location(scene: String) -> void:
	danger = "post" if scene.ends_with("outpost.tscn") else ("road" if scene.ends_with("outskirts.tscn") else "")
	if danger.is_empty(): ambience.stop()
	elif not ambience.playing: ambience.play()
	apply_volume()

func set_volume(value: float) -> void:
	volume = clampf(value,0,1)
	apply_volume()
	if can_persist:
		var config := ConfigFile.new()
		config.set_value("audio","volume",volume)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(config_path.get_base_dir()))
		config.save(config_path)

func apply_volume() -> void:
	for voice in voices: voice.volume_db = linear_to_db(maxf(volume,0.0001))-8
	if is_instance_valid(ambience): ambience.volume_db = linear_to_db(maxf(volume,0.0001))+(-7 if danger=="post" else -11)

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT: focused = false
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN: focused = true

func _process(_delta: float) -> void:
	if is_instance_valid(ambience): ambience.stream_paused = not focused or get_tree().paused
