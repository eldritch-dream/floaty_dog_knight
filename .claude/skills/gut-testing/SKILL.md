# Skill: GUT Testing

**Triggered when**: creating a new script or writing tests.

---

## Test Folder Structure

```
tests/
├── unit/           ← pure logic tests, no scene tree required
│   ├── test_camera_movement.gd
│   ├── test_coyote_time.gd
│   ├── test_dash_cooldown.gd
│   ├── test_jump_arc.gd
│   └── test_state_transitions.gd
└── integration/    ← currently empty (.gdkeep); reserved for full-scene tests
    └── .gdkeep
```

GUT config at `.gutconfig.json`:
```json
{
    "dirs": ["res://tests/unit", "res://tests/integration"],
    "include_subdirs": true,
    "prefix": "test_",
    "suffix": ".gd",
    "log_level": 1,
    "should_exit": true,
    "should_exit_on_success": false
}
```

---

## File Naming Convention

- Test files: `test_<subject>.gd` (e.g. `test_jump_arc.gd`)
- Unit tests go in `tests/unit/`
- Integration tests go in `tests/integration/`
- All test scripts extend `GutTest`

---

## Rule

> **Every new `.gd` file in `scripts/` must have a corresponding test file.**

New script at `scripts/player/states/wall_jump.gd` → test at `tests/unit/test_wall_jump.gd`.

---

## Writing Unit Tests for 3D Physics (Without the Physics Server)

The existing test suite deliberately avoids the physics server. Tests simulate timer countdown and velocity math directly in GDScript loops. This is the established pattern — follow it.

### Scaffold for a new unit test

```gdscript
extends GutTest
## One-line description of what this tests.

var config: GameConfig


func before_each() -> void:
    config = GameConfig.new()
    # Override only the values this test cares about.
    config.jump_velocity = 14.5


func test_example_assertion() -> void:
    var result := some_calculation(config)
    assert_almost_eq(result, expected, tolerance, "Description of what should be true")
```

### Simulating physics manually (the project pattern)

```gdscript
# Simulate n frames of physics at 60 FPS
var vel_y := config.jump_velocity
var dt    := 1.0 / 60.0
var height := 0.0
while vel_y > 0.0:
    vel_y -= gravity * dt
    height += vel_y * dt
```

### Testing StateMachine without a scene

```gdscript
var sm := StateMachine.new()
var parent := CharacterBody3D.new()
parent.add_child(sm)
# Add PlayerState children manually, register them in sm.states dict
add_child_autoqfree(parent)
```

### Mock pattern for anything touching the physics server

If a test absolutely must touch physics, instantiate the scene with `add_child_autoqfree` and `await get_tree().process_frame`. Prefer simulation loops over scene instantiation — they are faster and have no flakiness.

### Useful GUT assertions

| Assertion | Use |
|---|---|
| `assert_eq(a, b, msg)` | Exact equality |
| `assert_almost_eq(a, b, tol, msg)` | Float equality within tolerance |
| `assert_gt(a, b, msg)` | `a > b` |
| `assert_lt(a, b, msg)` | `a < b` |
| `assert_true(expr, msg)` | Boolean true |
| `assert_false(expr, msg)` | Boolean false |
| `watch_signals(node)` + `assert_signal_emitted(node, "name", msg)` | Signal testing |
| `add_child_autoqfree(node)` | Auto-frees node after test |

---

## Running GUT Headlessly

### Windows (PowerShell — the project script)

```powershell
.\run_tests.ps1
```

Requires Godot 4.5.1 console exe. Reads `$env:GODOT_EXE`; falls back to:
`C:\Users\smili\Documents\Godot\Installs\Godot_v4.5.1-stable_win64_console.exe`

### Linux/macOS (CI)

```bash
godot --headless --path . --display-driver headless --audio-driver Dummy \
      -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Exit code `0` = all tests pass. Any non-zero = failure.

---

## Manual Test Checklist Format

When generating a manual test checklist, use markdown checkbox format — the user works in a markdown editor and sends results back with boxes checked/unchecked:

```markdown
**Section Name**
- [ ] 1.1 Brief description of what to verify
- [ ] 1.2 Next check
- [ ] 1.3 Another check

**Next Section**
- [ ] 2.1 First check in section
- [ ] 2.2 Second check
```

Rules:
- Numbered denotations: `1.1`, `1.2`, `2.1`, etc. (section.item) inside the checkbox line
- Single line per check — no sub-bullets, no extra spacing within a section
- Blank line between sections only
- User checks boxes (`- [x]`) for pass, leaves unchecked for fail/skip, and sends back — Claude reads the result from the checkbox state
- Keep descriptions concise so lines stay readable in the editor

---

## scripts/new_test.sh

A scaffolding helper lives at `scripts/new_test.sh`. Usage:

```bash
bash scripts/new_test.sh scripts/player/states/wall_jump.gd
# → creates tests/unit/test_wall_jump.gd with correct scaffold
# → git add tests/unit/test_wall_jump.gd
```
