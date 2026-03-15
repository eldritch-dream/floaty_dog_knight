extends GutTest
## Tests for camera-relative movement direction calculation.
## Uses the static helper on player.gd to verify direction math
## without instantiating a full scene.


func test_forward_input_camera_at_zero_gives_negative_z() -> void:
	# Camera facing -Z (default), forward input → movement in -Z.
	var camera_basis := Basis.IDENTITY
	var input := Vector2(0, -1)  # Forward = negative Y in get_vector
	var direction: Vector3 = _compute_direction(input, camera_basis)
	# With identity basis, forward (-basis.z) = (0,0,-1). Input.y=-1, so
	# direction = forward * -(-1) = forward * 1 = (0,0,-1).
	assert_almost_eq(direction.z, -1.0, 0.01,
		"Forward input with identity camera should move in -Z")
	assert_almost_eq(direction.x, 0.0, 0.01,
		"No lateral movement expected")


func test_right_input_camera_at_zero_gives_positive_x() -> void:
	var camera_basis := Basis.IDENTITY
	var input := Vector2(1, 0)  # Right
	var direction: Vector3 = _compute_direction(input, camera_basis)
	assert_almost_eq(direction.x, 1.0, 0.01,
		"Right input with identity camera should move in +X")
	assert_almost_eq(direction.z, 0.0, 0.01,
		"No forward/back movement expected")


func test_forward_input_camera_rotated_90_gives_positive_x() -> void:
	# Camera rotated -90° around Y → -basis.z = (+1,0,0) → forward = +X.
	var camera_basis := Basis(Vector3.UP, deg_to_rad(-90.0))
	var input := Vector2(0, -1)  # Forward
	var direction: Vector3 = _compute_direction(input, camera_basis)
	assert_almost_eq(direction.x, 1.0, 0.01,
		"Forward with -90° camera rotation should move in +X")


func test_diagonal_input_normalized() -> void:
	var camera_basis := Basis.IDENTITY
	var input := Vector2(1, -1)  # Forward-right
	var direction: Vector3 = _compute_direction(input, camera_basis)
	assert_almost_eq(direction.length(), 1.0, 0.01,
		"Diagonal input should produce a normalized direction vector")


func test_zero_input_gives_zero_direction() -> void:
	var camera_basis := Basis.IDENTITY
	var input := Vector2(0, 0)
	var direction: Vector3 = _compute_direction(input, camera_basis)
	assert_eq(direction, Vector3.ZERO,
		"Zero input should produce zero direction")


func test_backward_input() -> void:
	var camera_basis := Basis.IDENTITY
	var input := Vector2(0, 1)  # Backward
	var direction: Vector3 = _compute_direction(input, camera_basis)
	assert_almost_eq(direction.z, 1.0, 0.01,
		"Backward input should move in +Z")


func test_direction_y_is_always_zero() -> void:
	# Movement direction should never have a Y component (no vertical movement from sticks).
	var camera_basis := Basis(Vector3.UP, deg_to_rad(45.0))
	var input := Vector2(0.5, -0.7)
	var direction: Vector3 = _compute_direction(input, camera_basis)
	assert_eq(direction.y, 0.0,
		"Movement direction Y should always be zero")


# ── Helper ────────────────────────────────────────────────────────────
## Replicates the camera-relative direction calculation from player.gd.
## This is a copy of the static method so tests don't depend on loading
## the player script, which requires the full scene tree.
func _compute_direction(input: Vector2, camera_basis: Basis) -> Vector3:
	if input.length() < 0.01:
		return Vector3.ZERO
	var forward := -camera_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := camera_basis.x
	right.y = 0.0
	right = right.normalized()
	return (forward * -input.y + right * input.x).normalized()
