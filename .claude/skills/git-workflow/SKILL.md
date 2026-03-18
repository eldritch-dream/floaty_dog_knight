# Skill: Git Workflow

**Triggered when**: about to make a commit or create a branch.

---

## Branch Strategy

| Branch | Purpose |
|---|---|
| `main` | Protected. Stable, releasable builds only. |
| `dev` | Integration branch. All feature branches merge here first. |
| `feature/*` | One branch per feature or fix. Branch from `dev`, PR back to `dev`. |

Example branch names:
- `feature/enemy-patrol-state`
- `feature/wall-jump`
- `fix/camera-clip-corners`
- `ci/gut-headless-workflow`

---

## Conventional Commit Format

```
<type>: <short imperative description>
```

Types used in this project:

| Type | When to use |
|---|---|
| `feat` | New gameplay feature or mechanic |
| `test` | Adding or updating tests |
| `fix` | Bug fix |
| `ci` | Changes to GitHub Actions or CI scripts |
| `chore` | Tooling, config, non-functional changes |
| `docs` | Documentation only |
| `refactor` | Code restructure with no behaviour change |
| `tune` | GameConfig value adjustments (feel/balance tweaks) |

### Project-specific examples

```
feat: add enemy patrol state
feat: wall jump with configurable wall slide speed
test: add dash distance regression test
fix: camera clip on tight corners
fix: coyote timer not resetting on re-land
ci: add GUT headless workflow for PRs to main
ci: add Windows/Linux export workflow on merge to main
chore: add agent skills for project conventions
tune: increase air_jump_velocity to 11.0 for better feel
refactor: extract gravity helper into shared utility
```

---

## Rule

> **Run GUT before every commit. Never commit with a failing test.**

```powershell
.\run_tests.ps1   # must exit 0 before committing
```

If a test fails, fix it before touching anything else.

---

## PR Checklist

Before opening a PR, confirm all of the following:

- [ ] GUT test suite passes (`run_tests.ps1` exits 0)
- [ ] No magic numbers — all tunable values go through `GameConfig`
- [ ] `GameConfig` default `.tres` updated if new parameters were added
- [ ] `SKILL.md` updated if the architecture changed (new state, new system, etc.)
- [ ] Commit messages follow Conventional Commit format
- [ ] Branch targets `dev` (not `main`) unless it is a CI/release workflow

---

## Pre-commit Hooks (Phase 3)

> Planned for Phase 3. Will enforce:
> - `gdlint` on staged `.gd` files
> - Block commit if any `tests/unit/` test fails
> - Warn if an `@export` var is removed from `GameConfig`
