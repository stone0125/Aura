#!/bin/bash
# =============================================================================
# install-git-hooks.sh — Install Git Pre-Commit Hook for Aura
#
# Run once: bash .claude/hooks/install-git-hooks.sh
#
# Installs a pre-commit hook that enforces:
#   - No hardcoded API keys/secrets in staged files
#   - dart format compliance on staged .dart files
#   - flutter analyze passes when .dart files are staged
#   - node --check syntax validation on staged .js files in functions/
# =============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK_TARGET="$PROJECT_ROOT/.git/hooks/pre-commit"

if [ -f "$HOOK_TARGET" ] && [ ! -L "$HOOK_TARGET" ]; then
  echo "WARNING: Existing pre-commit hook found at $HOOK_TARGET"
  echo "Backing up to ${HOOK_TARGET}.backup"
  cp "$HOOK_TARGET" "${HOOK_TARGET}.backup"
fi

cat > "$HOOK_TARGET" << 'HOOK'
#!/bin/bash
# =============================================================================
# Git Pre-Commit Hook for Aura
# Installed by: .claude/hooks/install-git-hooks.sh
# =============================================================================

set -e
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

echo "Running pre-commit checks..."

# 1. Check for hardcoded API keys/secrets in staged Dart and JS files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(dart|js)$' || true)
if [ -n "$STAGED_FILES" ]; then
  for file in $STAGED_FILES; do
    FULL_PATH="$PROJECT_ROOT/$file"
    if [ -f "$FULL_PATH" ]; then
      if grep -qE '(AIza[A-Za-z0-9_-]{35}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{36})' "$FULL_PATH"; then
        echo "ERROR: Possible API key detected in $file"
        echo "Remove the key and use environment variables or defineSecret instead."
        exit 1
      fi
    fi
  done
fi

# 2. Check dart format on staged .dart files
STAGED_DART=$(git diff --cached --name-only --diff-filter=ACM | grep '\.dart$' || true)
if [ -n "$STAGED_DART" ]; then
  echo "Checking Dart formatting..."
  UNFORMATTED=""
  for file in $STAGED_DART; do
    FULL_PATH="$PROJECT_ROOT/$file"
    if [ -f "$FULL_PATH" ]; then
      if ! dart format --set-exit-if-changed --output=none "$FULL_PATH" > /dev/null 2>&1; then
        UNFORMATTED="${UNFORMATTED}  $file\n"
      fi
    fi
  done
  if [ -n "$UNFORMATTED" ]; then
    echo "ERROR: These files need formatting:"
    echo -e "$UNFORMATTED"
    echo "Run: dart format <file>"
    exit 1
  fi
fi

# 3. Run flutter analyze if .dart files are staged
if [ -n "$STAGED_DART" ]; then
  echo "Running flutter analyze..."
  cd "$PROJECT_ROOT"
  if ! flutter analyze --no-pub 2>/dev/null; then
    echo "ERROR: flutter analyze failed. Fix issues before committing."
    exit 1
  fi
fi

# 4. Syntax check staged JS files in functions/
STAGED_JS=$(git diff --cached --name-only --diff-filter=ACM | grep '^functions/.*\.js$' || true)
if [ -n "$STAGED_JS" ]; then
  echo "Checking JS syntax..."
  for file in $STAGED_JS; do
    FULL_PATH="$PROJECT_ROOT/$file"
    if [ -f "$FULL_PATH" ]; then
      if ! node --check "$FULL_PATH" 2>/dev/null; then
        echo "ERROR: Syntax error in $file"
        exit 1
      fi
    fi
  done
fi

echo "Pre-commit checks passed."
exit 0
HOOK

chmod +x "$HOOK_TARGET"
echo "Git pre-commit hook installed at $HOOK_TARGET"
echo "To remove: rm $HOOK_TARGET"
