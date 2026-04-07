#!/bin/bash
# =============================================================================
# pre-completion-check.sh — Stop Hook: Pre-Completion Verification
#
# Runs quick checks before Claude finishes its response:
#   - Reports uncommitted changes count
#   - Runs flutter analyze (with timeout)
#   - Checks dart format compliance
#
# Non-blocking: always exit 0, provides additionalContext feedback
# Input: JSON on stdin
# Output: JSON on stdout with additionalContext
# =============================================================================

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT" 2>/dev/null || true

CONTEXT=""

# --- Check for uncommitted changes ---
CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$CHANGES" -gt 0 ]; then
  CONTEXT="${CONTEXT}[Git] ${CHANGES} uncommitted change(s) in the working tree.\n"
fi

# --- Try to find Flutter SDK in common locations ---
if ! command -v flutter &>/dev/null; then
  for candidate in "$HOME/development/flutter/bin" "$HOME/.local/share/flutter/bin" "$HOME/fvm/default/bin" "/opt/homebrew/bin"; do
    if [ -x "$candidate/flutter" ]; then
      export PATH="$candidate:$PATH"
      break
    fi
  done
fi

# --- macOS-compatible timeout using perl (no GNU coreutils needed) ---
run_with_timeout() {
  local secs="$1"
  shift
  perl -e 'alarm(shift @ARGV); exec @ARGV' "$secs" "$@"
}

# --- Run flutter analyze and dart format only if available ---
if command -v flutter &>/dev/null; then
  # --- Run flutter analyze (timeout 30s to avoid blocking) ---
  ANALYZE_OUTPUT=$(run_with_timeout 30 flutter analyze --no-pub 2>&1 || true)
  if echo "$ANALYZE_OUTPUT" | grep -q "error"; then
    ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "error" || echo "0")
    CONTEXT="${CONTEXT}[Analyze] flutter analyze found ${ERROR_COUNT} error(s). Run 'flutter analyze' for details.\n"
  fi

  # --- Check dart format compliance (timeout 15s) ---
  FORMAT_EXIT=0
  dart format --set-exit-if-changed --output=none lib/ >/dev/null 2>&1 || FORMAT_EXIT=$?
  if [ "$FORMAT_EXIT" != "0" ]; then
    CONTEXT="${CONTEXT}[Format] Some files need formatting. Run 'dart format lib/'.\n"
  fi
fi

# --- Output results ---
if [ -n "$CONTEXT" ]; then
  ESCAPED_CONTEXT=$(echo -e "=== PRE-COMPLETION CHECKLIST ===\n${CONTEXT}=== END CHECKLIST ===" | jq -Rs .)
  jq -n --argjson context "$ESCAPED_CONTEXT" '{
    "continue": true,
    "hookSpecificOutput": {
      "hookEventName": "Stop",
      "additionalContext": $context
    }
  }'
else
  echo '{"continue": true}'
fi

exit 0
