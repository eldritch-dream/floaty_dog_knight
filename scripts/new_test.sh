#!/usr/bin/env bash
# new_test.sh — scaffold a GUT test file for a given script.
#
# Usage:
#   bash scripts/new_test.sh scripts/player/states/wall_jump.gd
#
# What it does:
#   1. Derives the test file name from the script path
#   2. Creates tests/unit/test_<name>.gd with the correct GUT scaffold
#   3. Runs `git add` on the new file

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: bash scripts/new_test.sh <path/to/script.gd>" >&2
    exit 1
fi

SCRIPT_PATH="$1"

# Validate the path looks like a .gd file.
if [[ "$SCRIPT_PATH" != *.gd ]]; then
    echo "Error: argument must be a .gd file path" >&2
    exit 1
fi

# Derive basename without extension, strip leading path.
SCRIPT_BASENAME=$(basename "$SCRIPT_PATH" .gd)

# Build test file path.
TEST_FILE="tests/unit/test_${SCRIPT_BASENAME}.gd"

# Resolve project root (directory containing this script's parent).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FULL_TEST_PATH="${PROJECT_ROOT}/${TEST_FILE}"

if [[ -f "$FULL_TEST_PATH" ]]; then
    echo "Error: test file already exists: $TEST_FILE" >&2
    exit 1
fi

# Write the scaffold.
cat > "$FULL_TEST_PATH" << SCAFFOLD
extends GutTest
## Tests for ${SCRIPT_BASENAME}.
## TODO: describe what this covers.

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()
	# TODO: set config values relevant to this script.


func test_placeholder() -> void:
	# TODO: replace with a real assertion.
	assert_true(true, "placeholder — replace this test")
SCAFFOLD

echo "Created: $TEST_FILE"

# Add to git tracking.
cd "$PROJECT_ROOT"
git add "$TEST_FILE"
echo "git add: $TEST_FILE"
