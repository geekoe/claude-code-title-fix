#!/bin/bash
# Claude Code Terminal Title Fix
# https://github.com/geekoe/claude-code-title-fix

set -e

# Locate cli.js
if command -v claude &>/dev/null; then
  CLI_JS="$(dirname "$(realpath "$(which claude)")")/cli.js"
elif [ -f "$(npm root -g)/@anthropic-ai/claude-code/cli.js" ]; then
  CLI_JS="$(npm root -g)/@anthropic-ai/claude-code/cli.js"
else
  echo "❌ Cannot find Claude Code cli.js. Make sure 'claude' is installed and in PATH."
  exit 1
fi

if [ ! -f "$CLI_JS" ]; then
  echo "❌ cli.js not found: $CLI_JS"
  exit 1
fi

echo "📄 cli.js: $CLI_JS"

# Match the buggy condition:
#   !A&&!B&&!C&&VAR.length<=1&&D?.type==="user"&&typeof D.message.content==="string"
MATCH=$(grep -oE '![A-Za-z0-9$_]{1,5}&&![A-Za-z0-9$_]{1,5}&&![A-Za-z0-9$_]{1,5}&&[A-Za-z0-9$_]{1,5}\.length<=1&&[A-Za-z0-9$_]{1,5}\?\.type==="user"&&typeof [A-Za-z0-9$_]{1,5}\.message\.content==="string"' "$CLI_JS" || true)

if [ -z "$MATCH" ]; then
  # Check if already fixed (4 negated vars instead of 3 + length check)
  if grep -qE '![A-Za-z0-9$_]{1,5}&&![A-Za-z0-9$_]{1,5}&&![A-Za-z0-9$_]{1,5}&&![A-Za-z0-9$_]{1,5}&&[A-Za-z0-9$_]{1,5}\?\.type==="user"&&typeof [A-Za-z0-9$_]{1,5}\.message\.content==="string"' "$CLI_JS"; then
    echo "✅ Already fixed, nothing to do."
    exit 0
  fi
  echo "❌ Could not find the buggy code pattern. This version may not be affected or has changed significantly."
  echo "   Please open an issue: https://github.com/geekoe/claude-code-title-fix/issues"
  exit 1
fi

echo "🔍 Found: $MATCH"

# Extract the variable name before .length<=1
PREV_MSGS_VAR=$(echo "$MATCH" | grep -oE '[A-Za-z0-9$_]+\.length<=1' | sed 's/\.length<=1//')

# Find the title priority chain: X??Y??TITLE_VAR??"Claude Code"
TITLE_CHAIN=$(grep -oE '[A-Za-z0-9$_]{1,5}\?\?[A-Za-z0-9$_]{1,5}\?\?[A-Za-z0-9$_]{1,5}\?\?"Claude Code"' "$CLI_JS" | head -1)

if [ -z "$TITLE_CHAIN" ]; then
  echo "❌ Could not find title priority chain (XX??XX??XX??\"Claude Code\")"
  echo "   Please open an issue: https://github.com/geekoe/claude-code-title-fix/issues"
  exit 1
fi

# Extract the 3rd variable (auto-generated title variable): A??B??C → C
TITLE_VAR=$(echo "$TITLE_CHAIN" | sed 's/\?\?"Claude Code"//' | tr '?' '\n' | grep -v '^$' | tail -1)

if [ -z "$TITLE_VAR" ]; then
  echo "❌ Could not extract title variable name"
  echo "   Please open an issue: https://github.com/geekoe/claude-code-title-fix/issues"
  exit 1
fi

OLD="${PREV_MSGS_VAR}.length<=1"
NEW="!${TITLE_VAR}"

echo "🔧 Replacing: ${OLD} → ${NEW}"

# Ensure exactly 1 match
COUNT=$(grep -c "${OLD}" "$CLI_JS")
if [ "$COUNT" -ne 1 ]; then
  echo "⚠️  Found ${COUNT} matches (expected 1), aborting."
  exit 1
fi

# Backup and patch
cp "$CLI_JS" "${CLI_JS}.bak"

# Cross-platform sed -i
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/${OLD}/${NEW}/g" "$CLI_JS"
else
  sed -i "s/${OLD}/${NEW}/g" "$CLI_JS"
fi

# Verify
if grep -q "${NEW}" "$CLI_JS"; then
  echo "✅ Fixed! Restart Claude Code to take effect."
  echo "   Backup saved to: ${CLI_JS}.bak"
else
  echo "❌ Replacement failed, restoring backup..."
  cp "${CLI_JS}.bak" "$CLI_JS"
  exit 1
fi
