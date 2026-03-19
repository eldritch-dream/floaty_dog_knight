extends GutTest
## Unit tests for HitBox and HurtBox interaction.
## Uses plain Resource/Object instances — no scene tree needed.

var hit_box: HitBox
var hurt_box: HurtBox
var stats: PlayerStats
var source_node: Node

func before_each() -> void:
	source_node = Node.new()
	add_child(source_node)

	stats = PlayerStats.new()
	stats.max_health = 100.0
	stats.health = 100.0

	hit_box = HitBox.new()
	add_child(hit_box)

	hurt_box = HurtBox.new()
	hurt_box.stats = stats
	hurt_box.owner_node = Node.new()
	add_child(hurt_box)


func after_each() -> void:
	hit_box.queue_free()
	hurt_box.queue_free()
	if hurt_box.owner_node:
		hurt_box.owner_node.queue_free()
	source_node.queue_free()

# ── HitBox state ─────────────────────────────────────────────────────────────

func test_hitbox_inactive_by_default() -> void:
	assert_false(hit_box.monitoring)
	assert_false(hit_box.monitorable)

func test_activate_enables_monitoring() -> void:
	hit_box.activate(10.0, source_node)
	assert_true(hit_box.monitoring)
	assert_true(hit_box.monitorable)

func test_deactivate_disables_monitoring() -> void:
	hit_box.activate(10.0, source_node)
	hit_box.deactivate()
	assert_false(hit_box.monitoring)
	assert_false(hit_box.monitorable)

func test_activate_sets_damage() -> void:
	hit_box.activate(25.0, source_node)
	assert_eq(hit_box.damage, 25.0)

func test_activate_sets_source() -> void:
	hit_box.activate(10.0, source_node)
	assert_eq(hit_box.source, source_node)

# ── HurtBox ──────────────────────────────────────────────────────────────────

func test_receive_hit_reduces_health() -> void:
	hurt_box.receive_hit(30.0, source_node)
	assert_eq(stats.health, 70.0)

func test_receive_hit_emits_damaged_signal() -> void:
	watch_signals(hurt_box)
	hurt_box.receive_hit(10.0, source_node)
	assert_signal_emitted(hurt_box, "damaged")

func _make_node_with_invincible(value: bool) -> Node:
	var n := Node.new()
	var s := GDScript.new()
	s.source_code = "extends Node\nvar is_invincible: bool = %s\n" % str(value).to_lower()
	s.reload()
	n.set_script(s)
	add_child(n)
	return n


func test_receive_hit_skipped_when_invincible() -> void:
	var invincible_owner := _make_node_with_invincible(true)
	hurt_box.owner_node = invincible_owner
	hurt_box.receive_hit(50.0, source_node)
	assert_eq(stats.health, 100.0)
	invincible_owner.queue_free()


func test_receive_hit_works_when_not_invincible() -> void:
	var normal_owner := _make_node_with_invincible(false)
	hurt_box.owner_node = normal_owner
	hurt_box.receive_hit(20.0, source_node)
	assert_eq(stats.health, 80.0)
	normal_owner.queue_free()
