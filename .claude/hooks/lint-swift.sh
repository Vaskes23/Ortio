#!/bin/bash
# Run SwiftLint on changed Swift files
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only lint Swift files
if [[ "$FILE_PATH" != *.swift ]]; then
  exit 0
fi

# Only lint if file exists (might have been moved/deleted)
if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

if command -v swiftlint &>/dev/null; then
  # Lint the specific file, auto-fix what we can
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swiftlint lint --quiet "$FILE_PATH" 2>&1 || true
fi

exit 0
