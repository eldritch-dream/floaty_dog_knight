@tool
extends EditorScript
## Run once via Godot Editor: Script → Run (Ctrl+Shift+X).
## Generates placeholder .wav files for every entry in AudioManager.SOUNDS.
## Each sound has a distinct frequency/shape so you can identify which event
## triggered during testing. Replace any file with a real asset at any time —
## zero code changes needed.
##
## Tone guide:
##   Short high blip  (1200 Hz, 0.15s) = collect/pickup
##   Low thud          (80 Hz,  0.25s) = impact/hurt
##   Mid swoosh        (300→150 Hz, 0.3s) = swing (falling pitch)
##   Rising tone       (400→900 Hz, 0.4s) = level up
##   Soft low pad      (120 Hz, 0.6s, slow fade) = dream/ambient
##   Short pop         (600 Hz, 0.1s) = UI confirm / jump
##   Mid alert         (500 Hz, 0.2s, two pulses) = enemy alert
##   Low growl         (100 Hz, 0.3s) = enemy attack/death
##   Short click       (800 Hz, 0.08s) = stagger

const SAMPLE_RATE: int = 44100
const OUT_DIR: String = "res://assets/audio/sfx/"

# name → [base_hz, end_hz, duration_s, shape]
# shapes: "sine", "sweep", "pulse2", "fade"
const SPEC: Dictionary = {
	"swing_light":   [300.0, 150.0, 0.30, "sweep"],
	"swing_heavy":   [200.0,  80.0, 0.45, "sweep"],
	"hit_impact":    [ 80.0,  80.0, 0.25, "fade"],
	"player_hurt":   [200.0, 120.0, 0.30, "sweep"],
	"player_death":  [150.0,  60.0, 0.60, "fade"],
	"dodge_roll":    [350.0, 200.0, 0.20, "sweep"],
	"player_jump":   [500.0, 700.0, 0.15, "sweep"],
	"enemy_alert":   [500.0, 500.0, 0.25, "pulse2"],
	"enemy_attack":  [100.0,  80.0, 0.30, "fade"],
	"enemy_stagger": [800.0, 800.0, 0.08, "sine"],
	"enemy_death":   [100.0,  50.0, 0.50, "fade"],
	"orb_collect":   [1200.0,1200.0,0.15, "sine"],
	"level_up":      [400.0, 900.0, 0.40, "sweep"],
	"dream_enter":   [120.0, 120.0, 0.60, "fade"],
	"dream_wake":    [200.0, 400.0, 0.40, "sweep"],
	"portal_travel": [250.0, 500.0, 0.50, "sweep"],
}


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path(OUT_DIR))
	for name in SPEC:
		var s: Array = SPEC[name]
		var data: PackedByteArray = _generate(
				s[0], s[1], s[2], s[3])
		var path: String = OUT_DIR + name + ".wav"
		_write_wav(ProjectSettings.globalize_path(path), data)
		print("generated: ", path)
	print("Done — %d placeholder files written to %s" % [SPEC.size(), OUT_DIR])


func _generate(hz_start: float, hz_end: float,
		duration: float, shape: String) -> PackedByteArray:
	var num_samples: int = int(SAMPLE_RATE * duration)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(num_samples)
	for i in range(num_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var progress: float = float(i) / float(num_samples)
		var hz: float = lerp(hz_start, hz_end, progress)
		var amp: float = 1.0
		match shape:
			"sine":
				amp = sin(1.0 - progress) * 0.8  # simple decay
			"sweep":
				amp = (1.0 - progress) * 0.8
			"fade":
				amp = pow(1.0 - progress, 2.0) * 0.8
			"pulse2":
				# Two short blips separated by silence.
				var pulse: float = fmod(progress * 2.0, 1.0)
				amp = (1.0 - pulse) * 0.8 if pulse < 0.4 else 0.0
		samples[i] = sin(TAU * hz * t) * amp
	return _pack_pcm16(samples)


func _pack_pcm16(samples: PackedFloat32Array) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v: int = clamp(int(samples[i] * 32767.0), -32768, 32767)
		out[i * 2]     = v & 0xFF
		out[i * 2 + 1] = (v >> 8) & 0xFF
	return out


func _write_wav(abs_path: String, pcm: PackedByteArray) -> void:
	var data_size: int = pcm.size()
	var header: PackedByteArray = PackedByteArray()
	header.resize(44)
	# RIFF chunk
	header[0] = 0x52; header[1] = 0x49; header[2] = 0x46; header[3] = 0x46  # "RIFF"
	_write_u32(header,  4, 36 + data_size)
	header[8] = 0x57; header[9] = 0x41; header[10] = 0x56; header[11] = 0x45  # "WAVE"
	# fmt  chunk
	header[12] = 0x66; header[13] = 0x6D; header[14] = 0x74; header[15] = 0x20  # "fmt "
	_write_u32(header, 16, 16)        # chunk size
	_write_u16(header, 20, 1)         # PCM
	_write_u16(header, 22, 1)         # mono
	_write_u32(header, 24, SAMPLE_RATE)
	_write_u32(header, 28, SAMPLE_RATE * 2)  # byte rate
	_write_u16(header, 32, 2)         # block align
	_write_u16(header, 34, 16)        # bits per sample
	# data chunk
	header[36] = 0x64; header[37] = 0x61; header[38] = 0x74; header[39] = 0x61  # "data"
	_write_u32(header, 40, data_size)
	var file: FileAccess = FileAccess.open(abs_path, FileAccess.WRITE)
	file.store_buffer(header)
	file.store_buffer(pcm)
	file.close()


func _write_u32(buf: PackedByteArray, offset: int, value: int) -> void:
	buf[offset]     = value & 0xFF
	buf[offset + 1] = (value >> 8)  & 0xFF
	buf[offset + 2] = (value >> 16) & 0xFF
	buf[offset + 3] = (value >> 24) & 0xFF


func _write_u16(buf: PackedByteArray, offset: int, value: int) -> void:
	buf[offset]     = value & 0xFF
	buf[offset + 1] = (value >> 8) & 0xFF
