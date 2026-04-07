#!/bin/bash
# =============================================================================
# error-logger.sh — PostToolUseFailure Hook: Remind Claude to Log Errors
#
# When a tool fails, this hook reminds Claude to diagnose the root cause
# and record the lesson in .claude/rules/errors.md for self-reinforcement.
#
# Input: JSON on stdin with tool_name, tool_input, tool_response (error)
# Output: JSON on stdout with additionalContext prompt
# =============================================================================

set -e

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null)

jq -n --arg tool "$TOOL_NAME" '{
  "continue": true,
  "hookSpecificOutput": {
    "hookEventName": "PostToolUseFailure",
    "additionalContext": ("SELF-REINFORCEMENT: The " + $tool + " tool just failed. After fixing the issue, record the error, root cause, and fix in .claude/rules/errors.md so this mistake is not repeated in future sessions. Use the template in that file.")
  }
}'

exit 0
