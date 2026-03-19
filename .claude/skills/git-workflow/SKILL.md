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

## Pre-commit Hooks

Install with `bash scripts/install_hooks.sh`. Enforces:
- `gdlint` on staged `.gd` files (requires `pip install gdtoolkit`)
- Block commit if any `tests/unit/` test fails (requires Godot on PATH or `GODOT_EXE`)
- Warn if an `@export` var is removed from `GameConfig`

Skip GUT locally with `SKIP_GUT=1 git commit` — does not bypass CI.

---

## Release Pipeline

Full end-to-end flow from feature branch to itch.io:

1. **Develop** on `feature/*` branch, branched from `dev`
2. **PR feature/* → dev** — CI runs GUT suite; must pass before merge
3. **PR dev → main** — CI runs GUT suite again; must pass before merge
4. **Push to main** triggers `export.yml` (single workflow, confirmed working):
   - Builds Windows (`DoggoKnight.exe`, PCK embedded) and Web (`DoggoKnight-web.zip`)
   - Creates a GitHub Release with both artifacts and a version tag
   - Installs butler from `github.com/itchio/butler` releases (extracts to `linux-amd64/butler`)
   - Pushes Windows build to itch.io channel `windows-64` via butler
   - Pushes Web build to itch.io channel `html5` via butler
   - Both pushes tagged with the release version via `--userversion`
5. **Verify** both channels are live on the itch.io dashboard

### itch.io web build requirement

> **Warning**: The web build requires **SharedArrayBuffer** enabled in itch.io game
> settings under **Embed options → SharedArrayBuffer support**. Without it the
> Godot 4 web export will not load in the browser.

### Secrets required

| Secret | Purpose |
|---|---|
| `BUTLER_API_KEY` | Butler authentication for itch.io pushes |
| `GITHUB_TOKEN` | Auto-provided by Actions; used to create GitHub releases |
