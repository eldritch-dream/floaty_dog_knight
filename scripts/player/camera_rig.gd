class_name CameraRig
extends Node3D
## Over-the-shoulder camera rig. Handles mouse + stick input for orbiting.
## Child of the player — follows automatically. Contains SpringArm3D + Camera3D.

var config: GameConfig

## Internal pitch tracker (radians).
var _pitch: float = 0.0


func setup(game_config: GameConfig, spring_arm: SpringArm3D) -> void:
	config = game_config
	spring_arm.spring_length = config.camera_distance
	# Offset the spring arm upward for over-the-shoulder feel.
	spring_arm.position.y = config.camera_height


func handle_mouse_input(event: InputEventMouseMotion) -> void:
	if not config:
		return
	# Horizontal orbit (yaw) — rotate the entire rig around Y.
	rotate_y(-event.relative.x * config.camera_sensitivity)
	# Vertical orbit (pitch) — rotate within clamped range.
	_pitch -= event.relative.y * config.camera_sensitivity
	_pitch = clampf(_pitch, deg_to_rad(config.camera_pitch_min), deg_to_rad(config.camera_pitch_max))
	# Apply pitch to SpringArm3D (first child).
	var spring_arm := get_child(0) as SpringArm3D
	if spring_arm:
		spring_arm.rotation.x = _pitch


func handle_gamepad_look(delta: float) -> void:
	if not config:
		return
	var look_x := Input.get_axis("camera_look_left", "camera_look_right")
	var look_y := Input.get_axis("camera_look_up", "camera_look_down")
	if abs(look_x) > 0.1:
		rotate_y(-look_x * config.gamepad_camera_sensitivity * delta)
	if abs(look_y) > 0.1:
		_pitch -= look_y * config.gamepad_camera_sensitivity * delta
		_pitch = clampf(_pitch, deg_to_rad(config.camera_pitch_min), deg_to_rad(config.camera_pitch_max))
		var spring_arm := get_child(0) as SpringArm3D
		if spring_arm:
			spring_arm.rotation.x = _pitch
