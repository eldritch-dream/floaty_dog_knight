extends CanvasLayer
## Simple debug overlay: shows health, stamina, level, and XP each frame.
## Assign the PlayerStats resource via @export in the scene.

@export var stats: PlayerStats

@onready var label: Label = $Label


func _process(_delta: float) -> void:
	if not stats or not label:
		return
	label.text = (
		"HP:  %.0f / %.0f\nST:  %.0f / %.0f\nLVL: %d\nXP:  %d / %d" % [
			stats.health, stats.max_health,
			stats.stamina, stats.max_stamina,
			stats.level,
			stats.xp,
			int(100 * pow(stats.level, 1.5))  # mirrors xp_required formula
		]
	)
