#!/bin/bash
# Claude Code Terminal Bell Fix
# 修复 OSC 序列使用 BEL(\x07) 作终止符导致终端不断出现未读标记的问题
# 改为使用 ST(\x1b\\) 作为 OSC 终止符，notifyBell 不受影响
#
# 用法：bash fix-bell.sh
#       升级 Claude Code 后需重新运行
# https://github.com/geekoe/claude-code-title-fix

set -e

# Locate cli.js
if command -v claude &>/dev/null; then
  CLI_JS="$(dirname "$(realpath "$(which claude)")")/cli.js"
elif [ -f "$(npm root -g)/@anthropic-ai/claude-code/cli.js" ]; then
  CLI_JS="$(npm root -g)/@anthropic-ai/claude-code/cli.js"
else
  echo "❌ Cannot find Claude Code cli.js."
  exit 1
fi

if [ ! -f "$CLI_JS" ]; then
  echo "❌ cli.js not found: $CLI_JS"
  exit 1
fi

echo "📄 cli.js: $CLI_JS"

# Match the OSC terminator selection in gP function:
#   Q8.terminal==="kitty"?_U3:RU
# where _U3 = ST (\x1b\\) and RU = BEL (\x07)
# We want all terminals to use ST, so replace with just _U3

# Use a regex pattern to match regardless of variable names:
#   VAR.terminal==="kitty"?VAR:VAR
MATCH=$(grep -oE '[A-Za-z0-9$_]+\.terminal==="kitty"\?[A-Za-z0-9$_]+:[A-Za-z0-9$_]+' "$CLI_JS" | head -1)

if [ -z "$MATCH" ]; then
  # Check if already fixed
  if ! grep -q 'terminal==="kitty"' "$CLI_JS"; then
    echo "✅ Already fixed or not applicable."
    exit 0
  fi
  echo "❌ Could not find the OSC terminator pattern."
  echo "   Please open an issue: https://github.com/geekoe/claude-code-title-fix/issues"
  exit 1
fi

echo "🔍 Found: $MATCH"

# Extract the ST variable (the one after ?)
ST_VAR=$(echo "$MATCH" | sed 's/.*?//' | sed 's/:.*//')

echo "🔧 Replacing OSC terminator: always use ST ($ST_VAR) instead of BEL"

COUNT=$(grep -c "$MATCH" "$CLI_JS")
if [ "$COUNT" -ne 1 ]; then
  echo "⚠️  Found ${COUNT} matches (expected 1), aborting."
  exit 1
fi

# Backup (only if no backup exists yet)
if [ ! -f "${CLI_JS}.bak" ]; then
  cp "$CLI_JS" "${CLI_JS}.bak"
fi

# Replace: Q8.terminal==="kitty"?_U3:RU → _U3
# Using python for reliable replacement
python3 -c "
import sys
path = sys.argv[1]
old = sys.argv[2]
new = sys.argv[3]
with open(path, 'r') as f:
    content = f.read()
content = content.replace(old, new, 1)
with open(path, 'w') as f:
    f.write(content)
" "$CLI_JS" "$MATCH" "$ST_VAR"

# Verify
if grep -q "$MATCH" "$CLI_JS"; then
  echo "❌ Replacement failed, restoring backup..."
  cp "${CLI_JS}.bak" "$CLI_JS"
  exit 1
else
  echo "✅ Fixed! OSC sequences now use ST instead of BEL."
  echo "   notifyBell (real notifications) is not affected."
  echo "   Restart Claude Code to take effect."
fi
