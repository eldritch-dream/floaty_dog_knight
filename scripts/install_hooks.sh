#!/usr/bin/env bash
# Install Doggo Knight git hooks.
# Run once after cloning: bash scripts/install_hooks.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_SRC="$SCRIPT_DIR/hooks"
HOOKS_DEST="$PROJECT_ROOT/.git/hooks"

if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
    echo "Error: not a git repository (expected .git at $PROJECT_ROOT)" >&2
    exit 1
fi

echo "Installing git hooks from $HOOKS_SRC → $HOOKS_DEST"

for hook_file in "$HOOKS_SRC"/*; do
    hook_name=$(basename "$hook_file")
    dest="$HOOKS_DEST/$hook_name"
    cp "$hook_file" "$dest"
    chmod +x "$dest"
    echo "  Installed: .git/hooks/$hook_name"
done

echo ""
echo "Done. Hooks active:"
echo "  pre-commit  — gdlint, GameConfig guard, GUT unit tests"
echo ""
echo "Optional: install gdlint for the lint check:"
echo "  pip install gdtoolkit"
echo ""
echo "GUT runs by default if Godot is on PATH or GODOT_EXE is set."
echo "Skip with: SKIP_GUT=1 git commit ..."
