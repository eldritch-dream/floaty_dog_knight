# Doggo Knight — Agent Skills

Agent Skills capture the actual architecture of this project so Claude can make well-informed changes without re-reading the entire codebase every session. **Skills must always reflect actual code, never aspirational state.**

---

## Skills Index

| Skill | File | Triggered when |
|---|---|---|
| **Godot Movement** | `.claude/skills/godot-movement/SKILL.md` | Modifying player movement, camera behaviour, or adding new movement abilities |
| **GUT Testing** | `.claude/skills/gut-testing/SKILL.md` | Creating a new script or writing tests |
| **Git Workflow** | `.claude/skills/git-workflow/SKILL.md` | About to make a commit or create a branch |
| **Godot Conventions** | `.claude/skills/godot-conventions/SKILL.md` | Creating a new scene, script, or node structure |
| **Combat** | `.claude/skills/combat/SKILL.md` | Modifying combat, damage, hitboxes, dodge, stamina, or progression |

---

## What each Skill covers

### godot-movement
- Full CharacterBody3D movement architecture (player.gd + StateMachine delegation)
- All GameConfig @export parameter names, current values, and tuning notes
- SpringArm3D camera rig setup and the camera-relative movement pattern
- All PlayerStateMachine states and every valid transition, as coded
- Rule: never change movement feel without updating regression tests and PR sign-off

### gut-testing
- Test folder structure (`tests/unit/`, `tests/integration/`)
- GUT file naming convention (`test_*.gd`)
- How to write unit tests for 3D physics using manual simulation loops (no physics server)
- Mock/scene patterns for tests that need the scene tree
- How to run GUT headlessly (Windows PowerShell + Linux/CI)
- Rule: every new `.gd` file in `scripts/` needs a test file
- `scripts/new_test.sh` — scaffolds a new test file and adds it to git tracking

### git-workflow
- Branch strategy: `main` (protected), `dev`, `feature/*`
- Conventional commit format with project-specific examples
- Rule: run GUT before every commit, never commit a failing test
- PR checklist: tests, no magic numbers, GameConfig used, SKILL.md updated if architecture changed

### godot-conventions
- Full project folder structure as it exists now
- Naming conventions: PascalCase scenes/nodes/classes, snake_case scripts/variables
- Autoloads: `WorldManager` registered; rule: no `class_name` on autoloads
- GameConfig / PlayerStats / AbilityUnlocks resource pattern and decoupling rules
- Node naming inside `player.tscn`
- World geometry rule: CSG primitives OK during dev, mark with TODO comment
- All registered input actions (including `dodge` Q/LB, `heavy_attack` RMB/Y)

### combat
- Full combat architecture: HitBox/HurtBox pattern, ComboSystem, WeaponBase/Sword
- Stamina system: spend_stamina(), tick(), regen delay
- Dodge i-frame mechanics
- XPOrb collection and gain_xp() call signature
- WorldManager autoload and Portal trigger
- XP/level curve formula
- Rules: ability gating before transition; PlayerStats never references GameConfig

---

## How to update a Skill

When architecture changes (new state, new system, new GameConfig param, new scene structure):

1. Open the relevant `SKILL.md`
2. Edit the section that changed — update values, add rows, remove stale entries
3. Do **not** leave aspirational or planned values; only write what exists in code right now
4. Commit with: `chore: update <skill-name> SKILL.md — <what changed>`

If a change affects multiple Skills (e.g. adding a new state touches both godot-movement and godot-conventions), update both in the same commit.

---

## Integrity rule

Before writing any file, Claude must verify that every value, path, node name, and parameter name in a SKILL.md matches what is actually in the codebase. If a discrepancy is found, flag it and update the Skill — do not silently trust stale Skill data over observed code.
