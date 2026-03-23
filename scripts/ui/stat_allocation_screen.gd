class_name StatAllocationScreen
extends Control
## Dream stat allocation UI. Shown inside the DreamManager overlay.
## Displays unspent stat points and lets the player invest in Constitution or Endurance.
## The Wake Up button is disabled until all points are spent.
##
## Call setup(stats) before adding to the scene tree.

var _stats: PlayerStats = null

# Node references — built procedurally in setup() to avoid scene dependency.
var _points_label: Label
var _wake_btn: Button
var _stat_rows: Dictionary = {}  # stat_name -> { label, btn }


func setup(stats: PlayerStats) -> void:
	_stats = stats
	_build_ui()
	_refresh()
	_stats.stat_points_pending.connect(_on_stat_points_pending)
	_stats.stat_invested.connect(_on_stat_invested)


func _build_ui() -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(400, 0)
	add_child(vbox)

	var title: Label = Label.new()
	title.text = "The Dream"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	_points_label = Label.new()
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_points_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_points_label)

	vbox.add_child(_make_separator())

	if _stats:
		for stat_name: String in ["constitution", "endurance"]:
			_stat_rows[stat_name] = _make_stat_row(vbox, stat_name)

	vbox.add_child(_make_separator())

	_wake_btn = Button.new()
	_wake_btn.text = "Wake Up"
	_wake_btn.pressed.connect(DreamManager.exit_dream)
	vbox.add_child(_wake_btn)


func _make_stat_row(parent: VBoxContainer, stat_name: String) -> Dictionary:
	if not _stats:
		return {}
	var info: Dictionary = _stats.get_investable_stats().get(stat_name, {})

	var hbox: HBoxContainer = HBoxContainer.new()
	parent.add_child(hbox)

	var desc: Label = Label.new()
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.text = "%s — %s" % [info.get("label", stat_name), info.get("description", "")]
	hbox.add_child(desc)

	var val_label: Label = Label.new()
	val_label.custom_minimum_size = Vector2(120, 0)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(val_label)

	var btn: Button = Button.new()
	btn.text = "Invest"
	btn.pressed.connect(_on_invest_pressed.bind(stat_name))
	hbox.add_child(btn)

	return {"val_label": val_label, "btn": btn}


func _make_separator() -> HSeparator:
	var sep: HSeparator = HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 8)
	return sep


func _refresh() -> void:
	if not _stats:
		return
	var points: int = _stats.unspent_stat_points
	_points_label.text = "Points to spend: %d" % points
	_wake_btn.disabled = points > 0

	var investable: Dictionary = _stats.get_investable_stats()
	for stat_name: String in _stat_rows:
		var row: Dictionary = _stat_rows[stat_name]
		var info: Dictionary = investable.get(stat_name, {})
		var current: float = info.get("current", 0.0)
		var gain: float = info.get("gain", 0.0)
		(row["val_label"] as Label).text = "%.0f → %.0f" % [current, current + gain]
		(row["btn"] as Button).disabled = points <= 0


func _on_invest_pressed(stat_name: String) -> void:
	if _stats:
		_stats.invest_in_stat(stat_name)


func _on_stat_points_pending(_amount: int) -> void:
	_refresh()


func _on_stat_invested(_stat_name: String, _new_value: float) -> void:
	_refresh()
