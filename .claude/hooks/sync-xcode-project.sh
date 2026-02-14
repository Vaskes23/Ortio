#!/bin/bash
# Regenerate Xcode project from project.yml after file changes
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip files outside the project (empty path or irrelevant locations)
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# Regenerate .xcodeproj from project.yml
if [[ -f "project.yml" ]] && command -v xcodegen &>/dev/null; then
  xcodegen generate --quiet 2>&1 || true
fi

exit 0
