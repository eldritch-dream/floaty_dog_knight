extends Node
## Autoload singleton. Sole owner of all audio file paths and playback logic.
## Register as "AudioManager" in Project Settings → Autoload.
##
## Adding a new sound = one entry in SOUNDS + one file in assets/audio/sfx/.
## Swapping a placeholder for a real asset = drop the new file at the same path.
## No code changes needed when replacing placeholder files.
##
## 2D vs 3D rule:
##   play_sfx(name, Vector3.ZERO) → AudioStreamPlayer (non-positional, UI/system)
##   play_sfx(name, position)     → AudioStreamPlayer3D at world position (combat/world)

const SOUNDS: Dictionary = {
	# Player
	"swing_light":   "res://assets/audio/sfx/swing_light.wav",
	"swing_heavy":   "res://assets/audio/sfx/swing_heavy.wav",
	"hit_impact":    "res://assets/audio/sfx/hit_impact.wav",
	"player_hurt":   "res://assets/audio/sfx/player_hurt.wav",
	"player_death":  "res://assets/audio/sfx/player_death.wav",
	"dodge_roll":    "res://assets/audio/sfx/dodge_roll.wav",
	"player_jump":   "res://assets/audio/sfx/player_jump.wav",
	# Enemies
	"enemy_alert":   "res://assets/audio/sfx/enemy_alert.wav",
	"enemy_attack":  "res://assets/audio/sfx/enemy_attack.wav",
	"enemy_stagger": "res://assets/audio/sfx/enemy_stagger.wav",
	"enemy_death":   "res://assets/audio/sfx/enemy_death.wav",
	# Collectibles
	"orb_collect":   "res://assets/audio/sfx/orb_collect.wav",
	# Progression
	"level_up":      "res://assets/audio/sfx/level_up.wav",
	# World / UI
	"dream_enter":   "res://assets/audio/sfx/dream_enter.wav",
	"dream_wake":    "res://assets/audio/sfx/dream_wake.wav",
	"portal_travel": "res://assets/audio/sfx/portal_travel.wav",
}

## Max audible distance for 3D sources. Mirrors GameConfig.audio_3d_max_distance
## but AudioManager needs it without a config reference.
const DEFAULT_3D_MAX_DISTANCE: float = 20.0

var _music_player: AudioStreamPlayer = null


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)


## Play a sound effect by name.
## position = Vector3.ZERO → non-positional 2D player (UI/system sounds).
## position = world coords → AudioStreamPlayer3D at that location (combat/world sounds).
func play_sfx(sound_name: String, position: Vector3 = Vector3.ZERO,
		bus: String = "SFX") -> void:
	if not SOUNDS.has(sound_name):
		print("AudioManager: unknown sound '%s'" % sound_name)
		return
	var path: String = SOUNDS[sound_name]
	var stream: AudioStream = load(path) as AudioStream
	if not stream:
		print("AudioManager: could not load '%s'" % path)
		return
	if position == Vector3.ZERO:
		_play_2d(stream, bus)
	else:
		_play_3d(stream, position, bus)


func play_music(sound_name: String, _loop: bool = true) -> void:
	if not SOUNDS.has(sound_name):
		push_warning("AudioManager: unknown music '%s'" % sound_name)
		return
	var stream: AudioStream = load(SOUNDS[sound_name]) as AudioStream
	if not stream:
		return
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func set_sfx_volume(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)


func set_music_volume(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)


# ── Private ───────────────────────────────────────────────────────────────────

func _play_2d(stream: AudioStream, bus: String) -> void:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	add_child(player)
	player.play()
	# Free after playback finishes.
	player.finished.connect(player.queue_free)


func _play_3d(stream: AudioStream, position: Vector3, bus: String) -> void:
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = bus
	player.max_distance = DEFAULT_3D_MAX_DISTANCE
	# Attach to scene root so the sound outlives the emitting node (e.g. dying enemy).
	# Fall back to self if current_scene is null (e.g. during headless tests).
	var parent: Node = get_tree().current_scene if get_tree().current_scene else self
	parent.add_child(player)
	player.global_position = position
	player.play()
	player.finished.connect(player.queue_free)
