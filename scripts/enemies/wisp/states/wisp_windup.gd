extends WispState
## WindUp — telegraphs the incoming attack via a scale pulse on the visual mesh.
## Transitions to Attack after wisp_windup_duration.
## Transitions to Stagger immediately if hit (on_damaged called by WispEnemy).

var _timer: float = 0.0
var _interrupted: bool = false


func enter() -> void:
	_timer = config.wisp_windup_duration
	_interrupted = false


func exit() -> void:
	# Restore normal scale regardless of how we leave.
	if wisp.visual:
		wisp.visual.scale = Vector3.ONE


func physics_update(delta: float) -> void:
	if _interrupted:
		wisp.state_machine.transition_to("stagger")
		return

	_timer -= delta

	# Scale pulse: grows from 1.0 to 1.4 as wind-up progresses.
	if wisp.visual:
		var t: float = 1.0 - (_timer / config.wisp_windup_duration)
		var pulse: float = 1.0 + t * 0.4
		wisp.visual.scale = Vector3(pulse, pulse, pulse)

	# Hold position during wind-up.
	wisp.velocity.x = 0.0
	wisp.velocity.z = 0.0
	_apply_float(delta)
	wisp.move_and_slide()

	if _timer <= 0.0:
		wisp.state_machine.transition_to("attack")


## Called by WispEnemy.take_damage() to interrupt the wind-up.
func on_damaged() -> void:
	_interrupted = true


func _apply_float(delta: float) -> void:
	var target_y: float = wisp.spawn_y + config.wisp_float_height
	wisp.velocity.y = (target_y - wisp.global_position.y) * 8.0 * delta * 60.0
