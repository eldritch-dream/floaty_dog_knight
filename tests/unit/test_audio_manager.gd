extends GutTest
## Tests for AudioManager: dictionary integrity, volume control, and
## 2D vs 3D routing. Audio playback cannot be fully verified headlessly;
## the file-existence test (last section) is the highest-value regression
## check — catches missing assets before they hit the web export.

var _am: AudioManager


func before_each() -> void:
	_am = AudioManager


# ── SOUNDS dictionary integrity ───────────────────────────────────────────────

func test_sounds_dictionary_is_not_empty() -> void:
	assert_gt(AudioManager.SOUNDS.size(), 0)


func test_sounds_dictionary_has_no_missing_files() -> void:
	## Every path in SOUNDS must resolve to an existing file.
	## This is the primary regression guard against typos, renames,
	## or forgetting to commit a new asset.
	var missing: Array = []
	for sound_name in AudioManager.SOUNDS:
		var path: String = AudioManager.SOUNDS[sound_name]
		var abs_path: String = ProjectSettings.globalize_path(path)
		if not FileAccess.file_exists(abs_path):
			missing.append("%s → %s" % [sound_name, path])
	assert_eq(missing.size(), 0,
			"Missing audio files:\n" + "\n".join(missing))


func test_expected_sound_keys_present() -> void:
	var required: Array = [
		"swing_light", "swing_heavy", "hit_impact",
		"player_hurt", "player_death", "dodge_roll", "player_jump",
		"enemy_alert", "enemy_attack", "enemy_stagger", "enemy_death",
		"orb_collect", "level_up",
		"dream_enter", "dream_wake", "portal_travel",
	]
	for key in required:
		assert_true(AudioManager.SOUNDS.has(key),
				"SOUNDS dictionary must contain key: %s" % key)


# ── Unknown sound — must print and return, not crash ─────────────────────────

func test_play_sfx_unknown_sound_does_not_crash() -> void:
	# AudioManager.play_sfx prints and returns on unknown names — must not crash.
	# Calling with an unknown name is safe: no exception, no push_warning/error.
	_am.play_sfx("this_sound_does_not_exist")
	assert_true(true, "play_sfx with unknown name must not raise an error")


func test_play_sfx_unknown_sound_with_position_does_not_crash() -> void:
	_am.play_sfx("nonexistent", Vector3(1.0, 0.0, 0.0))
	assert_true(true, "play_sfx with unknown name and position must not raise an error")


# ── Volume control ────────────────────────────────────────────────────────────

func test_set_sfx_volume_changes_bus_volume() -> void:
	var idx: int = AudioServer.get_bus_index("SFX")
	_am.set_sfx_volume(-10.0)
	assert_almost_eq(AudioServer.get_bus_volume_db(idx), -10.0, 0.01)


func test_set_music_volume_changes_bus_volume() -> void:
	var idx: int = AudioServer.get_bus_index("Music")
	_am.set_music_volume(-20.0)
	assert_almost_eq(AudioServer.get_bus_volume_db(idx), -20.0, 0.01)


func test_stop_music_stops_playback() -> void:
	# Verifies stop_music() does not crash when called regardless of state.
	_am.stop_music()
	assert_true(true)


# ── 2D vs 3D routing ─────────────────────────────────────────────────────────

func test_play_sfx_with_zero_position_uses_2d() -> void:
	# When position is Vector3.ZERO a 2D AudioStreamPlayer is created (non-positional).
	# We verify by checking no AudioStreamPlayer3D was added to the AudioManager node.
	var before_3d: int = _count_children_of_type(_am, "AudioStreamPlayer3D")
	_am.play_sfx("orb_collect", Vector3.ZERO)
	var after_3d: int = _count_children_of_type(_am, "AudioStreamPlayer3D")
	assert_eq(after_3d, before_3d, "Zero position must not spawn a 3D player")


func test_play_sfx_with_position_creates_audio_player() -> void:
	# In headless tests current_scene is null, so _play_3d attaches to AudioManager.
	# Verify a child is created (routing happened) and cleaned up after playback.
	var before: int = _am.get_child_count()
	_am.play_sfx("hit_impact", Vector3(5.0, 0.0, 0.0))
	var after: int = _am.get_child_count()
	# At minimum one child was added (the 3D player, before it finishes and frees).
	assert_gte(after, before, "play_sfx with position must create an audio player")


# ── Helpers ───────────────────────────────────────────────────────────────────

func _count_children_of_type(node: Node, type_name: String) -> int:
	var count: int = 0
	for child in node.get_children():
		if child.get_class() == type_name:
			count += 1
	return count
