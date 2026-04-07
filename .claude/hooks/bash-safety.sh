#!/bin/bash
# =============================================================================
# bash-safety.sh — PreToolUse Hook: Validate Bash Commands Before Execution
#
# Blocks dangerous operations:
#   - git push --force to master (allows --force-with-lease)
#   - Broad recursive deletes (rm -rf /, rm -rf *, rm -rf ., rm -rf ..)
#   - git reset --hard without a specific ref
#   - firebase deploy without --only flag
#
# Known limitation: grep-based detection may match dangerous patterns inside
# string literals or heredocs. This is a trade-off for simplicity.
#
# Input: JSON on stdin with tool_input.command
# Output: JSON on stdout with permissionDecision
# Exit 0 = success (use JSON decision)
# =============================================================================

set -e

# Read JSON input from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# If we can't parse the command, allow (don't break normal usage)
if [ -z "$COMMAND" ]; then
  echo '{"continue": true}'
  exit 0
fi

# Helper: output deny JSON and exit
deny() {
  jq -n --arg reason "$1" '{
    "continue": false,
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $reason
    }
  }'
  exit 0
}

# --- Allow --force-with-lease (safer alternative, check before --force) ---
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force-with-lease'; then
  echo '{"continue": true}'
  exit 0
fi

# --- Block force push to master (handles --force and -f in any position) ---
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(--force|-f)\s.*\bmaster\b|git\s+push\s+.*\bmaster\b.*(--force|-f)'; then
  deny "Force push to master is blocked. Use a feature branch or --force-with-lease instead."
fi

# --- Block broad recursive deletes ---
# Matches: rm -rf /, rm -rf *, rm -rf ., rm -rf .., rm -fr /, rm -r -f /, rm --recursive --force /
# Does NOT match: rm -rf /tmp/specific-dir (absolute paths with subdirectories are allowed)
if echo "$COMMAND" | grep -qE 'rm\s+(-rf|-fr|-r\s+-f|-f\s+-r|--recursive\s+--force|--force\s+--recursive)\s+(/($|\s|;|&&|\|)|\*|\.\.|\.($|\s|;|&&|\|))'; then
  deny "Broad recursive delete is blocked. Specify exact paths to delete."
fi

# --- Block git reset --hard without specific ref (including chained commands) ---
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard(\s*$|\s*[;&|])'; then
  deny "git reset --hard without a specific ref is blocked. Specify a commit hash or branch."
fi

# --- Block accidental full firebase deploy (including chained commands) ---
if echo "$COMMAND" | grep -qE 'firebase\s+deploy(\s*$|\s*[;&|])'; then
  deny "Full firebase deploy is blocked. Use 'firebase deploy --only functions' (or --only firestore:rules, etc.)."
fi

# --- Allow everything else ---
echo '{"continue": true}'
exit 0
