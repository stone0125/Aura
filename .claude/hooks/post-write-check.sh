#!/bin/bash
# =============================================================================
# post-write-check.sh — PostToolUse Hook: Validate Written/Edited Files
#
# For .dart files:
#   - Check for dependency layer violations (models importing providers, etc.)
#   - Check for hardcoded API keys/secrets
# For .js files in functions/:
#   - Run node --check for syntax validation
#
# Input: JSON on stdin with tool_input.file_path (Write) or tool_input.file_path (Edit)
# Output: JSON on stdout with additionalContext feedback
# =============================================================================

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Extract file path — Write tool uses "file_path", Edit tool uses "file_path"
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# If no file path found, nothing to check
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  echo '{"continue": true}'
  exit 0
fi

WARNINGS=""

# --- Dart file checks ---
if [[ "$FILE_PATH" == *.dart ]]; then

  # Check dependency layering: models/ must not import services/providers/screens/widgets
  if [[ "$FILE_PATH" == */models/* ]]; then
    VIOLATION=$(grep -nE "import\s+['\"].*/(providers|services|screens|widgets)/" "$FILE_PATH" 2>/dev/null || true)
    if [ -n "$VIOLATION" ]; then
      WARNINGS="${WARNINGS}DEPENDENCY VIOLATION in models/: Cannot import from providers/, services/, screens/, or widgets/. Found: ${VIOLATION}\n"
    fi
  fi

  # Check dependency layering: services/ must not import providers/screens/widgets
  if [[ "$FILE_PATH" == */services/* ]]; then
    VIOLATION=$(grep -nE "import\s+['\"].*/(providers|screens|widgets)/" "$FILE_PATH" 2>/dev/null || true)
    if [ -n "$VIOLATION" ]; then
      WARNINGS="${WARNINGS}DEPENDENCY VIOLATION in services/: Cannot import from providers/, screens/, or widgets/. Found: ${VIOLATION}\n"
    fi
  fi

  # Check dependency layering: providers/ must not import screens/widgets
  if [[ "$FILE_PATH" == */providers/* ]]; then
    VIOLATION=$(grep -nE "import\s+['\"].*/(screens|widgets)/" "$FILE_PATH" 2>/dev/null || true)
    if [ -n "$VIOLATION" ]; then
      WARNINGS="${WARNINGS}DEPENDENCY VIOLATION in providers/: Cannot import from screens/ or widgets/. Found: ${VIOLATION}\n"
    fi
  fi

  # Check dependency layering: config/ must not import models/services/providers/screens/widgets
  if [[ "$FILE_PATH" == */config/* ]]; then
    VIOLATION=$(grep -nE "import\s+['\"].*/(models|services|providers|screens|widgets)/" "$FILE_PATH" 2>/dev/null || true)
    if [ -n "$VIOLATION" ]; then
      WARNINGS="${WARNINGS}DEPENDENCY VIOLATION in config/: Cannot import from models/, services/, providers/, screens/, or widgets/. Found: ${VIOLATION}\n"
    fi
  fi

  # Check dependency layering: utils/ must not import any app-level code
  if [[ "$FILE_PATH" == */utils/* ]]; then
    VIOLATION=$(grep -nE "import\s+['\"].*/(models|config|services|providers|screens|widgets)/" "$FILE_PATH" 2>/dev/null || true)
    if [ -n "$VIOLATION" ]; then
      WARNINGS="${WARNINGS}DEPENDENCY VIOLATION in utils/: Cannot import from any app-level code. Found: ${VIOLATION}\n"
    fi
  fi

  # Check dependency layering: widgets/ must not import screens
  if [[ "$FILE_PATH" == */widgets/* ]]; then
    VIOLATION=$(grep -nE "import\s+['\"].*/(screens)/" "$FILE_PATH" 2>/dev/null || true)
    if [ -n "$VIOLATION" ]; then
      WARNINGS="${WARNINGS}DEPENDENCY VIOLATION in widgets/: Cannot import from screens/. Found: ${VIOLATION}\n"
    fi
  fi

  # Check for hardcoded secrets/API keys
  SECRET_MATCH=$(grep -niE '(AIza[A-Za-z0-9_-]{35}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{36})' "$FILE_PATH" 2>/dev/null || true)
  if [ -n "$SECRET_MATCH" ]; then
    WARNINGS="${WARNINGS}POSSIBLE SECRET DETECTED: Hardcoded API key found. Use environment variables or defineSecret instead. Found: ${SECRET_MATCH}\n"
  fi
fi

# --- JS file checks (Cloud Functions) ---
if [[ "$FILE_PATH" == *.js ]] && [[ "$FILE_PATH" == */functions/* ]]; then
  SYNTAX_ERROR=$(node --check "$FILE_PATH" 2>&1 || true)
  if [ -n "$SYNTAX_ERROR" ]; then
    WARNINGS="${WARNINGS}JS SYNTAX ERROR: ${SYNTAX_ERROR}\n"
  fi
fi

# --- Output results ---
if [ -n "$WARNINGS" ]; then
  # Escape warnings for JSON
  ESCAPED_WARNINGS=$(echo -e "$WARNINGS" | jq -Rs .)
  jq -n --argjson warnings "$ESCAPED_WARNINGS" '{
    "continue": true,
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "additionalContext": $warnings
    }
  }'
else
  echo '{"continue": true}'
fi

exit 0
